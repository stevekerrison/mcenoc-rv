#include "irq-ops.S"

.globl main
.globl stack_top
.globl irq_vec_ptr
.globl irq_stack_top

.section .nullptr
_nullptr:
    sbreak /* Null ptr */

.section .start
_start:
    /* Initialize irq_vec_ptr */
    lui ra,%hi(irq_vec_ptr)
    sw zero,%lo(irq_vec_ptr)(ra)
    /* Sets up the stack then dive into main */
    lui sp,%hi(stack_top)
    add sp,sp,%lo(stack_top)
    j _init_bss

.section .irq
_irq:
    /* Save normal stack pointer and return address */
    setq q2,sp
    setq q3,ra
    /* Get IRQ stack */
    lui sp,%hi(irq_stack_top)
    add sp,sp,%lo(irq_stack_top)
    /* Make space for saved registers */
    add sp,sp,-64
    /* SAVE ALL THE THINGS */
    sw t0,0(sp)
    sw t1,4(sp)
    sw t2,8(sp)
    sw a0,12(sp)
    sw a1,16(sp)
    sw a2,20(sp)
    sw a3,24(sp)
    sw a4,28(sp)
    sw a5,32(sp)
    sw a6,36(sp)
    sw a7,40(sp)
    sw t3,44(sp)
    sw t4,48(sp)
    sw t5,52(sp)
    sw t6,56(sp)
    /* Load current IRQ handler */
    lui ra,%hi(irq_vec_ptr)
    add ra,ra,%lo(irq_vec_ptr)
    lw ra,0(ra)
    /* Handle IRQ(s) */
    jalr ra,ra
    /* RESTORE ALL THE THINGS */
    lw t0,0(sp)
    lw t1,4(sp)
    lw t2,8(sp)
    lw a0,12(sp)
    lw a1,16(sp)
    lw a2,20(sp)
    lw a3,24(sp)
    lw a4,28(sp)
    lw a5,32(sp)
    lw a6,36(sp)
    lw a7,40(sp)
    lw t3,44(sp)
    lw t4,48(sp)
    lw t5,52(sp)
    lw t6,56(sp)
    /* Resume normal service */
    getq sp,q2
    getq ra,q3
    retirq

.section .text

_init_bss:
    lui a0,%hi(bss_start)
    mv a1,a0
    add a0,a0,%lo(bss_start)
    add a1,a0,%lo(bss_end)
_init_bss_loop:
    sw zero,0(a0)
    sub a2,a1,a0
    add a0,a0,4
    bnez a2,_init_bss_loop
    jal ra,main
_exit:
    /* Mask all interrupts */
    li a0,-1
    maskirq zero,a0
    /* Reset to boot address */
    jal zero,4

/* EOF */
