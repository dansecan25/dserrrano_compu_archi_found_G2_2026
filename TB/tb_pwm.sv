`timescale 1ns/1ps
// 1) duty check: for each VALOR 0..7, count high clocks in 16 clocks (= 2*VALOR)
// 2) cycle-accurate check of every sample against a reference model
// 3) VALOR changing every clock, and a reset in the middle of operation
module tb_pwm;
    logic       CLK, RST_N;
    logic [2:0] VALOR;
    wire        PWM_OUT;
    logic [2:0] m_cnt;
    logic       m_out;
    int   v, k, highs, errors = 0;
    string verdict [2];

    pwm dut (.CLK(CLK), .RST_N(RST_N), .VALOR(VALOR), .PWM_OUT(PWM_OUT));

    // one clock; model = (counter < VALOR) registered on the rising edge
    task automatic tick;
        logic bad;
        #2;                                  // VALOR set-up time before the edge
        m_out = (m_cnt < VALOR);
        m_cnt = m_cnt + 1;
        CLK = 1; #5;
        bad = (PWM_OUT !== m_out);
        errors = errors + bad;
        highs = highs + PWM_OUT;
        CLK = 0; #5;
    endtask

    task automatic do_reset;
        logic bad;
        RST_N = 0; #5;
        m_cnt = 3'd0; m_out = 1'b0;
        bad = (PWM_OUT !== 1'b0);
        errors = errors + bad;
        CLK = 1; #5; CLK = 0; #5;
        CLK = 1; #5; CLK = 0; #5;
        RST_N = 1; #5;
    endtask

    initial begin
        verdict[0] = "FAILED"; verdict[1] = "PASSED";
        CLK = 0; VALOR = 3'd0; RST_N = 1; highs = 0;
        do_reset;

        // 1) + 2) every VALOR for 2 PWM periods
        for (v = 0; v < 8; v = v + 1) begin
            VALOR = v; highs = 0;
            for (k = 0; k < 16; k = k + 1) tick;
            errors = errors + (highs !== 2 * v);
            $display("VALOR=%0d | high clocks in 16 = %0d (exp %0d) | duty = %0d/8", v, highs, 2 * v, v);
        end

        // 3a) VALOR changes on every clock (checked sample by sample)
        for (k = 0; k < 64; k = k + 1) begin
            VALOR = k; tick;
        end

        // 3b) reset in the middle of operation
        VALOR = 3'd7;
        tick; tick; tick;
        do_reset;
        for (k = 0; k < 16; k = k + 1) tick;

        $display("=== tb_pwm: %s (errors = %0d) ===", verdict[errors == 0], errors);
    end
endmodule
