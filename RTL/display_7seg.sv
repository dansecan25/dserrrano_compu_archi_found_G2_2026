module display_7seg (
    input  wire X, Y, //X = abrir, Y = cerrar
    output wire a, b, c, d, e, f, g
);

    wire nX;
    wire nY;
    wire R;

    // NOT
    not U1 (nX, X);
    not U2 (nY, Y);

    // Segmento a: AND de las entradas negadas
    and U3 (a, nX, nY);

    // Segmentos b, c y g: NAND de X y Y negada
    nand U4 (R, X, nY);

    // Conexiones directas
    assign b = R;
    assign c = R;
    assign g = R;
    assign d = X;

    // Segmentos e y f permanentemente encendidos
    assign e = 1'b0;
    assign f = 1'b0;

endmodule