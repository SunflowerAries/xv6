// System call stubs.

#include <inc/syscall.h>
#include <inc/lib.h>
#include <inc/traps.h>
#include <kern/spinlock.h>

static inline int32_t
syscall(int num, int check, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
	int32_t ret;

	// Generic system call: pass system call number in AX,
	// up to five parameters in DX, CX, BX, DI, SI.
	// Interrupt kernel with T_SYSCALL.
	//
	// The "volatile" tells the assembler not to optimize
	// this instruction away just because we don't use the
	// return value.
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
		     : "=a" (ret)
		     : "i" (T_SYSCALL),
		       "a" (num),
		       "d" (a1),
		       "c" (a2),
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
		panic("syscall %d returned %d (> 0)", num, ret);

	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}

void
sys_exit(void)
{
	syscall(SYS_exit, 0, 0, 0, 0, 0, 0);
}

int
sys_fork(void)
{
	return syscall(SYS_fork, 0, 0, 0, 0, 0, 0); // TODO check the number of arguments
}

void
sys_sleep(uint32_t n)
{
	syscall(SYS_sleep, 0, n, 0, 0, 0, 0);
}

int
sys_wait(void)
{
	return syscall(SYS_wait, 0, 0, 0, 0, 0, 0);
}

int
sys_kill(uint32_t pid)
{
	return syscall(SYS_kill, 0, pid, 0, 0, 0, 0);
}

int
sys_read(int32_t fd, char *buf, int len)
{
	return syscall(SYS_read, 0, fd, (uint32_t)buf, len, 0, 0);
}

int
sys_write(int32_t fd, const char *buf, int len)
{
	return syscall(SYS_write, 0, fd, (uint32_t)buf, len, 0, 0);
}

int
sys_open(char *path, int mode)
{
	return syscall(SYS_open, 0, (uint32_t)path, mode, 0, 0, 0);
}

int
sys_link(char *old, char *new)
{
	return syscall(SYS_link, 0, (uint32_t)old, (uint32_t)new, 0, 0, 0);
}

int
sys_unlink(char *path)
{
	return syscall(SYS_unlink, 0, (uint32_t)path, 0, 0, 0, 0);
}

int
sys_stat(int32_t fd, struct stat *st)
{
	return syscall(SYS_stat, 0, fd, (uint32_t)st, 0, 0, 0);
}