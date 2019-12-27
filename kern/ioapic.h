#ifndef KERN_IOAPIC_H
#define KERN_IOAPIC_H
void ioapic_init(void);
void ioapicenable(int irq, int cpunum);
#endif