// Divisor de reloj: 50 MHz -> reloj lento con ciclo de trabajo 50 %.
// HALF_PERIOD = ciclos de CLK por cada medio periodo (nivel alto o bajo).
//   50 MHz y 1.5 s alto / 1.5 s bajo -> 75_000_000 ciclos (periodo 3 s, 0.333 Hz).
// Contador sincrono de 27 bits (2^27 = 134_217_728 > 75e6) que cuenta 0..HALF_PERIOD-1;
// en el ultimo conteo (tc = 1) vuelve a 0 y CLK_OUT cambia de nivel.
//   d[i] = (q[i] ^ c[i]) & ~tc       c[i] = q[0] & ... & q[i-1]   (acarreo)
//   tc   = (q == HALF_PERIOD-1)      comparacion con XOR/NOT contra la constante
//   CLK_OUT_d = CLK_OUT ^ tc
// RST_N (activo en bajo): borra contador y salida (CLK_OUT = 0 durante el reset).
// Solo compuertas + d_flipflop: sin if, ?:, ciclos ni generate.
module clock_divider #(
    parameter HALF_PERIOD = 75_000_000
) (
    input  logic CLK,
    input  logic RST_N,
    output logic CLK_OUT
);
    localparam [26:0] TERMINAL = HALF_PERIOD - 1;

    wire [26:0] q, qn, d, c, eq;
    wire tc, ntc, out_q, out_qn, out_d;

    // ---- acarreo del contador (c[i] = AND de los bits inferiores) ----
    assign c[0] = 1'b1;
    assign c[1] = c[0] & q[0];
    assign c[2] = c[1] & q[1];
    assign c[3] = c[2] & q[2];
    assign c[4] = c[3] & q[3];
    assign c[5] = c[4] & q[4];
    assign c[6] = c[5] & q[5];
    assign c[7] = c[6] & q[6];
    assign c[8] = c[7] & q[7];
    assign c[9] = c[8] & q[8];
    assign c[10] = c[9] & q[9];
    assign c[11] = c[10] & q[10];
    assign c[12] = c[11] & q[11];
    assign c[13] = c[12] & q[12];
    assign c[14] = c[13] & q[13];
    assign c[15] = c[14] & q[14];
    assign c[16] = c[15] & q[15];
    assign c[17] = c[16] & q[16];
    assign c[18] = c[17] & q[17];
    assign c[19] = c[18] & q[18];
    assign c[20] = c[19] & q[19];
    assign c[21] = c[20] & q[20];
    assign c[22] = c[21] & q[21];
    assign c[23] = c[22] & q[22];
    assign c[24] = c[23] & q[23];
    assign c[25] = c[24] & q[24];
    assign c[26] = c[25] & q[25];

    // ---- siguiente estado: incrementa, o 0 si es el ultimo conteo ----
    assign ntc = ~tc;
    assign d[0] = (q[0] ^ c[0]) & ntc;
    assign d[1] = (q[1] ^ c[1]) & ntc;
    assign d[2] = (q[2] ^ c[2]) & ntc;
    assign d[3] = (q[3] ^ c[3]) & ntc;
    assign d[4] = (q[4] ^ c[4]) & ntc;
    assign d[5] = (q[5] ^ c[5]) & ntc;
    assign d[6] = (q[6] ^ c[6]) & ntc;
    assign d[7] = (q[7] ^ c[7]) & ntc;
    assign d[8] = (q[8] ^ c[8]) & ntc;
    assign d[9] = (q[9] ^ c[9]) & ntc;
    assign d[10] = (q[10] ^ c[10]) & ntc;
    assign d[11] = (q[11] ^ c[11]) & ntc;
    assign d[12] = (q[12] ^ c[12]) & ntc;
    assign d[13] = (q[13] ^ c[13]) & ntc;
    assign d[14] = (q[14] ^ c[14]) & ntc;
    assign d[15] = (q[15] ^ c[15]) & ntc;
    assign d[16] = (q[16] ^ c[16]) & ntc;
    assign d[17] = (q[17] ^ c[17]) & ntc;
    assign d[18] = (q[18] ^ c[18]) & ntc;
    assign d[19] = (q[19] ^ c[19]) & ntc;
    assign d[20] = (q[20] ^ c[20]) & ntc;
    assign d[21] = (q[21] ^ c[21]) & ntc;
    assign d[22] = (q[22] ^ c[22]) & ntc;
    assign d[23] = (q[23] ^ c[23]) & ntc;
    assign d[24] = (q[24] ^ c[24]) & ntc;
    assign d[25] = (q[25] ^ c[25]) & ntc;
    assign d[26] = (q[26] ^ c[26]) & ntc;

    // ---- 27 flip-flops del contador ----
    d_flipflop u_cnt0  (.D(d[0]), .CLK(CLK), .CLR_N(RST_N), .Q(q[0]), .QN(qn[0]));
    d_flipflop u_cnt1  (.D(d[1]), .CLK(CLK), .CLR_N(RST_N), .Q(q[1]), .QN(qn[1]));
    d_flipflop u_cnt2  (.D(d[2]), .CLK(CLK), .CLR_N(RST_N), .Q(q[2]), .QN(qn[2]));
    d_flipflop u_cnt3  (.D(d[3]), .CLK(CLK), .CLR_N(RST_N), .Q(q[3]), .QN(qn[3]));
    d_flipflop u_cnt4  (.D(d[4]), .CLK(CLK), .CLR_N(RST_N), .Q(q[4]), .QN(qn[4]));
    d_flipflop u_cnt5  (.D(d[5]), .CLK(CLK), .CLR_N(RST_N), .Q(q[5]), .QN(qn[5]));
    d_flipflop u_cnt6  (.D(d[6]), .CLK(CLK), .CLR_N(RST_N), .Q(q[6]), .QN(qn[6]));
    d_flipflop u_cnt7  (.D(d[7]), .CLK(CLK), .CLR_N(RST_N), .Q(q[7]), .QN(qn[7]));
    d_flipflop u_cnt8  (.D(d[8]), .CLK(CLK), .CLR_N(RST_N), .Q(q[8]), .QN(qn[8]));
    d_flipflop u_cnt9  (.D(d[9]), .CLK(CLK), .CLR_N(RST_N), .Q(q[9]), .QN(qn[9]));
    d_flipflop u_cnt10 (.D(d[10]), .CLK(CLK), .CLR_N(RST_N), .Q(q[10]), .QN(qn[10]));
    d_flipflop u_cnt11 (.D(d[11]), .CLK(CLK), .CLR_N(RST_N), .Q(q[11]), .QN(qn[11]));
    d_flipflop u_cnt12 (.D(d[12]), .CLK(CLK), .CLR_N(RST_N), .Q(q[12]), .QN(qn[12]));
    d_flipflop u_cnt13 (.D(d[13]), .CLK(CLK), .CLR_N(RST_N), .Q(q[13]), .QN(qn[13]));
    d_flipflop u_cnt14 (.D(d[14]), .CLK(CLK), .CLR_N(RST_N), .Q(q[14]), .QN(qn[14]));
    d_flipflop u_cnt15 (.D(d[15]), .CLK(CLK), .CLR_N(RST_N), .Q(q[15]), .QN(qn[15]));
    d_flipflop u_cnt16 (.D(d[16]), .CLK(CLK), .CLR_N(RST_N), .Q(q[16]), .QN(qn[16]));
    d_flipflop u_cnt17 (.D(d[17]), .CLK(CLK), .CLR_N(RST_N), .Q(q[17]), .QN(qn[17]));
    d_flipflop u_cnt18 (.D(d[18]), .CLK(CLK), .CLR_N(RST_N), .Q(q[18]), .QN(qn[18]));
    d_flipflop u_cnt19 (.D(d[19]), .CLK(CLK), .CLR_N(RST_N), .Q(q[19]), .QN(qn[19]));
    d_flipflop u_cnt20 (.D(d[20]), .CLK(CLK), .CLR_N(RST_N), .Q(q[20]), .QN(qn[20]));
    d_flipflop u_cnt21 (.D(d[21]), .CLK(CLK), .CLR_N(RST_N), .Q(q[21]), .QN(qn[21]));
    d_flipflop u_cnt22 (.D(d[22]), .CLK(CLK), .CLR_N(RST_N), .Q(q[22]), .QN(qn[22]));
    d_flipflop u_cnt23 (.D(d[23]), .CLK(CLK), .CLR_N(RST_N), .Q(q[23]), .QN(qn[23]));
    d_flipflop u_cnt24 (.D(d[24]), .CLK(CLK), .CLR_N(RST_N), .Q(q[24]), .QN(qn[24]));
    d_flipflop u_cnt25 (.D(d[25]), .CLK(CLK), .CLR_N(RST_N), .Q(q[25]), .QN(qn[25]));
    d_flipflop u_cnt26 (.D(d[26]), .CLK(CLK), .CLR_N(RST_N), .Q(q[26]), .QN(qn[26]));

    // ---- ultimo conteo: q == HALF_PERIOD-1 ----
    assign eq[0] = ~(q[0] ^ TERMINAL[0]);
    assign eq[1] = ~(q[1] ^ TERMINAL[1]);
    assign eq[2] = ~(q[2] ^ TERMINAL[2]);
    assign eq[3] = ~(q[3] ^ TERMINAL[3]);
    assign eq[4] = ~(q[4] ^ TERMINAL[4]);
    assign eq[5] = ~(q[5] ^ TERMINAL[5]);
    assign eq[6] = ~(q[6] ^ TERMINAL[6]);
    assign eq[7] = ~(q[7] ^ TERMINAL[7]);
    assign eq[8] = ~(q[8] ^ TERMINAL[8]);
    assign eq[9] = ~(q[9] ^ TERMINAL[9]);
    assign eq[10] = ~(q[10] ^ TERMINAL[10]);
    assign eq[11] = ~(q[11] ^ TERMINAL[11]);
    assign eq[12] = ~(q[12] ^ TERMINAL[12]);
    assign eq[13] = ~(q[13] ^ TERMINAL[13]);
    assign eq[14] = ~(q[14] ^ TERMINAL[14]);
    assign eq[15] = ~(q[15] ^ TERMINAL[15]);
    assign eq[16] = ~(q[16] ^ TERMINAL[16]);
    assign eq[17] = ~(q[17] ^ TERMINAL[17]);
    assign eq[18] = ~(q[18] ^ TERMINAL[18]);
    assign eq[19] = ~(q[19] ^ TERMINAL[19]);
    assign eq[20] = ~(q[20] ^ TERMINAL[20]);
    assign eq[21] = ~(q[21] ^ TERMINAL[21]);
    assign eq[22] = ~(q[22] ^ TERMINAL[22]);
    assign eq[23] = ~(q[23] ^ TERMINAL[23]);
    assign eq[24] = ~(q[24] ^ TERMINAL[24]);
    assign eq[25] = ~(q[25] ^ TERMINAL[25]);
    assign eq[26] = ~(q[26] ^ TERMINAL[26]);
    assign tc = eq[0] & eq[1] & eq[2] & eq[3] & eq[4] & eq[5] & eq[6] & eq[7] & eq[8] &
                    eq[9] & eq[10] & eq[11] & eq[12] & eq[13] & eq[14] & eq[15] & eq[16] & eq[17] &
                    eq[18] & eq[19] & eq[20] & eq[21] & eq[22] & eq[23] & eq[24] & eq[25] & eq[26];

    // ---- salida: cambia de nivel en cada ultimo conteo ----
    assign out_d = out_q ^ tc;
    d_flipflop u_out (.D(out_d), .CLK(CLK), .CLR_N(RST_N), .Q(out_q), .QN(out_qn));
    assign CLK_OUT = out_q;
endmodule
