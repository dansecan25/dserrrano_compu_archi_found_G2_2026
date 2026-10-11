`timescale 1ns/1ps
// Tests shift_reg_8: one bit and two bits travelling QA -> QH and falling off,
// plus async clear. A tiny reference model ("model") is updated on each edge.
module tb_shift_reg_8;
    logic       SER, SRCLK, SRCLR_N;
    wire  [7:0] Q;
    logic [7:0] model;
    int         errors = 0;
    string      verdict [2];
    string      phase;

    shift_reg_8 dut (.SER(SER), .SRCLK(SRCLK), .SRCLR_N(SRCLR_N), .Q(Q));

    task automatic check(input string step);
        logic bad;
        bad = (Q !== model);
        errors = errors + bad;
        $display("%0t | %-26s | %-18s | SER=%b | QH..QA=%b | exp=%b | ok=%b",
                 $time, phase, step, SER, Q, model, ~bad);
    endtask

    task automatic clear_all;
        SRCLR_N = 0; #5;
        model = 8'h00;
        check("async clear");
        SRCLR_N = 1; #5;
    endtask

    task automatic clk_bit(input logic s);
        SER = s; #5;
        SRCLK = 1;
        model = {model[6:0], s};
        #5;
        check("rising edge");
        SRCLK = 0; #5;
    endtask

    initial begin
        verdict[0] = "FAILED"; verdict[1] = "PASSED";
        SER = 0; SRCLK = 0; SRCLR_N = 1; model = 8'h00; #5;

        phase = "reset";
        clear_all;

        phase = "single bit";
        clk_bit(1);
        repeat (8) clk_bit(0);              // bit reaches QH on clock 8, leaves on 9

        phase = "two adjacent bits (11)";
        clk_bit(1); clk_bit(1);
        repeat (8) clk_bit(0);

        phase = "two separated bits (101)";
        clk_bit(1); clk_bit(0); clk_bit(1);
        repeat (8) clk_bit(0);

        phase = "no clock, no shift";
        SER = 1; #10;
        check("SER=1, no edge");
        SER = 0;

        phase = "clear mid-shift";
        clk_bit(1); clk_bit(1); clk_bit(0);
        clear_all;
        clk_bit(0);

        $display("=== tb_shift_reg_8: %s (errors = %0d) ===", verdict[errors == 0], errors);
    end
endmodule
