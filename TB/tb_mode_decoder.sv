`timescale 1ns/1ps
// All 8 switch combinations. Expected vector = {TEST, FUNC2, NORMAL}.
module tb_mode_decoder;
    logic [2:0] sw;                 // {SW3,SW2,SW1}
    wire  sel_normal, sel_func2, sel_test;
    int   errors = 0;
    string verdict [2];

    mode_decoder dut (.SW1(sw[0]), .SW2(sw[1]), .SW3(sw[2]),
                      .SEL_NORMAL(sel_normal), .SEL_FUNC2(sel_func2), .SEL_TEST(sel_test));

    task automatic chk(input logic [2:0] sw_i, input logic [2:0] expv, input string note);
        logic bad;
        sw = sw_i; #5;
        bad = ({sel_test, sel_func2, sel_normal} !== expv);
        errors = errors + bad;
        $display("SW3 SW2 SW1=%b | TEST FUNC2 NORMAL=%b | exp=%b | ok=%b | %s",
                 sw, {sel_test, sel_func2, sel_normal}, expv, ~bad, note);
    endtask

    initial begin
        verdict[0] = "FAILED"; verdict[1] = "PASSED";
        chk(3'b000, 3'b000, "no mode");
        chk(3'b001, 3'b001, "normal");
        chk(3'b010, 3'b010, "func2");
        chk(3'b011, 3'b010, "SW2 over SW1");
        chk(3'b100, 3'b100, "test");
        chk(3'b101, 3'b100, "SW3 over SW1");
        chk(3'b110, 3'b100, "SW3 over SW2");
        chk(3'b111, 3'b100, "SW3 over all");
        $display("=== tb_mode_decoder: %s (errors = %0d) ===", verdict[errors == 0], errors);
    end
endmodule
