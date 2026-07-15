module cache_top #(
    parameter ADDR_WIDTH = 32,
    parameter CPU_DATA_WIDTH = 32,
    parameter MEM_DATA_WIDTH = 128
)(
    input  logic clk,
    input  logic rst_n,

    input  logic [ADDR_WIDTH-1:0]     cpu_addr,
    input  logic [CPU_DATA_WIDTH-1:0] cpu_wdata,
    input  logic                      cpu_ren,
    input  logic                      cpu_wen,
    output logic [CPU_DATA_WIDTH-1:0] cpu_rdata,
    output logic                      cpu_stall,

    output logic [ADDR_WIDTH-1:0]     mem_addr,
    output logic [MEM_DATA_WIDTH-1:0] mem_wdata,
    output logic                      mem_ren,
    output logic                      mem_wen,
    input  logic [MEM_DATA_WIDTH-1:0] mem_rdata,
    input  logic                      mem_ready
);

    logic [21:0] tag;
    logic [5:0] index;
    logic [3:0] offset;

    assign tag    = cpu_addr[31:10];
    assign index  = cpu_addr[9:4];
    assign offset = cpu_addr[3:0];

    logic [21:0] array_rtag;
    logic        array_valid;
    logic        array_dirty;
    logic [127:0] array_rdata;

    logic array_wen;
    logic array_set_dirty;
    logic array_clear_dirty;
    logic [127:0] array_wdata;

    tag_array my_tag_array (
        .clk(clk),
        .wen(array_wen),
        .set_dirty(array_set_dirty),
        .clear_dirty(array_clear_dirty),
        .index(index),
        .wtag(tag),
        .rtag(array_rtag),
        .valid(array_valid),
        .dirty(array_dirty)
    );

    data_array my_data_array (
        .clk(clk),
        .wen(array_wen),
        .index(index),
        .wdata(array_wdata),
        .rdata(array_rdata)
    );

    typedef enum logic [1:0] {
        IDLE       = 2'b00,
        COMPARE    = 2'b01,
        WRITE_BACK = 2'b10,
        ALLOCATE   = 2'b11
    } state_t;

    state_t state, next_state;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    logic cache_hit;

    assign cache_hit = (array_valid && (array_rtag == tag));

    always_comb begin
        next_state = state;

        case (state)
            IDLE: begin
                if (cpu_ren || cpu_wen)
                    next_state = COMPARE;
            end

            COMPARE: begin
                if (cache_hit)
                    next_state = IDLE;
                else begin
                    if (array_dirty)
                        next_state = WRITE_BACK;
                    else
                        next_state = ALLOCATE;
                end
            end

            WRITE_BACK: begin
                if (mem_ready)
                    next_state = ALLOCATE;
            end

            ALLOCATE: begin
                if (mem_ready)
                    next_state = COMPARE;
            end
        endcase
    end

    assign cpu_stall = !(state == IDLE || (state == COMPARE && cache_hit));

    assign mem_ren   = (state == ALLOCATE);
    assign mem_wen   = (state == WRITE_BACK);
    assign mem_addr  = (state == WRITE_BACK) ? {array_rtag, index, 4'b0000}
                                             : {tag, index, 4'b0000};
    assign mem_wdata = array_rdata;

    assign cpu_rdata = array_rdata[(offset * 8) +: 32];

endmodule