// Operation 011: F = A <<< 1  (6-bit rotate left by one, pure wiring)
module alu_rol (
    input  logic [5:0] A,
    output logic [5:0] F
);
    assign F = {A[4:0], A[5]};
endmodule
