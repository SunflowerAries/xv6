#ifndef KERN_PROC_H
#define KERN_PROC_H

enum procstate { UNUSED, EMBRYO, SLEEPING, RUNNABLE, RUNNING, ZOMBIE };

#define MAXPRIO 4
#define STATECOUNT 6
#define NPROC 64
#define KSTACKSIZE 4096
#define TICKS_TO_PROMOTE 1000
#define DEBUG_MLFQ
//#define UGLY_YIELD

#include <inc/types.h>
#include <inc/memlayout.h>
#include <kern/spinlock.h>

struct context {
	uint32_t edi;
	uint32_t esi;
	uint32_t ebx;
	uint32_t ebp;
	uint32_t eip;
};

struct proc {
	pde_t *pgdir;				// Page table
	char *kstack;				// Bottom of kernel stack of this process
	enum procstate state;		// Process state
	uint32_t pid;				// Process ID
	struct proc *parent;		// Parent process
	struct trapframe *tf;		// Trapframe for current syscall
	struct context *context;	// swtch() here to return process
#ifdef DEBUG_MLFQ
	struct proc *next;			// Next process in the corresponding list
	uint32_t priority;			// Process prority
	uint32_t budget;			// Own time-slice
	uint32_t begin_tick;		// Time to hold CPU
	void *chan;					// Sleeping on chan
#endif
};

#ifdef DEBUG_MLFQ
struct ptrs {
	struct proc *head;
	struct proc *tail;
};
#endif

struct ptable {
	struct spinlock lock;
	struct proc proc[NPROC];
#ifdef DEBUG_MLFQ
	struct ptrs list[STATECOUNT];
	struct ptrs ready[MAXPRIO + 1];
	uint32_t PromoteAtTime;
#endif
};

void proc_init(void);
void user_init(void);
void user_run(struct proc *p);
void ucode_run(void);
struct proc* thisproc(void);
void proc_init(void);
extern uint32_t time_slice[];
extern uint32_t ticks;

void exit(void);
void yield(void);
int fork(void);
void sleep(void *chan, struct spinlock *lk);
void wakeup1(void *chan);
int wait(void);
int kill(uint32_t pid);

// Without this extra macro, we couldn't pass macros like TEST to
// UCODE_LOAD because of the C pre-processor's argument prescan rule.
#define UCODE_PASTE3(x, y, z) x ## y ## z

#define NELEM(x) (sizeof(x)/sizeof((x)[0]))

#define UCODE_LOAD(p, x)						\
	do {								\
		extern uint8_t UCODE_PASTE3(_binary_obj_, x, _start)[];	\
		ucode_load(p, (uint8_t *)UCODE_PASTE3(_binary_obj_, x, _start));		\
	} while (0)

#endif /* !KERN_PROC_H */
