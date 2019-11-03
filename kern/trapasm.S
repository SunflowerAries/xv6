#include <inc/mmu.h>

	# vectors.S sends all traps here.
.globl alltraps
alltraps:
	# Your code here:
	#
	# Hint: you should build trap frame, set up data segments and then
	# call trap(tf)
	pushl %ds
	pushl %es
	pushl %fs
	pushl %gs
	pushal 

	movw $(SEG_KDATA<<3), %ax
	movw %ax, %ds
	movw %ax, %es

	pushl %esp
	call trap
	addl $4, %esp

	# Return falls through to trapret...
.globl trapret
trapret:
	# Restore registers.
	# Your code here:
	popal
	popl %gs
	popl %fs
	popl %es
	popl %ds
	addl $0x8, %esp
	iret
