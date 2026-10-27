
`timescale 1ns/1ps

/*
 * Modulo: tb_password_memory_param
 *
 * Descripcion:
 *   Verifica el banco de memoria con distintos
 *   valores del parametro N.
 *
 * Prueba:
 *   - Inicializacion.
 *   - Registro en la primera posicion.
 *   - Llenado de todas las posiciones.
 *   - Rechazo por memoria llena.
 *   - Eliminacion estando llena.
 *   - Borrado general.
 *
 * Ejecutar con N = 1 y N = 10.
 */

module tb_password_memory_param #(
    parameter integer N = 1
);

    logic clk = 1'b0;
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
    logic [8:0] test_password;

    always #5 clk = ~clk;

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

    password_comparator #(.N(N)) comparator_dut (
        .password_in(password_in),
        .stored_passwords(stored_passwords),
        .valid(valid),
        .password_type(password_type),
        .ABRIR(ABRIR),
        .CERRAR(CERRAR),
        .found(found)
    );

    // Procesa una solicitud durante un ciclo.
    task automatic register_password(
        input logic [8:0] p,
        input logic t
    );
        begin
            @(negedge clk);
            password_in = p;
            type_in = t;
            register_pulse = 1'b1;

            @(posedge clk);
            #1;

            @(negedge clk);
            register_pulse = 1'b0;
            #1;
        end
    endtask

    // Comprueba una condicion e informa el resultado.
    task automatic check(
        input logic condition,
        input string name
    );
        begin
            if (condition !== 1'b1) begin
                $error("FALLO N=%0d: %s", N, name);
                errors = errors + 1;
            end else begin
                $display("PASS N=%0d: %s", N, name);
            end
        end
    endtask

    initial begin

        clear = 1'b0;
        register_pulse = 1'b0;
        password_in = 9'b0;
        type_in = 1'b0;

        // Inicializacion.
        @(negedge clk);
        clear = 1'b1;

        @(posedge clk);
        #1;

        @(negedge clk);
        clear = 1'b0;
        #1;

        check(valid === {N{1'b0}},
              "Todas las posiciones comienzan libres");

        // Registrar 000 en la posicion 0.
        register_password(9'b000_000_000, 1'b1);

        check(valid[0] === 1'b1 &&
              found[0] === 1'b1 &&
              ABRIR === 1'b1,
              "Registro en primera posicion");

        // Llenar las posiciones restantes.
        // Las claves generadas usan digitos de 0 a 5.
        for (integer j = 1; j < N; j = j + 1) begin

            test_password = ((j / 6) << 6) | (j % 6);

            register_password(test_password, 1'b1);

            check(valid[j] === 1'b1 &&
                  stored_passwords[9*j +: 9] === test_password,
                  $sformatf("Registro en posicion %0d", j));

        end

        check(memory_full === 1'b1 &&
              (&valid) === 1'b1,
              "Memoria completamente llena");

        // Intentar registrar una clave nueva.
        register_password(9'b101_101_101, 1'b0);

        check(found === {N{1'b0}} &&
              memory_full === 1'b1,
              "Rechazo de contrasena nueva con memoria llena");

        // Buscar y eliminar la clave de la posicion 0.
        register_password(9'b000_000_000, 1'b1);

        check(valid[0] === 1'b0 &&
              memory_full === 1'b0,
              "Eliminacion libera una posicion");

        // Reutilizar la posicion liberada.
        register_password(9'b101_101_101, 1'b0);

        check(valid[0] === 1'b1 &&
              found[0] === 1'b1 &&
              CERRAR === 1'b1,
              "Reutilizacion de posicion libre");

        // Borrado general.
        @(negedge clk);
        clear = 1'b1;

        @(posedge clk);
        #1;

        @(negedge clk);
        clear = 1'b0;
        #1;

        check(valid === {N{1'b0}} &&
              found === {N{1'b0}} &&
              memory_full === 1'b0,
              "Borrado general");

        if (errors == 0) begin
            $display("================================");
            $display("TODAS LAS PRUEBAS PASARON N=%0d", N);
            $display("================================");
        end else begin
            $fatal(1, "N=%0d: %0d errores", N, errors);
        end

        $finish;
    end

endmodule
