// Physical memory allocator, intended to allocate memory for
// user processes, kernel stacks, page table pages, and pipe
// buffers. Allocates 4096-byte pages.

#include <inc/types.h>
#include <inc/mmu.h>
#include <inc/memlayout.h>
#include <inc/error.h>
#include <inc/assert.h>
#include <inc/string.h>

#include <kern/kalloc.h>
#include <kern/console.h>
#include <kern/spinlock.h>

// First address after kernel loaded from ELF file defined by the
// kernel linker script in kernel.ld.
extern char end[];
// bitmap which indicate if the block is occupied
bool *order[2];
// the beginning of each order in the bitmap
int *start[2];
// to establish the double linked list in each Buddy.free_list, have to leave a pointer to indicate the beginning;
struct run *linkbase[2];
// the order of two buddy system
int MAX_ORDER[2];

// Free page's list element struct.
// We store each free page's run structure in the free page itself.
struct run {
	struct run *next;
};

struct {
	struct run *free_list; // Free list of physical pages
} kmem; //TODO To figure out what this mean? the beginning of free lists? 

struct Buddykmem {
	struct run *free_list;
	int num;
};

struct {
	int use_lock;
	struct Buddykmem *slot;
	struct spinlock lock;
} Buddy[2];

struct run *base[2];
//struct Buddykmem *Buddy[2];

// Initialization happens in two phases.
// 1. Call boot_alloc_init() while still using entrypgdir to place just
// the pages mapped by entrypgdir on free list.
// 2. Call alloc_init() with the rest of the physical pages after
// installing a full page table.

int pow_2(int power)
{
	int num = 1;
	for (int i = 0; i < power; i++)
		num *= 2;
	return num;
}

void
boot_alloc_init(void)
{
	// TODO: Your code here.
	int num;
	char *mystart = end;
	//cprintf("%x, %x\n", end, (char *)P2V(4*1024*1024) - end);
	for (int i = 0; i < 2; i++) {
		if (i == 0)
			num = (uint32_t)((char *)P2V(4*1024*1024) - end) / PGSIZE;
		else
			num = (uint32_t)((char *)PHYSTOP - 4*1024*1024) / PGSIZE;
		int level = 0;
		int sum = 1;
		//cprintf("num: %x\n", num);
		while (sum < num) {
			sum *= 2;
			level++;
		}
		if (sum > num) {
			sum /= 2;
			level--;
		}
		//cprintf("level: %d, mystart: %x\n", level, mystart);

		order[i] = (bool *)mystart;
		memset(order[i], 0, pow_2(level) * 2);
		mystart += pow_2(level) * 2;
		//cprintf("order, mystart: %x %x\n", order[i], mystart);

		MAX_ORDER[i] = level;

		Buddy[i].slot = (struct Buddykmem *)mystart;
		memset(Buddy[i].slot, 0, sizeof(struct Buddykmem) * (level + 1));
		mystart += sizeof(struct Buddykmem) * (level + 1);
		//cprintf("Buddy, mystart: %x %x\n", Buddy[i], mystart);

		linkbase[i] = (struct run *)mystart;
		memset(linkbase[i], 0, sizeof(struct run) *(level + 1));
		mystart += sizeof(struct run) *(level + 1);
		//cprintf("linkbase, mystart: %x %x\n", linkbase[i], mystart);

		for (int j = 0; j <= level; j++) {
			linkbase[i][j].next = &linkbase[i][j];
			//cprintf("linkbase: %x\n", &linkbase[i][j]);
			Buddy[i].slot[j].free_list = &linkbase[i][j];
			//cprintf("Buddy[%d]: %x\n", i, Buddy[i].slot[j].free_list);
		}
		start[i] = (int *)mystart;
		start[i][0] = 0;
		for (int j = 0; j < level; j++)
			start[i][j + 1] = start[i][j] + pow_2(level - j);
		mystart += sizeof(int) * (level + 1);
	}
	base[0] = (struct run *)ROUNDUP(mystart, PGSIZE);
	base[1] = (struct run *)P2V(4 * 1024 * 1024);
	//cprintf("base[0]: %x, base[1]: %x\n", base[0], base[1]);
	for (int i = 0; i < 2; i++) {
		Buddy[i].use_lock = 0;
		char *name = "Buddykmem";
		//cprintf("%s\n", name);
		__spin_initlock(&Buddy[i].lock, name);
	}	
		
	Buddyfree_range((void *)base[0], MAX_ORDER[0]);
	/*for (int i = 0; i < 2; i++)
		for (int j = 0; j <= MAX_ORDER[i]; j++)
			cprintf("%x\n", start[i][j]);*/
	/*for (int i = 0; i <= MAX_ORDER[0]; i++)
		cprintf("Buddy[%d]: %x\n", i, Buddy[0].slot[i].free_list->next);

	cprintf("After allocate a block of order 3.\n");
	char *p = Buddykalloc(3);
	for (int i = 0; i <= MAX_ORDER[0]; i++)
		cprintf("Buddy[%d]: %x\n", i, Buddy[0].slot[i].free_list->next);

	cprintf("After allocate a block of order 0.\n");
	char *q = Buddykalloc(0);
	for (int i = 0; i <= MAX_ORDER[0]; i++)
		cprintf("Buddy[%d]: %x\n", i, Buddy[0].slot[i].free_list->next);

	cprintf("After allocate a block of order 8.\n");
	char *s = Buddykalloc(8);
	for (int i = 0; i <= MAX_ORDER[0]; i++)
		cprintf("Buddy[%d]: %x\n", i, Buddy[0].slot[i].free_list->next);

	cprintf("p: %x, q: %x, s: %x\n", p, q, s);

	cprintf("After reclaiming the block of order 0.\n");
	kfree(q);
	for (int i = 0; i <= MAX_ORDER[0]; i++)
		cprintf("Buddy[%d]: %x\n", i, Buddy[0].slot[i].free_list->next);

	cprintf("After reclaiming the block of order 8.\n");
	kfree(s);
	for (int i = 0; i <= MAX_ORDER[0]; i++)
		cprintf("Buddy[%d]: %x\n", i, Buddy[0].slot[i].free_list->next);

	cprintf("After reclaiming the block of order 3.\n");
	kfree(p);
	for (int i = 0; i <= MAX_ORDER[0]; i++)
		cprintf("Buddy[%d]: %x\n", i, Buddy[0].slot[i].free_list->next);*/
	
	check_free_list();
}

