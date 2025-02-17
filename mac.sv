module MAC #
(
parameter DATA_WIDTH = 8
)
(
input clk,
input rst_n,
input En,
input Clr,
input [DATA_WIDTH-1:0] Ain,
input [DATA_WIDTH-1:0] Bin,
output logic [DATA_WIDTH*3-1:0] Cout
);

  // internal logic signals
 logic [DATA_WIDTH*3-1:0] accum, mult;
always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        accum <= 0;
		  mult <= 0;
    end
    else if (Clr) begin
        accum <= 0;
    end
    else if (En) begin
        if (Ain === 'x || Bin === 'x) begin
            accum <= 0; // Reset if inputs are unknown
				mult <= 0;
        end
        else begin
				mult <= (Ain * Bin);
            accum <= mult + accum;
        end
    end
end

  assign Cout = accum;



endmodule