# ============================================================
# recorder.py
# ============================================================
#
# Description: Logs signal values on every simulation cycle for debugging.
#              Supports structured output to list-of-dictionaries format.
#              Used by all decoder testbenches in benchmarking mode.
# Author: RZ
# Start Date: 20250507
# Version: 0.1
#
# Changelog
# ============================================================
# [20250507-1] RZ: Implemented signal recorder for full-cycle logging.
# ============================================================

import cocotb
from cocotb.triggers import RisingEdge
from cocotb.utils import get_sim_time

from sim_config import SIM_CLK_PERIOD_NS
from ITCH_config import PARSER_HEADERS

_recorded_log = {}

def get_recorded_log():
    return _recorded_log

async def record_parser_outputs(dut, total_cycles=300):
    global _recorded_log
    _recorded_log = {}

    await RisingEdge(dut.clk)

    for _ in range(total_cycles):
        await RisingEdge(dut.clk)
        sim_time = get_sim_time('ns')
        abs_cycle = sim_time // SIM_CLK_PERIOD_NS

        row = {
        "cycle": abs_cycle,
        "parsed_valid": int(dut.parsed_valid.value),
        "parsed_type": hex(dut.parsed_type.value.integer) if hasattr(dut, 'parsed_type') else "",

        "order_ref": hex(getattr(dut, 'order_ref', 0).value.integer) if hasattr(dut, 'order_ref') else "",
        "side": hex(getattr(dut, 'side', 0).value.integer) if hasattr(dut, 'side') else "",
        "shares": hex(getattr(dut, 'shares', 0).value.integer) if hasattr(dut, 'shares') else "",
        "price": hex(getattr(dut, 'price', 0).value.integer) if hasattr(dut, 'price') else "",
        "timestamp": hex(getattr(dut, 'timestamp', 0).value.integer) if hasattr(dut, 'timestamp') else "",
        "misc_data": hex(getattr(dut, 'misc_data', 0).value.integer) if hasattr(dut, 'misc_data') else "",
        }


        _recorded_log[abs_cycle] = row