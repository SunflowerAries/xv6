#include <inc/types.h>
#include <inc/mmu.h>
#include <inc/memlayout.h>
#include <inc/x86.h>
#include <inc/stdio.h>
#include <inc/traps.h>
#include <inc/assert.h>
#include <kern/trap.h>
#include <kern/syscall.h>
#include <kern/proc.h>
#include <kern/cpu.h>

// Interrupt descriptor table (shared by all CPUs).
struct gatedesc idt[256];
extern uint32_t vectors[]; // in vectors.S: array of 256 entry pointers
uint32_t ticks;
struct spinlock tickslock;

// Initialize the interrupt descriptor table.
void
trap_init(void)
{
	// Your code here.
	//
	// Hints:
	// 1. The macro SETGATE in inc/mmu.h should help you, as well as the
	// T_* defines in inc/traps.h;
	// 2. T_SYSCALL is different from the others.
	for (int i = 0; i < 256; i++)
		SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
	SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
	__spin_initlock(&tickslock, "time");
}

void
idt_init(void)
{
	lidt(idt, sizeof(idt));
}

void
trap(struct trapframe *tf)
{
	// You don't need to implement this function now, but you can write
	// some code for debugging.
	struct proc *p = thisproc();
	if (tf->trapno == T_SYSCALL) {
		p->tf = tf;
		// cprintf("in trap.\n");
		tf->eax = syscall(tf->eax, tf->edx, tf->ecx, tf->ebx, tf->edi, tf->esi);
		return;
	}
	switch (tf->trapno) {
	case T_IRQ0 + IRQ_TIMER:
		// cprintf("in timer.\n");
		spin_lock(&tickslock);
		ticks++;
		wakeup1(&ticks);
		spin_unlock(&tickslock);
		lapic_eoi();
		break;
	
	default:
		if (p == NULL || (tf->cs & 3) == 0) {
			cprintf("unexpected trap %d from cpu %d eip: %x (cr2=0x%x)\n",
              tf->trapno, cpunum(), tf->eip, rcr2());
      		panic("trap");
		}
		cprintf("pid %d : trap %d err %d on cpu %d "
            "eip 0x%x addr 0x%x--kill proc\n",
            p->pid, tf->trapno,
            tf->err, cpunum(), tf->eip, rcr2());
		break;
	}
	if (p && p->state == RUNNING && tf->trapno == T_IRQ0 + IRQ_TIMER) {
#ifdef UGLY_YIELD
		if (ticks - p->begin_tick < time_slice[p->priority])
			return;
#endif
		yield();
	}
}