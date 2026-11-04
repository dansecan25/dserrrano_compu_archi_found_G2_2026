// Mux AND-OR de 3 flujos. Cada bus = {ABRIR, CERRAR, VALOR[2:0]}.
// Sin ninguna seleccion la salida es 0.
module flow_mux (
    input  logic [4:0] IN_NORMAL,
    input  logic [4:0] IN_FUNC2,
    input  logic [4:0] IN_TEST,
    input  logic       SEL_NORMAL,
    input  logic       SEL_FUNC2,
    input  logic       SEL_TEST,
    output logic [4:0] OUT
);
    assign OUT = (IN_NORMAL & {5{SEL_NORMAL}})
               | (IN_FUNC2  & {5{SEL_FUNC2}})
               | (IN_TEST   & {5{SEL_TEST}});
endmodule
