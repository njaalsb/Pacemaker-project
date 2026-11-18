//-----------------------------------------------------------------------------
// dff_pc : positive-edge triggered D flip-flop with asynchronous,
//          active-low preset (PRE_n) and clear (CLR_n).
//
// Gate level: six 3-input NAND gates (classic 7474 structure).
//   - PRE_n = 0 forces Q = 1, CLR_n = 0 forces Q = 0 (do not assert both).
//   - Tie unused PRE_n / CLR_n to logic 1.
// Each gate has a 1 ns delay so the feedback loops simulate cleanly.
// (Negligible compared to the 1.95 ms clock period at 512 Hz.)
//-----------------------------------------------------------------------------
`timescale 1ns/1ps

module dff_pc (
    input  wire D,
    input  wire CLK,
    input  wire PRE_n,
    input  wire CLR_n,
    output wire Q,
    output wire Qn
);
    wire x1, s_n, r_n, x4;

    // Input stage: captures D on the rising clock edge
    nand #1 g1 (x1,  PRE_n, x4,    s_n);
    nand #1 g2 (s_n, x1,    CLR_n, CLK);
    nand #1 g3 (r_n, s_n,   CLK,   x4);
    nand #1 g4 (x4,  r_n,   CLR_n, D);

    // Output SR latch
    nand #1 g5 (Q,   PRE_n, s_n,   Qn);
    nand #1 g6 (Qn,  CLR_n, r_n,   Q);
endmodule
