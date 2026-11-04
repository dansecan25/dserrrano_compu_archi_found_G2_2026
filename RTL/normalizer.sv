// Normalises any result to 0..7 with circular wrap-around (value mod 8):
// keep only the 3 least-significant bits. Works for negative (two's
// complement) results too, e.g. -3 -> 5.
module normalizer (
    input  logic [11:0] F,
    output logic [2:0]  VALOR
);
    assign VALOR = F[2:0];
endmodule
