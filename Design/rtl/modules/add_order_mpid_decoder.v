// =============================================
// add_order_mpid_decoder.v 
// =============================================
//
// Description: Zero-wait speculative Add Order with MPID Attribution decoder for ITCH feed.
//              Begins decoding at byte 0 and maps order_ref from byte 1.
//              Identical to 'A' (Add Order) but includes MPID attribution field.
// Author: JR
// Start Date: 20251112
// Version: 1.1
//
// Changelog
// =============================================
// [20251002-1] JR: Initial implementation based on add_order_decoder with MPID field.
// [20251007-1] JR: Fixed suppression logic for FPGA synthesis - single always_ff block
// =============================================

// ------------------------------------------------------------------------------------------------
// Architecture Notes:
// ------------------------------------------------------------------------------------------------
// The ITCH "Add Order - MPID Attribution" ('F') message has a fixed length of 40 bytes and is 
// structured as:
//   [0]     = Message Type (ASCII 'F')
//   [1:8]   = Order Reference Number (64-bit)
//   [9]     = Buy/Sell Indicator ('B' or 'S')
//   [10:13] = Number of Shares (32-bit)
//   [14:21] = Stock Symbol (8 ASCII characters, space-padded)
//   [22:25] = Price (32-bit, fixed-point with 4 implied decimal places)
//   [26:29] = Reserved or padding (zeroed)
//   [30:33] = Attribution (4 ASCII characters, MPID/firm identifier)
//   [34:39] = Reserved
//
// The decoder speculatively begins parsing at byte 0 and asserts `internal_valid`
// after 40 valid bytes if the message type is 'F'.
//
// Key Difference from 'A': Includes MPID Attribution field showing market participant ID
// ------------------------------------------------------------------------------------------------

module add_order_mpid_decoder (
    input  logic        clk,
    input  logic        rst,
    input  logic [7:0]  byte_in,
    input  logic        valid_in,

    output logic [3:0]  add_mpid_parsed_type,

    output logic        add_mpid_internal_valid,
    output logic        add_mpid_packet_invalid,

    output logic [63:0] add_mpid_order_ref,
    output logic        add_mpid_side,
    output logic [31:0] add_mpid_shares,
    output logic [31:0] add_mpid_price,
    output logic [63:0] add_mpid_stock_symbol,
    output logic [31:0] add_mpid_attribution    // NEW: 4-byte MPID
);

    parameter MSG_TYPE   = 8'h46;   // ASCII 'F'
    parameter MSG_LENGTH = 40;

    `include "itch_len.vh"
    `include "itch_suppression.vh"
    `include "itch_fields_add_mpid.vh"
    `include "itch_reset.vh"
    `include "itch_core_decode.vh"

    logic [5:0] byte_index;
    logic       is_add_mpid_order;
    
    // Suppression logic declaration
    `ITCH_SUPPRESSION_DECL
    
    // Main decode logic
    always_ff @(posedge clk) begin
         // Suppression counter update
        `ITCH_SUPPRESSION_UPDATE
        
        if (rst) begin
            byte_index         <= 0;
            `is_order          <= 0;
            `ITCH_RESET_LOGIC

        end else if (valid_in && decoder_enabled) begin

            `ITCH_CORE_DECODE(MSG_TYPE, MSG_LENGTH)
            `internal_valid <= 0;
            `packet_invalid <= 0;

            if (`is_order) begin
                case (byte_index)
                    // Order Reference Number: bytes 1-8
                    1:  add_mpid_order_ref[63:56]     <= byte_in;
                    2:  add_mpid_order_ref[55:48]     <= byte_in;
                    3:  add_mpid_order_ref[47:40]     <= byte_in;
                    4:  add_mpid_order_ref[39:32]     <= byte_in;
                    5:  add_mpid_order_ref[31:24]     <= byte_in;
                    6:  add_mpid_order_ref[23:16]     <= byte_in;
                    7:  add_mpid_order_ref[15:8]      <= byte_in;
                    8:  add_mpid_order_ref[7:0]       <= byte_in;
                    
                    // Buy/Sell Indicator: byte 9
                    9:  add_mpid_side                 <= (byte_in == "S");
                    
                    // Shares: bytes 10-13
                    10: add_mpid_shares[31:24]        <= byte_in;
                    11: add_mpid_shares[23:16]        <= byte_in;
                    12: add_mpid_shares[15:8]         <= byte_in;
                    13: add_mpid_shares[7:0]          <= byte_in;
                    
                    // Stock Symbol: bytes 14-21
                    14: add_mpid_stock_symbol[63:56]  <= byte_in;
                    15: add_mpid_stock_symbol[55:48]  <= byte_in;
                    16: add_mpid_stock_symbol[47:40]  <= byte_in;
                    17: add_mpid_stock_symbol[39:32]  <= byte_in;
                    18: add_mpid_stock_symbol[31:24]  <= byte_in;
                    19: add_mpid_stock_symbol[23:16]  <= byte_in;
                    20: add_mpid_stock_symbol[15:8]   <= byte_in;
                    21: add_mpid_stock_symbol[7:0]    <= byte_in;
                    
                    // Price: bytes 22-25
                    22: add_mpid_price[31:24]         <= byte_in;
                    23: add_mpid_price[23:16]         <= byte_in;
                    24: add_mpid_price[15:8]          <= byte_in;
                    25: add_mpid_price[7:0]           <= byte_in;
                    
                    // Bytes 26-29: Reserved/padding (skip)
                    
                    // Attribution (MPID): bytes 30-33
                    30: add_mpid_attribution[31:24]   <= byte_in;
                    31: add_mpid_attribution[23:16]   <= byte_in;
                    32: add_mpid_attribution[15:8]    <= byte_in;
                    33: add_mpid_attribution[7:0]     <= byte_in;
                    
                    // Bytes 34-39: Reserved (skip)
                endcase

                // Assert valid on last byte
                if (byte_index == MSG_LENGTH - 1) begin
                    `internal_valid <= 1;
                    `parsed_type    <= 4'd6;  // Add Order MPID = type 6
                end
            end

            // Packet overrun detection
            if (byte_index >= MSG_LENGTH && is_add_mpid_order)
                `packet_invalid <= 1;
        end

        // Mid-packet abort handling
        if (`is_order && (
            (valid_in == 0 && byte_index > 0 && byte_index < MSG_LENGTH) ||
            (byte_index >= MSG_LENGTH)
        ))
            `packet_invalid <= 1;

        `ITCH_RECHECK_OR_SUPPRESS(MSG_TYPE, MSG_LENGTH)
        `include "itch_abort_on_valid_drop.vh"
    end

endmodule
