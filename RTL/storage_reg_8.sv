// 8-bit storage (latch) register of a 74HC595: copies D on RCLK rising edge.
// No clear input (like the real device).
// Purely structural: eight explicit d_flipflop instances, no loops / generate.
module storage_reg_8 (
    input  logic [7:0] D,
    input  logic       RCLK,
    output logic [7:0] Q
);
    wire q0, q1, q2, q3, q4, q5, q6, q7;
    wire qn0, qn1, qn2, qn3, qn4, qn5, qn6, qn7;

    d_flipflop u_ff0 (.D(D[0]), .CLK(RCLK), .CLR_N(1'b1), .Q(q0), .QN(qn0));
    d_flipflop u_ff1 (.D(D[1]), .CLK(RCLK), .CLR_N(1'b1), .Q(q1), .QN(qn1));
    d_flipflop u_ff2 (.D(D[2]), .CLK(RCLK), .CLR_N(1'b1), .Q(q2), .QN(qn2));
    d_flipflop u_ff3 (.D(D[3]), .CLK(RCLK), .CLR_N(1'b1), .Q(q3), .QN(qn3));
    d_flipflop u_ff4 (.D(D[4]), .CLK(RCLK), .CLR_N(1'b1), .Q(q4), .QN(qn4));
    d_flipflop u_ff5 (.D(D[5]), .CLK(RCLK), .CLR_N(1'b1), .Q(q5), .QN(qn5));
    d_flipflop u_ff6 (.D(D[6]), .CLK(RCLK), .CLR_N(1'b1), .Q(q6), .QN(qn6));
    d_flipflop u_ff7 (.D(D[7]), .CLK(RCLK), .CLR_N(1'b1), .Q(q7), .QN(qn7));

    assign Q[0] = q0;
    assign Q[1] = q1;
    assign Q[2] = q2;
    assign Q[3] = q3;
    assign Q[4] = q4;
    assign Q[5] = q5;
    assign Q[6] = q6;
    assign Q[7] = q7;
endmodule