// File:        sb_systolic_array.sv
// Author:      Isaac Hagedorn
// Date:        2025-02-22
// Description: N x N weight-stationary int8 systolic array with WR, A and R ready/valid channels. Returns y = x * W (optional ReLU) for every accepted activation vector, in order.

module sb_systolic_array #(
  parameter int N      = 4,   // array is N x N
  parameter int DATA_W = 8,   // activation / weight width (signed)
  parameter int ACC_W  = 32   // result element width (signed)
) (
  input  logic                clk,
  input  logic                rst_n,      // async assert, sync deassert

  // WR channel: weight rows (addr 0..N-1) and CTRL (addr N)
  input  logic                wr_valid,
  output logic                wr_ready,
  input  logic [$clog2(N+1)-1:0] wr_addr,
  input  logic [N*DATA_W-1:0] wr_data,

  // A channel: activation vector, lane m at [m*DATA_W +: DATA_W]
  input  logic                a_valid,
  output logic                a_ready,
  input  logic [N*DATA_W-1:0] a_data,

  // R channel: result vector, lane n at [n*ACC_W +: ACC_W]
  output logic                r_valid,
  input  logic                r_ready,
  output logic [N*ACC_W-1:0]  r_data,

  output logic                busy        // results outstanding
);

  localparam int ADDR_W    = $clog2(N + 1);
  localparam int PIPE      = 2 * N;          // cycles from A handshake to FIFO push
  localparam int DEPTH     = 2 * N + 2;      // max outstanding results
  localparam int CNT_W     = $clog2(DEPTH + 1);
  localparam int ADDR_CTRL = N;

  // Parameter checks
  if (N < 2) begin : g_bad_n
    $error("sb_systolic_array: N must be >= 2 (got %0d)", N);
  end
  if (ACC_W < 2 * DATA_W + $clog2(N)) begin : g_bad_acc
    $error("sb_systolic_array: ACC_W=%0d cannot hold N*(-2^(DATA_W-1))^2", ACC_W);
  end

  // Handshakes and flow control
  logic             ready_en;     // low during reset and the first cycle after
  logic [PIPE:1]    vld;          // vld[k]: an activation was accepted k cycles ago
  logic             pipe_busy;    // an activation is in the pipeline
  logic [CNT_W-1:0] out_cnt;      // accepted but not yet delivered on R
  logic             a_fire, wr_fire, r_fire, push;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) ready_en <= 1'b0;
    else        ready_en <= 1'b1;
  end

  assign pipe_busy = |vld;

  assign a_ready  = ready_en && (out_cnt < CNT_W'(DEPTH));
  assign a_fire   = a_valid && a_ready;

  assign wr_ready = ready_en && !pipe_busy && !a_fire;
  assign wr_fire  = wr_valid && wr_ready;

  assign r_fire   = r_valid && r_ready;
  assign push     = vld[PIPE];
  assign busy     = (out_cnt != '0);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      vld     <= '0;
      out_cnt <= '0;
    end else begin
      vld <= {vld[PIPE-1:1], a_fire};
      case ({a_fire, r_fire})
        2'b10:   out_cnt <= out_cnt + 1'b1;
        2'b01:   out_cnt <= out_cnt - 1'b1;
        default: out_cnt <= out_cnt;
      endcase
    end
  end

  // Write port: weight registers and CTRL
  logic signed [DATA_W-1:0] w [N][N];   // weight W[m][n] for PE(m,n)
  logic                     cfg_relu;   // CTRL.RELU_EN

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (int m = 0; m < N; m++)
        for (int n = 0; n < N; n++)
          w[m][n] <= '0;
      cfg_relu <= 1'b0;
    end else if (wr_fire) begin
      for (int m = 0; m < N; m++)
        if (wr_addr == ADDR_W'(m))
          for (int n = 0; n < N; n++)
            w[m][n] <= wr_data[n*DATA_W +: DATA_W];
      if (wr_addr == ADDR_W'(ADDR_CTRL))
        cfg_relu <= wr_data[0];
    end
  end

  // Input register and skew: row m is delayed m cycles
  logic signed [DATA_W-1:0] x_q    [N];   // registered activation (0 when idle)
  logic signed [DATA_W-1:0] row_in [N];   // skewed input to PE(m,0)

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (int m = 0; m < N; m++) x_q[m] <= '0;
    end else begin
      for (int m = 0; m < N; m++) x_q[m] <= a_fire ? a_data[m*DATA_W +: DATA_W] : '0;
    end
  end

  for (genvar m = 0; m < N; m++) begin : g_skew
    if (m == 0) begin : g_none
      assign row_in[m] = x_q[m];
    end else begin : g_sr
      logic signed [DATA_W-1:0] sr [m];
      always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
          for (int k = 0; k < m; k++) sr[k] <= '0;
        end else begin
          sr[0] <= x_q[m];
          for (int k = 1; k < m; k++) sr[k] <= sr[k-1];
        end
      end
      assign row_in[m] = sr[m-1];
    end
  end

  // PE grid
  logic signed [DATA_W-1:0] a_h [N][N+1];   // activation entering PE(m,n) from the west
  logic signed [ACC_W-1:0]  p_v [N+1][N];   // partial sum entering PE(m,n) from the north

  for (genvar m = 0; m < N; m++) begin : g_row
    assign a_h[m][0] = row_in[m];
    for (genvar n = 0; n < N; n++) begin : g_col
      if (m == 0) begin : g_top
        assign p_v[0][n] = '0;
      end
      sb_sa_pe #(.DATA_W(DATA_W), .ACC_W(ACC_W)) u_pe (
        .clk      (clk),
        .rst_n    (rst_n),
        .w        (w[m][n]),
        .in_a     (a_h[m][n]),
        .in_psum  (p_v[m][n]),
        .out_a    (a_h[m][n+1]),
        .out_psum (p_v[m+1][n])
      );
    end
  end

  // Deskew: column n is delayed N-1-n cycles
  logic signed [ACC_W-1:0] col_out [N];   // aligned column results

  for (genvar n = 0; n < N; n++) begin : g_deskew
    if (n == N - 1) begin : g_none
      assign col_out[n] = p_v[N][n];
    end else begin : g_sr
      logic signed [ACC_W-1:0] sr [N-1-n];
      always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
          for (int k = 0; k < N - 1 - n; k++) sr[k] <= '0;
        end else begin
          sr[0] <= p_v[N][n];
          for (int k = 1; k < N - 1 - n; k++) sr[k] <= sr[k-1];
        end
      end
      assign col_out[n] = sr[N-2-n];
    end
  end

  // ReLU and result FIFO
  logic [N*ACC_W-1:0] push_data;   // result after ReLU
  logic               fifo_empty;

  always_comb begin
    for (int n = 0; n < N; n++)
      push_data[n*ACC_W +: ACC_W] = (cfg_relu && col_out[n] < 0) ? '0 : col_out[n];
  end

  sb_sa_fifo #(.WIDTH(N * ACC_W), .DEPTH(DEPTH)) u_fifo (
    .clk       (clk),
    .rst_n     (rst_n),
    .push      (push),
    .push_data (push_data),
    .pop       (r_fire),
    .head      (r_data),
    .empty     (fifo_empty)
  );

  assign r_valid = !fifo_empty;

endmodule
