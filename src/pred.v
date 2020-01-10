`include "defines.v"

module predictor(
    input   wire    clk,
    input   wire    rst,
    input   wire    rdy,
    input   wire[`InstAddrBus]  addr,

    input   wire[`InstAddrBus]  addr_r,
    input   wire                jmp_r,
    input   wire[`InstAddrBus]  target_real,
    input   wire                change_e,
    input   wire[`InstAddrBus]  target_addr,
    
    output  wire                jmp_e,
    output  wire[`InstAddrBus]  pred
);


`define PREDSize     128
`define PREDSizeLen  7
`define PREDBus      127 : 0
`define PREDEntryBus 8 : 2
reg[4 : 0]  tag[`PREDBus];
reg[12 : 0] target[`PREDBus];
reg[1 : 0]  valid[`PREDBus];

assign hit = (tag[addr[`PREDEntryBus]] == addr[13 : 9]);
assign PREDvalid = (valid[addr[`PREDEntryBus]] > 2'b01);

assign jmp_e = PREDvalid ? hit : 0;
assign pred = target[addr[`PREDEntryBus]];

integer i;

always @ (posedge clk) begin
    if (rst) begin
        for (i = 0; i < `PREDSize; i=i+1) begin
            valid[i] <= 2'b10;
        end
    end
    else if (rdy && jmp_r && change_e) begin // is a branch && token
        tag[addr_r[`PREDEntryBus]] <= addr_r[13 : 9];
        target[addr_r[`PREDEntryBus]] <= target_addr[12 : 0];
        if (valid[addr_r[`PREDEntryBus]] != 2'b11)
            valid[addr_r[`PREDEntryBus]] <= valid[addr_r[`PREDEntryBus]] + 1;
    end if (rdy && jmp_r && (!change_e)) begin //is a branch && nottoken
        tag[addr_r[`PREDEntryBus]] <= addr_r[13 : 9];
        target[addr_r[`PREDEntryBus]] <= target_addr[12 : 0];
        if (valid[addr_r[`PREDEntryBus]] != 2'b00)
            valid[addr_r[`PREDEntryBus]] <= valid[addr_r[`PREDEntryBus]] - 1;        
    end
end

endmodule // predictor