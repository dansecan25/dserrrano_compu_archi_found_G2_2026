// Dedos -> decoder de dedos (Y) -> SR latches (solo hay salida si CLK=1) -> password_decoder (ABRIR / CERRAR)
// ABRIR|CERRAR le entra al 74HC595 (SER). Cuando llega a la segunda salida, resetea los 5 latches Y, limpiando ABRIR/CERRAR.
//
//  SRCLK = CLK, RCLK = ~CLK 
//  RST_N (activo en bajo): global reset.
//
// Timeline (t0 = rising edge where the code is completed):
//  t0 high: ABRIR/CERRAR = 1   t1: QA=1   t1 falling: Q[0]=1
//  t2: QB=1                    t2 falling: Q[1]=1 -> latches reset -> output 0
module top (
    input  logic S1, S2, S3, S4, S5,
    input  logic CLK,
    input  logic RST_N,
    output logic ABRIR,
    output logic CERRAR
);
    wire y1, y2, y3, y4, y5;
    wire e1, e2, e3, e4, e5;
    wire abrir_w, cerrar_w, detect;
    wire nclk, nrst, y_reset;
    wire [7:0] sr_q;
    wire       sr_qh;

    finger_decoder u_fingers (
        .S1(S1), .S2(S2), .S3(S3), .S4(S4), .S5(S5),
        .Y1(y1), .Y2(y2), .Y3(y3), .Y4(y4), .Y5(y5)
    );
	 
	 //Retenedores del número de los dedos
    y_latch_bank u_ylatch (
        .Y1(y1), .Y2(y2), .Y3(y3), .Y4(y4), .Y5(y5),
        .CLK(CLK), .RESET(y_reset),
        .E1(e1), .E2(e2), .E3(e3), .E4(e4), .E5(e5)
    );
	 
	 //decoder de la contraseña Abrir=01110, Cerrar=00111
    password_decoder u_pass (
        .E1(e1), .E2(e2), .E3(e3), .E4(e4), .E5(e5),
        .ABRIR(abrir_w), .CERRAR(cerrar_w)
    );

    assign contra_detectada = abrir_w | cerrar_w;
    assign nclk   = ~CLK;
	
	//shift register para mantener los bits una cantidad de ciclos
    sn74hc595 u_sr (
        .SER(contra_detectada), .SRCLK(CLK), .SRCLR_N(RST_N),
        .RCLK(nclk), .OE_N(1'b0), .Q(sr_q), .QH_PRIME(sr_qh)
    );

    assign nrst    = ~RST_N;
    assign y_reset = sr_q[1] | nrst;

    assign ABRIR  = abrir_w;
    assign CERRAR = cerrar_w;
endmodule
