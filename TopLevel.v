module GoodButFixBallMotion(	
		CLOCK_50,						//	On Board 50 MHz
		SW, 								// On Board Switches
		KEY,							   // On Board Keys
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,					//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B,
		AUD_ADCDAT,
		AUD_BCLK,
		AUD_ADCLRCK,
		AUD_DACLRCK,
		FPGA_I2C_SDAT,
		AUD_XCK,
		AUD_DACDAT,
		FPGA_I2C_SCLK		
	);

	input		    CLOCK_50;			//	50 MHz
	input	 [3:0] KEY;					// Keys
	input  [9:0] SW;					// Switches
	output		 VGA_CLK;   		//	VGA Clock
	output		 VGA_HS;				//	VGA H_SYNC
	output		 VGA_VS;				//	VGA V_SYNC
	output		 VGA_BLANK_N;		//	VGA BLANK
	output		 VGA_SYNC_N;		//	VGA SYNC
	output [7:0] VGA_R;   			//	VGA Red[7:0] Changed from 10 to 8-bit DAC
	output [7:0] VGA_G;	 			//	VGA Green[7:0]
	output [7:0] VGA_B;   			//	VGA Blue[7:0]
	input				AUD_ADCDAT;

	// Bidirectionals
	inout				AUD_BCLK;
	inout				AUD_ADCLRCK;
	inout				AUD_DACLRCK;
	inout				FPGA_I2C_SDAT;

	// Outputs
	output				AUD_XCK;
	output				AUD_DACDAT;
	output				FPGA_I2C_SCLK;
	
	wire resetn;
	wire paddle1Up;
	wire paddle1Down;
	wire paddle2Up;
	wire paddle2Down;

	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;

	wire go, erase, plotEn, update, reset;
	
	
	//!!!!!
	assign resetn = SW[0]; ///   CHANGE THIS!!!!!!!
	//!!!!!
	assign paddle1Up = KEY[3];
	assign paddle1Down = KEY[2];
	assign paddle2Up = KEY[1];
	assign paddle2Down = KEY[0];

	
	
	parameter SCREEN_HEIGHT = 120;
   parameter PADDLE_HEIGHT = 4; //the up and down of the paddle
	parameter BALL_SIZE = 1;

	wire [7:0] xCounter;
	wire [6:0] yCounter;
	wire [31:0] speed;

	// Create an Instance of a VGA controller 
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(go),
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
		
			
	controlPath c(CLOCK_50, resetn, xCounter, yCounter, speed, go, erase, update, plotEn, reset);
	
	dataPath d(CLOCK_50, resetn, plotEn, go, erase, update, reset, paddle1Up, paddle1Down, paddle2Up, paddle2Down, x, y, colour, xCounter, yCounter, speed);
	
		DE1_SoC_Audio_Example audio(
  .CLOCK_50 (CLOCK_50),
  .KEY(KEY),
  .AUD_ADCDAT (AUD_ADCDAT),
  .AUD_BCLK (AUD_BCLK),
  .AUD_ADCLRCK (AUD_ADCLRCK),
  .AUD_DACLRCK (AUD_DACLRCK),
  .FPGA_I2C_SDAT (FPGA_I2C_SDAT),
  .AUD_XCK (AUD_XCK),
  .AUD_DACDAT (AUD_DACDAT),
  .FPGA_I2C_SCLK (FPGA_I2C_SCLK),
  .SW(SW));
	
	endmodule

