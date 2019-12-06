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
void swtch(struct context **, struct context*);
uint32_t time_slice[MAXPRIO + 1] = {16, 8, 4, 2, 1};

//
// Initialize something about process, such as ptable.lock
//
void
proc_init(void)
{
	// TODO: your code here
	__spin_initlock(&ptable.lock, "ptable");
}

#ifdef DEBUG_MLFQ
static void
proc_list_init(void)
{
	int i = 0;
	for (i = UNUSED; i <= ZOMBIE; i++) {
		ptable.list[i].head = NULL;
		ptable.list[i].tail = NULL;
	}
	for (i = 0; i <= MAXPRIO; i++) {
		ptable.ready[i].head = NULL;
		ptable.ready[i].tail = NULL;
	}
}

static void
stateListAdd(struct ptrs* list, struct proc *p, const char *place)
{
	if (list->head == NULL) {
		list->head = p;
		list->tail = p;
	} else {
		list->tail->next = p;
		list->tail = p;
	}
	p->next = NULL;
	// cprintf("Add pid %d to %d at %s\n", p->pid, p->state, place);
}

static int
stateListRemove(struct ptrs* list, struct proc *p, const char *place)
{
	// cprintf("Remove pid %d from %d at %s\n", p->pid, p->state, place);
	if (list->head == NULL || p == NULL)
		return -1;
	struct proc *ptr = list->head;
	struct proc *next;
	if (ptr == p) {
		if (ptr == list->tail)
			list->tail = list->tail->next;
		list->head = ptr->next;
		return 0;
	} 

	next = ptr->next;
	for (; ptr != list->tail; ptr = next, next = next->next)
		if (next == p) {
			ptr->next = next->next;
			next->next = NULL;
			return 0;
		}
	return -1;
}

static void
free_list_init(void)
{
	struct proc *p;
	for (p = ptable.proc; p < &ptable.proc[NPROC]; p++) {
		p->state = UNUSED;
		stateListAdd(&ptable.list[UNUSED], p, "Free_list");
	}
}

static void
assertState(struct proc *p, enum procstate state, const char *place)
{
	// cprintf("pid:%d, pid-state:%d, state:%d at %s\n", p->pid, p->state, state, place); 
	if (p->state != state)
		panic("process state not same as asserted state.");
}
#endif

// Look in the process table for an UNUSED proc.
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0
#ifdef DEBUG_MLFQ
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
	char* begin;
	
	p = ptable.list[UNUSED].head;
	if (p == NULL)
		return NULL;
	spin_lock(&ptable.lock);
	p->pid = nextpid++;
	if (stateListRemove(&ptable.list[UNUSED], p, "Proc") < 0)
		panic("In UNUSED: Empty or process not in list");
	assertState(p, UNUSED, "Proc");
	p->state = EMBRYO;
	stateListAdd(&ptable.list[EMBRYO], p, "Proc");
	spin_unlock(&ptable.lock);

	if ((p->kstack = kalloc()) == NULL) {
		spin_lock(&ptable.lock);
		if (stateListRemove(&ptable.list[EMBRYO], p, "Proc fail") < 0)
			panic("In EMBRYO: Empty or process not in list");
		assertState(p, EMBRYO, "Proc fail");
		p->state = UNUSED;
		stateListAdd(&ptable.list[UNUSED], p, "Proc fail");
		spin_unlock(&ptable.lock);
		return NULL;
	}
	begin = p->kstack + KSTACKSIZE; // Does the setup of trapframe happen before these?
	begin -= sizeof(*p->tf);
	p->tf = (struct trapframe *)begin;
	begin -= 4;
	*(uint32_t *)begin = (uint32_t)trapret;
	begin -= sizeof(*p->context);
	p->context = (struct context *)begin;
	memset(p->context, 0, sizeof(*p->context));
	p->context->eip = (uint32_t)forkret;
	p->priority = MAXPRIO;
	p->budget = time_slice[p->priority];
	return p;
}
#else
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
	char* begin;
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
			begin = p->kstack + KSTACKSIZE; // Does the setup of trapframe happen before these?
			begin -= sizeof(*p->tf);
			p->tf = (struct trapframe *)begin;
			begin -= 4;
			*(uint32_t *)begin = (uint32_t)trapret;
			begin -= sizeof(*p->context);
			p->context = (struct context *)begin;
			memset(p->context, 0, sizeof(*p->context));
			p->context->eip = (uint32_t)forkret;
			return p;
		}
	spin_unlock(&ptable.lock);
	return NULL;
}
#endif

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
	struct Proghdr *ph, *eph;
	struct Elf *elf = (struct Elf *)binary;
	ph = (struct Proghdr *) (binary + elf->e_phoff);
	eph = ph + elf->e_phnum;
	for (; ph < eph; ph++) {
			void *begin = (void *)ph->p_va;
			if (ph->p_type == ELF_PROG_LOAD) {
				region_alloc(p, begin, ph->p_memsz);
				if (loaduvm(p->pgdir, begin, ph, (char *)binary) < 0)
					panic("Load segment.");
			}
		}
	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.
	// TODO: Your code here.
	region_alloc(p, (void *)(USTACKTOP - PGSIZE), PGSIZE * 2);
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
#ifdef DEBUG_MLFQ
	spin_lock(&ptable.lock);
	proc_list_init();
	free_list_init();
	spin_unlock(&ptable.lock);
