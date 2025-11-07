// ============================================================
// parser.v
// ============================================================
//
// Description: Unified parsing core for all ITCH message types.
//              Wraps individual speculative decoders with arbitration and mux logic.
//              Produces parsed field outputs and a combined valid + type signal.
//
// Author: RZ
// Start Date: 20250507
// Version: 0.4
//
// Changelog
// ============================================================
// [20250507-1] RZ: Built arbitration + mux logic for decoded fields.
// [20250507-2] RZ: Added one-hot valid check for decoder outputs.
// [20250507-3] RZ: Added output selection logic for parsed fields.
// [20250507-4] RZ: Added comments and cleaned up code formatting.
// ============================================================


module parser (
    input  logic        clk,
    input  logic        rst,
    input  logic [7:0]  byte_in,
    input  logic        valid_in,

    output logic        parsed_valid,
    output logic [3:0]  parsed_type,
    output logic [63:0] order_ref,
    output logic        side,
    output logic [31:0] shares,
    output logic [31:0] price,
    output logic [63:0] new_order_ref,
    output logic [47:0] timestamp,
    output logic [63:0] misc_data
);
// Signals
    // Internal valid signals
    logic add_internal_valid, cancel_internal_valid, delete_internal_valid;
    logic replace_internal_valid, exec_internal_valid, trade_internal_valid;

    // Output fields
    logic [3:0]  add_parsed_type, cancel_parsed_type, delete_parsed_type;
    logic [3:0]  replace_parsed_type, exec_parsed_type, trade_parsed_type;

    logic [63:0] add_order_ref, cancel_order_ref, delete_order_ref;
    logic [63:0] replace_old_order_ref, replace_new_order_ref;
    logic [63:0] exec_order_ref, trade_order_ref;

    logic        add_side, trade_side;
    logic [31:0] add_shares, cancel_canceled_shares;
    logic [31:0] replace_shares, exec_shares, trade_shares;
    logic [31:0] add_price, replace_price, trade_price;

    logic [63:0] add_stock_symbol;
    logic [63:0] exec_match_id, trade_match_id;

    logic [47:0] exec_timestamp, trade_timestamp;
// End of signals
    // ==========================
    // Decoder instantiations
    // ==========================
    add_order_decoder add_dec (
        .clk(clk), .rst(rst), .byte_in(byte_in), .valid_in(valid_in),
        .add_internal_valid(add_internal_valid),
        .add_parsed_type(add_parsed_type),
        .add_order_ref(add_order_ref),
        .add_side(add_side),
        .add_shares(add_shares),
        .add_price(add_price),
        .add_stock_symbol(add_stock_symbol)
    );

    cancel_order_decoder cancel_dec (
        .clk(clk), .rst(rst), .byte_in(byte_in), .valid_in(valid_in),
        .cancel_internal_valid(cancel_internal_valid),
        .cancel_parsed_type(cancel_parsed_type),
        .cancel_order_ref(cancel_order_ref),
        .cancel_canceled_shares(cancel_canceled_shares)
    );

    delete_order_decoder delete_dec (
        .clk(clk), .rst(rst), .byte_in(byte_in), .valid_in(valid_in),
        .delete_internal_valid(delete_internal_valid),
        .delete_parsed_type(delete_parsed_type),
        .delete_order_ref(delete_order_ref)
    );

    replace_order_decoder replace_dec (
        .clk(clk), .rst(rst), .byte_in(byte_in), .valid_in(valid_in),
        .replace_internal_valid(replace_internal_valid),
        .replace_parsed_type(replace_parsed_type),
        .replace_old_order_ref(replace_old_order_ref),
        .replace_new_order_ref(replace_new_order_ref),
        .replace_shares(replace_shares),
        .replace_price(replace_price)
    );

    executed_order_decoder exec_dec (
        .clk(clk), .rst(rst), .byte_in(byte_in), .valid_in(valid_in),
        .exec_internal_valid(exec_internal_valid),
        .exec_parsed_type(exec_parsed_type),
        .exec_order_ref(exec_order_ref),
        .exec_shares(exec_shares),
        .exec_timestamp(exec_timestamp),
        .exec_match_id(exec_match_id)
    );

    trade_decoder trade_dec (
        .clk(clk), .rst(rst), .byte_in(byte_in), .valid_in(valid_in),
        .trade_internal_valid(trade_internal_valid),
        .trade_parsed_type(trade_parsed_type),
        .trade_order_ref(trade_order_ref),
        .trade_side(trade_side),
        .trade_shares(trade_shares),
        .trade_price(trade_price),
        .trade_match_id(trade_match_id),
        .trade_timestamp(trade_timestamp)
    );

    // ==========================
    // One-hot valid check
    // ==========================
    wire onehot_detect = $onehot({
        add_internal_valid,
        cancel_internal_valid,
        delete_internal_valid,
        replace_internal_valid,
        exec_internal_valid,
        trade_internal_valid
    });

    wire internal_valid_any = add_internal_valid     |
                              cancel_internal_valid  |
                              delete_internal_valid  |
                              replace_internal_valid |
                              exec_internal_valid    |
                              trade_internal_valid;

    assign parsed_valid = internal_valid_any && onehot_detect;

    // ==========================
    // Output Selection
    // ==========================
    assign parsed_type =
        add_internal_valid     ? add_parsed_type    :
        cancel_internal_valid  ? cancel_parsed_type :
        delete_internal_valid  ? delete_parsed_type :
        replace_internal_valid ? replace_parsed_type :
        exec_internal_valid    ? exec_parsed_type   :
        trade_internal_valid   ? trade_parsed_type  : 4'd0;

    assign order_ref =
        add_internal_valid     ? add_order_ref    :
        cancel_internal_valid  ? cancel_order_ref :
        delete_internal_valid  ? delete_order_ref :
        exec_internal_valid    ? exec_order_ref   :
        trade_internal_valid   ? trade_order_ref  : 64'd0;

    assign side =
        add_internal_valid     ? add_side         :
        trade_internal_valid   ? trade_side       : 1'b0;

    assign shares =
        add_internal_valid     ? add_shares             :
        cancel_internal_valid  ? cancel_canceled_shares :
        replace_internal_valid ? replace_shares         :
        exec_internal_valid    ? exec_shares            :
        trade_internal_valid   ? trade_shares           : 32'd0;

    assign price =
        add_internal_valid     ? add_price         :
        replace_internal_valid ? replace_price     :
        trade_internal_valid   ? trade_price       : 32'd0;

    assign new_order_ref =
        replace_internal_valid ? replace_new_order_ref : 64'd0;

    assign timestamp =
        exec_internal_valid    ? exec_timestamp    :
        trade_internal_valid   ? trade_timestamp   : 32'd0;

    assign misc_data =
        add_internal_valid     ? add_stock_symbol      :
        trade_internal_valid   ? trade_match_id        :
        exec_internal_valid    ? exec_match_id         :
        replace_internal_valid ? replace_old_order_ref : 64'd0;

endmodule
