`include "defines.v"

module if_stage(
    input   wire        rst,
    input   wire        clk,
    input   wire        rdy,

    input   wire[`InstAddrBus]  pc,
    output  wire[`InstAddrBus]  pc_o,
    input   wire[`InstAddrBus]  npc,
    output  wire[`InstAddrBus]  npc_o,

    output  reg[`InstBus]       inst,
    output  reg                 rw,
    input   wire[`InstAddrBus]  data_from_mem,
    input   wire[1 : 0]         mem_status,

    input   wire                cacheHit,
    input   wire[`InstBus]      cacheVal,

    input   wire[`StallBus]     stall,
    input   wire                pc_e,
    output  reg                 if_stall_req,

   // Prediction
   input    wire                btb_hit,
   input    wire[`InstAddrBus]  btb_pred,
   output   reg[`InstAddrBus]   pred,
   output   reg                 pred_e
);

assign pc_o = pc;
assign npc_o = npc;

reg _if_stall_req;
reg[`InstBus] _inst;
reg _rw;

wire    is_load;
assign is_load = (_inst[6 : 0] == 7'b0000011);

always @ (posedge clk) begin
    if (rdy) begin
        _inst <= inst;
        _if_stall_req <= if_stall_req;
        _rw <= rw;
    end
end


always @ (*) begin
    if (rst) begin
        rw = 0;
        if_stall_req = 0;
        inst = 0;
        pred_e = 0;
        pred = 0;
    end else begin
        pred_e = 0;
        pred = 0;
        if (mem_status == `DONE) begin
            rw = 0;
            inst = data_from_mem;
            if_stall_req = 0;
            if (btb_hit) begin
                pred_e = 1;
                pred = btb_pred; //btb_pred
            end else begin
                pred_e = 0;
                pred = pc + 4;
            end
        end else if (mem_status == `INIT && pc_e) begin
            if ((!cacheHit) || is_load) begin
                rw = 1;
                if_stall_req = 1;
                inst = _inst;
            end else if (cacheHit) begin
                inst = cacheVal;
                if_stall_req = 0;
                rw = 0;
                if (btb_hit) begin
                    pred_e = 1;
                    pred = btb_pred;
                end else begin
                    pred_e = 0;
                    pred = pc + 4;
                end
            end
        end else begin
            inst = _inst;
            if_stall_req = _if_stall_req;
            rw = _rw;
        end
    end
end

endmodule // if