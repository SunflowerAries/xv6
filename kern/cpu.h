#ifndef KERN_CPU_H
#define KERN_CPU_H

#include <inc/types.h>
#include <inc/memlayout.h>
#include <inc/mmu.h>
#include <kern/spinlock.h>

// Maximum number of CPUs
#define NCPU  8

// Values of status in struct Cpu
enum {
	CPU_UNUSED = 0,
	CPU_STARTED,
	CPU_HALTED,
};

// Per-CPU state
struct CpuInfo {
	uint8_t cpu_id;                 // Local APIC ID; index into cpus[] below
	volatile unsigned cpu_status;   // The status of the CPU
	struct context *scheduler;		// swtch() here to enter scheduler
	struct taskstate cpu_ts;        // Used by x86 to find stack for interrupt
	struct segdesc gdt[NSEGS];		// x86 global descriptor table
	struct proc *proc;				// The process running on this cpu or null
	int32_t ncli;					// Depth of pushcli nesting
	int32_t intena;					// Were interrupts enabled before pushcli?
	struct mcslock_node node;		// Mcslock node
};

// Initialized in mpconfig.c
extern struct CpuInfo cpus[NCPU];
extern int ncpu;                    // Total number of CPUs in the system
extern struct CpuInfo *bootcpu;     // The boot-strap processor (BSP)
extern physaddr_t lapicaddr;        // Physical MMIO address of the local APIC

// Per-CPU kernel stacks
extern unsigned char percpu_kstacks[NCPU][KSTKSIZE];

int cpunum(void);
#define thiscpu (&cpus[cpunum()])

void mp_init(void);
void lapic_init(void);
void lapic_startap(uint8_t apicid, uint32_t addr);
void lapic_eoi(void);
void lapic_ipi(int vector);

#endif
