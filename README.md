# Pong Game on FPGA in Verilog

**Overview**

This project, developed as part of the ECE241: Digital Systems course at the University of Toronto, involves designing and implementing a version of the classic video game Pong using Verilog. The game is played by two players using switches on an FPGA board, with the gameplay displayed on a VGA monitor. The project includes audio output, score tracking via a 7-segment display, and a fully integrated game system designed using hardware description languages (HDLs), specifically Verilog.

The project leverages digital design principles such as Finite State Machines (FSMs), ALUs, and registers to implement gameplay, ball physics, and paddle control. The game offers an interactive and engaging experience, showcasing fundamental digital system design concepts through Verilog-based development.

**Features**

- Complex ALU model with state machines: Implements the game’s “physics engine,” handling ball movement, paddle collisions, and game dynamics.
- VGA Display with Double Buffering: Responsible for rendering smooth game visuals on the VGA monitor.
- Audio Integration: Provides audio feedback for paddle-ball interactions and goal scoring, adding to the game’s immersive experience.
- FSM for Gameplay Tracking: Manages the game state, including player turns, resets, and game-over conditions.
- Paddle Control via Switches and Keys: Players control their paddles using switches on the FPGA board.
- Scorekeeping and Winning Animation: The game’s score is displayed using the 7-segment display, and LEDs are used to show the winning animation.
- Ball and Paddle Management: Keeps track of ball and paddle positions, directions, and velocities using inferred memories and registers.

**System Design**

**Key Components:**

1. VGA Display with Double Buffering: Renders the game in real-time, ensuring smooth visual output.
2. Complex ALU & State Machine: Acts as the “physics engine,” calculating the movement of the ball and detecting collisions with paddles and walls.
3. Audio Output: Audio feedback when the paddles hit the ball and when a goal is scored, adding to the game’s interactivity.
4. FSM for Gameplay Control: Tracks the current state of the game, manages ball resets, player turns, and game-over states.
5. Switch and Key Input for Paddle Control: Switches on the FPGA board allow players to move their paddles, creating a responsive gaming experience.
6. 7-Segment Display & LEDs: Displays the score and provides visual feedback with a winning animation.

**Conclusion**

This project was an excellent opportunity to apply digital systems design concepts in a practical way by building a real-time game system on an FPGA using Verilog. It demonstrates the integration of FSMs, ALUs, VGA display, and audio systems into a cohesive and interactive game. Although completed in 2023, this project is being uploaded now in 2024 to showcase my skills in FPGA-based digital system design and Verilog programming.
