
`timescale 1ns/1ps

/*
 * Modulo: tb_password_slot
 *
 * Descripcion:
 *   Verifica el funcionamiento de una posicion
 *   de memoria para contrasenas.
 *
 * Pruebas:
 *   - Inicializacion mediante clear.
 *   - Escritura de una contrasena.
 *   - Conservacion de datos sin habilitacion.
 *   - Cambio de tipo.
 *   - Eliminacion logica.
 *   - Reutilizacion de una posicion.
 *   - Reset con una contrasena registrada.
 *   - Actualizacion solamente en flanco positivo.
 *   - Prioridad de clear sobre escritura.
 *
 * Este modulo es exclusivo para simulacion.
 */

module tb_password_slot;

    logic clk;
    logic clear;

    logic write_en;
    logic delete_en;
    logic change_en;

    logic [8:0] password_in;
    logic       type_in;

    logic [8:0] password_out;
    logic       type_out;
    logic       valid_out;

    integer errors = 0;

    // Modulo bajo prueba.
    password_slot dut (
        .clk(clk),
        .clear(clear),
        .write_en(write_en),
        .delete_en(delete_en),
        .change_en(change_en),
        .password_in(password_in),
        .type_in(type_in),
        .password_out(password_out),
        .type_out(type_out),
        .valid_out(valid_out)
    );

    // Reloj de periodo 10 ns.
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Comprueba las tres salidas.
    task automatic check_slot(
        input logic [8:0] expected_password,
        input logic       expected_type,
        input logic       expected_valid,
        input string      test_name
    );
        begin
            #1;

            if (password_out !== expected_password ||
                type_out     !== expected_type ||
                valid_out    !== expected_valid) begin

                $error("FALLO: %s | P=%b T=%b V=%b | Esperado P=%b T=%b V=%b",
                       test_name,
                       password_out, type_out, valid_out,
                       expected_password, expected_type,
                       expected_valid);

                errors = errors + 1;

            end else begin
                $display("PASS: %s", test_name);
            end
        end
    endtask

    initial begin

        // Estado inicial de las entradas.
        clear       = 1'b0;
        write_en    = 1'b0;
        delete_en   = 1'b0;
        change_en   = 1'b0;
        password_in = 9'b000_000_000;
        type_in     = 1'b0;

        // -------------------------------------------------
        // 1. Inicializacion de la posicion
        // -------------------------------------------------
        @(negedge clk);
        clear = 1'b1;

        @(posedge clk);
        check_slot(9'bxxxxxxxxx, 1'bx, 1'b0,
                   "Clear inicial invalida la posicion");

        // Clear solo reinicia valid.
        @(negedge clk);
        clear = 1'b0;

        // -------------------------------------------------
        // 2. Registrar 245 como apertura
        // -------------------------------------------------
        write_en    = 1'b1;
        password_in = 9'b010_100_101;
        type_in     = 1'b1;

        @(posedge clk);
        check_slot(9'b010_100_101, 1'b1, 1'b1,
                   "Registrar 245 como apertura");

        // -------------------------------------------------
        // 3. Conservar el dato sin escribir
        // -------------------------------------------------
        @(negedge clk);
        write_en    = 1'b0;
        password_in = 9'b101_101_101;
        type_in     = 1'b0;

        @(posedge clk);
        check_slot(9'b010_100_101, 1'b1, 1'b1,
                   "Conservar 245 sin habilitacion");

        // -------------------------------------------------
        // 4. Cambiar el tipo de apertura a cierre
        // -------------------------------------------------
        @(negedge clk);
        change_en = 1'b1;

        @(posedge clk);
        check_slot(9'b010_100_101, 1'b0, 1'b1,
                   "Cambiar 245 a cierre");

        // -------------------------------------------------
        // 5. Eliminar la contrasena
        // -------------------------------------------------
        @(negedge clk);
        change_en = 1'b0;
        delete_en = 1'b1;

        @(posedge clk);
        check_slot(9'b010_100_101, 1'b0, 1'b0,
                   "Eliminar 245");

        // -------------------------------------------------
        // 6. Reutilizar la posicion con 123
        // -------------------------------------------------
        @(negedge clk);
        delete_en   = 1'b0;
        write_en    = 1'b1;
        password_in = 9'b001_010_011;
        type_in     = 1'b1;

        @(posedge clk);
        check_slot(9'b001_010_011, 1'b1, 1'b1,
                   "Reutilizar posicion con 123");

        // -------------------------------------------------
        // 7. Clear con una contrasena registrada
        // -------------------------------------------------
        @(negedge clk);
        write_en = 1'b0;
        clear    = 1'b1;

        @(posedge clk);
        check_slot(9'b001_010_011, 1'b1, 1'b0,
                   "Clear invalida sin borrar datos");

        // -------------------------------------------------
        // 8. No actualizar antes del flanco positivo
        // -------------------------------------------------
        @(negedge clk);
        clear       = 1'b0;
        write_en    = 1'b1;
        password_in = 9'b101_000_001;
        type_in     = 1'b0;

        // Comprobar antes del proximo flanco positivo.
        #2;
        check_slot(9'b001_010_011, 1'b1, 1'b0,
                   "No cambia antes del flanco");

        @(posedge clk);
        check_slot(9'b101_000_001, 1'b0, 1'b1,
                   "Cambia despues del flanco");

        // -------------------------------------------------
        // 9. Clear tiene prioridad sobre write_en
        // -------------------------------------------------
        @(negedge clk);
        clear       = 1'b1;
        write_en    = 1'b1;
        password_in = 9'b100_100_100;
        type_in     = 1'b1;

        @(posedge clk);

        // Clear invalida la posicion, aunque write_en
        // puede seguir actualizando password y type.
        check_slot(9'b100_100_100, 1'b1, 1'b0,
                   "Clear tiene prioridad en valid");

        // -------------------------------------------------
        // Resultado final
        // -------------------------------------------------
        if (errors == 0) begin
            $display("====================================");
            $display("TODAS LAS PRUEBAS DE SLOT PASARON");
            $display("====================================");
        end else begin
            $fatal(1, "Se detectaron %0d errores", errors);
        end

        $finish;
    end

endmodule
