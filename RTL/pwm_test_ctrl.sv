// Modo de prueba del PWM.
// Al presionar el boton (activo en bajo, se invierte aqui) con ENABLE=1:
//   fase ABRIR : VALOR = 5 (101)   fase CERRAR : VALOR = 1 (001)   luego 0.
// Dos 74HC595 en cascada (QH' -> SER) cuentan los ciclos de reloj:
// mientras RUNNING=1 el SER vale 1, asi que la salida k del registro (k=0..15)
// se enciende k+1 ciclos despues del primero: es un contador unario.
//   OPEN_TAP  : la fase ABRIR dura hasta que se enciende esta salida
//   CLOSE_TAP : la fase CERRAR dura hasta que se enciende esta salida (fin)
// Con 7 y 15 cada fase dura 8 ciclos de CLK (= 1 periodo del PWM).
// RUNNING es la bandera "prueba en curso" (0 si ENABLE=0).
// Solo compuertas + d_flipflop + sn74hc595; sin if, ?:, ciclos ni generate.
module pwm_test_ctrl (
    input  logic       CLK,
    input  logic       RST_N,
    input  logic       ENABLE,        // 1 = modo prueba seleccionado
    input  logic       BTN_N,         // boton de la FPGA, activo en bajo
    output logic       TEST_OPEN,     // fase ABRIR
    output logic       TEST_CLOSE,    // fase CERRAR
    output logic [2:0] VALOR,         // 5 abrir, 1 cerrar, 0 reposo
    output logic       RUNNING        // bandera de prueba en curso
);
    // ---- configuracion (0..15) ----
    localparam OPEN_TAP  = 7;
    localparam CLOSE_TAP = 15;
    // -------------------------------

    // boton invertido + sincronizador de 2 FF + deteccion de flanco de subida
    wire btn = ~BTN_N;
    wire s1, s1n, s2, s2n;
    d_flipflop u_sync1 (.D(btn), .CLK(CLK), .CLR_N(RST_N), .Q(s1), .QN(s1n));
    d_flipflop u_sync2 (.D(s1),  .CLK(CLK), .CLR_N(RST_N), .Q(s2), .QN(s2n));
    wire start = s1 & s2n & ENABLE;

    // bandera RUN: arranca con start, termina con la ultima salida del registro
    wire        run, runn, run_d, run_clr_n, done;
    wire [15:0] taps;
    wire        tap_open  = taps[OPEN_TAP];
    wire        tap_close = taps[CLOSE_TAP];

    assign done      = tap_close;
    assign run_d     = start | (run & ~done);
    assign run_clr_n = RST_N & ENABLE;
    d_flipflop u_run (.D(run_d), .CLK(CLK), .CLR_N(run_clr_n), .Q(run), .QN(runn));

    // contador de ciclos: 2 x 74HC595 en cascada, borrados mientras no hay prueba
    wire       nclk = ~CLK;
    wire [7:0] q1, q2;
    wire       qh1, qh2;
    sn74hc595 u_sr1 (.SER(run), .SRCLK(CLK), .SRCLR_N(run), .RCLK(nclk),
                     .OE_N(1'b0), .Q(q1), .QH_PRIME(qh1));
    sn74hc595 u_sr2 (.SER(qh1), .SRCLK(CLK), .SRCLR_N(run), .RCLK(nclk),
                     .OE_N(1'b0), .Q(q2), .QH_PRIME(qh2));
    assign taps = {q2, q1};

    // fases
    assign TEST_OPEN  = run & ~tap_open;
    assign TEST_CLOSE = run & tap_open & ~tap_close;
    assign VALOR      = {TEST_OPEN, 1'b0, TEST_OPEN | TEST_CLOSE};   // 101 / 001 / 000
    assign RUNNING    = run;
endmodule
