// OpCode (S2 S1 S0) -> one-hot select. Codes 101, 110, 111 select nothing.
module opcode_decoder (
    input  logic S2, S1, S0,
    output logic SEL_ADD,   // 000
    output logic SEL_SUB,   // 001
    output logic SEL_MUL,   // 010
    output logic SEL_ROL,   // 011
    output logic SEL_ROR    // 100
);
    wire nS2 = ~S2;
    wire nS1 = ~S1;
    wire nS0 = ~S0;

    assign SEL_ADD = nS2 & nS1 & nS0;
    assign SEL_SUB = nS2 & nS1 & S0;
    assign SEL_MUL = nS2 & S1  & nS0;
    assign SEL_ROL = nS2 & S1  & S0;
    assign SEL_ROR = S2  & nS1 & nS0;
endmodule
