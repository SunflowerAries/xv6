#ifndef JOS_INC_SYSCALL_H
#define JOS_INC_SYSCALL_H

/* system call numbers */
enum {
	SYS_cputs = 0,
	SYS_cgetc,
	SYS_exit,
	SYS_yield,
	SYS_fork,
	SYS_ipc_recv,
	SYS_ipc_send,
	NSYSCALLS
};

#endif /* !JOS_INC_SYSCALL_H */
