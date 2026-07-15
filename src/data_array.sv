module data_array #(
    parameter DATA_WIDTH = 128,
    parameter DEPTH = 64,
    parameter INDEX_WIDTH = 6
)(
    input  logic                   clk,
    input  logic                   wen,
    input  logic [INDEX_WIDTH-1:0] index,
    input  logic [DATA_WIDTH-1:0]  wdata,
    output logic [DATA_WIDTH-1:0]  rdata
);

    logic [DATA_WIDTH-1:0] memory [0:DEPTH-1];

    always_ff @(posedge clk) begin
        if (wen)
            memory[index] <= wdata;
    end

    assign rdata = memory[index];

endmodule