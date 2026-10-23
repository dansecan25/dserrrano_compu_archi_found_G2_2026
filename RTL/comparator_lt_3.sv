// 3-bit magnitude comparator: LT = 1 when A < B. Gates only (AND/OR/NOT/XOR).
module comparator_lt_3 (
    input  logic [2:0] A,
    input  logic [2:0] B,
    output logic       LT
);
    wire nA2 = ~A[2];
    wire nA1 = ~A[1];
    wire nA0 = ~A[0];

    wire eq2 = ~(A[2] ^ B[2]);
    wire eq1 = ~(A[1] ^ B[1]);

    wire lt2 = nA2 & B[2];
    wire lt1 = nA1 & B[1];
    wire lt0 = nA0 & B[0];

    assign LT = lt2 | (eq2 & lt1) | (eq2 & eq1 & lt0);
endmodule
