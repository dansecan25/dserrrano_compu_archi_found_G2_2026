`timescale 1ns/1ps
// Unit test of the PWM test-mode controller (defaults OPEN_TAP=7, CLOSE_TAP=15).
// Counters sample what the PWM would see on each rising edge:
//   one full test = 8 edges of OPEN (VALOR=5), 8 edges of CLOSE (VALOR=1),
//   RUNNING high on 17 edges.
module tb_pwm_test_ctrl;
    logic       CLK, RST_N, ENABLE, BTN_N;
    wire        TEST_OPEN, TEST_CLOSE, RUNNING;
    wire  [2:0] VALOR;
    int   errors = 0;
    int   k, n_open, n_close, n_run;
    string verdict [2];

    pwm_test_ctrl dut (.CLK(CLK), .RST_N(RST_N), .ENABLE(ENABLE), .BTN_N(BTN_N),
                       .TEST_OPEN(TEST_OPEN), .TEST_CLOSE(TEST_CLOSE),
                       .VALOR(VALOR), .RUNNING(RUNNING));

    // clock without sampling (used while in reset)
    task automatic raw_tick;
        CLK = 1; #5; CLK = 0; #5;
    endtask

    // one clock cycle, sampling the value present at the rising edge
    task automatic tick;
        logic bad;
        bad = (TEST_OPEN  & (VALOR !== 3'd5))
            | (TEST_CLOSE & (VALOR !== 3'd1))
            | (~TEST_OPEN & ~TEST_CLOSE & (VALOR !== 3'd0))
            | (TEST_OPEN & TEST_CLOSE);
        errors  = errors  + bad;
        n_open  = n_open  + TEST_OPEN;
        n_close = n_close + TEST_CLOSE;
        n_run   = n_run   + RUNNING;
        CLK = 1; #5; CLK = 0; #5;
    endtask

    task automatic ticks(input int n);
        int i;
        for (i = 0; i < n; i = i + 1) tick;
    endtask

    task automatic clear_counts;
        n_open = 0; n_close = 0; n_run = 0;
    endtask

    task automatic press;               // button down for one clock, then up
        BTN_N = 0; tick; BTN_N = 1;
    endtask

    task automatic expect_counts(input int eo, input int ec, input int er, input string note);
        logic bad;
        bad = (n_open !== eo) | (n_close !== ec) | (n_run !== er);
        errors = errors + bad;
        $display("%-44s | open=%0d close=%0d run=%0d | exp %0d %0d %0d | ok=%b",
                 note, n_open, n_close, n_run, eo, ec, er, ~bad);
    endtask

    task automatic expect_idle(input string note);
        logic bad;
        bad = (RUNNING !== 1'b0) | (VALOR !== 3'd0) | (TEST_OPEN !== 1'b0) | (TEST_CLOSE !== 1'b0);
        errors = errors + bad;
        $display("%-44s | RUNNING=%b VALOR=%0d | ok=%b", note, RUNNING, VALOR, ~bad);
    endtask

    initial begin
        verdict[0] = "FAILED"; verdict[1] = "PASSED";
        CLK = 0; RST_N = 0; ENABLE = 0; BTN_N = 1; #5;
        raw_tick; raw_tick; raw_tick;               // reset needs clock edges
        RST_N = 1; #5;
        expect_idle("after reset");

        // 1) button pressed while the mode is disabled: nothing happens
        clear_counts;
        press; ticks(30);
        expect_counts(0, 0, 0, "1) press with ENABLE=0");

        // 2) one complete test
        ENABLE = 1; #5; clear_counts;
        press; ticks(30);
        expect_counts(8, 8, 17, "2) full test: 8 open, 8 close");
        expect_idle("   idle again");

        // 3) a second test right after the first
        clear_counts;
        press; ticks(30);
        expect_counts(8, 8, 17, "3) second test");

        // 4) a press during the test is ignored (no restart)
        clear_counts;
        press; ticks(5); press; ticks(30);
        expect_counts(8, 8, 17, "4) press while running ignored");

        // 5) button held down the whole time: only one test
        clear_counts;
        BTN_N = 0; ticks(40); BTN_N = 1; ticks(5);
        expect_counts(8, 8, 17, "5) button held: single test");

        // 6) disabling the mode in the middle aborts the test
        clear_counts;
        press; ticks(6);
        ENABLE = 0; #5;
        expect_idle("6) ENABLE=0 mid-test: aborted");
        ticks(10);
        ENABLE = 1; #5; ticks(10);
        expect_idle("   re-enabled, no press: stays idle");

        // 7) button already held when the mode is enabled: no start
        ENABLE = 0; #5; clear_counts;
        BTN_N = 0; ticks(4);
        ENABLE = 1; #5; ticks(20);
        BTN_N = 1; ticks(5);
        expect_counts(0, 0, 0, "7) held button + enable: no start");

        // 8) global reset in the middle of a test
        press; ticks(6);
        RST_N = 0; #5;
        expect_idle("8) RST_N mid-test: aborted");
        raw_tick; raw_tick;
        RST_N = 1; #5;
        clear_counts; ticks(10);
        expect_counts(0, 0, 0, "   idle after reset");
        press; ticks(30);
        expect_counts(8, 8, 17, "   test works again after reset");

        $display("=== tb_pwm_test_ctrl: %s (errors = %0d) ===", verdict[errors == 0], errors);
    end
endmodule
