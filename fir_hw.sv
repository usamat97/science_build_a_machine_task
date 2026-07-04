`timescale 1ns/1ps

module fir_hw (
    input  wire         clk,
    input  wire         rst_n,

    input  wire         in_valid,
    input  wire         in_last,
    input  wire [63:0]  in_data,

    output reg          out_valid,
    output reg          out_last,
    output reg  [127:0] out_data
);

    localparam int TAPS = 16;

    localparam signed [15:0] C0  = 16'sd3;
    localparam signed [15:0] C1  = -16'sd2;
    localparam signed [15:0] C2  = 16'sd5;
    localparam signed [15:0] C3  = 16'sd7;
    localparam signed [15:0] C4  = -16'sd1;
    localparam signed [15:0] C5  = 16'sd4;
    localparam signed [15:0] C6  = -16'sd3;
    localparam signed [15:0] C7  = 16'sd6;
    localparam signed [15:0] C8  = 16'sd2;
    localparam signed [15:0] C9  = -16'sd5;
    localparam signed [15:0] C10 = 16'sd1;
    localparam signed [15:0] C11 = 16'sd3;
    localparam signed [15:0] C12 = -16'sd4;
    localparam signed [15:0] C13 = 16'sd2;
    localparam signed [15:0] C14 = 16'sd6;
    localparam signed [15:0] C15 = -16'sd2;

    wire signed [15:0] sample_ch0 = in_data[15:0];
    wire signed [15:0] sample_ch1 = in_data[31:16];
    wire signed [15:0] sample_ch2 = in_data[47:32];
    wire signed [15:0] sample_ch3 = in_data[63:48];

    reg signed [15:0] x0 [0:TAPS-1];
    reg signed [15:0] x1 [0:TAPS-1];
    reg signed [15:0] x2 [0:TAPS-1];
    reg signed [15:0] x3 [0:TAPS-1];

    reg [5:0] sample_count;
    reg       valid_d;
    reg       last_d;
    integer i;

    wire signed [31:0] y0;
    wire signed [31:0] y1;
    wire signed [31:0] y2;
    wire signed [31:0] y3;

    assign y0 =
        x0[0]  * C0  + x0[1]  * C1  + x0[2]  * C2  + x0[3]  * C3  +
        x0[4]  * C4  + x0[5]  * C5  + x0[6]  * C6  + x0[7]  * C7  +
        x0[8]  * C8  + x0[9]  * C9  + x0[10] * C10 + x0[11] * C11 +
        x0[12] * C12 + x0[13] * C13 + x0[14] * C14 + x0[15] * C15;

    assign y1 =
        x1[0]  * C0  + x1[1]  * C1  + x1[2]  * C2  + x1[3]  * C3  +
        x1[4]  * C4  + x1[5]  * C5  + x1[6]  * C6  + x1[7]  * C7  +
        x1[8]  * C8  + x1[9]  * C9  + x1[10] * C10 + x1[11] * C11 +
        x1[12] * C12 + x1[13] * C13 + x1[14] * C14 + x1[15] * C15;

    assign y2 =
        x2[0]  * C0  + x2[1]  * C1  + x2[2]  * C2  + x2[3]  * C3  +
        x2[4]  * C4  + x2[5]  * C5  + x2[6]  * C6  + x2[7]  * C7  +
        x2[8]  * C8  + x2[9]  * C9  + x2[10] * C10 + x2[11] * C11 +
        x2[12] * C12 + x2[13] * C13 + x2[14] * C14 + x2[15] * C15;

    assign y3 =
        x3[0]  * C0  + x3[1]  * C1  + x3[2]  * C2  + x3[3]  * C3  +
        x3[4]  * C4  + x3[5]  * C5  + x3[6]  * C6  + x3[7]  * C7  +
        x3[8]  * C8  + x3[9]  * C9  + x3[10] * C10 + x3[11] * C11 +
        x3[12] * C12 + x3[13] * C13 + x3[14] * C14 + x3[15] * C15;

    always @(posedge clk) begin
        if (!rst_n) begin
            for (i = 0; i < TAPS; i = i + 1) begin
                x0[i] <= 16'sd0;
                x1[i] <= 16'sd0;
                x2[i] <= 16'sd0;
                x3[i] <= 16'sd0;
            end

            sample_count <= 6'd0;
            valid_d      <= 1'b0;
            last_d       <= 1'b0;
            out_valid    <= 1'b0;
            out_last     <= 1'b0;
            out_data     <= 128'd0;
        end else begin
            out_valid <= valid_d;
            out_last  <= last_d;
            out_data  <= {y3, y2, y1, y0};

            valid_d <= 1'b0;
            last_d  <= 1'b0;

            if (in_valid) begin
                for (i = TAPS-1; i > 0; i = i - 1) begin
                    x0[i] <= x0[i-1];
                    x1[i] <= x1[i-1];
                    x2[i] <= x2[i-1];
                    x3[i] <= x3[i-1];
                end

                x0[0] <= sample_ch0;
                x1[0] <= sample_ch1;
                x2[0] <= sample_ch2;
                x3[0] <= sample_ch3;

                if (sample_count < 6'd16) begin
                    sample_count <= sample_count + 1'b1;
                end

                if (sample_count >= 6'd15) begin
                    valid_d <= 1'b1;
                    last_d  <= in_last;
                end
            end
        end
    end

endmodule