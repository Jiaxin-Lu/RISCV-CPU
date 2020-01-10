`timescale 1ns / 1ps
`include "defines.v"

module id(
    input wire                  rst,
    input wire[`InstAddrBus]    pc,
    input wire[`InstAddrBus]    npc,
    input wire[`InstBus]        inst,

    output wire[`InstAddrBus]   pc_o,
    output wire[`InstAddrBus]   npc_o,

    input wire[`RegBus]         rdata1,
    input wire[`RegBus]         rdata2,

// Forwarding from ex 
    input   wire                ex_we,
    input   wire[`RegAddrBus]   ex_waddr,
    input   wire[`RegBus]       ex_wdata,

//  Forwarding from mem
    input   wire                mem_we,
    input   wire[`RegAddrBus]   mem_waddr,
    input   wire[`RegBus]       mem_wdata,
// To Reg
    output reg                  re1,
    output reg                  re2,
    output reg[`RegAddrBus]     raddr1,
    output reg[`RegAddrBus]     raddr2,

    output reg[`AluOpBus]       aluop,
    output reg[`AluSelBus]      alusel,

    output reg[`RegBus]         reg1,
    output reg[`RegBus]         reg2,
    output reg[`RegBus]         Imm,
    output reg[`RegBus]         rd,
    output reg                  rd_e,
    output reg[4 : 0]           mem_length,
    
//Prediction
    input   wire[`InstAddrBus]  pred_i,
    output  wire[`InstAddrBus]  pred_o,
    output  reg[`InstAddrBus]   jmp_addr,

    output  reg                 if_br
);

assign pred_o = pred_i;
assign pc_o = pc;
assign npc_o = npc;

wire[6 : 0] opcode;
wire[2 : 0] funct3;
wire[6 : 0] funct7;
assign opcode = inst[6 : 0];
assign funct3 = inst[14 : 12];
assign funct7 = inst[31 : 25];

