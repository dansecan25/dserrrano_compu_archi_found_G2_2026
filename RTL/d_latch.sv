// Gated D latch (level sensitive) with asynchronous active-low clear.
// Built from the SR latch plus AND / OR / NOT gates only.
//   CLR_N EN D | Q
//     0   x  x | 0   (clear)
//     1   0  x | hold
//     1   1  D | D    (transparent)
module d_latch (
    input  logic D,
    input  logic EN,
    input  logic CLR_N,
    output logic Q,
    output logic QN
);
    wire nd = ~D;
    wire s  = D  & EN & CLR_N;
    wire r  = (nd & EN) | ~CLR_N;

    sr_latch u_sr (.S(s), .R(r), .Q(Q), .QN(QN));
endmodule
