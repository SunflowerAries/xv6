
obj/boot/boot.out:     file format elf32-i386


Disassembly of section .text:

00007c00 <start>:
.set CR0_PE_ON,         0x1

.code16								# Assemble for 16-bit mode
.globl start
start:
	cli								# BIOS enabled interrupts; disable
    7c00:	fa                   	cli    

	# Zero data segment registers DS, ES, and SS.
	xorw    %ax, %ax
    7c01:	31 c0                	xor    %eax,%eax
	movw    %ax, %ds				# -> Data Segment
    7c03:	8e d8                	mov    %eax,%ds
	movw    %ax, %es				# -> Extra Segment
    7c05:	8e c0                	mov    %eax,%es
	movw    %ax, %ss				# -> Stack Segment
    7c07:	8e d0                	mov    %eax,%ss

00007c09 <seta20.1>:

	# Physical address line A20 is tied to zero so that the first PCs
	# with 2 MB would run software that assumend 1 MB. Undo that.
seta20.1:
	inb     $0x64, %al               # Wait for not busy
    7c09:	e4 64                	in     $0x64,%al
	testb   $0x2, %al
    7c0b:	a8 02                	test   $0x2,%al
	jnz     seta20.1
    7c0d:	75 fa                	jne    7c09 <seta20.1>

	movb    $0xd1, %al               # 0xd1 -> port 0x64
    7c0f:	b0 d1                	mov    $0xd1,%al
	outb    %al, $0x64
    7c11:	e6 64                	out    %al,$0x64

00007c13 <seta20.2>:

seta20.2:
	inb     $0x64, %al               # Wait for not busy
    7c13:	e4 64                	in     $0x64,%al
	testb   $0x2, %al
    7c15:	a8 02                	test   $0x2,%al
	jnz     seta20.2
    7c17:	75 fa                	jne    7c13 <seta20.2>

	movb    $0xdf, %al               # 0xdf -> port 0x60
    7c19:	b0 df                	mov    $0xdf,%al
	outb    %al, $0x60
    7c1b:	e6 60                	out    %al,$0x60

	# Switch from real to protected mode. Use a bootstrap GDT that makes
	# virtual addresses map directly to physical addresses so that the
	# effective memory map doesn't change during the transition.
	lgdt    gdtdesc
    7c1d:	0f 01 16             	lgdtl  (%esi)
    7c20:	68 7c 0f 20 c0       	push   $0xc0200f7c
	movl    %cr0, %eax
	orl     $CR0_PE_ON, %eax
    7c25:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
    7c29:	0f 22 c0             	mov    %eax,%cr0

	# Comlete the transition to 32-bit protected mode by using a long jmp
	# to reload %cs and %eip. The segment descriptors are set up with no
	# translation, so that the mapping is still the identity mapping.
	ljmp    $PROT_MODE_CSEG, $start32
    7c2c:	ea                   	.byte 0xea
    7c2d:	31 7c 08 00          	xor    %edi,0x0(%eax,%ecx,1)

00007c31 <start32>:

.code32		# Tell assembler to generate 32-bit code now.
start32:
	# Set up the protected-mode data segment registers
	movw    $PROT_MODE_DSEG, %ax	# Our data segment selector
    7c31:	66 b8 10 00          	mov    $0x10,%ax
	movw    %ax, %ds				# -> Data Segment
    7c35:	8e d8                	mov    %eax,%ds
	movw    %ax, %es				# -> Extra Segment
    7c37:	8e c0                	mov    %eax,%es
	movw    %ax, %ss				# -> Stack Segment
    7c39:	8e d0                	mov    %eax,%ss
	movw    $0, %ax                 # Zero segments not ready for use
    7c3b:	66 b8 00 00          	mov    $0x0,%ax
	movw    %ax, %fs
    7c3f:	8e e0                	mov    %eax,%fs
	movw    %ax, %gs
    7c41:	8e e8                	mov    %eax,%gs

	# Set up the stack pointer and call into C.
	movl    $start, %esp
    7c43:	bc 00 7c 00 00       	mov    $0x7c00,%esp
	call    bootmain
    7c48:	e8 cc 00 00 00       	call   7d19 <bootmain>

00007c4d <spin>:

	# Bootmain shouldn't return.
	# If it returns, spin here.
spin:
	jmp     spin
    7c4d:	eb fe                	jmp    7c4d <spin>
    7c4f:	90                   	nop

00007c50 <gdt>:
	...
    7c58:	ff                   	(bad)  
    7c59:	ff 00                	incl   (%eax)
    7c5b:	00 00                	add    %al,(%eax)
    7c5d:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
    7c64:	00                   	.byte 0x0
    7c65:	92                   	xchg   %eax,%edx
    7c66:	cf                   	iret   
	...

