# ============================================================
# recorder.py
# ============================================================
#
# Description: Logs signal values on every simulation cycle for debugging.
#              Supports structured output to list-of-dictionaries format.
#              Used by all decoder testbenches in benchmarking mode.
# Author: RZ
# Start Date: 20250506
# Version: 0.2
#
# Changelog
# ============================================================
# [20250506-1] RZ: Implemented signal recorder for full-cycle logging.
# [20250507-1] RZ: Updated for parser testbench.
# ============================================================


import cocotb
from cocotb.triggers import RisingEdge
from cocotb.utils import get_sim_time

from sim_config import SIM_CLK_PERIOD_NS
from ITCH_config import SIM_HEADERS

_recorded_log = {}  # Global dictionary to store cycle-indexed logs

def get_recorded_log():
    return _recorded_log

async def record_all_internal_valids(dut, total_cycles=300):
    global _recorded_log
    _recorded_log = {}  # Reset at the start

    await RisingEdge(dut.clk)
    # dut._log.info("=== Full Signal Dump ===")

    for _ in range(total_cycles):
        await RisingEdge(dut.clk)
        sim_time = get_sim_time('ns')
        abs_cycle = sim_time // SIM_CLK_PERIOD_NS

        # Extract signals and default to 0 if not present
        row = {

            "cycle": abs_cycle,

            "add_internal_valid":       int(dut.add_internal_valid.value),
            "cancel_internal_valid":    int(dut.cancel_internal_valid.value),
            "delete_internal_valid":    int(dut.delete_internal_valid.value),
            "replace_internal_valid":   int(dut.replace_internal_valid.value),
            "executed_internal_valid":  int(dut.exec_internal_valid.value),
            "trade_internal_valid":     int(dut.trade_internal_valid.value),
            "add_mpid_internal_valid":  int(dut.add_mpid_internal_valid.value),
            "broken_internal_valid":    int(dut.broken_internal_valid.value),  # Fixed!
            "exec_price_internal_valid": int(dut.exec_price_internal_valid.value),  # Fixed!

            "add_order_ref":            hex(getattr(dut, 'add_order_ref', 0).value.integer)         if hasattr(dut, 'add_order_ref') else 0,
            "add_shares":               hex(getattr(dut, 'add_shares', 0).value.integer)            if hasattr(dut, 'add_shares') else 0,
            "add_side":                 hex(getattr(dut, 'add_side', 0).value.integer)              if hasattr(dut, 'add_side') else "",
            "add_price":                hex(getattr(dut, 'add_price', 0).value.integer)             if hasattr(dut, 'add_price') else 0,

            "cancel_order_ref":         hex(getattr(dut, 'cancel_order_ref', 0).value.integer)      if hasattr(dut, 'cancel_order_ref') else 0,
            "cancel_shares":            hex(getattr(dut, 'cancel_canceled_shares', 0).value.integer)if hasattr(dut, 'cancel_canceled_shares') else 0,

            "delete_order_ref":         hex(getattr(dut, 'delete_order_ref', 0).value.integer)      if hasattr(dut, 'delete_order_ref') else 0,
            
            "replace_old_order_ref":    hex(getattr(dut, 'replace_old_order_ref', 0).value.integer) if hasattr(dut, 'replace_old_order_ref') else 0,
            "replace_new_order_ref":    hex(getattr(dut, 'replace_new_order_ref', 0).value.integer) if hasattr(dut, 'replace_new_order_ref') else 0,
            "replace_shares":           hex(getattr(dut, 'replace_shares', 0).value.integer)        if hasattr(dut, 'replace_shares') else 0,
            "replace_price":            hex(getattr(dut, 'replace_price', 0).value.integer)         if hasattr(dut, 'replace_price') else 0,

            "exec_timestamp":           hex(getattr(dut, 'exec_timestamp', 0).value.integer)        if hasattr(dut, 'exec_timestamp') else 0,
            "exec_order_ref":           hex(getattr(dut, 'exec_order_ref', 0).value.integer)        if hasattr(dut, 'exec_order_ref') else 0,
            "exec_shares":              hex(getattr(dut, 'exec_shares', 0).value.integer)           if hasattr(dut, 'exec_shares') else 0,
            "exec_match_id":            hex(getattr(dut, 'exec_match_id', 0).value.integer)         if hasattr(dut, 'exec_match_id') else 0,
                
            "trade_timestamp":          hex(getattr(dut, 'trade_timestamp', 0).value.integer)       if hasattr(dut, 'trade_timestamp') else 0,
            "trade_order_ref":          hex(getattr(dut, 'trade_order_ref', 0).value.integer)       if hasattr(dut, 'trade_order_ref') else 0,
            "trade_side":               hex(getattr(dut, 'trade_side', 0).value.integer)            if hasattr(dut, 'trade_side') else 0,
            "trade_shares":             hex(getattr(dut, 'trade_shares', 0).value.integer)          if hasattr(dut, 'trade_shares') else 0,
            "trade_stock_symbol":       hex(getattr(dut, 'trade_stock_symbol', 0).value.integer)    if hasattr(dut, 'trade_stock_symbol') else 0,
            "trade_price":              hex(getattr(dut, 'trade_price', 0).value.integer)           if hasattr(dut, 'trade_price') else 0,
            "trade_match_id":           hex(getattr(dut, 'trade_match_id', 0).value.integer)        if hasattr(dut, 'trade_match_id') else 0,

            "add_mpid_order_ref":       hex(getattr(dut, 'add_mpid_order_ref', 0).value.integer) if hasattr(dut, 'add_mpid_order_ref') else 0,
            "add_mpid_shares":          hex(getattr(dut, 'add_mpid_shares', 0).value.integer) if hasattr(dut, 'add_mpid_shares') else 0,
            "add_mpid_price":           hex(getattr(dut, 'add_mpid_price', 0).value.integer) if hasattr(dut, 'add_mpid_price') else 0,
            "add_mpid_side":            hex(getattr(dut, 'add_mpid_side', 0).value.integer) if hasattr(dut, 'add_mpid_side') else "",
            "add_mpid_stock_symbol":    hex(getattr(dut, 'add_mpid_stock_symbol', 0).value.integer) if hasattr(dut, 'add_mpid_stock_symbol') else 0,
            "add_mpid_attribution":     hex(getattr(dut, 'add_mpid_attribution', 0).value.integer) if hasattr(dut, 'add_mpid_attribution') else 0,

            "broken_timestamp":         hex(getattr(dut, 'broken_timestamp', 0).value.integer) if hasattr(dut, 'broken_timestamp') else 0,  # Added!
            "broken_match_id":          hex(getattr(dut, 'broken_match_id', 0).value.integer) if hasattr(dut, 'broken_match_id') else 0,  # Fixed!

            "exec_price_timestamp":     hex(getattr(dut, 'exec_price_timestamp', 0).value.integer) if hasattr(dut, 'exec_price_timestamp') else 0,
            "exec_price_order_ref":     hex(getattr(dut, 'exec_price_order_ref', 0).value.integer) if hasattr(dut, 'exec_price_order_ref') else 0,
            "exec_price_shares":        hex(getattr(dut, 'exec_price_shares', 0).value.integer) if hasattr(dut, 'exec_price_shares') else 0,
            "exec_price_match_id":      hex(getattr(dut, 'exec_price_match_id', 0).value.integer) if hasattr(dut, 'exec_price_match_id') else 0,
            "exec_price_printable":     hex(getattr(dut, 'exec_price_printable', 0).value.integer) if hasattr(dut, 'exec_price_printable') else 0,
            "exec_price_price":         hex(getattr(dut, 'exec_price_price', 0).value.integer) if hasattr(dut, 'exec_price_price') else 0,

            "add_parsed_type":          hex(getattr(dut, 'add_parsed_type', 0).value.integer)       if hasattr(dut, 'add_parsed_type') else "",
            "cancel_parsed_type":       hex(getattr(dut, 'cancel_parsed_type', 0).value.integer)    if hasattr(dut, 'cancel_parsed_type') else "",
            "delete_parsed_type":       hex(getattr(dut, 'delete_parsed_type', 0).value.integer)    if hasattr(dut, 'delete_parsed_type') else "",
            "replace_parsed_type":      hex(getattr(dut, 'replace_parsed_type', 0).value.integer)   if hasattr(dut, 'replace_parsed_type') else "",
            "exec_parsed_type":         hex(getattr(dut, 'exec_parsed_type', 0).value.integer)      if hasattr(dut, 'exec_parsed_type') else "",
            "trade_parsed_type":        hex(getattr(dut, 'trade_parsed_type', 0).value.integer)     if hasattr(dut, 'trade_parsed_type') else "",
            "add_mpid_parsed_type":     hex(getattr(dut, 'add_mpid_parsed_type', 0).value.integer) if hasattr(dut, 'add_mpid_parsed_type') else "",
            "broken_parsed_type":       hex(getattr(dut, 'broken_parsed_type', 0).value.integer) if hasattr(dut, 'broken_parsed_type') else "",  # Fixed!
            "exec_price_parsed_type":   hex(getattr(dut, 'exec_price_parsed_type', 0).value.integer) if hasattr(dut, 'exec_price_parsed_type') else "",  # Fixed!

        }

        _recorded_log[abs_cycle] = row