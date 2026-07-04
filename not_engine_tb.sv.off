`timescale 1ns/1ps

module not_engine_tb;

    localparam real CLOCK_HZ = 200000000.0;

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
    integer timeout_cycles;
    reg [63:0] output_sample;
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
        timeout_cycles = 0;
        output_sample = 64'd0;
        hw_ops_per_sec = 0.0;

        repeat (2) @(posedge clk);
        rst_n = 1;

        @(negedge clk);
        s_axis_tvalid = 1;
        s_axis_tlast  = 1;

        while (!s_axis_tready) begin
            @(negedge clk);
        end
        @(posedge clk);
        #1;
        start_cycle = cycle_count;

        @(negedge clk);
        s_axis_tvalid = 0;
        s_axis_tlast  = 0;

        timeout_cycles = 0;
        while (!(m_axis_tvalid && m_axis_tready)) begin
            @(negedge clk);
            timeout_cycles = timeout_cycles + 1;
            if (timeout_cycles > 100) begin
                $display("SIMULATION: FAIL");
                $display("ERROR: timed out waiting for output handshake");
                $finish;
            end
        end

        output_sample = m_axis_tdata;
        @(posedge clk);
        #1;
        end_cycle = cycle_count;

        $display("INPUT  = %h", 64'h0000_0000_0000_00FF);
        $display("OUTPUT = %h", output_sample);
        $display("EXPECTED OUTPUT = ffff_ffff_ffff_ff00");

        if (output_sample == 64'hFFFF_FFFF_FFFF_FF00) begin
            $display("SIMULATION: PASS");
        end else begin
            $display("SIMULATION: FAIL");
        end

        hw_ops_per_sec = CLOCK_HZ / (end_cycle - start_cycle);
        $display("CYCLES=%0d", end_cycle - start_cycle);
        $display("HW_OPS_PER_SEC=%0.2f", hw_ops_per_sec);

        $finish;
    end

endmodule
