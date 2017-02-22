#include "isr.h"

extern void(*irq_vec_ptr)(void);
//extern void(*_exit)(void);

static void (*irq_table[IRQ_TABLE_SIZE])(void);

int isr_setup(unsigned int irq_num, void (*fn)(void)) {
    if (irq_num >= IRQ_TABLE_SIZE) {
        return 0;
    }
    irq_table[irq_num] = fn;
    return 1;
}

unsigned int isr_mask(unsigned int mask) {
    unsigned imask = 0;
    for (int i = 0; i < IRQ_TABLE_SIZE; i += 1) {
        if (irq_table[i] == (void *)-1) {
            imask |= (1 << i);
        }
    }
    imask |= mask;
    irq_mask(imask);
    return imask;
}

void isr(void) {
    unsigned int trig = irq_getq(q1);
    for (int i = 0; i < IRQ_TABLE_SIZE; i += 1) {
        if ((trig >> i) & 1) {
            if (irq_table[i] == (void *) -1) {
                //_exit();
                continue;
            }
            irq_table[i]();
        }
    }
    return;
}

void isr_install(void) {
    irq_vec_ptr = isr;
}
