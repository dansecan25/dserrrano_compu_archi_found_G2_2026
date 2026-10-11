// 8-bit serial-in / parallel-out shift register stage of a 74HC595.
// Q[0]=QA ... Q[7]=QH. SER enters QA; every SRCLK rising edge moves data QA->QH.
// SRCLR_N is an asynchronous active-low clear.
// Purely structural: eight explicit d_flipflop instances, no loops / generate.
module shift_reg_8 (
    input  logic       SER,
    input  logic       SRCLK,
    input  logic       SRCLR_N,
    output logic [7:0] Q
);
    wire q0, q1, q2, q3, q4, q5, q6, q7;
    wire qn0, qn1, qn2, qn3, qn4, qn5, qn6, qn7;

    d_flipflop u_ff0 (.D(SER), .CLK(SRCLK), .CLR_N(SRCLR_N), .Q(q0), .QN(qn0));
    d_flipflop u_ff1 (.D(q0),  .CLK(SRCLK), .CLR_N(SRCLR_N), .Q(q1), .QN(qn1));
    d_flipflop u_ff2 (.D(q1),  .CLK(SRCLK), .CLR_N(SRCLR_N), .Q(q2), .QN(qn2));
    d_flipflop u_ff3 (.D(q2),  .CLK(SRCLK), .CLR_N(SRCLR_N), .Q(q3), .QN(qn3));
    d_flipflop u_ff4 (.D(q3),  .CLK(SRCLK), .CLR_N(SRCLR_N), .Q(q4), .QN(qn4));
    d_flipflop u_ff5 (.D(q4),  .CLK(SRCLK), .CLR_N(SRCLR_N), .Q(q5), .QN(qn5));
    d_flipflop u_ff6 (.D(q5),  .CLK(SRCLK), .CLR_N(SRCLR_N), .Q(q6), .QN(qn6));
    d_flipflop u_ff7 (.D(q6),  .CLK(SRCLK), .CLR_N(SRCLR_N), .Q(q7), .QN(qn7));

    assign Q[0] = q0;
    assign Q[1] = q1;
    assign Q[2] = q2;
    assign Q[3] = q3;
    assign Q[4] = q4;
    assign Q[5] = q5;
    assign Q[6] = q6;
    assign Q[7] = q7;
endmodule