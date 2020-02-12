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
#include <kern/stat.h>
#include <kern/log.h>
#include <kern/fcntl.h>

extern struct spinlock tickslock;
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

static int
sys_fork(void)
{
	return fork();
}

static void
sys_sleep(uint32_t n)
{
	spin_lock(&tickslock);
	struct proc *p = thisproc();
	uint32_t ticks0 = ticks;
	while(ticks - ticks0 < n) {
		sleep(&ticks, &tickslock);
	}
	spin_unlock(&tickslock);
}

static int
sys_wait()
{
	return wait();
}

static int
sys_kill(uint32_t pid)
{
	return kill(pid);
}

static void
sys_ipc_try_send()
{
	
}

static void
sys_ipc_recv()
{

}

static int 
sys_link(char *old, char *new)
{
	char name[DIRSIZ];
	struct inode *ip, *dp;

	begin_op();
	if ((ip = namei(old)) == NULL) {
		end_op();
		return -1;
	}

	ilock(ip);
	if (ip->type == T_DIR) {
		iunlockput(ip);
		end_op();
		return -1;
	}

	ip->nlink++;
	iupdate(ip);
	iunlock(ip);

	if ((dp = nameiparent(new, name)) == NULL)
		goto bad;
	ilock(dp);
	if (dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0) {
		iunlockput(dp);
		goto bad;
	}
	iunlockput(dp);
	iput(ip);

	end_op();
	return 0;

	bad:
		ilock(ip);
		ip->nlink--;
		iupdate(ip);
		iunlockput(ip);
		end_op();
		return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
	struct inode *ip, *dp;
	char name[DIRSIZ];
	if ((dp = nameiparent(path, name)) == NULL)
		return 0;
	ilock(dp);

	if ((ip = dirlookup(dp, name, 0)) != NULL) {
		iunlockput(dp);
		ilock(ip);
		if (type == T_FILE && ip->type == T_FILE)
			return ip;
		iunlockput(ip);
		return 0;
	}

	if ((ip = ialloc(dp->dev, type)) == NULL)
		panic("create: ialloc");
	
	ilock(ip);
	ip->major = major;
	ip->minor = minor;
	ip->nlink = 1;
	iupdate(ip);

	if (type == T_DIR) { // Create . and .. entries.
		dp->nlink++;	 // for ..
		iupdate(dp);
		// No ip->nlink++ for ".": avoid cyclic ref count.
		if (dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
			panic("create dots");
	}

	if (dirlink(dp, name, ip->inum) < 0)
		panic("create: dirlink");

	iunlockput(dp);
	return ip;
}

static int
fdalloc(struct file *f)
{
	struct proc *curproc = thisproc();
	for (int fd = 0; fd < NFILE; fd++)
		if (curproc->ofile[fd] == NULL) {
			curproc->ofile[fd] = f;
			return fd;
		}
	return -1;
}

static int
sys_open(char *path, int mode)
{
	int fd;
	struct file *f;
	struct inode *ip;

	begin_op();
	if (mode & O_CREATE) {
		ip = create(path, T_FILE, 0, 0);
		if (ip == NULL) {
			end_op();
			return -1;
		}
	} else {
		if ((ip = namei(path)) == NULL) {
			end_op();
			return -1;
		}
		ilock(ip);
		if (ip->type == T_DIR && mode != O_RDONLY) {
			iunlockput(ip);
			end_op();
			return -1;
		}
	}
	
	if ((f = filealloc()) == NULL || (fd = fdalloc(f)) < 0) {
		if (f)
			fileclose(f);
		iunlockput(ip);
		end_op();
		return -1;
	}
	iunlock(ip);
	end_op();

	f->type = FD_INODE;
	f->ip = ip;
	f->off = 0;
	f->readable = !(mode & O_WRONLY);
	f->writable = (mode & O_WRONLY) || (mode & O_RDWR);
	return fd;
}

static int
sys_read(int32_t fd, char *buf, int len)
{
	struct file *f;
	if (fd < 0 || fd >= NFILE || (f = thisproc()->ofile[fd]) == NULL)
		return -1;
	return fileread(f, buf, len);
}

static int
sys_stat(int32_t fd, struct stat *st)
{
	struct file *f;
	if (fd < 0 || fd >= NFILE || (f = thisproc()->ofile[fd]) == NULL)
		return -1;
	return filestat(f, st);
}

static int
isdirempty(struct inode *dp)
{
	struct dirent de;
	for (int off = 2*sizeof(de); off < dp->size; off += sizeof(de)) {
		if (readi(dp, (char *)&de, off, sizeof(de)) != sizeof(de))
			panic("isdirempty: readi");
		if (de.inum != 0)
			return 0;
	}
	return 1;
}

static int
sys_unlink(char *path)
{
	struct inode *dp, *ip;
	struct dirent de;
	uint32_t off;
	char name[DIRSIZ];

	begin_op();
	if ((dp = nameiparent(path, name)) == NULL) {
		end_op();
		return -1;
	}

	ilock(dp);
	if (namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
		goto bad;
	
	if ((ip = dirlookup(dp, name, &off)) == NULL)
		goto bad;
	ilock(ip);

	if (ip->ref < 1)
		panic("unlink: nlink < 1");
	if (ip->type == T_DIR && !isdirempty(ip)) {
		iunlockput(ip);
		goto bad;
	}

	memset(&de, 0, sizeof(de));
	if (writei(dp, (char *)&de, off, sizeof(de)) != sizeof(de))
		panic("unlink: writei");
	if (ip->type == T_DIR) {
		dp->nlink--;
		iupdate(dp);
	}
	iunlockput(dp);

	ip->nlink--;
	iupdate(ip);
	iunlockput(ip);

	end_op();
	return 0;

	bad:
		iunlockput(dp);
		end_op();
		return -1;
}

static int
sys_write(int32_t fd, char *buf, int len)
{
	struct file *f;
	if (fd < 0 || fd >= NFILE || (f = thisproc()->ofile[fd]) == NULL)
		return -1;
	return filewrite(f, buf, len);
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
		case SYS_fork:
			return sys_fork();
		case SYS_sleep:
			sys_sleep(a1);
			return 0;
		case SYS_wait:
			return sys_wait();
		case SYS_kill:
			return sys_kill(a1);
		case SYS_ipc_recv:
			sys_ipc_recv();
			return 0;
		case SYS_ipc_try_send:
			sys_ipc_try_send();
			return 0;
		case SYS_open:
			return sys_open((char *)a1, a2);
		case SYS_read:
			return sys_read(a1, (char *)a2, a3);
		case SYS_write:
			return sys_write(a1, (char *)a2, a3);
		case SYS_link:
			return sys_link((char *)a1, (char *)a2);
		case SYS_unlink:
			return sys_unlink((char *)a1);
		case SYS_stat:
			return sys_stat(a1, (struct stat *)a2);
		default:
			return 0;
	}
}