`timescale 1ns/1ps
// Exhaustive A*B (4096 vectors), 12-bit result.
module tb_alu_mul;
    logic [5:0]  A, B;
    wire  [11:0] F;
    int   a, b, errors = 0;
    logic [11:0] expv;
    logic bad;
    string verdict [2];

    alu_mul dut (.A(A), .B(B), .F(F));

    task automatic example(input logic [5:0] a_i, input logic [5:0] b_i);
        A = a_i; B = b_i; #1;
        $display("A=%0d B=%0d -> F=%0d (%b)", A, B, F, F);
    endtask

    initial begin
        verdict[0] = "FAILED"; verdict[1] = "PASSED";
        for (a = 0; a < 64; a = a + 1)
            for (b = 0; b < 64; b = b + 1) begin
                A = a; B = b; #1;
                expv = a * b;
                bad  = (F !== expv);
                errors = errors + bad;
            end
        example(6'd0, 6'd63);
        example(6'd7, 6'd3);
        example(6'd63, 6'd63);
        $display("checked 4096 vectors");
        $display("=== tb_alu_mul: %s (errors = %0d) ===", verdict[errors == 0], errors);
    end
endmodule
