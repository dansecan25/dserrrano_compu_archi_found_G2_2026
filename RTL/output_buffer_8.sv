// Output-enable stage. OE_N=0 -> Q=D. OE_N=1 -> outputs forced to 0.
// NOTE: the real 74HC595 goes high-impedance (Z). Z cannot be expressed with
// only AND/OR/NOT/XOR, so "disabled" is modelled as all zeros.
module output_buffer_8 (
    input  logic [7:0] D,
    input  logic       OE_N,
    output logic [7:0] Q
);
    wire en = ~OE_N;
    assign Q = D & {8{en}};
endmodule
