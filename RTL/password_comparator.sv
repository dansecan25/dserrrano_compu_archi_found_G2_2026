
/*
 * password_comparator
 *
 * Descripcion:
 *   Compara una contrasena ingresada con N contrasenas
 *   almacenadas mediante comparadores en paralelo.
 *
 *   Cada contrasena ocupa 9 bits.
 *   N determina la capacidad durante la elaboracion.
 *
 *   Para cada posicion se verifica:
 *     - Coincidencia de contrasena.
 *     - Validez de la posicion. (para evitar problemas con 000 ej)
 *     - Tipo: apertura (1) o cierre (0).
 *
 * Implementacion:
 *   - N instancias de password_equal mediante generate. (Pregunta al profe 26 de oct 16:48)
 */

module password_comparator #(
	//Este parametro limita la cantidad de comparadores que el sistema puede soportar en paralelo,
	// se puede ampliar al máximo número de contraseñas posibles (6^3= 216)
    parameter integer N = 10 
)(
    input  logic [8:0]   password_in,
    input  logic [9*N-1:0] stored_passwords,
    input  logic [N-1:0] valid,
    input  logic [N-1:0] password_type,

    output logic ABRIR,
    output logic CERRAR,
	 output logic [N-1:0] found //esta salida permite saber en que posición está la contraseña válida, sin importar el tipo
);

    // Resultados individuales de los comparadores.
    wire [N-1:0] eq;

    // Coincidencias autorizadas segun el tipo.
    wire [N-1:0] match_abrir;
    wire [N-1:0] match_cerrar;
	 assign found = eq & valid;

	 
	 
    // Generacion de N comparadores en paralelo
    genvar i;

    generate
        for (i = 0; i < N; i = i + 1) begin : GEN_COMPARATORS

            password_equal comparator (
                .password_in(password_in),
                .password_stored(stored_passwords[9*i +: 9]),
                .equal(eq[i])
            );

        end
    endgenerate


    // Validacion y clasificacion
	 
    // Apertura: coincidencia, posicion valida y tipo 1.
    assign match_abrir = eq & valid & password_type;

    // Cierre: coincidencia, posicion valida y tipo 0.
    assign match_cerrar = eq & valid & (~password_type);


    // Salidas finales
    // OR de reduccion: basta una coincidencia autorizada.
    assign ABRIR  = |match_abrir;
    assign CERRAR = |match_cerrar;

endmodule
