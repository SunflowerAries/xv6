#ifndef KERN_KALLOC_H
#define KERN_KALLOC_H

void boot_alloc_init(void);
void alloc_init(void);
char *kalloc(void);
void kfree(char*);
void Buddykfree(char*);
void free_range(void *, void *);
void Buddyfree_range(void *, int);
void split(char*, int, int);
char *Buddykalloc(int);

int pow_2(int);

// Check function
void check_free_list(void);

#endif /* !KERN_KALLOC_H */