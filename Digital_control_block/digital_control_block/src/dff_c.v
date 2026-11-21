// dff_c : D flip-flop with asynchronous clear
     
																		   
`timescale 1ns/1ps

module dff_c (
    input  wire D,
    input  wire CLK,
    input  wire CLR_n,
    output wire Q,
    output wire Qn
);
    wire x1, s_n, r_n, x4;

    // Input stage: captures D on the rising clock edge
    nand #1 g1 (x1,  x4,  s_n);
    nand #1 g2 (s_n, x1,  CLR_n, CLK);
    nand #1 g3 (r_n, s_n, CLK,   x4);
    nand #1 g4 (x4,  r_n, CLR_n, D);

    // Output SR latch
    nand #1 g5 (Q,   s_n,   Qn);
    nand #1 g6 (Qn,  CLR_n, r_n, Q);
endmodule
