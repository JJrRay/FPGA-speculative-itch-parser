# ============================================================
# test_valid_drop_abort.py
# ============================================================
#
# Description: Unit testbench for decoder resilience to mid-packet `valid_in` drop.
#              Verifies clean message abortion and correct parsing of subsequent message.
#              Focused on stability of speculative decoder under stream interruption.
# Author: RZ
# Start Date: 20250507
# Version: 0.1
#
# Changelog
# ============================================================
# [20250507-1] RZ: Added test for mid-stream valid drop and message recovery.
# ============================================================


import cocotb
from cocotb.triggers import RisingEdge, Timer
from cocotb.clock import Clock
from cocotb.result import TestFailure


@cocotb.test()
async def test_valid_drop_aborts_message(dut):
    """Test that mid-packet valid_in drop aborts the current message cleanly."""

    # Start clock
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    # Reset
    dut.rst.value = 1
    dut.valid_in.value = 0
    dut.byte_in.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst.value = 0

    # Define message: 'D' message (Delete Order), 9 bytes
    first_byte = ord('D')
    dummy_payload = [first_byte] + [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08]

    # === Inject only 4 bytes ===
    for i in range(4):
        dut.valid_in.value = 1
        dut.byte_in.value = dummy_payload[i]
        await RisingEdge(dut.clk)

    # === Mid-packet valid_in drop ===
    dut.valid_in.value = 0
    dut.byte_in.value = 0
    await RisingEdge(dut.clk)

    # === Inject a full valid message ===
    for i in range(len(dummy_payload)):
        dut.valid_in.value = 1
        dut.byte_in.value = dummy_payload[i]
        await RisingEdge(dut.clk)

    # Drop valid after message
    dut.valid_in.value = 0
    dut.byte_in.value = 0

    # Wait a few cycles to allow latched_valid to assert
    for _ in range(3):
        await RisingEdge(dut.clk)

    # === Check results ===
    if not dut.latched_valid.value:
        raise TestFailure("Expected latched_valid to assert after second full message.")
    
    if dut.latched_order_ref.value.integer != 0x0102030405060708:
        raise TestFailure(f"Unexpected latched_order_ref: got {hex(dut.latched_order_ref.value.integer)}")

    dut._log.info("Mid-packet drop correctly aborted first message. Second message parsed cleanly.")
