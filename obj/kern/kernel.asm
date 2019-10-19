
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
f0100053:	e8 5a 17 00 00       	call   f01017b2 <memset>

	cons_init();
f0100058:	e8 b5 04 00 00       	call   f0100512 <cons_init>

	cprintf("Hello, world.\n");
f010005d:	c7 04 24 00 1c 10 f0 	movl   $0xf0101c00,(%esp)
f0100064:	e8 1b 06 00 00       	call   f0100684 <cprintf>
	boot_alloc_init();
f0100069:	e8 c9 0a 00 00       	call   f0100b37 <boot_alloc_init>
	vm_init();
f010006e:	e8 84 0e 00 00       	call   f0100ef7 <vm_init>
	alloc_init();
f0100073:	e8 65 0c 00 00       	call   f0100cdd <alloc_init>

	cprintf("VM: Init success.\n");
f0100078:	c7 04 24 0f 1c 10 f0 	movl   $0xf0101c0f,(%esp)
f010007f:	e8 00 06 00 00       	call   f0100684 <cprintf>
	check_free_list();
f0100084:	e8 1f 0a 00 00       	call   f0100aa8 <check_free_list>
	cprintf("Finish.\n");
f0100089:	c7 04 24 22 1c 10 f0 	movl   $0xf0101c22,(%esp)
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
f01000c1:	68 2b 1c 10 f0       	push   $0xf0101c2b
f01000c6:	e8 b9 05 00 00       	call   f0100684 <cprintf>
	vcprintf(fmt, ap);
f01000cb:	83 c4 08             	add    $0x8,%esp
f01000ce:	53                   	push   %ebx
f01000cf:	56                   	push   %esi
f01000d0:	e8 89 05 00 00       	call   f010065e <vcprintf>
	cprintf("\n");
f01000d5:	c7 04 24 67 1c 10 f0 	movl   $0xf0101c67,(%esp)
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
f01000f6:	68 43 1c 10 f0       	push   $0xf0101c43
f01000fb:	e8 84 05 00 00       	call   f0100684 <cprintf>
	vcprintf(fmt, ap);
f0100100:	83 c4 08             	add    $0x8,%esp
f0100103:	53                   	push   %ebx
f0100104:	ff 75 10             	pushl  0x10(%ebp)
f0100107:	e8 52 05 00 00       	call   f010065e <vcprintf>
	cprintf("\n");
f010010c:	c7 04 24 67 1c 10 f0 	movl   $0xf0101c67,(%esp)
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
f01001d3:	0f b6 82 c0 1d 10 f0 	movzbl -0xfefe240(%edx),%eax
f01001da:	0b 05 00 33 11 f0    	or     0xf0113300,%eax
	shift ^= togglecode[data];
f01001e0:	0f b6 8a c0 1c 10 f0 	movzbl -0xfefe340(%edx),%ecx
f01001e7:	31 c8                	xor    %ecx,%eax
f01001e9:	a3 00 33 11 f0       	mov    %eax,0xf0113300
	c = charcode[shift & (CTL | SHIFT)][data];
f01001ee:	89 c1                	mov    %eax,%ecx
f01001f0:	83 e1 03             	and    $0x3,%ecx
f01001f3:	8b 0c 8d a0 1c 10 f0 	mov    -0xfefe360(,%ecx,4),%ecx
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
f0100223:	68 5d 1c 10 f0       	push   $0xf0101c5d
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
f0100266:	0f b6 82 c0 1d 10 f0 	movzbl -0xfefe240(%edx),%eax
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
f0100467:	e8 93 13 00 00       	call   f01017ff <memmove>
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
f0100611:	68 69 1c 10 f0       	push   $0xf0101c69
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
f010067a:	e8 ee 09 00 00       	call   f010106d <vprintfmt>
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
f010070f:	68 c0 1e 10 f0       	push   $0xf0101ec0
f0100714:	68 ca 00 00 00       	push   $0xca
f0100719:	68 c6 1e 10 f0       	push   $0xf0101ec6
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
f010076a:	e8 43 10 00 00       	call   f01017b2 <memset>
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
f0100917:	e8 96 0e 00 00       	call   f01017b2 <memset>
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
f0100acf:	68 d4 1e 10 f0       	push   $0xf0101ed4
f0100ad4:	68 ec 1e 10 f0       	push   $0xf0101eec
f0100ad9:	68 6e 01 00 00       	push   $0x16e
f0100ade:	68 c6 1e 10 f0       	push   $0xf0101ec6
f0100ae3:	e8 b2 f5 ff ff       	call   f010009a <_panic>
		for (int i = 4; i < 4096; i++) 
			assert(((char *)p)[i] == 1);
f0100ae8:	68 01 1f 10 f0       	push   $0xf0101f01
f0100aed:	68 ec 1e 10 f0       	push   $0xf0101eec
f0100af2:	68 70 01 00 00       	push   $0x170
f0100af7:	68 c6 1e 10 f0       	push   $0xf0101ec6
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
f0100b9c:	e8 11 0c 00 00       	call   f01017b2 <memset>
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
f0100bc8:	e8 e5 0b 00 00       	call   f01017b2 <memset>
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
f0100be6:	e8 c7 0b 00 00       	call   f01017b2 <memset>
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
	check_free_list();
f0100ccd:	e8 d6 fd ff ff       	call   f0100aa8 <check_free_list>
}
f0100cd2:	83 c4 10             	add    $0x10,%esp
f0100cd5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100cd8:	5b                   	pop    %ebx
f0100cd9:	5e                   	pop    %esi
f0100cda:	5f                   	pop    %edi
f0100cdb:	5d                   	pop    %ebp
f0100cdc:	c3                   	ret    

f0100cdd <alloc_init>:
{
f0100cdd:	55                   	push   %ebp
f0100cde:	89 e5                	mov    %esp,%ebp
f0100ce0:	83 ec 10             	sub    $0x10,%esp
	Buddyfree_range((void *)base[1], MAX_ORDER[1]);
f0100ce3:	ff 35 78 39 11 f0    	pushl  0xf0113978
f0100ce9:	ff 35 4c 39 11 f0    	pushl  0xf011394c
f0100cef:	e8 f9 fb ff ff       	call   f01008ed <Buddyfree_range>
	check_free_list();
f0100cf4:	e8 af fd ff ff       	call   f0100aa8 <check_free_list>
}
f0100cf9:	83 c4 10             	add    $0x10,%esp
f0100cfc:	c9                   	leave  
f0100cfd:	c3                   	ret    

f0100cfe <pgdir_walk>:
// Hint 2: look at inc/mmu.h for useful macros that manipulate page
// table and page directory entries.
//
static pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int32_t alloc)
{
f0100cfe:	55                   	push   %ebp
f0100cff:	89 e5                	mov    %esp,%ebp
f0100d01:	57                   	push   %edi
f0100d02:	56                   	push   %esi
f0100d03:	53                   	push   %ebx
f0100d04:	83 ec 0c             	sub    $0xc,%esp
f0100d07:	89 d6                	mov    %edx,%esi
	// TODO: Fill this function in
	pde_t *pde = &pgdir[PDX(va)];
f0100d09:	c1 ea 16             	shr    $0x16,%edx
f0100d0c:	8d 3c 90             	lea    (%eax,%edx,4),%edi
	pte_t *pgtab;
	if ((*pde & PTE_P) == 1)
f0100d0f:	8b 1f                	mov    (%edi),%ebx
f0100d11:	f6 c3 01             	test   $0x1,%bl
f0100d14:	74 21                	je     f0100d37 <pgdir_walk+0x39>
	    pgtab = (pte_t *)P2V((*pde >> 12) << 12);
f0100d16:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
f0100d1c:	81 eb 00 00 00 10    	sub    $0x10000000,%ebx
	    if (alloc == 0 || (pgtab = (pte_t *)kalloc()) == NULL)
	        return NULL;
	    memset(pgtab, 0, PGSIZE);
        *pde = V2P(pgtab) | PTE_P | PTE_U | PTE_W;
	}
	return &pgtab[PTX(va)];
f0100d22:	c1 ee 0a             	shr    $0xa,%esi
f0100d25:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f0100d2b:	01 f3                	add    %esi,%ebx
}
f0100d2d:	89 d8                	mov    %ebx,%eax
f0100d2f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100d32:	5b                   	pop    %ebx
f0100d33:	5e                   	pop    %esi
f0100d34:	5f                   	pop    %edi
f0100d35:	5d                   	pop    %ebp
f0100d36:	c3                   	ret    
	    if (alloc == 0 || (pgtab = (pte_t *)kalloc()) == NULL)
f0100d37:	85 c9                	test   %ecx,%ecx
f0100d39:	74 2b                	je     f0100d66 <pgdir_walk+0x68>
f0100d3b:	e8 5c fd ff ff       	call   f0100a9c <kalloc>
f0100d40:	89 c3                	mov    %eax,%ebx
f0100d42:	85 c0                	test   %eax,%eax
f0100d44:	74 e7                	je     f0100d2d <pgdir_walk+0x2f>
	    memset(pgtab, 0, PGSIZE);
f0100d46:	83 ec 04             	sub    $0x4,%esp
f0100d49:	68 00 10 00 00       	push   $0x1000
f0100d4e:	6a 00                	push   $0x0
f0100d50:	50                   	push   %eax
f0100d51:	e8 5c 0a 00 00       	call   f01017b2 <memset>
        *pde = V2P(pgtab) | PTE_P | PTE_U | PTE_W;
f0100d56:	8d 83 00 00 00 10    	lea    0x10000000(%ebx),%eax
f0100d5c:	83 c8 07             	or     $0x7,%eax
f0100d5f:	89 07                	mov    %eax,(%edi)
f0100d61:	83 c4 10             	add    $0x10,%esp
f0100d64:	eb bc                	jmp    f0100d22 <pgdir_walk+0x24>
	        return NULL;
f0100d66:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100d6b:	eb c0                	jmp    f0100d2d <pgdir_walk+0x2f>

f0100d6d <kvm_init>:
//			for each item of kmap[];
//
// Hint: You may need ARRAY_SIZE.
pde_t *
kvm_init(void)
{
f0100d6d:	55                   	push   %ebp
f0100d6e:	89 e5                	mov    %esp,%ebp
f0100d70:	57                   	push   %edi
f0100d71:	56                   	push   %esi
f0100d72:	53                   	push   %ebx
f0100d73:	83 ec 1c             	sub    $0x1c,%esp
	// TODO: your code here
	pde_t *pgdirinit = (pde_t *)kalloc();
f0100d76:	e8 21 fd ff ff       	call   f0100a9c <kalloc>
f0100d7b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	if (pgdirinit) {
f0100d7e:	85 c0                	test   %eax,%eax
f0100d80:	74 2f                	je     f0100db1 <kvm_init+0x44>
	    memset(pgdirinit, 0, PGSIZE);
f0100d82:	83 ec 04             	sub    $0x4,%esp
f0100d85:	68 00 10 00 00       	push   $0x1000
f0100d8a:	6a 00                	push   $0x0
f0100d8c:	50                   	push   %eax
f0100d8d:	e8 20 0a 00 00       	call   f01017b2 <memset>
f0100d92:	bf 80 1f 10 f0       	mov    $0xf0101f80,%edi
f0100d97:	83 c4 10             	add    $0x10,%esp
f0100d9a:	eb 2e                	jmp    f0100dca <kvm_init+0x5d>
		for (int i = 0; i < ARRAY_SIZE(kmap); i++)
			if (map_region(pgdirinit, kmap[i].virt, kmap[i].phys_end - kmap[i].phys_start, kmap[i].phys_start, kmap[i].perm) < 0) {
                //cprintf("The %dth is wrong.\n", i);
				kfree((char *)pgdirinit);
f0100d9c:	83 ec 0c             	sub    $0xc,%esp
f0100d9f:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100da2:	e8 fd fa ff ff       	call   f01008a4 <kfree>
                return 0;
f0100da7:	83 c4 10             	add    $0x10,%esp
f0100daa:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
			}
		return pgdirinit;
	} else
		return 0;
}
f0100db1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100db4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100db7:	5b                   	pop    %ebx
f0100db8:	5e                   	pop    %esi
f0100db9:	5f                   	pop    %edi
f0100dba:	5d                   	pop    %ebp
f0100dbb:	c3                   	ret    
f0100dbc:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0100dbf:	83 c7 10             	add    $0x10,%edi
		for (int i = 0; i < ARRAY_SIZE(kmap); i++)
