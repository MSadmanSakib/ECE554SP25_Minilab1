`timescale 1 ps / 1 ps
module Top_tb;

  // Parameters
  parameter DATA_WIDTH = 8;
  parameter MAC_COUNT = 8;

  // Testbench signals
  reg clk;
  reg reset_n;
  reg start;
  wire [DATA_WIDTH*3-1:0] C_out [0:MAC_COUNT-1];
  
  // Switch inputs
  logic [9:0] SW;
  logic [3:0] KEY;

  // Outputs
  logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
  logic [9:0] LEDR;

  // Instantiate the top-level module
  Minilab1 uut (
    .clk(clk),
    .start(start),
	.clear(1'b0),
    .C_out(C_out),
	.SW(SW),
	.KEY(KEY),
    .HEX0(HEX0),
    .HEX1(HEX1),
    .HEX2(HEX2),
    .HEX3(HEX3),
    .HEX4(HEX4),
    .HEX5(HEX5),
    .LEDR(LEDR)
  );

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk; // 10ns clock period
  end

  // Testbench stimulus
  initial begin
    // Initialize signals
	    // Initialize inputs
    KEY = 4'b1111; // Reset inactive
    SW = 10'b0;
    start = 0;
    repeat(2) @(posedge clk); // Wait for a few clock cycles

    // Apply reset
	repeat(2) @(posedge clk);
    KEY[0] = 0; // Assert reset
	repeat(2) @(posedge clk);
    KEY[0] = 1; // Deassert reset

    // Start the FIFO filling process
    start = 1;
    repeat(2) @(posedge clk);
    start = 0;

    // Wait for the process to complete
    wait (uut.fifo_filler.fifo_out_done == 1);
    repeat(5) @(posedge clk); // Allow time for matrix-vector multiplication to complete
	SW[1] = 1;
	repeat(5) @(posedge clk);

    // End simulation
    $display("Simulation completed.");
    $stop;
  end

  // Monitor and print signals
  initial begin
    $monitor("Time: %0t | State: %b | Address: %h | Read_from_memory: %b | Fifo_A_Data: %h | Write_to_fifo_A_Valid: %p | Fifo_B_Data: %h | | Write_to_fifo_B_Valid: %b | | Enable: %p | A_Data: %h %h %h %h %h %h %h %h | Start: %b | B_Data: %p | C_out: %p",
             $time, uut.fifo_filler.state, uut.fifo_filler.address, uut.fifo_filler.read, uut.fifo_filler.mem_dataA, uut.fifo_filler.wren_A, uut.fifo_filler.mem_dataB, uut.fifo_filler.wren_B, uut.mat_mult.En_prop,
             uut.mat_mult.A_in[0], uut.mat_mult.A_in[1], uut.mat_mult.A_in[2], uut.mat_mult.A_in[3], uut.mat_mult.A_in[4], uut.mat_mult.A_in[5], uut.mat_mult.A_in[6], uut.mat_mult.A_in[7], 
			 uut.fifo_filler.start_mult, uut.mat_mult.B_prop, C_out);
  end

endmodule