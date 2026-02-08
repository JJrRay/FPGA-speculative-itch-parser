`timescale 1 ns / 1 ps

module Itch_axi_stream_v1_0 #
(
    parameter integer C_S00_AXI_DATA_WIDTH  = 32,
    parameter integer C_S00_AXI_ADDR_WIDTH  = 7,
    parameter integer C_S00_AXIS_TDATA_WIDTH = 32
)
(
    // AXI-Lite ports
    input wire  s00_axi_aclk,
    input wire  s00_axi_aresetn,
    input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
    input wire [2 : 0] s00_axi_awprot,
    input wire  s00_axi_awvalid,
    output wire s00_axi_awready,
    input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
    input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
    input wire  s00_axi_wvalid,
    output wire s00_axi_wready,
    output wire [1 : 0] s00_axi_bresp,
    output wire s00_axi_bvalid,
    input wire  s00_axi_bready,
    input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
    input wire [2 : 0] s00_axi_arprot,
    input wire  s00_axi_arvalid,
    output wire s00_axi_arready,
    output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
    output wire [1 : 0] s00_axi_rresp,
    output wire s00_axi_rvalid,
    input wire  s00_axi_rready,
    
    // AXI-Stream ports
    input wire  s00_axis_aclk,
    input wire  s00_axis_aresetn,
    output wire s00_axis_tready,
    input wire [C_S00_AXIS_TDATA_WIDTH-1 : 0] s00_axis_tdata,
    input wire [(C_S00_AXIS_TDATA_WIDTH/8)-1 : 0] s00_axis_tstrb,
    input wire  s00_axis_tlast,
    input wire  s00_axis_tvalid
);

    // Internal signals: AXIS to Parser
    wire [7:0]  parser_byte;
    wire        parser_valid;
    
    // Internal signals: Parser outputs
    wire        latched_valid;
    wire [3:0]  latched_type;
    wire [63:0] latched_order_ref;
    wire        latched_side;
    wire [31:0] latched_shares;
    wire [31:0] latched_price;
    wire [63:0] latched_new_order_ref;
    wire [47:0] latched_timestamp;
    wire [63:0] latched_misc_data;

    // AXI-Stream Slave (receives bytes from DMA)
    Itch_axi_stream_v1_0_S00_AXIS #(
        .C_S_AXIS_TDATA_WIDTH(C_S00_AXIS_TDATA_WIDTH)
    ) S00_AXIS_inst (
        .S_AXIS_ACLK(s00_axis_aclk),
        .S_AXIS_ARESETN(s00_axis_aresetn),
        .S_AXIS_TREADY(s00_axis_tready),
        .S_AXIS_TDATA(s00_axis_tdata),
        .S_AXIS_TSTRB(s00_axis_tstrb),
        .S_AXIS_TLAST(s00_axis_tlast),
        .S_AXIS_TVALID(s00_axis_tvalid),
        // To parser
        .parser_byte(parser_byte),
        .parser_valid(parser_valid)
    );

    // ITCH Parser
    integrated u_parser (
        .clk(s00_axis_aclk),
        .rst(~s00_axis_aresetn),
        .valid_in(parser_valid),
        .byte_in(parser_byte),
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

    // AXI-Lite Slave (reads parsed results)
    Itch_axi_stream_v1_0_S00_AXI #(
        .C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
    ) S00_AXI_inst (
        .S_AXI_ACLK(s00_axi_aclk),
        .S_AXI_ARESETN(s00_axi_aresetn),
        .S_AXI_AWADDR(s00_axi_awaddr),
        .S_AXI_AWPROT(s00_axi_awprot),
        .S_AXI_AWVALID(s00_axi_awvalid),
        .S_AXI_AWREADY(s00_axi_awready),
        .S_AXI_WDATA(s00_axi_wdata),
        .S_AXI_WSTRB(s00_axi_wstrb),
        .S_AXI_WVALID(s00_axi_wvalid),
        .S_AXI_WREADY(s00_axi_wready),
        .S_AXI_BRESP(s00_axi_bresp),
        .S_AXI_BVALID(s00_axi_bvalid),
        .S_AXI_BREADY(s00_axi_bready),
        .S_AXI_ARADDR(s00_axi_araddr),
        .S_AXI_ARPROT(s00_axi_arprot),
        .S_AXI_ARVALID(s00_axi_arvalid),
        .S_AXI_ARREADY(s00_axi_arready),
        .S_AXI_RDATA(s00_axi_rdata),
        .S_AXI_RRESP(s00_axi_rresp),
        .S_AXI_RVALID(s00_axi_rvalid),
        .S_AXI_RREADY(s00_axi_rready),
        // Parser outputs
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
