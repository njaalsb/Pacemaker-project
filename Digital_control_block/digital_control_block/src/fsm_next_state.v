//-----------------------------------------------------------------------------
// fsm_next_state : combinational next-state logic for the pacemaker FSM.
//
//   DA = A'·B'·H'·T
//   DB = A·B' + A'·H
//
// Gate for gate the same as Figure 4 in the report. The state bits are
// taken from the flip-flops' Q and Q' outputs, so only H needs an inverter.
//-----------------------------------------------------------------------------
`timescale 1ns/1ps

module fsm_next_state (
    input  wire A,     // state MSB      (Q  of flip-flop A)
    input  wire A_n,   // inverted MSB   (Q' of flip-flop A)
    input  wire B_n,   // inverted LSB   (Q' of flip-flop B)
    input  wire H,     // heartbeat sensed
    input  wire T,     // timer exceeded 1.5 s
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
