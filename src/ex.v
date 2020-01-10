`timescale 1ns / 1ps
`include "defines.v"

module ex(
    input   wire        rst,
    input   wire        clk,
    input   wire[`InstAddrBus]  pc,
    input   wire[`InstAddrBus]  npc,

    input   wire[`AluOpBus]     aluop,
    input   wire[`AluSelBus]    alusel,
    input   wire[`RegBus]       reg1,
    input   wire[`RegBus]       reg2,
    input   wire[`RegBus]       Imm,
    input   wire[`RegBus]       rd,
    input   wire                rd_e,
    input   wire[4 : 0]         mem_length_i,

    output  reg[`RegBus]        rd_data_o,
    output  reg[`RegAddrBus]    rd_addr,

    output  reg[`MemAddrBus]    mem_addr,
    output  reg                 rd_e_o,
    output  reg[4 : 0]          mem_length_o,

    output  reg                 id_br,
    input   wire[`InstAddrBus]  jmp_addr,
    input   wire[`InstAddrBus]  pred,
    output  reg                 jmp_e,
    output  reg[`InstAddrBus]   jmp_target,
    output  reg[`InstAddrBus]   jmp_addr_o,
    output  reg                 is_jmp,
    output  reg                 btb_change_e
);

reg[`RegBus]    res;

wire _beq;
wire _bne;
wire _blt;
wire _bltu;
wire _bge;
wire _bgeu;

assign _beq = (reg1 == reg2);
assign _bne = (reg1 != reg2);
assign _blt = (($signed(reg1)) < ($signed(reg2)));
assign _bltu = (reg1 < reg2);
assign _bge = (($signed(reg1)) >= ($signed(reg2)));
assign _bgeu = (reg1 >= reg2);

always @ (*) begin
    if (rst) begin
        res = 0;
        id_br = 0;
    end else begin
        id_br = 0;
        case (aluop)
            `AUIPC: res = pc + Imm;
            `ADD : res = reg1+reg2;
            `ADD2 : res = reg1 + Imm;
            `SUB : res = reg1 - reg2;
            `SLL : res = reg1 << reg2[4 : 0];
            `SLT : res = $signed(reg1) < $signed(reg2);
            `SLTU: res = reg1 < reg2;
            `XOR: res = reg1 ^ reg2;
            `SRL: res = reg1 >> reg2[4 : 0];
            `SRA: res = reg1 >>> reg2[4: 0];
            `OR:  res = reg1 | reg2;
            `AND: res = reg1 & reg2;
            `FLUSH: begin
                id_br = 1;
                res = 0;
            end
            default : res = 0;
        endcase
    end
end

always @ (*) begin
    if (rst) begin
        rd_addr = 0;
        mem_length_o = 0;
        rd_e_o = 0;
        rd_data_o = 0;
        mem_addr = 0;
    end else begin
        rd_addr = rd;
        rd_e_o = rd_e;
        mem_length_o = 0;
        mem_addr = 0;
        case (alusel)
            `EXE_RES_ARITH : rd_data_o = res;
            `EXE_RES_LUI : rd_data_o = Imm;
            `EXE_RES_LOAD : begin
                mem_length_o = mem_length_i;
                rd_data_o = res;
            end
            `EXE_RES_STORE : begin
                rd_e_o = 0;
                mem_length_o = mem_length_i;
                mem_addr = res;
                rd_data_o = reg2;
            end
            `EXE_RES_JAL : rd_data_o = reg2;
            default : rd_data_o = 0;
        endcase
    end
end


always @ (*) begin
    if (rst) begin
        jmp_e = 0;
        jmp_target = 0;
        jmp_addr_o = 0;
        btb_change_e = 0;
        is_jmp = 0;
    end else begin
        case (aluop)
            `BEQ: begin
                jmp_target = _beq ? jmp_addr : (pc + 4);
                jmp_addr_o = jmp_addr;
                if (_beq && pred != jmp_target) jmp_e = 1;
                else if ((!_beq) && pred != jmp_target) jmp_e = 1;
                else jmp_e = 0; 
                btb_change_e = _beq;
                is_jmp = 1;
            end
            `BNE: begin
                jmp_target = _bne ? jmp_addr : (pc + 4);
                jmp_addr_o = jmp_addr;
                if (_bne && pred != jmp_target) jmp_e = 1;
                else if ((!_bne) && pred != jmp_target) jmp_e = 1;
                else jmp_e = 0; 
                btb_change_e = _bne;
                is_jmp = 1;
            end
            `BLT: begin
                jmp_target = _blt ? jmp_addr : (pc + 4);
                jmp_addr_o = jmp_addr;
                if (_blt && pred != jmp_target) jmp_e = 1;
                else if ((!_blt) && pred != jmp_target) jmp_e = 1;
                else jmp_e = 0; 
                btb_change_e = _blt;
                is_jmp = 1;
            end
            `BLTU: begin
                jmp_target = _bltu ? jmp_addr : (pc + 4);
                jmp_addr_o = jmp_addr;
                if (_bltu && pred != jmp_target) jmp_e = 1;
                else if ((!_bltu) && pred != jmp_target) jmp_e = 1;
                else jmp_e = 0; 
                btb_change_e = _bltu;
                is_jmp = 1;
            end
            `BGE: begin
                jmp_target = _bge ? jmp_addr : (pc + 4);
                jmp_addr_o = jmp_addr;
                if (_bge && pred != jmp_target) jmp_e = 1;
                else if ((!_bge) && pred != jmp_target) jmp_e = 1;
                else jmp_e = 0; 
                btb_change_e = _bge;
                is_jmp = 1;
            end
            `BGEU: begin
                jmp_target = _bgeu ? jmp_addr : (pc + 4);
                jmp_addr_o = jmp_addr;
                if (_bgeu && pred != jmp_target) jmp_e = 1;
                else if ((!_bgeu) && pred != jmp_target) jmp_e = 1;
                else jmp_e = 0; 
                btb_change_e = _bgeu;
                is_jmp = 1;
            end
            `JAL: begin
                jmp_target = jmp_addr;
                jmp_addr_o = jmp_addr;
                jmp_e = (pred != jmp_target);
                btb_change_e = 1;
                is_jmp = 1;
            end
            `JALR: begin
                jmp_target = jmp_addr;
                jmp_addr_o = jmp_addr;
                jmp_e = (pred != jmp_target);
                btb_change_e = 1;
                is_jmp = 1;
            end
            default : begin
                jmp_target = 0;
                jmp_addr_o = 0;
                jmp_e = 0;
                btb_change_e = 0;
                is_jmp = 0;
            end
        endcase
    end
end

endmodule