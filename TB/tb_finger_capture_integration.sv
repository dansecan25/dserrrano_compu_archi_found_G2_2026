
`timescale 1ns/1ps

/*
 * Modulo: tb_finger_capture_integration
 *
 * Descripcion:
 *   Prueba integrada del sistema de entrada:
 *
 *   Sensores (S0..S5)
 *       -> finger_decoder_6
 *       -> finger_encoder_3
 *       -> alu_input_capture
 *
 *   Verifica captura de OpCode, A y B, formacion de
 *   contrasena, entradas invalidas, pausas y reset.
 *
 *   Los pulsos de captura se simulan desde el TB.
 *   Posteriormente seran generados por la MEF.
 *
 * Archivo exclusivo para simulacion.
 */

module tb_finger_capture_integration;

    logic clk = 1'b0;
    logic reset = 1'b0;

    // Orden: {S0, S1, S2, S3, S4, S5}.
    logic [5:0] sensors = 6'b000000;

    logic capture_opcode = 1'b0;
    logic capture_a = 1'b0;
    logic capture_b = 1'b0;

    wire Y0, Y1, Y2, Y3, Y4, Y5;

    wire [2:0] digit_value;
    wire digit_valid;
    wire opcode_valid;

    wire [2:0] opcode;
    wire [2:0] operand_a;
    wire [2:0] operand_b;

    wire [8:0] password_out;
    wire password_ready;

    integer errors = 0;
    integer passed = 0;

    // Reloj de periodo 10 ns.
    always #5 clk = ~clk;

    // ==================================================
    // Decodificador de los seis sensores
    // ==================================================

    finger_decoder_6 decoder_dut (
        .S0(sensors[5]),
        .S1(sensors[4]),
        .S2(sensors[3]),
        .S3(sensors[2]),
        .S4(sensors[1]),
        .S5(sensors[0]),

        .Y0(Y0),
        .Y1(Y1),
        .Y2(Y2),
        .Y3(Y3),
        .Y4(Y4),
        .Y5(Y5)
    );

    // ==================================================
    // Codificador a tres bits
    // ==================================================

    finger_encoder_3 encoder_dut (
        .Y0(Y0),
        .Y1(Y1),
        .Y2(Y2),
        .Y3(Y3),
        .Y4(Y4),
        .Y5(Y5),

        .digit_value(digit_value),
        .digit_valid(digit_valid),
        .opcode_valid(opcode_valid)
    );

    // ==================================================
    // Registros de captura
    // ==================================================

    alu_input_capture capture_dut (
        .clk(clk),
        .reset(reset),

        .digit_value(digit_value),
        .digit_valid(digit_valid),
        .opcode_valid(opcode_valid),

        .capture_opcode(capture_opcode),
        .capture_a(capture_a),
        .capture_b(capture_b),

        .opcode(opcode),
        .operand_a(operand_a),
        .operand_b(operand_b),

        .password_out(password_out),
        .password_ready(password_ready)
    );

    // ==================================================
    // Tareas auxiliares del testbench
    // ==================================================

    // Comprueba registros, contrasena y estado completo.
    task automatic check_state(
        input logic [2:0] expected_op,
        input logic [2:0] expected_a,
        input logic [2:0] expected_b,
        input logic expected_ready,
        input string test_name
    );
        begin
            #1;

            if (opcode !== expected_op ||
                operand_a !== expected_a ||
                operand_b !== expected_b ||
                password_ready !== expected_ready ||
                password_out !==
                    {expected_op, expected_a, expected_b}) begin

                $error("FALLO: %s", test_name);

                $display(
                    "Actual: OP=%b A=%b B=%b PASS=%b READY=%b",
                    opcode, operand_a, operand_b,
                    password_out, password_ready
                );

                errors = errors + 1;

            end else begin
                $display("PASS: %s", test_name);
                passed = passed + 1;
            end
        end
    endtask

    // Prepara las entradas y las mantiene hasta el
    // siguiente flanco positivo del reloj.
    task automatic apply_capture(
        input logic [5:0] sensor_pattern,
        input logic cap_op,
        input logic cap_a,
        input logic cap_b
    );
        begin
            @(negedge clk);

            sensors = sensor_pattern;
            capture_opcode = cap_op;
            capture_a = cap_a;
            capture_b = cap_b;

            @(posedge clk);
            #1;

            @(negedge clk);

            capture_opcode = 1'b0;
            capture_a = 1'b0;
            capture_b = 1'b0;
        end
    endtask

    // Reinicia los registros sin modificar los sensores.
    task automatic reset_capture;
        begin
            @(negedge clk);
            reset = 1'b1;

            @(posedge clk);
            #1;

            @(negedge clk);
            reset = 1'b0;
        end
    endtask

    // ==================================================
    // Pruebas
    // ==================================================

    initial begin

        // 1. Reset inicial.
        reset_capture();

        check_state(3'd0, 3'd0, 3'd0, 1'b0,
                    "Reset inicial");

        // ------------------------------------------------
        // Secuencia: OpCode 2, A 3, B 5
        // ------------------------------------------------

        // 2. Capturar OpCode 2 (multiplicacion).
        apply_capture(6'b011000, 1'b1, 1'b0, 1'b0);

        check_state(3'd2, 3'd0, 3'd0, 1'b0,
                    "Captura OpCode 2 desde sensores");

        // 3. Capturar A = 3.
        apply_capture(6'b011100, 1'b0, 1'b1, 1'b0);

        check_state(3'd2, 3'd3, 3'd0, 1'b0,
                    "Captura A = 3 desde sensores");

        // 4. Capturar B = 5.
        apply_capture(6'b011111, 1'b0, 1'b0, 1'b1);

        check_state(3'd2, 3'd3, 3'd5, 1'b1,
                    "Captura B = 5 y completa secuencia");

        // 5. Cambiar los sensores sin habilitacion.
        @(negedge clk);
        sensors = 6'b011110;

        repeat (3) @(posedge clk);

        check_state(3'd2, 3'd3, 3'd5, 1'b1,
                    "Conserva datos sin pulso de captura");

        // ------------------------------------------------
        // Entrada invalida y ausencia de sensores
        // ------------------------------------------------

        reset_capture();

        // 6. Ausencia de sensores: no debe capturar.
        apply_capture(6'b000000, 1'b1, 1'b0, 1'b0);

        check_state(3'd0, 3'd0, 3'd0, 1'b0,
                    "No captura ausencia de entrada");

        // 7. Patron contradictorio del cero y uno.
        apply_capture(6'b110000, 1'b1, 1'b0, 1'b0);

        check_state(3'd0, 3'd0, 3'd0, 1'b0,
                    "Rechaza patron contradictorio");

        // 8. OpCode 5: reconocido como digito,
        // pero invalido como operacion de ALU.
        apply_capture(6'b011111, 1'b1, 1'b0, 1'b0);

        check_state(3'd0, 3'd0, 3'd0, 1'b0,
                    "Rechaza OpCode 5");

        // ------------------------------------------------
        // Secuencia con ceros explicitos y pausas
        // ------------------------------------------------

        // 9. Cero explicito como OpCode (suma).
        apply_capture(6'b100000, 1'b1, 1'b0, 1'b0);

        check_state(3'd0, 3'd0, 3'd0, 1'b0,
                    "Acepta cero explicito como OpCode");

        // 10. Pausa sin sensores durante captura de A.
        apply_capture(6'b000000, 1'b0, 1'b1, 1'b0);

        check_state(3'd0, 3'd0, 3'd0, 1'b0,
                    "Pausa no completa operando A");

        // 11. Cero explicito como A.
        apply_capture(6'b100000, 1'b0, 1'b1, 1'b0);

        check_state(3'd0, 3'd0, 3'd0, 1'b0,
                    "Acepta cero explicito como A");

        // 12. B = 4.
        apply_capture(6'b011110, 1'b0, 1'b0, 1'b1);

        check_state(3'd0, 3'd0, 3'd4, 1'b1,
                    "Completa contrasena 004");

        // 13. Entrada invalida con B ya almacenado.
        apply_capture(6'b010100, 1'b0, 1'b0, 1'b1);

        check_state(3'd0, 3'd0, 3'd4, 1'b1,
                    "Patron invalido no sobrescribe B");

        // ------------------------------------------------
        // Reset y nueva captura
        // ------------------------------------------------

        // 14. Reset despues de completar.
        reset_capture();

        check_state(3'd0, 3'd0, 3'd0, 1'b0,
                    "Reset limpia captura completa");

        // 15. Nuevo OpCode 4 (rotacion derecha).
        apply_capture(6'b011110, 1'b1, 1'b0, 1'b0);

        check_state(3'd4, 3'd0, 3'd0, 1'b0,
                    "Nueva captura de OpCode 4");

        // ==================================================
        // Resultado final
        // ==================================================

        $display("====================================");
        $display("Pruebas correctas: %0d de 15", passed);
        $display("Errores: %0d", errors);
        $display("====================================");

        if (errors == 0) begin
            $display("TODAS LAS PRUEBAS INTEGRADAS PASARON");
        end else begin
            $fatal(1, "Se detectaron %0d errores", errors);
        end

        $finish;
    end

endmodule