#endif

	if ((child = proc_alloc()) == NULL)
		panic("Allocate User Process.");
	if ((child->pgdir = kvm_init()) == NULL)
		panic("User Pagedir.");
	// TODO: can't understand the reason for parent id.
	UCODE_LOAD(child, user_hello);	
	memset(child->tf, 0, sizeof(*child->tf));
	extern uint8_t _binary_obj_user_hello_start[];
	child->tf->cs = (SEG_UCODE << 3) | DPL_USER;
	child->tf->ds = (SEG_UDATA << 3) | DPL_USER;
	child->tf->es = (SEG_UDATA << 3) | DPL_USER;
	child->tf->ss = (SEG_UDATA << 3) | DPL_USER;
	child->tf->eflags = FL_IF;
	struct Elf *elf = (struct Elf *)_binary_obj_user_hello_start;
	char *begin = (char *)elf->e_entry;
	child->tf->eip = (uintptr_t)begin;
	child->tf->esp = USTACKTOP;

#ifdef DEBUG_MLFQ
	spin_lock(&ptable.lock);
	if (stateListRemove(&ptable.list[EMBRYO], child, "Userinit") < 0)
		panic("In EMBRYO: Empty or process not in list");
	assertState(child, EMBRYO, "Userinit");
#endif
	child->state = RUNNABLE;
#ifdef DEBUG_MLFQ
	stateListAdd(&ptable.ready[child->priority], child, "Userinit");
	ptable.PromoteAtTime = ticks + TICKS_TO_PROMOTE;
	spin_unlock(&ptable.lock);
#endif
	// stateListAdd(&ptable.list[child->state], child);
	
	
}

