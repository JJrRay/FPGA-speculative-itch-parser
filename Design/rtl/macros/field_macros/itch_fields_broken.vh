// =============================================
// itch_fields_broken.vh
// =============================================
//
// Description: Signal name indirection and reset assignment macro for Broken Trade decoder.
// Author: RZ
// Start Date: 20250508
// Version: 0.1
//
// Changelog
// =============================================
// [20250508-1] Initial field mapping for broken_trade_decoder.

`define internal_valid   broken_internal_valid
`define packet_invalid   broken_packet_invalid
`define parsed_type      broken_parsed_type
`define match_id         broken_match_id
`define timestamp        broken_timestamp
`define is_order         is_broken_trade   // used by ITCH_CORE_DECODE

`define ITCH_RESET_FIELDS        \
    `internal_valid <= 0;        \
    `parsed_type    <= 0;        \
    `packet_invalid <= 0;        \
    `match_id       <= 0;        \
    `timestamp      <= 0;
