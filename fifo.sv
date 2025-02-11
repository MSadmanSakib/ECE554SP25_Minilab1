module FIFO
#(
  parameter DEPTH=8,
  parameter DATA_WIDTH=8
)
(
  input  clk,
  input  rst_n,
  input  rden,
  input  wren,
  input  [DATA_WIDTH-1:0] i_data,
  output logic [DATA_WIDTH-1:0] o_data,
  output logic full,
  output logic empty
);

  logic [DATA_WIDTH-1:0] mem_array [0:DEPTH-1];
  logic [DEPTH-1:0] rd_ptr, wr_ptr;
  logic [DEPTH-1:0] curr_count;

  assign full = (curr_count == DEPTH);
  assign empty = (curr_count == 0);

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      rd_ptr <= 0;
      wr_ptr <= 0;
      curr_count <= 0;
    end else begin
      if (wren && !full) begin
        mem_array[wr_ptr] <= i_data;
        wr_ptr <= wr_ptr + 1;
        curr_count <= curr_count + 1;
      end
      if (rden && !empty) begin
        o_data <= mem_array[rd_ptr];
        rd_ptr <= rd_ptr + 1;
        curr_count <= curr_count - 1;
      end
    end
  end

endmodule