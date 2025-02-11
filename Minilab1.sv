module Minilab1 #
(
  // Parameters
  parameter DATA_WIDTH = 8,
  parameter MAC_COUNT = 8,
  parameter MEM_ADDR_WIDTH = 32,
  parameter MEM_DATA_WIDTH = 64
)
(
  input wire clk,
  input wire start,
  input wire clear,
  output wire [DATA_WIDTH*3-1:0] C_out [0:MAC_COUNT-1],
  
  	//////////// SEG7 //////////
	output	reg	     [6:0]		HEX0,
	output	reg	     [6:0]		HEX1,
	output	reg	     [6:0]		HEX2,
	output	reg	     [6:0]		HEX3,
	output	reg	     [6:0]		HEX4,
	output	reg	     [6:0]		HEX5,
	
	//////////// LED //////////
	output		     [9:0]		LEDR,

	//////////// KEY //////////
	input 		     [3:0]		KEY,

	//////////// SW //////////
	input 		     [9:0]		SW
);

  wire reset_n;
  assign reset_n = KEY[0];

parameter HEX_0 = 7'b1000000;		// zero
parameter HEX_1 = 7'b1111001;		// one
parameter HEX_2 = 7'b0100100;		// two
parameter HEX_3 = 7'b0110000;		// three
parameter HEX_4 = 7'b0011001;		// four
parameter HEX_5 = 7'b0010010;		// five
parameter HEX_6 = 7'b0000010;		// six
parameter HEX_7 = 7'b1111000;		// seven
parameter HEX_8 = 7'b0000000;		// eight
parameter HEX_9 = 7'b0011000;		// nine
parameter HEX_10 = 7'b0001000;	// ten
parameter HEX_11 = 7'b0000011;	// eleven
parameter HEX_12 = 7'b1000110;	// twelve
parameter HEX_13 = 7'b0100001;	// thirteen
parameter HEX_14 = 7'b0000110;	// fourteen
parameter HEX_15 = 7'b0001110;	// fifteen
parameter OFF   = 7'b1111111;		// all off



 // FIFO signals
  wire wren_A, wren_B;
  wire [DATA_WIDTH-1:0] A_data [0:MAC_COUNT-1]; 
  wire [DATA_WIDTH-1:0] B_data; 
  wire start_mult;
  wire stop;
  wire [2:0]state;
  wire Done;

  // Memory module signals
  wire [MEM_ADDR_WIDTH-1:0] address;
  wire read;
  wire [MEM_DATA_WIDTH-1:0] readdata;
  wire readdatavalid;
  wire waitrequest;

  // Memory module instance
  mem_wrapper memory (
    .clk(clk),
    .reset_n(reset_n),
    .address(address),
    .read(read),
    .readdata(readdata),
    .readdatavalid(readdatavalid),
    .waitrequest(waitrequest)
  );

  // FIFO Filler instance
  Fill_Fifo fifo_filler (
    .clk(clk),
    .reset_n(reset_n),
    .address(address),
    .read(read),
    .readdata(readdata),
    .readdatavalid(readdatavalid),
    .waitrequest(waitrequest),
    .A_data(A_data),
	.B_data(B_data),
    .start(start),
    .start_mult(start_mult),
	.stop(stop),
	.state_out(state)
  );

  // Matrix Multiplication instance
  Matrix_Mult mat_mult (
    .clk(clk),
    .rst_n(reset_n),
    .Clr(clear), // Clear signal 
    .A_in(A_data),  // Array of rows for matrix A
    .B_in(B_data),  // Array for vector B
    .start(start_mult),
	.stop(stop),
    .C_out(C_out),
	.done_final(Done)
  );

