
obj/user/hello:     file format elf32-i386


Disassembly of section .text:

00800020 <_start>:
// starts us running when we are initially loaded into a new environment.
.text
.globl _start
_start:
	// See if we were started with arguments on the stack
	cmpl $USTACKTOP, %esp
  800020:	81 fc 00 00 00 d0    	cmp    $0xd0000000,%esp
	jne args_exist
  800026:	75 04                	jne    80002c <args_exist>

	// If not, push dummy argc/argv arguments.
	// This happens when we are loaded by the kernel,
	// because the kernel does not know about passing arguments.
	pushl $0
  800028:	6a 00                	push   $0x0
	pushl $0
  80002a:	6a 00                	push   $0x0

0080002c <args_exist>:

args_exist:
	call libmain
  80002c:	e8 17 00 00 00       	call   800048 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:
// hello, world
#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	83 ec 14             	sub    $0x14,%esp
	cprintf("Hello, world.\n");
  800039:	68 5c 0d 80 00       	push   $0x800d5c
  80003e:	e8 c6 00 00 00       	call   800109 <cprintf>
}
  800043:	83 c4 10             	add    $0x10,%esp
  800046:	c9                   	leave  
  800047:	c3                   	ret    

00800048 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800048:	55                   	push   %ebp
  800049:	89 e5                	mov    %esp,%ebp
  80004b:	83 ec 08             	sub    $0x8,%esp
  80004e:	8b 45 08             	mov    0x8(%ebp),%eax
  800051:	8b 55 0c             	mov    0xc(%ebp),%edx
	// LAB 3: Your code here.
	// envid_t envid = sys_getenvid();
	// thisenv = envs + ENVX(envid);

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800054:	85 c0                	test   %eax,%eax
  800056:	7e 08                	jle    800060 <libmain+0x18>
		binaryname = argv[0];
  800058:	8b 0a                	mov    (%edx),%ecx
  80005a:	89 0d 00 10 80 00    	mov    %ecx,0x801000
	// cprintf("argc: %d\n", argc);
	// call user main routine
	umain(argc, argv);
  800060:	83 ec 08             	sub    $0x8,%esp
  800063:	52                   	push   %edx
  800064:	50                   	push   %eax
  800065:	e8 c9 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  80006a:	e8 48 01 00 00       	call   8001b7 <exit>
}
  80006f:	83 c4 10             	add    $0x10,%esp
  800072:	c9                   	leave  
  800073:	c3                   	ret    

00800074 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  800074:	55                   	push   %ebp
  800075:	89 e5                	mov    %esp,%ebp
  800077:	53                   	push   %ebx
  800078:	83 ec 04             	sub    $0x4,%esp
  80007b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  80007e:	8b 13                	mov    (%ebx),%edx
  800080:	8d 42 01             	lea    0x1(%edx),%eax
  800083:	89 03                	mov    %eax,(%ebx)
  800085:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800088:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  80008c:	3d ff 00 00 00       	cmp    $0xff,%eax
  800091:	74 09                	je     80009c <putch+0x28>
		sys_cputs(b->buf, b->idx);
		b->idx = 0;
	}
	b->cnt++;
  800093:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  800097:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  80009a:	c9                   	leave  
  80009b:	c3                   	ret    
		sys_cputs(b->buf, b->idx);
  80009c:	83 ec 08             	sub    $0x8,%esp
  80009f:	68 ff 00 00 00       	push   $0xff
  8000a4:	8d 43 08             	lea    0x8(%ebx),%eax
  8000a7:	50                   	push   %eax
  8000a8:	e8 70 00 00 00       	call   80011d <sys_cputs>
		b->idx = 0;
  8000ad:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8000b3:	83 c4 10             	add    $0x10,%esp
  8000b6:	eb db                	jmp    800093 <putch+0x1f>

008000b8 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8000b8:	55                   	push   %ebp
  8000b9:	89 e5                	mov    %esp,%ebp
  8000bb:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8000c1:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8000c8:	00 00 00 
	b.cnt = 0;
  8000cb:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8000d2:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  8000d5:	ff 75 0c             	pushl  0xc(%ebp)
  8000d8:	ff 75 08             	pushl  0x8(%ebp)
  8000db:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  8000e1:	50                   	push   %eax
  8000e2:	68 74 00 80 00       	push   $0x800074
  8000e7:	e8 ce 01 00 00       	call   8002ba <vprintfmt>
	sys_cputs(b.buf, b.idx);
  8000ec:	83 c4 08             	add    $0x8,%esp
  8000ef:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  8000f5:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  8000fb:	50                   	push   %eax
  8000fc:	e8 1c 00 00 00       	call   80011d <sys_cputs>

	return b.cnt;
}
  800101:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800107:	c9                   	leave  
  800108:	c3                   	ret    

00800109 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800109:	55                   	push   %ebp
  80010a:	89 e5                	mov    %esp,%ebp
  80010c:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  80010f:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800112:	50                   	push   %eax
  800113:	ff 75 08             	pushl  0x8(%ebp)
  800116:	e8 9d ff ff ff       	call   8000b8 <vcprintf>
	va_end(ap);

	return cnt;
}
  80011b:	c9                   	leave  
  80011c:	c3                   	ret    

