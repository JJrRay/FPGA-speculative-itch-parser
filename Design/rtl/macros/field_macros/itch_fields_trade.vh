// =============================================
// itch_fields_trade.vh
// =============================================
//
// Description: Signal name indirection and reset assignment macro for Trade decoder.
// Author: RZ
// Start Date: 20250505
// Version: 0.2
//
// Changelog
// =============================================
// [20250505-1] RZ: Initial field mapping for trade_decoder.
// [20250506-1] RZ: Added parsed type

`define internal_valid    trade_internal_valid
`define packet_invalid    trade_packet_invalid
`define parsed_type       trade_parsed_type
`define timestamp         trade_timestamp
`define order_ref         trade_order_ref
`define side              trade_side
`define shares            trade_shares
`define stock_symbol      trade_stock_symbol
`define price             trade_price
`define match_id          trade_match_id
`define is_order          is_trade   //used by ITCH_CORE_DECODE

`define ITCH_RESET_FIELDS            \
    `internal_valid    <= 0;         \
    `packet_invalid    <= 0;         \
    `parsed_type       <= 0;         \
    `timestamp         <= 0;         \
    `order_ref         <= 0;         \
    `side              <= 0;         \
    `shares            <= 0;         \
    `stock_symbol      <= 0;         \
    `price             <= 0;         \
    `match_id          <= 0;
