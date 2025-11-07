// =============================================
// itch_suppression.vh
// =============================================
//
// Description: Suppression counter and decoder enable signal used when skipping
//              uninterested ITCH messages.
// Author: RZ
// Start Date: 20250505
// Version: 0.2
//
// Changelog
// =============================================
// [20250505-1] RZ: Moved suppression logic to macro form for reuse.
// [20250507-1] RZ: Cleaned up and added comments for clarity.

logic [5:0] suppress_count;
wire decoder_enabled = (suppress_count == 0);

always_ff @(posedge clk) begin
    if (rst)
        suppress_count <= 0;
    else if (suppress_count != 0)
        suppress_count <= suppress_count - 1;
end
