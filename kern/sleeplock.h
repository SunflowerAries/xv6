#ifndef KERN_SLEEPLOCK_H
#define KERN_SLEEPLOCK_H

#include <inc/types.h>
#include <kern/spinlock.h>

struct sleeplock {
	uint32_t locked;
	struct spinlock lk;
#ifdef DEBUG_SLEEPLOCK
	// For debugging:
	char *name;            // Name of lock.
	uint32_t pid;
#endif
};
#endif