// RISCV32I CPU top module
// port modification allowed for debugging purposes
`include "defines.v"
module cpu(
    input  wire                 clk_in,			// system clock signal
    input  wire                 rst_in,			// reset signal
	  input  wire					        rdy_in,			// ready signal, pause cpu when low

    input  wire [ 7:0]          mem_din,		// data input bus
    output wire [ 7:0]          mem_dout,		// data output bus
    output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
    output wire                 mem_wr,			// write/read signal (1 for write)

	output wire [31:0]			dbgreg_dout		// cpu register output (debugging demo)
);

//Branch
wire  if_br, id_br, branch_if, branch_id;
wire  jmp_e;
wire[`InstAddrBus]  if_pred;
wire[`InstAddrBus]  id_pred_i, id_pred_o;
wire[`InstAddrBus]  ex_pred;
wire[`InstAddrBus]  jmp_target;
wire                pred_e;

//Branch Predictor
wire                btb_hit;
wire[`InstAddrBus]  btb_pred;
wire                btb_change_e;
wire[`InstAddrBus]  ex_jmp_addr_o;
wire                is_jmp;

//PC
wire[`InstAddrBus]  pc, npc;
wire                pc_e;

//IF - IF/ID
wire[`InstBus]      if_inst;
wire[`InstAddrBus]  if_pc, if_npc;
wire                cacheHit;
wire[`InstBus]      cacheVal;

//IF/ID - ID
wire[`InstBus]      id_inst_i;
wire[`InstAddrBus]  id_pc_i, id_npc_i;

//REG - ID
wire[`RegBus]       rdata1, rdata2;

//ID - REG
wire[`RegAddrBus]       raddr1, raddr2;
wire                re1, re2;

//ID - ID/EX
wire[`AluOpBus]     id_aluop;
wire[`AluSelBus]    id_alusel;
wire[`RegBus]       id_reg1, id_reg2, id_Imm, id_rd;
wire[4 : 0]         id_mem_length;
wire                id_rd_e;
wire[`InstAddrBus]  id_jmp_addr;
wire[`InstAddrBus]  id_pc_o, id_npc_o;

//ID/EX - EX
wire[`AluOpBus]     ex_aluop;
wire[`AluSelBus]    ex_alusel;
wire[`RegBus]       ex_reg1, ex_reg2, ex_Imm, ex_rd;
wire[4 : 0]         ex_mem_length;
wire                ex_rd_e;
wire[`InstAddrBus]  ex_jmp_addr;
wire[`InstAddrBus]  ex_pc, ex_npc;

//EX - EX/MEM
wire[`RegBus]       ex_rd_data;
wire[`RegAddrBus]   ex_rd_addr;
wire[`MemAddrBus]   ex_mem_addr;
wire                ex_rd_e_o;
wire[4 : 0]         ex_mem_length_o;

