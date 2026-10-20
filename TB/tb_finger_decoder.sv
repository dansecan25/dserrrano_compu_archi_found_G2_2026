`timescale 1ns/1ps
// Thermometer rows of the table -> one-hot Y; non-thermometer inputs -> all 0.
module tb_finger_decoder;
    logic [4:0] s;                 // {S5,S4,S3,S2,S1}
    wire  [4:0] y;                 // {Y5,Y4,Y3,Y2,Y1}
    int   errors = 0;
    string verdict [2];

    finger_decoder dut (.S1(s[0]), .S2(s[1]), .S3(s[2]), .S4(s[3]), .S5(s[4]),
                        .Y1(y[0]), .Y2(y[1]), .Y3(y[2]), .Y4(y[3]), .Y5(y[4]));

    task automatic chk(input logic [4:0] s_i, input logic [4:0] exp_y, input string note);
        logic bad;
        s = s_i; #10;
        bad = (y !== exp_y);
        errors = errors + bad;
        $display("%0t | S5..S1=%b | Y5..Y1=%b exp=%b | ok=%b | %s", $time, s, y, exp_y, ~bad, note);
    endtask

    initial begin
        verdict[0] = "FAILED"; verdict[1] = "PASSED";
        chk(5'b00000, 5'b00000, "no fingers");
        chk(5'b00001, 5'b00001, "1 finger  -> Y1");
        chk(5'b00011, 5'b00010, "2 fingers -> Y2");
        chk(5'b00111, 5'b00100, "3 fingers -> Y3");
        chk(5'b01111, 5'b01000, "4 fingers -> Y4");
        chk(5'b11111, 5'b10000, "5 fingers -> Y5");
        chk(5'b00010, 5'b00000, "invalid (S2 only)");
        chk(5'b00100, 5'b00000, "invalid (S3 only)");
        chk(5'b10000, 5'b00000, "invalid (S5 only)");
        chk(5'b00101, 5'b00000, "invalid (S1,S3)");
        chk(5'b11110, 5'b00000, "invalid (no S1)");
        chk(5'b01011, 5'b00000, "invalid (gap at S3)");
        $display("=== tb_finger_decoder: %s (errors = %0d) ===", verdict[errors == 0], errors);
    end
endmodule
