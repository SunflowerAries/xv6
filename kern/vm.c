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

// Defined by kern/kernel.ld.
extern char data[];
// Kernel's page table directory.
pde_t *kpgdir;

void
seg_init(void)
{
	// Map "logical" addresses to virtual addresses using identity map.
	// Cannot share a CODE descriptor for both kernel and user
	// because it would have to have DPL_USR, but the CPU forbids
	// an interrupt from CPL=0 to DPL=3.
	struct segdesc gdt[NSEGS];
	// Your code here.
	//
	// Hints:
	// 1. You should set up at least four segments: kern code, kern data,
	// user code, user data;
	// 2. The various segment selectors, application segment type bits and
	// User DPL have been defined in kern/mmu.h;
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
static pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int32_t alloc)
{
	// TODO: Fill this function in
	pde_t *pde = &pgdir[PDX(va)];
	pte_t *pgtab;
	if ((*pde & PTE_P) == 1)
	    pgtab = (pte_t *)P2V((*pde >> 12) << 12);
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
