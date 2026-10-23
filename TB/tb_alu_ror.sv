`timescale 1ns/1ps
// Exhaustive 6-bit rotate-right-by-1 (64 vectors).
module tb_alu_ror;
    logic [5:0] A;
    wire  [5:0] F;
    int   a, errors = 0;
    logic [5:0] expv;
    logic bad;
    string verdict [2];

    alu_ror dut (.A(A), .F(F));

    task automatic example(input logic [5:0] a_i);
        A = a_i; #1;
        $display("A=%b -> F=%b", A, F);
    endtask

    initial begin
        verdict[0] = "FAILED"; verdict[1] = "PASSED";
        for (a = 0; a < 64; a = a + 1) begin
            A = a; #1;
            expv = (a >> 1) | (a << 5);
            bad  = (F !== expv);
            errors = errors + bad;
        end
        example(6'b100001);
        example(6'b000001);
        example(6'b101010);
        $display("checked 64 vectors");
        $display("=== tb_alu_ror: %s (errors = %0d) ===", verdict[errors == 0], errors);
    end
endmodule
