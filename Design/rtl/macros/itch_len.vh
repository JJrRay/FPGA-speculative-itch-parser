// =============================================
// itch_len.vh
// =============================================
//
// Description: Function to return ITCH message length based on message type.
//              Used by speculative decoders for suppression and recheck logic.
// Author: RZ
// Start Date: 20250505
// Version: 0.1
//
// Changelog
// =============================================
// [20250505-1] RZ: Initial standalone macro for message length lookup.

function automatic logic [5:0] itch_length(input logic [7:0] msg_type);
    case (msg_type)
        "A": return 36;  // Add Order
        "X": return 23;  // Cancel Order
        "U": return 27;  // Replace Order
        "D": return 9;   // Delete Order
        "E": return 30;  // Executed Order
        "P": return 40;  // Trade
        default: return 2; // Catch-all / suppression fallback
    endcase
endfunction
