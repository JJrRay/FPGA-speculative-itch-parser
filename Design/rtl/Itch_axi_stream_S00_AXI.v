`timescale 1 ns / 1 ps

module Itch_axi_stream_v1_0_S00_AXI #
(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 7
)
(
    input wire  S_AXI_ACLK,
    input wire  S_AXI_ARESETN,
    
    // Write channels (active but unused for data)
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
    input wire [2 : 0] S_AXI_AWPROT,
    input wire  S_AXI_AWVALID,
    output wire S_AXI_AWREADY,
    input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
    input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
    input wire  S_AXI_WVALID,
    output wire S_AXI_WREADY,
    output wire [1 : 0] S_AXI_BRESP,
    output wire S_AXI_BVALID,
    input wire  S_AXI_BREADY,
    
    // Read channels
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
    input wire [2 : 0] S_AXI_ARPROT,
    input wire  S_AXI_ARVALID,
    output wire S_AXI_ARREADY,
    output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
    output wire [1 : 0] S_AXI_RRESP,
    output wire S_AXI_RVALID,
    input wire  S_AXI_RREADY,
    
    // Parser outputs (directly connected)
    input wire        latched_valid,
    input wire [3:0]  latched_type,
    input wire [63:0] latched_order_ref,
    input wire        latched_side,
    input wire [31:0] latched_shares,
    input wire [31:0] latched_price,
    input wire [63:0] latched_new_order_ref,
    input wire [47:0] latched_timestamp,
    input wire [63:0] latched_misc_data
);

    localparam integer ADDR_LSB = 2;
    localparam integer OPT_MEM_ADDR_BITS = 4;

    reg [C_S_AXI_ADDR_WIDTH-1 : 0] axi_awaddr;
    reg  axi_awready;
    reg  axi_wready;
    reg [1 : 0] axi_bresp;
    reg  axi_bvalid;
    reg [C_S_AXI_ADDR_WIDTH-1 : 0] axi_araddr;
    reg  axi_arready;
    reg [C_S_AXI_DATA_WIDTH-1 : 0] axi_rdata;
    reg [1 : 0] axi_rresp;
    reg  axi_rvalid;
    
    wire slv_reg_rden;
    reg [C_S_AXI_DATA_WIDTH-1:0] reg_data_out;
    reg aw_en;

    assign S_AXI_AWREADY = axi_awready;
    assign S_AXI_WREADY  = axi_wready;
    assign S_AXI_BRESP   = axi_bresp;
    assign S_AXI_BVALID  = axi_bvalid;
    assign S_AXI_ARREADY = axi_arready;
    assign S_AXI_RDATA   = axi_rdata;
    assign S_AXI_RRESP   = axi_rresp;
    assign S_AXI_RVALID  = axi_rvalid;

    // Write address ready
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_awready <= 1'b0;
            aw_en <= 1'b1;
        end else begin
            if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en) begin
                axi_awready <= 1'b1;
                aw_en <= 1'b0;
            end else if (S_AXI_BREADY && axi_bvalid) begin
                aw_en <= 1'b1;
                axi_awready <= 1'b0;
            end else begin
                axi_awready <= 1'b0;
            end
        end
    end

    // Write data ready
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_wready <= 1'b0;
        end else begin
            if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en)
                axi_wready <= 1'b1;
            else
                axi_wready <= 1'b0;
        end
    end

    // Write response
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_bvalid <= 0;
            axi_bresp <= 2'b0;
        end else begin
            if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID) begin
                axi_bvalid <= 1'b1;
                axi_bresp <= 2'b0;
            end else if (S_AXI_BREADY && axi_bvalid) begin
                axi_bvalid <= 1'b0;
            end
        end
    end

    // Read address ready
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_arready <= 1'b0;
            axi_araddr <= 0;
        end else begin
            if (~axi_arready && S_AXI_ARVALID) begin
                axi_arready <= 1'b1;
                axi_araddr <= S_AXI_ARADDR;
            end else begin
                axi_arready <= 1'b0;
            end
        end
    end

    // Read valid
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_rvalid <= 0;
            axi_rresp <= 0;
        end else begin
            if (axi_arready && S_AXI_ARVALID && ~axi_rvalid) begin
                axi_rvalid <= 1'b1;
                axi_rresp <= 2'b0;
            end else if (axi_rvalid && S_AXI_RREADY) begin
                axi_rvalid <= 1'b0;
            end
        end
    end

    // Read data mux - parser outputs
    assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;
    
    always @(*) begin
        case (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB])
            5'h00: reg_data_out <= 32'd0;                                  // Reserved
            5'h01: reg_data_out <= 32'd0;                                  // Status
            5'h02: reg_data_out <= {31'd0, latched_valid};                 // LATCHED_VALID
            5'h03: reg_data_out <= {28'd0, latched_type};                  // LATCHED_TYPE
            5'h04: reg_data_out <= latched_order_ref[31:0];                // ORDER_REF_LO
            5'h05: reg_data_out <= latched_order_ref[63:32];               // ORDER_REF_HI
            5'h06: reg_data_out <= {31'd0, latched_side};                  // SIDE
            5'h07: reg_data_out <= latched_shares;                         // SHARES
            5'h08: reg_data_out <= latched_price;                          // PRICE
            5'h09: reg_data_out <= latched_new_order_ref[31:0];            // NEW_REF_LO
            5'h0A: reg_data_out <= latched_new_order_ref[63:32];           // NEW_REF_HI
            5'h0B: reg_data_out <= latched_timestamp[31:0];                // TIMESTAMP_LO
            5'h0C: reg_data_out <= {16'd0, latched_timestamp[47:32]};      // TIMESTAMP_HI
            5'h0D: reg_data_out <= latched_misc_data[31:0];                // MISC_DATA_LO
            5'h0E: reg_data_out <= latched_misc_data[63:32];               // MISC_DATA_HI
            default: reg_data_out <= 32'hDEADBEEF;
        endcase
    end

    // Read data output
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_rdata <= 0;
        end else if (slv_reg_rden) begin
            axi_rdata <= reg_data_out;
        end
    end

endmodule