f0100dc2:	81 ff c0 1f 10 f0    	cmp    $0xf0101fc0,%edi
f0100dc8:	74 e7                	je     f0100db1 <kvm_init+0x44>
			if (map_region(pgdirinit, kmap[i].virt, kmap[i].phys_end - kmap[i].phys_start, kmap[i].phys_start, kmap[i].perm) < 0) {
f0100dca:	8b 57 04             	mov    0x4(%edi),%edx
	char *align = ROUNDUP(va, PGSIZE);
f0100dcd:	8b 07                	mov    (%edi),%eax
f0100dcf:	8d b0 ff 0f 00 00    	lea    0xfff(%eax),%esi
f0100dd5:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	uint32_t alignsize = ROUNDUP(size, PGSIZE);
f0100ddb:	8b 47 08             	mov    0x8(%edi),%eax
f0100dde:	05 ff 0f 00 00       	add    $0xfff,%eax
f0100de3:	29 d0                	sub    %edx,%eax
f0100de5:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100dea:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
f0100ded:	89 d3                	mov    %edx,%ebx
f0100def:	29 d6                	sub    %edx,%esi
		*pte = pa | perm | PTE_P;
f0100df1:	8b 47 0c             	mov    0xc(%edi),%eax
f0100df4:	83 c8 01             	or     $0x1,%eax
f0100df7:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100dfa:	89 7d dc             	mov    %edi,-0x24(%ebp)
f0100dfd:	89 cf                	mov    %ecx,%edi
f0100dff:	8d 14 1e             	lea    (%esi,%ebx,1),%edx
	while (alignsize) {
f0100e02:	39 fb                	cmp    %edi,%ebx
f0100e04:	74 b6                	je     f0100dbc <kvm_init+0x4f>
		pte_t *pte = pgdir_walk(pgdir, align, 1);
f0100e06:	b9 01 00 00 00       	mov    $0x1,%ecx
f0100e0b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100e0e:	e8 eb fe ff ff       	call   f0100cfe <pgdir_walk>
		if (pte == NULL)
f0100e13:	85 c0                	test   %eax,%eax
f0100e15:	74 85                	je     f0100d9c <kvm_init+0x2f>
		*pte = pa | perm | PTE_P;
f0100e17:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0100e1a:	09 da                	or     %ebx,%edx
f0100e1c:	89 10                	mov    %edx,(%eax)
		pa += PGSIZE;
f0100e1e:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0100e24:	eb d9                	jmp    f0100dff <kvm_init+0x92>

f0100e26 <kvm_switch>:

// Switch h/w page table register to the kernel-only page table.
void
kvm_switch(void)
{
f0100e26:	55                   	push   %ebp
f0100e27:	89 e5                	mov    %esp,%ebp
	lcr3(V2P(kpgdir)); // switch to the kernel page table
f0100e29:	a1 7c 39 11 f0       	mov    0xf011397c,%eax
f0100e2e:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0100e33:	0f 22 d8             	mov    %eax,%cr3
}
f0100e36:	5d                   	pop    %ebp
f0100e37:	c3                   	ret    

f0100e38 <check_vm>:

void
check_vm(pde_t *pgdir)
{
f0100e38:	55                   	push   %ebp
f0100e39:	89 e5                	mov    %esp,%ebp
f0100e3b:	57                   	push   %edi
f0100e3c:	56                   	push   %esi
f0100e3d:	53                   	push   %ebx
f0100e3e:	83 ec 1c             	sub    $0x1c,%esp
f0100e41:	c7 45 e4 80 1f 10 f0 	movl   $0xf0101f80,-0x1c(%ebp)
f0100e48:	eb 3e                	jmp    f0100e88 <check_vm+0x50>
		uint32_t alignsize = ROUNDUP(kmap[i].phys_end - kmap[i].phys_start, PGSIZE);
		uint32_t pa = kmap[i].phys_start;
		while(alignsize) {
			pte_t *pte = pgdir_walk(pgdir, align, 1);
			if (pte == NULL) 
				panic("vm_fail: Do not find the page table entry");
f0100e4a:	83 ec 04             	sub    $0x4,%esp
f0100e4d:	68 18 1f 10 f0       	push   $0xf0101f18
f0100e52:	68 94 00 00 00       	push   $0x94
f0100e57:	68 44 1f 10 f0       	push   $0xf0101f44
f0100e5c:	e8 39 f2 ff ff       	call   f010009a <_panic>
			pte_t tmp = (*pte >> 12) << 12;
			assert(tmp == pa);
f0100e61:	68 4e 1f 10 f0       	push   $0xf0101f4e
f0100e66:	68 ec 1e 10 f0       	push   $0xf0101eec
f0100e6b:	68 96 00 00 00       	push   $0x96
f0100e70:	68 44 1f 10 f0       	push   $0xf0101f44
f0100e75:	e8 20 f2 ff ff       	call   f010009a <_panic>
f0100e7a:	83 45 e4 10          	addl   $0x10,-0x1c(%ebp)
f0100e7e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
	for (int i = 0; i < ARRAY_SIZE(kmap); i++) {
f0100e81:	3d c0 1f 10 f0       	cmp    $0xf0101fc0,%eax
f0100e86:	74 67                	je     f0100eef <check_vm+0xb7>
		char *align = ROUNDUP(kmap[i].virt, PGSIZE);
f0100e88:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100e8b:	8b 08                	mov    (%eax),%ecx
f0100e8d:	89 cf                	mov    %ecx,%edi
f0100e8f:	81 c7 ff 0f 00 00    	add    $0xfff,%edi
f0100e95:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
		uint32_t alignsize = ROUNDUP(kmap[i].phys_end - kmap[i].phys_start, PGSIZE);
f0100e9b:	89 c1                	mov    %eax,%ecx
f0100e9d:	8b 40 04             	mov    0x4(%eax),%eax
f0100ea0:	8b 49 08             	mov    0x8(%ecx),%ecx
f0100ea3:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100ea6:	89 ce                	mov    %ecx,%esi
f0100ea8:	81 c6 ff 0f 00 00    	add    $0xfff,%esi
f0100eae:	29 c6                	sub    %eax,%esi
f0100eb0:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
f0100eb6:	01 c6                	add    %eax,%esi
		uint32_t pa = kmap[i].phys_start;
f0100eb8:	89 c3                	mov    %eax,%ebx
f0100eba:	29 c7                	sub    %eax,%edi
f0100ebc:	8d 14 1f             	lea    (%edi,%ebx,1),%edx
		while(alignsize) {
f0100ebf:	39 de                	cmp    %ebx,%esi
f0100ec1:	74 b7                	je     f0100e7a <check_vm+0x42>
			pte_t *pte = pgdir_walk(pgdir, align, 1);
f0100ec3:	b9 01 00 00 00       	mov    $0x1,%ecx
f0100ec8:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ecb:	e8 2e fe ff ff       	call   f0100cfe <pgdir_walk>
			if (pte == NULL) 
f0100ed0:	85 c0                	test   %eax,%eax
f0100ed2:	0f 84 72 ff ff ff    	je     f0100e4a <check_vm+0x12>
			pte_t tmp = (*pte >> 12) << 12;
f0100ed8:	8b 00                	mov    (%eax),%eax
f0100eda:	25 00 f0 ff ff       	and    $0xfffff000,%eax
			assert(tmp == pa);
f0100edf:	39 c3                	cmp    %eax,%ebx
f0100ee1:	0f 85 7a ff ff ff    	jne    f0100e61 <check_vm+0x29>
			align += PGSIZE;
			pa += PGSIZE;
f0100ee7:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0100eed:	eb cd                	jmp    f0100ebc <check_vm+0x84>
			alignsize -= PGSIZE;
		}
	}
}
f0100eef:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100ef2:	5b                   	pop    %ebx
f0100ef3:	5e                   	pop    %esi
f0100ef4:	5f                   	pop    %edi
f0100ef5:	5d                   	pop    %ebp
f0100ef6:	c3                   	ret    

f0100ef7 <vm_init>:

// Allocate one page table for the machine for the kernel address
// space.
void
vm_init(void)
{
f0100ef7:	55                   	push   %ebp
f0100ef8:	89 e5                	mov    %esp,%ebp
f0100efa:	83 ec 08             	sub    $0x8,%esp
	kpgdir = kvm_init();
f0100efd:	e8 6b fe ff ff       	call   f0100d6d <kvm_init>
f0100f02:	a3 7c 39 11 f0       	mov    %eax,0xf011397c
	if (kpgdir == 0)
f0100f07:	85 c0                	test   %eax,%eax
f0100f09:	74 13                	je     f0100f1e <vm_init+0x27>
		panic("vm_init: failure");
	check_vm(kpgdir);
f0100f0b:	83 ec 0c             	sub    $0xc,%esp
f0100f0e:	50                   	push   %eax
f0100f0f:	e8 24 ff ff ff       	call   f0100e38 <check_vm>
	kvm_switch();
f0100f14:	e8 0d ff ff ff       	call   f0100e26 <kvm_switch>
}
f0100f19:	83 c4 10             	add    $0x10,%esp
f0100f1c:	c9                   	leave  
f0100f1d:	c3                   	ret    
		panic("vm_init: failure");
f0100f1e:	83 ec 04             	sub    $0x4,%esp
f0100f21:	68 58 1f 10 f0       	push   $0xf0101f58
f0100f26:	68 a5 00 00 00       	push   $0xa5
f0100f2b:	68 44 1f 10 f0       	push   $0xf0101f44
f0100f30:	e8 65 f1 ff ff       	call   f010009a <_panic>

f0100f35 <vm_free>:
// Free a page table.
//
// Hint: You need to free all existing PTEs for this pgdir.
void
vm_free(pde_t *pgdir)
{
f0100f35:	55                   	push   %ebp
f0100f36:	89 e5                	mov    %esp,%ebp
f0100f38:	57                   	push   %edi
f0100f39:	56                   	push   %esi
f0100f3a:	53                   	push   %ebx
f0100f3b:	83 ec 0c             	sub    $0xc,%esp
f0100f3e:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100f41:	89 fb                	mov    %edi,%ebx
f0100f43:	8d b7 00 10 00 00    	lea    0x1000(%edi),%esi
f0100f49:	eb 07                	jmp    f0100f52 <vm_free+0x1d>
f0100f4b:	83 c3 04             	add    $0x4,%ebx
	// TODO: your code here
	for (int i = 0; i < 1024; i++) {
f0100f4e:	39 f3                	cmp    %esi,%ebx
f0100f50:	74 1e                	je     f0100f70 <vm_free+0x3b>
	    if (pgdir[i] & PTE_P) {
f0100f52:	8b 03                	mov    (%ebx),%eax
f0100f54:	a8 01                	test   $0x1,%al
f0100f56:	74 f3                	je     f0100f4b <vm_free+0x16>
	        char *v = P2V((pgdir[i] >> 12) << 12);
	        kfree(v);
f0100f58:	83 ec 0c             	sub    $0xc,%esp
	        char *v = P2V((pgdir[i] >> 12) << 12);
f0100f5b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100f60:	2d 00 00 00 10       	sub    $0x10000000,%eax
	        kfree(v);
f0100f65:	50                   	push   %eax
f0100f66:	e8 39 f9 ff ff       	call   f01008a4 <kfree>
f0100f6b:	83 c4 10             	add    $0x10,%esp
f0100f6e:	eb db                	jmp    f0100f4b <vm_free+0x16>
	    }
	}
	kfree((char *)pgdir);
f0100f70:	83 ec 0c             	sub    $0xc,%esp
f0100f73:	57                   	push   %edi
f0100f74:	e8 2b f9 ff ff       	call   f01008a4 <kfree>
}
f0100f79:	83 c4 10             	add    $0x10,%esp
f0100f7c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f7f:	5b                   	pop    %ebx
f0100f80:	5e                   	pop    %esi
f0100f81:	5f                   	pop    %edi
f0100f82:	5d                   	pop    %ebp
f0100f83:	c3                   	ret    

f0100f84 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100f84:	55                   	push   %ebp
f0100f85:	89 e5                	mov    %esp,%ebp
f0100f87:	57                   	push   %edi
f0100f88:	56                   	push   %esi
f0100f89:	53                   	push   %ebx
f0100f8a:	83 ec 1c             	sub    $0x1c,%esp
f0100f8d:	89 c7                	mov    %eax,%edi
f0100f8f:	89 d6                	mov    %edx,%esi
f0100f91:	8b 45 08             	mov    0x8(%ebp),%eax
f0100f94:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100f97:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100f9a:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100f9d:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0100fa0:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100fa5:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100fa8:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0100fab:	39 d3                	cmp    %edx,%ebx
f0100fad:	72 05                	jb     f0100fb4 <printnum+0x30>
f0100faf:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100fb2:	77 7a                	ja     f010102e <printnum+0xaa>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100fb4:	83 ec 0c             	sub    $0xc,%esp
f0100fb7:	ff 75 18             	pushl  0x18(%ebp)
f0100fba:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fbd:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0100fc0:	53                   	push   %ebx
f0100fc1:	ff 75 10             	pushl  0x10(%ebp)
f0100fc4:	83 ec 08             	sub    $0x8,%esp
f0100fc7:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100fca:	ff 75 e0             	pushl  -0x20(%ebp)
f0100fcd:	ff 75 dc             	pushl  -0x24(%ebp)
f0100fd0:	ff 75 d8             	pushl  -0x28(%ebp)
f0100fd3:	e8 d8 09 00 00       	call   f01019b0 <__udivdi3>
f0100fd8:	83 c4 18             	add    $0x18,%esp
f0100fdb:	52                   	push   %edx
f0100fdc:	50                   	push   %eax
f0100fdd:	89 f2                	mov    %esi,%edx
f0100fdf:	89 f8                	mov    %edi,%eax
f0100fe1:	e8 9e ff ff ff       	call   f0100f84 <printnum>
f0100fe6:	83 c4 20             	add    $0x20,%esp
f0100fe9:	eb 13                	jmp    f0100ffe <printnum+0x7a>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100feb:	83 ec 08             	sub    $0x8,%esp
f0100fee:	56                   	push   %esi
f0100fef:	ff 75 18             	pushl  0x18(%ebp)
f0100ff2:	ff d7                	call   *%edi
f0100ff4:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f0100ff7:	83 eb 01             	sub    $0x1,%ebx
f0100ffa:	85 db                	test   %ebx,%ebx
f0100ffc:	7f ed                	jg     f0100feb <printnum+0x67>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100ffe:	83 ec 08             	sub    $0x8,%esp
f0101001:	56                   	push   %esi
f0101002:	83 ec 04             	sub    $0x4,%esp
f0101005:	ff 75 e4             	pushl  -0x1c(%ebp)
f0101008:	ff 75 e0             	pushl  -0x20(%ebp)
f010100b:	ff 75 dc             	pushl  -0x24(%ebp)
f010100e:	ff 75 d8             	pushl  -0x28(%ebp)
f0101011:	e8 ba 0a 00 00       	call   f0101ad0 <__umoddi3>
f0101016:	83 c4 14             	add    $0x14,%esp
f0101019:	0f be 80 c0 1f 10 f0 	movsbl -0xfefe040(%eax),%eax
f0101020:	50                   	push   %eax
f0101021:	ff d7                	call   *%edi
}
f0101023:	83 c4 10             	add    $0x10,%esp
f0101026:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101029:	5b                   	pop    %ebx
f010102a:	5e                   	pop    %esi
f010102b:	5f                   	pop    %edi
f010102c:	5d                   	pop    %ebp
f010102d:	c3                   	ret    
f010102e:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0101031:	eb c4                	jmp    f0100ff7 <printnum+0x73>

f0101033 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0101033:	55                   	push   %ebp
f0101034:	89 e5                	mov    %esp,%ebp
f0101036:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0101039:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f010103d:	8b 10                	mov    (%eax),%edx
f010103f:	3b 50 04             	cmp    0x4(%eax),%edx
f0101042:	73 0a                	jae    f010104e <sprintputch+0x1b>
		*b->buf++ = ch;
f0101044:	8d 4a 01             	lea    0x1(%edx),%ecx
f0101047:	89 08                	mov    %ecx,(%eax)
f0101049:	8b 45 08             	mov    0x8(%ebp),%eax
f010104c:	88 02                	mov    %al,(%edx)
}
f010104e:	5d                   	pop    %ebp
f010104f:	c3                   	ret    

f0101050 <printfmt>:
{
f0101050:	55                   	push   %ebp
f0101051:	89 e5                	mov    %esp,%ebp
f0101053:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f0101056:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0101059:	50                   	push   %eax
f010105a:	ff 75 10             	pushl  0x10(%ebp)
f010105d:	ff 75 0c             	pushl  0xc(%ebp)
f0101060:	ff 75 08             	pushl  0x8(%ebp)
f0101063:	e8 05 00 00 00       	call   f010106d <vprintfmt>
}
f0101068:	83 c4 10             	add    $0x10,%esp
f010106b:	c9                   	leave  
f010106c:	c3                   	ret    

f010106d <vprintfmt>:
{
f010106d:	55                   	push   %ebp
f010106e:	89 e5                	mov    %esp,%ebp
f0101070:	57                   	push   %edi
f0101071:	56                   	push   %esi
f0101072:	53                   	push   %ebx
f0101073:	83 ec 2c             	sub    $0x2c,%esp
f0101076:	8b 75 08             	mov    0x8(%ebp),%esi
f0101079:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010107c:	8b 7d 10             	mov    0x10(%ebp),%edi
f010107f:	e9 c1 03 00 00       	jmp    f0101445 <vprintfmt+0x3d8>
		padc = ' ';
f0101084:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
f0101088:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
f010108f:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
		width = -1;
f0101096:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f010109d:	b9 00 00 00 00       	mov    $0x0,%ecx
		switch (ch = *(unsigned char *) fmt++) {
f01010a2:	8d 47 01             	lea    0x1(%edi),%eax
f01010a5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01010a8:	0f b6 17             	movzbl (%edi),%edx
f01010ab:	8d 42 dd             	lea    -0x23(%edx),%eax
f01010ae:	3c 55                	cmp    $0x55,%al
f01010b0:	0f 87 12 04 00 00    	ja     f01014c8 <vprintfmt+0x45b>
f01010b6:	0f b6 c0             	movzbl %al,%eax
f01010b9:	ff 24 85 4c 20 10 f0 	jmp    *-0xfefdfb4(,%eax,4)
f01010c0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f01010c3:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f01010c7:	eb d9                	jmp    f01010a2 <vprintfmt+0x35>
		switch (ch = *(unsigned char *) fmt++) {
f01010c9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '0';
f01010cc:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f01010d0:	eb d0                	jmp    f01010a2 <vprintfmt+0x35>
		switch (ch = *(unsigned char *) fmt++) {
f01010d2:	0f b6 d2             	movzbl %dl,%edx
f01010d5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f01010d8:	b8 00 00 00 00       	mov    $0x0,%eax
f01010dd:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
				precision = precision * 10 + ch - '0';
f01010e0:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01010e3:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f01010e7:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f01010ea:	8d 4a d0             	lea    -0x30(%edx),%ecx
f01010ed:	83 f9 09             	cmp    $0x9,%ecx
f01010f0:	77 55                	ja     f0101147 <vprintfmt+0xda>
			for (precision = 0; ; ++fmt) {
f01010f2:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f01010f5:	eb e9                	jmp    f01010e0 <vprintfmt+0x73>
			precision = va_arg(ap, int);
f01010f7:	8b 45 14             	mov    0x14(%ebp),%eax
f01010fa:	8b 00                	mov    (%eax),%eax
f01010fc:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01010ff:	8b 45 14             	mov    0x14(%ebp),%eax
f0101102:	8d 40 04             	lea    0x4(%eax),%eax
f0101105:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0101108:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f010110b:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f010110f:	79 91                	jns    f01010a2 <vprintfmt+0x35>
				width = precision, precision = -1;
f0101111:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101114:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101117:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f010111e:	eb 82                	jmp    f01010a2 <vprintfmt+0x35>
f0101120:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101123:	85 c0                	test   %eax,%eax
f0101125:	ba 00 00 00 00       	mov    $0x0,%edx
f010112a:	0f 49 d0             	cmovns %eax,%edx
f010112d:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0101130:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101133:	e9 6a ff ff ff       	jmp    f01010a2 <vprintfmt+0x35>
f0101138:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f010113b:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0101142:	e9 5b ff ff ff       	jmp    f01010a2 <vprintfmt+0x35>
f0101147:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f010114a:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010114d:	eb bc                	jmp    f010110b <vprintfmt+0x9e>
			lflag++;
f010114f:	83 c1 01             	add    $0x1,%ecx
		switch (ch = *(unsigned char *) fmt++) {
f0101152:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f0101155:	e9 48 ff ff ff       	jmp    f01010a2 <vprintfmt+0x35>
			putch(va_arg(ap, int), putdat);
f010115a:	8b 45 14             	mov    0x14(%ebp),%eax
f010115d:	8d 78 04             	lea    0x4(%eax),%edi
f0101160:	83 ec 08             	sub    $0x8,%esp
f0101163:	53                   	push   %ebx
f0101164:	ff 30                	pushl  (%eax)
f0101166:	ff d6                	call   *%esi
			break;
f0101168:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f010116b:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f010116e:	e9 cf 02 00 00       	jmp    f0101442 <vprintfmt+0x3d5>
			err = va_arg(ap, int);
f0101173:	8b 45 14             	mov    0x14(%ebp),%eax
f0101176:	8d 78 04             	lea    0x4(%eax),%edi
f0101179:	8b 00                	mov    (%eax),%eax
f010117b:	99                   	cltd   
f010117c:	31 d0                	xor    %edx,%eax
f010117e:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0101180:	83 f8 06             	cmp    $0x6,%eax
f0101183:	7f 23                	jg     f01011a8 <vprintfmt+0x13b>
f0101185:	8b 14 85 a4 21 10 f0 	mov    -0xfefde5c(,%eax,4),%edx
f010118c:	85 d2                	test   %edx,%edx
f010118e:	74 18                	je     f01011a8 <vprintfmt+0x13b>
				printfmt(putch, putdat, "%s", p);
f0101190:	52                   	push   %edx
f0101191:	68 fe 1e 10 f0       	push   $0xf0101efe
f0101196:	53                   	push   %ebx
f0101197:	56                   	push   %esi
f0101198:	e8 b3 fe ff ff       	call   f0101050 <printfmt>
f010119d:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f01011a0:	89 7d 14             	mov    %edi,0x14(%ebp)
f01011a3:	e9 9a 02 00 00       	jmp    f0101442 <vprintfmt+0x3d5>
				printfmt(putch, putdat, "error %d", err);
f01011a8:	50                   	push   %eax
f01011a9:	68 d8 1f 10 f0       	push   $0xf0101fd8
f01011ae:	53                   	push   %ebx
f01011af:	56                   	push   %esi
f01011b0:	e8 9b fe ff ff       	call   f0101050 <printfmt>
f01011b5:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f01011b8:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f01011bb:	e9 82 02 00 00       	jmp    f0101442 <vprintfmt+0x3d5>
			if ((p = va_arg(ap, char *)) == NULL)
f01011c0:	8b 45 14             	mov    0x14(%ebp),%eax
f01011c3:	83 c0 04             	add    $0x4,%eax
f01011c6:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01011c9:	8b 45 14             	mov    0x14(%ebp),%eax
f01011cc:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f01011ce:	85 ff                	test   %edi,%edi
f01011d0:	b8 d1 1f 10 f0       	mov    $0xf0101fd1,%eax
f01011d5:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f01011d8:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01011dc:	0f 8e bd 00 00 00    	jle    f010129f <vprintfmt+0x232>
f01011e2:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f01011e6:	75 0e                	jne    f01011f6 <vprintfmt+0x189>
f01011e8:	89 75 08             	mov    %esi,0x8(%ebp)
f01011eb:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01011ee:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01011f1:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f01011f4:	eb 6d                	jmp    f0101263 <vprintfmt+0x1f6>
				for (width -= strnlen(p, precision); width > 0; width--)
f01011f6:	83 ec 08             	sub    $0x8,%esp
f01011f9:	ff 75 d0             	pushl  -0x30(%ebp)
f01011fc:	57                   	push   %edi
f01011fd:	e8 50 04 00 00       	call   f0101652 <strnlen>
f0101202:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0101205:	29 c1                	sub    %eax,%ecx
f0101207:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f010120a:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f010120d:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0101211:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101214:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0101217:	89 cf                	mov    %ecx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f0101219:	eb 0f                	jmp    f010122a <vprintfmt+0x1bd>
					putch(padc, putdat);
f010121b:	83 ec 08             	sub    $0x8,%esp
f010121e:	53                   	push   %ebx
f010121f:	ff 75 e0             	pushl  -0x20(%ebp)
f0101222:	ff d6                	call   *%esi
				for (width -= strnlen(p, precision); width > 0; width--)
f0101224:	83 ef 01             	sub    $0x1,%edi
f0101227:	83 c4 10             	add    $0x10,%esp
f010122a:	85 ff                	test   %edi,%edi
f010122c:	7f ed                	jg     f010121b <vprintfmt+0x1ae>
f010122e:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101231:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0101234:	85 c9                	test   %ecx,%ecx
f0101236:	b8 00 00 00 00       	mov    $0x0,%eax
f010123b:	0f 49 c1             	cmovns %ecx,%eax
f010123e:	29 c1                	sub    %eax,%ecx
f0101240:	89 75 08             	mov    %esi,0x8(%ebp)
f0101243:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101246:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101249:	89 cb                	mov    %ecx,%ebx
f010124b:	eb 16                	jmp    f0101263 <vprintfmt+0x1f6>
				if (altflag && (ch < ' ' || ch > '~'))
f010124d:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0101251:	75 31                	jne    f0101284 <vprintfmt+0x217>
					putch(ch, putdat);
f0101253:	83 ec 08             	sub    $0x8,%esp
f0101256:	ff 75 0c             	pushl  0xc(%ebp)
f0101259:	50                   	push   %eax
f010125a:	ff 55 08             	call   *0x8(%ebp)
f010125d:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101260:	83 eb 01             	sub    $0x1,%ebx
f0101263:	83 c7 01             	add    $0x1,%edi
f0101266:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
f010126a:	0f be c2             	movsbl %dl,%eax
f010126d:	85 c0                	test   %eax,%eax
f010126f:	74 59                	je     f01012ca <vprintfmt+0x25d>
f0101271:	85 f6                	test   %esi,%esi
f0101273:	78 d8                	js     f010124d <vprintfmt+0x1e0>
f0101275:	83 ee 01             	sub    $0x1,%esi
f0101278:	79 d3                	jns    f010124d <vprintfmt+0x1e0>
f010127a:	89 df                	mov    %ebx,%edi
f010127c:	8b 75 08             	mov    0x8(%ebp),%esi
f010127f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101282:	eb 37                	jmp    f01012bb <vprintfmt+0x24e>
				if (altflag && (ch < ' ' || ch > '~'))
f0101284:	0f be d2             	movsbl %dl,%edx
f0101287:	83 ea 20             	sub    $0x20,%edx
f010128a:	83 fa 5e             	cmp    $0x5e,%edx
f010128d:	76 c4                	jbe    f0101253 <vprintfmt+0x1e6>
					putch('?', putdat);
f010128f:	83 ec 08             	sub    $0x8,%esp
f0101292:	ff 75 0c             	pushl  0xc(%ebp)
f0101295:	6a 3f                	push   $0x3f
f0101297:	ff 55 08             	call   *0x8(%ebp)
f010129a:	83 c4 10             	add    $0x10,%esp
f010129d:	eb c1                	jmp    f0101260 <vprintfmt+0x1f3>
f010129f:	89 75 08             	mov    %esi,0x8(%ebp)
f01012a2:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01012a5:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01012a8:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f01012ab:	eb b6                	jmp    f0101263 <vprintfmt+0x1f6>
				putch(' ', putdat);
f01012ad:	83 ec 08             	sub    $0x8,%esp
f01012b0:	53                   	push   %ebx
f01012b1:	6a 20                	push   $0x20
f01012b3:	ff d6                	call   *%esi
			for (; width > 0; width--)
f01012b5:	83 ef 01             	sub    $0x1,%edi
f01012b8:	83 c4 10             	add    $0x10,%esp
f01012bb:	85 ff                	test   %edi,%edi
f01012bd:	7f ee                	jg     f01012ad <vprintfmt+0x240>
			if ((p = va_arg(ap, char *)) == NULL)
f01012bf:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01012c2:	89 45 14             	mov    %eax,0x14(%ebp)
f01012c5:	e9 78 01 00 00       	jmp    f0101442 <vprintfmt+0x3d5>
f01012ca:	89 df                	mov    %ebx,%edi
f01012cc:	8b 75 08             	mov    0x8(%ebp),%esi
f01012cf:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01012d2:	eb e7                	jmp    f01012bb <vprintfmt+0x24e>
	if (lflag >= 2)
f01012d4:	83 f9 01             	cmp    $0x1,%ecx
f01012d7:	7e 3f                	jle    f0101318 <vprintfmt+0x2ab>
		return va_arg(*ap, long long);
f01012d9:	8b 45 14             	mov    0x14(%ebp),%eax
f01012dc:	8b 50 04             	mov    0x4(%eax),%edx
f01012df:	8b 00                	mov    (%eax),%eax
f01012e1:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01012e4:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01012e7:	8b 45 14             	mov    0x14(%ebp),%eax
f01012ea:	8d 40 08             	lea    0x8(%eax),%eax
f01012ed:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f01012f0:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01012f4:	79 5c                	jns    f0101352 <vprintfmt+0x2e5>
				putch('-', putdat);
f01012f6:	83 ec 08             	sub    $0x8,%esp
f01012f9:	53                   	push   %ebx
f01012fa:	6a 2d                	push   $0x2d
f01012fc:	ff d6                	call   *%esi
				num = -(long long) num;
f01012fe:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101301:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0101304:	f7 da                	neg    %edx
f0101306:	83 d1 00             	adc    $0x0,%ecx
f0101309:	f7 d9                	neg    %ecx
f010130b:	83 c4 10             	add    $0x10,%esp
			base = 10;
f010130e:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101313:	e9 10 01 00 00       	jmp    f0101428 <vprintfmt+0x3bb>
	else if (lflag)
f0101318:	85 c9                	test   %ecx,%ecx
f010131a:	75 1b                	jne    f0101337 <vprintfmt+0x2ca>
		return va_arg(*ap, int);
f010131c:	8b 45 14             	mov    0x14(%ebp),%eax
f010131f:	8b 00                	mov    (%eax),%eax
f0101321:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101324:	89 c1                	mov    %eax,%ecx
f0101326:	c1 f9 1f             	sar    $0x1f,%ecx
f0101329:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f010132c:	8b 45 14             	mov    0x14(%ebp),%eax
f010132f:	8d 40 04             	lea    0x4(%eax),%eax
f0101332:	89 45 14             	mov    %eax,0x14(%ebp)
f0101335:	eb b9                	jmp    f01012f0 <vprintfmt+0x283>
		return va_arg(*ap, long);
f0101337:	8b 45 14             	mov    0x14(%ebp),%eax
f010133a:	8b 00                	mov    (%eax),%eax
f010133c:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010133f:	89 c1                	mov    %eax,%ecx
f0101341:	c1 f9 1f             	sar    $0x1f,%ecx
f0101344:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0101347:	8b 45 14             	mov    0x14(%ebp),%eax
f010134a:	8d 40 04             	lea    0x4(%eax),%eax
f010134d:	89 45 14             	mov    %eax,0x14(%ebp)
f0101350:	eb 9e                	jmp    f01012f0 <vprintfmt+0x283>
			num = getint(&ap, lflag);
f0101352:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101355:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f0101358:	b8 0a 00 00 00       	mov    $0xa,%eax
f010135d:	e9 c6 00 00 00       	jmp    f0101428 <vprintfmt+0x3bb>
	if (lflag >= 2)
f0101362:	83 f9 01             	cmp    $0x1,%ecx
f0101365:	7e 18                	jle    f010137f <vprintfmt+0x312>
		return va_arg(*ap, unsigned long long);
f0101367:	8b 45 14             	mov    0x14(%ebp),%eax
f010136a:	8b 10                	mov    (%eax),%edx
f010136c:	8b 48 04             	mov    0x4(%eax),%ecx
f010136f:	8d 40 08             	lea    0x8(%eax),%eax
f0101372:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0101375:	b8 0a 00 00 00       	mov    $0xa,%eax
f010137a:	e9 a9 00 00 00       	jmp    f0101428 <vprintfmt+0x3bb>
	else if (lflag)
f010137f:	85 c9                	test   %ecx,%ecx
f0101381:	75 1a                	jne    f010139d <vprintfmt+0x330>
		return va_arg(*ap, unsigned int);
f0101383:	8b 45 14             	mov    0x14(%ebp),%eax
f0101386:	8b 10                	mov    (%eax),%edx
f0101388:	b9 00 00 00 00       	mov    $0x0,%ecx
f010138d:	8d 40 04             	lea    0x4(%eax),%eax
f0101390:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0101393:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101398:	e9 8b 00 00 00       	jmp    f0101428 <vprintfmt+0x3bb>
		return va_arg(*ap, unsigned long);
f010139d:	8b 45 14             	mov    0x14(%ebp),%eax
f01013a0:	8b 10                	mov    (%eax),%edx
f01013a2:	b9 00 00 00 00       	mov    $0x0,%ecx
f01013a7:	8d 40 04             	lea    0x4(%eax),%eax
f01013aa:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01013ad:	b8 0a 00 00 00       	mov    $0xa,%eax
f01013b2:	eb 74                	jmp    f0101428 <vprintfmt+0x3bb>
	if (lflag >= 2)
f01013b4:	83 f9 01             	cmp    $0x1,%ecx
f01013b7:	7e 15                	jle    f01013ce <vprintfmt+0x361>
		return va_arg(*ap, unsigned long long);
f01013b9:	8b 45 14             	mov    0x14(%ebp),%eax
f01013bc:	8b 10                	mov    (%eax),%edx
f01013be:	8b 48 04             	mov    0x4(%eax),%ecx
f01013c1:	8d 40 08             	lea    0x8(%eax),%eax
f01013c4:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f01013c7:	b8 08 00 00 00       	mov    $0x8,%eax
f01013cc:	eb 5a                	jmp    f0101428 <vprintfmt+0x3bb>
	else if (lflag)
f01013ce:	85 c9                	test   %ecx,%ecx
f01013d0:	75 17                	jne    f01013e9 <vprintfmt+0x37c>
		return va_arg(*ap, unsigned int);
f01013d2:	8b 45 14             	mov    0x14(%ebp),%eax
f01013d5:	8b 10                	mov    (%eax),%edx
f01013d7:	b9 00 00 00 00       	mov    $0x0,%ecx
f01013dc:	8d 40 04             	lea    0x4(%eax),%eax
f01013df:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f01013e2:	b8 08 00 00 00       	mov    $0x8,%eax
f01013e7:	eb 3f                	jmp    f0101428 <vprintfmt+0x3bb>
		return va_arg(*ap, unsigned long);
f01013e9:	8b 45 14             	mov    0x14(%ebp),%eax
f01013ec:	8b 10                	mov    (%eax),%edx
f01013ee:	b9 00 00 00 00       	mov    $0x0,%ecx
f01013f3:	8d 40 04             	lea    0x4(%eax),%eax
f01013f6:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f01013f9:	b8 08 00 00 00       	mov    $0x8,%eax
f01013fe:	eb 28                	jmp    f0101428 <vprintfmt+0x3bb>
			putch('0', putdat);
f0101400:	83 ec 08             	sub    $0x8,%esp
f0101403:	53                   	push   %ebx
f0101404:	6a 30                	push   $0x30
f0101406:	ff d6                	call   *%esi
			putch('x', putdat);
f0101408:	83 c4 08             	add    $0x8,%esp
f010140b:	53                   	push   %ebx
f010140c:	6a 78                	push   $0x78
f010140e:	ff d6                	call   *%esi
			num = (unsigned long long)
f0101410:	8b 45 14             	mov    0x14(%ebp),%eax
f0101413:	8b 10                	mov    (%eax),%edx
f0101415:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f010141a:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f010141d:	8d 40 04             	lea    0x4(%eax),%eax
f0101420:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101423:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f0101428:	83 ec 0c             	sub    $0xc,%esp
f010142b:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f010142f:	57                   	push   %edi
f0101430:	ff 75 e0             	pushl  -0x20(%ebp)
f0101433:	50                   	push   %eax
f0101434:	51                   	push   %ecx
f0101435:	52                   	push   %edx
f0101436:	89 da                	mov    %ebx,%edx
f0101438:	89 f0                	mov    %esi,%eax
f010143a:	e8 45 fb ff ff       	call   f0100f84 <printnum>
			break;
f010143f:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f0101442:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0101445:	83 c7 01             	add    $0x1,%edi
f0101448:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f010144c:	83 f8 25             	cmp    $0x25,%eax
f010144f:	0f 84 2f fc ff ff    	je     f0101084 <vprintfmt+0x17>
			if (ch == '\0')
f0101455:	85 c0                	test   %eax,%eax
f0101457:	0f 84 8b 00 00 00    	je     f01014e8 <vprintfmt+0x47b>
			putch(ch, putdat);
f010145d:	83 ec 08             	sub    $0x8,%esp
f0101460:	53                   	push   %ebx
f0101461:	50                   	push   %eax
f0101462:	ff d6                	call   *%esi
f0101464:	83 c4 10             	add    $0x10,%esp
f0101467:	eb dc                	jmp    f0101445 <vprintfmt+0x3d8>
	if (lflag >= 2)
f0101469:	83 f9 01             	cmp    $0x1,%ecx
f010146c:	7e 15                	jle    f0101483 <vprintfmt+0x416>
		return va_arg(*ap, unsigned long long);
f010146e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101471:	8b 10                	mov    (%eax),%edx
f0101473:	8b 48 04             	mov    0x4(%eax),%ecx
f0101476:	8d 40 08             	lea    0x8(%eax),%eax
f0101479:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010147c:	b8 10 00 00 00       	mov    $0x10,%eax
f0101481:	eb a5                	jmp    f0101428 <vprintfmt+0x3bb>
	else if (lflag)
f0101483:	85 c9                	test   %ecx,%ecx
f0101485:	75 17                	jne    f010149e <vprintfmt+0x431>
		return va_arg(*ap, unsigned int);
f0101487:	8b 45 14             	mov    0x14(%ebp),%eax
f010148a:	8b 10                	mov    (%eax),%edx
f010148c:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101491:	8d 40 04             	lea    0x4(%eax),%eax
f0101494:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101497:	b8 10 00 00 00       	mov    $0x10,%eax
f010149c:	eb 8a                	jmp    f0101428 <vprintfmt+0x3bb>
		return va_arg(*ap, unsigned long);
f010149e:	8b 45 14             	mov    0x14(%ebp),%eax
f01014a1:	8b 10                	mov    (%eax),%edx
f01014a3:	b9 00 00 00 00       	mov    $0x0,%ecx
f01014a8:	8d 40 04             	lea    0x4(%eax),%eax
f01014ab:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01014ae:	b8 10 00 00 00       	mov    $0x10,%eax
f01014b3:	e9 70 ff ff ff       	jmp    f0101428 <vprintfmt+0x3bb>
			putch(ch, putdat);
f01014b8:	83 ec 08             	sub    $0x8,%esp
f01014bb:	53                   	push   %ebx
f01014bc:	6a 25                	push   $0x25
f01014be:	ff d6                	call   *%esi
			break;
f01014c0:	83 c4 10             	add    $0x10,%esp
f01014c3:	e9 7a ff ff ff       	jmp    f0101442 <vprintfmt+0x3d5>
			putch('%', putdat);
f01014c8:	83 ec 08             	sub    $0x8,%esp
f01014cb:	53                   	push   %ebx
f01014cc:	6a 25                	push   $0x25
f01014ce:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01014d0:	83 c4 10             	add    $0x10,%esp
f01014d3:	89 f8                	mov    %edi,%eax
f01014d5:	eb 03                	jmp    f01014da <vprintfmt+0x46d>
f01014d7:	83 e8 01             	sub    $0x1,%eax
f01014da:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f01014de:	75 f7                	jne    f01014d7 <vprintfmt+0x46a>
f01014e0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01014e3:	e9 5a ff ff ff       	jmp    f0101442 <vprintfmt+0x3d5>
}
f01014e8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01014eb:	5b                   	pop    %ebx
f01014ec:	5e                   	pop    %esi
f01014ed:	5f                   	pop    %edi
f01014ee:	5d                   	pop    %ebp
f01014ef:	c3                   	ret    

f01014f0 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01014f0:	55                   	push   %ebp
f01014f1:	89 e5                	mov    %esp,%ebp
f01014f3:	83 ec 18             	sub    $0x18,%esp
f01014f6:	8b 45 08             	mov    0x8(%ebp),%eax
f01014f9:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01014fc:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01014ff:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101503:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101506:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010150d:	85 c0                	test   %eax,%eax
f010150f:	74 26                	je     f0101537 <vsnprintf+0x47>
f0101511:	85 d2                	test   %edx,%edx
f0101513:	7e 22                	jle    f0101537 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101515:	ff 75 14             	pushl  0x14(%ebp)
f0101518:	ff 75 10             	pushl  0x10(%ebp)
f010151b:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010151e:	50                   	push   %eax
f010151f:	68 33 10 10 f0       	push   $0xf0101033
f0101524:	e8 44 fb ff ff       	call   f010106d <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101529:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010152c:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010152f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101532:	83 c4 10             	add    $0x10,%esp
}
f0101535:	c9                   	leave  
f0101536:	c3                   	ret    
		return -E_INVAL;
f0101537:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f010153c:	eb f7                	jmp    f0101535 <vsnprintf+0x45>

f010153e <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010153e:	55                   	push   %ebp
f010153f:	89 e5                	mov    %esp,%ebp
f0101541:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101544:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101547:	50                   	push   %eax
f0101548:	ff 75 10             	pushl  0x10(%ebp)
f010154b:	ff 75 0c             	pushl  0xc(%ebp)
f010154e:	ff 75 08             	pushl  0x8(%ebp)
f0101551:	e8 9a ff ff ff       	call   f01014f0 <vsnprintf>
	va_end(ap);

	return rc;
}
f0101556:	c9                   	leave  
f0101557:	c3                   	ret    

f0101558 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101558:	55                   	push   %ebp
f0101559:	89 e5                	mov    %esp,%ebp
f010155b:	57                   	push   %edi
f010155c:	56                   	push   %esi
f010155d:	53                   	push   %ebx
f010155e:	83 ec 0c             	sub    $0xc,%esp
f0101561:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0101564:	85 c0                	test   %eax,%eax
f0101566:	74 11                	je     f0101579 <readline+0x21>
		cprintf("%s", prompt);
f0101568:	83 ec 08             	sub    $0x8,%esp
f010156b:	50                   	push   %eax
f010156c:	68 fe 1e 10 f0       	push   $0xf0101efe
f0101571:	e8 0e f1 ff ff       	call   f0100684 <cprintf>
f0101576:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0101579:	83 ec 0c             	sub    $0xc,%esp
f010157c:	6a 00                	push   $0x0
f010157e:	e8 be f0 ff ff       	call   f0100641 <iscons>
f0101583:	89 c7                	mov    %eax,%edi
f0101585:	83 c4 10             	add    $0x10,%esp
	i = 0;
f0101588:	be 00 00 00 00       	mov    $0x0,%esi
f010158d:	eb 3f                	jmp    f01015ce <readline+0x76>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f010158f:	83 ec 08             	sub    $0x8,%esp
f0101592:	50                   	push   %eax
f0101593:	68 c0 21 10 f0       	push   $0xf01021c0
f0101598:	e8 e7 f0 ff ff       	call   f0100684 <cprintf>
			return NULL;
f010159d:	83 c4 10             	add    $0x10,%esp
f01015a0:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f01015a5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01015a8:	5b                   	pop    %ebx
f01015a9:	5e                   	pop    %esi
f01015aa:	5f                   	pop    %edi
f01015ab:	5d                   	pop    %ebp
f01015ac:	c3                   	ret    
			if (echoing)
f01015ad:	85 ff                	test   %edi,%edi
f01015af:	75 05                	jne    f01015b6 <readline+0x5e>
			i--;
f01015b1:	83 ee 01             	sub    $0x1,%esi
f01015b4:	eb 18                	jmp    f01015ce <readline+0x76>
				cputchar('\b');
f01015b6:	83 ec 0c             	sub    $0xc,%esp
f01015b9:	6a 08                	push   $0x8
f01015bb:	e8 60 f0 ff ff       	call   f0100620 <cputchar>
f01015c0:	83 c4 10             	add    $0x10,%esp
f01015c3:	eb ec                	jmp    f01015b1 <readline+0x59>
			buf[i++] = c;
f01015c5:	88 9e 40 35 11 f0    	mov    %bl,-0xfeecac0(%esi)
f01015cb:	8d 76 01             	lea    0x1(%esi),%esi
		c = getchar();
f01015ce:	e8 5d f0 ff ff       	call   f0100630 <getchar>
f01015d3:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01015d5:	85 c0                	test   %eax,%eax
f01015d7:	78 b6                	js     f010158f <readline+0x37>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01015d9:	83 f8 08             	cmp    $0x8,%eax
f01015dc:	0f 94 c2             	sete   %dl
f01015df:	83 f8 7f             	cmp    $0x7f,%eax
f01015e2:	0f 94 c0             	sete   %al
f01015e5:	08 c2                	or     %al,%dl
f01015e7:	74 04                	je     f01015ed <readline+0x95>
f01015e9:	85 f6                	test   %esi,%esi
f01015eb:	7f c0                	jg     f01015ad <readline+0x55>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01015ed:	83 fb 1f             	cmp    $0x1f,%ebx
f01015f0:	7e 1a                	jle    f010160c <readline+0xb4>
f01015f2:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01015f8:	7f 12                	jg     f010160c <readline+0xb4>
			if (echoing)
f01015fa:	85 ff                	test   %edi,%edi
f01015fc:	74 c7                	je     f01015c5 <readline+0x6d>
				cputchar(c);
f01015fe:	83 ec 0c             	sub    $0xc,%esp
f0101601:	53                   	push   %ebx
f0101602:	e8 19 f0 ff ff       	call   f0100620 <cputchar>
f0101607:	83 c4 10             	add    $0x10,%esp
f010160a:	eb b9                	jmp    f01015c5 <readline+0x6d>
		} else if (c == '\n' || c == '\r') {
f010160c:	83 fb 0a             	cmp    $0xa,%ebx
f010160f:	74 05                	je     f0101616 <readline+0xbe>
f0101611:	83 fb 0d             	cmp    $0xd,%ebx
f0101614:	75 b8                	jne    f01015ce <readline+0x76>
			if (echoing)
f0101616:	85 ff                	test   %edi,%edi
f0101618:	75 11                	jne    f010162b <readline+0xd3>
			buf[i] = 0;
f010161a:	c6 86 40 35 11 f0 00 	movb   $0x0,-0xfeecac0(%esi)
			return buf;
f0101621:	b8 40 35 11 f0       	mov    $0xf0113540,%eax
f0101626:	e9 7a ff ff ff       	jmp    f01015a5 <readline+0x4d>
				cputchar('\n');
f010162b:	83 ec 0c             	sub    $0xc,%esp
f010162e:	6a 0a                	push   $0xa
f0101630:	e8 eb ef ff ff       	call   f0100620 <cputchar>
f0101635:	83 c4 10             	add    $0x10,%esp
f0101638:	eb e0                	jmp    f010161a <readline+0xc2>

f010163a <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f010163a:	55                   	push   %ebp
f010163b:	89 e5                	mov    %esp,%ebp
f010163d:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101640:	b8 00 00 00 00       	mov    $0x0,%eax
f0101645:	eb 03                	jmp    f010164a <strlen+0x10>
		n++;
f0101647:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f010164a:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f010164e:	75 f7                	jne    f0101647 <strlen+0xd>
	return n;
}
f0101650:	5d                   	pop    %ebp
f0101651:	c3                   	ret    

f0101652 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101652:	55                   	push   %ebp
f0101653:	89 e5                	mov    %esp,%ebp
f0101655:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101658:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010165b:	b8 00 00 00 00       	mov    $0x0,%eax
f0101660:	eb 03                	jmp    f0101665 <strnlen+0x13>
		n++;
f0101662:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101665:	39 d0                	cmp    %edx,%eax
f0101667:	74 06                	je     f010166f <strnlen+0x1d>
f0101669:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f010166d:	75 f3                	jne    f0101662 <strnlen+0x10>
	return n;
}
f010166f:	5d                   	pop    %ebp
f0101670:	c3                   	ret    

f0101671 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101671:	55                   	push   %ebp
f0101672:	89 e5                	mov    %esp,%ebp
f0101674:	53                   	push   %ebx
f0101675:	8b 45 08             	mov    0x8(%ebp),%eax
f0101678:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f010167b:	89 c2                	mov    %eax,%edx
f010167d:	83 c1 01             	add    $0x1,%ecx
f0101680:	83 c2 01             	add    $0x1,%edx
f0101683:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0101687:	88 5a ff             	mov    %bl,-0x1(%edx)
f010168a:	84 db                	test   %bl,%bl
f010168c:	75 ef                	jne    f010167d <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f010168e:	5b                   	pop    %ebx
f010168f:	5d                   	pop    %ebp
f0101690:	c3                   	ret    

f0101691 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101691:	55                   	push   %ebp
f0101692:	89 e5                	mov    %esp,%ebp
f0101694:	53                   	push   %ebx
f0101695:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101698:	53                   	push   %ebx
f0101699:	e8 9c ff ff ff       	call   f010163a <strlen>
f010169e:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f01016a1:	ff 75 0c             	pushl  0xc(%ebp)
f01016a4:	01 d8                	add    %ebx,%eax
f01016a6:	50                   	push   %eax
f01016a7:	e8 c5 ff ff ff       	call   f0101671 <strcpy>
	return dst;
}
f01016ac:	89 d8                	mov    %ebx,%eax
f01016ae:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01016b1:	c9                   	leave  
f01016b2:	c3                   	ret    

f01016b3 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01016b3:	55                   	push   %ebp
f01016b4:	89 e5                	mov    %esp,%ebp
f01016b6:	56                   	push   %esi
f01016b7:	53                   	push   %ebx
f01016b8:	8b 75 08             	mov    0x8(%ebp),%esi
f01016bb:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01016be:	89 f3                	mov    %esi,%ebx
f01016c0:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01016c3:	89 f2                	mov    %esi,%edx
f01016c5:	eb 0f                	jmp    f01016d6 <strncpy+0x23>
		*dst++ = *src;
f01016c7:	83 c2 01             	add    $0x1,%edx
f01016ca:	0f b6 01             	movzbl (%ecx),%eax
f01016cd:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01016d0:	80 39 01             	cmpb   $0x1,(%ecx)
f01016d3:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f01016d6:	39 da                	cmp    %ebx,%edx
f01016d8:	75 ed                	jne    f01016c7 <strncpy+0x14>
	}
	return ret;
}
f01016da:	89 f0                	mov    %esi,%eax
f01016dc:	5b                   	pop    %ebx
f01016dd:	5e                   	pop    %esi
f01016de:	5d                   	pop    %ebp
f01016df:	c3                   	ret    

