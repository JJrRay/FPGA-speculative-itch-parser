// ============================================================
// test_wrapper.v
// ============================================================
//
// Description: RTL-level test wrapper for parser and latch stage.
//              Drives `byte_in` + `valid_in`, captures and forwards latched output signals.
//              Intended for waveform inspection and integration verification.
//
// Author: RZ
// Start Date: 20250507
// Version: 0.4
//
// Changelog
// ============================================================
// [20250507-1] RZ: Created wrapper for standalone simulation of parser.
// [20250507-2] RZ: Added latch stage to capture output signals for inspection.
// [20250507-3] RZ: Added waveform dump functionality for simulation inspection.
// [20250507-4] RZ: Added comments for clarity and maintainability.
// ============================================================


module test_wrapper;

    // Inputs to parser
    logic        clk;
    logic        rst;
    logic        valid_in;
    logic [7:0]  byte_in;

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

    // Latched output signals
    logic        latched_valid;
    logic [3:0]  latched_type;
    logic [63:0] latched_order_ref;
    logic        latched_side;
    logic [31:0] latched_shares;
    logic [31:0] latched_price;
    logic [63:0] latched_new_order_ref;
    logic [47:0] latched_timestamp;
    logic [63:0] latched_misc_data;

    // DUT instantiation
    parser dut (
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

    parser_latch_stage latch (
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

    // ======================= Waveform Dump =======================
    `ifdef COCOTB_SIM
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, test_wrapper);
    end
    `endif
endmodule
