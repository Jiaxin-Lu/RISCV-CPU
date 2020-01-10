`include "defines.v"

module id_ex(
    input   wire    clk,
    input   wire    rst,
    input   wire    rdy,

    input   wire[`InstAddrBus]  id_pc,
    input   wire[`InstAddrBus]  id_npc,
    output  reg[`InstAddrBus]   ex_pc,
    output  reg[`InstAddrBus]   ex_npc,

    input   wire[`AluOpBus]     id_aluop,
    input   wire[`AluSelBus]    id_alusel,
    input   wire[`RegBus]       id_reg1,
    input   wire[`RegBus]       id_reg2,
    input   wire[`RegBus]       id_Imm,
    input   wire[`RegBus]       id_rd,
    input   wire                id_rd_e,
    input   wire[4 : 0]         id_mem_length,

    output  reg[`AluOpBus]      ex_aluop,
    output  reg[`AluSelBus]     ex_alusel,
    output  reg[`RegBus]        ex_reg1,
    output  reg[`RegBus]        ex_reg2,
    output  reg[`RegBus]        ex_Imm,
    output  reg[`RegBus]        ex_rd,
    output  reg                 ex_rd_e,
    output  reg[4 : 0]          ex_mem_length,

    input   wire                br,
    input   wire[`InstAddrBus]  id_jmp_addr,
    input   wire[`InstAddrBus]  id_pred,
    output  reg[`InstAddrBus]   ex_jmp_addr,
    output  reg[`InstAddrBus]   ex_pred,

    input   wire[`StallBus]     stall
    
);

always @(posedge clk) begin
    if (rst || (stall[2] == 1 && stall[3] == 0)) begin
        ex_aluop <= `NOP;
        ex_alusel <= `EXE_RES_NOP;
        ex_reg1 <= 0;
        ex_reg2 <= 0;
        ex_Imm <= 0;
        ex_rd <= 0;
        ex_rd_e <= 0;
        ex_mem_length <= 0;
        ex_pc <= 0;
    end else if (rdy && stall[2] == 0) begin
        if (br == 0) begin
            ex_reg1 <= id_reg1;
            ex_reg2 <= id_reg2;
            ex_aluop <= id_aluop;
            ex_alusel <= id_alusel;
            ex_Imm <= id_Imm;
            ex_rd <= id_rd;
            ex_rd_e <= id_rd_e;
            ex_mem_length <= id_mem_length;
            ex_pc <= id_pc;
            ex_jmp_addr <= id_jmp_addr;
            ex_pred <= id_pred;
            ex_npc <= id_npc;
        end else begin
            ex_alusel <= `EXE_RES_NOP;
            ex_aluop <= `FLUSH;
            ex_reg1 <= 0;
            ex_reg2 <= 0;
            ex_Imm <= 0;
            ex_mem_length <= 0;
            ex_rd_e <= 0;
        end
    end
end

endmodule // id_ex