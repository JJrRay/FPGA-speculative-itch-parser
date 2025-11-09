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
// [20250508-1] RZ: Added add_mpid, broken_trade, and executed_price decoders.
// ============================================================

module integrated (
    input  logic        clk,
    input  logic        rst,
    input  logic [7:0]  byte_in,
    input  logic        valid_in,

    output logic        add_internal_valid,
    output logic        cancel_internal_valid,
    output logic        delete_internal_valid,
    output logic        replace_internal_valid,
    output logic        exec_internal_valid,
    output logic        trade_internal_valid,
    output logic        add_mpid_internal_valid,
    output logic        broken_internal_valid,
    output logic        exec_price_internal_valid,

    output logic [3:0]  add_parsed_type,
    output logic [3:0]  cancel_parsed_type,
    output logic [3:0]  delete_parsed_type,
    output logic [3:0]  replace_parsed_type,
    output logic [3:0]  exec_parsed_type,
    output logic [3:0]  trade_parsed_type,
    output logic [3:0]  add_mpid_parsed_type,
    output logic [3:0]  broken_parsed_type,
    output logic [3:0]  exec_price_parsed_type
);

    // Add Order signals
    logic        add_packet_invalid;
    logic [63:0] add_order_ref;
    logic        add_side;
    logic [31:0] add_shares;
    logic [31:0] add_price;
    logic [63:0] add_stock_symbol;

    // Cancel Order signals
    logic        cancel_packet_invalid;
    logic [63:0] cancel_order_ref;
    logic [31:0] cancel_canceled_shares;

    // Delete Order signals
    logic        delete_packet_invalid;
    logic [63:0] delete_order_ref;

    // Replace Order signals
    logic        replace_packet_invalid;
    logic [63:0] replace_old_order_ref;
    logic [63:0] replace_new_order_ref;
    logic [31:0] replace_shares;
    logic [31:0] replace_price;

    // Executed Order signals
    logic [63:0] exec_order_ref;
    logic [31:0] exec_shares;
    logic [63:0] exec_match_id;
    logic [47:0] exec_timestamp;

    // Trade signals
    logic [47:0] trade_timestamp;
    logic [63:0] trade_order_ref;
    logic [7:0]  trade_side;
    logic [31:0] trade_shares;
    logic [63:0] trade_match_id;
    logic [31:0] trade_price;
    logic [63:0] trade_stock_symbol;

    // Add Order MPID signals
    logic        add_mpid_packet_invalid;
    logic [63:0] add_mpid_order_ref;
    logic        add_mpid_side;
    logic [31:0] add_mpid_shares;
    logic [31:0] add_mpid_price;
    logic [63:0] add_mpid_stock_symbol;
    logic [31:0] add_mpid_attribution;

    // Broken Trade signals
    logic        broken_packet_invalid;
    logic [47:0] broken_timestamp;
    logic [63:0] broken_match_id;

    // Executed Price signals
    logic        exec_price_packet_invalid;
    logic [47:0] exec_price_timestamp;
    logic [63:0] exec_price_order_ref;
    logic [31:0] exec_price_shares;
    logic [63:0] exec_price_match_id;
    logic        exec_price_printable;
    logic [31:0] exec_price_price;

    // ======================= Decoder Instantiations =======================

    add_order_decoder u_add (
        .clk(clk),
        .rst(rst),
        .byte_in(byte_in),
        .valid_in(valid_in),
        .add_internal_valid(add_internal_valid),
        .add_packet_invalid(add_packet_invalid),
        .add_order_ref(add_order_ref),
        .add_side(add_side),
        .add_shares(add_shares),
        .add_price(add_price),
        .add_parsed_type(add_parsed_type),
        .add_stock_symbol(add_stock_symbol)
    );

    cancel_order_decoder u_cancel (
        .clk(clk),
        .rst(rst),
        .byte_in(byte_in),
        .valid_in(valid_in),
        .cancel_internal_valid(cancel_internal_valid),
        .cancel_packet_invalid(cancel_packet_invalid),
        .cancel_order_ref(cancel_order_ref),
        .cancel_parsed_type(cancel_parsed_type),
        .cancel_canceled_shares(cancel_canceled_shares)
    );

    delete_order_decoder u_delete (
        .clk(clk),
        .rst(rst),
        .byte_in(byte_in),
        .valid_in(valid_in),
        .delete_internal_valid(delete_internal_valid),
        .delete_parsed_type(delete_parsed_type),
        .delete_order_ref(delete_order_ref)
    );

    replace_order_decoder u_replace (
        .clk(clk),
        .rst(rst),
        .byte_in(byte_in),
        .valid_in(valid_in),
        .replace_internal_valid(replace_internal_valid),
        .replace_old_order_ref(replace_old_order_ref),
        .replace_new_order_ref(replace_new_order_ref),
        .replace_shares(replace_shares),
        .replace_parsed_type(replace_parsed_type),
        .replace_price(replace_price)
    );

    executed_order_decoder u_executed (
        .clk(clk),
        .rst(rst),
        .byte_in(byte_in),
        .valid_in(valid_in),
        .exec_internal_valid(exec_internal_valid),
        .exec_order_ref(exec_order_ref),
        .exec_shares(exec_shares),
        .exec_match_id(exec_match_id),
        .exec_parsed_type(exec_parsed_type),
        .exec_timestamp(exec_timestamp)
    );

    trade_decoder u_trade (
        .clk(clk),
        .rst(rst),
        .byte_in(byte_in),
        .valid_in(valid_in),
        .trade_internal_valid(trade_internal_valid),
        .trade_timestamp(trade_timestamp),
        .trade_order_ref(trade_order_ref),
        .trade_side(trade_side),
        .trade_shares(trade_shares),
        .trade_price(trade_price),
        .trade_match_id(trade_match_id),
        .trade_parsed_type(trade_parsed_type),
        .trade_stock_symbol(trade_stock_symbol)
    );

    add_order_mpid_decoder u_add_mpid (
        .clk(clk),
        .rst(rst),
        .byte_in(byte_in),
        .valid_in(valid_in),
        .add_mpid_internal_valid(add_mpid_internal_valid),
        .add_mpid_packet_invalid(add_mpid_packet_invalid),
        .add_mpid_order_ref(add_mpid_order_ref),
        .add_mpid_side(add_mpid_side),
        .add_mpid_shares(add_mpid_shares),
        .add_mpid_price(add_mpid_price),
        .add_mpid_parsed_type(add_mpid_parsed_type),
        .add_mpid_stock_symbol(add_mpid_stock_symbol),
        .add_mpid_attribution(add_mpid_attribution)
    );

    broken_trade_decoder u_broken (
        .clk(clk),
        .rst(rst),
        .byte_in(byte_in),
        .valid_in(valid_in),
        .broken_internal_valid(broken_internal_valid),
        .broken_packet_invalid(broken_packet_invalid),
        .broken_timestamp(broken_timestamp),
        .broken_match_id(broken_match_id),
        .broken_parsed_type(broken_parsed_type)
    );

    executed_price_decoder u_exec_price (
        .clk(clk),
        .rst(rst),
        .byte_in(byte_in),
        .valid_in(valid_in),
        .exec_price_internal_valid(exec_price_internal_valid),
        .exec_price_packet_invalid(exec_price_packet_invalid),
        .exec_price_timestamp(exec_price_timestamp),
        .exec_price_order_ref(exec_price_order_ref),
        .exec_price_shares(exec_price_shares),
        .exec_price_match_id(exec_price_match_id),
        .exec_price_printable(exec_price_printable),
        .exec_price_price(exec_price_price),
        .exec_price_parsed_type(exec_price_parsed_type)
    );

    // ======================= Waveform Dump =======================
    `ifdef COCOTB_SIM
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, integrated);
    end
    `endif

endmodule