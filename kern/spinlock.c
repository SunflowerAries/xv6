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
	if (lk == &ptable.lock) {
		cprintf("CPU%d before aquire.\n", thiscpu->cpu_id);
	}
	if (pre != NULL) {
		if (lk == &ptable.lock) {
			for (int i = 0; i < 4; i++) {
				if (&cpus[i].node == pre) {
					cprintf("CPU%d wait CPU%d\n", thiscpu->cpu_id, i);
					break;
				}
			}
		}
		me->waiting = 1;
		__sync_synchronize();
		pre->next = me;
		cprintf("me: %x, pre: %x\n", me, pre->next);
		__sync_synchronize();
		while (me->waiting) {
			asm volatile("pause");
			if (!pre->next)
				panic("Next empty");
			else if (pre->next != me)
				panic("Next False");
		}
	}
	if (lk == &ptable.lock) {
		cprintf("CPU%d acquire ptable.lock with pre: %x\n", thiscpu->cpu_id, pre);
	}
	lk->cpu = thiscpu;
}

void
spin_unlock(struct spinlock *lk)
{
	struct mcslock_node *me = &thiscpu->node;
	struct mcslock_node *tmp = me;
	if (!holding(lk)) {
		if (lk->cpu) {
			cprintf("unlock: %u, %u\n", lk->cpu->cpu_id, thiscpu->cpu_id);
		}
		else {
			cprintf("unlock: NULL, %u\n", thiscpu->cpu_id);
		}
		panic("spin_unlock");
	}
	lk->cpu = NULL;
	if (lk == &ptable.lock) {
		cprintf("CPU%d release ptable.lock with next %x\n", thiscpu->cpu_id, me->next);
	}
	__sync_synchronize();
	if (me->next == NULL) {
		if (Cmpxchg(&lk->locked, tmp, NULL) == me) {
			__sync_synchronize();
			if (lk == &ptable.lock) {
				cprintf("CPU%d has no next.\n", thiscpu->cpu_id);
			}
			popcli();
			return;
		}
		// cprintf("Entre.\n");
		int num = 0;
		while (me->next == NULL) {
			asm volatile("pause");
			num++;
			if (num > 10000)
				return;
		}
		// cprintf("Fini.\n");
	}
	__sync_synchronize();
	cprintf("OK\n");
	int i = 0;
	if (lk == &ptable.lock) {
		for (; i < 4; i++) {
			if (&cpus[i].node == me->next) {
				cprintf("CPU%d wakeup CPU%d\n", thiscpu->cpu_id, i);
				break;
			}
		}
	}
	me->next->waiting = 0;
	cprintf("CPU%d wakeup.\n", i);
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
	if (lk->cpu == thiscpu)
		panic("spinlock");
	while(xchg(&lk->locked, 1));
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
	if (lk->cpu == thiscpu) {
		lk->cpu = 0;
		//xchg(&lk->locked, 0);
		__sync_synchronize();
		asm volatile("movl $0, %0" : "+m"(lk->locked) : );
	} else 
		panic("spin_unlock");
	popcli();
}

int
holding(struct spinlock *lock)
{
  int r;
  pushcli();
  r = lock->cpu == thiscpu;
  popcli();
  return r;
}
#endif