// PWM with 8 steps. VALOR (0..7) comes from the ALU.
//   PWM_OUT is high for VALOR out of every 8 clock cycles:
//   duty = VALOR / 8  ->  0, 12.5, 25, 37.5, 50, 62.5, 75, 87.5 %
//   PWM frequency = f_CLK / 8.
// The compare result goes through a flip-flop so the output pin is glitch-free
// (one clock of latency). RST_N (active low) clears the counter and output.
module pwm (
    input  logic       CLK,
    input  logic       RST_N,
    input  logic [2:0] VALOR,
    output logic       PWM_OUT
);
    wire [2:0] cnt;
    wire       lt;
    wire       pwm_qn;

    counter_3       u_cnt (.CLK(CLK), .RST_N(RST_N), .Q(cnt));
    comparator_lt_3 u_cmp (.A(cnt), .B(VALOR), .LT(lt));
    d_flipflop      u_out (.D(lt), .CLK(CLK), .CLR_N(RST_N), .Q(PWM_OUT), .QN(pwm_qn));
endmodule