f01016e0 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01016e0:	55                   	push   %ebp
f01016e1:	89 e5                	mov    %esp,%ebp
f01016e3:	56                   	push   %esi
f01016e4:	53                   	push   %ebx
f01016e5:	8b 75 08             	mov    0x8(%ebp),%esi
f01016e8:	8b 55 0c             	mov    0xc(%ebp),%edx
f01016eb:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01016ee:	89 f0                	mov    %esi,%eax
f01016f0:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01016f4:	85 c9                	test   %ecx,%ecx
f01016f6:	75 0b                	jne    f0101703 <strlcpy+0x23>
f01016f8:	eb 17                	jmp    f0101711 <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01016fa:	83 c2 01             	add    $0x1,%edx
f01016fd:	83 c0 01             	add    $0x1,%eax
f0101700:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f0101703:	39 d8                	cmp    %ebx,%eax
f0101705:	74 07                	je     f010170e <strlcpy+0x2e>
f0101707:	0f b6 0a             	movzbl (%edx),%ecx
f010170a:	84 c9                	test   %cl,%cl
f010170c:	75 ec                	jne    f01016fa <strlcpy+0x1a>
		*dst = '\0';
f010170e:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0101711:	29 f0                	sub    %esi,%eax
}
f0101713:	5b                   	pop    %ebx
f0101714:	5e                   	pop    %esi
f0101715:	5d                   	pop    %ebp
f0101716:	c3                   	ret    

