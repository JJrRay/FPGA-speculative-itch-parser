// =============================================
// itch_fields_replace.vh
// =============================================
//
// Description: Signal name indirection and reset assignment macro for Replace Order decoder.
// Author: RZ
// Start Date: 20250505
// Version: 0.1
//
// Changelog
// =============================================
// [20250505-1] RZ: Initial field mapping for replace_order_decoder.

`define internal_valid    replace_internal_valid
`define packet_invalid    replace_packet_invalid
`define parsed_type       replace_parsed_type
`define old_order_ref     replace_old_order_ref
`define new_order_ref     replace_new_order_ref
`define shares            replace_shares
`define price             replace_price
`define is_order          is_replace_order    

`define ITCH_RESET_FIELDS          \
    `internal_valid    <= 0;       \
    `packet_invalid    <= 0;       \
    `parsed_type       <= 0;       \
    `old_order_ref     <= 0;       \
    `new_order_ref     <= 0;       \
    `shares            <= 0;       \
    `price             <= 0;
