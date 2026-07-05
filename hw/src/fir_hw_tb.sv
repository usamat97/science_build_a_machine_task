`timescale 1ns/1ps

module fir_hw_tb;

    localparam int CHANNELS   = 4;
    localparam int TAPS       = 16;
    localparam int NUM_FRAMES = 1024;
    localparam int OUT_FRAMES = NUM_FRAMES - TAPS + 1;
    localparam real CLK_HZ    = 200000000.0;

    reg          clk;
    reg          rst_n;

    reg  [63:0]  s_axis_tdata;
    reg          s_axis_tvalid;
    wire         s_axis_tready;
    reg          s_axis_tlast;

    wire [127:0] m_axis_tdata;
    wire         m_axis_tvalid;
    reg          m_axis_tready;
    wire         m_axis_tlast;

    reg [63:0] input_words [0:NUM_FRAMES-1];

    integer cycle_count;
    integer start_cycle;
    integer end_cycle;
    integer send_frame;
    integer recv_frame;
    integer hw_file;

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

    always #2.5 clk = ~clk;

    initial begin
        $readmemh("fir_input_1024.txt", input_words);

        hw_file = $fopen("hw_output.txt", "w");
        if (hw_file == 0) begin
            $display("ERROR: could not open hw_output.txt");
            $finish;
        end

        clk = 0;
        rst_n = 0;

        s_axis_tdata  = 64'd0;
        s_axis_tvalid = 1'b0;
        s_axis_tlast  = 1'b0;
        m_axis_tready = 1'b1;

        cycle_count = 0;
        start_cycle = -1;
        end_cycle   = -1;
        send_frame  = 0;
        recv_frame  = 0;

        repeat (5) @(posedge clk);
        rst_n = 1;

        while (recv_frame < OUT_FRAMES) begin
            @(negedge clk);

            if (send_frame < NUM_FRAMES) begin
                s_axis_tvalid = 1'b1;
                s_axis_tdata  = input_words[send_frame];
                s_axis_tlast  = (send_frame == NUM_FRAMES - 1);
            end else begin
                s_axis_tvalid = 1'b0;
                s_axis_tdata  = input_words[NUM_FRAMES-1];
                s_axis_tlast  = 1'b0;
            end

            @(posedge clk);
            #1;

            cycle_count = cycle_count + 1;

            if (s_axis_tvalid && s_axis_tready) begin
                if (start_cycle < 0) begin
                    start_cycle = cycle_count;
                end
                send_frame = send_frame + 1;
            end

            if (m_axis_tvalid && m_axis_tready) begin
                $fdisplay(hw_file, "%032h", m_axis_tdata);
                recv_frame = recv_frame + 1;

                if (recv_frame == OUT_FRAMES) begin
                    end_cycle = cycle_count;
                end
            end

            if (cycle_count > NUM_FRAMES + 200) begin
                $display("FAIL: timeout");
                $finish;
            end
        end

        $fclose(hw_file);

        hw_ops_per_sec = (OUT_FRAMES * CHANNELS * CLK_HZ) / (end_cycle - start_cycle + 1);

        $display("HW_RUN: PASS");
        $display("INPUT_FRAMES=%0d", NUM_FRAMES);
        $display("OUTPUT_FRAMES=%0d", OUT_FRAMES);
        $display("OUTPUT_SAMPLES=%0d", OUT_FRAMES * CHANNELS);
        $display("CYCLES=%0d", end_cycle - start_cycle + 1);
        $display("HW_OPS_PER_SEC=%0.2f", hw_ops_per_sec);

        $finish;
    end

endmodule