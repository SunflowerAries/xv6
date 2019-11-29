
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
f0100015:	b8 00 a0 11 00       	mov    $0x11a000,%eax
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
f010002f:	bc 00 a0 11 f0       	mov    $0xf011a000,%esp

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
f0100042:	b8 54 57 16 f0       	mov    $0xf0165754,%eax
f0100047:	2d e8 2e 12 f0       	sub    $0xf0122ee8,%eax
f010004c:	50                   	push   %eax
f010004d:	6a 00                	push   $0x0
f010004f:	68 e8 2e 12 f0       	push   $0xf0122ee8
f0100054:	e8 52 37 00 00       	call   f01037ab <memset>

	cons_init();
f0100059:	e8 b2 05 00 00       	call   f0100610 <cons_init>

	cprintf("Hello, world.\n");
f010005e:	c7 04 24 00 3c 10 f0 	movl   $0xf0103c00,(%esp)
f0100065:	e8 18 07 00 00       	call   f0100782 <cprintf>
	boot_alloc_init();
f010006a:	e8 5a 20 00 00       	call   f01020c9 <boot_alloc_init>
	vm_init();
f010006f:	e8 e8 16 00 00       	call   f010175c <vm_init>
	seg_init();
f0100074:	e8 ae 12 00 00       	call   f0101327 <seg_init>
	trap_init();
f0100079:	e8 18 07 00 00       	call   f0100796 <trap_init>
	proc_init();
f010007e:	e8 eb 2a 00 00       	call   f0102b6e <proc_init>
	mp_init();
f0100083:	e8 3b 23 00 00       	call   f01023c3 <mp_init>
	lapic_init();
f0100088:	e8 fd 25 00 00       	call   f010268a <lapic_init>
	pic_init();
f010008d:	e8 64 29 00 00       	call   f01029f6 <pic_init>
	void *code;
	struct CpuInfo *c;

	// Write entry code to unused memory at MPENTRY_PADDR
	code = P2V(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);
f0100092:	83 c4 0c             	add    $0xc,%esp
f0100095:	b8 66 23 10 f0       	mov    $0xf0102366,%eax
f010009a:	2d ec 22 10 f0       	sub    $0xf01022ec,%eax
f010009f:	50                   	push   %eax
f01000a0:	68 ec 22 10 f0       	push   $0xf01022ec
f01000a5:	68 00 70 00 f0       	push   $0xf0007000
f01000aa:	e8 49 37 00 00       	call   f01037f8 <memmove>
f01000af:	83 c4 10             	add    $0x10,%esp

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f01000b2:	bb 20 40 12 f0       	mov    $0xf0124020,%ebx
f01000b7:	eb 06                	jmp    f01000bf <i386_init+0x84>
f01000b9:	81 c3 b8 00 00 00    	add    $0xb8,%ebx
f01000bf:	69 05 e4 45 12 f0 b8 	imul   $0xb8,0xf01245e4,%eax
f01000c6:	00 00 00 
f01000c9:	05 20 40 12 f0       	add    $0xf0124020,%eax
f01000ce:	39 c3                	cmp    %eax,%ebx
f01000d0:	73 4f                	jae    f0100121 <i386_init+0xe6>
		if (c == cpus + cpunum())  // We've started already.
f01000d2:	e8 99 25 00 00       	call   f0102670 <cpunum>
f01000d7:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f01000dd:	05 20 40 12 f0       	add    $0xf0124020,%eax
f01000e2:	39 c3                	cmp    %eax,%ebx
f01000e4:	74 d3                	je     f01000b9 <i386_init+0x7e>
			continue;

		// Tell mpentry.S what stack to use 
		mpentry_kstack = percpu_kstacks[c - cpus] + KSTKSIZE;
f01000e6:	89 d8                	mov    %ebx,%eax
f01000e8:	2d 20 40 12 f0       	sub    $0xf0124020,%eax
f01000ed:	c1 f8 03             	sar    $0x3,%eax
f01000f0:	69 c0 a7 37 bd e9    	imul   $0xe9bd37a7,%eax,%eax
f01000f6:	c1 e0 0f             	shl    $0xf,%eax
f01000f9:	05 00 d0 12 f0       	add    $0xf012d000,%eax
f01000fe:	a3 48 36 12 f0       	mov    %eax,0xf0123648
		// Start the CPU at mpentry_start
		lapic_startap(c->cpu_id, V2P(code));
f0100103:	83 ec 08             	sub    $0x8,%esp
f0100106:	68 00 70 00 00       	push   $0x7000
f010010b:	0f b6 03             	movzbl (%ebx),%eax
f010010e:	50                   	push   %eax
f010010f:	e8 b9 26 00 00       	call   f01027cd <lapic_startap>
f0100114:	83 c4 10             	add    $0x10,%esp
		// Wait for the CPU to finish some basic setup in mp_main()
		while(c->cpu_status != CPU_STARTED)
f0100117:	8b 43 04             	mov    0x4(%ebx),%eax
f010011a:	83 f8 01             	cmp    $0x1,%eax
f010011d:	75 f8                	jne    f0100117 <i386_init+0xdc>
f010011f:	eb 98                	jmp    f01000b9 <i386_init+0x7e>
	alloc_init();
f0100121:	e8 91 21 00 00       	call   f01022b7 <alloc_init>
	idt_init();
f0100126:	e8 de 06 00 00       	call   f0100809 <idt_init>
	cprintf("VM: Init success.\n");
f010012b:	83 ec 0c             	sub    $0xc,%esp
f010012e:	68 0f 3c 10 f0       	push   $0xf0103c0f
f0100133:	e8 4a 06 00 00       	call   f0100782 <cprintf>
	check_free_list();
f0100138:	e8 fd 1e 00 00       	call   f010203a <check_free_list>
	user_init();
f010013d:	e8 46 2a 00 00       	call   f0102b88 <user_init>
	ucode_run();
f0100142:	e8 6d 2b 00 00       	call   f0102cb4 <ucode_run>
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
f0100152:	e8 3a 15 00 00       	call   f0101691 <kvm_switch>
	seg_init();
f0100157:	e8 cb 11 00 00       	call   f0101327 <seg_init>
	lapic_init();
f010015c:	e8 29 25 00 00       	call   f010268a <lapic_init>
	cprintf("Starting CPU%d.\n", cpunum());
f0100161:	e8 0a 25 00 00       	call   f0102670 <cpunum>
f0100166:	83 ec 08             	sub    $0x8,%esp
f0100169:	50                   	push   %eax
f010016a:	68 22 3c 10 f0       	push   $0xf0103c22
f010016f:	e8 0e 06 00 00       	call   f0100782 <cprintf>
	idt_init();
f0100174:	e8 90 06 00 00       	call   f0100809 <idt_init>
	xchg(&thiscpu->cpu_status, CPU_STARTED); // tell boot_aps() we're up
f0100179:	e8 f2 24 00 00       	call   f0102670 <cpunum>
f010017e:	69 d0 b8 00 00 00    	imul   $0xb8,%eax,%edx
f0100184:	83 c2 04             	add    $0x4,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f0100187:	b8 01 00 00 00       	mov    $0x1,%eax
f010018c:	f0 87 82 20 40 12 f0 	lock xchg %eax,-0xfedbfe0(%edx)
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
f01001a0:	83 3d 44 36 12 f0 00 	cmpl   $0x0,0xf0123644
f01001a7:	74 02                	je     f01001ab <_panic+0x13>
f01001a9:	eb fe                	jmp    f01001a9 <_panic+0x11>
		goto dead;
	panicstr = fmt;
f01001ab:	89 35 44 36 12 f0    	mov    %esi,0xf0123644

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
f01001bf:	68 33 3c 10 f0       	push   $0xf0103c33
f01001c4:	e8 b9 05 00 00       	call   f0100782 <cprintf>
	vcprintf(fmt, ap);
f01001c9:	83 c4 08             	add    $0x8,%esp
f01001cc:	53                   	push   %ebx
f01001cd:	56                   	push   %esi
f01001ce:	e8 89 05 00 00       	call   f010075c <vcprintf>
	cprintf("\n");
f01001d3:	c7 04 24 6f 3c 10 f0 	movl   $0xf0103c6f,(%esp)
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
f01001f4:	68 4b 3c 10 f0       	push   $0xf0103c4b
f01001f9:	e8 84 05 00 00       	call   f0100782 <cprintf>
	vcprintf(fmt, ap);
f01001fe:	83 c4 08             	add    $0x8,%esp
f0100201:	53                   	push   %ebx
f0100202:	ff 75 10             	pushl  0x10(%ebp)
f0100205:	e8 52 05 00 00       	call   f010075c <vcprintf>
	cprintf("\n");
f010020a:	c7 04 24 6f 3c 10 f0 	movl   $0xf0103c6f,(%esp)
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
f0100251:	8b 0d 24 32 12 f0    	mov    0xf0123224,%ecx
f0100257:	8d 51 01             	lea    0x1(%ecx),%edx
f010025a:	89 15 24 32 12 f0    	mov    %edx,0xf0123224
f0100260:	88 81 20 30 12 f0    	mov    %al,-0xfedcfe0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f0100266:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010026c:	75 d8                	jne    f0100246 <cons_intr+0x9>
			cons.wpos = 0;
f010026e:	c7 05 24 32 12 f0 00 	movl   $0x0,0xf0123224
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
f01002b5:	8b 0d 00 30 12 f0    	mov    0xf0123000,%ecx
f01002bb:	f6 c1 40             	test   $0x40,%cl
f01002be:	74 0e                	je     f01002ce <kbd_proc_data+0x4e>
		data |= 0x80;
f01002c0:	83 c8 80             	or     $0xffffff80,%eax
f01002c3:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f01002c5:	83 e1 bf             	and    $0xffffffbf,%ecx
f01002c8:	89 0d 00 30 12 f0    	mov    %ecx,0xf0123000
	shift |= shiftcode[data];
f01002ce:	0f b6 d2             	movzbl %dl,%edx
f01002d1:	0f b6 82 c0 3d 10 f0 	movzbl -0xfefc240(%edx),%eax
f01002d8:	0b 05 00 30 12 f0    	or     0xf0123000,%eax
	shift ^= togglecode[data];
f01002de:	0f b6 8a c0 3c 10 f0 	movzbl -0xfefc340(%edx),%ecx
f01002e5:	31 c8                	xor    %ecx,%eax
f01002e7:	a3 00 30 12 f0       	mov    %eax,0xf0123000
	c = charcode[shift & (CTL | SHIFT)][data];
f01002ec:	89 c1                	mov    %eax,%ecx
f01002ee:	83 e1 03             	and    $0x3,%ecx
f01002f1:	8b 0c 8d a0 3c 10 f0 	mov    -0xfefc360(,%ecx,4),%ecx
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
f0100321:	68 65 3c 10 f0       	push   $0xf0103c65
f0100326:	e8 57 04 00 00       	call   f0100782 <cprintf>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010032b:	b8 03 00 00 00       	mov    $0x3,%eax
f0100330:	ba 92 00 00 00       	mov    $0x92,%edx
f0100335:	ee                   	out    %al,(%dx)
f0100336:	83 c4 10             	add    $0x10,%esp
f0100339:	eb 0c                	jmp    f0100347 <kbd_proc_data+0xc7>
		shift |= E0ESC;
f010033b:	83 0d 00 30 12 f0 40 	orl    $0x40,0xf0123000
		return 0;
f0100342:	bb 00 00 00 00       	mov    $0x0,%ebx
}
f0100347:	89 d8                	mov    %ebx,%eax
f0100349:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010034c:	c9                   	leave  
f010034d:	c3                   	ret    
		data = (shift & E0ESC ? data : data & 0x7F);
f010034e:	8b 0d 00 30 12 f0    	mov    0xf0123000,%ecx
f0100354:	89 cb                	mov    %ecx,%ebx
f0100356:	83 e3 40             	and    $0x40,%ebx
f0100359:	83 e0 7f             	and    $0x7f,%eax
f010035c:	85 db                	test   %ebx,%ebx
f010035e:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100361:	0f b6 d2             	movzbl %dl,%edx
f0100364:	0f b6 82 c0 3d 10 f0 	movzbl -0xfefc240(%edx),%eax
f010036b:	83 c8 40             	or     $0x40,%eax
f010036e:	0f b6 c0             	movzbl %al,%eax
f0100371:	f7 d0                	not    %eax
f0100373:	21 c8                	and    %ecx,%eax
f0100375:	a3 00 30 12 f0       	mov    %eax,0xf0123000
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
f0100457:	0f b7 05 28 32 12 f0 	movzwl 0xf0123228,%eax
f010045e:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100464:	c1 e8 16             	shr    $0x16,%eax
f0100467:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010046a:	c1 e0 04             	shl    $0x4,%eax
f010046d:	66 a3 28 32 12 f0    	mov    %ax,0xf0123228
	if (crt_pos >= CRT_SIZE) {
f0100473:	66 81 3d 28 32 12 f0 	cmpw   $0x7cf,0xf0123228
f010047a:	cf 07 
f010047c:	0f 87 ce 00 00 00    	ja     f0100550 <cons_putc+0x1b3>
	outb(addr_6845, 14);
f0100482:	8b 0d 30 32 12 f0    	mov    0xf0123230,%ecx
f0100488:	b8 0e 00 00 00       	mov    $0xe,%eax
f010048d:	89 ca                	mov    %ecx,%edx
f010048f:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100490:	0f b7 1d 28 32 12 f0 	movzwl 0xf0123228,%ebx
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
f01004bd:	0f b7 05 28 32 12 f0 	movzwl 0xf0123228,%eax
f01004c4:	66 85 c0             	test   %ax,%ax
f01004c7:	74 b9                	je     f0100482 <cons_putc+0xe5>
			crt_pos--;
f01004c9:	83 e8 01             	sub    $0x1,%eax
f01004cc:	66 a3 28 32 12 f0    	mov    %ax,0xf0123228
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01004d2:	0f b7 c0             	movzwl %ax,%eax
f01004d5:	66 81 e7 00 ff       	and    $0xff00,%di
f01004da:	83 cf 20             	or     $0x20,%edi
f01004dd:	8b 15 2c 32 12 f0    	mov    0xf012322c,%edx
f01004e3:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01004e7:	eb 8a                	jmp    f0100473 <cons_putc+0xd6>
		crt_pos += CRT_COLS;
f01004e9:	66 83 05 28 32 12 f0 	addw   $0x50,0xf0123228
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
f010052d:	0f b7 05 28 32 12 f0 	movzwl 0xf0123228,%eax
f0100534:	8d 50 01             	lea    0x1(%eax),%edx
f0100537:	66 89 15 28 32 12 f0 	mov    %dx,0xf0123228
f010053e:	0f b7 c0             	movzwl %ax,%eax
f0100541:	8b 15 2c 32 12 f0    	mov    0xf012322c,%edx
f0100547:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f010054b:	e9 23 ff ff ff       	jmp    f0100473 <cons_putc+0xd6>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100550:	a1 2c 32 12 f0       	mov    0xf012322c,%eax
f0100555:	83 ec 04             	sub    $0x4,%esp
f0100558:	68 00 0f 00 00       	push   $0xf00
f010055d:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100563:	52                   	push   %edx
f0100564:	50                   	push   %eax
f0100565:	e8 8e 32 00 00       	call   f01037f8 <memmove>
			crt_buf[i] = 0x0700 | ' ';
f010056a:	8b 15 2c 32 12 f0    	mov    0xf012322c,%edx
f0100570:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100576:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f010057c:	83 c4 10             	add    $0x10,%esp
f010057f:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100584:	83 c0 02             	add    $0x2,%eax
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100587:	39 d0                	cmp    %edx,%eax
f0100589:	75 f4                	jne    f010057f <cons_putc+0x1e2>
		crt_pos -= CRT_COLS;
f010058b:	66 83 2d 28 32 12 f0 	subw   $0x50,0xf0123228
f0100592:	50 
f0100593:	e9 ea fe ff ff       	jmp    f0100482 <cons_putc+0xe5>

f0100598 <serial_intr>:
	if (serial_exists)
f0100598:	80 3d 34 32 12 f0 00 	cmpb   $0x0,0xf0123234
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
f01005d7:	8b 15 20 32 12 f0    	mov    0xf0123220,%edx
	return 0;
f01005dd:	b8 00 00 00 00       	mov    $0x0,%eax
	if (cons.rpos != cons.wpos) {
f01005e2:	3b 15 24 32 12 f0    	cmp    0xf0123224,%edx
f01005e8:	74 18                	je     f0100602 <cons_getc+0x3b>
		c = cons.buf[cons.rpos++];
f01005ea:	8d 4a 01             	lea    0x1(%edx),%ecx
f01005ed:	89 0d 20 32 12 f0    	mov    %ecx,0xf0123220
f01005f3:	0f b6 82 20 30 12 f0 	movzbl -0xfedcfe0(%edx),%eax
		if (cons.rpos == CONSBUFSIZE)
f01005fa:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f0100600:	74 02                	je     f0100604 <cons_getc+0x3d>
}
f0100602:	c9                   	leave  
f0100603:	c3                   	ret    
			cons.rpos = 0;
f0100604:	c7 05 20 32 12 f0 00 	movl   $0x0,0xf0123220
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
f010063a:	c7 05 30 32 12 f0 b4 	movl   $0x3b4,0xf0123230
f0100641:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100644:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
	outb(addr_6845, 14);
f0100649:	8b 3d 30 32 12 f0    	mov    0xf0123230,%edi
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
f0100670:	89 35 2c 32 12 f0    	mov    %esi,0xf012322c
	pos |= inb(addr_6845 + 1);
f0100676:	0f b6 c0             	movzbl %al,%eax
f0100679:	09 d8                	or     %ebx,%eax
	crt_pos = pos;
f010067b:	66 a3 28 32 12 f0    	mov    %ax,0xf0123228
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
f01006d4:	0f 95 05 34 32 12 f0 	setne  0xf0123234
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
f01006f8:	c7 05 30 32 12 f0 d4 	movl   $0x3d4,0xf0123230
f01006ff:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100702:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
f0100707:	e9 3d ff ff ff       	jmp    f0100649 <cons_init+0x39>
		cprintf("Serial port does not exist!\n");
f010070c:	83 ec 0c             	sub    $0xc,%esp
f010070f:	68 71 3c 10 f0       	push   $0xf0103c71
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
f0100778:	e8 e9 28 00 00       	call   f0103066 <vprintfmt>
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
uint32_t ticks;

// Initialize the interrupt descriptor table.
void
trap_init(void)
{
f0100796:	55                   	push   %ebp
f0100797:	89 e5                	mov    %esp,%ebp
	//
	// Hints:
	// 1. The macro SETGATE in inc/mmu.h should help you, as well as the
	// T_* defines in inc/traps.h;
	// 2. T_SYSCALL is different from the others.
	for (int i = 0; i < 256; i++)
f0100799:	b8 00 00 00 00       	mov    $0x0,%eax
		SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
f010079e:	8b 14 85 00 c3 11 f0 	mov    -0xfee3d00(,%eax,4),%edx
f01007a5:	66 89 14 c5 60 36 12 	mov    %dx,-0xfedc9a0(,%eax,8)
f01007ac:	f0 
f01007ad:	66 c7 04 c5 62 36 12 	movw   $0x8,-0xfedc99e(,%eax,8)
f01007b4:	f0 08 00 
f01007b7:	c6 04 c5 64 36 12 f0 	movb   $0x0,-0xfedc99c(,%eax,8)
f01007be:	00 
f01007bf:	c6 04 c5 65 36 12 f0 	movb   $0x8e,-0xfedc99b(,%eax,8)
f01007c6:	8e 
f01007c7:	c1 ea 10             	shr    $0x10,%edx
f01007ca:	66 89 14 c5 66 36 12 	mov    %dx,-0xfedc99a(,%eax,8)
f01007d1:	f0 
	for (int i = 0; i < 256; i++)
f01007d2:	83 c0 01             	add    $0x1,%eax
f01007d5:	3d 00 01 00 00       	cmp    $0x100,%eax
f01007da:	75 c2                	jne    f010079e <trap_init+0x8>
	SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
f01007dc:	a1 00 c4 11 f0       	mov    0xf011c400,%eax
f01007e1:	66 a3 60 38 12 f0    	mov    %ax,0xf0123860
f01007e7:	66 c7 05 62 38 12 f0 	movw   $0x8,0xf0123862
f01007ee:	08 00 
f01007f0:	c6 05 64 38 12 f0 00 	movb   $0x0,0xf0123864
f01007f7:	c6 05 65 38 12 f0 ef 	movb   $0xef,0xf0123865
f01007fe:	c1 e8 10             	shr    $0x10,%eax
f0100801:	66 a3 66 38 12 f0    	mov    %ax,0xf0123866
}
f0100807:	5d                   	pop    %ebp
f0100808:	c3                   	ret    

f0100809 <idt_init>:

void
idt_init(void)
{
f0100809:	55                   	push   %ebp
f010080a:	89 e5                	mov    %esp,%ebp
f010080c:	83 ec 10             	sub    $0x10,%esp
	pd[0] = size-1;
f010080f:	66 c7 45 fa ff 07    	movw   $0x7ff,-0x6(%ebp)
	pd[1] = (unsigned)p;
f0100815:	b8 60 36 12 f0       	mov    $0xf0123660,%eax
f010081a:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
	pd[2] = (unsigned)p >> 16;
f010081e:	c1 e8 10             	shr    $0x10,%eax
f0100821:	66 89 45 fe          	mov    %ax,-0x2(%ebp)
	asm volatile("lidt (%0)" : : "r" (pd));
f0100825:	8d 45 fa             	lea    -0x6(%ebp),%eax
f0100828:	0f 01 18             	lidtl  (%eax)
	lidt(idt, sizeof(idt));
}
f010082b:	c9                   	leave  
f010082c:	c3                   	ret    

f010082d <trap>:

void
trap(struct trapframe *tf)
{
f010082d:	55                   	push   %ebp
f010082e:	89 e5                	mov    %esp,%ebp
f0100830:	56                   	push   %esi
f0100831:	53                   	push   %ebx
f0100832:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// You don't need to implement this function now, but you can write
	// some code for debugging.
	struct proc *p = thisproc();
f0100835:	e8 2f 25 00 00       	call   f0102d69 <thisproc>
f010083a:	89 c6                	mov    %eax,%esi
	if (tf->trapno == T_SYSCALL) {
f010083c:	8b 43 30             	mov    0x30(%ebx),%eax
f010083f:	83 f8 40             	cmp    $0x40,%eax
f0100842:	74 16                	je     f010085a <trap+0x2d>
		p->tf = tf;
		// cprintf("in trap.\n");
		tf->eax = syscall(tf->eax, tf->edx, tf->ecx, tf->ebx, tf->edi, tf->esi);
		return;
	}
	switch (tf->trapno) {
f0100844:	83 f8 20             	cmp    $0x20,%eax
f0100847:	74 35                	je     f010087e <trap+0x51>
        //     "eip 0x%x addr 0x%x--kill proc\n",
        //     p->pid, tf->trapno,
        //     tf->err, cpunum(), tf->eip, rcr2());
		break;
	}
	if (p && p->state == RUNNING && tf->trapno == T_IRQ0 + IRQ_TIMER)
f0100849:	85 f6                	test   %esi,%esi
f010084b:	74 06                	je     f0100853 <trap+0x26>
f010084d:	83 7e 08 04          	cmpl   $0x4,0x8(%esi)
f0100851:	74 32                	je     f0100885 <trap+0x58>
		yield();
f0100853:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100856:	5b                   	pop    %ebx
f0100857:	5e                   	pop    %esi
f0100858:	5d                   	pop    %ebp
f0100859:	c3                   	ret    
		p->tf = tf;
f010085a:	89 5e 14             	mov    %ebx,0x14(%esi)
		tf->eax = syscall(tf->eax, tf->edx, tf->ecx, tf->ebx, tf->edi, tf->esi);
f010085d:	83 ec 08             	sub    $0x8,%esp
f0100860:	ff 73 04             	pushl  0x4(%ebx)
f0100863:	ff 33                	pushl  (%ebx)
f0100865:	ff 73 10             	pushl  0x10(%ebx)
f0100868:	ff 73 18             	pushl  0x18(%ebx)
f010086b:	ff 73 14             	pushl  0x14(%ebx)
f010086e:	ff 73 1c             	pushl  0x1c(%ebx)
f0100871:	e8 3e 26 00 00       	call   f0102eb4 <syscall>
f0100876:	89 43 1c             	mov    %eax,0x1c(%ebx)
		return;
f0100879:	83 c4 20             	add    $0x20,%esp
f010087c:	eb d5                	jmp    f0100853 <trap+0x26>
		lapic_eoi();
f010087e:	e8 2b 1f 00 00       	call   f01027ae <lapic_eoi>
		break;
f0100883:	eb c4                	jmp    f0100849 <trap+0x1c>
	if (p && p->state == RUNNING && tf->trapno == T_IRQ0 + IRQ_TIMER)
f0100885:	83 7b 30 20          	cmpl   $0x20,0x30(%ebx)
f0100889:	75 c8                	jne    f0100853 <trap+0x26>
		yield();
f010088b:	e8 e9 25 00 00       	call   f0102e79 <yield>
f0100890:	eb c1                	jmp    f0100853 <trap+0x26>

f0100892 <alltraps>:
alltraps:
	# Your code here:
	#
	# Hint: you should build trap frame, set up data segments and then
	# call trap(tf)
	pushl %ds
f0100892:	1e                   	push   %ds
	pushl %es
f0100893:	06                   	push   %es
	pushl %fs
f0100894:	0f a0                	push   %fs
	pushl %gs
f0100896:	0f a8                	push   %gs
	pushal 
f0100898:	60                   	pusha  

	movw $(SEG_KDATA<<3), %ax
f0100899:	66 b8 10 00          	mov    $0x10,%ax
	movw %ax, %ds
f010089d:	8e d8                	mov    %eax,%ds
	movw %ax, %es
f010089f:	8e c0                	mov    %eax,%es

	pushl %esp
f01008a1:	54                   	push   %esp
	call trap
f01008a2:	e8 86 ff ff ff       	call   f010082d <trap>
	addl $4, %esp
f01008a7:	83 c4 04             	add    $0x4,%esp

f01008aa <trapret>:
	# Return falls through to trapret...
.globl trapret
trapret:
	# Restore registers.
	# Your code here:
	popal
f01008aa:	61                   	popa   
	popl %gs
f01008ab:	0f a9                	pop    %gs
	popl %fs
f01008ad:	0f a1                	pop    %fs
	popl %es
f01008af:	07                   	pop    %es
	popl %ds
f01008b0:	1f                   	pop    %ds
	addl $0x8, %esp
f01008b1:	83 c4 08             	add    $0x8,%esp
	iret
f01008b4:	cf                   	iret   

f01008b5 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
f01008b5:	6a 00                	push   $0x0
  pushl $0
f01008b7:	6a 00                	push   $0x0
  jmp alltraps
f01008b9:	e9 d4 ff ff ff       	jmp    f0100892 <alltraps>

f01008be <vector1>:
.globl vector1
vector1:
  pushl $0
f01008be:	6a 00                	push   $0x0
  pushl $1
f01008c0:	6a 01                	push   $0x1
  jmp alltraps
f01008c2:	e9 cb ff ff ff       	jmp    f0100892 <alltraps>

f01008c7 <vector2>:
.globl vector2
vector2:
  pushl $0
f01008c7:	6a 00                	push   $0x0
  pushl $2
f01008c9:	6a 02                	push   $0x2
  jmp alltraps
f01008cb:	e9 c2 ff ff ff       	jmp    f0100892 <alltraps>

f01008d0 <vector3>:
.globl vector3
vector3:
  pushl $0
f01008d0:	6a 00                	push   $0x0
  pushl $3
f01008d2:	6a 03                	push   $0x3
  jmp alltraps
f01008d4:	e9 b9 ff ff ff       	jmp    f0100892 <alltraps>

f01008d9 <vector4>:
.globl vector4
vector4:
  pushl $0
f01008d9:	6a 00                	push   $0x0
  pushl $4
f01008db:	6a 04                	push   $0x4
  jmp alltraps
f01008dd:	e9 b0 ff ff ff       	jmp    f0100892 <alltraps>

f01008e2 <vector5>:
.globl vector5
vector5:
  pushl $0
f01008e2:	6a 00                	push   $0x0
  pushl $5
f01008e4:	6a 05                	push   $0x5
  jmp alltraps
f01008e6:	e9 a7 ff ff ff       	jmp    f0100892 <alltraps>

f01008eb <vector6>:
.globl vector6
vector6:
  pushl $0
f01008eb:	6a 00                	push   $0x0
  pushl $6
f01008ed:	6a 06                	push   $0x6
  jmp alltraps
f01008ef:	e9 9e ff ff ff       	jmp    f0100892 <alltraps>

f01008f4 <vector7>:
.globl vector7
vector7:
  pushl $0
f01008f4:	6a 00                	push   $0x0
  pushl $7
f01008f6:	6a 07                	push   $0x7
  jmp alltraps
f01008f8:	e9 95 ff ff ff       	jmp    f0100892 <alltraps>

f01008fd <vector8>:
.globl vector8
vector8:
  pushl $8
f01008fd:	6a 08                	push   $0x8
  jmp alltraps
f01008ff:	e9 8e ff ff ff       	jmp    f0100892 <alltraps>

f0100904 <vector9>:
.globl vector9
vector9:
  pushl $0
f0100904:	6a 00                	push   $0x0
  pushl $9
f0100906:	6a 09                	push   $0x9
  jmp alltraps
f0100908:	e9 85 ff ff ff       	jmp    f0100892 <alltraps>

f010090d <vector10>:
.globl vector10
vector10:
  pushl $10
f010090d:	6a 0a                	push   $0xa
  jmp alltraps
f010090f:	e9 7e ff ff ff       	jmp    f0100892 <alltraps>

f0100914 <vector11>:
.globl vector11
vector11:
  pushl $11
f0100914:	6a 0b                	push   $0xb
  jmp alltraps
f0100916:	e9 77 ff ff ff       	jmp    f0100892 <alltraps>

f010091b <vector12>:
.globl vector12
vector12:
  pushl $12
f010091b:	6a 0c                	push   $0xc
  jmp alltraps
f010091d:	e9 70 ff ff ff       	jmp    f0100892 <alltraps>

f0100922 <vector13>:
.globl vector13
vector13:
  pushl $13
f0100922:	6a 0d                	push   $0xd
  jmp alltraps
f0100924:	e9 69 ff ff ff       	jmp    f0100892 <alltraps>

f0100929 <vector14>:
.globl vector14
vector14:
  pushl $14
f0100929:	6a 0e                	push   $0xe
  jmp alltraps
f010092b:	e9 62 ff ff ff       	jmp    f0100892 <alltraps>

f0100930 <vector15>:
.globl vector15
vector15:
  pushl $0
f0100930:	6a 00                	push   $0x0
  pushl $15
f0100932:	6a 0f                	push   $0xf
  jmp alltraps
f0100934:	e9 59 ff ff ff       	jmp    f0100892 <alltraps>

f0100939 <vector16>:
.globl vector16
vector16:
  pushl $0
f0100939:	6a 00                	push   $0x0
  pushl $16
f010093b:	6a 10                	push   $0x10
  jmp alltraps
f010093d:	e9 50 ff ff ff       	jmp    f0100892 <alltraps>

f0100942 <vector17>:
.globl vector17
vector17:
  pushl $17
f0100942:	6a 11                	push   $0x11
  jmp alltraps
f0100944:	e9 49 ff ff ff       	jmp    f0100892 <alltraps>

f0100949 <vector18>:
.globl vector18
vector18:
  pushl $0
f0100949:	6a 00                	push   $0x0
  pushl $18
f010094b:	6a 12                	push   $0x12
  jmp alltraps
f010094d:	e9 40 ff ff ff       	jmp    f0100892 <alltraps>

f0100952 <vector19>:
.globl vector19
vector19:
  pushl $0
f0100952:	6a 00                	push   $0x0
  pushl $19
f0100954:	6a 13                	push   $0x13
  jmp alltraps
f0100956:	e9 37 ff ff ff       	jmp    f0100892 <alltraps>

f010095b <vector20>:
.globl vector20
vector20:
  pushl $0
f010095b:	6a 00                	push   $0x0
  pushl $20
f010095d:	6a 14                	push   $0x14
  jmp alltraps
f010095f:	e9 2e ff ff ff       	jmp    f0100892 <alltraps>

f0100964 <vector21>:
.globl vector21
vector21:
  pushl $0
f0100964:	6a 00                	push   $0x0
  pushl $21
f0100966:	6a 15                	push   $0x15
  jmp alltraps
f0100968:	e9 25 ff ff ff       	jmp    f0100892 <alltraps>

f010096d <vector22>:
.globl vector22
vector22:
  pushl $0
f010096d:	6a 00                	push   $0x0
  pushl $22
f010096f:	6a 16                	push   $0x16
  jmp alltraps
f0100971:	e9 1c ff ff ff       	jmp    f0100892 <alltraps>

f0100976 <vector23>:
.globl vector23
vector23:
  pushl $0
f0100976:	6a 00                	push   $0x0
  pushl $23
f0100978:	6a 17                	push   $0x17
  jmp alltraps
f010097a:	e9 13 ff ff ff       	jmp    f0100892 <alltraps>

f010097f <vector24>:
.globl vector24
vector24:
  pushl $0
f010097f:	6a 00                	push   $0x0
  pushl $24
f0100981:	6a 18                	push   $0x18
  jmp alltraps
f0100983:	e9 0a ff ff ff       	jmp    f0100892 <alltraps>

f0100988 <vector25>:
.globl vector25
vector25:
  pushl $0
f0100988:	6a 00                	push   $0x0
  pushl $25
f010098a:	6a 19                	push   $0x19
  jmp alltraps
f010098c:	e9 01 ff ff ff       	jmp    f0100892 <alltraps>

f0100991 <vector26>:
.globl vector26
vector26:
  pushl $0
f0100991:	6a 00                	push   $0x0
  pushl $26
f0100993:	6a 1a                	push   $0x1a
  jmp alltraps
f0100995:	e9 f8 fe ff ff       	jmp    f0100892 <alltraps>

f010099a <vector27>:
.globl vector27
vector27:
  pushl $0
f010099a:	6a 00                	push   $0x0
  pushl $27
f010099c:	6a 1b                	push   $0x1b
  jmp alltraps
f010099e:	e9 ef fe ff ff       	jmp    f0100892 <alltraps>

f01009a3 <vector28>:
.globl vector28
vector28:
  pushl $0
f01009a3:	6a 00                	push   $0x0
  pushl $28
f01009a5:	6a 1c                	push   $0x1c
  jmp alltraps
f01009a7:	e9 e6 fe ff ff       	jmp    f0100892 <alltraps>

f01009ac <vector29>:
.globl vector29
vector29:
  pushl $0
f01009ac:	6a 00                	push   $0x0
  pushl $29
f01009ae:	6a 1d                	push   $0x1d
  jmp alltraps
f01009b0:	e9 dd fe ff ff       	jmp    f0100892 <alltraps>

f01009b5 <vector30>:
.globl vector30
vector30:
  pushl $0
f01009b5:	6a 00                	push   $0x0
  pushl $30
f01009b7:	6a 1e                	push   $0x1e
  jmp alltraps
f01009b9:	e9 d4 fe ff ff       	jmp    f0100892 <alltraps>

f01009be <vector31>:
.globl vector31
vector31:
  pushl $0
f01009be:	6a 00                	push   $0x0
  pushl $31
f01009c0:	6a 1f                	push   $0x1f
  jmp alltraps
f01009c2:	e9 cb fe ff ff       	jmp    f0100892 <alltraps>

f01009c7 <vector32>:
.globl vector32
vector32:
  pushl $0
f01009c7:	6a 00                	push   $0x0
  pushl $32
f01009c9:	6a 20                	push   $0x20
  jmp alltraps
f01009cb:	e9 c2 fe ff ff       	jmp    f0100892 <alltraps>

f01009d0 <vector33>:
.globl vector33
vector33:
  pushl $0
f01009d0:	6a 00                	push   $0x0
  pushl $33
f01009d2:	6a 21                	push   $0x21
  jmp alltraps
f01009d4:	e9 b9 fe ff ff       	jmp    f0100892 <alltraps>

f01009d9 <vector34>:
.globl vector34
vector34:
  pushl $0
f01009d9:	6a 00                	push   $0x0
  pushl $34
f01009db:	6a 22                	push   $0x22
  jmp alltraps
f01009dd:	e9 b0 fe ff ff       	jmp    f0100892 <alltraps>

f01009e2 <vector35>:
.globl vector35
vector35:
  pushl $0
f01009e2:	6a 00                	push   $0x0
  pushl $35
f01009e4:	6a 23                	push   $0x23
  jmp alltraps
f01009e6:	e9 a7 fe ff ff       	jmp    f0100892 <alltraps>

f01009eb <vector36>:
.globl vector36
vector36:
  pushl $0
f01009eb:	6a 00                	push   $0x0
  pushl $36
f01009ed:	6a 24                	push   $0x24
  jmp alltraps
f01009ef:	e9 9e fe ff ff       	jmp    f0100892 <alltraps>

f01009f4 <vector37>:
.globl vector37
vector37:
  pushl $0
f01009f4:	6a 00                	push   $0x0
  pushl $37
f01009f6:	6a 25                	push   $0x25
  jmp alltraps
f01009f8:	e9 95 fe ff ff       	jmp    f0100892 <alltraps>

f01009fd <vector38>:
.globl vector38
vector38:
  pushl $0
f01009fd:	6a 00                	push   $0x0
  pushl $38
f01009ff:	6a 26                	push   $0x26
  jmp alltraps
f0100a01:	e9 8c fe ff ff       	jmp    f0100892 <alltraps>

f0100a06 <vector39>:
.globl vector39
vector39:
  pushl $0
f0100a06:	6a 00                	push   $0x0
  pushl $39
f0100a08:	6a 27                	push   $0x27
  jmp alltraps
f0100a0a:	e9 83 fe ff ff       	jmp    f0100892 <alltraps>

f0100a0f <vector40>:
.globl vector40
vector40:
  pushl $0
f0100a0f:	6a 00                	push   $0x0
  pushl $40
f0100a11:	6a 28                	push   $0x28
  jmp alltraps
f0100a13:	e9 7a fe ff ff       	jmp    f0100892 <alltraps>

f0100a18 <vector41>:
.globl vector41
vector41:
  pushl $0
f0100a18:	6a 00                	push   $0x0
  pushl $41
f0100a1a:	6a 29                	push   $0x29
  jmp alltraps
f0100a1c:	e9 71 fe ff ff       	jmp    f0100892 <alltraps>

f0100a21 <vector42>:
.globl vector42
vector42:
  pushl $0
f0100a21:	6a 00                	push   $0x0
  pushl $42
f0100a23:	6a 2a                	push   $0x2a
  jmp alltraps
f0100a25:	e9 68 fe ff ff       	jmp    f0100892 <alltraps>

f0100a2a <vector43>:
.globl vector43
vector43:
  pushl $0
f0100a2a:	6a 00                	push   $0x0
  pushl $43
f0100a2c:	6a 2b                	push   $0x2b
  jmp alltraps
f0100a2e:	e9 5f fe ff ff       	jmp    f0100892 <alltraps>

f0100a33 <vector44>:
.globl vector44
vector44:
  pushl $0
f0100a33:	6a 00                	push   $0x0
  pushl $44
f0100a35:	6a 2c                	push   $0x2c
  jmp alltraps
f0100a37:	e9 56 fe ff ff       	jmp    f0100892 <alltraps>

f0100a3c <vector45>:
.globl vector45
vector45:
  pushl $0
f0100a3c:	6a 00                	push   $0x0
  pushl $45
f0100a3e:	6a 2d                	push   $0x2d
  jmp alltraps
f0100a40:	e9 4d fe ff ff       	jmp    f0100892 <alltraps>

f0100a45 <vector46>:
.globl vector46
vector46:
  pushl $0
f0100a45:	6a 00                	push   $0x0
  pushl $46
f0100a47:	6a 2e                	push   $0x2e
  jmp alltraps
f0100a49:	e9 44 fe ff ff       	jmp    f0100892 <alltraps>

f0100a4e <vector47>:
.globl vector47
vector47:
  pushl $0
f0100a4e:	6a 00                	push   $0x0
  pushl $47
f0100a50:	6a 2f                	push   $0x2f
  jmp alltraps
f0100a52:	e9 3b fe ff ff       	jmp    f0100892 <alltraps>

f0100a57 <vector48>:
.globl vector48
vector48:
  pushl $0
f0100a57:	6a 00                	push   $0x0
  pushl $48
f0100a59:	6a 30                	push   $0x30
  jmp alltraps
f0100a5b:	e9 32 fe ff ff       	jmp    f0100892 <alltraps>

f0100a60 <vector49>:
.globl vector49
vector49:
  pushl $0
f0100a60:	6a 00                	push   $0x0
  pushl $49
f0100a62:	6a 31                	push   $0x31
  jmp alltraps
f0100a64:	e9 29 fe ff ff       	jmp    f0100892 <alltraps>

f0100a69 <vector50>:
.globl vector50
vector50:
  pushl $0
f0100a69:	6a 00                	push   $0x0
  pushl $50
f0100a6b:	6a 32                	push   $0x32
  jmp alltraps
f0100a6d:	e9 20 fe ff ff       	jmp    f0100892 <alltraps>

f0100a72 <vector51>:
.globl vector51
vector51:
  pushl $0
f0100a72:	6a 00                	push   $0x0
  pushl $51
f0100a74:	6a 33                	push   $0x33
  jmp alltraps
f0100a76:	e9 17 fe ff ff       	jmp    f0100892 <alltraps>

f0100a7b <vector52>:
.globl vector52
vector52:
  pushl $0
f0100a7b:	6a 00                	push   $0x0
  pushl $52
f0100a7d:	6a 34                	push   $0x34
  jmp alltraps
f0100a7f:	e9 0e fe ff ff       	jmp    f0100892 <alltraps>

f0100a84 <vector53>:
.globl vector53
vector53:
  pushl $0
f0100a84:	6a 00                	push   $0x0
  pushl $53
f0100a86:	6a 35                	push   $0x35
  jmp alltraps
f0100a88:	e9 05 fe ff ff       	jmp    f0100892 <alltraps>

f0100a8d <vector54>:
.globl vector54
vector54:
  pushl $0
f0100a8d:	6a 00                	push   $0x0
  pushl $54
f0100a8f:	6a 36                	push   $0x36
  jmp alltraps
f0100a91:	e9 fc fd ff ff       	jmp    f0100892 <alltraps>

f0100a96 <vector55>:
.globl vector55
vector55:
  pushl $0
f0100a96:	6a 00                	push   $0x0
  pushl $55
f0100a98:	6a 37                	push   $0x37
  jmp alltraps
f0100a9a:	e9 f3 fd ff ff       	jmp    f0100892 <alltraps>

f0100a9f <vector56>:
.globl vector56
vector56:
  pushl $0
f0100a9f:	6a 00                	push   $0x0
  pushl $56
f0100aa1:	6a 38                	push   $0x38
  jmp alltraps
f0100aa3:	e9 ea fd ff ff       	jmp    f0100892 <alltraps>

f0100aa8 <vector57>:
.globl vector57
vector57:
  pushl $0
f0100aa8:	6a 00                	push   $0x0
  pushl $57
f0100aaa:	6a 39                	push   $0x39
  jmp alltraps
f0100aac:	e9 e1 fd ff ff       	jmp    f0100892 <alltraps>

f0100ab1 <vector58>:
.globl vector58
vector58:
  pushl $0
f0100ab1:	6a 00                	push   $0x0
  pushl $58
f0100ab3:	6a 3a                	push   $0x3a
  jmp alltraps
f0100ab5:	e9 d8 fd ff ff       	jmp    f0100892 <alltraps>

f0100aba <vector59>:
.globl vector59
vector59:
  pushl $0
f0100aba:	6a 00                	push   $0x0
  pushl $59
f0100abc:	6a 3b                	push   $0x3b
  jmp alltraps
f0100abe:	e9 cf fd ff ff       	jmp    f0100892 <alltraps>

f0100ac3 <vector60>:
.globl vector60
vector60:
  pushl $0
f0100ac3:	6a 00                	push   $0x0
  pushl $60
f0100ac5:	6a 3c                	push   $0x3c
  jmp alltraps
f0100ac7:	e9 c6 fd ff ff       	jmp    f0100892 <alltraps>

f0100acc <vector61>:
.globl vector61
vector61:
  pushl $0
f0100acc:	6a 00                	push   $0x0
  pushl $61
f0100ace:	6a 3d                	push   $0x3d
  jmp alltraps
f0100ad0:	e9 bd fd ff ff       	jmp    f0100892 <alltraps>

f0100ad5 <vector62>:
.globl vector62
vector62:
  pushl $0
f0100ad5:	6a 00                	push   $0x0
  pushl $62
f0100ad7:	6a 3e                	push   $0x3e
  jmp alltraps
f0100ad9:	e9 b4 fd ff ff       	jmp    f0100892 <alltraps>

f0100ade <vector63>:
.globl vector63
vector63:
  pushl $0
f0100ade:	6a 00                	push   $0x0
  pushl $63
f0100ae0:	6a 3f                	push   $0x3f
  jmp alltraps
f0100ae2:	e9 ab fd ff ff       	jmp    f0100892 <alltraps>

f0100ae7 <vector64>:
.globl vector64
vector64:
  pushl $0
f0100ae7:	6a 00                	push   $0x0
  pushl $64
f0100ae9:	6a 40                	push   $0x40
  jmp alltraps
f0100aeb:	e9 a2 fd ff ff       	jmp    f0100892 <alltraps>

f0100af0 <vector65>:
.globl vector65
vector65:
  pushl $0
f0100af0:	6a 00                	push   $0x0
  pushl $65
f0100af2:	6a 41                	push   $0x41
  jmp alltraps
f0100af4:	e9 99 fd ff ff       	jmp    f0100892 <alltraps>

f0100af9 <vector66>:
.globl vector66
vector66:
  pushl $0
f0100af9:	6a 00                	push   $0x0
  pushl $66
f0100afb:	6a 42                	push   $0x42
  jmp alltraps
f0100afd:	e9 90 fd ff ff       	jmp    f0100892 <alltraps>

f0100b02 <vector67>:
.globl vector67
vector67:
  pushl $0
f0100b02:	6a 00                	push   $0x0
  pushl $67
f0100b04:	6a 43                	push   $0x43
  jmp alltraps
f0100b06:	e9 87 fd ff ff       	jmp    f0100892 <alltraps>

f0100b0b <vector68>:
.globl vector68
vector68:
  pushl $0
f0100b0b:	6a 00                	push   $0x0
  pushl $68
f0100b0d:	6a 44                	push   $0x44
  jmp alltraps
f0100b0f:	e9 7e fd ff ff       	jmp    f0100892 <alltraps>

f0100b14 <vector69>:
.globl vector69
vector69:
  pushl $0
f0100b14:	6a 00                	push   $0x0
  pushl $69
f0100b16:	6a 45                	push   $0x45
  jmp alltraps
f0100b18:	e9 75 fd ff ff       	jmp    f0100892 <alltraps>

f0100b1d <vector70>:
.globl vector70
vector70:
  pushl $0
f0100b1d:	6a 00                	push   $0x0
  pushl $70
f0100b1f:	6a 46                	push   $0x46
  jmp alltraps
f0100b21:	e9 6c fd ff ff       	jmp    f0100892 <alltraps>

f0100b26 <vector71>:
.globl vector71
vector71:
  pushl $0
f0100b26:	6a 00                	push   $0x0
  pushl $71
f0100b28:	6a 47                	push   $0x47
  jmp alltraps
f0100b2a:	e9 63 fd ff ff       	jmp    f0100892 <alltraps>

f0100b2f <vector72>:
.globl vector72
vector72:
  pushl $0
f0100b2f:	6a 00                	push   $0x0
  pushl $72
f0100b31:	6a 48                	push   $0x48
  jmp alltraps
f0100b33:	e9 5a fd ff ff       	jmp    f0100892 <alltraps>

f0100b38 <vector73>:
.globl vector73
vector73:
  pushl $0
f0100b38:	6a 00                	push   $0x0
  pushl $73
f0100b3a:	6a 49                	push   $0x49
  jmp alltraps
f0100b3c:	e9 51 fd ff ff       	jmp    f0100892 <alltraps>

f0100b41 <vector74>:
.globl vector74
vector74:
  pushl $0
f0100b41:	6a 00                	push   $0x0
  pushl $74
f0100b43:	6a 4a                	push   $0x4a
  jmp alltraps
f0100b45:	e9 48 fd ff ff       	jmp    f0100892 <alltraps>

f0100b4a <vector75>:
.globl vector75
vector75:
  pushl $0
f0100b4a:	6a 00                	push   $0x0
  pushl $75
f0100b4c:	6a 4b                	push   $0x4b
  jmp alltraps
f0100b4e:	e9 3f fd ff ff       	jmp    f0100892 <alltraps>

f0100b53 <vector76>:
.globl vector76
vector76:
  pushl $0
f0100b53:	6a 00                	push   $0x0
  pushl $76
f0100b55:	6a 4c                	push   $0x4c
  jmp alltraps
f0100b57:	e9 36 fd ff ff       	jmp    f0100892 <alltraps>

f0100b5c <vector77>:
.globl vector77
vector77:
  pushl $0
f0100b5c:	6a 00                	push   $0x0
  pushl $77
f0100b5e:	6a 4d                	push   $0x4d
  jmp alltraps
f0100b60:	e9 2d fd ff ff       	jmp    f0100892 <alltraps>

f0100b65 <vector78>:
.globl vector78
vector78:
  pushl $0
f0100b65:	6a 00                	push   $0x0
  pushl $78
f0100b67:	6a 4e                	push   $0x4e
  jmp alltraps
f0100b69:	e9 24 fd ff ff       	jmp    f0100892 <alltraps>

f0100b6e <vector79>:
.globl vector79
vector79:
  pushl $0
f0100b6e:	6a 00                	push   $0x0
  pushl $79
f0100b70:	6a 4f                	push   $0x4f
  jmp alltraps
f0100b72:	e9 1b fd ff ff       	jmp    f0100892 <alltraps>

f0100b77 <vector80>:
.globl vector80
vector80:
  pushl $0
f0100b77:	6a 00                	push   $0x0
  pushl $80
f0100b79:	6a 50                	push   $0x50
  jmp alltraps
f0100b7b:	e9 12 fd ff ff       	jmp    f0100892 <alltraps>

f0100b80 <vector81>:
.globl vector81
vector81:
  pushl $0
f0100b80:	6a 00                	push   $0x0
  pushl $81
f0100b82:	6a 51                	push   $0x51
  jmp alltraps
f0100b84:	e9 09 fd ff ff       	jmp    f0100892 <alltraps>

f0100b89 <vector82>:
.globl vector82
vector82:
  pushl $0
f0100b89:	6a 00                	push   $0x0
  pushl $82
f0100b8b:	6a 52                	push   $0x52
  jmp alltraps
f0100b8d:	e9 00 fd ff ff       	jmp    f0100892 <alltraps>

f0100b92 <vector83>:
.globl vector83
vector83:
  pushl $0
f0100b92:	6a 00                	push   $0x0
  pushl $83
f0100b94:	6a 53                	push   $0x53
  jmp alltraps
f0100b96:	e9 f7 fc ff ff       	jmp    f0100892 <alltraps>

f0100b9b <vector84>:
.globl vector84
vector84:
  pushl $0
f0100b9b:	6a 00                	push   $0x0
  pushl $84
f0100b9d:	6a 54                	push   $0x54
  jmp alltraps
f0100b9f:	e9 ee fc ff ff       	jmp    f0100892 <alltraps>

f0100ba4 <vector85>:
.globl vector85
vector85:
  pushl $0
f0100ba4:	6a 00                	push   $0x0
  pushl $85
f0100ba6:	6a 55                	push   $0x55
  jmp alltraps
f0100ba8:	e9 e5 fc ff ff       	jmp    f0100892 <alltraps>

f0100bad <vector86>:
.globl vector86
vector86:
  pushl $0
f0100bad:	6a 00                	push   $0x0
  pushl $86
f0100baf:	6a 56                	push   $0x56
  jmp alltraps
f0100bb1:	e9 dc fc ff ff       	jmp    f0100892 <alltraps>

f0100bb6 <vector87>:
.globl vector87
vector87:
  pushl $0
f0100bb6:	6a 00                	push   $0x0
  pushl $87
f0100bb8:	6a 57                	push   $0x57
  jmp alltraps
f0100bba:	e9 d3 fc ff ff       	jmp    f0100892 <alltraps>

f0100bbf <vector88>:
.globl vector88
vector88:
  pushl $0
f0100bbf:	6a 00                	push   $0x0
  pushl $88
f0100bc1:	6a 58                	push   $0x58
  jmp alltraps
f0100bc3:	e9 ca fc ff ff       	jmp    f0100892 <alltraps>

f0100bc8 <vector89>:
.globl vector89
vector89:
  pushl $0
f0100bc8:	6a 00                	push   $0x0
  pushl $89
f0100bca:	6a 59                	push   $0x59
  jmp alltraps
f0100bcc:	e9 c1 fc ff ff       	jmp    f0100892 <alltraps>

f0100bd1 <vector90>:
.globl vector90
vector90:
  pushl $0
f0100bd1:	6a 00                	push   $0x0
  pushl $90
f0100bd3:	6a 5a                	push   $0x5a
  jmp alltraps
f0100bd5:	e9 b8 fc ff ff       	jmp    f0100892 <alltraps>

f0100bda <vector91>:
.globl vector91
vector91:
  pushl $0
f0100bda:	6a 00                	push   $0x0
  pushl $91
f0100bdc:	6a 5b                	push   $0x5b
  jmp alltraps
f0100bde:	e9 af fc ff ff       	jmp    f0100892 <alltraps>

f0100be3 <vector92>:
.globl vector92
vector92:
  pushl $0
f0100be3:	6a 00                	push   $0x0
  pushl $92
f0100be5:	6a 5c                	push   $0x5c
  jmp alltraps
f0100be7:	e9 a6 fc ff ff       	jmp    f0100892 <alltraps>

f0100bec <vector93>:
.globl vector93
vector93:
  pushl $0
f0100bec:	6a 00                	push   $0x0
  pushl $93
f0100bee:	6a 5d                	push   $0x5d
  jmp alltraps
f0100bf0:	e9 9d fc ff ff       	jmp    f0100892 <alltraps>

f0100bf5 <vector94>:
.globl vector94
vector94:
  pushl $0
f0100bf5:	6a 00                	push   $0x0
  pushl $94
f0100bf7:	6a 5e                	push   $0x5e
  jmp alltraps
f0100bf9:	e9 94 fc ff ff       	jmp    f0100892 <alltraps>

f0100bfe <vector95>:
.globl vector95
vector95:
  pushl $0
f0100bfe:	6a 00                	push   $0x0
  pushl $95
f0100c00:	6a 5f                	push   $0x5f
  jmp alltraps
f0100c02:	e9 8b fc ff ff       	jmp    f0100892 <alltraps>

f0100c07 <vector96>:
.globl vector96
vector96:
  pushl $0
f0100c07:	6a 00                	push   $0x0
  pushl $96
f0100c09:	6a 60                	push   $0x60
  jmp alltraps
f0100c0b:	e9 82 fc ff ff       	jmp    f0100892 <alltraps>

f0100c10 <vector97>:
.globl vector97
vector97:
  pushl $0
f0100c10:	6a 00                	push   $0x0
  pushl $97
f0100c12:	6a 61                	push   $0x61
  jmp alltraps
f0100c14:	e9 79 fc ff ff       	jmp    f0100892 <alltraps>

f0100c19 <vector98>:
.globl vector98
vector98:
  pushl $0
f0100c19:	6a 00                	push   $0x0
  pushl $98
f0100c1b:	6a 62                	push   $0x62
  jmp alltraps
f0100c1d:	e9 70 fc ff ff       	jmp    f0100892 <alltraps>

f0100c22 <vector99>:
.globl vector99
vector99:
  pushl $0
f0100c22:	6a 00                	push   $0x0
  pushl $99
f0100c24:	6a 63                	push   $0x63
  jmp alltraps
f0100c26:	e9 67 fc ff ff       	jmp    f0100892 <alltraps>

f0100c2b <vector100>:
.globl vector100
vector100:
  pushl $0
f0100c2b:	6a 00                	push   $0x0
  pushl $100
f0100c2d:	6a 64                	push   $0x64
  jmp alltraps
f0100c2f:	e9 5e fc ff ff       	jmp    f0100892 <alltraps>

f0100c34 <vector101>:
.globl vector101
vector101:
  pushl $0
f0100c34:	6a 00                	push   $0x0
  pushl $101
f0100c36:	6a 65                	push   $0x65
  jmp alltraps
f0100c38:	e9 55 fc ff ff       	jmp    f0100892 <alltraps>

f0100c3d <vector102>:
.globl vector102
vector102:
  pushl $0
f0100c3d:	6a 00                	push   $0x0
  pushl $102
f0100c3f:	6a 66                	push   $0x66
  jmp alltraps
f0100c41:	e9 4c fc ff ff       	jmp    f0100892 <alltraps>

f0100c46 <vector103>:
.globl vector103
vector103:
  pushl $0
f0100c46:	6a 00                	push   $0x0
  pushl $103
f0100c48:	6a 67                	push   $0x67
  jmp alltraps
f0100c4a:	e9 43 fc ff ff       	jmp    f0100892 <alltraps>

f0100c4f <vector104>:
.globl vector104
vector104:
  pushl $0
f0100c4f:	6a 00                	push   $0x0
  pushl $104
f0100c51:	6a 68                	push   $0x68
  jmp alltraps
f0100c53:	e9 3a fc ff ff       	jmp    f0100892 <alltraps>

f0100c58 <vector105>:
.globl vector105
vector105:
  pushl $0
f0100c58:	6a 00                	push   $0x0
  pushl $105
f0100c5a:	6a 69                	push   $0x69
  jmp alltraps
f0100c5c:	e9 31 fc ff ff       	jmp    f0100892 <alltraps>

f0100c61 <vector106>:
.globl vector106
vector106:
  pushl $0
f0100c61:	6a 00                	push   $0x0
  pushl $106
f0100c63:	6a 6a                	push   $0x6a
  jmp alltraps
f0100c65:	e9 28 fc ff ff       	jmp    f0100892 <alltraps>

f0100c6a <vector107>:
.globl vector107
vector107:
  pushl $0
f0100c6a:	6a 00                	push   $0x0
  pushl $107
f0100c6c:	6a 6b                	push   $0x6b
  jmp alltraps
f0100c6e:	e9 1f fc ff ff       	jmp    f0100892 <alltraps>

f0100c73 <vector108>:
.globl vector108
vector108:
  pushl $0
f0100c73:	6a 00                	push   $0x0
  pushl $108
f0100c75:	6a 6c                	push   $0x6c
  jmp alltraps
f0100c77:	e9 16 fc ff ff       	jmp    f0100892 <alltraps>

f0100c7c <vector109>:
.globl vector109
vector109:
  pushl $0
f0100c7c:	6a 00                	push   $0x0
  pushl $109
f0100c7e:	6a 6d                	push   $0x6d
  jmp alltraps
f0100c80:	e9 0d fc ff ff       	jmp    f0100892 <alltraps>

f0100c85 <vector110>:
.globl vector110
vector110:
  pushl $0
f0100c85:	6a 00                	push   $0x0
  pushl $110
f0100c87:	6a 6e                	push   $0x6e
  jmp alltraps
f0100c89:	e9 04 fc ff ff       	jmp    f0100892 <alltraps>

f0100c8e <vector111>:
.globl vector111
vector111:
  pushl $0
f0100c8e:	6a 00                	push   $0x0
  pushl $111
f0100c90:	6a 6f                	push   $0x6f
  jmp alltraps
f0100c92:	e9 fb fb ff ff       	jmp    f0100892 <alltraps>

f0100c97 <vector112>:
.globl vector112
vector112:
  pushl $0
f0100c97:	6a 00                	push   $0x0
  pushl $112
f0100c99:	6a 70                	push   $0x70
  jmp alltraps
f0100c9b:	e9 f2 fb ff ff       	jmp    f0100892 <alltraps>

f0100ca0 <vector113>:
.globl vector113
vector113:
  pushl $0
f0100ca0:	6a 00                	push   $0x0
  pushl $113
f0100ca2:	6a 71                	push   $0x71
  jmp alltraps
f0100ca4:	e9 e9 fb ff ff       	jmp    f0100892 <alltraps>

f0100ca9 <vector114>:
.globl vector114
vector114:
  pushl $0
f0100ca9:	6a 00                	push   $0x0
  pushl $114
f0100cab:	6a 72                	push   $0x72
  jmp alltraps
f0100cad:	e9 e0 fb ff ff       	jmp    f0100892 <alltraps>

f0100cb2 <vector115>:
.globl vector115
vector115:
  pushl $0
f0100cb2:	6a 00                	push   $0x0
  pushl $115
f0100cb4:	6a 73                	push   $0x73
  jmp alltraps
f0100cb6:	e9 d7 fb ff ff       	jmp    f0100892 <alltraps>

f0100cbb <vector116>:
.globl vector116
vector116:
  pushl $0
f0100cbb:	6a 00                	push   $0x0
  pushl $116
f0100cbd:	6a 74                	push   $0x74
  jmp alltraps
f0100cbf:	e9 ce fb ff ff       	jmp    f0100892 <alltraps>

f0100cc4 <vector117>:
.globl vector117
vector117:
  pushl $0
f0100cc4:	6a 00                	push   $0x0
  pushl $117
f0100cc6:	6a 75                	push   $0x75
  jmp alltraps
f0100cc8:	e9 c5 fb ff ff       	jmp    f0100892 <alltraps>

f0100ccd <vector118>:
.globl vector118
vector118:
  pushl $0
f0100ccd:	6a 00                	push   $0x0
  pushl $118
f0100ccf:	6a 76                	push   $0x76
  jmp alltraps
f0100cd1:	e9 bc fb ff ff       	jmp    f0100892 <alltraps>

f0100cd6 <vector119>:
.globl vector119
vector119:
  pushl $0
f0100cd6:	6a 00                	push   $0x0
  pushl $119
f0100cd8:	6a 77                	push   $0x77
  jmp alltraps
f0100cda:	e9 b3 fb ff ff       	jmp    f0100892 <alltraps>

f0100cdf <vector120>:
.globl vector120
vector120:
  pushl $0
f0100cdf:	6a 00                	push   $0x0
  pushl $120
f0100ce1:	6a 78                	push   $0x78
  jmp alltraps
f0100ce3:	e9 aa fb ff ff       	jmp    f0100892 <alltraps>

f0100ce8 <vector121>:
.globl vector121
vector121:
  pushl $0
f0100ce8:	6a 00                	push   $0x0
  pushl $121
f0100cea:	6a 79                	push   $0x79
  jmp alltraps
f0100cec:	e9 a1 fb ff ff       	jmp    f0100892 <alltraps>

f0100cf1 <vector122>:
.globl vector122
vector122:
  pushl $0
f0100cf1:	6a 00                	push   $0x0
  pushl $122
f0100cf3:	6a 7a                	push   $0x7a
  jmp alltraps
f0100cf5:	e9 98 fb ff ff       	jmp    f0100892 <alltraps>

f0100cfa <vector123>:
.globl vector123
vector123:
  pushl $0
f0100cfa:	6a 00                	push   $0x0
  pushl $123
f0100cfc:	6a 7b                	push   $0x7b
  jmp alltraps
f0100cfe:	e9 8f fb ff ff       	jmp    f0100892 <alltraps>

f0100d03 <vector124>:
.globl vector124
vector124:
  pushl $0
f0100d03:	6a 00                	push   $0x0
  pushl $124
f0100d05:	6a 7c                	push   $0x7c
  jmp alltraps
f0100d07:	e9 86 fb ff ff       	jmp    f0100892 <alltraps>

f0100d0c <vector125>:
.globl vector125
vector125:
  pushl $0
f0100d0c:	6a 00                	push   $0x0
  pushl $125
f0100d0e:	6a 7d                	push   $0x7d
  jmp alltraps
f0100d10:	e9 7d fb ff ff       	jmp    f0100892 <alltraps>

f0100d15 <vector126>:
.globl vector126
vector126:
  pushl $0
f0100d15:	6a 00                	push   $0x0
  pushl $126
f0100d17:	6a 7e                	push   $0x7e
  jmp alltraps
f0100d19:	e9 74 fb ff ff       	jmp    f0100892 <alltraps>

f0100d1e <vector127>:
.globl vector127
vector127:
  pushl $0
f0100d1e:	6a 00                	push   $0x0
  pushl $127
f0100d20:	6a 7f                	push   $0x7f
  jmp alltraps
f0100d22:	e9 6b fb ff ff       	jmp    f0100892 <alltraps>

f0100d27 <vector128>:
.globl vector128
vector128:
  pushl $0
f0100d27:	6a 00                	push   $0x0
  pushl $128
f0100d29:	68 80 00 00 00       	push   $0x80
  jmp alltraps
f0100d2e:	e9 5f fb ff ff       	jmp    f0100892 <alltraps>

f0100d33 <vector129>:
.globl vector129
vector129:
  pushl $0
f0100d33:	6a 00                	push   $0x0
  pushl $129
f0100d35:	68 81 00 00 00       	push   $0x81
  jmp alltraps
f0100d3a:	e9 53 fb ff ff       	jmp    f0100892 <alltraps>

f0100d3f <vector130>:
.globl vector130
vector130:
  pushl $0
f0100d3f:	6a 00                	push   $0x0
  pushl $130
f0100d41:	68 82 00 00 00       	push   $0x82
  jmp alltraps
f0100d46:	e9 47 fb ff ff       	jmp    f0100892 <alltraps>

f0100d4b <vector131>:
.globl vector131
vector131:
  pushl $0
f0100d4b:	6a 00                	push   $0x0
  pushl $131
f0100d4d:	68 83 00 00 00       	push   $0x83
  jmp alltraps
f0100d52:	e9 3b fb ff ff       	jmp    f0100892 <alltraps>

f0100d57 <vector132>:
.globl vector132
vector132:
  pushl $0
f0100d57:	6a 00                	push   $0x0
  pushl $132
f0100d59:	68 84 00 00 00       	push   $0x84
  jmp alltraps
f0100d5e:	e9 2f fb ff ff       	jmp    f0100892 <alltraps>

f0100d63 <vector133>:
.globl vector133
vector133:
  pushl $0
f0100d63:	6a 00                	push   $0x0
  pushl $133
f0100d65:	68 85 00 00 00       	push   $0x85
  jmp alltraps
f0100d6a:	e9 23 fb ff ff       	jmp    f0100892 <alltraps>

f0100d6f <vector134>:
.globl vector134
vector134:
  pushl $0
f0100d6f:	6a 00                	push   $0x0
  pushl $134
f0100d71:	68 86 00 00 00       	push   $0x86
  jmp alltraps
f0100d76:	e9 17 fb ff ff       	jmp    f0100892 <alltraps>

f0100d7b <vector135>:
.globl vector135
vector135:
  pushl $0
f0100d7b:	6a 00                	push   $0x0
  pushl $135
f0100d7d:	68 87 00 00 00       	push   $0x87
  jmp alltraps
f0100d82:	e9 0b fb ff ff       	jmp    f0100892 <alltraps>

f0100d87 <vector136>:
.globl vector136
vector136:
  pushl $0
f0100d87:	6a 00                	push   $0x0
  pushl $136
f0100d89:	68 88 00 00 00       	push   $0x88
  jmp alltraps
f0100d8e:	e9 ff fa ff ff       	jmp    f0100892 <alltraps>

f0100d93 <vector137>:
.globl vector137
vector137:
  pushl $0
f0100d93:	6a 00                	push   $0x0
  pushl $137
f0100d95:	68 89 00 00 00       	push   $0x89
  jmp alltraps
f0100d9a:	e9 f3 fa ff ff       	jmp    f0100892 <alltraps>

f0100d9f <vector138>:
.globl vector138
vector138:
  pushl $0
f0100d9f:	6a 00                	push   $0x0
  pushl $138
f0100da1:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
f0100da6:	e9 e7 fa ff ff       	jmp    f0100892 <alltraps>

f0100dab <vector139>:
.globl vector139
vector139:
  pushl $0
f0100dab:	6a 00                	push   $0x0
  pushl $139
f0100dad:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
f0100db2:	e9 db fa ff ff       	jmp    f0100892 <alltraps>

f0100db7 <vector140>:
.globl vector140
vector140:
  pushl $0
f0100db7:	6a 00                	push   $0x0
  pushl $140
f0100db9:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
f0100dbe:	e9 cf fa ff ff       	jmp    f0100892 <alltraps>

f0100dc3 <vector141>:
.globl vector141
vector141:
  pushl $0
f0100dc3:	6a 00                	push   $0x0
  pushl $141
f0100dc5:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
f0100dca:	e9 c3 fa ff ff       	jmp    f0100892 <alltraps>

f0100dcf <vector142>:
.globl vector142
vector142:
  pushl $0
f0100dcf:	6a 00                	push   $0x0
  pushl $142
f0100dd1:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
f0100dd6:	e9 b7 fa ff ff       	jmp    f0100892 <alltraps>

f0100ddb <vector143>:
.globl vector143
vector143:
  pushl $0
f0100ddb:	6a 00                	push   $0x0
  pushl $143
f0100ddd:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
f0100de2:	e9 ab fa ff ff       	jmp    f0100892 <alltraps>

f0100de7 <vector144>:
.globl vector144
vector144:
  pushl $0
f0100de7:	6a 00                	push   $0x0
  pushl $144
f0100de9:	68 90 00 00 00       	push   $0x90
  jmp alltraps
f0100dee:	e9 9f fa ff ff       	jmp    f0100892 <alltraps>

f0100df3 <vector145>:
.globl vector145
vector145:
  pushl $0
f0100df3:	6a 00                	push   $0x0
  pushl $145
f0100df5:	68 91 00 00 00       	push   $0x91
  jmp alltraps
f0100dfa:	e9 93 fa ff ff       	jmp    f0100892 <alltraps>

f0100dff <vector146>:
.globl vector146
vector146:
  pushl $0
f0100dff:	6a 00                	push   $0x0
  pushl $146
f0100e01:	68 92 00 00 00       	push   $0x92
  jmp alltraps
f0100e06:	e9 87 fa ff ff       	jmp    f0100892 <alltraps>

f0100e0b <vector147>:
.globl vector147
vector147:
  pushl $0
f0100e0b:	6a 00                	push   $0x0
  pushl $147
f0100e0d:	68 93 00 00 00       	push   $0x93
  jmp alltraps
f0100e12:	e9 7b fa ff ff       	jmp    f0100892 <alltraps>

f0100e17 <vector148>:
.globl vector148
vector148:
  pushl $0
f0100e17:	6a 00                	push   $0x0
  pushl $148
f0100e19:	68 94 00 00 00       	push   $0x94
  jmp alltraps
f0100e1e:	e9 6f fa ff ff       	jmp    f0100892 <alltraps>

f0100e23 <vector149>:
.globl vector149
vector149:
  pushl $0
f0100e23:	6a 00                	push   $0x0
  pushl $149
f0100e25:	68 95 00 00 00       	push   $0x95
  jmp alltraps
f0100e2a:	e9 63 fa ff ff       	jmp    f0100892 <alltraps>

f0100e2f <vector150>:
.globl vector150
vector150:
  pushl $0
f0100e2f:	6a 00                	push   $0x0
  pushl $150
f0100e31:	68 96 00 00 00       	push   $0x96
  jmp alltraps
f0100e36:	e9 57 fa ff ff       	jmp    f0100892 <alltraps>

f0100e3b <vector151>:
.globl vector151
vector151:
  pushl $0
f0100e3b:	6a 00                	push   $0x0
  pushl $151
f0100e3d:	68 97 00 00 00       	push   $0x97
  jmp alltraps
f0100e42:	e9 4b fa ff ff       	jmp    f0100892 <alltraps>

f0100e47 <vector152>:
.globl vector152
vector152:
  pushl $0
f0100e47:	6a 00                	push   $0x0
  pushl $152
f0100e49:	68 98 00 00 00       	push   $0x98
  jmp alltraps
f0100e4e:	e9 3f fa ff ff       	jmp    f0100892 <alltraps>

f0100e53 <vector153>:
.globl vector153
vector153:
  pushl $0
f0100e53:	6a 00                	push   $0x0
  pushl $153
f0100e55:	68 99 00 00 00       	push   $0x99
  jmp alltraps
f0100e5a:	e9 33 fa ff ff       	jmp    f0100892 <alltraps>

f0100e5f <vector154>:
.globl vector154
vector154:
  pushl $0
f0100e5f:	6a 00                	push   $0x0
  pushl $154
f0100e61:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
f0100e66:	e9 27 fa ff ff       	jmp    f0100892 <alltraps>

f0100e6b <vector155>:
.globl vector155
vector155:
  pushl $0
f0100e6b:	6a 00                	push   $0x0
  pushl $155
f0100e6d:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
f0100e72:	e9 1b fa ff ff       	jmp    f0100892 <alltraps>

f0100e77 <vector156>:
.globl vector156
vector156:
  pushl $0
f0100e77:	6a 00                	push   $0x0
  pushl $156
f0100e79:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
f0100e7e:	e9 0f fa ff ff       	jmp    f0100892 <alltraps>

f0100e83 <vector157>:
.globl vector157
vector157:
  pushl $0
f0100e83:	6a 00                	push   $0x0
  pushl $157
f0100e85:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
f0100e8a:	e9 03 fa ff ff       	jmp    f0100892 <alltraps>

f0100e8f <vector158>:
.globl vector158
vector158:
  pushl $0
f0100e8f:	6a 00                	push   $0x0
  pushl $158
f0100e91:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
f0100e96:	e9 f7 f9 ff ff       	jmp    f0100892 <alltraps>

f0100e9b <vector159>:
.globl vector159
vector159:
  pushl $0
f0100e9b:	6a 00                	push   $0x0
  pushl $159
f0100e9d:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
f0100ea2:	e9 eb f9 ff ff       	jmp    f0100892 <alltraps>

f0100ea7 <vector160>:
.globl vector160
vector160:
  pushl $0
f0100ea7:	6a 00                	push   $0x0
  pushl $160
f0100ea9:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
f0100eae:	e9 df f9 ff ff       	jmp    f0100892 <alltraps>

f0100eb3 <vector161>:
.globl vector161
vector161:
  pushl $0
f0100eb3:	6a 00                	push   $0x0
  pushl $161
f0100eb5:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
f0100eba:	e9 d3 f9 ff ff       	jmp    f0100892 <alltraps>

f0100ebf <vector162>:
.globl vector162
vector162:
  pushl $0
f0100ebf:	6a 00                	push   $0x0
  pushl $162
f0100ec1:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
f0100ec6:	e9 c7 f9 ff ff       	jmp    f0100892 <alltraps>

f0100ecb <vector163>:
.globl vector163
vector163:
  pushl $0
f0100ecb:	6a 00                	push   $0x0
  pushl $163
f0100ecd:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
f0100ed2:	e9 bb f9 ff ff       	jmp    f0100892 <alltraps>

f0100ed7 <vector164>:
.globl vector164
vector164:
  pushl $0
f0100ed7:	6a 00                	push   $0x0
  pushl $164
f0100ed9:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
f0100ede:	e9 af f9 ff ff       	jmp    f0100892 <alltraps>

f0100ee3 <vector165>:
.globl vector165
vector165:
  pushl $0
f0100ee3:	6a 00                	push   $0x0
  pushl $165
f0100ee5:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
f0100eea:	e9 a3 f9 ff ff       	jmp    f0100892 <alltraps>

f0100eef <vector166>:
.globl vector166
vector166:
  pushl $0
f0100eef:	6a 00                	push   $0x0
  pushl $166
f0100ef1:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
f0100ef6:	e9 97 f9 ff ff       	jmp    f0100892 <alltraps>

f0100efb <vector167>:
.globl vector167
vector167:
  pushl $0
f0100efb:	6a 00                	push   $0x0
  pushl $167
f0100efd:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
f0100f02:	e9 8b f9 ff ff       	jmp    f0100892 <alltraps>

f0100f07 <vector168>:
.globl vector168
vector168:
  pushl $0
f0100f07:	6a 00                	push   $0x0
  pushl $168
f0100f09:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
f0100f0e:	e9 7f f9 ff ff       	jmp    f0100892 <alltraps>

f0100f13 <vector169>:
.globl vector169
vector169:
  pushl $0
f0100f13:	6a 00                	push   $0x0
  pushl $169
f0100f15:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
f0100f1a:	e9 73 f9 ff ff       	jmp    f0100892 <alltraps>

f0100f1f <vector170>:
.globl vector170
vector170:
  pushl $0
f0100f1f:	6a 00                	push   $0x0
  pushl $170
f0100f21:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
f0100f26:	e9 67 f9 ff ff       	jmp    f0100892 <alltraps>

f0100f2b <vector171>:
.globl vector171
vector171:
  pushl $0
f0100f2b:	6a 00                	push   $0x0
  pushl $171
f0100f2d:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
f0100f32:	e9 5b f9 ff ff       	jmp    f0100892 <alltraps>

f0100f37 <vector172>:
.globl vector172
vector172:
  pushl $0
f0100f37:	6a 00                	push   $0x0
  pushl $172
f0100f39:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
f0100f3e:	e9 4f f9 ff ff       	jmp    f0100892 <alltraps>

f0100f43 <vector173>:
.globl vector173
vector173:
  pushl $0
f0100f43:	6a 00                	push   $0x0
  pushl $173
f0100f45:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
f0100f4a:	e9 43 f9 ff ff       	jmp    f0100892 <alltraps>

f0100f4f <vector174>:
.globl vector174
vector174:
  pushl $0
f0100f4f:	6a 00                	push   $0x0
  pushl $174
f0100f51:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
f0100f56:	e9 37 f9 ff ff       	jmp    f0100892 <alltraps>

f0100f5b <vector175>:
.globl vector175
vector175:
  pushl $0
f0100f5b:	6a 00                	push   $0x0
  pushl $175
f0100f5d:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
f0100f62:	e9 2b f9 ff ff       	jmp    f0100892 <alltraps>

f0100f67 <vector176>:
.globl vector176
vector176:
  pushl $0
f0100f67:	6a 00                	push   $0x0
  pushl $176
f0100f69:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
f0100f6e:	e9 1f f9 ff ff       	jmp    f0100892 <alltraps>

f0100f73 <vector177>:
.globl vector177
vector177:
  pushl $0
f0100f73:	6a 00                	push   $0x0
  pushl $177
f0100f75:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
f0100f7a:	e9 13 f9 ff ff       	jmp    f0100892 <alltraps>

f0100f7f <vector178>:
.globl vector178
vector178:
  pushl $0
f0100f7f:	6a 00                	push   $0x0
  pushl $178
f0100f81:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
f0100f86:	e9 07 f9 ff ff       	jmp    f0100892 <alltraps>

f0100f8b <vector179>:
.globl vector179
vector179:
  pushl $0
f0100f8b:	6a 00                	push   $0x0
  pushl $179
f0100f8d:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
f0100f92:	e9 fb f8 ff ff       	jmp    f0100892 <alltraps>

f0100f97 <vector180>:
.globl vector180
vector180:
  pushl $0
f0100f97:	6a 00                	push   $0x0
  pushl $180
f0100f99:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
f0100f9e:	e9 ef f8 ff ff       	jmp    f0100892 <alltraps>

f0100fa3 <vector181>:
.globl vector181
vector181:
  pushl $0
f0100fa3:	6a 00                	push   $0x0
  pushl $181
f0100fa5:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
f0100faa:	e9 e3 f8 ff ff       	jmp    f0100892 <alltraps>

f0100faf <vector182>:
.globl vector182
vector182:
  pushl $0
f0100faf:	6a 00                	push   $0x0
  pushl $182
f0100fb1:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
f0100fb6:	e9 d7 f8 ff ff       	jmp    f0100892 <alltraps>

f0100fbb <vector183>:
.globl vector183
vector183:
  pushl $0
f0100fbb:	6a 00                	push   $0x0
  pushl $183
f0100fbd:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
f0100fc2:	e9 cb f8 ff ff       	jmp    f0100892 <alltraps>

f0100fc7 <vector184>:
.globl vector184
vector184:
  pushl $0
f0100fc7:	6a 00                	push   $0x0
  pushl $184
f0100fc9:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
f0100fce:	e9 bf f8 ff ff       	jmp    f0100892 <alltraps>

f0100fd3 <vector185>:
.globl vector185
vector185:
  pushl $0
f0100fd3:	6a 00                	push   $0x0
  pushl $185
f0100fd5:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
f0100fda:	e9 b3 f8 ff ff       	jmp    f0100892 <alltraps>

f0100fdf <vector186>:
.globl vector186
vector186:
  pushl $0
f0100fdf:	6a 00                	push   $0x0
  pushl $186
f0100fe1:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
f0100fe6:	e9 a7 f8 ff ff       	jmp    f0100892 <alltraps>

f0100feb <vector187>:
.globl vector187
vector187:
  pushl $0
f0100feb:	6a 00                	push   $0x0
  pushl $187
f0100fed:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
f0100ff2:	e9 9b f8 ff ff       	jmp    f0100892 <alltraps>

f0100ff7 <vector188>:
.globl vector188
vector188:
  pushl $0
f0100ff7:	6a 00                	push   $0x0
  pushl $188
f0100ff9:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
f0100ffe:	e9 8f f8 ff ff       	jmp    f0100892 <alltraps>

f0101003 <vector189>:
.globl vector189
vector189:
  pushl $0
f0101003:	6a 00                	push   $0x0
  pushl $189
f0101005:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
f010100a:	e9 83 f8 ff ff       	jmp    f0100892 <alltraps>

f010100f <vector190>:
.globl vector190
vector190:
  pushl $0
f010100f:	6a 00                	push   $0x0
  pushl $190
f0101011:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
f0101016:	e9 77 f8 ff ff       	jmp    f0100892 <alltraps>

f010101b <vector191>:
.globl vector191
vector191:
  pushl $0
f010101b:	6a 00                	push   $0x0
  pushl $191
f010101d:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
f0101022:	e9 6b f8 ff ff       	jmp    f0100892 <alltraps>

f0101027 <vector192>:
.globl vector192
vector192:
  pushl $0
f0101027:	6a 00                	push   $0x0
  pushl $192
f0101029:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
f010102e:	e9 5f f8 ff ff       	jmp    f0100892 <alltraps>

f0101033 <vector193>:
.globl vector193
vector193:
  pushl $0
f0101033:	6a 00                	push   $0x0
  pushl $193
f0101035:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
f010103a:	e9 53 f8 ff ff       	jmp    f0100892 <alltraps>

f010103f <vector194>:
.globl vector194
vector194:
  pushl $0
f010103f:	6a 00                	push   $0x0
  pushl $194
f0101041:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
f0101046:	e9 47 f8 ff ff       	jmp    f0100892 <alltraps>

f010104b <vector195>:
.globl vector195
vector195:
  pushl $0
f010104b:	6a 00                	push   $0x0
  pushl $195
f010104d:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
f0101052:	e9 3b f8 ff ff       	jmp    f0100892 <alltraps>

f0101057 <vector196>:
.globl vector196
vector196:
  pushl $0
f0101057:	6a 00                	push   $0x0
  pushl $196
f0101059:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
f010105e:	e9 2f f8 ff ff       	jmp    f0100892 <alltraps>

f0101063 <vector197>:
.globl vector197
vector197:
  pushl $0
f0101063:	6a 00                	push   $0x0
  pushl $197
f0101065:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
f010106a:	e9 23 f8 ff ff       	jmp    f0100892 <alltraps>

f010106f <vector198>:
.globl vector198
vector198:
  pushl $0
f010106f:	6a 00                	push   $0x0
  pushl $198
f0101071:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
f0101076:	e9 17 f8 ff ff       	jmp    f0100892 <alltraps>

f010107b <vector199>:
.globl vector199
vector199:
  pushl $0
f010107b:	6a 00                	push   $0x0
  pushl $199
f010107d:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
f0101082:	e9 0b f8 ff ff       	jmp    f0100892 <alltraps>

f0101087 <vector200>:
.globl vector200
vector200:
  pushl $0
f0101087:	6a 00                	push   $0x0
  pushl $200
f0101089:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
f010108e:	e9 ff f7 ff ff       	jmp    f0100892 <alltraps>

f0101093 <vector201>:
.globl vector201
vector201:
  pushl $0
f0101093:	6a 00                	push   $0x0
  pushl $201
f0101095:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
f010109a:	e9 f3 f7 ff ff       	jmp    f0100892 <alltraps>

f010109f <vector202>:
.globl vector202
vector202:
  pushl $0
f010109f:	6a 00                	push   $0x0
  pushl $202
f01010a1:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
f01010a6:	e9 e7 f7 ff ff       	jmp    f0100892 <alltraps>

f01010ab <vector203>:
.globl vector203
vector203:
  pushl $0
f01010ab:	6a 00                	push   $0x0
  pushl $203
f01010ad:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
f01010b2:	e9 db f7 ff ff       	jmp    f0100892 <alltraps>

f01010b7 <vector204>:
.globl vector204
vector204:
  pushl $0
f01010b7:	6a 00                	push   $0x0
  pushl $204
f01010b9:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
f01010be:	e9 cf f7 ff ff       	jmp    f0100892 <alltraps>

f01010c3 <vector205>:
.globl vector205
vector205:
  pushl $0
f01010c3:	6a 00                	push   $0x0
  pushl $205
f01010c5:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
f01010ca:	e9 c3 f7 ff ff       	jmp    f0100892 <alltraps>

f01010cf <vector206>:
.globl vector206
vector206:
  pushl $0
f01010cf:	6a 00                	push   $0x0
  pushl $206
f01010d1:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
f01010d6:	e9 b7 f7 ff ff       	jmp    f0100892 <alltraps>

f01010db <vector207>:
.globl vector207
vector207:
  pushl $0
f01010db:	6a 00                	push   $0x0
  pushl $207
f01010dd:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
f01010e2:	e9 ab f7 ff ff       	jmp    f0100892 <alltraps>

f01010e7 <vector208>:
.globl vector208
vector208:
  pushl $0
f01010e7:	6a 00                	push   $0x0
  pushl $208
f01010e9:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
f01010ee:	e9 9f f7 ff ff       	jmp    f0100892 <alltraps>

f01010f3 <vector209>:
.globl vector209
vector209:
  pushl $0
f01010f3:	6a 00                	push   $0x0
  pushl $209
f01010f5:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
f01010fa:	e9 93 f7 ff ff       	jmp    f0100892 <alltraps>

f01010ff <vector210>:
.globl vector210
vector210:
  pushl $0
f01010ff:	6a 00                	push   $0x0
  pushl $210
f0101101:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
f0101106:	e9 87 f7 ff ff       	jmp    f0100892 <alltraps>

f010110b <vector211>:
.globl vector211
vector211:
  pushl $0
f010110b:	6a 00                	push   $0x0
  pushl $211
f010110d:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
f0101112:	e9 7b f7 ff ff       	jmp    f0100892 <alltraps>

f0101117 <vector212>:
.globl vector212
vector212:
  pushl $0
f0101117:	6a 00                	push   $0x0
  pushl $212
f0101119:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
f010111e:	e9 6f f7 ff ff       	jmp    f0100892 <alltraps>

f0101123 <vector213>:
.globl vector213
vector213:
  pushl $0
f0101123:	6a 00                	push   $0x0
  pushl $213
f0101125:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
f010112a:	e9 63 f7 ff ff       	jmp    f0100892 <alltraps>

f010112f <vector214>:
.globl vector214
vector214:
  pushl $0
f010112f:	6a 00                	push   $0x0
  pushl $214
f0101131:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
f0101136:	e9 57 f7 ff ff       	jmp    f0100892 <alltraps>

f010113b <vector215>:
.globl vector215
vector215:
  pushl $0
f010113b:	6a 00                	push   $0x0
  pushl $215
f010113d:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
f0101142:	e9 4b f7 ff ff       	jmp    f0100892 <alltraps>

f0101147 <vector216>:
.globl vector216
vector216:
  pushl $0
f0101147:	6a 00                	push   $0x0
  pushl $216
f0101149:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
f010114e:	e9 3f f7 ff ff       	jmp    f0100892 <alltraps>

f0101153 <vector217>:
.globl vector217
vector217:
  pushl $0
f0101153:	6a 00                	push   $0x0
  pushl $217
f0101155:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
f010115a:	e9 33 f7 ff ff       	jmp    f0100892 <alltraps>

f010115f <vector218>:
.globl vector218
vector218:
  pushl $0
f010115f:	6a 00                	push   $0x0
  pushl $218
f0101161:	68 da 00 00 00       	push   $0xda
  jmp alltraps
f0101166:	e9 27 f7 ff ff       	jmp    f0100892 <alltraps>

f010116b <vector219>:
.globl vector219
vector219:
  pushl $0
f010116b:	6a 00                	push   $0x0
  pushl $219
f010116d:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
f0101172:	e9 1b f7 ff ff       	jmp    f0100892 <alltraps>

f0101177 <vector220>:
.globl vector220
vector220:
  pushl $0
f0101177:	6a 00                	push   $0x0
  pushl $220
f0101179:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
f010117e:	e9 0f f7 ff ff       	jmp    f0100892 <alltraps>

f0101183 <vector221>:
.globl vector221
vector221:
  pushl $0
f0101183:	6a 00                	push   $0x0
  pushl $221
f0101185:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
f010118a:	e9 03 f7 ff ff       	jmp    f0100892 <alltraps>

f010118f <vector222>:
.globl vector222
vector222:
  pushl $0
f010118f:	6a 00                	push   $0x0
  pushl $222
f0101191:	68 de 00 00 00       	push   $0xde
  jmp alltraps
f0101196:	e9 f7 f6 ff ff       	jmp    f0100892 <alltraps>

f010119b <vector223>:
.globl vector223
vector223:
  pushl $0
f010119b:	6a 00                	push   $0x0
  pushl $223
f010119d:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
f01011a2:	e9 eb f6 ff ff       	jmp    f0100892 <alltraps>

f01011a7 <vector224>:
.globl vector224
vector224:
  pushl $0
f01011a7:	6a 00                	push   $0x0
  pushl $224
f01011a9:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
f01011ae:	e9 df f6 ff ff       	jmp    f0100892 <alltraps>

f01011b3 <vector225>:
.globl vector225
vector225:
  pushl $0
f01011b3:	6a 00                	push   $0x0
  pushl $225
f01011b5:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
f01011ba:	e9 d3 f6 ff ff       	jmp    f0100892 <alltraps>

f01011bf <vector226>:
.globl vector226
vector226:
  pushl $0
f01011bf:	6a 00                	push   $0x0
  pushl $226
f01011c1:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
f01011c6:	e9 c7 f6 ff ff       	jmp    f0100892 <alltraps>

f01011cb <vector227>:
.globl vector227
vector227:
  pushl $0
f01011cb:	6a 00                	push   $0x0
  pushl $227
f01011cd:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
f01011d2:	e9 bb f6 ff ff       	jmp    f0100892 <alltraps>

f01011d7 <vector228>:
.globl vector228
vector228:
  pushl $0
f01011d7:	6a 00                	push   $0x0
  pushl $228
f01011d9:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
f01011de:	e9 af f6 ff ff       	jmp    f0100892 <alltraps>

f01011e3 <vector229>:
.globl vector229
vector229:
  pushl $0
f01011e3:	6a 00                	push   $0x0
  pushl $229
f01011e5:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
f01011ea:	e9 a3 f6 ff ff       	jmp    f0100892 <alltraps>

f01011ef <vector230>:
.globl vector230
vector230:
  pushl $0
f01011ef:	6a 00                	push   $0x0
  pushl $230
f01011f1:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
f01011f6:	e9 97 f6 ff ff       	jmp    f0100892 <alltraps>

f01011fb <vector231>:
.globl vector231
vector231:
  pushl $0
f01011fb:	6a 00                	push   $0x0
  pushl $231
f01011fd:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
f0101202:	e9 8b f6 ff ff       	jmp    f0100892 <alltraps>

f0101207 <vector232>:
.globl vector232
vector232:
  pushl $0
f0101207:	6a 00                	push   $0x0
  pushl $232
f0101209:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
f010120e:	e9 7f f6 ff ff       	jmp    f0100892 <alltraps>

f0101213 <vector233>:
.globl vector233
vector233:
  pushl $0
f0101213:	6a 00                	push   $0x0
  pushl $233
f0101215:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
f010121a:	e9 73 f6 ff ff       	jmp    f0100892 <alltraps>

f010121f <vector234>:
.globl vector234
vector234:
  pushl $0
f010121f:	6a 00                	push   $0x0
  pushl $234
f0101221:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
f0101226:	e9 67 f6 ff ff       	jmp    f0100892 <alltraps>

f010122b <vector235>:
.globl vector235
vector235:
  pushl $0
f010122b:	6a 00                	push   $0x0
  pushl $235
f010122d:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
f0101232:	e9 5b f6 ff ff       	jmp    f0100892 <alltraps>

f0101237 <vector236>:
.globl vector236
vector236:
  pushl $0
f0101237:	6a 00                	push   $0x0
  pushl $236
f0101239:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
f010123e:	e9 4f f6 ff ff       	jmp    f0100892 <alltraps>

f0101243 <vector237>:
.globl vector237
vector237:
  pushl $0
f0101243:	6a 00                	push   $0x0
  pushl $237
f0101245:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
f010124a:	e9 43 f6 ff ff       	jmp    f0100892 <alltraps>

f010124f <vector238>:
.globl vector238
vector238:
  pushl $0
f010124f:	6a 00                	push   $0x0
  pushl $238
f0101251:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
f0101256:	e9 37 f6 ff ff       	jmp    f0100892 <alltraps>

f010125b <vector239>:
.globl vector239
vector239:
  pushl $0
f010125b:	6a 00                	push   $0x0
  pushl $239
f010125d:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
f0101262:	e9 2b f6 ff ff       	jmp    f0100892 <alltraps>

f0101267 <vector240>:
.globl vector240
vector240:
  pushl $0
f0101267:	6a 00                	push   $0x0
  pushl $240
f0101269:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
f010126e:	e9 1f f6 ff ff       	jmp    f0100892 <alltraps>

f0101273 <vector241>:
.globl vector241
vector241:
  pushl $0
f0101273:	6a 00                	push   $0x0
  pushl $241
f0101275:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
f010127a:	e9 13 f6 ff ff       	jmp    f0100892 <alltraps>

f010127f <vector242>:
.globl vector242
vector242:
  pushl $0
f010127f:	6a 00                	push   $0x0
  pushl $242
f0101281:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
f0101286:	e9 07 f6 ff ff       	jmp    f0100892 <alltraps>

f010128b <vector243>:
.globl vector243
vector243:
  pushl $0
f010128b:	6a 00                	push   $0x0
  pushl $243
f010128d:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
f0101292:	e9 fb f5 ff ff       	jmp    f0100892 <alltraps>

f0101297 <vector244>:
.globl vector244
vector244:
  pushl $0
f0101297:	6a 00                	push   $0x0
  pushl $244
f0101299:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
f010129e:	e9 ef f5 ff ff       	jmp    f0100892 <alltraps>

f01012a3 <vector245>:
.globl vector245
vector245:
  pushl $0
f01012a3:	6a 00                	push   $0x0
  pushl $245
f01012a5:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
f01012aa:	e9 e3 f5 ff ff       	jmp    f0100892 <alltraps>

f01012af <vector246>:
.globl vector246
vector246:
  pushl $0
f01012af:	6a 00                	push   $0x0
  pushl $246
f01012b1:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
f01012b6:	e9 d7 f5 ff ff       	jmp    f0100892 <alltraps>

f01012bb <vector247>:
.globl vector247
vector247:
  pushl $0
f01012bb:	6a 00                	push   $0x0
  pushl $247
f01012bd:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
f01012c2:	e9 cb f5 ff ff       	jmp    f0100892 <alltraps>

f01012c7 <vector248>:
.globl vector248
vector248:
  pushl $0
f01012c7:	6a 00                	push   $0x0
  pushl $248
f01012c9:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
f01012ce:	e9 bf f5 ff ff       	jmp    f0100892 <alltraps>

f01012d3 <vector249>:
.globl vector249
vector249:
  pushl $0
f01012d3:	6a 00                	push   $0x0
  pushl $249
f01012d5:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
f01012da:	e9 b3 f5 ff ff       	jmp    f0100892 <alltraps>

f01012df <vector250>:
.globl vector250
vector250:
  pushl $0
f01012df:	6a 00                	push   $0x0
  pushl $250
f01012e1:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
f01012e6:	e9 a7 f5 ff ff       	jmp    f0100892 <alltraps>

f01012eb <vector251>:
.globl vector251
vector251:
  pushl $0
f01012eb:	6a 00                	push   $0x0
  pushl $251
f01012ed:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
f01012f2:	e9 9b f5 ff ff       	jmp    f0100892 <alltraps>

f01012f7 <vector252>:
.globl vector252
vector252:
  pushl $0
f01012f7:	6a 00                	push   $0x0
  pushl $252
f01012f9:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
f01012fe:	e9 8f f5 ff ff       	jmp    f0100892 <alltraps>

f0101303 <vector253>:
.globl vector253
vector253:
  pushl $0
f0101303:	6a 00                	push   $0x0
  pushl $253
f0101305:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
f010130a:	e9 83 f5 ff ff       	jmp    f0100892 <alltraps>

f010130f <vector254>:
.globl vector254
vector254:
  pushl $0
f010130f:	6a 00                	push   $0x0
  pushl $254
f0101311:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
f0101316:	e9 77 f5 ff ff       	jmp    f0100892 <alltraps>

f010131b <vector255>:
.globl vector255
vector255:
  pushl $0
f010131b:	6a 00                	push   $0x0
  pushl $255
f010131d:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
f0101322:	e9 6b f5 ff ff       	jmp    f0100892 <alltraps>

f0101327 <seg_init>:
// GDT.
struct segdesc gdt[NSEGS];

void
seg_init(void)
{
f0101327:	55                   	push   %ebp
f0101328:	89 e5                	mov    %esp,%ebp
f010132a:	83 ec 18             	sub    $0x18,%esp
	// Cannot share a CODE descriptor for both kernel and user
	// because it would have to have DPL_USR, but the CPU forbids
	// an interrupt from CPL=0 to DPL=3.
	// Your code here.
	//
	thiscpu->gdt[SEG_KCODE] = SEG(STA_R | STA_X, 0, 0xffffffff, 0);
f010132d:	e8 3e 13 00 00       	call   f0102670 <cpunum>
f0101332:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f0101338:	8d 90 20 40 12 f0    	lea    -0xfedbfe0(%eax),%edx
f010133e:	66 c7 80 9c 40 12 f0 	movw   $0xffff,-0xfedbf64(%eax)
f0101345:	ff ff 
f0101347:	66 c7 80 9e 40 12 f0 	movw   $0x0,-0xfedbf62(%eax)
f010134e:	00 00 
f0101350:	c6 80 a0 40 12 f0 00 	movb   $0x0,-0xfedbf60(%eax)
f0101357:	c6 80 a1 40 12 f0 9a 	movb   $0x9a,-0xfedbf5f(%eax)
f010135e:	c6 80 a2 40 12 f0 cf 	movb   $0xcf,-0xfedbf5e(%eax)
f0101365:	c6 82 83 00 00 00 00 	movb   $0x0,0x83(%edx)
	thiscpu->gdt[SEG_KDATA] = SEG(STA_W | STA_R, 0, 0xffffffff, 0);
f010136c:	e8 ff 12 00 00       	call   f0102670 <cpunum>
f0101371:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f0101377:	8d 90 20 40 12 f0    	lea    -0xfedbfe0(%eax),%edx
f010137d:	66 c7 80 a4 40 12 f0 	movw   $0xffff,-0xfedbf5c(%eax)
f0101384:	ff ff 
f0101386:	66 c7 80 a6 40 12 f0 	movw   $0x0,-0xfedbf5a(%eax)
f010138d:	00 00 
f010138f:	c6 80 a8 40 12 f0 00 	movb   $0x0,-0xfedbf58(%eax)
f0101396:	c6 80 a9 40 12 f0 92 	movb   $0x92,-0xfedbf57(%eax)
f010139d:	c6 80 aa 40 12 f0 cf 	movb   $0xcf,-0xfedbf56(%eax)
f01013a4:	c6 82 8b 00 00 00 00 	movb   $0x0,0x8b(%edx)
	thiscpu->gdt[SEG_UCODE] = SEG(STA_R | STA_X, 0, 0xffffffff, DPL_USER);
f01013ab:	e8 c0 12 00 00       	call   f0102670 <cpunum>
f01013b0:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f01013b6:	8d 90 20 40 12 f0    	lea    -0xfedbfe0(%eax),%edx
f01013bc:	66 c7 80 ac 40 12 f0 	movw   $0xffff,-0xfedbf54(%eax)
f01013c3:	ff ff 
f01013c5:	66 c7 80 ae 40 12 f0 	movw   $0x0,-0xfedbf52(%eax)
f01013cc:	00 00 
f01013ce:	c6 80 b0 40 12 f0 00 	movb   $0x0,-0xfedbf50(%eax)
f01013d5:	c6 80 b1 40 12 f0 fa 	movb   $0xfa,-0xfedbf4f(%eax)
f01013dc:	c6 80 b2 40 12 f0 cf 	movb   $0xcf,-0xfedbf4e(%eax)
f01013e3:	c6 82 93 00 00 00 00 	movb   $0x0,0x93(%edx)
	thiscpu->gdt[SEG_UDATA] = SEG(STA_R | STA_W, 0, 0xffffffff, DPL_USER);
f01013ea:	e8 81 12 00 00       	call   f0102670 <cpunum>
f01013ef:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f01013f5:	8d 90 20 40 12 f0    	lea    -0xfedbfe0(%eax),%edx
f01013fb:	66 c7 80 b4 40 12 f0 	movw   $0xffff,-0xfedbf4c(%eax)
f0101402:	ff ff 
f0101404:	66 c7 80 b6 40 12 f0 	movw   $0x0,-0xfedbf4a(%eax)
f010140b:	00 00 
f010140d:	c6 80 b8 40 12 f0 00 	movb   $0x0,-0xfedbf48(%eax)
f0101414:	c6 80 b9 40 12 f0 f2 	movb   $0xf2,-0xfedbf47(%eax)
f010141b:	c6 80 ba 40 12 f0 cf 	movb   $0xcf,-0xfedbf46(%eax)
f0101422:	c6 82 9b 00 00 00 00 	movb   $0x0,0x9b(%edx)
	lgdt(thiscpu->gdt, sizeof(thiscpu->gdt));
f0101429:	e8 42 12 00 00       	call   f0102670 <cpunum>
f010142e:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f0101434:	05 94 40 12 f0       	add    $0xf0124094,%eax
	pd[0] = size-1;
f0101439:	66 c7 45 f2 2f 00    	movw   $0x2f,-0xe(%ebp)
	pd[1] = (unsigned)p;
f010143f:	66 89 45 f4          	mov    %ax,-0xc(%ebp)
	pd[2] = (unsigned)p >> 16;
f0101443:	c1 e8 10             	shr    $0x10,%eax
f0101446:	66 89 45 f6          	mov    %ax,-0xa(%ebp)
	asm volatile("lgdt (%0)" : : "r" (pd));
f010144a:	8d 45 f2             	lea    -0xe(%ebp),%eax
f010144d:	0f 01 10             	lgdtl  (%eax)
	// user code, user data;
	// 2. The various segment selectors, application segment type bits and
	// User DPL have been defined in inc/mmu.h;
	// 3. You may need macro SEG() to set up segments;
	// 4. We have implememted the C function lgdt() in inc/x86.h;
}
f0101450:	c9                   	leave  
f0101451:	c3                   	ret    

f0101452 <pgdir_walk>:
// Hint 2: look at inc/mmu.h for useful macros that manipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int32_t alloc)
{
f0101452:	55                   	push   %ebp
f0101453:	89 e5                	mov    %esp,%ebp
f0101455:	57                   	push   %edi
f0101456:	56                   	push   %esi
f0101457:	53                   	push   %ebx
f0101458:	83 ec 0c             	sub    $0xc,%esp
f010145b:	8b 75 0c             	mov    0xc(%ebp),%esi
	// TODO: Fill this function in
	pde_t *pde = &pgdir[PDX(va)];
f010145e:	89 f7                	mov    %esi,%edi
f0101460:	c1 ef 16             	shr    $0x16,%edi
f0101463:	c1 e7 02             	shl    $0x2,%edi
f0101466:	03 7d 08             	add    0x8(%ebp),%edi
	pte_t *pgtab;
	if ((*pde & PTE_P) == 1)
f0101469:	8b 1f                	mov    (%edi),%ebx
f010146b:	f6 c3 01             	test   $0x1,%bl
f010146e:	74 21                	je     f0101491 <pgdir_walk+0x3f>
	    pgtab = (pte_t *)P2V(PTE_ADDR(*pde));
f0101470:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
f0101476:	81 eb 00 00 00 10    	sub    $0x10000000,%ebx
	    if (alloc == 0 || (pgtab = (pte_t *)kalloc()) == NULL)
	        return NULL;
	    memset(pgtab, 0, PGSIZE);
        *pde = V2P(pgtab) | PTE_P | PTE_U | PTE_W;
	}
	return &pgtab[PTX(va)];
f010147c:	c1 ee 0a             	shr    $0xa,%esi
f010147f:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f0101485:	01 f3                	add    %esi,%ebx
}
f0101487:	89 d8                	mov    %ebx,%eax
f0101489:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010148c:	5b                   	pop    %ebx
f010148d:	5e                   	pop    %esi
f010148e:	5f                   	pop    %edi
f010148f:	5d                   	pop    %ebp
f0101490:	c3                   	ret    
	    if (alloc == 0 || (pgtab = (pte_t *)kalloc()) == NULL)
f0101491:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101495:	74 2b                	je     f01014c2 <pgdir_walk+0x70>
f0101497:	e8 8f 0b 00 00       	call   f010202b <kalloc>
f010149c:	89 c3                	mov    %eax,%ebx
f010149e:	85 c0                	test   %eax,%eax
f01014a0:	74 e5                	je     f0101487 <pgdir_walk+0x35>
	    memset(pgtab, 0, PGSIZE);
f01014a2:	83 ec 04             	sub    $0x4,%esp
f01014a5:	68 00 10 00 00       	push   $0x1000
f01014aa:	6a 00                	push   $0x0
f01014ac:	50                   	push   %eax
f01014ad:	e8 f9 22 00 00       	call   f01037ab <memset>
        *pde = V2P(pgtab) | PTE_P | PTE_U | PTE_W;
f01014b2:	8d 83 00 00 00 10    	lea    0x10000000(%ebx),%eax
f01014b8:	83 c8 07             	or     $0x7,%eax
f01014bb:	89 07                	mov    %eax,(%edi)
f01014bd:	83 c4 10             	add    $0x10,%esp
f01014c0:	eb ba                	jmp    f010147c <pgdir_walk+0x2a>
	        return NULL;
f01014c2:	bb 00 00 00 00       	mov    $0x0,%ebx
f01014c7:	eb be                	jmp    f0101487 <pgdir_walk+0x35>

f01014c9 <map_region>:
// Use permission bits perm|PTE_P for the entries.
//
// Hint: the TA solution uses pgdir_walk
static int // What to return?
map_region(pde_t *pgdir, void *va, uint32_t size, uint32_t pa, int32_t perm)
{
f01014c9:	55                   	push   %ebp
f01014ca:	89 e5                	mov    %esp,%ebp
f01014cc:	57                   	push   %edi
f01014cd:	56                   	push   %esi
f01014ce:	53                   	push   %ebx
f01014cf:	83 ec 1c             	sub    $0x1c,%esp
f01014d2:	89 c7                	mov    %eax,%edi
f01014d4:	8b 45 08             	mov    0x8(%ebp),%eax
	// TODO: Fill this function in
	char *align = ROUNDUP(va, PGSIZE);
f01014d7:	8d b2 ff 0f 00 00    	lea    0xfff(%edx),%esi
f01014dd:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	uint32_t alignsize = ROUNDUP(size, PGSIZE);
f01014e3:	81 c1 ff 0f 00 00    	add    $0xfff,%ecx
f01014e9:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f01014ef:	01 c1                	add    %eax,%ecx
f01014f1:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	while (alignsize) {
f01014f4:	89 c3                	mov    %eax,%ebx
f01014f6:	29 c6                	sub    %eax,%esi
		pte_t *pte = pgdir_walk(pgdir, align, 1);
		if (pte == NULL)
			return -1;
		*pte = pa | perm | PTE_P;
f01014f8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01014fb:	83 c8 01             	or     $0x1,%eax
f01014fe:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101501:	8d 04 1e             	lea    (%esi,%ebx,1),%eax
	while (alignsize) {
f0101504:	39 5d e4             	cmp    %ebx,-0x1c(%ebp)
f0101507:	74 22                	je     f010152b <map_region+0x62>
		pte_t *pte = pgdir_walk(pgdir, align, 1);
f0101509:	83 ec 04             	sub    $0x4,%esp
f010150c:	6a 01                	push   $0x1
f010150e:	50                   	push   %eax
f010150f:	57                   	push   %edi
f0101510:	e8 3d ff ff ff       	call   f0101452 <pgdir_walk>
		if (pte == NULL)
f0101515:	83 c4 10             	add    $0x10,%esp
f0101518:	85 c0                	test   %eax,%eax
f010151a:	74 1c                	je     f0101538 <map_region+0x6f>
		*pte = pa | perm | PTE_P;
f010151c:	8b 55 e0             	mov    -0x20(%ebp),%edx
f010151f:	09 da                	or     %ebx,%edx
f0101521:	89 10                	mov    %edx,(%eax)
		alignsize -= PGSIZE;
		pa += PGSIZE;
f0101523:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0101529:	eb d6                	jmp    f0101501 <map_region+0x38>
		align += PGSIZE;
	} 
	return 0;
f010152b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101530:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101533:	5b                   	pop    %ebx
f0101534:	5e                   	pop    %esi
f0101535:	5f                   	pop    %edi
f0101536:	5d                   	pop    %ebp
f0101537:	c3                   	ret    
			return -1;
f0101538:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010153d:	eb f1                	jmp    f0101530 <map_region+0x67>

f010153f <loaduvm>:

int
loaduvm(pde_t *pgdir, char *addr, struct Proghdr *ph, char *binary)
{
f010153f:	55                   	push   %ebp
f0101540:	89 e5                	mov    %esp,%ebp
f0101542:	57                   	push   %edi
f0101543:	56                   	push   %esi
f0101544:	53                   	push   %ebx
f0101545:	83 ec 20             	sub    $0x20,%esp
f0101548:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010154b:	8b 45 10             	mov    0x10(%ebp),%eax
	pte_t *pte;
	void *dst;
	void *src = ph->p_offset + (void *)binary;
f010154e:	8b 70 04             	mov    0x4(%eax),%esi
f0101551:	03 75 14             	add    0x14(%ebp),%esi
	uint32_t sz = ph->p_filesz;
f0101554:	8b 78 10             	mov    0x10(%eax),%edi
f0101557:	89 7d e0             	mov    %edi,-0x20(%ebp)
	if ((pte = pgdir_walk(pgdir, addr, 0)) == 0)
f010155a:	6a 00                	push   $0x0
f010155c:	53                   	push   %ebx
f010155d:	ff 75 08             	pushl  0x8(%ebp)
f0101560:	e8 ed fe ff ff       	call   f0101452 <pgdir_walk>
f0101565:	83 c4 10             	add    $0x10,%esp
f0101568:	85 c0                	test   %eax,%eax
f010156a:	0f 84 9f 00 00 00    	je     f010160f <loaduvm+0xd0>
		return -1;
	dst = P2V(PTE_ADDR(*pte));
f0101570:	8b 10                	mov    (%eax),%edx
f0101572:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	
	uint32_t offset = (uint32_t)addr & 0xFFF;
f0101578:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f010157b:	89 d8                	mov    %ebx,%eax
f010157d:	25 ff 0f 00 00       	and    $0xfff,%eax
	dst += offset;
	uint32_t n = PGSIZE - offset;
f0101582:	bb 00 10 00 00       	mov    $0x1000,%ebx
f0101587:	29 c3                	sub    %eax,%ebx
	memmove(dst, src, n);
f0101589:	83 ec 04             	sub    $0x4,%esp
f010158c:	53                   	push   %ebx
f010158d:	56                   	push   %esi
	dst += offset;
f010158e:	8d 84 10 00 00 00 f0 	lea    -0x10000000(%eax,%edx,1),%eax
	memmove(dst, src, n);
f0101595:	50                   	push   %eax
f0101596:	e8 5d 22 00 00       	call   f01037f8 <memmove>
	src += n;
f010159b:	8d 04 1e             	lea    (%esi,%ebx,1),%eax
f010159e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01015a1:	89 fe                	mov    %edi,%esi
f01015a3:	29 de                	sub    %ebx,%esi
	for (uint32_t i = n; i < sz; i += PGSIZE) {
f01015a5:	83 c4 10             	add    $0x10,%esp
f01015a8:	3b 5d e0             	cmp    -0x20(%ebp),%ebx
f01015ab:	73 55                	jae    f0101602 <loaduvm+0xc3>
		if ((pte = pgdir_walk(pgdir, addr + i, 0)) == 0)
f01015ad:	83 ec 04             	sub    $0x4,%esp
f01015b0:	6a 00                	push   $0x0
f01015b2:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01015b5:	01 d8                	add    %ebx,%eax
f01015b7:	50                   	push   %eax
f01015b8:	ff 75 08             	pushl  0x8(%ebp)
f01015bb:	e8 92 fe ff ff       	call   f0101452 <pgdir_walk>
f01015c0:	83 c4 10             	add    $0x10,%esp
f01015c3:	85 c0                	test   %eax,%eax
f01015c5:	74 4f                	je     f0101616 <loaduvm+0xd7>
			return -1;
		dst = P2V(PTE_ADDR(*pte));
f01015c7:	8b 00                	mov    (%eax),%eax
f01015c9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01015ce:	2d 00 00 00 10       	sub    $0x10000000,%eax
		if (sz - i < PGSIZE)
			n = sz - i;
f01015d3:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
f01015d9:	bf 00 10 00 00       	mov    $0x1000,%edi
f01015de:	0f 46 fe             	cmovbe %esi,%edi
		else 
			n = PGSIZE;
		memmove(dst, src, n);
f01015e1:	83 ec 04             	sub    $0x4,%esp
f01015e4:	57                   	push   %edi
f01015e5:	ff 75 e4             	pushl  -0x1c(%ebp)
f01015e8:	50                   	push   %eax
f01015e9:	e8 0a 22 00 00       	call   f01037f8 <memmove>
		src += n;
f01015ee:	01 7d e4             	add    %edi,-0x1c(%ebp)
	for (uint32_t i = n; i < sz; i += PGSIZE) {
f01015f1:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01015f7:	81 ee 00 10 00 00    	sub    $0x1000,%esi
f01015fd:	83 c4 10             	add    $0x10,%esp
f0101600:	eb a6                	jmp    f01015a8 <loaduvm+0x69>
	}
	return 0;
f0101602:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101607:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010160a:	5b                   	pop    %ebx
f010160b:	5e                   	pop    %esi
f010160c:	5f                   	pop    %edi
f010160d:	5d                   	pop    %ebp
f010160e:	c3                   	ret    
		return -1;
f010160f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101614:	eb f1                	jmp    f0101607 <loaduvm+0xc8>
			return -1;
f0101616:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010161b:	eb ea                	jmp    f0101607 <loaduvm+0xc8>

f010161d <kvm_init>:
//			for each item of kmap[];
//
// Hint: You may need ARRAY_SIZE.
pde_t *
kvm_init(void)
{
f010161d:	55                   	push   %ebp
f010161e:	89 e5                	mov    %esp,%ebp
f0101620:	57                   	push   %edi
f0101621:	56                   	push   %esi
f0101622:	53                   	push   %ebx
f0101623:	83 ec 0c             	sub    $0xc,%esp
	// TODO: your code here
	pde_t *pgdirinit = (pde_t *)kalloc();
f0101626:	e8 00 0a 00 00       	call   f010202b <kalloc>
f010162b:	89 c6                	mov    %eax,%esi
	if (pgdirinit) {
f010162d:	85 c0                	test   %eax,%eax
f010162f:	74 43                	je     f0101674 <kvm_init+0x57>
	    memset(pgdirinit, 0, PGSIZE);
f0101631:	83 ec 04             	sub    $0x4,%esp
f0101634:	68 00 10 00 00       	push   $0x1000
f0101639:	6a 00                	push   $0x0
f010163b:	50                   	push   %eax
f010163c:	e8 6a 21 00 00       	call   f01037ab <memset>
f0101641:	bb 60 3f 10 f0       	mov    $0xf0103f60,%ebx
f0101646:	bf a0 3f 10 f0       	mov    $0xf0103fa0,%edi
f010164b:	83 c4 10             	add    $0x10,%esp
		for (int i = 0; i < ARRAY_SIZE(kmap); i++)
			if (map_region(pgdirinit, kmap[i].virt, kmap[i].phys_end - kmap[i].phys_start, kmap[i].phys_start, kmap[i].perm) < 0) {
f010164e:	8b 43 04             	mov    0x4(%ebx),%eax
f0101651:	8b 4b 08             	mov    0x8(%ebx),%ecx
f0101654:	29 c1                	sub    %eax,%ecx
f0101656:	83 ec 08             	sub    $0x8,%esp
f0101659:	ff 73 0c             	pushl  0xc(%ebx)
f010165c:	50                   	push   %eax
f010165d:	8b 13                	mov    (%ebx),%edx
f010165f:	89 f0                	mov    %esi,%eax
f0101661:	e8 63 fe ff ff       	call   f01014c9 <map_region>
f0101666:	83 c4 10             	add    $0x10,%esp
f0101669:	85 c0                	test   %eax,%eax
f010166b:	78 11                	js     f010167e <kvm_init+0x61>
f010166d:	83 c3 10             	add    $0x10,%ebx
		for (int i = 0; i < ARRAY_SIZE(kmap); i++)
f0101670:	39 fb                	cmp    %edi,%ebx
f0101672:	75 da                	jne    f010164e <kvm_init+0x31>
                return 0;
			}
		return pgdirinit;
	} else
		return 0;
}
f0101674:	89 f0                	mov    %esi,%eax
f0101676:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101679:	5b                   	pop    %ebx
f010167a:	5e                   	pop    %esi
f010167b:	5f                   	pop    %edi
f010167c:	5d                   	pop    %ebp
f010167d:	c3                   	ret    
				kfree((char *)pgdirinit);
f010167e:	83 ec 0c             	sub    $0xc,%esp
f0101681:	56                   	push   %esi
f0101682:	e8 ec 06 00 00       	call   f0101d73 <kfree>
                return 0;
f0101687:	83 c4 10             	add    $0x10,%esp
f010168a:	be 00 00 00 00       	mov    $0x0,%esi
f010168f:	eb e3                	jmp    f0101674 <kvm_init+0x57>

f0101691 <kvm_switch>:

// Switch h/w page table register to the kernel-only page table.
void
kvm_switch(void)
{
f0101691:	55                   	push   %ebp
f0101692:	89 e5                	mov    %esp,%ebp
	lcr3(V2P(kpgdir)); // switch to the kernel page table
f0101694:	a1 b0 3e 12 f0       	mov    0xf0123eb0,%eax
f0101699:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f010169e:	0f 22 d8             	mov    %eax,%cr3
}
f01016a1:	5d                   	pop    %ebp
f01016a2:	c3                   	ret    

f01016a3 <check_vm>:

void
check_vm(pde_t *pgdir)
{
f01016a3:	55                   	push   %ebp
f01016a4:	89 e5                	mov    %esp,%ebp
f01016a6:	57                   	push   %edi
f01016a7:	56                   	push   %esi
f01016a8:	53                   	push   %ebx
f01016a9:	83 ec 1c             	sub    $0x1c,%esp
f01016ac:	c7 45 e0 60 3f 10 f0 	movl   $0xf0103f60,-0x20(%ebp)
f01016b3:	8b 7d 08             	mov    0x8(%ebp),%edi
f01016b6:	eb 3e                	jmp    f01016f6 <check_vm+0x53>
		uint32_t alignsize = ROUNDUP(kmap[i].phys_end - kmap[i].phys_start, PGSIZE);
		uint32_t pa = kmap[i].phys_start;
		while(alignsize) {
			pte_t *pte = pgdir_walk(pgdir, align, 1);
			if (pte == NULL) 
				panic("vm_fail: Do not find the page table entry");
f01016b8:	83 ec 04             	sub    $0x4,%esp
f01016bb:	68 c0 3e 10 f0       	push   $0xf0103ec0
f01016c0:	68 cd 00 00 00       	push   $0xcd
f01016c5:	68 ea 3e 10 f0       	push   $0xf0103eea
f01016ca:	e8 c9 ea ff ff       	call   f0100198 <_panic>
			pte_t tmp = (*pte >> 12) << 12;
			assert(tmp == pa);
f01016cf:	68 f4 3e 10 f0       	push   $0xf0103ef4
f01016d4:	68 fe 3e 10 f0       	push   $0xf0103efe
f01016d9:	68 cf 00 00 00       	push   $0xcf
f01016de:	68 ea 3e 10 f0       	push   $0xf0103eea
f01016e3:	e8 b0 ea ff ff       	call   f0100198 <_panic>
f01016e8:	83 45 e0 10          	addl   $0x10,-0x20(%ebp)
f01016ec:	8b 45 e0             	mov    -0x20(%ebp),%eax
	for (int i = 0; i < ARRAY_SIZE(kmap); i++) {
f01016ef:	3d a0 3f 10 f0       	cmp    $0xf0103fa0,%eax
f01016f4:	74 5e                	je     f0101754 <check_vm+0xb1>
		char *align = ROUNDUP(kmap[i].virt, PGSIZE);
f01016f6:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01016f9:	8b 10                	mov    (%eax),%edx
f01016fb:	8d b2 ff 0f 00 00    	lea    0xfff(%edx),%esi
f0101701:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
		uint32_t alignsize = ROUNDUP(kmap[i].phys_end - kmap[i].phys_start, PGSIZE);
f0101707:	8b 50 04             	mov    0x4(%eax),%edx
f010170a:	8b 40 08             	mov    0x8(%eax),%eax
f010170d:	05 ff 0f 00 00       	add    $0xfff,%eax
f0101712:	29 d0                	sub    %edx,%eax
f0101714:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0101719:	01 d0                	add    %edx,%eax
f010171b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		uint32_t pa = kmap[i].phys_start;
f010171e:	89 d3                	mov    %edx,%ebx
f0101720:	29 d6                	sub    %edx,%esi
f0101722:	8d 04 1e             	lea    (%esi,%ebx,1),%eax
		while(alignsize) {
f0101725:	39 5d e4             	cmp    %ebx,-0x1c(%ebp)
f0101728:	74 be                	je     f01016e8 <check_vm+0x45>
			pte_t *pte = pgdir_walk(pgdir, align, 1);
f010172a:	83 ec 04             	sub    $0x4,%esp
f010172d:	6a 01                	push   $0x1
f010172f:	50                   	push   %eax
f0101730:	57                   	push   %edi
f0101731:	e8 1c fd ff ff       	call   f0101452 <pgdir_walk>
			if (pte == NULL) 
f0101736:	83 c4 10             	add    $0x10,%esp
f0101739:	85 c0                	test   %eax,%eax
f010173b:	0f 84 77 ff ff ff    	je     f01016b8 <check_vm+0x15>
			pte_t tmp = (*pte >> 12) << 12;
f0101741:	8b 00                	mov    (%eax),%eax
f0101743:	25 00 f0 ff ff       	and    $0xfffff000,%eax
			assert(tmp == pa);
f0101748:	39 c3                	cmp    %eax,%ebx
f010174a:	75 83                	jne    f01016cf <check_vm+0x2c>
			align += PGSIZE;
			pa += PGSIZE;
f010174c:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0101752:	eb ce                	jmp    f0101722 <check_vm+0x7f>
			alignsize -= PGSIZE;
		}
	}
}
f0101754:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101757:	5b                   	pop    %ebx
f0101758:	5e                   	pop    %esi
f0101759:	5f                   	pop    %edi
f010175a:	5d                   	pop    %ebp
f010175b:	c3                   	ret    

f010175c <vm_init>:

// Allocate one page table for the machine for the kernel address
// space.
void
vm_init(void)
{
f010175c:	55                   	push   %ebp
f010175d:	89 e5                	mov    %esp,%ebp
f010175f:	83 ec 08             	sub    $0x8,%esp
	kpgdir = kvm_init();
f0101762:	e8 b6 fe ff ff       	call   f010161d <kvm_init>
f0101767:	a3 b0 3e 12 f0       	mov    %eax,0xf0123eb0
	if (kpgdir == 0)
f010176c:	85 c0                	test   %eax,%eax
f010176e:	74 13                	je     f0101783 <vm_init+0x27>
		panic("vm_init: failure");
	check_vm(kpgdir);
f0101770:	83 ec 0c             	sub    $0xc,%esp
f0101773:	50                   	push   %eax
f0101774:	e8 2a ff ff ff       	call   f01016a3 <check_vm>
	kvm_switch();
f0101779:	e8 13 ff ff ff       	call   f0101691 <kvm_switch>
}
f010177e:	83 c4 10             	add    $0x10,%esp
f0101781:	c9                   	leave  
f0101782:	c3                   	ret    
		panic("vm_init: failure");
f0101783:	83 ec 04             	sub    $0x4,%esp
f0101786:	68 13 3f 10 f0       	push   $0xf0103f13
f010178b:	68 de 00 00 00       	push   $0xde
f0101790:	68 ea 3e 10 f0       	push   $0xf0103eea
f0101795:	e8 fe e9 ff ff       	call   f0100198 <_panic>

f010179a <vm_free>:
// Free a page table.
//
// Hint: You need to free all existing PTEs for this pgdir.
void
vm_free(pde_t *pgdir)
{
f010179a:	55                   	push   %ebp
f010179b:	89 e5                	mov    %esp,%ebp
f010179d:	57                   	push   %edi
f010179e:	56                   	push   %esi
f010179f:	53                   	push   %ebx
f01017a0:	83 ec 0c             	sub    $0xc,%esp
f01017a3:	8b 7d 08             	mov    0x8(%ebp),%edi
f01017a6:	89 fb                	mov    %edi,%ebx
f01017a8:	8d b7 00 10 00 00    	lea    0x1000(%edi),%esi
f01017ae:	eb 07                	jmp    f01017b7 <vm_free+0x1d>
f01017b0:	83 c3 04             	add    $0x4,%ebx
	// TODO: your code here
	for (int i = 0; i < 1024; i++) {
f01017b3:	39 f3                	cmp    %esi,%ebx
f01017b5:	74 1e                	je     f01017d5 <vm_free+0x3b>
	    if (pgdir[i] & PTE_P) {
f01017b7:	8b 03                	mov    (%ebx),%eax
f01017b9:	a8 01                	test   $0x1,%al
f01017bb:	74 f3                	je     f01017b0 <vm_free+0x16>
	        char *v = P2V((pgdir[i] >> 12) << 12);
	        kfree(v);
f01017bd:	83 ec 0c             	sub    $0xc,%esp
	        char *v = P2V((pgdir[i] >> 12) << 12);
f01017c0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01017c5:	2d 00 00 00 10       	sub    $0x10000000,%eax
	        kfree(v);
f01017ca:	50                   	push   %eax
f01017cb:	e8 a3 05 00 00       	call   f0101d73 <kfree>
f01017d0:	83 c4 10             	add    $0x10,%esp
f01017d3:	eb db                	jmp    f01017b0 <vm_free+0x16>
	    }
	}
	kfree((char *)pgdir);
f01017d5:	83 ec 0c             	sub    $0xc,%esp
f01017d8:	57                   	push   %edi
f01017d9:	e8 95 05 00 00       	call   f0101d73 <kfree>
}
f01017de:	83 c4 10             	add    $0x10,%esp
f01017e1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01017e4:	5b                   	pop    %ebx
f01017e5:	5e                   	pop    %esi
f01017e6:	5f                   	pop    %edi
f01017e7:	5d                   	pop    %ebp
f01017e8:	c3                   	ret    

f01017e9 <copyuvm>:

// Copy parent process's page table to its children
pde_t *
copyuvm(pde_t *pgdir)
{
f01017e9:	55                   	push   %ebp
f01017ea:	89 e5                	mov    %esp,%ebp
f01017ec:	57                   	push   %edi
f01017ed:	56                   	push   %esi
f01017ee:	53                   	push   %ebx
f01017ef:	83 ec 1c             	sub    $0x1c,%esp
f01017f2:	8b 7d 08             	mov    0x8(%ebp),%edi
	pde_t *child_pgdir;
	pte_t *pte;
	uint32_t pa, flags;
	char *page;
	if ((child_pgdir = kvm_init()) == 0)
f01017f5:	e8 23 fe ff ff       	call   f010161d <kvm_init>
f01017fa:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01017fd:	85 c0                	test   %eax,%eax
f01017ff:	74 1c                	je     f010181d <copyuvm+0x34>
		return NULL;
	for (uint32_t i = 0; i < USTACKTOP; i += PGSIZE) {
f0101801:	be 00 00 00 00       	mov    $0x0,%esi
f0101806:	eb 2e                	jmp    f0101836 <copyuvm+0x4d>
			continue;
		if (*pte & PTE_P) {
			pa = PTE_ADDR(*pte);
			flags = PTE_FLAGS(*pte);
			if ((page = kalloc()) == NULL) {
				vm_free(child_pgdir);
f0101808:	83 ec 0c             	sub    $0xc,%esp
f010180b:	ff 75 d8             	pushl  -0x28(%ebp)
f010180e:	e8 87 ff ff ff       	call   f010179a <vm_free>
				return NULL;
f0101813:	83 c4 10             	add    $0x10,%esp
f0101816:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
				return NULL;
			}
		}
	}
	return child_pgdir;
}
f010181d:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101820:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101823:	5b                   	pop    %ebx
f0101824:	5e                   	pop    %esi
f0101825:	5f                   	pop    %edi
f0101826:	5d                   	pop    %ebp
f0101827:	c3                   	ret    
	for (uint32_t i = 0; i < USTACKTOP; i += PGSIZE) {
f0101828:	81 c6 00 10 00 00    	add    $0x1000,%esi
f010182e:	81 fe 00 00 00 d0    	cmp    $0xd0000000,%esi
f0101834:	74 e7                	je     f010181d <copyuvm+0x34>
		if ((pte = pgdir_walk(pgdir, (void *)i, 0)) == NULL)
f0101836:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0101839:	83 ec 04             	sub    $0x4,%esp
f010183c:	6a 00                	push   $0x0
f010183e:	56                   	push   %esi
f010183f:	57                   	push   %edi
f0101840:	e8 0d fc ff ff       	call   f0101452 <pgdir_walk>
f0101845:	83 c4 10             	add    $0x10,%esp
f0101848:	85 c0                	test   %eax,%eax
f010184a:	74 dc                	je     f0101828 <copyuvm+0x3f>
		if (*pte & PTE_P) {
f010184c:	8b 00                	mov    (%eax),%eax
f010184e:	a8 01                	test   $0x1,%al
f0101850:	74 d6                	je     f0101828 <copyuvm+0x3f>
			pa = PTE_ADDR(*pte);
f0101852:	89 c2                	mov    %eax,%edx
f0101854:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010185a:	89 55 e0             	mov    %edx,-0x20(%ebp)
			flags = PTE_FLAGS(*pte);
f010185d:	25 ff 0f 00 00       	and    $0xfff,%eax
f0101862:	89 45 dc             	mov    %eax,-0x24(%ebp)
			if ((page = kalloc()) == NULL) {
f0101865:	e8 c1 07 00 00       	call   f010202b <kalloc>
f010186a:	89 c3                	mov    %eax,%ebx
f010186c:	85 c0                	test   %eax,%eax
f010186e:	74 98                	je     f0101808 <copyuvm+0x1f>
			memmove(page, P2V(pa), PGSIZE);
f0101870:	83 ec 04             	sub    $0x4,%esp
f0101873:	68 00 10 00 00       	push   $0x1000
f0101878:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010187b:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101880:	50                   	push   %eax
f0101881:	53                   	push   %ebx
f0101882:	e8 71 1f 00 00       	call   f01037f8 <memmove>
			if (map_region(child_pgdir, (void *)i, PGSIZE, V2P(page), flags) < 0) {
f0101887:	83 c4 08             	add    $0x8,%esp
f010188a:	ff 75 dc             	pushl  -0x24(%ebp)
f010188d:	8d 83 00 00 00 10    	lea    0x10000000(%ebx),%eax
f0101893:	50                   	push   %eax
f0101894:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0101899:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f010189c:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010189f:	e8 25 fc ff ff       	call   f01014c9 <map_region>
f01018a4:	83 c4 10             	add    $0x10,%esp
f01018a7:	85 c0                	test   %eax,%eax
f01018a9:	0f 89 79 ff ff ff    	jns    f0101828 <copyuvm+0x3f>
				kfree(page);
f01018af:	83 ec 0c             	sub    $0xc,%esp
f01018b2:	53                   	push   %ebx
f01018b3:	e8 bb 04 00 00       	call   f0101d73 <kfree>
				vm_free(child_pgdir);
f01018b8:	83 c4 04             	add    $0x4,%esp
f01018bb:	ff 75 d8             	pushl  -0x28(%ebp)
f01018be:	e8 d7 fe ff ff       	call   f010179a <vm_free>
				return NULL;
f01018c3:	83 c4 10             	add    $0x10,%esp
f01018c6:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f01018cd:	e9 4b ff ff ff       	jmp    f010181d <copyuvm+0x34>

f01018d2 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
void
region_alloc(struct proc *p, void *va, size_t len)
{
f01018d2:	55                   	push   %ebp
f01018d3:	89 e5                	mov    %esp,%ebp
f01018d5:	57                   	push   %edi
f01018d6:	56                   	push   %esi
f01018d7:	53                   	push   %ebx
f01018d8:	83 ec 1c             	sub    $0x1c,%esp
f01018db:	8b 7d 08             	mov    0x8(%ebp),%edi
	//
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	char *begin = ROUNDDOWN(va, PGSIZE);
f01018de:	8b 55 0c             	mov    0xc(%ebp),%edx
f01018e1:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01018e7:	89 d6                	mov    %edx,%esi
	uint32_t size = ROUNDUP(len, PGSIZE);
f01018e9:	8b 45 10             	mov    0x10(%ebp),%eax
f01018ec:	05 ff 0f 00 00       	add    $0xfff,%eax
f01018f1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01018f6:	01 d0                	add    %edx,%eax
f01018f8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	while (size) {
f01018fb:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f01018fe:	74 57                	je     f0101957 <region_alloc+0x85>
		char *page = kalloc();
f0101900:	e8 26 07 00 00       	call   f010202b <kalloc>
f0101905:	89 c3                	mov    %eax,%ebx
		memset(page, 0, PGSIZE);
f0101907:	83 ec 04             	sub    $0x4,%esp
f010190a:	68 00 10 00 00       	push   $0x1000
f010190f:	6a 00                	push   $0x0
f0101911:	50                   	push   %eax
f0101912:	e8 94 1e 00 00       	call   f01037ab <memset>
		if (map_region(p->pgdir, begin, PGSIZE, V2P(page), PTE_W | PTE_U) < 0)
f0101917:	83 c4 08             	add    $0x8,%esp
f010191a:	6a 06                	push   $0x6
f010191c:	81 c3 00 00 00 10    	add    $0x10000000,%ebx
f0101922:	53                   	push   %ebx
f0101923:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0101928:	89 f2                	mov    %esi,%edx
f010192a:	8b 07                	mov    (%edi),%eax
f010192c:	e8 98 fb ff ff       	call   f01014c9 <map_region>
f0101931:	83 c4 10             	add    $0x10,%esp
f0101934:	85 c0                	test   %eax,%eax
f0101936:	78 08                	js     f0101940 <region_alloc+0x6e>
			panic("Map space for user process.");
		begin += PGSIZE;
f0101938:	81 c6 00 10 00 00    	add    $0x1000,%esi
f010193e:	eb bb                	jmp    f01018fb <region_alloc+0x29>
			panic("Map space for user process.");
f0101940:	83 ec 04             	sub    $0x4,%esp
f0101943:	68 24 3f 10 f0       	push   $0xf0103f24
f0101948:	68 29 01 00 00       	push   $0x129
f010194d:	68 ea 3e 10 f0       	push   $0xf0103eea
f0101952:	e8 41 e8 ff ff       	call   f0100198 <_panic>
		size -= PGSIZE;
	}
}
f0101957:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010195a:	5b                   	pop    %ebx
f010195b:	5e                   	pop    %esi
f010195c:	5f                   	pop    %edi
f010195d:	5d                   	pop    %ebp
f010195e:	c3                   	ret    

f010195f <pushcli>:

void
pushcli(void)
{
f010195f:	55                   	push   %ebp
f0101960:	89 e5                	mov    %esp,%ebp
f0101962:	53                   	push   %ebx
f0101963:	83 ec 04             	sub    $0x4,%esp
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f0101966:	9c                   	pushf  
f0101967:	5b                   	pop    %ebx
}

static inline void
cli(void)
{
	asm volatile("cli");
f0101968:	fa                   	cli    
	int32_t eflags;

	eflags = read_eflags();
	cli();
	if (thiscpu->ncli == 0)
f0101969:	e8 02 0d 00 00       	call   f0102670 <cpunum>
f010196e:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f0101974:	83 b8 c8 40 12 f0 00 	cmpl   $0x0,-0xfedbf38(%eax)
f010197b:	74 18                	je     f0101995 <pushcli+0x36>
		thiscpu->intena = eflags & FL_IF;
	thiscpu->ncli += 1;
f010197d:	e8 ee 0c 00 00       	call   f0102670 <cpunum>
f0101982:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f0101988:	83 80 c8 40 12 f0 01 	addl   $0x1,-0xfedbf38(%eax)
	// cprintf("%x in push ncli: %d\n", thiscpu, thiscpu->ncli);
}
f010198f:	83 c4 04             	add    $0x4,%esp
f0101992:	5b                   	pop    %ebx
f0101993:	5d                   	pop    %ebp
f0101994:	c3                   	ret    
		thiscpu->intena = eflags & FL_IF;
f0101995:	e8 d6 0c 00 00       	call   f0102670 <cpunum>
f010199a:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f01019a0:	81 e3 00 02 00 00    	and    $0x200,%ebx
f01019a6:	89 98 cc 40 12 f0    	mov    %ebx,-0xfedbf34(%eax)
f01019ac:	eb cf                	jmp    f010197d <pushcli+0x1e>

f01019ae <popcli>:

void
popcli(void)
{
f01019ae:	55                   	push   %ebp
f01019af:	89 e5                	mov    %esp,%ebp
f01019b1:	83 ec 08             	sub    $0x8,%esp
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f01019b4:	9c                   	pushf  
f01019b5:	58                   	pop    %eax
	if (read_eflags() & FL_IF)
f01019b6:	f6 c4 02             	test   $0x2,%ah
f01019b9:	75 34                	jne    f01019ef <popcli+0x41>
		panic("popcli - interruptible");
	// cprintf("%x in pop ncli: %d\n", thiscpu, thiscpu->ncli);
	if (--thiscpu->ncli < 0)
f01019bb:	e8 b0 0c 00 00       	call   f0102670 <cpunum>
f01019c0:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f01019c6:	8b 88 c8 40 12 f0    	mov    -0xfedbf38(%eax),%ecx
f01019cc:	8d 51 ff             	lea    -0x1(%ecx),%edx
f01019cf:	89 90 c8 40 12 f0    	mov    %edx,-0xfedbf38(%eax)
f01019d5:	85 d2                	test   %edx,%edx
f01019d7:	78 2d                	js     f0101a06 <popcli+0x58>
		panic("popcli");
	
	if (thiscpu->ncli == 0 && thiscpu->intena)
f01019d9:	e8 92 0c 00 00       	call   f0102670 <cpunum>
f01019de:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f01019e4:	83 b8 c8 40 12 f0 00 	cmpl   $0x0,-0xfedbf38(%eax)
f01019eb:	74 30                	je     f0101a1d <popcli+0x6f>
		sti();
}
f01019ed:	c9                   	leave  
f01019ee:	c3                   	ret    
		panic("popcli - interruptible");
f01019ef:	83 ec 04             	sub    $0x4,%esp
f01019f2:	68 40 3f 10 f0       	push   $0xf0103f40
f01019f7:	68 40 01 00 00       	push   $0x140
f01019fc:	68 ea 3e 10 f0       	push   $0xf0103eea
f0101a01:	e8 92 e7 ff ff       	call   f0100198 <_panic>
		panic("popcli");
f0101a06:	83 ec 04             	sub    $0x4,%esp
f0101a09:	68 57 3f 10 f0       	push   $0xf0103f57
f0101a0e:	68 43 01 00 00       	push   $0x143
f0101a13:	68 ea 3e 10 f0       	push   $0xf0103eea
f0101a18:	e8 7b e7 ff ff       	call   f0100198 <_panic>
	if (thiscpu->ncli == 0 && thiscpu->intena)
f0101a1d:	e8 4e 0c 00 00       	call   f0102670 <cpunum>
f0101a22:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f0101a28:	83 b8 cc 40 12 f0 00 	cmpl   $0x0,-0xfedbf34(%eax)
f0101a2f:	74 bc                	je     f01019ed <popcli+0x3f>
}

static inline void
sti(void)
{
	asm volatile("sti");
f0101a31:	fb                   	sti    
}
f0101a32:	eb b9                	jmp    f01019ed <popcli+0x3f>

f0101a34 <uvm_switch>:
//
// Switch TSS and h/w page table to correspond to process p.
//
void
uvm_switch(struct proc *p)
{
f0101a34:	55                   	push   %ebp
f0101a35:	89 e5                	mov    %esp,%ebp
f0101a37:	57                   	push   %edi
f0101a38:	56                   	push   %esi
f0101a39:	53                   	push   %ebx
f0101a3a:	83 ec 0c             	sub    $0xc,%esp
	//
	// Hints:
	// - You may need pushcli() and popcli()
	// - You need to set TSS and ltr(SEG_TSS << 3)
	// - You need to switch to process's address space
	pushcli();
f0101a3d:	e8 1d ff ff ff       	call   f010195f <pushcli>
	thiscpu->gdt[SEG_TSS] = SEG16(STS_T32A, &thiscpu->cpu_ts, sizeof(thiscpu->cpu_ts) - 1, 0);
f0101a42:	e8 29 0c 00 00       	call   f0102670 <cpunum>
f0101a47:	89 c3                	mov    %eax,%ebx
f0101a49:	e8 22 0c 00 00       	call   f0102670 <cpunum>
f0101a4e:	89 c7                	mov    %eax,%edi
f0101a50:	e8 1b 0c 00 00       	call   f0102670 <cpunum>
f0101a55:	89 c6                	mov    %eax,%esi
f0101a57:	e8 14 0c 00 00       	call   f0102670 <cpunum>
f0101a5c:	69 db b8 00 00 00    	imul   $0xb8,%ebx,%ebx
f0101a62:	8d 93 20 40 12 f0    	lea    -0xfedbfe0(%ebx),%edx
f0101a68:	66 c7 83 bc 40 12 f0 	movw   $0x67,-0xfedbf44(%ebx)
f0101a6f:	67 00 
f0101a71:	69 ff b8 00 00 00    	imul   $0xb8,%edi,%edi
f0101a77:	81 c7 2c 40 12 f0    	add    $0xf012402c,%edi
f0101a7d:	66 89 bb be 40 12 f0 	mov    %di,-0xfedbf42(%ebx)
f0101a84:	69 ce b8 00 00 00    	imul   $0xb8,%esi,%ecx
f0101a8a:	81 c1 2c 40 12 f0    	add    $0xf012402c,%ecx
f0101a90:	c1 e9 10             	shr    $0x10,%ecx
f0101a93:	88 8b c0 40 12 f0    	mov    %cl,-0xfedbf40(%ebx)
f0101a99:	c6 83 c1 40 12 f0 99 	movb   $0x99,-0xfedbf3f(%ebx)
f0101aa0:	c6 83 c2 40 12 f0 40 	movb   $0x40,-0xfedbf3e(%ebx)
f0101aa7:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f0101aad:	05 2c 40 12 f0       	add    $0xf012402c,%eax
f0101ab2:	c1 e8 18             	shr    $0x18,%eax
f0101ab5:	88 82 a3 00 00 00    	mov    %al,0xa3(%edx)
	thiscpu->gdt[SEG_TSS].s = 0;
f0101abb:	e8 b0 0b 00 00       	call   f0102670 <cpunum>
f0101ac0:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f0101ac6:	80 a0 c1 40 12 f0 ef 	andb   $0xef,-0xfedbf3f(%eax)
	thiscpu->cpu_ts.ss0 = SEG_KDATA << 3;
f0101acd:	e8 9e 0b 00 00       	call   f0102670 <cpunum>
f0101ad2:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f0101ad8:	66 c7 80 34 40 12 f0 	movw   $0x10,-0xfedbfcc(%eax)
f0101adf:	10 00 
	thiscpu->cpu_ts.esp0 = (uintptr_t)p->kstack + KSTACKSIZE;
f0101ae1:	8b 45 08             	mov    0x8(%ebp),%eax
f0101ae4:	8b 58 04             	mov    0x4(%eax),%ebx
f0101ae7:	e8 84 0b 00 00       	call   f0102670 <cpunum>
f0101aec:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f0101af2:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0101af8:	89 98 30 40 12 f0    	mov    %ebx,-0xfedbfd0(%eax)
	thiscpu->cpu_ts.iomb = (uint16_t)0xFFFF;
f0101afe:	e8 6d 0b 00 00       	call   f0102670 <cpunum>
f0101b03:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f0101b09:	66 c7 80 92 40 12 f0 	movw   $0xffff,-0xfedbf6e(%eax)
f0101b10:	ff ff 
	asm volatile("ltr %0" : : "r" (sel));
f0101b12:	b8 28 00 00 00       	mov    $0x28,%eax
f0101b17:	0f 00 d8             	ltr    %ax
	ltr(SEG_TSS << 3);
	lcr3(V2P(p->pgdir));
f0101b1a:	8b 45 08             	mov    0x8(%ebp),%eax
f0101b1d:	8b 00                	mov    (%eax),%eax
f0101b1f:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0101b24:	0f 22 d8             	mov    %eax,%cr3
	popcli();
f0101b27:	e8 82 fe ff ff       	call   f01019ae <popcli>
}
f0101b2c:	83 c4 0c             	add    $0xc,%esp
f0101b2f:	5b                   	pop    %ebx
f0101b30:	5e                   	pop    %esi
f0101b31:	5f                   	pop    %edi
f0101b32:	5d                   	pop    %ebp
f0101b33:	c3                   	ret    

f0101b34 <pow_2>:
// the pages mapped by entrypgdir on free list.
// 2. Call alloc_init() with the rest of the physical pages after
// installing a full page table.

int pow_2(int power)
{
f0101b34:	55                   	push   %ebp
f0101b35:	89 e5                	mov    %esp,%ebp
f0101b37:	8b 4d 08             	mov    0x8(%ebp),%ecx
	int num = 1;
	for (int i = 0; i < power; i++)
f0101b3a:	ba 00 00 00 00       	mov    $0x0,%edx
	int num = 1;
f0101b3f:	b8 01 00 00 00       	mov    $0x1,%eax
	for (int i = 0; i < power; i++)
f0101b44:	eb 05                	jmp    f0101b4b <pow_2+0x17>
		num *= 2;
f0101b46:	01 c0                	add    %eax,%eax
	for (int i = 0; i < power; i++)
f0101b48:	83 c2 01             	add    $0x1,%edx
f0101b4b:	39 ca                	cmp    %ecx,%edx
f0101b4d:	7c f7                	jl     f0101b46 <pow_2+0x12>
	return num;
}
f0101b4f:	5d                   	pop    %ebp
f0101b50:	c3                   	ret    

f0101b51 <Buddykfree>:
	kmem.free_list = r;*/
}

void
Buddykfree(char *v)
{
f0101b51:	55                   	push   %ebp
f0101b52:	89 e5                	mov    %esp,%ebp
f0101b54:	57                   	push   %edi
f0101b55:	56                   	push   %esi
f0101b56:	53                   	push   %ebx
f0101b57:	83 ec 2c             	sub    $0x2c,%esp
	struct run *r;

	if ((uint32_t)v % PGSIZE || v < end || V2P(v) >= PHYSTOP)
f0101b5a:	8b 45 08             	mov    0x8(%ebp),%eax
f0101b5d:	a9 ff 0f 00 00       	test   $0xfff,%eax
f0101b62:	75 56                	jne    f0101bba <Buddykfree+0x69>
f0101b64:	3d 54 57 16 f0       	cmp    $0xf0165754,%eax
f0101b69:	72 4f                	jb     f0101bba <Buddykfree+0x69>
f0101b6b:	05 00 00 00 10       	add    $0x10000000,%eax
f0101b70:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
f0101b75:	77 43                	ja     f0101bba <Buddykfree+0x69>
		panic("kfree");
	int idx, id;
	id = (void *)v >= (void *)base[1];
f0101b77:	8b 45 08             	mov    0x8(%ebp),%eax
f0101b7a:	39 05 c4 3e 12 f0    	cmp    %eax,0xf0123ec4
f0101b80:	0f 96 45 cb          	setbe  -0x35(%ebp)
f0101b84:	0f b6 45 cb          	movzbl -0x35(%ebp),%eax
f0101b88:	0f b6 f0             	movzbl %al,%esi
	//cprintf("minus: %x, num: %x,idx: %x\n", (void *)v - (void *)base[0], (uint32_t)((void *)v - (void *)base[0]) / PGSIZE, idx);
	idx = (uint32_t)((void *)v - (void *)base[id]) / PGSIZE;
f0101b8b:	8b 45 08             	mov    0x8(%ebp),%eax
f0101b8e:	2b 04 b5 c0 3e 12 f0 	sub    -0xfedc140(,%esi,4),%eax
f0101b95:	c1 e8 0c             	shr    $0xc,%eax
f0101b98:	89 45 cc             	mov    %eax,-0x34(%ebp)
	int p = idx;
	int count = 0;
	//cprintf("v: %x, idx: %x, p: %x\n", v, idx, p);
	if (Buddy[id].use_lock)
f0101b9b:	6b c6 3c             	imul   $0x3c,%esi,%eax
f0101b9e:	83 b8 e0 3e 12 f0 00 	cmpl   $0x0,-0xfedc120(%eax)
f0101ba5:	75 2a                	jne    f0101bd1 <Buddykfree+0x80>
		spin_lock(&Buddy[id].lock);
	while (order[id][p] != 1) {
f0101ba7:	8b 3c b5 60 3f 12 f0 	mov    -0xfedc0a0(,%esi,4),%edi
f0101bae:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101bb1:	89 c3                	mov    %eax,%ebx
f0101bb3:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101bb8:	eb 3e                	jmp    f0101bf8 <Buddykfree+0xa7>
		panic("kfree");
f0101bba:	83 ec 04             	sub    $0x4,%esp
f0101bbd:	68 a0 3f 10 f0       	push   $0xf0103fa0
f0101bc2:	68 e3 00 00 00       	push   $0xe3
f0101bc7:	68 a6 3f 10 f0       	push   $0xf0103fa6
f0101bcc:	e8 c7 e5 ff ff       	call   f0100198 <_panic>
		spin_lock(&Buddy[id].lock);
f0101bd1:	83 ec 0c             	sub    $0xc,%esp
f0101bd4:	6b c6 3c             	imul   $0x3c,%esi,%eax
f0101bd7:	05 e8 3e 12 f0       	add    $0xf0123ee8,%eax
f0101bdc:	50                   	push   %eax
f0101bdd:	e8 cb 0c 00 00       	call   f01028ad <spin_lock>
f0101be2:	83 c4 10             	add    $0x10,%esp
f0101be5:	eb c0                	jmp    f0101ba7 <Buddykfree+0x56>
		count++;
f0101be7:	83 c1 01             	add    $0x1,%ecx
		p = start[id][count] + (idx >> count);
f0101bea:	8b 14 b5 68 3f 12 f0 	mov    -0xfedc098(,%esi,4),%edx
f0101bf1:	89 c3                	mov    %eax,%ebx
f0101bf3:	d3 fb                	sar    %cl,%ebx
f0101bf5:	03 1c 8a             	add    (%edx,%ecx,4),%ebx
	while (order[id][p] != 1) {
f0101bf8:	80 3c 1f 00          	cmpb   $0x0,(%edi,%ebx,1)
f0101bfc:	74 e9                	je     f0101be7 <Buddykfree+0x96>
f0101bfe:	89 5d e0             	mov    %ebx,-0x20(%ebp)
f0101c01:	89 cf                	mov    %ecx,%edi
f0101c03:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	}
	//cprintf("p: %x\n", p);
	memset(v, 1, PGSIZE * pow_2(count));
f0101c06:	83 ec 0c             	sub    $0xc,%esp
f0101c09:	51                   	push   %ecx
f0101c0a:	e8 25 ff ff ff       	call   f0101b34 <pow_2>
f0101c0f:	83 c4 0c             	add    $0xc,%esp
f0101c12:	c1 e0 0c             	shl    $0xc,%eax
f0101c15:	50                   	push   %eax
f0101c16:	6a 01                	push   $0x1
f0101c18:	ff 75 08             	pushl  0x8(%ebp)
f0101c1b:	e8 8b 1b 00 00       	call   f01037ab <memset>
	order[id][p] = 0;
f0101c20:	8b 04 b5 60 3f 12 f0 	mov    -0xfedc0a0(,%esi,4),%eax
f0101c27:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0101c2a:	c6 04 10 00          	movb   $0x0,(%eax,%edx,1)
	int buddy = p ^ 1;
f0101c2e:	89 d8                	mov    %ebx,%eax
f0101c30:	83 f0 01             	xor    $0x1,%eax
	int mark = 1 << (count + 12);
f0101c33:	8d 4f 0c             	lea    0xc(%edi),%ecx
f0101c36:	ba 01 00 00 00       	mov    $0x1,%edx
f0101c3b:	d3 e2                	shl    %cl,%edx
f0101c3d:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101c40:	8d 14 fd 00 00 00 00 	lea    0x0(,%edi,8),%edx
f0101c47:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0101c4a:	8d 3c bd 04 00 00 00 	lea    0x4(,%edi,4),%edi
f0101c51:	89 7d d8             	mov    %edi,-0x28(%ebp)
	char *buddypos;
	while (count < MAX_ORDER[id] && order[id][buddy] == 0) {
f0101c54:	83 c4 10             	add    $0x10,%esp
		//cprintf("p: %x, buddy: %x\n", p, buddy);
		buddypos = (char *)base[id] + ((uint32_t)(v - (char *)base[id]) ^ mark);
		//cprintf("buddypos: %x, mark: %x\n", buddypos, mark);
		struct run *iter = Buddy[id].slot[count].free_list;
f0101c57:	6b d6 3c             	imul   $0x3c,%esi,%edx
f0101c5a:	8d ba e0 3e 12 f0    	lea    -0xfedc120(%edx),%edi
f0101c60:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0101c63:	89 f7                	mov    %esi,%edi
	while (count < MAX_ORDER[id] && order[id][buddy] == 0) {
f0101c65:	eb 72                	jmp    f0101cd9 <Buddykfree+0x188>
		while (iter->next != (struct run *)buddypos && iter->next != Buddy[id].slot[count].free_list)
f0101c67:	89 c2                	mov    %eax,%edx
f0101c69:	8b 02                	mov    (%edx),%eax
f0101c6b:	39 f0                	cmp    %esi,%eax
f0101c6d:	0f 95 c3             	setne  %bl
f0101c70:	39 f8                	cmp    %edi,%eax
f0101c72:	0f 95 c1             	setne  %cl
f0101c75:	84 cb                	test   %cl,%bl
f0101c77:	75 ee                	jne    f0101c67 <Buddykfree+0x116>
f0101c79:	8b 7d d0             	mov    -0x30(%ebp),%edi
		// buddy is occupied
		// have little change
		//if (iter->next != (struct run *)buddypos)
		//	break;
		struct run *uni = iter->next;
		iter->next = uni->next;
f0101c7c:	8b 08                	mov    (%eax),%ecx
f0101c7e:	89 0a                	mov    %ecx,(%edx)
		Buddy[id].slot[count].num--;
f0101c80:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101c83:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0101c86:	89 f1                	mov    %esi,%ecx
f0101c88:	03 4b 04             	add    0x4(%ebx),%ecx
f0101c8b:	83 69 04 01          	subl   $0x1,0x4(%ecx)
		Buddy[id].slot[count].free_list = iter->next;
f0101c8f:	8b 0a                	mov    (%edx),%ecx
f0101c91:	8b 53 04             	mov    0x4(%ebx),%edx
f0101c94:	89 0c 32             	mov    %ecx,(%edx,%esi,1)
		v = (v > (char *)uni) ? (char *)uni : v;
f0101c97:	39 45 08             	cmp    %eax,0x8(%ebp)
f0101c9a:	0f 46 45 08          	cmovbe 0x8(%ebp),%eax
f0101c9e:	89 45 08             	mov    %eax,0x8(%ebp)
		count++;
f0101ca1:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
f0101ca5:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		mark <<= 1;
f0101ca8:	d1 65 dc             	shll   -0x24(%ebp)
		p = start[id][count] + (idx >> count);
f0101cab:	8b 14 bd 68 3f 12 f0 	mov    -0xfedc098(,%edi,4),%edx
f0101cb2:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101cb5:	89 d9                	mov    %ebx,%ecx
f0101cb7:	d3 f8                	sar    %cl,%eax
f0101cb9:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0101cbc:	03 04 1a             	add    (%edx,%ebx,1),%eax
		//cprintf("order: %d, p: %x\n", order[id][p], p);
		order[id][p] = 0;
f0101cbf:	8b 14 bd 60 3f 12 f0 	mov    -0xfedc0a0(,%edi,4),%edx
f0101cc6:	c6 04 02 00          	movb   $0x0,(%edx,%eax,1)
		//cprintf("order: %d\n", order[id][p]);
		buddy = p ^ 1;
f0101cca:	83 f0 01             	xor    $0x1,%eax
f0101ccd:	83 c6 08             	add    $0x8,%esi
f0101cd0:	89 75 e0             	mov    %esi,-0x20(%ebp)
f0101cd3:	83 c3 04             	add    $0x4,%ebx
f0101cd6:	89 5d d8             	mov    %ebx,-0x28(%ebp)
	while (count < MAX_ORDER[id] && order[id][buddy] == 0) {
f0101cd9:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101cdc:	39 0c bd 70 3f 12 f0 	cmp    %ecx,-0xfedc090(,%edi,4)
f0101ce3:	7e 37                	jle    f0101d1c <Buddykfree+0x1cb>
f0101ce5:	8b 14 bd 60 3f 12 f0 	mov    -0xfedc0a0(,%edi,4),%edx
f0101cec:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101cf0:	75 2a                	jne    f0101d1c <Buddykfree+0x1cb>
		buddypos = (char *)base[id] + ((uint32_t)(v - (char *)base[id]) ^ mark);
f0101cf2:	8b 04 bd c0 3e 12 f0 	mov    -0xfedc140(,%edi,4),%eax
f0101cf9:	8b 75 08             	mov    0x8(%ebp),%esi
f0101cfc:	29 c6                	sub    %eax,%esi
f0101cfe:	33 75 dc             	xor    -0x24(%ebp),%esi
f0101d01:	8d 0c 30             	lea    (%eax,%esi,1),%ecx
		struct run *iter = Buddy[id].slot[count].free_list;
f0101d04:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d07:	8b 40 04             	mov    0x4(%eax),%eax
f0101d0a:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0101d0d:	8b 34 30             	mov    (%eax,%esi,1),%esi
f0101d10:	89 f2                	mov    %esi,%edx
f0101d12:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0101d15:	89 cf                	mov    %ecx,%edi
		while (iter->next != (struct run *)buddypos && iter->next != Buddy[id].slot[count].free_list)
f0101d17:	e9 4d ff ff ff       	jmp    f0101c69 <Buddykfree+0x118>
	}
	r = (struct run *)v;
	r->next = Buddy[id].slot[count].free_list->next;
f0101d1c:	6b d7 3c             	imul   $0x3c,%edi,%edx
f0101d1f:	8b 8a e4 3e 12 f0    	mov    -0xfedc11c(%edx),%ecx
f0101d25:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101d28:	8b 0c f9             	mov    (%ecx,%edi,8),%ecx
f0101d2b:	8b 09                	mov    (%ecx),%ecx
f0101d2d:	8b 75 08             	mov    0x8(%ebp),%esi
f0101d30:	89 0e                	mov    %ecx,(%esi)
	Buddy[id].slot[count].free_list->next = r;
f0101d32:	8b 8a e4 3e 12 f0    	mov    -0xfedc11c(%edx),%ecx
f0101d38:	8b 0c f9             	mov    (%ecx,%edi,8),%ecx
f0101d3b:	89 31                	mov    %esi,(%ecx)
	Buddy[id].slot[count].num++;
f0101d3d:	8b 82 e4 3e 12 f0    	mov    -0xfedc11c(%edx),%eax
f0101d43:	83 44 f8 04 01       	addl   $0x1,0x4(%eax,%edi,8)
	if (Buddy[id].use_lock)
f0101d48:	83 ba e0 3e 12 f0 00 	cmpl   $0x0,-0xfedc120(%edx)
f0101d4f:	75 08                	jne    f0101d59 <Buddykfree+0x208>
		spin_unlock(&Buddy[id].lock);
}
f0101d51:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101d54:	5b                   	pop    %ebx
f0101d55:	5e                   	pop    %esi
f0101d56:	5f                   	pop    %edi
f0101d57:	5d                   	pop    %ebp
f0101d58:	c3                   	ret    
		spin_unlock(&Buddy[id].lock);
f0101d59:	83 ec 0c             	sub    $0xc,%esp
f0101d5c:	0f b6 45 cb          	movzbl -0x35(%ebp),%eax
f0101d60:	6b c0 3c             	imul   $0x3c,%eax,%eax
f0101d63:	05 e8 3e 12 f0       	add    $0xf0123ee8,%eax
f0101d68:	50                   	push   %eax
f0101d69:	e8 9e 0b 00 00       	call   f010290c <spin_unlock>
f0101d6e:	83 c4 10             	add    $0x10,%esp
}
f0101d71:	eb de                	jmp    f0101d51 <Buddykfree+0x200>

f0101d73 <kfree>:
{
f0101d73:	55                   	push   %ebp
f0101d74:	89 e5                	mov    %esp,%ebp
f0101d76:	83 ec 14             	sub    $0x14,%esp
	Buddykfree(v);
f0101d79:	ff 75 08             	pushl  0x8(%ebp)
f0101d7c:	e8 d0 fd ff ff       	call   f0101b51 <Buddykfree>
}
f0101d81:	83 c4 10             	add    $0x10,%esp
f0101d84:	c9                   	leave  
f0101d85:	c3                   	ret    

f0101d86 <free_range>:

void
free_range(void *vstart, void *vend)
{
f0101d86:	55                   	push   %ebp
f0101d87:	89 e5                	mov    %esp,%ebp
f0101d89:	56                   	push   %esi
f0101d8a:	53                   	push   %ebx
f0101d8b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *p;
	p = ROUNDUP((char *)vstart, PGSIZE);
f0101d8e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101d91:	05 ff 0f 00 00       	add    $0xfff,%eax
f0101d96:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	for (; p + PGSIZE <= (char *)vend; p += PGSIZE)
f0101d9b:	eb 0e                	jmp    f0101dab <free_range+0x25>
	Buddykfree(v);
f0101d9d:	83 ec 0c             	sub    $0xc,%esp
f0101da0:	50                   	push   %eax
f0101da1:	e8 ab fd ff ff       	call   f0101b51 <Buddykfree>
	for (; p + PGSIZE <= (char *)vend; p += PGSIZE)
f0101da6:	83 c4 10             	add    $0x10,%esp
f0101da9:	89 f0                	mov    %esi,%eax
f0101dab:	8d b0 00 10 00 00    	lea    0x1000(%eax),%esi
f0101db1:	39 de                	cmp    %ebx,%esi
f0101db3:	76 e8                	jbe    f0101d9d <free_range+0x17>
		kfree(p);
}
f0101db5:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0101db8:	5b                   	pop    %ebx
f0101db9:	5e                   	pop    %esi
f0101dba:	5d                   	pop    %ebp
f0101dbb:	c3                   	ret    

f0101dbc <Buddyfree_range>:

void
Buddyfree_range(void *vstart, int level)
{
f0101dbc:	55                   	push   %ebp
f0101dbd:	89 e5                	mov    %esp,%ebp
f0101dbf:	57                   	push   %edi
f0101dc0:	56                   	push   %esi
f0101dc1:	53                   	push   %ebx
f0101dc2:	83 ec 0c             	sub    $0xc,%esp
f0101dc5:	8b 75 08             	mov    0x8(%ebp),%esi
f0101dc8:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	struct run *r;
	int id = ((void *)vstart >= (void *)base[1]) ? 1 : 0;
f0101dcb:	39 35 c4 3e 12 f0    	cmp    %esi,0xf0123ec4
f0101dd1:	0f 96 c0             	setbe  %al
f0101dd4:	0f b6 c0             	movzbl %al,%eax
f0101dd7:	89 c7                	mov    %eax,%edi

	memset(vstart, 1, PGSIZE * pow_2(level));
f0101dd9:	53                   	push   %ebx
f0101dda:	e8 55 fd ff ff       	call   f0101b34 <pow_2>
f0101ddf:	c1 e0 0c             	shl    $0xc,%eax
f0101de2:	50                   	push   %eax
f0101de3:	6a 01                	push   $0x1
f0101de5:	56                   	push   %esi
f0101de6:	e8 c0 19 00 00       	call   f01037ab <memset>
	r = (struct run *)vstart;
	//cprintf("%x, %x\n", Buddy[id][level].free_list->next, Buddy[id][level].free_list);
	r->next = Buddy[id].slot[level].free_list->next;
f0101deb:	6b c7 3c             	imul   $0x3c,%edi,%eax
f0101dee:	8b 90 e4 3e 12 f0    	mov    -0xfedc11c(%eax),%edx
f0101df4:	8b 14 da             	mov    (%edx,%ebx,8),%edx
f0101df7:	8b 12                	mov    (%edx),%edx
f0101df9:	89 16                	mov    %edx,(%esi)
	Buddy[id].slot[level].free_list->next = r;
f0101dfb:	8b 90 e4 3e 12 f0    	mov    -0xfedc11c(%eax),%edx
	r->next = Buddy[id].slot[level].free_list->next;
f0101e01:	05 e0 3e 12 f0       	add    $0xf0123ee0,%eax
	Buddy[id].slot[level].free_list->next = r;
f0101e06:	8b 14 da             	mov    (%edx,%ebx,8),%edx
f0101e09:	89 32                	mov    %esi,(%edx)
	//cprintf("%x, %x\n", Buddy[id][level].free_list->next, Buddy[id][level].free_list);
	Buddy[id].slot[level].num++;
f0101e0b:	8b 40 04             	mov    0x4(%eax),%eax
f0101e0e:	83 44 d8 04 01       	addl   $0x1,0x4(%eax,%ebx,8)
}
f0101e13:	83 c4 10             	add    $0x10,%esp
f0101e16:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101e19:	5b                   	pop    %ebx
f0101e1a:	5e                   	pop    %esi
f0101e1b:	5f                   	pop    %edi
f0101e1c:	5d                   	pop    %ebp
f0101e1d:	c3                   	ret    

f0101e1e <split>:
		return NULL;*/
}

void
split(char *r, int low, int high)
{
f0101e1e:	55                   	push   %ebp
f0101e1f:	89 e5                	mov    %esp,%ebp
f0101e21:	57                   	push   %edi
f0101e22:	56                   	push   %esi
f0101e23:	53                   	push   %ebx
f0101e24:	83 ec 10             	sub    $0x10,%esp
f0101e27:	8b 4d 10             	mov    0x10(%ebp),%ecx
	int size = 1 << high;
f0101e2a:	b8 01 00 00 00       	mov    $0x1,%eax
f0101e2f:	d3 e0                	shl    %cl,%eax
f0101e31:	89 45 f0             	mov    %eax,-0x10(%ebp)
	int id, idx;
	id = (void *)r >= (void *)base[1];
f0101e34:	8b 45 08             	mov    0x8(%ebp),%eax
f0101e37:	39 05 c4 3e 12 f0    	cmp    %eax,0xf0123ec4
f0101e3d:	0f 96 c0             	setbe  %al
f0101e40:	0f b6 c0             	movzbl %al,%eax
f0101e43:	89 c6                	mov    %eax,%esi
	idx = (uint32_t)((void *)r - (void *)base[id]) / PGSIZE;
f0101e45:	8b 45 08             	mov    0x8(%ebp),%eax
f0101e48:	2b 04 b5 c0 3e 12 f0 	sub    -0xfedc140(,%esi,4),%eax
f0101e4f:	c1 e8 0c             	shr    $0xc,%eax
f0101e52:	89 45 e8             	mov    %eax,-0x18(%ebp)
f0101e55:	8d 04 8d 00 00 00 00 	lea    0x0(,%ecx,4),%eax
f0101e5c:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101e5f:	8d 04 cd f8 ff ff ff 	lea    -0x8(,%ecx,8),%eax
		//cprintf("high: %x, pos: %x\n", high, start[high] + (idx >> high));
		high--;
		size >>= 1;
		struct run *p = (struct run *)((uint32_t)r + PGSIZE * size);
		//add high
		p->next = Buddy[id].slot[high].free_list->next;
f0101e66:	6b de 3c             	imul   $0x3c,%esi,%ebx
f0101e69:	81 c3 e0 3e 12 f0    	add    $0xf0123ee0,%ebx
f0101e6f:	89 75 e4             	mov    %esi,-0x1c(%ebp)
	while (high > low) {
f0101e72:	eb 54                	jmp    f0101ec8 <split+0xaa>
		order[id][start[id][high] + (idx >> high)] = 1;
f0101e74:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101e77:	8b 3c b5 68 3f 12 f0 	mov    -0xfedc098(,%esi,4),%edi
f0101e7e:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0101e81:	d3 fa                	sar    %cl,%edx
f0101e83:	03 14 b5 60 3f 12 f0 	add    -0xfedc0a0(,%esi,4),%edx
f0101e8a:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0101e8d:	03 14 37             	add    (%edi,%esi,1),%edx
f0101e90:	c6 02 01             	movb   $0x1,(%edx)
		high--;
f0101e93:	83 e9 01             	sub    $0x1,%ecx
		size >>= 1;
f0101e96:	d1 7d f0             	sarl   -0x10(%ebp)
f0101e99:	8b 7d f0             	mov    -0x10(%ebp),%edi
		struct run *p = (struct run *)((uint32_t)r + PGSIZE * size);
f0101e9c:	89 fa                	mov    %edi,%edx
f0101e9e:	c1 e2 0c             	shl    $0xc,%edx
f0101ea1:	03 55 08             	add    0x8(%ebp),%edx
		p->next = Buddy[id].slot[high].free_list->next;
f0101ea4:	8b 7b 04             	mov    0x4(%ebx),%edi
f0101ea7:	8b 3c 07             	mov    (%edi,%eax,1),%edi
f0101eaa:	8b 3f                	mov    (%edi),%edi
f0101eac:	89 3a                	mov    %edi,(%edx)
		Buddy[id].slot[high].free_list->next = p;
f0101eae:	8b 7b 04             	mov    0x4(%ebx),%edi
f0101eb1:	8b 3c 07             	mov    (%edi,%eax,1),%edi
f0101eb4:	89 17                	mov    %edx,(%edi)
		Buddy[id].slot[high].num++;
f0101eb6:	89 c2                	mov    %eax,%edx
f0101eb8:	03 53 04             	add    0x4(%ebx),%edx
f0101ebb:	83 42 04 01          	addl   $0x1,0x4(%edx)
f0101ebf:	83 ee 04             	sub    $0x4,%esi
f0101ec2:	89 75 ec             	mov    %esi,-0x14(%ebp)
f0101ec5:	83 e8 08             	sub    $0x8,%eax
	while (high > low) {
f0101ec8:	3b 4d 0c             	cmp    0xc(%ebp),%ecx
f0101ecb:	7f a7                	jg     f0101e74 <split+0x56>
f0101ecd:	8b 75 e4             	mov    -0x1c(%ebp),%esi
	}
	order[id][start[id][high] + (idx >> high)] = 1;
f0101ed0:	8b 14 b5 68 3f 12 f0 	mov    -0xfedc098(,%esi,4),%edx
f0101ed7:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0101eda:	d3 f8                	sar    %cl,%eax
f0101edc:	03 04 b5 60 3f 12 f0 	add    -0xfedc0a0(,%esi,4),%eax
f0101ee3:	03 04 8a             	add    (%edx,%ecx,4),%eax
f0101ee6:	c6 00 01             	movb   $0x1,(%eax)
	//cprintf("pos: %x\n", start[id][high] + (idx >> high));
}
f0101ee9:	83 c4 10             	add    $0x10,%esp
f0101eec:	5b                   	pop    %ebx
f0101eed:	5e                   	pop    %esi
f0101eee:	5f                   	pop    %edi
f0101eef:	5d                   	pop    %ebp
f0101ef0:	c3                   	ret    

f0101ef1 <Buddykalloc>:

char *
Buddykalloc(int order)
{
f0101ef1:	55                   	push   %ebp
f0101ef2:	89 e5                	mov    %esp,%ebp
f0101ef4:	57                   	push   %edi
f0101ef5:	56                   	push   %esi
f0101ef6:	53                   	push   %ebx
f0101ef7:	83 ec 1c             	sub    $0x1c,%esp
	for (int i = 0; i < 2; i++) {
		if (Buddy[i].use_lock)
f0101efa:	83 3d e0 3e 12 f0 00 	cmpl   $0x0,0xf0123ee0
f0101f01:	75 36                	jne    f0101f39 <Buddykalloc+0x48>
			spin_lock(&Buddy[i].lock);
		for (int currentorder = order; currentorder <= MAX_ORDER[i]; currentorder++)
f0101f03:	8b 35 70 3f 12 f0    	mov    0xf0123f70,%esi
f0101f09:	8b 45 08             	mov    0x8(%ebp),%eax
f0101f0c:	8d 1c c5 00 00 00 00 	lea    0x0(,%eax,8),%ebx
			if (Buddy[i].slot[currentorder].num > 0) {
f0101f13:	8b 3d e4 3e 12 f0    	mov    0xf0123ee4,%edi
f0101f19:	89 da                	mov    %ebx,%edx
		for (int currentorder = order; currentorder <= MAX_ORDER[i]; currentorder++)
f0101f1b:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0101f1e:	39 c6                	cmp    %eax,%esi
f0101f20:	7c 29                	jl     f0101f4b <Buddykalloc+0x5a>
			if (Buddy[i].slot[currentorder].num > 0) {
f0101f22:	8d 0c 17             	lea    (%edi,%edx,1),%ecx
f0101f25:	8d 5a 08             	lea    0x8(%edx),%ebx
f0101f28:	83 79 04 00          	cmpl   $0x0,0x4(%ecx)
f0101f2c:	0f 8f 84 00 00 00    	jg     f0101fb6 <Buddykalloc+0xc5>
		for (int currentorder = order; currentorder <= MAX_ORDER[i]; currentorder++)
f0101f32:	83 c0 01             	add    $0x1,%eax
f0101f35:	89 da                	mov    %ebx,%edx
f0101f37:	eb e5                	jmp    f0101f1e <Buddykalloc+0x2d>
			spin_lock(&Buddy[i].lock);
f0101f39:	83 ec 0c             	sub    $0xc,%esp
f0101f3c:	68 e8 3e 12 f0       	push   $0xf0123ee8
f0101f41:	e8 67 09 00 00       	call   f01028ad <spin_lock>
f0101f46:	83 c4 10             	add    $0x10,%esp
f0101f49:	eb b8                	jmp    f0101f03 <Buddykalloc+0x12>
f0101f4b:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
				split((char *)r, order, currentorder);
				if (Buddy[i].use_lock)
					spin_unlock(&Buddy[i].lock);
				return (char *)r;
			}
		if (Buddy[i].use_lock)
f0101f4e:	83 3d e0 3e 12 f0 00 	cmpl   $0x0,0xf0123ee0
f0101f55:	75 32                	jne    f0101f89 <Buddykalloc+0x98>
		if (Buddy[i].use_lock)
f0101f57:	83 3d 1c 3f 12 f0 00 	cmpl   $0x0,0xf0123f1c
f0101f5e:	75 3b                	jne    f0101f9b <Buddykalloc+0xaa>
		for (int currentorder = order; currentorder <= MAX_ORDER[i]; currentorder++)
f0101f60:	8b 35 74 3f 12 f0    	mov    0xf0123f74,%esi
f0101f66:	8b 45 08             	mov    0x8(%ebp),%eax
f0101f69:	39 c6                	cmp    %eax,%esi
f0101f6b:	0f 8c 98 00 00 00    	jl     f0102009 <Buddykalloc+0x118>
			if (Buddy[i].slot[currentorder].num > 0) {
f0101f71:	89 d9                	mov    %ebx,%ecx
f0101f73:	03 0d 20 3f 12 f0    	add    0xf0123f20,%ecx
f0101f79:	8d 53 08             	lea    0x8(%ebx),%edx
f0101f7c:	83 79 04 00          	cmpl   $0x0,0x4(%ecx)
f0101f80:	7f 2b                	jg     f0101fad <Buddykalloc+0xbc>
		for (int currentorder = order; currentorder <= MAX_ORDER[i]; currentorder++)
f0101f82:	83 c0 01             	add    $0x1,%eax
f0101f85:	89 d3                	mov    %edx,%ebx
f0101f87:	eb e0                	jmp    f0101f69 <Buddykalloc+0x78>
			spin_unlock(&Buddy[i].lock);
f0101f89:	83 ec 0c             	sub    $0xc,%esp
f0101f8c:	68 e8 3e 12 f0       	push   $0xf0123ee8
f0101f91:	e8 76 09 00 00       	call   f010290c <spin_unlock>
f0101f96:	83 c4 10             	add    $0x10,%esp
f0101f99:	eb bc                	jmp    f0101f57 <Buddykalloc+0x66>
			spin_lock(&Buddy[i].lock);
f0101f9b:	83 ec 0c             	sub    $0xc,%esp
f0101f9e:	68 24 3f 12 f0       	push   $0xf0123f24
f0101fa3:	e8 05 09 00 00       	call   f01028ad <spin_lock>
f0101fa8:	83 c4 10             	add    $0x10,%esp
f0101fab:	eb b3                	jmp    f0101f60 <Buddykalloc+0x6f>
			if (Buddy[i].slot[currentorder].num > 0) {
f0101fad:	89 da                	mov    %ebx,%edx
	for (int i = 0; i < 2; i++) {
f0101faf:	bf 01 00 00 00       	mov    $0x1,%edi
f0101fb4:	eb 05                	jmp    f0101fbb <Buddykalloc+0xca>
f0101fb6:	bf 00 00 00 00       	mov    $0x0,%edi
				r = Buddy[i].slot[currentorder].free_list->next;
f0101fbb:	8b 09                	mov    (%ecx),%ecx
f0101fbd:	8b 19                	mov    (%ecx),%ebx
				Buddy[i].slot[currentorder].free_list->next = r->next;
f0101fbf:	8b 33                	mov    (%ebx),%esi
f0101fc1:	89 31                	mov    %esi,(%ecx)
				Buddy[i].slot[currentorder].num--;
f0101fc3:	6b f7 3c             	imul   $0x3c,%edi,%esi
f0101fc6:	03 96 e4 3e 12 f0    	add    -0xfedc11c(%esi),%edx
f0101fcc:	83 6a 04 01          	subl   $0x1,0x4(%edx)
				split((char *)r, order, currentorder);
f0101fd0:	83 ec 04             	sub    $0x4,%esp
f0101fd3:	50                   	push   %eax
f0101fd4:	ff 75 08             	pushl  0x8(%ebp)
f0101fd7:	53                   	push   %ebx
f0101fd8:	e8 41 fe ff ff       	call   f0101e1e <split>
				if (Buddy[i].use_lock)
f0101fdd:	83 c4 10             	add    $0x10,%esp
f0101fe0:	83 be e0 3e 12 f0 00 	cmpl   $0x0,-0xfedc120(%esi)
f0101fe7:	75 0a                	jne    f0101ff3 <Buddykalloc+0x102>
	}
	return NULL;
}
f0101fe9:	89 d8                	mov    %ebx,%eax
f0101feb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101fee:	5b                   	pop    %ebx
f0101fef:	5e                   	pop    %esi
f0101ff0:	5f                   	pop    %edi
f0101ff1:	5d                   	pop    %ebp
f0101ff2:	c3                   	ret    
					spin_unlock(&Buddy[i].lock);
f0101ff3:	83 ec 0c             	sub    $0xc,%esp
f0101ff6:	89 f7                	mov    %esi,%edi
f0101ff8:	81 c7 e8 3e 12 f0    	add    $0xf0123ee8,%edi
f0101ffe:	57                   	push   %edi
f0101fff:	e8 08 09 00 00       	call   f010290c <spin_unlock>
f0102004:	83 c4 10             	add    $0x10,%esp
f0102007:	eb e0                	jmp    f0101fe9 <Buddykalloc+0xf8>
		if (Buddy[i].use_lock)
f0102009:	83 3d 1c 3f 12 f0 00 	cmpl   $0x0,0xf0123f1c
f0102010:	75 07                	jne    f0102019 <Buddykalloc+0x128>
	return NULL;
f0102012:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102017:	eb d0                	jmp    f0101fe9 <Buddykalloc+0xf8>
			spin_unlock(&Buddy[i].lock);
f0102019:	83 ec 0c             	sub    $0xc,%esp
f010201c:	68 24 3f 12 f0       	push   $0xf0123f24
f0102021:	e8 e6 08 00 00       	call   f010290c <spin_unlock>
f0102026:	83 c4 10             	add    $0x10,%esp
f0102029:	eb e7                	jmp    f0102012 <Buddykalloc+0x121>

f010202b <kalloc>:
{
f010202b:	55                   	push   %ebp
f010202c:	89 e5                	mov    %esp,%ebp
f010202e:	83 ec 14             	sub    $0x14,%esp
	return Buddykalloc(0);
f0102031:	6a 00                	push   $0x0
f0102033:	e8 b9 fe ff ff       	call   f0101ef1 <Buddykalloc>
}
f0102038:	c9                   	leave  
f0102039:	c3                   	ret    

f010203a <check_free_list>:
void
check_free_list(void)
{
	struct run *p;
	bool exist;
	for (int i = 0; i < 2; i++)
f010203a:	ba 00 00 00 00       	mov    $0x0,%edx
		for (int j = 0; j <= MAX_ORDER[i]; j++)
f010203f:	b8 00 00 00 00       	mov    $0x0,%eax
f0102044:	eb 03                	jmp    f0102049 <check_free_list+0xf>
f0102046:	83 c0 01             	add    $0x1,%eax
f0102049:	39 04 95 70 3f 12 f0 	cmp    %eax,-0xfedc090(,%edx,4)
f0102050:	7d f4                	jge    f0102046 <check_free_list+0xc>
	for (int i = 0; i < 2; i++)
f0102052:	83 c2 01             	add    $0x1,%edx
f0102055:	83 fa 01             	cmp    $0x1,%edx
f0102058:	7f 39                	jg     f0102093 <check_free_list+0x59>
		for (int j = 0; j <= MAX_ORDER[i]; j++)
f010205a:	b8 00 00 00 00       	mov    $0x0,%eax
f010205f:	eb e8                	jmp    f0102049 <check_free_list+0xf>

	//cprintf("end: 0x%x\n", end);

	for (p = kmem.free_list; p; p = p->next) {
		//cprintf("0x%x\n", p);
		assert((void *)p > (void *)end);
f0102061:	68 b4 3f 10 f0       	push   $0xf0103fb4
f0102066:	68 fe 3e 10 f0       	push   $0xf0103efe
f010206b:	68 89 01 00 00       	push   $0x189
f0102070:	68 a6 3f 10 f0       	push   $0xf0103fa6
f0102075:	e8 1e e1 ff ff       	call   f0100198 <_panic>
		for (int i = 4; i < 4096; i++) 
			assert(((char *)p)[i] == 1);
f010207a:	68 cc 3f 10 f0       	push   $0xf0103fcc
f010207f:	68 fe 3e 10 f0       	push   $0xf0103efe
f0102084:	68 8b 01 00 00       	push   $0x18b
f0102089:	68 a6 3f 10 f0       	push   $0xf0103fa6
f010208e:	e8 05 e1 ff ff       	call   f0100198 <_panic>
	for (p = kmem.free_list; p; p = p->next) {
f0102093:	8b 0d c8 3e 12 f0    	mov    0xf0123ec8,%ecx
f0102099:	85 c9                	test   %ecx,%ecx
f010209b:	74 2b                	je     f01020c8 <check_free_list+0x8e>
{
f010209d:	55                   	push   %ebp
f010209e:	89 e5                	mov    %esp,%ebp
f01020a0:	83 ec 08             	sub    $0x8,%esp
		assert((void *)p > (void *)end);
f01020a3:	81 f9 54 57 16 f0    	cmp    $0xf0165754,%ecx
f01020a9:	76 b6                	jbe    f0102061 <check_free_list+0x27>
f01020ab:	8d 41 04             	lea    0x4(%ecx),%eax
f01020ae:	8d 91 00 10 00 00    	lea    0x1000(%ecx),%edx
			assert(((char *)p)[i] == 1);
f01020b4:	80 38 01             	cmpb   $0x1,(%eax)
f01020b7:	75 c1                	jne    f010207a <check_free_list+0x40>
f01020b9:	83 c0 01             	add    $0x1,%eax
		for (int i = 4; i < 4096; i++) 
f01020bc:	39 d0                	cmp    %edx,%eax
f01020be:	75 f4                	jne    f01020b4 <check_free_list+0x7a>
	for (p = kmem.free_list; p; p = p->next) {
f01020c0:	8b 09                	mov    (%ecx),%ecx
f01020c2:	85 c9                	test   %ecx,%ecx
f01020c4:	75 dd                	jne    f01020a3 <check_free_list+0x69>
	}
}
f01020c6:	c9                   	leave  
f01020c7:	c3                   	ret    
f01020c8:	c3                   	ret    

f01020c9 <boot_alloc_init>:
{
f01020c9:	55                   	push   %ebp
f01020ca:	89 e5                	mov    %esp,%ebp
f01020cc:	57                   	push   %edi
f01020cd:	56                   	push   %esi
f01020ce:	53                   	push   %ebx
f01020cf:	83 ec 2c             	sub    $0x2c,%esp
			num = (uint32_t)((char *)P2V(4*1024*1024) - end) / PGSIZE;
f01020d2:	b8 00 00 40 f0       	mov    $0xf0400000,%eax
f01020d7:	2d 54 57 16 f0       	sub    $0xf0165754,%eax
	char *mystart = end;
f01020dc:	bf 54 57 16 f0       	mov    $0xf0165754,%edi
			num = (uint32_t)((char *)P2V(4*1024*1024) - end) / PGSIZE;
f01020e1:	c1 e8 0c             	shr    $0xc,%eax
f01020e4:	89 45 c8             	mov    %eax,-0x38(%ebp)
f01020e7:	c7 45 d0 e4 3e 12 f0 	movl   $0xf0123ee4,-0x30(%ebp)
f01020ee:	c7 45 cc 58 3f 12 f0 	movl   $0xf0123f58,-0x34(%ebp)
f01020f5:	8b 55 c8             	mov    -0x38(%ebp),%edx
f01020f8:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f01020ff:	e9 2c 01 00 00       	jmp    f0102230 <boot_alloc_init+0x167>
			sum *= 2;
f0102104:	01 c0                	add    %eax,%eax
			level++;
f0102106:	83 c6 01             	add    $0x1,%esi
		while (sum < num) {
f0102109:	39 c2                	cmp    %eax,%edx
f010210b:	7f f7                	jg     f0102104 <boot_alloc_init+0x3b>
			level--;
f010210d:	0f 9c c0             	setl   %al
f0102110:	0f b6 c0             	movzbl %al,%eax
f0102113:	29 c6                	sub    %eax,%esi
f0102115:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102118:	89 45 e0             	mov    %eax,-0x20(%ebp)
		order[i] = (bool *)mystart;
f010211b:	89 3c 85 60 3f 12 f0 	mov    %edi,-0xfedc0a0(,%eax,4)
		memset(order[i], 0, pow_2(level) * 2);
f0102122:	56                   	push   %esi
f0102123:	e8 0c fa ff ff       	call   f0101b34 <pow_2>
f0102128:	8d 1c 00             	lea    (%eax,%eax,1),%ebx
f010212b:	53                   	push   %ebx
f010212c:	6a 00                	push   $0x0
f010212e:	57                   	push   %edi
f010212f:	e8 77 16 00 00       	call   f01037ab <memset>
		mystart += pow_2(level) * 2;
f0102134:	01 fb                	add    %edi,%ebx
		MAX_ORDER[i] = level;
f0102136:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102139:	89 34 85 70 3f 12 f0 	mov    %esi,-0xfedc090(,%eax,4)
f0102140:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102143:	89 c7                	mov    %eax,%edi
		Buddy[i].slot = (struct Buddykmem *)mystart;
f0102145:	89 18                	mov    %ebx,(%eax)
		memset(Buddy[i].slot, 0, sizeof(struct Buddykmem) * (level + 1));
f0102147:	8d 46 01             	lea    0x1(%esi),%eax
f010214a:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010214d:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
f0102154:	83 c4 0c             	add    $0xc,%esp
f0102157:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f010215a:	51                   	push   %ecx
f010215b:	6a 00                	push   $0x0
f010215d:	53                   	push   %ebx
f010215e:	e8 48 16 00 00       	call   f01037ab <memset>
		mystart += sizeof(struct Buddykmem) * (level + 1);
f0102163:	03 5d e4             	add    -0x1c(%ebp),%ebx
f0102166:	89 d8                	mov    %ebx,%eax
f0102168:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f010216b:	89 cb                	mov    %ecx,%ebx
		linkbase[i] = (struct run *)mystart;
f010216d:	89 01                	mov    %eax,(%ecx)
		memset(linkbase[i], 0, sizeof(struct run) *(level + 1));
f010216f:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102172:	8d 0c 95 00 00 00 00 	lea    0x0(,%edx,4),%ecx
f0102179:	83 c4 0c             	add    $0xc,%esp
f010217c:	89 4d d8             	mov    %ecx,-0x28(%ebp)
f010217f:	51                   	push   %ecx
f0102180:	6a 00                	push   $0x0
f0102182:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102185:	50                   	push   %eax
f0102186:	e8 20 16 00 00       	call   f01037ab <memset>
		mystart += sizeof(struct run) *(level + 1);
f010218b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010218e:	03 45 d8             	add    -0x28(%ebp),%eax
f0102191:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		for (int j = 0; j <= level; j++) {
f0102194:	83 c4 10             	add    $0x10,%esp
f0102197:	b8 00 00 00 00       	mov    $0x0,%eax
f010219c:	eb 17                	jmp    f01021b5 <boot_alloc_init+0xec>
f010219e:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
			linkbase[i][j].next = &linkbase[i][j];
f01021a5:	89 d1                	mov    %edx,%ecx
f01021a7:	03 0b                	add    (%ebx),%ecx
f01021a9:	89 09                	mov    %ecx,(%ecx)
			Buddy[i].slot[j].free_list = &linkbase[i][j];
f01021ab:	8b 0f                	mov    (%edi),%ecx
f01021ad:	03 13                	add    (%ebx),%edx
f01021af:	89 14 c1             	mov    %edx,(%ecx,%eax,8)
		for (int j = 0; j <= level; j++) {
f01021b2:	83 c0 01             	add    $0x1,%eax
f01021b5:	39 c6                	cmp    %eax,%esi
f01021b7:	7d e5                	jge    f010219e <boot_alloc_init+0xd5>
		start[i] = (int *)mystart;
f01021b9:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01021bc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01021bf:	89 04 bd 68 3f 12 f0 	mov    %eax,-0xfedc098(,%edi,4)
		start[i][0] = 0;
f01021c6:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		for (int j = 0; j < level; j++)
f01021cc:	bb 00 00 00 00       	mov    $0x0,%ebx
f01021d1:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f01021d4:	eb 2c                	jmp    f0102202 <boot_alloc_init+0x139>
			start[i][j + 1] = start[i][j] + pow_2(level - j);
f01021d6:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01021d9:	8b 34 85 68 3f 12 f0 	mov    -0xfedc098(,%eax,4),%esi
f01021e0:	8d 3c 9d 00 00 00 00 	lea    0x0(,%ebx,4),%edi
f01021e7:	83 ec 0c             	sub    $0xc,%esp
f01021ea:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01021ed:	29 d8                	sub    %ebx,%eax
f01021ef:	50                   	push   %eax
f01021f0:	e8 3f f9 ff ff       	call   f0101b34 <pow_2>
f01021f5:	83 c4 10             	add    $0x10,%esp
f01021f8:	03 04 9e             	add    (%esi,%ebx,4),%eax
f01021fb:	89 44 3e 04          	mov    %eax,0x4(%esi,%edi,1)
		for (int j = 0; j < level; j++)
f01021ff:	83 c3 01             	add    $0x1,%ebx
f0102202:	39 5d e4             	cmp    %ebx,-0x1c(%ebp)
f0102205:	7f cf                	jg     f01021d6 <boot_alloc_init+0x10d>
		mystart += sizeof(int) * (level + 1);
f0102207:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010220a:	03 7d d8             	add    -0x28(%ebp),%edi
	for (int i = 0; i < 2; i++) {
f010220d:	83 45 dc 01          	addl   $0x1,-0x24(%ebp)
f0102211:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102214:	83 f8 01             	cmp    $0x1,%eax
f0102217:	7f 26                	jg     f010223f <boot_alloc_init+0x176>
f0102219:	83 45 d0 3c          	addl   $0x3c,-0x30(%ebp)
f010221d:	83 45 cc 04          	addl   $0x4,-0x34(%ebp)
			num = (uint32_t)((char *)PHYSTOP - 4*1024*1024) / PGSIZE;
f0102221:	ba 00 dc 00 00       	mov    $0xdc00,%edx
		if (i == 0)
f0102226:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010222a:	0f 84 b7 fe ff ff    	je     f01020e7 <boot_alloc_init+0x1e>
		int sum = 1;
f0102230:	b8 01 00 00 00       	mov    $0x1,%eax
		int level = 0;
f0102235:	be 00 00 00 00       	mov    $0x0,%esi
		while (sum < num) {
f010223a:	e9 ca fe ff ff       	jmp    f0102109 <boot_alloc_init+0x40>
	base[0] = (struct run *)ROUNDUP(mystart, PGSIZE);
f010223f:	81 c7 ff 0f 00 00    	add    $0xfff,%edi
f0102245:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
f010224b:	89 3d c0 3e 12 f0    	mov    %edi,0xf0123ec0
	base[1] = (struct run *)P2V(4 * 1024 * 1024);
f0102251:	c7 05 c4 3e 12 f0 00 	movl   $0xf0400000,0xf0123ec4
f0102258:	00 40 f0 
		Buddy[i].use_lock = 0;
f010225b:	c7 05 e0 3e 12 f0 00 	movl   $0x0,0xf0123ee0
f0102262:	00 00 00 
		__spin_initlock(&Buddy[i].lock, name);
f0102265:	83 ec 08             	sub    $0x8,%esp
f0102268:	68 e0 3f 10 f0       	push   $0xf0103fe0
f010226d:	68 e8 3e 12 f0       	push   $0xf0123ee8
f0102272:	e8 1b 06 00 00       	call   f0102892 <__spin_initlock>
		Buddy[i].use_lock = 0;
f0102277:	c7 05 1c 3f 12 f0 00 	movl   $0x0,0xf0123f1c
f010227e:	00 00 00 
		__spin_initlock(&Buddy[i].lock, name);
f0102281:	83 c4 08             	add    $0x8,%esp
f0102284:	68 e0 3f 10 f0       	push   $0xf0103fe0
f0102289:	68 24 3f 12 f0       	push   $0xf0123f24
f010228e:	e8 ff 05 00 00       	call   f0102892 <__spin_initlock>
	Buddyfree_range((void *)base[0], MAX_ORDER[0]);
f0102293:	83 c4 08             	add    $0x8,%esp
f0102296:	ff 35 70 3f 12 f0    	pushl  0xf0123f70
f010229c:	ff 35 c0 3e 12 f0    	pushl  0xf0123ec0
f01022a2:	e8 15 fb ff ff       	call   f0101dbc <Buddyfree_range>
	check_free_list();
f01022a7:	e8 8e fd ff ff       	call   f010203a <check_free_list>
}
f01022ac:	83 c4 10             	add    $0x10,%esp
f01022af:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01022b2:	5b                   	pop    %ebx
f01022b3:	5e                   	pop    %esi
f01022b4:	5f                   	pop    %edi
f01022b5:	5d                   	pop    %ebp
f01022b6:	c3                   	ret    

f01022b7 <alloc_init>:
{
f01022b7:	55                   	push   %ebp
f01022b8:	89 e5                	mov    %esp,%ebp
f01022ba:	83 ec 10             	sub    $0x10,%esp
	Buddyfree_range((void *)base[1], MAX_ORDER[1]);
f01022bd:	ff 35 74 3f 12 f0    	pushl  0xf0123f74
f01022c3:	ff 35 c4 3e 12 f0    	pushl  0xf0123ec4
f01022c9:	e8 ee fa ff ff       	call   f0101dbc <Buddyfree_range>
		Buddy[i].use_lock = 1;
f01022ce:	c7 05 e0 3e 12 f0 01 	movl   $0x1,0xf0123ee0
f01022d5:	00 00 00 
f01022d8:	c7 05 1c 3f 12 f0 01 	movl   $0x1,0xf0123f1c
f01022df:	00 00 00 
	check_free_list();
f01022e2:	e8 53 fd ff ff       	call   f010203a <check_free_list>
}
f01022e7:	83 c4 10             	add    $0x10,%esp
f01022ea:	c9                   	leave  
f01022eb:	c3                   	ret    

f01022ec <mpentry_start>:
.set PROT_MODE_DSEG, 0x10	# kernel data segment selector

.code16           
.globl mpentry_start
mpentry_start:
	cli            
f01022ec:	fa                   	cli    

	xorw    %ax, %ax
f01022ed:	31 c0                	xor    %eax,%eax
	movw    %ax, %ds
f01022ef:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f01022f1:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f01022f3:	8e d0                	mov    %eax,%ss

	lgdt    MPBOOTPHYS(gdtdesc)
f01022f5:	0f 01 16             	lgdtl  (%esi)
f01022f8:	74 70                	je     f010236a <mpsearch1+0x3>
	movl    %cr0, %eax
f01022fa:	0f 20 c0             	mov    %cr0,%eax
	orl     $CR0_PE, %eax
f01022fd:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
f0102301:	0f 22 c0             	mov    %eax,%cr0

	ljmpl   $(PROT_MODE_CSEG), $(MPBOOTPHYS(start32))
f0102304:	66 ea 20 70 00 00    	ljmpw  $0x0,$0x7020
f010230a:	08 00                	or     %al,(%eax)

f010230c <start32>:

.code32
start32:
	movw    $(PROT_MODE_DSEG), %ax
f010230c:	66 b8 10 00          	mov    $0x10,%ax
	movw    %ax, %ds
f0102310:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0102312:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0102314:	8e d0                	mov    %eax,%ss
	movw    $0, %ax
f0102316:	66 b8 00 00          	mov    $0x0,%ax
	movw    %ax, %fs
f010231a:	8e e0                	mov    %eax,%fs
	movw    %ax, %gs
f010231c:	8e e8                	mov    %eax,%gs

	# Set up initial page table. We cannot use kern_pgdir yet because
	# we are still running at a low EIP.
	movl    $(RELOC(entry_pgdir)), %eax
f010231e:	b8 00 a0 11 00       	mov    $0x11a000,%eax
	movl    %eax, %cr3
f0102323:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl    %cr0, %eax
f0102326:	0f 20 c0             	mov    %cr0,%eax
	orl     $(CR0_PE|CR0_PG|CR0_WP), %eax
f0102329:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl    %eax, %cr0
f010232e:	0f 22 c0             	mov    %eax,%cr0

	# Switch to the per-cpu stack allocated in boot_aps()
	movl    mpentry_kstack, %esp
f0102331:	8b 25 48 36 12 f0    	mov    0xf0123648,%esp
	movl    $0x0, %ebp       # nuke frame pointer
f0102337:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Call mp_main().  (Exercise for the reader: why the indirect call?)
	movl    $mp_main, %eax
f010233c:	b8 4c 01 10 f0       	mov    $0xf010014c,%eax
	call    *%eax
f0102341:	ff d0                	call   *%eax

f0102343 <spin>:

	# If mp_main returns (it shouldn't), loop.
spin:
	jmp     spin
f0102343:	eb fe                	jmp    f0102343 <spin>
f0102345:	8d 76 00             	lea    0x0(%esi),%esi

f0102348 <gdt>:
	...
f0102350:	ff                   	(bad)  
f0102351:	ff 00                	incl   (%eax)
f0102353:	00 00                	add    %al,(%eax)
f0102355:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
f010235c:	00                   	.byte 0x0
f010235d:	92                   	xchg   %eax,%edx
f010235e:	cf                   	iret   
	...

f0102360 <gdtdesc>:
f0102360:	17                   	pop    %ss
f0102361:	00 5c 70 00          	add    %bl,0x0(%eax,%esi,2)
	...

f0102366 <mpentry_end>:
	.word   0x17				# sizeof(gdt) - 1
	.long   MPBOOTPHYS(gdt)			# address gdt

.globl mpentry_end
mpentry_end:
	nop
f0102366:	90                   	nop

f0102367 <mpsearch1>:
}

// Look for an MP structure in the len bytes at physical address addr.
static struct mp *
mpsearch1(physaddr_t a, int len)
{
f0102367:	55                   	push   %ebp
f0102368:	89 e5                	mov    %esp,%ebp
f010236a:	57                   	push   %edi
f010236b:	56                   	push   %esi
f010236c:	53                   	push   %ebx
f010236d:	83 ec 0c             	sub    $0xc,%esp
	struct mp *mp = P2V(a), *end = P2V(a + len);
f0102370:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
f0102376:	8d b4 10 00 00 00 f0 	lea    -0x10000000(%eax,%edx,1),%esi

	for (; mp < end; mp++)
f010237d:	eb 03                	jmp    f0102382 <mpsearch1+0x1b>
f010237f:	83 c3 10             	add    $0x10,%ebx
f0102382:	39 f3                	cmp    %esi,%ebx
f0102384:	73 2e                	jae    f01023b4 <mpsearch1+0x4d>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0102386:	83 ec 04             	sub    $0x4,%esp
f0102389:	6a 04                	push   $0x4
f010238b:	68 ea 3f 10 f0       	push   $0xf0103fea
f0102390:	53                   	push   %ebx
f0102391:	e8 dd 14 00 00       	call   f0103873 <memcmp>
f0102396:	83 c4 10             	add    $0x10,%esp
f0102399:	85 c0                	test   %eax,%eax
f010239b:	75 e2                	jne    f010237f <mpsearch1+0x18>
f010239d:	89 da                	mov    %ebx,%edx
f010239f:	8d 7b 10             	lea    0x10(%ebx),%edi
		sum += ((uint8_t *)addr)[i];
f01023a2:	0f b6 0a             	movzbl (%edx),%ecx
f01023a5:	01 c8                	add    %ecx,%eax
f01023a7:	83 c2 01             	add    $0x1,%edx
	for (i = 0; i < len; i++)
f01023aa:	39 fa                	cmp    %edi,%edx
f01023ac:	75 f4                	jne    f01023a2 <mpsearch1+0x3b>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f01023ae:	84 c0                	test   %al,%al
f01023b0:	75 cd                	jne    f010237f <mpsearch1+0x18>
f01023b2:	eb 05                	jmp    f01023b9 <mpsearch1+0x52>
		    sum(mp, sizeof(*mp)) == 0)
			return mp;
	return NULL;
f01023b4:	bb 00 00 00 00       	mov    $0x0,%ebx
}
f01023b9:	89 d8                	mov    %ebx,%eax
f01023bb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01023be:	5b                   	pop    %ebx
f01023bf:	5e                   	pop    %esi
f01023c0:	5f                   	pop    %edi
f01023c1:	5d                   	pop    %ebp
f01023c2:	c3                   	ret    

f01023c3 <mp_init>:
	return conf;
}

void
mp_init(void)
{
f01023c3:	55                   	push   %ebp
f01023c4:	89 e5                	mov    %esp,%ebp
f01023c6:	57                   	push   %edi
f01023c7:	56                   	push   %esi
f01023c8:	53                   	push   %ebx
f01023c9:	83 ec 1c             	sub    $0x1c,%esp
	struct mpconf *conf;
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
f01023cc:	c7 05 e0 45 12 f0 20 	movl   $0xf0124020,0xf01245e0
f01023d3:	40 12 f0 
	if ((p = *(uint16_t *) (bda + 0x0E))) {
f01023d6:	0f b7 05 0e 04 00 f0 	movzwl 0xf000040e,%eax
f01023dd:	85 c0                	test   %eax,%eax
f01023df:	74 53                	je     f0102434 <mp_init+0x71>
		p <<= 4;	// Translate from segment to PA
f01023e1:	c1 e0 04             	shl    $0x4,%eax
		if ((mp = mpsearch1(p, 1024)))
f01023e4:	ba 00 04 00 00       	mov    $0x400,%edx
f01023e9:	e8 79 ff ff ff       	call   f0102367 <mpsearch1>
f01023ee:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01023f1:	85 c0                	test   %eax,%eax
f01023f3:	74 5f                	je     f0102454 <mp_init+0x91>
	if (mp->physaddr == 0 || mp->type != 0) {
f01023f5:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01023f8:	8b 41 04             	mov    0x4(%ecx),%eax
f01023fb:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01023fe:	85 c0                	test   %eax,%eax
f0102400:	74 6d                	je     f010246f <mp_init+0xac>
f0102402:	80 79 0b 00          	cmpb   $0x0,0xb(%ecx)
f0102406:	75 67                	jne    f010246f <mp_init+0xac>
	conf = (struct mpconf *) P2V(mp->physaddr);
f0102408:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010240b:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
f0102411:	89 de                	mov    %ebx,%esi
	if (memcmp(conf, "PCMP", 4) != 0) {
f0102413:	83 ec 04             	sub    $0x4,%esp
f0102416:	6a 04                	push   $0x4
f0102418:	68 ef 3f 10 f0       	push   $0xf0103fef
f010241d:	53                   	push   %ebx
f010241e:	e8 50 14 00 00       	call   f0103873 <memcmp>
f0102423:	83 c4 10             	add    $0x10,%esp
f0102426:	85 c0                	test   %eax,%eax
f0102428:	75 5a                	jne    f0102484 <mp_init+0xc1>
f010242a:	0f b7 7b 04          	movzwl 0x4(%ebx),%edi
f010242e:	01 df                	add    %ebx,%edi
	sum = 0;
f0102430:	89 c2                	mov    %eax,%edx
f0102432:	eb 6d                	jmp    f01024a1 <mp_init+0xde>
		p = *(uint16_t *) (bda + 0x13) * 1024;
f0102434:	0f b7 05 13 04 00 f0 	movzwl 0xf0000413,%eax
f010243b:	c1 e0 0a             	shl    $0xa,%eax
		if ((mp = mpsearch1(p - 1024, 1024)))
f010243e:	2d 00 04 00 00       	sub    $0x400,%eax
f0102443:	ba 00 04 00 00       	mov    $0x400,%edx
f0102448:	e8 1a ff ff ff       	call   f0102367 <mpsearch1>
f010244d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102450:	85 c0                	test   %eax,%eax
f0102452:	75 a1                	jne    f01023f5 <mp_init+0x32>
	return mpsearch1(0xF0000, 0x10000);
f0102454:	ba 00 00 01 00       	mov    $0x10000,%edx
f0102459:	b8 00 00 0f 00       	mov    $0xf0000,%eax
f010245e:	e8 04 ff ff ff       	call   f0102367 <mpsearch1>
f0102463:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	if ((mp = mpsearch()) == 0)
f0102466:	85 c0                	test   %eax,%eax
f0102468:	75 8b                	jne    f01023f5 <mp_init+0x32>
f010246a:	e9 97 01 00 00       	jmp    f0102606 <mp_init+0x243>
		cprintf("SMP: Default configurations not implemented\n");
f010246f:	83 ec 0c             	sub    $0xc,%esp
f0102472:	68 14 40 10 f0       	push   $0xf0104014
f0102477:	e8 06 e3 ff ff       	call   f0100782 <cprintf>
f010247c:	83 c4 10             	add    $0x10,%esp
f010247f:	e9 82 01 00 00       	jmp    f0102606 <mp_init+0x243>
		cprintf("SMP: Incorrect MP configuration table signature\n");
f0102484:	83 ec 0c             	sub    $0xc,%esp
f0102487:	68 44 40 10 f0       	push   $0xf0104044
f010248c:	e8 f1 e2 ff ff       	call   f0100782 <cprintf>
f0102491:	83 c4 10             	add    $0x10,%esp
f0102494:	e9 6d 01 00 00       	jmp    f0102606 <mp_init+0x243>
		sum += ((uint8_t *)addr)[i];
f0102499:	0f b6 0b             	movzbl (%ebx),%ecx
f010249c:	01 ca                	add    %ecx,%edx
f010249e:	83 c3 01             	add    $0x1,%ebx
	for (i = 0; i < len; i++)
f01024a1:	39 fb                	cmp    %edi,%ebx
f01024a3:	75 f4                	jne    f0102499 <mp_init+0xd6>
	if (sum(conf, conf->length) != 0) {
f01024a5:	84 d2                	test   %dl,%dl
f01024a7:	75 16                	jne    f01024bf <mp_init+0xfc>
	if (conf->version != 1 && conf->version != 4) {
f01024a9:	0f b6 56 06          	movzbl 0x6(%esi),%edx
f01024ad:	80 fa 01             	cmp    $0x1,%dl
f01024b0:	74 05                	je     f01024b7 <mp_init+0xf4>
f01024b2:	80 fa 04             	cmp    $0x4,%dl
f01024b5:	75 1d                	jne    f01024d4 <mp_init+0x111>
f01024b7:	0f b7 4e 28          	movzwl 0x28(%esi),%ecx
f01024bb:	01 d9                	add    %ebx,%ecx
f01024bd:	eb 36                	jmp    f01024f5 <mp_init+0x132>
		cprintf("SMP: Bad MP configuration checksum\n");
f01024bf:	83 ec 0c             	sub    $0xc,%esp
f01024c2:	68 78 40 10 f0       	push   $0xf0104078
f01024c7:	e8 b6 e2 ff ff       	call   f0100782 <cprintf>
f01024cc:	83 c4 10             	add    $0x10,%esp
f01024cf:	e9 32 01 00 00       	jmp    f0102606 <mp_init+0x243>
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
f01024d4:	83 ec 08             	sub    $0x8,%esp
f01024d7:	0f b6 d2             	movzbl %dl,%edx
f01024da:	52                   	push   %edx
f01024db:	68 9c 40 10 f0       	push   $0xf010409c
f01024e0:	e8 9d e2 ff ff       	call   f0100782 <cprintf>
f01024e5:	83 c4 10             	add    $0x10,%esp
f01024e8:	e9 19 01 00 00       	jmp    f0102606 <mp_init+0x243>
		sum += ((uint8_t *)addr)[i];
f01024ed:	0f b6 13             	movzbl (%ebx),%edx
f01024f0:	01 d0                	add    %edx,%eax
f01024f2:	83 c3 01             	add    $0x1,%ebx
	for (i = 0; i < len; i++)
f01024f5:	39 d9                	cmp    %ebx,%ecx
f01024f7:	75 f4                	jne    f01024ed <mp_init+0x12a>
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f01024f9:	02 46 2a             	add    0x2a(%esi),%al
f01024fc:	75 29                	jne    f0102527 <mp_init+0x164>
	if ((conf = mpconfig(&mp)) == 0)
f01024fe:	81 7d e0 00 00 00 10 	cmpl   $0x10000000,-0x20(%ebp)
f0102505:	0f 84 fb 00 00 00    	je     f0102606 <mp_init+0x243>
		return;
	ismp = 1;
f010250b:	c7 05 00 40 12 f0 01 	movl   $0x1,0xf0124000
f0102512:	00 00 00 
	lapicaddr = conf->lapicaddr;
f0102515:	8b 46 24             	mov    0x24(%esi),%eax
f0102518:	a3 00 50 16 f0       	mov    %eax,0xf0165000

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f010251d:	8d 7e 2c             	lea    0x2c(%esi),%edi
f0102520:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102525:	eb 53                	jmp    f010257a <mp_init+0x1b7>
		cprintf("SMP: Bad MP configuration extended checksum\n");
f0102527:	83 ec 0c             	sub    $0xc,%esp
f010252a:	68 bc 40 10 f0       	push   $0xf01040bc
f010252f:	e8 4e e2 ff ff       	call   f0100782 <cprintf>
f0102534:	83 c4 10             	add    $0x10,%esp
f0102537:	e9 ca 00 00 00       	jmp    f0102606 <mp_init+0x243>
		switch (*p) {
		case MPPROC:
			proc = (struct mpproc *)p;
			if (proc->flags & MPPROC_BOOT)
f010253c:	f6 47 03 02          	testb  $0x2,0x3(%edi)
f0102540:	74 14                	je     f0102556 <mp_init+0x193>
				bootcpu = &cpus[ncpu];
f0102542:	69 05 e4 45 12 f0 b8 	imul   $0xb8,0xf01245e4,%eax
f0102549:	00 00 00 
f010254c:	05 20 40 12 f0       	add    $0xf0124020,%eax
f0102551:	a3 e0 45 12 f0       	mov    %eax,0xf01245e0
			if (ncpu < NCPU) {
f0102556:	a1 e4 45 12 f0       	mov    0xf01245e4,%eax
f010255b:	83 f8 07             	cmp    $0x7,%eax
f010255e:	7f 32                	jg     f0102592 <mp_init+0x1cf>
				cpus[ncpu].cpu_id = ncpu;
f0102560:	69 d0 b8 00 00 00    	imul   $0xb8,%eax,%edx
f0102566:	88 82 20 40 12 f0    	mov    %al,-0xfedbfe0(%edx)
				ncpu++;
f010256c:	83 c0 01             	add    $0x1,%eax
f010256f:	a3 e4 45 12 f0       	mov    %eax,0xf01245e4
			} else {
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
					proc->apicid);
			}
			p += sizeof(struct mpproc);
f0102574:	83 c7 14             	add    $0x14,%edi
	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0102577:	83 c3 01             	add    $0x1,%ebx
f010257a:	0f b7 46 22          	movzwl 0x22(%esi),%eax
f010257e:	39 d8                	cmp    %ebx,%eax
f0102580:	76 4b                	jbe    f01025cd <mp_init+0x20a>
		switch (*p) {
f0102582:	0f b6 07             	movzbl (%edi),%eax
f0102585:	84 c0                	test   %al,%al
f0102587:	74 b3                	je     f010253c <mp_init+0x179>
f0102589:	3c 04                	cmp    $0x4,%al
f010258b:	77 1c                	ja     f01025a9 <mp_init+0x1e6>
			continue;
		case MPBUS:
		case MPIOAPIC:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
f010258d:	83 c7 08             	add    $0x8,%edi
			continue;
f0102590:	eb e5                	jmp    f0102577 <mp_init+0x1b4>
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
f0102592:	83 ec 08             	sub    $0x8,%esp
f0102595:	0f b6 47 01          	movzbl 0x1(%edi),%eax
f0102599:	50                   	push   %eax
f010259a:	68 ec 40 10 f0       	push   $0xf01040ec
f010259f:	e8 de e1 ff ff       	call   f0100782 <cprintf>
f01025a4:	83 c4 10             	add    $0x10,%esp
f01025a7:	eb cb                	jmp    f0102574 <mp_init+0x1b1>
		default:
			cprintf("mpinit: unknown config type %x\n", *p);
f01025a9:	83 ec 08             	sub    $0x8,%esp
		switch (*p) {
f01025ac:	0f b6 c0             	movzbl %al,%eax
			cprintf("mpinit: unknown config type %x\n", *p);
f01025af:	50                   	push   %eax
f01025b0:	68 14 41 10 f0       	push   $0xf0104114
f01025b5:	e8 c8 e1 ff ff       	call   f0100782 <cprintf>
			ismp = 0;
f01025ba:	c7 05 00 40 12 f0 00 	movl   $0x0,0xf0124000
f01025c1:	00 00 00 
			i = conf->entry;
f01025c4:	0f b7 5e 22          	movzwl 0x22(%esi),%ebx
f01025c8:	83 c4 10             	add    $0x10,%esp
f01025cb:	eb aa                	jmp    f0102577 <mp_init+0x1b4>
		}
	}

	bootcpu->cpu_status = CPU_STARTED;
f01025cd:	a1 e0 45 12 f0       	mov    0xf01245e0,%eax
f01025d2:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	if (!ismp) {
f01025d9:	83 3d 00 40 12 f0 00 	cmpl   $0x0,0xf0124000
f01025e0:	75 2c                	jne    f010260e <mp_init+0x24b>
		// Didn't like what we found; fall back to no MP.
		ncpu = 1;
f01025e2:	c7 05 e4 45 12 f0 01 	movl   $0x1,0xf01245e4
f01025e9:	00 00 00 
		lapicaddr = 0;
f01025ec:	c7 05 00 50 16 f0 00 	movl   $0x0,0xf0165000
f01025f3:	00 00 00 
		cprintf("SMP: configuration not found, SMP disabled\n");
f01025f6:	83 ec 0c             	sub    $0xc,%esp
f01025f9:	68 34 41 10 f0       	push   $0xf0104134
f01025fe:	e8 7f e1 ff ff       	call   f0100782 <cprintf>
		return;
f0102603:	83 c4 10             	add    $0x10,%esp
		// switch to getting interrupts from the LAPIC.
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
		outb(0x22, 0x70);   // Select IMCR
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
	}
}
f0102606:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102609:	5b                   	pop    %ebx
f010260a:	5e                   	pop    %esi
f010260b:	5f                   	pop    %edi
f010260c:	5d                   	pop    %ebp
f010260d:	c3                   	ret    
	cprintf("SMP: CPU %d found %d CPU(s)\n", bootcpu->cpu_id,  ncpu);
f010260e:	83 ec 04             	sub    $0x4,%esp
f0102611:	ff 35 e4 45 12 f0    	pushl  0xf01245e4
f0102617:	0f b6 00             	movzbl (%eax),%eax
f010261a:	50                   	push   %eax
f010261b:	68 f4 3f 10 f0       	push   $0xf0103ff4
f0102620:	e8 5d e1 ff ff       	call   f0100782 <cprintf>
	if (mp->imcrp) {
f0102625:	83 c4 10             	add    $0x10,%esp
f0102628:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010262b:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
f010262f:	74 d5                	je     f0102606 <mp_init+0x243>
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
f0102631:	83 ec 0c             	sub    $0xc,%esp
f0102634:	68 60 41 10 f0       	push   $0xf0104160
f0102639:	e8 44 e1 ff ff       	call   f0100782 <cprintf>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010263e:	b8 70 00 00 00       	mov    $0x70,%eax
f0102643:	ba 22 00 00 00       	mov    $0x22,%edx
f0102648:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102649:	ba 23 00 00 00       	mov    $0x23,%edx
f010264e:	ec                   	in     (%dx),%al
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
f010264f:	83 c8 01             	or     $0x1,%eax
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102652:	ee                   	out    %al,(%dx)
f0102653:	83 c4 10             	add    $0x10,%esp
f0102656:	eb ae                	jmp    f0102606 <mp_init+0x243>

f0102658 <lapicw>:
physaddr_t lapicaddr;        // Initialized in mpconfig.c
volatile uint32_t *lapic;

static void
lapicw(int index, int value)
{
f0102658:	55                   	push   %ebp
f0102659:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
f010265b:	8b 0d 04 50 16 f0    	mov    0xf0165004,%ecx
f0102661:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f0102664:	89 10                	mov    %edx,(%eax)
	lapic[ID];  // wait for write to finish, by reading
f0102666:	a1 04 50 16 f0       	mov    0xf0165004,%eax
f010266b:	8b 40 20             	mov    0x20(%eax),%eax
}
f010266e:	5d                   	pop    %ebp
f010266f:	c3                   	ret    

f0102670 <cpunum>:
	lapicw(TPR, 0);
}

int
cpunum(void)
{
f0102670:	55                   	push   %ebp
f0102671:	89 e5                	mov    %esp,%ebp
	if (lapic)
f0102673:	8b 15 04 50 16 f0    	mov    0xf0165004,%edx
		return lapic[ID] >> 24;
	return 0;
f0102679:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lapic)
f010267e:	85 d2                	test   %edx,%edx
f0102680:	74 06                	je     f0102688 <cpunum+0x18>
		return lapic[ID] >> 24;
f0102682:	8b 42 20             	mov    0x20(%edx),%eax
f0102685:	c1 e8 18             	shr    $0x18,%eax
}
f0102688:	5d                   	pop    %ebp
f0102689:	c3                   	ret    

f010268a <lapic_init>:
	if (!lapicaddr)
f010268a:	a1 00 50 16 f0       	mov    0xf0165000,%eax
f010268f:	85 c0                	test   %eax,%eax
f0102691:	75 02                	jne    f0102695 <lapic_init+0xb>
f0102693:	f3 c3                	repz ret 
{
f0102695:	55                   	push   %ebp
f0102696:	89 e5                	mov    %esp,%ebp
	lapic = (uint32_t *)lapicaddr;
f0102698:	a3 04 50 16 f0       	mov    %eax,0xf0165004
	lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
f010269d:	ba 3f 01 00 00       	mov    $0x13f,%edx
f01026a2:	b8 3c 00 00 00       	mov    $0x3c,%eax
f01026a7:	e8 ac ff ff ff       	call   f0102658 <lapicw>
	lapicw(TDCR, X1);
f01026ac:	ba 0b 00 00 00       	mov    $0xb,%edx
f01026b1:	b8 f8 00 00 00       	mov    $0xf8,%eax
f01026b6:	e8 9d ff ff ff       	call   f0102658 <lapicw>
	lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
f01026bb:	ba 20 00 02 00       	mov    $0x20020,%edx
f01026c0:	b8 c8 00 00 00       	mov    $0xc8,%eax
f01026c5:	e8 8e ff ff ff       	call   f0102658 <lapicw>
	lapicw(TICR, 10000000); 
f01026ca:	ba 80 96 98 00       	mov    $0x989680,%edx
f01026cf:	b8 e0 00 00 00       	mov    $0xe0,%eax
f01026d4:	e8 7f ff ff ff       	call   f0102658 <lapicw>
	if (thiscpu != bootcpu)
f01026d9:	e8 92 ff ff ff       	call   f0102670 <cpunum>
f01026de:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f01026e4:	05 20 40 12 f0       	add    $0xf0124020,%eax
f01026e9:	39 05 e0 45 12 f0    	cmp    %eax,0xf01245e0
f01026ef:	74 0f                	je     f0102700 <lapic_init+0x76>
		lapicw(LINT0, MASKED);
f01026f1:	ba 00 00 01 00       	mov    $0x10000,%edx
f01026f6:	b8 d4 00 00 00       	mov    $0xd4,%eax
f01026fb:	e8 58 ff ff ff       	call   f0102658 <lapicw>
	lapicw(LINT1, MASKED);
f0102700:	ba 00 00 01 00       	mov    $0x10000,%edx
f0102705:	b8 d8 00 00 00       	mov    $0xd8,%eax
f010270a:	e8 49 ff ff ff       	call   f0102658 <lapicw>
	if (((lapic[VER]>>16) & 0xFF) >= 4)
f010270f:	a1 04 50 16 f0       	mov    0xf0165004,%eax
f0102714:	8b 40 30             	mov    0x30(%eax),%eax
f0102717:	c1 e8 10             	shr    $0x10,%eax
f010271a:	3c 03                	cmp    $0x3,%al
f010271c:	77 7c                	ja     f010279a <lapic_init+0x110>
	lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
f010271e:	ba 33 00 00 00       	mov    $0x33,%edx
f0102723:	b8 dc 00 00 00       	mov    $0xdc,%eax
f0102728:	e8 2b ff ff ff       	call   f0102658 <lapicw>
	lapicw(ESR, 0);
f010272d:	ba 00 00 00 00       	mov    $0x0,%edx
f0102732:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0102737:	e8 1c ff ff ff       	call   f0102658 <lapicw>
	lapicw(ESR, 0);
f010273c:	ba 00 00 00 00       	mov    $0x0,%edx
f0102741:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0102746:	e8 0d ff ff ff       	call   f0102658 <lapicw>
	lapicw(EOI, 0);
f010274b:	ba 00 00 00 00       	mov    $0x0,%edx
f0102750:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0102755:	e8 fe fe ff ff       	call   f0102658 <lapicw>
	lapicw(ICRHI, 0);
f010275a:	ba 00 00 00 00       	mov    $0x0,%edx
f010275f:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0102764:	e8 ef fe ff ff       	call   f0102658 <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
f0102769:	ba 00 85 08 00       	mov    $0x88500,%edx
f010276e:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0102773:	e8 e0 fe ff ff       	call   f0102658 <lapicw>
	while(lapic[ICRLO] & DELIVS)
f0102778:	8b 15 04 50 16 f0    	mov    0xf0165004,%edx
f010277e:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0102784:	f6 c4 10             	test   $0x10,%ah
f0102787:	75 f5                	jne    f010277e <lapic_init+0xf4>
	lapicw(TPR, 0);
f0102789:	ba 00 00 00 00       	mov    $0x0,%edx
f010278e:	b8 20 00 00 00       	mov    $0x20,%eax
f0102793:	e8 c0 fe ff ff       	call   f0102658 <lapicw>
}
f0102798:	5d                   	pop    %ebp
f0102799:	c3                   	ret    
		lapicw(PCINT, MASKED);
f010279a:	ba 00 00 01 00       	mov    $0x10000,%edx
f010279f:	b8 d0 00 00 00       	mov    $0xd0,%eax
f01027a4:	e8 af fe ff ff       	call   f0102658 <lapicw>
f01027a9:	e9 70 ff ff ff       	jmp    f010271e <lapic_init+0x94>

f01027ae <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
	if (lapic)
f01027ae:	83 3d 04 50 16 f0 00 	cmpl   $0x0,0xf0165004
f01027b5:	74 14                	je     f01027cb <lapic_eoi+0x1d>
{
f01027b7:	55                   	push   %ebp
f01027b8:	89 e5                	mov    %esp,%ebp
		lapicw(EOI, 0);
f01027ba:	ba 00 00 00 00       	mov    $0x0,%edx
f01027bf:	b8 2c 00 00 00       	mov    $0x2c,%eax
f01027c4:	e8 8f fe ff ff       	call   f0102658 <lapicw>
}
f01027c9:	5d                   	pop    %ebp
f01027ca:	c3                   	ret    
f01027cb:	f3 c3                	repz ret 

f01027cd <lapic_startap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startap(uint8_t apicid, uint32_t addr)
{
f01027cd:	55                   	push   %ebp
f01027ce:	89 e5                	mov    %esp,%ebp
f01027d0:	56                   	push   %esi
f01027d1:	53                   	push   %ebx
f01027d2:	8b 75 08             	mov    0x8(%ebp),%esi
f01027d5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01027d8:	b8 0f 00 00 00       	mov    $0xf,%eax
f01027dd:	ba 70 00 00 00       	mov    $0x70,%edx
f01027e2:	ee                   	out    %al,(%dx)
f01027e3:	b8 0a 00 00 00       	mov    $0xa,%eax
f01027e8:	ba 71 00 00 00       	mov    $0x71,%edx
f01027ed:	ee                   	out    %al,(%dx)
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t *)P2V((0x40 << 4 | 0x67));  // Warm reset vector
	wrv[0] = 0;
f01027ee:	66 c7 05 67 04 00 f0 	movw   $0x0,0xf0000467
f01027f5:	00 00 
	wrv[1] = addr >> 4;
f01027f7:	89 d8                	mov    %ebx,%eax
f01027f9:	c1 e8 04             	shr    $0x4,%eax
f01027fc:	66 a3 69 04 00 f0    	mov    %ax,0xf0000469

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid << 24);
f0102802:	c1 e6 18             	shl    $0x18,%esi
f0102805:	89 f2                	mov    %esi,%edx
f0102807:	b8 c4 00 00 00       	mov    $0xc4,%eax
f010280c:	e8 47 fe ff ff       	call   f0102658 <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
f0102811:	ba 00 c5 00 00       	mov    $0xc500,%edx
f0102816:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010281b:	e8 38 fe ff ff       	call   f0102658 <lapicw>
	microdelay(200);
	lapicw(ICRLO, INIT | LEVEL);
f0102820:	ba 00 85 00 00       	mov    $0x8500,%edx
f0102825:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010282a:	e8 29 fe ff ff       	call   f0102658 <lapicw>
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
		lapicw(ICRLO, STARTUP | (addr >> 12));
f010282f:	c1 eb 0c             	shr    $0xc,%ebx
f0102832:	80 cf 06             	or     $0x6,%bh
		lapicw(ICRHI, apicid << 24);
f0102835:	89 f2                	mov    %esi,%edx
f0102837:	b8 c4 00 00 00       	mov    $0xc4,%eax
f010283c:	e8 17 fe ff ff       	call   f0102658 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0102841:	89 da                	mov    %ebx,%edx
f0102843:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0102848:	e8 0b fe ff ff       	call   f0102658 <lapicw>
		lapicw(ICRHI, apicid << 24);
f010284d:	89 f2                	mov    %esi,%edx
f010284f:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0102854:	e8 ff fd ff ff       	call   f0102658 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0102859:	89 da                	mov    %ebx,%edx
f010285b:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0102860:	e8 f3 fd ff ff       	call   f0102658 <lapicw>
		microdelay(200);
	}
}
f0102865:	5b                   	pop    %ebx
f0102866:	5e                   	pop    %esi
f0102867:	5d                   	pop    %ebp
f0102868:	c3                   	ret    

f0102869 <lapic_ipi>:

void
lapic_ipi(int vector)
{
f0102869:	55                   	push   %ebp
f010286a:	89 e5                	mov    %esp,%ebp
	lapicw(ICRLO, OTHERS | FIXED | vector);
f010286c:	8b 55 08             	mov    0x8(%ebp),%edx
f010286f:	81 ca 00 00 0c 00    	or     $0xc0000,%edx
f0102875:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010287a:	e8 d9 fd ff ff       	call   f0102658 <lapicw>
	while (lapic[ICRLO] & DELIVS)
f010287f:	8b 15 04 50 16 f0    	mov    0xf0165004,%edx
f0102885:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f010288b:	f6 c4 10             	test   $0x10,%ah
f010288e:	75 f5                	jne    f0102885 <lapic_ipi+0x1c>
		;
}
f0102890:	5d                   	pop    %ebp
f0102891:	c3                   	ret    

f0102892 <__spin_initlock>:
#endif
};

void
__spin_initlock(struct spinlock *lk, char *name)
{
f0102892:	55                   	push   %ebp
f0102893:	89 e5                	mov    %esp,%ebp
f0102895:	8b 45 08             	mov    0x8(%ebp),%eax
	// TODO: Your code here.
#ifdef DEBUG_MCSLOCK
	lk->locked = NULL;
f0102898:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
#else
	lk->locked = 0;
#endif
	lk->name = name;
f010289e:	8b 55 0c             	mov    0xc(%ebp),%edx
f01028a1:	89 50 04             	mov    %edx,0x4(%eax)
	lk->cpu = 0;
f01028a4:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
f01028ab:	5d                   	pop    %ebp
f01028ac:	c3                   	ret    

f01028ad <spin_lock>:
// other CPUs to waste time spinning to acquire it.

#ifdef DEBUG_MCSLOCK
void
spin_lock(struct spinlock *lk)
{
f01028ad:	55                   	push   %ebp
f01028ae:	89 e5                	mov    %esp,%ebp
f01028b0:	53                   	push   %ebx
f01028b1:	83 ec 04             	sub    $0x4,%esp
f01028b4:	8b 5d 08             	mov    0x8(%ebp),%ebx
	struct mcslock_node *me = &thiscpu->node;
f01028b7:	e8 b4 fd ff ff       	call   f0102670 <cpunum>
f01028bc:	89 c2                	mov    %eax,%edx
f01028be:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f01028c4:	8d 88 d0 40 12 f0    	lea    -0xfedbf30(%eax),%ecx
	struct mcslock_node *tmp = me;
	me->next = NULL;
f01028ca:	c7 80 d4 40 12 f0 00 	movl   $0x0,-0xfedbf2c(%eax)
f01028d1:	00 00 00 
	asm volatile("lock; xchgl %0, %1"
f01028d4:	89 c8                	mov    %ecx,%eax
f01028d6:	f0 87 03             	lock xchg %eax,(%ebx)
	struct mcslock_node *pre = Xchg(&lk->locked, tmp);
	if (pre == NULL)
f01028d9:	85 c0                	test   %eax,%eax
f01028db:	74 29                	je     f0102906 <spin_lock+0x59>
		return;
	me->waiting = 1;
f01028dd:	69 da b8 00 00 00    	imul   $0xb8,%edx,%ebx
f01028e3:	81 c3 20 40 12 f0    	add    $0xf0124020,%ebx
f01028e9:	c7 83 b0 00 00 00 01 	movl   $0x1,0xb0(%ebx)
f01028f0:	00 00 00 
	asm volatile("" : : : "memory");
	pre->next = me;
f01028f3:	89 48 04             	mov    %ecx,0x4(%eax)
	while (me->waiting) 
f01028f6:	89 d8                	mov    %ebx,%eax
f01028f8:	eb 02                	jmp    f01028fc <spin_lock+0x4f>
		asm volatile("pause");
f01028fa:	f3 90                	pause  
	while (me->waiting) 
f01028fc:	8b 90 b0 00 00 00    	mov    0xb0(%eax),%edx
f0102902:	85 d2                	test   %edx,%edx
f0102904:	75 f4                	jne    f01028fa <spin_lock+0x4d>
}
f0102906:	83 c4 04             	add    $0x4,%esp
f0102909:	5b                   	pop    %ebx
f010290a:	5d                   	pop    %ebp
f010290b:	c3                   	ret    

f010290c <spin_unlock>:

void
spin_unlock(struct spinlock *lk)
{
f010290c:	55                   	push   %ebp
f010290d:	89 e5                	mov    %esp,%ebp
f010290f:	56                   	push   %esi
f0102910:	53                   	push   %ebx
	struct mcslock_node *me = &thiscpu->node;
f0102911:	e8 5a fd ff ff       	call   f0102670 <cpunum>
f0102916:	89 c2                	mov    %eax,%edx
	struct mcslock_node *tmp = me;
	if (me->next == NULL) {
f0102918:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f010291e:	05 20 40 12 f0       	add    $0xf0124020,%eax
f0102923:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
f0102929:	85 c0                	test   %eax,%eax
f010292b:	74 16                	je     f0102943 <spin_unlock+0x37>
		if (Cmpxchg(&lk->locked, tmp, NULL) == me)
			return;
		while (me->next == NULL)
			continue;
	}
	me->next->waiting = 0;
f010292d:	69 d2 b8 00 00 00    	imul   $0xb8,%edx,%edx
f0102933:	8b 82 d4 40 12 f0    	mov    -0xfedbf2c(%edx),%eax
f0102939:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}
f010293f:	5b                   	pop    %ebx
f0102940:	5e                   	pop    %esi
f0102941:	5d                   	pop    %ebp
f0102942:	c3                   	ret    
	struct mcslock_node *me = &thiscpu->node;
f0102943:	69 ca b8 00 00 00    	imul   $0xb8,%edx,%ecx
f0102949:	81 c1 d0 40 12 f0    	add    $0xf01240d0,%ecx
	asm volatile("lock; cmpxchgl %2, %1"
f010294f:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102954:	8b 75 08             	mov    0x8(%ebp),%esi
f0102957:	89 c8                	mov    %ecx,%eax
f0102959:	f0 0f b1 1e          	lock cmpxchg %ebx,(%esi)
		if (Cmpxchg(&lk->locked, tmp, NULL) == me)
f010295d:	39 c1                	cmp    %eax,%ecx
f010295f:	74 de                	je     f010293f <spin_unlock+0x33>
		while (me->next == NULL)
f0102961:	69 c2 b8 00 00 00    	imul   $0xb8,%edx,%eax
f0102967:	05 20 40 12 f0       	add    $0xf0124020,%eax
f010296c:	8b 88 b4 00 00 00    	mov    0xb4(%eax),%ecx
f0102972:	85 c9                	test   %ecx,%ecx
f0102974:	75 b7                	jne    f010292d <spin_unlock+0x21>
f0102976:	eb f4                	jmp    f010296c <spin_unlock+0x60>

f0102978 <irq_setmask_8259A>:
		irq_setmask_8259A(irq_mask_8259A);
}

void
irq_setmask_8259A(uint16_t mask)
{
f0102978:	55                   	push   %ebp
f0102979:	89 e5                	mov    %esp,%ebp
f010297b:	56                   	push   %esi
f010297c:	53                   	push   %ebx
f010297d:	8b 45 08             	mov    0x8(%ebp),%eax
	int i;
	irq_mask_8259A = mask;
f0102980:	66 a3 34 c7 11 f0    	mov    %ax,0xf011c734
	if (!didinit)
f0102986:	80 3d 35 32 12 f0 00 	cmpb   $0x0,0xf0123235
f010298d:	75 07                	jne    f0102996 <irq_setmask_8259A+0x1e>
	cprintf("enabled interrupts:");
	for (i = 0; i < 16; i++)
		if (~mask & (1<<i))
			cprintf(" %d", i);
	cprintf("\n");
}
f010298f:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0102992:	5b                   	pop    %ebx
f0102993:	5e                   	pop    %esi
f0102994:	5d                   	pop    %ebp
f0102995:	c3                   	ret    
f0102996:	89 c6                	mov    %eax,%esi
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102998:	ba 21 00 00 00       	mov    $0x21,%edx
f010299d:	ee                   	out    %al,(%dx)
	outb(IO_PIC2+1, (char)(mask >> 8));
f010299e:	66 c1 e8 08          	shr    $0x8,%ax
f01029a2:	ba a1 00 00 00       	mov    $0xa1,%edx
f01029a7:	ee                   	out    %al,(%dx)
	cprintf("enabled interrupts:");
f01029a8:	83 ec 0c             	sub    $0xc,%esp
f01029ab:	68 b0 41 10 f0       	push   $0xf01041b0
f01029b0:	e8 cd dd ff ff       	call   f0100782 <cprintf>
f01029b5:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < 16; i++)
f01029b8:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (~mask & (1<<i))
f01029bd:	0f b7 f6             	movzwl %si,%esi
f01029c0:	f7 d6                	not    %esi
f01029c2:	eb 08                	jmp    f01029cc <irq_setmask_8259A+0x54>
	for (i = 0; i < 16; i++)
f01029c4:	83 c3 01             	add    $0x1,%ebx
f01029c7:	83 fb 10             	cmp    $0x10,%ebx
f01029ca:	74 18                	je     f01029e4 <irq_setmask_8259A+0x6c>
		if (~mask & (1<<i))
f01029cc:	0f a3 de             	bt     %ebx,%esi
f01029cf:	73 f3                	jae    f01029c4 <irq_setmask_8259A+0x4c>
			cprintf(" %d", i);
f01029d1:	83 ec 08             	sub    $0x8,%esp
f01029d4:	53                   	push   %ebx
f01029d5:	68 3d 42 10 f0       	push   $0xf010423d
f01029da:	e8 a3 dd ff ff       	call   f0100782 <cprintf>
f01029df:	83 c4 10             	add    $0x10,%esp
f01029e2:	eb e0                	jmp    f01029c4 <irq_setmask_8259A+0x4c>
	cprintf("\n");
f01029e4:	83 ec 0c             	sub    $0xc,%esp
f01029e7:	68 6f 3c 10 f0       	push   $0xf0103c6f
f01029ec:	e8 91 dd ff ff       	call   f0100782 <cprintf>
f01029f1:	83 c4 10             	add    $0x10,%esp
f01029f4:	eb 99                	jmp    f010298f <irq_setmask_8259A+0x17>

f01029f6 <pic_init>:
{
f01029f6:	55                   	push   %ebp
f01029f7:	89 e5                	mov    %esp,%ebp
f01029f9:	57                   	push   %edi
f01029fa:	56                   	push   %esi
f01029fb:	53                   	push   %ebx
f01029fc:	83 ec 0c             	sub    $0xc,%esp
	didinit = 1;
f01029ff:	c6 05 35 32 12 f0 01 	movb   $0x1,0xf0123235
f0102a06:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a0b:	bb 21 00 00 00       	mov    $0x21,%ebx
f0102a10:	89 da                	mov    %ebx,%edx
f0102a12:	ee                   	out    %al,(%dx)
f0102a13:	b9 a1 00 00 00       	mov    $0xa1,%ecx
f0102a18:	89 ca                	mov    %ecx,%edx
f0102a1a:	ee                   	out    %al,(%dx)
f0102a1b:	bf 11 00 00 00       	mov    $0x11,%edi
f0102a20:	be 20 00 00 00       	mov    $0x20,%esi
f0102a25:	89 f8                	mov    %edi,%eax
f0102a27:	89 f2                	mov    %esi,%edx
f0102a29:	ee                   	out    %al,(%dx)
f0102a2a:	b8 20 00 00 00       	mov    $0x20,%eax
f0102a2f:	89 da                	mov    %ebx,%edx
f0102a31:	ee                   	out    %al,(%dx)
f0102a32:	b8 04 00 00 00       	mov    $0x4,%eax
f0102a37:	ee                   	out    %al,(%dx)
f0102a38:	b8 03 00 00 00       	mov    $0x3,%eax
f0102a3d:	ee                   	out    %al,(%dx)
f0102a3e:	bb a0 00 00 00       	mov    $0xa0,%ebx
f0102a43:	89 f8                	mov    %edi,%eax
f0102a45:	89 da                	mov    %ebx,%edx
f0102a47:	ee                   	out    %al,(%dx)
f0102a48:	b8 28 00 00 00       	mov    $0x28,%eax
f0102a4d:	89 ca                	mov    %ecx,%edx
f0102a4f:	ee                   	out    %al,(%dx)
f0102a50:	b8 02 00 00 00       	mov    $0x2,%eax
f0102a55:	ee                   	out    %al,(%dx)
f0102a56:	b8 01 00 00 00       	mov    $0x1,%eax
f0102a5b:	ee                   	out    %al,(%dx)
f0102a5c:	bf 68 00 00 00       	mov    $0x68,%edi
f0102a61:	89 f8                	mov    %edi,%eax
f0102a63:	89 f2                	mov    %esi,%edx
f0102a65:	ee                   	out    %al,(%dx)
f0102a66:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0102a6b:	89 c8                	mov    %ecx,%eax
f0102a6d:	ee                   	out    %al,(%dx)
f0102a6e:	89 f8                	mov    %edi,%eax
f0102a70:	89 da                	mov    %ebx,%edx
f0102a72:	ee                   	out    %al,(%dx)
f0102a73:	89 c8                	mov    %ecx,%eax
f0102a75:	ee                   	out    %al,(%dx)
	if (irq_mask_8259A != 0xFFFF)
f0102a76:	0f b7 05 34 c7 11 f0 	movzwl 0xf011c734,%eax
f0102a7d:	66 83 f8 ff          	cmp    $0xffff,%ax
f0102a81:	74 0f                	je     f0102a92 <pic_init+0x9c>
		irq_setmask_8259A(irq_mask_8259A);
f0102a83:	83 ec 0c             	sub    $0xc,%esp
f0102a86:	0f b7 c0             	movzwl %ax,%eax
f0102a89:	50                   	push   %eax
f0102a8a:	e8 e9 fe ff ff       	call   f0102978 <irq_setmask_8259A>
f0102a8f:	83 c4 10             	add    $0x10,%esp
}
f0102a92:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102a95:	5b                   	pop    %ebx
f0102a96:	5e                   	pop    %esi
f0102a97:	5f                   	pop    %edi
f0102a98:	5d                   	pop    %ebp
f0102a99:	c3                   	ret    

f0102a9a <forkret>:
	swtch(&p->context, thiscpu->scheduler);
}

void
forkret(void)
{
f0102a9a:	55                   	push   %ebp
f0102a9b:	89 e5                	mov    %esp,%ebp
f0102a9d:	83 ec 14             	sub    $0x14,%esp
	// Return to "caller", actually trapret (see proc_alloc)
	// That means the first proc starts here.
	// When it returns from forkret, it need to return to trapret.
	// TODO: your code here.
	spin_unlock(&ptable.lock);
f0102aa0:	68 20 50 16 f0       	push   $0xf0165020
f0102aa5:	e8 62 fe ff ff       	call   f010290c <spin_unlock>

}
f0102aaa:	83 c4 10             	add    $0x10,%esp
f0102aad:	c9                   	leave  
f0102aae:	c3                   	ret    

f0102aaf <proc_alloc>:
{
f0102aaf:	55                   	push   %ebp
f0102ab0:	89 e5                	mov    %esp,%ebp
f0102ab2:	53                   	push   %ebx
f0102ab3:	83 ec 10             	sub    $0x10,%esp
	spin_lock(&ptable.lock);
f0102ab6:	68 20 50 16 f0       	push   $0xf0165020
f0102abb:	e8 ed fd ff ff       	call   f01028ad <spin_lock>
f0102ac0:	83 c4 10             	add    $0x10,%esp
	for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
f0102ac3:	bb 54 50 16 f0       	mov    $0xf0165054,%ebx
		if (p->state == UNUSED) {
f0102ac8:	83 7b 08 00          	cmpl   $0x0,0x8(%ebx)
f0102acc:	74 22                	je     f0102af0 <proc_alloc+0x41>
	for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
f0102ace:	83 c3 1c             	add    $0x1c,%ebx
f0102ad1:	81 fb 54 57 16 f0    	cmp    $0xf0165754,%ebx
f0102ad7:	72 ef                	jb     f0102ac8 <proc_alloc+0x19>
	spin_unlock(&ptable.lock);
f0102ad9:	83 ec 0c             	sub    $0xc,%esp
f0102adc:	68 20 50 16 f0       	push   $0xf0165020
f0102ae1:	e8 26 fe ff ff       	call   f010290c <spin_unlock>
	return NULL;
f0102ae6:	83 c4 10             	add    $0x10,%esp
f0102ae9:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102aee:	eb 69                	jmp    f0102b59 <proc_alloc+0xaa>
			p->state = EMBRYO;
f0102af0:	c7 43 08 01 00 00 00 	movl   $0x1,0x8(%ebx)
			p->pid = nextpid++;
f0102af7:	a1 4c c7 11 f0       	mov    0xf011c74c,%eax
f0102afc:	8d 50 01             	lea    0x1(%eax),%edx
f0102aff:	89 15 4c c7 11 f0    	mov    %edx,0xf011c74c
f0102b05:	89 43 0c             	mov    %eax,0xc(%ebx)
			spin_unlock(&ptable.lock);
f0102b08:	83 ec 0c             	sub    $0xc,%esp
f0102b0b:	68 20 50 16 f0       	push   $0xf0165020
f0102b10:	e8 f7 fd ff ff       	call   f010290c <spin_unlock>
			if ((p->kstack = kalloc()) == NULL) {
f0102b15:	e8 11 f5 ff ff       	call   f010202b <kalloc>
f0102b1a:	89 43 04             	mov    %eax,0x4(%ebx)
f0102b1d:	83 c4 10             	add    $0x10,%esp
f0102b20:	85 c0                	test   %eax,%eax
f0102b22:	74 3c                	je     f0102b60 <proc_alloc+0xb1>
			begin -= sizeof(*p->tf);
f0102b24:	8d 90 b4 0f 00 00    	lea    0xfb4(%eax),%edx
f0102b2a:	89 53 14             	mov    %edx,0x14(%ebx)
			*(uint32_t *)begin = (uint32_t)trapret;
f0102b2d:	c7 80 b0 0f 00 00 aa 	movl   $0xf01008aa,0xfb0(%eax)
f0102b34:	08 10 f0 
			begin -= sizeof(*p->context);
f0102b37:	05 9c 0f 00 00       	add    $0xf9c,%eax
			p->context = (struct context *)begin;
f0102b3c:	89 43 18             	mov    %eax,0x18(%ebx)
			memset(p->context, 0, sizeof(*p->context));
f0102b3f:	83 ec 04             	sub    $0x4,%esp
f0102b42:	6a 14                	push   $0x14
f0102b44:	6a 00                	push   $0x0
f0102b46:	50                   	push   %eax
f0102b47:	e8 5f 0c 00 00       	call   f01037ab <memset>
			p->context->eip = (uint32_t)forkret;
f0102b4c:	8b 43 18             	mov    0x18(%ebx),%eax
f0102b4f:	c7 40 10 9a 2a 10 f0 	movl   $0xf0102a9a,0x10(%eax)
			return p;
f0102b56:	83 c4 10             	add    $0x10,%esp
}
f0102b59:	89 d8                	mov    %ebx,%eax
f0102b5b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102b5e:	c9                   	leave  
f0102b5f:	c3                   	ret    
				p->state = UNUSED;
f0102b60:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
				return NULL;
f0102b67:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102b6c:	eb eb                	jmp    f0102b59 <proc_alloc+0xaa>

f0102b6e <proc_init>:
{
f0102b6e:	55                   	push   %ebp
f0102b6f:	89 e5                	mov    %esp,%ebp
f0102b71:	83 ec 10             	sub    $0x10,%esp
	__spin_initlock(&ptable.lock, "ptable");
f0102b74:	68 c4 41 10 f0       	push   $0xf01041c4
f0102b79:	68 20 50 16 f0       	push   $0xf0165020
f0102b7e:	e8 0f fd ff ff       	call   f0102892 <__spin_initlock>
}
f0102b83:	83 c4 10             	add    $0x10,%esp
f0102b86:	c9                   	leave  
f0102b87:	c3                   	ret    

f0102b88 <user_init>:
{
f0102b88:	55                   	push   %ebp
f0102b89:	89 e5                	mov    %esp,%ebp
f0102b8b:	57                   	push   %edi
f0102b8c:	56                   	push   %esi
f0102b8d:	53                   	push   %ebx
f0102b8e:	83 ec 1c             	sub    $0x1c,%esp
	if ((child = proc_alloc()) == NULL)
f0102b91:	e8 19 ff ff ff       	call   f0102aaf <proc_alloc>
f0102b96:	85 c0                	test   %eax,%eax
f0102b98:	74 27                	je     f0102bc1 <user_init+0x39>
f0102b9a:	89 c6                	mov    %eax,%esi
	if ((child->pgdir = kvm_init()) == NULL)
f0102b9c:	e8 7c ea ff ff       	call   f010161d <kvm_init>
f0102ba1:	89 06                	mov    %eax,(%esi)
f0102ba3:	85 c0                	test   %eax,%eax
f0102ba5:	74 31                	je     f0102bd8 <user_init+0x50>
	ph = (struct Proghdr *) (binary + elf->e_phoff);
f0102ba7:	a1 6c c7 11 f0       	mov    0xf011c76c,%eax
f0102bac:	8d 98 50 c7 11 f0    	lea    -0xfee38b0(%eax),%ebx
	eph = ph + elf->e_phnum;
f0102bb2:	0f b7 05 7c c7 11 f0 	movzwl 0xf011c77c,%eax
f0102bb9:	c1 e0 05             	shl    $0x5,%eax
f0102bbc:	8d 3c 03             	lea    (%ebx,%eax,1),%edi
f0102bbf:	eb 31                	jmp    f0102bf2 <user_init+0x6a>
		panic("Allocate User Process.");
f0102bc1:	83 ec 04             	sub    $0x4,%esp
f0102bc4:	68 cb 41 10 f0       	push   $0xf01041cb
f0102bc9:	68 21 01 00 00       	push   $0x121
f0102bce:	68 e2 41 10 f0       	push   $0xf01041e2
f0102bd3:	e8 c0 d5 ff ff       	call   f0100198 <_panic>
		panic("User Pagedir.");
f0102bd8:	83 ec 04             	sub    $0x4,%esp
f0102bdb:	68 ee 41 10 f0       	push   $0xf01041ee
f0102be0:	68 23 01 00 00       	push   $0x123
f0102be5:	68 e2 41 10 f0       	push   $0xf01041e2
f0102bea:	e8 a9 d5 ff ff       	call   f0100198 <_panic>
	for (; ph < eph; ph++) {
f0102bef:	83 c3 20             	add    $0x20,%ebx
f0102bf2:	39 df                	cmp    %ebx,%edi
f0102bf4:	76 46                	jbe    f0102c3c <user_init+0xb4>
			if (ph->p_type == ELF_PROG_LOAD) {
f0102bf6:	83 3b 01             	cmpl   $0x1,(%ebx)
f0102bf9:	75 f4                	jne    f0102bef <user_init+0x67>
			void *begin = (void *)ph->p_va;
f0102bfb:	8b 43 08             	mov    0x8(%ebx),%eax
				region_alloc(p, begin, ph->p_memsz);
f0102bfe:	83 ec 04             	sub    $0x4,%esp
f0102c01:	ff 73 14             	pushl  0x14(%ebx)
f0102c04:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102c07:	50                   	push   %eax
f0102c08:	56                   	push   %esi
f0102c09:	e8 c4 ec ff ff       	call   f01018d2 <region_alloc>
				if (loaduvm(p->pgdir, begin, ph, (char *)binary) < 0)
f0102c0e:	68 50 c7 11 f0       	push   $0xf011c750
f0102c13:	53                   	push   %ebx
f0102c14:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102c17:	ff 36                	pushl  (%esi)
f0102c19:	e8 21 e9 ff ff       	call   f010153f <loaduvm>
f0102c1e:	83 c4 20             	add    $0x20,%esp
f0102c21:	85 c0                	test   %eax,%eax
f0102c23:	79 ca                	jns    f0102bef <user_init+0x67>
					panic("Load segment.");
f0102c25:	83 ec 04             	sub    $0x4,%esp
f0102c28:	68 fc 41 10 f0       	push   $0xf01041fc
f0102c2d:	68 04 01 00 00       	push   $0x104
f0102c32:	68 e2 41 10 f0       	push   $0xf01041e2
f0102c37:	e8 5c d5 ff ff       	call   f0100198 <_panic>
	region_alloc(p, (void *)(USTACKTOP - PGSIZE), PGSIZE * 2);
f0102c3c:	83 ec 04             	sub    $0x4,%esp
f0102c3f:	68 00 20 00 00       	push   $0x2000
f0102c44:	68 00 f0 ff cf       	push   $0xcffff000
f0102c49:	56                   	push   %esi
f0102c4a:	e8 83 ec ff ff       	call   f01018d2 <region_alloc>
	memset(child->tf, 0, sizeof(*child->tf));
f0102c4f:	83 c4 0c             	add    $0xc,%esp
f0102c52:	6a 4c                	push   $0x4c
f0102c54:	6a 00                	push   $0x0
f0102c56:	ff 76 14             	pushl  0x14(%esi)
f0102c59:	e8 4d 0b 00 00       	call   f01037ab <memset>
	child->tf->cs = (SEG_UCODE << 3) | DPL_USER;
f0102c5e:	8b 46 14             	mov    0x14(%esi),%eax
f0102c61:	66 c7 40 3c 1b 00    	movw   $0x1b,0x3c(%eax)
	child->tf->ds = (SEG_UDATA << 3) | DPL_USER;
f0102c67:	8b 46 14             	mov    0x14(%esi),%eax
f0102c6a:	66 c7 40 2c 23 00    	movw   $0x23,0x2c(%eax)
	child->tf->es = (SEG_UDATA << 3) | DPL_USER;
f0102c70:	8b 46 14             	mov    0x14(%esi),%eax
f0102c73:	66 c7 40 28 23 00    	movw   $0x23,0x28(%eax)
	child->tf->ss = (SEG_UDATA << 3) | DPL_USER;
f0102c79:	8b 46 14             	mov    0x14(%esi),%eax
f0102c7c:	66 c7 40 48 23 00    	movw   $0x23,0x48(%eax)
	child->tf->eflags = FL_IF;
f0102c82:	8b 46 14             	mov    0x14(%esi),%eax
f0102c85:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
	child->tf->eip = (uintptr_t)begin;
f0102c8c:	8b 46 14             	mov    0x14(%esi),%eax
f0102c8f:	8b 15 68 c7 11 f0    	mov    0xf011c768,%edx
f0102c95:	89 50 38             	mov    %edx,0x38(%eax)
	child->tf->esp = USTACKTOP;
f0102c98:	8b 46 14             	mov    0x14(%esi),%eax
f0102c9b:	c7 40 44 00 00 00 d0 	movl   $0xd0000000,0x44(%eax)
	child->state = RUNNABLE;
f0102ca2:	c7 46 08 03 00 00 00 	movl   $0x3,0x8(%esi)
}
f0102ca9:	83 c4 10             	add    $0x10,%esp
f0102cac:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102caf:	5b                   	pop    %ebx
f0102cb0:	5e                   	pop    %esi
f0102cb1:	5f                   	pop    %edi
f0102cb2:	5d                   	pop    %ebp
f0102cb3:	c3                   	ret    

f0102cb4 <ucode_run>:
{
f0102cb4:	55                   	push   %ebp
f0102cb5:	89 e5                	mov    %esp,%ebp
f0102cb7:	56                   	push   %esi
f0102cb8:	53                   	push   %ebx
	thiscpu->proc = NULL;
f0102cb9:	e8 b2 f9 ff ff       	call   f0102670 <cpunum>
f0102cbe:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f0102cc4:	c7 80 c4 40 12 f0 00 	movl   $0x0,-0xfedbf3c(%eax)
f0102ccb:	00 00 00 
f0102cce:	eb 7e                	jmp    f0102d4e <ucode_run+0x9a>
		for (p = ptable.proc; p < &ptable.proc[NPROC]; p++) {
f0102cd0:	83 c3 1c             	add    $0x1c,%ebx
f0102cd3:	81 fb 54 57 16 f0    	cmp    $0xf0165754,%ebx
f0102cd9:	73 63                	jae    f0102d3e <ucode_run+0x8a>
			if (p->state == RUNNABLE) {
f0102cdb:	83 7b 08 03          	cmpl   $0x3,0x8(%ebx)
f0102cdf:	75 ef                	jne    f0102cd0 <ucode_run+0x1c>
				uvm_switch(p);
f0102ce1:	83 ec 0c             	sub    $0xc,%esp
f0102ce4:	53                   	push   %ebx
f0102ce5:	e8 4a ed ff ff       	call   f0101a34 <uvm_switch>
				p->state = RUNNING;
f0102cea:	c7 43 08 04 00 00 00 	movl   $0x4,0x8(%ebx)
				thiscpu->proc = p;
f0102cf1:	e8 7a f9 ff ff       	call   f0102670 <cpunum>
f0102cf6:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f0102cfc:	89 98 c4 40 12 f0    	mov    %ebx,-0xfedbf3c(%eax)
				swtch(&thiscpu->scheduler, p->context);
f0102d02:	8b 73 18             	mov    0x18(%ebx),%esi
f0102d05:	e8 66 f9 ff ff       	call   f0102670 <cpunum>
f0102d0a:	83 c4 08             	add    $0x8,%esp
f0102d0d:	56                   	push   %esi
f0102d0e:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f0102d14:	05 28 40 12 f0       	add    $0xf0124028,%eax
f0102d19:	50                   	push   %eax
f0102d1a:	e8 49 02 00 00       	call   f0102f68 <swtch>
				kvm_switch();
f0102d1f:	e8 6d e9 ff ff       	call   f0101691 <kvm_switch>
				thiscpu->proc = NULL;
f0102d24:	e8 47 f9 ff ff       	call   f0102670 <cpunum>
f0102d29:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f0102d2f:	c7 80 c4 40 12 f0 00 	movl   $0x0,-0xfedbf3c(%eax)
f0102d36:	00 00 00 
f0102d39:	83 c4 10             	add    $0x10,%esp
f0102d3c:	eb 92                	jmp    f0102cd0 <ucode_run+0x1c>
		spin_unlock(&ptable.lock);
f0102d3e:	83 ec 0c             	sub    $0xc,%esp
f0102d41:	68 20 50 16 f0       	push   $0xf0165020
f0102d46:	e8 c1 fb ff ff       	call   f010290c <spin_unlock>
		sti();
f0102d4b:	83 c4 10             	add    $0x10,%esp
	asm volatile("sti");
f0102d4e:	fb                   	sti    
		spin_lock(&ptable.lock);
f0102d4f:	83 ec 0c             	sub    $0xc,%esp
f0102d52:	68 20 50 16 f0       	push   $0xf0165020
f0102d57:	e8 51 fb ff ff       	call   f01028ad <spin_lock>
f0102d5c:	83 c4 10             	add    $0x10,%esp
		for (p = ptable.proc; p < &ptable.proc[NPROC]; p++) {
f0102d5f:	bb 54 50 16 f0       	mov    $0xf0165054,%ebx
f0102d64:	e9 72 ff ff ff       	jmp    f0102cdb <ucode_run+0x27>

f0102d69 <thisproc>:
thisproc(void) {
f0102d69:	55                   	push   %ebp
f0102d6a:	89 e5                	mov    %esp,%ebp
f0102d6c:	53                   	push   %ebx
f0102d6d:	83 ec 04             	sub    $0x4,%esp
	pushcli();
f0102d70:	e8 ea eb ff ff       	call   f010195f <pushcli>
	p = thiscpu->proc;
f0102d75:	e8 f6 f8 ff ff       	call   f0102670 <cpunum>
f0102d7a:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f0102d80:	8b 98 c4 40 12 f0    	mov    -0xfedbf3c(%eax),%ebx
	popcli();
f0102d86:	e8 23 ec ff ff       	call   f01019ae <popcli>
}
f0102d8b:	89 d8                	mov    %ebx,%eax
f0102d8d:	83 c4 04             	add    $0x4,%esp
f0102d90:	5b                   	pop    %ebx
f0102d91:	5d                   	pop    %ebp
f0102d92:	c3                   	ret    

f0102d93 <sched>:
{
f0102d93:	55                   	push   %ebp
f0102d94:	89 e5                	mov    %esp,%ebp
f0102d96:	53                   	push   %ebx
f0102d97:	83 ec 04             	sub    $0x4,%esp
	struct proc *p = thisproc();
f0102d9a:	e8 ca ff ff ff       	call   f0102d69 <thisproc>
f0102d9f:	89 c3                	mov    %eax,%ebx
	swtch(&p->context, thiscpu->scheduler);
f0102da1:	e8 ca f8 ff ff       	call   f0102670 <cpunum>
f0102da6:	83 ec 08             	sub    $0x8,%esp
f0102da9:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f0102daf:	ff b0 28 40 12 f0    	pushl  -0xfedbfd8(%eax)
f0102db5:	83 c3 18             	add    $0x18,%ebx
f0102db8:	53                   	push   %ebx
f0102db9:	e8 aa 01 00 00       	call   f0102f68 <swtch>
}
f0102dbe:	83 c4 10             	add    $0x10,%esp
f0102dc1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102dc4:	c9                   	leave  
f0102dc5:	c3                   	ret    

f0102dc6 <fork>:
	spin_unlock(&ptable.lock);
}
#else
int
fork(void)
{
f0102dc6:	55                   	push   %ebp
f0102dc7:	89 e5                	mov    %esp,%ebp
f0102dc9:	57                   	push   %edi
f0102dca:	56                   	push   %esi
f0102dcb:	53                   	push   %ebx
f0102dcc:	83 ec 0c             	sub    $0xc,%esp
	struct proc *p = thisproc();
f0102dcf:	e8 95 ff ff ff       	call   f0102d69 <thisproc>
f0102dd4:	89 c6                	mov    %eax,%esi
	struct proc *child;
	if ((child = proc_alloc()) == NULL)
f0102dd6:	e8 d4 fc ff ff       	call   f0102aaf <proc_alloc>
f0102ddb:	85 c0                	test   %eax,%eax
f0102ddd:	74 5d                	je     f0102e3c <fork+0x76>
f0102ddf:	89 c3                	mov    %eax,%ebx
		return -1;
	if ((child->pgdir = copyuvm(p->pgdir)) == NULL)
f0102de1:	83 ec 0c             	sub    $0xc,%esp
f0102de4:	ff 36                	pushl  (%esi)
f0102de6:	e8 fe e9 ff ff       	call   f01017e9 <copyuvm>
f0102deb:	89 03                	mov    %eax,(%ebx)
f0102ded:	83 c4 10             	add    $0x10,%esp
f0102df0:	85 c0                	test   %eax,%eax
f0102df2:	74 4f                	je     f0102e43 <fork+0x7d>
		return -1;
	child->parent = p;
f0102df4:	89 73 10             	mov    %esi,0x10(%ebx)
	*child->tf = *p->tf;
f0102df7:	8b 76 14             	mov    0x14(%esi),%esi
f0102dfa:	b9 13 00 00 00       	mov    $0x13,%ecx
f0102dff:	8b 7b 14             	mov    0x14(%ebx),%edi
f0102e02:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	// TODO: can't understand the reason for parent id.
	child->tf->eax = 0;
f0102e04:	8b 43 14             	mov    0x14(%ebx),%eax
f0102e07:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
	spin_lock(&ptable.lock);
f0102e0e:	83 ec 0c             	sub    $0xc,%esp
f0102e11:	68 20 50 16 f0       	push   $0xf0165020
f0102e16:	e8 92 fa ff ff       	call   f01028ad <spin_lock>
	child->state = RUNNABLE;
f0102e1b:	c7 43 08 03 00 00 00 	movl   $0x3,0x8(%ebx)
	spin_unlock(&ptable.lock);
f0102e22:	c7 04 24 20 50 16 f0 	movl   $0xf0165020,(%esp)
f0102e29:	e8 de fa ff ff       	call   f010290c <spin_unlock>
	return child->pid;
f0102e2e:	8b 43 0c             	mov    0xc(%ebx),%eax
f0102e31:	83 c4 10             	add    $0x10,%esp
}
f0102e34:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102e37:	5b                   	pop    %ebx
f0102e38:	5e                   	pop    %esi
f0102e39:	5f                   	pop    %edi
f0102e3a:	5d                   	pop    %ebp
f0102e3b:	c3                   	ret    
		return -1;
f0102e3c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102e41:	eb f1                	jmp    f0102e34 <fork+0x6e>
		return -1;
f0102e43:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102e48:	eb ea                	jmp    f0102e34 <fork+0x6e>

f0102e4a <exit>:

void
exit(void)
{
f0102e4a:	55                   	push   %ebp
f0102e4b:	89 e5                	mov    %esp,%ebp
f0102e4d:	53                   	push   %ebx
f0102e4e:	83 ec 04             	sub    $0x4,%esp
	// sys_exit() call to here.
	// TODO: your code here.
	struct proc *p = thisproc();
f0102e51:	e8 13 ff ff ff       	call   f0102d69 <thisproc>
f0102e56:	89 c3                	mov    %eax,%ebx
	spin_lock(&ptable.lock);
f0102e58:	83 ec 0c             	sub    $0xc,%esp
f0102e5b:	68 20 50 16 f0       	push   $0xf0165020
f0102e60:	e8 48 fa ff ff       	call   f01028ad <spin_lock>
	p->state = ZOMBIE;
f0102e65:	c7 43 08 05 00 00 00 	movl   $0x5,0x8(%ebx)
	sched();
f0102e6c:	e8 22 ff ff ff       	call   f0102d93 <sched>
}
f0102e71:	83 c4 10             	add    $0x10,%esp
f0102e74:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102e77:	c9                   	leave  
f0102e78:	c3                   	ret    

f0102e79 <yield>:

void
yield(void)
{
f0102e79:	55                   	push   %ebp
f0102e7a:	89 e5                	mov    %esp,%ebp
f0102e7c:	53                   	push   %ebx
f0102e7d:	83 ec 04             	sub    $0x4,%esp
	struct proc *p = thisproc();
f0102e80:	e8 e4 fe ff ff       	call   f0102d69 <thisproc>
f0102e85:	89 c3                	mov    %eax,%ebx
	spin_lock(&ptable.lock);
f0102e87:	83 ec 0c             	sub    $0xc,%esp
f0102e8a:	68 20 50 16 f0       	push   $0xf0165020
f0102e8f:	e8 19 fa ff ff       	call   f01028ad <spin_lock>
	p->state = RUNNABLE;
f0102e94:	c7 43 08 03 00 00 00 	movl   $0x3,0x8(%ebx)
	sched();
f0102e9b:	e8 f3 fe ff ff       	call   f0102d93 <sched>
	spin_unlock(&ptable.lock);
f0102ea0:	c7 04 24 20 50 16 f0 	movl   $0xf0165020,(%esp)
f0102ea7:	e8 60 fa ff ff       	call   f010290c <spin_unlock>
}
f0102eac:	83 c4 10             	add    $0x10,%esp
f0102eaf:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102eb2:	c9                   	leave  
f0102eb3:	c3                   	ret    

f0102eb4 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f0102eb4:	55                   	push   %ebp
f0102eb5:	89 e5                	mov    %esp,%ebp
f0102eb7:	57                   	push   %edi
f0102eb8:	56                   	push   %esi
f0102eb9:	53                   	push   %ebx
f0102eba:	83 ec 0c             	sub    $0xc,%esp
f0102ebd:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// TODO: Your code here.
	struct proc *p = thisproc();
f0102ec0:	e8 a4 fe ff ff       	call   f0102d69 <thisproc>
	switch (syscallno) {
f0102ec5:	83 fb 04             	cmp    $0x4,%ebx
f0102ec8:	0f 87 93 00 00 00    	ja     f0102f61 <syscall+0xad>
f0102ece:	ff 24 9d 0c 42 10 f0 	jmp    *-0xfefbdf4(,%ebx,4)
	struct proc *p = thisproc();
f0102ed5:	e8 8f fe ff ff       	call   f0102d69 <thisproc>
f0102eda:	89 c7                	mov    %eax,%edi
	void *begin = ROUNDDOWN(tmp, PGSIZE);
f0102edc:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102edf:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	void *end = ROUNDUP(tmp + len, PGSIZE);
f0102ee5:	8b 45 10             	mov    0x10(%ebp),%eax
f0102ee8:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102eeb:	8d b4 02 ff 0f 00 00 	lea    0xfff(%edx,%eax,1),%esi
f0102ef2:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
f0102ef8:	eb 05                	jmp    f0102eff <syscall+0x4b>
			exit();
f0102efa:	e8 4b ff ff ff       	call   f0102e4a <exit>
	while (begin < end) {
f0102eff:	39 de                	cmp    %ebx,%esi
f0102f01:	76 1d                	jbe    f0102f20 <syscall+0x6c>
		pte_t *pte = pgdir_walk(p->pgdir, begin, 0);
f0102f03:	83 ec 04             	sub    $0x4,%esp
f0102f06:	6a 00                	push   $0x0
f0102f08:	53                   	push   %ebx
f0102f09:	ff 37                	pushl  (%edi)
f0102f0b:	e8 42 e5 ff ff       	call   f0101452 <pgdir_walk>
		if (*pte & PTE_U)
f0102f10:	83 c4 10             	add    $0x10,%esp
f0102f13:	f6 00 04             	testb  $0x4,(%eax)
f0102f16:	74 e2                	je     f0102efa <syscall+0x46>
			begin += PGSIZE;
f0102f18:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102f1e:	eb df                	jmp    f0102eff <syscall+0x4b>
	cprintf(s);
f0102f20:	83 ec 0c             	sub    $0xc,%esp
f0102f23:	ff 75 0c             	pushl  0xc(%ebp)
f0102f26:	e8 57 d8 ff ff       	call   f0100782 <cprintf>
f0102f2b:	83 c4 10             	add    $0x10,%esp
		case SYS_cputs:
			sys_cputs((const char *)a1, (size_t)a2);
			return 0;
f0102f2e:	b8 00 00 00 00       	mov    $0x0,%eax
			return 0;
		default:
			return 0;
	}
	
f0102f33:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102f36:	5b                   	pop    %ebx
f0102f37:	5e                   	pop    %esi
f0102f38:	5f                   	pop    %edi
f0102f39:	5d                   	pop    %ebp
f0102f3a:	c3                   	ret    
	return cons_getc();
f0102f3b:	e8 87 d6 ff ff       	call   f01005c7 <cons_getc>
			return sys_cgetc();
f0102f40:	eb f1                	jmp    f0102f33 <syscall+0x7f>
	exit();
f0102f42:	e8 03 ff ff ff       	call   f0102e4a <exit>
			return 0;
f0102f47:	b8 00 00 00 00       	mov    $0x0,%eax
f0102f4c:	eb e5                	jmp    f0102f33 <syscall+0x7f>
	return fork();
f0102f4e:	e8 73 fe ff ff       	call   f0102dc6 <fork>
			return sys_fork();
f0102f53:	eb de                	jmp    f0102f33 <syscall+0x7f>
	yield();
f0102f55:	e8 1f ff ff ff       	call   f0102e79 <yield>
			return 0;
f0102f5a:	b8 00 00 00 00       	mov    $0x0,%eax
f0102f5f:	eb d2                	jmp    f0102f33 <syscall+0x7f>
			return 0;
f0102f61:	b8 00 00 00 00       	mov    $0x0,%eax
f0102f66:	eb cb                	jmp    f0102f33 <syscall+0x7f>

f0102f68 <swtch>:
# Switch stacks to new and pop previously-saved registers.

.globl swtch
swtch:
	# TODO: your code here
	movl 4(%esp), %eax # old
f0102f68:	8b 44 24 04          	mov    0x4(%esp),%eax
	movl 8(%esp), %edx # new
f0102f6c:	8b 54 24 08          	mov    0x8(%esp),%edx
	# Save old callee-saved registers
	pushl %ebp
f0102f70:	55                   	push   %ebp
	pushl %ebx
f0102f71:	53                   	push   %ebx
	pushl %esi
f0102f72:	56                   	push   %esi
	pushl %edi
f0102f73:	57                   	push   %edi
	# Switch stacks
	movl %esp, (%eax)
f0102f74:	89 20                	mov    %esp,(%eax)
	movl %edx, %esp
f0102f76:	89 d4                	mov    %edx,%esp
	# Load new callee-saved registers
	popl %edi
f0102f78:	5f                   	pop    %edi
	popl %esi
f0102f79:	5e                   	pop    %esi
	popl %ebx
f0102f7a:	5b                   	pop    %ebx
	popl %ebp
f0102f7b:	5d                   	pop    %ebp
f0102f7c:	c3                   	ret    

f0102f7d <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0102f7d:	55                   	push   %ebp
f0102f7e:	89 e5                	mov    %esp,%ebp
f0102f80:	57                   	push   %edi
f0102f81:	56                   	push   %esi
f0102f82:	53                   	push   %ebx
f0102f83:	83 ec 1c             	sub    $0x1c,%esp
f0102f86:	89 c7                	mov    %eax,%edi
f0102f88:	89 d6                	mov    %edx,%esi
f0102f8a:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f8d:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102f90:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102f93:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0102f96:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0102f99:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102f9e:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102fa1:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0102fa4:	39 d3                	cmp    %edx,%ebx
f0102fa6:	72 05                	jb     f0102fad <printnum+0x30>
f0102fa8:	39 45 10             	cmp    %eax,0x10(%ebp)
f0102fab:	77 7a                	ja     f0103027 <printnum+0xaa>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0102fad:	83 ec 0c             	sub    $0xc,%esp
f0102fb0:	ff 75 18             	pushl  0x18(%ebp)
f0102fb3:	8b 45 14             	mov    0x14(%ebp),%eax
f0102fb6:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0102fb9:	53                   	push   %ebx
f0102fba:	ff 75 10             	pushl  0x10(%ebp)
f0102fbd:	83 ec 08             	sub    $0x8,%esp
f0102fc0:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102fc3:	ff 75 e0             	pushl  -0x20(%ebp)
f0102fc6:	ff 75 dc             	pushl  -0x24(%ebp)
f0102fc9:	ff 75 d8             	pushl  -0x28(%ebp)
f0102fcc:	e8 df 09 00 00       	call   f01039b0 <__udivdi3>
f0102fd1:	83 c4 18             	add    $0x18,%esp
f0102fd4:	52                   	push   %edx
f0102fd5:	50                   	push   %eax
f0102fd6:	89 f2                	mov    %esi,%edx
f0102fd8:	89 f8                	mov    %edi,%eax
f0102fda:	e8 9e ff ff ff       	call   f0102f7d <printnum>
f0102fdf:	83 c4 20             	add    $0x20,%esp
f0102fe2:	eb 13                	jmp    f0102ff7 <printnum+0x7a>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0102fe4:	83 ec 08             	sub    $0x8,%esp
f0102fe7:	56                   	push   %esi
f0102fe8:	ff 75 18             	pushl  0x18(%ebp)
f0102feb:	ff d7                	call   *%edi
f0102fed:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f0102ff0:	83 eb 01             	sub    $0x1,%ebx
f0102ff3:	85 db                	test   %ebx,%ebx
f0102ff5:	7f ed                	jg     f0102fe4 <printnum+0x67>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0102ff7:	83 ec 08             	sub    $0x8,%esp
f0102ffa:	56                   	push   %esi
f0102ffb:	83 ec 04             	sub    $0x4,%esp
f0102ffe:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103001:	ff 75 e0             	pushl  -0x20(%ebp)
f0103004:	ff 75 dc             	pushl  -0x24(%ebp)
f0103007:	ff 75 d8             	pushl  -0x28(%ebp)
f010300a:	e8 c1 0a 00 00       	call   f0103ad0 <__umoddi3>
f010300f:	83 c4 14             	add    $0x14,%esp
f0103012:	0f be 80 20 42 10 f0 	movsbl -0xfefbde0(%eax),%eax
f0103019:	50                   	push   %eax
f010301a:	ff d7                	call   *%edi
}
f010301c:	83 c4 10             	add    $0x10,%esp
f010301f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103022:	5b                   	pop    %ebx
f0103023:	5e                   	pop    %esi
f0103024:	5f                   	pop    %edi
f0103025:	5d                   	pop    %ebp
f0103026:	c3                   	ret    
f0103027:	8b 5d 14             	mov    0x14(%ebp),%ebx
f010302a:	eb c4                	jmp    f0102ff0 <printnum+0x73>

f010302c <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f010302c:	55                   	push   %ebp
f010302d:	89 e5                	mov    %esp,%ebp
f010302f:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0103032:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103036:	8b 10                	mov    (%eax),%edx
f0103038:	3b 50 04             	cmp    0x4(%eax),%edx
f010303b:	73 0a                	jae    f0103047 <sprintputch+0x1b>
		*b->buf++ = ch;
f010303d:	8d 4a 01             	lea    0x1(%edx),%ecx
f0103040:	89 08                	mov    %ecx,(%eax)
f0103042:	8b 45 08             	mov    0x8(%ebp),%eax
f0103045:	88 02                	mov    %al,(%edx)
}
f0103047:	5d                   	pop    %ebp
f0103048:	c3                   	ret    

f0103049 <printfmt>:
{
f0103049:	55                   	push   %ebp
f010304a:	89 e5                	mov    %esp,%ebp
f010304c:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f010304f:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0103052:	50                   	push   %eax
f0103053:	ff 75 10             	pushl  0x10(%ebp)
f0103056:	ff 75 0c             	pushl  0xc(%ebp)
f0103059:	ff 75 08             	pushl  0x8(%ebp)
f010305c:	e8 05 00 00 00       	call   f0103066 <vprintfmt>
}
f0103061:	83 c4 10             	add    $0x10,%esp
f0103064:	c9                   	leave  
f0103065:	c3                   	ret    

f0103066 <vprintfmt>:
{
f0103066:	55                   	push   %ebp
f0103067:	89 e5                	mov    %esp,%ebp
f0103069:	57                   	push   %edi
f010306a:	56                   	push   %esi
f010306b:	53                   	push   %ebx
f010306c:	83 ec 2c             	sub    $0x2c,%esp
f010306f:	8b 75 08             	mov    0x8(%ebp),%esi
f0103072:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103075:	8b 7d 10             	mov    0x10(%ebp),%edi
f0103078:	e9 c1 03 00 00       	jmp    f010343e <vprintfmt+0x3d8>
		padc = ' ';
f010307d:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
f0103081:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
f0103088:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
		width = -1;
f010308f:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f0103096:	b9 00 00 00 00       	mov    $0x0,%ecx
		switch (ch = *(unsigned char *) fmt++) {
f010309b:	8d 47 01             	lea    0x1(%edi),%eax
f010309e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01030a1:	0f b6 17             	movzbl (%edi),%edx
f01030a4:	8d 42 dd             	lea    -0x23(%edx),%eax
f01030a7:	3c 55                	cmp    $0x55,%al
f01030a9:	0f 87 12 04 00 00    	ja     f01034c1 <vprintfmt+0x45b>
f01030af:	0f b6 c0             	movzbl %al,%eax
f01030b2:	ff 24 85 ac 42 10 f0 	jmp    *-0xfefbd54(,%eax,4)
f01030b9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f01030bc:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f01030c0:	eb d9                	jmp    f010309b <vprintfmt+0x35>
		switch (ch = *(unsigned char *) fmt++) {
f01030c2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '0';
f01030c5:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f01030c9:	eb d0                	jmp    f010309b <vprintfmt+0x35>
		switch (ch = *(unsigned char *) fmt++) {
f01030cb:	0f b6 d2             	movzbl %dl,%edx
f01030ce:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f01030d1:	b8 00 00 00 00       	mov    $0x0,%eax
f01030d6:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
				precision = precision * 10 + ch - '0';
f01030d9:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01030dc:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f01030e0:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f01030e3:	8d 4a d0             	lea    -0x30(%edx),%ecx
f01030e6:	83 f9 09             	cmp    $0x9,%ecx
f01030e9:	77 55                	ja     f0103140 <vprintfmt+0xda>
			for (precision = 0; ; ++fmt) {
f01030eb:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f01030ee:	eb e9                	jmp    f01030d9 <vprintfmt+0x73>
			precision = va_arg(ap, int);
f01030f0:	8b 45 14             	mov    0x14(%ebp),%eax
f01030f3:	8b 00                	mov    (%eax),%eax
f01030f5:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01030f8:	8b 45 14             	mov    0x14(%ebp),%eax
f01030fb:	8d 40 04             	lea    0x4(%eax),%eax
f01030fe:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0103101:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f0103104:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103108:	79 91                	jns    f010309b <vprintfmt+0x35>
				width = precision, precision = -1;
f010310a:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010310d:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103110:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103117:	eb 82                	jmp    f010309b <vprintfmt+0x35>
f0103119:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010311c:	85 c0                	test   %eax,%eax
f010311e:	ba 00 00 00 00       	mov    $0x0,%edx
f0103123:	0f 49 d0             	cmovns %eax,%edx
f0103126:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0103129:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010312c:	e9 6a ff ff ff       	jmp    f010309b <vprintfmt+0x35>
f0103131:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f0103134:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f010313b:	e9 5b ff ff ff       	jmp    f010309b <vprintfmt+0x35>
f0103140:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0103143:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103146:	eb bc                	jmp    f0103104 <vprintfmt+0x9e>
			lflag++;
f0103148:	83 c1 01             	add    $0x1,%ecx
		switch (ch = *(unsigned char *) fmt++) {
f010314b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f010314e:	e9 48 ff ff ff       	jmp    f010309b <vprintfmt+0x35>
			putch(va_arg(ap, int), putdat);
f0103153:	8b 45 14             	mov    0x14(%ebp),%eax
f0103156:	8d 78 04             	lea    0x4(%eax),%edi
f0103159:	83 ec 08             	sub    $0x8,%esp
f010315c:	53                   	push   %ebx
f010315d:	ff 30                	pushl  (%eax)
f010315f:	ff d6                	call   *%esi
			break;
f0103161:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f0103164:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f0103167:	e9 cf 02 00 00       	jmp    f010343b <vprintfmt+0x3d5>
			err = va_arg(ap, int);
f010316c:	8b 45 14             	mov    0x14(%ebp),%eax
f010316f:	8d 78 04             	lea    0x4(%eax),%edi
f0103172:	8b 00                	mov    (%eax),%eax
f0103174:	99                   	cltd   
f0103175:	31 d0                	xor    %edx,%eax
f0103177:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0103179:	83 f8 06             	cmp    $0x6,%eax
f010317c:	7f 23                	jg     f01031a1 <vprintfmt+0x13b>
f010317e:	8b 14 85 04 44 10 f0 	mov    -0xfefbbfc(,%eax,4),%edx
f0103185:	85 d2                	test   %edx,%edx
f0103187:	74 18                	je     f01031a1 <vprintfmt+0x13b>
				printfmt(putch, putdat, "%s", p);
f0103189:	52                   	push   %edx
f010318a:	68 10 3f 10 f0       	push   $0xf0103f10
f010318f:	53                   	push   %ebx
f0103190:	56                   	push   %esi
f0103191:	e8 b3 fe ff ff       	call   f0103049 <printfmt>
f0103196:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0103199:	89 7d 14             	mov    %edi,0x14(%ebp)
f010319c:	e9 9a 02 00 00       	jmp    f010343b <vprintfmt+0x3d5>
				printfmt(putch, putdat, "error %d", err);
f01031a1:	50                   	push   %eax
f01031a2:	68 38 42 10 f0       	push   $0xf0104238
f01031a7:	53                   	push   %ebx
f01031a8:	56                   	push   %esi
f01031a9:	e8 9b fe ff ff       	call   f0103049 <printfmt>
f01031ae:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f01031b1:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f01031b4:	e9 82 02 00 00       	jmp    f010343b <vprintfmt+0x3d5>
			if ((p = va_arg(ap, char *)) == NULL)
f01031b9:	8b 45 14             	mov    0x14(%ebp),%eax
f01031bc:	83 c0 04             	add    $0x4,%eax
f01031bf:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01031c2:	8b 45 14             	mov    0x14(%ebp),%eax
f01031c5:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f01031c7:	85 ff                	test   %edi,%edi
f01031c9:	b8 31 42 10 f0       	mov    $0xf0104231,%eax
f01031ce:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f01031d1:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01031d5:	0f 8e bd 00 00 00    	jle    f0103298 <vprintfmt+0x232>
f01031db:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f01031df:	75 0e                	jne    f01031ef <vprintfmt+0x189>
f01031e1:	89 75 08             	mov    %esi,0x8(%ebp)
f01031e4:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01031e7:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01031ea:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f01031ed:	eb 6d                	jmp    f010325c <vprintfmt+0x1f6>
				for (width -= strnlen(p, precision); width > 0; width--)
f01031ef:	83 ec 08             	sub    $0x8,%esp
f01031f2:	ff 75 d0             	pushl  -0x30(%ebp)
f01031f5:	57                   	push   %edi
f01031f6:	e8 50 04 00 00       	call   f010364b <strnlen>
f01031fb:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f01031fe:	29 c1                	sub    %eax,%ecx
f0103200:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0103203:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0103206:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f010320a:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010320d:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103210:	89 cf                	mov    %ecx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f0103212:	eb 0f                	jmp    f0103223 <vprintfmt+0x1bd>
					putch(padc, putdat);
f0103214:	83 ec 08             	sub    $0x8,%esp
f0103217:	53                   	push   %ebx
f0103218:	ff 75 e0             	pushl  -0x20(%ebp)
f010321b:	ff d6                	call   *%esi
				for (width -= strnlen(p, precision); width > 0; width--)
f010321d:	83 ef 01             	sub    $0x1,%edi
f0103220:	83 c4 10             	add    $0x10,%esp
f0103223:	85 ff                	test   %edi,%edi
f0103225:	7f ed                	jg     f0103214 <vprintfmt+0x1ae>
f0103227:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010322a:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f010322d:	85 c9                	test   %ecx,%ecx
f010322f:	b8 00 00 00 00       	mov    $0x0,%eax
f0103234:	0f 49 c1             	cmovns %ecx,%eax
f0103237:	29 c1                	sub    %eax,%ecx
f0103239:	89 75 08             	mov    %esi,0x8(%ebp)
f010323c:	8b 75 d0             	mov    -0x30(%ebp),%esi
f010323f:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103242:	89 cb                	mov    %ecx,%ebx
f0103244:	eb 16                	jmp    f010325c <vprintfmt+0x1f6>
				if (altflag && (ch < ' ' || ch > '~'))
f0103246:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f010324a:	75 31                	jne    f010327d <vprintfmt+0x217>
					putch(ch, putdat);
f010324c:	83 ec 08             	sub    $0x8,%esp
f010324f:	ff 75 0c             	pushl  0xc(%ebp)
f0103252:	50                   	push   %eax
f0103253:	ff 55 08             	call   *0x8(%ebp)
f0103256:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103259:	83 eb 01             	sub    $0x1,%ebx
f010325c:	83 c7 01             	add    $0x1,%edi
f010325f:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
f0103263:	0f be c2             	movsbl %dl,%eax
f0103266:	85 c0                	test   %eax,%eax
f0103268:	74 59                	je     f01032c3 <vprintfmt+0x25d>
f010326a:	85 f6                	test   %esi,%esi
f010326c:	78 d8                	js     f0103246 <vprintfmt+0x1e0>
f010326e:	83 ee 01             	sub    $0x1,%esi
f0103271:	79 d3                	jns    f0103246 <vprintfmt+0x1e0>
f0103273:	89 df                	mov    %ebx,%edi
f0103275:	8b 75 08             	mov    0x8(%ebp),%esi
f0103278:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010327b:	eb 37                	jmp    f01032b4 <vprintfmt+0x24e>
				if (altflag && (ch < ' ' || ch > '~'))
f010327d:	0f be d2             	movsbl %dl,%edx
f0103280:	83 ea 20             	sub    $0x20,%edx
f0103283:	83 fa 5e             	cmp    $0x5e,%edx
f0103286:	76 c4                	jbe    f010324c <vprintfmt+0x1e6>
					putch('?', putdat);
f0103288:	83 ec 08             	sub    $0x8,%esp
f010328b:	ff 75 0c             	pushl  0xc(%ebp)
f010328e:	6a 3f                	push   $0x3f
f0103290:	ff 55 08             	call   *0x8(%ebp)
f0103293:	83 c4 10             	add    $0x10,%esp
f0103296:	eb c1                	jmp    f0103259 <vprintfmt+0x1f3>
f0103298:	89 75 08             	mov    %esi,0x8(%ebp)
f010329b:	8b 75 d0             	mov    -0x30(%ebp),%esi
f010329e:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01032a1:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f01032a4:	eb b6                	jmp    f010325c <vprintfmt+0x1f6>
				putch(' ', putdat);
f01032a6:	83 ec 08             	sub    $0x8,%esp
f01032a9:	53                   	push   %ebx
f01032aa:	6a 20                	push   $0x20
f01032ac:	ff d6                	call   *%esi
			for (; width > 0; width--)
f01032ae:	83 ef 01             	sub    $0x1,%edi
f01032b1:	83 c4 10             	add    $0x10,%esp
f01032b4:	85 ff                	test   %edi,%edi
f01032b6:	7f ee                	jg     f01032a6 <vprintfmt+0x240>
			if ((p = va_arg(ap, char *)) == NULL)
f01032b8:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01032bb:	89 45 14             	mov    %eax,0x14(%ebp)
f01032be:	e9 78 01 00 00       	jmp    f010343b <vprintfmt+0x3d5>
f01032c3:	89 df                	mov    %ebx,%edi
f01032c5:	8b 75 08             	mov    0x8(%ebp),%esi
f01032c8:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01032cb:	eb e7                	jmp    f01032b4 <vprintfmt+0x24e>
	if (lflag >= 2)
f01032cd:	83 f9 01             	cmp    $0x1,%ecx
f01032d0:	7e 3f                	jle    f0103311 <vprintfmt+0x2ab>
		return va_arg(*ap, long long);
f01032d2:	8b 45 14             	mov    0x14(%ebp),%eax
f01032d5:	8b 50 04             	mov    0x4(%eax),%edx
f01032d8:	8b 00                	mov    (%eax),%eax
f01032da:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01032dd:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01032e0:	8b 45 14             	mov    0x14(%ebp),%eax
f01032e3:	8d 40 08             	lea    0x8(%eax),%eax
f01032e6:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f01032e9:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01032ed:	79 5c                	jns    f010334b <vprintfmt+0x2e5>
				putch('-', putdat);
f01032ef:	83 ec 08             	sub    $0x8,%esp
f01032f2:	53                   	push   %ebx
f01032f3:	6a 2d                	push   $0x2d
f01032f5:	ff d6                	call   *%esi
				num = -(long long) num;
f01032f7:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01032fa:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01032fd:	f7 da                	neg    %edx
f01032ff:	83 d1 00             	adc    $0x0,%ecx
f0103302:	f7 d9                	neg    %ecx
f0103304:	83 c4 10             	add    $0x10,%esp
			base = 10;
f0103307:	b8 0a 00 00 00       	mov    $0xa,%eax
f010330c:	e9 10 01 00 00       	jmp    f0103421 <vprintfmt+0x3bb>
	else if (lflag)
f0103311:	85 c9                	test   %ecx,%ecx
f0103313:	75 1b                	jne    f0103330 <vprintfmt+0x2ca>
		return va_arg(*ap, int);
f0103315:	8b 45 14             	mov    0x14(%ebp),%eax
f0103318:	8b 00                	mov    (%eax),%eax
f010331a:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010331d:	89 c1                	mov    %eax,%ecx
f010331f:	c1 f9 1f             	sar    $0x1f,%ecx
f0103322:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0103325:	8b 45 14             	mov    0x14(%ebp),%eax
f0103328:	8d 40 04             	lea    0x4(%eax),%eax
f010332b:	89 45 14             	mov    %eax,0x14(%ebp)
f010332e:	eb b9                	jmp    f01032e9 <vprintfmt+0x283>
		return va_arg(*ap, long);
f0103330:	8b 45 14             	mov    0x14(%ebp),%eax
f0103333:	8b 00                	mov    (%eax),%eax
f0103335:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103338:	89 c1                	mov    %eax,%ecx
f010333a:	c1 f9 1f             	sar    $0x1f,%ecx
f010333d:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0103340:	8b 45 14             	mov    0x14(%ebp),%eax
f0103343:	8d 40 04             	lea    0x4(%eax),%eax
f0103346:	89 45 14             	mov    %eax,0x14(%ebp)
f0103349:	eb 9e                	jmp    f01032e9 <vprintfmt+0x283>
			num = getint(&ap, lflag);
f010334b:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010334e:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f0103351:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103356:	e9 c6 00 00 00       	jmp    f0103421 <vprintfmt+0x3bb>
	if (lflag >= 2)
f010335b:	83 f9 01             	cmp    $0x1,%ecx
f010335e:	7e 18                	jle    f0103378 <vprintfmt+0x312>
		return va_arg(*ap, unsigned long long);
f0103360:	8b 45 14             	mov    0x14(%ebp),%eax
f0103363:	8b 10                	mov    (%eax),%edx
f0103365:	8b 48 04             	mov    0x4(%eax),%ecx
f0103368:	8d 40 08             	lea    0x8(%eax),%eax
f010336b:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f010336e:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103373:	e9 a9 00 00 00       	jmp    f0103421 <vprintfmt+0x3bb>
	else if (lflag)
f0103378:	85 c9                	test   %ecx,%ecx
f010337a:	75 1a                	jne    f0103396 <vprintfmt+0x330>
		return va_arg(*ap, unsigned int);
f010337c:	8b 45 14             	mov    0x14(%ebp),%eax
f010337f:	8b 10                	mov    (%eax),%edx
f0103381:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103386:	8d 40 04             	lea    0x4(%eax),%eax
f0103389:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f010338c:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103391:	e9 8b 00 00 00       	jmp    f0103421 <vprintfmt+0x3bb>
		return va_arg(*ap, unsigned long);
f0103396:	8b 45 14             	mov    0x14(%ebp),%eax
f0103399:	8b 10                	mov    (%eax),%edx
f010339b:	b9 00 00 00 00       	mov    $0x0,%ecx
f01033a0:	8d 40 04             	lea    0x4(%eax),%eax
f01033a3:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01033a6:	b8 0a 00 00 00       	mov    $0xa,%eax
f01033ab:	eb 74                	jmp    f0103421 <vprintfmt+0x3bb>
	if (lflag >= 2)
f01033ad:	83 f9 01             	cmp    $0x1,%ecx
f01033b0:	7e 15                	jle    f01033c7 <vprintfmt+0x361>
		return va_arg(*ap, unsigned long long);
f01033b2:	8b 45 14             	mov    0x14(%ebp),%eax
f01033b5:	8b 10                	mov    (%eax),%edx
f01033b7:	8b 48 04             	mov    0x4(%eax),%ecx
f01033ba:	8d 40 08             	lea    0x8(%eax),%eax
f01033bd:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f01033c0:	b8 08 00 00 00       	mov    $0x8,%eax
f01033c5:	eb 5a                	jmp    f0103421 <vprintfmt+0x3bb>
	else if (lflag)
f01033c7:	85 c9                	test   %ecx,%ecx
f01033c9:	75 17                	jne    f01033e2 <vprintfmt+0x37c>
		return va_arg(*ap, unsigned int);
f01033cb:	8b 45 14             	mov    0x14(%ebp),%eax
f01033ce:	8b 10                	mov    (%eax),%edx
f01033d0:	b9 00 00 00 00       	mov    $0x0,%ecx
f01033d5:	8d 40 04             	lea    0x4(%eax),%eax
f01033d8:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f01033db:	b8 08 00 00 00       	mov    $0x8,%eax
f01033e0:	eb 3f                	jmp    f0103421 <vprintfmt+0x3bb>
		return va_arg(*ap, unsigned long);
f01033e2:	8b 45 14             	mov    0x14(%ebp),%eax
f01033e5:	8b 10                	mov    (%eax),%edx
f01033e7:	b9 00 00 00 00       	mov    $0x0,%ecx
f01033ec:	8d 40 04             	lea    0x4(%eax),%eax
f01033ef:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f01033f2:	b8 08 00 00 00       	mov    $0x8,%eax
f01033f7:	eb 28                	jmp    f0103421 <vprintfmt+0x3bb>
			putch('0', putdat);
f01033f9:	83 ec 08             	sub    $0x8,%esp
f01033fc:	53                   	push   %ebx
f01033fd:	6a 30                	push   $0x30
f01033ff:	ff d6                	call   *%esi
			putch('x', putdat);
f0103401:	83 c4 08             	add    $0x8,%esp
f0103404:	53                   	push   %ebx
f0103405:	6a 78                	push   $0x78
f0103407:	ff d6                	call   *%esi
			num = (unsigned long long)
f0103409:	8b 45 14             	mov    0x14(%ebp),%eax
f010340c:	8b 10                	mov    (%eax),%edx
f010340e:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f0103413:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f0103416:	8d 40 04             	lea    0x4(%eax),%eax
f0103419:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010341c:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f0103421:	83 ec 0c             	sub    $0xc,%esp
f0103424:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0103428:	57                   	push   %edi
f0103429:	ff 75 e0             	pushl  -0x20(%ebp)
f010342c:	50                   	push   %eax
f010342d:	51                   	push   %ecx
f010342e:	52                   	push   %edx
f010342f:	89 da                	mov    %ebx,%edx
f0103431:	89 f0                	mov    %esi,%eax
f0103433:	e8 45 fb ff ff       	call   f0102f7d <printnum>
			break;
f0103438:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f010343b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f010343e:	83 c7 01             	add    $0x1,%edi
f0103441:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103445:	83 f8 25             	cmp    $0x25,%eax
f0103448:	0f 84 2f fc ff ff    	je     f010307d <vprintfmt+0x17>
			if (ch == '\0')
f010344e:	85 c0                	test   %eax,%eax
f0103450:	0f 84 8b 00 00 00    	je     f01034e1 <vprintfmt+0x47b>
			putch(ch, putdat);
f0103456:	83 ec 08             	sub    $0x8,%esp
f0103459:	53                   	push   %ebx
f010345a:	50                   	push   %eax
f010345b:	ff d6                	call   *%esi
f010345d:	83 c4 10             	add    $0x10,%esp
f0103460:	eb dc                	jmp    f010343e <vprintfmt+0x3d8>
	if (lflag >= 2)
f0103462:	83 f9 01             	cmp    $0x1,%ecx
f0103465:	7e 15                	jle    f010347c <vprintfmt+0x416>
		return va_arg(*ap, unsigned long long);
f0103467:	8b 45 14             	mov    0x14(%ebp),%eax
f010346a:	8b 10                	mov    (%eax),%edx
f010346c:	8b 48 04             	mov    0x4(%eax),%ecx
f010346f:	8d 40 08             	lea    0x8(%eax),%eax
f0103472:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0103475:	b8 10 00 00 00       	mov    $0x10,%eax
f010347a:	eb a5                	jmp    f0103421 <vprintfmt+0x3bb>
	else if (lflag)
f010347c:	85 c9                	test   %ecx,%ecx
f010347e:	75 17                	jne    f0103497 <vprintfmt+0x431>
		return va_arg(*ap, unsigned int);
f0103480:	8b 45 14             	mov    0x14(%ebp),%eax
f0103483:	8b 10                	mov    (%eax),%edx
f0103485:	b9 00 00 00 00       	mov    $0x0,%ecx
f010348a:	8d 40 04             	lea    0x4(%eax),%eax
f010348d:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0103490:	b8 10 00 00 00       	mov    $0x10,%eax
f0103495:	eb 8a                	jmp    f0103421 <vprintfmt+0x3bb>
		return va_arg(*ap, unsigned long);
f0103497:	8b 45 14             	mov    0x14(%ebp),%eax
f010349a:	8b 10                	mov    (%eax),%edx
f010349c:	b9 00 00 00 00       	mov    $0x0,%ecx
f01034a1:	8d 40 04             	lea    0x4(%eax),%eax
f01034a4:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01034a7:	b8 10 00 00 00       	mov    $0x10,%eax
f01034ac:	e9 70 ff ff ff       	jmp    f0103421 <vprintfmt+0x3bb>
			putch(ch, putdat);
f01034b1:	83 ec 08             	sub    $0x8,%esp
f01034b4:	53                   	push   %ebx
f01034b5:	6a 25                	push   $0x25
f01034b7:	ff d6                	call   *%esi
			break;
f01034b9:	83 c4 10             	add    $0x10,%esp
f01034bc:	e9 7a ff ff ff       	jmp    f010343b <vprintfmt+0x3d5>
			putch('%', putdat);
f01034c1:	83 ec 08             	sub    $0x8,%esp
f01034c4:	53                   	push   %ebx
f01034c5:	6a 25                	push   $0x25
f01034c7:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01034c9:	83 c4 10             	add    $0x10,%esp
f01034cc:	89 f8                	mov    %edi,%eax
f01034ce:	eb 03                	jmp    f01034d3 <vprintfmt+0x46d>
f01034d0:	83 e8 01             	sub    $0x1,%eax
f01034d3:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f01034d7:	75 f7                	jne    f01034d0 <vprintfmt+0x46a>
f01034d9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01034dc:	e9 5a ff ff ff       	jmp    f010343b <vprintfmt+0x3d5>
}
f01034e1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01034e4:	5b                   	pop    %ebx
f01034e5:	5e                   	pop    %esi
f01034e6:	5f                   	pop    %edi
f01034e7:	5d                   	pop    %ebp
f01034e8:	c3                   	ret    

f01034e9 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01034e9:	55                   	push   %ebp
f01034ea:	89 e5                	mov    %esp,%ebp
f01034ec:	83 ec 18             	sub    $0x18,%esp
f01034ef:	8b 45 08             	mov    0x8(%ebp),%eax
f01034f2:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01034f5:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01034f8:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01034fc:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01034ff:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0103506:	85 c0                	test   %eax,%eax
f0103508:	74 26                	je     f0103530 <vsnprintf+0x47>
f010350a:	85 d2                	test   %edx,%edx
f010350c:	7e 22                	jle    f0103530 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010350e:	ff 75 14             	pushl  0x14(%ebp)
f0103511:	ff 75 10             	pushl  0x10(%ebp)
f0103514:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103517:	50                   	push   %eax
f0103518:	68 2c 30 10 f0       	push   $0xf010302c
f010351d:	e8 44 fb ff ff       	call   f0103066 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103522:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103525:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0103528:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010352b:	83 c4 10             	add    $0x10,%esp
}
f010352e:	c9                   	leave  
f010352f:	c3                   	ret    
		return -E_INVAL;
f0103530:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0103535:	eb f7                	jmp    f010352e <vsnprintf+0x45>

f0103537 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0103537:	55                   	push   %ebp
f0103538:	89 e5                	mov    %esp,%ebp
f010353a:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010353d:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103540:	50                   	push   %eax
f0103541:	ff 75 10             	pushl  0x10(%ebp)
f0103544:	ff 75 0c             	pushl  0xc(%ebp)
f0103547:	ff 75 08             	pushl  0x8(%ebp)
f010354a:	e8 9a ff ff ff       	call   f01034e9 <vsnprintf>
	va_end(ap);

	return rc;
}
f010354f:	c9                   	leave  
f0103550:	c3                   	ret    

f0103551 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103551:	55                   	push   %ebp
f0103552:	89 e5                	mov    %esp,%ebp
f0103554:	57                   	push   %edi
f0103555:	56                   	push   %esi
f0103556:	53                   	push   %ebx
f0103557:	83 ec 0c             	sub    $0xc,%esp
f010355a:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010355d:	85 c0                	test   %eax,%eax
f010355f:	74 11                	je     f0103572 <readline+0x21>
		cprintf("%s", prompt);
f0103561:	83 ec 08             	sub    $0x8,%esp
f0103564:	50                   	push   %eax
f0103565:	68 10 3f 10 f0       	push   $0xf0103f10
f010356a:	e8 13 d2 ff ff       	call   f0100782 <cprintf>
f010356f:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0103572:	83 ec 0c             	sub    $0xc,%esp
f0103575:	6a 00                	push   $0x0
f0103577:	e8 c3 d1 ff ff       	call   f010073f <iscons>
f010357c:	89 c7                	mov    %eax,%edi
f010357e:	83 c4 10             	add    $0x10,%esp
	i = 0;
f0103581:	be 00 00 00 00       	mov    $0x0,%esi
f0103586:	eb 3f                	jmp    f01035c7 <readline+0x76>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f0103588:	83 ec 08             	sub    $0x8,%esp
f010358b:	50                   	push   %eax
f010358c:	68 20 44 10 f0       	push   $0xf0104420
f0103591:	e8 ec d1 ff ff       	call   f0100782 <cprintf>
			return NULL;
f0103596:	83 c4 10             	add    $0x10,%esp
f0103599:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f010359e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01035a1:	5b                   	pop    %ebx
f01035a2:	5e                   	pop    %esi
f01035a3:	5f                   	pop    %edi
f01035a4:	5d                   	pop    %ebp
f01035a5:	c3                   	ret    
			if (echoing)
f01035a6:	85 ff                	test   %edi,%edi
f01035a8:	75 05                	jne    f01035af <readline+0x5e>
			i--;
f01035aa:	83 ee 01             	sub    $0x1,%esi
f01035ad:	eb 18                	jmp    f01035c7 <readline+0x76>
				cputchar('\b');
f01035af:	83 ec 0c             	sub    $0xc,%esp
f01035b2:	6a 08                	push   $0x8
f01035b4:	e8 65 d1 ff ff       	call   f010071e <cputchar>
f01035b9:	83 c4 10             	add    $0x10,%esp
f01035bc:	eb ec                	jmp    f01035aa <readline+0x59>
			buf[i++] = c;
f01035be:	88 9e 40 32 12 f0    	mov    %bl,-0xfedcdc0(%esi)
f01035c4:	8d 76 01             	lea    0x1(%esi),%esi
		c = getchar();
f01035c7:	e8 62 d1 ff ff       	call   f010072e <getchar>
f01035cc:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01035ce:	85 c0                	test   %eax,%eax
f01035d0:	78 b6                	js     f0103588 <readline+0x37>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01035d2:	83 f8 08             	cmp    $0x8,%eax
f01035d5:	0f 94 c2             	sete   %dl
f01035d8:	83 f8 7f             	cmp    $0x7f,%eax
f01035db:	0f 94 c0             	sete   %al
f01035de:	08 c2                	or     %al,%dl
f01035e0:	74 04                	je     f01035e6 <readline+0x95>
f01035e2:	85 f6                	test   %esi,%esi
f01035e4:	7f c0                	jg     f01035a6 <readline+0x55>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01035e6:	83 fb 1f             	cmp    $0x1f,%ebx
f01035e9:	7e 1a                	jle    f0103605 <readline+0xb4>
f01035eb:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01035f1:	7f 12                	jg     f0103605 <readline+0xb4>
			if (echoing)
f01035f3:	85 ff                	test   %edi,%edi
f01035f5:	74 c7                	je     f01035be <readline+0x6d>
				cputchar(c);
f01035f7:	83 ec 0c             	sub    $0xc,%esp
f01035fa:	53                   	push   %ebx
f01035fb:	e8 1e d1 ff ff       	call   f010071e <cputchar>
f0103600:	83 c4 10             	add    $0x10,%esp
f0103603:	eb b9                	jmp    f01035be <readline+0x6d>
		} else if (c == '\n' || c == '\r') {
f0103605:	83 fb 0a             	cmp    $0xa,%ebx
f0103608:	74 05                	je     f010360f <readline+0xbe>
f010360a:	83 fb 0d             	cmp    $0xd,%ebx
f010360d:	75 b8                	jne    f01035c7 <readline+0x76>
			if (echoing)
f010360f:	85 ff                	test   %edi,%edi
f0103611:	75 11                	jne    f0103624 <readline+0xd3>
			buf[i] = 0;
f0103613:	c6 86 40 32 12 f0 00 	movb   $0x0,-0xfedcdc0(%esi)
			return buf;
f010361a:	b8 40 32 12 f0       	mov    $0xf0123240,%eax
f010361f:	e9 7a ff ff ff       	jmp    f010359e <readline+0x4d>
				cputchar('\n');
f0103624:	83 ec 0c             	sub    $0xc,%esp
f0103627:	6a 0a                	push   $0xa
f0103629:	e8 f0 d0 ff ff       	call   f010071e <cputchar>
f010362e:	83 c4 10             	add    $0x10,%esp
f0103631:	eb e0                	jmp    f0103613 <readline+0xc2>

f0103633 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103633:	55                   	push   %ebp
f0103634:	89 e5                	mov    %esp,%ebp
f0103636:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103639:	b8 00 00 00 00       	mov    $0x0,%eax
f010363e:	eb 03                	jmp    f0103643 <strlen+0x10>
		n++;
f0103640:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f0103643:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103647:	75 f7                	jne    f0103640 <strlen+0xd>
	return n;
}
f0103649:	5d                   	pop    %ebp
f010364a:	c3                   	ret    

f010364b <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010364b:	55                   	push   %ebp
f010364c:	89 e5                	mov    %esp,%ebp
f010364e:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103651:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103654:	b8 00 00 00 00       	mov    $0x0,%eax
f0103659:	eb 03                	jmp    f010365e <strnlen+0x13>
		n++;
f010365b:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010365e:	39 d0                	cmp    %edx,%eax
f0103660:	74 06                	je     f0103668 <strnlen+0x1d>
f0103662:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0103666:	75 f3                	jne    f010365b <strnlen+0x10>
	return n;
}
f0103668:	5d                   	pop    %ebp
f0103669:	c3                   	ret    

f010366a <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010366a:	55                   	push   %ebp
f010366b:	89 e5                	mov    %esp,%ebp
f010366d:	53                   	push   %ebx
f010366e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103671:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103674:	89 c2                	mov    %eax,%edx
f0103676:	83 c1 01             	add    $0x1,%ecx
f0103679:	83 c2 01             	add    $0x1,%edx
f010367c:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0103680:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103683:	84 db                	test   %bl,%bl
f0103685:	75 ef                	jne    f0103676 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103687:	5b                   	pop    %ebx
f0103688:	5d                   	pop    %ebp
f0103689:	c3                   	ret    

f010368a <strcat>:

char *
strcat(char *dst, const char *src)
{
f010368a:	55                   	push   %ebp
f010368b:	89 e5                	mov    %esp,%ebp
f010368d:	53                   	push   %ebx
f010368e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103691:	53                   	push   %ebx
f0103692:	e8 9c ff ff ff       	call   f0103633 <strlen>
f0103697:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f010369a:	ff 75 0c             	pushl  0xc(%ebp)
f010369d:	01 d8                	add    %ebx,%eax
f010369f:	50                   	push   %eax
f01036a0:	e8 c5 ff ff ff       	call   f010366a <strcpy>
	return dst;
}
f01036a5:	89 d8                	mov    %ebx,%eax
f01036a7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01036aa:	c9                   	leave  
f01036ab:	c3                   	ret    

f01036ac <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01036ac:	55                   	push   %ebp
f01036ad:	89 e5                	mov    %esp,%ebp
f01036af:	56                   	push   %esi
f01036b0:	53                   	push   %ebx
f01036b1:	8b 75 08             	mov    0x8(%ebp),%esi
f01036b4:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01036b7:	89 f3                	mov    %esi,%ebx
f01036b9:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01036bc:	89 f2                	mov    %esi,%edx
f01036be:	eb 0f                	jmp    f01036cf <strncpy+0x23>
		*dst++ = *src;
f01036c0:	83 c2 01             	add    $0x1,%edx
f01036c3:	0f b6 01             	movzbl (%ecx),%eax
f01036c6:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01036c9:	80 39 01             	cmpb   $0x1,(%ecx)
f01036cc:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f01036cf:	39 da                	cmp    %ebx,%edx
f01036d1:	75 ed                	jne    f01036c0 <strncpy+0x14>
	}
	return ret;
}
f01036d3:	89 f0                	mov    %esi,%eax
f01036d5:	5b                   	pop    %ebx
f01036d6:	5e                   	pop    %esi
f01036d7:	5d                   	pop    %ebp
f01036d8:	c3                   	ret    

f01036d9 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01036d9:	55                   	push   %ebp
f01036da:	89 e5                	mov    %esp,%ebp
f01036dc:	56                   	push   %esi
f01036dd:	53                   	push   %ebx
f01036de:	8b 75 08             	mov    0x8(%ebp),%esi
f01036e1:	8b 55 0c             	mov    0xc(%ebp),%edx
f01036e4:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01036e7:	89 f0                	mov    %esi,%eax
f01036e9:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01036ed:	85 c9                	test   %ecx,%ecx
f01036ef:	75 0b                	jne    f01036fc <strlcpy+0x23>
f01036f1:	eb 17                	jmp    f010370a <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01036f3:	83 c2 01             	add    $0x1,%edx
f01036f6:	83 c0 01             	add    $0x1,%eax
f01036f9:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f01036fc:	39 d8                	cmp    %ebx,%eax
f01036fe:	74 07                	je     f0103707 <strlcpy+0x2e>
f0103700:	0f b6 0a             	movzbl (%edx),%ecx
f0103703:	84 c9                	test   %cl,%cl
f0103705:	75 ec                	jne    f01036f3 <strlcpy+0x1a>
		*dst = '\0';
f0103707:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f010370a:	29 f0                	sub    %esi,%eax
}
f010370c:	5b                   	pop    %ebx
f010370d:	5e                   	pop    %esi
f010370e:	5d                   	pop    %ebp
f010370f:	c3                   	ret    

f0103710 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103710:	55                   	push   %ebp
f0103711:	89 e5                	mov    %esp,%ebp
f0103713:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103716:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103719:	eb 06                	jmp    f0103721 <strcmp+0x11>
		p++, q++;
f010371b:	83 c1 01             	add    $0x1,%ecx
f010371e:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f0103721:	0f b6 01             	movzbl (%ecx),%eax
f0103724:	84 c0                	test   %al,%al
f0103726:	74 04                	je     f010372c <strcmp+0x1c>
f0103728:	3a 02                	cmp    (%edx),%al
f010372a:	74 ef                	je     f010371b <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f010372c:	0f b6 c0             	movzbl %al,%eax
f010372f:	0f b6 12             	movzbl (%edx),%edx
f0103732:	29 d0                	sub    %edx,%eax
}
f0103734:	5d                   	pop    %ebp
f0103735:	c3                   	ret    

f0103736 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103736:	55                   	push   %ebp
f0103737:	89 e5                	mov    %esp,%ebp
f0103739:	53                   	push   %ebx
f010373a:	8b 45 08             	mov    0x8(%ebp),%eax
f010373d:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103740:	89 c3                	mov    %eax,%ebx
f0103742:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103745:	eb 06                	jmp    f010374d <strncmp+0x17>
		n--, p++, q++;
f0103747:	83 c0 01             	add    $0x1,%eax
f010374a:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f010374d:	39 d8                	cmp    %ebx,%eax
f010374f:	74 16                	je     f0103767 <strncmp+0x31>
f0103751:	0f b6 08             	movzbl (%eax),%ecx
f0103754:	84 c9                	test   %cl,%cl
f0103756:	74 04                	je     f010375c <strncmp+0x26>
f0103758:	3a 0a                	cmp    (%edx),%cl
f010375a:	74 eb                	je     f0103747 <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f010375c:	0f b6 00             	movzbl (%eax),%eax
f010375f:	0f b6 12             	movzbl (%edx),%edx
f0103762:	29 d0                	sub    %edx,%eax
}
f0103764:	5b                   	pop    %ebx
f0103765:	5d                   	pop    %ebp
f0103766:	c3                   	ret    
		return 0;
f0103767:	b8 00 00 00 00       	mov    $0x0,%eax
f010376c:	eb f6                	jmp    f0103764 <strncmp+0x2e>

f010376e <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010376e:	55                   	push   %ebp
f010376f:	89 e5                	mov    %esp,%ebp
f0103771:	8b 45 08             	mov    0x8(%ebp),%eax
f0103774:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103778:	0f b6 10             	movzbl (%eax),%edx
f010377b:	84 d2                	test   %dl,%dl
f010377d:	74 09                	je     f0103788 <strchr+0x1a>
		if (*s == c)
f010377f:	38 ca                	cmp    %cl,%dl
f0103781:	74 0a                	je     f010378d <strchr+0x1f>
	for (; *s; s++)
f0103783:	83 c0 01             	add    $0x1,%eax
f0103786:	eb f0                	jmp    f0103778 <strchr+0xa>
			return (char *) s;
	return 0;
f0103788:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010378d:	5d                   	pop    %ebp
f010378e:	c3                   	ret    

f010378f <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010378f:	55                   	push   %ebp
f0103790:	89 e5                	mov    %esp,%ebp
f0103792:	8b 45 08             	mov    0x8(%ebp),%eax
f0103795:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103799:	eb 03                	jmp    f010379e <strfind+0xf>
f010379b:	83 c0 01             	add    $0x1,%eax
f010379e:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01037a1:	38 ca                	cmp    %cl,%dl
f01037a3:	74 04                	je     f01037a9 <strfind+0x1a>
f01037a5:	84 d2                	test   %dl,%dl
f01037a7:	75 f2                	jne    f010379b <strfind+0xc>
			break;
	return (char *) s;
}
f01037a9:	5d                   	pop    %ebp
f01037aa:	c3                   	ret    

f01037ab <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01037ab:	55                   	push   %ebp
f01037ac:	89 e5                	mov    %esp,%ebp
f01037ae:	57                   	push   %edi
f01037af:	56                   	push   %esi
f01037b0:	53                   	push   %ebx
f01037b1:	8b 7d 08             	mov    0x8(%ebp),%edi
f01037b4:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01037b7:	85 c9                	test   %ecx,%ecx
f01037b9:	74 13                	je     f01037ce <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01037bb:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01037c1:	75 05                	jne    f01037c8 <memset+0x1d>
f01037c3:	f6 c1 03             	test   $0x3,%cl
f01037c6:	74 0d                	je     f01037d5 <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01037c8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01037cb:	fc                   	cld    
f01037cc:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01037ce:	89 f8                	mov    %edi,%eax
f01037d0:	5b                   	pop    %ebx
f01037d1:	5e                   	pop    %esi
f01037d2:	5f                   	pop    %edi
f01037d3:	5d                   	pop    %ebp
f01037d4:	c3                   	ret    
		c &= 0xFF;
f01037d5:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01037d9:	89 d3                	mov    %edx,%ebx
f01037db:	c1 e3 08             	shl    $0x8,%ebx
f01037de:	89 d0                	mov    %edx,%eax
f01037e0:	c1 e0 18             	shl    $0x18,%eax
f01037e3:	89 d6                	mov    %edx,%esi
f01037e5:	c1 e6 10             	shl    $0x10,%esi
f01037e8:	09 f0                	or     %esi,%eax
f01037ea:	09 c2                	or     %eax,%edx
f01037ec:	09 da                	or     %ebx,%edx
			:: "D" (v), "a" (c), "c" (n/4)
f01037ee:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f01037f1:	89 d0                	mov    %edx,%eax
f01037f3:	fc                   	cld    
f01037f4:	f3 ab                	rep stos %eax,%es:(%edi)
f01037f6:	eb d6                	jmp    f01037ce <memset+0x23>

f01037f8 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01037f8:	55                   	push   %ebp
f01037f9:	89 e5                	mov    %esp,%ebp
f01037fb:	57                   	push   %edi
f01037fc:	56                   	push   %esi
f01037fd:	8b 45 08             	mov    0x8(%ebp),%eax
f0103800:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103803:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103806:	39 c6                	cmp    %eax,%esi
f0103808:	73 35                	jae    f010383f <memmove+0x47>
f010380a:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010380d:	39 c2                	cmp    %eax,%edx
f010380f:	76 2e                	jbe    f010383f <memmove+0x47>
		s += n;
		d += n;
f0103811:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103814:	89 d6                	mov    %edx,%esi
f0103816:	09 fe                	or     %edi,%esi
f0103818:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010381e:	74 0c                	je     f010382c <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0103820:	83 ef 01             	sub    $0x1,%edi
f0103823:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f0103826:	fd                   	std    
f0103827:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103829:	fc                   	cld    
f010382a:	eb 21                	jmp    f010384d <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010382c:	f6 c1 03             	test   $0x3,%cl
f010382f:	75 ef                	jne    f0103820 <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0103831:	83 ef 04             	sub    $0x4,%edi
f0103834:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103837:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f010383a:	fd                   	std    
f010383b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010383d:	eb ea                	jmp    f0103829 <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010383f:	89 f2                	mov    %esi,%edx
f0103841:	09 c2                	or     %eax,%edx
f0103843:	f6 c2 03             	test   $0x3,%dl
f0103846:	74 09                	je     f0103851 <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103848:	89 c7                	mov    %eax,%edi
f010384a:	fc                   	cld    
f010384b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f010384d:	5e                   	pop    %esi
f010384e:	5f                   	pop    %edi
f010384f:	5d                   	pop    %ebp
f0103850:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103851:	f6 c1 03             	test   $0x3,%cl
f0103854:	75 f2                	jne    f0103848 <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0103856:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f0103859:	89 c7                	mov    %eax,%edi
f010385b:	fc                   	cld    
f010385c:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010385e:	eb ed                	jmp    f010384d <memmove+0x55>

f0103860 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103860:	55                   	push   %ebp
f0103861:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0103863:	ff 75 10             	pushl  0x10(%ebp)
f0103866:	ff 75 0c             	pushl  0xc(%ebp)
f0103869:	ff 75 08             	pushl  0x8(%ebp)
f010386c:	e8 87 ff ff ff       	call   f01037f8 <memmove>
}
f0103871:	c9                   	leave  
f0103872:	c3                   	ret    

f0103873 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103873:	55                   	push   %ebp
f0103874:	89 e5                	mov    %esp,%ebp
f0103876:	56                   	push   %esi
f0103877:	53                   	push   %ebx
f0103878:	8b 45 08             	mov    0x8(%ebp),%eax
f010387b:	8b 55 0c             	mov    0xc(%ebp),%edx
f010387e:	89 c6                	mov    %eax,%esi
f0103880:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103883:	39 f0                	cmp    %esi,%eax
f0103885:	74 1c                	je     f01038a3 <memcmp+0x30>
		if (*s1 != *s2)
f0103887:	0f b6 08             	movzbl (%eax),%ecx
f010388a:	0f b6 1a             	movzbl (%edx),%ebx
f010388d:	38 d9                	cmp    %bl,%cl
f010388f:	75 08                	jne    f0103899 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f0103891:	83 c0 01             	add    $0x1,%eax
f0103894:	83 c2 01             	add    $0x1,%edx
f0103897:	eb ea                	jmp    f0103883 <memcmp+0x10>
			return (int) *s1 - (int) *s2;
f0103899:	0f b6 c1             	movzbl %cl,%eax
f010389c:	0f b6 db             	movzbl %bl,%ebx
f010389f:	29 d8                	sub    %ebx,%eax
f01038a1:	eb 05                	jmp    f01038a8 <memcmp+0x35>
	}

	return 0;
f01038a3:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01038a8:	5b                   	pop    %ebx
f01038a9:	5e                   	pop    %esi
f01038aa:	5d                   	pop    %ebp
f01038ab:	c3                   	ret    

f01038ac <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01038ac:	55                   	push   %ebp
f01038ad:	89 e5                	mov    %esp,%ebp
f01038af:	8b 45 08             	mov    0x8(%ebp),%eax
f01038b2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f01038b5:	89 c2                	mov    %eax,%edx
f01038b7:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01038ba:	39 d0                	cmp    %edx,%eax
f01038bc:	73 09                	jae    f01038c7 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f01038be:	38 08                	cmp    %cl,(%eax)
f01038c0:	74 05                	je     f01038c7 <memfind+0x1b>
	for (; s < ends; s++)
f01038c2:	83 c0 01             	add    $0x1,%eax
f01038c5:	eb f3                	jmp    f01038ba <memfind+0xe>
			break;
	return (void *) s;
}
f01038c7:	5d                   	pop    %ebp
f01038c8:	c3                   	ret    

f01038c9 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01038c9:	55                   	push   %ebp
f01038ca:	89 e5                	mov    %esp,%ebp
f01038cc:	57                   	push   %edi
f01038cd:	56                   	push   %esi
f01038ce:	53                   	push   %ebx
f01038cf:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01038d2:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01038d5:	eb 03                	jmp    f01038da <strtol+0x11>
		s++;
f01038d7:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f01038da:	0f b6 01             	movzbl (%ecx),%eax
f01038dd:	3c 20                	cmp    $0x20,%al
f01038df:	74 f6                	je     f01038d7 <strtol+0xe>
f01038e1:	3c 09                	cmp    $0x9,%al
f01038e3:	74 f2                	je     f01038d7 <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f01038e5:	3c 2b                	cmp    $0x2b,%al
f01038e7:	74 2e                	je     f0103917 <strtol+0x4e>
	int neg = 0;
f01038e9:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f01038ee:	3c 2d                	cmp    $0x2d,%al
f01038f0:	74 2f                	je     f0103921 <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01038f2:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01038f8:	75 05                	jne    f01038ff <strtol+0x36>
f01038fa:	80 39 30             	cmpb   $0x30,(%ecx)
f01038fd:	74 2c                	je     f010392b <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01038ff:	85 db                	test   %ebx,%ebx
f0103901:	75 0a                	jne    f010390d <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103903:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
f0103908:	80 39 30             	cmpb   $0x30,(%ecx)
f010390b:	74 28                	je     f0103935 <strtol+0x6c>
		base = 10;
f010390d:	b8 00 00 00 00       	mov    $0x0,%eax
f0103912:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0103915:	eb 50                	jmp    f0103967 <strtol+0x9e>
		s++;
f0103917:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f010391a:	bf 00 00 00 00       	mov    $0x0,%edi
f010391f:	eb d1                	jmp    f01038f2 <strtol+0x29>
		s++, neg = 1;
f0103921:	83 c1 01             	add    $0x1,%ecx
f0103924:	bf 01 00 00 00       	mov    $0x1,%edi
f0103929:	eb c7                	jmp    f01038f2 <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010392b:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f010392f:	74 0e                	je     f010393f <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f0103931:	85 db                	test   %ebx,%ebx
f0103933:	75 d8                	jne    f010390d <strtol+0x44>
		s++, base = 8;
f0103935:	83 c1 01             	add    $0x1,%ecx
f0103938:	bb 08 00 00 00       	mov    $0x8,%ebx
f010393d:	eb ce                	jmp    f010390d <strtol+0x44>
		s += 2, base = 16;
f010393f:	83 c1 02             	add    $0x2,%ecx
f0103942:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103947:	eb c4                	jmp    f010390d <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f0103949:	8d 72 9f             	lea    -0x61(%edx),%esi
f010394c:	89 f3                	mov    %esi,%ebx
f010394e:	80 fb 19             	cmp    $0x19,%bl
f0103951:	77 29                	ja     f010397c <strtol+0xb3>
			dig = *s - 'a' + 10;
f0103953:	0f be d2             	movsbl %dl,%edx
f0103956:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0103959:	3b 55 10             	cmp    0x10(%ebp),%edx
f010395c:	7d 30                	jge    f010398e <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f010395e:	83 c1 01             	add    $0x1,%ecx
f0103961:	0f af 45 10          	imul   0x10(%ebp),%eax
f0103965:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f0103967:	0f b6 11             	movzbl (%ecx),%edx
f010396a:	8d 72 d0             	lea    -0x30(%edx),%esi
f010396d:	89 f3                	mov    %esi,%ebx
f010396f:	80 fb 09             	cmp    $0x9,%bl
f0103972:	77 d5                	ja     f0103949 <strtol+0x80>
			dig = *s - '0';
f0103974:	0f be d2             	movsbl %dl,%edx
f0103977:	83 ea 30             	sub    $0x30,%edx
f010397a:	eb dd                	jmp    f0103959 <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
f010397c:	8d 72 bf             	lea    -0x41(%edx),%esi
f010397f:	89 f3                	mov    %esi,%ebx
f0103981:	80 fb 19             	cmp    $0x19,%bl
f0103984:	77 08                	ja     f010398e <strtol+0xc5>
			dig = *s - 'A' + 10;
f0103986:	0f be d2             	movsbl %dl,%edx
f0103989:	83 ea 37             	sub    $0x37,%edx
f010398c:	eb cb                	jmp    f0103959 <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
f010398e:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103992:	74 05                	je     f0103999 <strtol+0xd0>
		*endptr = (char *) s;
f0103994:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103997:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f0103999:	89 c2                	mov    %eax,%edx
f010399b:	f7 da                	neg    %edx
f010399d:	85 ff                	test   %edi,%edi
f010399f:	0f 45 c2             	cmovne %edx,%eax
}
f01039a2:	5b                   	pop    %ebx
f01039a3:	5e                   	pop    %esi
f01039a4:	5f                   	pop    %edi
f01039a5:	5d                   	pop    %ebp
f01039a6:	c3                   	ret    
f01039a7:	66 90                	xchg   %ax,%ax
f01039a9:	66 90                	xchg   %ax,%ax
f01039ab:	66 90                	xchg   %ax,%ax
f01039ad:	66 90                	xchg   %ax,%ax
f01039af:	90                   	nop

f01039b0 <__udivdi3>:
f01039b0:	55                   	push   %ebp
f01039b1:	57                   	push   %edi
f01039b2:	56                   	push   %esi
f01039b3:	53                   	push   %ebx
f01039b4:	83 ec 1c             	sub    $0x1c,%esp
f01039b7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01039bb:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f01039bf:	8b 74 24 34          	mov    0x34(%esp),%esi
f01039c3:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f01039c7:	85 d2                	test   %edx,%edx
f01039c9:	75 35                	jne    f0103a00 <__udivdi3+0x50>
f01039cb:	39 f3                	cmp    %esi,%ebx
f01039cd:	0f 87 bd 00 00 00    	ja     f0103a90 <__udivdi3+0xe0>
f01039d3:	85 db                	test   %ebx,%ebx
f01039d5:	89 d9                	mov    %ebx,%ecx
f01039d7:	75 0b                	jne    f01039e4 <__udivdi3+0x34>
f01039d9:	b8 01 00 00 00       	mov    $0x1,%eax
f01039de:	31 d2                	xor    %edx,%edx
f01039e0:	f7 f3                	div    %ebx
f01039e2:	89 c1                	mov    %eax,%ecx
f01039e4:	31 d2                	xor    %edx,%edx
f01039e6:	89 f0                	mov    %esi,%eax
f01039e8:	f7 f1                	div    %ecx
f01039ea:	89 c6                	mov    %eax,%esi
f01039ec:	89 e8                	mov    %ebp,%eax
f01039ee:	89 f7                	mov    %esi,%edi
f01039f0:	f7 f1                	div    %ecx
f01039f2:	89 fa                	mov    %edi,%edx
f01039f4:	83 c4 1c             	add    $0x1c,%esp
f01039f7:	5b                   	pop    %ebx
f01039f8:	5e                   	pop    %esi
f01039f9:	5f                   	pop    %edi
f01039fa:	5d                   	pop    %ebp
f01039fb:	c3                   	ret    
f01039fc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103a00:	39 f2                	cmp    %esi,%edx
f0103a02:	77 7c                	ja     f0103a80 <__udivdi3+0xd0>
f0103a04:	0f bd fa             	bsr    %edx,%edi
f0103a07:	83 f7 1f             	xor    $0x1f,%edi
f0103a0a:	0f 84 98 00 00 00    	je     f0103aa8 <__udivdi3+0xf8>
f0103a10:	89 f9                	mov    %edi,%ecx
f0103a12:	b8 20 00 00 00       	mov    $0x20,%eax
f0103a17:	29 f8                	sub    %edi,%eax
f0103a19:	d3 e2                	shl    %cl,%edx
f0103a1b:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103a1f:	89 c1                	mov    %eax,%ecx
f0103a21:	89 da                	mov    %ebx,%edx
f0103a23:	d3 ea                	shr    %cl,%edx
f0103a25:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0103a29:	09 d1                	or     %edx,%ecx
f0103a2b:	89 f2                	mov    %esi,%edx
f0103a2d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103a31:	89 f9                	mov    %edi,%ecx
f0103a33:	d3 e3                	shl    %cl,%ebx
f0103a35:	89 c1                	mov    %eax,%ecx
f0103a37:	d3 ea                	shr    %cl,%edx
f0103a39:	89 f9                	mov    %edi,%ecx
f0103a3b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0103a3f:	d3 e6                	shl    %cl,%esi
f0103a41:	89 eb                	mov    %ebp,%ebx
f0103a43:	89 c1                	mov    %eax,%ecx
f0103a45:	d3 eb                	shr    %cl,%ebx
f0103a47:	09 de                	or     %ebx,%esi
f0103a49:	89 f0                	mov    %esi,%eax
f0103a4b:	f7 74 24 08          	divl   0x8(%esp)
f0103a4f:	89 d6                	mov    %edx,%esi
f0103a51:	89 c3                	mov    %eax,%ebx
f0103a53:	f7 64 24 0c          	mull   0xc(%esp)
f0103a57:	39 d6                	cmp    %edx,%esi
f0103a59:	72 0c                	jb     f0103a67 <__udivdi3+0xb7>
f0103a5b:	89 f9                	mov    %edi,%ecx
f0103a5d:	d3 e5                	shl    %cl,%ebp
f0103a5f:	39 c5                	cmp    %eax,%ebp
f0103a61:	73 5d                	jae    f0103ac0 <__udivdi3+0x110>
f0103a63:	39 d6                	cmp    %edx,%esi
f0103a65:	75 59                	jne    f0103ac0 <__udivdi3+0x110>
f0103a67:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0103a6a:	31 ff                	xor    %edi,%edi
f0103a6c:	89 fa                	mov    %edi,%edx
f0103a6e:	83 c4 1c             	add    $0x1c,%esp
f0103a71:	5b                   	pop    %ebx
f0103a72:	5e                   	pop    %esi
f0103a73:	5f                   	pop    %edi
f0103a74:	5d                   	pop    %ebp
f0103a75:	c3                   	ret    
f0103a76:	8d 76 00             	lea    0x0(%esi),%esi
f0103a79:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0103a80:	31 ff                	xor    %edi,%edi
f0103a82:	31 c0                	xor    %eax,%eax
f0103a84:	89 fa                	mov    %edi,%edx
f0103a86:	83 c4 1c             	add    $0x1c,%esp
f0103a89:	5b                   	pop    %ebx
f0103a8a:	5e                   	pop    %esi
f0103a8b:	5f                   	pop    %edi
f0103a8c:	5d                   	pop    %ebp
f0103a8d:	c3                   	ret    
f0103a8e:	66 90                	xchg   %ax,%ax
f0103a90:	31 ff                	xor    %edi,%edi
f0103a92:	89 e8                	mov    %ebp,%eax
f0103a94:	89 f2                	mov    %esi,%edx
f0103a96:	f7 f3                	div    %ebx
f0103a98:	89 fa                	mov    %edi,%edx
f0103a9a:	83 c4 1c             	add    $0x1c,%esp
f0103a9d:	5b                   	pop    %ebx
f0103a9e:	5e                   	pop    %esi
f0103a9f:	5f                   	pop    %edi
f0103aa0:	5d                   	pop    %ebp
f0103aa1:	c3                   	ret    
f0103aa2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103aa8:	39 f2                	cmp    %esi,%edx
f0103aaa:	72 06                	jb     f0103ab2 <__udivdi3+0x102>
f0103aac:	31 c0                	xor    %eax,%eax
f0103aae:	39 eb                	cmp    %ebp,%ebx
f0103ab0:	77 d2                	ja     f0103a84 <__udivdi3+0xd4>
f0103ab2:	b8 01 00 00 00       	mov    $0x1,%eax
f0103ab7:	eb cb                	jmp    f0103a84 <__udivdi3+0xd4>
f0103ab9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103ac0:	89 d8                	mov    %ebx,%eax
f0103ac2:	31 ff                	xor    %edi,%edi
f0103ac4:	eb be                	jmp    f0103a84 <__udivdi3+0xd4>
f0103ac6:	66 90                	xchg   %ax,%ax
f0103ac8:	66 90                	xchg   %ax,%ax
f0103aca:	66 90                	xchg   %ax,%ax
f0103acc:	66 90                	xchg   %ax,%ax
f0103ace:	66 90                	xchg   %ax,%ax

f0103ad0 <__umoddi3>:
f0103ad0:	55                   	push   %ebp
f0103ad1:	57                   	push   %edi
f0103ad2:	56                   	push   %esi
f0103ad3:	53                   	push   %ebx
f0103ad4:	83 ec 1c             	sub    $0x1c,%esp
f0103ad7:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
f0103adb:	8b 74 24 30          	mov    0x30(%esp),%esi
f0103adf:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0103ae3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103ae7:	85 ed                	test   %ebp,%ebp
f0103ae9:	89 f0                	mov    %esi,%eax
f0103aeb:	89 da                	mov    %ebx,%edx
f0103aed:	75 19                	jne    f0103b08 <__umoddi3+0x38>
f0103aef:	39 df                	cmp    %ebx,%edi
f0103af1:	0f 86 b1 00 00 00    	jbe    f0103ba8 <__umoddi3+0xd8>
f0103af7:	f7 f7                	div    %edi
f0103af9:	89 d0                	mov    %edx,%eax
f0103afb:	31 d2                	xor    %edx,%edx
f0103afd:	83 c4 1c             	add    $0x1c,%esp
f0103b00:	5b                   	pop    %ebx
f0103b01:	5e                   	pop    %esi
f0103b02:	5f                   	pop    %edi
f0103b03:	5d                   	pop    %ebp
f0103b04:	c3                   	ret    
f0103b05:	8d 76 00             	lea    0x0(%esi),%esi
f0103b08:	39 dd                	cmp    %ebx,%ebp
f0103b0a:	77 f1                	ja     f0103afd <__umoddi3+0x2d>
f0103b0c:	0f bd cd             	bsr    %ebp,%ecx
f0103b0f:	83 f1 1f             	xor    $0x1f,%ecx
f0103b12:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0103b16:	0f 84 b4 00 00 00    	je     f0103bd0 <__umoddi3+0x100>
f0103b1c:	b8 20 00 00 00       	mov    $0x20,%eax
f0103b21:	89 c2                	mov    %eax,%edx
f0103b23:	8b 44 24 04          	mov    0x4(%esp),%eax
f0103b27:	29 c2                	sub    %eax,%edx
f0103b29:	89 c1                	mov    %eax,%ecx
f0103b2b:	89 f8                	mov    %edi,%eax
f0103b2d:	d3 e5                	shl    %cl,%ebp
f0103b2f:	89 d1                	mov    %edx,%ecx
f0103b31:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103b35:	d3 e8                	shr    %cl,%eax
f0103b37:	09 c5                	or     %eax,%ebp
f0103b39:	8b 44 24 04          	mov    0x4(%esp),%eax
f0103b3d:	89 c1                	mov    %eax,%ecx
f0103b3f:	d3 e7                	shl    %cl,%edi
f0103b41:	89 d1                	mov    %edx,%ecx
f0103b43:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0103b47:	89 df                	mov    %ebx,%edi
f0103b49:	d3 ef                	shr    %cl,%edi
f0103b4b:	89 c1                	mov    %eax,%ecx
f0103b4d:	89 f0                	mov    %esi,%eax
f0103b4f:	d3 e3                	shl    %cl,%ebx
f0103b51:	89 d1                	mov    %edx,%ecx
f0103b53:	89 fa                	mov    %edi,%edx
f0103b55:	d3 e8                	shr    %cl,%eax
f0103b57:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103b5c:	09 d8                	or     %ebx,%eax
f0103b5e:	f7 f5                	div    %ebp
f0103b60:	d3 e6                	shl    %cl,%esi
f0103b62:	89 d1                	mov    %edx,%ecx
f0103b64:	f7 64 24 08          	mull   0x8(%esp)
f0103b68:	39 d1                	cmp    %edx,%ecx
f0103b6a:	89 c3                	mov    %eax,%ebx
f0103b6c:	89 d7                	mov    %edx,%edi
f0103b6e:	72 06                	jb     f0103b76 <__umoddi3+0xa6>
f0103b70:	75 0e                	jne    f0103b80 <__umoddi3+0xb0>
f0103b72:	39 c6                	cmp    %eax,%esi
f0103b74:	73 0a                	jae    f0103b80 <__umoddi3+0xb0>
f0103b76:	2b 44 24 08          	sub    0x8(%esp),%eax
f0103b7a:	19 ea                	sbb    %ebp,%edx
f0103b7c:	89 d7                	mov    %edx,%edi
f0103b7e:	89 c3                	mov    %eax,%ebx
f0103b80:	89 ca                	mov    %ecx,%edx
f0103b82:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f0103b87:	29 de                	sub    %ebx,%esi
f0103b89:	19 fa                	sbb    %edi,%edx
f0103b8b:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f0103b8f:	89 d0                	mov    %edx,%eax
f0103b91:	d3 e0                	shl    %cl,%eax
f0103b93:	89 d9                	mov    %ebx,%ecx
f0103b95:	d3 ee                	shr    %cl,%esi
f0103b97:	d3 ea                	shr    %cl,%edx
f0103b99:	09 f0                	or     %esi,%eax
f0103b9b:	83 c4 1c             	add    $0x1c,%esp
f0103b9e:	5b                   	pop    %ebx
f0103b9f:	5e                   	pop    %esi
f0103ba0:	5f                   	pop    %edi
f0103ba1:	5d                   	pop    %ebp
f0103ba2:	c3                   	ret    
f0103ba3:	90                   	nop
f0103ba4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103ba8:	85 ff                	test   %edi,%edi
f0103baa:	89 f9                	mov    %edi,%ecx
f0103bac:	75 0b                	jne    f0103bb9 <__umoddi3+0xe9>
f0103bae:	b8 01 00 00 00       	mov    $0x1,%eax
f0103bb3:	31 d2                	xor    %edx,%edx
f0103bb5:	f7 f7                	div    %edi
f0103bb7:	89 c1                	mov    %eax,%ecx
f0103bb9:	89 d8                	mov    %ebx,%eax
f0103bbb:	31 d2                	xor    %edx,%edx
f0103bbd:	f7 f1                	div    %ecx
f0103bbf:	89 f0                	mov    %esi,%eax
f0103bc1:	f7 f1                	div    %ecx
f0103bc3:	e9 31 ff ff ff       	jmp    f0103af9 <__umoddi3+0x29>
f0103bc8:	90                   	nop
f0103bc9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103bd0:	39 dd                	cmp    %ebx,%ebp
f0103bd2:	72 08                	jb     f0103bdc <__umoddi3+0x10c>
f0103bd4:	39 f7                	cmp    %esi,%edi
f0103bd6:	0f 87 21 ff ff ff    	ja     f0103afd <__umoddi3+0x2d>
f0103bdc:	89 da                	mov    %ebx,%edx
f0103bde:	89 f0                	mov    %esi,%eax
f0103be0:	29 f8                	sub    %edi,%eax
f0103be2:	19 ea                	sbb    %ebp,%edx
f0103be4:	e9 14 ff ff ff       	jmp    f0103afd <__umoddi3+0x2d>
