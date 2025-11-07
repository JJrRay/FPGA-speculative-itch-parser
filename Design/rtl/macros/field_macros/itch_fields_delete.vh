// =============================================
// itch_fields_delete.vh
// =============================================
//
// Description: Signal name indirection and reset assignment macro for Delete Order decoder.
// Author: RZ
// Start Date: 20250505
// Version: 0.2
//
// Changelog
// =============================================
// [20250505-1] RZ: Initial field mapping for delete_order_decoder.
// [20250506-1] RZ: Added parsed type

`define internal_valid   delete_internal_valid
`define packet_invalid   delete_packet_invalid
`define parsed_type      delete_parsed_type
`define order_ref        delete_order_ref
`define is_order         is_delete_order   // used by ITCH_CORE_DECODE

`define ITCH_RESET_FIELDS        \
    `internal_valid <= 0;        \
    `packet_invalid <= 0;        \
    `parsed_type    <= 0;        \ 
    `order_ref      <= 0;
