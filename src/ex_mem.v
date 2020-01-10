`include "defines.v"

module ex_mem (
    input   wire        clk,
    input   wire        rst,
    input   wire        rdy,

    input   wire[`RegBus]       ex_rd_data,
    input   wire[`RegAddrBus]   ex_rd_addr,
    input   wire[`DataAddrBus]  ex_mem_addr,
    input   wire                ex_rd_e,
    input   wire[4 : 0]         ex_mem_length,

    output  reg[`RegBus]        mem_rd_data,
    output  reg[`RegAddrBus]    mem_rd_addr,
    output  reg[`DataAddrBus]   mem_mem_addr,
    output  reg                 mem_rd_e,
    output  reg[4 : 0]          mem_length,

    input   wire[`StallBus]     stall
);

always @ (posedge clk) begin
    if (rst || (stall[3] == 1 && stall[4] == 0)) begin
        mem_rd_data <= 0;
        mem_rd_addr <= 0;
        mem_rd_e <= 0;
        mem_mem_addr <= 0;
        mem_length <= 0;
    end else if (rdy && !stall[3]) begin
        mem_rd_data <= ex_rd_data;
        mem_rd_addr <= ex_rd_addr;
        mem_rd_e <= ex_rd_e;
        mem_mem_addr <= ex_mem_addr;
        mem_length <= ex_mem_length;
    end
end

endmodule