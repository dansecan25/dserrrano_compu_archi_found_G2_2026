/*
 * Integracion MEF + captura + memoria + ALU + PWM + prueba + buzzer.
 * Reloj de control: CLK_50.
 * SW1: normal; SW2: administracion; SW3: prueba (prioridad SW3>SW2>SW1).
 * SW_TYPE: tipo de contrasena administrada (1=abrir, 0=cerrar).
 * BTN_TEST_N: solicitud de prueba, activo en bajo.
 * S0: cero explicito; S1..S5: patrones termometricos.
 * RST_N: reset general, activo en bajo.
 *
 * Parametros pequenos aceleran el TB; valores de produccion por defecto.
 * PWM_CLK_HALF=1563 produce f_PWM ~ 2 kHz (50MHz/(2*1563*8)).
 * TEST_CLK_HALF=3_125_000 produce f_TEST=8Hz; 8 ciclos/fase ~1s.
 */
module top #(
    parameter integer N_PASSWORDS       = 10,
    parameter integer SAMPLE_CYCLES     = 100_000_000,
    parameter integer MOVEMENT_CYCLES   = 50_000_000,
    parameter integer PWM_CLK_HALF      = 1563,
    parameter integer TEST_CLK_HALF     = 3_125_000,
    parameter integer BUZZ_HALF_TEST    = 6250,
    parameter integer BUZZ_HALF_OPEN    = 7143,
    parameter integer BUZZ_HALF_CLOSE   = 5556,
    parameter integer BUZZ_SLOT_CYCLES  = 5_000_000
)(
    input  logic S0, S1, S2, S3, S4, S5,
    input  logic CLK_50,
    input  logic RST_N,
    input  logic SW1, SW2, SW3,
    input  logic SW_TYPE,
    input  logic BTN_TEST_N,

    output wire PWM_OUT,
    output wire MOTOR_OPEN,
    output wire MOTOR_CLOSE,
    output wire BUZZER_OUT,
    output wire TEST_RUNNING,

    output wire SEG_A, SEG_B, SEG_C, SEG_D, SEG_E, SEG_F, SEG_G,
    output wire LED_CLK, LED_ABRIR, LED_CERRAR,
    output wire LED_Y0, LED_Y1, LED_Y2, LED_Y3, LED_Y4, LED_Y5
);
    wire reset = ~RST_N;

    // Modo: prioridad SW3 > SW2 > SW1.
    wire sel_test, sel_admin, sel_normal;
    assign sel_test   = SW3;
    assign sel_admin  = SW2 & ~SW3;
    assign sel_normal = SW1 & ~SW2 & ~SW3;

    // Sensores -> one-hot -> digito y validez.
    wire Y0,Y1,Y2,Y3,Y4,Y5;
    wire [2:0] digit_value;
    wire digit_valid, opcode_valid;

    finger_decoder_6 u_decoder (
        .S0(S0),.S1(S1),.S2(S2),.S3(S3),.S4(S4),.S5(S5),
        .Y0(Y0),.Y1(Y1),.Y2(Y2),.Y3(Y3),.Y4(Y4),.Y5(Y5)
    );
    finger_encoder_3 u_encoder (
        .Y0(Y0),.Y1(Y1),.Y2(Y2),.Y3(Y3),.Y4(Y4),.Y5(Y5),
        .digit_value(digit_value),
        .digit_valid(digit_valid),.opcode_valid(opcode_valid)
    );

    // Temporizacion y control de captura.
    wire capture_reset, capture_opcode, capture_a, capture_b;
    wire capture_active, sample_pulse;
    wire [2:0] opcode, operand_a, operand_b;
    wire [8:0] password_out;
    wire password_ready;

    alu_input_capture u_capture (
        .clk(CLK_50),.reset(capture_reset),
        .digit_value(digit_value),.digit_valid(digit_valid),
        .opcode_valid(opcode_valid),
        .capture_opcode(capture_opcode),.capture_a(capture_a),
        .capture_b(capture_b),
        .opcode(opcode),.operand_a(operand_a),.operand_b(operand_b),
        .password_out(password_out),.password_ready(password_ready)
    );

    // No modificar sample_timer: generador de pulso, no reloj de FF.
    sample_timer #(.SAMPLE_CYCLES(SAMPLE_CYCLES)) u_sample (
        .clk(CLK_50),.reset(reset),.enable(capture_active),
        .sample_pulse(sample_pulse)
    );

    // Banco de contrasenas y comparador (realimentacion registrada).
    wire [9*N_PASSWORDS-1:0] stored_passwords;
    wire [N_PASSWORDS-1:0] valid, password_type, found;
    wire memory_full, pass_abrir, pass_cerrar;
    wire register_pulse, selected_type;

    password_comparator #(.N(N_PASSWORDS)) u_comparator (
        .password_in(password_out),
        .stored_passwords(stored_passwords),
        .valid(valid),.password_type(password_type),
        .ABRIR(pass_abrir),.CERRAR(pass_cerrar),.found(found)
    );
    password_memory #(.N(N_PASSWORDS)) u_memory (
        .clk(CLK_50),.clear(reset),.register_pulse(register_pulse),
        .password_in(password_out),.type_in(selected_type),.found(found),
        .stored_passwords(stored_passwords),.valid(valid),
        .password_type(password_type),.memory_full(memory_full)
    );

    // ALU: los operandos de 3 bits se extienden con ceros a 6 bits.
    wire [2:0] alu_valor;
    alu u_alu (
        .A({3'b000,operand_a}),.B({3'b000,operand_b}),
        .S(opcode),.VALOR(alu_valor)
    );

    // Temporizador de movimiento normal.
    wire movement_active, movement_done;
    wire normal_open, normal_close;
    movement_timer #(.MOVEMENT_CYCLES(MOVEMENT_CYCLES)) u_movement (
        .clk(CLK_50),.reset(reset),.enable(movement_active),
        .done(movement_done)
    );

    // Modo de prueba original. Solo se adapta el boton de arranque:
    // la solicitud permanece activa hasta que RUNNING se confirma.
    // El controlador de prueba opera sobre un reloj independiente de 8 Hz.
    wire clk_test, clk_pwm;
    clock_divider #(.HALF_PERIOD(TEST_CLK_HALF)) u_test_clk (
        .CLK(CLK_50),.RST_N(RST_N),.CLK_OUT(clk_test)
    );
    clock_divider #(.HALF_PERIOD(PWM_CLK_HALF)) u_pwm_clk (
        .CLK(CLK_50),.RST_N(RST_N),.CLK_OUT(clk_pwm)
    );

    wire test_start_pulse, t_abrir, t_cerrar;
    wire [2:0] valor_test;
    wire t_running_raw, t_running;
    logic test_command;
    wire test_command_next;
    logic test_sync1, test_sync2;
    wire test_enable;

    // Retener peticion para que el dominio lento pueda verla.
    assign test_command_next = ~reset &
        (test_start_pulse | (test_command & ~t_running));
    always_ff @(posedge CLK_50) begin
        test_command <= test_command_next;
        test_sync1 <= ~reset & t_running_raw;
        test_sync2 <= ~reset & test_sync1;
    end
    assign t_running = test_sync2;
    assign test_enable = sel_test | test_command | t_running;

    pwm_test_ctrl u_test (
        .CLK(clk_test),.RST_N(RST_N),.ENABLE(test_enable),
        .BTN_N(~test_command),
        .TEST_OPEN(t_abrir),.TEST_CLOSE(t_cerrar),
        .VALOR(valor_test),.RUNNING(t_running_raw)
    );

    // MEF principal. Se requiere agregar capture_active a fsm_controller.
    wire sound_test, sound_opening, sound_closing;
    wire sound_registered, sound_valid, sound_invalid;
    wire door_open;
    fsm_controller #(.N(N_PASSWORDS)) u_fsm (
        .clk(CLK_50),.reset(reset),
        .normal_mode(sel_normal),.admin_mode(sel_admin),
        .admin_type(SW_TYPE),
        .test_request(sel_test & ~BTN_TEST_N),
        .sample_pulse(sample_pulse),
        .digit_valid(digit_valid),.opcode_valid(opcode_valid),
        .password_ready(password_ready),
        .ABRIR(pass_abrir),.CERRAR(pass_cerrar),
        .found(found),.password_type(password_type),
        .memory_full(memory_full),
        .movement_done(movement_done),.test_running(t_running),
        .capture_reset(capture_reset),
        .capture_opcode(capture_opcode),.capture_a(capture_a),
        .capture_b(capture_b),.capture_active(capture_active),
        .register_pulse(register_pulse),.selected_type(selected_type),
        .motor_open(normal_open),.motor_close(normal_close),
        .movement_active(movement_active),
        .test_start_pulse(test_start_pulse),
        .sound_test(sound_test),.sound_opening(sound_opening),
        .sound_closing(sound_closing),
        .sound_registered(sound_registered),
        .sound_valid(sound_valid),.sound_invalid(sound_invalid),
        .door_open(door_open)
    );

    // El controlador de prueba selecciona su propio VALOR.
    // Normal usa resultado ALU solo mientras mueve la puerta.
    wire [2:0] valor_normal, valor_selected;
    wire test_priority;
    wire motor_open_i, motor_close_i, motor_any;
    assign test_priority = t_running | test_command;
    assign motor_open_i  = ~reset & ((test_priority & t_abrir) |
                           (~test_priority & normal_open));
    assign motor_close_i = ~reset & ((test_priority & t_cerrar) |
                           (~test_priority & normal_close));
    assign motor_any = motor_open_i | motor_close_i;
    assign valor_normal = alu_valor & {3{movement_active}};
    assign valor_selected =
        (valor_test & {3{test_priority}}) |
        (valor_normal & {3{~test_priority}});

    wire pwm_raw;
    pwm u_pwm (
        .CLK(clk_pwm),.RST_N(RST_N),
        .VALOR(valor_selected),.PWM_OUT(pwm_raw)
    );
    assign PWM_OUT = pwm_raw & motor_any & ~reset;
    assign MOTOR_OPEN  = motor_open_i;
    assign MOTOR_CLOSE = motor_close_i;

    // Buzzer: genera audio, MEF solo emite solicitudes.
    wire buzzer_busy;
    buzzer_controller #(
        .HALF_TEST(BUZZ_HALF_TEST),
        .HALF_OPEN(BUZZ_HALF_OPEN),
        .HALF_CLOSE(BUZZ_HALF_CLOSE),
        .SLOT_CYCLES(BUZZ_SLOT_CYCLES)
    ) u_buzzer (
        .clk(CLK_50),.reset(reset),
        .sound_test(sound_test),
        .sound_opening(sound_opening),
        .sound_closing(sound_closing),
        .sound_registered(sound_registered),
        .sound_valid(sound_valid),
        .sound_invalid(sound_invalid),
        .buzzer_out(BUZZER_OUT),.buzzer_busy(buzzer_busy)
    );

    display_7seg u_display (
        .VALOR(valor_selected),
        .a(SEG_A),.b(SEG_B),.c(SEG_C),.d(SEG_D),
        .e(SEG_E),.f(SEG_F),.g(SEG_G)
    );

    assign TEST_RUNNING = t_running;
    assign LED_CLK = clk_test;
    assign LED_ABRIR  = MOTOR_OPEN;
    assign LED_CERRAR = MOTOR_CLOSE;
    assign LED_Y0=Y0; assign LED_Y1=Y1; assign LED_Y2=Y2;
    assign LED_Y3=Y3; assign LED_Y4=Y4; assign LED_Y5=Y5;
endmodule
