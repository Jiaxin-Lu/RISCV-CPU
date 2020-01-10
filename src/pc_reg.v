`include "defines.v"

module pc_reg(
    input   wire    clk,
    input   wire    rst,
    input   wire    stall,
    input   wire    rdy,
    output  reg[`InstAddrBus]   pc,
    output  reg[`InstAddrBus]   npc,
    output  reg                 pc_e,

//  Prediction
    input   wire[`InstAddrBus]  jmp_target,
    input   wire                jmp_e,
    input   wire[`InstAddrBus]  pred,
    input   wire                pred_e
);

reg pc_done;

always @ (posedge clk) begin
    if (rst) begin
        npc <= 0;
        pc <= 0;
        pc_done <= 0;
        pc_e <= 1;
    end else if (rdy) begin
        if (jmp_e == 1) begin
            if (stall == 0) begin
                pc <= jmp_target;
                npc <= jmp_target + 4;
                pc_e <= 1;
            end else begin
                pc_done <= 1;
                pc_e <= 0;
                npc <= jmp_target;
            end
        end
        else if (pred_e == 1 && pc_done == 0) begin
            if (stall == 0) begin
                pc <= pred;
                npc <= pred + 4;
                pc_e <= 1;
            end else begin
                pc_e <= 0;
                npc <= pred;
            end
        end else if (stall == 0) begin
            pc <= npc;
            npc <= npc + 4;
            pc_done <= 0;
            pc_e <= 1;
        end else begin
            pc_e <= 0;
        end
    end
end

endmodule