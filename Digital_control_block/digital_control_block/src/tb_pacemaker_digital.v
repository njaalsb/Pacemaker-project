 // tb_pacemaker_digital : waveform testbench, cycle throug different heartrates
`timescale 1ns/1ps

module tb_pacemaker_digital;

    localparam real HALF_PERIOD = 976562.5;    
    localparam integer H_WIDTH  = 15;          

    reg  CLK   = 1'b0;
    reg  RST_n = 1'b0;
    reg  H     = 1'b0;
    wire P;

     
    wire       R     = dut.R;
    wire       T     = dut.T;
    wire [9:0] count = dut.u_timer.Q;

    reg [8*16-1:0] phase = "reset";           
    integer cycle = 0;

    always #(HALF_PERIOD) CLK = ~CLK;
    always @(posedge CLK) cycle = cycle + 1;

    pacemaker_digital dut (
        .CLK   (CLK),
        .RST_n (RST_n),
        .H     (H),
        .P     (P)
    );

     
    always @(posedge P)
        $display("  PACE at t = %8.3f s  (%0s)", $realtime / 1.0e9, phase);

     
    task heartbeat;
        input integer interval;    
        integer k;
        begin
            for (k = 0; k < interval; k = k + 1) begin
                @(negedge CLK);
                H = (k < H_WIDTH);
            end
        end
    endtask

    task no_heartbeat;
        input integer cycles;
        begin
            @(negedge CLK);
            H = 1'b0;
            repeat (cycles - 1) @(negedge CLK);
        end
    endtask

    initial begin
        $display("==== Pacemaker digital block ====");

        repeat (2) @(negedge CLK);
        RST_n = 1'b1;

        phase = "60 bpm";
        $display("%0s (1.0 s between beats)", phase);
        repeat (5) heartbeat(512);

        phase = "43 bpm";
        $display("%0s (1.4 s between beats)", phase);
        repeat (3) heartbeat(717);

        phase = "30 bpm";
        $display("%0s (2.0 s between beats)", phase);
        repeat (3) heartbeat(1024);

        phase = "heart stopped";
        $display("%0s (6 s)", phase);
        no_heartbeat(3072);

        phase = "recovered";
        $display("%0s, 60 bpm", phase);
        repeat (4) heartbeat(512);

        $display("==== done at t = %.3f s ====", $realtime / 1.0e9);
        $finish;
    end

endmodule
