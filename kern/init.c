#include <inc/stdio.h>
#include <inc/string.h>
#include <inc/assert.h>
#include <kern/console.h>

#include <kern/console.h>
#include <kern/kalloc.h>
#include <kern/vm.h>
#include <kern/trap.h>
#include <kern/cpu.h>
#include <kern/picirq.h>
#include <kern/ide.h>
#include <kern/ioapic.h>
#include <kern/bio.h>
#include <kern/spinlock.h>
#include <kern/file.h>

static void boot_aps(void);

void
i386_init()
{
    extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
    memset(edata, 0, end - edata);

	cons_init();

	cprintf("Hello, world.\n");
	boot_alloc_init();
	vm_init();
	seg_init();
	trap_init();
	proc_init();
	mp_init();
	lapic_init();
	pic_init();
	ioapic_init();
	fileinit();
	ide_init();
	binit();
	
	boot_aps();

	alloc_init();
	idt_init();
	cprintf("VM: Init success.\n");
	check_free_list();
	user_init();
	xchg(&thiscpu->cpu_status, CPU_STARTED);
	ucode_run();
	// Spin.
    while (1);
}

// While boot_aps is booting a given CPU, it communicates the per-core
// stack pointer that should be loaded by mpentry.S to that CPU in
// this variable.
void *mpentry_kstack;

static void
boot_aps(void)
{
	extern unsigned char mpentry_start[], mpentry_end[];
	void *code;
	struct CpuInfo *c;

	// Write entry code to unused memory at MPENTRY_PADDR
	code = P2V(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
		if (c == thiscpu)  // We've started already.
			continue;

		// Tell mpentry.S what stack to use 
		mpentry_kstack = percpu_kstacks[c - cpus] + KSTKSIZE;
		// Start the CPU at mpentry_start
		lapic_startap(c->cpu_id, V2P(code));
		// Wait for the CPU to finish some basic setup in mp_main()
		while(c->cpu_status != CPU_STARTED)
			;
	}
}

// Setup code for APs
void
mp_main(void)
{
	// TODO: Your code here.
	// You need to initialize something.
	kvm_switch();
	seg_init();
	lapic_init();
	cprintf("Starting CPU%d.\n", cpunum());
	idt_init();
	xchg(&thiscpu->cpu_status, CPU_STARTED); // tell boot_aps() we're up
	ucode_run();
}

/*
 * Variable panicstr contains argument to first call to panic; used as flag
 * to indicate that the kernel has already called panic.
 */
const char *panicstr;

/*
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
	va_list ap;
	if (panicstr)
		goto dead;
	panicstr = fmt;

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");

	va_start(ap, fmt);
	cprintf("kernel panic at %s:%d: ", file, line);
	vcprintf(fmt, ap);
	cprintf("\n");
	va_end(ap);
	while(1);
dead:
    while(1);
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
	va_list ap;

	va_start(ap, fmt);
	cprintf("kernel warning at %s:%d: ", file, line);
	vcprintf(fmt, ap);
	cprintf("\n");
	va_end(ap);
}
