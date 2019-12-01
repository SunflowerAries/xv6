#include <inc/lib.h>

void
exit(void)
{
	sys_exit();
}

int
fork(void)
{
	return sys_fork();
}

void
sleep(uint32_t n)
{
	sys_sleep(n);
}

int
wait(void)
{
	return sys_wait();
}

int
kill(uint32_t pid)
{
	return sys_kill(pid);
}