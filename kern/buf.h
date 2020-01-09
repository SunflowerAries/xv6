#ifndef KERN_BUF_H
#define KERN_BUF_H

#include <inc/types.h>
#include <kern/sleeplock.h>

#define ROOTDEV 0
#define BSIZE 512

struct buf {
  int32_t flags;
  uint32_t dev;
  uint32_t blockno;
  struct sleeplock lock;
  uint8_t refcnt;
  //TODO: a queue or other data structure to manage buf
  struct buf *next;
  struct buf *prev;
  struct buf *Qnext;
  uint8_t data[BSIZE];
};

struct ide_queue {
  struct buf *head;
  struct buf *tail;
};

#define B_VALID 0x2  // buffer has been read from disk
#define B_DIRTY 0x4  // buffer needs to be written to disk

#endif /* !KERN_BUF_H */