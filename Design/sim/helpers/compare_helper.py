# ============================================================
# compare_helper.py
# ============================================================
#
# Description: Post-injection signal comparison utility for ITCH decoders.
#              Aligns recorded simulation logs with expected parsed outputs.
#              Supports CSV logging, mismatch reporting, and validation.
# Author: RZ
# Start Date: 20250505
# Version: 0.2
#
# Changelog
# ============================================================
# [20250505-1] RZ: Initial implementation for benchmark signal matching.
# [20250506-1] RZ: Added support for parser mode and unified key generation.
# ============================================================

from helpers.payload_generator_helper import (
    generate_add_order_payload, generate_cancel_order_payload, 
    generate_delete_order_payload, generate_replace_order_payload, 
    generate_executed_order_payload, generate_trade_payload)
from helpers.full_workload_helper import MSG_LENGTHS
from sim_config import RESET_CYCLES, SIM_CLK_PERIOD_NS
from ITCH_config import SIM_HEADERS

def compare_against_expected(recorded_log, expected_events):
    """
    Compares the actual signal log vs expected events, field by field.
    """
    for expected in expected_events:
        cycle = expected["cycle"]
        actual = recorded_log.get(cycle, {})

        for key in SIM_HEADERS:
            if key == "cycle":
                continue  # Skip cycle field

            expected_val = expected.get(key, "")
            actual_val = actual.get(key, "")

            # Only assert if expected value is non-empty
            if expected_val != "":
                assert actual_val == expected_val, (
                    f"Mismatch at cycle {cycle} for '{key}': expected {expected_val}, got {actual_val}"
                )

def generate_expected_events_with_fields(message_plan, mode='set', parser_mode=False):

    """
    Generates a list of expected output events per message with matching SIM_HEADERS:
    - Internal valid signal set to 1
    - Parsed fields based on payloads
    - All fields from SIM_HEADERS included in each dict (even if value is blank)

    Returns:
        List[Dict] with unified keys for CSV and comparison
    """
    expected_events = []
    current_cycle = 0

    for msg_type in message_plan:
        msg_len = MSG_LENGTHS[msg_type]
        expected_valid_cycle = current_cycle + msg_len + RESET_CYCLES

        if parser_mode:
            from ITCH_config import PARSER_HEADERS
            row = {key: "" for key in PARSER_HEADERS}
        else:
            row = {key: "" for key in SIM_HEADERS}
        row["cycle"] = expected_valid_cycle

        if parser_mode:
            row["parsed_valid"] = 1
            row["parsed_type"] = hex({
                "add": 0,
                "cancel": 1,
                "delete": 2,
                "executed": 3,
                "replace": 4,
                "trade": 5
            }[msg_type])

        if msg_type == "add":
            payload = generate_add_order_payload(mode)
            row["add_internal_valid"]           = 1
            row["add_order_ref"]                = hex(int.from_bytes(payload[1:9], byteorder='big'))
            row["add_side"]                     = hex(0) if payload[9] == ord('B') else hex(1)
            row["add_shares"]                   = hex(int.from_bytes(payload[10:14], byteorder='big'))
            row["add_price"]                    = hex(int.from_bytes(payload[22:26], byteorder='big'))

        elif msg_type == "cancel":
            payload = generate_cancel_order_payload(mode)
            row["cancel_internal_valid"]        = 1
            row["cancel_order_ref"]             = hex(int.from_bytes(payload[1:9], byteorder='big'))
            row["cancel_shares"]                = hex(int.from_bytes(payload[9:13], byteorder='big'))

        elif msg_type == "delete":
            payload = generate_delete_order_payload(mode)
            row["delete_internal_valid"]        = 1
            row["delete_order_ref"]             = hex(int.from_bytes(payload[1:9], byteorder='big'))

        elif msg_type == "replace":
            payload = generate_replace_order_payload(mode)
            row["replace_internal_valid"]       = 1
            row["replace_old_order_ref"]        = hex(int.from_bytes(payload[1:9], byteorder='big'))
            row["replace_new_order_ref"]        = hex(int.from_bytes(payload[9:17], byteorder='big'))
            row["replace_shares"]               = hex(int.from_bytes(payload[17:21], byteorder='big'))
            row["replace_price"]                = hex(int.from_bytes(payload[21:25], byteorder='big'))

        elif msg_type == "executed":
            payload = generate_executed_order_payload(mode)

            row["executed_internal_valid"]      = 1
            row["exec_timestamp"]               = hex(int.from_bytes(payload[1:7], byteorder='big'))
            row["exec_order_ref"]               = hex(int.from_bytes(payload[7:15], byteorder='big'))
            row["exec_shares"]                  = hex(int.from_bytes(payload[15:19], byteorder='big'))
            row["exec_match_id"]                = hex(int.from_bytes(payload[19:27], byteorder='big'))

        elif msg_type == "trade":
            payload = generate_trade_payload(mode)
            row["trade_internal_valid"]         = 1
            row["trade_timestamp"]              = hex(int.from_bytes(payload[1:7], byteorder='big'))
            row["trade_order_ref"]              = hex(int.from_bytes(payload[7:15], byteorder='big'))
            row["trade_side"]                   = hex(0) if payload[15] == ord('B') else hex(1)
            row["trade_shares"]                 = hex(int.from_bytes(payload[16:20], byteorder='big'))
            row["trade_stock_symbol"]           = hex(int.from_bytes(payload[20:28], byteorder='big'))  
            row["trade_price"]                  = hex(int.from_bytes(payload[28:32], byteorder='big'))
            row["trade_match_id"]               = hex(int.from_bytes(payload[32:40], byteorder='big'))


 


        expected_events.append(row)
        current_cycle += msg_len

    return expected_events