//
// Context switch from scheduler to first proc.
//
// This function does not return.
//
#ifdef DEBUG_MLFQ
void
ucode_run(void)
{
	// TODO: your code here
	//
	// Hints:
	// - you may need sti() and cli()
	// - you may need uvm_switch(), swtch() and kvm_switch()
	// TODO: where is the scheduler, thisproc may be wrong
	struct proc *p, *tmp;
	thiscpu->proc = NULL;
	int priority;
	// cprintf("After null.\n");
	for (;;) {
		sti();
		spin_lock(&ptable.lock);
		// cprintf("in while.\n");
		if (ticks >= ptable.PromoteAtTime) {
			for (int j = MAXPRIO - 1; j >= 0; j--) {
				p = ptable.ready[j].head;
				while(p) {
					tmp = p->next;
					if (stateListRemove(&ptable.ready[j], p, "Ucode_run") < 0)
						panic("In Priority Queue: Empty or process is not in list");
					assertState(p, RUNNABLE, "Ucode_run");
					if (p->priority != j)
						panic("Priority");
					stateListAdd(&ptable.ready[j + 1], p, "Ucode_run");
					p->budget = time_slice[++p->priority];
					p = tmp;
				}
			}
			ptable.PromoteAtTime = ticks + TICKS_TO_PROMOTE;
		}
		for (priority = MAXPRIO; priority >= 0; priority--) {
			p = ptable.ready[priority].head;
			// cprintf("At priority %d\n", priority);
			if (p) {
				uvm_switch(p);
				if (stateListRemove(&ptable.ready[priority], p, "Ucode_run") < 0)
					panic("In Priority Queue: Empty or process is not in list");
				if (p->priority != priority) 
					panic("Priority");
				// cprintf("In ucode_run.\n");
				assertState(p, RUNNABLE, "Ucode_run");
				p->state = RUNNING;
				stateListAdd(&ptable.list[p->state], p, "Ucode_run");
				thiscpu->proc = p;
				p->begin_tick = ticks;
				swtch(&thiscpu->scheduler, p->context);
				kvm_switch();
				thiscpu->proc = NULL;
				break;
			}
		}
		spin_unlock(&ptable.lock);
	}
}
#else
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
	// cprintf("After null.\n");
	for (;;) {
		sti();
		spin_lock(&ptable.lock);
		// cprintf("in while.\n");
		for (p = ptable.proc; p < &ptable.proc[NPROC]; p++) {
			// cprintf("proc: %x\n", p);
			if (p->state == RUNNABLE) {
				// cprintf("in scheduler.\n");
				uvm_switch(p);
				p->state = RUNNING;
				thiscpu->proc = p;
				swtch(&thiscpu->scheduler, p->context);
				kvm_switch();
				thiscpu->proc = NULL;
			}
		}
		spin_unlock(&ptable.lock);
	}
}
#endif

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
wakeup1(void *chan)
{
	struct proc *p = ptable.list[SLEEPING].head;
	struct proc *tmp;
	while(p) {
		tmp = p->next;
		if (p->chan == chan) {
			if (stateListRemove(&ptable.list[SLEEPING], p, "Wakeup") < 0)
				panic("In SLEEPING: Empty or process not in list");
			assertState(p, SLEEPING, "Wakeup");
			cprintf("wakeup pid %d\n", p->pid);
			p->state = RUNNABLE;
			stateListAdd(&ptable.ready[p->priority], p, "Wakeup");
		}	
		p = tmp;
	}
}

#ifdef DEBUG_MLFQ
int
fork(void)
{
	struct proc *p = thisproc();
	struct proc *child;
	if ((child = proc_alloc()) == NULL)
		return -1;
	if ((child->pgdir = copyuvm(p->pgdir)) == NULL) {
		kfree(child->kstack);
		child->kstack = NULL;
		spin_lock(&ptable.lock);
		if (stateListRemove(&ptable.list[EMBRYO], child, "fork fail") < 0)
			panic("In EMBRYO: Empty or process not in list");
		assertState(child, EMBRYO, "fork");
		child->state = UNUSED;
		stateListAdd(&ptable.list[child->state], child, "fork fail");
		spin_unlock(&ptable.lock);
		return -1;
	}
	child->parent = p;
	*child->tf = *p->tf;
	// TODO: can't understand the reason for parent id.
	child->tf->eax = 0;
	spin_lock(&ptable.lock);
	if (stateListRemove(&ptable.list[EMBRYO], child, "fork") < 0)
		panic("In EMBRYO: Empty or process not in list");
	assertState(child, EMBRYO, "fork");
	child->state = RUNNABLE;
	stateListAdd(&ptable.ready[child->priority], child, "fork");
	spin_unlock(&ptable.lock);
	return child->pid;
}

void
exit(void)
{
	// sys_exit() call to here.
	// TODO: your code here.
	struct proc *p = thisproc();
	cprintf("process %d exit.\n", p->pid);
	spin_lock(&ptable.lock);
	if (p->parent) {
		cprintf("parent:%d\n", p->parent->pid);
		wakeup1(p->parent); // TODO: need root process
	}
	if (stateListRemove(&ptable.list[RUNNING], p, "exit") < 0)
		panic("In RUNNING: Empty or process is not in list");
	assertState(p, RUNNING, "exit");
	p->state = ZOMBIE;
	stateListAdd(&ptable.list[p->state], p, "exit");
	sched();
}

