// =============================================
// executed_price_decoder.v
// =============================================
//
// Description: Speculative streaming Order Executed With Price decoder.
//              Parses 36-byte ITCH 'C' messages from a raw byte stream.
//              Similar to 'E' (Executed Order) but includes execution price.
//
// Author: RZ
// Start Date: 20250508
// Version: 1.0
//
// Changelog
// =============================================
// [20250508-1] Initial implementation based on executed_order_decoder with price field.
// =============================================

// ------------------------------------------------------------------------------------------------
// Architecture Notes:
// ------------------------------------------------------------------------------------------------
// The ITCH "Order Executed With Price" ('C') message has a fixed length of 36 bytes and is 
// structured as:
//   [0]     = Message Type (ASCII 'C')
//   [1:6]   = Timestamp (48-bit nanoseconds)
//   [7:14]  = Order Reference Number (64-bit)
//   [15:18] = Executed Shares (32-bit)
//   [19:26] = Match Number (64-bit)
//   [27]    = Printable ('Y' = print on tape, 'N' = don't print)
//   [28:31] = Execution Price (32-bit, 4 implied decimal places)
//   [32:35] = Reserved (zeroed)
//
// The decoder speculatively begins parsing at byte 0 and asserts `internal_valid`
// after 36 valid bytes if the message type is 'C'.
//
// Key Difference from 'E': Includes execution price (useful when order executed at different
// price than original order price, e.g., price improvement or odd lot trades)
// ------------------------------------------------------------------------------------------------

module executed_price_decoder (
    input  logic        clk,
    input  logic        rst,
    input  logic [7:0]  byte_in,
    input  logic        valid_in,

    output logic [3:0]  exec_price_parsed_type,

    output logic        exec_price_internal_valid,
    output logic        exec_price_packet_invalid,

    output logic [47:0] exec_price_timestamp,
    output logic [63:0] exec_price_order_ref,
    output logic [31:0] exec_price_shares,
    output logic [63:0] exec_price_match_id,
    output logic        exec_price_printable,     // NEW: Print flag
    output logic [31:0] exec_price_price          // NEW: Execution price
);

    parameter MSG_TYPE   = 8'h43;  // ASCII 'C'
    parameter MSG_LENGTH = 36;

    `include "macros/itch_len.vh"
    `include "macros/itch_suppression.vh"
    `include "macros/field_macros/itch_fields_exec_price.vh"
    `include "macros/itch_reset.vh"
    `include "macros/itch_core_decode.vh"

    logic [5:0] byte_index;
    logic       is_exec_price_order;

    // Main decode logic
    always_ff @(posedge clk) begin
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
                    // Timestamp: bytes 1-6 (48-bit)
                    1:  exec_price_timestamp[47:40] <= byte_in;
                    2:  exec_price_timestamp[39:32] <= byte_in;
                    3:  exec_price_timestamp[31:24] <= byte_in;
                    4:  exec_price_timestamp[23:16] <= byte_in;
                    5:  exec_price_timestamp[15:8]  <= byte_in;
                    6:  exec_price_timestamp[7:0]   <= byte_in;

                    // Order Reference Number: bytes 7-14
                    7:  exec_price_order_ref[63:56] <= byte_in;
                    8:  exec_price_order_ref[55:48] <= byte_in;
                    9:  exec_price_order_ref[47:40] <= byte_in;
                    10: exec_price_order_ref[39:32] <= byte_in;
                    11: exec_price_order_ref[31:24] <= byte_in;
                    12: exec_price_order_ref[23:16] <= byte_in;
                    13: exec_price_order_ref[15:8]  <= byte_in;
                    14: exec_price_order_ref[7:0]   <= byte_in;

                    // Executed Shares: bytes 15-18
                    15: exec_price_shares[31:24]    <= byte_in;
                    16: exec_price_shares[23:16]    <= byte_in;
                    17: exec_price_shares[15:8]     <= byte_in;
                    18: exec_price_shares[7:0]      <= byte_in;

                    // Match Number: bytes 19-26
                    19: exec_price_match_id[63:56]  <= byte_in;
                    20: exec_price_match_id[55:48]  <= byte_in;
                    21: exec_price_match_id[47:40]  <= byte_in;
                    22: exec_price_match_id[39:32]  <= byte_in;
                    23: exec_price_match_id[31:24]  <= byte_in;
                    24: exec_price_match_id[23:16]  <= byte_in;
                    25: exec_price_match_id[15:8]   <= byte_in;
                    26: exec_price_match_id[7:0]    <= byte_in;
                    
                    // Printable: byte 27 ('Y' or 'N')
                    27: exec_price_printable        <= (byte_in == "Y");
                    
                    // Execution Price: bytes 28-31 (32-bit, 4 decimal places)
                    28: exec_price_price[31:24]     <= byte_in;
                    29: exec_price_price[23:16]     <= byte_in;
                    30: exec_price_price[15:8]      <= byte_in;
                    31: exec_price_price[7:0]       <= byte_in;
                    
                    // Bytes 32-35: Reserved (skip)
                endcase

                // Assert valid on last byte
                if (byte_index == MSG_LENGTH - 1) begin
                    `internal_valid <= 1;
                    `parsed_type    <= 4'd7;  // Executed With Price = type 7
                end
            end

            // Packet overrun detection
            if (byte_index >= MSG_LENGTH && is_exec_price_order)
                `packet_invalid <= 1;
        end

        // Mid-packet abort handling
        if (`is_order && (
            (valid_in == 0 && byte_index > 0 && byte_index < MSG_LENGTH) ||
            (byte_index >= MSG_LENGTH)
        ))
            `packet_invalid <= 1;

        `ITCH_RECHECK_OR_SUPPRESS(MSG_TYPE, MSG_LENGTH)
        `include "macros/itch_abort_on_valid_drop.vh"
    end

endmodule
