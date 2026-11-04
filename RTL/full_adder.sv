// 1-bit full adder. Gates: XOR / AND / OR only.
module full_adder (
    input  logic A,
    input  logic B,
    input  logic CIN,
    output logic SUM,
    output logic COUT
);
    wire axb     = A ^ B;
    wire ab      = A & B;
    wire axb_cin = axb & CIN;

    assign SUM  = axb ^ CIN;
    assign COUT = ab | axb_cin;
endmodule
