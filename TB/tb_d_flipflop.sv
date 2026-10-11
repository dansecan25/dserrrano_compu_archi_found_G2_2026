`timescale 1ns/1ps
// Truth-table test of the positive-edge D flip-flop with async clear.
module tb_d_flipflop;
    logic D, CLK, CLR_N;
    wire  Q, QN;
    int   errors = 0;
    string verdict [2];

    d_flipflop dut (.D(D), .CLK(CLK), .CLR_N(CLR_N), .Q(Q), .QN(QN));

    task automatic chk(input logic exp_q, input string note);
        logic bad;
        bad = (Q !== exp_q) | (QN !== ~exp_q);
        errors = errors + bad;
        $display("%0t | CLR_N=%b CLK=%b D=%b | Q=%b QN=%b | exp Q=%b | ok=%b | %s",
                 $time, CLR_N, CLK, D, Q, QN, exp_q, ~bad, note);
    endtask

    initial begin
        verdict[0] = "FAILED"; verdict[1] = "PASSED";

        // ---- asynchronous clear ----
        CLK = 0; D = 0; CLR_N = 0; #10;
        chk(0, "async clear (CLK=0, D=0)");
        D = 1; #10;
        chk(0, "clear dominates D=1");
        CLK = 1; #10;
        chk(0, "clear dominates rising edge");
        CLK = 0; #10;
        chk(0, "clear dominates falling edge");
        CLR_N = 1; #10;
        chk(0, "clear released, no edge: holds 0");

        // ---- edge-triggered capture ----
        D = 1; #10;
        chk(0, "D=1 before edge: Q unchanged");
        CLK = 1; #10;
        chk(1, "rising edge captures D=1");
        D = 0; #10;
        chk(1, "D=0 while CLK=1: Q holds");
        CLK = 0; #10;
        chk(1, "falling edge: Q holds");
        CLK = 1; #10;
        chk(0, "rising edge captures D=0");
        D = 1; #10;
        chk(0, "D=1 while CLK=1: Q holds");
        CLK = 0; #10;
        chk(0, "falling edge: Q holds 0");
        D = 0; #10;
        CLK = 1; #10;
        chk(0, "rising edge, D=0: stays 0");
        CLK = 0; D = 1; #10;
        CLK = 1; #10;
        chk(1, "rising edge captures D=1");

        // ---- clear while storing 1 ----
        CLR_N = 0; #10;
        chk(0, "async clear while Q=1, CLK=1");
        CLR_N = 1; #10;
        chk(0, "release with CLK=1, D=1: no edge, holds 0");
        CLK = 0; #10;
        chk(0, "falling edge after release: holds 0");
        CLK = 1; #10;
        chk(1, "next rising edge captures D=1");

        $display("=== tb_d_flipflop: %s (errors = %0d) ===", verdict[errors == 0], errors);
    end
endmodule
