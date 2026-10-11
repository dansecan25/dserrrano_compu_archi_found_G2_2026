`timescale 1ns/1ps
// Truth-table test of d_latch (transparent when EN=1, hold when EN=0, async clear).
module tb_d_latch;
    logic CLR_N, EN, D;
    wire  Q, QN;
    int   errors = 0;
    string verdict [2];

    d_latch dut (.D(D), .EN(EN), .CLR_N(CLR_N), .Q(Q), .QN(QN));

    // EN is changed first so the latch is closed before D moves.
    task automatic apply(input logic c, input logic e, input logic d,
                         input logic exp_q, input string note);
        logic bad;
        EN = e; #2;
        D = d; CLR_N = c; #8;
        bad = (Q !== exp_q) | (QN !== ~exp_q);
        errors = errors + bad;
        $display("%0t | CLR_N=%b EN=%b D=%b | Q=%b QN=%b | exp Q=%b | ok=%b | %s",
                 $time, CLR_N, EN, D, Q, QN, exp_q, ~bad, note);
    endtask

    initial begin
        verdict[0] = "FAILED"; verdict[1] = "PASSED";
        apply(0,0,1, 0, "clear dominates (EN=0, D=1)");
        apply(0,1,1, 0, "clear dominates (EN=1, D=1)");
        apply(0,1,0, 0, "clear dominates (EN=1, D=0)");
        apply(1,1,1, 1, "transparent, D=1");
        apply(1,1,0, 0, "transparent, D=0");
        apply(1,1,1, 1, "transparent, D=1");
        apply(1,0,1, 1, "EN=0, D=1 holds 1");
        apply(1,0,0, 1, "EN=0, D=0 holds 1");
        apply(1,1,0, 0, "transparent, D=0");
        apply(1,0,0, 0, "EN=0, D=0 holds 0");
        apply(1,0,1, 0, "EN=0, D=1 holds 0");
        apply(1,1,1, 1, "transparent, D=1");
        apply(0,1,1, 0, "async clear while transparent");
        apply(1,1,1, 1, "clear released, follows D");
        $display("=== tb_d_latch: %s (errors = %0d) ===", verdict[errors == 0], errors);
    end
endmodule
