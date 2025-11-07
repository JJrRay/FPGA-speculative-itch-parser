// =============================================
// executed_order_decoder.v
// =============================================
//
// Description: Speculative streaming Executed Order decoder.
//              Parses 30-byte ITCH 'E' messages from a raw byte stream.
//
// Author: RZ
// Start Date: 20250501
// Version: 0.5
//
// Changelog
// =============================================
// [20250501-1] RZ: Initial implementation based on cancel and replace decoder patterns.
// [20250502-1] RZ: Added self disable and zeroing of signals after message parsing completion.
// [20250504-1] RZ: Fixed timestamp width to 48-bit and corrected field byte ranges.
// [20250505-1] RZ: Updated to use macros
// [20250506-1] RZ: Added parsed type
// =============================================

// ------------------------------------------------------------------------------------------------
// ------------------------------------------------------------------------------------------------
// Architecture Notes:
// ------------------------------------------------------------------------------------------------
// The ITCH "Executed Order" ('E') message has a fixed length of 30 bytes and is structured as:
//   [0]     = Message Type (ASCII 'E')
//   [1:6]   = Timestamp (48-bit)
//   [7:14]  = Order Reference Number (64-bit)
//   [15:18] = Executed Shares (32-bit)
//   [19:26] = Match ID (64-bit)
//   [27:29] = Reserved (zeroed)
//
// The decoder speculatively begins parsing at byte 0 and asserts `internal_valid`
// after 30 valid bytes if the message type is 'E'.
// ------------------------------------------------------------------------------------------------


module executed_order_decoder (
    input  logic        clk,
    input  logic        rst,
    input  logic [7:0]  byte_in,
    input  logic        valid_in,

    output logic [3:0] exec_parsed_type,


    output logic        exec_internal_valid,
    output logic        exec_packet_invalid,

    output logic [63:0] exec_order_ref,
    output logic [31:0] exec_shares,
    output logic [63:0] exec_match_id,
    output logic [47:0] exec_timestamp
);

    parameter MSG_TYPE   = 8'h45;  // ASCII 'E'
    parameter MSG_LENGTH = 30;

    `include "macros/itch_len.vh"
    `include "macros/itch_suppression.vh"
    `include "macros/field_macros/itch_fields_executed.vh"
    `include "macros/itch_reset.vh"
    `include "macros/itch_core_decode.vh"

    logic [5:0] byte_index;
    logic       is_exec_order;

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
                    1:  exec_timestamp[47:40] <= byte_in;
                    2:  exec_timestamp[39:32] <= byte_in;
                    3:  exec_timestamp[31:24] <= byte_in;
                    4:  exec_timestamp[23:16] <= byte_in;
                    5:  exec_timestamp[15:8]  <= byte_in;
                    6:  exec_timestamp[7:0]   <= byte_in;

                    7:  exec_order_ref[63:56] <= byte_in;
                    8:  exec_order_ref[55:48] <= byte_in;
                    9:  exec_order_ref[47:40] <= byte_in;
                    10: exec_order_ref[39:32] <= byte_in;
                    11: exec_order_ref[31:24] <= byte_in;
                    12: exec_order_ref[23:16] <= byte_in;
                    13: exec_order_ref[15:8]  <= byte_in;
                    14: exec_order_ref[7:0]   <= byte_in;

                    15: exec_shares[31:24]    <= byte_in;
                    16: exec_shares[23:16]    <= byte_in;
                    17: exec_shares[15:8]     <= byte_in;
                    18: exec_shares[7:0]      <= byte_in;

                    19: exec_match_id[63:56]  <= byte_in;
                    20: exec_match_id[55:48]  <= byte_in;
                    21: exec_match_id[47:40]  <= byte_in;
                    22: exec_match_id[39:32]  <= byte_in;
                    23: exec_match_id[31:24]  <= byte_in;
                    24: exec_match_id[23:16]  <= byte_in;
                    25: exec_match_id[15:8]   <= byte_in;
                    26: exec_match_id[7:0]    <= byte_in;
                endcase

                if (byte_index == MSG_LENGTH - 1)
               
                    `internal_valid <= 1;
                    `parsed_type    <= 4'd3;
            end

            if (byte_index >= MSG_LENGTH && is_exec_order)
 
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
