
/*
 * Modulo: movement_timer
 *
 * Cuenta ciclos de CLK mientras enable=1.
 * Genera done al completar MOVEMENT_CYCLES.
 *
 * Si enable=0, el contador vuelve a cero.
 * Reset sincrono activo en alto.
 *
 * básicamente cuenta mientras el motor esta activo
 */

module movement_timer #(
    parameter integer MOVEMENT_CYCLES = 50_000_000,
    parameter integer WIDTH = $clog2(MOVEMENT_CYCLES + 1)
)(
    input  logic clk,
    input  logic reset,
    input  logic enable,

    output logic done
);

    logic [WIDTH-1:0] count;
    wire  [WIDTH-1:0] count_next;

    wire terminal_count;
    wire count_en;

    // Detecta el ultimo ciclo del intervalo.
    assign terminal_count =
        (count == MOVEMENT_CYCLES - 1);

    // DONE se activa durante el ultimo ciclo.
    assign done = enable & ~reset & terminal_count;

    // Permite contar solamente durante movimiento.
    assign count_en = ~reset & enable & ~done;

    // Ecuacion estructural del proximo estado.
    assign count_next =
        (count + 1'b1) & {WIDTH{count_en}};

    always_ff @(posedge clk) begin
        count <= count_next;
    end

endmodule
