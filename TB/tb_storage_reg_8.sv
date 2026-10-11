`timescale 1ns/1ps
// Tests storage_reg_8: loads only on RCLK rising edge.
module tb_storage_reg_8;
    logic [7:0] D;
    logic       RCLK;
    wire  [7:0] Q;
    int         errors = 0;
    int         i;
    string      verdict [2];

    storage_reg_8 dut (.D(D), .RCLK(RCLK), .Q(Q));

    task automatic expect_q(input logic [7:0] e, input string note);
        logic bad;
        bad = (Q !== e);
        errors = errors + bad;
        $display("%0t | RCLK=%b D=%b | Q=%b | exp=%b | ok=%b | %s",
                 $time, RCLK, D, Q, e, ~bad, note);
    endtask

    initial begin
        verdict[0] = "FAILED"; verdict[1] = "PASSED";
        RCLK = 0; D = 8'hA5; #5;
        RCLK = 1; #5;
        expect_q(8'hA5, "rising edge loads A5");
        D = 8'h3C; #5;
        expect_q(8'hA5, "D changes while RCLK=1: holds");
        RCLK = 0; #5;
        expect_q(8'hA5, "falling edge: holds");
        D = 8'hFF; #5;
        expect_q(8'hA5, "D changes while RCLK=0: holds");
        RCLK = 1; #5;
        expect_q(8'hFF, "rising edge loads FF");
        RCLK = 0; #5;

        for (i = 0; i < 8; i = i + 1) begin
            D = 8'h01 << i; #5;
            RCLK = 1; #5;
            expect_q(D, $sformatf("walking one, bit %0d", i));
            RCLK = 0; #5;
        end
        for (i = 0; i < 8; i = i + 1) begin
            D = ~(8'h01 << i); #5;
            RCLK = 1; #5;
            expect_q(D, $sformatf("walking zero, bit %0d", i));
            RCLK = 0; #5;
        end

        $display("=== tb_storage_reg_8: %s (errors = %0d) ===", verdict[errors == 0], errors);
    end
endmodule
