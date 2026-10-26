`timescale 1ns/1ps
// Each select passes only its own bus; no select -> 0. No loops.
module tb_flow_mux;
    logic [4:0] in_n, in_f, in_t;
    logic [2:0] sel;                // {TEST, FUNC2, NORMAL}
    wire  [4:0] out;
    int   errors = 0;
    string verdict [2];

    flow_mux dut (.IN_NORMAL(in_n), .IN_FUNC2(in_f), .IN_TEST(in_t),
                  .SEL_NORMAL(sel[0]), .SEL_FUNC2(sel[1]), .SEL_TEST(sel[2]), .OUT(out));

    task automatic chk(input logic [2:0] s, input logic [4:0] expv, input string note);
        logic bad;
        sel = s; #5;
        bad = (out !== expv);
        errors = errors + bad;
        $display("sel=%b | OUT=%b exp=%b | ok=%b | %s", sel, out, expv, ~bad, note);
    endtask

    initial begin
        verdict[0] = "FAILED"; verdict[1] = "PASSED";
        in_n = 5'b10101; in_f = 5'b01010; in_t = 5'b11001;
        chk(3'b001, 5'b10101, "normal");
        chk(3'b010, 5'b01010, "func2");
        chk(3'b100, 5'b11001, "test");
        chk(3'b000, 5'b00000, "none");
        $display("=== tb_flow_mux: %s (errors = %0d) ===", verdict[errors == 0], errors);
    end
endmodule
