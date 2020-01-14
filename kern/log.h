#ifndef KERN_LOG_H
#define KERN_LOG_H

#include <kern/buf.h>
void initlog(int dev);
void log_write(struct buf *b);
void begin_op(void);
void end_op(void);

#endif /* !KERN_LOG_H */