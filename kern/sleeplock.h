#ifndef KERN_SLEEPLOCK_H
#define KERN_SLEEPLOCK_H

#include <inc/types.h>
#include <kern/spinlock.h>

struct sleepnode {
	uint32_t pid;
	struct sleepnode *next;
};

struct sleeping_queue {
	struct sleepnode *head;
	struct sleepnode *tail;
};

struct sleeplock {
	uint32_t locked;
	struct spinlock lk;
	struct sleeping_queue queue;
#ifdef DEBUG_SLEEPLOCK
	// For debugging:
	char *name;            // Name of lock.
	uint32_t pid;
#endif
};

void __sleep_initlock(struct sleeplock *lk, char *name);
void sleep_lock(struct sleeplock *lk);
bool holdingsleep(struct sleeplock *lk);
void sleep_unlock(struct sleeplock *lk);
int holding(struct spinlock *lock);
#endif
