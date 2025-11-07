
# ITCH Parser Testbench Helpers – Functional Overview

This README documents all Python helper modules used in the cocotb-based verification environment of the speculative ITCH parser. These helpers provide core utilities for:

- Payload generation
- Input stream scheduling
- Output logging and validation
- Midstream reset testing
- Simulation orchestration and signal comparison

Each module is structured for reusability, modularity, and clear separation of concerns.

---

## 1. `payload_generator_helper.py`

### Purpose

Encodes ITCH protocol message types into byte-aligned payloads for simulation injection.

### Supported Messages

- Add Order (`'A'`)
- Cancel Order (`'X'`)
- Delete Order (`'D'`)
- Replace Order (`'U'`)
- Executed Order (`'E'`)
- Trade (`'P'`)

### Features

- Supports fixed (`mode='set'`) and randomized (`mode='rand'`) payloads
- Adds synthetic padding for stress testing
- Consistent field encoding logic with Verilog parser

---

## 2. `msg_sequence_helper.py`

### Purpose

Creates message type sequences for simulation planning.

### Key Functions

- `generate_msg_sequence(length, weights=None)`: Produces randomized message plans with optional type weighting
- `generate_permutation_coverage_sequence()`: Exhaustive permutation coverage across all message types

Used for workload diversity and permutation testing in benchmarking scenarios.

---

## 3. `full_workload_helper.py`

### Purpose

Combines byte streams and metadata into complete test vectors for injection.

### Output Format

```python
{
    "full_stream": List[int],  # concatenated byte stream
    "injection_schedule": List[Dict]  # metadata per message:
        {
            "type": msg_type,
            "payload": [int],
            "expected_valid_cycle": int
        }
}
```

### Features

- Automatically aligns message start and expected valid cycles
- Integrates cleanly with comparator and recorder utilities

---

## 4. `reset_helper.py`

### Purpose

Orchestrates simulation resets including startup and midstream aborts.

### Key Functions

- `reset_dut(dut, duration_clks=2)`: Applies initial reset pulse
- `reset_midstream(dut, trigger_cycle=2)`: Inserts a reset mid-simulation to test recovery
- `start_clock(dut, period_ns=10)`: Launches simulation clock

Supports clean, repeatable test setups and edge case recovery testing.

---

## 5. `recorder.py`

### Purpose

Logs **internal valid flags** and **field outputs** for every decoder across all simulation cycles.

### Features

- Extracts field values even if signal is not present on the DUT
- Logs to a cycle-indexed dictionary (`_recorded_log`)
- Supports detailed trace inspection and debugging

### Example Fields

- `add_internal_valid`, `add_order_ref`, `add_shares`, ...
- `replace_internal_valid`, `replace_old_order_ref`, ...
- `trade_internal_valid`, `trade_match_id`, etc.

---

## 6. `recorder_parser.py`

### Purpose

Logs **canonical parser outputs** from the top-level `parser.v`.

### Example Fields

- `parsed_valid`, `parsed_type`
- `order_ref`, `side`, `shares`, `price`
- `timestamp`, `misc_data`

Used to evaluate system-level performance and latency tracking.

---

## 7. `compare_helper.py`

### Purpose

Compares expected decoded outputs against recorded simulation logs.

### Features

- Generates expected output rows per message using payload decoders
- Aligns results with actual cycles
- Reports mismatches per field and simulation cycle
- Supports CSV-formatted signal headers (`SIM_HEADERS`, `PARSER_HEADERS`)

### Modes

- `compare_against_expected()`: Validates log vs expected outputs
- `generate_expected_events_from_schedule()`: Decoder-specific expected row generation
- `generate_expected_events_with_fields()`: Parser mode with canonical output validation

---

## Summary

| Module Name               | Role in Testbench                              |
|---------------------------|------------------------------------------------|
| `payload_generator_helper` | Encodes messages into ITCH-format payloads     |
| `msg_sequence_helper`      | Generates message type sequences               |
| `full_workload_helper`     | Combines full streams and cycle metadata       |
| `reset_helper`             | Handles DUT reset and recovery testing         |
| `recorder.py`              | Logs per-decoder internal states               |
| `recorder_parser.py`       | Logs canonical parser outputs                  |
| `compare_helper.py`        | Compares actual vs expected results            |

These helper modules form the foundation of a reproducible, high-coverage, and automation-friendly testbench architecture.
