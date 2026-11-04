`timescale 1ns/1ps
// Exhaustive: 8 x 8 = 64 combinations.
module tb_comparator_lt_3;
    logic [2:0] A, B;
    wire        LT;
    int   a, b, errors = 0;
    logic bad;
    string verdict [2];

    comparator_lt_3 dut (.A(A), .B(B), .LT(LT));

    initial begin
        verdict[0] = "FAILED"; verdict[1] = "PASSED";
        for (a = 0; a < 8; a = a + 1)
            for (b = 0; b < 8; b = b + 1) begin
                A = a; B = b; #1;
                bad = (LT !== (a < b));
                errors = errors + bad;
                $display("A=%0d B=%0d | LT=%b exp=%b | ok=%b", A, B, LT, (a < b), ~bad);
            end
        $display("=== tb_comparator_lt_3: %s (errors = %0d) ===", verdict[errors == 0], errors);
    end
endmodule
