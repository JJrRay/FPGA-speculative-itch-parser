// =============================================
// itch_fields_add_mpid.vh
// =============================================
//
// Description: Signal name indirection and reset assignment macro for Add Order MPID decoder.
// Author: RZ
// Start Date: 20250508
// Version: 0.1
//
// Changelog
// =============================================
// [20250508-1] Initial field mapping for add_order_mpid_decoder.

`define internal_valid   add_mpid_internal_valid
`define packet_invalid   add_mpid_packet_invalid
`define order_ref        add_mpid_order_ref
`define parsed_type      add_mpid_parsed_type
`define side             add_mpid_side
`define shares           add_mpid_shares
`define price            add_mpid_price
`define stock_symbol     add_mpid_stock_symbol
`define attribution      add_mpid_attribution
`define is_order         is_add_mpid_order   // used by ITCH_CORE_DECODE

`define ITCH_RESET_FIELDS        \
    `internal_valid <= 0;        \
    `parsed_type    <= 0;        \
    `packet_invalid <= 0;        \
    `order_ref      <= 0;        \
    `side           <= 0;        \
    `shares         <= 0;        \
    `price          <= 0;        \
    `stock_symbol   <= 0;        \
    `attribution    <= 0;