f0101717 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101717:	55                   	push   %ebp
f0101718:	89 e5                	mov    %esp,%ebp
f010171a:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010171d:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101720:	eb 06                	jmp    f0101728 <strcmp+0x11>
		p++, q++;
f0101722:	83 c1 01             	add    $0x1,%ecx
f0101725:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f0101728:	0f b6 01             	movzbl (%ecx),%eax
f010172b:	84 c0                	test   %al,%al
f010172d:	74 04                	je     f0101733 <strcmp+0x1c>
f010172f:	3a 02                	cmp    (%edx),%al
f0101731:	74 ef                	je     f0101722 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101733:	0f b6 c0             	movzbl %al,%eax
f0101736:	0f b6 12             	movzbl (%edx),%edx
f0101739:	29 d0                	sub    %edx,%eax
}
f010173b:	5d                   	pop    %ebp
f010173c:	c3                   	ret    

f010173d <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010173d:	55                   	push   %ebp
f010173e:	89 e5                	mov    %esp,%ebp
f0101740:	53                   	push   %ebx
f0101741:	8b 45 08             	mov    0x8(%ebp),%eax
f0101744:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101747:	89 c3                	mov    %eax,%ebx
f0101749:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f010174c:	eb 06                	jmp    f0101754 <strncmp+0x17>
		n--, p++, q++;
