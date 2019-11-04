
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 70 11 00       	mov    $0x117000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f010002f:	bc 00 70 11 f0       	mov    $0xf0117000,%esp

	# now to C code
	call	i386_init
f0100034:	e8 02 00 00 00       	call   f010003b <i386_init>

f0100039 <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f0100039:	eb fe                	jmp    f0100039 <spin>

f010003b <i386_init>:

static void boot_aps(void);

void
i386_init()
{
f010003b:	55                   	push   %ebp
f010003c:	89 e5                	mov    %esp,%ebp
f010003e:	53                   	push   %ebx
f010003f:	83 ec 08             	sub    $0x8,%esp
    extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
    memset(edata, 0, end - edata);
f0100042:	b8 08 c0 15 f0       	mov    $0xf015c008,%eax
f0100047:	2d 76 97 11 f0       	sub    $0xf0119776,%eax
f010004c:	50                   	push   %eax
f010004d:	6a 00                	push   $0x0
f010004f:	68 76 97 11 f0       	push   $0xf0119776
f0100054:	e8 d0 2c 00 00       	call   f0102d29 <memset>

	cons_init();
f0100059:	e8 ab 05 00 00       	call   f0100609 <cons_init>

	cprintf("Hello, world.\n");
f010005e:	c7 04 24 80 31 10 f0 	movl   $0xf0103180,(%esp)
f0100065:	e8 11 07 00 00       	call   f010077b <cprintf>
	boot_alloc_init();
f010006a:	e8 9e 1a 00 00       	call   f0101b0d <boot_alloc_init>
	vm_init();
f010006f:	e8 a0 15 00 00       	call   f0101614 <vm_init>
	seg_init();
f0100074:	e8 b6 12 00 00       	call   f010132f <seg_init>
	trap_init();
f0100079:	e8 11 07 00 00       	call   f010078f <trap_init>

	mp_init();
f010007e:	e8 28 1d 00 00       	call   f0101dab <mp_init>
	lapic_init();
f0100083:	e8 eb 1f 00 00       	call   f0102073 <lapic_init>
	pic_init();
f0100088:	e8 ca 23 00 00       	call   f0102457 <pic_init>
	void *code;
	struct CpuInfo *c;

	// Write entry code to unused memory at MPENTRY_PADDR
	code = P2V(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);
f010008d:	83 c4 0c             	add    $0xc,%esp
f0100090:	b8 4e 1d 10 f0       	mov    $0xf0101d4e,%eax
f0100095:	2d d4 1c 10 f0       	sub    $0xf0101cd4,%eax
f010009a:	50                   	push   %eax
f010009b:	68 d4 1c 10 f0       	push   $0xf0101cd4
f01000a0:	68 00 70 00 f0       	push   $0xf0007000
f01000a5:	e8 cc 2c 00 00       	call   f0102d76 <memmove>
f01000aa:	83 c4 10             	add    $0x10,%esp

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f01000ad:	bb 20 b0 11 f0       	mov    $0xf011b020,%ebx
f01000b2:	eb 06                	jmp    f01000ba <i386_init+0x7f>
f01000b4:	81 c3 a0 00 00 00    	add    $0xa0,%ebx
f01000ba:	a1 24 b5 11 f0       	mov    0xf011b524,%eax
f01000bf:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01000c2:	c1 e0 05             	shl    $0x5,%eax
f01000c5:	05 20 b0 11 f0       	add    $0xf011b020,%eax
f01000ca:	39 c3                	cmp    %eax,%ebx
f01000cc:	73 4f                	jae    f010011d <i386_init+0xe2>
		if (c == cpus + cpunum())  // We've started already.
f01000ce:	e8 86 1f 00 00       	call   f0102059 <cpunum>
f01000d3:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01000d6:	c1 e0 05             	shl    $0x5,%eax
f01000d9:	05 20 b0 11 f0       	add    $0xf011b020,%eax
f01000de:	39 c3                	cmp    %eax,%ebx
f01000e0:	74 d2                	je     f01000b4 <i386_init+0x79>
			continue;

		// Tell mpentry.S what stack to use 
		mpentry_kstack = percpu_kstacks[c - cpus] + KSTKSIZE;
f01000e2:	89 d8                	mov    %ebx,%eax
f01000e4:	2d 20 b0 11 f0       	sub    $0xf011b020,%eax
f01000e9:	c1 f8 05             	sar    $0x5,%eax
f01000ec:	69 c0 cd cc cc cc    	imul   $0xcccccccd,%eax,%eax
f01000f2:	c1 e0 0f             	shl    $0xf,%eax
f01000f5:	05 00 40 12 f0       	add    $0xf0124000,%eax
f01000fa:	a3 48 a6 11 f0       	mov    %eax,0xf011a648
		// Start the CPU at mpentry_start
		lapic_startap(c->cpu_id, V2P(code));
f01000ff:	83 ec 08             	sub    $0x8,%esp
f0100102:	68 00 70 00 00       	push   $0x7000
f0100107:	0f b6 03             	movzbl (%ebx),%eax
f010010a:	50                   	push   %eax
f010010b:	e8 a6 20 00 00       	call   f01021b6 <lapic_startap>
f0100110:	83 c4 10             	add    $0x10,%esp
		// Wait for the CPU to finish some basic setup in mp_main()
		while(c->cpu_status != CPU_STARTED)
f0100113:	8b 43 04             	mov    0x4(%ebx),%eax
f0100116:	83 f8 01             	cmp    $0x1,%eax
f0100119:	75 f8                	jne    f0100113 <i386_init+0xd8>
f010011b:	eb 97                	jmp    f01000b4 <i386_init+0x79>
	alloc_init();
f010011d:	e8 91 1b 00 00       	call   f0101cb3 <alloc_init>
	cprintf("VM: Init success.\n");
f0100122:	83 ec 0c             	sub    $0xc,%esp
f0100125:	68 8f 31 10 f0       	push   $0xf010318f
f010012a:	e8 4c 06 00 00       	call   f010077b <cprintf>
	check_free_list();
f010012f:	e8 4a 19 00 00       	call   f0101a7e <check_free_list>
	cprintf("Finish.\n");
f0100134:	c7 04 24 a2 31 10 f0 	movl   $0xf01031a2,(%esp)
f010013b:	e8 3b 06 00 00       	call   f010077b <cprintf>
f0100140:	83 c4 10             	add    $0x10,%esp
f0100143:	eb fe                	jmp    f0100143 <i386_init+0x108>

f0100145 <mp_main>:
}

// Setup code for APs
void
mp_main(void)
{
f0100145:	55                   	push   %ebp
f0100146:	89 e5                	mov    %esp,%ebp
f0100148:	83 ec 08             	sub    $0x8,%esp
	// TODO: Your code here.
	// You need to initialize something.
	kvm_switch();
f010014b:	e8 f3 13 00 00       	call   f0101543 <kvm_switch>
	seg_init();
f0100150:	e8 da 11 00 00       	call   f010132f <seg_init>
	lapic_init();
f0100155:	e8 19 1f 00 00       	call   f0102073 <lapic_init>
	cprintf("Starting CPU%d.\n", cpunum());
f010015a:	e8 fa 1e 00 00       	call   f0102059 <cpunum>
f010015f:	83 ec 08             	sub    $0x8,%esp
f0100162:	50                   	push   %eax
f0100163:	68 ab 31 10 f0       	push   $0xf01031ab
f0100168:	e8 0e 06 00 00       	call   f010077b <cprintf>
	idt_init();
f010016d:	e8 90 06 00 00       	call   f0100802 <idt_init>
	xchg(&thiscpu->cpu_status, CPU_STARTED); // tell boot_aps() we're up
f0100172:	e8 e2 1e 00 00       	call   f0102059 <cpunum>
f0100177:	8d 14 80             	lea    (%eax,%eax,4),%edx
f010017a:	c1 e2 05             	shl    $0x5,%edx
f010017d:	83 c2 04             	add    $0x4,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f0100180:	b8 01 00 00 00       	mov    $0x1,%eax
f0100185:	f0 87 82 20 b0 11 f0 	lock xchg %eax,-0xfee4fe0(%edx)
f010018c:	83 c4 10             	add    $0x10,%esp
f010018f:	eb fe                	jmp    f010018f <mp_main+0x4a>

f0100191 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100191:	55                   	push   %ebp
f0100192:	89 e5                	mov    %esp,%ebp
f0100194:	56                   	push   %esi
f0100195:	53                   	push   %ebx
f0100196:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100199:	83 3d 44 a6 11 f0 00 	cmpl   $0x0,0xf011a644
f01001a0:	74 02                	je     f01001a4 <_panic+0x13>
f01001a2:	eb fe                	jmp    f01001a2 <_panic+0x11>
		goto dead;
	panicstr = fmt;
f01001a4:	89 35 44 a6 11 f0    	mov    %esi,0xf011a644

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01001aa:	fa                   	cli    
f01001ab:	fc                   	cld    

	va_start(ap, fmt);
f01001ac:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01001af:	83 ec 04             	sub    $0x4,%esp
f01001b2:	ff 75 0c             	pushl  0xc(%ebp)
f01001b5:	ff 75 08             	pushl  0x8(%ebp)
f01001b8:	68 bc 31 10 f0       	push   $0xf01031bc
f01001bd:	e8 b9 05 00 00       	call   f010077b <cprintf>
	vcprintf(fmt, ap);
f01001c2:	83 c4 08             	add    $0x8,%esp
f01001c5:	53                   	push   %ebx
f01001c6:	56                   	push   %esi
f01001c7:	e8 89 05 00 00       	call   f0100755 <vcprintf>
	cprintf("\n");
f01001cc:	c7 04 24 f8 31 10 f0 	movl   $0xf01031f8,(%esp)
f01001d3:	e8 a3 05 00 00       	call   f010077b <cprintf>
f01001d8:	83 c4 10             	add    $0x10,%esp
f01001db:	eb c5                	jmp    f01001a2 <_panic+0x11>

f01001dd <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01001dd:	55                   	push   %ebp
f01001de:	89 e5                	mov    %esp,%ebp
f01001e0:	53                   	push   %ebx
f01001e1:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01001e4:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01001e7:	ff 75 0c             	pushl  0xc(%ebp)
f01001ea:	ff 75 08             	pushl  0x8(%ebp)
f01001ed:	68 d4 31 10 f0       	push   $0xf01031d4
f01001f2:	e8 84 05 00 00       	call   f010077b <cprintf>
	vcprintf(fmt, ap);
f01001f7:	83 c4 08             	add    $0x8,%esp
f01001fa:	53                   	push   %ebx
f01001fb:	ff 75 10             	pushl  0x10(%ebp)
f01001fe:	e8 52 05 00 00       	call   f0100755 <vcprintf>
	cprintf("\n");
f0100203:	c7 04 24 f8 31 10 f0 	movl   $0xf01031f8,(%esp)
f010020a:	e8 6c 05 00 00       	call   f010077b <cprintf>
	va_end(ap);
}
f010020f:	83 c4 10             	add    $0x10,%esp
f0100212:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100215:	c9                   	leave  
f0100216:	c3                   	ret    

f0100217 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100217:	55                   	push   %ebp
f0100218:	89 e5                	mov    %esp,%ebp
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010021a:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010021f:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100220:	a8 01                	test   $0x1,%al
f0100222:	74 0b                	je     f010022f <serial_proc_data+0x18>
f0100224:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100229:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010022a:	0f b6 c0             	movzbl %al,%eax
}
f010022d:	5d                   	pop    %ebp
f010022e:	c3                   	ret    
		return -1;
f010022f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100234:	eb f7                	jmp    f010022d <serial_proc_data+0x16>

f0100236 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100236:	55                   	push   %ebp
f0100237:	89 e5                	mov    %esp,%ebp
f0100239:	53                   	push   %ebx
f010023a:	83 ec 04             	sub    $0x4,%esp
f010023d:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f010023f:	ff d3                	call   *%ebx
f0100241:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100244:	74 2d                	je     f0100273 <cons_intr+0x3d>
		if (c == 0)
f0100246:	85 c0                	test   %eax,%eax
f0100248:	74 f5                	je     f010023f <cons_intr+0x9>
			continue;
		cons.buf[cons.wpos++] = c;
f010024a:	8b 0d 24 a2 11 f0    	mov    0xf011a224,%ecx
f0100250:	8d 51 01             	lea    0x1(%ecx),%edx
f0100253:	89 15 24 a2 11 f0    	mov    %edx,0xf011a224
f0100259:	88 81 20 a0 11 f0    	mov    %al,-0xfee5fe0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f010025f:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100265:	75 d8                	jne    f010023f <cons_intr+0x9>
			cons.wpos = 0;
f0100267:	c7 05 24 a2 11 f0 00 	movl   $0x0,0xf011a224
f010026e:	00 00 00 
f0100271:	eb cc                	jmp    f010023f <cons_intr+0x9>
	}
}
f0100273:	83 c4 04             	add    $0x4,%esp
f0100276:	5b                   	pop    %ebx
f0100277:	5d                   	pop    %ebp
f0100278:	c3                   	ret    

