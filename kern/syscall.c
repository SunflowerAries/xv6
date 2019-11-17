#include <inc/x86.h>
#include <inc/error.h>
#include <inc/string.h>
#include <inc/assert.h>
#include <inc/mmu.h>

#include <kern/trap.h>
#include <kern/syscall.h>
#include <kern/console.h>
#include <kern/proc.h>
#include <kern/vm.h>

/*static int (*syscalls[])(void) = {
[SYS_cputs] sys_cputs,
[SYS_cgetc] sys_cgetc,
[SYS_exit] sys_exit,
};*/

// Print a string to the system console.
// The string is exactly 'len' characters long.
static void
sys_cputs(const char *s, size_t len)
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// TODO: Your code here.
	struct proc *p = thisproc();
	char *tmp = (char *)s;
	void *begin = ROUNDDOWN(tmp, PGSIZE);
	void *end = ROUNDUP(tmp + len, PGSIZE);
	while (begin < end) {
		pte_t *pte = pgdir_walk(p->pgdir, begin, 0);
		if (*pte & PTE_U)
			begin += PGSIZE;
		else {
			exit();
		}
	}
	// Print the string supplied by the user.
	cprintf(s);
}

// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
}

static void
sys_exit(void)
{
	exit();
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// TODO: Your code here.
	struct proc *p = thisproc();
	switch (syscallno) {
		case SYS_cputs:
			sys_cputs((const char *)a1, (size_t)a2);
			return 0;
		case SYS_cgetc:
			return sys_cgetc();
		case SYS_exit:
			sys_exit();
			return 0;

		default:
			return 0;
	}
	
}