f010174e:	83 c0 01             	add    $0x1,%eax
f0101751:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f0101754:	39 d8                	cmp    %ebx,%eax
f0101756:	74 16                	je     f010176e <strncmp+0x31>
f0101758:	0f b6 08             	movzbl (%eax),%ecx
f010175b:	84 c9                	test   %cl,%cl
f010175d:	74 04                	je     f0101763 <strncmp+0x26>
f010175f:	3a 0a                	cmp    (%edx),%cl
f0101761:	74 eb                	je     f010174e <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101763:	0f b6 00             	movzbl (%eax),%eax
f0101766:	0f b6 12             	movzbl (%edx),%edx
f0101769:	29 d0                	sub    %edx,%eax
}
f010176b:	5b                   	pop    %ebx
f010176c:	5d                   	pop    %ebp
f010176d:	c3                   	ret    
		return 0;
f010176e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101773:	eb f6                	jmp    f010176b <strncmp+0x2e>

f0101775 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101775:	55                   	push   %ebp
f0101776:	89 e5                	mov    %esp,%ebp
f0101778:	8b 45 08             	mov    0x8(%ebp),%eax
f010177b:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010177f:	0f b6 10             	movzbl (%eax),%edx
f0101782:	84 d2                	test   %dl,%dl
f0101784:	74 09                	je     f010178f <strchr+0x1a>
		if (*s == c)
