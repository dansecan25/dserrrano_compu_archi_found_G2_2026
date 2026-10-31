
`timescale 1ns/1ps

module tb_buzzer_controller;

    logic clk = 0;
    logic reset = 1;

    logic sound_test = 0;
    logic sound_opening = 0;
    logic sound_closing = 0;

    logic sound_registered = 0;
    logic sound_valid = 0;
    logic sound_invalid = 0;

    wire buzzer_out;
    wire buzzer_busy;

    integer passed = 0;
    integer errors = 0;

    always #5 clk = ~clk;

    buzzer_controller #(
        .HALF_TEST(2),
        .HALF_OPEN(3),
        .HALF_CLOSE(4),
        .SLOT_CYCLES(4)
    ) dut (
        .clk(clk),
        .reset(reset),

        .sound_test(sound_test),
        .sound_opening(sound_opening),
        .sound_closing(sound_closing),

        .sound_registered(sound_registered),
        .sound_valid(sound_valid),
        .sound_invalid(sound_invalid),

        .buzzer_out(buzzer_out),
        .buzzer_busy(buzzer_busy)
    );

    task automatic tick;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    task automatic check_bit(
        input logic actual,
        input logic expected,
        input string description
    );
        begin
            if (actual !== expected) begin
                $display("FAIL: %s (actual=%b, esperado=%b)",
                         description, actual, expected);
                errors = errors + 1;
            end else begin
                $display("PASS: %s", description);
                passed = passed + 1;
            end
        end
    endtask

    // Emite un evento de un ciclo de reloj.
    task automatic pulse_valid;
        begin
            @(negedge clk);
            sound_valid = 1;
            tick();
            @(negedge clk);
            sound_valid = 0;
        end
    endtask

    task automatic pulse_registered;
        begin
            @(negedge clk);
            sound_registered = 1;
            tick();
            @(negedge clk);
            sound_registered = 0;
        end
    endtask

    task automatic pulse_invalid;
        begin
            @(negedge clk);
            sound_invalid = 1;
            tick();
            @(negedge clk);
            sound_invalid = 0;
        end
    endtask

    initial begin

        // ==========================================
        // 1. Reset
        // ==========================================

        tick();

        check_bit(buzzer_out, 0, "Reset: buzzer apagado");
        check_bit(buzzer_busy, 0, "Reset: sin evento activo");

        @(negedge clk);
        reset = 0;

        // ==========================================
        // 2. Contrasena valida: un pitido
        // ==========================================

        pulse_valid();

        check_bit(buzzer_busy, 1,
                  "Valida: evento almacenado");

        check_bit(dut.event_tone, 1,
                  "Valida: intervalo sonoro");

        repeat (4) tick();

        check_bit(buzzer_busy, 0,
                  "Valida: termina tras un intervalo");

        // ==========================================
        // 3. Registro: dos pitidos
        // ==========================================

        pulse_registered();

        check_bit(buzzer_busy, 1,
                  "Registro: evento almacenado");

        repeat (4) tick();

        check_bit(dut.event_tone, 0,
                  "Registro: intervalo de silencio");

        repeat (4) tick();

        check_bit(dut.event_tone, 1,
                  "Registro: segundo pitido");

        repeat (4) tick();

        check_bit(buzzer_busy, 0,
                  "Registro: finaliza correctamente");

        // ==========================================
        // 4. Invalida: tres pitidos
        // ==========================================

        pulse_invalid();

        check_bit(buzzer_busy, 1,
                  "Invalida: evento almacenado");

        repeat (4) tick();

        check_bit(dut.event_tone, 0,
                  "Invalida: primer silencio");

        repeat (4) tick();

        check_bit(dut.event_tone, 1,
                  "Invalida: segundo pitido");

        repeat (4) tick();

        check_bit(dut.event_tone, 0,
                  "Invalida: segundo silencio");

        repeat (4) tick();

        check_bit(dut.event_tone, 1,
                  "Invalida: tercer pitido");

        repeat (4) tick();

        check_bit(buzzer_busy, 0,
                  "Invalida: finaliza correctamente");

        // ==========================================
        // 5. Sonido continuo de apertura
        // ==========================================

        @(negedge clk);
        sound_opening = 1;

        repeat (4) tick();

        check_bit(dut.tone_open, 1,
                  "Apertura: tono seleccionado");

        check_bit(dut.tone_enable, 1,
                  "Apertura: generador habilitado");

        @(negedge clk);
        sound_opening = 0;
        #1;

        check_bit(buzzer_out, 0,
                  "Apertura: silencio al desactivar");

        // ==========================================
        // 6. Sonido continuo de cierre
        // ==========================================

        @(negedge clk);
        sound_closing = 1;

        repeat (5) tick();

        check_bit(dut.tone_close, 1,
                  "Cierre: tono seleccionado");

        @(negedge clk);
        sound_closing = 0;
        #1;

        check_bit(buzzer_out, 0,
                  "Cierre: silencio al desactivar");

        // ==========================================
        // 7. Modo de prueba y prioridad
        // ==========================================

        @(negedge clk);
        sound_test = 1;
        sound_opening = 1;

        repeat (3) tick();

        check_bit(dut.tone_test, 1,
                  "Prueba: tono prioritario");

        check_bit(dut.tone_open, 0,
                  "Prueba: inhibe tono de apertura");

        @(negedge clk);
        sound_valid = 1;

        tick();

        check_bit(buzzer_busy, 0,
                  "Prueba: rechaza eventos breves");

        @(negedge clk);
        sound_valid = 0;
        sound_test = 0;
        sound_opening = 0;

        #1;

        check_bit(buzzer_out, 0,
                  "Prueba: silencio al finalizar");

        // ==========================================
        // 8. Reset durante un evento
        // ==========================================

        pulse_invalid();

        check_bit(buzzer_busy, 1,
                  "Reset: evento activo previamente");

        @(negedge clk);
        reset = 1;
        #1;

        check_bit(buzzer_out, 0,
                  "Reset: salida inmediatamente inhibida");

        tick();

        check_bit(buzzer_busy, 0,
                  "Reset: evento cancelado");

        @(negedge clk);
        reset = 0;

        // ==========================================
        // Resultado
        // ==========================================

        $display("====================================");
        $display("Pruebas correctas: %0d", passed);
        $display("Errores: %0d", errors);
        $display("====================================");

        if (errors == 0)
            $display("TODAS LAS PRUEBAS DEL BUZZER PASARON");
        else
            $fatal(1, "Errores en buzzer_controller");

        $finish;
    end

endmodule
