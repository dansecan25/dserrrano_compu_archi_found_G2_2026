`timescale 1ns/1ps
// Integration test of top: normal flow + display, test mode (button, flag, PWM,
// display), mode switching.
//  - Finger sensors: S1..S4 active high, S5 pin is active LOW (top inverts it);
//    the task fingers(n) takes care of that.
//  - CLK here is the 50 MHz-style clock (CLK_50). top is instantiated with
//    CLK_DIV_HALF = 1, so the divided clock toggles on every fast cycle:
//    hi = divided clock rising, lo = divided clock falling. The real 1.5 s
//    divider value is checked in tb_clock_divider.
//  - Needs password_decoder: ABRIR = E3.E4.E5, CERRAR = E2.E3.E4 (others 0).
//  - Switches active high, button active low.
module tb_top;
    logic [4:0] sv;                         // logical finger bits {5..1}
    logic       CLK, RST_N, SW1, SW2, SW3, BTN_TEST_N;
    wire        ABRIR, CERRAR, PWM_OUT, TEST_RUNNING;
    wire        SEG_A, SEG_B, SEG_C, SEG_D, SEG_E, SEG_F, SEG_G;
    wire        LED_CLK, LED_ABRIR, LED_CERRAR;
    wire        LED_Y1, LED_Y2, LED_Y3, LED_Y4, LED_Y5;
    int   errors = 0;
    int   n_open, n_close, n_run, pwm_open, pwm_close;
    string verdict [2];

    // lit-segment vectors {a,b,c,d,e,f,g}
    localparam logic [6:0] DIG0 = 7'b1111110;
    localparam logic [6:0] DIG1 = 7'b0110000;
    localparam logic [6:0] DIG5 = 7'b1011011;

    top #(.CLK_DIV_HALF(1)) dut (.S1(sv[0]), .S2(sv[1]), .S3(sv[2]), .S4(sv[3]), .S5(~sv[4]),
             .CLK_50(CLK), .RST_N(RST_N),
             .SW1(SW1), .SW2(SW2), .SW3(SW3), .BTN_TEST_N(BTN_TEST_N),
             .ABRIR(ABRIR), .CERRAR(CERRAR), .PWM_OUT(PWM_OUT), .TEST_RUNNING(TEST_RUNNING),
             .SEG_A(SEG_A), .SEG_B(SEG_B), .SEG_C(SEG_C), .SEG_D(SEG_D),
             .SEG_E(SEG_E), .SEG_F(SEG_F), .SEG_G(SEG_G),
             .LED_CLK(LED_CLK), .LED_ABRIR(LED_ABRIR), .LED_CERRAR(LED_CERRAR),
             .LED_Y1(LED_Y1), .LED_Y2(LED_Y2), .LED_Y3(LED_Y3), .LED_Y4(LED_Y4), .LED_Y5(LED_Y5));

    // ---- checks ----
    task automatic chk(input logic ea, input logic ec, input logic [6:0] lit,
                       input logic erun, input string note);
        logic bad;
        bad = (ABRIR !== ea) | (CERRAR !== ec)
            | ({SEG_A, SEG_B, SEG_C, SEG_D, SEG_E, SEG_F, SEG_G} !== ~lit)
            | (TEST_RUNNING !== erun)
            | (LED_ABRIR !== ea) | (LED_CERRAR !== ec);
        errors = errors + bad;
        $display("%0t | SW=%b%b%b | ABRIR=%b CERRAR=%b seg=%b run=%b PWM=%b | exp %b %b lit=%b run=%b | ok=%b | %s",
                 $time, SW3, SW2, SW1, ABRIR, CERRAR, {SEG_A, SEG_B, SEG_C, SEG_D, SEG_E, SEG_F, SEG_G},
                 TEST_RUNNING, PWM_OUT, ea, ec, lit, erun, ~bad, note);
    endtask

    task automatic chk_count(input int got, input int expv, input string note);
        logic bad;
        bad = (got !== expv);
        errors = errors + bad;
        $display("%-46s | %0d (exp %0d) | ok=%b", note, got, expv, ~bad);
    endtask

    // ---- stimulus helpers ----
    task automatic fpulse; CLK = 1; #5; CLK = 0; #5; endtask   // one fast (50 MHz) cycle
    task automatic hi;     fpulse; endtask                     // divided clock -> 1
    task automatic lo;     fpulse; endtask                     // divided clock -> 0
    task automatic cycle;  hi; lo; endtask
    task automatic fingers(input int n);  sv = ~(5'b11111 << n); #5; endtask
    task automatic idle6;  cycle; cycle; cycle; cycle; cycle; cycle; endtask

    // sampled clock cycle for test mode: classifies the value the PWM sees at the edge
    task automatic tick_s;
        logic po, pc;
        po = ABRIR; pc = CERRAR;
        n_open  = n_open  + po;
        n_close = n_close + pc;
        n_run   = n_run   + TEST_RUNNING;
        CLK = 1; #5;                         // divided clock rises
        pwm_open  = pwm_open  + (PWM_OUT & po);
        pwm_close = pwm_close + (PWM_OUT & pc);
        CLK = 0; #5;
        fpulse;                              // divided clock falls
    endtask

    task automatic ticks_s(input int n);
        int i;
        for (i = 0; i < n; i = i + 1) tick_s;
    endtask

    task automatic clear_counts;
        n_open = 0; n_close = 0; n_run = 0; pwm_open = 0; pwm_close = 0;
    endtask

    task automatic press;                // button down one cycle, then up
        BTN_TEST_N = 0; #5; cycle; BTN_TEST_N = 1; #5;
    endtask

    // normal flow: output held until the 2nd shift output sets, then cleared
    task automatic hold_then_clear(input logic ea, input logic ec, input logic [6:0] lit);
        lo; sv = 5'b00000;
        chk(ea, ec, lit, 0, "t0 falling: held");
        hi; chk(ea, ec, lit, 0, "t1 high: held");
        lo; chk(ea, ec, lit, 0, "t1 falling: held");
        hi; chk(ea, ec, lit, 0, "t2 high: held");
        lo; chk(0, 0, DIG0, 0,  "t2 falling: cleared, display 0");
        idle6;
        chk(0, 0, DIG0, 0, "flushed, idle");
    endtask

    initial begin
        verdict[0] = "FAILED"; verdict[1] = "PASSED";
        sv = 5'b00000; CLK = 0; RST_N = 0; SW1 = 1; SW2 = 0; SW3 = 0; BTN_TEST_N = 1; #10;
        fpulse; fpulse;                      // reset keeps the divided clock low
        RST_N = 1; #10;
        cycle; cycle;                        // 2 divided-clock cycles: storage registers load zeros

        // ============ SW1: normal flow ============
        chk(0, 0, DIG0, 0, "SW1 normal: idle, display 0");

        fingers(3); hi; lo; sv = 5'b00000; #5;
        fingers(4); hi; lo; sv = 5'b00000; #5;
        fingers(5); hi; chk(1, 0, DIG5, 0, "normal ABRIR (3,4,5): display 5");
        hold_then_clear(1, 0, DIG5);

        fingers(2); hi; lo; sv = 5'b00000; #5;
        fingers(3); hi; lo; sv = 5'b00000; #5;
        fingers(4); hi; chk(0, 1, DIG1, 0, "normal CERRAR (2,3,4): display 1");
        hold_then_clear(0, 1, DIG1);

        // ============ SW3: PWM test mode ============
        SW3 = 1; #5;
        chk(0, 0, DIG0, 0, "SW3 test mode: idle, flag 0");

        clear_counts;
        press;                                       // E1: button seen
        tick_s;                                      // E2: RUNNING rises, open phase starts
        chk(1, 0, DIG5, 1, "test: open phase (value 5)");
        ticks_s(8);                                  // E3..E10
        chk(0, 1, DIG1, 1, "test: close phase (value 1)");
        ticks_s(8);                                  // E11..E18
        chk(0, 0, DIG0, 1, "test: last tap set, flag still 1");
        tick_s;                                      // E19: run clears
        chk(0, 0, DIG0, 0, "test: finished, flag 0");
        ticks_s(10);
        chk_count(n_open,    8,  "test: edges with value 5");
        chk_count(n_close,   8,  "test: edges with value 1");
        chk_count(n_run,     17, "test: edges with flag = 1");
        chk_count(pwm_open,  5,  "test: PWM high edges during value 5 (5/8)");
        chk_count(pwm_close, 1,  "test: PWM high edges during value 1 (1/8)");
        chk(0, 0, DIG0, 0, "test: idle after run");

        // button held down: single run
        clear_counts;
        BTN_TEST_N = 0; #5; ticks_s(40); BTN_TEST_N = 1; #5; ticks_s(5);
        chk_count(n_open,  8, "test: button held -> one run (open edges)");
        chk_count(n_close, 8, "test: button held -> one run (close edges)");

        // leaving test mode in the middle aborts it
        press; ticks_s(5);
        SW3 = 0; #5;
        chk(0, 0, DIG0, 0, "SW3->0 mid-test: aborted, back to normal idle");
        ticks_s(10);
        chk(0, 0, DIG0, 0, "still idle");

        // ============ SW2: reserved ============
        SW1 = 0; SW2 = 1; #5;
        chk(0, 0, DIG0, 0, "SW2: reserved, all 0");
        cycle; cycle;
        chk(0, 0, DIG0, 0, "SW2: still 0");

        // ============ no switch ============
        SW2 = 0; #5;
        chk(0, 0, DIG0, 0, "no switch: all 0");

        // ============ back to SW1, normal flow still works ============
        SW1 = 1; #5;
        fingers(3); hi; lo; sv = 5'b00000; #5;
        fingers(4); hi; lo; sv = 5'b00000; #5;
        fingers(5); hi; chk(1, 0, DIG5, 0, "back in normal: ABRIR, display 5");
        hold_then_clear(1, 0, DIG5);

        $display("=== tb_top: %s (errors = %0d) ===", verdict[errors == 0], errors);
    end
endmodule
