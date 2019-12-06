# <center>Lab2 Memory Management</center>

[TOC]

## Kalloc

### Boot_alloc_init() & Alloc_init()

In these two functions, we need to find vacant pages and then add page header to each of them, and then put these pages into the free list and update the kmem.free_list which denotes the beginning of the list of vacant pages, so that everytime when we need a vacant page, we can just get one from the free list and update the kmem.free_list. We can directly invoke the function free_range(void *vstart, void *vend), which then call the function kfree(char *v). Kfree(char *v) will free the page of physical memory pointed at by v and then add the page into the free list, so free_range() can free the contiguous segment starting at the vstart and ending at the vend and batch put these free pages into the free list. So the only difference between the Boot_alloc_init() and Alloc_init() is the segment they deal with, since when we invoke the Boot_alloc_init(), we only map 4M physical address to our address space using the entrypgdir, and need to build another mapper using the vacant page in the mapped 4M space. 

### Kalloc()

It will return a pointer pointing to the page that is allocated and can be used. So just look up in the kmem to see if there are free pages or panic.

### Check_free_list()

We add a procedure to check if all the bits in a free page has been set to 1. 

## VM

### Pgdir_walk()

Pgdir_walk() need to find the address of the corresponding page table entry of the virtual address. According to the rules, the first 10 bits of virtual address correspond to the offset in the page directory entry which helps to find the page table page, If that entry is valid (present at the page directory page) then we can directly to retrieve the page table page using it, otherwise we need to allocate a page for the page directory entry and clear the page and set its flags. With the address of the page table page, we can easily get the address of page table entry using the next 10 bits of virtual address.

### Map_region()

Map_region() need to set the corresponding physical address in the page table entry. And since the virtual address and the size of the segment may not be aligned to the pagesize, so we need first invoke Macro ROUNDUP(), and then map each physical page to the corresponding virtual one. Pgdir_walk() will return the address of the page table entry, which we can use to set the physical address and page table flags. Also we may fail to find the address of the page table entry and then return -1 to indicate that, otherwise return 0.

### Kvm_init()

Kvm_init() need to map all the virtual address to the physical address by the rules of kmap. In the kmap, we just map the physical address to the high address in the virtual address by adding the KERNBASE. As for the flags we just set all the segments to Writable except the instruction segment. Back to the kvm_init(), we need first allocate space for the new page directory page, by the way, everytime we invoke the kalloc() we need to check if we've allocate a page successfully by check if the return value is not 0, and then clear the page, cause when we free a page, we just fill the page with junk, that's to say 1. And then invoke the map_region() to map the virtual address to the physical address by the rules of kmap and need to check if it succeed, if not, then free the page directory page and then return 0 to indicate the failure.

### Vm_free()

Vm_free(pde_t *pgdir) need to free all existing PTEs for the given page directory. Since the first 10 bits of the virtual address correspond to the offset in the page directory page, we need to iterate 1024 times to see if there are valid page directory entry that points to the page table page. And the last 12 bits of the page directory entry are directory entry flags, so we need to clear them to get the page-aligned address of the page table page, and then free the page using kfree(). 

### Check_vm()

We add this function to check if all the page table entry has been set as we want.

## Questions

- About physical allocator, why do we need to initialize it in two phases?

  Because allocator need space to reside and every use of the space should be in the address space while to maintain the page directory page and page table page we need allocator to allocate space, which becomes the circular dependency. To break the circle, we can first build up a small mapping (4M) through the entrypgdir which contains the text and data and also leaves enough space which we can use to build up another mapper covering all the physical space. 