void
alloc_init(void)
{
	// TODO: Your code here.
	Buddyfree_range((void *)base[1], MAX_ORDER[1]);
	for (int i = 0; i < 2; i++)
		Buddy[i].use_lock = 1;
	/*for (int i = 0; i <= MAX_ORDER[1]; i++)
		cprintf("Buddy: %x\n", Buddy[1][i].free_list->next);

	char *p = Buddykalloc(0);
	char *q = Buddykalloc(10);
	char *s = Buddykalloc(4);
	char *t = Buddykalloc(13);
	char *u = Buddykalloc(7);
	cprintf("p: %x, q: %x, s: %x\n", p, q, s);

	for (int i = 0; i <= MAX_ORDER[1]; i++)
		cprintf("Buddy: %x\n", Buddy[1][i].free_list->next);

	kfree(t);
	kfree(q);
	kfree(u);
	kfree(s);
	kfree(p);

	for (int i = 0; i <= MAX_ORDER[1]; i++)
		cprintf("Buddy: %x\n", Buddy[1][i].free_list->next);*/
	check_free_list();
}

// Free the page of physical memory pointed at by v.
void
kfree(char *v)
{
	Buddykfree(v);
	/*struct run *r;

	if ((uint32_t)v % PGSIZE || v < end || V2P(v) >= PHYSTOP)
		panic("kfree");

	// Fill with junk to catch dangling refs.
	memset(v, 1, PGSIZE);

	r = (struct run *)v;
	r->next = kmem.free_list;
	kmem.free_list = r;*/
}

void
Buddykfree(char *v)
{
	struct run *r;

	if ((uint32_t)v % PGSIZE || v < end || V2P(v) >= PHYSTOP)
		panic("kfree");
	int idx, id;
	id = (void *)v >= (void *)base[1];
	//cprintf("minus: %x, num: %x,idx: %x\n", (void *)v - (void *)base[0], (uint32_t)((void *)v - (void *)base[0]) / PGSIZE, idx);
	idx = (uint32_t)((void *)v - (void *)base[id]) / PGSIZE;
	int p = idx;
	int count = 0;
	//cprintf("v: %x, idx: %x, p: %x\n", v, idx, p);
	if (Buddy[id].use_lock)
		spin_lock(&Buddy[id].lock);
	while (order[id][p] != 1) {
		count++;
		p = start[id][count] + (idx >> count);
	}
	//cprintf("p: %x\n", p);
	memset(v, 1, PGSIZE * pow_2(count));
	order[id][p] = 0;
	int buddy = p ^ 1;
	int mark = 1 << (count + 12);
	char *buddypos;
	while (count < MAX_ORDER[id] && order[id][buddy] == 0) {
		//cprintf("p: %x, buddy: %x\n", p, buddy);
		buddypos = (char *)base[id] + ((uint32_t)(v - (char *)base[id]) ^ mark);
		//cprintf("buddypos: %x, mark: %x\n", buddypos, mark);
		struct run *iter = Buddy[id].slot[count].free_list;
		while (iter->next != (struct run *)buddypos && iter->next != Buddy[id].slot[count].free_list)
			iter = iter->next;
		// buddy is occupied
		// have little change
		//if (iter->next != (struct run *)buddypos)
		//	break;
		struct run *uni = iter->next;
		iter->next = uni->next;
		Buddy[id].slot[count].num--;
		Buddy[id].slot[count].free_list = iter->next;
		v = (v > (char *)uni) ? (char *)uni : v;
		count++;
		mark <<= 1;
		p = start[id][count] + (idx >> count);
		//cprintf("order: %d, p: %x\n", order[id][p], p);
		order[id][p] = 0;
		//cprintf("order: %d\n", order[id][p]);
		buddy = p ^ 1;
	}
	r = (struct run *)v;
	r->next = Buddy[id].slot[count].free_list->next;
	Buddy[id].slot[count].free_list->next = r;
	Buddy[id].slot[count].num++;
	if (Buddy[id].use_lock)
		spin_unlock(&Buddy[id].lock);
}

