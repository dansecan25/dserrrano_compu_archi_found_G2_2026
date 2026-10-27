
/*
 * Modulo: password_slot
 *
 * Descripcion:
 *   Almacena una contrasena de 9 bits, su tipo y
 *   un bit que indica si la posicion esta ocupada.
 *
 * Operaciones: (las operaciones son controladas en password_memory.sv)
 *   write_en  -> Guarda una contrasena nueva.
 *   delete_en -> Invalida la posicion.
 *   change_en -> Cambia el tipo de la contrasena.
 *   clear     -> Invalida la posicion (borrado sincrono).
 *
 *   type_in = 1 -> Apertura
 *   type_in = 0 -> Cierre
 *
 * Todas las actualizaciones ocurren en el flanco
 * positivo del reloj.
 *
 */

module password_slot (
    input  logic       clk,
    input  logic       clear,

    input  logic       write_en,
    input  logic       delete_en,
    input  logic       change_en,

    input  logic [8:0] password_in,
    input  logic       type_in,

    output logic [8:0] password_out,
    output logic       type_out,
    output logic       valid_out
);

    // Valores que capturaran los registros.
    wire [8:0] password_next;
    wire       type_next;
    wire       valid_next;


    // Registro de contrasena
    // Solo cambia cuando se escribe una nueva contrasena.

    assign password_next =
        (password_out & {9{~write_en}}) |
        (password_in  & {9{ write_en}});

    // Registro de tipo
    // Se actualiza al registrar o cambiar el tipo.

    wire type_enable;

    assign type_enable = write_en | change_en;

    assign type_next =
        (type_out & ~type_enable) |
        (type_in  &  type_enable);


    // Registro de validez
    // Escritura: valid = 1.
    // Eliminacion o clear: valid = 0.
    // Sin operacion: conserva su valor.

    assign valid_next =
        ~clear & ~delete_en & (write_en | valid_out);

    // Almacenamiento secuencial
    // Los flip-flops capturan los valores calculados
    // por las ecuaciones anteriores.

    always_ff @(posedge clk) begin
        password_out <= password_next;
        type_out     <= type_next;
        valid_out    <= valid_next;
    end

endmodule
