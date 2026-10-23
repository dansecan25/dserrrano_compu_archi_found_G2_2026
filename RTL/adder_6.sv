// 6-bit ripple-carry adder: SUM = A + B + CIN, COUT = carry out.
// Six explicit full_adder instances (no loops / generate).
module adder_6 (
    input  logic [5:0] A,
    input  logic [5:0] B,
    input  logic       CIN,
    output logic [5:0] SUM,
    output logic       COUT
);
    wire s0, s1, s2, s3, s4, s5;
    wire c1, c2, c3, c4, c5, c6;

    full_adder u_fa0 (.A(A[0]), .B(B[0]), .CIN(CIN), .SUM(s0), .COUT(c1));
    full_adder u_fa1 (.A(A[1]), .B(B[1]), .CIN(c1),  .SUM(s1), .COUT(c2));
    full_adder u_fa2 (.A(A[2]), .B(B[2]), .CIN(c2),  .SUM(s2), .COUT(c3));
    full_adder u_fa3 (.A(A[3]), .B(B[3]), .CIN(c3),  .SUM(s3), .COUT(c4));
    full_adder u_fa4 (.A(A[4]), .B(B[4]), .CIN(c4),  .SUM(s4), .COUT(c5));
    full_adder u_fa5 (.A(A[5]), .B(B[5]), .CIN(c5),  .SUM(s5), .COUT(c6));

    assign SUM  = {s5, s4, s3, s2, s1, s0};
    assign COUT = c6;
endmodule
