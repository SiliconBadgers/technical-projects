// File:        sb_sa_fifo.sv
// Author:      Isaac Hagedorn
// Date:        2025-01-11
// Description: Result FIFO of sb_systolic_array. Flop-based, show-ahead head, any DEPTH.

module sb_sa_fifo #(
  parameter int WIDTH = 128,
  parameter int DEPTH = 10
) (
  input  logic             clk,
  input  logic             rst_n,
  input  logic             push,
  input  logic [WIDTH-1:0] push_data,
  input  logic             pop,
  output logic [WIDTH-1:0] head,        // oldest entry
  output logic             empty
);

  localparam int PTR_W = (DEPTH > 1) ? $clog2(DEPTH) : 1;
  localparam int CNT_W = $clog2(DEPTH + 1);

  logic [WIDTH-1:0] mem [DEPTH];        // storage (not reset)
  logic [PTR_W-1:0] wr_ptr, rd_ptr;
  logic [CNT_W-1:0] count;              // entries stored

  // Pointer increment with wrap at DEPTH-1.
  function automatic logic [PTR_W-1:0] next_ptr(input logic [PTR_W-1:0] p);
    return (p == PTR_W'(DEPTH - 1)) ? '0 : p + 1'b1;
  endfunction

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr <= '0;
      rd_ptr <= '0;
      count  <= '0;
    end else begin
      if (push) wr_ptr <= next_ptr(wr_ptr);
      if (pop)  rd_ptr <= next_ptr(rd_ptr);
      case ({push, pop})
        2'b10:   count <= count + 1'b1;
        2'b01:   count <= count - 1'b1;
        default: count <= count;
      endcase
    end
  end

  always_ff @(posedge clk) begin
    if (push) mem[wr_ptr] <= push_data;
  end

  assign head  = mem[rd_ptr];
  assign empty = (count == '0);

endmodule
