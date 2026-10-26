`timescale 1ns/1ps
// Several dividers run at once on the same 50 MHz-style clock and are compared
// cycle by cycle with a reference model:
//   after fast edge n (counted from reset release) the output must be (n / HALF) mod 2,
//   i.e. HALF cycles high, HALF cycles low, 50 % duty.
// HALF = 1, 3, 5, 8 and 1029 (bits 0..10 of the counter) are simulated.
// The real value (75_000_000 -> 1.5 s at 50 MHz) is too long for gate-level
// simulation, so the instance with the default parameter is checked through its
// constants: HALF_PERIOD = 75_000_000 and TERMINAL = 74_999_999.
module tb_clock_divider;
    logic CLK, RST_N;
    wire  o1, o3, o5, o8, o1029, ofull;
    int   n, k, errors = 0;
    string verdict [2];

    clock_divider #(.HALF_PERIOD(1))    d1    (.CLK(CLK), .RST_N(RST_N), .CLK_OUT(o1));
    clock_divider #(.HALF_PERIOD(3))    d3    (.CLK(CLK), .RST_N(RST_N), .CLK_OUT(o3));
    clock_divider #(.HALF_PERIOD(5))    d5    (.CLK(CLK), .RST_N(RST_N), .CLK_OUT(o5));
    clock_divider #(.HALF_PERIOD(8))    d8    (.CLK(CLK), .RST_N(RST_N), .CLK_OUT(o8));
    clock_divider #(.HALF_PERIOD(1029)) d1029 (.CLK(CLK), .RST_N(RST_N), .CLK_OUT(o1029));
    clock_divider                       dfull (.CLK(CLK), .RST_N(RST_N), .CLK_OUT(ofull));

    // one 50 MHz-style cycle, then compare every output with the model
    task automatic fast_edge;
        logic bad;
        CLK = 1; #5;
        n = n + 1;
        bad = (o1    !== ((n / 1)    % 2))
            | (o3    !== ((n / 3)    % 2))
            | (o5    !== ((n / 5)    % 2))
            | (o8    !== ((n / 8)    % 2))
            | (o1029 !== ((n / 1029) % 2))
            | (ofull !== 1'b0);
        errors = errors + bad;
        CLK = 0; #5;
    endtask

    task automatic expect_all_low(input string note);
        logic bad;
        bad = (o1 !== 1'b0) | (o3 !== 1'b0) | (o5 !== 1'b0) | (o8 !== 1'b0)
            | (o1029 !== 1'b0) | (ofull !== 1'b0);
        errors = errors + bad;
        $display("%-48s | outputs all 0: ok=%b", note, ~bad);
    endtask

    initial begin
        verdict[0] = "FAILED"; verdict[1] = "PASSED";
        CLK = 0; RST_N = 0; n = 0; #10;
        expect_all_low("reset: all outputs low");
        CLK = 1; #5; CLK = 0; #5; CLK = 1; #5; CLK = 0; #5;
        expect_all_low("reset with clock running: still low");

        RST_N = 1; #5; n = 0;
        for (k = 0; k < 4200; k = k + 1) fast_edge;      // > 4 half periods of the 1029 divider
        $display("compared %0d edges against the model (HALF = 1, 3, 5, 8, 1029)", n);

        // reset in the middle of operation, then it starts again from 0
        RST_N = 0; #5;
        expect_all_low("reset mid-run: outputs cleared immediately");
        CLK = 1; #5; CLK = 0; #5;
        RST_N = 1; #5; n = 0;
        for (k = 0; k < 60; k = k + 1) fast_edge;
        $display("restarted after reset: %0d more edges compared", n);

        // constants of the default instance (1.5 s at 50 MHz)
        errors = errors + (dfull.HALF_PERIOD !== 75000000);
        errors = errors + (dfull.TERMINAL !== 27'd74999999);
        $display("default HALF_PERIOD = %0d, TERMINAL = %0d (2 * HALF_PERIOD / 50e6 = %0d s period)",
                 dfull.HALF_PERIOD, dfull.TERMINAL, 2 * dfull.HALF_PERIOD / 50000000);

        $display("=== tb_clock_divider: %s (errors = %0d) ===", verdict[errors == 0], errors);
    end
endmodule
