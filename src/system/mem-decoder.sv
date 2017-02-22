`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.05.2016 14:41:25
// Design Name: 
// Module Name: mem_decoder
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

interface mem_iface ();
    bit en_rom, en_ram, ready;
    logic [31:0] addr;
    logic [31:0] rom_addr;
    logic [31:0] cpu_rdata;
    logic [31:0] rom_rdata;
    logic [31:0] ram_rdata;
    logic [31:0] wdata;
    logic [3:0]  wstrb;
    
    modport cpu(output addr, output wdata, output wstrb,
                input cpu_rdata, input ready);
    modport rom(input rom_addr, input en_rom, output rom_rdata);
    modport ram(input addr, input wstrb, input en_ram, input wdata,
                output ram_rdata);
    modport dec(input addr, input ram_rdata, input rom_rdata, 
                output en_rom, output en_ram, output ready, output rom_addr, output cpu_rdata);
endinterface

module mem_decoder #(parameter rom_base = 0, parameter rom_size = 1024,
        parameter ram_base = 1024, parameter ram_size = 6144) (
    mem_iface decif
);

    assign decif.en_rom = (decif.addr >= rom_base && decif.addr < rom_base + rom_size);
    assign decif.en_ram = (decif.addr >= ram_base && decif.addr < ram_base + ram_size);
    assign decif.ready = decif.en_rom | decif.en_ram;
    assign decif.cpu_rdata = decif.en_rom ? decif.rom_rdata : decif.ram_rdata;
    assign decif.rom_addr = decif.addr[31:2];
    
endmodule
