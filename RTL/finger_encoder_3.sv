
/*
 * Modulo: finger_encoder_3
 *
 * Descripcion:
 *   Convierte las salidas del decodificador de
 *   dedos en un valor binario de 3 bits.
 *
 *   digit_valid  = 1 para los valores 0 a 5.
 *   opcode_valid = 1 para los valores 0 a 4.
 *
 *   Se asume que finger_decoder_6 entrega
 *   como maximo una salida Y activa.
 */

module finger_encoder_3 (
    input  logic Y0, Y1, Y2, Y3, Y4, Y5,

    output logic [2:0] digit_value,
    output logic       digit_valid,
    output logic       opcode_valid
);

    // Codificacion binaria de los valores 0 a 5.
    assign digit_value[2] = Y4 | Y5;
    assign digit_value[1] = Y2 | Y3;
    assign digit_value[0] = Y1 | Y3 | Y5;

    // Se reconoce al menos un valor valido.
    assign digit_valid =
        Y0 | Y1 | Y2 | Y3 | Y4 | Y5;

    // Los OpCodes permitidos son 0, 1, 2, 3 y 4.
    // El valor 5 se acepta como operando,
    // pero no como operacion de la ALU.
    assign opcode_valid =
        Y0 | Y1 | Y2 | Y3 | Y4;

endmodule
