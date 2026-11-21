// pacemaker_timer : 10-bit ripple counter

`timescale 1ns/1ps

module pacemaker_timer (
    input  wire CLK,    
    input  wire RST_n, 
    input  wire R,      
    output wire T      
);
    wire       R_n, CLR_n, T_n;
    wire [9:0] Q, Qn;

    not  g0 (R_n, R);
    and  g1 (CLR_n, RST_n, R_n);

    // Ripple counter
    dff_c ff0 (.D(Qn[0]), .CLK(CLK),   .CLR_n(CLR_n), .Q(Q[0]), .Qn(Qn[0]));
    dff_c ff1 (.D(Qn[1]), .CLK(Qn[0]), .CLR_n(CLR_n), .Q(Q[1]), .Qn(Qn[1]));
    dff_c ff2 (.D(Qn[2]), .CLK(Qn[1]), .CLR_n(CLR_n), .Q(Q[2]), .Qn(Qn[2]));
    dff_c ff3 (.D(Qn[3]), .CLK(Qn[2]), .CLR_n(CLR_n), .Q(Q[3]), .Qn(Qn[3]));
    dff_c ff4 (.D(Qn[4]), .CLK(Qn[3]), .CLR_n(CLR_n), .Q(Q[4]), .Qn(Qn[4]));
    dff_c ff5 (.D(Qn[5]), .CLK(Qn[4]), .CLR_n(CLR_n), .Q(Q[5]), .Qn(Qn[5]));
    dff_c ff6 (.D(Qn[6]), .CLK(Qn[5]), .CLR_n(CLR_n), .Q(Q[6]), .Qn(Qn[6]));
    dff_c ff7 (.D(Qn[7]), .CLK(Qn[6]), .CLR_n(CLR_n), .Q(Q[7]), .Qn(Qn[7]));
    dff_c ff8 (.D(Qn[8]), .CLK(Qn[7]), .CLR_n(CLR_n), .Q(Q[8]), .Qn(Qn[8]));
    dff_c ff9 (.D(Qn[9]), .CLK(Qn[8]), .CLR_n(CLR_n), .Q(Q[9]), .Qn(Qn[9]));

    nand g2 (T_n, Q[8], Q[9]);
    not  g3 (T, T_n);
endmodule
