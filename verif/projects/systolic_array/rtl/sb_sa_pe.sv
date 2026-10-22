// File:        sb_sa_pe.sv
// Author:      Isaac Hagedorn
// Date:        2024-11-23
// Description: Processing element of sb_systolic_array. Passes the activation east and adds activation * weight to the partial sum passed south.

module sb_sa_pe #(
  parameter int DATA_W = 8,
  parameter int ACC_W  = 32
) (
  input  logic                     clk,
  input  logic                     rst_n,
  input  logic signed [DATA_W-1:0] w,         // stationary weight
  input  logic signed [DATA_W-1:0] in_a,      // activation from the west
  input  logic signed [ACC_W-1:0]  in_psum,   // partial sum from the north
  output logic signed [DATA_W-1:0] out_a,     // activation to the east
  output logic signed [ACC_W-1:0]  out_psum   // partial sum to the south
);

  logic signed [2*DATA_W-1:0] prod;           // signed product
  assign prod = in_a * w;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      out_a    <= '0;
      out_psum <= '0;
    end else begin
      out_a    <= in_a;
      out_psum <= in_psum + ACC_W'(prod);
    end
  end

endmodule