0080011d <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  80011d:	55                   	push   %ebp
  80011e:	89 e5                	mov    %esp,%ebp
  800120:	57                   	push   %edi
  800121:	56                   	push   %esi
  800122:	53                   	push   %ebx
	asm volatile("int %1\n"
  800123:	b8 00 00 00 00       	mov    $0x0,%eax
  800128:	8b 55 08             	mov    0x8(%ebp),%edx
  80012b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80012e:	89 c3                	mov    %eax,%ebx
  800130:	89 c7                	mov    %eax,%edi
  800132:	89 c6                	mov    %eax,%esi
  800134:	cd 40                	int    $0x40
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800136:	5b                   	pop    %ebx
  800137:	5e                   	pop    %esi
  800138:	5f                   	pop    %edi
  800139:	5d                   	pop    %ebp
  80013a:	c3                   	ret    

0080013b <sys_cgetc>:

int
sys_cgetc(void)
{
  80013b:	55                   	push   %ebp
  80013c:	89 e5                	mov    %esp,%ebp
  80013e:	57                   	push   %edi
  80013f:	56                   	push   %esi
  800140:	53                   	push   %ebx
	asm volatile("int %1\n"
  800141:	ba 00 00 00 00       	mov    $0x0,%edx
  800146:	b8 01 00 00 00       	mov    $0x1,%eax
  80014b:	89 d1                	mov    %edx,%ecx
  80014d:	89 d3                	mov    %edx,%ebx
  80014f:	89 d7                	mov    %edx,%edi
  800151:	89 d6                	mov    %edx,%esi
  800153:	cd 40                	int    $0x40
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800155:	5b                   	pop    %ebx
  800156:	5e                   	pop    %esi
  800157:	5f                   	pop    %edi
  800158:	5d                   	pop    %ebp
  800159:	c3                   	ret    

0080015a <sys_exit>:

void
sys_exit(void)
{
  80015a:	55                   	push   %ebp
  80015b:	89 e5                	mov    %esp,%ebp
  80015d:	57                   	push   %edi
  80015e:	56                   	push   %esi
  80015f:	53                   	push   %ebx
	asm volatile("int %1\n"
  800160:	ba 00 00 00 00       	mov    $0x0,%edx
  800165:	b8 02 00 00 00       	mov    $0x2,%eax
  80016a:	89 d1                	mov    %edx,%ecx
  80016c:	89 d3                	mov    %edx,%ebx
  80016e:	89 d7                	mov    %edx,%edi
  800170:	89 d6                	mov    %edx,%esi
  800172:	cd 40                	int    $0x40
	syscall(SYS_exit, 0, 0, 0, 0, 0, 0);
}
  800174:	5b                   	pop    %ebx
  800175:	5e                   	pop    %esi
  800176:	5f                   	pop    %edi
  800177:	5d                   	pop    %ebp
  800178:	c3                   	ret    

00800179 <sys_fork>:

int
sys_fork(void)
{
  800179:	55                   	push   %ebp
  80017a:	89 e5                	mov    %esp,%ebp
  80017c:	57                   	push   %edi
  80017d:	56                   	push   %esi
  80017e:	53                   	push   %ebx
	asm volatile("int %1\n"
  80017f:	ba 00 00 00 00       	mov    $0x0,%edx
  800184:	b8 04 00 00 00       	mov    $0x4,%eax
  800189:	89 d1                	mov    %edx,%ecx
  80018b:	89 d3                	mov    %edx,%ebx
  80018d:	89 d7                	mov    %edx,%edi
  80018f:	89 d6                	mov    %edx,%esi
  800191:	cd 40                	int    $0x40
	return syscall(SYS_fork, 0, 0, 0, 0, 0, 0); // TODO check the number of arguments
}
  800193:	5b                   	pop    %ebx
  800194:	5e                   	pop    %esi
  800195:	5f                   	pop    %edi
  800196:	5d                   	pop    %ebp
  800197:	c3                   	ret    

00800198 <sys_yield>:

void
sys_yield(void)
{
  800198:	55                   	push   %ebp
  800199:	89 e5                	mov    %esp,%ebp
  80019b:	57                   	push   %edi
  80019c:	56                   	push   %esi
  80019d:	53                   	push   %ebx
	asm volatile("int %1\n"
  80019e:	ba 00 00 00 00       	mov    $0x0,%edx
  8001a3:	b8 03 00 00 00       	mov    $0x3,%eax
  8001a8:	89 d1                	mov    %edx,%ecx
  8001aa:	89 d3                	mov    %edx,%ebx
  8001ac:	89 d7                	mov    %edx,%edi
  8001ae:	89 d6                	mov    %edx,%esi
  8001b0:	cd 40                	int    $0x40
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
  8001b2:	5b                   	pop    %ebx
  8001b3:	5e                   	pop    %esi
  8001b4:	5f                   	pop    %edi
  8001b5:	5d                   	pop    %ebp
  8001b6:	c3                   	ret    

008001b7 <exit>:
#include <inc/lib.h>

void
exit(void)
{
  8001b7:	55                   	push   %ebp
  8001b8:	89 e5                	mov    %esp,%ebp
  8001ba:	83 ec 08             	sub    $0x8,%esp
	sys_exit();
  8001bd:	e8 98 ff ff ff       	call   80015a <sys_exit>
}
  8001c2:	c9                   	leave  
  8001c3:	c3                   	ret    

008001c4 <fork>:

int
fork(void)
{
  8001c4:	55                   	push   %ebp
  8001c5:	89 e5                	mov    %esp,%ebp
  8001c7:	83 ec 08             	sub    $0x8,%esp
	return sys_fork();
  8001ca:	e8 aa ff ff ff       	call   800179 <sys_fork>
  8001cf:	c9                   	leave  
  8001d0:	c3                   	ret    

008001d1 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  8001d1:	55                   	push   %ebp
  8001d2:	89 e5                	mov    %esp,%ebp
  8001d4:	57                   	push   %edi
  8001d5:	56                   	push   %esi
  8001d6:	53                   	push   %ebx
  8001d7:	83 ec 1c             	sub    $0x1c,%esp
  8001da:	89 c7                	mov    %eax,%edi
  8001dc:	89 d6                	mov    %edx,%esi
  8001de:	8b 45 08             	mov    0x8(%ebp),%eax
  8001e1:	8b 55 0c             	mov    0xc(%ebp),%edx
  8001e4:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8001e7:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  8001ea:	8b 4d 10             	mov    0x10(%ebp),%ecx
  8001ed:	bb 00 00 00 00       	mov    $0x0,%ebx
  8001f2:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  8001f5:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  8001f8:	39 d3                	cmp    %edx,%ebx
  8001fa:	72 05                	jb     800201 <printnum+0x30>
  8001fc:	39 45 10             	cmp    %eax,0x10(%ebp)
  8001ff:	77 7a                	ja     80027b <printnum+0xaa>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  800201:	83 ec 0c             	sub    $0xc,%esp
  800204:	ff 75 18             	pushl  0x18(%ebp)
  800207:	8b 45 14             	mov    0x14(%ebp),%eax
  80020a:	8d 58 ff             	lea    -0x1(%eax),%ebx
  80020d:	53                   	push   %ebx
  80020e:	ff 75 10             	pushl  0x10(%ebp)
  800211:	83 ec 08             	sub    $0x8,%esp
  800214:	ff 75 e4             	pushl  -0x1c(%ebp)
  800217:	ff 75 e0             	pushl  -0x20(%ebp)
  80021a:	ff 75 dc             	pushl  -0x24(%ebp)
  80021d:	ff 75 d8             	pushl  -0x28(%ebp)
  800220:	e8 fb 08 00 00       	call   800b20 <__udivdi3>
  800225:	83 c4 18             	add    $0x18,%esp
  800228:	52                   	push   %edx
  800229:	50                   	push   %eax
  80022a:	89 f2                	mov    %esi,%edx
  80022c:	89 f8                	mov    %edi,%eax
  80022e:	e8 9e ff ff ff       	call   8001d1 <printnum>
  800233:	83 c4 20             	add    $0x20,%esp
  800236:	eb 13                	jmp    80024b <printnum+0x7a>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  800238:	83 ec 08             	sub    $0x8,%esp
  80023b:	56                   	push   %esi
  80023c:	ff 75 18             	pushl  0x18(%ebp)
  80023f:	ff d7                	call   *%edi
  800241:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
  800244:	83 eb 01             	sub    $0x1,%ebx
  800247:	85 db                	test   %ebx,%ebx
  800249:	7f ed                	jg     800238 <printnum+0x67>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80024b:	83 ec 08             	sub    $0x8,%esp
  80024e:	56                   	push   %esi
  80024f:	83 ec 04             	sub    $0x4,%esp
  800252:	ff 75 e4             	pushl  -0x1c(%ebp)
  800255:	ff 75 e0             	pushl  -0x20(%ebp)
  800258:	ff 75 dc             	pushl  -0x24(%ebp)
  80025b:	ff 75 d8             	pushl  -0x28(%ebp)
  80025e:	e8 dd 09 00 00       	call   800c40 <__umoddi3>
  800263:	83 c4 14             	add    $0x14,%esp
  800266:	0f be 80 75 0d 80 00 	movsbl 0x800d75(%eax),%eax
  80026d:	50                   	push   %eax
  80026e:	ff d7                	call   *%edi
}
  800270:	83 c4 10             	add    $0x10,%esp
  800273:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800276:	5b                   	pop    %ebx
  800277:	5e                   	pop    %esi
  800278:	5f                   	pop    %edi
  800279:	5d                   	pop    %ebp
  80027a:	c3                   	ret    
  80027b:	8b 5d 14             	mov    0x14(%ebp),%ebx
  80027e:	eb c4                	jmp    800244 <printnum+0x73>

00800280 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  800280:	55                   	push   %ebp
  800281:	89 e5                	mov    %esp,%ebp
  800283:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  800286:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  80028a:	8b 10                	mov    (%eax),%edx
  80028c:	3b 50 04             	cmp    0x4(%eax),%edx
  80028f:	73 0a                	jae    80029b <sprintputch+0x1b>
		*b->buf++ = ch;
  800291:	8d 4a 01             	lea    0x1(%edx),%ecx
  800294:	89 08                	mov    %ecx,(%eax)
  800296:	8b 45 08             	mov    0x8(%ebp),%eax
  800299:	88 02                	mov    %al,(%edx)
}
  80029b:	5d                   	pop    %ebp
  80029c:	c3                   	ret    

0080029d <printfmt>:
{
  80029d:	55                   	push   %ebp
  80029e:	89 e5                	mov    %esp,%ebp
  8002a0:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
  8002a3:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8002a6:	50                   	push   %eax
  8002a7:	ff 75 10             	pushl  0x10(%ebp)
  8002aa:	ff 75 0c             	pushl  0xc(%ebp)
  8002ad:	ff 75 08             	pushl  0x8(%ebp)
  8002b0:	e8 05 00 00 00       	call   8002ba <vprintfmt>
}
  8002b5:	83 c4 10             	add    $0x10,%esp
  8002b8:	c9                   	leave  
  8002b9:	c3                   	ret    

008002ba <vprintfmt>:
{
  8002ba:	55                   	push   %ebp
  8002bb:	89 e5                	mov    %esp,%ebp
  8002bd:	57                   	push   %edi
  8002be:	56                   	push   %esi
  8002bf:	53                   	push   %ebx
  8002c0:	83 ec 2c             	sub    $0x2c,%esp
  8002c3:	8b 75 08             	mov    0x8(%ebp),%esi
  8002c6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8002c9:	8b 7d 10             	mov    0x10(%ebp),%edi
  8002cc:	e9 c1 03 00 00       	jmp    800692 <vprintfmt+0x3d8>
		padc = ' ';
  8002d1:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
  8002d5:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
  8002dc:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
		width = -1;
  8002e3:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
  8002ea:	b9 00 00 00 00       	mov    $0x0,%ecx
		switch (ch = *(unsigned char *) fmt++) {
  8002ef:	8d 47 01             	lea    0x1(%edi),%eax
  8002f2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8002f5:	0f b6 17             	movzbl (%edi),%edx
  8002f8:	8d 42 dd             	lea    -0x23(%edx),%eax
  8002fb:	3c 55                	cmp    $0x55,%al
  8002fd:	0f 87 12 04 00 00    	ja     800715 <vprintfmt+0x45b>
  800303:	0f b6 c0             	movzbl %al,%eax
  800306:	ff 24 85 04 0e 80 00 	jmp    *0x800e04(,%eax,4)
  80030d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
  800310:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
  800314:	eb d9                	jmp    8002ef <vprintfmt+0x35>
		switch (ch = *(unsigned char *) fmt++) {
  800316:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '0';
  800319:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  80031d:	eb d0                	jmp    8002ef <vprintfmt+0x35>
		switch (ch = *(unsigned char *) fmt++) {
  80031f:	0f b6 d2             	movzbl %dl,%edx
  800322:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
  800325:	b8 00 00 00 00       	mov    $0x0,%eax
  80032a:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
				precision = precision * 10 + ch - '0';
  80032d:	8d 04 80             	lea    (%eax,%eax,4),%eax
  800330:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
  800334:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
  800337:	8d 4a d0             	lea    -0x30(%edx),%ecx
  80033a:	83 f9 09             	cmp    $0x9,%ecx
  80033d:	77 55                	ja     800394 <vprintfmt+0xda>
			for (precision = 0; ; ++fmt) {
  80033f:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
  800342:	eb e9                	jmp    80032d <vprintfmt+0x73>
			precision = va_arg(ap, int);
  800344:	8b 45 14             	mov    0x14(%ebp),%eax
  800347:	8b 00                	mov    (%eax),%eax
  800349:	89 45 d0             	mov    %eax,-0x30(%ebp)
  80034c:	8b 45 14             	mov    0x14(%ebp),%eax
  80034f:	8d 40 04             	lea    0x4(%eax),%eax
  800352:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
  800355:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
  800358:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  80035c:	79 91                	jns    8002ef <vprintfmt+0x35>
				width = precision, precision = -1;
  80035e:	8b 45 d0             	mov    -0x30(%ebp),%eax
  800361:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800364:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  80036b:	eb 82                	jmp    8002ef <vprintfmt+0x35>
  80036d:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800370:	85 c0                	test   %eax,%eax
  800372:	ba 00 00 00 00       	mov    $0x0,%edx
  800377:	0f 49 d0             	cmovns %eax,%edx
  80037a:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
  80037d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800380:	e9 6a ff ff ff       	jmp    8002ef <vprintfmt+0x35>
  800385:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
  800388:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  80038f:	e9 5b ff ff ff       	jmp    8002ef <vprintfmt+0x35>
  800394:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  800397:	89 45 d0             	mov    %eax,-0x30(%ebp)
  80039a:	eb bc                	jmp    800358 <vprintfmt+0x9e>
			lflag++;
  80039c:	83 c1 01             	add    $0x1,%ecx
		switch (ch = *(unsigned char *) fmt++) {
  80039f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
  8003a2:	e9 48 ff ff ff       	jmp    8002ef <vprintfmt+0x35>
			putch(va_arg(ap, int), putdat);
  8003a7:	8b 45 14             	mov    0x14(%ebp),%eax
  8003aa:	8d 78 04             	lea    0x4(%eax),%edi
  8003ad:	83 ec 08             	sub    $0x8,%esp
  8003b0:	53                   	push   %ebx
  8003b1:	ff 30                	pushl  (%eax)
  8003b3:	ff d6                	call   *%esi
			break;
  8003b5:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
  8003b8:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
  8003bb:	e9 cf 02 00 00       	jmp    80068f <vprintfmt+0x3d5>
			err = va_arg(ap, int);
  8003c0:	8b 45 14             	mov    0x14(%ebp),%eax
  8003c3:	8d 78 04             	lea    0x4(%eax),%edi
  8003c6:	8b 00                	mov    (%eax),%eax
  8003c8:	99                   	cltd   
  8003c9:	31 d0                	xor    %edx,%eax
  8003cb:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  8003cd:	83 f8 06             	cmp    $0x6,%eax
  8003d0:	7f 23                	jg     8003f5 <vprintfmt+0x13b>
  8003d2:	8b 14 85 5c 0f 80 00 	mov    0x800f5c(,%eax,4),%edx
  8003d9:	85 d2                	test   %edx,%edx
  8003db:	74 18                	je     8003f5 <vprintfmt+0x13b>
				printfmt(putch, putdat, "%s", p);
  8003dd:	52                   	push   %edx
  8003de:	68 96 0d 80 00       	push   $0x800d96
  8003e3:	53                   	push   %ebx
  8003e4:	56                   	push   %esi
  8003e5:	e8 b3 fe ff ff       	call   80029d <printfmt>
  8003ea:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
  8003ed:	89 7d 14             	mov    %edi,0x14(%ebp)
  8003f0:	e9 9a 02 00 00       	jmp    80068f <vprintfmt+0x3d5>
				printfmt(putch, putdat, "error %d", err);
  8003f5:	50                   	push   %eax
  8003f6:	68 8d 0d 80 00       	push   $0x800d8d
  8003fb:	53                   	push   %ebx
  8003fc:	56                   	push   %esi
  8003fd:	e8 9b fe ff ff       	call   80029d <printfmt>
  800402:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
  800405:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
  800408:	e9 82 02 00 00       	jmp    80068f <vprintfmt+0x3d5>
			if ((p = va_arg(ap, char *)) == NULL)
  80040d:	8b 45 14             	mov    0x14(%ebp),%eax
  800410:	83 c0 04             	add    $0x4,%eax
  800413:	89 45 cc             	mov    %eax,-0x34(%ebp)
  800416:	8b 45 14             	mov    0x14(%ebp),%eax
  800419:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  80041b:	85 ff                	test   %edi,%edi
  80041d:	b8 86 0d 80 00       	mov    $0x800d86,%eax
  800422:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  800425:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800429:	0f 8e bd 00 00 00    	jle    8004ec <vprintfmt+0x232>
  80042f:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  800433:	75 0e                	jne    800443 <vprintfmt+0x189>
  800435:	89 75 08             	mov    %esi,0x8(%ebp)
  800438:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80043b:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80043e:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800441:	eb 6d                	jmp    8004b0 <vprintfmt+0x1f6>
				for (width -= strnlen(p, precision); width > 0; width--)
  800443:	83 ec 08             	sub    $0x8,%esp
  800446:	ff 75 d0             	pushl  -0x30(%ebp)
  800449:	57                   	push   %edi
  80044a:	e8 6e 03 00 00       	call   8007bd <strnlen>
  80044f:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  800452:	29 c1                	sub    %eax,%ecx
  800454:	89 4d c8             	mov    %ecx,-0x38(%ebp)
  800457:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  80045a:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  80045e:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800461:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  800464:	89 cf                	mov    %ecx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
  800466:	eb 0f                	jmp    800477 <vprintfmt+0x1bd>
					putch(padc, putdat);
  800468:	83 ec 08             	sub    $0x8,%esp
  80046b:	53                   	push   %ebx
  80046c:	ff 75 e0             	pushl  -0x20(%ebp)
  80046f:	ff d6                	call   *%esi
				for (width -= strnlen(p, precision); width > 0; width--)
  800471:	83 ef 01             	sub    $0x1,%edi
  800474:	83 c4 10             	add    $0x10,%esp
  800477:	85 ff                	test   %edi,%edi
  800479:	7f ed                	jg     800468 <vprintfmt+0x1ae>
  80047b:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  80047e:	8b 4d c8             	mov    -0x38(%ebp),%ecx
  800481:	85 c9                	test   %ecx,%ecx
  800483:	b8 00 00 00 00       	mov    $0x0,%eax
  800488:	0f 49 c1             	cmovns %ecx,%eax
  80048b:	29 c1                	sub    %eax,%ecx
  80048d:	89 75 08             	mov    %esi,0x8(%ebp)
  800490:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800493:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800496:	89 cb                	mov    %ecx,%ebx
  800498:	eb 16                	jmp    8004b0 <vprintfmt+0x1f6>
				if (altflag && (ch < ' ' || ch > '~'))
  80049a:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  80049e:	75 31                	jne    8004d1 <vprintfmt+0x217>
					putch(ch, putdat);
  8004a0:	83 ec 08             	sub    $0x8,%esp
  8004a3:	ff 75 0c             	pushl  0xc(%ebp)
  8004a6:	50                   	push   %eax
  8004a7:	ff 55 08             	call   *0x8(%ebp)
  8004aa:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8004ad:	83 eb 01             	sub    $0x1,%ebx
  8004b0:	83 c7 01             	add    $0x1,%edi
  8004b3:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
  8004b7:	0f be c2             	movsbl %dl,%eax
  8004ba:	85 c0                	test   %eax,%eax
  8004bc:	74 59                	je     800517 <vprintfmt+0x25d>
  8004be:	85 f6                	test   %esi,%esi
  8004c0:	78 d8                	js     80049a <vprintfmt+0x1e0>
  8004c2:	83 ee 01             	sub    $0x1,%esi
  8004c5:	79 d3                	jns    80049a <vprintfmt+0x1e0>
  8004c7:	89 df                	mov    %ebx,%edi
  8004c9:	8b 75 08             	mov    0x8(%ebp),%esi
  8004cc:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8004cf:	eb 37                	jmp    800508 <vprintfmt+0x24e>
				if (altflag && (ch < ' ' || ch > '~'))
  8004d1:	0f be d2             	movsbl %dl,%edx
  8004d4:	83 ea 20             	sub    $0x20,%edx
  8004d7:	83 fa 5e             	cmp    $0x5e,%edx
  8004da:	76 c4                	jbe    8004a0 <vprintfmt+0x1e6>
					putch('?', putdat);
  8004dc:	83 ec 08             	sub    $0x8,%esp
  8004df:	ff 75 0c             	pushl  0xc(%ebp)
  8004e2:	6a 3f                	push   $0x3f
  8004e4:	ff 55 08             	call   *0x8(%ebp)
  8004e7:	83 c4 10             	add    $0x10,%esp
  8004ea:	eb c1                	jmp    8004ad <vprintfmt+0x1f3>
  8004ec:	89 75 08             	mov    %esi,0x8(%ebp)
  8004ef:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8004f2:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8004f5:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  8004f8:	eb b6                	jmp    8004b0 <vprintfmt+0x1f6>
				putch(' ', putdat);
  8004fa:	83 ec 08             	sub    $0x8,%esp
  8004fd:	53                   	push   %ebx
  8004fe:	6a 20                	push   $0x20
  800500:	ff d6                	call   *%esi
			for (; width > 0; width--)
  800502:	83 ef 01             	sub    $0x1,%edi
  800505:	83 c4 10             	add    $0x10,%esp
  800508:	85 ff                	test   %edi,%edi
  80050a:	7f ee                	jg     8004fa <vprintfmt+0x240>
			if ((p = va_arg(ap, char *)) == NULL)
  80050c:	8b 45 cc             	mov    -0x34(%ebp),%eax
  80050f:	89 45 14             	mov    %eax,0x14(%ebp)
  800512:	e9 78 01 00 00       	jmp    80068f <vprintfmt+0x3d5>
  800517:	89 df                	mov    %ebx,%edi
  800519:	8b 75 08             	mov    0x8(%ebp),%esi
  80051c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80051f:	eb e7                	jmp    800508 <vprintfmt+0x24e>
	if (lflag >= 2)
  800521:	83 f9 01             	cmp    $0x1,%ecx
  800524:	7e 3f                	jle    800565 <vprintfmt+0x2ab>
		return va_arg(*ap, long long);
  800526:	8b 45 14             	mov    0x14(%ebp),%eax
  800529:	8b 50 04             	mov    0x4(%eax),%edx
  80052c:	8b 00                	mov    (%eax),%eax
  80052e:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800531:	89 55 dc             	mov    %edx,-0x24(%ebp)
  800534:	8b 45 14             	mov    0x14(%ebp),%eax
  800537:	8d 40 08             	lea    0x8(%eax),%eax
  80053a:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
  80053d:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800541:	79 5c                	jns    80059f <vprintfmt+0x2e5>
				putch('-', putdat);
  800543:	83 ec 08             	sub    $0x8,%esp
  800546:	53                   	push   %ebx
  800547:	6a 2d                	push   $0x2d
  800549:	ff d6                	call   *%esi
				num = -(long long) num;
  80054b:	8b 55 d8             	mov    -0x28(%ebp),%edx
  80054e:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  800551:	f7 da                	neg    %edx
  800553:	83 d1 00             	adc    $0x0,%ecx
  800556:	f7 d9                	neg    %ecx
  800558:	83 c4 10             	add    $0x10,%esp
			base = 10;
  80055b:	b8 0a 00 00 00       	mov    $0xa,%eax
  800560:	e9 10 01 00 00       	jmp    800675 <vprintfmt+0x3bb>
	else if (lflag)
  800565:	85 c9                	test   %ecx,%ecx
  800567:	75 1b                	jne    800584 <vprintfmt+0x2ca>
		return va_arg(*ap, int);
  800569:	8b 45 14             	mov    0x14(%ebp),%eax
  80056c:	8b 00                	mov    (%eax),%eax
  80056e:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800571:	89 c1                	mov    %eax,%ecx
  800573:	c1 f9 1f             	sar    $0x1f,%ecx
  800576:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  800579:	8b 45 14             	mov    0x14(%ebp),%eax
  80057c:	8d 40 04             	lea    0x4(%eax),%eax
  80057f:	89 45 14             	mov    %eax,0x14(%ebp)
  800582:	eb b9                	jmp    80053d <vprintfmt+0x283>
		return va_arg(*ap, long);
  800584:	8b 45 14             	mov    0x14(%ebp),%eax
  800587:	8b 00                	mov    (%eax),%eax
  800589:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80058c:	89 c1                	mov    %eax,%ecx
  80058e:	c1 f9 1f             	sar    $0x1f,%ecx
  800591:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  800594:	8b 45 14             	mov    0x14(%ebp),%eax
  800597:	8d 40 04             	lea    0x4(%eax),%eax
  80059a:	89 45 14             	mov    %eax,0x14(%ebp)
  80059d:	eb 9e                	jmp    80053d <vprintfmt+0x283>
			num = getint(&ap, lflag);
  80059f:	8b 55 d8             	mov    -0x28(%ebp),%edx
  8005a2:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
  8005a5:	b8 0a 00 00 00       	mov    $0xa,%eax
  8005aa:	e9 c6 00 00 00       	jmp    800675 <vprintfmt+0x3bb>
	if (lflag >= 2)
  8005af:	83 f9 01             	cmp    $0x1,%ecx
  8005b2:	7e 18                	jle    8005cc <vprintfmt+0x312>
		return va_arg(*ap, unsigned long long);
  8005b4:	8b 45 14             	mov    0x14(%ebp),%eax
  8005b7:	8b 10                	mov    (%eax),%edx
  8005b9:	8b 48 04             	mov    0x4(%eax),%ecx
  8005bc:	8d 40 08             	lea    0x8(%eax),%eax
  8005bf:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
  8005c2:	b8 0a 00 00 00       	mov    $0xa,%eax
  8005c7:	e9 a9 00 00 00       	jmp    800675 <vprintfmt+0x3bb>
	else if (lflag)
  8005cc:	85 c9                	test   %ecx,%ecx
  8005ce:	75 1a                	jne    8005ea <vprintfmt+0x330>
		return va_arg(*ap, unsigned int);
  8005d0:	8b 45 14             	mov    0x14(%ebp),%eax
  8005d3:	8b 10                	mov    (%eax),%edx
  8005d5:	b9 00 00 00 00       	mov    $0x0,%ecx
  8005da:	8d 40 04             	lea    0x4(%eax),%eax
  8005dd:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
  8005e0:	b8 0a 00 00 00       	mov    $0xa,%eax
  8005e5:	e9 8b 00 00 00       	jmp    800675 <vprintfmt+0x3bb>
		return va_arg(*ap, unsigned long);
  8005ea:	8b 45 14             	mov    0x14(%ebp),%eax
  8005ed:	8b 10                	mov    (%eax),%edx
  8005ef:	b9 00 00 00 00       	mov    $0x0,%ecx
  8005f4:	8d 40 04             	lea    0x4(%eax),%eax
  8005f7:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
  8005fa:	b8 0a 00 00 00       	mov    $0xa,%eax
  8005ff:	eb 74                	jmp    800675 <vprintfmt+0x3bb>
	if (lflag >= 2)
  800601:	83 f9 01             	cmp    $0x1,%ecx
  800604:	7e 15                	jle    80061b <vprintfmt+0x361>
		return va_arg(*ap, unsigned long long);
  800606:	8b 45 14             	mov    0x14(%ebp),%eax
  800609:	8b 10                	mov    (%eax),%edx
  80060b:	8b 48 04             	mov    0x4(%eax),%ecx
  80060e:	8d 40 08             	lea    0x8(%eax),%eax
  800611:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
  800614:	b8 08 00 00 00       	mov    $0x8,%eax
  800619:	eb 5a                	jmp    800675 <vprintfmt+0x3bb>
	else if (lflag)
  80061b:	85 c9                	test   %ecx,%ecx
  80061d:	75 17                	jne    800636 <vprintfmt+0x37c>
		return va_arg(*ap, unsigned int);
  80061f:	8b 45 14             	mov    0x14(%ebp),%eax
  800622:	8b 10                	mov    (%eax),%edx
  800624:	b9 00 00 00 00       	mov    $0x0,%ecx
  800629:	8d 40 04             	lea    0x4(%eax),%eax
  80062c:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
  80062f:	b8 08 00 00 00       	mov    $0x8,%eax
  800634:	eb 3f                	jmp    800675 <vprintfmt+0x3bb>
		return va_arg(*ap, unsigned long);
  800636:	8b 45 14             	mov    0x14(%ebp),%eax
  800639:	8b 10                	mov    (%eax),%edx
  80063b:	b9 00 00 00 00       	mov    $0x0,%ecx
  800640:	8d 40 04             	lea    0x4(%eax),%eax
  800643:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
  800646:	b8 08 00 00 00       	mov    $0x8,%eax
  80064b:	eb 28                	jmp    800675 <vprintfmt+0x3bb>
			putch('0', putdat);
  80064d:	83 ec 08             	sub    $0x8,%esp
  800650:	53                   	push   %ebx
  800651:	6a 30                	push   $0x30
  800653:	ff d6                	call   *%esi
			putch('x', putdat);
  800655:	83 c4 08             	add    $0x8,%esp
  800658:	53                   	push   %ebx
  800659:	6a 78                	push   $0x78
  80065b:	ff d6                	call   *%esi
			num = (unsigned long long)
  80065d:	8b 45 14             	mov    0x14(%ebp),%eax
  800660:	8b 10                	mov    (%eax),%edx
  800662:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
  800667:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
  80066a:	8d 40 04             	lea    0x4(%eax),%eax
  80066d:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  800670:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
  800675:	83 ec 0c             	sub    $0xc,%esp
  800678:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  80067c:	57                   	push   %edi
  80067d:	ff 75 e0             	pushl  -0x20(%ebp)
  800680:	50                   	push   %eax
  800681:	51                   	push   %ecx
  800682:	52                   	push   %edx
  800683:	89 da                	mov    %ebx,%edx
  800685:	89 f0                	mov    %esi,%eax
  800687:	e8 45 fb ff ff       	call   8001d1 <printnum>
			break;
  80068c:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
  80068f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800692:	83 c7 01             	add    $0x1,%edi
  800695:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800699:	83 f8 25             	cmp    $0x25,%eax
  80069c:	0f 84 2f fc ff ff    	je     8002d1 <vprintfmt+0x17>
			if (ch == '\0')
  8006a2:	85 c0                	test   %eax,%eax
  8006a4:	0f 84 8b 00 00 00    	je     800735 <vprintfmt+0x47b>
			putch(ch, putdat);
  8006aa:	83 ec 08             	sub    $0x8,%esp
  8006ad:	53                   	push   %ebx
  8006ae:	50                   	push   %eax
  8006af:	ff d6                	call   *%esi
  8006b1:	83 c4 10             	add    $0x10,%esp
  8006b4:	eb dc                	jmp    800692 <vprintfmt+0x3d8>
	if (lflag >= 2)
  8006b6:	83 f9 01             	cmp    $0x1,%ecx
  8006b9:	7e 15                	jle    8006d0 <vprintfmt+0x416>
		return va_arg(*ap, unsigned long long);
  8006bb:	8b 45 14             	mov    0x14(%ebp),%eax
  8006be:	8b 10                	mov    (%eax),%edx
  8006c0:	8b 48 04             	mov    0x4(%eax),%ecx
  8006c3:	8d 40 08             	lea    0x8(%eax),%eax
  8006c6:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  8006c9:	b8 10 00 00 00       	mov    $0x10,%eax
  8006ce:	eb a5                	jmp    800675 <vprintfmt+0x3bb>
	else if (lflag)
  8006d0:	85 c9                	test   %ecx,%ecx
  8006d2:	75 17                	jne    8006eb <vprintfmt+0x431>
		return va_arg(*ap, unsigned int);
  8006d4:	8b 45 14             	mov    0x14(%ebp),%eax
  8006d7:	8b 10                	mov    (%eax),%edx
  8006d9:	b9 00 00 00 00       	mov    $0x0,%ecx
  8006de:	8d 40 04             	lea    0x4(%eax),%eax
  8006e1:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  8006e4:	b8 10 00 00 00       	mov    $0x10,%eax
  8006e9:	eb 8a                	jmp    800675 <vprintfmt+0x3bb>
		return va_arg(*ap, unsigned long);
  8006eb:	8b 45 14             	mov    0x14(%ebp),%eax
  8006ee:	8b 10                	mov    (%eax),%edx
  8006f0:	b9 00 00 00 00       	mov    $0x0,%ecx
  8006f5:	8d 40 04             	lea    0x4(%eax),%eax
  8006f8:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  8006fb:	b8 10 00 00 00       	mov    $0x10,%eax
  800700:	e9 70 ff ff ff       	jmp    800675 <vprintfmt+0x3bb>
			putch(ch, putdat);
  800705:	83 ec 08             	sub    $0x8,%esp
  800708:	53                   	push   %ebx
  800709:	6a 25                	push   $0x25
  80070b:	ff d6                	call   *%esi
			break;
  80070d:	83 c4 10             	add    $0x10,%esp
  800710:	e9 7a ff ff ff       	jmp    80068f <vprintfmt+0x3d5>
			putch('%', putdat);
  800715:	83 ec 08             	sub    $0x8,%esp
  800718:	53                   	push   %ebx
  800719:	6a 25                	push   $0x25
  80071b:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  80071d:	83 c4 10             	add    $0x10,%esp
  800720:	89 f8                	mov    %edi,%eax
  800722:	eb 03                	jmp    800727 <vprintfmt+0x46d>
  800724:	83 e8 01             	sub    $0x1,%eax
  800727:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
  80072b:	75 f7                	jne    800724 <vprintfmt+0x46a>
  80072d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800730:	e9 5a ff ff ff       	jmp    80068f <vprintfmt+0x3d5>
}
  800735:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800738:	5b                   	pop    %ebx
  800739:	5e                   	pop    %esi
  80073a:	5f                   	pop    %edi
  80073b:	5d                   	pop    %ebp
  80073c:	c3                   	ret    

0080073d <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  80073d:	55                   	push   %ebp
  80073e:	89 e5                	mov    %esp,%ebp
  800740:	83 ec 18             	sub    $0x18,%esp
  800743:	8b 45 08             	mov    0x8(%ebp),%eax
  800746:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  800749:	89 45 ec             	mov    %eax,-0x14(%ebp)
  80074c:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800750:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800753:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  80075a:	85 c0                	test   %eax,%eax
  80075c:	74 26                	je     800784 <vsnprintf+0x47>
  80075e:	85 d2                	test   %edx,%edx
  800760:	7e 22                	jle    800784 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800762:	ff 75 14             	pushl  0x14(%ebp)
  800765:	ff 75 10             	pushl  0x10(%ebp)
  800768:	8d 45 ec             	lea    -0x14(%ebp),%eax
  80076b:	50                   	push   %eax
  80076c:	68 80 02 80 00       	push   $0x800280
  800771:	e8 44 fb ff ff       	call   8002ba <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800776:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800779:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  80077c:	8b 45 f4             	mov    -0xc(%ebp),%eax
  80077f:	83 c4 10             	add    $0x10,%esp
}
  800782:	c9                   	leave  
  800783:	c3                   	ret    
		return -E_INVAL;
  800784:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
  800789:	eb f7                	jmp    800782 <vsnprintf+0x45>

0080078b <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  80078b:	55                   	push   %ebp
  80078c:	89 e5                	mov    %esp,%ebp
  80078e:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800791:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800794:	50                   	push   %eax
  800795:	ff 75 10             	pushl  0x10(%ebp)
  800798:	ff 75 0c             	pushl  0xc(%ebp)
  80079b:	ff 75 08             	pushl  0x8(%ebp)
  80079e:	e8 9a ff ff ff       	call   80073d <vsnprintf>
	va_end(ap);

	return rc;
}
  8007a3:	c9                   	leave  
  8007a4:	c3                   	ret    

008007a5 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  8007a5:	55                   	push   %ebp
  8007a6:	89 e5                	mov    %esp,%ebp
  8007a8:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  8007ab:	b8 00 00 00 00       	mov    $0x0,%eax
  8007b0:	eb 03                	jmp    8007b5 <strlen+0x10>
		n++;
  8007b2:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
  8007b5:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  8007b9:	75 f7                	jne    8007b2 <strlen+0xd>
	return n;
}
  8007bb:	5d                   	pop    %ebp
  8007bc:	c3                   	ret    

008007bd <strnlen>:

int
strnlen(const char *s, size_t size)
{
  8007bd:	55                   	push   %ebp
  8007be:	89 e5                	mov    %esp,%ebp
  8007c0:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8007c3:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8007c6:	b8 00 00 00 00       	mov    $0x0,%eax
  8007cb:	eb 03                	jmp    8007d0 <strnlen+0x13>
		n++;
  8007cd:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8007d0:	39 d0                	cmp    %edx,%eax
  8007d2:	74 06                	je     8007da <strnlen+0x1d>
  8007d4:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
  8007d8:	75 f3                	jne    8007cd <strnlen+0x10>
	return n;
}
  8007da:	5d                   	pop    %ebp
  8007db:	c3                   	ret    

008007dc <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8007dc:	55                   	push   %ebp
  8007dd:	89 e5                	mov    %esp,%ebp
  8007df:	53                   	push   %ebx
  8007e0:	8b 45 08             	mov    0x8(%ebp),%eax
  8007e3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8007e6:	89 c2                	mov    %eax,%edx
  8007e8:	83 c1 01             	add    $0x1,%ecx
  8007eb:	83 c2 01             	add    $0x1,%edx
  8007ee:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  8007f2:	88 5a ff             	mov    %bl,-0x1(%edx)
  8007f5:	84 db                	test   %bl,%bl
  8007f7:	75 ef                	jne    8007e8 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8007f9:	5b                   	pop    %ebx
  8007fa:	5d                   	pop    %ebp
  8007fb:	c3                   	ret    

008007fc <strcat>:

char *
strcat(char *dst, const char *src)
{
  8007fc:	55                   	push   %ebp
  8007fd:	89 e5                	mov    %esp,%ebp
  8007ff:	53                   	push   %ebx
  800800:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800803:	53                   	push   %ebx
  800804:	e8 9c ff ff ff       	call   8007a5 <strlen>
  800809:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  80080c:	ff 75 0c             	pushl  0xc(%ebp)
  80080f:	01 d8                	add    %ebx,%eax
  800811:	50                   	push   %eax
  800812:	e8 c5 ff ff ff       	call   8007dc <strcpy>
	return dst;
}
  800817:	89 d8                	mov    %ebx,%eax
  800819:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  80081c:	c9                   	leave  
  80081d:	c3                   	ret    

0080081e <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  80081e:	55                   	push   %ebp
  80081f:	89 e5                	mov    %esp,%ebp
  800821:	56                   	push   %esi
  800822:	53                   	push   %ebx
  800823:	8b 75 08             	mov    0x8(%ebp),%esi
  800826:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800829:	89 f3                	mov    %esi,%ebx
  80082b:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  80082e:	89 f2                	mov    %esi,%edx
  800830:	eb 0f                	jmp    800841 <strncpy+0x23>
		*dst++ = *src;
  800832:	83 c2 01             	add    $0x1,%edx
  800835:	0f b6 01             	movzbl (%ecx),%eax
  800838:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  80083b:	80 39 01             	cmpb   $0x1,(%ecx)
  80083e:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
  800841:	39 da                	cmp    %ebx,%edx
  800843:	75 ed                	jne    800832 <strncpy+0x14>
	}
	return ret;
}
  800845:	89 f0                	mov    %esi,%eax
  800847:	5b                   	pop    %ebx
  800848:	5e                   	pop    %esi
  800849:	5d                   	pop    %ebp
  80084a:	c3                   	ret    

0080084b <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  80084b:	55                   	push   %ebp
  80084c:	89 e5                	mov    %esp,%ebp
  80084e:	56                   	push   %esi
  80084f:	53                   	push   %ebx
  800850:	8b 75 08             	mov    0x8(%ebp),%esi
  800853:	8b 55 0c             	mov    0xc(%ebp),%edx
  800856:	8b 4d 10             	mov    0x10(%ebp),%ecx
  800859:	89 f0                	mov    %esi,%eax
  80085b:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  80085f:	85 c9                	test   %ecx,%ecx
  800861:	75 0b                	jne    80086e <strlcpy+0x23>
  800863:	eb 17                	jmp    80087c <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800865:	83 c2 01             	add    $0x1,%edx
  800868:	83 c0 01             	add    $0x1,%eax
  80086b:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
  80086e:	39 d8                	cmp    %ebx,%eax
  800870:	74 07                	je     800879 <strlcpy+0x2e>
  800872:	0f b6 0a             	movzbl (%edx),%ecx
  800875:	84 c9                	test   %cl,%cl
  800877:	75 ec                	jne    800865 <strlcpy+0x1a>
		*dst = '\0';
  800879:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  80087c:	29 f0                	sub    %esi,%eax
}
  80087e:	5b                   	pop    %ebx
  80087f:	5e                   	pop    %esi
  800880:	5d                   	pop    %ebp
  800881:	c3                   	ret    

00800882 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800882:	55                   	push   %ebp
  800883:	89 e5                	mov    %esp,%ebp
  800885:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800888:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  80088b:	eb 06                	jmp    800893 <strcmp+0x11>
		p++, q++;
  80088d:	83 c1 01             	add    $0x1,%ecx
  800890:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
  800893:	0f b6 01             	movzbl (%ecx),%eax
  800896:	84 c0                	test   %al,%al
  800898:	74 04                	je     80089e <strcmp+0x1c>
  80089a:	3a 02                	cmp    (%edx),%al
  80089c:	74 ef                	je     80088d <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
  80089e:	0f b6 c0             	movzbl %al,%eax
  8008a1:	0f b6 12             	movzbl (%edx),%edx
  8008a4:	29 d0                	sub    %edx,%eax
}
  8008a6:	5d                   	pop    %ebp
  8008a7:	c3                   	ret    

008008a8 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  8008a8:	55                   	push   %ebp
  8008a9:	89 e5                	mov    %esp,%ebp
  8008ab:	53                   	push   %ebx
  8008ac:	8b 45 08             	mov    0x8(%ebp),%eax
  8008af:	8b 55 0c             	mov    0xc(%ebp),%edx
  8008b2:	89 c3                	mov    %eax,%ebx
  8008b4:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  8008b7:	eb 06                	jmp    8008bf <strncmp+0x17>
		n--, p++, q++;
  8008b9:	83 c0 01             	add    $0x1,%eax
  8008bc:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
  8008bf:	39 d8                	cmp    %ebx,%eax
  8008c1:	74 16                	je     8008d9 <strncmp+0x31>
  8008c3:	0f b6 08             	movzbl (%eax),%ecx
  8008c6:	84 c9                	test   %cl,%cl
  8008c8:	74 04                	je     8008ce <strncmp+0x26>
  8008ca:	3a 0a                	cmp    (%edx),%cl
  8008cc:	74 eb                	je     8008b9 <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  8008ce:	0f b6 00             	movzbl (%eax),%eax
  8008d1:	0f b6 12             	movzbl (%edx),%edx
  8008d4:	29 d0                	sub    %edx,%eax
}
  8008d6:	5b                   	pop    %ebx
  8008d7:	5d                   	pop    %ebp
  8008d8:	c3                   	ret    
		return 0;
  8008d9:	b8 00 00 00 00       	mov    $0x0,%eax
  8008de:	eb f6                	jmp    8008d6 <strncmp+0x2e>

008008e0 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  8008e0:	55                   	push   %ebp
  8008e1:	89 e5                	mov    %esp,%ebp
  8008e3:	8b 45 08             	mov    0x8(%ebp),%eax
  8008e6:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8008ea:	0f b6 10             	movzbl (%eax),%edx
  8008ed:	84 d2                	test   %dl,%dl
  8008ef:	74 09                	je     8008fa <strchr+0x1a>
		if (*s == c)
  8008f1:	38 ca                	cmp    %cl,%dl
  8008f3:	74 0a                	je     8008ff <strchr+0x1f>
	for (; *s; s++)
  8008f5:	83 c0 01             	add    $0x1,%eax
  8008f8:	eb f0                	jmp    8008ea <strchr+0xa>
			return (char *) s;
	return 0;
  8008fa:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8008ff:	5d                   	pop    %ebp
  800900:	c3                   	ret    

00800901 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800901:	55                   	push   %ebp
  800902:	89 e5                	mov    %esp,%ebp
  800904:	8b 45 08             	mov    0x8(%ebp),%eax
  800907:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  80090b:	eb 03                	jmp    800910 <strfind+0xf>
  80090d:	83 c0 01             	add    $0x1,%eax
  800910:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  800913:	38 ca                	cmp    %cl,%dl
  800915:	74 04                	je     80091b <strfind+0x1a>
  800917:	84 d2                	test   %dl,%dl
  800919:	75 f2                	jne    80090d <strfind+0xc>
			break;
	return (char *) s;
}
  80091b:	5d                   	pop    %ebp
  80091c:	c3                   	ret    

0080091d <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  80091d:	55                   	push   %ebp
  80091e:	89 e5                	mov    %esp,%ebp
  800920:	57                   	push   %edi
  800921:	56                   	push   %esi
  800922:	53                   	push   %ebx
  800923:	8b 7d 08             	mov    0x8(%ebp),%edi
  800926:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800929:	85 c9                	test   %ecx,%ecx
  80092b:	74 13                	je     800940 <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  80092d:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800933:	75 05                	jne    80093a <memset+0x1d>
  800935:	f6 c1 03             	test   $0x3,%cl
  800938:	74 0d                	je     800947 <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  80093a:	8b 45 0c             	mov    0xc(%ebp),%eax
  80093d:	fc                   	cld    
  80093e:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800940:	89 f8                	mov    %edi,%eax
  800942:	5b                   	pop    %ebx
  800943:	5e                   	pop    %esi
  800944:	5f                   	pop    %edi
  800945:	5d                   	pop    %ebp
  800946:	c3                   	ret    
		c &= 0xFF;
  800947:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  80094b:	89 d3                	mov    %edx,%ebx
  80094d:	c1 e3 08             	shl    $0x8,%ebx
  800950:	89 d0                	mov    %edx,%eax
  800952:	c1 e0 18             	shl    $0x18,%eax
  800955:	89 d6                	mov    %edx,%esi
  800957:	c1 e6 10             	shl    $0x10,%esi
  80095a:	09 f0                	or     %esi,%eax
  80095c:	09 c2                	or     %eax,%edx
  80095e:	09 da                	or     %ebx,%edx
			:: "D" (v), "a" (c), "c" (n/4)
  800960:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
  800963:	89 d0                	mov    %edx,%eax
  800965:	fc                   	cld    
  800966:	f3 ab                	rep stos %eax,%es:(%edi)
  800968:	eb d6                	jmp    800940 <memset+0x23>

0080096a <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  80096a:	55                   	push   %ebp
  80096b:	89 e5                	mov    %esp,%ebp
  80096d:	57                   	push   %edi
  80096e:	56                   	push   %esi
  80096f:	8b 45 08             	mov    0x8(%ebp),%eax
  800972:	8b 75 0c             	mov    0xc(%ebp),%esi
  800975:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800978:	39 c6                	cmp    %eax,%esi
  80097a:	73 35                	jae    8009b1 <memmove+0x47>
  80097c:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  80097f:	39 c2                	cmp    %eax,%edx
  800981:	76 2e                	jbe    8009b1 <memmove+0x47>
		s += n;
		d += n;
  800983:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800986:	89 d6                	mov    %edx,%esi
  800988:	09 fe                	or     %edi,%esi
  80098a:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800990:	74 0c                	je     80099e <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  800992:	83 ef 01             	sub    $0x1,%edi
  800995:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
  800998:	fd                   	std    
  800999:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  80099b:	fc                   	cld    
  80099c:	eb 21                	jmp    8009bf <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  80099e:	f6 c1 03             	test   $0x3,%cl
  8009a1:	75 ef                	jne    800992 <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  8009a3:	83 ef 04             	sub    $0x4,%edi
  8009a6:	8d 72 fc             	lea    -0x4(%edx),%esi
  8009a9:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
  8009ac:	fd                   	std    
  8009ad:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  8009af:	eb ea                	jmp    80099b <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  8009b1:	89 f2                	mov    %esi,%edx
  8009b3:	09 c2                	or     %eax,%edx
  8009b5:	f6 c2 03             	test   $0x3,%dl
  8009b8:	74 09                	je     8009c3 <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  8009ba:	89 c7                	mov    %eax,%edi
  8009bc:	fc                   	cld    
  8009bd:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  8009bf:	5e                   	pop    %esi
  8009c0:	5f                   	pop    %edi
  8009c1:	5d                   	pop    %ebp
  8009c2:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  8009c3:	f6 c1 03             	test   $0x3,%cl
  8009c6:	75 f2                	jne    8009ba <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  8009c8:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
  8009cb:	89 c7                	mov    %eax,%edi
  8009cd:	fc                   	cld    
  8009ce:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  8009d0:	eb ed                	jmp    8009bf <memmove+0x55>

008009d2 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  8009d2:	55                   	push   %ebp
  8009d3:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  8009d5:	ff 75 10             	pushl  0x10(%ebp)
  8009d8:	ff 75 0c             	pushl  0xc(%ebp)
  8009db:	ff 75 08             	pushl  0x8(%ebp)
  8009de:	e8 87 ff ff ff       	call   80096a <memmove>
}
  8009e3:	c9                   	leave  
  8009e4:	c3                   	ret    

008009e5 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  8009e5:	55                   	push   %ebp
  8009e6:	89 e5                	mov    %esp,%ebp
  8009e8:	56                   	push   %esi
  8009e9:	53                   	push   %ebx
  8009ea:	8b 45 08             	mov    0x8(%ebp),%eax
  8009ed:	8b 55 0c             	mov    0xc(%ebp),%edx
  8009f0:	89 c6                	mov    %eax,%esi
  8009f2:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009f5:	39 f0                	cmp    %esi,%eax
  8009f7:	74 1c                	je     800a15 <memcmp+0x30>
		if (*s1 != *s2)
  8009f9:	0f b6 08             	movzbl (%eax),%ecx
  8009fc:	0f b6 1a             	movzbl (%edx),%ebx
  8009ff:	38 d9                	cmp    %bl,%cl
  800a01:	75 08                	jne    800a0b <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
  800a03:	83 c0 01             	add    $0x1,%eax
  800a06:	83 c2 01             	add    $0x1,%edx
  800a09:	eb ea                	jmp    8009f5 <memcmp+0x10>
			return (int) *s1 - (int) *s2;
  800a0b:	0f b6 c1             	movzbl %cl,%eax
  800a0e:	0f b6 db             	movzbl %bl,%ebx
  800a11:	29 d8                	sub    %ebx,%eax
  800a13:	eb 05                	jmp    800a1a <memcmp+0x35>
	}

	return 0;
  800a15:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800a1a:	5b                   	pop    %ebx
  800a1b:	5e                   	pop    %esi
  800a1c:	5d                   	pop    %ebp
  800a1d:	c3                   	ret    

