#include <inc/types.h>
#include <inc/memlayout.h>
#include <inc/traps.h>
#include <inc/mmu.h>
#include <inc/elf.h>
#include <inc/string.h>
#include <inc/assert.h>
#include <inc/x86.h>

#include <kern/kalloc.h>
#include <kern/proc.h>
#include <kern/vm.h>
#include <kern/trap.h>
#include <kern/cpu.h>

struct ptable ptable;

uint32_t nextpid = 1;
extern pde_t *kpgdir;
extern void forkret(void);
extern void trapret(void);
extern char *_binary_obj_user_hello_start, *_binary_obj_user_hello_end, *_binary_obj_user_hello_size;
void swtch(struct context **, struct context*);


//
// Initialize something about process, such as ptable.lock
//
void
proc_init(void)
{
	// TODO: your code here
	__spin_initlock(&ptable.lock, "ptable");
}

// Look in the process table for an UNUSED proc.
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0
static struct proc*
proc_alloc(void)
{
	// TODO: your code here
	//
	// Following things you need to do:
	// - set state and pid.
	// - allocate kernel stack.
	// - leave room for trap frame in kernel stack.
	// - Set up new context to start executing at forkret, which returns to trapret.
	struct proc* p;
	spin_lock(&ptable.lock);
	for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
		if (p->state == UNUSED) {
			p->state = EMBRYO;
			p->pid = nextpid++;
			spin_unlock(&ptable.lock);
			if ((p->kstack = kalloc()) == NULL) {
				p->state = UNUSED;
				return NULL;
			}
			char* begin = p->kstack + KSTACKSIZE; // Does the setup of trapframe happen before these?
			begin -= sizeof(p->tf);
			p->tf = (struct trapframe *)begin;
			begin -= 4;
			*(uint32_t *)begin = (uint32_t)trapret;
			begin -= sizeof(p->context);
			p->context = (struct context *)begin;
			memset(p->context, 0, sizeof(p->context));
			p->context->eip = (uint32_t)forkret;
			return p;
		}
	spin_unlock(&ptable.lock);
	return NULL;
}

//
// Set up the initial program binary, stack, and processor flags
// for a user process.
// This function is ONLY called during kernel initialization,
// before running the first user-mode process.
//
// This function loads all loadable segments from the ELF binary image
// into the environment's user memory, starting at the appropriate
// virtual addresses indicated in the ELF program header.
// At the same time it clears to zero any portions of these segments
// that are marked in the program header as being mapped
// but not actually present in the ELF file - i.e., the program's bss section.
//
// All this is very similar to what our boot loader does, except the boot
// loader also needs to read the code from disk.  Take a look at
// boot/bootmain.c to get ideas.
//
// Finally, this function maps one page for the program's initial stack.
//
// load_icode panics if it encounters problems.
//  - How might load_icode fail?  What might be wrong with the given input?
//
static void
ucode_load(struct proc *p, uint8_t *binary) {
	// Hints:
	//  Load each program segment into virtual memory
	//  at the address specified in the ELF segment header.
	//  You should only load segments with ph->p_type == ELF_PROG_LOAD.
	//  Each segment's virtual address can be found in ph->p_va
	//  and its size in memory can be found in ph->p_memsz.
	//  The ph->p_filesz bytes from the ELF binary, starting at
	//  'binary + ph->p_offset', should be copied to virtual address
	//  ph->p_va.  Any remaining memory bytes should be cleared to zero.
	//  (The ELF header should have ph->p_filesz <= ph->p_memsz.)
	//  Use functions from the previous lab to allocate and map pages.
	//
	//  All page protection bits should be user read/write for now.
	//  ELF segments are not necessarily page-aligned, but you can
	//  assume for this function that no two segments will touch
	//  the same virtual page.
	//
	//  You may find a function like region_alloc useful.
	//
	//  Loading the segments is much simpler if you can move data
	//  directly into the virtual addresses stored in the ELF binary.
	//  So which page directory should be in force during
	//  this function?
	//
	//  You must also do something with the program's entry point,
	//  to make sure that the environment starts executing there.
	//  What? 

	// TODO: Your code here.
	region_alloc(p, 0, (int)_binary_obj_user_hello_size);
	struct Proghdr *ph, *eph;
	struct Elf *elf = (struct Elf *)binary;
	ph = (struct Proghdr *) (binary + elf->e_phoff);
	eph = ph + elf->e_phnum;
	void *begin = 0;
	for (; ph < eph; ph++)
		if (ph->p_type == ELF_PROG_LOAD) {
			memmove(begin, (void *)ph->p_va, ph->p_filesz);
			begin += PGSIZE;
		}
	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.
	// TODO: Your code here.
	char *stack = kalloc();
	if (map_region(p->pgdir, (void *)(USTACKTOP - PGSIZE), PGSIZE, V2P(stack), PTE_U | PTE_W) < 0)
		panic("USER STACK.");
}

