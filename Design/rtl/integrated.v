// ============================================================
// integrated.v
// ============================================================
//
// Description: Top-level ITCH parser integrating all decoder modules.
//              Instantiates speculative decoders for Add, Cancel, Delete, Replace,
//              Executed, Trade, Add MPID, Broken Trade, and Executed Price messages.
//              One-byte-per-cycle input interface.
//              Aggregates all internal valids and decoded field outputs.
//
// Author: RZ
// Editor: JR
// Start Date: 20250504
// Version: 0.8
//
// Changelog
// ============================================================
// [20250504-1] RZ: Initial integration of all speculative decoder modules.
// [20250504-2] RZ: Added input and output signal declarations.
// [20250504-3] RZ: Integrated all decoder modules and connected signals.
// [20250504-4] RZ: Added waveform dump for simulation purposes.
// [20250505-1] RZ: Added comments and cleaned up code for readability.
// [20250506-1] RZ: Finalized the module and cleaned up unused signals.
// [20250507-1] RZ: Added header comments and cleaned up formatting.
// [20251007-1] JR: Added add_mpid, broken_trade, and executed_price decoders.
// ============================================================

module integrated (
    input  logic        clk,
    input  logic        rst,

    input  logic        valid_in,
    input  logic [7:0]  byte_in,

    output logic        latched_valid,
    output logic [3:0]  latched_type,
    output logic [63:0] latched_order_ref,
    output logic        latched_side,
    output logic [31:0] latched_shares,
    output logic [31:0] latched_price,
    output logic [63:0] latched_new_order_ref,
    output logic [47:0] latched_timestamp,
    output logic [63:0] latched_misc_data
);

    // Outputs from parser
    logic        parsed_valid;
    logic [3:0]  parsed_type;
    logic [63:0] order_ref;
    logic        side;
    logic [31:0] shares;
    logic [31:0] price;
    logic [63:0] new_order_ref;
    logic [47:0] timestamp;
    logic [63:0] misc_data;

    // ========================
    // Parser
    // ========================
    parser u_parser (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),
        .byte_in(byte_in),
        .parsed_valid(parsed_valid),
        .parsed_type(parsed_type),
        .order_ref(order_ref),
        .side(side),
        .shares(shares),
        .price(price),
        .new_order_ref(new_order_ref),
        .timestamp(timestamp),
        .misc_data(misc_data)
    );

    // ========================
    // Latch stage
    // ========================
    parser_latch_stage u_latch (
        .clk(clk),
        .rst(rst),
        .parsed_valid(parsed_valid),
        .parsed_type(parsed_type),
        .order_ref(order_ref),
        .side(side),
        .shares(shares),
        .price(price),
        .new_order_ref(new_order_ref),
        .timestamp(timestamp),
        .misc_data(misc_data),
        .latched_valid(latched_valid),
        .latched_type(latched_type),
        .latched_order_ref(latched_order_ref),
        .latched_side(latched_side),
        .latched_shares(latched_shares),
        .latched_price(latched_price),
        .latched_new_order_ref(latched_new_order_ref),
        .latched_timestamp(latched_timestamp),
        .latched_misc_data(latched_misc_data)
    );

endmodule
