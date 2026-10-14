// SN74HC595-style 8-bit shift register with output latches.
//  SER      serial data in            SRCLK   shift clock (rising edge)
//  RCLK     storage clock (rising)    SRCLR_N async clear of shift register only
//  OE_N     output enable (active low; disabled outputs read 0 here, see output_buffer_8)
//  Q[7:0]   QA..QH parallel outputs   QH_PRIME serial out (last shift stage)
module sn74hc595 (
    input  logic       SER,
    input  logic       SRCLK,
    input  logic       SRCLR_N,
    input  logic       RCLK,
    input  logic       OE_N,
    output logic [7:0] Q,
    output logic       QH_PRIME
);
    wire [7:0] shift_q;
    wire [7:0] store_q;

    shift_reg_8    u_shift  (.SER(SER), .SRCLK(SRCLK), .SRCLR_N(SRCLR_N), .Q(shift_q));
    storage_reg_8  u_store  (.D(shift_q), .RCLK(RCLK), .Q(store_q));
    output_buffer_8 u_out   (.D(store_q), .OE_N(OE_N), .Q(Q));

    assign QH_PRIME = shift_q[7];
endmodule