// TODO: run enough time!!!
#ifdef UGLY_YIELD
void
yield(void)
{
	struct proc *p = thisproc();
	spin_lock(&ptable.lock);
	if (stateListRemove(&ptable.list[RUNNING], p, "yield") < 0)
		panic("In RUNNING: Empty or process is not in list");
	assertState(p, RUNNING, "yield");
	p->state = RUNNABLE;
	if (p->priority > 0) {
		// cprintf("priority %d\n", p->priority);
		p->priority--;
		stateListAdd(&ptable.ready[p->priority], p, "yield");
		// cprintf("priority %d\n", p->priority);
	}
	p->budget = time_slice[p->priority];
	sched();
	spin_unlock(&ptable.lock);
}
#else
void
yield(void)
{
	struct proc *p = thisproc();
	spin_lock(&ptable.lock);
	if (stateListRemove(&ptable.list[RUNNING], p, "yield") < 0)
		panic("In RUNNING: Empty or process is not in list");
	assertState(p, RUNNING, "yield");
	p->state = RUNNABLE;
	if (p->priority > 0) {
		// cprintf("priority %d\n", p->priority);
		p->priority--;
		stateListAdd(&ptable.ready[p->priority], p, "yield");
		// cprintf("priority %d\n", p->priority);
	}
	p->budget = time_slice[p->priority];
	sched();
	spin_unlock(&ptable.lock);
}
#endif

void
sleep(void *chan, struct spinlock *lk)
{
	struct proc *p = thisproc();
	if (p == NULL)
		panic("sleep");
	if (lk == NULL)
		panic("sleep without tickslock");
	if (lk != &ptable.lock) {
		spin_lock(&ptable.lock);
		spin_unlock(lk);
	}
	if (stateListRemove(&ptable.list[RUNNING], p, "Sleep") < 0)
		panic("In Priority Queue: Empty or process is not in list");
	assertState(p, RUNNING, "Sleep");
	p->chan = chan;
	p->state = SLEEPING;
	stateListAdd(&ptable.list[p->state], p, "Sleep");
	sched();
	p->chan = NULL;
	if (lk != &ptable.lock) {
		spin_unlock(&ptable.lock);
		spin_lock(lk);
	}
}

int
wait(void)
{
	struct proc *p = thisproc();
	struct proc *q, *tmp;
	uint32_t pid;
	spin_lock(&ptable.lock);
	for (;;) {
		q = ptable.list[ZOMBIE].head;
		while (q) {
			tmp = q->next;
			if (q->parent == p) {
				if (stateListRemove(&ptable.list[ZOMBIE], q, "Wait") < 0)
					panic("In ZOMBIE: Empty or process not in list");
				assertState(q, ZOMBIE, "Wait");
				q->state = UNUSED;
				stateListAdd(&ptable.list[q->state], q, "Wait");
				pid = q->pid;
				vm_free(q->pgdir);
				kfree(q->kstack);
				q->kstack = NULL;
				q->pgdir = NULL;
				q->parent = NULL;
				q->pid = 0;
				spin_unlock(&ptable.lock);
				return pid;
			}
			q = tmp;
		}
		cprintf("sleep %d\n", p->pid);
		sleep(p, &ptable.lock);
	}
}

int
kill(uint32_t pid) // TODO
{
	struct proc *p;
	spin_lock(&ptable.lock);
	return 0;
}

#else
int
fork(void)
{
	struct proc *p = thisproc();
	struct proc *child;
	if ((child = proc_alloc()) == NULL)
		return -1;
	if ((child->pgdir = copyuvm(p->pgdir)) == NULL)
		return -1;
	child->parent = p;
	*child->tf = *p->tf;
	// TODO: can't understand the reason for parent id.
	child->tf->eax = 0;
	spin_lock(&ptable.lock);
	child->state = RUNNABLE;
	spin_unlock(&ptable.lock);
	return child->pid;
}

void
exit(void)
{
	// sys_exit() call to here.
	// TODO: your code here.
	struct proc *p = thisproc();
	spin_lock(&ptable.lock);
	p->state = ZOMBIE;
	sched();
}

void
yield(void)
{
	struct proc *p = thisproc();
	spin_lock(&ptable.lock);
	p->state = RUNNABLE;
	sched();
	spin_unlock(&ptable.lock);
}
#endif