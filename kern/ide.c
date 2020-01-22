// Simple PIO-based (non-DMA) IDE driver code.

// TODO: include any files you need
#include <inc/types.h>
#include <inc/traps.h>
#include <inc/x86.h>
#include <inc/assert.h>
#include <kern/ide.h>
#include <kern/cpu.h>
#include <kern/ioapic.h>
#include <kern/proc.h>
#include <kern/spinlock.h>

#define SECTOR_SIZE 512

#define IDE_BSY 0x80
#define IDE_DRDY 0x40
#define IDE_DF 0x20
#define IDE_ERR 0x01

#define IDE_CMD_READ 0x20
#define IDE_CMD_WRITE 0x30
#define IDE_CMD_RDMUL 0xc4
#define IDE_CMD_WRMUL 0xc5

// You must hold ide_lock while manipulating queue.
static struct spinlock ide_lock;
static struct ide_queue ide_queue;

static int havedisk1;
extern int ncpu;

static void
ideQueueAdd(struct ide_queue *queue, struct buf *b)
{
    if (queue->head == NULL)
        queue->tail = queue->head = b;
    else {
        queue->tail->Qnext = b;
        queue->tail = b;
    }
    b->Qnext = NULL;
}

static struct buf*
ideQueueRemove(struct ide_queue *queue)
{
    if (queue->head == NULL)
        panic("Queue: Empty.");
    if (queue->tail == queue->head)
        queue->head = queue->tail = NULL;
    else
        queue->head = queue->head->Qnext;
    return queue->head;
}

/* Busy Wait for IDE disk to become ready.
 * todo:
 * poll the status bits(status register) until the busy bit is clear and the ready bit is set.
 * check if IDE disk is error when checkkerr is set.
 * return value:
 * if checkerr is set: return -1 when IDE disk is error, return 0 otherwise.
 * else return 0 all the time.
 * Hint:
 * 1. you may use inb or insl to get data from I/O Port.
 * 2. Infomation about the status register can be found in ATA_PIO_Mode on https://osdev.org
 * 3. here are some MARCO you may need: IDE_* (IDE_CMD_* is not included)
 */
static int
ide_wait(int checkerr)
{
    uint8_t r;
    while (((r = inb(0x1f7)) & (IDE_DRDY | IDE_BSY)) != IDE_DRDY);
    if (checkerr && ((r & (IDE_ERR | IDE_DF)) != 0))
        return -1;
    return 0;
}

/* Init IDE disk driver, and check if you have disk 1.
 * todo: 
 * wait for IDE disk ready
 * Switch to disk 1 (use Drive/Head Register)
 * Check if disk 1 is present (poll Status Register for 1000 times, see if it responds)
 * Set havedisk1 if disk 1 is present
 * Switch back to disk 0
 * Hint:
 * 1. you may use outb or outsl to send data to I/O Port.
 * 2. Infomation about Drive/Head Register and Status Register can be found in ATA_PIO_Mode on https://osdev.org
 */
void
ide_init(void)
{
    //init the lock and pic first.
    __spin_initlock(&ide_lock, "ide");
    ioapicenable(IRQ_IDE, ncpu - 1);
    // ioapicenable(IRQ_IDE, 0);

    //todo: your code here.
    if (ide_wait(1) < 0)
        panic("ide_wait in ide_init");
    outb(0x1f6, 0xe0 | (1 << 4));
    for (int i = 0; i < 1000; i++) {
        if (inb(0x1f7) != 0) {
            havedisk1 = 1;
            break;
        }
    }
    outb(0x1f6, 0xe0 | (0 << 4));
}

/* Start the request for b. Caller must hold ide_lock.
 * todo:
 * start a read/write request for buf b on disk device correctly according to buf b
 * Hint:
 * 1. Information can be found in ATA_PIO_Mode and ATA_Command_Matrix on https://osdev.org
 * 2. here are some MARCO you may need: IDE_CMD_* SECTOR_SIZE and BSIZE(define in fs.h) 
 * 3. notice the difference between Block size and Sector size
 * 4. write the data here if you need, but read the data when you get the interrupt(not here).
 * 5. inb insl outb and outsl might be used
 */
static void
ide_start(struct buf *b)
{
    //todo: your code here.
    if (b == NULL)
        panic("ide_start");
    int sector_per_block = BSIZE / SECTOR_SIZE;
    int sector = sector_per_block * b->blockno;
    int read_cmd = (sector_per_block == 1) ? IDE_CMD_READ : IDE_CMD_RDMUL;
    int write_cmd = (sector_per_block == 1) ? IDE_CMD_WRITE : IDE_CMD_WRMUL;
    if (ide_wait(1) < 0)
        panic("ide_wait in ide_start");
    outb(0x3f6, 0);
    outb(0x1f2, sector_per_block);
    outb(0x1f3, sector & 0xff);
    outb(0x1f4, (sector >> 8) & 0xff);
    outb(0x1f5, (sector >> 16) & 0xff);
    outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((sector>>24)&0x0f));
    if (b->flags & B_DIRTY) {
        outb(0x1f7, write_cmd);
        outsl(0x1f0, b->data, BSIZE / 4);
    } else 
        outb(0x1f7, read_cmd);
}

/* Interrupt handler.
 * todo:
 * IMPORTANT: get the ide_lock at first!
 * read data here if you need
 * update the buf's flag
 * wake up the process waiting for this buf
 * start the right ide request
 * IMPORTANT: release the ide_lock!
 * Hint:
 * 1. you may use idequeue to manage all the ide request
 * 2. in challenge problem, you should start the right ide request according to your algorithm, while the next ide request in normal problem.
 */
void
ide_intr(void)
{
    spin_lock(&ide_lock);
    struct buf *b = ide_queue.head;
    if (b == NULL) {
        spin_unlock(&ide_lock);
        return;
    }
    if (!(b->flags & B_DIRTY) && ide_wait(1) >= 0)
        insl(0x1f0, b->data, BSIZE / 4);
    b->flags |= B_VALID;
    b->flags &= ~B_DIRTY;
    cprintf("Clear flags.\n");
    wakeup(b);
    if ((b = ideQueueRemove(&ide_queue)))
        ide_start(b);
    spin_unlock(&ide_lock);
}

/* Sync buf b with disk.(in another word:ide request)
 * If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
 * Else if B_VALID is not set, read buf from disk, set B_VALID.
 * todo:
 * IMPORTANT: get the ide_lock at first!
 * append b to idequeue
 * start this request if idequeue is empty before
 * wait for ide request to finish sleeplock may be suitable.
 * IMPORTANT:Release the lock
 * Hint:
 * 1.busy wait or spin-lock may be not suitable,you may need implement sleeplock
 */
void
iderw(struct buf *b)
{
    // TODO
    if(!holdingsleep(&b->lock))
        panic("iderw: buf not locked");
    if ((b->flags & (B_DIRTY | B_VALID)) == B_VALID)
        panic("iderw: nothing to do");
    if (b->dev && !havedisk1)
        panic("iderw: ide disk 1 not avaible");
    spin_lock(&ide_lock);
    ideQueueAdd(&ide_queue, b);
    if (b == ide_queue.head)
        ide_start(b);
    while ((b->flags & (B_VALID | B_DIRTY)) != B_VALID)
        sleep(b, &ide_lock);
    spin_unlock(&ide_lock);
}
