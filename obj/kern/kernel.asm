
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
f0100015:	b8 00 10 11 00       	mov    $0x111000,%eax
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
f010002f:	bc 00 10 11 f0       	mov    $0xf0111000,%esp

	# now to C code
	call	i386_init
f0100034:	e8 02 00 00 00       	call   f010003b <i386_init>

f0100039 <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f0100039:	eb fe                	jmp    f0100039 <spin>

f010003b <i386_init>:
#include <kern/kalloc.h>
#include <kern/vm.h>

void
i386_init()
{
f010003b:	55                   	push   %ebp
f010003c:	89 e5                	mov    %esp,%ebp
f010003e:	83 ec 0c             	sub    $0xc,%esp
    extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
    memset(edata, 0, end - edata);
f0100041:	b8 80 39 11 f0       	mov    $0xf0113980,%eax
f0100046:	2d 00 33 11 f0       	sub    $0xf0113300,%eax
f010004b:	50                   	push   %eax
f010004c:	6a 00                	push   $0x0
f010004e:	68 00 33 11 f0       	push   $0xf0113300
f0100053:	e8 49 19 00 00       	call   f01019a1 <memset>

	cons_init();
f0100058:	e8 b5 04 00 00       	call   f0100512 <cons_init>

	cprintf("Hello, world.\n");
f010005d:	c7 04 24 e0 1d 10 f0 	movl   $0xf0101de0,(%esp)
f0100064:	e8 1b 06 00 00       	call   f0100684 <cprintf>
	boot_alloc_init();
f0100069:	e8 c9 0a 00 00       	call   f0100b37 <boot_alloc_init>
	vm_init();
f010006e:	e8 73 10 00 00       	call   f01010e6 <vm_init>
	alloc_init();
f0100073:	e8 54 0e 00 00       	call   f0100ecc <alloc_init>

	cprintf("VM: Init success.\n");
f0100078:	c7 04 24 ef 1d 10 f0 	movl   $0xf0101def,(%esp)
f010007f:	e8 00 06 00 00       	call   f0100684 <cprintf>
	check_free_list();
f0100084:	e8 1f 0a 00 00       	call   f0100aa8 <check_free_list>
	cprintf("Finish.\n");
f0100089:	c7 04 24 02 1e 10 f0 	movl   $0xf0101e02,(%esp)
f0100090:	e8 ef 05 00 00       	call   f0100684 <cprintf>
f0100095:	83 c4 10             	add    $0x10,%esp
f0100098:	eb fe                	jmp    f0100098 <i386_init+0x5d>

f010009a <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f010009a:	55                   	push   %ebp
f010009b:	89 e5                	mov    %esp,%ebp
f010009d:	56                   	push   %esi
f010009e:	53                   	push   %ebx
f010009f:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000a2:	83 3d 44 39 11 f0 00 	cmpl   $0x0,0xf0113944
f01000a9:	74 02                	je     f01000ad <_panic+0x13>
f01000ab:	eb fe                	jmp    f01000ab <_panic+0x11>
		goto dead;
	panicstr = fmt;
f01000ad:	89 35 44 39 11 f0    	mov    %esi,0xf0113944

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000b3:	fa                   	cli    
f01000b4:	fc                   	cld    

	va_start(ap, fmt);
f01000b5:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000b8:	83 ec 04             	sub    $0x4,%esp
f01000bb:	ff 75 0c             	pushl  0xc(%ebp)
f01000be:	ff 75 08             	pushl  0x8(%ebp)
f01000c1:	68 0b 1e 10 f0       	push   $0xf0101e0b
f01000c6:	e8 b9 05 00 00       	call   f0100684 <cprintf>
	vcprintf(fmt, ap);
f01000cb:	83 c4 08             	add    $0x8,%esp
f01000ce:	53                   	push   %ebx
f01000cf:	56                   	push   %esi
f01000d0:	e8 89 05 00 00       	call   f010065e <vcprintf>
	cprintf("\n");
f01000d5:	c7 04 24 47 1e 10 f0 	movl   $0xf0101e47,(%esp)
f01000dc:	e8 a3 05 00 00       	call   f0100684 <cprintf>
f01000e1:	83 c4 10             	add    $0x10,%esp
f01000e4:	eb c5                	jmp    f01000ab <_panic+0x11>

f01000e6 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000e6:	55                   	push   %ebp
f01000e7:	89 e5                	mov    %esp,%ebp
f01000e9:	53                   	push   %ebx
f01000ea:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01000ed:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000f0:	ff 75 0c             	pushl  0xc(%ebp)
f01000f3:	ff 75 08             	pushl  0x8(%ebp)
f01000f6:	68 23 1e 10 f0       	push   $0xf0101e23
f01000fb:	e8 84 05 00 00       	call   f0100684 <cprintf>
	vcprintf(fmt, ap);
f0100100:	83 c4 08             	add    $0x8,%esp
f0100103:	53                   	push   %ebx
f0100104:	ff 75 10             	pushl  0x10(%ebp)
f0100107:	e8 52 05 00 00       	call   f010065e <vcprintf>
	cprintf("\n");
f010010c:	c7 04 24 47 1e 10 f0 	movl   $0xf0101e47,(%esp)
f0100113:	e8 6c 05 00 00       	call   f0100684 <cprintf>
	va_end(ap);
}
f0100118:	83 c4 10             	add    $0x10,%esp
f010011b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010011e:	c9                   	leave  
f010011f:	c3                   	ret    

f0100120 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100120:	55                   	push   %ebp
f0100121:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100123:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100128:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100129:	a8 01                	test   $0x1,%al
f010012b:	74 0b                	je     f0100138 <serial_proc_data+0x18>
f010012d:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100132:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100133:	0f b6 c0             	movzbl %al,%eax
}
f0100136:	5d                   	pop    %ebp
f0100137:	c3                   	ret    
		return -1;
f0100138:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010013d:	eb f7                	jmp    f0100136 <serial_proc_data+0x16>

f010013f <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010013f:	55                   	push   %ebp
f0100140:	89 e5                	mov    %esp,%ebp
f0100142:	53                   	push   %ebx
f0100143:	83 ec 04             	sub    $0x4,%esp
f0100146:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100148:	ff d3                	call   *%ebx
f010014a:	83 f8 ff             	cmp    $0xffffffff,%eax
f010014d:	74 2d                	je     f010017c <cons_intr+0x3d>
		if (c == 0)
f010014f:	85 c0                	test   %eax,%eax
f0100151:	74 f5                	je     f0100148 <cons_intr+0x9>
			continue;
		cons.buf[cons.wpos++] = c;
f0100153:	8b 0d 24 35 11 f0    	mov    0xf0113524,%ecx
f0100159:	8d 51 01             	lea    0x1(%ecx),%edx
f010015c:	89 15 24 35 11 f0    	mov    %edx,0xf0113524
f0100162:	88 81 20 33 11 f0    	mov    %al,-0xfeecce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f0100168:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010016e:	75 d8                	jne    f0100148 <cons_intr+0x9>
			cons.wpos = 0;
f0100170:	c7 05 24 35 11 f0 00 	movl   $0x0,0xf0113524
f0100177:	00 00 00 
f010017a:	eb cc                	jmp    f0100148 <cons_intr+0x9>
	}
}
f010017c:	83 c4 04             	add    $0x4,%esp
f010017f:	5b                   	pop    %ebx
f0100180:	5d                   	pop    %ebp
f0100181:	c3                   	ret    

