// =============================================
// itch_fields_exec_price.vh
// =============================================
//
// Description: Signal name indirection and reset assignment macro for Executed With Price decoder.
// Author: RZ
// Start Date: 20250508
// Version: 0.1
//
// Changelog
// =============================================
// [20250508-1] Initial field mapping for executed_price_decoder.

`define internal_valid   exec_price_internal_valid
`define packet_invalid   exec_price_packet_invalid
`define parsed_type      exec_price_parsed_type
`define order_ref        exec_price_order_ref
`define shares           exec_price_shares
`define match_id         exec_price_match_id
`define printable        exec_price_printable
`define price            exec_price_price
`define timestamp        exec_price_timestamp
`define is_order         is_exec_price_order   // used by ITCH_CORE_DECODE

`define ITCH_RESET_FIELDS        \
    `internal_valid <= 0;        \
    `parsed_type    <= 0;        \
    `packet_invalid <= 0;        \
    `order_ref      <= 0;        \
    `shares         <= 0;        \
    `match_id       <= 0;        \
    `printable      <= 0;        \
    `price          <= 0;        \
    `timestamp      <= 0;