from sim_config import SIM_HEADERS
from helpers.payload_generator_helper import (
    generate_add_order_payload,
    generate_cancel_order_payload,
    generate_delete_order_payload,
    generate_replace_order_payload,
    generate_executed_order_payload,
    generate_trade_payload,
)

# def generate_expected_events_from_schedule(schedule, parser_mode=False):
#     """
#     Given the injection schedule (with fixed payloads), decode expected outputs.
#     Returns a list of dicts with unified keys.
#     """
#     expected_events = []

#     for item in schedule:
#         msg_type = item["type"]
#         payload = item["payload"]
#         expected_valid_cycle = item["expected_valid_cycle"]

#         if parser_mode:
#             from ITCH_config import PARSER_HEADERS
#             row = {key: "" for key in PARSER_HEADERS}
#             row["cycle"] = expected_valid_cycle
#             row["parsed_valid"] = 1
#             row["parsed_type"] = hex({
#                 "add": 0,
#                 "cancel": 1,
#                 "delete": 2,
#                 "executed": 3,
#                 "replace": 4,
#                 "trade": 5
#             }[msg_type])

#             if msg_type == "add":
#                 row["order_ref"] = hex(int.from_bytes(payload[1:9], byteorder='big'))
#                 row["side"] = hex(0) if payload[9] == ord('B') else hex(1)
#                 row["shares"] = hex(int.from_bytes(payload[10:14], byteorder='big'))
#                 row["price"] = hex(int.from_bytes(payload[22:26], byteorder='big'))

#             elif msg_type == "cancel":
#                 row["order_ref"] = hex(int.from_bytes(payload[1:9], byteorder='big'))
#                 row["shares"] = hex(int.from_bytes(payload[9:13], byteorder='big'))

#             elif msg_type == "delete":
#                 row["order_ref"] = hex(int.from_bytes(payload[1:9], byteorder='big'))

#             elif msg_type == "replace":
#                 row["order_ref"] = hex(int.from_bytes(payload[9:17], byteorder='big'))
#                 row["shares"] = hex(int.from_bytes(payload[17:21], byteorder='big'))
#                 row["price"] = hex(int.from_bytes(payload[21:25], byteorder='big'))

#             elif msg_type == "executed":
#                 row["timestamp"] = hex(int.from_bytes(payload[1:7], byteorder='big'))
#                 row["order_ref"] = hex(int.from_bytes(payload[7:15], byteorder='big'))
#                 row["shares"] = hex(int.from_bytes(payload[15:19], byteorder='big'))
#                 row["match_id"] = hex(int.from_bytes(payload[19:27], byteorder='big'))

#             elif msg_type == "trade":
#                 row["timestamp"] = hex(int.from_bytes(payload[1:7], byteorder='big'))
#                 row["order_ref"] = hex(int.from_bytes(payload[7:15], byteorder='big'))
#                 row["side"] = hex(0) if payload[15] == ord('B') else hex(1)
#                 row["shares"] = hex(int.from_bytes(payload[16:20], byteorder='big'))
#                 row["stock_symbol"] = hex(int.from_bytes(payload[20:28], byteorder='big'))
#                 row["price"] = hex(int.from_bytes(payload[28:32], byteorder='big'))
#                 row["match_id"] = hex(int.from_bytes(payload[32:40], byteorder='big'))

#         else:
#             from ITCH_config import SIM_HEADERS
#             row = {key: "" for key in SIM_HEADERS}
#             row["cycle"] = expected_valid_cycle

