// 3-bit synchronous up counter (0..7, wraps), async active-low clear.
// Three d_flipflop + XOR/AND/NOT toggle logic:
//   d0 = ~q0   d1 = q1 ^ q0   d2 = q2 ^ (q1 & q0)
module counter_3 (
    input  logic       CLK,
    input  logic       RST_N,
    output logic [2:0] Q
);
    wire q0, q1, q2;
    wire qn0, qn1, qn2;
    wire d0 = ~q0;
    wire d1 = q1 ^ q0;
    wire d2 = q2 ^ (q1 & q0);

    d_flipflop u_ff0 (.D(d0), .CLK(CLK), .CLR_N(RST_N), .Q(q0), .QN(qn0));
    d_flipflop u_ff1 (.D(d1), .CLK(CLK), .CLR_N(RST_N), .Q(q1), .QN(qn1));
    d_flipflop u_ff2 (.D(d2), .CLK(CLK), .CLR_N(RST_N), .Q(q2), .QN(qn2));

    assign Q = {q2, q1, q0};
endmodule
