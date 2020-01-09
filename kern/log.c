#include <inc/types.h>
#include <inc/assert.h>
#include <inc/string.h>
#include <kern/bio.h>
#include <kern/log.h>
#include <kern/block.h>
#include <kern/spinlock.h>
#include <kern/sleeplock.h>
#include <kern/buf.h>
#include <kern/proc.h>

// Simple logging that allows concurrent FS system calls.
//
// A log transaction contains the updates of multiple FS system
// calls. The logging system only commits when there are
// no FS system calls active. Thus there is never
// any reasoning required about whether a commit might
// write an uncommitted system call's updates to disk.
//
// A system call should call begin_op()/end_op() to mark
// its start and end. Usually begin_op() just increments
// the count of in-progress FS system calls and returns.
// But if it thinks the log is close to running out, it
// sleeps until the last outstanding end_op() commits.
//
// The log is a physical re-do log containing disk blocks.
// The on-disk log format:
//   header block, containing block #s for block A, B, C, ...
//   block A
//   block B
//   block C
//   ...
// Log appends are synchronous.

// Contents of the header block, used for both the on-disk header block
// and to keep track in memory of logged block# before commit.
struct logheader {
  int n;
  int block[LOGSIZE];
};

struct log {
  struct spinlock lock;
  int start;
  int size;
  int outstanding; // how many FS sys calls are executing.
  int committing;  // in commit(), please wait.
  int dev;
  struct logheader lh;
};
struct log log;

static void recover_from_log(void);
static void commit(void);

/* Init struct log.
 * todo:
 * 1. init struct log according to superblock
 * 2. recover from log after log's initialization
 */
void
initlog(int dev)
{
  if (sizeof(struct logheader) > BSIZE) // TODO: Logheader has to resides on a single block
    panic("Initlog: too big logheader");
  
  struct superblock sb;
  readsb(dev, &sb);
  __spin_initlock(&log.lock, "log");
  log.start = sb.logstart;
  log.size = sb.nlog;
  log.dev = dev;
  recover_from_log();
}

/* Copy committed blocks from log to their destination
 * Be careful about the order of block release
 */
static void
install_trans(void)
{
  int tail;
  for (tail = 0; tail < log.lh.n; tail++) {
    struct buf *logbuf = bread(log.dev, log.start + tail + 1);
    struct buf *dstbuf = bread(log.dev, log.lh.block[tail]);
    memmove(dstbuf->data, logbuf->data, BSIZE);
    bwrite(dstbuf);
    brelse(dstbuf);
    brelse(logbuf);
  }
}

/* Read the log header from disk into the in-memory log header
 */
static void
read_head(void)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
  for (i = 0; i < log.lh.n; i++)
    log.lh.block[i] = lh->block[i];
  brelse(buf);
}

/* Write in-memory log header to disk.
 */
static void
write_head(void)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
  for (i = 0; i < log.lh.n; i++) {
    hb->block[i] = log.lh.block[i];
  }
  bwrite(buf);
  brelse(buf);
}

/* Recover from log which must be consistent with commit
 * todo:
 * 1. read the log header
 * 2. copy committed blocks from log
 * 3. set the count in head to zero
 * 4. write the log header
 */
static void
recover_from_log(void)
{
  read_head();
  install_trans();
  log.lh.n = 0;
  write_head();
}

/* called at the start of each FS system call.
 * means that it join current transaction
 * todo:
 * 1. wait if it is committing now or not enough space for this op
 * 2. increase the count simply
 */
void
begin_op(void)
{
  spin_lock(&log.lock);
  while (1) {
    if (log.committing)
      sleep(&log, &log.lock);
    else if (log.lh.n + (log.outstanding + 1) * MAXOPBLOCKS > LOGSIZE) // TODO: why log.lh.n + log.outstanding ?
      sleep(&log, &log.lock);
    else {
      log.outstanding += 1;
      spin_unlock(&log.lock);
      break;
    }
  }
}

/* called at the end of each FS system call.
 * means that it leave current transaction but this op may not be commited immediately
 * todo:
 * 1. decrease the count
 * 2. commits if this was the last outstanding operation.
 * Hint:
 * 1. you should call commit without holding locks, since not allowed to sleep with locks
 * 2. however changing log.committing should hold locks.
 */
void
end_op(void)
{
  bool do_commit = false;

  spin_lock(&log.lock);
  log.outstanding -= 1;
  if (log.committing)
    panic("End_op: log_commiting");
  if (log.outstanding == 0) {
    do_commit = true;
    log.committing = 1;
  } else
    wakeup(&log); // TODO: Wakeup process waiting for begin_op but when to add to logheader ?
  spin_unlock(&log.lock);

  if (do_commit) {
    commit();
    spin_lock(&log.lock);
    log.committing = 0;
    wakeup(&log);
    spin_unlock(&log.lock);
  }
}

/* Copy modified blocks from cache to log.
 */
static void
write_log(void)
{
  int tail;
  for (tail = 0; tail < log.lh.n; tail++) {
    struct buf *to = bread(log.dev, log.start + tail + 1); // TODO: log.start+tail = header block
    struct buf *from = bread(log.dev, log.lh.block[tail]);
    memmove(to->data, from->data, BSIZE);
    bwrite(to);
    brelse(to);
    brelse(from);
  }
}

/* Commit the transaction in four steps
 * todo:
 * 1. write modified blocks from cache to log
 * 2. write log header to disk -- the real commit
 * 3. write modified blocks from log to cache
 * 4. set the count in header to zero -- Erase the transaction from the log
 */
static void
commit(void)
{
  if (log.lh.n > 0) {
    write_log();
    write_head();
    install_trans();
    log.lh.n = 0;         // TODO: Others are all blocked due to committing == 1
    write_head();         // TODO: Refresh the logheader.n
  }
}

/* log_write acts as a proxy for bwrite.
 * we assume that caller has modified b->data and is done with the buffer
 * we only record the block number and pin in the cache with B_DIRTY
 * commit()/write_log() will do the disk write.
 *
 * a typical use is:
 *   bp = bread(...)
 *   modify bp->data[]
 *   log_write(bp)
 *   brelse(bp)
 * 
 * todo:
 * 1. find if the buffer is already in the list of the blockno of modified buffer.
 * 2. if not append the blockno to the list
 * 3. set flag with B_DIRTY to prevent eviction
 */
void
log_write(struct buf *b)
{
  int i;
  spin_lock(&log.lock);
  
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size)
    panic("too big a transaction");
  
  for (i = 0; i < log.lh.n; i++)
    if (log.lh.block[i] == b->blockno)
      break;

  if (i == log.lh.n) {
    log.lh.block[i] = b->blockno;
    log.lh.n++;
  }
  spin_unlock(&log.lock);
  b->flags |= B_DIRTY;
}

