// Dedos -> decoder de dedos (Y) -> SR latches (solo hay salida si CLK=1) -> password_decoder (ABRIR / CERRAR)
// ABRIR|CERRAR le entra al 74HC595 (SER). Cuando llega a la segunda salida, resetea los 5 latches Y, limpiando ABRIR/CERRAR.
//
//  RELOJ: CLK_50 es el reloj de 50 MHz de la FPGA. clock_divider genera clk_slow
//  (1.5 s en alto, 1.5 s en bajo) y TODO el diseno funciona con clk_slow.
//  SRCLK = clk_slow, RCLK = ~clk_slow
//  RST_N (activo en bajo): global reset (mientras esta activo clk_slow = 0; despues
//  de soltarlo hace falta un ciclo de clk_slow para que los registros carguen ceros).
//
// Timeline (t0 = rising edge where the code is completed):
//  t0 high: ABRIR/CERRAR = 1   t1: QA=1   t1 falling: Q[0]=1
//  t2: QB=1                    t2 falling: Q[1]=1 -> latches reset -> output 0
//
// MODOS (interruptores activos en alto, prioridad SW3 > SW2 > SW1):
//   SW1 = flujo normal (el de arriba)
//   SW2 = reservado (funcion por definir, por ahora todo en 0)
//   SW3 = modo prueba del PWM: al presionar el boton se envia 5 (abrir) y luego 1 (cerrar)
//   El valor 0..7 va al PWM y al display de 7 segmentos.
//   En el flujo normal: ABRIR -> 5, CERRAR -> 1, reposo -> 0.
module top #(
    parameter CLK_DIV_HALF = 75_000_000     // ciclos de 50 MHz por medio periodo (1.5 s)
) (
    input  logic S1, S2, S3, S4, S5,
    input  logic CLK_50,                    // reloj de 50 MHz de la FPGA
    input  logic RST_N,

    // seleccion de modo
    input  logic SW1,
    input  logic SW2,
    input  logic SW3,
    input  logic BTN_TEST_N,        // boton de la FPGA (activo en bajo)

    output wire  PWM_OUT,
    output wire  TEST_RUNNING,      // bandera: modo prueba en ejecucion

    output wire SEG_A,
    output wire SEG_B,
    output wire SEG_C,
    output wire SEG_D,
    output wire SEG_E,
    output wire SEG_F,
    output wire SEG_G,

    output wire LED_CLK,
    output wire LED_ABRIR,
    output wire LED_CERRAR,

    //debugging
    output wire LED_Y1,
    output wire LED_Y2,
    output wire LED_Y3,
    output wire LED_Y4,
    output wire LED_Y5
);
    // ---------------- reloj lento (1.5 s alto / 1.5 s bajo) ----------------
    wire clk_slow;

    clock_divider #(.HALF_PERIOD(CLK_DIV_HALF)) u_div (
        .CLK(CLK_50), .RST_N(RST_N), .CLK_OUT(clk_slow)
    );

    // ---------------- flujo normal ----------------
    wire y1, y2, y3, y4, y5;
    wire e1, e2, e3, e4, e5;
    wire abrir_w, cerrar_w, contra_detectada;
    wire nclk, nrst, y_reset;
    wire [7:0] sr_q;
    wire       sr_qh;
	 wire ABRIR;
    wire CERRAR;

    finger_decoder u_fingers (
        .S1(S1), .S2(S2), .S3(S3), .S4(S4), .S5(~S5),
        .Y1(y1), .Y2(y2), .Y3(y3), .Y4(y4), .Y5(y5)
    );

    //Retenedores del número de los dedos
    y_latch_bank u_ylatch (
        .Y1(y1), .Y2(y2), .Y3(y3), .Y4(y4), .Y5(y5),
        .CLK(clk_slow), .RESET(y_reset),
        .E1(e1), .E2(e2), .E3(e3), .E4(e4), .E5(e5)
    );

    //decoder de la contraseña
    password_decoder u_pass (
        .E1(e1), .E2(e2), .E3(e3), .E4(e4), .E5(e5),
        .ABRIR(abrir_w), .CERRAR(cerrar_w)
    );

    assign contra_detectada = abrir_w | cerrar_w;
    assign nclk = ~clk_slow;

    //shift register para mantener los bits una cantidad de ciclos
    sn74hc595 u_sr (
        .SER(contra_detectada), .SRCLK(clk_slow), .SRCLR_N(RST_N),
        .RCLK(nclk), .OE_N(1'b0), .Q(sr_q), .QH_PRIME(sr_qh)
    );

    assign nrst    = ~RST_N;
    assign y_reset = sr_q[1] | nrst;

    // valor normalizado 0..7 del flujo normal: ABRIR=5 (101), CERRAR=1 (001), reposo=0
    wire [2:0] valor_normal = {abrir_w, 1'b0, abrir_w | cerrar_w};

    // ---------------- modo prueba del PWM ----------------
    wire       sel_normal, sel_func2, sel_test;
    wire       t_abrir, t_cerrar, t_running;
    wire [2:0] valor_test;

    mode_decoder u_mode (
        .SW1(SW1), .SW2(SW2), .SW3(SW3),
        .SEL_NORMAL(sel_normal), .SEL_FUNC2(sel_func2), .SEL_TEST(sel_test)
    );

    pwm_test_ctrl u_test (
        .CLK(clk_slow), .RST_N(RST_N), .ENABLE(sel_test), .BTN_N(BTN_TEST_N),
        .TEST_OPEN(t_abrir), .TEST_CLOSE(t_cerrar),
        .VALOR(valor_test), .RUNNING(t_running)
    );

    // ---------------- mux de flujos: {ABRIR, CERRAR, VALOR[2:0]} ----------------
    wire [4:0] mux_out;
    flow_mux u_mux (
        .IN_NORMAL({abrir_w, cerrar_w, valor_normal}),
        .IN_FUNC2 (5'b00000),                          // por definir
        .IN_TEST  ({t_abrir, t_cerrar, valor_test}),
        .SEL_NORMAL(sel_normal), .SEL_FUNC2(sel_func2), .SEL_TEST(sel_test),
        .OUT(mux_out)
    );

    wire [2:0] valor_sel = mux_out[2:0];

    assign ABRIR  = mux_out[4];
    assign CERRAR = mux_out[3];

    // ---------------- PWM ----------------
    pwm u_pwm (
        .CLK(clk_slow), .RST_N(RST_N), .VALOR(valor_sel), .PWM_OUT(PWM_OUT)
    );

    // Display de siete segmentos, anodo comun: muestra el valor 0..7
    display_7seg u_display (
        .VALOR(valor_sel),
        .a(SEG_A),
        .b(SEG_B),
        .c(SEG_C),
        .d(SEG_D),
        .e(SEG_E),
        .f(SEG_F),
        .g(SEG_G)
    );

    assign TEST_RUNNING = t_running;

    assign LED_CLK    = clk_slow;
    assign LED_ABRIR  = ABRIR;
    assign LED_CERRAR = CERRAR;

    assign LED_Y1 = e1;
    assign LED_Y2 = e2;
    assign LED_Y3 = e3;
    assign LED_Y4 = e4;
    assign LED_Y5 = e5;
endmodule
