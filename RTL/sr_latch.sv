// SR latch (active-high inputs) built from two cross-coupled NOR gates.
// NOR(a,b) = ~(a | b)  -> only OR / NOT operators.
//   S R | Q  QN
//   0 0 | hold
//   0 1 | 0  1   (reset)
//   1 0 | 1  0   (set)
//   1 1 | 0  0   (forbidden)
module sr_latch (
    input  logic S,
    input  logic R,
    output logic Q,
    output logic QN
);
    assign Q  = ~(R | QN);
    assign QN = ~(S | Q);
endmodule