f0101786:	38 ca                	cmp    %cl,%dl
f0101788:	74 0a                	je     f0101794 <strchr+0x1f>
	for (; *s; s++)
f010178a:	83 c0 01             	add    $0x1,%eax
f010178d:	eb f0                	jmp    f010177f <strchr+0xa>
			return (char *) s;
	return 0;
f010178f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101794:	5d                   	pop    %ebp
f0101795:	c3                   	ret    

f0101796 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101796:	55                   	push   %ebp
f0101797:	89 e5                	mov    %esp,%ebp
f0101799:	8b 45 08             	mov    0x8(%ebp),%eax
f010179c:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01017a0:	eb 03                	jmp    f01017a5 <strfind+0xf>
f01017a2:	83 c0 01             	add    $0x1,%eax
f01017a5:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01017a8:	38 ca                	cmp    %cl,%dl
f01017aa:	74 04                	je     f01017b0 <strfind+0x1a>
f01017ac:	84 d2                	test   %dl,%dl
f01017ae:	75 f2                	jne    f01017a2 <strfind+0xc>
			break;
	return (char *) s;
}
f01017b0:	5d                   	pop    %ebp
f01017b1:	c3                   	ret    

f01017b2 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01017b2:	55                   	push   %ebp
f01017b3:	89 e5                	mov    %esp,%ebp
f01017b5:	57                   	push   %edi
f01017b6:	56                   	push   %esi
f01017b7:	53                   	push   %ebx
f01017b8:	8b 7d 08             	mov    0x8(%ebp),%edi
f01017bb:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01017be:	85 c9                	test   %ecx,%ecx
f01017c0:	74 13                	je     f01017d5 <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01017c2:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01017c8:	75 05                	jne    f01017cf <memset+0x1d>
f01017ca:	f6 c1 03             	test   $0x3,%cl
f01017cd:	74 0d                	je     f01017dc <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01017cf:	8b 45 0c             	mov    0xc(%ebp),%eax
f01017d2:	fc                   	cld    
f01017d3:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01017d5:	89 f8                	mov    %edi,%eax
f01017d7:	5b                   	pop    %ebx
f01017d8:	5e                   	pop    %esi
f01017d9:	5f                   	pop    %edi
f01017da:	5d                   	pop    %ebp
f01017db:	c3                   	ret    
		c &= 0xFF;
f01017dc:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01017e0:	89 d3                	mov    %edx,%ebx
f01017e2:	c1 e3 08             	shl    $0x8,%ebx
f01017e5:	89 d0                	mov    %edx,%eax
f01017e7:	c1 e0 18             	shl    $0x18,%eax
f01017ea:	89 d6                	mov    %edx,%esi
f01017ec:	c1 e6 10             	shl    $0x10,%esi
f01017ef:	09 f0                	or     %esi,%eax
f01017f1:	09 c2                	or     %eax,%edx
f01017f3:	09 da                	or     %ebx,%edx
			:: "D" (v), "a" (c), "c" (n/4)
f01017f5:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f01017f8:	89 d0                	mov    %edx,%eax
f01017fa:	fc                   	cld    
f01017fb:	f3 ab                	rep stos %eax,%es:(%edi)
f01017fd:	eb d6                	jmp    f01017d5 <memset+0x23>

