// ============================================================
// parser_latch_stage.v
// ============================================================
//
// Description: Latch stage for parsed ITCH output fields.
//              Buffers parser-level outputs to make them stable for downstream modules.
//              Enabled only when `parsed_valid` is high.
//
// Author: RZ
// Start Date: 20250507
// Version: 0.1
//
// Changelog
// ============================================================
// [20250507-1] RZ: Implemented 1-cycle valid-guarded latch stage for parsed outputs.
// ============================================================


module parser_latch_stage (
    input  logic        clk,
    input  logic        rst,

    input  logic        parsed_valid,
    input  logic [3:0]  parsed_type,
    input  logic [63:0] order_ref,
    input  logic        side,
    input  logic [31:0] shares,
    input  logic [31:0] price,
    input  logic [63:0] new_order_ref,
    input  logic [47:0] timestamp,
    input  logic [63:0] misc_data,

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

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            latched_valid         <= 0;
            latched_type          <= 4'd0;
            latched_order_ref     <= 64'd0;
            latched_side          <= 1'b0;
            latched_shares        <= 32'd0;
            latched_price         <= 32'd0;
            latched_new_order_ref <= 64'd0;
            latched_timestamp     <= 48'd0;
            latched_misc_data     <= 64'd0;
        end else if (parsed_valid) begin
            latched_valid         <= 1;
            latched_type          <= parsed_type;
            latched_order_ref     <= order_ref;
            latched_side          <= side;
            latched_shares        <= shares;
            latched_price         <= price;
            latched_new_order_ref <= new_order_ref;
            latched_timestamp     <= timestamp;
            latched_misc_data     <= misc_data;
        end
    end

endmodule
