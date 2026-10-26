`timescale 1ns/1ps
// Exhaustive: 64 x 64 x 2 = 8192 combinations of A, B, CIN.
module tb_adder_6;
    logic [5:0] A, B;
    logic       CIN;
    wire  [5:0] SUM;
    wire        COUT;
    int   a, b, c, errors = 0;
    logic [6:0] expv;
    logic bad;
    string verdict [2];

    adder_6 dut (.A(A), .B(B), .CIN(CIN), .SUM(SUM), .COUT(COUT));

    initial begin
        verdict[0] = "FAILED"; verdict[1] = "PASSED";
        for (a = 0; a < 64; a = a + 1)
            for (b = 0; b < 64; b = b + 1)
                for (c = 0; c < 2; c = c + 1) begin
                    A = a; B = b; CIN = c; #1;
                    expv = a + b + c;
                    bad  = ({COUT, SUM} !== expv);
                    errors = errors + bad;
                end
        A = 6'd63; B = 6'd63; CIN = 1; #1;
        $display("63 + 63 + 1 = {COUT=%b, SUM=%0d} -> %0d", COUT, SUM, {COUT, SUM});
        A = 6'd0;  B = 6'd0;  CIN = 0; #1;
        $display(" 0 +  0 + 0 = {COUT=%b, SUM=%0d} -> %0d", COUT, SUM, {COUT, SUM});
        $display("checked 8192 vectors");
        $display("=== tb_adder_6: %s (errors = %0d) ===", verdict[errors == 0], errors);
    end
endmodule
