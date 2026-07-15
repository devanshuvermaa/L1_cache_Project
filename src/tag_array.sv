module tag_array #(
    parameter TAG_WIDTH = 22,
    parameter DEPTH = 64,
    parameter INDEX_WIDTH = 6
)(
    input  logic                   clk,
    input  logic                   wen,
    input  logic                   set_dirty,
    input  logic                   clear_dirty,
    input  logic [INDEX_WIDTH-1:0] index,
    input  logic [TAG_WIDTH-1:0]   wtag,
    output logic [TAG_WIDTH-1:0]   rtag,
    output logic                   valid,
    output logic                   dirty
);

    typedef struct packed {
        logic                 valid;
        logic                 dirty;
        logic [TAG_WIDTH-1:0] tag;
    } tag_row_t;

    tag_row_t tag_memory [0:DEPTH-1];

    always_ff @(posedge clk) begin
        if (wen) begin
            tag_memory[index].valid <= 1'b1;
            tag_memory[index].dirty <= 1'b0;
            tag_memory[index].tag   <= wtag;
        end
        else begin
            if (set_dirty)
                tag_memory[index].dirty <= 1'b1;
            if (clear_dirty)
                tag_memory[index].dirty <= 1'b0;
        end
    end

    assign rtag  = tag_memory[index].tag;
    assign valid = tag_memory[index].valid;
    assign dirty = tag_memory[index].dirty;

    initial begin
        for (int i = 0; i < DEPTH; i++) begin
            tag_memory[i].valid = 1'b0;
            tag_memory[i].dirty = 1'b0;
            tag_memory[i].tag   = '0;
        end
    end

endmodule