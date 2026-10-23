`timescale 1ns/1ps
// Digits 0..7 on a common-anode display (segment = 0 -> lit). No loops.
// Expected vectors are the LIT segments {a,b,c,d,e,f,g}; pins must be the inverse.
module tb_display_7seg;
    logic [2:0] valor;
    wire  a, b, c, d, e, f, g;
    int   errors = 0;
    string verdict [2];

    display_7seg dut (.VALOR(valor), .a(a), .b(b), .c(c), .d(d), .e(e), .f(f), .g(g));

    task automatic chk(input logic [2:0] v, input logic [6:0] lit, input string note);
        logic bad;
        valor = v; #5;
        bad = ({a, b, c, d, e, f, g} !== ~lit);
        errors = errors + bad;
        $display("VALOR=%0d | pins abcdefg=%b | lit=%b | ok=%b | %s",
                 valor, {a, b, c, d, e, f, g}, ~{a, b, c, d, e, f, g}, ~bad, note);
    endtask

    initial begin
        verdict[0] = "FAILED"; verdict[1] = "PASSED";
        chk(3'd0, 7'b1111110, "0");
        chk(3'd1, 7'b0110000, "1");
        chk(3'd2, 7'b1101101, "2");
        chk(3'd3, 7'b1111001, "3");
        chk(3'd4, 7'b0110011, "4");
        chk(3'd5, 7'b1011011, "5");
        chk(3'd6, 7'b1011111, "6");
        chk(3'd7, 7'b1110000, "7");
        $display("=== tb_display_7seg: %s (errors = %0d) ===", verdict[errors == 0], errors);
    end
endmodule
