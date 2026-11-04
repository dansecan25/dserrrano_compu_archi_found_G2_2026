/*
 * buzzer_controller - buzzer ACTIVO (salida de encendido/apagado)
 *
 * Test, apertura y cierre: sonido continuo (por nivel).
 * Registro: 2 pitidos de SLOT_CYCLES con un silencio intermedio.
 * Valida: 1 pitido de SLOT_CYCLES.
 * Invalida: 3 pitidos de SLOT_CYCLES con silencios intermedios.
 * Inicio de captura (opcode, A, B): 1 pitido de CAP_BEEP_CYCLES.
 *
 * Solo ecuaciones booleanas en la logica sintetizable (sin if/case/?:).
 * Reset sincrono, activo en alto.
 * clk es el reloj de 50 MHz del TOP.
 *
 * Nota: HALF_* se conservan por compatibilidad con el TOP antiguo.
 * El buzzer activo TMB12A05 tiene oscilador interno, por lo que HALF_*
 * no se usan para producir una onda cuadrada.
 */
module buzzer_controller #(
    parameter integer HALF_TEST       = 6250,
    parameter integer HALF_OPEN       = 7143,
    parameter integer HALF_CLOSE      = 5556,
    parameter integer SLOT_CYCLES     = 5_000_000,
    parameter integer CAP_BEEP_CYCLES = 2_500_000,
    parameter integer SLOT_WIDTH =
        $clog2(SLOT_CYCLES + CAP_BEEP_CYCLES + 1)
)(
    input  logic clk,
    input  logic reset,
    input  logic sound_test,
    input  logic sound_opening,
    input  logic sound_closing,
    input  logic sound_registered,
    input  logic sound_valid,
    input  logic sound_invalid,
    input  logic capture_active,
    input  logic capture_opcode,
    input  logic capture_a,
    output logic buzzer_out,
    output logic buzzer_busy
);
    // 1. Aviso al entrar a CAP_OPCODE, o al aceptar opcode/A.
    logic capture_active_prev;
    wire capture_begin;
    wire capture_request;

    always_ff @(posedge clk) begin
        capture_active_prev <= ~reset & capture_active;
    end

    assign capture_begin = capture_active & ~capture_active_prev;
    assign capture_request = capture_begin | capture_opcode | capture_a;

    // 2. Arbitraje de eventos; el aviso de captura tiene prioridad menor.
    logic event_active;
    logic event_registered;
    logic event_valid;
    logic event_invalid;
    logic event_capture;

    wire event_available;
    wire start_invalid;
    wire start_registered;
    wire start_valid;
    wire start_capture;
    wire start_event;

    assign event_available = ~reset & ~event_active & ~sound_test;

    assign start_invalid = event_available & sound_invalid;
    assign start_registered = event_available & ~sound_invalid & sound_registered;
    assign start_valid = event_available & ~sound_invalid &
                         ~sound_registered & sound_valid;
    assign start_capture = event_available & ~sound_invalid &
                           ~sound_registered & ~sound_valid &
                           ~sound_opening & ~sound_closing &
                           capture_request;

    assign start_event = start_invalid | start_registered |
                         start_valid | start_capture;

    // 3. Contador de ranuras. La captura tiene duracion propia.
    logic [SLOT_WIDTH-1:0] slot_count;
    wire  [SLOT_WIDTH-1:0] slot_count_next;
    logic [2:0] slot_index;
    wire  [2:0] slot_index_next;

    wire slot_end;
    wire event_last;
    wire finish_event;
    wire event_active_next;

    assign slot_end = event_active & (
        (event_capture & (slot_count == CAP_BEEP_CYCLES - 1)) |
        (~event_capture & (slot_count == SLOT_CYCLES - 1))
    );

    assign event_last =
        ((event_valid | event_capture) & (slot_index == 3'd0)) |
        (event_registered & (slot_index == 3'd2)) |
        (event_invalid & (slot_index == 3'd4));

    assign finish_event = slot_end & event_last;
    assign event_active_next = ~reset &
        (start_event | (event_active & ~finish_event));

    assign slot_count_next = (slot_count + 1'b1) &
        {SLOT_WIDTH{~reset & event_active & ~slot_end}};

    assign slot_index_next =
        (slot_index + {2'b00, (slot_end & ~event_last)}) &
        {3{~reset & event_active & ~finish_event}};

    always_ff @(posedge clk) begin
        event_active <= event_active_next;
        event_registered <= ~reset &
            (start_registered | (event_registered & ~finish_event));
        event_valid <= ~reset &
            (start_valid | (event_valid & ~finish_event));
        event_invalid <= ~reset &
            (start_invalid | (event_invalid & ~finish_event));
        event_capture <= ~reset &
            (start_capture | (event_capture & ~finish_event));
        slot_count <= slot_count_next;
        slot_index <= slot_index_next;
    end

    // 4. Salida: buzzer activo, alto significa sonido.
    // Los indices pares son intervalos sonoros.
    wire event_tone;
    wire test_selected;
    wire event_selected;
    wire open_selected;
    wire close_selected;
    wire tone_enable;

    assign event_tone = event_active & ~slot_index[0];
    assign test_selected = sound_test & ~reset;
    assign event_selected = ~sound_test & event_tone & ~reset;
    assign open_selected = ~sound_test & ~event_active &
                           sound_opening & ~reset;
    assign close_selected = ~sound_test & ~event_active &
                            ~sound_opening & sound_closing & ~reset;
    assign tone_enable = test_selected | event_selected |
                         open_selected | close_selected;

    assign buzzer_out = ~reset & tone_enable;
    assign buzzer_busy = event_active;
endmodule
