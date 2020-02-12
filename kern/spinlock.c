// Mutual exclusion spin locks.

#include <inc/types.h>
#include <inc/assert.h>
#include <inc/x86.h>
#include <inc/memlayout.h>
#include <inc/string.h>
#include <kern/cpu.h>
#include <kern/spinlock.h>
#include <kern/vm.h>

extern struct ptable ptable;
// The big kernel lock
struct spinlock kernel_lock = {
#ifdef DEBUG_SPINLOCK
	.name = "kernel_lock"
#endif
};

void
__spin_initlock(struct spinlock *lk, char *name)
{
	// TODO: Your code here.
#ifdef DEBUG_MCSLOCK
	lk->locked = NULL;
#else
	lk->locked = 0;
#endif
	lk->name = name;
	lk->cpu = 0;
}

// Acquire the lock.
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.

#ifdef DEBUG_MCSLOCK
void
spin_lock(struct spinlock *lk)
{
	pushcli();
	if (holding(lk))
		panic("spinlock");
	struct mcslock_node *me = &thiscpu->node;
	struct mcslock_node *tmp = me;
	me->next = NULL;
	struct mcslock_node *pre = Xchg(&lk->locked, tmp);
	__sync_synchronize();
	if (pre != NULL) {
		me->waiting = 1;
		__sync_synchronize();
		pre->next = me;
		__sync_synchronize();
		while (me->waiting) {
			asm volatile("pause");
		}
	}
	lk->cpu = thiscpu;
}

void
spin_unlock(struct spinlock *lk)
{
	struct mcslock_node *me = &thiscpu->node;
	struct mcslock_node *tmp = me;
	if (!holding(lk)) {
		cprintf("locked: %d, cpu: %d, %u\n", ptable.lock.locked != NULL, ptable.lock.cpu == thiscpu, ptable.lock.cpu);
		panic("spin_unlock");
	}
	lk->cpu = NULL;
	__sync_synchronize();
	if (me->next == NULL) {
		if (Cmpxchg(&lk->locked, tmp, NULL) == me) {
			__sync_synchronize();
			popcli();
			return;
		}
		while (me->next == NULL);
	}
	__sync_synchronize();
	me->next->waiting = 0;
	__sync_synchronize();
	me->next = NULL;
	popcli();
}

int
holding(struct spinlock *lock)
{
	int r;
	pushcli();
	// if (lock->cpu)
	// 	cprintf("holding: %u, %u\n", lock->cpu->cpu_id, thiscpu->cpu_id);
	// else
	// 	cprintf("holding: NULL, %u\n", thiscpu->cpu_id);
	r = lock->locked && lock->cpu == thiscpu;
	popcli();
	return r;
}
#else
void
spin_lock(struct spinlock *lk)
{
	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	// TODO: Your code here.
	pushcli();
	if(holding(lk))
    	panic("acquire");
	while(xchg(&lk->locked, 1) != 0);
	__sync_synchronize();
	lk->cpu = thiscpu;
}

// Release the lock.
void
spin_unlock(struct spinlock *lk)
{

	// The xchg instruction is atomic (i.e. uses the "lock" prefix) with
	// respect to any other instruction which references the same memory.
	// x86 CPUs will not reorder loads/stores across locked instructions
	// (vol 3, 8.2.2). Because xchg() is implemented using asm volatile,
	// gcc will not reorder C statements across the xchg.
	// TODO: Your code here.
	if (!holding(lk))
		panic("release");
	
	lk->cpu = NULL;
	__sync_synchronize();
	asm volatile("movl $0, %0" : "+m" (lk->locked) : );
	// xchg(&lk->locked, 0);
	// if (lk->cpu == thiscpu) {
	// 	lk->cpu = 0;
	// 	//xchg(&lk->locked, 0);
		
	// } else 
	// 	panic("spin_unlock");
	popcli();
}

int
holding(struct spinlock *lock)
{
  int r;
  pushcli();
  r = lock->locked && lock->cpu == thiscpu;
//   cprintf("thiscpu: %u, lock: %u, r: %d\n", thiscpu, lock->cpu, r);
  popcli();
  return r;
}
#endif