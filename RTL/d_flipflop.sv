// Positive-edge D flip-flop (master/slave) with asynchronous active-low clear.
// Master latch is transparent while CLK=0, slave latch while CLK=1.
// Tie CLR_N to 1 to get a plain D flip-flop.
//   CLR_N CLK  D | Q
//     0    x   x | 0   (async clear)
//     1   rise D | D
//     1  other x | hold
module d_flipflop (
    input  logic D,
    input  logic CLK,
    input  logic CLR_N,
    output logic Q,
    output logic QN
);
    wire nclk = ~CLK;
    wire qm, qmn;

    d_latch u_master (.D(D),  .EN(nclk), .CLR_N(CLR_N), .Q(qm), .QN(qmn));
    d_latch u_slave  (.D(qm), .EN(CLK),  .CLR_N(CLR_N), .Q(Q),  .QN(QN));
endmodule
