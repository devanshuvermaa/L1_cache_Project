module data_array #(
    parameter DATA_WIDTH = 128,
    parameter DEPTH = 64,
    parameter INDEX_WIDTH = 6
)(
    input  logic                   clk,
    input  logic                   wen_way0,
    input  logic                   wen_way1,
    input  logic [INDEX_WIDTH-1:0] index,
    input  logic [DATA_WIDTH-1:0]  wdata,
    output logic [DATA_WIDTH-1:0]  rdata_way0,
    output logic [DATA_WIDTH-1:0]  rdata_way1
);

    logic [DATA_WIDTH-1:0] memory_way0 [0:DEPTH-1];
    logic [DATA_WIDTH-1:0] memory_way1 [0:DEPTH-1];

    always_ff @(posedge clk) begin
        if (wen_way0)
            memory_way0[index] <= wdata;

        if (wen_way1)
            memory_way1[index] <= wdata;
    end

    assign rdata_way0 = memory_way0[index];
    assign rdata_way1 = memory_way1[index];

endmodule