00007c68 <gdtdesc>:
    7c68:	17                   	pop    %ss
    7c69:	00 50 7c             	add    %dl,0x7c(%eax)
	...

00007c6e <waitdisk>:
		/* Do nothing */;
}

void
waitdisk(void)
{
    7c6e:	55                   	push   %ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
    7c6f:	ba f7 01 00 00       	mov    $0x1f7,%edx
    7c74:	89 e5                	mov    %esp,%ebp
    7c76:	ec                   	in     (%dx),%al
	// Wait for disk reaady
	while ((inb(0x1F7) & 0xC0) != 0x40)
    7c77:	83 e0 c0             	and    $0xffffffc0,%eax
    7c7a:	3c 40                	cmp    $0x40,%al
    7c7c:	75 f8                	jne    7c76 <waitdisk+0x8>
		/* Do nothing */;
}
    7c7e:	5d                   	pop    %ebp
    7c7f:	c3                   	ret    

00007c80 <readsect>:

void
readsect(void *dst, uint32_t offset)
{
    7c80:	55                   	push   %ebp
    7c81:	89 e5                	mov    %esp,%ebp
    7c83:	57                   	push   %edi
    7c84:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	// Wait for disk to be ready
	waitdisk();
    7c87:	e8 e2 ff ff ff       	call   7c6e <waitdisk>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
    7c8c:	b0 01                	mov    $0x1,%al
    7c8e:	ba f2 01 00 00       	mov    $0x1f2,%edx
    7c93:	ee                   	out    %al,(%dx)
    7c94:	ba f3 01 00 00       	mov    $0x1f3,%edx
    7c99:	88 c8                	mov    %cl,%al
    7c9b:	ee                   	out    %al,(%dx)

	outb(0x1F2, 1);		// count = 1
	outb(0x1F3, offset);
	outb(0x1F4, offset >> 8);
    7c9c:	89 c8                	mov    %ecx,%eax
    7c9e:	ba f4 01 00 00       	mov    $0x1f4,%edx
    7ca3:	c1 e8 08             	shr    $0x8,%eax
    7ca6:	ee                   	out    %al,(%dx)
	outb(0x1F5, offset >> 16);
    7ca7:	89 c8                	mov    %ecx,%eax
    7ca9:	ba f5 01 00 00       	mov    $0x1f5,%edx
    7cae:	c1 e8 10             	shr    $0x10,%eax
    7cb1:	ee                   	out    %al,(%dx)
	outb(0x1F6, (offset >> 24) | 0xE0);
    7cb2:	89 c8                	mov    %ecx,%eax
    7cb4:	ba f6 01 00 00       	mov    $0x1f6,%edx
    7cb9:	c1 e8 18             	shr    $0x18,%eax
    7cbc:	83 c8 e0             	or     $0xffffffe0,%eax
    7cbf:	ee                   	out    %al,(%dx)
    7cc0:	b0 20                	mov    $0x20,%al
    7cc2:	ba f7 01 00 00       	mov    $0x1f7,%edx
    7cc7:	ee                   	out    %al,(%dx)
	outb(0x1F7, 0x20);	// cmd 0x20 - read sectors

	// Wait for disk to be ready
	waitdisk();
    7cc8:	e8 a1 ff ff ff       	call   7c6e <waitdisk>
	asm volatile("cld\n\trepne\n\tinsl"
    7ccd:	8b 7d 08             	mov    0x8(%ebp),%edi
    7cd0:	b9 80 00 00 00       	mov    $0x80,%ecx
    7cd5:	ba f0 01 00 00       	mov    $0x1f0,%edx
    7cda:	fc                   	cld    
    7cdb:	f2 6d                	repnz insl (%dx),%es:(%edi)

	// Read a sector
	insl(0x1F0, dst, SECTSIZE/4);
}
    7cdd:	5f                   	pop    %edi
    7cde:	5d                   	pop    %ebp
    7cdf:	c3                   	ret    

00007ce0 <readseg>:

// Read 'count' bytes at 'offset' from kernel into physical address 'pa'.
// Might copy more than asked
void
readseg(uint32_t pa, uint32_t count, uint32_t offset)
{
    7ce0:	55                   	push   %ebp
    7ce1:	89 e5                	mov    %esp,%ebp
    7ce3:	57                   	push   %edi
    7ce4:	56                   	push   %esi

	// Round down to sector boundary
	pa &= ~(SECTSIZE - 1); 

	// Translate from bytes to sectors, and kernel starts at sector 1
	offset = (offset / SECTSIZE) + 1;
    7ce5:	8b 7d 10             	mov    0x10(%ebp),%edi
{
    7ce8:	53                   	push   %ebx
	end_pa = pa + count;
    7ce9:	8b 75 0c             	mov    0xc(%ebp),%esi
{
    7cec:	8b 5d 08             	mov    0x8(%ebp),%ebx
	offset = (offset / SECTSIZE) + 1;
    7cef:	c1 ef 09             	shr    $0x9,%edi
	end_pa = pa + count;
    7cf2:	01 de                	add    %ebx,%esi
	offset = (offset / SECTSIZE) + 1;
    7cf4:	47                   	inc    %edi
	pa &= ~(SECTSIZE - 1); 
    7cf5:	81 e3 00 fe ff ff    	and    $0xfffffe00,%ebx

	// If this is too slow, we could read lots of sectors at a time.
	// We'd write more to memory than asked, but it doesn't matter --
	// we load in increasing order.
	while (pa < end_pa) {
    7cfb:	39 f3                	cmp    %esi,%ebx
    7cfd:	73 12                	jae    7d11 <readseg+0x31>
		// Since we haven't enabled paging yet and we're using
		// an identity segment mapping (see bootasm.S), we can
		// use physical addresses directly.  This won't be the
		// case once xv6 enables the MMU.
		readsect((uint8_t*) pa, offset);
    7cff:	57                   	push   %edi
    7d00:	53                   	push   %ebx
		pa += SECTSIZE;
		offset++;
    7d01:	47                   	inc    %edi
		pa += SECTSIZE;
    7d02:	81 c3 00 02 00 00    	add    $0x200,%ebx
		readsect((uint8_t*) pa, offset);
    7d08:	e8 73 ff ff ff       	call   7c80 <readsect>
		offset++;
    7d0d:	58                   	pop    %eax
    7d0e:	5a                   	pop    %edx
    7d0f:	eb ea                	jmp    7cfb <readseg+0x1b>
	}
}
    7d11:	8d 65 f4             	lea    -0xc(%ebp),%esp
    7d14:	5b                   	pop    %ebx
    7d15:	5e                   	pop    %esi
    7d16:	5f                   	pop    %edi
    7d17:	5d                   	pop    %ebp
    7d18:	c3                   	ret    

00007d19 <bootmain>:
{
    7d19:	55                   	push   %ebp
    7d1a:	89 e5                	mov    %esp,%ebp
    7d1c:	56                   	push   %esi
    7d1d:	53                   	push   %ebx
	readseg((uint32_t) ELFHDR, SECTSIZE*8, 0);//TODO
    7d1e:	6a 00                	push   $0x0
    7d20:	68 00 10 00 00       	push   $0x1000
    7d25:	68 00 00 01 00       	push   $0x10000
    7d2a:	e8 b1 ff ff ff       	call   7ce0 <readseg>
	if (ELFHDR->e_magic != ELF_MAGIC)
    7d2f:	83 c4 0c             	add    $0xc,%esp
    7d32:	81 3d 00 00 01 00 7f 	cmpl   $0x464c457f,0x10000
    7d39:	45 4c 46 
    7d3c:	75 37                	jne    7d75 <bootmain+0x5c>
	ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
    7d3e:	a1 1c 00 01 00       	mov    0x1001c,%eax
	eph = ph + ELFHDR->e_phnum;
    7d43:	0f b7 35 2c 00 01 00 	movzwl 0x1002c,%esi
	ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
    7d4a:	8d 98 00 00 01 00    	lea    0x10000(%eax),%ebx
	eph = ph + ELFHDR->e_phnum;
    7d50:	c1 e6 05             	shl    $0x5,%esi
    7d53:	01 de                	add    %ebx,%esi
	for (; ph < eph; ph++)
    7d55:	39 f3                	cmp    %esi,%ebx
    7d57:	73 16                	jae    7d6f <bootmain+0x56>
		readseg(ph->p_pa, ph->p_memsz, ph->p_offset);
    7d59:	ff 73 04             	pushl  0x4(%ebx)
    7d5c:	ff 73 14             	pushl  0x14(%ebx)
	for (; ph < eph; ph++)
    7d5f:	83 c3 20             	add    $0x20,%ebx
		readseg(ph->p_pa, ph->p_memsz, ph->p_offset);
    7d62:	ff 73 ec             	pushl  -0x14(%ebx)
    7d65:	e8 76 ff ff ff       	call   7ce0 <readseg>
	for (; ph < eph; ph++)
    7d6a:	83 c4 0c             	add    $0xc,%esp
    7d6d:	eb e6                	jmp    7d55 <bootmain+0x3c>
	((void (*)(void)) (ELFHDR->e_entry))(); // Invert ELFHDR->e_entry to a function pointer without return or argument and then execute it
    7d6f:	ff 15 18 00 01 00    	call   *0x10018
    7d75:	eb fe                	jmp    7d75 <bootmain+0x5c>
