// ============================================================
// itch_abort_on_valid_drop.vh
// ============================================================
//
// Description: Aborts decoding if `valid_in` drops mid-message or
//              if byte_index exceeds expected length. Resets decoder state
//              to recover gracefully for next stream segment.
// Author: RZ
// Start Date: 20250507
// Version: 0.7
//
// Changelog
// ============================================================
// [20250506-1] RZ: Initial mid-packet abort logic macro for all decoders.
// ============================================================


if (`is_order && (
    (valid_in == 0 && byte_index > 0 && byte_index < MSG_LENGTH) ||
    (byte_index >= MSG_LENGTH)
)) begin
    `packet_invalid <= 1;
    suppress_count  <= 0;   // Allow immediate restart
    byte_index      <= 0;
end
