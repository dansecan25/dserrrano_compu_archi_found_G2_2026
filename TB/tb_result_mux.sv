`timescale 1ns/1ps
// Each select alone passes its own bus; no select -> 0 (explicit, no loops).
module tb_result_mux;
    logic [11:0] r_add, r_sub, r_mul, r_rol, r_ror;
    logic [4:0]  sel;               // {ROR,ROL,MUL,SUB,ADD}
    wire  [11:0] r;
    int   errors = 0;
    string verdict [2];

    result_mux dut (.R_ADD(r_add), .R_SUB(r_sub), .R_MUL(r_mul), .R_ROL(r_rol), .R_ROR(r_ror),
                    .SEL_ADD(sel[0]), .SEL_SUB(sel[1]), .SEL_MUL(sel[2]),
                    .SEL_ROL(sel[3]), .SEL_ROR(sel[4]), .R(r));

    task automatic chk(input logic [4:0] sel_i, input logic [11:0] expv, input string note);
        logic bad;
        sel = sel_i; #5;
        bad = (r !== expv);
        errors = errors + bad;
        $display("sel=%b | R=%h exp=%h | ok=%b | %s", sel, r, expv, ~bad, note);
    endtask

    initial begin
        verdict[0] = "FAILED"; verdict[1] = "PASSED";
        r_add = 12'hA01; r_sub = 12'h5B2; r_mul = 12'hC43; r_rol = 12'h3D4; r_ror = 12'hE65;
        chk(5'b00001, 12'hA01, "ADD");
        chk(5'b00010, 12'h5B2, "SUB");
        chk(5'b00100, 12'hC43, "MUL");
        chk(5'b01000, 12'h3D4, "ROL");
        chk(5'b10000, 12'hE65, "ROR");
        chk(5'b00000, 12'h000, "none selected");
        $display("=== tb_result_mux: %s (errors = %0d) ===", verdict[errors == 0], errors);
    end
endmodule