void
free_range(void *vstart, void *vend)
{
	char *p;
	p = ROUNDUP((char *)vstart, PGSIZE);
	for (; p + PGSIZE <= (char *)vend; p += PGSIZE)
		kfree(p);
}

void
Buddyfree_range(void *vstart, int level)
{
	struct run *r;
	int id = ((void *)vstart >= (void *)base[1]) ? 1 : 0;

	memset(vstart, 1, PGSIZE * pow_2(level));
	r = (struct run *)vstart;
	//cprintf("%x, %x\n", Buddy[id][level].free_list->next, Buddy[id][level].free_list);
	r->next = Buddy[id].slot[level].free_list->next;
	Buddy[id].slot[level].free_list->next = r;
	//cprintf("%x, %x\n", Buddy[id][level].free_list->next, Buddy[id][level].free_list);
	Buddy[id].slot[level].num++;
}

// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char *
kalloc(void) // Why char *?
{
	// TODO: Your code here.
	return Buddykalloc(0);
	/*if (kmem.free_list) {
		struct run *r;
		r = kmem.free_list;
		kmem.free_list = kmem.free_list->next;
		//return r;
		return (char *)r; //TODO
	} else 
		return NULL;*/
}

void
split(char *r, int low, int high)
{
	int size = 1 << high;
	int id, idx;
	id = (void *)r >= (void *)base[1];
	idx = (uint32_t)((void *)r - (void *)base[id]) / PGSIZE;
	//cprintf("%x\n", r);
	while (high > low) {
		//cprintf("pos: %x, high: %d\n", start[id][high] + (idx >> high), high);
		order[id][start[id][high] + (idx >> high)] = 1;
		//cprintf("high: %x, pos: %x\n", high, start[high] + (idx >> high));
		high--;
		size >>= 1;
		struct run *p = (struct run *)((uint32_t)r + PGSIZE * size);
		//add high
		p->next = Buddy[id].slot[high].free_list->next;
		Buddy[id].slot[high].free_list->next = p;
		Buddy[id].slot[high].num++;
	}
	order[id][start[id][high] + (idx >> high)] = 1;
	//cprintf("pos: %x\n", start[id][high] + (idx >> high));
}

char *
Buddykalloc(int order)
{
	for (int i = 0; i < 2; i++) {
		if (Buddy[i].use_lock)
			spin_lock(&Buddy[i].lock);
		for (int currentorder = order; currentorder <= MAX_ORDER[i]; currentorder++)
			if (Buddy[i].slot[currentorder].num > 0) {
				struct run *r;
				r = Buddy[i].slot[currentorder].free_list->next;
				Buddy[i].slot[currentorder].free_list->next = r->next;
				Buddy[i].slot[currentorder].num--;
				//cprintf("%d\n", currentorder);
				split((char *)r, order, currentorder);
				if (Buddy[i].use_lock)
					spin_unlock(&Buddy[i].lock);
				return (char *)r;
			}
		if (Buddy[i].use_lock)
			spin_unlock(&Buddy[i].lock);
	}
	return NULL;
}
// --------------------------------------------------------------
// Checking functions.
// --------------------------------------------------------------

//
// Check that the pages on the kmem.free_list are reasonable.
// TODO: There is only a simple test code here.
// 		 Please add more test code.
//
void
check_free_list(void)
{
	struct run *p;
	bool exist;
	for (int i = 0; i < 2; i++)
		for (int j = 0; j <= MAX_ORDER[i]; j++)
			if(Buddy[i].slot[j].free_list)
				exist = true;
	if (!exist)
		panic("'Buddykmem.free_list' is a null pointer!");

	//cprintf("end: 0x%x\n", end);

	for (p = kmem.free_list; p; p = p->next) {
		//cprintf("0x%x\n", p);
		assert((void *)p > (void *)end);
		for (int i = 4; i < 4096; i++) 
			assert(((char *)p)[i] == 1);
	}
}
