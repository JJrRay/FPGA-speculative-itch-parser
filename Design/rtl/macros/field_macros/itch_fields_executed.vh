// =============================================
// itch_fields_executed.vh
// =============================================
//
// Description: Signal name indirection and reset assignment macro for Executed Order decoder.
// Author: RZ
// Start Date: 20250505
// Version: 0.2
//
// Changelog
// =============================================
// [20250505-1] RZ: Initial field mapping for executed_order_decoder.
// [20250506-1] RZ: Added parsed type

`define internal_valid   exec_internal_valid
`define packet_invalid   exec_packet_invalid
`define parsed_type      exec_parsed_type
`define order_ref        exec_order_ref
`define shares           exec_shares
`define match_id         exec_match_id
`define timestamp        exec_timestamp
`define is_order         is_exec_order   // used by ITCH_CORE_DECODE

`define ITCH_RESET_FIELDS        \
    `internal_valid <= 0;        \
    `packet_invalid <= 0;        \
    `parsed_type    <= 0;        \
    `order_ref      <= 0;        \
    `shares         <= 0;        \
    `match_id       <= 0;        \
    `timestamp      <= 0;
