// Five SR latches that remember each Y.
//   S_n = Yn & CLK   (a Y is only captured while CLK = 1)
//   R_n = RESET      (shared, active high; RESET wins -> Q=0)
// En = Q of latch n.
module y_latch_bank (
    input  logic Y1, Y2, Y3, Y4, Y5,
    input  logic CLK,
    input  logic RESET,
    output logic E1, E2, E3, E4, E5
);
    wire s1 = Y1 & CLK;
    wire s2 = Y2 & CLK;
    wire s3 = Y3 & CLK;
    wire s4 = Y4 & CLK;
    wire s5 = Y5 & CLK;

    sr_latch u_l1 (.S(s1), .R(RESET), .Q(E1), .QN());
    sr_latch u_l2 (.S(s2), .R(RESET), .Q(E2), .QN());
    sr_latch u_l3 (.S(s3), .R(RESET), .Q(E3), .QN());
    sr_latch u_l4 (.S(s4), .R(RESET), .Q(E4), .QN());
    sr_latch u_l5 (.S(s5), .R(RESET), .Q(E5), .QN());
endmodule
