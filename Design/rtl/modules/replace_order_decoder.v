// =============================================
// replace_order_decoder.v
// =============================================
//
// Description: Speculative streaming Replace Order decoder.
//              Parses 25-byte ITCH 'U' messages from a raw byte stream.
//
// Author: RZ
// Start Date: 20250428
// Version: 0.6
//
// Changelog
// =============================================
// [20250428-1] RZ: Initial Replace Order decoder implementation.
// [20250428-2] RZ: Added valid_flag signal
// [20250501-1] RZ: Initial implementation modeled after add_order_decoder module under new architecture.
// [20250502-1] RZ: Added self disable and zeroing of signals after message parsing completion.
// [20250505-1] RZ: Updated to use macros
// [20250506-1] RZ: Added parsed type
// =============================================

// ------------------------------------------------------------------------------------------------
// Protocol Version Note:
// ------------------------------------------------------------------------------------------------
// While some ITCH variants or academic simulations include stock symbol or participant metadata 
// (e.g., total 35 bytes), the Nasdaq ITCH 5.0 spec defines the Replace Order ('U') message as 
// exactly 25 bytes: 1-byte type, 2x 64-bit refs, 32-bit shares, and 32-bit price.
// This decoder implements the 27-byte ITCH 5.0 version.
// ------------------------------------------------------------------------------------------------
//
// ------------------------------------------------------------------------------------------------
// Architecture Notes:
// ------------------------------------------------------------------------------------------------
// The ITCH "Replace Order" ('U') message has a fixed length of 27 bytes and is structured as:
//   [0]     = Message Type (ASCII 'U')
//   [1:8]   = Original Order Reference Number (64-bit)
//   [9:16]  = New Order Reference Number (64-bit)
//   [17:20] = Updated Shares (32-bit)
//   [21:24] = Updated Price (32-bit)
//   [25:26] = Reserved (zeroed)
//
// The decoder speculatively begins parsing at byte 0 and asserts `internal_valid`
// after 27 valid bytes if the message type is 'U'.
// ------------------------------------------------------------------------------------------------

module replace_order_decoder (
    input  logic        clk,
    input  logic        rst,
    input  logic [7:0]  byte_in,
    input  logic        valid_in,

    output logic [3:0] replace_parsed_type,

    output logic        replace_internal_valid,
    output logic        replace_packet_invalid,

    output logic [63:0] replace_old_order_ref,
    output logic [63:0] replace_new_order_ref,
    output logic [31:0] replace_shares,
    output logic [31:0] replace_price
);

    parameter MSG_TYPE   = 8'h55;  // ASCII 'U'
    parameter MSG_LENGTH = 27;

    `include "macros/itch_len.vh"
    `include "macros/itch_suppression.vh"
    `include "macros/field_macros/itch_fields_replace.vh"
    `include "macros/itch_reset.vh"
    `include "macros/itch_core_decode.vh"

    logic [5:0] byte_index;
    logic       is_replace_order;

    // Main decode logic
    always_ff @(posedge clk) begin
        if (rst) begin
            byte_index              <= 0;
            `is_order          <= 0;
            `ITCH_RESET_LOGIC

        end else if (valid_in && decoder_enabled) begin

            `ITCH_CORE_DECODE(MSG_TYPE, MSG_LENGTH)
            `internal_valid <= 0;
            `packet_invalid <= 0;

            if (`is_order) begin
                case (byte_index)
                    1:  replace_old_order_ref[63:56] <= byte_in;
                    2:  replace_old_order_ref[55:48] <= byte_in;
                    3:  replace_old_order_ref[47:40] <= byte_in;
                    4:  replace_old_order_ref[39:32] <= byte_in;
                    5:  replace_old_order_ref[31:24] <= byte_in;
                    6:  replace_old_order_ref[23:16] <= byte_in;
                    7:  replace_old_order_ref[15:8]  <= byte_in;
                    8:  replace_old_order_ref[7:0]   <= byte_in;
                    9:  replace_new_order_ref[63:56] <= byte_in;
                    10: replace_new_order_ref[55:48] <= byte_in;
                    11: replace_new_order_ref[47:40] <= byte_in;
                    12: replace_new_order_ref[39:32] <= byte_in;
                    13: replace_new_order_ref[31:24] <= byte_in;
                    14: replace_new_order_ref[23:16] <= byte_in;
                    15: replace_new_order_ref[15:8]  <= byte_in;
                    16: replace_new_order_ref[7:0]   <= byte_in;
                    17: replace_shares[31:24] <= byte_in;
                    18: replace_shares[23:16] <= byte_in;
                    19: replace_shares[15:8]  <= byte_in;
                    20: replace_shares[7:0]   <= byte_in;
                    21: replace_price[31:24] <= byte_in;
                    22: replace_price[23:16] <= byte_in;
                    23: replace_price[15:8]  <= byte_in;
                    24: replace_price[7:0]   <= byte_in;
                    //   [25:26]  = Reserved bytes (ignored)
                endcase

                if (byte_index == MSG_LENGTH - 1)
                    
                    `internal_valid <= 1;
                    `parsed_type    <= 4'd4;
            end

            if (byte_index >= MSG_LENGTH && is_replace_order)
                 
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
