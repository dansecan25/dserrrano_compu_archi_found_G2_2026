`timescale 1ns/1ps
// Full truth table (8 rows). Loops/arithmetic are used only here, as reference.
module tb_full_adder;
    logic A, B, CIN;
    wire  SUM, COUT;
    int   errors = 0;
    int   i;
    logic [1:0] expv;
    logic bad;
    string verdict [2];

    full_adder dut (.A(A), .B(B), .CIN(CIN), .SUM(SUM), .COUT(COUT));

    initial begin
        verdict[0] = "FAILED"; verdict[1] = "PASSED";
        for (i = 0; i < 8; i = i + 1) begin
            {A, B, CIN} = i[2:0]; #5;
            expv = A + B + CIN;
            bad  = ({COUT, SUM} !== expv);
            errors = errors + bad;
            $display("A=%b B=%b CIN=%b | COUT=%b SUM=%b | exp=%b | ok=%b", A, B, CIN, COUT, SUM, expv, ~bad);
        end
        $display("=== tb_full_adder: %s (errors = %0d) ===", verdict[errors == 0], errors);
    end
endmodule
