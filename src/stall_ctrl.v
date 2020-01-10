`include "defines.v"

module stall_ctrl(
    input   wire    rst,
    input   wire    clk,
    input   wire    rdy,
    input   wire    if_stall_req,
    input   wire    mem_stall_req,

    input   wire    jmp_e,
    input   wire    if_br,
    input   wire    id_br,
    output  reg     branch_if,
    output  reg     branch_id,

    output  reg[`StallBus]  stall
);

always @(*) begin
    if (rst) begin
        stall = 6'b000000;
    end else if (!rdy) begin
        stall = 6'b111111;
    end else if (mem_stall_req) begin
        stall = 6'b011111;
    end else if (if_stall_req) begin
        stall = 6'b000011;        
    end else begin
        stall = 6'b000000;
    end
end

reg _branch_if, _branch_id;

always @ (posedge clk) begin
    if (rdy) begin
        _branch_if <= branch_if;
        _branch_id <= branch_id;
    end
end

always @ (*) begin
    if (rst) begin
        branch_if = 0;
        branch_id = 0;
    end else begin
        if (jmp_e) begin
            branch_if = 1;
            branch_id = 1;
        end else begin
            branch_if = _branch_if;
            branch_id = _branch_id;
        end

        if (if_br)  branch_if = 0;
        if (id_br)  branch_id = 0;
    end
end

endmodule // stall_ctrl