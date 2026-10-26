// ============================================================
// password_equal
// Descripcion:
//   Comparador estructural de dos contrasenas de 9 bits.
//
//   Cada contrasena contiene 3 digitos de 3 bits:
//     [8:6] = primer digito
//     [5:3] = segundo digito
//     [2:0] = tercer digito
//
//   La salida equal vale 1 cuando todos los bits coinciden.
//
// Implementacion:
//   - 9 operaciones XOR
//   - 9 inversiones logicas
//   - Reduccion AND de los 9 resultados
// ============================================================

module password_equal (
    input  logic [8:0] password_in,
    input  logic [8:0] password_stored,
    output logic       equal
);

    // XOR indica diferencias entre bits:
    // 0 = bits iguales
    // 1 = bits diferentes
    wire [8:0] diff;

    assign diff = password_in ^ password_stored;

    // Invirtiendo diff para que el AND devuelva 1 si todos son 1.
    // La reduccion AND sera 1 solo si los 9 bits coinciden.
    assign equal = &(~diff);

endmodule