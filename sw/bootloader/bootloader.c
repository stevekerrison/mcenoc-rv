#include "uart.h"
#include "irq-ops.h"

extern void (*bootloaded_start)(void);
extern unsigned int max_prog_size;

inline char nibble2hex(char nib) {
    if (nib <= 9) return nib + 48;
    else return nib + 55;
}

void print_mem(unsigned char * ptr, size_t len) {
    char hex[2];
    for (size_t i = 0; i < len; i += 1) {
        hex[0] = nibble2hex(ptr[i] >> 4);
        hex[1] = nibble2hex(ptr[i] & 0xf);
        uart_tx_buf(hex, 2, UART_BLOCK);
    }
}

/* Using the hacker's delight crc32b, modified */
unsigned int load_prog(size_t len) {
    int i, j;
    unsigned int crc, mask;
    unsigned char byte;
    unsigned char * p = (unsigned char *)&bootloaded_start;
    crc = 0xFFFFFFFF;
    for (i = 0; i < len; i += 1) {
        uart_rx_char((char *)&byte, UART_BLOCK);
        *p = byte;
        p += 1;
        crc = crc ^ byte;
        for (j = 7; j >= 0; j--) {    // Do eight times.
            mask = -(crc & 1);
            crc = (crc >> 1) ^ (0xEDB88320 & mask);
        }
    }
    return ~crc;
}

void bootloader(void) {
    unsigned int pcrc, tcrc, proglen, magic;
    char c;
    while (1) {
        magic = 0;
        /* Ignore all input until we get the magic word hex("mcen") */
        while (magic != 0x6d63656e) {
            uart_rx_char(&c, UART_BLOCK);
            magic <<= 8;
            magic |= c;
        }
        uart_tx_buf("go\r\n", 0, UART_BLOCK);
        uart_rx_buf((char *)&proglen, 4, UART_BLOCK);
        if (proglen >= (unsigned int)&max_prog_size) {
            uart_tx_buf("Image too large, retry>\r\n", 0, UART_BLOCK);
            continue;
        }
        pcrc = load_prog(proglen);
        uart_rx_buf((char *)&tcrc, 4, UART_BLOCK);
        if (pcrc != tcrc) {
            uart_tx_buf("CRC FAIL, retry>\r\n", 0, UART_BLOCK);
            uart_tx_drain();
        } else {
            /* Hand-over control to the loaded program */
            uart_tx_buf("SUCCESS!\r\n", 0, UART_BLOCK);
            uart_tx_drain();
            //__asm__ __volatile__("ecall");
            irq_mask(-1); //Disable all interrupts
            __asm__ __volatile__("lui sp,%%hi(stack_top)\n"
                                "add sp,sp,%%lo(stack_top)\n"
                                "j bootloaded_start"::);
        }
    }
}
