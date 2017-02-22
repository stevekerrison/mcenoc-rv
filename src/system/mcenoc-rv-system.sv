`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Bristol
// Engineer: Steve Kerrison
// 
// Create Date: 10.05.2016 12:36:42
// Design Name: mcenoc-rv
// Module Name: mcenoc-rv-system
// Project Name: MCENoC RISC V
// Target Devices: Kintex-7 (Trenz Electric)
// Tool Versions: 2016.01
// Description: 
// 
// Dependencies: picorv32, mcenoc-switch
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module mcenoc_rv_system_top (
    input clk_in_p,
    input clk_in_n,
    input uart_rx,
    output uart_tx,
    output led,
    output usbclk,
    output pll_clk_en,
    output pll_i2c_in4
    );
    
    assign pll_clk_en = 1'b1;
    assign pll_ic2_in4 = 1'b0;
    
    mcenoc_rv_system #(.num_cores(16), .mcenoc_data_width(8), .mcenoc_bits_per_switch(1)) sys(.*);
endmodule

module mcenoc_rv_system_tb (
    output uart_tx
);
    reg clk_in_p = 0, uart_rx = 1;
    wire clk_in_n, led;
    wire usbclk;
    
    assign clk_in_n = ~clk_in_p;
    
    always #5 clk_in_p = ~clk_in_p;
    
    mcenoc_rv_system #(.num_cores(8), .mcenoc_data_width(8), .mcenoc_bits_per_switch(1)) dut(.*);
    
    initial begin
        /* Generate a 'K' to test UART receive in simulation
         * Put it at 400us, after the program has started */
        #300000 uart_rx <= 0;
        #80 uart_rx <= 1;
        #80 uart_rx <= 1;
        #80 uart_rx <= 0;
        #80 uart_rx <= 1;
        #80 uart_rx <= 0;
        #80 uart_rx <= 0;
        #80 uart_rx <= 1;
        #80 uart_rx <= 0;
        #80 uart_rx <= 1;

    end

    initial begin
        #1000000 $finish();
    end
endmodule

/* Test the interface behaviour open-ended */
module mcenoc_ni_open_test #(
    parameter MCENOC_DATA_WIDTH=1,
    parameter MCENOC_BITS_PER_SWITCH=1
) (
    input           clk,
    input           resetn,
    input           reset,
    input           pcpi_valid,
    input   [31:0]  pcpi_insn,
    input   [31:0]  pcpi_rs1,
    input   [31:0]  eoi,
    output  [31:0]  pcpi_rd,
    output          pcpi_wr,
    output          pcpi_wait,
    output          pcpi_ready,
    output  [31:0]  irq,
    input   [MCENOC_DATA_WIDTH-1:0] data_in,
    input           act_in,
    input           err_in,
    input           cts_in,
    input           clm_in
);

    wire [MCENOC_DATA_WIDTH-1:0] data_out;
    wire act_out;
    wire clm_out;
    wire err_out;
    wire cts_out;

    pcpi_mcenoc_ni #(
        .NETWORK_BITS_PER_SWITCH(MCENOC_BITS_PER_SWITCH),
        .NETWORK_DWIDTH(MCENOC_DATA_WIDTH),
        .OPEN_SVA(1) /* Enable open-ended assertion checking */
    ) mcenoc_ni (
        .irq(irq[4]),
        .eoi(eoi[4]),
        .*
    );

endmodule

/* Test the interface behaviour without the network switches */
module mcenoc_ni_loopback_test #(
    parameter MCENOC_DATA_WIDTH=1,
    parameter MCENOC_BITS_PER_SWITCH=1
) (
    input           clk,
    input           resetn,
    input           pcpi_valid,
    input   [31:0]  pcpi_insn,
    input   [31:0]  pcpi_rs1,
    input   [31:0]  eoi,
    output  [31:0]  pcpi_rd,
    output          pcpi_wr,
    output          pcpi_wait,
    output          pcpi_ready,
    output  [31:0]  irq
);

    wire [MCENOC_DATA_WIDTH-1:0]dat_in;
    wire act;
    wire clm;
    wire err;
    wire cts;
    wire [MCENOC_DATA_WIDTH-1:0]dat;
    wire reset;
    assign reset = !resetn;


    pcpi_mcenoc_ni #(
        .NETWORK_BITS_PER_SWITCH(MCENOC_BITS_PER_SWITCH),
        .NETWORK_DWIDTH(MCENOC_DATA_WIDTH),
        .NETWORK_NPORTS(1)
    ) mcenoc_ni (
        .data_in(dat),
        .clm_in(clm),
        .act_in(act),
        .cts_out(cts),
        .err_out(err),
        .data_out(dat),
        .clm_out(clm),
        .act_out(act),
        .cts_in(cts),
        .err_in(err),
        .irq(irq[4]),
        .eoi(eoi[4]),
        .*
    );
`ifdef SVA_ENABLE_0

    /* Format verification of PCPI MCENoC NI, loopback specific */
    default clocking svaclk @(posedge clk);
    endclocking
    default disable iff (!resetn);
    
    assume property (!err && !eoi && !irq);
    
    sequence initclaim();
        /* Start from no instruction or claim */
        ($rose(resetn) && !err && !clm && !pcpi_valid) ##1
        /* Claim the port */
        pcpi_valid && pcpi_insn[6:0] == 7'b0001011 && pcpi_insn[31:25] == 26 &&
            pcpi_insn[23:20] == 4'b0 && pcpi_insn[24] == 1 && pcpi_rs1 == 1 ##1 
        /* Idle cycle */
        !pcpi_valid;
    endsequence
    
    initclaimv: assert property (
        initclaim() |-> $past(pcpi_ready) && clm
    );
    
    sequence txword();
        /* Do the TX */
        pcpi_valid && pcpi_insn[6:0] == 7'b0001011 && pcpi_insn[31:25] == 25 &&
            pcpi_insn[21:20] == 2'h3 && $stable(pcpi_rs1);
    endsequence
    
    txwordstart: assert property(
        initclaim() ##1 txword() [*1:3] |-> pcpi_wait && !pcpi_ready
    );
    
    txwordend: assert property(
        initclaim() ##1 txword() [*4] |-> $fell(pcpi_wait) && $rose(pcpi_ready) && pcpi_valid ##1 pcpi_valid
    );
    
    sequence rxword();
        pcpi_valid && pcpi_insn[6:0] == 7'b0001011 && pcpi_insn[31:25] == 24 &&
            pcpi_insn[21:20] == 2'h3;
    endsequence
    
    rxwordstart: assert property(
        initclaim() ##1 txword() [*4] ##0 pcpi_ready ##1 $fell(pcpi_valid) |=> 1'b0
    );
    
    property endtoend();
        bit [31:0] txdata;
        initclaim() ##1 (txword(), txdata = pcpi_rs1) ##1 txword() [*4] ##1
        /* Wait a cycle */
        !pcpi_valid ##1
        /* Do the RX */
        pcpi_valid && pcpi_insn[6:0] == 7'b0001011 && pcpi_insn[31:25] == 24 &&
            pcpi_insn[21:20] == 2'h3 [*4]
        /* Check that data arrives intact */
        |-> pcpi_ready && pcpi_wr && pcpi_rd == txdata;
    endproperty
    
    txrx: assert property (endtoend());
