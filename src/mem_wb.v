`include "defines.v"

module mem_wb(
    input   wire    clk,
    input   wire    rst,
    input   wire    rdy,
    
    input   wire[`RegBus]       mem_rd_data,
    input   wire[`RegAddrBus]   mem_rd_addr,
    input   wire                mem_rd_e,

    output  reg[`RegBus]        wb_rd_data,
    output  reg[`RegAddrBus]    wb_rd_addr,
    output  reg                 wb_rd_e,

    input   wire[`StallBus]     stall
);

always @ (posedge clk) begin
    if (rst || (stall[4] == 1 && stall[5] == 0)) begin
        wb_rd_addr <= 0;
        wb_rd_data <= 0;
        wb_rd_e <= 0;
    end else if (rdy && stall[4] == 0) begin
        wb_rd_addr <= mem_rd_addr;
        wb_rd_data <= mem_rd_data;
        wb_rd_e <= mem_rd_e;
    end
end

endmodule // mem_wb