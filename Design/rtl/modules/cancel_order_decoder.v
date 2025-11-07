// =============================================
// cancel_order_decoder.v
// =============================================
//
// Description: Module to decode Cancel Order ('X') messages from ITCH payloads.
// Author: RZ
// Start Date: 04172025
// Version: 0.7
// Changelog
// =============================================
// [20250427-1] RZ: Initial version created for Cancel Order payload decoding.
// [20250428-1] RZ: Updated ports and internal signals for dispatcher integration.
// [20250428-2] RZ: Added valid_flag signal 
// [20250501-1] RZ: Initial implementation based on add_order_decoder structure with new arch.
// [20250502-1] RZ: Added self disable and zeroing of signals after message parsing completion.
// [20250505-1] RZ: Updated to use macros
// [20250506-1] RZ: Added parsed type
// =============================================
// ------------------------------------------------------------------------------------------------
// Architecture Notes:
// ------------------------------------------------------------------------------------------------
// The ITCH "Cancel Order" ('X') message has a fixed length of 23 bytes and is structured as:
//   [0]     = Message Type (ASCII 'X')
//   [1:8]   = Order Reference Number (64-bit)
//   [9:12]  = Canceled Shares (32-bit)
//   [13:22] = Reserved or padding (zeroed)
//
// The decoder speculatively begins parsing at byte 0 and asserts `internal_valid`
// after 23 valid bytes if the message type is 'X'.
// ------------------------------------------------------------------------------------------------

module cancel_order_decoder (
    input  logic        clk,
    input  logic        rst,
    input  logic [7:0]  byte_in,
    input  logic        valid_in,

    output logic [3:0] cancel_parsed_type,

    output logic        cancel_internal_valid,
    output logic        cancel_packet_invalid,

    output logic [63:0] cancel_order_ref,
    output logic [31:0] cancel_canceled_shares
);

    parameter MSG_TYPE   = 8'h58;   // ASCII 'X'
    parameter MSG_LENGTH = 23;

    `include "macros/itch_len.vh"
    `include "macros/itch_suppression.vh"
    `include "macros/field_macros/itch_fields_cancel.vh"
    `include "macros/itch_reset.vh"
    `include "macros/itch_core_decode.vh"

    logic [5:0] byte_index;
    logic       is_cancel_order;

    always_ff @(posedge clk) begin
        if (rst) begin
            byte_index              <= 0;
            `is_order         <= 0;
            `ITCH_RESET_LOGIC

        end else if (valid_in && decoder_enabled) begin
                `ITCH_CORE_DECODE(MSG_TYPE, MSG_LENGTH)
                `internal_valid <= 0;
                `packet_invalid <= 0;

            if (is_cancel_order) begin
                case (byte_index)
                    1:  cancel_order_ref[63:56]       <= byte_in;
                    2:  cancel_order_ref[55:48]       <= byte_in;
                    3:  cancel_order_ref[47:40]       <= byte_in;
                    4:  cancel_order_ref[39:32]       <= byte_in;
                    5:  cancel_order_ref[31:24]       <= byte_in;
                    6:  cancel_order_ref[23:16]       <= byte_in;
                    7:  cancel_order_ref[15:8]        <= byte_in;
                    8:  cancel_order_ref[7:0]         <= byte_in;
                    9:  cancel_canceled_shares[31:24] <= byte_in;
                    10: cancel_canceled_shares[23:16] <= byte_in;
                    11: cancel_canceled_shares[15:8]  <= byte_in;
                    12: cancel_canceled_shares[7:0]   <= byte_in;
                endcase

                if (byte_index == MSG_LENGTH - 1)
                   
                    `internal_valid <= 1;
                    `parsed_type    <= 4'd1;
            end

            if (byte_index >= MSG_LENGTH && is_cancel_order)
                
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


