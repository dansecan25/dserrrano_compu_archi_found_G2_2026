
`timescale 1ns/1ps

/*
 * Modulo: tb_password_memory
 *
 * Descripcion:
 *   Prueba integrada de password_memory y
 *   password_comparator con N = 4.
 *
 * Verifica registro, busqueda, eliminacion,
 * reclasificacion, memoria llena y clear.
 *
 * Este archivo es exclusivo para simulacion.
 */

module tb_password_memory;

    localparam integer N = 4;

    logic clk;
    logic clear;
    logic register_pulse;

    logic [8:0] password_in;
    logic type_in;

    wire [9*N-1:0] stored_passwords;
    wire [N-1:0] valid;
    wire [N-1:0] password_type;
    wire [N-1:0] found;

    wire ABRIR;
    wire CERRAR;
    wire memory_full;

    integer errors = 0;
	 
	 // Copias de los registros para comprobar que
	 // no se modifican durante ciertas operaciones.
	 logic [9*N-1:0] snapshot_passwords;
	 logic [N-1:0]   snapshot_types;

    // Reloj de periodo 10 ns.
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Banco de memoria.
    password_memory #(.N(N)) memory_dut (
        .clk(clk),
        .clear(clear),
        .register_pulse(register_pulse),
        .password_in(password_in),
        .type_in(type_in),
        .found(found),
        .stored_passwords(stored_passwords),
        .valid(valid),
        .password_type(password_type),
        .memory_full(memory_full)
    );

    // Comparadores paralelos.
    password_comparator #(.N(N)) comparator_dut (
        .password_in(password_in),
        .stored_passwords(stored_passwords),
        .valid(valid),
        .password_type(password_type),
        .ABRIR(ABRIR),
        .CERRAR(CERRAR),
        .found(found)
    );

    // Ejecuta exactamente un ciclo de administracion.
    // Cambia las entradas en flanco negativo y desactiva
    // register_pulse antes del siguiente flanco positivo.
    task automatic register_password(
        input logic [8:0] new_password,
        input logic new_type
    );
        begin
            @(negedge clk);
            password_in = new_password;
            type_in = new_type;
            register_pulse = 1'b1;

            @(posedge clk);
            #1;

            @(negedge clk);
            register_pulse = 1'b0;
            #1;
        end
    endtask

    // Comprueba las salidas del sistema completo.
    task automatic check_result(
        input logic [N-1:0] expected_valid,
        input logic [N-1:0] expected_found,
        input logic expected_abrir,
        input logic expected_cerrar,
        input logic expected_full,
        input string test_name
    );
        begin
            #1;

            if (valid !== expected_valid ||
                found !== expected_found ||
                ABRIR !== expected_abrir ||
                CERRAR !== expected_cerrar ||
                memory_full !== expected_full) begin

                $error("FALLO: %s", test_name);
                $display("  valid=%b found=%b A=%b C=%b full=%b",
                         valid, found, ABRIR, CERRAR, memory_full);
                $display("  esperado: %b %b %b %b %b",
                         expected_valid, expected_found,
                         expected_abrir, expected_cerrar,
                         expected_full);

                errors = errors + 1;

            end else begin
                $display("PASS: %s", test_name);
            end
        end
    endtask

    initial begin

        clear = 1'b0;
        register_pulse = 1'b0;
        password_in = 9'b0;
        type_in = 1'b0;

        // 1. Inicializar el banco.
        @(negedge clk);
        clear = 1'b1;

        @(posedge clk);
        #1;

        @(negedge clk);
        clear = 1'b0;

        check_result(4'b0000, 4'b0000, 0, 0, 0,
                     "Memoria inicializada");

        // 2. Registrar 245 para abrir.
        register_password(9'b010_100_101, 1'b1);

        check_result(4'b0001, 4'b0001, 1, 0, 0,
                     "245 registrada para apertura");

        // 3. Registrar 123 para cerrar.
        register_password(9'b001_010_011, 1'b0);

        check_result(4'b0011, 4'b0010, 0, 1, 0,
                     "123 registrada para cierre");

        // 4. Reclasificar 245 de apertura a cierre.
        register_password(9'b010_100_101, 1'b0);

        check_result(4'b0011, 4'b0001, 0, 1, 0,
                     "245 reclasificada a cierre");

        // 5. Repetir 245 del mismo tipo: eliminar.
        register_password(9'b010_100_101, 1'b0);

        check_result(4'b0010, 4'b0000, 0, 0, 0,
                     "245 eliminada");

        // 6. Reutilizar la primera posicion libre.
        register_password(9'b101_000_001, 1'b1);

        check_result(4'b0011, 4'b0001, 1, 0, 0,
                     "501 ocupa posicion 0");

        // 7. Registrar 555 como cierre.
        register_password(9'b101_101_101, 1'b0);

        check_result(4'b0111, 4'b0100, 0, 1, 0,
                     "555 ocupa posicion 2");

        // 8. Registrar 000 como apertura.
        register_password(9'b000_000_000, 1'b1);

        check_result(4'b1111, 4'b1000, 1, 0, 1,
                     "000 ocupa posicion 3; memoria llena");

        // 9. Intentar guardar una contrasena nueva.
        register_password(9'b100_100_100, 1'b1);

        check_result(4'b1111, 4'b0000, 0, 0, 1,
                     "Memoria llena rechaza 444");

        // 10. Reclasificar estando llena.
        register_password(9'b101_101_101, 1'b1);

        check_result(4'b1111, 4'b0100, 1, 0, 1,
                     "Reclasificar 555 con memoria llena");

        // 11. Eliminar estando llena.
        register_password(9'b101_101_101, 1'b1);

        check_result(4'b1011, 4'b0000, 0, 0, 0,
                     "Eliminar 555 libera espacio");

        // 12. Registrar 444 en la posicion liberada.
        register_password(9'b100_100_100, 1'b0);

        check_result(4'b1111, 4'b0100, 0, 1, 1,
                     "444 reutiliza posicion 2");

        // 13. Borrar toda la memoria.
        @(negedge clk);
        register_pulse = 1'b0;
        clear = 1'b1;

        @(posedge clk);
        #1;

        @(negedge clk);
        clear = 1'b0;

        check_result(4'b0000, 4'b0000, 0, 0, 0,
                     "Clear invalida toda la memoria");

        // -------------------------------------------------
        // 14. Registrar una contrasena para nuevas pruebas
        // -------------------------------------------------

        register_password(9'b010_100_101, 1'b1);

        check_result(4'b0001, 4'b0001, 1, 0, 0,
                     "Registrar 245 despues de clear");

        // Guardar el contenido actual de los registros.
        snapshot_passwords = stored_passwords;
        snapshot_types = password_type;

        // -------------------------------------------------
        // 15. Cambiar entradas sin register_pulse
        // -------------------------------------------------

        @(negedge clk);
        register_pulse = 1'b0;
        password_in = 9'b001_010_011;
        type_in = 1'b0;

        // Esperar varios ciclos de reloj.
        repeat (3) @(posedge clk);
        #1;

        // 123 no existe, pero 245 debe seguir almacenada.
        check_result(4'b0001, 4'b0000, 0, 0, 0,
                     "Sin pulso no se registra 123");

        if (stored_passwords !== snapshot_passwords ||
            password_type !== snapshot_types) begin
            $error("FALLO: Registros modificados sin pulso");
            errors = errors + 1;
        end else begin
            $display("PASS: Registros conservados sin pulso");
        end

        // -------------------------------------------------
        // 16. Clear y register_pulse simultaneos
        // -------------------------------------------------

        @(negedge clk);
        clear = 1'b1;
        register_pulse = 1'b1;
        password_in = 9'b101_101_101;
        type_in = 1'b0;

        @(posedge clk);
        #1;

        check_result(4'b0000, 4'b0000, 0, 0, 0,
                     "Clear bloquea administracion");

        // Clear debe invalidar, pero no alterar los
        // registros de contrasena y tipo.
        if (stored_passwords !== snapshot_passwords ||
            password_type !== snapshot_types) begin
            $error("FALLO: Clear modifico datos almacenados");
            errors = errors + 1;
        end else begin
            $display("PASS: Clear conserva datos fisicos");
        end

        // -------------------------------------------------
        // 17. Comprobar que la memoria vuelve a funcionar
        // -------------------------------------------------

        @(negedge clk);
        clear = 1'b0;
        register_pulse = 1'b0;

        register_password(9'b101_101_101, 1'b0);

        check_result(4'b0001, 4'b0001, 0, 1, 0,
                     "Registrar 555 despues de clear");
				
							
        // Resultado final.
        if (errors == 0) begin
            $display("====================================");
            $display("TODAS LAS PRUEBAS DE MEMORIA PASARON");
            $display("====================================");
        end else begin
            $fatal(1, "Se detectaron %0d errores", errors);
        end

        $finish;
    end

endmodule
