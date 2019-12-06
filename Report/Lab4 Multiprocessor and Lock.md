# <center>Lab4 Multiprocessor and Lock</center>

[toc]

## Exercise 1

In mp_main(), since all the CPUs share the kernel page table, we need to inform all the APs of the address of kernel page table using kvm_switch() which sets %cr3 register to the address of kpgdir. Also every AP need to initialize their own gdt. The reason why they can not share the gdt is that gdt consists of **tss** segment which varies among CPUs. AP need to initialize their own local APIC and then invoke idt_init() to get the address of interrupt descriptor table. Finally use xchg() to inform BSP that this AP has finished initialization. All the procedure goes like what BSP does in i386_init(). And there are still some differences between them. All the preparations can be skipped over including memset(), cons_init(), boot_alloc_init(), vm_init(), trap_init(), pic_init(), alloc_init(), since CPUs share the same page table and interrupt descriptor table.

## Exercise 2

All we need to do is specify the CPU that we initialize.

## Exercise 3

Just as what we learn in the laboratory class.

## Exercise 4

> Compare kern/mpentry.S side by side with boot/boot.S. Bearing in mind that kern/mpentry.S is compiled and linked to run above KERNBASE just like everything else in the kernel, what is the purpose of macro MPBOOTPHYS? Why is it necessary in kern/mpentry.S but not in boot/boot.S? In other words, what could go wrong if it were omitted in kern/mpentry.S? 

In boot.S we've not turned on paging and can easily reference addresses such as start32, while in mpentry.S since addresses such as start32 reside above 0xf0000000, which can not be referenced in the real mode so need macro MPBOOTPHYS to map *mpentry_start + offset* to *MPENTRY_PADDR + offset*.

> It seems that using the big kernel lock guarantees that only one CPU can run the kernel code at a time. Why do we still need separate kernel stacks for each CPU? Describe a scenario in which using a shared kernel stack will go wrong, even with the protection of the big kernel lock.

When a write to disk or network occurs on CPU0, which will take time to complete, and then another system call takes place on CPU1 and have pushed all the necessary registers into the shared kernel stack and then the disk send an interrupt indicating that it has finished writing and then CPU0 entered the kernel state, since only one process can run in the kernel mode, so the other process on CPU1 will be switched out and then process on CPU0 may pop some registers that don't belong to it.

## MCS_Lock

In this section, I've implemented the mcslock which has lighter cache coherency than simple spinlock since each thread polls on its predecessor while the simple one polls on a single shared variable and every change will make the copies in other CPUs' cache invalidated which will significantly degrade the performance. The mcslock requires two atomic instructions: xchg and cmpxchg.

### cmpxchg

```c++
cmpxchg(volatile uint32_t *addr, uint32_t old, uint32_t new) {
	uint32_t result;

    asm volatile("lock; cmpxchgl %2, %1" // line 1
                 : "=a"(result)			 // line 2
                 : "m"(*addr), "r"(new), "a"(old)	// line 3
                 : "cc", "memory");		 // line 4
	return result;
}

```

According to Intel' manual, the LOCK# signal in the line 1 insures that the processor has exclusive use of any shared memory while the signal is asserted in a multiprocessor environment.

And the format of extended inline assembly looks like this

```c++
asm("statement"
    : output_reg(output_variable),  // optional
    : input_reg(input_variable),    // optional
    : colbbered_args);              // optional
```

So "=a"(result) means the output is assigned to %eax, on which resides *result*. And line 3 means assigning *new* to available register between %esi and %edi and *old* to %eax, and reading values from static memory location, *addr*. "memory" means writing to a variable that GCC thinks it has in a register, and "cc" indicates changing the condition codes. And *%n* tokens means the arguments is allocated to the *nth* register.

According to AT&T assembly syntax the assembly code below means assigning %cx to %bx if %ax equals to %bx and setting ZF to 1, otherwise assigning %bx to %ax and setting ZF to 0.

```assembly
cmpxchg %cx, %bx
```

Back to the code in line 1, it means if *\*addr*(%1) equals to *old*(%eax) then assign *new* to *\*addr* and set ZF to 1; otherwise assign *\*addr* to *old*(%eax) and set ZF to 0. And result will get the original value of *\*addr*.

```assembly
cmpxchgl %2, %1
```

So we can invoke cmpxchg in this way when unlocking.

```c
if (Cmpxchg(&lk->locked, tmp, NULL) == me)
```

### Mcslock

Mcslock need the following two data structure to work.

