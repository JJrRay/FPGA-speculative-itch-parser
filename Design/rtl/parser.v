// ============================================================
// parser.v  (Updated for 9 message types)
// ============================================================
//
// Supports:
//   1. Add
//   2. Cancel
//   3. Delete
//   4. Replace
//   5. Executed
//   6. Trade
//   7. Add Order MPID          (NEW)
//   8. Broken Trade            (NEW)
//   9. Executed Price          (NEW)
//
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

    // ============================================================
    // Internal valid signals (9 types)
    // ============================================================
    logic add_internal_valid;
    logic cancel_internal_valid;
    logic delete_internal_valid;
    logic replace_internal_valid;
    logic exec_internal_valid;
    logic trade_internal_valid;

    logic add_mpid_internal_valid;   // NEW
    logic broken_internal_valid;     // NEW
    logic exec_price_internal_valid; // NEW


    // ============================================================
    // Decoded outputs for existing types
    // ============================================================
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

    // ============================================================
    // NEW message type output wires
    // ============================================================

    // Add Order MPID
    logic [3:0]  add_mpid_parsed_type;
    logic [63:0] add_mpid_order_ref;
    logic        add_mpid_side;
    logic [31:0] add_mpid_shares;
    logic [31:0] add_mpid_price;
    logic [63:0] add_mpid_stock_symbol;
    logic [31:0] add_mpid_attribution;

    // Broken Trade
    logic [3:0]  broken_parsed_type;
    logic [47:0] broken_timestamp;
    logic [63:0] broken_match_id;

    // Executed Price
    logic [3:0]  exec_price_parsed_type;
    logic [47:0] exec_price_timestamp;
    logic [63:0] exec_price_order_ref;
    logic [31:0] exec_price_shares;
    logic [63:0] exec_price_match_id;
    logic        exec_price_printable;
    logic [31:0] exec_price_price;


    // ============================================================
    // Instantiate all 9 decoders
    // ============================================================

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

    add_order_mpid_decoder add_mpid_dec (     // NEW
        .clk(clk), .rst(rst),
        .byte_in(byte_in), .valid_in(valid_in),
        .add_mpid_internal_valid(add_mpid_internal_valid),
        .add_mpid_parsed_type(add_mpid_parsed_type),
        .add_mpid_order_ref(add_mpid_order_ref),
        .add_mpid_side(add_mpid_side),
        .add_mpid_shares(add_mpid_shares),
        .add_mpid_price(add_mpid_price),
        .add_mpid_stock_symbol(add_mpid_stock_symbol),
        .add_mpid_attribution(add_mpid_attribution)
    );

    broken_trade_decoder broken_dec (         // NEW
        .clk(clk), .rst(rst),
        .byte_in(byte_in), .valid_in(valid_in),
        .broken_internal_valid(broken_internal_valid),
        .broken_parsed_type(broken_parsed_type),
        .broken_timestamp(broken_timestamp),
        .broken_match_id(broken_match_id)
    );

    executed_price_decoder exec_price_dec (    // NEW
        .clk(clk), .rst(rst),
        .byte_in(byte_in), .valid_in(valid_in),
        .exec_price_internal_valid(exec_price_internal_valid),
        .exec_price_parsed_type(exec_price_parsed_type),
        .exec_price_timestamp(exec_price_timestamp),
        .exec_price_order_ref(exec_price_order_ref),
        .exec_price_shares(exec_price_shares),
        .exec_price_match_id(exec_price_match_id),
        .exec_price_printable(exec_price_printable),
        .exec_price_price(exec_price_price)
    );


    // ============================================================
    // One-hot valid check (9 bits now)
    // ============================================================

    wire [8:0] valid_vec = {
        add_mpid_internal_valid,
        broken_internal_valid,
        exec_price_internal_valid,
        trade_internal_valid,
        exec_internal_valid,
        replace_internal_valid,
        delete_internal_valid,
        cancel_internal_valid,
        add_internal_valid
    };

    wire parsed_any = |valid_vec;
    wire parsed_onehot = $onehot(valid_vec);

    assign parsed_valid = parsed_any && parsed_onehot;


    // ============================================================
    // Parsed TYPE selection (9-way)
    // ============================================================

    assign parsed_type =
        add_internal_valid         ? add_parsed_type :
        cancel_internal_valid      ? cancel_parsed_type :
        delete_internal_valid      ? delete_parsed_type :
        replace_internal_valid     ? replace_parsed_type :
        exec_internal_valid        ? exec_parsed_type :
        trade_internal_valid       ? trade_parsed_type :
        add_mpid_internal_valid    ? add_mpid_parsed_type :
        broken_internal_valid      ? broken_parsed_type :
        exec_price_internal_valid  ? exec_price_parsed_type :
                                     4'd0;


    // ============================================================
    // order_ref (9-way)
    // ============================================================

    assign order_ref =
        add_internal_valid        ? add_order_ref :
        cancel_internal_valid     ? cancel_order_ref :
        delete_internal_valid     ? delete_order_ref :
        replace_internal_valid    ? replace_old_order_ref :
        exec_internal_valid       ? exec_order_ref :
        trade_internal_valid      ? trade_order_ref :
        add_mpid_internal_valid   ? add_mpid_order_ref :
        exec_price_internal_valid ? exec_price_order_ref :
                                    64'd0;


    // ============================================================
    // side (3 types: add, trade, add_mpid)
    // ============================================================

    assign side =
        add_internal_valid        ? add_side :
        trade_internal_valid      ? trade_side :
        add_mpid_internal_valid   ? add_mpid_side :
                                    1'b0;


    // ============================================================
    // shares (9-way)
    // ============================================================

    assign shares =
        add_internal_valid        ? add_shares :
        cancel_internal_valid     ? cancel_canceled_shares :
        replace_internal_valid    ? replace_shares :
        exec_internal_valid       ? exec_shares :
        trade_internal_valid      ? trade_shares :
        add_mpid_internal_valid   ? add_mpid_shares :
        exec_price_internal_valid ? exec_price_shares :
                                    32'd0;


    // ============================================================
    // price (5 types)
    // ============================================================

    assign price =
        add_internal_valid        ? add_price :
        replace_internal_valid    ? replace_price :
        trade_internal_valid      ? trade_price :
        add_mpid_internal_valid   ? add_mpid_price :
        exec_price_internal_valid ? exec_price_price :
                                    32'd0;


    // ============================================================
    // new_order_ref (only replace)
    // ============================================================

    assign new_order_ref =
        replace_internal_valid ? replace_new_order_ref : 64'd0;


    // ============================================================
    // timestamp (4 types)
    // ============================================================

    assign timestamp =
        exec_internal_valid        ? exec_timestamp :
        trade_internal_valid       ? trade_timestamp :
        broken_internal_valid      ? broken_timestamp :
        exec_price_internal_valid  ? exec_price_timestamp :
                                     48'd0;


    // ============================================================
    // misc_data (stock_symbol, match_id, attribution)
    // ============================================================

    assign misc_data =
        add_internal_valid        ? add_stock_symbol :
        exec_internal_valid       ? exec_match_id :
        trade_internal_valid      ? trade_match_id :
        add_mpid_internal_valid   ? add_mpid_stock_symbol :
        broken_internal_valid     ? broken_match_id :
        exec_price_internal_valid ? exec_price_match_id :
                                    64'd0;

endmodule