f0100182 <kbd_proc_data>:
{
f0100182:	55                   	push   %ebp
f0100183:	89 e5                	mov    %esp,%ebp
f0100185:	53                   	push   %ebx
f0100186:	83 ec 04             	sub    $0x4,%esp
f0100189:	ba 64 00 00 00       	mov    $0x64,%edx
f010018e:	ec                   	in     (%dx),%al
	if ((stat & KBS_DIB) == 0)
f010018f:	a8 01                	test   $0x1,%al
f0100191:	0f 84 fa 00 00 00    	je     f0100291 <kbd_proc_data+0x10f>
	if (stat & KBS_TERR)
f0100197:	a8 20                	test   $0x20,%al
f0100199:	0f 85 f9 00 00 00    	jne    f0100298 <kbd_proc_data+0x116>
f010019f:	ba 60 00 00 00       	mov    $0x60,%edx
f01001a4:	ec                   	in     (%dx),%al
f01001a5:	89 c2                	mov    %eax,%edx
	if (data == 0xE0) {
f01001a7:	3c e0                	cmp    $0xe0,%al
f01001a9:	0f 84 8e 00 00 00    	je     f010023d <kbd_proc_data+0xbb>
	} else if (data & 0x80) {
f01001af:	84 c0                	test   %al,%al
f01001b1:	0f 88 99 00 00 00    	js     f0100250 <kbd_proc_data+0xce>
	} else if (shift & E0ESC) {
f01001b7:	8b 0d 00 33 11 f0    	mov    0xf0113300,%ecx
f01001bd:	f6 c1 40             	test   $0x40,%cl
f01001c0:	74 0e                	je     f01001d0 <kbd_proc_data+0x4e>
		data |= 0x80;
f01001c2:	83 c8 80             	or     $0xffffff80,%eax
f01001c5:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f01001c7:	83 e1 bf             	and    $0xffffffbf,%ecx
f01001ca:	89 0d 00 33 11 f0    	mov    %ecx,0xf0113300
	shift |= shiftcode[data];
f01001d0:	0f b6 d2             	movzbl %dl,%edx
f01001d3:	0f b6 82 a0 1f 10 f0 	movzbl -0xfefe060(%edx),%eax
f01001da:	0b 05 00 33 11 f0    	or     0xf0113300,%eax
	shift ^= togglecode[data];
f01001e0:	0f b6 8a a0 1e 10 f0 	movzbl -0xfefe160(%edx),%ecx
f01001e7:	31 c8                	xor    %ecx,%eax
f01001e9:	a3 00 33 11 f0       	mov    %eax,0xf0113300
	c = charcode[shift & (CTL | SHIFT)][data];
f01001ee:	89 c1                	mov    %eax,%ecx
f01001f0:	83 e1 03             	and    $0x3,%ecx
f01001f3:	8b 0c 8d 80 1e 10 f0 	mov    -0xfefe180(,%ecx,4),%ecx
f01001fa:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f01001fe:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100201:	a8 08                	test   $0x8,%al
f0100203:	74 0d                	je     f0100212 <kbd_proc_data+0x90>
		if ('a' <= c && c <= 'z')
f0100205:	89 da                	mov    %ebx,%edx
f0100207:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f010020a:	83 f9 19             	cmp    $0x19,%ecx
f010020d:	77 74                	ja     f0100283 <kbd_proc_data+0x101>
			c += 'A' - 'a';
f010020f:	83 eb 20             	sub    $0x20,%ebx
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100212:	f7 d0                	not    %eax
f0100214:	a8 06                	test   $0x6,%al
f0100216:	75 31                	jne    f0100249 <kbd_proc_data+0xc7>
f0100218:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f010021e:	75 29                	jne    f0100249 <kbd_proc_data+0xc7>
		cprintf("Rebooting!\n");
f0100220:	83 ec 0c             	sub    $0xc,%esp
f0100223:	68 3d 1e 10 f0       	push   $0xf0101e3d
f0100228:	e8 57 04 00 00       	call   f0100684 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010022d:	b8 03 00 00 00       	mov    $0x3,%eax
f0100232:	ba 92 00 00 00       	mov    $0x92,%edx
f0100237:	ee                   	out    %al,(%dx)
f0100238:	83 c4 10             	add    $0x10,%esp
f010023b:	eb 0c                	jmp    f0100249 <kbd_proc_data+0xc7>
		shift |= E0ESC;
f010023d:	83 0d 00 33 11 f0 40 	orl    $0x40,0xf0113300
		return 0;
f0100244:	bb 00 00 00 00       	mov    $0x0,%ebx
}
f0100249:	89 d8                	mov    %ebx,%eax
f010024b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010024e:	c9                   	leave  
f010024f:	c3                   	ret    
		data = (shift & E0ESC ? data : data & 0x7F);
f0100250:	8b 0d 00 33 11 f0    	mov    0xf0113300,%ecx
f0100256:	89 cb                	mov    %ecx,%ebx
f0100258:	83 e3 40             	and    $0x40,%ebx
f010025b:	83 e0 7f             	and    $0x7f,%eax
f010025e:	85 db                	test   %ebx,%ebx
f0100260:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100263:	0f b6 d2             	movzbl %dl,%edx
f0100266:	0f b6 82 a0 1f 10 f0 	movzbl -0xfefe060(%edx),%eax
f010026d:	83 c8 40             	or     $0x40,%eax
f0100270:	0f b6 c0             	movzbl %al,%eax
f0100273:	f7 d0                	not    %eax
f0100275:	21 c8                	and    %ecx,%eax
f0100277:	a3 00 33 11 f0       	mov    %eax,0xf0113300
		return 0;
f010027c:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100281:	eb c6                	jmp    f0100249 <kbd_proc_data+0xc7>
		else if ('A' <= c && c <= 'Z')
f0100283:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f0100286:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100289:	83 fa 1a             	cmp    $0x1a,%edx
f010028c:	0f 42 d9             	cmovb  %ecx,%ebx
f010028f:	eb 81                	jmp    f0100212 <kbd_proc_data+0x90>
		return -1;
f0100291:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
f0100296:	eb b1                	jmp    f0100249 <kbd_proc_data+0xc7>
		return -1;
f0100298:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
f010029d:	eb aa                	jmp    f0100249 <kbd_proc_data+0xc7>

f010029f <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f010029f:	55                   	push   %ebp
f01002a0:	89 e5                	mov    %esp,%ebp
f01002a2:	57                   	push   %edi
f01002a3:	56                   	push   %esi
f01002a4:	53                   	push   %ebx
f01002a5:	83 ec 1c             	sub    $0x1c,%esp
f01002a8:	89 c7                	mov    %eax,%edi
	for (i = 0;
f01002aa:	bb 00 00 00 00       	mov    $0x0,%ebx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002af:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002b4:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002b9:	eb 09                	jmp    f01002c4 <cons_putc+0x25>
f01002bb:	89 ca                	mov    %ecx,%edx
f01002bd:	ec                   	in     (%dx),%al
f01002be:	ec                   	in     (%dx),%al
f01002bf:	ec                   	in     (%dx),%al
f01002c0:	ec                   	in     (%dx),%al
	     i++)
f01002c1:	83 c3 01             	add    $0x1,%ebx
f01002c4:	89 f2                	mov    %esi,%edx
f01002c6:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002c7:	a8 20                	test   $0x20,%al
f01002c9:	75 08                	jne    f01002d3 <cons_putc+0x34>
f01002cb:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002d1:	7e e8                	jle    f01002bb <cons_putc+0x1c>
	outb(COM1 + COM_TX, c);
f01002d3:	89 f8                	mov    %edi,%eax
f01002d5:	88 45 e7             	mov    %al,-0x19(%ebp)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002d8:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002dd:	ee                   	out    %al,(%dx)
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002de:	bb 00 00 00 00       	mov    $0x0,%ebx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002e3:	be 79 03 00 00       	mov    $0x379,%esi
f01002e8:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002ed:	eb 09                	jmp    f01002f8 <cons_putc+0x59>
f01002ef:	89 ca                	mov    %ecx,%edx
f01002f1:	ec                   	in     (%dx),%al
f01002f2:	ec                   	in     (%dx),%al
f01002f3:	ec                   	in     (%dx),%al
f01002f4:	ec                   	in     (%dx),%al
f01002f5:	83 c3 01             	add    $0x1,%ebx
f01002f8:	89 f2                	mov    %esi,%edx
f01002fa:	ec                   	in     (%dx),%al
f01002fb:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100301:	7f 04                	jg     f0100307 <cons_putc+0x68>
f0100303:	84 c0                	test   %al,%al
f0100305:	79 e8                	jns    f01002ef <cons_putc+0x50>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100307:	ba 78 03 00 00       	mov    $0x378,%edx
f010030c:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100310:	ee                   	out    %al,(%dx)
f0100311:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100316:	b8 0d 00 00 00       	mov    $0xd,%eax
f010031b:	ee                   	out    %al,(%dx)
f010031c:	b8 08 00 00 00       	mov    $0x8,%eax
f0100321:	ee                   	out    %al,(%dx)
	if (!(c & ~0xFF))
f0100322:	89 fa                	mov    %edi,%edx
f0100324:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f010032a:	89 f8                	mov    %edi,%eax
f010032c:	80 cc 07             	or     $0x7,%ah
f010032f:	85 d2                	test   %edx,%edx
f0100331:	0f 44 f8             	cmove  %eax,%edi
	switch (c & 0xff) {
f0100334:	89 f8                	mov    %edi,%eax
f0100336:	0f b6 c0             	movzbl %al,%eax
f0100339:	83 f8 09             	cmp    $0x9,%eax
f010033c:	0f 84 b6 00 00 00    	je     f01003f8 <cons_putc+0x159>
f0100342:	83 f8 09             	cmp    $0x9,%eax
f0100345:	7e 73                	jle    f01003ba <cons_putc+0x11b>
f0100347:	83 f8 0a             	cmp    $0xa,%eax
f010034a:	0f 84 9b 00 00 00    	je     f01003eb <cons_putc+0x14c>
f0100350:	83 f8 0d             	cmp    $0xd,%eax
f0100353:	0f 85 d6 00 00 00    	jne    f010042f <cons_putc+0x190>
		crt_pos -= (crt_pos % CRT_COLS);
f0100359:	0f b7 05 28 35 11 f0 	movzwl 0xf0113528,%eax
f0100360:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100366:	c1 e8 16             	shr    $0x16,%eax
f0100369:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010036c:	c1 e0 04             	shl    $0x4,%eax
f010036f:	66 a3 28 35 11 f0    	mov    %ax,0xf0113528
	if (crt_pos >= CRT_SIZE) {
f0100375:	66 81 3d 28 35 11 f0 	cmpw   $0x7cf,0xf0113528
f010037c:	cf 07 
f010037e:	0f 87 ce 00 00 00    	ja     f0100452 <cons_putc+0x1b3>
	outb(addr_6845, 14);
f0100384:	8b 0d 30 35 11 f0    	mov    0xf0113530,%ecx
f010038a:	b8 0e 00 00 00       	mov    $0xe,%eax
f010038f:	89 ca                	mov    %ecx,%edx
f0100391:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100392:	0f b7 1d 28 35 11 f0 	movzwl 0xf0113528,%ebx
f0100399:	8d 71 01             	lea    0x1(%ecx),%esi
f010039c:	89 d8                	mov    %ebx,%eax
f010039e:	66 c1 e8 08          	shr    $0x8,%ax
f01003a2:	89 f2                	mov    %esi,%edx
f01003a4:	ee                   	out    %al,(%dx)
f01003a5:	b8 0f 00 00 00       	mov    $0xf,%eax
f01003aa:	89 ca                	mov    %ecx,%edx
f01003ac:	ee                   	out    %al,(%dx)
f01003ad:	89 d8                	mov    %ebx,%eax
f01003af:	89 f2                	mov    %esi,%edx
f01003b1:	ee                   	out    %al,(%dx)
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01003b2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01003b5:	5b                   	pop    %ebx
f01003b6:	5e                   	pop    %esi
f01003b7:	5f                   	pop    %edi
f01003b8:	5d                   	pop    %ebp
f01003b9:	c3                   	ret    
	switch (c & 0xff) {
f01003ba:	83 f8 08             	cmp    $0x8,%eax
f01003bd:	75 70                	jne    f010042f <cons_putc+0x190>
		if (crt_pos > 0) {
f01003bf:	0f b7 05 28 35 11 f0 	movzwl 0xf0113528,%eax
f01003c6:	66 85 c0             	test   %ax,%ax
f01003c9:	74 b9                	je     f0100384 <cons_putc+0xe5>
			crt_pos--;
f01003cb:	83 e8 01             	sub    $0x1,%eax
f01003ce:	66 a3 28 35 11 f0    	mov    %ax,0xf0113528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003d4:	0f b7 c0             	movzwl %ax,%eax
f01003d7:	66 81 e7 00 ff       	and    $0xff00,%di
f01003dc:	83 cf 20             	or     $0x20,%edi
f01003df:	8b 15 2c 35 11 f0    	mov    0xf011352c,%edx
f01003e5:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003e9:	eb 8a                	jmp    f0100375 <cons_putc+0xd6>
		crt_pos += CRT_COLS;
f01003eb:	66 83 05 28 35 11 f0 	addw   $0x50,0xf0113528
f01003f2:	50 
f01003f3:	e9 61 ff ff ff       	jmp    f0100359 <cons_putc+0xba>
		cons_putc(' ');
f01003f8:	b8 20 00 00 00       	mov    $0x20,%eax
f01003fd:	e8 9d fe ff ff       	call   f010029f <cons_putc>
		cons_putc(' ');
f0100402:	b8 20 00 00 00       	mov    $0x20,%eax
f0100407:	e8 93 fe ff ff       	call   f010029f <cons_putc>
		cons_putc(' ');
f010040c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100411:	e8 89 fe ff ff       	call   f010029f <cons_putc>
		cons_putc(' ');
f0100416:	b8 20 00 00 00       	mov    $0x20,%eax
f010041b:	e8 7f fe ff ff       	call   f010029f <cons_putc>
		cons_putc(' ');
f0100420:	b8 20 00 00 00       	mov    $0x20,%eax
f0100425:	e8 75 fe ff ff       	call   f010029f <cons_putc>
f010042a:	e9 46 ff ff ff       	jmp    f0100375 <cons_putc+0xd6>
		crt_buf[crt_pos++] = c;		/* write the character */
f010042f:	0f b7 05 28 35 11 f0 	movzwl 0xf0113528,%eax
f0100436:	8d 50 01             	lea    0x1(%eax),%edx
f0100439:	66 89 15 28 35 11 f0 	mov    %dx,0xf0113528
f0100440:	0f b7 c0             	movzwl %ax,%eax
f0100443:	8b 15 2c 35 11 f0    	mov    0xf011352c,%edx
f0100449:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f010044d:	e9 23 ff ff ff       	jmp    f0100375 <cons_putc+0xd6>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100452:	a1 2c 35 11 f0       	mov    0xf011352c,%eax
f0100457:	83 ec 04             	sub    $0x4,%esp
f010045a:	68 00 0f 00 00       	push   $0xf00
f010045f:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100465:	52                   	push   %edx
f0100466:	50                   	push   %eax
f0100467:	e8 82 15 00 00       	call   f01019ee <memmove>
			crt_buf[i] = 0x0700 | ' ';
f010046c:	8b 15 2c 35 11 f0    	mov    0xf011352c,%edx
f0100472:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100478:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f010047e:	83 c4 10             	add    $0x10,%esp
f0100481:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100486:	83 c0 02             	add    $0x2,%eax
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100489:	39 d0                	cmp    %edx,%eax
f010048b:	75 f4                	jne    f0100481 <cons_putc+0x1e2>
		crt_pos -= CRT_COLS;
f010048d:	66 83 2d 28 35 11 f0 	subw   $0x50,0xf0113528
f0100494:	50 
f0100495:	e9 ea fe ff ff       	jmp    f0100384 <cons_putc+0xe5>

f010049a <serial_intr>:
	if (serial_exists)
f010049a:	80 3d 34 35 11 f0 00 	cmpb   $0x0,0xf0113534
f01004a1:	75 02                	jne    f01004a5 <serial_intr+0xb>
f01004a3:	f3 c3                	repz ret 
{
f01004a5:	55                   	push   %ebp
f01004a6:	89 e5                	mov    %esp,%ebp
f01004a8:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f01004ab:	b8 20 01 10 f0       	mov    $0xf0100120,%eax
f01004b0:	e8 8a fc ff ff       	call   f010013f <cons_intr>
}
f01004b5:	c9                   	leave  
f01004b6:	c3                   	ret    

f01004b7 <kbd_intr>:
{
f01004b7:	55                   	push   %ebp
f01004b8:	89 e5                	mov    %esp,%ebp
f01004ba:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004bd:	b8 82 01 10 f0       	mov    $0xf0100182,%eax
f01004c2:	e8 78 fc ff ff       	call   f010013f <cons_intr>
}
f01004c7:	c9                   	leave  
f01004c8:	c3                   	ret    

f01004c9 <cons_getc>:
{
f01004c9:	55                   	push   %ebp
f01004ca:	89 e5                	mov    %esp,%ebp
f01004cc:	83 ec 08             	sub    $0x8,%esp
	serial_intr();
f01004cf:	e8 c6 ff ff ff       	call   f010049a <serial_intr>
	kbd_intr();
f01004d4:	e8 de ff ff ff       	call   f01004b7 <kbd_intr>
	if (cons.rpos != cons.wpos) {
f01004d9:	8b 15 20 35 11 f0    	mov    0xf0113520,%edx
	return 0;
f01004df:	b8 00 00 00 00       	mov    $0x0,%eax
	if (cons.rpos != cons.wpos) {
f01004e4:	3b 15 24 35 11 f0    	cmp    0xf0113524,%edx
f01004ea:	74 18                	je     f0100504 <cons_getc+0x3b>
		c = cons.buf[cons.rpos++];
f01004ec:	8d 4a 01             	lea    0x1(%edx),%ecx
f01004ef:	89 0d 20 35 11 f0    	mov    %ecx,0xf0113520
f01004f5:	0f b6 82 20 33 11 f0 	movzbl -0xfeecce0(%edx),%eax
		if (cons.rpos == CONSBUFSIZE)
f01004fc:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f0100502:	74 02                	je     f0100506 <cons_getc+0x3d>
}
f0100504:	c9                   	leave  
f0100505:	c3                   	ret    
			cons.rpos = 0;
f0100506:	c7 05 20 35 11 f0 00 	movl   $0x0,0xf0113520
f010050d:	00 00 00 
f0100510:	eb f2                	jmp    f0100504 <cons_getc+0x3b>

f0100512 <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f0100512:	55                   	push   %ebp
f0100513:	89 e5                	mov    %esp,%ebp
f0100515:	57                   	push   %edi
f0100516:	56                   	push   %esi
f0100517:	53                   	push   %ebx
f0100518:	83 ec 0c             	sub    $0xc,%esp
	was = *cp;
f010051b:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100522:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100529:	5a a5 
	if (*cp != 0xA55A) {
f010052b:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100532:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100536:	0f 84 b7 00 00 00    	je     f01005f3 <cons_init+0xe1>
		addr_6845 = MONO_BASE;
f010053c:	c7 05 30 35 11 f0 b4 	movl   $0x3b4,0xf0113530
f0100543:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100546:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
	outb(addr_6845, 14);
f010054b:	8b 3d 30 35 11 f0    	mov    0xf0113530,%edi
f0100551:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100556:	89 fa                	mov    %edi,%edx
f0100558:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100559:	8d 4f 01             	lea    0x1(%edi),%ecx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010055c:	89 ca                	mov    %ecx,%edx
f010055e:	ec                   	in     (%dx),%al
f010055f:	0f b6 c0             	movzbl %al,%eax
f0100562:	c1 e0 08             	shl    $0x8,%eax
f0100565:	89 c3                	mov    %eax,%ebx
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100567:	b8 0f 00 00 00       	mov    $0xf,%eax
f010056c:	89 fa                	mov    %edi,%edx
f010056e:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010056f:	89 ca                	mov    %ecx,%edx
f0100571:	ec                   	in     (%dx),%al
	crt_buf = (uint16_t*) cp;
f0100572:	89 35 2c 35 11 f0    	mov    %esi,0xf011352c
	pos |= inb(addr_6845 + 1);
f0100578:	0f b6 c0             	movzbl %al,%eax
f010057b:	09 d8                	or     %ebx,%eax
	crt_pos = pos;
f010057d:	66 a3 28 35 11 f0    	mov    %ax,0xf0113528
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100583:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100588:	b9 fa 03 00 00       	mov    $0x3fa,%ecx
f010058d:	89 d8                	mov    %ebx,%eax
f010058f:	89 ca                	mov    %ecx,%edx
f0100591:	ee                   	out    %al,(%dx)
f0100592:	bf fb 03 00 00       	mov    $0x3fb,%edi
f0100597:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f010059c:	89 fa                	mov    %edi,%edx
f010059e:	ee                   	out    %al,(%dx)
f010059f:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005a4:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01005a9:	ee                   	out    %al,(%dx)
f01005aa:	be f9 03 00 00       	mov    $0x3f9,%esi
f01005af:	89 d8                	mov    %ebx,%eax
f01005b1:	89 f2                	mov    %esi,%edx
f01005b3:	ee                   	out    %al,(%dx)
f01005b4:	b8 03 00 00 00       	mov    $0x3,%eax
f01005b9:	89 fa                	mov    %edi,%edx
f01005bb:	ee                   	out    %al,(%dx)
f01005bc:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01005c1:	89 d8                	mov    %ebx,%eax
f01005c3:	ee                   	out    %al,(%dx)
f01005c4:	b8 01 00 00 00       	mov    $0x1,%eax
f01005c9:	89 f2                	mov    %esi,%edx
f01005cb:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005cc:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01005d1:	ec                   	in     (%dx),%al
f01005d2:	89 c3                	mov    %eax,%ebx
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005d4:	3c ff                	cmp    $0xff,%al
f01005d6:	0f 95 05 34 35 11 f0 	setne  0xf0113534
f01005dd:	89 ca                	mov    %ecx,%edx
f01005df:	ec                   	in     (%dx),%al
f01005e0:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01005e5:	ec                   	in     (%dx),%al
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005e6:	80 fb ff             	cmp    $0xff,%bl
f01005e9:	74 23                	je     f010060e <cons_init+0xfc>
		cprintf("Serial port does not exist!\n");
}
f01005eb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01005ee:	5b                   	pop    %ebx
f01005ef:	5e                   	pop    %esi
f01005f0:	5f                   	pop    %edi
f01005f1:	5d                   	pop    %ebp
f01005f2:	c3                   	ret    
		*cp = was;
f01005f3:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01005fa:	c7 05 30 35 11 f0 d4 	movl   $0x3d4,0xf0113530
f0100601:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100604:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
f0100609:	e9 3d ff ff ff       	jmp    f010054b <cons_init+0x39>
		cprintf("Serial port does not exist!\n");
f010060e:	83 ec 0c             	sub    $0xc,%esp
f0100611:	68 49 1e 10 f0       	push   $0xf0101e49
f0100616:	e8 69 00 00 00       	call   f0100684 <cprintf>
f010061b:	83 c4 10             	add    $0x10,%esp
}
f010061e:	eb cb                	jmp    f01005eb <cons_init+0xd9>

f0100620 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100620:	55                   	push   %ebp
f0100621:	89 e5                	mov    %esp,%ebp
f0100623:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100626:	8b 45 08             	mov    0x8(%ebp),%eax
f0100629:	e8 71 fc ff ff       	call   f010029f <cons_putc>
}
f010062e:	c9                   	leave  
f010062f:	c3                   	ret    

f0100630 <getchar>:

int
getchar(void)
{
f0100630:	55                   	push   %ebp
f0100631:	89 e5                	mov    %esp,%ebp
f0100633:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100636:	e8 8e fe ff ff       	call   f01004c9 <cons_getc>
f010063b:	85 c0                	test   %eax,%eax
f010063d:	74 f7                	je     f0100636 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010063f:	c9                   	leave  
f0100640:	c3                   	ret    

f0100641 <iscons>:

int
iscons(int fdnum)
{
f0100641:	55                   	push   %ebp
f0100642:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100644:	b8 01 00 00 00       	mov    $0x1,%eax
f0100649:	5d                   	pop    %ebp
f010064a:	c3                   	ret    

f010064b <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010064b:	55                   	push   %ebp
f010064c:	89 e5                	mov    %esp,%ebp
f010064e:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0100651:	ff 75 08             	pushl  0x8(%ebp)
f0100654:	e8 c7 ff ff ff       	call   f0100620 <cputchar>
	*cnt++;
}
f0100659:	83 c4 10             	add    $0x10,%esp
f010065c:	c9                   	leave  
f010065d:	c3                   	ret    

f010065e <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f010065e:	55                   	push   %ebp
f010065f:	89 e5                	mov    %esp,%ebp
f0100661:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0100664:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010066b:	ff 75 0c             	pushl  0xc(%ebp)
f010066e:	ff 75 08             	pushl  0x8(%ebp)
f0100671:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100674:	50                   	push   %eax
f0100675:	68 4b 06 10 f0       	push   $0xf010064b
f010067a:	e8 dd 0b 00 00       	call   f010125c <vprintfmt>
	return cnt;
}
f010067f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100682:	c9                   	leave  
f0100683:	c3                   	ret    

f0100684 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100684:	55                   	push   %ebp
f0100685:	89 e5                	mov    %esp,%ebp
f0100687:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010068a:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f010068d:	50                   	push   %eax
f010068e:	ff 75 08             	pushl  0x8(%ebp)
f0100691:	e8 c8 ff ff ff       	call   f010065e <vcprintf>
	va_end(ap);

	return cnt;
}
f0100696:	c9                   	leave  
f0100697:	c3                   	ret    

f0100698 <pow_2>:
// the pages mapped by entrypgdir on free list.
// 2. Call alloc_init() with the rest of the physical pages after
// installing a full page table.

int pow_2(int power)
{
f0100698:	55                   	push   %ebp
f0100699:	89 e5                	mov    %esp,%ebp
f010069b:	8b 4d 08             	mov    0x8(%ebp),%ecx
	int num = 1;
	for (int i = 0; i < power; i++)
f010069e:	ba 00 00 00 00       	mov    $0x0,%edx
	int num = 1;
f01006a3:	b8 01 00 00 00       	mov    $0x1,%eax
	for (int i = 0; i < power; i++)
f01006a8:	eb 05                	jmp    f01006af <pow_2+0x17>
		num *= 2;
f01006aa:	01 c0                	add    %eax,%eax
	for (int i = 0; i < power; i++)
f01006ac:	83 c2 01             	add    $0x1,%edx
f01006af:	39 ca                	cmp    %ecx,%edx
f01006b1:	7c f7                	jl     f01006aa <pow_2+0x12>
	return num;
}
f01006b3:	5d                   	pop    %ebp
f01006b4:	c3                   	ret    

f01006b5 <Buddykfree>:
	kmem.free_list = r;*/
}

void
Buddykfree(char *v)
{
f01006b5:	55                   	push   %ebp
f01006b6:	89 e5                	mov    %esp,%ebp
f01006b8:	57                   	push   %edi
f01006b9:	56                   	push   %esi
f01006ba:	53                   	push   %ebx
f01006bb:	83 ec 2c             	sub    $0x2c,%esp
	struct run *r;

	if ((uint32_t)v % PGSIZE || v < end || V2P(v) >= PHYSTOP)
f01006be:	8b 45 08             	mov    0x8(%ebp),%eax
f01006c1:	a9 ff 0f 00 00       	test   $0xfff,%eax
f01006c6:	75 44                	jne    f010070c <Buddykfree+0x57>
f01006c8:	3d 80 39 11 f0       	cmp    $0xf0113980,%eax
f01006cd:	72 3d                	jb     f010070c <Buddykfree+0x57>
f01006cf:	05 00 00 00 10       	add    $0x10000000,%eax
f01006d4:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
f01006d9:	77 31                	ja     f010070c <Buddykfree+0x57>
		panic("kfree");
	int idx, id;
	if ((void *)v >= (void *)base[1]) {
f01006db:	a1 4c 39 11 f0       	mov    0xf011394c,%eax
f01006e0:	3b 45 08             	cmp    0x8(%ebp),%eax
f01006e3:	77 3e                	ja     f0100723 <Buddykfree+0x6e>
		idx = (uint32_t)((void *)v - (void *)base[1]) / PGSIZE;
f01006e5:	8b 7d 08             	mov    0x8(%ebp),%edi
f01006e8:	29 c7                	sub    %eax,%edi
f01006ea:	89 f8                	mov    %edi,%eax
f01006ec:	c1 e8 0c             	shr    $0xc,%eax
f01006ef:	89 45 cc             	mov    %eax,-0x34(%ebp)
		id = 1;
f01006f2:	bf 01 00 00 00       	mov    $0x1,%edi
		//cprintf("minus: %x, num: %x,idx: %x\n", (void *)v - (void *)base[0], (uint32_t)((void *)v - (void *)base[0]) / PGSIZE, idx);
	}
	int p = idx;
	int count = 0;
	//cprintf("v: %x, idx: %x, p: %x\n", v, idx, p);
	while (order[id][p] != 1) {
f01006f7:	8b 14 bd 64 39 11 f0 	mov    -0xfeec69c(,%edi,4),%edx
	int p = idx;
f01006fe:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0100701:	89 c3                	mov    %eax,%ebx
	int count = 0;
f0100703:	be 00 00 00 00       	mov    $0x0,%esi
f0100708:	89 f1                	mov    %esi,%ecx
	while (order[id][p] != 1) {
f010070a:	eb 3e                	jmp    f010074a <Buddykfree+0x95>
		panic("kfree");
f010070c:	83 ec 04             	sub    $0x4,%esp
f010070f:	68 a0 20 10 f0       	push   $0xf01020a0
f0100714:	68 d7 00 00 00       	push   $0xd7
f0100719:	68 a6 20 10 f0       	push   $0xf01020a6
f010071e:	e8 77 f9 ff ff       	call   f010009a <_panic>
		idx = (uint32_t)((void *)v - (void *)base[0]) / PGSIZE;
f0100723:	8b 45 08             	mov    0x8(%ebp),%eax
f0100726:	2b 05 48 39 11 f0    	sub    0xf0113948,%eax
f010072c:	c1 e8 0c             	shr    $0xc,%eax
f010072f:	89 45 cc             	mov    %eax,-0x34(%ebp)
		id = 0;
f0100732:	bf 00 00 00 00       	mov    $0x0,%edi
f0100737:	eb be                	jmp    f01006f7 <Buddykfree+0x42>
		count++;
f0100739:	83 c1 01             	add    $0x1,%ecx
		p = start[id][count] + (idx >> count);
f010073c:	8b 34 bd 6c 39 11 f0 	mov    -0xfeec694(,%edi,4),%esi
f0100743:	89 c3                	mov    %eax,%ebx
f0100745:	d3 fb                	sar    %cl,%ebx
f0100747:	03 1c 8e             	add    (%esi,%ecx,4),%ebx
	while (order[id][p] != 1) {
f010074a:	80 3c 1a 00          	cmpb   $0x0,(%edx,%ebx,1)
f010074e:	74 e9                	je     f0100739 <Buddykfree+0x84>
f0100750:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0100753:	89 ce                	mov    %ecx,%esi
	}
	//cprintf("p: %x\n", p);
	memset(v, 1, PGSIZE * pow_2(count));
f0100755:	83 ec 0c             	sub    $0xc,%esp
f0100758:	51                   	push   %ecx
f0100759:	e8 3a ff ff ff       	call   f0100698 <pow_2>
f010075e:	83 c4 0c             	add    $0xc,%esp
f0100761:	c1 e0 0c             	shl    $0xc,%eax
f0100764:	50                   	push   %eax
f0100765:	6a 01                	push   $0x1
f0100767:	ff 75 08             	pushl  0x8(%ebp)
f010076a:	e8 32 12 00 00       	call   f01019a1 <memset>
	order[id][p] = 0;
f010076f:	8b 04 bd 64 39 11 f0 	mov    -0xfeec69c(,%edi,4),%eax
f0100776:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100779:	c6 04 10 00          	movb   $0x0,(%eax,%edx,1)
	int buddy = p ^ 1;
f010077d:	89 d8                	mov    %ebx,%eax
f010077f:	83 f0 01             	xor    $0x1,%eax
	int mark = 1 << (count + 12);
f0100782:	8d 4e 0c             	lea    0xc(%esi),%ecx
f0100785:	ba 01 00 00 00       	mov    $0x1,%edx
f010078a:	d3 e2                	shl    %cl,%edx
f010078c:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010078f:	8d 1c f5 00 00 00 00 	lea    0x0(,%esi,8),%ebx
f0100796:	89 5d e0             	mov    %ebx,-0x20(%ebp)
f0100799:	8d 1c b5 04 00 00 00 	lea    0x4(,%esi,4),%ebx
f01007a0:	89 5d d8             	mov    %ebx,-0x28(%ebp)
	char *buddypos;
	while (count < MAX_ORDER[id] && order[id][buddy] == 0) {
f01007a3:	83 c4 10             	add    $0x10,%esp
f01007a6:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f01007a9:	eb 7e                	jmp    f0100829 <Buddykfree+0x174>
		//cprintf("p: %x, buddy: %x\n", p, buddy);
		buddypos = (char *)base[id] + ((uint32_t)(v - (char *)base[id]) ^ mark);
		//cprintf("buddypos: %x, mark: %x\n", buddypos, mark);
		struct run *iter = Buddy[id][count].free_list;
		while (iter->next != (struct run *)buddypos && iter->next != Buddy[id][count].free_list)
f01007ab:	89 c2                	mov    %eax,%edx
f01007ad:	8b 02                	mov    (%edx),%eax
f01007af:	39 f0                	cmp    %esi,%eax
f01007b1:	0f 95 c3             	setne  %bl
f01007b4:	39 f8                	cmp    %edi,%eax
f01007b6:	0f 95 c1             	setne  %cl
f01007b9:	84 cb                	test   %cl,%bl
f01007bb:	75 ee                	jne    f01007ab <Buddykfree+0xf6>
f01007bd:	8b 7d d0             	mov    -0x30(%ebp),%edi
f01007c0:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01007c3:	8d 5e 08             	lea    0x8(%esi),%ebx
			iter = iter->next;
		// buddy is occupied
		if (iter->next != (struct run *)buddypos)
f01007c6:	3b 45 d4             	cmp    -0x2c(%ebp),%eax
f01007c9:	0f 85 a1 00 00 00    	jne    f0100870 <Buddykfree+0x1bb>
			break;
		struct run *uni = iter->next;
		iter->next = uni->next;
f01007cf:	8b 08                	mov    (%eax),%ecx
f01007d1:	89 0a                	mov    %ecx,(%edx)
		Buddy[id][count].num--;
f01007d3:	89 f1                	mov    %esi,%ecx
f01007d5:	03 0c bd 54 39 11 f0 	add    -0xfeec6ac(,%edi,4),%ecx
f01007dc:	83 69 04 01          	subl   $0x1,0x4(%ecx)
		Buddy[id][count].free_list = iter->next;
f01007e0:	8b 0a                	mov    (%edx),%ecx
f01007e2:	8b 14 bd 54 39 11 f0 	mov    -0xfeec6ac(,%edi,4),%edx
f01007e9:	89 0c 32             	mov    %ecx,(%edx,%esi,1)
		v = (v > (char *)uni) ? (char *)uni : v;
f01007ec:	39 45 08             	cmp    %eax,0x8(%ebp)
f01007ef:	0f 46 45 08          	cmovbe 0x8(%ebp),%eax
f01007f3:	89 45 08             	mov    %eax,0x8(%ebp)
		count++;
f01007f6:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
f01007fa:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
		mark <<= 1;
f01007fd:	d1 65 dc             	shll   -0x24(%ebp)
		p = start[id][count] + (idx >> count);
f0100800:	8b 14 bd 6c 39 11 f0 	mov    -0xfeec694(,%edi,4),%edx
f0100807:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010080a:	d3 f8                	sar    %cl,%eax
f010080c:	8b 75 d8             	mov    -0x28(%ebp),%esi
f010080f:	03 04 32             	add    (%edx,%esi,1),%eax
		//cprintf("order: %d, p: %x\n", order[id][p], p);
		order[id][p] = 0;
f0100812:	8b 14 bd 64 39 11 f0 	mov    -0xfeec69c(,%edi,4),%edx
f0100819:	c6 04 02 00          	movb   $0x0,(%edx,%eax,1)
		//cprintf("order: %d\n", order[id][p]);
		buddy = p ^ 1;
f010081d:	83 f0 01             	xor    $0x1,%eax
f0100820:	83 c6 04             	add    $0x4,%esi
f0100823:	89 75 d8             	mov    %esi,-0x28(%ebp)
f0100826:	89 5d e0             	mov    %ebx,-0x20(%ebp)
	while (count < MAX_ORDER[id] && order[id][buddy] == 0) {
f0100829:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010082c:	39 1c bd 74 39 11 f0 	cmp    %ebx,-0xfeec68c(,%edi,4)
f0100833:	7e 3b                	jle    f0100870 <Buddykfree+0x1bb>
f0100835:	8b 14 bd 64 39 11 f0 	mov    -0xfeec69c(,%edi,4),%edx
f010083c:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0100840:	75 2e                	jne    f0100870 <Buddykfree+0x1bb>
		buddypos = (char *)base[id] + ((uint32_t)(v - (char *)base[id]) ^ mark);
f0100842:	8b 04 bd 48 39 11 f0 	mov    -0xfeec6b8(,%edi,4),%eax
f0100849:	8b 75 08             	mov    0x8(%ebp),%esi
f010084c:	29 c6                	sub    %eax,%esi
f010084e:	33 75 dc             	xor    -0x24(%ebp),%esi
f0100851:	8d 1c 30             	lea    (%eax,%esi,1),%ebx
f0100854:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
		struct run *iter = Buddy[id][count].free_list;
f0100857:	8b 04 bd 54 39 11 f0 	mov    -0xfeec6ac(,%edi,4),%eax
f010085e:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0100861:	8b 34 10             	mov    (%eax,%edx,1),%esi
f0100864:	89 f2                	mov    %esi,%edx
f0100866:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0100869:	89 df                	mov    %ebx,%edi
		while (iter->next != (struct run *)buddypos && iter->next != Buddy[id][count].free_list)
f010086b:	e9 3d ff ff ff       	jmp    f01007ad <Buddykfree+0xf8>
f0100870:	8b 75 e4             	mov    -0x1c(%ebp),%esi
	}
	r = (struct run *)v;
	r->next = Buddy[id][count].free_list->next;
f0100873:	8b 04 bd 54 39 11 f0 	mov    -0xfeec6ac(,%edi,4),%eax
f010087a:	8b 04 f0             	mov    (%eax,%esi,8),%eax
f010087d:	8b 00                	mov    (%eax),%eax
f010087f:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0100882:	89 03                	mov    %eax,(%ebx)
	Buddy[id][count].free_list->next = r;
f0100884:	8b 04 bd 54 39 11 f0 	mov    -0xfeec6ac(,%edi,4),%eax
f010088b:	8b 04 f0             	mov    (%eax,%esi,8),%eax
f010088e:	89 18                	mov    %ebx,(%eax)
	Buddy[id][count].num++;
f0100890:	8b 04 bd 54 39 11 f0 	mov    -0xfeec6ac(,%edi,4),%eax
f0100897:	83 44 f0 04 01       	addl   $0x1,0x4(%eax,%esi,8)
}
f010089c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010089f:	5b                   	pop    %ebx
f01008a0:	5e                   	pop    %esi
f01008a1:	5f                   	pop    %edi
f01008a2:	5d                   	pop    %ebp
f01008a3:	c3                   	ret    

f01008a4 <kfree>:
{
f01008a4:	55                   	push   %ebp
f01008a5:	89 e5                	mov    %esp,%ebp
f01008a7:	83 ec 14             	sub    $0x14,%esp
	Buddykfree(v);
f01008aa:	ff 75 08             	pushl  0x8(%ebp)
f01008ad:	e8 03 fe ff ff       	call   f01006b5 <Buddykfree>
}
f01008b2:	83 c4 10             	add    $0x10,%esp
f01008b5:	c9                   	leave  
f01008b6:	c3                   	ret    

f01008b7 <free_range>:

void
free_range(void *vstart, void *vend)
{
f01008b7:	55                   	push   %ebp
f01008b8:	89 e5                	mov    %esp,%ebp
f01008ba:	56                   	push   %esi
f01008bb:	53                   	push   %ebx
f01008bc:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *p;
	p = ROUNDUP((char *)vstart, PGSIZE);
f01008bf:	8b 45 08             	mov    0x8(%ebp),%eax
f01008c2:	05 ff 0f 00 00       	add    $0xfff,%eax
f01008c7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	for (; p + PGSIZE <= (char *)vend; p += PGSIZE)
f01008cc:	eb 0e                	jmp    f01008dc <free_range+0x25>
	Buddykfree(v);
f01008ce:	83 ec 0c             	sub    $0xc,%esp
f01008d1:	50                   	push   %eax
f01008d2:	e8 de fd ff ff       	call   f01006b5 <Buddykfree>
	for (; p + PGSIZE <= (char *)vend; p += PGSIZE)
f01008d7:	83 c4 10             	add    $0x10,%esp
f01008da:	89 f0                	mov    %esi,%eax
f01008dc:	8d b0 00 10 00 00    	lea    0x1000(%eax),%esi
f01008e2:	39 de                	cmp    %ebx,%esi
f01008e4:	76 e8                	jbe    f01008ce <free_range+0x17>
		kfree(p);
}
f01008e6:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01008e9:	5b                   	pop    %ebx
f01008ea:	5e                   	pop    %esi
f01008eb:	5d                   	pop    %ebp
f01008ec:	c3                   	ret    

f01008ed <Buddyfree_range>:

void
Buddyfree_range(void *vstart, int level)
{
f01008ed:	55                   	push   %ebp
f01008ee:	89 e5                	mov    %esp,%ebp
f01008f0:	57                   	push   %edi
f01008f1:	56                   	push   %esi
f01008f2:	53                   	push   %ebx
f01008f3:	83 ec 0c             	sub    $0xc,%esp
f01008f6:	8b 75 08             	mov    0x8(%ebp),%esi
f01008f9:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	struct run *r;
	int id = ((void *)vstart >= (void *)base[1]) ? 1 : 0;
f01008fc:	39 35 4c 39 11 f0    	cmp    %esi,0xf011394c
f0100902:	0f 96 c0             	setbe  %al
f0100905:	0f b6 c0             	movzbl %al,%eax
f0100908:	89 c7                	mov    %eax,%edi

	memset(vstart, 1, PGSIZE * pow_2(level));
f010090a:	53                   	push   %ebx
f010090b:	e8 88 fd ff ff       	call   f0100698 <pow_2>
f0100910:	c1 e0 0c             	shl    $0xc,%eax
f0100913:	50                   	push   %eax
f0100914:	6a 01                	push   $0x1
f0100916:	56                   	push   %esi
f0100917:	e8 85 10 00 00       	call   f01019a1 <memset>
	r = (struct run *)vstart;
	//cprintf("%x, %x\n", Buddy[id][level].free_list->next, Buddy[id][level].free_list);
	r->next = Buddy[id][level].free_list->next;
f010091c:	8b 04 bd 54 39 11 f0 	mov    -0xfeec6ac(,%edi,4),%eax
f0100923:	8b 04 d8             	mov    (%eax,%ebx,8),%eax
f0100926:	8b 00                	mov    (%eax),%eax
f0100928:	89 06                	mov    %eax,(%esi)
	Buddy[id][level].free_list->next = r;
f010092a:	8b 04 bd 54 39 11 f0 	mov    -0xfeec6ac(,%edi,4),%eax
f0100931:	8b 04 d8             	mov    (%eax,%ebx,8),%eax
f0100934:	89 30                	mov    %esi,(%eax)
	//cprintf("%x, %x\n", Buddy[id][level].free_list->next, Buddy[id][level].free_list);
	Buddy[id][level].num++;
f0100936:	8b 04 bd 54 39 11 f0 	mov    -0xfeec6ac(,%edi,4),%eax
f010093d:	83 44 d8 04 01       	addl   $0x1,0x4(%eax,%ebx,8)
}
f0100942:	83 c4 10             	add    $0x10,%esp
f0100945:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100948:	5b                   	pop    %ebx
f0100949:	5e                   	pop    %esi
f010094a:	5f                   	pop    %edi
f010094b:	5d                   	pop    %ebp
f010094c:	c3                   	ret    

f010094d <split>:
		return NULL;*/
}

void
split(char *r, int low, int high)
{
f010094d:	55                   	push   %ebp
f010094e:	89 e5                	mov    %esp,%ebp
f0100950:	57                   	push   %edi
f0100951:	56                   	push   %esi
f0100952:	53                   	push   %ebx
f0100953:	83 ec 08             	sub    $0x8,%esp
f0100956:	8b 4d 10             	mov    0x10(%ebp),%ecx
	int size = 1 << high;
f0100959:	b8 01 00 00 00       	mov    $0x1,%eax
f010095e:	d3 e0                	shl    %cl,%eax
f0100960:	89 45 f0             	mov    %eax,-0x10(%ebp)
	int id, idx;
	if ((void *)r >= (void *)base[1]) {
f0100963:	a1 4c 39 11 f0       	mov    0xf011394c,%eax
f0100968:	3b 45 08             	cmp    0x8(%ebp),%eax
f010096b:	77 22                	ja     f010098f <split+0x42>
		idx = (uint32_t)((void *)r - (void *)base[1]) / PGSIZE;
f010096d:	8b 75 08             	mov    0x8(%ebp),%esi
f0100970:	29 c6                	sub    %eax,%esi
f0100972:	89 f0                	mov    %esi,%eax
f0100974:	c1 e8 0c             	shr    $0xc,%eax
f0100977:	89 45 ec             	mov    %eax,-0x14(%ebp)
		id = 1;
f010097a:	b8 01 00 00 00       	mov    $0x1,%eax
f010097f:	8d 34 8d 00 00 00 00 	lea    0x0(,%ecx,4),%esi
f0100986:	8d 14 cd f8 ff ff ff 	lea    -0x8(,%ecx,8),%edx
f010098d:	eb 6d                	jmp    f01009fc <split+0xaf>
	} else {
		idx = (uint32_t)((void *)r - (void *)base[0]) / PGSIZE;
f010098f:	8b 45 08             	mov    0x8(%ebp),%eax
f0100992:	2b 05 48 39 11 f0    	sub    0xf0113948,%eax
f0100998:	c1 e8 0c             	shr    $0xc,%eax
f010099b:	89 45 ec             	mov    %eax,-0x14(%ebp)
		id = 0;
f010099e:	b8 00 00 00 00       	mov    $0x0,%eax
f01009a3:	eb da                	jmp    f010097f <split+0x32>
	}
	//cprintf("%x\n", r);
	while (high > low) {
		//cprintf("pos: %x, high: %d\n", start[id][high] + (idx >> high), high);
		order[id][start[id][high] + (idx >> high)] = 1;
f01009a5:	8b 3c 85 6c 39 11 f0 	mov    -0xfeec694(,%eax,4),%edi
f01009ac:	8b 5d ec             	mov    -0x14(%ebp),%ebx
f01009af:	d3 fb                	sar    %cl,%ebx
f01009b1:	03 1c 85 64 39 11 f0 	add    -0xfeec69c(,%eax,4),%ebx
f01009b8:	03 1c 37             	add    (%edi,%esi,1),%ebx
f01009bb:	c6 03 01             	movb   $0x1,(%ebx)
		//cprintf("high: %x, pos: %x\n", high, start[high] + (idx >> high));
		high--;
f01009be:	83 e9 01             	sub    $0x1,%ecx
		size >>= 1;
f01009c1:	d1 7d f0             	sarl   -0x10(%ebp)
f01009c4:	8b 7d f0             	mov    -0x10(%ebp),%edi
		struct run *p = (struct run *)((uint32_t)r + PGSIZE * size);
f01009c7:	89 fb                	mov    %edi,%ebx
f01009c9:	c1 e3 0c             	shl    $0xc,%ebx
f01009cc:	03 5d 08             	add    0x8(%ebp),%ebx
		//add high
		p->next = Buddy[id][high].free_list->next;
f01009cf:	8b 3c 85 54 39 11 f0 	mov    -0xfeec6ac(,%eax,4),%edi
f01009d6:	8b 3c 17             	mov    (%edi,%edx,1),%edi
f01009d9:	8b 3f                	mov    (%edi),%edi
f01009db:	89 3b                	mov    %edi,(%ebx)
		Buddy[id][high].free_list->next = p;
f01009dd:	8b 3c 85 54 39 11 f0 	mov    -0xfeec6ac(,%eax,4),%edi
f01009e4:	8b 3c 17             	mov    (%edi,%edx,1),%edi
f01009e7:	89 1f                	mov    %ebx,(%edi)
		Buddy[id][high].num++;
f01009e9:	89 d3                	mov    %edx,%ebx
f01009eb:	03 1c 85 54 39 11 f0 	add    -0xfeec6ac(,%eax,4),%ebx
f01009f2:	83 43 04 01          	addl   $0x1,0x4(%ebx)
f01009f6:	83 ee 04             	sub    $0x4,%esi
f01009f9:	83 ea 08             	sub    $0x8,%edx
	while (high > low) {
f01009fc:	3b 4d 0c             	cmp    0xc(%ebp),%ecx
f01009ff:	7f a4                	jg     f01009a5 <split+0x58>
	}
	order[id][start[id][high] + (idx >> high)] = 1;
f0100a01:	8b 14 85 6c 39 11 f0 	mov    -0xfeec694(,%eax,4),%edx
f0100a08:	8b 5d ec             	mov    -0x14(%ebp),%ebx
f0100a0b:	d3 fb                	sar    %cl,%ebx
f0100a0d:	03 1c 85 64 39 11 f0 	add    -0xfeec69c(,%eax,4),%ebx
f0100a14:	89 d8                	mov    %ebx,%eax
f0100a16:	03 04 8a             	add    (%edx,%ecx,4),%eax
f0100a19:	c6 00 01             	movb   $0x1,(%eax)
	//cprintf("pos: %x\n", start[id][high] + (idx >> high));
}
f0100a1c:	83 c4 08             	add    $0x8,%esp
f0100a1f:	5b                   	pop    %ebx
f0100a20:	5e                   	pop    %esi
f0100a21:	5f                   	pop    %edi
f0100a22:	5d                   	pop    %ebp
f0100a23:	c3                   	ret    

f0100a24 <Buddykalloc>:

char *
Buddykalloc(int order)
{
f0100a24:	55                   	push   %ebp
f0100a25:	89 e5                	mov    %esp,%ebp
f0100a27:	57                   	push   %edi
f0100a28:	56                   	push   %esi
f0100a29:	53                   	push   %ebx
f0100a2a:	83 ec 04             	sub    $0x4,%esp
f0100a2d:	8b 75 08             	mov    0x8(%ebp),%esi
	for (int i = 0; i < 2; i++)
		for (int currentorder = order; currentorder <= MAX_ORDER[i]; currentorder++)
f0100a30:	89 f0                	mov    %esi,%eax
	for (int i = 0; i < 2; i++)
f0100a32:	ba 00 00 00 00       	mov    $0x0,%edx
		for (int currentorder = order; currentorder <= MAX_ORDER[i]; currentorder++)
f0100a37:	39 04 95 74 39 11 f0 	cmp    %eax,-0xfeec68c(,%edx,4)
f0100a3e:	7c 45                	jl     f0100a85 <Buddykalloc+0x61>
			if (Buddy[i][currentorder].num > 0) {
f0100a40:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
f0100a47:	89 cb                	mov    %ecx,%ebx
f0100a49:	03 1c 95 54 39 11 f0 	add    -0xfeec6ac(,%edx,4),%ebx
f0100a50:	83 7b 04 00          	cmpl   $0x0,0x4(%ebx)
f0100a54:	7f 05                	jg     f0100a5b <Buddykalloc+0x37>
		for (int currentorder = order; currentorder <= MAX_ORDER[i]; currentorder++)
f0100a56:	83 c0 01             	add    $0x1,%eax
f0100a59:	eb dc                	jmp    f0100a37 <Buddykalloc+0x13>
f0100a5b:	89 4d f0             	mov    %ecx,-0x10(%ebp)
				struct run *r;
				r = Buddy[i][currentorder].free_list->next;
f0100a5e:	8b 3b                	mov    (%ebx),%edi
f0100a60:	8b 1f                	mov    (%edi),%ebx
				Buddy[i][currentorder].free_list->next = r->next;
f0100a62:	8b 0b                	mov    (%ebx),%ecx
f0100a64:	89 0f                	mov    %ecx,(%edi)
				Buddy[i][currentorder].num--;
f0100a66:	8b 4d f0             	mov    -0x10(%ebp),%ecx
f0100a69:	03 0c 95 54 39 11 f0 	add    -0xfeec6ac(,%edx,4),%ecx
f0100a70:	83 69 04 01          	subl   $0x1,0x4(%ecx)
				//cprintf("%d\n", currentorder);
				split((char *)r, order, currentorder);
f0100a74:	50                   	push   %eax
f0100a75:	56                   	push   %esi
f0100a76:	53                   	push   %ebx
f0100a77:	e8 d1 fe ff ff       	call   f010094d <split>
				return (char *)r;
f0100a7c:	83 c4 0c             	add    $0xc,%esp
f0100a7f:	eb 11                	jmp    f0100a92 <Buddykalloc+0x6e>
		for (int currentorder = order; currentorder <= MAX_ORDER[i]; currentorder++)
f0100a81:	89 f0                	mov    %esi,%eax
f0100a83:	eb b2                	jmp    f0100a37 <Buddykalloc+0x13>
	for (int i = 0; i < 2; i++)
f0100a85:	83 c2 01             	add    $0x1,%edx
f0100a88:	83 fa 01             	cmp    $0x1,%edx
f0100a8b:	7e f4                	jle    f0100a81 <Buddykalloc+0x5d>
			} 
	return NULL;
f0100a8d:	bb 00 00 00 00       	mov    $0x0,%ebx
}
f0100a92:	89 d8                	mov    %ebx,%eax
f0100a94:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a97:	5b                   	pop    %ebx
f0100a98:	5e                   	pop    %esi
f0100a99:	5f                   	pop    %edi
f0100a9a:	5d                   	pop    %ebp
f0100a9b:	c3                   	ret    

f0100a9c <kalloc>:
{
f0100a9c:	55                   	push   %ebp
f0100a9d:	89 e5                	mov    %esp,%ebp
	return Buddykalloc(0);
f0100a9f:	6a 00                	push   $0x0
f0100aa1:	e8 7e ff ff ff       	call   f0100a24 <Buddykalloc>
}
f0100aa6:	c9                   	leave  
f0100aa7:	c3                   	ret    

f0100aa8 <check_free_list>:
void
check_free_list(void)
{
	struct run *p;
	bool exist;
	for (int i = 0; i < 2; i++)
f0100aa8:	ba 00 00 00 00       	mov    $0x0,%edx
		for (int j = 0; j <= MAX_ORDER[i]; j++)
f0100aad:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ab2:	eb 03                	jmp    f0100ab7 <check_free_list+0xf>
f0100ab4:	83 c0 01             	add    $0x1,%eax
f0100ab7:	39 04 95 74 39 11 f0 	cmp    %eax,-0xfeec68c(,%edx,4)
f0100abe:	7d f4                	jge    f0100ab4 <check_free_list+0xc>
	for (int i = 0; i < 2; i++)
f0100ac0:	83 c2 01             	add    $0x1,%edx
f0100ac3:	83 fa 01             	cmp    $0x1,%edx
f0100ac6:	7f 39                	jg     f0100b01 <check_free_list+0x59>
		for (int j = 0; j <= MAX_ORDER[i]; j++)
f0100ac8:	b8 00 00 00 00       	mov    $0x0,%eax
f0100acd:	eb e8                	jmp    f0100ab7 <check_free_list+0xf>

	//cprintf("end: 0x%x\n", end);

	for (p = kmem.free_list; p; p = p->next) {
		//cprintf("0x%x\n", p);
		assert((void *)p > (void *)end);
f0100acf:	68 b4 20 10 f0       	push   $0xf01020b4
f0100ad4:	68 cc 20 10 f0       	push   $0xf01020cc
f0100ad9:	68 7b 01 00 00       	push   $0x17b
f0100ade:	68 a6 20 10 f0       	push   $0xf01020a6
f0100ae3:	e8 b2 f5 ff ff       	call   f010009a <_panic>
		for (int i = 4; i < 4096; i++) 
			assert(((char *)p)[i] == 1);
f0100ae8:	68 e1 20 10 f0       	push   $0xf01020e1
f0100aed:	68 cc 20 10 f0       	push   $0xf01020cc
f0100af2:	68 7d 01 00 00       	push   $0x17d
f0100af7:	68 a6 20 10 f0       	push   $0xf01020a6
f0100afc:	e8 99 f5 ff ff       	call   f010009a <_panic>
	for (p = kmem.free_list; p; p = p->next) {
f0100b01:	8b 0d 50 39 11 f0    	mov    0xf0113950,%ecx
f0100b07:	85 c9                	test   %ecx,%ecx
f0100b09:	74 2b                	je     f0100b36 <check_free_list+0x8e>
{
f0100b0b:	55                   	push   %ebp
f0100b0c:	89 e5                	mov    %esp,%ebp
f0100b0e:	83 ec 08             	sub    $0x8,%esp
		assert((void *)p > (void *)end);
f0100b11:	81 f9 80 39 11 f0    	cmp    $0xf0113980,%ecx
f0100b17:	76 b6                	jbe    f0100acf <check_free_list+0x27>
f0100b19:	8d 41 04             	lea    0x4(%ecx),%eax
f0100b1c:	8d 91 00 10 00 00    	lea    0x1000(%ecx),%edx
			assert(((char *)p)[i] == 1);
f0100b22:	80 38 01             	cmpb   $0x1,(%eax)
f0100b25:	75 c1                	jne    f0100ae8 <check_free_list+0x40>
f0100b27:	83 c0 01             	add    $0x1,%eax
		for (int i = 4; i < 4096; i++) 
f0100b2a:	39 d0                	cmp    %edx,%eax
f0100b2c:	75 f4                	jne    f0100b22 <check_free_list+0x7a>
	for (p = kmem.free_list; p; p = p->next) {
f0100b2e:	8b 09                	mov    (%ecx),%ecx
f0100b30:	85 c9                	test   %ecx,%ecx
f0100b32:	75 dd                	jne    f0100b11 <check_free_list+0x69>
	}
}
f0100b34:	c9                   	leave  
f0100b35:	c3                   	ret    
f0100b36:	c3                   	ret    

f0100b37 <boot_alloc_init>:
{
f0100b37:	55                   	push   %ebp
f0100b38:	89 e5                	mov    %esp,%ebp
f0100b3a:	57                   	push   %edi
f0100b3b:	56                   	push   %esi
f0100b3c:	53                   	push   %ebx
f0100b3d:	83 ec 2c             	sub    $0x2c,%esp
			num = (uint32_t)((char *)P2V(4*1024*1024) - end) / PGSIZE;
f0100b40:	b8 00 00 40 f0       	mov    $0xf0400000,%eax
f0100b45:	2d 80 39 11 f0       	sub    $0xf0113980,%eax
	char *mystart = end;
f0100b4a:	bf 80 39 11 f0       	mov    $0xf0113980,%edi
			num = (uint32_t)((char *)P2V(4*1024*1024) - end) / PGSIZE;
f0100b4f:	c1 e8 0c             	shr    $0xc,%eax
f0100b52:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100b55:	c7 45 d0 5c 39 11 f0 	movl   $0xf011395c,-0x30(%ebp)
f0100b5c:	8b 55 cc             	mov    -0x34(%ebp),%edx
f0100b5f:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f0100b66:	89 fe                	mov    %edi,%esi
f0100b68:	e9 24 01 00 00       	jmp    f0100c91 <boot_alloc_init+0x15a>
f0100b6d:	89 f7                	mov    %esi,%edi
f0100b6f:	eb e4                	jmp    f0100b55 <boot_alloc_init+0x1e>
			sum *= 2;
f0100b71:	01 c0                	add    %eax,%eax
			level++;
f0100b73:	83 c7 01             	add    $0x1,%edi
		while (sum < num) {
f0100b76:	39 c2                	cmp    %eax,%edx
f0100b78:	7f f7                	jg     f0100b71 <boot_alloc_init+0x3a>
			level--;
f0100b7a:	0f 9c c0             	setl   %al
f0100b7d:	0f b6 c0             	movzbl %al,%eax
f0100b80:	29 c7                	sub    %eax,%edi
f0100b82:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100b85:	89 45 e0             	mov    %eax,-0x20(%ebp)
		order[i] = (bool *)mystart;
f0100b88:	89 34 85 64 39 11 f0 	mov    %esi,-0xfeec69c(,%eax,4)
		memset(order[i], 0, pow_2(level) * 2);
f0100b8f:	57                   	push   %edi
f0100b90:	e8 03 fb ff ff       	call   f0100698 <pow_2>
f0100b95:	8d 1c 00             	lea    (%eax,%eax,1),%ebx
f0100b98:	53                   	push   %ebx
f0100b99:	6a 00                	push   $0x0
f0100b9b:	56                   	push   %esi
f0100b9c:	e8 00 0e 00 00       	call   f01019a1 <memset>
		mystart += pow_2(level) * 2;
f0100ba1:	01 f3                	add    %esi,%ebx
		MAX_ORDER[i] = level;
f0100ba3:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100ba6:	89 3c 8d 74 39 11 f0 	mov    %edi,-0xfeec68c(,%ecx,4)
		Buddy[i] = (struct Buddykmem *)mystart;
f0100bad:	89 1c 8d 54 39 11 f0 	mov    %ebx,-0xfeec6ac(,%ecx,4)
		memset(Buddy[i], 0, sizeof(struct Buddykmem) * (level + 1));
f0100bb4:	8d 57 01             	lea    0x1(%edi),%edx
f0100bb7:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100bba:	8d 34 d5 00 00 00 00 	lea    0x0(,%edx,8),%esi
f0100bc1:	83 c4 0c             	add    $0xc,%esp
f0100bc4:	56                   	push   %esi
f0100bc5:	6a 00                	push   $0x0
f0100bc7:	53                   	push   %ebx
f0100bc8:	e8 d4 0d 00 00       	call   f01019a1 <memset>
		mystart += sizeof(struct Buddykmem) * (level + 1);
f0100bcd:	01 de                	add    %ebx,%esi
f0100bcf:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0100bd2:	89 cb                	mov    %ecx,%ebx
		linkbase[i] = (struct run *)mystart;
f0100bd4:	89 31                	mov    %esi,(%ecx)
		memset(linkbase[i], 0, sizeof(struct run) *(level + 1));
f0100bd6:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100bd9:	c1 e2 02             	shl    $0x2,%edx
f0100bdc:	83 c4 0c             	add    $0xc,%esp
f0100bdf:	89 55 d8             	mov    %edx,-0x28(%ebp)
f0100be2:	52                   	push   %edx
f0100be3:	6a 00                	push   $0x0
f0100be5:	56                   	push   %esi
f0100be6:	e8 b6 0d 00 00       	call   f01019a1 <memset>
		mystart += sizeof(struct run) *(level + 1);
f0100beb:	03 75 d8             	add    -0x28(%ebp),%esi
f0100bee:	89 75 d4             	mov    %esi,-0x2c(%ebp)
		for (int j = 0; j <= level; j++) {
f0100bf1:	83 c4 10             	add    $0x10,%esp
f0100bf4:	b8 00 00 00 00       	mov    $0x0,%eax
f0100bf9:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100bfc:	eb 1c                	jmp    f0100c1a <boot_alloc_init+0xe3>
f0100bfe:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
			linkbase[i][j].next = &linkbase[i][j];
f0100c05:	89 d1                	mov    %edx,%ecx
f0100c07:	03 0b                	add    (%ebx),%ecx
f0100c09:	89 09                	mov    %ecx,(%ecx)
			Buddy[i][j].free_list = &linkbase[i][j];
f0100c0b:	8b 0c b5 54 39 11 f0 	mov    -0xfeec6ac(,%esi,4),%ecx
f0100c12:	03 13                	add    (%ebx),%edx
f0100c14:	89 14 c1             	mov    %edx,(%ecx,%eax,8)
		for (int j = 0; j <= level; j++) {
f0100c17:	83 c0 01             	add    $0x1,%eax
f0100c1a:	39 c7                	cmp    %eax,%edi
f0100c1c:	7d e0                	jge    f0100bfe <boot_alloc_init+0xc7>
		start[i] = (int *)mystart;
f0100c1e:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100c21:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100c24:	89 04 b5 6c 39 11 f0 	mov    %eax,-0xfeec694(,%esi,4)
		start[i][0] = 0;
f0100c2b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		for (int j = 0; j < level; j++)
f0100c31:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100c36:	89 7d e4             	mov    %edi,-0x1c(%ebp)
f0100c39:	eb 2c                	jmp    f0100c67 <boot_alloc_init+0x130>
			start[i][j + 1] = start[i][j] + pow_2(level - j);
f0100c3b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c3e:	8b 34 85 6c 39 11 f0 	mov    -0xfeec694(,%eax,4),%esi
f0100c45:	8d 3c 9d 00 00 00 00 	lea    0x0(,%ebx,4),%edi
f0100c4c:	83 ec 0c             	sub    $0xc,%esp
f0100c4f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c52:	29 d8                	sub    %ebx,%eax
f0100c54:	50                   	push   %eax
f0100c55:	e8 3e fa ff ff       	call   f0100698 <pow_2>
f0100c5a:	83 c4 10             	add    $0x10,%esp
f0100c5d:	03 04 9e             	add    (%esi,%ebx,4),%eax
f0100c60:	89 44 3e 04          	mov    %eax,0x4(%esi,%edi,1)
		for (int j = 0; j < level; j++)
f0100c64:	83 c3 01             	add    $0x1,%ebx
f0100c67:	39 5d e4             	cmp    %ebx,-0x1c(%ebp)
f0100c6a:	7f cf                	jg     f0100c3b <boot_alloc_init+0x104>
		mystart += sizeof(int) * (level + 1);
f0100c6c:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0100c6f:	03 75 d8             	add    -0x28(%ebp),%esi
	for (int i = 0; i < 2; i++) {
f0100c72:	83 45 dc 01          	addl   $0x1,-0x24(%ebp)
f0100c76:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100c79:	83 f8 01             	cmp    $0x1,%eax
f0100c7c:	7f 22                	jg     f0100ca0 <boot_alloc_init+0x169>
f0100c7e:	83 45 d0 04          	addl   $0x4,-0x30(%ebp)
			num = (uint32_t)((char *)PHYSTOP - 4*1024*1024) / PGSIZE;
f0100c82:	ba 00 dc 00 00       	mov    $0xdc00,%edx
		if (i == 0)
f0100c87:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0100c8b:	0f 84 dc fe ff ff    	je     f0100b6d <boot_alloc_init+0x36>
		int sum = 1;
f0100c91:	b8 01 00 00 00       	mov    $0x1,%eax
		int level = 0;
f0100c96:	bf 00 00 00 00       	mov    $0x0,%edi
		while (sum < num) {
f0100c9b:	e9 d6 fe ff ff       	jmp    f0100b76 <boot_alloc_init+0x3f>
f0100ca0:	89 f7                	mov    %esi,%edi
	base[0] = (struct run *)ROUNDUP(mystart, PGSIZE);
f0100ca2:	81 c7 ff 0f 00 00    	add    $0xfff,%edi
f0100ca8:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
f0100cae:	89 3d 48 39 11 f0    	mov    %edi,0xf0113948
	base[1] = (struct run *)P2V(4 * 1024 * 1024);
f0100cb4:	c7 05 4c 39 11 f0 00 	movl   $0xf0400000,0xf011394c
f0100cbb:	00 40 f0 
	Buddyfree_range((void *)base[0], MAX_ORDER[0]);
f0100cbe:	83 ec 08             	sub    $0x8,%esp
f0100cc1:	ff 35 74 39 11 f0    	pushl  0xf0113974
f0100cc7:	57                   	push   %edi
f0100cc8:	e8 20 fc ff ff       	call   f01008ed <Buddyfree_range>
	for (int i = 0; i <= MAX_ORDER[0]; i++)
f0100ccd:	83 c4 10             	add    $0x10,%esp
f0100cd0:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100cd5:	eb 1e                	jmp    f0100cf5 <boot_alloc_init+0x1be>
		cprintf("Buddy[%d]: %x\n", i, Buddy[0][i].free_list->next);
f0100cd7:	83 ec 04             	sub    $0x4,%esp
f0100cda:	a1 54 39 11 f0       	mov    0xf0113954,%eax
f0100cdf:	8b 04 d8             	mov    (%eax,%ebx,8),%eax
f0100ce2:	ff 30                	pushl  (%eax)
f0100ce4:	53                   	push   %ebx
f0100ce5:	68 f5 20 10 f0       	push   $0xf01020f5
f0100cea:	e8 95 f9 ff ff       	call   f0100684 <cprintf>
	for (int i = 0; i <= MAX_ORDER[0]; i++)
f0100cef:	83 c3 01             	add    $0x1,%ebx
f0100cf2:	83 c4 10             	add    $0x10,%esp
f0100cf5:	39 1d 74 39 11 f0    	cmp    %ebx,0xf0113974
f0100cfb:	7d da                	jge    f0100cd7 <boot_alloc_init+0x1a0>
	cprintf("After allocate a block of order 3.\n");
f0100cfd:	83 ec 0c             	sub    $0xc,%esp
f0100d00:	68 1c 21 10 f0       	push   $0xf010211c
f0100d05:	e8 7a f9 ff ff       	call   f0100684 <cprintf>
	char *p = Buddykalloc(3);
f0100d0a:	c7 04 24 03 00 00 00 	movl   $0x3,(%esp)
f0100d11:	e8 0e fd ff ff       	call   f0100a24 <Buddykalloc>
f0100d16:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for (int i = 0; i <= MAX_ORDER[0]; i++)
f0100d19:	83 c4 10             	add    $0x10,%esp
f0100d1c:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100d21:	eb 1e                	jmp    f0100d41 <boot_alloc_init+0x20a>
		cprintf("Buddy[%d]: %x\n", i, Buddy[0][i].free_list->next);
f0100d23:	83 ec 04             	sub    $0x4,%esp
f0100d26:	a1 54 39 11 f0       	mov    0xf0113954,%eax
f0100d2b:	8b 04 d8             	mov    (%eax,%ebx,8),%eax
f0100d2e:	ff 30                	pushl  (%eax)
f0100d30:	53                   	push   %ebx
f0100d31:	68 f5 20 10 f0       	push   $0xf01020f5
f0100d36:	e8 49 f9 ff ff       	call   f0100684 <cprintf>
	for (int i = 0; i <= MAX_ORDER[0]; i++)
f0100d3b:	83 c3 01             	add    $0x1,%ebx
f0100d3e:	83 c4 10             	add    $0x10,%esp
f0100d41:	39 1d 74 39 11 f0    	cmp    %ebx,0xf0113974
f0100d47:	7d da                	jge    f0100d23 <boot_alloc_init+0x1ec>
	cprintf("After allocate a block of order 0.\n");
f0100d49:	83 ec 0c             	sub    $0xc,%esp
f0100d4c:	68 40 21 10 f0       	push   $0xf0102140
f0100d51:	e8 2e f9 ff ff       	call   f0100684 <cprintf>
	char *q = Buddykalloc(0);
f0100d56:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100d5d:	e8 c2 fc ff ff       	call   f0100a24 <Buddykalloc>
f0100d62:	89 c7                	mov    %eax,%edi
	for (int i = 0; i <= MAX_ORDER[0]; i++)
f0100d64:	83 c4 10             	add    $0x10,%esp
f0100d67:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100d6c:	eb 1e                	jmp    f0100d8c <boot_alloc_init+0x255>
		cprintf("Buddy[%d]: %x\n", i, Buddy[0][i].free_list->next);
f0100d6e:	83 ec 04             	sub    $0x4,%esp
f0100d71:	a1 54 39 11 f0       	mov    0xf0113954,%eax
f0100d76:	8b 04 d8             	mov    (%eax,%ebx,8),%eax
f0100d79:	ff 30                	pushl  (%eax)
f0100d7b:	53                   	push   %ebx
f0100d7c:	68 f5 20 10 f0       	push   $0xf01020f5
f0100d81:	e8 fe f8 ff ff       	call   f0100684 <cprintf>
	for (int i = 0; i <= MAX_ORDER[0]; i++)
f0100d86:	83 c3 01             	add    $0x1,%ebx
f0100d89:	83 c4 10             	add    $0x10,%esp
f0100d8c:	39 1d 74 39 11 f0    	cmp    %ebx,0xf0113974
f0100d92:	7d da                	jge    f0100d6e <boot_alloc_init+0x237>
	cprintf("After allocate a block of order 8.\n");
f0100d94:	83 ec 0c             	sub    $0xc,%esp
f0100d97:	68 64 21 10 f0       	push   $0xf0102164
f0100d9c:	e8 e3 f8 ff ff       	call   f0100684 <cprintf>
	char *s = Buddykalloc(8);
f0100da1:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f0100da8:	e8 77 fc ff ff       	call   f0100a24 <Buddykalloc>
f0100dad:	89 c6                	mov    %eax,%esi
	for (int i = 0; i <= MAX_ORDER[0]; i++)
f0100daf:	83 c4 10             	add    $0x10,%esp
f0100db2:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100db7:	eb 1e                	jmp    f0100dd7 <boot_alloc_init+0x2a0>
		cprintf("Buddy[%d]: %x\n", i, Buddy[0][i].free_list->next);
f0100db9:	83 ec 04             	sub    $0x4,%esp
f0100dbc:	a1 54 39 11 f0       	mov    0xf0113954,%eax
f0100dc1:	8b 04 d8             	mov    (%eax,%ebx,8),%eax
f0100dc4:	ff 30                	pushl  (%eax)
f0100dc6:	53                   	push   %ebx
f0100dc7:	68 f5 20 10 f0       	push   $0xf01020f5
f0100dcc:	e8 b3 f8 ff ff       	call   f0100684 <cprintf>
	for (int i = 0; i <= MAX_ORDER[0]; i++)
f0100dd1:	83 c3 01             	add    $0x1,%ebx
f0100dd4:	83 c4 10             	add    $0x10,%esp
f0100dd7:	39 1d 74 39 11 f0    	cmp    %ebx,0xf0113974
f0100ddd:	7d da                	jge    f0100db9 <boot_alloc_init+0x282>
	cprintf("p: %x, q: %x, s: %x\n", p, q, s);
f0100ddf:	56                   	push   %esi
f0100de0:	57                   	push   %edi
f0100de1:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100de4:	68 04 21 10 f0       	push   $0xf0102104
f0100de9:	e8 96 f8 ff ff       	call   f0100684 <cprintf>
	cprintf("After reclaiming the block of order 0.\n");
f0100dee:	c7 04 24 88 21 10 f0 	movl   $0xf0102188,(%esp)
f0100df5:	e8 8a f8 ff ff       	call   f0100684 <cprintf>
	Buddykfree(v);
f0100dfa:	89 3c 24             	mov    %edi,(%esp)
f0100dfd:	e8 b3 f8 ff ff       	call   f01006b5 <Buddykfree>
f0100e02:	83 c4 10             	add    $0x10,%esp
	for (int i = 0; i <= MAX_ORDER[0]; i++)
f0100e05:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100e0a:	eb 1e                	jmp    f0100e2a <boot_alloc_init+0x2f3>
		cprintf("Buddy[%d]: %x\n", i, Buddy[0][i].free_list->next);
f0100e0c:	83 ec 04             	sub    $0x4,%esp
f0100e0f:	a1 54 39 11 f0       	mov    0xf0113954,%eax
f0100e14:	8b 04 d8             	mov    (%eax,%ebx,8),%eax
f0100e17:	ff 30                	pushl  (%eax)
f0100e19:	53                   	push   %ebx
f0100e1a:	68 f5 20 10 f0       	push   $0xf01020f5
f0100e1f:	e8 60 f8 ff ff       	call   f0100684 <cprintf>
	for (int i = 0; i <= MAX_ORDER[0]; i++)
f0100e24:	83 c3 01             	add    $0x1,%ebx
f0100e27:	83 c4 10             	add    $0x10,%esp
f0100e2a:	39 1d 74 39 11 f0    	cmp    %ebx,0xf0113974
f0100e30:	7d da                	jge    f0100e0c <boot_alloc_init+0x2d5>
	cprintf("After reclaiming the block of order 8.\n");
f0100e32:	83 ec 0c             	sub    $0xc,%esp
f0100e35:	68 b0 21 10 f0       	push   $0xf01021b0
f0100e3a:	e8 45 f8 ff ff       	call   f0100684 <cprintf>
	Buddykfree(v);
f0100e3f:	89 34 24             	mov    %esi,(%esp)
f0100e42:	e8 6e f8 ff ff       	call   f01006b5 <Buddykfree>
f0100e47:	83 c4 10             	add    $0x10,%esp
	for (int i = 0; i <= MAX_ORDER[0]; i++)
f0100e4a:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100e4f:	eb 1e                	jmp    f0100e6f <boot_alloc_init+0x338>
		cprintf("Buddy[%d]: %x\n", i, Buddy[0][i].free_list->next);
f0100e51:	83 ec 04             	sub    $0x4,%esp
f0100e54:	a1 54 39 11 f0       	mov    0xf0113954,%eax
f0100e59:	8b 04 d8             	mov    (%eax,%ebx,8),%eax
f0100e5c:	ff 30                	pushl  (%eax)
f0100e5e:	53                   	push   %ebx
f0100e5f:	68 f5 20 10 f0       	push   $0xf01020f5
f0100e64:	e8 1b f8 ff ff       	call   f0100684 <cprintf>
	for (int i = 0; i <= MAX_ORDER[0]; i++)
f0100e69:	83 c3 01             	add    $0x1,%ebx
f0100e6c:	83 c4 10             	add    $0x10,%esp
f0100e6f:	39 1d 74 39 11 f0    	cmp    %ebx,0xf0113974
f0100e75:	7d da                	jge    f0100e51 <boot_alloc_init+0x31a>
	cprintf("After reclaiming the block of order 3.\n");
f0100e77:	83 ec 0c             	sub    $0xc,%esp
f0100e7a:	68 d8 21 10 f0       	push   $0xf01021d8
f0100e7f:	e8 00 f8 ff ff       	call   f0100684 <cprintf>
	Buddykfree(v);
f0100e84:	83 c4 04             	add    $0x4,%esp
f0100e87:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100e8a:	e8 26 f8 ff ff       	call   f01006b5 <Buddykfree>
f0100e8f:	83 c4 10             	add    $0x10,%esp
	for (int i = 0; i <= MAX_ORDER[0]; i++)
f0100e92:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100e97:	eb 1e                	jmp    f0100eb7 <boot_alloc_init+0x380>
		cprintf("Buddy[%d]: %x\n", i, Buddy[0][i].free_list->next);
f0100e99:	83 ec 04             	sub    $0x4,%esp
f0100e9c:	a1 54 39 11 f0       	mov    0xf0113954,%eax
f0100ea1:	8b 04 d8             	mov    (%eax,%ebx,8),%eax
f0100ea4:	ff 30                	pushl  (%eax)
f0100ea6:	53                   	push   %ebx
f0100ea7:	68 f5 20 10 f0       	push   $0xf01020f5
f0100eac:	e8 d3 f7 ff ff       	call   f0100684 <cprintf>
	for (int i = 0; i <= MAX_ORDER[0]; i++)
f0100eb1:	83 c3 01             	add    $0x1,%ebx
f0100eb4:	83 c4 10             	add    $0x10,%esp
f0100eb7:	39 1d 74 39 11 f0    	cmp    %ebx,0xf0113974
f0100ebd:	7d da                	jge    f0100e99 <boot_alloc_init+0x362>
	check_free_list();
f0100ebf:	e8 e4 fb ff ff       	call   f0100aa8 <check_free_list>
}
f0100ec4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100ec7:	5b                   	pop    %ebx
f0100ec8:	5e                   	pop    %esi
f0100ec9:	5f                   	pop    %edi
f0100eca:	5d                   	pop    %ebp
f0100ecb:	c3                   	ret    

f0100ecc <alloc_init>:
{
f0100ecc:	55                   	push   %ebp
f0100ecd:	89 e5                	mov    %esp,%ebp
f0100ecf:	83 ec 10             	sub    $0x10,%esp
	Buddyfree_range((void *)base[1], MAX_ORDER[1]);
f0100ed2:	ff 35 78 39 11 f0    	pushl  0xf0113978
f0100ed8:	ff 35 4c 39 11 f0    	pushl  0xf011394c
f0100ede:	e8 0a fa ff ff       	call   f01008ed <Buddyfree_range>
	check_free_list();
f0100ee3:	e8 c0 fb ff ff       	call   f0100aa8 <check_free_list>
}
f0100ee8:	83 c4 10             	add    $0x10,%esp
f0100eeb:	c9                   	leave  
f0100eec:	c3                   	ret    

f0100eed <pgdir_walk>:
// Hint 2: look at inc/mmu.h for useful macros that manipulate page
// table and page directory entries.
//
static pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int32_t alloc)
{
f0100eed:	55                   	push   %ebp
f0100eee:	89 e5                	mov    %esp,%ebp
f0100ef0:	57                   	push   %edi
f0100ef1:	56                   	push   %esi
f0100ef2:	53                   	push   %ebx
f0100ef3:	83 ec 0c             	sub    $0xc,%esp
f0100ef6:	89 d6                	mov    %edx,%esi
	// TODO: Fill this function in
	pde_t *pde = &pgdir[PDX(va)];
f0100ef8:	c1 ea 16             	shr    $0x16,%edx
f0100efb:	8d 3c 90             	lea    (%eax,%edx,4),%edi
	pte_t *pgtab;
	if ((*pde & PTE_P) == 1)
f0100efe:	8b 1f                	mov    (%edi),%ebx
f0100f00:	f6 c3 01             	test   $0x1,%bl
f0100f03:	74 21                	je     f0100f26 <pgdir_walk+0x39>
	    pgtab = (pte_t *)P2V((*pde >> 12) << 12);
f0100f05:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
f0100f0b:	81 eb 00 00 00 10    	sub    $0x10000000,%ebx
	    if (alloc == 0 || (pgtab = (pte_t *)kalloc()) == NULL)
	        return NULL;
	    memset(pgtab, 0, PGSIZE);
        *pde = V2P(pgtab) | PTE_P | PTE_U | PTE_W;
	}
	return &pgtab[PTX(va)];
f0100f11:	c1 ee 0a             	shr    $0xa,%esi
f0100f14:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f0100f1a:	01 f3                	add    %esi,%ebx
}
f0100f1c:	89 d8                	mov    %ebx,%eax
f0100f1e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f21:	5b                   	pop    %ebx
f0100f22:	5e                   	pop    %esi
f0100f23:	5f                   	pop    %edi
f0100f24:	5d                   	pop    %ebp
f0100f25:	c3                   	ret    
	    if (alloc == 0 || (pgtab = (pte_t *)kalloc()) == NULL)
f0100f26:	85 c9                	test   %ecx,%ecx
f0100f28:	74 2b                	je     f0100f55 <pgdir_walk+0x68>
f0100f2a:	e8 6d fb ff ff       	call   f0100a9c <kalloc>
f0100f2f:	89 c3                	mov    %eax,%ebx
f0100f31:	85 c0                	test   %eax,%eax
f0100f33:	74 e7                	je     f0100f1c <pgdir_walk+0x2f>
	    memset(pgtab, 0, PGSIZE);
f0100f35:	83 ec 04             	sub    $0x4,%esp
f0100f38:	68 00 10 00 00       	push   $0x1000
f0100f3d:	6a 00                	push   $0x0
f0100f3f:	50                   	push   %eax
f0100f40:	e8 5c 0a 00 00       	call   f01019a1 <memset>
        *pde = V2P(pgtab) | PTE_P | PTE_U | PTE_W;
f0100f45:	8d 83 00 00 00 10    	lea    0x10000000(%ebx),%eax
f0100f4b:	83 c8 07             	or     $0x7,%eax
f0100f4e:	89 07                	mov    %eax,(%edi)
f0100f50:	83 c4 10             	add    $0x10,%esp
f0100f53:	eb bc                	jmp    f0100f11 <pgdir_walk+0x24>
	        return NULL;
f0100f55:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100f5a:	eb c0                	jmp    f0100f1c <pgdir_walk+0x2f>

f0100f5c <kvm_init>:
//			for each item of kmap[];
//
// Hint: You may need ARRAY_SIZE.
pde_t *
kvm_init(void)
{
f0100f5c:	55                   	push   %ebp
f0100f5d:	89 e5                	mov    %esp,%ebp
f0100f5f:	57                   	push   %edi
f0100f60:	56                   	push   %esi
f0100f61:	53                   	push   %ebx
f0100f62:	83 ec 1c             	sub    $0x1c,%esp
	// TODO: your code here
	pde_t *pgdirinit = (pde_t *)kalloc();
f0100f65:	e8 32 fb ff ff       	call   f0100a9c <kalloc>
f0100f6a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	if (pgdirinit) {
f0100f6d:	85 c0                	test   %eax,%eax
f0100f6f:	74 2f                	je     f0100fa0 <kvm_init+0x44>
	    memset(pgdirinit, 0, PGSIZE);
f0100f71:	83 ec 04             	sub    $0x4,%esp
f0100f74:	68 00 10 00 00       	push   $0x1000
f0100f79:	6a 00                	push   $0x0
f0100f7b:	50                   	push   %eax
f0100f7c:	e8 20 0a 00 00       	call   f01019a1 <memset>
f0100f81:	bf 60 22 10 f0       	mov    $0xf0102260,%edi
f0100f86:	83 c4 10             	add    $0x10,%esp
f0100f89:	eb 2e                	jmp    f0100fb9 <kvm_init+0x5d>
		for (int i = 0; i < ARRAY_SIZE(kmap); i++)
			if (map_region(pgdirinit, kmap[i].virt, kmap[i].phys_end - kmap[i].phys_start, kmap[i].phys_start, kmap[i].perm) < 0) {
                //cprintf("The %dth is wrong.\n", i);
				kfree((char *)pgdirinit);
f0100f8b:	83 ec 0c             	sub    $0xc,%esp
f0100f8e:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100f91:	e8 0e f9 ff ff       	call   f01008a4 <kfree>
                return 0;
f0100f96:	83 c4 10             	add    $0x10,%esp
f0100f99:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
			}
		return pgdirinit;
	} else
		return 0;
}
f0100fa0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100fa3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100fa6:	5b                   	pop    %ebx
f0100fa7:	5e                   	pop    %esi
f0100fa8:	5f                   	pop    %edi
f0100fa9:	5d                   	pop    %ebp
f0100faa:	c3                   	ret    
f0100fab:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0100fae:	83 c7 10             	add    $0x10,%edi
		for (int i = 0; i < ARRAY_SIZE(kmap); i++)
f0100fb1:	81 ff a0 22 10 f0    	cmp    $0xf01022a0,%edi
f0100fb7:	74 e7                	je     f0100fa0 <kvm_init+0x44>
			if (map_region(pgdirinit, kmap[i].virt, kmap[i].phys_end - kmap[i].phys_start, kmap[i].phys_start, kmap[i].perm) < 0) {
f0100fb9:	8b 57 04             	mov    0x4(%edi),%edx
	char *align = ROUNDUP(va, PGSIZE);
f0100fbc:	8b 07                	mov    (%edi),%eax
f0100fbe:	8d b0 ff 0f 00 00    	lea    0xfff(%eax),%esi
f0100fc4:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	uint32_t alignsize = ROUNDUP(size, PGSIZE);
f0100fca:	8b 47 08             	mov    0x8(%edi),%eax
f0100fcd:	05 ff 0f 00 00       	add    $0xfff,%eax
f0100fd2:	29 d0                	sub    %edx,%eax
f0100fd4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100fd9:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
f0100fdc:	89 d3                	mov    %edx,%ebx
f0100fde:	29 d6                	sub    %edx,%esi
		*pte = pa | perm | PTE_P;
f0100fe0:	8b 47 0c             	mov    0xc(%edi),%eax
f0100fe3:	83 c8 01             	or     $0x1,%eax
f0100fe6:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100fe9:	89 7d dc             	mov    %edi,-0x24(%ebp)
f0100fec:	89 cf                	mov    %ecx,%edi
f0100fee:	8d 14 1e             	lea    (%esi,%ebx,1),%edx
	while (alignsize) {
f0100ff1:	39 fb                	cmp    %edi,%ebx
f0100ff3:	74 b6                	je     f0100fab <kvm_init+0x4f>
		pte_t *pte = pgdir_walk(pgdir, align, 1);
f0100ff5:	b9 01 00 00 00       	mov    $0x1,%ecx
f0100ffa:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ffd:	e8 eb fe ff ff       	call   f0100eed <pgdir_walk>
		if (pte == NULL)
f0101002:	85 c0                	test   %eax,%eax
f0101004:	74 85                	je     f0100f8b <kvm_init+0x2f>
		*pte = pa | perm | PTE_P;
f0101006:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0101009:	09 da                	or     %ebx,%edx
f010100b:	89 10                	mov    %edx,(%eax)
		pa += PGSIZE;
f010100d:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0101013:	eb d9                	jmp    f0100fee <kvm_init+0x92>

f0101015 <kvm_switch>:

// Switch h/w page table register to the kernel-only page table.
void
kvm_switch(void)
{
f0101015:	55                   	push   %ebp
f0101016:	89 e5                	mov    %esp,%ebp
	lcr3(V2P(kpgdir)); // switch to the kernel page table
f0101018:	a1 7c 39 11 f0       	mov    0xf011397c,%eax
f010101d:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0101022:	0f 22 d8             	mov    %eax,%cr3
}
f0101025:	5d                   	pop    %ebp
f0101026:	c3                   	ret    

f0101027 <check_vm>:

void
check_vm(pde_t *pgdir)
{
f0101027:	55                   	push   %ebp
f0101028:	89 e5                	mov    %esp,%ebp
f010102a:	57                   	push   %edi
f010102b:	56                   	push   %esi
f010102c:	53                   	push   %ebx
f010102d:	83 ec 1c             	sub    $0x1c,%esp
f0101030:	c7 45 e4 60 22 10 f0 	movl   $0xf0102260,-0x1c(%ebp)
f0101037:	eb 3e                	jmp    f0101077 <check_vm+0x50>
		uint32_t alignsize = ROUNDUP(kmap[i].phys_end - kmap[i].phys_start, PGSIZE);
		uint32_t pa = kmap[i].phys_start;
		while(alignsize) {
			pte_t *pte = pgdir_walk(pgdir, align, 1);
			if (pte == NULL) 
				panic("vm_fail: Do not find the page table entry");
f0101039:	83 ec 04             	sub    $0x4,%esp
f010103c:	68 00 22 10 f0       	push   $0xf0102200
f0101041:	68 94 00 00 00       	push   $0x94
f0101046:	68 2c 22 10 f0       	push   $0xf010222c
f010104b:	e8 4a f0 ff ff       	call   f010009a <_panic>
			pte_t tmp = (*pte >> 12) << 12;
			assert(tmp == pa);
f0101050:	68 36 22 10 f0       	push   $0xf0102236
f0101055:	68 cc 20 10 f0       	push   $0xf01020cc
f010105a:	68 96 00 00 00       	push   $0x96
f010105f:	68 2c 22 10 f0       	push   $0xf010222c
f0101064:	e8 31 f0 ff ff       	call   f010009a <_panic>
f0101069:	83 45 e4 10          	addl   $0x10,-0x1c(%ebp)
f010106d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
	for (int i = 0; i < ARRAY_SIZE(kmap); i++) {
f0101070:	3d a0 22 10 f0       	cmp    $0xf01022a0,%eax
f0101075:	74 67                	je     f01010de <check_vm+0xb7>
		char *align = ROUNDUP(kmap[i].virt, PGSIZE);
f0101077:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010107a:	8b 08                	mov    (%eax),%ecx
f010107c:	89 cf                	mov    %ecx,%edi
f010107e:	81 c7 ff 0f 00 00    	add    $0xfff,%edi
f0101084:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
		uint32_t alignsize = ROUNDUP(kmap[i].phys_end - kmap[i].phys_start, PGSIZE);
f010108a:	89 c1                	mov    %eax,%ecx
f010108c:	8b 40 04             	mov    0x4(%eax),%eax
f010108f:	8b 49 08             	mov    0x8(%ecx),%ecx
f0101092:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0101095:	89 ce                	mov    %ecx,%esi
f0101097:	81 c6 ff 0f 00 00    	add    $0xfff,%esi
f010109d:	29 c6                	sub    %eax,%esi
f010109f:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
f01010a5:	01 c6                	add    %eax,%esi
		uint32_t pa = kmap[i].phys_start;
f01010a7:	89 c3                	mov    %eax,%ebx
f01010a9:	29 c7                	sub    %eax,%edi
f01010ab:	8d 14 1f             	lea    (%edi,%ebx,1),%edx
		while(alignsize) {
f01010ae:	39 de                	cmp    %ebx,%esi
f01010b0:	74 b7                	je     f0101069 <check_vm+0x42>
			pte_t *pte = pgdir_walk(pgdir, align, 1);
f01010b2:	b9 01 00 00 00       	mov    $0x1,%ecx
f01010b7:	8b 45 08             	mov    0x8(%ebp),%eax
f01010ba:	e8 2e fe ff ff       	call   f0100eed <pgdir_walk>
			if (pte == NULL) 
f01010bf:	85 c0                	test   %eax,%eax
f01010c1:	0f 84 72 ff ff ff    	je     f0101039 <check_vm+0x12>
			pte_t tmp = (*pte >> 12) << 12;
f01010c7:	8b 00                	mov    (%eax),%eax
f01010c9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
			assert(tmp == pa);
f01010ce:	39 c3                	cmp    %eax,%ebx
f01010d0:	0f 85 7a ff ff ff    	jne    f0101050 <check_vm+0x29>
			align += PGSIZE;
			pa += PGSIZE;
f01010d6:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01010dc:	eb cd                	jmp    f01010ab <check_vm+0x84>
			alignsize -= PGSIZE;
		}
	}
}
f01010de:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01010e1:	5b                   	pop    %ebx
f01010e2:	5e                   	pop    %esi
f01010e3:	5f                   	pop    %edi
f01010e4:	5d                   	pop    %ebp
f01010e5:	c3                   	ret    

f01010e6 <vm_init>:

// Allocate one page table for the machine for the kernel address
// space.
void
vm_init(void)
{
f01010e6:	55                   	push   %ebp
f01010e7:	89 e5                	mov    %esp,%ebp
f01010e9:	83 ec 08             	sub    $0x8,%esp
	kpgdir = kvm_init();
f01010ec:	e8 6b fe ff ff       	call   f0100f5c <kvm_init>
f01010f1:	a3 7c 39 11 f0       	mov    %eax,0xf011397c
	if (kpgdir == 0)
f01010f6:	85 c0                	test   %eax,%eax
f01010f8:	74 13                	je     f010110d <vm_init+0x27>
		panic("vm_init: failure");
	check_vm(kpgdir);
f01010fa:	83 ec 0c             	sub    $0xc,%esp
f01010fd:	50                   	push   %eax
f01010fe:	e8 24 ff ff ff       	call   f0101027 <check_vm>
	kvm_switch();
f0101103:	e8 0d ff ff ff       	call   f0101015 <kvm_switch>
}
f0101108:	83 c4 10             	add    $0x10,%esp
f010110b:	c9                   	leave  
f010110c:	c3                   	ret    
		panic("vm_init: failure");
f010110d:	83 ec 04             	sub    $0x4,%esp
f0101110:	68 40 22 10 f0       	push   $0xf0102240
f0101115:	68 a5 00 00 00       	push   $0xa5
f010111a:	68 2c 22 10 f0       	push   $0xf010222c
f010111f:	e8 76 ef ff ff       	call   f010009a <_panic>

f0101124 <vm_free>:
// Free a page table.
//
// Hint: You need to free all existing PTEs for this pgdir.
void
vm_free(pde_t *pgdir)
{
f0101124:	55                   	push   %ebp
f0101125:	89 e5                	mov    %esp,%ebp
f0101127:	57                   	push   %edi
f0101128:	56                   	push   %esi
f0101129:	53                   	push   %ebx
f010112a:	83 ec 0c             	sub    $0xc,%esp
f010112d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101130:	89 fb                	mov    %edi,%ebx
f0101132:	8d b7 00 10 00 00    	lea    0x1000(%edi),%esi
f0101138:	eb 07                	jmp    f0101141 <vm_free+0x1d>
f010113a:	83 c3 04             	add    $0x4,%ebx
	// TODO: your code here
	for (int i = 0; i < 1024; i++) {
f010113d:	39 f3                	cmp    %esi,%ebx
f010113f:	74 1e                	je     f010115f <vm_free+0x3b>
	    if (pgdir[i] & PTE_P) {
f0101141:	8b 03                	mov    (%ebx),%eax
f0101143:	a8 01                	test   $0x1,%al
f0101145:	74 f3                	je     f010113a <vm_free+0x16>
	        char *v = P2V((pgdir[i] >> 12) << 12);
	        kfree(v);
f0101147:	83 ec 0c             	sub    $0xc,%esp
	        char *v = P2V((pgdir[i] >> 12) << 12);
f010114a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010114f:	2d 00 00 00 10       	sub    $0x10000000,%eax
	        kfree(v);
f0101154:	50                   	push   %eax
f0101155:	e8 4a f7 ff ff       	call   f01008a4 <kfree>
f010115a:	83 c4 10             	add    $0x10,%esp
f010115d:	eb db                	jmp    f010113a <vm_free+0x16>
	    }
	}
	kfree((char *)pgdir);
f010115f:	83 ec 0c             	sub    $0xc,%esp
f0101162:	57                   	push   %edi
f0101163:	e8 3c f7 ff ff       	call   f01008a4 <kfree>
}
f0101168:	83 c4 10             	add    $0x10,%esp
f010116b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010116e:	5b                   	pop    %ebx
f010116f:	5e                   	pop    %esi
f0101170:	5f                   	pop    %edi
f0101171:	5d                   	pop    %ebp
f0101172:	c3                   	ret    

f0101173 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0101173:	55                   	push   %ebp
f0101174:	89 e5                	mov    %esp,%ebp
f0101176:	57                   	push   %edi
f0101177:	56                   	push   %esi
f0101178:	53                   	push   %ebx
f0101179:	83 ec 1c             	sub    $0x1c,%esp
f010117c:	89 c7                	mov    %eax,%edi
f010117e:	89 d6                	mov    %edx,%esi
f0101180:	8b 45 08             	mov    0x8(%ebp),%eax
f0101183:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101186:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101189:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f010118c:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010118f:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101194:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0101197:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f010119a:	39 d3                	cmp    %edx,%ebx
f010119c:	72 05                	jb     f01011a3 <printnum+0x30>
f010119e:	39 45 10             	cmp    %eax,0x10(%ebp)
f01011a1:	77 7a                	ja     f010121d <printnum+0xaa>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01011a3:	83 ec 0c             	sub    $0xc,%esp
f01011a6:	ff 75 18             	pushl  0x18(%ebp)
f01011a9:	8b 45 14             	mov    0x14(%ebp),%eax
f01011ac:	8d 58 ff             	lea    -0x1(%eax),%ebx
f01011af:	53                   	push   %ebx
f01011b0:	ff 75 10             	pushl  0x10(%ebp)
f01011b3:	83 ec 08             	sub    $0x8,%esp
f01011b6:	ff 75 e4             	pushl  -0x1c(%ebp)
f01011b9:	ff 75 e0             	pushl  -0x20(%ebp)
f01011bc:	ff 75 dc             	pushl  -0x24(%ebp)
f01011bf:	ff 75 d8             	pushl  -0x28(%ebp)
f01011c2:	e8 d9 09 00 00       	call   f0101ba0 <__udivdi3>
f01011c7:	83 c4 18             	add    $0x18,%esp
f01011ca:	52                   	push   %edx
f01011cb:	50                   	push   %eax
f01011cc:	89 f2                	mov    %esi,%edx
f01011ce:	89 f8                	mov    %edi,%eax
f01011d0:	e8 9e ff ff ff       	call   f0101173 <printnum>
f01011d5:	83 c4 20             	add    $0x20,%esp
f01011d8:	eb 13                	jmp    f01011ed <printnum+0x7a>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01011da:	83 ec 08             	sub    $0x8,%esp
f01011dd:	56                   	push   %esi
f01011de:	ff 75 18             	pushl  0x18(%ebp)
f01011e1:	ff d7                	call   *%edi
f01011e3:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f01011e6:	83 eb 01             	sub    $0x1,%ebx
f01011e9:	85 db                	test   %ebx,%ebx
f01011eb:	7f ed                	jg     f01011da <printnum+0x67>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01011ed:	83 ec 08             	sub    $0x8,%esp
f01011f0:	56                   	push   %esi
f01011f1:	83 ec 04             	sub    $0x4,%esp
f01011f4:	ff 75 e4             	pushl  -0x1c(%ebp)
f01011f7:	ff 75 e0             	pushl  -0x20(%ebp)
f01011fa:	ff 75 dc             	pushl  -0x24(%ebp)
f01011fd:	ff 75 d8             	pushl  -0x28(%ebp)
f0101200:	e8 bb 0a 00 00       	call   f0101cc0 <__umoddi3>
f0101205:	83 c4 14             	add    $0x14,%esp
f0101208:	0f be 80 a0 22 10 f0 	movsbl -0xfefdd60(%eax),%eax
f010120f:	50                   	push   %eax
f0101210:	ff d7                	call   *%edi
}
f0101212:	83 c4 10             	add    $0x10,%esp
f0101215:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101218:	5b                   	pop    %ebx
f0101219:	5e                   	pop    %esi
f010121a:	5f                   	pop    %edi
f010121b:	5d                   	pop    %ebp
f010121c:	c3                   	ret    
f010121d:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0101220:	eb c4                	jmp    f01011e6 <printnum+0x73>

f0101222 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0101222:	55                   	push   %ebp
f0101223:	89 e5                	mov    %esp,%ebp
f0101225:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0101228:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f010122c:	8b 10                	mov    (%eax),%edx
f010122e:	3b 50 04             	cmp    0x4(%eax),%edx
f0101231:	73 0a                	jae    f010123d <sprintputch+0x1b>
		*b->buf++ = ch;
f0101233:	8d 4a 01             	lea    0x1(%edx),%ecx
f0101236:	89 08                	mov    %ecx,(%eax)
f0101238:	8b 45 08             	mov    0x8(%ebp),%eax
f010123b:	88 02                	mov    %al,(%edx)
}
f010123d:	5d                   	pop    %ebp
f010123e:	c3                   	ret    

f010123f <printfmt>:
{
f010123f:	55                   	push   %ebp
f0101240:	89 e5                	mov    %esp,%ebp
f0101242:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f0101245:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0101248:	50                   	push   %eax
f0101249:	ff 75 10             	pushl  0x10(%ebp)
f010124c:	ff 75 0c             	pushl  0xc(%ebp)
f010124f:	ff 75 08             	pushl  0x8(%ebp)
f0101252:	e8 05 00 00 00       	call   f010125c <vprintfmt>
}
f0101257:	83 c4 10             	add    $0x10,%esp
f010125a:	c9                   	leave  
f010125b:	c3                   	ret    

f010125c <vprintfmt>:
{
f010125c:	55                   	push   %ebp
f010125d:	89 e5                	mov    %esp,%ebp
f010125f:	57                   	push   %edi
f0101260:	56                   	push   %esi
f0101261:	53                   	push   %ebx
f0101262:	83 ec 2c             	sub    $0x2c,%esp
f0101265:	8b 75 08             	mov    0x8(%ebp),%esi
f0101268:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010126b:	8b 7d 10             	mov    0x10(%ebp),%edi
f010126e:	e9 c1 03 00 00       	jmp    f0101634 <vprintfmt+0x3d8>
		padc = ' ';
f0101273:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
f0101277:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
f010127e:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
		width = -1;
f0101285:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f010128c:	b9 00 00 00 00       	mov    $0x0,%ecx
		switch (ch = *(unsigned char *) fmt++) {
f0101291:	8d 47 01             	lea    0x1(%edi),%eax
f0101294:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101297:	0f b6 17             	movzbl (%edi),%edx
f010129a:	8d 42 dd             	lea    -0x23(%edx),%eax
f010129d:	3c 55                	cmp    $0x55,%al
f010129f:	0f 87 12 04 00 00    	ja     f01016b7 <vprintfmt+0x45b>
f01012a5:	0f b6 c0             	movzbl %al,%eax
f01012a8:	ff 24 85 2c 23 10 f0 	jmp    *-0xfefdcd4(,%eax,4)
f01012af:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f01012b2:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f01012b6:	eb d9                	jmp    f0101291 <vprintfmt+0x35>
		switch (ch = *(unsigned char *) fmt++) {
f01012b8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '0';
f01012bb:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f01012bf:	eb d0                	jmp    f0101291 <vprintfmt+0x35>
		switch (ch = *(unsigned char *) fmt++) {
f01012c1:	0f b6 d2             	movzbl %dl,%edx
f01012c4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f01012c7:	b8 00 00 00 00       	mov    $0x0,%eax
f01012cc:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
				precision = precision * 10 + ch - '0';
f01012cf:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01012d2:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f01012d6:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f01012d9:	8d 4a d0             	lea    -0x30(%edx),%ecx
f01012dc:	83 f9 09             	cmp    $0x9,%ecx
f01012df:	77 55                	ja     f0101336 <vprintfmt+0xda>
			for (precision = 0; ; ++fmt) {
f01012e1:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f01012e4:	eb e9                	jmp    f01012cf <vprintfmt+0x73>
			precision = va_arg(ap, int);
f01012e6:	8b 45 14             	mov    0x14(%ebp),%eax
f01012e9:	8b 00                	mov    (%eax),%eax
f01012eb:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01012ee:	8b 45 14             	mov    0x14(%ebp),%eax
f01012f1:	8d 40 04             	lea    0x4(%eax),%eax
f01012f4:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01012f7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f01012fa:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01012fe:	79 91                	jns    f0101291 <vprintfmt+0x35>
				width = precision, precision = -1;
f0101300:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101303:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101306:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f010130d:	eb 82                	jmp    f0101291 <vprintfmt+0x35>
f010130f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101312:	85 c0                	test   %eax,%eax
f0101314:	ba 00 00 00 00       	mov    $0x0,%edx
f0101319:	0f 49 d0             	cmovns %eax,%edx
f010131c:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010131f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101322:	e9 6a ff ff ff       	jmp    f0101291 <vprintfmt+0x35>
f0101327:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f010132a:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0101331:	e9 5b ff ff ff       	jmp    f0101291 <vprintfmt+0x35>
f0101336:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101339:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010133c:	eb bc                	jmp    f01012fa <vprintfmt+0x9e>
			lflag++;
f010133e:	83 c1 01             	add    $0x1,%ecx
		switch (ch = *(unsigned char *) fmt++) {
f0101341:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f0101344:	e9 48 ff ff ff       	jmp    f0101291 <vprintfmt+0x35>
			putch(va_arg(ap, int), putdat);
f0101349:	8b 45 14             	mov    0x14(%ebp),%eax
f010134c:	8d 78 04             	lea    0x4(%eax),%edi
f010134f:	83 ec 08             	sub    $0x8,%esp
f0101352:	53                   	push   %ebx
f0101353:	ff 30                	pushl  (%eax)
f0101355:	ff d6                	call   *%esi
			break;
f0101357:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f010135a:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f010135d:	e9 cf 02 00 00       	jmp    f0101631 <vprintfmt+0x3d5>
			err = va_arg(ap, int);
f0101362:	8b 45 14             	mov    0x14(%ebp),%eax
f0101365:	8d 78 04             	lea    0x4(%eax),%edi
f0101368:	8b 00                	mov    (%eax),%eax
f010136a:	99                   	cltd   
f010136b:	31 d0                	xor    %edx,%eax
f010136d:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010136f:	83 f8 06             	cmp    $0x6,%eax
f0101372:	7f 23                	jg     f0101397 <vprintfmt+0x13b>
f0101374:	8b 14 85 84 24 10 f0 	mov    -0xfefdb7c(,%eax,4),%edx
f010137b:	85 d2                	test   %edx,%edx
f010137d:	74 18                	je     f0101397 <vprintfmt+0x13b>
				printfmt(putch, putdat, "%s", p);
f010137f:	52                   	push   %edx
f0101380:	68 de 20 10 f0       	push   $0xf01020de
f0101385:	53                   	push   %ebx
f0101386:	56                   	push   %esi
f0101387:	e8 b3 fe ff ff       	call   f010123f <printfmt>
f010138c:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f010138f:	89 7d 14             	mov    %edi,0x14(%ebp)
f0101392:	e9 9a 02 00 00       	jmp    f0101631 <vprintfmt+0x3d5>
				printfmt(putch, putdat, "error %d", err);
f0101397:	50                   	push   %eax
f0101398:	68 b8 22 10 f0       	push   $0xf01022b8
f010139d:	53                   	push   %ebx
f010139e:	56                   	push   %esi
f010139f:	e8 9b fe ff ff       	call   f010123f <printfmt>
f01013a4:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f01013a7:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f01013aa:	e9 82 02 00 00       	jmp    f0101631 <vprintfmt+0x3d5>
			if ((p = va_arg(ap, char *)) == NULL)
f01013af:	8b 45 14             	mov    0x14(%ebp),%eax
f01013b2:	83 c0 04             	add    $0x4,%eax
f01013b5:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01013b8:	8b 45 14             	mov    0x14(%ebp),%eax
f01013bb:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f01013bd:	85 ff                	test   %edi,%edi
f01013bf:	b8 b1 22 10 f0       	mov    $0xf01022b1,%eax
f01013c4:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f01013c7:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01013cb:	0f 8e bd 00 00 00    	jle    f010148e <vprintfmt+0x232>
f01013d1:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f01013d5:	75 0e                	jne    f01013e5 <vprintfmt+0x189>
f01013d7:	89 75 08             	mov    %esi,0x8(%ebp)
f01013da:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01013dd:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01013e0:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f01013e3:	eb 6d                	jmp    f0101452 <vprintfmt+0x1f6>
				for (width -= strnlen(p, precision); width > 0; width--)
f01013e5:	83 ec 08             	sub    $0x8,%esp
f01013e8:	ff 75 d0             	pushl  -0x30(%ebp)
f01013eb:	57                   	push   %edi
f01013ec:	e8 50 04 00 00       	call   f0101841 <strnlen>
f01013f1:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f01013f4:	29 c1                	sub    %eax,%ecx
f01013f6:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f01013f9:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f01013fc:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0101400:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101403:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0101406:	89 cf                	mov    %ecx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f0101408:	eb 0f                	jmp    f0101419 <vprintfmt+0x1bd>
					putch(padc, putdat);
f010140a:	83 ec 08             	sub    $0x8,%esp
f010140d:	53                   	push   %ebx
f010140e:	ff 75 e0             	pushl  -0x20(%ebp)
f0101411:	ff d6                	call   *%esi
				for (width -= strnlen(p, precision); width > 0; width--)
f0101413:	83 ef 01             	sub    $0x1,%edi
f0101416:	83 c4 10             	add    $0x10,%esp
f0101419:	85 ff                	test   %edi,%edi
f010141b:	7f ed                	jg     f010140a <vprintfmt+0x1ae>
f010141d:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101420:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0101423:	85 c9                	test   %ecx,%ecx
f0101425:	b8 00 00 00 00       	mov    $0x0,%eax
f010142a:	0f 49 c1             	cmovns %ecx,%eax
f010142d:	29 c1                	sub    %eax,%ecx
f010142f:	89 75 08             	mov    %esi,0x8(%ebp)
f0101432:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101435:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101438:	89 cb                	mov    %ecx,%ebx
f010143a:	eb 16                	jmp    f0101452 <vprintfmt+0x1f6>
				if (altflag && (ch < ' ' || ch > '~'))
f010143c:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0101440:	75 31                	jne    f0101473 <vprintfmt+0x217>
					putch(ch, putdat);
f0101442:	83 ec 08             	sub    $0x8,%esp
f0101445:	ff 75 0c             	pushl  0xc(%ebp)
f0101448:	50                   	push   %eax
f0101449:	ff 55 08             	call   *0x8(%ebp)
f010144c:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010144f:	83 eb 01             	sub    $0x1,%ebx
f0101452:	83 c7 01             	add    $0x1,%edi
f0101455:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
f0101459:	0f be c2             	movsbl %dl,%eax
f010145c:	85 c0                	test   %eax,%eax
f010145e:	74 59                	je     f01014b9 <vprintfmt+0x25d>
f0101460:	85 f6                	test   %esi,%esi
f0101462:	78 d8                	js     f010143c <vprintfmt+0x1e0>
f0101464:	83 ee 01             	sub    $0x1,%esi
f0101467:	79 d3                	jns    f010143c <vprintfmt+0x1e0>
f0101469:	89 df                	mov    %ebx,%edi
f010146b:	8b 75 08             	mov    0x8(%ebp),%esi
f010146e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101471:	eb 37                	jmp    f01014aa <vprintfmt+0x24e>
				if (altflag && (ch < ' ' || ch > '~'))
f0101473:	0f be d2             	movsbl %dl,%edx
f0101476:	83 ea 20             	sub    $0x20,%edx
f0101479:	83 fa 5e             	cmp    $0x5e,%edx
f010147c:	76 c4                	jbe    f0101442 <vprintfmt+0x1e6>
					putch('?', putdat);
f010147e:	83 ec 08             	sub    $0x8,%esp
f0101481:	ff 75 0c             	pushl  0xc(%ebp)
f0101484:	6a 3f                	push   $0x3f
f0101486:	ff 55 08             	call   *0x8(%ebp)
f0101489:	83 c4 10             	add    $0x10,%esp
f010148c:	eb c1                	jmp    f010144f <vprintfmt+0x1f3>
f010148e:	89 75 08             	mov    %esi,0x8(%ebp)
f0101491:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101494:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101497:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f010149a:	eb b6                	jmp    f0101452 <vprintfmt+0x1f6>
				putch(' ', putdat);
f010149c:	83 ec 08             	sub    $0x8,%esp
f010149f:	53                   	push   %ebx
f01014a0:	6a 20                	push   $0x20
f01014a2:	ff d6                	call   *%esi
			for (; width > 0; width--)
f01014a4:	83 ef 01             	sub    $0x1,%edi
f01014a7:	83 c4 10             	add    $0x10,%esp
f01014aa:	85 ff                	test   %edi,%edi
f01014ac:	7f ee                	jg     f010149c <vprintfmt+0x240>
			if ((p = va_arg(ap, char *)) == NULL)
f01014ae:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01014b1:	89 45 14             	mov    %eax,0x14(%ebp)
f01014b4:	e9 78 01 00 00       	jmp    f0101631 <vprintfmt+0x3d5>
f01014b9:	89 df                	mov    %ebx,%edi
f01014bb:	8b 75 08             	mov    0x8(%ebp),%esi
f01014be:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01014c1:	eb e7                	jmp    f01014aa <vprintfmt+0x24e>
	if (lflag >= 2)
f01014c3:	83 f9 01             	cmp    $0x1,%ecx
f01014c6:	7e 3f                	jle    f0101507 <vprintfmt+0x2ab>
		return va_arg(*ap, long long);
f01014c8:	8b 45 14             	mov    0x14(%ebp),%eax
f01014cb:	8b 50 04             	mov    0x4(%eax),%edx
f01014ce:	8b 00                	mov    (%eax),%eax
f01014d0:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01014d3:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01014d6:	8b 45 14             	mov    0x14(%ebp),%eax
f01014d9:	8d 40 08             	lea    0x8(%eax),%eax
f01014dc:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f01014df:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01014e3:	79 5c                	jns    f0101541 <vprintfmt+0x2e5>
				putch('-', putdat);
f01014e5:	83 ec 08             	sub    $0x8,%esp
f01014e8:	53                   	push   %ebx
f01014e9:	6a 2d                	push   $0x2d
f01014eb:	ff d6                	call   *%esi
				num = -(long long) num;
f01014ed:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01014f0:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01014f3:	f7 da                	neg    %edx
f01014f5:	83 d1 00             	adc    $0x0,%ecx
f01014f8:	f7 d9                	neg    %ecx
f01014fa:	83 c4 10             	add    $0x10,%esp
			base = 10;
f01014fd:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101502:	e9 10 01 00 00       	jmp    f0101617 <vprintfmt+0x3bb>
	else if (lflag)
f0101507:	85 c9                	test   %ecx,%ecx
f0101509:	75 1b                	jne    f0101526 <vprintfmt+0x2ca>
		return va_arg(*ap, int);
f010150b:	8b 45 14             	mov    0x14(%ebp),%eax
f010150e:	8b 00                	mov    (%eax),%eax
f0101510:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101513:	89 c1                	mov    %eax,%ecx
f0101515:	c1 f9 1f             	sar    $0x1f,%ecx
f0101518:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f010151b:	8b 45 14             	mov    0x14(%ebp),%eax
f010151e:	8d 40 04             	lea    0x4(%eax),%eax
f0101521:	89 45 14             	mov    %eax,0x14(%ebp)
f0101524:	eb b9                	jmp    f01014df <vprintfmt+0x283>
		return va_arg(*ap, long);
f0101526:	8b 45 14             	mov    0x14(%ebp),%eax
f0101529:	8b 00                	mov    (%eax),%eax
f010152b:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010152e:	89 c1                	mov    %eax,%ecx
f0101530:	c1 f9 1f             	sar    $0x1f,%ecx
f0101533:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0101536:	8b 45 14             	mov    0x14(%ebp),%eax
f0101539:	8d 40 04             	lea    0x4(%eax),%eax
f010153c:	89 45 14             	mov    %eax,0x14(%ebp)
f010153f:	eb 9e                	jmp    f01014df <vprintfmt+0x283>
			num = getint(&ap, lflag);
f0101541:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101544:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f0101547:	b8 0a 00 00 00       	mov    $0xa,%eax
f010154c:	e9 c6 00 00 00       	jmp    f0101617 <vprintfmt+0x3bb>
	if (lflag >= 2)
f0101551:	83 f9 01             	cmp    $0x1,%ecx
f0101554:	7e 18                	jle    f010156e <vprintfmt+0x312>
		return va_arg(*ap, unsigned long long);
f0101556:	8b 45 14             	mov    0x14(%ebp),%eax
f0101559:	8b 10                	mov    (%eax),%edx
f010155b:	8b 48 04             	mov    0x4(%eax),%ecx
f010155e:	8d 40 08             	lea    0x8(%eax),%eax
f0101561:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0101564:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101569:	e9 a9 00 00 00       	jmp    f0101617 <vprintfmt+0x3bb>
	else if (lflag)
f010156e:	85 c9                	test   %ecx,%ecx
f0101570:	75 1a                	jne    f010158c <vprintfmt+0x330>
		return va_arg(*ap, unsigned int);
f0101572:	8b 45 14             	mov    0x14(%ebp),%eax
f0101575:	8b 10                	mov    (%eax),%edx
f0101577:	b9 00 00 00 00       	mov    $0x0,%ecx
f010157c:	8d 40 04             	lea    0x4(%eax),%eax
f010157f:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0101582:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101587:	e9 8b 00 00 00       	jmp    f0101617 <vprintfmt+0x3bb>
		return va_arg(*ap, unsigned long);
f010158c:	8b 45 14             	mov    0x14(%ebp),%eax
f010158f:	8b 10                	mov    (%eax),%edx
f0101591:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101596:	8d 40 04             	lea    0x4(%eax),%eax
f0101599:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f010159c:	b8 0a 00 00 00       	mov    $0xa,%eax
f01015a1:	eb 74                	jmp    f0101617 <vprintfmt+0x3bb>
	if (lflag >= 2)
f01015a3:	83 f9 01             	cmp    $0x1,%ecx
f01015a6:	7e 15                	jle    f01015bd <vprintfmt+0x361>
		return va_arg(*ap, unsigned long long);
f01015a8:	8b 45 14             	mov    0x14(%ebp),%eax
f01015ab:	8b 10                	mov    (%eax),%edx
f01015ad:	8b 48 04             	mov    0x4(%eax),%ecx
f01015b0:	8d 40 08             	lea    0x8(%eax),%eax
f01015b3:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f01015b6:	b8 08 00 00 00       	mov    $0x8,%eax
f01015bb:	eb 5a                	jmp    f0101617 <vprintfmt+0x3bb>
	else if (lflag)
f01015bd:	85 c9                	test   %ecx,%ecx
f01015bf:	75 17                	jne    f01015d8 <vprintfmt+0x37c>
		return va_arg(*ap, unsigned int);
f01015c1:	8b 45 14             	mov    0x14(%ebp),%eax
f01015c4:	8b 10                	mov    (%eax),%edx
f01015c6:	b9 00 00 00 00       	mov    $0x0,%ecx
f01015cb:	8d 40 04             	lea    0x4(%eax),%eax
f01015ce:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f01015d1:	b8 08 00 00 00       	mov    $0x8,%eax
f01015d6:	eb 3f                	jmp    f0101617 <vprintfmt+0x3bb>
		return va_arg(*ap, unsigned long);
f01015d8:	8b 45 14             	mov    0x14(%ebp),%eax
f01015db:	8b 10                	mov    (%eax),%edx
f01015dd:	b9 00 00 00 00       	mov    $0x0,%ecx
f01015e2:	8d 40 04             	lea    0x4(%eax),%eax
f01015e5:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f01015e8:	b8 08 00 00 00       	mov    $0x8,%eax
f01015ed:	eb 28                	jmp    f0101617 <vprintfmt+0x3bb>
			putch('0', putdat);
f01015ef:	83 ec 08             	sub    $0x8,%esp
f01015f2:	53                   	push   %ebx
f01015f3:	6a 30                	push   $0x30
f01015f5:	ff d6                	call   *%esi
			putch('x', putdat);
f01015f7:	83 c4 08             	add    $0x8,%esp
f01015fa:	53                   	push   %ebx
f01015fb:	6a 78                	push   $0x78
f01015fd:	ff d6                	call   *%esi
			num = (unsigned long long)
f01015ff:	8b 45 14             	mov    0x14(%ebp),%eax
f0101602:	8b 10                	mov    (%eax),%edx
f0101604:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f0101609:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f010160c:	8d 40 04             	lea    0x4(%eax),%eax
f010160f:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101612:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f0101617:	83 ec 0c             	sub    $0xc,%esp
f010161a:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f010161e:	57                   	push   %edi
f010161f:	ff 75 e0             	pushl  -0x20(%ebp)
f0101622:	50                   	push   %eax
f0101623:	51                   	push   %ecx
f0101624:	52                   	push   %edx
f0101625:	89 da                	mov    %ebx,%edx
f0101627:	89 f0                	mov    %esi,%eax
f0101629:	e8 45 fb ff ff       	call   f0101173 <printnum>
			break;
f010162e:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f0101631:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0101634:	83 c7 01             	add    $0x1,%edi
f0101637:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f010163b:	83 f8 25             	cmp    $0x25,%eax
f010163e:	0f 84 2f fc ff ff    	je     f0101273 <vprintfmt+0x17>
			if (ch == '\0')
f0101644:	85 c0                	test   %eax,%eax
f0101646:	0f 84 8b 00 00 00    	je     f01016d7 <vprintfmt+0x47b>
			putch(ch, putdat);
f010164c:	83 ec 08             	sub    $0x8,%esp
f010164f:	53                   	push   %ebx
f0101650:	50                   	push   %eax
f0101651:	ff d6                	call   *%esi
f0101653:	83 c4 10             	add    $0x10,%esp
f0101656:	eb dc                	jmp    f0101634 <vprintfmt+0x3d8>
	if (lflag >= 2)
f0101658:	83 f9 01             	cmp    $0x1,%ecx
f010165b:	7e 15                	jle    f0101672 <vprintfmt+0x416>
		return va_arg(*ap, unsigned long long);
f010165d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101660:	8b 10                	mov    (%eax),%edx
f0101662:	8b 48 04             	mov    0x4(%eax),%ecx
f0101665:	8d 40 08             	lea    0x8(%eax),%eax
f0101668:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010166b:	b8 10 00 00 00       	mov    $0x10,%eax
f0101670:	eb a5                	jmp    f0101617 <vprintfmt+0x3bb>
	else if (lflag)
f0101672:	85 c9                	test   %ecx,%ecx
f0101674:	75 17                	jne    f010168d <vprintfmt+0x431>
		return va_arg(*ap, unsigned int);
f0101676:	8b 45 14             	mov    0x14(%ebp),%eax
f0101679:	8b 10                	mov    (%eax),%edx
f010167b:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101680:	8d 40 04             	lea    0x4(%eax),%eax
f0101683:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101686:	b8 10 00 00 00       	mov    $0x10,%eax
f010168b:	eb 8a                	jmp    f0101617 <vprintfmt+0x3bb>
		return va_arg(*ap, unsigned long);
f010168d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101690:	8b 10                	mov    (%eax),%edx
f0101692:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101697:	8d 40 04             	lea    0x4(%eax),%eax
f010169a:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010169d:	b8 10 00 00 00       	mov    $0x10,%eax
f01016a2:	e9 70 ff ff ff       	jmp    f0101617 <vprintfmt+0x3bb>
			putch(ch, putdat);
f01016a7:	83 ec 08             	sub    $0x8,%esp
f01016aa:	53                   	push   %ebx
f01016ab:	6a 25                	push   $0x25
f01016ad:	ff d6                	call   *%esi
			break;
f01016af:	83 c4 10             	add    $0x10,%esp
f01016b2:	e9 7a ff ff ff       	jmp    f0101631 <vprintfmt+0x3d5>
			putch('%', putdat);
f01016b7:	83 ec 08             	sub    $0x8,%esp
f01016ba:	53                   	push   %ebx
f01016bb:	6a 25                	push   $0x25
f01016bd:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01016bf:	83 c4 10             	add    $0x10,%esp
f01016c2:	89 f8                	mov    %edi,%eax
f01016c4:	eb 03                	jmp    f01016c9 <vprintfmt+0x46d>
f01016c6:	83 e8 01             	sub    $0x1,%eax
f01016c9:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f01016cd:	75 f7                	jne    f01016c6 <vprintfmt+0x46a>
f01016cf:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01016d2:	e9 5a ff ff ff       	jmp    f0101631 <vprintfmt+0x3d5>
}
f01016d7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01016da:	5b                   	pop    %ebx
f01016db:	5e                   	pop    %esi
f01016dc:	5f                   	pop    %edi
f01016dd:	5d                   	pop    %ebp
f01016de:	c3                   	ret    

f01016df <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01016df:	55                   	push   %ebp
f01016e0:	89 e5                	mov    %esp,%ebp
f01016e2:	83 ec 18             	sub    $0x18,%esp
f01016e5:	8b 45 08             	mov    0x8(%ebp),%eax
f01016e8:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01016eb:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01016ee:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01016f2:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01016f5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01016fc:	85 c0                	test   %eax,%eax
f01016fe:	74 26                	je     f0101726 <vsnprintf+0x47>
f0101700:	85 d2                	test   %edx,%edx
f0101702:	7e 22                	jle    f0101726 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101704:	ff 75 14             	pushl  0x14(%ebp)
f0101707:	ff 75 10             	pushl  0x10(%ebp)
f010170a:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010170d:	50                   	push   %eax
f010170e:	68 22 12 10 f0       	push   $0xf0101222
f0101713:	e8 44 fb ff ff       	call   f010125c <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101718:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010171b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010171e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101721:	83 c4 10             	add    $0x10,%esp
}
f0101724:	c9                   	leave  
f0101725:	c3                   	ret    
		return -E_INVAL;
f0101726:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f010172b:	eb f7                	jmp    f0101724 <vsnprintf+0x45>

f010172d <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010172d:	55                   	push   %ebp
f010172e:	89 e5                	mov    %esp,%ebp
f0101730:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101733:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101736:	50                   	push   %eax
f0101737:	ff 75 10             	pushl  0x10(%ebp)
f010173a:	ff 75 0c             	pushl  0xc(%ebp)
f010173d:	ff 75 08             	pushl  0x8(%ebp)
f0101740:	e8 9a ff ff ff       	call   f01016df <vsnprintf>
	va_end(ap);

	return rc;
}
f0101745:	c9                   	leave  
f0101746:	c3                   	ret    

f0101747 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101747:	55                   	push   %ebp
f0101748:	89 e5                	mov    %esp,%ebp
f010174a:	57                   	push   %edi
f010174b:	56                   	push   %esi
f010174c:	53                   	push   %ebx
f010174d:	83 ec 0c             	sub    $0xc,%esp
f0101750:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0101753:	85 c0                	test   %eax,%eax
f0101755:	74 11                	je     f0101768 <readline+0x21>
		cprintf("%s", prompt);
f0101757:	83 ec 08             	sub    $0x8,%esp
f010175a:	50                   	push   %eax
f010175b:	68 de 20 10 f0       	push   $0xf01020de
f0101760:	e8 1f ef ff ff       	call   f0100684 <cprintf>
f0101765:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0101768:	83 ec 0c             	sub    $0xc,%esp
f010176b:	6a 00                	push   $0x0
f010176d:	e8 cf ee ff ff       	call   f0100641 <iscons>
f0101772:	89 c7                	mov    %eax,%edi
f0101774:	83 c4 10             	add    $0x10,%esp
	i = 0;
f0101777:	be 00 00 00 00       	mov    $0x0,%esi
f010177c:	eb 3f                	jmp    f01017bd <readline+0x76>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f010177e:	83 ec 08             	sub    $0x8,%esp
f0101781:	50                   	push   %eax
f0101782:	68 a0 24 10 f0       	push   $0xf01024a0
f0101787:	e8 f8 ee ff ff       	call   f0100684 <cprintf>
			return NULL;
f010178c:	83 c4 10             	add    $0x10,%esp
f010178f:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f0101794:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101797:	5b                   	pop    %ebx
f0101798:	5e                   	pop    %esi
f0101799:	5f                   	pop    %edi
f010179a:	5d                   	pop    %ebp
f010179b:	c3                   	ret    
			if (echoing)
f010179c:	85 ff                	test   %edi,%edi
f010179e:	75 05                	jne    f01017a5 <readline+0x5e>
			i--;
f01017a0:	83 ee 01             	sub    $0x1,%esi
f01017a3:	eb 18                	jmp    f01017bd <readline+0x76>
				cputchar('\b');
f01017a5:	83 ec 0c             	sub    $0xc,%esp
f01017a8:	6a 08                	push   $0x8
f01017aa:	e8 71 ee ff ff       	call   f0100620 <cputchar>
f01017af:	83 c4 10             	add    $0x10,%esp
f01017b2:	eb ec                	jmp    f01017a0 <readline+0x59>
			buf[i++] = c;
f01017b4:	88 9e 40 35 11 f0    	mov    %bl,-0xfeecac0(%esi)
f01017ba:	8d 76 01             	lea    0x1(%esi),%esi
		c = getchar();
f01017bd:	e8 6e ee ff ff       	call   f0100630 <getchar>
f01017c2:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01017c4:	85 c0                	test   %eax,%eax
f01017c6:	78 b6                	js     f010177e <readline+0x37>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01017c8:	83 f8 08             	cmp    $0x8,%eax
f01017cb:	0f 94 c2             	sete   %dl
f01017ce:	83 f8 7f             	cmp    $0x7f,%eax
f01017d1:	0f 94 c0             	sete   %al
f01017d4:	08 c2                	or     %al,%dl
f01017d6:	74 04                	je     f01017dc <readline+0x95>
f01017d8:	85 f6                	test   %esi,%esi
f01017da:	7f c0                	jg     f010179c <readline+0x55>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01017dc:	83 fb 1f             	cmp    $0x1f,%ebx
f01017df:	7e 1a                	jle    f01017fb <readline+0xb4>
f01017e1:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01017e7:	7f 12                	jg     f01017fb <readline+0xb4>
			if (echoing)
f01017e9:	85 ff                	test   %edi,%edi
f01017eb:	74 c7                	je     f01017b4 <readline+0x6d>
				cputchar(c);
f01017ed:	83 ec 0c             	sub    $0xc,%esp
f01017f0:	53                   	push   %ebx
f01017f1:	e8 2a ee ff ff       	call   f0100620 <cputchar>
f01017f6:	83 c4 10             	add    $0x10,%esp
f01017f9:	eb b9                	jmp    f01017b4 <readline+0x6d>
		} else if (c == '\n' || c == '\r') {
f01017fb:	83 fb 0a             	cmp    $0xa,%ebx
f01017fe:	74 05                	je     f0101805 <readline+0xbe>
f0101800:	83 fb 0d             	cmp    $0xd,%ebx
f0101803:	75 b8                	jne    f01017bd <readline+0x76>
			if (echoing)
f0101805:	85 ff                	test   %edi,%edi
f0101807:	75 11                	jne    f010181a <readline+0xd3>
			buf[i] = 0;
f0101809:	c6 86 40 35 11 f0 00 	movb   $0x0,-0xfeecac0(%esi)
			return buf;
f0101810:	b8 40 35 11 f0       	mov    $0xf0113540,%eax
f0101815:	e9 7a ff ff ff       	jmp    f0101794 <readline+0x4d>
				cputchar('\n');
f010181a:	83 ec 0c             	sub    $0xc,%esp
f010181d:	6a 0a                	push   $0xa
f010181f:	e8 fc ed ff ff       	call   f0100620 <cputchar>
f0101824:	83 c4 10             	add    $0x10,%esp
f0101827:	eb e0                	jmp    f0101809 <readline+0xc2>

f0101829 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101829:	55                   	push   %ebp
f010182a:	89 e5                	mov    %esp,%ebp
f010182c:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f010182f:	b8 00 00 00 00       	mov    $0x0,%eax
f0101834:	eb 03                	jmp    f0101839 <strlen+0x10>
		n++;
f0101836:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f0101839:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f010183d:	75 f7                	jne    f0101836 <strlen+0xd>
	return n;
}
f010183f:	5d                   	pop    %ebp
f0101840:	c3                   	ret    

f0101841 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101841:	55                   	push   %ebp
f0101842:	89 e5                	mov    %esp,%ebp
f0101844:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101847:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010184a:	b8 00 00 00 00       	mov    $0x0,%eax
f010184f:	eb 03                	jmp    f0101854 <strnlen+0x13>
		n++;
f0101851:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101854:	39 d0                	cmp    %edx,%eax
f0101856:	74 06                	je     f010185e <strnlen+0x1d>
f0101858:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f010185c:	75 f3                	jne    f0101851 <strnlen+0x10>
	return n;
}
f010185e:	5d                   	pop    %ebp
f010185f:	c3                   	ret    

f0101860 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101860:	55                   	push   %ebp
f0101861:	89 e5                	mov    %esp,%ebp
f0101863:	53                   	push   %ebx
f0101864:	8b 45 08             	mov    0x8(%ebp),%eax
f0101867:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f010186a:	89 c2                	mov    %eax,%edx
f010186c:	83 c1 01             	add    $0x1,%ecx
f010186f:	83 c2 01             	add    $0x1,%edx
f0101872:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0101876:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101879:	84 db                	test   %bl,%bl
f010187b:	75 ef                	jne    f010186c <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f010187d:	5b                   	pop    %ebx
f010187e:	5d                   	pop    %ebp
f010187f:	c3                   	ret    

f0101880 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101880:	55                   	push   %ebp
f0101881:	89 e5                	mov    %esp,%ebp
f0101883:	53                   	push   %ebx
f0101884:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101887:	53                   	push   %ebx
f0101888:	e8 9c ff ff ff       	call   f0101829 <strlen>
f010188d:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0101890:	ff 75 0c             	pushl  0xc(%ebp)
f0101893:	01 d8                	add    %ebx,%eax
f0101895:	50                   	push   %eax
f0101896:	e8 c5 ff ff ff       	call   f0101860 <strcpy>
	return dst;
}
f010189b:	89 d8                	mov    %ebx,%eax
f010189d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01018a0:	c9                   	leave  
f01018a1:	c3                   	ret    

f01018a2 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01018a2:	55                   	push   %ebp
f01018a3:	89 e5                	mov    %esp,%ebp
f01018a5:	56                   	push   %esi
f01018a6:	53                   	push   %ebx
f01018a7:	8b 75 08             	mov    0x8(%ebp),%esi
f01018aa:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01018ad:	89 f3                	mov    %esi,%ebx
f01018af:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01018b2:	89 f2                	mov    %esi,%edx
f01018b4:	eb 0f                	jmp    f01018c5 <strncpy+0x23>
		*dst++ = *src;
f01018b6:	83 c2 01             	add    $0x1,%edx
f01018b9:	0f b6 01             	movzbl (%ecx),%eax
f01018bc:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01018bf:	80 39 01             	cmpb   $0x1,(%ecx)
f01018c2:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f01018c5:	39 da                	cmp    %ebx,%edx
f01018c7:	75 ed                	jne    f01018b6 <strncpy+0x14>
	}
	return ret;
}
f01018c9:	89 f0                	mov    %esi,%eax
f01018cb:	5b                   	pop    %ebx
f01018cc:	5e                   	pop    %esi
f01018cd:	5d                   	pop    %ebp
f01018ce:	c3                   	ret    

f01018cf <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01018cf:	55                   	push   %ebp
f01018d0:	89 e5                	mov    %esp,%ebp
f01018d2:	56                   	push   %esi
f01018d3:	53                   	push   %ebx
f01018d4:	8b 75 08             	mov    0x8(%ebp),%esi
f01018d7:	8b 55 0c             	mov    0xc(%ebp),%edx
f01018da:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01018dd:	89 f0                	mov    %esi,%eax
f01018df:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01018e3:	85 c9                	test   %ecx,%ecx
f01018e5:	75 0b                	jne    f01018f2 <strlcpy+0x23>
f01018e7:	eb 17                	jmp    f0101900 <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01018e9:	83 c2 01             	add    $0x1,%edx
f01018ec:	83 c0 01             	add    $0x1,%eax
f01018ef:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f01018f2:	39 d8                	cmp    %ebx,%eax
f01018f4:	74 07                	je     f01018fd <strlcpy+0x2e>
f01018f6:	0f b6 0a             	movzbl (%edx),%ecx
f01018f9:	84 c9                	test   %cl,%cl
f01018fb:	75 ec                	jne    f01018e9 <strlcpy+0x1a>
		*dst = '\0';
f01018fd:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0101900:	29 f0                	sub    %esi,%eax
}
f0101902:	5b                   	pop    %ebx
f0101903:	5e                   	pop    %esi
f0101904:	5d                   	pop    %ebp
f0101905:	c3                   	ret    

f0101906 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101906:	55                   	push   %ebp
f0101907:	89 e5                	mov    %esp,%ebp
f0101909:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010190c:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f010190f:	eb 06                	jmp    f0101917 <strcmp+0x11>
		p++, q++;
f0101911:	83 c1 01             	add    $0x1,%ecx
f0101914:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f0101917:	0f b6 01             	movzbl (%ecx),%eax
f010191a:	84 c0                	test   %al,%al
f010191c:	74 04                	je     f0101922 <strcmp+0x1c>
f010191e:	3a 02                	cmp    (%edx),%al
f0101920:	74 ef                	je     f0101911 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101922:	0f b6 c0             	movzbl %al,%eax
f0101925:	0f b6 12             	movzbl (%edx),%edx
f0101928:	29 d0                	sub    %edx,%eax
}
f010192a:	5d                   	pop    %ebp
f010192b:	c3                   	ret    

f010192c <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010192c:	55                   	push   %ebp
f010192d:	89 e5                	mov    %esp,%ebp
f010192f:	53                   	push   %ebx
f0101930:	8b 45 08             	mov    0x8(%ebp),%eax
f0101933:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101936:	89 c3                	mov    %eax,%ebx
f0101938:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f010193b:	eb 06                	jmp    f0101943 <strncmp+0x17>
		n--, p++, q++;
f010193d:	83 c0 01             	add    $0x1,%eax
f0101940:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f0101943:	39 d8                	cmp    %ebx,%eax
f0101945:	74 16                	je     f010195d <strncmp+0x31>
f0101947:	0f b6 08             	movzbl (%eax),%ecx
f010194a:	84 c9                	test   %cl,%cl
f010194c:	74 04                	je     f0101952 <strncmp+0x26>
f010194e:	3a 0a                	cmp    (%edx),%cl
f0101950:	74 eb                	je     f010193d <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101952:	0f b6 00             	movzbl (%eax),%eax
f0101955:	0f b6 12             	movzbl (%edx),%edx
f0101958:	29 d0                	sub    %edx,%eax
}
f010195a:	5b                   	pop    %ebx
f010195b:	5d                   	pop    %ebp
f010195c:	c3                   	ret    
		return 0;
f010195d:	b8 00 00 00 00       	mov    $0x0,%eax
f0101962:	eb f6                	jmp    f010195a <strncmp+0x2e>

f0101964 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101964:	55                   	push   %ebp
f0101965:	89 e5                	mov    %esp,%ebp
f0101967:	8b 45 08             	mov    0x8(%ebp),%eax
f010196a:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010196e:	0f b6 10             	movzbl (%eax),%edx
f0101971:	84 d2                	test   %dl,%dl
f0101973:	74 09                	je     f010197e <strchr+0x1a>
		if (*s == c)
f0101975:	38 ca                	cmp    %cl,%dl
f0101977:	74 0a                	je     f0101983 <strchr+0x1f>
	for (; *s; s++)
f0101979:	83 c0 01             	add    $0x1,%eax
f010197c:	eb f0                	jmp    f010196e <strchr+0xa>
			return (char *) s;
	return 0;
f010197e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101983:	5d                   	pop    %ebp
f0101984:	c3                   	ret    

f0101985 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101985:	55                   	push   %ebp
f0101986:	89 e5                	mov    %esp,%ebp
f0101988:	8b 45 08             	mov    0x8(%ebp),%eax
f010198b:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010198f:	eb 03                	jmp    f0101994 <strfind+0xf>
f0101991:	83 c0 01             	add    $0x1,%eax
f0101994:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0101997:	38 ca                	cmp    %cl,%dl
f0101999:	74 04                	je     f010199f <strfind+0x1a>
f010199b:	84 d2                	test   %dl,%dl
f010199d:	75 f2                	jne    f0101991 <strfind+0xc>
			break;
	return (char *) s;
}
f010199f:	5d                   	pop    %ebp
f01019a0:	c3                   	ret    

f01019a1 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01019a1:	55                   	push   %ebp
f01019a2:	89 e5                	mov    %esp,%ebp
f01019a4:	57                   	push   %edi
f01019a5:	56                   	push   %esi
f01019a6:	53                   	push   %ebx
f01019a7:	8b 7d 08             	mov    0x8(%ebp),%edi
f01019aa:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01019ad:	85 c9                	test   %ecx,%ecx
f01019af:	74 13                	je     f01019c4 <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01019b1:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01019b7:	75 05                	jne    f01019be <memset+0x1d>
f01019b9:	f6 c1 03             	test   $0x3,%cl
f01019bc:	74 0d                	je     f01019cb <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01019be:	8b 45 0c             	mov    0xc(%ebp),%eax
f01019c1:	fc                   	cld    
f01019c2:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01019c4:	89 f8                	mov    %edi,%eax
f01019c6:	5b                   	pop    %ebx
f01019c7:	5e                   	pop    %esi
f01019c8:	5f                   	pop    %edi
f01019c9:	5d                   	pop    %ebp
f01019ca:	c3                   	ret    
		c &= 0xFF;
f01019cb:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01019cf:	89 d3                	mov    %edx,%ebx
f01019d1:	c1 e3 08             	shl    $0x8,%ebx
f01019d4:	89 d0                	mov    %edx,%eax
f01019d6:	c1 e0 18             	shl    $0x18,%eax
f01019d9:	89 d6                	mov    %edx,%esi
f01019db:	c1 e6 10             	shl    $0x10,%esi
f01019de:	09 f0                	or     %esi,%eax
f01019e0:	09 c2                	or     %eax,%edx
f01019e2:	09 da                	or     %ebx,%edx
			:: "D" (v), "a" (c), "c" (n/4)
f01019e4:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f01019e7:	89 d0                	mov    %edx,%eax
f01019e9:	fc                   	cld    
f01019ea:	f3 ab                	rep stos %eax,%es:(%edi)
f01019ec:	eb d6                	jmp    f01019c4 <memset+0x23>

f01019ee <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01019ee:	55                   	push   %ebp
f01019ef:	89 e5                	mov    %esp,%ebp
f01019f1:	57                   	push   %edi
f01019f2:	56                   	push   %esi
f01019f3:	8b 45 08             	mov    0x8(%ebp),%eax
f01019f6:	8b 75 0c             	mov    0xc(%ebp),%esi
f01019f9:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01019fc:	39 c6                	cmp    %eax,%esi
f01019fe:	73 35                	jae    f0101a35 <memmove+0x47>
f0101a00:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0101a03:	39 c2                	cmp    %eax,%edx
f0101a05:	76 2e                	jbe    f0101a35 <memmove+0x47>
		s += n;
		d += n;
f0101a07:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101a0a:	89 d6                	mov    %edx,%esi
f0101a0c:	09 fe                	or     %edi,%esi
f0101a0e:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101a14:	74 0c                	je     f0101a22 <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0101a16:	83 ef 01             	sub    $0x1,%edi
f0101a19:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f0101a1c:	fd                   	std    
f0101a1d:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101a1f:	fc                   	cld    
f0101a20:	eb 21                	jmp    f0101a43 <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101a22:	f6 c1 03             	test   $0x3,%cl
f0101a25:	75 ef                	jne    f0101a16 <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101a27:	83 ef 04             	sub    $0x4,%edi
f0101a2a:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101a2d:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f0101a30:	fd                   	std    
f0101a31:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101a33:	eb ea                	jmp    f0101a1f <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101a35:	89 f2                	mov    %esi,%edx
f0101a37:	09 c2                	or     %eax,%edx
f0101a39:	f6 c2 03             	test   $0x3,%dl
f0101a3c:	74 09                	je     f0101a47 <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101a3e:	89 c7                	mov    %eax,%edi
f0101a40:	fc                   	cld    
f0101a41:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101a43:	5e                   	pop    %esi
f0101a44:	5f                   	pop    %edi
f0101a45:	5d                   	pop    %ebp
f0101a46:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101a47:	f6 c1 03             	test   $0x3,%cl
f0101a4a:	75 f2                	jne    f0101a3e <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0101a4c:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f0101a4f:	89 c7                	mov    %eax,%edi
f0101a51:	fc                   	cld    
f0101a52:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101a54:	eb ed                	jmp    f0101a43 <memmove+0x55>

f0101a56 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0101a56:	55                   	push   %ebp
f0101a57:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0101a59:	ff 75 10             	pushl  0x10(%ebp)
f0101a5c:	ff 75 0c             	pushl  0xc(%ebp)
f0101a5f:	ff 75 08             	pushl  0x8(%ebp)
f0101a62:	e8 87 ff ff ff       	call   f01019ee <memmove>
}
f0101a67:	c9                   	leave  
f0101a68:	c3                   	ret    

f0101a69 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101a69:	55                   	push   %ebp
f0101a6a:	89 e5                	mov    %esp,%ebp
f0101a6c:	56                   	push   %esi
f0101a6d:	53                   	push   %ebx
f0101a6e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101a71:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101a74:	89 c6                	mov    %eax,%esi
f0101a76:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101a79:	39 f0                	cmp    %esi,%eax
f0101a7b:	74 1c                	je     f0101a99 <memcmp+0x30>
		if (*s1 != *s2)
f0101a7d:	0f b6 08             	movzbl (%eax),%ecx
f0101a80:	0f b6 1a             	movzbl (%edx),%ebx
f0101a83:	38 d9                	cmp    %bl,%cl
f0101a85:	75 08                	jne    f0101a8f <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f0101a87:	83 c0 01             	add    $0x1,%eax
f0101a8a:	83 c2 01             	add    $0x1,%edx
f0101a8d:	eb ea                	jmp    f0101a79 <memcmp+0x10>
			return (int) *s1 - (int) *s2;
f0101a8f:	0f b6 c1             	movzbl %cl,%eax
f0101a92:	0f b6 db             	movzbl %bl,%ebx
f0101a95:	29 d8                	sub    %ebx,%eax
f0101a97:	eb 05                	jmp    f0101a9e <memcmp+0x35>
	}

	return 0;
f0101a99:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101a9e:	5b                   	pop    %ebx
f0101a9f:	5e                   	pop    %esi
f0101aa0:	5d                   	pop    %ebp
f0101aa1:	c3                   	ret    

f0101aa2 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101aa2:	55                   	push   %ebp
f0101aa3:	89 e5                	mov    %esp,%ebp
f0101aa5:	8b 45 08             	mov    0x8(%ebp),%eax
f0101aa8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0101aab:	89 c2                	mov    %eax,%edx
f0101aad:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0101ab0:	39 d0                	cmp    %edx,%eax
f0101ab2:	73 09                	jae    f0101abd <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101ab4:	38 08                	cmp    %cl,(%eax)
f0101ab6:	74 05                	je     f0101abd <memfind+0x1b>
	for (; s < ends; s++)
f0101ab8:	83 c0 01             	add    $0x1,%eax
f0101abb:	eb f3                	jmp    f0101ab0 <memfind+0xe>
			break;
	return (void *) s;
}
f0101abd:	5d                   	pop    %ebp
f0101abe:	c3                   	ret    

f0101abf <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101abf:	55                   	push   %ebp
f0101ac0:	89 e5                	mov    %esp,%ebp
f0101ac2:	57                   	push   %edi
f0101ac3:	56                   	push   %esi
f0101ac4:	53                   	push   %ebx
f0101ac5:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101ac8:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101acb:	eb 03                	jmp    f0101ad0 <strtol+0x11>
		s++;
f0101acd:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f0101ad0:	0f b6 01             	movzbl (%ecx),%eax
f0101ad3:	3c 20                	cmp    $0x20,%al
f0101ad5:	74 f6                	je     f0101acd <strtol+0xe>
f0101ad7:	3c 09                	cmp    $0x9,%al
f0101ad9:	74 f2                	je     f0101acd <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f0101adb:	3c 2b                	cmp    $0x2b,%al
f0101add:	74 2e                	je     f0101b0d <strtol+0x4e>
	int neg = 0;
f0101adf:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f0101ae4:	3c 2d                	cmp    $0x2d,%al
f0101ae6:	74 2f                	je     f0101b17 <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101ae8:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0101aee:	75 05                	jne    f0101af5 <strtol+0x36>
f0101af0:	80 39 30             	cmpb   $0x30,(%ecx)
f0101af3:	74 2c                	je     f0101b21 <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101af5:	85 db                	test   %ebx,%ebx
f0101af7:	75 0a                	jne    f0101b03 <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0101af9:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
f0101afe:	80 39 30             	cmpb   $0x30,(%ecx)
f0101b01:	74 28                	je     f0101b2b <strtol+0x6c>
		base = 10;
f0101b03:	b8 00 00 00 00       	mov    $0x0,%eax
f0101b08:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0101b0b:	eb 50                	jmp    f0101b5d <strtol+0x9e>
		s++;
f0101b0d:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f0101b10:	bf 00 00 00 00       	mov    $0x0,%edi
f0101b15:	eb d1                	jmp    f0101ae8 <strtol+0x29>
		s++, neg = 1;
f0101b17:	83 c1 01             	add    $0x1,%ecx
f0101b1a:	bf 01 00 00 00       	mov    $0x1,%edi
f0101b1f:	eb c7                	jmp    f0101ae8 <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101b21:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0101b25:	74 0e                	je     f0101b35 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f0101b27:	85 db                	test   %ebx,%ebx
f0101b29:	75 d8                	jne    f0101b03 <strtol+0x44>
		s++, base = 8;
f0101b2b:	83 c1 01             	add    $0x1,%ecx
f0101b2e:	bb 08 00 00 00       	mov    $0x8,%ebx
f0101b33:	eb ce                	jmp    f0101b03 <strtol+0x44>
		s += 2, base = 16;
f0101b35:	83 c1 02             	add    $0x2,%ecx
f0101b38:	bb 10 00 00 00       	mov    $0x10,%ebx
f0101b3d:	eb c4                	jmp    f0101b03 <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f0101b3f:	8d 72 9f             	lea    -0x61(%edx),%esi
f0101b42:	89 f3                	mov    %esi,%ebx
f0101b44:	80 fb 19             	cmp    $0x19,%bl
f0101b47:	77 29                	ja     f0101b72 <strtol+0xb3>
			dig = *s - 'a' + 10;
f0101b49:	0f be d2             	movsbl %dl,%edx
f0101b4c:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0101b4f:	3b 55 10             	cmp    0x10(%ebp),%edx
f0101b52:	7d 30                	jge    f0101b84 <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f0101b54:	83 c1 01             	add    $0x1,%ecx
f0101b57:	0f af 45 10          	imul   0x10(%ebp),%eax
f0101b5b:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f0101b5d:	0f b6 11             	movzbl (%ecx),%edx
f0101b60:	8d 72 d0             	lea    -0x30(%edx),%esi
f0101b63:	89 f3                	mov    %esi,%ebx
f0101b65:	80 fb 09             	cmp    $0x9,%bl
f0101b68:	77 d5                	ja     f0101b3f <strtol+0x80>
			dig = *s - '0';
f0101b6a:	0f be d2             	movsbl %dl,%edx
f0101b6d:	83 ea 30             	sub    $0x30,%edx
f0101b70:	eb dd                	jmp    f0101b4f <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
f0101b72:	8d 72 bf             	lea    -0x41(%edx),%esi
f0101b75:	89 f3                	mov    %esi,%ebx
f0101b77:	80 fb 19             	cmp    $0x19,%bl
f0101b7a:	77 08                	ja     f0101b84 <strtol+0xc5>
			dig = *s - 'A' + 10;
f0101b7c:	0f be d2             	movsbl %dl,%edx
f0101b7f:	83 ea 37             	sub    $0x37,%edx
f0101b82:	eb cb                	jmp    f0101b4f <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
f0101b84:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101b88:	74 05                	je     f0101b8f <strtol+0xd0>
		*endptr = (char *) s;
f0101b8a:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101b8d:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f0101b8f:	89 c2                	mov    %eax,%edx
f0101b91:	f7 da                	neg    %edx
f0101b93:	85 ff                	test   %edi,%edi
f0101b95:	0f 45 c2             	cmovne %edx,%eax
}
f0101b98:	5b                   	pop    %ebx
f0101b99:	5e                   	pop    %esi
f0101b9a:	5f                   	pop    %edi
f0101b9b:	5d                   	pop    %ebp
f0101b9c:	c3                   	ret    
f0101b9d:	66 90                	xchg   %ax,%ax
f0101b9f:	90                   	nop

f0101ba0 <__udivdi3>:
f0101ba0:	55                   	push   %ebp
f0101ba1:	57                   	push   %edi
f0101ba2:	56                   	push   %esi
f0101ba3:	53                   	push   %ebx
f0101ba4:	83 ec 1c             	sub    $0x1c,%esp
f0101ba7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f0101bab:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f0101baf:	8b 74 24 34          	mov    0x34(%esp),%esi
f0101bb3:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f0101bb7:	85 d2                	test   %edx,%edx
f0101bb9:	75 35                	jne    f0101bf0 <__udivdi3+0x50>
f0101bbb:	39 f3                	cmp    %esi,%ebx
f0101bbd:	0f 87 bd 00 00 00    	ja     f0101c80 <__udivdi3+0xe0>
f0101bc3:	85 db                	test   %ebx,%ebx
f0101bc5:	89 d9                	mov    %ebx,%ecx
f0101bc7:	75 0b                	jne    f0101bd4 <__udivdi3+0x34>
f0101bc9:	b8 01 00 00 00       	mov    $0x1,%eax
f0101bce:	31 d2                	xor    %edx,%edx
f0101bd0:	f7 f3                	div    %ebx
f0101bd2:	89 c1                	mov    %eax,%ecx
f0101bd4:	31 d2                	xor    %edx,%edx
f0101bd6:	89 f0                	mov    %esi,%eax
f0101bd8:	f7 f1                	div    %ecx
f0101bda:	89 c6                	mov    %eax,%esi
f0101bdc:	89 e8                	mov    %ebp,%eax
f0101bde:	89 f7                	mov    %esi,%edi
f0101be0:	f7 f1                	div    %ecx
f0101be2:	89 fa                	mov    %edi,%edx
f0101be4:	83 c4 1c             	add    $0x1c,%esp
f0101be7:	5b                   	pop    %ebx
f0101be8:	5e                   	pop    %esi
f0101be9:	5f                   	pop    %edi
f0101bea:	5d                   	pop    %ebp
f0101beb:	c3                   	ret    
f0101bec:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101bf0:	39 f2                	cmp    %esi,%edx
f0101bf2:	77 7c                	ja     f0101c70 <__udivdi3+0xd0>
f0101bf4:	0f bd fa             	bsr    %edx,%edi
f0101bf7:	83 f7 1f             	xor    $0x1f,%edi
f0101bfa:	0f 84 98 00 00 00    	je     f0101c98 <__udivdi3+0xf8>
f0101c00:	89 f9                	mov    %edi,%ecx
f0101c02:	b8 20 00 00 00       	mov    $0x20,%eax
f0101c07:	29 f8                	sub    %edi,%eax
f0101c09:	d3 e2                	shl    %cl,%edx
f0101c0b:	89 54 24 08          	mov    %edx,0x8(%esp)
f0101c0f:	89 c1                	mov    %eax,%ecx
f0101c11:	89 da                	mov    %ebx,%edx
f0101c13:	d3 ea                	shr    %cl,%edx
f0101c15:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0101c19:	09 d1                	or     %edx,%ecx
f0101c1b:	89 f2                	mov    %esi,%edx
f0101c1d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101c21:	89 f9                	mov    %edi,%ecx
f0101c23:	d3 e3                	shl    %cl,%ebx
f0101c25:	89 c1                	mov    %eax,%ecx
f0101c27:	d3 ea                	shr    %cl,%edx
f0101c29:	89 f9                	mov    %edi,%ecx
f0101c2b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0101c2f:	d3 e6                	shl    %cl,%esi
f0101c31:	89 eb                	mov    %ebp,%ebx
f0101c33:	89 c1                	mov    %eax,%ecx
f0101c35:	d3 eb                	shr    %cl,%ebx
f0101c37:	09 de                	or     %ebx,%esi
f0101c39:	89 f0                	mov    %esi,%eax
f0101c3b:	f7 74 24 08          	divl   0x8(%esp)
f0101c3f:	89 d6                	mov    %edx,%esi
f0101c41:	89 c3                	mov    %eax,%ebx
f0101c43:	f7 64 24 0c          	mull   0xc(%esp)
f0101c47:	39 d6                	cmp    %edx,%esi
f0101c49:	72 0c                	jb     f0101c57 <__udivdi3+0xb7>
f0101c4b:	89 f9                	mov    %edi,%ecx
f0101c4d:	d3 e5                	shl    %cl,%ebp
f0101c4f:	39 c5                	cmp    %eax,%ebp
f0101c51:	73 5d                	jae    f0101cb0 <__udivdi3+0x110>
f0101c53:	39 d6                	cmp    %edx,%esi
f0101c55:	75 59                	jne    f0101cb0 <__udivdi3+0x110>
f0101c57:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0101c5a:	31 ff                	xor    %edi,%edi
f0101c5c:	89 fa                	mov    %edi,%edx
f0101c5e:	83 c4 1c             	add    $0x1c,%esp
f0101c61:	5b                   	pop    %ebx
f0101c62:	5e                   	pop    %esi
f0101c63:	5f                   	pop    %edi
f0101c64:	5d                   	pop    %ebp
f0101c65:	c3                   	ret    
f0101c66:	8d 76 00             	lea    0x0(%esi),%esi
f0101c69:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0101c70:	31 ff                	xor    %edi,%edi
f0101c72:	31 c0                	xor    %eax,%eax
f0101c74:	89 fa                	mov    %edi,%edx
f0101c76:	83 c4 1c             	add    $0x1c,%esp
f0101c79:	5b                   	pop    %ebx
f0101c7a:	5e                   	pop    %esi
f0101c7b:	5f                   	pop    %edi
f0101c7c:	5d                   	pop    %ebp
f0101c7d:	c3                   	ret    
f0101c7e:	66 90                	xchg   %ax,%ax
f0101c80:	31 ff                	xor    %edi,%edi
f0101c82:	89 e8                	mov    %ebp,%eax
f0101c84:	89 f2                	mov    %esi,%edx
f0101c86:	f7 f3                	div    %ebx
f0101c88:	89 fa                	mov    %edi,%edx
f0101c8a:	83 c4 1c             	add    $0x1c,%esp
f0101c8d:	5b                   	pop    %ebx
f0101c8e:	5e                   	pop    %esi
f0101c8f:	5f                   	pop    %edi
f0101c90:	5d                   	pop    %ebp
f0101c91:	c3                   	ret    
f0101c92:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101c98:	39 f2                	cmp    %esi,%edx
f0101c9a:	72 06                	jb     f0101ca2 <__udivdi3+0x102>
f0101c9c:	31 c0                	xor    %eax,%eax
f0101c9e:	39 eb                	cmp    %ebp,%ebx
f0101ca0:	77 d2                	ja     f0101c74 <__udivdi3+0xd4>
f0101ca2:	b8 01 00 00 00       	mov    $0x1,%eax
f0101ca7:	eb cb                	jmp    f0101c74 <__udivdi3+0xd4>
f0101ca9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101cb0:	89 d8                	mov    %ebx,%eax
f0101cb2:	31 ff                	xor    %edi,%edi
f0101cb4:	eb be                	jmp    f0101c74 <__udivdi3+0xd4>
f0101cb6:	66 90                	xchg   %ax,%ax
f0101cb8:	66 90                	xchg   %ax,%ax
f0101cba:	66 90                	xchg   %ax,%ax
f0101cbc:	66 90                	xchg   %ax,%ax
f0101cbe:	66 90                	xchg   %ax,%ax

f0101cc0 <__umoddi3>:
f0101cc0:	55                   	push   %ebp
f0101cc1:	57                   	push   %edi
f0101cc2:	56                   	push   %esi
f0101cc3:	53                   	push   %ebx
f0101cc4:	83 ec 1c             	sub    $0x1c,%esp
f0101cc7:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
f0101ccb:	8b 74 24 30          	mov    0x30(%esp),%esi
f0101ccf:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0101cd3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101cd7:	85 ed                	test   %ebp,%ebp
f0101cd9:	89 f0                	mov    %esi,%eax
f0101cdb:	89 da                	mov    %ebx,%edx
f0101cdd:	75 19                	jne    f0101cf8 <__umoddi3+0x38>
f0101cdf:	39 df                	cmp    %ebx,%edi
f0101ce1:	0f 86 b1 00 00 00    	jbe    f0101d98 <__umoddi3+0xd8>
f0101ce7:	f7 f7                	div    %edi
f0101ce9:	89 d0                	mov    %edx,%eax
f0101ceb:	31 d2                	xor    %edx,%edx
f0101ced:	83 c4 1c             	add    $0x1c,%esp
f0101cf0:	5b                   	pop    %ebx
f0101cf1:	5e                   	pop    %esi
f0101cf2:	5f                   	pop    %edi
f0101cf3:	5d                   	pop    %ebp
f0101cf4:	c3                   	ret    
f0101cf5:	8d 76 00             	lea    0x0(%esi),%esi
f0101cf8:	39 dd                	cmp    %ebx,%ebp
f0101cfa:	77 f1                	ja     f0101ced <__umoddi3+0x2d>
f0101cfc:	0f bd cd             	bsr    %ebp,%ecx
f0101cff:	83 f1 1f             	xor    $0x1f,%ecx
f0101d02:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101d06:	0f 84 b4 00 00 00    	je     f0101dc0 <__umoddi3+0x100>
f0101d0c:	b8 20 00 00 00       	mov    $0x20,%eax
f0101d11:	89 c2                	mov    %eax,%edx
f0101d13:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101d17:	29 c2                	sub    %eax,%edx
f0101d19:	89 c1                	mov    %eax,%ecx
f0101d1b:	89 f8                	mov    %edi,%eax
f0101d1d:	d3 e5                	shl    %cl,%ebp
f0101d1f:	89 d1                	mov    %edx,%ecx
f0101d21:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101d25:	d3 e8                	shr    %cl,%eax
f0101d27:	09 c5                	or     %eax,%ebp
f0101d29:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101d2d:	89 c1                	mov    %eax,%ecx
f0101d2f:	d3 e7                	shl    %cl,%edi
f0101d31:	89 d1                	mov    %edx,%ecx
f0101d33:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0101d37:	89 df                	mov    %ebx,%edi
f0101d39:	d3 ef                	shr    %cl,%edi
f0101d3b:	89 c1                	mov    %eax,%ecx
f0101d3d:	89 f0                	mov    %esi,%eax
f0101d3f:	d3 e3                	shl    %cl,%ebx
f0101d41:	89 d1                	mov    %edx,%ecx
f0101d43:	89 fa                	mov    %edi,%edx
f0101d45:	d3 e8                	shr    %cl,%eax
f0101d47:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101d4c:	09 d8                	or     %ebx,%eax
f0101d4e:	f7 f5                	div    %ebp
f0101d50:	d3 e6                	shl    %cl,%esi
f0101d52:	89 d1                	mov    %edx,%ecx
f0101d54:	f7 64 24 08          	mull   0x8(%esp)
f0101d58:	39 d1                	cmp    %edx,%ecx
f0101d5a:	89 c3                	mov    %eax,%ebx
f0101d5c:	89 d7                	mov    %edx,%edi
f0101d5e:	72 06                	jb     f0101d66 <__umoddi3+0xa6>
f0101d60:	75 0e                	jne    f0101d70 <__umoddi3+0xb0>
f0101d62:	39 c6                	cmp    %eax,%esi
f0101d64:	73 0a                	jae    f0101d70 <__umoddi3+0xb0>
f0101d66:	2b 44 24 08          	sub    0x8(%esp),%eax
f0101d6a:	19 ea                	sbb    %ebp,%edx
f0101d6c:	89 d7                	mov    %edx,%edi
f0101d6e:	89 c3                	mov    %eax,%ebx
f0101d70:	89 ca                	mov    %ecx,%edx
f0101d72:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f0101d77:	29 de                	sub    %ebx,%esi
f0101d79:	19 fa                	sbb    %edi,%edx
f0101d7b:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f0101d7f:	89 d0                	mov    %edx,%eax
f0101d81:	d3 e0                	shl    %cl,%eax
f0101d83:	89 d9                	mov    %ebx,%ecx
f0101d85:	d3 ee                	shr    %cl,%esi
f0101d87:	d3 ea                	shr    %cl,%edx
f0101d89:	09 f0                	or     %esi,%eax
f0101d8b:	83 c4 1c             	add    $0x1c,%esp
f0101d8e:	5b                   	pop    %ebx
f0101d8f:	5e                   	pop    %esi
f0101d90:	5f                   	pop    %edi
f0101d91:	5d                   	pop    %ebp
f0101d92:	c3                   	ret    
f0101d93:	90                   	nop
f0101d94:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101d98:	85 ff                	test   %edi,%edi
f0101d9a:	89 f9                	mov    %edi,%ecx
f0101d9c:	75 0b                	jne    f0101da9 <__umoddi3+0xe9>
f0101d9e:	b8 01 00 00 00       	mov    $0x1,%eax
f0101da3:	31 d2                	xor    %edx,%edx
f0101da5:	f7 f7                	div    %edi
f0101da7:	89 c1                	mov    %eax,%ecx
f0101da9:	89 d8                	mov    %ebx,%eax
f0101dab:	31 d2                	xor    %edx,%edx
f0101dad:	f7 f1                	div    %ecx
f0101daf:	89 f0                	mov    %esi,%eax
f0101db1:	f7 f1                	div    %ecx
f0101db3:	e9 31 ff ff ff       	jmp    f0101ce9 <__umoddi3+0x29>
f0101db8:	90                   	nop
f0101db9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101dc0:	39 dd                	cmp    %ebx,%ebp
f0101dc2:	72 08                	jb     f0101dcc <__umoddi3+0x10c>
f0101dc4:	39 f7                	cmp    %esi,%edi
f0101dc6:	0f 87 21 ff ff ff    	ja     f0101ced <__umoddi3+0x2d>
f0101dcc:	89 da                	mov    %ebx,%edx
f0101dce:	89 f0                	mov    %esi,%eax
f0101dd0:	29 f8                	sub    %edi,%eax
f0101dd2:	19 ea                	sbb    %ebp,%edx
f0101dd4:	e9 14 ff ff ff       	jmp    f0101ced <__umoddi3+0x2d>
