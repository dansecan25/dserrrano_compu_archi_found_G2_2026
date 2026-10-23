`timescale 1ns/1ps
// Full ALU test: every A,B (4096) for each of the 5 operations, plus the
// unused opcodes (must give 0), plus a few directed examples.
// Expected value = reference result mod 8 (truncation to 3 bits).
module tb_alu;
    logic [5:0] A, B;
    logic [2:0] S;
    wire  [2:0] VALOR;
    int   a, b;
    int   e_add = 0, e_sub = 0, e_mul = 0, e_rol = 0, e_ror = 0, e_inv = 0, e_dir = 0;
    int   errors;
    logic [2:0] expv;
    string verdict [2];

    alu dut (.A(A), .B(B), .S(S), .VALOR(VALOR));

    task automatic example(input logic [5:0] a_i, input logic [5:0] b_i,
                           input logic [2:0] s_i, input logic [2:0] expv_i,
                           input string note);
        logic bad;
        A = a_i; B = b_i; S = s_i; #1;
        bad = (VALOR !== expv_i);
        e_dir = e_dir + bad;
        $display("S=%b A=%0d B=%0d | VALOR=%0d exp=%0d | ok=%b | %s",
                 S, A, B, VALOR, expv_i, ~bad, note);
    endtask

    initial begin
        verdict[0] = "FAILED"; verdict[1] = "PASSED";

        S = 3'b000;                                    // ADD
        for (a = 0; a < 64; a = a + 1)
            for (b = 0; b < 64; b = b + 1) begin
                A = a; B = b; #1;
                expv = a + b;
                e_add = e_add + (VALOR !== expv);
            end

        S = 3'b001;                                    // SUB (negative wraps)
        for (a = 0; a < 64; a = a + 1)
            for (b = 0; b < 64; b = b + 1) begin
                A = a; B = b; #1;
                expv = a - b;
                e_sub = e_sub + (VALOR !== expv);
            end

        S = 3'b010;                                    // MUL
        for (a = 0; a < 64; a = a + 1)
            for (b = 0; b < 64; b = b + 1) begin
                A = a; B = b; #1;
                expv = a * b;
                e_mul = e_mul + (VALOR !== expv);
            end

        S = 3'b011;                                    // ROL (A, 6-bit)
        for (a = 0; a < 64; a = a + 1)
            for (b = 0; b < 64; b = b + 1) begin
                A = a; B = b; #1;
                expv = (a << 1) | (a >> 5);
                e_rol = e_rol + (VALOR !== expv);
            end

        S = 3'b100;                                    // ROR (A, 6-bit)
        for (a = 0; a < 64; a = a + 1)
            for (b = 0; b < 64; b = b + 1) begin
                A = a; B = b; #1;
                expv = (a >> 1) | (a << 5);
                e_ror = e_ror + (VALOR !== expv);
            end

        for (S = 3'b101; S != 3'b000; S = S + 1) begin  // 101,110,111 -> 0
            for (a = 0; a < 64; a = a + 1)
                for (b = 0; b < 64; b = b + 1) begin
                    A = a; B = b; #1;
                    e_inv = e_inv + (VALOR !== 3'b000);
                end
        end

        // directed examples (expected values worked out by hand)
        example(6'd7,  6'd1,  3'b000, 3'd0, "7+1=8 wraps to 0");
        example(6'd63, 6'd63, 3'b000, 3'd6, "63+63=126 -> 126 mod 8 = 6");
        example(6'd5,  6'd3,  3'b001, 3'd2, "5-3=2");
        example(6'd2,  6'd5,  3'b001, 3'd5, "2-5=-3 wraps to 5");
        example(6'd7,  6'd3,  3'b010, 3'd5, "7*3=21 -> 5");
        example(6'd63, 6'd63, 3'b010, 3'd1, "63*63=3969 -> 1");
        example(6'b100001, 6'd0, 3'b011, 3'd3, "ROL 100001 = 000011 -> 3");
        example(6'b000011, 6'd0, 3'b100, 3'd1, "ROR 000011 = 100001 -> 1");
        example(6'd9,  6'd9,  3'b111, 3'd0, "unused opcode -> 0");

        errors = e_add + e_sub + e_mul + e_rol + e_ror + e_inv + e_dir;
        $display("ADD errors=%0d  SUB=%0d  MUL=%0d  ROL=%0d  ROR=%0d  unused=%0d  directed=%0d",
                 e_add, e_sub, e_mul, e_rol, e_ror, e_inv, e_dir);
        $display("=== tb_alu: %s (errors = %0d) ===", verdict[errors == 0], errors);
    end
endmodule
