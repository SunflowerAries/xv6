#ifndef JOS_INC_SYSCALL_H
#define JOS_INC_SYSCALL_H

/* system call numbers */
enum {
	SYS_cputs = 0,
	SYS_cgetc,
	SYS_exit,
	SYS_fork,
	SYS_sleep,
	SYS_wait,
	SYS_kill,
	SYS_ipc_recv,
	SYS_ipc_try_send,
	NSYSCALLS
};

#endif /* !JOS_INC_SYSCALL_H */
