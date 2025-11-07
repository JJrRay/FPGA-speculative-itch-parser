# ============================================================
# test_parser_canonical.py
# ============================================================
#
# Description: Cocotb testbench validating speculative parser using parser-level headers.
#              Performs stream injection, records field-wise parsed outputs, and
#              compares against scheduled expectations. Generates CSV output logs.
# Author: RZ
# Start Date: 20250506
# Version: 0.4
#
# Changelog
# ============================================================
# [20250506-1] RZ: Created parser-level output validation testbench with CSV logging.
# [20250506-2] RZ: Added expected events generation and comparison logic.
# [20250506-3] RZ: Implemented CSV output for recorded log and expected events.
# [20250507-1] RZ: Refactored code for clarity and modularity.
# ============================================================


import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
import csv

from helpers.reset_helper import reset_dut
from helpers.recorder import get_recorded_log
from helpers.full_workload_helper import run_full_payload_workload
from helpers.compare_helper import compare_against_expected, generate_expected_events_from_schedule
from sim_config import SIM_CLK_PERIOD_NS, MSG_SEQUENCE, SIM_CYCLES, RESET_CYCLES
from ITCH_config import PARSER_HEADERS
from helpers.recorder_parser import record_parser_outputs


@cocotb.test()
async def test_parser_output(dut):
    dut._log.info("Starting parser arbitration test")

    cocotb.start_soon(Clock(dut.clk, SIM_CLK_PERIOD_NS, units="ns").start())

    dut.valid_in.value = 0
    dut.byte_in.value = 0


    await reset_dut(dut)

    result = run_full_payload_workload(MSG_SEQUENCE)
    full_stream = result["full_stream"]
    injection_schedule = result["injection_schedule"]
    expected_events = generate_expected_events_from_schedule(injection_schedule, parser_mode=True)

    
    cocotb.start_soon(record_parser_outputs(dut, total_cycles=SIM_CYCLES))

    for byte in full_stream:
        dut.valid_in.value = 1
        dut.byte_in.value = byte
        await RisingEdge(dut.clk)
    dut.valid_in.value = 0

    for _ in range(20):
        await RisingEdge(dut.clk)

    recorded_log = get_recorded_log()

    with open("parser_recorded_log.csv", "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=PARSER_HEADERS)
        writer.writeheader()
        for cycle in sorted(recorded_log):
            row = {"cycle": cycle}
            row.update(recorded_log[cycle])
            writer.writerow(row)

    with open("parser_expected_events.csv", "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=PARSER_HEADERS)
        writer.writeheader()
        for event in expected_events:
            writer.writerow(event)

    compare_against_expected(recorded_log, expected_events)