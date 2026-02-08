# FPGA Speculative ITCH Parser

## Original Author

**Ruixuan Zhang (Rex)**  
Independent Researcher  
ruixuan.zhang.ee@gmail.com  
rz0704rz@gmail.com

## Extended By

**Jean-Claude Junior Raymond**  
Electrical Engineering Student, Polytechnique Montréal  
Extended as part of INF8503 Design Project (Fall 2025)

---

## Overview

This project implements a speculative, low-latency ITCH message parser with a robust, gated architecture that achieves canonical-format output with only **one clock cycle of parsing delay**. All message types are parsed in parallel using a fully macro-driven RTL structure, enabling aggressive pipelining and precise control.

The RTL modules are highly modular and reusable, with suppression logic, mid-packet recovery, and arbitration implemented through well-isolated macros. A matching Cocotb testbench framework—also macroized and helper-driven—provides full-cycle logging, field-level validation, and protocol-level benchmarking.

Thanks to this flexible and structured design, the parser architecture can be trivially adapted to support other streaming protocols with raw serial input and canonical parallel output—such as market data feeds, trading logic interfaces, or packetized control streams.

---

## Extensions and Contributions

This fork extends the original implementation with the following contributions:

### RTL Modifications for Vivado Synthesis Compatibility
- **Single-process refactoring**: The original decoder modules used two separate `always` blocks that modified the same signals, which is not supported by Vivado synthesis. All decoders were refactored to consolidate signal assignments into a single process while preserving the original logic and modularity.
- This modification was required for successful synthesis on Xilinx tools without altering the functional behavior of the parsers.

### Additional Message Type Decoders
- **Add Order MPID ('F')** - 40 bytes: Adds market participant identifier support
- **Executed Order with Price ('C')** - 36 bytes: Execution notifications with price information
- **Broken Trade ('B')** - 19 bytes: Trade break notifications

### PYNQ-Z2 FPGA Integration
- Complete AXI4-Stream wrapper for DMA integration
- AXI4-Lite register interface for result readback
- Vivado block design for Zynq-7000 SoC deployment
- Python/PYNQ driver for hardware validation

### Four-Phase Validation Methodology
1. **Python Golden Model** (original work) - Pure software reference implementation
2. **Cocotb + Icarus** (extended from author) - RTL simulation with added decoder tests
3. **Vivado Simulator** - Pre-synthesis validation with AXI interfaces
4. **PYNQ Hardware** - On-target validation with real DMA transfers

### Documentation
- Comprehensive technical report documenting the implementation
- Detailed latency analysis for all 9 message types
- FPGA resource utilization analysis

---

## Project Structure

- [`rtl/`](Design/rtl/)
  - [`macros/`](Design/rtl/macros/)
    - [`field_macros/`](Design/rtl/macros/field_macros/)
      - ITCH field declarations (e.g., `itch_fields_add.vh`)
      - [README_field_macros.md](Design/rtl/macros/field_macros/README_field_macros.md)
    - Shared control macros (`itch_reset.vh`, `itch_core_decode.vh`, etc.)
    - [README_macros.md](Design/rtl/macros/README_macros.md)
  - [`modules/`](Design/rtl/modules/)
    - Individual ITCH message decoders (`*_order_decoder.v`)
    - [README_decoders.md](Design/rtl/modules/README_decoders.md)
  - Parser integration files (`parser.v`, `parser_latch_stage.v`, etc.)
  - [README_core_logic.md](Design/rtl/README_core_logic.md)

- [`sim/`](Design/sim/)
  - [`helpers/`](Design/sim/helpers/)
    - Simulation drivers, workload generators, and recorders
    - [README_helpers.md](Design/sim/helpers/README_helpers.md)
  - [`vcd`](Design/sim/vcd)
    - Waveform files and pictures
  - Cocotb testbenches (`test_integrated.py`, `test_parser_canonical.py`, `test_valid_drop_abort.py`)
  - Output logs and waveform automation (e.g., `recorded_log.csv`, `Makefile`)
  - [README_testbench.md](Design/sim/README_testbench.md)

- [`vivado/`](vivado/) *(new)*
  - Vivado project files for PYNQ-Z2
  - Block design with AXI DMA and custom IP
  - Constraint files and bitstream generation

- [`pynq/`](pynq/) *(new)*
  - Python drivers for hardware testing
  - Jupyter notebooks for demonstration
  - Overlay files (.bit, .hwh)

- [README.md](README.md) 

---

## Supported Message Types

