#include <inc/types.h>
#include <inc/x86.h>
#include <inc/mmu.h>
#include <inc/string.h>
#include <inc/memlayout.h>
#include <inc/error.h>
#include <inc/assert.h>

#include <kern/vm.h>
#include <kern/kalloc.h>
#include <kern/console.h>
#include <kern/proc.h>
#include <kern/cpu.h>

// Defined by kern/kernel.ld.
extern char data[];
// Kernel's page table directory.
pde_t *kpgdir;
// GDT.
struct segdesc gdt[NSEGS];

void
seg_init(void)
{
	// Map "logical" addresses to virtual addresses using identity map.
	// Cannot share a CODE descriptor for both kernel and user
	// because it would have to have DPL_USR, but the CPU forbids
	// an interrupt from CPL=0 to DPL=3.
	// Your code here.
	//
	thiscpu->gdt[SEG_KCODE] = SEG(STA_R | STA_X, 0, 0xffffffff, 0);
	thiscpu->gdt[SEG_KDATA] = SEG(STA_W | STA_R, 0, 0xffffffff, 0);
	thiscpu->gdt[SEG_UCODE] = SEG(STA_R | STA_X, 0, 0xffffffff, DPL_USER);
	thiscpu->gdt[SEG_UDATA] = SEG(STA_R | STA_W, 0, 0xffffffff, DPL_USER);
	lgdt(thiscpu->gdt, sizeof(thiscpu->gdt));
	// Hints:
	// 1. You should set up at least four segments: kern code, kern data,
	// user code, user data;
	// 2. The various segment selectors, application segment type bits and
	// User DPL have been defined in inc/mmu.h;
	// 3. You may need macro SEG() to set up segments;
	// 4. We have implememted the C function lgdt() in inc/x86.h;
}

// Given 'pgdir', a pointer to a page directory, pgdir_walk returns
// a pointer to the page table entry (PTE) for linear address 'va'.
// This requires walking the two-level page table structure.
//
// The relevant page table page might not exist yet.
// If this is true, and alloc == false, then pgdir_walk returns NULL.
// Otherwise, pgdir_walk allocates a new page table page with kalloc.
// 		- If the allocation fails, pgdir_walk returns NULL.
// 		- Otherwise, the new page is cleared, and pgdir_walk returns
// a pointer into the new page table page.
//
// Hint 1: the x86 MMU checks permission bits in both the page directory
// and the page table, so it's safe to leave permissions in the page
// directory more permissive than strictly necessary.
//
// Hint 2: look at inc/mmu.h for useful macros that manipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int32_t alloc)
{
	// TODO: Fill this function in
	pde_t *pde = &pgdir[PDX(va)];
	pte_t *pgtab;
	if ((*pde & PTE_P) == 1)
	    pgtab = (pte_t *)P2V(PTE_ADDR(*pde));
	else {
	    if (alloc == 0 || (pgtab = (pte_t *)kalloc()) == NULL)
	        return NULL;
	    memset(pgtab, 0, PGSIZE);
        *pde = V2P(pgtab) | PTE_P | PTE_U | PTE_W;
	}
	return &pgtab[PTX(va)];
}

// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might **NOT**
// be page-aligned.
// Use permission bits perm|PTE_P for the entries.
//
// Hint: the TA solution uses pgdir_walk
static int // What to return?
map_region(pde_t *pgdir, void *va, uint32_t size, uint32_t pa, int32_t perm)
{
	// TODO: Fill this function in
	char *align = ROUNDUP(va, PGSIZE);
	uint32_t alignsize = ROUNDUP(size, PGSIZE);
	while (alignsize) {
		pte_t *pte = pgdir_walk(pgdir, align, 1);
		if (pte == NULL)
			return -1;
		*pte = pa | perm | PTE_P;
		alignsize -= PGSIZE;
		pa += PGSIZE;
		align += PGSIZE;
	} 
	return 0;
}

