
/*
 * password_comparator
 *
 * Descripcion:
 *   Compara una contrasena ingresada con un banco de
 *   10 contrasenas almacenadas. (PROVISIONAL)
 *
 *   Cada contrasena es de 9 bits (3 digitos de 3 bits).
 *
 *   Para cada posicion de memoria se verifica:
 *     1. Si la contrasena coincide.
 *     2. Si la posicion contiene una contrasena valida. (para evitar problemas con 000 y falsos positivos)
 *     3. Si corresponde a apertura o cierre.
 *
 *   password_type = 1 -> Apertura
 *   password_type = 0 -> Cierre
 *   valid         = 1 -> Posicion ocupada
 *
 */

module password_comparator (
    input  logic [8:0]  password_in,
    input  logic [89:0] stored_passwords, // bus de 90 bits: 10 contraseñas * 9 bits c/u
    input  logic [9:0]  valid,
    input  logic [9:0]  password_type,

    output logic ABRIR,
    output logic CERRAR
);

    // Resultado individual de los 10 comparadores.
    wire [9:0] eq;

    // Coincidencias autorizadas segun el tipo.
    wire [9:0] match_abrir;
    wire [9:0] match_cerrar;


    // Comparadores de igualdad
     
    // Cada instancia recibe password_in y una posicion
    // diferente del bus stored_passwords.

    password_equal comparator_0 (
        .password_in(password_in),
        .password_stored(stored_passwords[8:0]),
        .equal(eq[0])
    );

    password_equal comparator_1 (
        .password_in(password_in),
        .password_stored(stored_passwords[17:9]),
        .equal(eq[1])
    );

    password_equal comparator_2 (
        .password_in(password_in),
        .password_stored(stored_passwords[26:18]),
        .equal(eq[2])
    );

    password_equal comparator_3 (
        .password_in(password_in),
        .password_stored(stored_passwords[35:27]),
        .equal(eq[3])
    );

    password_equal comparator_4 (
        .password_in(password_in),
        .password_stored(stored_passwords[44:36]),
        .equal(eq[4])
    );

    password_equal comparator_5 (
        .password_in(password_in),
        .password_stored(stored_passwords[53:45]),
        .equal(eq[5])
    );

    password_equal comparator_6 (
        .password_in(password_in),
        .password_stored(stored_passwords[62:54]),
        .equal(eq[6])
    );

    password_equal comparator_7 (
        .password_in(password_in),
        .password_stored(stored_passwords[71:63]),
        .equal(eq[7])
    );

    password_equal comparator_8 (
        .password_in(password_in),
        .password_stored(stored_passwords[80:72]),
        .equal(eq[8])
    );

    password_equal comparator_9 (
        .password_in(password_in),
        .password_stored(stored_passwords[89:81]),
        .equal(eq[9])
    );
 
    // clasificacion de las coincidencias 

    // Una coincidencia autoriza apertura solamente si:
    // - Los 9 bits coinciden.
    // - La posicion esta ocupada.
    // - El tipo de contrasena es apertura (1).
    assign match_abrir = eq & valid & password_type;

    // Una coincidencia autoriza cierre solamente si:
    // - Los 9 bits coinciden.
    // - La posicion esta ocupada.
    // - El tipo de contrasena es cierre (0).
    assign match_cerrar = eq & valid & (~password_type);

	 
    // Salidas del banco de comparadores
    // Basta una coincidencia valida para activar la salida.
    assign ABRIR  = |match_abrir;
    assign CERRAR = |match_cerrar;

endmodule
