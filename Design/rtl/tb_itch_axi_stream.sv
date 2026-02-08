// ============================================================
// tb_itch_axi_stream.v
// ============================================================
//
// Description: System-level testbench for the ITCH Parser IP.
//              Simulates a DMA-driven AXI-Stream source to feed 
//              raw ITCH message bytes and an AXI-Lite master to 
//              verify decoded output registers.
//
// Author: JR
// Start Date: 20251009
// Version: 0.1
//
// Changelog
// ============================================================
// [20250507-1] JR: Created testbench with tasks for AXIS streaming 
//                  and AXI-Lite read transactions. Verified 
//                  Delete Order ('D') message parsing.
// ============================================================

module tb_itch_axi_stream;

    // Parameters
    parameter C_S00_AXI_DATA_WIDTH = 32;
    parameter C_S00_AXI_ADDR_WIDTH = 7;
    parameter C_S00_AXIS_TDATA_WIDTH = 32;
    
    // Clock and reset
    reg clk;
    reg resetn;
    
    // AXI-Stream signals (to send bytes)
    reg [C_S00_AXIS_TDATA_WIDTH-1:0] axis_tdata;
    reg axis_tvalid;
    wire axis_tready;
    reg axis_tlast;
    reg [(C_S00_AXIS_TDATA_WIDTH/8)-1:0] axis_tstrb;
    
    // AXI-Lite signals (to read results)
    reg  [C_S00_AXI_ADDR_WIDTH-1:0] araddr;
    reg  [2:0] arprot;
    reg  arvalid;
    wire arready;
    wire [C_S00_AXI_DATA_WIDTH-1:0] rdata;
    wire [1:0] rresp;
    wire rvalid;
    reg  rready;
    
    // Write channels (active but unused)
    reg  [C_S00_AXI_ADDR_WIDTH-1:0] awaddr;
    reg  [2:0] awprot;
    reg  awvalid;
    wire awready;
    reg  [C_S00_AXI_DATA_WIDTH-1:0] wdata;
    reg  [3:0] wstrb;
    reg  wvalid;
    wire wready;
    wire [1:0] bresp;
    wire bvalid;
    reg  bready;
    
    // DUT
    Itch_axi_stream_v1_0 #(
        .C_S00_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
        .C_S00_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH),
        .C_S00_AXIS_TDATA_WIDTH(C_S00_AXIS_TDATA_WIDTH)
    ) dut (
        // AXI-Lite
        .s00_axi_aclk(clk),
        .s00_axi_aresetn(resetn),
        .s00_axi_awaddr(awaddr),
        .s00_axi_awprot(awprot),
        .s00_axi_awvalid(awvalid),
        .s00_axi_awready(awready),
        .s00_axi_wdata(wdata),
        .s00_axi_wstrb(wstrb),
        .s00_axi_wvalid(wvalid),
        .s00_axi_wready(wready),
        .s00_axi_bresp(bresp),
        .s00_axi_bvalid(bvalid),
        .s00_axi_bready(bready),
        .s00_axi_araddr(araddr),
        .s00_axi_arprot(arprot),
        .s00_axi_arvalid(arvalid),
        .s00_axi_arready(arready),
        .s00_axi_rdata(rdata),
        .s00_axi_rresp(rresp),
        .s00_axi_rvalid(rvalid),
        .s00_axi_rready(rready),
        
        // AXI-Stream
        .s00_axis_aclk(clk),
        .s00_axis_aresetn(resetn),
        .s00_axis_tready(axis_tready),
        .s00_axis_tdata(axis_tdata),
        .s00_axis_tstrb(axis_tstrb),
        .s00_axis_tlast(axis_tlast),
        .s00_axis_tvalid(axis_tvalid)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Send one byte via AXI-Stream (one clock cycle!)
    task axis_send_byte(input [7:0] b, input last);
        begin
            @(posedge clk);
            axis_tdata <= {24'd0, b};
            axis_tvalid <= 1;
            axis_tlast <= last;
            
            // Wait for ready (should be immediate)
            while (!axis_tready) @(posedge clk);
            @(posedge clk);
            
            axis_tvalid <= 0;
            axis_tlast <= 0;
        end
    endtask
    
    // Send bytes back-to-back (continuous stream)
    task axis_send_stream(input [7:0] data[], input integer len);
        integer i;
        begin
            for (i = 0; i < len; i = i + 1) begin
                @(posedge clk);
                axis_tdata <= {24'd0, data[i]};
                axis_tvalid <= 1;
                axis_tlast <= (i == len - 1);
            end
            @(posedge clk);
            axis_tvalid <= 0;
            axis_tlast <= 0;
        end
    endtask
    
    // AXI-Lite Read Task
    task axi_read(input [C_S00_AXI_ADDR_WIDTH-1:0] addr, output [31:0] data);
        begin
            @(posedge clk);
            araddr = addr;
            arprot = 3'b000;
            arvalid = 1;
            
            while (!arready) @(posedge clk);
            @(posedge clk);
            arvalid = 0;
            
            while (!rvalid) @(posedge clk);
            data = rdata;
            @(posedge clk);
        end
    endtask
    
    reg [31:0] read_data;
    
    // Test sequence
    initial begin
        // Initialize
        resetn = 0;
        axis_tdata = 0;
        axis_tvalid = 0;
        axis_tlast = 0;
        axis_tstrb = 4'hF;
        
        awaddr = 0; awprot = 0; awvalid = 0;
        wdata = 0; wstrb = 4'hF; wvalid = 0;
        bready = 1;
        araddr = 0; arprot = 0; arvalid = 0;
        rready = 1;
        
        // Reset
        #100;
        resetn = 1;
        #20;
        
        $display("===========================================");
        $display("Sending Delete Order via AXI-Stream");
        $display("===========================================");
        
        // Send Delete Order: 'D' + 8-byte order_ref
        // Back-to-back, one byte per clock cycle!
        @(posedge clk);
        axis_tvalid <= 1;
        
        axis_tdata <= 8'h44; axis_tlast <= 0; @(posedge clk); $display("Sent: 0x44 'D'");
        axis_tdata <= 8'h01; axis_tlast <= 0; @(posedge clk); $display("Sent: 0x01");
        axis_tdata <= 8'h02; axis_tlast <= 0; @(posedge clk); $display("Sent: 0x02");
        axis_tdata <= 8'h03; axis_tlast <= 0; @(posedge clk); $display("Sent: 0x03");
        axis_tdata <= 8'h04; axis_tlast <= 0; @(posedge clk); $display("Sent: 0x04");
        axis_tdata <= 8'h05; axis_tlast <= 0; @(posedge clk); $display("Sent: 0x05");
        axis_tdata <= 8'h06; axis_tlast <= 0; @(posedge clk); $display("Sent: 0x06");
        axis_tdata <= 8'h07; axis_tlast <= 0; @(posedge clk); $display("Sent: 0x07");
        axis_tdata <= 8'h08; axis_tlast <= 1; @(posedge clk); $display("Sent: 0x08 (LAST)");
        
        axis_tvalid <= 0;
        axis_tlast <= 0;
        
        // Wait for parser to latch
        #50;
        
        $display("");
        $display("=== Reading Results via AXI-Lite ===");
        
        axi_read(7'h08, read_data);  // LATCHED_VALID
        $display("LATCHED_VALID: %d (expect 1)", read_data[0]);
        
        axi_read(7'h0C, read_data);  // LATCHED_TYPE
        $display("LATCHED_TYPE:  %d (expect 2 for DELETE)", read_data[3:0]);
        
        axi_read(7'h10, read_data);  // ORDER_REF_LO
        $display("ORDER_REF_LO:  0x%08X (expect 0x05060708)", read_data);
        
        axi_read(7'h14, read_data);  // ORDER_REF_HI
        $display("ORDER_REF_HI:  0x%08X (expect 0x01020304)", read_data);
        
        #50;
        
        if (read_data == 32'h01020304)
            $display("\n*** TEST PASSED ***");
        else
            $display("\n*** TEST FAILED ***");
        
        $finish;
    end

endmodule