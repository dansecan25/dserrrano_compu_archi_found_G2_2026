
`timescale 1ns/1ps

/*
 * Modulo: tb_finger_input
 *
 * Descripcion:
 *   Prueba integrada de finger_decoder_6
 *   y finger_encoder_3.
 *
 * Comprueba:
 *   - Los seis valores permitidos (0 a 5).
 *   - La ausencia de entrada.
 *   - Los patrones invalidos.
 *   - La validez del OpCode (0 a 4).
 *
 * Se prueban las 64 combinaciones posibles
 * de los seis sensores.
 *
 * Este modulo es exclusivo para simulacion.
 */

module tb_finger_input;

    logic [5:0] sensors;

    wire Y0, Y1, Y2, Y3, Y4, Y5;

    wire [2:0] digit_value;
    wire digit_valid;
    wire opcode_valid;

    logic [2:0] expected_digit;
    logic expected_valid;
    logic expected_opcode;

    integer errors = 0;
    integer passed = 0;

    // Orden del bus:
    // sensors[5:0] = {S0, S1, S2, S3, S4, S5}

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

    initial begin

        // Probar todas las combinaciones de los sensores.
        for (integer i = 0; i < 64; i = i + 1) begin

            sensors = i;

            // Valores esperados por defecto:
            // cualquier patron no reconocido es invalido.
            expected_digit = 3'b000;
            expected_valid = 1'b0;
            expected_opcode = 1'b0;

            case (sensors)

                6'b100000: begin
                    expected_digit = 3'd0;
                    expected_valid = 1'b1;
                    expected_opcode = 1'b1;
                end

                6'b010000: begin
                    expected_digit = 3'd1;
                    expected_valid = 1'b1;
                    expected_opcode = 1'b1;
                end

                6'b011000: begin
                    expected_digit = 3'd2;
                    expected_valid = 1'b1;
                    expected_opcode = 1'b1;
                end

                6'b011100: begin
                    expected_digit = 3'd3;
                    expected_valid = 1'b1;
                    expected_opcode = 1'b1;
                end

                6'b011110: begin
                    expected_digit = 3'd4;
                    expected_valid = 1'b1;
                    expected_opcode = 1'b1;
                end

                6'b011111: begin
                    expected_digit = 3'd5;
                    expected_valid = 1'b1;
                    expected_opcode = 1'b0;
                end

                default: begin
                    // Se conservan los valores invalidos.
                end

            endcase

            #10;

            if (digit_value !== expected_digit ||
                digit_valid !== expected_valid ||
                opcode_valid !== expected_opcode) begin

                $error(
                    "FALLO: sensores=%b dato=%b valido=%b opcode=%b | Esperado=%b,%b,%b",
                    sensors,
                    digit_value,
                    digit_valid,
                    opcode_valid,
                    expected_digit,
                    expected_valid,
                    expected_opcode
                );

                errors = errors + 1;

            end else begin

                passed = passed + 1;

                $display(
                    "PASS: sensores=%b dato=%b valido=%b opcode=%b",
                    sensors,
                    digit_value,
                    digit_valid,
                    opcode_valid
                );

            end

        end

        $display("====================================");
        $display("Pruebas correctas: %0d de 64", passed);
        $display("Errores: %0d", errors);
        $display("====================================");

        if (errors == 0) begin

            $display("TODAS LAS PRUEBAS DE ENTRADA PASARON");

        end else begin

            $fatal(1, "Se detectaron %0d errores", errors);

        end

        $finish;

    end

endmodule
