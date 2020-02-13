# <center>Lab7b File System (Part B)</center>

[toc]

## Inode Layer(Metadata)

### Ialloc and Iget

**Ialloc** is used to allocate a new inode. Similar to **balloc**, it loops over the inode sectors on disk to find one marked free. If found, we then update its type and write back to disk and then return an entry of corresponding item on inode cache through **iget**.

**Iget** looks through the inode cache for an active entry with the corresponding device and inode number. If found, return the inode entry. Different from **bget**, we do not implement a doubly linked list and not refer to the design of cold-hot page. Moreover **iget** returns an unlocked inode. A typical sequence just like below

```c
    ip = iget(dev, inum);
    ilock(ip);
    modify(ip);
    iunlock(ip);
    iput(ip)
```

In this way (**ilock** separate from **iget**), we can have a long-term reference to an inode (as for system call **open**) and only lock the inode for short periods(for system calls **write** and **read**). It can also help avoid deadlock and races during pathname lookup.

### Ilock and Iunlock

We must lock(**sleeplock**) the inode before reading or writing its metadata or content through **ilock**. Once we have exclusive access to the inode, we can read the inode from disk (more likely, the buffer cache) if needed.

**Iunlock** just release the **sleeplock**.

### Iput and Itrunc

**Iput** releases a C pointer to an inode by decrementing the reference count. If **iput** sees that there are no C pointer references to an inode and that the inode has no links to it (occurs in no directory), then the inode and its data blocks must be freed. **Iput** calls **itrunc** to truncate the file to zero bytes, freeing the data blocks; sets the inode type to 0 (unallocated); and writes the inode to disk by calling **iupdate**.

Since **iput** can write to the disk, which means that any system call that uses the file system may write the disk.

There seems to be many dangers in the locking protocol in **iput** in which it frees the inode thus worthing a closer look. One danger is that a concurrent thread might be waiting in **ilock** to use this inode (e.g. to read a file or list a directory), and won’t be prepared to find the inode is not longer allocated. This can’t happen because there is no way for a system call to get a pointer to a cached inode if it has no links to it and ip->ref is one. That one reference is the reference owned by the thread calling **iput**. It’s true that **iput** checks that the reference count is one outside of its icache.lock critical section, but at that point the link count is known to be zero, so no thread will try to acquire a new reference.

The other main danger is that a concurrent call to **ialloc** might choose the same inode that **iput** is freeing. This can only happen after the **iupdate** writes the disk so that the inode has type zero, so the allocating thread will politely wait to acquire the inode’s sleep-lock before reading or writing the inode, at which point **iput** is done with it

## Inode Layer(Content)

### Bmap

**Bmap** returns the disk block number of the data block for that inode. If the inode does not have such a block yet, bmap allocates one. 

Some things to mention, an inode has **NDIRECT**(12) direct entry pointing to data blocks on disk, and an indirect entry which points to a data blocks on which reside **NINDIRECT** entries point to the rest data blocks.

### Readi, Writei and Stati

**readi** reads each block of the file, copying data from the buffer into destination.

**writei** copies data into the buffer, and update its size if needed.

**Stati** copies inode metadata into the stat structure, which is exposed to user programs via the **stat** system call.

## Directory Layer

### Dirlookup

**Dirlookup** searches a directory for an entry with the given name. If it finds one, it returns a pointer to the corresponding inode, unlocked, and return byte offset of the entry within the directory, in case the caller wishes to edit it.

### Dirlink

**Dirlink** writes a new directory entry with the given name and inode number into the directory dp. If the name already exists, **dirlink** should return an error. 

## Path Name Layer

### Namei(parent) and Namex

Both **namei** and **nameiparent** call the generalized function **namex** to do the real work. The difference between **namei** and **nameiparent** is that the latter stops before the last element, returning the inode of the parent directory and copying the final element into name. 

**Namex** starts by deciding where the path evaluation begins. If the path begins with a slash, evaluation begins at the root; otherwise, the current directory. Then it uses **skipelem** to consider each element of the path in turn.

## File Descriptor Layer

### Filealloc, Filedup and Fileclose

**Filealloc** scans the file table for an unreferenced file (f->ref == 0) and returns a new reference; **filedup** increments the reference count; and **fileclose** decrements it. When a file’s reference count reaches zero, **fileclose** releases the underlying inode.

### Fileread, Filewrite and Filestat

**Fileread** need to acquire corresponding sleeplock before reading from datablock. As for **Filewrite**, limited by the size of log sectors on disk, we limit the size that we can write and truncate the to-write data to pieces and only possess sleeplock when writing. If the file represents an inode, **fileread** and **filewrite** use the i/o offset as the offset for the operation and then advance it. **Filestat** just copy metadata from inode.

## System Call

### Open

In this section, we need to open a file. Operations can be totally different according to the given mode. If enabling **O_CREATE**, we'll create a file by first looking through the directory to find if there exists one, if found, just return the corresponding inode; if not, call **ialloc** to allocate an inode, then advance as its type suggests.

Then we need to allocate a file descriptor, index of ftable of a process, to point to the inode.

### Read, Write and Stat

In this section, we mainly use the function we implement above, such as **fileread**, **filewrite**, **filestat**, but we need to check given file descriptor and whether there is a corresponding file in the calling process's ftable.

### Link and Unlink

**Link** and **unlink** only act on the file not directory, which link and unlink the same inode with different name. When no process have links to the inode, we can drop it.

## Fix

As for **fork**, We need clone context as well as file descriptor. For **exit**, we need also release files occupied by the process.

## Conclusion

Finally, I've finished all the code for my xv6, integrated with Buddy System to allocate kernel memory, Multi-level Feedback Queue to schedule process. Sadly, I have to give up MCSLock since it can not support multi-core(I've debugged half a month, but it can only support single-core). To be honest, there are still many things that I can do, such as more supported devices like Network, shell, and more system calls like malloc, ipc-related and so on, but I have to stop since I've spent so many time on it (really unforgettable). Toy as my xv6 looks like, I've still learned a lot about OS and system development through all these labs, and feel truly interested in them. 

Sincere thanks to TAs for their useful helps and tips.