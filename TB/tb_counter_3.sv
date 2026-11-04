`timescale 1ns/1ps
// Async clear, counting 0..7 with wrap, clear in the middle of a count.
module tb_counter_3;
    logic       CLK, RST_N;
    wire  [2:0] Q;
    int   k, errors = 0;
    string verdict [2];

    counter_3 dut (.CLK(CLK), .RST_N(RST_N), .Q(Q));

    task automatic chk(input logic [2:0] expv, input string note);
        logic bad;
        bad = (Q !== expv);
        errors = errors + bad;
        $display("%0t | RST_N=%b | Q=%0d exp=%0d | ok=%b | %s", $time, RST_N, Q, expv, ~bad, note);
    endtask

    task automatic tick;
        CLK = 1; #5; CLK = 0; #5;
    endtask

    initial begin
        verdict[0] = "FAILED"; verdict[1] = "PASSED";
        CLK = 0; RST_N = 0; #5;
        chk(3'd0, "async clear");
        tick;
        chk(3'd0, "clock ignored while in reset");
        RST_N = 1; #5;
        chk(3'd0, "reset released, still 0");

        for (k = 1; k <= 20; k = k + 1) begin
            tick;
            chk(k % 8, "counting");
        end

        RST_N = 0; #5;
        chk(3'd0, "async clear mid-count");
        RST_N = 1; #5;
        tick;
        chk(3'd1, "counts again from 0");

        $display("=== tb_counter_3: %s (errors = %0d) ===", verdict[errors == 0], errors);
    end
endmodule
