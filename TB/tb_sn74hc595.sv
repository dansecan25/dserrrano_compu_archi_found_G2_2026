`timescale 1ns/1ps
// Full 74HC595 test. Reference model: sreg (shift register), stored (output latch).
// Checks that outputs only change on RCLK, QH' follows the last shift stage,
// a single bit and two bits travel through QA..QH, OE_N and SRCLR_N behaviour.
module tb_sn74hc595;
    logic       SER, SRCLK, SRCLR_N, RCLK, OE_N;
    wire  [7:0] Q;
    wire        QH_PRIME;
    logic [7:0] sreg, stored, pat;
    int         errors = 0;
    int         i;
    string      verdict [2];
    string      phase;

    sn74hc595 dut (.SER(SER), .SRCLK(SRCLK), .SRCLR_N(SRCLR_N), .RCLK(RCLK),
                   .OE_N(OE_N), .Q(Q), .QH_PRIME(QH_PRIME));

    task automatic check(input string step);
        logic bad;
        bad = (Q !== (stored & {8{~OE_N}})) | (QH_PRIME !== sreg[7]);
        errors = errors + bad;
        $display("%0t | %-18s | %-22s | Q(QH..QA)=%b exp=%b | QH'=%b exp=%b | ok=%b",
                 $time, phase, step, Q, (stored & {8{~OE_N}}), QH_PRIME, sreg[7], ~bad);
    endtask

    task automatic shift_in(input logic s);
        SER = s; #5;
        SRCLK = 1;
        sreg = {sreg[6:0], s};
        #5;
        check("SRCLK edge (not latched)");
        SRCLK = 0; #5;
    endtask

    task automatic latch;
        RCLK = 1;
        stored = sreg;
        #5;
        check("RCLK edge (latched)");
        RCLK = 0; #5;
    endtask

    initial begin
        verdict[0] = "FAILED"; verdict[1] = "PASSED";
        SER = 0; SRCLK = 0; RCLK = 0; OE_N = 0; SRCLR_N = 0; #5;

        phase = "reset";
        sreg = 8'h00;
        latch;                               // storage <- cleared shift register
        SRCLR_N = 1; #5;

        phase = "single bit";
        shift_in(1); latch;
        for (i = 0; i < 8; i = i + 1) begin
            shift_in(0); latch;              // bit walks QA -> QH, then leaves
        end

        phase = "two adjacent bits";
        shift_in(1); latch; shift_in(1); latch;
        for (i = 0; i < 8; i = i + 1) begin
            shift_in(0); latch;
        end

        phase = "two separated bits";
        shift_in(1); latch; shift_in(0); latch; shift_in(1); latch;
        for (i = 0; i < 8; i = i + 1) begin
            shift_in(0); latch;
        end

        phase = "output enable";
        pat = 8'b10110010;
        for (i = 7; i >= 0; i = i - 1) shift_in(pat[i]);   // outputs not latched yet
        latch;
        OE_N = 1; #5;
        check("OE_N=1 (disabled)");
        shift_in(1); latch;
        check("shift while disabled");
        OE_N = 0; #5;
        check("OE_N=0 (enabled)");

        phase = "async clear";
        SRCLR_N = 0; #5;
        sreg = 8'h00;
        check("clear: outputs hold");
        SRCLR_N = 1; #5;
        latch;                               // zeros reach the outputs

        $display("=== tb_sn74hc595: %s (errors = %0d) ===", verdict[errors == 0], errors);
    end
endmodule
