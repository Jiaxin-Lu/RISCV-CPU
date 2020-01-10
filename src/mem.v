`include "defines.v"

module mem (
    input   wire        rst,
    input   wire        clk,
    input   wire        rdy,
    
    input   wire[`RegBus]        rd_data_i,
    input   wire[`RegAddrBus]    rd_addr_i,
    input   wire[`DataAddrBus]   mem_addr,
    input   wire                 rd_e_i,
    input   wire[4 : 0]          mem_length,
    
    output  reg[`RegBus]         rd_data_o,
    output  reg[`RegAddrBus]     rd_addr_o,
    output  reg                  rd_e_o,

// To men_ctrl
    output  reg[`MemAddrBus]    addr_mem,
    output  reg[`DataBus]       data_to_mem,
    output  reg[1 : 0]          rw_mem,
    output  reg[2 : 0]          mem_times,

    input   wire[`DataBus]      data_from_mem,
    input   wire[1 : 0]         mem_status,
// Stall
    input   wire[`StallBus]     stall,
    output  reg                 mem_stall_req
);

reg _mem_stall_req;

always @(posedge clk) begin
    if (rdy) begin
        _mem_stall_req <= mem_stall_req;
    end
end

always @ (*) begin
    if (rst) begin
        rd_data_o = 0;
        rd_addr_o = 0;
        rd_e_o = 0;
        mem_stall_req = 0;
        rw_mem = 0;
        addr_mem = 0;
        mem_times = 0;
        data_to_mem = 0;
    end else begin
        if (mem_length == 4'b0000) begin
            rd_data_o = rd_data_i;
            rd_addr_o = rd_addr_i;
            rd_e_o = rd_e_i;
            mem_stall_req = 0;
            rw_mem = 0;
            addr_mem = 0;
            mem_times = 0;
            data_to_mem = 0;
        end else if (mem_length[4] == 0) begin  //LOAD
            data_to_mem = 0;
            rd_addr_o = rd_addr_i;
            rd_data_o = 0;
            rd_e_o = 1;
            mem_times = mem_length[2 : 0];

            rw_mem = 2'b01;
            addr_mem = rd_data_i;
            if (mem_status == `DONE) begin
                if (mem_length[3] == 1) begin //USIGNED
                    if (mem_length[0] == 1) begin // LBU
                        rd_data_o = {{24{1'b0}} , data_from_mem[7 : 0]};
                    end else begin //LHU
                        rd_data_o = {{16{1'b0}} , data_from_mem[15 : 0]} ;
                    end
                end else begin  //SIGNED
                    if (mem_length[0] == 1) begin // LB
                        rd_data_o = $signed(data_from_mem[7 : 0]);
                    end else if (mem_length[1] == 1) begin //LH
                        rd_data_o = $signed(data_from_mem[15 : 0]);
                    end else begin //LW
                        rd_data_o = $signed(data_from_mem[31 : 0]);
                    end
                end
                mem_stall_req = 0;
                rw_mem = 2'b00;
            end else if (mem_status == `INIT) begin
                mem_stall_req = 1;
            end else begin
                mem_stall_req = _mem_stall_req;
            end            
        end else begin // STORE
            rd_data_o = 0;
            rd_e_o = 0;
            rd_addr_o = rd_addr_i;
            mem_times = mem_length[2 : 0];
            data_to_mem = rd_data_i;
            addr_mem = mem_addr;
            rw_mem = 2'b10;
            if (mem_status == `DONE) begin
                mem_stall_req = 0;
                rw_mem = 2'b00;
            end else if(mem_status == `INIT) begin
                mem_stall_req = 1;
            end else begin
                mem_stall_req = _mem_stall_req;
            end
        end
    end
end

endmodule