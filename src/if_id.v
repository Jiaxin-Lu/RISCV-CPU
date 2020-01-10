`include "defines.v"

module if_id(
    input   wire    clk,
    input   wire    rst,
    input   wire    rdy,

    input   wire[`InstAddrBus]  if_pc,
    input   wire[`InstAddrBus]  if_npc,
    input   wire[`InstBus]      if_inst,
    input   wire[`InstAddrBus]  if_pred,

    output  reg[`InstAddrBus]   id_pc,
    output  reg[`InstAddrBus]   id_npc,
    output  reg[`InstBus]       id_inst,
    output  reg[`InstAddrBus]   id_pred,

    input   wire                br,
    input   wire[`StallBus]     stall
);

always @ (posedge clk) begin
    if (rst || (stall[1] == 1 && stall[2] == 0)) begin
        id_pc <= 0;
        id_npc <= 0;
        id_inst <= 0;
        id_pred <= 0;
    end else if (rdy && stall[1] == 0) begin
        if (!br) begin
            id_pc <= if_pc;
            id_npc <= if_npc;
            id_inst <= if_inst;
            id_pred <= if_pred;
        end else begin
            id_inst <= `FlushInst;
            id_pc <= 0;
            id_npc <= 0; 
            id_pred <= 0;
        end
    end
end

endmodule // if_id