
# ITCH Parser Macros Documentation

This document describes all shared macros used across the speculative ITCH parser design. Each macro is designed for modularity, zero-latency integration, and reuse across all decoder modules. The macros cover reset handling, speculative decoding, suppression logic, parsing FSMs, and mid-packet abort handling.

---

## 1. `itch_reset.vh` – Field Reset Macros

### Purpose

Initializes all decoder output signals to known values on reset.

### Usage

Called at the beginning of the decoder `always_ff` block when `rst` is asserted.

### Pseudocode

```verilog
if (rst) begin
    ITCH_RESET_FIELDS(); // Expands to: signal_a <= 0; signal_b <= 0; ...
end
```

### Details

- Each decoder defines its own `*_RESET_FIELDS` macro using its field header (e.g., `itch_fields_add.vh`)
- Promotes consistency across decoders and simplifies signal declarations

---

## 2. `itch_core_decode.vh` – Core FSM Logic

### Purpose

Implements per-byte parsing logic based on `byte_count`. Designed to be inlined within `case (byte_count)`.

### Usage

Called during the speculative decode phase.

### Pseudocode

```verilog
case (byte_count)
    0: if (byte_in == 'A') begin ... else suppress;
    1: field_a[7:0]  <= byte_in;
    2: field_a[15:8] <= byte_in;
    ...
    N-1: begin
        ITCH_SET_VALID(); // Mark decoding as successful
        parsed_type <= 4'dX;
    end
endcase
```

### Details

- Macros like `ITCH_FIELD_ASSIGN(idx, field, hi, lo)` are typically used to group field assembly
- Clean decoding logic inlined per byte count, matching ITCH spec

---

## 3. `itch_suppression.vh` – Suppression Logic

### Purpose

Skips decoding when the incoming message type does not match this decoder. Ensures zero waste of logic cycles.

### Usage

Invoked on byte 0 mismatch or mid-decode.

### Pseudocode

```verilog
if (byte_count == 0 && byte_in != expected_type) begin
    suppress_count <= ITCH_LEN(byte_in);  // Lookup message length
end

if (suppress_count > 0) begin
    suppress_count <= suppress_count - 1;
    // do not decode
end
```

### Details

- Uses the `ITCH_LEN` function from `itch_len.vh` to look up known message lengths
- Applied in parallel across all decoders
- Critical for supporting back-to-back injection and speculative decoding

---

## 4. `itch_len.vh` – Message Length Lookup

### Purpose

Provides a centralized function-like macro that returns the length of an ITCH message given its type.

### Usage

Called in suppression logic to determine how many bytes to skip if this decoder is not responsible for the message.

### Pseudocode

```verilog
function automatic int ITCH_LEN(input byte_type);
    case (byte_type)
        "A": return 36;
        "X": return 12;
        "D": return 11;
        ...
        default: return 0;
    endcase
endfunction
```

### Details

- Supports every valid ITCH type used in the parser
- Enables suppression and message completion checks to be decoupled from hardcoding

---

## 5. `itch_abort_on_valid_drop.vh` – Mid-Packet Abort Handling

### Purpose

Handles the scenario where `valid_in` drops in the middle of message decoding. This macro ensures that the decoder resets cleanly and does not propagate partially decoded data.

### Usage

Evaluated in the decoder FSM when `valid_in` is low.

### Pseudocode

```verilog
if (!valid_in) begin
    ITCH_RESET_FIELDS();  // Clean abort
    suppress_count <= 0;
end
```

### Details

- Essential for robustness in noisy or streaming environments
- Ensures decoding logic resumes cleanly on the next rising `valid_in`

---

All of these macros contribute to the overall structure of a robust, speculative ITCH parser that is safe, efficient, and easy to extend.

