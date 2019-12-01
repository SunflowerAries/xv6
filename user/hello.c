// hello, world
#include <inc/lib.h>

void
umain(int argc, char **argv)
{
	uint32_t pid = fork();
	cprintf("pid:%d\n", pid);
	if (pid == 0) {
		cprintf("Here, I'm child process.\n");
		sleep(1);
	} else {
		cprintf("I'm father.\n");
		pid = wait();
		cprintf("wait pid %d.\n", pid);
	}
		
}
