`timescale 1ns/1ps

/* TB de integracion: usa temporizaciones reducidas, sin alterar ecuaciones RTL.
 * Comprueba registro, uso real de memoria, ALU, movimiento, reset y prueba.
 */
module tb_top;
    localparam integer N=4;
    logic CLK_50=0, RST_N=0;
    logic S0=0,S1=0,S2=0,S3=0,S4=0,S5=0;
    logic SW1=0,SW2=0,SW3=0,SW_TYPE=0,BTN_TEST_N=1;
    wire PWM_OUT, MOTOR_OPEN, MOTOR_CLOSE, BUZZER_OUT, TEST_RUNNING;
    wire SEG_A,SEG_B,SEG_C,SEG_D,SEG_E,SEG_F,SEG_G;
    wire LED_CLK,LED_ABRIR,LED_CERRAR;
    wire LED_Y0,LED_Y1,LED_Y2,LED_Y3,LED_Y4,LED_Y5;
    integer passed=0,errors=0;

    always #5 CLK_50=~CLK_50;

    top #(
        .N_PASSWORDS(N),
        .SAMPLE_CYCLES(5),
        .MOVEMENT_CYCLES(15),
        .PWM_CLK_HALF(2),
        .TEST_CLK_HALF(2),
        .BUZZ_HALF_TEST(2),
        .BUZZ_HALF_OPEN(3),
        .BUZZ_HALF_CLOSE(4),
        .BUZZ_SLOT_CYCLES(3)
    ) dut (
        .CLK_50(CLK_50),.RST_N(RST_N),
        .S0(S0),.S1(S1),.S2(S2),.S3(S3),.S4(S4),.S5(S5),
        .SW1(SW1),.SW2(SW2),.SW3(SW3),.SW_TYPE(SW_TYPE),
        .BTN_TEST_N(BTN_TEST_N),
        .PWM_OUT(PWM_OUT),.MOTOR_OPEN(MOTOR_OPEN),
        .MOTOR_CLOSE(MOTOR_CLOSE),.BUZZER_OUT(BUZZER_OUT),
        .TEST_RUNNING(TEST_RUNNING),
        .SEG_A(SEG_A),.SEG_B(SEG_B),.SEG_C(SEG_C),.SEG_D(SEG_D),
        .SEG_E(SEG_E),.SEG_F(SEG_F),.SEG_G(SEG_G),
        .LED_CLK(LED_CLK),.LED_ABRIR(LED_ABRIR),
        .LED_CERRAR(LED_CERRAR),
        .LED_Y0(LED_Y0),.LED_Y1(LED_Y1),.LED_Y2(LED_Y2),
        .LED_Y3(LED_Y3),.LED_Y4(LED_Y4),.LED_Y5(LED_Y5)
    );

    task automatic check(input logic actual, input logic expected,
                         input string name);
        begin
            #1;
            if (actual !== expected) begin
                $display("FAIL: %s | actual=%b esperado=%b",name,actual,expected);
                errors=errors+1;
            end else begin
                $display("PASS: %s",name);
                passed=passed+1;
            end
        end
    endtask

    task automatic check3(input logic [2:0] actual,
                          input logic [2:0] expected,input string name);
        begin
            #1;
            if(actual !== expected) begin
                $display("FAIL: %s | actual=%b esperado=%b",name,actual,expected);
                errors=errors+1;
            end else begin
                $display("PASS: %s",name);
                passed=passed+1;
            end
        end
    endtask

    task automatic sensors_digit(input integer value);
        begin
            // Patron {S0,S1,S2,S3,S4,S5}. Se asigna en flanco negativo.
            @(negedge CLK_50);
            {S0,S1,S2,S3,S4,S5}=6'b000000;
            case(value)
              0: {S0,S1,S2,S3,S4,S5}=6'b100000;
              1: {S0,S1,S2,S3,S4,S5}=6'b010000;
              2: {S0,S1,S2,S3,S4,S5}=6'b011000;
              3: {S0,S1,S2,S3,S4,S5}=6'b011100;
              4: {S0,S1,S2,S3,S4,S5}=6'b011110;
              5: {S0,S1,S2,S3,S4,S5}=6'b011111;
            endcase
        end
    endtask

    // Verifica el paso de cada estado de captura usando entradas fisicas.
    task automatic enter_three_digits(input integer op,
                                      input integer a,input integer b);
        begin
            wait (dut.u_fsm.state[1] === 1'b1);
            sensors_digit(op);
            wait (dut.u_fsm.state[2] === 1'b1);
            sensors_digit(a);
            wait (dut.u_fsm.state[3] === 1'b1);
            sensors_digit(b);
            wait (dut.u_fsm.state[4] === 1'b1);
            @(negedge CLK_50);
            {S0,S1,S2,S3,S4,S5}=6'b000000;
        end
    endtask

    task automatic register_password(input integer op,
                                     input integer a,input integer b,
                                     input logic type_value);
        begin
            @(negedge CLK_50);
            SW_TYPE=type_value;
            SW2=1;
            wait(dut.u_fsm.state[1] === 1'b1);
            @(negedge CLK_50); SW2=0;
            enter_three_digits(op,a,b);
            wait(dut.u_fsm.state[7] === 1'b1);
            check(dut.sound_registered,1,"Registro: emite evento de exito");
            wait(dut.u_fsm.state[0] === 1'b1);
        end
    endtask

    task automatic present_normal(input integer op,
                                  input integer a,input integer b);
        begin
            @(negedge CLK_50); SW1=1;
            wait(dut.u_fsm.state[1] === 1'b1);
            @(negedge CLK_50); SW1=0;
            enter_three_digits(op,a,b);
        end
    endtask

    initial begin
        #200000;
        $fatal(1,"TIMEOUT: la integracion quedo detenida en un estado");
    end

    initial begin
        $display("=================================");
        $display("TB INTEGRADO: TOP");
        $display("=================================");

        repeat(6) @(posedge CLK_50);
        @(negedge CLK_50); RST_N=1;
        wait(dut.u_fsm.state[0] === 1'b1);
        check(dut.door_open,0,"Reset: puerta inicialmente cerrada");
        check(MOTOR_OPEN,0,"Reset: sin orden de apertura");
        check(MOTOR_CLOSE,0,"Reset: sin orden de cierre");

        // Contraseña {2,3,5} => multiplicacion = 15 mod 8 = 7.
        register_password(2,3,5,1);
        check(dut.valid[0],1,"Memoria: primera ranura valida");
        check(dut.password_type[0],1,"Memoria: tipo abrir");

        present_normal(2,3,5);
        wait(dut.u_fsm.state[12] === 1'b1);
        check(MOTOR_OPEN,1,"Contraseña válida: motor abre");
        check(MOTOR_CLOSE,0,"Apertura: cierre inactivo");
        check3(dut.alu_valor,3'd7,"ALU: 3*5 mod 8 = 7");
        wait(dut.u_fsm.state[0] === 1'b1);
        check(dut.door_open,1,"Movimiento terminado: puerta abierta");
        check(MOTOR_OPEN,0,"Movimiento terminado: motor apagado");

        // Contraseña {0,1,1} => suma = 2; tipo cerrar.
        register_password(0,1,1,0);
        check(dut.valid[1],1,"Memoria: segunda ranura valida");
        check(dut.password_type[1],0,"Memoria: tipo cerrar");

        present_normal(0,1,1);
        wait(dut.u_fsm.state[13] === 1'b1);
        check(MOTOR_CLOSE,1,"Contraseña válida: motor cierra");
        check3(dut.alu_valor,3'd2,"ALU: 1+1 = 2");
        wait(dut.u_fsm.state[0] === 1'b1);
        check(dut.door_open,0,"Movimiento terminado: puerta cerrada");

        // Contraseña desconocida; no debe encender motor.
        present_normal(1,4,2);
        wait(dut.u_fsm.state[11] === 1'b1);
        check(dut.sound_invalid,1,"Desconocida: evento invalido");
        check(MOTOR_OPEN,0,"Desconocida: no abre");
        check(MOTOR_CLOSE,0,"Desconocida: no cierra");
        wait(dut.u_fsm.state[0] === 1'b1);

        // Prueba existente: se arranca con SW3 y BTN_TEST_N.
        @(negedge CLK_50); SW3=1; BTN_TEST_N=0;
        wait(dut.u_fsm.state[14] === 1'b1);
        check(dut.test_start_pulse,1,"Prueba: pulso desde MEF");
        @(negedge CLK_50); BTN_TEST_N=1;
        wait(TEST_RUNNING === 1'b1);
        check(dut.sound_test,1,"Prueba: solicita sonido continuo");
        wait(TEST_RUNNING === 1'b0);
        wait(dut.u_fsm.state[0] === 1'b1);
        check(dut.door_open,0,"Prueba: posicion final cerrada");
        @(negedge CLK_50); SW3=0;

        // Reset general invalida el banco de contrasenas.
        @(negedge CLK_50); RST_N=0;
        repeat(3) @(posedge CLK_50);
        #1;
        check(dut.valid[0],0,"Reset general: borra ranura 0");
        check(dut.valid[1],0,"Reset general: borra ranura 1");
        check(PWM_OUT,0,"Reset general: inhibe PWM externo");

        $display("=================================");
        $display("PASS: %0d  FAIL: %0d",passed,errors);
        if(errors == 0)
            $display("TOP: TODAS LAS PRUEBAS PASARON");
        else
            $fatal(1,"TOP: pruebas fallidas");
        $finish;
    end
endmodule
