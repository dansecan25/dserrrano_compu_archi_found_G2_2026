
`timescale 1ns/1ps

/*
 * Modulo: tb_password_comparator
 *
 * Descripcion:
 *   Testbench del banco de 10 comparadores de contrasenas.
 *
 * Verifica:
 *   - Reconocimiento de contrasenas de apertura y cierre.
 *   - Contrasenas inexistentes.
 *   - Posiciones de memoria invalidas.
 *   - Primera y ultima posicion del banco.
 *   - Contrasena 000.
 *   - Cambio del tipo de una contrasena.
 *   - Comportamiento ante duplicados.
 *
 * Este modulo es solo para simulacion.
 */

module tb_password_comparator;

    logic [8:0]  password_in;
    logic [89:0] stored_passwords;
    logic [9:0]  valid;
    logic [9:0]  password_type;

    logic ABRIR;
    logic CERRAR;

    integer errors = 0;

    // Instancia del banco de comparadores.
    password_comparator dut (
        .password_in(password_in),
        .stored_passwords(stored_passwords),
        .valid(valid),
        .password_type(password_type),
        .ABRIR(ABRIR),
        .CERRAR(CERRAR)
    );

    // Comprueba las salidas despues de estabilizar las señales.
    task automatic check_result(
        input logic expected_abrir,
        input logic expected_cerrar,
        input string test_name
    );
        begin
            #10;

            if (ABRIR !== expected_abrir ||
                CERRAR !== expected_cerrar) begin

                $error("FALLO: %s | ABRIR=%b CERRAR=%b | Esperado=%b,%b",
                       test_name, ABRIR, CERRAR,
                       expected_abrir, expected_cerrar);

                errors = errors + 1;

            end else begin

                $display("PASS: %s", test_name);

            end
        end
    endtask

    initial begin

        // Inicialmente todas las posiciones estan vacias.
        password_in     = 9'b000_000_000;
        stored_passwords = 90'b0;
        valid            = 10'b0;
        password_type    = 10'b0;

        // -------------------------------------------------
        // Configuracion inicial de memoria simulada
        // -------------------------------------------------

        // Posicion 0: 245, apertura.
        stored_passwords[8:0]   = 9'b010_100_101;
        valid[0]                = 1'b1;
        password_type[0]        = 1'b1;

        // Posicion 1: 123, cierre.
        stored_passwords[17:9]  = 9'b001_010_011;
        valid[1]                = 1'b1;
        password_type[1]        = 1'b0;

        // Posicion 2: 501, apertura.
        stored_passwords[26:18] = 9'b101_000_001;
        valid[2]                = 1'b1;
        password_type[2]        = 1'b1;

        // Posicion 3: 333, almacenada pero invalida.
        stored_passwords[35:27] = 9'b011_011_011;
        valid[3]                = 1'b0;
        password_type[3]        = 1'b1;

        // Posicion 9: 555, cierre.
        stored_passwords[89:81] = 9'b101_101_101;
        valid[9]                = 1'b1;
        password_type[9]        = 1'b0;

        // -------------------------------------------------
        // Pruebas
        // -------------------------------------------------

        // 1. Contrasena valida de apertura.
        password_in = 9'b010_100_101;
        check_result(1'b1, 1'b0, "245 permite apertura");

        // 2. Contrasena valida de cierre.
        password_in = 9'b001_010_011;
        check_result(1'b0, 1'b1, "123 permite cierre");

        // 3. Otra contrasena valida de apertura.
        password_in = 9'b101_000_001;
        check_result(1'b1, 1'b0, "501 permite apertura");

        // 4. Contrasena inexistente.
        password_in = 9'b100_100_100;
        check_result(1'b0, 1'b0, "444 no registrada");

        // 5. Posicion con valid = 0.
        password_in = 9'b011_011_011;
        check_result(1'b0, 1'b0, "333 en posicion invalida");

        // 6. Ultima posicion del banco.
        password_in = 9'b101_101_101;
        check_result(1'b0, 1'b1, "555 en posicion 9");

        // 7. Ninguna contrasena registrada.
        valid = 10'b0;
        password_in = 9'b010_100_101;
        check_result(1'b0, 1'b0, "Memoria vacia");

        // Restaurar posiciones ocupadas.
        valid[0] = 1'b1;
        valid[1] = 1'b1;
        valid[2] = 1'b1;
        valid[9] = 1'b1;

        // 8. Contrasena 000 valida.
        stored_passwords[44:36] = 9'b000_000_000;
        valid[4] = 1'b1;
        password_type[4] = 1'b1;

        password_in = 9'b000_000_000;
        check_result(1'b1, 1'b0, "000 permite apertura");

        // 9. Cambiar la contrasena 245 de apertura a cierre.
        password_type[0] = 1'b0;
        password_in = 9'b010_100_101;
        check_result(1'b0, 1'b1, "245 reclasificada a cierre");

        // 10. Caso incorrecto que la memoria debe evitar:
        // La misma contrasena aparece en dos posiciones
        // validas con tipos opuestos.
        stored_passwords[53:45] = 9'b010_100_101;
        valid[5] = 1'b1;
        password_type[5] = 1'b1;

        password_in = 9'b010_100_101;
        check_result(1'b1, 1'b1, "Duplicado con tipos opuestos");

        // -------------------------------------------------
        // Resultado final
        // -------------------------------------------------

        if (errors == 0) begin
            $display("====================================");
            $display("TODAS LAS PRUEBAS PASARON");
            $display("====================================");
        end else begin
            $fatal(1, "Se detectaron %0d errores", errors);
        end

        $finish;

    end

endmodule
