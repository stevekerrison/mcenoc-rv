#include <isr.h>
#include <uart.h>
#include <syscall.h>
#include <irq-ops.h>
#include <stdio.h>

int main(void) {
    uart_init();
    isr_setup(1, (void *)mcenoc_rv_syscall);
    isr_setup(3, uart_irq);
    isr_install();
    isr_mask(0);
    puts("Echo test. Use <ctrl+c> to soft-reboot system.");
    while (1) {
        char c = getchar();
        if (c == 3)
            break;
        putchar(c);
        fflush(stdout);
    }
    return 0;
}
