// File:        sb_apb_regs.sv
// Author:      Isaac Hagedorn
// Date:        2026-10-08
// Description: APB4 completer with seven 32-bit registers, a down-counting timer (one-shot or auto-reload) and a level interrupt. Reads of TIMER_VALUE take one wait state; unmapped addresses and writes to read-only registers complete with pslverr.

module sb_apb_regs #(
  parameter int ADDR_W = 8,    // paddr width (byte address)
  parameter int DATA_W = 32    // pwdata / prdata width (must be 32)
) (
  input  logic                pclk,
  input  logic                presetn,    // async assert, sync deassert

  // APB4 completer
  input  logic                psel,
  input  logic                penable,
  input  logic                pwrite,
  input  logic [ADDR_W-1:0]   paddr,      // byte address; [1:0] ignored
  input  logic [DATA_W-1:0]   pwdata,
  input  logic [DATA_W/8-1:0] pstrb,      // byte lane write enables
  output logic [DATA_W-1:0]   prdata,
  output logic                pready,
  output logic                pslverr,

  output logic                irq         // |(INT_STATUS & INT_ENABLE)
);

  localparam int                STRB_W   = DATA_W / 8;
  localparam int                IDX_W    = ADDR_W - 2;     // word index width
  localparam int                STS_W    = 2;              // INT_STATUS / INT_ENABLE bits
  localparam int                TMR      = 0;              // INT_STATUS bit: timer expired
  localparam int                ERR      = 1;              // INT_STATUS bit: access error
  localparam logic [DATA_W-1:0] ID_VALUE = 32'h5342_4150;  // "SBAP"

  // Parameter checks
  if (DATA_W != 32) begin : g_bad_data
    $error("sb_apb_regs: DATA_W must be 32 (got %0d)", DATA_W);
  end
  if (ADDR_W < 5) begin : g_bad_addr
    $error("sb_apb_regs: ADDR_W must be >= 5 to hold the register map (got %0d)", ADDR_W);
  end

  // Address decode: the word index paddr[ADDR_W-1:2] selects a register
  typedef enum logic [2:0] {
    SEL_ID, SEL_CTRL, SEL_SCRATCH, SEL_LOAD, SEL_VALUE, SEL_STATUS, SEL_ENABLE, SEL_NONE
  } sel_e;

  sel_e sel;       // register addressed by paddr
  logic unused;    // paddr[1:0] is ignored

  assign unused = ^paddr[1:0];

  always_comb begin
    unique case (paddr[ADDR_W-1:2])
      IDX_W'(0): sel = SEL_ID;         // 0x00
      IDX_W'(1): sel = SEL_CTRL;       // 0x04
      IDX_W'(2): sel = SEL_SCRATCH;    // 0x08
      IDX_W'(3): sel = SEL_LOAD;       // 0x0C
      IDX_W'(4): sel = SEL_VALUE;      // 0x10
      IDX_W'(5): sel = SEL_STATUS;     // 0x14
      IDX_W'(6): sel = SEL_ENABLE;     // 0x18
      default:   sel = SEL_NONE;
    endcase
  end

  // APB phases, wait state and error response
  logic access;     // access phase
  logic rd_wait;    // first access cycle of a TIMER_VALUE read: pready low
  logic wait_q;     // the TIMER_VALUE wait state has been inserted
  logic xfer;       // a transfer completes at this edge
  logic err;        // the addressed access is an error
  logic wr_en;      // a write takes effect at this edge
  logic rd_en;      // a read completes without error at this edge

  assign access  = psel && penable;
  assign rd_wait = access && !pwrite && (sel == SEL_VALUE) && !wait_q;
  assign pready  = !rd_wait;
  assign xfer    = access && pready;
  assign err     = (sel == SEL_NONE) || (pwrite && (sel == SEL_ID || sel == SEL_VALUE));
  assign pslverr = xfer && err;
  assign wr_en   = xfer && pwrite && !err;
  assign rd_en   = xfer && !pwrite && !err;

  // Byte lane mask from pstrb
  logic [DATA_W-1:0] wmask;

  always_comb begin
    for (int i = 0; i < STRB_W; i++) wmask[i*8 +: 8] = {8{pstrb[i]}};
  end

  // Registers
  logic              ctrl_en;       // CTRL.EN
  logic              ctrl_reload;   // CTRL.RELOAD
  logic [DATA_W-1:0] scratch;       // SCRATCH
  logic [DATA_W-1:0] tmr_load;      // TIMER_LOAD
  logic [DATA_W-1:0] tmr_value;     // TIMER_VALUE (the counter)
  logic [DATA_W-1:0] value_snap;    // counter captured in the wait state of a TIMER_VALUE read
  logic [STS_W-1:0]  int_status;    // INT_STATUS
  logic [STS_W-1:0]  int_enable;    // INT_ENABLE

  logic ctrl_wr, scratch_wr, load_wr, status_wr, enable_wr;

  assign ctrl_wr    = wr_en && (sel == SEL_CTRL);
  assign scratch_wr = wr_en && (sel == SEL_SCRATCH);
  assign load_wr    = wr_en && (sel == SEL_LOAD) && (|pstrb);
  assign status_wr  = wr_en && (sel == SEL_STATUS);
  assign enable_wr  = wr_en && (sel == SEL_ENABLE);

  // Wait state: capture the counter, then complete one edge later
  always_ff @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      wait_q     <= 1'b0;
      value_snap <= '0;
    end else begin
      wait_q <= rd_wait;
      if (rd_wait) value_snap <= tmr_value;
    end
  end

  // Timer: a TIMER_LOAD write loads the counter; otherwise it counts down while enabled
  // and reloads from TIMER_LOAD at the edge where it is 0 (expiry)
  logic              expire;      // timer expires at this edge
  logic [DATA_W-1:0] load_next;   // TIMER_LOAD after the write

  assign expire    = ctrl_en && (tmr_value == '0) && !load_wr;
  assign load_next = (tmr_load & ~wmask) | (pwdata & wmask);

  always_ff @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      tmr_load  <= '0;
      tmr_value <= '0;
    end else if (load_wr) begin
      tmr_load  <= load_next;
      tmr_value <= load_next;
    end else if (expire) begin
      tmr_value <= tmr_load;
    end else if (ctrl_en) begin
      tmr_value <= tmr_value - DATA_W'(1);
    end
  end

  // CTRL: a write (byte lane 0) wins over the one-shot stop at expiry
  always_ff @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      ctrl_en     <= 1'b0;
      ctrl_reload <= 1'b0;
    end else if (ctrl_wr && pstrb[0]) begin
      ctrl_en     <= pwdata[0];
      ctrl_reload <= pwdata[1];
    end else if (expire && !ctrl_reload) begin
      ctrl_en     <= 1'b0;
    end
  end

  // SCRATCH
  always_ff @(posedge pclk or negedge presetn) begin
    if (!presetn)        scratch <= '0;
    else if (scratch_wr) scratch <= (scratch & ~wmask) | (pwdata & wmask);
  end

  // INT_ENABLE
  always_ff @(posedge pclk or negedge presetn) begin
    if (!presetn)                    int_enable <= '0;
    else if (enable_wr && pstrb[0])  int_enable <= pwdata[STS_W-1:0];
  end

  // INT_STATUS: set by hardware, write-1-to-clear
  logic [STS_W-1:0] sts_set;   // bits set at this edge
  logic [STS_W-1:0] sts_clr;   // bits cleared at this edge

  always_comb begin
    sts_set      = '0;
    sts_set[TMR] = expire;
    sts_set[ERR] = pslverr;
  end

  assign sts_clr = (status_wr && pstrb[0]) ? pwdata[STS_W-1:0] : '0;

  always_ff @(posedge pclk or negedge presetn) begin
    if (!presetn) int_status <= '0;
    else          int_status <= (int_status & ~sts_clr) | sts_set;   // hardware set wins
  end

  // Read data
  logic [DATA_W-1:0] rdata;   // value of the addressed register

  always_comb begin
    unique case (sel)
      SEL_ID:      rdata = ID_VALUE;
      SEL_CTRL:    rdata = DATA_W'({ctrl_reload, ctrl_en});
      SEL_SCRATCH: rdata = scratch;
      SEL_LOAD:    rdata = tmr_load;
      SEL_VALUE:   rdata = value_snap;
      SEL_STATUS:  rdata = DATA_W'(int_status);
      SEL_ENABLE:  rdata = DATA_W'(int_enable);
      SEL_NONE:    rdata = '0;
    endcase
  end

  assign prdata = rd_en ? rdata : '0;
  assign irq    = |(int_status & int_enable);

endmodule
