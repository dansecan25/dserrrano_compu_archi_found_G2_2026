// Operation 000: F = A + B   (7-bit result, 0..126)
module alu_add (
    input  logic [5:0] A,
    input  logic [5:0] B,
    output logic [6:0] F
);
    wire [5:0] sum;
    wire       cout;

    adder_6 u_add (.A(A), .B(B), .CIN(1'b0), .SUM(sum), .COUT(cout));

    assign F = {cout, sum};
endmodule
