// fsm_next_state : next-state logic for the pacemaker FSM

`timescale 1ns/1ps

module fsm_next_state (
    input  wire A,     
    input  wire A_n,    
    input  wire B_n,    
    input  wire H,      
    input  wire T,      
    output wire DA,
    output wire DB
);
    wire H_n;
    wire a_bn, an_h, an_bn, hn_t;

    not g0 (H_n, H);

    // DB = A·B' + A'·H
    and g1 (a_bn,  A,   B_n);
    and g2 (an_h,  A_n, H);
    or  g3 (DB,    a_bn, an_h);

    // DA = (A'·B')·(H'·T)
    and g4 (an_bn, A_n, B_n);
    and g5 (hn_t,  H_n, T);
    and g6 (DA,    an_bn, hn_t);
endmodule
