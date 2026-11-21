// pacemaker_fsm : Moore FSM controlling pacing.

`timescale 1ns/1ps

module pacemaker_fsm (
    input  wire CLK,    
    input  wire RST_n,  
    input  wire H,      
    input  wire T,      
    output wire P,     
    output wire R       
);
    wire A_n, B_n;
    wire DA, DB;

    // Instantiating fsm_next_state
    fsm_next_state u_logic (
        .A   (P),
        .A_n (A_n),
        .B_n (B_n),
        .H   (H),
        .T   (T),
        .DA  (DA),
        .DB  (DB)
    );

    // register
    dff_c  u_ffA (.D(DA), .CLK(CLK), .CLR_n(RST_n), .Q(P), .Qn(A_n));
    dff_c  u_ffB (.D(DB), .CLK(CLK), .CLR_n(RST_n), .Q(R), .Qn(B_n));
endmodule

