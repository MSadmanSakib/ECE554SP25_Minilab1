module Fill_Fifo #
(
  parameter DATA_WIDTH = 8,
  parameter FIFO_DEPTH = 8,
  parameter MEM_ADDR_WIDTH = 32,
  parameter MEM_DATA_WIDTH = 64
)
(
  input wire clk,
  input wire reset_n,
  input wire start,

  // Avalon-MM Master Interface
  output reg [MEM_ADDR_WIDTH-1:0] address,      // Memory address
  output reg read,                              // Read request
  input wire [MEM_DATA_WIDTH-1:0] readdata,     // Read data from memory
  input wire readdatavalid,                     // Read data valid signal
  input wire waitrequest,                       // Memory busy signal

  // FIFO Data Outputs (No Write Enable)
  output reg [DATA_WIDTH-1:0] A_data[0:FIFO_DEPTH-1],
  output reg [DATA_WIDTH-1:0] B_data,
  output reg start_mult,
  output wire stop,
  output wire [2:0] state_out
);

  // Internal signals
  reg [MEM_DATA_WIDTH-1:0] mem_data;
  reg [DATA_WIDTH-1:0] mem_dataA; // Latched memory data
  reg [DATA_WIDTH-1:0] mem_dataB;  
  reg B_loaded;                                 // Flag to indicate B is loaded
  reg fifo_in_done, fifo_out_done;              // Done signal when FIFOs are filled

  // Declare rden_A and wren_A, full and empty
  reg rden_A [0:FIFO_DEPTH-1] ;                  // Read enable for each FIFO A
  reg wren_A [0:FIFO_DEPTH-1] ;                  // Write enable for FIFO A
  reg rden_B;                                   // Read enable for FIFO B
  logic wren_B,count_A, count_B, count_j, clear_i_A, count_address, clear_address;                                   // Write enable for FIFO B
  wire A_full [FIFO_DEPTH-1:0]  ; 
  wire B_full;
  wire A_empty [FIFO_DEPTH-1:0] ;
  wire B_empty; 
  logic [2:0] i_A, i_B, j;

  // State encoding
  typedef enum logic [2:0] {IDLE, LOAD_B, READ_MEM, WRITE_FIFO_A, DONE_IN, READ_FIFOS, RESET} state_t;
  
  state_t state, next_state; // Current state and next state
  
  assign state_out = state;
  assign stop = A_empty[0];

 
  // FIFO for Matrix A (8 rows)
  genvar i;
  generate
    for (i = 0; i < FIFO_DEPTH; i = i + 1) begin : fifo_A
      FIFO_IP //#(
       // .DEPTH(FIFO_DEPTH),
       // .DATA_WIDTH(DATA_WIDTH))
       fifo_A_inst ( 
	    .data (mem_dataA),
		.rdclk (clk),
		.rdreq (rden_A[i]),
		.wrclk (clk),
		.wrreq (wren_A[i]),
		.q (A_data[i]),
		.rdempty (A_empty[i]),
		.wrfull (A_full[i])		
      );

    end
  endgenerate 
  

  // FIFO for Vector B (1 row/column)
  FIFO_IP //#(
       // .DEPTH(FIFO_DEPTH),
       // .DATA_WIDTH(DATA_WIDTH))
   fifo_B_inst (
    /*.clk(clk),
    .rst_n(reset_n),
    .rden(rden_B),     // Read enable for FIFO B
    .wren(wren_B),     // Write enable for FIFO B
    .i_data(mem_dataB), // First byte of mem_data for B
    .o_data(B_data),
    .full(B_full),           
    .empty(B_empty)  */ 
		.data (mem_dataB),
		.rdclk (clk),
		.rdreq (rden_B),
		.wrclk (clk),
		.wrreq (wren_B),
		.q (B_data),
		.rdempty (B_empty),
		.wrfull (B_full)	 
  );
  
  
  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        i_A <= 0;
        i_B <= 0;
        j <= 0;
        address <= 0;
		rden_A <= '{default: 0};
    end
    else begin
        // Priority logic for i_A
        if (clear_i_A) begin
            i_A <= 0; // Clear i_A has the highest priority
        end
        else if (count_A) begin
            i_A <= i_A + 1; // Increment i_A if clear_i_A is not active
        end

        // Priority logic for i_B
        if (count_B) begin
            i_B <= i_B + 1;
        end

        // Priority logic for j
        if (count_j) begin
            j <= j + 1;
        end

        // Priority logic for address
        if (count_address) begin
            address <= address + 1;
        end
		  if (clear_address) begin
            address <= 0;
        end
		if (state == READ_FIFOS) begin
			rden_A[i_A] <= 1'b1;  // Enable reading when in READ_FIFOS
			if (A_empty[i_A]) begin
				rden_A[i_A] <= 1'b0; // Deassert when FIFO is empty
        end
    end
    end
