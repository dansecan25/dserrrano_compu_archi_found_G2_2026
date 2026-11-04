`timescale 1ns/1ps

module tb_password_equal;

    logic [8:0] password_in;
    logic [8:0] password_stored;
    logic equal;

    // Instancia del comparador
    password_equal dut (
        .password_in(password_in),
        .password_stored(password_stored),
        .equal(equal)
    );

    initial begin

        // Caso 1: contrasenas identicas (245)
        password_in     = 9'b010_100_101;
        password_stored = 9'b010_100_101;
        #10;
        assert(equal === 1'b1)
            else $error("Error: contrasenas iguales");

        // Caso 2: contrasenas diferentes (245 y 243)
        password_in     = 9'b010_100_101;
        password_stored = 9'b010_100_011;
        #10;
        assert(equal === 1'b0)
            else $error("Error: contrasenas diferentes");

        // Caso 3: contrasenas iguales a cero
        password_in     = 9'b000_000_000;
        password_stored = 9'b000_000_000;
        #10;
        assert(equal === 1'b1)
            else $error("Error: contrasenas 000");

        // Caso 4: contrasena maxima valida (555)
        password_in     = 9'b101_101_101;
        password_stored = 9'b101_101_101;
        #10;
        assert(equal === 1'b1)
            else $error("Error: contrasenas 555");

        // Caso 5: primera posicion diferente
        password_in     = 9'b001_010_011;
        password_stored = 9'b100_010_011;
        #10;
        assert(equal === 1'b0)
            else $error("Error: primer digito diferente");

        $display("Pruebas de password_equal finalizadas");
        $finish;

    end

endmodule