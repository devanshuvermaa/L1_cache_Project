module tag_array (
    input  logic        clk,
    input  logic        wen_way0,
    input  logic        set_dirty_way0,
    input  logic        clear_dirty_way0,
    input  logic        wen_way1,
    input  logic        set_dirty_way1,
    input  logic        clear_dirty_way1,
    input  logic        update_lru,
    input  logic        accessed_way,
    input  logic [5:0]  index,
    input  logic [21:0] wtag,
    output logic [21:0] rtag_way0,
    output logic        valid_way0,
    output logic        dirty_way0,
    output logic [21:0] rtag_way1,
    output logic        valid_way1,
    output logic        dirty_way1,
    output logic        lru_way
);

    logic [21:0] tag_mem_way0   [0:63];
    logic        valid_mem_way0 [0:63];
    logic        dirty_mem_way0 [0:63];

    logic [21:0] tag_mem_way1   [0:63];
    logic        valid_mem_way1 [0:63];
    logic        dirty_mem_way1 [0:63];

    logic        lru_mem [0:63];

    assign rtag_way0  = tag_mem_way0[index];
    assign valid_way0 = valid_mem_way0[index];
    assign dirty_way0 = dirty_mem_way0[index];

    assign rtag_way1  = tag_mem_way1[index];
    assign valid_way1 = valid_mem_way1[index];
    assign dirty_way1 = dirty_mem_way1[index];

    assign lru_way = lru_mem[index];

    always_ff @(posedge clk) begin
        if (update_lru) begin
            if (accessed_way == 1'b0)
                lru_mem[index] <= 1'b1;
            else
                lru_mem[index] <= 1'b0;
        end

        if (wen_way0) begin
            tag_mem_way0[index]   <= wtag;
            valid_mem_way0[index] <= 1'b1;
            dirty_mem_way0[index] <= 1'b0;
        end
        else begin
            if (set_dirty_way0)
                dirty_mem_way0[index] <= 1'b1;
            if (clear_dirty_way0)
                dirty_mem_way0[index] <= 1'b0;
        end

        if (wen_way1) begin
            tag_mem_way1[index]   <= wtag;
            valid_mem_way1[index] <= 1'b1;
            dirty_mem_way1[index] <= 1'b0;
        end
        else begin
            if (set_dirty_way1)
                dirty_mem_way1[index] <= 1'b1;
            if (clear_dirty_way1)
                dirty_mem_way1[index] <= 1'b0;
        end
    end

    initial begin
        for (int i = 0; i < 64; i++) begin
            valid_mem_way0[i] = 1'b0;
            dirty_mem_way0[i] = 1'b0;
            tag_mem_way0[i]   = 22'b0;

            valid_mem_way1[i] = 1'b0;
            dirty_mem_way1[i] = 1'b0;
            tag_mem_way1[i]   = 22'b0;

            lru_mem[i] = 1'b0;
        end
    end

endmodule