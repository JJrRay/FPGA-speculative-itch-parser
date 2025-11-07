
# ITCH Decoder Modules – Architectural Overview

This document details the structure, message-specific architecture, and macro integration strategy for the six ITCH decoder modules:

- `add_order_decoder.v`
- `cancel_order_decoder.v`
- `delete_order_decoder.v`
- `replace_order_decoder.v`
- `executed_order_decoder.v`
- `trade_decoder.v`

All decoder modules share a **common FSM control structure**, rely on macro definitions for modularity, and parse message content based on fixed byte positions defined by the ITCH protocol.

---

## Shared Decoder Architecture

Each decoder operates under the following speculative decoding framework:

1. **Cycle 0**: Inspect `byte_in`. If it matches the expected message type, decoding begins.
2. **Cycle 1 to N-1**: Accumulate fields byte-by-byte using `byte_index`.
3. **Cycle N**: Parsing completes. If valid, assert `*_internal_valid`.
4. **Cycle N+1**: Canonical output is available at the top level.
5. **If not matched on cycle 0**: Suppress using `suppress_count <= ITCH_LEN(byte_in) - 1`.

Macros like `ITCH_CORE_DECODE`, `ITCH_RESET_FIELDS`, and `ITCH_RECHECK_OR_SUPPRESS` encapsulate this logic.

---

## Message-Specific Architectures

### 1. `add_order_decoder.v` – Add Order (`'A'`)

- **Length**: 36 bytes
- **Fields**:
  - `order_ref [63:0]`
  - `side [7:0]`
  - `shares [31:0]`
  - `stock_symbol [63:0]` (8 ASCII characters)
  - `price [31:0]`

This decoder is the most feature-rich, serving as a canonical reference. It uses:
- `itch_fields_add.vh` for declaration and reset
- `ITCH_SET_VALID` at byte 35
- `parsed_type = 4'd1`

---

### 2. `cancel_order_decoder.v` – Cancel Order (`'X'`)

- **Length**: 12 bytes
- **Fields**:
  - `order_ref [63:0]`
  - `canceled_shares [31:0]`

Lightweight decoder using:
- `itch_fields_cancel.vh`
- Suppression and validation macros at byte 11

---

### 3. `delete_order_decoder.v` – Delete Order (`'D'`)

- **Length**: 11 bytes
- **Fields**:
  - `order_ref [63:0]`

The simplest decoder. Integration includes:
- `itch_fields_delete.vh`
- Field complete at byte 10
- `parsed_type = 4'd3`

---

### 4. `replace_order_decoder.v` – Replace Order (`'U'`)

- **Length**: 34 bytes
- **Fields**:
  - `old_order_ref [63:0]`
  - `new_order_ref [63:0]`
  - `shares [31:0]`
  - `price [31:0]`

This decoder supports remapping orders and uses:
- `itch_fields_replace.vh`
- Suppression macros and byte_index FSM
- `parsed_type = 4'd4`

---

### 5. `executed_order_decoder.v` – Executed Order (`'E'`)

- **Length**: 25 bytes
- **Fields**:
  - `order_ref [63:0]`
  - `executed_shares [31:0]`
  - `match_id [63:0]`

Typical fill execution event parser using:
- `itch_fields_executed.vh`
- Completes at byte 24
- Output via canonical mux on valid

---

### 6. `trade_decoder.v` – Trade Message (`'P'`)

- **Length**: 40 bytes
- **Fields**:
  - `order_ref [63:0]`
  - `side [7:0]`
  - `shares [31:0]`
  - `stock_symbol [63:0]`
  - `price [31:0]`
  - `match_id [63:0]`

This decoder handles the most complex structure and uses:
- `itch_fields_trade.vh`
- Extensive use of `byte_index` with field reassembly
- Field assembly completes at byte 39, triggers valid

---

## Macro Integration in Each Decoder

All decoders follow this pattern:

```verilog
// Include field macro
`include "itch_fields_<message>.vh"

// Declare outputs
ITCH_DECLARE_FIELDS_<MSG>();

// Reset block
if (rst || !valid_in) begin
    ITCH_RESET_FIELDS();
    suppress_count <= 0;
    byte_index     <= 0;
end

// Decode control
ITCH_CORE_DECODE(MSG_TYPE, MSG_LENGTH)

switch (byte_index):
    // assign byte_in to fields
    field_a[idx] <= byte_in;

// Message complete
if (byte_index == MSG_LENGTH - 1) begin
    ITCH_SET_VALID();
    parsed_type <= 4'd<type>;
end

// Post-packet recheck
ITCH_RECHECK_OR_SUPPRESS(MSG_TYPE, MSG_LENGTH)
```

This structure is consistent, compact, and reusable across all modules.

---

## Summary

Each decoder is:

- Designed to operate **speculatively and in parallel**
- Uses shared macros to eliminate boilerplate
- Handles suppression, parsing, and output assertion autonomously
- Outputs a consistent canonical signal set to the parser

This design pattern enables robust, scalable, and low-latency message parsing across the ITCH message protocol.