logic [DATA_WIDTH*3-1:0] selected_C_out;
// **Multiplexing logic for selecting the correct `C_out[row]`**
always @(*) begin
  case (1'b1)  // **Priority encoding (highest switch active)**
    SW[1]: selected_C_out = C_out[0];
    SW[2]: selected_C_out = C_out[1];
    SW[3]: selected_C_out = C_out[2];
    SW[4]: selected_C_out = C_out[3];
    SW[5]: selected_C_out = C_out[4];
    SW[6]: selected_C_out = C_out[5];
    SW[7]: selected_C_out = C_out[6];
    SW[8]: selected_C_out = C_out[7];
    default: selected_C_out = 0; // If no switch is active, display nothing
  endcase
end

// **Mapping `selected_C_out` to HEX0 - HEX5**
always @(*) begin
  if (Done) begin
    case (selected_C_out[3:0])
      4'd0: HEX0 = HEX_0;
      4'd1: HEX0 = HEX_1;
      4'd2: HEX0 = HEX_2;
      4'd3: HEX0 = HEX_3;
      4'd4: HEX0 = HEX_4;
      4'd5: HEX0 = HEX_5;
      4'd6: HEX0 = HEX_6;
      4'd7: HEX0 = HEX_7;
      4'd8: HEX0 = HEX_8;
      4'd9: HEX0 = HEX_9;
      4'd10: HEX0 = HEX_10;
      4'd11: HEX0 = HEX_11;
      4'd12: HEX0 = HEX_12;
      4'd13: HEX0 = HEX_13;
      4'd14: HEX0 = HEX_14;
      4'd15: HEX0 = HEX_15;
      default: HEX0 = OFF;
    endcase
  end else begin
    HEX0 = OFF;
  end
end

always @(*) begin
  if (Done) begin
    case (selected_C_out[7:4])
      4'd0: HEX1 = HEX_0;
      4'd1: HEX1 = HEX_1;
      4'd2: HEX1 = HEX_2;
      4'd3: HEX1 = HEX_3;
      4'd4: HEX1 = HEX_4;
      4'd5: HEX1 = HEX_5;
      4'd6: HEX1 = HEX_6;
      4'd7: HEX1 = HEX_7;
      4'd8: HEX1 = HEX_8;
      4'd9: HEX1 = HEX_9;
      4'd10: HEX1 = HEX_10;
      4'd11: HEX1 = HEX_11;
      4'd12: HEX1 = HEX_12;
      4'd13: HEX1 = HEX_13;
      4'd14: HEX1 = HEX_14;
      4'd15: HEX1 = HEX_15;
      default: HEX1 = OFF;
    endcase
  end else begin
    HEX1 = OFF;
  end
end

always @(*) begin
  if (Done) begin
    case (selected_C_out[11:8])
      4'd0: HEX2 = HEX_0;
      4'd1: HEX2 = HEX_1;
      4'd2: HEX2 = HEX_2;
      4'd3: HEX2 = HEX_3;
      4'd4: HEX2 = HEX_4;
      4'd5: HEX2 = HEX_5;
      4'd6: HEX2 = HEX_6;
      4'd7: HEX2 = HEX_7;
      4'd8: HEX2 = HEX_8;
      4'd9: HEX2 = HEX_9;
      4'd10: HEX2 = HEX_10;
      4'd11: HEX2 = HEX_11;
      4'd12: HEX2 = HEX_12;
      4'd13: HEX2 = HEX_13;
      4'd14: HEX2 = HEX_14;
      4'd15: HEX2 = HEX_15;
      default: HEX2 = OFF;
    endcase
  end else begin
    HEX2 = OFF;
  end
end

always @(*) begin
  if (Done) begin
    case (selected_C_out[15:12])
      4'd0: HEX3 = HEX_0;
      4'd1: HEX3 = HEX_1;
      4'd2: HEX3 = HEX_2;
      4'd3: HEX3 = HEX_3;
      4'd4: HEX3 = HEX_4;
      4'd5: HEX3 = HEX_5;
      4'd6: HEX3 = HEX_6;
      4'd7: HEX3 = HEX_7;
      4'd8: HEX3 = HEX_8;
      4'd9: HEX3 = HEX_9;
      4'd10: HEX3 = HEX_10;
      4'd11: HEX3 = HEX_11;
      4'd12: HEX3 = HEX_12;
      4'd13: HEX3 = HEX_13;
      4'd14: HEX3 = HEX_14;
      4'd15: HEX3 = HEX_15;
      default: HEX3 = OFF;
    endcase
  end else begin
    HEX3 = OFF;
  end
end

always @(*) begin
  if (Done) begin
    case (selected_C_out[19:16])
      4'd0: HEX4 = HEX_0;
      4'd1: HEX4 = HEX_1;
      4'd2: HEX4 = HEX_2;
      4'd3: HEX4 = HEX_3;
      4'd4: HEX4 = HEX_4;
      4'd5: HEX4 = HEX_5;
      4'd6: HEX4 = HEX_6;
      4'd7: HEX4 = HEX_7;
      4'd8: HEX4 = HEX_8;
      4'd9: HEX4 = HEX_9;
      4'd10: HEX4 = HEX_10;
      4'd11: HEX4 = HEX_11;
      4'd12: HEX4 = HEX_12;
      4'd13: HEX4 = HEX_13;
      4'd14: HEX4 = HEX_14;
      4'd15: HEX4 = HEX_15;
      default: HEX4 = OFF;
    endcase
  end else begin
    HEX4 = OFF;
  end
end

always @(*) begin
  if (Done) begin
    case (selected_C_out[23:20])
      4'd0: HEX5 = HEX_0;
      4'd1: HEX5 = HEX_1;
      4'd2: HEX5 = HEX_2;
      4'd3: HEX5 = HEX_3;
      4'd4: HEX5 = HEX_4;
      4'd5: HEX5 = HEX_5;
      4'd6: HEX5 = HEX_6;
      4'd7: HEX5 = HEX_7;
      4'd8: HEX5 = HEX_8;
      4'd9: HEX5 = HEX_9;
      4'd10: HEX5 = HEX_10;
      4'd11: HEX5 = HEX_11;
      4'd12: HEX5 = HEX_12;
      4'd13: HEX5 = HEX_13;
      4'd14: HEX5 = HEX_14;
      4'd15: HEX5 = HEX_15;
      default: HEX5 = OFF;
    endcase
  end else begin
    HEX5 = OFF;
  end
end

assign LEDR = {{7{1'b0}}, state};


endmodule