//-----------------------------------------------------------------------------
// tb_pacemaker_fsm : self-checking testbench for pacemaker_fsm.
// (Behavioural code is allowed in testbenches.)
//
// Part 1: Exhaustive test of the next-state logic (all 16 rows of Table 1).
// Part 2: Directed scenarios on the full FSM, compared cycle by cycle
//         against a behavioural reference model.
// Part 3: Random H/T stimulus for 2000 cycles against the reference model.
// Part 4: System sanity run with a behavioural 10-bit timer model:
//         heart at 60 bpm (no pacing expected), then the heart stops
//         (pacing roughly every 1.5 s expected).
//
// Inputs change on the falling clock edge; outputs are checked on the
// falling edge, half a period after the FSM has clocked.
// Look for "ALL TESTS PASSED" / "TESTS FAILED" at the end of the log.
//-----------------------------------------------------------------------------
`timescale 1ns/1ps

module tb_pacemaker_fsm;

    // 512 Hz clock -> period 1 953 125 ns
    localparam real HALF_PERIOD = 976562.5;

    // State encoding (for the reference model and messages)
    localparam [1:0] IDLE = 2'b00, RESTART = 2'b01, PACE = 2'b10, UNUSED = 2'b11;

    reg  CLK   = 1'b0;
    reg  RST_n = 1'b0;
    reg  H     = 1'b0;
    reg  T_drv = 1'b0;
    reg  use_timer = 1'b0;     // 0: T driven by testbench, 1: T from timer model
    wire T;
    wire P, R;

    integer errors = 0;
    integer cycle  = 0;

    always #(HALF_PERIOD) CLK = ~CLK;
    always @(posedge CLK) cycle = cycle + 1;

    //-------------------------------------------------------------------------
    // Device under test
    //-------------------------------------------------------------------------
    pacemaker_fsm dut (
        .CLK   (CLK),
        .RST_n (RST_n),
        .H     (H),
        .T     (T),
        .P     (P),
        .R     (R)
    );

    //-------------------------------------------------------------------------
    // Behavioural timer model (stand-in for the real timer in Part 4)
    // Counts at 512 Hz, cleared while R = 1, T = Q9·Q8 (count >= 768).
    //-------------------------------------------------------------------------
    // The #5 models clock-to-Q delay of a real counter. Without it, T would
    // change at the exact clock edge and violate the hold time of the
    // gate-level flip-flops in the DUT (it would pace one cycle early).
    reg  [9:0] cnt;
    always @(posedge CLK or negedge RST_n)
        if (!RST_n)            cnt <= 10'd0;
        else if (R)            cnt <= #5 10'd0;
        else if (cnt != 10'h3FF) cnt <= #5 cnt + 10'd1;

    wire T_timer = cnt[9] & cnt[8];
    assign T = use_timer ? T_timer : T_drv;

    //-------------------------------------------------------------------------
    // Reference model of the state diagram
    //-------------------------------------------------------------------------
    reg [1:0] ref_state;
    always @(posedge CLK or negedge RST_n)
        if (!RST_n) ref_state <= IDLE;
        else case (ref_state)
            IDLE:    ref_state <= H ? RESTART : (T ? PACE : IDLE);
            RESTART: ref_state <= H ? RESTART : IDLE;
            PACE:    ref_state <= RESTART;
            default: ref_state <= IDLE;
        endcase

    wire ref_P = (ref_state == PACE);
    wire ref_R = (ref_state == RESTART);

    function [8*7-1:0] name;
        input [1:0] s;
        case (s)
            IDLE:    name = "IDLE";
            RESTART: name = "RESTART";
            PACE:    name = "PACE";
            default: name = "UNUSED";
        endcase
    endfunction

    task check_outputs;
        begin
            if (P !== ref_P || R !== ref_R) begin
                errors = errors + 1;
                $display("ERROR  t=%0t cycle=%0d: expected %0s (P=%b R=%b), got P=%b R=%b  (H=%b T=%b)",
                         $time, cycle, name(ref_state), ref_P, ref_R, P, R, H, T);
            end
        end
    endtask

    // Wait for the falling edge, check outputs, then apply new inputs
    task step;
        input h, t;
        begin
            @(negedge CLK);
            check_outputs;
            H     = h;
            T_drv = t;
        end
    endtask

    // Apply inputs on a falling edge, let the FSM clock once, then check
    // the new state on the next falling edge. Call only on a falling edge.
    task apply;
        input h, t;
        input [1:0] s;
        input [8*40-1:0] msg;
        begin
            H     = h;
            T_drv = t;
            @(negedge CLK);
            check_outputs;
            if ({P, R} !== {s == PACE, s == RESTART}) begin
                errors = errors + 1;
                $display("ERROR  %0s: expected %0s, got P=%b R=%b", msg, name(s), P, R);
            end else
                $display("  ok   %0s -> %0s", msg, name(s));
        end
    endtask

    //-------------------------------------------------------------------------
    // Part 1: exhaustive next-state logic test
    //-------------------------------------------------------------------------
    reg  la, lb, lh, lt;
    wire lDA, lDB;
    fsm_next_state u_logic_test (
        .A(la), .A_n(~la), .B_n(~lb), .H(lh), .T(lt), .DA(lDA), .DB(lDB)
    );

    task test_logic;
        integer i;
        reg exp_A, exp_B;
        begin
            $display("\n--- Part 1: next-state logic, all 16 rows ---");
            $display("  A B H T | DA DB | expected");
            for (i = 0; i < 16; i = i + 1) begin
                {la, lb, lh, lt} = i[3:0];
                case ({la, lb})
                    IDLE:    {exp_A, exp_B} = lh ? RESTART : (lt ? PACE : IDLE);
                    RESTART: {exp_A, exp_B} = lh ? RESTART : IDLE;
                    PACE:    {exp_A, exp_B} = RESTART;
                    default: {exp_A, exp_B} = IDLE;
                endcase
                #10;
                $display("  %b %b %b %b |  %b  %b |   %b  %b %0s",
                         la, lb, lh, lt, lDA, lDB, exp_A, exp_B,
                         ({lDA, lDB} === {exp_A, exp_B}) ? "" : "<-- MISMATCH");
                if ({lDA, lDB} !== {exp_A, exp_B}) errors = errors + 1;
            end
        end
    endtask

    //-------------------------------------------------------------------------
    // Part 4 helpers
    //-------------------------------------------------------------------------
    integer pace_count = 0;
    integer last_pace  = -1;
    integer interval;
    integer min_int = 99999, max_int = 0;

    always @(negedge CLK)
        if (use_timer && P) begin
            pace_count = pace_count + 1;
            if (last_pace >= 0) begin
                interval = cycle - last_pace;
                if (interval < min_int) min_int = interval;
                if (interval > max_int) max_int = interval;
            end
            last_pace = cycle;
        end

    // One heartbeat: H high for 20 cycles (~40 ms), then low
    task heartbeat_then_wait;
        input integer total_cycles;
        integer k;
        begin
            for (k = 0; k < total_cycles; k = k + 1)
                step(k < 20, 1'b0);
        end
    endtask

    //-------------------------------------------------------------------------
    // Stimulus
    //-------------------------------------------------------------------------
    integer i, paces_before, err_before;

    initial begin
        $display("==== Pacemaker FSM testbench ====");

        test_logic;

        //---------------------------------------------------------------------
        $display("\n--- Part 2: directed scenarios ---");
        RST_n = 1'b0; H = 1'b0; T_drv = 1'b0;
        repeat (2) @(negedge CLK);
        if ({P, R} !== 2'b00) begin
            errors = errors + 1;
            $display("ERROR  reset did not give IDLE (P=%b R=%b)", P, R);
        end else
            $display("  ok   reset -> IDLE");
        RST_n = 1'b1;

        // No inputs: stay idle
        apply(0, 0, IDLE,    "idle, H=0 T=0");
        // Heartbeat
        apply(1, 0, RESTART, "idle, H=1");
        apply(1, 0, RESTART, "restart, H held 1");
        apply(0, 0, IDLE,    "restart, H=0");
        // Missed beat -> pace for exactly one cycle
        apply(0, 1, PACE,    "idle, T=1");
        // T still high (timer not cleared yet) -> must go to RESTART
        apply(0, 1, RESTART, "pace -> restart");
        // T still high in RESTART -> must NOT pace again
        apply(0, 1, IDLE,    "restart, H=0 T=1 (T ignored)");
        // H and T at the same time in IDLE -> heartbeat wins
        apply(1, 1, RESTART, "idle, H=1 T=1");
        apply(0, 0, IDLE,    "restart -> idle");
        // Paced beat sensed as H during PACE
        apply(0, 1, PACE,    "idle, T=1");
        apply(1, 0, RESTART, "pace, H=1");
        apply(0, 0, IDLE,    "restart -> idle");

        // Asynchronous reset in the middle of a clock period
        apply(1, 0, RESTART, "idle, H=1");
        #(HALF_PERIOD / 2);
        RST_n = 1'b0;
        #100;
        if ({P, R} !== 2'b00) begin
            errors = errors + 1;
            $display("ERROR  async reset mid-cycle: P=%b R=%b", P, R);
        end else
            $display("  ok   async reset mid-cycle -> IDLE immediately");
        @(negedge CLK);
        RST_n = 1'b1;
        H = 1'b0; T_drv = 1'b0;

        //---------------------------------------------------------------------
        $display("\n--- Part 3: 2000 random cycles vs reference model ---");
        err_before = errors;
        for (i = 0; i < 2000; i = i + 1)
            step($random, $random);
        $display("  %0s", (errors == err_before) ? "ok   no mismatches" : "mismatches found");

        //---------------------------------------------------------------------
        $display("\n--- Part 4: with timer model ---");
        @(negedge CLK);
        RST_n = 1'b0; H = 1'b0; T_drv = 1'b0;
        @(negedge CLK);
        RST_n = 1'b1;
        use_timer = 1'b1;

        // 6 heartbeats at 60 bpm (512 cycles apart)
        repeat (6) heartbeat_then_wait(512);
        if (pace_count != 0) begin
            errors = errors + 1;
            $display("ERROR  %0d pace(s) during normal 60 bpm rhythm", pace_count);
        end else
            $display("  ok   60 bpm: no pacing");

        // Heart stops for 10 s (5120 cycles)
        for (i = 0; i < 5120; i = i + 1)
            step(1'b0, 1'b0);
        $display("  heart stopped 10 s: %0d paces, interval %0d..%0d cycles (%.3f..%.3f s)",
                 pace_count, min_int, max_int, min_int / 512.0, max_int / 512.0);
        if (pace_count < 6 || pace_count > 7 || min_int < 768 || max_int > 775) begin
            errors = errors + 1;
            $display("ERROR  pacing rate outside expected range (~1.5 s)");
        end else
            $display("  ok   paces about every 1.5 s");

        // Heart recovers: pacing should stop
        paces_before = pace_count;
        repeat (4) heartbeat_then_wait(512);
        if (pace_count != paces_before) begin
            errors = errors + 1;
            $display("ERROR  pacing continued after heart recovered");
        end else
            $display("  ok   heart recovered: pacing stopped");

        //---------------------------------------------------------------------
        $display("\n================================");
        if (errors == 0) $display("ALL TESTS PASSED");
        else             $display("TESTS FAILED: %0d error(s)", errors);
        $display("================================");
        $finish;
    end

endmodule
