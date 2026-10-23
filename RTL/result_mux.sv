// AND-OR multiplexer: passes the bus whose select is 1 (no select -> 0).
module result_mux (
    input  logic [11:0] R_ADD, R_SUB, R_MUL, R_ROL, R_ROR,
    input  logic        SEL_ADD, SEL_SUB, SEL_MUL, SEL_ROL, SEL_ROR,
    output logic [11:0] R
);
    assign R = (R_ADD & {12{SEL_ADD}})
             | (R_SUB & {12{SEL_SUB}})
             | (R_MUL & {12{SEL_MUL}})
             | (R_ROL & {12{SEL_ROL}})
             | (R_ROR & {12{SEL_ROR}});
endmodule
