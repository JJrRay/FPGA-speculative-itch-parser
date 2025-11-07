
# ITCH Parser Testbench – Architecture and Workflow

This README documents the cocotb-based simulation environment for verifying the speculative ITCH parser system. The testbench structure is modular, reusable, and built for full-cycle benchmarking, field-level validation, and mid-stream recovery testing.

---

## Core Design Goals

- Validate speculative decode logic with randomized and structured workloads
- Simulate real-world streaming conditions including backpressure and resets
- Benchmark timing, output latency, and signal integrity
- Ensure strict one-to-one match between expected and parsed outputs

---

## Primary Testbenches

### 1. `test_integrated.py`

Verifies the full speculative pipeline using internal valid signals and decoder fields. 

**Workflow:**
- Starts simulation and applies reset via `reset_helper.py`
- Uses `run_full_payload_workload()` to generate the byte stream
- Logs all `*_internal_valid` and field-level outputs using `record_all_internal_valids()`
- Injects byte stream continuously with no delay between messages
- Uses `generate_expected_events_from_schedule()` to align expected output cycles
- Dumps logs and expectations to CSV, and compares using `compare_against_expected()`

---

### 2. `test_parser_canonical.py`

Tests the top-level parser’s canonical output interface.

**Workflow:**
- Uses the same injection plan and clock/reset flow as the integrated test
- Records top-level outputs like `parsed_valid`, `parsed_type`, `order_ref`, `shares`, `price`
- Aligns expected output using `parser_mode=True` in the comparator
- Ensures that arbitration and canonical muxing operate with 1-cycle delay

---

### 3. `test_valid_drop_abort.py`

Focuses on **mid-packet `valid_in` drop** behavior for a single decoder.

**Test Flow:**
- Starts injecting a partial message
- Drops `valid_in` mid-stream
- Verifies the decoder **resets cleanly** and ignores the partial message
- Immediately injects a new full message and confirms it is parsed correctly
- Ensures `latched_valid` and final field values match expectations

---

## Helper Integration

Each testbench imports the following helper modules:

- `reset_helper.py`: starts clock and applies reset or midstream abort
- `payload_generator_helper.py`: constructs message-specific byte arrays
- `full_workload_helper.py`: returns both `full_stream` and injection timing
- `compare_helper.py`: generates cycle-aligned expectations and compares logs
- `recorder.py` / `recorder_parser.py`: logs either decoder or parser outputs to structured dicts

---

## Expected Value Evaluation

The testbenches **do not hardcode** any expected values. Instead:

1. They use the same payload generators to recreate test vectors
2. Field values are parsed directly from payload bytes
3. The exact cycle when `*_internal_valid` or `parsed_valid` is expected is computed ahead of time using message length and reset cycle constants

This ensures consistency, adaptability, and minimal human error.

---

## Automation with Makefile

A `Makefile` is provided to automate:

- Compilation
- Simulation
- VCD waveform dumping
- Automatic launching of GTKWave viewer with the correct file

Example:

```bash
make MODULE=test_integrated
```

This compiles and runs `test_integrated.py`, then launches GTKWave to inspect results.

---

## Summary

| Testbench                | Purpose                                           | Output Type              |
|--------------------------|---------------------------------------------------|--------------------------|
| `test_integrated.py`     | Full pipeline verification                        | Internal decoder signals |
| `test_parser_canonical.py` | Top-level parser arbitration and mux testing     | Canonical outputs        |
| `test_valid_drop_abort.py` | Stability test for `valid_in` interruption      | Latched values           |

Each testbench ensures that both functional correctness and real-world resilience are evaluated across speculative decoders, parser arbitration, and output registration.

