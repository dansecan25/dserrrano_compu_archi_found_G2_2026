
`timescale 1ns/1ps

module tb_fsm_controller;

    localparam integer N = 4;

    // Indices de los estados one-hot.
    localparam integer I  = 0,  O  = 1,  A  = 2;
    localparam integer B  = 3,  E  = 4,  AW = 5;
    localparam integer AR = 6,  RO = 7,  AD = 8;
    localparam integer V  = 9,  VO = 10, VE = 11;
    localparam integer P  = 12, C  = 13, TS = 14;
    localparam integer TW = 15, TR = 16;

    logic clk = 0;
    logic reset = 1;

    logic normal_mode = 0;
    logic admin_mode = 0;
    logic admin_type = 0;
    logic test_request = 0;

    logic sample_pulse = 0;
    logic digit_valid = 0;
    logic opcode_valid = 0;
    logic password_ready = 0;

    logic ABRIR = 0;
    logic CERRAR = 0;
    logic [N-1:0] found = '0;
    logic [N-1:0] password_type = '0;
    logic memory_full = 0;

    logic movement_done = 0;
    logic test_running = 0;

    wire capture_reset;
    wire capture_opcode, capture_a, capture_b;
    wire register_pulse, selected_type;
    wire motor_open, motor_close, movement_active;
    wire test_start_pulse;

    wire sound_test, sound_opening, sound_closing;
    wire sound_registered, sound_valid, sound_invalid;
    wire door_open;

    integer passed = 0;
    integer errors = 0;

    // Reloj de 10 ns.
    always #5 clk = ~clk;

    fsm_controller #(.N(N)) dut (
        .clk(clk),
        .reset(reset),

        .normal_mode(normal_mode),
        .admin_mode(admin_mode),
        .admin_type(admin_type),
        .test_request(test_request),

        .sample_pulse(sample_pulse),
        .digit_valid(digit_valid),
        .opcode_valid(opcode_valid),
        .password_ready(password_ready),

        .ABRIR(ABRIR),
        .CERRAR(CERRAR),
        .found(found),
        .password_type(password_type),
        .memory_full(memory_full),

        .movement_done(movement_done),
        .test_running(test_running),

        .capture_reset(capture_reset),
        .capture_opcode(capture_opcode),
        .capture_a(capture_a),
        .capture_b(capture_b),

        .register_pulse(register_pulse),
        .selected_type(selected_type),

        .motor_open(motor_open),
        .motor_close(motor_close),
        .movement_active(movement_active),

        .test_start_pulse(test_start_pulse),

        .sound_test(sound_test),
        .sound_opening(sound_opening),
        .sound_closing(sound_closing),
        .sound_registered(sound_registered),
        .sound_valid(sound_valid),
        .sound_invalid(sound_invalid),

        .door_open(door_open)
    );

    // ==================================================
    // Tareas auxiliares
    // ==================================================

    // Espera el flanco positivo y las actualizaciones FF.
    task automatic tick;
        @(posedge clk);
        #1;
    endtask

    // Comprueba el estado one-hot completo.
    task automatic check_state(
        input integer expected,
        input string description
    );
        logic [16:0] expected_vector;
        begin
            expected_vector = 17'b1 << expected;

            if (dut.state !== expected_vector) begin
                $display("FAIL: %s", description);
                $display("  Estado actual:   %017b", dut.state);
                $display("  Estado esperado: %017b", expected_vector);
                errors = errors + 1;
            end else begin
                $display("PASS: %s", description);
                passed = passed + 1;
            end
        end
    endtask

    // Comprueba cualquier señal de un bit.
    task automatic check_bit(
        input logic actual,
        input logic expected,
        input string description
    );
        begin
            if (actual !== expected) begin
                $display("FAIL: %s | actual=%b esperado=%b",
                         description, actual, expected);
                errors = errors + 1;
            end else begin
                $display("PASS: %s", description);
                passed = passed + 1;
            end
        end
    endtask

    // Inicia una captura normal o administrativa.
    // El modo se retira al entrar a CAP_OPCODE.
    task automatic begin_capture(
        input logic administrative,
        input logic requested_type
    );
        begin
            @(negedge clk);
            normal_mode = ~administrative;
            admin_mode = administrative;
            admin_type = requested_type;

            tick();

            @(negedge clk);
            normal_mode = 0;
            admin_mode = 0;
        end
    endtask

    // Simula una ventana de captura valida.
    // Para OpCode, valid_opcode=1.
    task automatic capture_sample(
        input logic valid_opcode
    );
        begin
            @(negedge clk);
            sample_pulse = 1;
            digit_valid = 1;
            opcode_valid = valid_opcode;

            tick();

            @(negedge clk);
            sample_pulse = 0;
            digit_valid = 0;
            opcode_valid = 0;
        end
    endtask

    // Completa las tres etapas desde CAP_OPCODE.
    task automatic complete_capture;
        begin
            capture_sample(1);
            capture_sample(0);
            capture_sample(0);

            // Ahora estamos en EVALUATE.
            @(negedge clk);
            password_ready = 1;
        end
    endtask

    // Limpia los datos simulados entre escenarios.
    task automatic clean_inputs;
        begin
            @(negedge clk);

            normal_mode = 0;
            admin_mode = 0;
            admin_type = 0;
            test_request = 0;

            sample_pulse = 0;
            digit_valid = 0;
            opcode_valid = 0;
            password_ready = 0;

            ABRIR = 0;
            CERRAR = 0;
            found = '0;
            password_type = '0;
            memory_full = 0;

            movement_done = 0;
            test_running = 0;
        end
    endtask

    // ==================================================
    // Secuencia principal de pruebas
    // ==================================================

    initial begin

        $display("========================================");
        $display("TESTBENCH: FSM CONTROLLER");
        $display("========================================");

        // 1. Reset inicial.
        tick();
        check_state(I, "Reset: estado IDLE");
        check_bit(door_open, 0, "Puerta cerrada al iniciar");
        check_bit(movement_active, 0, "Motor apagado al iniciar");
        check_bit(capture_reset, 1, "Reset de captura en IDLE");

        @(negedge clk);
        reset = 0;

        // ================================================
        // PRUEBA 1: Captura y validacion de apertura
        // ================================================

        begin_capture(0, 0);
        check_state(O, "Entrada a CAP_OPCODE");

        // Sin OpCode valido no debe avanzar.
        capture_sample(0);
        check_state(O, "OpCode invalido: permanece");

        capture_sample(1);
        check_state(A, "OpCode valido: CAP_A");

        capture_sample(0);
        check_state(B, "Operando A valido: CAP_B");

        capture_sample(0);
        check_state(E, "Operando B valido: EVALUATE");

        @(negedge clk);
        password_ready = 1;
        tick();
        check_state(V, "Captura completa: VALIDATE");

        @(negedge clk);
        ABRIR = 1;
        password_ready = 0;

        tick();
        check_state(VO, "Contrasena conocida: VALID_OK");
        check_bit(sound_valid, 1, "Evento de contrasena valida");

        tick();
        check_state(P, "Comienza apertura");
        check_bit(motor_open, 1, "Orden de abrir");
        check_bit(sound_opening, 1, "Sonido continuo de abrir");
        check_bit(motor_close, 0, "No cerrar simultaneamente");

        // El motor continua hasta movement_done.
        repeat (3) tick();
        check_state(P, "Mantiene apertura sin DONE");

        @(negedge clk);
        movement_done = 1;

        tick();
        check_state(I, "Finaliza apertura");
        check_bit(door_open, 1, "Registra puerta abierta");
        check_bit(movement_active, 0, "Motor apagado al terminar");
        check_bit(sound_opening, 0, "Finaliza sonido de apertura");

        clean_inputs();

        // ================================================
        // PRUEBA 2: Captura y cierre de puerta
        // ================================================

        begin_capture(0, 0);
        complete_capture();

        tick();
        check_state(V, "Segunda secuencia: VALIDATE");

        @(negedge clk);
        password_ready = 0;
        CERRAR = 1;

        tick();
        check_state(VO, "Contrasena de cierre valida");

        tick();
        check_state(C, "Comienza cierre");
        check_bit(motor_close, 1, "Orden de cerrar");
        check_bit(sound_closing, 1, "Sonido continuo de cierre");

        @(negedge clk);
        movement_done = 1;

        tick();
        check_state(I, "Finaliza cierre");
        check_bit(door_open, 0, "Registra puerta cerrada");

        clean_inputs();

        // ================================================
        // PRUEBA 3: Contrasena desconocida
        // ================================================

        begin_capture(0, 0);
        complete_capture();

        tick();
        check_state(V, "Contrasena desconocida: VALIDATE");

        @(negedge clk);
        password_ready = 0;
        ABRIR = 0;
        CERRAR = 0;

        tick();
        check_state(VE, "Contrasena desconocida: VALID_ERROR");
        check_bit(sound_invalid, 1, "Evento de contrasena invalida");
        check_bit(movement_active, 0, "No mueve la puerta");

        tick();
        check_state(I, "Regresa a IDLE despues del rechazo");

        clean_inputs();

        // ================================================
        // PRUEBA 4: Registrar contrasena nueva
        // ================================================

        begin_capture(1, 1);
        check_bit(selected_type, 1, "Tipo de apertura almacenado");

        complete_capture();

        tick();
        check_state(AW, "Administracion: ADMIN_WRITE");
        check_bit(register_pulse, 1, "Pulso de registro activo");

        // Nueva contrasena y espacio disponible.
        @(negedge clk);
        found = 4'b0000;
        memory_full = 0;

        tick();
        check_state(AR, "Administracion: ADMIN_RESULT");
        check_bit(register_pulse, 0, "Pulso de registro terminado");

        // Emular el cambio posterior de memoria.
        @(negedge clk);
        found = 4'b0001;
        password_type = 4'b0001;

        tick();
        check_state(RO, "Nueva contrasena: REGISTER_OK");
        check_bit(sound_registered, 1, "Sonido de registro exitoso");

        tick();
        check_state(I, "Registro finalizado");

        clean_inputs();

        // ================================================
        // PRUEBA 5: Eliminar contrasena repetida
        // ================================================

        begin_capture(1, 1);
        complete_capture();
        tick();
        check_state(AW, "Eliminacion: ADMIN_WRITE");

        @(negedge clk);
        found = 4'b0001;
        password_type = 4'b0001;

        tick();
        check_state(AR, "Eliminacion: ADMIN_RESULT");

        tick();
        check_state(AD, "Contrasena repetida: ADMIN_DONE");
        check_bit(sound_registered, 0,
                  "Eliminacion sin sonido de registro");

        tick();
        check_state(I, "Eliminacion finalizada");

        clean_inputs();

        // ================================================
        // PRUEBA 6: Memoria llena
        // ================================================

        begin_capture(1, 0);
        complete_capture();
        tick();
        check_state(AW, "Memoria llena: ADMIN_WRITE");

        @(negedge clk);
        found = 4'b0000;
        memory_full = 1;

        tick();
        check_state(AR, "Memoria llena: ADMIN_RESULT");

        tick();
        check_state(AD, "Memoria llena: ADMIN_DONE");
        check_bit(sound_invalid, 1,
                  "Notificacion de memoria llena");

        tick();
        check_state(I, "Regresa a IDLE tras memoria llena");

        clean_inputs();

        // ================================================
        // PRUEBA 7: Metodo de prueba
        // ================================================

        @(negedge clk);
        test_request = 1;

        tick();
        check_state(TS, "Solicitud de prueba: TEST_START");
        check_bit(test_start_pulse, 1, "Pulso de inicio de prueba");

        @(negedge clk);
        test_request = 0;

        tick();
        check_state(TW, "Espera confirmacion de prueba");

        repeat (2) tick();
        check_state(TW, "Mantiene espera sin RUNNING");

        @(negedge clk);
        test_running = 1;

        tick();
        check_state(TR, "Prueba confirmada: TEST_RUNNING");
        check_bit(sound_test, 1, "Sonido continuo de prueba");

        repeat (3) tick();
        check_state(TR, "Mantiene estado de prueba");

        @(negedge clk);
        test_running = 0;

        tick();
        check_state(I, "Prueba finalizada");
        check_bit(sound_test, 0, "Finaliza sonido de prueba");
        check_bit(door_open, 0, "Termina con puerta cerrada");

        clean_inputs();

        // ================================================
        // PRUEBA 8: Reset durante apertura
        // ================================================

        begin_capture(0, 0);
        complete_capture();
        tick();

        @(negedge clk);
        password_ready = 0;
        ABRIR = 1;

        tick();
        check_state(VO, "Preparar apertura para probar reset");

        tick();
        check_state(P, "Motor activo antes del reset");

        @(negedge clk);
        reset = 1;

        // Las salidas del motor se inhiben inmediatamente.
        #1;
        check_bit(motor_open, 0, "Reset inhibe motor");

        tick();
        check_state(I, "Reset regresa a IDLE");
        check_bit(door_open, 0, "Reset limpia posicion logica");

        @(negedge clk);
        reset = 0;

        // ================================================
        // Resultado final
        // ================================================

        $display("========================================");
        $display("Comprobaciones exitosas: %0d", passed);
        $display("Errores: %0d", errors);
        $display("========================================");

        if (errors == 0)
            $display("TODAS LAS PRUEBAS DE LA MEF PASARON");
        else
            $fatal(1, "La MEF presenta errores");

        $finish;
    end

endmodule
