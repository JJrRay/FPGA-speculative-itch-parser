// ============================================================
// integrated.v
// ============================================================
//
// Description: Top-level ITCH parser integrating all decoder modules.
//              Instantiates speculative decoders for Add, Cancel, Delete, Replace,
//              Executed, and Trade messages, with one-byte-per-cycle input interface.
//              Aggregates all internal valids and decoded field outputs.
//
// Author: RZ
// Start Date: 20250504
// Version: 0.7
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

    output logic [3:0] add_parsed_type,
    output logic [3:0] cancel_parsed_type,
    output logic [3:0] delete_parsed_type,
    output logic [3:0] replace_parsed_type,
    output logic [3:0] exec_parsed_type,
    output logic [3:0] trade_parsed_type


    
    );

    logic        add_packet_invalid;
    logic [63:0] add_order_ref;
    logic        add_side;
    logic [31:0] add_shares;
    logic [31:0] add_price;
    logic [63:0] add_stock_symbol;

    logic        cancel_packet_invalid;
    logic [63:0] cancel_order_ref;
    logic [31:0] cancel_canceled_shares;

    logic        delete_packet_invalid;
    logic [63:0] delete_order_ref;

    logic        replace_packet_invalid;
    logic [63:0] replace_old_order_ref;
    logic [63:0] replace_new_order_ref;
    logic [31:0] replace_shares;
    logic [31:0] replace_price;

    logic [63:0] exec_order_ref;
    logic [31:0] exec_shares;
    logic [63:0] exec_match_id;
    logic [47:0] exec_timestamp;

    logic [47:0] trade_timestamp;
    logic [63:0] trade_order_ref;
    logic [7:0]  trade_side;
    logic [31:0] trade_shares;
    logic [63:0] trade_match_id;
    logic [31:0] trade_price;
    logic [63:0] trade_stock_symbol;

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

    delete_order_decoder u_delete_order_decoder (
        .clk                   (clk),
        .rst                   (rst),
        .byte_in               (byte_in),
        .valid_in              (valid_in),
        .delete_internal_valid(delete_internal_valid),
        .delete_parsed_type(delete_parsed_type),
        .delete_order_ref      (delete_order_ref)
    );

    replace_order_decoder u_replace_order_decoder (
        .clk                   (clk),
        .rst                   (rst),
        .byte_in               (byte_in),
        .valid_in              (valid_in),
        .replace_internal_valid(replace_internal_valid),
        .replace_old_order_ref (replace_old_order_ref),
        .replace_new_order_ref (replace_new_order_ref),
        .replace_shares        (replace_shares),
        .replace_parsed_type(replace_parsed_type),
        .replace_price         (replace_price)
    );

    executed_order_decoder u_executed_order_decoder (
        .clk                 (clk),
        .rst                 (rst),
        .byte_in             (byte_in),
        .valid_in            (valid_in),
        .exec_internal_valid (exec_internal_valid),
        .exec_order_ref      (exec_order_ref),
        .exec_shares         (exec_shares),
        .exec_match_id       (exec_match_id),
        .exec_parsed_type(exec_parsed_type),
        .exec_timestamp      (exec_timestamp)
    );

    trade_decoder u_trade_decoder (
        .clk                (clk),
        .rst                (rst),
        .byte_in            (byte_in),
        .valid_in           (valid_in),
        .trade_internal_valid (trade_internal_valid),
        .trade_timestamp    (trade_timestamp),
        .trade_order_ref    (trade_order_ref),
        .trade_side         (trade_side),
        .trade_shares       (trade_shares),
        .trade_price        (trade_price),
        .trade_match_id     (trade_match_id),
        .trade_parsed_type(trade_parsed_type),
        .trade_stock_symbol (trade_stock_symbol)
    );

    // ======================= Waveform Dump =======================
    `ifdef COCOTB_SIM
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, integrated);
    end
    `endif

endmodule
