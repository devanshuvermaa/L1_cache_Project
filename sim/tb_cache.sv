`timescale 1ns / 1ps

module tb_cache;

    logic clk;
    logic rst_n;

    logic [31:0] cpu_addr;
    logic [31:0] cpu_wdata;
    logic        cpu_ren;
    logic        cpu_wen;
    logic [31:0] cpu_rdata;
    logic        cpu_stall;

    logic [31:0]  mem_addr;
    logic [127:0] mem_wdata;
    logic         mem_ren;
    logic         mem_wen;
    logic [127:0] mem_rdata;
    logic         mem_ready;

    cache_top dut (
        .clk(clk),
        .rst_n(rst_n),
        .cpu_addr(cpu_addr),
        .cpu_wdata(cpu_wdata),
        .cpu_ren(cpu_ren),
        .cpu_wen(cpu_wen),
        .cpu_rdata(cpu_rdata),
        .cpu_stall(cpu_stall),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_ren(mem_ren),
        .mem_wen(mem_wen),
        .mem_rdata(mem_rdata),
        .mem_ready(mem_ready)
    );

    initial
        clk = 0;

    always #5 clk = ~clk;

    int mem_wait_ctr = 0;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            mem_ready <= 0;
            mem_wait_ctr <= 0;
        end
        else if ((mem_ren || mem_wen) && !mem_ready) begin
            if (mem_wait_ctr < 4) begin
                mem_wait_ctr <= mem_wait_ctr + 1;
            end
            else begin
                mem_ready <= 1;
                mem_wait_ctr <= 0;

                if (mem_ren)
                    mem_rdata <= {4{32'hDEADBEEF}};
            end
        end
        else begin
            mem_ready <= 0;
            mem_wait_ctr <= 0;
        end
    end

    int total_accesses = 0;
    int total_hits = 0;

    logic [21:0] rand_tag;
    logic [5:0]  rand_idx;
    int rw_roll;
    integer i;

    initial begin
        $dumpfile("cache_waves.vcd");
        $dumpvars(0, tb_cache);

        rst_n = 0;
        cpu_ren = 0;
        cpu_wen = 0;

        #15 rst_n = 1;
        #10;

        $display("Starting Procedural Random Cache Simulation...");

        for (i = 0; i < 1000; i = i + 1) begin

            rand_tag = $urandom_range(1, 4);
            rand_idx = $urandom_range(0, 3);

            @(posedge clk);

            cpu_addr  = {rand_tag, rand_idx, 4'h0};
            cpu_wdata = $urandom();

            rw_roll = $urandom_range(1, 100);

            if (rw_roll <= 70) begin
                cpu_ren = 1;
                cpu_wen = 0;
            end
            else begin
                cpu_ren = 0;
                cpu_wen = 1;
            end

            @(posedge clk);

            cpu_ren = 0;
            cpu_wen = 0;

            total_accesses = total_accesses + 1;

            if (!cpu_stall) begin
                total_hits = total_hits + 1;
            end
            else begin
                while (cpu_stall)
                    @(posedge clk);
            end
        end

        $display("========================================");
        $display("   CACHE SIMULATION COMPLETE");
        $display("   Total Accesses: %0d", total_accesses);
        $display("   Total Hits:     %0d", total_hits);
        $display("   Hit Rate:       %0.2f%%",
                 (real'(total_hits) / total_accesses) * 100);
        $display("========================================");

        #50 $finish;
    end

endmodule