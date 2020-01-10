`include "defines.v"

module cache(
    input wire      clk,
    input wire      rst,
    input wire      rdy,
    input wire[`InstAddrBus]    addr,
    input wire[`InstBus]        data_i,
    input wire      work,

    output  wire[`InstBus]      data_o,
    output  wire                isHit,
    output  wire                isValid
);
`define CacheSizeLen    8
`define CacheSize       256
`define CacheBus        255 : 0
`define TagLen          5
`define TagBus          4 : 0
`define AddrEntryBus    9 : 2
`define AddrTagBus      14 : 10

reg[`InstBus]   data[`CacheBus];
reg             valid[`CacheBus];
reg[`TagBus]    tag[`CacheBus];

assign data_o = data[addr[`AddrEntryBus]];
assign isValid = (valid[addr[`AddrEntryBus]] == 1);
assign isHit = (valid[addr[`AddrEntryBus]] == 1) ? (tag[addr[`AddrEntryBus]] == addr[`AddrTagBus]) : 0;

integer i;
always @ (posedge clk) begin
    if (rst) begin
        for (i = 0; i < `CacheSize; i=i+1) begin
            valid[i] <= 0;
        end
    end else if (rdy && work) begin
        data[addr[`AddrEntryBus]] <= data_i;
        tag[addr[`AddrEntryBus]] <= addr[`AddrTagBus];
        valid[addr[`AddrEntryBus]] <= 1;
    end
end

endmodule