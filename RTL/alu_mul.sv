// Operation 010: F = A * B   (12-bit product, 0..3969)
// Array multiplier: 36 AND partial products + 5 rows of adder_6.
// accN is the running sum after row N; accN[0] is final product bit N.
module alu_mul (
    input  logic [5:0]  A,
    input  logic [5:0]  B,
    output logic [11:0] F
);
    wire [5:0] pp0 = A & {6{B[0]}};
    wire [5:0] pp1 = A & {6{B[1]}};
    wire [5:0] pp2 = A & {6{B[2]}};
    wire [5:0] pp3 = A & {6{B[3]}};
    wire [5:0] pp4 = A & {6{B[4]}};
    wire [5:0] pp5 = A & {6{B[5]}};

    wire [5:0] s1, s2, s3, s4, s5;
    wire       c1, c2, c3, c4, c5;
    wire [6:0] acc1 = {c1, s1};
    wire [6:0] acc2 = {c2, s2};
    wire [6:0] acc3 = {c3, s3};
    wire [6:0] acc4 = {c4, s4};
    wire [6:0] acc5 = {c5, s5};

    adder_6 u_row1 (.A({1'b0, pp0[5:1]}), .B(pp1), .CIN(1'b0), .SUM(s1), .COUT(c1));
    adder_6 u_row2 (.A(acc1[6:1]),        .B(pp2), .CIN(1'b0), .SUM(s2), .COUT(c2));
    adder_6 u_row3 (.A(acc2[6:1]),        .B(pp3), .CIN(1'b0), .SUM(s3), .COUT(c3));
    adder_6 u_row4 (.A(acc3[6:1]),        .B(pp4), .CIN(1'b0), .SUM(s4), .COUT(c4));
    adder_6 u_row5 (.A(acc4[6:1]),        .B(pp5), .CIN(1'b0), .SUM(s5), .COUT(c5));

    assign F = {acc5[6:1], acc5[0], acc4[0], acc3[0], acc2[0], acc1[0], pp0[0]};
endmodule
