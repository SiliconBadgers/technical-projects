// File:        cycle_tables_tb.sv
// Author:      Isaac Hagedorn
// Date:        2025-10-04
// Description: Prints the cycle tables in docs/spec/cycle_tables.md from the golden RTL. Run by gen_cycle_tables.sh.

module cycle_tables_tb;
  localparam int N = 4, DW = 8, AW = 32;
  logic clk = 0; always #5 clk = ~clk;
  logic rst_n = 0;
  logic wr_valid = 0, wr_ready; logic [2:0] wr_addr = 0; logic [N*DW-1:0] wr_data = 0;
  logic a_valid = 0, a_ready;  logic [N*DW-1:0] a_data = 0;
  logic r_valid, r_ready = 1;  logic [N*AW-1:0] r_data; logic busy;
  sb_systolic_array #(.N(N)) dut (.*);

  int edge_no; bit on;
  clocking cb @(posedge clk); default input #1step;
    input rst_n, wr_valid, wr_ready, wr_addr, a_valid, a_ready, a_data, r_valid, r_ready, r_data, busy;
  endclocking

  function automatic string vec8(logic [N*DW-1:0] d);
    string s = "[";
    for (int i = 0; i < N; i++) begin
      logic signed [DW-1:0] e = d[i*DW +: DW];
      s = {s, $sformatf("%0d%s", e, i == N-1 ? "]" : ",")};
    end
    return s;
  endfunction
  function automatic string vec32(logic [N*AW-1:0] d);
    string s = "[";
    for (int i = 0; i < N; i++) begin
      logic signed [AW-1:0] e = d[i*AW +: AW];
      s = {s, $sformatf("%0d%s", e, i == N-1 ? "]" : ",")};
    end
    return s;
  endfunction
  function automatic string hs(logic v, logic r); return (v && r) ? " **xfer**" : ""; endfunction

  always @(cb) if (on) begin
    $display("| %0d | %0b | %0b | %0b%s | %s | %0b | %0b%s | %s | %0b | %0b%s | %s | %0b |",
      edge_no, cb.rst_n,
      cb.a_valid, cb.a_ready, hs(cb.a_valid, cb.a_ready), cb.a_valid ? vec8(cb.a_data) : "",
      cb.wr_valid, cb.wr_ready, hs(cb.wr_valid, cb.wr_ready), cb.wr_valid ? $sformatf("%0d", cb.wr_addr) : "",
      cb.r_ready, cb.r_valid, hs(cb.r_valid, cb.r_ready), cb.r_valid ? vec32(cb.r_data) : "",
      cb.busy);
    edge_no++;
  end

  task automatic table_start(string title);
    $display("\n### %s\n", title);
    $display("| edge | rst_n | a_valid | a_ready | a_data | wr_valid | wr_ready | wr_addr | r_ready | r_valid | r_data | busy |");
    $display("|---:|:-:|:-:|:-:|---|:-:|:-:|:-:|:-:|:-:|---|:-:|");
    edge_no = 0; on = 1;
  endtask
  task automatic table_end(); @(negedge clk); on = 0; endtask
  task automatic nedge(int n = 1); repeat (n) @(negedge clk); endtask

  task automatic write_row(int a, logic [N*DW-1:0] d);
    @(negedge clk); wr_valid = 1; wr_addr = a; wr_data = d;
    do @(posedge clk); while (!wr_ready);
    @(negedge clk); wr_valid = 0;
  endtask

  initial begin
    nedge(3); rst_n = 1; nedge(2);
    // W = rows 1,2,3,4 (row m: every element m+1)
    for (int m = 0; m < N; m++) write_row(m, {4{8'(m + 1)}});
    nedge(12);

    table_start("T1. One activation (SA-R17)");
    @(negedge clk); a_valid = 1; a_data = {8'sd4, 8'sd3, 8'sd2, 8'sd1};
    nedge(); a_valid = 0;
    nedge(8);
    nedge(2); table_end();

    nedge(4);
    table_start("T2. Write after an activation (SA-R09)");
    @(negedge clk); a_valid = 1; a_data = {4{8'sd1}};
    nedge(); a_valid = 0; wr_valid = 1; wr_addr = 0; wr_data = {4{8'sd5}};
    nedge(7);
    nedge();
    nedge(); wr_valid = 0; nedge(3); table_end();
    // restore row 0
    write_row(0, {4{8'sd1}}); nedge(12);

    table_start("T3. Write and activation offered together (SA-R09, SA-R14)");
    @(negedge clk); a_valid = 1; a_data = {4{8'sd1}}; wr_valid = 1; wr_addr = 0; wr_data = {4{8'sd7}};
   
    nedge(); a_valid = 0;
    nedge(8);
    nedge(); wr_valid = 0;
    nedge(3); table_end();
    write_row(0, {4{8'sd1}}); nedge(12);

    table_start("T4. Stream with r_ready low (SA-R11)");
    r_ready = 0;
    @(negedge clk); a_valid = 1; a_data = {4{8'sd1}};
    for (int i = 0; i < 16; i++) begin
      nedge();
      if (cb.a_valid && cb.a_ready) a_data = a_data + 32'h01010101;   // next vector after a transfer
      if (i == 13) r_ready = 1;
    end
    a_valid = 0; nedge(2); table_end();
    nedge(30);

    table_start("T5. Reset during traffic (SA-R01..R04)");
    @(negedge clk); a_valid = 1; a_data = {4{8'sd1}};
    nedge(2); a_valid = 0;
    #2 rst_n = 0;                                      // assert mid-cycle
    nedge();
    nedge();
    @(posedge clk); #1 rst_n = 1;                      // release just after an edge
    @(negedge clk);
    nedge(); a_valid = 1; a_data = {4{8'sd1}};
    nedge(); a_valid = 0; nedge(10); table_end();
    $finish;
  end
endmodule
