// Display de siete segmentos, ANODO COMUN (segmento = 0 -> encendido).
// Recibe el valor normalizado 0..7 y dibuja el digito.
//   0: abcdef   1: bc   2: abdeg   3: abcdg   4: bcfg   5: acdfg   6: acdefg   7: abc
// Solo compuertas AND / OR / NOT.
module display_7seg (
    input  wire [2:0] VALOR,                 // 0..7
    output wire a, b, c, d, e, f, g
);
    wire x2 = VALOR[2];
    wire x1 = VALOR[1];
    wire x0 = VALOR[0];

    wire nx2 = ~x2;
    wire nx1 = ~x1;
    wire nx0 = ~x0;

    // minterminos (un digito cada uno)
    wire m0 = nx2 & nx1 & nx0;
    wire m1 = nx2 & nx1 & x0;
    wire m2 = nx2 & x1  & nx0;
    wire m3 = nx2 & x1  & x0;
    wire m4 = x2  & nx1 & nx0;
    wire m5 = x2  & nx1 & x0;
    wire m6 = x2  & x1  & nx0;
    wire m7 = x2  & x1  & x0;

    // segmento encendido (activo en alto)
    wire on_a = m0 | m2 | m3 | m5 | m6 | m7;
    wire on_b = m0 | m1 | m2 | m3 | m4 | m7;
    wire on_c = m0 | m1 | m3 | m4 | m5 | m6 | m7;
    wire on_d = m0 | m2 | m3 | m5 | m6;
    wire on_e = m0 | m2 | m6;
    wire on_f = m0 | m4 | m5 | m6;
    wire on_g = m2 | m3 | m4 | m5 | m6;

    // anodo comun: se invierte
    assign a = ~on_a;
    assign b = ~on_b;
    assign c = ~on_c;
    assign d = ~on_d;
    assign e = ~on_e;
    assign f = ~on_f;
    assign g = ~on_g;
endmodule
