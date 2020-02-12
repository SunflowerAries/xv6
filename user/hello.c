// hello, world
#include <inc/lib.h>

void
umain(int argc, char **argv)
{
	// cprintf("before fork\n");
	uint32_t pid = fork();
	cprintf("pid:%d\n", pid);
	char buf[12] = "hello world";
	char buff[20];
	if (pid == 0) {
		cprintf("Here, I'm child process.\n");
		sleep(1);
		int fd = open("hello", O_RDWR | O_CREAT);
		cprintf("child write \"%s\" to fd[%d]\n", buf, fd);
		if (write(fd, buf, sizeof(buf)) != sizeof(buf))
			cprintf("write error\n");
	} else {
		cprintf("I'm father.\n");
		pid = wait();
		cprintf("wait pid %d.\n", pid);
		int fd = open("hello", O_RDWR | O_CREAT);		
		if (read(fd, buff, sizeof(buf)) != sizeof(buf))
			cprintf("read error\n");
		cprintf("parent read \"%s\" from fd[%d]\n", buff, fd);
	}
}
