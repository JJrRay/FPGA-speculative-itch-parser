
# ITCH Parser Field Macro Documentation

This document describes the decoder-specific **field definition macros** used in the speculative ITCH parser. These macros are responsible for declaring and initializing the outputs for each message type, allowing for **high modularity**, **clear separation of concerns**, and **easier integration** with shared logic such as resets and arbitration.

---

## Why Use Field Macros?

Instead of repeating signal declarations and reset logic in every decoder module, each message type has a dedicated `itch_fields_*.vh` file that encapsulates:

1. **Signal Declarations**: All parsed fields and flags for that message type
2. **Reset Behavior**: Default values for all fields during `rst`
3. **Parsed Type Code**: A 4-bit message ID used for downstream identification

By encapsulating field logic, we avoid copy-paste errors, simplify arbitration wiring, and streamline the design.

---

## Macro Format and Usage

Each macro file typically includes:

```verilog
// Declaration block
`define ITCH_DECLARE_FIELDS_<NAME> \
    output logic field1; \
    output logic [N:0] field2; \
    ...

// Reset block
`define ITCH_RESET_FIELDS_<NAME> \
    field1 <= '0'; \
    field2 <= '0'; \
    ...

// Parsed type block
`define ITCH_PARSED_TYPE_<NAME> \
    parsed_type <= 4'dX;
```

Each decoder then `\`includes its respective macro file and uses:

- `ITCH_DECLARE_FIELDS_<NAME>`
- `ITCH_RESET_FIELDS_<NAME>`
- `ITCH_PARSED_TYPE_<NAME>`

---

## Field Macro Breakdown

### 1. `itch_fields_add.vh`

- Message Type: `'A'` (Add Order)
- Fields:
  - `order_ref [63:0]`
  - `side [7:0]`
  - `shares [31:0]`
  - `stock_symbol [63:0]` (8 ASCII chars)
  - `price [31:0]`

### 2. `itch_fields_cancel.vh`

- Message Type: `'X'` (Cancel Order)
- Fields:
  - `order_ref [63:0]`
  - `canceled_shares [31:0]`

### 3. `itch_fields_delete.vh`

- Message Type: `'D'` (Delete Order)
- Fields:
  - `order_ref [63:0]`

### 4. `itch_fields_replace.vh`

- Message Type: `'U'` (Replace Order)
- Fields:
  - `old_order_ref [63:0]`
  - `new_order_ref [63:0]`
  - `shares [31:0]`
  - `price [31:0]`

### 5. `itch_fields_executed.vh`

- Message Type: `'E'` (Executed Order)
- Fields:
  - `order_ref [63:0]`
  - `executed_shares [31:0]`
  - `match_id [63:0]`

### 6. `itch_fields_trade.vh`

- Message Type: `'P'` (Trade Message)
- Fields:
  - `order_ref [63:0]`
  - `side [7:0]`
  - `shares [31:0]`
  - `stock_symbol [63:0]`
  - `price [31:0]`
  - `match_id [64:0]`

---

## Benefits

- **Cleaner Modules**: Decoder code focuses only on FSM and logic
- **Ease of Refactoring**: Field changes are isolated to one macro file
- **Standardization**: Enforced structure across all message types
- **Simplified Arbitration**: All fields are defined up front, aiding combinational muxing

---

These macros are foundational to the parser’s modular design and make large-scale changes safer and easier to manage.
