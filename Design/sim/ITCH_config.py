# ============================================================
# ITCH_config.py
# ============================================================
#
# Description: Centralized configuration for ITCH message format and type lengths.
#              Used by both payload generators and validators.
#              Supports speculative parsing via static message length lookup.
# Author: RZ
# Start Date: 20250505
MSG_LENGTHS = {
    "add": 36,
    "cancel": 23,
    "replace": 27,
    "delete": 9,
    "executed": 30,
    "trade": 40,
    "add_mpid": 40,      # F - Add Order MPID Attribution
    "broken_trade": 19,  # B - Broken Trade
    "executed_price": 36 # C - Executed Order With Price
}



# Define common headers to enforce identical CSV structure
SIM_HEADERS = [
    "cycle",
    
    "add_internal_valid",
    "cancel_internal_valid",
    "delete_internal_valid",
    "replace_internal_valid",
    "executed_internal_valid",
    "trade_internal_valid",
    "add_mpid_internal_valid",
    "broken_internal_valid",           # ← matches Verilog
    "exec_price_internal_valid",       # ← matches Verilog
    
    "add_order_ref",
    "add_shares",
    "add_price",
    "add_side",
    
    "cancel_order_ref",
    "cancel_shares",
        
    "delete_order_ref",
    
    "replace_old_order_ref",
    "replace_new_order_ref",
    "replace_shares",
    "replace_price",

    "exec_timestamp",
    "exec_order_ref",
    "exec_shares",
    "exec_match_id",

    "trade_timestamp",
    "trade_order_ref",
    "trade_side",
    "trade_shares",
    "trade_stock_symbol",
    "trade_price",
    "trade_match_id",

    "add_mpid_order_ref",
    "add_mpid_shares",
    "add_mpid_price",
    "add_mpid_side",
    "add_mpid_stock_symbol",           # ← you were missing this!
    "add_mpid_attribution",

    "broken_timestamp",                # ← you were missing this!
    "broken_match_id",
    
    "exec_price_timestamp",
    "exec_price_order_ref",
    "exec_price_shares",
    "exec_price_match_id",
    "exec_price_printable",
    "exec_price_price",

    "add_parsed_type",
    "cancel_parsed_type",
    "delete_parsed_type",
    "replace_parsed_type",
    "exec_parsed_type",
    "trade_parsed_type",
    "add_mpid_parsed_type",
    "broken_parsed_type",              # ← Fixed! Was broken_trade_parsed_type
    "exec_price_parsed_type"           # ← Fixed! Was executed_price_parsed_type
]

PARSER_HEADERS = [
    "cycle",
    "parsed_valid",
    "parsed_type",
    "order_ref",
    "side",
    "shares",
    "price",
    "timestamp",
    "misc_data"
]