| Type | Name | Char | Size | Extracted Fields |
|------|------|------|------|------------------|
| 0 | Add Order | 'A' | 36 B | order_ref, side, shares, stock, price |
| 1 | Cancel Order | 'X' | 23 B | order_ref, canceled_shares |
| 2 | Delete Order | 'D' | 9 B | order_ref |
| 3 | Executed Order | 'E' | 30 B | order_ref, executed_shares, match_id |
| 4 | Replace Order | 'U' | 27 B | old_order_ref, new_order_ref, shares, price |
| 5 | Trade | 'P' | 40 B | order_ref, side, shares, stock, price, match_id |
| 6 | Add Order MPID | 'F' | 40 B | order_ref, side, shares, stock, price, attribution |
| 7 | Exec with Price | 'C' | 36 B | order_ref, exec_shares, match_id, price |
| 8 | Broken Trade | 'B' | 19 B | reason_code, match_id |

---

## Waveforms

Waveform Segment
![Waveform Segment](Design/sim/vcd/First_Packet_Segment.png)

Back-to-Back Detail
![Waveform Segment - Back-to-Back Packets](Design/sim/vcd/Back_to_Back_Packet_Segment.png)

Mid-Packet Valid Drop Detail
![Waveform Segment - Mid-Packet Valid Drop](Design/sim/vcd/Waveform_Valid_Drop_Segment.png)

---

## Architecture Summary

### Core RTL Files

- `*_order_decoder.v`: One decoder per ITCH message type (Add, Cancel, Delete, Replace, Executed, Trade, Add MPID, Exec with Price, Broken Trade)
- `parser.v`: Combinational arbitration logic that selects a valid decoder output
- `parser_latch_stage.v`: Optional pipeline register to stabilize downstream sampling
- `itch_*.vh`: Macro libraries for decoding logic, suppression, reset, and validity handling
- `rtl/signal_definitions/`: Decoder-specific field definitions for modular wiring

### FPGA Integration Files *(new)*

- `Itch_axi_stream_v1_0.v`: Top-level AXI wrapper
- `integrated.v`: Parser + latch stage integration
- `S00_AXI.v`: AXI-Lite slave for register access
- `S00_AXIS.v`: AXI-Stream slave for data input

---

## Top-Level Parser Behavior (`parser.v`)

### Overview

- Each decoder asserts its own `*_internal_valid` when a message of its type is fully decoded
- The parser checks that exactly one decoder is active using a one-hot validation condition
- If exactly one decoder is active, its parsed fields are routed to the canonical output ports

### One-Hot Valid Check

- The one-hot condition is evaluated using internal signals from each decoder
- This check is done fully in parallel, with no added latency

### Arbitration Pseudocode

```verilog
always_comb begin
    parsed_valid = 1'b0;
    parsed_type  = 4'd0;
    ... // zero other outputs

    // Count active decoders
    valid_count = add_internal_valid + cancel_internal_valid +
                  delete_internal_valid + replace_internal_valid +
                  exec_internal_valid + trade_internal_valid +
                  add_mpid_internal_valid + exec_price_internal_valid +
                  broken_internal_valid;

    // Assert parsed_valid only if exactly one decoder fires
    if (valid_in && valid_count == 1) begin
        parsed_valid = 1'b1;

        if (add_internal_valid) begin
            parsed_type  = add_parsed_type;
            order_ref    = add_order_ref;
            ...
        end else if (cancel_internal_valid) begin
            ...
        end
        ...
    end
end
```

---

## Decoder Logic (All `*_decoder.v`)

### Shared Speculative Structure

- All decoders begin speculative parsing from cycle 0
- The first byte (`byte_in`) is always inspected, regardless of message type
- If it matches the expected type (`'A'`, `'X'`, etc.), decoding continues
- If not, suppression logic activates using `ITCH_LEN(byte_in)` to skip N cycles

### Parallel Suppression Logic

- The suppression counter is initialized in parallel across all decoders
- This eliminates idle cycles and ensures no latency is added when skipping mismatched messages

### Decoder Pseudocode (e.g., Add Order Decoder)

```verilog
always_ff @(posedge clk) begin
    if (rst) begin
        ITCH_RESET_FIELDS();
    end else if (valid_in) begin
        if (suppress_count > 0) begin
            suppress_count <= suppress_count - 1;
        end else begin
            case (byte_count)
                0: begin
                    if (byte_in == "A") begin
                        // Start decoding this message type
                        order_ref[63:56] <= byte_in;
                    end else begin
                        // Not our type; suppress future decode
                        suppress_count <= ITCH_LEN(byte_in);
                    end
                end
                1:  order_ref[55:48] <= byte_in;
                ...
                35: begin
                    ITCH_SET_VALID();        // Raise internal_valid
                    parsed_type <= 4'd1;     // 'A' = 1
                end
            endcase
        end
    end
end
```