end

  // State machine for FIFO filling
  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
		state <= IDLE;
    end 
	else begin
      state <= next_state;  // Update state
    end
  end

  // Next state logic
  always_comb begin
    // Default values to avoid latches
      read = 0;
      fifo_in_done = 0;
	  fifo_out_done = 0;
      B_loaded = 0;
      count_address = 0;
		clear_address = 0;
      //rden_A= '{default: 0};      // Initialize rden_A to 0 (no reads)
      wren_A = '{default: 0};      // Deassert write for A
      rden_B = 0;      // Initialize rden_B to 0 (no reads)
      wren_B = 0;      // Deassert write for B
	  mem_data = 0;
	  mem_dataA = 0;
	  mem_dataB = 0;
	  start_mult = 0;
	  count_A = 0;
	  count_B = 0;
	  count_j = 0;
	  clear_i_A = 0;
	  next_state = state;

    case(state)
      IDLE: begin
		  clear_address = 1;
        if (start) begin
          read = 1;            // Issue read request
        end
		if (readdatavalid) begin
		    read = 0;
			next_state = LOAD_B;
		end
      end

      LOAD_B: begin
        
          mem_data = readdata; // Latch memory data
          mem_dataB = mem_data[((FIFO_DEPTH - 1) - i_B)*DATA_WIDTH +: DATA_WIDTH]; 
          wren_B = 1;          // Write to FIFO B
          count_B = 1;
          if (i_B == FIFO_DEPTH - 1) begin
		    count_B = 0;
            B_loaded = 1;      // Set flag to indicate B is loaded
            // Move to A loading and start from address 1
            count_address = 1;        // Start loading A from address 1
            next_state = READ_MEM;
          end
       
      end

      READ_MEM: begin
	    wren_B = 0; // Deassert FIFO B write
		count_address = 0;
		count_A = 0;
		read = 1; 
        if (!waitrequest & readdatavalid) begin
          read = 0; // Deassert read request
          next_state = WRITE_FIFO_A;
        end
      end

      WRITE_FIFO_A: begin
          mem_data = readdata; // Latch memory data
          mem_dataA = mem_data[((FIFO_DEPTH - 1) - j)*DATA_WIDTH +: DATA_WIDTH]; 
          wren_A[i_A] = 1;          // Write to FIFO A
		  count_j = 1;
          if (A_full[i_A]) begin
            wren_A[i_A] = 0;
				count_j = 0;
            count_A = 1;         // Increment i_A	
            count_address = 1; // Increment address for next read
            next_state = READ_MEM;			
          end
          if (A_full[FIFO_DEPTH-1]) begin
            wren_A[i_A-1] = 0; 
			count_A = 0;
			clear_i_A = 1;
            next_state = DONE_IN;     // All data written
          end 
        
      end

      DONE_IN: begin
		clear_i_A = 0;
        if (A_full[FIFO_DEPTH-1] && B_full) begin
          fifo_in_done = 1;   // Assert done signal
          next_state = READ_FIFOS; 
        end
      end
	  
      READ_FIFOS: begin
	    clear_i_A = 0;
	    count_A = 1;
        start_mult = 1;
	    //rden_A[i_A] = 1;
        rden_B = 1; // Deassert FIFO B write
        if (B_empty) begin
          rden_B = 0;
        end 
        if (A_empty[FIFO_DEPTH-1]) begin
          //rden_A = '{default: 0};
		  fifo_out_done = 1;   // Assert done signal
		  next_state = RESET;			
        end	
      end
		
		RESET: begin
		  // wait till reset
		
		end
   default: next_state = IDLE;
    endcase
  end

endmodule