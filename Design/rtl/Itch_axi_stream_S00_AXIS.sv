
`timescale 1 ns / 1 ps

`timescale 1 ns / 1 ps

module Itch_axi_stream_v1_0_S00_AXIS #
(
    parameter integer C_S_AXIS_TDATA_WIDTH = 32
)
(
    input wire  S_AXIS_ACLK,
    input wire  S_AXIS_ARESETN,
    output wire S_AXIS_TREADY,
    input wire [C_S_AXIS_TDATA_WIDTH-1 : 0] S_AXIS_TDATA,
    input wire [(C_S_AXIS_TDATA_WIDTH/8)-1 : 0] S_AXIS_TSTRB,
    input wire  S_AXIS_TLAST,
    input wire  S_AXIS_TVALID,
    
    // Output to parser
    output wire [7:0]  parser_byte,
    output wire        parser_valid
);

    // Simple pass-through - always ready when not in reset
    assign S_AXIS_TREADY = S_AXIS_ARESETN;
    
    // Pass data directly to parser
    assign parser_byte = S_AXIS_TDATA[7:0];
    assign parser_valid = S_AXIS_TVALID && S_AXIS_TREADY;

endmodule