//EX/MEM - MEM
wire[`RegBus]       mem_rd_data_i;
wire[`RegAddrBus]   mem_rd_addr_i;
wire[`MemAddrBus]   mem_mem_addr;
wire                mem_rd_e_i;
wire[4 : 0]         mem_length;

//MEM - MEM/WB
wire[`RegBus]       mem_rd_data_o;
wire[`RegAddrBus]   mem_rd_addr_o;
wire                mem_rd_e_o;

//MEM/WB - REG
wire                write_e;
wire[`RegAddrBus]   write_addr;
wire[`RegBus]       write_data;

//MemCtrl
wire[`InstAddrBus]  addr_if;
wire[`MemAddrBus]   addr_mem;
wire                rw_if;
wire[1 : 0]         rw_mem;
wire[`DataBus]      data_mem_i, data_mem_o;
wire[1 : 0]         status_if, status_mem;
wire[2 : 0]         mem_times;
//StallCtrl
wire[`StallBus]     stall;
wire                if_stall_req, mem_stall_req;
// wire                stall_req;

pc_reg  pc_reg0
(
    .clk(clk_in), .rst(rst_in), .rdy(rdy_in),
    .pc(pc), .npc(npc), .pc_e(pc_e),
    .stall(stall[0]),
    .jmp_target(jmp_target), .jmp_e(jmp_e), .pred(if_pred), .pred_e(pred_e)
);

predictor predictor0
(
    .clk(clk_in), .rst(rst_in), .rdy(rdy_in),
    .addr(pc), .addr_r(ex_pc), .jmp_r(is_jmp),
    .target_real(jmp_target), .target_addr(ex_jmp_addr_o),
    .change_e(btb_change_e),
    .jmp_e(btb_hit), .pred(btb_pred)
);

if_stage if0
(
    .clk(clk_in), .rst(rst_in), .rdy(rdy_in),
    .pc(pc), .npc(npc), .pc_o(if_pc), .npc_o(if_npc),
    .pc_e(pc_e), .inst(if_inst),
    .rw(rw_if), .data_from_mem(data_mem_o), .mem_status(status_if),
    .cacheHit(cacheHit), .cacheVal(cacheVal),
    .stall(stall), .if_stall_req(if_stall_req),
    .pred(if_pred), .pred_e(pred_e),
    .btb_hit(btb_hit), .btb_pred(btb_pred)
);

if_id if_id0(
    .clk(clk_in), .rst(rst_in), .rdy(rdy_in),
    .if_pc(if_pc), .if_npc(if_npc), .if_inst(if_inst),
    .id_pc(id_pc_i), .id_npc(id_npc_i), .id_inst(id_inst_i),
    .stall(stall),
    .if_pred(if_pred), .id_pred(id_pred_i),
    .br(branch_if)
);

id id0(
    .rst(rst_in),
    .pc(id_pc_i), .npc(id_npc_i),
    .pc_o(id_pc_o), .npc_o(id_npc_o),

    .inst(id_inst_i), .rdata1(rdata1), .rdata2(rdata2),
    .raddr1(raddr1), .raddr2(raddr2), .re1(re1), .re2(re2),

    .reg1(id_reg1), .reg2(id_reg2), .Imm(id_Imm), .rd(id_rd), .rd_e(id_rd_e),
    .aluop(id_aluop), .alusel(id_alusel), .mem_length(id_mem_length),
    .ex_we(ex_rd_e_o), .ex_waddr(ex_rd_addr), .ex_wdata(ex_rd_data),
    .mem_we(mem_rd_e_o), .mem_waddr(mem_rd_addr_o), .mem_wdata(mem_rd_data_o),

    .pred_i(id_pred_i), .pred_o(id_pred_o),
    .jmp_addr(id_jmp_addr), .if_br(if_br)
);

regfile regfile0(
    .clk(clk_in), .rst(rst_in), .rdy(rdy_in),
    .we(write_e), .waddr(write_addr), .wdata(write_data),
    .re1(re1), .raddr1(raddr1), .rdata1(rdata1),
    .re2(re2), .raddr2(raddr2), .rdata2(rdata2)
);

id_ex id_ex0(
    .clk(clk_in), .rst(rst_in), .rdy(rdy_in),
    .id_pc(id_pc_o), .ex_pc(ex_pc),
    .id_npc(id_npc_o), .ex_npc(ex_npc),
    .id_reg1(id_reg1), .id_reg2(id_reg2),
    .id_Imm(id_Imm), .id_rd(id_rd), .id_rd_e(id_rd_e),
    .id_aluop(id_aluop), .id_alusel(id_alusel),
    .id_mem_length(id_mem_length),
    .ex_reg1(ex_reg1), .ex_reg2(ex_reg2),
    .ex_Imm(ex_Imm), .ex_rd(ex_rd), .ex_rd_e(ex_rd_e_i),
    .ex_aluop(ex_aluop), .ex_alusel(ex_alusel),
    .ex_mem_length(ex_mem_length),
    .id_jmp_addr(id_jmp_addr), .ex_jmp_addr(ex_jmp_addr),
    .id_pred(id_pred_o), .ex_pred(ex_pred),
    .stall(stall), .br(branch_id)
);

ex ex0(
    .clk(clk_in), .rst(rst_in),
    .pc(ex_pc), .npc(ex_npc),
    .reg1(ex_reg1), .reg2(ex_reg2),
    .Imm(ex_Imm), .rd(ex_rd), .rd_e(ex_rd_e_i),
    .aluop(ex_aluop), .alusel(ex_alusel), .mem_length_i(ex_mem_length),

    .rd_data_o(ex_rd_data), .rd_addr(ex_rd_addr), .rd_e_o(ex_rd_e_o),
    .mem_addr(ex_mem_addr), .mem_length_o(ex_mem_length_o),
    
    .jmp_addr(ex_jmp_addr), .pred(ex_pred),
    .jmp_e(jmp_e), .jmp_target(jmp_target),.jmp_addr_o(ex_jmp_addr_o),
    .btb_change_e(btb_change_e), .is_jmp(is_jmp),
    .id_br(id_br)
);

ex_mem ex_mem0(
    .clk(clk_in), .rst(rst_in), .rdy(rdy_in),
    .ex_rd_data(ex_rd_data), .ex_rd_addr(ex_rd_addr), .ex_rd_e(ex_rd_e_o),
    .ex_mem_addr(ex_mem_addr), .ex_mem_length(ex_mem_length_o),
    .mem_rd_data(mem_rd_data_i), .mem_rd_addr(mem_rd_addr_i), .mem_rd_e(mem_rd_e_i),
    .mem_mem_addr(mem_mem_addr), .mem_length(mem_length),
    .stall(stall)
);

mem mem0(
    .clk(clk_in), .rst(rst_in), .rdy(rdy_in),
    .rd_data_i(mem_rd_data_i), .rd_addr_i(mem_rd_addr_i), .rd_e_i(mem_rd_e_i),
    .mem_addr(mem_mem_addr), .mem_length(mem_length),

    .rd_data_o(mem_rd_data_o), .rd_addr_o(mem_rd_addr_o), .rd_e_o(mem_rd_e_o),
    
    .addr_mem(addr_mem), .rw_mem(rw_mem), .mem_times(mem_times),
    .mem_stall_req(mem_stall_req),
    .mem_status(status_mem), .data_from_mem(data_mem_o), .data_to_mem(data_mem_i),
    .stall(stall)
);

mem_wb mem_wb0(
    .clk(clk_in), .rst(rst_in), .rdy(rdy_in),
    .mem_rd_data(mem_rd_data_o), .mem_rd_addr(mem_rd_addr_o),
    .mem_rd_e(mem_rd_e_o),
    .wb_rd_data(write_data), .wb_rd_addr(write_addr), .wb_rd_e(write_e),
    .stall(stall)
);

stall_ctrl stall_ctrl0(
    .clk(clk_in), .rst(rst_in), .rdy(rdy_in),
    .if_stall_req(if_stall_req), .mem_stall_req(mem_stall_req),
    .stall(stall),
    .jmp_e(jmp_e), .if_br(if_br), .id_br(id_br),
    .branch_if(branch_if), .branch_id(branch_id)
);

mem_ctrl mem_ctrl0(
    .clk(clk_in), .rst(rst_in), .rdy(rdy_in),
    .pc(pc),
    .addr_if(pc), .addr_mem(addr_mem),
    .data_mem_i(data_mem_i), .data_mem_o(data_mem_o),
    .rw_if(rw_if), .rw_mem(rw_mem), .mem_times(mem_times),
    .status_if(status_if), .status_mem(status_mem),

    .data_from_out(mem_din), .data_to_out(mem_dout),
    .addr_to_out(mem_a), .wr_out(mem_wr),

    .cacheHit(cacheHit), .cacheVal(cacheVal)

);

// implementation goes here

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read takes 2 cycles(wait till next cycle), write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)

always @(posedge clk_in)
  begin
    if (rst_in)
      begin
      
      end
    else if (!rdy_in)
      begin
      
      end
    else
      begin
      
      end
  end

endmodule