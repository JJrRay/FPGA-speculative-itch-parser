// =============================================
// trade_decoder.v
// =============================================
//
// Description: Speculative streaming Trade decoder.
//              Parses 44-byte ITCH 'P' messages from a raw byte stream.
//
// Author: RZ
// Start Date: 20250501
// Version: 0.4
//
// Changelog
// =============================================
// [20250501-1] RZ: Initial implementation with symbol and price extraction.
// [20250501-2] RZ: Added self disable and zeroing of signals after message parsing completion.
// [20250502-1] RZ: Updated msg structure
// [20250505-1] RZ: Updated to use macros
// =============================================
// ------------------------------------------------------------------------------------------------
// Protocol Version Note:
// ------------------------------------------------------------------------------------------------
// This decoder implements the streamlined ITCH 5.0 Trade ('P') message used in real-world HFT
// parser designs. It excludes upstream metadata such as tracking numbers, locate codes, and
// participant info.
//
// ------------------------------------------------------------------------------------------------
// Architecture Notes:
// ------------------------------------------------------------------------------------------------
// The ITCH "Trade" ('P') message has a fixed length of 40 bytes and is structured as:
//   [0]     = Message Type (ASCII 'P')
//   [1:6]   = Timestamp (48-bit)
//   [7:14]  = Order Reference Number (64-bit)
//   [15]    = Buy/Sell Indicator ('B' or 'S')
//   [16:19] = Number of Shares (32-bit)
//   [20:27] = Stock Symbol (8 ASCII characters, space-padded)
//   [28:31] = Price (32-bit)
//   [32:39] = Match ID (64-bit)
//
// The decoder speculatively begins parsing at byte 0 and asserts `internal_valid`
// after 40 valid bytes if the message type is 'P'.
// ------------------------------------------------------------------------------------------------



module trade_decoder (
    input  logic        clk,
    input  logic        rst,
    input  logic [7:0]  byte_in,
    input  logic        valid_in,

    output logic [3:0] trade_parsed_type,

    output logic        trade_internal_valid,
    output logic        trade_packet_invalid,

    output logic [47:0] trade_timestamp,
    output logic [63:0] trade_order_ref,
    output logic        trade_side,
    output logic [31:0] trade_shares,
    output logic [63:0] trade_stock_symbol,
    output logic [31:0] trade_price,
    output logic [63:0] trade_match_id
);

    parameter MSG_TYPE   = 8'h50;  // ASCII 'P'
    parameter MSG_LENGTH = 40;

    `include "macros/itch_len.vh"
    `include "macros/itch_suppression.vh"
    `include "macros/field_macros/itch_fields_trade.vh"
    `include "macros/itch_reset.vh"
    `include "macros/itch_core_decode.vh"

    logic [5:0] byte_index;
    logic       is_trade;

    // Main decode logic
    always_ff @(posedge clk) begin
        if (rst) begin
            byte_index            <= 0;
            `is_order          <= 0;
            
            `ITCH_RESET_LOGIC

        end else if (valid_in && decoder_enabled) begin

            `ITCH_CORE_DECODE(MSG_TYPE, MSG_LENGTH)
            `internal_valid <= 0;
            `packet_invalid <= 0;

            if (`is_order) begin
                case (byte_index)
                    1:  trade_timestamp[47:40] <= byte_in;
                    2:  trade_timestamp[39:32] <= byte_in;
                    3:  trade_timestamp[31:24] <= byte_in;
                    4:  trade_timestamp[23:16] <= byte_in;
                    5:  trade_timestamp[15:8]  <= byte_in;
                    6:  trade_timestamp[7:0]   <= byte_in;

                    7:  trade_order_ref[63:56] <= byte_in;
                    8:  trade_order_ref[55:48] <= byte_in;
                    9:  trade_order_ref[47:40] <= byte_in;
                    10: trade_order_ref[39:32] <= byte_in;
                    11: trade_order_ref[31:24] <= byte_in;
                    12: trade_order_ref[23:16] <= byte_in;
                    13: trade_order_ref[15:8]  <= byte_in;
                    14: trade_order_ref[7:0]   <= byte_in;

                    15: trade_side <= (byte_in == "S");


                    16: trade_shares[31:24] <= byte_in;
                    17: trade_shares[23:16] <= byte_in;
                    18: trade_shares[15:8]  <= byte_in;
                    19: trade_shares[7:0]   <= byte_in;

                    20: trade_stock_symbol[63:56] <= byte_in;
                    21: trade_stock_symbol[55:48] <= byte_in;
                    22: trade_stock_symbol[47:40] <= byte_in;
                    23: trade_stock_symbol[39:32] <= byte_in;
                    24: trade_stock_symbol[31:24] <= byte_in;
                    25: trade_stock_symbol[23:16] <= byte_in;
                    26: trade_stock_symbol[15:8]  <= byte_in;
                    27: trade_stock_symbol[7:0]   <= byte_in;

                    28: trade_price[31:24] <= byte_in;
                    29: trade_price[23:16] <= byte_in;
                    30: trade_price[15:8]  <= byte_in;
                    31: trade_price[7:0]   <= byte_in;

                    32: trade_match_id[63:56] <= byte_in;
                    33: trade_match_id[55:48] <= byte_in;
                    34: trade_match_id[47:40] <= byte_in;
                    35: trade_match_id[39:32] <= byte_in;
                    36: trade_match_id[31:24] <= byte_in;
                    37: trade_match_id[23:16] <= byte_in;
                    38: trade_match_id[15:8]  <= byte_in;
                    39: trade_match_id[7:0]   <= byte_in;
                endcase

                if (byte_index == MSG_LENGTH - 1)
                    `internal_valid <= 1;
                    `parsed_type    <= 4'd5;
                    
            end

            if (byte_index >= MSG_LENGTH && is_trade)
               
                `packet_invalid <= 1;
        end

        if (`is_order && (
            (valid_in == 0 && byte_index > 0 && byte_index < MSG_LENGTH) ||
            (byte_index >= MSG_LENGTH)
        ))
            `packet_invalid <= 1;

        `ITCH_RECHECK_OR_SUPPRESS(MSG_TYPE, MSG_LENGTH)
        `include "macros/itch_abort_on_valid_drop.vh"
    end

endmodule

