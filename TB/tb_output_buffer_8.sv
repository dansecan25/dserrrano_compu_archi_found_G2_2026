`timescale 1ns/1ps
// Tests output_buffer_8 exhaustively: 256 patterns x OE_N in {0,1}.
module tb_output_buffer_8;
    logic [7:0] D;
    logic       OE_N;
    wire  [7:0] Q;
    int         errors = 0;
    int         i;
    logic       bad;
    string      verdict [2];

    output_buffer_8 dut (.D(D), .OE_N(OE_N), .Q(Q));

    initial begin
        verdict[0] = "FAILED"; verdict[1] = "PASSED";

        OE_N = 0; D = 8'hA5; #5;
        $display("OE_N=%b D=%b Q=%b (expect Q=D)",   OE_N, D, Q);
        OE_N = 1; #5;
        $display("OE_N=%b D=%b Q=%b (expect Q=0)",   OE_N, D, Q);

        for (i = 0; i < 256; i = i + 1) begin
            D = i; OE_N = 0; #2;
            bad = (Q !== D);
            errors = errors + bad;
            OE_N = 1; #2;
            bad = (Q !== 8'h00);
            errors = errors + bad;
        end
        $display("checked 512 vectors");
        $display("=== tb_output_buffer_8: %s (errors = %0d) ===", verdict[errors == 0], errors);
    end
endmodule
