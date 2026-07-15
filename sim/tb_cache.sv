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

    always @(posedge clk) begin
        if (mem_ren) begin
            #20;
            mem_rdata <= 128'hDEADBEEF_CAFEBABE_01234567_89ABCDEF;
            mem_ready <= 1;
            #10 mem_ready <= 0;
        end
        else if (mem_wen) begin
            #20;
            mem_ready <= 1;
            #10 mem_ready <= 0;
        end
        else begin
            mem_ready <= 0;
        end
    end

    initial begin
        $dumpfile("cache_waves.vcd");
        $dumpvars(0, tb_cache);

        rst_n = 0;
        cpu_ren = 0;
        cpu_wen = 0;

        #15 rst_n = 1;

        #10;
        cpu_addr = 32'h0000_1000;
        cpu_ren  = 1;

        wait (!cpu_stall);
        cpu_ren = 0;

        #20;
        cpu_addr  = 32'h0000_1000;
        cpu_wdata = 32'h9999_9999;
        cpu_wen   = 1;

        wait (!cpu_stall);
        cpu_wen = 0;

        #20;
        cpu_addr = 32'h0000_2000;
        cpu_ren  = 1;

        wait (!cpu_stall);
        cpu_ren = 0;

        #50 $finish;
    end

endmodule