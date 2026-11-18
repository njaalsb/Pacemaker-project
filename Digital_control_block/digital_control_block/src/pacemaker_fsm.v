//-----------------------------------------------------------------------------
// pacemaker_fsm : Moore FSM controlling pacing.
//
//   State  	A B   P R
//   IDLE   	0 0   0 0   H=1 -> RESTART,  H=0,T=1 -> PACE,  else stay
//   RESTART	0 1   0 1   H=1 -> stay,     H=0     -> IDLE   (T ignored)
//   PACE   	1 0   1 0   always -> RESTART (pace counts as a heartbeat)
//   unused 	1 1   0 0   always -> IDLE
//
// Outputs are the state bits directly: P = A, R = B.
// RST_n is asynchronous, active low, and forces IDLE (00).
// H and T must be synchronous to CLK (synchronize H in the top level).
//-----------------------------------------------------------------------------
`timescale 1ns/1ps

module pacemaker_fsm (
    input  wire CLK,    // 512 Hz clock
    input  wire RST_n,  // asynchronous reset, active low
    input  wire H,      // heartbeat sensed
    input  wire T,      // timer exceeded 1.5 s
    output wire P,      // pace the heart  (= state bit A)
    output wire R       // restart timer   (= state bit B)
);
    supply1 VDD;        // logic 1 for the unused preset inputs

    wire A_n, B_n;
    wire DA, DB;

    // Next-state logic (P is state bit A)
    fsm_next_state u_logic (
        .A   (P),
        .A_n (A_n),
        .B_n (B_n),
        .H   (H),
        .T   (T),
        .DA  (DA),
        .DB  (DB)
    );

    // State register
    dff_pc u_ffA (.D(DA), .CLK(CLK), .PRE_n(VDD), .CLR_n(RST_n), .Q(P), .Qn(A_n));
    dff_pc u_ffB (.D(DB), .CLK(CLK), .PRE_n(VDD), .CLR_n(RST_n), .Q(R), .Qn(B_n));
endmodule
