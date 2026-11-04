`timescale 1ns/1ps
// All 8 opcodes, explicit (no loops). Expected vector = {ROR,ROL,MUL,SUB,ADD}.
module tb_opcode_decoder;
    logic [2:0] s;
    wire  sel_add, sel_sub, sel_mul, sel_rol, sel_ror;
    int   errors = 0;
    string verdict [2];

    opcode_decoder dut (.S2(s[2]), .S1(s[1]), .S0(s[0]),
                        .SEL_ADD(sel_add), .SEL_SUB(sel_sub), .SEL_MUL(sel_mul),
                        .SEL_ROL(sel_rol), .SEL_ROR(sel_ror));

    task automatic chk(input logic [2:0] s_i, input logic [4:0] expv, input string note);
        logic bad;
        s = s_i; #5;
        bad = ({sel_ror, sel_rol, sel_mul, sel_sub, sel_add} !== expv);
        errors = errors + bad;
        $display("S2S1S0=%b | ROR ROL MUL SUB ADD = %b | exp=%b | ok=%b | %s",
                 s, {sel_ror, sel_rol, sel_mul, sel_sub, sel_add}, expv, ~bad, note);
    endtask

    initial begin
        verdict[0] = "FAILED"; verdict[1] = "PASSED";
        chk(3'b000, 5'b00001, "ADD");
        chk(3'b001, 5'b00010, "SUB");
        chk(3'b010, 5'b00100, "MUL");
        chk(3'b011, 5'b01000, "ROL");
        chk(3'b100, 5'b10000, "ROR");
        chk(3'b101, 5'b00000, "unused");
        chk(3'b110, 5'b00000, "unused");
        chk(3'b111, 5'b00000, "unused");
        $display("=== tb_opcode_decoder: %s (errors = %0d) ===", verdict[errors == 0], errors);
    end
endmodule
