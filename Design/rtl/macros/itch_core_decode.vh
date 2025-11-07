// =============================================
// itch_core_decode.vh
// =============================================
//
// Description: Core speculative decode macro for byte_index advancement,
//              type match, and suppression fallback. Includes post-boundary
//              recheck logic via ITCH_RECHECK_OR_SUPPRESS.
// Author: RZ
// Start Date: 20250505
// Version: 0.2
//
// Changelog
// =============================================
// [20250505-1] RZ: Introduced ITCH_CORE_DECODE and ITCH_RECHECK_OR_SUPPRESS macros.
// [20250505-2] RZ: Corrected suppress_count assignment from itch_length(byte_in)-2 to itch_length(byte_in)-1 to prevent overlapping.

`define ITCH_CORE_DECODE(MSG_TYPE, MSG_LENGTH)              \
    if (byte_index == 0) begin                              \
        `is_order <= (byte_in == MSG_TYPE);                 \
        if (byte_in == MSG_TYPE) begin                      \
            byte_index <= 1;                                \
        end else begin                                      \
            suppress_count <= itch_length(byte_in) - 1;     \
            `is_order     <= 0;                             \
            byte_index    <= 0;                             \
        end                                                 \
    end else begin                                          \
        byte_index <= byte_index + 1;                       \
    end

`define ITCH_RECHECK_OR_SUPPRESS(MSG_TYPE, MSG_LENGTH)       \
    if (byte_index == MSG_LENGTH) begin                      \
        `ITCH_RESET_FIELDS                                   \
        if (valid_in && byte_in == MSG_TYPE) begin           \
            `is_order <= 1;                                  \
            byte_index <= 1;                                 \
        end else if (valid_in) begin                         \
            `is_order <= 0;                                  \
            byte_index <= 0;                                 \
            suppress_count <= itch_length(byte_in) - 1;      \
        end else begin                                       \
            `is_order <= 0;                                  \
            byte_index <= 0;                                 \
        end                                                  \
    end

