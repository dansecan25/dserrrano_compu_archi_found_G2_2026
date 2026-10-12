`timescale 1ns/1ps
// Y latches: capture only while CLK=1, hold afterwards, RESET clears (and wins).
module tb_y_latch_bank;
    logic [4:0] y;                 // {Y5..Y1}
    logic       CLK, RESET;
    wire  [4:0] e;                 // {E5..E1}
    int   errors = 0;
    string verdict [2];

    y_latch_bank dut (.Y1(y[0]), .Y2(y[1]), .Y3(y[2]), .Y4(y[3]), .Y5(y[4]),
                      .CLK(CLK), .RESET(RESET),
                      .E1(e[0]), .E2(e[1]), .E3(e[2]), .E4(e[3]), .E5(e[4]));

    task automatic chk(input logic [4:0] exp_e, input string note);
        logic bad;
        #5;
        bad = (e !== exp_e);
        errors = errors + bad;
        $display("%0t | CLK=%b RESET=%b Y=%b | E=%b exp=%b | ok=%b | %s",
                 $time, CLK, RESET, y, e, exp_e, ~bad, note);
    endtask

    initial begin
        verdict[0] = "FAILED"; verdict[1] = "PASSED";
        CLK = 0; y = 5'b00000; RESET = 1; #5;
        chk(5'b00000, "reset initialises latches");
        RESET = 0;
        chk(5'b00000, "reset released, holds 0");

        y = 5'b00001; chk(5'b00000, "Y1=1 but CLK=0: not captured");
        CLK = 1;      chk(5'b00001, "CLK=1: Y1 captured");
        CLK = 0; y = 5'b00000; chk(5'b00001, "CLK=0, Y=0: holds");

        y = 5'b00100; CLK = 1; chk(5'b00101, "Y3 captured, Y1 kept");
        CLK = 0; y = 5'b00000; chk(5'b00101, "holds");

        y = 5'b10000; CLK = 1; chk(5'b10101, "Y5 captured");
        CLK = 0; y = 5'b00000; chk(5'b10101, "holds");

        y = 5'b01010; CLK = 1; chk(5'b11111, "Y2,Y4 captured -> all set");
        CLK = 0; y = 5'b00000; chk(5'b11111, "holds");

        RESET = 1; chk(5'b00000, "RESET clears all");
        y = 5'b00001; CLK = 1; chk(5'b00000, "RESET wins over S");
        // leave S=R=1 in two steps (S first): S=R=1 -> S=R=0 at once is a race
        CLK = 0; y = 5'b00000; chk(5'b00000, "CLK=0 while RESET=1: still 0");
        RESET = 0;              chk(5'b00000, "RESET released: holds 0");

        $display("=== tb_y_latch_bank: %s (errors = %0d) ===", verdict[errors == 0], errors);
    end
endmodule