```c
struct mcslock_node {
	volatile uint32_t waiting;
	struct mcslock_node *volatile next;
};

struct mcslock {
	struct mcslock_node *locked;       // Is the lock held?
#ifdef DEBUG_SPINLOCK
	// For debugging:
	char *name;            // Name of lock.
	struct CpuInfo *cpu;   // The CPU holding the lock.
	uintptr_t pcs[10];     // The call stack (an array of program counters)
	                       // that locked the lock.
#endif
};
```

<img src="Pic/Mcslock">

As the picture above shows mcslock always points to the end of linked list waiting for the lock. And all the mcslock_node has two field: *waiting* and *next*. That node's *waiting* equals to 0 indicates this thread holds the lock and *next* points to the next thread waiting in the linked list. 

```c
void
mspin_lock(struct mcslock *lk)
{
	static __thread struct mcslock_node node;
	struct mcslock_node *me = &node;
	struct mcslock_node *tmp = me;
	me->next = NULL;
	struct mcslock_node *pre = Xchg(&lk->locked, tmp);
	if (pre == NULL)
		return;
	me->waiting = 1;
	asm volatile("" : : : "memory");
	pre->next = me;
	while (me->waiting) 
		asm volatile("pause");
}
```

Here *static __thread* variable can ensure changes made on it by a thread can only be seen by the thread itself. Everytime when a thread wants to acquire the lock, just invoke Xchg(), in which we wrap xchg() to help invert types of input and output in x86.h, to determine if mcslock is free. If it's free, Xchg() will return NULL which means thread has acquired the lock successfully and then return. However, if some thread is holding the lock, then this one has to wait, just set *waiting* to 1 and then insert mcslock_node of its own to the end of the linked list by setting the end's *next* points to this node. And then wait until the previous node set this node's waiting to 0. Here notice that we've inserted an assembly code between setting *waiting* and *next*, we'll explain it after we've finished explaining unlock.

```c
void
mspin_unlock(struct mcslock *lk)
{
	static __thread struct mcslock_node node;
	struct mcslock_node *me = &node;
	struct mcslock_node *tmp = me;
	if (me->next == NULL) {
		if (Cmpxchg(&lk->locked, tmp, NULL) == me)
			return;
		while (me->next == NULL)
			continue;
	}
	me->next->waiting = 0;
}
```

When a thread wants to release the lock, first it have to check if it's the last node wanting to acquire the lock, if it is then set mcslock points to *NULL*, and to ensure atomicity, here we invoke Cmpxchg(), a wrapper function we define in x86.h. If there are still some thread waiting to acquire the lock in the linked list, this thread need set next thread's waiting to 0 to inform that the lock is free.

Now we'll explore the meaning of the inserted assembly code we mention above which help to ensure the validity of the procedure. Since the following two statements have no correlation, CPU can execute them out of order. Image when a thread is acquiring the lock and its CPU plans to first execute statement (b) and then (a), then just after finishing (b), a thread on another CPU is releasing the lock, and it is supposed to be the last one in the linked list, and find that now some thread is waiting in the list so set its *waiting* to 0 to allow it to hold the lock then back to the acquiring thread to execute statement (a) and then spinwait for *waiting* since its previous node has set its *waiting* before its setting. To deal with this problem, we insert an assembly code to force the CPU to execute the statements respectively. In this way,  when the last thread in the list is releasing the lock and just find its *next* is NULL and then another thread is acquiring the lock and have changed lk->locked, then Atomic code Cmpxchg() will find lk->locked not equal to itself and then if *next* is still NULL just wait until the acquiring thread finish setting previous one's *next* and then the releasing one informs the acquiring one the lock is free.

```c
me->waiting = 1; 	(a)
pre->next = me;  	(b)
while (me->waiting) (c)
		asm volatile("pause");

```

## Reference

Three easy pieces awake my memory about locks. Also <a style="text-decoration:none;" href="http://www.delorie.com/djgpp/doc/brennan/brennan_att_inline_djgpp.html">Brennan's Guide</a> gives me the foundation of the inline assembly.

And the following three blogs give me helps in different ways:

- <a style="text-decoration:none;" href="https://www.ibm.com/developerworks/cn/linux/l-cn-mcsspinlock/index.html">Help me understand how mcslock works</a>
- <a style="text-decoration:none;" href="http://www.yebangyu.org/blog/2016/08/21/mcslock/">instruct me to implement mcslock more reasonably </a>
- <a style="text-decoration:none;" href="http://ju.outofmemory.cn/entry/146477">Help me roughly understand how atomic instruction cmpxchg works</a>
- <a style="text-decoration:none;" href="https://blog.csdn.net/lotluck/article/details/78793468?utm_source=blogxgwz7">Help me understand details of procedure of cmpxchg</a>