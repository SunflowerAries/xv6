
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
f0100047:	2d d0 2e 12 f0       	sub    $0xf0122ed0,%eax
f010004c:	50                   	push   %eax
f010004d:	6a 00                	push   $0x0
f010004f:	68 d0 2e 12 f0       	push   $0xf0122ed0
f0100054:	e8 5f 37 00 00       	call   f01037b8 <memset>

	cons_init();
f0100059:	e8 b9 05 00 00       	call   f0100617 <cons_init>

	cprintf("Hello, world.\n");
f010005e:	c7 04 24 00 3c 10 f0 	movl   $0xf0103c00,(%esp)
f0100065:	e8 1f 07 00 00       	call   f0100789 <cprintf>
	boot_alloc_init();
f010006a:	e8 6b 1f 00 00       	call   f0101fda <boot_alloc_init>
	vm_init();
f010006f:	e8 ec 16 00 00       	call   f0101760 <vm_init>
	seg_init();
f0100074:	e8 12 13 00 00       	call   f010138b <seg_init>
	trap_init();
f0100079:	e8 1f 07 00 00       	call   f010079d <trap_init>
	proc_init();
f010007e:	e8 07 2a 00 00       	call   f0102a8a <proc_init>
	mp_init();
f0100083:	e8 4f 22 00 00       	call   f01022d7 <mp_init>
	lapic_init();
f0100088:	e8 11 25 00 00       	call   f010259e <lapic_init>
	pic_init();
f010008d:	e8 3f 29 00 00       	call   f01029d1 <pic_init>
	void *code;
	struct CpuInfo *c;

	// Write entry code to unused memory at MPENTRY_PADDR
	code = P2V(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);
f0100092:	83 c4 0c             	add    $0xc,%esp
f0100095:	b8 7a 22 10 f0       	mov    $0xf010227a,%eax
f010009a:	2d 00 22 10 f0       	sub    $0xf0102200,%eax
f010009f:	50                   	push   %eax
f01000a0:	68 00 22 10 f0       	push   $0xf0102200
f01000a5:	68 00 70 00 f0       	push   $0xf0007000
f01000aa:	e8 56 37 00 00       	call   f0103805 <memmove>
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
f01000d2:	e8 ad 24 00 00       	call   f0102584 <cpunum>
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
f010010f:	e8 cd 25 00 00       	call   f01026e1 <lapic_startap>
f0100114:	83 c4 10             	add    $0x10,%esp
		// Wait for the CPU to finish some basic setup in mp_main()
		while(c->cpu_status != CPU_STARTED)
f0100117:	8b 43 04             	mov    0x4(%ebx),%eax
f010011a:	83 f8 01             	cmp    $0x1,%eax
f010011d:	75 f8                	jne    f0100117 <i386_init+0xdc>
f010011f:	eb 98                	jmp    f01000b9 <i386_init+0x7e>
	alloc_init();
f0100121:	e8 a2 20 00 00       	call   f01021c8 <alloc_init>
	cprintf("VM: Init success.\n");
f0100126:	83 ec 0c             	sub    $0xc,%esp
f0100129:	68 0f 3c 10 f0       	push   $0xf0103c0f
f010012e:	e8 56 06 00 00       	call   f0100789 <cprintf>
	check_free_list();
f0100133:	e8 13 1e 00 00       	call   f0101f4b <check_free_list>
	cprintf("Finish.\n");
f0100138:	c7 04 24 22 3c 10 f0 	movl   $0xf0103c22,(%esp)
f010013f:	e8 45 06 00 00       	call   f0100789 <cprintf>
	user_init();
f0100144:	e8 5b 29 00 00       	call   f0102aa4 <user_init>
	ucode_run();
f0100149:	e8 46 2c 00 00       	call   f0102d94 <ucode_run>
f010014e:	83 c4 10             	add    $0x10,%esp
f0100151:	eb fe                	jmp    f0100151 <i386_init+0x116>

f0100153 <mp_main>:
}

// Setup code for APs
void
mp_main(void)
{
f0100153:	55                   	push   %ebp
f0100154:	89 e5                	mov    %esp,%ebp
f0100156:	83 ec 08             	sub    $0x8,%esp
	// TODO: Your code here.
	// You need to initialize something.
	kvm_switch();
f0100159:	e8 37 15 00 00       	call   f0101695 <kvm_switch>
	seg_init();
f010015e:	e8 28 12 00 00       	call   f010138b <seg_init>
	lapic_init();
f0100163:	e8 36 24 00 00       	call   f010259e <lapic_init>
	cprintf("Starting CPU%d.\n", cpunum());
f0100168:	e8 17 24 00 00       	call   f0102584 <cpunum>
f010016d:	83 ec 08             	sub    $0x8,%esp
f0100170:	50                   	push   %eax
f0100171:	68 2b 3c 10 f0       	push   $0xf0103c2b
f0100176:	e8 0e 06 00 00       	call   f0100789 <cprintf>
	idt_init();
f010017b:	e8 90 06 00 00       	call   f0100810 <idt_init>
	xchg(&thiscpu->cpu_status, CPU_STARTED); // tell boot_aps() we're up
f0100180:	e8 ff 23 00 00       	call   f0102584 <cpunum>
f0100185:	69 d0 b8 00 00 00    	imul   $0xb8,%eax,%edx
f010018b:	83 c2 04             	add    $0x4,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f010018e:	b8 01 00 00 00       	mov    $0x1,%eax
f0100193:	f0 87 82 20 40 12 f0 	lock xchg %eax,-0xfedbfe0(%edx)
f010019a:	83 c4 10             	add    $0x10,%esp
f010019d:	eb fe                	jmp    f010019d <mp_main+0x4a>

f010019f <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f010019f:	55                   	push   %ebp
f01001a0:	89 e5                	mov    %esp,%ebp
f01001a2:	56                   	push   %esi
f01001a3:	53                   	push   %ebx
f01001a4:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01001a7:	83 3d 44 36 12 f0 00 	cmpl   $0x0,0xf0123644
f01001ae:	74 02                	je     f01001b2 <_panic+0x13>
f01001b0:	eb fe                	jmp    f01001b0 <_panic+0x11>
		goto dead;
	panicstr = fmt;
f01001b2:	89 35 44 36 12 f0    	mov    %esi,0xf0123644

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01001b8:	fa                   	cli    
f01001b9:	fc                   	cld    

	va_start(ap, fmt);
f01001ba:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01001bd:	83 ec 04             	sub    $0x4,%esp
f01001c0:	ff 75 0c             	pushl  0xc(%ebp)
f01001c3:	ff 75 08             	pushl  0x8(%ebp)
f01001c6:	68 3c 3c 10 f0       	push   $0xf0103c3c
f01001cb:	e8 b9 05 00 00       	call   f0100789 <cprintf>
	vcprintf(fmt, ap);
f01001d0:	83 c4 08             	add    $0x8,%esp
f01001d3:	53                   	push   %ebx
f01001d4:	56                   	push   %esi
f01001d5:	e8 89 05 00 00       	call   f0100763 <vcprintf>
	cprintf("\n");
f01001da:	c7 04 24 78 3c 10 f0 	movl   $0xf0103c78,(%esp)
f01001e1:	e8 a3 05 00 00       	call   f0100789 <cprintf>
f01001e6:	83 c4 10             	add    $0x10,%esp
f01001e9:	eb c5                	jmp    f01001b0 <_panic+0x11>

f01001eb <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01001eb:	55                   	push   %ebp
f01001ec:	89 e5                	mov    %esp,%ebp
f01001ee:	53                   	push   %ebx
f01001ef:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01001f2:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01001f5:	ff 75 0c             	pushl  0xc(%ebp)
f01001f8:	ff 75 08             	pushl  0x8(%ebp)
f01001fb:	68 54 3c 10 f0       	push   $0xf0103c54
f0100200:	e8 84 05 00 00       	call   f0100789 <cprintf>
	vcprintf(fmt, ap);
f0100205:	83 c4 08             	add    $0x8,%esp
f0100208:	53                   	push   %ebx
f0100209:	ff 75 10             	pushl  0x10(%ebp)
f010020c:	e8 52 05 00 00       	call   f0100763 <vcprintf>
	cprintf("\n");
f0100211:	c7 04 24 78 3c 10 f0 	movl   $0xf0103c78,(%esp)
f0100218:	e8 6c 05 00 00       	call   f0100789 <cprintf>
	va_end(ap);
}
f010021d:	83 c4 10             	add    $0x10,%esp
f0100220:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100223:	c9                   	leave  
f0100224:	c3                   	ret    

f0100225 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100225:	55                   	push   %ebp
f0100226:	89 e5                	mov    %esp,%ebp
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100228:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010022d:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010022e:	a8 01                	test   $0x1,%al
f0100230:	74 0b                	je     f010023d <serial_proc_data+0x18>
f0100232:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100237:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100238:	0f b6 c0             	movzbl %al,%eax
}
f010023b:	5d                   	pop    %ebp
f010023c:	c3                   	ret    
		return -1;
f010023d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100242:	eb f7                	jmp    f010023b <serial_proc_data+0x16>

f0100244 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100244:	55                   	push   %ebp
f0100245:	89 e5                	mov    %esp,%ebp
f0100247:	53                   	push   %ebx
f0100248:	83 ec 04             	sub    $0x4,%esp
f010024b:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f010024d:	ff d3                	call   *%ebx
f010024f:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100252:	74 2d                	je     f0100281 <cons_intr+0x3d>
		if (c == 0)
f0100254:	85 c0                	test   %eax,%eax
f0100256:	74 f5                	je     f010024d <cons_intr+0x9>
			continue;
		cons.buf[cons.wpos++] = c;
f0100258:	8b 0d 24 32 12 f0    	mov    0xf0123224,%ecx
f010025e:	8d 51 01             	lea    0x1(%ecx),%edx
f0100261:	89 15 24 32 12 f0    	mov    %edx,0xf0123224
f0100267:	88 81 20 30 12 f0    	mov    %al,-0xfedcfe0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f010026d:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100273:	75 d8                	jne    f010024d <cons_intr+0x9>
			cons.wpos = 0;
f0100275:	c7 05 24 32 12 f0 00 	movl   $0x0,0xf0123224
f010027c:	00 00 00 
f010027f:	eb cc                	jmp    f010024d <cons_intr+0x9>
	}
}
f0100281:	83 c4 04             	add    $0x4,%esp
f0100284:	5b                   	pop    %ebx
f0100285:	5d                   	pop    %ebp
f0100286:	c3                   	ret    

f0100287 <kbd_proc_data>:
{
f0100287:	55                   	push   %ebp
f0100288:	89 e5                	mov    %esp,%ebp
f010028a:	53                   	push   %ebx
f010028b:	83 ec 04             	sub    $0x4,%esp
f010028e:	ba 64 00 00 00       	mov    $0x64,%edx
f0100293:	ec                   	in     (%dx),%al
	if ((stat & KBS_DIB) == 0)
f0100294:	a8 01                	test   $0x1,%al
f0100296:	0f 84 fa 00 00 00    	je     f0100396 <kbd_proc_data+0x10f>
	if (stat & KBS_TERR)
f010029c:	a8 20                	test   $0x20,%al
f010029e:	0f 85 f9 00 00 00    	jne    f010039d <kbd_proc_data+0x116>
f01002a4:	ba 60 00 00 00       	mov    $0x60,%edx
f01002a9:	ec                   	in     (%dx),%al
f01002aa:	89 c2                	mov    %eax,%edx
	if (data == 0xE0) {
f01002ac:	3c e0                	cmp    $0xe0,%al
f01002ae:	0f 84 8e 00 00 00    	je     f0100342 <kbd_proc_data+0xbb>
	} else if (data & 0x80) {
f01002b4:	84 c0                	test   %al,%al
f01002b6:	0f 88 99 00 00 00    	js     f0100355 <kbd_proc_data+0xce>
	} else if (shift & E0ESC) {
f01002bc:	8b 0d 00 30 12 f0    	mov    0xf0123000,%ecx
f01002c2:	f6 c1 40             	test   $0x40,%cl
f01002c5:	74 0e                	je     f01002d5 <kbd_proc_data+0x4e>
		data |= 0x80;
f01002c7:	83 c8 80             	or     $0xffffff80,%eax
f01002ca:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f01002cc:	83 e1 bf             	and    $0xffffffbf,%ecx
f01002cf:	89 0d 00 30 12 f0    	mov    %ecx,0xf0123000
	shift |= shiftcode[data];
f01002d5:	0f b6 d2             	movzbl %dl,%edx
f01002d8:	0f b6 82 c0 3d 10 f0 	movzbl -0xfefc240(%edx),%eax
f01002df:	0b 05 00 30 12 f0    	or     0xf0123000,%eax
	shift ^= togglecode[data];
f01002e5:	0f b6 8a c0 3c 10 f0 	movzbl -0xfefc340(%edx),%ecx
f01002ec:	31 c8                	xor    %ecx,%eax
f01002ee:	a3 00 30 12 f0       	mov    %eax,0xf0123000
	c = charcode[shift & (CTL | SHIFT)][data];
f01002f3:	89 c1                	mov    %eax,%ecx
f01002f5:	83 e1 03             	and    $0x3,%ecx
f01002f8:	8b 0c 8d a0 3c 10 f0 	mov    -0xfefc360(,%ecx,4),%ecx
f01002ff:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100303:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100306:	a8 08                	test   $0x8,%al
f0100308:	74 0d                	je     f0100317 <kbd_proc_data+0x90>
		if ('a' <= c && c <= 'z')
f010030a:	89 da                	mov    %ebx,%edx
f010030c:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f010030f:	83 f9 19             	cmp    $0x19,%ecx
f0100312:	77 74                	ja     f0100388 <kbd_proc_data+0x101>
			c += 'A' - 'a';
f0100314:	83 eb 20             	sub    $0x20,%ebx
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100317:	f7 d0                	not    %eax
f0100319:	a8 06                	test   $0x6,%al
f010031b:	75 31                	jne    f010034e <kbd_proc_data+0xc7>
f010031d:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100323:	75 29                	jne    f010034e <kbd_proc_data+0xc7>
		cprintf("Rebooting!\n");
f0100325:	83 ec 0c             	sub    $0xc,%esp
f0100328:	68 6e 3c 10 f0       	push   $0xf0103c6e
f010032d:	e8 57 04 00 00       	call   f0100789 <cprintf>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100332:	b8 03 00 00 00       	mov    $0x3,%eax
f0100337:	ba 92 00 00 00       	mov    $0x92,%edx
f010033c:	ee                   	out    %al,(%dx)
f010033d:	83 c4 10             	add    $0x10,%esp
f0100340:	eb 0c                	jmp    f010034e <kbd_proc_data+0xc7>
		shift |= E0ESC;
f0100342:	83 0d 00 30 12 f0 40 	orl    $0x40,0xf0123000
		return 0;
f0100349:	bb 00 00 00 00       	mov    $0x0,%ebx
}
f010034e:	89 d8                	mov    %ebx,%eax
f0100350:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100353:	c9                   	leave  
f0100354:	c3                   	ret    
		data = (shift & E0ESC ? data : data & 0x7F);
f0100355:	8b 0d 00 30 12 f0    	mov    0xf0123000,%ecx
f010035b:	89 cb                	mov    %ecx,%ebx
f010035d:	83 e3 40             	and    $0x40,%ebx
f0100360:	83 e0 7f             	and    $0x7f,%eax
f0100363:	85 db                	test   %ebx,%ebx
f0100365:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100368:	0f b6 d2             	movzbl %dl,%edx
f010036b:	0f b6 82 c0 3d 10 f0 	movzbl -0xfefc240(%edx),%eax
f0100372:	83 c8 40             	or     $0x40,%eax
f0100375:	0f b6 c0             	movzbl %al,%eax
f0100378:	f7 d0                	not    %eax
f010037a:	21 c8                	and    %ecx,%eax
f010037c:	a3 00 30 12 f0       	mov    %eax,0xf0123000
		return 0;
f0100381:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100386:	eb c6                	jmp    f010034e <kbd_proc_data+0xc7>
		else if ('A' <= c && c <= 'Z')
f0100388:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f010038b:	8d 4b 20             	lea    0x20(%ebx),%ecx
f010038e:	83 fa 1a             	cmp    $0x1a,%edx
f0100391:	0f 42 d9             	cmovb  %ecx,%ebx
f0100394:	eb 81                	jmp    f0100317 <kbd_proc_data+0x90>
		return -1;
f0100396:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
f010039b:	eb b1                	jmp    f010034e <kbd_proc_data+0xc7>
		return -1;
f010039d:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
f01003a2:	eb aa                	jmp    f010034e <kbd_proc_data+0xc7>

f01003a4 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01003a4:	55                   	push   %ebp
f01003a5:	89 e5                	mov    %esp,%ebp
f01003a7:	57                   	push   %edi
f01003a8:	56                   	push   %esi
f01003a9:	53                   	push   %ebx
f01003aa:	83 ec 1c             	sub    $0x1c,%esp
f01003ad:	89 c7                	mov    %eax,%edi
	for (i = 0;
f01003af:	bb 00 00 00 00       	mov    $0x0,%ebx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003b4:	be fd 03 00 00       	mov    $0x3fd,%esi
f01003b9:	b9 84 00 00 00       	mov    $0x84,%ecx
f01003be:	eb 09                	jmp    f01003c9 <cons_putc+0x25>
f01003c0:	89 ca                	mov    %ecx,%edx
f01003c2:	ec                   	in     (%dx),%al
f01003c3:	ec                   	in     (%dx),%al
f01003c4:	ec                   	in     (%dx),%al
f01003c5:	ec                   	in     (%dx),%al
	     i++)
f01003c6:	83 c3 01             	add    $0x1,%ebx
f01003c9:	89 f2                	mov    %esi,%edx
f01003cb:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01003cc:	a8 20                	test   $0x20,%al
f01003ce:	75 08                	jne    f01003d8 <cons_putc+0x34>
f01003d0:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01003d6:	7e e8                	jle    f01003c0 <cons_putc+0x1c>
	outb(COM1 + COM_TX, c);
f01003d8:	89 f8                	mov    %edi,%eax
f01003da:	88 45 e7             	mov    %al,-0x19(%ebp)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003dd:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01003e2:	ee                   	out    %al,(%dx)
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01003e3:	bb 00 00 00 00       	mov    $0x0,%ebx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003e8:	be 79 03 00 00       	mov    $0x379,%esi
f01003ed:	b9 84 00 00 00       	mov    $0x84,%ecx
f01003f2:	eb 09                	jmp    f01003fd <cons_putc+0x59>
f01003f4:	89 ca                	mov    %ecx,%edx
f01003f6:	ec                   	in     (%dx),%al
f01003f7:	ec                   	in     (%dx),%al
f01003f8:	ec                   	in     (%dx),%al
f01003f9:	ec                   	in     (%dx),%al
f01003fa:	83 c3 01             	add    $0x1,%ebx
f01003fd:	89 f2                	mov    %esi,%edx
f01003ff:	ec                   	in     (%dx),%al
f0100400:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100406:	7f 04                	jg     f010040c <cons_putc+0x68>
f0100408:	84 c0                	test   %al,%al
f010040a:	79 e8                	jns    f01003f4 <cons_putc+0x50>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010040c:	ba 78 03 00 00       	mov    $0x378,%edx
f0100411:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100415:	ee                   	out    %al,(%dx)
f0100416:	ba 7a 03 00 00       	mov    $0x37a,%edx
f010041b:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100420:	ee                   	out    %al,(%dx)
f0100421:	b8 08 00 00 00       	mov    $0x8,%eax
f0100426:	ee                   	out    %al,(%dx)
	if (!(c & ~0xFF))
f0100427:	89 fa                	mov    %edi,%edx
f0100429:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f010042f:	89 f8                	mov    %edi,%eax
f0100431:	80 cc 07             	or     $0x7,%ah
f0100434:	85 d2                	test   %edx,%edx
f0100436:	0f 44 f8             	cmove  %eax,%edi
	switch (c & 0xff) {
f0100439:	89 f8                	mov    %edi,%eax
f010043b:	0f b6 c0             	movzbl %al,%eax
f010043e:	83 f8 09             	cmp    $0x9,%eax
f0100441:	0f 84 b6 00 00 00    	je     f01004fd <cons_putc+0x159>
f0100447:	83 f8 09             	cmp    $0x9,%eax
f010044a:	7e 73                	jle    f01004bf <cons_putc+0x11b>
f010044c:	83 f8 0a             	cmp    $0xa,%eax
f010044f:	0f 84 9b 00 00 00    	je     f01004f0 <cons_putc+0x14c>
f0100455:	83 f8 0d             	cmp    $0xd,%eax
f0100458:	0f 85 d6 00 00 00    	jne    f0100534 <cons_putc+0x190>
		crt_pos -= (crt_pos % CRT_COLS);
f010045e:	0f b7 05 28 32 12 f0 	movzwl 0xf0123228,%eax
f0100465:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f010046b:	c1 e8 16             	shr    $0x16,%eax
f010046e:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100471:	c1 e0 04             	shl    $0x4,%eax
f0100474:	66 a3 28 32 12 f0    	mov    %ax,0xf0123228
	if (crt_pos >= CRT_SIZE) {
f010047a:	66 81 3d 28 32 12 f0 	cmpw   $0x7cf,0xf0123228
f0100481:	cf 07 
f0100483:	0f 87 ce 00 00 00    	ja     f0100557 <cons_putc+0x1b3>
	outb(addr_6845, 14);
f0100489:	8b 0d 30 32 12 f0    	mov    0xf0123230,%ecx
f010048f:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100494:	89 ca                	mov    %ecx,%edx
f0100496:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100497:	0f b7 1d 28 32 12 f0 	movzwl 0xf0123228,%ebx
f010049e:	8d 71 01             	lea    0x1(%ecx),%esi
f01004a1:	89 d8                	mov    %ebx,%eax
f01004a3:	66 c1 e8 08          	shr    $0x8,%ax
f01004a7:	89 f2                	mov    %esi,%edx
f01004a9:	ee                   	out    %al,(%dx)
f01004aa:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004af:	89 ca                	mov    %ecx,%edx
f01004b1:	ee                   	out    %al,(%dx)
f01004b2:	89 d8                	mov    %ebx,%eax
f01004b4:	89 f2                	mov    %esi,%edx
f01004b6:	ee                   	out    %al,(%dx)
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004b7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01004ba:	5b                   	pop    %ebx
f01004bb:	5e                   	pop    %esi
f01004bc:	5f                   	pop    %edi
f01004bd:	5d                   	pop    %ebp
f01004be:	c3                   	ret    
	switch (c & 0xff) {
f01004bf:	83 f8 08             	cmp    $0x8,%eax
f01004c2:	75 70                	jne    f0100534 <cons_putc+0x190>
		if (crt_pos > 0) {
f01004c4:	0f b7 05 28 32 12 f0 	movzwl 0xf0123228,%eax
f01004cb:	66 85 c0             	test   %ax,%ax
f01004ce:	74 b9                	je     f0100489 <cons_putc+0xe5>
			crt_pos--;
f01004d0:	83 e8 01             	sub    $0x1,%eax
f01004d3:	66 a3 28 32 12 f0    	mov    %ax,0xf0123228
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01004d9:	0f b7 c0             	movzwl %ax,%eax
f01004dc:	66 81 e7 00 ff       	and    $0xff00,%di
f01004e1:	83 cf 20             	or     $0x20,%edi
f01004e4:	8b 15 2c 32 12 f0    	mov    0xf012322c,%edx
f01004ea:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01004ee:	eb 8a                	jmp    f010047a <cons_putc+0xd6>
		crt_pos += CRT_COLS;
f01004f0:	66 83 05 28 32 12 f0 	addw   $0x50,0xf0123228
f01004f7:	50 
f01004f8:	e9 61 ff ff ff       	jmp    f010045e <cons_putc+0xba>
		cons_putc(' ');
f01004fd:	b8 20 00 00 00       	mov    $0x20,%eax
f0100502:	e8 9d fe ff ff       	call   f01003a4 <cons_putc>
		cons_putc(' ');
f0100507:	b8 20 00 00 00       	mov    $0x20,%eax
f010050c:	e8 93 fe ff ff       	call   f01003a4 <cons_putc>
		cons_putc(' ');
f0100511:	b8 20 00 00 00       	mov    $0x20,%eax
f0100516:	e8 89 fe ff ff       	call   f01003a4 <cons_putc>
		cons_putc(' ');
f010051b:	b8 20 00 00 00       	mov    $0x20,%eax
f0100520:	e8 7f fe ff ff       	call   f01003a4 <cons_putc>
		cons_putc(' ');
f0100525:	b8 20 00 00 00       	mov    $0x20,%eax
f010052a:	e8 75 fe ff ff       	call   f01003a4 <cons_putc>
f010052f:	e9 46 ff ff ff       	jmp    f010047a <cons_putc+0xd6>
		crt_buf[crt_pos++] = c;		/* write the character */
f0100534:	0f b7 05 28 32 12 f0 	movzwl 0xf0123228,%eax
f010053b:	8d 50 01             	lea    0x1(%eax),%edx
f010053e:	66 89 15 28 32 12 f0 	mov    %dx,0xf0123228
f0100545:	0f b7 c0             	movzwl %ax,%eax
f0100548:	8b 15 2c 32 12 f0    	mov    0xf012322c,%edx
f010054e:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100552:	e9 23 ff ff ff       	jmp    f010047a <cons_putc+0xd6>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100557:	a1 2c 32 12 f0       	mov    0xf012322c,%eax
f010055c:	83 ec 04             	sub    $0x4,%esp
f010055f:	68 00 0f 00 00       	push   $0xf00
f0100564:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010056a:	52                   	push   %edx
f010056b:	50                   	push   %eax
f010056c:	e8 94 32 00 00       	call   f0103805 <memmove>
			crt_buf[i] = 0x0700 | ' ';
f0100571:	8b 15 2c 32 12 f0    	mov    0xf012322c,%edx
f0100577:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f010057d:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100583:	83 c4 10             	add    $0x10,%esp
f0100586:	66 c7 00 20 07       	movw   $0x720,(%eax)
f010058b:	83 c0 02             	add    $0x2,%eax
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010058e:	39 d0                	cmp    %edx,%eax
f0100590:	75 f4                	jne    f0100586 <cons_putc+0x1e2>
		crt_pos -= CRT_COLS;
f0100592:	66 83 2d 28 32 12 f0 	subw   $0x50,0xf0123228
f0100599:	50 
f010059a:	e9 ea fe ff ff       	jmp    f0100489 <cons_putc+0xe5>

f010059f <serial_intr>:
	if (serial_exists)
f010059f:	80 3d 34 32 12 f0 00 	cmpb   $0x0,0xf0123234
f01005a6:	75 02                	jne    f01005aa <serial_intr+0xb>
f01005a8:	f3 c3                	repz ret 
{
f01005aa:	55                   	push   %ebp
f01005ab:	89 e5                	mov    %esp,%ebp
f01005ad:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f01005b0:	b8 25 02 10 f0       	mov    $0xf0100225,%eax
f01005b5:	e8 8a fc ff ff       	call   f0100244 <cons_intr>
}
f01005ba:	c9                   	leave  
f01005bb:	c3                   	ret    

f01005bc <kbd_intr>:
{
f01005bc:	55                   	push   %ebp
f01005bd:	89 e5                	mov    %esp,%ebp
f01005bf:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01005c2:	b8 87 02 10 f0       	mov    $0xf0100287,%eax
f01005c7:	e8 78 fc ff ff       	call   f0100244 <cons_intr>
}
f01005cc:	c9                   	leave  
f01005cd:	c3                   	ret    

f01005ce <cons_getc>:
{
f01005ce:	55                   	push   %ebp
f01005cf:	89 e5                	mov    %esp,%ebp
f01005d1:	83 ec 08             	sub    $0x8,%esp
	serial_intr();
f01005d4:	e8 c6 ff ff ff       	call   f010059f <serial_intr>
	kbd_intr();
f01005d9:	e8 de ff ff ff       	call   f01005bc <kbd_intr>
	if (cons.rpos != cons.wpos) {
f01005de:	8b 15 20 32 12 f0    	mov    0xf0123220,%edx
	return 0;
f01005e4:	b8 00 00 00 00       	mov    $0x0,%eax
	if (cons.rpos != cons.wpos) {
f01005e9:	3b 15 24 32 12 f0    	cmp    0xf0123224,%edx
f01005ef:	74 18                	je     f0100609 <cons_getc+0x3b>
		c = cons.buf[cons.rpos++];
f01005f1:	8d 4a 01             	lea    0x1(%edx),%ecx
f01005f4:	89 0d 20 32 12 f0    	mov    %ecx,0xf0123220
f01005fa:	0f b6 82 20 30 12 f0 	movzbl -0xfedcfe0(%edx),%eax
		if (cons.rpos == CONSBUFSIZE)
f0100601:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f0100607:	74 02                	je     f010060b <cons_getc+0x3d>
}
f0100609:	c9                   	leave  
f010060a:	c3                   	ret    
			cons.rpos = 0;
f010060b:	c7 05 20 32 12 f0 00 	movl   $0x0,0xf0123220
f0100612:	00 00 00 
f0100615:	eb f2                	jmp    f0100609 <cons_getc+0x3b>

f0100617 <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f0100617:	55                   	push   %ebp
f0100618:	89 e5                	mov    %esp,%ebp
f010061a:	57                   	push   %edi
f010061b:	56                   	push   %esi
f010061c:	53                   	push   %ebx
f010061d:	83 ec 0c             	sub    $0xc,%esp
	was = *cp;
f0100620:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100627:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010062e:	5a a5 
	if (*cp != 0xA55A) {
f0100630:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100637:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010063b:	0f 84 b7 00 00 00    	je     f01006f8 <cons_init+0xe1>
		addr_6845 = MONO_BASE;
f0100641:	c7 05 30 32 12 f0 b4 	movl   $0x3b4,0xf0123230
f0100648:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010064b:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
	outb(addr_6845, 14);
f0100650:	8b 3d 30 32 12 f0    	mov    0xf0123230,%edi
f0100656:	b8 0e 00 00 00       	mov    $0xe,%eax
f010065b:	89 fa                	mov    %edi,%edx
f010065d:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010065e:	8d 4f 01             	lea    0x1(%edi),%ecx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100661:	89 ca                	mov    %ecx,%edx
f0100663:	ec                   	in     (%dx),%al
f0100664:	0f b6 c0             	movzbl %al,%eax
f0100667:	c1 e0 08             	shl    $0x8,%eax
f010066a:	89 c3                	mov    %eax,%ebx
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010066c:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100671:	89 fa                	mov    %edi,%edx
f0100673:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100674:	89 ca                	mov    %ecx,%edx
f0100676:	ec                   	in     (%dx),%al
	crt_buf = (uint16_t*) cp;
f0100677:	89 35 2c 32 12 f0    	mov    %esi,0xf012322c
	pos |= inb(addr_6845 + 1);
f010067d:	0f b6 c0             	movzbl %al,%eax
f0100680:	09 d8                	or     %ebx,%eax
	crt_pos = pos;
f0100682:	66 a3 28 32 12 f0    	mov    %ax,0xf0123228
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100688:	bb 00 00 00 00       	mov    $0x0,%ebx
f010068d:	b9 fa 03 00 00       	mov    $0x3fa,%ecx
f0100692:	89 d8                	mov    %ebx,%eax
f0100694:	89 ca                	mov    %ecx,%edx
f0100696:	ee                   	out    %al,(%dx)
f0100697:	bf fb 03 00 00       	mov    $0x3fb,%edi
f010069c:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01006a1:	89 fa                	mov    %edi,%edx
f01006a3:	ee                   	out    %al,(%dx)
f01006a4:	b8 0c 00 00 00       	mov    $0xc,%eax
f01006a9:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01006ae:	ee                   	out    %al,(%dx)
f01006af:	be f9 03 00 00       	mov    $0x3f9,%esi
f01006b4:	89 d8                	mov    %ebx,%eax
f01006b6:	89 f2                	mov    %esi,%edx
f01006b8:	ee                   	out    %al,(%dx)
f01006b9:	b8 03 00 00 00       	mov    $0x3,%eax
f01006be:	89 fa                	mov    %edi,%edx
f01006c0:	ee                   	out    %al,(%dx)
f01006c1:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01006c6:	89 d8                	mov    %ebx,%eax
f01006c8:	ee                   	out    %al,(%dx)
f01006c9:	b8 01 00 00 00       	mov    $0x1,%eax
f01006ce:	89 f2                	mov    %esi,%edx
f01006d0:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006d1:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01006d6:	ec                   	in     (%dx),%al
f01006d7:	89 c3                	mov    %eax,%ebx
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01006d9:	3c ff                	cmp    $0xff,%al
f01006db:	0f 95 05 34 32 12 f0 	setne  0xf0123234
f01006e2:	89 ca                	mov    %ecx,%edx
f01006e4:	ec                   	in     (%dx),%al
f01006e5:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01006ea:	ec                   	in     (%dx),%al
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01006eb:	80 fb ff             	cmp    $0xff,%bl
f01006ee:	74 23                	je     f0100713 <cons_init+0xfc>
		cprintf("Serial port does not exist!\n");
}
f01006f0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01006f3:	5b                   	pop    %ebx
f01006f4:	5e                   	pop    %esi
f01006f5:	5f                   	pop    %edi
f01006f6:	5d                   	pop    %ebp
f01006f7:	c3                   	ret    
		*cp = was;
f01006f8:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01006ff:	c7 05 30 32 12 f0 d4 	movl   $0x3d4,0xf0123230
f0100706:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100709:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
f010070e:	e9 3d ff ff ff       	jmp    f0100650 <cons_init+0x39>
		cprintf("Serial port does not exist!\n");
f0100713:	83 ec 0c             	sub    $0xc,%esp
f0100716:	68 7a 3c 10 f0       	push   $0xf0103c7a
f010071b:	e8 69 00 00 00       	call   f0100789 <cprintf>
f0100720:	83 c4 10             	add    $0x10,%esp
}
f0100723:	eb cb                	jmp    f01006f0 <cons_init+0xd9>

f0100725 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100725:	55                   	push   %ebp
f0100726:	89 e5                	mov    %esp,%ebp
f0100728:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010072b:	8b 45 08             	mov    0x8(%ebp),%eax
f010072e:	e8 71 fc ff ff       	call   f01003a4 <cons_putc>
}
f0100733:	c9                   	leave  
f0100734:	c3                   	ret    

f0100735 <getchar>:

int
getchar(void)
{
f0100735:	55                   	push   %ebp
f0100736:	89 e5                	mov    %esp,%ebp
f0100738:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010073b:	e8 8e fe ff ff       	call   f01005ce <cons_getc>
f0100740:	85 c0                	test   %eax,%eax
f0100742:	74 f7                	je     f010073b <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100744:	c9                   	leave  
f0100745:	c3                   	ret    

f0100746 <iscons>:

int
iscons(int fdnum)
{
f0100746:	55                   	push   %ebp
f0100747:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100749:	b8 01 00 00 00       	mov    $0x1,%eax
f010074e:	5d                   	pop    %ebp
f010074f:	c3                   	ret    

f0100750 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100750:	55                   	push   %ebp
f0100751:	89 e5                	mov    %esp,%ebp
f0100753:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0100756:	ff 75 08             	pushl  0x8(%ebp)
f0100759:	e8 c7 ff ff ff       	call   f0100725 <cputchar>
	*cnt++;
}
f010075e:	83 c4 10             	add    $0x10,%esp
f0100761:	c9                   	leave  
f0100762:	c3                   	ret    

f0100763 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100763:	55                   	push   %ebp
f0100764:	89 e5                	mov    %esp,%ebp
f0100766:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0100769:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100770:	ff 75 0c             	pushl  0xc(%ebp)
f0100773:	ff 75 08             	pushl  0x8(%ebp)
f0100776:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100779:	50                   	push   %eax
f010077a:	68 50 07 10 f0       	push   $0xf0100750
f010077f:	e8 ef 28 00 00       	call   f0103073 <vprintfmt>
	return cnt;
}
f0100784:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100787:	c9                   	leave  
f0100788:	c3                   	ret    

f0100789 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100789:	55                   	push   %ebp
f010078a:	89 e5                	mov    %esp,%ebp
f010078c:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010078f:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100792:	50                   	push   %eax
f0100793:	ff 75 08             	pushl  0x8(%ebp)
f0100796:	e8 c8 ff ff ff       	call   f0100763 <vcprintf>
	va_end(ap);

	return cnt;
}
f010079b:	c9                   	leave  
f010079c:	c3                   	ret    

f010079d <trap_init>:
extern uint32_t vectors[]; // in vectors.S: array of 256 entry pointers

// Initialize the interrupt descriptor table.
void
trap_init(void)
{
f010079d:	55                   	push   %ebp
f010079e:	89 e5                	mov    %esp,%ebp
	//
	// Hints:
	// 1. The macro SETGATE in inc/mmu.h should help you, as well as the
	// T_* defines in inc/traps.h;
	// 2. T_SYSCALL is different from the others.
	for (int i = 0; i < 256; i++)
f01007a0:	b8 00 00 00 00       	mov    $0x0,%eax
		SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
f01007a5:	8b 14 85 00 c3 11 f0 	mov    -0xfee3d00(,%eax,4),%edx
f01007ac:	66 89 14 c5 60 36 12 	mov    %dx,-0xfedc9a0(,%eax,8)
f01007b3:	f0 
f01007b4:	66 c7 04 c5 62 36 12 	movw   $0x8,-0xfedc99e(,%eax,8)
f01007bb:	f0 08 00 
f01007be:	c6 04 c5 64 36 12 f0 	movb   $0x0,-0xfedc99c(,%eax,8)
f01007c5:	00 
f01007c6:	c6 04 c5 65 36 12 f0 	movb   $0x8e,-0xfedc99b(,%eax,8)
f01007cd:	8e 
f01007ce:	c1 ea 10             	shr    $0x10,%edx
f01007d1:	66 89 14 c5 66 36 12 	mov    %dx,-0xfedc99a(,%eax,8)
f01007d8:	f0 
	for (int i = 0; i < 256; i++)
f01007d9:	83 c0 01             	add    $0x1,%eax
f01007dc:	3d 00 01 00 00       	cmp    $0x100,%eax
f01007e1:	75 c2                	jne    f01007a5 <trap_init+0x8>
	SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
f01007e3:	a1 00 c4 11 f0       	mov    0xf011c400,%eax
f01007e8:	66 a3 60 38 12 f0    	mov    %ax,0xf0123860
f01007ee:	66 c7 05 62 38 12 f0 	movw   $0x8,0xf0123862
f01007f5:	08 00 
f01007f7:	c6 05 64 38 12 f0 00 	movb   $0x0,0xf0123864
f01007fe:	c6 05 65 38 12 f0 ef 	movb   $0xef,0xf0123865
f0100805:	c1 e8 10             	shr    $0x10,%eax
f0100808:	66 a3 66 38 12 f0    	mov    %ax,0xf0123866
}
f010080e:	5d                   	pop    %ebp
f010080f:	c3                   	ret    

f0100810 <idt_init>:

void
idt_init(void)
{
f0100810:	55                   	push   %ebp
f0100811:	89 e5                	mov    %esp,%ebp
f0100813:	83 ec 10             	sub    $0x10,%esp
	pd[0] = size-1;
f0100816:	66 c7 45 fa ff 07    	movw   $0x7ff,-0x6(%ebp)
	pd[1] = (unsigned)p;
f010081c:	b8 60 36 12 f0       	mov    $0xf0123660,%eax
f0100821:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
	pd[2] = (unsigned)p >> 16;
f0100825:	c1 e8 10             	shr    $0x10,%eax
f0100828:	66 89 45 fe          	mov    %ax,-0x2(%ebp)
	asm volatile("lidt (%0)" : : "r" (pd));
f010082c:	8d 45 fa             	lea    -0x6(%ebp),%eax
f010082f:	0f 01 18             	lidtl  (%eax)
	lidt(idt, sizeof(idt));
}
f0100832:	c9                   	leave  
f0100833:	c3                   	ret    

f0100834 <trap>:

void
trap(struct trapframe *tf)
{
f0100834:	55                   	push   %ebp
f0100835:	89 e5                	mov    %esp,%ebp
f0100837:	57                   	push   %edi
f0100838:	56                   	push   %esi
f0100839:	53                   	push   %ebx
f010083a:	83 ec 1c             	sub    $0x1c,%esp
f010083d:	8b 7d 08             	mov    0x8(%ebp),%edi
	// You don't need to implement this function now, but you can write
	// some code for debugging.
	struct proc *p = thisproc();
f0100840:	e8 04 26 00 00       	call   f0102e49 <thisproc>
f0100845:	89 c3                	mov    %eax,%ebx
	if (tf->trapno == T_SYSCALL) {
f0100847:	83 7f 30 40          	cmpl   $0x40,0x30(%edi)
f010084b:	74 44                	je     f0100891 <trap+0x5d>
		p->tf = tf;
		syscall(tf->eax, tf->edx, tf->ecx, tf->ebx, tf->edi, tf->esi);
	}
	switch (tf->trapno) {
f010084d:	83 7f 30 20          	cmpl   $0x20,0x30(%edi)
f0100851:	74 5f                	je     f01008b2 <trap+0x7e>
		cprintf("in timer.\n");
		//lapic_eoi();
		break;
	
	default:
		if (p == NULL || (tf->cs & 3) == 0) {
f0100853:	85 db                	test   %ebx,%ebx
f0100855:	74 6d                	je     f01008c4 <trap+0x90>
f0100857:	f6 47 3c 03          	testb  $0x3,0x3c(%edi)
f010085b:	74 67                	je     f01008c4 <trap+0x90>
	asm volatile("movl %%cr2,%0" : "=r" (val));
f010085d:	0f 20 d0             	mov    %cr2,%eax
f0100860:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			cprintf("unexpected trap %d from cpu %d eip: %x (cr2=0x%x)\n",
              tf->trapno, cpunum(), tf->eip, rcr2());
      		panic("trap");
		}
		cprintf("pid %d : trap %d err %d on cpu %d "
f0100863:	8b 77 38             	mov    0x38(%edi),%esi
f0100866:	e8 19 1d 00 00       	call   f0102584 <cpunum>
f010086b:	83 ec 04             	sub    $0x4,%esp
f010086e:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100871:	56                   	push   %esi
f0100872:	50                   	push   %eax
f0100873:	ff 77 34             	pushl  0x34(%edi)
f0100876:	ff 77 30             	pushl  0x30(%edi)
f0100879:	ff 73 0c             	pushl  0xc(%ebx)
f010087c:	68 10 3f 10 f0       	push   $0xf0103f10
f0100881:	e8 03 ff ff ff       	call   f0100789 <cprintf>
f0100886:	83 c4 20             	add    $0x20,%esp
            p->pid, tf->trapno,
            tf->err, cpunum(), tf->eip, rcr2());
	}
	//if (p && p->state == RUNNING && tf->trapno == T_IRQ0 + IRQ_TIMER)
	//	yield();
f0100889:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010088c:	5b                   	pop    %ebx
f010088d:	5e                   	pop    %esi
f010088e:	5f                   	pop    %edi
f010088f:	5d                   	pop    %ebp
f0100890:	c3                   	ret    
		p->tf = tf;
f0100891:	89 78 14             	mov    %edi,0x14(%eax)
		syscall(tf->eax, tf->edx, tf->ecx, tf->ebx, tf->edi, tf->esi);
f0100894:	83 ec 08             	sub    $0x8,%esp
f0100897:	ff 77 04             	pushl  0x4(%edi)
f010089a:	ff 37                	pushl  (%edi)
f010089c:	ff 77 10             	pushl  0x10(%edi)
f010089f:	ff 77 18             	pushl  0x18(%edi)
f01008a2:	ff 77 14             	pushl  0x14(%edi)
f01008a5:	ff 77 1c             	pushl  0x1c(%edi)
f01008a8:	e8 28 26 00 00       	call   f0102ed5 <syscall>
f01008ad:	83 c4 20             	add    $0x20,%esp
f01008b0:	eb 9b                	jmp    f010084d <trap+0x19>
		cprintf("in timer.\n");
f01008b2:	83 ec 0c             	sub    $0xc,%esp
f01008b5:	68 c0 3e 10 f0       	push   $0xf0103ec0
f01008ba:	e8 ca fe ff ff       	call   f0100789 <cprintf>
		break;
f01008bf:	83 c4 10             	add    $0x10,%esp
f01008c2:	eb c5                	jmp    f0100889 <trap+0x55>
f01008c4:	0f 20 d6             	mov    %cr2,%esi
			cprintf("unexpected trap %d from cpu %d eip: %x (cr2=0x%x)\n",
f01008c7:	8b 5f 38             	mov    0x38(%edi),%ebx
f01008ca:	e8 b5 1c 00 00       	call   f0102584 <cpunum>
f01008cf:	83 ec 0c             	sub    $0xc,%esp
f01008d2:	56                   	push   %esi
f01008d3:	53                   	push   %ebx
f01008d4:	50                   	push   %eax
f01008d5:	ff 77 30             	pushl  0x30(%edi)
f01008d8:	68 dc 3e 10 f0       	push   $0xf0103edc
f01008dd:	e8 a7 fe ff ff       	call   f0100789 <cprintf>
      		panic("trap");
f01008e2:	83 c4 1c             	add    $0x1c,%esp
f01008e5:	68 cb 3e 10 f0       	push   $0xf0103ecb
f01008ea:	6a 3a                	push   $0x3a
f01008ec:	68 d0 3e 10 f0       	push   $0xf0103ed0
f01008f1:	e8 a9 f8 ff ff       	call   f010019f <_panic>

f01008f6 <alltraps>:
alltraps:
	# Your code here:
	#
	# Hint: you should build trap frame, set up data segments and then
	# call trap(tf)
	pushl %ds
f01008f6:	1e                   	push   %ds
	pushl %es
f01008f7:	06                   	push   %es
	pushl %fs
f01008f8:	0f a0                	push   %fs
	pushl %gs
f01008fa:	0f a8                	push   %gs
	pushal 
f01008fc:	60                   	pusha  

	movw $(SEG_KDATA<<3), %ax
f01008fd:	66 b8 10 00          	mov    $0x10,%ax
	movw %ax, %ds
f0100901:	8e d8                	mov    %eax,%ds
	movw %ax, %es
f0100903:	8e c0                	mov    %eax,%es

	pushl %esp
f0100905:	54                   	push   %esp
	call trap
f0100906:	e8 29 ff ff ff       	call   f0100834 <trap>
	addl $4, %esp
f010090b:	83 c4 04             	add    $0x4,%esp

f010090e <trapret>:
	# Return falls through to trapret...
.globl trapret
trapret:
	# Restore registers.
	# Your code here:
	popal
f010090e:	61                   	popa   
	popl %gs
f010090f:	0f a9                	pop    %gs
	popl %fs
f0100911:	0f a1                	pop    %fs
	popl %es
f0100913:	07                   	pop    %es
	popl %ds
f0100914:	1f                   	pop    %ds
	addl $0x8, %esp
f0100915:	83 c4 08             	add    $0x8,%esp
	iret
f0100918:	cf                   	iret   

f0100919 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
f0100919:	6a 00                	push   $0x0
  pushl $0
f010091b:	6a 00                	push   $0x0
  jmp alltraps
f010091d:	e9 d4 ff ff ff       	jmp    f01008f6 <alltraps>

f0100922 <vector1>:
.globl vector1
vector1:
  pushl $0
f0100922:	6a 00                	push   $0x0
  pushl $1
f0100924:	6a 01                	push   $0x1
  jmp alltraps
f0100926:	e9 cb ff ff ff       	jmp    f01008f6 <alltraps>

f010092b <vector2>:
.globl vector2
vector2:
  pushl $0
f010092b:	6a 00                	push   $0x0
  pushl $2
f010092d:	6a 02                	push   $0x2
  jmp alltraps
f010092f:	e9 c2 ff ff ff       	jmp    f01008f6 <alltraps>

f0100934 <vector3>:
.globl vector3
vector3:
  pushl $0
f0100934:	6a 00                	push   $0x0
  pushl $3
f0100936:	6a 03                	push   $0x3
  jmp alltraps
f0100938:	e9 b9 ff ff ff       	jmp    f01008f6 <alltraps>

f010093d <vector4>:
.globl vector4
vector4:
  pushl $0
f010093d:	6a 00                	push   $0x0
  pushl $4
f010093f:	6a 04                	push   $0x4
  jmp alltraps
f0100941:	e9 b0 ff ff ff       	jmp    f01008f6 <alltraps>

f0100946 <vector5>:
.globl vector5
vector5:
  pushl $0
f0100946:	6a 00                	push   $0x0
  pushl $5
f0100948:	6a 05                	push   $0x5
  jmp alltraps
f010094a:	e9 a7 ff ff ff       	jmp    f01008f6 <alltraps>

f010094f <vector6>:
.globl vector6
vector6:
  pushl $0
f010094f:	6a 00                	push   $0x0
  pushl $6
f0100951:	6a 06                	push   $0x6
  jmp alltraps
f0100953:	e9 9e ff ff ff       	jmp    f01008f6 <alltraps>

f0100958 <vector7>:
.globl vector7
vector7:
  pushl $0
f0100958:	6a 00                	push   $0x0
  pushl $7
f010095a:	6a 07                	push   $0x7
  jmp alltraps
f010095c:	e9 95 ff ff ff       	jmp    f01008f6 <alltraps>

f0100961 <vector8>:
.globl vector8
vector8:
  pushl $8
f0100961:	6a 08                	push   $0x8
  jmp alltraps
f0100963:	e9 8e ff ff ff       	jmp    f01008f6 <alltraps>

f0100968 <vector9>:
.globl vector9
vector9:
  pushl $0
f0100968:	6a 00                	push   $0x0
  pushl $9
f010096a:	6a 09                	push   $0x9
  jmp alltraps
f010096c:	e9 85 ff ff ff       	jmp    f01008f6 <alltraps>

f0100971 <vector10>:
.globl vector10
vector10:
  pushl $10
f0100971:	6a 0a                	push   $0xa
  jmp alltraps
f0100973:	e9 7e ff ff ff       	jmp    f01008f6 <alltraps>

f0100978 <vector11>:
.globl vector11
vector11:
  pushl $11
f0100978:	6a 0b                	push   $0xb
  jmp alltraps
f010097a:	e9 77 ff ff ff       	jmp    f01008f6 <alltraps>

f010097f <vector12>:
.globl vector12
vector12:
  pushl $12
f010097f:	6a 0c                	push   $0xc
  jmp alltraps
f0100981:	e9 70 ff ff ff       	jmp    f01008f6 <alltraps>

f0100986 <vector13>:
.globl vector13
vector13:
  pushl $13
f0100986:	6a 0d                	push   $0xd
  jmp alltraps
f0100988:	e9 69 ff ff ff       	jmp    f01008f6 <alltraps>

f010098d <vector14>:
.globl vector14
vector14:
  pushl $14
f010098d:	6a 0e                	push   $0xe
  jmp alltraps
f010098f:	e9 62 ff ff ff       	jmp    f01008f6 <alltraps>

f0100994 <vector15>:
.globl vector15
vector15:
  pushl $0
f0100994:	6a 00                	push   $0x0
  pushl $15
f0100996:	6a 0f                	push   $0xf
  jmp alltraps
f0100998:	e9 59 ff ff ff       	jmp    f01008f6 <alltraps>

f010099d <vector16>:
.globl vector16
vector16:
  pushl $0
f010099d:	6a 00                	push   $0x0
  pushl $16
f010099f:	6a 10                	push   $0x10
  jmp alltraps
f01009a1:	e9 50 ff ff ff       	jmp    f01008f6 <alltraps>

f01009a6 <vector17>:
.globl vector17
vector17:
  pushl $17
f01009a6:	6a 11                	push   $0x11
  jmp alltraps
f01009a8:	e9 49 ff ff ff       	jmp    f01008f6 <alltraps>

f01009ad <vector18>:
.globl vector18
vector18:
  pushl $0
f01009ad:	6a 00                	push   $0x0
  pushl $18
f01009af:	6a 12                	push   $0x12
  jmp alltraps
f01009b1:	e9 40 ff ff ff       	jmp    f01008f6 <alltraps>

f01009b6 <vector19>:
.globl vector19
vector19:
  pushl $0
f01009b6:	6a 00                	push   $0x0
  pushl $19
f01009b8:	6a 13                	push   $0x13
  jmp alltraps
f01009ba:	e9 37 ff ff ff       	jmp    f01008f6 <alltraps>

f01009bf <vector20>:
.globl vector20
vector20:
  pushl $0
f01009bf:	6a 00                	push   $0x0
  pushl $20
f01009c1:	6a 14                	push   $0x14
  jmp alltraps
f01009c3:	e9 2e ff ff ff       	jmp    f01008f6 <alltraps>

f01009c8 <vector21>:
.globl vector21
vector21:
  pushl $0
f01009c8:	6a 00                	push   $0x0
  pushl $21
f01009ca:	6a 15                	push   $0x15
  jmp alltraps
f01009cc:	e9 25 ff ff ff       	jmp    f01008f6 <alltraps>

f01009d1 <vector22>:
.globl vector22
vector22:
  pushl $0
f01009d1:	6a 00                	push   $0x0
  pushl $22
f01009d3:	6a 16                	push   $0x16
  jmp alltraps
f01009d5:	e9 1c ff ff ff       	jmp    f01008f6 <alltraps>

f01009da <vector23>:
.globl vector23
vector23:
  pushl $0
f01009da:	6a 00                	push   $0x0
  pushl $23
f01009dc:	6a 17                	push   $0x17
  jmp alltraps
f01009de:	e9 13 ff ff ff       	jmp    f01008f6 <alltraps>

f01009e3 <vector24>:
.globl vector24
vector24:
  pushl $0
f01009e3:	6a 00                	push   $0x0
  pushl $24
f01009e5:	6a 18                	push   $0x18
  jmp alltraps
f01009e7:	e9 0a ff ff ff       	jmp    f01008f6 <alltraps>

f01009ec <vector25>:
.globl vector25
vector25:
  pushl $0
f01009ec:	6a 00                	push   $0x0
  pushl $25
f01009ee:	6a 19                	push   $0x19
  jmp alltraps
f01009f0:	e9 01 ff ff ff       	jmp    f01008f6 <alltraps>

f01009f5 <vector26>:
.globl vector26
vector26:
  pushl $0
f01009f5:	6a 00                	push   $0x0
  pushl $26
f01009f7:	6a 1a                	push   $0x1a
  jmp alltraps
f01009f9:	e9 f8 fe ff ff       	jmp    f01008f6 <alltraps>

f01009fe <vector27>:
.globl vector27
vector27:
  pushl $0
f01009fe:	6a 00                	push   $0x0
  pushl $27
f0100a00:	6a 1b                	push   $0x1b
  jmp alltraps
f0100a02:	e9 ef fe ff ff       	jmp    f01008f6 <alltraps>

f0100a07 <vector28>:
.globl vector28
vector28:
  pushl $0
f0100a07:	6a 00                	push   $0x0
  pushl $28
f0100a09:	6a 1c                	push   $0x1c
  jmp alltraps
f0100a0b:	e9 e6 fe ff ff       	jmp    f01008f6 <alltraps>

f0100a10 <vector29>:
.globl vector29
vector29:
  pushl $0
f0100a10:	6a 00                	push   $0x0
  pushl $29
f0100a12:	6a 1d                	push   $0x1d
  jmp alltraps
f0100a14:	e9 dd fe ff ff       	jmp    f01008f6 <alltraps>

f0100a19 <vector30>:
.globl vector30
vector30:
  pushl $0
f0100a19:	6a 00                	push   $0x0
  pushl $30
f0100a1b:	6a 1e                	push   $0x1e
  jmp alltraps
f0100a1d:	e9 d4 fe ff ff       	jmp    f01008f6 <alltraps>

f0100a22 <vector31>:
.globl vector31
vector31:
  pushl $0
f0100a22:	6a 00                	push   $0x0
  pushl $31
f0100a24:	6a 1f                	push   $0x1f
  jmp alltraps
f0100a26:	e9 cb fe ff ff       	jmp    f01008f6 <alltraps>

f0100a2b <vector32>:
.globl vector32
vector32:
  pushl $0
f0100a2b:	6a 00                	push   $0x0
  pushl $32
f0100a2d:	6a 20                	push   $0x20
  jmp alltraps
f0100a2f:	e9 c2 fe ff ff       	jmp    f01008f6 <alltraps>

f0100a34 <vector33>:
.globl vector33
vector33:
  pushl $0
f0100a34:	6a 00                	push   $0x0
  pushl $33
f0100a36:	6a 21                	push   $0x21
  jmp alltraps
f0100a38:	e9 b9 fe ff ff       	jmp    f01008f6 <alltraps>

f0100a3d <vector34>:
.globl vector34
vector34:
  pushl $0
f0100a3d:	6a 00                	push   $0x0
  pushl $34
f0100a3f:	6a 22                	push   $0x22
  jmp alltraps
f0100a41:	e9 b0 fe ff ff       	jmp    f01008f6 <alltraps>

f0100a46 <vector35>:
.globl vector35
vector35:
  pushl $0
f0100a46:	6a 00                	push   $0x0
  pushl $35
f0100a48:	6a 23                	push   $0x23
  jmp alltraps
f0100a4a:	e9 a7 fe ff ff       	jmp    f01008f6 <alltraps>

f0100a4f <vector36>:
.globl vector36
vector36:
  pushl $0
f0100a4f:	6a 00                	push   $0x0
  pushl $36
f0100a51:	6a 24                	push   $0x24
  jmp alltraps
f0100a53:	e9 9e fe ff ff       	jmp    f01008f6 <alltraps>

f0100a58 <vector37>:
.globl vector37
vector37:
  pushl $0
f0100a58:	6a 00                	push   $0x0
  pushl $37
f0100a5a:	6a 25                	push   $0x25
  jmp alltraps
f0100a5c:	e9 95 fe ff ff       	jmp    f01008f6 <alltraps>

f0100a61 <vector38>:
.globl vector38
vector38:
  pushl $0
f0100a61:	6a 00                	push   $0x0
  pushl $38
f0100a63:	6a 26                	push   $0x26
  jmp alltraps
f0100a65:	e9 8c fe ff ff       	jmp    f01008f6 <alltraps>

f0100a6a <vector39>:
.globl vector39
vector39:
  pushl $0
f0100a6a:	6a 00                	push   $0x0
  pushl $39
f0100a6c:	6a 27                	push   $0x27
  jmp alltraps
f0100a6e:	e9 83 fe ff ff       	jmp    f01008f6 <alltraps>

f0100a73 <vector40>:
.globl vector40
vector40:
  pushl $0
f0100a73:	6a 00                	push   $0x0
  pushl $40
f0100a75:	6a 28                	push   $0x28
  jmp alltraps
f0100a77:	e9 7a fe ff ff       	jmp    f01008f6 <alltraps>

f0100a7c <vector41>:
.globl vector41
vector41:
  pushl $0
f0100a7c:	6a 00                	push   $0x0
  pushl $41
f0100a7e:	6a 29                	push   $0x29
  jmp alltraps
f0100a80:	e9 71 fe ff ff       	jmp    f01008f6 <alltraps>

f0100a85 <vector42>:
.globl vector42
vector42:
  pushl $0
f0100a85:	6a 00                	push   $0x0
  pushl $42
f0100a87:	6a 2a                	push   $0x2a
  jmp alltraps
f0100a89:	e9 68 fe ff ff       	jmp    f01008f6 <alltraps>

f0100a8e <vector43>:
.globl vector43
vector43:
  pushl $0
f0100a8e:	6a 00                	push   $0x0
  pushl $43
f0100a90:	6a 2b                	push   $0x2b
  jmp alltraps
f0100a92:	e9 5f fe ff ff       	jmp    f01008f6 <alltraps>

f0100a97 <vector44>:
.globl vector44
vector44:
  pushl $0
f0100a97:	6a 00                	push   $0x0
  pushl $44
f0100a99:	6a 2c                	push   $0x2c
  jmp alltraps
f0100a9b:	e9 56 fe ff ff       	jmp    f01008f6 <alltraps>

f0100aa0 <vector45>:
.globl vector45
vector45:
  pushl $0
f0100aa0:	6a 00                	push   $0x0
  pushl $45
f0100aa2:	6a 2d                	push   $0x2d
  jmp alltraps
f0100aa4:	e9 4d fe ff ff       	jmp    f01008f6 <alltraps>

f0100aa9 <vector46>:
.globl vector46
vector46:
  pushl $0
f0100aa9:	6a 00                	push   $0x0
  pushl $46
f0100aab:	6a 2e                	push   $0x2e
  jmp alltraps
f0100aad:	e9 44 fe ff ff       	jmp    f01008f6 <alltraps>

f0100ab2 <vector47>:
.globl vector47
vector47:
  pushl $0
f0100ab2:	6a 00                	push   $0x0
  pushl $47
f0100ab4:	6a 2f                	push   $0x2f
  jmp alltraps
f0100ab6:	e9 3b fe ff ff       	jmp    f01008f6 <alltraps>

f0100abb <vector48>:
.globl vector48
vector48:
  pushl $0
f0100abb:	6a 00                	push   $0x0
  pushl $48
f0100abd:	6a 30                	push   $0x30
  jmp alltraps
f0100abf:	e9 32 fe ff ff       	jmp    f01008f6 <alltraps>

f0100ac4 <vector49>:
.globl vector49
vector49:
  pushl $0
f0100ac4:	6a 00                	push   $0x0
  pushl $49
f0100ac6:	6a 31                	push   $0x31
  jmp alltraps
f0100ac8:	e9 29 fe ff ff       	jmp    f01008f6 <alltraps>

f0100acd <vector50>:
.globl vector50
vector50:
  pushl $0
f0100acd:	6a 00                	push   $0x0
  pushl $50
f0100acf:	6a 32                	push   $0x32
  jmp alltraps
f0100ad1:	e9 20 fe ff ff       	jmp    f01008f6 <alltraps>

f0100ad6 <vector51>:
.globl vector51
vector51:
  pushl $0
f0100ad6:	6a 00                	push   $0x0
  pushl $51
f0100ad8:	6a 33                	push   $0x33
  jmp alltraps
f0100ada:	e9 17 fe ff ff       	jmp    f01008f6 <alltraps>

f0100adf <vector52>:
.globl vector52
vector52:
  pushl $0
f0100adf:	6a 00                	push   $0x0
  pushl $52
f0100ae1:	6a 34                	push   $0x34
  jmp alltraps
f0100ae3:	e9 0e fe ff ff       	jmp    f01008f6 <alltraps>

f0100ae8 <vector53>:
.globl vector53
vector53:
  pushl $0
f0100ae8:	6a 00                	push   $0x0
  pushl $53
f0100aea:	6a 35                	push   $0x35
  jmp alltraps
f0100aec:	e9 05 fe ff ff       	jmp    f01008f6 <alltraps>

f0100af1 <vector54>:
.globl vector54
vector54:
  pushl $0
f0100af1:	6a 00                	push   $0x0
  pushl $54
f0100af3:	6a 36                	push   $0x36
  jmp alltraps
f0100af5:	e9 fc fd ff ff       	jmp    f01008f6 <alltraps>

f0100afa <vector55>:
.globl vector55
vector55:
  pushl $0
f0100afa:	6a 00                	push   $0x0
  pushl $55
f0100afc:	6a 37                	push   $0x37
  jmp alltraps
f0100afe:	e9 f3 fd ff ff       	jmp    f01008f6 <alltraps>

f0100b03 <vector56>:
.globl vector56
vector56:
  pushl $0
f0100b03:	6a 00                	push   $0x0
  pushl $56
f0100b05:	6a 38                	push   $0x38
  jmp alltraps
f0100b07:	e9 ea fd ff ff       	jmp    f01008f6 <alltraps>

f0100b0c <vector57>:
.globl vector57
vector57:
  pushl $0
f0100b0c:	6a 00                	push   $0x0
  pushl $57
f0100b0e:	6a 39                	push   $0x39
  jmp alltraps
f0100b10:	e9 e1 fd ff ff       	jmp    f01008f6 <alltraps>

f0100b15 <vector58>:
.globl vector58
vector58:
  pushl $0
f0100b15:	6a 00                	push   $0x0
  pushl $58
f0100b17:	6a 3a                	push   $0x3a
  jmp alltraps
f0100b19:	e9 d8 fd ff ff       	jmp    f01008f6 <alltraps>

f0100b1e <vector59>:
.globl vector59
vector59:
  pushl $0
f0100b1e:	6a 00                	push   $0x0
  pushl $59
f0100b20:	6a 3b                	push   $0x3b
  jmp alltraps
f0100b22:	e9 cf fd ff ff       	jmp    f01008f6 <alltraps>

f0100b27 <vector60>:
.globl vector60
vector60:
  pushl $0
f0100b27:	6a 00                	push   $0x0
  pushl $60
f0100b29:	6a 3c                	push   $0x3c
  jmp alltraps
f0100b2b:	e9 c6 fd ff ff       	jmp    f01008f6 <alltraps>

f0100b30 <vector61>:
.globl vector61
vector61:
  pushl $0
f0100b30:	6a 00                	push   $0x0
  pushl $61
f0100b32:	6a 3d                	push   $0x3d
  jmp alltraps
f0100b34:	e9 bd fd ff ff       	jmp    f01008f6 <alltraps>

f0100b39 <vector62>:
.globl vector62
vector62:
  pushl $0
f0100b39:	6a 00                	push   $0x0
  pushl $62
f0100b3b:	6a 3e                	push   $0x3e
  jmp alltraps
f0100b3d:	e9 b4 fd ff ff       	jmp    f01008f6 <alltraps>

f0100b42 <vector63>:
.globl vector63
vector63:
  pushl $0
f0100b42:	6a 00                	push   $0x0
  pushl $63
f0100b44:	6a 3f                	push   $0x3f
  jmp alltraps
f0100b46:	e9 ab fd ff ff       	jmp    f01008f6 <alltraps>

f0100b4b <vector64>:
.globl vector64
vector64:
  pushl $0
f0100b4b:	6a 00                	push   $0x0
  pushl $64
f0100b4d:	6a 40                	push   $0x40
  jmp alltraps
f0100b4f:	e9 a2 fd ff ff       	jmp    f01008f6 <alltraps>

f0100b54 <vector65>:
.globl vector65
vector65:
  pushl $0
f0100b54:	6a 00                	push   $0x0
  pushl $65
f0100b56:	6a 41                	push   $0x41
  jmp alltraps
f0100b58:	e9 99 fd ff ff       	jmp    f01008f6 <alltraps>

f0100b5d <vector66>:
.globl vector66
vector66:
  pushl $0
f0100b5d:	6a 00                	push   $0x0
  pushl $66
f0100b5f:	6a 42                	push   $0x42
  jmp alltraps
f0100b61:	e9 90 fd ff ff       	jmp    f01008f6 <alltraps>

f0100b66 <vector67>:
.globl vector67
vector67:
  pushl $0
f0100b66:	6a 00                	push   $0x0
  pushl $67
f0100b68:	6a 43                	push   $0x43
  jmp alltraps
f0100b6a:	e9 87 fd ff ff       	jmp    f01008f6 <alltraps>

f0100b6f <vector68>:
.globl vector68
vector68:
  pushl $0
f0100b6f:	6a 00                	push   $0x0
  pushl $68
f0100b71:	6a 44                	push   $0x44
  jmp alltraps
f0100b73:	e9 7e fd ff ff       	jmp    f01008f6 <alltraps>

f0100b78 <vector69>:
.globl vector69
vector69:
  pushl $0
f0100b78:	6a 00                	push   $0x0
  pushl $69
f0100b7a:	6a 45                	push   $0x45
  jmp alltraps
f0100b7c:	e9 75 fd ff ff       	jmp    f01008f6 <alltraps>

f0100b81 <vector70>:
.globl vector70
vector70:
  pushl $0
f0100b81:	6a 00                	push   $0x0
  pushl $70
f0100b83:	6a 46                	push   $0x46
  jmp alltraps
f0100b85:	e9 6c fd ff ff       	jmp    f01008f6 <alltraps>

f0100b8a <vector71>:
.globl vector71
vector71:
  pushl $0
f0100b8a:	6a 00                	push   $0x0
  pushl $71
f0100b8c:	6a 47                	push   $0x47
  jmp alltraps
f0100b8e:	e9 63 fd ff ff       	jmp    f01008f6 <alltraps>

f0100b93 <vector72>:
.globl vector72
vector72:
  pushl $0
f0100b93:	6a 00                	push   $0x0
  pushl $72
f0100b95:	6a 48                	push   $0x48
  jmp alltraps
f0100b97:	e9 5a fd ff ff       	jmp    f01008f6 <alltraps>

f0100b9c <vector73>:
.globl vector73
vector73:
  pushl $0
f0100b9c:	6a 00                	push   $0x0
  pushl $73
f0100b9e:	6a 49                	push   $0x49
  jmp alltraps
f0100ba0:	e9 51 fd ff ff       	jmp    f01008f6 <alltraps>

f0100ba5 <vector74>:
.globl vector74
vector74:
  pushl $0
f0100ba5:	6a 00                	push   $0x0
  pushl $74
f0100ba7:	6a 4a                	push   $0x4a
  jmp alltraps
f0100ba9:	e9 48 fd ff ff       	jmp    f01008f6 <alltraps>

f0100bae <vector75>:
.globl vector75
vector75:
  pushl $0
f0100bae:	6a 00                	push   $0x0
  pushl $75
f0100bb0:	6a 4b                	push   $0x4b
  jmp alltraps
f0100bb2:	e9 3f fd ff ff       	jmp    f01008f6 <alltraps>

f0100bb7 <vector76>:
.globl vector76
vector76:
  pushl $0
f0100bb7:	6a 00                	push   $0x0
  pushl $76
f0100bb9:	6a 4c                	push   $0x4c
  jmp alltraps
f0100bbb:	e9 36 fd ff ff       	jmp    f01008f6 <alltraps>

f0100bc0 <vector77>:
.globl vector77
vector77:
  pushl $0
f0100bc0:	6a 00                	push   $0x0
  pushl $77
f0100bc2:	6a 4d                	push   $0x4d
  jmp alltraps
f0100bc4:	e9 2d fd ff ff       	jmp    f01008f6 <alltraps>

f0100bc9 <vector78>:
.globl vector78
vector78:
  pushl $0
f0100bc9:	6a 00                	push   $0x0
  pushl $78
f0100bcb:	6a 4e                	push   $0x4e
  jmp alltraps
f0100bcd:	e9 24 fd ff ff       	jmp    f01008f6 <alltraps>

f0100bd2 <vector79>:
.globl vector79
vector79:
  pushl $0
f0100bd2:	6a 00                	push   $0x0
  pushl $79
f0100bd4:	6a 4f                	push   $0x4f
  jmp alltraps
f0100bd6:	e9 1b fd ff ff       	jmp    f01008f6 <alltraps>

f0100bdb <vector80>:
.globl vector80
vector80:
  pushl $0
f0100bdb:	6a 00                	push   $0x0
  pushl $80
f0100bdd:	6a 50                	push   $0x50
  jmp alltraps
f0100bdf:	e9 12 fd ff ff       	jmp    f01008f6 <alltraps>

f0100be4 <vector81>:
.globl vector81
vector81:
  pushl $0
f0100be4:	6a 00                	push   $0x0
  pushl $81
f0100be6:	6a 51                	push   $0x51
  jmp alltraps
f0100be8:	e9 09 fd ff ff       	jmp    f01008f6 <alltraps>

f0100bed <vector82>:
.globl vector82
vector82:
  pushl $0
f0100bed:	6a 00                	push   $0x0
  pushl $82
f0100bef:	6a 52                	push   $0x52
  jmp alltraps
f0100bf1:	e9 00 fd ff ff       	jmp    f01008f6 <alltraps>

f0100bf6 <vector83>:
.globl vector83
vector83:
  pushl $0
f0100bf6:	6a 00                	push   $0x0
  pushl $83
f0100bf8:	6a 53                	push   $0x53
  jmp alltraps
f0100bfa:	e9 f7 fc ff ff       	jmp    f01008f6 <alltraps>

f0100bff <vector84>:
.globl vector84
vector84:
  pushl $0
f0100bff:	6a 00                	push   $0x0
  pushl $84
f0100c01:	6a 54                	push   $0x54
  jmp alltraps
f0100c03:	e9 ee fc ff ff       	jmp    f01008f6 <alltraps>

f0100c08 <vector85>:
.globl vector85
vector85:
  pushl $0
f0100c08:	6a 00                	push   $0x0
  pushl $85
f0100c0a:	6a 55                	push   $0x55
  jmp alltraps
f0100c0c:	e9 e5 fc ff ff       	jmp    f01008f6 <alltraps>

f0100c11 <vector86>:
.globl vector86
vector86:
  pushl $0
f0100c11:	6a 00                	push   $0x0
  pushl $86
f0100c13:	6a 56                	push   $0x56
  jmp alltraps
f0100c15:	e9 dc fc ff ff       	jmp    f01008f6 <alltraps>

f0100c1a <vector87>:
.globl vector87
vector87:
  pushl $0
f0100c1a:	6a 00                	push   $0x0
  pushl $87
f0100c1c:	6a 57                	push   $0x57
  jmp alltraps
f0100c1e:	e9 d3 fc ff ff       	jmp    f01008f6 <alltraps>

f0100c23 <vector88>:
.globl vector88
vector88:
  pushl $0
f0100c23:	6a 00                	push   $0x0
  pushl $88
f0100c25:	6a 58                	push   $0x58
  jmp alltraps
f0100c27:	e9 ca fc ff ff       	jmp    f01008f6 <alltraps>

f0100c2c <vector89>:
.globl vector89
vector89:
  pushl $0
f0100c2c:	6a 00                	push   $0x0
  pushl $89
f0100c2e:	6a 59                	push   $0x59
  jmp alltraps
f0100c30:	e9 c1 fc ff ff       	jmp    f01008f6 <alltraps>

f0100c35 <vector90>:
.globl vector90
vector90:
  pushl $0
f0100c35:	6a 00                	push   $0x0
  pushl $90
f0100c37:	6a 5a                	push   $0x5a
  jmp alltraps
f0100c39:	e9 b8 fc ff ff       	jmp    f01008f6 <alltraps>

f0100c3e <vector91>:
.globl vector91
vector91:
  pushl $0
f0100c3e:	6a 00                	push   $0x0
  pushl $91
f0100c40:	6a 5b                	push   $0x5b
  jmp alltraps
f0100c42:	e9 af fc ff ff       	jmp    f01008f6 <alltraps>

f0100c47 <vector92>:
.globl vector92
vector92:
  pushl $0
f0100c47:	6a 00                	push   $0x0
  pushl $92
f0100c49:	6a 5c                	push   $0x5c
  jmp alltraps
f0100c4b:	e9 a6 fc ff ff       	jmp    f01008f6 <alltraps>

f0100c50 <vector93>:
.globl vector93
vector93:
  pushl $0
f0100c50:	6a 00                	push   $0x0
  pushl $93
f0100c52:	6a 5d                	push   $0x5d
  jmp alltraps
f0100c54:	e9 9d fc ff ff       	jmp    f01008f6 <alltraps>

f0100c59 <vector94>:
.globl vector94
vector94:
  pushl $0
f0100c59:	6a 00                	push   $0x0
  pushl $94
f0100c5b:	6a 5e                	push   $0x5e
  jmp alltraps
f0100c5d:	e9 94 fc ff ff       	jmp    f01008f6 <alltraps>

f0100c62 <vector95>:
.globl vector95
vector95:
  pushl $0
f0100c62:	6a 00                	push   $0x0
  pushl $95
f0100c64:	6a 5f                	push   $0x5f
  jmp alltraps
f0100c66:	e9 8b fc ff ff       	jmp    f01008f6 <alltraps>

f0100c6b <vector96>:
.globl vector96
vector96:
  pushl $0
f0100c6b:	6a 00                	push   $0x0
  pushl $96
f0100c6d:	6a 60                	push   $0x60
  jmp alltraps
f0100c6f:	e9 82 fc ff ff       	jmp    f01008f6 <alltraps>

f0100c74 <vector97>:
.globl vector97
vector97:
  pushl $0
f0100c74:	6a 00                	push   $0x0
  pushl $97
f0100c76:	6a 61                	push   $0x61
  jmp alltraps
f0100c78:	e9 79 fc ff ff       	jmp    f01008f6 <alltraps>

f0100c7d <vector98>:
.globl vector98
vector98:
  pushl $0
f0100c7d:	6a 00                	push   $0x0
  pushl $98
f0100c7f:	6a 62                	push   $0x62
  jmp alltraps
f0100c81:	e9 70 fc ff ff       	jmp    f01008f6 <alltraps>

f0100c86 <vector99>:
.globl vector99
vector99:
  pushl $0
f0100c86:	6a 00                	push   $0x0
  pushl $99
f0100c88:	6a 63                	push   $0x63
  jmp alltraps
f0100c8a:	e9 67 fc ff ff       	jmp    f01008f6 <alltraps>

f0100c8f <vector100>:
.globl vector100
vector100:
  pushl $0
f0100c8f:	6a 00                	push   $0x0
  pushl $100
f0100c91:	6a 64                	push   $0x64
  jmp alltraps
f0100c93:	e9 5e fc ff ff       	jmp    f01008f6 <alltraps>

f0100c98 <vector101>:
.globl vector101
vector101:
  pushl $0
f0100c98:	6a 00                	push   $0x0
  pushl $101
f0100c9a:	6a 65                	push   $0x65
  jmp alltraps
f0100c9c:	e9 55 fc ff ff       	jmp    f01008f6 <alltraps>

f0100ca1 <vector102>:
.globl vector102
vector102:
  pushl $0
f0100ca1:	6a 00                	push   $0x0
  pushl $102
f0100ca3:	6a 66                	push   $0x66
  jmp alltraps
f0100ca5:	e9 4c fc ff ff       	jmp    f01008f6 <alltraps>

f0100caa <vector103>:
.globl vector103
vector103:
  pushl $0
f0100caa:	6a 00                	push   $0x0
  pushl $103
f0100cac:	6a 67                	push   $0x67
  jmp alltraps
f0100cae:	e9 43 fc ff ff       	jmp    f01008f6 <alltraps>

f0100cb3 <vector104>:
.globl vector104
vector104:
  pushl $0
f0100cb3:	6a 00                	push   $0x0
  pushl $104
f0100cb5:	6a 68                	push   $0x68
  jmp alltraps
f0100cb7:	e9 3a fc ff ff       	jmp    f01008f6 <alltraps>

f0100cbc <vector105>:
.globl vector105
vector105:
  pushl $0
f0100cbc:	6a 00                	push   $0x0
  pushl $105
f0100cbe:	6a 69                	push   $0x69
  jmp alltraps
f0100cc0:	e9 31 fc ff ff       	jmp    f01008f6 <alltraps>

f0100cc5 <vector106>:
.globl vector106
vector106:
  pushl $0
f0100cc5:	6a 00                	push   $0x0
  pushl $106
f0100cc7:	6a 6a                	push   $0x6a
  jmp alltraps
f0100cc9:	e9 28 fc ff ff       	jmp    f01008f6 <alltraps>

f0100cce <vector107>:
.globl vector107
vector107:
  pushl $0
f0100cce:	6a 00                	push   $0x0
  pushl $107
f0100cd0:	6a 6b                	push   $0x6b
  jmp alltraps
f0100cd2:	e9 1f fc ff ff       	jmp    f01008f6 <alltraps>

f0100cd7 <vector108>:
.globl vector108
vector108:
  pushl $0
f0100cd7:	6a 00                	push   $0x0
  pushl $108
f0100cd9:	6a 6c                	push   $0x6c
  jmp alltraps
f0100cdb:	e9 16 fc ff ff       	jmp    f01008f6 <alltraps>

f0100ce0 <vector109>:
.globl vector109
vector109:
  pushl $0
f0100ce0:	6a 00                	push   $0x0
  pushl $109
f0100ce2:	6a 6d                	push   $0x6d
  jmp alltraps
f0100ce4:	e9 0d fc ff ff       	jmp    f01008f6 <alltraps>

f0100ce9 <vector110>:
.globl vector110
vector110:
  pushl $0
f0100ce9:	6a 00                	push   $0x0
  pushl $110
f0100ceb:	6a 6e                	push   $0x6e
  jmp alltraps
f0100ced:	e9 04 fc ff ff       	jmp    f01008f6 <alltraps>

f0100cf2 <vector111>:
.globl vector111
vector111:
  pushl $0
f0100cf2:	6a 00                	push   $0x0
  pushl $111
f0100cf4:	6a 6f                	push   $0x6f
  jmp alltraps
f0100cf6:	e9 fb fb ff ff       	jmp    f01008f6 <alltraps>

f0100cfb <vector112>:
.globl vector112
vector112:
  pushl $0
f0100cfb:	6a 00                	push   $0x0
  pushl $112
f0100cfd:	6a 70                	push   $0x70
  jmp alltraps
f0100cff:	e9 f2 fb ff ff       	jmp    f01008f6 <alltraps>

f0100d04 <vector113>:
.globl vector113
vector113:
  pushl $0
f0100d04:	6a 00                	push   $0x0
  pushl $113
f0100d06:	6a 71                	push   $0x71
  jmp alltraps
f0100d08:	e9 e9 fb ff ff       	jmp    f01008f6 <alltraps>

f0100d0d <vector114>:
.globl vector114
vector114:
  pushl $0
f0100d0d:	6a 00                	push   $0x0
  pushl $114
f0100d0f:	6a 72                	push   $0x72
  jmp alltraps
f0100d11:	e9 e0 fb ff ff       	jmp    f01008f6 <alltraps>

f0100d16 <vector115>:
.globl vector115
vector115:
  pushl $0
f0100d16:	6a 00                	push   $0x0
  pushl $115
f0100d18:	6a 73                	push   $0x73
  jmp alltraps
f0100d1a:	e9 d7 fb ff ff       	jmp    f01008f6 <alltraps>

f0100d1f <vector116>:
.globl vector116
vector116:
  pushl $0
f0100d1f:	6a 00                	push   $0x0
  pushl $116
f0100d21:	6a 74                	push   $0x74
  jmp alltraps
f0100d23:	e9 ce fb ff ff       	jmp    f01008f6 <alltraps>

f0100d28 <vector117>:
.globl vector117
vector117:
  pushl $0
f0100d28:	6a 00                	push   $0x0
  pushl $117
f0100d2a:	6a 75                	push   $0x75
  jmp alltraps
f0100d2c:	e9 c5 fb ff ff       	jmp    f01008f6 <alltraps>

f0100d31 <vector118>:
.globl vector118
vector118:
  pushl $0
f0100d31:	6a 00                	push   $0x0
  pushl $118
f0100d33:	6a 76                	push   $0x76
  jmp alltraps
f0100d35:	e9 bc fb ff ff       	jmp    f01008f6 <alltraps>

f0100d3a <vector119>:
.globl vector119
vector119:
  pushl $0
f0100d3a:	6a 00                	push   $0x0
  pushl $119
f0100d3c:	6a 77                	push   $0x77
  jmp alltraps
f0100d3e:	e9 b3 fb ff ff       	jmp    f01008f6 <alltraps>

f0100d43 <vector120>:
.globl vector120
vector120:
  pushl $0
f0100d43:	6a 00                	push   $0x0
  pushl $120
f0100d45:	6a 78                	push   $0x78
  jmp alltraps
f0100d47:	e9 aa fb ff ff       	jmp    f01008f6 <alltraps>

f0100d4c <vector121>:
.globl vector121
vector121:
  pushl $0
f0100d4c:	6a 00                	push   $0x0
  pushl $121
f0100d4e:	6a 79                	push   $0x79
  jmp alltraps
f0100d50:	e9 a1 fb ff ff       	jmp    f01008f6 <alltraps>

f0100d55 <vector122>:
.globl vector122
vector122:
  pushl $0
f0100d55:	6a 00                	push   $0x0
  pushl $122
f0100d57:	6a 7a                	push   $0x7a
  jmp alltraps
f0100d59:	e9 98 fb ff ff       	jmp    f01008f6 <alltraps>

f0100d5e <vector123>:
.globl vector123
vector123:
  pushl $0
f0100d5e:	6a 00                	push   $0x0
  pushl $123
f0100d60:	6a 7b                	push   $0x7b
  jmp alltraps
f0100d62:	e9 8f fb ff ff       	jmp    f01008f6 <alltraps>

f0100d67 <vector124>:
.globl vector124
vector124:
  pushl $0
f0100d67:	6a 00                	push   $0x0
  pushl $124
f0100d69:	6a 7c                	push   $0x7c
  jmp alltraps
f0100d6b:	e9 86 fb ff ff       	jmp    f01008f6 <alltraps>

f0100d70 <vector125>:
.globl vector125
vector125:
  pushl $0
f0100d70:	6a 00                	push   $0x0
  pushl $125
f0100d72:	6a 7d                	push   $0x7d
  jmp alltraps
f0100d74:	e9 7d fb ff ff       	jmp    f01008f6 <alltraps>

f0100d79 <vector126>:
.globl vector126
vector126:
  pushl $0
f0100d79:	6a 00                	push   $0x0
  pushl $126
f0100d7b:	6a 7e                	push   $0x7e
  jmp alltraps
f0100d7d:	e9 74 fb ff ff       	jmp    f01008f6 <alltraps>

f0100d82 <vector127>:
.globl vector127
vector127:
  pushl $0
f0100d82:	6a 00                	push   $0x0
  pushl $127
f0100d84:	6a 7f                	push   $0x7f
  jmp alltraps
f0100d86:	e9 6b fb ff ff       	jmp    f01008f6 <alltraps>

f0100d8b <vector128>:
.globl vector128
vector128:
  pushl $0
f0100d8b:	6a 00                	push   $0x0
  pushl $128
f0100d8d:	68 80 00 00 00       	push   $0x80
  jmp alltraps
f0100d92:	e9 5f fb ff ff       	jmp    f01008f6 <alltraps>

f0100d97 <vector129>:
.globl vector129
vector129:
  pushl $0
f0100d97:	6a 00                	push   $0x0
  pushl $129
f0100d99:	68 81 00 00 00       	push   $0x81
  jmp alltraps
f0100d9e:	e9 53 fb ff ff       	jmp    f01008f6 <alltraps>

f0100da3 <vector130>:
.globl vector130
vector130:
  pushl $0
f0100da3:	6a 00                	push   $0x0
  pushl $130
f0100da5:	68 82 00 00 00       	push   $0x82
  jmp alltraps
f0100daa:	e9 47 fb ff ff       	jmp    f01008f6 <alltraps>

f0100daf <vector131>:
.globl vector131
vector131:
  pushl $0
f0100daf:	6a 00                	push   $0x0
  pushl $131
f0100db1:	68 83 00 00 00       	push   $0x83
  jmp alltraps
f0100db6:	e9 3b fb ff ff       	jmp    f01008f6 <alltraps>

f0100dbb <vector132>:
.globl vector132
vector132:
  pushl $0
f0100dbb:	6a 00                	push   $0x0
  pushl $132
f0100dbd:	68 84 00 00 00       	push   $0x84
  jmp alltraps
f0100dc2:	e9 2f fb ff ff       	jmp    f01008f6 <alltraps>

f0100dc7 <vector133>:
.globl vector133
vector133:
  pushl $0
f0100dc7:	6a 00                	push   $0x0
  pushl $133
f0100dc9:	68 85 00 00 00       	push   $0x85
  jmp alltraps
f0100dce:	e9 23 fb ff ff       	jmp    f01008f6 <alltraps>

f0100dd3 <vector134>:
.globl vector134
vector134:
  pushl $0
f0100dd3:	6a 00                	push   $0x0
  pushl $134
f0100dd5:	68 86 00 00 00       	push   $0x86
  jmp alltraps
f0100dda:	e9 17 fb ff ff       	jmp    f01008f6 <alltraps>

f0100ddf <vector135>:
.globl vector135
vector135:
  pushl $0
f0100ddf:	6a 00                	push   $0x0
  pushl $135
f0100de1:	68 87 00 00 00       	push   $0x87
  jmp alltraps
f0100de6:	e9 0b fb ff ff       	jmp    f01008f6 <alltraps>

f0100deb <vector136>:
.globl vector136
vector136:
  pushl $0
f0100deb:	6a 00                	push   $0x0
  pushl $136
f0100ded:	68 88 00 00 00       	push   $0x88
  jmp alltraps
f0100df2:	e9 ff fa ff ff       	jmp    f01008f6 <alltraps>

f0100df7 <vector137>:
.globl vector137
vector137:
  pushl $0
f0100df7:	6a 00                	push   $0x0
  pushl $137
f0100df9:	68 89 00 00 00       	push   $0x89
  jmp alltraps
f0100dfe:	e9 f3 fa ff ff       	jmp    f01008f6 <alltraps>

f0100e03 <vector138>:
.globl vector138
vector138:
  pushl $0
f0100e03:	6a 00                	push   $0x0
  pushl $138
f0100e05:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
f0100e0a:	e9 e7 fa ff ff       	jmp    f01008f6 <alltraps>

f0100e0f <vector139>:
.globl vector139
vector139:
  pushl $0
f0100e0f:	6a 00                	push   $0x0
  pushl $139
f0100e11:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
f0100e16:	e9 db fa ff ff       	jmp    f01008f6 <alltraps>

f0100e1b <vector140>:
.globl vector140
vector140:
  pushl $0
f0100e1b:	6a 00                	push   $0x0
  pushl $140
f0100e1d:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
f0100e22:	e9 cf fa ff ff       	jmp    f01008f6 <alltraps>

f0100e27 <vector141>:
.globl vector141
vector141:
  pushl $0
f0100e27:	6a 00                	push   $0x0
  pushl $141
f0100e29:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
f0100e2e:	e9 c3 fa ff ff       	jmp    f01008f6 <alltraps>

f0100e33 <vector142>:
.globl vector142
vector142:
  pushl $0
f0100e33:	6a 00                	push   $0x0
  pushl $142
f0100e35:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
f0100e3a:	e9 b7 fa ff ff       	jmp    f01008f6 <alltraps>

f0100e3f <vector143>:
.globl vector143
vector143:
  pushl $0
f0100e3f:	6a 00                	push   $0x0
  pushl $143
f0100e41:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
f0100e46:	e9 ab fa ff ff       	jmp    f01008f6 <alltraps>

f0100e4b <vector144>:
.globl vector144
vector144:
  pushl $0
f0100e4b:	6a 00                	push   $0x0
  pushl $144
f0100e4d:	68 90 00 00 00       	push   $0x90
  jmp alltraps
f0100e52:	e9 9f fa ff ff       	jmp    f01008f6 <alltraps>

f0100e57 <vector145>:
.globl vector145
vector145:
  pushl $0
f0100e57:	6a 00                	push   $0x0
  pushl $145
f0100e59:	68 91 00 00 00       	push   $0x91
  jmp alltraps
f0100e5e:	e9 93 fa ff ff       	jmp    f01008f6 <alltraps>

f0100e63 <vector146>:
.globl vector146
vector146:
  pushl $0
f0100e63:	6a 00                	push   $0x0
  pushl $146
f0100e65:	68 92 00 00 00       	push   $0x92
  jmp alltraps
f0100e6a:	e9 87 fa ff ff       	jmp    f01008f6 <alltraps>

f0100e6f <vector147>:
.globl vector147
vector147:
  pushl $0
f0100e6f:	6a 00                	push   $0x0
  pushl $147
f0100e71:	68 93 00 00 00       	push   $0x93
  jmp alltraps
f0100e76:	e9 7b fa ff ff       	jmp    f01008f6 <alltraps>

f0100e7b <vector148>:
.globl vector148
vector148:
  pushl $0
f0100e7b:	6a 00                	push   $0x0
  pushl $148
f0100e7d:	68 94 00 00 00       	push   $0x94
  jmp alltraps
f0100e82:	e9 6f fa ff ff       	jmp    f01008f6 <alltraps>

f0100e87 <vector149>:
.globl vector149
vector149:
  pushl $0
f0100e87:	6a 00                	push   $0x0
  pushl $149
f0100e89:	68 95 00 00 00       	push   $0x95
  jmp alltraps
f0100e8e:	e9 63 fa ff ff       	jmp    f01008f6 <alltraps>

f0100e93 <vector150>:
.globl vector150
vector150:
  pushl $0
f0100e93:	6a 00                	push   $0x0
  pushl $150
f0100e95:	68 96 00 00 00       	push   $0x96
  jmp alltraps
f0100e9a:	e9 57 fa ff ff       	jmp    f01008f6 <alltraps>

f0100e9f <vector151>:
.globl vector151
vector151:
  pushl $0
f0100e9f:	6a 00                	push   $0x0
  pushl $151
f0100ea1:	68 97 00 00 00       	push   $0x97
  jmp alltraps
f0100ea6:	e9 4b fa ff ff       	jmp    f01008f6 <alltraps>

f0100eab <vector152>:
.globl vector152
vector152:
  pushl $0
f0100eab:	6a 00                	push   $0x0
  pushl $152
f0100ead:	68 98 00 00 00       	push   $0x98
  jmp alltraps
f0100eb2:	e9 3f fa ff ff       	jmp    f01008f6 <alltraps>

f0100eb7 <vector153>:
.globl vector153
vector153:
  pushl $0
f0100eb7:	6a 00                	push   $0x0
  pushl $153
f0100eb9:	68 99 00 00 00       	push   $0x99
  jmp alltraps
f0100ebe:	e9 33 fa ff ff       	jmp    f01008f6 <alltraps>

f0100ec3 <vector154>:
.globl vector154
vector154:
  pushl $0
f0100ec3:	6a 00                	push   $0x0
  pushl $154
f0100ec5:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
f0100eca:	e9 27 fa ff ff       	jmp    f01008f6 <alltraps>

f0100ecf <vector155>:
.globl vector155
vector155:
  pushl $0
f0100ecf:	6a 00                	push   $0x0
  pushl $155
f0100ed1:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
f0100ed6:	e9 1b fa ff ff       	jmp    f01008f6 <alltraps>

f0100edb <vector156>:
.globl vector156
vector156:
  pushl $0
f0100edb:	6a 00                	push   $0x0
  pushl $156
f0100edd:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
f0100ee2:	e9 0f fa ff ff       	jmp    f01008f6 <alltraps>

f0100ee7 <vector157>:
.globl vector157
vector157:
  pushl $0
f0100ee7:	6a 00                	push   $0x0
  pushl $157
f0100ee9:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
f0100eee:	e9 03 fa ff ff       	jmp    f01008f6 <alltraps>

f0100ef3 <vector158>:
.globl vector158
vector158:
  pushl $0
f0100ef3:	6a 00                	push   $0x0
  pushl $158
f0100ef5:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
f0100efa:	e9 f7 f9 ff ff       	jmp    f01008f6 <alltraps>

f0100eff <vector159>:
.globl vector159
vector159:
  pushl $0
f0100eff:	6a 00                	push   $0x0
  pushl $159
f0100f01:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
f0100f06:	e9 eb f9 ff ff       	jmp    f01008f6 <alltraps>

f0100f0b <vector160>:
.globl vector160
vector160:
  pushl $0
f0100f0b:	6a 00                	push   $0x0
  pushl $160
f0100f0d:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
f0100f12:	e9 df f9 ff ff       	jmp    f01008f6 <alltraps>

f0100f17 <vector161>:
.globl vector161
vector161:
  pushl $0
f0100f17:	6a 00                	push   $0x0
  pushl $161
f0100f19:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
f0100f1e:	e9 d3 f9 ff ff       	jmp    f01008f6 <alltraps>

f0100f23 <vector162>:
.globl vector162
vector162:
  pushl $0
f0100f23:	6a 00                	push   $0x0
  pushl $162
f0100f25:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
f0100f2a:	e9 c7 f9 ff ff       	jmp    f01008f6 <alltraps>

f0100f2f <vector163>:
.globl vector163
vector163:
  pushl $0
f0100f2f:	6a 00                	push   $0x0
  pushl $163
f0100f31:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
f0100f36:	e9 bb f9 ff ff       	jmp    f01008f6 <alltraps>

f0100f3b <vector164>:
.globl vector164
vector164:
  pushl $0
f0100f3b:	6a 00                	push   $0x0
  pushl $164
f0100f3d:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
f0100f42:	e9 af f9 ff ff       	jmp    f01008f6 <alltraps>

f0100f47 <vector165>:
.globl vector165
vector165:
  pushl $0
f0100f47:	6a 00                	push   $0x0
  pushl $165
f0100f49:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
f0100f4e:	e9 a3 f9 ff ff       	jmp    f01008f6 <alltraps>

f0100f53 <vector166>:
.globl vector166
vector166:
  pushl $0
f0100f53:	6a 00                	push   $0x0
  pushl $166
f0100f55:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
f0100f5a:	e9 97 f9 ff ff       	jmp    f01008f6 <alltraps>

f0100f5f <vector167>:
.globl vector167
vector167:
  pushl $0
f0100f5f:	6a 00                	push   $0x0
  pushl $167
f0100f61:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
f0100f66:	e9 8b f9 ff ff       	jmp    f01008f6 <alltraps>

f0100f6b <vector168>:
.globl vector168
vector168:
  pushl $0
f0100f6b:	6a 00                	push   $0x0
  pushl $168
f0100f6d:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
f0100f72:	e9 7f f9 ff ff       	jmp    f01008f6 <alltraps>

f0100f77 <vector169>:
.globl vector169
vector169:
  pushl $0
f0100f77:	6a 00                	push   $0x0
  pushl $169
f0100f79:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
f0100f7e:	e9 73 f9 ff ff       	jmp    f01008f6 <alltraps>

f0100f83 <vector170>:
.globl vector170
vector170:
  pushl $0
f0100f83:	6a 00                	push   $0x0
  pushl $170
f0100f85:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
f0100f8a:	e9 67 f9 ff ff       	jmp    f01008f6 <alltraps>

f0100f8f <vector171>:
.globl vector171
vector171:
  pushl $0
f0100f8f:	6a 00                	push   $0x0
  pushl $171
f0100f91:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
f0100f96:	e9 5b f9 ff ff       	jmp    f01008f6 <alltraps>

f0100f9b <vector172>:
.globl vector172
vector172:
  pushl $0
f0100f9b:	6a 00                	push   $0x0
  pushl $172
f0100f9d:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
f0100fa2:	e9 4f f9 ff ff       	jmp    f01008f6 <alltraps>

f0100fa7 <vector173>:
.globl vector173
vector173:
  pushl $0
f0100fa7:	6a 00                	push   $0x0
  pushl $173
f0100fa9:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
f0100fae:	e9 43 f9 ff ff       	jmp    f01008f6 <alltraps>

f0100fb3 <vector174>:
.globl vector174
vector174:
  pushl $0
f0100fb3:	6a 00                	push   $0x0
  pushl $174
f0100fb5:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
f0100fba:	e9 37 f9 ff ff       	jmp    f01008f6 <alltraps>

f0100fbf <vector175>:
.globl vector175
vector175:
  pushl $0
f0100fbf:	6a 00                	push   $0x0
  pushl $175
f0100fc1:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
f0100fc6:	e9 2b f9 ff ff       	jmp    f01008f6 <alltraps>

f0100fcb <vector176>:
.globl vector176
vector176:
  pushl $0
f0100fcb:	6a 00                	push   $0x0
  pushl $176
f0100fcd:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
f0100fd2:	e9 1f f9 ff ff       	jmp    f01008f6 <alltraps>

f0100fd7 <vector177>:
.globl vector177
vector177:
  pushl $0
f0100fd7:	6a 00                	push   $0x0
  pushl $177
f0100fd9:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
f0100fde:	e9 13 f9 ff ff       	jmp    f01008f6 <alltraps>

f0100fe3 <vector178>:
.globl vector178
vector178:
  pushl $0
f0100fe3:	6a 00                	push   $0x0
  pushl $178
f0100fe5:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
f0100fea:	e9 07 f9 ff ff       	jmp    f01008f6 <alltraps>

f0100fef <vector179>:
.globl vector179
vector179:
  pushl $0
f0100fef:	6a 00                	push   $0x0
  pushl $179
f0100ff1:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
f0100ff6:	e9 fb f8 ff ff       	jmp    f01008f6 <alltraps>

f0100ffb <vector180>:
.globl vector180
vector180:
  pushl $0
f0100ffb:	6a 00                	push   $0x0
  pushl $180
f0100ffd:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
f0101002:	e9 ef f8 ff ff       	jmp    f01008f6 <alltraps>

f0101007 <vector181>:
.globl vector181
vector181:
  pushl $0
f0101007:	6a 00                	push   $0x0
  pushl $181
f0101009:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
f010100e:	e9 e3 f8 ff ff       	jmp    f01008f6 <alltraps>

f0101013 <vector182>:
.globl vector182
vector182:
  pushl $0
f0101013:	6a 00                	push   $0x0
  pushl $182
f0101015:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
f010101a:	e9 d7 f8 ff ff       	jmp    f01008f6 <alltraps>

f010101f <vector183>:
.globl vector183
vector183:
  pushl $0
f010101f:	6a 00                	push   $0x0
  pushl $183
f0101021:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
f0101026:	e9 cb f8 ff ff       	jmp    f01008f6 <alltraps>

f010102b <vector184>:
.globl vector184
vector184:
  pushl $0
f010102b:	6a 00                	push   $0x0
  pushl $184
f010102d:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
f0101032:	e9 bf f8 ff ff       	jmp    f01008f6 <alltraps>

f0101037 <vector185>:
.globl vector185
vector185:
  pushl $0
f0101037:	6a 00                	push   $0x0
  pushl $185
f0101039:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
f010103e:	e9 b3 f8 ff ff       	jmp    f01008f6 <alltraps>

f0101043 <vector186>:
.globl vector186
vector186:
  pushl $0
f0101043:	6a 00                	push   $0x0
  pushl $186
f0101045:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
f010104a:	e9 a7 f8 ff ff       	jmp    f01008f6 <alltraps>

f010104f <vector187>:
.globl vector187
vector187:
  pushl $0
f010104f:	6a 00                	push   $0x0
  pushl $187
f0101051:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
f0101056:	e9 9b f8 ff ff       	jmp    f01008f6 <alltraps>

f010105b <vector188>:
.globl vector188
vector188:
  pushl $0
f010105b:	6a 00                	push   $0x0
  pushl $188
f010105d:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
f0101062:	e9 8f f8 ff ff       	jmp    f01008f6 <alltraps>

f0101067 <vector189>:
.globl vector189
vector189:
  pushl $0
f0101067:	6a 00                	push   $0x0
  pushl $189
f0101069:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
f010106e:	e9 83 f8 ff ff       	jmp    f01008f6 <alltraps>

f0101073 <vector190>:
.globl vector190
vector190:
  pushl $0
f0101073:	6a 00                	push   $0x0
  pushl $190
f0101075:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
f010107a:	e9 77 f8 ff ff       	jmp    f01008f6 <alltraps>

f010107f <vector191>:
.globl vector191
vector191:
  pushl $0
f010107f:	6a 00                	push   $0x0
  pushl $191
f0101081:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
f0101086:	e9 6b f8 ff ff       	jmp    f01008f6 <alltraps>

f010108b <vector192>:
.globl vector192
vector192:
  pushl $0
f010108b:	6a 00                	push   $0x0
  pushl $192
f010108d:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
f0101092:	e9 5f f8 ff ff       	jmp    f01008f6 <alltraps>

f0101097 <vector193>:
.globl vector193
vector193:
  pushl $0
f0101097:	6a 00                	push   $0x0
  pushl $193
f0101099:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
f010109e:	e9 53 f8 ff ff       	jmp    f01008f6 <alltraps>

f01010a3 <vector194>:
.globl vector194
vector194:
  pushl $0
f01010a3:	6a 00                	push   $0x0
  pushl $194
f01010a5:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
f01010aa:	e9 47 f8 ff ff       	jmp    f01008f6 <alltraps>

f01010af <vector195>:
.globl vector195
vector195:
  pushl $0
f01010af:	6a 00                	push   $0x0
  pushl $195
f01010b1:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
f01010b6:	e9 3b f8 ff ff       	jmp    f01008f6 <alltraps>

f01010bb <vector196>:
.globl vector196
vector196:
  pushl $0
f01010bb:	6a 00                	push   $0x0
  pushl $196
f01010bd:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
f01010c2:	e9 2f f8 ff ff       	jmp    f01008f6 <alltraps>

f01010c7 <vector197>:
.globl vector197
vector197:
  pushl $0
f01010c7:	6a 00                	push   $0x0
  pushl $197
f01010c9:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
f01010ce:	e9 23 f8 ff ff       	jmp    f01008f6 <alltraps>

f01010d3 <vector198>:
.globl vector198
vector198:
  pushl $0
f01010d3:	6a 00                	push   $0x0
  pushl $198
f01010d5:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
f01010da:	e9 17 f8 ff ff       	jmp    f01008f6 <alltraps>

f01010df <vector199>:
.globl vector199
vector199:
  pushl $0
f01010df:	6a 00                	push   $0x0
  pushl $199
f01010e1:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
f01010e6:	e9 0b f8 ff ff       	jmp    f01008f6 <alltraps>

f01010eb <vector200>:
.globl vector200
vector200:
  pushl $0
f01010eb:	6a 00                	push   $0x0
  pushl $200
f01010ed:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
f01010f2:	e9 ff f7 ff ff       	jmp    f01008f6 <alltraps>

f01010f7 <vector201>:
.globl vector201
vector201:
  pushl $0
f01010f7:	6a 00                	push   $0x0
  pushl $201
f01010f9:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
f01010fe:	e9 f3 f7 ff ff       	jmp    f01008f6 <alltraps>

f0101103 <vector202>:
.globl vector202
vector202:
  pushl $0
f0101103:	6a 00                	push   $0x0
  pushl $202
f0101105:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
f010110a:	e9 e7 f7 ff ff       	jmp    f01008f6 <alltraps>

f010110f <vector203>:
.globl vector203
vector203:
  pushl $0
f010110f:	6a 00                	push   $0x0
  pushl $203
f0101111:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
f0101116:	e9 db f7 ff ff       	jmp    f01008f6 <alltraps>

f010111b <vector204>:
.globl vector204
vector204:
  pushl $0
f010111b:	6a 00                	push   $0x0
  pushl $204
f010111d:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
f0101122:	e9 cf f7 ff ff       	jmp    f01008f6 <alltraps>

f0101127 <vector205>:
.globl vector205
vector205:
  pushl $0
f0101127:	6a 00                	push   $0x0
  pushl $205
f0101129:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
f010112e:	e9 c3 f7 ff ff       	jmp    f01008f6 <alltraps>

f0101133 <vector206>:
.globl vector206
vector206:
  pushl $0
f0101133:	6a 00                	push   $0x0
  pushl $206
f0101135:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
f010113a:	e9 b7 f7 ff ff       	jmp    f01008f6 <alltraps>

f010113f <vector207>:
.globl vector207
vector207:
  pushl $0
f010113f:	6a 00                	push   $0x0
  pushl $207
f0101141:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
f0101146:	e9 ab f7 ff ff       	jmp    f01008f6 <alltraps>

f010114b <vector208>:
.globl vector208
vector208:
  pushl $0
f010114b:	6a 00                	push   $0x0
  pushl $208
f010114d:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
f0101152:	e9 9f f7 ff ff       	jmp    f01008f6 <alltraps>

f0101157 <vector209>:
.globl vector209
vector209:
  pushl $0
f0101157:	6a 00                	push   $0x0
  pushl $209
f0101159:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
f010115e:	e9 93 f7 ff ff       	jmp    f01008f6 <alltraps>

f0101163 <vector210>:
.globl vector210
vector210:
  pushl $0
f0101163:	6a 00                	push   $0x0
  pushl $210
f0101165:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
f010116a:	e9 87 f7 ff ff       	jmp    f01008f6 <alltraps>

f010116f <vector211>:
.globl vector211
vector211:
  pushl $0
f010116f:	6a 00                	push   $0x0
  pushl $211
f0101171:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
f0101176:	e9 7b f7 ff ff       	jmp    f01008f6 <alltraps>

f010117b <vector212>:
.globl vector212
vector212:
  pushl $0
f010117b:	6a 00                	push   $0x0
  pushl $212
f010117d:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
f0101182:	e9 6f f7 ff ff       	jmp    f01008f6 <alltraps>

f0101187 <vector213>:
.globl vector213
vector213:
  pushl $0
f0101187:	6a 00                	push   $0x0
  pushl $213
f0101189:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
f010118e:	e9 63 f7 ff ff       	jmp    f01008f6 <alltraps>

f0101193 <vector214>:
.globl vector214
vector214:
  pushl $0
f0101193:	6a 00                	push   $0x0
  pushl $214
f0101195:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
f010119a:	e9 57 f7 ff ff       	jmp    f01008f6 <alltraps>

f010119f <vector215>:
.globl vector215
vector215:
  pushl $0
f010119f:	6a 00                	push   $0x0
  pushl $215
f01011a1:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
f01011a6:	e9 4b f7 ff ff       	jmp    f01008f6 <alltraps>

f01011ab <vector216>:
.globl vector216
vector216:
  pushl $0
f01011ab:	6a 00                	push   $0x0
  pushl $216
f01011ad:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
f01011b2:	e9 3f f7 ff ff       	jmp    f01008f6 <alltraps>

f01011b7 <vector217>:
.globl vector217
vector217:
  pushl $0
f01011b7:	6a 00                	push   $0x0
  pushl $217
f01011b9:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
f01011be:	e9 33 f7 ff ff       	jmp    f01008f6 <alltraps>

f01011c3 <vector218>:
.globl vector218
vector218:
  pushl $0
f01011c3:	6a 00                	push   $0x0
  pushl $218
f01011c5:	68 da 00 00 00       	push   $0xda
  jmp alltraps
f01011ca:	e9 27 f7 ff ff       	jmp    f01008f6 <alltraps>

f01011cf <vector219>:
.globl vector219
vector219:
  pushl $0
f01011cf:	6a 00                	push   $0x0
  pushl $219
f01011d1:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
f01011d6:	e9 1b f7 ff ff       	jmp    f01008f6 <alltraps>

f01011db <vector220>:
.globl vector220
vector220:
  pushl $0
f01011db:	6a 00                	push   $0x0
  pushl $220
f01011dd:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
f01011e2:	e9 0f f7 ff ff       	jmp    f01008f6 <alltraps>

f01011e7 <vector221>:
.globl vector221
vector221:
  pushl $0
f01011e7:	6a 00                	push   $0x0
  pushl $221
f01011e9:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
f01011ee:	e9 03 f7 ff ff       	jmp    f01008f6 <alltraps>

f01011f3 <vector222>:
.globl vector222
vector222:
  pushl $0
f01011f3:	6a 00                	push   $0x0
  pushl $222
f01011f5:	68 de 00 00 00       	push   $0xde
  jmp alltraps
f01011fa:	e9 f7 f6 ff ff       	jmp    f01008f6 <alltraps>

f01011ff <vector223>:
.globl vector223
vector223:
  pushl $0
f01011ff:	6a 00                	push   $0x0
  pushl $223
f0101201:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
f0101206:	e9 eb f6 ff ff       	jmp    f01008f6 <alltraps>

f010120b <vector224>:
.globl vector224
vector224:
  pushl $0
f010120b:	6a 00                	push   $0x0
  pushl $224
f010120d:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
f0101212:	e9 df f6 ff ff       	jmp    f01008f6 <alltraps>

f0101217 <vector225>:
.globl vector225
vector225:
  pushl $0
f0101217:	6a 00                	push   $0x0
  pushl $225
f0101219:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
f010121e:	e9 d3 f6 ff ff       	jmp    f01008f6 <alltraps>

f0101223 <vector226>:
.globl vector226
vector226:
  pushl $0
f0101223:	6a 00                	push   $0x0
  pushl $226
f0101225:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
f010122a:	e9 c7 f6 ff ff       	jmp    f01008f6 <alltraps>

f010122f <vector227>:
.globl vector227
vector227:
  pushl $0
f010122f:	6a 00                	push   $0x0
  pushl $227
f0101231:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
f0101236:	e9 bb f6 ff ff       	jmp    f01008f6 <alltraps>

f010123b <vector228>:
.globl vector228
vector228:
  pushl $0
f010123b:	6a 00                	push   $0x0
  pushl $228
f010123d:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
f0101242:	e9 af f6 ff ff       	jmp    f01008f6 <alltraps>

f0101247 <vector229>:
.globl vector229
vector229:
  pushl $0
f0101247:	6a 00                	push   $0x0
  pushl $229
f0101249:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
f010124e:	e9 a3 f6 ff ff       	jmp    f01008f6 <alltraps>

f0101253 <vector230>:
.globl vector230
vector230:
  pushl $0
f0101253:	6a 00                	push   $0x0
  pushl $230
f0101255:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
f010125a:	e9 97 f6 ff ff       	jmp    f01008f6 <alltraps>

f010125f <vector231>:
.globl vector231
vector231:
  pushl $0
f010125f:	6a 00                	push   $0x0
  pushl $231
f0101261:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
f0101266:	e9 8b f6 ff ff       	jmp    f01008f6 <alltraps>

f010126b <vector232>:
.globl vector232
vector232:
  pushl $0
f010126b:	6a 00                	push   $0x0
  pushl $232
f010126d:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
f0101272:	e9 7f f6 ff ff       	jmp    f01008f6 <alltraps>

f0101277 <vector233>:
.globl vector233
vector233:
  pushl $0
f0101277:	6a 00                	push   $0x0
  pushl $233
f0101279:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
f010127e:	e9 73 f6 ff ff       	jmp    f01008f6 <alltraps>

f0101283 <vector234>:
.globl vector234
vector234:
  pushl $0
f0101283:	6a 00                	push   $0x0
  pushl $234
f0101285:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
f010128a:	e9 67 f6 ff ff       	jmp    f01008f6 <alltraps>

f010128f <vector235>:
.globl vector235
vector235:
  pushl $0
f010128f:	6a 00                	push   $0x0
  pushl $235
f0101291:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
f0101296:	e9 5b f6 ff ff       	jmp    f01008f6 <alltraps>

f010129b <vector236>:
.globl vector236
vector236:
  pushl $0
f010129b:	6a 00                	push   $0x0
  pushl $236
f010129d:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
f01012a2:	e9 4f f6 ff ff       	jmp    f01008f6 <alltraps>

f01012a7 <vector237>:
.globl vector237
vector237:
  pushl $0
f01012a7:	6a 00                	push   $0x0
  pushl $237
f01012a9:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
f01012ae:	e9 43 f6 ff ff       	jmp    f01008f6 <alltraps>

f01012b3 <vector238>:
.globl vector238
vector238:
  pushl $0
f01012b3:	6a 00                	push   $0x0
  pushl $238
f01012b5:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
f01012ba:	e9 37 f6 ff ff       	jmp    f01008f6 <alltraps>

f01012bf <vector239>:
.globl vector239
vector239:
  pushl $0
f01012bf:	6a 00                	push   $0x0
  pushl $239
f01012c1:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
f01012c6:	e9 2b f6 ff ff       	jmp    f01008f6 <alltraps>

f01012cb <vector240>:
.globl vector240
vector240:
  pushl $0
f01012cb:	6a 00                	push   $0x0
  pushl $240
f01012cd:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
f01012d2:	e9 1f f6 ff ff       	jmp    f01008f6 <alltraps>

f01012d7 <vector241>:
.globl vector241
vector241:
  pushl $0
f01012d7:	6a 00                	push   $0x0
  pushl $241
f01012d9:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
f01012de:	e9 13 f6 ff ff       	jmp    f01008f6 <alltraps>

f01012e3 <vector242>:
.globl vector242
vector242:
  pushl $0
f01012e3:	6a 00                	push   $0x0
  pushl $242
f01012e5:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
f01012ea:	e9 07 f6 ff ff       	jmp    f01008f6 <alltraps>

f01012ef <vector243>:
.globl vector243
vector243:
  pushl $0
f01012ef:	6a 00                	push   $0x0
  pushl $243
f01012f1:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
f01012f6:	e9 fb f5 ff ff       	jmp    f01008f6 <alltraps>

f01012fb <vector244>:
.globl vector244
vector244:
  pushl $0
f01012fb:	6a 00                	push   $0x0
  pushl $244
f01012fd:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
f0101302:	e9 ef f5 ff ff       	jmp    f01008f6 <alltraps>

f0101307 <vector245>:
.globl vector245
vector245:
  pushl $0
f0101307:	6a 00                	push   $0x0
  pushl $245
f0101309:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
f010130e:	e9 e3 f5 ff ff       	jmp    f01008f6 <alltraps>

f0101313 <vector246>:
.globl vector246
vector246:
  pushl $0
f0101313:	6a 00                	push   $0x0
  pushl $246
f0101315:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
f010131a:	e9 d7 f5 ff ff       	jmp    f01008f6 <alltraps>

f010131f <vector247>:
.globl vector247
vector247:
  pushl $0
f010131f:	6a 00                	push   $0x0
  pushl $247
f0101321:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
f0101326:	e9 cb f5 ff ff       	jmp    f01008f6 <alltraps>

f010132b <vector248>:
.globl vector248
vector248:
  pushl $0
f010132b:	6a 00                	push   $0x0
  pushl $248
f010132d:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
f0101332:	e9 bf f5 ff ff       	jmp    f01008f6 <alltraps>

f0101337 <vector249>:
.globl vector249
vector249:
  pushl $0
f0101337:	6a 00                	push   $0x0
  pushl $249
f0101339:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
f010133e:	e9 b3 f5 ff ff       	jmp    f01008f6 <alltraps>

f0101343 <vector250>:
.globl vector250
vector250:
  pushl $0
f0101343:	6a 00                	push   $0x0
  pushl $250
f0101345:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
f010134a:	e9 a7 f5 ff ff       	jmp    f01008f6 <alltraps>

f010134f <vector251>:
.globl vector251
vector251:
  pushl $0
f010134f:	6a 00                	push   $0x0
  pushl $251
f0101351:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
f0101356:	e9 9b f5 ff ff       	jmp    f01008f6 <alltraps>

f010135b <vector252>:
.globl vector252
vector252:
  pushl $0
f010135b:	6a 00                	push   $0x0
  pushl $252
f010135d:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
f0101362:	e9 8f f5 ff ff       	jmp    f01008f6 <alltraps>

f0101367 <vector253>:
.globl vector253
vector253:
  pushl $0
f0101367:	6a 00                	push   $0x0
  pushl $253
f0101369:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
f010136e:	e9 83 f5 ff ff       	jmp    f01008f6 <alltraps>

f0101373 <vector254>:
.globl vector254
vector254:
  pushl $0
f0101373:	6a 00                	push   $0x0
  pushl $254
f0101375:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
f010137a:	e9 77 f5 ff ff       	jmp    f01008f6 <alltraps>

f010137f <vector255>:
.globl vector255
vector255:
  pushl $0
f010137f:	6a 00                	push   $0x0
  pushl $255
f0101381:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
f0101386:	e9 6b f5 ff ff       	jmp    f01008f6 <alltraps>

f010138b <seg_init>:
// GDT.
struct segdesc gdt[NSEGS];

void
seg_init(void)
{
f010138b:	55                   	push   %ebp
f010138c:	89 e5                	mov    %esp,%ebp
f010138e:	83 ec 18             	sub    $0x18,%esp
	// Cannot share a CODE descriptor for both kernel and user
	// because it would have to have DPL_USR, but the CPU forbids
	// an interrupt from CPL=0 to DPL=3.
	// Your code here.
	//
	thiscpu->gdt[SEG_KCODE] = SEG(STA_R | STA_X, 0, 0xffffffff, 0);
f0101391:	e8 ee 11 00 00       	call   f0102584 <cpunum>
f0101396:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f010139c:	8d 90 20 40 12 f0    	lea    -0xfedbfe0(%eax),%edx
f01013a2:	66 c7 80 9c 40 12 f0 	movw   $0xffff,-0xfedbf64(%eax)
f01013a9:	ff ff 
f01013ab:	66 c7 80 9e 40 12 f0 	movw   $0x0,-0xfedbf62(%eax)
f01013b2:	00 00 
f01013b4:	c6 80 a0 40 12 f0 00 	movb   $0x0,-0xfedbf60(%eax)
f01013bb:	c6 80 a1 40 12 f0 9a 	movb   $0x9a,-0xfedbf5f(%eax)
f01013c2:	c6 80 a2 40 12 f0 cf 	movb   $0xcf,-0xfedbf5e(%eax)
f01013c9:	c6 82 83 00 00 00 00 	movb   $0x0,0x83(%edx)
	thiscpu->gdt[SEG_KDATA] = SEG(STA_W | STA_R, 0, 0xffffffff, 0);
f01013d0:	e8 af 11 00 00       	call   f0102584 <cpunum>
f01013d5:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f01013db:	8d 90 20 40 12 f0    	lea    -0xfedbfe0(%eax),%edx
f01013e1:	66 c7 80 a4 40 12 f0 	movw   $0xffff,-0xfedbf5c(%eax)
f01013e8:	ff ff 
f01013ea:	66 c7 80 a6 40 12 f0 	movw   $0x0,-0xfedbf5a(%eax)
f01013f1:	00 00 
f01013f3:	c6 80 a8 40 12 f0 00 	movb   $0x0,-0xfedbf58(%eax)
f01013fa:	c6 80 a9 40 12 f0 92 	movb   $0x92,-0xfedbf57(%eax)
f0101401:	c6 80 aa 40 12 f0 cf 	movb   $0xcf,-0xfedbf56(%eax)
f0101408:	c6 82 8b 00 00 00 00 	movb   $0x0,0x8b(%edx)
	thiscpu->gdt[SEG_UCODE] = SEG(STA_R | STA_X, 0, 0xffffffff, DPL_USER);
f010140f:	e8 70 11 00 00       	call   f0102584 <cpunum>
f0101414:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f010141a:	8d 90 20 40 12 f0    	lea    -0xfedbfe0(%eax),%edx
f0101420:	66 c7 80 ac 40 12 f0 	movw   $0xffff,-0xfedbf54(%eax)
f0101427:	ff ff 
f0101429:	66 c7 80 ae 40 12 f0 	movw   $0x0,-0xfedbf52(%eax)
f0101430:	00 00 
f0101432:	c6 80 b0 40 12 f0 00 	movb   $0x0,-0xfedbf50(%eax)
f0101439:	c6 80 b1 40 12 f0 fa 	movb   $0xfa,-0xfedbf4f(%eax)
f0101440:	c6 80 b2 40 12 f0 cf 	movb   $0xcf,-0xfedbf4e(%eax)
f0101447:	c6 82 93 00 00 00 00 	movb   $0x0,0x93(%edx)
	thiscpu->gdt[SEG_UDATA] = SEG(STA_R | STA_W, 0, 0xffffffff, DPL_USER);
f010144e:	e8 31 11 00 00       	call   f0102584 <cpunum>
f0101453:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f0101459:	8d 90 20 40 12 f0    	lea    -0xfedbfe0(%eax),%edx
f010145f:	66 c7 80 b4 40 12 f0 	movw   $0xffff,-0xfedbf4c(%eax)
f0101466:	ff ff 
f0101468:	66 c7 80 b6 40 12 f0 	movw   $0x0,-0xfedbf4a(%eax)
f010146f:	00 00 
f0101471:	c6 80 b8 40 12 f0 00 	movb   $0x0,-0xfedbf48(%eax)
f0101478:	c6 80 b9 40 12 f0 f2 	movb   $0xf2,-0xfedbf47(%eax)
f010147f:	c6 80 ba 40 12 f0 cf 	movb   $0xcf,-0xfedbf46(%eax)
f0101486:	c6 82 9b 00 00 00 00 	movb   $0x0,0x9b(%edx)
	lgdt(thiscpu->gdt, sizeof(thiscpu->gdt));
f010148d:	e8 f2 10 00 00       	call   f0102584 <cpunum>
f0101492:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f0101498:	05 94 40 12 f0       	add    $0xf0124094,%eax
	pd[0] = size-1;
f010149d:	66 c7 45 f2 2f 00    	movw   $0x2f,-0xe(%ebp)
	pd[1] = (unsigned)p;
f01014a3:	66 89 45 f4          	mov    %ax,-0xc(%ebp)
	pd[2] = (unsigned)p >> 16;
f01014a7:	c1 e8 10             	shr    $0x10,%eax
f01014aa:	66 89 45 f6          	mov    %ax,-0xa(%ebp)
	asm volatile("lgdt (%0)" : : "r" (pd));
f01014ae:	8d 45 f2             	lea    -0xe(%ebp),%eax
f01014b1:	0f 01 10             	lgdtl  (%eax)
	// user code, user data;
	// 2. The various segment selectors, application segment type bits and
	// User DPL have been defined in inc/mmu.h;
	// 3. You may need macro SEG() to set up segments;
	// 4. We have implememted the C function lgdt() in inc/x86.h;
}
f01014b4:	c9                   	leave  
f01014b5:	c3                   	ret    

f01014b6 <pgdir_walk>:
// Hint 2: look at inc/mmu.h for useful macros that manipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int32_t alloc)
{
f01014b6:	55                   	push   %ebp
f01014b7:	89 e5                	mov    %esp,%ebp
f01014b9:	57                   	push   %edi
f01014ba:	56                   	push   %esi
f01014bb:	53                   	push   %ebx
f01014bc:	83 ec 0c             	sub    $0xc,%esp
f01014bf:	8b 75 0c             	mov    0xc(%ebp),%esi
	// TODO: Fill this function in
	pde_t *pde = &pgdir[PDX(va)];
f01014c2:	89 f7                	mov    %esi,%edi
f01014c4:	c1 ef 16             	shr    $0x16,%edi
f01014c7:	c1 e7 02             	shl    $0x2,%edi
f01014ca:	03 7d 08             	add    0x8(%ebp),%edi
	pte_t *pgtab;
	if ((*pde & PTE_P) == 1)
f01014cd:	8b 1f                	mov    (%edi),%ebx
f01014cf:	f6 c3 01             	test   $0x1,%bl
f01014d2:	74 21                	je     f01014f5 <pgdir_walk+0x3f>
	    pgtab = (pte_t *)P2V(PTE_ADDR(*pde));
f01014d4:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
f01014da:	81 eb 00 00 00 10    	sub    $0x10000000,%ebx
	    if (alloc == 0 || (pgtab = (pte_t *)kalloc()) == NULL)
	        return NULL;
	    memset(pgtab, 0, PGSIZE);
        *pde = V2P(pgtab) | PTE_P | PTE_U | PTE_W;
	}
	return &pgtab[PTX(va)];
f01014e0:	c1 ee 0a             	shr    $0xa,%esi
f01014e3:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f01014e9:	01 f3                	add    %esi,%ebx
}
f01014eb:	89 d8                	mov    %ebx,%eax
f01014ed:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01014f0:	5b                   	pop    %ebx
f01014f1:	5e                   	pop    %esi
f01014f2:	5f                   	pop    %edi
f01014f3:	5d                   	pop    %ebp
f01014f4:	c3                   	ret    
	    if (alloc == 0 || (pgtab = (pte_t *)kalloc()) == NULL)
f01014f5:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f01014f9:	74 2b                	je     f0101526 <pgdir_walk+0x70>
f01014fb:	e8 3c 0a 00 00       	call   f0101f3c <kalloc>
f0101500:	89 c3                	mov    %eax,%ebx
f0101502:	85 c0                	test   %eax,%eax
f0101504:	74 e5                	je     f01014eb <pgdir_walk+0x35>
	    memset(pgtab, 0, PGSIZE);
f0101506:	83 ec 04             	sub    $0x4,%esp
f0101509:	68 00 10 00 00       	push   $0x1000
f010150e:	6a 00                	push   $0x0
f0101510:	50                   	push   %eax
f0101511:	e8 a2 22 00 00       	call   f01037b8 <memset>
        *pde = V2P(pgtab) | PTE_P | PTE_U | PTE_W;
f0101516:	8d 83 00 00 00 10    	lea    0x10000000(%ebx),%eax
f010151c:	83 c8 07             	or     $0x7,%eax
f010151f:	89 07                	mov    %eax,(%edi)
f0101521:	83 c4 10             	add    $0x10,%esp
f0101524:	eb ba                	jmp    f01014e0 <pgdir_walk+0x2a>
	        return NULL;
f0101526:	bb 00 00 00 00       	mov    $0x0,%ebx
f010152b:	eb be                	jmp    f01014eb <pgdir_walk+0x35>

f010152d <map_region>:
// Use permission bits perm|PTE_P for the entries.
//
// Hint: the TA solution uses pgdir_walk
int // What to return?
map_region(pde_t *pgdir, void *va, uint32_t size, uint32_t pa, int32_t perm)
{
f010152d:	55                   	push   %ebp
f010152e:	89 e5                	mov    %esp,%ebp
f0101530:	57                   	push   %edi
f0101531:	56                   	push   %esi
f0101532:	53                   	push   %ebx
f0101533:	83 ec 1c             	sub    $0x1c,%esp
f0101536:	8b 45 14             	mov    0x14(%ebp),%eax
	// TODO: Fill this function in
	char *align = ROUNDUP(va, PGSIZE);
f0101539:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010153c:	8d b1 ff 0f 00 00    	lea    0xfff(%ecx),%esi
f0101542:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	uint32_t alignsize = ROUNDUP(size, PGSIZE);
f0101548:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010154b:	8d b9 ff 0f 00 00    	lea    0xfff(%ecx),%edi
f0101551:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
f0101557:	01 c7                	add    %eax,%edi
	while (alignsize) {
f0101559:	89 c3                	mov    %eax,%ebx
f010155b:	29 c6                	sub    %eax,%esi
		pte_t *pte = pgdir_walk(pgdir, align, 1);
		if (pte == NULL)
			return -1;
		*pte = pa | perm | PTE_P;
f010155d:	8b 45 18             	mov    0x18(%ebp),%eax
f0101560:	83 c8 01             	or     $0x1,%eax
f0101563:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101566:	8d 04 1e             	lea    (%esi,%ebx,1),%eax
	while (alignsize) {
f0101569:	39 df                	cmp    %ebx,%edi
f010156b:	74 24                	je     f0101591 <map_region+0x64>
		pte_t *pte = pgdir_walk(pgdir, align, 1);
f010156d:	83 ec 04             	sub    $0x4,%esp
f0101570:	6a 01                	push   $0x1
f0101572:	50                   	push   %eax
f0101573:	ff 75 08             	pushl  0x8(%ebp)
f0101576:	e8 3b ff ff ff       	call   f01014b6 <pgdir_walk>
		if (pte == NULL)
f010157b:	83 c4 10             	add    $0x10,%esp
f010157e:	85 c0                	test   %eax,%eax
f0101580:	74 1c                	je     f010159e <map_region+0x71>
		*pte = pa | perm | PTE_P;
f0101582:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101585:	09 da                	or     %ebx,%edx
f0101587:	89 10                	mov    %edx,(%eax)
		alignsize -= PGSIZE;
		pa += PGSIZE;
f0101589:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010158f:	eb d5                	jmp    f0101566 <map_region+0x39>
		align += PGSIZE;
	} 
	return 0;
f0101591:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101596:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101599:	5b                   	pop    %ebx
f010159a:	5e                   	pop    %esi
f010159b:	5f                   	pop    %edi
f010159c:	5d                   	pop    %ebp
f010159d:	c3                   	ret    
			return -1;
f010159e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01015a3:	eb f1                	jmp    f0101596 <map_region+0x69>

f01015a5 <loaduvm>:

int
loaduvm(pde_t *pgdir, char *addr, struct Proghdr *ph)
{
f01015a5:	55                   	push   %ebp
f01015a6:	89 e5                	mov    %esp,%ebp
f01015a8:	56                   	push   %esi
f01015a9:	53                   	push   %ebx
f01015aa:	8b 75 10             	mov    0x10(%ebp),%esi
	pte_t *pte;
	if ((pte = pgdir_walk(pgdir, addr, 1)) == 0)
f01015ad:	83 ec 04             	sub    $0x4,%esp
f01015b0:	6a 01                	push   $0x1
f01015b2:	ff 75 0c             	pushl  0xc(%ebp)
f01015b5:	ff 75 08             	pushl  0x8(%ebp)
f01015b8:	e8 f9 fe ff ff       	call   f01014b6 <pgdir_walk>
f01015bd:	83 c4 10             	add    $0x10,%esp
f01015c0:	85 c0                	test   %eax,%eax
f01015c2:	74 56                	je     f010161a <loaduvm+0x75>
		return -1;
	void *dst = P2V(PTE_ADDR(*pte));
f01015c4:	8b 18                	mov    (%eax),%ebx
f01015c6:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
f01015cc:	81 eb 00 00 00 10    	sub    $0x10000000,%ebx
	memmove(dst, P2V(ph->p_pa), ph->p_memsz);
f01015d2:	83 ec 04             	sub    $0x4,%esp
f01015d5:	ff 76 14             	pushl  0x14(%esi)
f01015d8:	8b 46 0c             	mov    0xc(%esi),%eax
f01015db:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01015e0:	50                   	push   %eax
f01015e1:	53                   	push   %ebx
f01015e2:	e8 1e 22 00 00       	call   f0103805 <memmove>
	if (ph->p_memsz > ph->p_filesz)
f01015e7:	8b 56 14             	mov    0x14(%esi),%edx
f01015ea:	8b 4e 10             	mov    0x10(%esi),%ecx
f01015ed:	83 c4 10             	add    $0x10,%esp
		memset(dst + ph->p_filesz, 0, ph->p_memsz - ph->p_filesz);
	return 0;
f01015f0:	b8 00 00 00 00       	mov    $0x0,%eax
	if (ph->p_memsz > ph->p_filesz)
f01015f5:	39 ca                	cmp    %ecx,%edx
f01015f7:	77 07                	ja     f0101600 <loaduvm+0x5b>
}
f01015f9:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01015fc:	5b                   	pop    %ebx
f01015fd:	5e                   	pop    %esi
f01015fe:	5d                   	pop    %ebp
f01015ff:	c3                   	ret    
		memset(dst + ph->p_filesz, 0, ph->p_memsz - ph->p_filesz);
f0101600:	83 ec 04             	sub    $0x4,%esp
f0101603:	29 ca                	sub    %ecx,%edx
f0101605:	52                   	push   %edx
f0101606:	6a 00                	push   $0x0
f0101608:	01 cb                	add    %ecx,%ebx
f010160a:	53                   	push   %ebx
f010160b:	e8 a8 21 00 00       	call   f01037b8 <memset>
f0101610:	83 c4 10             	add    $0x10,%esp
	return 0;
f0101613:	b8 00 00 00 00       	mov    $0x0,%eax
f0101618:	eb df                	jmp    f01015f9 <loaduvm+0x54>
		return -1;
f010161a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010161f:	eb d8                	jmp    f01015f9 <loaduvm+0x54>

f0101621 <kvm_init>:
//			for each item of kmap[];
//
// Hint: You may need ARRAY_SIZE.
pde_t *
kvm_init(void)
{
f0101621:	55                   	push   %ebp
f0101622:	89 e5                	mov    %esp,%ebp
f0101624:	57                   	push   %edi
f0101625:	56                   	push   %esi
f0101626:	53                   	push   %ebx
f0101627:	83 ec 0c             	sub    $0xc,%esp
	// TODO: your code here
	pde_t *pgdirinit = (pde_t *)kalloc();
f010162a:	e8 0d 09 00 00       	call   f0101f3c <kalloc>
f010162f:	89 c6                	mov    %eax,%esi
	if (pgdirinit) {
f0101631:	85 c0                	test   %eax,%eax
f0101633:	74 43                	je     f0101678 <kvm_init+0x57>
	    memset(pgdirinit, 0, PGSIZE);
f0101635:	83 ec 04             	sub    $0x4,%esp
f0101638:	68 00 10 00 00       	push   $0x1000
f010163d:	6a 00                	push   $0x0
f010163f:	50                   	push   %eax
f0101640:	e8 73 21 00 00       	call   f01037b8 <memset>
f0101645:	bb 00 40 10 f0       	mov    $0xf0104000,%ebx
f010164a:	bf 40 40 10 f0       	mov    $0xf0104040,%edi
f010164f:	83 c4 10             	add    $0x10,%esp
		for (int i = 0; i < ARRAY_SIZE(kmap); i++)
			if (map_region(pgdirinit, kmap[i].virt, kmap[i].phys_end - kmap[i].phys_start, kmap[i].phys_start, kmap[i].perm) < 0) {
f0101652:	8b 43 04             	mov    0x4(%ebx),%eax
f0101655:	83 ec 0c             	sub    $0xc,%esp
f0101658:	ff 73 0c             	pushl  0xc(%ebx)
f010165b:	50                   	push   %eax
f010165c:	8b 53 08             	mov    0x8(%ebx),%edx
f010165f:	29 c2                	sub    %eax,%edx
f0101661:	52                   	push   %edx
f0101662:	ff 33                	pushl  (%ebx)
f0101664:	56                   	push   %esi
f0101665:	e8 c3 fe ff ff       	call   f010152d <map_region>
f010166a:	83 c4 20             	add    $0x20,%esp
f010166d:	85 c0                	test   %eax,%eax
f010166f:	78 11                	js     f0101682 <kvm_init+0x61>
f0101671:	83 c3 10             	add    $0x10,%ebx
		for (int i = 0; i < ARRAY_SIZE(kmap); i++)
f0101674:	39 fb                	cmp    %edi,%ebx
f0101676:	75 da                	jne    f0101652 <kvm_init+0x31>
                return 0;
			}
		return pgdirinit;
	} else
		return 0;
}
f0101678:	89 f0                	mov    %esi,%eax
f010167a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010167d:	5b                   	pop    %ebx
f010167e:	5e                   	pop    %esi
f010167f:	5f                   	pop    %edi
f0101680:	5d                   	pop    %ebp
f0101681:	c3                   	ret    
				kfree((char *)pgdirinit);
f0101682:	83 ec 0c             	sub    $0xc,%esp
f0101685:	56                   	push   %esi
f0101686:	e8 f9 05 00 00       	call   f0101c84 <kfree>
                return 0;
f010168b:	83 c4 10             	add    $0x10,%esp
f010168e:	be 00 00 00 00       	mov    $0x0,%esi
f0101693:	eb e3                	jmp    f0101678 <kvm_init+0x57>

f0101695 <kvm_switch>:

// Switch h/w page table register to the kernel-only page table.
void
kvm_switch(void)
{
f0101695:	55                   	push   %ebp
f0101696:	89 e5                	mov    %esp,%ebp
	lcr3(V2P(kpgdir)); // switch to the kernel page table
f0101698:	a1 90 3e 12 f0       	mov    0xf0123e90,%eax
f010169d:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01016a2:	0f 22 d8             	mov    %eax,%cr3
}
f01016a5:	5d                   	pop    %ebp
f01016a6:	c3                   	ret    

f01016a7 <check_vm>:

void
check_vm(pde_t *pgdir)
{
f01016a7:	55                   	push   %ebp
f01016a8:	89 e5                	mov    %esp,%ebp
f01016aa:	57                   	push   %edi
f01016ab:	56                   	push   %esi
f01016ac:	53                   	push   %ebx
f01016ad:	83 ec 1c             	sub    $0x1c,%esp
f01016b0:	c7 45 e0 00 40 10 f0 	movl   $0xf0104000,-0x20(%ebp)
f01016b7:	8b 7d 08             	mov    0x8(%ebp),%edi
f01016ba:	eb 3e                	jmp    f01016fa <check_vm+0x53>
		uint32_t alignsize = ROUNDUP(kmap[i].phys_end - kmap[i].phys_start, PGSIZE);
		uint32_t pa = kmap[i].phys_start;
		while(alignsize) {
			pte_t *pte = pgdir_walk(pgdir, align, 1);
			if (pte == NULL) 
				panic("vm_fail: Do not find the page table entry");
f01016bc:	83 ec 04             	sub    $0x4,%esp
f01016bf:	68 54 3f 10 f0       	push   $0xf0103f54
f01016c4:	68 bc 00 00 00       	push   $0xbc
f01016c9:	68 7e 3f 10 f0       	push   $0xf0103f7e
f01016ce:	e8 cc ea ff ff       	call   f010019f <_panic>
			pte_t tmp = (*pte >> 12) << 12;
			assert(tmp == pa);
f01016d3:	68 88 3f 10 f0       	push   $0xf0103f88
f01016d8:	68 92 3f 10 f0       	push   $0xf0103f92
f01016dd:	68 be 00 00 00       	push   $0xbe
f01016e2:	68 7e 3f 10 f0       	push   $0xf0103f7e
f01016e7:	e8 b3 ea ff ff       	call   f010019f <_panic>
f01016ec:	83 45 e0 10          	addl   $0x10,-0x20(%ebp)
f01016f0:	8b 45 e0             	mov    -0x20(%ebp),%eax
	for (int i = 0; i < ARRAY_SIZE(kmap); i++) {
f01016f3:	3d 40 40 10 f0       	cmp    $0xf0104040,%eax
f01016f8:	74 5e                	je     f0101758 <check_vm+0xb1>
		char *align = ROUNDUP(kmap[i].virt, PGSIZE);
f01016fa:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01016fd:	8b 10                	mov    (%eax),%edx
f01016ff:	8d b2 ff 0f 00 00    	lea    0xfff(%edx),%esi
f0101705:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
		uint32_t alignsize = ROUNDUP(kmap[i].phys_end - kmap[i].phys_start, PGSIZE);
f010170b:	8b 50 04             	mov    0x4(%eax),%edx
f010170e:	8b 40 08             	mov    0x8(%eax),%eax
f0101711:	05 ff 0f 00 00       	add    $0xfff,%eax
f0101716:	29 d0                	sub    %edx,%eax
f0101718:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010171d:	01 d0                	add    %edx,%eax
f010171f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		uint32_t pa = kmap[i].phys_start;
f0101722:	89 d3                	mov    %edx,%ebx
f0101724:	29 d6                	sub    %edx,%esi
f0101726:	8d 04 1e             	lea    (%esi,%ebx,1),%eax
		while(alignsize) {
f0101729:	39 5d e4             	cmp    %ebx,-0x1c(%ebp)
f010172c:	74 be                	je     f01016ec <check_vm+0x45>
			pte_t *pte = pgdir_walk(pgdir, align, 1);
f010172e:	83 ec 04             	sub    $0x4,%esp
f0101731:	6a 01                	push   $0x1
f0101733:	50                   	push   %eax
f0101734:	57                   	push   %edi
f0101735:	e8 7c fd ff ff       	call   f01014b6 <pgdir_walk>
			if (pte == NULL) 
f010173a:	83 c4 10             	add    $0x10,%esp
f010173d:	85 c0                	test   %eax,%eax
f010173f:	0f 84 77 ff ff ff    	je     f01016bc <check_vm+0x15>
			pte_t tmp = (*pte >> 12) << 12;
f0101745:	8b 00                	mov    (%eax),%eax
f0101747:	25 00 f0 ff ff       	and    $0xfffff000,%eax
			assert(tmp == pa);
f010174c:	39 c3                	cmp    %eax,%ebx
f010174e:	75 83                	jne    f01016d3 <check_vm+0x2c>
			align += PGSIZE;
			pa += PGSIZE;
f0101750:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0101756:	eb ce                	jmp    f0101726 <check_vm+0x7f>
			alignsize -= PGSIZE;
		}
	}
}
f0101758:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010175b:	5b                   	pop    %ebx
f010175c:	5e                   	pop    %esi
f010175d:	5f                   	pop    %edi
f010175e:	5d                   	pop    %ebp
f010175f:	c3                   	ret    

f0101760 <vm_init>:

// Allocate one page table for the machine for the kernel address
// space.
void
vm_init(void)
{
f0101760:	55                   	push   %ebp
f0101761:	89 e5                	mov    %esp,%ebp
f0101763:	83 ec 08             	sub    $0x8,%esp
	kpgdir = kvm_init();
f0101766:	e8 b6 fe ff ff       	call   f0101621 <kvm_init>
f010176b:	a3 90 3e 12 f0       	mov    %eax,0xf0123e90
	if (kpgdir == 0)
f0101770:	85 c0                	test   %eax,%eax
f0101772:	74 13                	je     f0101787 <vm_init+0x27>
		panic("vm_init: failure");
	check_vm(kpgdir);
f0101774:	83 ec 0c             	sub    $0xc,%esp
f0101777:	50                   	push   %eax
f0101778:	e8 2a ff ff ff       	call   f01016a7 <check_vm>
	kvm_switch();
f010177d:	e8 13 ff ff ff       	call   f0101695 <kvm_switch>
}
f0101782:	83 c4 10             	add    $0x10,%esp
f0101785:	c9                   	leave  
f0101786:	c3                   	ret    
		panic("vm_init: failure");
f0101787:	83 ec 04             	sub    $0x4,%esp
f010178a:	68 a7 3f 10 f0       	push   $0xf0103fa7
f010178f:	68 cd 00 00 00       	push   $0xcd
f0101794:	68 7e 3f 10 f0       	push   $0xf0103f7e
f0101799:	e8 01 ea ff ff       	call   f010019f <_panic>

f010179e <vm_free>:
// Free a page table.
//
// Hint: You need to free all existing PTEs for this pgdir.
void
vm_free(pde_t *pgdir)
{
f010179e:	55                   	push   %ebp
f010179f:	89 e5                	mov    %esp,%ebp
f01017a1:	57                   	push   %edi
f01017a2:	56                   	push   %esi
f01017a3:	53                   	push   %ebx
f01017a4:	83 ec 0c             	sub    $0xc,%esp
f01017a7:	8b 7d 08             	mov    0x8(%ebp),%edi
f01017aa:	89 fb                	mov    %edi,%ebx
f01017ac:	8d b7 00 10 00 00    	lea    0x1000(%edi),%esi
f01017b2:	eb 07                	jmp    f01017bb <vm_free+0x1d>
f01017b4:	83 c3 04             	add    $0x4,%ebx
	// TODO: your code here
	for (int i = 0; i < 1024; i++) {
f01017b7:	39 f3                	cmp    %esi,%ebx
f01017b9:	74 1e                	je     f01017d9 <vm_free+0x3b>
	    if (pgdir[i] & PTE_P) {
f01017bb:	8b 03                	mov    (%ebx),%eax
f01017bd:	a8 01                	test   $0x1,%al
f01017bf:	74 f3                	je     f01017b4 <vm_free+0x16>
	        char *v = P2V((pgdir[i] >> 12) << 12);
	        kfree(v);
f01017c1:	83 ec 0c             	sub    $0xc,%esp
	        char *v = P2V((pgdir[i] >> 12) << 12);
f01017c4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01017c9:	2d 00 00 00 10       	sub    $0x10000000,%eax
	        kfree(v);
f01017ce:	50                   	push   %eax
f01017cf:	e8 b0 04 00 00       	call   f0101c84 <kfree>
f01017d4:	83 c4 10             	add    $0x10,%esp
f01017d7:	eb db                	jmp    f01017b4 <vm_free+0x16>
	    }
	}
	kfree((char *)pgdir);
f01017d9:	83 ec 0c             	sub    $0xc,%esp
f01017dc:	57                   	push   %edi
f01017dd:	e8 a2 04 00 00       	call   f0101c84 <kfree>
}
f01017e2:	83 c4 10             	add    $0x10,%esp
f01017e5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01017e8:	5b                   	pop    %ebx
f01017e9:	5e                   	pop    %esi
f01017ea:	5f                   	pop    %edi
f01017eb:	5d                   	pop    %ebp
f01017ec:	c3                   	ret    

f01017ed <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
void
region_alloc(struct proc *p, void *va, size_t len)
{
f01017ed:	55                   	push   %ebp
f01017ee:	89 e5                	mov    %esp,%ebp
f01017f0:	57                   	push   %edi
f01017f1:	56                   	push   %esi
f01017f2:	53                   	push   %ebx
f01017f3:	83 ec 0c             	sub    $0xc,%esp
f01017f6:	8b 7d 08             	mov    0x8(%ebp),%edi
f01017f9:	8b 75 0c             	mov    0xc(%ebp),%esi
	//
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	char *begin = ROUNDDOWN(va, PGSIZE);
f01017fc:	89 f3                	mov    %esi,%ebx
f01017fe:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	char *end = ROUNDUP(va + len, PGSIZE);
f0101804:	03 75 10             	add    0x10(%ebp),%esi
f0101807:	81 c6 ff 0f 00 00    	add    $0xfff,%esi
f010180d:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	while (begin < end) {
f0101813:	39 f3                	cmp    %esi,%ebx
f0101815:	73 43                	jae    f010185a <region_alloc+0x6d>
		char *page = kalloc();
f0101817:	e8 20 07 00 00       	call   f0101f3c <kalloc>
		//memset(page, 0, PGSIZE);
		if (map_region(p->pgdir, begin, PGSIZE, V2P(page), PTE_W | PTE_U) < 0)
f010181c:	83 ec 0c             	sub    $0xc,%esp
f010181f:	6a 06                	push   $0x6
f0101821:	05 00 00 00 10       	add    $0x10000000,%eax
f0101826:	50                   	push   %eax
f0101827:	68 00 10 00 00       	push   $0x1000
f010182c:	53                   	push   %ebx
f010182d:	ff 37                	pushl  (%edi)
f010182f:	e8 f9 fc ff ff       	call   f010152d <map_region>
f0101834:	83 c4 20             	add    $0x20,%esp
f0101837:	85 c0                	test   %eax,%eax
f0101839:	78 08                	js     f0101843 <region_alloc+0x56>
			panic("Map space for user process.");
		begin += PGSIZE;
f010183b:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0101841:	eb d0                	jmp    f0101813 <region_alloc+0x26>
			panic("Map space for user process.");
f0101843:	83 ec 04             	sub    $0x4,%esp
f0101846:	68 b8 3f 10 f0       	push   $0xf0103fb8
f010184b:	68 f9 00 00 00       	push   $0xf9
f0101850:	68 7e 3f 10 f0       	push   $0xf0103f7e
f0101855:	e8 45 e9 ff ff       	call   f010019f <_panic>
	}
}
f010185a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010185d:	5b                   	pop    %ebx
f010185e:	5e                   	pop    %esi
f010185f:	5f                   	pop    %edi
f0101860:	5d                   	pop    %ebp
f0101861:	c3                   	ret    

f0101862 <pushcli>:

void
pushcli(void)
{
f0101862:	55                   	push   %ebp
f0101863:	89 e5                	mov    %esp,%ebp
f0101865:	53                   	push   %ebx
f0101866:	83 ec 04             	sub    $0x4,%esp
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f0101869:	9c                   	pushf  
f010186a:	5b                   	pop    %ebx
}

static inline void
cli(void)
{
	asm volatile("cli");
f010186b:	fa                   	cli    
	int32_t eflags;

	eflags = read_eflags();
	cli();
	if (thiscpu->ncli == 0)
f010186c:	e8 13 0d 00 00       	call   f0102584 <cpunum>
f0101871:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f0101877:	83 b8 c8 40 12 f0 00 	cmpl   $0x0,-0xfedbf38(%eax)
f010187e:	74 18                	je     f0101898 <pushcli+0x36>
		thiscpu->intena = eflags & FL_IF;
	thiscpu->ncli += 1;
f0101880:	e8 ff 0c 00 00       	call   f0102584 <cpunum>
f0101885:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f010188b:	83 80 c8 40 12 f0 01 	addl   $0x1,-0xfedbf38(%eax)
}
f0101892:	83 c4 04             	add    $0x4,%esp
f0101895:	5b                   	pop    %ebx
f0101896:	5d                   	pop    %ebp
f0101897:	c3                   	ret    
		thiscpu->intena = eflags & FL_IF;
f0101898:	e8 e7 0c 00 00       	call   f0102584 <cpunum>
f010189d:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f01018a3:	81 e3 00 02 00 00    	and    $0x200,%ebx
f01018a9:	89 98 cc 40 12 f0    	mov    %ebx,-0xfedbf34(%eax)
f01018af:	eb cf                	jmp    f0101880 <pushcli+0x1e>

f01018b1 <popcli>:

void
popcli(void)
{
f01018b1:	55                   	push   %ebp
f01018b2:	89 e5                	mov    %esp,%ebp
f01018b4:	83 ec 08             	sub    $0x8,%esp
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f01018b7:	9c                   	pushf  
f01018b8:	58                   	pop    %eax
	if (read_eflags() & FL_IF)
f01018b9:	f6 c4 02             	test   $0x2,%ah
f01018bc:	75 34                	jne    f01018f2 <popcli+0x41>
		panic("popcli - interruptible");
	
	if (--thiscpu->ncli < 0)
f01018be:	e8 c1 0c 00 00       	call   f0102584 <cpunum>
f01018c3:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f01018c9:	8b 88 c8 40 12 f0    	mov    -0xfedbf38(%eax),%ecx
f01018cf:	8d 51 ff             	lea    -0x1(%ecx),%edx
f01018d2:	89 90 c8 40 12 f0    	mov    %edx,-0xfedbf38(%eax)
f01018d8:	85 d2                	test   %edx,%edx
f01018da:	78 2d                	js     f0101909 <popcli+0x58>
		panic("popcli");
	
	if (thiscpu->ncli == 0 && thiscpu->intena)
f01018dc:	e8 a3 0c 00 00       	call   f0102584 <cpunum>
f01018e1:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f01018e7:	83 b8 c8 40 12 f0 00 	cmpl   $0x0,-0xfedbf38(%eax)
f01018ee:	74 30                	je     f0101920 <popcli+0x6f>
		sti();
}
f01018f0:	c9                   	leave  
f01018f1:	c3                   	ret    
		panic("popcli - interruptible");
f01018f2:	83 ec 04             	sub    $0x4,%esp
f01018f5:	68 d4 3f 10 f0       	push   $0xf0103fd4
f01018fa:	68 0e 01 00 00       	push   $0x10e
f01018ff:	68 7e 3f 10 f0       	push   $0xf0103f7e
f0101904:	e8 96 e8 ff ff       	call   f010019f <_panic>
		panic("popcli");
f0101909:	83 ec 04             	sub    $0x4,%esp
f010190c:	68 eb 3f 10 f0       	push   $0xf0103feb
f0101911:	68 11 01 00 00       	push   $0x111
f0101916:	68 7e 3f 10 f0       	push   $0xf0103f7e
f010191b:	e8 7f e8 ff ff       	call   f010019f <_panic>
	if (thiscpu->ncli == 0 && thiscpu->intena)
f0101920:	e8 5f 0c 00 00       	call   f0102584 <cpunum>
f0101925:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f010192b:	83 b8 cc 40 12 f0 00 	cmpl   $0x0,-0xfedbf34(%eax)
f0101932:	74 bc                	je     f01018f0 <popcli+0x3f>
}

static inline void
sti(void)
{
	asm volatile("sti");
f0101934:	fb                   	sti    
}
f0101935:	eb b9                	jmp    f01018f0 <popcli+0x3f>

f0101937 <uvm_switch>:
//
// Switch TSS and h/w page table to correspond to process p.
//
void
uvm_switch(struct proc *p)
{
f0101937:	55                   	push   %ebp
f0101938:	89 e5                	mov    %esp,%ebp
f010193a:	57                   	push   %edi
f010193b:	56                   	push   %esi
f010193c:	53                   	push   %ebx
f010193d:	83 ec 0c             	sub    $0xc,%esp
	//
	// Hints:
	// - You may need pushcli() and popcli()
	// - You need to set TSS and ltr(SEG_TSS << 3)
	// - You need to switch to process's address space
	pushcli();
f0101940:	e8 1d ff ff ff       	call   f0101862 <pushcli>
	thiscpu->gdt[SEG_TSS] = SEG16(STS_T32A, &thiscpu->cpu_ts, sizeof(thiscpu->cpu_ts) - 1, 0);
f0101945:	e8 3a 0c 00 00       	call   f0102584 <cpunum>
f010194a:	89 c3                	mov    %eax,%ebx
f010194c:	e8 33 0c 00 00       	call   f0102584 <cpunum>
f0101951:	89 c7                	mov    %eax,%edi
f0101953:	e8 2c 0c 00 00       	call   f0102584 <cpunum>
f0101958:	89 c6                	mov    %eax,%esi
f010195a:	e8 25 0c 00 00       	call   f0102584 <cpunum>
f010195f:	69 db b8 00 00 00    	imul   $0xb8,%ebx,%ebx
f0101965:	8d 93 20 40 12 f0    	lea    -0xfedbfe0(%ebx),%edx
f010196b:	66 c7 83 bc 40 12 f0 	movw   $0x67,-0xfedbf44(%ebx)
f0101972:	67 00 
f0101974:	69 ff b8 00 00 00    	imul   $0xb8,%edi,%edi
f010197a:	81 c7 2c 40 12 f0    	add    $0xf012402c,%edi
f0101980:	66 89 bb be 40 12 f0 	mov    %di,-0xfedbf42(%ebx)
f0101987:	69 ce b8 00 00 00    	imul   $0xb8,%esi,%ecx
f010198d:	81 c1 2c 40 12 f0    	add    $0xf012402c,%ecx
f0101993:	c1 e9 10             	shr    $0x10,%ecx
f0101996:	88 8b c0 40 12 f0    	mov    %cl,-0xfedbf40(%ebx)
f010199c:	c6 83 c1 40 12 f0 99 	movb   $0x99,-0xfedbf3f(%ebx)
f01019a3:	c6 83 c2 40 12 f0 40 	movb   $0x40,-0xfedbf3e(%ebx)
f01019aa:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f01019b0:	05 2c 40 12 f0       	add    $0xf012402c,%eax
f01019b5:	c1 e8 18             	shr    $0x18,%eax
f01019b8:	88 82 a3 00 00 00    	mov    %al,0xa3(%edx)
	thiscpu->gdt[SEG_TSS].s = 0;
f01019be:	e8 c1 0b 00 00       	call   f0102584 <cpunum>
f01019c3:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f01019c9:	80 a0 c1 40 12 f0 ef 	andb   $0xef,-0xfedbf3f(%eax)
	thiscpu->cpu_ts.ss0 = SEG_KDATA << 3;
f01019d0:	e8 af 0b 00 00       	call   f0102584 <cpunum>
f01019d5:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f01019db:	66 c7 80 34 40 12 f0 	movw   $0x10,-0xfedbfcc(%eax)
f01019e2:	10 00 
	thiscpu->cpu_ts.esp0 = (uintptr_t)thiscpu->proc->kstack + KSTACKSIZE;
f01019e4:	e8 9b 0b 00 00       	call   f0102584 <cpunum>
f01019e9:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f01019ef:	8b 80 c4 40 12 f0    	mov    -0xfedbf3c(%eax),%eax
f01019f5:	8b 58 04             	mov    0x4(%eax),%ebx
f01019f8:	e8 87 0b 00 00       	call   f0102584 <cpunum>
f01019fd:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f0101a03:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0101a09:	89 98 30 40 12 f0    	mov    %ebx,-0xfedbfd0(%eax)
	thiscpu->cpu_ts.iomb = (uint16_t)0xFFFF;
f0101a0f:	e8 70 0b 00 00       	call   f0102584 <cpunum>
f0101a14:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f0101a1a:	66 c7 80 92 40 12 f0 	movw   $0xffff,-0xfedbf6e(%eax)
f0101a21:	ff ff 
	asm volatile("ltr %0" : : "r" (sel));
f0101a23:	b8 28 00 00 00       	mov    $0x28,%eax
f0101a28:	0f 00 d8             	ltr    %ax
	ltr(SEG_TSS << 3);
	lcr3(V2P(p->pgdir));
f0101a2b:	8b 45 08             	mov    0x8(%ebp),%eax
f0101a2e:	8b 00                	mov    (%eax),%eax
f0101a30:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0101a35:	0f 22 d8             	mov    %eax,%cr3
	popcli();
f0101a38:	e8 74 fe ff ff       	call   f01018b1 <popcli>
}
f0101a3d:	83 c4 0c             	add    $0xc,%esp
f0101a40:	5b                   	pop    %ebx
f0101a41:	5e                   	pop    %esi
f0101a42:	5f                   	pop    %edi
f0101a43:	5d                   	pop    %ebp
f0101a44:	c3                   	ret    

f0101a45 <pow_2>:
// the pages mapped by entrypgdir on free list.
// 2. Call alloc_init() with the rest of the physical pages after
// installing a full page table.

int pow_2(int power)
{
f0101a45:	55                   	push   %ebp
f0101a46:	89 e5                	mov    %esp,%ebp
f0101a48:	8b 4d 08             	mov    0x8(%ebp),%ecx
	int num = 1;
	for (int i = 0; i < power; i++)
f0101a4b:	ba 00 00 00 00       	mov    $0x0,%edx
	int num = 1;
f0101a50:	b8 01 00 00 00       	mov    $0x1,%eax
	for (int i = 0; i < power; i++)
f0101a55:	eb 05                	jmp    f0101a5c <pow_2+0x17>
		num *= 2;
f0101a57:	01 c0                	add    %eax,%eax
	for (int i = 0; i < power; i++)
f0101a59:	83 c2 01             	add    $0x1,%edx
f0101a5c:	39 ca                	cmp    %ecx,%edx
f0101a5e:	7c f7                	jl     f0101a57 <pow_2+0x12>
	return num;
}
f0101a60:	5d                   	pop    %ebp
f0101a61:	c3                   	ret    

f0101a62 <Buddykfree>:
	kmem.free_list = r;*/
}

void
Buddykfree(char *v)
{
f0101a62:	55                   	push   %ebp
f0101a63:	89 e5                	mov    %esp,%ebp
f0101a65:	57                   	push   %edi
f0101a66:	56                   	push   %esi
f0101a67:	53                   	push   %ebx
f0101a68:	83 ec 2c             	sub    $0x2c,%esp
	struct run *r;

	if ((uint32_t)v % PGSIZE || v < end || V2P(v) >= PHYSTOP)
f0101a6b:	8b 45 08             	mov    0x8(%ebp),%eax
f0101a6e:	a9 ff 0f 00 00       	test   $0xfff,%eax
f0101a73:	75 56                	jne    f0101acb <Buddykfree+0x69>
f0101a75:	3d 54 57 16 f0       	cmp    $0xf0165754,%eax
f0101a7a:	72 4f                	jb     f0101acb <Buddykfree+0x69>
f0101a7c:	05 00 00 00 10       	add    $0x10000000,%eax
f0101a81:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
f0101a86:	77 43                	ja     f0101acb <Buddykfree+0x69>
		panic("kfree");
	int idx, id;
	id = (void *)v >= (void *)base[1];
f0101a88:	8b 45 08             	mov    0x8(%ebp),%eax
f0101a8b:	39 05 a4 3e 12 f0    	cmp    %eax,0xf0123ea4
f0101a91:	0f 96 45 cb          	setbe  -0x35(%ebp)
f0101a95:	0f b6 45 cb          	movzbl -0x35(%ebp),%eax
f0101a99:	0f b6 f0             	movzbl %al,%esi
	//cprintf("minus: %x, num: %x,idx: %x\n", (void *)v - (void *)base[0], (uint32_t)((void *)v - (void *)base[0]) / PGSIZE, idx);
	idx = (uint32_t)((void *)v - (void *)base[id]) / PGSIZE;
f0101a9c:	8b 45 08             	mov    0x8(%ebp),%eax
f0101a9f:	2b 04 b5 a0 3e 12 f0 	sub    -0xfedc160(,%esi,4),%eax
f0101aa6:	c1 e8 0c             	shr    $0xc,%eax
f0101aa9:	89 45 cc             	mov    %eax,-0x34(%ebp)
	int p = idx;
	int count = 0;
	//cprintf("v: %x, idx: %x, p: %x\n", v, idx, p);
	if (Buddy[id].use_lock)
f0101aac:	6b c6 3c             	imul   $0x3c,%esi,%eax
f0101aaf:	83 b8 c0 3e 12 f0 00 	cmpl   $0x0,-0xfedc140(%eax)
f0101ab6:	75 2a                	jne    f0101ae2 <Buddykfree+0x80>
		spin_lock(&Buddy[id].lock);
	while (order[id][p] != 1) {
f0101ab8:	8b 3c b5 40 3f 12 f0 	mov    -0xfedc0c0(,%esi,4),%edi
f0101abf:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101ac2:	89 c3                	mov    %eax,%ebx
f0101ac4:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101ac9:	eb 3e                	jmp    f0101b09 <Buddykfree+0xa7>
		panic("kfree");
f0101acb:	83 ec 04             	sub    $0x4,%esp
f0101ace:	68 40 40 10 f0       	push   $0xf0104040
f0101ad3:	68 e3 00 00 00       	push   $0xe3
f0101ad8:	68 46 40 10 f0       	push   $0xf0104046
f0101add:	e8 bd e6 ff ff       	call   f010019f <_panic>
		spin_lock(&Buddy[id].lock);
f0101ae2:	83 ec 0c             	sub    $0xc,%esp
f0101ae5:	6b c6 3c             	imul   $0x3c,%esi,%eax
f0101ae8:	05 c8 3e 12 f0       	add    $0xf0123ec8,%eax
f0101aed:	50                   	push   %eax
f0101aee:	e8 e9 0c 00 00       	call   f01027dc <spin_lock>
f0101af3:	83 c4 10             	add    $0x10,%esp
f0101af6:	eb c0                	jmp    f0101ab8 <Buddykfree+0x56>
		count++;
f0101af8:	83 c1 01             	add    $0x1,%ecx
		p = start[id][count] + (idx >> count);
f0101afb:	8b 14 b5 48 3f 12 f0 	mov    -0xfedc0b8(,%esi,4),%edx
f0101b02:	89 c3                	mov    %eax,%ebx
f0101b04:	d3 fb                	sar    %cl,%ebx
f0101b06:	03 1c 8a             	add    (%edx,%ecx,4),%ebx
	while (order[id][p] != 1) {
f0101b09:	80 3c 1f 00          	cmpb   $0x0,(%edi,%ebx,1)
f0101b0d:	74 e9                	je     f0101af8 <Buddykfree+0x96>
f0101b0f:	89 5d e0             	mov    %ebx,-0x20(%ebp)
f0101b12:	89 cf                	mov    %ecx,%edi
f0101b14:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	}
	//cprintf("p: %x\n", p);
	memset(v, 1, PGSIZE * pow_2(count));
f0101b17:	83 ec 0c             	sub    $0xc,%esp
f0101b1a:	51                   	push   %ecx
f0101b1b:	e8 25 ff ff ff       	call   f0101a45 <pow_2>
f0101b20:	83 c4 0c             	add    $0xc,%esp
f0101b23:	c1 e0 0c             	shl    $0xc,%eax
f0101b26:	50                   	push   %eax
f0101b27:	6a 01                	push   $0x1
f0101b29:	ff 75 08             	pushl  0x8(%ebp)
f0101b2c:	e8 87 1c 00 00       	call   f01037b8 <memset>
	order[id][p] = 0;
f0101b31:	8b 04 b5 40 3f 12 f0 	mov    -0xfedc0c0(,%esi,4),%eax
f0101b38:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0101b3b:	c6 04 10 00          	movb   $0x0,(%eax,%edx,1)
	int buddy = p ^ 1;
f0101b3f:	89 d8                	mov    %ebx,%eax
f0101b41:	83 f0 01             	xor    $0x1,%eax
	int mark = 1 << (count + 12);
f0101b44:	8d 4f 0c             	lea    0xc(%edi),%ecx
f0101b47:	ba 01 00 00 00       	mov    $0x1,%edx
f0101b4c:	d3 e2                	shl    %cl,%edx
f0101b4e:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101b51:	8d 14 fd 00 00 00 00 	lea    0x0(,%edi,8),%edx
f0101b58:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0101b5b:	8d 3c bd 04 00 00 00 	lea    0x4(,%edi,4),%edi
f0101b62:	89 7d d8             	mov    %edi,-0x28(%ebp)
	char *buddypos;
	while (count < MAX_ORDER[id] && order[id][buddy] == 0) {
f0101b65:	83 c4 10             	add    $0x10,%esp
		//cprintf("p: %x, buddy: %x\n", p, buddy);
		buddypos = (char *)base[id] + ((uint32_t)(v - (char *)base[id]) ^ mark);
		//cprintf("buddypos: %x, mark: %x\n", buddypos, mark);
		struct run *iter = Buddy[id].slot[count].free_list;
f0101b68:	6b d6 3c             	imul   $0x3c,%esi,%edx
f0101b6b:	8d ba c0 3e 12 f0    	lea    -0xfedc140(%edx),%edi
f0101b71:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0101b74:	89 f7                	mov    %esi,%edi
	while (count < MAX_ORDER[id] && order[id][buddy] == 0) {
f0101b76:	eb 72                	jmp    f0101bea <Buddykfree+0x188>
		while (iter->next != (struct run *)buddypos && iter->next != Buddy[id].slot[count].free_list)
f0101b78:	89 c2                	mov    %eax,%edx
f0101b7a:	8b 02                	mov    (%edx),%eax
f0101b7c:	39 f0                	cmp    %esi,%eax
f0101b7e:	0f 95 c3             	setne  %bl
f0101b81:	39 f8                	cmp    %edi,%eax
f0101b83:	0f 95 c1             	setne  %cl
f0101b86:	84 cb                	test   %cl,%bl
f0101b88:	75 ee                	jne    f0101b78 <Buddykfree+0x116>
f0101b8a:	8b 7d d0             	mov    -0x30(%ebp),%edi
		// buddy is occupied
		// have little change
		//if (iter->next != (struct run *)buddypos)
		//	break;
		struct run *uni = iter->next;
		iter->next = uni->next;
f0101b8d:	8b 08                	mov    (%eax),%ecx
f0101b8f:	89 0a                	mov    %ecx,(%edx)
		Buddy[id].slot[count].num--;
f0101b91:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101b94:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0101b97:	89 f1                	mov    %esi,%ecx
f0101b99:	03 4b 04             	add    0x4(%ebx),%ecx
f0101b9c:	83 69 04 01          	subl   $0x1,0x4(%ecx)
		Buddy[id].slot[count].free_list = iter->next;
f0101ba0:	8b 0a                	mov    (%edx),%ecx
f0101ba2:	8b 53 04             	mov    0x4(%ebx),%edx
f0101ba5:	89 0c 32             	mov    %ecx,(%edx,%esi,1)
		v = (v > (char *)uni) ? (char *)uni : v;
f0101ba8:	39 45 08             	cmp    %eax,0x8(%ebp)
f0101bab:	0f 46 45 08          	cmovbe 0x8(%ebp),%eax
f0101baf:	89 45 08             	mov    %eax,0x8(%ebp)
		count++;
f0101bb2:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
f0101bb6:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		mark <<= 1;
f0101bb9:	d1 65 dc             	shll   -0x24(%ebp)
		p = start[id][count] + (idx >> count);
f0101bbc:	8b 14 bd 48 3f 12 f0 	mov    -0xfedc0b8(,%edi,4),%edx
f0101bc3:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101bc6:	89 d9                	mov    %ebx,%ecx
f0101bc8:	d3 f8                	sar    %cl,%eax
f0101bca:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0101bcd:	03 04 1a             	add    (%edx,%ebx,1),%eax
		//cprintf("order: %d, p: %x\n", order[id][p], p);
		order[id][p] = 0;
f0101bd0:	8b 14 bd 40 3f 12 f0 	mov    -0xfedc0c0(,%edi,4),%edx
f0101bd7:	c6 04 02 00          	movb   $0x0,(%edx,%eax,1)
		//cprintf("order: %d\n", order[id][p]);
		buddy = p ^ 1;
f0101bdb:	83 f0 01             	xor    $0x1,%eax
f0101bde:	83 c6 08             	add    $0x8,%esi
f0101be1:	89 75 e0             	mov    %esi,-0x20(%ebp)
f0101be4:	83 c3 04             	add    $0x4,%ebx
f0101be7:	89 5d d8             	mov    %ebx,-0x28(%ebp)
	while (count < MAX_ORDER[id] && order[id][buddy] == 0) {
f0101bea:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101bed:	39 0c bd 50 3f 12 f0 	cmp    %ecx,-0xfedc0b0(,%edi,4)
f0101bf4:	7e 37                	jle    f0101c2d <Buddykfree+0x1cb>
f0101bf6:	8b 14 bd 40 3f 12 f0 	mov    -0xfedc0c0(,%edi,4),%edx
f0101bfd:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101c01:	75 2a                	jne    f0101c2d <Buddykfree+0x1cb>
		buddypos = (char *)base[id] + ((uint32_t)(v - (char *)base[id]) ^ mark);
f0101c03:	8b 04 bd a0 3e 12 f0 	mov    -0xfedc160(,%edi,4),%eax
f0101c0a:	8b 75 08             	mov    0x8(%ebp),%esi
f0101c0d:	29 c6                	sub    %eax,%esi
f0101c0f:	33 75 dc             	xor    -0x24(%ebp),%esi
f0101c12:	8d 0c 30             	lea    (%eax,%esi,1),%ecx
		struct run *iter = Buddy[id].slot[count].free_list;
f0101c15:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101c18:	8b 40 04             	mov    0x4(%eax),%eax
f0101c1b:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0101c1e:	8b 34 30             	mov    (%eax,%esi,1),%esi
f0101c21:	89 f2                	mov    %esi,%edx
f0101c23:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0101c26:	89 cf                	mov    %ecx,%edi
		while (iter->next != (struct run *)buddypos && iter->next != Buddy[id].slot[count].free_list)
f0101c28:	e9 4d ff ff ff       	jmp    f0101b7a <Buddykfree+0x118>
	}
	r = (struct run *)v;
	r->next = Buddy[id].slot[count].free_list->next;
f0101c2d:	6b d7 3c             	imul   $0x3c,%edi,%edx
f0101c30:	8b 8a c4 3e 12 f0    	mov    -0xfedc13c(%edx),%ecx
f0101c36:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101c39:	8b 0c f9             	mov    (%ecx,%edi,8),%ecx
f0101c3c:	8b 09                	mov    (%ecx),%ecx
f0101c3e:	8b 75 08             	mov    0x8(%ebp),%esi
f0101c41:	89 0e                	mov    %ecx,(%esi)
	Buddy[id].slot[count].free_list->next = r;
f0101c43:	8b 8a c4 3e 12 f0    	mov    -0xfedc13c(%edx),%ecx
f0101c49:	8b 0c f9             	mov    (%ecx,%edi,8),%ecx
f0101c4c:	89 31                	mov    %esi,(%ecx)
	Buddy[id].slot[count].num++;
f0101c4e:	8b 82 c4 3e 12 f0    	mov    -0xfedc13c(%edx),%eax
f0101c54:	83 44 f8 04 01       	addl   $0x1,0x4(%eax,%edi,8)
	if (Buddy[id].use_lock)
f0101c59:	83 ba c0 3e 12 f0 00 	cmpl   $0x0,-0xfedc140(%edx)
f0101c60:	75 08                	jne    f0101c6a <Buddykfree+0x208>
		spin_unlock(&Buddy[id].lock);
}
f0101c62:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101c65:	5b                   	pop    %ebx
f0101c66:	5e                   	pop    %esi
f0101c67:	5f                   	pop    %edi
f0101c68:	5d                   	pop    %ebp
f0101c69:	c3                   	ret    
		spin_unlock(&Buddy[id].lock);
f0101c6a:	83 ec 0c             	sub    $0xc,%esp
f0101c6d:	0f b6 45 cb          	movzbl -0x35(%ebp),%eax
f0101c71:	6b c0 3c             	imul   $0x3c,%eax,%eax
f0101c74:	05 c8 3e 12 f0       	add    $0xf0123ec8,%eax
f0101c79:	50                   	push   %eax
f0101c7a:	e8 1c 0c 00 00       	call   f010289b <spin_unlock>
f0101c7f:	83 c4 10             	add    $0x10,%esp
}
f0101c82:	eb de                	jmp    f0101c62 <Buddykfree+0x200>

f0101c84 <kfree>:
{
f0101c84:	55                   	push   %ebp
f0101c85:	89 e5                	mov    %esp,%ebp
f0101c87:	83 ec 14             	sub    $0x14,%esp
	Buddykfree(v);
f0101c8a:	ff 75 08             	pushl  0x8(%ebp)
f0101c8d:	e8 d0 fd ff ff       	call   f0101a62 <Buddykfree>
}
f0101c92:	83 c4 10             	add    $0x10,%esp
f0101c95:	c9                   	leave  
f0101c96:	c3                   	ret    

f0101c97 <free_range>:

void
free_range(void *vstart, void *vend)
{
f0101c97:	55                   	push   %ebp
f0101c98:	89 e5                	mov    %esp,%ebp
f0101c9a:	56                   	push   %esi
f0101c9b:	53                   	push   %ebx
f0101c9c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *p;
	p = ROUNDUP((char *)vstart, PGSIZE);
f0101c9f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101ca2:	05 ff 0f 00 00       	add    $0xfff,%eax
f0101ca7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	for (; p + PGSIZE <= (char *)vend; p += PGSIZE)
f0101cac:	eb 0e                	jmp    f0101cbc <free_range+0x25>
	Buddykfree(v);
f0101cae:	83 ec 0c             	sub    $0xc,%esp
f0101cb1:	50                   	push   %eax
f0101cb2:	e8 ab fd ff ff       	call   f0101a62 <Buddykfree>
	for (; p + PGSIZE <= (char *)vend; p += PGSIZE)
f0101cb7:	83 c4 10             	add    $0x10,%esp
f0101cba:	89 f0                	mov    %esi,%eax
f0101cbc:	8d b0 00 10 00 00    	lea    0x1000(%eax),%esi
f0101cc2:	39 de                	cmp    %ebx,%esi
f0101cc4:	76 e8                	jbe    f0101cae <free_range+0x17>
		kfree(p);
}
f0101cc6:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0101cc9:	5b                   	pop    %ebx
f0101cca:	5e                   	pop    %esi
f0101ccb:	5d                   	pop    %ebp
f0101ccc:	c3                   	ret    

f0101ccd <Buddyfree_range>:

void
Buddyfree_range(void *vstart, int level)
{
f0101ccd:	55                   	push   %ebp
f0101cce:	89 e5                	mov    %esp,%ebp
f0101cd0:	57                   	push   %edi
f0101cd1:	56                   	push   %esi
f0101cd2:	53                   	push   %ebx
f0101cd3:	83 ec 0c             	sub    $0xc,%esp
f0101cd6:	8b 75 08             	mov    0x8(%ebp),%esi
f0101cd9:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	struct run *r;
	int id = ((void *)vstart >= (void *)base[1]) ? 1 : 0;
f0101cdc:	39 35 a4 3e 12 f0    	cmp    %esi,0xf0123ea4
f0101ce2:	0f 96 c0             	setbe  %al
f0101ce5:	0f b6 c0             	movzbl %al,%eax
f0101ce8:	89 c7                	mov    %eax,%edi

	memset(vstart, 1, PGSIZE * pow_2(level));
f0101cea:	53                   	push   %ebx
f0101ceb:	e8 55 fd ff ff       	call   f0101a45 <pow_2>
f0101cf0:	c1 e0 0c             	shl    $0xc,%eax
f0101cf3:	50                   	push   %eax
f0101cf4:	6a 01                	push   $0x1
f0101cf6:	56                   	push   %esi
f0101cf7:	e8 bc 1a 00 00       	call   f01037b8 <memset>
	r = (struct run *)vstart;
	//cprintf("%x, %x\n", Buddy[id][level].free_list->next, Buddy[id][level].free_list);
	r->next = Buddy[id].slot[level].free_list->next;
f0101cfc:	6b c7 3c             	imul   $0x3c,%edi,%eax
f0101cff:	8b 90 c4 3e 12 f0    	mov    -0xfedc13c(%eax),%edx
f0101d05:	8b 14 da             	mov    (%edx,%ebx,8),%edx
f0101d08:	8b 12                	mov    (%edx),%edx
f0101d0a:	89 16                	mov    %edx,(%esi)
	Buddy[id].slot[level].free_list->next = r;
f0101d0c:	8b 90 c4 3e 12 f0    	mov    -0xfedc13c(%eax),%edx
	r->next = Buddy[id].slot[level].free_list->next;
f0101d12:	05 c0 3e 12 f0       	add    $0xf0123ec0,%eax
	Buddy[id].slot[level].free_list->next = r;
f0101d17:	8b 14 da             	mov    (%edx,%ebx,8),%edx
f0101d1a:	89 32                	mov    %esi,(%edx)
	//cprintf("%x, %x\n", Buddy[id][level].free_list->next, Buddy[id][level].free_list);
	Buddy[id].slot[level].num++;
f0101d1c:	8b 40 04             	mov    0x4(%eax),%eax
f0101d1f:	83 44 d8 04 01       	addl   $0x1,0x4(%eax,%ebx,8)
}
f0101d24:	83 c4 10             	add    $0x10,%esp
f0101d27:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101d2a:	5b                   	pop    %ebx
f0101d2b:	5e                   	pop    %esi
f0101d2c:	5f                   	pop    %edi
f0101d2d:	5d                   	pop    %ebp
f0101d2e:	c3                   	ret    

f0101d2f <split>:
		return NULL;*/
}

void
split(char *r, int low, int high)
{
f0101d2f:	55                   	push   %ebp
f0101d30:	89 e5                	mov    %esp,%ebp
f0101d32:	57                   	push   %edi
f0101d33:	56                   	push   %esi
f0101d34:	53                   	push   %ebx
f0101d35:	83 ec 10             	sub    $0x10,%esp
f0101d38:	8b 4d 10             	mov    0x10(%ebp),%ecx
	int size = 1 << high;
f0101d3b:	b8 01 00 00 00       	mov    $0x1,%eax
f0101d40:	d3 e0                	shl    %cl,%eax
f0101d42:	89 45 f0             	mov    %eax,-0x10(%ebp)
	int id, idx;
	id = (void *)r >= (void *)base[1];
f0101d45:	8b 45 08             	mov    0x8(%ebp),%eax
f0101d48:	39 05 a4 3e 12 f0    	cmp    %eax,0xf0123ea4
f0101d4e:	0f 96 c0             	setbe  %al
f0101d51:	0f b6 c0             	movzbl %al,%eax
f0101d54:	89 c6                	mov    %eax,%esi
	idx = (uint32_t)((void *)r - (void *)base[id]) / PGSIZE;
f0101d56:	8b 45 08             	mov    0x8(%ebp),%eax
f0101d59:	2b 04 b5 a0 3e 12 f0 	sub    -0xfedc160(,%esi,4),%eax
f0101d60:	c1 e8 0c             	shr    $0xc,%eax
f0101d63:	89 45 e8             	mov    %eax,-0x18(%ebp)
f0101d66:	8d 04 8d 00 00 00 00 	lea    0x0(,%ecx,4),%eax
f0101d6d:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101d70:	8d 04 cd f8 ff ff ff 	lea    -0x8(,%ecx,8),%eax
		//cprintf("high: %x, pos: %x\n", high, start[high] + (idx >> high));
		high--;
		size >>= 1;
		struct run *p = (struct run *)((uint32_t)r + PGSIZE * size);
		//add high
		p->next = Buddy[id].slot[high].free_list->next;
f0101d77:	6b de 3c             	imul   $0x3c,%esi,%ebx
f0101d7a:	81 c3 c0 3e 12 f0    	add    $0xf0123ec0,%ebx
f0101d80:	89 75 e4             	mov    %esi,-0x1c(%ebp)
	while (high > low) {
f0101d83:	eb 54                	jmp    f0101dd9 <split+0xaa>
		order[id][start[id][high] + (idx >> high)] = 1;
f0101d85:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101d88:	8b 3c b5 48 3f 12 f0 	mov    -0xfedc0b8(,%esi,4),%edi
f0101d8f:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0101d92:	d3 fa                	sar    %cl,%edx
f0101d94:	03 14 b5 40 3f 12 f0 	add    -0xfedc0c0(,%esi,4),%edx
f0101d9b:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0101d9e:	03 14 37             	add    (%edi,%esi,1),%edx
f0101da1:	c6 02 01             	movb   $0x1,(%edx)
		high--;
f0101da4:	83 e9 01             	sub    $0x1,%ecx
		size >>= 1;
f0101da7:	d1 7d f0             	sarl   -0x10(%ebp)
f0101daa:	8b 7d f0             	mov    -0x10(%ebp),%edi
		struct run *p = (struct run *)((uint32_t)r + PGSIZE * size);
f0101dad:	89 fa                	mov    %edi,%edx
f0101daf:	c1 e2 0c             	shl    $0xc,%edx
f0101db2:	03 55 08             	add    0x8(%ebp),%edx
		p->next = Buddy[id].slot[high].free_list->next;
f0101db5:	8b 7b 04             	mov    0x4(%ebx),%edi
f0101db8:	8b 3c 07             	mov    (%edi,%eax,1),%edi
f0101dbb:	8b 3f                	mov    (%edi),%edi
f0101dbd:	89 3a                	mov    %edi,(%edx)
		Buddy[id].slot[high].free_list->next = p;
f0101dbf:	8b 7b 04             	mov    0x4(%ebx),%edi
f0101dc2:	8b 3c 07             	mov    (%edi,%eax,1),%edi
f0101dc5:	89 17                	mov    %edx,(%edi)
		Buddy[id].slot[high].num++;
f0101dc7:	89 c2                	mov    %eax,%edx
f0101dc9:	03 53 04             	add    0x4(%ebx),%edx
f0101dcc:	83 42 04 01          	addl   $0x1,0x4(%edx)
f0101dd0:	83 ee 04             	sub    $0x4,%esi
f0101dd3:	89 75 ec             	mov    %esi,-0x14(%ebp)
f0101dd6:	83 e8 08             	sub    $0x8,%eax
	while (high > low) {
f0101dd9:	3b 4d 0c             	cmp    0xc(%ebp),%ecx
f0101ddc:	7f a7                	jg     f0101d85 <split+0x56>
f0101dde:	8b 75 e4             	mov    -0x1c(%ebp),%esi
	}
	order[id][start[id][high] + (idx >> high)] = 1;
f0101de1:	8b 14 b5 48 3f 12 f0 	mov    -0xfedc0b8(,%esi,4),%edx
f0101de8:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0101deb:	d3 f8                	sar    %cl,%eax
f0101ded:	03 04 b5 40 3f 12 f0 	add    -0xfedc0c0(,%esi,4),%eax
f0101df4:	03 04 8a             	add    (%edx,%ecx,4),%eax
f0101df7:	c6 00 01             	movb   $0x1,(%eax)
	//cprintf("pos: %x\n", start[id][high] + (idx >> high));
}
f0101dfa:	83 c4 10             	add    $0x10,%esp
f0101dfd:	5b                   	pop    %ebx
f0101dfe:	5e                   	pop    %esi
f0101dff:	5f                   	pop    %edi
f0101e00:	5d                   	pop    %ebp
f0101e01:	c3                   	ret    

f0101e02 <Buddykalloc>:

char *
Buddykalloc(int order)
{
f0101e02:	55                   	push   %ebp
f0101e03:	89 e5                	mov    %esp,%ebp
f0101e05:	57                   	push   %edi
f0101e06:	56                   	push   %esi
f0101e07:	53                   	push   %ebx
f0101e08:	83 ec 1c             	sub    $0x1c,%esp
	for (int i = 0; i < 2; i++) {
		if (Buddy[i].use_lock)
f0101e0b:	83 3d c0 3e 12 f0 00 	cmpl   $0x0,0xf0123ec0
f0101e12:	75 36                	jne    f0101e4a <Buddykalloc+0x48>
			spin_lock(&Buddy[i].lock);
		for (int currentorder = order; currentorder <= MAX_ORDER[i]; currentorder++)
f0101e14:	8b 35 50 3f 12 f0    	mov    0xf0123f50,%esi
f0101e1a:	8b 45 08             	mov    0x8(%ebp),%eax
f0101e1d:	8d 1c c5 00 00 00 00 	lea    0x0(,%eax,8),%ebx
			if (Buddy[i].slot[currentorder].num > 0) {
f0101e24:	8b 3d c4 3e 12 f0    	mov    0xf0123ec4,%edi
f0101e2a:	89 da                	mov    %ebx,%edx
		for (int currentorder = order; currentorder <= MAX_ORDER[i]; currentorder++)
f0101e2c:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0101e2f:	39 c6                	cmp    %eax,%esi
f0101e31:	7c 29                	jl     f0101e5c <Buddykalloc+0x5a>
			if (Buddy[i].slot[currentorder].num > 0) {
f0101e33:	8d 0c 17             	lea    (%edi,%edx,1),%ecx
f0101e36:	8d 5a 08             	lea    0x8(%edx),%ebx
f0101e39:	83 79 04 00          	cmpl   $0x0,0x4(%ecx)
f0101e3d:	0f 8f 84 00 00 00    	jg     f0101ec7 <Buddykalloc+0xc5>
		for (int currentorder = order; currentorder <= MAX_ORDER[i]; currentorder++)
f0101e43:	83 c0 01             	add    $0x1,%eax
f0101e46:	89 da                	mov    %ebx,%edx
f0101e48:	eb e5                	jmp    f0101e2f <Buddykalloc+0x2d>
			spin_lock(&Buddy[i].lock);
f0101e4a:	83 ec 0c             	sub    $0xc,%esp
f0101e4d:	68 c8 3e 12 f0       	push   $0xf0123ec8
f0101e52:	e8 85 09 00 00       	call   f01027dc <spin_lock>
f0101e57:	83 c4 10             	add    $0x10,%esp
f0101e5a:	eb b8                	jmp    f0101e14 <Buddykalloc+0x12>
f0101e5c:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
				split((char *)r, order, currentorder);
				if (Buddy[i].use_lock)
					spin_unlock(&Buddy[i].lock);
				return (char *)r;
			}
		if (Buddy[i].use_lock)
f0101e5f:	83 3d c0 3e 12 f0 00 	cmpl   $0x0,0xf0123ec0
f0101e66:	75 32                	jne    f0101e9a <Buddykalloc+0x98>
		if (Buddy[i].use_lock)
f0101e68:	83 3d fc 3e 12 f0 00 	cmpl   $0x0,0xf0123efc
f0101e6f:	75 3b                	jne    f0101eac <Buddykalloc+0xaa>
		for (int currentorder = order; currentorder <= MAX_ORDER[i]; currentorder++)
f0101e71:	8b 35 54 3f 12 f0    	mov    0xf0123f54,%esi
f0101e77:	8b 45 08             	mov    0x8(%ebp),%eax
f0101e7a:	39 c6                	cmp    %eax,%esi
f0101e7c:	0f 8c 98 00 00 00    	jl     f0101f1a <Buddykalloc+0x118>
			if (Buddy[i].slot[currentorder].num > 0) {
f0101e82:	89 d9                	mov    %ebx,%ecx
f0101e84:	03 0d 00 3f 12 f0    	add    0xf0123f00,%ecx
f0101e8a:	8d 53 08             	lea    0x8(%ebx),%edx
f0101e8d:	83 79 04 00          	cmpl   $0x0,0x4(%ecx)
f0101e91:	7f 2b                	jg     f0101ebe <Buddykalloc+0xbc>
		for (int currentorder = order; currentorder <= MAX_ORDER[i]; currentorder++)
f0101e93:	83 c0 01             	add    $0x1,%eax
f0101e96:	89 d3                	mov    %edx,%ebx
f0101e98:	eb e0                	jmp    f0101e7a <Buddykalloc+0x78>
			spin_unlock(&Buddy[i].lock);
f0101e9a:	83 ec 0c             	sub    $0xc,%esp
f0101e9d:	68 c8 3e 12 f0       	push   $0xf0123ec8
f0101ea2:	e8 f4 09 00 00       	call   f010289b <spin_unlock>
f0101ea7:	83 c4 10             	add    $0x10,%esp
f0101eaa:	eb bc                	jmp    f0101e68 <Buddykalloc+0x66>
			spin_lock(&Buddy[i].lock);
f0101eac:	83 ec 0c             	sub    $0xc,%esp
f0101eaf:	68 04 3f 12 f0       	push   $0xf0123f04
f0101eb4:	e8 23 09 00 00       	call   f01027dc <spin_lock>
f0101eb9:	83 c4 10             	add    $0x10,%esp
f0101ebc:	eb b3                	jmp    f0101e71 <Buddykalloc+0x6f>
			if (Buddy[i].slot[currentorder].num > 0) {
f0101ebe:	89 da                	mov    %ebx,%edx
	for (int i = 0; i < 2; i++) {
f0101ec0:	bf 01 00 00 00       	mov    $0x1,%edi
f0101ec5:	eb 05                	jmp    f0101ecc <Buddykalloc+0xca>
f0101ec7:	bf 00 00 00 00       	mov    $0x0,%edi
				r = Buddy[i].slot[currentorder].free_list->next;
f0101ecc:	8b 09                	mov    (%ecx),%ecx
f0101ece:	8b 19                	mov    (%ecx),%ebx
				Buddy[i].slot[currentorder].free_list->next = r->next;
f0101ed0:	8b 33                	mov    (%ebx),%esi
f0101ed2:	89 31                	mov    %esi,(%ecx)
				Buddy[i].slot[currentorder].num--;
f0101ed4:	6b f7 3c             	imul   $0x3c,%edi,%esi
f0101ed7:	03 96 c4 3e 12 f0    	add    -0xfedc13c(%esi),%edx
f0101edd:	83 6a 04 01          	subl   $0x1,0x4(%edx)
				split((char *)r, order, currentorder);
f0101ee1:	83 ec 04             	sub    $0x4,%esp
f0101ee4:	50                   	push   %eax
f0101ee5:	ff 75 08             	pushl  0x8(%ebp)
f0101ee8:	53                   	push   %ebx
f0101ee9:	e8 41 fe ff ff       	call   f0101d2f <split>
				if (Buddy[i].use_lock)
f0101eee:	83 c4 10             	add    $0x10,%esp
f0101ef1:	83 be c0 3e 12 f0 00 	cmpl   $0x0,-0xfedc140(%esi)
f0101ef8:	75 0a                	jne    f0101f04 <Buddykalloc+0x102>
	}
	return NULL;
}
f0101efa:	89 d8                	mov    %ebx,%eax
f0101efc:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101eff:	5b                   	pop    %ebx
f0101f00:	5e                   	pop    %esi
f0101f01:	5f                   	pop    %edi
f0101f02:	5d                   	pop    %ebp
f0101f03:	c3                   	ret    
					spin_unlock(&Buddy[i].lock);
f0101f04:	83 ec 0c             	sub    $0xc,%esp
f0101f07:	89 f7                	mov    %esi,%edi
f0101f09:	81 c7 c8 3e 12 f0    	add    $0xf0123ec8,%edi
f0101f0f:	57                   	push   %edi
f0101f10:	e8 86 09 00 00       	call   f010289b <spin_unlock>
f0101f15:	83 c4 10             	add    $0x10,%esp
f0101f18:	eb e0                	jmp    f0101efa <Buddykalloc+0xf8>
		if (Buddy[i].use_lock)
f0101f1a:	83 3d fc 3e 12 f0 00 	cmpl   $0x0,0xf0123efc
f0101f21:	75 07                	jne    f0101f2a <Buddykalloc+0x128>
	return NULL;
f0101f23:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101f28:	eb d0                	jmp    f0101efa <Buddykalloc+0xf8>
			spin_unlock(&Buddy[i].lock);
f0101f2a:	83 ec 0c             	sub    $0xc,%esp
f0101f2d:	68 04 3f 12 f0       	push   $0xf0123f04
f0101f32:	e8 64 09 00 00       	call   f010289b <spin_unlock>
f0101f37:	83 c4 10             	add    $0x10,%esp
f0101f3a:	eb e7                	jmp    f0101f23 <Buddykalloc+0x121>

f0101f3c <kalloc>:
{
f0101f3c:	55                   	push   %ebp
f0101f3d:	89 e5                	mov    %esp,%ebp
f0101f3f:	83 ec 14             	sub    $0x14,%esp
	return Buddykalloc(0);
f0101f42:	6a 00                	push   $0x0
f0101f44:	e8 b9 fe ff ff       	call   f0101e02 <Buddykalloc>
}
f0101f49:	c9                   	leave  
f0101f4a:	c3                   	ret    

f0101f4b <check_free_list>:
void
check_free_list(void)
{
	struct run *p;
	bool exist;
	for (int i = 0; i < 2; i++)
f0101f4b:	ba 00 00 00 00       	mov    $0x0,%edx
		for (int j = 0; j <= MAX_ORDER[i]; j++)
f0101f50:	b8 00 00 00 00       	mov    $0x0,%eax
f0101f55:	eb 03                	jmp    f0101f5a <check_free_list+0xf>
f0101f57:	83 c0 01             	add    $0x1,%eax
f0101f5a:	39 04 95 50 3f 12 f0 	cmp    %eax,-0xfedc0b0(,%edx,4)
f0101f61:	7d f4                	jge    f0101f57 <check_free_list+0xc>
	for (int i = 0; i < 2; i++)
f0101f63:	83 c2 01             	add    $0x1,%edx
f0101f66:	83 fa 01             	cmp    $0x1,%edx
f0101f69:	7f 39                	jg     f0101fa4 <check_free_list+0x59>
		for (int j = 0; j <= MAX_ORDER[i]; j++)
f0101f6b:	b8 00 00 00 00       	mov    $0x0,%eax
f0101f70:	eb e8                	jmp    f0101f5a <check_free_list+0xf>

	//cprintf("end: 0x%x\n", end);

	for (p = kmem.free_list; p; p = p->next) {
		//cprintf("0x%x\n", p);
		assert((void *)p > (void *)end);
f0101f72:	68 54 40 10 f0       	push   $0xf0104054
f0101f77:	68 92 3f 10 f0       	push   $0xf0103f92
f0101f7c:	68 89 01 00 00       	push   $0x189
f0101f81:	68 46 40 10 f0       	push   $0xf0104046
f0101f86:	e8 14 e2 ff ff       	call   f010019f <_panic>
		for (int i = 4; i < 4096; i++) 
			assert(((char *)p)[i] == 1);
f0101f8b:	68 6c 40 10 f0       	push   $0xf010406c
f0101f90:	68 92 3f 10 f0       	push   $0xf0103f92
f0101f95:	68 8b 01 00 00       	push   $0x18b
f0101f9a:	68 46 40 10 f0       	push   $0xf0104046
f0101f9f:	e8 fb e1 ff ff       	call   f010019f <_panic>
	for (p = kmem.free_list; p; p = p->next) {
f0101fa4:	8b 0d a8 3e 12 f0    	mov    0xf0123ea8,%ecx
f0101faa:	85 c9                	test   %ecx,%ecx
f0101fac:	74 2b                	je     f0101fd9 <check_free_list+0x8e>
{
f0101fae:	55                   	push   %ebp
f0101faf:	89 e5                	mov    %esp,%ebp
f0101fb1:	83 ec 08             	sub    $0x8,%esp
		assert((void *)p > (void *)end);
f0101fb4:	81 f9 54 57 16 f0    	cmp    $0xf0165754,%ecx
f0101fba:	76 b6                	jbe    f0101f72 <check_free_list+0x27>
f0101fbc:	8d 41 04             	lea    0x4(%ecx),%eax
f0101fbf:	8d 91 00 10 00 00    	lea    0x1000(%ecx),%edx
			assert(((char *)p)[i] == 1);
f0101fc5:	80 38 01             	cmpb   $0x1,(%eax)
f0101fc8:	75 c1                	jne    f0101f8b <check_free_list+0x40>
f0101fca:	83 c0 01             	add    $0x1,%eax
		for (int i = 4; i < 4096; i++) 
f0101fcd:	39 d0                	cmp    %edx,%eax
f0101fcf:	75 f4                	jne    f0101fc5 <check_free_list+0x7a>
	for (p = kmem.free_list; p; p = p->next) {
f0101fd1:	8b 09                	mov    (%ecx),%ecx
f0101fd3:	85 c9                	test   %ecx,%ecx
f0101fd5:	75 dd                	jne    f0101fb4 <check_free_list+0x69>
	}
}
f0101fd7:	c9                   	leave  
f0101fd8:	c3                   	ret    
f0101fd9:	c3                   	ret    

f0101fda <boot_alloc_init>:
{
f0101fda:	55                   	push   %ebp
f0101fdb:	89 e5                	mov    %esp,%ebp
f0101fdd:	57                   	push   %edi
f0101fde:	56                   	push   %esi
f0101fdf:	53                   	push   %ebx
f0101fe0:	83 ec 2c             	sub    $0x2c,%esp
			num = (uint32_t)((char *)P2V(4*1024*1024) - end) / PGSIZE;
f0101fe3:	b8 00 00 40 f0       	mov    $0xf0400000,%eax
f0101fe8:	2d 54 57 16 f0       	sub    $0xf0165754,%eax
	char *mystart = end;
f0101fed:	bf 54 57 16 f0       	mov    $0xf0165754,%edi
			num = (uint32_t)((char *)P2V(4*1024*1024) - end) / PGSIZE;
f0101ff2:	c1 e8 0c             	shr    $0xc,%eax
f0101ff5:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0101ff8:	c7 45 d0 c4 3e 12 f0 	movl   $0xf0123ec4,-0x30(%ebp)
f0101fff:	c7 45 cc 38 3f 12 f0 	movl   $0xf0123f38,-0x34(%ebp)
f0102006:	8b 55 c8             	mov    -0x38(%ebp),%edx
f0102009:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f0102010:	e9 2c 01 00 00       	jmp    f0102141 <boot_alloc_init+0x167>
			sum *= 2;
f0102015:	01 c0                	add    %eax,%eax
			level++;
f0102017:	83 c6 01             	add    $0x1,%esi
		while (sum < num) {
f010201a:	39 c2                	cmp    %eax,%edx
f010201c:	7f f7                	jg     f0102015 <boot_alloc_init+0x3b>
			level--;
f010201e:	0f 9c c0             	setl   %al
f0102021:	0f b6 c0             	movzbl %al,%eax
f0102024:	29 c6                	sub    %eax,%esi
f0102026:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102029:	89 45 e0             	mov    %eax,-0x20(%ebp)
		order[i] = (bool *)mystart;
f010202c:	89 3c 85 40 3f 12 f0 	mov    %edi,-0xfedc0c0(,%eax,4)
		memset(order[i], 0, pow_2(level) * 2);
f0102033:	56                   	push   %esi
f0102034:	e8 0c fa ff ff       	call   f0101a45 <pow_2>
f0102039:	8d 1c 00             	lea    (%eax,%eax,1),%ebx
f010203c:	53                   	push   %ebx
f010203d:	6a 00                	push   $0x0
f010203f:	57                   	push   %edi
f0102040:	e8 73 17 00 00       	call   f01037b8 <memset>
		mystart += pow_2(level) * 2;
f0102045:	01 fb                	add    %edi,%ebx
		MAX_ORDER[i] = level;
f0102047:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010204a:	89 34 85 50 3f 12 f0 	mov    %esi,-0xfedc0b0(,%eax,4)
f0102051:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102054:	89 c7                	mov    %eax,%edi
		Buddy[i].slot = (struct Buddykmem *)mystart;
f0102056:	89 18                	mov    %ebx,(%eax)
		memset(Buddy[i].slot, 0, sizeof(struct Buddykmem) * (level + 1));
f0102058:	8d 46 01             	lea    0x1(%esi),%eax
f010205b:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010205e:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
f0102065:	83 c4 0c             	add    $0xc,%esp
f0102068:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f010206b:	51                   	push   %ecx
f010206c:	6a 00                	push   $0x0
f010206e:	53                   	push   %ebx
f010206f:	e8 44 17 00 00       	call   f01037b8 <memset>
		mystart += sizeof(struct Buddykmem) * (level + 1);
f0102074:	03 5d e4             	add    -0x1c(%ebp),%ebx
f0102077:	89 d8                	mov    %ebx,%eax
f0102079:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f010207c:	89 cb                	mov    %ecx,%ebx
		linkbase[i] = (struct run *)mystart;
f010207e:	89 01                	mov    %eax,(%ecx)
		memset(linkbase[i], 0, sizeof(struct run) *(level + 1));
f0102080:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102083:	8d 0c 95 00 00 00 00 	lea    0x0(,%edx,4),%ecx
f010208a:	83 c4 0c             	add    $0xc,%esp
f010208d:	89 4d d8             	mov    %ecx,-0x28(%ebp)
f0102090:	51                   	push   %ecx
f0102091:	6a 00                	push   $0x0
f0102093:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102096:	50                   	push   %eax
f0102097:	e8 1c 17 00 00       	call   f01037b8 <memset>
		mystart += sizeof(struct run) *(level + 1);
f010209c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010209f:	03 45 d8             	add    -0x28(%ebp),%eax
f01020a2:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		for (int j = 0; j <= level; j++) {
f01020a5:	83 c4 10             	add    $0x10,%esp
f01020a8:	b8 00 00 00 00       	mov    $0x0,%eax
f01020ad:	eb 17                	jmp    f01020c6 <boot_alloc_init+0xec>
f01020af:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
			linkbase[i][j].next = &linkbase[i][j];
f01020b6:	89 d1                	mov    %edx,%ecx
f01020b8:	03 0b                	add    (%ebx),%ecx
f01020ba:	89 09                	mov    %ecx,(%ecx)
			Buddy[i].slot[j].free_list = &linkbase[i][j];
f01020bc:	8b 0f                	mov    (%edi),%ecx
f01020be:	03 13                	add    (%ebx),%edx
f01020c0:	89 14 c1             	mov    %edx,(%ecx,%eax,8)
		for (int j = 0; j <= level; j++) {
f01020c3:	83 c0 01             	add    $0x1,%eax
f01020c6:	39 c6                	cmp    %eax,%esi
f01020c8:	7d e5                	jge    f01020af <boot_alloc_init+0xd5>
		start[i] = (int *)mystart;
f01020ca:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01020cd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020d0:	89 04 bd 48 3f 12 f0 	mov    %eax,-0xfedc0b8(,%edi,4)
		start[i][0] = 0;
f01020d7:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		for (int j = 0; j < level; j++)
f01020dd:	bb 00 00 00 00       	mov    $0x0,%ebx
f01020e2:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f01020e5:	eb 2c                	jmp    f0102113 <boot_alloc_init+0x139>
			start[i][j + 1] = start[i][j] + pow_2(level - j);
f01020e7:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01020ea:	8b 34 85 48 3f 12 f0 	mov    -0xfedc0b8(,%eax,4),%esi
f01020f1:	8d 3c 9d 00 00 00 00 	lea    0x0(,%ebx,4),%edi
f01020f8:	83 ec 0c             	sub    $0xc,%esp
f01020fb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01020fe:	29 d8                	sub    %ebx,%eax
f0102100:	50                   	push   %eax
f0102101:	e8 3f f9 ff ff       	call   f0101a45 <pow_2>
f0102106:	83 c4 10             	add    $0x10,%esp
f0102109:	03 04 9e             	add    (%esi,%ebx,4),%eax
f010210c:	89 44 3e 04          	mov    %eax,0x4(%esi,%edi,1)
		for (int j = 0; j < level; j++)
f0102110:	83 c3 01             	add    $0x1,%ebx
f0102113:	39 5d e4             	cmp    %ebx,-0x1c(%ebp)
f0102116:	7f cf                	jg     f01020e7 <boot_alloc_init+0x10d>
		mystart += sizeof(int) * (level + 1);
f0102118:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010211b:	03 7d d8             	add    -0x28(%ebp),%edi
	for (int i = 0; i < 2; i++) {
f010211e:	83 45 dc 01          	addl   $0x1,-0x24(%ebp)
f0102122:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102125:	83 f8 01             	cmp    $0x1,%eax
f0102128:	7f 26                	jg     f0102150 <boot_alloc_init+0x176>
f010212a:	83 45 d0 3c          	addl   $0x3c,-0x30(%ebp)
f010212e:	83 45 cc 04          	addl   $0x4,-0x34(%ebp)
			num = (uint32_t)((char *)PHYSTOP - 4*1024*1024) / PGSIZE;
f0102132:	ba 00 dc 00 00       	mov    $0xdc00,%edx
		if (i == 0)
f0102137:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010213b:	0f 84 b7 fe ff ff    	je     f0101ff8 <boot_alloc_init+0x1e>
		int sum = 1;
f0102141:	b8 01 00 00 00       	mov    $0x1,%eax
		int level = 0;
f0102146:	be 00 00 00 00       	mov    $0x0,%esi
		while (sum < num) {
f010214b:	e9 ca fe ff ff       	jmp    f010201a <boot_alloc_init+0x40>
	base[0] = (struct run *)ROUNDUP(mystart, PGSIZE);
f0102150:	81 c7 ff 0f 00 00    	add    $0xfff,%edi
f0102156:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
f010215c:	89 3d a0 3e 12 f0    	mov    %edi,0xf0123ea0
	base[1] = (struct run *)P2V(4 * 1024 * 1024);
f0102162:	c7 05 a4 3e 12 f0 00 	movl   $0xf0400000,0xf0123ea4
f0102169:	00 40 f0 
		Buddy[i].use_lock = 0;
f010216c:	c7 05 c0 3e 12 f0 00 	movl   $0x0,0xf0123ec0
f0102173:	00 00 00 
		__spin_initlock(&Buddy[i].lock, name);
f0102176:	83 ec 08             	sub    $0x8,%esp
f0102179:	68 80 40 10 f0       	push   $0xf0104080
f010217e:	68 c8 3e 12 f0       	push   $0xf0123ec8
f0102183:	e8 1e 06 00 00       	call   f01027a6 <__spin_initlock>
		Buddy[i].use_lock = 0;
f0102188:	c7 05 fc 3e 12 f0 00 	movl   $0x0,0xf0123efc
f010218f:	00 00 00 
		__spin_initlock(&Buddy[i].lock, name);
f0102192:	83 c4 08             	add    $0x8,%esp
f0102195:	68 80 40 10 f0       	push   $0xf0104080
f010219a:	68 04 3f 12 f0       	push   $0xf0123f04
f010219f:	e8 02 06 00 00       	call   f01027a6 <__spin_initlock>
	Buddyfree_range((void *)base[0], MAX_ORDER[0]);
f01021a4:	83 c4 08             	add    $0x8,%esp
f01021a7:	ff 35 50 3f 12 f0    	pushl  0xf0123f50
f01021ad:	ff 35 a0 3e 12 f0    	pushl  0xf0123ea0
f01021b3:	e8 15 fb ff ff       	call   f0101ccd <Buddyfree_range>
	check_free_list();
f01021b8:	e8 8e fd ff ff       	call   f0101f4b <check_free_list>
}
f01021bd:	83 c4 10             	add    $0x10,%esp
f01021c0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01021c3:	5b                   	pop    %ebx
f01021c4:	5e                   	pop    %esi
f01021c5:	5f                   	pop    %edi
f01021c6:	5d                   	pop    %ebp
f01021c7:	c3                   	ret    

f01021c8 <alloc_init>:
{
f01021c8:	55                   	push   %ebp
f01021c9:	89 e5                	mov    %esp,%ebp
f01021cb:	83 ec 10             	sub    $0x10,%esp
	Buddyfree_range((void *)base[1], MAX_ORDER[1]);
f01021ce:	ff 35 54 3f 12 f0    	pushl  0xf0123f54
f01021d4:	ff 35 a4 3e 12 f0    	pushl  0xf0123ea4
f01021da:	e8 ee fa ff ff       	call   f0101ccd <Buddyfree_range>
		Buddy[i].use_lock = 1;
f01021df:	c7 05 c0 3e 12 f0 01 	movl   $0x1,0xf0123ec0
f01021e6:	00 00 00 
f01021e9:	c7 05 fc 3e 12 f0 01 	movl   $0x1,0xf0123efc
f01021f0:	00 00 00 
	check_free_list();
f01021f3:	e8 53 fd ff ff       	call   f0101f4b <check_free_list>
}
f01021f8:	83 c4 10             	add    $0x10,%esp
f01021fb:	c9                   	leave  
f01021fc:	c3                   	ret    
f01021fd:	66 90                	xchg   %ax,%ax
f01021ff:	90                   	nop

f0102200 <mpentry_start>:
.set PROT_MODE_DSEG, 0x10	# kernel data segment selector

.code16           
.globl mpentry_start
mpentry_start:
	cli            
f0102200:	fa                   	cli    

	xorw    %ax, %ax
f0102201:	31 c0                	xor    %eax,%eax
	movw    %ax, %ds
f0102203:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0102205:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0102207:	8e d0                	mov    %eax,%ss

	lgdt    MPBOOTPHYS(gdtdesc)
f0102209:	0f 01 16             	lgdtl  (%esi)
f010220c:	74 70                	je     f010227e <mpsearch1+0x3>
	movl    %cr0, %eax
f010220e:	0f 20 c0             	mov    %cr0,%eax
	orl     $CR0_PE, %eax
f0102211:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
f0102215:	0f 22 c0             	mov    %eax,%cr0

	ljmpl   $(PROT_MODE_CSEG), $(MPBOOTPHYS(start32))
f0102218:	66 ea 20 70 00 00    	ljmpw  $0x0,$0x7020
f010221e:	08 00                	or     %al,(%eax)

f0102220 <start32>:

.code32
start32:
	movw    $(PROT_MODE_DSEG), %ax
f0102220:	66 b8 10 00          	mov    $0x10,%ax
	movw    %ax, %ds
f0102224:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0102226:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0102228:	8e d0                	mov    %eax,%ss
	movw    $0, %ax
f010222a:	66 b8 00 00          	mov    $0x0,%ax
	movw    %ax, %fs
f010222e:	8e e0                	mov    %eax,%fs
	movw    %ax, %gs
f0102230:	8e e8                	mov    %eax,%gs

	# Set up initial page table. We cannot use kern_pgdir yet because
	# we are still running at a low EIP.
	movl    $(RELOC(entry_pgdir)), %eax
f0102232:	b8 00 a0 11 00       	mov    $0x11a000,%eax
	movl    %eax, %cr3
f0102237:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl    %cr0, %eax
f010223a:	0f 20 c0             	mov    %cr0,%eax
	orl     $(CR0_PE|CR0_PG|CR0_WP), %eax
f010223d:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl    %eax, %cr0
f0102242:	0f 22 c0             	mov    %eax,%cr0

	# Switch to the per-cpu stack allocated in boot_aps()
	movl    mpentry_kstack, %esp
f0102245:	8b 25 48 36 12 f0    	mov    0xf0123648,%esp
	movl    $0x0, %ebp       # nuke frame pointer
f010224b:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Call mp_main().  (Exercise for the reader: why the indirect call?)
	movl    $mp_main, %eax
f0102250:	b8 53 01 10 f0       	mov    $0xf0100153,%eax
	call    *%eax
f0102255:	ff d0                	call   *%eax

f0102257 <spin>:

	# If mp_main returns (it shouldn't), loop.
spin:
	jmp     spin
f0102257:	eb fe                	jmp    f0102257 <spin>
f0102259:	8d 76 00             	lea    0x0(%esi),%esi

f010225c <gdt>:
	...
f0102264:	ff                   	(bad)  
f0102265:	ff 00                	incl   (%eax)
f0102267:	00 00                	add    %al,(%eax)
f0102269:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
f0102270:	00                   	.byte 0x0
f0102271:	92                   	xchg   %eax,%edx
f0102272:	cf                   	iret   
	...

f0102274 <gdtdesc>:
f0102274:	17                   	pop    %ss
f0102275:	00 5c 70 00          	add    %bl,0x0(%eax,%esi,2)
	...

f010227a <mpentry_end>:
	.word   0x17				# sizeof(gdt) - 1
	.long   MPBOOTPHYS(gdt)			# address gdt

.globl mpentry_end
mpentry_end:
	nop
f010227a:	90                   	nop

f010227b <mpsearch1>:
}

// Look for an MP structure in the len bytes at physical address addr.
static struct mp *
mpsearch1(physaddr_t a, int len)
{
f010227b:	55                   	push   %ebp
f010227c:	89 e5                	mov    %esp,%ebp
f010227e:	57                   	push   %edi
f010227f:	56                   	push   %esi
f0102280:	53                   	push   %ebx
f0102281:	83 ec 0c             	sub    $0xc,%esp
	struct mp *mp = P2V(a), *end = P2V(a + len);
f0102284:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
f010228a:	8d b4 10 00 00 00 f0 	lea    -0x10000000(%eax,%edx,1),%esi

	for (; mp < end; mp++)
f0102291:	eb 03                	jmp    f0102296 <mpsearch1+0x1b>
f0102293:	83 c3 10             	add    $0x10,%ebx
f0102296:	39 f3                	cmp    %esi,%ebx
f0102298:	73 2e                	jae    f01022c8 <mpsearch1+0x4d>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f010229a:	83 ec 04             	sub    $0x4,%esp
f010229d:	6a 04                	push   $0x4
f010229f:	68 8a 40 10 f0       	push   $0xf010408a
f01022a4:	53                   	push   %ebx
f01022a5:	e8 d6 15 00 00       	call   f0103880 <memcmp>
f01022aa:	83 c4 10             	add    $0x10,%esp
f01022ad:	85 c0                	test   %eax,%eax
f01022af:	75 e2                	jne    f0102293 <mpsearch1+0x18>
f01022b1:	89 da                	mov    %ebx,%edx
f01022b3:	8d 7b 10             	lea    0x10(%ebx),%edi
		sum += ((uint8_t *)addr)[i];
f01022b6:	0f b6 0a             	movzbl (%edx),%ecx
f01022b9:	01 c8                	add    %ecx,%eax
f01022bb:	83 c2 01             	add    $0x1,%edx
	for (i = 0; i < len; i++)
f01022be:	39 fa                	cmp    %edi,%edx
f01022c0:	75 f4                	jne    f01022b6 <mpsearch1+0x3b>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f01022c2:	84 c0                	test   %al,%al
f01022c4:	75 cd                	jne    f0102293 <mpsearch1+0x18>
f01022c6:	eb 05                	jmp    f01022cd <mpsearch1+0x52>
		    sum(mp, sizeof(*mp)) == 0)
			return mp;
	return NULL;
f01022c8:	bb 00 00 00 00       	mov    $0x0,%ebx
}
f01022cd:	89 d8                	mov    %ebx,%eax
f01022cf:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01022d2:	5b                   	pop    %ebx
f01022d3:	5e                   	pop    %esi
f01022d4:	5f                   	pop    %edi
f01022d5:	5d                   	pop    %ebp
f01022d6:	c3                   	ret    

f01022d7 <mp_init>:
	return conf;
}

void
mp_init(void)
{
f01022d7:	55                   	push   %ebp
f01022d8:	89 e5                	mov    %esp,%ebp
f01022da:	57                   	push   %edi
f01022db:	56                   	push   %esi
f01022dc:	53                   	push   %ebx
f01022dd:	83 ec 1c             	sub    $0x1c,%esp
	struct mpconf *conf;
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
f01022e0:	c7 05 e0 45 12 f0 20 	movl   $0xf0124020,0xf01245e0
f01022e7:	40 12 f0 
	if ((p = *(uint16_t *) (bda + 0x0E))) {
f01022ea:	0f b7 05 0e 04 00 f0 	movzwl 0xf000040e,%eax
f01022f1:	85 c0                	test   %eax,%eax
f01022f3:	74 53                	je     f0102348 <mp_init+0x71>
		p <<= 4;	// Translate from segment to PA
f01022f5:	c1 e0 04             	shl    $0x4,%eax
		if ((mp = mpsearch1(p, 1024)))
f01022f8:	ba 00 04 00 00       	mov    $0x400,%edx
f01022fd:	e8 79 ff ff ff       	call   f010227b <mpsearch1>
f0102302:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102305:	85 c0                	test   %eax,%eax
f0102307:	74 5f                	je     f0102368 <mp_init+0x91>
	if (mp->physaddr == 0 || mp->type != 0) {
f0102309:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f010230c:	8b 41 04             	mov    0x4(%ecx),%eax
f010230f:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102312:	85 c0                	test   %eax,%eax
f0102314:	74 6d                	je     f0102383 <mp_init+0xac>
f0102316:	80 79 0b 00          	cmpb   $0x0,0xb(%ecx)
f010231a:	75 67                	jne    f0102383 <mp_init+0xac>
	conf = (struct mpconf *) P2V(mp->physaddr);
f010231c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010231f:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
f0102325:	89 de                	mov    %ebx,%esi
	if (memcmp(conf, "PCMP", 4) != 0) {
f0102327:	83 ec 04             	sub    $0x4,%esp
f010232a:	6a 04                	push   $0x4
f010232c:	68 8f 40 10 f0       	push   $0xf010408f
f0102331:	53                   	push   %ebx
f0102332:	e8 49 15 00 00       	call   f0103880 <memcmp>
f0102337:	83 c4 10             	add    $0x10,%esp
f010233a:	85 c0                	test   %eax,%eax
f010233c:	75 5a                	jne    f0102398 <mp_init+0xc1>
f010233e:	0f b7 7b 04          	movzwl 0x4(%ebx),%edi
f0102342:	01 df                	add    %ebx,%edi
	sum = 0;
f0102344:	89 c2                	mov    %eax,%edx
f0102346:	eb 6d                	jmp    f01023b5 <mp_init+0xde>
		p = *(uint16_t *) (bda + 0x13) * 1024;
f0102348:	0f b7 05 13 04 00 f0 	movzwl 0xf0000413,%eax
f010234f:	c1 e0 0a             	shl    $0xa,%eax
		if ((mp = mpsearch1(p - 1024, 1024)))
f0102352:	2d 00 04 00 00       	sub    $0x400,%eax
f0102357:	ba 00 04 00 00       	mov    $0x400,%edx
f010235c:	e8 1a ff ff ff       	call   f010227b <mpsearch1>
f0102361:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102364:	85 c0                	test   %eax,%eax
f0102366:	75 a1                	jne    f0102309 <mp_init+0x32>
	return mpsearch1(0xF0000, 0x10000);
f0102368:	ba 00 00 01 00       	mov    $0x10000,%edx
f010236d:	b8 00 00 0f 00       	mov    $0xf0000,%eax
f0102372:	e8 04 ff ff ff       	call   f010227b <mpsearch1>
f0102377:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	if ((mp = mpsearch()) == 0)
f010237a:	85 c0                	test   %eax,%eax
f010237c:	75 8b                	jne    f0102309 <mp_init+0x32>
f010237e:	e9 97 01 00 00       	jmp    f010251a <mp_init+0x243>
		cprintf("SMP: Default configurations not implemented\n");
f0102383:	83 ec 0c             	sub    $0xc,%esp
f0102386:	68 b4 40 10 f0       	push   $0xf01040b4
f010238b:	e8 f9 e3 ff ff       	call   f0100789 <cprintf>
f0102390:	83 c4 10             	add    $0x10,%esp
f0102393:	e9 82 01 00 00       	jmp    f010251a <mp_init+0x243>
		cprintf("SMP: Incorrect MP configuration table signature\n");
f0102398:	83 ec 0c             	sub    $0xc,%esp
f010239b:	68 e4 40 10 f0       	push   $0xf01040e4
f01023a0:	e8 e4 e3 ff ff       	call   f0100789 <cprintf>
f01023a5:	83 c4 10             	add    $0x10,%esp
f01023a8:	e9 6d 01 00 00       	jmp    f010251a <mp_init+0x243>
		sum += ((uint8_t *)addr)[i];
f01023ad:	0f b6 0b             	movzbl (%ebx),%ecx
f01023b0:	01 ca                	add    %ecx,%edx
f01023b2:	83 c3 01             	add    $0x1,%ebx
	for (i = 0; i < len; i++)
f01023b5:	39 fb                	cmp    %edi,%ebx
f01023b7:	75 f4                	jne    f01023ad <mp_init+0xd6>
	if (sum(conf, conf->length) != 0) {
f01023b9:	84 d2                	test   %dl,%dl
f01023bb:	75 16                	jne    f01023d3 <mp_init+0xfc>
	if (conf->version != 1 && conf->version != 4) {
f01023bd:	0f b6 56 06          	movzbl 0x6(%esi),%edx
f01023c1:	80 fa 01             	cmp    $0x1,%dl
f01023c4:	74 05                	je     f01023cb <mp_init+0xf4>
f01023c6:	80 fa 04             	cmp    $0x4,%dl
f01023c9:	75 1d                	jne    f01023e8 <mp_init+0x111>
f01023cb:	0f b7 4e 28          	movzwl 0x28(%esi),%ecx
f01023cf:	01 d9                	add    %ebx,%ecx
f01023d1:	eb 36                	jmp    f0102409 <mp_init+0x132>
		cprintf("SMP: Bad MP configuration checksum\n");
f01023d3:	83 ec 0c             	sub    $0xc,%esp
f01023d6:	68 18 41 10 f0       	push   $0xf0104118
f01023db:	e8 a9 e3 ff ff       	call   f0100789 <cprintf>
f01023e0:	83 c4 10             	add    $0x10,%esp
f01023e3:	e9 32 01 00 00       	jmp    f010251a <mp_init+0x243>
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
f01023e8:	83 ec 08             	sub    $0x8,%esp
f01023eb:	0f b6 d2             	movzbl %dl,%edx
f01023ee:	52                   	push   %edx
f01023ef:	68 3c 41 10 f0       	push   $0xf010413c
f01023f4:	e8 90 e3 ff ff       	call   f0100789 <cprintf>
f01023f9:	83 c4 10             	add    $0x10,%esp
f01023fc:	e9 19 01 00 00       	jmp    f010251a <mp_init+0x243>
		sum += ((uint8_t *)addr)[i];
f0102401:	0f b6 13             	movzbl (%ebx),%edx
f0102404:	01 d0                	add    %edx,%eax
f0102406:	83 c3 01             	add    $0x1,%ebx
	for (i = 0; i < len; i++)
f0102409:	39 d9                	cmp    %ebx,%ecx
f010240b:	75 f4                	jne    f0102401 <mp_init+0x12a>
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f010240d:	02 46 2a             	add    0x2a(%esi),%al
f0102410:	75 29                	jne    f010243b <mp_init+0x164>
	if ((conf = mpconfig(&mp)) == 0)
f0102412:	81 7d e0 00 00 00 10 	cmpl   $0x10000000,-0x20(%ebp)
f0102419:	0f 84 fb 00 00 00    	je     f010251a <mp_init+0x243>
		return;
	ismp = 1;
f010241f:	c7 05 00 40 12 f0 01 	movl   $0x1,0xf0124000
f0102426:	00 00 00 
	lapicaddr = conf->lapicaddr;
f0102429:	8b 46 24             	mov    0x24(%esi),%eax
f010242c:	a3 00 50 16 f0       	mov    %eax,0xf0165000

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0102431:	8d 7e 2c             	lea    0x2c(%esi),%edi
f0102434:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102439:	eb 53                	jmp    f010248e <mp_init+0x1b7>
		cprintf("SMP: Bad MP configuration extended checksum\n");
f010243b:	83 ec 0c             	sub    $0xc,%esp
f010243e:	68 5c 41 10 f0       	push   $0xf010415c
f0102443:	e8 41 e3 ff ff       	call   f0100789 <cprintf>
f0102448:	83 c4 10             	add    $0x10,%esp
f010244b:	e9 ca 00 00 00       	jmp    f010251a <mp_init+0x243>
		switch (*p) {
		case MPPROC:
			proc = (struct mpproc *)p;
			if (proc->flags & MPPROC_BOOT)
f0102450:	f6 47 03 02          	testb  $0x2,0x3(%edi)
f0102454:	74 14                	je     f010246a <mp_init+0x193>
				bootcpu = &cpus[ncpu];
f0102456:	69 05 e4 45 12 f0 b8 	imul   $0xb8,0xf01245e4,%eax
f010245d:	00 00 00 
f0102460:	05 20 40 12 f0       	add    $0xf0124020,%eax
f0102465:	a3 e0 45 12 f0       	mov    %eax,0xf01245e0
			if (ncpu < NCPU) {
f010246a:	a1 e4 45 12 f0       	mov    0xf01245e4,%eax
f010246f:	83 f8 07             	cmp    $0x7,%eax
f0102472:	7f 32                	jg     f01024a6 <mp_init+0x1cf>
				cpus[ncpu].cpu_id = ncpu;
f0102474:	69 d0 b8 00 00 00    	imul   $0xb8,%eax,%edx
f010247a:	88 82 20 40 12 f0    	mov    %al,-0xfedbfe0(%edx)
				ncpu++;
f0102480:	83 c0 01             	add    $0x1,%eax
f0102483:	a3 e4 45 12 f0       	mov    %eax,0xf01245e4
			} else {
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
					proc->apicid);
			}
			p += sizeof(struct mpproc);
f0102488:	83 c7 14             	add    $0x14,%edi
	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f010248b:	83 c3 01             	add    $0x1,%ebx
f010248e:	0f b7 46 22          	movzwl 0x22(%esi),%eax
f0102492:	39 d8                	cmp    %ebx,%eax
f0102494:	76 4b                	jbe    f01024e1 <mp_init+0x20a>
		switch (*p) {
f0102496:	0f b6 07             	movzbl (%edi),%eax
f0102499:	84 c0                	test   %al,%al
f010249b:	74 b3                	je     f0102450 <mp_init+0x179>
f010249d:	3c 04                	cmp    $0x4,%al
f010249f:	77 1c                	ja     f01024bd <mp_init+0x1e6>
			continue;
		case MPBUS:
		case MPIOAPIC:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
f01024a1:	83 c7 08             	add    $0x8,%edi
			continue;
f01024a4:	eb e5                	jmp    f010248b <mp_init+0x1b4>
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
f01024a6:	83 ec 08             	sub    $0x8,%esp
f01024a9:	0f b6 47 01          	movzbl 0x1(%edi),%eax
f01024ad:	50                   	push   %eax
f01024ae:	68 8c 41 10 f0       	push   $0xf010418c
f01024b3:	e8 d1 e2 ff ff       	call   f0100789 <cprintf>
f01024b8:	83 c4 10             	add    $0x10,%esp
f01024bb:	eb cb                	jmp    f0102488 <mp_init+0x1b1>
		default:
			cprintf("mpinit: unknown config type %x\n", *p);
f01024bd:	83 ec 08             	sub    $0x8,%esp
		switch (*p) {
f01024c0:	0f b6 c0             	movzbl %al,%eax
			cprintf("mpinit: unknown config type %x\n", *p);
f01024c3:	50                   	push   %eax
f01024c4:	68 b4 41 10 f0       	push   $0xf01041b4
f01024c9:	e8 bb e2 ff ff       	call   f0100789 <cprintf>
			ismp = 0;
f01024ce:	c7 05 00 40 12 f0 00 	movl   $0x0,0xf0124000
f01024d5:	00 00 00 
			i = conf->entry;
f01024d8:	0f b7 5e 22          	movzwl 0x22(%esi),%ebx
f01024dc:	83 c4 10             	add    $0x10,%esp
f01024df:	eb aa                	jmp    f010248b <mp_init+0x1b4>
		}
	}

	bootcpu->cpu_status = CPU_STARTED;
f01024e1:	a1 e0 45 12 f0       	mov    0xf01245e0,%eax
f01024e6:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	if (!ismp) {
f01024ed:	83 3d 00 40 12 f0 00 	cmpl   $0x0,0xf0124000
f01024f4:	75 2c                	jne    f0102522 <mp_init+0x24b>
		// Didn't like what we found; fall back to no MP.
		ncpu = 1;
f01024f6:	c7 05 e4 45 12 f0 01 	movl   $0x1,0xf01245e4
f01024fd:	00 00 00 
		lapicaddr = 0;
f0102500:	c7 05 00 50 16 f0 00 	movl   $0x0,0xf0165000
f0102507:	00 00 00 
		cprintf("SMP: configuration not found, SMP disabled\n");
f010250a:	83 ec 0c             	sub    $0xc,%esp
f010250d:	68 d4 41 10 f0       	push   $0xf01041d4
f0102512:	e8 72 e2 ff ff       	call   f0100789 <cprintf>
		return;
f0102517:	83 c4 10             	add    $0x10,%esp
		// switch to getting interrupts from the LAPIC.
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
		outb(0x22, 0x70);   // Select IMCR
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
	}
}
f010251a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010251d:	5b                   	pop    %ebx
f010251e:	5e                   	pop    %esi
f010251f:	5f                   	pop    %edi
f0102520:	5d                   	pop    %ebp
f0102521:	c3                   	ret    
	cprintf("SMP: CPU %d found %d CPU(s)\n", bootcpu->cpu_id,  ncpu);
f0102522:	83 ec 04             	sub    $0x4,%esp
f0102525:	ff 35 e4 45 12 f0    	pushl  0xf01245e4
f010252b:	0f b6 00             	movzbl (%eax),%eax
f010252e:	50                   	push   %eax
f010252f:	68 94 40 10 f0       	push   $0xf0104094
f0102534:	e8 50 e2 ff ff       	call   f0100789 <cprintf>
	if (mp->imcrp) {
f0102539:	83 c4 10             	add    $0x10,%esp
f010253c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010253f:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
f0102543:	74 d5                	je     f010251a <mp_init+0x243>
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
f0102545:	83 ec 0c             	sub    $0xc,%esp
f0102548:	68 00 42 10 f0       	push   $0xf0104200
f010254d:	e8 37 e2 ff ff       	call   f0100789 <cprintf>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102552:	b8 70 00 00 00       	mov    $0x70,%eax
f0102557:	ba 22 00 00 00       	mov    $0x22,%edx
f010255c:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010255d:	ba 23 00 00 00       	mov    $0x23,%edx
f0102562:	ec                   	in     (%dx),%al
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
f0102563:	83 c8 01             	or     $0x1,%eax
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102566:	ee                   	out    %al,(%dx)
f0102567:	83 c4 10             	add    $0x10,%esp
f010256a:	eb ae                	jmp    f010251a <mp_init+0x243>

f010256c <lapicw>:
physaddr_t lapicaddr;        // Initialized in mpconfig.c
volatile uint32_t *lapic;

static void
lapicw(int index, int value)
{
f010256c:	55                   	push   %ebp
f010256d:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
f010256f:	8b 0d 04 50 16 f0    	mov    0xf0165004,%ecx
f0102575:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f0102578:	89 10                	mov    %edx,(%eax)
	lapic[ID];  // wait for write to finish, by reading
f010257a:	a1 04 50 16 f0       	mov    0xf0165004,%eax
f010257f:	8b 40 20             	mov    0x20(%eax),%eax
}
f0102582:	5d                   	pop    %ebp
f0102583:	c3                   	ret    

f0102584 <cpunum>:
	lapicw(TPR, 0);
}

int
cpunum(void)
{
f0102584:	55                   	push   %ebp
f0102585:	89 e5                	mov    %esp,%ebp
	if (lapic)
f0102587:	8b 15 04 50 16 f0    	mov    0xf0165004,%edx
		return lapic[ID] >> 24;
	return 0;
f010258d:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lapic)
f0102592:	85 d2                	test   %edx,%edx
f0102594:	74 06                	je     f010259c <cpunum+0x18>
		return lapic[ID] >> 24;
f0102596:	8b 42 20             	mov    0x20(%edx),%eax
f0102599:	c1 e8 18             	shr    $0x18,%eax
}
f010259c:	5d                   	pop    %ebp
f010259d:	c3                   	ret    

f010259e <lapic_init>:
	if (!lapicaddr)
f010259e:	a1 00 50 16 f0       	mov    0xf0165000,%eax
f01025a3:	85 c0                	test   %eax,%eax
f01025a5:	75 02                	jne    f01025a9 <lapic_init+0xb>
f01025a7:	f3 c3                	repz ret 
{
f01025a9:	55                   	push   %ebp
f01025aa:	89 e5                	mov    %esp,%ebp
	lapic = (uint32_t *)lapicaddr;
f01025ac:	a3 04 50 16 f0       	mov    %eax,0xf0165004
	lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
f01025b1:	ba 3f 01 00 00       	mov    $0x13f,%edx
f01025b6:	b8 3c 00 00 00       	mov    $0x3c,%eax
f01025bb:	e8 ac ff ff ff       	call   f010256c <lapicw>
	lapicw(TDCR, X1);
f01025c0:	ba 0b 00 00 00       	mov    $0xb,%edx
f01025c5:	b8 f8 00 00 00       	mov    $0xf8,%eax
f01025ca:	e8 9d ff ff ff       	call   f010256c <lapicw>
	lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
f01025cf:	ba 20 00 02 00       	mov    $0x20020,%edx
f01025d4:	b8 c8 00 00 00       	mov    $0xc8,%eax
f01025d9:	e8 8e ff ff ff       	call   f010256c <lapicw>
	lapicw(TICR, 10000000); 
f01025de:	ba 80 96 98 00       	mov    $0x989680,%edx
f01025e3:	b8 e0 00 00 00       	mov    $0xe0,%eax
f01025e8:	e8 7f ff ff ff       	call   f010256c <lapicw>
	if (thiscpu != bootcpu)
f01025ed:	e8 92 ff ff ff       	call   f0102584 <cpunum>
f01025f2:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f01025f8:	05 20 40 12 f0       	add    $0xf0124020,%eax
f01025fd:	39 05 e0 45 12 f0    	cmp    %eax,0xf01245e0
f0102603:	74 0f                	je     f0102614 <lapic_init+0x76>
		lapicw(LINT0, MASKED);
f0102605:	ba 00 00 01 00       	mov    $0x10000,%edx
f010260a:	b8 d4 00 00 00       	mov    $0xd4,%eax
f010260f:	e8 58 ff ff ff       	call   f010256c <lapicw>
	lapicw(LINT1, MASKED);
f0102614:	ba 00 00 01 00       	mov    $0x10000,%edx
f0102619:	b8 d8 00 00 00       	mov    $0xd8,%eax
f010261e:	e8 49 ff ff ff       	call   f010256c <lapicw>
	if (((lapic[VER]>>16) & 0xFF) >= 4)
f0102623:	a1 04 50 16 f0       	mov    0xf0165004,%eax
f0102628:	8b 40 30             	mov    0x30(%eax),%eax
f010262b:	c1 e8 10             	shr    $0x10,%eax
f010262e:	3c 03                	cmp    $0x3,%al
f0102630:	77 7c                	ja     f01026ae <lapic_init+0x110>
	lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
f0102632:	ba 33 00 00 00       	mov    $0x33,%edx
f0102637:	b8 dc 00 00 00       	mov    $0xdc,%eax
f010263c:	e8 2b ff ff ff       	call   f010256c <lapicw>
	lapicw(ESR, 0);
f0102641:	ba 00 00 00 00       	mov    $0x0,%edx
f0102646:	b8 a0 00 00 00       	mov    $0xa0,%eax
f010264b:	e8 1c ff ff ff       	call   f010256c <lapicw>
	lapicw(ESR, 0);
f0102650:	ba 00 00 00 00       	mov    $0x0,%edx
f0102655:	b8 a0 00 00 00       	mov    $0xa0,%eax
f010265a:	e8 0d ff ff ff       	call   f010256c <lapicw>
	lapicw(EOI, 0);
f010265f:	ba 00 00 00 00       	mov    $0x0,%edx
f0102664:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0102669:	e8 fe fe ff ff       	call   f010256c <lapicw>
	lapicw(ICRHI, 0);
f010266e:	ba 00 00 00 00       	mov    $0x0,%edx
f0102673:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0102678:	e8 ef fe ff ff       	call   f010256c <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
f010267d:	ba 00 85 08 00       	mov    $0x88500,%edx
f0102682:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0102687:	e8 e0 fe ff ff       	call   f010256c <lapicw>
	while(lapic[ICRLO] & DELIVS)
f010268c:	8b 15 04 50 16 f0    	mov    0xf0165004,%edx
f0102692:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0102698:	f6 c4 10             	test   $0x10,%ah
f010269b:	75 f5                	jne    f0102692 <lapic_init+0xf4>
	lapicw(TPR, 0);
f010269d:	ba 00 00 00 00       	mov    $0x0,%edx
f01026a2:	b8 20 00 00 00       	mov    $0x20,%eax
f01026a7:	e8 c0 fe ff ff       	call   f010256c <lapicw>
}
f01026ac:	5d                   	pop    %ebp
f01026ad:	c3                   	ret    
		lapicw(PCINT, MASKED);
f01026ae:	ba 00 00 01 00       	mov    $0x10000,%edx
f01026b3:	b8 d0 00 00 00       	mov    $0xd0,%eax
f01026b8:	e8 af fe ff ff       	call   f010256c <lapicw>
f01026bd:	e9 70 ff ff ff       	jmp    f0102632 <lapic_init+0x94>

f01026c2 <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
	if (lapic)
f01026c2:	83 3d 04 50 16 f0 00 	cmpl   $0x0,0xf0165004
f01026c9:	74 14                	je     f01026df <lapic_eoi+0x1d>
{
f01026cb:	55                   	push   %ebp
f01026cc:	89 e5                	mov    %esp,%ebp
		lapicw(EOI, 0);
f01026ce:	ba 00 00 00 00       	mov    $0x0,%edx
f01026d3:	b8 2c 00 00 00       	mov    $0x2c,%eax
f01026d8:	e8 8f fe ff ff       	call   f010256c <lapicw>
}
f01026dd:	5d                   	pop    %ebp
f01026de:	c3                   	ret    
f01026df:	f3 c3                	repz ret 

f01026e1 <lapic_startap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startap(uint8_t apicid, uint32_t addr)
{
f01026e1:	55                   	push   %ebp
f01026e2:	89 e5                	mov    %esp,%ebp
f01026e4:	56                   	push   %esi
f01026e5:	53                   	push   %ebx
f01026e6:	8b 75 08             	mov    0x8(%ebp),%esi
f01026e9:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01026ec:	b8 0f 00 00 00       	mov    $0xf,%eax
f01026f1:	ba 70 00 00 00       	mov    $0x70,%edx
f01026f6:	ee                   	out    %al,(%dx)
f01026f7:	b8 0a 00 00 00       	mov    $0xa,%eax
f01026fc:	ba 71 00 00 00       	mov    $0x71,%edx
f0102701:	ee                   	out    %al,(%dx)
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t *)P2V((0x40 << 4 | 0x67));  // Warm reset vector
	wrv[0] = 0;
f0102702:	66 c7 05 67 04 00 f0 	movw   $0x0,0xf0000467
f0102709:	00 00 
	wrv[1] = addr >> 4;
f010270b:	89 d8                	mov    %ebx,%eax
f010270d:	c1 e8 04             	shr    $0x4,%eax
f0102710:	66 a3 69 04 00 f0    	mov    %ax,0xf0000469

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid << 24);
f0102716:	c1 e6 18             	shl    $0x18,%esi
f0102719:	89 f2                	mov    %esi,%edx
f010271b:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0102720:	e8 47 fe ff ff       	call   f010256c <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
f0102725:	ba 00 c5 00 00       	mov    $0xc500,%edx
f010272a:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010272f:	e8 38 fe ff ff       	call   f010256c <lapicw>
	microdelay(200);
	lapicw(ICRLO, INIT | LEVEL);
f0102734:	ba 00 85 00 00       	mov    $0x8500,%edx
f0102739:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010273e:	e8 29 fe ff ff       	call   f010256c <lapicw>
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0102743:	c1 eb 0c             	shr    $0xc,%ebx
f0102746:	80 cf 06             	or     $0x6,%bh
		lapicw(ICRHI, apicid << 24);
f0102749:	89 f2                	mov    %esi,%edx
f010274b:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0102750:	e8 17 fe ff ff       	call   f010256c <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0102755:	89 da                	mov    %ebx,%edx
f0102757:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010275c:	e8 0b fe ff ff       	call   f010256c <lapicw>
		lapicw(ICRHI, apicid << 24);
f0102761:	89 f2                	mov    %esi,%edx
f0102763:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0102768:	e8 ff fd ff ff       	call   f010256c <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f010276d:	89 da                	mov    %ebx,%edx
f010276f:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0102774:	e8 f3 fd ff ff       	call   f010256c <lapicw>
		microdelay(200);
	}
}
f0102779:	5b                   	pop    %ebx
f010277a:	5e                   	pop    %esi
f010277b:	5d                   	pop    %ebp
f010277c:	c3                   	ret    

f010277d <lapic_ipi>:

void
lapic_ipi(int vector)
{
f010277d:	55                   	push   %ebp
f010277e:	89 e5                	mov    %esp,%ebp
	lapicw(ICRLO, OTHERS | FIXED | vector);
f0102780:	8b 55 08             	mov    0x8(%ebp),%edx
f0102783:	81 ca 00 00 0c 00    	or     $0xc0000,%edx
f0102789:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010278e:	e8 d9 fd ff ff       	call   f010256c <lapicw>
	while (lapic[ICRLO] & DELIVS)
f0102793:	8b 15 04 50 16 f0    	mov    0xf0165004,%edx
f0102799:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f010279f:	f6 c4 10             	test   $0x10,%ah
f01027a2:	75 f5                	jne    f0102799 <lapic_ipi+0x1c>
		;
}
f01027a4:	5d                   	pop    %ebp
f01027a5:	c3                   	ret    

f01027a6 <__spin_initlock>:
#endif
};

void
__spin_initlock(struct spinlock *lk, char *name)
{
f01027a6:	55                   	push   %ebp
f01027a7:	89 e5                	mov    %esp,%ebp
f01027a9:	8b 45 08             	mov    0x8(%ebp),%eax
	// TODO: Your code here.
	lk->locked = 0;
f01027ac:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	lk->name = name;
f01027b2:	8b 55 0c             	mov    0xc(%ebp),%edx
f01027b5:	89 50 04             	mov    %edx,0x4(%eax)
	lk->cpu = 0;
f01027b8:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
f01027bf:	5d                   	pop    %ebp
f01027c0:	c3                   	ret    

f01027c1 <__mspin_initlock>:

void
__mspin_initlock(struct mcslock *lk, char *name)
{
f01027c1:	55                   	push   %ebp
f01027c2:	89 e5                	mov    %esp,%ebp
f01027c4:	8b 45 08             	mov    0x8(%ebp),%eax
	// TODO: Your code here.
	lk->locked = NULL;
f01027c7:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	lk->name = name;
f01027cd:	8b 55 0c             	mov    0xc(%ebp),%edx
f01027d0:	89 50 04             	mov    %edx,0x4(%eax)
	lk->cpu = 0;
f01027d3:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
f01027da:	5d                   	pop    %ebp
f01027db:	c3                   	ret    

f01027dc <spin_lock>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
f01027dc:	55                   	push   %ebp
f01027dd:	89 e5                	mov    %esp,%ebp
f01027df:	56                   	push   %esi
f01027e0:	53                   	push   %ebx
f01027e1:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	// TODO: Your code here.
	pushcli();
f01027e4:	e8 79 f0 ff ff       	call   f0101862 <pushcli>
	if (lk->cpu == thiscpu)
f01027e9:	8b 73 08             	mov    0x8(%ebx),%esi
f01027ec:	e8 93 fd ff ff       	call   f0102584 <cpunum>
f01027f1:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f01027f7:	05 20 40 12 f0       	add    $0xf0124020,%eax
f01027fc:	39 c6                	cmp    %eax,%esi
f01027fe:	74 28                	je     f0102828 <spin_lock+0x4c>
	asm volatile("lock; xchgl %0, %1"
f0102800:	ba 01 00 00 00       	mov    $0x1,%edx
f0102805:	89 d0                	mov    %edx,%eax
f0102807:	f0 87 03             	lock xchg %eax,(%ebx)
		panic("spinlock");
	int locked = 1;
	while(xchg(&lk->locked, locked));
f010280a:	85 c0                	test   %eax,%eax
f010280c:	75 f7                	jne    f0102805 <spin_lock+0x29>
	asm volatile("" : : : "memory");
	lk->cpu = thiscpu;
f010280e:	e8 71 fd ff ff       	call   f0102584 <cpunum>
f0102813:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f0102819:	05 20 40 12 f0       	add    $0xf0124020,%eax
f010281e:	89 43 08             	mov    %eax,0x8(%ebx)
}
f0102821:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0102824:	5b                   	pop    %ebx
f0102825:	5e                   	pop    %esi
f0102826:	5d                   	pop    %ebp
f0102827:	c3                   	ret    
		panic("spinlock");
f0102828:	83 ec 04             	sub    $0x4,%esp
f010282b:	68 41 42 10 f0       	push   $0xf0104241
f0102830:	6a 38                	push   $0x38
f0102832:	68 4a 42 10 f0       	push   $0xf010424a
f0102837:	e8 63 d9 ff ff       	call   f010019f <_panic>

f010283c <mspin_lock>:

void
mspin_lock(struct mcslock *lk)
{
f010283c:	55                   	push   %ebp
f010283d:	89 e5                	mov    %esp,%ebp
f010283f:	53                   	push   %ebx
f0102840:	83 ec 04             	sub    $0x4,%esp
f0102843:	8b 5d 08             	mov    0x8(%ebp),%ebx
	struct mcslock_node *me = &thiscpu->node;
f0102846:	e8 39 fd ff ff       	call   f0102584 <cpunum>
f010284b:	89 c2                	mov    %eax,%edx
f010284d:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f0102853:	8d 88 d0 40 12 f0    	lea    -0xfedbf30(%eax),%ecx
	struct mcslock_node *tmp = me;
	me->next = NULL;
f0102859:	c7 80 d4 40 12 f0 00 	movl   $0x0,-0xfedbf2c(%eax)
f0102860:	00 00 00 
f0102863:	89 c8                	mov    %ecx,%eax
f0102865:	f0 87 03             	lock xchg %eax,(%ebx)
	struct mcslock_node *pre = Xchg(&lk->locked, tmp);
	if (pre == NULL)
f0102868:	85 c0                	test   %eax,%eax
f010286a:	74 29                	je     f0102895 <mspin_lock+0x59>
		return;
	me->waiting = 1;
f010286c:	69 da b8 00 00 00    	imul   $0xb8,%edx,%ebx
f0102872:	81 c3 20 40 12 f0    	add    $0xf0124020,%ebx
f0102878:	c7 83 b0 00 00 00 01 	movl   $0x1,0xb0(%ebx)
f010287f:	00 00 00 
	asm volatile("" : : : "memory");
	pre->next = me;
f0102882:	89 48 04             	mov    %ecx,0x4(%eax)
	while (me->waiting) 
f0102885:	89 d8                	mov    %ebx,%eax
f0102887:	eb 02                	jmp    f010288b <mspin_lock+0x4f>
		asm volatile("pause");
f0102889:	f3 90                	pause  
	while (me->waiting) 
f010288b:	8b 90 b0 00 00 00    	mov    0xb0(%eax),%edx
f0102891:	85 d2                	test   %edx,%edx
f0102893:	75 f4                	jne    f0102889 <mspin_lock+0x4d>
}
f0102895:	83 c4 04             	add    $0x4,%esp
f0102898:	5b                   	pop    %ebx
f0102899:	5d                   	pop    %ebp
f010289a:	c3                   	ret    

f010289b <spin_unlock>:

// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
f010289b:	55                   	push   %ebp
f010289c:	89 e5                	mov    %esp,%ebp
f010289e:	56                   	push   %esi
f010289f:	53                   	push   %ebx
f01028a0:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// respect to any other instruction which references the same memory.
	// x86 CPUs will not reorder loads/stores across locked instructions
	// (vol 3, 8.2.2). Because xchg() is implemented using asm volatile,
	// gcc will not reorder C statements across the xchg.
	// TODO: Your code here.
	if (lk->cpu == thiscpu) {
f01028a3:	8b 73 08             	mov    0x8(%ebx),%esi
f01028a6:	e8 d9 fc ff ff       	call   f0102584 <cpunum>
f01028ab:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f01028b1:	05 20 40 12 f0       	add    $0xf0124020,%eax
f01028b6:	39 c6                	cmp    %eax,%esi
f01028b8:	75 19                	jne    f01028d3 <spin_unlock+0x38>
		lk->cpu = 0;
f01028ba:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
		//xchg(&lk->locked, 0);
		asm volatile("" : : : "memory");
		asm volatile("movl $0, %0" : "+m"(lk->locked) : );
f01028c1:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	} else 
		panic("spin_unlock");
	popcli();
f01028c7:	e8 e5 ef ff ff       	call   f01018b1 <popcli>
}
f01028cc:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01028cf:	5b                   	pop    %ebx
f01028d0:	5e                   	pop    %esi
f01028d1:	5d                   	pop    %ebp
f01028d2:	c3                   	ret    
		panic("spin_unlock");
f01028d3:	83 ec 04             	sub    $0x4,%esp
f01028d6:	68 5a 42 10 f0       	push   $0xf010425a
f01028db:	6a 60                	push   $0x60
f01028dd:	68 4a 42 10 f0       	push   $0xf010424a
f01028e2:	e8 b8 d8 ff ff       	call   f010019f <_panic>

f01028e7 <mspin_unlock>:

void
mspin_unlock(struct mcslock *lk)
{
f01028e7:	55                   	push   %ebp
f01028e8:	89 e5                	mov    %esp,%ebp
f01028ea:	56                   	push   %esi
f01028eb:	53                   	push   %ebx
	struct mcslock_node *me = &thiscpu->node;
f01028ec:	e8 93 fc ff ff       	call   f0102584 <cpunum>
f01028f1:	89 c2                	mov    %eax,%edx
	struct mcslock_node *tmp = me;
	if (me->next == NULL) {
f01028f3:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f01028f9:	05 20 40 12 f0       	add    $0xf0124020,%eax
f01028fe:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
f0102904:	85 c0                	test   %eax,%eax
f0102906:	74 16                	je     f010291e <mspin_unlock+0x37>
		if (Cmpxchg(&lk->locked, tmp, NULL) == me)
			return;
		while (me->next == NULL)
			continue;
	}
	me->next->waiting = 0;
f0102908:	69 d2 b8 00 00 00    	imul   $0xb8,%edx,%edx
f010290e:	8b 82 d4 40 12 f0    	mov    -0xfedbf2c(%edx),%eax
f0102914:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f010291a:	5b                   	pop    %ebx
f010291b:	5e                   	pop    %esi
f010291c:	5d                   	pop    %ebp
f010291d:	c3                   	ret    
	struct mcslock_node *me = &thiscpu->node;
f010291e:	69 ca b8 00 00 00    	imul   $0xb8,%edx,%ecx
f0102924:	81 c1 d0 40 12 f0    	add    $0xf01240d0,%ecx
	asm volatile("lock; cmpxchgl %2, %1"
f010292a:	bb 00 00 00 00       	mov    $0x0,%ebx
f010292f:	8b 75 08             	mov    0x8(%ebp),%esi
f0102932:	89 c8                	mov    %ecx,%eax
f0102934:	f0 0f b1 1e          	lock cmpxchg %ebx,(%esi)
		if (Cmpxchg(&lk->locked, tmp, NULL) == me)
f0102938:	39 c1                	cmp    %eax,%ecx
f010293a:	74 de                	je     f010291a <mspin_unlock+0x33>
		while (me->next == NULL)
f010293c:	69 c2 b8 00 00 00    	imul   $0xb8,%edx,%eax
f0102942:	05 20 40 12 f0       	add    $0xf0124020,%eax
f0102947:	8b 88 b4 00 00 00    	mov    0xb4(%eax),%ecx
f010294d:	85 c9                	test   %ecx,%ecx
f010294f:	75 b7                	jne    f0102908 <mspin_unlock+0x21>
f0102951:	eb f4                	jmp    f0102947 <mspin_unlock+0x60>

f0102953 <irq_setmask_8259A>:
		irq_setmask_8259A(irq_mask_8259A);
}

void
irq_setmask_8259A(uint16_t mask)
{
f0102953:	55                   	push   %ebp
f0102954:	89 e5                	mov    %esp,%ebp
f0102956:	56                   	push   %esi
f0102957:	53                   	push   %ebx
f0102958:	8b 45 08             	mov    0x8(%ebp),%eax
	int i;
	irq_mask_8259A = mask;
f010295b:	66 a3 74 c7 11 f0    	mov    %ax,0xf011c774
	if (!didinit)
f0102961:	80 3d 35 32 12 f0 00 	cmpb   $0x0,0xf0123235
f0102968:	75 07                	jne    f0102971 <irq_setmask_8259A+0x1e>
	cprintf("enabled interrupts:");
	for (i = 0; i < 16; i++)
		if (~mask & (1<<i))
			cprintf(" %d", i);
	cprintf("\n");
}
f010296a:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010296d:	5b                   	pop    %ebx
f010296e:	5e                   	pop    %esi
f010296f:	5d                   	pop    %ebp
f0102970:	c3                   	ret    
f0102971:	89 c6                	mov    %eax,%esi
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102973:	ba 21 00 00 00       	mov    $0x21,%edx
f0102978:	ee                   	out    %al,(%dx)
	outb(IO_PIC2+1, (char)(mask >> 8));
f0102979:	66 c1 e8 08          	shr    $0x8,%ax
f010297d:	ba a1 00 00 00       	mov    $0xa1,%edx
f0102982:	ee                   	out    %al,(%dx)
	cprintf("enabled interrupts:");
f0102983:	83 ec 0c             	sub    $0xc,%esp
f0102986:	68 72 42 10 f0       	push   $0xf0104272
f010298b:	e8 f9 dd ff ff       	call   f0100789 <cprintf>
f0102990:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < 16; i++)
f0102993:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (~mask & (1<<i))
f0102998:	0f b7 f6             	movzwl %si,%esi
f010299b:	f7 d6                	not    %esi
f010299d:	eb 08                	jmp    f01029a7 <irq_setmask_8259A+0x54>
	for (i = 0; i < 16; i++)
f010299f:	83 c3 01             	add    $0x1,%ebx
f01029a2:	83 fb 10             	cmp    $0x10,%ebx
f01029a5:	74 18                	je     f01029bf <irq_setmask_8259A+0x6c>
		if (~mask & (1<<i))
f01029a7:	0f a3 de             	bt     %ebx,%esi
f01029aa:	73 f3                	jae    f010299f <irq_setmask_8259A+0x4c>
			cprintf(" %d", i);
f01029ac:	83 ec 08             	sub    $0x8,%esp
f01029af:	53                   	push   %ebx
f01029b0:	68 f9 43 10 f0       	push   $0xf01043f9
f01029b5:	e8 cf dd ff ff       	call   f0100789 <cprintf>
f01029ba:	83 c4 10             	add    $0x10,%esp
f01029bd:	eb e0                	jmp    f010299f <irq_setmask_8259A+0x4c>
	cprintf("\n");
f01029bf:	83 ec 0c             	sub    $0xc,%esp
f01029c2:	68 78 3c 10 f0       	push   $0xf0103c78
f01029c7:	e8 bd dd ff ff       	call   f0100789 <cprintf>
f01029cc:	83 c4 10             	add    $0x10,%esp
f01029cf:	eb 99                	jmp    f010296a <irq_setmask_8259A+0x17>

f01029d1 <pic_init>:
{
f01029d1:	55                   	push   %ebp
f01029d2:	89 e5                	mov    %esp,%ebp
f01029d4:	57                   	push   %edi
f01029d5:	56                   	push   %esi
f01029d6:	53                   	push   %ebx
f01029d7:	83 ec 0c             	sub    $0xc,%esp
	didinit = 1;
f01029da:	c6 05 35 32 12 f0 01 	movb   $0x1,0xf0123235
f01029e1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01029e6:	bb 21 00 00 00       	mov    $0x21,%ebx
f01029eb:	89 da                	mov    %ebx,%edx
f01029ed:	ee                   	out    %al,(%dx)
f01029ee:	b9 a1 00 00 00       	mov    $0xa1,%ecx
f01029f3:	89 ca                	mov    %ecx,%edx
f01029f5:	ee                   	out    %al,(%dx)
f01029f6:	bf 11 00 00 00       	mov    $0x11,%edi
f01029fb:	be 20 00 00 00       	mov    $0x20,%esi
f0102a00:	89 f8                	mov    %edi,%eax
f0102a02:	89 f2                	mov    %esi,%edx
f0102a04:	ee                   	out    %al,(%dx)
f0102a05:	b8 20 00 00 00       	mov    $0x20,%eax
f0102a0a:	89 da                	mov    %ebx,%edx
f0102a0c:	ee                   	out    %al,(%dx)
f0102a0d:	b8 04 00 00 00       	mov    $0x4,%eax
f0102a12:	ee                   	out    %al,(%dx)
f0102a13:	b8 03 00 00 00       	mov    $0x3,%eax
f0102a18:	ee                   	out    %al,(%dx)
f0102a19:	bb a0 00 00 00       	mov    $0xa0,%ebx
f0102a1e:	89 f8                	mov    %edi,%eax
f0102a20:	89 da                	mov    %ebx,%edx
f0102a22:	ee                   	out    %al,(%dx)
f0102a23:	b8 28 00 00 00       	mov    $0x28,%eax
f0102a28:	89 ca                	mov    %ecx,%edx
f0102a2a:	ee                   	out    %al,(%dx)
f0102a2b:	b8 02 00 00 00       	mov    $0x2,%eax
f0102a30:	ee                   	out    %al,(%dx)
f0102a31:	b8 01 00 00 00       	mov    $0x1,%eax
f0102a36:	ee                   	out    %al,(%dx)
f0102a37:	bf 68 00 00 00       	mov    $0x68,%edi
f0102a3c:	89 f8                	mov    %edi,%eax
f0102a3e:	89 f2                	mov    %esi,%edx
f0102a40:	ee                   	out    %al,(%dx)
f0102a41:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0102a46:	89 c8                	mov    %ecx,%eax
f0102a48:	ee                   	out    %al,(%dx)
f0102a49:	89 f8                	mov    %edi,%eax
f0102a4b:	89 da                	mov    %ebx,%edx
f0102a4d:	ee                   	out    %al,(%dx)
f0102a4e:	89 c8                	mov    %ecx,%eax
f0102a50:	ee                   	out    %al,(%dx)
	if (irq_mask_8259A != 0xFFFF)
f0102a51:	0f b7 05 74 c7 11 f0 	movzwl 0xf011c774,%eax
f0102a58:	66 83 f8 ff          	cmp    $0xffff,%ax
f0102a5c:	74 0f                	je     f0102a6d <pic_init+0x9c>
		irq_setmask_8259A(irq_mask_8259A);
f0102a5e:	83 ec 0c             	sub    $0xc,%esp
f0102a61:	0f b7 c0             	movzwl %ax,%eax
f0102a64:	50                   	push   %eax
f0102a65:	e8 e9 fe ff ff       	call   f0102953 <irq_setmask_8259A>
f0102a6a:	83 c4 10             	add    $0x10,%esp
}
f0102a6d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102a70:	5b                   	pop    %ebx
f0102a71:	5e                   	pop    %esi
f0102a72:	5f                   	pop    %edi
f0102a73:	5d                   	pop    %ebp
f0102a74:	c3                   	ret    

f0102a75 <forkret>:
}


void
forkret(void)
{
f0102a75:	55                   	push   %ebp
f0102a76:	89 e5                	mov    %esp,%ebp
f0102a78:	83 ec 14             	sub    $0x14,%esp
	// Return to "caller", actually trapret (see proc_alloc)
	// That means the first proc starts here.
	// When it returns from forkret, it need to return to trapret.
	// TODO: your code here.
	spin_unlock(&ptable.lock);
f0102a7b:	68 20 50 16 f0       	push   $0xf0165020
f0102a80:	e8 16 fe ff ff       	call   f010289b <spin_unlock>

}
f0102a85:	83 c4 10             	add    $0x10,%esp
f0102a88:	c9                   	leave  
f0102a89:	c3                   	ret    

f0102a8a <proc_init>:
{
f0102a8a:	55                   	push   %ebp
f0102a8b:	89 e5                	mov    %esp,%ebp
f0102a8d:	83 ec 10             	sub    $0x10,%esp
	__spin_initlock(&ptable.lock, "ptable");
f0102a90:	68 86 42 10 f0       	push   $0xf0104286
f0102a95:	68 20 50 16 f0       	push   $0xf0165020
f0102a9a:	e8 07 fd ff ff       	call   f01027a6 <__spin_initlock>
}
f0102a9f:	83 c4 10             	add    $0x10,%esp
f0102aa2:	c9                   	leave  
f0102aa3:	c3                   	ret    

f0102aa4 <user_init>:
{
f0102aa4:	55                   	push   %ebp
f0102aa5:	89 e5                	mov    %esp,%ebp
f0102aa7:	57                   	push   %edi
f0102aa8:	56                   	push   %esi
f0102aa9:	53                   	push   %ebx
f0102aaa:	83 ec 28             	sub    $0x28,%esp
	spin_lock(&ptable.lock);
f0102aad:	68 20 50 16 f0       	push   $0xf0165020
f0102ab2:	e8 25 fd ff ff       	call   f01027dc <spin_lock>
f0102ab7:	83 c4 10             	add    $0x10,%esp
	for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
f0102aba:	bb 54 50 16 f0       	mov    $0xf0165054,%ebx
		if (p->state == UNUSED) {
f0102abf:	83 7b 08 00          	cmpl   $0x0,0x8(%ebx)
f0102ac3:	74 32                	je     f0102af7 <user_init+0x53>
	for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
f0102ac5:	83 c3 1c             	add    $0x1c,%ebx
f0102ac8:	81 fb 54 57 16 f0    	cmp    $0xf0165754,%ebx
f0102ace:	72 ef                	jb     f0102abf <user_init+0x1b>
	spin_unlock(&ptable.lock);
f0102ad0:	83 ec 0c             	sub    $0xc,%esp
f0102ad3:	68 20 50 16 f0       	push   $0xf0165020
f0102ad8:	e8 be fd ff ff       	call   f010289b <spin_unlock>
f0102add:	83 c4 10             	add    $0x10,%esp
		panic("Allocate User Process.");
f0102ae0:	83 ec 04             	sub    $0x4,%esp
f0102ae3:	68 8d 42 10 f0       	push   $0xf010428d
f0102ae8:	68 ad 00 00 00       	push   $0xad
f0102aed:	68 a4 42 10 f0       	push   $0xf01042a4
f0102af2:	e8 a8 d6 ff ff       	call   f010019f <_panic>
			p->state = EMBRYO;
f0102af7:	c7 43 08 01 00 00 00 	movl   $0x1,0x8(%ebx)
			p->pid = nextpid++;
f0102afe:	a1 78 c7 11 f0       	mov    0xf011c778,%eax
f0102b03:	8d 50 01             	lea    0x1(%eax),%edx
f0102b06:	89 15 78 c7 11 f0    	mov    %edx,0xf011c778
f0102b0c:	89 43 0c             	mov    %eax,0xc(%ebx)
			spin_unlock(&ptable.lock);
f0102b0f:	83 ec 0c             	sub    $0xc,%esp
f0102b12:	68 20 50 16 f0       	push   $0xf0165020
f0102b17:	e8 7f fd ff ff       	call   f010289b <spin_unlock>
			if ((p->kstack = kalloc()) == NULL) {
f0102b1c:	e8 1b f4 ff ff       	call   f0101f3c <kalloc>
f0102b21:	89 43 04             	mov    %eax,0x4(%ebx)
f0102b24:	83 c4 10             	add    $0x10,%esp
f0102b27:	85 c0                	test   %eax,%eax
f0102b29:	0f 84 3c 01 00 00    	je     f0102c6b <user_init+0x1c7>
			begin -= sizeof(*p->tf);
f0102b2f:	8d 90 b4 0f 00 00    	lea    0xfb4(%eax),%edx
f0102b35:	89 53 14             	mov    %edx,0x14(%ebx)
			*(uint32_t *)begin = (uint32_t)trapret;
f0102b38:	c7 80 b0 0f 00 00 0e 	movl   $0xf010090e,0xfb0(%eax)
f0102b3f:	09 10 f0 
			begin -= sizeof(*p->context);
f0102b42:	05 9c 0f 00 00       	add    $0xf9c,%eax
			p->context = (struct context *)begin;
f0102b47:	89 43 18             	mov    %eax,0x18(%ebx)
			memset(p->context, 0, sizeof(*p->context));
f0102b4a:	83 ec 04             	sub    $0x4,%esp
f0102b4d:	6a 14                	push   $0x14
f0102b4f:	6a 00                	push   $0x0
f0102b51:	50                   	push   %eax
f0102b52:	e8 61 0c 00 00       	call   f01037b8 <memset>
			p->context->eip = (uint32_t)forkret;
f0102b57:	8b 43 18             	mov    0x18(%ebx),%eax
f0102b5a:	c7 40 10 75 2a 10 f0 	movl   $0xf0102a75,0x10(%eax)
	if ((child = proc_alloc()) == NULL)
f0102b61:	83 c4 10             	add    $0x10,%esp
f0102b64:	85 db                	test   %ebx,%ebx
f0102b66:	0f 84 74 ff ff ff    	je     f0102ae0 <user_init+0x3c>
	cprintf("Finish allocate proc.\n");
f0102b6c:	83 ec 0c             	sub    $0xc,%esp
f0102b6f:	68 b0 42 10 f0       	push   $0xf01042b0
f0102b74:	e8 10 dc ff ff       	call   f0100789 <cprintf>
	if ((child->pgdir = kvm_init()) == NULL)
f0102b79:	e8 a3 ea ff ff       	call   f0101621 <kvm_init>
f0102b7e:	89 03                	mov    %eax,(%ebx)
f0102b80:	83 c4 10             	add    $0x10,%esp
f0102b83:	85 c0                	test   %eax,%eax
f0102b85:	0f 84 ec 00 00 00    	je     f0102c77 <user_init+0x1d3>
	cprintf("Finish allocate pgdir %x.\n", child->pgdir);
f0102b8b:	83 ec 08             	sub    $0x8,%esp
f0102b8e:	50                   	push   %eax
f0102b8f:	68 d5 42 10 f0       	push   $0xf01042d5
f0102b94:	e8 f0 db ff ff       	call   f0100789 <cprintf>
	cprintf("%s", child->parent);
f0102b99:	83 c4 08             	add    $0x8,%esp
f0102b9c:	ff 73 10             	pushl  0x10(%ebx)
f0102b9f:	68 a4 3f 10 f0       	push   $0xf0103fa4
f0102ba4:	e8 e0 db ff ff       	call   f0100789 <cprintf>
	cprintf("Before Load.\n");
f0102ba9:	c7 04 24 f0 42 10 f0 	movl   $0xf01042f0,(%esp)
f0102bb0:	e8 d4 db ff ff       	call   f0100789 <cprintf>
	cprintf("start: %x, size: %x\n", _binary_obj_user_hello_start, _binary_obj_user_hello_size);
f0102bb5:	83 c4 0c             	add    $0xc,%esp
f0102bb8:	ff 35 54 67 00 00    	pushl  0x6754
f0102bbe:	ff 35 7c c7 11 f0    	pushl  0xf011c77c
f0102bc4:	68 fe 42 10 f0       	push   $0xf01042fe
f0102bc9:	e8 bb db ff ff       	call   f0100789 <cprintf>
	ucode_load(child, (uint8_t *)_binary_obj_user_hello_start);
f0102bce:	8b 3d 7c c7 11 f0    	mov    0xf011c77c,%edi
	cprintf("Enter alloc.\n");
f0102bd4:	c7 04 24 13 43 10 f0 	movl   $0xf0104313,(%esp)
f0102bdb:	e8 a9 db ff ff       	call   f0100789 <cprintf>
	cprintf("Before assigning elf.\n");
f0102be0:	c7 04 24 21 43 10 f0 	movl   $0xf0104321,(%esp)
f0102be7:	e8 9d db ff ff       	call   f0100789 <cprintf>
	cprintf("%x", elf);
f0102bec:	83 c4 08             	add    $0x8,%esp
f0102bef:	57                   	push   %edi
f0102bf0:	68 38 43 10 f0       	push   $0xf0104338
f0102bf5:	e8 8f db ff ff       	call   f0100789 <cprintf>
	cprintf("Before assigning begin.\n");
f0102bfa:	c7 04 24 3b 43 10 f0 	movl   $0xf010433b,(%esp)
f0102c01:	e8 83 db ff ff       	call   f0100789 <cprintf>
	cprintf("%x\n", elf->e_entry);
f0102c06:	83 c4 08             	add    $0x8,%esp
f0102c09:	ff 77 18             	pushl  0x18(%edi)
f0102c0c:	68 0f 43 10 f0       	push   $0xf010430f
f0102c11:	e8 73 db ff ff       	call   f0100789 <cprintf>
	char *begin = (char *)elf->e_entry;
f0102c16:	8b 47 18             	mov    0x18(%edi),%eax
f0102c19:	89 c6                	mov    %eax,%esi
f0102c1b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	cprintf("After assigning begin.\n");
f0102c1e:	c7 04 24 54 43 10 f0 	movl   $0xf0104354,(%esp)
f0102c25:	e8 5f db ff ff       	call   f0100789 <cprintf>
	p->tf->eip = (uintptr_t)begin;
f0102c2a:	8b 43 14             	mov    0x14(%ebx),%eax
f0102c2d:	89 70 38             	mov    %esi,0x38(%eax)
	cprintf("Before alloc.\n");
f0102c30:	c7 04 24 6c 43 10 f0 	movl   $0xf010436c,(%esp)
f0102c37:	e8 4d db ff ff       	call   f0100789 <cprintf>
	region_alloc(p, begin, (int)_binary_obj_user_hello_size);
f0102c3c:	83 c4 0c             	add    $0xc,%esp
f0102c3f:	ff 35 54 67 00 00    	pushl  0x6754
f0102c45:	56                   	push   %esi
f0102c46:	53                   	push   %ebx
f0102c47:	e8 a1 eb ff ff       	call   f01017ed <region_alloc>
	cprintf("After alloc.\n");
f0102c4c:	c7 04 24 7b 43 10 f0 	movl   $0xf010437b,(%esp)
f0102c53:	e8 31 db ff ff       	call   f0100789 <cprintf>
	ph = (struct Proghdr *) (binary + elf->e_phoff);
f0102c58:	89 fe                	mov    %edi,%esi
f0102c5a:	03 77 1c             	add    0x1c(%edi),%esi
	eph = ph + elf->e_phnum;
f0102c5d:	0f b7 7f 2c          	movzwl 0x2c(%edi),%edi
f0102c61:	c1 e7 05             	shl    $0x5,%edi
f0102c64:	01 f7                	add    %esi,%edi
f0102c66:	83 c4 10             	add    $0x10,%esp
f0102c69:	eb 3d                	jmp    f0102ca8 <user_init+0x204>
				p->state = UNUSED;
f0102c6b:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
f0102c72:	e9 69 fe ff ff       	jmp    f0102ae0 <user_init+0x3c>
		panic("User Pagedir.");
f0102c77:	83 ec 04             	sub    $0x4,%esp
f0102c7a:	68 c7 42 10 f0       	push   $0xf01042c7
f0102c7f:	68 b0 00 00 00       	push   $0xb0
f0102c84:	68 a4 42 10 f0       	push   $0xf01042a4
f0102c89:	e8 11 d5 ff ff       	call   f010019f <_panic>
				panic("Load segment.");
f0102c8e:	83 ec 04             	sub    $0x4,%esp
f0102c91:	68 89 43 10 f0       	push   $0xf0104389
f0102c96:	68 94 00 00 00       	push   $0x94
f0102c9b:	68 a4 42 10 f0       	push   $0xf01042a4
f0102ca0:	e8 fa d4 ff ff       	call   f010019f <_panic>
	for (; ph < eph; ph++)
f0102ca5:	83 c6 20             	add    $0x20,%esi
f0102ca8:	39 f7                	cmp    %esi,%edi
f0102caa:	76 22                	jbe    f0102cce <user_init+0x22a>
		if (ph->p_type == ELF_PROG_LOAD) {
f0102cac:	83 3e 01             	cmpl   $0x1,(%esi)
f0102caf:	75 f4                	jne    f0102ca5 <user_init+0x201>
			if (loaduvm(p->pgdir, begin, ph) < 0)
f0102cb1:	83 ec 04             	sub    $0x4,%esp
f0102cb4:	56                   	push   %esi
f0102cb5:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102cb8:	ff 33                	pushl  (%ebx)
f0102cba:	e8 e6 e8 ff ff       	call   f01015a5 <loaduvm>
f0102cbf:	83 c4 10             	add    $0x10,%esp
f0102cc2:	85 c0                	test   %eax,%eax
f0102cc4:	78 c8                	js     f0102c8e <user_init+0x1ea>
			begin += ph->p_memsz;
f0102cc6:	8b 4e 14             	mov    0x14(%esi),%ecx
f0102cc9:	01 4d e4             	add    %ecx,-0x1c(%ebp)
f0102ccc:	eb d7                	jmp    f0102ca5 <user_init+0x201>
	char *stack = kalloc();
f0102cce:	e8 69 f2 ff ff       	call   f0101f3c <kalloc>
	p->tf->esp = USTACKTOP;
f0102cd3:	8b 53 14             	mov    0x14(%ebx),%edx
f0102cd6:	c7 42 44 00 00 00 d0 	movl   $0xd0000000,0x44(%edx)
	if (map_region(p->pgdir, (void *)(USTACKTOP - PGSIZE), PGSIZE, V2P(stack), PTE_U | PTE_W) < 0)
f0102cdd:	83 ec 0c             	sub    $0xc,%esp
f0102ce0:	6a 06                	push   $0x6
f0102ce2:	05 00 00 00 10       	add    $0x10000000,%eax
f0102ce7:	50                   	push   %eax
f0102ce8:	68 00 10 00 00       	push   $0x1000
f0102ced:	68 00 f0 ff cf       	push   $0xcffff000
f0102cf2:	ff 33                	pushl  (%ebx)
f0102cf4:	e8 34 e8 ff ff       	call   f010152d <map_region>
f0102cf9:	83 c4 20             	add    $0x20,%esp
f0102cfc:	85 c0                	test   %eax,%eax
f0102cfe:	78 7d                	js     f0102d7d <user_init+0x2d9>
	cprintf("Finish Load.\n");
f0102d00:	83 ec 0c             	sub    $0xc,%esp
f0102d03:	68 a3 43 10 f0       	push   $0xf01043a3
f0102d08:	e8 7c da ff ff       	call   f0100789 <cprintf>
	memset(child->tf, 0, sizeof(*child->tf));
f0102d0d:	83 c4 0c             	add    $0xc,%esp
f0102d10:	6a 4c                	push   $0x4c
f0102d12:	6a 00                	push   $0x0
f0102d14:	ff 73 14             	pushl  0x14(%ebx)
f0102d17:	e8 9c 0a 00 00       	call   f01037b8 <memset>
	child->tf->cs = (SEG_UCODE << 3) | DPL_USER;
f0102d1c:	8b 43 14             	mov    0x14(%ebx),%eax
f0102d1f:	66 c7 40 3c 1b 00    	movw   $0x1b,0x3c(%eax)
	child->tf->ds = (SEG_UDATA << 3) | DPL_USER;
f0102d25:	8b 43 14             	mov    0x14(%ebx),%eax
f0102d28:	66 c7 40 2c 23 00    	movw   $0x23,0x2c(%eax)
	child->tf->es = (SEG_UDATA << 3) | DPL_USER;
f0102d2e:	8b 43 14             	mov    0x14(%ebx),%eax
f0102d31:	66 c7 40 28 23 00    	movw   $0x23,0x28(%eax)
	child->tf->ss = (SEG_UDATA << 3) | DPL_USER;
f0102d37:	8b 43 14             	mov    0x14(%ebx),%eax
f0102d3a:	66 c7 40 48 23 00    	movw   $0x23,0x48(%eax)
	child->tf->eflags = FL_IF;
f0102d40:	8b 43 14             	mov    0x14(%ebx),%eax
f0102d43:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
	spin_lock(&ptable.lock);
f0102d4a:	c7 04 24 20 50 16 f0 	movl   $0xf0165020,(%esp)
f0102d51:	e8 86 fa ff ff       	call   f01027dc <spin_lock>
	child->state = RUNNABLE;
f0102d56:	c7 43 08 03 00 00 00 	movl   $0x3,0x8(%ebx)
	spin_unlock(&ptable.lock);
f0102d5d:	c7 04 24 20 50 16 f0 	movl   $0xf0165020,(%esp)
f0102d64:	e8 32 fb ff ff       	call   f010289b <spin_unlock>
	cprintf("Finish all the environment for usr.\n");
f0102d69:	c7 04 24 b4 43 10 f0 	movl   $0xf01043b4,(%esp)
f0102d70:	e8 14 da ff ff       	call   f0100789 <cprintf>
}
f0102d75:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102d78:	5b                   	pop    %ebx
f0102d79:	5e                   	pop    %esi
f0102d7a:	5f                   	pop    %edi
f0102d7b:	5d                   	pop    %ebp
f0102d7c:	c3                   	ret    
		panic("USER STACK.");
f0102d7d:	83 ec 04             	sub    $0x4,%esp
f0102d80:	68 97 43 10 f0       	push   $0xf0104397
f0102d85:	68 9d 00 00 00       	push   $0x9d
f0102d8a:	68 a4 42 10 f0       	push   $0xf01042a4
f0102d8f:	e8 0b d4 ff ff       	call   f010019f <_panic>

f0102d94 <ucode_run>:
{
f0102d94:	55                   	push   %ebp
f0102d95:	89 e5                	mov    %esp,%ebp
f0102d97:	56                   	push   %esi
f0102d98:	53                   	push   %ebx
	thiscpu->proc = NULL;
f0102d99:	e8 e6 f7 ff ff       	call   f0102584 <cpunum>
f0102d9e:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f0102da4:	c7 80 c4 40 12 f0 00 	movl   $0x0,-0xfedbf3c(%eax)
f0102dab:	00 00 00 
f0102dae:	eb 7e                	jmp    f0102e2e <ucode_run+0x9a>
		for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
f0102db0:	83 c3 1c             	add    $0x1c,%ebx
f0102db3:	81 fb 54 57 16 f0    	cmp    $0xf0165754,%ebx
f0102db9:	73 63                	jae    f0102e1e <ucode_run+0x8a>
			if (p->state == RUNNABLE) {
f0102dbb:	83 7b 08 03          	cmpl   $0x3,0x8(%ebx)
f0102dbf:	75 ef                	jne    f0102db0 <ucode_run+0x1c>
				uvm_switch(p);
f0102dc1:	83 ec 0c             	sub    $0xc,%esp
f0102dc4:	53                   	push   %ebx
f0102dc5:	e8 6d eb ff ff       	call   f0101937 <uvm_switch>
				p->state = RUNNING;
f0102dca:	c7 43 08 04 00 00 00 	movl   $0x4,0x8(%ebx)
				thiscpu->proc = p;
f0102dd1:	e8 ae f7 ff ff       	call   f0102584 <cpunum>
f0102dd6:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f0102ddc:	89 98 c4 40 12 f0    	mov    %ebx,-0xfedbf3c(%eax)
				swtch(&thiscpu->scheduler, p->context);
f0102de2:	8b 73 18             	mov    0x18(%ebx),%esi
f0102de5:	e8 9a f7 ff ff       	call   f0102584 <cpunum>
f0102dea:	83 c4 08             	add    $0x8,%esp
f0102ded:	56                   	push   %esi
f0102dee:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f0102df4:	05 28 40 12 f0       	add    $0xf0124028,%eax
f0102df9:	50                   	push   %eax
f0102dfa:	e8 76 01 00 00       	call   f0102f75 <swtch>
				kvm_switch();
f0102dff:	e8 91 e8 ff ff       	call   f0101695 <kvm_switch>
				thiscpu->proc = NULL;
f0102e04:	e8 7b f7 ff ff       	call   f0102584 <cpunum>
f0102e09:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f0102e0f:	c7 80 c4 40 12 f0 00 	movl   $0x0,-0xfedbf3c(%eax)
f0102e16:	00 00 00 
f0102e19:	83 c4 10             	add    $0x10,%esp
f0102e1c:	eb 92                	jmp    f0102db0 <ucode_run+0x1c>
		spin_unlock(&ptable.lock);
f0102e1e:	83 ec 0c             	sub    $0xc,%esp
f0102e21:	68 20 50 16 f0       	push   $0xf0165020
f0102e26:	e8 70 fa ff ff       	call   f010289b <spin_unlock>
		sti();
f0102e2b:	83 c4 10             	add    $0x10,%esp
	asm volatile("sti");
f0102e2e:	fb                   	sti    
		spin_lock(&ptable.lock);
f0102e2f:	83 ec 0c             	sub    $0xc,%esp
f0102e32:	68 20 50 16 f0       	push   $0xf0165020
f0102e37:	e8 a0 f9 ff ff       	call   f01027dc <spin_lock>
f0102e3c:	83 c4 10             	add    $0x10,%esp
		for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
f0102e3f:	bb 54 50 16 f0       	mov    $0xf0165054,%ebx
f0102e44:	e9 72 ff ff ff       	jmp    f0102dbb <ucode_run+0x27>

f0102e49 <thisproc>:
thisproc(void) {
f0102e49:	55                   	push   %ebp
f0102e4a:	89 e5                	mov    %esp,%ebp
f0102e4c:	53                   	push   %ebx
f0102e4d:	83 ec 04             	sub    $0x4,%esp
	pushcli();
f0102e50:	e8 0d ea ff ff       	call   f0101862 <pushcli>
	p = thiscpu->proc;
f0102e55:	e8 2a f7 ff ff       	call   f0102584 <cpunum>
f0102e5a:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f0102e60:	8b 98 c4 40 12 f0    	mov    -0xfedbf3c(%eax),%ebx
	popcli();
f0102e66:	e8 46 ea ff ff       	call   f01018b1 <popcli>
}
f0102e6b:	89 d8                	mov    %ebx,%eax
f0102e6d:	83 c4 04             	add    $0x4,%esp
f0102e70:	5b                   	pop    %ebx
f0102e71:	5d                   	pop    %ebp
f0102e72:	c3                   	ret    

f0102e73 <sched>:
{
f0102e73:	55                   	push   %ebp
f0102e74:	89 e5                	mov    %esp,%ebp
f0102e76:	53                   	push   %ebx
f0102e77:	83 ec 04             	sub    $0x4,%esp
	struct proc *p = thisproc();
f0102e7a:	e8 ca ff ff ff       	call   f0102e49 <thisproc>
f0102e7f:	89 c3                	mov    %eax,%ebx
	swtch(&p->context, thiscpu->scheduler);
f0102e81:	e8 fe f6 ff ff       	call   f0102584 <cpunum>
f0102e86:	83 ec 08             	sub    $0x8,%esp
f0102e89:	69 c0 b8 00 00 00    	imul   $0xb8,%eax,%eax
f0102e8f:	ff b0 28 40 12 f0    	pushl  -0xfedbfd8(%eax)
f0102e95:	83 c3 18             	add    $0x18,%ebx
f0102e98:	53                   	push   %ebx
f0102e99:	e8 d7 00 00 00       	call   f0102f75 <swtch>
}
f0102e9e:	83 c4 10             	add    $0x10,%esp
f0102ea1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102ea4:	c9                   	leave  
f0102ea5:	c3                   	ret    

f0102ea6 <exit>:

void
exit(void)
{
f0102ea6:	55                   	push   %ebp
f0102ea7:	89 e5                	mov    %esp,%ebp
f0102ea9:	53                   	push   %ebx
f0102eaa:	83 ec 04             	sub    $0x4,%esp
	// sys_exit() call to here.
	// TODO: your code here.
	struct proc *p = thisproc();
f0102ead:	e8 97 ff ff ff       	call   f0102e49 <thisproc>
f0102eb2:	89 c3                	mov    %eax,%ebx
	spin_lock(&ptable.lock);
f0102eb4:	83 ec 0c             	sub    $0xc,%esp
f0102eb7:	68 20 50 16 f0       	push   $0xf0165020
f0102ebc:	e8 1b f9 ff ff       	call   f01027dc <spin_lock>
	p->state = ZOMBIE;
f0102ec1:	c7 43 08 05 00 00 00 	movl   $0x5,0x8(%ebx)
	sched();
f0102ec8:	e8 a6 ff ff ff       	call   f0102e73 <sched>
f0102ecd:	83 c4 10             	add    $0x10,%esp
f0102ed0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102ed3:	c9                   	leave  
f0102ed4:	c3                   	ret    

f0102ed5 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f0102ed5:	55                   	push   %ebp
f0102ed6:	89 e5                	mov    %esp,%ebp
f0102ed8:	57                   	push   %edi
f0102ed9:	56                   	push   %esi
f0102eda:	53                   	push   %ebx
f0102edb:	83 ec 0c             	sub    $0xc,%esp
f0102ede:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// TODO: Your code here.
	struct proc *p = thisproc();
f0102ee1:	e8 63 ff ff ff       	call   f0102e49 <thisproc>
	switch (syscallno) {
f0102ee6:	83 fb 01             	cmp    $0x1,%ebx
f0102ee9:	74 77                	je     f0102f62 <syscall+0x8d>
f0102eeb:	83 fb 01             	cmp    $0x1,%ebx
f0102eee:	72 0c                	jb     f0102efc <syscall+0x27>
f0102ef0:	83 fb 02             	cmp    $0x2,%ebx
f0102ef3:	74 74                	je     f0102f69 <syscall+0x94>
		case SYS_exit:
			sys_exit();
			return 0;

		default:
			return 0;
f0102ef5:	b8 00 00 00 00       	mov    $0x0,%eax
f0102efa:	eb 5e                	jmp    f0102f5a <syscall+0x85>
	struct proc *p = thisproc();
f0102efc:	e8 48 ff ff ff       	call   f0102e49 <thisproc>
f0102f01:	89 c7                	mov    %eax,%edi
	void *begin = ROUNDDOWN(tmp, PGSIZE);
f0102f03:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102f06:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	void *end = ROUNDUP(tmp + len, PGSIZE);
f0102f0c:	8b 45 10             	mov    0x10(%ebp),%eax
f0102f0f:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102f12:	8d b4 02 ff 0f 00 00 	lea    0xfff(%edx,%eax,1),%esi
f0102f19:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
f0102f1f:	eb 05                	jmp    f0102f26 <syscall+0x51>
			exit();
f0102f21:	e8 80 ff ff ff       	call   f0102ea6 <exit>
	while (begin < end) {
f0102f26:	39 de                	cmp    %ebx,%esi
f0102f28:	76 1d                	jbe    f0102f47 <syscall+0x72>
		pte_t *pte = pgdir_walk(p->pgdir, begin, 0);
f0102f2a:	83 ec 04             	sub    $0x4,%esp
f0102f2d:	6a 00                	push   $0x0
f0102f2f:	53                   	push   %ebx
f0102f30:	ff 37                	pushl  (%edi)
f0102f32:	e8 7f e5 ff ff       	call   f01014b6 <pgdir_walk>
		if (*pte & PTE_U)
f0102f37:	83 c4 10             	add    $0x10,%esp
f0102f3a:	f6 00 04             	testb  $0x4,(%eax)
f0102f3d:	74 e2                	je     f0102f21 <syscall+0x4c>
			begin += PGSIZE;
f0102f3f:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102f45:	eb df                	jmp    f0102f26 <syscall+0x51>
	cprintf(s);
f0102f47:	83 ec 0c             	sub    $0xc,%esp
f0102f4a:	ff 75 0c             	pushl  0xc(%ebp)
f0102f4d:	e8 37 d8 ff ff       	call   f0100789 <cprintf>
f0102f52:	83 c4 10             	add    $0x10,%esp
			return 0;
f0102f55:	b8 00 00 00 00       	mov    $0x0,%eax
	}
	
f0102f5a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102f5d:	5b                   	pop    %ebx
f0102f5e:	5e                   	pop    %esi
f0102f5f:	5f                   	pop    %edi
f0102f60:	5d                   	pop    %ebp
f0102f61:	c3                   	ret    
	return cons_getc();
f0102f62:	e8 67 d6 ff ff       	call   f01005ce <cons_getc>
			return sys_cgetc();
f0102f67:	eb f1                	jmp    f0102f5a <syscall+0x85>
	exit();
f0102f69:	e8 38 ff ff ff       	call   f0102ea6 <exit>
			return 0;
f0102f6e:	b8 00 00 00 00       	mov    $0x0,%eax
f0102f73:	eb e5                	jmp    f0102f5a <syscall+0x85>

f0102f75 <swtch>:
# Switch stacks to new and pop previously-saved registers.

.globl swtch
swtch:
	# TODO: your code here
	movl 4(%esp), %eax # old
f0102f75:	8b 44 24 04          	mov    0x4(%esp),%eax
	movl 8(%esp), %edx # new
f0102f79:	8b 54 24 08          	mov    0x8(%esp),%edx
	# Save old callee-saved registers
	pushl %ebp
f0102f7d:	55                   	push   %ebp
	pushl %ebx
f0102f7e:	53                   	push   %ebx
	pushl %esi
f0102f7f:	56                   	push   %esi
	pushl %edi
f0102f80:	57                   	push   %edi
	# Switch stacks
	movl %esp, (%eax)
f0102f81:	89 20                	mov    %esp,(%eax)
	movl %edx, %esp
f0102f83:	89 d4                	mov    %edx,%esp
	# Load new callee-saved registers
	popl %edi
f0102f85:	5f                   	pop    %edi
	popl %esi
f0102f86:	5e                   	pop    %esi
	popl %ebx
f0102f87:	5b                   	pop    %ebx
	popl %ebp
f0102f88:	5d                   	pop    %ebp
f0102f89:	c3                   	ret    

f0102f8a <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0102f8a:	55                   	push   %ebp
f0102f8b:	89 e5                	mov    %esp,%ebp
f0102f8d:	57                   	push   %edi
f0102f8e:	56                   	push   %esi
f0102f8f:	53                   	push   %ebx
f0102f90:	83 ec 1c             	sub    $0x1c,%esp
f0102f93:	89 c7                	mov    %eax,%edi
f0102f95:	89 d6                	mov    %edx,%esi
f0102f97:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f9a:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102f9d:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102fa0:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0102fa3:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0102fa6:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102fab:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102fae:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0102fb1:	39 d3                	cmp    %edx,%ebx
f0102fb3:	72 05                	jb     f0102fba <printnum+0x30>
f0102fb5:	39 45 10             	cmp    %eax,0x10(%ebp)
f0102fb8:	77 7a                	ja     f0103034 <printnum+0xaa>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0102fba:	83 ec 0c             	sub    $0xc,%esp
f0102fbd:	ff 75 18             	pushl  0x18(%ebp)
f0102fc0:	8b 45 14             	mov    0x14(%ebp),%eax
f0102fc3:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0102fc6:	53                   	push   %ebx
f0102fc7:	ff 75 10             	pushl  0x10(%ebp)
f0102fca:	83 ec 08             	sub    $0x8,%esp
f0102fcd:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102fd0:	ff 75 e0             	pushl  -0x20(%ebp)
f0102fd3:	ff 75 dc             	pushl  -0x24(%ebp)
f0102fd6:	ff 75 d8             	pushl  -0x28(%ebp)
f0102fd9:	e8 e2 09 00 00       	call   f01039c0 <__udivdi3>
f0102fde:	83 c4 18             	add    $0x18,%esp
f0102fe1:	52                   	push   %edx
f0102fe2:	50                   	push   %eax
f0102fe3:	89 f2                	mov    %esi,%edx
f0102fe5:	89 f8                	mov    %edi,%eax
f0102fe7:	e8 9e ff ff ff       	call   f0102f8a <printnum>
f0102fec:	83 c4 20             	add    $0x20,%esp
f0102fef:	eb 13                	jmp    f0103004 <printnum+0x7a>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0102ff1:	83 ec 08             	sub    $0x8,%esp
f0102ff4:	56                   	push   %esi
f0102ff5:	ff 75 18             	pushl  0x18(%ebp)
f0102ff8:	ff d7                	call   *%edi
f0102ffa:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f0102ffd:	83 eb 01             	sub    $0x1,%ebx
f0103000:	85 db                	test   %ebx,%ebx
f0103002:	7f ed                	jg     f0102ff1 <printnum+0x67>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103004:	83 ec 08             	sub    $0x8,%esp
f0103007:	56                   	push   %esi
f0103008:	83 ec 04             	sub    $0x4,%esp
f010300b:	ff 75 e4             	pushl  -0x1c(%ebp)
f010300e:	ff 75 e0             	pushl  -0x20(%ebp)
f0103011:	ff 75 dc             	pushl  -0x24(%ebp)
f0103014:	ff 75 d8             	pushl  -0x28(%ebp)
f0103017:	e8 c4 0a 00 00       	call   f0103ae0 <__umoddi3>
f010301c:	83 c4 14             	add    $0x14,%esp
f010301f:	0f be 80 dc 43 10 f0 	movsbl -0xfefbc24(%eax),%eax
f0103026:	50                   	push   %eax
f0103027:	ff d7                	call   *%edi
}
f0103029:	83 c4 10             	add    $0x10,%esp
f010302c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010302f:	5b                   	pop    %ebx
f0103030:	5e                   	pop    %esi
f0103031:	5f                   	pop    %edi
f0103032:	5d                   	pop    %ebp
f0103033:	c3                   	ret    
f0103034:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0103037:	eb c4                	jmp    f0102ffd <printnum+0x73>

f0103039 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103039:	55                   	push   %ebp
f010303a:	89 e5                	mov    %esp,%ebp
f010303c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010303f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103043:	8b 10                	mov    (%eax),%edx
f0103045:	3b 50 04             	cmp    0x4(%eax),%edx
f0103048:	73 0a                	jae    f0103054 <sprintputch+0x1b>
		*b->buf++ = ch;
f010304a:	8d 4a 01             	lea    0x1(%edx),%ecx
f010304d:	89 08                	mov    %ecx,(%eax)
f010304f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103052:	88 02                	mov    %al,(%edx)
}
f0103054:	5d                   	pop    %ebp
f0103055:	c3                   	ret    

f0103056 <printfmt>:
{
f0103056:	55                   	push   %ebp
f0103057:	89 e5                	mov    %esp,%ebp
f0103059:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f010305c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010305f:	50                   	push   %eax
f0103060:	ff 75 10             	pushl  0x10(%ebp)
f0103063:	ff 75 0c             	pushl  0xc(%ebp)
f0103066:	ff 75 08             	pushl  0x8(%ebp)
f0103069:	e8 05 00 00 00       	call   f0103073 <vprintfmt>
}
f010306e:	83 c4 10             	add    $0x10,%esp
f0103071:	c9                   	leave  
f0103072:	c3                   	ret    

f0103073 <vprintfmt>:
{
f0103073:	55                   	push   %ebp
f0103074:	89 e5                	mov    %esp,%ebp
f0103076:	57                   	push   %edi
f0103077:	56                   	push   %esi
f0103078:	53                   	push   %ebx
f0103079:	83 ec 2c             	sub    $0x2c,%esp
f010307c:	8b 75 08             	mov    0x8(%ebp),%esi
f010307f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103082:	8b 7d 10             	mov    0x10(%ebp),%edi
f0103085:	e9 c1 03 00 00       	jmp    f010344b <vprintfmt+0x3d8>
		padc = ' ';
f010308a:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
f010308e:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
f0103095:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
		width = -1;
f010309c:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f01030a3:	b9 00 00 00 00       	mov    $0x0,%ecx
		switch (ch = *(unsigned char *) fmt++) {
f01030a8:	8d 47 01             	lea    0x1(%edi),%eax
f01030ab:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01030ae:	0f b6 17             	movzbl (%edi),%edx
f01030b1:	8d 42 dd             	lea    -0x23(%edx),%eax
f01030b4:	3c 55                	cmp    $0x55,%al
f01030b6:	0f 87 12 04 00 00    	ja     f01034ce <vprintfmt+0x45b>
f01030bc:	0f b6 c0             	movzbl %al,%eax
f01030bf:	ff 24 85 68 44 10 f0 	jmp    *-0xfefbb98(,%eax,4)
f01030c6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f01030c9:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f01030cd:	eb d9                	jmp    f01030a8 <vprintfmt+0x35>
		switch (ch = *(unsigned char *) fmt++) {
f01030cf:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '0';
f01030d2:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f01030d6:	eb d0                	jmp    f01030a8 <vprintfmt+0x35>
		switch (ch = *(unsigned char *) fmt++) {
f01030d8:	0f b6 d2             	movzbl %dl,%edx
f01030db:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f01030de:	b8 00 00 00 00       	mov    $0x0,%eax
f01030e3:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
				precision = precision * 10 + ch - '0';
f01030e6:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01030e9:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f01030ed:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f01030f0:	8d 4a d0             	lea    -0x30(%edx),%ecx
f01030f3:	83 f9 09             	cmp    $0x9,%ecx
f01030f6:	77 55                	ja     f010314d <vprintfmt+0xda>
			for (precision = 0; ; ++fmt) {
f01030f8:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f01030fb:	eb e9                	jmp    f01030e6 <vprintfmt+0x73>
			precision = va_arg(ap, int);
f01030fd:	8b 45 14             	mov    0x14(%ebp),%eax
f0103100:	8b 00                	mov    (%eax),%eax
f0103102:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103105:	8b 45 14             	mov    0x14(%ebp),%eax
f0103108:	8d 40 04             	lea    0x4(%eax),%eax
f010310b:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010310e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f0103111:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103115:	79 91                	jns    f01030a8 <vprintfmt+0x35>
				width = precision, precision = -1;
f0103117:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010311a:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010311d:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103124:	eb 82                	jmp    f01030a8 <vprintfmt+0x35>
f0103126:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103129:	85 c0                	test   %eax,%eax
f010312b:	ba 00 00 00 00       	mov    $0x0,%edx
f0103130:	0f 49 d0             	cmovns %eax,%edx
f0103133:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0103136:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103139:	e9 6a ff ff ff       	jmp    f01030a8 <vprintfmt+0x35>
f010313e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f0103141:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0103148:	e9 5b ff ff ff       	jmp    f01030a8 <vprintfmt+0x35>
f010314d:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0103150:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103153:	eb bc                	jmp    f0103111 <vprintfmt+0x9e>
			lflag++;
f0103155:	83 c1 01             	add    $0x1,%ecx
		switch (ch = *(unsigned char *) fmt++) {
f0103158:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f010315b:	e9 48 ff ff ff       	jmp    f01030a8 <vprintfmt+0x35>
			putch(va_arg(ap, int), putdat);
f0103160:	8b 45 14             	mov    0x14(%ebp),%eax
f0103163:	8d 78 04             	lea    0x4(%eax),%edi
f0103166:	83 ec 08             	sub    $0x8,%esp
f0103169:	53                   	push   %ebx
f010316a:	ff 30                	pushl  (%eax)
f010316c:	ff d6                	call   *%esi
			break;
f010316e:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f0103171:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f0103174:	e9 cf 02 00 00       	jmp    f0103448 <vprintfmt+0x3d5>
			err = va_arg(ap, int);
f0103179:	8b 45 14             	mov    0x14(%ebp),%eax
f010317c:	8d 78 04             	lea    0x4(%eax),%edi
f010317f:	8b 00                	mov    (%eax),%eax
f0103181:	99                   	cltd   
f0103182:	31 d0                	xor    %edx,%eax
f0103184:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0103186:	83 f8 06             	cmp    $0x6,%eax
f0103189:	7f 23                	jg     f01031ae <vprintfmt+0x13b>
f010318b:	8b 14 85 c0 45 10 f0 	mov    -0xfefba40(,%eax,4),%edx
f0103192:	85 d2                	test   %edx,%edx
f0103194:	74 18                	je     f01031ae <vprintfmt+0x13b>
				printfmt(putch, putdat, "%s", p);
f0103196:	52                   	push   %edx
f0103197:	68 a4 3f 10 f0       	push   $0xf0103fa4
f010319c:	53                   	push   %ebx
f010319d:	56                   	push   %esi
f010319e:	e8 b3 fe ff ff       	call   f0103056 <printfmt>
f01031a3:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f01031a6:	89 7d 14             	mov    %edi,0x14(%ebp)
f01031a9:	e9 9a 02 00 00       	jmp    f0103448 <vprintfmt+0x3d5>
				printfmt(putch, putdat, "error %d", err);
f01031ae:	50                   	push   %eax
f01031af:	68 f4 43 10 f0       	push   $0xf01043f4
f01031b4:	53                   	push   %ebx
f01031b5:	56                   	push   %esi
f01031b6:	e8 9b fe ff ff       	call   f0103056 <printfmt>
f01031bb:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f01031be:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f01031c1:	e9 82 02 00 00       	jmp    f0103448 <vprintfmt+0x3d5>
			if ((p = va_arg(ap, char *)) == NULL)
f01031c6:	8b 45 14             	mov    0x14(%ebp),%eax
f01031c9:	83 c0 04             	add    $0x4,%eax
f01031cc:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01031cf:	8b 45 14             	mov    0x14(%ebp),%eax
f01031d2:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f01031d4:	85 ff                	test   %edi,%edi
f01031d6:	b8 ed 43 10 f0       	mov    $0xf01043ed,%eax
f01031db:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f01031de:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01031e2:	0f 8e bd 00 00 00    	jle    f01032a5 <vprintfmt+0x232>
f01031e8:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f01031ec:	75 0e                	jne    f01031fc <vprintfmt+0x189>
f01031ee:	89 75 08             	mov    %esi,0x8(%ebp)
f01031f1:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01031f4:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01031f7:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f01031fa:	eb 6d                	jmp    f0103269 <vprintfmt+0x1f6>
				for (width -= strnlen(p, precision); width > 0; width--)
f01031fc:	83 ec 08             	sub    $0x8,%esp
f01031ff:	ff 75 d0             	pushl  -0x30(%ebp)
f0103202:	57                   	push   %edi
f0103203:	e8 50 04 00 00       	call   f0103658 <strnlen>
f0103208:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f010320b:	29 c1                	sub    %eax,%ecx
f010320d:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0103210:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0103213:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0103217:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010321a:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f010321d:	89 cf                	mov    %ecx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f010321f:	eb 0f                	jmp    f0103230 <vprintfmt+0x1bd>
					putch(padc, putdat);
f0103221:	83 ec 08             	sub    $0x8,%esp
f0103224:	53                   	push   %ebx
f0103225:	ff 75 e0             	pushl  -0x20(%ebp)
f0103228:	ff d6                	call   *%esi
				for (width -= strnlen(p, precision); width > 0; width--)
f010322a:	83 ef 01             	sub    $0x1,%edi
f010322d:	83 c4 10             	add    $0x10,%esp
f0103230:	85 ff                	test   %edi,%edi
f0103232:	7f ed                	jg     f0103221 <vprintfmt+0x1ae>
f0103234:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103237:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f010323a:	85 c9                	test   %ecx,%ecx
f010323c:	b8 00 00 00 00       	mov    $0x0,%eax
f0103241:	0f 49 c1             	cmovns %ecx,%eax
f0103244:	29 c1                	sub    %eax,%ecx
f0103246:	89 75 08             	mov    %esi,0x8(%ebp)
f0103249:	8b 75 d0             	mov    -0x30(%ebp),%esi
f010324c:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010324f:	89 cb                	mov    %ecx,%ebx
f0103251:	eb 16                	jmp    f0103269 <vprintfmt+0x1f6>
				if (altflag && (ch < ' ' || ch > '~'))
f0103253:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0103257:	75 31                	jne    f010328a <vprintfmt+0x217>
					putch(ch, putdat);
f0103259:	83 ec 08             	sub    $0x8,%esp
f010325c:	ff 75 0c             	pushl  0xc(%ebp)
f010325f:	50                   	push   %eax
f0103260:	ff 55 08             	call   *0x8(%ebp)
f0103263:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103266:	83 eb 01             	sub    $0x1,%ebx
f0103269:	83 c7 01             	add    $0x1,%edi
f010326c:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
f0103270:	0f be c2             	movsbl %dl,%eax
f0103273:	85 c0                	test   %eax,%eax
f0103275:	74 59                	je     f01032d0 <vprintfmt+0x25d>
f0103277:	85 f6                	test   %esi,%esi
f0103279:	78 d8                	js     f0103253 <vprintfmt+0x1e0>
f010327b:	83 ee 01             	sub    $0x1,%esi
f010327e:	79 d3                	jns    f0103253 <vprintfmt+0x1e0>
f0103280:	89 df                	mov    %ebx,%edi
f0103282:	8b 75 08             	mov    0x8(%ebp),%esi
f0103285:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103288:	eb 37                	jmp    f01032c1 <vprintfmt+0x24e>
				if (altflag && (ch < ' ' || ch > '~'))
f010328a:	0f be d2             	movsbl %dl,%edx
f010328d:	83 ea 20             	sub    $0x20,%edx
f0103290:	83 fa 5e             	cmp    $0x5e,%edx
f0103293:	76 c4                	jbe    f0103259 <vprintfmt+0x1e6>
					putch('?', putdat);
f0103295:	83 ec 08             	sub    $0x8,%esp
f0103298:	ff 75 0c             	pushl  0xc(%ebp)
f010329b:	6a 3f                	push   $0x3f
f010329d:	ff 55 08             	call   *0x8(%ebp)
f01032a0:	83 c4 10             	add    $0x10,%esp
f01032a3:	eb c1                	jmp    f0103266 <vprintfmt+0x1f3>
f01032a5:	89 75 08             	mov    %esi,0x8(%ebp)
f01032a8:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01032ab:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01032ae:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f01032b1:	eb b6                	jmp    f0103269 <vprintfmt+0x1f6>
				putch(' ', putdat);
f01032b3:	83 ec 08             	sub    $0x8,%esp
f01032b6:	53                   	push   %ebx
f01032b7:	6a 20                	push   $0x20
f01032b9:	ff d6                	call   *%esi
			for (; width > 0; width--)
f01032bb:	83 ef 01             	sub    $0x1,%edi
f01032be:	83 c4 10             	add    $0x10,%esp
f01032c1:	85 ff                	test   %edi,%edi
f01032c3:	7f ee                	jg     f01032b3 <vprintfmt+0x240>
			if ((p = va_arg(ap, char *)) == NULL)
f01032c5:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01032c8:	89 45 14             	mov    %eax,0x14(%ebp)
f01032cb:	e9 78 01 00 00       	jmp    f0103448 <vprintfmt+0x3d5>
f01032d0:	89 df                	mov    %ebx,%edi
f01032d2:	8b 75 08             	mov    0x8(%ebp),%esi
f01032d5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01032d8:	eb e7                	jmp    f01032c1 <vprintfmt+0x24e>
	if (lflag >= 2)
f01032da:	83 f9 01             	cmp    $0x1,%ecx
f01032dd:	7e 3f                	jle    f010331e <vprintfmt+0x2ab>
		return va_arg(*ap, long long);
f01032df:	8b 45 14             	mov    0x14(%ebp),%eax
f01032e2:	8b 50 04             	mov    0x4(%eax),%edx
f01032e5:	8b 00                	mov    (%eax),%eax
f01032e7:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01032ea:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01032ed:	8b 45 14             	mov    0x14(%ebp),%eax
f01032f0:	8d 40 08             	lea    0x8(%eax),%eax
f01032f3:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f01032f6:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01032fa:	79 5c                	jns    f0103358 <vprintfmt+0x2e5>
				putch('-', putdat);
f01032fc:	83 ec 08             	sub    $0x8,%esp
f01032ff:	53                   	push   %ebx
f0103300:	6a 2d                	push   $0x2d
f0103302:	ff d6                	call   *%esi
				num = -(long long) num;
f0103304:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103307:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010330a:	f7 da                	neg    %edx
f010330c:	83 d1 00             	adc    $0x0,%ecx
f010330f:	f7 d9                	neg    %ecx
f0103311:	83 c4 10             	add    $0x10,%esp
			base = 10;
f0103314:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103319:	e9 10 01 00 00       	jmp    f010342e <vprintfmt+0x3bb>
	else if (lflag)
f010331e:	85 c9                	test   %ecx,%ecx
f0103320:	75 1b                	jne    f010333d <vprintfmt+0x2ca>
		return va_arg(*ap, int);
f0103322:	8b 45 14             	mov    0x14(%ebp),%eax
f0103325:	8b 00                	mov    (%eax),%eax
f0103327:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010332a:	89 c1                	mov    %eax,%ecx
f010332c:	c1 f9 1f             	sar    $0x1f,%ecx
f010332f:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0103332:	8b 45 14             	mov    0x14(%ebp),%eax
f0103335:	8d 40 04             	lea    0x4(%eax),%eax
f0103338:	89 45 14             	mov    %eax,0x14(%ebp)
f010333b:	eb b9                	jmp    f01032f6 <vprintfmt+0x283>
		return va_arg(*ap, long);
f010333d:	8b 45 14             	mov    0x14(%ebp),%eax
f0103340:	8b 00                	mov    (%eax),%eax
f0103342:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103345:	89 c1                	mov    %eax,%ecx
f0103347:	c1 f9 1f             	sar    $0x1f,%ecx
f010334a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f010334d:	8b 45 14             	mov    0x14(%ebp),%eax
f0103350:	8d 40 04             	lea    0x4(%eax),%eax
f0103353:	89 45 14             	mov    %eax,0x14(%ebp)
f0103356:	eb 9e                	jmp    f01032f6 <vprintfmt+0x283>
			num = getint(&ap, lflag);
f0103358:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010335b:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f010335e:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103363:	e9 c6 00 00 00       	jmp    f010342e <vprintfmt+0x3bb>
	if (lflag >= 2)
f0103368:	83 f9 01             	cmp    $0x1,%ecx
f010336b:	7e 18                	jle    f0103385 <vprintfmt+0x312>
		return va_arg(*ap, unsigned long long);
f010336d:	8b 45 14             	mov    0x14(%ebp),%eax
f0103370:	8b 10                	mov    (%eax),%edx
f0103372:	8b 48 04             	mov    0x4(%eax),%ecx
f0103375:	8d 40 08             	lea    0x8(%eax),%eax
f0103378:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f010337b:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103380:	e9 a9 00 00 00       	jmp    f010342e <vprintfmt+0x3bb>
	else if (lflag)
f0103385:	85 c9                	test   %ecx,%ecx
f0103387:	75 1a                	jne    f01033a3 <vprintfmt+0x330>
		return va_arg(*ap, unsigned int);
f0103389:	8b 45 14             	mov    0x14(%ebp),%eax
f010338c:	8b 10                	mov    (%eax),%edx
f010338e:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103393:	8d 40 04             	lea    0x4(%eax),%eax
f0103396:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0103399:	b8 0a 00 00 00       	mov    $0xa,%eax
f010339e:	e9 8b 00 00 00       	jmp    f010342e <vprintfmt+0x3bb>
		return va_arg(*ap, unsigned long);
f01033a3:	8b 45 14             	mov    0x14(%ebp),%eax
f01033a6:	8b 10                	mov    (%eax),%edx
f01033a8:	b9 00 00 00 00       	mov    $0x0,%ecx
f01033ad:	8d 40 04             	lea    0x4(%eax),%eax
f01033b0:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01033b3:	b8 0a 00 00 00       	mov    $0xa,%eax
f01033b8:	eb 74                	jmp    f010342e <vprintfmt+0x3bb>
	if (lflag >= 2)
f01033ba:	83 f9 01             	cmp    $0x1,%ecx
f01033bd:	7e 15                	jle    f01033d4 <vprintfmt+0x361>
		return va_arg(*ap, unsigned long long);
f01033bf:	8b 45 14             	mov    0x14(%ebp),%eax
f01033c2:	8b 10                	mov    (%eax),%edx
f01033c4:	8b 48 04             	mov    0x4(%eax),%ecx
f01033c7:	8d 40 08             	lea    0x8(%eax),%eax
f01033ca:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f01033cd:	b8 08 00 00 00       	mov    $0x8,%eax
f01033d2:	eb 5a                	jmp    f010342e <vprintfmt+0x3bb>
	else if (lflag)
f01033d4:	85 c9                	test   %ecx,%ecx
f01033d6:	75 17                	jne    f01033ef <vprintfmt+0x37c>
		return va_arg(*ap, unsigned int);
f01033d8:	8b 45 14             	mov    0x14(%ebp),%eax
f01033db:	8b 10                	mov    (%eax),%edx
f01033dd:	b9 00 00 00 00       	mov    $0x0,%ecx
f01033e2:	8d 40 04             	lea    0x4(%eax),%eax
f01033e5:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f01033e8:	b8 08 00 00 00       	mov    $0x8,%eax
f01033ed:	eb 3f                	jmp    f010342e <vprintfmt+0x3bb>
		return va_arg(*ap, unsigned long);
f01033ef:	8b 45 14             	mov    0x14(%ebp),%eax
f01033f2:	8b 10                	mov    (%eax),%edx
f01033f4:	b9 00 00 00 00       	mov    $0x0,%ecx
f01033f9:	8d 40 04             	lea    0x4(%eax),%eax
f01033fc:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f01033ff:	b8 08 00 00 00       	mov    $0x8,%eax
f0103404:	eb 28                	jmp    f010342e <vprintfmt+0x3bb>
			putch('0', putdat);
f0103406:	83 ec 08             	sub    $0x8,%esp
f0103409:	53                   	push   %ebx
f010340a:	6a 30                	push   $0x30
f010340c:	ff d6                	call   *%esi
			putch('x', putdat);
f010340e:	83 c4 08             	add    $0x8,%esp
f0103411:	53                   	push   %ebx
f0103412:	6a 78                	push   $0x78
f0103414:	ff d6                	call   *%esi
			num = (unsigned long long)
f0103416:	8b 45 14             	mov    0x14(%ebp),%eax
f0103419:	8b 10                	mov    (%eax),%edx
f010341b:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f0103420:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f0103423:	8d 40 04             	lea    0x4(%eax),%eax
f0103426:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0103429:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f010342e:	83 ec 0c             	sub    $0xc,%esp
f0103431:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0103435:	57                   	push   %edi
f0103436:	ff 75 e0             	pushl  -0x20(%ebp)
f0103439:	50                   	push   %eax
f010343a:	51                   	push   %ecx
f010343b:	52                   	push   %edx
f010343c:	89 da                	mov    %ebx,%edx
f010343e:	89 f0                	mov    %esi,%eax
f0103440:	e8 45 fb ff ff       	call   f0102f8a <printnum>
			break;
f0103445:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f0103448:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f010344b:	83 c7 01             	add    $0x1,%edi
f010344e:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103452:	83 f8 25             	cmp    $0x25,%eax
f0103455:	0f 84 2f fc ff ff    	je     f010308a <vprintfmt+0x17>
			if (ch == '\0')
f010345b:	85 c0                	test   %eax,%eax
f010345d:	0f 84 8b 00 00 00    	je     f01034ee <vprintfmt+0x47b>
			putch(ch, putdat);
f0103463:	83 ec 08             	sub    $0x8,%esp
f0103466:	53                   	push   %ebx
f0103467:	50                   	push   %eax
f0103468:	ff d6                	call   *%esi
f010346a:	83 c4 10             	add    $0x10,%esp
f010346d:	eb dc                	jmp    f010344b <vprintfmt+0x3d8>
	if (lflag >= 2)
f010346f:	83 f9 01             	cmp    $0x1,%ecx
f0103472:	7e 15                	jle    f0103489 <vprintfmt+0x416>
		return va_arg(*ap, unsigned long long);
f0103474:	8b 45 14             	mov    0x14(%ebp),%eax
f0103477:	8b 10                	mov    (%eax),%edx
f0103479:	8b 48 04             	mov    0x4(%eax),%ecx
f010347c:	8d 40 08             	lea    0x8(%eax),%eax
f010347f:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0103482:	b8 10 00 00 00       	mov    $0x10,%eax
f0103487:	eb a5                	jmp    f010342e <vprintfmt+0x3bb>
	else if (lflag)
f0103489:	85 c9                	test   %ecx,%ecx
f010348b:	75 17                	jne    f01034a4 <vprintfmt+0x431>
		return va_arg(*ap, unsigned int);
f010348d:	8b 45 14             	mov    0x14(%ebp),%eax
f0103490:	8b 10                	mov    (%eax),%edx
f0103492:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103497:	8d 40 04             	lea    0x4(%eax),%eax
f010349a:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010349d:	b8 10 00 00 00       	mov    $0x10,%eax
f01034a2:	eb 8a                	jmp    f010342e <vprintfmt+0x3bb>
		return va_arg(*ap, unsigned long);
f01034a4:	8b 45 14             	mov    0x14(%ebp),%eax
f01034a7:	8b 10                	mov    (%eax),%edx
f01034a9:	b9 00 00 00 00       	mov    $0x0,%ecx
f01034ae:	8d 40 04             	lea    0x4(%eax),%eax
f01034b1:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01034b4:	b8 10 00 00 00       	mov    $0x10,%eax
f01034b9:	e9 70 ff ff ff       	jmp    f010342e <vprintfmt+0x3bb>
			putch(ch, putdat);
f01034be:	83 ec 08             	sub    $0x8,%esp
f01034c1:	53                   	push   %ebx
f01034c2:	6a 25                	push   $0x25
f01034c4:	ff d6                	call   *%esi
			break;
f01034c6:	83 c4 10             	add    $0x10,%esp
f01034c9:	e9 7a ff ff ff       	jmp    f0103448 <vprintfmt+0x3d5>
			putch('%', putdat);
f01034ce:	83 ec 08             	sub    $0x8,%esp
f01034d1:	53                   	push   %ebx
f01034d2:	6a 25                	push   $0x25
f01034d4:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01034d6:	83 c4 10             	add    $0x10,%esp
f01034d9:	89 f8                	mov    %edi,%eax
f01034db:	eb 03                	jmp    f01034e0 <vprintfmt+0x46d>
f01034dd:	83 e8 01             	sub    $0x1,%eax
f01034e0:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f01034e4:	75 f7                	jne    f01034dd <vprintfmt+0x46a>
f01034e6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01034e9:	e9 5a ff ff ff       	jmp    f0103448 <vprintfmt+0x3d5>
}
f01034ee:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01034f1:	5b                   	pop    %ebx
f01034f2:	5e                   	pop    %esi
f01034f3:	5f                   	pop    %edi
f01034f4:	5d                   	pop    %ebp
f01034f5:	c3                   	ret    

f01034f6 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01034f6:	55                   	push   %ebp
f01034f7:	89 e5                	mov    %esp,%ebp
f01034f9:	83 ec 18             	sub    $0x18,%esp
f01034fc:	8b 45 08             	mov    0x8(%ebp),%eax
f01034ff:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0103502:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103505:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103509:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010350c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0103513:	85 c0                	test   %eax,%eax
f0103515:	74 26                	je     f010353d <vsnprintf+0x47>
f0103517:	85 d2                	test   %edx,%edx
f0103519:	7e 22                	jle    f010353d <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010351b:	ff 75 14             	pushl  0x14(%ebp)
f010351e:	ff 75 10             	pushl  0x10(%ebp)
f0103521:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103524:	50                   	push   %eax
f0103525:	68 39 30 10 f0       	push   $0xf0103039
f010352a:	e8 44 fb ff ff       	call   f0103073 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010352f:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103532:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0103535:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103538:	83 c4 10             	add    $0x10,%esp
}
f010353b:	c9                   	leave  
f010353c:	c3                   	ret    
		return -E_INVAL;
f010353d:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0103542:	eb f7                	jmp    f010353b <vsnprintf+0x45>

f0103544 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0103544:	55                   	push   %ebp
f0103545:	89 e5                	mov    %esp,%ebp
f0103547:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010354a:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f010354d:	50                   	push   %eax
f010354e:	ff 75 10             	pushl  0x10(%ebp)
f0103551:	ff 75 0c             	pushl  0xc(%ebp)
f0103554:	ff 75 08             	pushl  0x8(%ebp)
f0103557:	e8 9a ff ff ff       	call   f01034f6 <vsnprintf>
	va_end(ap);

	return rc;
}
f010355c:	c9                   	leave  
f010355d:	c3                   	ret    

f010355e <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f010355e:	55                   	push   %ebp
f010355f:	89 e5                	mov    %esp,%ebp
f0103561:	57                   	push   %edi
f0103562:	56                   	push   %esi
f0103563:	53                   	push   %ebx
f0103564:	83 ec 0c             	sub    $0xc,%esp
f0103567:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010356a:	85 c0                	test   %eax,%eax
f010356c:	74 11                	je     f010357f <readline+0x21>
		cprintf("%s", prompt);
f010356e:	83 ec 08             	sub    $0x8,%esp
f0103571:	50                   	push   %eax
f0103572:	68 a4 3f 10 f0       	push   $0xf0103fa4
f0103577:	e8 0d d2 ff ff       	call   f0100789 <cprintf>
f010357c:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f010357f:	83 ec 0c             	sub    $0xc,%esp
f0103582:	6a 00                	push   $0x0
f0103584:	e8 bd d1 ff ff       	call   f0100746 <iscons>
f0103589:	89 c7                	mov    %eax,%edi
f010358b:	83 c4 10             	add    $0x10,%esp
	i = 0;
f010358e:	be 00 00 00 00       	mov    $0x0,%esi
f0103593:	eb 3f                	jmp    f01035d4 <readline+0x76>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f0103595:	83 ec 08             	sub    $0x8,%esp
f0103598:	50                   	push   %eax
f0103599:	68 dc 45 10 f0       	push   $0xf01045dc
f010359e:	e8 e6 d1 ff ff       	call   f0100789 <cprintf>
			return NULL;
f01035a3:	83 c4 10             	add    $0x10,%esp
f01035a6:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f01035ab:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01035ae:	5b                   	pop    %ebx
f01035af:	5e                   	pop    %esi
f01035b0:	5f                   	pop    %edi
f01035b1:	5d                   	pop    %ebp
f01035b2:	c3                   	ret    
			if (echoing)
f01035b3:	85 ff                	test   %edi,%edi
f01035b5:	75 05                	jne    f01035bc <readline+0x5e>
			i--;
f01035b7:	83 ee 01             	sub    $0x1,%esi
f01035ba:	eb 18                	jmp    f01035d4 <readline+0x76>
				cputchar('\b');
f01035bc:	83 ec 0c             	sub    $0xc,%esp
f01035bf:	6a 08                	push   $0x8
f01035c1:	e8 5f d1 ff ff       	call   f0100725 <cputchar>
f01035c6:	83 c4 10             	add    $0x10,%esp
f01035c9:	eb ec                	jmp    f01035b7 <readline+0x59>
			buf[i++] = c;
f01035cb:	88 9e 40 32 12 f0    	mov    %bl,-0xfedcdc0(%esi)
f01035d1:	8d 76 01             	lea    0x1(%esi),%esi
		c = getchar();
f01035d4:	e8 5c d1 ff ff       	call   f0100735 <getchar>
f01035d9:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01035db:	85 c0                	test   %eax,%eax
f01035dd:	78 b6                	js     f0103595 <readline+0x37>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01035df:	83 f8 08             	cmp    $0x8,%eax
f01035e2:	0f 94 c2             	sete   %dl
f01035e5:	83 f8 7f             	cmp    $0x7f,%eax
f01035e8:	0f 94 c0             	sete   %al
f01035eb:	08 c2                	or     %al,%dl
f01035ed:	74 04                	je     f01035f3 <readline+0x95>
f01035ef:	85 f6                	test   %esi,%esi
f01035f1:	7f c0                	jg     f01035b3 <readline+0x55>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01035f3:	83 fb 1f             	cmp    $0x1f,%ebx
f01035f6:	7e 1a                	jle    f0103612 <readline+0xb4>
f01035f8:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01035fe:	7f 12                	jg     f0103612 <readline+0xb4>
			if (echoing)
f0103600:	85 ff                	test   %edi,%edi
f0103602:	74 c7                	je     f01035cb <readline+0x6d>
				cputchar(c);
f0103604:	83 ec 0c             	sub    $0xc,%esp
f0103607:	53                   	push   %ebx
f0103608:	e8 18 d1 ff ff       	call   f0100725 <cputchar>
f010360d:	83 c4 10             	add    $0x10,%esp
f0103610:	eb b9                	jmp    f01035cb <readline+0x6d>
		} else if (c == '\n' || c == '\r') {
f0103612:	83 fb 0a             	cmp    $0xa,%ebx
f0103615:	74 05                	je     f010361c <readline+0xbe>
f0103617:	83 fb 0d             	cmp    $0xd,%ebx
f010361a:	75 b8                	jne    f01035d4 <readline+0x76>
			if (echoing)
f010361c:	85 ff                	test   %edi,%edi
f010361e:	75 11                	jne    f0103631 <readline+0xd3>
			buf[i] = 0;
f0103620:	c6 86 40 32 12 f0 00 	movb   $0x0,-0xfedcdc0(%esi)
			return buf;
f0103627:	b8 40 32 12 f0       	mov    $0xf0123240,%eax
f010362c:	e9 7a ff ff ff       	jmp    f01035ab <readline+0x4d>
				cputchar('\n');
f0103631:	83 ec 0c             	sub    $0xc,%esp
f0103634:	6a 0a                	push   $0xa
f0103636:	e8 ea d0 ff ff       	call   f0100725 <cputchar>
f010363b:	83 c4 10             	add    $0x10,%esp
f010363e:	eb e0                	jmp    f0103620 <readline+0xc2>

f0103640 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103640:	55                   	push   %ebp
f0103641:	89 e5                	mov    %esp,%ebp
f0103643:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103646:	b8 00 00 00 00       	mov    $0x0,%eax
f010364b:	eb 03                	jmp    f0103650 <strlen+0x10>
		n++;
f010364d:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f0103650:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103654:	75 f7                	jne    f010364d <strlen+0xd>
	return n;
}
f0103656:	5d                   	pop    %ebp
f0103657:	c3                   	ret    

f0103658 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103658:	55                   	push   %ebp
f0103659:	89 e5                	mov    %esp,%ebp
f010365b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010365e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103661:	b8 00 00 00 00       	mov    $0x0,%eax
f0103666:	eb 03                	jmp    f010366b <strnlen+0x13>
		n++;
f0103668:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010366b:	39 d0                	cmp    %edx,%eax
f010366d:	74 06                	je     f0103675 <strnlen+0x1d>
f010366f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0103673:	75 f3                	jne    f0103668 <strnlen+0x10>
	return n;
}
f0103675:	5d                   	pop    %ebp
f0103676:	c3                   	ret    

f0103677 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103677:	55                   	push   %ebp
f0103678:	89 e5                	mov    %esp,%ebp
f010367a:	53                   	push   %ebx
f010367b:	8b 45 08             	mov    0x8(%ebp),%eax
f010367e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103681:	89 c2                	mov    %eax,%edx
f0103683:	83 c1 01             	add    $0x1,%ecx
f0103686:	83 c2 01             	add    $0x1,%edx
f0103689:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010368d:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103690:	84 db                	test   %bl,%bl
f0103692:	75 ef                	jne    f0103683 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103694:	5b                   	pop    %ebx
f0103695:	5d                   	pop    %ebp
f0103696:	c3                   	ret    

f0103697 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103697:	55                   	push   %ebp
f0103698:	89 e5                	mov    %esp,%ebp
f010369a:	53                   	push   %ebx
f010369b:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f010369e:	53                   	push   %ebx
f010369f:	e8 9c ff ff ff       	call   f0103640 <strlen>
f01036a4:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f01036a7:	ff 75 0c             	pushl  0xc(%ebp)
f01036aa:	01 d8                	add    %ebx,%eax
f01036ac:	50                   	push   %eax
f01036ad:	e8 c5 ff ff ff       	call   f0103677 <strcpy>
	return dst;
}
f01036b2:	89 d8                	mov    %ebx,%eax
f01036b4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01036b7:	c9                   	leave  
f01036b8:	c3                   	ret    

f01036b9 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01036b9:	55                   	push   %ebp
f01036ba:	89 e5                	mov    %esp,%ebp
f01036bc:	56                   	push   %esi
f01036bd:	53                   	push   %ebx
f01036be:	8b 75 08             	mov    0x8(%ebp),%esi
f01036c1:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01036c4:	89 f3                	mov    %esi,%ebx
f01036c6:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01036c9:	89 f2                	mov    %esi,%edx
f01036cb:	eb 0f                	jmp    f01036dc <strncpy+0x23>
		*dst++ = *src;
f01036cd:	83 c2 01             	add    $0x1,%edx
f01036d0:	0f b6 01             	movzbl (%ecx),%eax
f01036d3:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01036d6:	80 39 01             	cmpb   $0x1,(%ecx)
f01036d9:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f01036dc:	39 da                	cmp    %ebx,%edx
f01036de:	75 ed                	jne    f01036cd <strncpy+0x14>
	}
	return ret;
}
f01036e0:	89 f0                	mov    %esi,%eax
f01036e2:	5b                   	pop    %ebx
f01036e3:	5e                   	pop    %esi
f01036e4:	5d                   	pop    %ebp
f01036e5:	c3                   	ret    

f01036e6 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01036e6:	55                   	push   %ebp
f01036e7:	89 e5                	mov    %esp,%ebp
f01036e9:	56                   	push   %esi
f01036ea:	53                   	push   %ebx
f01036eb:	8b 75 08             	mov    0x8(%ebp),%esi
f01036ee:	8b 55 0c             	mov    0xc(%ebp),%edx
f01036f1:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01036f4:	89 f0                	mov    %esi,%eax
f01036f6:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01036fa:	85 c9                	test   %ecx,%ecx
f01036fc:	75 0b                	jne    f0103709 <strlcpy+0x23>
f01036fe:	eb 17                	jmp    f0103717 <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103700:	83 c2 01             	add    $0x1,%edx
f0103703:	83 c0 01             	add    $0x1,%eax
f0103706:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f0103709:	39 d8                	cmp    %ebx,%eax
f010370b:	74 07                	je     f0103714 <strlcpy+0x2e>
f010370d:	0f b6 0a             	movzbl (%edx),%ecx
f0103710:	84 c9                	test   %cl,%cl
f0103712:	75 ec                	jne    f0103700 <strlcpy+0x1a>
		*dst = '\0';
f0103714:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0103717:	29 f0                	sub    %esi,%eax
}
f0103719:	5b                   	pop    %ebx
f010371a:	5e                   	pop    %esi
f010371b:	5d                   	pop    %ebp
f010371c:	c3                   	ret    

f010371d <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010371d:	55                   	push   %ebp
f010371e:	89 e5                	mov    %esp,%ebp
f0103720:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103723:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103726:	eb 06                	jmp    f010372e <strcmp+0x11>
		p++, q++;
f0103728:	83 c1 01             	add    $0x1,%ecx
f010372b:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f010372e:	0f b6 01             	movzbl (%ecx),%eax
f0103731:	84 c0                	test   %al,%al
f0103733:	74 04                	je     f0103739 <strcmp+0x1c>
f0103735:	3a 02                	cmp    (%edx),%al
f0103737:	74 ef                	je     f0103728 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103739:	0f b6 c0             	movzbl %al,%eax
f010373c:	0f b6 12             	movzbl (%edx),%edx
f010373f:	29 d0                	sub    %edx,%eax
}
f0103741:	5d                   	pop    %ebp
f0103742:	c3                   	ret    

f0103743 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103743:	55                   	push   %ebp
f0103744:	89 e5                	mov    %esp,%ebp
f0103746:	53                   	push   %ebx
f0103747:	8b 45 08             	mov    0x8(%ebp),%eax
f010374a:	8b 55 0c             	mov    0xc(%ebp),%edx
f010374d:	89 c3                	mov    %eax,%ebx
f010374f:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103752:	eb 06                	jmp    f010375a <strncmp+0x17>
		n--, p++, q++;
f0103754:	83 c0 01             	add    $0x1,%eax
f0103757:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f010375a:	39 d8                	cmp    %ebx,%eax
f010375c:	74 16                	je     f0103774 <strncmp+0x31>
f010375e:	0f b6 08             	movzbl (%eax),%ecx
f0103761:	84 c9                	test   %cl,%cl
f0103763:	74 04                	je     f0103769 <strncmp+0x26>
f0103765:	3a 0a                	cmp    (%edx),%cl
f0103767:	74 eb                	je     f0103754 <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103769:	0f b6 00             	movzbl (%eax),%eax
f010376c:	0f b6 12             	movzbl (%edx),%edx
f010376f:	29 d0                	sub    %edx,%eax
}
f0103771:	5b                   	pop    %ebx
f0103772:	5d                   	pop    %ebp
f0103773:	c3                   	ret    
		return 0;
f0103774:	b8 00 00 00 00       	mov    $0x0,%eax
f0103779:	eb f6                	jmp    f0103771 <strncmp+0x2e>

f010377b <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010377b:	55                   	push   %ebp
f010377c:	89 e5                	mov    %esp,%ebp
f010377e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103781:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103785:	0f b6 10             	movzbl (%eax),%edx
f0103788:	84 d2                	test   %dl,%dl
f010378a:	74 09                	je     f0103795 <strchr+0x1a>
		if (*s == c)
f010378c:	38 ca                	cmp    %cl,%dl
f010378e:	74 0a                	je     f010379a <strchr+0x1f>
	for (; *s; s++)
f0103790:	83 c0 01             	add    $0x1,%eax
f0103793:	eb f0                	jmp    f0103785 <strchr+0xa>
			return (char *) s;
	return 0;
f0103795:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010379a:	5d                   	pop    %ebp
f010379b:	c3                   	ret    

f010379c <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010379c:	55                   	push   %ebp
f010379d:	89 e5                	mov    %esp,%ebp
f010379f:	8b 45 08             	mov    0x8(%ebp),%eax
f01037a2:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01037a6:	eb 03                	jmp    f01037ab <strfind+0xf>
f01037a8:	83 c0 01             	add    $0x1,%eax
f01037ab:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01037ae:	38 ca                	cmp    %cl,%dl
f01037b0:	74 04                	je     f01037b6 <strfind+0x1a>
f01037b2:	84 d2                	test   %dl,%dl
f01037b4:	75 f2                	jne    f01037a8 <strfind+0xc>
			break;
	return (char *) s;
}
f01037b6:	5d                   	pop    %ebp
f01037b7:	c3                   	ret    

f01037b8 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01037b8:	55                   	push   %ebp
f01037b9:	89 e5                	mov    %esp,%ebp
f01037bb:	57                   	push   %edi
f01037bc:	56                   	push   %esi
f01037bd:	53                   	push   %ebx
f01037be:	8b 7d 08             	mov    0x8(%ebp),%edi
f01037c1:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01037c4:	85 c9                	test   %ecx,%ecx
f01037c6:	74 13                	je     f01037db <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01037c8:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01037ce:	75 05                	jne    f01037d5 <memset+0x1d>
f01037d0:	f6 c1 03             	test   $0x3,%cl
f01037d3:	74 0d                	je     f01037e2 <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01037d5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01037d8:	fc                   	cld    
f01037d9:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01037db:	89 f8                	mov    %edi,%eax
f01037dd:	5b                   	pop    %ebx
f01037de:	5e                   	pop    %esi
f01037df:	5f                   	pop    %edi
f01037e0:	5d                   	pop    %ebp
f01037e1:	c3                   	ret    
		c &= 0xFF;
f01037e2:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01037e6:	89 d3                	mov    %edx,%ebx
f01037e8:	c1 e3 08             	shl    $0x8,%ebx
f01037eb:	89 d0                	mov    %edx,%eax
f01037ed:	c1 e0 18             	shl    $0x18,%eax
f01037f0:	89 d6                	mov    %edx,%esi
f01037f2:	c1 e6 10             	shl    $0x10,%esi
f01037f5:	09 f0                	or     %esi,%eax
f01037f7:	09 c2                	or     %eax,%edx
f01037f9:	09 da                	or     %ebx,%edx
			:: "D" (v), "a" (c), "c" (n/4)
f01037fb:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f01037fe:	89 d0                	mov    %edx,%eax
f0103800:	fc                   	cld    
f0103801:	f3 ab                	rep stos %eax,%es:(%edi)
f0103803:	eb d6                	jmp    f01037db <memset+0x23>

f0103805 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103805:	55                   	push   %ebp
f0103806:	89 e5                	mov    %esp,%ebp
f0103808:	57                   	push   %edi
f0103809:	56                   	push   %esi
f010380a:	8b 45 08             	mov    0x8(%ebp),%eax
f010380d:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103810:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103813:	39 c6                	cmp    %eax,%esi
f0103815:	73 35                	jae    f010384c <memmove+0x47>
f0103817:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010381a:	39 c2                	cmp    %eax,%edx
f010381c:	76 2e                	jbe    f010384c <memmove+0x47>
		s += n;
		d += n;
f010381e:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103821:	89 d6                	mov    %edx,%esi
f0103823:	09 fe                	or     %edi,%esi
f0103825:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010382b:	74 0c                	je     f0103839 <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f010382d:	83 ef 01             	sub    $0x1,%edi
f0103830:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f0103833:	fd                   	std    
f0103834:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103836:	fc                   	cld    
f0103837:	eb 21                	jmp    f010385a <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103839:	f6 c1 03             	test   $0x3,%cl
f010383c:	75 ef                	jne    f010382d <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f010383e:	83 ef 04             	sub    $0x4,%edi
f0103841:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103844:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f0103847:	fd                   	std    
f0103848:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010384a:	eb ea                	jmp    f0103836 <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010384c:	89 f2                	mov    %esi,%edx
f010384e:	09 c2                	or     %eax,%edx
f0103850:	f6 c2 03             	test   $0x3,%dl
f0103853:	74 09                	je     f010385e <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103855:	89 c7                	mov    %eax,%edi
f0103857:	fc                   	cld    
f0103858:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f010385a:	5e                   	pop    %esi
f010385b:	5f                   	pop    %edi
f010385c:	5d                   	pop    %ebp
f010385d:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010385e:	f6 c1 03             	test   $0x3,%cl
f0103861:	75 f2                	jne    f0103855 <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0103863:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f0103866:	89 c7                	mov    %eax,%edi
f0103868:	fc                   	cld    
f0103869:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010386b:	eb ed                	jmp    f010385a <memmove+0x55>

f010386d <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010386d:	55                   	push   %ebp
f010386e:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0103870:	ff 75 10             	pushl  0x10(%ebp)
f0103873:	ff 75 0c             	pushl  0xc(%ebp)
f0103876:	ff 75 08             	pushl  0x8(%ebp)
f0103879:	e8 87 ff ff ff       	call   f0103805 <memmove>
}
f010387e:	c9                   	leave  
f010387f:	c3                   	ret    

f0103880 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103880:	55                   	push   %ebp
f0103881:	89 e5                	mov    %esp,%ebp
f0103883:	56                   	push   %esi
f0103884:	53                   	push   %ebx
f0103885:	8b 45 08             	mov    0x8(%ebp),%eax
f0103888:	8b 55 0c             	mov    0xc(%ebp),%edx
f010388b:	89 c6                	mov    %eax,%esi
f010388d:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103890:	39 f0                	cmp    %esi,%eax
f0103892:	74 1c                	je     f01038b0 <memcmp+0x30>
		if (*s1 != *s2)
f0103894:	0f b6 08             	movzbl (%eax),%ecx
f0103897:	0f b6 1a             	movzbl (%edx),%ebx
f010389a:	38 d9                	cmp    %bl,%cl
f010389c:	75 08                	jne    f01038a6 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f010389e:	83 c0 01             	add    $0x1,%eax
f01038a1:	83 c2 01             	add    $0x1,%edx
f01038a4:	eb ea                	jmp    f0103890 <memcmp+0x10>
			return (int) *s1 - (int) *s2;
f01038a6:	0f b6 c1             	movzbl %cl,%eax
f01038a9:	0f b6 db             	movzbl %bl,%ebx
f01038ac:	29 d8                	sub    %ebx,%eax
f01038ae:	eb 05                	jmp    f01038b5 <memcmp+0x35>
	}

	return 0;
f01038b0:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01038b5:	5b                   	pop    %ebx
f01038b6:	5e                   	pop    %esi
f01038b7:	5d                   	pop    %ebp
f01038b8:	c3                   	ret    

f01038b9 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01038b9:	55                   	push   %ebp
f01038ba:	89 e5                	mov    %esp,%ebp
f01038bc:	8b 45 08             	mov    0x8(%ebp),%eax
f01038bf:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f01038c2:	89 c2                	mov    %eax,%edx
f01038c4:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01038c7:	39 d0                	cmp    %edx,%eax
f01038c9:	73 09                	jae    f01038d4 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f01038cb:	38 08                	cmp    %cl,(%eax)
f01038cd:	74 05                	je     f01038d4 <memfind+0x1b>
	for (; s < ends; s++)
f01038cf:	83 c0 01             	add    $0x1,%eax
f01038d2:	eb f3                	jmp    f01038c7 <memfind+0xe>
			break;
	return (void *) s;
}
f01038d4:	5d                   	pop    %ebp
f01038d5:	c3                   	ret    

f01038d6 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01038d6:	55                   	push   %ebp
f01038d7:	89 e5                	mov    %esp,%ebp
f01038d9:	57                   	push   %edi
f01038da:	56                   	push   %esi
f01038db:	53                   	push   %ebx
f01038dc:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01038df:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01038e2:	eb 03                	jmp    f01038e7 <strtol+0x11>
		s++;
f01038e4:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f01038e7:	0f b6 01             	movzbl (%ecx),%eax
f01038ea:	3c 20                	cmp    $0x20,%al
f01038ec:	74 f6                	je     f01038e4 <strtol+0xe>
f01038ee:	3c 09                	cmp    $0x9,%al
f01038f0:	74 f2                	je     f01038e4 <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f01038f2:	3c 2b                	cmp    $0x2b,%al
f01038f4:	74 2e                	je     f0103924 <strtol+0x4e>
	int neg = 0;
f01038f6:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f01038fb:	3c 2d                	cmp    $0x2d,%al
f01038fd:	74 2f                	je     f010392e <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01038ff:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0103905:	75 05                	jne    f010390c <strtol+0x36>
f0103907:	80 39 30             	cmpb   $0x30,(%ecx)
f010390a:	74 2c                	je     f0103938 <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010390c:	85 db                	test   %ebx,%ebx
f010390e:	75 0a                	jne    f010391a <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103910:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
f0103915:	80 39 30             	cmpb   $0x30,(%ecx)
f0103918:	74 28                	je     f0103942 <strtol+0x6c>
		base = 10;
f010391a:	b8 00 00 00 00       	mov    $0x0,%eax
f010391f:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0103922:	eb 50                	jmp    f0103974 <strtol+0x9e>
		s++;
f0103924:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f0103927:	bf 00 00 00 00       	mov    $0x0,%edi
f010392c:	eb d1                	jmp    f01038ff <strtol+0x29>
		s++, neg = 1;
f010392e:	83 c1 01             	add    $0x1,%ecx
f0103931:	bf 01 00 00 00       	mov    $0x1,%edi
f0103936:	eb c7                	jmp    f01038ff <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103938:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f010393c:	74 0e                	je     f010394c <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f010393e:	85 db                	test   %ebx,%ebx
f0103940:	75 d8                	jne    f010391a <strtol+0x44>
		s++, base = 8;
f0103942:	83 c1 01             	add    $0x1,%ecx
f0103945:	bb 08 00 00 00       	mov    $0x8,%ebx
f010394a:	eb ce                	jmp    f010391a <strtol+0x44>
		s += 2, base = 16;
f010394c:	83 c1 02             	add    $0x2,%ecx
f010394f:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103954:	eb c4                	jmp    f010391a <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f0103956:	8d 72 9f             	lea    -0x61(%edx),%esi
f0103959:	89 f3                	mov    %esi,%ebx
f010395b:	80 fb 19             	cmp    $0x19,%bl
f010395e:	77 29                	ja     f0103989 <strtol+0xb3>
			dig = *s - 'a' + 10;
f0103960:	0f be d2             	movsbl %dl,%edx
f0103963:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0103966:	3b 55 10             	cmp    0x10(%ebp),%edx
f0103969:	7d 30                	jge    f010399b <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f010396b:	83 c1 01             	add    $0x1,%ecx
f010396e:	0f af 45 10          	imul   0x10(%ebp),%eax
f0103972:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f0103974:	0f b6 11             	movzbl (%ecx),%edx
f0103977:	8d 72 d0             	lea    -0x30(%edx),%esi
f010397a:	89 f3                	mov    %esi,%ebx
f010397c:	80 fb 09             	cmp    $0x9,%bl
f010397f:	77 d5                	ja     f0103956 <strtol+0x80>
			dig = *s - '0';
f0103981:	0f be d2             	movsbl %dl,%edx
f0103984:	83 ea 30             	sub    $0x30,%edx
f0103987:	eb dd                	jmp    f0103966 <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
f0103989:	8d 72 bf             	lea    -0x41(%edx),%esi
f010398c:	89 f3                	mov    %esi,%ebx
f010398e:	80 fb 19             	cmp    $0x19,%bl
f0103991:	77 08                	ja     f010399b <strtol+0xc5>
			dig = *s - 'A' + 10;
f0103993:	0f be d2             	movsbl %dl,%edx
f0103996:	83 ea 37             	sub    $0x37,%edx
f0103999:	eb cb                	jmp    f0103966 <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
f010399b:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010399f:	74 05                	je     f01039a6 <strtol+0xd0>
		*endptr = (char *) s;
f01039a1:	8b 75 0c             	mov    0xc(%ebp),%esi
f01039a4:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f01039a6:	89 c2                	mov    %eax,%edx
f01039a8:	f7 da                	neg    %edx
f01039aa:	85 ff                	test   %edi,%edi
f01039ac:	0f 45 c2             	cmovne %edx,%eax
}
f01039af:	5b                   	pop    %ebx
f01039b0:	5e                   	pop    %esi
f01039b1:	5f                   	pop    %edi
f01039b2:	5d                   	pop    %ebp
f01039b3:	c3                   	ret    
f01039b4:	66 90                	xchg   %ax,%ax
f01039b6:	66 90                	xchg   %ax,%ax
f01039b8:	66 90                	xchg   %ax,%ax
f01039ba:	66 90                	xchg   %ax,%ax
f01039bc:	66 90                	xchg   %ax,%ax
f01039be:	66 90                	xchg   %ax,%ax

f01039c0 <__udivdi3>:
f01039c0:	55                   	push   %ebp
f01039c1:	57                   	push   %edi
f01039c2:	56                   	push   %esi
f01039c3:	53                   	push   %ebx
f01039c4:	83 ec 1c             	sub    $0x1c,%esp
f01039c7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01039cb:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f01039cf:	8b 74 24 34          	mov    0x34(%esp),%esi
f01039d3:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f01039d7:	85 d2                	test   %edx,%edx
f01039d9:	75 35                	jne    f0103a10 <__udivdi3+0x50>
f01039db:	39 f3                	cmp    %esi,%ebx
f01039dd:	0f 87 bd 00 00 00    	ja     f0103aa0 <__udivdi3+0xe0>
f01039e3:	85 db                	test   %ebx,%ebx
f01039e5:	89 d9                	mov    %ebx,%ecx
f01039e7:	75 0b                	jne    f01039f4 <__udivdi3+0x34>
f01039e9:	b8 01 00 00 00       	mov    $0x1,%eax
f01039ee:	31 d2                	xor    %edx,%edx
f01039f0:	f7 f3                	div    %ebx
f01039f2:	89 c1                	mov    %eax,%ecx
f01039f4:	31 d2                	xor    %edx,%edx
f01039f6:	89 f0                	mov    %esi,%eax
f01039f8:	f7 f1                	div    %ecx
f01039fa:	89 c6                	mov    %eax,%esi
f01039fc:	89 e8                	mov    %ebp,%eax
f01039fe:	89 f7                	mov    %esi,%edi
f0103a00:	f7 f1                	div    %ecx
f0103a02:	89 fa                	mov    %edi,%edx
f0103a04:	83 c4 1c             	add    $0x1c,%esp
f0103a07:	5b                   	pop    %ebx
f0103a08:	5e                   	pop    %esi
f0103a09:	5f                   	pop    %edi
f0103a0a:	5d                   	pop    %ebp
f0103a0b:	c3                   	ret    
f0103a0c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103a10:	39 f2                	cmp    %esi,%edx
f0103a12:	77 7c                	ja     f0103a90 <__udivdi3+0xd0>
f0103a14:	0f bd fa             	bsr    %edx,%edi
f0103a17:	83 f7 1f             	xor    $0x1f,%edi
f0103a1a:	0f 84 98 00 00 00    	je     f0103ab8 <__udivdi3+0xf8>
f0103a20:	89 f9                	mov    %edi,%ecx
f0103a22:	b8 20 00 00 00       	mov    $0x20,%eax
f0103a27:	29 f8                	sub    %edi,%eax
f0103a29:	d3 e2                	shl    %cl,%edx
f0103a2b:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103a2f:	89 c1                	mov    %eax,%ecx
f0103a31:	89 da                	mov    %ebx,%edx
f0103a33:	d3 ea                	shr    %cl,%edx
f0103a35:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0103a39:	09 d1                	or     %edx,%ecx
f0103a3b:	89 f2                	mov    %esi,%edx
f0103a3d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103a41:	89 f9                	mov    %edi,%ecx
f0103a43:	d3 e3                	shl    %cl,%ebx
f0103a45:	89 c1                	mov    %eax,%ecx
f0103a47:	d3 ea                	shr    %cl,%edx
f0103a49:	89 f9                	mov    %edi,%ecx
f0103a4b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0103a4f:	d3 e6                	shl    %cl,%esi
f0103a51:	89 eb                	mov    %ebp,%ebx
f0103a53:	89 c1                	mov    %eax,%ecx
f0103a55:	d3 eb                	shr    %cl,%ebx
f0103a57:	09 de                	or     %ebx,%esi
f0103a59:	89 f0                	mov    %esi,%eax
f0103a5b:	f7 74 24 08          	divl   0x8(%esp)
f0103a5f:	89 d6                	mov    %edx,%esi
f0103a61:	89 c3                	mov    %eax,%ebx
f0103a63:	f7 64 24 0c          	mull   0xc(%esp)
f0103a67:	39 d6                	cmp    %edx,%esi
f0103a69:	72 0c                	jb     f0103a77 <__udivdi3+0xb7>
f0103a6b:	89 f9                	mov    %edi,%ecx
f0103a6d:	d3 e5                	shl    %cl,%ebp
f0103a6f:	39 c5                	cmp    %eax,%ebp
f0103a71:	73 5d                	jae    f0103ad0 <__udivdi3+0x110>
f0103a73:	39 d6                	cmp    %edx,%esi
f0103a75:	75 59                	jne    f0103ad0 <__udivdi3+0x110>
f0103a77:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0103a7a:	31 ff                	xor    %edi,%edi
f0103a7c:	89 fa                	mov    %edi,%edx
f0103a7e:	83 c4 1c             	add    $0x1c,%esp
f0103a81:	5b                   	pop    %ebx
f0103a82:	5e                   	pop    %esi
f0103a83:	5f                   	pop    %edi
f0103a84:	5d                   	pop    %ebp
f0103a85:	c3                   	ret    
f0103a86:	8d 76 00             	lea    0x0(%esi),%esi
f0103a89:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0103a90:	31 ff                	xor    %edi,%edi
f0103a92:	31 c0                	xor    %eax,%eax
f0103a94:	89 fa                	mov    %edi,%edx
f0103a96:	83 c4 1c             	add    $0x1c,%esp
f0103a99:	5b                   	pop    %ebx
f0103a9a:	5e                   	pop    %esi
f0103a9b:	5f                   	pop    %edi
f0103a9c:	5d                   	pop    %ebp
f0103a9d:	c3                   	ret    
f0103a9e:	66 90                	xchg   %ax,%ax
f0103aa0:	31 ff                	xor    %edi,%edi
f0103aa2:	89 e8                	mov    %ebp,%eax
f0103aa4:	89 f2                	mov    %esi,%edx
f0103aa6:	f7 f3                	div    %ebx
f0103aa8:	89 fa                	mov    %edi,%edx
f0103aaa:	83 c4 1c             	add    $0x1c,%esp
f0103aad:	5b                   	pop    %ebx
f0103aae:	5e                   	pop    %esi
f0103aaf:	5f                   	pop    %edi
f0103ab0:	5d                   	pop    %ebp
f0103ab1:	c3                   	ret    
f0103ab2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103ab8:	39 f2                	cmp    %esi,%edx
f0103aba:	72 06                	jb     f0103ac2 <__udivdi3+0x102>
f0103abc:	31 c0                	xor    %eax,%eax
f0103abe:	39 eb                	cmp    %ebp,%ebx
f0103ac0:	77 d2                	ja     f0103a94 <__udivdi3+0xd4>
f0103ac2:	b8 01 00 00 00       	mov    $0x1,%eax
f0103ac7:	eb cb                	jmp    f0103a94 <__udivdi3+0xd4>
f0103ac9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103ad0:	89 d8                	mov    %ebx,%eax
f0103ad2:	31 ff                	xor    %edi,%edi
f0103ad4:	eb be                	jmp    f0103a94 <__udivdi3+0xd4>
f0103ad6:	66 90                	xchg   %ax,%ax
f0103ad8:	66 90                	xchg   %ax,%ax
f0103ada:	66 90                	xchg   %ax,%ax
f0103adc:	66 90                	xchg   %ax,%ax
f0103ade:	66 90                	xchg   %ax,%ax

f0103ae0 <__umoddi3>:
f0103ae0:	55                   	push   %ebp
f0103ae1:	57                   	push   %edi
f0103ae2:	56                   	push   %esi
f0103ae3:	53                   	push   %ebx
f0103ae4:	83 ec 1c             	sub    $0x1c,%esp
f0103ae7:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
f0103aeb:	8b 74 24 30          	mov    0x30(%esp),%esi
f0103aef:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0103af3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103af7:	85 ed                	test   %ebp,%ebp
f0103af9:	89 f0                	mov    %esi,%eax
f0103afb:	89 da                	mov    %ebx,%edx
f0103afd:	75 19                	jne    f0103b18 <__umoddi3+0x38>
f0103aff:	39 df                	cmp    %ebx,%edi
f0103b01:	0f 86 b1 00 00 00    	jbe    f0103bb8 <__umoddi3+0xd8>
f0103b07:	f7 f7                	div    %edi
f0103b09:	89 d0                	mov    %edx,%eax
f0103b0b:	31 d2                	xor    %edx,%edx
f0103b0d:	83 c4 1c             	add    $0x1c,%esp
f0103b10:	5b                   	pop    %ebx
f0103b11:	5e                   	pop    %esi
f0103b12:	5f                   	pop    %edi
f0103b13:	5d                   	pop    %ebp
f0103b14:	c3                   	ret    
f0103b15:	8d 76 00             	lea    0x0(%esi),%esi
f0103b18:	39 dd                	cmp    %ebx,%ebp
f0103b1a:	77 f1                	ja     f0103b0d <__umoddi3+0x2d>
f0103b1c:	0f bd cd             	bsr    %ebp,%ecx
f0103b1f:	83 f1 1f             	xor    $0x1f,%ecx
f0103b22:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0103b26:	0f 84 b4 00 00 00    	je     f0103be0 <__umoddi3+0x100>
f0103b2c:	b8 20 00 00 00       	mov    $0x20,%eax
f0103b31:	89 c2                	mov    %eax,%edx
f0103b33:	8b 44 24 04          	mov    0x4(%esp),%eax
f0103b37:	29 c2                	sub    %eax,%edx
f0103b39:	89 c1                	mov    %eax,%ecx
f0103b3b:	89 f8                	mov    %edi,%eax
f0103b3d:	d3 e5                	shl    %cl,%ebp
f0103b3f:	89 d1                	mov    %edx,%ecx
f0103b41:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103b45:	d3 e8                	shr    %cl,%eax
f0103b47:	09 c5                	or     %eax,%ebp
f0103b49:	8b 44 24 04          	mov    0x4(%esp),%eax
f0103b4d:	89 c1                	mov    %eax,%ecx
f0103b4f:	d3 e7                	shl    %cl,%edi
f0103b51:	89 d1                	mov    %edx,%ecx
f0103b53:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0103b57:	89 df                	mov    %ebx,%edi
f0103b59:	d3 ef                	shr    %cl,%edi
f0103b5b:	89 c1                	mov    %eax,%ecx
f0103b5d:	89 f0                	mov    %esi,%eax
f0103b5f:	d3 e3                	shl    %cl,%ebx
f0103b61:	89 d1                	mov    %edx,%ecx
f0103b63:	89 fa                	mov    %edi,%edx
f0103b65:	d3 e8                	shr    %cl,%eax
f0103b67:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103b6c:	09 d8                	or     %ebx,%eax
f0103b6e:	f7 f5                	div    %ebp
f0103b70:	d3 e6                	shl    %cl,%esi
f0103b72:	89 d1                	mov    %edx,%ecx
f0103b74:	f7 64 24 08          	mull   0x8(%esp)
f0103b78:	39 d1                	cmp    %edx,%ecx
f0103b7a:	89 c3                	mov    %eax,%ebx
f0103b7c:	89 d7                	mov    %edx,%edi
f0103b7e:	72 06                	jb     f0103b86 <__umoddi3+0xa6>
f0103b80:	75 0e                	jne    f0103b90 <__umoddi3+0xb0>
f0103b82:	39 c6                	cmp    %eax,%esi
f0103b84:	73 0a                	jae    f0103b90 <__umoddi3+0xb0>
f0103b86:	2b 44 24 08          	sub    0x8(%esp),%eax
f0103b8a:	19 ea                	sbb    %ebp,%edx
f0103b8c:	89 d7                	mov    %edx,%edi
f0103b8e:	89 c3                	mov    %eax,%ebx
f0103b90:	89 ca                	mov    %ecx,%edx
f0103b92:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f0103b97:	29 de                	sub    %ebx,%esi
f0103b99:	19 fa                	sbb    %edi,%edx
f0103b9b:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f0103b9f:	89 d0                	mov    %edx,%eax
f0103ba1:	d3 e0                	shl    %cl,%eax
f0103ba3:	89 d9                	mov    %ebx,%ecx
f0103ba5:	d3 ee                	shr    %cl,%esi
f0103ba7:	d3 ea                	shr    %cl,%edx
f0103ba9:	09 f0                	or     %esi,%eax
f0103bab:	83 c4 1c             	add    $0x1c,%esp
f0103bae:	5b                   	pop    %ebx
f0103baf:	5e                   	pop    %esi
f0103bb0:	5f                   	pop    %edi
f0103bb1:	5d                   	pop    %ebp
f0103bb2:	c3                   	ret    
f0103bb3:	90                   	nop
f0103bb4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103bb8:	85 ff                	test   %edi,%edi
f0103bba:	89 f9                	mov    %edi,%ecx
f0103bbc:	75 0b                	jne    f0103bc9 <__umoddi3+0xe9>
f0103bbe:	b8 01 00 00 00       	mov    $0x1,%eax
f0103bc3:	31 d2                	xor    %edx,%edx
f0103bc5:	f7 f7                	div    %edi
f0103bc7:	89 c1                	mov    %eax,%ecx
f0103bc9:	89 d8                	mov    %ebx,%eax
f0103bcb:	31 d2                	xor    %edx,%edx
f0103bcd:	f7 f1                	div    %ecx
f0103bcf:	89 f0                	mov    %esi,%eax
f0103bd1:	f7 f1                	div    %ecx
f0103bd3:	e9 31 ff ff ff       	jmp    f0103b09 <__umoddi3+0x29>
f0103bd8:	90                   	nop
f0103bd9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103be0:	39 dd                	cmp    %ebx,%ebp
f0103be2:	72 08                	jb     f0103bec <__umoddi3+0x10c>
f0103be4:	39 f7                	cmp    %esi,%edi
f0103be6:	0f 87 21 ff ff ff    	ja     f0103b0d <__umoddi3+0x2d>
f0103bec:	89 da                	mov    %ebx,%edx
f0103bee:	89 f0                	mov    %esi,%eax
f0103bf0:	29 f8                	sub    %edi,%eax
f0103bf2:	19 ea                	sbb    %ebp,%edx
f0103bf4:	e9 14 ff ff ff       	jmp    f0103b0d <__umoddi3+0x2d>
