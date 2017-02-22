#include "isr.h"
#include "irq-ops.h"
#include "uart.h"
#include "bootloader.h"

#define VERSION "0.2016.05"

extern void(*irq_vec_ptr)(void);

const char str[] = ("MCENoC UART bootloader, v" VERSION "\
, built " __DATE__ " @ " __TIME__ "\
\r\nboot (binary)>");

void reset_isr(void) {
    /*uart_tx_char('.', UART_BLOCK);
    while (1) {
        __asm__ __volatile__("nop"::);
    }*/
    //irq_setq(q0, 4);
    /*irq_mask(-1);
    uart_deinit();*/
    //unsigned q = irq_getq(q0);
    irq_mask(-1);
    irq_setq(q0, 4);
    irq_ret();
}

int main(void) {
    uart_init();
    isr_setup(1, reset_isr);
    isr_setup(3, uart_irq);
    isr_install();
    isr_mask(0);
    uart_tx_buf((char *)str, 0, UART_BLOCK);
    bootloader();
}
