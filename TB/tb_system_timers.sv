
`timescale 1ns/1ps

module tb_system_timers;

    logic clk = 0;
    logic reset = 1;

    logic movement_enable = 0;
    logic sample_enable = 0;

    wire movement_done;
    wire sample_pulse;

    integer passed = 0;
    integer errors = 0;

    always #5 clk = ~clk;

    movement_timer #(
        .MOVEMENT_CYCLES(4)
    ) u_movement (
        .clk(clk),
        .reset(reset),
        .enable(movement_enable),
        .done(movement_done)
    );

    sample_timer #(
        .SAMPLE_CYCLES(3)
    ) u_sample (
        .clk(clk),
        .reset(reset),
        .enable(sample_enable),
        .sample_pulse(sample_pulse)
    );

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

    task automatic tick;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    initial begin

        // Inicializacion.
        tick();

        check_bit(movement_done, 0,
                  "Movimiento: reset inicial");
        check_bit(sample_pulse, 0,
                  "Muestreo: reset inicial");

        // ==========================================
        // Movimiento: cuatro ciclos
        // ==========================================

        @(negedge clk);
        reset = 0;
        movement_enable = 1;

        tick(); // contador = 1
        check_bit(movement_done, 0,
                  "Movimiento: primer ciclo");

        tick(); // contador = 2
        check_bit(movement_done, 0,
                  "Movimiento: segundo ciclo");

        tick(); // contador = 3
        check_bit(movement_done, 1,
                  "Movimiento: intervalo alcanzado");

        tick(); // reinicio del contador
        check_bit(movement_done, 0,
                  "Movimiento: pulso finalizado");

        // En uso normal, la MEF desactiva enable
        // cuando consume movement_done.
        @(negedge clk);
        movement_enable = 0;

        tick();

        check_bit(movement_done, 0,
                  "Movimiento: reposo");

        // Nueva operacion.
        @(negedge clk);
        movement_enable = 1;

        tick();
        tick();
        tick();

        check_bit(movement_done, 1,
                  "Movimiento: segunda operacion");

        @(negedge clk);
        movement_enable = 0;

        tick();

        // ==========================================
        // Muestreo: tres ciclos periodicos
        // ==========================================

        @(negedge clk);
        sample_enable = 1;

        tick(); // contador = 1
        check_bit(sample_pulse, 0,
                  "Muestreo: primer ciclo");

        tick(); // contador = 2
        check_bit(sample_pulse, 1,
                  "Muestreo: primer pulso");

        tick(); // contador = 0
        check_bit(sample_pulse, 0,
                  "Muestreo: pulso dura un ciclo");

        tick(); // contador = 1
        tick(); // contador = 2

        check_bit(sample_pulse, 1,
                  "Muestreo: segundo pulso periodico");

        // Desactivar antes de otro ciclo.
			@(negedge clk);
			sample_enable = 0;

			// Permitir que se actualice la logica combinacional.
			#1;

			check_bit(sample_pulse, 0,
						 "Muestreo: deshabilitado");

        tick();

        // Comprobar reinicio del periodo.
        @(negedge clk);
        sample_enable = 1;

        tick();
        check_bit(sample_pulse, 0,
                  "Muestreo: reinicio primer ciclo");

        tick();
        check_bit(sample_pulse, 1,
                  "Muestreo: periodo reiniciado");

        // ==========================================
        // Reset durante temporizacion
        // ==========================================

        @(negedge clk);
        reset = 1;

        #1;
        check_bit(movement_done, 0,
                  "Reset inhibe movement_done");
        check_bit(sample_pulse, 0,
                  "Reset inhibe sample_pulse");

        tick();

        check_bit(u_movement.count == 0, 1,
                  "Reset limpia contador movimiento");

        check_bit(u_sample.count == 0, 1,
                  "Reset limpia contador muestreo");

        // ==========================================
        // Resultado
        // ==========================================

        $display("====================================");
        $display("Pruebas correctas: %0d", passed);
        $display("Errores: %0d", errors);
        $display("====================================");

        if (errors == 0)
            $display("TODAS LAS PRUEBAS PASARON");
        else
            $fatal(1, "Errores en temporizadores");

        $finish;
    end

endmodule
