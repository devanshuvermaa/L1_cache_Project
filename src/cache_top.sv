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
    logic [5:0]  index;
    logic [3:0]  offset;

    assign tag    = cpu_addr[31:10];
    assign index  = cpu_addr[9:4];
    assign offset = cpu_addr[3:0];

    logic [21:0] rtag_way0, rtag_way1;
    logic        valid_way0, valid_way1;
    logic        dirty_way0, dirty_way1;
    logic [127:0] rdata_way0, rdata_way1;
    logic        lru_way;

    logic wen_way0, set_dirty_way0, clear_dirty_way0;
    logic wen_way1, set_dirty_way1, clear_dirty_way1;
    logic update_lru, accessed_way;

    tag_array my_tag_array (
        .clk(clk),
        .wen_way0(wen_way0),
        .set_dirty_way0(set_dirty_way0),
        .clear_dirty_way0(clear_dirty_way0),
        .wen_way1(wen_way1),
        .set_dirty_way1(set_dirty_way1),
        .clear_dirty_way1(clear_dirty_way1),
        .update_lru(update_lru),
        .accessed_way(accessed_way),
        .index(index),
        .wtag(tag),
        .rtag_way0(rtag_way0),
        .valid_way0(valid_way0),
        .dirty_way0(dirty_way0),
        .rtag_way1(rtag_way1),
        .valid_way1(valid_way1),
        .dirty_way1(dirty_way1),
        .lru_way(lru_way)
    );

    data_array my_data_array (
        .clk(clk),
        .wen_way0(wen_way0),
        .wen_way1(wen_way1),
        .index(index),
        .wdata(mem_rdata),
        .rdata_way0(rdata_way0),
        .rdata_way1(rdata_way1)
    );

    logic hit_way0, hit_way1, cache_hit;

    assign hit_way0  = valid_way0 && (rtag_way0 == tag);
    assign hit_way1  = valid_way1 && (rtag_way1 == tag);
    assign cache_hit = hit_way0 | hit_way1;

    logic [127:0] hit_data;

    assign hit_data = hit_way1 ? rdata_way1 : rdata_way0;

    logic [21:0]  evict_tag;
    logic [127:0] evict_data;
    logic         evict_dirty;

    assign evict_tag   = lru_way ? rtag_way1 : rtag_way0;
    assign evict_data  = lru_way ? rdata_way1 : rdata_way0;
    assign evict_dirty = lru_way ? dirty_way1 : dirty_way0;

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
                    if (evict_dirty)
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

    assign cpu_rdata = hit_data[(offset * 8) +: 32];

    assign mem_ren   = (state == ALLOCATE);
    assign mem_wen   = (state == WRITE_BACK);

    assign mem_addr  = (state == WRITE_BACK) ?
                       {evict_tag, index, 4'b0000} :
                       {tag, index, 4'b0000};

    assign mem_wdata = evict_data;

    assign wen_way0 = (state == ALLOCATE && mem_ready && !lru_way);
    assign wen_way1 = (state == ALLOCATE && mem_ready &&  lru_way);

    assign set_dirty_way0 = (state == COMPARE && hit_way0 && cpu_wen);
    assign set_dirty_way1 = (state == COMPARE && hit_way1 && cpu_wen);

    assign clear_dirty_way0 = 1'b0;
    assign clear_dirty_way1 = 1'b0;

    assign update_lru = (state == COMPARE && cache_hit) ||
                        (state == ALLOCATE && mem_ready);

    assign accessed_way = (state == COMPARE && cache_hit) ?
                          hit_way1 : lru_way;

endmodule