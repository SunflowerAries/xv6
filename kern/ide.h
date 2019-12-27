#ifndef KERN_IDE_H
#define KERN_IDE_H

#include <kern/buf.h>

void ide_init(void);
void ide_intr(void);
void iderw(struct buf *b);

#endif