f01017ff <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01017ff:	55                   	push   %ebp
f0101800:	89 e5                	mov    %esp,%ebp
f0101802:	57                   	push   %edi
f0101803:	56                   	push   %esi
f0101804:	8b 45 08             	mov    0x8(%ebp),%eax
f0101807:	8b 75 0c             	mov    0xc(%ebp),%esi
f010180a:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010180d:	39 c6                	cmp    %eax,%esi
f010180f:	73 35                	jae    f0101846 <memmove+0x47>
f0101811:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0101814:	39 c2                	cmp    %eax,%edx
f0101816:	76 2e                	jbe    f0101846 <memmove+0x47>
		s += n;
		d += n;
f0101818:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010181b:	89 d6                	mov    %edx,%esi
f010181d:	09 fe                	or     %edi,%esi
f010181f:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101825:	74 0c                	je     f0101833 <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0101827:	83 ef 01             	sub    $0x1,%edi
f010182a:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f010182d:	fd                   	std    
f010182e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101830:	fc                   	cld    
f0101831:	eb 21                	jmp    f0101854 <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101833:	f6 c1 03             	test   $0x3,%cl
f0101836:	75 ef                	jne    f0101827 <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101838:	83 ef 04             	sub    $0x4,%edi
f010183b:	8d 72 fc             	lea    -0x4(%edx),%esi
f010183e:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f0101841:	fd                   	std    
f0101842:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101844:	eb ea                	jmp    f0101830 <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101846:	89 f2                	mov    %esi,%edx
f0101848:	09 c2                	or     %eax,%edx
f010184a:	f6 c2 03             	test   $0x3,%dl
f010184d:	74 09                	je     f0101858 <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010184f:	89 c7                	mov    %eax,%edi
f0101851:	fc                   	cld    
f0101852:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101854:	5e                   	pop    %esi
f0101855:	5f                   	pop    %edi
f0101856:	5d                   	pop    %ebp
f0101857:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101858:	f6 c1 03             	test   $0x3,%cl
f010185b:	75 f2                	jne    f010184f <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f010185d:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f0101860:	89 c7                	mov    %eax,%edi
f0101862:	fc                   	cld    
f0101863:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101865:	eb ed                	jmp    f0101854 <memmove+0x55>

f0101867 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0101867:	55                   	push   %ebp
f0101868:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f010186a:	ff 75 10             	pushl  0x10(%ebp)
f010186d:	ff 75 0c             	pushl  0xc(%ebp)
f0101870:	ff 75 08             	pushl  0x8(%ebp)
f0101873:	e8 87 ff ff ff       	call   f01017ff <memmove>
}
f0101878:	c9                   	leave  
f0101879:	c3                   	ret    

f010187a <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010187a:	55                   	push   %ebp
f010187b:	89 e5                	mov    %esp,%ebp
f010187d:	56                   	push   %esi
f010187e:	53                   	push   %ebx
f010187f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101882:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101885:	89 c6                	mov    %eax,%esi
f0101887:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010188a:	39 f0                	cmp    %esi,%eax
f010188c:	74 1c                	je     f01018aa <memcmp+0x30>
		if (*s1 != *s2)
f010188e:	0f b6 08             	movzbl (%eax),%ecx
f0101891:	0f b6 1a             	movzbl (%edx),%ebx
f0101894:	38 d9                	cmp    %bl,%cl
f0101896:	75 08                	jne    f01018a0 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f0101898:	83 c0 01             	add    $0x1,%eax
f010189b:	83 c2 01             	add    $0x1,%edx
f010189e:	eb ea                	jmp    f010188a <memcmp+0x10>
			return (int) *s1 - (int) *s2;
f01018a0:	0f b6 c1             	movzbl %cl,%eax
f01018a3:	0f b6 db             	movzbl %bl,%ebx
f01018a6:	29 d8                	sub    %ebx,%eax
f01018a8:	eb 05                	jmp    f01018af <memcmp+0x35>
	}

	return 0;
f01018aa:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01018af:	5b                   	pop    %ebx
f01018b0:	5e                   	pop    %esi
f01018b1:	5d                   	pop    %ebp
f01018b2:	c3                   	ret    

f01018b3 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01018b3:	55                   	push   %ebp
f01018b4:	89 e5                	mov    %esp,%ebp
f01018b6:	8b 45 08             	mov    0x8(%ebp),%eax
f01018b9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f01018bc:	89 c2                	mov    %eax,%edx
f01018be:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01018c1:	39 d0                	cmp    %edx,%eax
f01018c3:	73 09                	jae    f01018ce <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f01018c5:	38 08                	cmp    %cl,(%eax)
f01018c7:	74 05                	je     f01018ce <memfind+0x1b>
	for (; s < ends; s++)
f01018c9:	83 c0 01             	add    $0x1,%eax
f01018cc:	eb f3                	jmp    f01018c1 <memfind+0xe>
			break;
	return (void *) s;
}
f01018ce:	5d                   	pop    %ebp
f01018cf:	c3                   	ret    

f01018d0 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01018d0:	55                   	push   %ebp
f01018d1:	89 e5                	mov    %esp,%ebp
f01018d3:	57                   	push   %edi
f01018d4:	56                   	push   %esi
f01018d5:	53                   	push   %ebx
f01018d6:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01018d9:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01018dc:	eb 03                	jmp    f01018e1 <strtol+0x11>
		s++;
f01018de:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f01018e1:	0f b6 01             	movzbl (%ecx),%eax
f01018e4:	3c 20                	cmp    $0x20,%al
f01018e6:	74 f6                	je     f01018de <strtol+0xe>
f01018e8:	3c 09                	cmp    $0x9,%al
f01018ea:	74 f2                	je     f01018de <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f01018ec:	3c 2b                	cmp    $0x2b,%al
f01018ee:	74 2e                	je     f010191e <strtol+0x4e>
	int neg = 0;
f01018f0:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f01018f5:	3c 2d                	cmp    $0x2d,%al
f01018f7:	74 2f                	je     f0101928 <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01018f9:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01018ff:	75 05                	jne    f0101906 <strtol+0x36>
f0101901:	80 39 30             	cmpb   $0x30,(%ecx)
f0101904:	74 2c                	je     f0101932 <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101906:	85 db                	test   %ebx,%ebx
f0101908:	75 0a                	jne    f0101914 <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010190a:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
f010190f:	80 39 30             	cmpb   $0x30,(%ecx)
f0101912:	74 28                	je     f010193c <strtol+0x6c>
		base = 10;
f0101914:	b8 00 00 00 00       	mov    $0x0,%eax
f0101919:	89 5d 10             	mov    %ebx,0x10(%ebp)
f010191c:	eb 50                	jmp    f010196e <strtol+0x9e>
		s++;
f010191e:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f0101921:	bf 00 00 00 00       	mov    $0x0,%edi
f0101926:	eb d1                	jmp    f01018f9 <strtol+0x29>
		s++, neg = 1;
f0101928:	83 c1 01             	add    $0x1,%ecx
f010192b:	bf 01 00 00 00       	mov    $0x1,%edi
f0101930:	eb c7                	jmp    f01018f9 <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101932:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0101936:	74 0e                	je     f0101946 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f0101938:	85 db                	test   %ebx,%ebx
f010193a:	75 d8                	jne    f0101914 <strtol+0x44>
		s++, base = 8;
f010193c:	83 c1 01             	add    $0x1,%ecx
f010193f:	bb 08 00 00 00       	mov    $0x8,%ebx
f0101944:	eb ce                	jmp    f0101914 <strtol+0x44>
		s += 2, base = 16;
f0101946:	83 c1 02             	add    $0x2,%ecx
f0101949:	bb 10 00 00 00       	mov    $0x10,%ebx
f010194e:	eb c4                	jmp    f0101914 <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f0101950:	8d 72 9f             	lea    -0x61(%edx),%esi
f0101953:	89 f3                	mov    %esi,%ebx
f0101955:	80 fb 19             	cmp    $0x19,%bl
f0101958:	77 29                	ja     f0101983 <strtol+0xb3>
			dig = *s - 'a' + 10;
f010195a:	0f be d2             	movsbl %dl,%edx
f010195d:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0101960:	3b 55 10             	cmp    0x10(%ebp),%edx
f0101963:	7d 30                	jge    f0101995 <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f0101965:	83 c1 01             	add    $0x1,%ecx
f0101968:	0f af 45 10          	imul   0x10(%ebp),%eax
f010196c:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f010196e:	0f b6 11             	movzbl (%ecx),%edx
f0101971:	8d 72 d0             	lea    -0x30(%edx),%esi
f0101974:	89 f3                	mov    %esi,%ebx
f0101976:	80 fb 09             	cmp    $0x9,%bl
f0101979:	77 d5                	ja     f0101950 <strtol+0x80>
			dig = *s - '0';
f010197b:	0f be d2             	movsbl %dl,%edx
f010197e:	83 ea 30             	sub    $0x30,%edx
f0101981:	eb dd                	jmp    f0101960 <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
f0101983:	8d 72 bf             	lea    -0x41(%edx),%esi
f0101986:	89 f3                	mov    %esi,%ebx
f0101988:	80 fb 19             	cmp    $0x19,%bl
f010198b:	77 08                	ja     f0101995 <strtol+0xc5>
			dig = *s - 'A' + 10;
f010198d:	0f be d2             	movsbl %dl,%edx
f0101990:	83 ea 37             	sub    $0x37,%edx
f0101993:	eb cb                	jmp    f0101960 <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
f0101995:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101999:	74 05                	je     f01019a0 <strtol+0xd0>
		*endptr = (char *) s;
f010199b:	8b 75 0c             	mov    0xc(%ebp),%esi
f010199e:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f01019a0:	89 c2                	mov    %eax,%edx
f01019a2:	f7 da                	neg    %edx
f01019a4:	85 ff                	test   %edi,%edi
f01019a6:	0f 45 c2             	cmovne %edx,%eax
}
f01019a9:	5b                   	pop    %ebx
f01019aa:	5e                   	pop    %esi
f01019ab:	5f                   	pop    %edi
f01019ac:	5d                   	pop    %ebp
f01019ad:	c3                   	ret    
f01019ae:	66 90                	xchg   %ax,%ax

