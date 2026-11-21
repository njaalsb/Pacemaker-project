// pacemaker_digital : digital control block, top level design
 
`timescale 1ns/1ps

module pacemaker_digital (
    input  wire CLK,    
    input  wire RST_n,  
    input  wire H,      
    output wire P       
);
    wire R, T;

    pacemaker_fsm u_fsm (
        .CLK   (CLK),
        .RST_n (RST_n),
        .H     (H),
        .T     (T),
        .P     (P),
        .R     (R)
    );

    pacemaker_timer u_timer (
        .CLK   (CLK),
        .RST_n (RST_n),
        .R     (R),
        .T     (T)
    );
endmodule
