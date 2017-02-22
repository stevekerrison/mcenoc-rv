MEMORY {
    rom : ORIGIN = 0x00000000, LENGTH = 2K
    /* ram : ORIGIN = 0x00001000, LENGTH = 16K */
    ram : ORIGIN = 0x00008000, LENGTH = 32K
}

reset_addr = 0x4;
irq_vec_ptr = ORIGIN(ram);
bootloaded_start = irq_vec_ptr + 4;
stack_size = 2K;
irq_stack_size = 1K;
ram_end = ORIGIN(ram) + LENGTH(ram) - 4;
stack_bot = stack_top - stack_size;
stack_top = ram_end - irq_stack_size;
irq_stack_top = ram_end;
irq_a0 = irq_stack_top - 44;
bootloader_data_limit = 128;
bootloader_data_loc = stack_bot - bootloader_data_limit;
/* Assume we expect at most 8K of stack (of which 2K is already accounted for in
 the bootloader stack, so + 6K). */
max_prog_size = (stack_bot - 6K) - ORIGIN(ram);


SECTIONS {
    ROM : {
        *(.nullptr)
        . = 0x4;
        *(.start)
    } > rom
    ROM : {
        . = 0x20;
        *(.irq)
        *(.text)
        *(.text*)
        *(.rodata)
        *(.rodata*)
        *(.comment)
    } > rom
    .data : {
        *(.data)
        *(.rwdata)
        *(.rwdata*)
    } > ram
    .bss : {
        . = ABSOLUTE(bootloader_data_loc);
        bss_start = .;
        *(.bss)
        *(.sbss)
        *(.bss*)
        *(COMMON)
        . = ALIGN(4);
        bss_end = .;
        ASSERT(. < stack_bot, "Error: Bootloader bss invades stack"); 
    } > ram
}