f01019b0 <__udivdi3>:
f01019b0:	55                   	push   %ebp
f01019b1:	57                   	push   %edi
f01019b2:	56                   	push   %esi
f01019b3:	53                   	push   %ebx
f01019b4:	83 ec 1c             	sub    $0x1c,%esp
f01019b7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01019bb:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f01019bf:	8b 74 24 34          	mov    0x34(%esp),%esi
f01019c3:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f01019c7:	85 d2                	test   %edx,%edx
f01019c9:	75 35                	jne    f0101a00 <__udivdi3+0x50>
f01019cb:	39 f3                	cmp    %esi,%ebx
f01019cd:	0f 87 bd 00 00 00    	ja     f0101a90 <__udivdi3+0xe0>
f01019d3:	85 db                	test   %ebx,%ebx
f01019d5:	89 d9                	mov    %ebx,%ecx
f01019d7:	75 0b                	jne    f01019e4 <__udivdi3+0x34>
f01019d9:	b8 01 00 00 00       	mov    $0x1,%eax
f01019de:	31 d2                	xor    %edx,%edx
f01019e0:	f7 f3                	div    %ebx
f01019e2:	89 c1                	mov    %eax,%ecx
f01019e4:	31 d2                	xor    %edx,%edx
f01019e6:	89 f0                	mov    %esi,%eax
f01019e8:	f7 f1                	div    %ecx
f01019ea:	89 c6                	mov    %eax,%esi
f01019ec:	89 e8                	mov    %ebp,%eax
f01019ee:	89 f7                	mov    %esi,%edi
f01019f0:	f7 f1                	div    %ecx
f01019f2:	89 fa                	mov    %edi,%edx
f01019f4:	83 c4 1c             	add    $0x1c,%esp
f01019f7:	5b                   	pop    %ebx
f01019f8:	5e                   	pop    %esi
f01019f9:	5f                   	pop    %edi
f01019fa:	5d                   	pop    %ebp
f01019fb:	c3                   	ret    
f01019fc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101a00:	39 f2                	cmp    %esi,%edx
f0101a02:	77 7c                	ja     f0101a80 <__udivdi3+0xd0>
f0101a04:	0f bd fa             	bsr    %edx,%edi
f0101a07:	83 f7 1f             	xor    $0x1f,%edi
f0101a0a:	0f 84 98 00 00 00    	je     f0101aa8 <__udivdi3+0xf8>
f0101a10:	89 f9                	mov    %edi,%ecx
f0101a12:	b8 20 00 00 00       	mov    $0x20,%eax
f0101a17:	29 f8                	sub    %edi,%eax
f0101a19:	d3 e2                	shl    %cl,%edx
f0101a1b:	89 54 24 08          	mov    %edx,0x8(%esp)
f0101a1f:	89 c1                	mov    %eax,%ecx
f0101a21:	89 da                	mov    %ebx,%edx
f0101a23:	d3 ea                	shr    %cl,%edx
f0101a25:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0101a29:	09 d1                	or     %edx,%ecx
f0101a2b:	89 f2                	mov    %esi,%edx
f0101a2d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101a31:	89 f9                	mov    %edi,%ecx
f0101a33:	d3 e3                	shl    %cl,%ebx
f0101a35:	89 c1                	mov    %eax,%ecx
f0101a37:	d3 ea                	shr    %cl,%edx
f0101a39:	89 f9                	mov    %edi,%ecx
f0101a3b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0101a3f:	d3 e6                	shl    %cl,%esi
f0101a41:	89 eb                	mov    %ebp,%ebx
f0101a43:	89 c1                	mov    %eax,%ecx
f0101a45:	d3 eb                	shr    %cl,%ebx
f0101a47:	09 de                	or     %ebx,%esi
f0101a49:	89 f0                	mov    %esi,%eax
f0101a4b:	f7 74 24 08          	divl   0x8(%esp)
f0101a4f:	89 d6                	mov    %edx,%esi
f0101a51:	89 c3                	mov    %eax,%ebx
f0101a53:	f7 64 24 0c          	mull   0xc(%esp)
f0101a57:	39 d6                	cmp    %edx,%esi
f0101a59:	72 0c                	jb     f0101a67 <__udivdi3+0xb7>
f0101a5b:	89 f9                	mov    %edi,%ecx
f0101a5d:	d3 e5                	shl    %cl,%ebp
f0101a5f:	39 c5                	cmp    %eax,%ebp
f0101a61:	73 5d                	jae    f0101ac0 <__udivdi3+0x110>
f0101a63:	39 d6                	cmp    %edx,%esi
f0101a65:	75 59                	jne    f0101ac0 <__udivdi3+0x110>
f0101a67:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0101a6a:	31 ff                	xor    %edi,%edi
f0101a6c:	89 fa                	mov    %edi,%edx
f0101a6e:	83 c4 1c             	add    $0x1c,%esp
f0101a71:	5b                   	pop    %ebx
f0101a72:	5e                   	pop    %esi
f0101a73:	5f                   	pop    %edi
f0101a74:	5d                   	pop    %ebp
f0101a75:	c3                   	ret    
f0101a76:	8d 76 00             	lea    0x0(%esi),%esi
f0101a79:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0101a80:	31 ff                	xor    %edi,%edi
f0101a82:	31 c0                	xor    %eax,%eax
f0101a84:	89 fa                	mov    %edi,%edx
f0101a86:	83 c4 1c             	add    $0x1c,%esp
f0101a89:	5b                   	pop    %ebx
f0101a8a:	5e                   	pop    %esi
f0101a8b:	5f                   	pop    %edi
f0101a8c:	5d                   	pop    %ebp
f0101a8d:	c3                   	ret    
f0101a8e:	66 90                	xchg   %ax,%ax
f0101a90:	31 ff                	xor    %edi,%edi
f0101a92:	89 e8                	mov    %ebp,%eax
f0101a94:	89 f2                	mov    %esi,%edx
f0101a96:	f7 f3                	div    %ebx
f0101a98:	89 fa                	mov    %edi,%edx
f0101a9a:	83 c4 1c             	add    $0x1c,%esp
f0101a9d:	5b                   	pop    %ebx
f0101a9e:	5e                   	pop    %esi
f0101a9f:	5f                   	pop    %edi
f0101aa0:	5d                   	pop    %ebp
f0101aa1:	c3                   	ret    
f0101aa2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101aa8:	39 f2                	cmp    %esi,%edx
f0101aaa:	72 06                	jb     f0101ab2 <__udivdi3+0x102>
f0101aac:	31 c0                	xor    %eax,%eax
f0101aae:	39 eb                	cmp    %ebp,%ebx
f0101ab0:	77 d2                	ja     f0101a84 <__udivdi3+0xd4>
f0101ab2:	b8 01 00 00 00       	mov    $0x1,%eax
f0101ab7:	eb cb                	jmp    f0101a84 <__udivdi3+0xd4>
f0101ab9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101ac0:	89 d8                	mov    %ebx,%eax
f0101ac2:	31 ff                	xor    %edi,%edi
f0101ac4:	eb be                	jmp    f0101a84 <__udivdi3+0xd4>
f0101ac6:	66 90                	xchg   %ax,%ax
f0101ac8:	66 90                	xchg   %ax,%ax
f0101aca:	66 90                	xchg   %ax,%ax
f0101acc:	66 90                	xchg   %ax,%ax
f0101ace:	66 90                	xchg   %ax,%ax

f0101ad0 <__umoddi3>:
f0101ad0:	55                   	push   %ebp
f0101ad1:	57                   	push   %edi
f0101ad2:	56                   	push   %esi
f0101ad3:	53                   	push   %ebx
f0101ad4:	83 ec 1c             	sub    $0x1c,%esp
f0101ad7:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
f0101adb:	8b 74 24 30          	mov    0x30(%esp),%esi
f0101adf:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0101ae3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101ae7:	85 ed                	test   %ebp,%ebp
f0101ae9:	89 f0                	mov    %esi,%eax
f0101aeb:	89 da                	mov    %ebx,%edx
f0101aed:	75 19                	jne    f0101b08 <__umoddi3+0x38>
f0101aef:	39 df                	cmp    %ebx,%edi
f0101af1:	0f 86 b1 00 00 00    	jbe    f0101ba8 <__umoddi3+0xd8>
f0101af7:	f7 f7                	div    %edi
f0101af9:	89 d0                	mov    %edx,%eax
f0101afb:	31 d2                	xor    %edx,%edx
f0101afd:	83 c4 1c             	add    $0x1c,%esp
f0101b00:	5b                   	pop    %ebx
f0101b01:	5e                   	pop    %esi
f0101b02:	5f                   	pop    %edi
f0101b03:	5d                   	pop    %ebp
f0101b04:	c3                   	ret    
f0101b05:	8d 76 00             	lea    0x0(%esi),%esi
f0101b08:	39 dd                	cmp    %ebx,%ebp
f0101b0a:	77 f1                	ja     f0101afd <__umoddi3+0x2d>
f0101b0c:	0f bd cd             	bsr    %ebp,%ecx
f0101b0f:	83 f1 1f             	xor    $0x1f,%ecx
f0101b12:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101b16:	0f 84 b4 00 00 00    	je     f0101bd0 <__umoddi3+0x100>
f0101b1c:	b8 20 00 00 00       	mov    $0x20,%eax
f0101b21:	89 c2                	mov    %eax,%edx
f0101b23:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101b27:	29 c2                	sub    %eax,%edx
f0101b29:	89 c1                	mov    %eax,%ecx
f0101b2b:	89 f8                	mov    %edi,%eax
f0101b2d:	d3 e5                	shl    %cl,%ebp
f0101b2f:	89 d1                	mov    %edx,%ecx
f0101b31:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101b35:	d3 e8                	shr    %cl,%eax
f0101b37:	09 c5                	or     %eax,%ebp
f0101b39:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101b3d:	89 c1                	mov    %eax,%ecx
f0101b3f:	d3 e7                	shl    %cl,%edi
f0101b41:	89 d1                	mov    %edx,%ecx
f0101b43:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0101b47:	89 df                	mov    %ebx,%edi
f0101b49:	d3 ef                	shr    %cl,%edi
f0101b4b:	89 c1                	mov    %eax,%ecx
f0101b4d:	89 f0                	mov    %esi,%eax
f0101b4f:	d3 e3                	shl    %cl,%ebx
f0101b51:	89 d1                	mov    %edx,%ecx
f0101b53:	89 fa                	mov    %edi,%edx
f0101b55:	d3 e8                	shr    %cl,%eax
f0101b57:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101b5c:	09 d8                	or     %ebx,%eax
f0101b5e:	f7 f5                	div    %ebp
f0101b60:	d3 e6                	shl    %cl,%esi
f0101b62:	89 d1                	mov    %edx,%ecx
f0101b64:	f7 64 24 08          	mull   0x8(%esp)
f0101b68:	39 d1                	cmp    %edx,%ecx
f0101b6a:	89 c3                	mov    %eax,%ebx
f0101b6c:	89 d7                	mov    %edx,%edi
f0101b6e:	72 06                	jb     f0101b76 <__umoddi3+0xa6>
f0101b70:	75 0e                	jne    f0101b80 <__umoddi3+0xb0>
f0101b72:	39 c6                	cmp    %eax,%esi
f0101b74:	73 0a                	jae    f0101b80 <__umoddi3+0xb0>
f0101b76:	2b 44 24 08          	sub    0x8(%esp),%eax
f0101b7a:	19 ea                	sbb    %ebp,%edx
f0101b7c:	89 d7                	mov    %edx,%edi
f0101b7e:	89 c3                	mov    %eax,%ebx
f0101b80:	89 ca                	mov    %ecx,%edx
f0101b82:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f0101b87:	29 de                	sub    %ebx,%esi
f0101b89:	19 fa                	sbb    %edi,%edx
f0101b8b:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f0101b8f:	89 d0                	mov    %edx,%eax
f0101b91:	d3 e0                	shl    %cl,%eax
f0101b93:	89 d9                	mov    %ebx,%ecx
f0101b95:	d3 ee                	shr    %cl,%esi
f0101b97:	d3 ea                	shr    %cl,%edx
f0101b99:	09 f0                	or     %esi,%eax
f0101b9b:	83 c4 1c             	add    $0x1c,%esp
f0101b9e:	5b                   	pop    %ebx
f0101b9f:	5e                   	pop    %esi
f0101ba0:	5f                   	pop    %edi
f0101ba1:	5d                   	pop    %ebp
f0101ba2:	c3                   	ret    
f0101ba3:	90                   	nop
f0101ba4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101ba8:	85 ff                	test   %edi,%edi
f0101baa:	89 f9                	mov    %edi,%ecx
f0101bac:	75 0b                	jne    f0101bb9 <__umoddi3+0xe9>
f0101bae:	b8 01 00 00 00       	mov    $0x1,%eax
f0101bb3:	31 d2                	xor    %edx,%edx
f0101bb5:	f7 f7                	div    %edi
f0101bb7:	89 c1                	mov    %eax,%ecx
f0101bb9:	89 d8                	mov    %ebx,%eax
f0101bbb:	31 d2                	xor    %edx,%edx
f0101bbd:	f7 f1                	div    %ecx
f0101bbf:	89 f0                	mov    %esi,%eax
f0101bc1:	f7 f1                	div    %ecx
f0101bc3:	e9 31 ff ff ff       	jmp    f0101af9 <__umoddi3+0x29>
f0101bc8:	90                   	nop
f0101bc9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101bd0:	39 dd                	cmp    %ebx,%ebp
f0101bd2:	72 08                	jb     f0101bdc <__umoddi3+0x10c>
f0101bd4:	39 f7                	cmp    %esi,%edi
f0101bd6:	0f 87 21 ff ff ff    	ja     f0101afd <__umoddi3+0x2d>
f0101bdc:	89 da                	mov    %ebx,%edx
f0101bde:	89 f0                	mov    %esi,%eax
f0101be0:	29 f8                	sub    %edi,%eax
f0101be2:	19 ea                	sbb    %ebp,%edx
f0101be4:	e9 14 ff ff ff       	jmp    f0101afd <__umoddi3+0x2d>
