`timescale 1ns/1ps

module not_engine (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [63:0] in_data,
    output wire [63:0] out_data
);

    reg [63:0] pipe [0:9];
    integer i;

    always @(posedge clk) begin
        if (!rst_n) begin
            for (i = 0; i < 10; i = i + 1) begin
                pipe[i] <= 64'd0;
            end
        end else begin
            pipe[0] <= ~in_data;

            for (i = 1; i < 10; i = i + 1) begin
                pipe[i] <= pipe[i-1];
            end
        end
    end

    assign out_data = pipe[9];

endmodule