#             if msg_type == "add":
#                 row["add_parsed_type"] = hex(0)
#                 row["add_internal_valid"] = 1
#                 row["add_order_ref"] = hex(int.from_bytes(payload[1:9], byteorder='big'))
#                 row["add_side"] = hex(0) if payload[9] == ord('B') else hex(1)
#                 row["add_shares"] = hex(int.from_bytes(payload[10:14], byteorder='big'))
#                 row["add_price"] = hex(int.from_bytes(payload[22:26], byteorder='big'))

#             elif msg_type == "cancel":
#                 row["cancel_parsed_type"] = hex(1)
#                 row["cancel_internal_valid"] = 1
#                 row["cancel_order_ref"] = hex(int.from_bytes(payload[1:9], byteorder='big'))
#                 row["cancel_shares"] = hex(int.from_bytes(payload[9:13], byteorder='big'))

#             elif msg_type == "delete":
#                 row["delete_parsed_type"] = hex(2)
#                 row["delete_internal_valid"] = 1
#                 row["delete_order_ref"] = hex(int.from_bytes(payload[1:9], byteorder='big'))

#             elif msg_type == "replace":
#                 row["replace_parsed_type"] = hex(4)
#                 row["replace_internal_valid"] = 1
#                 row["replace_old_order_ref"] = hex(int.from_bytes(payload[1:9], byteorder='big'))
#                 row["replace_new_order_ref"] = hex(int.from_bytes(payload[9:17], byteorder='big'))
#                 row["replace_shares"] = hex(int.from_bytes(payload[17:21], byteorder='big'))
#                 row["replace_price"] = hex(int.from_bytes(payload[21:25], byteorder='big'))

#             elif msg_type == "executed":
#                 row["exec_parsed_type"] = hex(3)
#                 row["executed_internal_valid"] = 1
#                 row["exec_timestamp"] = hex(int.from_bytes(payload[1:7], byteorder='big'))
#                 row["exec_order_ref"] = hex(int.from_bytes(payload[7:15], byteorder='big'))
#                 row["exec_shares"] = hex(int.from_bytes(payload[15:19], byteorder='big'))
#                 row["exec_match_id"] = hex(int.from_bytes(payload[19:27], byteorder='big'))

#             elif msg_type == "trade":
#                 row["trade_parsed_type"] = hex(5)
#                 row["trade_internal_valid"] = 1
#                 row["trade_timestamp"] = hex(int.from_bytes(payload[1:7], byteorder='big'))
#                 row["trade_order_ref"] = hex(int.from_bytes(payload[7:15], byteorder='big'))
#                 row["trade_side"] = hex(0) if payload[15] == ord('B') else hex(1)
#                 row["trade_shares"] = hex(int.from_bytes(payload[16:20], byteorder='big'))
#                 row["trade_stock_symbol"] = hex(int.from_bytes(payload[20:28], byteorder='big'))
#                 row["trade_price"] = hex(int.from_bytes(payload[28:32], byteorder='big'))
#                 row["trade_match_id"] = hex(int.from_bytes(payload[32:40], byteorder='big'))

#         expected_events.append(row)

#     return expected_events


