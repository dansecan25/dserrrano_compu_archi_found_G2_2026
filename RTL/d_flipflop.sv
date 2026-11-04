
/*
 * Modulo: d_flipflop
 *
 * Flip-flop tipo D de flanco positivo.
 * Reset asincrono activo en bajo.
 *
 * Implementacion sintetizable mediante FF nativo.
 * Conserva la interfaz original.
 *
 * CLR_N = 0 -> Q = 0
 * CLR_N = 1 -> Q captura D en flanco positivo.
 */

module d_flipflop (
    input  logic D,
    input  logic CLK,
    input  logic CLR_N,
    output logic Q,
    output logic QN
);

    always_ff @(posedge CLK or negedge CLR_N) begin
        if (!CLR_N)
            Q <= 1'b0;
        else
            Q <= D;
    end

    assign QN = ~Q;

endmodule
