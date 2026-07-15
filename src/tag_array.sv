module tag_array (
    input  logic        clk,
    input  logic        wen,
    input  logic        set_dirty,
    input  logic        clear_dirty,
    input  logic [5:0]  index,
    input  logic [21:0] wtag,
    output logic [21:0] rtag,
    output logic        valid,
    output logic        dirty
);

    logic [21:0] tag_mem   [0:63];
    logic        valid_mem [0:63];
    logic        dirty_mem [0:63];

    assign rtag  = tag_mem[index];
    assign valid = valid_mem[index];
    assign dirty = dirty_mem[index];

    always_ff @(posedge clk) begin
        if (wen) begin
            tag_mem[index]   <= wtag;
            valid_mem[index] <= 1'b1;
            dirty_mem[index] <= 1'b0;
        end
        else begin
            if (set_dirty)
                dirty_mem[index] <= 1'b1;
            if (clear_dirty)
                dirty_mem[index] <= 1'b0;
        end
    end

    initial begin
        for (int i = 0; i < 64; i++) begin
            valid_mem[i] = 1'b0;
            dirty_mem[i] = 1'b0;
            tag_mem[i]   = 22'b0;
        end
    end

endmodule