def generate_expected_events_from_schedule(schedule, parser_mode=False):
    """
    Given the injection schedule (with fixed payloads), decode expected outputs.
    Returns a list of dicts with unified keys.
    """
    expected_events = []

    for item in schedule:
        msg_type = item["type"]
        payload = item["payload"]
        expected_valid_cycle = item["expected_valid_cycle"]

        if parser_mode:
            from ITCH_config import PARSER_HEADERS
            row = {key: "" for key in PARSER_HEADERS}
            row["cycle"] = expected_valid_cycle
            row["parsed_valid"] = 1
            row["parsed_type"] = hex({
                "add": 0,
                "cancel": 1,
                "delete": 2,
                "executed": 3,
                "replace": 4,
                "trade": 5
            }[msg_type])

            if msg_type == "add":
                row["order_ref"] = hex(int.from_bytes(payload[1:9], byteorder='big'))
                row["side"] = hex(0) if payload[9] == ord('B') else hex(1)
                row["shares"] = hex(int.from_bytes(payload[10:14], byteorder='big'))
                row["price"] = hex(int.from_bytes(payload[22:26], byteorder='big'))
                row["misc_data"] = hex(int.from_bytes(payload[14:22], byteorder='big'))  # stock_symbol

            elif msg_type == "cancel":
                row["order_ref"] = hex(int.from_bytes(payload[1:9], byteorder='big'))
                row["shares"] = hex(int.from_bytes(payload[9:13], byteorder='big'))

            elif msg_type == "delete":
                row["order_ref"] = hex(int.from_bytes(payload[1:9], byteorder='big'))

            elif msg_type == "replace":
                row["order_ref"] = hex(int.from_bytes(payload[9:17], byteorder='big'))  # new_order_ref
                row["shares"] = hex(int.from_bytes(payload[17:21], byteorder='big'))
                row["price"] = hex(int.from_bytes(payload[21:25], byteorder='big'))
                row["misc_data"] = hex(int.from_bytes(payload[1:9], byteorder='big'))    # old_order_ref

            elif msg_type == "executed":
                row["timestamp"] = hex(int.from_bytes(payload[1:7], byteorder='big'))
                row["order_ref"] = hex(int.from_bytes(payload[7:15], byteorder='big'))
                row["shares"] = hex(int.from_bytes(payload[15:19], byteorder='big'))
                row["misc_data"] = hex(int.from_bytes(payload[19:27], byteorder='big'))  # match_id

            elif msg_type == "trade":
                row["timestamp"] = hex(int.from_bytes(payload[1:7], byteorder='big'))
                row["order_ref"] = hex(int.from_bytes(payload[7:15], byteorder='big'))
                row["side"] = hex(0) if payload[15] == ord('B') else hex(1)
                row["shares"] = hex(int.from_bytes(payload[16:20], byteorder='big'))
                row["price"] = hex(int.from_bytes(payload[28:32], byteorder='big'))
                row["misc_data"] = hex(int.from_bytes(payload[32:40], byteorder='big'))  # match_id

        else:
            from ITCH_config import SIM_HEADERS
            row = {key: "" for key in SIM_HEADERS}
            row["cycle"] = expected_valid_cycle
            if msg_type == "add":
                row["add_parsed_type"] = hex(0)
                row["add_internal_valid"] = 1
                row["add_order_ref"] = hex(int.from_bytes(payload[1:9], byteorder='big'))
                row["add_side"] = hex(0) if payload[9] == ord('B') else hex(1)
                row["add_shares"] = hex(int.from_bytes(payload[10:14], byteorder='big'))
                row["add_price"] = hex(int.from_bytes(payload[22:26], byteorder='big'))

            elif msg_type == "cancel":
                row["cancel_parsed_type"] = hex(1)
                row["cancel_internal_valid"] = 1
                row["cancel_order_ref"] = hex(int.from_bytes(payload[1:9], byteorder='big'))
                row["cancel_shares"] = hex(int.from_bytes(payload[9:13], byteorder='big'))

            elif msg_type == "delete":
                row["delete_parsed_type"] = hex(2)
                row["delete_internal_valid"] = 1
                row["delete_order_ref"] = hex(int.from_bytes(payload[1:9], byteorder='big'))

            elif msg_type == "replace":
                row["replace_parsed_type"] = hex(4)
                row["replace_internal_valid"] = 1
                row["replace_old_order_ref"] = hex(int.from_bytes(payload[1:9], byteorder='big'))
                row["replace_new_order_ref"] = hex(int.from_bytes(payload[9:17], byteorder='big'))
                row["replace_shares"] = hex(int.from_bytes(payload[17:21], byteorder='big'))
                row["replace_price"] = hex(int.from_bytes(payload[21:25], byteorder='big'))

            elif msg_type == "executed":
                row["exec_parsed_type"] = hex(3)
                row["executed_internal_valid"] = 1
                row["exec_timestamp"] = hex(int.from_bytes(payload[1:7], byteorder='big'))
                row["exec_order_ref"] = hex(int.from_bytes(payload[7:15], byteorder='big'))
                row["exec_shares"] = hex(int.from_bytes(payload[15:19], byteorder='big'))
                row["exec_match_id"] = hex(int.from_bytes(payload[19:27], byteorder='big'))

            elif msg_type == "trade":
                row["trade_parsed_type"] = hex(5)
                row["trade_internal_valid"] = 1
                row["trade_timestamp"] = hex(int.from_bytes(payload[1:7], byteorder='big'))
                row["trade_order_ref"] = hex(int.from_bytes(payload[7:15], byteorder='big'))
                row["trade_side"] = hex(0) if payload[15] == ord('B') else hex(1)
                row["trade_shares"] = hex(int.from_bytes(payload[16:20], byteorder='big'))
                row["trade_stock_symbol"] = hex(int.from_bytes(payload[20:28], byteorder='big'))
                row["trade_price"] = hex(int.from_bytes(payload[28:32], byteorder='big'))
                row["trade_match_id"] = hex(int.from_bytes(payload[32:40], byteorder='big'))

        expected_events.append(row)

    return expected_events
