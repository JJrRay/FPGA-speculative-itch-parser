
# Core Parser Logic – Speculative ITCH Parser

This document provides an in-depth, structured explanation of the core architectural logic of the speculative ITCH parser. It is the heart of the design, coordinating all decoders, handling arbitration, enforcing correctness through one-hot validation, and ultimately producing low-latency canonical outputs.

## Table of Contents

1. Parallel Decoder Design and Gating  
2. Suppression Logic  
3. One-Hot Valid Check and Timing   
4. Mid-Packet `valid_in` Drop Handling  
5. Canonical Output Multiplexing  
6. Latching Stage and Its Rationale  
7. Architectural Summary  
8. Full Pseudocode Walkthrough  

---

## 1. Parallel Decoder Design and Gating

Each ITCH message type (e.g., Add, Cancel, Delete, etc.) has its own dedicated decoder. These decoders are:

- Always active at cycle 0 for every new byte
- Speculatively parse the first byte (message type)
- If matched, proceed with parsing according to that message type’s structure
- If not matched, engage suppression logic

All decoders share:
- Clock and reset
- `byte_in`, `valid_in`, `byte_count`
- Access to a suppression macro to gate decoding if mismatched

Because of this parallelism, no decoder waits to be activated. The system relies on downstream arbitration to determine which output is valid.

---

## 2. Suppression Logic

### Purpose

To ensure only one decoder continues decoding after cycle 0, and all others ignore the rest of the incoming message.

### Mechanism

- Implemented using a suppress counter unique to each decoder
- Uses a macro:
  ```verilog
  suppress_count <= ITCH_LEN(byte_in);
  ```
- If `suppress_count > 0`, the decoder disables its FSM for that cycle

### Effect

- Decoder begins suppression on byte 0 mismatch
- Will stay idle for the exact number of cycles needed to skip over the message
- Fully parallel: suppression logic runs in each decoder without a centralized controller

### Benefits

- Enables truly zero-latency speculative parsing
- Avoids accidental decoding of unintended messages
- Supports back-to-back messages without gaps

---

## 3. One-Hot Valid Check and Timing (with RTL logic)

### Purpose

To ensure exactly one decoder is reporting a valid output per message.

### Key Design Decision

The check for whether only one decoder fired is done one cycle before final assertion, in parallel with the decoders. This is possible because:

- The suppression logic guarantees that only one decoder is ever active
- Therefore, checking one-hotness of `*_internal_valid` signals can be safely pre-evaluated

 
```

### Benefit

- Avoids arbitration latency
- No stalling required to check which decoder is active
- Combinational check ensures only 1 cycle delay total

---

## 4. Mid-Packet `valid_in` Drop Handling

### Scenario

In real-world streaming scenarios, the `valid_in` signal might drop unexpectedly due to backpressure or upstream stalls. If this occurs in the middle of a message, we must immediately abort the current parse attempt.

### Implementation via `itch_abort_on_valid_drop.vh`

Each decoder includes logic like:

```verilog
if (!valid_in) begin
    ITCH_RESET_FIELDS();     // Reset all outputs
    suppress_count <= 0;     // Clear suppression counter
end
```

This ensures:

- No partially-decoded output is ever propagated
- All FSM and counters are reset
- Decoder is ready for clean operation the next time `valid_in` rises

### Why It Matters

Without this logic:

- Partial field values might cause undefined behavior downstream
- The parser could become misaligned with byte stream boundaries
- One-hot safety and suppression logic might break due to leftover state

By handling `valid_in` drop defensively and consistently, the parser maintains correctness and recovery even in non-ideal dataflow conditions.

---

## 5. Canonical Output Multiplexing

### Purpose

To standardize the output format for all ITCH messages into a unified signal interface.

### Fields Include

- `parsed_valid` (1-bit)
- `parsed_type` (4-bit message code)
- `order_ref`, `shares`, `side`, `price`, etc. — decoder dependent

### Multiplexing Strategy

```verilog
if (add_internal_valid) begin
    parsed_type = add_parsed_type;
    order_ref   = add_order_ref;
    ...
