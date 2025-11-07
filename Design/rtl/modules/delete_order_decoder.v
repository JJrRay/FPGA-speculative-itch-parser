// =============================================
// delete_order_decoder.v
// =============================================
//
// Description: Speculative streaming Delete Order decoder.
//              Parses 9-byte ITCH 'D' messages from a raw byte stream.
// Author: RZ
// Start Date: 04172025
// Version: 0.6
//
// Changelog
// =============================================
// [20250428-1] RZ: Initial scaffold of Delete Order payload decoder module.
// [20250428-2] RZ: Updated ports and internal signals for valid_flag
// [20250501-1] RZ: Initial implementation based on new arch.
// [20250502-1] RZ: Added self disable and zeroing of signals after message parsing completion.
// [20250505-1] RZ: Updated to use macros
// [20250506-1] RZ: Added parsed type
// =============================================
// ------------------------------------------------------------------------------------------------
// Protocol Version Note:
// ------------------------------------------------------------------------------------------------
// While older ITCH variants (e.g., ITCH 4.1 or proprietary BATS feeds) may define a Delete Order 
// message with 19 bytes including symbol information, the Nasdaq ITCH 5.0 specification defines 
// the 'D' message as exactly 9 bytes: a 1-byte message type and 8-byte order reference.
// This module implements the 9-byte ITCH 5.0 format.
// ------------------------------------------------------------------------------------------------
// ------------------------------------------------------------------------------------------------
// Architecture Notes:
// ------------------------------------------------------------------------------------------------
// The ITCH "Delete Order" ('D') message (Nasdaq ITCH 5.0) has a fixed length of 9 bytes and is structured as:
//   [0]      = Message Type (ASCII 'D')
//   [1:8]    = Order Reference Number (64-bit)
//
// This decoder consumes a byte-aligned, per-cycle stream of ITCH bytes and speculatively 
// begins parsing at cycle 0. On cycle 0, it captures the message type and immediately decodes
// byte 1 as `order_ref[63:56]`. Parallel validation confirms whether the message is of type 'D'.
// The decoder asserts `internal_valid` after 9 valid cycles only if the type matches.
//
// Inputs:
//   - clk               : system clock
//   - rst               : synchronous reset
//   - byte_in[7:0]      : ITCH byte stream (1 byte per cycle)
//   - valid_in          : asserted high when byte_in is valid
//
// Outputs:
//   - internal_valid    : one-cycle pulse when a valid Delete Order message is fully parsed
//   - packet_invalid    : asserted if message length overruns unexpectedly (optional use)
//   - order_ref         : 64-bit parsed order reference number
// ------------------------------------------------------------------------------------------------

module delete_order_decoder (
    input  logic        clk,
    input  logic        rst,
    input  logic [7:0]  byte_in,
    input  logic        valid_in,

    output logic [3:0] delete_parsed_type,

    output logic        delete_internal_valid,
    output logic        delete_packet_invalid,

    output logic [63:0] delete_order_ref
    );

    parameter MSG_TYPE   = 8'h44;  // ASCII 'D'
    parameter MSG_LENGTH = 9;

    `include "macros/itch_len.vh"
    `include "macros/itch_suppression.vh"
    `include "macros/field_macros/itch_fields_delete.vh"
    `include "macros/itch_reset.vh"
    `include "macros/itch_core_decode.vh"

    logic [5:0] byte_index;
    logic       is_delete_order;

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
                    1: delete_order_ref[63:56] <= byte_in;
                    2: delete_order_ref[55:48] <= byte_in;
                    3: delete_order_ref[47:40] <= byte_in;
                    4: delete_order_ref[39:32] <= byte_in;
                    5: delete_order_ref[31:24] <= byte_in;
                    6: delete_order_ref[23:16] <= byte_in;
                    7: delete_order_ref[15:8]  <= byte_in;
                    8: delete_order_ref[7:0]   <= byte_in;
                endcase

                if (byte_index == MSG_LENGTH - 1)
              
                    `internal_valid <= 1;
                    `parsed_type    <= 4'd2;
            end

            if (byte_index >= MSG_LENGTH && is_delete_order)
 
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