always @ (*) begin
    if (rst) begin
        rd_e = 0;
        raddr1 = 0;
        raddr2 = 0;
        re1 = 0;
        re2 = 0;
        rd = 0;
        Imm = 0;
        aluop = 0;
        alusel = 0;
        mem_length = 0;
        jmp_addr = 0;
        if_br = 0;
    end else begin
        raddr1 = inst[19 : 15];
        raddr2 = inst[24 : 20];
        rd = inst[11 : 7];
        if_br = 0;
        re1 = 0;
        re2 = 0;
        Imm = 0;
        aluop = 0;
        alusel = 0;
        mem_length = 0;
        jmp_addr = 0;
        case (opcode)
            `Flushed: begin
                if_br = 1;
                re1 = 0;
                re2 = 0;
                Imm = 0;
                rd_e = 0;
            end
            `OP_JAL : begin
                re1 = 0;
                re2 = 0;
                Imm = pc + 4;
                rd_e = 1;
                aluop = `JAL;
                alusel = `EXE_RES_JAL;
                jmp_addr = pc + {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};
            end
            `OP_JALR: begin
                re1 = 1;
                re2 = 0;
                rd_e = 1;
                Imm = pc + 4;
                aluop = `JALR;
                alusel = `EXE_RES_JAL;
                jmp_addr = (rdata1 + {{20{inst[31]}}, inst[31:20]}) & 32'hfffffffe;
            end
            `OP_BRANCH: begin
                alusel = `EXE_RES_BRANCH;
                re1 = 1;
                re2 = 1;
                rd_e = 0;
                jmp_addr = pc + {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
                case (funct3)
                    `FUNCT3_BEQ: begin
                        aluop = `BEQ;
                    end
                    `FUNCT3_BNE: begin
                        aluop = `BNE;
                    end
                    `FUNCT3_BLT: begin
                        aluop = `BLT;
                    end
                    `FUNCT3_BLTU: begin
                        aluop = `BLTU;
                    end
                    `FUNCT3_BGE: begin
                        aluop = `BGE;
                    end
                    `FUNCT3_BGEU: begin
                        aluop = `BGEU;
                    end
                    default : begin
                    end
                endcase
            end
            `OP_LOAD: begin
                Imm = {{20{inst[31]}} ,inst[31:20]};
                re1 = 1;
                re2 = 0;
                rd_e = 1;
                alusel = `EXE_RES_LOAD;
                aluop = `ADD;
                case (funct3)
                    `FUNCT3_LB: begin
                        mem_length = 5'b00001;
                    end
                    `FUNCT3_LH: begin
                        mem_length = 5'b00010;
                    end
                    `FUNCT3_LW: begin
                        mem_length = 5'b00100;
                    end
                    `FUNCT3_LBU: begin
                        mem_length = 5'b01001;
                    end
                    `FUNCT3_LHU: begin
                        mem_length = 5'b01010;
                    end
                    default: begin
                    end
                endcase
            end
            `OP_STORE: begin
                Imm = {{20{inst[31]}} ,inst[31:25], inst[11:7]};
                re1 = 1;
                re2 = 1;
                rd_e = 1;
                aluop = `ADD2;
                alusel = `EXE_RES_STORE;
                case (funct3)
                    `FUNCT3_SB: begin
                        mem_length = 5'b10001;
                    end
                    `FUNCT3_SH: begin
                        mem_length = 5'b10010;
                    end
                    `FUNCT3_SW: begin
                        mem_length = 5'b10100;
                    end
                    default: begin
                    end
                endcase
            end
            `OP_OP_I: begin
                Imm = {{20{inst[31]}} ,inst[31:20]};
                re1 = 1;
                re2 = 0;
                rd_e = 1;
                alusel = `EXE_RES_ARITH;
                case (funct3)
                    `FUNCT3_ADDI: begin
                        aluop = `ADD;
                    end
                    `FUNCT3_SLLI: begin
                        aluop = `SLL;
                        Imm = {{27{1'b0}}, inst[24:20]};
                    end
                    `FUNCT3_SLTI: begin
                        aluop = `SLT;
                    end
                    `FUNCT3_SLTIU: begin
                        aluop = `SLTU;
                    end
                    `FUNCT3_XORI: begin
                        aluop = `XOR;
                    end
                    `FUNCT3_ORI: begin
                        aluop = `OR;
                    end
                    `FUNCT3_ANDI: begin
                        aluop = `AND;
                    end
                    `FUNCT3_SRLI_SRAI: begin
                        Imm = {{27{1'b0}}, inst[24:20]};
                        case (funct7)
                            `FUNCT7_SRLI: begin
                                aluop = `SRL;
                            end
                            `FUNCT7_SRAI: begin
                                aluop = `SRA;
                            end
                            default : begin
                            end
                        endcase
                    end
                    default: begin
                    end
                endcase
            end
            `OP_OP: begin
                re1 = 1;
                re2 = 1;
                rd_e = 1;
                alusel = `EXE_RES_ARITH;
                case (funct3)
                    `FUNCT3_SLL: begin
                        aluop = `SLL;
                    end
                    `FUNCT3_SLT: begin
                        aluop = `SLT;
                    end
                    `FUNCT3_SLTU: begin
                        aluop = `SLTU;
                    end
                    `FUNCT3_XOR: begin
                        aluop = `XOR;
                    end
                    `FUNCT3_OR: begin
                        aluop = `OR;
                    end
                    `FUNCT3_AND: begin
                        aluop = `AND;
                    end
                    `FUNCT3_ADD_SUB: begin
                        case (funct7)
                            `FUNCT7_ADD: begin
                                aluop = `ADD;
                            end
                            `FUNCT7_SUB: begin
                                aluop = `SUB;
                            end
                            default : begin
                            end
                        endcase
                    end
                    `FUNCT3_SRL_SRA: begin
                        case (funct7)
                            `FUNCT7_SRL: begin
                                aluop = `SRL;
                            end
                            `FUNCT7_SRA: begin
                                aluop = `SRA;
                            end
                            default : begin
                            end
                        endcase
                    end
                    default: begin
                    end
                endcase
            end
            `OP_LUI: begin
                Imm = {inst[31:12], {12{1'b0}}};
                rd_e = 1;
                aluop = `LUI;
                alusel = `EXE_RES_LUI;
            end
            `OP_AUIPC: begin
                Imm = {inst[31:12], {12{1'b0}}};
                rd_e = 1;
                aluop = `LUI;
                alusel = `EXE_RES_LUI;
            end
            default : begin
                rd_e = 0;
                re1 = 0;
                re2 = 0;
                rd = 0;
                Imm = 0;
                aluop = 0;
                alusel = 0;
                mem_length = 0;
            end
        endcase
    end
end

always @ (*) begin
    if (rst == 1) begin
        reg1 = 0;
    end else if(re1 == 0) begin
        reg1 = 0;
    end else if(re1) begin
        if (ex_we && ex_waddr == raddr1) begin
            if (ex_waddr == 0)
                reg1 = 0;
            else
                reg1 = ex_wdata;
        end
        else if(mem_we && mem_waddr == raddr1) begin
            if (mem_waddr == 0)
                reg1 = 0;
            else
                reg1 = mem_wdata;
        end else reg1 = rdata1;
    end else begin
        reg1 = 0;
    end
end

always @ (*) begin
    if (rst == 1) begin
        reg2 = 0;
    end else if(re2 == 0) begin
        reg2 = Imm;
    end else if(re2) begin
        if (ex_we && ex_waddr == raddr2) begin
            if (ex_waddr == 0)
                reg2 = 0;
            else
                reg2 = ex_wdata;
        end
        else if(mem_we && mem_waddr == raddr2) begin
            if (mem_waddr == 0)
                reg2 = 0;
            else
                reg2 = mem_wdata;
        end else reg2 = rdata2;
    end else begin
        reg2 = 0;        
    end
end

endmodule