`timescale 1ns/1ps

module not_engine (
    input  wire [63:0] in_data,
    output wire [63:0] out_data
);

    assign out_data = ~in_data;


endmodule