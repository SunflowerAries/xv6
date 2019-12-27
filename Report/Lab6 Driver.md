# <center>Lab6 Driver</center>

[toc]

## Buf.h

In this file, we've defined the size of buffer, added a field *next* to struct *buf*, which helps to deal with the request of I/O workload, and a struct *ide_queue*, which can help us insert new requests into the request list more quickly.

```c
struct ide_queue {
  struct buf *head;
  struct buf *tail;
};
```

## Ide.c

### Ide_init

In this function, we need initialize all the things needed for an I/O request, for example, the initialization of *ide_lock*, checking whether disk 1 is available. we need call **ide_wait** to wait for the disk to be able to accept commands, and then switch to another disk to check if it's available. As the Drive / Head Register below suggests, we first rewrite the fourth bit and then poll 1000 times on I/O port 0x1f7 which presents the status of disk hardware until it's ready, otherwise just assume we do not have disk 1.

```c 
outb(0x1f6, 0xe0 | (1 << 4));
for (int i = 0; i < 1000; i++) {
    if (inb(0x1f7) & IDE_DRDY) {
        havedisk1 = 1;
        break;
    }
}
outb(0x1f6, 0xe0);
```

Drive / Head Register (I/O base + 6)

| 7 | 6 | 5 | 4 | 3-0 |
| :--: | :--:| :--: | :--: | :--: |
| 1 | LBA | 1 | DRV |  |
| Always set | clear(CHS)  set(LBA) | Always set | drive number | CHS: bits 0 to 3 of the head. LBA: bits 24 to 27 of the block number. |

Status Register (I/O base + 7)

| 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
| :--: | :-- : | :--: | :--: | :--: | :--: | :--: | :--: |
| BSY | RDY | DF | SRV | DRQ | CORR | IDX | ERR |
### Ide_wait

In this function, we need to wait until the hardware is ready by continuously reading from the status bits (0x1f7). And then, if needed, we can check if there are some errors.

### Ide_rw

After finishing initialization, we can begin I/O operations. Since there can be several processes requesting for I/O at the same time, we need to ensure the atomicity of operation on buffer. And after checking if the buffer works well, then acquire *ide_lock* and there we added a function **ideQueueAdd** to add the newly-coming request to the end of the request queue. And disk will only resolve request at the head of the queue, while others sleep. If the newly-added request is the head of queue, we can just call **ide_start** to start the I/O operation or make the request sleep on itself.

### Ide_start

In this function, we need read or write to block from disk. According to the table below, we can easily fulfill the work.

| 0x1f0 | 0x1f1 | 0x1f2 | 0x1f3 | 0x1f4 | 0x1f5 | 0x1f6 | 0x1f7 |
| :--: | :--: | :--: | :--: | :--: | :--: | :--: | :--: |
| Data Register | Error Register | Sector Count Register | Sector Number Register (LBAlo) | Cylinder Low Register (LBAmid) | Cylinder High Register (LBAhi) | Drive/Head Register | Status Register / Command Register |

### Ide_intr

Every time when disk finishes the operation on buffer, it will send a signal to inform kernel, then we will call **ide_intr** in the **trap** handler. Here, since there may be some processes requesting I/O operations sleeping on the queue, we first acquire *ide_lock* to refresh the buffer at the head of queue and wakeup the process, and then schedule next process, if exists, to start I/O operation. And finally release *ide_lock*.