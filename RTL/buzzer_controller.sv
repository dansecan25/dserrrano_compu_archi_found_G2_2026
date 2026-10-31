
/*
 * Modulo: buzzer_controller
 *
 * Genera seis indicaciones sonoras:
 *  - Prueba: tono continuo.
 *  - Apertura: tono continuo.
 *  - Cierre: tono continuo.
 *  - Registro: dos pitidos.
 *  - Valida: un pitido.
 *  - Invalida: tres pitidos.
 *
 * Los eventos breves se almacenan internamente.
 * Las señales continuas se mantienen por nivel.
 *
 * Implementacion:
 *  - Ecuaciones booleanas.
 *  - Contadores y flip-flops mediante always_ff.
 *  - Sin if, case ni operador ternario.
 *
 * reset sincrono activo en alto.
 */

module buzzer_controller #(
    parameter integer HALF_TEST  = 6250,       // 4 kHz
    parameter integer HALF_OPEN  = 7143,       // ~3.5 kHz
    parameter integer HALF_CLOSE = 5556,       // ~4.5 kHz
    parameter integer SLOT_CYCLES = 5_000_000, // 100 ms
    parameter integer SLOT_WIDTH = $clog2(SLOT_CYCLES + 1)
)(
    input  logic clk,
    input  logic reset,

    input  logic sound_test,
    input  logic sound_opening,
    input  logic sound_closing,

    input  logic sound_registered,
    input  logic sound_valid,
    input  logic sound_invalid,

    output logic buzzer_out,
    output logic buzzer_busy
);

    // ==================================================
    // 1. Seleccion y almacenamiento de eventos
    // ==================================================

    logic event_active;
    logic event_registered;
    logic event_valid;
    logic event_invalid;

    wire start_registered;
    wire start_valid;
    wire start_invalid;
    wire start_event;

    // Se aceptan eventos nuevos si no hay otro
    // evento activo ni metodo de prueba.
    wire event_available;

    assign event_available =
        ~reset & ~event_active & ~sound_test;

    // Prioridad: invalida > registrada > valida.
    assign start_invalid =
        event_available & sound_invalid;

    assign start_registered =
        event_available & ~sound_invalid &
        sound_registered;

    assign start_valid =
        event_available & ~sound_invalid &
        ~sound_registered & sound_valid;

    assign start_event =
        start_invalid | start_registered | start_valid;

    // ==================================================
    // 2. Contador de intervalos de los eventos
    // ==================================================

    logic [SLOT_WIDTH-1:0] slot_count;
    wire  [SLOT_WIDTH-1:0] slot_count_next;

    logic [2:0] slot_index;
    wire  [2:0] slot_index_next;

    wire slot_end;
    wire event_last;
    wire finish_event;
    wire event_active_next;

    assign slot_end =
        event_active &
        (slot_count == SLOT_CYCLES - 1);

    // Valida: 1 intervalo  (indice final 0).
    // Registro: 3 intervalos (indice final 2).
    // Invalida: 5 intervalos (indice final 4).
    assign event_last =
        (event_valid & (slot_index == 3'd0)) |
        (event_registered & (slot_index == 3'd2)) |
        (event_invalid & (slot_index == 3'd4));

    assign finish_event = slot_end & event_last;

    assign event_active_next =
        ~reset &
        (start_event | (event_active & ~finish_event));

    // Al iniciar un evento o terminar cada intervalo,
    // el contador vuelve a cero.
    assign slot_count_next =
        (slot_count + 1'b1) &
        {SLOT_WIDTH{
            ~reset & event_active & ~slot_end
        }};

    // Avanza de intervalo si no es el ultimo.
    assign slot_index_next =
        (slot_index +
            {2'b00, (slot_end & ~event_last)}) &
        {3{
            ~reset & event_active & ~finish_event
        }};

    // ==================================================
    // 3. Registros del evento
    // ==================================================

    always_ff @(posedge clk) begin
        event_active <= event_active_next;

        event_registered <=
            ~reset &
            (start_registered |
            (event_registered & ~finish_event));

        event_valid <=
            ~reset &
            (start_valid |
            (event_valid & ~finish_event));

        event_invalid <=
            ~reset &
            (start_invalid |
            (event_invalid & ~finish_event));

        slot_count <= slot_count_next;
        slot_index <= slot_index_next;
    end

    // Intervalos 0, 2 y 4 producen sonido.
    // Intervalos 1 y 3 son silencios.
    wire event_tone;

    assign event_tone =
        event_active & ~slot_index[0];

    assign buzzer_busy = event_active;

    // ==================================================
    // 4. Prioridad de tonos continuos
    // ==================================================

    wire test_selected;
    wire event_selected;
    wire open_selected;
    wire close_selected;

    assign test_selected =
        sound_test & ~reset;

    assign event_selected =
        ~sound_test & event_tone & ~reset;

    assign open_selected =
        ~sound_test & ~event_active &
        sound_opening & ~reset;

    assign close_selected =
        ~sound_test & ~event_active &
        ~sound_opening & sound_closing & ~reset;

    // Los eventos breves utilizan el tono de 4 kHz.
    wire tone_test;
    wire tone_open;
    wire tone_close;
    wire tone_enable;

    assign tone_test =
        test_selected | event_selected;

    assign tone_open = open_selected;
    assign tone_close = close_selected;

    assign tone_enable =
        tone_test | tone_open | tone_close;

    // ==================================================
    // 5. Generador de onda cuadrada
    // ==================================================

    // 16 bits son suficientes para los medios
    // periodos configurados por defecto.
    logic [15:0] tone_count;
    wire  [15:0] tone_count_next;

    logic tone_q;
    wire tone_q_next;

    wire [15:0] selected_half;
    wire tone_terminal;

    // Seleccion de frecuencia mediante mascaras.
    assign selected_half =
        (16'(HALF_TEST)  & {16{tone_test}}) |
        (16'(HALF_OPEN)  & {16{tone_open}}) |
        (16'(HALF_CLOSE) & {16{tone_close}});

    assign tone_terminal =
        tone_enable &
        (tone_count >= selected_half - 16'd1);

    // Contador de medio periodo.
    assign tone_count_next =
        (tone_count + 16'd1) &
        {16{
            ~reset & tone_enable & ~tone_terminal
        }};

    // Flip-flop que alterna el nivel del buzzer.
    assign tone_q_next =
        ~reset & tone_enable &
        (tone_q ^ tone_terminal);

    always_ff @(posedge clk) begin
        tone_count <= tone_count_next;
        tone_q <= tone_q_next;
    end

    // En silencio se fuerza el pin a cero.
    assign buzzer_out =
        ~reset & tone_enable & tone_q;

endmodule