00800a1e <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800a1e:	55                   	push   %ebp
  800a1f:	89 e5                	mov    %esp,%ebp
  800a21:	8b 45 08             	mov    0x8(%ebp),%eax
  800a24:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
  800a27:	89 c2                	mov    %eax,%edx
  800a29:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800a2c:	39 d0                	cmp    %edx,%eax
  800a2e:	73 09                	jae    800a39 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
  800a30:	38 08                	cmp    %cl,(%eax)
  800a32:	74 05                	je     800a39 <memfind+0x1b>
	for (; s < ends; s++)
  800a34:	83 c0 01             	add    $0x1,%eax
  800a37:	eb f3                	jmp    800a2c <memfind+0xe>
			break;
	return (void *) s;
}
  800a39:	5d                   	pop    %ebp
  800a3a:	c3                   	ret    

00800a3b <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800a3b:	55                   	push   %ebp
  800a3c:	89 e5                	mov    %esp,%ebp
  800a3e:	57                   	push   %edi
  800a3f:	56                   	push   %esi
  800a40:	53                   	push   %ebx
  800a41:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a44:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a47:	eb 03                	jmp    800a4c <strtol+0x11>
		s++;
  800a49:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
  800a4c:	0f b6 01             	movzbl (%ecx),%eax
  800a4f:	3c 20                	cmp    $0x20,%al
  800a51:	74 f6                	je     800a49 <strtol+0xe>
  800a53:	3c 09                	cmp    $0x9,%al
  800a55:	74 f2                	je     800a49 <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
  800a57:	3c 2b                	cmp    $0x2b,%al
  800a59:	74 2e                	je     800a89 <strtol+0x4e>
	int neg = 0;
  800a5b:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
  800a60:	3c 2d                	cmp    $0x2d,%al
  800a62:	74 2f                	je     800a93 <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800a64:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800a6a:	75 05                	jne    800a71 <strtol+0x36>
  800a6c:	80 39 30             	cmpb   $0x30,(%ecx)
  800a6f:	74 2c                	je     800a9d <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a71:	85 db                	test   %ebx,%ebx
  800a73:	75 0a                	jne    800a7f <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800a75:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
  800a7a:	80 39 30             	cmpb   $0x30,(%ecx)
  800a7d:	74 28                	je     800aa7 <strtol+0x6c>
		base = 10;
  800a7f:	b8 00 00 00 00       	mov    $0x0,%eax
  800a84:	89 5d 10             	mov    %ebx,0x10(%ebp)
  800a87:	eb 50                	jmp    800ad9 <strtol+0x9e>
		s++;
  800a89:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
  800a8c:	bf 00 00 00 00       	mov    $0x0,%edi
  800a91:	eb d1                	jmp    800a64 <strtol+0x29>
		s++, neg = 1;
  800a93:	83 c1 01             	add    $0x1,%ecx
  800a96:	bf 01 00 00 00       	mov    $0x1,%edi
  800a9b:	eb c7                	jmp    800a64 <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800a9d:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800aa1:	74 0e                	je     800ab1 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
  800aa3:	85 db                	test   %ebx,%ebx
  800aa5:	75 d8                	jne    800a7f <strtol+0x44>
		s++, base = 8;
  800aa7:	83 c1 01             	add    $0x1,%ecx
  800aaa:	bb 08 00 00 00       	mov    $0x8,%ebx
  800aaf:	eb ce                	jmp    800a7f <strtol+0x44>
		s += 2, base = 16;
  800ab1:	83 c1 02             	add    $0x2,%ecx
  800ab4:	bb 10 00 00 00       	mov    $0x10,%ebx
  800ab9:	eb c4                	jmp    800a7f <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
  800abb:	8d 72 9f             	lea    -0x61(%edx),%esi
  800abe:	89 f3                	mov    %esi,%ebx
  800ac0:	80 fb 19             	cmp    $0x19,%bl
  800ac3:	77 29                	ja     800aee <strtol+0xb3>
			dig = *s - 'a' + 10;
  800ac5:	0f be d2             	movsbl %dl,%edx
  800ac8:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
  800acb:	3b 55 10             	cmp    0x10(%ebp),%edx
  800ace:	7d 30                	jge    800b00 <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
  800ad0:	83 c1 01             	add    $0x1,%ecx
  800ad3:	0f af 45 10          	imul   0x10(%ebp),%eax
  800ad7:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
  800ad9:	0f b6 11             	movzbl (%ecx),%edx
  800adc:	8d 72 d0             	lea    -0x30(%edx),%esi
  800adf:	89 f3                	mov    %esi,%ebx
  800ae1:	80 fb 09             	cmp    $0x9,%bl
  800ae4:	77 d5                	ja     800abb <strtol+0x80>
			dig = *s - '0';
  800ae6:	0f be d2             	movsbl %dl,%edx
  800ae9:	83 ea 30             	sub    $0x30,%edx
  800aec:	eb dd                	jmp    800acb <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
  800aee:	8d 72 bf             	lea    -0x41(%edx),%esi
  800af1:	89 f3                	mov    %esi,%ebx
  800af3:	80 fb 19             	cmp    $0x19,%bl
  800af6:	77 08                	ja     800b00 <strtol+0xc5>
			dig = *s - 'A' + 10;
  800af8:	0f be d2             	movsbl %dl,%edx
  800afb:	83 ea 37             	sub    $0x37,%edx
  800afe:	eb cb                	jmp    800acb <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
  800b00:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800b04:	74 05                	je     800b0b <strtol+0xd0>
		*endptr = (char *) s;
  800b06:	8b 75 0c             	mov    0xc(%ebp),%esi
  800b09:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
  800b0b:	89 c2                	mov    %eax,%edx
  800b0d:	f7 da                	neg    %edx
  800b0f:	85 ff                	test   %edi,%edi
  800b11:	0f 45 c2             	cmovne %edx,%eax
}
  800b14:	5b                   	pop    %ebx
  800b15:	5e                   	pop    %esi
  800b16:	5f                   	pop    %edi
  800b17:	5d                   	pop    %ebp
  800b18:	c3                   	ret    
  800b19:	66 90                	xchg   %ax,%ax
  800b1b:	66 90                	xchg   %ax,%ax
  800b1d:	66 90                	xchg   %ax,%ax
  800b1f:	90                   	nop

