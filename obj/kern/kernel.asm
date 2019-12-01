
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
f0100015:	b8 00 c0 11 00       	mov    $0x11c000,%eax
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
f010002f:	bc 00 c0 11 f0       	mov    $0xf011c000,%esp

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
f0100042:	b8 b0 8c 16 f0       	mov    $0xf0168cb0,%eax
f0100047:	2d 48 5f 12 f0       	sub    $0xf0125f48,%eax
f010004c:	50                   	push   %eax
f010004d:	6a 00                	push   $0x0
f010004f:	68 48 5f 12 f0       	push   $0xf0125f48
f0100054:	e8 ec 41 00 00       	call   f0104245 <memset>

	cons_init();
f0100059:	e8 b2 05 00 00       	call   f0100610 <cons_init>

	cprintf("Hello, world.\n");
f010005e:	c7 04 24 a0 46 10 f0 	movl   $0xf01046a0,(%esp)
f0100065:	e8 18 07 00 00       	call   f0100782 <cprintf>
	boot_alloc_init();
f010006a:	e8 ae 21 00 00       	call   f010221d <boot_alloc_init>
	vm_init();
f010006f:	e8 c7 17 00 00       	call   f010183b <vm_init>
	seg_init();
f0100074:	e8 8d 13 00 00       	call   f0101406 <seg_init>
	trap_init();
f0100079:	e8 18 07 00 00       	call   f0100796 <trap_init>
	proc_init();
f010007e:	e8 a5 2d 00 00       	call   f0102e28 <proc_init>
	mp_init();
f0100083:	e8 8f 24 00 00       	call   f0102517 <mp_init>
	lapic_init();
f0100088:	e8 51 27 00 00       	call   f01027de <lapic_init>
	pic_init();
f010008d:	e8 c6 2a 00 00       	call   f0102b58 <pic_init>
	void *code;
	struct CpuInfo *c;

	// Write entry code to unused memory at MPENTRY_PADDR
	code = P2V(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);
f0100092:	83 c4 0c             	add    $0xc,%esp
f0100095:	b8 ba 24 10 f0       	mov    $0xf01024ba,%eax
f010009a:	2d 40 24 10 f0       	sub    $0xf0102440,%eax
f010009f:	50                   	push   %eax
f01000a0:	68 40 24 10 f0       	push   $0xf0102440
f01000a5:	68 00 70 00 f0       	push   $0xf0007000
f01000aa:	e8 e3 41 00 00       	call   f0104292 <memmove>
f01000af:	83 c4 10             	add    $0x10,%esp

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f01000b2:	bb 20 70 12 f0       	mov    $0xf0127020,%ebx
f01000b7:	eb 06                	jmp    f01000bf <i386_init+0x84>
f01000b9:	81 c3 b8 00 00 00    	add    $0xb8,%ebx
f01000bf:	69 05 e4 75 12 f0 b8 	imul   $0xb8,0xf01275e4,%eax
f01000c6:	00 00 00 
f01000c9:	05 20 70 12 f0       	add    $0xf0127020,%eax
f01000ce:	39 c3                	cmp    %eax,%ebx
f01000d0:	73 4f                	jae    f0100121 <i386_init+0xe6>
		if (c == cpus + cpunum())  // We've started already.
f01000d2:	e8 ed 26 00 00       	call   f01027c4 <cpunum>
f01000d7:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f01000dd:	05 20 70 12 f0       	add    $0xf0127020,%eax
f01000e2:	39 c3                	cmp    %eax,%ebx
f01000e4:	74 d3                	je     f01000b9 <i386_init+0x7e>
			continue;

		// Tell mpentry.S what stack to use 
		mpentry_kstack = percpu_kstacks[c - cpus] + KSTKSIZE;
f01000e6:	89 d8                	mov    %ebx,%eax
f01000e8:	2d 20 70 12 f0       	sub    $0xf0127020,%eax
f01000ed:	c1 f8 03             	sar    $0x3,%eax
f01000f0:	69 c0 a7 37 bd e9    	imul   $0xe9bd37a7,%eax,%eax
f01000f6:	c1 e0 0f             	shl    $0xf,%eax
f01000f9:	05 00 00 13 f0       	add    $0xf0130000,%eax
f01000fe:	a3 48 66 12 f0       	mov    %eax,0xf0126648
		// Start the CPU at mpentry_start
		lapic_startap(c->cpu_id, V2P(code));
f0100103:	83 ec 08             	sub    $0x8,%esp
f0100106:	68 00 70 00 00       	push   $0x7000
f010010b:	0f b6 03             	movzbl (%ebx),%eax
f010010e:	50                   	push   %eax
f010010f:	e8 0d 28 00 00       	call   f0102921 <lapic_startap>
f0100114:	83 c4 10             	add    $0x10,%esp
		// Wait for the CPU to finish some basic setup in mp_main()
		while(c->cpu_status != CPU_STARTED)
f0100117:	8b 43 04             	mov    0x4(%ebx),%eax
f010011a:	83 f8 01             	cmp    $0x1,%eax
f010011d:	75 f8                	jne    f0100117 <i386_init+0xdc>
f010011f:	eb 98                	jmp    f01000b9 <i386_init+0x7e>
	alloc_init();
f0100121:	e8 e5 22 00 00       	call   f010240b <alloc_init>
	idt_init();
f0100126:	e8 f6 06 00 00       	call   f0100821 <idt_init>
	cprintf("VM: Init success.\n");
f010012b:	83 ec 0c             	sub    $0xc,%esp
f010012e:	68 af 46 10 f0       	push   $0xf01046af
f0100133:	e8 4a 06 00 00       	call   f0100782 <cprintf>
	check_free_list();
f0100138:	e8 51 20 00 00       	call   f010218e <check_free_list>
	user_init();
f010013d:	e8 00 2d 00 00       	call   f0102e42 <user_init>
	ucode_run();
f0100142:	e8 6c 2f 00 00       	call   f01030b3 <ucode_run>
f0100147:	83 c4 10             	add    $0x10,%esp
f010014a:	eb fe                	jmp    f010014a <i386_init+0x10f>

f010014c <mp_main>:
}

// Setup code for APs
void
mp_main(void)
{
f010014c:	55                   	push   %ebp
f010014d:	89 e5                	mov    %esp,%ebp
f010014f:	83 ec 08             	sub    $0x8,%esp
	// TODO: Your code here.
	// You need to initialize something.
	kvm_switch();
f0100152:	e8 19 16 00 00       	call   f0101770 <kvm_switch>
	seg_init();
f0100157:	e8 aa 12 00 00       	call   f0101406 <seg_init>
	lapic_init();
f010015c:	e8 7d 26 00 00       	call   f01027de <lapic_init>
	cprintf("Starting CPU%d.\n", cpunum());
f0100161:	e8 5e 26 00 00       	call   f01027c4 <cpunum>
f0100166:	83 ec 08             	sub    $0x8,%esp
f0100169:	50                   	push   %eax
f010016a:	68 c2 46 10 f0       	push   $0xf01046c2
f010016f:	e8 0e 06 00 00       	call   f0100782 <cprintf>
	idt_init();
f0100174:	e8 a8 06 00 00       	call   f0100821 <idt_init>
	xchg(&thiscpu->cpu_status, CPU_STARTED); // tell boot_aps() we're up
f0100179:	e8 46 26 00 00       	call   f01027c4 <cpunum>
f010017e:	69 d0 b8 00 00 00    	imul   $0xb8,%eax,%edx
f0100184:	83 c2 04             	add    $0x4,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f0100187:	b8 01 00 00 00       	mov    $0x1,%eax
f010018c:	f0 87 82 20 70 12 f0 	lock xchg %eax,-0xfed8fe0(%edx)
f0100193:	83 c4 10             	add    $0x10,%esp
f0100196:	eb fe                	jmp    f0100196 <mp_main+0x4a>

f0100198 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100198:	55                   	push   %ebp
f0100199:	89 e5                	mov    %esp,%ebp
f010019b:	56                   	push   %esi
f010019c:	53                   	push   %ebx
f010019d:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01001a0:	83 3d 44 66 12 f0 00 	cmpl   $0x0,0xf0126644
f01001a7:	74 02                	je     f01001ab <_panic+0x13>
f01001a9:	eb fe                	jmp    f01001a9 <_panic+0x11>
		goto dead;
	panicstr = fmt;
f01001ab:	89 35 44 66 12 f0    	mov    %esi,0xf0126644

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01001b1:	fa                   	cli    
f01001b2:	fc                   	cld    

	va_start(ap, fmt);
f01001b3:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01001b6:	83 ec 04             	sub    $0x4,%esp
f01001b9:	ff 75 0c             	pushl  0xc(%ebp)
f01001bc:	ff 75 08             	pushl  0x8(%ebp)
f01001bf:	68 d3 46 10 f0       	push   $0xf01046d3
f01001c4:	e8 b9 05 00 00       	call   f0100782 <cprintf>
	vcprintf(fmt, ap);
f01001c9:	83 c4 08             	add    $0x8,%esp
f01001cc:	53                   	push   %ebx
f01001cd:	56                   	push   %esi
f01001ce:	e8 89 05 00 00       	call   f010075c <vcprintf>
	cprintf("\n");
f01001d3:	c7 04 24 0f 47 10 f0 	movl   $0xf010470f,(%esp)
f01001da:	e8 a3 05 00 00       	call   f0100782 <cprintf>
f01001df:	83 c4 10             	add    $0x10,%esp
f01001e2:	eb c5                	jmp    f01001a9 <_panic+0x11>

f01001e4 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01001e4:	55                   	push   %ebp
f01001e5:	89 e5                	mov    %esp,%ebp
f01001e7:	53                   	push   %ebx
f01001e8:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01001eb:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01001ee:	ff 75 0c             	pushl  0xc(%ebp)
f01001f1:	ff 75 08             	pushl  0x8(%ebp)
f01001f4:	68 eb 46 10 f0       	push   $0xf01046eb
f01001f9:	e8 84 05 00 00       	call   f0100782 <cprintf>
	vcprintf(fmt, ap);
f01001fe:	83 c4 08             	add    $0x8,%esp
f0100201:	53                   	push   %ebx
f0100202:	ff 75 10             	pushl  0x10(%ebp)
f0100205:	e8 52 05 00 00       	call   f010075c <vcprintf>
	cprintf("\n");
f010020a:	c7 04 24 0f 47 10 f0 	movl   $0xf010470f,(%esp)
f0100211:	e8 6c 05 00 00       	call   f0100782 <cprintf>
	va_end(ap);
}
f0100216:	83 c4 10             	add    $0x10,%esp
f0100219:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010021c:	c9                   	leave  
f010021d:	c3                   	ret    

f010021e <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010021e:	55                   	push   %ebp
f010021f:	89 e5                	mov    %esp,%ebp
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100221:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100226:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100227:	a8 01                	test   $0x1,%al
f0100229:	74 0b                	je     f0100236 <serial_proc_data+0x18>
f010022b:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100230:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100231:	0f b6 c0             	movzbl %al,%eax
}
f0100234:	5d                   	pop    %ebp
f0100235:	c3                   	ret    
		return -1;
f0100236:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010023b:	eb f7                	jmp    f0100234 <serial_proc_data+0x16>

f010023d <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010023d:	55                   	push   %ebp
f010023e:	89 e5                	mov    %esp,%ebp
f0100240:	53                   	push   %ebx
f0100241:	83 ec 04             	sub    $0x4,%esp
f0100244:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100246:	ff d3                	call   *%ebx
f0100248:	83 f8 ff             	cmp    $0xffffffff,%eax
f010024b:	74 2d                	je     f010027a <cons_intr+0x3d>
		if (c == 0)
f010024d:	85 c0                	test   %eax,%eax
f010024f:	74 f5                	je     f0100246 <cons_intr+0x9>
			continue;
		cons.buf[cons.wpos++] = c;
f0100251:	8b 0d 24 62 12 f0    	mov    0xf0126224,%ecx
f0100257:	8d 51 01             	lea    0x1(%ecx),%edx
f010025a:	89 15 24 62 12 f0    	mov    %edx,0xf0126224
f0100260:	88 81 20 60 12 f0    	mov    %al,-0xfed9fe0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f0100266:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010026c:	75 d8                	jne    f0100246 <cons_intr+0x9>
			cons.wpos = 0;
f010026e:	c7 05 24 62 12 f0 00 	movl   $0x0,0xf0126224
f0100275:	00 00 00 
f0100278:	eb cc                	jmp    f0100246 <cons_intr+0x9>
	}
}
f010027a:	83 c4 04             	add    $0x4,%esp
f010027d:	5b                   	pop    %ebx
f010027e:	5d                   	pop    %ebp
f010027f:	c3                   	ret    

f0100280 <kbd_proc_data>:
{
f0100280:	55                   	push   %ebp
f0100281:	89 e5                	mov    %esp,%ebp
f0100283:	53                   	push   %ebx
f0100284:	83 ec 04             	sub    $0x4,%esp
f0100287:	ba 64 00 00 00       	mov    $0x64,%edx
f010028c:	ec                   	in     (%dx),%al
	if ((stat & KBS_DIB) == 0)
f010028d:	a8 01                	test   $0x1,%al
f010028f:	0f 84 fa 00 00 00    	je     f010038f <kbd_proc_data+0x10f>
	if (stat & KBS_TERR)
f0100295:	a8 20                	test   $0x20,%al
f0100297:	0f 85 f9 00 00 00    	jne    f0100396 <kbd_proc_data+0x116>
f010029d:	ba 60 00 00 00       	mov    $0x60,%edx
f01002a2:	ec                   	in     (%dx),%al
f01002a3:	89 c2                	mov    %eax,%edx
	if (data == 0xE0) {
f01002a5:	3c e0                	cmp    $0xe0,%al
f01002a7:	0f 84 8e 00 00 00    	je     f010033b <kbd_proc_data+0xbb>
	} else if (data & 0x80) {
f01002ad:	84 c0                	test   %al,%al
f01002af:	0f 88 99 00 00 00    	js     f010034e <kbd_proc_data+0xce>
	} else if (shift & E0ESC) {
f01002b5:	8b 0d 00 60 12 f0    	mov    0xf0126000,%ecx
f01002bb:	f6 c1 40             	test   $0x40,%cl
f01002be:	74 0e                	je     f01002ce <kbd_proc_data+0x4e>
		data |= 0x80;
f01002c0:	83 c8 80             	or     $0xffffff80,%eax
f01002c3:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f01002c5:	83 e1 bf             	and    $0xffffffbf,%ecx
f01002c8:	89 0d 00 60 12 f0    	mov    %ecx,0xf0126000
	shift |= shiftcode[data];
f01002ce:	0f b6 d2             	movzbl %dl,%edx
f01002d1:	0f b6 82 60 48 10 f0 	movzbl -0xfefb7a0(%edx),%eax
f01002d8:	0b 05 00 60 12 f0    	or     0xf0126000,%eax
	shift ^= togglecode[data];
f01002de:	0f b6 8a 60 47 10 f0 	movzbl -0xfefb8a0(%edx),%ecx
f01002e5:	31 c8                	xor    %ecx,%eax
f01002e7:	a3 00 60 12 f0       	mov    %eax,0xf0126000
	c = charcode[shift & (CTL | SHIFT)][data];
f01002ec:	89 c1                	mov    %eax,%ecx
f01002ee:	83 e1 03             	and    $0x3,%ecx
f01002f1:	8b 0c 8d 40 47 10 f0 	mov    -0xfefb8c0(,%ecx,4),%ecx
f01002f8:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f01002fc:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f01002ff:	a8 08                	test   $0x8,%al
f0100301:	74 0d                	je     f0100310 <kbd_proc_data+0x90>
		if ('a' <= c && c <= 'z')
f0100303:	89 da                	mov    %ebx,%edx
f0100305:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100308:	83 f9 19             	cmp    $0x19,%ecx
f010030b:	77 74                	ja     f0100381 <kbd_proc_data+0x101>
			c += 'A' - 'a';
f010030d:	83 eb 20             	sub    $0x20,%ebx
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100310:	f7 d0                	not    %eax
f0100312:	a8 06                	test   $0x6,%al
f0100314:	75 31                	jne    f0100347 <kbd_proc_data+0xc7>
f0100316:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f010031c:	75 29                	jne    f0100347 <kbd_proc_data+0xc7>
		cprintf("Rebooting!\n");
f010031e:	83 ec 0c             	sub    $0xc,%esp
f0100321:	68 05 47 10 f0       	push   $0xf0104705
f0100326:	e8 57 04 00 00       	call   f0100782 <cprintf>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010032b:	b8 03 00 00 00       	mov    $0x3,%eax
f0100330:	ba 92 00 00 00       	mov    $0x92,%edx
f0100335:	ee                   	out    %al,(%dx)
f0100336:	83 c4 10             	add    $0x10,%esp
f0100339:	eb 0c                	jmp    f0100347 <kbd_proc_data+0xc7>
		shift |= E0ESC;
f010033b:	83 0d 00 60 12 f0 40 	orl    $0x40,0xf0126000
		return 0;
f0100342:	bb 00 00 00 00       	mov    $0x0,%ebx
}
f0100347:	89 d8                	mov    %ebx,%eax
f0100349:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010034c:	c9                   	leave  
f010034d:	c3                   	ret    
		data = (shift & E0ESC ? data : data & 0x7F);
f010034e:	8b 0d 00 60 12 f0    	mov    0xf0126000,%ecx
f0100354:	89 cb                	mov    %ecx,%ebx
f0100356:	83 e3 40             	and    $0x40,%ebx
f0100359:	83 e0 7f             	and    $0x7f,%eax
f010035c:	85 db                	test   %ebx,%ebx
f010035e:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100361:	0f b6 d2             	movzbl %dl,%edx
f0100364:	0f b6 82 60 48 10 f0 	movzbl -0xfefb7a0(%edx),%eax
f010036b:	83 c8 40             	or     $0x40,%eax
f010036e:	0f b6 c0             	movzbl %al,%eax
f0100371:	f7 d0                	not    %eax
f0100373:	21 c8                	and    %ecx,%eax
f0100375:	a3 00 60 12 f0       	mov    %eax,0xf0126000
		return 0;
f010037a:	bb 00 00 00 00       	mov    $0x0,%ebx
f010037f:	eb c6                	jmp    f0100347 <kbd_proc_data+0xc7>
		else if ('A' <= c && c <= 'Z')
f0100381:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f0100384:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100387:	83 fa 1a             	cmp    $0x1a,%edx
f010038a:	0f 42 d9             	cmovb  %ecx,%ebx
f010038d:	eb 81                	jmp    f0100310 <kbd_proc_data+0x90>
		return -1;
f010038f:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
f0100394:	eb b1                	jmp    f0100347 <kbd_proc_data+0xc7>
		return -1;
f0100396:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
f010039b:	eb aa                	jmp    f0100347 <kbd_proc_data+0xc7>

f010039d <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f010039d:	55                   	push   %ebp
f010039e:	89 e5                	mov    %esp,%ebp
f01003a0:	57                   	push   %edi
f01003a1:	56                   	push   %esi
f01003a2:	53                   	push   %ebx
f01003a3:	83 ec 1c             	sub    $0x1c,%esp
f01003a6:	89 c7                	mov    %eax,%edi
	for (i = 0;
f01003a8:	bb 00 00 00 00       	mov    $0x0,%ebx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003ad:	be fd 03 00 00       	mov    $0x3fd,%esi
f01003b2:	b9 84 00 00 00       	mov    $0x84,%ecx
f01003b7:	eb 09                	jmp    f01003c2 <cons_putc+0x25>
f01003b9:	89 ca                	mov    %ecx,%edx
f01003bb:	ec                   	in     (%dx),%al
f01003bc:	ec                   	in     (%dx),%al
f01003bd:	ec                   	in     (%dx),%al
f01003be:	ec                   	in     (%dx),%al
	     i++)
f01003bf:	83 c3 01             	add    $0x1,%ebx
f01003c2:	89 f2                	mov    %esi,%edx
f01003c4:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01003c5:	a8 20                	test   $0x20,%al
f01003c7:	75 08                	jne    f01003d1 <cons_putc+0x34>
f01003c9:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01003cf:	7e e8                	jle    f01003b9 <cons_putc+0x1c>
	outb(COM1 + COM_TX, c);
f01003d1:	89 f8                	mov    %edi,%eax
f01003d3:	88 45 e7             	mov    %al,-0x19(%ebp)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003d6:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01003db:	ee                   	out    %al,(%dx)
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01003dc:	bb 00 00 00 00       	mov    $0x0,%ebx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003e1:	be 79 03 00 00       	mov    $0x379,%esi
f01003e6:	b9 84 00 00 00       	mov    $0x84,%ecx
f01003eb:	eb 09                	jmp    f01003f6 <cons_putc+0x59>
f01003ed:	89 ca                	mov    %ecx,%edx
f01003ef:	ec                   	in     (%dx),%al
f01003f0:	ec                   	in     (%dx),%al
f01003f1:	ec                   	in     (%dx),%al
f01003f2:	ec                   	in     (%dx),%al
f01003f3:	83 c3 01             	add    $0x1,%ebx
f01003f6:	89 f2                	mov    %esi,%edx
f01003f8:	ec                   	in     (%dx),%al
f01003f9:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01003ff:	7f 04                	jg     f0100405 <cons_putc+0x68>
f0100401:	84 c0                	test   %al,%al
f0100403:	79 e8                	jns    f01003ed <cons_putc+0x50>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100405:	ba 78 03 00 00       	mov    $0x378,%edx
f010040a:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f010040e:	ee                   	out    %al,(%dx)
f010040f:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100414:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100419:	ee                   	out    %al,(%dx)
f010041a:	b8 08 00 00 00       	mov    $0x8,%eax
f010041f:	ee                   	out    %al,(%dx)
	if (!(c & ~0xFF))
f0100420:	89 fa                	mov    %edi,%edx
f0100422:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100428:	89 f8                	mov    %edi,%eax
f010042a:	80 cc 07             	or     $0x7,%ah
f010042d:	85 d2                	test   %edx,%edx
f010042f:	0f 44 f8             	cmove  %eax,%edi
	switch (c & 0xff) {
f0100432:	89 f8                	mov    %edi,%eax
f0100434:	0f b6 c0             	movzbl %al,%eax
f0100437:	83 f8 09             	cmp    $0x9,%eax
f010043a:	0f 84 b6 00 00 00    	je     f01004f6 <cons_putc+0x159>
f0100440:	83 f8 09             	cmp    $0x9,%eax
f0100443:	7e 73                	jle    f01004b8 <cons_putc+0x11b>
f0100445:	83 f8 0a             	cmp    $0xa,%eax
f0100448:	0f 84 9b 00 00 00    	je     f01004e9 <cons_putc+0x14c>
f010044e:	83 f8 0d             	cmp    $0xd,%eax
f0100451:	0f 85 d6 00 00 00    	jne    f010052d <cons_putc+0x190>
		crt_pos -= (crt_pos % CRT_COLS);
f0100457:	0f b7 05 28 62 12 f0 	movzwl 0xf0126228,%eax
f010045e:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100464:	c1 e8 16             	shr    $0x16,%eax
f0100467:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010046a:	c1 e0 04             	shl    $0x4,%eax
f010046d:	66 a3 28 62 12 f0    	mov    %ax,0xf0126228
	if (crt_pos >= CRT_SIZE) {
f0100473:	66 81 3d 28 62 12 f0 	cmpw   $0x7cf,0xf0126228
f010047a:	cf 07 
f010047c:	0f 87 ce 00 00 00    	ja     f0100550 <cons_putc+0x1b3>
	outb(addr_6845, 14);
f0100482:	8b 0d 30 62 12 f0    	mov    0xf0126230,%ecx
f0100488:	b8 0e 00 00 00       	mov    $0xe,%eax
f010048d:	89 ca                	mov    %ecx,%edx
f010048f:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100490:	0f b7 1d 28 62 12 f0 	movzwl 0xf0126228,%ebx
f0100497:	8d 71 01             	lea    0x1(%ecx),%esi
f010049a:	89 d8                	mov    %ebx,%eax
f010049c:	66 c1 e8 08          	shr    $0x8,%ax
f01004a0:	89 f2                	mov    %esi,%edx
f01004a2:	ee                   	out    %al,(%dx)
f01004a3:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004a8:	89 ca                	mov    %ecx,%edx
f01004aa:	ee                   	out    %al,(%dx)
f01004ab:	89 d8                	mov    %ebx,%eax
f01004ad:	89 f2                	mov    %esi,%edx
f01004af:	ee                   	out    %al,(%dx)
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004b0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01004b3:	5b                   	pop    %ebx
f01004b4:	5e                   	pop    %esi
f01004b5:	5f                   	pop    %edi
f01004b6:	5d                   	pop    %ebp
f01004b7:	c3                   	ret    
	switch (c & 0xff) {
f01004b8:	83 f8 08             	cmp    $0x8,%eax
f01004bb:	75 70                	jne    f010052d <cons_putc+0x190>
		if (crt_pos > 0) {
f01004bd:	0f b7 05 28 62 12 f0 	movzwl 0xf0126228,%eax
f01004c4:	66 85 c0             	test   %ax,%ax
f01004c7:	74 b9                	je     f0100482 <cons_putc+0xe5>
			crt_pos--;
f01004c9:	83 e8 01             	sub    $0x1,%eax
f01004cc:	66 a3 28 62 12 f0    	mov    %ax,0xf0126228
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01004d2:	0f b7 c0             	movzwl %ax,%eax
f01004d5:	66 81 e7 00 ff       	and    $0xff00,%di
f01004da:	83 cf 20             	or     $0x20,%edi
f01004dd:	8b 15 2c 62 12 f0    	mov    0xf012622c,%edx
f01004e3:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01004e7:	eb 8a                	jmp    f0100473 <cons_putc+0xd6>
		crt_pos += CRT_COLS;
f01004e9:	66 83 05 28 62 12 f0 	addw   $0x50,0xf0126228
f01004f0:	50 
f01004f1:	e9 61 ff ff ff       	jmp    f0100457 <cons_putc+0xba>
		cons_putc(' ');
f01004f6:	b8 20 00 00 00       	mov    $0x20,%eax
f01004fb:	e8 9d fe ff ff       	call   f010039d <cons_putc>
		cons_putc(' ');
f0100500:	b8 20 00 00 00       	mov    $0x20,%eax
f0100505:	e8 93 fe ff ff       	call   f010039d <cons_putc>
		cons_putc(' ');
f010050a:	b8 20 00 00 00       	mov    $0x20,%eax
f010050f:	e8 89 fe ff ff       	call   f010039d <cons_putc>
		cons_putc(' ');
f0100514:	b8 20 00 00 00       	mov    $0x20,%eax
f0100519:	e8 7f fe ff ff       	call   f010039d <cons_putc>
		cons_putc(' ');
f010051e:	b8 20 00 00 00       	mov    $0x20,%eax
f0100523:	e8 75 fe ff ff       	call   f010039d <cons_putc>
f0100528:	e9 46 ff ff ff       	jmp    f0100473 <cons_putc+0xd6>
		crt_buf[crt_pos++] = c;		/* write the character */
f010052d:	0f b7 05 28 62 12 f0 	movzwl 0xf0126228,%eax
f0100534:	8d 50 01             	lea    0x1(%eax),%edx
f0100537:	66 89 15 28 62 12 f0 	mov    %dx,0xf0126228
f010053e:	0f b7 c0             	movzwl %ax,%eax
f0100541:	8b 15 2c 62 12 f0    	mov    0xf012622c,%edx
f0100547:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f010054b:	e9 23 ff ff ff       	jmp    f0100473 <cons_putc+0xd6>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100550:	a1 2c 62 12 f0       	mov    0xf012622c,%eax
f0100555:	83 ec 04             	sub    $0x4,%esp
f0100558:	68 00 0f 00 00       	push   $0xf00
f010055d:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100563:	52                   	push   %edx
f0100564:	50                   	push   %eax
f0100565:	e8 28 3d 00 00       	call   f0104292 <memmove>
			crt_buf[i] = 0x0700 | ' ';
f010056a:	8b 15 2c 62 12 f0    	mov    0xf012622c,%edx
f0100570:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100576:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f010057c:	83 c4 10             	add    $0x10,%esp
f010057f:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100584:	83 c0 02             	add    $0x2,%eax
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100587:	39 d0                	cmp    %edx,%eax
f0100589:	75 f4                	jne    f010057f <cons_putc+0x1e2>
		crt_pos -= CRT_COLS;
f010058b:	66 83 2d 28 62 12 f0 	subw   $0x50,0xf0126228
f0100592:	50 
f0100593:	e9 ea fe ff ff       	jmp    f0100482 <cons_putc+0xe5>

f0100598 <serial_intr>:
	if (serial_exists)
f0100598:	80 3d 34 62 12 f0 00 	cmpb   $0x0,0xf0126234
f010059f:	75 02                	jne    f01005a3 <serial_intr+0xb>
f01005a1:	f3 c3                	repz ret 
{
f01005a3:	55                   	push   %ebp
f01005a4:	89 e5                	mov    %esp,%ebp
f01005a6:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f01005a9:	b8 1e 02 10 f0       	mov    $0xf010021e,%eax
f01005ae:	e8 8a fc ff ff       	call   f010023d <cons_intr>
}
f01005b3:	c9                   	leave  
f01005b4:	c3                   	ret    

f01005b5 <kbd_intr>:
{
f01005b5:	55                   	push   %ebp
f01005b6:	89 e5                	mov    %esp,%ebp
f01005b8:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01005bb:	b8 80 02 10 f0       	mov    $0xf0100280,%eax
f01005c0:	e8 78 fc ff ff       	call   f010023d <cons_intr>
}
f01005c5:	c9                   	leave  
f01005c6:	c3                   	ret    

f01005c7 <cons_getc>:
{
f01005c7:	55                   	push   %ebp
f01005c8:	89 e5                	mov    %esp,%ebp
f01005ca:	83 ec 08             	sub    $0x8,%esp
	serial_intr();
f01005cd:	e8 c6 ff ff ff       	call   f0100598 <serial_intr>
	kbd_intr();
f01005d2:	e8 de ff ff ff       	call   f01005b5 <kbd_intr>
	if (cons.rpos != cons.wpos) {
f01005d7:	8b 15 20 62 12 f0    	mov    0xf0126220,%edx
	return 0;
f01005dd:	b8 00 00 00 00       	mov    $0x0,%eax
	if (cons.rpos != cons.wpos) {
f01005e2:	3b 15 24 62 12 f0    	cmp    0xf0126224,%edx
f01005e8:	74 18                	je     f0100602 <cons_getc+0x3b>
		c = cons.buf[cons.rpos++];
f01005ea:	8d 4a 01             	lea    0x1(%edx),%ecx
f01005ed:	89 0d 20 62 12 f0    	mov    %ecx,0xf0126220
f01005f3:	0f b6 82 20 60 12 f0 	movzbl -0xfed9fe0(%edx),%eax
		if (cons.rpos == CONSBUFSIZE)
f01005fa:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f0100600:	74 02                	je     f0100604 <cons_getc+0x3d>
}
f0100602:	c9                   	leave  
f0100603:	c3                   	ret    
			cons.rpos = 0;
f0100604:	c7 05 20 62 12 f0 00 	movl   $0x0,0xf0126220
f010060b:	00 00 00 
f010060e:	eb f2                	jmp    f0100602 <cons_getc+0x3b>

f0100610 <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f0100610:	55                   	push   %ebp
f0100611:	89 e5                	mov    %esp,%ebp
f0100613:	57                   	push   %edi
f0100614:	56                   	push   %esi
f0100615:	53                   	push   %ebx
f0100616:	83 ec 0c             	sub    $0xc,%esp
	was = *cp;
f0100619:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100620:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100627:	5a a5 
	if (*cp != 0xA55A) {
f0100629:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100630:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100634:	0f 84 b7 00 00 00    	je     f01006f1 <cons_init+0xe1>
		addr_6845 = MONO_BASE;
f010063a:	c7 05 30 62 12 f0 b4 	movl   $0x3b4,0xf0126230
f0100641:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100644:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
	outb(addr_6845, 14);
f0100649:	8b 3d 30 62 12 f0    	mov    0xf0126230,%edi
f010064f:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100654:	89 fa                	mov    %edi,%edx
f0100656:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100657:	8d 4f 01             	lea    0x1(%edi),%ecx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010065a:	89 ca                	mov    %ecx,%edx
f010065c:	ec                   	in     (%dx),%al
f010065d:	0f b6 c0             	movzbl %al,%eax
f0100660:	c1 e0 08             	shl    $0x8,%eax
f0100663:	89 c3                	mov    %eax,%ebx
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100665:	b8 0f 00 00 00       	mov    $0xf,%eax
f010066a:	89 fa                	mov    %edi,%edx
f010066c:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010066d:	89 ca                	mov    %ecx,%edx
f010066f:	ec                   	in     (%dx),%al
	crt_buf = (uint16_t*) cp;
f0100670:	89 35 2c 62 12 f0    	mov    %esi,0xf012622c
	pos |= inb(addr_6845 + 1);
f0100676:	0f b6 c0             	movzbl %al,%eax
f0100679:	09 d8                	or     %ebx,%eax
	crt_pos = pos;
f010067b:	66 a3 28 62 12 f0    	mov    %ax,0xf0126228
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100681:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100686:	b9 fa 03 00 00       	mov    $0x3fa,%ecx
f010068b:	89 d8                	mov    %ebx,%eax
f010068d:	89 ca                	mov    %ecx,%edx
f010068f:	ee                   	out    %al,(%dx)
f0100690:	bf fb 03 00 00       	mov    $0x3fb,%edi
f0100695:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f010069a:	89 fa                	mov    %edi,%edx
f010069c:	ee                   	out    %al,(%dx)
f010069d:	b8 0c 00 00 00       	mov    $0xc,%eax
f01006a2:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01006a7:	ee                   	out    %al,(%dx)
f01006a8:	be f9 03 00 00       	mov    $0x3f9,%esi
f01006ad:	89 d8                	mov    %ebx,%eax
f01006af:	89 f2                	mov    %esi,%edx
f01006b1:	ee                   	out    %al,(%dx)
f01006b2:	b8 03 00 00 00       	mov    $0x3,%eax
f01006b7:	89 fa                	mov    %edi,%edx
f01006b9:	ee                   	out    %al,(%dx)
f01006ba:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01006bf:	89 d8                	mov    %ebx,%eax
f01006c1:	ee                   	out    %al,(%dx)
f01006c2:	b8 01 00 00 00       	mov    $0x1,%eax
f01006c7:	89 f2                	mov    %esi,%edx
f01006c9:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006ca:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01006cf:	ec                   	in     (%dx),%al
f01006d0:	89 c3                	mov    %eax,%ebx
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01006d2:	3c ff                	cmp    $0xff,%al
f01006d4:	0f 95 05 34 62 12 f0 	setne  0xf0126234
f01006db:	89 ca                	mov    %ecx,%edx
f01006dd:	ec                   	in     (%dx),%al
f01006de:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01006e3:	ec                   	in     (%dx),%al
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01006e4:	80 fb ff             	cmp    $0xff,%bl
f01006e7:	74 23                	je     f010070c <cons_init+0xfc>
		cprintf("Serial port does not exist!\n");
}
f01006e9:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01006ec:	5b                   	pop    %ebx
f01006ed:	5e                   	pop    %esi
f01006ee:	5f                   	pop    %edi
f01006ef:	5d                   	pop    %ebp
f01006f0:	c3                   	ret    
		*cp = was;
f01006f1:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01006f8:	c7 05 30 62 12 f0 d4 	movl   $0x3d4,0xf0126230
f01006ff:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100702:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
f0100707:	e9 3d ff ff ff       	jmp    f0100649 <cons_init+0x39>
		cprintf("Serial port does not exist!\n");
f010070c:	83 ec 0c             	sub    $0xc,%esp
f010070f:	68 11 47 10 f0       	push   $0xf0104711
f0100714:	e8 69 00 00 00       	call   f0100782 <cprintf>
f0100719:	83 c4 10             	add    $0x10,%esp
}
f010071c:	eb cb                	jmp    f01006e9 <cons_init+0xd9>

f010071e <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010071e:	55                   	push   %ebp
f010071f:	89 e5                	mov    %esp,%ebp
f0100721:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100724:	8b 45 08             	mov    0x8(%ebp),%eax
f0100727:	e8 71 fc ff ff       	call   f010039d <cons_putc>
}
f010072c:	c9                   	leave  
f010072d:	c3                   	ret    

f010072e <getchar>:

int
getchar(void)
{
f010072e:	55                   	push   %ebp
f010072f:	89 e5                	mov    %esp,%ebp
f0100731:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100734:	e8 8e fe ff ff       	call   f01005c7 <cons_getc>
f0100739:	85 c0                	test   %eax,%eax
f010073b:	74 f7                	je     f0100734 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010073d:	c9                   	leave  
f010073e:	c3                   	ret    

f010073f <iscons>:

int
iscons(int fdnum)
{
f010073f:	55                   	push   %ebp
f0100740:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100742:	b8 01 00 00 00       	mov    $0x1,%eax
f0100747:	5d                   	pop    %ebp
f0100748:	c3                   	ret    

f0100749 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100749:	55                   	push   %ebp
f010074a:	89 e5                	mov    %esp,%ebp
f010074c:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f010074f:	ff 75 08             	pushl  0x8(%ebp)
f0100752:	e8 c7 ff ff ff       	call   f010071e <cputchar>
	*cnt++;
}
f0100757:	83 c4 10             	add    $0x10,%esp
f010075a:	c9                   	leave  
f010075b:	c3                   	ret    

f010075c <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f010075c:	55                   	push   %ebp
f010075d:	89 e5                	mov    %esp,%ebp
f010075f:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0100762:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100769:	ff 75 0c             	pushl  0xc(%ebp)
f010076c:	ff 75 08             	pushl  0x8(%ebp)
f010076f:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100772:	50                   	push   %eax
f0100773:	68 49 07 10 f0       	push   $0xf0100749
f0100778:	e8 83 33 00 00       	call   f0103b00 <vprintfmt>
	return cnt;
}
f010077d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100780:	c9                   	leave  
f0100781:	c3                   	ret    

f0100782 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100782:	55                   	push   %ebp
f0100783:	89 e5                	mov    %esp,%ebp
f0100785:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100788:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f010078b:	50                   	push   %eax
f010078c:	ff 75 08             	pushl  0x8(%ebp)
f010078f:	e8 c8 ff ff ff       	call   f010075c <vcprintf>
	va_end(ap);

	return cnt;
}
f0100794:	c9                   	leave  
f0100795:	c3                   	ret    

f0100796 <trap_init>:
struct spinlock tickslock;

// Initialize the interrupt descriptor table.
void
trap_init(void)
{
f0100796:	55                   	push   %ebp
f0100797:	89 e5                	mov    %esp,%ebp
f0100799:	83 ec 08             	sub    $0x8,%esp
	//
	// Hints:
	// 1. The macro SETGATE in inc/mmu.h should help you, as well as the
	// T_* defines in inc/traps.h;
	// 2. T_SYSCALL is different from the others.
	for (int i = 0; i < 256; i++)
f010079c:	b8 00 00 00 00       	mov    $0x0,%eax
		SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
f01007a1:	8b 14 85 00 e3 11 f0 	mov    -0xfee1d00(,%eax,4),%edx
f01007a8:	66 89 14 c5 a0 66 12 	mov    %dx,-0xfed9960(,%eax,8)
f01007af:	f0 
f01007b0:	66 c7 04 c5 a2 66 12 	movw   $0x8,-0xfed995e(,%eax,8)
f01007b7:	f0 08 00 
f01007ba:	c6 04 c5 a4 66 12 f0 	movb   $0x0,-0xfed995c(,%eax,8)
f01007c1:	00 
f01007c2:	c6 04 c5 a5 66 12 f0 	movb   $0x8e,-0xfed995b(,%eax,8)
f01007c9:	8e 
f01007ca:	c1 ea 10             	shr    $0x10,%edx
f01007cd:	66 89 14 c5 a6 66 12 	mov    %dx,-0xfed995a(,%eax,8)
f01007d4:	f0 
	for (int i = 0; i < 256; i++)
f01007d5:	83 c0 01             	add    $0x1,%eax
f01007d8:	3d 00 01 00 00       	cmp    $0x100,%eax
f01007dd:	75 c2                	jne    f01007a1 <trap_init+0xb>
	SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
f01007df:	a1 00 e4 11 f0       	mov    0xf011e400,%eax
f01007e4:	66 a3 a0 68 12 f0    	mov    %ax,0xf01268a0
f01007ea:	66 c7 05 a2 68 12 f0 	movw   $0x8,0xf01268a2
f01007f1:	08 00 
f01007f3:	c6 05 a4 68 12 f0 00 	movb   $0x0,0xf01268a4
f01007fa:	c6 05 a5 68 12 f0 ef 	movb   $0xef,0xf01268a5
f0100801:	c1 e8 10             	shr    $0x10,%eax
f0100804:	66 a3 a6 68 12 f0    	mov    %ax,0xf01268a6
	__spin_initlock(&tickslock, "time");
f010080a:	83 ec 08             	sub    $0x8,%esp
f010080d:	68 60 49 10 f0       	push   $0xf0104960
f0100812:	68 60 66 12 f0       	push   $0xf0126660
f0100817:	e8 ca 21 00 00       	call   f01029e6 <__spin_initlock>
}
f010081c:	83 c4 10             	add    $0x10,%esp
f010081f:	c9                   	leave  
f0100820:	c3                   	ret    

f0100821 <idt_init>:

void
idt_init(void)
{
f0100821:	55                   	push   %ebp
f0100822:	89 e5                	mov    %esp,%ebp
f0100824:	83 ec 10             	sub    $0x10,%esp
	pd[0] = size-1;
f0100827:	66 c7 45 fa ff 07    	movw   $0x7ff,-0x6(%ebp)
	pd[1] = (unsigned)p;
f010082d:	b8 a0 66 12 f0       	mov    $0xf01266a0,%eax
f0100832:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
	pd[2] = (unsigned)p >> 16;
f0100836:	c1 e8 10             	shr    $0x10,%eax
f0100839:	66 89 45 fe          	mov    %ax,-0x2(%ebp)
	asm volatile("lidt (%0)" : : "r" (pd));
f010083d:	8d 45 fa             	lea    -0x6(%ebp),%eax
f0100840:	0f 01 18             	lidtl  (%eax)
	lidt(idt, sizeof(idt));
}
f0100843:	c9                   	leave  
f0100844:	c3                   	ret    

f0100845 <trap>:

void
trap(struct trapframe *tf)
{
f0100845:	55                   	push   %ebp
f0100846:	89 e5                	mov    %esp,%ebp
f0100848:	57                   	push   %edi
f0100849:	56                   	push   %esi
f010084a:	53                   	push   %ebx
f010084b:	83 ec 1c             	sub    $0x1c,%esp
f010084e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// You don't need to implement this function now, but you can write
	// some code for debugging.
	struct proc *p = thisproc();
f0100851:	e8 72 2a 00 00       	call   f01032c8 <thisproc>
f0100856:	89 c6                	mov    %eax,%esi
	if (tf->trapno == T_SYSCALL) {
f0100858:	8b 43 30             	mov    0x30(%ebx),%eax
f010085b:	83 f8 40             	cmp    $0x40,%eax
f010085e:	74 55                	je     f01008b5 <trap+0x70>
		p->tf = tf;
		// cprintf("in trap.\n");
		tf->eax = syscall(tf->eax, tf->edx, tf->ecx, tf->ebx, tf->edi, tf->esi);
		return;
	}
	switch (tf->trapno) {
f0100860:	83 f8 20             	cmp    $0x20,%eax
f0100863:	74 74                	je     f01008d9 <trap+0x94>
		spin_unlock(&tickslock);
		lapic_eoi();
		break;
	
	default:
		if (p == NULL || (tf->cs & 3) == 0) {
f0100865:	85 f6                	test   %esi,%esi
f0100867:	0f 84 a6 00 00 00    	je     f0100913 <trap+0xce>
f010086d:	f6 43 3c 03          	testb  $0x3,0x3c(%ebx)
f0100871:	0f 84 9c 00 00 00    	je     f0100913 <trap+0xce>
	asm volatile("movl %%cr2,%0" : "=r" (val));
f0100877:	0f 20 d7             	mov    %cr2,%edi
			cprintf("unexpected trap %d from cpu %d eip: %x (cr2=0x%x)\n",
              tf->trapno, cpunum(), tf->eip, rcr2());
      		panic("trap");
		}
		cprintf("pid %d : trap %d err %d on cpu %d "
f010087a:	8b 43 38             	mov    0x38(%ebx),%eax
f010087d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100880:	e8 3f 1f 00 00       	call   f01027c4 <cpunum>
f0100885:	83 ec 04             	sub    $0x4,%esp
f0100888:	57                   	push   %edi
f0100889:	ff 75 e4             	pushl  -0x1c(%ebp)
f010088c:	50                   	push   %eax
f010088d:	ff 73 34             	pushl  0x34(%ebx)
f0100890:	ff 73 30             	pushl  0x30(%ebx)
f0100893:	ff 76 0c             	pushl  0xc(%esi)
f0100896:	68 ac 49 10 f0       	push   $0xf01049ac
f010089b:	e8 e2 fe ff ff       	call   f0100782 <cprintf>
f01008a0:	83 c4 20             	add    $0x20,%esp
            "eip 0x%x addr 0x%x--kill proc\n",
            p->pid, tf->trapno,
            tf->err, cpunum(), tf->eip, rcr2());
		break;
	}
	if (p && p->state == RUNNING && tf->trapno == T_IRQ0 + IRQ_TIMER) {
f01008a3:	83 7e 08 04          	cmpl   $0x4,0x8(%esi)
f01008a7:	0f 84 98 00 00 00    	je     f0100945 <trap+0x100>
		if (ticks - p->begin_tick < time_slice[p->priority])
			return;
		yield();
	}
f01008ad:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008b0:	5b                   	pop    %ebx
f01008b1:	5e                   	pop    %esi
f01008b2:	5f                   	pop    %edi
f01008b3:	5d                   	pop    %ebp
f01008b4:	c3                   	ret    
		p->tf = tf;
f01008b5:	89 5e 14             	mov    %ebx,0x14(%esi)
		tf->eax = syscall(tf->eax, tf->edx, tf->ecx, tf->ebx, tf->edi, tf->esi);
f01008b8:	83 ec 08             	sub    $0x8,%esp
f01008bb:	ff 73 04             	pushl  0x4(%ebx)
f01008be:	ff 33                	pushl  (%ebx)
f01008c0:	ff 73 10             	pushl  0x10(%ebx)
f01008c3:	ff 73 18             	pushl  0x18(%ebx)
f01008c6:	ff 73 14             	pushl  0x14(%ebx)
f01008c9:	ff 73 1c             	pushl  0x1c(%ebx)
f01008cc:	e8 17 30 00 00       	call   f01038e8 <syscall>
f01008d1:	89 43 1c             	mov    %eax,0x1c(%ebx)
		return;
f01008d4:	83 c4 20             	add    $0x20,%esp
f01008d7:	eb d4                	jmp    f01008ad <trap+0x68>
		spin_lock(&tickslock);
f01008d9:	83 ec 0c             	sub    $0xc,%esp
f01008dc:	68 60 66 12 f0       	push   $0xf0126660
f01008e1:	e8 1b 21 00 00       	call   f0102a01 <spin_lock>
		ticks++;
f01008e6:	83 05 a0 6e 12 f0 01 	addl   $0x1,0xf0126ea0
		wakeup1(&ticks);
f01008ed:	c7 04 24 a0 6e 12 f0 	movl   $0xf0126ea0,(%esp)
f01008f4:	e8 2c 2a 00 00       	call   f0103325 <wakeup1>
		spin_unlock(&tickslock);
f01008f9:	c7 04 24 60 66 12 f0 	movl   $0xf0126660,(%esp)
f0100900:	e8 64 21 00 00       	call   f0102a69 <spin_unlock>
		lapic_eoi();
f0100905:	e8 f8 1f 00 00       	call   f0102902 <lapic_eoi>
	if (p && p->state == RUNNING && tf->trapno == T_IRQ0 + IRQ_TIMER) {
f010090a:	83 c4 10             	add    $0x10,%esp
f010090d:	85 f6                	test   %esi,%esi
f010090f:	74 9c                	je     f01008ad <trap+0x68>
f0100911:	eb 90                	jmp    f01008a3 <trap+0x5e>
f0100913:	0f 20 d7             	mov    %cr2,%edi
			cprintf("unexpected trap %d from cpu %d eip: %x (cr2=0x%x)\n",
f0100916:	8b 73 38             	mov    0x38(%ebx),%esi
f0100919:	e8 a6 1e 00 00       	call   f01027c4 <cpunum>
f010091e:	83 ec 0c             	sub    $0xc,%esp
f0100921:	57                   	push   %edi
f0100922:	56                   	push   %esi
f0100923:	50                   	push   %eax
f0100924:	ff 73 30             	pushl  0x30(%ebx)
f0100927:	68 78 49 10 f0       	push   $0xf0104978
f010092c:	e8 51 fe ff ff       	call   f0100782 <cprintf>
      		panic("trap");
f0100931:	83 c4 1c             	add    $0x1c,%esp
f0100934:	68 65 49 10 f0       	push   $0xf0104965
f0100939:	6a 43                	push   $0x43
f010093b:	68 6a 49 10 f0       	push   $0xf010496a
f0100940:	e8 53 f8 ff ff       	call   f0100198 <_panic>
	if (p && p->state == RUNNING && tf->trapno == T_IRQ0 + IRQ_TIMER) {
f0100945:	83 7b 30 20          	cmpl   $0x20,0x30(%ebx)
f0100949:	0f 85 5e ff ff ff    	jne    f01008ad <trap+0x68>
		if (ticks - p->begin_tick < time_slice[p->priority])
f010094f:	a1 a0 6e 12 f0       	mov    0xf0126ea0,%eax
f0100954:	2b 46 28             	sub    0x28(%esi),%eax
f0100957:	8b 56 20             	mov    0x20(%esi),%edx
f010095a:	3b 04 95 38 e7 11 f0 	cmp    -0xfee18c8(,%edx,4),%eax
f0100961:	0f 82 46 ff ff ff    	jb     f01008ad <trap+0x68>
		yield();
f0100967:	e8 71 2c 00 00       	call   f01035dd <yield>
f010096c:	e9 3c ff ff ff       	jmp    f01008ad <trap+0x68>

f0100971 <alltraps>:
alltraps:
	# Your code here:
	#
	# Hint: you should build trap frame, set up data segments and then
	# call trap(tf)
	pushl %ds
f0100971:	1e                   	push   %ds
	pushl %es
f0100972:	06                   	push   %es
	pushl %fs
f0100973:	0f a0                	push   %fs
	pushl %gs
f0100975:	0f a8                	push   %gs
	pushal 
f0100977:	60                   	pusha  

	movw $(SEG_KDATA<<3), %ax
f0100978:	66 b8 10 00          	mov    $0x10,%ax
	movw %ax, %ds
f010097c:	8e d8                	mov    %eax,%ds
	movw %ax, %es
f010097e:	8e c0                	mov    %eax,%es

	pushl %esp
f0100980:	54                   	push   %esp
	call trap
f0100981:	e8 bf fe ff ff       	call   f0100845 <trap>
	addl $4, %esp
f0100986:	83 c4 04             	add    $0x4,%esp

f0100989 <trapret>:
	# Return falls through to trapret...
.globl trapret
trapret:
	# Restore registers.
	# Your code here:
	popal
f0100989:	61                   	popa   
	popl %gs
f010098a:	0f a9                	pop    %gs
	popl %fs
f010098c:	0f a1                	pop    %fs
	popl %es
f010098e:	07                   	pop    %es
	popl %ds
f010098f:	1f                   	pop    %ds
	addl $0x8, %esp
f0100990:	83 c4 08             	add    $0x8,%esp
	iret
f0100993:	cf                   	iret   

f0100994 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
f0100994:	6a 00                	push   $0x0
  pushl $0
f0100996:	6a 00                	push   $0x0
  jmp alltraps
f0100998:	e9 d4 ff ff ff       	jmp    f0100971 <alltraps>

f010099d <vector1>:
.globl vector1
vector1:
  pushl $0
f010099d:	6a 00                	push   $0x0
  pushl $1
f010099f:	6a 01                	push   $0x1
  jmp alltraps
f01009a1:	e9 cb ff ff ff       	jmp    f0100971 <alltraps>

f01009a6 <vector2>:
.globl vector2
vector2:
  pushl $0
f01009a6:	6a 00                	push   $0x0
  pushl $2
f01009a8:	6a 02                	push   $0x2
  jmp alltraps
f01009aa:	e9 c2 ff ff ff       	jmp    f0100971 <alltraps>

f01009af <vector3>:
.globl vector3
vector3:
  pushl $0
f01009af:	6a 00                	push   $0x0
  pushl $3
f01009b1:	6a 03                	push   $0x3
  jmp alltraps
f01009b3:	e9 b9 ff ff ff       	jmp    f0100971 <alltraps>

f01009b8 <vector4>:
.globl vector4
vector4:
  pushl $0
f01009b8:	6a 00                	push   $0x0
  pushl $4
f01009ba:	6a 04                	push   $0x4
  jmp alltraps
f01009bc:	e9 b0 ff ff ff       	jmp    f0100971 <alltraps>

f01009c1 <vector5>:
.globl vector5
vector5:
  pushl $0
f01009c1:	6a 00                	push   $0x0
  pushl $5
f01009c3:	6a 05                	push   $0x5
  jmp alltraps
f01009c5:	e9 a7 ff ff ff       	jmp    f0100971 <alltraps>

f01009ca <vector6>:
.globl vector6
vector6:
  pushl $0
f01009ca:	6a 00                	push   $0x0
  pushl $6
f01009cc:	6a 06                	push   $0x6
  jmp alltraps
f01009ce:	e9 9e ff ff ff       	jmp    f0100971 <alltraps>

f01009d3 <vector7>:
.globl vector7
vector7:
  pushl $0
f01009d3:	6a 00                	push   $0x0
  pushl $7
f01009d5:	6a 07                	push   $0x7
  jmp alltraps
f01009d7:	e9 95 ff ff ff       	jmp    f0100971 <alltraps>

f01009dc <vector8>:
.globl vector8
vector8:
  pushl $8
f01009dc:	6a 08                	push   $0x8
  jmp alltraps
f01009de:	e9 8e ff ff ff       	jmp    f0100971 <alltraps>

f01009e3 <vector9>:
.globl vector9
vector9:
  pushl $0
f01009e3:	6a 00                	push   $0x0
  pushl $9
f01009e5:	6a 09                	push   $0x9
  jmp alltraps
f01009e7:	e9 85 ff ff ff       	jmp    f0100971 <alltraps>

f01009ec <vector10>:
.globl vector10
vector10:
  pushl $10
f01009ec:	6a 0a                	push   $0xa
  jmp alltraps
f01009ee:	e9 7e ff ff ff       	jmp    f0100971 <alltraps>

f01009f3 <vector11>:
.globl vector11
vector11:
  pushl $11
f01009f3:	6a 0b                	push   $0xb
  jmp alltraps
f01009f5:	e9 77 ff ff ff       	jmp    f0100971 <alltraps>

f01009fa <vector12>:
.globl vector12
vector12:
  pushl $12
f01009fa:	6a 0c                	push   $0xc
  jmp alltraps
f01009fc:	e9 70 ff ff ff       	jmp    f0100971 <alltraps>

f0100a01 <vector13>:
.globl vector13
vector13:
  pushl $13
f0100a01:	6a 0d                	push   $0xd
  jmp alltraps
f0100a03:	e9 69 ff ff ff       	jmp    f0100971 <alltraps>

f0100a08 <vector14>:
.globl vector14
vector14:
  pushl $14
f0100a08:	6a 0e                	push   $0xe
  jmp alltraps
f0100a0a:	e9 62 ff ff ff       	jmp    f0100971 <alltraps>

f0100a0f <vector15>:
.globl vector15
vector15:
  pushl $0
f0100a0f:	6a 00                	push   $0x0
  pushl $15
f0100a11:	6a 0f                	push   $0xf
  jmp alltraps
f0100a13:	e9 59 ff ff ff       	jmp    f0100971 <alltraps>

f0100a18 <vector16>:
.globl vector16
vector16:
  pushl $0
f0100a18:	6a 00                	push   $0x0
  pushl $16
f0100a1a:	6a 10                	push   $0x10
  jmp alltraps
f0100a1c:	e9 50 ff ff ff       	jmp    f0100971 <alltraps>

f0100a21 <vector17>:
.globl vector17
vector17:
  pushl $17
f0100a21:	6a 11                	push   $0x11
  jmp alltraps
f0100a23:	e9 49 ff ff ff       	jmp    f0100971 <alltraps>

f0100a28 <vector18>:
.globl vector18
vector18:
  pushl $0
f0100a28:	6a 00                	push   $0x0
  pushl $18
f0100a2a:	6a 12                	push   $0x12
  jmp alltraps
f0100a2c:	e9 40 ff ff ff       	jmp    f0100971 <alltraps>

f0100a31 <vector19>:
.globl vector19
vector19:
  pushl $0
f0100a31:	6a 00                	push   $0x0
  pushl $19
f0100a33:	6a 13                	push   $0x13
  jmp alltraps
f0100a35:	e9 37 ff ff ff       	jmp    f0100971 <alltraps>

f0100a3a <vector20>:
.globl vector20
vector20:
  pushl $0
f0100a3a:	6a 00                	push   $0x0
  pushl $20
f0100a3c:	6a 14                	push   $0x14
  jmp alltraps
f0100a3e:	e9 2e ff ff ff       	jmp    f0100971 <alltraps>

f0100a43 <vector21>:
.globl vector21
vector21:
  pushl $0
f0100a43:	6a 00                	push   $0x0
  pushl $21
f0100a45:	6a 15                	push   $0x15
  jmp alltraps
f0100a47:	e9 25 ff ff ff       	jmp    f0100971 <alltraps>

f0100a4c <vector22>:
.globl vector22
vector22:
  pushl $0
f0100a4c:	6a 00                	push   $0x0
  pushl $22
f0100a4e:	6a 16                	push   $0x16
  jmp alltraps
f0100a50:	e9 1c ff ff ff       	jmp    f0100971 <alltraps>

f0100a55 <vector23>:
.globl vector23
vector23:
  pushl $0
f0100a55:	6a 00                	push   $0x0
  pushl $23
f0100a57:	6a 17                	push   $0x17
  jmp alltraps
f0100a59:	e9 13 ff ff ff       	jmp    f0100971 <alltraps>

f0100a5e <vector24>:
.globl vector24
vector24:
  pushl $0
f0100a5e:	6a 00                	push   $0x0
  pushl $24
f0100a60:	6a 18                	push   $0x18
  jmp alltraps
f0100a62:	e9 0a ff ff ff       	jmp    f0100971 <alltraps>

f0100a67 <vector25>:
.globl vector25
vector25:
  pushl $0
f0100a67:	6a 00                	push   $0x0
  pushl $25
f0100a69:	6a 19                	push   $0x19
  jmp alltraps
f0100a6b:	e9 01 ff ff ff       	jmp    f0100971 <alltraps>

f0100a70 <vector26>:
.globl vector26
vector26:
  pushl $0
f0100a70:	6a 00                	push   $0x0
  pushl $26
f0100a72:	6a 1a                	push   $0x1a
  jmp alltraps
f0100a74:	e9 f8 fe ff ff       	jmp    f0100971 <alltraps>

f0100a79 <vector27>:
.globl vector27
vector27:
  pushl $0
f0100a79:	6a 00                	push   $0x0
  pushl $27
f0100a7b:	6a 1b                	push   $0x1b
  jmp alltraps
f0100a7d:	e9 ef fe ff ff       	jmp    f0100971 <alltraps>

f0100a82 <vector28>:
.globl vector28
vector28:
  pushl $0
f0100a82:	6a 00                	push   $0x0
  pushl $28
f0100a84:	6a 1c                	push   $0x1c
  jmp alltraps
f0100a86:	e9 e6 fe ff ff       	jmp    f0100971 <alltraps>

f0100a8b <vector29>:
.globl vector29
vector29:
  pushl $0
f0100a8b:	6a 00                	push   $0x0
  pushl $29
f0100a8d:	6a 1d                	push   $0x1d
  jmp alltraps
f0100a8f:	e9 dd fe ff ff       	jmp    f0100971 <alltraps>

f0100a94 <vector30>:
.globl vector30
vector30:
  pushl $0
f0100a94:	6a 00                	push   $0x0
  pushl $30
f0100a96:	6a 1e                	push   $0x1e
  jmp alltraps
f0100a98:	e9 d4 fe ff ff       	jmp    f0100971 <alltraps>

f0100a9d <vector31>:
.globl vector31
vector31:
  pushl $0
f0100a9d:	6a 00                	push   $0x0
  pushl $31
f0100a9f:	6a 1f                	push   $0x1f
  jmp alltraps
f0100aa1:	e9 cb fe ff ff       	jmp    f0100971 <alltraps>

f0100aa6 <vector32>:
.globl vector32
vector32:
  pushl $0
f0100aa6:	6a 00                	push   $0x0
  pushl $32
f0100aa8:	6a 20                	push   $0x20
  jmp alltraps
f0100aaa:	e9 c2 fe ff ff       	jmp    f0100971 <alltraps>

f0100aaf <vector33>:
.globl vector33
vector33:
  pushl $0
f0100aaf:	6a 00                	push   $0x0
  pushl $33
f0100ab1:	6a 21                	push   $0x21
  jmp alltraps
f0100ab3:	e9 b9 fe ff ff       	jmp    f0100971 <alltraps>

f0100ab8 <vector34>:
.globl vector34
vector34:
  pushl $0
f0100ab8:	6a 00                	push   $0x0
  pushl $34
f0100aba:	6a 22                	push   $0x22
  jmp alltraps
f0100abc:	e9 b0 fe ff ff       	jmp    f0100971 <alltraps>

f0100ac1 <vector35>:
.globl vector35
vector35:
  pushl $0
f0100ac1:	6a 00                	push   $0x0
  pushl $35
f0100ac3:	6a 23                	push   $0x23
  jmp alltraps
f0100ac5:	e9 a7 fe ff ff       	jmp    f0100971 <alltraps>

f0100aca <vector36>:
.globl vector36
vector36:
  pushl $0
f0100aca:	6a 00                	push   $0x0
  pushl $36
f0100acc:	6a 24                	push   $0x24
  jmp alltraps
f0100ace:	e9 9e fe ff ff       	jmp    f0100971 <alltraps>

f0100ad3 <vector37>:
.globl vector37
vector37:
  pushl $0
f0100ad3:	6a 00                	push   $0x0
  pushl $37
f0100ad5:	6a 25                	push   $0x25
  jmp alltraps
f0100ad7:	e9 95 fe ff ff       	jmp    f0100971 <alltraps>

f0100adc <vector38>:
.globl vector38
vector38:
  pushl $0
f0100adc:	6a 00                	push   $0x0
  pushl $38
f0100ade:	6a 26                	push   $0x26
  jmp alltraps
f0100ae0:	e9 8c fe ff ff       	jmp    f0100971 <alltraps>

f0100ae5 <vector39>:
.globl vector39
vector39:
  pushl $0
f0100ae5:	6a 00                	push   $0x0
  pushl $39
f0100ae7:	6a 27                	push   $0x27
  jmp alltraps
f0100ae9:	e9 83 fe ff ff       	jmp    f0100971 <alltraps>

f0100aee <vector40>:
.globl vector40
vector40:
  pushl $0
f0100aee:	6a 00                	push   $0x0
  pushl $40
f0100af0:	6a 28                	push   $0x28
  jmp alltraps
f0100af2:	e9 7a fe ff ff       	jmp    f0100971 <alltraps>

f0100af7 <vector41>:
.globl vector41
vector41:
  pushl $0
f0100af7:	6a 00                	push   $0x0
  pushl $41
f0100af9:	6a 29                	push   $0x29
  jmp alltraps
f0100afb:	e9 71 fe ff ff       	jmp    f0100971 <alltraps>

f0100b00 <vector42>:
.globl vector42
vector42:
  pushl $0
f0100b00:	6a 00                	push   $0x0
  pushl $42
f0100b02:	6a 2a                	push   $0x2a
  jmp alltraps
f0100b04:	e9 68 fe ff ff       	jmp    f0100971 <alltraps>

f0100b09 <vector43>:
.globl vector43
vector43:
  pushl $0
f0100b09:	6a 00                	push   $0x0
  pushl $43
f0100b0b:	6a 2b                	push   $0x2b
  jmp alltraps
f0100b0d:	e9 5f fe ff ff       	jmp    f0100971 <alltraps>

f0100b12 <vector44>:
.globl vector44
vector44:
  pushl $0
f0100b12:	6a 00                	push   $0x0
  pushl $44
f0100b14:	6a 2c                	push   $0x2c
  jmp alltraps
f0100b16:	e9 56 fe ff ff       	jmp    f0100971 <alltraps>

f0100b1b <vector45>:
.globl vector45
vector45:
  pushl $0
f0100b1b:	6a 00                	push   $0x0
  pushl $45
f0100b1d:	6a 2d                	push   $0x2d
  jmp alltraps
f0100b1f:	e9 4d fe ff ff       	jmp    f0100971 <alltraps>

f0100b24 <vector46>:
.globl vector46
vector46:
  pushl $0
f0100b24:	6a 00                	push   $0x0
  pushl $46
f0100b26:	6a 2e                	push   $0x2e
  jmp alltraps
f0100b28:	e9 44 fe ff ff       	jmp    f0100971 <alltraps>

f0100b2d <vector47>:
.globl vector47
vector47:
  pushl $0
f0100b2d:	6a 00                	push   $0x0
  pushl $47
f0100b2f:	6a 2f                	push   $0x2f
  jmp alltraps
f0100b31:	e9 3b fe ff ff       	jmp    f0100971 <alltraps>

f0100b36 <vector48>:
.globl vector48
vector48:
  pushl $0
f0100b36:	6a 00                	push   $0x0
  pushl $48
f0100b38:	6a 30                	push   $0x30
  jmp alltraps
f0100b3a:	e9 32 fe ff ff       	jmp    f0100971 <alltraps>

f0100b3f <vector49>:
.globl vector49
vector49:
  pushl $0
f0100b3f:	6a 00                	push   $0x0
  pushl $49
f0100b41:	6a 31                	push   $0x31
  jmp alltraps
f0100b43:	e9 29 fe ff ff       	jmp    f0100971 <alltraps>

f0100b48 <vector50>:
.globl vector50
vector50:
  pushl $0
f0100b48:	6a 00                	push   $0x0
  pushl $50
f0100b4a:	6a 32                	push   $0x32
  jmp alltraps
f0100b4c:	e9 20 fe ff ff       	jmp    f0100971 <alltraps>

f0100b51 <vector51>:
.globl vector51
vector51:
  pushl $0
f0100b51:	6a 00                	push   $0x0
  pushl $51
f0100b53:	6a 33                	push   $0x33
  jmp alltraps
f0100b55:	e9 17 fe ff ff       	jmp    f0100971 <alltraps>

f0100b5a <vector52>:
.globl vector52
vector52:
  pushl $0
f0100b5a:	6a 00                	push   $0x0
  pushl $52
f0100b5c:	6a 34                	push   $0x34
  jmp alltraps
f0100b5e:	e9 0e fe ff ff       	jmp    f0100971 <alltraps>

f0100b63 <vector53>:
.globl vector53
vector53:
  pushl $0
f0100b63:	6a 00                	push   $0x0
  pushl $53
f0100b65:	6a 35                	push   $0x35
  jmp alltraps
f0100b67:	e9 05 fe ff ff       	jmp    f0100971 <alltraps>

f0100b6c <vector54>:
.globl vector54
vector54:
  pushl $0
f0100b6c:	6a 00                	push   $0x0
  pushl $54
f0100b6e:	6a 36                	push   $0x36
  jmp alltraps
f0100b70:	e9 fc fd ff ff       	jmp    f0100971 <alltraps>

f0100b75 <vector55>:
.globl vector55
vector55:
  pushl $0
f0100b75:	6a 00                	push   $0x0
  pushl $55
f0100b77:	6a 37                	push   $0x37
  jmp alltraps
f0100b79:	e9 f3 fd ff ff       	jmp    f0100971 <alltraps>

f0100b7e <vector56>:
.globl vector56
vector56:
  pushl $0
f0100b7e:	6a 00                	push   $0x0
  pushl $56
f0100b80:	6a 38                	push   $0x38
  jmp alltraps
f0100b82:	e9 ea fd ff ff       	jmp    f0100971 <alltraps>

f0100b87 <vector57>:
.globl vector57
vector57:
  pushl $0
f0100b87:	6a 00                	push   $0x0
  pushl $57
f0100b89:	6a 39                	push   $0x39
  jmp alltraps
f0100b8b:	e9 e1 fd ff ff       	jmp    f0100971 <alltraps>

f0100b90 <vector58>:
.globl vector58
vector58:
  pushl $0
f0100b90:	6a 00                	push   $0x0
  pushl $58
f0100b92:	6a 3a                	push   $0x3a
  jmp alltraps
f0100b94:	e9 d8 fd ff ff       	jmp    f0100971 <alltraps>

f0100b99 <vector59>:
.globl vector59
vector59:
  pushl $0
f0100b99:	6a 00                	push   $0x0
  pushl $59
f0100b9b:	6a 3b                	push   $0x3b
  jmp alltraps
f0100b9d:	e9 cf fd ff ff       	jmp    f0100971 <alltraps>

f0100ba2 <vector60>:
.globl vector60
vector60:
  pushl $0
f0100ba2:	6a 00                	push   $0x0
  pushl $60
f0100ba4:	6a 3c                	push   $0x3c
  jmp alltraps
f0100ba6:	e9 c6 fd ff ff       	jmp    f0100971 <alltraps>

f0100bab <vector61>:
.globl vector61
vector61:
  pushl $0
f0100bab:	6a 00                	push   $0x0
  pushl $61
f0100bad:	6a 3d                	push   $0x3d
  jmp alltraps
f0100baf:	e9 bd fd ff ff       	jmp    f0100971 <alltraps>

f0100bb4 <vector62>:
.globl vector62
vector62:
  pushl $0
f0100bb4:	6a 00                	push   $0x0
  pushl $62
f0100bb6:	6a 3e                	push   $0x3e
  jmp alltraps
f0100bb8:	e9 b4 fd ff ff       	jmp    f0100971 <alltraps>

f0100bbd <vector63>:
.globl vector63
vector63:
  pushl $0
f0100bbd:	6a 00                	push   $0x0
  pushl $63
f0100bbf:	6a 3f                	push   $0x3f
  jmp alltraps
f0100bc1:	e9 ab fd ff ff       	jmp    f0100971 <alltraps>

f0100bc6 <vector64>:
.globl vector64
vector64:
  pushl $0
f0100bc6:	6a 00                	push   $0x0
  pushl $64
f0100bc8:	6a 40                	push   $0x40
  jmp alltraps
f0100bca:	e9 a2 fd ff ff       	jmp    f0100971 <alltraps>

f0100bcf <vector65>:
.globl vector65
vector65:
  pushl $0
f0100bcf:	6a 00                	push   $0x0
  pushl $65
f0100bd1:	6a 41                	push   $0x41
  jmp alltraps
f0100bd3:	e9 99 fd ff ff       	jmp    f0100971 <alltraps>

f0100bd8 <vector66>:
.globl vector66
vector66:
  pushl $0
f0100bd8:	6a 00                	push   $0x0
  pushl $66
f0100bda:	6a 42                	push   $0x42
  jmp alltraps
f0100bdc:	e9 90 fd ff ff       	jmp    f0100971 <alltraps>

f0100be1 <vector67>:
.globl vector67
vector67:
  pushl $0
f0100be1:	6a 00                	push   $0x0
  pushl $67
f0100be3:	6a 43                	push   $0x43
  jmp alltraps
f0100be5:	e9 87 fd ff ff       	jmp    f0100971 <alltraps>

f0100bea <vector68>:
.globl vector68
vector68:
  pushl $0
f0100bea:	6a 00                	push   $0x0
  pushl $68
f0100bec:	6a 44                	push   $0x44
  jmp alltraps
f0100bee:	e9 7e fd ff ff       	jmp    f0100971 <alltraps>

f0100bf3 <vector69>:
.globl vector69
vector69:
  pushl $0
f0100bf3:	6a 00                	push   $0x0
  pushl $69
f0100bf5:	6a 45                	push   $0x45
  jmp alltraps
f0100bf7:	e9 75 fd ff ff       	jmp    f0100971 <alltraps>

f0100bfc <vector70>:
.globl vector70
vector70:
  pushl $0
f0100bfc:	6a 00                	push   $0x0
  pushl $70
f0100bfe:	6a 46                	push   $0x46
  jmp alltraps
f0100c00:	e9 6c fd ff ff       	jmp    f0100971 <alltraps>

f0100c05 <vector71>:
.globl vector71
vector71:
  pushl $0
f0100c05:	6a 00                	push   $0x0
  pushl $71
f0100c07:	6a 47                	push   $0x47
  jmp alltraps
f0100c09:	e9 63 fd ff ff       	jmp    f0100971 <alltraps>

f0100c0e <vector72>:
.globl vector72
vector72:
  pushl $0
f0100c0e:	6a 00                	push   $0x0
  pushl $72
f0100c10:	6a 48                	push   $0x48
  jmp alltraps
f0100c12:	e9 5a fd ff ff       	jmp    f0100971 <alltraps>

f0100c17 <vector73>:
.globl vector73
vector73:
  pushl $0
f0100c17:	6a 00                	push   $0x0
  pushl $73
f0100c19:	6a 49                	push   $0x49
  jmp alltraps
f0100c1b:	e9 51 fd ff ff       	jmp    f0100971 <alltraps>

f0100c20 <vector74>:
.globl vector74
vector74:
  pushl $0
f0100c20:	6a 00                	push   $0x0
  pushl $74
f0100c22:	6a 4a                	push   $0x4a
  jmp alltraps
f0100c24:	e9 48 fd ff ff       	jmp    f0100971 <alltraps>

f0100c29 <vector75>:
.globl vector75
vector75:
  pushl $0
f0100c29:	6a 00                	push   $0x0
  pushl $75
f0100c2b:	6a 4b                	push   $0x4b
  jmp alltraps
f0100c2d:	e9 3f fd ff ff       	jmp    f0100971 <alltraps>

f0100c32 <vector76>:
.globl vector76
vector76:
  pushl $0
f0100c32:	6a 00                	push   $0x0
  pushl $76
f0100c34:	6a 4c                	push   $0x4c
  jmp alltraps
f0100c36:	e9 36 fd ff ff       	jmp    f0100971 <alltraps>

f0100c3b <vector77>:
.globl vector77
vector77:
  pushl $0
f0100c3b:	6a 00                	push   $0x0
  pushl $77
f0100c3d:	6a 4d                	push   $0x4d
  jmp alltraps
f0100c3f:	e9 2d fd ff ff       	jmp    f0100971 <alltraps>

f0100c44 <vector78>:
.globl vector78
vector78:
  pushl $0
f0100c44:	6a 00                	push   $0x0
  pushl $78
f0100c46:	6a 4e                	push   $0x4e
  jmp alltraps
f0100c48:	e9 24 fd ff ff       	jmp    f0100971 <alltraps>

f0100c4d <vector79>:
.globl vector79
vector79:
  pushl $0
f0100c4d:	6a 00                	push   $0x0
  pushl $79
f0100c4f:	6a 4f                	push   $0x4f
  jmp alltraps
f0100c51:	e9 1b fd ff ff       	jmp    f0100971 <alltraps>

f0100c56 <vector80>:
.globl vector80
vector80:
  pushl $0
f0100c56:	6a 00                	push   $0x0
  pushl $80
f0100c58:	6a 50                	push   $0x50
  jmp alltraps
f0100c5a:	e9 12 fd ff ff       	jmp    f0100971 <alltraps>

f0100c5f <vector81>:
.globl vector81
vector81:
  pushl $0
f0100c5f:	6a 00                	push   $0x0
  pushl $81
f0100c61:	6a 51                	push   $0x51
  jmp alltraps
f0100c63:	e9 09 fd ff ff       	jmp    f0100971 <alltraps>

f0100c68 <vector82>:
.globl vector82
vector82:
  pushl $0
f0100c68:	6a 00                	push   $0x0
  pushl $82
f0100c6a:	6a 52                	push   $0x52
  jmp alltraps
f0100c6c:	e9 00 fd ff ff       	jmp    f0100971 <alltraps>

f0100c71 <vector83>:
.globl vector83
vector83:
  pushl $0
f0100c71:	6a 00                	push   $0x0
  pushl $83
f0100c73:	6a 53                	push   $0x53
  jmp alltraps
f0100c75:	e9 f7 fc ff ff       	jmp    f0100971 <alltraps>

f0100c7a <vector84>:
.globl vector84
vector84:
  pushl $0
f0100c7a:	6a 00                	push   $0x0
  pushl $84
f0100c7c:	6a 54                	push   $0x54
  jmp alltraps
f0100c7e:	e9 ee fc ff ff       	jmp    f0100971 <alltraps>

f0100c83 <vector85>:
.globl vector85
vector85:
  pushl $0
f0100c83:	6a 00                	push   $0x0
  pushl $85
f0100c85:	6a 55                	push   $0x55
  jmp alltraps
f0100c87:	e9 e5 fc ff ff       	jmp    f0100971 <alltraps>

f0100c8c <vector86>:
.globl vector86
vector86:
  pushl $0
f0100c8c:	6a 00                	push   $0x0
  pushl $86
f0100c8e:	6a 56                	push   $0x56
  jmp alltraps
f0100c90:	e9 dc fc ff ff       	jmp    f0100971 <alltraps>

f0100c95 <vector87>:
.globl vector87
vector87:
  pushl $0
f0100c95:	6a 00                	push   $0x0
  pushl $87
f0100c97:	6a 57                	push   $0x57
  jmp alltraps
f0100c99:	e9 d3 fc ff ff       	jmp    f0100971 <alltraps>

f0100c9e <vector88>:
.globl vector88
vector88:
  pushl $0
f0100c9e:	6a 00                	push   $0x0
  pushl $88
f0100ca0:	6a 58                	push   $0x58
  jmp alltraps
f0100ca2:	e9 ca fc ff ff       	jmp    f0100971 <alltraps>

f0100ca7 <vector89>:
.globl vector89
vector89:
  pushl $0
f0100ca7:	6a 00                	push   $0x0
  pushl $89
f0100ca9:	6a 59                	push   $0x59
  jmp alltraps
f0100cab:	e9 c1 fc ff ff       	jmp    f0100971 <alltraps>

f0100cb0 <vector90>:
.globl vector90
vector90:
  pushl $0
f0100cb0:	6a 00                	push   $0x0
  pushl $90
f0100cb2:	6a 5a                	push   $0x5a
  jmp alltraps
f0100cb4:	e9 b8 fc ff ff       	jmp    f0100971 <alltraps>

f0100cb9 <vector91>:
.globl vector91
vector91:
  pushl $0
f0100cb9:	6a 00                	push   $0x0
  pushl $91
f0100cbb:	6a 5b                	push   $0x5b
  jmp alltraps
f0100cbd:	e9 af fc ff ff       	jmp    f0100971 <alltraps>

f0100cc2 <vector92>:
.globl vector92
vector92:
  pushl $0
f0100cc2:	6a 00                	push   $0x0
  pushl $92
f0100cc4:	6a 5c                	push   $0x5c
  jmp alltraps
f0100cc6:	e9 a6 fc ff ff       	jmp    f0100971 <alltraps>

f0100ccb <vector93>:
.globl vector93
vector93:
  pushl $0
f0100ccb:	6a 00                	push   $0x0
  pushl $93
f0100ccd:	6a 5d                	push   $0x5d
  jmp alltraps
f0100ccf:	e9 9d fc ff ff       	jmp    f0100971 <alltraps>

f0100cd4 <vector94>:
.globl vector94
vector94:
  pushl $0
f0100cd4:	6a 00                	push   $0x0
  pushl $94
f0100cd6:	6a 5e                	push   $0x5e
  jmp alltraps
f0100cd8:	e9 94 fc ff ff       	jmp    f0100971 <alltraps>

f0100cdd <vector95>:
.globl vector95
vector95:
  pushl $0
f0100cdd:	6a 00                	push   $0x0
  pushl $95
f0100cdf:	6a 5f                	push   $0x5f
  jmp alltraps
f0100ce1:	e9 8b fc ff ff       	jmp    f0100971 <alltraps>

f0100ce6 <vector96>:
.globl vector96
vector96:
  pushl $0
f0100ce6:	6a 00                	push   $0x0
  pushl $96
f0100ce8:	6a 60                	push   $0x60
  jmp alltraps
f0100cea:	e9 82 fc ff ff       	jmp    f0100971 <alltraps>

f0100cef <vector97>:
.globl vector97
vector97:
  pushl $0
f0100cef:	6a 00                	push   $0x0
  pushl $97
f0100cf1:	6a 61                	push   $0x61
  jmp alltraps
f0100cf3:	e9 79 fc ff ff       	jmp    f0100971 <alltraps>

f0100cf8 <vector98>:
.globl vector98
vector98:
  pushl $0
f0100cf8:	6a 00                	push   $0x0
  pushl $98
f0100cfa:	6a 62                	push   $0x62
  jmp alltraps
f0100cfc:	e9 70 fc ff ff       	jmp    f0100971 <alltraps>

f0100d01 <vector99>:
.globl vector99
vector99:
  pushl $0
f0100d01:	6a 00                	push   $0x0
  pushl $99
f0100d03:	6a 63                	push   $0x63
  jmp alltraps
f0100d05:	e9 67 fc ff ff       	jmp    f0100971 <alltraps>

f0100d0a <vector100>:
.globl vector100
vector100:
  pushl $0
f0100d0a:	6a 00                	push   $0x0
  pushl $100
f0100d0c:	6a 64                	push   $0x64
  jmp alltraps
f0100d0e:	e9 5e fc ff ff       	jmp    f0100971 <alltraps>

f0100d13 <vector101>:
.globl vector101
vector101:
  pushl $0
f0100d13:	6a 00                	push   $0x0
  pushl $101
f0100d15:	6a 65                	push   $0x65
  jmp alltraps
f0100d17:	e9 55 fc ff ff       	jmp    f0100971 <alltraps>

f0100d1c <vector102>:
.globl vector102
vector102:
  pushl $0
f0100d1c:	6a 00                	push   $0x0
  pushl $102
f0100d1e:	6a 66                	push   $0x66
  jmp alltraps
f0100d20:	e9 4c fc ff ff       	jmp    f0100971 <alltraps>

f0100d25 <vector103>:
.globl vector103
vector103:
  pushl $0
f0100d25:	6a 00                	push   $0x0
  pushl $103
f0100d27:	6a 67                	push   $0x67
  jmp alltraps
f0100d29:	e9 43 fc ff ff       	jmp    f0100971 <alltraps>

f0100d2e <vector104>:
.globl vector104
vector104:
  pushl $0
f0100d2e:	6a 00                	push   $0x0
  pushl $104
f0100d30:	6a 68                	push   $0x68
  jmp alltraps
f0100d32:	e9 3a fc ff ff       	jmp    f0100971 <alltraps>

f0100d37 <vector105>:
.globl vector105
vector105:
  pushl $0
f0100d37:	6a 00                	push   $0x0
  pushl $105
f0100d39:	6a 69                	push   $0x69
  jmp alltraps
f0100d3b:	e9 31 fc ff ff       	jmp    f0100971 <alltraps>

f0100d40 <vector106>:
.globl vector106
vector106:
  pushl $0
f0100d40:	6a 00                	push   $0x0
  pushl $106
f0100d42:	6a 6a                	push   $0x6a
  jmp alltraps
f0100d44:	e9 28 fc ff ff       	jmp    f0100971 <alltraps>

f0100d49 <vector107>:
.globl vector107
vector107:
  pushl $0
f0100d49:	6a 00                	push   $0x0
  pushl $107
f0100d4b:	6a 6b                	push   $0x6b
  jmp alltraps
f0100d4d:	e9 1f fc ff ff       	jmp    f0100971 <alltraps>

f0100d52 <vector108>:
.globl vector108
vector108:
  pushl $0
f0100d52:	6a 00                	push   $0x0
  pushl $108
f0100d54:	6a 6c                	push   $0x6c
  jmp alltraps
f0100d56:	e9 16 fc ff ff       	jmp    f0100971 <alltraps>

f0100d5b <vector109>:
.globl vector109
vector109:
  pushl $0
f0100d5b:	6a 00                	push   $0x0
  pushl $109
f0100d5d:	6a 6d                	push   $0x6d
  jmp alltraps
f0100d5f:	e9 0d fc ff ff       	jmp    f0100971 <alltraps>

f0100d64 <vector110>:
.globl vector110
vector110:
  pushl $0
f0100d64:	6a 00                	push   $0x0
  pushl $110
f0100d66:	6a 6e                	push   $0x6e
  jmp alltraps
f0100d68:	e9 04 fc ff ff       	jmp    f0100971 <alltraps>

f0100d6d <vector111>:
.globl vector111
vector111:
  pushl $0
f0100d6d:	6a 00                	push   $0x0
  pushl $111
f0100d6f:	6a 6f                	push   $0x6f
  jmp alltraps
f0100d71:	e9 fb fb ff ff       	jmp    f0100971 <alltraps>

f0100d76 <vector112>:
.globl vector112
vector112:
  pushl $0
f0100d76:	6a 00                	push   $0x0
  pushl $112
f0100d78:	6a 70                	push   $0x70
  jmp alltraps
f0100d7a:	e9 f2 fb ff ff       	jmp    f0100971 <alltraps>

f0100d7f <vector113>:
.globl vector113
vector113:
  pushl $0
f0100d7f:	6a 00                	push   $0x0
  pushl $113
f0100d81:	6a 71                	push   $0x71
  jmp alltraps
f0100d83:	e9 e9 fb ff ff       	jmp    f0100971 <alltraps>

f0100d88 <vector114>:
.globl vector114
vector114:
  pushl $0
f0100d88:	6a 00                	push   $0x0
  pushl $114
f0100d8a:	6a 72                	push   $0x72
  jmp alltraps
f0100d8c:	e9 e0 fb ff ff       	jmp    f0100971 <alltraps>

f0100d91 <vector115>:
.globl vector115
vector115:
  pushl $0
f0100d91:	6a 00                	push   $0x0
  pushl $115
f0100d93:	6a 73                	push   $0x73
  jmp alltraps
f0100d95:	e9 d7 fb ff ff       	jmp    f0100971 <alltraps>

f0100d9a <vector116>:
.globl vector116
vector116:
  pushl $0
f0100d9a:	6a 00                	push   $0x0
  pushl $116
f0100d9c:	6a 74                	push   $0x74
  jmp alltraps
f0100d9e:	e9 ce fb ff ff       	jmp    f0100971 <alltraps>

f0100da3 <vector117>:
.globl vector117
vector117:
  pushl $0
f0100da3:	6a 00                	push   $0x0
  pushl $117
f0100da5:	6a 75                	push   $0x75
  jmp alltraps
f0100da7:	e9 c5 fb ff ff       	jmp    f0100971 <alltraps>

f0100dac <vector118>:
.globl vector118
vector118:
  pushl $0
f0100dac:	6a 00                	push   $0x0
  pushl $118
f0100dae:	6a 76                	push   $0x76
  jmp alltraps
f0100db0:	e9 bc fb ff ff       	jmp    f0100971 <alltraps>

f0100db5 <vector119>:
.globl vector119
vector119:
  pushl $0
f0100db5:	6a 00                	push   $0x0
  pushl $119
f0100db7:	6a 77                	push   $0x77
  jmp alltraps
f0100db9:	e9 b3 fb ff ff       	jmp    f0100971 <alltraps>

f0100dbe <vector120>:
.globl vector120
vector120:
  pushl $0
f0100dbe:	6a 00                	push   $0x0
  pushl $120
f0100dc0:	6a 78                	push   $0x78
  jmp alltraps
f0100dc2:	e9 aa fb ff ff       	jmp    f0100971 <alltraps>

f0100dc7 <vector121>:
.globl vector121
vector121:
  pushl $0
f0100dc7:	6a 00                	push   $0x0
  pushl $121
f0100dc9:	6a 79                	push   $0x79
  jmp alltraps
f0100dcb:	e9 a1 fb ff ff       	jmp    f0100971 <alltraps>

f0100dd0 <vector122>:
.globl vector122
vector122:
  pushl $0
f0100dd0:	6a 00                	push   $0x0
  pushl $122
f0100dd2:	6a 7a                	push   $0x7a
  jmp alltraps
f0100dd4:	e9 98 fb ff ff       	jmp    f0100971 <alltraps>

f0100dd9 <vector123>:
.globl vector123
vector123:
  pushl $0
f0100dd9:	6a 00                	push   $0x0
  pushl $123
f0100ddb:	6a 7b                	push   $0x7b
  jmp alltraps
f0100ddd:	e9 8f fb ff ff       	jmp    f0100971 <alltraps>

f0100de2 <vector124>:
.globl vector124
vector124:
  pushl $0
f0100de2:	6a 00                	push   $0x0
  pushl $124
f0100de4:	6a 7c                	push   $0x7c
  jmp alltraps
f0100de6:	e9 86 fb ff ff       	jmp    f0100971 <alltraps>

f0100deb <vector125>:
.globl vector125
vector125:
  pushl $0
f0100deb:	6a 00                	push   $0x0
  pushl $125
f0100ded:	6a 7d                	push   $0x7d
  jmp alltraps
f0100def:	e9 7d fb ff ff       	jmp    f0100971 <alltraps>

f0100df4 <vector126>:
.globl vector126
vector126:
  pushl $0
f0100df4:	6a 00                	push   $0x0
  pushl $126
f0100df6:	6a 7e                	push   $0x7e
  jmp alltraps
f0100df8:	e9 74 fb ff ff       	jmp    f0100971 <alltraps>

f0100dfd <vector127>:
.globl vector127
vector127:
  pushl $0
f0100dfd:	6a 00                	push   $0x0
  pushl $127
f0100dff:	6a 7f                	push   $0x7f
  jmp alltraps
f0100e01:	e9 6b fb ff ff       	jmp    f0100971 <alltraps>

f0100e06 <vector128>:
.globl vector128
vector128:
  pushl $0
f0100e06:	6a 00                	push   $0x0
  pushl $128
f0100e08:	68 80 00 00 00       	push   $0x80
  jmp alltraps
f0100e0d:	e9 5f fb ff ff       	jmp    f0100971 <alltraps>

f0100e12 <vector129>:
.globl vector129
vector129:
  pushl $0
f0100e12:	6a 00                	push   $0x0
  pushl $129
f0100e14:	68 81 00 00 00       	push   $0x81
  jmp alltraps
f0100e19:	e9 53 fb ff ff       	jmp    f0100971 <alltraps>

f0100e1e <vector130>:
.globl vector130
vector130:
  pushl $0
f0100e1e:	6a 00                	push   $0x0
  pushl $130
f0100e20:	68 82 00 00 00       	push   $0x82
  jmp alltraps
f0100e25:	e9 47 fb ff ff       	jmp    f0100971 <alltraps>

f0100e2a <vector131>:
.globl vector131
vector131:
  pushl $0
f0100e2a:	6a 00                	push   $0x0
  pushl $131
f0100e2c:	68 83 00 00 00       	push   $0x83
  jmp alltraps
f0100e31:	e9 3b fb ff ff       	jmp    f0100971 <alltraps>

f0100e36 <vector132>:
.globl vector132
vector132:
  pushl $0
f0100e36:	6a 00                	push   $0x0
  pushl $132
f0100e38:	68 84 00 00 00       	push   $0x84
  jmp alltraps
f0100e3d:	e9 2f fb ff ff       	jmp    f0100971 <alltraps>

f0100e42 <vector133>:
.globl vector133
vector133:
  pushl $0
f0100e42:	6a 00                	push   $0x0
  pushl $133
f0100e44:	68 85 00 00 00       	push   $0x85
  jmp alltraps
f0100e49:	e9 23 fb ff ff       	jmp    f0100971 <alltraps>

f0100e4e <vector134>:
.globl vector134
vector134:
  pushl $0
f0100e4e:	6a 00                	push   $0x0
  pushl $134
f0100e50:	68 86 00 00 00       	push   $0x86
  jmp alltraps
f0100e55:	e9 17 fb ff ff       	jmp    f0100971 <alltraps>

f0100e5a <vector135>:
.globl vector135
vector135:
  pushl $0
f0100e5a:	6a 00                	push   $0x0
  pushl $135
f0100e5c:	68 87 00 00 00       	push   $0x87
  jmp alltraps
f0100e61:	e9 0b fb ff ff       	jmp    f0100971 <alltraps>

f0100e66 <vector136>:
.globl vector136
vector136:
  pushl $0
f0100e66:	6a 00                	push   $0x0
  pushl $136
f0100e68:	68 88 00 00 00       	push   $0x88
  jmp alltraps
f0100e6d:	e9 ff fa ff ff       	jmp    f0100971 <alltraps>

f0100e72 <vector137>:
.globl vector137
vector137:
  pushl $0
f0100e72:	6a 00                	push   $0x0
  pushl $137
f0100e74:	68 89 00 00 00       	push   $0x89
  jmp alltraps
f0100e79:	e9 f3 fa ff ff       	jmp    f0100971 <alltraps>

f0100e7e <vector138>:
.globl vector138
vector138:
  pushl $0
f0100e7e:	6a 00                	push   $0x0
  pushl $138
f0100e80:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
f0100e85:	e9 e7 fa ff ff       	jmp    f0100971 <alltraps>

f0100e8a <vector139>:
.globl vector139
vector139:
  pushl $0
f0100e8a:	6a 00                	push   $0x0
  pushl $139
f0100e8c:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
f0100e91:	e9 db fa ff ff       	jmp    f0100971 <alltraps>

f0100e96 <vector140>:
.globl vector140
vector140:
  pushl $0
f0100e96:	6a 00                	push   $0x0
  pushl $140
f0100e98:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
f0100e9d:	e9 cf fa ff ff       	jmp    f0100971 <alltraps>

f0100ea2 <vector141>:
.globl vector141
vector141:
  pushl $0
f0100ea2:	6a 00                	push   $0x0
  pushl $141
f0100ea4:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
f0100ea9:	e9 c3 fa ff ff       	jmp    f0100971 <alltraps>

f0100eae <vector142>:
.globl vector142
vector142:
  pushl $0
f0100eae:	6a 00                	push   $0x0
  pushl $142
f0100eb0:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
f0100eb5:	e9 b7 fa ff ff       	jmp    f0100971 <alltraps>

f0100eba <vector143>:
.globl vector143
vector143:
  pushl $0
f0100eba:	6a 00                	push   $0x0
  pushl $143
f0100ebc:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
f0100ec1:	e9 ab fa ff ff       	jmp    f0100971 <alltraps>

f0100ec6 <vector144>:
.globl vector144
vector144:
  pushl $0
f0100ec6:	6a 00                	push   $0x0
  pushl $144
f0100ec8:	68 90 00 00 00       	push   $0x90
  jmp alltraps
f0100ecd:	e9 9f fa ff ff       	jmp    f0100971 <alltraps>

f0100ed2 <vector145>:
.globl vector145
vector145:
  pushl $0
f0100ed2:	6a 00                	push   $0x0
  pushl $145
f0100ed4:	68 91 00 00 00       	push   $0x91
  jmp alltraps
f0100ed9:	e9 93 fa ff ff       	jmp    f0100971 <alltraps>

f0100ede <vector146>:
.globl vector146
vector146:
  pushl $0
f0100ede:	6a 00                	push   $0x0
  pushl $146
f0100ee0:	68 92 00 00 00       	push   $0x92
  jmp alltraps
f0100ee5:	e9 87 fa ff ff       	jmp    f0100971 <alltraps>

f0100eea <vector147>:
.globl vector147
vector147:
  pushl $0
f0100eea:	6a 00                	push   $0x0
  pushl $147
f0100eec:	68 93 00 00 00       	push   $0x93
  jmp alltraps
f0100ef1:	e9 7b fa ff ff       	jmp    f0100971 <alltraps>

f0100ef6 <vector148>:
.globl vector148
vector148:
  pushl $0
f0100ef6:	6a 00                	push   $0x0
  pushl $148
f0100ef8:	68 94 00 00 00       	push   $0x94
  jmp alltraps
f0100efd:	e9 6f fa ff ff       	jmp    f0100971 <alltraps>

f0100f02 <vector149>:
.globl vector149
vector149:
  pushl $0
f0100f02:	6a 00                	push   $0x0
  pushl $149
f0100f04:	68 95 00 00 00       	push   $0x95
  jmp alltraps
f0100f09:	e9 63 fa ff ff       	jmp    f0100971 <alltraps>

f0100f0e <vector150>:
.globl vector150
vector150:
  pushl $0
f0100f0e:	6a 00                	push   $0x0
  pushl $150
f0100f10:	68 96 00 00 00       	push   $0x96
  jmp alltraps
f0100f15:	e9 57 fa ff ff       	jmp    f0100971 <alltraps>

f0100f1a <vector151>:
.globl vector151
vector151:
  pushl $0
f0100f1a:	6a 00                	push   $0x0
  pushl $151
f0100f1c:	68 97 00 00 00       	push   $0x97
  jmp alltraps
f0100f21:	e9 4b fa ff ff       	jmp    f0100971 <alltraps>

f0100f26 <vector152>:
.globl vector152
vector152:
  pushl $0
f0100f26:	6a 00                	push   $0x0
  pushl $152
f0100f28:	68 98 00 00 00       	push   $0x98
  jmp alltraps
f0100f2d:	e9 3f fa ff ff       	jmp    f0100971 <alltraps>

f0100f32 <vector153>:
.globl vector153
vector153:
  pushl $0
f0100f32:	6a 00                	push   $0x0
  pushl $153
f0100f34:	68 99 00 00 00       	push   $0x99
  jmp alltraps
f0100f39:	e9 33 fa ff ff       	jmp    f0100971 <alltraps>

f0100f3e <vector154>:
.globl vector154
vector154:
  pushl $0
f0100f3e:	6a 00                	push   $0x0
  pushl $154
f0100f40:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
f0100f45:	e9 27 fa ff ff       	jmp    f0100971 <alltraps>

f0100f4a <vector155>:
.globl vector155
vector155:
  pushl $0
f0100f4a:	6a 00                	push   $0x0
  pushl $155
f0100f4c:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
f0100f51:	e9 1b fa ff ff       	jmp    f0100971 <alltraps>

f0100f56 <vector156>:
.globl vector156
vector156:
  pushl $0
f0100f56:	6a 00                	push   $0x0
  pushl $156
f0100f58:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
f0100f5d:	e9 0f fa ff ff       	jmp    f0100971 <alltraps>

f0100f62 <vector157>:
.globl vector157
vector157:
  pushl $0
f0100f62:	6a 00                	push   $0x0
  pushl $157
f0100f64:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
f0100f69:	e9 03 fa ff ff       	jmp    f0100971 <alltraps>

f0100f6e <vector158>:
.globl vector158
vector158:
  pushl $0
f0100f6e:	6a 00                	push   $0x0
  pushl $158
f0100f70:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
f0100f75:	e9 f7 f9 ff ff       	jmp    f0100971 <alltraps>

f0100f7a <vector159>:
.globl vector159
vector159:
  pushl $0
f0100f7a:	6a 00                	push   $0x0
  pushl $159
f0100f7c:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
f0100f81:	e9 eb f9 ff ff       	jmp    f0100971 <alltraps>

f0100f86 <vector160>:
.globl vector160
vector160:
  pushl $0
f0100f86:	6a 00                	push   $0x0
  pushl $160
f0100f88:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
f0100f8d:	e9 df f9 ff ff       	jmp    f0100971 <alltraps>

f0100f92 <vector161>:
.globl vector161
vector161:
  pushl $0
f0100f92:	6a 00                	push   $0x0
  pushl $161
f0100f94:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
f0100f99:	e9 d3 f9 ff ff       	jmp    f0100971 <alltraps>

f0100f9e <vector162>:
.globl vector162
vector162:
  pushl $0
f0100f9e:	6a 00                	push   $0x0
  pushl $162
f0100fa0:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
f0100fa5:	e9 c7 f9 ff ff       	jmp    f0100971 <alltraps>

f0100faa <vector163>:
.globl vector163
vector163:
  pushl $0
f0100faa:	6a 00                	push   $0x0
  pushl $163
f0100fac:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
f0100fb1:	e9 bb f9 ff ff       	jmp    f0100971 <alltraps>

f0100fb6 <vector164>:
.globl vector164
vector164:
  pushl $0
f0100fb6:	6a 00                	push   $0x0
  pushl $164
f0100fb8:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
f0100fbd:	e9 af f9 ff ff       	jmp    f0100971 <alltraps>

f0100fc2 <vector165>:
.globl vector165
vector165:
  pushl $0
f0100fc2:	6a 00                	push   $0x0
  pushl $165
f0100fc4:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
f0100fc9:	e9 a3 f9 ff ff       	jmp    f0100971 <alltraps>

f0100fce <vector166>:
.globl vector166
vector166:
  pushl $0
f0100fce:	6a 00                	push   $0x0
  pushl $166
f0100fd0:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
f0100fd5:	e9 97 f9 ff ff       	jmp    f0100971 <alltraps>

f0100fda <vector167>:
.globl vector167
vector167:
  pushl $0
f0100fda:	6a 00                	push   $0x0
  pushl $167
f0100fdc:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
f0100fe1:	e9 8b f9 ff ff       	jmp    f0100971 <alltraps>

f0100fe6 <vector168>:
.globl vector168
vector168:
  pushl $0
f0100fe6:	6a 00                	push   $0x0
  pushl $168
f0100fe8:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
f0100fed:	e9 7f f9 ff ff       	jmp    f0100971 <alltraps>

f0100ff2 <vector169>:
.globl vector169
vector169:
  pushl $0
f0100ff2:	6a 00                	push   $0x0
  pushl $169
f0100ff4:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
f0100ff9:	e9 73 f9 ff ff       	jmp    f0100971 <alltraps>

f0100ffe <vector170>:
.globl vector170
vector170:
  pushl $0
f0100ffe:	6a 00                	push   $0x0
  pushl $170
f0101000:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
f0101005:	e9 67 f9 ff ff       	jmp    f0100971 <alltraps>

f010100a <vector171>:
.globl vector171
vector171:
  pushl $0
f010100a:	6a 00                	push   $0x0
  pushl $171
f010100c:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
f0101011:	e9 5b f9 ff ff       	jmp    f0100971 <alltraps>

f0101016 <vector172>:
.globl vector172
vector172:
  pushl $0
f0101016:	6a 00                	push   $0x0
  pushl $172
f0101018:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
f010101d:	e9 4f f9 ff ff       	jmp    f0100971 <alltraps>

f0101022 <vector173>:
.globl vector173
vector173:
  pushl $0
f0101022:	6a 00                	push   $0x0
  pushl $173
f0101024:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
f0101029:	e9 43 f9 ff ff       	jmp    f0100971 <alltraps>

f010102e <vector174>:
.globl vector174
vector174:
  pushl $0
f010102e:	6a 00                	push   $0x0
  pushl $174
f0101030:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
f0101035:	e9 37 f9 ff ff       	jmp    f0100971 <alltraps>

f010103a <vector175>:
.globl vector175
vector175:
  pushl $0
f010103a:	6a 00                	push   $0x0
  pushl $175
f010103c:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
f0101041:	e9 2b f9 ff ff       	jmp    f0100971 <alltraps>

f0101046 <vector176>:
.globl vector176
vector176:
  pushl $0
f0101046:	6a 00                	push   $0x0
  pushl $176
f0101048:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
f010104d:	e9 1f f9 ff ff       	jmp    f0100971 <alltraps>

f0101052 <vector177>:
.globl vector177
vector177:
  pushl $0
f0101052:	6a 00                	push   $0x0
  pushl $177
f0101054:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
f0101059:	e9 13 f9 ff ff       	jmp    f0100971 <alltraps>

f010105e <vector178>:
.globl vector178
vector178:
  pushl $0
f010105e:	6a 00                	push   $0x0
  pushl $178
f0101060:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
f0101065:	e9 07 f9 ff ff       	jmp    f0100971 <alltraps>

f010106a <vector179>:
.globl vector179
vector179:
  pushl $0
f010106a:	6a 00                	push   $0x0
  pushl $179
f010106c:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
f0101071:	e9 fb f8 ff ff       	jmp    f0100971 <alltraps>

f0101076 <vector180>:
.globl vector180
vector180:
  pushl $0
f0101076:	6a 00                	push   $0x0
  pushl $180
f0101078:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
f010107d:	e9 ef f8 ff ff       	jmp    f0100971 <alltraps>

f0101082 <vector181>:
.globl vector181
vector181:
  pushl $0
f0101082:	6a 00                	push   $0x0
  pushl $181
f0101084:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
f0101089:	e9 e3 f8 ff ff       	jmp    f0100971 <alltraps>

f010108e <vector182>:
.globl vector182
vector182:
  pushl $0
f010108e:	6a 00                	push   $0x0
  pushl $182
f0101090:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
f0101095:	e9 d7 f8 ff ff       	jmp    f0100971 <alltraps>

f010109a <vector183>:
.globl vector183
vector183:
  pushl $0
f010109a:	6a 00                	push   $0x0
  pushl $183
f010109c:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
f01010a1:	e9 cb f8 ff ff       	jmp    f0100971 <alltraps>

f01010a6 <vector184>:
.globl vector184
vector184:
  pushl $0
f01010a6:	6a 00                	push   $0x0
  pushl $184
f01010a8:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
f01010ad:	e9 bf f8 ff ff       	jmp    f0100971 <alltraps>

f01010b2 <vector185>:
.globl vector185
vector185:
  pushl $0
f01010b2:	6a 00                	push   $0x0
  pushl $185
f01010b4:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
f01010b9:	e9 b3 f8 ff ff       	jmp    f0100971 <alltraps>

f01010be <vector186>:
.globl vector186
vector186:
  pushl $0
f01010be:	6a 00                	push   $0x0
  pushl $186
f01010c0:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
f01010c5:	e9 a7 f8 ff ff       	jmp    f0100971 <alltraps>

f01010ca <vector187>:
.globl vector187
vector187:
  pushl $0
f01010ca:	6a 00                	push   $0x0
  pushl $187
f01010cc:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
f01010d1:	e9 9b f8 ff ff       	jmp    f0100971 <alltraps>

f01010d6 <vector188>:
.globl vector188
vector188:
  pushl $0
f01010d6:	6a 00                	push   $0x0
  pushl $188
f01010d8:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
f01010dd:	e9 8f f8 ff ff       	jmp    f0100971 <alltraps>

f01010e2 <vector189>:
.globl vector189
vector189:
  pushl $0
f01010e2:	6a 00                	push   $0x0
  pushl $189
f01010e4:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
f01010e9:	e9 83 f8 ff ff       	jmp    f0100971 <alltraps>

f01010ee <vector190>:
.globl vector190
vector190:
  pushl $0
f01010ee:	6a 00                	push   $0x0
  pushl $190
f01010f0:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
f01010f5:	e9 77 f8 ff ff       	jmp    f0100971 <alltraps>

f01010fa <vector191>:
.globl vector191
vector191:
  pushl $0
f01010fa:	6a 00                	push   $0x0
  pushl $191
f01010fc:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
f0101101:	e9 6b f8 ff ff       	jmp    f0100971 <alltraps>

f0101106 <vector192>:
.globl vector192
vector192:
  pushl $0
f0101106:	6a 00                	push   $0x0
  pushl $192
f0101108:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
f010110d:	e9 5f f8 ff ff       	jmp    f0100971 <alltraps>

f0101112 <vector193>:
.globl vector193
vector193:
  pushl $0
f0101112:	6a 00                	push   $0x0
  pushl $193
f0101114:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
f0101119:	e9 53 f8 ff ff       	jmp    f0100971 <alltraps>

f010111e <vector194>:
.globl vector194
vector194:
  pushl $0
f010111e:	6a 00                	push   $0x0
  pushl $194
f0101120:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
f0101125:	e9 47 f8 ff ff       	jmp    f0100971 <alltraps>

f010112a <vector195>:
.globl vector195
vector195:
  pushl $0
f010112a:	6a 00                	push   $0x0
  pushl $195
f010112c:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
f0101131:	e9 3b f8 ff ff       	jmp    f0100971 <alltraps>

f0101136 <vector196>:
.globl vector196
vector196:
  pushl $0
f0101136:	6a 00                	push   $0x0
  pushl $196
f0101138:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
f010113d:	e9 2f f8 ff ff       	jmp    f0100971 <alltraps>

f0101142 <vector197>:
.globl vector197
vector197:
  pushl $0
f0101142:	6a 00                	push   $0x0
  pushl $197
f0101144:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
f0101149:	e9 23 f8 ff ff       	jmp    f0100971 <alltraps>

f010114e <vector198>:
.globl vector198
vector198:
  pushl $0
f010114e:	6a 00                	push   $0x0
  pushl $198
f0101150:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
f0101155:	e9 17 f8 ff ff       	jmp    f0100971 <alltraps>

f010115a <vector199>:
.globl vector199
vector199:
  pushl $0
f010115a:	6a 00                	push   $0x0
  pushl $199
f010115c:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
f0101161:	e9 0b f8 ff ff       	jmp    f0100971 <alltraps>

f0101166 <vector200>:
.globl vector200
vector200:
  pushl $0
f0101166:	6a 00                	push   $0x0
  pushl $200
f0101168:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
f010116d:	e9 ff f7 ff ff       	jmp    f0100971 <alltraps>

f0101172 <vector201>:
.globl vector201
vector201:
  pushl $0
f0101172:	6a 00                	push   $0x0
  pushl $201
f0101174:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
f0101179:	e9 f3 f7 ff ff       	jmp    f0100971 <alltraps>

f010117e <vector202>:
.globl vector202
vector202:
  pushl $0
f010117e:	6a 00                	push   $0x0
  pushl $202
f0101180:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
f0101185:	e9 e7 f7 ff ff       	jmp    f0100971 <alltraps>

f010118a <vector203>:
.globl vector203
vector203:
  pushl $0
f010118a:	6a 00                	push   $0x0
  pushl $203
f010118c:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
f0101191:	e9 db f7 ff ff       	jmp    f0100971 <alltraps>

f0101196 <vector204>:
.globl vector204
vector204:
  pushl $0
f0101196:	6a 00                	push   $0x0
  pushl $204
f0101198:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
f010119d:	e9 cf f7 ff ff       	jmp    f0100971 <alltraps>

f01011a2 <vector205>:
.globl vector205
vector205:
  pushl $0
f01011a2:	6a 00                	push   $0x0
  pushl $205
f01011a4:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
f01011a9:	e9 c3 f7 ff ff       	jmp    f0100971 <alltraps>

f01011ae <vector206>:
.globl vector206
vector206:
  pushl $0
f01011ae:	6a 00                	push   $0x0
  pushl $206
f01011b0:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
f01011b5:	e9 b7 f7 ff ff       	jmp    f0100971 <alltraps>

f01011ba <vector207>:
.globl vector207
vector207:
  pushl $0
f01011ba:	6a 00                	push   $0x0
  pushl $207
f01011bc:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
f01011c1:	e9 ab f7 ff ff       	jmp    f0100971 <alltraps>

f01011c6 <vector208>:
.globl vector208
vector208:
  pushl $0
f01011c6:	6a 00                	push   $0x0
  pushl $208
f01011c8:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
f01011cd:	e9 9f f7 ff ff       	jmp    f0100971 <alltraps>

f01011d2 <vector209>:
.globl vector209
vector209:
  pushl $0
f01011d2:	6a 00                	push   $0x0
  pushl $209
f01011d4:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
f01011d9:	e9 93 f7 ff ff       	jmp    f0100971 <alltraps>

f01011de <vector210>:
.globl vector210
vector210:
  pushl $0
f01011de:	6a 00                	push   $0x0
  pushl $210
f01011e0:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
f01011e5:	e9 87 f7 ff ff       	jmp    f0100971 <alltraps>

f01011ea <vector211>:
.globl vector211
vector211:
  pushl $0
f01011ea:	6a 00                	push   $0x0
  pushl $211
f01011ec:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
f01011f1:	e9 7b f7 ff ff       	jmp    f0100971 <alltraps>

f01011f6 <vector212>:
.globl vector212
vector212:
  pushl $0
f01011f6:	6a 00                	push   $0x0
  pushl $212
f01011f8:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
f01011fd:	e9 6f f7 ff ff       	jmp    f0100971 <alltraps>

f0101202 <vector213>:
.globl vector213
vector213:
  pushl $0
f0101202:	6a 00                	push   $0x0
  pushl $213
f0101204:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
f0101209:	e9 63 f7 ff ff       	jmp    f0100971 <alltraps>

f010120e <vector214>:
.globl vector214
vector214:
  pushl $0
f010120e:	6a 00                	push   $0x0
  pushl $214
f0101210:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
f0101215:	e9 57 f7 ff ff       	jmp    f0100971 <alltraps>

f010121a <vector215>:
.globl vector215
vector215:
  pushl $0
f010121a:	6a 00                	push   $0x0
  pushl $215
f010121c:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
f0101221:	e9 4b f7 ff ff       	jmp    f0100971 <alltraps>

f0101226 <vector216>:
.globl vector216
vector216:
  pushl $0
f0101226:	6a 00                	push   $0x0
  pushl $216
f0101228:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
f010122d:	e9 3f f7 ff ff       	jmp    f0100971 <alltraps>

f0101232 <vector217>:
.globl vector217
vector217:
  pushl $0
f0101232:	6a 00                	push   $0x0
  pushl $217
f0101234:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
f0101239:	e9 33 f7 ff ff       	jmp    f0100971 <alltraps>

f010123e <vector218>:
.globl vector218
vector218:
  pushl $0
f010123e:	6a 00                	push   $0x0
  pushl $218
f0101240:	68 da 00 00 00       	push   $0xda
  jmp alltraps
f0101245:	e9 27 f7 ff ff       	jmp    f0100971 <alltraps>

f010124a <vector219>:
.globl vector219
vector219:
  pushl $0
f010124a:	6a 00                	push   $0x0
  pushl $219
f010124c:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
f0101251:	e9 1b f7 ff ff       	jmp    f0100971 <alltraps>

f0101256 <vector220>:
.globl vector220
vector220:
  pushl $0
f0101256:	6a 00                	push   $0x0
  pushl $220
f0101258:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
f010125d:	e9 0f f7 ff ff       	jmp    f0100971 <alltraps>

f0101262 <vector221>:
.globl vector221
vector221:
  pushl $0
f0101262:	6a 00                	push   $0x0
  pushl $221
f0101264:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
f0101269:	e9 03 f7 ff ff       	jmp    f0100971 <alltraps>

f010126e <vector222>:
.globl vector222
vector222:
  pushl $0
f010126e:	6a 00                	push   $0x0
  pushl $222
f0101270:	68 de 00 00 00       	push   $0xde
  jmp alltraps
f0101275:	e9 f7 f6 ff ff       	jmp    f0100971 <alltraps>

f010127a <vector223>:
.globl vector223
vector223:
  pushl $0
f010127a:	6a 00                	push   $0x0
  pushl $223
f010127c:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
f0101281:	e9 eb f6 ff ff       	jmp    f0100971 <alltraps>

f0101286 <vector224>:
.globl vector224
vector224:
  pushl $0
f0101286:	6a 00                	push   $0x0
  pushl $224
f0101288:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
f010128d:	e9 df f6 ff ff       	jmp    f0100971 <alltraps>

f0101292 <vector225>:
.globl vector225
vector225:
  pushl $0
f0101292:	6a 00                	push   $0x0
  pushl $225
f0101294:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
f0101299:	e9 d3 f6 ff ff       	jmp    f0100971 <alltraps>

f010129e <vector226>:
.globl vector226
vector226:
  pushl $0
f010129e:	6a 00                	push   $0x0
  pushl $226
f01012a0:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
f01012a5:	e9 c7 f6 ff ff       	jmp    f0100971 <alltraps>

f01012aa <vector227>:
.globl vector227
vector227:
  pushl $0
f01012aa:	6a 00                	push   $0x0
  pushl $227
f01012ac:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
f01012b1:	e9 bb f6 ff ff       	jmp    f0100971 <alltraps>

f01012b6 <vector228>:
.globl vector228
vector228:
  pushl $0
f01012b6:	6a 00                	push   $0x0
  pushl $228
f01012b8:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
f01012bd:	e9 af f6 ff ff       	jmp    f0100971 <alltraps>

f01012c2 <vector229>:
.globl vector229
vector229:
  pushl $0
f01012c2:	6a 00                	push   $0x0
  pushl $229
f01012c4:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
f01012c9:	e9 a3 f6 ff ff       	jmp    f0100971 <alltraps>

f01012ce <vector230>:
.globl vector230
vector230:
  pushl $0
f01012ce:	6a 00                	push   $0x0
  pushl $230
f01012d0:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
f01012d5:	e9 97 f6 ff ff       	jmp    f0100971 <alltraps>

f01012da <vector231>:
.globl vector231
vector231:
  pushl $0
f01012da:	6a 00                	push   $0x0
  pushl $231
f01012dc:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
f01012e1:	e9 8b f6 ff ff       	jmp    f0100971 <alltraps>

f01012e6 <vector232>:
.globl vector232
vector232:
  pushl $0
f01012e6:	6a 00                	push   $0x0
  pushl $232
f01012e8:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
f01012ed:	e9 7f f6 ff ff       	jmp    f0100971 <alltraps>

f01012f2 <vector233>:
.globl vector233
vector233:
  pushl $0
f01012f2:	6a 00                	push   $0x0
  pushl $233
f01012f4:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
f01012f9:	e9 73 f6 ff ff       	jmp    f0100971 <alltraps>

f01012fe <vector234>:
.globl vector234
vector234:
  pushl $0
f01012fe:	6a 00                	push   $0x0
  pushl $234
f0101300:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
f0101305:	e9 67 f6 ff ff       	jmp    f0100971 <alltraps>

f010130a <vector235>:
.globl vector235
vector235:
  pushl $0
f010130a:	6a 00                	push   $0x0
  pushl $235
f010130c:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
f0101311:	e9 5b f6 ff ff       	jmp    f0100971 <alltraps>

f0101316 <vector236>:
.globl vector236
vector236:
  pushl $0
f0101316:	6a 00                	push   $0x0
  pushl $236
f0101318:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
f010131d:	e9 4f f6 ff ff       	jmp    f0100971 <alltraps>

f0101322 <vector237>:
.globl vector237
vector237:
  pushl $0
f0101322:	6a 00                	push   $0x0
  pushl $237
f0101324:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
f0101329:	e9 43 f6 ff ff       	jmp    f0100971 <alltraps>

f010132e <vector238>:
.globl vector238
vector238:
  pushl $0
f010132e:	6a 00                	push   $0x0
  pushl $238
f0101330:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
f0101335:	e9 37 f6 ff ff       	jmp    f0100971 <alltraps>

f010133a <vector239>:
.globl vector239
vector239:
  pushl $0
f010133a:	6a 00                	push   $0x0
  pushl $239
f010133c:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
f0101341:	e9 2b f6 ff ff       	jmp    f0100971 <alltraps>

f0101346 <vector240>:
.globl vector240
vector240:
  pushl $0
f0101346:	6a 00                	push   $0x0
  pushl $240
f0101348:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
f010134d:	e9 1f f6 ff ff       	jmp    f0100971 <alltraps>

f0101352 <vector241>:
.globl vector241
vector241:
  pushl $0
f0101352:	6a 00                	push   $0x0
  pushl $241
f0101354:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
f0101359:	e9 13 f6 ff ff       	jmp    f0100971 <alltraps>

f010135e <vector242>:
.globl vector242
vector242:
  pushl $0
f010135e:	6a 00                	push   $0x0
  pushl $242
f0101360:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
f0101365:	e9 07 f6 ff ff       	jmp    f0100971 <alltraps>

f010136a <vector243>:
.globl vector243
vector243:
  pushl $0
f010136a:	6a 00                	push   $0x0
  pushl $243
f010136c:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
f0101371:	e9 fb f5 ff ff       	jmp    f0100971 <alltraps>

f0101376 <vector244>:
.globl vector244
vector244:
  pushl $0
f0101376:	6a 00                	push   $0x0
  pushl $244
f0101378:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
f010137d:	e9 ef f5 ff ff       	jmp    f0100971 <alltraps>

f0101382 <vector245>:
.globl vector245
vector245:
  pushl $0
f0101382:	6a 00                	push   $0x0
  pushl $245
f0101384:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
f0101389:	e9 e3 f5 ff ff       	jmp    f0100971 <alltraps>

f010138e <vector246>:
.globl vector246
vector246:
  pushl $0
f010138e:	6a 00                	push   $0x0
  pushl $246
f0101390:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
f0101395:	e9 d7 f5 ff ff       	jmp    f0100971 <alltraps>

f010139a <vector247>:
.globl vector247
vector247:
  pushl $0
f010139a:	6a 00                	push   $0x0
  pushl $247
f010139c:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
f01013a1:	e9 cb f5 ff ff       	jmp    f0100971 <alltraps>

f01013a6 <vector248>:
.globl vector248
vector248:
  pushl $0
f01013a6:	6a 00                	push   $0x0
  pushl $248
f01013a8:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
f01013ad:	e9 bf f5 ff ff       	jmp    f0100971 <alltraps>

f01013b2 <vector249>:
.globl vector249
vector249:
  pushl $0
f01013b2:	6a 00                	push   $0x0
  pushl $249
f01013b4:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
f01013b9:	e9 b3 f5 ff ff       	jmp    f0100971 <alltraps>

f01013be <vector250>:
.globl vector250
vector250:
  pushl $0
f01013be:	6a 00                	push   $0x0
  pushl $250
f01013c0:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
f01013c5:	e9 a7 f5 ff ff       	jmp    f0100971 <alltraps>

f01013ca <vector251>:
.globl vector251
vector251:
  pushl $0
f01013ca:	6a 00                	push   $0x0
  pushl $251
f01013cc:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
f01013d1:	e9 9b f5 ff ff       	jmp    f0100971 <alltraps>

f01013d6 <vector252>:
.globl vector252
vector252:
  pushl $0
f01013d6:	6a 00                	push   $0x0
  pushl $252
f01013d8:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
f01013dd:	e9 8f f5 ff ff       	jmp    f0100971 <alltraps>

f01013e2 <vector253>:
.globl vector253
vector253:
  pushl $0
f01013e2:	6a 00                	push   $0x0
  pushl $253
f01013e4:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
f01013e9:	e9 83 f5 ff ff       	jmp    f0100971 <alltraps>

f01013ee <vector254>:
.globl vector254
vector254:
  pushl $0
f01013ee:	6a 00                	push   $0x0
  pushl $254
f01013f0:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
f01013f5:	e9 77 f5 ff ff       	jmp    f0100971 <alltraps>

f01013fa <vector255>:
.globl vector255
vector255:
  pushl $0
f01013fa:	6a 00                	push   $0x0
  pushl $255
f01013fc:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
f0101401:	e9 6b f5 ff ff       	jmp    f0100971 <alltraps>

f0101406 <seg_init>:
// GDT.
struct segdesc gdt[NSEGS];

void
seg_init(void)
{
f0101406:	55                   	push   %ebp
f0101407:	89 e5                	mov    %esp,%ebp
f0101409:	83 ec 18             	sub    $0x18,%esp
	// Cannot share a CODE descriptor for both kernel and user
	// because it would have to have DPL_USR, but the CPU forbids
	// an interrupt from CPL=0 to DPL=3.
	// Your code here.
	//
	thiscpu->gdt[SEG_KCODE] = SEG(STA_R | STA_X, 0, 0xffffffff, 0);
f010140c:	e8 b3 13 00 00       	call   f01027c4 <cpunum>
f0101411:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f0101417:	8d 90 20 70 12 f0    	lea    -0xfed8fe0(%eax),%edx
f010141d:	66 c7 80 9c 70 12 f0 	movw   $0xffff,-0xfed8f64(%eax)
f0101424:	ff ff 
f0101426:	66 c7 80 9e 70 12 f0 	movw   $0x0,-0xfed8f62(%eax)
f010142d:	00 00 
f010142f:	c6 80 a0 70 12 f0 00 	movb   $0x0,-0xfed8f60(%eax)
f0101436:	c6 80 a1 70 12 f0 9a 	movb   $0x9a,-0xfed8f5f(%eax)
f010143d:	c6 80 a2 70 12 f0 cf 	movb   $0xcf,-0xfed8f5e(%eax)
f0101444:	c6 82 83 00 00 00 00 	movb   $0x0,0x83(%edx)
	thiscpu->gdt[SEG_KDATA] = SEG(STA_W | STA_R, 0, 0xffffffff, 0);
f010144b:	e8 74 13 00 00       	call   f01027c4 <cpunum>
f0101450:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f0101456:	8d 90 20 70 12 f0    	lea    -0xfed8fe0(%eax),%edx
f010145c:	66 c7 80 a4 70 12 f0 	movw   $0xffff,-0xfed8f5c(%eax)
f0101463:	ff ff 
f0101465:	66 c7 80 a6 70 12 f0 	movw   $0x0,-0xfed8f5a(%eax)
f010146c:	00 00 
f010146e:	c6 80 a8 70 12 f0 00 	movb   $0x0,-0xfed8f58(%eax)
f0101475:	c6 80 a9 70 12 f0 92 	movb   $0x92,-0xfed8f57(%eax)
f010147c:	c6 80 aa 70 12 f0 cf 	movb   $0xcf,-0xfed8f56(%eax)
f0101483:	c6 82 8b 00 00 00 00 	movb   $0x0,0x8b(%edx)
	thiscpu->gdt[SEG_UCODE] = SEG(STA_R | STA_X, 0, 0xffffffff, DPL_USER);
f010148a:	e8 35 13 00 00       	call   f01027c4 <cpunum>
f010148f:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f0101495:	8d 90 20 70 12 f0    	lea    -0xfed8fe0(%eax),%edx
f010149b:	66 c7 80 ac 70 12 f0 	movw   $0xffff,-0xfed8f54(%eax)
f01014a2:	ff ff 
f01014a4:	66 c7 80 ae 70 12 f0 	movw   $0x0,-0xfed8f52(%eax)
f01014ab:	00 00 
f01014ad:	c6 80 b0 70 12 f0 00 	movb   $0x0,-0xfed8f50(%eax)
f01014b4:	c6 80 b1 70 12 f0 fa 	movb   $0xfa,-0xfed8f4f(%eax)
f01014bb:	c6 80 b2 70 12 f0 cf 	movb   $0xcf,-0xfed8f4e(%eax)
f01014c2:	c6 82 93 00 00 00 00 	movb   $0x0,0x93(%edx)
	thiscpu->gdt[SEG_UDATA] = SEG(STA_R | STA_W, 0, 0xffffffff, DPL_USER);
f01014c9:	e8 f6 12 00 00       	call   f01027c4 <cpunum>
f01014ce:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f01014d4:	8d 90 20 70 12 f0    	lea    -0xfed8fe0(%eax),%edx
f01014da:	66 c7 80 b4 70 12 f0 	movw   $0xffff,-0xfed8f4c(%eax)
f01014e1:	ff ff 
f01014e3:	66 c7 80 b6 70 12 f0 	movw   $0x0,-0xfed8f4a(%eax)
f01014ea:	00 00 
f01014ec:	c6 80 b8 70 12 f0 00 	movb   $0x0,-0xfed8f48(%eax)
f01014f3:	c6 80 b9 70 12 f0 f2 	movb   $0xf2,-0xfed8f47(%eax)
f01014fa:	c6 80 ba 70 12 f0 cf 	movb   $0xcf,-0xfed8f46(%eax)
f0101501:	c6 82 9b 00 00 00 00 	movb   $0x0,0x9b(%edx)
	lgdt(thiscpu->gdt, sizeof(thiscpu->gdt));
f0101508:	e8 b7 12 00 00       	call   f01027c4 <cpunum>
f010150d:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f0101513:	05 94 70 12 f0       	add    $0xf0127094,%eax
	pd[0] = size-1;
f0101518:	66 c7 45 f2 2f 00    	movw   $0x2f,-0xe(%ebp)
	pd[1] = (unsigned)p;
f010151e:	66 89 45 f4          	mov    %ax,-0xc(%ebp)
	pd[2] = (unsigned)p >> 16;
f0101522:	c1 e8 10             	shr    $0x10,%eax
f0101525:	66 89 45 f6          	mov    %ax,-0xa(%ebp)
	asm volatile("lgdt (%0)" : : "r" (pd));
f0101529:	8d 45 f2             	lea    -0xe(%ebp),%eax
f010152c:	0f 01 10             	lgdtl  (%eax)
	// user code, user data;
	// 2. The various segment selectors, application segment type bits and
	// User DPL have been defined in inc/mmu.h;
	// 3. You may need macro SEG() to set up segments;
	// 4. We have implememted the C function lgdt() in inc/x86.h;
}
f010152f:	c9                   	leave  
f0101530:	c3                   	ret    

f0101531 <pgdir_walk>:
// Hint 2: look at inc/mmu.h for useful macros that manipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int32_t alloc)
{
f0101531:	55                   	push   %ebp
f0101532:	89 e5                	mov    %esp,%ebp
f0101534:	57                   	push   %edi
f0101535:	56                   	push   %esi
f0101536:	53                   	push   %ebx
f0101537:	83 ec 0c             	sub    $0xc,%esp
f010153a:	8b 75 0c             	mov    0xc(%ebp),%esi
	// TODO: Fill this function in
	pde_t *pde = &pgdir[PDX(va)];
f010153d:	89 f7                	mov    %esi,%edi
f010153f:	c1 ef 16             	shr    $0x16,%edi
f0101542:	c1 e7 02             	shl    $0x2,%edi
f0101545:	03 7d 08             	add    0x8(%ebp),%edi
	pte_t *pgtab;
	if ((*pde & PTE_P) == 1)
f0101548:	8b 1f                	mov    (%edi),%ebx
f010154a:	f6 c3 01             	test   $0x1,%bl
f010154d:	74 21                	je     f0101570 <pgdir_walk+0x3f>
	    pgtab = (pte_t *)P2V(PTE_ADDR(*pde));
f010154f:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
f0101555:	81 eb 00 00 00 10    	sub    $0x10000000,%ebx
	    if (alloc == 0 || (pgtab = (pte_t *)kalloc()) == NULL)
	        return NULL;
	    memset(pgtab, 0, PGSIZE);
        *pde = V2P(pgtab) | PTE_P | PTE_U | PTE_W;
	}
	return &pgtab[PTX(va)];
f010155b:	c1 ee 0a             	shr    $0xa,%esi
f010155e:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f0101564:	01 f3                	add    %esi,%ebx
}
f0101566:	89 d8                	mov    %ebx,%eax
f0101568:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010156b:	5b                   	pop    %ebx
f010156c:	5e                   	pop    %esi
f010156d:	5f                   	pop    %edi
f010156e:	5d                   	pop    %ebp
f010156f:	c3                   	ret    
	    if (alloc == 0 || (pgtab = (pte_t *)kalloc()) == NULL)
f0101570:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101574:	74 2b                	je     f01015a1 <pgdir_walk+0x70>
f0101576:	e8 04 0c 00 00       	call   f010217f <kalloc>
f010157b:	89 c3                	mov    %eax,%ebx
f010157d:	85 c0                	test   %eax,%eax
f010157f:	74 e5                	je     f0101566 <pgdir_walk+0x35>
	    memset(pgtab, 0, PGSIZE);
f0101581:	83 ec 04             	sub    $0x4,%esp
f0101584:	68 00 10 00 00       	push   $0x1000
f0101589:	6a 00                	push   $0x0
f010158b:	50                   	push   %eax
f010158c:	e8 b4 2c 00 00       	call   f0104245 <memset>
        *pde = V2P(pgtab) | PTE_P | PTE_U | PTE_W;
f0101591:	8d 83 00 00 00 10    	lea    0x10000000(%ebx),%eax
f0101597:	83 c8 07             	or     $0x7,%eax
f010159a:	89 07                	mov    %eax,(%edi)
f010159c:	83 c4 10             	add    $0x10,%esp
f010159f:	eb ba                	jmp    f010155b <pgdir_walk+0x2a>
	        return NULL;
f01015a1:	bb 00 00 00 00       	mov    $0x0,%ebx
f01015a6:	eb be                	jmp    f0101566 <pgdir_walk+0x35>

f01015a8 <map_region>:
// Use permission bits perm|PTE_P for the entries.
//
// Hint: the TA solution uses pgdir_walk
static int // What to return?
map_region(pde_t *pgdir, void *va, uint32_t size, uint32_t pa, int32_t perm)
{
f01015a8:	55                   	push   %ebp
f01015a9:	89 e5                	mov    %esp,%ebp
f01015ab:	57                   	push   %edi
f01015ac:	56                   	push   %esi
f01015ad:	53                   	push   %ebx
f01015ae:	83 ec 1c             	sub    $0x1c,%esp
f01015b1:	89 c7                	mov    %eax,%edi
f01015b3:	8b 45 08             	mov    0x8(%ebp),%eax
	// TODO: Fill this function in
	char *align = ROUNDUP(va, PGSIZE);
f01015b6:	8d b2 ff 0f 00 00    	lea    0xfff(%edx),%esi
f01015bc:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	uint32_t alignsize = ROUNDUP(size, PGSIZE);
f01015c2:	81 c1 ff 0f 00 00    	add    $0xfff,%ecx
f01015c8:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f01015ce:	01 c1                	add    %eax,%ecx
f01015d0:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	while (alignsize) {
f01015d3:	89 c3                	mov    %eax,%ebx
f01015d5:	29 c6                	sub    %eax,%esi
		pte_t *pte = pgdir_walk(pgdir, align, 1);
		if (pte == NULL)
			return -1;
		*pte = pa | perm | PTE_P;
f01015d7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01015da:	83 c8 01             	or     $0x1,%eax
f01015dd:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01015e0:	8d 04 1e             	lea    (%esi,%ebx,1),%eax
	while (alignsize) {
f01015e3:	39 5d e4             	cmp    %ebx,-0x1c(%ebp)
f01015e6:	74 22                	je     f010160a <map_region+0x62>
		pte_t *pte = pgdir_walk(pgdir, align, 1);
f01015e8:	83 ec 04             	sub    $0x4,%esp
f01015eb:	6a 01                	push   $0x1
f01015ed:	50                   	push   %eax
f01015ee:	57                   	push   %edi
f01015ef:	e8 3d ff ff ff       	call   f0101531 <pgdir_walk>
		if (pte == NULL)
f01015f4:	83 c4 10             	add    $0x10,%esp
f01015f7:	85 c0                	test   %eax,%eax
f01015f9:	74 1c                	je     f0101617 <map_region+0x6f>
		*pte = pa | perm | PTE_P;
f01015fb:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01015fe:	09 da                	or     %ebx,%edx
f0101600:	89 10                	mov    %edx,(%eax)
		alignsize -= PGSIZE;
		pa += PGSIZE;
f0101602:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0101608:	eb d6                	jmp    f01015e0 <map_region+0x38>
		align += PGSIZE;
	} 
	return 0;
f010160a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010160f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101612:	5b                   	pop    %ebx
f0101613:	5e                   	pop    %esi
f0101614:	5f                   	pop    %edi
f0101615:	5d                   	pop    %ebp
f0101616:	c3                   	ret    
			return -1;
f0101617:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010161c:	eb f1                	jmp    f010160f <map_region+0x67>

f010161e <loaduvm>:

int
loaduvm(pde_t *pgdir, char *addr, struct Proghdr *ph, char *binary)
{
f010161e:	55                   	push   %ebp
f010161f:	89 e5                	mov    %esp,%ebp
f0101621:	57                   	push   %edi
f0101622:	56                   	push   %esi
f0101623:	53                   	push   %ebx
f0101624:	83 ec 20             	sub    $0x20,%esp
f0101627:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010162a:	8b 45 10             	mov    0x10(%ebp),%eax
	pte_t *pte;
	void *dst;
	void *src = ph->p_offset + (void *)binary;
f010162d:	8b 70 04             	mov    0x4(%eax),%esi
f0101630:	03 75 14             	add    0x14(%ebp),%esi
	uint32_t sz = ph->p_filesz;
f0101633:	8b 78 10             	mov    0x10(%eax),%edi
f0101636:	89 7d e0             	mov    %edi,-0x20(%ebp)
	if ((pte = pgdir_walk(pgdir, addr, 0)) == 0)
f0101639:	6a 00                	push   $0x0
f010163b:	53                   	push   %ebx
f010163c:	ff 75 08             	pushl  0x8(%ebp)
f010163f:	e8 ed fe ff ff       	call   f0101531 <pgdir_walk>
f0101644:	83 c4 10             	add    $0x10,%esp
f0101647:	85 c0                	test   %eax,%eax
f0101649:	0f 84 9f 00 00 00    	je     f01016ee <loaduvm+0xd0>
		return -1;
	dst = P2V(PTE_ADDR(*pte));
f010164f:	8b 10                	mov    (%eax),%edx
f0101651:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	
	uint32_t offset = (uint32_t)addr & 0xFFF;
f0101657:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f010165a:	89 d8                	mov    %ebx,%eax
f010165c:	25 ff 0f 00 00       	and    $0xfff,%eax
	dst += offset;
	uint32_t n = PGSIZE - offset;
f0101661:	bb 00 10 00 00       	mov    $0x1000,%ebx
f0101666:	29 c3                	sub    %eax,%ebx
	memmove(dst, src, n);
f0101668:	83 ec 04             	sub    $0x4,%esp
f010166b:	53                   	push   %ebx
f010166c:	56                   	push   %esi
	dst += offset;
f010166d:	8d 84 10 00 00 00 f0 	lea    -0x10000000(%eax,%edx,1),%eax
	memmove(dst, src, n);
f0101674:	50                   	push   %eax
f0101675:	e8 18 2c 00 00       	call   f0104292 <memmove>
	src += n;
f010167a:	8d 04 1e             	lea    (%esi,%ebx,1),%eax
f010167d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101680:	89 fe                	mov    %edi,%esi
f0101682:	29 de                	sub    %ebx,%esi
	for (uint32_t i = n; i < sz; i += PGSIZE) {
f0101684:	83 c4 10             	add    $0x10,%esp
f0101687:	3b 5d e0             	cmp    -0x20(%ebp),%ebx
f010168a:	73 55                	jae    f01016e1 <loaduvm+0xc3>
		if ((pte = pgdir_walk(pgdir, addr + i, 0)) == 0)
f010168c:	83 ec 04             	sub    $0x4,%esp
f010168f:	6a 00                	push   $0x0
f0101691:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101694:	01 d8                	add    %ebx,%eax
f0101696:	50                   	push   %eax
f0101697:	ff 75 08             	pushl  0x8(%ebp)
f010169a:	e8 92 fe ff ff       	call   f0101531 <pgdir_walk>
f010169f:	83 c4 10             	add    $0x10,%esp
f01016a2:	85 c0                	test   %eax,%eax
f01016a4:	74 4f                	je     f01016f5 <loaduvm+0xd7>
			return -1;
		dst = P2V(PTE_ADDR(*pte));
f01016a6:	8b 00                	mov    (%eax),%eax
f01016a8:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01016ad:	2d 00 00 00 10       	sub    $0x10000000,%eax
		if (sz - i < PGSIZE)
			n = sz - i;
f01016b2:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
f01016b8:	bf 00 10 00 00       	mov    $0x1000,%edi
f01016bd:	0f 46 fe             	cmovbe %esi,%edi
		else 
			n = PGSIZE;
		memmove(dst, src, n);
f01016c0:	83 ec 04             	sub    $0x4,%esp
f01016c3:	57                   	push   %edi
f01016c4:	ff 75 e4             	pushl  -0x1c(%ebp)
f01016c7:	50                   	push   %eax
f01016c8:	e8 c5 2b 00 00       	call   f0104292 <memmove>
		src += n;
f01016cd:	01 7d e4             	add    %edi,-0x1c(%ebp)
	for (uint32_t i = n; i < sz; i += PGSIZE) {
f01016d0:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01016d6:	81 ee 00 10 00 00    	sub    $0x1000,%esi
f01016dc:	83 c4 10             	add    $0x10,%esp
f01016df:	eb a6                	jmp    f0101687 <loaduvm+0x69>
	}
	return 0;
f01016e1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01016e6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01016e9:	5b                   	pop    %ebx
f01016ea:	5e                   	pop    %esi
f01016eb:	5f                   	pop    %edi
f01016ec:	5d                   	pop    %ebp
f01016ed:	c3                   	ret    
		return -1;
f01016ee:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01016f3:	eb f1                	jmp    f01016e6 <loaduvm+0xc8>
			return -1;
f01016f5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01016fa:	eb ea                	jmp    f01016e6 <loaduvm+0xc8>

f01016fc <kvm_init>:
//			for each item of kmap[];
//
// Hint: You may need ARRAY_SIZE.
pde_t *
kvm_init(void)
{
f01016fc:	55                   	push   %ebp
f01016fd:	89 e5                	mov    %esp,%ebp
f01016ff:	57                   	push   %edi
f0101700:	56                   	push   %esi
f0101701:	53                   	push   %ebx
f0101702:	83 ec 0c             	sub    $0xc,%esp
	// TODO: your code here
	pde_t *pgdirinit = (pde_t *)kalloc();
f0101705:	e8 75 0a 00 00       	call   f010217f <kalloc>
f010170a:	89 c6                	mov    %eax,%esi
	if (pgdirinit) {
f010170c:	85 c0                	test   %eax,%eax
f010170e:	74 43                	je     f0101753 <kvm_init+0x57>
	    memset(pgdirinit, 0, PGSIZE);
f0101710:	83 ec 04             	sub    $0x4,%esp
f0101713:	68 00 10 00 00       	push   $0x1000
f0101718:	6a 00                	push   $0x0
f010171a:	50                   	push   %eax
f010171b:	e8 25 2b 00 00       	call   f0104245 <memset>
f0101720:	bb a0 4a 10 f0       	mov    $0xf0104aa0,%ebx
f0101725:	bf e0 4a 10 f0       	mov    $0xf0104ae0,%edi
f010172a:	83 c4 10             	add    $0x10,%esp
		for (int i = 0; i < ARRAY_SIZE(kmap); i++)
			if (map_region(pgdirinit, kmap[i].virt, kmap[i].phys_end - kmap[i].phys_start, kmap[i].phys_start, kmap[i].perm) < 0) {
f010172d:	8b 43 04             	mov    0x4(%ebx),%eax
f0101730:	8b 4b 08             	mov    0x8(%ebx),%ecx
f0101733:	29 c1                	sub    %eax,%ecx
f0101735:	83 ec 08             	sub    $0x8,%esp
f0101738:	ff 73 0c             	pushl  0xc(%ebx)
f010173b:	50                   	push   %eax
f010173c:	8b 13                	mov    (%ebx),%edx
f010173e:	89 f0                	mov    %esi,%eax
f0101740:	e8 63 fe ff ff       	call   f01015a8 <map_region>
f0101745:	83 c4 10             	add    $0x10,%esp
f0101748:	85 c0                	test   %eax,%eax
f010174a:	78 11                	js     f010175d <kvm_init+0x61>
f010174c:	83 c3 10             	add    $0x10,%ebx
		for (int i = 0; i < ARRAY_SIZE(kmap); i++)
f010174f:	39 fb                	cmp    %edi,%ebx
f0101751:	75 da                	jne    f010172d <kvm_init+0x31>
                return 0;
			}
		return pgdirinit;
	} else
		return 0;
}
f0101753:	89 f0                	mov    %esi,%eax
f0101755:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101758:	5b                   	pop    %ebx
f0101759:	5e                   	pop    %esi
f010175a:	5f                   	pop    %edi
f010175b:	5d                   	pop    %ebp
f010175c:	c3                   	ret    
				kfree((char *)pgdirinit);
f010175d:	83 ec 0c             	sub    $0xc,%esp
f0101760:	56                   	push   %esi
f0101761:	e8 61 07 00 00       	call   f0101ec7 <kfree>
                return 0;
f0101766:	83 c4 10             	add    $0x10,%esp
f0101769:	be 00 00 00 00       	mov    $0x0,%esi
f010176e:	eb e3                	jmp    f0101753 <kvm_init+0x57>

f0101770 <kvm_switch>:

// Switch h/w page table register to the kernel-only page table.
void
kvm_switch(void)
{
f0101770:	55                   	push   %ebp
f0101771:	89 e5                	mov    %esp,%ebp
	lcr3(V2P(kpgdir)); // switch to the kernel page table
f0101773:	a1 f0 6e 12 f0       	mov    0xf0126ef0,%eax
f0101778:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f010177d:	0f 22 d8             	mov    %eax,%cr3
}
f0101780:	5d                   	pop    %ebp
f0101781:	c3                   	ret    

f0101782 <check_vm>:

void
check_vm(pde_t *pgdir)
{
f0101782:	55                   	push   %ebp
f0101783:	89 e5                	mov    %esp,%ebp
f0101785:	57                   	push   %edi
f0101786:	56                   	push   %esi
f0101787:	53                   	push   %ebx
f0101788:	83 ec 1c             	sub    $0x1c,%esp
f010178b:	c7 45 e0 a0 4a 10 f0 	movl   $0xf0104aa0,-0x20(%ebp)
f0101792:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101795:	eb 3e                	jmp    f01017d5 <check_vm+0x53>
		uint32_t alignsize = ROUNDUP(kmap[i].phys_end - kmap[i].phys_start, PGSIZE);
		uint32_t pa = kmap[i].phys_start;
		while(alignsize) {
			pte_t *pte = pgdir_walk(pgdir, align, 1);
			if (pte == NULL) 
				panic("vm_fail: Do not find the page table entry");
f0101797:	83 ec 04             	sub    $0x4,%esp
f010179a:	68 f0 49 10 f0       	push   $0xf01049f0
f010179f:	68 cd 00 00 00       	push   $0xcd
f01017a4:	68 1a 4a 10 f0       	push   $0xf0104a1a
f01017a9:	e8 ea e9 ff ff       	call   f0100198 <_panic>
			pte_t tmp = (*pte >> 12) << 12;
			assert(tmp == pa);
f01017ae:	68 24 4a 10 f0       	push   $0xf0104a24
f01017b3:	68 2e 4a 10 f0       	push   $0xf0104a2e
f01017b8:	68 cf 00 00 00       	push   $0xcf
f01017bd:	68 1a 4a 10 f0       	push   $0xf0104a1a
f01017c2:	e8 d1 e9 ff ff       	call   f0100198 <_panic>
f01017c7:	83 45 e0 10          	addl   $0x10,-0x20(%ebp)
f01017cb:	8b 45 e0             	mov    -0x20(%ebp),%eax
	for (int i = 0; i < ARRAY_SIZE(kmap); i++) {
f01017ce:	3d e0 4a 10 f0       	cmp    $0xf0104ae0,%eax
f01017d3:	74 5e                	je     f0101833 <check_vm+0xb1>
		char *align = ROUNDUP(kmap[i].virt, PGSIZE);
f01017d5:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01017d8:	8b 10                	mov    (%eax),%edx
f01017da:	8d b2 ff 0f 00 00    	lea    0xfff(%edx),%esi
f01017e0:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
		uint32_t alignsize = ROUNDUP(kmap[i].phys_end - kmap[i].phys_start, PGSIZE);
f01017e6:	8b 50 04             	mov    0x4(%eax),%edx
f01017e9:	8b 40 08             	mov    0x8(%eax),%eax
f01017ec:	05 ff 0f 00 00       	add    $0xfff,%eax
f01017f1:	29 d0                	sub    %edx,%eax
f01017f3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01017f8:	01 d0                	add    %edx,%eax
f01017fa:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		uint32_t pa = kmap[i].phys_start;
f01017fd:	89 d3                	mov    %edx,%ebx
f01017ff:	29 d6                	sub    %edx,%esi
f0101801:	8d 04 1e             	lea    (%esi,%ebx,1),%eax
		while(alignsize) {
f0101804:	39 5d e4             	cmp    %ebx,-0x1c(%ebp)
f0101807:	74 be                	je     f01017c7 <check_vm+0x45>
			pte_t *pte = pgdir_walk(pgdir, align, 1);
f0101809:	83 ec 04             	sub    $0x4,%esp
f010180c:	6a 01                	push   $0x1
f010180e:	50                   	push   %eax
f010180f:	57                   	push   %edi
f0101810:	e8 1c fd ff ff       	call   f0101531 <pgdir_walk>
			if (pte == NULL) 
f0101815:	83 c4 10             	add    $0x10,%esp
f0101818:	85 c0                	test   %eax,%eax
f010181a:	0f 84 77 ff ff ff    	je     f0101797 <check_vm+0x15>
			pte_t tmp = (*pte >> 12) << 12;
f0101820:	8b 00                	mov    (%eax),%eax
f0101822:	25 00 f0 ff ff       	and    $0xfffff000,%eax
			assert(tmp == pa);
f0101827:	39 c3                	cmp    %eax,%ebx
f0101829:	75 83                	jne    f01017ae <check_vm+0x2c>
			align += PGSIZE;
			pa += PGSIZE;
f010182b:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0101831:	eb ce                	jmp    f0101801 <check_vm+0x7f>
			alignsize -= PGSIZE;
		}
	}
}
f0101833:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101836:	5b                   	pop    %ebx
f0101837:	5e                   	pop    %esi
f0101838:	5f                   	pop    %edi
f0101839:	5d                   	pop    %ebp
f010183a:	c3                   	ret    

f010183b <vm_init>:

// Allocate one page table for the machine for the kernel address
// space.
void
vm_init(void)
{
f010183b:	55                   	push   %ebp
f010183c:	89 e5                	mov    %esp,%ebp
f010183e:	83 ec 08             	sub    $0x8,%esp
	kpgdir = kvm_init();
f0101841:	e8 b6 fe ff ff       	call   f01016fc <kvm_init>
f0101846:	a3 f0 6e 12 f0       	mov    %eax,0xf0126ef0
	if (kpgdir == 0)
f010184b:	85 c0                	test   %eax,%eax
f010184d:	74 13                	je     f0101862 <vm_init+0x27>
		panic("vm_init: failure");
	check_vm(kpgdir);
f010184f:	83 ec 0c             	sub    $0xc,%esp
f0101852:	50                   	push   %eax
f0101853:	e8 2a ff ff ff       	call   f0101782 <check_vm>
	kvm_switch();
f0101858:	e8 13 ff ff ff       	call   f0101770 <kvm_switch>
}
f010185d:	83 c4 10             	add    $0x10,%esp
f0101860:	c9                   	leave  
f0101861:	c3                   	ret    
		panic("vm_init: failure");
f0101862:	83 ec 04             	sub    $0x4,%esp
f0101865:	68 43 4a 10 f0       	push   $0xf0104a43
f010186a:	68 de 00 00 00       	push   $0xde
f010186f:	68 1a 4a 10 f0       	push   $0xf0104a1a
f0101874:	e8 1f e9 ff ff       	call   f0100198 <_panic>

f0101879 <reclaim_uvm>:

void
reclaim_uvm(pde_t *pgdir)
{
f0101879:	55                   	push   %ebp
f010187a:	89 e5                	mov    %esp,%ebp
f010187c:	56                   	push   %esi
f010187d:	53                   	push   %ebx
f010187e:	8b 75 08             	mov    0x8(%ebp),%esi
	uint32_t pa;
	pte_t *pte;
	char *page;
	for (uint32_t i = 0; i < USTACKTOP; i += PGSIZE) {
f0101881:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101886:	eb 1f                	jmp    f01018a7 <reclaim_uvm+0x2e>
			continue;
		if (*pte & PTE_P) {
			pa = PTE_ADDR(*pte);
			if (pa == 0)
				panic("reclaim");
			kfree(P2V(pa));
f0101888:	83 ec 0c             	sub    $0xc,%esp
f010188b:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101890:	50                   	push   %eax
f0101891:	e8 31 06 00 00       	call   f0101ec7 <kfree>
f0101896:	83 c4 10             	add    $0x10,%esp
	for (uint32_t i = 0; i < USTACKTOP; i += PGSIZE) {
f0101899:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010189f:	81 fb 00 00 00 d0    	cmp    $0xd0000000,%ebx
f01018a5:	74 37                	je     f01018de <reclaim_uvm+0x65>
		if ((pte = pgdir_walk(pgdir, (void *)i, 0)) == NULL)
f01018a7:	83 ec 04             	sub    $0x4,%esp
f01018aa:	6a 00                	push   $0x0
f01018ac:	53                   	push   %ebx
f01018ad:	56                   	push   %esi
f01018ae:	e8 7e fc ff ff       	call   f0101531 <pgdir_walk>
f01018b3:	83 c4 10             	add    $0x10,%esp
f01018b6:	85 c0                	test   %eax,%eax
f01018b8:	74 df                	je     f0101899 <reclaim_uvm+0x20>
		if (*pte & PTE_P) {
f01018ba:	8b 00                	mov    (%eax),%eax
f01018bc:	a8 01                	test   $0x1,%al
f01018be:	74 d9                	je     f0101899 <reclaim_uvm+0x20>
			if (pa == 0)
f01018c0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01018c5:	75 c1                	jne    f0101888 <reclaim_uvm+0xf>
				panic("reclaim");
f01018c7:	83 ec 04             	sub    $0x4,%esp
f01018ca:	68 54 4a 10 f0       	push   $0xf0104a54
f01018cf:	68 ef 00 00 00       	push   $0xef
f01018d4:	68 1a 4a 10 f0       	push   $0xf0104a1a
f01018d9:	e8 ba e8 ff ff       	call   f0100198 <_panic>
		}
	}
}
f01018de:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01018e1:	5b                   	pop    %ebx
f01018e2:	5e                   	pop    %esi
f01018e3:	5d                   	pop    %ebp
f01018e4:	c3                   	ret    

f01018e5 <vm_free>:
// Free a page table.
//
// Hint: You need to free all existing PTEs for this pgdir.
void
vm_free(pde_t *pgdir)
{
f01018e5:	55                   	push   %ebp
f01018e6:	89 e5                	mov    %esp,%ebp
f01018e8:	57                   	push   %edi
f01018e9:	56                   	push   %esi
f01018ea:	53                   	push   %ebx
f01018eb:	83 ec 18             	sub    $0x18,%esp
f01018ee:	8b 7d 08             	mov    0x8(%ebp),%edi
	// TODO: your code here
	reclaim_uvm(pgdir);
f01018f1:	57                   	push   %edi
f01018f2:	e8 82 ff ff ff       	call   f0101879 <reclaim_uvm>
f01018f7:	89 fb                	mov    %edi,%ebx
f01018f9:	8d b7 00 10 00 00    	lea    0x1000(%edi),%esi
f01018ff:	83 c4 10             	add    $0x10,%esp
f0101902:	eb 07                	jmp    f010190b <vm_free+0x26>
f0101904:	83 c3 04             	add    $0x4,%ebx
	for (int i = 0; i < 1024; i++)
f0101907:	39 f3                	cmp    %esi,%ebx
f0101909:	74 1e                	je     f0101929 <vm_free+0x44>
	    if (pgdir[i] & PTE_P) {
f010190b:	8b 03                	mov    (%ebx),%eax
f010190d:	a8 01                	test   $0x1,%al
f010190f:	74 f3                	je     f0101904 <vm_free+0x1f>
	        char *v = P2V((pgdir[i] >> 12) << 12);
	        kfree(v);
f0101911:	83 ec 0c             	sub    $0xc,%esp
	        char *v = P2V((pgdir[i] >> 12) << 12);
f0101914:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0101919:	2d 00 00 00 10       	sub    $0x10000000,%eax
	        kfree(v);
f010191e:	50                   	push   %eax
f010191f:	e8 a3 05 00 00       	call   f0101ec7 <kfree>
f0101924:	83 c4 10             	add    $0x10,%esp
f0101927:	eb db                	jmp    f0101904 <vm_free+0x1f>
	    }
	kfree((char *)pgdir);
f0101929:	83 ec 0c             	sub    $0xc,%esp
f010192c:	57                   	push   %edi
f010192d:	e8 95 05 00 00       	call   f0101ec7 <kfree>
}
f0101932:	83 c4 10             	add    $0x10,%esp
f0101935:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101938:	5b                   	pop    %ebx
f0101939:	5e                   	pop    %esi
f010193a:	5f                   	pop    %edi
f010193b:	5d                   	pop    %ebp
f010193c:	c3                   	ret    

f010193d <copyuvm>:

// Copy parent process's page table to its children
pde_t *
copyuvm(pde_t *pgdir)
{
f010193d:	55                   	push   %ebp
f010193e:	89 e5                	mov    %esp,%ebp
f0101940:	57                   	push   %edi
f0101941:	56                   	push   %esi
f0101942:	53                   	push   %ebx
f0101943:	83 ec 1c             	sub    $0x1c,%esp
f0101946:	8b 7d 08             	mov    0x8(%ebp),%edi
	pde_t *child_pgdir;
	pte_t *pte;
	uint32_t pa, flags;
	char *page;
	if ((child_pgdir = kvm_init()) == 0)
f0101949:	e8 ae fd ff ff       	call   f01016fc <kvm_init>
f010194e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101951:	85 c0                	test   %eax,%eax
f0101953:	74 1c                	je     f0101971 <copyuvm+0x34>
		return NULL;
	for (uint32_t i = 0; i < USTACKTOP; i += PGSIZE) {
f0101955:	be 00 00 00 00       	mov    $0x0,%esi
f010195a:	eb 2e                	jmp    f010198a <copyuvm+0x4d>
			continue;
		if (*pte & PTE_P) {
			pa = PTE_ADDR(*pte);
			flags = PTE_FLAGS(*pte);
			if ((page = kalloc()) == NULL) {
				vm_free(child_pgdir);
f010195c:	83 ec 0c             	sub    $0xc,%esp
f010195f:	ff 75 d8             	pushl  -0x28(%ebp)
f0101962:	e8 7e ff ff ff       	call   f01018e5 <vm_free>
				return NULL;
f0101967:	83 c4 10             	add    $0x10,%esp
f010196a:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
				return NULL;
			}
		}
	}
	return child_pgdir;
}
f0101971:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101974:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101977:	5b                   	pop    %ebx
f0101978:	5e                   	pop    %esi
f0101979:	5f                   	pop    %edi
f010197a:	5d                   	pop    %ebp
f010197b:	c3                   	ret    
	for (uint32_t i = 0; i < USTACKTOP; i += PGSIZE) {
f010197c:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0101982:	81 fe 00 00 00 d0    	cmp    $0xd0000000,%esi
f0101988:	74 e7                	je     f0101971 <copyuvm+0x34>
		if ((pte = pgdir_walk(pgdir, (void *)i, 0)) == NULL)
f010198a:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f010198d:	83 ec 04             	sub    $0x4,%esp
f0101990:	6a 00                	push   $0x0
f0101992:	56                   	push   %esi
f0101993:	57                   	push   %edi
f0101994:	e8 98 fb ff ff       	call   f0101531 <pgdir_walk>
f0101999:	83 c4 10             	add    $0x10,%esp
f010199c:	85 c0                	test   %eax,%eax
f010199e:	74 dc                	je     f010197c <copyuvm+0x3f>
		if (*pte & PTE_P) {
f01019a0:	8b 00                	mov    (%eax),%eax
f01019a2:	a8 01                	test   $0x1,%al
f01019a4:	74 d6                	je     f010197c <copyuvm+0x3f>
			pa = PTE_ADDR(*pte);
f01019a6:	89 c2                	mov    %eax,%edx
f01019a8:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01019ae:	89 55 e0             	mov    %edx,-0x20(%ebp)
			flags = PTE_FLAGS(*pte);
f01019b1:	25 ff 0f 00 00       	and    $0xfff,%eax
f01019b6:	89 45 dc             	mov    %eax,-0x24(%ebp)
			if ((page = kalloc()) == NULL) {
f01019b9:	e8 c1 07 00 00       	call   f010217f <kalloc>
f01019be:	89 c3                	mov    %eax,%ebx
f01019c0:	85 c0                	test   %eax,%eax
f01019c2:	74 98                	je     f010195c <copyuvm+0x1f>
			memmove(page, P2V(pa), PGSIZE);
f01019c4:	83 ec 04             	sub    $0x4,%esp
f01019c7:	68 00 10 00 00       	push   $0x1000
f01019cc:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01019cf:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01019d4:	50                   	push   %eax
f01019d5:	53                   	push   %ebx
f01019d6:	e8 b7 28 00 00       	call   f0104292 <memmove>
			if (map_region(child_pgdir, (void *)i, PGSIZE, V2P(page), flags) < 0) {
f01019db:	83 c4 08             	add    $0x8,%esp
f01019de:	ff 75 dc             	pushl  -0x24(%ebp)
f01019e1:	8d 83 00 00 00 10    	lea    0x10000000(%ebx),%eax
f01019e7:	50                   	push   %eax
f01019e8:	b9 00 10 00 00       	mov    $0x1000,%ecx
f01019ed:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01019f0:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01019f3:	e8 b0 fb ff ff       	call   f01015a8 <map_region>
f01019f8:	83 c4 10             	add    $0x10,%esp
f01019fb:	85 c0                	test   %eax,%eax
f01019fd:	0f 89 79 ff ff ff    	jns    f010197c <copyuvm+0x3f>
				kfree(page);
f0101a03:	83 ec 0c             	sub    $0xc,%esp
f0101a06:	53                   	push   %ebx
f0101a07:	e8 bb 04 00 00       	call   f0101ec7 <kfree>
				vm_free(child_pgdir);
f0101a0c:	83 c4 04             	add    $0x4,%esp
f0101a0f:	ff 75 d8             	pushl  -0x28(%ebp)
f0101a12:	e8 ce fe ff ff       	call   f01018e5 <vm_free>
				return NULL;
f0101a17:	83 c4 10             	add    $0x10,%esp
f0101a1a:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0101a21:	e9 4b ff ff ff       	jmp    f0101971 <copyuvm+0x34>

f0101a26 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
void
region_alloc(struct proc *p, void *va, size_t len)
{
f0101a26:	55                   	push   %ebp
f0101a27:	89 e5                	mov    %esp,%ebp
f0101a29:	57                   	push   %edi
f0101a2a:	56                   	push   %esi
f0101a2b:	53                   	push   %ebx
f0101a2c:	83 ec 1c             	sub    $0x1c,%esp
f0101a2f:	8b 7d 08             	mov    0x8(%ebp),%edi
	//
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	char *begin = ROUNDDOWN(va, PGSIZE);
f0101a32:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101a35:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101a3b:	89 d6                	mov    %edx,%esi
	uint32_t size = ROUNDUP(len, PGSIZE);
f0101a3d:	8b 45 10             	mov    0x10(%ebp),%eax
f0101a40:	05 ff 0f 00 00       	add    $0xfff,%eax
f0101a45:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0101a4a:	01 d0                	add    %edx,%eax
f0101a4c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	while (size) {
f0101a4f:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f0101a52:	74 57                	je     f0101aab <region_alloc+0x85>
		char *page = kalloc();
f0101a54:	e8 26 07 00 00       	call   f010217f <kalloc>
f0101a59:	89 c3                	mov    %eax,%ebx
		memset(page, 0, PGSIZE);
f0101a5b:	83 ec 04             	sub    $0x4,%esp
f0101a5e:	68 00 10 00 00       	push   $0x1000
f0101a63:	6a 00                	push   $0x0
f0101a65:	50                   	push   %eax
f0101a66:	e8 da 27 00 00       	call   f0104245 <memset>
		if (map_region(p->pgdir, begin, PGSIZE, V2P(page), PTE_W | PTE_U) < 0)
f0101a6b:	83 c4 08             	add    $0x8,%esp
f0101a6e:	6a 06                	push   $0x6
f0101a70:	81 c3 00 00 00 10    	add    $0x10000000,%ebx
f0101a76:	53                   	push   %ebx
f0101a77:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0101a7c:	89 f2                	mov    %esi,%edx
f0101a7e:	8b 07                	mov    (%edi),%eax
f0101a80:	e8 23 fb ff ff       	call   f01015a8 <map_region>
f0101a85:	83 c4 10             	add    $0x10,%esp
f0101a88:	85 c0                	test   %eax,%eax
f0101a8a:	78 08                	js     f0101a94 <region_alloc+0x6e>
			panic("Map space for user process.");
		begin += PGSIZE;
f0101a8c:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0101a92:	eb bb                	jmp    f0101a4f <region_alloc+0x29>
			panic("Map space for user process.");
f0101a94:	83 ec 04             	sub    $0x4,%esp
f0101a97:	68 5c 4a 10 f0       	push   $0xf0104a5c
f0101a9c:	68 3b 01 00 00       	push   $0x13b
f0101aa1:	68 1a 4a 10 f0       	push   $0xf0104a1a
f0101aa6:	e8 ed e6 ff ff       	call   f0100198 <_panic>
		size -= PGSIZE;
	}
}
f0101aab:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101aae:	5b                   	pop    %ebx
f0101aaf:	5e                   	pop    %esi
f0101ab0:	5f                   	pop    %edi
f0101ab1:	5d                   	pop    %ebp
f0101ab2:	c3                   	ret    

f0101ab3 <pushcli>:

void
pushcli(void)
{
f0101ab3:	55                   	push   %ebp
f0101ab4:	89 e5                	mov    %esp,%ebp
f0101ab6:	53                   	push   %ebx
f0101ab7:	83 ec 04             	sub    $0x4,%esp
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f0101aba:	9c                   	pushf  
f0101abb:	5b                   	pop    %ebx
}

static inline void
cli(void)
{
	asm volatile("cli");
f0101abc:	fa                   	cli    
	int32_t eflags;

	eflags = read_eflags();
	cli();
	if (thiscpu->ncli == 0)
f0101abd:	e8 02 0d 00 00       	call   f01027c4 <cpunum>
f0101ac2:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f0101ac8:	83 b8 c8 70 12 f0 00 	cmpl   $0x0,-0xfed8f38(%eax)
f0101acf:	74 18                	je     f0101ae9 <pushcli+0x36>
		thiscpu->intena = eflags & FL_IF;
	thiscpu->ncli += 1;
f0101ad1:	e8 ee 0c 00 00       	call   f01027c4 <cpunum>
f0101ad6:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f0101adc:	83 80 c8 70 12 f0 01 	addl   $0x1,-0xfed8f38(%eax)
	// cprintf("%x in push ncli: %d\n", thiscpu, thiscpu->ncli);
}
f0101ae3:	83 c4 04             	add    $0x4,%esp
f0101ae6:	5b                   	pop    %ebx
f0101ae7:	5d                   	pop    %ebp
f0101ae8:	c3                   	ret    
		thiscpu->intena = eflags & FL_IF;
f0101ae9:	e8 d6 0c 00 00       	call   f01027c4 <cpunum>
f0101aee:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f0101af4:	81 e3 00 02 00 00    	and    $0x200,%ebx
f0101afa:	89 98 cc 70 12 f0    	mov    %ebx,-0xfed8f34(%eax)
f0101b00:	eb cf                	jmp    f0101ad1 <pushcli+0x1e>

f0101b02 <popcli>:

void
popcli(void)
{
f0101b02:	55                   	push   %ebp
f0101b03:	89 e5                	mov    %esp,%ebp
f0101b05:	83 ec 08             	sub    $0x8,%esp
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f0101b08:	9c                   	pushf  
f0101b09:	58                   	pop    %eax
	if (read_eflags() & FL_IF)
f0101b0a:	f6 c4 02             	test   $0x2,%ah
f0101b0d:	75 34                	jne    f0101b43 <popcli+0x41>
		panic("popcli - interruptible");
	// cprintf("%x in pop ncli: %d\n", thiscpu, thiscpu->ncli);
	if (--thiscpu->ncli < 0)
f0101b0f:	e8 b0 0c 00 00       	call   f01027c4 <cpunum>
f0101b14:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f0101b1a:	8b 88 c8 70 12 f0    	mov    -0xfed8f38(%eax),%ecx
f0101b20:	8d 51 ff             	lea    -0x1(%ecx),%edx
f0101b23:	89 90 c8 70 12 f0    	mov    %edx,-0xfed8f38(%eax)
f0101b29:	85 d2                	test   %edx,%edx
f0101b2b:	78 2d                	js     f0101b5a <popcli+0x58>
		panic("popcli");
	
	if (thiscpu->ncli == 0 && thiscpu->intena)
f0101b2d:	e8 92 0c 00 00       	call   f01027c4 <cpunum>
f0101b32:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f0101b38:	83 b8 c8 70 12 f0 00 	cmpl   $0x0,-0xfed8f38(%eax)
f0101b3f:	74 30                	je     f0101b71 <popcli+0x6f>
		sti();
}
f0101b41:	c9                   	leave  
f0101b42:	c3                   	ret    
		panic("popcli - interruptible");
f0101b43:	83 ec 04             	sub    $0x4,%esp
f0101b46:	68 78 4a 10 f0       	push   $0xf0104a78
f0101b4b:	68 52 01 00 00       	push   $0x152
f0101b50:	68 1a 4a 10 f0       	push   $0xf0104a1a
f0101b55:	e8 3e e6 ff ff       	call   f0100198 <_panic>
		panic("popcli");
f0101b5a:	83 ec 04             	sub    $0x4,%esp
f0101b5d:	68 8f 4a 10 f0       	push   $0xf0104a8f
f0101b62:	68 55 01 00 00       	push   $0x155
f0101b67:	68 1a 4a 10 f0       	push   $0xf0104a1a
f0101b6c:	e8 27 e6 ff ff       	call   f0100198 <_panic>
	if (thiscpu->ncli == 0 && thiscpu->intena)
f0101b71:	e8 4e 0c 00 00       	call   f01027c4 <cpunum>
f0101b76:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f0101b7c:	83 b8 cc 70 12 f0 00 	cmpl   $0x0,-0xfed8f34(%eax)
f0101b83:	74 bc                	je     f0101b41 <popcli+0x3f>
}

static inline void
sti(void)
{
	asm volatile("sti");
f0101b85:	fb                   	sti    
}
f0101b86:	eb b9                	jmp    f0101b41 <popcli+0x3f>

f0101b88 <uvm_switch>:
//
// Switch TSS and h/w page table to correspond to process p.
//
void
uvm_switch(struct proc *p)
{
f0101b88:	55                   	push   %ebp
f0101b89:	89 e5                	mov    %esp,%ebp
f0101b8b:	57                   	push   %edi
f0101b8c:	56                   	push   %esi
f0101b8d:	53                   	push   %ebx
f0101b8e:	83 ec 0c             	sub    $0xc,%esp
	//
	// Hints:
	// - You may need pushcli() and popcli()
	// - You need to set TSS and ltr(SEG_TSS << 3)
	// - You need to switch to process's address space
	pushcli();
f0101b91:	e8 1d ff ff ff       	call   f0101ab3 <pushcli>
	thiscpu->gdt[SEG_TSS] = SEG16(STS_T32A, &thiscpu->cpu_ts, sizeof(thiscpu->cpu_ts) - 1, 0);
f0101b96:	e8 29 0c 00 00       	call   f01027c4 <cpunum>
f0101b9b:	89 c3                	mov    %eax,%ebx
f0101b9d:	e8 22 0c 00 00       	call   f01027c4 <cpunum>
f0101ba2:	89 c7                	mov    %eax,%edi
f0101ba4:	e8 1b 0c 00 00       	call   f01027c4 <cpunum>
f0101ba9:	89 c6                	mov    %eax,%esi
f0101bab:	e8 14 0c 00 00       	call   f01027c4 <cpunum>
f0101bb0:	69 db b8 00 00 00    	imul   $0xb8,%ebx,%ebx
f0101bb6:	8d 93 20 70 12 f0    	lea    -0xfed8fe0(%ebx),%edx
f0101bbc:	66 c7 83 bc 70 12 f0 	movw   $0x67,-0xfed8f44(%ebx)
f0101bc3:	67 00 
f0101bc5:	69 ff b8 00 00 00    	imul   $0xb8,%edi,%edi
f0101bcb:	81 c7 2c 70 12 f0    	add    $0xf012702c,%edi
f0101bd1:	66 89 bb be 70 12 f0 	mov    %di,-0xfed8f42(%ebx)
f0101bd8:	69 ce b8 00 00 00    	imul   $0xb8,%esi,%ecx
f0101bde:	81 c1 2c 70 12 f0    	add    $0xf012702c,%ecx
f0101be4:	c1 e9 10             	shr    $0x10,%ecx
f0101be7:	88 8b c0 70 12 f0    	mov    %cl,-0xfed8f40(%ebx)
f0101bed:	c6 83 c1 70 12 f0 99 	movb   $0x99,-0xfed8f3f(%ebx)
f0101bf4:	c6 83 c2 70 12 f0 40 	movb   $0x40,-0xfed8f3e(%ebx)
f0101bfb:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f0101c01:	05 2c 70 12 f0       	add    $0xf012702c,%eax
f0101c06:	c1 e8 18             	shr    $0x18,%eax
f0101c09:	88 82 a3 00 00 00    	mov    %al,0xa3(%edx)
	thiscpu->gdt[SEG_TSS].s = 0;
f0101c0f:	e8 b0 0b 00 00       	call   f01027c4 <cpunum>
f0101c14:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f0101c1a:	80 a0 c1 70 12 f0 ef 	andb   $0xef,-0xfed8f3f(%eax)
	thiscpu->cpu_ts.ss0 = SEG_KDATA << 3;
f0101c21:	e8 9e 0b 00 00       	call   f01027c4 <cpunum>
f0101c26:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f0101c2c:	66 c7 80 34 70 12 f0 	movw   $0x10,-0xfed8fcc(%eax)
f0101c33:	10 00 
	thiscpu->cpu_ts.esp0 = (uintptr_t)p->kstack + KSTACKSIZE;
f0101c35:	8b 45 08             	mov    0x8(%ebp),%eax
f0101c38:	8b 58 04             	mov    0x4(%eax),%ebx
f0101c3b:	e8 84 0b 00 00       	call   f01027c4 <cpunum>
f0101c40:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f0101c46:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0101c4c:	89 98 30 70 12 f0    	mov    %ebx,-0xfed8fd0(%eax)
	thiscpu->cpu_ts.iomb = (uint16_t)0xFFFF;
f0101c52:	e8 6d 0b 00 00       	call   f01027c4 <cpunum>
f0101c57:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f0101c5d:	66 c7 80 92 70 12 f0 	movw   $0xffff,-0xfed8f6e(%eax)
f0101c64:	ff ff 
	asm volatile("ltr %0" : : "r" (sel));
f0101c66:	b8 28 00 00 00       	mov    $0x28,%eax
f0101c6b:	0f 00 d8             	ltr    %ax
	ltr(SEG_TSS << 3);
	lcr3(V2P(p->pgdir));
f0101c6e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101c71:	8b 00                	mov    (%eax),%eax
f0101c73:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0101c78:	0f 22 d8             	mov    %eax,%cr3
	popcli();
f0101c7b:	e8 82 fe ff ff       	call   f0101b02 <popcli>
}
f0101c80:	83 c4 0c             	add    $0xc,%esp
f0101c83:	5b                   	pop    %ebx
f0101c84:	5e                   	pop    %esi
f0101c85:	5f                   	pop    %edi
f0101c86:	5d                   	pop    %ebp
f0101c87:	c3                   	ret    

f0101c88 <pow_2>:
// the pages mapped by entrypgdir on free list.
// 2. Call alloc_init() with the rest of the physical pages after
// installing a full page table.

int pow_2(int power)
{
f0101c88:	55                   	push   %ebp
f0101c89:	89 e5                	mov    %esp,%ebp
f0101c8b:	8b 4d 08             	mov    0x8(%ebp),%ecx
	int num = 1;
	for (int i = 0; i < power; i++)
f0101c8e:	ba 00 00 00 00       	mov    $0x0,%edx
	int num = 1;
f0101c93:	b8 01 00 00 00       	mov    $0x1,%eax
	for (int i = 0; i < power; i++)
f0101c98:	eb 05                	jmp    f0101c9f <pow_2+0x17>
		num *= 2;
f0101c9a:	01 c0                	add    %eax,%eax
	for (int i = 0; i < power; i++)
f0101c9c:	83 c2 01             	add    $0x1,%edx
f0101c9f:	39 ca                	cmp    %ecx,%edx
f0101ca1:	7c f7                	jl     f0101c9a <pow_2+0x12>
	return num;
}
f0101ca3:	5d                   	pop    %ebp
f0101ca4:	c3                   	ret    

f0101ca5 <Buddykfree>:
	kmem.free_list = r;*/
}

void
Buddykfree(char *v)
{
f0101ca5:	55                   	push   %ebp
f0101ca6:	89 e5                	mov    %esp,%ebp
f0101ca8:	57                   	push   %edi
f0101ca9:	56                   	push   %esi
f0101caa:	53                   	push   %ebx
f0101cab:	83 ec 2c             	sub    $0x2c,%esp
	struct run *r;

	if ((uint32_t)v % PGSIZE || v < end || V2P(v) >= PHYSTOP)
f0101cae:	8b 45 08             	mov    0x8(%ebp),%eax
f0101cb1:	a9 ff 0f 00 00       	test   $0xfff,%eax
f0101cb6:	75 56                	jne    f0101d0e <Buddykfree+0x69>
f0101cb8:	3d b0 8c 16 f0       	cmp    $0xf0168cb0,%eax
f0101cbd:	72 4f                	jb     f0101d0e <Buddykfree+0x69>
f0101cbf:	05 00 00 00 10       	add    $0x10000000,%eax
f0101cc4:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
f0101cc9:	77 43                	ja     f0101d0e <Buddykfree+0x69>
		panic("kfree");
	int idx, id;
	id = (void *)v >= (void *)base[1];
f0101ccb:	8b 45 08             	mov    0x8(%ebp),%eax
f0101cce:	39 05 04 6f 12 f0    	cmp    %eax,0xf0126f04
f0101cd4:	0f 96 45 cb          	setbe  -0x35(%ebp)
f0101cd8:	0f b6 45 cb          	movzbl -0x35(%ebp),%eax
f0101cdc:	0f b6 f0             	movzbl %al,%esi
	//cprintf("minus: %x, num: %x,idx: %x\n", (void *)v - (void *)base[0], (uint32_t)((void *)v - (void *)base[0]) / PGSIZE, idx);
	idx = (uint32_t)((void *)v - (void *)base[id]) / PGSIZE;
f0101cdf:	8b 45 08             	mov    0x8(%ebp),%eax
f0101ce2:	2b 04 b5 00 6f 12 f0 	sub    -0xfed9100(,%esi,4),%eax
f0101ce9:	c1 e8 0c             	shr    $0xc,%eax
f0101cec:	89 45 cc             	mov    %eax,-0x34(%ebp)
	int p = idx;
	int count = 0;
	//cprintf("v: %x, idx: %x, p: %x\n", v, idx, p);
	if (Buddy[id].use_lock)
f0101cef:	6b c6 3c             	imul   $0x3c,%esi,%eax
f0101cf2:	83 b8 20 6f 12 f0 00 	cmpl   $0x0,-0xfed90e0(%eax)
f0101cf9:	75 2a                	jne    f0101d25 <Buddykfree+0x80>
		spin_lock(&Buddy[id].lock);
	while (order[id][p] != 1) {
f0101cfb:	8b 3c b5 a0 6f 12 f0 	mov    -0xfed9060(,%esi,4),%edi
f0101d02:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101d05:	89 c3                	mov    %eax,%ebx
f0101d07:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101d0c:	eb 3e                	jmp    f0101d4c <Buddykfree+0xa7>
		panic("kfree");
f0101d0e:	83 ec 04             	sub    $0x4,%esp
f0101d11:	68 e0 4a 10 f0       	push   $0xf0104ae0
f0101d16:	68 e3 00 00 00       	push   $0xe3
f0101d1b:	68 e6 4a 10 f0       	push   $0xf0104ae6
f0101d20:	e8 73 e4 ff ff       	call   f0100198 <_panic>
		spin_lock(&Buddy[id].lock);
f0101d25:	83 ec 0c             	sub    $0xc,%esp
f0101d28:	6b c6 3c             	imul   $0x3c,%esi,%eax
f0101d2b:	05 28 6f 12 f0       	add    $0xf0126f28,%eax
f0101d30:	50                   	push   %eax
f0101d31:	e8 cb 0c 00 00       	call   f0102a01 <spin_lock>
f0101d36:	83 c4 10             	add    $0x10,%esp
f0101d39:	eb c0                	jmp    f0101cfb <Buddykfree+0x56>
		count++;
f0101d3b:	83 c1 01             	add    $0x1,%ecx
		p = start[id][count] + (idx >> count);
f0101d3e:	8b 14 b5 a8 6f 12 f0 	mov    -0xfed9058(,%esi,4),%edx
f0101d45:	89 c3                	mov    %eax,%ebx
f0101d47:	d3 fb                	sar    %cl,%ebx
f0101d49:	03 1c 8a             	add    (%edx,%ecx,4),%ebx
	while (order[id][p] != 1) {
f0101d4c:	80 3c 1f 00          	cmpb   $0x0,(%edi,%ebx,1)
f0101d50:	74 e9                	je     f0101d3b <Buddykfree+0x96>
f0101d52:	89 5d e0             	mov    %ebx,-0x20(%ebp)
f0101d55:	89 cf                	mov    %ecx,%edi
f0101d57:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	}
	//cprintf("p: %x\n", p);
	memset(v, 1, PGSIZE * pow_2(count));
f0101d5a:	83 ec 0c             	sub    $0xc,%esp
f0101d5d:	51                   	push   %ecx
f0101d5e:	e8 25 ff ff ff       	call   f0101c88 <pow_2>
f0101d63:	83 c4 0c             	add    $0xc,%esp
f0101d66:	c1 e0 0c             	shl    $0xc,%eax
f0101d69:	50                   	push   %eax
f0101d6a:	6a 01                	push   $0x1
f0101d6c:	ff 75 08             	pushl  0x8(%ebp)
f0101d6f:	e8 d1 24 00 00       	call   f0104245 <memset>
	order[id][p] = 0;
f0101d74:	8b 04 b5 a0 6f 12 f0 	mov    -0xfed9060(,%esi,4),%eax
f0101d7b:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0101d7e:	c6 04 10 00          	movb   $0x0,(%eax,%edx,1)
	int buddy = p ^ 1;
f0101d82:	89 d8                	mov    %ebx,%eax
f0101d84:	83 f0 01             	xor    $0x1,%eax
	int mark = 1 << (count + 12);
f0101d87:	8d 4f 0c             	lea    0xc(%edi),%ecx
f0101d8a:	ba 01 00 00 00       	mov    $0x1,%edx
f0101d8f:	d3 e2                	shl    %cl,%edx
f0101d91:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101d94:	8d 14 fd 00 00 00 00 	lea    0x0(,%edi,8),%edx
f0101d9b:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0101d9e:	8d 3c bd 04 00 00 00 	lea    0x4(,%edi,4),%edi
f0101da5:	89 7d d8             	mov    %edi,-0x28(%ebp)
	char *buddypos;
	while (count < MAX_ORDER[id] && order[id][buddy] == 0) {
f0101da8:	83 c4 10             	add    $0x10,%esp
		//cprintf("p: %x, buddy: %x\n", p, buddy);
		buddypos = (char *)base[id] + ((uint32_t)(v - (char *)base[id]) ^ mark);
		//cprintf("buddypos: %x, mark: %x\n", buddypos, mark);
		struct run *iter = Buddy[id].slot[count].free_list;
f0101dab:	6b d6 3c             	imul   $0x3c,%esi,%edx
f0101dae:	8d ba 20 6f 12 f0    	lea    -0xfed90e0(%edx),%edi
f0101db4:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0101db7:	89 f7                	mov    %esi,%edi
	while (count < MAX_ORDER[id] && order[id][buddy] == 0) {
f0101db9:	eb 72                	jmp    f0101e2d <Buddykfree+0x188>
		while (iter->next != (struct run *)buddypos && iter->next != Buddy[id].slot[count].free_list)
f0101dbb:	89 c2                	mov    %eax,%edx
f0101dbd:	8b 02                	mov    (%edx),%eax
f0101dbf:	39 f0                	cmp    %esi,%eax
f0101dc1:	0f 95 c3             	setne  %bl
f0101dc4:	39 f8                	cmp    %edi,%eax
f0101dc6:	0f 95 c1             	setne  %cl
f0101dc9:	84 cb                	test   %cl,%bl
f0101dcb:	75 ee                	jne    f0101dbb <Buddykfree+0x116>
f0101dcd:	8b 7d d0             	mov    -0x30(%ebp),%edi
		// buddy is occupied
		// have little change
		//if (iter->next != (struct run *)buddypos)
		//	break;
		struct run *uni = iter->next;
		iter->next = uni->next;
f0101dd0:	8b 08                	mov    (%eax),%ecx
f0101dd2:	89 0a                	mov    %ecx,(%edx)
		Buddy[id].slot[count].num--;
f0101dd4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101dd7:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0101dda:	89 f1                	mov    %esi,%ecx
f0101ddc:	03 4b 04             	add    0x4(%ebx),%ecx
f0101ddf:	83 69 04 01          	subl   $0x1,0x4(%ecx)
		Buddy[id].slot[count].free_list = iter->next;
f0101de3:	8b 0a                	mov    (%edx),%ecx
f0101de5:	8b 53 04             	mov    0x4(%ebx),%edx
f0101de8:	89 0c 32             	mov    %ecx,(%edx,%esi,1)
		v = (v > (char *)uni) ? (char *)uni : v;
f0101deb:	39 45 08             	cmp    %eax,0x8(%ebp)
f0101dee:	0f 46 45 08          	cmovbe 0x8(%ebp),%eax
f0101df2:	89 45 08             	mov    %eax,0x8(%ebp)
		count++;
f0101df5:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
f0101df9:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		mark <<= 1;
f0101dfc:	d1 65 dc             	shll   -0x24(%ebp)
		p = start[id][count] + (idx >> count);
f0101dff:	8b 14 bd a8 6f 12 f0 	mov    -0xfed9058(,%edi,4),%edx
f0101e06:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101e09:	89 d9                	mov    %ebx,%ecx
f0101e0b:	d3 f8                	sar    %cl,%eax
f0101e0d:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0101e10:	03 04 1a             	add    (%edx,%ebx,1),%eax
		//cprintf("order: %d, p: %x\n", order[id][p], p);
		order[id][p] = 0;
f0101e13:	8b 14 bd a0 6f 12 f0 	mov    -0xfed9060(,%edi,4),%edx
f0101e1a:	c6 04 02 00          	movb   $0x0,(%edx,%eax,1)
		//cprintf("order: %d\n", order[id][p]);
		buddy = p ^ 1;
f0101e1e:	83 f0 01             	xor    $0x1,%eax
f0101e21:	83 c6 08             	add    $0x8,%esi
f0101e24:	89 75 e0             	mov    %esi,-0x20(%ebp)
f0101e27:	83 c3 04             	add    $0x4,%ebx
f0101e2a:	89 5d d8             	mov    %ebx,-0x28(%ebp)
	while (count < MAX_ORDER[id] && order[id][buddy] == 0) {
f0101e2d:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101e30:	39 0c bd b0 6f 12 f0 	cmp    %ecx,-0xfed9050(,%edi,4)
f0101e37:	7e 37                	jle    f0101e70 <Buddykfree+0x1cb>
f0101e39:	8b 14 bd a0 6f 12 f0 	mov    -0xfed9060(,%edi,4),%edx
f0101e40:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101e44:	75 2a                	jne    f0101e70 <Buddykfree+0x1cb>
		buddypos = (char *)base[id] + ((uint32_t)(v - (char *)base[id]) ^ mark);
f0101e46:	8b 04 bd 00 6f 12 f0 	mov    -0xfed9100(,%edi,4),%eax
f0101e4d:	8b 75 08             	mov    0x8(%ebp),%esi
f0101e50:	29 c6                	sub    %eax,%esi
f0101e52:	33 75 dc             	xor    -0x24(%ebp),%esi
f0101e55:	8d 0c 30             	lea    (%eax,%esi,1),%ecx
		struct run *iter = Buddy[id].slot[count].free_list;
f0101e58:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e5b:	8b 40 04             	mov    0x4(%eax),%eax
f0101e5e:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0101e61:	8b 34 30             	mov    (%eax,%esi,1),%esi
f0101e64:	89 f2                	mov    %esi,%edx
f0101e66:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0101e69:	89 cf                	mov    %ecx,%edi
		while (iter->next != (struct run *)buddypos && iter->next != Buddy[id].slot[count].free_list)
f0101e6b:	e9 4d ff ff ff       	jmp    f0101dbd <Buddykfree+0x118>
	}
	r = (struct run *)v;
	r->next = Buddy[id].slot[count].free_list->next;
f0101e70:	6b d7 3c             	imul   $0x3c,%edi,%edx
f0101e73:	8b 8a 24 6f 12 f0    	mov    -0xfed90dc(%edx),%ecx
f0101e79:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101e7c:	8b 0c f9             	mov    (%ecx,%edi,8),%ecx
f0101e7f:	8b 09                	mov    (%ecx),%ecx
f0101e81:	8b 75 08             	mov    0x8(%ebp),%esi
f0101e84:	89 0e                	mov    %ecx,(%esi)
	Buddy[id].slot[count].free_list->next = r;
f0101e86:	8b 8a 24 6f 12 f0    	mov    -0xfed90dc(%edx),%ecx
f0101e8c:	8b 0c f9             	mov    (%ecx,%edi,8),%ecx
f0101e8f:	89 31                	mov    %esi,(%ecx)
	Buddy[id].slot[count].num++;
f0101e91:	8b 82 24 6f 12 f0    	mov    -0xfed90dc(%edx),%eax
f0101e97:	83 44 f8 04 01       	addl   $0x1,0x4(%eax,%edi,8)
	if (Buddy[id].use_lock)
f0101e9c:	83 ba 20 6f 12 f0 00 	cmpl   $0x0,-0xfed90e0(%edx)
f0101ea3:	75 08                	jne    f0101ead <Buddykfree+0x208>
		spin_unlock(&Buddy[id].lock);
}
f0101ea5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101ea8:	5b                   	pop    %ebx
f0101ea9:	5e                   	pop    %esi
f0101eaa:	5f                   	pop    %edi
f0101eab:	5d                   	pop    %ebp
f0101eac:	c3                   	ret    
		spin_unlock(&Buddy[id].lock);
f0101ead:	83 ec 0c             	sub    $0xc,%esp
f0101eb0:	0f b6 45 cb          	movzbl -0x35(%ebp),%eax
f0101eb4:	6b c0 3c             	imul   $0x3c,%eax,%eax
f0101eb7:	05 28 6f 12 f0       	add    $0xf0126f28,%eax
f0101ebc:	50                   	push   %eax
f0101ebd:	e8 a7 0b 00 00       	call   f0102a69 <spin_unlock>
f0101ec2:	83 c4 10             	add    $0x10,%esp
}
f0101ec5:	eb de                	jmp    f0101ea5 <Buddykfree+0x200>

f0101ec7 <kfree>:
{
f0101ec7:	55                   	push   %ebp
f0101ec8:	89 e5                	mov    %esp,%ebp
f0101eca:	83 ec 14             	sub    $0x14,%esp
	Buddykfree(v);
f0101ecd:	ff 75 08             	pushl  0x8(%ebp)
f0101ed0:	e8 d0 fd ff ff       	call   f0101ca5 <Buddykfree>
}
f0101ed5:	83 c4 10             	add    $0x10,%esp
f0101ed8:	c9                   	leave  
f0101ed9:	c3                   	ret    

f0101eda <free_range>:

void
free_range(void *vstart, void *vend)
{
f0101eda:	55                   	push   %ebp
f0101edb:	89 e5                	mov    %esp,%ebp
f0101edd:	56                   	push   %esi
f0101ede:	53                   	push   %ebx
f0101edf:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *p;
	p = ROUNDUP((char *)vstart, PGSIZE);
f0101ee2:	8b 45 08             	mov    0x8(%ebp),%eax
f0101ee5:	05 ff 0f 00 00       	add    $0xfff,%eax
f0101eea:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	for (; p + PGSIZE <= (char *)vend; p += PGSIZE)
f0101eef:	eb 0e                	jmp    f0101eff <free_range+0x25>
	Buddykfree(v);
f0101ef1:	83 ec 0c             	sub    $0xc,%esp
f0101ef4:	50                   	push   %eax
f0101ef5:	e8 ab fd ff ff       	call   f0101ca5 <Buddykfree>
	for (; p + PGSIZE <= (char *)vend; p += PGSIZE)
f0101efa:	83 c4 10             	add    $0x10,%esp
f0101efd:	89 f0                	mov    %esi,%eax
f0101eff:	8d b0 00 10 00 00    	lea    0x1000(%eax),%esi
f0101f05:	39 de                	cmp    %ebx,%esi
f0101f07:	76 e8                	jbe    f0101ef1 <free_range+0x17>
		kfree(p);
}
f0101f09:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0101f0c:	5b                   	pop    %ebx
f0101f0d:	5e                   	pop    %esi
f0101f0e:	5d                   	pop    %ebp
f0101f0f:	c3                   	ret    

f0101f10 <Buddyfree_range>:

void
Buddyfree_range(void *vstart, int level)
{
f0101f10:	55                   	push   %ebp
f0101f11:	89 e5                	mov    %esp,%ebp
f0101f13:	57                   	push   %edi
f0101f14:	56                   	push   %esi
f0101f15:	53                   	push   %ebx
f0101f16:	83 ec 0c             	sub    $0xc,%esp
f0101f19:	8b 75 08             	mov    0x8(%ebp),%esi
f0101f1c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	struct run *r;
	int id = ((void *)vstart >= (void *)base[1]) ? 1 : 0;
f0101f1f:	39 35 04 6f 12 f0    	cmp    %esi,0xf0126f04
f0101f25:	0f 96 c0             	setbe  %al
f0101f28:	0f b6 c0             	movzbl %al,%eax
f0101f2b:	89 c7                	mov    %eax,%edi

	memset(vstart, 1, PGSIZE * pow_2(level));
f0101f2d:	53                   	push   %ebx
f0101f2e:	e8 55 fd ff ff       	call   f0101c88 <pow_2>
f0101f33:	c1 e0 0c             	shl    $0xc,%eax
f0101f36:	50                   	push   %eax
f0101f37:	6a 01                	push   $0x1
f0101f39:	56                   	push   %esi
f0101f3a:	e8 06 23 00 00       	call   f0104245 <memset>
	r = (struct run *)vstart;
	//cprintf("%x, %x\n", Buddy[id][level].free_list->next, Buddy[id][level].free_list);
	r->next = Buddy[id].slot[level].free_list->next;
f0101f3f:	6b c7 3c             	imul   $0x3c,%edi,%eax
f0101f42:	8b 90 24 6f 12 f0    	mov    -0xfed90dc(%eax),%edx
f0101f48:	8b 14 da             	mov    (%edx,%ebx,8),%edx
f0101f4b:	8b 12                	mov    (%edx),%edx
f0101f4d:	89 16                	mov    %edx,(%esi)
	Buddy[id].slot[level].free_list->next = r;
f0101f4f:	8b 90 24 6f 12 f0    	mov    -0xfed90dc(%eax),%edx
	r->next = Buddy[id].slot[level].free_list->next;
f0101f55:	05 20 6f 12 f0       	add    $0xf0126f20,%eax
	Buddy[id].slot[level].free_list->next = r;
f0101f5a:	8b 14 da             	mov    (%edx,%ebx,8),%edx
f0101f5d:	89 32                	mov    %esi,(%edx)
	//cprintf("%x, %x\n", Buddy[id][level].free_list->next, Buddy[id][level].free_list);
	Buddy[id].slot[level].num++;
f0101f5f:	8b 40 04             	mov    0x4(%eax),%eax
f0101f62:	83 44 d8 04 01       	addl   $0x1,0x4(%eax,%ebx,8)
}
f0101f67:	83 c4 10             	add    $0x10,%esp
f0101f6a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101f6d:	5b                   	pop    %ebx
f0101f6e:	5e                   	pop    %esi
f0101f6f:	5f                   	pop    %edi
f0101f70:	5d                   	pop    %ebp
f0101f71:	c3                   	ret    

f0101f72 <split>:
		return NULL;*/
}

void
split(char *r, int low, int high)
{
f0101f72:	55                   	push   %ebp
f0101f73:	89 e5                	mov    %esp,%ebp
f0101f75:	57                   	push   %edi
f0101f76:	56                   	push   %esi
f0101f77:	53                   	push   %ebx
f0101f78:	83 ec 10             	sub    $0x10,%esp
f0101f7b:	8b 4d 10             	mov    0x10(%ebp),%ecx
	int size = 1 << high;
f0101f7e:	b8 01 00 00 00       	mov    $0x1,%eax
f0101f83:	d3 e0                	shl    %cl,%eax
f0101f85:	89 45 f0             	mov    %eax,-0x10(%ebp)
	int id, idx;
	id = (void *)r >= (void *)base[1];
f0101f88:	8b 45 08             	mov    0x8(%ebp),%eax
f0101f8b:	39 05 04 6f 12 f0    	cmp    %eax,0xf0126f04
f0101f91:	0f 96 c0             	setbe  %al
f0101f94:	0f b6 c0             	movzbl %al,%eax
f0101f97:	89 c6                	mov    %eax,%esi
	idx = (uint32_t)((void *)r - (void *)base[id]) / PGSIZE;
f0101f99:	8b 45 08             	mov    0x8(%ebp),%eax
f0101f9c:	2b 04 b5 00 6f 12 f0 	sub    -0xfed9100(,%esi,4),%eax
f0101fa3:	c1 e8 0c             	shr    $0xc,%eax
f0101fa6:	89 45 e8             	mov    %eax,-0x18(%ebp)
f0101fa9:	8d 04 8d 00 00 00 00 	lea    0x0(,%ecx,4),%eax
f0101fb0:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101fb3:	8d 04 cd f8 ff ff ff 	lea    -0x8(,%ecx,8),%eax
		//cprintf("high: %x, pos: %x\n", high, start[high] + (idx >> high));
		high--;
		size >>= 1;
		struct run *p = (struct run *)((uint32_t)r + PGSIZE * size);
		//add high
		p->next = Buddy[id].slot[high].free_list->next;
f0101fba:	6b de 3c             	imul   $0x3c,%esi,%ebx
f0101fbd:	81 c3 20 6f 12 f0    	add    $0xf0126f20,%ebx
f0101fc3:	89 75 e4             	mov    %esi,-0x1c(%ebp)
	while (high > low) {
f0101fc6:	eb 54                	jmp    f010201c <split+0xaa>
		order[id][start[id][high] + (idx >> high)] = 1;
f0101fc8:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101fcb:	8b 3c b5 a8 6f 12 f0 	mov    -0xfed9058(,%esi,4),%edi
f0101fd2:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0101fd5:	d3 fa                	sar    %cl,%edx
f0101fd7:	03 14 b5 a0 6f 12 f0 	add    -0xfed9060(,%esi,4),%edx
f0101fde:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0101fe1:	03 14 37             	add    (%edi,%esi,1),%edx
f0101fe4:	c6 02 01             	movb   $0x1,(%edx)
		high--;
f0101fe7:	83 e9 01             	sub    $0x1,%ecx
		size >>= 1;
f0101fea:	d1 7d f0             	sarl   -0x10(%ebp)
f0101fed:	8b 7d f0             	mov    -0x10(%ebp),%edi
		struct run *p = (struct run *)((uint32_t)r + PGSIZE * size);
f0101ff0:	89 fa                	mov    %edi,%edx
f0101ff2:	c1 e2 0c             	shl    $0xc,%edx
f0101ff5:	03 55 08             	add    0x8(%ebp),%edx
		p->next = Buddy[id].slot[high].free_list->next;
f0101ff8:	8b 7b 04             	mov    0x4(%ebx),%edi
f0101ffb:	8b 3c 07             	mov    (%edi,%eax,1),%edi
f0101ffe:	8b 3f                	mov    (%edi),%edi
f0102000:	89 3a                	mov    %edi,(%edx)
		Buddy[id].slot[high].free_list->next = p;
f0102002:	8b 7b 04             	mov    0x4(%ebx),%edi
f0102005:	8b 3c 07             	mov    (%edi,%eax,1),%edi
f0102008:	89 17                	mov    %edx,(%edi)
		Buddy[id].slot[high].num++;
f010200a:	89 c2                	mov    %eax,%edx
f010200c:	03 53 04             	add    0x4(%ebx),%edx
f010200f:	83 42 04 01          	addl   $0x1,0x4(%edx)
f0102013:	83 ee 04             	sub    $0x4,%esi
f0102016:	89 75 ec             	mov    %esi,-0x14(%ebp)
f0102019:	83 e8 08             	sub    $0x8,%eax
	while (high > low) {
f010201c:	3b 4d 0c             	cmp    0xc(%ebp),%ecx
f010201f:	7f a7                	jg     f0101fc8 <split+0x56>
f0102021:	8b 75 e4             	mov    -0x1c(%ebp),%esi
	}
	order[id][start[id][high] + (idx >> high)] = 1;
f0102024:	8b 14 b5 a8 6f 12 f0 	mov    -0xfed9058(,%esi,4),%edx
f010202b:	8b 45 e8             	mov    -0x18(%ebp),%eax
f010202e:	d3 f8                	sar    %cl,%eax
f0102030:	03 04 b5 a0 6f 12 f0 	add    -0xfed9060(,%esi,4),%eax
f0102037:	03 04 8a             	add    (%edx,%ecx,4),%eax
f010203a:	c6 00 01             	movb   $0x1,(%eax)
	//cprintf("pos: %x\n", start[id][high] + (idx >> high));
}
f010203d:	83 c4 10             	add    $0x10,%esp
f0102040:	5b                   	pop    %ebx
f0102041:	5e                   	pop    %esi
f0102042:	5f                   	pop    %edi
f0102043:	5d                   	pop    %ebp
f0102044:	c3                   	ret    

f0102045 <Buddykalloc>:

char *
Buddykalloc(int order)
{
f0102045:	55                   	push   %ebp
f0102046:	89 e5                	mov    %esp,%ebp
f0102048:	57                   	push   %edi
f0102049:	56                   	push   %esi
f010204a:	53                   	push   %ebx
f010204b:	83 ec 1c             	sub    $0x1c,%esp
	for (int i = 0; i < 2; i++) {
		if (Buddy[i].use_lock)
f010204e:	83 3d 20 6f 12 f0 00 	cmpl   $0x0,0xf0126f20
f0102055:	75 36                	jne    f010208d <Buddykalloc+0x48>
			spin_lock(&Buddy[i].lock);
		for (int currentorder = order; currentorder <= MAX_ORDER[i]; currentorder++)
f0102057:	8b 35 b0 6f 12 f0    	mov    0xf0126fb0,%esi
f010205d:	8b 45 08             	mov    0x8(%ebp),%eax
f0102060:	8d 1c c5 00 00 00 00 	lea    0x0(,%eax,8),%ebx
			if (Buddy[i].slot[currentorder].num > 0) {
f0102067:	8b 3d 24 6f 12 f0    	mov    0xf0126f24,%edi
f010206d:	89 da                	mov    %ebx,%edx
		for (int currentorder = order; currentorder <= MAX_ORDER[i]; currentorder++)
f010206f:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0102072:	39 c6                	cmp    %eax,%esi
f0102074:	7c 29                	jl     f010209f <Buddykalloc+0x5a>
			if (Buddy[i].slot[currentorder].num > 0) {
f0102076:	8d 0c 17             	lea    (%edi,%edx,1),%ecx
f0102079:	8d 5a 08             	lea    0x8(%edx),%ebx
f010207c:	83 79 04 00          	cmpl   $0x0,0x4(%ecx)
f0102080:	0f 8f 84 00 00 00    	jg     f010210a <Buddykalloc+0xc5>
		for (int currentorder = order; currentorder <= MAX_ORDER[i]; currentorder++)
f0102086:	83 c0 01             	add    $0x1,%eax
f0102089:	89 da                	mov    %ebx,%edx
f010208b:	eb e5                	jmp    f0102072 <Buddykalloc+0x2d>
			spin_lock(&Buddy[i].lock);
f010208d:	83 ec 0c             	sub    $0xc,%esp
f0102090:	68 28 6f 12 f0       	push   $0xf0126f28
f0102095:	e8 67 09 00 00       	call   f0102a01 <spin_lock>
f010209a:	83 c4 10             	add    $0x10,%esp
f010209d:	eb b8                	jmp    f0102057 <Buddykalloc+0x12>
f010209f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
				split((char *)r, order, currentorder);
				if (Buddy[i].use_lock)
					spin_unlock(&Buddy[i].lock);
				return (char *)r;
			}
		if (Buddy[i].use_lock)
f01020a2:	83 3d 20 6f 12 f0 00 	cmpl   $0x0,0xf0126f20
f01020a9:	75 32                	jne    f01020dd <Buddykalloc+0x98>
		if (Buddy[i].use_lock)
f01020ab:	83 3d 5c 6f 12 f0 00 	cmpl   $0x0,0xf0126f5c
f01020b2:	75 3b                	jne    f01020ef <Buddykalloc+0xaa>
		for (int currentorder = order; currentorder <= MAX_ORDER[i]; currentorder++)
f01020b4:	8b 35 b4 6f 12 f0    	mov    0xf0126fb4,%esi
f01020ba:	8b 45 08             	mov    0x8(%ebp),%eax
f01020bd:	39 c6                	cmp    %eax,%esi
f01020bf:	0f 8c 98 00 00 00    	jl     f010215d <Buddykalloc+0x118>
			if (Buddy[i].slot[currentorder].num > 0) {
f01020c5:	89 d9                	mov    %ebx,%ecx
f01020c7:	03 0d 60 6f 12 f0    	add    0xf0126f60,%ecx
f01020cd:	8d 53 08             	lea    0x8(%ebx),%edx
f01020d0:	83 79 04 00          	cmpl   $0x0,0x4(%ecx)
f01020d4:	7f 2b                	jg     f0102101 <Buddykalloc+0xbc>
		for (int currentorder = order; currentorder <= MAX_ORDER[i]; currentorder++)
f01020d6:	83 c0 01             	add    $0x1,%eax
f01020d9:	89 d3                	mov    %edx,%ebx
f01020db:	eb e0                	jmp    f01020bd <Buddykalloc+0x78>
			spin_unlock(&Buddy[i].lock);
f01020dd:	83 ec 0c             	sub    $0xc,%esp
f01020e0:	68 28 6f 12 f0       	push   $0xf0126f28
f01020e5:	e8 7f 09 00 00       	call   f0102a69 <spin_unlock>
f01020ea:	83 c4 10             	add    $0x10,%esp
f01020ed:	eb bc                	jmp    f01020ab <Buddykalloc+0x66>
			spin_lock(&Buddy[i].lock);
f01020ef:	83 ec 0c             	sub    $0xc,%esp
f01020f2:	68 64 6f 12 f0       	push   $0xf0126f64
f01020f7:	e8 05 09 00 00       	call   f0102a01 <spin_lock>
f01020fc:	83 c4 10             	add    $0x10,%esp
f01020ff:	eb b3                	jmp    f01020b4 <Buddykalloc+0x6f>
			if (Buddy[i].slot[currentorder].num > 0) {
f0102101:	89 da                	mov    %ebx,%edx
	for (int i = 0; i < 2; i++) {
f0102103:	bf 01 00 00 00       	mov    $0x1,%edi
f0102108:	eb 05                	jmp    f010210f <Buddykalloc+0xca>
f010210a:	bf 00 00 00 00       	mov    $0x0,%edi
				r = Buddy[i].slot[currentorder].free_list->next;
f010210f:	8b 09                	mov    (%ecx),%ecx
f0102111:	8b 19                	mov    (%ecx),%ebx
				Buddy[i].slot[currentorder].free_list->next = r->next;
f0102113:	8b 33                	mov    (%ebx),%esi
f0102115:	89 31                	mov    %esi,(%ecx)
				Buddy[i].slot[currentorder].num--;
f0102117:	6b f7 3c             	imul   $0x3c,%edi,%esi
f010211a:	03 96 24 6f 12 f0    	add    -0xfed90dc(%esi),%edx
f0102120:	83 6a 04 01          	subl   $0x1,0x4(%edx)
				split((char *)r, order, currentorder);
f0102124:	83 ec 04             	sub    $0x4,%esp
f0102127:	50                   	push   %eax
f0102128:	ff 75 08             	pushl  0x8(%ebp)
f010212b:	53                   	push   %ebx
f010212c:	e8 41 fe ff ff       	call   f0101f72 <split>
				if (Buddy[i].use_lock)
f0102131:	83 c4 10             	add    $0x10,%esp
f0102134:	83 be 20 6f 12 f0 00 	cmpl   $0x0,-0xfed90e0(%esi)
f010213b:	75 0a                	jne    f0102147 <Buddykalloc+0x102>
	}
	return NULL;
}
f010213d:	89 d8                	mov    %ebx,%eax
f010213f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102142:	5b                   	pop    %ebx
f0102143:	5e                   	pop    %esi
f0102144:	5f                   	pop    %edi
f0102145:	5d                   	pop    %ebp
f0102146:	c3                   	ret    
					spin_unlock(&Buddy[i].lock);
f0102147:	83 ec 0c             	sub    $0xc,%esp
f010214a:	89 f7                	mov    %esi,%edi
f010214c:	81 c7 28 6f 12 f0    	add    $0xf0126f28,%edi
f0102152:	57                   	push   %edi
f0102153:	e8 11 09 00 00       	call   f0102a69 <spin_unlock>
f0102158:	83 c4 10             	add    $0x10,%esp
f010215b:	eb e0                	jmp    f010213d <Buddykalloc+0xf8>
		if (Buddy[i].use_lock)
f010215d:	83 3d 5c 6f 12 f0 00 	cmpl   $0x0,0xf0126f5c
f0102164:	75 07                	jne    f010216d <Buddykalloc+0x128>
	return NULL;
f0102166:	bb 00 00 00 00       	mov    $0x0,%ebx
f010216b:	eb d0                	jmp    f010213d <Buddykalloc+0xf8>
			spin_unlock(&Buddy[i].lock);
f010216d:	83 ec 0c             	sub    $0xc,%esp
f0102170:	68 64 6f 12 f0       	push   $0xf0126f64
f0102175:	e8 ef 08 00 00       	call   f0102a69 <spin_unlock>
f010217a:	83 c4 10             	add    $0x10,%esp
f010217d:	eb e7                	jmp    f0102166 <Buddykalloc+0x121>

f010217f <kalloc>:
{
f010217f:	55                   	push   %ebp
f0102180:	89 e5                	mov    %esp,%ebp
f0102182:	83 ec 14             	sub    $0x14,%esp
	return Buddykalloc(0);
f0102185:	6a 00                	push   $0x0
f0102187:	e8 b9 fe ff ff       	call   f0102045 <Buddykalloc>
}
f010218c:	c9                   	leave  
f010218d:	c3                   	ret    

f010218e <check_free_list>:
void
check_free_list(void)
{
	struct run *p;
	bool exist;
	for (int i = 0; i < 2; i++)
f010218e:	ba 00 00 00 00       	mov    $0x0,%edx
		for (int j = 0; j <= MAX_ORDER[i]; j++)
f0102193:	b8 00 00 00 00       	mov    $0x0,%eax
f0102198:	eb 03                	jmp    f010219d <check_free_list+0xf>
f010219a:	83 c0 01             	add    $0x1,%eax
f010219d:	39 04 95 b0 6f 12 f0 	cmp    %eax,-0xfed9050(,%edx,4)
f01021a4:	7d f4                	jge    f010219a <check_free_list+0xc>
	for (int i = 0; i < 2; i++)
f01021a6:	83 c2 01             	add    $0x1,%edx
f01021a9:	83 fa 01             	cmp    $0x1,%edx
f01021ac:	7f 39                	jg     f01021e7 <check_free_list+0x59>
		for (int j = 0; j <= MAX_ORDER[i]; j++)
f01021ae:	b8 00 00 00 00       	mov    $0x0,%eax
f01021b3:	eb e8                	jmp    f010219d <check_free_list+0xf>

	//cprintf("end: 0x%x\n", end);

	for (p = kmem.free_list; p; p = p->next) {
		//cprintf("0x%x\n", p);
		assert((void *)p > (void *)end);
f01021b5:	68 f4 4a 10 f0       	push   $0xf0104af4
f01021ba:	68 2e 4a 10 f0       	push   $0xf0104a2e
f01021bf:	68 89 01 00 00       	push   $0x189
f01021c4:	68 e6 4a 10 f0       	push   $0xf0104ae6
f01021c9:	e8 ca df ff ff       	call   f0100198 <_panic>
		for (int i = 4; i < 4096; i++) 
			assert(((char *)p)[i] == 1);
f01021ce:	68 0c 4b 10 f0       	push   $0xf0104b0c
f01021d3:	68 2e 4a 10 f0       	push   $0xf0104a2e
f01021d8:	68 8b 01 00 00       	push   $0x18b
f01021dd:	68 e6 4a 10 f0       	push   $0xf0104ae6
f01021e2:	e8 b1 df ff ff       	call   f0100198 <_panic>
	for (p = kmem.free_list; p; p = p->next) {
f01021e7:	8b 0d 08 6f 12 f0    	mov    0xf0126f08,%ecx
f01021ed:	85 c9                	test   %ecx,%ecx
f01021ef:	74 2b                	je     f010221c <check_free_list+0x8e>
{
f01021f1:	55                   	push   %ebp
f01021f2:	89 e5                	mov    %esp,%ebp
f01021f4:	83 ec 08             	sub    $0x8,%esp
		assert((void *)p > (void *)end);
f01021f7:	81 f9 b0 8c 16 f0    	cmp    $0xf0168cb0,%ecx
f01021fd:	76 b6                	jbe    f01021b5 <check_free_list+0x27>
f01021ff:	8d 41 04             	lea    0x4(%ecx),%eax
f0102202:	8d 91 00 10 00 00    	lea    0x1000(%ecx),%edx
			assert(((char *)p)[i] == 1);
f0102208:	80 38 01             	cmpb   $0x1,(%eax)
f010220b:	75 c1                	jne    f01021ce <check_free_list+0x40>
f010220d:	83 c0 01             	add    $0x1,%eax
		for (int i = 4; i < 4096; i++) 
f0102210:	39 d0                	cmp    %edx,%eax
f0102212:	75 f4                	jne    f0102208 <check_free_list+0x7a>
	for (p = kmem.free_list; p; p = p->next) {
f0102214:	8b 09                	mov    (%ecx),%ecx
f0102216:	85 c9                	test   %ecx,%ecx
f0102218:	75 dd                	jne    f01021f7 <check_free_list+0x69>
	}
}
f010221a:	c9                   	leave  
f010221b:	c3                   	ret    
f010221c:	c3                   	ret    

f010221d <boot_alloc_init>:
{
f010221d:	55                   	push   %ebp
f010221e:	89 e5                	mov    %esp,%ebp
f0102220:	57                   	push   %edi
f0102221:	56                   	push   %esi
f0102222:	53                   	push   %ebx
f0102223:	83 ec 2c             	sub    $0x2c,%esp
			num = (uint32_t)((char *)P2V(4*1024*1024) - end) / PGSIZE;
f0102226:	b8 00 00 40 f0       	mov    $0xf0400000,%eax
f010222b:	2d b0 8c 16 f0       	sub    $0xf0168cb0,%eax
	char *mystart = end;
f0102230:	bf b0 8c 16 f0       	mov    $0xf0168cb0,%edi
			num = (uint32_t)((char *)P2V(4*1024*1024) - end) / PGSIZE;
f0102235:	c1 e8 0c             	shr    $0xc,%eax
f0102238:	89 45 c8             	mov    %eax,-0x38(%ebp)
f010223b:	c7 45 d0 24 6f 12 f0 	movl   $0xf0126f24,-0x30(%ebp)
f0102242:	c7 45 cc 98 6f 12 f0 	movl   $0xf0126f98,-0x34(%ebp)
f0102249:	8b 55 c8             	mov    -0x38(%ebp),%edx
f010224c:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f0102253:	e9 2c 01 00 00       	jmp    f0102384 <boot_alloc_init+0x167>
			sum *= 2;
f0102258:	01 c0                	add    %eax,%eax
			level++;
f010225a:	83 c6 01             	add    $0x1,%esi
		while (sum < num) {
f010225d:	39 c2                	cmp    %eax,%edx
f010225f:	7f f7                	jg     f0102258 <boot_alloc_init+0x3b>
			level--;
f0102261:	0f 9c c0             	setl   %al
f0102264:	0f b6 c0             	movzbl %al,%eax
f0102267:	29 c6                	sub    %eax,%esi
f0102269:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010226c:	89 45 e0             	mov    %eax,-0x20(%ebp)
		order[i] = (bool *)mystart;
f010226f:	89 3c 85 a0 6f 12 f0 	mov    %edi,-0xfed9060(,%eax,4)
		memset(order[i], 0, pow_2(level) * 2);
f0102276:	56                   	push   %esi
f0102277:	e8 0c fa ff ff       	call   f0101c88 <pow_2>
f010227c:	8d 1c 00             	lea    (%eax,%eax,1),%ebx
f010227f:	53                   	push   %ebx
f0102280:	6a 00                	push   $0x0
f0102282:	57                   	push   %edi
f0102283:	e8 bd 1f 00 00       	call   f0104245 <memset>
		mystart += pow_2(level) * 2;
f0102288:	01 fb                	add    %edi,%ebx
		MAX_ORDER[i] = level;
f010228a:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010228d:	89 34 85 b0 6f 12 f0 	mov    %esi,-0xfed9050(,%eax,4)
f0102294:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102297:	89 c7                	mov    %eax,%edi
		Buddy[i].slot = (struct Buddykmem *)mystart;
f0102299:	89 18                	mov    %ebx,(%eax)
		memset(Buddy[i].slot, 0, sizeof(struct Buddykmem) * (level + 1));
f010229b:	8d 46 01             	lea    0x1(%esi),%eax
f010229e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01022a1:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
f01022a8:	83 c4 0c             	add    $0xc,%esp
f01022ab:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f01022ae:	51                   	push   %ecx
f01022af:	6a 00                	push   $0x0
f01022b1:	53                   	push   %ebx
f01022b2:	e8 8e 1f 00 00       	call   f0104245 <memset>
		mystart += sizeof(struct Buddykmem) * (level + 1);
f01022b7:	03 5d e4             	add    -0x1c(%ebp),%ebx
f01022ba:	89 d8                	mov    %ebx,%eax
f01022bc:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f01022bf:	89 cb                	mov    %ecx,%ebx
		linkbase[i] = (struct run *)mystart;
f01022c1:	89 01                	mov    %eax,(%ecx)
		memset(linkbase[i], 0, sizeof(struct run) *(level + 1));
f01022c3:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01022c6:	8d 0c 95 00 00 00 00 	lea    0x0(,%edx,4),%ecx
f01022cd:	83 c4 0c             	add    $0xc,%esp
f01022d0:	89 4d d8             	mov    %ecx,-0x28(%ebp)
f01022d3:	51                   	push   %ecx
f01022d4:	6a 00                	push   $0x0
f01022d6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01022d9:	50                   	push   %eax
f01022da:	e8 66 1f 00 00       	call   f0104245 <memset>
		mystart += sizeof(struct run) *(level + 1);
f01022df:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01022e2:	03 45 d8             	add    -0x28(%ebp),%eax
f01022e5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		for (int j = 0; j <= level; j++) {
f01022e8:	83 c4 10             	add    $0x10,%esp
f01022eb:	b8 00 00 00 00       	mov    $0x0,%eax
f01022f0:	eb 17                	jmp    f0102309 <boot_alloc_init+0xec>
f01022f2:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
			linkbase[i][j].next = &linkbase[i][j];
f01022f9:	89 d1                	mov    %edx,%ecx
f01022fb:	03 0b                	add    (%ebx),%ecx
f01022fd:	89 09                	mov    %ecx,(%ecx)
			Buddy[i].slot[j].free_list = &linkbase[i][j];
f01022ff:	8b 0f                	mov    (%edi),%ecx
f0102301:	03 13                	add    (%ebx),%edx
f0102303:	89 14 c1             	mov    %edx,(%ecx,%eax,8)
		for (int j = 0; j <= level; j++) {
f0102306:	83 c0 01             	add    $0x1,%eax
f0102309:	39 c6                	cmp    %eax,%esi
f010230b:	7d e5                	jge    f01022f2 <boot_alloc_init+0xd5>
		start[i] = (int *)mystart;
f010230d:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0102310:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102313:	89 04 bd a8 6f 12 f0 	mov    %eax,-0xfed9058(,%edi,4)
		start[i][0] = 0;
f010231a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		for (int j = 0; j < level; j++)
f0102320:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102325:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0102328:	eb 2c                	jmp    f0102356 <boot_alloc_init+0x139>
			start[i][j + 1] = start[i][j] + pow_2(level - j);
f010232a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010232d:	8b 34 85 a8 6f 12 f0 	mov    -0xfed9058(,%eax,4),%esi
f0102334:	8d 3c 9d 00 00 00 00 	lea    0x0(,%ebx,4),%edi
f010233b:	83 ec 0c             	sub    $0xc,%esp
f010233e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102341:	29 d8                	sub    %ebx,%eax
f0102343:	50                   	push   %eax
f0102344:	e8 3f f9 ff ff       	call   f0101c88 <pow_2>
f0102349:	83 c4 10             	add    $0x10,%esp
f010234c:	03 04 9e             	add    (%esi,%ebx,4),%eax
f010234f:	89 44 3e 04          	mov    %eax,0x4(%esi,%edi,1)
		for (int j = 0; j < level; j++)
f0102353:	83 c3 01             	add    $0x1,%ebx
f0102356:	39 5d e4             	cmp    %ebx,-0x1c(%ebp)
f0102359:	7f cf                	jg     f010232a <boot_alloc_init+0x10d>
		mystart += sizeof(int) * (level + 1);
f010235b:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010235e:	03 7d d8             	add    -0x28(%ebp),%edi
	for (int i = 0; i < 2; i++) {
f0102361:	83 45 dc 01          	addl   $0x1,-0x24(%ebp)
f0102365:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102368:	83 f8 01             	cmp    $0x1,%eax
f010236b:	7f 26                	jg     f0102393 <boot_alloc_init+0x176>
f010236d:	83 45 d0 3c          	addl   $0x3c,-0x30(%ebp)
f0102371:	83 45 cc 04          	addl   $0x4,-0x34(%ebp)
			num = (uint32_t)((char *)PHYSTOP - 4*1024*1024) / PGSIZE;
f0102375:	ba 00 dc 00 00       	mov    $0xdc00,%edx
		if (i == 0)
f010237a:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010237e:	0f 84 b7 fe ff ff    	je     f010223b <boot_alloc_init+0x1e>
		int sum = 1;
f0102384:	b8 01 00 00 00       	mov    $0x1,%eax
		int level = 0;
f0102389:	be 00 00 00 00       	mov    $0x0,%esi
		while (sum < num) {
f010238e:	e9 ca fe ff ff       	jmp    f010225d <boot_alloc_init+0x40>
	base[0] = (struct run *)ROUNDUP(mystart, PGSIZE);
f0102393:	81 c7 ff 0f 00 00    	add    $0xfff,%edi
f0102399:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
f010239f:	89 3d 00 6f 12 f0    	mov    %edi,0xf0126f00
	base[1] = (struct run *)P2V(4 * 1024 * 1024);
f01023a5:	c7 05 04 6f 12 f0 00 	movl   $0xf0400000,0xf0126f04
f01023ac:	00 40 f0 
		Buddy[i].use_lock = 0;
f01023af:	c7 05 20 6f 12 f0 00 	movl   $0x0,0xf0126f20
f01023b6:	00 00 00 
		__spin_initlock(&Buddy[i].lock, name);
f01023b9:	83 ec 08             	sub    $0x8,%esp
f01023bc:	68 20 4b 10 f0       	push   $0xf0104b20
f01023c1:	68 28 6f 12 f0       	push   $0xf0126f28
f01023c6:	e8 1b 06 00 00       	call   f01029e6 <__spin_initlock>
		Buddy[i].use_lock = 0;
f01023cb:	c7 05 5c 6f 12 f0 00 	movl   $0x0,0xf0126f5c
f01023d2:	00 00 00 
		__spin_initlock(&Buddy[i].lock, name);
f01023d5:	83 c4 08             	add    $0x8,%esp
f01023d8:	68 20 4b 10 f0       	push   $0xf0104b20
f01023dd:	68 64 6f 12 f0       	push   $0xf0126f64
f01023e2:	e8 ff 05 00 00       	call   f01029e6 <__spin_initlock>
	Buddyfree_range((void *)base[0], MAX_ORDER[0]);
f01023e7:	83 c4 08             	add    $0x8,%esp
f01023ea:	ff 35 b0 6f 12 f0    	pushl  0xf0126fb0
f01023f0:	ff 35 00 6f 12 f0    	pushl  0xf0126f00
f01023f6:	e8 15 fb ff ff       	call   f0101f10 <Buddyfree_range>
	check_free_list();
f01023fb:	e8 8e fd ff ff       	call   f010218e <check_free_list>
}
f0102400:	83 c4 10             	add    $0x10,%esp
f0102403:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102406:	5b                   	pop    %ebx
f0102407:	5e                   	pop    %esi
f0102408:	5f                   	pop    %edi
f0102409:	5d                   	pop    %ebp
f010240a:	c3                   	ret    

f010240b <alloc_init>:
{
f010240b:	55                   	push   %ebp
f010240c:	89 e5                	mov    %esp,%ebp
f010240e:	83 ec 10             	sub    $0x10,%esp
	Buddyfree_range((void *)base[1], MAX_ORDER[1]);
f0102411:	ff 35 b4 6f 12 f0    	pushl  0xf0126fb4
f0102417:	ff 35 04 6f 12 f0    	pushl  0xf0126f04
f010241d:	e8 ee fa ff ff       	call   f0101f10 <Buddyfree_range>
		Buddy[i].use_lock = 1;
f0102422:	c7 05 20 6f 12 f0 01 	movl   $0x1,0xf0126f20
f0102429:	00 00 00 
f010242c:	c7 05 5c 6f 12 f0 01 	movl   $0x1,0xf0126f5c
f0102433:	00 00 00 
	check_free_list();
f0102436:	e8 53 fd ff ff       	call   f010218e <check_free_list>
}
f010243b:	83 c4 10             	add    $0x10,%esp
f010243e:	c9                   	leave  
f010243f:	c3                   	ret    

f0102440 <mpentry_start>:
.set PROT_MODE_DSEG, 0x10	# kernel data segment selector

.code16           
.globl mpentry_start
mpentry_start:
	cli            
f0102440:	fa                   	cli    

	xorw    %ax, %ax
f0102441:	31 c0                	xor    %eax,%eax
	movw    %ax, %ds
f0102443:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0102445:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0102447:	8e d0                	mov    %eax,%ss

	lgdt    MPBOOTPHYS(gdtdesc)
f0102449:	0f 01 16             	lgdtl  (%esi)
f010244c:	74 70                	je     f01024be <mpsearch1+0x3>
	movl    %cr0, %eax
f010244e:	0f 20 c0             	mov    %cr0,%eax
	orl     $CR0_PE, %eax
f0102451:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
f0102455:	0f 22 c0             	mov    %eax,%cr0

	ljmpl   $(PROT_MODE_CSEG), $(MPBOOTPHYS(start32))
f0102458:	66 ea 20 70 00 00    	ljmpw  $0x0,$0x7020
f010245e:	08 00                	or     %al,(%eax)

f0102460 <start32>:

.code32
start32:
	movw    $(PROT_MODE_DSEG), %ax
f0102460:	66 b8 10 00          	mov    $0x10,%ax
	movw    %ax, %ds
f0102464:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0102466:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0102468:	8e d0                	mov    %eax,%ss
	movw    $0, %ax
f010246a:	66 b8 00 00          	mov    $0x0,%ax
	movw    %ax, %fs
f010246e:	8e e0                	mov    %eax,%fs
	movw    %ax, %gs
f0102470:	8e e8                	mov    %eax,%gs

	# Set up initial page table. We cannot use kern_pgdir yet because
	# we are still running at a low EIP.
	movl    $(RELOC(entry_pgdir)), %eax
f0102472:	b8 00 c0 11 00       	mov    $0x11c000,%eax
	movl    %eax, %cr3
f0102477:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl    %cr0, %eax
f010247a:	0f 20 c0             	mov    %cr0,%eax
	orl     $(CR0_PE|CR0_PG|CR0_WP), %eax
f010247d:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl    %eax, %cr0
f0102482:	0f 22 c0             	mov    %eax,%cr0

	# Switch to the per-cpu stack allocated in boot_aps()
	movl    mpentry_kstack, %esp
f0102485:	8b 25 48 66 12 f0    	mov    0xf0126648,%esp
	movl    $0x0, %ebp       # nuke frame pointer
f010248b:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Call mp_main().  (Exercise for the reader: why the indirect call?)
	movl    $mp_main, %eax
f0102490:	b8 4c 01 10 f0       	mov    $0xf010014c,%eax
	call    *%eax
f0102495:	ff d0                	call   *%eax

f0102497 <spin>:

	# If mp_main returns (it shouldn't), loop.
spin:
	jmp     spin
f0102497:	eb fe                	jmp    f0102497 <spin>
f0102499:	8d 76 00             	lea    0x0(%esi),%esi

f010249c <gdt>:
	...
f01024a4:	ff                   	(bad)  
f01024a5:	ff 00                	incl   (%eax)
f01024a7:	00 00                	add    %al,(%eax)
f01024a9:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
f01024b0:	00                   	.byte 0x0
f01024b1:	92                   	xchg   %eax,%edx
f01024b2:	cf                   	iret   
	...

f01024b4 <gdtdesc>:
f01024b4:	17                   	pop    %ss
f01024b5:	00 5c 70 00          	add    %bl,0x0(%eax,%esi,2)
	...

f01024ba <mpentry_end>:
	.word   0x17				# sizeof(gdt) - 1
	.long   MPBOOTPHYS(gdt)			# address gdt

.globl mpentry_end
mpentry_end:
	nop
f01024ba:	90                   	nop

f01024bb <mpsearch1>:
}

// Look for an MP structure in the len bytes at physical address addr.
static struct mp *
mpsearch1(physaddr_t a, int len)
{
f01024bb:	55                   	push   %ebp
f01024bc:	89 e5                	mov    %esp,%ebp
f01024be:	57                   	push   %edi
f01024bf:	56                   	push   %esi
f01024c0:	53                   	push   %ebx
f01024c1:	83 ec 0c             	sub    $0xc,%esp
	struct mp *mp = P2V(a), *end = P2V(a + len);
f01024c4:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
f01024ca:	8d b4 10 00 00 00 f0 	lea    -0x10000000(%eax,%edx,1),%esi

	for (; mp < end; mp++)
f01024d1:	eb 03                	jmp    f01024d6 <mpsearch1+0x1b>
f01024d3:	83 c3 10             	add    $0x10,%ebx
f01024d6:	39 f3                	cmp    %esi,%ebx
f01024d8:	73 2e                	jae    f0102508 <mpsearch1+0x4d>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f01024da:	83 ec 04             	sub    $0x4,%esp
f01024dd:	6a 04                	push   $0x4
f01024df:	68 2a 4b 10 f0       	push   $0xf0104b2a
f01024e4:	53                   	push   %ebx
f01024e5:	e8 23 1e 00 00       	call   f010430d <memcmp>
f01024ea:	83 c4 10             	add    $0x10,%esp
f01024ed:	85 c0                	test   %eax,%eax
f01024ef:	75 e2                	jne    f01024d3 <mpsearch1+0x18>
f01024f1:	89 da                	mov    %ebx,%edx
f01024f3:	8d 7b 10             	lea    0x10(%ebx),%edi
		sum += ((uint8_t *)addr)[i];
f01024f6:	0f b6 0a             	movzbl (%edx),%ecx
f01024f9:	01 c8                	add    %ecx,%eax
f01024fb:	83 c2 01             	add    $0x1,%edx
	for (i = 0; i < len; i++)
f01024fe:	39 fa                	cmp    %edi,%edx
f0102500:	75 f4                	jne    f01024f6 <mpsearch1+0x3b>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0102502:	84 c0                	test   %al,%al
f0102504:	75 cd                	jne    f01024d3 <mpsearch1+0x18>
f0102506:	eb 05                	jmp    f010250d <mpsearch1+0x52>
		    sum(mp, sizeof(*mp)) == 0)
			return mp;
	return NULL;
f0102508:	bb 00 00 00 00       	mov    $0x0,%ebx
}
f010250d:	89 d8                	mov    %ebx,%eax
f010250f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102512:	5b                   	pop    %ebx
f0102513:	5e                   	pop    %esi
f0102514:	5f                   	pop    %edi
f0102515:	5d                   	pop    %ebp
f0102516:	c3                   	ret    

f0102517 <mp_init>:
	return conf;
}

void
mp_init(void)
{
f0102517:	55                   	push   %ebp
f0102518:	89 e5                	mov    %esp,%ebp
f010251a:	57                   	push   %edi
f010251b:	56                   	push   %esi
f010251c:	53                   	push   %ebx
f010251d:	83 ec 1c             	sub    $0x1c,%esp
	struct mpconf *conf;
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
f0102520:	c7 05 e0 75 12 f0 20 	movl   $0xf0127020,0xf01275e0
f0102527:	70 12 f0 
	if ((p = *(uint16_t *) (bda + 0x0E))) {
f010252a:	0f b7 05 0e 04 00 f0 	movzwl 0xf000040e,%eax
f0102531:	85 c0                	test   %eax,%eax
f0102533:	74 53                	je     f0102588 <mp_init+0x71>
		p <<= 4;	// Translate from segment to PA
f0102535:	c1 e0 04             	shl    $0x4,%eax
		if ((mp = mpsearch1(p, 1024)))
f0102538:	ba 00 04 00 00       	mov    $0x400,%edx
f010253d:	e8 79 ff ff ff       	call   f01024bb <mpsearch1>
f0102542:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102545:	85 c0                	test   %eax,%eax
f0102547:	74 5f                	je     f01025a8 <mp_init+0x91>
	if (mp->physaddr == 0 || mp->type != 0) {
f0102549:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f010254c:	8b 41 04             	mov    0x4(%ecx),%eax
f010254f:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102552:	85 c0                	test   %eax,%eax
f0102554:	74 6d                	je     f01025c3 <mp_init+0xac>
f0102556:	80 79 0b 00          	cmpb   $0x0,0xb(%ecx)
f010255a:	75 67                	jne    f01025c3 <mp_init+0xac>
	conf = (struct mpconf *) P2V(mp->physaddr);
f010255c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010255f:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
f0102565:	89 de                	mov    %ebx,%esi
	if (memcmp(conf, "PCMP", 4) != 0) {
f0102567:	83 ec 04             	sub    $0x4,%esp
f010256a:	6a 04                	push   $0x4
f010256c:	68 2f 4b 10 f0       	push   $0xf0104b2f
f0102571:	53                   	push   %ebx
f0102572:	e8 96 1d 00 00       	call   f010430d <memcmp>
f0102577:	83 c4 10             	add    $0x10,%esp
f010257a:	85 c0                	test   %eax,%eax
f010257c:	75 5a                	jne    f01025d8 <mp_init+0xc1>
f010257e:	0f b7 7b 04          	movzwl 0x4(%ebx),%edi
f0102582:	01 df                	add    %ebx,%edi
	sum = 0;
f0102584:	89 c2                	mov    %eax,%edx
f0102586:	eb 6d                	jmp    f01025f5 <mp_init+0xde>
		p = *(uint16_t *) (bda + 0x13) * 1024;
f0102588:	0f b7 05 13 04 00 f0 	movzwl 0xf0000413,%eax
f010258f:	c1 e0 0a             	shl    $0xa,%eax
		if ((mp = mpsearch1(p - 1024, 1024)))
f0102592:	2d 00 04 00 00       	sub    $0x400,%eax
f0102597:	ba 00 04 00 00       	mov    $0x400,%edx
f010259c:	e8 1a ff ff ff       	call   f01024bb <mpsearch1>
f01025a1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01025a4:	85 c0                	test   %eax,%eax
f01025a6:	75 a1                	jne    f0102549 <mp_init+0x32>
	return mpsearch1(0xF0000, 0x10000);
f01025a8:	ba 00 00 01 00       	mov    $0x10000,%edx
f01025ad:	b8 00 00 0f 00       	mov    $0xf0000,%eax
f01025b2:	e8 04 ff ff ff       	call   f01024bb <mpsearch1>
f01025b7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	if ((mp = mpsearch()) == 0)
f01025ba:	85 c0                	test   %eax,%eax
f01025bc:	75 8b                	jne    f0102549 <mp_init+0x32>
f01025be:	e9 97 01 00 00       	jmp    f010275a <mp_init+0x243>
		cprintf("SMP: Default configurations not implemented\n");
f01025c3:	83 ec 0c             	sub    $0xc,%esp
f01025c6:	68 54 4b 10 f0       	push   $0xf0104b54
f01025cb:	e8 b2 e1 ff ff       	call   f0100782 <cprintf>
f01025d0:	83 c4 10             	add    $0x10,%esp
f01025d3:	e9 82 01 00 00       	jmp    f010275a <mp_init+0x243>
		cprintf("SMP: Incorrect MP configuration table signature\n");
f01025d8:	83 ec 0c             	sub    $0xc,%esp
f01025db:	68 84 4b 10 f0       	push   $0xf0104b84
f01025e0:	e8 9d e1 ff ff       	call   f0100782 <cprintf>
f01025e5:	83 c4 10             	add    $0x10,%esp
f01025e8:	e9 6d 01 00 00       	jmp    f010275a <mp_init+0x243>
		sum += ((uint8_t *)addr)[i];
f01025ed:	0f b6 0b             	movzbl (%ebx),%ecx
f01025f0:	01 ca                	add    %ecx,%edx
f01025f2:	83 c3 01             	add    $0x1,%ebx
	for (i = 0; i < len; i++)
f01025f5:	39 fb                	cmp    %edi,%ebx
f01025f7:	75 f4                	jne    f01025ed <mp_init+0xd6>
	if (sum(conf, conf->length) != 0) {
f01025f9:	84 d2                	test   %dl,%dl
f01025fb:	75 16                	jne    f0102613 <mp_init+0xfc>
	if (conf->version != 1 && conf->version != 4) {
f01025fd:	0f b6 56 06          	movzbl 0x6(%esi),%edx
f0102601:	80 fa 01             	cmp    $0x1,%dl
f0102604:	74 05                	je     f010260b <mp_init+0xf4>
f0102606:	80 fa 04             	cmp    $0x4,%dl
f0102609:	75 1d                	jne    f0102628 <mp_init+0x111>
f010260b:	0f b7 4e 28          	movzwl 0x28(%esi),%ecx
f010260f:	01 d9                	add    %ebx,%ecx
f0102611:	eb 36                	jmp    f0102649 <mp_init+0x132>
		cprintf("SMP: Bad MP configuration checksum\n");
f0102613:	83 ec 0c             	sub    $0xc,%esp
f0102616:	68 b8 4b 10 f0       	push   $0xf0104bb8
f010261b:	e8 62 e1 ff ff       	call   f0100782 <cprintf>
f0102620:	83 c4 10             	add    $0x10,%esp
f0102623:	e9 32 01 00 00       	jmp    f010275a <mp_init+0x243>
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
f0102628:	83 ec 08             	sub    $0x8,%esp
f010262b:	0f b6 d2             	movzbl %dl,%edx
f010262e:	52                   	push   %edx
f010262f:	68 dc 4b 10 f0       	push   $0xf0104bdc
f0102634:	e8 49 e1 ff ff       	call   f0100782 <cprintf>
f0102639:	83 c4 10             	add    $0x10,%esp
f010263c:	e9 19 01 00 00       	jmp    f010275a <mp_init+0x243>
		sum += ((uint8_t *)addr)[i];
f0102641:	0f b6 13             	movzbl (%ebx),%edx
f0102644:	01 d0                	add    %edx,%eax
f0102646:	83 c3 01             	add    $0x1,%ebx
	for (i = 0; i < len; i++)
f0102649:	39 d9                	cmp    %ebx,%ecx
f010264b:	75 f4                	jne    f0102641 <mp_init+0x12a>
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f010264d:	02 46 2a             	add    0x2a(%esi),%al
f0102650:	75 29                	jne    f010267b <mp_init+0x164>
	if ((conf = mpconfig(&mp)) == 0)
f0102652:	81 7d e0 00 00 00 10 	cmpl   $0x10000000,-0x20(%ebp)
f0102659:	0f 84 fb 00 00 00    	je     f010275a <mp_init+0x243>
		return;
	ismp = 1;
f010265f:	c7 05 00 70 12 f0 01 	movl   $0x1,0xf0127000
f0102666:	00 00 00 
	lapicaddr = conf->lapicaddr;
f0102669:	8b 46 24             	mov    0x24(%esi),%eax
f010266c:	a3 00 80 16 f0       	mov    %eax,0xf0168000

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0102671:	8d 7e 2c             	lea    0x2c(%esi),%edi
f0102674:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102679:	eb 53                	jmp    f01026ce <mp_init+0x1b7>
		cprintf("SMP: Bad MP configuration extended checksum\n");
f010267b:	83 ec 0c             	sub    $0xc,%esp
f010267e:	68 fc 4b 10 f0       	push   $0xf0104bfc
f0102683:	e8 fa e0 ff ff       	call   f0100782 <cprintf>
f0102688:	83 c4 10             	add    $0x10,%esp
f010268b:	e9 ca 00 00 00       	jmp    f010275a <mp_init+0x243>
		switch (*p) {
		case MPPROC:
			proc = (struct mpproc *)p;
			if (proc->flags & MPPROC_BOOT)
f0102690:	f6 47 03 02          	testb  $0x2,0x3(%edi)
f0102694:	74 14                	je     f01026aa <mp_init+0x193>
				bootcpu = &cpus[ncpu];
f0102696:	69 05 e4 75 12 f0 b8 	imul   $0xb8,0xf01275e4,%eax
f010269d:	00 00 00 
f01026a0:	05 20 70 12 f0       	add    $0xf0127020,%eax
f01026a5:	a3 e0 75 12 f0       	mov    %eax,0xf01275e0
			if (ncpu < NCPU) {
f01026aa:	a1 e4 75 12 f0       	mov    0xf01275e4,%eax
f01026af:	83 f8 07             	cmp    $0x7,%eax
f01026b2:	7f 32                	jg     f01026e6 <mp_init+0x1cf>
				cpus[ncpu].cpu_id = ncpu;
f01026b4:	69 d0 b8 00 00 00    	imul   $0xb8,%eax,%edx
f01026ba:	88 82 20 70 12 f0    	mov    %al,-0xfed8fe0(%edx)
				ncpu++;
f01026c0:	83 c0 01             	add    $0x1,%eax
f01026c3:	a3 e4 75 12 f0       	mov    %eax,0xf01275e4
			} else {
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
					proc->apicid);
			}
			p += sizeof(struct mpproc);
f01026c8:	83 c7 14             	add    $0x14,%edi
	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f01026cb:	83 c3 01             	add    $0x1,%ebx
f01026ce:	0f b7 46 22          	movzwl 0x22(%esi),%eax
f01026d2:	39 d8                	cmp    %ebx,%eax
f01026d4:	76 4b                	jbe    f0102721 <mp_init+0x20a>
		switch (*p) {
f01026d6:	0f b6 07             	movzbl (%edi),%eax
f01026d9:	84 c0                	test   %al,%al
f01026db:	74 b3                	je     f0102690 <mp_init+0x179>
f01026dd:	3c 04                	cmp    $0x4,%al
f01026df:	77 1c                	ja     f01026fd <mp_init+0x1e6>
			continue;
		case MPBUS:
		case MPIOAPIC:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
f01026e1:	83 c7 08             	add    $0x8,%edi
			continue;
f01026e4:	eb e5                	jmp    f01026cb <mp_init+0x1b4>
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
f01026e6:	83 ec 08             	sub    $0x8,%esp
f01026e9:	0f b6 47 01          	movzbl 0x1(%edi),%eax
f01026ed:	50                   	push   %eax
f01026ee:	68 2c 4c 10 f0       	push   $0xf0104c2c
f01026f3:	e8 8a e0 ff ff       	call   f0100782 <cprintf>
f01026f8:	83 c4 10             	add    $0x10,%esp
f01026fb:	eb cb                	jmp    f01026c8 <mp_init+0x1b1>
		default:
			cprintf("mpinit: unknown config type %x\n", *p);
f01026fd:	83 ec 08             	sub    $0x8,%esp
		switch (*p) {
f0102700:	0f b6 c0             	movzbl %al,%eax
			cprintf("mpinit: unknown config type %x\n", *p);
f0102703:	50                   	push   %eax
f0102704:	68 54 4c 10 f0       	push   $0xf0104c54
f0102709:	e8 74 e0 ff ff       	call   f0100782 <cprintf>
			ismp = 0;
f010270e:	c7 05 00 70 12 f0 00 	movl   $0x0,0xf0127000
f0102715:	00 00 00 
			i = conf->entry;
f0102718:	0f b7 5e 22          	movzwl 0x22(%esi),%ebx
f010271c:	83 c4 10             	add    $0x10,%esp
f010271f:	eb aa                	jmp    f01026cb <mp_init+0x1b4>
		}
	}

	bootcpu->cpu_status = CPU_STARTED;
f0102721:	a1 e0 75 12 f0       	mov    0xf01275e0,%eax
f0102726:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	if (!ismp) {
f010272d:	83 3d 00 70 12 f0 00 	cmpl   $0x0,0xf0127000
f0102734:	75 2c                	jne    f0102762 <mp_init+0x24b>
		// Didn't like what we found; fall back to no MP.
		ncpu = 1;
f0102736:	c7 05 e4 75 12 f0 01 	movl   $0x1,0xf01275e4
f010273d:	00 00 00 
		lapicaddr = 0;
f0102740:	c7 05 00 80 16 f0 00 	movl   $0x0,0xf0168000
f0102747:	00 00 00 
		cprintf("SMP: configuration not found, SMP disabled\n");
f010274a:	83 ec 0c             	sub    $0xc,%esp
f010274d:	68 74 4c 10 f0       	push   $0xf0104c74
f0102752:	e8 2b e0 ff ff       	call   f0100782 <cprintf>
		return;
f0102757:	83 c4 10             	add    $0x10,%esp
		// switch to getting interrupts from the LAPIC.
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
		outb(0x22, 0x70);   // Select IMCR
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
	}
}
f010275a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010275d:	5b                   	pop    %ebx
f010275e:	5e                   	pop    %esi
f010275f:	5f                   	pop    %edi
f0102760:	5d                   	pop    %ebp
f0102761:	c3                   	ret    
	cprintf("SMP: CPU %d found %d CPU(s)\n", bootcpu->cpu_id,  ncpu);
f0102762:	83 ec 04             	sub    $0x4,%esp
f0102765:	ff 35 e4 75 12 f0    	pushl  0xf01275e4
f010276b:	0f b6 00             	movzbl (%eax),%eax
f010276e:	50                   	push   %eax
f010276f:	68 34 4b 10 f0       	push   $0xf0104b34
f0102774:	e8 09 e0 ff ff       	call   f0100782 <cprintf>
	if (mp->imcrp) {
f0102779:	83 c4 10             	add    $0x10,%esp
f010277c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010277f:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
f0102783:	74 d5                	je     f010275a <mp_init+0x243>
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
f0102785:	83 ec 0c             	sub    $0xc,%esp
f0102788:	68 a0 4c 10 f0       	push   $0xf0104ca0
f010278d:	e8 f0 df ff ff       	call   f0100782 <cprintf>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102792:	b8 70 00 00 00       	mov    $0x70,%eax
f0102797:	ba 22 00 00 00       	mov    $0x22,%edx
f010279c:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010279d:	ba 23 00 00 00       	mov    $0x23,%edx
f01027a2:	ec                   	in     (%dx),%al
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
f01027a3:	83 c8 01             	or     $0x1,%eax
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01027a6:	ee                   	out    %al,(%dx)
f01027a7:	83 c4 10             	add    $0x10,%esp
f01027aa:	eb ae                	jmp    f010275a <mp_init+0x243>

f01027ac <lapicw>:
physaddr_t lapicaddr;        // Initialized in mpconfig.c
volatile uint32_t *lapic;

static void
lapicw(int index, int value)
{
f01027ac:	55                   	push   %ebp
f01027ad:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
f01027af:	8b 0d 04 80 16 f0    	mov    0xf0168004,%ecx
f01027b5:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f01027b8:	89 10                	mov    %edx,(%eax)
	lapic[ID];  // wait for write to finish, by reading
f01027ba:	a1 04 80 16 f0       	mov    0xf0168004,%eax
f01027bf:	8b 40 20             	mov    0x20(%eax),%eax
}
f01027c2:	5d                   	pop    %ebp
f01027c3:	c3                   	ret    

f01027c4 <cpunum>:
	lapicw(TPR, 0);
}

int
cpunum(void)
{
f01027c4:	55                   	push   %ebp
f01027c5:	89 e5                	mov    %esp,%ebp
	if (lapic)
f01027c7:	8b 15 04 80 16 f0    	mov    0xf0168004,%edx
		return lapic[ID] >> 24;
	return 0;
f01027cd:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lapic)
f01027d2:	85 d2                	test   %edx,%edx
f01027d4:	74 06                	je     f01027dc <cpunum+0x18>
		return lapic[ID] >> 24;
f01027d6:	8b 42 20             	mov    0x20(%edx),%eax
f01027d9:	c1 e8 18             	shr    $0x18,%eax
}
f01027dc:	5d                   	pop    %ebp
f01027dd:	c3                   	ret    

f01027de <lapic_init>:
	if (!lapicaddr)
f01027de:	a1 00 80 16 f0       	mov    0xf0168000,%eax
f01027e3:	85 c0                	test   %eax,%eax
f01027e5:	75 02                	jne    f01027e9 <lapic_init+0xb>
f01027e7:	f3 c3                	repz ret 
{
f01027e9:	55                   	push   %ebp
f01027ea:	89 e5                	mov    %esp,%ebp
	lapic = (uint32_t *)lapicaddr;
f01027ec:	a3 04 80 16 f0       	mov    %eax,0xf0168004
	lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
f01027f1:	ba 3f 01 00 00       	mov    $0x13f,%edx
f01027f6:	b8 3c 00 00 00       	mov    $0x3c,%eax
f01027fb:	e8 ac ff ff ff       	call   f01027ac <lapicw>
	lapicw(TDCR, X1);
f0102800:	ba 0b 00 00 00       	mov    $0xb,%edx
f0102805:	b8 f8 00 00 00       	mov    $0xf8,%eax
f010280a:	e8 9d ff ff ff       	call   f01027ac <lapicw>
	lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
f010280f:	ba 20 00 02 00       	mov    $0x20020,%edx
f0102814:	b8 c8 00 00 00       	mov    $0xc8,%eax
f0102819:	e8 8e ff ff ff       	call   f01027ac <lapicw>
	lapicw(TICR, 10000000); 
f010281e:	ba 80 96 98 00       	mov    $0x989680,%edx
f0102823:	b8 e0 00 00 00       	mov    $0xe0,%eax
f0102828:	e8 7f ff ff ff       	call   f01027ac <lapicw>
	if (thiscpu != bootcpu)
f010282d:	e8 92 ff ff ff       	call   f01027c4 <cpunum>
f0102832:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f0102838:	05 20 70 12 f0       	add    $0xf0127020,%eax
f010283d:	39 05 e0 75 12 f0    	cmp    %eax,0xf01275e0
f0102843:	74 0f                	je     f0102854 <lapic_init+0x76>
		lapicw(LINT0, MASKED);
f0102845:	ba 00 00 01 00       	mov    $0x10000,%edx
f010284a:	b8 d4 00 00 00       	mov    $0xd4,%eax
f010284f:	e8 58 ff ff ff       	call   f01027ac <lapicw>
	lapicw(LINT1, MASKED);
f0102854:	ba 00 00 01 00       	mov    $0x10000,%edx
f0102859:	b8 d8 00 00 00       	mov    $0xd8,%eax
f010285e:	e8 49 ff ff ff       	call   f01027ac <lapicw>
	if (((lapic[VER]>>16) & 0xFF) >= 4)
f0102863:	a1 04 80 16 f0       	mov    0xf0168004,%eax
f0102868:	8b 40 30             	mov    0x30(%eax),%eax
f010286b:	c1 e8 10             	shr    $0x10,%eax
f010286e:	3c 03                	cmp    $0x3,%al
f0102870:	77 7c                	ja     f01028ee <lapic_init+0x110>
	lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
f0102872:	ba 33 00 00 00       	mov    $0x33,%edx
f0102877:	b8 dc 00 00 00       	mov    $0xdc,%eax
f010287c:	e8 2b ff ff ff       	call   f01027ac <lapicw>
	lapicw(ESR, 0);
f0102881:	ba 00 00 00 00       	mov    $0x0,%edx
f0102886:	b8 a0 00 00 00       	mov    $0xa0,%eax
f010288b:	e8 1c ff ff ff       	call   f01027ac <lapicw>
	lapicw(ESR, 0);
f0102890:	ba 00 00 00 00       	mov    $0x0,%edx
f0102895:	b8 a0 00 00 00       	mov    $0xa0,%eax
f010289a:	e8 0d ff ff ff       	call   f01027ac <lapicw>
	lapicw(EOI, 0);
f010289f:	ba 00 00 00 00       	mov    $0x0,%edx
f01028a4:	b8 2c 00 00 00       	mov    $0x2c,%eax
f01028a9:	e8 fe fe ff ff       	call   f01027ac <lapicw>
	lapicw(ICRHI, 0);
f01028ae:	ba 00 00 00 00       	mov    $0x0,%edx
f01028b3:	b8 c4 00 00 00       	mov    $0xc4,%eax
f01028b8:	e8 ef fe ff ff       	call   f01027ac <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
f01028bd:	ba 00 85 08 00       	mov    $0x88500,%edx
f01028c2:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01028c7:	e8 e0 fe ff ff       	call   f01027ac <lapicw>
	while(lapic[ICRLO] & DELIVS)
f01028cc:	8b 15 04 80 16 f0    	mov    0xf0168004,%edx
f01028d2:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f01028d8:	f6 c4 10             	test   $0x10,%ah
f01028db:	75 f5                	jne    f01028d2 <lapic_init+0xf4>
	lapicw(TPR, 0);
f01028dd:	ba 00 00 00 00       	mov    $0x0,%edx
f01028e2:	b8 20 00 00 00       	mov    $0x20,%eax
f01028e7:	e8 c0 fe ff ff       	call   f01027ac <lapicw>
}
f01028ec:	5d                   	pop    %ebp
f01028ed:	c3                   	ret    
		lapicw(PCINT, MASKED);
f01028ee:	ba 00 00 01 00       	mov    $0x10000,%edx
f01028f3:	b8 d0 00 00 00       	mov    $0xd0,%eax
f01028f8:	e8 af fe ff ff       	call   f01027ac <lapicw>
f01028fd:	e9 70 ff ff ff       	jmp    f0102872 <lapic_init+0x94>

f0102902 <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
	if (lapic)
f0102902:	83 3d 04 80 16 f0 00 	cmpl   $0x0,0xf0168004
f0102909:	74 14                	je     f010291f <lapic_eoi+0x1d>
{
f010290b:	55                   	push   %ebp
f010290c:	89 e5                	mov    %esp,%ebp
		lapicw(EOI, 0);
f010290e:	ba 00 00 00 00       	mov    $0x0,%edx
f0102913:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0102918:	e8 8f fe ff ff       	call   f01027ac <lapicw>
}
f010291d:	5d                   	pop    %ebp
f010291e:	c3                   	ret    
f010291f:	f3 c3                	repz ret 

f0102921 <lapic_startap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startap(uint8_t apicid, uint32_t addr)
{
f0102921:	55                   	push   %ebp
f0102922:	89 e5                	mov    %esp,%ebp
f0102924:	56                   	push   %esi
f0102925:	53                   	push   %ebx
f0102926:	8b 75 08             	mov    0x8(%ebp),%esi
f0102929:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010292c:	b8 0f 00 00 00       	mov    $0xf,%eax
f0102931:	ba 70 00 00 00       	mov    $0x70,%edx
f0102936:	ee                   	out    %al,(%dx)
f0102937:	b8 0a 00 00 00       	mov    $0xa,%eax
f010293c:	ba 71 00 00 00       	mov    $0x71,%edx
f0102941:	ee                   	out    %al,(%dx)
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t *)P2V((0x40 << 4 | 0x67));  // Warm reset vector
	wrv[0] = 0;
f0102942:	66 c7 05 67 04 00 f0 	movw   $0x0,0xf0000467
f0102949:	00 00 
	wrv[1] = addr >> 4;
f010294b:	89 d8                	mov    %ebx,%eax
f010294d:	c1 e8 04             	shr    $0x4,%eax
f0102950:	66 a3 69 04 00 f0    	mov    %ax,0xf0000469

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid << 24);
f0102956:	c1 e6 18             	shl    $0x18,%esi
f0102959:	89 f2                	mov    %esi,%edx
f010295b:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0102960:	e8 47 fe ff ff       	call   f01027ac <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
f0102965:	ba 00 c5 00 00       	mov    $0xc500,%edx
f010296a:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010296f:	e8 38 fe ff ff       	call   f01027ac <lapicw>
	microdelay(200);
	lapicw(ICRLO, INIT | LEVEL);
f0102974:	ba 00 85 00 00       	mov    $0x8500,%edx
f0102979:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010297e:	e8 29 fe ff ff       	call   f01027ac <lapicw>
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0102983:	c1 eb 0c             	shr    $0xc,%ebx
f0102986:	80 cf 06             	or     $0x6,%bh
		lapicw(ICRHI, apicid << 24);
f0102989:	89 f2                	mov    %esi,%edx
f010298b:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0102990:	e8 17 fe ff ff       	call   f01027ac <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0102995:	89 da                	mov    %ebx,%edx
f0102997:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010299c:	e8 0b fe ff ff       	call   f01027ac <lapicw>
		lapicw(ICRHI, apicid << 24);
f01029a1:	89 f2                	mov    %esi,%edx
f01029a3:	b8 c4 00 00 00       	mov    $0xc4,%eax
f01029a8:	e8 ff fd ff ff       	call   f01027ac <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f01029ad:	89 da                	mov    %ebx,%edx
f01029af:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01029b4:	e8 f3 fd ff ff       	call   f01027ac <lapicw>
		microdelay(200);
	}
}
f01029b9:	5b                   	pop    %ebx
f01029ba:	5e                   	pop    %esi
f01029bb:	5d                   	pop    %ebp
f01029bc:	c3                   	ret    

f01029bd <lapic_ipi>:

void
lapic_ipi(int vector)
{
f01029bd:	55                   	push   %ebp
f01029be:	89 e5                	mov    %esp,%ebp
	lapicw(ICRLO, OTHERS | FIXED | vector);
f01029c0:	8b 55 08             	mov    0x8(%ebp),%edx
f01029c3:	81 ca 00 00 0c 00    	or     $0xc0000,%edx
f01029c9:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01029ce:	e8 d9 fd ff ff       	call   f01027ac <lapicw>
	while (lapic[ICRLO] & DELIVS)
f01029d3:	8b 15 04 80 16 f0    	mov    0xf0168004,%edx
f01029d9:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f01029df:	f6 c4 10             	test   $0x10,%ah
f01029e2:	75 f5                	jne    f01029d9 <lapic_ipi+0x1c>
		;
}
f01029e4:	5d                   	pop    %ebp
f01029e5:	c3                   	ret    

f01029e6 <__spin_initlock>:
#endif
};

void
__spin_initlock(struct spinlock *lk, char *name)
{
f01029e6:	55                   	push   %ebp
f01029e7:	89 e5                	mov    %esp,%ebp
f01029e9:	8b 45 08             	mov    0x8(%ebp),%eax
	// TODO: Your code here.
#ifdef DEBUG_MCSLOCK
	lk->locked = NULL;
f01029ec:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
#else
	lk->locked = 0;
#endif
	lk->name = name;
f01029f2:	8b 55 0c             	mov    0xc(%ebp),%edx
f01029f5:	89 50 04             	mov    %edx,0x4(%eax)
	lk->cpu = 0;
f01029f8:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
f01029ff:	5d                   	pop    %ebp
f0102a00:	c3                   	ret    

f0102a01 <spin_lock>:
// other CPUs to waste time spinning to acquire it.

#ifdef DEBUG_MCSLOCK
void
spin_lock(struct spinlock *lk)
{
f0102a01:	55                   	push   %ebp
f0102a02:	89 e5                	mov    %esp,%ebp
f0102a04:	57                   	push   %edi
f0102a05:	56                   	push   %esi
f0102a06:	53                   	push   %ebx
f0102a07:	83 ec 0c             	sub    $0xc,%esp
f0102a0a:	8b 75 08             	mov    0x8(%ebp),%esi
	struct mcslock_node *me = &thiscpu->node;
f0102a0d:	e8 b2 fd ff ff       	call   f01027c4 <cpunum>
f0102a12:	89 c3                	mov    %eax,%ebx
f0102a14:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f0102a1a:	8d b8 d0 70 12 f0    	lea    -0xfed8f30(%eax),%edi
	struct mcslock_node *tmp = me;
	me->next = NULL;
f0102a20:	c7 80 d4 70 12 f0 00 	movl   $0x0,-0xfed8f2c(%eax)
f0102a27:	00 00 00 
	pushcli();
f0102a2a:	e8 84 f0 ff ff       	call   f0101ab3 <pushcli>
	asm volatile("lock; xchgl %0, %1"
f0102a2f:	89 f8                	mov    %edi,%eax
f0102a31:	f0 87 06             	lock xchg %eax,(%esi)
	struct mcslock_node *pre = Xchg(&lk->locked, tmp);
	if (pre == NULL)
f0102a34:	85 c0                	test   %eax,%eax
f0102a36:	74 29                	je     f0102a61 <spin_lock+0x60>
		return;
	me->waiting = 1;
f0102a38:	69 d3 b8 00 00 00    	imul   $0xb8,%ebx,%edx
f0102a3e:	81 c2 20 70 12 f0    	add    $0xf0127020,%edx
f0102a44:	c7 82 b0 00 00 00 01 	movl   $0x1,0xb0(%edx)
f0102a4b:	00 00 00 
	asm volatile("" : : : "memory");
	pre->next = me;
f0102a4e:	89 78 04             	mov    %edi,0x4(%eax)
	while (me->waiting) 
f0102a51:	89 d0                	mov    %edx,%eax
f0102a53:	eb 02                	jmp    f0102a57 <spin_lock+0x56>
		asm volatile("pause");
f0102a55:	f3 90                	pause  
	while (me->waiting) 
f0102a57:	8b 90 b0 00 00 00    	mov    0xb0(%eax),%edx
f0102a5d:	85 d2                	test   %edx,%edx
f0102a5f:	75 f4                	jne    f0102a55 <spin_lock+0x54>
}
f0102a61:	83 c4 0c             	add    $0xc,%esp
f0102a64:	5b                   	pop    %ebx
f0102a65:	5e                   	pop    %esi
f0102a66:	5f                   	pop    %edi
f0102a67:	5d                   	pop    %ebp
f0102a68:	c3                   	ret    

f0102a69 <spin_unlock>:

void
spin_unlock(struct spinlock *lk)
{
f0102a69:	55                   	push   %ebp
f0102a6a:	89 e5                	mov    %esp,%ebp
f0102a6c:	56                   	push   %esi
f0102a6d:	53                   	push   %ebx
	struct mcslock_node *me = &thiscpu->node;
f0102a6e:	e8 51 fd ff ff       	call   f01027c4 <cpunum>
f0102a73:	89 c2                	mov    %eax,%edx
	struct mcslock_node *tmp = me;
	if (me->next == NULL) {
f0102a75:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f0102a7b:	05 20 70 12 f0       	add    $0xf0127020,%eax
f0102a80:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
f0102a86:	85 c0                	test   %eax,%eax
f0102a88:	74 1b                	je     f0102aa5 <spin_unlock+0x3c>
		if (Cmpxchg(&lk->locked, tmp, NULL) == me)
			return;
		while (me->next == NULL)
			continue;
	}
	me->next->waiting = 0;
f0102a8a:	69 d2 b8 00 00 00    	imul   $0xb8,%edx,%edx
f0102a90:	8b 82 d4 70 12 f0    	mov    -0xfed8f2c(%edx),%eax
f0102a96:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	popcli();
f0102a9c:	e8 61 f0 ff ff       	call   f0101b02 <popcli>
}
f0102aa1:	5b                   	pop    %ebx
f0102aa2:	5e                   	pop    %esi
f0102aa3:	5d                   	pop    %ebp
f0102aa4:	c3                   	ret    
	struct mcslock_node *me = &thiscpu->node;
f0102aa5:	69 ca b8 00 00 00    	imul   $0xb8,%edx,%ecx
f0102aab:	81 c1 d0 70 12 f0    	add    $0xf01270d0,%ecx
	asm volatile("lock; cmpxchgl %2, %1"
f0102ab1:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102ab6:	8b 75 08             	mov    0x8(%ebp),%esi
f0102ab9:	89 c8                	mov    %ecx,%eax
f0102abb:	f0 0f b1 1e          	lock cmpxchg %ebx,(%esi)
		if (Cmpxchg(&lk->locked, tmp, NULL) == me)
f0102abf:	39 c1                	cmp    %eax,%ecx
f0102ac1:	74 de                	je     f0102aa1 <spin_unlock+0x38>
		while (me->next == NULL)
f0102ac3:	69 c2 b8 00 00 00    	imul   $0xb8,%edx,%eax
f0102ac9:	05 20 70 12 f0       	add    $0xf0127020,%eax
f0102ace:	8b 88 b4 00 00 00    	mov    0xb4(%eax),%ecx
f0102ad4:	85 c9                	test   %ecx,%ecx
f0102ad6:	75 b2                	jne    f0102a8a <spin_unlock+0x21>
f0102ad8:	eb f4                	jmp    f0102ace <spin_unlock+0x65>

f0102ada <irq_setmask_8259A>:
		irq_setmask_8259A(irq_mask_8259A);
}

void
irq_setmask_8259A(uint16_t mask)
{
f0102ada:	55                   	push   %ebp
f0102adb:	89 e5                	mov    %esp,%ebp
f0102add:	56                   	push   %esi
f0102ade:	53                   	push   %ebx
f0102adf:	8b 45 08             	mov    0x8(%ebp),%eax
	int i;
	irq_mask_8259A = mask;
f0102ae2:	66 a3 34 e7 11 f0    	mov    %ax,0xf011e734
	if (!didinit)
f0102ae8:	80 3d 35 62 12 f0 00 	cmpb   $0x0,0xf0126235
f0102aef:	75 07                	jne    f0102af8 <irq_setmask_8259A+0x1e>
	cprintf("enabled interrupts:");
	for (i = 0; i < 16; i++)
		if (~mask & (1<<i))
			cprintf(" %d", i);
	cprintf("\n");
}
f0102af1:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0102af4:	5b                   	pop    %ebx
f0102af5:	5e                   	pop    %esi
f0102af6:	5d                   	pop    %ebp
f0102af7:	c3                   	ret    
f0102af8:	89 c6                	mov    %eax,%esi
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102afa:	ba 21 00 00 00       	mov    $0x21,%edx
f0102aff:	ee                   	out    %al,(%dx)
	outb(IO_PIC2+1, (char)(mask >> 8));
f0102b00:	66 c1 e8 08          	shr    $0x8,%ax
f0102b04:	ba a1 00 00 00       	mov    $0xa1,%edx
f0102b09:	ee                   	out    %al,(%dx)
	cprintf("enabled interrupts:");
f0102b0a:	83 ec 0c             	sub    $0xc,%esp
f0102b0d:	68 ed 4c 10 f0       	push   $0xf0104ced
f0102b12:	e8 6b dc ff ff       	call   f0100782 <cprintf>
f0102b17:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < 16; i++)
f0102b1a:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (~mask & (1<<i))
f0102b1f:	0f b7 f6             	movzwl %si,%esi
f0102b22:	f7 d6                	not    %esi
f0102b24:	eb 08                	jmp    f0102b2e <irq_setmask_8259A+0x54>
	for (i = 0; i < 16; i++)
f0102b26:	83 c3 01             	add    $0x1,%ebx
f0102b29:	83 fb 10             	cmp    $0x10,%ebx
f0102b2c:	74 18                	je     f0102b46 <irq_setmask_8259A+0x6c>
		if (~mask & (1<<i))
f0102b2e:	0f a3 de             	bt     %ebx,%esi
f0102b31:	73 f3                	jae    f0102b26 <irq_setmask_8259A+0x4c>
			cprintf(" %d", i);
f0102b33:	83 ec 08             	sub    $0x8,%esp
f0102b36:	53                   	push   %ebx
f0102b37:	68 69 4f 10 f0       	push   $0xf0104f69
f0102b3c:	e8 41 dc ff ff       	call   f0100782 <cprintf>
f0102b41:	83 c4 10             	add    $0x10,%esp
f0102b44:	eb e0                	jmp    f0102b26 <irq_setmask_8259A+0x4c>
	cprintf("\n");
f0102b46:	83 ec 0c             	sub    $0xc,%esp
f0102b49:	68 0f 47 10 f0       	push   $0xf010470f
f0102b4e:	e8 2f dc ff ff       	call   f0100782 <cprintf>
f0102b53:	83 c4 10             	add    $0x10,%esp
f0102b56:	eb 99                	jmp    f0102af1 <irq_setmask_8259A+0x17>

f0102b58 <pic_init>:
{
f0102b58:	55                   	push   %ebp
f0102b59:	89 e5                	mov    %esp,%ebp
f0102b5b:	57                   	push   %edi
f0102b5c:	56                   	push   %esi
f0102b5d:	53                   	push   %ebx
f0102b5e:	83 ec 0c             	sub    $0xc,%esp
	didinit = 1;
f0102b61:	c6 05 35 62 12 f0 01 	movb   $0x1,0xf0126235
f0102b68:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102b6d:	bb 21 00 00 00       	mov    $0x21,%ebx
f0102b72:	89 da                	mov    %ebx,%edx
f0102b74:	ee                   	out    %al,(%dx)
f0102b75:	b9 a1 00 00 00       	mov    $0xa1,%ecx
f0102b7a:	89 ca                	mov    %ecx,%edx
f0102b7c:	ee                   	out    %al,(%dx)
f0102b7d:	bf 11 00 00 00       	mov    $0x11,%edi
f0102b82:	be 20 00 00 00       	mov    $0x20,%esi
f0102b87:	89 f8                	mov    %edi,%eax
f0102b89:	89 f2                	mov    %esi,%edx
f0102b8b:	ee                   	out    %al,(%dx)
f0102b8c:	b8 20 00 00 00       	mov    $0x20,%eax
f0102b91:	89 da                	mov    %ebx,%edx
f0102b93:	ee                   	out    %al,(%dx)
f0102b94:	b8 04 00 00 00       	mov    $0x4,%eax
f0102b99:	ee                   	out    %al,(%dx)
f0102b9a:	b8 03 00 00 00       	mov    $0x3,%eax
f0102b9f:	ee                   	out    %al,(%dx)
f0102ba0:	bb a0 00 00 00       	mov    $0xa0,%ebx
f0102ba5:	89 f8                	mov    %edi,%eax
f0102ba7:	89 da                	mov    %ebx,%edx
f0102ba9:	ee                   	out    %al,(%dx)
f0102baa:	b8 28 00 00 00       	mov    $0x28,%eax
f0102baf:	89 ca                	mov    %ecx,%edx
f0102bb1:	ee                   	out    %al,(%dx)
f0102bb2:	b8 02 00 00 00       	mov    $0x2,%eax
f0102bb7:	ee                   	out    %al,(%dx)
f0102bb8:	b8 01 00 00 00       	mov    $0x1,%eax
f0102bbd:	ee                   	out    %al,(%dx)
f0102bbe:	bf 68 00 00 00       	mov    $0x68,%edi
f0102bc3:	89 f8                	mov    %edi,%eax
f0102bc5:	89 f2                	mov    %esi,%edx
f0102bc7:	ee                   	out    %al,(%dx)
f0102bc8:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0102bcd:	89 c8                	mov    %ecx,%eax
f0102bcf:	ee                   	out    %al,(%dx)
f0102bd0:	89 f8                	mov    %edi,%eax
f0102bd2:	89 da                	mov    %ebx,%edx
f0102bd4:	ee                   	out    %al,(%dx)
f0102bd5:	89 c8                	mov    %ecx,%eax
f0102bd7:	ee                   	out    %al,(%dx)
	if (irq_mask_8259A != 0xFFFF)
f0102bd8:	0f b7 05 34 e7 11 f0 	movzwl 0xf011e734,%eax
f0102bdf:	66 83 f8 ff          	cmp    $0xffff,%ax
f0102be3:	74 0f                	je     f0102bf4 <pic_init+0x9c>
		irq_setmask_8259A(irq_mask_8259A);
f0102be5:	83 ec 0c             	sub    $0xc,%esp
f0102be8:	0f b7 c0             	movzwl %ax,%eax
f0102beb:	50                   	push   %eax
f0102bec:	e8 e9 fe ff ff       	call   f0102ada <irq_setmask_8259A>
f0102bf1:	83 c4 10             	add    $0x10,%esp
}
f0102bf4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102bf7:	5b                   	pop    %ebx
f0102bf8:	5e                   	pop    %esi
f0102bf9:	5f                   	pop    %edi
f0102bfa:	5d                   	pop    %ebp
f0102bfb:	c3                   	ret    

f0102bfc <stateListAdd>:
	}
}

static void
stateListAdd(struct ptrs* list, struct proc *p, const char *place)
{
f0102bfc:	55                   	push   %ebp
f0102bfd:	89 e5                	mov    %esp,%ebp
	if (list->head == NULL) {
f0102bff:	83 38 00             	cmpl   $0x0,(%eax)
f0102c02:	74 12                	je     f0102c16 <stateListAdd+0x1a>
		list->head = p;
		list->tail = p;
	} else {
		list->tail->next = p;
f0102c04:	8b 48 04             	mov    0x4(%eax),%ecx
f0102c07:	89 51 1c             	mov    %edx,0x1c(%ecx)
		list->tail = p;
f0102c0a:	89 50 04             	mov    %edx,0x4(%eax)
	}
	p->next = NULL;
f0102c0d:	c7 42 1c 00 00 00 00 	movl   $0x0,0x1c(%edx)
	// cprintf("Add pid %d to %d at %s\n", p->pid, p->state, place);
}
f0102c14:	5d                   	pop    %ebp
f0102c15:	c3                   	ret    
		list->head = p;
f0102c16:	89 10                	mov    %edx,(%eax)
		list->tail = p;
f0102c18:	89 50 04             	mov    %edx,0x4(%eax)
f0102c1b:	eb f0                	jmp    f0102c0d <stateListAdd+0x11>

f0102c1d <stateListRemove>:

static int
stateListRemove(struct ptrs* list, struct proc *p, const char *place)
{
f0102c1d:	55                   	push   %ebp
f0102c1e:	89 e5                	mov    %esp,%ebp
f0102c20:	53                   	push   %ebx
	// cprintf("Remove pid %d from %d at %s\n", p->pid, p->state, place);
	if (list->head == NULL || p == NULL)
f0102c21:	8b 18                	mov    (%eax),%ebx
f0102c23:	85 d2                	test   %edx,%edx
f0102c25:	74 52                	je     f0102c79 <stateListRemove+0x5c>
f0102c27:	85 db                	test   %ebx,%ebx
f0102c29:	74 4e                	je     f0102c79 <stateListRemove+0x5c>
		return -1;
	struct proc *ptr = list->head;
	struct proc *next;
	if (ptr == p) {
f0102c2b:	39 d3                	cmp    %edx,%ebx
f0102c2d:	74 15                	je     f0102c44 <stateListRemove+0x27>
			list->tail = list->tail->next;
		list->head = ptr->next;
		return 0;
	} 

	next = ptr->next;
f0102c2f:	8b 4b 1c             	mov    0x1c(%ebx),%ecx
	for (; ptr != list->tail; ptr = next, next = next->next)
f0102c32:	8b 40 04             	mov    0x4(%eax),%eax
f0102c35:	39 d8                	cmp    %ebx,%eax
f0102c37:	74 38                	je     f0102c71 <stateListRemove+0x54>
		if (next == p) {
f0102c39:	39 d1                	cmp    %edx,%ecx
f0102c3b:	74 20                	je     f0102c5d <stateListRemove+0x40>
	for (; ptr != list->tail; ptr = next, next = next->next)
f0102c3d:	89 cb                	mov    %ecx,%ebx
f0102c3f:	8b 49 1c             	mov    0x1c(%ecx),%ecx
f0102c42:	eb f1                	jmp    f0102c35 <stateListRemove+0x18>
		if (ptr == list->tail)
f0102c44:	3b 58 04             	cmp    0x4(%eax),%ebx
f0102c47:	74 0c                	je     f0102c55 <stateListRemove+0x38>
		list->head = ptr->next;
f0102c49:	8b 53 1c             	mov    0x1c(%ebx),%edx
f0102c4c:	89 10                	mov    %edx,(%eax)
		return 0;
f0102c4e:	b8 00 00 00 00       	mov    $0x0,%eax
f0102c53:	eb 21                	jmp    f0102c76 <stateListRemove+0x59>
			list->tail = list->tail->next;
f0102c55:	8b 53 1c             	mov    0x1c(%ebx),%edx
f0102c58:	89 50 04             	mov    %edx,0x4(%eax)
f0102c5b:	eb ec                	jmp    f0102c49 <stateListRemove+0x2c>
			ptr->next = next->next;
f0102c5d:	8b 41 1c             	mov    0x1c(%ecx),%eax
f0102c60:	89 43 1c             	mov    %eax,0x1c(%ebx)
			next->next = NULL;
f0102c63:	c7 41 1c 00 00 00 00 	movl   $0x0,0x1c(%ecx)
			return 0;
f0102c6a:	b8 00 00 00 00       	mov    $0x0,%eax
f0102c6f:	eb 05                	jmp    f0102c76 <stateListRemove+0x59>
		}
	return -1;
f0102c71:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
f0102c76:	5b                   	pop    %ebx
f0102c77:	5d                   	pop    %ebp
f0102c78:	c3                   	ret    
		return -1;
f0102c79:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102c7e:	eb f6                	jmp    f0102c76 <stateListRemove+0x59>

f0102c80 <forkret>:
	swtch(&p->context, thiscpu->scheduler);
}

void
forkret(void)
{
f0102c80:	55                   	push   %ebp
f0102c81:	89 e5                	mov    %esp,%ebp
f0102c83:	83 ec 14             	sub    $0x14,%esp
	// Return to "caller", actually trapret (see proc_alloc)
	// That means the first proc starts here.
	// When it returns from forkret, it need to return to trapret.
	// TODO: your code here.
	spin_unlock(&ptable.lock);
f0102c86:	68 20 80 16 f0       	push   $0xf0168020
f0102c8b:	e8 d9 fd ff ff       	call   f0102a69 <spin_unlock>

}
f0102c90:	83 c4 10             	add    $0x10,%esp
f0102c93:	c9                   	leave  
f0102c94:	c3                   	ret    

f0102c95 <assertState>:
	if (p->state != state)
f0102c95:	39 50 08             	cmp    %edx,0x8(%eax)
f0102c98:	75 02                	jne    f0102c9c <assertState+0x7>
f0102c9a:	f3 c3                	repz ret 
{
f0102c9c:	55                   	push   %ebp
f0102c9d:	89 e5                	mov    %esp,%ebp
f0102c9f:	83 ec 0c             	sub    $0xc,%esp
		panic("process state not same as asserted state.");
f0102ca2:	68 04 4d 10 f0       	push   $0xf0104d04
f0102ca7:	6a 68                	push   $0x68
f0102ca9:	68 34 4e 10 f0       	push   $0xf0104e34
f0102cae:	e8 e5 d4 ff ff       	call   f0100198 <_panic>

f0102cb3 <proc_alloc>:
{
f0102cb3:	55                   	push   %ebp
f0102cb4:	89 e5                	mov    %esp,%ebp
f0102cb6:	53                   	push   %ebx
f0102cb7:	83 ec 04             	sub    $0x4,%esp
	p = ptable.list[UNUSED].head;
f0102cba:	8b 1d 54 8c 16 f0    	mov    0xf0168c54,%ebx
	if (p == NULL)
f0102cc0:	85 db                	test   %ebx,%ebx
f0102cc2:	0f 84 c3 00 00 00    	je     f0102d8b <proc_alloc+0xd8>
	spin_lock(&ptable.lock);
f0102cc8:	83 ec 0c             	sub    $0xc,%esp
f0102ccb:	68 20 80 16 f0       	push   $0xf0168020
f0102cd0:	e8 2c fd ff ff       	call   f0102a01 <spin_lock>
	p->pid = nextpid++;
f0102cd5:	a1 4c e7 11 f0       	mov    0xf011e74c,%eax
f0102cda:	8d 50 01             	lea    0x1(%eax),%edx
f0102cdd:	89 15 4c e7 11 f0    	mov    %edx,0xf011e74c
f0102ce3:	89 43 0c             	mov    %eax,0xc(%ebx)
	if (stateListRemove(&ptable.list[UNUSED], p, "Proc") < 0)
f0102ce6:	b9 40 4e 10 f0       	mov    $0xf0104e40,%ecx
f0102ceb:	89 da                	mov    %ebx,%edx
f0102ced:	b8 54 8c 16 f0       	mov    $0xf0168c54,%eax
f0102cf2:	e8 26 ff ff ff       	call   f0102c1d <stateListRemove>
f0102cf7:	83 c4 10             	add    $0x10,%esp
f0102cfa:	85 c0                	test   %eax,%eax
f0102cfc:	0f 88 90 00 00 00    	js     f0102d92 <proc_alloc+0xdf>
	assertState(p, UNUSED, "Proc");
f0102d02:	b9 40 4e 10 f0       	mov    $0xf0104e40,%ecx
f0102d07:	ba 00 00 00 00       	mov    $0x0,%edx
f0102d0c:	89 d8                	mov    %ebx,%eax
f0102d0e:	e8 82 ff ff ff       	call   f0102c95 <assertState>
	p->state = EMBRYO;
f0102d13:	c7 43 08 01 00 00 00 	movl   $0x1,0x8(%ebx)
	stateListAdd(&ptable.list[EMBRYO], p, "Proc");
f0102d1a:	b9 40 4e 10 f0       	mov    $0xf0104e40,%ecx
f0102d1f:	89 da                	mov    %ebx,%edx
f0102d21:	b8 5c 8c 16 f0       	mov    $0xf0168c5c,%eax
f0102d26:	e8 d1 fe ff ff       	call   f0102bfc <stateListAdd>
	spin_unlock(&ptable.lock);
f0102d2b:	83 ec 0c             	sub    $0xc,%esp
f0102d2e:	68 20 80 16 f0       	push   $0xf0168020
f0102d33:	e8 31 fd ff ff       	call   f0102a69 <spin_unlock>
	if ((p->kstack = kalloc()) == NULL) {
f0102d38:	e8 42 f4 ff ff       	call   f010217f <kalloc>
f0102d3d:	89 43 04             	mov    %eax,0x4(%ebx)
f0102d40:	83 c4 10             	add    $0x10,%esp
f0102d43:	85 c0                	test   %eax,%eax
f0102d45:	74 62                	je     f0102da9 <proc_alloc+0xf6>
	begin -= sizeof(*p->tf);
f0102d47:	8d 90 b4 0f 00 00    	lea    0xfb4(%eax),%edx
f0102d4d:	89 53 14             	mov    %edx,0x14(%ebx)
	*(uint32_t *)begin = (uint32_t)trapret;
f0102d50:	c7 80 b0 0f 00 00 89 	movl   $0xf0100989,0xfb0(%eax)
f0102d57:	09 10 f0 
	begin -= sizeof(*p->context);
f0102d5a:	05 9c 0f 00 00       	add    $0xf9c,%eax
	p->context = (struct context *)begin;
f0102d5f:	89 43 18             	mov    %eax,0x18(%ebx)
	memset(p->context, 0, sizeof(*p->context));
f0102d62:	83 ec 04             	sub    $0x4,%esp
f0102d65:	6a 14                	push   $0x14
f0102d67:	6a 00                	push   $0x0
f0102d69:	50                   	push   %eax
f0102d6a:	e8 d6 14 00 00       	call   f0104245 <memset>
	p->context->eip = (uint32_t)forkret;
f0102d6f:	8b 43 18             	mov    0x18(%ebx),%eax
f0102d72:	c7 40 10 80 2c 10 f0 	movl   $0xf0102c80,0x10(%eax)
	p->priority = MAXPRIO;
f0102d79:	c7 43 20 04 00 00 00 	movl   $0x4,0x20(%ebx)
	p->budget = time_slice[p->priority];
f0102d80:	a1 48 e7 11 f0       	mov    0xf011e748,%eax
f0102d85:	89 43 24             	mov    %eax,0x24(%ebx)
	return p;
f0102d88:	83 c4 10             	add    $0x10,%esp
}
f0102d8b:	89 d8                	mov    %ebx,%eax
f0102d8d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102d90:	c9                   	leave  
f0102d91:	c3                   	ret    
		panic("In UNUSED: Empty or process not in list");
f0102d92:	83 ec 04             	sub    $0x4,%esp
f0102d95:	68 30 4d 10 f0       	push   $0xf0104d30
f0102d9a:	68 84 00 00 00       	push   $0x84
f0102d9f:	68 34 4e 10 f0       	push   $0xf0104e34
f0102da4:	e8 ef d3 ff ff       	call   f0100198 <_panic>
		spin_lock(&ptable.lock);
f0102da9:	83 ec 0c             	sub    $0xc,%esp
f0102dac:	68 20 80 16 f0       	push   $0xf0168020
f0102db1:	e8 4b fc ff ff       	call   f0102a01 <spin_lock>
		if (stateListRemove(&ptable.list[EMBRYO], p, "Proc fail") < 0)
f0102db6:	b9 45 4e 10 f0       	mov    $0xf0104e45,%ecx
f0102dbb:	89 da                	mov    %ebx,%edx
f0102dbd:	b8 5c 8c 16 f0       	mov    $0xf0168c5c,%eax
f0102dc2:	e8 56 fe ff ff       	call   f0102c1d <stateListRemove>
f0102dc7:	83 c4 10             	add    $0x10,%esp
f0102dca:	85 c0                	test   %eax,%eax
f0102dcc:	78 43                	js     f0102e11 <proc_alloc+0x15e>
		assertState(p, EMBRYO, "Proc fail");
f0102dce:	b9 45 4e 10 f0       	mov    $0xf0104e45,%ecx
f0102dd3:	ba 01 00 00 00       	mov    $0x1,%edx
f0102dd8:	89 d8                	mov    %ebx,%eax
f0102dda:	e8 b6 fe ff ff       	call   f0102c95 <assertState>
		p->state = UNUSED;
f0102ddf:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
		stateListAdd(&ptable.list[UNUSED], p, "Proc fail");
f0102de6:	b9 45 4e 10 f0       	mov    $0xf0104e45,%ecx
f0102deb:	89 da                	mov    %ebx,%edx
f0102ded:	b8 54 8c 16 f0       	mov    $0xf0168c54,%eax
f0102df2:	e8 05 fe ff ff       	call   f0102bfc <stateListAdd>
		spin_unlock(&ptable.lock);
f0102df7:	83 ec 0c             	sub    $0xc,%esp
f0102dfa:	68 20 80 16 f0       	push   $0xf0168020
f0102dff:	e8 65 fc ff ff       	call   f0102a69 <spin_unlock>
		return NULL;
f0102e04:	83 c4 10             	add    $0x10,%esp
f0102e07:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102e0c:	e9 7a ff ff ff       	jmp    f0102d8b <proc_alloc+0xd8>
			panic("In EMBRYO: Empty or process not in list");
f0102e11:	83 ec 04             	sub    $0x4,%esp
f0102e14:	68 58 4d 10 f0       	push   $0xf0104d58
f0102e19:	68 8d 00 00 00       	push   $0x8d
f0102e1e:	68 34 4e 10 f0       	push   $0xf0104e34
f0102e23:	e8 70 d3 ff ff       	call   f0100198 <_panic>

f0102e28 <proc_init>:
{
f0102e28:	55                   	push   %ebp
f0102e29:	89 e5                	mov    %esp,%ebp
f0102e2b:	83 ec 10             	sub    $0x10,%esp
	__spin_initlock(&ptable.lock, "ptable");
f0102e2e:	68 4f 4e 10 f0       	push   $0xf0104e4f
f0102e33:	68 20 80 16 f0       	push   $0xf0168020
f0102e38:	e8 a9 fb ff ff       	call   f01029e6 <__spin_initlock>
}
f0102e3d:	83 c4 10             	add    $0x10,%esp
f0102e40:	c9                   	leave  
f0102e41:	c3                   	ret    

f0102e42 <user_init>:
{
f0102e42:	55                   	push   %ebp
f0102e43:	89 e5                	mov    %esp,%ebp
f0102e45:	57                   	push   %edi
f0102e46:	56                   	push   %esi
f0102e47:	53                   	push   %ebx
f0102e48:	83 ec 28             	sub    $0x28,%esp
	spin_lock(&ptable.lock);
f0102e4b:	68 20 80 16 f0       	push   $0xf0168020
f0102e50:	e8 ac fb ff ff       	call   f0102a01 <spin_lock>
f0102e55:	b8 54 8c 16 f0       	mov    $0xf0168c54,%eax
f0102e5a:	ba 84 8c 16 f0       	mov    $0xf0168c84,%edx
f0102e5f:	83 c4 10             	add    $0x10,%esp
		ptable.list[i].head = NULL;
f0102e62:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		ptable.list[i].tail = NULL;
f0102e68:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
f0102e6f:	83 c0 08             	add    $0x8,%eax
	for (i = UNUSED; i <= ZOMBIE; i++) {
f0102e72:	39 d0                	cmp    %edx,%eax
f0102e74:	75 ec                	jne    f0102e62 <user_init+0x20>
		ptable.ready[i].head = NULL;
f0102e76:	c7 05 84 8c 16 f0 00 	movl   $0x0,0xf0168c84
f0102e7d:	00 00 00 
		ptable.ready[i].tail = NULL;
f0102e80:	c7 05 88 8c 16 f0 00 	movl   $0x0,0xf0168c88
f0102e87:	00 00 00 
		ptable.ready[i].head = NULL;
f0102e8a:	c7 05 8c 8c 16 f0 00 	movl   $0x0,0xf0168c8c
f0102e91:	00 00 00 
		ptable.ready[i].tail = NULL;
f0102e94:	c7 05 90 8c 16 f0 00 	movl   $0x0,0xf0168c90
f0102e9b:	00 00 00 
		ptable.ready[i].head = NULL;
f0102e9e:	c7 05 94 8c 16 f0 00 	movl   $0x0,0xf0168c94
f0102ea5:	00 00 00 
		ptable.ready[i].tail = NULL;
f0102ea8:	c7 05 98 8c 16 f0 00 	movl   $0x0,0xf0168c98
f0102eaf:	00 00 00 
		ptable.ready[i].head = NULL;
f0102eb2:	c7 05 9c 8c 16 f0 00 	movl   $0x0,0xf0168c9c
f0102eb9:	00 00 00 
		ptable.ready[i].tail = NULL;
f0102ebc:	c7 05 a0 8c 16 f0 00 	movl   $0x0,0xf0168ca0
f0102ec3:	00 00 00 
		ptable.ready[i].head = NULL;
f0102ec6:	c7 05 a4 8c 16 f0 00 	movl   $0x0,0xf0168ca4
f0102ecd:	00 00 00 
		ptable.ready[i].tail = NULL;
f0102ed0:	c7 05 a8 8c 16 f0 00 	movl   $0x0,0xf0168ca8
f0102ed7:	00 00 00 
	for (p = ptable.proc; p < &ptable.proc[NPROC]; p++) {
f0102eda:	bb 54 80 16 f0       	mov    $0xf0168054,%ebx
		p->state = UNUSED;
f0102edf:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
		stateListAdd(&ptable.list[UNUSED], p, "Free_list");
f0102ee6:	b9 56 4e 10 f0       	mov    $0xf0104e56,%ecx
f0102eeb:	89 da                	mov    %ebx,%edx
f0102eed:	b8 54 8c 16 f0       	mov    $0xf0168c54,%eax
f0102ef2:	e8 05 fd ff ff       	call   f0102bfc <stateListAdd>
	for (p = ptable.proc; p < &ptable.proc[NPROC]; p++) {
f0102ef7:	83 c3 30             	add    $0x30,%ebx
f0102efa:	81 fb 54 8c 16 f0    	cmp    $0xf0168c54,%ebx
f0102f00:	72 dd                	jb     f0102edf <user_init+0x9d>
	spin_unlock(&ptable.lock);
f0102f02:	83 ec 0c             	sub    $0xc,%esp
f0102f05:	68 20 80 16 f0       	push   $0xf0168020
f0102f0a:	e8 5a fb ff ff       	call   f0102a69 <spin_unlock>
	if ((child = proc_alloc()) == NULL)
f0102f0f:	e8 9f fd ff ff       	call   f0102cb3 <proc_alloc>
f0102f14:	89 c6                	mov    %eax,%esi
f0102f16:	83 c4 10             	add    $0x10,%esp
f0102f19:	85 c0                	test   %eax,%eax
f0102f1b:	74 25                	je     f0102f42 <user_init+0x100>
	if ((child->pgdir = kvm_init()) == NULL)
f0102f1d:	e8 da e7 ff ff       	call   f01016fc <kvm_init>
f0102f22:	89 06                	mov    %eax,(%esi)
f0102f24:	85 c0                	test   %eax,%eax
f0102f26:	74 31                	je     f0102f59 <user_init+0x117>
	ph = (struct Proghdr *) (binary + elf->e_phoff);
f0102f28:	a1 6c e7 11 f0       	mov    0xf011e76c,%eax
f0102f2d:	8d 98 50 e7 11 f0    	lea    -0xfee18b0(%eax),%ebx
	eph = ph + elf->e_phnum;
f0102f33:	0f b7 05 7c e7 11 f0 	movzwl 0xf011e77c,%eax
f0102f3a:	c1 e0 05             	shl    $0x5,%eax
f0102f3d:	8d 3c 03             	lea    (%ebx,%eax,1),%edi
f0102f40:	eb 31                	jmp    f0102f73 <user_init+0x131>
		panic("Allocate User Process.");
f0102f42:	83 ec 04             	sub    $0x4,%esp
f0102f45:	68 60 4e 10 f0       	push   $0xf0104e60
f0102f4a:	68 23 01 00 00       	push   $0x123
f0102f4f:	68 34 4e 10 f0       	push   $0xf0104e34
f0102f54:	e8 3f d2 ff ff       	call   f0100198 <_panic>
		panic("User Pagedir.");
f0102f59:	83 ec 04             	sub    $0x4,%esp
f0102f5c:	68 77 4e 10 f0       	push   $0xf0104e77
f0102f61:	68 25 01 00 00       	push   $0x125
f0102f66:	68 34 4e 10 f0       	push   $0xf0104e34
f0102f6b:	e8 28 d2 ff ff       	call   f0100198 <_panic>
	for (; ph < eph; ph++) {
f0102f70:	83 c3 20             	add    $0x20,%ebx
f0102f73:	39 df                	cmp    %ebx,%edi
f0102f75:	76 46                	jbe    f0102fbd <user_init+0x17b>
			if (ph->p_type == ELF_PROG_LOAD) {
f0102f77:	83 3b 01             	cmpl   $0x1,(%ebx)
f0102f7a:	75 f4                	jne    f0102f70 <user_init+0x12e>
			void *begin = (void *)ph->p_va;
f0102f7c:	8b 43 08             	mov    0x8(%ebx),%eax
				region_alloc(p, begin, ph->p_memsz);
f0102f7f:	83 ec 04             	sub    $0x4,%esp
f0102f82:	ff 73 14             	pushl  0x14(%ebx)
f0102f85:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102f88:	50                   	push   %eax
f0102f89:	56                   	push   %esi
f0102f8a:	e8 97 ea ff ff       	call   f0101a26 <region_alloc>
				if (loaduvm(p->pgdir, begin, ph, (char *)binary) < 0)
f0102f8f:	68 50 e7 11 f0       	push   $0xf011e750
f0102f94:	53                   	push   %ebx
f0102f95:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102f98:	ff 36                	pushl  (%esi)
f0102f9a:	e8 7f e6 ff ff       	call   f010161e <loaduvm>
f0102f9f:	83 c4 20             	add    $0x20,%esp
f0102fa2:	85 c0                	test   %eax,%eax
f0102fa4:	79 ca                	jns    f0102f70 <user_init+0x12e>
					panic("Load segment.");
f0102fa6:	83 ec 04             	sub    $0x4,%esp
f0102fa9:	68 85 4e 10 f0       	push   $0xf0104e85
f0102fae:	68 06 01 00 00       	push   $0x106
f0102fb3:	68 34 4e 10 f0       	push   $0xf0104e34
f0102fb8:	e8 db d1 ff ff       	call   f0100198 <_panic>
	region_alloc(p, (void *)(USTACKTOP - PGSIZE), PGSIZE * 2);
f0102fbd:	83 ec 04             	sub    $0x4,%esp
f0102fc0:	68 00 20 00 00       	push   $0x2000
f0102fc5:	68 00 f0 ff cf       	push   $0xcffff000
f0102fca:	56                   	push   %esi
f0102fcb:	e8 56 ea ff ff       	call   f0101a26 <region_alloc>
	memset(child->tf, 0, sizeof(*child->tf));
f0102fd0:	83 c4 0c             	add    $0xc,%esp
f0102fd3:	6a 4c                	push   $0x4c
f0102fd5:	6a 00                	push   $0x0
f0102fd7:	ff 76 14             	pushl  0x14(%esi)
f0102fda:	e8 66 12 00 00       	call   f0104245 <memset>
	child->tf->cs = (SEG_UCODE << 3) | DPL_USER;
f0102fdf:	8b 46 14             	mov    0x14(%esi),%eax
f0102fe2:	66 c7 40 3c 1b 00    	movw   $0x1b,0x3c(%eax)
	child->tf->ds = (SEG_UDATA << 3) | DPL_USER;
f0102fe8:	8b 46 14             	mov    0x14(%esi),%eax
f0102feb:	66 c7 40 2c 23 00    	movw   $0x23,0x2c(%eax)
	child->tf->es = (SEG_UDATA << 3) | DPL_USER;
f0102ff1:	8b 46 14             	mov    0x14(%esi),%eax
f0102ff4:	66 c7 40 28 23 00    	movw   $0x23,0x28(%eax)
	child->tf->ss = (SEG_UDATA << 3) | DPL_USER;
f0102ffa:	8b 46 14             	mov    0x14(%esi),%eax
f0102ffd:	66 c7 40 48 23 00    	movw   $0x23,0x48(%eax)
	child->tf->eflags = FL_IF;
f0103003:	8b 46 14             	mov    0x14(%esi),%eax
f0103006:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
	child->tf->eip = (uintptr_t)begin;
f010300d:	8b 46 14             	mov    0x14(%esi),%eax
f0103010:	8b 15 68 e7 11 f0    	mov    0xf011e768,%edx
f0103016:	89 50 38             	mov    %edx,0x38(%eax)
	child->tf->esp = USTACKTOP;
f0103019:	8b 46 14             	mov    0x14(%esi),%eax
f010301c:	c7 40 44 00 00 00 d0 	movl   $0xd0000000,0x44(%eax)
	spin_lock(&ptable.lock);
f0103023:	c7 04 24 20 80 16 f0 	movl   $0xf0168020,(%esp)
f010302a:	e8 d2 f9 ff ff       	call   f0102a01 <spin_lock>
	if (stateListRemove(&ptable.list[EMBRYO], child, "Userinit") < 0)
f010302f:	b9 93 4e 10 f0       	mov    $0xf0104e93,%ecx
f0103034:	89 f2                	mov    %esi,%edx
f0103036:	b8 5c 8c 16 f0       	mov    $0xf0168c5c,%eax
f010303b:	e8 dd fb ff ff       	call   f0102c1d <stateListRemove>
f0103040:	83 c4 10             	add    $0x10,%esp
f0103043:	85 c0                	test   %eax,%eax
f0103045:	78 55                	js     f010309c <user_init+0x25a>
	assertState(child, EMBRYO, "Userinit");
f0103047:	b9 93 4e 10 f0       	mov    $0xf0104e93,%ecx
f010304c:	ba 01 00 00 00       	mov    $0x1,%edx
f0103051:	89 f0                	mov    %esi,%eax
f0103053:	e8 3d fc ff ff       	call   f0102c95 <assertState>
	child->state = RUNNABLE;
f0103058:	c7 46 08 03 00 00 00 	movl   $0x3,0x8(%esi)
	stateListAdd(&ptable.ready[child->priority], child, "Userinit");
f010305f:	8b 46 20             	mov    0x20(%esi),%eax
f0103062:	8d 04 c5 84 8c 16 f0 	lea    -0xfe9737c(,%eax,8),%eax
f0103069:	b9 93 4e 10 f0       	mov    $0xf0104e93,%ecx
f010306e:	89 f2                	mov    %esi,%edx
f0103070:	e8 87 fb ff ff       	call   f0102bfc <stateListAdd>
	ptable.PromoteAtTime = ticks + TICKS_TO_PROMOTE;
f0103075:	a1 a0 6e 12 f0       	mov    0xf0126ea0,%eax
f010307a:	05 e8 03 00 00       	add    $0x3e8,%eax
f010307f:	a3 ac 8c 16 f0       	mov    %eax,0xf0168cac
	spin_unlock(&ptable.lock);
f0103084:	83 ec 0c             	sub    $0xc,%esp
f0103087:	68 20 80 16 f0       	push   $0xf0168020
f010308c:	e8 d8 f9 ff ff       	call   f0102a69 <spin_unlock>
}
f0103091:	83 c4 10             	add    $0x10,%esp
f0103094:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103097:	5b                   	pop    %ebx
f0103098:	5e                   	pop    %esi
f0103099:	5f                   	pop    %edi
f010309a:	5d                   	pop    %ebp
f010309b:	c3                   	ret    
		panic("In EMBRYO: Empty or process not in list");
f010309c:	83 ec 04             	sub    $0x4,%esp
f010309f:	68 58 4d 10 f0       	push   $0xf0104d58
f01030a4:	68 37 01 00 00       	push   $0x137
f01030a9:	68 34 4e 10 f0       	push   $0xf0104e34
f01030ae:	e8 e5 d0 ff ff       	call   f0100198 <_panic>

f01030b3 <ucode_run>:
{
f01030b3:	55                   	push   %ebp
f01030b4:	89 e5                	mov    %esp,%ebp
f01030b6:	57                   	push   %edi
f01030b7:	56                   	push   %esi
f01030b8:	53                   	push   %ebx
f01030b9:	83 ec 1c             	sub    $0x1c,%esp
	thiscpu->proc = NULL;
f01030bc:	e8 03 f7 ff ff       	call   f01027c4 <cpunum>
f01030c1:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f01030c7:	c7 80 c4 70 12 f0 00 	movl   $0x0,-0xfed8f3c(%eax)
f01030ce:	00 00 00 
f01030d1:	e9 82 01 00 00       	jmp    f0103258 <ucode_run+0x1a5>
f01030d6:	c7 45 dc 9c 8c 16 f0 	movl   $0xf0168c9c,-0x24(%ebp)
			for (int j = MAXPRIO - 1; j >= 0; j--) {
f01030dd:	bf 03 00 00 00       	mov    $0x3,%edi
f01030e2:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01030e5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				p = ptable.ready[j].head;
f01030e8:	8b 18                	mov    (%eax),%ebx
f01030ea:	83 c0 08             	add    $0x8,%eax
f01030ed:	89 45 e0             	mov    %eax,-0x20(%ebp)
				while(p) {
f01030f0:	85 db                	test   %ebx,%ebx
f01030f2:	0f 84 80 00 00 00    	je     f0103178 <ucode_run+0xc5>
					tmp = p->next;
f01030f8:	8b 73 1c             	mov    0x1c(%ebx),%esi
					if (stateListRemove(&ptable.ready[j], p, "Ucode_run") < 0)
f01030fb:	b9 9c 4e 10 f0       	mov    $0xf0104e9c,%ecx
f0103100:	89 da                	mov    %ebx,%edx
f0103102:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103105:	e8 13 fb ff ff       	call   f0102c1d <stateListRemove>
f010310a:	85 c0                	test   %eax,%eax
f010310c:	78 3c                	js     f010314a <ucode_run+0x97>
					assertState(p, RUNNABLE, "Ucode_run");
f010310e:	b9 9c 4e 10 f0       	mov    $0xf0104e9c,%ecx
f0103113:	ba 03 00 00 00       	mov    $0x3,%edx
f0103118:	89 d8                	mov    %ebx,%eax
f010311a:	e8 76 fb ff ff       	call   f0102c95 <assertState>
					if (p->priority != j)
f010311f:	39 7b 20             	cmp    %edi,0x20(%ebx)
f0103122:	75 3d                	jne    f0103161 <ucode_run+0xae>
					stateListAdd(&ptable.ready[j + 1], p, "Ucode_run");
f0103124:	b9 9c 4e 10 f0       	mov    $0xf0104e9c,%ecx
f0103129:	89 da                	mov    %ebx,%edx
f010312b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010312e:	e8 c9 fa ff ff       	call   f0102bfc <stateListAdd>
					p->budget = time_slice[++p->priority];
f0103133:	8b 43 20             	mov    0x20(%ebx),%eax
f0103136:	83 c0 01             	add    $0x1,%eax
f0103139:	89 43 20             	mov    %eax,0x20(%ebx)
f010313c:	8b 04 85 38 e7 11 f0 	mov    -0xfee18c8(,%eax,4),%eax
f0103143:	89 43 24             	mov    %eax,0x24(%ebx)
					p = tmp;
f0103146:	89 f3                	mov    %esi,%ebx
f0103148:	eb a6                	jmp    f01030f0 <ucode_run+0x3d>
						panic("In Priority Queue: Empty or process is not in list");
f010314a:	83 ec 04             	sub    $0x4,%esp
f010314d:	68 80 4d 10 f0       	push   $0xf0104d80
f0103152:	68 62 01 00 00       	push   $0x162
f0103157:	68 34 4e 10 f0       	push   $0xf0104e34
f010315c:	e8 37 d0 ff ff       	call   f0100198 <_panic>
						panic("Priority");
f0103161:	83 ec 04             	sub    $0x4,%esp
f0103164:	68 a6 4e 10 f0       	push   $0xf0104ea6
f0103169:	68 65 01 00 00       	push   $0x165
f010316e:	68 34 4e 10 f0       	push   $0xf0104e34
f0103173:	e8 20 d0 ff ff       	call   f0100198 <_panic>
			for (int j = MAXPRIO - 1; j >= 0; j--) {
f0103178:	83 ef 01             	sub    $0x1,%edi
f010317b:	83 6d dc 08          	subl   $0x8,-0x24(%ebp)
f010317f:	83 ff ff             	cmp    $0xffffffff,%edi
f0103182:	0f 85 5a ff ff ff    	jne    f01030e2 <ucode_run+0x2f>
			ptable.PromoteAtTime = ticks + TICKS_TO_PROMOTE;
f0103188:	a1 a0 6e 12 f0       	mov    0xf0126ea0,%eax
f010318d:	05 e8 03 00 00       	add    $0x3e8,%eax
f0103192:	a3 ac 8c 16 f0       	mov    %eax,0xf0168cac
f0103197:	e9 de 00 00 00       	jmp    f010327a <ucode_run+0x1c7>
				uvm_switch(p);
f010319c:	83 ec 0c             	sub    $0xc,%esp
f010319f:	53                   	push   %ebx
f01031a0:	e8 e3 e9 ff ff       	call   f0101b88 <uvm_switch>
				if (stateListRemove(&ptable.ready[priority], p, "Ucode_run") < 0)
f01031a5:	8d 04 f5 84 8c 16 f0 	lea    -0xfe9737c(,%esi,8),%eax
f01031ac:	b9 9c 4e 10 f0       	mov    $0xf0104e9c,%ecx
f01031b1:	89 da                	mov    %ebx,%edx
f01031b3:	e8 65 fa ff ff       	call   f0102c1d <stateListRemove>
f01031b8:	83 c4 10             	add    $0x10,%esp
f01031bb:	85 c0                	test   %eax,%eax
f01031bd:	0f 88 d7 00 00 00    	js     f010329a <ucode_run+0x1e7>
				if (p->priority != priority) 
f01031c3:	39 73 20             	cmp    %esi,0x20(%ebx)
f01031c6:	0f 85 e5 00 00 00    	jne    f01032b1 <ucode_run+0x1fe>
				assertState(p, RUNNABLE, "Ucode_run");
f01031cc:	b9 9c 4e 10 f0       	mov    $0xf0104e9c,%ecx
f01031d1:	ba 03 00 00 00       	mov    $0x3,%edx
f01031d6:	89 d8                	mov    %ebx,%eax
f01031d8:	e8 b8 fa ff ff       	call   f0102c95 <assertState>
				p->state = RUNNING;
f01031dd:	c7 43 08 04 00 00 00 	movl   $0x4,0x8(%ebx)
				stateListAdd(&ptable.list[p->state], p, "Ucode_run");
f01031e4:	b9 9c 4e 10 f0       	mov    $0xf0104e9c,%ecx
f01031e9:	89 da                	mov    %ebx,%edx
f01031eb:	b8 74 8c 16 f0       	mov    $0xf0168c74,%eax
f01031f0:	e8 07 fa ff ff       	call   f0102bfc <stateListAdd>
				thiscpu->proc = p;
f01031f5:	e8 ca f5 ff ff       	call   f01027c4 <cpunum>
f01031fa:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f0103200:	89 98 c4 70 12 f0    	mov    %ebx,-0xfed8f3c(%eax)
				p->begin_tick = ticks;
f0103206:	a1 a0 6e 12 f0       	mov    0xf0126ea0,%eax
f010320b:	89 43 28             	mov    %eax,0x28(%ebx)
				swtch(&thiscpu->scheduler, p->context);
f010320e:	8b 5b 18             	mov    0x18(%ebx),%ebx
f0103211:	e8 ae f5 ff ff       	call   f01027c4 <cpunum>
f0103216:	83 ec 08             	sub    $0x8,%esp
f0103219:	53                   	push   %ebx
f010321a:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f0103220:	05 28 70 12 f0       	add    $0xf0127028,%eax
f0103225:	50                   	push   %eax
f0103226:	e8 d7 07 00 00       	call   f0103a02 <swtch>
				kvm_switch();
f010322b:	e8 40 e5 ff ff       	call   f0101770 <kvm_switch>
				thiscpu->proc = NULL;
f0103230:	e8 8f f5 ff ff       	call   f01027c4 <cpunum>
f0103235:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f010323b:	c7 80 c4 70 12 f0 00 	movl   $0x0,-0xfed8f3c(%eax)
f0103242:	00 00 00 
				break;
f0103245:	83 c4 10             	add    $0x10,%esp
		spin_unlock(&ptable.lock);
f0103248:	83 ec 0c             	sub    $0xc,%esp
f010324b:	68 20 80 16 f0       	push   $0xf0168020
f0103250:	e8 14 f8 ff ff       	call   f0102a69 <spin_unlock>
		sti();
f0103255:	83 c4 10             	add    $0x10,%esp
	asm volatile("sti");
f0103258:	fb                   	sti    
		spin_lock(&ptable.lock);
f0103259:	83 ec 0c             	sub    $0xc,%esp
f010325c:	68 20 80 16 f0       	push   $0xf0168020
f0103261:	e8 9b f7 ff ff       	call   f0102a01 <spin_lock>
		if (ticks >= ptable.PromoteAtTime) {
f0103266:	83 c4 10             	add    $0x10,%esp
f0103269:	a1 a0 6e 12 f0       	mov    0xf0126ea0,%eax
f010326e:	39 05 ac 8c 16 f0    	cmp    %eax,0xf0168cac
f0103274:	0f 86 5c fe ff ff    	jbe    f01030d6 <ucode_run+0x23>
		for (priority = MAXPRIO; priority >= 0; priority--) {
f010327a:	b8 04 00 00 00       	mov    $0x4,%eax
f010327f:	89 c6                	mov    %eax,%esi
			p = ptable.ready[priority].head;
f0103281:	8b 1c c5 84 8c 16 f0 	mov    -0xfe9737c(,%eax,8),%ebx
			if (p) {
f0103288:	85 db                	test   %ebx,%ebx
f010328a:	0f 85 0c ff ff ff    	jne    f010319c <ucode_run+0xe9>
		for (priority = MAXPRIO; priority >= 0; priority--) {
f0103290:	83 e8 01             	sub    $0x1,%eax
f0103293:	83 f8 ff             	cmp    $0xffffffff,%eax
f0103296:	75 e7                	jne    f010327f <ucode_run+0x1cc>
f0103298:	eb ae                	jmp    f0103248 <ucode_run+0x195>
					panic("In Priority Queue: Empty or process is not in list");
f010329a:	83 ec 04             	sub    $0x4,%esp
f010329d:	68 80 4d 10 f0       	push   $0xf0104d80
f01032a2:	68 73 01 00 00       	push   $0x173
f01032a7:	68 34 4e 10 f0       	push   $0xf0104e34
f01032ac:	e8 e7 ce ff ff       	call   f0100198 <_panic>
					panic("Priority");
f01032b1:	83 ec 04             	sub    $0x4,%esp
f01032b4:	68 a6 4e 10 f0       	push   $0xf0104ea6
f01032b9:	68 75 01 00 00       	push   $0x175
f01032be:	68 34 4e 10 f0       	push   $0xf0104e34
f01032c3:	e8 d0 ce ff ff       	call   f0100198 <_panic>

f01032c8 <thisproc>:
thisproc(void) {
f01032c8:	55                   	push   %ebp
f01032c9:	89 e5                	mov    %esp,%ebp
f01032cb:	53                   	push   %ebx
f01032cc:	83 ec 04             	sub    $0x4,%esp
	pushcli();
f01032cf:	e8 df e7 ff ff       	call   f0101ab3 <pushcli>
	p = thiscpu->proc;
f01032d4:	e8 eb f4 ff ff       	call   f01027c4 <cpunum>
f01032d9:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f01032df:	8b 98 c4 70 12 f0    	mov    -0xfed8f3c(%eax),%ebx
	popcli();
f01032e5:	e8 18 e8 ff ff       	call   f0101b02 <popcli>
}
f01032ea:	89 d8                	mov    %ebx,%eax
f01032ec:	83 c4 04             	add    $0x4,%esp
f01032ef:	5b                   	pop    %ebx
f01032f0:	5d                   	pop    %ebp
f01032f1:	c3                   	ret    

f01032f2 <sched>:
{
f01032f2:	55                   	push   %ebp
f01032f3:	89 e5                	mov    %esp,%ebp
f01032f5:	53                   	push   %ebx
f01032f6:	83 ec 04             	sub    $0x4,%esp
	struct proc *p = thisproc();
f01032f9:	e8 ca ff ff ff       	call   f01032c8 <thisproc>
f01032fe:	89 c3                	mov    %eax,%ebx
	swtch(&p->context, thiscpu->scheduler);
f0103300:	e8 bf f4 ff ff       	call   f01027c4 <cpunum>
f0103305:	83 ec 08             	sub    $0x8,%esp
f0103308:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f010330e:	ff b0 28 70 12 f0    	pushl  -0xfed8fd8(%eax)
f0103314:	83 c3 18             	add    $0x18,%ebx
f0103317:	53                   	push   %ebx
f0103318:	e8 e5 06 00 00       	call   f0103a02 <swtch>
}
f010331d:	83 c4 10             	add    $0x10,%esp
f0103320:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103323:	c9                   	leave  
f0103324:	c3                   	ret    

f0103325 <wakeup1>:

void
wakeup1(void *chan)
{
f0103325:	55                   	push   %ebp
f0103326:	89 e5                	mov    %esp,%ebp
f0103328:	57                   	push   %edi
f0103329:	56                   	push   %esi
f010332a:	53                   	push   %ebx
f010332b:	83 ec 0c             	sub    $0xc,%esp
f010332e:	8b 7d 08             	mov    0x8(%ebp),%edi
	struct proc *p = ptable.list[SLEEPING].head;
f0103331:	8b 1d 64 8c 16 f0    	mov    0xf0168c64,%ebx
	struct proc *tmp;
	while(p) {
f0103337:	eb 43                	jmp    f010337c <wakeup1+0x57>
		tmp = p->next;
		if (p->chan == chan) {
			if (stateListRemove(&ptable.list[SLEEPING], p, "Wakeup") < 0)
				panic("In SLEEPING: Empty or process not in list");
			assertState(p, SLEEPING, "Wakeup");
f0103339:	b9 af 4e 10 f0       	mov    $0xf0104eaf,%ecx
f010333e:	ba 02 00 00 00       	mov    $0x2,%edx
f0103343:	89 d8                	mov    %ebx,%eax
f0103345:	e8 4b f9 ff ff       	call   f0102c95 <assertState>
			cprintf("wakeup pid %d\n", p->pid);
f010334a:	83 ec 08             	sub    $0x8,%esp
f010334d:	ff 73 0c             	pushl  0xc(%ebx)
f0103350:	68 b6 4e 10 f0       	push   $0xf0104eb6
f0103355:	e8 28 d4 ff ff       	call   f0100782 <cprintf>
			p->state = RUNNABLE;
f010335a:	c7 43 08 03 00 00 00 	movl   $0x3,0x8(%ebx)
			stateListAdd(&ptable.ready[p->priority], p, "Wakeup");
f0103361:	8b 43 20             	mov    0x20(%ebx),%eax
f0103364:	8d 04 c5 84 8c 16 f0 	lea    -0xfe9737c(,%eax,8),%eax
f010336b:	b9 af 4e 10 f0       	mov    $0xf0104eaf,%ecx
f0103370:	89 da                	mov    %ebx,%edx
f0103372:	e8 85 f8 ff ff       	call   f0102bfc <stateListAdd>
f0103377:	83 c4 10             	add    $0x10,%esp
{
f010337a:	89 f3                	mov    %esi,%ebx
	while(p) {
f010337c:	85 db                	test   %ebx,%ebx
f010337e:	74 34                	je     f01033b4 <wakeup1+0x8f>
		tmp = p->next;
f0103380:	8b 73 1c             	mov    0x1c(%ebx),%esi
		if (p->chan == chan) {
f0103383:	39 7b 2c             	cmp    %edi,0x2c(%ebx)
f0103386:	75 f2                	jne    f010337a <wakeup1+0x55>
			if (stateListRemove(&ptable.list[SLEEPING], p, "Wakeup") < 0)
f0103388:	b9 af 4e 10 f0       	mov    $0xf0104eaf,%ecx
f010338d:	89 da                	mov    %ebx,%edx
f010338f:	b8 64 8c 16 f0       	mov    $0xf0168c64,%eax
f0103394:	e8 84 f8 ff ff       	call   f0102c1d <stateListRemove>
f0103399:	85 c0                	test   %eax,%eax
f010339b:	79 9c                	jns    f0103339 <wakeup1+0x14>
				panic("In SLEEPING: Empty or process not in list");
f010339d:	83 ec 04             	sub    $0x4,%esp
f01033a0:	68 b4 4d 10 f0       	push   $0xf0104db4
f01033a5:	68 cf 01 00 00       	push   $0x1cf
f01033aa:	68 34 4e 10 f0       	push   $0xf0104e34
f01033af:	e8 e4 cd ff ff       	call   f0100198 <_panic>
		}	
		p = tmp;
	}
}
f01033b4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01033b7:	5b                   	pop    %ebx
f01033b8:	5e                   	pop    %esi
f01033b9:	5f                   	pop    %edi
f01033ba:	5d                   	pop    %ebp
f01033bb:	c3                   	ret    

f01033bc <fork>:

#ifdef DEBUG_MLFQ
int
fork(void)
{
f01033bc:	55                   	push   %ebp
f01033bd:	89 e5                	mov    %esp,%ebp
f01033bf:	57                   	push   %edi
f01033c0:	56                   	push   %esi
f01033c1:	53                   	push   %ebx
f01033c2:	83 ec 0c             	sub    $0xc,%esp
	struct proc *p = thisproc();
f01033c5:	e8 fe fe ff ff       	call   f01032c8 <thisproc>
f01033ca:	89 c6                	mov    %eax,%esi
	struct proc *child;
	if ((child = proc_alloc()) == NULL)
f01033cc:	e8 e2 f8 ff ff       	call   f0102cb3 <proc_alloc>
f01033d1:	85 c0                	test   %eax,%eax
f01033d3:	0f 84 49 01 00 00    	je     f0103522 <fork+0x166>
f01033d9:	89 c3                	mov    %eax,%ebx
		return -1;
	if ((child->pgdir = copyuvm(p->pgdir)) == NULL) {
f01033db:	83 ec 0c             	sub    $0xc,%esp
f01033de:	ff 36                	pushl  (%esi)
f01033e0:	e8 58 e5 ff ff       	call   f010193d <copyuvm>
f01033e5:	89 03                	mov    %eax,(%ebx)
f01033e7:	83 c4 10             	add    $0x10,%esp
f01033ea:	85 c0                	test   %eax,%eax
f01033ec:	0f 84 8c 00 00 00    	je     f010347e <fork+0xc2>
		child->state = UNUSED;
		stateListAdd(&ptable.list[child->state], child, "fork fail");
		spin_unlock(&ptable.lock);
		return -1;
	}
	child->parent = p;
f01033f2:	89 73 10             	mov    %esi,0x10(%ebx)
	*child->tf = *p->tf;
f01033f5:	8b 76 14             	mov    0x14(%esi),%esi
f01033f8:	b9 13 00 00 00       	mov    $0x13,%ecx
f01033fd:	8b 7b 14             	mov    0x14(%ebx),%edi
f0103400:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	// TODO: can't understand the reason for parent id.
	child->tf->eax = 0;
f0103402:	8b 43 14             	mov    0x14(%ebx),%eax
f0103405:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
	spin_lock(&ptable.lock);
f010340c:	83 ec 0c             	sub    $0xc,%esp
f010340f:	68 20 80 16 f0       	push   $0xf0168020
f0103414:	e8 e8 f5 ff ff       	call   f0102a01 <spin_lock>
	if (stateListRemove(&ptable.list[EMBRYO], child, "fork") < 0)
f0103419:	b9 cf 4e 10 f0       	mov    $0xf0104ecf,%ecx
f010341e:	89 da                	mov    %ebx,%edx
f0103420:	b8 5c 8c 16 f0       	mov    $0xf0168c5c,%eax
f0103425:	e8 f3 f7 ff ff       	call   f0102c1d <stateListRemove>
f010342a:	83 c4 10             	add    $0x10,%esp
f010342d:	85 c0                	test   %eax,%eax
f010342f:	0f 88 d6 00 00 00    	js     f010350b <fork+0x14f>
		panic("In EMBRYO: Empty or process not in list");
	assertState(child, EMBRYO, "fork");
f0103435:	b9 cf 4e 10 f0       	mov    $0xf0104ecf,%ecx
f010343a:	ba 01 00 00 00       	mov    $0x1,%edx
f010343f:	89 d8                	mov    %ebx,%eax
f0103441:	e8 4f f8 ff ff       	call   f0102c95 <assertState>
	child->state = RUNNABLE;
f0103446:	c7 43 08 03 00 00 00 	movl   $0x3,0x8(%ebx)
	stateListAdd(&ptable.ready[child->priority], child, "fork");
f010344d:	8b 43 20             	mov    0x20(%ebx),%eax
f0103450:	8d 04 c5 84 8c 16 f0 	lea    -0xfe9737c(,%eax,8),%eax
f0103457:	b9 cf 4e 10 f0       	mov    $0xf0104ecf,%ecx
f010345c:	89 da                	mov    %ebx,%edx
f010345e:	e8 99 f7 ff ff       	call   f0102bfc <stateListAdd>
	spin_unlock(&ptable.lock);
f0103463:	83 ec 0c             	sub    $0xc,%esp
f0103466:	68 20 80 16 f0       	push   $0xf0168020
f010346b:	e8 f9 f5 ff ff       	call   f0102a69 <spin_unlock>
	return child->pid;
f0103470:	8b 43 0c             	mov    0xc(%ebx),%eax
f0103473:	83 c4 10             	add    $0x10,%esp
}
f0103476:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103479:	5b                   	pop    %ebx
f010347a:	5e                   	pop    %esi
f010347b:	5f                   	pop    %edi
f010347c:	5d                   	pop    %ebp
f010347d:	c3                   	ret    
		kfree(child->kstack);
f010347e:	83 ec 0c             	sub    $0xc,%esp
f0103481:	ff 73 04             	pushl  0x4(%ebx)
f0103484:	e8 3e ea ff ff       	call   f0101ec7 <kfree>
		child->kstack = NULL;
f0103489:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
		spin_lock(&ptable.lock);
f0103490:	c7 04 24 20 80 16 f0 	movl   $0xf0168020,(%esp)
f0103497:	e8 65 f5 ff ff       	call   f0102a01 <spin_lock>
		if (stateListRemove(&ptable.list[EMBRYO], child, "fork fail") < 0)
f010349c:	b9 c5 4e 10 f0       	mov    $0xf0104ec5,%ecx
f01034a1:	89 da                	mov    %ebx,%edx
f01034a3:	b8 5c 8c 16 f0       	mov    $0xf0168c5c,%eax
f01034a8:	e8 70 f7 ff ff       	call   f0102c1d <stateListRemove>
f01034ad:	83 c4 10             	add    $0x10,%esp
f01034b0:	85 c0                	test   %eax,%eax
f01034b2:	78 40                	js     f01034f4 <fork+0x138>
		assertState(child, EMBRYO, "fork");
f01034b4:	b9 cf 4e 10 f0       	mov    $0xf0104ecf,%ecx
f01034b9:	ba 01 00 00 00       	mov    $0x1,%edx
f01034be:	89 d8                	mov    %ebx,%eax
f01034c0:	e8 d0 f7 ff ff       	call   f0102c95 <assertState>
		child->state = UNUSED;
f01034c5:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
		stateListAdd(&ptable.list[child->state], child, "fork fail");
f01034cc:	b9 c5 4e 10 f0       	mov    $0xf0104ec5,%ecx
f01034d1:	89 da                	mov    %ebx,%edx
f01034d3:	b8 54 8c 16 f0       	mov    $0xf0168c54,%eax
f01034d8:	e8 1f f7 ff ff       	call   f0102bfc <stateListAdd>
		spin_unlock(&ptable.lock);
f01034dd:	83 ec 0c             	sub    $0xc,%esp
f01034e0:	68 20 80 16 f0       	push   $0xf0168020
f01034e5:	e8 7f f5 ff ff       	call   f0102a69 <spin_unlock>
		return -1;
f01034ea:	83 c4 10             	add    $0x10,%esp
f01034ed:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01034f2:	eb 82                	jmp    f0103476 <fork+0xba>
			panic("In EMBRYO: Empty or process not in list");
f01034f4:	83 ec 04             	sub    $0x4,%esp
f01034f7:	68 58 4d 10 f0       	push   $0xf0104d58
f01034fc:	68 e6 01 00 00       	push   $0x1e6
f0103501:	68 34 4e 10 f0       	push   $0xf0104e34
f0103506:	e8 8d cc ff ff       	call   f0100198 <_panic>
		panic("In EMBRYO: Empty or process not in list");
f010350b:	83 ec 04             	sub    $0x4,%esp
f010350e:	68 58 4d 10 f0       	push   $0xf0104d58
f0103513:	68 f3 01 00 00       	push   $0x1f3
f0103518:	68 34 4e 10 f0       	push   $0xf0104e34
f010351d:	e8 76 cc ff ff       	call   f0100198 <_panic>
		return -1;
f0103522:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103527:	e9 4a ff ff ff       	jmp    f0103476 <fork+0xba>

f010352c <exit>:

void
exit(void)
{
f010352c:	55                   	push   %ebp
f010352d:	89 e5                	mov    %esp,%ebp
f010352f:	53                   	push   %ebx
f0103530:	83 ec 04             	sub    $0x4,%esp
	// sys_exit() call to here.
	// TODO: your code here.
	struct proc *p = thisproc();
f0103533:	e8 90 fd ff ff       	call   f01032c8 <thisproc>
f0103538:	89 c3                	mov    %eax,%ebx
	cprintf("process %d exit.\n", p->pid);
f010353a:	83 ec 08             	sub    $0x8,%esp
f010353d:	ff 70 0c             	pushl  0xc(%eax)
f0103540:	68 d4 4e 10 f0       	push   $0xf0104ed4
f0103545:	e8 38 d2 ff ff       	call   f0100782 <cprintf>
	spin_lock(&ptable.lock);
f010354a:	c7 04 24 20 80 16 f0 	movl   $0xf0168020,(%esp)
f0103551:	e8 ab f4 ff ff       	call   f0102a01 <spin_lock>
	if (p->parent) {
f0103556:	8b 43 10             	mov    0x10(%ebx),%eax
f0103559:	83 c4 10             	add    $0x10,%esp
f010355c:	85 c0                	test   %eax,%eax
f010355e:	74 1e                	je     f010357e <exit+0x52>
		cprintf("parent:%d\n", p->parent->pid);
f0103560:	83 ec 08             	sub    $0x8,%esp
f0103563:	ff 70 0c             	pushl  0xc(%eax)
f0103566:	68 e6 4e 10 f0       	push   $0xf0104ee6
f010356b:	e8 12 d2 ff ff       	call   f0100782 <cprintf>
		wakeup1(p->parent); // TODO: need root process
f0103570:	83 c4 04             	add    $0x4,%esp
f0103573:	ff 73 10             	pushl  0x10(%ebx)
f0103576:	e8 aa fd ff ff       	call   f0103325 <wakeup1>
f010357b:	83 c4 10             	add    $0x10,%esp
	}
	if (stateListRemove(&ptable.list[RUNNING], p, "exit") < 0)
f010357e:	b9 f1 4e 10 f0       	mov    $0xf0104ef1,%ecx
f0103583:	89 da                	mov    %ebx,%edx
f0103585:	b8 74 8c 16 f0       	mov    $0xf0168c74,%eax
f010358a:	e8 8e f6 ff ff       	call   f0102c1d <stateListRemove>
f010358f:	85 c0                	test   %eax,%eax
f0103591:	78 33                	js     f01035c6 <exit+0x9a>
		panic("In RUNNING: Empty or process is not in list");
	assertState(p, RUNNING, "exit");
f0103593:	b9 f1 4e 10 f0       	mov    $0xf0104ef1,%ecx
f0103598:	ba 04 00 00 00       	mov    $0x4,%edx
f010359d:	89 d8                	mov    %ebx,%eax
f010359f:	e8 f1 f6 ff ff       	call   f0102c95 <assertState>
	p->state = ZOMBIE;
f01035a4:	c7 43 08 05 00 00 00 	movl   $0x5,0x8(%ebx)
	stateListAdd(&ptable.list[p->state], p, "exit");
f01035ab:	b9 f1 4e 10 f0       	mov    $0xf0104ef1,%ecx
f01035b0:	89 da                	mov    %ebx,%edx
f01035b2:	b8 7c 8c 16 f0       	mov    $0xf0168c7c,%eax
f01035b7:	e8 40 f6 ff ff       	call   f0102bfc <stateListAdd>
	sched();
f01035bc:	e8 31 fd ff ff       	call   f01032f2 <sched>
}
f01035c1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01035c4:	c9                   	leave  
f01035c5:	c3                   	ret    
		panic("In RUNNING: Empty or process is not in list");
f01035c6:	83 ec 04             	sub    $0x4,%esp
f01035c9:	68 e0 4d 10 f0       	push   $0xf0104de0
f01035ce:	68 08 02 00 00       	push   $0x208
f01035d3:	68 34 4e 10 f0       	push   $0xf0104e34
f01035d8:	e8 bb cb ff ff       	call   f0100198 <_panic>

f01035dd <yield>:

// TODO: run enough time!!!
void
yield(void)
{
f01035dd:	55                   	push   %ebp
f01035de:	89 e5                	mov    %esp,%ebp
f01035e0:	53                   	push   %ebx
f01035e1:	83 ec 04             	sub    $0x4,%esp
	struct proc *p = thisproc();
f01035e4:	e8 df fc ff ff       	call   f01032c8 <thisproc>
f01035e9:	89 c3                	mov    %eax,%ebx
	spin_lock(&ptable.lock);
f01035eb:	83 ec 0c             	sub    $0xc,%esp
f01035ee:	68 20 80 16 f0       	push   $0xf0168020
f01035f3:	e8 09 f4 ff ff       	call   f0102a01 <spin_lock>
	if (stateListRemove(&ptable.list[RUNNING], p, "yield") < 0)
f01035f8:	b9 f6 4e 10 f0       	mov    $0xf0104ef6,%ecx
f01035fd:	89 da                	mov    %ebx,%edx
f01035ff:	b8 74 8c 16 f0       	mov    $0xf0168c74,%eax
f0103604:	e8 14 f6 ff ff       	call   f0102c1d <stateListRemove>
f0103609:	83 c4 10             	add    $0x10,%esp
f010360c:	85 c0                	test   %eax,%eax
f010360e:	78 46                	js     f0103656 <yield+0x79>
		panic("In RUNNING: Empty or process is not in list");
	assertState(p, RUNNING, "yield");
f0103610:	b9 f6 4e 10 f0       	mov    $0xf0104ef6,%ecx
f0103615:	ba 04 00 00 00       	mov    $0x4,%edx
f010361a:	89 d8                	mov    %ebx,%eax
f010361c:	e8 74 f6 ff ff       	call   f0102c95 <assertState>
	p->state = RUNNABLE;
f0103621:	c7 43 08 03 00 00 00 	movl   $0x3,0x8(%ebx)
	if (p->priority > 0) {
f0103628:	8b 43 20             	mov    0x20(%ebx),%eax
f010362b:	85 c0                	test   %eax,%eax
f010362d:	75 3e                	jne    f010366d <yield+0x90>
		// cprintf("priority %d\n", p->priority);
		p->priority--;
		stateListAdd(&ptable.ready[p->priority], p, "yield");
		// cprintf("priority %d\n", p->priority);
	}
	p->budget = time_slice[p->priority];
f010362f:	8b 43 20             	mov    0x20(%ebx),%eax
f0103632:	8b 04 85 38 e7 11 f0 	mov    -0xfee18c8(,%eax,4),%eax
f0103639:	89 43 24             	mov    %eax,0x24(%ebx)
	sched();
f010363c:	e8 b1 fc ff ff       	call   f01032f2 <sched>
	spin_unlock(&ptable.lock);
f0103641:	83 ec 0c             	sub    $0xc,%esp
f0103644:	68 20 80 16 f0       	push   $0xf0168020
f0103649:	e8 1b f4 ff ff       	call   f0102a69 <spin_unlock>
}
f010364e:	83 c4 10             	add    $0x10,%esp
f0103651:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103654:	c9                   	leave  
f0103655:	c3                   	ret    
		panic("In RUNNING: Empty or process is not in list");
f0103656:	83 ec 04             	sub    $0x4,%esp
f0103659:	68 e0 4d 10 f0       	push   $0xf0104de0
f010365e:	68 16 02 00 00       	push   $0x216
f0103663:	68 34 4e 10 f0       	push   $0xf0104e34
f0103668:	e8 2b cb ff ff       	call   f0100198 <_panic>
		p->priority--;
f010366d:	8d 50 ff             	lea    -0x1(%eax),%edx
f0103670:	89 53 20             	mov    %edx,0x20(%ebx)
		stateListAdd(&ptable.ready[p->priority], p, "yield");
f0103673:	8d 04 c5 7c 8c 16 f0 	lea    -0xfe97384(,%eax,8),%eax
f010367a:	b9 f6 4e 10 f0       	mov    $0xf0104ef6,%ecx
f010367f:	89 da                	mov    %ebx,%edx
f0103681:	e8 76 f5 ff ff       	call   f0102bfc <stateListAdd>
f0103686:	eb a7                	jmp    f010362f <yield+0x52>

f0103688 <sleep>:

void
sleep(void *chan, struct spinlock *lk)
{
f0103688:	55                   	push   %ebp
f0103689:	89 e5                	mov    %esp,%ebp
f010368b:	56                   	push   %esi
f010368c:	53                   	push   %ebx
f010368d:	8b 75 0c             	mov    0xc(%ebp),%esi
	struct proc *p = thisproc();
f0103690:	e8 33 fc ff ff       	call   f01032c8 <thisproc>
	if (p == NULL)
f0103695:	85 c0                	test   %eax,%eax
f0103697:	0f 84 a1 00 00 00    	je     f010373e <sleep+0xb6>
f010369d:	89 c3                	mov    %eax,%ebx
		panic("sleep");
	if (lk == NULL)
f010369f:	85 f6                	test   %esi,%esi
f01036a1:	0f 84 ae 00 00 00    	je     f0103755 <sleep+0xcd>
		panic("sleep without tickslock");
	if (lk != &ptable.lock) {
f01036a7:	81 fe 20 80 16 f0    	cmp    $0xf0168020,%esi
f01036ad:	0f 84 d0 00 00 00    	je     f0103783 <sleep+0xfb>
		spin_lock(&ptable.lock);
f01036b3:	83 ec 0c             	sub    $0xc,%esp
f01036b6:	68 20 80 16 f0       	push   $0xf0168020
f01036bb:	e8 41 f3 ff ff       	call   f0102a01 <spin_lock>
		spin_unlock(lk);
f01036c0:	89 34 24             	mov    %esi,(%esp)
f01036c3:	e8 a1 f3 ff ff       	call   f0102a69 <spin_unlock>
	}
	if (stateListRemove(&ptable.list[RUNNING], p, "Sleep") < 0)
f01036c8:	b9 1a 4f 10 f0       	mov    $0xf0104f1a,%ecx
f01036cd:	89 da                	mov    %ebx,%edx
f01036cf:	b8 74 8c 16 f0       	mov    $0xf0168c74,%eax
f01036d4:	e8 44 f5 ff ff       	call   f0102c1d <stateListRemove>
f01036d9:	83 c4 10             	add    $0x10,%esp
f01036dc:	85 c0                	test   %eax,%eax
f01036de:	0f 88 88 00 00 00    	js     f010376c <sleep+0xe4>
		panic("In Priority Queue: Empty or process is not in list");
	assertState(p, RUNNING, "Sleep");
f01036e4:	b9 1a 4f 10 f0       	mov    $0xf0104f1a,%ecx
f01036e9:	ba 04 00 00 00       	mov    $0x4,%edx
f01036ee:	89 d8                	mov    %ebx,%eax
f01036f0:	e8 a0 f5 ff ff       	call   f0102c95 <assertState>
	p->chan = chan;
f01036f5:	8b 45 08             	mov    0x8(%ebp),%eax
f01036f8:	89 43 2c             	mov    %eax,0x2c(%ebx)
	p->state = SLEEPING;
f01036fb:	c7 43 08 02 00 00 00 	movl   $0x2,0x8(%ebx)
	stateListAdd(&ptable.list[p->state], p, "Sleep");
f0103702:	b9 1a 4f 10 f0       	mov    $0xf0104f1a,%ecx
f0103707:	89 da                	mov    %ebx,%edx
f0103709:	b8 64 8c 16 f0       	mov    $0xf0168c64,%eax
f010370e:	e8 e9 f4 ff ff       	call   f0102bfc <stateListAdd>
	sched();
f0103713:	e8 da fb ff ff       	call   f01032f2 <sched>
	p->chan = NULL;
f0103718:	c7 43 2c 00 00 00 00 	movl   $0x0,0x2c(%ebx)
	if (lk != &ptable.lock) {
		spin_unlock(&ptable.lock);
f010371f:	83 ec 0c             	sub    $0xc,%esp
f0103722:	68 20 80 16 f0       	push   $0xf0168020
f0103727:	e8 3d f3 ff ff       	call   f0102a69 <spin_unlock>
		spin_lock(lk);
f010372c:	89 34 24             	mov    %esi,(%esp)
f010372f:	e8 cd f2 ff ff       	call   f0102a01 <spin_lock>
f0103734:	83 c4 10             	add    $0x10,%esp
	}
}
f0103737:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010373a:	5b                   	pop    %ebx
f010373b:	5e                   	pop    %esi
f010373c:	5d                   	pop    %ebp
f010373d:	c3                   	ret    
		panic("sleep");
f010373e:	83 ec 04             	sub    $0x4,%esp
f0103741:	68 fc 4e 10 f0       	push   $0xf0104efc
f0103746:	68 29 02 00 00       	push   $0x229
f010374b:	68 34 4e 10 f0       	push   $0xf0104e34
f0103750:	e8 43 ca ff ff       	call   f0100198 <_panic>
		panic("sleep without tickslock");
f0103755:	83 ec 04             	sub    $0x4,%esp
f0103758:	68 02 4f 10 f0       	push   $0xf0104f02
f010375d:	68 2b 02 00 00       	push   $0x22b
f0103762:	68 34 4e 10 f0       	push   $0xf0104e34
f0103767:	e8 2c ca ff ff       	call   f0100198 <_panic>
		panic("In Priority Queue: Empty or process is not in list");
f010376c:	83 ec 04             	sub    $0x4,%esp
f010376f:	68 80 4d 10 f0       	push   $0xf0104d80
f0103774:	68 31 02 00 00       	push   $0x231
f0103779:	68 34 4e 10 f0       	push   $0xf0104e34
f010377e:	e8 15 ca ff ff       	call   f0100198 <_panic>
	if (stateListRemove(&ptable.list[RUNNING], p, "Sleep") < 0)
f0103783:	b9 1a 4f 10 f0       	mov    $0xf0104f1a,%ecx
f0103788:	89 c2                	mov    %eax,%edx
f010378a:	b8 74 8c 16 f0       	mov    $0xf0168c74,%eax
f010378f:	e8 89 f4 ff ff       	call   f0102c1d <stateListRemove>
f0103794:	85 c0                	test   %eax,%eax
f0103796:	78 d4                	js     f010376c <sleep+0xe4>
	assertState(p, RUNNING, "Sleep");
f0103798:	b9 1a 4f 10 f0       	mov    $0xf0104f1a,%ecx
f010379d:	ba 04 00 00 00       	mov    $0x4,%edx
f01037a2:	89 d8                	mov    %ebx,%eax
f01037a4:	e8 ec f4 ff ff       	call   f0102c95 <assertState>
	p->chan = chan;
f01037a9:	8b 45 08             	mov    0x8(%ebp),%eax
f01037ac:	89 43 2c             	mov    %eax,0x2c(%ebx)
	p->state = SLEEPING;
f01037af:	c7 43 08 02 00 00 00 	movl   $0x2,0x8(%ebx)
	stateListAdd(&ptable.list[p->state], p, "Sleep");
f01037b6:	b9 1a 4f 10 f0       	mov    $0xf0104f1a,%ecx
f01037bb:	89 da                	mov    %ebx,%edx
f01037bd:	b8 64 8c 16 f0       	mov    $0xf0168c64,%eax
f01037c2:	e8 35 f4 ff ff       	call   f0102bfc <stateListAdd>
	sched();
f01037c7:	e8 26 fb ff ff       	call   f01032f2 <sched>
	p->chan = NULL;
f01037cc:	c7 43 2c 00 00 00 00 	movl   $0x0,0x2c(%ebx)
f01037d3:	e9 5f ff ff ff       	jmp    f0103737 <sleep+0xaf>

f01037d8 <wait>:

int
wait(void)
{
f01037d8:	55                   	push   %ebp
f01037d9:	89 e5                	mov    %esp,%ebp
f01037db:	56                   	push   %esi
f01037dc:	53                   	push   %ebx
	struct proc *p = thisproc();
f01037dd:	e8 e6 fa ff ff       	call   f01032c8 <thisproc>
f01037e2:	89 c6                	mov    %eax,%esi
	struct proc *q, *tmp;
	uint32_t pid;
	spin_lock(&ptable.lock);
f01037e4:	83 ec 0c             	sub    $0xc,%esp
f01037e7:	68 20 80 16 f0       	push   $0xf0168020
f01037ec:	e8 10 f2 ff ff       	call   f0102a01 <spin_lock>
f01037f1:	83 c4 10             	add    $0x10,%esp
f01037f4:	e9 be 00 00 00       	jmp    f01038b7 <wait+0xdf>
	for (;;) {
		q = ptable.list[ZOMBIE].head;
		while (q) {
			tmp = q->next;
			if (q->parent == p) {
				if (stateListRemove(&ptable.list[ZOMBIE], q, "Wait") < 0)
f01037f9:	b9 20 4f 10 f0       	mov    $0xf0104f20,%ecx
f01037fe:	89 da                	mov    %ebx,%edx
f0103800:	b8 7c 8c 16 f0       	mov    $0xf0168c7c,%eax
f0103805:	e8 13 f4 ff ff       	call   f0102c1d <stateListRemove>
f010380a:	85 c0                	test   %eax,%eax
f010380c:	78 71                	js     f010387f <wait+0xa7>
					panic("In ZOMBIE: Empty or process not in list");
				assertState(q, ZOMBIE, "Wait");
f010380e:	b9 20 4f 10 f0       	mov    $0xf0104f20,%ecx
f0103813:	ba 05 00 00 00       	mov    $0x5,%edx
f0103818:	89 d8                	mov    %ebx,%eax
f010381a:	e8 76 f4 ff ff       	call   f0102c95 <assertState>
				q->state = UNUSED;
f010381f:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
				stateListAdd(&ptable.list[q->state], q, "Wait");
f0103826:	b9 20 4f 10 f0       	mov    $0xf0104f20,%ecx
f010382b:	89 da                	mov    %ebx,%edx
f010382d:	b8 54 8c 16 f0       	mov    $0xf0168c54,%eax
f0103832:	e8 c5 f3 ff ff       	call   f0102bfc <stateListAdd>
				pid = q->pid;
f0103837:	8b 73 0c             	mov    0xc(%ebx),%esi
				vm_free(q->pgdir);
f010383a:	83 ec 0c             	sub    $0xc,%esp
f010383d:	ff 33                	pushl  (%ebx)
f010383f:	e8 a1 e0 ff ff       	call   f01018e5 <vm_free>
				kfree(q->kstack);
f0103844:	83 c4 04             	add    $0x4,%esp
f0103847:	ff 73 04             	pushl  0x4(%ebx)
f010384a:	e8 78 e6 ff ff       	call   f0101ec7 <kfree>
				q->kstack = NULL;
f010384f:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
				q->pgdir = NULL;
f0103856:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
				q->parent = NULL;
f010385c:	c7 43 10 00 00 00 00 	movl   $0x0,0x10(%ebx)
				q->pid = 0;
f0103863:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
				spin_unlock(&ptable.lock);
f010386a:	c7 04 24 20 80 16 f0 	movl   $0xf0168020,(%esp)
f0103871:	e8 f3 f1 ff ff       	call   f0102a69 <spin_unlock>
			q = tmp;
		}
		cprintf("sleep %d\n", p->pid);
		sleep(p, &ptable.lock);
	}
}
f0103876:	89 f0                	mov    %esi,%eax
f0103878:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010387b:	5b                   	pop    %ebx
f010387c:	5e                   	pop    %esi
f010387d:	5d                   	pop    %ebp
f010387e:	c3                   	ret    
					panic("In ZOMBIE: Empty or process not in list");
f010387f:	83 ec 04             	sub    $0x4,%esp
f0103882:	68 0c 4e 10 f0       	push   $0xf0104e0c
f0103887:	68 4b 02 00 00       	push   $0x24b
f010388c:	68 34 4e 10 f0       	push   $0xf0104e34
f0103891:	e8 02 c9 ff ff       	call   f0100198 <_panic>
		cprintf("sleep %d\n", p->pid);
f0103896:	83 ec 08             	sub    $0x8,%esp
f0103899:	ff 76 0c             	pushl  0xc(%esi)
f010389c:	68 25 4f 10 f0       	push   $0xf0104f25
f01038a1:	e8 dc ce ff ff       	call   f0100782 <cprintf>
		sleep(p, &ptable.lock);
f01038a6:	83 c4 08             	add    $0x8,%esp
f01038a9:	68 20 80 16 f0       	push   $0xf0168020
f01038ae:	56                   	push   %esi
f01038af:	e8 d4 fd ff ff       	call   f0103688 <sleep>
		q = ptable.list[ZOMBIE].head;
f01038b4:	83 c4 10             	add    $0x10,%esp
f01038b7:	8b 1d 7c 8c 16 f0    	mov    0xf0168c7c,%ebx
		while (q) {
f01038bd:	85 db                	test   %ebx,%ebx
f01038bf:	74 d5                	je     f0103896 <wait+0xbe>
			tmp = q->next;
f01038c1:	8b 43 1c             	mov    0x1c(%ebx),%eax
			if (q->parent == p) {
f01038c4:	39 73 10             	cmp    %esi,0x10(%ebx)
f01038c7:	0f 84 2c ff ff ff    	je     f01037f9 <wait+0x21>
			q = tmp;
f01038cd:	89 c3                	mov    %eax,%ebx
f01038cf:	eb ec                	jmp    f01038bd <wait+0xe5>

f01038d1 <kill>:

int
kill(uint32_t pid) // TODO
{
f01038d1:	55                   	push   %ebp
f01038d2:	89 e5                	mov    %esp,%ebp
f01038d4:	83 ec 14             	sub    $0x14,%esp
	struct proc *p;
	spin_lock(&ptable.lock);
f01038d7:	68 20 80 16 f0       	push   $0xf0168020
f01038dc:	e8 20 f1 ff ff       	call   f0102a01 <spin_lock>
	return 0;
}
f01038e1:	b8 00 00 00 00       	mov    $0x0,%eax
f01038e6:	c9                   	leave  
f01038e7:	c3                   	ret    

f01038e8 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f01038e8:	55                   	push   %ebp
f01038e9:	89 e5                	mov    %esp,%ebp
f01038eb:	57                   	push   %edi
f01038ec:	56                   	push   %esi
f01038ed:	53                   	push   %ebx
f01038ee:	83 ec 0c             	sub    $0xc,%esp
f01038f1:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// TODO: Your code here.
	struct proc *p = thisproc();
f01038f4:	e8 cf f9 ff ff       	call   f01032c8 <thisproc>
	switch (syscallno) {
f01038f9:	83 fb 06             	cmp    $0x6,%ebx
f01038fc:	0f 87 f6 00 00 00    	ja     f01039f8 <syscall+0x110>
f0103902:	ff 24 9d 30 4f 10 f0 	jmp    *-0xfefb0d0(,%ebx,4)
	struct proc *p = thisproc();
f0103909:	e8 ba f9 ff ff       	call   f01032c8 <thisproc>
f010390e:	89 c7                	mov    %eax,%edi
	void *begin = ROUNDDOWN(tmp, PGSIZE);
f0103910:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103913:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	void *end = ROUNDUP(tmp + len, PGSIZE);
f0103919:	8b 45 10             	mov    0x10(%ebp),%eax
f010391c:	8b 55 0c             	mov    0xc(%ebp),%edx
f010391f:	8d b4 02 ff 0f 00 00 	lea    0xfff(%edx,%eax,1),%esi
f0103926:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
f010392c:	eb 05                	jmp    f0103933 <syscall+0x4b>
			exit();
f010392e:	e8 f9 fb ff ff       	call   f010352c <exit>
	while (begin < end) {
f0103933:	39 de                	cmp    %ebx,%esi
f0103935:	76 1d                	jbe    f0103954 <syscall+0x6c>
		pte_t *pte = pgdir_walk(p->pgdir, begin, 0);
f0103937:	83 ec 04             	sub    $0x4,%esp
f010393a:	6a 00                	push   $0x0
f010393c:	53                   	push   %ebx
f010393d:	ff 37                	pushl  (%edi)
f010393f:	e8 ed db ff ff       	call   f0101531 <pgdir_walk>
		if (*pte & PTE_U)
f0103944:	83 c4 10             	add    $0x10,%esp
f0103947:	f6 00 04             	testb  $0x4,(%eax)
f010394a:	74 e2                	je     f010392e <syscall+0x46>
			begin += PGSIZE;
f010394c:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0103952:	eb df                	jmp    f0103933 <syscall+0x4b>
	cprintf(s);
f0103954:	83 ec 0c             	sub    $0xc,%esp
f0103957:	ff 75 0c             	pushl  0xc(%ebp)
f010395a:	e8 23 ce ff ff       	call   f0100782 <cprintf>
f010395f:	83 c4 10             	add    $0x10,%esp
		case SYS_cputs:
			sys_cputs((const char *)a1, (size_t)a2);
			return 0;
f0103962:	b8 00 00 00 00       	mov    $0x0,%eax
			return 0;
		default:
			return 0;
	}
	
f0103967:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010396a:	5b                   	pop    %ebx
f010396b:	5e                   	pop    %esi
f010396c:	5f                   	pop    %edi
f010396d:	5d                   	pop    %ebp
f010396e:	c3                   	ret    
	return cons_getc();
f010396f:	e8 53 cc ff ff       	call   f01005c7 <cons_getc>
			return sys_cgetc();
f0103974:	eb f1                	jmp    f0103967 <syscall+0x7f>
	exit();
f0103976:	e8 b1 fb ff ff       	call   f010352c <exit>
			return 0;
f010397b:	b8 00 00 00 00       	mov    $0x0,%eax
f0103980:	eb e5                	jmp    f0103967 <syscall+0x7f>
	return fork();
f0103982:	e8 35 fa ff ff       	call   f01033bc <fork>
			return sys_fork();
f0103987:	eb de                	jmp    f0103967 <syscall+0x7f>
	struct proc *p = thisproc();
f0103989:	e8 3a f9 ff ff       	call   f01032c8 <thisproc>
	spin_lock(&tickslock);
f010398e:	83 ec 0c             	sub    $0xc,%esp
f0103991:	68 60 66 12 f0       	push   $0xf0126660
f0103996:	e8 66 f0 ff ff       	call   f0102a01 <spin_lock>
	uint32_t ticks0 = ticks;
f010399b:	8b 1d a0 6e 12 f0    	mov    0xf0126ea0,%ebx
f01039a1:	83 c4 10             	add    $0x10,%esp
f01039a4:	eb 15                	jmp    f01039bb <syscall+0xd3>
		sleep(&ticks, &tickslock);
f01039a6:	83 ec 08             	sub    $0x8,%esp
f01039a9:	68 60 66 12 f0       	push   $0xf0126660
f01039ae:	68 a0 6e 12 f0       	push   $0xf0126ea0
f01039b3:	e8 d0 fc ff ff       	call   f0103688 <sleep>
f01039b8:	83 c4 10             	add    $0x10,%esp
	while(ticks - ticks0 < n) {
f01039bb:	a1 a0 6e 12 f0       	mov    0xf0126ea0,%eax
f01039c0:	29 d8                	sub    %ebx,%eax
f01039c2:	39 45 0c             	cmp    %eax,0xc(%ebp)
f01039c5:	77 df                	ja     f01039a6 <syscall+0xbe>
	spin_unlock(&tickslock);
f01039c7:	83 ec 0c             	sub    $0xc,%esp
f01039ca:	68 60 66 12 f0       	push   $0xf0126660
f01039cf:	e8 95 f0 ff ff       	call   f0102a69 <spin_unlock>
f01039d4:	83 c4 10             	add    $0x10,%esp
			return 0;
f01039d7:	b8 00 00 00 00       	mov    $0x0,%eax
f01039dc:	eb 89                	jmp    f0103967 <syscall+0x7f>
	return wait();
f01039de:	e8 f5 fd ff ff       	call   f01037d8 <wait>
			return sys_wait();
f01039e3:	eb 82                	jmp    f0103967 <syscall+0x7f>
	return kill(pid);
f01039e5:	83 ec 0c             	sub    $0xc,%esp
f01039e8:	ff 75 0c             	pushl  0xc(%ebp)
f01039eb:	e8 e1 fe ff ff       	call   f01038d1 <kill>
			return sys_kill(a1);
f01039f0:	83 c4 10             	add    $0x10,%esp
f01039f3:	e9 6f ff ff ff       	jmp    f0103967 <syscall+0x7f>
			return 0;
f01039f8:	b8 00 00 00 00       	mov    $0x0,%eax
f01039fd:	e9 65 ff ff ff       	jmp    f0103967 <syscall+0x7f>

f0103a02 <swtch>:
# Switch stacks to new and pop previously-saved registers.

.globl swtch
swtch:
	# TODO: your code here
	movl 4(%esp), %eax # old
f0103a02:	8b 44 24 04          	mov    0x4(%esp),%eax
	movl 8(%esp), %edx # new
f0103a06:	8b 54 24 08          	mov    0x8(%esp),%edx
	# Save old callee-saved registers
	pushl %ebp
f0103a0a:	55                   	push   %ebp
	pushl %ebx
f0103a0b:	53                   	push   %ebx
	pushl %esi
f0103a0c:	56                   	push   %esi
	pushl %edi
f0103a0d:	57                   	push   %edi
	# Switch stacks
	movl %esp, (%eax)
f0103a0e:	89 20                	mov    %esp,(%eax)
	movl %edx, %esp
f0103a10:	89 d4                	mov    %edx,%esp
	# Load new callee-saved registers
	popl %edi
f0103a12:	5f                   	pop    %edi
	popl %esi
f0103a13:	5e                   	pop    %esi
	popl %ebx
f0103a14:	5b                   	pop    %ebx
	popl %ebp
f0103a15:	5d                   	pop    %ebp
f0103a16:	c3                   	ret    

f0103a17 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103a17:	55                   	push   %ebp
f0103a18:	89 e5                	mov    %esp,%ebp
f0103a1a:	57                   	push   %edi
f0103a1b:	56                   	push   %esi
f0103a1c:	53                   	push   %ebx
f0103a1d:	83 ec 1c             	sub    $0x1c,%esp
f0103a20:	89 c7                	mov    %eax,%edi
f0103a22:	89 d6                	mov    %edx,%esi
f0103a24:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a27:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103a2a:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103a2d:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103a30:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0103a33:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103a38:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103a3b:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0103a3e:	39 d3                	cmp    %edx,%ebx
f0103a40:	72 05                	jb     f0103a47 <printnum+0x30>
f0103a42:	39 45 10             	cmp    %eax,0x10(%ebp)
f0103a45:	77 7a                	ja     f0103ac1 <printnum+0xaa>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0103a47:	83 ec 0c             	sub    $0xc,%esp
f0103a4a:	ff 75 18             	pushl  0x18(%ebp)
f0103a4d:	8b 45 14             	mov    0x14(%ebp),%eax
f0103a50:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0103a53:	53                   	push   %ebx
f0103a54:	ff 75 10             	pushl  0x10(%ebp)
f0103a57:	83 ec 08             	sub    $0x8,%esp
f0103a5a:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103a5d:	ff 75 e0             	pushl  -0x20(%ebp)
f0103a60:	ff 75 dc             	pushl  -0x24(%ebp)
f0103a63:	ff 75 d8             	pushl  -0x28(%ebp)
f0103a66:	e8 e5 09 00 00       	call   f0104450 <__udivdi3>
f0103a6b:	83 c4 18             	add    $0x18,%esp
f0103a6e:	52                   	push   %edx
f0103a6f:	50                   	push   %eax
f0103a70:	89 f2                	mov    %esi,%edx
f0103a72:	89 f8                	mov    %edi,%eax
f0103a74:	e8 9e ff ff ff       	call   f0103a17 <printnum>
f0103a79:	83 c4 20             	add    $0x20,%esp
f0103a7c:	eb 13                	jmp    f0103a91 <printnum+0x7a>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0103a7e:	83 ec 08             	sub    $0x8,%esp
f0103a81:	56                   	push   %esi
f0103a82:	ff 75 18             	pushl  0x18(%ebp)
f0103a85:	ff d7                	call   *%edi
f0103a87:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f0103a8a:	83 eb 01             	sub    $0x1,%ebx
f0103a8d:	85 db                	test   %ebx,%ebx
f0103a8f:	7f ed                	jg     f0103a7e <printnum+0x67>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103a91:	83 ec 08             	sub    $0x8,%esp
f0103a94:	56                   	push   %esi
f0103a95:	83 ec 04             	sub    $0x4,%esp
f0103a98:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103a9b:	ff 75 e0             	pushl  -0x20(%ebp)
f0103a9e:	ff 75 dc             	pushl  -0x24(%ebp)
f0103aa1:	ff 75 d8             	pushl  -0x28(%ebp)
f0103aa4:	e8 c7 0a 00 00       	call   f0104570 <__umoddi3>
f0103aa9:	83 c4 14             	add    $0x14,%esp
f0103aac:	0f be 80 4c 4f 10 f0 	movsbl -0xfefb0b4(%eax),%eax
f0103ab3:	50                   	push   %eax
f0103ab4:	ff d7                	call   *%edi
}
f0103ab6:	83 c4 10             	add    $0x10,%esp
f0103ab9:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103abc:	5b                   	pop    %ebx
f0103abd:	5e                   	pop    %esi
f0103abe:	5f                   	pop    %edi
f0103abf:	5d                   	pop    %ebp
f0103ac0:	c3                   	ret    
f0103ac1:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0103ac4:	eb c4                	jmp    f0103a8a <printnum+0x73>

f0103ac6 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103ac6:	55                   	push   %ebp
f0103ac7:	89 e5                	mov    %esp,%ebp
f0103ac9:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0103acc:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103ad0:	8b 10                	mov    (%eax),%edx
f0103ad2:	3b 50 04             	cmp    0x4(%eax),%edx
f0103ad5:	73 0a                	jae    f0103ae1 <sprintputch+0x1b>
		*b->buf++ = ch;
f0103ad7:	8d 4a 01             	lea    0x1(%edx),%ecx
f0103ada:	89 08                	mov    %ecx,(%eax)
f0103adc:	8b 45 08             	mov    0x8(%ebp),%eax
f0103adf:	88 02                	mov    %al,(%edx)
}
f0103ae1:	5d                   	pop    %ebp
f0103ae2:	c3                   	ret    

f0103ae3 <printfmt>:
{
f0103ae3:	55                   	push   %ebp
f0103ae4:	89 e5                	mov    %esp,%ebp
f0103ae6:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f0103ae9:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0103aec:	50                   	push   %eax
f0103aed:	ff 75 10             	pushl  0x10(%ebp)
f0103af0:	ff 75 0c             	pushl  0xc(%ebp)
f0103af3:	ff 75 08             	pushl  0x8(%ebp)
f0103af6:	e8 05 00 00 00       	call   f0103b00 <vprintfmt>
}
f0103afb:	83 c4 10             	add    $0x10,%esp
f0103afe:	c9                   	leave  
f0103aff:	c3                   	ret    

f0103b00 <vprintfmt>:
{
f0103b00:	55                   	push   %ebp
f0103b01:	89 e5                	mov    %esp,%ebp
f0103b03:	57                   	push   %edi
f0103b04:	56                   	push   %esi
f0103b05:	53                   	push   %ebx
f0103b06:	83 ec 2c             	sub    $0x2c,%esp
f0103b09:	8b 75 08             	mov    0x8(%ebp),%esi
f0103b0c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103b0f:	8b 7d 10             	mov    0x10(%ebp),%edi
f0103b12:	e9 c1 03 00 00       	jmp    f0103ed8 <vprintfmt+0x3d8>
		padc = ' ';
f0103b17:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
f0103b1b:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
f0103b22:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
		width = -1;
f0103b29:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f0103b30:	b9 00 00 00 00       	mov    $0x0,%ecx
		switch (ch = *(unsigned char *) fmt++) {
f0103b35:	8d 47 01             	lea    0x1(%edi),%eax
f0103b38:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103b3b:	0f b6 17             	movzbl (%edi),%edx
f0103b3e:	8d 42 dd             	lea    -0x23(%edx),%eax
f0103b41:	3c 55                	cmp    $0x55,%al
f0103b43:	0f 87 12 04 00 00    	ja     f0103f5b <vprintfmt+0x45b>
f0103b49:	0f b6 c0             	movzbl %al,%eax
f0103b4c:	ff 24 85 d8 4f 10 f0 	jmp    *-0xfefb028(,%eax,4)
f0103b53:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f0103b56:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f0103b5a:	eb d9                	jmp    f0103b35 <vprintfmt+0x35>
		switch (ch = *(unsigned char *) fmt++) {
f0103b5c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '0';
f0103b5f:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0103b63:	eb d0                	jmp    f0103b35 <vprintfmt+0x35>
		switch (ch = *(unsigned char *) fmt++) {
f0103b65:	0f b6 d2             	movzbl %dl,%edx
f0103b68:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f0103b6b:	b8 00 00 00 00       	mov    $0x0,%eax
f0103b70:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
				precision = precision * 10 + ch - '0';
f0103b73:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0103b76:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0103b7a:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0103b7d:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0103b80:	83 f9 09             	cmp    $0x9,%ecx
f0103b83:	77 55                	ja     f0103bda <vprintfmt+0xda>
			for (precision = 0; ; ++fmt) {
f0103b85:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f0103b88:	eb e9                	jmp    f0103b73 <vprintfmt+0x73>
			precision = va_arg(ap, int);
f0103b8a:	8b 45 14             	mov    0x14(%ebp),%eax
f0103b8d:	8b 00                	mov    (%eax),%eax
f0103b8f:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103b92:	8b 45 14             	mov    0x14(%ebp),%eax
f0103b95:	8d 40 04             	lea    0x4(%eax),%eax
f0103b98:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0103b9b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f0103b9e:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103ba2:	79 91                	jns    f0103b35 <vprintfmt+0x35>
				width = precision, precision = -1;
f0103ba4:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103ba7:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103baa:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103bb1:	eb 82                	jmp    f0103b35 <vprintfmt+0x35>
f0103bb3:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103bb6:	85 c0                	test   %eax,%eax
f0103bb8:	ba 00 00 00 00       	mov    $0x0,%edx
f0103bbd:	0f 49 d0             	cmovns %eax,%edx
f0103bc0:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0103bc3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103bc6:	e9 6a ff ff ff       	jmp    f0103b35 <vprintfmt+0x35>
f0103bcb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f0103bce:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0103bd5:	e9 5b ff ff ff       	jmp    f0103b35 <vprintfmt+0x35>
f0103bda:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0103bdd:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103be0:	eb bc                	jmp    f0103b9e <vprintfmt+0x9e>
			lflag++;
f0103be2:	83 c1 01             	add    $0x1,%ecx
		switch (ch = *(unsigned char *) fmt++) {
f0103be5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f0103be8:	e9 48 ff ff ff       	jmp    f0103b35 <vprintfmt+0x35>
			putch(va_arg(ap, int), putdat);
f0103bed:	8b 45 14             	mov    0x14(%ebp),%eax
f0103bf0:	8d 78 04             	lea    0x4(%eax),%edi
f0103bf3:	83 ec 08             	sub    $0x8,%esp
f0103bf6:	53                   	push   %ebx
f0103bf7:	ff 30                	pushl  (%eax)
f0103bf9:	ff d6                	call   *%esi
			break;
f0103bfb:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f0103bfe:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f0103c01:	e9 cf 02 00 00       	jmp    f0103ed5 <vprintfmt+0x3d5>
			err = va_arg(ap, int);
f0103c06:	8b 45 14             	mov    0x14(%ebp),%eax
f0103c09:	8d 78 04             	lea    0x4(%eax),%edi
f0103c0c:	8b 00                	mov    (%eax),%eax
f0103c0e:	99                   	cltd   
f0103c0f:	31 d0                	xor    %edx,%eax
f0103c11:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0103c13:	83 f8 06             	cmp    $0x6,%eax
f0103c16:	7f 23                	jg     f0103c3b <vprintfmt+0x13b>
f0103c18:	8b 14 85 30 51 10 f0 	mov    -0xfefaed0(,%eax,4),%edx
f0103c1f:	85 d2                	test   %edx,%edx
f0103c21:	74 18                	je     f0103c3b <vprintfmt+0x13b>
				printfmt(putch, putdat, "%s", p);
f0103c23:	52                   	push   %edx
f0103c24:	68 40 4a 10 f0       	push   $0xf0104a40
f0103c29:	53                   	push   %ebx
f0103c2a:	56                   	push   %esi
f0103c2b:	e8 b3 fe ff ff       	call   f0103ae3 <printfmt>
f0103c30:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0103c33:	89 7d 14             	mov    %edi,0x14(%ebp)
f0103c36:	e9 9a 02 00 00       	jmp    f0103ed5 <vprintfmt+0x3d5>
				printfmt(putch, putdat, "error %d", err);
f0103c3b:	50                   	push   %eax
f0103c3c:	68 64 4f 10 f0       	push   $0xf0104f64
f0103c41:	53                   	push   %ebx
f0103c42:	56                   	push   %esi
f0103c43:	e8 9b fe ff ff       	call   f0103ae3 <printfmt>
f0103c48:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0103c4b:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f0103c4e:	e9 82 02 00 00       	jmp    f0103ed5 <vprintfmt+0x3d5>
			if ((p = va_arg(ap, char *)) == NULL)
f0103c53:	8b 45 14             	mov    0x14(%ebp),%eax
f0103c56:	83 c0 04             	add    $0x4,%eax
f0103c59:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0103c5c:	8b 45 14             	mov    0x14(%ebp),%eax
f0103c5f:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0103c61:	85 ff                	test   %edi,%edi
f0103c63:	b8 5d 4f 10 f0       	mov    $0xf0104f5d,%eax
f0103c68:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0103c6b:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103c6f:	0f 8e bd 00 00 00    	jle    f0103d32 <vprintfmt+0x232>
f0103c75:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0103c79:	75 0e                	jne    f0103c89 <vprintfmt+0x189>
f0103c7b:	89 75 08             	mov    %esi,0x8(%ebp)
f0103c7e:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103c81:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103c84:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103c87:	eb 6d                	jmp    f0103cf6 <vprintfmt+0x1f6>
				for (width -= strnlen(p, precision); width > 0; width--)
f0103c89:	83 ec 08             	sub    $0x8,%esp
f0103c8c:	ff 75 d0             	pushl  -0x30(%ebp)
f0103c8f:	57                   	push   %edi
f0103c90:	e8 50 04 00 00       	call   f01040e5 <strnlen>
f0103c95:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103c98:	29 c1                	sub    %eax,%ecx
f0103c9a:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0103c9d:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0103ca0:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0103ca4:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103ca7:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103caa:	89 cf                	mov    %ecx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f0103cac:	eb 0f                	jmp    f0103cbd <vprintfmt+0x1bd>
					putch(padc, putdat);
f0103cae:	83 ec 08             	sub    $0x8,%esp
f0103cb1:	53                   	push   %ebx
f0103cb2:	ff 75 e0             	pushl  -0x20(%ebp)
f0103cb5:	ff d6                	call   *%esi
				for (width -= strnlen(p, precision); width > 0; width--)
f0103cb7:	83 ef 01             	sub    $0x1,%edi
f0103cba:	83 c4 10             	add    $0x10,%esp
f0103cbd:	85 ff                	test   %edi,%edi
f0103cbf:	7f ed                	jg     f0103cae <vprintfmt+0x1ae>
f0103cc1:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103cc4:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0103cc7:	85 c9                	test   %ecx,%ecx
f0103cc9:	b8 00 00 00 00       	mov    $0x0,%eax
f0103cce:	0f 49 c1             	cmovns %ecx,%eax
f0103cd1:	29 c1                	sub    %eax,%ecx
f0103cd3:	89 75 08             	mov    %esi,0x8(%ebp)
f0103cd6:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103cd9:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103cdc:	89 cb                	mov    %ecx,%ebx
f0103cde:	eb 16                	jmp    f0103cf6 <vprintfmt+0x1f6>
				if (altflag && (ch < ' ' || ch > '~'))
f0103ce0:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0103ce4:	75 31                	jne    f0103d17 <vprintfmt+0x217>
					putch(ch, putdat);
f0103ce6:	83 ec 08             	sub    $0x8,%esp
f0103ce9:	ff 75 0c             	pushl  0xc(%ebp)
f0103cec:	50                   	push   %eax
f0103ced:	ff 55 08             	call   *0x8(%ebp)
f0103cf0:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103cf3:	83 eb 01             	sub    $0x1,%ebx
f0103cf6:	83 c7 01             	add    $0x1,%edi
f0103cf9:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
f0103cfd:	0f be c2             	movsbl %dl,%eax
f0103d00:	85 c0                	test   %eax,%eax
f0103d02:	74 59                	je     f0103d5d <vprintfmt+0x25d>
f0103d04:	85 f6                	test   %esi,%esi
f0103d06:	78 d8                	js     f0103ce0 <vprintfmt+0x1e0>
f0103d08:	83 ee 01             	sub    $0x1,%esi
f0103d0b:	79 d3                	jns    f0103ce0 <vprintfmt+0x1e0>
f0103d0d:	89 df                	mov    %ebx,%edi
f0103d0f:	8b 75 08             	mov    0x8(%ebp),%esi
f0103d12:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103d15:	eb 37                	jmp    f0103d4e <vprintfmt+0x24e>
				if (altflag && (ch < ' ' || ch > '~'))
f0103d17:	0f be d2             	movsbl %dl,%edx
f0103d1a:	83 ea 20             	sub    $0x20,%edx
f0103d1d:	83 fa 5e             	cmp    $0x5e,%edx
f0103d20:	76 c4                	jbe    f0103ce6 <vprintfmt+0x1e6>
					putch('?', putdat);
f0103d22:	83 ec 08             	sub    $0x8,%esp
f0103d25:	ff 75 0c             	pushl  0xc(%ebp)
f0103d28:	6a 3f                	push   $0x3f
f0103d2a:	ff 55 08             	call   *0x8(%ebp)
f0103d2d:	83 c4 10             	add    $0x10,%esp
f0103d30:	eb c1                	jmp    f0103cf3 <vprintfmt+0x1f3>
f0103d32:	89 75 08             	mov    %esi,0x8(%ebp)
f0103d35:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103d38:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103d3b:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103d3e:	eb b6                	jmp    f0103cf6 <vprintfmt+0x1f6>
				putch(' ', putdat);
f0103d40:	83 ec 08             	sub    $0x8,%esp
f0103d43:	53                   	push   %ebx
f0103d44:	6a 20                	push   $0x20
f0103d46:	ff d6                	call   *%esi
			for (; width > 0; width--)
f0103d48:	83 ef 01             	sub    $0x1,%edi
f0103d4b:	83 c4 10             	add    $0x10,%esp
f0103d4e:	85 ff                	test   %edi,%edi
f0103d50:	7f ee                	jg     f0103d40 <vprintfmt+0x240>
			if ((p = va_arg(ap, char *)) == NULL)
f0103d52:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0103d55:	89 45 14             	mov    %eax,0x14(%ebp)
f0103d58:	e9 78 01 00 00       	jmp    f0103ed5 <vprintfmt+0x3d5>
f0103d5d:	89 df                	mov    %ebx,%edi
f0103d5f:	8b 75 08             	mov    0x8(%ebp),%esi
f0103d62:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103d65:	eb e7                	jmp    f0103d4e <vprintfmt+0x24e>
	if (lflag >= 2)
f0103d67:	83 f9 01             	cmp    $0x1,%ecx
f0103d6a:	7e 3f                	jle    f0103dab <vprintfmt+0x2ab>
		return va_arg(*ap, long long);
f0103d6c:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d6f:	8b 50 04             	mov    0x4(%eax),%edx
f0103d72:	8b 00                	mov    (%eax),%eax
f0103d74:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103d77:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103d7a:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d7d:	8d 40 08             	lea    0x8(%eax),%eax
f0103d80:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f0103d83:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103d87:	79 5c                	jns    f0103de5 <vprintfmt+0x2e5>
				putch('-', putdat);
f0103d89:	83 ec 08             	sub    $0x8,%esp
f0103d8c:	53                   	push   %ebx
f0103d8d:	6a 2d                	push   $0x2d
f0103d8f:	ff d6                	call   *%esi
				num = -(long long) num;
f0103d91:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103d94:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0103d97:	f7 da                	neg    %edx
f0103d99:	83 d1 00             	adc    $0x0,%ecx
f0103d9c:	f7 d9                	neg    %ecx
f0103d9e:	83 c4 10             	add    $0x10,%esp
			base = 10;
f0103da1:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103da6:	e9 10 01 00 00       	jmp    f0103ebb <vprintfmt+0x3bb>
	else if (lflag)
f0103dab:	85 c9                	test   %ecx,%ecx
f0103dad:	75 1b                	jne    f0103dca <vprintfmt+0x2ca>
		return va_arg(*ap, int);
f0103daf:	8b 45 14             	mov    0x14(%ebp),%eax
f0103db2:	8b 00                	mov    (%eax),%eax
f0103db4:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103db7:	89 c1                	mov    %eax,%ecx
f0103db9:	c1 f9 1f             	sar    $0x1f,%ecx
f0103dbc:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0103dbf:	8b 45 14             	mov    0x14(%ebp),%eax
f0103dc2:	8d 40 04             	lea    0x4(%eax),%eax
f0103dc5:	89 45 14             	mov    %eax,0x14(%ebp)
f0103dc8:	eb b9                	jmp    f0103d83 <vprintfmt+0x283>
		return va_arg(*ap, long);
f0103dca:	8b 45 14             	mov    0x14(%ebp),%eax
f0103dcd:	8b 00                	mov    (%eax),%eax
f0103dcf:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103dd2:	89 c1                	mov    %eax,%ecx
f0103dd4:	c1 f9 1f             	sar    $0x1f,%ecx
f0103dd7:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0103dda:	8b 45 14             	mov    0x14(%ebp),%eax
f0103ddd:	8d 40 04             	lea    0x4(%eax),%eax
f0103de0:	89 45 14             	mov    %eax,0x14(%ebp)
f0103de3:	eb 9e                	jmp    f0103d83 <vprintfmt+0x283>
			num = getint(&ap, lflag);
f0103de5:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103de8:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f0103deb:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103df0:	e9 c6 00 00 00       	jmp    f0103ebb <vprintfmt+0x3bb>
	if (lflag >= 2)
f0103df5:	83 f9 01             	cmp    $0x1,%ecx
f0103df8:	7e 18                	jle    f0103e12 <vprintfmt+0x312>
		return va_arg(*ap, unsigned long long);
f0103dfa:	8b 45 14             	mov    0x14(%ebp),%eax
f0103dfd:	8b 10                	mov    (%eax),%edx
f0103dff:	8b 48 04             	mov    0x4(%eax),%ecx
f0103e02:	8d 40 08             	lea    0x8(%eax),%eax
f0103e05:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0103e08:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103e0d:	e9 a9 00 00 00       	jmp    f0103ebb <vprintfmt+0x3bb>
	else if (lflag)
f0103e12:	85 c9                	test   %ecx,%ecx
f0103e14:	75 1a                	jne    f0103e30 <vprintfmt+0x330>
		return va_arg(*ap, unsigned int);
f0103e16:	8b 45 14             	mov    0x14(%ebp),%eax
f0103e19:	8b 10                	mov    (%eax),%edx
f0103e1b:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103e20:	8d 40 04             	lea    0x4(%eax),%eax
f0103e23:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0103e26:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103e2b:	e9 8b 00 00 00       	jmp    f0103ebb <vprintfmt+0x3bb>
		return va_arg(*ap, unsigned long);
f0103e30:	8b 45 14             	mov    0x14(%ebp),%eax
f0103e33:	8b 10                	mov    (%eax),%edx
f0103e35:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103e3a:	8d 40 04             	lea    0x4(%eax),%eax
f0103e3d:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0103e40:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103e45:	eb 74                	jmp    f0103ebb <vprintfmt+0x3bb>
	if (lflag >= 2)
f0103e47:	83 f9 01             	cmp    $0x1,%ecx
f0103e4a:	7e 15                	jle    f0103e61 <vprintfmt+0x361>
		return va_arg(*ap, unsigned long long);
f0103e4c:	8b 45 14             	mov    0x14(%ebp),%eax
f0103e4f:	8b 10                	mov    (%eax),%edx
f0103e51:	8b 48 04             	mov    0x4(%eax),%ecx
f0103e54:	8d 40 08             	lea    0x8(%eax),%eax
f0103e57:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0103e5a:	b8 08 00 00 00       	mov    $0x8,%eax
f0103e5f:	eb 5a                	jmp    f0103ebb <vprintfmt+0x3bb>
	else if (lflag)
f0103e61:	85 c9                	test   %ecx,%ecx
f0103e63:	75 17                	jne    f0103e7c <vprintfmt+0x37c>
		return va_arg(*ap, unsigned int);
f0103e65:	8b 45 14             	mov    0x14(%ebp),%eax
f0103e68:	8b 10                	mov    (%eax),%edx
f0103e6a:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103e6f:	8d 40 04             	lea    0x4(%eax),%eax
f0103e72:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0103e75:	b8 08 00 00 00       	mov    $0x8,%eax
f0103e7a:	eb 3f                	jmp    f0103ebb <vprintfmt+0x3bb>
		return va_arg(*ap, unsigned long);
f0103e7c:	8b 45 14             	mov    0x14(%ebp),%eax
f0103e7f:	8b 10                	mov    (%eax),%edx
f0103e81:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103e86:	8d 40 04             	lea    0x4(%eax),%eax
f0103e89:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0103e8c:	b8 08 00 00 00       	mov    $0x8,%eax
f0103e91:	eb 28                	jmp    f0103ebb <vprintfmt+0x3bb>
			putch('0', putdat);
f0103e93:	83 ec 08             	sub    $0x8,%esp
f0103e96:	53                   	push   %ebx
f0103e97:	6a 30                	push   $0x30
f0103e99:	ff d6                	call   *%esi
			putch('x', putdat);
f0103e9b:	83 c4 08             	add    $0x8,%esp
f0103e9e:	53                   	push   %ebx
f0103e9f:	6a 78                	push   $0x78
f0103ea1:	ff d6                	call   *%esi
			num = (unsigned long long)
f0103ea3:	8b 45 14             	mov    0x14(%ebp),%eax
f0103ea6:	8b 10                	mov    (%eax),%edx
f0103ea8:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f0103ead:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f0103eb0:	8d 40 04             	lea    0x4(%eax),%eax
f0103eb3:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0103eb6:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f0103ebb:	83 ec 0c             	sub    $0xc,%esp
f0103ebe:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0103ec2:	57                   	push   %edi
f0103ec3:	ff 75 e0             	pushl  -0x20(%ebp)
f0103ec6:	50                   	push   %eax
f0103ec7:	51                   	push   %ecx
f0103ec8:	52                   	push   %edx
f0103ec9:	89 da                	mov    %ebx,%edx
f0103ecb:	89 f0                	mov    %esi,%eax
f0103ecd:	e8 45 fb ff ff       	call   f0103a17 <printnum>
			break;
f0103ed2:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f0103ed5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103ed8:	83 c7 01             	add    $0x1,%edi
f0103edb:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103edf:	83 f8 25             	cmp    $0x25,%eax
f0103ee2:	0f 84 2f fc ff ff    	je     f0103b17 <vprintfmt+0x17>
			if (ch == '\0')
f0103ee8:	85 c0                	test   %eax,%eax
f0103eea:	0f 84 8b 00 00 00    	je     f0103f7b <vprintfmt+0x47b>
			putch(ch, putdat);
f0103ef0:	83 ec 08             	sub    $0x8,%esp
f0103ef3:	53                   	push   %ebx
f0103ef4:	50                   	push   %eax
f0103ef5:	ff d6                	call   *%esi
f0103ef7:	83 c4 10             	add    $0x10,%esp
f0103efa:	eb dc                	jmp    f0103ed8 <vprintfmt+0x3d8>
	if (lflag >= 2)
f0103efc:	83 f9 01             	cmp    $0x1,%ecx
f0103eff:	7e 15                	jle    f0103f16 <vprintfmt+0x416>
		return va_arg(*ap, unsigned long long);
f0103f01:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f04:	8b 10                	mov    (%eax),%edx
f0103f06:	8b 48 04             	mov    0x4(%eax),%ecx
f0103f09:	8d 40 08             	lea    0x8(%eax),%eax
f0103f0c:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0103f0f:	b8 10 00 00 00       	mov    $0x10,%eax
f0103f14:	eb a5                	jmp    f0103ebb <vprintfmt+0x3bb>
	else if (lflag)
f0103f16:	85 c9                	test   %ecx,%ecx
f0103f18:	75 17                	jne    f0103f31 <vprintfmt+0x431>
		return va_arg(*ap, unsigned int);
f0103f1a:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f1d:	8b 10                	mov    (%eax),%edx
f0103f1f:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103f24:	8d 40 04             	lea    0x4(%eax),%eax
f0103f27:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0103f2a:	b8 10 00 00 00       	mov    $0x10,%eax
f0103f2f:	eb 8a                	jmp    f0103ebb <vprintfmt+0x3bb>
		return va_arg(*ap, unsigned long);
f0103f31:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f34:	8b 10                	mov    (%eax),%edx
f0103f36:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103f3b:	8d 40 04             	lea    0x4(%eax),%eax
f0103f3e:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0103f41:	b8 10 00 00 00       	mov    $0x10,%eax
f0103f46:	e9 70 ff ff ff       	jmp    f0103ebb <vprintfmt+0x3bb>
			putch(ch, putdat);
f0103f4b:	83 ec 08             	sub    $0x8,%esp
f0103f4e:	53                   	push   %ebx
f0103f4f:	6a 25                	push   $0x25
f0103f51:	ff d6                	call   *%esi
			break;
f0103f53:	83 c4 10             	add    $0x10,%esp
f0103f56:	e9 7a ff ff ff       	jmp    f0103ed5 <vprintfmt+0x3d5>
			putch('%', putdat);
f0103f5b:	83 ec 08             	sub    $0x8,%esp
f0103f5e:	53                   	push   %ebx
f0103f5f:	6a 25                	push   $0x25
f0103f61:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103f63:	83 c4 10             	add    $0x10,%esp
f0103f66:	89 f8                	mov    %edi,%eax
f0103f68:	eb 03                	jmp    f0103f6d <vprintfmt+0x46d>
f0103f6a:	83 e8 01             	sub    $0x1,%eax
f0103f6d:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f0103f71:	75 f7                	jne    f0103f6a <vprintfmt+0x46a>
f0103f73:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103f76:	e9 5a ff ff ff       	jmp    f0103ed5 <vprintfmt+0x3d5>
}
f0103f7b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103f7e:	5b                   	pop    %ebx
f0103f7f:	5e                   	pop    %esi
f0103f80:	5f                   	pop    %edi
f0103f81:	5d                   	pop    %ebp
f0103f82:	c3                   	ret    

f0103f83 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103f83:	55                   	push   %ebp
f0103f84:	89 e5                	mov    %esp,%ebp
f0103f86:	83 ec 18             	sub    $0x18,%esp
f0103f89:	8b 45 08             	mov    0x8(%ebp),%eax
f0103f8c:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0103f8f:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103f92:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103f96:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103f99:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0103fa0:	85 c0                	test   %eax,%eax
f0103fa2:	74 26                	je     f0103fca <vsnprintf+0x47>
f0103fa4:	85 d2                	test   %edx,%edx
f0103fa6:	7e 22                	jle    f0103fca <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0103fa8:	ff 75 14             	pushl  0x14(%ebp)
f0103fab:	ff 75 10             	pushl  0x10(%ebp)
f0103fae:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103fb1:	50                   	push   %eax
f0103fb2:	68 c6 3a 10 f0       	push   $0xf0103ac6
f0103fb7:	e8 44 fb ff ff       	call   f0103b00 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103fbc:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103fbf:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0103fc2:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103fc5:	83 c4 10             	add    $0x10,%esp
}
f0103fc8:	c9                   	leave  
f0103fc9:	c3                   	ret    
		return -E_INVAL;
f0103fca:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0103fcf:	eb f7                	jmp    f0103fc8 <vsnprintf+0x45>

f0103fd1 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0103fd1:	55                   	push   %ebp
f0103fd2:	89 e5                	mov    %esp,%ebp
f0103fd4:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0103fd7:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103fda:	50                   	push   %eax
f0103fdb:	ff 75 10             	pushl  0x10(%ebp)
f0103fde:	ff 75 0c             	pushl  0xc(%ebp)
f0103fe1:	ff 75 08             	pushl  0x8(%ebp)
f0103fe4:	e8 9a ff ff ff       	call   f0103f83 <vsnprintf>
	va_end(ap);

	return rc;
}
f0103fe9:	c9                   	leave  
f0103fea:	c3                   	ret    

f0103feb <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103feb:	55                   	push   %ebp
f0103fec:	89 e5                	mov    %esp,%ebp
f0103fee:	57                   	push   %edi
f0103fef:	56                   	push   %esi
f0103ff0:	53                   	push   %ebx
f0103ff1:	83 ec 0c             	sub    $0xc,%esp
f0103ff4:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0103ff7:	85 c0                	test   %eax,%eax
f0103ff9:	74 11                	je     f010400c <readline+0x21>
		cprintf("%s", prompt);
f0103ffb:	83 ec 08             	sub    $0x8,%esp
f0103ffe:	50                   	push   %eax
f0103fff:	68 40 4a 10 f0       	push   $0xf0104a40
f0104004:	e8 79 c7 ff ff       	call   f0100782 <cprintf>
f0104009:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f010400c:	83 ec 0c             	sub    $0xc,%esp
f010400f:	6a 00                	push   $0x0
f0104011:	e8 29 c7 ff ff       	call   f010073f <iscons>
f0104016:	89 c7                	mov    %eax,%edi
f0104018:	83 c4 10             	add    $0x10,%esp
	i = 0;
f010401b:	be 00 00 00 00       	mov    $0x0,%esi
f0104020:	eb 3f                	jmp    f0104061 <readline+0x76>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f0104022:	83 ec 08             	sub    $0x8,%esp
f0104025:	50                   	push   %eax
f0104026:	68 4c 51 10 f0       	push   $0xf010514c
f010402b:	e8 52 c7 ff ff       	call   f0100782 <cprintf>
			return NULL;
f0104030:	83 c4 10             	add    $0x10,%esp
f0104033:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f0104038:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010403b:	5b                   	pop    %ebx
f010403c:	5e                   	pop    %esi
f010403d:	5f                   	pop    %edi
f010403e:	5d                   	pop    %ebp
f010403f:	c3                   	ret    
			if (echoing)
f0104040:	85 ff                	test   %edi,%edi
f0104042:	75 05                	jne    f0104049 <readline+0x5e>
			i--;
f0104044:	83 ee 01             	sub    $0x1,%esi
f0104047:	eb 18                	jmp    f0104061 <readline+0x76>
				cputchar('\b');
f0104049:	83 ec 0c             	sub    $0xc,%esp
f010404c:	6a 08                	push   $0x8
f010404e:	e8 cb c6 ff ff       	call   f010071e <cputchar>
f0104053:	83 c4 10             	add    $0x10,%esp
f0104056:	eb ec                	jmp    f0104044 <readline+0x59>
			buf[i++] = c;
f0104058:	88 9e 40 62 12 f0    	mov    %bl,-0xfed9dc0(%esi)
f010405e:	8d 76 01             	lea    0x1(%esi),%esi
		c = getchar();
f0104061:	e8 c8 c6 ff ff       	call   f010072e <getchar>
f0104066:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0104068:	85 c0                	test   %eax,%eax
f010406a:	78 b6                	js     f0104022 <readline+0x37>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f010406c:	83 f8 08             	cmp    $0x8,%eax
f010406f:	0f 94 c2             	sete   %dl
f0104072:	83 f8 7f             	cmp    $0x7f,%eax
f0104075:	0f 94 c0             	sete   %al
f0104078:	08 c2                	or     %al,%dl
f010407a:	74 04                	je     f0104080 <readline+0x95>
f010407c:	85 f6                	test   %esi,%esi
f010407e:	7f c0                	jg     f0104040 <readline+0x55>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0104080:	83 fb 1f             	cmp    $0x1f,%ebx
f0104083:	7e 1a                	jle    f010409f <readline+0xb4>
f0104085:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010408b:	7f 12                	jg     f010409f <readline+0xb4>
			if (echoing)
f010408d:	85 ff                	test   %edi,%edi
f010408f:	74 c7                	je     f0104058 <readline+0x6d>
				cputchar(c);
f0104091:	83 ec 0c             	sub    $0xc,%esp
f0104094:	53                   	push   %ebx
f0104095:	e8 84 c6 ff ff       	call   f010071e <cputchar>
f010409a:	83 c4 10             	add    $0x10,%esp
f010409d:	eb b9                	jmp    f0104058 <readline+0x6d>
		} else if (c == '\n' || c == '\r') {
f010409f:	83 fb 0a             	cmp    $0xa,%ebx
f01040a2:	74 05                	je     f01040a9 <readline+0xbe>
f01040a4:	83 fb 0d             	cmp    $0xd,%ebx
f01040a7:	75 b8                	jne    f0104061 <readline+0x76>
			if (echoing)
f01040a9:	85 ff                	test   %edi,%edi
f01040ab:	75 11                	jne    f01040be <readline+0xd3>
			buf[i] = 0;
f01040ad:	c6 86 40 62 12 f0 00 	movb   $0x0,-0xfed9dc0(%esi)
			return buf;
f01040b4:	b8 40 62 12 f0       	mov    $0xf0126240,%eax
f01040b9:	e9 7a ff ff ff       	jmp    f0104038 <readline+0x4d>
				cputchar('\n');
f01040be:	83 ec 0c             	sub    $0xc,%esp
f01040c1:	6a 0a                	push   $0xa
f01040c3:	e8 56 c6 ff ff       	call   f010071e <cputchar>
f01040c8:	83 c4 10             	add    $0x10,%esp
f01040cb:	eb e0                	jmp    f01040ad <readline+0xc2>

f01040cd <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01040cd:	55                   	push   %ebp
f01040ce:	89 e5                	mov    %esp,%ebp
f01040d0:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01040d3:	b8 00 00 00 00       	mov    $0x0,%eax
f01040d8:	eb 03                	jmp    f01040dd <strlen+0x10>
		n++;
f01040da:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f01040dd:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01040e1:	75 f7                	jne    f01040da <strlen+0xd>
	return n;
}
f01040e3:	5d                   	pop    %ebp
f01040e4:	c3                   	ret    

f01040e5 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01040e5:	55                   	push   %ebp
f01040e6:	89 e5                	mov    %esp,%ebp
f01040e8:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01040eb:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01040ee:	b8 00 00 00 00       	mov    $0x0,%eax
f01040f3:	eb 03                	jmp    f01040f8 <strnlen+0x13>
		n++;
f01040f5:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01040f8:	39 d0                	cmp    %edx,%eax
f01040fa:	74 06                	je     f0104102 <strnlen+0x1d>
f01040fc:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0104100:	75 f3                	jne    f01040f5 <strnlen+0x10>
	return n;
}
f0104102:	5d                   	pop    %ebp
f0104103:	c3                   	ret    

f0104104 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0104104:	55                   	push   %ebp
f0104105:	89 e5                	mov    %esp,%ebp
f0104107:	53                   	push   %ebx
f0104108:	8b 45 08             	mov    0x8(%ebp),%eax
f010410b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f010410e:	89 c2                	mov    %eax,%edx
f0104110:	83 c1 01             	add    $0x1,%ecx
f0104113:	83 c2 01             	add    $0x1,%edx
f0104116:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010411a:	88 5a ff             	mov    %bl,-0x1(%edx)
f010411d:	84 db                	test   %bl,%bl
f010411f:	75 ef                	jne    f0104110 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0104121:	5b                   	pop    %ebx
f0104122:	5d                   	pop    %ebp
f0104123:	c3                   	ret    

f0104124 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0104124:	55                   	push   %ebp
f0104125:	89 e5                	mov    %esp,%ebp
f0104127:	53                   	push   %ebx
f0104128:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f010412b:	53                   	push   %ebx
f010412c:	e8 9c ff ff ff       	call   f01040cd <strlen>
f0104131:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0104134:	ff 75 0c             	pushl  0xc(%ebp)
f0104137:	01 d8                	add    %ebx,%eax
f0104139:	50                   	push   %eax
f010413a:	e8 c5 ff ff ff       	call   f0104104 <strcpy>
	return dst;
}
f010413f:	89 d8                	mov    %ebx,%eax
f0104141:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0104144:	c9                   	leave  
f0104145:	c3                   	ret    

f0104146 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0104146:	55                   	push   %ebp
f0104147:	89 e5                	mov    %esp,%ebp
f0104149:	56                   	push   %esi
f010414a:	53                   	push   %ebx
f010414b:	8b 75 08             	mov    0x8(%ebp),%esi
f010414e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104151:	89 f3                	mov    %esi,%ebx
f0104153:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104156:	89 f2                	mov    %esi,%edx
f0104158:	eb 0f                	jmp    f0104169 <strncpy+0x23>
		*dst++ = *src;
f010415a:	83 c2 01             	add    $0x1,%edx
f010415d:	0f b6 01             	movzbl (%ecx),%eax
f0104160:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0104163:	80 39 01             	cmpb   $0x1,(%ecx)
f0104166:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f0104169:	39 da                	cmp    %ebx,%edx
f010416b:	75 ed                	jne    f010415a <strncpy+0x14>
	}
	return ret;
}
f010416d:	89 f0                	mov    %esi,%eax
f010416f:	5b                   	pop    %ebx
f0104170:	5e                   	pop    %esi
f0104171:	5d                   	pop    %ebp
f0104172:	c3                   	ret    

f0104173 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0104173:	55                   	push   %ebp
f0104174:	89 e5                	mov    %esp,%ebp
f0104176:	56                   	push   %esi
f0104177:	53                   	push   %ebx
f0104178:	8b 75 08             	mov    0x8(%ebp),%esi
f010417b:	8b 55 0c             	mov    0xc(%ebp),%edx
f010417e:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0104181:	89 f0                	mov    %esi,%eax
f0104183:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0104187:	85 c9                	test   %ecx,%ecx
f0104189:	75 0b                	jne    f0104196 <strlcpy+0x23>
f010418b:	eb 17                	jmp    f01041a4 <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010418d:	83 c2 01             	add    $0x1,%edx
f0104190:	83 c0 01             	add    $0x1,%eax
f0104193:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f0104196:	39 d8                	cmp    %ebx,%eax
f0104198:	74 07                	je     f01041a1 <strlcpy+0x2e>
f010419a:	0f b6 0a             	movzbl (%edx),%ecx
f010419d:	84 c9                	test   %cl,%cl
f010419f:	75 ec                	jne    f010418d <strlcpy+0x1a>
		*dst = '\0';
f01041a1:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01041a4:	29 f0                	sub    %esi,%eax
}
f01041a6:	5b                   	pop    %ebx
f01041a7:	5e                   	pop    %esi
f01041a8:	5d                   	pop    %ebp
f01041a9:	c3                   	ret    

f01041aa <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01041aa:	55                   	push   %ebp
f01041ab:	89 e5                	mov    %esp,%ebp
f01041ad:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01041b0:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01041b3:	eb 06                	jmp    f01041bb <strcmp+0x11>
		p++, q++;
f01041b5:	83 c1 01             	add    $0x1,%ecx
f01041b8:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f01041bb:	0f b6 01             	movzbl (%ecx),%eax
f01041be:	84 c0                	test   %al,%al
f01041c0:	74 04                	je     f01041c6 <strcmp+0x1c>
f01041c2:	3a 02                	cmp    (%edx),%al
f01041c4:	74 ef                	je     f01041b5 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01041c6:	0f b6 c0             	movzbl %al,%eax
f01041c9:	0f b6 12             	movzbl (%edx),%edx
f01041cc:	29 d0                	sub    %edx,%eax
}
f01041ce:	5d                   	pop    %ebp
f01041cf:	c3                   	ret    

f01041d0 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01041d0:	55                   	push   %ebp
f01041d1:	89 e5                	mov    %esp,%ebp
f01041d3:	53                   	push   %ebx
f01041d4:	8b 45 08             	mov    0x8(%ebp),%eax
f01041d7:	8b 55 0c             	mov    0xc(%ebp),%edx
f01041da:	89 c3                	mov    %eax,%ebx
f01041dc:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01041df:	eb 06                	jmp    f01041e7 <strncmp+0x17>
		n--, p++, q++;
f01041e1:	83 c0 01             	add    $0x1,%eax
f01041e4:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f01041e7:	39 d8                	cmp    %ebx,%eax
f01041e9:	74 16                	je     f0104201 <strncmp+0x31>
f01041eb:	0f b6 08             	movzbl (%eax),%ecx
f01041ee:	84 c9                	test   %cl,%cl
f01041f0:	74 04                	je     f01041f6 <strncmp+0x26>
f01041f2:	3a 0a                	cmp    (%edx),%cl
f01041f4:	74 eb                	je     f01041e1 <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01041f6:	0f b6 00             	movzbl (%eax),%eax
f01041f9:	0f b6 12             	movzbl (%edx),%edx
f01041fc:	29 d0                	sub    %edx,%eax
}
f01041fe:	5b                   	pop    %ebx
f01041ff:	5d                   	pop    %ebp
f0104200:	c3                   	ret    
		return 0;
f0104201:	b8 00 00 00 00       	mov    $0x0,%eax
f0104206:	eb f6                	jmp    f01041fe <strncmp+0x2e>

f0104208 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0104208:	55                   	push   %ebp
f0104209:	89 e5                	mov    %esp,%ebp
f010420b:	8b 45 08             	mov    0x8(%ebp),%eax
f010420e:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104212:	0f b6 10             	movzbl (%eax),%edx
f0104215:	84 d2                	test   %dl,%dl
f0104217:	74 09                	je     f0104222 <strchr+0x1a>
		if (*s == c)
f0104219:	38 ca                	cmp    %cl,%dl
f010421b:	74 0a                	je     f0104227 <strchr+0x1f>
	for (; *s; s++)
f010421d:	83 c0 01             	add    $0x1,%eax
f0104220:	eb f0                	jmp    f0104212 <strchr+0xa>
			return (char *) s;
	return 0;
f0104222:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104227:	5d                   	pop    %ebp
f0104228:	c3                   	ret    

f0104229 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0104229:	55                   	push   %ebp
f010422a:	89 e5                	mov    %esp,%ebp
f010422c:	8b 45 08             	mov    0x8(%ebp),%eax
f010422f:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104233:	eb 03                	jmp    f0104238 <strfind+0xf>
f0104235:	83 c0 01             	add    $0x1,%eax
f0104238:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f010423b:	38 ca                	cmp    %cl,%dl
f010423d:	74 04                	je     f0104243 <strfind+0x1a>
f010423f:	84 d2                	test   %dl,%dl
f0104241:	75 f2                	jne    f0104235 <strfind+0xc>
			break;
	return (char *) s;
}
f0104243:	5d                   	pop    %ebp
f0104244:	c3                   	ret    

f0104245 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0104245:	55                   	push   %ebp
f0104246:	89 e5                	mov    %esp,%ebp
f0104248:	57                   	push   %edi
f0104249:	56                   	push   %esi
f010424a:	53                   	push   %ebx
f010424b:	8b 7d 08             	mov    0x8(%ebp),%edi
f010424e:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0104251:	85 c9                	test   %ecx,%ecx
f0104253:	74 13                	je     f0104268 <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0104255:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010425b:	75 05                	jne    f0104262 <memset+0x1d>
f010425d:	f6 c1 03             	test   $0x3,%cl
f0104260:	74 0d                	je     f010426f <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0104262:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104265:	fc                   	cld    
f0104266:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0104268:	89 f8                	mov    %edi,%eax
f010426a:	5b                   	pop    %ebx
f010426b:	5e                   	pop    %esi
f010426c:	5f                   	pop    %edi
f010426d:	5d                   	pop    %ebp
f010426e:	c3                   	ret    
		c &= 0xFF;
f010426f:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0104273:	89 d3                	mov    %edx,%ebx
f0104275:	c1 e3 08             	shl    $0x8,%ebx
f0104278:	89 d0                	mov    %edx,%eax
f010427a:	c1 e0 18             	shl    $0x18,%eax
f010427d:	89 d6                	mov    %edx,%esi
f010427f:	c1 e6 10             	shl    $0x10,%esi
f0104282:	09 f0                	or     %esi,%eax
f0104284:	09 c2                	or     %eax,%edx
f0104286:	09 da                	or     %ebx,%edx
			:: "D" (v), "a" (c), "c" (n/4)
f0104288:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f010428b:	89 d0                	mov    %edx,%eax
f010428d:	fc                   	cld    
f010428e:	f3 ab                	rep stos %eax,%es:(%edi)
f0104290:	eb d6                	jmp    f0104268 <memset+0x23>

f0104292 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0104292:	55                   	push   %ebp
f0104293:	89 e5                	mov    %esp,%ebp
f0104295:	57                   	push   %edi
f0104296:	56                   	push   %esi
f0104297:	8b 45 08             	mov    0x8(%ebp),%eax
f010429a:	8b 75 0c             	mov    0xc(%ebp),%esi
f010429d:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01042a0:	39 c6                	cmp    %eax,%esi
f01042a2:	73 35                	jae    f01042d9 <memmove+0x47>
f01042a4:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01042a7:	39 c2                	cmp    %eax,%edx
f01042a9:	76 2e                	jbe    f01042d9 <memmove+0x47>
		s += n;
		d += n;
f01042ab:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01042ae:	89 d6                	mov    %edx,%esi
f01042b0:	09 fe                	or     %edi,%esi
f01042b2:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01042b8:	74 0c                	je     f01042c6 <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01042ba:	83 ef 01             	sub    $0x1,%edi
f01042bd:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f01042c0:	fd                   	std    
f01042c1:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01042c3:	fc                   	cld    
f01042c4:	eb 21                	jmp    f01042e7 <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01042c6:	f6 c1 03             	test   $0x3,%cl
f01042c9:	75 ef                	jne    f01042ba <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01042cb:	83 ef 04             	sub    $0x4,%edi
f01042ce:	8d 72 fc             	lea    -0x4(%edx),%esi
f01042d1:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f01042d4:	fd                   	std    
f01042d5:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01042d7:	eb ea                	jmp    f01042c3 <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01042d9:	89 f2                	mov    %esi,%edx
f01042db:	09 c2                	or     %eax,%edx
f01042dd:	f6 c2 03             	test   $0x3,%dl
f01042e0:	74 09                	je     f01042eb <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01042e2:	89 c7                	mov    %eax,%edi
f01042e4:	fc                   	cld    
f01042e5:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01042e7:	5e                   	pop    %esi
f01042e8:	5f                   	pop    %edi
f01042e9:	5d                   	pop    %ebp
f01042ea:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01042eb:	f6 c1 03             	test   $0x3,%cl
f01042ee:	75 f2                	jne    f01042e2 <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01042f0:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f01042f3:	89 c7                	mov    %eax,%edi
f01042f5:	fc                   	cld    
f01042f6:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01042f8:	eb ed                	jmp    f01042e7 <memmove+0x55>

f01042fa <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01042fa:	55                   	push   %ebp
f01042fb:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01042fd:	ff 75 10             	pushl  0x10(%ebp)
f0104300:	ff 75 0c             	pushl  0xc(%ebp)
f0104303:	ff 75 08             	pushl  0x8(%ebp)
f0104306:	e8 87 ff ff ff       	call   f0104292 <memmove>
}
f010430b:	c9                   	leave  
f010430c:	c3                   	ret    

f010430d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010430d:	55                   	push   %ebp
f010430e:	89 e5                	mov    %esp,%ebp
f0104310:	56                   	push   %esi
f0104311:	53                   	push   %ebx
f0104312:	8b 45 08             	mov    0x8(%ebp),%eax
f0104315:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104318:	89 c6                	mov    %eax,%esi
f010431a:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010431d:	39 f0                	cmp    %esi,%eax
f010431f:	74 1c                	je     f010433d <memcmp+0x30>
		if (*s1 != *s2)
f0104321:	0f b6 08             	movzbl (%eax),%ecx
f0104324:	0f b6 1a             	movzbl (%edx),%ebx
f0104327:	38 d9                	cmp    %bl,%cl
f0104329:	75 08                	jne    f0104333 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f010432b:	83 c0 01             	add    $0x1,%eax
f010432e:	83 c2 01             	add    $0x1,%edx
f0104331:	eb ea                	jmp    f010431d <memcmp+0x10>
			return (int) *s1 - (int) *s2;
f0104333:	0f b6 c1             	movzbl %cl,%eax
f0104336:	0f b6 db             	movzbl %bl,%ebx
f0104339:	29 d8                	sub    %ebx,%eax
f010433b:	eb 05                	jmp    f0104342 <memcmp+0x35>
	}

	return 0;
f010433d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104342:	5b                   	pop    %ebx
f0104343:	5e                   	pop    %esi
f0104344:	5d                   	pop    %ebp
f0104345:	c3                   	ret    

f0104346 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0104346:	55                   	push   %ebp
f0104347:	89 e5                	mov    %esp,%ebp
f0104349:	8b 45 08             	mov    0x8(%ebp),%eax
f010434c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f010434f:	89 c2                	mov    %eax,%edx
f0104351:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0104354:	39 d0                	cmp    %edx,%eax
f0104356:	73 09                	jae    f0104361 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f0104358:	38 08                	cmp    %cl,(%eax)
f010435a:	74 05                	je     f0104361 <memfind+0x1b>
	for (; s < ends; s++)
f010435c:	83 c0 01             	add    $0x1,%eax
f010435f:	eb f3                	jmp    f0104354 <memfind+0xe>
			break;
	return (void *) s;
}
f0104361:	5d                   	pop    %ebp
f0104362:	c3                   	ret    

f0104363 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0104363:	55                   	push   %ebp
f0104364:	89 e5                	mov    %esp,%ebp
f0104366:	57                   	push   %edi
f0104367:	56                   	push   %esi
f0104368:	53                   	push   %ebx
f0104369:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010436c:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010436f:	eb 03                	jmp    f0104374 <strtol+0x11>
		s++;
f0104371:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f0104374:	0f b6 01             	movzbl (%ecx),%eax
f0104377:	3c 20                	cmp    $0x20,%al
f0104379:	74 f6                	je     f0104371 <strtol+0xe>
f010437b:	3c 09                	cmp    $0x9,%al
f010437d:	74 f2                	je     f0104371 <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f010437f:	3c 2b                	cmp    $0x2b,%al
f0104381:	74 2e                	je     f01043b1 <strtol+0x4e>
	int neg = 0;
f0104383:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f0104388:	3c 2d                	cmp    $0x2d,%al
f010438a:	74 2f                	je     f01043bb <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010438c:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0104392:	75 05                	jne    f0104399 <strtol+0x36>
f0104394:	80 39 30             	cmpb   $0x30,(%ecx)
f0104397:	74 2c                	je     f01043c5 <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104399:	85 db                	test   %ebx,%ebx
f010439b:	75 0a                	jne    f01043a7 <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010439d:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
f01043a2:	80 39 30             	cmpb   $0x30,(%ecx)
f01043a5:	74 28                	je     f01043cf <strtol+0x6c>
		base = 10;
f01043a7:	b8 00 00 00 00       	mov    $0x0,%eax
f01043ac:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01043af:	eb 50                	jmp    f0104401 <strtol+0x9e>
		s++;
f01043b1:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f01043b4:	bf 00 00 00 00       	mov    $0x0,%edi
f01043b9:	eb d1                	jmp    f010438c <strtol+0x29>
		s++, neg = 1;
f01043bb:	83 c1 01             	add    $0x1,%ecx
f01043be:	bf 01 00 00 00       	mov    $0x1,%edi
f01043c3:	eb c7                	jmp    f010438c <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01043c5:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01043c9:	74 0e                	je     f01043d9 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f01043cb:	85 db                	test   %ebx,%ebx
f01043cd:	75 d8                	jne    f01043a7 <strtol+0x44>
		s++, base = 8;
f01043cf:	83 c1 01             	add    $0x1,%ecx
f01043d2:	bb 08 00 00 00       	mov    $0x8,%ebx
f01043d7:	eb ce                	jmp    f01043a7 <strtol+0x44>
		s += 2, base = 16;
f01043d9:	83 c1 02             	add    $0x2,%ecx
f01043dc:	bb 10 00 00 00       	mov    $0x10,%ebx
f01043e1:	eb c4                	jmp    f01043a7 <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f01043e3:	8d 72 9f             	lea    -0x61(%edx),%esi
f01043e6:	89 f3                	mov    %esi,%ebx
f01043e8:	80 fb 19             	cmp    $0x19,%bl
f01043eb:	77 29                	ja     f0104416 <strtol+0xb3>
			dig = *s - 'a' + 10;
f01043ed:	0f be d2             	movsbl %dl,%edx
f01043f0:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f01043f3:	3b 55 10             	cmp    0x10(%ebp),%edx
f01043f6:	7d 30                	jge    f0104428 <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f01043f8:	83 c1 01             	add    $0x1,%ecx
f01043fb:	0f af 45 10          	imul   0x10(%ebp),%eax
f01043ff:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f0104401:	0f b6 11             	movzbl (%ecx),%edx
f0104404:	8d 72 d0             	lea    -0x30(%edx),%esi
f0104407:	89 f3                	mov    %esi,%ebx
f0104409:	80 fb 09             	cmp    $0x9,%bl
f010440c:	77 d5                	ja     f01043e3 <strtol+0x80>
			dig = *s - '0';
f010440e:	0f be d2             	movsbl %dl,%edx
f0104411:	83 ea 30             	sub    $0x30,%edx
f0104414:	eb dd                	jmp    f01043f3 <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
f0104416:	8d 72 bf             	lea    -0x41(%edx),%esi
f0104419:	89 f3                	mov    %esi,%ebx
f010441b:	80 fb 19             	cmp    $0x19,%bl
f010441e:	77 08                	ja     f0104428 <strtol+0xc5>
			dig = *s - 'A' + 10;
f0104420:	0f be d2             	movsbl %dl,%edx
f0104423:	83 ea 37             	sub    $0x37,%edx
f0104426:	eb cb                	jmp    f01043f3 <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
f0104428:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010442c:	74 05                	je     f0104433 <strtol+0xd0>
		*endptr = (char *) s;
f010442e:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104431:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f0104433:	89 c2                	mov    %eax,%edx
f0104435:	f7 da                	neg    %edx
f0104437:	85 ff                	test   %edi,%edi
f0104439:	0f 45 c2             	cmovne %edx,%eax
}
f010443c:	5b                   	pop    %ebx
f010443d:	5e                   	pop    %esi
f010443e:	5f                   	pop    %edi
f010443f:	5d                   	pop    %ebp
f0104440:	c3                   	ret    
f0104441:	66 90                	xchg   %ax,%ax
f0104443:	66 90                	xchg   %ax,%ax
f0104445:	66 90                	xchg   %ax,%ax
f0104447:	66 90                	xchg   %ax,%ax
f0104449:	66 90                	xchg   %ax,%ax
f010444b:	66 90                	xchg   %ax,%ax
f010444d:	66 90                	xchg   %ax,%ax
f010444f:	90                   	nop

f0104450 <__udivdi3>:
f0104450:	55                   	push   %ebp
f0104451:	57                   	push   %edi
f0104452:	56                   	push   %esi
f0104453:	53                   	push   %ebx
f0104454:	83 ec 1c             	sub    $0x1c,%esp
f0104457:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010445b:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f010445f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0104463:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f0104467:	85 d2                	test   %edx,%edx
f0104469:	75 35                	jne    f01044a0 <__udivdi3+0x50>
f010446b:	39 f3                	cmp    %esi,%ebx
f010446d:	0f 87 bd 00 00 00    	ja     f0104530 <__udivdi3+0xe0>
f0104473:	85 db                	test   %ebx,%ebx
f0104475:	89 d9                	mov    %ebx,%ecx
f0104477:	75 0b                	jne    f0104484 <__udivdi3+0x34>
f0104479:	b8 01 00 00 00       	mov    $0x1,%eax
f010447e:	31 d2                	xor    %edx,%edx
f0104480:	f7 f3                	div    %ebx
f0104482:	89 c1                	mov    %eax,%ecx
f0104484:	31 d2                	xor    %edx,%edx
f0104486:	89 f0                	mov    %esi,%eax
f0104488:	f7 f1                	div    %ecx
f010448a:	89 c6                	mov    %eax,%esi
f010448c:	89 e8                	mov    %ebp,%eax
f010448e:	89 f7                	mov    %esi,%edi
f0104490:	f7 f1                	div    %ecx
f0104492:	89 fa                	mov    %edi,%edx
f0104494:	83 c4 1c             	add    $0x1c,%esp
f0104497:	5b                   	pop    %ebx
f0104498:	5e                   	pop    %esi
f0104499:	5f                   	pop    %edi
f010449a:	5d                   	pop    %ebp
f010449b:	c3                   	ret    
f010449c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01044a0:	39 f2                	cmp    %esi,%edx
f01044a2:	77 7c                	ja     f0104520 <__udivdi3+0xd0>
f01044a4:	0f bd fa             	bsr    %edx,%edi
f01044a7:	83 f7 1f             	xor    $0x1f,%edi
f01044aa:	0f 84 98 00 00 00    	je     f0104548 <__udivdi3+0xf8>
f01044b0:	89 f9                	mov    %edi,%ecx
f01044b2:	b8 20 00 00 00       	mov    $0x20,%eax
f01044b7:	29 f8                	sub    %edi,%eax
f01044b9:	d3 e2                	shl    %cl,%edx
f01044bb:	89 54 24 08          	mov    %edx,0x8(%esp)
f01044bf:	89 c1                	mov    %eax,%ecx
f01044c1:	89 da                	mov    %ebx,%edx
f01044c3:	d3 ea                	shr    %cl,%edx
f01044c5:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f01044c9:	09 d1                	or     %edx,%ecx
f01044cb:	89 f2                	mov    %esi,%edx
f01044cd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01044d1:	89 f9                	mov    %edi,%ecx
f01044d3:	d3 e3                	shl    %cl,%ebx
f01044d5:	89 c1                	mov    %eax,%ecx
f01044d7:	d3 ea                	shr    %cl,%edx
f01044d9:	89 f9                	mov    %edi,%ecx
f01044db:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f01044df:	d3 e6                	shl    %cl,%esi
f01044e1:	89 eb                	mov    %ebp,%ebx
f01044e3:	89 c1                	mov    %eax,%ecx
f01044e5:	d3 eb                	shr    %cl,%ebx
f01044e7:	09 de                	or     %ebx,%esi
f01044e9:	89 f0                	mov    %esi,%eax
f01044eb:	f7 74 24 08          	divl   0x8(%esp)
f01044ef:	89 d6                	mov    %edx,%esi
f01044f1:	89 c3                	mov    %eax,%ebx
f01044f3:	f7 64 24 0c          	mull   0xc(%esp)
f01044f7:	39 d6                	cmp    %edx,%esi
f01044f9:	72 0c                	jb     f0104507 <__udivdi3+0xb7>
f01044fb:	89 f9                	mov    %edi,%ecx
f01044fd:	d3 e5                	shl    %cl,%ebp
f01044ff:	39 c5                	cmp    %eax,%ebp
f0104501:	73 5d                	jae    f0104560 <__udivdi3+0x110>
f0104503:	39 d6                	cmp    %edx,%esi
f0104505:	75 59                	jne    f0104560 <__udivdi3+0x110>
f0104507:	8d 43 ff             	lea    -0x1(%ebx),%eax
f010450a:	31 ff                	xor    %edi,%edi
f010450c:	89 fa                	mov    %edi,%edx
f010450e:	83 c4 1c             	add    $0x1c,%esp
f0104511:	5b                   	pop    %ebx
f0104512:	5e                   	pop    %esi
f0104513:	5f                   	pop    %edi
f0104514:	5d                   	pop    %ebp
f0104515:	c3                   	ret    
f0104516:	8d 76 00             	lea    0x0(%esi),%esi
f0104519:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0104520:	31 ff                	xor    %edi,%edi
f0104522:	31 c0                	xor    %eax,%eax
f0104524:	89 fa                	mov    %edi,%edx
f0104526:	83 c4 1c             	add    $0x1c,%esp
f0104529:	5b                   	pop    %ebx
f010452a:	5e                   	pop    %esi
f010452b:	5f                   	pop    %edi
f010452c:	5d                   	pop    %ebp
f010452d:	c3                   	ret    
f010452e:	66 90                	xchg   %ax,%ax
f0104530:	31 ff                	xor    %edi,%edi
f0104532:	89 e8                	mov    %ebp,%eax
f0104534:	89 f2                	mov    %esi,%edx
f0104536:	f7 f3                	div    %ebx
f0104538:	89 fa                	mov    %edi,%edx
f010453a:	83 c4 1c             	add    $0x1c,%esp
f010453d:	5b                   	pop    %ebx
f010453e:	5e                   	pop    %esi
f010453f:	5f                   	pop    %edi
f0104540:	5d                   	pop    %ebp
f0104541:	c3                   	ret    
f0104542:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104548:	39 f2                	cmp    %esi,%edx
f010454a:	72 06                	jb     f0104552 <__udivdi3+0x102>
f010454c:	31 c0                	xor    %eax,%eax
f010454e:	39 eb                	cmp    %ebp,%ebx
f0104550:	77 d2                	ja     f0104524 <__udivdi3+0xd4>
f0104552:	b8 01 00 00 00       	mov    $0x1,%eax
f0104557:	eb cb                	jmp    f0104524 <__udivdi3+0xd4>
f0104559:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104560:	89 d8                	mov    %ebx,%eax
f0104562:	31 ff                	xor    %edi,%edi
f0104564:	eb be                	jmp    f0104524 <__udivdi3+0xd4>
f0104566:	66 90                	xchg   %ax,%ax
f0104568:	66 90                	xchg   %ax,%ax
f010456a:	66 90                	xchg   %ax,%ax
f010456c:	66 90                	xchg   %ax,%ax
f010456e:	66 90                	xchg   %ax,%ax

f0104570 <__umoddi3>:
f0104570:	55                   	push   %ebp
f0104571:	57                   	push   %edi
f0104572:	56                   	push   %esi
f0104573:	53                   	push   %ebx
f0104574:	83 ec 1c             	sub    $0x1c,%esp
f0104577:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
f010457b:	8b 74 24 30          	mov    0x30(%esp),%esi
f010457f:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0104583:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0104587:	85 ed                	test   %ebp,%ebp
f0104589:	89 f0                	mov    %esi,%eax
f010458b:	89 da                	mov    %ebx,%edx
f010458d:	75 19                	jne    f01045a8 <__umoddi3+0x38>
f010458f:	39 df                	cmp    %ebx,%edi
f0104591:	0f 86 b1 00 00 00    	jbe    f0104648 <__umoddi3+0xd8>
f0104597:	f7 f7                	div    %edi
f0104599:	89 d0                	mov    %edx,%eax
f010459b:	31 d2                	xor    %edx,%edx
f010459d:	83 c4 1c             	add    $0x1c,%esp
f01045a0:	5b                   	pop    %ebx
f01045a1:	5e                   	pop    %esi
f01045a2:	5f                   	pop    %edi
f01045a3:	5d                   	pop    %ebp
f01045a4:	c3                   	ret    
f01045a5:	8d 76 00             	lea    0x0(%esi),%esi
f01045a8:	39 dd                	cmp    %ebx,%ebp
f01045aa:	77 f1                	ja     f010459d <__umoddi3+0x2d>
f01045ac:	0f bd cd             	bsr    %ebp,%ecx
f01045af:	83 f1 1f             	xor    $0x1f,%ecx
f01045b2:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01045b6:	0f 84 b4 00 00 00    	je     f0104670 <__umoddi3+0x100>
f01045bc:	b8 20 00 00 00       	mov    $0x20,%eax
f01045c1:	89 c2                	mov    %eax,%edx
f01045c3:	8b 44 24 04          	mov    0x4(%esp),%eax
f01045c7:	29 c2                	sub    %eax,%edx
f01045c9:	89 c1                	mov    %eax,%ecx
f01045cb:	89 f8                	mov    %edi,%eax
f01045cd:	d3 e5                	shl    %cl,%ebp
f01045cf:	89 d1                	mov    %edx,%ecx
f01045d1:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01045d5:	d3 e8                	shr    %cl,%eax
f01045d7:	09 c5                	or     %eax,%ebp
f01045d9:	8b 44 24 04          	mov    0x4(%esp),%eax
f01045dd:	89 c1                	mov    %eax,%ecx
f01045df:	d3 e7                	shl    %cl,%edi
f01045e1:	89 d1                	mov    %edx,%ecx
f01045e3:	89 7c 24 08          	mov    %edi,0x8(%esp)
f01045e7:	89 df                	mov    %ebx,%edi
f01045e9:	d3 ef                	shr    %cl,%edi
f01045eb:	89 c1                	mov    %eax,%ecx
f01045ed:	89 f0                	mov    %esi,%eax
f01045ef:	d3 e3                	shl    %cl,%ebx
f01045f1:	89 d1                	mov    %edx,%ecx
f01045f3:	89 fa                	mov    %edi,%edx
f01045f5:	d3 e8                	shr    %cl,%eax
f01045f7:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01045fc:	09 d8                	or     %ebx,%eax
f01045fe:	f7 f5                	div    %ebp
f0104600:	d3 e6                	shl    %cl,%esi
f0104602:	89 d1                	mov    %edx,%ecx
f0104604:	f7 64 24 08          	mull   0x8(%esp)
f0104608:	39 d1                	cmp    %edx,%ecx
f010460a:	89 c3                	mov    %eax,%ebx
f010460c:	89 d7                	mov    %edx,%edi
f010460e:	72 06                	jb     f0104616 <__umoddi3+0xa6>
f0104610:	75 0e                	jne    f0104620 <__umoddi3+0xb0>
f0104612:	39 c6                	cmp    %eax,%esi
f0104614:	73 0a                	jae    f0104620 <__umoddi3+0xb0>
f0104616:	2b 44 24 08          	sub    0x8(%esp),%eax
f010461a:	19 ea                	sbb    %ebp,%edx
f010461c:	89 d7                	mov    %edx,%edi
f010461e:	89 c3                	mov    %eax,%ebx
f0104620:	89 ca                	mov    %ecx,%edx
f0104622:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f0104627:	29 de                	sub    %ebx,%esi
f0104629:	19 fa                	sbb    %edi,%edx
f010462b:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f010462f:	89 d0                	mov    %edx,%eax
f0104631:	d3 e0                	shl    %cl,%eax
f0104633:	89 d9                	mov    %ebx,%ecx
f0104635:	d3 ee                	shr    %cl,%esi
f0104637:	d3 ea                	shr    %cl,%edx
f0104639:	09 f0                	or     %esi,%eax
f010463b:	83 c4 1c             	add    $0x1c,%esp
f010463e:	5b                   	pop    %ebx
f010463f:	5e                   	pop    %esi
f0104640:	5f                   	pop    %edi
f0104641:	5d                   	pop    %ebp
f0104642:	c3                   	ret    
f0104643:	90                   	nop
f0104644:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104648:	85 ff                	test   %edi,%edi
f010464a:	89 f9                	mov    %edi,%ecx
f010464c:	75 0b                	jne    f0104659 <__umoddi3+0xe9>
f010464e:	b8 01 00 00 00       	mov    $0x1,%eax
f0104653:	31 d2                	xor    %edx,%edx
f0104655:	f7 f7                	div    %edi
f0104657:	89 c1                	mov    %eax,%ecx
f0104659:	89 d8                	mov    %ebx,%eax
f010465b:	31 d2                	xor    %edx,%edx
f010465d:	f7 f1                	div    %ecx
f010465f:	89 f0                	mov    %esi,%eax
f0104661:	f7 f1                	div    %ecx
f0104663:	e9 31 ff ff ff       	jmp    f0104599 <__umoddi3+0x29>
f0104668:	90                   	nop
f0104669:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104670:	39 dd                	cmp    %ebx,%ebp
f0104672:	72 08                	jb     f010467c <__umoddi3+0x10c>
f0104674:	39 f7                	cmp    %esi,%edi
f0104676:	0f 87 21 ff ff ff    	ja     f010459d <__umoddi3+0x2d>
f010467c:	89 da                	mov    %ebx,%edx
f010467e:	89 f0                	mov    %esi,%eax
f0104680:	29 f8                	sub    %edi,%eax
f0104682:	19 ea                	sbb    %ebp,%edx
f0104684:	e9 14 ff ff ff       	jmp    f010459d <__umoddi3+0x2d>
