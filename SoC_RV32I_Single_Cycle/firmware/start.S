#.equ MEM_SIZE, 0x1000   # 4KB

.section .text.start
.globl start

start:
    # setup stack pointer (top of RAM)
    #li sp, MEM_SIZE
    la sp, _stack_top

    # call main
    call main

    # main không được return; nếu có thì đứng yên tại đây
1:  j 1b

