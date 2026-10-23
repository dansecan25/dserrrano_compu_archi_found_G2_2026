// ALU: A, B (6 bits) and OpCode S = {S2,S1,S0}  ->  VALOR (0..7) for the PWM.
//   000 A+B   001 A-B   010 A*B   011 A<<<1   100 A>>>1   101..111 -> 0
// Rotations act on A. The result is wrapped circularly (mod 8).
module alu (
    input  logic [5:0] A,
    input  logic [5:0] B,
    input  logic [2:0] S,
    output logic [2:0] VALOR
);
    wire [6:0]  f_add, f_sub;
    wire [11:0] f_mul;
    wire [5:0]  f_rol, f_ror;
    wire        sel_add, sel_sub, sel_mul, sel_rol, sel_ror;
    wire [11:0] r_add, r_sub, r_mul, r_rol, r_ror, r_sel;

    opcode_decoder u_dec (.S2(S[2]), .S1(S[1]), .S0(S[0]),
                          .SEL_ADD(sel_add), .SEL_SUB(sel_sub), .SEL_MUL(sel_mul),
                          .SEL_ROL(sel_rol), .SEL_ROR(sel_ror));

    alu_add u_add (.A(A), .B(B), .F(f_add));
    alu_sub u_sub (.A(A), .B(B), .F(f_sub));
    alu_mul u_mul (.A(A), .B(B), .F(f_mul));
    alu_rol u_rol (.A(A), .F(f_rol));
    alu_ror u_ror (.A(A), .F(f_ror));

    // widen every result to 12 bits (sub is sign-extended)
    assign r_add = {5'b00000, f_add};
    assign r_sub = {{5{f_sub[6]}}, f_sub};
    assign r_mul = f_mul;
    assign r_rol = {6'b000000, f_rol};
    assign r_ror = {6'b000000, f_ror};

    result_mux u_mux (.R_ADD(r_add), .R_SUB(r_sub), .R_MUL(r_mul), .R_ROL(r_rol), .R_ROR(r_ror),
                      .SEL_ADD(sel_add), .SEL_SUB(sel_sub), .SEL_MUL(sel_mul),
                      .SEL_ROL(sel_rol), .SEL_ROR(sel_ror), .R(r_sel));

    normalizer u_norm (.F(r_sel), .VALOR(VALOR));
endmodule
