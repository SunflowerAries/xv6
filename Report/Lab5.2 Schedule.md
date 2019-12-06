# <center>Lab5.2 Schedule</center>

[toc]

## Exercise 4

In this section, I've implemented a **Multilevel Feedback Queue Scheduling(MLFQ)**, which accommodates 5 queues of different priorities whose given time slices double with the decreasing of priority, ranging from 1 to 16 units of time. After 1000 units of time, we boost the priority of all the process in the system in a moderate way, advancing only one level.

We've added some fields to both *ptable* and *proc*, In struct *proc*, we've added *priority*, *budget*, *begin_tick*, *chan*, where *budget* refers to the given time slice of every process and *begin_tick* refers to the time at which this process is scheduled to run the CPU, and *chan* refers to the place where a process invoking system call *sleep* sleeps. We've also added a struct *ptrs* which help to manage a queue of *proc*, of which *head* refers to the first node of queue and *tail* refers to the last node of queue. With this new struct, we've added *list* and *ready* queues, where each *list* accommodates processes of different states to help to find a process of given state more quickly and *ready* accommodates processes of different priorities which waits for being scheduled. Then *PromoteAtTime* records the time that next boosting will occur.

```c
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
```

In this case, nearly all the functions in proc.c need revising. In **user_init()**, we should first initialize all the added queues to *NULL*, and then put all the process into the *UNUSED* queue to hide the *ptable.proc*, in this way every time when allocating a new process, we just check if there are processes in that queue. Then call **proc_alloc()** to allocate the first process and then go as before until we've finished initialized the first process and then change the state of the first process from *EMBRYO* to *READY*. Here we have to mention that every time when we change the state or priority of a process we need to ensure the atomicity of the procedure. Just as follows

```c
Acquire_lock(&ptable.lock)
Remove_process_from_list(ptable.list[p->state], p)
Change_state(p)
Add_process_to_list(ptable.list[p->state], p)
Release_lock(&ptable.lock)
```

We insert a process to the tail of queue using **stateListAdd**, and iterate the whole queue to remove the given process through **stateListRemove** and return 0 to indicate success, otherwise -1 to indicate failure.

In **proc_alloc()** we just use the atomic procedure illustrated above to convert the state of the first process of *UNUSED* queue to *EMBRYO*. And then if we fail to allocate space for the kernel stack, we should also convert the state back to *UNUSED* atomically. At end of the function, we add the initialization of *priority* and *budget* of process.

Then when comes to the scheduler, we'd better first have a look at the pseudo-code.

```c
void scheduler(void) {
    While True
        Turn on the interrupt
        Acquire_lock(&ptable.lock)
        If Time equals to NextTimeToBoost
            For priority = 0 to MAX_Priority - 1
                For process in Ready[priority]
                    advance process's level
            Update NextTimeToBoost
        For priority = MAX_Priority to 0
            If there exists RUNNABLE process in Ready[priority]
                Update process's state(RUNNABLE to RUNNING)
                swtch the environment
                break
        Release_lock(&ptable.lock)
    Endwhile
}
```

Several things to mention

- We need to check if we need to boost processes before scheduling process to run the CPU, and here we choose to lift processes' level in a moderate way.
- And then we schedule processes to run and start from the queue of *MAX_Priority* to ensure processes of higher priority be scheduled before lower ones. And every time after scheduling a process, we need to restart from the beginning of the while loop. Otherwise, we may come across a situation that a process of higher priority come during scheduling a lower process, and after finishing scheduling, we continue to schedule processes of lower priority without turning to the higher one.

And we also implement system calls including **fork, sleep, wait**, and other functions such as **wakeup1, yield**. The reason why we do not set **yield** as a system call is that we believe with coroutines, **wakeup1** and **sleep**, there is no need to expose **yield** to the user mode. We'll take the same way to first give the pseudo-code and then point out some important parts as above.

### Fork

```c
int fork(void) {
    If allocating a process as child fails
        return -1 to indicate failure
    If allocate space for child's pgdir and copy the pgdir from parent to child fails
        Release space allocated to the child process's kernel stack
        Update process's state(EMBRYO to UNUSED)
        return -1 to indicate failure
    Copy the trapframe from parent to child
    Set child's $eax on trapframe to 0
    Update process's state(EMBRYO to RUNNABLE)
    return child's pid
}
```

There is only one point worth mentioning

- We set child's \$eax on trapframe to 0, since it's the return value of **fork** for child process and child's pid is the return value of  **fork** for parent process.

### Sleep and Wakeup1

```c
void sleep(void *chan, struct spinlock *lk) {
	If lk is not ptable's lock
    	Acquire_lock(&ptable.lock)
        Release_lock(lk)
    Update process's state(RUNNING to SLEEPING)
    process->chan = chan(sleep on chan)
    Sched(call to scheduler)
    process->chan = NULL
    If lk is not ptable's lock
    	Release_lock(&ptable.lock)
        Acquire_lock(lk)
}

void wakeup1(void *chan) {
    For process in ptable.list[SLEEPING]
        If(process->chan equals to chan) (process sleep on chan)
        	Update process's state(SLEEPING to RUNNABLE)
}
```

One thing to mention

- In **sleep**, since we need to update the state of process, we need to acquire the lock of ptable to ensure atomicity, and set process's *chan* to *chan*, meaning sleeping on chan. When waking up process, we just iterate the sleeping list to find if there exist processes sleeping on *chan*.

### Wait and Exit

```c
int wait(void) {
	Acquire_lock(&ptable.lock)
	While True
		For process in ptable.list[ZOMBIE]
        	If process.parent equals to recent process
        		Update process's state(ZOMBIE to UNUSED)
        		Release space allocated for process
                Release_lock(&ptable.lock)
                return process->pid
        sleep(recent process, &ptable.lock)
	Endwhile
}

void exit(void) {
    Acquire_lock(&ptable.lock)
    If recent process's parent exists
        wakeup1(process' parent)
    Update process's state(RUNNING to ZOMBIE)
    Sched(call to scheduler)
}
```

- In **wait**, process have to loop until it finds one of its child *ZOMBIE*, so after iterating the whole list without finding a qualified process, it will sleep on itself until one of its children exit and wake up the parent.
- When finding a qualified child process, we need to reclaim space allocated for it, including *pgdir*, *kstack*, *user memory*. Setting related pointer to NULL is also necessary, including *kstack*, *pgdir*, *parent*.

### Yield

```c
void yield(void) {
	Acquire_lock(&ptable.lock)
    Update process's state(RUNNING to RUNNABLE)
    Update process's priority(decrease) and time_slice(increase)
    Sched(call to scheduler)
    Release_lock(&ptable.lock)
}
```

- Since we put the judgment whether the process has used up its whole time slice into **trap**, it must have used up the slice once entering the **yield**, and we need to update the process's priority(decrease) and time slice(increase).

## Reference

To implement MLFQ, I've referred both <a style="text-decoration:none;" href="http://pages.cs.wisc.edu/~gerald/cs537/Fall17/projects/p2b.html">UW-Madison</a>'s and <a style="text-decoration:none;" href="https://web.cecs.pdx.edu/~markem/CS333/projects/p4">Portland-State University</a>'s projects.