`ifndef DEFINES_V
`define DEFINES_V

`define RstEnable       1'b1
`define RstDisable      1'b0
`define ZeroWord        32'h00000000
`define WriteEnable     1'b1
`define WriteDisable    1'b0
`define ReadEnable      1'b1
`define ReadDisable     1'b0
`define Enable 			1'b1
`define Disable   	 	1'b0

// Inst Memory
`define InstAddrBus     31 : 0
`define InstBus         31 : 0
`define InstMemNum      1310701
`define InstMemNumLog2  17

`define StallBus        5 : 0      

//Memory
`define MemAddrBus	 	31:0
`define MemBus			7 : 0

//MEMCTRL
`define INIT  			2'b00
`define READ  			2'b01
`define WRITE 			2'b10
`define DONE 			2'b11
`define WORKING			2'b01

// Data Memory
`define DataAddrBus     31:0
`define DataBus         31:0
`define DataMemNum      131072
`define DataMemNumLog2  17

// Register File
`define RegWidth        32
`define RegAddrBus      4 : 0
`define RegBus          31 : 0
`define RegNum          32
`define RegNumLog2      5

// ALU
`define AluOpWidth      6
`define AluSelWidth     3
`define AluOpBus        7 : 0
`define AluSelBus       2 : 0

`define OpWidth         7
`define Op2Width        3
`define Op3Width        7
`define tagWidth        5
`define dataWidth       32
`define instWidth       32
`define addrWidth       32
`define newopWidth      5 

`define RamDataBus      8


`define OpRange         6  : 0  
`define funct3Range     14 : 12
`define funct7Range     31 : 25
`define rdRange         11 : 7
`define rsRange        19 : 15   
`define rtRange        24 : 20
`define ImmRange        31 : 20
`define UImmRange       31 : 12

`define cutRange        3 : 0
`define tagFree         5'b11111

//Instruction
`define OP_OP_I			7'b0010011
`define OP_OP			7'b0110011
`define OP_LUI			7'b0110111
`define OP_AUIPC		7'b0010111
`define OP_JAL			7'b1101111
`define OP_JALR			7'b1100111 
`define OP_BRANCH		7'b1100011
`define OP_LOAD			7'b0000011
`define OP_STORE		7'b0100011

/*
  	Instruction funct3
*/

// OP_IMM
`define FUNCT3_ADDI			3'b000
`define FUNCT3_SLLI			3'b001
`define FUNCT3_SLTI			3'b010
`define FUNCT3_SLTIU		3'b011
`define FUNCT3_XORI			3'b100
`define FUNCT3_SRLI_SRAI	3'b101
`define FUNCT3_ORI  		3'b110
`define FUNCT3_ANDI 		3'b111

// OP
`define FUNCT3_ADD_SUB	3'b000
`define FUNCT3_SLL		3'b001
`define FUNCT3_SLT		3'b010
`define FUNCT3_SLTU		3'b011
`define FUNCT3_XOR 		3'b100
`define FUNCT3_SRL_SRA	3'b101
`define FUNCT3_OR  		3'b110
`define FUNCT3_AND  	3'b111

// BRANCH
`define FUNCT3_BEQ		3'b000
`define FUNCT3_BNE		3'b001
`define FUNCT3_BLT		3'b100
`define FUNCT3_BGE		3'b101
`define FUNCT3_BLTU		3'b110
`define FUNCT3_BGEU		3'b111

// LOAD
`define FUNCT3_LB		3'b000
`define FUNCT3_LH		3'b001
`define FUNCT3_LW		3'b010
`define FUNCT3_LBU		3'b100
`define FUNCT3_LHU		3'b101

// STORE
`define FUNCT3_SB		3'b000
`define FUNCT3_SH		3'b001
`define FUNCT3_SW		3'b010

/*
	Instruction funct7
*/

// ADD_SUB
`define FUNCT7_ADD		7'b0000000
`define FUNCT7_SUB		7'b0100000

// SRLI_SRAI
`define FUNCT7_SRLI		7'b0000000
`define FUNCT7_SRAI		7'b0100000

// SRL_SRA
`define FUNCT7_SRL		7'b0000000
`define FUNCT7_SRA		7'b0100000


`define FlushInst 		32'h00000001
`define Flushed 		7'b0000001

/*
	AluSel
*/
`define EXE_RES_NOP			3'b000
`define EXE_RES_ARITH		3'b001
`define EXE_RES_LUI			3'b010
`define EXE_RES_AUIPC		3'b011
`define EXE_RES_BRANCH		3'b100
`define EXE_RES_LOAD		3'b101
`define EXE_RES_STORE		3'b110
`define EXE_RES_JAL			3'b111

/*
	AluOp
*/
`define NOP    5'b00000
`define LUI    5'b00001
`define AUIPC  5'b00010
`define JAL    5'b00011
`define JALR   5'b00100
`define BEQ    5'b00101 
`define BNE    5'b00110     
`define BLT    5'b00111     
`define BGE    5'b01000     
`define BLTU   5'b01001     
`define BGEU   5'b01010     
`define LB     5'b01011    
`define LH     5'b01100    
`define LW     5'b01101    
`define LBU    5'b01110    
`define LHU    5'b01111    
`define SB     5'b10000    
`define SW     5'b10001    
`define SH     5'b10010    
`define ADD    5'b10011
`define SUB    5'b10100   
`define SLL    5'b10101   
`define SLT    5'b10110   
`define SLTU   5'b10111    
`define XOR    5'b11000
`define SRL    5'b11001
`define SRA    5'b11010   
`define OR     5'b11011   
`define AND    5'b11100
`define ADD2   5'b11101
`define FLUSH  5'b11111

`endif