end else if (cancel_internal_valid) begin
    ...
end ...
```

- All fields are explicitly routed to top-level ports
- The first valid decoder’s fields are selected
- Evaluation order is deterministic (Add > Cancel > ...)

### Timing

- Suppose a message is N bytes long
- It begins injection at cycle 0
- Last byte arrives at cycle N−1
- Parsing completes at cycle N
- Canonical output is available at cycle N+1

Hence, only one cycle of parsing delay is introduced by the parser

---

## 6. Latching Stage and Its Rationale

### Why We Need It

The canonical output is derived from combinational logic, which may:

- Change as soon as a decoder changes
- Be difficult to sample reliably in downstream systems

To solve this, we use a register-based output stage defined in:

```verilog
parser_latch_stage.v
```

### Behavior

- Clocked register stage
- Samples canonical output only when `parsed_valid == 1`
- Holds the value until the next parsed message completes

### Benefits

- Stable output interface
- Decouples combinational timing from downstream design
- Facilitates pipelining and testbench observation

---

## 7. Architectural Summary

| Feature                | Implementation                                   | Benefit                                    |
|------------------------|--------------------------------------------------|--------------------------------------------|
| Speculative Parsing    | All decoders parse byte 0                        | Zero initial latency                       |
| Suppression Logic      | Per-decoder counter via `ITCH_LEN`              | Isolates non-matching decoders             |
| One-Hot Checking       | Combinational logic via internal_valid signals  | Low-cost arbitration                       |
| Canonical Output       | Fixed field muxing from decoders                | Standard interface to downstream systems   |
| Latch Stage            | Register buffer via `parser_latch_stage.v`      | Stable sampling, decoupling                |
| Mid-Packet Abort       | `ITCH_RESET_FIELDS()` + clear suppression       | Robust recovery under signal drop          |

---

## 8. Pseudocode Walkthrough

```verilog
// ============ Decoder Side ============

always_ff @(posedge clk) begin
    if (rst) begin
        // Reset all outputs and internal state
        ITCH_RESET_FIELDS();
        suppress_count <= 0;
        byte_index     <= 0;
        is_order       <= 0;
    end else if (!valid_in) begin
        // Mid-packet abort
        ITCH_RESET_FIELDS();
        suppress_count <= 0;
        byte_index     <= 0;
        is_order       <= 0;
    end else if (suppress_count > 0) begin
        suppress_count <= suppress_count - 1;
    end else begin
        case (byte_index)
            // Core decode macro (starts decode or suppress)
            0: begin
                is_order <= (byte_in == MSG_TYPE);
                if (byte_in == MSG_TYPE) begin
                    byte_index <= 1;
                end else begin
                    suppress_count <= ITCH_LEN(byte_in) - 1;
                    is_order       <= 0;
                    byte_index     <= 0;
                end
            end

            // Field decoding using byte_index
            1...MSG_LENGTH-1: begin
                // Decode fields per byte_index
                decode_fields(byte_index, byte_in);
                byte_index <= byte_index + 1;
            end

            // Re-check or suppress logic for back-to-back injection
            MSG_LENGTH: begin
                ITCH_RESET_FIELDS();
                if (byte_in == MSG_TYPE) begin
                    is_order   <= 1;
                    byte_index <= 1;
                end else begin
                    is_order   <= 0;
                    byte_index <= 0;
                    suppress_count <= ITCH_LEN(byte_in) - 1;
                end
            end
        endcase
    end
end

// ============ Arbitration Side ============

always_comb begin
    parsed_valid = 0;
    parsed_type  = 0;
    all other outputs = 0;

    if (valid_in && exactly one *_internal_valid) begin
        parsed_valid = 1;
        route selected decoder outputs to canonical outputs;
    end
end

// ============ Latch Stage ============

always_ff @(posedge clk) begin
    if (parsed_valid) begin
        latched_outputs <= canonical_outputs;
    end
end
