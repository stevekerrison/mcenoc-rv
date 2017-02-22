`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.05.2016 16:34:19
// Design Name: 
// Module Name: pcpi_uart
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

`define PCPI_UART_CUSTOM0_F7_URC 16
`define PCPI_UART_CUSTOM0_F7_UWC 17
`define PCPI_UART_CUSTOM0_F7_URX 18
`define PCPI_UART_CUSTOM0_F7_UTX 19
`define PCPI_UART_CUSTOM0_F7_START 16
`define PCPI_UART_CUSTOM0_F7_END 19
`define PCPI_UART_CUSTOM0_OPCODE 7'b0001011

module pcpi_uart(
    input               clk,
    input               resetn,
    /*** PCPI ***/
    input               pcpi_valid,
    input       [31:0]  pcpi_insn,
    input       [31:0]  pcpi_rs1,
    output tri          pcpi_wr,
    output tri  [31:0]  pcpi_rd,
    output              pcpi_wait,
    output tri          pcpi_ready,
    /*** IRQ ***/
    output              irq,
    input               eoi,
    /*** UART ***/
    input               rx,
    output              tx
);

`ifdef XILINX_SIMULATOR
    parameter CLOCK_DIVIDE = 4;
`else
    parameter CLOCK_DIVIDE = 217; //424;//1;//217;//434;
`endif
    
    typedef enum { IRQ_IDLE, IRQ_RAISED, IRQ_HANDLE } irq_state_t;
    irq_state_t irq_state = IRQ_IDLE;

    wire rst = ~resetn;
    wire is_receiving, recv_error;
    wire [7:0] rx_byte, tx_byte;
    wire received, is_transmitting;
    bit transmit = 0, write = 0, ready = 0, wt = 0, rx_latched, rx_unlatch = 0;
    bit rx_irq_en = 0, tx_irq_en = 0, tx_wait = 1;
    byte rx_data = 0;
    logic [31:0] rdata = 0;
    bit irq_r = 0;
    wire [31:0] status = {28'b0, rx_irq_en, tx_irq_en, rx_latched, is_transmitting};
    
    wire instr_trigger = (
        pcpi_valid &&
        pcpi_insn[6:0] == `PCPI_UART_CUSTOM0_OPCODE &&
        pcpi_insn[31:25] >= `PCPI_UART_CUSTOM0_F7_START &&
        pcpi_insn[31:25] <= `PCPI_UART_CUSTOM0_F7_END
    ); 
    assign pcpi_wr      = (instr_trigger) ?  write : 1'bZ;
    assign pcpi_ready   = (instr_trigger) ?  ready : 1'bZ;
    assign pcpi_rd      = (instr_trigger) ?  rdata : 32'bZ;
    assign pcpi_wait    = (instr_trigger) ?  wt    : 1'bZ;
    assign tx_byte      = pcpi_rs1[7:0];
    assign irq = irq_r & !eoi;

    /* Registers for input metastability */
    reg rx_1, rx_2;  
    always_ff @(posedge clk) begin
        rx_1 <= rx;
        rx_2 <= rx_1;
    end
    
    /* Attach double-FF'd rx input to UART */
    uart #(.CLOCK_DIVIDE(CLOCK_DIVIDE)) uart (.rx(rx_2), .*);
    
    /* PCPI Instruction execution */
    always_ff @(posedge clk) begin
        write <= 0;
        ready <= 0;
        rdata <= 0;
        wt <= 0;
        transmit <= 0;
        rx_unlatch <= 0;
        rx_irq_en <= rx_irq_en;
        tx_irq_en <= tx_irq_en;
        tx_wait <= tx_wait;
        if (instr_trigger) begin
            wt <= 1;
            case (pcpi_insn[31:25])
                default: begin
                    /* Invalid instruction, stay silent! */
                end
                /* Read control/stats reg */
                `PCPI_UART_CUSTOM0_F7_URC: begin
                    rdata <= status;
                    write <= 1;
                    ready <= 1;
                    wt <= 0;
                end
                /* Write control/stats reg */
                `PCPI_UART_CUSTOM0_F7_UWC: begin
                    ready <= 1;
                    wt <= 0;
                    rx_irq_en <= pcpi_rs1[3];
                    tx_irq_en <= pcpi_rs1[2];
                end
                `PCPI_UART_CUSTOM0_F7_URX: begin
                    /* Wait for a byte */
                    if (!received && rx_latched) begin
                        rdata <= {24'b0, rx_byte};
                        write <= 1;
                        ready <= 1;
                        wt <= 0;
                        rx_unlatch <= 1;
                    end
                end
                `PCPI_UART_CUSTOM0_F7_UTX: begin
                    if (!is_transmitting) begin
                        ready <= 1;
                        wt <= 0;
                        transmit <= 1;
                    end
                end
            endcase
        end
    end
    
    /* IRQ SM */
    always_ff @(posedge clk) begin
        irq_r <= irq_r;
        case (irq_state)
            IRQ_IDLE: begin
                if ((received && rx_irq_en) || (!is_transmitting && tx_irq_en)) begin
                    irq_r <= 1;
                    irq_state <= IRQ_RAISED;
                end
            end
            IRQ_RAISED: begin
                if (eoi) begin
                    irq_r <= 0;
                    irq_state <= IRQ_HANDLE;
                end
            end
            IRQ_HANDLE: begin
                if (!eoi) begin
                    irq_state <= IRQ_IDLE;
                end
            end
        endcase
    end

    /* Receive buffer */
    always_ff @(posedge clk) begin
        rx_latched <= rx_latched;
        if (received) begin
            rx_data <= rx_byte;
            rx_latched <= 1;
        end else if (rx_unlatch) begin
            rx_latched <= 0;
        end
    end

endmodule
