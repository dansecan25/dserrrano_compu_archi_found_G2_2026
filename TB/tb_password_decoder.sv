`timescale 1ns/1ps
// ABRIR  = ~E1 & ~E2 &  E3 & E4 &  E5
// CERRAR = ~E1 &  E2 &  E3 & E4 & ~E5
// Both codes plus every single-bit neighbour of each (must NOT open/close).
module tb_password_decoder;
    logic [4:0] e;                 // {E5,E4,E3,E2,E1}
    wire  abrir, cerrar;
    int   errors = 0;
    string verdict [2];

    password_decoder dut (.E1(e[0]), .E2(e[1]), .E3(e[2]), .E4(e[3]), .E5(e[4]),
                          .ABRIR(abrir), .CERRAR(cerrar));

    task automatic chk(input logic [4:0] e_i, input logic ea, input logic ec, input string note);
        logic bad;
        e = e_i; #10;
        bad = (abrir !== ea) | (cerrar !== ec);
        errors = errors + bad;
        $display("%0t | E5..E1=%b | ABRIR=%b CERRAR=%b | exp %b %b | ok=%b | %s",
                 $time, e, abrir, cerrar, ea, ec, ~bad, note);
    endtask

    initial begin
        verdict[0] = "FAILED"; verdict[1] = "PASSED";
        chk(5'b11100, 1, 0, "ABRIR code (E3,E4,E5)");
        chk(5'b01110, 0, 1, "CERRAR code (E2,E3,E4)");
        // single-bit neighbours of ABRIR
        chk(5'b11101, 0, 0, "ABRIR + E1");
        chk(5'b11110, 0, 0, "ABRIR + E2 (= CERRAR + E5)");
        chk(5'b11000, 0, 0, "ABRIR - E3");
        chk(5'b10100, 0, 0, "ABRIR - E4");
        chk(5'b01100, 0, 0, "ABRIR - E5 (= CERRAR - E2)");
        // single-bit neighbours of CERRAR
        chk(5'b01111, 0, 0, "CERRAR + E1");
        chk(5'b01010, 0, 0, "CERRAR - E3");
        chk(5'b00110, 0, 0, "CERRAR - E4");
        chk(5'b00000, 0, 0, "nothing");
        chk(5'b11111, 0, 0, "everything");
        $display("=== tb_password_decoder: %s (errors = %0d) ===", verdict[errors == 0], errors);
    end
endmodule
