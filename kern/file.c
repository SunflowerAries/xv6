//
// File descriptors
//

#include <inc/types.h>
#include <inc/assert.h>

#include <kern/fs.h>
#include <kern/spinlock.h>
#include <kern/sleeplock.h>
#include <kern/file.h>
#include <kern/log.h>

struct devsw devsw[NDEV];
struct {
	struct spinlock lock;
	struct file file[NFILE];
} ftable;

void
fileinit(void)
{
	__spin_initlock(&ftable.lock, "ftable");
}

// Allocate a file structure.
struct file*
filealloc(void)
{
	struct file *f;

	spin_lock(&ftable.lock);
	for (f = ftable.file; f < ftable.file + NFILE; f++)
		if (f->ref == 0) {
			f->ref = 1;
			spin_unlock(&ftable.lock);
			return f;
		}
	
	spin_unlock(&ftable.lock);
	return NULL;
}

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
	spin_lock(&ftable.lock);
	if (f->ref < 1)
		panic("filedup");
	f->ref++;
	spin_unlock(&ftable.lock);
	return f;
}

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
	struct file ff;

	spin_lock(&ftable.lock);
	if (f->ref < 1)
		panic("fileclose");
	if (--f->ref > 0) {
		spin_unlock(&ftable.lock);
		return;
	}
	ff = *f;
	f->ref = 0;
	f->type = FD_NONE;
	spin_unlock(&ftable.lock);

	if (ff.type == FD_INODE) {
		begin_op();
		iput(ff.ip);
		end_op();
	}
}

// Get metadata about file f.
int
filestat(struct file *f, struct stat *st)
{
	if (f->type == FD_INODE) {
		ilock(f->ip);
		stati(f->ip, st);
		iunlock(f->ip);
		return 0;
	}
	return -1;
}

// Read from file f.
int
fileread(struct file *f, char *addr, int n)
{
	int r;

	if (f->readable == 0)
		return -1;
	if (f->type == FD_INODE) {
		ilock(f->ip);
		if ((r = readi(f->ip, addr, f->off, n)) > 0)
			f->off += r;
		iunlock(f->ip);
		return r;
	}
	panic("fileread");
}

// Write to file f.
int
filewrite(struct file *f, char *addr, int n)
{
	int r;

	if (f->writable == 0)
		return -1;
	if (f->type == FD_INODE) {
		int max = ((MAXOPBLOCKS-1-1-2) / 2) * 512;
		int i = 0;
		while (i < n) {
			int n1 = n - i;
			if (n1 > max) 
				n1 = max;
				
			begin_op();
			ilock(f->ip);
			if ((r = writei(f->ip, addr + i, f->off, n1)) > 0)
				f->off += r;
			iunlock(f->ip);
			end_op();

			if (r < 0)
				break;
			if (r != n1)
				panic("short filewrite");
			i += r;
		}
		return i == n ? n : -1;
	}
	panic("filewrite");
}

