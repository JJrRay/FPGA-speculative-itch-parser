// =============================================
// itch_reset.vh
// =============================================
//
// Description: Shared reset logic macro delegating to decoder-specific signal
//              assignments via ITCH_RESET_FIELDS.
// Author: RZ
// Start Date: 20250505
// Version: 0.1
//
// Changelog
// =============================================
// [20250505-1] RZ: Created decoder-agnostic reset wrapper.

`define ITCH_RESET_LOGIC \
    `ITCH_RESET_FIELDS
