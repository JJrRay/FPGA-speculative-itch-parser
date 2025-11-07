# ============================================================
# full_workload_helper.py
# ============================================================
#
# Description: Generates synthetic ITCH message streams for stress testing.
#              Combines multiple message types into full workloads.
#              Supports stream injection with type and length alignment.
# Author: RZ
# Start Date: 20250505
# Version: 0.1
#
# Changelog
# ============================================================
# [20250505-1] RZ: Created full-stream ITCH generator for benchmarking.
# [20250506-1] RZ: Added support for multiple message types.
# [20250506-1] RZ: Implemented cycle-based scheduling for message injection.
# ============================================================

from sim_config import SIM_CLK_PERIOD_NS, RESET_CYCLES, MSG_MODE
from ITCH_config import SIM_HEADERS, MSG_LENGTHS

from .payload_generator_helper import (
    generate_add_order_payload, 
    generate_cancel_order_payload, 
    generate_delete_order_payload,
    generate_replace_order_payload,
    generate_executed_order_payload, 
    generate_trade_payload)


def generate_payload_by_type(msg_type, mode='set'):
    if msg_type == 'add':
        return generate_add_order_payload(mode)
    elif msg_type == 'cancel':
        return generate_cancel_order_payload(mode)
    elif msg_type == 'delete':
        return generate_delete_order_payload(mode)
    elif msg_type == 'replace':
        return generate_replace_order_payload(mode)
    elif msg_type == 'executed':
        return generate_executed_order_payload(mode)
    elif msg_type == "trade":
        return generate_trade_payload(mode)


    else:
        raise ValueError(f"Unsupported message type: {msg_type}")
# def generate_payload_by_type(msg_type: str, mode: str = "set"):
#     if msg_type == "add":
#         return generate_add_order_payload(mode)
#     elif msg_type == "cancel":
#         return generate_cancel_order_payload(mode)
 
#     else:
#         raise ValueError(f"Unknown message type: {msg_type}")


def run_full_payload_workload(message_plan):

    """
    Generates a full ITCH message stream and logs timing info.

    Args:
        message_plan: list of message types like ["add", "cancel", "add", ...]

    Returns:
        {
            'full_stream': List[int],
            'injection_schedule': List[Dict] with keys:
                'type', 'start_cycle', 'start_time_ns', 'expected_valid_cycle'
        }
    """
    full_stream = []
    schedule = []
    current_cycle = 0

    for msg_type in message_plan:
        payload = generate_payload_by_type(msg_type, MSG_MODE)
        msg_len = len(payload)

        expected_valid_cycle = current_cycle + msg_len + RESET_CYCLES
        full_stream.extend(payload)  # Injected byte stream

        schedule.append({
            "type": msg_type,
            "payload": payload,
            "expected_valid_cycle": expected_valid_cycle
        })

        current_cycle += msg_len

    return {
        "full_stream": full_stream,
        "injection_schedule": schedule
    }


