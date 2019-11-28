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