`timescale 1ns/1ps

module accelerator (
    input  wire         clk,
    input  wire         rst_n,

    input  wire [63:0]  s_axis_tdata,
    input  wire         s_axis_tvalid,
    output wire         s_axis_tready,
    input  wire         s_axis_tlast,

    output wire [127:0] m_axis_tdata,
    output wire         m_axis_tvalid,
    input  wire         m_axis_tready,
    output wire         m_axis_tlast
);

    wire        fir_in_valid;
    wire        fir_out_valid;
    wire        fir_out_last;
    wire [127:0] fir_out_data;

    assign s_axis_tready = 1'b1;
    assign fir_in_valid  = s_axis_tvalid && s_axis_tready;

    fir_hw u_fir_hw (
        .clk       (clk),
        .rst_n     (rst_n),
        .in_valid  (fir_in_valid),
        .in_last   (s_axis_tlast),
        .in_data   (s_axis_tdata),
        .out_valid (fir_out_valid),
        .out_last  (fir_out_last),
        .out_data  (fir_out_data)
    );

    assign m_axis_tdata  = fir_out_data;
    assign m_axis_tvalid = fir_out_valid;
    assign m_axis_tlast  = fir_out_last;

endmodule