`endif

endmodule

module mcenoc_network_test #(
        parameter num_cores = 16,
        parameter mcenoc_data_width=8,
        parameter bits_per_switch=1
    ) (
        input           clk,
        input           resetn,
        input           pcpi_valid,
        input   [31:0]  pcpi_insn,
        input   [31:0]  pcpi_rs1,
        input   [31:0]  eoi,
        output  [31:0]  pcpi_rd,
        output          pcpi_wr,
        output          pcpi_wait,
        output          pcpi_ready,
        output  [31:0]  irq
);

    wire reset = !resetn;
    wire [mcenoc_data_width-1:0]dat_in[num_cores-1:0];
    wire act_in[num_cores-1:0];
    wire clm_in[num_cores-1:0];
    wire err_in[num_cores-1:0];
    wire cts_in[num_cores-1:0];
    wire [mcenoc_data_width-1:0]dat_out[num_cores-1:0];
    wire cts_out[num_cores-1:0];
    wire err_out[num_cores-1:0];
    wire act_out[num_cores-1:0];
    wire clm_out[num_cores-1:0];

    uob_network #(
        .n_ports(num_cores),
        .data_width(mcenoc_data_width),
        .bits_per_switch(bits_per_switch),
        .asrt_on(0)
    ) nw (
        .rst(reset),
        .*
    );

    genvar port;
    generate
        for (port = 1; port <  num_cores; port = port + 1) begin:uobnpull
            assign dat_in[port] = 1'b0;
            assign act_in[port] = 1'b0;
            assign clm_in[port] = 1'b0;
            assign err_in[port] = 1'b0;
            assign cts_in[port] = 1'b0;
        end
    endgenerate

    pcpi_mcenoc_ni #(
        .NETWORK_NPORTS(num_cores),
        .NETWORK_BITS_PER_SWITCH(1),
        .NETWORK_DWIDTH(mcenoc_data_width)
    ) mcenoc_ni (
        .data_in(dat_out[0]),
        .clm_in(clm_out[0]),
        .act_in(act_out[0]),
        .cts_out(cts_in[0]),
        .err_out(err_in[0]),
        .data_out(dat_in[0]),
        .clm_out(clm_in[0]),
        .act_out(act_in[0]),
        .cts_in(cts_out[0]),
        .err_in(err_out[0]),
        .irq(irq[4]),
        .eoi(eoi[4]),
        .*
    );


endmodule

module mcenoc_rv_system #(
    parameter num_cores = 1,
    parameter mcenoc_data_width=1,
    parameter reset_time = 64,
    parameter mcenoc_bits_per_switch=1
) (
    input clk_in_p,
    input clk_in_n,
    input uart_rx,
    output uart_tx,
    output led,
    output usbclk
);

    wire clk, locked;
    reg resetn = 0;
    integer rstcnt = 0;
    wire reset;
    assign reset = !resetn;
    
    mcenoc_clk clkblk(.clk_in1_p(clk_in_p), .clk_in1_n(clk_in_n), .clk_out1(clk), .clk_out2(usbclk), .*);
    
    reg [22:0] clkdiv = 0;
    reg ledval = 0;
    assign led = ledval;
    
    /* Just some simple stuff - an LED to check liveness, and a reset circuit */
    always_ff @(posedge clk) begin
        if (locked) begin
            /* LED circuit */
            if (clkdiv == 0) ledval = ~ledval;
            clkdiv = clkdiv + 1;
            
            /* Reset circuit */
            if (rstcnt == reset_time) begin
                resetn = 1;
            end else begin
                rstcnt = rstcnt + 1;
                resetn = 0;
            end
        end else rstcnt = 0;
    end

    wire [mcenoc_data_width-1:0]dat_in[num_cores-1:0];
    wire act_in[num_cores-1:0];
    wire clm_in[num_cores-1:0];
    wire err_in[num_cores-1:0];
    wire cts_in[num_cores-1:0];
    wire [mcenoc_data_width-1:0]dat_out[num_cores-1:0];
    wire cts_out[num_cores-1:0];
    wire err_out[num_cores-1:0];
    wire act_out[num_cores-1:0];
    wire clm_out[num_cores-1:0];

    generate
        if (num_cores > 1) begin
            uob_network #(
                .n_ports(num_cores),
                .data_width(mcenoc_data_width),
                .bits_per_switch(mcenoc_bits_per_switch)
            ) nw (
                .rst(reset),
                .*
            );
        end else begin
            assign dat_out[0] = dat_in[0];
            assign clm_out[0] = clm_in[0];
            assign act_out[0] = act_in[0];
            assign cts_out[0] = cts_in[0];
            assign err_out[0] = err_in[0];
        end
    endgenerate
    
    /*** APB ***/
    wire [31:0]         paddr;
    wire [num_cores-1:0] psel;
    wire                penable;
    wire                pready;
    wire [31:0]         prdata;
    wire                pslverr;
     
    genvar gi;
    generate for (gi = 0; gi < num_cores; gi = gi + 1) begin:coregen

        
        wire pcpi_valid, pcpi_wr, pcpi_wait, pcpi_ready;
        wire [31:0] pcpi_insn, pcpi_rs1, pcpi_rd, irq, eoi;
        assign irq[31:5] = 0;
        assign irq[2:0] = 0;
        
        if (gi == 0) begin
            /* Only core 0 gets a UART. Sorry everyone else! */
            pcpi_uart uart(.rx(uart_rx), .tx(uart_tx), .irq(irq[3]), .eoi(eoi[3]), .*);
        end

        pcpi_mcenoc_ni #(
            .NETWORK_NPORTS(num_cores),
            .NETWORK_BITS_PER_SWITCH(1),
            .NETWORK_DWIDTH(mcenoc_data_width)
        ) mcenoc_ni (
            .data_in(dat_out[gi]),
            .clm_in(clm_out[gi]),
            .act_in(act_out[gi]),
            .cts_out(cts_in[gi]),
            .err_out(err_in[gi]),
            .data_out(dat_in[gi]),
            .clm_out(clm_in[gi]),
            .act_out(act_in[gi]),
            .cts_in(cts_out[gi]),
            .err_in(err_out[gi]),
            .irq(irq[4]),
            .eoi(eoi[4]),
            .pclk(),
            .presetn(),
            .pwdata(),
            .pstrb(),
            .pprot(),
            .psel(psel[gi]),
            .pwrite(),
            .*
        );

        wire mem_ready = 1;
        wire mem_valid, mem_write;
        wire [3:0] mem_wstrb, mem_la_wstrb;
        wire [31:0] mem_addr, mem_rdata, mem_wdata;

        assign mem_wstrb = mem_la_wstrb & {4{mem_write}};

        picorv32_mem mem (
          .clk(clk),    // input wire clka
          .mem_wstrb(mem_wstrb),      // input wire [3 : 0] wea
          .mem_addr(mem_addr),  // input wire [31 : 0] addra
          .mem_wdata(mem_wdata),    // input wire [31 : 0] dina
          .mem_rdata(mem_rdata)  // output wire [31 : 0] douta
        );

        picorv32 #(
            .COMPRESSED_ISA(1),
            .TWO_CYCLE_COMPARE(0),
            .BARREL_SHIFTER(1),
            .ENABLE_PCPI(1),
            .ENABLE_MUL(1),
            .ENABLE_IRQ(1),
            .ENABLE_DIV(1),
`ifdef XILINX_SIMULATOR
            //.PROGADDR_RESET(32'h0000_05b8),
            .PROGADDR_RESET(32'h0000_0004),
`else
            .PROGADDR_RESET(32'h0000_0004),
`endif
            .PROGADDR_IRQ(32'h0000_0020),
            .MASKED_IRQ(32'h0000_0000)
            //.LATCHED_IRQ(32'h0000_0000)
        ) cpu(
            .clk(clk),
            .resetn(resetn),
            /* TODO: TRAP */
            .mem_ready(mem_ready),
            .mem_valid(mem_valid),
            .mem_rdata(mem_rdata),
            .mem_la_write(mem_write),
            .mem_la_addr(mem_addr),
            .mem_la_wstrb(mem_la_wstrb),
            .mem_la_wdata(mem_wdata),
            .pcpi_valid(pcpi_valid),
            .pcpi_insn(pcpi_insn),
            .pcpi_rs1(pcpi_rs1),
            .pcpi_wr(pcpi_wr),
            .pcpi_rd(pcpi_rd),
            .pcpi_wait(pcpi_wait),
            .pcpi_ready(pcpi_ready),
            .irq(irq),
            .eoi(eoi)
        );
    end
    endgenerate
endmodule
