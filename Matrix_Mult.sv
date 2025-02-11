module Matrix_Mult #
(
  parameter DATA_WIDTH = 8,
  parameter MAC_COUNT = 8
)
(
  input clk,
  input rst_n,
  input Clr,
  input logic [DATA_WIDTH-1:0] A_in [0:MAC_COUNT-1],  // Input for each row of A
  input logic [DATA_WIDTH-1:0] B_in,  // Input for vector B
  input logic start,
  input logic stop,
  output logic [DATA_WIDTH*3-1:0] C_out [MAC_COUNT],
  output logic done_final
);

  // MAC array signals
  logic En_prop [MAC_COUNT];
  logic [DATA_WIDTH-1:0] B_in_flopped;
  logic [DATA_WIDTH-1:0] B_prop [MAC_COUNT];  // Propagated enable and B signals
  logic enable, stop_flopped;

  // Initialize En and B propagation
  assign En_prop[0] = stop_flopped ? 0 : enable;  // Start the enable signal
  assign B_prop[0] = B_in_flopped;
  
  assign done_final = stop_flopped;
  
  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
	  enable <= 0;
	  stop_flopped <= 0;
	  B_in_flopped <= 0;
	end
	else if(start & (~enable)) begin
	  enable <= start;
	end
	else begin
	  stop_flopped <= stop;
	  B_in_flopped <= B_in;
	end
  end

  // Generate MAC array
  genvar i;
  generate
    for (i = 0; i < MAC_COUNT; i = i + 1) begin : mac_array
      // Instantiate MAC unit
      MAC #(.DATA_WIDTH(DATA_WIDTH)) mac_unit (
        .clk(clk),
        .rst_n(rst_n),
        .En(En_prop[i]),  // Propagated enable signal
        .Clr(Clr),
        .Ain(A_in[i]),  // Input from row of A
        .Bin(B_prop[i]),  // Input from vector B
        .Cout(C_out[i])  // Output for this row
      );

      // Propagate En signal with a one-cycle delay
      if (i < MAC_COUNT - 1) begin
        always @(posedge clk or negedge rst_n) begin
          if (!rst_n)begin
            En_prop[i+1] <= 1'b0;  // Reset enable
			B_prop[i+1] <= 1'b0;
		  end	
          else begin
            En_prop[i+1] <= En_prop[i];  // Delay enable by one cycle
			B_prop[i+1] <= B_prop[i];
		  end	
        end
      end
    end
  endgenerate



endmodule
