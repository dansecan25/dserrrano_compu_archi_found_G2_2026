// Finger-count decoder (the 5 Y equations from the table).
// S1..S5 = thermometer code of the pressed buttons, Yn = "exactly n fingers".
//   Y1 = S1 ~S2 ~S3 ~S4 ~S5      Y2 = S1 S2 ~S3 ~S4 ~S5
//   Y3 = S1 S2 S3 ~S4 ~S5        Y4 = S1 S2 S3 S4 ~S5
//   Y5 = S1 S2 S3 S4 S5
// Structural: only AND / NOT.
module finger_decoder (
    input  logic S1, S2, S3, S4, S5,
    output logic Y1, Y2, Y3, Y4, Y5
);
    wire nS1 = ~S1;
    wire nS2 = ~S2;
    wire nS3 = ~S3;
    wire nS4 = ~S4;
    wire nS5 = ~S5;

    assign Y1 = S1 & nS2 & nS3 & nS4 & nS5;
    assign Y2 = S1 & S2  & nS3 & nS4 & nS5;
    assign Y3 = S1 & S2  & S3  & nS4 & nS5;
    assign Y4 = S1 & S2  & S3  & S4  & nS5;
    assign Y5 = S1 & S2  & S3  & S4  & S5;
endmodule