//
// Allocates a new proc with proc_alloc, loads the user_hello elf
// binary into it with UCODE_LOAD.
// This function is ONLY called during kernel initialization,
// before running the first user-mode process.
// The new proc's parent ID is set to 0.
//
void
user_init(void)
{
	// TODO: your code here.
	struct proc *child;
	if ((child = proc_alloc()) == NULL)
		panic("Allocate User Process.");
	if ((child->pgdir = kvm_init()) == NULL)
		panic("User Pagedir.");
	// TODO: can't understand the reason for parent id.
	//child->parent->pid = 0; 
	ucode_load(child, (uint8_t *)_binary_obj_user_hello_start);
	memset(child->tf, 0, sizeof(child->tf));
	child->tf->cs = (SEG_UCODE << 3) | DPL_USER;
	child->tf->ds = (SEG_UDATA << 3) | DPL_USER;
	child->tf->es = (SEG_UDATA << 3) | DPL_USER;
	child->tf->ss = (SEG_UDATA << 3) | DPL_USER;
	child->tf->eflags = FL_IF;
	child->tf->esp = PGSIZE;
	child->tf->eip = 0;
	spin_lock(&ptable.lock);
	child->state = RUNNABLE;
	spin_unlock(&ptable.lock);
}

//
// Context switch from scheduler to first proc.
//
// This function does not return.
//
void
ucode_run(void)
{
	// TODO: your code here
	//
	// Hints:
	// - you may need sti() and cli()
	// - you may need uvm_switch(), swtch() and kvm_switch()
	// TODO: where is the scheduler, thisproc may be wrong
	struct proc *p;
	thiscpu->proc = NULL;
	while (1) {
		sti();
		spin_lock(&ptable.lock);
		for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
			if (p->state == RUNNABLE) {
				uvm_switch(p);
				p->state = RUNNING;
				thiscpu->proc = p;
				swtch(&thiscpu->scheduler, p->context);
				kvm_switch();
				thiscpu->proc = NULL;
			}
		spin_unlock(&ptable.lock);
	}
}

struct proc*
thisproc(void) {
	struct proc *p;
	pushcli();
	p = thiscpu->proc;
	popcli();
	return p;
}

//
// Context switch from thisproc to scheduler.
//
void
sched(void)
{
	// TODO: your code here.
	struct proc *p = thisproc();
	swtch(&p->context, thiscpu->scheduler);
}


void
forkret(void)
{
	// Return to "caller", actually trapret (see proc_alloc)
	// That means the first proc starts here.
	// When it returns from forkret, it need to return to trapret.
	// TODO: your code here.
	spin_unlock(&ptable.lock);

}

void
exit(void)
{
	// sys_exit() call to here.
	// TODO: your code here.
	struct proc *p = thisproc();
	vm_free(p->pgdir);
	vm_free(p->kstack);
	spinlock(&ptable.lock);
	p->state = ZOMBIE;
	sched();
}