---

## Timing Behavior

### Canonical Output Delay

- For an N-byte message injected starting at cycle 0:
  - The last byte arrives at cycle N−1
  - The decoder completes at cycle N
  - The parser outputs canonical data at cycle N+1
- This results in only 1 cycle of parsing delay

### Latency by Message Type

| Message Type | Length | Parse Cycles | Latency @ 100 MHz |
|--------------|--------|--------------|-------------------|
| Delete Order ('D') | 9 B | 10 | 100 ns |
| Broken Trade ('B') | 19 B | 20 | 200 ns |
| Cancel Order ('X') | 23 B | 24 | 240 ns |
| Replace Order ('U') | 27 B | 28 | 280 ns |
| Executed Order ('E') | 30 B | 31 | 310 ns |
| Add Order ('A') | 36 B | 37 | 370 ns |
| Exec with Price ('C') | 36 B | 37 | 370 ns |
| Trade ('P') | 40 B | 41 | 410 ns |
| Add Order MPID ('F') | 40 B | 41 | 410 ns |

---

## Key Features

### Speculative Decoding

- All decoders speculatively parse the first byte
- Parsing proceeds immediately without waiting for message boundaries
- Reduces initial decode latency to zero

### Parallel Suppression Logic

- Each decoder autonomously computes suppression count on mismatch
- Suppression is applied in parallel and is zero-latency

### Back-to-Back Message Support

- The parser supports uninterrupted message streams
- No idle cycles or reset required between packets

### Mid-Packet Abort Handling

- If `valid_in` drops mid-message, all active decoders abort cleanly
- Parsing resumes immediately when `valid_in` rises again, with no state corruption

### Canonical Output Format

- The parser outputs a standardized signal set including:
  - `parsed_valid` (1 cycle pulse)
  - `parsed_type` (4-bit message ID)
  - `order_ref`, `shares`, `price`, etc. (depending on message type)

---

## FPGA Implementation Results

### Target Platform
- **Board**: PYNQ-Z2
- **SoC**: Zynq-7000 (XC7Z020-1CLG400C)
- **Clock**: 100 MHz

### Resource Utilization

| Resource | Used | Available | Utilization |
|----------|------|-----------|-------------|
| LUTs | 2,578 | 53,200 | 4.85% |
| Flip-Flops | 3,705 | 106,400 | 3.48% |
| BRAM | 0 | 140 | 0% |
| DSP | 0 | 220 | 0% |

---

## Verification and Testing

- Exhaustive testbench using Cocotb
- All 9 ITCH message types validated with:
  - Random values in all fields
  - Permuted sequences and back-to-back messages
- Python golden model for reference validation
- Automated `Makefile`:
  - Builds and runs the simulation
  - Dumps `vcd` waveform and auto-opens GTKWave
- Latching logic (`parser_latch_stage.v`) verified separately
- Hardware validation on PYNQ-Z2 with real DMA transfers

---

## Design Philosophy and Structure

### Modular RTL

- Shared macros handle FSM structure, resets, and suppression
- Decoder field declarations are separated into `rtl/signal_definitions/` for clean code

### Modular Testbench

- Stimulus generation and validation are built on reusable Python helpers
- Logs both signal traces and cycle-aligned decoded outputs to CSV

### Documentation

- Every module includes a title block with:
  - Description, Author, Start Date, Version
  - Detailed changelog entries

---

## References

1. R. Zhang, "Speculative, Macro-Driven FPGA Architecture for Ultra-Low-Latency ITCH Parsing in High-Frequency Trading Systems," *TechRxiv*, 2023. [Online]. Available: https://www.techrxiv.org/users/924957/articles/1296717

2. NASDAQ, "ITCH 5.0 Specification," *NASDAQ Trader*, 2020. [Online]. Available: https://www.nasdaqtrader.com/content/technicalsupport/specifications/dataproducts/NQTVITCHSpecification.pdf

3. Xilinx, "PYNQ: Python Productivity for Zynq," *PYNQ Documentation*, 2023. [Online]. Available: https://pynq.readthedocs.io/

---

## License

This repository is publicly viewable for academic and demonstration purposes only.

All rights are reserved by the original author (Ruixuan Zhang). Reproduction, modification, or redistribution of the source code is not permitted without explicit written consent.

Extensions by Jean-Claude Junior Raymond are provided for academic purposes as part of the INF8503 course project at Polytechnique Montréal.
