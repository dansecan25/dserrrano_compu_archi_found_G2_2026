// Selector de modo (interruptores activos en alto). Prioridad SW3 > SW2 > SW1.
//   SW3=1          -> SEL_TEST    (modo de prueba del PWM)
//   SW2=1, SW3=0   -> SEL_FUNC2   (reservado, funcion por definir)
//   SW1=1, SW2=SW3=0 -> SEL_NORMAL (flujo normal)
//   todos en 0     -> ningun modo (salidas en 0)
module mode_decoder (
    input  logic SW1, SW2, SW3,
    output logic SEL_NORMAL,
    output logic SEL_FUNC2,
    output logic SEL_TEST
);
    wire nSW2 = ~SW2;
    wire nSW3 = ~SW3;

    assign SEL_TEST   = SW3;
    assign SEL_FUNC2  = SW2 & nSW3;
    assign SEL_NORMAL = SW1 & nSW2 & nSW3;
endmodule
