`timescale 1ns/1ps

module not_engine_tb;

    reg         clk;
    reg         rst_n;

    reg  [63:0] s_axis_tdata;
    reg         s_axis_tvalid;
    wire        s_axis_tready;
    reg         s_axis_tlast;

    wire [63:0] m_axis_tdata;
    wire        m_axis_tvalid;
    reg         m_axis_tready;
    wire        m_axis_tlast;

    integer cycle_count;
    integer start_cycle;
    integer end_cycle;
    real hw_ops_per_sec;

    accelerator dut (
        .clk(clk),
        .rst_n(rst_n),

        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tlast(s_axis_tlast),

        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tlast(m_axis_tlast)
    );

    always #5 clk = ~clk;

    //count clock cycles:
    always @(posedge clk) begin
        if (rst_n) begin
            cycle_count <= cycle_count + 1;
        end
    end

    initial begin
        clk = 0;
        rst_n = 0;

        s_axis_tdata  = 64'h0000_0000_0000_00FF;
        s_axis_tvalid = 0;
        s_axis_tlast  = 0;
        m_axis_tready = 1;

        cycle_count = 0;
        start_cycle = 0;
        end_cycle = 0;
        hw_ops_per_sec = 0.0;

        #20;
        rst_n = 1;

        #10;
        start_cycle = cycle_count; //record the current cycle count
        s_axis_tvalid = 1;
        s_axis_tlast  = 1;

        #10;
        s_axis_tvalid = 0;
        s_axis_tlast  = 0;

        #20;
        end_cycle = cycle_count; //record the current cycle count
        $display("INPUT  = %h", 64'h0000_0000_0000_00FF);
        $display("OUTPUT = %h", m_axis_tdata);
        $display("EXPECTED OUTPUT = ffff_ffff_ffff_ff00");

        if (m_axis_tdata == 64'hFFFF_FFFF_FFFF_FF00) begin
            $display("SIMULATION: PASS");
        end else begin
            $display("SIMULATION: FAIL");
        end

        hw_ops_per_sec = (1.0 * 200000000.0) / (end_cycle - start_cycle);
        $display("CYCLES=%0d", end_cycle - start_cycle);
        $display("HW_OPS_PER_SEC=%0.2f", hw_ops_per_sec);

        $finish;
    end

endmodule