00800b20 <__udivdi3>:
  800b20:	55                   	push   %ebp
  800b21:	57                   	push   %edi
  800b22:	56                   	push   %esi
  800b23:	53                   	push   %ebx
  800b24:	83 ec 1c             	sub    $0x1c,%esp
  800b27:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  800b2b:	8b 6c 24 30          	mov    0x30(%esp),%ebp
  800b2f:	8b 74 24 34          	mov    0x34(%esp),%esi
  800b33:	8b 5c 24 38          	mov    0x38(%esp),%ebx
  800b37:	85 d2                	test   %edx,%edx
  800b39:	75 35                	jne    800b70 <__udivdi3+0x50>
  800b3b:	39 f3                	cmp    %esi,%ebx
  800b3d:	0f 87 bd 00 00 00    	ja     800c00 <__udivdi3+0xe0>
  800b43:	85 db                	test   %ebx,%ebx
  800b45:	89 d9                	mov    %ebx,%ecx
  800b47:	75 0b                	jne    800b54 <__udivdi3+0x34>
  800b49:	b8 01 00 00 00       	mov    $0x1,%eax
  800b4e:	31 d2                	xor    %edx,%edx
  800b50:	f7 f3                	div    %ebx
  800b52:	89 c1                	mov    %eax,%ecx
  800b54:	31 d2                	xor    %edx,%edx
  800b56:	89 f0                	mov    %esi,%eax
  800b58:	f7 f1                	div    %ecx
  800b5a:	89 c6                	mov    %eax,%esi
  800b5c:	89 e8                	mov    %ebp,%eax
  800b5e:	89 f7                	mov    %esi,%edi
  800b60:	f7 f1                	div    %ecx
  800b62:	89 fa                	mov    %edi,%edx
  800b64:	83 c4 1c             	add    $0x1c,%esp
  800b67:	5b                   	pop    %ebx
  800b68:	5e                   	pop    %esi
  800b69:	5f                   	pop    %edi
  800b6a:	5d                   	pop    %ebp
  800b6b:	c3                   	ret    
  800b6c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800b70:	39 f2                	cmp    %esi,%edx
  800b72:	77 7c                	ja     800bf0 <__udivdi3+0xd0>
  800b74:	0f bd fa             	bsr    %edx,%edi
  800b77:	83 f7 1f             	xor    $0x1f,%edi
  800b7a:	0f 84 98 00 00 00    	je     800c18 <__udivdi3+0xf8>
  800b80:	89 f9                	mov    %edi,%ecx
  800b82:	b8 20 00 00 00       	mov    $0x20,%eax
  800b87:	29 f8                	sub    %edi,%eax
  800b89:	d3 e2                	shl    %cl,%edx
  800b8b:	89 54 24 08          	mov    %edx,0x8(%esp)
  800b8f:	89 c1                	mov    %eax,%ecx
  800b91:	89 da                	mov    %ebx,%edx
  800b93:	d3 ea                	shr    %cl,%edx
  800b95:	8b 4c 24 08          	mov    0x8(%esp),%ecx
  800b99:	09 d1                	or     %edx,%ecx
  800b9b:	89 f2                	mov    %esi,%edx
  800b9d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800ba1:	89 f9                	mov    %edi,%ecx
  800ba3:	d3 e3                	shl    %cl,%ebx
  800ba5:	89 c1                	mov    %eax,%ecx
  800ba7:	d3 ea                	shr    %cl,%edx
  800ba9:	89 f9                	mov    %edi,%ecx
  800bab:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  800baf:	d3 e6                	shl    %cl,%esi
  800bb1:	89 eb                	mov    %ebp,%ebx
  800bb3:	89 c1                	mov    %eax,%ecx
  800bb5:	d3 eb                	shr    %cl,%ebx
  800bb7:	09 de                	or     %ebx,%esi
  800bb9:	89 f0                	mov    %esi,%eax
  800bbb:	f7 74 24 08          	divl   0x8(%esp)
  800bbf:	89 d6                	mov    %edx,%esi
  800bc1:	89 c3                	mov    %eax,%ebx
  800bc3:	f7 64 24 0c          	mull   0xc(%esp)
  800bc7:	39 d6                	cmp    %edx,%esi
  800bc9:	72 0c                	jb     800bd7 <__udivdi3+0xb7>
  800bcb:	89 f9                	mov    %edi,%ecx
  800bcd:	d3 e5                	shl    %cl,%ebp
  800bcf:	39 c5                	cmp    %eax,%ebp
  800bd1:	73 5d                	jae    800c30 <__udivdi3+0x110>
  800bd3:	39 d6                	cmp    %edx,%esi
  800bd5:	75 59                	jne    800c30 <__udivdi3+0x110>
  800bd7:	8d 43 ff             	lea    -0x1(%ebx),%eax
  800bda:	31 ff                	xor    %edi,%edi
  800bdc:	89 fa                	mov    %edi,%edx
  800bde:	83 c4 1c             	add    $0x1c,%esp
  800be1:	5b                   	pop    %ebx
  800be2:	5e                   	pop    %esi
  800be3:	5f                   	pop    %edi
  800be4:	5d                   	pop    %ebp
  800be5:	c3                   	ret    
  800be6:	8d 76 00             	lea    0x0(%esi),%esi
  800be9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
  800bf0:	31 ff                	xor    %edi,%edi
  800bf2:	31 c0                	xor    %eax,%eax
  800bf4:	89 fa                	mov    %edi,%edx
  800bf6:	83 c4 1c             	add    $0x1c,%esp
  800bf9:	5b                   	pop    %ebx
  800bfa:	5e                   	pop    %esi
  800bfb:	5f                   	pop    %edi
  800bfc:	5d                   	pop    %ebp
  800bfd:	c3                   	ret    
  800bfe:	66 90                	xchg   %ax,%ax
  800c00:	31 ff                	xor    %edi,%edi
  800c02:	89 e8                	mov    %ebp,%eax
  800c04:	89 f2                	mov    %esi,%edx
  800c06:	f7 f3                	div    %ebx
  800c08:	89 fa                	mov    %edi,%edx
  800c0a:	83 c4 1c             	add    $0x1c,%esp
  800c0d:	5b                   	pop    %ebx
  800c0e:	5e                   	pop    %esi
  800c0f:	5f                   	pop    %edi
  800c10:	5d                   	pop    %ebp
  800c11:	c3                   	ret    
  800c12:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800c18:	39 f2                	cmp    %esi,%edx
  800c1a:	72 06                	jb     800c22 <__udivdi3+0x102>
  800c1c:	31 c0                	xor    %eax,%eax
  800c1e:	39 eb                	cmp    %ebp,%ebx
  800c20:	77 d2                	ja     800bf4 <__udivdi3+0xd4>
  800c22:	b8 01 00 00 00       	mov    $0x1,%eax
  800c27:	eb cb                	jmp    800bf4 <__udivdi3+0xd4>
  800c29:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800c30:	89 d8                	mov    %ebx,%eax
  800c32:	31 ff                	xor    %edi,%edi
  800c34:	eb be                	jmp    800bf4 <__udivdi3+0xd4>
  800c36:	66 90                	xchg   %ax,%ax
  800c38:	66 90                	xchg   %ax,%ax
  800c3a:	66 90                	xchg   %ax,%ax
  800c3c:	66 90                	xchg   %ax,%ax
  800c3e:	66 90                	xchg   %ax,%ax

