`timescale 1ns/1ps
// Truth-table test of sr_latch. (No if / ternary used here either.)
// Note: S=R=1 -> S=R=0 simultaneously is a race (oscillation), so the
// forbidden state is always left through S=1,R=0 or S=0,R=1.
module tb_sr_latch;
    logic S, R;
    wire  Q, QN;
    int   errors = 0;
    string verdict [2];

    sr_latch dut (.S(S), .R(R), .Q(Q), .QN(QN));

    task automatic apply(input logic s_i, input logic r_i,
                         input logic exp_q, input logic exp_qn,
                         input string note);
        logic bad;
        S = s_i; R = r_i; #10;
        bad = (Q !== exp_q) | (QN !== exp_qn);
        errors = errors + bad;
        $display("%0t | S=%b R=%b | Q=%b QN=%b | exp Q=%b QN=%b | ok=%b | %s",
                 $time, S, R, Q, QN, exp_q, exp_qn, ~bad, note);
    endtask

    initial begin
        verdict[0] = "FAILED"; verdict[1] = "PASSED";
        apply(0,1, 0,1, "reset (initialises latch)");
        apply(0,0, 0,1, "hold 0");
        apply(0,1, 0,1, "reset again, stays 0");
        apply(1,0, 1,0, "set");
        apply(0,0, 1,0, "hold 1");
        apply(1,0, 1,0, "set again, stays 1");
        apply(1,1, 0,0, "forbidden 11 from Q=1");
        apply(1,0, 1,0, "leave forbidden via S");
        apply(0,1, 0,1, "reset");
        apply(1,1, 0,0, "forbidden 11 from Q=0");
        apply(0,1, 0,1, "leave forbidden via R");
        $display("=== tb_sr_latch: %s (errors = %0d) ===", verdict[errors == 0], errors);
    end
endmodule
