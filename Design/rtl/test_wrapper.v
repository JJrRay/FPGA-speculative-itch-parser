// ============================================================
// test_wrapper.v
// ============================================================
//
// Description: RTL-level test wrapper for parser and latch stage.
//              Drives `byte_in` + `valid_in`, captures and forwards latched output signals.
//              Sends Delete Order.
//              Intended for waveform inspection and integration verification.
//
// Author: JR
// Start Date: 20251010
// Version: 0.1
//
// Changelog
// ============================================================
// [20251010-1] JR: Created test wrapper highly inspired from original file written by the author
// ============================================================


module test_wrapper;

    // Inputs
    logic        clk;
    logic        rst;
    logic        valid_in;
    logic [7:0]  byte_in;

    // Latched output signals (from integrated)
    logic        latched_valid;
    logic [3:0]  latched_type;
    logic [63:0] latched_order_ref;
    logic        latched_side;
    logic [31:0] latched_shares;
    logic [31:0] latched_price;
    logic [63:0] latched_new_order_ref;
    logic [47:0] latched_timestamp;
    logic [63:0] latched_misc_data;

    // ============================================================
    // DUT: integrated ITCH parser + latch stage
    // ============================================================

    integrated dut (
        .clk(clk),
        .rst(rst),
        .byte_in(byte_in),
        .valid_in(valid_in),

        // Latched outputs (these are what we inspect)
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

    // ============================================================
    // Clock generation (100 MHz)
    // ============================================================
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // ============================================================
    // Test stimulus: simple DELETE order ("D")
    // ============================================================
    initial begin
        rst = 1;
        valid_in = 0;
        byte_in = 0;

        #100;
        rst = 0;

        #20;

        // DELETE ORDER MESSAGE:
        // Msg Type: 'D' (0x44)
        // Order Ref: 01 02 03 04 05 06 07 08

        valid_in = 1;

        byte_in = 8'h44; #10;   // 'D'
        byte_in = 8'h01; #10;
        byte_in = 8'h02; #10;
        byte_in = 8'h03; #10;
        byte_in = 8'h04; #10;
        byte_in = 8'h05; #10;
        byte_in = 8'h06; #10;
        byte_in = 8'h07; #10;
        byte_in = 8'h08; #10;

        valid_in = 0;
        byte_in = 0;

        #200;

        $finish;
    end

    // ============================================================
    // Waveform dump
    // ============================================================
    `ifdef COCOTB_SIM
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, test_wrapper);
    end
    `endif

endmodule
