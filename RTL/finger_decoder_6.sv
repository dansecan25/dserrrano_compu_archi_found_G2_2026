
/*
 * Modulo: finger_decoder_6
 *
 * Descripcion:
 *   Reconoce seis valores (0 a 5) mediante
 *   seis sensores digitales.
 *
 *   S0 representa explicitamente el valor cero.
 *   S1..S5 utilizan codificacion termometrica.
 *
 *   Si no hay sensores activos o el patron es
 *   incorrecto, ninguna salida Y se activa.
 */

module finger_decoder_6 (
    input  logic S0, S1, S2, S3, S4, S5,

    output logic Y0, Y1, Y2, Y3, Y4, Y5
);

    // Complementos de las entradas.
    wire nS0, nS1, nS2, nS3, nS4, nS5;

    assign nS0 = ~S0;
    assign nS1 = ~S1;
    assign nS2 = ~S2;
    assign nS3 = ~S3;
    assign nS4 = ~S4;
    assign nS5 = ~S5;

    // Cero explicito: solamente S0 activo.
    assign Y0 = S0  & nS1 & nS2 & nS3 & nS4 & nS5;

    // Valores de 1 a 5: S0 debe permanecer inactivo.
    assign Y1 = nS0 & S1  & nS2 & nS3 & nS4 & nS5;
    assign Y2 = nS0 & S1  & S2  & nS3 & nS4 & nS5;
    assign Y3 = nS0 & S1  & S2  & S3  & nS4 & nS5;
    assign Y4 = nS0 & S1  & S2  & S3  & S4  & nS5;
    assign Y5 = nS0 & S1  & S2  & S3  & S4  & S5;

endmodule
