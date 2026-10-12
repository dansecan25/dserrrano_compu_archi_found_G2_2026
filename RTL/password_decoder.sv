// Password decoder.
//   ABRIR  = ~E1 & ~E2 & ~E3 &  E4 &  E5
//   CERRAR = ~E1 &  E2 &  E3 &  E4 & ~E5
// Structural: only AND / NOT.
module password_decoder (
    input  logic E1, E2, E3, E4, E5,
    output logic ABRIR,
    output logic CERRAR
);
    wire nE1 = ~E1;
    wire nE2 = ~E2;
    wire nE3 = ~E3;
    wire nE5 = ~E5;

    assign ABRIR  = nE1 & nE2 & E3 & E4 & E5;
    assign CERRAR = nE1 & E2  & E3  & E4 & nE5;
endmodule
