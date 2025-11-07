// =============================================
// add_order_decoder.v 
// =============================================
//
// Description: Zero-wait speculative Add Order decoder for ITCH feed.
//              Begins decoding at byte 0 and maps order_ref from byte 1.
// Author: RZ
// Start Date: 20250430
// Version: 0.8
//
// Changelog
// =============================================
// [20250430-1] RZ: Initial speculative streaming implementation.
// [20250501-1] RZ: Renamed misc_data to stock_symbol.
// [20250501-2] RZ: Fixed byte index off-by-one.
// [20250501-3] RZ: Fully speculative decode without waiting for type match.
// [20250501-4] RZ: Rebased order_ref to start at byte 1 (byte 0 is msg_type).
// [20250502-1] RZ: Added self disable and zeroing of signals after message parsing completion.
// [20250505-1] RZ: Updated to use macros
// [20250506-1] RZ: Added parsed type output
// =============================================

// ------------------------------------------------------------------------------------------------
// Architecture Notes:
// ------------------------------------------------------------------------------------------------
// The ITCH "Add Order" ('A') message has a fixed length of 36 bytes and is structured as:
//   [0]     = Message Type (ASCII 'A')
//   [1:8]   = Order Reference Number (64-bit)
//   [9]     = Buy/Sell Indicator ('B' or 'S')
//   [10:13] = Number of Shares (32-bit)
//   [14:21] = Stock Symbol (8 ASCII characters, space-padded)
//   [22:25] = Price (32-bit, fixed-point with 4 implied decimal places)
//   [26:35] = Reserved or padding (zeroed)
//
// The decoder speculatively begins parsing at byte 0 and asserts `internal_valid`
// after 36 valid bytes if the message type is 'A'.
// ------------------------------------------------------------------------------------------------

module add_order_decoder (
    input  logic        clk,
    input  logic        rst,
    input  logic [7:0]  byte_in,
    input  logic        valid_in,

    output logic [3:0]  add_parsed_type,

    output logic        add_internal_valid,
    output logic        add_packet_invalid,

    output logic [63:0] add_order_ref,
    output logic        add_side,
    output logic [31:0] add_shares,
    output logic [31:0] add_price,
    output logic [63:0] add_stock_symbol
);

    parameter MSG_TYPE   = 8'h41;   // ASCII 'A'
    parameter MSG_LENGTH = 36;

    `include "macros/itch_len.vh"
    `include "macros/itch_suppression.vh"
    `include "macros/field_macros/itch_fields_add.vh"
    `include "macros/itch_reset.vh"
    `include "macros/itch_core_decode.vh"

    logic [5:0] byte_index;
    logic       is_add_order;
    
    // Main decode logic
    always_ff @(posedge clk) begin
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
                    1:  add_order_ref[63:56]     <= byte_in;
                    2:  add_order_ref[55:48]     <= byte_in;
                    3:  add_order_ref[47:40]     <= byte_in;
                    4:  add_order_ref[39:32]     <= byte_in;
                    5:  add_order_ref[31:24]     <= byte_in;
                    6:  add_order_ref[23:16]     <= byte_in;
                    7:  add_order_ref[15:8]      <= byte_in;
                    8:  add_order_ref[7:0]       <= byte_in;
                    9:  add_side                 <= (byte_in == "S");
                    10: add_shares[31:24]        <= byte_in;
                    11: add_shares[23:16]        <= byte_in;
                    12: add_shares[15:8]         <= byte_in;
                    13: add_shares[7:0]          <= byte_in;
                    14: add_stock_symbol[63:56]  <= byte_in;
                    15: add_stock_symbol[55:48]  <= byte_in;
                    16: add_stock_symbol[47:40]  <= byte_in;
                    17: add_stock_symbol[39:32]  <= byte_in;
                    18: add_stock_symbol[31:24]  <= byte_in;
                    19: add_stock_symbol[23:16]  <= byte_in;
                    20: add_stock_symbol[15:8]   <= byte_in;
                    21: add_stock_symbol[7:0]    <= byte_in;
                    22: add_price[31:24]         <= byte_in;
                    23: add_price[23:16]         <= byte_in;
                    24: add_price[15:8]          <= byte_in;
                    25: add_price[7:0]           <= byte_in;
                endcase

                if (byte_index == MSG_LENGTH - 1)
                    `internal_valid <= 1;
                    `parsed_type    <= 4'd0; 
                    
            end

            if (byte_index >= MSG_LENGTH && is_add_order)
             
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
