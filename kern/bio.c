// Buffer cache.
//
// The buffer cache hold cached copies of disk block contents.  
// Caching disk blocks in memory reduces the number of disk reads and also provides
// a synchronization point for disk blocks used by multiple processes.
//
// Interface:
// * To get a buffer for a particular disk block, call bread.
// * After changing buffer data, call bwrite to write it to disk.
// * When done with the buffer, call brelse.
// * Do not use the buffer after calling brelse.
// * Only one process at a time can use a buffer,
//     so do not keep them longer than necessary.
//
// The implementation uses two state flags internally:
// * B_VALID: the buffer data has been read from the disk.
// * B_DIRTY: the buffer data has been modified
//     and needs to be written to disk.

#include <kern/bio.h>
#include <kern/sleeplock.h>
#include <kern/ide.h>

/* Init the block cache
 * todo:
 * init the cache and its lock.
 * init each buf and its lock
 * let main call this function
 */
void
binit(void)
{
    struct buf *b;
    __spin_initlock(&bcache.lock, "bcache");
    bcache.head.prev = &bcache.head;
    bcache.head.next = &bcache.head;
    for (b = bcache.buf; b < bcache.buf+NBUF; b++) {
        b->next = bcache.head.next;
        b->prev = &bcache.head;
        __sleep_initlock(&b->lock, "buffer");
        bcache.head.next->prev = b;
        bcache.head.next = b;
    }
}
// Hint: Remember to get the lock, if you need change the block cache. 


/* Return a locked buffer for given sector.
 * todo:(Recommended)
 * return it in following order:
 * 1. there is such a buffer
 * 2. there is a free buffer, reuse it
 * 3. there is an unlocked and undirty buffer, reuse it
 * 4. wait for a buffer to become ready(or simply panic here)
 */
static struct buf*
bget(uint32_t dev, uint32_t blockno)
{
//     spin_lock(&bcache.lock); // TODO: need clarify why need lock here: for fear that there are some process releasing the buffer because the value refcnt set to 0
//     struct buf *b = bcache.head.next;
//     while (b != &bcache.head) {
//         if (b->dev == dev && b->blockno == blockno) {
//             b->refcnt++;
//             spin_unlock(&bcache.lock);
//             sleep_lock(&b->lock); // TODO: need clarify why need sleeplock instead of spinlock here: I/O operations need more time
//             return b;
//         }
//         b = b->next;
//     }
//     b = bcache.head.prev;
//     while (b != &bcache.head) {
//         if (b->refcnt == 0 && (b->flags & B_DIRTY) == 0) {
//             b->dev = dev;
//             b->blockno = blockno;
//             b->flags = 0;
//             b->refcnt = 1;
//             spin_unlock(&bcache.lock);
//             sleep_lock(&b->lock);
//             return b;
//         }
//         b = b->prev;
//     }
//     panic("Bget: No buffers");
  struct buf *b;

  spin_lock(&bcache.lock);

  // Is the block already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    if(b->dev == dev && b->blockno == blockno){
      b->refcnt++;
      spin_unlock(&bcache.lock);
      sleep_lock(&b->lock);
      return b;
    }
  }

  // Not cached; recycle an unused buffer.
  // Even if refcnt==0, B_DIRTY indicates a buffer is in use
  // because log.c has modified it but not yet committed it.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    if(b->refcnt == 0 && (b->flags & B_DIRTY) == 0) {
      b->dev = dev;
      b->blockno = blockno;
      b->flags = 0;
      b->refcnt = 1;
      spin_unlock(&bcache.lock);
      sleep_lock(&b->lock);
      return b;
    }
  }
  panic("bget: no buffers");
}

/* Return a locked buffer with the contents of the indicated block.
 * todo:
 * 1. get a locked buffer by calling bget.
 * 2. call iderw if necessary.
 */
struct buf*
bread(uint32_t dev, uint32_t blockno)
{
    struct buf *b;
    b = bget(dev, blockno);
    #ifdef DEBUG_BIO
    cprintf("bread: blockno: %d, flags: %d\n", b->blockno, b->flags);
    #endif
    if (!(b->flags & B_VALID))
        iderw(b);
    return b;
}

/* Write b's contents to disk.
 * todo:
 * 1. write the buffer to disk.
 */
void
bwrite(struct buf *b)
{
    if (!holdingsleep(&b->lock))
        panic("Bwrite");
    b->flags |= B_DIRTY;
    iderw(b);
}

/* Release a locked buffer.
 * todo:
 * 1. release the buffer's lock.
 */
void
brelse(struct buf *b)
{
    if (!holdingsleep(&b->lock))
        panic("brelease");
    sleep_unlock(&b->lock); // TODO: Why release at here? 
                            // TODO: Ans: I think it doesn't matter whether releasing this sleeplock within the critical section of bcachelock
    spin_lock(&bcache.lock);
    b->refcnt--;
    if (b->refcnt == 0) {
        b->next->prev = b->prev;
        b->prev->next = b->next;
        b->next = bcache.head.next;
        b->prev = &bcache.head;
        bcache.head.next->prev = b;
        bcache.head.next = b;
        // b->flags = 0;       // TODO: When to write back, why not judge if the buffer is dirty?
                               // TODO: Undirty is guaranteed by the order of invoking the functions of buffer cache eg. bread, (bwrite), brelse
    }
    spin_unlock(&bcache.lock);
}
