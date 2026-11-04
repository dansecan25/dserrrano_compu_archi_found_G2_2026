// Operation 001: F = A - B   (7-bit two's complement, -63..63)
// A - B = A + ~B + 1.  The carry out is "no borrow", so the sign bit is ~cout.
module alu_sub (
    input  logic [5:0] A,
    input  logic [5:0] B,
    output logic [6:0] F
);
    wire [5:0] nb = ~B;
    wire [5:0] diff;
    wire       cout;

    adder_6 u_sub (.A(A), .B(nb), .CIN(1'b1), .SUM(diff), .COUT(cout));

    assign F = {~cout, diff};
endmodule
