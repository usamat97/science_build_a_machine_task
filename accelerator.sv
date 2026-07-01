`timescale 1ns/1ps

module accelerator (
    input  wire        clk,
    input  wire        rst_n,

    // Input stream.
    // AXI-Stream handshake: transfer when tvalid && tready on rising clk.
    // tlast marks the end of a work unit (packet, block, frame -- you define it).
    input  wire [63:0] s_axis_tdata,
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    input  wire        s_axis_tlast,

    // Output stream.
    output wire [63:0] m_axis_tdata,
    output wire        m_axis_tvalid,
    input  wire        m_axis_tready,
    output wire        m_axis_tlast
);

    // Your design here.
    //
    // You can change the data widths, add ports, split into multiple
    // modules, or restructure entirely. This template is a starting
    // point, not a requirement.
    not_engine u_not_engine (
        .in_data  (r_data),
        .out_data (design_out)
    );
    
    // Stub: passes input to output with one cycle latency.
    reg [63:0] r_data;
    reg        r_valid;
    reg        r_last;
    wire [63:0] design_out;

    

    always @(posedge clk) begin
        if (!rst_n) begin
            r_data  <= 64'd0;
            r_valid <= 1'b0;
            r_last  <= 1'b0;
        end else if (s_axis_tvalid && s_axis_tready) begin
            r_data  <= s_axis_tdata;
            r_valid <= 1'b1;
            r_last  <= s_axis_tlast;
        end else if (m_axis_tready) begin
            r_valid <= 1'b0;
        end
    end

    assign s_axis_tready = !r_valid || m_axis_tready;
    assign m_axis_tdata  = design_out;
    assign m_axis_tvalid = r_valid;
    assign m_axis_tlast  = r_last;

endmodule