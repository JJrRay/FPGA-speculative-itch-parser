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
    "trade": 40
}



# Define common headers to enforce identical CSV structure
SIM_HEADERS = [
    "cycle",
    
    "add_internal_valid",
    "cancel_internal_valid",
    "delete_internal_valid",
    "replace_internal_valid",
    "executed_internal_valid", 
    
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

    "trade_internal_valid",
    "trade_timestamp",
    "trade_order_ref",
    "trade_side",
    "trade_shares",
    "trade_stock_symbol",
    "trade_price",
    "trade_match_id",

    "add_parsed_type",
    "cancel_parsed_type",
    "delete_parsed_type",
    "replace_parsed_type",
    "exec_parsed_type",
    "trade_parsed_type"


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


