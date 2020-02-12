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

int
open(char *path, int mode)
{
	return sys_open(path, mode);
}

int
read(int32_t fd, char *buf, int len)
{
	return sys_read(fd, buf, len);
}

int
write(int32_t fd, char *buf, int len)
{
	return sys_write(fd, buf, len);
}

int 
link(char *old, char *new)
{
	return sys_link(old, new);
}

int
unlink(char *path)
{
	return sys_unlink(path);
}

int
stat(int32_t fd, struct stat *st)
{
	return sys_stat(fd, st);
}