`timescale 1ns/1ps
// System test. Finger counts are shown only while CLK=1 is about to start
// (set while CLK=0), so each count is captured in one clock-high phase.
//   CLK: 10 ns high / 10 ns low.
module tb_top;
    logic [4:0] sv;                // {S5..S1}
    logic       CLK, RST_N;
    wire        ABRIR, CERRAR;
    int         errors = 0;
    string      verdict [2];

    top dut (.S1(sv[0]), .S2(sv[1]), .S3(sv[2]), .S4(sv[3]), .S5(sv[4]),
             .CLK(CLK), .RST_N(RST_N), .ABRIR(ABRIR), .CERRAR(CERRAR));

    task automatic chk(input logic ea, input logic ec, input string note);
        logic bad;
        bad = (ABRIR !== ea) | (CERRAR !== ec);
        errors = errors + bad;
        $display("%0t | CLK=%b S5..S1=%b | ABRIR=%b CERRAR=%b | exp %b %b | ok=%b | %s",
                 $time, CLK, sv, ABRIR, CERRAR, ea, ec, ~bad, note);
    endtask

    task automatic hi;     CLK = 1; #10; endtask
    task automatic lo;     CLK = 0; #10; endtask
    task automatic cycle;  hi; lo;       endtask
    task automatic fingers(input int n);  sv = ~(5'b11111 << n); #5; endtask
    task automatic idle6;  cycle; cycle; cycle; cycle; cycle; cycle; endtask

    // after the code is completed in a CLK-high phase: 3 highs total, output
    // must stay up until the falling edge that sets the 2nd shift output.
    task automatic hold_then_clear(input logic ea, input logic ec);
        lo; sv = 5'b00000;
        chk(ea, ec, "t0 falling: held");
        hi; chk(ea, ec, "t1 high: held");
        lo; chk(ea, ec, "t1 falling: held (1st output set)");
        hi; chk(ea, ec, "t2 high: held");
        lo; chk(0, 0,   "t2 falling: 2nd output set -> latches reset");
        idle6;
        chk(0, 0, "flushed, idle");
    endtask

    initial begin
        verdict[0] = "FAILED"; verdict[1] = "PASSED";
        sv = 5'b00000; CLK = 0; RST_N = 0; #10;
        cycle; cycle;                       // reset needs clock edges
        RST_N = 1; #10;
        chk(0, 0, "after power-up reset");

        // ---------- ABRIR: fingers 3, 4, 5 ----------
        fingers(3); hi; chk(0, 0, "3 fingers (E3)");        lo; sv = 5'b00000; #5;
        fingers(4); hi; chk(0, 0, "4 fingers (E3,E4)");     lo; sv = 5'b00000; #5;
        fingers(5); hi; chk(1, 0, "5 fingers (E3,E4,E5) -> ABRIR");
        hold_then_clear(1, 0);

        // ---------- CERRAR: fingers 2, 3, 4 ----------
        fingers(2); hi; chk(0, 0, "2 fingers (E2)");        lo; sv = 5'b00000; #5;
        fingers(3); hi; chk(0, 0, "3 fingers (E2,E3)");     lo; sv = 5'b00000; #5;
        fingers(4); hi; chk(0, 1, "4 fingers (E2,E3,E4) -> CERRAR");
        hold_then_clear(0, 1);

        // ---------- wrong code (E1,E3,E4,E5) then global reset ----------
        fingers(1); hi; lo; sv = 5'b00000; #5;
        fingers(3); hi; lo; sv = 5'b00000; #5;
        fingers(4); hi; lo; sv = 5'b00000; #5;
        fingers(5); hi; chk(0, 0, "E1,E3,E4,E5: ABRIR code + E1, nothing");
        lo; sv = 5'b00000;
        cycle; cycle;
        chk(0, 0, "still nothing");
        RST_N = 0; cycle; cycle; RST_N = 1; #10;
        chk(0, 0, "global reset");
        fingers(3); hi; lo; sv = 5'b00000; #5;
        fingers(4); hi; lo; sv = 5'b00000; #5;
        fingers(5); hi; chk(1, 0, "after reset E1 is gone -> ABRIR");
        hold_then_clear(1, 0);

        $display("=== tb_top: %s (errors = %0d) ===", verdict[errors == 0], errors);
    end
endmodule