f0100279 <kbd_proc_data>:
{
f0100279:	55                   	push   %ebp
f010027a:	89 e5                	mov    %esp,%ebp
f010027c:	53                   	push   %ebx
f010027d:	83 ec 04             	sub    $0x4,%esp
f0100280:	ba 64 00 00 00       	mov    $0x64,%edx
f0100285:	ec                   	in     (%dx),%al
	if ((stat & KBS_DIB) == 0)
f0100286:	a8 01                	test   $0x1,%al
f0100288:	0f 84 fa 00 00 00    	je     f0100388 <kbd_proc_data+0x10f>
	if (stat & KBS_TERR)
f010028e:	a8 20                	test   $0x20,%al
f0100290:	0f 85 f9 00 00 00    	jne    f010038f <kbd_proc_data+0x116>
f0100296:	ba 60 00 00 00       	mov    $0x60,%edx
f010029b:	ec                   	in     (%dx),%al
f010029c:	89 c2                	mov    %eax,%edx
	if (data == 0xE0) {
f010029e:	3c e0                	cmp    $0xe0,%al
f01002a0:	0f 84 8e 00 00 00    	je     f0100334 <kbd_proc_data+0xbb>
	} else if (data & 0x80) {
f01002a6:	84 c0                	test   %al,%al
f01002a8:	0f 88 99 00 00 00    	js     f0100347 <kbd_proc_data+0xce>
	} else if (shift & E0ESC) {
f01002ae:	8b 0d 00 a0 11 f0    	mov    0xf011a000,%ecx
f01002b4:	f6 c1 40             	test   $0x40,%cl
f01002b7:	74 0e                	je     f01002c7 <kbd_proc_data+0x4e>
		data |= 0x80;
f01002b9:	83 c8 80             	or     $0xffffff80,%eax
f01002bc:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f01002be:	83 e1 bf             	and    $0xffffffbf,%ecx
f01002c1:	89 0d 00 a0 11 f0    	mov    %ecx,0xf011a000
	shift |= shiftcode[data];
f01002c7:	0f b6 d2             	movzbl %dl,%edx
f01002ca:	0f b6 82 40 33 10 f0 	movzbl -0xfefccc0(%edx),%eax
f01002d1:	0b 05 00 a0 11 f0    	or     0xf011a000,%eax
	shift ^= togglecode[data];
f01002d7:	0f b6 8a 40 32 10 f0 	movzbl -0xfefcdc0(%edx),%ecx
f01002de:	31 c8                	xor    %ecx,%eax
f01002e0:	a3 00 a0 11 f0       	mov    %eax,0xf011a000
	c = charcode[shift & (CTL | SHIFT)][data];
f01002e5:	89 c1                	mov    %eax,%ecx
f01002e7:	83 e1 03             	and    $0x3,%ecx
f01002ea:	8b 0c 8d 20 32 10 f0 	mov    -0xfefcde0(,%ecx,4),%ecx
f01002f1:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f01002f5:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f01002f8:	a8 08                	test   $0x8,%al
f01002fa:	74 0d                	je     f0100309 <kbd_proc_data+0x90>
		if ('a' <= c && c <= 'z')
f01002fc:	89 da                	mov    %ebx,%edx
f01002fe:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100301:	83 f9 19             	cmp    $0x19,%ecx
f0100304:	77 74                	ja     f010037a <kbd_proc_data+0x101>
			c += 'A' - 'a';
f0100306:	83 eb 20             	sub    $0x20,%ebx
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100309:	f7 d0                	not    %eax
f010030b:	a8 06                	test   $0x6,%al
f010030d:	75 31                	jne    f0100340 <kbd_proc_data+0xc7>
f010030f:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100315:	75 29                	jne    f0100340 <kbd_proc_data+0xc7>
		cprintf("Rebooting!\n");
f0100317:	83 ec 0c             	sub    $0xc,%esp
f010031a:	68 ee 31 10 f0       	push   $0xf01031ee
f010031f:	e8 57 04 00 00       	call   f010077b <cprintf>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100324:	b8 03 00 00 00       	mov    $0x3,%eax
f0100329:	ba 92 00 00 00       	mov    $0x92,%edx
f010032e:	ee                   	out    %al,(%dx)
f010032f:	83 c4 10             	add    $0x10,%esp
f0100332:	eb 0c                	jmp    f0100340 <kbd_proc_data+0xc7>
		shift |= E0ESC;
f0100334:	83 0d 00 a0 11 f0 40 	orl    $0x40,0xf011a000
		return 0;
f010033b:	bb 00 00 00 00       	mov    $0x0,%ebx
}
f0100340:	89 d8                	mov    %ebx,%eax
f0100342:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100345:	c9                   	leave  
f0100346:	c3                   	ret    
		data = (shift & E0ESC ? data : data & 0x7F);
f0100347:	8b 0d 00 a0 11 f0    	mov    0xf011a000,%ecx
f010034d:	89 cb                	mov    %ecx,%ebx
f010034f:	83 e3 40             	and    $0x40,%ebx
f0100352:	83 e0 7f             	and    $0x7f,%eax
f0100355:	85 db                	test   %ebx,%ebx
f0100357:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f010035a:	0f b6 d2             	movzbl %dl,%edx
f010035d:	0f b6 82 40 33 10 f0 	movzbl -0xfefccc0(%edx),%eax
f0100364:	83 c8 40             	or     $0x40,%eax
f0100367:	0f b6 c0             	movzbl %al,%eax
f010036a:	f7 d0                	not    %eax
f010036c:	21 c8                	and    %ecx,%eax
f010036e:	a3 00 a0 11 f0       	mov    %eax,0xf011a000
		return 0;
f0100373:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100378:	eb c6                	jmp    f0100340 <kbd_proc_data+0xc7>
		else if ('A' <= c && c <= 'Z')
f010037a:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f010037d:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100380:	83 fa 1a             	cmp    $0x1a,%edx
f0100383:	0f 42 d9             	cmovb  %ecx,%ebx
f0100386:	eb 81                	jmp    f0100309 <kbd_proc_data+0x90>
		return -1;
f0100388:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
f010038d:	eb b1                	jmp    f0100340 <kbd_proc_data+0xc7>
		return -1;
f010038f:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
f0100394:	eb aa                	jmp    f0100340 <kbd_proc_data+0xc7>

f0100396 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100396:	55                   	push   %ebp
f0100397:	89 e5                	mov    %esp,%ebp
f0100399:	57                   	push   %edi
f010039a:	56                   	push   %esi
f010039b:	53                   	push   %ebx
f010039c:	83 ec 1c             	sub    $0x1c,%esp
f010039f:	89 c7                	mov    %eax,%edi
	for (i = 0;
f01003a1:	bb 00 00 00 00       	mov    $0x0,%ebx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003a6:	be fd 03 00 00       	mov    $0x3fd,%esi
f01003ab:	b9 84 00 00 00       	mov    $0x84,%ecx
f01003b0:	eb 09                	jmp    f01003bb <cons_putc+0x25>
f01003b2:	89 ca                	mov    %ecx,%edx
f01003b4:	ec                   	in     (%dx),%al
f01003b5:	ec                   	in     (%dx),%al
f01003b6:	ec                   	in     (%dx),%al
f01003b7:	ec                   	in     (%dx),%al
	     i++)
f01003b8:	83 c3 01             	add    $0x1,%ebx
f01003bb:	89 f2                	mov    %esi,%edx
f01003bd:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01003be:	a8 20                	test   $0x20,%al
f01003c0:	75 08                	jne    f01003ca <cons_putc+0x34>
f01003c2:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01003c8:	7e e8                	jle    f01003b2 <cons_putc+0x1c>
	outb(COM1 + COM_TX, c);
f01003ca:	89 f8                	mov    %edi,%eax
f01003cc:	88 45 e7             	mov    %al,-0x19(%ebp)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003cf:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01003d4:	ee                   	out    %al,(%dx)
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01003d5:	bb 00 00 00 00       	mov    $0x0,%ebx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003da:	be 79 03 00 00       	mov    $0x379,%esi
f01003df:	b9 84 00 00 00       	mov    $0x84,%ecx
f01003e4:	eb 09                	jmp    f01003ef <cons_putc+0x59>
f01003e6:	89 ca                	mov    %ecx,%edx
f01003e8:	ec                   	in     (%dx),%al
f01003e9:	ec                   	in     (%dx),%al
f01003ea:	ec                   	in     (%dx),%al
f01003eb:	ec                   	in     (%dx),%al
f01003ec:	83 c3 01             	add    $0x1,%ebx
f01003ef:	89 f2                	mov    %esi,%edx
f01003f1:	ec                   	in     (%dx),%al
f01003f2:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01003f8:	7f 04                	jg     f01003fe <cons_putc+0x68>
f01003fa:	84 c0                	test   %al,%al
f01003fc:	79 e8                	jns    f01003e6 <cons_putc+0x50>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003fe:	ba 78 03 00 00       	mov    $0x378,%edx
f0100403:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100407:	ee                   	out    %al,(%dx)
f0100408:	ba 7a 03 00 00       	mov    $0x37a,%edx
f010040d:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100412:	ee                   	out    %al,(%dx)
f0100413:	b8 08 00 00 00       	mov    $0x8,%eax
f0100418:	ee                   	out    %al,(%dx)
	if (!(c & ~0xFF))
f0100419:	89 fa                	mov    %edi,%edx
f010041b:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100421:	89 f8                	mov    %edi,%eax
f0100423:	80 cc 07             	or     $0x7,%ah
f0100426:	85 d2                	test   %edx,%edx
f0100428:	0f 44 f8             	cmove  %eax,%edi
	switch (c & 0xff) {
f010042b:	89 f8                	mov    %edi,%eax
f010042d:	0f b6 c0             	movzbl %al,%eax
f0100430:	83 f8 09             	cmp    $0x9,%eax
f0100433:	0f 84 b6 00 00 00    	je     f01004ef <cons_putc+0x159>
f0100439:	83 f8 09             	cmp    $0x9,%eax
f010043c:	7e 73                	jle    f01004b1 <cons_putc+0x11b>
f010043e:	83 f8 0a             	cmp    $0xa,%eax
f0100441:	0f 84 9b 00 00 00    	je     f01004e2 <cons_putc+0x14c>
f0100447:	83 f8 0d             	cmp    $0xd,%eax
f010044a:	0f 85 d6 00 00 00    	jne    f0100526 <cons_putc+0x190>
		crt_pos -= (crt_pos % CRT_COLS);
f0100450:	0f b7 05 28 a2 11 f0 	movzwl 0xf011a228,%eax
f0100457:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f010045d:	c1 e8 16             	shr    $0x16,%eax
f0100460:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100463:	c1 e0 04             	shl    $0x4,%eax
f0100466:	66 a3 28 a2 11 f0    	mov    %ax,0xf011a228
	if (crt_pos >= CRT_SIZE) {
f010046c:	66 81 3d 28 a2 11 f0 	cmpw   $0x7cf,0xf011a228
f0100473:	cf 07 
f0100475:	0f 87 ce 00 00 00    	ja     f0100549 <cons_putc+0x1b3>
	outb(addr_6845, 14);
f010047b:	8b 0d 30 a2 11 f0    	mov    0xf011a230,%ecx
f0100481:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100486:	89 ca                	mov    %ecx,%edx
f0100488:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100489:	0f b7 1d 28 a2 11 f0 	movzwl 0xf011a228,%ebx
f0100490:	8d 71 01             	lea    0x1(%ecx),%esi
f0100493:	89 d8                	mov    %ebx,%eax
f0100495:	66 c1 e8 08          	shr    $0x8,%ax
f0100499:	89 f2                	mov    %esi,%edx
f010049b:	ee                   	out    %al,(%dx)
f010049c:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004a1:	89 ca                	mov    %ecx,%edx
f01004a3:	ee                   	out    %al,(%dx)
f01004a4:	89 d8                	mov    %ebx,%eax
f01004a6:	89 f2                	mov    %esi,%edx
f01004a8:	ee                   	out    %al,(%dx)
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004a9:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01004ac:	5b                   	pop    %ebx
f01004ad:	5e                   	pop    %esi
f01004ae:	5f                   	pop    %edi
f01004af:	5d                   	pop    %ebp
f01004b0:	c3                   	ret    
	switch (c & 0xff) {
f01004b1:	83 f8 08             	cmp    $0x8,%eax
f01004b4:	75 70                	jne    f0100526 <cons_putc+0x190>
		if (crt_pos > 0) {
f01004b6:	0f b7 05 28 a2 11 f0 	movzwl 0xf011a228,%eax
f01004bd:	66 85 c0             	test   %ax,%ax
f01004c0:	74 b9                	je     f010047b <cons_putc+0xe5>
			crt_pos--;
f01004c2:	83 e8 01             	sub    $0x1,%eax
f01004c5:	66 a3 28 a2 11 f0    	mov    %ax,0xf011a228
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01004cb:	0f b7 c0             	movzwl %ax,%eax
f01004ce:	66 81 e7 00 ff       	and    $0xff00,%di
f01004d3:	83 cf 20             	or     $0x20,%edi
f01004d6:	8b 15 2c a2 11 f0    	mov    0xf011a22c,%edx
f01004dc:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01004e0:	eb 8a                	jmp    f010046c <cons_putc+0xd6>
		crt_pos += CRT_COLS;
f01004e2:	66 83 05 28 a2 11 f0 	addw   $0x50,0xf011a228
f01004e9:	50 
f01004ea:	e9 61 ff ff ff       	jmp    f0100450 <cons_putc+0xba>
		cons_putc(' ');
f01004ef:	b8 20 00 00 00       	mov    $0x20,%eax
f01004f4:	e8 9d fe ff ff       	call   f0100396 <cons_putc>
		cons_putc(' ');
f01004f9:	b8 20 00 00 00       	mov    $0x20,%eax
f01004fe:	e8 93 fe ff ff       	call   f0100396 <cons_putc>
		cons_putc(' ');
f0100503:	b8 20 00 00 00       	mov    $0x20,%eax
f0100508:	e8 89 fe ff ff       	call   f0100396 <cons_putc>
		cons_putc(' ');
f010050d:	b8 20 00 00 00       	mov    $0x20,%eax
f0100512:	e8 7f fe ff ff       	call   f0100396 <cons_putc>
		cons_putc(' ');
f0100517:	b8 20 00 00 00       	mov    $0x20,%eax
f010051c:	e8 75 fe ff ff       	call   f0100396 <cons_putc>
f0100521:	e9 46 ff ff ff       	jmp    f010046c <cons_putc+0xd6>
		crt_buf[crt_pos++] = c;		/* write the character */
f0100526:	0f b7 05 28 a2 11 f0 	movzwl 0xf011a228,%eax
f010052d:	8d 50 01             	lea    0x1(%eax),%edx
f0100530:	66 89 15 28 a2 11 f0 	mov    %dx,0xf011a228
f0100537:	0f b7 c0             	movzwl %ax,%eax
f010053a:	8b 15 2c a2 11 f0    	mov    0xf011a22c,%edx
f0100540:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100544:	e9 23 ff ff ff       	jmp    f010046c <cons_putc+0xd6>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100549:	a1 2c a2 11 f0       	mov    0xf011a22c,%eax
f010054e:	83 ec 04             	sub    $0x4,%esp
f0100551:	68 00 0f 00 00       	push   $0xf00
f0100556:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010055c:	52                   	push   %edx
f010055d:	50                   	push   %eax
f010055e:	e8 13 28 00 00       	call   f0102d76 <memmove>
			crt_buf[i] = 0x0700 | ' ';
f0100563:	8b 15 2c a2 11 f0    	mov    0xf011a22c,%edx
f0100569:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f010056f:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100575:	83 c4 10             	add    $0x10,%esp
f0100578:	66 c7 00 20 07       	movw   $0x720,(%eax)
f010057d:	83 c0 02             	add    $0x2,%eax
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100580:	39 d0                	cmp    %edx,%eax
f0100582:	75 f4                	jne    f0100578 <cons_putc+0x1e2>
		crt_pos -= CRT_COLS;
f0100584:	66 83 2d 28 a2 11 f0 	subw   $0x50,0xf011a228
f010058b:	50 
f010058c:	e9 ea fe ff ff       	jmp    f010047b <cons_putc+0xe5>

f0100591 <serial_intr>:
	if (serial_exists)
f0100591:	80 3d 34 a2 11 f0 00 	cmpb   $0x0,0xf011a234
f0100598:	75 02                	jne    f010059c <serial_intr+0xb>
f010059a:	f3 c3                	repz ret 
{
f010059c:	55                   	push   %ebp
f010059d:	89 e5                	mov    %esp,%ebp
f010059f:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f01005a2:	b8 17 02 10 f0       	mov    $0xf0100217,%eax
f01005a7:	e8 8a fc ff ff       	call   f0100236 <cons_intr>
}
f01005ac:	c9                   	leave  
f01005ad:	c3                   	ret    

f01005ae <kbd_intr>:
{
f01005ae:	55                   	push   %ebp
f01005af:	89 e5                	mov    %esp,%ebp
f01005b1:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01005b4:	b8 79 02 10 f0       	mov    $0xf0100279,%eax
f01005b9:	e8 78 fc ff ff       	call   f0100236 <cons_intr>
}
f01005be:	c9                   	leave  
f01005bf:	c3                   	ret    

f01005c0 <cons_getc>:
{
f01005c0:	55                   	push   %ebp
f01005c1:	89 e5                	mov    %esp,%ebp
f01005c3:	83 ec 08             	sub    $0x8,%esp
	serial_intr();
f01005c6:	e8 c6 ff ff ff       	call   f0100591 <serial_intr>
	kbd_intr();
f01005cb:	e8 de ff ff ff       	call   f01005ae <kbd_intr>
	if (cons.rpos != cons.wpos) {
f01005d0:	8b 15 20 a2 11 f0    	mov    0xf011a220,%edx
	return 0;
f01005d6:	b8 00 00 00 00       	mov    $0x0,%eax
	if (cons.rpos != cons.wpos) {
f01005db:	3b 15 24 a2 11 f0    	cmp    0xf011a224,%edx
f01005e1:	74 18                	je     f01005fb <cons_getc+0x3b>
		c = cons.buf[cons.rpos++];
f01005e3:	8d 4a 01             	lea    0x1(%edx),%ecx
f01005e6:	89 0d 20 a2 11 f0    	mov    %ecx,0xf011a220
f01005ec:	0f b6 82 20 a0 11 f0 	movzbl -0xfee5fe0(%edx),%eax
		if (cons.rpos == CONSBUFSIZE)
f01005f3:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01005f9:	74 02                	je     f01005fd <cons_getc+0x3d>
}
f01005fb:	c9                   	leave  
f01005fc:	c3                   	ret    
			cons.rpos = 0;
f01005fd:	c7 05 20 a2 11 f0 00 	movl   $0x0,0xf011a220
f0100604:	00 00 00 
f0100607:	eb f2                	jmp    f01005fb <cons_getc+0x3b>

f0100609 <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f0100609:	55                   	push   %ebp
f010060a:	89 e5                	mov    %esp,%ebp
f010060c:	57                   	push   %edi
f010060d:	56                   	push   %esi
f010060e:	53                   	push   %ebx
f010060f:	83 ec 0c             	sub    $0xc,%esp
	was = *cp;
f0100612:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100619:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100620:	5a a5 
	if (*cp != 0xA55A) {
f0100622:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100629:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010062d:	0f 84 b7 00 00 00    	je     f01006ea <cons_init+0xe1>
		addr_6845 = MONO_BASE;
f0100633:	c7 05 30 a2 11 f0 b4 	movl   $0x3b4,0xf011a230
f010063a:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010063d:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
	outb(addr_6845, 14);
f0100642:	8b 3d 30 a2 11 f0    	mov    0xf011a230,%edi
f0100648:	b8 0e 00 00 00       	mov    $0xe,%eax
f010064d:	89 fa                	mov    %edi,%edx
f010064f:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100650:	8d 4f 01             	lea    0x1(%edi),%ecx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100653:	89 ca                	mov    %ecx,%edx
f0100655:	ec                   	in     (%dx),%al
f0100656:	0f b6 c0             	movzbl %al,%eax
f0100659:	c1 e0 08             	shl    $0x8,%eax
f010065c:	89 c3                	mov    %eax,%ebx
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010065e:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100663:	89 fa                	mov    %edi,%edx
f0100665:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100666:	89 ca                	mov    %ecx,%edx
f0100668:	ec                   	in     (%dx),%al
	crt_buf = (uint16_t*) cp;
f0100669:	89 35 2c a2 11 f0    	mov    %esi,0xf011a22c
	pos |= inb(addr_6845 + 1);
f010066f:	0f b6 c0             	movzbl %al,%eax
f0100672:	09 d8                	or     %ebx,%eax
	crt_pos = pos;
f0100674:	66 a3 28 a2 11 f0    	mov    %ax,0xf011a228
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010067a:	bb 00 00 00 00       	mov    $0x0,%ebx
f010067f:	b9 fa 03 00 00       	mov    $0x3fa,%ecx
f0100684:	89 d8                	mov    %ebx,%eax
f0100686:	89 ca                	mov    %ecx,%edx
f0100688:	ee                   	out    %al,(%dx)
f0100689:	bf fb 03 00 00       	mov    $0x3fb,%edi
f010068e:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100693:	89 fa                	mov    %edi,%edx
f0100695:	ee                   	out    %al,(%dx)
f0100696:	b8 0c 00 00 00       	mov    $0xc,%eax
f010069b:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01006a0:	ee                   	out    %al,(%dx)
f01006a1:	be f9 03 00 00       	mov    $0x3f9,%esi
f01006a6:	89 d8                	mov    %ebx,%eax
f01006a8:	89 f2                	mov    %esi,%edx
f01006aa:	ee                   	out    %al,(%dx)
f01006ab:	b8 03 00 00 00       	mov    $0x3,%eax
f01006b0:	89 fa                	mov    %edi,%edx
f01006b2:	ee                   	out    %al,(%dx)
f01006b3:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01006b8:	89 d8                	mov    %ebx,%eax
f01006ba:	ee                   	out    %al,(%dx)
f01006bb:	b8 01 00 00 00       	mov    $0x1,%eax
f01006c0:	89 f2                	mov    %esi,%edx
f01006c2:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006c3:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01006c8:	ec                   	in     (%dx),%al
f01006c9:	89 c3                	mov    %eax,%ebx
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01006cb:	3c ff                	cmp    $0xff,%al
f01006cd:	0f 95 05 34 a2 11 f0 	setne  0xf011a234
f01006d4:	89 ca                	mov    %ecx,%edx
f01006d6:	ec                   	in     (%dx),%al
f01006d7:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01006dc:	ec                   	in     (%dx),%al
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01006dd:	80 fb ff             	cmp    $0xff,%bl
f01006e0:	74 23                	je     f0100705 <cons_init+0xfc>
		cprintf("Serial port does not exist!\n");
}
f01006e2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01006e5:	5b                   	pop    %ebx
f01006e6:	5e                   	pop    %esi
f01006e7:	5f                   	pop    %edi
f01006e8:	5d                   	pop    %ebp
f01006e9:	c3                   	ret    
		*cp = was;
f01006ea:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01006f1:	c7 05 30 a2 11 f0 d4 	movl   $0x3d4,0xf011a230
f01006f8:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01006fb:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
f0100700:	e9 3d ff ff ff       	jmp    f0100642 <cons_init+0x39>
		cprintf("Serial port does not exist!\n");
f0100705:	83 ec 0c             	sub    $0xc,%esp
f0100708:	68 fa 31 10 f0       	push   $0xf01031fa
f010070d:	e8 69 00 00 00       	call   f010077b <cprintf>
f0100712:	83 c4 10             	add    $0x10,%esp
}
f0100715:	eb cb                	jmp    f01006e2 <cons_init+0xd9>

f0100717 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100717:	55                   	push   %ebp
f0100718:	89 e5                	mov    %esp,%ebp
f010071a:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010071d:	8b 45 08             	mov    0x8(%ebp),%eax
f0100720:	e8 71 fc ff ff       	call   f0100396 <cons_putc>
}
f0100725:	c9                   	leave  
f0100726:	c3                   	ret    

f0100727 <getchar>:

int
getchar(void)
{
f0100727:	55                   	push   %ebp
f0100728:	89 e5                	mov    %esp,%ebp
f010072a:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010072d:	e8 8e fe ff ff       	call   f01005c0 <cons_getc>
f0100732:	85 c0                	test   %eax,%eax
f0100734:	74 f7                	je     f010072d <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100736:	c9                   	leave  
f0100737:	c3                   	ret    

f0100738 <iscons>:

int
iscons(int fdnum)
{
f0100738:	55                   	push   %ebp
f0100739:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f010073b:	b8 01 00 00 00       	mov    $0x1,%eax
f0100740:	5d                   	pop    %ebp
f0100741:	c3                   	ret    

f0100742 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100742:	55                   	push   %ebp
f0100743:	89 e5                	mov    %esp,%ebp
f0100745:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0100748:	ff 75 08             	pushl  0x8(%ebp)
f010074b:	e8 c7 ff ff ff       	call   f0100717 <cputchar>
	*cnt++;
}
f0100750:	83 c4 10             	add    $0x10,%esp
f0100753:	c9                   	leave  
f0100754:	c3                   	ret    

f0100755 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100755:	55                   	push   %ebp
f0100756:	89 e5                	mov    %esp,%ebp
f0100758:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f010075b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100762:	ff 75 0c             	pushl  0xc(%ebp)
f0100765:	ff 75 08             	pushl  0x8(%ebp)
f0100768:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010076b:	50                   	push   %eax
f010076c:	68 42 07 10 f0       	push   $0xf0100742
f0100771:	e8 6e 1e 00 00       	call   f01025e4 <vprintfmt>
	return cnt;
}
f0100776:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100779:	c9                   	leave  
f010077a:	c3                   	ret    

f010077b <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010077b:	55                   	push   %ebp
f010077c:	89 e5                	mov    %esp,%ebp
f010077e:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100781:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100784:	50                   	push   %eax
f0100785:	ff 75 08             	pushl  0x8(%ebp)
f0100788:	e8 c8 ff ff ff       	call   f0100755 <vcprintf>
	va_end(ap);

	return cnt;
}
f010078d:	c9                   	leave  
f010078e:	c3                   	ret    

f010078f <trap_init>:
extern uint32_t vectors[]; // in vectors.S: array of 256 entry pointers

// Initialize the interrupt descriptor table.
void
trap_init(void)
{
f010078f:	55                   	push   %ebp
f0100790:	89 e5                	mov    %esp,%ebp
	//
	// Hints:
	// 1. The macro SETGATE in inc/mmu.h should help you, as well as the
	// T_* defines in inc/traps.h;
	// 2. T_SYSCALL is different from the others.
	for (int i = 0; i < 256; i++)
f0100792:	b8 00 00 00 00       	mov    $0x0,%eax
		SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
f0100797:	8b 14 85 00 93 11 f0 	mov    -0xfee6d00(,%eax,4),%edx
f010079e:	66 89 14 c5 60 a6 11 	mov    %dx,-0xfee59a0(,%eax,8)
f01007a5:	f0 
f01007a6:	66 c7 04 c5 62 a6 11 	movw   $0x8,-0xfee599e(,%eax,8)
f01007ad:	f0 08 00 
f01007b0:	c6 04 c5 64 a6 11 f0 	movb   $0x0,-0xfee599c(,%eax,8)
f01007b7:	00 
f01007b8:	c6 04 c5 65 a6 11 f0 	movb   $0x8e,-0xfee599b(,%eax,8)
f01007bf:	8e 
f01007c0:	c1 ea 10             	shr    $0x10,%edx
f01007c3:	66 89 14 c5 66 a6 11 	mov    %dx,-0xfee599a(,%eax,8)
f01007ca:	f0 
	for (int i = 0; i < 256; i++)
f01007cb:	83 c0 01             	add    $0x1,%eax
f01007ce:	3d 00 01 00 00       	cmp    $0x100,%eax
f01007d3:	75 c2                	jne    f0100797 <trap_init+0x8>
	SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
f01007d5:	a1 00 94 11 f0       	mov    0xf0119400,%eax
f01007da:	66 a3 60 a8 11 f0    	mov    %ax,0xf011a860
f01007e0:	66 c7 05 62 a8 11 f0 	movw   $0x8,0xf011a862
f01007e7:	08 00 
f01007e9:	c6 05 64 a8 11 f0 00 	movb   $0x0,0xf011a864
f01007f0:	c6 05 65 a8 11 f0 ef 	movb   $0xef,0xf011a865
f01007f7:	c1 e8 10             	shr    $0x10,%eax
f01007fa:	66 a3 66 a8 11 f0    	mov    %ax,0xf011a866
}
f0100800:	5d                   	pop    %ebp
f0100801:	c3                   	ret    

f0100802 <idt_init>:

void
idt_init(void)
{
f0100802:	55                   	push   %ebp
f0100803:	89 e5                	mov    %esp,%ebp
f0100805:	83 ec 10             	sub    $0x10,%esp
	pd[0] = size-1;
f0100808:	66 c7 45 fa ff 07    	movw   $0x7ff,-0x6(%ebp)
	pd[1] = (unsigned)p;
f010080e:	b8 60 a6 11 f0       	mov    $0xf011a660,%eax
f0100813:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
	pd[2] = (unsigned)p >> 16;
f0100817:	c1 e8 10             	shr    $0x10,%eax
f010081a:	66 89 45 fe          	mov    %ax,-0x2(%ebp)
	asm volatile("lidt (%0)" : : "r" (pd));
f010081e:	8d 45 fa             	lea    -0x6(%ebp),%eax
f0100821:	0f 01 18             	lidtl  (%eax)
	lidt(idt, sizeof(idt));
}
f0100824:	c9                   	leave  
f0100825:	c3                   	ret    

f0100826 <trap>:

void
trap(struct trapframe *tf)
{
f0100826:	55                   	push   %ebp
f0100827:	89 e5                	mov    %esp,%ebp
	// You don't need to implement this function now, but you can write
	// some code for debugging.
f0100829:	5d                   	pop    %ebp
f010082a:	c3                   	ret    

f010082b <alltraps>:
alltraps:
	# Your code here:
	#
	# Hint: you should build trap frame, set up data segments and then
	# call trap(tf)
	pushl %ds
f010082b:	1e                   	push   %ds
	pushl %es
f010082c:	06                   	push   %es
	pushl %fs
f010082d:	0f a0                	push   %fs
	pushl %gs
f010082f:	0f a8                	push   %gs
	pushal 
f0100831:	60                   	pusha  

	movw $(SEG_KDATA<<3), %ax
f0100832:	66 b8 10 00          	mov    $0x10,%ax
	movw %ax, %ds
f0100836:	8e d8                	mov    %eax,%ds
	movw %ax, %es
f0100838:	8e c0                	mov    %eax,%es

	pushl %esp
f010083a:	54                   	push   %esp
	call trap
f010083b:	e8 e6 ff ff ff       	call   f0100826 <trap>
	addl $4, %esp
f0100840:	83 c4 04             	add    $0x4,%esp

f0100843 <trapret>:
	# Return falls through to trapret...
.globl trapret
trapret:
	# Restore registers.
	# Your code here:
	popal
f0100843:	61                   	popa   
	popl %gs
f0100844:	0f a9                	pop    %gs
	popl %fs
f0100846:	0f a1                	pop    %fs
	popl %es
f0100848:	07                   	pop    %es
	popl %ds
f0100849:	1f                   	pop    %ds
	addl $0x8, %esp
f010084a:	83 c4 08             	add    $0x8,%esp
	iret
f010084d:	cf                   	iret   

f010084e <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
f010084e:	6a 00                	push   $0x0
  pushl $0
f0100850:	6a 00                	push   $0x0
  jmp alltraps
f0100852:	e9 d4 ff ff ff       	jmp    f010082b <alltraps>

f0100857 <vector1>:
.globl vector1
vector1:
  pushl $0
f0100857:	6a 00                	push   $0x0
  pushl $1
f0100859:	6a 01                	push   $0x1
  jmp alltraps
f010085b:	e9 cb ff ff ff       	jmp    f010082b <alltraps>

f0100860 <vector2>:
.globl vector2
vector2:
  pushl $0
f0100860:	6a 00                	push   $0x0
  pushl $2
f0100862:	6a 02                	push   $0x2
  jmp alltraps
f0100864:	e9 c2 ff ff ff       	jmp    f010082b <alltraps>

f0100869 <vector3>:
.globl vector3
vector3:
  pushl $0
f0100869:	6a 00                	push   $0x0
  pushl $3
f010086b:	6a 03                	push   $0x3
  jmp alltraps
f010086d:	e9 b9 ff ff ff       	jmp    f010082b <alltraps>

f0100872 <vector4>:
.globl vector4
vector4:
  pushl $0
f0100872:	6a 00                	push   $0x0
  pushl $4
f0100874:	6a 04                	push   $0x4
  jmp alltraps
f0100876:	e9 b0 ff ff ff       	jmp    f010082b <alltraps>

f010087b <vector5>:
.globl vector5
vector5:
  pushl $0
f010087b:	6a 00                	push   $0x0
  pushl $5
f010087d:	6a 05                	push   $0x5
  jmp alltraps
f010087f:	e9 a7 ff ff ff       	jmp    f010082b <alltraps>

f0100884 <vector6>:
.globl vector6
vector6:
  pushl $0
f0100884:	6a 00                	push   $0x0
  pushl $6
f0100886:	6a 06                	push   $0x6
  jmp alltraps
f0100888:	e9 9e ff ff ff       	jmp    f010082b <alltraps>

f010088d <vector7>:
.globl vector7
vector7:
  pushl $0
f010088d:	6a 00                	push   $0x0
  pushl $7
f010088f:	6a 07                	push   $0x7
  jmp alltraps
f0100891:	e9 95 ff ff ff       	jmp    f010082b <alltraps>

f0100896 <vector8>:
.globl vector8
vector8:
  pushl $8
f0100896:	6a 08                	push   $0x8
  jmp alltraps
f0100898:	e9 8e ff ff ff       	jmp    f010082b <alltraps>

f010089d <vector9>:
.globl vector9
vector9:
  pushl $0
f010089d:	6a 00                	push   $0x0
  pushl $9
f010089f:	6a 09                	push   $0x9
  jmp alltraps
f01008a1:	e9 85 ff ff ff       	jmp    f010082b <alltraps>

f01008a6 <vector10>:
.globl vector10
vector10:
  pushl $10
f01008a6:	6a 0a                	push   $0xa
  jmp alltraps
f01008a8:	e9 7e ff ff ff       	jmp    f010082b <alltraps>

f01008ad <vector11>:
.globl vector11
vector11:
  pushl $11
f01008ad:	6a 0b                	push   $0xb
  jmp alltraps
f01008af:	e9 77 ff ff ff       	jmp    f010082b <alltraps>

f01008b4 <vector12>:
.globl vector12
vector12:
  pushl $12
f01008b4:	6a 0c                	push   $0xc
  jmp alltraps
f01008b6:	e9 70 ff ff ff       	jmp    f010082b <alltraps>

f01008bb <vector13>:
.globl vector13
vector13:
  pushl $13
f01008bb:	6a 0d                	push   $0xd
  jmp alltraps
f01008bd:	e9 69 ff ff ff       	jmp    f010082b <alltraps>

f01008c2 <vector14>:
.globl vector14
vector14:
  pushl $14
f01008c2:	6a 0e                	push   $0xe
  jmp alltraps
f01008c4:	e9 62 ff ff ff       	jmp    f010082b <alltraps>

f01008c9 <vector15>:
.globl vector15
vector15:
  pushl $0
f01008c9:	6a 00                	push   $0x0
  pushl $15
f01008cb:	6a 0f                	push   $0xf
  jmp alltraps
f01008cd:	e9 59 ff ff ff       	jmp    f010082b <alltraps>

f01008d2 <vector16>:
.globl vector16
vector16:
  pushl $0
f01008d2:	6a 00                	push   $0x0
  pushl $16
f01008d4:	6a 10                	push   $0x10
  jmp alltraps
f01008d6:	e9 50 ff ff ff       	jmp    f010082b <alltraps>

f01008db <vector17>:
.globl vector17
vector17:
  pushl $17
f01008db:	6a 11                	push   $0x11
  jmp alltraps
f01008dd:	e9 49 ff ff ff       	jmp    f010082b <alltraps>

f01008e2 <vector18>:
.globl vector18
vector18:
  pushl $0
f01008e2:	6a 00                	push   $0x0
  pushl $18
f01008e4:	6a 12                	push   $0x12
  jmp alltraps
f01008e6:	e9 40 ff ff ff       	jmp    f010082b <alltraps>

f01008eb <vector19>:
.globl vector19
vector19:
  pushl $0
f01008eb:	6a 00                	push   $0x0
  pushl $19
f01008ed:	6a 13                	push   $0x13
  jmp alltraps
f01008ef:	e9 37 ff ff ff       	jmp    f010082b <alltraps>

f01008f4 <vector20>:
.globl vector20
vector20:
  pushl $0
f01008f4:	6a 00                	push   $0x0
  pushl $20
f01008f6:	6a 14                	push   $0x14
  jmp alltraps
f01008f8:	e9 2e ff ff ff       	jmp    f010082b <alltraps>

f01008fd <vector21>:
.globl vector21
vector21:
  pushl $0
f01008fd:	6a 00                	push   $0x0
  pushl $21
f01008ff:	6a 15                	push   $0x15
  jmp alltraps
f0100901:	e9 25 ff ff ff       	jmp    f010082b <alltraps>

f0100906 <vector22>:
.globl vector22
vector22:
  pushl $0
f0100906:	6a 00                	push   $0x0
  pushl $22
f0100908:	6a 16                	push   $0x16
  jmp alltraps
f010090a:	e9 1c ff ff ff       	jmp    f010082b <alltraps>

f010090f <vector23>:
.globl vector23
vector23:
  pushl $0
f010090f:	6a 00                	push   $0x0
  pushl $23
f0100911:	6a 17                	push   $0x17
  jmp alltraps
f0100913:	e9 13 ff ff ff       	jmp    f010082b <alltraps>

f0100918 <vector24>:
.globl vector24
vector24:
  pushl $0
f0100918:	6a 00                	push   $0x0
  pushl $24
f010091a:	6a 18                	push   $0x18
  jmp alltraps
f010091c:	e9 0a ff ff ff       	jmp    f010082b <alltraps>

f0100921 <vector25>:
.globl vector25
vector25:
  pushl $0
f0100921:	6a 00                	push   $0x0
  pushl $25
f0100923:	6a 19                	push   $0x19
  jmp alltraps
f0100925:	e9 01 ff ff ff       	jmp    f010082b <alltraps>

f010092a <vector26>:
.globl vector26
vector26:
  pushl $0
f010092a:	6a 00                	push   $0x0
  pushl $26
f010092c:	6a 1a                	push   $0x1a
  jmp alltraps
f010092e:	e9 f8 fe ff ff       	jmp    f010082b <alltraps>

f0100933 <vector27>:
.globl vector27
vector27:
  pushl $0
f0100933:	6a 00                	push   $0x0
  pushl $27
f0100935:	6a 1b                	push   $0x1b
  jmp alltraps
f0100937:	e9 ef fe ff ff       	jmp    f010082b <alltraps>

f010093c <vector28>:
.globl vector28
vector28:
  pushl $0
f010093c:	6a 00                	push   $0x0
  pushl $28
f010093e:	6a 1c                	push   $0x1c
  jmp alltraps
f0100940:	e9 e6 fe ff ff       	jmp    f010082b <alltraps>

f0100945 <vector29>:
.globl vector29
vector29:
  pushl $0
f0100945:	6a 00                	push   $0x0
  pushl $29
f0100947:	6a 1d                	push   $0x1d
  jmp alltraps
f0100949:	e9 dd fe ff ff       	jmp    f010082b <alltraps>

f010094e <vector30>:
.globl vector30
vector30:
  pushl $0
f010094e:	6a 00                	push   $0x0
  pushl $30
f0100950:	6a 1e                	push   $0x1e
  jmp alltraps
f0100952:	e9 d4 fe ff ff       	jmp    f010082b <alltraps>

f0100957 <vector31>:
.globl vector31
vector31:
  pushl $0
f0100957:	6a 00                	push   $0x0
  pushl $31
f0100959:	6a 1f                	push   $0x1f
  jmp alltraps
f010095b:	e9 cb fe ff ff       	jmp    f010082b <alltraps>

f0100960 <vector32>:
.globl vector32
vector32:
  pushl $0
f0100960:	6a 00                	push   $0x0
  pushl $32
f0100962:	6a 20                	push   $0x20
  jmp alltraps
f0100964:	e9 c2 fe ff ff       	jmp    f010082b <alltraps>

f0100969 <vector33>:
.globl vector33
vector33:
  pushl $0
f0100969:	6a 00                	push   $0x0
  pushl $33
f010096b:	6a 21                	push   $0x21
  jmp alltraps
f010096d:	e9 b9 fe ff ff       	jmp    f010082b <alltraps>

f0100972 <vector34>:
.globl vector34
vector34:
  pushl $0
f0100972:	6a 00                	push   $0x0
  pushl $34
f0100974:	6a 22                	push   $0x22
  jmp alltraps
f0100976:	e9 b0 fe ff ff       	jmp    f010082b <alltraps>

f010097b <vector35>:
.globl vector35
vector35:
  pushl $0
f010097b:	6a 00                	push   $0x0
  pushl $35
f010097d:	6a 23                	push   $0x23
  jmp alltraps
f010097f:	e9 a7 fe ff ff       	jmp    f010082b <alltraps>

f0100984 <vector36>:
.globl vector36
vector36:
  pushl $0
f0100984:	6a 00                	push   $0x0
  pushl $36
f0100986:	6a 24                	push   $0x24
  jmp alltraps
f0100988:	e9 9e fe ff ff       	jmp    f010082b <alltraps>

f010098d <vector37>:
.globl vector37
vector37:
  pushl $0
f010098d:	6a 00                	push   $0x0
  pushl $37
f010098f:	6a 25                	push   $0x25
  jmp alltraps
f0100991:	e9 95 fe ff ff       	jmp    f010082b <alltraps>

f0100996 <vector38>:
.globl vector38
vector38:
  pushl $0
f0100996:	6a 00                	push   $0x0
  pushl $38
f0100998:	6a 26                	push   $0x26
  jmp alltraps
f010099a:	e9 8c fe ff ff       	jmp    f010082b <alltraps>

f010099f <vector39>:
.globl vector39
vector39:
  pushl $0
f010099f:	6a 00                	push   $0x0
  pushl $39
f01009a1:	6a 27                	push   $0x27
  jmp alltraps
f01009a3:	e9 83 fe ff ff       	jmp    f010082b <alltraps>

f01009a8 <vector40>:
.globl vector40
vector40:
  pushl $0
f01009a8:	6a 00                	push   $0x0
  pushl $40
f01009aa:	6a 28                	push   $0x28
  jmp alltraps
f01009ac:	e9 7a fe ff ff       	jmp    f010082b <alltraps>

f01009b1 <vector41>:
.globl vector41
vector41:
  pushl $0
f01009b1:	6a 00                	push   $0x0
  pushl $41
f01009b3:	6a 29                	push   $0x29
  jmp alltraps
f01009b5:	e9 71 fe ff ff       	jmp    f010082b <alltraps>

f01009ba <vector42>:
.globl vector42
vector42:
  pushl $0
f01009ba:	6a 00                	push   $0x0
  pushl $42
f01009bc:	6a 2a                	push   $0x2a
  jmp alltraps
f01009be:	e9 68 fe ff ff       	jmp    f010082b <alltraps>

f01009c3 <vector43>:
.globl vector43
vector43:
  pushl $0
f01009c3:	6a 00                	push   $0x0
  pushl $43
f01009c5:	6a 2b                	push   $0x2b
  jmp alltraps
f01009c7:	e9 5f fe ff ff       	jmp    f010082b <alltraps>

f01009cc <vector44>:
.globl vector44
vector44:
  pushl $0
f01009cc:	6a 00                	push   $0x0
  pushl $44
f01009ce:	6a 2c                	push   $0x2c
  jmp alltraps
f01009d0:	e9 56 fe ff ff       	jmp    f010082b <alltraps>

f01009d5 <vector45>:
.globl vector45
vector45:
  pushl $0
f01009d5:	6a 00                	push   $0x0
  pushl $45
f01009d7:	6a 2d                	push   $0x2d
  jmp alltraps
f01009d9:	e9 4d fe ff ff       	jmp    f010082b <alltraps>

f01009de <vector46>:
.globl vector46
vector46:
  pushl $0
f01009de:	6a 00                	push   $0x0
  pushl $46
f01009e0:	6a 2e                	push   $0x2e
  jmp alltraps
f01009e2:	e9 44 fe ff ff       	jmp    f010082b <alltraps>

f01009e7 <vector47>:
.globl vector47
vector47:
  pushl $0
f01009e7:	6a 00                	push   $0x0
  pushl $47
f01009e9:	6a 2f                	push   $0x2f
  jmp alltraps
f01009eb:	e9 3b fe ff ff       	jmp    f010082b <alltraps>

f01009f0 <vector48>:
.globl vector48
vector48:
  pushl $0
f01009f0:	6a 00                	push   $0x0
  pushl $48
f01009f2:	6a 30                	push   $0x30
  jmp alltraps
f01009f4:	e9 32 fe ff ff       	jmp    f010082b <alltraps>

f01009f9 <vector49>:
.globl vector49
vector49:
  pushl $0
f01009f9:	6a 00                	push   $0x0
  pushl $49
f01009fb:	6a 31                	push   $0x31
  jmp alltraps
f01009fd:	e9 29 fe ff ff       	jmp    f010082b <alltraps>

f0100a02 <vector50>:
.globl vector50
vector50:
  pushl $0
f0100a02:	6a 00                	push   $0x0
  pushl $50
f0100a04:	6a 32                	push   $0x32
  jmp alltraps
f0100a06:	e9 20 fe ff ff       	jmp    f010082b <alltraps>

f0100a0b <vector51>:
.globl vector51
vector51:
  pushl $0
f0100a0b:	6a 00                	push   $0x0
  pushl $51
f0100a0d:	6a 33                	push   $0x33
  jmp alltraps
f0100a0f:	e9 17 fe ff ff       	jmp    f010082b <alltraps>

f0100a14 <vector52>:
.globl vector52
vector52:
  pushl $0
f0100a14:	6a 00                	push   $0x0
  pushl $52
f0100a16:	6a 34                	push   $0x34
  jmp alltraps
f0100a18:	e9 0e fe ff ff       	jmp    f010082b <alltraps>

f0100a1d <vector53>:
.globl vector53
vector53:
  pushl $0
f0100a1d:	6a 00                	push   $0x0
  pushl $53
f0100a1f:	6a 35                	push   $0x35
  jmp alltraps
f0100a21:	e9 05 fe ff ff       	jmp    f010082b <alltraps>

f0100a26 <vector54>:
.globl vector54
vector54:
  pushl $0
f0100a26:	6a 00                	push   $0x0
  pushl $54
f0100a28:	6a 36                	push   $0x36
  jmp alltraps
f0100a2a:	e9 fc fd ff ff       	jmp    f010082b <alltraps>

f0100a2f <vector55>:
.globl vector55
vector55:
  pushl $0
f0100a2f:	6a 00                	push   $0x0
  pushl $55
f0100a31:	6a 37                	push   $0x37
  jmp alltraps
f0100a33:	e9 f3 fd ff ff       	jmp    f010082b <alltraps>

f0100a38 <vector56>:
.globl vector56
vector56:
  pushl $0
f0100a38:	6a 00                	push   $0x0
  pushl $56
f0100a3a:	6a 38                	push   $0x38
  jmp alltraps
f0100a3c:	e9 ea fd ff ff       	jmp    f010082b <alltraps>

f0100a41 <vector57>:
.globl vector57
vector57:
  pushl $0
f0100a41:	6a 00                	push   $0x0
  pushl $57
f0100a43:	6a 39                	push   $0x39
  jmp alltraps
f0100a45:	e9 e1 fd ff ff       	jmp    f010082b <alltraps>

f0100a4a <vector58>:
.globl vector58
vector58:
  pushl $0
f0100a4a:	6a 00                	push   $0x0
  pushl $58
f0100a4c:	6a 3a                	push   $0x3a
  jmp alltraps
f0100a4e:	e9 d8 fd ff ff       	jmp    f010082b <alltraps>

f0100a53 <vector59>:
.globl vector59
vector59:
  pushl $0
f0100a53:	6a 00                	push   $0x0
  pushl $59
f0100a55:	6a 3b                	push   $0x3b
  jmp alltraps
f0100a57:	e9 cf fd ff ff       	jmp    f010082b <alltraps>

f0100a5c <vector60>:
.globl vector60
vector60:
  pushl $0
f0100a5c:	6a 00                	push   $0x0
  pushl $60
f0100a5e:	6a 3c                	push   $0x3c
  jmp alltraps
f0100a60:	e9 c6 fd ff ff       	jmp    f010082b <alltraps>

f0100a65 <vector61>:
.globl vector61
vector61:
  pushl $0
f0100a65:	6a 00                	push   $0x0
  pushl $61
f0100a67:	6a 3d                	push   $0x3d
  jmp alltraps
f0100a69:	e9 bd fd ff ff       	jmp    f010082b <alltraps>

f0100a6e <vector62>:
.globl vector62
vector62:
  pushl $0
f0100a6e:	6a 00                	push   $0x0
  pushl $62
f0100a70:	6a 3e                	push   $0x3e
  jmp alltraps
f0100a72:	e9 b4 fd ff ff       	jmp    f010082b <alltraps>

f0100a77 <vector63>:
.globl vector63
vector63:
  pushl $0
f0100a77:	6a 00                	push   $0x0
  pushl $63
f0100a79:	6a 3f                	push   $0x3f
  jmp alltraps
f0100a7b:	e9 ab fd ff ff       	jmp    f010082b <alltraps>

f0100a80 <vector64>:
.globl vector64
vector64:
  pushl $0
f0100a80:	6a 00                	push   $0x0
  pushl $64
f0100a82:	6a 40                	push   $0x40
  jmp alltraps
f0100a84:	e9 a2 fd ff ff       	jmp    f010082b <alltraps>

f0100a89 <vector65>:
.globl vector65
vector65:
  pushl $0
f0100a89:	6a 00                	push   $0x0
  pushl $65
f0100a8b:	6a 41                	push   $0x41
  jmp alltraps
f0100a8d:	e9 99 fd ff ff       	jmp    f010082b <alltraps>

f0100a92 <vector66>:
.globl vector66
vector66:
  pushl $0
f0100a92:	6a 00                	push   $0x0
  pushl $66
f0100a94:	6a 42                	push   $0x42
  jmp alltraps
f0100a96:	e9 90 fd ff ff       	jmp    f010082b <alltraps>

f0100a9b <vector67>:
.globl vector67
vector67:
  pushl $0
f0100a9b:	6a 00                	push   $0x0
  pushl $67
f0100a9d:	6a 43                	push   $0x43
  jmp alltraps
f0100a9f:	e9 87 fd ff ff       	jmp    f010082b <alltraps>

f0100aa4 <vector68>:
.globl vector68
vector68:
  pushl $0
f0100aa4:	6a 00                	push   $0x0
  pushl $68
f0100aa6:	6a 44                	push   $0x44
  jmp alltraps
f0100aa8:	e9 7e fd ff ff       	jmp    f010082b <alltraps>

f0100aad <vector69>:
.globl vector69
vector69:
  pushl $0
f0100aad:	6a 00                	push   $0x0
  pushl $69
f0100aaf:	6a 45                	push   $0x45
  jmp alltraps
f0100ab1:	e9 75 fd ff ff       	jmp    f010082b <alltraps>

f0100ab6 <vector70>:
.globl vector70
vector70:
  pushl $0
f0100ab6:	6a 00                	push   $0x0
  pushl $70
f0100ab8:	6a 46                	push   $0x46
  jmp alltraps
f0100aba:	e9 6c fd ff ff       	jmp    f010082b <alltraps>

f0100abf <vector71>:
.globl vector71
vector71:
  pushl $0
f0100abf:	6a 00                	push   $0x0
  pushl $71
f0100ac1:	6a 47                	push   $0x47
  jmp alltraps
f0100ac3:	e9 63 fd ff ff       	jmp    f010082b <alltraps>

f0100ac8 <vector72>:
.globl vector72
vector72:
  pushl $0
f0100ac8:	6a 00                	push   $0x0
  pushl $72
f0100aca:	6a 48                	push   $0x48
  jmp alltraps
f0100acc:	e9 5a fd ff ff       	jmp    f010082b <alltraps>

f0100ad1 <vector73>:
.globl vector73
vector73:
  pushl $0
f0100ad1:	6a 00                	push   $0x0
  pushl $73
f0100ad3:	6a 49                	push   $0x49
  jmp alltraps
f0100ad5:	e9 51 fd ff ff       	jmp    f010082b <alltraps>

f0100ada <vector74>:
.globl vector74
vector74:
  pushl $0
f0100ada:	6a 00                	push   $0x0
  pushl $74
f0100adc:	6a 4a                	push   $0x4a
  jmp alltraps
f0100ade:	e9 48 fd ff ff       	jmp    f010082b <alltraps>

f0100ae3 <vector75>:
.globl vector75
vector75:
  pushl $0
f0100ae3:	6a 00                	push   $0x0
  pushl $75
f0100ae5:	6a 4b                	push   $0x4b
  jmp alltraps
f0100ae7:	e9 3f fd ff ff       	jmp    f010082b <alltraps>

f0100aec <vector76>:
.globl vector76
vector76:
  pushl $0
f0100aec:	6a 00                	push   $0x0
  pushl $76
f0100aee:	6a 4c                	push   $0x4c
  jmp alltraps
f0100af0:	e9 36 fd ff ff       	jmp    f010082b <alltraps>

f0100af5 <vector77>:
.globl vector77
vector77:
  pushl $0
f0100af5:	6a 00                	push   $0x0
  pushl $77
f0100af7:	6a 4d                	push   $0x4d
  jmp alltraps
f0100af9:	e9 2d fd ff ff       	jmp    f010082b <alltraps>

f0100afe <vector78>:
.globl vector78
vector78:
  pushl $0
f0100afe:	6a 00                	push   $0x0
  pushl $78
f0100b00:	6a 4e                	push   $0x4e
  jmp alltraps
f0100b02:	e9 24 fd ff ff       	jmp    f010082b <alltraps>

f0100b07 <vector79>:
.globl vector79
vector79:
  pushl $0
f0100b07:	6a 00                	push   $0x0
  pushl $79
f0100b09:	6a 4f                	push   $0x4f
  jmp alltraps
f0100b0b:	e9 1b fd ff ff       	jmp    f010082b <alltraps>

f0100b10 <vector80>:
.globl vector80
vector80:
  pushl $0
f0100b10:	6a 00                	push   $0x0
  pushl $80
f0100b12:	6a 50                	push   $0x50
  jmp alltraps
f0100b14:	e9 12 fd ff ff       	jmp    f010082b <alltraps>

f0100b19 <vector81>:
.globl vector81
vector81:
  pushl $0
f0100b19:	6a 00                	push   $0x0
  pushl $81
f0100b1b:	6a 51                	push   $0x51
  jmp alltraps
f0100b1d:	e9 09 fd ff ff       	jmp    f010082b <alltraps>

f0100b22 <vector82>:
.globl vector82
vector82:
  pushl $0
f0100b22:	6a 00                	push   $0x0
  pushl $82
f0100b24:	6a 52                	push   $0x52
  jmp alltraps
f0100b26:	e9 00 fd ff ff       	jmp    f010082b <alltraps>

f0100b2b <vector83>:
.globl vector83
vector83:
  pushl $0
f0100b2b:	6a 00                	push   $0x0
  pushl $83
f0100b2d:	6a 53                	push   $0x53
  jmp alltraps
f0100b2f:	e9 f7 fc ff ff       	jmp    f010082b <alltraps>

f0100b34 <vector84>:
.globl vector84
vector84:
  pushl $0
f0100b34:	6a 00                	push   $0x0
  pushl $84
f0100b36:	6a 54                	push   $0x54
  jmp alltraps
f0100b38:	e9 ee fc ff ff       	jmp    f010082b <alltraps>

f0100b3d <vector85>:
.globl vector85
vector85:
  pushl $0
f0100b3d:	6a 00                	push   $0x0
  pushl $85
f0100b3f:	6a 55                	push   $0x55
  jmp alltraps
f0100b41:	e9 e5 fc ff ff       	jmp    f010082b <alltraps>

f0100b46 <vector86>:
.globl vector86
vector86:
  pushl $0
f0100b46:	6a 00                	push   $0x0
  pushl $86
f0100b48:	6a 56                	push   $0x56
  jmp alltraps
f0100b4a:	e9 dc fc ff ff       	jmp    f010082b <alltraps>

f0100b4f <vector87>:
.globl vector87
vector87:
  pushl $0
f0100b4f:	6a 00                	push   $0x0
  pushl $87
f0100b51:	6a 57                	push   $0x57
  jmp alltraps
f0100b53:	e9 d3 fc ff ff       	jmp    f010082b <alltraps>

f0100b58 <vector88>:
.globl vector88
vector88:
  pushl $0
f0100b58:	6a 00                	push   $0x0
  pushl $88
f0100b5a:	6a 58                	push   $0x58
  jmp alltraps
f0100b5c:	e9 ca fc ff ff       	jmp    f010082b <alltraps>

f0100b61 <vector89>:
.globl vector89
vector89:
  pushl $0
f0100b61:	6a 00                	push   $0x0
  pushl $89
f0100b63:	6a 59                	push   $0x59
  jmp alltraps
f0100b65:	e9 c1 fc ff ff       	jmp    f010082b <alltraps>

f0100b6a <vector90>:
.globl vector90
vector90:
  pushl $0
f0100b6a:	6a 00                	push   $0x0
  pushl $90
f0100b6c:	6a 5a                	push   $0x5a
  jmp alltraps
f0100b6e:	e9 b8 fc ff ff       	jmp    f010082b <alltraps>

f0100b73 <vector91>:
.globl vector91
vector91:
  pushl $0
f0100b73:	6a 00                	push   $0x0
  pushl $91
f0100b75:	6a 5b                	push   $0x5b
  jmp alltraps
f0100b77:	e9 af fc ff ff       	jmp    f010082b <alltraps>

f0100b7c <vector92>:
.globl vector92
vector92:
  pushl $0
f0100b7c:	6a 00                	push   $0x0
  pushl $92
f0100b7e:	6a 5c                	push   $0x5c
  jmp alltraps
f0100b80:	e9 a6 fc ff ff       	jmp    f010082b <alltraps>

f0100b85 <vector93>:
.globl vector93
vector93:
  pushl $0
f0100b85:	6a 00                	push   $0x0
  pushl $93
f0100b87:	6a 5d                	push   $0x5d
  jmp alltraps
f0100b89:	e9 9d fc ff ff       	jmp    f010082b <alltraps>

f0100b8e <vector94>:
.globl vector94
vector94:
  pushl $0
f0100b8e:	6a 00                	push   $0x0
  pushl $94
f0100b90:	6a 5e                	push   $0x5e
  jmp alltraps
f0100b92:	e9 94 fc ff ff       	jmp    f010082b <alltraps>

f0100b97 <vector95>:
.globl vector95
vector95:
  pushl $0
f0100b97:	6a 00                	push   $0x0
  pushl $95
f0100b99:	6a 5f                	push   $0x5f
  jmp alltraps
f0100b9b:	e9 8b fc ff ff       	jmp    f010082b <alltraps>

f0100ba0 <vector96>:
.globl vector96
vector96:
  pushl $0
f0100ba0:	6a 00                	push   $0x0
  pushl $96
f0100ba2:	6a 60                	push   $0x60
  jmp alltraps
f0100ba4:	e9 82 fc ff ff       	jmp    f010082b <alltraps>

f0100ba9 <vector97>:
.globl vector97
vector97:
  pushl $0
f0100ba9:	6a 00                	push   $0x0
  pushl $97
f0100bab:	6a 61                	push   $0x61
  jmp alltraps
f0100bad:	e9 79 fc ff ff       	jmp    f010082b <alltraps>

f0100bb2 <vector98>:
.globl vector98
vector98:
  pushl $0
f0100bb2:	6a 00                	push   $0x0
  pushl $98
f0100bb4:	6a 62                	push   $0x62
  jmp alltraps
f0100bb6:	e9 70 fc ff ff       	jmp    f010082b <alltraps>

f0100bbb <vector99>:
.globl vector99
vector99:
  pushl $0
f0100bbb:	6a 00                	push   $0x0
  pushl $99
f0100bbd:	6a 63                	push   $0x63
  jmp alltraps
f0100bbf:	e9 67 fc ff ff       	jmp    f010082b <alltraps>

f0100bc4 <vector100>:
.globl vector100
vector100:
  pushl $0
f0100bc4:	6a 00                	push   $0x0
  pushl $100
f0100bc6:	6a 64                	push   $0x64
  jmp alltraps
f0100bc8:	e9 5e fc ff ff       	jmp    f010082b <alltraps>

f0100bcd <vector101>:
.globl vector101
vector101:
  pushl $0
f0100bcd:	6a 00                	push   $0x0
  pushl $101
f0100bcf:	6a 65                	push   $0x65
  jmp alltraps
f0100bd1:	e9 55 fc ff ff       	jmp    f010082b <alltraps>

f0100bd6 <vector102>:
.globl vector102
vector102:
  pushl $0
f0100bd6:	6a 00                	push   $0x0
  pushl $102
f0100bd8:	6a 66                	push   $0x66
  jmp alltraps
f0100bda:	e9 4c fc ff ff       	jmp    f010082b <alltraps>

f0100bdf <vector103>:
.globl vector103
vector103:
  pushl $0
f0100bdf:	6a 00                	push   $0x0
  pushl $103
f0100be1:	6a 67                	push   $0x67
  jmp alltraps
f0100be3:	e9 43 fc ff ff       	jmp    f010082b <alltraps>

f0100be8 <vector104>:
.globl vector104
vector104:
  pushl $0
f0100be8:	6a 00                	push   $0x0
  pushl $104
f0100bea:	6a 68                	push   $0x68
  jmp alltraps
f0100bec:	e9 3a fc ff ff       	jmp    f010082b <alltraps>

f0100bf1 <vector105>:
.globl vector105
vector105:
  pushl $0
f0100bf1:	6a 00                	push   $0x0
  pushl $105
f0100bf3:	6a 69                	push   $0x69
  jmp alltraps
f0100bf5:	e9 31 fc ff ff       	jmp    f010082b <alltraps>

f0100bfa <vector106>:
.globl vector106
vector106:
  pushl $0
f0100bfa:	6a 00                	push   $0x0
  pushl $106
f0100bfc:	6a 6a                	push   $0x6a
  jmp alltraps
f0100bfe:	e9 28 fc ff ff       	jmp    f010082b <alltraps>

f0100c03 <vector107>:
.globl vector107
vector107:
  pushl $0
f0100c03:	6a 00                	push   $0x0
  pushl $107
f0100c05:	6a 6b                	push   $0x6b
  jmp alltraps
f0100c07:	e9 1f fc ff ff       	jmp    f010082b <alltraps>

f0100c0c <vector108>:
.globl vector108
vector108:
  pushl $0
f0100c0c:	6a 00                	push   $0x0
  pushl $108
f0100c0e:	6a 6c                	push   $0x6c
  jmp alltraps
f0100c10:	e9 16 fc ff ff       	jmp    f010082b <alltraps>

f0100c15 <vector109>:
.globl vector109
vector109:
  pushl $0
f0100c15:	6a 00                	push   $0x0
  pushl $109
f0100c17:	6a 6d                	push   $0x6d
  jmp alltraps
f0100c19:	e9 0d fc ff ff       	jmp    f010082b <alltraps>

f0100c1e <vector110>:
.globl vector110
vector110:
  pushl $0
f0100c1e:	6a 00                	push   $0x0
  pushl $110
f0100c20:	6a 6e                	push   $0x6e
  jmp alltraps
f0100c22:	e9 04 fc ff ff       	jmp    f010082b <alltraps>

f0100c27 <vector111>:
.globl vector111
vector111:
  pushl $0
f0100c27:	6a 00                	push   $0x0
  pushl $111
f0100c29:	6a 6f                	push   $0x6f
  jmp alltraps
f0100c2b:	e9 fb fb ff ff       	jmp    f010082b <alltraps>

f0100c30 <vector112>:
.globl vector112
vector112:
  pushl $0
f0100c30:	6a 00                	push   $0x0
  pushl $112
f0100c32:	6a 70                	push   $0x70
  jmp alltraps
f0100c34:	e9 f2 fb ff ff       	jmp    f010082b <alltraps>

f0100c39 <vector113>:
.globl vector113
vector113:
  pushl $0
f0100c39:	6a 00                	push   $0x0
  pushl $113
f0100c3b:	6a 71                	push   $0x71
  jmp alltraps
f0100c3d:	e9 e9 fb ff ff       	jmp    f010082b <alltraps>

f0100c42 <vector114>:
.globl vector114
vector114:
  pushl $0
f0100c42:	6a 00                	push   $0x0
  pushl $114
f0100c44:	6a 72                	push   $0x72
  jmp alltraps
f0100c46:	e9 e0 fb ff ff       	jmp    f010082b <alltraps>

f0100c4b <vector115>:
.globl vector115
vector115:
  pushl $0
f0100c4b:	6a 00                	push   $0x0
  pushl $115
f0100c4d:	6a 73                	push   $0x73
  jmp alltraps
f0100c4f:	e9 d7 fb ff ff       	jmp    f010082b <alltraps>

f0100c54 <vector116>:
.globl vector116
vector116:
  pushl $0
f0100c54:	6a 00                	push   $0x0
  pushl $116
f0100c56:	6a 74                	push   $0x74
  jmp alltraps
f0100c58:	e9 ce fb ff ff       	jmp    f010082b <alltraps>

f0100c5d <vector117>:
.globl vector117
vector117:
  pushl $0
f0100c5d:	6a 00                	push   $0x0
  pushl $117
f0100c5f:	6a 75                	push   $0x75
  jmp alltraps
f0100c61:	e9 c5 fb ff ff       	jmp    f010082b <alltraps>

f0100c66 <vector118>:
.globl vector118
vector118:
  pushl $0
f0100c66:	6a 00                	push   $0x0
  pushl $118
f0100c68:	6a 76                	push   $0x76
  jmp alltraps
f0100c6a:	e9 bc fb ff ff       	jmp    f010082b <alltraps>

f0100c6f <vector119>:
.globl vector119
vector119:
  pushl $0
f0100c6f:	6a 00                	push   $0x0
  pushl $119
f0100c71:	6a 77                	push   $0x77
  jmp alltraps
f0100c73:	e9 b3 fb ff ff       	jmp    f010082b <alltraps>

f0100c78 <vector120>:
.globl vector120
vector120:
  pushl $0
f0100c78:	6a 00                	push   $0x0
  pushl $120
f0100c7a:	6a 78                	push   $0x78
  jmp alltraps
f0100c7c:	e9 aa fb ff ff       	jmp    f010082b <alltraps>

f0100c81 <vector121>:
.globl vector121
vector121:
  pushl $0
f0100c81:	6a 00                	push   $0x0
  pushl $121
f0100c83:	6a 79                	push   $0x79
  jmp alltraps
f0100c85:	e9 a1 fb ff ff       	jmp    f010082b <alltraps>

f0100c8a <vector122>:
.globl vector122
vector122:
  pushl $0
f0100c8a:	6a 00                	push   $0x0
  pushl $122
f0100c8c:	6a 7a                	push   $0x7a
  jmp alltraps
f0100c8e:	e9 98 fb ff ff       	jmp    f010082b <alltraps>

f0100c93 <vector123>:
.globl vector123
vector123:
  pushl $0
f0100c93:	6a 00                	push   $0x0
  pushl $123
f0100c95:	6a 7b                	push   $0x7b
  jmp alltraps
f0100c97:	e9 8f fb ff ff       	jmp    f010082b <alltraps>

f0100c9c <vector124>:
.globl vector124
vector124:
  pushl $0
f0100c9c:	6a 00                	push   $0x0
  pushl $124
f0100c9e:	6a 7c                	push   $0x7c
  jmp alltraps
f0100ca0:	e9 86 fb ff ff       	jmp    f010082b <alltraps>

f0100ca5 <vector125>:
.globl vector125
vector125:
  pushl $0
f0100ca5:	6a 00                	push   $0x0
  pushl $125
f0100ca7:	6a 7d                	push   $0x7d
  jmp alltraps
f0100ca9:	e9 7d fb ff ff       	jmp    f010082b <alltraps>

f0100cae <vector126>:
.globl vector126
vector126:
  pushl $0
f0100cae:	6a 00                	push   $0x0
  pushl $126
f0100cb0:	6a 7e                	push   $0x7e
  jmp alltraps
f0100cb2:	e9 74 fb ff ff       	jmp    f010082b <alltraps>

f0100cb7 <vector127>:
.globl vector127
vector127:
  pushl $0
f0100cb7:	6a 00                	push   $0x0
  pushl $127
f0100cb9:	6a 7f                	push   $0x7f
  jmp alltraps
f0100cbb:	e9 6b fb ff ff       	jmp    f010082b <alltraps>

f0100cc0 <vector128>:
.globl vector128
vector128:
  pushl $0
f0100cc0:	6a 00                	push   $0x0
  pushl $128
f0100cc2:	68 80 00 00 00       	push   $0x80
  jmp alltraps
f0100cc7:	e9 5f fb ff ff       	jmp    f010082b <alltraps>

f0100ccc <vector129>:
.globl vector129
vector129:
  pushl $0
f0100ccc:	6a 00                	push   $0x0
  pushl $129
f0100cce:	68 81 00 00 00       	push   $0x81
  jmp alltraps
f0100cd3:	e9 53 fb ff ff       	jmp    f010082b <alltraps>

f0100cd8 <vector130>:
.globl vector130
vector130:
  pushl $0
f0100cd8:	6a 00                	push   $0x0
  pushl $130
f0100cda:	68 82 00 00 00       	push   $0x82
  jmp alltraps
f0100cdf:	e9 47 fb ff ff       	jmp    f010082b <alltraps>

f0100ce4 <vector131>:
.globl vector131
vector131:
  pushl $0
f0100ce4:	6a 00                	push   $0x0
  pushl $131
f0100ce6:	68 83 00 00 00       	push   $0x83
  jmp alltraps
f0100ceb:	e9 3b fb ff ff       	jmp    f010082b <alltraps>

f0100cf0 <vector132>:
.globl vector132
vector132:
  pushl $0
f0100cf0:	6a 00                	push   $0x0
  pushl $132
f0100cf2:	68 84 00 00 00       	push   $0x84
  jmp alltraps
f0100cf7:	e9 2f fb ff ff       	jmp    f010082b <alltraps>

f0100cfc <vector133>:
.globl vector133
vector133:
  pushl $0
f0100cfc:	6a 00                	push   $0x0
  pushl $133
f0100cfe:	68 85 00 00 00       	push   $0x85
  jmp alltraps
f0100d03:	e9 23 fb ff ff       	jmp    f010082b <alltraps>

f0100d08 <vector134>:
.globl vector134
vector134:
  pushl $0
f0100d08:	6a 00                	push   $0x0
  pushl $134
f0100d0a:	68 86 00 00 00       	push   $0x86
  jmp alltraps
f0100d0f:	e9 17 fb ff ff       	jmp    f010082b <alltraps>

f0100d14 <vector135>:
.globl vector135
vector135:
  pushl $0
f0100d14:	6a 00                	push   $0x0
  pushl $135
f0100d16:	68 87 00 00 00       	push   $0x87
  jmp alltraps
f0100d1b:	e9 0b fb ff ff       	jmp    f010082b <alltraps>

f0100d20 <vector136>:
.globl vector136
vector136:
  pushl $0
f0100d20:	6a 00                	push   $0x0
  pushl $136
f0100d22:	68 88 00 00 00       	push   $0x88
  jmp alltraps
f0100d27:	e9 ff fa ff ff       	jmp    f010082b <alltraps>

f0100d2c <vector137>:
.globl vector137
vector137:
  pushl $0
f0100d2c:	6a 00                	push   $0x0
  pushl $137
f0100d2e:	68 89 00 00 00       	push   $0x89
  jmp alltraps
f0100d33:	e9 f3 fa ff ff       	jmp    f010082b <alltraps>

f0100d38 <vector138>:
.globl vector138
vector138:
  pushl $0
f0100d38:	6a 00                	push   $0x0
  pushl $138
f0100d3a:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
f0100d3f:	e9 e7 fa ff ff       	jmp    f010082b <alltraps>

f0100d44 <vector139>:
.globl vector139
vector139:
  pushl $0
f0100d44:	6a 00                	push   $0x0
  pushl $139
f0100d46:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
f0100d4b:	e9 db fa ff ff       	jmp    f010082b <alltraps>

f0100d50 <vector140>:
.globl vector140
vector140:
  pushl $0
f0100d50:	6a 00                	push   $0x0
  pushl $140
f0100d52:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
f0100d57:	e9 cf fa ff ff       	jmp    f010082b <alltraps>

f0100d5c <vector141>:
.globl vector141
vector141:
  pushl $0
f0100d5c:	6a 00                	push   $0x0
  pushl $141
f0100d5e:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
f0100d63:	e9 c3 fa ff ff       	jmp    f010082b <alltraps>

f0100d68 <vector142>:
.globl vector142
vector142:
  pushl $0
f0100d68:	6a 00                	push   $0x0
  pushl $142
f0100d6a:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
f0100d6f:	e9 b7 fa ff ff       	jmp    f010082b <alltraps>

f0100d74 <vector143>:
.globl vector143
vector143:
  pushl $0
f0100d74:	6a 00                	push   $0x0
  pushl $143
f0100d76:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
f0100d7b:	e9 ab fa ff ff       	jmp    f010082b <alltraps>

f0100d80 <vector144>:
.globl vector144
vector144:
  pushl $0
f0100d80:	6a 00                	push   $0x0
  pushl $144
f0100d82:	68 90 00 00 00       	push   $0x90
  jmp alltraps
f0100d87:	e9 9f fa ff ff       	jmp    f010082b <alltraps>

f0100d8c <vector145>:
.globl vector145
vector145:
  pushl $0
f0100d8c:	6a 00                	push   $0x0
  pushl $145
f0100d8e:	68 91 00 00 00       	push   $0x91
  jmp alltraps
f0100d93:	e9 93 fa ff ff       	jmp    f010082b <alltraps>

f0100d98 <vector146>:
.globl vector146
vector146:
  pushl $0
f0100d98:	6a 00                	push   $0x0
  pushl $146
f0100d9a:	68 92 00 00 00       	push   $0x92
  jmp alltraps
f0100d9f:	e9 87 fa ff ff       	jmp    f010082b <alltraps>

f0100da4 <vector147>:
.globl vector147
vector147:
  pushl $0
f0100da4:	6a 00                	push   $0x0
  pushl $147
f0100da6:	68 93 00 00 00       	push   $0x93
  jmp alltraps
f0100dab:	e9 7b fa ff ff       	jmp    f010082b <alltraps>

f0100db0 <vector148>:
.globl vector148
vector148:
  pushl $0
f0100db0:	6a 00                	push   $0x0
  pushl $148
f0100db2:	68 94 00 00 00       	push   $0x94
  jmp alltraps
f0100db7:	e9 6f fa ff ff       	jmp    f010082b <alltraps>

f0100dbc <vector149>:
.globl vector149
vector149:
  pushl $0
f0100dbc:	6a 00                	push   $0x0
  pushl $149
f0100dbe:	68 95 00 00 00       	push   $0x95
  jmp alltraps
f0100dc3:	e9 63 fa ff ff       	jmp    f010082b <alltraps>

f0100dc8 <vector150>:
.globl vector150
vector150:
  pushl $0
f0100dc8:	6a 00                	push   $0x0
  pushl $150
f0100dca:	68 96 00 00 00       	push   $0x96
  jmp alltraps
f0100dcf:	e9 57 fa ff ff       	jmp    f010082b <alltraps>

f0100dd4 <vector151>:
.globl vector151
vector151:
  pushl $0
f0100dd4:	6a 00                	push   $0x0
  pushl $151
f0100dd6:	68 97 00 00 00       	push   $0x97
  jmp alltraps
f0100ddb:	e9 4b fa ff ff       	jmp    f010082b <alltraps>

f0100de0 <vector152>:
.globl vector152
vector152:
  pushl $0
f0100de0:	6a 00                	push   $0x0
  pushl $152
f0100de2:	68 98 00 00 00       	push   $0x98
  jmp alltraps
f0100de7:	e9 3f fa ff ff       	jmp    f010082b <alltraps>

f0100dec <vector153>:
.globl vector153
vector153:
  pushl $0
f0100dec:	6a 00                	push   $0x0
  pushl $153
f0100dee:	68 99 00 00 00       	push   $0x99
  jmp alltraps
f0100df3:	e9 33 fa ff ff       	jmp    f010082b <alltraps>

f0100df8 <vector154>:
.globl vector154
vector154:
  pushl $0
f0100df8:	6a 00                	push   $0x0
  pushl $154
f0100dfa:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
f0100dff:	e9 27 fa ff ff       	jmp    f010082b <alltraps>

f0100e04 <vector155>:
.globl vector155
vector155:
  pushl $0
f0100e04:	6a 00                	push   $0x0
  pushl $155
f0100e06:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
f0100e0b:	e9 1b fa ff ff       	jmp    f010082b <alltraps>

f0100e10 <vector156>:
.globl vector156
vector156:
  pushl $0
f0100e10:	6a 00                	push   $0x0
  pushl $156
f0100e12:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
f0100e17:	e9 0f fa ff ff       	jmp    f010082b <alltraps>

f0100e1c <vector157>:
.globl vector157
vector157:
  pushl $0
f0100e1c:	6a 00                	push   $0x0
  pushl $157
f0100e1e:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
f0100e23:	e9 03 fa ff ff       	jmp    f010082b <alltraps>

f0100e28 <vector158>:
.globl vector158
vector158:
  pushl $0
f0100e28:	6a 00                	push   $0x0
  pushl $158
f0100e2a:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
f0100e2f:	e9 f7 f9 ff ff       	jmp    f010082b <alltraps>

f0100e34 <vector159>:
.globl vector159
vector159:
  pushl $0
f0100e34:	6a 00                	push   $0x0
  pushl $159
f0100e36:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
f0100e3b:	e9 eb f9 ff ff       	jmp    f010082b <alltraps>

f0100e40 <vector160>:
.globl vector160
vector160:
  pushl $0
f0100e40:	6a 00                	push   $0x0
  pushl $160
f0100e42:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
f0100e47:	e9 df f9 ff ff       	jmp    f010082b <alltraps>

f0100e4c <vector161>:
.globl vector161
vector161:
  pushl $0
f0100e4c:	6a 00                	push   $0x0
  pushl $161
f0100e4e:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
f0100e53:	e9 d3 f9 ff ff       	jmp    f010082b <alltraps>

f0100e58 <vector162>:
.globl vector162
vector162:
  pushl $0
f0100e58:	6a 00                	push   $0x0
  pushl $162
f0100e5a:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
f0100e5f:	e9 c7 f9 ff ff       	jmp    f010082b <alltraps>

f0100e64 <vector163>:
.globl vector163
vector163:
  pushl $0
f0100e64:	6a 00                	push   $0x0
  pushl $163
f0100e66:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
f0100e6b:	e9 bb f9 ff ff       	jmp    f010082b <alltraps>

f0100e70 <vector164>:
.globl vector164
vector164:
  pushl $0
f0100e70:	6a 00                	push   $0x0
  pushl $164
f0100e72:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
f0100e77:	e9 af f9 ff ff       	jmp    f010082b <alltraps>

f0100e7c <vector165>:
.globl vector165
vector165:
  pushl $0
f0100e7c:	6a 00                	push   $0x0
  pushl $165
f0100e7e:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
f0100e83:	e9 a3 f9 ff ff       	jmp    f010082b <alltraps>

f0100e88 <vector166>:
.globl vector166
vector166:
  pushl $0
f0100e88:	6a 00                	push   $0x0
  pushl $166
f0100e8a:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
f0100e8f:	e9 97 f9 ff ff       	jmp    f010082b <alltraps>

f0100e94 <vector167>:
.globl vector167
vector167:
  pushl $0
f0100e94:	6a 00                	push   $0x0
  pushl $167
f0100e96:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
f0100e9b:	e9 8b f9 ff ff       	jmp    f010082b <alltraps>

f0100ea0 <vector168>:
.globl vector168
vector168:
  pushl $0
f0100ea0:	6a 00                	push   $0x0
  pushl $168
f0100ea2:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
f0100ea7:	e9 7f f9 ff ff       	jmp    f010082b <alltraps>

f0100eac <vector169>:
.globl vector169
vector169:
  pushl $0
f0100eac:	6a 00                	push   $0x0
  pushl $169
f0100eae:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
f0100eb3:	e9 73 f9 ff ff       	jmp    f010082b <alltraps>

f0100eb8 <vector170>:
.globl vector170
vector170:
  pushl $0
f0100eb8:	6a 00                	push   $0x0
  pushl $170
f0100eba:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
f0100ebf:	e9 67 f9 ff ff       	jmp    f010082b <alltraps>

f0100ec4 <vector171>:
.globl vector171
vector171:
  pushl $0
f0100ec4:	6a 00                	push   $0x0
  pushl $171
f0100ec6:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
f0100ecb:	e9 5b f9 ff ff       	jmp    f010082b <alltraps>

f0100ed0 <vector172>:
.globl vector172
vector172:
  pushl $0
f0100ed0:	6a 00                	push   $0x0
  pushl $172
f0100ed2:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
f0100ed7:	e9 4f f9 ff ff       	jmp    f010082b <alltraps>

f0100edc <vector173>:
.globl vector173
vector173:
  pushl $0
f0100edc:	6a 00                	push   $0x0
  pushl $173
f0100ede:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
f0100ee3:	e9 43 f9 ff ff       	jmp    f010082b <alltraps>

f0100ee8 <vector174>:
.globl vector174
vector174:
  pushl $0
f0100ee8:	6a 00                	push   $0x0
  pushl $174
f0100eea:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
f0100eef:	e9 37 f9 ff ff       	jmp    f010082b <alltraps>

f0100ef4 <vector175>:
.globl vector175
vector175:
  pushl $0
f0100ef4:	6a 00                	push   $0x0
  pushl $175
f0100ef6:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
f0100efb:	e9 2b f9 ff ff       	jmp    f010082b <alltraps>

f0100f00 <vector176>:
.globl vector176
vector176:
  pushl $0
f0100f00:	6a 00                	push   $0x0
  pushl $176
f0100f02:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
f0100f07:	e9 1f f9 ff ff       	jmp    f010082b <alltraps>

f0100f0c <vector177>:
.globl vector177
vector177:
  pushl $0
f0100f0c:	6a 00                	push   $0x0
  pushl $177
f0100f0e:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
f0100f13:	e9 13 f9 ff ff       	jmp    f010082b <alltraps>

f0100f18 <vector178>:
.globl vector178
vector178:
  pushl $0
f0100f18:	6a 00                	push   $0x0
  pushl $178
f0100f1a:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
f0100f1f:	e9 07 f9 ff ff       	jmp    f010082b <alltraps>

f0100f24 <vector179>:
.globl vector179
vector179:
  pushl $0
f0100f24:	6a 00                	push   $0x0
  pushl $179
f0100f26:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
f0100f2b:	e9 fb f8 ff ff       	jmp    f010082b <alltraps>

f0100f30 <vector180>:
.globl vector180
vector180:
  pushl $0
f0100f30:	6a 00                	push   $0x0
  pushl $180
f0100f32:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
f0100f37:	e9 ef f8 ff ff       	jmp    f010082b <alltraps>

f0100f3c <vector181>:
.globl vector181
vector181:
  pushl $0
f0100f3c:	6a 00                	push   $0x0
  pushl $181
f0100f3e:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
f0100f43:	e9 e3 f8 ff ff       	jmp    f010082b <alltraps>

f0100f48 <vector182>:
.globl vector182
vector182:
  pushl $0
f0100f48:	6a 00                	push   $0x0
  pushl $182
f0100f4a:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
f0100f4f:	e9 d7 f8 ff ff       	jmp    f010082b <alltraps>

f0100f54 <vector183>:
.globl vector183
vector183:
  pushl $0
f0100f54:	6a 00                	push   $0x0
  pushl $183
f0100f56:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
f0100f5b:	e9 cb f8 ff ff       	jmp    f010082b <alltraps>

f0100f60 <vector184>:
.globl vector184
vector184:
  pushl $0
f0100f60:	6a 00                	push   $0x0
  pushl $184
f0100f62:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
f0100f67:	e9 bf f8 ff ff       	jmp    f010082b <alltraps>

f0100f6c <vector185>:
.globl vector185
vector185:
  pushl $0
f0100f6c:	6a 00                	push   $0x0
  pushl $185
f0100f6e:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
f0100f73:	e9 b3 f8 ff ff       	jmp    f010082b <alltraps>

f0100f78 <vector186>:
.globl vector186
vector186:
  pushl $0
f0100f78:	6a 00                	push   $0x0
  pushl $186
f0100f7a:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
f0100f7f:	e9 a7 f8 ff ff       	jmp    f010082b <alltraps>

f0100f84 <vector187>:
.globl vector187
vector187:
  pushl $0
f0100f84:	6a 00                	push   $0x0
  pushl $187
f0100f86:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
f0100f8b:	e9 9b f8 ff ff       	jmp    f010082b <alltraps>

f0100f90 <vector188>:
.globl vector188
vector188:
  pushl $0
f0100f90:	6a 00                	push   $0x0
  pushl $188
f0100f92:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
f0100f97:	e9 8f f8 ff ff       	jmp    f010082b <alltraps>

f0100f9c <vector189>:
.globl vector189
vector189:
  pushl $0
f0100f9c:	6a 00                	push   $0x0
  pushl $189
f0100f9e:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
f0100fa3:	e9 83 f8 ff ff       	jmp    f010082b <alltraps>

f0100fa8 <vector190>:
.globl vector190
vector190:
  pushl $0
f0100fa8:	6a 00                	push   $0x0
  pushl $190
f0100faa:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
f0100faf:	e9 77 f8 ff ff       	jmp    f010082b <alltraps>

f0100fb4 <vector191>:
.globl vector191
vector191:
  pushl $0
f0100fb4:	6a 00                	push   $0x0
  pushl $191
f0100fb6:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
f0100fbb:	e9 6b f8 ff ff       	jmp    f010082b <alltraps>

f0100fc0 <vector192>:
.globl vector192
vector192:
  pushl $0
f0100fc0:	6a 00                	push   $0x0
  pushl $192
f0100fc2:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
f0100fc7:	e9 5f f8 ff ff       	jmp    f010082b <alltraps>

f0100fcc <vector193>:
.globl vector193
vector193:
  pushl $0
f0100fcc:	6a 00                	push   $0x0
  pushl $193
f0100fce:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
f0100fd3:	e9 53 f8 ff ff       	jmp    f010082b <alltraps>

f0100fd8 <vector194>:
.globl vector194
vector194:
  pushl $0
f0100fd8:	6a 00                	push   $0x0
  pushl $194
f0100fda:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
f0100fdf:	e9 47 f8 ff ff       	jmp    f010082b <alltraps>

f0100fe4 <vector195>:
.globl vector195
vector195:
  pushl $0
f0100fe4:	6a 00                	push   $0x0
  pushl $195
f0100fe6:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
f0100feb:	e9 3b f8 ff ff       	jmp    f010082b <alltraps>

f0100ff0 <vector196>:
.globl vector196
vector196:
  pushl $0
f0100ff0:	6a 00                	push   $0x0
  pushl $196
f0100ff2:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
f0100ff7:	e9 2f f8 ff ff       	jmp    f010082b <alltraps>

f0100ffc <vector197>:
.globl vector197
vector197:
  pushl $0
f0100ffc:	6a 00                	push   $0x0
  pushl $197
f0100ffe:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
f0101003:	e9 23 f8 ff ff       	jmp    f010082b <alltraps>

f0101008 <vector198>:
.globl vector198
vector198:
  pushl $0
f0101008:	6a 00                	push   $0x0
  pushl $198
f010100a:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
f010100f:	e9 17 f8 ff ff       	jmp    f010082b <alltraps>

f0101014 <vector199>:
.globl vector199
vector199:
  pushl $0
f0101014:	6a 00                	push   $0x0
  pushl $199
f0101016:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
f010101b:	e9 0b f8 ff ff       	jmp    f010082b <alltraps>

f0101020 <vector200>:
.globl vector200
vector200:
  pushl $0
f0101020:	6a 00                	push   $0x0
  pushl $200
f0101022:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
f0101027:	e9 ff f7 ff ff       	jmp    f010082b <alltraps>

f010102c <vector201>:
.globl vector201
vector201:
  pushl $0
f010102c:	6a 00                	push   $0x0
  pushl $201
f010102e:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
f0101033:	e9 f3 f7 ff ff       	jmp    f010082b <alltraps>

f0101038 <vector202>:
.globl vector202
vector202:
  pushl $0
f0101038:	6a 00                	push   $0x0
  pushl $202
f010103a:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
f010103f:	e9 e7 f7 ff ff       	jmp    f010082b <alltraps>

f0101044 <vector203>:
.globl vector203
vector203:
  pushl $0
f0101044:	6a 00                	push   $0x0
  pushl $203
f0101046:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
f010104b:	e9 db f7 ff ff       	jmp    f010082b <alltraps>

f0101050 <vector204>:
.globl vector204
vector204:
  pushl $0
f0101050:	6a 00                	push   $0x0
  pushl $204
f0101052:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
f0101057:	e9 cf f7 ff ff       	jmp    f010082b <alltraps>

f010105c <vector205>:
.globl vector205
vector205:
  pushl $0
f010105c:	6a 00                	push   $0x0
  pushl $205
f010105e:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
f0101063:	e9 c3 f7 ff ff       	jmp    f010082b <alltraps>

f0101068 <vector206>:
.globl vector206
vector206:
  pushl $0
f0101068:	6a 00                	push   $0x0
  pushl $206
f010106a:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
f010106f:	e9 b7 f7 ff ff       	jmp    f010082b <alltraps>

f0101074 <vector207>:
.globl vector207
vector207:
  pushl $0
f0101074:	6a 00                	push   $0x0
  pushl $207
f0101076:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
f010107b:	e9 ab f7 ff ff       	jmp    f010082b <alltraps>

f0101080 <vector208>:
.globl vector208
vector208:
  pushl $0
f0101080:	6a 00                	push   $0x0
  pushl $208
f0101082:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
f0101087:	e9 9f f7 ff ff       	jmp    f010082b <alltraps>

f010108c <vector209>:
.globl vector209
vector209:
  pushl $0
f010108c:	6a 00                	push   $0x0
  pushl $209
f010108e:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
f0101093:	e9 93 f7 ff ff       	jmp    f010082b <alltraps>

f0101098 <vector210>:
.globl vector210
vector210:
  pushl $0
f0101098:	6a 00                	push   $0x0
  pushl $210
f010109a:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
f010109f:	e9 87 f7 ff ff       	jmp    f010082b <alltraps>

f01010a4 <vector211>:
.globl vector211
vector211:
  pushl $0
f01010a4:	6a 00                	push   $0x0
  pushl $211
f01010a6:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
f01010ab:	e9 7b f7 ff ff       	jmp    f010082b <alltraps>

f01010b0 <vector212>:
.globl vector212
vector212:
  pushl $0
f01010b0:	6a 00                	push   $0x0
  pushl $212
f01010b2:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
f01010b7:	e9 6f f7 ff ff       	jmp    f010082b <alltraps>

f01010bc <vector213>:
.globl vector213
vector213:
  pushl $0
f01010bc:	6a 00                	push   $0x0
  pushl $213
f01010be:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
f01010c3:	e9 63 f7 ff ff       	jmp    f010082b <alltraps>

f01010c8 <vector214>:
.globl vector214
vector214:
  pushl $0
f01010c8:	6a 00                	push   $0x0
  pushl $214
f01010ca:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
f01010cf:	e9 57 f7 ff ff       	jmp    f010082b <alltraps>

f01010d4 <vector215>:
.globl vector215
vector215:
  pushl $0
f01010d4:	6a 00                	push   $0x0
  pushl $215
f01010d6:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
f01010db:	e9 4b f7 ff ff       	jmp    f010082b <alltraps>

f01010e0 <vector216>:
.globl vector216
vector216:
  pushl $0
f01010e0:	6a 00                	push   $0x0
  pushl $216
f01010e2:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
f01010e7:	e9 3f f7 ff ff       	jmp    f010082b <alltraps>

f01010ec <vector217>:
.globl vector217
vector217:
  pushl $0
f01010ec:	6a 00                	push   $0x0
  pushl $217
f01010ee:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
f01010f3:	e9 33 f7 ff ff       	jmp    f010082b <alltraps>

f01010f8 <vector218>:
.globl vector218
vector218:
  pushl $0
f01010f8:	6a 00                	push   $0x0
  pushl $218
f01010fa:	68 da 00 00 00       	push   $0xda
  jmp alltraps
f01010ff:	e9 27 f7 ff ff       	jmp    f010082b <alltraps>

f0101104 <vector219>:
.globl vector219
vector219:
  pushl $0
f0101104:	6a 00                	push   $0x0
  pushl $219
f0101106:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
f010110b:	e9 1b f7 ff ff       	jmp    f010082b <alltraps>

f0101110 <vector220>:
.globl vector220
vector220:
  pushl $0
f0101110:	6a 00                	push   $0x0
  pushl $220
f0101112:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
f0101117:	e9 0f f7 ff ff       	jmp    f010082b <alltraps>

f010111c <vector221>:
.globl vector221
vector221:
  pushl $0
f010111c:	6a 00                	push   $0x0
  pushl $221
f010111e:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
f0101123:	e9 03 f7 ff ff       	jmp    f010082b <alltraps>

f0101128 <vector222>:
.globl vector222
vector222:
  pushl $0
f0101128:	6a 00                	push   $0x0
  pushl $222
f010112a:	68 de 00 00 00       	push   $0xde
  jmp alltraps
f010112f:	e9 f7 f6 ff ff       	jmp    f010082b <alltraps>

f0101134 <vector223>:
.globl vector223
vector223:
  pushl $0
f0101134:	6a 00                	push   $0x0
  pushl $223
f0101136:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
f010113b:	e9 eb f6 ff ff       	jmp    f010082b <alltraps>

f0101140 <vector224>:
.globl vector224
vector224:
  pushl $0
f0101140:	6a 00                	push   $0x0
  pushl $224
f0101142:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
f0101147:	e9 df f6 ff ff       	jmp    f010082b <alltraps>

f010114c <vector225>:
.globl vector225
vector225:
  pushl $0
f010114c:	6a 00                	push   $0x0
  pushl $225
f010114e:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
f0101153:	e9 d3 f6 ff ff       	jmp    f010082b <alltraps>

f0101158 <vector226>:
.globl vector226
vector226:
  pushl $0
f0101158:	6a 00                	push   $0x0
  pushl $226
f010115a:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
f010115f:	e9 c7 f6 ff ff       	jmp    f010082b <alltraps>

f0101164 <vector227>:
.globl vector227
vector227:
  pushl $0
f0101164:	6a 00                	push   $0x0
  pushl $227
f0101166:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
f010116b:	e9 bb f6 ff ff       	jmp    f010082b <alltraps>

f0101170 <vector228>:
.globl vector228
vector228:
  pushl $0
f0101170:	6a 00                	push   $0x0
  pushl $228
f0101172:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
f0101177:	e9 af f6 ff ff       	jmp    f010082b <alltraps>

f010117c <vector229>:
.globl vector229
vector229:
  pushl $0
f010117c:	6a 00                	push   $0x0
  pushl $229
f010117e:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
f0101183:	e9 a3 f6 ff ff       	jmp    f010082b <alltraps>

f0101188 <vector230>:
.globl vector230
vector230:
  pushl $0
f0101188:	6a 00                	push   $0x0
  pushl $230
f010118a:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
f010118f:	e9 97 f6 ff ff       	jmp    f010082b <alltraps>

f0101194 <vector231>:
.globl vector231
vector231:
  pushl $0
f0101194:	6a 00                	push   $0x0
  pushl $231
f0101196:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
f010119b:	e9 8b f6 ff ff       	jmp    f010082b <alltraps>

f01011a0 <vector232>:
.globl vector232
vector232:
  pushl $0
f01011a0:	6a 00                	push   $0x0
  pushl $232
f01011a2:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
f01011a7:	e9 7f f6 ff ff       	jmp    f010082b <alltraps>

f01011ac <vector233>:
.globl vector233
vector233:
  pushl $0
f01011ac:	6a 00                	push   $0x0
  pushl $233
f01011ae:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
f01011b3:	e9 73 f6 ff ff       	jmp    f010082b <alltraps>

f01011b8 <vector234>:
.globl vector234
vector234:
  pushl $0
f01011b8:	6a 00                	push   $0x0
  pushl $234
f01011ba:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
f01011bf:	e9 67 f6 ff ff       	jmp    f010082b <alltraps>

f01011c4 <vector235>:
.globl vector235
vector235:
  pushl $0
f01011c4:	6a 00                	push   $0x0
  pushl $235
f01011c6:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
f01011cb:	e9 5b f6 ff ff       	jmp    f010082b <alltraps>

f01011d0 <vector236>:
.globl vector236
vector236:
  pushl $0
f01011d0:	6a 00                	push   $0x0
  pushl $236
f01011d2:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
f01011d7:	e9 4f f6 ff ff       	jmp    f010082b <alltraps>

f01011dc <vector237>:
.globl vector237
vector237:
  pushl $0
f01011dc:	6a 00                	push   $0x0
  pushl $237
f01011de:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
f01011e3:	e9 43 f6 ff ff       	jmp    f010082b <alltraps>

f01011e8 <vector238>:
.globl vector238
vector238:
  pushl $0
f01011e8:	6a 00                	push   $0x0
  pushl $238
f01011ea:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
f01011ef:	e9 37 f6 ff ff       	jmp    f010082b <alltraps>

f01011f4 <vector239>:
.globl vector239
vector239:
  pushl $0
f01011f4:	6a 00                	push   $0x0
  pushl $239
f01011f6:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
f01011fb:	e9 2b f6 ff ff       	jmp    f010082b <alltraps>

f0101200 <vector240>:
.globl vector240
vector240:
  pushl $0
f0101200:	6a 00                	push   $0x0
  pushl $240
f0101202:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
f0101207:	e9 1f f6 ff ff       	jmp    f010082b <alltraps>

f010120c <vector241>:
.globl vector241
vector241:
  pushl $0
f010120c:	6a 00                	push   $0x0
  pushl $241
f010120e:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
f0101213:	e9 13 f6 ff ff       	jmp    f010082b <alltraps>

f0101218 <vector242>:
.globl vector242
vector242:
  pushl $0
f0101218:	6a 00                	push   $0x0
  pushl $242
f010121a:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
f010121f:	e9 07 f6 ff ff       	jmp    f010082b <alltraps>

f0101224 <vector243>:
.globl vector243
vector243:
  pushl $0
f0101224:	6a 00                	push   $0x0
  pushl $243
f0101226:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
f010122b:	e9 fb f5 ff ff       	jmp    f010082b <alltraps>

f0101230 <vector244>:
.globl vector244
vector244:
  pushl $0
f0101230:	6a 00                	push   $0x0
  pushl $244
f0101232:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
f0101237:	e9 ef f5 ff ff       	jmp    f010082b <alltraps>

f010123c <vector245>:
.globl vector245
vector245:
  pushl $0
f010123c:	6a 00                	push   $0x0
  pushl $245
f010123e:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
f0101243:	e9 e3 f5 ff ff       	jmp    f010082b <alltraps>

f0101248 <vector246>:
.globl vector246
vector246:
  pushl $0
f0101248:	6a 00                	push   $0x0
  pushl $246
f010124a:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
f010124f:	e9 d7 f5 ff ff       	jmp    f010082b <alltraps>

f0101254 <vector247>:
.globl vector247
vector247:
  pushl $0
f0101254:	6a 00                	push   $0x0
  pushl $247
f0101256:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
f010125b:	e9 cb f5 ff ff       	jmp    f010082b <alltraps>

f0101260 <vector248>:
.globl vector248
vector248:
  pushl $0
f0101260:	6a 00                	push   $0x0
  pushl $248
f0101262:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
f0101267:	e9 bf f5 ff ff       	jmp    f010082b <alltraps>

f010126c <vector249>:
.globl vector249
vector249:
  pushl $0
f010126c:	6a 00                	push   $0x0
  pushl $249
f010126e:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
f0101273:	e9 b3 f5 ff ff       	jmp    f010082b <alltraps>

f0101278 <vector250>:
.globl vector250
vector250:
  pushl $0
f0101278:	6a 00                	push   $0x0
  pushl $250
f010127a:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
f010127f:	e9 a7 f5 ff ff       	jmp    f010082b <alltraps>

f0101284 <vector251>:
.globl vector251
vector251:
  pushl $0
f0101284:	6a 00                	push   $0x0
  pushl $251
f0101286:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
f010128b:	e9 9b f5 ff ff       	jmp    f010082b <alltraps>

f0101290 <vector252>:
.globl vector252
vector252:
  pushl $0
f0101290:	6a 00                	push   $0x0
  pushl $252
f0101292:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
f0101297:	e9 8f f5 ff ff       	jmp    f010082b <alltraps>

f010129c <vector253>:
.globl vector253
vector253:
  pushl $0
f010129c:	6a 00                	push   $0x0
  pushl $253
f010129e:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
f01012a3:	e9 83 f5 ff ff       	jmp    f010082b <alltraps>

f01012a8 <vector254>:
.globl vector254
vector254:
  pushl $0
f01012a8:	6a 00                	push   $0x0
  pushl $254
f01012aa:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
f01012af:	e9 77 f5 ff ff       	jmp    f010082b <alltraps>

f01012b4 <vector255>:
.globl vector255
vector255:
  pushl $0
f01012b4:	6a 00                	push   $0x0
  pushl $255
f01012b6:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
f01012bb:	e9 6b f5 ff ff       	jmp    f010082b <alltraps>

f01012c0 <pgdir_walk>:
// Hint 2: look at inc/mmu.h for useful macros that manipulate page
// table and page directory entries.
//
static pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int32_t alloc)
{
f01012c0:	55                   	push   %ebp
f01012c1:	89 e5                	mov    %esp,%ebp
f01012c3:	57                   	push   %edi
f01012c4:	56                   	push   %esi
f01012c5:	53                   	push   %ebx
f01012c6:	83 ec 0c             	sub    $0xc,%esp
f01012c9:	89 d6                	mov    %edx,%esi
	// TODO: Fill this function in
	pde_t *pde = &pgdir[PDX(va)];
f01012cb:	c1 ea 16             	shr    $0x16,%edx
f01012ce:	8d 3c 90             	lea    (%eax,%edx,4),%edi
	pte_t *pgtab;
	if ((*pde & PTE_P) == 1)
f01012d1:	8b 1f                	mov    (%edi),%ebx
f01012d3:	f6 c3 01             	test   $0x1,%bl
f01012d6:	74 21                	je     f01012f9 <pgdir_walk+0x39>
	    pgtab = (pte_t *)P2V((*pde >> 12) << 12);
f01012d8:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
f01012de:	81 eb 00 00 00 10    	sub    $0x10000000,%ebx
	    if (alloc == 0 || (pgtab = (pte_t *)kalloc()) == NULL)
	        return NULL;
	    memset(pgtab, 0, PGSIZE);
        *pde = V2P(pgtab) | PTE_P | PTE_U | PTE_W;
	}
	return &pgtab[PTX(va)];
f01012e4:	c1 ee 0a             	shr    $0xa,%esi
f01012e7:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f01012ed:	01 f3                	add    %esi,%ebx
}
f01012ef:	89 d8                	mov    %ebx,%eax
f01012f1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01012f4:	5b                   	pop    %ebx
f01012f5:	5e                   	pop    %esi
f01012f6:	5f                   	pop    %edi
f01012f7:	5d                   	pop    %ebp
f01012f8:	c3                   	ret    
	    if (alloc == 0 || (pgtab = (pte_t *)kalloc()) == NULL)
f01012f9:	85 c9                	test   %ecx,%ecx
f01012fb:	74 2b                	je     f0101328 <pgdir_walk+0x68>
f01012fd:	e8 70 07 00 00       	call   f0101a72 <kalloc>
f0101302:	89 c3                	mov    %eax,%ebx
f0101304:	85 c0                	test   %eax,%eax
f0101306:	74 e7                	je     f01012ef <pgdir_walk+0x2f>
	    memset(pgtab, 0, PGSIZE);
f0101308:	83 ec 04             	sub    $0x4,%esp
f010130b:	68 00 10 00 00       	push   $0x1000
f0101310:	6a 00                	push   $0x0
f0101312:	50                   	push   %eax
f0101313:	e8 11 1a 00 00       	call   f0102d29 <memset>
        *pde = V2P(pgtab) | PTE_P | PTE_U | PTE_W;
f0101318:	8d 83 00 00 00 10    	lea    0x10000000(%ebx),%eax
f010131e:	83 c8 07             	or     $0x7,%eax
f0101321:	89 07                	mov    %eax,(%edi)
f0101323:	83 c4 10             	add    $0x10,%esp
f0101326:	eb bc                	jmp    f01012e4 <pgdir_walk+0x24>
	        return NULL;
f0101328:	bb 00 00 00 00       	mov    $0x0,%ebx
f010132d:	eb c0                	jmp    f01012ef <pgdir_walk+0x2f>

f010132f <seg_init>:
{
f010132f:	55                   	push   %ebp
f0101330:	89 e5                	mov    %esp,%ebp
f0101332:	83 ec 18             	sub    $0x18,%esp
	thiscpu->gdt[SEG_KCODE] = SEG(STA_R | STA_X, 0, 0xffffffff, 0);
f0101335:	e8 1f 0d 00 00       	call   f0102059 <cpunum>
f010133a:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0101341:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
f0101344:	c1 e1 05             	shl    $0x5,%ecx
f0101347:	66 c7 81 98 b0 11 f0 	movw   $0xffff,-0xfee4f68(%ecx)
f010134e:	ff ff 
f0101350:	66 c7 81 9a b0 11 f0 	movw   $0x0,-0xfee4f66(%ecx)
f0101357:	00 00 
f0101359:	c6 81 9c b0 11 f0 00 	movb   $0x0,-0xfee4f64(%ecx)
f0101360:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
f0101363:	c1 e1 05             	shl    $0x5,%ecx
f0101366:	c6 81 9d b0 11 f0 9a 	movb   $0x9a,-0xfee4f63(%ecx)
f010136d:	c6 81 9e b0 11 f0 cf 	movb   $0xcf,-0xfee4f62(%ecx)
f0101374:	01 c2                	add    %eax,%edx
f0101376:	c1 e2 05             	shl    $0x5,%edx
f0101379:	c6 82 9f b0 11 f0 00 	movb   $0x0,-0xfee4f61(%edx)
	thiscpu->gdt[SEG_KDATA] = SEG(STA_W | STA_R, 0, 0xffffffff, 0);
f0101380:	e8 d4 0c 00 00       	call   f0102059 <cpunum>
f0101385:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f010138c:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
f010138f:	c1 e1 05             	shl    $0x5,%ecx
f0101392:	66 c7 81 a0 b0 11 f0 	movw   $0xffff,-0xfee4f60(%ecx)
f0101399:	ff ff 
f010139b:	66 c7 81 a2 b0 11 f0 	movw   $0x0,-0xfee4f5e(%ecx)
f01013a2:	00 00 
f01013a4:	c6 81 a4 b0 11 f0 00 	movb   $0x0,-0xfee4f5c(%ecx)
f01013ab:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
f01013ae:	c1 e1 05             	shl    $0x5,%ecx
f01013b1:	c6 81 a5 b0 11 f0 92 	movb   $0x92,-0xfee4f5b(%ecx)
f01013b8:	c6 81 a6 b0 11 f0 cf 	movb   $0xcf,-0xfee4f5a(%ecx)
f01013bf:	01 c2                	add    %eax,%edx
f01013c1:	c1 e2 05             	shl    $0x5,%edx
f01013c4:	c6 82 a7 b0 11 f0 00 	movb   $0x0,-0xfee4f59(%edx)
	thiscpu->gdt[SEG_UCODE] = SEG(STA_R | STA_X, 0, 0xffffffff, DPL_USER);
f01013cb:	e8 89 0c 00 00       	call   f0102059 <cpunum>
f01013d0:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f01013d7:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
f01013da:	c1 e1 05             	shl    $0x5,%ecx
f01013dd:	66 c7 81 a8 b0 11 f0 	movw   $0xffff,-0xfee4f58(%ecx)
f01013e4:	ff ff 
f01013e6:	66 c7 81 aa b0 11 f0 	movw   $0x0,-0xfee4f56(%ecx)
f01013ed:	00 00 
f01013ef:	c6 81 ac b0 11 f0 00 	movb   $0x0,-0xfee4f54(%ecx)
f01013f6:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
f01013f9:	c1 e1 05             	shl    $0x5,%ecx
f01013fc:	c6 81 ad b0 11 f0 fa 	movb   $0xfa,-0xfee4f53(%ecx)
f0101403:	c6 81 ae b0 11 f0 cf 	movb   $0xcf,-0xfee4f52(%ecx)
f010140a:	01 c2                	add    %eax,%edx
f010140c:	c1 e2 05             	shl    $0x5,%edx
f010140f:	c6 82 af b0 11 f0 00 	movb   $0x0,-0xfee4f51(%edx)
	thiscpu->gdt[SEG_UDATA] = SEG(STA_R | STA_W, 0, 0xffffffff, DPL_USER);
f0101416:	e8 3e 0c 00 00       	call   f0102059 <cpunum>
f010141b:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0101422:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
f0101425:	c1 e1 05             	shl    $0x5,%ecx
f0101428:	66 c7 81 b0 b0 11 f0 	movw   $0xffff,-0xfee4f50(%ecx)
f010142f:	ff ff 
f0101431:	66 c7 81 b2 b0 11 f0 	movw   $0x0,-0xfee4f4e(%ecx)
f0101438:	00 00 
f010143a:	c6 81 b4 b0 11 f0 00 	movb   $0x0,-0xfee4f4c(%ecx)
f0101441:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
f0101444:	c1 e1 05             	shl    $0x5,%ecx
f0101447:	c6 81 b5 b0 11 f0 f2 	movb   $0xf2,-0xfee4f4b(%ecx)
f010144e:	c6 81 b6 b0 11 f0 cf 	movb   $0xcf,-0xfee4f4a(%ecx)
f0101455:	01 c2                	add    %eax,%edx
f0101457:	c1 e2 05             	shl    $0x5,%edx
f010145a:	c6 82 b7 b0 11 f0 00 	movb   $0x0,-0xfee4f49(%edx)
	lgdt(thiscpu->gdt, sizeof(thiscpu->gdt));
f0101461:	e8 f3 0b 00 00       	call   f0102059 <cpunum>
f0101466:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0101469:	c1 e0 05             	shl    $0x5,%eax
f010146c:	05 90 b0 11 f0       	add    $0xf011b090,%eax
	pd[0] = size-1;
f0101471:	66 c7 45 f2 2f 00    	movw   $0x2f,-0xe(%ebp)
	pd[1] = (unsigned)p;
f0101477:	66 89 45 f4          	mov    %ax,-0xc(%ebp)
	pd[2] = (unsigned)p >> 16;
f010147b:	c1 e8 10             	shr    $0x10,%eax
f010147e:	66 89 45 f6          	mov    %ax,-0xa(%ebp)
	asm volatile("lgdt (%0)" : : "r" (pd));
f0101482:	8d 45 f2             	lea    -0xe(%ebp),%eax
f0101485:	0f 01 10             	lgdtl  (%eax)
}
f0101488:	c9                   	leave  
f0101489:	c3                   	ret    

f010148a <kvm_init>:
//			for each item of kmap[];
//
// Hint: You may need ARRAY_SIZE.
pde_t *
kvm_init(void)
{
f010148a:	55                   	push   %ebp
f010148b:	89 e5                	mov    %esp,%ebp
f010148d:	57                   	push   %edi
f010148e:	56                   	push   %esi
f010148f:	53                   	push   %ebx
f0101490:	83 ec 1c             	sub    $0x1c,%esp
	// TODO: your code here
	pde_t *pgdirinit = (pde_t *)kalloc();
f0101493:	e8 da 05 00 00       	call   f0101a72 <kalloc>
f0101498:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	if (pgdirinit) {
f010149b:	85 c0                	test   %eax,%eax
f010149d:	74 2f                	je     f01014ce <kvm_init+0x44>
	    memset(pgdirinit, 0, PGSIZE);
f010149f:	83 ec 04             	sub    $0x4,%esp
f01014a2:	68 00 10 00 00       	push   $0x1000
f01014a7:	6a 00                	push   $0x0
f01014a9:	50                   	push   %eax
f01014aa:	e8 7a 18 00 00       	call   f0102d29 <memset>
f01014af:	bf c0 34 10 f0       	mov    $0xf01034c0,%edi
f01014b4:	83 c4 10             	add    $0x10,%esp
f01014b7:	eb 2e                	jmp    f01014e7 <kvm_init+0x5d>
		for (int i = 0; i < ARRAY_SIZE(kmap); i++)
			if (map_region(pgdirinit, kmap[i].virt, kmap[i].phys_end - kmap[i].phys_start, kmap[i].phys_start, kmap[i].perm) < 0) {
                //cprintf("The %dth is wrong.\n", i);
				kfree((char *)pgdirinit);
f01014b9:	83 ec 0c             	sub    $0xc,%esp
f01014bc:	ff 75 e4             	pushl  -0x1c(%ebp)
f01014bf:	e8 c9 03 00 00       	call   f010188d <kfree>
                return 0;
f01014c4:	83 c4 10             	add    $0x10,%esp
f01014c7:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
			}
		return pgdirinit;
	} else
		return 0;
}
f01014ce:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01014d1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01014d4:	5b                   	pop    %ebx
f01014d5:	5e                   	pop    %esi
f01014d6:	5f                   	pop    %edi
f01014d7:	5d                   	pop    %ebp
f01014d8:	c3                   	ret    
f01014d9:	8b 7d dc             	mov    -0x24(%ebp),%edi
f01014dc:	83 c7 10             	add    $0x10,%edi
		for (int i = 0; i < ARRAY_SIZE(kmap); i++)
f01014df:	81 ff 00 35 10 f0    	cmp    $0xf0103500,%edi
f01014e5:	74 e7                	je     f01014ce <kvm_init+0x44>
			if (map_region(pgdirinit, kmap[i].virt, kmap[i].phys_end - kmap[i].phys_start, kmap[i].phys_start, kmap[i].perm) < 0) {
f01014e7:	8b 57 04             	mov    0x4(%edi),%edx
	char *align = ROUNDUP(va, PGSIZE);
f01014ea:	8b 07                	mov    (%edi),%eax
f01014ec:	8d b0 ff 0f 00 00    	lea    0xfff(%eax),%esi
f01014f2:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	uint32_t alignsize = ROUNDUP(size, PGSIZE);
f01014f8:	8b 47 08             	mov    0x8(%edi),%eax
f01014fb:	05 ff 0f 00 00       	add    $0xfff,%eax
f0101500:	29 d0                	sub    %edx,%eax
f0101502:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0101507:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
f010150a:	89 d3                	mov    %edx,%ebx
f010150c:	29 d6                	sub    %edx,%esi
		*pte = pa | perm | PTE_P;
f010150e:	8b 47 0c             	mov    0xc(%edi),%eax
f0101511:	83 c8 01             	or     $0x1,%eax
f0101514:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101517:	89 7d dc             	mov    %edi,-0x24(%ebp)
f010151a:	89 cf                	mov    %ecx,%edi
f010151c:	8d 14 1e             	lea    (%esi,%ebx,1),%edx
	while (alignsize) {
f010151f:	39 fb                	cmp    %edi,%ebx
f0101521:	74 b6                	je     f01014d9 <kvm_init+0x4f>
		pte_t *pte = pgdir_walk(pgdir, align, 1);
f0101523:	b9 01 00 00 00       	mov    $0x1,%ecx
f0101528:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010152b:	e8 90 fd ff ff       	call   f01012c0 <pgdir_walk>
		if (pte == NULL)
f0101530:	85 c0                	test   %eax,%eax
f0101532:	74 85                	je     f01014b9 <kvm_init+0x2f>
		*pte = pa | perm | PTE_P;
f0101534:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0101537:	09 da                	or     %ebx,%edx
f0101539:	89 10                	mov    %edx,(%eax)
		pa += PGSIZE;
f010153b:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0101541:	eb d9                	jmp    f010151c <kvm_init+0x92>

f0101543 <kvm_switch>:

// Switch h/w page table register to the kernel-only page table.
void
kvm_switch(void)
{
f0101543:	55                   	push   %ebp
f0101544:	89 e5                	mov    %esp,%ebp
	lcr3(V2P(kpgdir)); // switch to the kernel page table
f0101546:	a1 90 ae 11 f0       	mov    0xf011ae90,%eax
f010154b:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0101550:	0f 22 d8             	mov    %eax,%cr3
}
f0101553:	5d                   	pop    %ebp
f0101554:	c3                   	ret    

f0101555 <check_vm>:

void
check_vm(pde_t *pgdir)
{
f0101555:	55                   	push   %ebp
f0101556:	89 e5                	mov    %esp,%ebp
f0101558:	57                   	push   %edi
f0101559:	56                   	push   %esi
f010155a:	53                   	push   %ebx
f010155b:	83 ec 1c             	sub    $0x1c,%esp
f010155e:	c7 45 e4 c0 34 10 f0 	movl   $0xf01034c0,-0x1c(%ebp)
f0101565:	eb 3e                	jmp    f01015a5 <check_vm+0x50>
		uint32_t alignsize = ROUNDUP(kmap[i].phys_end - kmap[i].phys_start, PGSIZE);
		uint32_t pa = kmap[i].phys_start;
		while(alignsize) {
			pte_t *pte = pgdir_walk(pgdir, align, 1);
			if (pte == NULL) 
				panic("vm_fail: Do not find the page table entry");
f0101567:	83 ec 04             	sub    $0x4,%esp
f010156a:	68 40 34 10 f0       	push   $0xf0103440
f010156f:	68 ae 00 00 00       	push   $0xae
f0101574:	68 6a 34 10 f0       	push   $0xf010346a
f0101579:	e8 13 ec ff ff       	call   f0100191 <_panic>
			pte_t tmp = (*pte >> 12) << 12;
			assert(tmp == pa);
f010157e:	68 74 34 10 f0       	push   $0xf0103474
f0101583:	68 7e 34 10 f0       	push   $0xf010347e
f0101588:	68 b0 00 00 00       	push   $0xb0
f010158d:	68 6a 34 10 f0       	push   $0xf010346a
f0101592:	e8 fa eb ff ff       	call   f0100191 <_panic>
f0101597:	83 45 e4 10          	addl   $0x10,-0x1c(%ebp)
f010159b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
	for (int i = 0; i < ARRAY_SIZE(kmap); i++) {
f010159e:	3d 00 35 10 f0       	cmp    $0xf0103500,%eax
f01015a3:	74 67                	je     f010160c <check_vm+0xb7>
		char *align = ROUNDUP(kmap[i].virt, PGSIZE);
f01015a5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01015a8:	8b 08                	mov    (%eax),%ecx
f01015aa:	89 cf                	mov    %ecx,%edi
f01015ac:	81 c7 ff 0f 00 00    	add    $0xfff,%edi
f01015b2:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
		uint32_t alignsize = ROUNDUP(kmap[i].phys_end - kmap[i].phys_start, PGSIZE);
f01015b8:	89 c1                	mov    %eax,%ecx
f01015ba:	8b 40 04             	mov    0x4(%eax),%eax
f01015bd:	8b 49 08             	mov    0x8(%ecx),%ecx
f01015c0:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01015c3:	89 ce                	mov    %ecx,%esi
f01015c5:	81 c6 ff 0f 00 00    	add    $0xfff,%esi
f01015cb:	29 c6                	sub    %eax,%esi
f01015cd:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
f01015d3:	01 c6                	add    %eax,%esi
		uint32_t pa = kmap[i].phys_start;
f01015d5:	89 c3                	mov    %eax,%ebx
f01015d7:	29 c7                	sub    %eax,%edi
f01015d9:	8d 14 1f             	lea    (%edi,%ebx,1),%edx
		while(alignsize) {
f01015dc:	39 de                	cmp    %ebx,%esi
f01015de:	74 b7                	je     f0101597 <check_vm+0x42>
			pte_t *pte = pgdir_walk(pgdir, align, 1);
f01015e0:	b9 01 00 00 00       	mov    $0x1,%ecx
f01015e5:	8b 45 08             	mov    0x8(%ebp),%eax
f01015e8:	e8 d3 fc ff ff       	call   f01012c0 <pgdir_walk>
			if (pte == NULL) 
f01015ed:	85 c0                	test   %eax,%eax
f01015ef:	0f 84 72 ff ff ff    	je     f0101567 <check_vm+0x12>
			pte_t tmp = (*pte >> 12) << 12;
f01015f5:	8b 00                	mov    (%eax),%eax
f01015f7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
			assert(tmp == pa);
f01015fc:	39 c3                	cmp    %eax,%ebx
f01015fe:	0f 85 7a ff ff ff    	jne    f010157e <check_vm+0x29>
			align += PGSIZE;
			pa += PGSIZE;
f0101604:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010160a:	eb cd                	jmp    f01015d9 <check_vm+0x84>
			alignsize -= PGSIZE;
		}
	}
}
f010160c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010160f:	5b                   	pop    %ebx
f0101610:	5e                   	pop    %esi
f0101611:	5f                   	pop    %edi
f0101612:	5d                   	pop    %ebp
f0101613:	c3                   	ret    

f0101614 <vm_init>:

// Allocate one page table for the machine for the kernel address
// space.
void
vm_init(void)
{
f0101614:	55                   	push   %ebp
f0101615:	89 e5                	mov    %esp,%ebp
f0101617:	83 ec 08             	sub    $0x8,%esp
	kpgdir = kvm_init();
f010161a:	e8 6b fe ff ff       	call   f010148a <kvm_init>
f010161f:	a3 90 ae 11 f0       	mov    %eax,0xf011ae90
	if (kpgdir == 0)
f0101624:	85 c0                	test   %eax,%eax
f0101626:	74 13                	je     f010163b <vm_init+0x27>
		panic("vm_init: failure");
	check_vm(kpgdir);
f0101628:	83 ec 0c             	sub    $0xc,%esp
f010162b:	50                   	push   %eax
f010162c:	e8 24 ff ff ff       	call   f0101555 <check_vm>
	kvm_switch();
f0101631:	e8 0d ff ff ff       	call   f0101543 <kvm_switch>
}
f0101636:	83 c4 10             	add    $0x10,%esp
f0101639:	c9                   	leave  
f010163a:	c3                   	ret    
		panic("vm_init: failure");
f010163b:	83 ec 04             	sub    $0x4,%esp
f010163e:	68 93 34 10 f0       	push   $0xf0103493
f0101643:	68 bf 00 00 00       	push   $0xbf
f0101648:	68 6a 34 10 f0       	push   $0xf010346a
f010164d:	e8 3f eb ff ff       	call   f0100191 <_panic>

f0101652 <vm_free>:
// Free a page table.
//
// Hint: You need to free all existing PTEs for this pgdir.
void
vm_free(pde_t *pgdir)
{
f0101652:	55                   	push   %ebp
f0101653:	89 e5                	mov    %esp,%ebp
f0101655:	57                   	push   %edi
f0101656:	56                   	push   %esi
f0101657:	53                   	push   %ebx
f0101658:	83 ec 0c             	sub    $0xc,%esp
f010165b:	8b 7d 08             	mov    0x8(%ebp),%edi
f010165e:	89 fb                	mov    %edi,%ebx
f0101660:	8d b7 00 10 00 00    	lea    0x1000(%edi),%esi
f0101666:	eb 07                	jmp    f010166f <vm_free+0x1d>
f0101668:	83 c3 04             	add    $0x4,%ebx
	// TODO: your code here
	for (int i = 0; i < 1024; i++) {
f010166b:	39 f3                	cmp    %esi,%ebx
f010166d:	74 1e                	je     f010168d <vm_free+0x3b>
	    if (pgdir[i] & PTE_P) {
f010166f:	8b 03                	mov    (%ebx),%eax
f0101671:	a8 01                	test   $0x1,%al
f0101673:	74 f3                	je     f0101668 <vm_free+0x16>
	        char *v = P2V((pgdir[i] >> 12) << 12);
	        kfree(v);
f0101675:	83 ec 0c             	sub    $0xc,%esp
	        char *v = P2V((pgdir[i] >> 12) << 12);
f0101678:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010167d:	2d 00 00 00 10       	sub    $0x10000000,%eax
	        kfree(v);
f0101682:	50                   	push   %eax
f0101683:	e8 05 02 00 00       	call   f010188d <kfree>
f0101688:	83 c4 10             	add    $0x10,%esp
f010168b:	eb db                	jmp    f0101668 <vm_free+0x16>
	    }
	}
	kfree((char *)pgdir);
f010168d:	83 ec 0c             	sub    $0xc,%esp
f0101690:	57                   	push   %edi
f0101691:	e8 f7 01 00 00       	call   f010188d <kfree>
}
f0101696:	83 c4 10             	add    $0x10,%esp
f0101699:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010169c:	5b                   	pop    %ebx
f010169d:	5e                   	pop    %esi
f010169e:	5f                   	pop    %edi
f010169f:	5d                   	pop    %ebp
f01016a0:	c3                   	ret    

f01016a1 <pow_2>:
// the pages mapped by entrypgdir on free list.
// 2. Call alloc_init() with the rest of the physical pages after
// installing a full page table.

int pow_2(int power)
{
f01016a1:	55                   	push   %ebp
f01016a2:	89 e5                	mov    %esp,%ebp
f01016a4:	8b 4d 08             	mov    0x8(%ebp),%ecx
	int num = 1;
	for (int i = 0; i < power; i++)
f01016a7:	ba 00 00 00 00       	mov    $0x0,%edx
	int num = 1;
f01016ac:	b8 01 00 00 00       	mov    $0x1,%eax
	for (int i = 0; i < power; i++)
f01016b1:	eb 05                	jmp    f01016b8 <pow_2+0x17>
		num *= 2;
f01016b3:	01 c0                	add    %eax,%eax
	for (int i = 0; i < power; i++)
f01016b5:	83 c2 01             	add    $0x1,%edx
f01016b8:	39 ca                	cmp    %ecx,%edx
f01016ba:	7c f7                	jl     f01016b3 <pow_2+0x12>
	return num;
}
f01016bc:	5d                   	pop    %ebp
f01016bd:	c3                   	ret    

f01016be <Buddykfree>:
	kmem.free_list = r;*/
}

void
Buddykfree(char *v)
{
f01016be:	55                   	push   %ebp
f01016bf:	89 e5                	mov    %esp,%ebp
f01016c1:	57                   	push   %edi
f01016c2:	56                   	push   %esi
f01016c3:	53                   	push   %ebx
f01016c4:	83 ec 2c             	sub    $0x2c,%esp
	struct run *r;

	if ((uint32_t)v % PGSIZE || v < end || V2P(v) >= PHYSTOP)
f01016c7:	8b 45 08             	mov    0x8(%ebp),%eax
f01016ca:	a9 ff 0f 00 00       	test   $0xfff,%eax
f01016cf:	75 46                	jne    f0101717 <Buddykfree+0x59>
f01016d1:	3d 08 c0 15 f0       	cmp    $0xf015c008,%eax
f01016d6:	72 3f                	jb     f0101717 <Buddykfree+0x59>
f01016d8:	05 00 00 00 10       	add    $0x10000000,%eax
f01016dd:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
f01016e2:	77 33                	ja     f0101717 <Buddykfree+0x59>
		panic("kfree");
	int idx, id;
	id = (void *)v >= (void *)base[1];
f01016e4:	8b 45 08             	mov    0x8(%ebp),%eax
f01016e7:	39 05 98 ae 11 f0    	cmp    %eax,0xf011ae98
f01016ed:	0f 96 c0             	setbe  %al
f01016f0:	0f b6 c0             	movzbl %al,%eax
f01016f3:	89 c7                	mov    %eax,%edi
	//cprintf("minus: %x, num: %x,idx: %x\n", (void *)v - (void *)base[0], (uint32_t)((void *)v - (void *)base[0]) / PGSIZE, idx);
	idx = (uint32_t)((void *)v - (void *)base[id]) / PGSIZE;
f01016f5:	8b 45 08             	mov    0x8(%ebp),%eax
f01016f8:	2b 04 bd 94 ae 11 f0 	sub    -0xfee516c(,%edi,4),%eax
f01016ff:	c1 e8 0c             	shr    $0xc,%eax
f0101702:	89 45 d0             	mov    %eax,-0x30(%ebp)
	int p = idx;
	int count = 0;
	//cprintf("v: %x, idx: %x, p: %x\n", v, idx, p);
	while (order[id][p] != 1) {
f0101705:	8b 14 bd b0 ae 11 f0 	mov    -0xfee5150(,%edi,4),%edx
	int p = idx;
f010170c:	89 c3                	mov    %eax,%ebx
	int count = 0;
f010170e:	be 00 00 00 00       	mov    $0x0,%esi
f0101713:	89 f1                	mov    %esi,%ecx
	while (order[id][p] != 1) {
f0101715:	eb 28                	jmp    f010173f <Buddykfree+0x81>
		panic("kfree");
f0101717:	83 ec 04             	sub    $0x4,%esp
f010171a:	68 00 35 10 f0       	push   $0xf0103500
f010171f:	68 d7 00 00 00       	push   $0xd7
f0101724:	68 06 35 10 f0       	push   $0xf0103506
f0101729:	e8 63 ea ff ff       	call   f0100191 <_panic>
		count++;
f010172e:	83 c1 01             	add    $0x1,%ecx
		p = start[id][count] + (idx >> count);
f0101731:	8b 34 bd b8 ae 11 f0 	mov    -0xfee5148(,%edi,4),%esi
f0101738:	89 c3                	mov    %eax,%ebx
f010173a:	d3 fb                	sar    %cl,%ebx
f010173c:	03 1c 8e             	add    (%esi,%ecx,4),%ebx
	while (order[id][p] != 1) {
f010173f:	80 3c 1a 00          	cmpb   $0x0,(%edx,%ebx,1)
f0101743:	74 e9                	je     f010172e <Buddykfree+0x70>
f0101745:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0101748:	89 ce                	mov    %ecx,%esi
	}
	//cprintf("p: %x\n", p);
	memset(v, 1, PGSIZE * pow_2(count));
f010174a:	83 ec 0c             	sub    $0xc,%esp
f010174d:	51                   	push   %ecx
f010174e:	e8 4e ff ff ff       	call   f01016a1 <pow_2>
f0101753:	83 c4 0c             	add    $0xc,%esp
f0101756:	c1 e0 0c             	shl    $0xc,%eax
f0101759:	50                   	push   %eax
f010175a:	6a 01                	push   $0x1
f010175c:	ff 75 08             	pushl  0x8(%ebp)
f010175f:	e8 c5 15 00 00       	call   f0102d29 <memset>
	order[id][p] = 0;
f0101764:	8b 04 bd b0 ae 11 f0 	mov    -0xfee5150(,%edi,4),%eax
f010176b:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f010176e:	c6 04 10 00          	movb   $0x0,(%eax,%edx,1)
	int buddy = p ^ 1;
f0101772:	83 f3 01             	xor    $0x1,%ebx
	int mark = 1 << (count + 12);
f0101775:	8d 4e 0c             	lea    0xc(%esi),%ecx
f0101778:	b8 01 00 00 00       	mov    $0x1,%eax
f010177d:	d3 e0                	shl    %cl,%eax
f010177f:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0101782:	8d 04 f5 00 00 00 00 	lea    0x0(,%esi,8),%eax
f0101789:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010178c:	8d 04 b5 04 00 00 00 	lea    0x4(,%esi,4),%eax
f0101793:	89 45 d8             	mov    %eax,-0x28(%ebp)
	char *buddypos;
	while (count < MAX_ORDER[id] && order[id][buddy] == 0) {
f0101796:	83 c4 10             	add    $0x10,%esp
f0101799:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f010179c:	eb 77                	jmp    f0101815 <Buddykfree+0x157>
		//cprintf("p: %x, buddy: %x\n", p, buddy);
		buddypos = (char *)base[id] + ((uint32_t)(v - (char *)base[id]) ^ mark);
		//cprintf("buddypos: %x, mark: %x\n", buddypos, mark);
		struct run *iter = Buddy[id][count].free_list;
		while (iter->next != (struct run *)buddypos && iter->next != Buddy[id][count].free_list)
f010179e:	89 c2                	mov    %eax,%edx
f01017a0:	8b 02                	mov    (%edx),%eax
f01017a2:	39 f0                	cmp    %esi,%eax
f01017a4:	0f 95 c3             	setne  %bl
f01017a7:	39 f8                	cmp    %edi,%eax
f01017a9:	0f 95 c1             	setne  %cl
f01017ac:	84 cb                	test   %cl,%bl
f01017ae:	75 ee                	jne    f010179e <Buddykfree+0xe0>
f01017b0:	8b 7d d4             	mov    -0x2c(%ebp),%edi
		// buddy is occupied
		// have little change
		//if (iter->next != (struct run *)buddypos)
		//	break;
		struct run *uni = iter->next;
		iter->next = uni->next;
f01017b3:	8b 08                	mov    (%eax),%ecx
f01017b5:	89 0a                	mov    %ecx,(%edx)
		Buddy[id][count].num--;
f01017b7:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01017ba:	89 f1                	mov    %esi,%ecx
f01017bc:	03 0c bd a0 ae 11 f0 	add    -0xfee5160(,%edi,4),%ecx
f01017c3:	83 69 04 01          	subl   $0x1,0x4(%ecx)
		Buddy[id][count].free_list = iter->next;
f01017c7:	8b 0a                	mov    (%edx),%ecx
f01017c9:	8b 14 bd a0 ae 11 f0 	mov    -0xfee5160(,%edi,4),%edx
f01017d0:	89 0c 32             	mov    %ecx,(%edx,%esi,1)
		v = (v > (char *)uni) ? (char *)uni : v;
f01017d3:	39 45 08             	cmp    %eax,0x8(%ebp)
f01017d6:	0f 46 45 08          	cmovbe 0x8(%ebp),%eax
f01017da:	89 45 08             	mov    %eax,0x8(%ebp)
		count++;
f01017dd:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
f01017e1:	8b 55 e4             	mov    -0x1c(%ebp),%edx
		mark <<= 1;
f01017e4:	d1 65 dc             	shll   -0x24(%ebp)
		p = start[id][count] + (idx >> count);
f01017e7:	8b 04 bd b8 ae 11 f0 	mov    -0xfee5148(,%edi,4),%eax
f01017ee:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f01017f1:	89 d1                	mov    %edx,%ecx
f01017f3:	d3 fb                	sar    %cl,%ebx
f01017f5:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f01017f8:	03 1c 08             	add    (%eax,%ecx,1),%ebx
		//cprintf("order: %d, p: %x\n", order[id][p], p);
		order[id][p] = 0;
f01017fb:	8b 04 bd b0 ae 11 f0 	mov    -0xfee5150(,%edi,4),%eax
f0101802:	c6 04 18 00          	movb   $0x0,(%eax,%ebx,1)
		//cprintf("order: %d\n", order[id][p]);
		buddy = p ^ 1;
f0101806:	83 f3 01             	xor    $0x1,%ebx
f0101809:	83 c6 08             	add    $0x8,%esi
f010180c:	89 75 e0             	mov    %esi,-0x20(%ebp)
f010180f:	83 c1 04             	add    $0x4,%ecx
f0101812:	89 4d d8             	mov    %ecx,-0x28(%ebp)
	while (count < MAX_ORDER[id] && order[id][buddy] == 0) {
f0101815:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101818:	39 04 bd c0 ae 11 f0 	cmp    %eax,-0xfee5140(,%edi,4)
f010181f:	7e 38                	jle    f0101859 <Buddykfree+0x19b>
f0101821:	8b 04 bd b0 ae 11 f0 	mov    -0xfee5150(,%edi,4),%eax
f0101828:	80 3c 18 00          	cmpb   $0x0,(%eax,%ebx,1)
f010182c:	75 2b                	jne    f0101859 <Buddykfree+0x19b>
		buddypos = (char *)base[id] + ((uint32_t)(v - (char *)base[id]) ^ mark);
f010182e:	8b 04 bd 94 ae 11 f0 	mov    -0xfee516c(,%edi,4),%eax
f0101835:	8b 75 08             	mov    0x8(%ebp),%esi
f0101838:	29 c6                	sub    %eax,%esi
f010183a:	33 75 dc             	xor    -0x24(%ebp),%esi
f010183d:	8d 1c 30             	lea    (%eax,%esi,1),%ebx
		struct run *iter = Buddy[id][count].free_list;
f0101840:	8b 04 bd a0 ae 11 f0 	mov    -0xfee5160(,%edi,4),%eax
f0101847:	8b 55 e0             	mov    -0x20(%ebp),%edx
f010184a:	8b 34 10             	mov    (%eax,%edx,1),%esi
f010184d:	89 f2                	mov    %esi,%edx
f010184f:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0101852:	89 df                	mov    %ebx,%edi
		while (iter->next != (struct run *)buddypos && iter->next != Buddy[id][count].free_list)
f0101854:	e9 47 ff ff ff       	jmp    f01017a0 <Buddykfree+0xe2>
f0101859:	8b 75 e4             	mov    -0x1c(%ebp),%esi
	}
	r = (struct run *)v;
	r->next = Buddy[id][count].free_list->next;
f010185c:	8b 04 bd a0 ae 11 f0 	mov    -0xfee5160(,%edi,4),%eax
f0101863:	8b 04 f0             	mov    (%eax,%esi,8),%eax
f0101866:	8b 00                	mov    (%eax),%eax
f0101868:	8b 55 08             	mov    0x8(%ebp),%edx
f010186b:	89 02                	mov    %eax,(%edx)
	Buddy[id][count].free_list->next = r;
f010186d:	8b 04 bd a0 ae 11 f0 	mov    -0xfee5160(,%edi,4),%eax
f0101874:	8b 04 f0             	mov    (%eax,%esi,8),%eax
f0101877:	89 10                	mov    %edx,(%eax)
	Buddy[id][count].num++;
f0101879:	8b 04 bd a0 ae 11 f0 	mov    -0xfee5160(,%edi,4),%eax
f0101880:	83 44 f0 04 01       	addl   $0x1,0x4(%eax,%esi,8)
}
f0101885:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101888:	5b                   	pop    %ebx
f0101889:	5e                   	pop    %esi
f010188a:	5f                   	pop    %edi
f010188b:	5d                   	pop    %ebp
f010188c:	c3                   	ret    

f010188d <kfree>:
{
f010188d:	55                   	push   %ebp
f010188e:	89 e5                	mov    %esp,%ebp
f0101890:	83 ec 14             	sub    $0x14,%esp
	Buddykfree(v);
f0101893:	ff 75 08             	pushl  0x8(%ebp)
f0101896:	e8 23 fe ff ff       	call   f01016be <Buddykfree>
}
f010189b:	83 c4 10             	add    $0x10,%esp
f010189e:	c9                   	leave  
f010189f:	c3                   	ret    

f01018a0 <free_range>:

void
free_range(void *vstart, void *vend)
{
f01018a0:	55                   	push   %ebp
f01018a1:	89 e5                	mov    %esp,%ebp
f01018a3:	56                   	push   %esi
f01018a4:	53                   	push   %ebx
f01018a5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *p;
	p = ROUNDUP((char *)vstart, PGSIZE);
f01018a8:	8b 45 08             	mov    0x8(%ebp),%eax
f01018ab:	05 ff 0f 00 00       	add    $0xfff,%eax
f01018b0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	for (; p + PGSIZE <= (char *)vend; p += PGSIZE)
f01018b5:	eb 0e                	jmp    f01018c5 <free_range+0x25>
	Buddykfree(v);
f01018b7:	83 ec 0c             	sub    $0xc,%esp
f01018ba:	50                   	push   %eax
f01018bb:	e8 fe fd ff ff       	call   f01016be <Buddykfree>
	for (; p + PGSIZE <= (char *)vend; p += PGSIZE)
f01018c0:	83 c4 10             	add    $0x10,%esp
f01018c3:	89 f0                	mov    %esi,%eax
f01018c5:	8d b0 00 10 00 00    	lea    0x1000(%eax),%esi
f01018cb:	39 de                	cmp    %ebx,%esi
f01018cd:	76 e8                	jbe    f01018b7 <free_range+0x17>
		kfree(p);
}
f01018cf:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01018d2:	5b                   	pop    %ebx
f01018d3:	5e                   	pop    %esi
f01018d4:	5d                   	pop    %ebp
f01018d5:	c3                   	ret    

f01018d6 <Buddyfree_range>:

void
Buddyfree_range(void *vstart, int level)
{
f01018d6:	55                   	push   %ebp
f01018d7:	89 e5                	mov    %esp,%ebp
f01018d9:	57                   	push   %edi
f01018da:	56                   	push   %esi
f01018db:	53                   	push   %ebx
f01018dc:	83 ec 0c             	sub    $0xc,%esp
f01018df:	8b 75 08             	mov    0x8(%ebp),%esi
f01018e2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	struct run *r;
	int id = ((void *)vstart >= (void *)base[1]) ? 1 : 0;
f01018e5:	39 35 98 ae 11 f0    	cmp    %esi,0xf011ae98
f01018eb:	0f 96 c0             	setbe  %al
f01018ee:	0f b6 c0             	movzbl %al,%eax
f01018f1:	89 c7                	mov    %eax,%edi

	memset(vstart, 1, PGSIZE * pow_2(level));
f01018f3:	53                   	push   %ebx
f01018f4:	e8 a8 fd ff ff       	call   f01016a1 <pow_2>
f01018f9:	c1 e0 0c             	shl    $0xc,%eax
f01018fc:	50                   	push   %eax
f01018fd:	6a 01                	push   $0x1
f01018ff:	56                   	push   %esi
f0101900:	e8 24 14 00 00       	call   f0102d29 <memset>
	r = (struct run *)vstart;
	//cprintf("%x, %x\n", Buddy[id][level].free_list->next, Buddy[id][level].free_list);
	r->next = Buddy[id][level].free_list->next;
f0101905:	8b 04 bd a0 ae 11 f0 	mov    -0xfee5160(,%edi,4),%eax
f010190c:	8b 04 d8             	mov    (%eax,%ebx,8),%eax
f010190f:	8b 00                	mov    (%eax),%eax
f0101911:	89 06                	mov    %eax,(%esi)
	Buddy[id][level].free_list->next = r;
f0101913:	8b 04 bd a0 ae 11 f0 	mov    -0xfee5160(,%edi,4),%eax
f010191a:	8b 04 d8             	mov    (%eax,%ebx,8),%eax
f010191d:	89 30                	mov    %esi,(%eax)
	//cprintf("%x, %x\n", Buddy[id][level].free_list->next, Buddy[id][level].free_list);
	Buddy[id][level].num++;
f010191f:	8b 04 bd a0 ae 11 f0 	mov    -0xfee5160(,%edi,4),%eax
f0101926:	83 44 d8 04 01       	addl   $0x1,0x4(%eax,%ebx,8)
}
f010192b:	83 c4 10             	add    $0x10,%esp
f010192e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101931:	5b                   	pop    %ebx
f0101932:	5e                   	pop    %esi
f0101933:	5f                   	pop    %edi
f0101934:	5d                   	pop    %ebp
f0101935:	c3                   	ret    

f0101936 <split>:
		return NULL;*/
}

void
split(char *r, int low, int high)
{
f0101936:	55                   	push   %ebp
f0101937:	89 e5                	mov    %esp,%ebp
f0101939:	57                   	push   %edi
f010193a:	56                   	push   %esi
f010193b:	53                   	push   %ebx
f010193c:	83 ec 08             	sub    $0x8,%esp
f010193f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	int size = 1 << high;
f0101942:	b8 01 00 00 00       	mov    $0x1,%eax
f0101947:	d3 e0                	shl    %cl,%eax
f0101949:	89 45 f0             	mov    %eax,-0x10(%ebp)
	int id, idx;
	id = (void *)r >= (void *)base[1];
f010194c:	8b 45 08             	mov    0x8(%ebp),%eax
f010194f:	39 05 98 ae 11 f0    	cmp    %eax,0xf011ae98
f0101955:	0f 96 c0             	setbe  %al
f0101958:	0f b6 c0             	movzbl %al,%eax
	idx = (uint32_t)((void *)r - (void *)base[id]) / PGSIZE;
f010195b:	8b 55 08             	mov    0x8(%ebp),%edx
f010195e:	2b 14 85 94 ae 11 f0 	sub    -0xfee516c(,%eax,4),%edx
f0101965:	c1 ea 0c             	shr    $0xc,%edx
f0101968:	89 55 ec             	mov    %edx,-0x14(%ebp)
f010196b:	8d 34 8d 00 00 00 00 	lea    0x0(,%ecx,4),%esi
f0101972:	8d 14 cd f8 ff ff ff 	lea    -0x8(,%ecx,8),%edx
	//cprintf("%x\n", r);
	while (high > low) {
f0101979:	eb 57                	jmp    f01019d2 <split+0x9c>
		//cprintf("pos: %x, high: %d\n", start[id][high] + (idx >> high), high);
		order[id][start[id][high] + (idx >> high)] = 1;
f010197b:	8b 3c 85 b8 ae 11 f0 	mov    -0xfee5148(,%eax,4),%edi
f0101982:	8b 5d ec             	mov    -0x14(%ebp),%ebx
f0101985:	d3 fb                	sar    %cl,%ebx
f0101987:	03 1c 85 b0 ae 11 f0 	add    -0xfee5150(,%eax,4),%ebx
f010198e:	03 1c 37             	add    (%edi,%esi,1),%ebx
f0101991:	c6 03 01             	movb   $0x1,(%ebx)
		//cprintf("high: %x, pos: %x\n", high, start[high] + (idx >> high));
		high--;
f0101994:	83 e9 01             	sub    $0x1,%ecx
		size >>= 1;
f0101997:	d1 7d f0             	sarl   -0x10(%ebp)
f010199a:	8b 7d f0             	mov    -0x10(%ebp),%edi
		struct run *p = (struct run *)((uint32_t)r + PGSIZE * size);
f010199d:	89 fb                	mov    %edi,%ebx
f010199f:	c1 e3 0c             	shl    $0xc,%ebx
f01019a2:	03 5d 08             	add    0x8(%ebp),%ebx
		//add high
		p->next = Buddy[id][high].free_list->next;
f01019a5:	8b 3c 85 a0 ae 11 f0 	mov    -0xfee5160(,%eax,4),%edi
f01019ac:	8b 3c 17             	mov    (%edi,%edx,1),%edi
f01019af:	8b 3f                	mov    (%edi),%edi
f01019b1:	89 3b                	mov    %edi,(%ebx)
		Buddy[id][high].free_list->next = p;
f01019b3:	8b 3c 85 a0 ae 11 f0 	mov    -0xfee5160(,%eax,4),%edi
f01019ba:	8b 3c 17             	mov    (%edi,%edx,1),%edi
f01019bd:	89 1f                	mov    %ebx,(%edi)
		Buddy[id][high].num++;
f01019bf:	89 d3                	mov    %edx,%ebx
f01019c1:	03 1c 85 a0 ae 11 f0 	add    -0xfee5160(,%eax,4),%ebx
f01019c8:	83 43 04 01          	addl   $0x1,0x4(%ebx)
f01019cc:	83 ee 04             	sub    $0x4,%esi
f01019cf:	83 ea 08             	sub    $0x8,%edx
	while (high > low) {
f01019d2:	3b 4d 0c             	cmp    0xc(%ebp),%ecx
f01019d5:	7f a4                	jg     f010197b <split+0x45>
	}
	order[id][start[id][high] + (idx >> high)] = 1;
f01019d7:	8b 14 85 b8 ae 11 f0 	mov    -0xfee5148(,%eax,4),%edx
f01019de:	8b 5d ec             	mov    -0x14(%ebp),%ebx
f01019e1:	d3 fb                	sar    %cl,%ebx
f01019e3:	03 1c 85 b0 ae 11 f0 	add    -0xfee5150(,%eax,4),%ebx
f01019ea:	89 d8                	mov    %ebx,%eax
f01019ec:	03 04 8a             	add    (%edx,%ecx,4),%eax
f01019ef:	c6 00 01             	movb   $0x1,(%eax)
	//cprintf("pos: %x\n", start[id][high] + (idx >> high));
}
f01019f2:	83 c4 08             	add    $0x8,%esp
f01019f5:	5b                   	pop    %ebx
f01019f6:	5e                   	pop    %esi
f01019f7:	5f                   	pop    %edi
f01019f8:	5d                   	pop    %ebp
f01019f9:	c3                   	ret    

f01019fa <Buddykalloc>:

char *
Buddykalloc(int order)
{
f01019fa:	55                   	push   %ebp
f01019fb:	89 e5                	mov    %esp,%ebp
f01019fd:	57                   	push   %edi
f01019fe:	56                   	push   %esi
f01019ff:	53                   	push   %ebx
f0101a00:	83 ec 04             	sub    $0x4,%esp
f0101a03:	8b 75 08             	mov    0x8(%ebp),%esi
	for (int i = 0; i < 2; i++)
		for (int currentorder = order; currentorder <= MAX_ORDER[i]; currentorder++)
f0101a06:	89 f0                	mov    %esi,%eax
	for (int i = 0; i < 2; i++)
f0101a08:	ba 00 00 00 00       	mov    $0x0,%edx
		for (int currentorder = order; currentorder <= MAX_ORDER[i]; currentorder++)
f0101a0d:	39 04 95 c0 ae 11 f0 	cmp    %eax,-0xfee5140(,%edx,4)
f0101a14:	7c 45                	jl     f0101a5b <Buddykalloc+0x61>
			if (Buddy[i][currentorder].num > 0) {
f0101a16:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
f0101a1d:	89 cb                	mov    %ecx,%ebx
f0101a1f:	03 1c 95 a0 ae 11 f0 	add    -0xfee5160(,%edx,4),%ebx
f0101a26:	83 7b 04 00          	cmpl   $0x0,0x4(%ebx)
f0101a2a:	7f 05                	jg     f0101a31 <Buddykalloc+0x37>
		for (int currentorder = order; currentorder <= MAX_ORDER[i]; currentorder++)
f0101a2c:	83 c0 01             	add    $0x1,%eax
f0101a2f:	eb dc                	jmp    f0101a0d <Buddykalloc+0x13>
f0101a31:	89 4d f0             	mov    %ecx,-0x10(%ebp)
				struct run *r;
				r = Buddy[i][currentorder].free_list->next;
f0101a34:	8b 3b                	mov    (%ebx),%edi
f0101a36:	8b 1f                	mov    (%edi),%ebx
				Buddy[i][currentorder].free_list->next = r->next;
f0101a38:	8b 0b                	mov    (%ebx),%ecx
f0101a3a:	89 0f                	mov    %ecx,(%edi)
				Buddy[i][currentorder].num--;
f0101a3c:	8b 4d f0             	mov    -0x10(%ebp),%ecx
f0101a3f:	03 0c 95 a0 ae 11 f0 	add    -0xfee5160(,%edx,4),%ecx
f0101a46:	83 69 04 01          	subl   $0x1,0x4(%ecx)
				//cprintf("%d\n", currentorder);
				split((char *)r, order, currentorder);
f0101a4a:	50                   	push   %eax
f0101a4b:	56                   	push   %esi
f0101a4c:	53                   	push   %ebx
f0101a4d:	e8 e4 fe ff ff       	call   f0101936 <split>
				return (char *)r;
f0101a52:	83 c4 0c             	add    $0xc,%esp
f0101a55:	eb 11                	jmp    f0101a68 <Buddykalloc+0x6e>
		for (int currentorder = order; currentorder <= MAX_ORDER[i]; currentorder++)
f0101a57:	89 f0                	mov    %esi,%eax
f0101a59:	eb b2                	jmp    f0101a0d <Buddykalloc+0x13>
	for (int i = 0; i < 2; i++)
f0101a5b:	83 c2 01             	add    $0x1,%edx
f0101a5e:	83 fa 01             	cmp    $0x1,%edx
f0101a61:	7e f4                	jle    f0101a57 <Buddykalloc+0x5d>
			} 
	return NULL;
f0101a63:	bb 00 00 00 00       	mov    $0x0,%ebx
}
f0101a68:	89 d8                	mov    %ebx,%eax
f0101a6a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101a6d:	5b                   	pop    %ebx
f0101a6e:	5e                   	pop    %esi
f0101a6f:	5f                   	pop    %edi
f0101a70:	5d                   	pop    %ebp
f0101a71:	c3                   	ret    

f0101a72 <kalloc>:
{
f0101a72:	55                   	push   %ebp
f0101a73:	89 e5                	mov    %esp,%ebp
	return Buddykalloc(0);
f0101a75:	6a 00                	push   $0x0
f0101a77:	e8 7e ff ff ff       	call   f01019fa <Buddykalloc>
}
f0101a7c:	c9                   	leave  
f0101a7d:	c3                   	ret    

f0101a7e <check_free_list>:
void
check_free_list(void)
{
	struct run *p;
	bool exist;
	for (int i = 0; i < 2; i++)
f0101a7e:	ba 00 00 00 00       	mov    $0x0,%edx
		for (int j = 0; j <= MAX_ORDER[i]; j++)
f0101a83:	b8 00 00 00 00       	mov    $0x0,%eax
f0101a88:	eb 03                	jmp    f0101a8d <check_free_list+0xf>
f0101a8a:	83 c0 01             	add    $0x1,%eax
f0101a8d:	39 04 95 c0 ae 11 f0 	cmp    %eax,-0xfee5140(,%edx,4)
f0101a94:	7d f4                	jge    f0101a8a <check_free_list+0xc>
	for (int i = 0; i < 2; i++)
f0101a96:	83 c2 01             	add    $0x1,%edx
f0101a99:	83 fa 01             	cmp    $0x1,%edx
f0101a9c:	7f 39                	jg     f0101ad7 <check_free_list+0x59>
		for (int j = 0; j <= MAX_ORDER[i]; j++)
f0101a9e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101aa3:	eb e8                	jmp    f0101a8d <check_free_list+0xf>

	//cprintf("end: 0x%x\n", end);

	for (p = kmem.free_list; p; p = p->next) {
		//cprintf("0x%x\n", p);
		assert((void *)p > (void *)end);
f0101aa5:	68 14 35 10 f0       	push   $0xf0103514
f0101aaa:	68 7e 34 10 f0       	push   $0xf010347e
f0101aaf:	68 72 01 00 00       	push   $0x172
f0101ab4:	68 06 35 10 f0       	push   $0xf0103506
f0101ab9:	e8 d3 e6 ff ff       	call   f0100191 <_panic>
		for (int i = 4; i < 4096; i++) 
			assert(((char *)p)[i] == 1);
f0101abe:	68 2c 35 10 f0       	push   $0xf010352c
f0101ac3:	68 7e 34 10 f0       	push   $0xf010347e
f0101ac8:	68 74 01 00 00       	push   $0x174
f0101acd:	68 06 35 10 f0       	push   $0xf0103506
f0101ad2:	e8 ba e6 ff ff       	call   f0100191 <_panic>
	for (p = kmem.free_list; p; p = p->next) {
f0101ad7:	8b 0d 9c ae 11 f0    	mov    0xf011ae9c,%ecx
f0101add:	85 c9                	test   %ecx,%ecx
f0101adf:	74 2b                	je     f0101b0c <check_free_list+0x8e>
{
f0101ae1:	55                   	push   %ebp
f0101ae2:	89 e5                	mov    %esp,%ebp
f0101ae4:	83 ec 08             	sub    $0x8,%esp
		assert((void *)p > (void *)end);
f0101ae7:	81 f9 08 c0 15 f0    	cmp    $0xf015c008,%ecx
f0101aed:	76 b6                	jbe    f0101aa5 <check_free_list+0x27>
f0101aef:	8d 41 04             	lea    0x4(%ecx),%eax
f0101af2:	8d 91 00 10 00 00    	lea    0x1000(%ecx),%edx
			assert(((char *)p)[i] == 1);
f0101af8:	80 38 01             	cmpb   $0x1,(%eax)
f0101afb:	75 c1                	jne    f0101abe <check_free_list+0x40>
f0101afd:	83 c0 01             	add    $0x1,%eax
		for (int i = 4; i < 4096; i++) 
f0101b00:	39 d0                	cmp    %edx,%eax
f0101b02:	75 f4                	jne    f0101af8 <check_free_list+0x7a>
	for (p = kmem.free_list; p; p = p->next) {
f0101b04:	8b 09                	mov    (%ecx),%ecx
f0101b06:	85 c9                	test   %ecx,%ecx
f0101b08:	75 dd                	jne    f0101ae7 <check_free_list+0x69>
	}
}
f0101b0a:	c9                   	leave  
f0101b0b:	c3                   	ret    
f0101b0c:	c3                   	ret    

f0101b0d <boot_alloc_init>:
{
f0101b0d:	55                   	push   %ebp
f0101b0e:	89 e5                	mov    %esp,%ebp
f0101b10:	57                   	push   %edi
f0101b11:	56                   	push   %esi
f0101b12:	53                   	push   %ebx
f0101b13:	83 ec 2c             	sub    $0x2c,%esp
			num = (uint32_t)((char *)P2V(4*1024*1024) - end) / PGSIZE;
f0101b16:	b8 00 00 40 f0       	mov    $0xf0400000,%eax
f0101b1b:	2d 08 c0 15 f0       	sub    $0xf015c008,%eax
	char *mystart = end;
f0101b20:	bf 08 c0 15 f0       	mov    $0xf015c008,%edi
			num = (uint32_t)((char *)P2V(4*1024*1024) - end) / PGSIZE;
f0101b25:	c1 e8 0c             	shr    $0xc,%eax
f0101b28:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101b2b:	c7 45 d0 a8 ae 11 f0 	movl   $0xf011aea8,-0x30(%ebp)
f0101b32:	8b 55 cc             	mov    -0x34(%ebp),%edx
f0101b35:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f0101b3c:	89 fe                	mov    %edi,%esi
f0101b3e:	e9 24 01 00 00       	jmp    f0101c67 <boot_alloc_init+0x15a>
f0101b43:	89 f7                	mov    %esi,%edi
f0101b45:	eb e4                	jmp    f0101b2b <boot_alloc_init+0x1e>
			sum *= 2;
f0101b47:	01 c0                	add    %eax,%eax
			level++;
f0101b49:	83 c7 01             	add    $0x1,%edi
		while (sum < num) {
f0101b4c:	39 c2                	cmp    %eax,%edx
f0101b4e:	7f f7                	jg     f0101b47 <boot_alloc_init+0x3a>
			level--;
f0101b50:	0f 9c c0             	setl   %al
f0101b53:	0f b6 c0             	movzbl %al,%eax
f0101b56:	29 c7                	sub    %eax,%edi
f0101b58:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101b5b:	89 45 e0             	mov    %eax,-0x20(%ebp)
		order[i] = (bool *)mystart;
f0101b5e:	89 34 85 b0 ae 11 f0 	mov    %esi,-0xfee5150(,%eax,4)
		memset(order[i], 0, pow_2(level) * 2);
f0101b65:	57                   	push   %edi
f0101b66:	e8 36 fb ff ff       	call   f01016a1 <pow_2>
f0101b6b:	8d 1c 00             	lea    (%eax,%eax,1),%ebx
f0101b6e:	53                   	push   %ebx
f0101b6f:	6a 00                	push   $0x0
f0101b71:	56                   	push   %esi
f0101b72:	e8 b2 11 00 00       	call   f0102d29 <memset>
		mystart += pow_2(level) * 2;
f0101b77:	01 f3                	add    %esi,%ebx
		MAX_ORDER[i] = level;
f0101b79:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0101b7c:	89 3c 8d c0 ae 11 f0 	mov    %edi,-0xfee5140(,%ecx,4)
		Buddy[i] = (struct Buddykmem *)mystart;
f0101b83:	89 1c 8d a0 ae 11 f0 	mov    %ebx,-0xfee5160(,%ecx,4)
		memset(Buddy[i], 0, sizeof(struct Buddykmem) * (level + 1));
f0101b8a:	8d 57 01             	lea    0x1(%edi),%edx
f0101b8d:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0101b90:	8d 34 d5 00 00 00 00 	lea    0x0(,%edx,8),%esi
f0101b97:	83 c4 0c             	add    $0xc,%esp
f0101b9a:	56                   	push   %esi
f0101b9b:	6a 00                	push   $0x0
f0101b9d:	53                   	push   %ebx
f0101b9e:	e8 86 11 00 00       	call   f0102d29 <memset>
		mystart += sizeof(struct Buddykmem) * (level + 1);
f0101ba3:	01 de                	add    %ebx,%esi
f0101ba5:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0101ba8:	89 cb                	mov    %ecx,%ebx
		linkbase[i] = (struct run *)mystart;
f0101baa:	89 31                	mov    %esi,(%ecx)
		memset(linkbase[i], 0, sizeof(struct run) *(level + 1));
f0101bac:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101baf:	c1 e2 02             	shl    $0x2,%edx
f0101bb2:	83 c4 0c             	add    $0xc,%esp
f0101bb5:	89 55 d8             	mov    %edx,-0x28(%ebp)
f0101bb8:	52                   	push   %edx
f0101bb9:	6a 00                	push   $0x0
f0101bbb:	56                   	push   %esi
f0101bbc:	e8 68 11 00 00       	call   f0102d29 <memset>
		mystart += sizeof(struct run) *(level + 1);
f0101bc1:	03 75 d8             	add    -0x28(%ebp),%esi
f0101bc4:	89 75 d4             	mov    %esi,-0x2c(%ebp)
		for (int j = 0; j <= level; j++) {
f0101bc7:	83 c4 10             	add    $0x10,%esp
f0101bca:	b8 00 00 00 00       	mov    $0x0,%eax
f0101bcf:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0101bd2:	eb 1c                	jmp    f0101bf0 <boot_alloc_init+0xe3>
f0101bd4:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
			linkbase[i][j].next = &linkbase[i][j];
f0101bdb:	89 d1                	mov    %edx,%ecx
f0101bdd:	03 0b                	add    (%ebx),%ecx
f0101bdf:	89 09                	mov    %ecx,(%ecx)
			Buddy[i][j].free_list = &linkbase[i][j];
f0101be1:	8b 0c b5 a0 ae 11 f0 	mov    -0xfee5160(,%esi,4),%ecx
f0101be8:	03 13                	add    (%ebx),%edx
f0101bea:	89 14 c1             	mov    %edx,(%ecx,%eax,8)
		for (int j = 0; j <= level; j++) {
f0101bed:	83 c0 01             	add    $0x1,%eax
f0101bf0:	39 c7                	cmp    %eax,%edi
f0101bf2:	7d e0                	jge    f0101bd4 <boot_alloc_init+0xc7>
		start[i] = (int *)mystart;
f0101bf4:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0101bf7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101bfa:	89 04 b5 b8 ae 11 f0 	mov    %eax,-0xfee5148(,%esi,4)
		start[i][0] = 0;
f0101c01:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		for (int j = 0; j < level; j++)
f0101c07:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101c0c:	89 7d e4             	mov    %edi,-0x1c(%ebp)
f0101c0f:	eb 2c                	jmp    f0101c3d <boot_alloc_init+0x130>
			start[i][j + 1] = start[i][j] + pow_2(level - j);
f0101c11:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101c14:	8b 34 85 b8 ae 11 f0 	mov    -0xfee5148(,%eax,4),%esi
f0101c1b:	8d 3c 9d 00 00 00 00 	lea    0x0(,%ebx,4),%edi
f0101c22:	83 ec 0c             	sub    $0xc,%esp
f0101c25:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101c28:	29 d8                	sub    %ebx,%eax
f0101c2a:	50                   	push   %eax
f0101c2b:	e8 71 fa ff ff       	call   f01016a1 <pow_2>
f0101c30:	83 c4 10             	add    $0x10,%esp
f0101c33:	03 04 9e             	add    (%esi,%ebx,4),%eax
f0101c36:	89 44 3e 04          	mov    %eax,0x4(%esi,%edi,1)
		for (int j = 0; j < level; j++)
f0101c3a:	83 c3 01             	add    $0x1,%ebx
f0101c3d:	39 5d e4             	cmp    %ebx,-0x1c(%ebp)
f0101c40:	7f cf                	jg     f0101c11 <boot_alloc_init+0x104>
		mystart += sizeof(int) * (level + 1);
f0101c42:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0101c45:	03 75 d8             	add    -0x28(%ebp),%esi
	for (int i = 0; i < 2; i++) {
f0101c48:	83 45 dc 01          	addl   $0x1,-0x24(%ebp)
f0101c4c:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101c4f:	83 f8 01             	cmp    $0x1,%eax
f0101c52:	7f 22                	jg     f0101c76 <boot_alloc_init+0x169>
f0101c54:	83 45 d0 04          	addl   $0x4,-0x30(%ebp)
			num = (uint32_t)((char *)PHYSTOP - 4*1024*1024) / PGSIZE;
f0101c58:	ba 00 dc 00 00       	mov    $0xdc00,%edx
		if (i == 0)
f0101c5d:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0101c61:	0f 84 dc fe ff ff    	je     f0101b43 <boot_alloc_init+0x36>
		int sum = 1;
f0101c67:	b8 01 00 00 00       	mov    $0x1,%eax
		int level = 0;
f0101c6c:	bf 00 00 00 00       	mov    $0x0,%edi
		while (sum < num) {
f0101c71:	e9 d6 fe ff ff       	jmp    f0101b4c <boot_alloc_init+0x3f>
f0101c76:	89 f7                	mov    %esi,%edi
	base[0] = (struct run *)ROUNDUP(mystart, PGSIZE);
f0101c78:	81 c7 ff 0f 00 00    	add    $0xfff,%edi
f0101c7e:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
f0101c84:	89 3d 94 ae 11 f0    	mov    %edi,0xf011ae94
	base[1] = (struct run *)P2V(4 * 1024 * 1024);
f0101c8a:	c7 05 98 ae 11 f0 00 	movl   $0xf0400000,0xf011ae98
f0101c91:	00 40 f0 
	Buddyfree_range((void *)base[0], MAX_ORDER[0]);
f0101c94:	83 ec 08             	sub    $0x8,%esp
f0101c97:	ff 35 c0 ae 11 f0    	pushl  0xf011aec0
f0101c9d:	57                   	push   %edi
f0101c9e:	e8 33 fc ff ff       	call   f01018d6 <Buddyfree_range>
	check_free_list();
f0101ca3:	e8 d6 fd ff ff       	call   f0101a7e <check_free_list>
}
f0101ca8:	83 c4 10             	add    $0x10,%esp
f0101cab:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101cae:	5b                   	pop    %ebx
f0101caf:	5e                   	pop    %esi
f0101cb0:	5f                   	pop    %edi
f0101cb1:	5d                   	pop    %ebp
f0101cb2:	c3                   	ret    

f0101cb3 <alloc_init>:
{
f0101cb3:	55                   	push   %ebp
f0101cb4:	89 e5                	mov    %esp,%ebp
f0101cb6:	83 ec 10             	sub    $0x10,%esp
	Buddyfree_range((void *)base[1], MAX_ORDER[1]);
f0101cb9:	ff 35 c4 ae 11 f0    	pushl  0xf011aec4
f0101cbf:	ff 35 98 ae 11 f0    	pushl  0xf011ae98
f0101cc5:	e8 0c fc ff ff       	call   f01018d6 <Buddyfree_range>
	check_free_list();
f0101cca:	e8 af fd ff ff       	call   f0101a7e <check_free_list>
}
f0101ccf:	83 c4 10             	add    $0x10,%esp
f0101cd2:	c9                   	leave  
f0101cd3:	c3                   	ret    

f0101cd4 <mpentry_start>:
.set PROT_MODE_DSEG, 0x10	# kernel data segment selector

.code16           
.globl mpentry_start
mpentry_start:
	cli            
f0101cd4:	fa                   	cli    

	xorw    %ax, %ax
f0101cd5:	31 c0                	xor    %eax,%eax
	movw    %ax, %ds
f0101cd7:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0101cd9:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0101cdb:	8e d0                	mov    %eax,%ss

	lgdt    MPBOOTPHYS(gdtdesc)
f0101cdd:	0f 01 16             	lgdtl  (%esi)
f0101ce0:	74 70                	je     f0101d52 <mpsearch1+0x3>
	movl    %cr0, %eax
f0101ce2:	0f 20 c0             	mov    %cr0,%eax
	orl     $CR0_PE, %eax
f0101ce5:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
f0101ce9:	0f 22 c0             	mov    %eax,%cr0

	ljmpl   $(PROT_MODE_CSEG), $(MPBOOTPHYS(start32))
f0101cec:	66 ea 20 70 00 00    	ljmpw  $0x0,$0x7020
f0101cf2:	08 00                	or     %al,(%eax)

f0101cf4 <start32>:

.code32
start32:
	movw    $(PROT_MODE_DSEG), %ax
f0101cf4:	66 b8 10 00          	mov    $0x10,%ax
	movw    %ax, %ds
f0101cf8:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0101cfa:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0101cfc:	8e d0                	mov    %eax,%ss
	movw    $0, %ax
f0101cfe:	66 b8 00 00          	mov    $0x0,%ax
	movw    %ax, %fs
f0101d02:	8e e0                	mov    %eax,%fs
	movw    %ax, %gs
f0101d04:	8e e8                	mov    %eax,%gs

	# Set up initial page table. We cannot use kern_pgdir yet because
	# we are still running at a low EIP.
	movl    $(RELOC(entry_pgdir)), %eax
f0101d06:	b8 00 70 11 00       	mov    $0x117000,%eax
	movl    %eax, %cr3
f0101d0b:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl    %cr0, %eax
f0101d0e:	0f 20 c0             	mov    %cr0,%eax
	orl     $(CR0_PE|CR0_PG|CR0_WP), %eax
f0101d11:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl    %eax, %cr0
f0101d16:	0f 22 c0             	mov    %eax,%cr0

	# Switch to the per-cpu stack allocated in boot_aps()
	movl    mpentry_kstack, %esp
f0101d19:	8b 25 48 a6 11 f0    	mov    0xf011a648,%esp
	movl    $0x0, %ebp       # nuke frame pointer
f0101d1f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Call mp_main().  (Exercise for the reader: why the indirect call?)
	movl    $mp_main, %eax
f0101d24:	b8 45 01 10 f0       	mov    $0xf0100145,%eax
	call    *%eax
f0101d29:	ff d0                	call   *%eax

f0101d2b <spin>:

	# If mp_main returns (it shouldn't), loop.
spin:
	jmp     spin
f0101d2b:	eb fe                	jmp    f0101d2b <spin>
f0101d2d:	8d 76 00             	lea    0x0(%esi),%esi

f0101d30 <gdt>:
	...
f0101d38:	ff                   	(bad)  
f0101d39:	ff 00                	incl   (%eax)
f0101d3b:	00 00                	add    %al,(%eax)
f0101d3d:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
f0101d44:	00                   	.byte 0x0
f0101d45:	92                   	xchg   %eax,%edx
f0101d46:	cf                   	iret   
	...

f0101d48 <gdtdesc>:
f0101d48:	17                   	pop    %ss
f0101d49:	00 5c 70 00          	add    %bl,0x0(%eax,%esi,2)
	...

f0101d4e <mpentry_end>:
	.word   0x17				# sizeof(gdt) - 1
	.long   MPBOOTPHYS(gdt)			# address gdt

.globl mpentry_end
mpentry_end:
	nop
f0101d4e:	90                   	nop

f0101d4f <mpsearch1>:
}

// Look for an MP structure in the len bytes at physical address addr.
static struct mp *
mpsearch1(physaddr_t a, int len)
{
f0101d4f:	55                   	push   %ebp
f0101d50:	89 e5                	mov    %esp,%ebp
f0101d52:	57                   	push   %edi
f0101d53:	56                   	push   %esi
f0101d54:	53                   	push   %ebx
f0101d55:	83 ec 0c             	sub    $0xc,%esp
	struct mp *mp = P2V(a), *end = P2V(a + len);
f0101d58:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
f0101d5e:	8d b4 10 00 00 00 f0 	lea    -0x10000000(%eax,%edx,1),%esi

	for (; mp < end; mp++)
f0101d65:	eb 03                	jmp    f0101d6a <mpsearch1+0x1b>
f0101d67:	83 c3 10             	add    $0x10,%ebx
f0101d6a:	39 f3                	cmp    %esi,%ebx
f0101d6c:	73 2e                	jae    f0101d9c <mpsearch1+0x4d>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0101d6e:	83 ec 04             	sub    $0x4,%esp
f0101d71:	6a 04                	push   $0x4
f0101d73:	68 40 35 10 f0       	push   $0xf0103540
f0101d78:	53                   	push   %ebx
f0101d79:	e8 73 10 00 00       	call   f0102df1 <memcmp>
f0101d7e:	83 c4 10             	add    $0x10,%esp
f0101d81:	85 c0                	test   %eax,%eax
f0101d83:	75 e2                	jne    f0101d67 <mpsearch1+0x18>
f0101d85:	89 da                	mov    %ebx,%edx
f0101d87:	8d 7b 10             	lea    0x10(%ebx),%edi
		sum += ((uint8_t *)addr)[i];
f0101d8a:	0f b6 0a             	movzbl (%edx),%ecx
f0101d8d:	01 c8                	add    %ecx,%eax
f0101d8f:	83 c2 01             	add    $0x1,%edx
	for (i = 0; i < len; i++)
f0101d92:	39 fa                	cmp    %edi,%edx
f0101d94:	75 f4                	jne    f0101d8a <mpsearch1+0x3b>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0101d96:	84 c0                	test   %al,%al
f0101d98:	75 cd                	jne    f0101d67 <mpsearch1+0x18>
f0101d9a:	eb 05                	jmp    f0101da1 <mpsearch1+0x52>
		    sum(mp, sizeof(*mp)) == 0)
			return mp;
	return NULL;
f0101d9c:	bb 00 00 00 00       	mov    $0x0,%ebx
}
f0101da1:	89 d8                	mov    %ebx,%eax
f0101da3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101da6:	5b                   	pop    %ebx
f0101da7:	5e                   	pop    %esi
f0101da8:	5f                   	pop    %edi
f0101da9:	5d                   	pop    %ebp
f0101daa:	c3                   	ret    

f0101dab <mp_init>:
	return conf;
}

void
mp_init(void)
{
f0101dab:	55                   	push   %ebp
f0101dac:	89 e5                	mov    %esp,%ebp
f0101dae:	57                   	push   %edi
f0101daf:	56                   	push   %esi
f0101db0:	53                   	push   %ebx
f0101db1:	83 ec 1c             	sub    $0x1c,%esp
	struct mpconf *conf;
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
f0101db4:	c7 05 20 b5 11 f0 20 	movl   $0xf011b020,0xf011b520
f0101dbb:	b0 11 f0 
	if ((p = *(uint16_t *) (bda + 0x0E))) {
f0101dbe:	0f b7 05 0e 04 00 f0 	movzwl 0xf000040e,%eax
f0101dc5:	85 c0                	test   %eax,%eax
f0101dc7:	74 53                	je     f0101e1c <mp_init+0x71>
		p <<= 4;	// Translate from segment to PA
f0101dc9:	c1 e0 04             	shl    $0x4,%eax
		if ((mp = mpsearch1(p, 1024)))
f0101dcc:	ba 00 04 00 00       	mov    $0x400,%edx
f0101dd1:	e8 79 ff ff ff       	call   f0101d4f <mpsearch1>
f0101dd6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101dd9:	85 c0                	test   %eax,%eax
f0101ddb:	74 5f                	je     f0101e3c <mp_init+0x91>
	if (mp->physaddr == 0 || mp->type != 0) {
f0101ddd:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101de0:	8b 41 04             	mov    0x4(%ecx),%eax
f0101de3:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101de6:	85 c0                	test   %eax,%eax
f0101de8:	74 6d                	je     f0101e57 <mp_init+0xac>
f0101dea:	80 79 0b 00          	cmpb   $0x0,0xb(%ecx)
f0101dee:	75 67                	jne    f0101e57 <mp_init+0xac>
	conf = (struct mpconf *) P2V(mp->physaddr);
f0101df0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101df3:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
f0101df9:	89 de                	mov    %ebx,%esi
	if (memcmp(conf, "PCMP", 4) != 0) {
f0101dfb:	83 ec 04             	sub    $0x4,%esp
f0101dfe:	6a 04                	push   $0x4
f0101e00:	68 45 35 10 f0       	push   $0xf0103545
f0101e05:	53                   	push   %ebx
f0101e06:	e8 e6 0f 00 00       	call   f0102df1 <memcmp>
f0101e0b:	83 c4 10             	add    $0x10,%esp
f0101e0e:	85 c0                	test   %eax,%eax
f0101e10:	75 5a                	jne    f0101e6c <mp_init+0xc1>
f0101e12:	0f b7 7b 04          	movzwl 0x4(%ebx),%edi
f0101e16:	01 df                	add    %ebx,%edi
	sum = 0;
f0101e18:	89 c2                	mov    %eax,%edx
f0101e1a:	eb 6d                	jmp    f0101e89 <mp_init+0xde>
		p = *(uint16_t *) (bda + 0x13) * 1024;
f0101e1c:	0f b7 05 13 04 00 f0 	movzwl 0xf0000413,%eax
f0101e23:	c1 e0 0a             	shl    $0xa,%eax
		if ((mp = mpsearch1(p - 1024, 1024)))
f0101e26:	2d 00 04 00 00       	sub    $0x400,%eax
f0101e2b:	ba 00 04 00 00       	mov    $0x400,%edx
f0101e30:	e8 1a ff ff ff       	call   f0101d4f <mpsearch1>
f0101e35:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101e38:	85 c0                	test   %eax,%eax
f0101e3a:	75 a1                	jne    f0101ddd <mp_init+0x32>
	return mpsearch1(0xF0000, 0x10000);
f0101e3c:	ba 00 00 01 00       	mov    $0x10000,%edx
f0101e41:	b8 00 00 0f 00       	mov    $0xf0000,%eax
f0101e46:	e8 04 ff ff ff       	call   f0101d4f <mpsearch1>
f0101e4b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	if ((mp = mpsearch()) == 0)
f0101e4e:	85 c0                	test   %eax,%eax
f0101e50:	75 8b                	jne    f0101ddd <mp_init+0x32>
f0101e52:	e9 98 01 00 00       	jmp    f0101fef <mp_init+0x244>
		cprintf("SMP: Default configurations not implemented\n");
f0101e57:	83 ec 0c             	sub    $0xc,%esp
f0101e5a:	68 68 35 10 f0       	push   $0xf0103568
f0101e5f:	e8 17 e9 ff ff       	call   f010077b <cprintf>
f0101e64:	83 c4 10             	add    $0x10,%esp
f0101e67:	e9 83 01 00 00       	jmp    f0101fef <mp_init+0x244>
		cprintf("SMP: Incorrect MP configuration table signature\n");
f0101e6c:	83 ec 0c             	sub    $0xc,%esp
f0101e6f:	68 98 35 10 f0       	push   $0xf0103598
f0101e74:	e8 02 e9 ff ff       	call   f010077b <cprintf>
f0101e79:	83 c4 10             	add    $0x10,%esp
f0101e7c:	e9 6e 01 00 00       	jmp    f0101fef <mp_init+0x244>
		sum += ((uint8_t *)addr)[i];
f0101e81:	0f b6 0b             	movzbl (%ebx),%ecx
f0101e84:	01 ca                	add    %ecx,%edx
f0101e86:	83 c3 01             	add    $0x1,%ebx
	for (i = 0; i < len; i++)
f0101e89:	39 fb                	cmp    %edi,%ebx
f0101e8b:	75 f4                	jne    f0101e81 <mp_init+0xd6>
	if (sum(conf, conf->length) != 0) {
f0101e8d:	84 d2                	test   %dl,%dl
f0101e8f:	75 16                	jne    f0101ea7 <mp_init+0xfc>
	if (conf->version != 1 && conf->version != 4) {
f0101e91:	0f b6 56 06          	movzbl 0x6(%esi),%edx
f0101e95:	80 fa 01             	cmp    $0x1,%dl
f0101e98:	74 05                	je     f0101e9f <mp_init+0xf4>
f0101e9a:	80 fa 04             	cmp    $0x4,%dl
f0101e9d:	75 1d                	jne    f0101ebc <mp_init+0x111>
f0101e9f:	0f b7 4e 28          	movzwl 0x28(%esi),%ecx
f0101ea3:	01 d9                	add    %ebx,%ecx
f0101ea5:	eb 36                	jmp    f0101edd <mp_init+0x132>
		cprintf("SMP: Bad MP configuration checksum\n");
f0101ea7:	83 ec 0c             	sub    $0xc,%esp
f0101eaa:	68 cc 35 10 f0       	push   $0xf01035cc
f0101eaf:	e8 c7 e8 ff ff       	call   f010077b <cprintf>
f0101eb4:	83 c4 10             	add    $0x10,%esp
f0101eb7:	e9 33 01 00 00       	jmp    f0101fef <mp_init+0x244>
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
f0101ebc:	83 ec 08             	sub    $0x8,%esp
f0101ebf:	0f b6 d2             	movzbl %dl,%edx
f0101ec2:	52                   	push   %edx
f0101ec3:	68 f0 35 10 f0       	push   $0xf01035f0
f0101ec8:	e8 ae e8 ff ff       	call   f010077b <cprintf>
f0101ecd:	83 c4 10             	add    $0x10,%esp
f0101ed0:	e9 1a 01 00 00       	jmp    f0101fef <mp_init+0x244>
		sum += ((uint8_t *)addr)[i];
f0101ed5:	0f b6 13             	movzbl (%ebx),%edx
f0101ed8:	01 d0                	add    %edx,%eax
f0101eda:	83 c3 01             	add    $0x1,%ebx
	for (i = 0; i < len; i++)
f0101edd:	39 d9                	cmp    %ebx,%ecx
f0101edf:	75 f4                	jne    f0101ed5 <mp_init+0x12a>
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f0101ee1:	02 46 2a             	add    0x2a(%esi),%al
f0101ee4:	75 29                	jne    f0101f0f <mp_init+0x164>
	if ((conf = mpconfig(&mp)) == 0)
f0101ee6:	81 7d e0 00 00 00 10 	cmpl   $0x10000000,-0x20(%ebp)
f0101eed:	0f 84 fc 00 00 00    	je     f0101fef <mp_init+0x244>
		return;
	ismp = 1;
f0101ef3:	c7 05 00 b0 11 f0 01 	movl   $0x1,0xf011b000
f0101efa:	00 00 00 
	lapicaddr = conf->lapicaddr;
f0101efd:	8b 46 24             	mov    0x24(%esi),%eax
f0101f00:	a3 00 c0 15 f0       	mov    %eax,0xf015c000

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0101f05:	8d 7e 2c             	lea    0x2c(%esi),%edi
f0101f08:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101f0d:	eb 54                	jmp    f0101f63 <mp_init+0x1b8>
		cprintf("SMP: Bad MP configuration extended checksum\n");
f0101f0f:	83 ec 0c             	sub    $0xc,%esp
f0101f12:	68 10 36 10 f0       	push   $0xf0103610
f0101f17:	e8 5f e8 ff ff       	call   f010077b <cprintf>
f0101f1c:	83 c4 10             	add    $0x10,%esp
f0101f1f:	e9 cb 00 00 00       	jmp    f0101fef <mp_init+0x244>
		switch (*p) {
		case MPPROC:
			proc = (struct mpproc *)p;
			if (proc->flags & MPPROC_BOOT)
f0101f24:	f6 47 03 02          	testb  $0x2,0x3(%edi)
f0101f28:	74 15                	je     f0101f3f <mp_init+0x194>
				bootcpu = &cpus[ncpu];
f0101f2a:	a1 24 b5 11 f0       	mov    0xf011b524,%eax
f0101f2f:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0101f32:	c1 e0 05             	shl    $0x5,%eax
f0101f35:	05 20 b0 11 f0       	add    $0xf011b020,%eax
f0101f3a:	a3 20 b5 11 f0       	mov    %eax,0xf011b520
			if (ncpu < NCPU) {
f0101f3f:	a1 24 b5 11 f0       	mov    0xf011b524,%eax
f0101f44:	83 f8 07             	cmp    $0x7,%eax
f0101f47:	7f 32                	jg     f0101f7b <mp_init+0x1d0>
				cpus[ncpu].cpu_id = ncpu;
f0101f49:	8d 14 80             	lea    (%eax,%eax,4),%edx
f0101f4c:	c1 e2 05             	shl    $0x5,%edx
f0101f4f:	88 82 20 b0 11 f0    	mov    %al,-0xfee4fe0(%edx)
				ncpu++;
f0101f55:	83 c0 01             	add    $0x1,%eax
f0101f58:	a3 24 b5 11 f0       	mov    %eax,0xf011b524
			} else {
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
					proc->apicid);
			}
			p += sizeof(struct mpproc);
f0101f5d:	83 c7 14             	add    $0x14,%edi
	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0101f60:	83 c3 01             	add    $0x1,%ebx
f0101f63:	0f b7 46 22          	movzwl 0x22(%esi),%eax
f0101f67:	39 d8                	cmp    %ebx,%eax
f0101f69:	76 4b                	jbe    f0101fb6 <mp_init+0x20b>
		switch (*p) {
f0101f6b:	0f b6 07             	movzbl (%edi),%eax
f0101f6e:	84 c0                	test   %al,%al
f0101f70:	74 b2                	je     f0101f24 <mp_init+0x179>
f0101f72:	3c 04                	cmp    $0x4,%al
f0101f74:	77 1c                	ja     f0101f92 <mp_init+0x1e7>
			continue;
		case MPBUS:
		case MPIOAPIC:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
f0101f76:	83 c7 08             	add    $0x8,%edi
			continue;
f0101f79:	eb e5                	jmp    f0101f60 <mp_init+0x1b5>
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
f0101f7b:	83 ec 08             	sub    $0x8,%esp
f0101f7e:	0f b6 47 01          	movzbl 0x1(%edi),%eax
f0101f82:	50                   	push   %eax
f0101f83:	68 40 36 10 f0       	push   $0xf0103640
f0101f88:	e8 ee e7 ff ff       	call   f010077b <cprintf>
f0101f8d:	83 c4 10             	add    $0x10,%esp
f0101f90:	eb cb                	jmp    f0101f5d <mp_init+0x1b2>
		default:
			cprintf("mpinit: unknown config type %x\n", *p);
f0101f92:	83 ec 08             	sub    $0x8,%esp
		switch (*p) {
f0101f95:	0f b6 c0             	movzbl %al,%eax
			cprintf("mpinit: unknown config type %x\n", *p);
f0101f98:	50                   	push   %eax
f0101f99:	68 68 36 10 f0       	push   $0xf0103668
f0101f9e:	e8 d8 e7 ff ff       	call   f010077b <cprintf>
			ismp = 0;
f0101fa3:	c7 05 00 b0 11 f0 00 	movl   $0x0,0xf011b000
f0101faa:	00 00 00 
			i = conf->entry;
f0101fad:	0f b7 5e 22          	movzwl 0x22(%esi),%ebx
f0101fb1:	83 c4 10             	add    $0x10,%esp
f0101fb4:	eb aa                	jmp    f0101f60 <mp_init+0x1b5>
		}
	}

	bootcpu->cpu_status = CPU_STARTED;
f0101fb6:	a1 20 b5 11 f0       	mov    0xf011b520,%eax
f0101fbb:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	if (!ismp) {
f0101fc2:	83 3d 00 b0 11 f0 00 	cmpl   $0x0,0xf011b000
f0101fc9:	75 2c                	jne    f0101ff7 <mp_init+0x24c>
		// Didn't like what we found; fall back to no MP.
		ncpu = 1;
f0101fcb:	c7 05 24 b5 11 f0 01 	movl   $0x1,0xf011b524
f0101fd2:	00 00 00 
		lapicaddr = 0;
f0101fd5:	c7 05 00 c0 15 f0 00 	movl   $0x0,0xf015c000
f0101fdc:	00 00 00 
		cprintf("SMP: configuration not found, SMP disabled\n");
f0101fdf:	83 ec 0c             	sub    $0xc,%esp
f0101fe2:	68 88 36 10 f0       	push   $0xf0103688
f0101fe7:	e8 8f e7 ff ff       	call   f010077b <cprintf>
		return;
f0101fec:	83 c4 10             	add    $0x10,%esp
		// switch to getting interrupts from the LAPIC.
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
		outb(0x22, 0x70);   // Select IMCR
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
	}
}
f0101fef:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101ff2:	5b                   	pop    %ebx
f0101ff3:	5e                   	pop    %esi
f0101ff4:	5f                   	pop    %edi
f0101ff5:	5d                   	pop    %ebp
f0101ff6:	c3                   	ret    
	cprintf("SMP: CPU %d found %d CPU(s)\n", bootcpu->cpu_id,  ncpu);
f0101ff7:	83 ec 04             	sub    $0x4,%esp
f0101ffa:	ff 35 24 b5 11 f0    	pushl  0xf011b524
f0102000:	0f b6 00             	movzbl (%eax),%eax
f0102003:	50                   	push   %eax
f0102004:	68 4a 35 10 f0       	push   $0xf010354a
f0102009:	e8 6d e7 ff ff       	call   f010077b <cprintf>
	if (mp->imcrp) {
f010200e:	83 c4 10             	add    $0x10,%esp
f0102011:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102014:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
f0102018:	74 d5                	je     f0101fef <mp_init+0x244>
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
f010201a:	83 ec 0c             	sub    $0xc,%esp
f010201d:	68 b4 36 10 f0       	push   $0xf01036b4
f0102022:	e8 54 e7 ff ff       	call   f010077b <cprintf>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102027:	b8 70 00 00 00       	mov    $0x70,%eax
f010202c:	ba 22 00 00 00       	mov    $0x22,%edx
f0102031:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102032:	ba 23 00 00 00       	mov    $0x23,%edx
f0102037:	ec                   	in     (%dx),%al
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
f0102038:	83 c8 01             	or     $0x1,%eax
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010203b:	ee                   	out    %al,(%dx)
f010203c:	83 c4 10             	add    $0x10,%esp
f010203f:	eb ae                	jmp    f0101fef <mp_init+0x244>

f0102041 <lapicw>:
physaddr_t lapicaddr;        // Initialized in mpconfig.c
volatile uint32_t *lapic;

static void
lapicw(int index, int value)
{
f0102041:	55                   	push   %ebp
f0102042:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
f0102044:	8b 0d 04 c0 15 f0    	mov    0xf015c004,%ecx
f010204a:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f010204d:	89 10                	mov    %edx,(%eax)
	lapic[ID];  // wait for write to finish, by reading
f010204f:	a1 04 c0 15 f0       	mov    0xf015c004,%eax
f0102054:	8b 40 20             	mov    0x20(%eax),%eax
}
f0102057:	5d                   	pop    %ebp
f0102058:	c3                   	ret    

f0102059 <cpunum>:
	lapicw(TPR, 0);
}

int
cpunum(void)
{
f0102059:	55                   	push   %ebp
f010205a:	89 e5                	mov    %esp,%ebp
	if (lapic)
f010205c:	8b 15 04 c0 15 f0    	mov    0xf015c004,%edx
		return lapic[ID] >> 24;
	return 0;
f0102062:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lapic)
f0102067:	85 d2                	test   %edx,%edx
f0102069:	74 06                	je     f0102071 <cpunum+0x18>
		return lapic[ID] >> 24;
f010206b:	8b 42 20             	mov    0x20(%edx),%eax
f010206e:	c1 e8 18             	shr    $0x18,%eax
}
f0102071:	5d                   	pop    %ebp
f0102072:	c3                   	ret    

f0102073 <lapic_init>:
	if (!lapicaddr)
f0102073:	a1 00 c0 15 f0       	mov    0xf015c000,%eax
f0102078:	85 c0                	test   %eax,%eax
f010207a:	75 02                	jne    f010207e <lapic_init+0xb>
f010207c:	f3 c3                	repz ret 
{
f010207e:	55                   	push   %ebp
f010207f:	89 e5                	mov    %esp,%ebp
	lapic = (uint32_t *)lapicaddr;
f0102081:	a3 04 c0 15 f0       	mov    %eax,0xf015c004
	lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
f0102086:	ba 3f 01 00 00       	mov    $0x13f,%edx
f010208b:	b8 3c 00 00 00       	mov    $0x3c,%eax
f0102090:	e8 ac ff ff ff       	call   f0102041 <lapicw>
	lapicw(TDCR, X1);
f0102095:	ba 0b 00 00 00       	mov    $0xb,%edx
f010209a:	b8 f8 00 00 00       	mov    $0xf8,%eax
f010209f:	e8 9d ff ff ff       	call   f0102041 <lapicw>
	lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
f01020a4:	ba 20 00 02 00       	mov    $0x20020,%edx
f01020a9:	b8 c8 00 00 00       	mov    $0xc8,%eax
f01020ae:	e8 8e ff ff ff       	call   f0102041 <lapicw>
	lapicw(TICR, 10000000); 
f01020b3:	ba 80 96 98 00       	mov    $0x989680,%edx
f01020b8:	b8 e0 00 00 00       	mov    $0xe0,%eax
f01020bd:	e8 7f ff ff ff       	call   f0102041 <lapicw>
	if (thiscpu != bootcpu)
f01020c2:	e8 92 ff ff ff       	call   f0102059 <cpunum>
f01020c7:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01020ca:	c1 e0 05             	shl    $0x5,%eax
f01020cd:	05 20 b0 11 f0       	add    $0xf011b020,%eax
f01020d2:	39 05 20 b5 11 f0    	cmp    %eax,0xf011b520
f01020d8:	74 0f                	je     f01020e9 <lapic_init+0x76>
		lapicw(LINT0, MASKED);
f01020da:	ba 00 00 01 00       	mov    $0x10000,%edx
f01020df:	b8 d4 00 00 00       	mov    $0xd4,%eax
f01020e4:	e8 58 ff ff ff       	call   f0102041 <lapicw>
	lapicw(LINT1, MASKED);
f01020e9:	ba 00 00 01 00       	mov    $0x10000,%edx
f01020ee:	b8 d8 00 00 00       	mov    $0xd8,%eax
f01020f3:	e8 49 ff ff ff       	call   f0102041 <lapicw>
	if (((lapic[VER]>>16) & 0xFF) >= 4)
f01020f8:	a1 04 c0 15 f0       	mov    0xf015c004,%eax
f01020fd:	8b 40 30             	mov    0x30(%eax),%eax
f0102100:	c1 e8 10             	shr    $0x10,%eax
f0102103:	3c 03                	cmp    $0x3,%al
f0102105:	77 7c                	ja     f0102183 <lapic_init+0x110>
	lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
f0102107:	ba 33 00 00 00       	mov    $0x33,%edx
f010210c:	b8 dc 00 00 00       	mov    $0xdc,%eax
f0102111:	e8 2b ff ff ff       	call   f0102041 <lapicw>
	lapicw(ESR, 0);
f0102116:	ba 00 00 00 00       	mov    $0x0,%edx
f010211b:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0102120:	e8 1c ff ff ff       	call   f0102041 <lapicw>
	lapicw(ESR, 0);
f0102125:	ba 00 00 00 00       	mov    $0x0,%edx
f010212a:	b8 a0 00 00 00       	mov    $0xa0,%eax
f010212f:	e8 0d ff ff ff       	call   f0102041 <lapicw>
	lapicw(EOI, 0);
f0102134:	ba 00 00 00 00       	mov    $0x0,%edx
f0102139:	b8 2c 00 00 00       	mov    $0x2c,%eax
f010213e:	e8 fe fe ff ff       	call   f0102041 <lapicw>
	lapicw(ICRHI, 0);
f0102143:	ba 00 00 00 00       	mov    $0x0,%edx
f0102148:	b8 c4 00 00 00       	mov    $0xc4,%eax
f010214d:	e8 ef fe ff ff       	call   f0102041 <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
f0102152:	ba 00 85 08 00       	mov    $0x88500,%edx
f0102157:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010215c:	e8 e0 fe ff ff       	call   f0102041 <lapicw>
	while(lapic[ICRLO] & DELIVS)
f0102161:	8b 15 04 c0 15 f0    	mov    0xf015c004,%edx
f0102167:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f010216d:	f6 c4 10             	test   $0x10,%ah
f0102170:	75 f5                	jne    f0102167 <lapic_init+0xf4>
	lapicw(TPR, 0);
f0102172:	ba 00 00 00 00       	mov    $0x0,%edx
f0102177:	b8 20 00 00 00       	mov    $0x20,%eax
f010217c:	e8 c0 fe ff ff       	call   f0102041 <lapicw>
}
f0102181:	5d                   	pop    %ebp
f0102182:	c3                   	ret    
		lapicw(PCINT, MASKED);
f0102183:	ba 00 00 01 00       	mov    $0x10000,%edx
f0102188:	b8 d0 00 00 00       	mov    $0xd0,%eax
f010218d:	e8 af fe ff ff       	call   f0102041 <lapicw>
f0102192:	e9 70 ff ff ff       	jmp    f0102107 <lapic_init+0x94>

f0102197 <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
	if (lapic)
f0102197:	83 3d 04 c0 15 f0 00 	cmpl   $0x0,0xf015c004
f010219e:	74 14                	je     f01021b4 <lapic_eoi+0x1d>
{
f01021a0:	55                   	push   %ebp
f01021a1:	89 e5                	mov    %esp,%ebp
		lapicw(EOI, 0);
f01021a3:	ba 00 00 00 00       	mov    $0x0,%edx
f01021a8:	b8 2c 00 00 00       	mov    $0x2c,%eax
f01021ad:	e8 8f fe ff ff       	call   f0102041 <lapicw>
}
f01021b2:	5d                   	pop    %ebp
f01021b3:	c3                   	ret    
f01021b4:	f3 c3                	repz ret 

f01021b6 <lapic_startap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startap(uint8_t apicid, uint32_t addr)
{
f01021b6:	55                   	push   %ebp
f01021b7:	89 e5                	mov    %esp,%ebp
f01021b9:	56                   	push   %esi
f01021ba:	53                   	push   %ebx
f01021bb:	8b 75 08             	mov    0x8(%ebp),%esi
f01021be:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01021c1:	b8 0f 00 00 00       	mov    $0xf,%eax
f01021c6:	ba 70 00 00 00       	mov    $0x70,%edx
f01021cb:	ee                   	out    %al,(%dx)
f01021cc:	b8 0a 00 00 00       	mov    $0xa,%eax
f01021d1:	ba 71 00 00 00       	mov    $0x71,%edx
f01021d6:	ee                   	out    %al,(%dx)
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t *)P2V((0x40 << 4 | 0x67));  // Warm reset vector
	wrv[0] = 0;
f01021d7:	66 c7 05 67 04 00 f0 	movw   $0x0,0xf0000467
f01021de:	00 00 
	wrv[1] = addr >> 4;
f01021e0:	89 d8                	mov    %ebx,%eax
f01021e2:	c1 e8 04             	shr    $0x4,%eax
f01021e5:	66 a3 69 04 00 f0    	mov    %ax,0xf0000469

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid << 24);
f01021eb:	c1 e6 18             	shl    $0x18,%esi
f01021ee:	89 f2                	mov    %esi,%edx
f01021f0:	b8 c4 00 00 00       	mov    $0xc4,%eax
f01021f5:	e8 47 fe ff ff       	call   f0102041 <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
f01021fa:	ba 00 c5 00 00       	mov    $0xc500,%edx
f01021ff:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0102204:	e8 38 fe ff ff       	call   f0102041 <lapicw>
	microdelay(200);
	lapicw(ICRLO, INIT | LEVEL);
f0102209:	ba 00 85 00 00       	mov    $0x8500,%edx
f010220e:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0102213:	e8 29 fe ff ff       	call   f0102041 <lapicw>
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0102218:	c1 eb 0c             	shr    $0xc,%ebx
f010221b:	80 cf 06             	or     $0x6,%bh
		lapicw(ICRHI, apicid << 24);
f010221e:	89 f2                	mov    %esi,%edx
f0102220:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0102225:	e8 17 fe ff ff       	call   f0102041 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f010222a:	89 da                	mov    %ebx,%edx
f010222c:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0102231:	e8 0b fe ff ff       	call   f0102041 <lapicw>
		lapicw(ICRHI, apicid << 24);
f0102236:	89 f2                	mov    %esi,%edx
f0102238:	b8 c4 00 00 00       	mov    $0xc4,%eax
f010223d:	e8 ff fd ff ff       	call   f0102041 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0102242:	89 da                	mov    %ebx,%edx
f0102244:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0102249:	e8 f3 fd ff ff       	call   f0102041 <lapicw>
		microdelay(200);
	}
}
f010224e:	5b                   	pop    %ebx
f010224f:	5e                   	pop    %esi
f0102250:	5d                   	pop    %ebp
f0102251:	c3                   	ret    

f0102252 <lapic_ipi>:

void
lapic_ipi(int vector)
{
f0102252:	55                   	push   %ebp
f0102253:	89 e5                	mov    %esp,%ebp
	lapicw(ICRLO, OTHERS | FIXED | vector);
f0102255:	8b 55 08             	mov    0x8(%ebp),%edx
f0102258:	81 ca 00 00 0c 00    	or     $0xc0000,%edx
f010225e:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0102263:	e8 d9 fd ff ff       	call   f0102041 <lapicw>
	while (lapic[ICRLO] & DELIVS)
f0102268:	8b 15 04 c0 15 f0    	mov    0xf015c004,%edx
f010226e:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0102274:	f6 c4 10             	test   $0x10,%ah
f0102277:	75 f5                	jne    f010226e <lapic_ipi+0x1c>
		;
}
f0102279:	5d                   	pop    %ebp
f010227a:	c3                   	ret    

f010227b <__spin_initlock>:
#endif
};

void
__spin_initlock(struct spinlock *lk, char *name)
{
f010227b:	55                   	push   %ebp
f010227c:	89 e5                	mov    %esp,%ebp
f010227e:	8b 45 08             	mov    0x8(%ebp),%eax
	// TODO: Your code here.
	lk->locked = 0;
f0102281:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	lk->name = name;
f0102287:	8b 55 0c             	mov    0xc(%ebp),%edx
f010228a:	89 50 04             	mov    %edx,0x4(%eax)
	lk->cpu = 0;
f010228d:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
f0102294:	5d                   	pop    %ebp
f0102295:	c3                   	ret    

f0102296 <spin_lock>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
f0102296:	55                   	push   %ebp
f0102297:	89 e5                	mov    %esp,%ebp
f0102299:	56                   	push   %esi
f010229a:	53                   	push   %ebx
f010229b:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	// TODO: Your code here.
	if (lk->cpu == thiscpu)
f010229e:	8b 73 08             	mov    0x8(%ebx),%esi
f01022a1:	e8 b3 fd ff ff       	call   f0102059 <cpunum>
f01022a6:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01022a9:	c1 e0 05             	shl    $0x5,%eax
f01022ac:	05 20 b0 11 f0       	add    $0xf011b020,%eax
f01022b1:	39 c6                	cmp    %eax,%esi
f01022b3:	74 28                	je     f01022dd <spin_lock+0x47>
	asm volatile("lock; xchgl %0, %1"
f01022b5:	ba 01 00 00 00       	mov    $0x1,%edx
f01022ba:	89 d0                	mov    %edx,%eax
f01022bc:	f0 87 03             	lock xchg %eax,(%ebx)
		panic("spinlock");
	int locked = 1;
	while(xchg(&lk->locked, locked));
f01022bf:	85 c0                	test   %eax,%eax
f01022c1:	75 f7                	jne    f01022ba <spin_lock+0x24>
	lk->cpu = thiscpu;
f01022c3:	e8 91 fd ff ff       	call   f0102059 <cpunum>
f01022c8:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01022cb:	c1 e0 05             	shl    $0x5,%eax
f01022ce:	05 20 b0 11 f0       	add    $0xf011b020,%eax
f01022d3:	89 43 08             	mov    %eax,0x8(%ebx)
}
f01022d6:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01022d9:	5b                   	pop    %ebx
f01022da:	5e                   	pop    %esi
f01022db:	5d                   	pop    %ebp
f01022dc:	c3                   	ret    
		panic("spinlock");
f01022dd:	83 ec 04             	sub    $0x4,%esp
f01022e0:	68 f8 36 10 f0       	push   $0xf01036f8
f01022e5:	6a 2d                	push   $0x2d
f01022e7:	68 01 37 10 f0       	push   $0xf0103701
f01022ec:	e8 a0 de ff ff       	call   f0100191 <_panic>

f01022f1 <mspin_lock>:

void
mspin_lock(struct mcslock *lk)
{
f01022f1:	55                   	push   %ebp
f01022f2:	89 e5                	mov    %esp,%ebp
f01022f4:	8b 55 08             	mov    0x8(%ebp),%edx
	static __thread struct mcslock_node node;
	struct mcslock_node *me = &node;
	struct mcslock_node *tmp = me;
	me->next = NULL;
f01022f7:	65 c7 05 fc ff ff ff 	movl   $0x0,%gs:0xfffffffc
f01022fe:	00 00 00 00 
	struct mcslock_node *pre = Xchg(&lk->locked, tmp);
f0102302:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
f0102308:	05 f8 ff ff ff       	add    $0xfffffff8,%eax
f010230d:	f0 87 02             	lock xchg %eax,(%edx)
	if (pre == NULL)
f0102310:	85 c0                	test   %eax,%eax
f0102312:	74 29                	je     f010233d <mspin_lock+0x4c>
		return;
	me->waiting = 1;
f0102314:	65 c7 05 f8 ff ff ff 	movl   $0x1,%gs:0xfffffff8
f010231b:	01 00 00 00 
	asm volatile("" : : : "memory");
	pre->next = me;
f010231f:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
f0102326:	81 c2 f8 ff ff ff    	add    $0xfffffff8,%edx
f010232c:	89 50 04             	mov    %edx,0x4(%eax)
	while (me->waiting) 
f010232f:	eb 02                	jmp    f0102333 <mspin_lock+0x42>
		asm volatile("pause");
f0102331:	f3 90                	pause  
	while (me->waiting) 
f0102333:	65 a1 f8 ff ff ff    	mov    %gs:0xfffffff8,%eax
f0102339:	85 c0                	test   %eax,%eax
f010233b:	75 f4                	jne    f0102331 <mspin_lock+0x40>
}
f010233d:	5d                   	pop    %ebp
f010233e:	c3                   	ret    

f010233f <spin_unlock>:

// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
f010233f:	55                   	push   %ebp
f0102340:	89 e5                	mov    %esp,%ebp
f0102342:	56                   	push   %esi
f0102343:	53                   	push   %ebx
f0102344:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// respect to any other instruction which references the same memory.
	// x86 CPUs will not reorder loads/stores across locked instructions
	// (vol 3, 8.2.2). Because xchg() is implemented using asm volatile,
	// gcc will not reorder C statements across the xchg.
	// TODO: Your code here.
	if (lk->cpu == thiscpu) {
f0102347:	8b 73 08             	mov    0x8(%ebx),%esi
f010234a:	e8 0a fd ff ff       	call   f0102059 <cpunum>
f010234f:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0102352:	c1 e0 05             	shl    $0x5,%eax
f0102355:	05 20 b0 11 f0       	add    $0xf011b020,%eax
f010235a:	39 c6                	cmp    %eax,%esi
f010235c:	75 14                	jne    f0102372 <spin_unlock+0x33>
		lk->cpu = 0;
f010235e:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
		//xchg(&lk->locked, 0);
		asm volatile("movl $0, %0" : "+m"(lk->locked) : );
f0102365:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	} else 
		panic("spin_unlock");
}
f010236b:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010236e:	5b                   	pop    %ebx
f010236f:	5e                   	pop    %esi
f0102370:	5d                   	pop    %ebp
f0102371:	c3                   	ret    
		panic("spin_unlock");
f0102372:	83 ec 04             	sub    $0x4,%esp
f0102375:	68 11 37 10 f0       	push   $0xf0103711
f010237a:	6a 54                	push   $0x54
f010237c:	68 01 37 10 f0       	push   $0xf0103701
f0102381:	e8 0b de ff ff       	call   f0100191 <_panic>

f0102386 <mspin_unlock>:
mspin_unlock(struct mcslock *lk)
{
	static __thread struct mcslock_node node;
	struct mcslock_node *me = &node;
	struct mcslock_node *tmp = me;
	if (me->next == NULL) {
f0102386:	65 a1 f4 ff ff ff    	mov    %gs:0xfffffff4,%eax
f010238c:	85 c0                	test   %eax,%eax
f010238e:	74 0d                	je     f010239d <mspin_unlock+0x17>
		if (Cmpxchg(&lk->locked, tmp, NULL) == me)
			return;
		while (me->next == NULL)
			continue;
	}
	me->next->waiting = 0;
f0102390:	65 a1 f4 ff ff ff    	mov    %gs:0xfffffff4,%eax
f0102396:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f010239c:	c3                   	ret    
{
f010239d:	55                   	push   %ebp
f010239e:	89 e5                	mov    %esp,%ebp
f01023a0:	53                   	push   %ebx
		if (Cmpxchg(&lk->locked, tmp, NULL) == me)
f01023a1:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
f01023a8:	81 c2 f0 ff ff ff    	add    $0xfffffff0,%edx

static inline uint32_t
cmpxchg(volatile uint32_t *addr, uint32_t old, uint32_t new) {
	uint32_t result;

	asm volatile("lock; cmpxchgl %2, %1"
f01023ae:	b9 00 00 00 00       	mov    $0x0,%ecx
f01023b3:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01023b6:	89 d0                	mov    %edx,%eax
f01023b8:	f0 0f b1 0b          	lock cmpxchg %ecx,(%ebx)
f01023bc:	39 d0                	cmp    %edx,%eax
f01023be:	74 16                	je     f01023d6 <mspin_unlock+0x50>
		while (me->next == NULL)
f01023c0:	65 a1 f4 ff ff ff    	mov    %gs:0xfffffff4,%eax
f01023c6:	85 c0                	test   %eax,%eax
f01023c8:	74 f6                	je     f01023c0 <mspin_unlock+0x3a>
	me->next->waiting = 0;
f01023ca:	65 a1 f4 ff ff ff    	mov    %gs:0xfffffff4,%eax
f01023d0:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f01023d6:	5b                   	pop    %ebx
f01023d7:	5d                   	pop    %ebp
f01023d8:	c3                   	ret    

f01023d9 <irq_setmask_8259A>:
		irq_setmask_8259A(irq_mask_8259A);
}

void
irq_setmask_8259A(uint16_t mask)
{
f01023d9:	55                   	push   %ebp
f01023da:	89 e5                	mov    %esp,%ebp
f01023dc:	56                   	push   %esi
f01023dd:	53                   	push   %ebx
f01023de:	8b 45 08             	mov    0x8(%ebp),%eax
	int i;
	irq_mask_8259A = mask;
f01023e1:	66 a3 74 97 11 f0    	mov    %ax,0xf0119774
	if (!didinit)
f01023e7:	80 3d 35 a2 11 f0 00 	cmpb   $0x0,0xf011a235
f01023ee:	75 07                	jne    f01023f7 <irq_setmask_8259A+0x1e>
	cprintf("enabled interrupts:");
	for (i = 0; i < 16; i++)
		if (~mask & (1<<i))
			cprintf(" %d", i);
	cprintf("\n");
}
f01023f0:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01023f3:	5b                   	pop    %ebx
f01023f4:	5e                   	pop    %esi
f01023f5:	5d                   	pop    %ebp
f01023f6:	c3                   	ret    
f01023f7:	89 c6                	mov    %eax,%esi
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01023f9:	ba 21 00 00 00       	mov    $0x21,%edx
f01023fe:	ee                   	out    %al,(%dx)
	outb(IO_PIC2+1, (char)(mask >> 8));
f01023ff:	66 c1 e8 08          	shr    $0x8,%ax
f0102403:	ba a1 00 00 00       	mov    $0xa1,%edx
f0102408:	ee                   	out    %al,(%dx)
	cprintf("enabled interrupts:");
f0102409:	83 ec 0c             	sub    $0xc,%esp
f010240c:	68 29 37 10 f0       	push   $0xf0103729
f0102411:	e8 65 e3 ff ff       	call   f010077b <cprintf>
f0102416:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < 16; i++)
f0102419:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (~mask & (1<<i))
f010241e:	0f b7 f6             	movzwl %si,%esi
f0102421:	f7 d6                	not    %esi
f0102423:	eb 08                	jmp    f010242d <irq_setmask_8259A+0x54>
	for (i = 0; i < 16; i++)
f0102425:	83 c3 01             	add    $0x1,%ebx
f0102428:	83 fb 10             	cmp    $0x10,%ebx
f010242b:	74 18                	je     f0102445 <irq_setmask_8259A+0x6c>
		if (~mask & (1<<i))
f010242d:	0f a3 de             	bt     %ebx,%esi
f0102430:	73 f3                	jae    f0102425 <irq_setmask_8259A+0x4c>
			cprintf(" %d", i);
f0102432:	83 ec 08             	sub    $0x8,%esp
f0102435:	53                   	push   %ebx
f0102436:	68 5a 37 10 f0       	push   $0xf010375a
f010243b:	e8 3b e3 ff ff       	call   f010077b <cprintf>
f0102440:	83 c4 10             	add    $0x10,%esp
f0102443:	eb e0                	jmp    f0102425 <irq_setmask_8259A+0x4c>
	cprintf("\n");
f0102445:	83 ec 0c             	sub    $0xc,%esp
f0102448:	68 f8 31 10 f0       	push   $0xf01031f8
f010244d:	e8 29 e3 ff ff       	call   f010077b <cprintf>
f0102452:	83 c4 10             	add    $0x10,%esp
f0102455:	eb 99                	jmp    f01023f0 <irq_setmask_8259A+0x17>

f0102457 <pic_init>:
{
f0102457:	55                   	push   %ebp
f0102458:	89 e5                	mov    %esp,%ebp
f010245a:	57                   	push   %edi
f010245b:	56                   	push   %esi
f010245c:	53                   	push   %ebx
f010245d:	83 ec 0c             	sub    $0xc,%esp
	didinit = 1;
f0102460:	c6 05 35 a2 11 f0 01 	movb   $0x1,0xf011a235
f0102467:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010246c:	bb 21 00 00 00       	mov    $0x21,%ebx
f0102471:	89 da                	mov    %ebx,%edx
f0102473:	ee                   	out    %al,(%dx)
f0102474:	b9 a1 00 00 00       	mov    $0xa1,%ecx
f0102479:	89 ca                	mov    %ecx,%edx
f010247b:	ee                   	out    %al,(%dx)
f010247c:	bf 11 00 00 00       	mov    $0x11,%edi
f0102481:	be 20 00 00 00       	mov    $0x20,%esi
f0102486:	89 f8                	mov    %edi,%eax
f0102488:	89 f2                	mov    %esi,%edx
f010248a:	ee                   	out    %al,(%dx)
f010248b:	b8 20 00 00 00       	mov    $0x20,%eax
f0102490:	89 da                	mov    %ebx,%edx
f0102492:	ee                   	out    %al,(%dx)
f0102493:	b8 04 00 00 00       	mov    $0x4,%eax
f0102498:	ee                   	out    %al,(%dx)
f0102499:	b8 03 00 00 00       	mov    $0x3,%eax
f010249e:	ee                   	out    %al,(%dx)
f010249f:	bb a0 00 00 00       	mov    $0xa0,%ebx
f01024a4:	89 f8                	mov    %edi,%eax
f01024a6:	89 da                	mov    %ebx,%edx
f01024a8:	ee                   	out    %al,(%dx)
f01024a9:	b8 28 00 00 00       	mov    $0x28,%eax
f01024ae:	89 ca                	mov    %ecx,%edx
f01024b0:	ee                   	out    %al,(%dx)
f01024b1:	b8 02 00 00 00       	mov    $0x2,%eax
f01024b6:	ee                   	out    %al,(%dx)
f01024b7:	b8 01 00 00 00       	mov    $0x1,%eax
f01024bc:	ee                   	out    %al,(%dx)
f01024bd:	bf 68 00 00 00       	mov    $0x68,%edi
f01024c2:	89 f8                	mov    %edi,%eax
f01024c4:	89 f2                	mov    %esi,%edx
f01024c6:	ee                   	out    %al,(%dx)
f01024c7:	b9 0a 00 00 00       	mov    $0xa,%ecx
f01024cc:	89 c8                	mov    %ecx,%eax
f01024ce:	ee                   	out    %al,(%dx)
f01024cf:	89 f8                	mov    %edi,%eax
f01024d1:	89 da                	mov    %ebx,%edx
f01024d3:	ee                   	out    %al,(%dx)
f01024d4:	89 c8                	mov    %ecx,%eax
f01024d6:	ee                   	out    %al,(%dx)
	if (irq_mask_8259A != 0xFFFF)
f01024d7:	0f b7 05 74 97 11 f0 	movzwl 0xf0119774,%eax
f01024de:	66 83 f8 ff          	cmp    $0xffff,%ax
f01024e2:	74 0f                	je     f01024f3 <pic_init+0x9c>
		irq_setmask_8259A(irq_mask_8259A);
f01024e4:	83 ec 0c             	sub    $0xc,%esp
f01024e7:	0f b7 c0             	movzwl %ax,%eax
f01024ea:	50                   	push   %eax
f01024eb:	e8 e9 fe ff ff       	call   f01023d9 <irq_setmask_8259A>
f01024f0:	83 c4 10             	add    $0x10,%esp
}
f01024f3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01024f6:	5b                   	pop    %ebx
f01024f7:	5e                   	pop    %esi
f01024f8:	5f                   	pop    %edi
f01024f9:	5d                   	pop    %ebp
f01024fa:	c3                   	ret    

f01024fb <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01024fb:	55                   	push   %ebp
f01024fc:	89 e5                	mov    %esp,%ebp
f01024fe:	57                   	push   %edi
f01024ff:	56                   	push   %esi
f0102500:	53                   	push   %ebx
f0102501:	83 ec 1c             	sub    $0x1c,%esp
f0102504:	89 c7                	mov    %eax,%edi
f0102506:	89 d6                	mov    %edx,%esi
f0102508:	8b 45 08             	mov    0x8(%ebp),%eax
f010250b:	8b 55 0c             	mov    0xc(%ebp),%edx
f010250e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102511:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0102514:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0102517:	bb 00 00 00 00       	mov    $0x0,%ebx
f010251c:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010251f:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0102522:	39 d3                	cmp    %edx,%ebx
f0102524:	72 05                	jb     f010252b <printnum+0x30>
f0102526:	39 45 10             	cmp    %eax,0x10(%ebp)
f0102529:	77 7a                	ja     f01025a5 <printnum+0xaa>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f010252b:	83 ec 0c             	sub    $0xc,%esp
f010252e:	ff 75 18             	pushl  0x18(%ebp)
f0102531:	8b 45 14             	mov    0x14(%ebp),%eax
f0102534:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0102537:	53                   	push   %ebx
f0102538:	ff 75 10             	pushl  0x10(%ebp)
f010253b:	83 ec 08             	sub    $0x8,%esp
f010253e:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102541:	ff 75 e0             	pushl  -0x20(%ebp)
f0102544:	ff 75 dc             	pushl  -0x24(%ebp)
f0102547:	ff 75 d8             	pushl  -0x28(%ebp)
f010254a:	e8 e1 09 00 00       	call   f0102f30 <__udivdi3>
f010254f:	83 c4 18             	add    $0x18,%esp
f0102552:	52                   	push   %edx
f0102553:	50                   	push   %eax
f0102554:	89 f2                	mov    %esi,%edx
f0102556:	89 f8                	mov    %edi,%eax
f0102558:	e8 9e ff ff ff       	call   f01024fb <printnum>
f010255d:	83 c4 20             	add    $0x20,%esp
f0102560:	eb 13                	jmp    f0102575 <printnum+0x7a>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0102562:	83 ec 08             	sub    $0x8,%esp
f0102565:	56                   	push   %esi
f0102566:	ff 75 18             	pushl  0x18(%ebp)
f0102569:	ff d7                	call   *%edi
f010256b:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f010256e:	83 eb 01             	sub    $0x1,%ebx
f0102571:	85 db                	test   %ebx,%ebx
f0102573:	7f ed                	jg     f0102562 <printnum+0x67>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0102575:	83 ec 08             	sub    $0x8,%esp
f0102578:	56                   	push   %esi
f0102579:	83 ec 04             	sub    $0x4,%esp
f010257c:	ff 75 e4             	pushl  -0x1c(%ebp)
f010257f:	ff 75 e0             	pushl  -0x20(%ebp)
f0102582:	ff 75 dc             	pushl  -0x24(%ebp)
f0102585:	ff 75 d8             	pushl  -0x28(%ebp)
f0102588:	e8 c3 0a 00 00       	call   f0103050 <__umoddi3>
f010258d:	83 c4 14             	add    $0x14,%esp
f0102590:	0f be 80 3d 37 10 f0 	movsbl -0xfefc8c3(%eax),%eax
f0102597:	50                   	push   %eax
f0102598:	ff d7                	call   *%edi
}
f010259a:	83 c4 10             	add    $0x10,%esp
f010259d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01025a0:	5b                   	pop    %ebx
f01025a1:	5e                   	pop    %esi
f01025a2:	5f                   	pop    %edi
f01025a3:	5d                   	pop    %ebp
f01025a4:	c3                   	ret    
f01025a5:	8b 5d 14             	mov    0x14(%ebp),%ebx
f01025a8:	eb c4                	jmp    f010256e <printnum+0x73>

f01025aa <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01025aa:	55                   	push   %ebp
f01025ab:	89 e5                	mov    %esp,%ebp
f01025ad:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01025b0:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01025b4:	8b 10                	mov    (%eax),%edx
f01025b6:	3b 50 04             	cmp    0x4(%eax),%edx
f01025b9:	73 0a                	jae    f01025c5 <sprintputch+0x1b>
		*b->buf++ = ch;
f01025bb:	8d 4a 01             	lea    0x1(%edx),%ecx
f01025be:	89 08                	mov    %ecx,(%eax)
f01025c0:	8b 45 08             	mov    0x8(%ebp),%eax
f01025c3:	88 02                	mov    %al,(%edx)
}
f01025c5:	5d                   	pop    %ebp
f01025c6:	c3                   	ret    

f01025c7 <printfmt>:
{
f01025c7:	55                   	push   %ebp
f01025c8:	89 e5                	mov    %esp,%ebp
f01025ca:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f01025cd:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f01025d0:	50                   	push   %eax
f01025d1:	ff 75 10             	pushl  0x10(%ebp)
f01025d4:	ff 75 0c             	pushl  0xc(%ebp)
f01025d7:	ff 75 08             	pushl  0x8(%ebp)
f01025da:	e8 05 00 00 00       	call   f01025e4 <vprintfmt>
}
f01025df:	83 c4 10             	add    $0x10,%esp
f01025e2:	c9                   	leave  
f01025e3:	c3                   	ret    

f01025e4 <vprintfmt>:
{
f01025e4:	55                   	push   %ebp
f01025e5:	89 e5                	mov    %esp,%ebp
f01025e7:	57                   	push   %edi
f01025e8:	56                   	push   %esi
f01025e9:	53                   	push   %ebx
f01025ea:	83 ec 2c             	sub    $0x2c,%esp
f01025ed:	8b 75 08             	mov    0x8(%ebp),%esi
f01025f0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01025f3:	8b 7d 10             	mov    0x10(%ebp),%edi
f01025f6:	e9 c1 03 00 00       	jmp    f01029bc <vprintfmt+0x3d8>
		padc = ' ';
f01025fb:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
f01025ff:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
f0102606:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
		width = -1;
f010260d:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f0102614:	b9 00 00 00 00       	mov    $0x0,%ecx
		switch (ch = *(unsigned char *) fmt++) {
f0102619:	8d 47 01             	lea    0x1(%edi),%eax
f010261c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010261f:	0f b6 17             	movzbl (%edi),%edx
f0102622:	8d 42 dd             	lea    -0x23(%edx),%eax
f0102625:	3c 55                	cmp    $0x55,%al
f0102627:	0f 87 12 04 00 00    	ja     f0102a3f <vprintfmt+0x45b>
f010262d:	0f b6 c0             	movzbl %al,%eax
f0102630:	ff 24 85 c8 37 10 f0 	jmp    *-0xfefc838(,%eax,4)
f0102637:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f010263a:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f010263e:	eb d9                	jmp    f0102619 <vprintfmt+0x35>
		switch (ch = *(unsigned char *) fmt++) {
f0102640:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '0';
f0102643:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0102647:	eb d0                	jmp    f0102619 <vprintfmt+0x35>
		switch (ch = *(unsigned char *) fmt++) {
f0102649:	0f b6 d2             	movzbl %dl,%edx
f010264c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f010264f:	b8 00 00 00 00       	mov    $0x0,%eax
f0102654:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
				precision = precision * 10 + ch - '0';
f0102657:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010265a:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f010265e:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0102661:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0102664:	83 f9 09             	cmp    $0x9,%ecx
f0102667:	77 55                	ja     f01026be <vprintfmt+0xda>
			for (precision = 0; ; ++fmt) {
f0102669:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f010266c:	eb e9                	jmp    f0102657 <vprintfmt+0x73>
			precision = va_arg(ap, int);
f010266e:	8b 45 14             	mov    0x14(%ebp),%eax
f0102671:	8b 00                	mov    (%eax),%eax
f0102673:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102676:	8b 45 14             	mov    0x14(%ebp),%eax
f0102679:	8d 40 04             	lea    0x4(%eax),%eax
f010267c:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010267f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f0102682:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102686:	79 91                	jns    f0102619 <vprintfmt+0x35>
				width = precision, precision = -1;
f0102688:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010268b:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010268e:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102695:	eb 82                	jmp    f0102619 <vprintfmt+0x35>
f0102697:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010269a:	85 c0                	test   %eax,%eax
f010269c:	ba 00 00 00 00       	mov    $0x0,%edx
f01026a1:	0f 49 d0             	cmovns %eax,%edx
f01026a4:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01026a7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01026aa:	e9 6a ff ff ff       	jmp    f0102619 <vprintfmt+0x35>
f01026af:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f01026b2:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f01026b9:	e9 5b ff ff ff       	jmp    f0102619 <vprintfmt+0x35>
f01026be:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01026c1:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01026c4:	eb bc                	jmp    f0102682 <vprintfmt+0x9e>
			lflag++;
f01026c6:	83 c1 01             	add    $0x1,%ecx
		switch (ch = *(unsigned char *) fmt++) {
f01026c9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f01026cc:	e9 48 ff ff ff       	jmp    f0102619 <vprintfmt+0x35>
			putch(va_arg(ap, int), putdat);
f01026d1:	8b 45 14             	mov    0x14(%ebp),%eax
f01026d4:	8d 78 04             	lea    0x4(%eax),%edi
f01026d7:	83 ec 08             	sub    $0x8,%esp
f01026da:	53                   	push   %ebx
f01026db:	ff 30                	pushl  (%eax)
f01026dd:	ff d6                	call   *%esi
			break;
f01026df:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f01026e2:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f01026e5:	e9 cf 02 00 00       	jmp    f01029b9 <vprintfmt+0x3d5>
			err = va_arg(ap, int);
f01026ea:	8b 45 14             	mov    0x14(%ebp),%eax
f01026ed:	8d 78 04             	lea    0x4(%eax),%edi
f01026f0:	8b 00                	mov    (%eax),%eax
f01026f2:	99                   	cltd   
f01026f3:	31 d0                	xor    %edx,%eax
f01026f5:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01026f7:	83 f8 06             	cmp    $0x6,%eax
f01026fa:	7f 23                	jg     f010271f <vprintfmt+0x13b>
f01026fc:	8b 14 85 20 39 10 f0 	mov    -0xfefc6e0(,%eax,4),%edx
f0102703:	85 d2                	test   %edx,%edx
f0102705:	74 18                	je     f010271f <vprintfmt+0x13b>
				printfmt(putch, putdat, "%s", p);
f0102707:	52                   	push   %edx
f0102708:	68 90 34 10 f0       	push   $0xf0103490
f010270d:	53                   	push   %ebx
f010270e:	56                   	push   %esi
f010270f:	e8 b3 fe ff ff       	call   f01025c7 <printfmt>
f0102714:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0102717:	89 7d 14             	mov    %edi,0x14(%ebp)
f010271a:	e9 9a 02 00 00       	jmp    f01029b9 <vprintfmt+0x3d5>
				printfmt(putch, putdat, "error %d", err);
f010271f:	50                   	push   %eax
f0102720:	68 55 37 10 f0       	push   $0xf0103755
f0102725:	53                   	push   %ebx
f0102726:	56                   	push   %esi
f0102727:	e8 9b fe ff ff       	call   f01025c7 <printfmt>
f010272c:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f010272f:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f0102732:	e9 82 02 00 00       	jmp    f01029b9 <vprintfmt+0x3d5>
			if ((p = va_arg(ap, char *)) == NULL)
f0102737:	8b 45 14             	mov    0x14(%ebp),%eax
f010273a:	83 c0 04             	add    $0x4,%eax
f010273d:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102740:	8b 45 14             	mov    0x14(%ebp),%eax
f0102743:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0102745:	85 ff                	test   %edi,%edi
f0102747:	b8 4e 37 10 f0       	mov    $0xf010374e,%eax
f010274c:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f010274f:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102753:	0f 8e bd 00 00 00    	jle    f0102816 <vprintfmt+0x232>
f0102759:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f010275d:	75 0e                	jne    f010276d <vprintfmt+0x189>
f010275f:	89 75 08             	mov    %esi,0x8(%ebp)
f0102762:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102765:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102768:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f010276b:	eb 6d                	jmp    f01027da <vprintfmt+0x1f6>
				for (width -= strnlen(p, precision); width > 0; width--)
f010276d:	83 ec 08             	sub    $0x8,%esp
f0102770:	ff 75 d0             	pushl  -0x30(%ebp)
f0102773:	57                   	push   %edi
f0102774:	e8 50 04 00 00       	call   f0102bc9 <strnlen>
f0102779:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f010277c:	29 c1                	sub    %eax,%ecx
f010277e:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0102781:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0102784:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0102788:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010278b:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f010278e:	89 cf                	mov    %ecx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f0102790:	eb 0f                	jmp    f01027a1 <vprintfmt+0x1bd>
					putch(padc, putdat);
f0102792:	83 ec 08             	sub    $0x8,%esp
f0102795:	53                   	push   %ebx
f0102796:	ff 75 e0             	pushl  -0x20(%ebp)
f0102799:	ff d6                	call   *%esi
				for (width -= strnlen(p, precision); width > 0; width--)
f010279b:	83 ef 01             	sub    $0x1,%edi
f010279e:	83 c4 10             	add    $0x10,%esp
f01027a1:	85 ff                	test   %edi,%edi
f01027a3:	7f ed                	jg     f0102792 <vprintfmt+0x1ae>
f01027a5:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01027a8:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f01027ab:	85 c9                	test   %ecx,%ecx
f01027ad:	b8 00 00 00 00       	mov    $0x0,%eax
f01027b2:	0f 49 c1             	cmovns %ecx,%eax
f01027b5:	29 c1                	sub    %eax,%ecx
f01027b7:	89 75 08             	mov    %esi,0x8(%ebp)
f01027ba:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01027bd:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01027c0:	89 cb                	mov    %ecx,%ebx
f01027c2:	eb 16                	jmp    f01027da <vprintfmt+0x1f6>
				if (altflag && (ch < ' ' || ch > '~'))
f01027c4:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01027c8:	75 31                	jne    f01027fb <vprintfmt+0x217>
					putch(ch, putdat);
f01027ca:	83 ec 08             	sub    $0x8,%esp
f01027cd:	ff 75 0c             	pushl  0xc(%ebp)
f01027d0:	50                   	push   %eax
f01027d1:	ff 55 08             	call   *0x8(%ebp)
f01027d4:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01027d7:	83 eb 01             	sub    $0x1,%ebx
f01027da:	83 c7 01             	add    $0x1,%edi
f01027dd:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
f01027e1:	0f be c2             	movsbl %dl,%eax
f01027e4:	85 c0                	test   %eax,%eax
f01027e6:	74 59                	je     f0102841 <vprintfmt+0x25d>
f01027e8:	85 f6                	test   %esi,%esi
f01027ea:	78 d8                	js     f01027c4 <vprintfmt+0x1e0>
f01027ec:	83 ee 01             	sub    $0x1,%esi
f01027ef:	79 d3                	jns    f01027c4 <vprintfmt+0x1e0>
f01027f1:	89 df                	mov    %ebx,%edi
f01027f3:	8b 75 08             	mov    0x8(%ebp),%esi
f01027f6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01027f9:	eb 37                	jmp    f0102832 <vprintfmt+0x24e>
				if (altflag && (ch < ' ' || ch > '~'))
f01027fb:	0f be d2             	movsbl %dl,%edx
f01027fe:	83 ea 20             	sub    $0x20,%edx
f0102801:	83 fa 5e             	cmp    $0x5e,%edx
f0102804:	76 c4                	jbe    f01027ca <vprintfmt+0x1e6>
					putch('?', putdat);
f0102806:	83 ec 08             	sub    $0x8,%esp
f0102809:	ff 75 0c             	pushl  0xc(%ebp)
f010280c:	6a 3f                	push   $0x3f
f010280e:	ff 55 08             	call   *0x8(%ebp)
f0102811:	83 c4 10             	add    $0x10,%esp
f0102814:	eb c1                	jmp    f01027d7 <vprintfmt+0x1f3>
f0102816:	89 75 08             	mov    %esi,0x8(%ebp)
f0102819:	8b 75 d0             	mov    -0x30(%ebp),%esi
f010281c:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010281f:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102822:	eb b6                	jmp    f01027da <vprintfmt+0x1f6>
				putch(' ', putdat);
f0102824:	83 ec 08             	sub    $0x8,%esp
f0102827:	53                   	push   %ebx
f0102828:	6a 20                	push   $0x20
f010282a:	ff d6                	call   *%esi
			for (; width > 0; width--)
f010282c:	83 ef 01             	sub    $0x1,%edi
f010282f:	83 c4 10             	add    $0x10,%esp
f0102832:	85 ff                	test   %edi,%edi
f0102834:	7f ee                	jg     f0102824 <vprintfmt+0x240>
			if ((p = va_arg(ap, char *)) == NULL)
f0102836:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102839:	89 45 14             	mov    %eax,0x14(%ebp)
f010283c:	e9 78 01 00 00       	jmp    f01029b9 <vprintfmt+0x3d5>
f0102841:	89 df                	mov    %ebx,%edi
f0102843:	8b 75 08             	mov    0x8(%ebp),%esi
f0102846:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102849:	eb e7                	jmp    f0102832 <vprintfmt+0x24e>
	if (lflag >= 2)
f010284b:	83 f9 01             	cmp    $0x1,%ecx
f010284e:	7e 3f                	jle    f010288f <vprintfmt+0x2ab>
		return va_arg(*ap, long long);
f0102850:	8b 45 14             	mov    0x14(%ebp),%eax
f0102853:	8b 50 04             	mov    0x4(%eax),%edx
f0102856:	8b 00                	mov    (%eax),%eax
f0102858:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010285b:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010285e:	8b 45 14             	mov    0x14(%ebp),%eax
f0102861:	8d 40 08             	lea    0x8(%eax),%eax
f0102864:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f0102867:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010286b:	79 5c                	jns    f01028c9 <vprintfmt+0x2e5>
				putch('-', putdat);
f010286d:	83 ec 08             	sub    $0x8,%esp
f0102870:	53                   	push   %ebx
f0102871:	6a 2d                	push   $0x2d
f0102873:	ff d6                	call   *%esi
				num = -(long long) num;
f0102875:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102878:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010287b:	f7 da                	neg    %edx
f010287d:	83 d1 00             	adc    $0x0,%ecx
f0102880:	f7 d9                	neg    %ecx
f0102882:	83 c4 10             	add    $0x10,%esp
			base = 10;
f0102885:	b8 0a 00 00 00       	mov    $0xa,%eax
f010288a:	e9 10 01 00 00       	jmp    f010299f <vprintfmt+0x3bb>
	else if (lflag)
f010288f:	85 c9                	test   %ecx,%ecx
f0102891:	75 1b                	jne    f01028ae <vprintfmt+0x2ca>
		return va_arg(*ap, int);
f0102893:	8b 45 14             	mov    0x14(%ebp),%eax
f0102896:	8b 00                	mov    (%eax),%eax
f0102898:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010289b:	89 c1                	mov    %eax,%ecx
f010289d:	c1 f9 1f             	sar    $0x1f,%ecx
f01028a0:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01028a3:	8b 45 14             	mov    0x14(%ebp),%eax
f01028a6:	8d 40 04             	lea    0x4(%eax),%eax
f01028a9:	89 45 14             	mov    %eax,0x14(%ebp)
f01028ac:	eb b9                	jmp    f0102867 <vprintfmt+0x283>
		return va_arg(*ap, long);
f01028ae:	8b 45 14             	mov    0x14(%ebp),%eax
f01028b1:	8b 00                	mov    (%eax),%eax
f01028b3:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01028b6:	89 c1                	mov    %eax,%ecx
f01028b8:	c1 f9 1f             	sar    $0x1f,%ecx
f01028bb:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01028be:	8b 45 14             	mov    0x14(%ebp),%eax
f01028c1:	8d 40 04             	lea    0x4(%eax),%eax
f01028c4:	89 45 14             	mov    %eax,0x14(%ebp)
f01028c7:	eb 9e                	jmp    f0102867 <vprintfmt+0x283>
			num = getint(&ap, lflag);
f01028c9:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01028cc:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f01028cf:	b8 0a 00 00 00       	mov    $0xa,%eax
f01028d4:	e9 c6 00 00 00       	jmp    f010299f <vprintfmt+0x3bb>
	if (lflag >= 2)
f01028d9:	83 f9 01             	cmp    $0x1,%ecx
f01028dc:	7e 18                	jle    f01028f6 <vprintfmt+0x312>
		return va_arg(*ap, unsigned long long);
f01028de:	8b 45 14             	mov    0x14(%ebp),%eax
f01028e1:	8b 10                	mov    (%eax),%edx
f01028e3:	8b 48 04             	mov    0x4(%eax),%ecx
f01028e6:	8d 40 08             	lea    0x8(%eax),%eax
f01028e9:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01028ec:	b8 0a 00 00 00       	mov    $0xa,%eax
f01028f1:	e9 a9 00 00 00       	jmp    f010299f <vprintfmt+0x3bb>
	else if (lflag)
f01028f6:	85 c9                	test   %ecx,%ecx
f01028f8:	75 1a                	jne    f0102914 <vprintfmt+0x330>
		return va_arg(*ap, unsigned int);
f01028fa:	8b 45 14             	mov    0x14(%ebp),%eax
f01028fd:	8b 10                	mov    (%eax),%edx
f01028ff:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102904:	8d 40 04             	lea    0x4(%eax),%eax
f0102907:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f010290a:	b8 0a 00 00 00       	mov    $0xa,%eax
f010290f:	e9 8b 00 00 00       	jmp    f010299f <vprintfmt+0x3bb>
		return va_arg(*ap, unsigned long);
f0102914:	8b 45 14             	mov    0x14(%ebp),%eax
f0102917:	8b 10                	mov    (%eax),%edx
f0102919:	b9 00 00 00 00       	mov    $0x0,%ecx
f010291e:	8d 40 04             	lea    0x4(%eax),%eax
f0102921:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0102924:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102929:	eb 74                	jmp    f010299f <vprintfmt+0x3bb>
	if (lflag >= 2)
f010292b:	83 f9 01             	cmp    $0x1,%ecx
f010292e:	7e 15                	jle    f0102945 <vprintfmt+0x361>
		return va_arg(*ap, unsigned long long);
f0102930:	8b 45 14             	mov    0x14(%ebp),%eax
f0102933:	8b 10                	mov    (%eax),%edx
f0102935:	8b 48 04             	mov    0x4(%eax),%ecx
f0102938:	8d 40 08             	lea    0x8(%eax),%eax
f010293b:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f010293e:	b8 08 00 00 00       	mov    $0x8,%eax
f0102943:	eb 5a                	jmp    f010299f <vprintfmt+0x3bb>
	else if (lflag)
f0102945:	85 c9                	test   %ecx,%ecx
f0102947:	75 17                	jne    f0102960 <vprintfmt+0x37c>
		return va_arg(*ap, unsigned int);
f0102949:	8b 45 14             	mov    0x14(%ebp),%eax
f010294c:	8b 10                	mov    (%eax),%edx
f010294e:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102953:	8d 40 04             	lea    0x4(%eax),%eax
f0102956:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0102959:	b8 08 00 00 00       	mov    $0x8,%eax
f010295e:	eb 3f                	jmp    f010299f <vprintfmt+0x3bb>
		return va_arg(*ap, unsigned long);
f0102960:	8b 45 14             	mov    0x14(%ebp),%eax
f0102963:	8b 10                	mov    (%eax),%edx
f0102965:	b9 00 00 00 00       	mov    $0x0,%ecx
f010296a:	8d 40 04             	lea    0x4(%eax),%eax
f010296d:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0102970:	b8 08 00 00 00       	mov    $0x8,%eax
f0102975:	eb 28                	jmp    f010299f <vprintfmt+0x3bb>
			putch('0', putdat);
f0102977:	83 ec 08             	sub    $0x8,%esp
f010297a:	53                   	push   %ebx
f010297b:	6a 30                	push   $0x30
f010297d:	ff d6                	call   *%esi
			putch('x', putdat);
f010297f:	83 c4 08             	add    $0x8,%esp
f0102982:	53                   	push   %ebx
f0102983:	6a 78                	push   $0x78
f0102985:	ff d6                	call   *%esi
			num = (unsigned long long)
f0102987:	8b 45 14             	mov    0x14(%ebp),%eax
f010298a:	8b 10                	mov    (%eax),%edx
f010298c:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f0102991:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f0102994:	8d 40 04             	lea    0x4(%eax),%eax
f0102997:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010299a:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f010299f:	83 ec 0c             	sub    $0xc,%esp
f01029a2:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f01029a6:	57                   	push   %edi
f01029a7:	ff 75 e0             	pushl  -0x20(%ebp)
f01029aa:	50                   	push   %eax
f01029ab:	51                   	push   %ecx
f01029ac:	52                   	push   %edx
f01029ad:	89 da                	mov    %ebx,%edx
f01029af:	89 f0                	mov    %esi,%eax
f01029b1:	e8 45 fb ff ff       	call   f01024fb <printnum>
			break;
f01029b6:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f01029b9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01029bc:	83 c7 01             	add    $0x1,%edi
f01029bf:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f01029c3:	83 f8 25             	cmp    $0x25,%eax
f01029c6:	0f 84 2f fc ff ff    	je     f01025fb <vprintfmt+0x17>
			if (ch == '\0')
f01029cc:	85 c0                	test   %eax,%eax
f01029ce:	0f 84 8b 00 00 00    	je     f0102a5f <vprintfmt+0x47b>
			putch(ch, putdat);
f01029d4:	83 ec 08             	sub    $0x8,%esp
f01029d7:	53                   	push   %ebx
f01029d8:	50                   	push   %eax
f01029d9:	ff d6                	call   *%esi
f01029db:	83 c4 10             	add    $0x10,%esp
f01029de:	eb dc                	jmp    f01029bc <vprintfmt+0x3d8>
	if (lflag >= 2)
f01029e0:	83 f9 01             	cmp    $0x1,%ecx
f01029e3:	7e 15                	jle    f01029fa <vprintfmt+0x416>
		return va_arg(*ap, unsigned long long);
f01029e5:	8b 45 14             	mov    0x14(%ebp),%eax
f01029e8:	8b 10                	mov    (%eax),%edx
f01029ea:	8b 48 04             	mov    0x4(%eax),%ecx
f01029ed:	8d 40 08             	lea    0x8(%eax),%eax
f01029f0:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01029f3:	b8 10 00 00 00       	mov    $0x10,%eax
f01029f8:	eb a5                	jmp    f010299f <vprintfmt+0x3bb>
	else if (lflag)
f01029fa:	85 c9                	test   %ecx,%ecx
f01029fc:	75 17                	jne    f0102a15 <vprintfmt+0x431>
		return va_arg(*ap, unsigned int);
f01029fe:	8b 45 14             	mov    0x14(%ebp),%eax
f0102a01:	8b 10                	mov    (%eax),%edx
f0102a03:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102a08:	8d 40 04             	lea    0x4(%eax),%eax
f0102a0b:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0102a0e:	b8 10 00 00 00       	mov    $0x10,%eax
f0102a13:	eb 8a                	jmp    f010299f <vprintfmt+0x3bb>
		return va_arg(*ap, unsigned long);
f0102a15:	8b 45 14             	mov    0x14(%ebp),%eax
f0102a18:	8b 10                	mov    (%eax),%edx
f0102a1a:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102a1f:	8d 40 04             	lea    0x4(%eax),%eax
f0102a22:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0102a25:	b8 10 00 00 00       	mov    $0x10,%eax
f0102a2a:	e9 70 ff ff ff       	jmp    f010299f <vprintfmt+0x3bb>
			putch(ch, putdat);
f0102a2f:	83 ec 08             	sub    $0x8,%esp
f0102a32:	53                   	push   %ebx
f0102a33:	6a 25                	push   $0x25
f0102a35:	ff d6                	call   *%esi
			break;
f0102a37:	83 c4 10             	add    $0x10,%esp
f0102a3a:	e9 7a ff ff ff       	jmp    f01029b9 <vprintfmt+0x3d5>
			putch('%', putdat);
f0102a3f:	83 ec 08             	sub    $0x8,%esp
f0102a42:	53                   	push   %ebx
f0102a43:	6a 25                	push   $0x25
f0102a45:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0102a47:	83 c4 10             	add    $0x10,%esp
f0102a4a:	89 f8                	mov    %edi,%eax
f0102a4c:	eb 03                	jmp    f0102a51 <vprintfmt+0x46d>
f0102a4e:	83 e8 01             	sub    $0x1,%eax
f0102a51:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f0102a55:	75 f7                	jne    f0102a4e <vprintfmt+0x46a>
f0102a57:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102a5a:	e9 5a ff ff ff       	jmp    f01029b9 <vprintfmt+0x3d5>
}
f0102a5f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102a62:	5b                   	pop    %ebx
f0102a63:	5e                   	pop    %esi
f0102a64:	5f                   	pop    %edi
f0102a65:	5d                   	pop    %ebp
f0102a66:	c3                   	ret    

f0102a67 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0102a67:	55                   	push   %ebp
f0102a68:	89 e5                	mov    %esp,%ebp
f0102a6a:	83 ec 18             	sub    $0x18,%esp
f0102a6d:	8b 45 08             	mov    0x8(%ebp),%eax
f0102a70:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0102a73:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102a76:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0102a7a:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0102a7d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0102a84:	85 c0                	test   %eax,%eax
f0102a86:	74 26                	je     f0102aae <vsnprintf+0x47>
f0102a88:	85 d2                	test   %edx,%edx
f0102a8a:	7e 22                	jle    f0102aae <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0102a8c:	ff 75 14             	pushl  0x14(%ebp)
f0102a8f:	ff 75 10             	pushl  0x10(%ebp)
f0102a92:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0102a95:	50                   	push   %eax
f0102a96:	68 aa 25 10 f0       	push   $0xf01025aa
f0102a9b:	e8 44 fb ff ff       	call   f01025e4 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0102aa0:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102aa3:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0102aa6:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102aa9:	83 c4 10             	add    $0x10,%esp
}
f0102aac:	c9                   	leave  
f0102aad:	c3                   	ret    
		return -E_INVAL;
f0102aae:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0102ab3:	eb f7                	jmp    f0102aac <vsnprintf+0x45>

f0102ab5 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0102ab5:	55                   	push   %ebp
f0102ab6:	89 e5                	mov    %esp,%ebp
f0102ab8:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0102abb:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0102abe:	50                   	push   %eax
f0102abf:	ff 75 10             	pushl  0x10(%ebp)
f0102ac2:	ff 75 0c             	pushl  0xc(%ebp)
f0102ac5:	ff 75 08             	pushl  0x8(%ebp)
f0102ac8:	e8 9a ff ff ff       	call   f0102a67 <vsnprintf>
	va_end(ap);

	return rc;
}
f0102acd:	c9                   	leave  
f0102ace:	c3                   	ret    

f0102acf <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0102acf:	55                   	push   %ebp
f0102ad0:	89 e5                	mov    %esp,%ebp
f0102ad2:	57                   	push   %edi
f0102ad3:	56                   	push   %esi
f0102ad4:	53                   	push   %ebx
f0102ad5:	83 ec 0c             	sub    $0xc,%esp
f0102ad8:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0102adb:	85 c0                	test   %eax,%eax
f0102add:	74 11                	je     f0102af0 <readline+0x21>
		cprintf("%s", prompt);
f0102adf:	83 ec 08             	sub    $0x8,%esp
f0102ae2:	50                   	push   %eax
f0102ae3:	68 90 34 10 f0       	push   $0xf0103490
f0102ae8:	e8 8e dc ff ff       	call   f010077b <cprintf>
f0102aed:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0102af0:	83 ec 0c             	sub    $0xc,%esp
f0102af3:	6a 00                	push   $0x0
f0102af5:	e8 3e dc ff ff       	call   f0100738 <iscons>
f0102afa:	89 c7                	mov    %eax,%edi
f0102afc:	83 c4 10             	add    $0x10,%esp
	i = 0;
f0102aff:	be 00 00 00 00       	mov    $0x0,%esi
f0102b04:	eb 3f                	jmp    f0102b45 <readline+0x76>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f0102b06:	83 ec 08             	sub    $0x8,%esp
f0102b09:	50                   	push   %eax
f0102b0a:	68 3c 39 10 f0       	push   $0xf010393c
f0102b0f:	e8 67 dc ff ff       	call   f010077b <cprintf>
			return NULL;
f0102b14:	83 c4 10             	add    $0x10,%esp
f0102b17:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f0102b1c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102b1f:	5b                   	pop    %ebx
f0102b20:	5e                   	pop    %esi
f0102b21:	5f                   	pop    %edi
f0102b22:	5d                   	pop    %ebp
f0102b23:	c3                   	ret    
			if (echoing)
f0102b24:	85 ff                	test   %edi,%edi
f0102b26:	75 05                	jne    f0102b2d <readline+0x5e>
			i--;
f0102b28:	83 ee 01             	sub    $0x1,%esi
f0102b2b:	eb 18                	jmp    f0102b45 <readline+0x76>
				cputchar('\b');
f0102b2d:	83 ec 0c             	sub    $0xc,%esp
f0102b30:	6a 08                	push   $0x8
f0102b32:	e8 e0 db ff ff       	call   f0100717 <cputchar>
f0102b37:	83 c4 10             	add    $0x10,%esp
f0102b3a:	eb ec                	jmp    f0102b28 <readline+0x59>
			buf[i++] = c;
f0102b3c:	88 9e 40 a2 11 f0    	mov    %bl,-0xfee5dc0(%esi)
f0102b42:	8d 76 01             	lea    0x1(%esi),%esi
		c = getchar();
f0102b45:	e8 dd db ff ff       	call   f0100727 <getchar>
f0102b4a:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0102b4c:	85 c0                	test   %eax,%eax
f0102b4e:	78 b6                	js     f0102b06 <readline+0x37>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0102b50:	83 f8 08             	cmp    $0x8,%eax
f0102b53:	0f 94 c2             	sete   %dl
f0102b56:	83 f8 7f             	cmp    $0x7f,%eax
f0102b59:	0f 94 c0             	sete   %al
f0102b5c:	08 c2                	or     %al,%dl
f0102b5e:	74 04                	je     f0102b64 <readline+0x95>
f0102b60:	85 f6                	test   %esi,%esi
f0102b62:	7f c0                	jg     f0102b24 <readline+0x55>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0102b64:	83 fb 1f             	cmp    $0x1f,%ebx
f0102b67:	7e 1a                	jle    f0102b83 <readline+0xb4>
f0102b69:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0102b6f:	7f 12                	jg     f0102b83 <readline+0xb4>
			if (echoing)
f0102b71:	85 ff                	test   %edi,%edi
f0102b73:	74 c7                	je     f0102b3c <readline+0x6d>
				cputchar(c);
f0102b75:	83 ec 0c             	sub    $0xc,%esp
f0102b78:	53                   	push   %ebx
f0102b79:	e8 99 db ff ff       	call   f0100717 <cputchar>
f0102b7e:	83 c4 10             	add    $0x10,%esp
f0102b81:	eb b9                	jmp    f0102b3c <readline+0x6d>
		} else if (c == '\n' || c == '\r') {
f0102b83:	83 fb 0a             	cmp    $0xa,%ebx
f0102b86:	74 05                	je     f0102b8d <readline+0xbe>
f0102b88:	83 fb 0d             	cmp    $0xd,%ebx
f0102b8b:	75 b8                	jne    f0102b45 <readline+0x76>
			if (echoing)
f0102b8d:	85 ff                	test   %edi,%edi
f0102b8f:	75 11                	jne    f0102ba2 <readline+0xd3>
			buf[i] = 0;
f0102b91:	c6 86 40 a2 11 f0 00 	movb   $0x0,-0xfee5dc0(%esi)
			return buf;
f0102b98:	b8 40 a2 11 f0       	mov    $0xf011a240,%eax
f0102b9d:	e9 7a ff ff ff       	jmp    f0102b1c <readline+0x4d>
				cputchar('\n');
f0102ba2:	83 ec 0c             	sub    $0xc,%esp
f0102ba5:	6a 0a                	push   $0xa
f0102ba7:	e8 6b db ff ff       	call   f0100717 <cputchar>
f0102bac:	83 c4 10             	add    $0x10,%esp
f0102baf:	eb e0                	jmp    f0102b91 <readline+0xc2>

f0102bb1 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0102bb1:	55                   	push   %ebp
f0102bb2:	89 e5                	mov    %esp,%ebp
f0102bb4:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0102bb7:	b8 00 00 00 00       	mov    $0x0,%eax
f0102bbc:	eb 03                	jmp    f0102bc1 <strlen+0x10>
		n++;
f0102bbe:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f0102bc1:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0102bc5:	75 f7                	jne    f0102bbe <strlen+0xd>
	return n;
}
f0102bc7:	5d                   	pop    %ebp
f0102bc8:	c3                   	ret    

f0102bc9 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0102bc9:	55                   	push   %ebp
f0102bca:	89 e5                	mov    %esp,%ebp
f0102bcc:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0102bcf:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0102bd2:	b8 00 00 00 00       	mov    $0x0,%eax
f0102bd7:	eb 03                	jmp    f0102bdc <strnlen+0x13>
		n++;
f0102bd9:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0102bdc:	39 d0                	cmp    %edx,%eax
f0102bde:	74 06                	je     f0102be6 <strnlen+0x1d>
f0102be0:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0102be4:	75 f3                	jne    f0102bd9 <strnlen+0x10>
	return n;
}
f0102be6:	5d                   	pop    %ebp
f0102be7:	c3                   	ret    

f0102be8 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0102be8:	55                   	push   %ebp
f0102be9:	89 e5                	mov    %esp,%ebp
f0102beb:	53                   	push   %ebx
f0102bec:	8b 45 08             	mov    0x8(%ebp),%eax
f0102bef:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0102bf2:	89 c2                	mov    %eax,%edx
f0102bf4:	83 c1 01             	add    $0x1,%ecx
f0102bf7:	83 c2 01             	add    $0x1,%edx
f0102bfa:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0102bfe:	88 5a ff             	mov    %bl,-0x1(%edx)
f0102c01:	84 db                	test   %bl,%bl
f0102c03:	75 ef                	jne    f0102bf4 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0102c05:	5b                   	pop    %ebx
f0102c06:	5d                   	pop    %ebp
f0102c07:	c3                   	ret    

f0102c08 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0102c08:	55                   	push   %ebp
f0102c09:	89 e5                	mov    %esp,%ebp
f0102c0b:	53                   	push   %ebx
f0102c0c:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0102c0f:	53                   	push   %ebx
f0102c10:	e8 9c ff ff ff       	call   f0102bb1 <strlen>
f0102c15:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0102c18:	ff 75 0c             	pushl  0xc(%ebp)
f0102c1b:	01 d8                	add    %ebx,%eax
f0102c1d:	50                   	push   %eax
f0102c1e:	e8 c5 ff ff ff       	call   f0102be8 <strcpy>
	return dst;
}
f0102c23:	89 d8                	mov    %ebx,%eax
f0102c25:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102c28:	c9                   	leave  
f0102c29:	c3                   	ret    

f0102c2a <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0102c2a:	55                   	push   %ebp
f0102c2b:	89 e5                	mov    %esp,%ebp
f0102c2d:	56                   	push   %esi
f0102c2e:	53                   	push   %ebx
f0102c2f:	8b 75 08             	mov    0x8(%ebp),%esi
f0102c32:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102c35:	89 f3                	mov    %esi,%ebx
f0102c37:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0102c3a:	89 f2                	mov    %esi,%edx
f0102c3c:	eb 0f                	jmp    f0102c4d <strncpy+0x23>
		*dst++ = *src;
f0102c3e:	83 c2 01             	add    $0x1,%edx
f0102c41:	0f b6 01             	movzbl (%ecx),%eax
f0102c44:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0102c47:	80 39 01             	cmpb   $0x1,(%ecx)
f0102c4a:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f0102c4d:	39 da                	cmp    %ebx,%edx
f0102c4f:	75 ed                	jne    f0102c3e <strncpy+0x14>
	}
	return ret;
}
f0102c51:	89 f0                	mov    %esi,%eax
f0102c53:	5b                   	pop    %ebx
f0102c54:	5e                   	pop    %esi
f0102c55:	5d                   	pop    %ebp
f0102c56:	c3                   	ret    

f0102c57 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0102c57:	55                   	push   %ebp
f0102c58:	89 e5                	mov    %esp,%ebp
f0102c5a:	56                   	push   %esi
f0102c5b:	53                   	push   %ebx
f0102c5c:	8b 75 08             	mov    0x8(%ebp),%esi
f0102c5f:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102c62:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0102c65:	89 f0                	mov    %esi,%eax
f0102c67:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0102c6b:	85 c9                	test   %ecx,%ecx
f0102c6d:	75 0b                	jne    f0102c7a <strlcpy+0x23>
f0102c6f:	eb 17                	jmp    f0102c88 <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0102c71:	83 c2 01             	add    $0x1,%edx
f0102c74:	83 c0 01             	add    $0x1,%eax
f0102c77:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f0102c7a:	39 d8                	cmp    %ebx,%eax
f0102c7c:	74 07                	je     f0102c85 <strlcpy+0x2e>
f0102c7e:	0f b6 0a             	movzbl (%edx),%ecx
f0102c81:	84 c9                	test   %cl,%cl
f0102c83:	75 ec                	jne    f0102c71 <strlcpy+0x1a>
		*dst = '\0';
f0102c85:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0102c88:	29 f0                	sub    %esi,%eax
}
f0102c8a:	5b                   	pop    %ebx
f0102c8b:	5e                   	pop    %esi
f0102c8c:	5d                   	pop    %ebp
f0102c8d:	c3                   	ret    

f0102c8e <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0102c8e:	55                   	push   %ebp
f0102c8f:	89 e5                	mov    %esp,%ebp
f0102c91:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0102c94:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0102c97:	eb 06                	jmp    f0102c9f <strcmp+0x11>
		p++, q++;
f0102c99:	83 c1 01             	add    $0x1,%ecx
f0102c9c:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f0102c9f:	0f b6 01             	movzbl (%ecx),%eax
f0102ca2:	84 c0                	test   %al,%al
f0102ca4:	74 04                	je     f0102caa <strcmp+0x1c>
f0102ca6:	3a 02                	cmp    (%edx),%al
f0102ca8:	74 ef                	je     f0102c99 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0102caa:	0f b6 c0             	movzbl %al,%eax
f0102cad:	0f b6 12             	movzbl (%edx),%edx
f0102cb0:	29 d0                	sub    %edx,%eax
}
f0102cb2:	5d                   	pop    %ebp
f0102cb3:	c3                   	ret    

f0102cb4 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0102cb4:	55                   	push   %ebp
f0102cb5:	89 e5                	mov    %esp,%ebp
f0102cb7:	53                   	push   %ebx
f0102cb8:	8b 45 08             	mov    0x8(%ebp),%eax
f0102cbb:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102cbe:	89 c3                	mov    %eax,%ebx
f0102cc0:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0102cc3:	eb 06                	jmp    f0102ccb <strncmp+0x17>
		n--, p++, q++;
f0102cc5:	83 c0 01             	add    $0x1,%eax
f0102cc8:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f0102ccb:	39 d8                	cmp    %ebx,%eax
f0102ccd:	74 16                	je     f0102ce5 <strncmp+0x31>
f0102ccf:	0f b6 08             	movzbl (%eax),%ecx
f0102cd2:	84 c9                	test   %cl,%cl
f0102cd4:	74 04                	je     f0102cda <strncmp+0x26>
f0102cd6:	3a 0a                	cmp    (%edx),%cl
f0102cd8:	74 eb                	je     f0102cc5 <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0102cda:	0f b6 00             	movzbl (%eax),%eax
f0102cdd:	0f b6 12             	movzbl (%edx),%edx
f0102ce0:	29 d0                	sub    %edx,%eax
}
f0102ce2:	5b                   	pop    %ebx
f0102ce3:	5d                   	pop    %ebp
f0102ce4:	c3                   	ret    
		return 0;
f0102ce5:	b8 00 00 00 00       	mov    $0x0,%eax
f0102cea:	eb f6                	jmp    f0102ce2 <strncmp+0x2e>

f0102cec <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0102cec:	55                   	push   %ebp
f0102ced:	89 e5                	mov    %esp,%ebp
f0102cef:	8b 45 08             	mov    0x8(%ebp),%eax
f0102cf2:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0102cf6:	0f b6 10             	movzbl (%eax),%edx
f0102cf9:	84 d2                	test   %dl,%dl
f0102cfb:	74 09                	je     f0102d06 <strchr+0x1a>
		if (*s == c)
f0102cfd:	38 ca                	cmp    %cl,%dl
f0102cff:	74 0a                	je     f0102d0b <strchr+0x1f>
	for (; *s; s++)
f0102d01:	83 c0 01             	add    $0x1,%eax
f0102d04:	eb f0                	jmp    f0102cf6 <strchr+0xa>
			return (char *) s;
	return 0;
f0102d06:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102d0b:	5d                   	pop    %ebp
f0102d0c:	c3                   	ret    

f0102d0d <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0102d0d:	55                   	push   %ebp
f0102d0e:	89 e5                	mov    %esp,%ebp
f0102d10:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d13:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0102d17:	eb 03                	jmp    f0102d1c <strfind+0xf>
f0102d19:	83 c0 01             	add    $0x1,%eax
f0102d1c:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0102d1f:	38 ca                	cmp    %cl,%dl
f0102d21:	74 04                	je     f0102d27 <strfind+0x1a>
f0102d23:	84 d2                	test   %dl,%dl
f0102d25:	75 f2                	jne    f0102d19 <strfind+0xc>
			break;
	return (char *) s;
}
f0102d27:	5d                   	pop    %ebp
f0102d28:	c3                   	ret    

f0102d29 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0102d29:	55                   	push   %ebp
f0102d2a:	89 e5                	mov    %esp,%ebp
f0102d2c:	57                   	push   %edi
f0102d2d:	56                   	push   %esi
f0102d2e:	53                   	push   %ebx
f0102d2f:	8b 7d 08             	mov    0x8(%ebp),%edi
f0102d32:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0102d35:	85 c9                	test   %ecx,%ecx
f0102d37:	74 13                	je     f0102d4c <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0102d39:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0102d3f:	75 05                	jne    f0102d46 <memset+0x1d>
f0102d41:	f6 c1 03             	test   $0x3,%cl
f0102d44:	74 0d                	je     f0102d53 <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0102d46:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102d49:	fc                   	cld    
f0102d4a:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0102d4c:	89 f8                	mov    %edi,%eax
f0102d4e:	5b                   	pop    %ebx
f0102d4f:	5e                   	pop    %esi
f0102d50:	5f                   	pop    %edi
f0102d51:	5d                   	pop    %ebp
f0102d52:	c3                   	ret    
		c &= 0xFF;
f0102d53:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0102d57:	89 d3                	mov    %edx,%ebx
f0102d59:	c1 e3 08             	shl    $0x8,%ebx
f0102d5c:	89 d0                	mov    %edx,%eax
f0102d5e:	c1 e0 18             	shl    $0x18,%eax
f0102d61:	89 d6                	mov    %edx,%esi
f0102d63:	c1 e6 10             	shl    $0x10,%esi
f0102d66:	09 f0                	or     %esi,%eax
f0102d68:	09 c2                	or     %eax,%edx
f0102d6a:	09 da                	or     %ebx,%edx
			:: "D" (v), "a" (c), "c" (n/4)
f0102d6c:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f0102d6f:	89 d0                	mov    %edx,%eax
f0102d71:	fc                   	cld    
f0102d72:	f3 ab                	rep stos %eax,%es:(%edi)
f0102d74:	eb d6                	jmp    f0102d4c <memset+0x23>

f0102d76 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0102d76:	55                   	push   %ebp
f0102d77:	89 e5                	mov    %esp,%ebp
f0102d79:	57                   	push   %edi
f0102d7a:	56                   	push   %esi
f0102d7b:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d7e:	8b 75 0c             	mov    0xc(%ebp),%esi
f0102d81:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0102d84:	39 c6                	cmp    %eax,%esi
f0102d86:	73 35                	jae    f0102dbd <memmove+0x47>
f0102d88:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0102d8b:	39 c2                	cmp    %eax,%edx
f0102d8d:	76 2e                	jbe    f0102dbd <memmove+0x47>
		s += n;
		d += n;
f0102d8f:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0102d92:	89 d6                	mov    %edx,%esi
f0102d94:	09 fe                	or     %edi,%esi
f0102d96:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0102d9c:	74 0c                	je     f0102daa <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0102d9e:	83 ef 01             	sub    $0x1,%edi
f0102da1:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f0102da4:	fd                   	std    
f0102da5:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0102da7:	fc                   	cld    
f0102da8:	eb 21                	jmp    f0102dcb <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0102daa:	f6 c1 03             	test   $0x3,%cl
f0102dad:	75 ef                	jne    f0102d9e <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0102daf:	83 ef 04             	sub    $0x4,%edi
f0102db2:	8d 72 fc             	lea    -0x4(%edx),%esi
f0102db5:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f0102db8:	fd                   	std    
f0102db9:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0102dbb:	eb ea                	jmp    f0102da7 <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0102dbd:	89 f2                	mov    %esi,%edx
f0102dbf:	09 c2                	or     %eax,%edx
f0102dc1:	f6 c2 03             	test   $0x3,%dl
f0102dc4:	74 09                	je     f0102dcf <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0102dc6:	89 c7                	mov    %eax,%edi
f0102dc8:	fc                   	cld    
f0102dc9:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0102dcb:	5e                   	pop    %esi
f0102dcc:	5f                   	pop    %edi
f0102dcd:	5d                   	pop    %ebp
f0102dce:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0102dcf:	f6 c1 03             	test   $0x3,%cl
f0102dd2:	75 f2                	jne    f0102dc6 <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0102dd4:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f0102dd7:	89 c7                	mov    %eax,%edi
f0102dd9:	fc                   	cld    
f0102dda:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0102ddc:	eb ed                	jmp    f0102dcb <memmove+0x55>

f0102dde <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0102dde:	55                   	push   %ebp
f0102ddf:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0102de1:	ff 75 10             	pushl  0x10(%ebp)
f0102de4:	ff 75 0c             	pushl  0xc(%ebp)
f0102de7:	ff 75 08             	pushl  0x8(%ebp)
f0102dea:	e8 87 ff ff ff       	call   f0102d76 <memmove>
}
f0102def:	c9                   	leave  
f0102df0:	c3                   	ret    

f0102df1 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0102df1:	55                   	push   %ebp
f0102df2:	89 e5                	mov    %esp,%ebp
f0102df4:	56                   	push   %esi
f0102df5:	53                   	push   %ebx
f0102df6:	8b 45 08             	mov    0x8(%ebp),%eax
f0102df9:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102dfc:	89 c6                	mov    %eax,%esi
f0102dfe:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0102e01:	39 f0                	cmp    %esi,%eax
f0102e03:	74 1c                	je     f0102e21 <memcmp+0x30>
		if (*s1 != *s2)
f0102e05:	0f b6 08             	movzbl (%eax),%ecx
f0102e08:	0f b6 1a             	movzbl (%edx),%ebx
f0102e0b:	38 d9                	cmp    %bl,%cl
f0102e0d:	75 08                	jne    f0102e17 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f0102e0f:	83 c0 01             	add    $0x1,%eax
f0102e12:	83 c2 01             	add    $0x1,%edx
f0102e15:	eb ea                	jmp    f0102e01 <memcmp+0x10>
			return (int) *s1 - (int) *s2;
f0102e17:	0f b6 c1             	movzbl %cl,%eax
f0102e1a:	0f b6 db             	movzbl %bl,%ebx
f0102e1d:	29 d8                	sub    %ebx,%eax
f0102e1f:	eb 05                	jmp    f0102e26 <memcmp+0x35>
	}

	return 0;
f0102e21:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102e26:	5b                   	pop    %ebx
f0102e27:	5e                   	pop    %esi
f0102e28:	5d                   	pop    %ebp
f0102e29:	c3                   	ret    

f0102e2a <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0102e2a:	55                   	push   %ebp
f0102e2b:	89 e5                	mov    %esp,%ebp
f0102e2d:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e30:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0102e33:	89 c2                	mov    %eax,%edx
f0102e35:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0102e38:	39 d0                	cmp    %edx,%eax
f0102e3a:	73 09                	jae    f0102e45 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f0102e3c:	38 08                	cmp    %cl,(%eax)
f0102e3e:	74 05                	je     f0102e45 <memfind+0x1b>
	for (; s < ends; s++)
f0102e40:	83 c0 01             	add    $0x1,%eax
f0102e43:	eb f3                	jmp    f0102e38 <memfind+0xe>
			break;
	return (void *) s;
}
f0102e45:	5d                   	pop    %ebp
f0102e46:	c3                   	ret    

f0102e47 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0102e47:	55                   	push   %ebp
f0102e48:	89 e5                	mov    %esp,%ebp
f0102e4a:	57                   	push   %edi
f0102e4b:	56                   	push   %esi
f0102e4c:	53                   	push   %ebx
f0102e4d:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0102e50:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0102e53:	eb 03                	jmp    f0102e58 <strtol+0x11>
		s++;
f0102e55:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f0102e58:	0f b6 01             	movzbl (%ecx),%eax
f0102e5b:	3c 20                	cmp    $0x20,%al
f0102e5d:	74 f6                	je     f0102e55 <strtol+0xe>
f0102e5f:	3c 09                	cmp    $0x9,%al
f0102e61:	74 f2                	je     f0102e55 <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f0102e63:	3c 2b                	cmp    $0x2b,%al
f0102e65:	74 2e                	je     f0102e95 <strtol+0x4e>
	int neg = 0;
f0102e67:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f0102e6c:	3c 2d                	cmp    $0x2d,%al
f0102e6e:	74 2f                	je     f0102e9f <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0102e70:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0102e76:	75 05                	jne    f0102e7d <strtol+0x36>
f0102e78:	80 39 30             	cmpb   $0x30,(%ecx)
f0102e7b:	74 2c                	je     f0102ea9 <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0102e7d:	85 db                	test   %ebx,%ebx
f0102e7f:	75 0a                	jne    f0102e8b <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0102e81:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
f0102e86:	80 39 30             	cmpb   $0x30,(%ecx)
f0102e89:	74 28                	je     f0102eb3 <strtol+0x6c>
		base = 10;
f0102e8b:	b8 00 00 00 00       	mov    $0x0,%eax
f0102e90:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0102e93:	eb 50                	jmp    f0102ee5 <strtol+0x9e>
		s++;
f0102e95:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f0102e98:	bf 00 00 00 00       	mov    $0x0,%edi
f0102e9d:	eb d1                	jmp    f0102e70 <strtol+0x29>
		s++, neg = 1;
f0102e9f:	83 c1 01             	add    $0x1,%ecx
f0102ea2:	bf 01 00 00 00       	mov    $0x1,%edi
f0102ea7:	eb c7                	jmp    f0102e70 <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0102ea9:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0102ead:	74 0e                	je     f0102ebd <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f0102eaf:	85 db                	test   %ebx,%ebx
f0102eb1:	75 d8                	jne    f0102e8b <strtol+0x44>
		s++, base = 8;
f0102eb3:	83 c1 01             	add    $0x1,%ecx
f0102eb6:	bb 08 00 00 00       	mov    $0x8,%ebx
f0102ebb:	eb ce                	jmp    f0102e8b <strtol+0x44>
		s += 2, base = 16;
f0102ebd:	83 c1 02             	add    $0x2,%ecx
f0102ec0:	bb 10 00 00 00       	mov    $0x10,%ebx
f0102ec5:	eb c4                	jmp    f0102e8b <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f0102ec7:	8d 72 9f             	lea    -0x61(%edx),%esi
f0102eca:	89 f3                	mov    %esi,%ebx
f0102ecc:	80 fb 19             	cmp    $0x19,%bl
f0102ecf:	77 29                	ja     f0102efa <strtol+0xb3>
			dig = *s - 'a' + 10;
f0102ed1:	0f be d2             	movsbl %dl,%edx
f0102ed4:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0102ed7:	3b 55 10             	cmp    0x10(%ebp),%edx
f0102eda:	7d 30                	jge    f0102f0c <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f0102edc:	83 c1 01             	add    $0x1,%ecx
f0102edf:	0f af 45 10          	imul   0x10(%ebp),%eax
f0102ee3:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f0102ee5:	0f b6 11             	movzbl (%ecx),%edx
f0102ee8:	8d 72 d0             	lea    -0x30(%edx),%esi
f0102eeb:	89 f3                	mov    %esi,%ebx
f0102eed:	80 fb 09             	cmp    $0x9,%bl
f0102ef0:	77 d5                	ja     f0102ec7 <strtol+0x80>
			dig = *s - '0';
f0102ef2:	0f be d2             	movsbl %dl,%edx
f0102ef5:	83 ea 30             	sub    $0x30,%edx
f0102ef8:	eb dd                	jmp    f0102ed7 <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
f0102efa:	8d 72 bf             	lea    -0x41(%edx),%esi
f0102efd:	89 f3                	mov    %esi,%ebx
f0102eff:	80 fb 19             	cmp    $0x19,%bl
f0102f02:	77 08                	ja     f0102f0c <strtol+0xc5>
			dig = *s - 'A' + 10;
f0102f04:	0f be d2             	movsbl %dl,%edx
f0102f07:	83 ea 37             	sub    $0x37,%edx
f0102f0a:	eb cb                	jmp    f0102ed7 <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
f0102f0c:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0102f10:	74 05                	je     f0102f17 <strtol+0xd0>
		*endptr = (char *) s;
f0102f12:	8b 75 0c             	mov    0xc(%ebp),%esi
f0102f15:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f0102f17:	89 c2                	mov    %eax,%edx
f0102f19:	f7 da                	neg    %edx
f0102f1b:	85 ff                	test   %edi,%edi
f0102f1d:	0f 45 c2             	cmovne %edx,%eax
}
f0102f20:	5b                   	pop    %ebx
f0102f21:	5e                   	pop    %esi
f0102f22:	5f                   	pop    %edi
f0102f23:	5d                   	pop    %ebp
f0102f24:	c3                   	ret    
f0102f25:	66 90                	xchg   %ax,%ax
f0102f27:	66 90                	xchg   %ax,%ax
f0102f29:	66 90                	xchg   %ax,%ax
f0102f2b:	66 90                	xchg   %ax,%ax
f0102f2d:	66 90                	xchg   %ax,%ax
f0102f2f:	90                   	nop

f0102f30 <__udivdi3>:
f0102f30:	55                   	push   %ebp
f0102f31:	57                   	push   %edi
f0102f32:	56                   	push   %esi
f0102f33:	53                   	push   %ebx
f0102f34:	83 ec 1c             	sub    $0x1c,%esp
f0102f37:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f0102f3b:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f0102f3f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0102f43:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f0102f47:	85 d2                	test   %edx,%edx
f0102f49:	75 35                	jne    f0102f80 <__udivdi3+0x50>
f0102f4b:	39 f3                	cmp    %esi,%ebx
f0102f4d:	0f 87 bd 00 00 00    	ja     f0103010 <__udivdi3+0xe0>
f0102f53:	85 db                	test   %ebx,%ebx
f0102f55:	89 d9                	mov    %ebx,%ecx
f0102f57:	75 0b                	jne    f0102f64 <__udivdi3+0x34>
f0102f59:	b8 01 00 00 00       	mov    $0x1,%eax
f0102f5e:	31 d2                	xor    %edx,%edx
f0102f60:	f7 f3                	div    %ebx
f0102f62:	89 c1                	mov    %eax,%ecx
f0102f64:	31 d2                	xor    %edx,%edx
f0102f66:	89 f0                	mov    %esi,%eax
f0102f68:	f7 f1                	div    %ecx
f0102f6a:	89 c6                	mov    %eax,%esi
f0102f6c:	89 e8                	mov    %ebp,%eax
f0102f6e:	89 f7                	mov    %esi,%edi
f0102f70:	f7 f1                	div    %ecx
f0102f72:	89 fa                	mov    %edi,%edx
f0102f74:	83 c4 1c             	add    $0x1c,%esp
f0102f77:	5b                   	pop    %ebx
f0102f78:	5e                   	pop    %esi
f0102f79:	5f                   	pop    %edi
f0102f7a:	5d                   	pop    %ebp
f0102f7b:	c3                   	ret    
f0102f7c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0102f80:	39 f2                	cmp    %esi,%edx
f0102f82:	77 7c                	ja     f0103000 <__udivdi3+0xd0>
f0102f84:	0f bd fa             	bsr    %edx,%edi
f0102f87:	83 f7 1f             	xor    $0x1f,%edi
f0102f8a:	0f 84 98 00 00 00    	je     f0103028 <__udivdi3+0xf8>
f0102f90:	89 f9                	mov    %edi,%ecx
f0102f92:	b8 20 00 00 00       	mov    $0x20,%eax
f0102f97:	29 f8                	sub    %edi,%eax
f0102f99:	d3 e2                	shl    %cl,%edx
f0102f9b:	89 54 24 08          	mov    %edx,0x8(%esp)
f0102f9f:	89 c1                	mov    %eax,%ecx
f0102fa1:	89 da                	mov    %ebx,%edx
f0102fa3:	d3 ea                	shr    %cl,%edx
f0102fa5:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0102fa9:	09 d1                	or     %edx,%ecx
f0102fab:	89 f2                	mov    %esi,%edx
f0102fad:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0102fb1:	89 f9                	mov    %edi,%ecx
f0102fb3:	d3 e3                	shl    %cl,%ebx
f0102fb5:	89 c1                	mov    %eax,%ecx
f0102fb7:	d3 ea                	shr    %cl,%edx
f0102fb9:	89 f9                	mov    %edi,%ecx
f0102fbb:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0102fbf:	d3 e6                	shl    %cl,%esi
f0102fc1:	89 eb                	mov    %ebp,%ebx
f0102fc3:	89 c1                	mov    %eax,%ecx
f0102fc5:	d3 eb                	shr    %cl,%ebx
f0102fc7:	09 de                	or     %ebx,%esi
f0102fc9:	89 f0                	mov    %esi,%eax
f0102fcb:	f7 74 24 08          	divl   0x8(%esp)
f0102fcf:	89 d6                	mov    %edx,%esi
f0102fd1:	89 c3                	mov    %eax,%ebx
f0102fd3:	f7 64 24 0c          	mull   0xc(%esp)
f0102fd7:	39 d6                	cmp    %edx,%esi
f0102fd9:	72 0c                	jb     f0102fe7 <__udivdi3+0xb7>
f0102fdb:	89 f9                	mov    %edi,%ecx
f0102fdd:	d3 e5                	shl    %cl,%ebp
f0102fdf:	39 c5                	cmp    %eax,%ebp
f0102fe1:	73 5d                	jae    f0103040 <__udivdi3+0x110>
f0102fe3:	39 d6                	cmp    %edx,%esi
f0102fe5:	75 59                	jne    f0103040 <__udivdi3+0x110>
f0102fe7:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0102fea:	31 ff                	xor    %edi,%edi
f0102fec:	89 fa                	mov    %edi,%edx
f0102fee:	83 c4 1c             	add    $0x1c,%esp
f0102ff1:	5b                   	pop    %ebx
f0102ff2:	5e                   	pop    %esi
f0102ff3:	5f                   	pop    %edi
f0102ff4:	5d                   	pop    %ebp
f0102ff5:	c3                   	ret    
f0102ff6:	8d 76 00             	lea    0x0(%esi),%esi
f0102ff9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0103000:	31 ff                	xor    %edi,%edi
f0103002:	31 c0                	xor    %eax,%eax
f0103004:	89 fa                	mov    %edi,%edx
f0103006:	83 c4 1c             	add    $0x1c,%esp
f0103009:	5b                   	pop    %ebx
f010300a:	5e                   	pop    %esi
f010300b:	5f                   	pop    %edi
f010300c:	5d                   	pop    %ebp
f010300d:	c3                   	ret    
f010300e:	66 90                	xchg   %ax,%ax
f0103010:	31 ff                	xor    %edi,%edi
f0103012:	89 e8                	mov    %ebp,%eax
f0103014:	89 f2                	mov    %esi,%edx
f0103016:	f7 f3                	div    %ebx
f0103018:	89 fa                	mov    %edi,%edx
f010301a:	83 c4 1c             	add    $0x1c,%esp
f010301d:	5b                   	pop    %ebx
f010301e:	5e                   	pop    %esi
f010301f:	5f                   	pop    %edi
f0103020:	5d                   	pop    %ebp
f0103021:	c3                   	ret    
f0103022:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103028:	39 f2                	cmp    %esi,%edx
f010302a:	72 06                	jb     f0103032 <__udivdi3+0x102>
f010302c:	31 c0                	xor    %eax,%eax
f010302e:	39 eb                	cmp    %ebp,%ebx
f0103030:	77 d2                	ja     f0103004 <__udivdi3+0xd4>
f0103032:	b8 01 00 00 00       	mov    $0x1,%eax
f0103037:	eb cb                	jmp    f0103004 <__udivdi3+0xd4>
f0103039:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103040:	89 d8                	mov    %ebx,%eax
f0103042:	31 ff                	xor    %edi,%edi
f0103044:	eb be                	jmp    f0103004 <__udivdi3+0xd4>
f0103046:	66 90                	xchg   %ax,%ax
f0103048:	66 90                	xchg   %ax,%ax
f010304a:	66 90                	xchg   %ax,%ax
f010304c:	66 90                	xchg   %ax,%ax
f010304e:	66 90                	xchg   %ax,%ax

f0103050 <__umoddi3>:
f0103050:	55                   	push   %ebp
f0103051:	57                   	push   %edi
f0103052:	56                   	push   %esi
f0103053:	53                   	push   %ebx
f0103054:	83 ec 1c             	sub    $0x1c,%esp
f0103057:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
f010305b:	8b 74 24 30          	mov    0x30(%esp),%esi
f010305f:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0103063:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103067:	85 ed                	test   %ebp,%ebp
f0103069:	89 f0                	mov    %esi,%eax
f010306b:	89 da                	mov    %ebx,%edx
f010306d:	75 19                	jne    f0103088 <__umoddi3+0x38>
f010306f:	39 df                	cmp    %ebx,%edi
f0103071:	0f 86 b1 00 00 00    	jbe    f0103128 <__umoddi3+0xd8>
f0103077:	f7 f7                	div    %edi
f0103079:	89 d0                	mov    %edx,%eax
f010307b:	31 d2                	xor    %edx,%edx
f010307d:	83 c4 1c             	add    $0x1c,%esp
f0103080:	5b                   	pop    %ebx
f0103081:	5e                   	pop    %esi
f0103082:	5f                   	pop    %edi
f0103083:	5d                   	pop    %ebp
f0103084:	c3                   	ret    
f0103085:	8d 76 00             	lea    0x0(%esi),%esi
f0103088:	39 dd                	cmp    %ebx,%ebp
f010308a:	77 f1                	ja     f010307d <__umoddi3+0x2d>
f010308c:	0f bd cd             	bsr    %ebp,%ecx
f010308f:	83 f1 1f             	xor    $0x1f,%ecx
f0103092:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0103096:	0f 84 b4 00 00 00    	je     f0103150 <__umoddi3+0x100>
f010309c:	b8 20 00 00 00       	mov    $0x20,%eax
f01030a1:	89 c2                	mov    %eax,%edx
f01030a3:	8b 44 24 04          	mov    0x4(%esp),%eax
f01030a7:	29 c2                	sub    %eax,%edx
f01030a9:	89 c1                	mov    %eax,%ecx
f01030ab:	89 f8                	mov    %edi,%eax
f01030ad:	d3 e5                	shl    %cl,%ebp
f01030af:	89 d1                	mov    %edx,%ecx
f01030b1:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01030b5:	d3 e8                	shr    %cl,%eax
f01030b7:	09 c5                	or     %eax,%ebp
f01030b9:	8b 44 24 04          	mov    0x4(%esp),%eax
f01030bd:	89 c1                	mov    %eax,%ecx
f01030bf:	d3 e7                	shl    %cl,%edi
f01030c1:	89 d1                	mov    %edx,%ecx
f01030c3:	89 7c 24 08          	mov    %edi,0x8(%esp)
f01030c7:	89 df                	mov    %ebx,%edi
f01030c9:	d3 ef                	shr    %cl,%edi
f01030cb:	89 c1                	mov    %eax,%ecx
f01030cd:	89 f0                	mov    %esi,%eax
f01030cf:	d3 e3                	shl    %cl,%ebx
f01030d1:	89 d1                	mov    %edx,%ecx
f01030d3:	89 fa                	mov    %edi,%edx
f01030d5:	d3 e8                	shr    %cl,%eax
f01030d7:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01030dc:	09 d8                	or     %ebx,%eax
f01030de:	f7 f5                	div    %ebp
f01030e0:	d3 e6                	shl    %cl,%esi
f01030e2:	89 d1                	mov    %edx,%ecx
f01030e4:	f7 64 24 08          	mull   0x8(%esp)
f01030e8:	39 d1                	cmp    %edx,%ecx
f01030ea:	89 c3                	mov    %eax,%ebx
f01030ec:	89 d7                	mov    %edx,%edi
f01030ee:	72 06                	jb     f01030f6 <__umoddi3+0xa6>
f01030f0:	75 0e                	jne    f0103100 <__umoddi3+0xb0>
f01030f2:	39 c6                	cmp    %eax,%esi
f01030f4:	73 0a                	jae    f0103100 <__umoddi3+0xb0>
f01030f6:	2b 44 24 08          	sub    0x8(%esp),%eax
f01030fa:	19 ea                	sbb    %ebp,%edx
f01030fc:	89 d7                	mov    %edx,%edi
f01030fe:	89 c3                	mov    %eax,%ebx
f0103100:	89 ca                	mov    %ecx,%edx
f0103102:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f0103107:	29 de                	sub    %ebx,%esi
f0103109:	19 fa                	sbb    %edi,%edx
f010310b:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f010310f:	89 d0                	mov    %edx,%eax
f0103111:	d3 e0                	shl    %cl,%eax
f0103113:	89 d9                	mov    %ebx,%ecx
f0103115:	d3 ee                	shr    %cl,%esi
f0103117:	d3 ea                	shr    %cl,%edx
f0103119:	09 f0                	or     %esi,%eax
f010311b:	83 c4 1c             	add    $0x1c,%esp
f010311e:	5b                   	pop    %ebx
f010311f:	5e                   	pop    %esi
f0103120:	5f                   	pop    %edi
f0103121:	5d                   	pop    %ebp
f0103122:	c3                   	ret    
f0103123:	90                   	nop
f0103124:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103128:	85 ff                	test   %edi,%edi
f010312a:	89 f9                	mov    %edi,%ecx
f010312c:	75 0b                	jne    f0103139 <__umoddi3+0xe9>
f010312e:	b8 01 00 00 00       	mov    $0x1,%eax
f0103133:	31 d2                	xor    %edx,%edx
f0103135:	f7 f7                	div    %edi
f0103137:	89 c1                	mov    %eax,%ecx
f0103139:	89 d8                	mov    %ebx,%eax
f010313b:	31 d2                	xor    %edx,%edx
f010313d:	f7 f1                	div    %ecx
f010313f:	89 f0                	mov    %esi,%eax
f0103141:	f7 f1                	div    %ecx
f0103143:	e9 31 ff ff ff       	jmp    f0103079 <__umoddi3+0x29>
f0103148:	90                   	nop
f0103149:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103150:	39 dd                	cmp    %ebx,%ebp
f0103152:	72 08                	jb     f010315c <__umoddi3+0x10c>
f0103154:	39 f7                	cmp    %esi,%edi
f0103156:	0f 87 21 ff ff ff    	ja     f010307d <__umoddi3+0x2d>
f010315c:	89 da                	mov    %ebx,%edx
f010315e:	89 f0                	mov    %esi,%eax
f0103160:	29 f8                	sub    %edi,%eax
f0103162:	19 ea                	sbb    %ebp,%edx
f0103164:	e9 14 ff ff ff       	jmp    f010307d <__umoddi3+0x2d>