00800c40 <__umoddi3>:
  800c40:	55                   	push   %ebp
  800c41:	57                   	push   %edi
  800c42:	56                   	push   %esi
  800c43:	53                   	push   %ebx
  800c44:	83 ec 1c             	sub    $0x1c,%esp
  800c47:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
  800c4b:	8b 74 24 30          	mov    0x30(%esp),%esi
  800c4f:	8b 5c 24 34          	mov    0x34(%esp),%ebx
  800c53:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800c57:	85 ed                	test   %ebp,%ebp
  800c59:	89 f0                	mov    %esi,%eax
  800c5b:	89 da                	mov    %ebx,%edx
  800c5d:	75 19                	jne    800c78 <__umoddi3+0x38>
  800c5f:	39 df                	cmp    %ebx,%edi
  800c61:	0f 86 b1 00 00 00    	jbe    800d18 <__umoddi3+0xd8>
  800c67:	f7 f7                	div    %edi
  800c69:	89 d0                	mov    %edx,%eax
  800c6b:	31 d2                	xor    %edx,%edx
  800c6d:	83 c4 1c             	add    $0x1c,%esp
  800c70:	5b                   	pop    %ebx
  800c71:	5e                   	pop    %esi
  800c72:	5f                   	pop    %edi
  800c73:	5d                   	pop    %ebp
  800c74:	c3                   	ret    
  800c75:	8d 76 00             	lea    0x0(%esi),%esi
  800c78:	39 dd                	cmp    %ebx,%ebp
  800c7a:	77 f1                	ja     800c6d <__umoddi3+0x2d>
  800c7c:	0f bd cd             	bsr    %ebp,%ecx
  800c7f:	83 f1 1f             	xor    $0x1f,%ecx
  800c82:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  800c86:	0f 84 b4 00 00 00    	je     800d40 <__umoddi3+0x100>
  800c8c:	b8 20 00 00 00       	mov    $0x20,%eax
  800c91:	89 c2                	mov    %eax,%edx
  800c93:	8b 44 24 04          	mov    0x4(%esp),%eax
  800c97:	29 c2                	sub    %eax,%edx
  800c99:	89 c1                	mov    %eax,%ecx
  800c9b:	89 f8                	mov    %edi,%eax
  800c9d:	d3 e5                	shl    %cl,%ebp
  800c9f:	89 d1                	mov    %edx,%ecx
  800ca1:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800ca5:	d3 e8                	shr    %cl,%eax
  800ca7:	09 c5                	or     %eax,%ebp
  800ca9:	8b 44 24 04          	mov    0x4(%esp),%eax
  800cad:	89 c1                	mov    %eax,%ecx
  800caf:	d3 e7                	shl    %cl,%edi
  800cb1:	89 d1                	mov    %edx,%ecx
  800cb3:	89 7c 24 08          	mov    %edi,0x8(%esp)
  800cb7:	89 df                	mov    %ebx,%edi
  800cb9:	d3 ef                	shr    %cl,%edi
  800cbb:	89 c1                	mov    %eax,%ecx
  800cbd:	89 f0                	mov    %esi,%eax
  800cbf:	d3 e3                	shl    %cl,%ebx
  800cc1:	89 d1                	mov    %edx,%ecx
  800cc3:	89 fa                	mov    %edi,%edx
  800cc5:	d3 e8                	shr    %cl,%eax
  800cc7:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  800ccc:	09 d8                	or     %ebx,%eax
  800cce:	f7 f5                	div    %ebp
  800cd0:	d3 e6                	shl    %cl,%esi
  800cd2:	89 d1                	mov    %edx,%ecx
  800cd4:	f7 64 24 08          	mull   0x8(%esp)
  800cd8:	39 d1                	cmp    %edx,%ecx
  800cda:	89 c3                	mov    %eax,%ebx
  800cdc:	89 d7                	mov    %edx,%edi
  800cde:	72 06                	jb     800ce6 <__umoddi3+0xa6>
  800ce0:	75 0e                	jne    800cf0 <__umoddi3+0xb0>
  800ce2:	39 c6                	cmp    %eax,%esi
  800ce4:	73 0a                	jae    800cf0 <__umoddi3+0xb0>
  800ce6:	2b 44 24 08          	sub    0x8(%esp),%eax
  800cea:	19 ea                	sbb    %ebp,%edx
  800cec:	89 d7                	mov    %edx,%edi
  800cee:	89 c3                	mov    %eax,%ebx
  800cf0:	89 ca                	mov    %ecx,%edx
  800cf2:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
  800cf7:	29 de                	sub    %ebx,%esi
  800cf9:	19 fa                	sbb    %edi,%edx
  800cfb:	8b 5c 24 04          	mov    0x4(%esp),%ebx
  800cff:	89 d0                	mov    %edx,%eax
  800d01:	d3 e0                	shl    %cl,%eax
  800d03:	89 d9                	mov    %ebx,%ecx
  800d05:	d3 ee                	shr    %cl,%esi
  800d07:	d3 ea                	shr    %cl,%edx
  800d09:	09 f0                	or     %esi,%eax
  800d0b:	83 c4 1c             	add    $0x1c,%esp
  800d0e:	5b                   	pop    %ebx
  800d0f:	5e                   	pop    %esi
  800d10:	5f                   	pop    %edi
  800d11:	5d                   	pop    %ebp
  800d12:	c3                   	ret    
  800d13:	90                   	nop
  800d14:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800d18:	85 ff                	test   %edi,%edi
  800d1a:	89 f9                	mov    %edi,%ecx
  800d1c:	75 0b                	jne    800d29 <__umoddi3+0xe9>
  800d1e:	b8 01 00 00 00       	mov    $0x1,%eax
  800d23:	31 d2                	xor    %edx,%edx
  800d25:	f7 f7                	div    %edi
  800d27:	89 c1                	mov    %eax,%ecx
  800d29:	89 d8                	mov    %ebx,%eax
  800d2b:	31 d2                	xor    %edx,%edx
  800d2d:	f7 f1                	div    %ecx
  800d2f:	89 f0                	mov    %esi,%eax
  800d31:	f7 f1                	div    %ecx
  800d33:	e9 31 ff ff ff       	jmp    800c69 <__umoddi3+0x29>
  800d38:	90                   	nop
  800d39:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800d40:	39 dd                	cmp    %ebx,%ebp
  800d42:	72 08                	jb     800d4c <__umoddi3+0x10c>
  800d44:	39 f7                	cmp    %esi,%edi
  800d46:	0f 87 21 ff ff ff    	ja     800c6d <__umoddi3+0x2d>
  800d4c:	89 da                	mov    %ebx,%edx
  800d4e:	89 f0                	mov    %esi,%eax
  800d50:	29 f8                	sub    %edi,%eax
  800d52:	19 ea                	sbb    %ebp,%edx
  800d54:	e9 14 ff ff ff       	jmp    800c6d <__umoddi3+0x2d>
