`include "defines.v"

module regfile(
    input   wire            clk,
    input   wire            rst,
    input   wire            rdy,

    input   wire            we,
    input   wire[`RegAddrBus]   waddr,
    input   wire[`RegBus]       wdata,

    input   wire            re1,
    input   wire[`RegAddrBus]   raddr1,
    output  reg[`RegBus]        rdata1,

    input   wire            re2,
    input   wire[`RegAddrBus]   raddr2,
    output  reg[`RegBus]        rdata2
);

reg[`RegBus]    regs[`RegNum-1 : 0];

integer i;

always @ (posedge clk) begin
    if (rst) begin
        for (i = 0; i < `RegNum; i=i+1) regs[i] <= 0;
    end else if (rdy && we) begin
        if (waddr != 0)
            regs[waddr] <= wdata;
    end
end

always @ (*) begin
    if (!rst && re1) begin
        if (raddr1 == 0) begin
            rdata1 = 0;
        end
        else if (we && raddr1 == waddr) begin
            rdata1 = wdata;
        end else begin
            rdata1 = regs[raddr1];
        end
    end else begin
        rdata1 = 0;
    end
end
always @ (*) begin
    if (!rst && re2) begin
        if (raddr2 == 0) begin
            rdata2 = 0;
        end
        else if (we && raddr2 == waddr) begin
            rdata2 = wdata;
        end else begin
            rdata2 = regs[raddr2];
        end
    end else begin
        rdata2 = 0;
    end
end

endmodule // regfile