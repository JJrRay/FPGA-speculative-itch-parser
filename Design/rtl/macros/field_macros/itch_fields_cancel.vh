// =============================================
// itch_fields_cancel.vh
// =============================================
//
// Description: Signal name indirection and reset assignment macro for Cancel Order decoder.
// Author: RZ
// Start Date: 20250505
// Version: 0.1
//
// Changelog
// =============================================
// [20250505-1] RZ: Initial field mapping for cancel_order_decoder.
// [20250506-1] RZ: Added parsed type

`define internal_valid    cancel_internal_valid
`define packet_invalid    cancel_packet_invalid
`define order_ref         cancel_order_ref
`define parsed_type       cancel_parsed_type
`define canceled_shares   cancel_canceled_shares
`define is_order          is_cancel_order   //  ITCH_CORE_DECODE

`define ITCH_RESET_FIELDS        \
    `internal_valid    <= 0;     \
    `parsed_type       <= 0;     \
    `packet_invalid    <= 0;     \
    `order_ref         <= 0;     \
    `canceled_shares   <= 0;
