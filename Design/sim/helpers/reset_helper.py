# =============================================
# ============================================================
# reset_helper.py
# ============================================================
#
# Description: Provides reset control utilities for simulation setup.
#              Supports clean module initialization and reset vector assertion.
#              Used by top-level and module-specific Cocotb testbenches.
# Author: RZ
# Start Date: 05042025
# Version: 0.4

# Changelog
# =============================================
# [20250504-1] RZ: Initial version (see reset_utils.py).
# [20250504-2] RZ: Added reset_and_test_decoder_behavior for decoder scenarios.
# [20250504-3] RZ: Adopted into new reset_helper.py from reset_utils.py.
# [20250507-1] RZ: Added reset_midstream utility for recovery tests.
# =============================================

import cocotb
from cocotb.triggers import RisingEdge
from cocotb.clock import Clock

async def start_clock(dut, period_ns=10):
    cocotb.start_soon(Clock(dut.clk, period_ns, units="ns").start())

async def reset_dut(dut, duration_clks=2):
    dut.rst.value = 1
    for _ in range(duration_clks):
        await RisingEdge(dut.clk)
    dut.rst.value = 0
    await RisingEdge(dut.clk)

async def reset_midstream(dut, trigger_cycle=2):
    dut.rst.value = 0
    for cycle in range(trigger_cycle):
        await RisingEdge(dut.clk)
    dut.rst.value = 1
    await RisingEdge(dut.clk)
    dut.rst.value = 0
    await RisingEdge(dut.clk)

