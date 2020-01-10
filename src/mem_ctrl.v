`include "defines.v"

module mem_ctrl(
    input   wire        rst,
    input   wire        clk,
    input   wire        rdy,
    input   wire[`InstAddrBus]  pc,

    input   wire[`InstAddrBus]  addr_if,
    input   wire[`MemAddrBus]   addr_mem,
    input   wire[`DataBus]      data_mem_i,
    output  reg[`DataBus]       data_mem_o,

    input   wire                rw_if,
    input   wire[1 : 0]         rw_mem,
    input   wire[2 : 0]         mem_times,
    
    output  reg[1 : 0]          status_if,
    output  reg[1 : 0]          status_mem,

    //Cache
    output  wire                cacheHit,
    output  wire[`InstBus]      cacheVal,

    //To outside
    input   wire[`MemBus]       data_from_out,
    output  reg[`MemBus]        data_to_out,
    output  reg                 wr_out,
    output  reg[`MemAddrBus]    addr_to_out
);

reg c_work[1 : 0];
wire c_valid[1 : 0], c_hit[1 : 0];
wire[`InstBus]  c_data[1 : 0];

cache cache0(
    .clk(clk),
    .rst(rst),
    .rdy(rdy),
    .addr(pc),
    .work(c_work[0]),
    .data_i(data_mem_o),
    .data_o(c_data[0]),
    .isValid(c_valid[0]),
    .isHit(c_hit[0])
);

cache cache1(
    .clk(clk),
    .rst(rst),
    .rdy(rdy),
    .addr(pc),
    .work(c_work[1]),
    .data_i(data_mem_o),
    .data_o(c_data[1]),
    .isValid(c_valid[1]),
    .isHit(c_hit[1])
);

assign cacheVal = c_hit[0] ? c_data[0] : c_data[1];
assign cacheHit = c_hit[0] || c_hit[1];

reg[2 : 0] times;
reg[3 : 0] cnt;
reg[1 : 0] status;

always @ (posedge clk) begin
    if (rst) begin
        status <= `INIT;
        status_if <= 0;
        status_mem <= 0;
        wr_out <= 0;
        c_work[0] <= 0;
        c_work[1] <= 0;
        times <= 0;
        cnt <= 0;
    end else if (rdy) begin
        case (status)
            `INIT: begin
                data_mem_o <= 0;
                cnt <= 0;
                status_mem <= `INIT;
                status_if <= `INIT;
                wr_out <= 0;
                addr_to_out <= 0;
                c_work[0] <= 0;
                c_work[1] <= 0;
                if (rw_mem != 2'b00) begin
                    wr_out <= (rw_mem == 2'b10);
                    addr_to_out <= addr_mem;
                    times <= mem_times;
                    status_mem <= `WORKING;
                    if (rw_mem == 2'b01)
                        status <= `READ;
                    else begin
                        data_to_out <= data_mem_i[7 : 0];
                        status <= `WRITE;
                    end
                end else if (rw_if != 0) begin
                    wr_out <= 0;
                    addr_to_out <= addr_if;
                    times <= 3'b100;
                    status_if <= `WORKING;
                    status <= `READ;
                end
            end
            `READ: begin
                cnt <= cnt + 1;
                if (cnt <= 2 && times >= 2) begin
                    addr_to_out <= addr_to_out + 1;
                end
                if (cnt == 1) begin
                    data_mem_o[7 : 0] <= data_from_out;
                end else if (cnt == 2) begin
                    data_mem_o[15 : 8] <= data_from_out;
                end else if (cnt == 3) begin
                    data_mem_o[23 : 16] <= data_from_out;
                end else if (cnt == 4) begin
                    data_mem_o[31 : 24] <= data_from_out;
                end
                times <= times - 1;

                if (cnt ==4 || times == 0) begin
                    status <= `INIT;
                    addr_to_out <= 0;

                    if (status_if == `WORKING) begin
                        status_if <= `DONE;
                        if (!c_valid[0])
                            c_work[0] <= 1;
                        else
                            c_work[1] <= 1;
                    end else begin
                        status_mem <= `DONE;
                    end
                end
            end
            `WRITE: begin
                cnt <= cnt + 1;
                if (cnt == 0) begin
                    data_to_out <= data_mem_i[15 : 8];
                end else if (cnt == 1) begin
                    data_to_out <= data_mem_i[23 : 16];
                end else if (cnt == 2) begin
                    data_to_out <= data_mem_i[31 : 24];
                end

                times <= times - 1;
                addr_to_out <= addr_to_out + 1;
                if (cnt == 2 || times <= 2) begin
                    status <= `INIT;
                    status_mem <= `DONE;
                end
            end
            default : begin
            end
        endcase
    end
end

endmodule // mem_ctrl