int
loaduvm(pde_t *pgdir, char *addr, struct Proghdr *ph, char *binary)
{
	pte_t *pte;
	void *dst;
	void *src = ph->p_offset + (void *)binary;
	uint32_t sz = ph->p_filesz;
	if ((pte = pgdir_walk(pgdir, addr, 0)) == 0)
		return -1;
	dst = P2V(PTE_ADDR(*pte));
	
	uint32_t offset = (uint32_t)addr & 0xFFF;
	dst += offset;
	uint32_t n = PGSIZE - offset;
	memmove(dst, src, n);
	src += n;
	for (uint32_t i = n; i < sz; i += PGSIZE) {
		if ((pte = pgdir_walk(pgdir, addr + i, 0)) == 0)
			return -1;
		dst = P2V(PTE_ADDR(*pte));
		if (sz - i < PGSIZE)
			n = sz - i;
		else 
			n = PGSIZE;
		memmove(dst, src, n);
		src += n;
	}
	return 0;
}

// This table defines the kernel's mappings, which are present in
// every process's page table.
// The example code here marks all physical as writable.
// However this is not truly the case.
// kvm_init() should set up page table like this:
//
//	KERNBASE..KERNBASE+EXTMEM: mapped to 0..EXTMEM
// 									(for I/O space)
// 	KERNBASE+EXTMEM..data: mapped to EXTMEM..V2P(data)
//					for the kernel's instructions and r/o data
// 	data..KERNBASE+PHYSTOP: mapped to V2P(data)..PHYSTOP,
//					rw data + free physical memory
//  DEVSPACE..0: mapped direct (devices such as ioapic)
static struct kmap {
	void *virt;
	uint32_t phys_start;
	uint32_t phys_end;
	int perm;
} kmap[] = {
	// TODO: Modify the code to reflect the above.
	{ (void *)KERNBASE, 0, EXTMEM, PTE_W}, // I/O space
	{ (void *)KERNBASE + EXTMEM, EXTMEM, V2P(data), 0}, // ro data
	{ (void *)data, V2P(data), PHYSTOP, PTE_W}, // rw data + free physical memory
	{ (void *)DEVSPACE, DEVSPACE, 0, PTE_W}, // devices
};

// Set up kernel part of a page table.
// Return a pointer of the page table.
// Return 0 on failure.
//
// In general, you need to do the following things:
// 		1. kalloc() memory for page table;
// 		2. use map_region() to create corresponding PTEs
//			for each item of kmap[];
//
// Hint: You may need ARRAY_SIZE.
pde_t *
kvm_init(void)
{
	// TODO: your code here
	pde_t *pgdirinit = (pde_t *)kalloc();
	if (pgdirinit) {
	    memset(pgdirinit, 0, PGSIZE);
		for (int i = 0; i < ARRAY_SIZE(kmap); i++)
			if (map_region(pgdirinit, kmap[i].virt, kmap[i].phys_end - kmap[i].phys_start, kmap[i].phys_start, kmap[i].perm) < 0) {
                //cprintf("The %dth is wrong.\n", i);
				kfree((char *)pgdirinit);
                return 0;
			}
		return pgdirinit;
	} else
		return 0;
}

// Switch h/w page table register to the kernel-only page table.
void
kvm_switch(void)
{
	lcr3(V2P(kpgdir)); // switch to the kernel page table
}

void
check_vm(pde_t *pgdir)
{
	for (int i = 0; i < ARRAY_SIZE(kmap); i++) {
		char *align = ROUNDUP(kmap[i].virt, PGSIZE);
		uint32_t alignsize = ROUNDUP(kmap[i].phys_end - kmap[i].phys_start, PGSIZE);
		uint32_t pa = kmap[i].phys_start;
		while(alignsize) {
			pte_t *pte = pgdir_walk(pgdir, align, 1);
			if (pte == NULL) 
				panic("vm_fail: Do not find the page table entry");
			pte_t tmp = (*pte >> 12) << 12;
			assert(tmp == pa);
			align += PGSIZE;
			pa += PGSIZE;
			alignsize -= PGSIZE;
		}
	}
}

