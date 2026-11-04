
`timescale 1ns/1ps

/*
 * Modulo: tb_alu_input_capture
 *
 * Descripcion:
 *   Verifica los registros de captura de OpCode,
 *   operando A y operando B.
 *
 * Pruebas:
 *   - Reset e inicializacion.
 *   - Captura secuencial de los tres datos.
 *   - Generacion de la contrasena de 9 bits.
 *   - Activacion de password_ready.
 *   - Rechazo de OpCode invalido.
 *   - Rechazo de entradas invalidas.
 *   - Conservacion sin habilitacion.
 *   - Captura del valor cero.
 *   - Reset despues de una captura completa.
 *   - Actualizacion exclusiva en flanco positivo.
 *
 * Este modulo es exclusivo para simulacion.
 */

module tb_alu_input_capture;

    logic clk;
    logic reset;

    logic [2:0] digit_value;
    logic digit_valid;
    logic opcode_valid;

    logic capture_opcode;
    logic capture_a;
    logic capture_b;

    wire [2:0] opcode;
    wire [2:0] operand_a;
    wire [2:0] operand_b;

    wire [8:0] password_out;
    wire password_ready;

    integer errors = 0;
    integer passed = 0;

    // Reloj de periodo 10 ns.
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Modulo bajo prueba.
    alu_input_capture dut (
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

    // Comprueba el estado completo del modulo.
    task automatic check_result(
        input logic [2:0] expected_opcode,
        input logic [2:0] expected_a,
        input logic [2:0] expected_b,
        input logic       expected_ready,
        input string      test_name
    );
        begin
            #1;

            if (opcode !== expected_opcode ||
                operand_a !== expected_a ||
                operand_b !== expected_b ||
                password_ready !== expected_ready ||
                password_out !==
                    {expected_opcode, expected_a, expected_b}) begin

                $error("FALLO: %s", test_name);

                $display("  Actual:   OP=%b A=%b B=%b P=%b ready=%b",
                         opcode, operand_a, operand_b,
                         password_out, password_ready);

                $display("  Esperado: OP=%b A=%b B=%b P=%b ready=%b",
                         expected_opcode, expected_a, expected_b,
                         {expected_opcode, expected_a, expected_b},
                         expected_ready);

                errors = errors + 1;

            end else begin

                $display("PASS: %s", test_name);
                passed = passed + 1;

            end
        end
    endtask

    // Captura un valor durante un unico ciclo.
    // Las entradas se preparan en el flanco negativo.
    task automatic capture_digit(
        input logic [2:0] value,
        input logic valid,
        input logic op_valid,
        input logic cap_op,
        input logic cap_a,
        input logic cap_b
    );
        begin
            @(negedge clk);

            digit_value = value;
            digit_valid = valid;
            opcode_valid = op_valid;

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

    initial begin

        // Inicializar entradas.
        reset = 1'b0;

        digit_value = 3'b000;
        digit_valid = 1'b0;
        opcode_valid = 1'b0;

        capture_opcode = 1'b0;
        capture_a = 1'b0;
        capture_b = 1'b0;

        // -------------------------------------------------
        // 1. Reset inicial
        // -------------------------------------------------

        @(negedge clk);
        reset = 1'b1;

        @(posedge clk);
        check_result(3'b000, 3'b000, 3'b000, 1'b0,
                     "Reset inicial");

        @(negedge clk);
        reset = 1'b0;

        // -------------------------------------------------
        // 2. Capturar OpCode 010 (multiplicacion)
        // -------------------------------------------------

        capture_digit(3'b010, 1'b1, 1'b1,
                      1'b1, 1'b0, 1'b0);

        check_result(3'b010, 3'b000, 3'b000, 1'b0,
                     "Capturar OpCode 010");

        // -------------------------------------------------
        // 3. Capturar A = 3
        // -------------------------------------------------

        capture_digit(3'b011, 1'b1, 1'b1,
                      1'b0, 1'b1, 1'b0);

        check_result(3'b010, 3'b011, 3'b000, 1'b0,
                     "Capturar operando A = 3");

        // -------------------------------------------------
        // 4. Capturar B = 5
        // -------------------------------------------------

        capture_digit(3'b101, 1'b1, 1'b0,
                      1'b0, 1'b0, 1'b1);

        check_result(3'b010, 3'b011, 3'b101, 1'b1,
                     "Capturar B = 5 y completar");

        // -------------------------------------------------
        // 5. Cambiar entradas sin habilitacion
        // -------------------------------------------------

        @(negedge clk);
        digit_value = 3'b100;
        digit_valid = 1'b1;
        opcode_valid = 1'b1;

        repeat (3) @(posedge clk);

        check_result(3'b010, 3'b011, 3'b101, 1'b1,
                     "Conservar registros sin habilitacion");

        // -------------------------------------------------
        // 6. Reset despues de completar la entrada
        // -------------------------------------------------

        @(negedge clk);
        reset = 1'b1;

        @(posedge clk);

        check_result(3'b000, 3'b000, 3'b000, 1'b0,
                     "Reset despues de captura completa");

        @(negedge clk);
        reset = 1'b0;

        // -------------------------------------------------
        // 7. OpCode 5 debe rechazarse
        // -------------------------------------------------

        capture_digit(3'b101, 1'b1, 1'b0,
                      1'b1, 1'b0, 1'b0);

        check_result(3'b000, 3'b000, 3'b000, 1'b0,
                     "Rechazar OpCode 5");

        // -------------------------------------------------
        // 8. Entrada sin digito valido
        // -------------------------------------------------

        capture_digit(3'b000, 1'b0, 1'b0,
                      1'b0, 1'b1, 1'b0);

        check_result(3'b000, 3'b000, 3'b000, 1'b0,
                     "Rechazar entrada sin dedos");

        // -------------------------------------------------
        // 9. Capturar cero explicito como OpCode
        // -------------------------------------------------

        capture_digit(3'b000, 1'b1, 1'b1,
                      1'b1, 1'b0, 1'b0);

        check_result(3'b000, 3'b000, 3'b000, 1'b0,
                     "Capturar OpCode cero");

        // -------------------------------------------------
        // 10. Capturar cero explicito como A
        // -------------------------------------------------

        capture_digit(3'b000, 1'b1, 1'b1,
                      1'b0, 1'b1, 1'b0);

        check_result(3'b000, 3'b000, 3'b000, 1'b0,
                     "Capturar operando A cero");

        // -------------------------------------------------
        // 11. Capturar B = 1 y completar
        // -------------------------------------------------

        capture_digit(3'b001, 1'b1, 1'b1,
                      1'b0, 1'b0, 1'b1);

        check_result(3'b000, 3'b000, 3'b001, 1'b1,
                     "Completar contrasena 001");

        // -------------------------------------------------
        // 12. Verificar que no cambia antes del flanco
        // -------------------------------------------------

        @(negedge clk);

        digit_value = 3'b100;
        digit_valid = 1'b1;
        opcode_valid = 1'b1;

        capture_opcode = 1'b1;

        #2;

        check_result(3'b000, 3'b000, 3'b001, 1'b1,
                     "No actualizar antes del flanco");

        // -------------------------------------------------
        // 13. Actualizar despues del flanco
        // -------------------------------------------------

        @(posedge clk);

        check_result(3'b100, 3'b000, 3'b001, 1'b1,
                     "Actualizar despues del flanco");

        // Desactivar la captura.
        @(negedge clk);
        capture_opcode = 1'b0;

        // -------------------------------------------------
        // 14. Reset con captura simultanea
        // -------------------------------------------------

        reset = 1'b1;
        capture_a = 1'b1;
        digit_value = 3'b101;

        @(posedge clk);

        check_result(3'b000, 3'b000, 3'b000, 1'b0,
                     "Reset tiene prioridad");

        @(negedge clk);
        reset = 1'b0;
        capture_a = 1'b0;

        // -------------------------------------------------
        // Resultado final
        // -------------------------------------------------

        $display("====================================");
        $display("Pruebas correctas: %0d de 14", passed);
        $display("Errores: %0d", errors);
        $display("====================================");

        if (errors == 0) begin

            $display("TODAS LAS PRUEBAS DE CAPTURA PASARON");

        end else begin

            $fatal(1, "Se detectaron %0d errores", errors);

        end

        $finish;

    end

endmodule
