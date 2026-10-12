`timescale 1ns/1ps

module tb_display_7seg;

    reg X;
    reg Y;

    wire a, b, c, d, e, f, g;

    display_7seg DUT (
        .X(X),
        .Y(Y),
        .a(a),
        .b(b),
        .c(c),
        .d(d),
        .e(e),
        .f(f),
        .g(g)
    );

    initial begin
        X = 0; Y = 0;
        #10;

        X = 1; Y = 0;
        #10;

        X = 0; Y = 1;
        #10;

        X = 1; Y = 1;
        #10;

        $finish;
    end

endmodule