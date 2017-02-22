`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.05.2016 13:58:39
// Design Name: 
// Module Name: picorv32_mem
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

module picorv32_mem #(
        parameter ROM_BASE=0,
        parameter ROM_SIZE=2048,
        parameter RAM_BASE=32'h0000_8000,
        parameter RAM_SIZE=32'h0000_8000 //32KB
    )(
        input           clk,
        input  [3:0]    mem_wstrb,
        input  [31:0]   mem_addr,
        input  [31:0]   mem_wdata,
        output [31:0]   mem_rdata
    );
    
    wire sel_ram, sel_rom;
    wire [3:0]  ram_wstrb;
    wire [31:0] ram_addr, ram_rdata, ram_wdata,
                rom_addr, rom_rdata;
    
    /* Select device */
    assign sel_rom = mem_addr >= ROM_BASE && mem_addr < ROM_BASE + ROM_SIZE;
    assign sel_ram = mem_addr >= RAM_BASE && mem_addr < RAM_BASE + RAM_SIZE;
    
    /* Assign RAM input based on selection */
    assign ram_wstrb = sel_ram ? mem_wstrb : 0;
    assign ram_addr = sel_ram ? ((mem_addr - RAM_BASE) >> 2) : 0;
    assign ram_wdata = sel_ram ? mem_wdata : 0;
    
    /* Assign ROM input based on selection */
    assign rom_addr = sel_rom ? ((mem_addr - ROM_BASE) >> 2) : 0;
    
    /* Assign mem output based on selection */
    assign mem_rdata = sel_ram ? ram_rdata : sel_rom ? rom_rdata : 0;
    
    picorv32_bram ram (
      .clka(clk),    // input wire clka
      .wea(ram_wstrb),      // input wire [3 : 0] wea
      .addra(ram_addr),  // input wire [12 : 0] addra
      .dina(ram_wdata),    // input wire [31 : 0] dina
      .douta(ram_rdata)  // output wire [31 : 0] douta
    );
    
    picorv32_brom rom (
      .clka(clk),    // input wire clka
      .addra(rom_addr),  // input wire [8 : 0] addra
      .douta(rom_rdata)  // output wire [31 : 0] douta
    );
    
endmodule