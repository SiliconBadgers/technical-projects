# File:        test_ibex.py
# Author:      Isaac Hagedorn
# Date:        2026-10-08
# Description: cocotb smoke test for ibex_core: runs a short RV32IM program and checks memory.

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, ReadOnly, RisingEdge

CLK_NS = 10
BOOT_ADDR = 0x0000_0000   # ibex starts fetching at boot_addr + 0x80
DATA_BASE = 0x100
MAX_CYCLES = 3000

# --- tiny RV32 encoder ---
def r_type(funct7, rs2, rs1, funct3, rd, opcode):
    return (funct7 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode

def i_type(imm, rs1, funct3, rd, opcode):
    return ((imm & 0xFFF) << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode

def s_type(imm, rs2, rs1, funct3):
    imm &= 0xFFF
    return ((imm >> 5) << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | ((imm & 0x1F) << 7) | 0x23

def b_type(offset, rs2, rs1, funct3):
    o = offset & 0x1FFF
    return (((o >> 12) & 1) << 31) | (((o >> 5) & 0x3F) << 25) | (rs2 << 20) | (rs1 << 15) \
        | (funct3 << 12) | (((o >> 1) & 0xF) << 8) | (((o >> 11) & 1) << 7) | 0x63

def addi(rd, rs1, imm): return i_type(imm, rs1, 0, rd, 0x13)
def add(rd, rs1, rs2):  return r_type(0, rs2, rs1, 0, rd, 0x33)
def mul(rd, rs1, rs2):  return r_type(1, rs2, rs1, 0, rd, 0x33)   # RV32M
def lw(rd, rs1, imm):   return i_type(imm, rs1, 2, rd, 0x03)
def sw(rs2, rs1, imm):  return s_type(imm, rs2, rs1, 2)
def sb(rs2, rs1, imm):  return s_type(imm, rs2, rs1, 0)
def bne(rs1, rs2, off): return b_type(off, rs2, rs1, 1)
def lui(rd, imm20):     return ((imm20 & 0xFFFFF) << 12) | (rd << 7) | 0x37
def jal(rd, off):
    o = off & 0x1FFFFF
    return (((o >> 20) & 1) << 31) | (((o >> 1) & 0x3FF) << 21) | (((o >> 11) & 1) << 20) \
        | (((o >> 12) & 0xFF) << 12) | (rd << 7) | 0x6F

PROGRAM = [
    addi(1, 0, 0),            # x1 = 0        (sum)
    addi(2, 0, 1),            # x2 = 1        (i)
    addi(3, 0, 11),           # x3 = 11
    add(1, 1, 2),             # loop: x1 += x2
    addi(2, 2, 1),            #       x2 += 1
    bne(2, 3, -8),            #       while x2 != 11
    addi(4, 0, DATA_BASE),    # x4 = 0x100
    sw(1, 4, 0),              # mem[0x100] = 55
    lw(5, 4, 0),              # x5 = mem[0x100]
    mul(6, 5, 5),             # x6 = 55 * 55 = 3025
    sw(6, 4, 4),              # mem[0x104] = 3025
    lui(7, 0x12345),          # x7 = 0x12345000
    addi(7, 7, 0x678),        # x7 = 0x12345678
    sb(7, 4, 9),              # byte 0x78 -> mem[0x109] (lane 1 of word 0x108)
    sw(7, 4, 12),             # mem[0x10c] = 0x12345678  (written last: "done")
    jal(0, 0),                # spin here
]
EXPECTED = {0x100: 55, 0x104: 3025, 0x108: 0x0000_7800, 0x10C: 0x1234_5678}


class Memory:
    def __init__(self):
        self.words = {}

    def load_program(self, base, words):
        for i, w in enumerate(words):
            self.words[base + 4 * i] = w

    def read(self, addr):
        return self.words.get(addr & ~3, 0)

    def write(self, addr, data, be):
        word = self.read(addr)
        for lane in range(4):
            if (be >> lane) & 1:
                mask = 0xFF << (8 * lane)
                word = (word & ~mask) | (data & mask)
        self.words[addr & ~3] = word


async def run_memory(dut, mem, writes):
    """Serve the instruction and data ports; record every data write."""
    instr_pending = None    # address accepted at the last rising edge
    data_pending = None     # (is_write, address)
    while True:
        await FallingEdge(dut.clk_i)
        # Responses to requests accepted at the last rising edge.
        dut.instr_rvalid_i.value = int(instr_pending is not None)
        dut.instr_rdata_i.value = mem.read(instr_pending) if instr_pending is not None else 0
        dut.data_rvalid_i.value = int(data_pending is not None)
        dut.data_rdata_i.value = mem.read(data_pending[1]) if data_pending and not data_pending[0] else 0
        # Requests for the next rising edge (gnt is always 1).
        await ReadOnly()
        instr_pending = int(dut.instr_addr_o.value) if int(dut.instr_req_o.value) else None
        data_pending = None
        if int(dut.data_req_o.value):
            addr = int(dut.data_addr_o.value)
            we = int(dut.data_we_o.value)
            if we:
                be, wdata = int(dut.data_be_o.value), int(dut.data_wdata_o.value)
                mem.write(addr, wdata, be)
                writes.append((addr & ~3, be, wdata))
            data_pending = (bool(we), addr)


async def reset(dut):
    for name, val in [("test_en_i", 0), ("hart_id_i", 0), ("boot_addr_i", BOOT_ADDR),
                      ("instr_gnt_i", 1), ("instr_rvalid_i", 0), ("instr_rdata_i", 0), ("instr_err_i", 0),
                      ("data_gnt_i", 1), ("data_rvalid_i", 0), ("data_rdata_i", 0), ("data_err_i", 0),
                      ("irq_software_i", 0), ("irq_timer_i", 0), ("irq_external_i", 0),
                      ("irq_fast_i", 0), ("irq_nm_i", 0), ("debug_req_i", 0), ("fetch_enable_i", 1)]:
        getattr(dut, name).value = val
    dut.rst_ni.value = 0            # asynchronous, active-low reset
    for _ in range(5):
        await RisingEdge(dut.clk_i)
    await FallingEdge(dut.clk_i)
    dut.rst_ni.value = 1


@cocotb.test()
async def test_program(dut):
    """Run PROGRAM from boot_addr + 0x80 and check what it stored."""
    cocotb.start_soon(Clock(dut.clk_i, CLK_NS, unit="ns").start())
    mem = Memory()
    mem.load_program(BOOT_ADDR + 0x80, PROGRAM)
    writes = []
    await reset(dut)
    cocotb.start_soon(run_memory(dut, mem, writes))

    for cycle in range(MAX_CYCLES):
        await RisingEdge(dut.clk_i)
        if any(addr == 0x10C for addr, _, _ in writes):
            break
    else:
        raise AssertionError(f"program did not finish in {MAX_CYCLES} cycles; data writes: "
                             + ", ".join(f"{a:#x}/{b:04b}/{d:#010x}" for a, b, d in writes))
    dut._log.info("program finished after %d cycles", cycle + 1)

    for addr, want in EXPECTED.items():
        got = mem.read(addr)
        assert got == want, f"mem[{addr:#x}] = {got:#010x}, expected {want:#010x}"
    assert int(dut.alert_major_o.value) == 0, "ibex raised alert_major_o"
