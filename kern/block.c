#include <kern/block.h>
#include <kern/spinlock.h>
#include <kern/sleeplock.h>
#include <kern/buf.h>
#include <kern/bio.h>
#include <kern/log.h>

//There should be one superblock per disk device, but we run with only one device
struct superblock sb;

/* Read the super block.
 */
void
readsb(int dev, struct superblock *sb)
{
    struct buf *bp;
    bp = bread(dev, 1);
    memmove(sb, bp->data, sizeof(*sb));
    cprintf("%d", sb->size);
    cprintf("%d", sb->nblocks);
    brelse(bp);
}


/* Zero a block.
 */
static void
bzero(int dev, int bno)
{
    struct buf *bp;
    bp = bread(dev, bno);
    memset(bp->data, 0, BSIZE);
    log_write(bp);
    brelse(bp);
}

/* Allocate a zeroed disk block.
 * todo:
 * 1. find a free block
 * 2. mark it in use
 * 3. bzero the block
 */
static uint32_t
balloc(uint32_t dev)
{
    int i, j, mask;
    struct buf *bitmap;
    
    for (i = 0; i < sb.size; i += BPB) {
        bitmap = bread(dev, BBLOCK(i, sb));
        for (j = 0; j < BPB && i + j < sb.size; j++) {
            mask = 1 << (j % 8);
            if ((bitmap->data[j / 8] & mask) == 0) {
                bitmap->data[j / 8] |= mask;
                log_write(bitmap);
                brelse(bitmap);
                bzero(dev, i + j);
                return i + j;
            }
        }
        brelse(bitmap);
    }
    panic("Balloc: out of blocks");
}

/* Free a disk block
 * todo:
 * mark it unused
 */
static void
bfree(int dev, uint32_t b)
{
    struct buf *bitmap;
    int bi, mask;
    bitmap = bread(dev, BBLOCK(b, sb));
    bi = b % BPB;
    mask = 1 << (bi % 8);
    if ((bitmap->data[bi / 8] & mask) == 0)
        panic("freeing free block");
    bitmap->data[bi / 8] &= ~mask;
    log_write(bitmap);
    brelse(bitmap);
}
