#ifndef KERN_VM_H
#define KERN_VM_H

#include <inc/memlayout.h>
#include <kern/proc.h>
#include <inc/elf.h>
#include <inc/mmu.h>

void vm_init(void);
pde_t *kvm_init(void);
void kvm_switch(void);
void vm_free(pde_t *);

void seg_init(void);
void region_alloc(struct proc *p, void *va, size_t len);
void uvm_switch(struct proc *p);
int loaduvm(pde_t *pgdir, char *addr, struct Proghdr *ph, char *binary);
pte_t *pgdir_walk(pde_t *pgdir, const void *va, int32_t alloc);
pde_t *copyuvm(pde_t *pgdir);

void pushcli(void);
void popcli(void);

#endif /* !KERN_VM_H */