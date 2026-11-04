// Operation 100: F = A >>> 1  (6-bit rotate right by one, pure wiring)
module alu_ror (
    input  logic [5:0] A,
    output logic [5:0] F
);
    assign F = {A[0], A[5:1]};
endmodule