// Allocate one page table for the machine for the kernel address
// space.
void
vm_init(void)
{
	kpgdir = kvm_init();
	if (kpgdir == 0)
		panic("vm_init: failure");
	check_vm(kpgdir);
	kvm_switch();
}

// Free a page table.
//
// Hint: You need to free all existing PTEs for this pgdir.
void
vm_free(pde_t *pgdir)
{
	// TODO: your code here
	for (int i = 0; i < 1024; i++) {
	    if (pgdir[i] & PTE_P) {
	        char *v = P2V((pgdir[i] >> 12) << 12);
	        kfree(v);
	    }
	}
	kfree((char *)pgdir);
}

// Copy parent process's page table to its children
pde_t *
copyuvm(pde_t *pgdir)
{
	pde_t *child_pgdir;
	pte_t *pte;
	uint32_t pa, flags;
	char *page;
	if ((child_pgdir = kvm_init()) == 0)
		return NULL;
	for (uint32_t i = 0; i < USTACKTOP; i += PGSIZE) {
		if ((pte = pgdir_walk(pgdir, (void *)i, 0)) == NULL)
			continue;
		if (*pte & PTE_P) {
			pa = PTE_ADDR(*pte);
			flags = PTE_FLAGS(*pte);
			if ((page = kalloc()) == NULL) {
				vm_free(child_pgdir);
				return NULL;
			}
			memmove(page, P2V(pa), PGSIZE);
			if (map_region(child_pgdir, (void *)i, PGSIZE, V2P(page), flags) < 0) {
				kfree(page);
				vm_free(child_pgdir);
				return NULL;
			}
		}
	}
	return child_pgdir;
}

//
// Allocate len bytes of physical memory for proc,
// and map it at virtual address va in the proc's address space.
// Does not zero or otherwise initialize the mapped pages in any way.
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
void
region_alloc(struct proc *p, void *va, size_t len)
{
	// TODO: Your code here.
	// (But only if you need it for ucode_load.)
	//
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	char *begin = ROUNDDOWN(va, PGSIZE);
	uint32_t size = ROUNDUP(len, PGSIZE);
	while (size) {
		char *page = kalloc();
		memset(page, 0, PGSIZE);
		if (map_region(p->pgdir, begin, PGSIZE, V2P(page), PTE_W | PTE_U) < 0)
			panic("Map space for user process.");
		begin += PGSIZE;
		size -= PGSIZE;
	}
}

void
pushcli(void)
{
	int32_t eflags;

	eflags = read_eflags();
	cli();
	if (thiscpu->ncli == 0)
		thiscpu->intena = eflags & FL_IF;
	thiscpu->ncli += 1;
	// cprintf("%x in push ncli: %d\n", thiscpu, thiscpu->ncli);
}

void
popcli(void)
{
	if (read_eflags() & FL_IF)
		panic("popcli - interruptible");
	// cprintf("%x in pop ncli: %d\n", thiscpu, thiscpu->ncli);
	if (--thiscpu->ncli < 0)
		panic("popcli");
	
	if (thiscpu->ncli == 0 && thiscpu->intena)
		sti();
}

//
// Switch TSS and h/w page table to correspond to process p.
//
void
uvm_switch(struct proc *p)
{
	// TODO: your code here.
	//
	// Hints:
	// - You may need pushcli() and popcli()
	// - You need to set TSS and ltr(SEG_TSS << 3)
	// - You need to switch to process's address space
	pushcli();
	thiscpu->gdt[SEG_TSS] = SEG16(STS_T32A, &thiscpu->cpu_ts, sizeof(thiscpu->cpu_ts) - 1, 0);
	thiscpu->gdt[SEG_TSS].s = 0;
	thiscpu->cpu_ts.ss0 = SEG_KDATA << 3;
	thiscpu->cpu_ts.esp0 = (uintptr_t)p->kstack + KSTACKSIZE;
	thiscpu->cpu_ts.iomb = (uint16_t)0xFFFF;
	ltr(SEG_TSS << 3);
	lcr3(V2P(p->pgdir));
	popcli();
}
