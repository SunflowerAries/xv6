#include <kern/sleeplock.h>
#include <kern/proc.h>

static void
sleepingQueueAdd(struct sleeping_queue *queue, struct sleepnode *p)
{
    p->next = NULL;
    // cprintf("before add head: %u, head->next: %u, tail: %u, p: %u\n", queue->head, queue->head == NULL ? NULL : queue->head->next, queue->tail, p);
    if (queue->head == NULL)
        queue->tail = queue->head = p;
    else {
        queue->tail->next = p;
        queue->tail = queue->tail->next;
    }
    // cprintf("after add head: %u, head->next: %u, tail: %u\n", queue->head, queue->head == NULL ? NULL : queue->head->next, queue->tail);
}

static struct sleepnode*
sleepingQueueRemove(struct sleeping_queue *queue)
{
    struct sleepnode *p;
    // cprintf("before remove head: %u, head->next: %u, tail: %u\n", queue->head, queue->head == NULL ? NULL : queue->head->next, queue->tail);
    if (queue->head == NULL)
        panic("sleeping remove");
    if (queue->tail == queue->head)
        queue->head = queue->tail = NULL;
    else {
        p = queue->head;
        p->next = NULL;
        queue->head = queue->head->next;
    }
    // cprintf("after remove head: %u, head->next: %u, tail: %u\n", queue->head, queue->head == NULL ? NULL : queue->head->next, queue->tail);
    return queue->head;
}

void
__sleep_initlock(struct sleeplock *lk, char *name)
{
    __spin_initlock(&lk->lk, "sleep lock");
    lk->locked = 0;
    lk->name = name;
    lk->pid = 0;
}

void
sleep_lock(struct sleeplock *lk)
{
    spin_lock(&lk->lk);
    struct sleepnode p;
    p.pid = thisproc()->pid;
    sleepingQueueAdd(&lk->queue, &p);
    while (lk->locked)
        sleep(&p, &lk->lk);
    lk->locked = 1;
    lk->pid = p.pid;
    spin_unlock(&lk->lk);
}

void
sleep_unlock(struct sleeplock *lk)
{
    spin_lock(&lk->lk);
    lk->locked = 0;
    lk->pid = 0;
    struct sleepnode *p = NULL;
    p = sleepingQueueRemove(&lk->queue);
    if (p != NULL)
        wakeup(p);
    spin_unlock(&lk->lk);
}

bool
holdingsleep(struct sleeplock *lk)
{
    int r;
    spin_lock(&lk->lk);
    // cprintf("cpu: %u, lock: %d\n", lk->lk.cpu, lk->lk.locked);
    r = lk->locked && (lk->pid == thisproc()->pid);
    spin_unlock(&lk->lk);
    return r;
}