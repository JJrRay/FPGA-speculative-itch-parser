// =============================================
// broken_trade_decoder.v
// =============================================
//
// Description: Speculative streaming Broken Trade decoder.
//              Parses 19-byte ITCH 'B' messages from a raw byte stream.
//              Used to indicate a trade cancellation/bust.
//
// Author: JR
// Start Date: 20250508
// Version: 1.1
//
// Changelog
// =============================================
// [20251002-1] JR: Initial implementation for broken trade message.
// [20251007-1] JR: Fixed suppression logic for FPGA synthesis - single always_ff block
// =============================================

// ------------------------------------------------------------------------------------------------
// Architecture Notes:
// ------------------------------------------------------------------------------------------------
// The ITCH "Broken Trade" ('B') message has a fixed length of 19 bytes and is structured as:
//   [0]     = Message Type (ASCII 'B')
//   [1:6]   = Timestamp (48-bit nanoseconds)
//   [7:14]  = Match Number (64-bit, identifies the trade to break/bust)
//   [15:18] = Reserved (zeroed)
//
// The decoder speculatively begins parsing at byte 0 and asserts `internal_valid`
// after 19 valid bytes if the message type is 'B'.
//
// Purpose: Indicates that a previously reported trade is being cancelled (trade bust).
// The Match Number field identifies which trade from a previous 'P' (Trade) or 'C' 
// (Executed With Price) message is being broken.
//
// Important: Systems must remove the broken trade from their tape and adjust volume/vwap
// calculations accordingly.
// ------------------------------------------------------------------------------------------------

module broken_trade_decoder (
    input  logic        clk,
    input  logic        rst,
    input  logic [7:0]  byte_in,
    input  logic        valid_in,

    output logic [3:0]  broken_parsed_type,

    output logic        broken_internal_valid,
    output logic        broken_packet_invalid,

    output logic [47:0] broken_timestamp,
    output logic [63:0] broken_match_id        // Identifies which trade to bust
);

    parameter MSG_TYPE   = 8'h42;  // ASCII 'B'
    parameter MSG_LENGTH = 19;

    `include "itch_len.vh"
    `include "itch_suppression.vh"
    `include "itch_fields_broken.vh"
    `include "itch_reset.vh"
    `include "itch_core_decode.vh"

    logic [5:0] byte_index;
    logic       is_broken_trade;
    // Suppression logic declaration
    `ITCH_SUPPRESSION_DECL
    
    // Main decode logic
    always_ff @(posedge clk) begin
         // Suppression counter update
        `ITCH_SUPPRESSION_UPDATE
        if (rst) begin
            byte_index          <= 0;
            `is_order          <= 0;
            `ITCH_RESET_LOGIC
 
        end else if (valid_in && decoder_enabled) begin

            `ITCH_CORE_DECODE(MSG_TYPE, MSG_LENGTH)
            `internal_valid <= 0;
            `packet_invalid <= 0;
 
            if (`is_order) begin
                case (byte_index)
                    // Timestamp: bytes 1-6 (48-bit nanoseconds)
                    1:  broken_timestamp[47:40] <= byte_in;
                    2:  broken_timestamp[39:32] <= byte_in;
                    3:  broken_timestamp[31:24] <= byte_in;
                    4:  broken_timestamp[23:16] <= byte_in;
                    5:  broken_timestamp[15:8]  <= byte_in;
                    6:  broken_timestamp[7:0]   <= byte_in;

                    // Match Number: bytes 7-14 (64-bit)
                    // This identifies which trade to bust
                    7:  broken_match_id[63:56]  <= byte_in;
                    8:  broken_match_id[55:48]  <= byte_in;
                    9:  broken_match_id[47:40]  <= byte_in;
                    10: broken_match_id[39:32]  <= byte_in;
                    11: broken_match_id[31:24]  <= byte_in;
                    12: broken_match_id[23:16]  <= byte_in;
                    13: broken_match_id[15:8]   <= byte_in;
                    14: broken_match_id[7:0]    <= byte_in;
                    
                    // Bytes 15-18: Reserved (skip)
                endcase

                // Assert valid on last byte
                if (byte_index == MSG_LENGTH - 1) begin
                    `internal_valid <= 1;
                    `parsed_type    <= 4'd8;  // Broken Trade = type 8
                end
            end

            // Packet overrun detection
            if (byte_index >= MSG_LENGTH && is_broken_trade)
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
