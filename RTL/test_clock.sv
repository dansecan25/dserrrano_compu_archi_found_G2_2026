module test_clock (
    input  wire CLK,
    output wire LED_CLK
);

    assign LED_CLK = CLK;

endmodule