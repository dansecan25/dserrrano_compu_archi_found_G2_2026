`timescale 1ns/1ps
// Wrap-around to 0..7 for every 12-bit input (4096 vectors) + examples.
module tb_normalizer;
    logic [11:0] F;
    wire  [2:0]  VALOR;
    int   i, errors = 0;
    logic bad;
    string verdict [2];

    normalizer dut (.F(F), .VALOR(VALOR));

    task automatic example(input logic [11:0] f_i);
        F = f_i; #1;
        $display("F=%0d (%b) -> VALOR=%0d", F, F, VALOR);
    endtask

    initial begin
        verdict[0] = "FAILED"; verdict[1] = "PASSED";
        for (i = 0; i < 4096; i = i + 1) begin
            F = i; #1;
            bad = (VALOR !== (i % 8));
            errors = errors + bad;
        end
        example(12'd0);
        example(12'd7);
        example(12'd8);
        example(12'd21);
        example(12'd3969);
        $display("checked 4096 vectors");
        $display("=== tb_normalizer: %s (errors = %0d) ===", verdict[errors == 0], errors);
    end
endmodule