module controlPath (input clk, resetn,
						 input [7:0] xCounter,  
						 input [6:0] yCounter,  
						 input [31:0] speed,
						 output reg go, erase, update, plotEn, reset);
	
	reg [2:0] currentSt, nextSt;
	
	localparam UPDATE = 3'b000;
   localparam DRAW   = 3'b001;
   localparam PAUSE  = 3'b010;
   localparam ERASE  = 3'b011;
   localparam RESET  = 3'b100;
	
	always @(*) begin

		case(currentSt)
            RESET: nextSt = UPDATE;
            UPDATE: nextSt = DRAW;
			DRAW: begin
				if((xCounter == 8'd160) && (yCounter == 7'd120))  ///no done erase anymore??
					nextSt = PAUSE;
				else 
					nextSt = DRAW;
				end
			PAUSE: begin
				if(speed < 32'd6250000)
					nextSt = PAUSE;
				else
					nextSt = ERASE;
				end
			ERASE: begin
				if ((xCounter != 8'd160) || (yCounter != 7'd120))
					nextSt = ERASE;
				else
					nextSt = UPDATE;
				end
			default: nextSt = RESET;
		endcase
	end

	always@(*)
	begin

		go = 1'b0;
		update = 1'b0;
		reset = 1'b0;
		erase = 1'b0;
		plotEn = 1'b0;

		case(currentSt)
         RESET: begin
                 reset = 1'b1;
					  go = 1'b1;
               end
			UPDATE: begin
                 go = 1'b0;
					  update = 1'b1;
					end
         DRAW: begin
					  go = 1'b1;
                 plotEn = 1'b1;
					end
			PAUSE: begin 
					  go = 1'b0;
					end
			ERASE: begin 
					  erase = 1'b1;
                 go = 1'b1;
					end
			endcase
		end

	
	always @(posedge clk)
	begin
			if(!resetn)
				currentSt <= RESET;
			else
				currentSt<=nextSt;
	end
endmodule 

module dataPath(input clk, resetn, plotEn, go, erase, update, reset, paddle1Up, paddle1Down, paddle2Up, paddle2Down,
					 output reg [7:0] X,
					 output reg [6:0] Y,
					 output reg [2:0] CLR,
					 output reg [7:0] xCounter,
					 output reg [6:0] yCounter, 
					 output reg [31:0] speed
                      );
	
	
	//declaration of motion and collision modules
	reg [6:0] Paddle1_Y;
	reg [6:0] Paddle2_Y;
	reg [7:0] Ball_X;
	reg [6:0] Ball_Y;
	reg [2:0] Ball_Vx;
	reg [2:0] Ball_Vy;
	reg [2:0] Updated_Ball_Vx;
	reg [2:0] Updated_Ball_Vy;
	reg [3:0] paddle1_score;
	reg [3:0] paddle2_score;
	reg [2:0] direction;
    //reg [7:0] next_Ball_X;
    //reg [6:0] next_Ball_Y;
    //reg [7:0] next_Vx;
    //reg [6:0] next_Vy;
	
	parameter SCREEN_WIDTH = 159;
	parameter SCREEN_HEIGHT = 119;
	parameter PADDLE_HEIGHT = 4;
	parameter BALL_SIZE = 2;
	parameter MAX_SCORE = 4'b1001;
	
	localparam UP = 3'b000;
   localparam DOWN = 3'b001;
   localparam  LEFT_UP = 3'b010;
   localparam  LEFT_DOWN = 3'b011;
   localparam  RIGHT_UP = 3'b100;
   localparam RIGHT_DOWN = 3'b101;
	  
	always @(posedge clk) 
	begin
		if (reset || !resetn) begin
			X <= 8'd156;
			Y <= 7'b0;
			xCounter<= 8'b0;
			yCounter <= 7'b0;
			speed <= 32'd0;
			Ball_X <= SCREEN_WIDTH/2;
			Ball_Y <= SCREEN_HEIGHT/2;
			Paddle1_Y <= SCREEN_HEIGHT/2;
			Paddle2_Y <= SCREEN_HEIGHT/2;
			Ball_Vx <= 2;
			Ball_Vy <= 0;
            
        end

        //UPDATE
        if(update) begin    //if it's time to update and draw the next frame then the xCounter and yCounter needs to be reset to 0 since next state is draw
				///all the logic for the game goes in here
				//READING OF INPUT

				xCounter<= 8'b0;
				yCounter <= 7'b0;
			
				//Update paddleYs
				
				if(!paddle1Up && (Paddle1_Y<=(SCREEN_HEIGHT-PADDLE_HEIGHT)))
				begin
					Paddle1_Y <= Paddle1_Y + 1;
				end

				if(!paddle2Up && (Paddle2_Y<=(SCREEN_HEIGHT-PADDLE_HEIGHT)))
				begin
					Paddle2_Y <= Paddle2_Y + 1;
				end

				if(!paddle1Down && (Paddle1_Y>=PADDLE_HEIGHT))
				begin
					Paddle1_Y <= Paddle1_Y - 1;
				end

				if(!paddle2Down && (Paddle2_Y>=PADDLE_HEIGHT))
				begin
					Paddle2_Y <= Paddle2_Y - 1;
				end

				
				//Check collision between ball and Paddle1 and updates velocity accordingly if collision is there
				  Updated_Ball_Vx = Ball_Vx;  //set the updated Velocities to the current initially
				  Updated_Ball_Vy = Ball_Vy;
					
				  if (Ball_X == 6 || Ball_X == 5 || Ball_X == 4 || Ball_X == 3)
						begin
							integer BallSubsection;
							 // Determining  the subsection of the paddle that was hit
							if ((Ball_X == 6) && (Ball_Y >= Paddle1_Y-PADDLE_HEIGHT-2) && (Ball_Y <= (Paddle1_Y + PADDLE_HEIGHT+2))) 
								begin
									if (Ball_Y >= (Paddle1_Y - PADDLE_HEIGHT-2) && Ball_Y <= Paddle1_Y-2) 
										BallSubsection = 1;
									else if (Ball_Y >= (Paddle1_Y - 1) && Ball_Y <= Paddle1_Y+1) 
										BallSubsection = 2;
									else BallSubsection = 3; 
								end
							if ((Ball_X == 3 || Ball_X == 4 || Ball_X == 5) && (Ball_Y >= Paddle1_Y-PADDLE_HEIGHT-2) && (Ball_Y <= (Paddle1_Y + PADDLE_HEIGHT+2))) 
								begin
									BallSubsection = 4;
								end
							case(BallSubsection)
								 1: 
									begin
									  // Move diagonally upward with inverted velocity
									  Updated_Ball_Vx = -Ball_Vx;
									  Updated_Ball_Vy = Ball_Vy - 1;
									end

								 2: 
									begin
									  // Reflect backward in a linear fashion
									  Updated_Ball_Vx = -Ball_Vx;
									  Updated_Ball_Vy = 0;
									end
								 3: 
									begin
									  // Move diagonally downward with inverted velocity
									  Updated_Ball_Vx = -Ball_Vx;
									  Updated_Ball_Vy = Ball_Vy + 1;
									end
								 4: 
									begin
									  // bouncIng off the sides backwards
									  Updated_Ball_Vx = Ball_Vx;
									  Updated_Ball_Vy = -Ball_Vy;
									end
								 default: 
									begin
									  Updated_Ball_Vx = Ball_Vx;
									  Updated_Ball_Vy = Ball_Vy;
									end
							endcase
					  end

				//Check collision between ball and Paddle2 and updates velocity accordingly if collision is there
				  if (Ball_X == 152 || Ball_X == 153 || Ball_X == 154 || Ball_X == 155)
						begin
							integer BallSubsection;
							 // Determining  the subsection of the paddle that was hit
							if ((Ball_X == 152) && (Ball_Y >= Paddle2_Y-PADDLE_HEIGHT-3) && (Ball_Y <= (Paddle2_Y + PADDLE_HEIGHT+3))) 
								begin
									if (Ball_Y >= (Paddle2_Y - PADDLE_HEIGHT-3) && Ball_Y <= Paddle2_Y+3) 
										BallSubsection = 1;
									else if (Ball_Y >= (Paddle2_Y - 1) && Ball_Y <= Paddle2_Y+1) 
										BallSubsection = 2;
									else BallSubsection = 3; 
								end    
							//seeing if ball hit the sides (bottom/top) of the paddle
							if ((Ball_X == 153 || Ball_X == 154) && (Ball_Y >= Paddle2_Y-PADDLE_HEIGHT-2) && (Ball_Y <= (Paddle2_Y + PADDLE_HEIGHT+2))) 
								begin
									BallSubsection = 4;
								end
							case(BallSubsection)
								 1: 
									begin
									  // Move diagonally upward with inverted velocity
									  Updated_Ball_Vx = -Ball_Vx;
									  Updated_Ball_Vy = Ball_Vy - 1;
									end

								 2: 
									begin
									  // Reflect backward in a linear fashion
									  Updated_Ball_Vx = -Ball_Vx;
									  Updated_Ball_Vy = 0;
									end
								 3: 
									begin
									  // Move diagonally downward with inverted velocity
									  Updated_Ball_Vx = -Ball_Vx;
									  Updated_Ball_Vy = Ball_Vy + 1;
									end
								 4: 
									begin
									  // bounicng off the sides (bottom/top) of paddle and going backwards
									  Updated_Ball_Vx = Ball_Vx;
									  Updated_Ball_Vy = -Ball_Vy;
									end
								 default: 
									begin
									  Updated_Ball_Vx = Ball_Vx;
									  Updated_Ball_Vy = Ball_Vy;
									end
							endcase
					  end
				  
				//check collision between ball and up wall
				  if ((Ball_Y == BALL_SIZE) && (Ball_X > 2) && (Ball_X < SCREEN_WIDTH-2)) 
						begin
							Updated_Ball_Vx = Ball_Vx;
							Updated_Ball_Vy = -Ball_Vy;
						end
				//check collision between ball and down wall
				  if ((Ball_Y == SCREEN_HEIGHT - BALL_SIZE) && (Ball_X > 2) && (Ball_X < SCREEN_WIDTH-2)) 
						begin
							Updated_Ball_Vx = Ball_Vx;
							Updated_Ball_Vy = -Ball_Vy;
						end
				//check collision between ball and Paddle1 Wall
					if ((Ball_X == 2)) //this is assuming that it is not any of the cases above
						begin
						// Update Paddle 2 score, ensuring it does not exceed the maximum score
						if (paddle2_score < MAX_SCORE) 
							begin
								paddle2_score = paddle2_score + 1;
								//somehow reset the game to reset
							end
						end
				//check collision between ball and Paddle2 Wall
					if (Ball_X == SCREEN_WIDTH - 2) 
						begin
						// Update Paddle 1 score, ensuring it does not exceed the maximum score
						if (paddle1_score < MAX_SCORE) 
							begin
								paddle1_score = paddle1_score + 1;
							end
						end
				//update the position X and Y of the ball
				Ball_Vx <= Updated_Ball_Vx;
				Ball_Vy <= Updated_Ball_Vy;
				Ball_X <= Ball_X + Ball_Vx;
				Ball_Y <= Ball_Y + Ball_Vy;
				end
				
        

        //DRAW
        if(go && plotEn) begin
            if (xCounter == 8'd160 && yCounter != 7'd120) 
            begin
					xCounter <= 8'b0;
					yCounter <= yCounter + 1;
			end
			
			else 
            begin
					xCounter <= xCounter + 1;
					X <= xCounter;
					Y <= yCounter;
					if(((X==3)||(X==4))&&((Y>(Paddle1_Y-6))&&(Y<(Paddle1_Y+6))))
                    begin
                        CLR<=3'b1;
                    end
               else if(((X==155)||(X==156))&&((Y>(Paddle2_Y-6))&&(Y<(Paddle2_Y+6))))
						  begin
                        CLR<=3'b1;
                    end
               else if(((X>Ball_X-2)&&(X<Ball_X+2))&&((Y>(Ball_Y-2))&&(Y<(Ball_Y+2))))
                    begin
                        CLR<=3'b1;
                    end
               else
                    begin
                        CLR<=3'b0;
                    end
			   end
        end

        //PAUSE
        if(!go && !update)
			begin
				xCounter<= 8'b0;
				yCounter <= 7'b0;
				if (speed == 32'd6250000) speed <= 32'd0;
				else speed <= speed + 1;
			end

        //ERASE
		if (erase) 
            begin
			if(xCounter == 8'd160 && yCounter != 7'd120) 
                begin
                        xCounter <= 8'b0;
                        yCounter <= yCounter + 1;
                end
            else
                begin
                xCounter <= xCounter + 1;
                        X <= xCounter;
                        Y <= yCounter;
                        CLR <= 3'b0;
                end
		    end
	end

endmodule
