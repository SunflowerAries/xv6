
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
	cprintf("hello, world in user mode\n");
  800039:	68 0c 0d 80 00       	push   $0x800d0c
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

	// call user main routine
	umain(argc, argv);
  800060:	83 ec 08             	sub    $0x8,%esp
  800063:	52                   	push   %edx
  800064:	50                   	push   %eax
  800065:	e8 c9 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  80006a:	e8 0a 01 00 00       	call   800179 <exit>
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
  8000e7:	e8 83 01 00 00       	call   80026f <vprintfmt>
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

00800179 <exit>:
#include <inc/lib.h>

void
exit(void)
{
  800179:	55                   	push   %ebp
  80017a:	89 e5                	mov    %esp,%ebp
  80017c:	83 ec 08             	sub    $0x8,%esp
	sys_exit();
  80017f:	e8 d6 ff ff ff       	call   80015a <sys_exit>
  800184:	c9                   	leave  
  800185:	c3                   	ret    

00800186 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800186:	55                   	push   %ebp
  800187:	89 e5                	mov    %esp,%ebp
  800189:	57                   	push   %edi
  80018a:	56                   	push   %esi
  80018b:	53                   	push   %ebx
  80018c:	83 ec 1c             	sub    $0x1c,%esp
  80018f:	89 c7                	mov    %eax,%edi
  800191:	89 d6                	mov    %edx,%esi
  800193:	8b 45 08             	mov    0x8(%ebp),%eax
  800196:	8b 55 0c             	mov    0xc(%ebp),%edx
  800199:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80019c:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  80019f:	8b 4d 10             	mov    0x10(%ebp),%ecx
  8001a2:	bb 00 00 00 00       	mov    $0x0,%ebx
  8001a7:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  8001aa:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  8001ad:	39 d3                	cmp    %edx,%ebx
  8001af:	72 05                	jb     8001b6 <printnum+0x30>
  8001b1:	39 45 10             	cmp    %eax,0x10(%ebp)
  8001b4:	77 7a                	ja     800230 <printnum+0xaa>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  8001b6:	83 ec 0c             	sub    $0xc,%esp
  8001b9:	ff 75 18             	pushl  0x18(%ebp)
  8001bc:	8b 45 14             	mov    0x14(%ebp),%eax
  8001bf:	8d 58 ff             	lea    -0x1(%eax),%ebx
  8001c2:	53                   	push   %ebx
  8001c3:	ff 75 10             	pushl  0x10(%ebp)
  8001c6:	83 ec 08             	sub    $0x8,%esp
  8001c9:	ff 75 e4             	pushl  -0x1c(%ebp)
  8001cc:	ff 75 e0             	pushl  -0x20(%ebp)
  8001cf:	ff 75 dc             	pushl  -0x24(%ebp)
  8001d2:	ff 75 d8             	pushl  -0x28(%ebp)
  8001d5:	e8 f6 08 00 00       	call   800ad0 <__udivdi3>
  8001da:	83 c4 18             	add    $0x18,%esp
  8001dd:	52                   	push   %edx
  8001de:	50                   	push   %eax
  8001df:	89 f2                	mov    %esi,%edx
  8001e1:	89 f8                	mov    %edi,%eax
  8001e3:	e8 9e ff ff ff       	call   800186 <printnum>
  8001e8:	83 c4 20             	add    $0x20,%esp
  8001eb:	eb 13                	jmp    800200 <printnum+0x7a>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8001ed:	83 ec 08             	sub    $0x8,%esp
  8001f0:	56                   	push   %esi
  8001f1:	ff 75 18             	pushl  0x18(%ebp)
  8001f4:	ff d7                	call   *%edi
  8001f6:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
  8001f9:	83 eb 01             	sub    $0x1,%ebx
  8001fc:	85 db                	test   %ebx,%ebx
  8001fe:	7f ed                	jg     8001ed <printnum+0x67>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  800200:	83 ec 08             	sub    $0x8,%esp
  800203:	56                   	push   %esi
  800204:	83 ec 04             	sub    $0x4,%esp
  800207:	ff 75 e4             	pushl  -0x1c(%ebp)
  80020a:	ff 75 e0             	pushl  -0x20(%ebp)
  80020d:	ff 75 dc             	pushl  -0x24(%ebp)
  800210:	ff 75 d8             	pushl  -0x28(%ebp)
  800213:	e8 d8 09 00 00       	call   800bf0 <__umoddi3>
  800218:	83 c4 14             	add    $0x14,%esp
  80021b:	0f be 80 31 0d 80 00 	movsbl 0x800d31(%eax),%eax
  800222:	50                   	push   %eax
  800223:	ff d7                	call   *%edi
}
  800225:	83 c4 10             	add    $0x10,%esp
  800228:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80022b:	5b                   	pop    %ebx
  80022c:	5e                   	pop    %esi
  80022d:	5f                   	pop    %edi
  80022e:	5d                   	pop    %ebp
  80022f:	c3                   	ret    
  800230:	8b 5d 14             	mov    0x14(%ebp),%ebx
  800233:	eb c4                	jmp    8001f9 <printnum+0x73>

00800235 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  800235:	55                   	push   %ebp
  800236:	89 e5                	mov    %esp,%ebp
  800238:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  80023b:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  80023f:	8b 10                	mov    (%eax),%edx
  800241:	3b 50 04             	cmp    0x4(%eax),%edx
  800244:	73 0a                	jae    800250 <sprintputch+0x1b>
		*b->buf++ = ch;
  800246:	8d 4a 01             	lea    0x1(%edx),%ecx
  800249:	89 08                	mov    %ecx,(%eax)
  80024b:	8b 45 08             	mov    0x8(%ebp),%eax
  80024e:	88 02                	mov    %al,(%edx)
}
  800250:	5d                   	pop    %ebp
  800251:	c3                   	ret    

00800252 <printfmt>:
{
  800252:	55                   	push   %ebp
  800253:	89 e5                	mov    %esp,%ebp
  800255:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
  800258:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  80025b:	50                   	push   %eax
  80025c:	ff 75 10             	pushl  0x10(%ebp)
  80025f:	ff 75 0c             	pushl  0xc(%ebp)
  800262:	ff 75 08             	pushl  0x8(%ebp)
  800265:	e8 05 00 00 00       	call   80026f <vprintfmt>
}
  80026a:	83 c4 10             	add    $0x10,%esp
  80026d:	c9                   	leave  
  80026e:	c3                   	ret    

0080026f <vprintfmt>:
{
  80026f:	55                   	push   %ebp
  800270:	89 e5                	mov    %esp,%ebp
  800272:	57                   	push   %edi
  800273:	56                   	push   %esi
  800274:	53                   	push   %ebx
  800275:	83 ec 2c             	sub    $0x2c,%esp
  800278:	8b 75 08             	mov    0x8(%ebp),%esi
  80027b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80027e:	8b 7d 10             	mov    0x10(%ebp),%edi
  800281:	e9 c1 03 00 00       	jmp    800647 <vprintfmt+0x3d8>
		padc = ' ';
  800286:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
  80028a:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
  800291:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
		width = -1;
  800298:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
  80029f:	b9 00 00 00 00       	mov    $0x0,%ecx
		switch (ch = *(unsigned char *) fmt++) {
  8002a4:	8d 47 01             	lea    0x1(%edi),%eax
  8002a7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8002aa:	0f b6 17             	movzbl (%edi),%edx
  8002ad:	8d 42 dd             	lea    -0x23(%edx),%eax
  8002b0:	3c 55                	cmp    $0x55,%al
  8002b2:	0f 87 12 04 00 00    	ja     8006ca <vprintfmt+0x45b>
  8002b8:	0f b6 c0             	movzbl %al,%eax
  8002bb:	ff 24 85 c0 0d 80 00 	jmp    *0x800dc0(,%eax,4)
  8002c2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
  8002c5:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
  8002c9:	eb d9                	jmp    8002a4 <vprintfmt+0x35>
		switch (ch = *(unsigned char *) fmt++) {
  8002cb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '0';
  8002ce:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  8002d2:	eb d0                	jmp    8002a4 <vprintfmt+0x35>
		switch (ch = *(unsigned char *) fmt++) {
  8002d4:	0f b6 d2             	movzbl %dl,%edx
  8002d7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
  8002da:	b8 00 00 00 00       	mov    $0x0,%eax
  8002df:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
				precision = precision * 10 + ch - '0';
  8002e2:	8d 04 80             	lea    (%eax,%eax,4),%eax
  8002e5:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
  8002e9:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
  8002ec:	8d 4a d0             	lea    -0x30(%edx),%ecx
  8002ef:	83 f9 09             	cmp    $0x9,%ecx
  8002f2:	77 55                	ja     800349 <vprintfmt+0xda>
			for (precision = 0; ; ++fmt) {
  8002f4:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
  8002f7:	eb e9                	jmp    8002e2 <vprintfmt+0x73>
			precision = va_arg(ap, int);
  8002f9:	8b 45 14             	mov    0x14(%ebp),%eax
  8002fc:	8b 00                	mov    (%eax),%eax
  8002fe:	89 45 d0             	mov    %eax,-0x30(%ebp)
  800301:	8b 45 14             	mov    0x14(%ebp),%eax
  800304:	8d 40 04             	lea    0x4(%eax),%eax
  800307:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
  80030a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
  80030d:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800311:	79 91                	jns    8002a4 <vprintfmt+0x35>
				width = precision, precision = -1;
  800313:	8b 45 d0             	mov    -0x30(%ebp),%eax
  800316:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800319:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800320:	eb 82                	jmp    8002a4 <vprintfmt+0x35>
  800322:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800325:	85 c0                	test   %eax,%eax
  800327:	ba 00 00 00 00       	mov    $0x0,%edx
  80032c:	0f 49 d0             	cmovns %eax,%edx
  80032f:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
  800332:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800335:	e9 6a ff ff ff       	jmp    8002a4 <vprintfmt+0x35>
  80033a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
  80033d:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  800344:	e9 5b ff ff ff       	jmp    8002a4 <vprintfmt+0x35>
  800349:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  80034c:	89 45 d0             	mov    %eax,-0x30(%ebp)
  80034f:	eb bc                	jmp    80030d <vprintfmt+0x9e>
			lflag++;
  800351:	83 c1 01             	add    $0x1,%ecx
		switch (ch = *(unsigned char *) fmt++) {
  800354:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
  800357:	e9 48 ff ff ff       	jmp    8002a4 <vprintfmt+0x35>
			putch(va_arg(ap, int), putdat);
  80035c:	8b 45 14             	mov    0x14(%ebp),%eax
  80035f:	8d 78 04             	lea    0x4(%eax),%edi
  800362:	83 ec 08             	sub    $0x8,%esp
  800365:	53                   	push   %ebx
  800366:	ff 30                	pushl  (%eax)
  800368:	ff d6                	call   *%esi
			break;
  80036a:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
  80036d:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
  800370:	e9 cf 02 00 00       	jmp    800644 <vprintfmt+0x3d5>
			err = va_arg(ap, int);
  800375:	8b 45 14             	mov    0x14(%ebp),%eax
  800378:	8d 78 04             	lea    0x4(%eax),%edi
  80037b:	8b 00                	mov    (%eax),%eax
  80037d:	99                   	cltd   
  80037e:	31 d0                	xor    %edx,%eax
  800380:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800382:	83 f8 06             	cmp    $0x6,%eax
  800385:	7f 23                	jg     8003aa <vprintfmt+0x13b>
  800387:	8b 14 85 18 0f 80 00 	mov    0x800f18(,%eax,4),%edx
  80038e:	85 d2                	test   %edx,%edx
  800390:	74 18                	je     8003aa <vprintfmt+0x13b>
				printfmt(putch, putdat, "%s", p);
  800392:	52                   	push   %edx
  800393:	68 52 0d 80 00       	push   $0x800d52
  800398:	53                   	push   %ebx
  800399:	56                   	push   %esi
  80039a:	e8 b3 fe ff ff       	call   800252 <printfmt>
  80039f:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
  8003a2:	89 7d 14             	mov    %edi,0x14(%ebp)
  8003a5:	e9 9a 02 00 00       	jmp    800644 <vprintfmt+0x3d5>
				printfmt(putch, putdat, "error %d", err);
  8003aa:	50                   	push   %eax
  8003ab:	68 49 0d 80 00       	push   $0x800d49
  8003b0:	53                   	push   %ebx
  8003b1:	56                   	push   %esi
  8003b2:	e8 9b fe ff ff       	call   800252 <printfmt>
  8003b7:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
  8003ba:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
  8003bd:	e9 82 02 00 00       	jmp    800644 <vprintfmt+0x3d5>
			if ((p = va_arg(ap, char *)) == NULL)
  8003c2:	8b 45 14             	mov    0x14(%ebp),%eax
  8003c5:	83 c0 04             	add    $0x4,%eax
  8003c8:	89 45 cc             	mov    %eax,-0x34(%ebp)
  8003cb:	8b 45 14             	mov    0x14(%ebp),%eax
  8003ce:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  8003d0:	85 ff                	test   %edi,%edi
  8003d2:	b8 42 0d 80 00       	mov    $0x800d42,%eax
  8003d7:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  8003da:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8003de:	0f 8e bd 00 00 00    	jle    8004a1 <vprintfmt+0x232>
  8003e4:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  8003e8:	75 0e                	jne    8003f8 <vprintfmt+0x189>
  8003ea:	89 75 08             	mov    %esi,0x8(%ebp)
  8003ed:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8003f0:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8003f3:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  8003f6:	eb 6d                	jmp    800465 <vprintfmt+0x1f6>
				for (width -= strnlen(p, precision); width > 0; width--)
  8003f8:	83 ec 08             	sub    $0x8,%esp
  8003fb:	ff 75 d0             	pushl  -0x30(%ebp)
  8003fe:	57                   	push   %edi
  8003ff:	e8 6e 03 00 00       	call   800772 <strnlen>
  800404:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  800407:	29 c1                	sub    %eax,%ecx
  800409:	89 4d c8             	mov    %ecx,-0x38(%ebp)
  80040c:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  80040f:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  800413:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800416:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  800419:	89 cf                	mov    %ecx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
  80041b:	eb 0f                	jmp    80042c <vprintfmt+0x1bd>
					putch(padc, putdat);
  80041d:	83 ec 08             	sub    $0x8,%esp
  800420:	53                   	push   %ebx
  800421:	ff 75 e0             	pushl  -0x20(%ebp)
  800424:	ff d6                	call   *%esi
				for (width -= strnlen(p, precision); width > 0; width--)
  800426:	83 ef 01             	sub    $0x1,%edi
  800429:	83 c4 10             	add    $0x10,%esp
  80042c:	85 ff                	test   %edi,%edi
  80042e:	7f ed                	jg     80041d <vprintfmt+0x1ae>
  800430:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  800433:	8b 4d c8             	mov    -0x38(%ebp),%ecx
  800436:	85 c9                	test   %ecx,%ecx
  800438:	b8 00 00 00 00       	mov    $0x0,%eax
  80043d:	0f 49 c1             	cmovns %ecx,%eax
  800440:	29 c1                	sub    %eax,%ecx
  800442:	89 75 08             	mov    %esi,0x8(%ebp)
  800445:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800448:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80044b:	89 cb                	mov    %ecx,%ebx
  80044d:	eb 16                	jmp    800465 <vprintfmt+0x1f6>
				if (altflag && (ch < ' ' || ch > '~'))
  80044f:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  800453:	75 31                	jne    800486 <vprintfmt+0x217>
					putch(ch, putdat);
  800455:	83 ec 08             	sub    $0x8,%esp
  800458:	ff 75 0c             	pushl  0xc(%ebp)
  80045b:	50                   	push   %eax
  80045c:	ff 55 08             	call   *0x8(%ebp)
  80045f:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800462:	83 eb 01             	sub    $0x1,%ebx
  800465:	83 c7 01             	add    $0x1,%edi
  800468:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
  80046c:	0f be c2             	movsbl %dl,%eax
  80046f:	85 c0                	test   %eax,%eax
  800471:	74 59                	je     8004cc <vprintfmt+0x25d>
  800473:	85 f6                	test   %esi,%esi
  800475:	78 d8                	js     80044f <vprintfmt+0x1e0>
  800477:	83 ee 01             	sub    $0x1,%esi
  80047a:	79 d3                	jns    80044f <vprintfmt+0x1e0>
  80047c:	89 df                	mov    %ebx,%edi
  80047e:	8b 75 08             	mov    0x8(%ebp),%esi
  800481:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800484:	eb 37                	jmp    8004bd <vprintfmt+0x24e>
				if (altflag && (ch < ' ' || ch > '~'))
  800486:	0f be d2             	movsbl %dl,%edx
  800489:	83 ea 20             	sub    $0x20,%edx
  80048c:	83 fa 5e             	cmp    $0x5e,%edx
  80048f:	76 c4                	jbe    800455 <vprintfmt+0x1e6>
					putch('?', putdat);
  800491:	83 ec 08             	sub    $0x8,%esp
  800494:	ff 75 0c             	pushl  0xc(%ebp)
  800497:	6a 3f                	push   $0x3f
  800499:	ff 55 08             	call   *0x8(%ebp)
  80049c:	83 c4 10             	add    $0x10,%esp
  80049f:	eb c1                	jmp    800462 <vprintfmt+0x1f3>
  8004a1:	89 75 08             	mov    %esi,0x8(%ebp)
  8004a4:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8004a7:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8004aa:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  8004ad:	eb b6                	jmp    800465 <vprintfmt+0x1f6>
				putch(' ', putdat);
  8004af:	83 ec 08             	sub    $0x8,%esp
  8004b2:	53                   	push   %ebx
  8004b3:	6a 20                	push   $0x20
  8004b5:	ff d6                	call   *%esi
			for (; width > 0; width--)
  8004b7:	83 ef 01             	sub    $0x1,%edi
  8004ba:	83 c4 10             	add    $0x10,%esp
  8004bd:	85 ff                	test   %edi,%edi
  8004bf:	7f ee                	jg     8004af <vprintfmt+0x240>
			if ((p = va_arg(ap, char *)) == NULL)
  8004c1:	8b 45 cc             	mov    -0x34(%ebp),%eax
  8004c4:	89 45 14             	mov    %eax,0x14(%ebp)
  8004c7:	e9 78 01 00 00       	jmp    800644 <vprintfmt+0x3d5>
  8004cc:	89 df                	mov    %ebx,%edi
  8004ce:	8b 75 08             	mov    0x8(%ebp),%esi
  8004d1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8004d4:	eb e7                	jmp    8004bd <vprintfmt+0x24e>
	if (lflag >= 2)
  8004d6:	83 f9 01             	cmp    $0x1,%ecx
  8004d9:	7e 3f                	jle    80051a <vprintfmt+0x2ab>
		return va_arg(*ap, long long);
  8004db:	8b 45 14             	mov    0x14(%ebp),%eax
  8004de:	8b 50 04             	mov    0x4(%eax),%edx
  8004e1:	8b 00                	mov    (%eax),%eax
  8004e3:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8004e6:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8004e9:	8b 45 14             	mov    0x14(%ebp),%eax
  8004ec:	8d 40 08             	lea    0x8(%eax),%eax
  8004ef:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
  8004f2:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  8004f6:	79 5c                	jns    800554 <vprintfmt+0x2e5>
				putch('-', putdat);
  8004f8:	83 ec 08             	sub    $0x8,%esp
  8004fb:	53                   	push   %ebx
  8004fc:	6a 2d                	push   $0x2d
  8004fe:	ff d6                	call   *%esi
				num = -(long long) num;
  800500:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800503:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  800506:	f7 da                	neg    %edx
  800508:	83 d1 00             	adc    $0x0,%ecx
  80050b:	f7 d9                	neg    %ecx
  80050d:	83 c4 10             	add    $0x10,%esp
			base = 10;
  800510:	b8 0a 00 00 00       	mov    $0xa,%eax
  800515:	e9 10 01 00 00       	jmp    80062a <vprintfmt+0x3bb>
	else if (lflag)
  80051a:	85 c9                	test   %ecx,%ecx
  80051c:	75 1b                	jne    800539 <vprintfmt+0x2ca>
		return va_arg(*ap, int);
  80051e:	8b 45 14             	mov    0x14(%ebp),%eax
  800521:	8b 00                	mov    (%eax),%eax
  800523:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800526:	89 c1                	mov    %eax,%ecx
  800528:	c1 f9 1f             	sar    $0x1f,%ecx
  80052b:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  80052e:	8b 45 14             	mov    0x14(%ebp),%eax
  800531:	8d 40 04             	lea    0x4(%eax),%eax
  800534:	89 45 14             	mov    %eax,0x14(%ebp)
  800537:	eb b9                	jmp    8004f2 <vprintfmt+0x283>
		return va_arg(*ap, long);
  800539:	8b 45 14             	mov    0x14(%ebp),%eax
  80053c:	8b 00                	mov    (%eax),%eax
  80053e:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800541:	89 c1                	mov    %eax,%ecx
  800543:	c1 f9 1f             	sar    $0x1f,%ecx
  800546:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  800549:	8b 45 14             	mov    0x14(%ebp),%eax
  80054c:	8d 40 04             	lea    0x4(%eax),%eax
  80054f:	89 45 14             	mov    %eax,0x14(%ebp)
  800552:	eb 9e                	jmp    8004f2 <vprintfmt+0x283>
			num = getint(&ap, lflag);
  800554:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800557:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
  80055a:	b8 0a 00 00 00       	mov    $0xa,%eax
  80055f:	e9 c6 00 00 00       	jmp    80062a <vprintfmt+0x3bb>
	if (lflag >= 2)
  800564:	83 f9 01             	cmp    $0x1,%ecx
  800567:	7e 18                	jle    800581 <vprintfmt+0x312>
		return va_arg(*ap, unsigned long long);
  800569:	8b 45 14             	mov    0x14(%ebp),%eax
  80056c:	8b 10                	mov    (%eax),%edx
  80056e:	8b 48 04             	mov    0x4(%eax),%ecx
  800571:	8d 40 08             	lea    0x8(%eax),%eax
  800574:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
  800577:	b8 0a 00 00 00       	mov    $0xa,%eax
  80057c:	e9 a9 00 00 00       	jmp    80062a <vprintfmt+0x3bb>
	else if (lflag)
  800581:	85 c9                	test   %ecx,%ecx
  800583:	75 1a                	jne    80059f <vprintfmt+0x330>
		return va_arg(*ap, unsigned int);
  800585:	8b 45 14             	mov    0x14(%ebp),%eax
  800588:	8b 10                	mov    (%eax),%edx
  80058a:	b9 00 00 00 00       	mov    $0x0,%ecx
  80058f:	8d 40 04             	lea    0x4(%eax),%eax
  800592:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
  800595:	b8 0a 00 00 00       	mov    $0xa,%eax
  80059a:	e9 8b 00 00 00       	jmp    80062a <vprintfmt+0x3bb>
		return va_arg(*ap, unsigned long);
  80059f:	8b 45 14             	mov    0x14(%ebp),%eax
  8005a2:	8b 10                	mov    (%eax),%edx
  8005a4:	b9 00 00 00 00       	mov    $0x0,%ecx
  8005a9:	8d 40 04             	lea    0x4(%eax),%eax
  8005ac:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
  8005af:	b8 0a 00 00 00       	mov    $0xa,%eax
  8005b4:	eb 74                	jmp    80062a <vprintfmt+0x3bb>
	if (lflag >= 2)
  8005b6:	83 f9 01             	cmp    $0x1,%ecx
  8005b9:	7e 15                	jle    8005d0 <vprintfmt+0x361>
		return va_arg(*ap, unsigned long long);
  8005bb:	8b 45 14             	mov    0x14(%ebp),%eax
  8005be:	8b 10                	mov    (%eax),%edx
  8005c0:	8b 48 04             	mov    0x4(%eax),%ecx
  8005c3:	8d 40 08             	lea    0x8(%eax),%eax
  8005c6:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
  8005c9:	b8 08 00 00 00       	mov    $0x8,%eax
  8005ce:	eb 5a                	jmp    80062a <vprintfmt+0x3bb>
	else if (lflag)
  8005d0:	85 c9                	test   %ecx,%ecx
  8005d2:	75 17                	jne    8005eb <vprintfmt+0x37c>
		return va_arg(*ap, unsigned int);
  8005d4:	8b 45 14             	mov    0x14(%ebp),%eax
  8005d7:	8b 10                	mov    (%eax),%edx
  8005d9:	b9 00 00 00 00       	mov    $0x0,%ecx
  8005de:	8d 40 04             	lea    0x4(%eax),%eax
  8005e1:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
  8005e4:	b8 08 00 00 00       	mov    $0x8,%eax
  8005e9:	eb 3f                	jmp    80062a <vprintfmt+0x3bb>
		return va_arg(*ap, unsigned long);
  8005eb:	8b 45 14             	mov    0x14(%ebp),%eax
  8005ee:	8b 10                	mov    (%eax),%edx
  8005f0:	b9 00 00 00 00       	mov    $0x0,%ecx
  8005f5:	8d 40 04             	lea    0x4(%eax),%eax
  8005f8:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
  8005fb:	b8 08 00 00 00       	mov    $0x8,%eax
  800600:	eb 28                	jmp    80062a <vprintfmt+0x3bb>
			putch('0', putdat);
  800602:	83 ec 08             	sub    $0x8,%esp
  800605:	53                   	push   %ebx
  800606:	6a 30                	push   $0x30
  800608:	ff d6                	call   *%esi
			putch('x', putdat);
  80060a:	83 c4 08             	add    $0x8,%esp
  80060d:	53                   	push   %ebx
  80060e:	6a 78                	push   $0x78
  800610:	ff d6                	call   *%esi
			num = (unsigned long long)
  800612:	8b 45 14             	mov    0x14(%ebp),%eax
  800615:	8b 10                	mov    (%eax),%edx
  800617:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
  80061c:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
  80061f:	8d 40 04             	lea    0x4(%eax),%eax
  800622:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  800625:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
  80062a:	83 ec 0c             	sub    $0xc,%esp
  80062d:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  800631:	57                   	push   %edi
  800632:	ff 75 e0             	pushl  -0x20(%ebp)
  800635:	50                   	push   %eax
  800636:	51                   	push   %ecx
  800637:	52                   	push   %edx
  800638:	89 da                	mov    %ebx,%edx
  80063a:	89 f0                	mov    %esi,%eax
  80063c:	e8 45 fb ff ff       	call   800186 <printnum>
			break;
  800641:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
  800644:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800647:	83 c7 01             	add    $0x1,%edi
  80064a:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  80064e:	83 f8 25             	cmp    $0x25,%eax
  800651:	0f 84 2f fc ff ff    	je     800286 <vprintfmt+0x17>
			if (ch == '\0')
  800657:	85 c0                	test   %eax,%eax
  800659:	0f 84 8b 00 00 00    	je     8006ea <vprintfmt+0x47b>
			putch(ch, putdat);
  80065f:	83 ec 08             	sub    $0x8,%esp
  800662:	53                   	push   %ebx
  800663:	50                   	push   %eax
  800664:	ff d6                	call   *%esi
  800666:	83 c4 10             	add    $0x10,%esp
  800669:	eb dc                	jmp    800647 <vprintfmt+0x3d8>
	if (lflag >= 2)
  80066b:	83 f9 01             	cmp    $0x1,%ecx
  80066e:	7e 15                	jle    800685 <vprintfmt+0x416>
		return va_arg(*ap, unsigned long long);
  800670:	8b 45 14             	mov    0x14(%ebp),%eax
  800673:	8b 10                	mov    (%eax),%edx
  800675:	8b 48 04             	mov    0x4(%eax),%ecx
  800678:	8d 40 08             	lea    0x8(%eax),%eax
  80067b:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  80067e:	b8 10 00 00 00       	mov    $0x10,%eax
  800683:	eb a5                	jmp    80062a <vprintfmt+0x3bb>
	else if (lflag)
  800685:	85 c9                	test   %ecx,%ecx
  800687:	75 17                	jne    8006a0 <vprintfmt+0x431>
		return va_arg(*ap, unsigned int);
  800689:	8b 45 14             	mov    0x14(%ebp),%eax
  80068c:	8b 10                	mov    (%eax),%edx
  80068e:	b9 00 00 00 00       	mov    $0x0,%ecx
  800693:	8d 40 04             	lea    0x4(%eax),%eax
  800696:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  800699:	b8 10 00 00 00       	mov    $0x10,%eax
  80069e:	eb 8a                	jmp    80062a <vprintfmt+0x3bb>
		return va_arg(*ap, unsigned long);
  8006a0:	8b 45 14             	mov    0x14(%ebp),%eax
  8006a3:	8b 10                	mov    (%eax),%edx
  8006a5:	b9 00 00 00 00       	mov    $0x0,%ecx
  8006aa:	8d 40 04             	lea    0x4(%eax),%eax
  8006ad:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  8006b0:	b8 10 00 00 00       	mov    $0x10,%eax
  8006b5:	e9 70 ff ff ff       	jmp    80062a <vprintfmt+0x3bb>
			putch(ch, putdat);
  8006ba:	83 ec 08             	sub    $0x8,%esp
  8006bd:	53                   	push   %ebx
  8006be:	6a 25                	push   $0x25
  8006c0:	ff d6                	call   *%esi
			break;
  8006c2:	83 c4 10             	add    $0x10,%esp
  8006c5:	e9 7a ff ff ff       	jmp    800644 <vprintfmt+0x3d5>
			putch('%', putdat);
  8006ca:	83 ec 08             	sub    $0x8,%esp
  8006cd:	53                   	push   %ebx
  8006ce:	6a 25                	push   $0x25
  8006d0:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  8006d2:	83 c4 10             	add    $0x10,%esp
  8006d5:	89 f8                	mov    %edi,%eax
  8006d7:	eb 03                	jmp    8006dc <vprintfmt+0x46d>
  8006d9:	83 e8 01             	sub    $0x1,%eax
  8006dc:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
  8006e0:	75 f7                	jne    8006d9 <vprintfmt+0x46a>
  8006e2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8006e5:	e9 5a ff ff ff       	jmp    800644 <vprintfmt+0x3d5>
}
  8006ea:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8006ed:	5b                   	pop    %ebx
  8006ee:	5e                   	pop    %esi
  8006ef:	5f                   	pop    %edi
  8006f0:	5d                   	pop    %ebp
  8006f1:	c3                   	ret    

008006f2 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  8006f2:	55                   	push   %ebp
  8006f3:	89 e5                	mov    %esp,%ebp
  8006f5:	83 ec 18             	sub    $0x18,%esp
  8006f8:	8b 45 08             	mov    0x8(%ebp),%eax
  8006fb:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  8006fe:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800701:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800705:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800708:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  80070f:	85 c0                	test   %eax,%eax
  800711:	74 26                	je     800739 <vsnprintf+0x47>
  800713:	85 d2                	test   %edx,%edx
  800715:	7e 22                	jle    800739 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800717:	ff 75 14             	pushl  0x14(%ebp)
  80071a:	ff 75 10             	pushl  0x10(%ebp)
  80071d:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800720:	50                   	push   %eax
  800721:	68 35 02 80 00       	push   $0x800235
  800726:	e8 44 fb ff ff       	call   80026f <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  80072b:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80072e:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800731:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800734:	83 c4 10             	add    $0x10,%esp
}
  800737:	c9                   	leave  
  800738:	c3                   	ret    
		return -E_INVAL;
  800739:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
  80073e:	eb f7                	jmp    800737 <vsnprintf+0x45>

00800740 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800740:	55                   	push   %ebp
  800741:	89 e5                	mov    %esp,%ebp
  800743:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800746:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800749:	50                   	push   %eax
  80074a:	ff 75 10             	pushl  0x10(%ebp)
  80074d:	ff 75 0c             	pushl  0xc(%ebp)
  800750:	ff 75 08             	pushl  0x8(%ebp)
  800753:	e8 9a ff ff ff       	call   8006f2 <vsnprintf>
	va_end(ap);

	return rc;
}
  800758:	c9                   	leave  
  800759:	c3                   	ret    

0080075a <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  80075a:	55                   	push   %ebp
  80075b:	89 e5                	mov    %esp,%ebp
  80075d:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800760:	b8 00 00 00 00       	mov    $0x0,%eax
  800765:	eb 03                	jmp    80076a <strlen+0x10>
		n++;
  800767:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
  80076a:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  80076e:	75 f7                	jne    800767 <strlen+0xd>
	return n;
}
  800770:	5d                   	pop    %ebp
  800771:	c3                   	ret    

00800772 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800772:	55                   	push   %ebp
  800773:	89 e5                	mov    %esp,%ebp
  800775:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800778:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80077b:	b8 00 00 00 00       	mov    $0x0,%eax
  800780:	eb 03                	jmp    800785 <strnlen+0x13>
		n++;
  800782:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800785:	39 d0                	cmp    %edx,%eax
  800787:	74 06                	je     80078f <strnlen+0x1d>
  800789:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
  80078d:	75 f3                	jne    800782 <strnlen+0x10>
	return n;
}
  80078f:	5d                   	pop    %ebp
  800790:	c3                   	ret    

00800791 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800791:	55                   	push   %ebp
  800792:	89 e5                	mov    %esp,%ebp
  800794:	53                   	push   %ebx
  800795:	8b 45 08             	mov    0x8(%ebp),%eax
  800798:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  80079b:	89 c2                	mov    %eax,%edx
  80079d:	83 c1 01             	add    $0x1,%ecx
  8007a0:	83 c2 01             	add    $0x1,%edx
  8007a3:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  8007a7:	88 5a ff             	mov    %bl,-0x1(%edx)
  8007aa:	84 db                	test   %bl,%bl
  8007ac:	75 ef                	jne    80079d <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8007ae:	5b                   	pop    %ebx
  8007af:	5d                   	pop    %ebp
  8007b0:	c3                   	ret    

008007b1 <strcat>:

char *
strcat(char *dst, const char *src)
{
  8007b1:	55                   	push   %ebp
  8007b2:	89 e5                	mov    %esp,%ebp
  8007b4:	53                   	push   %ebx
  8007b5:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8007b8:	53                   	push   %ebx
  8007b9:	e8 9c ff ff ff       	call   80075a <strlen>
  8007be:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  8007c1:	ff 75 0c             	pushl  0xc(%ebp)
  8007c4:	01 d8                	add    %ebx,%eax
  8007c6:	50                   	push   %eax
  8007c7:	e8 c5 ff ff ff       	call   800791 <strcpy>
	return dst;
}
  8007cc:	89 d8                	mov    %ebx,%eax
  8007ce:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8007d1:	c9                   	leave  
  8007d2:	c3                   	ret    

008007d3 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8007d3:	55                   	push   %ebp
  8007d4:	89 e5                	mov    %esp,%ebp
  8007d6:	56                   	push   %esi
  8007d7:	53                   	push   %ebx
  8007d8:	8b 75 08             	mov    0x8(%ebp),%esi
  8007db:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8007de:	89 f3                	mov    %esi,%ebx
  8007e0:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007e3:	89 f2                	mov    %esi,%edx
  8007e5:	eb 0f                	jmp    8007f6 <strncpy+0x23>
		*dst++ = *src;
  8007e7:	83 c2 01             	add    $0x1,%edx
  8007ea:	0f b6 01             	movzbl (%ecx),%eax
  8007ed:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  8007f0:	80 39 01             	cmpb   $0x1,(%ecx)
  8007f3:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
  8007f6:	39 da                	cmp    %ebx,%edx
  8007f8:	75 ed                	jne    8007e7 <strncpy+0x14>
	}
	return ret;
}
  8007fa:	89 f0                	mov    %esi,%eax
  8007fc:	5b                   	pop    %ebx
  8007fd:	5e                   	pop    %esi
  8007fe:	5d                   	pop    %ebp
  8007ff:	c3                   	ret    

00800800 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800800:	55                   	push   %ebp
  800801:	89 e5                	mov    %esp,%ebp
  800803:	56                   	push   %esi
  800804:	53                   	push   %ebx
  800805:	8b 75 08             	mov    0x8(%ebp),%esi
  800808:	8b 55 0c             	mov    0xc(%ebp),%edx
  80080b:	8b 4d 10             	mov    0x10(%ebp),%ecx
  80080e:	89 f0                	mov    %esi,%eax
  800810:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800814:	85 c9                	test   %ecx,%ecx
  800816:	75 0b                	jne    800823 <strlcpy+0x23>
  800818:	eb 17                	jmp    800831 <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  80081a:	83 c2 01             	add    $0x1,%edx
  80081d:	83 c0 01             	add    $0x1,%eax
  800820:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
  800823:	39 d8                	cmp    %ebx,%eax
  800825:	74 07                	je     80082e <strlcpy+0x2e>
  800827:	0f b6 0a             	movzbl (%edx),%ecx
  80082a:	84 c9                	test   %cl,%cl
  80082c:	75 ec                	jne    80081a <strlcpy+0x1a>
		*dst = '\0';
  80082e:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800831:	29 f0                	sub    %esi,%eax
}
  800833:	5b                   	pop    %ebx
  800834:	5e                   	pop    %esi
  800835:	5d                   	pop    %ebp
  800836:	c3                   	ret    

00800837 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800837:	55                   	push   %ebp
  800838:	89 e5                	mov    %esp,%ebp
  80083a:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80083d:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800840:	eb 06                	jmp    800848 <strcmp+0x11>
		p++, q++;
  800842:	83 c1 01             	add    $0x1,%ecx
  800845:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
  800848:	0f b6 01             	movzbl (%ecx),%eax
  80084b:	84 c0                	test   %al,%al
  80084d:	74 04                	je     800853 <strcmp+0x1c>
  80084f:	3a 02                	cmp    (%edx),%al
  800851:	74 ef                	je     800842 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800853:	0f b6 c0             	movzbl %al,%eax
  800856:	0f b6 12             	movzbl (%edx),%edx
  800859:	29 d0                	sub    %edx,%eax
}
  80085b:	5d                   	pop    %ebp
  80085c:	c3                   	ret    

0080085d <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  80085d:	55                   	push   %ebp
  80085e:	89 e5                	mov    %esp,%ebp
  800860:	53                   	push   %ebx
  800861:	8b 45 08             	mov    0x8(%ebp),%eax
  800864:	8b 55 0c             	mov    0xc(%ebp),%edx
  800867:	89 c3                	mov    %eax,%ebx
  800869:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  80086c:	eb 06                	jmp    800874 <strncmp+0x17>
		n--, p++, q++;
  80086e:	83 c0 01             	add    $0x1,%eax
  800871:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
  800874:	39 d8                	cmp    %ebx,%eax
  800876:	74 16                	je     80088e <strncmp+0x31>
  800878:	0f b6 08             	movzbl (%eax),%ecx
  80087b:	84 c9                	test   %cl,%cl
  80087d:	74 04                	je     800883 <strncmp+0x26>
  80087f:	3a 0a                	cmp    (%edx),%cl
  800881:	74 eb                	je     80086e <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800883:	0f b6 00             	movzbl (%eax),%eax
  800886:	0f b6 12             	movzbl (%edx),%edx
  800889:	29 d0                	sub    %edx,%eax
}
  80088b:	5b                   	pop    %ebx
  80088c:	5d                   	pop    %ebp
  80088d:	c3                   	ret    
		return 0;
  80088e:	b8 00 00 00 00       	mov    $0x0,%eax
  800893:	eb f6                	jmp    80088b <strncmp+0x2e>

00800895 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800895:	55                   	push   %ebp
  800896:	89 e5                	mov    %esp,%ebp
  800898:	8b 45 08             	mov    0x8(%ebp),%eax
  80089b:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  80089f:	0f b6 10             	movzbl (%eax),%edx
  8008a2:	84 d2                	test   %dl,%dl
  8008a4:	74 09                	je     8008af <strchr+0x1a>
		if (*s == c)
  8008a6:	38 ca                	cmp    %cl,%dl
  8008a8:	74 0a                	je     8008b4 <strchr+0x1f>
	for (; *s; s++)
  8008aa:	83 c0 01             	add    $0x1,%eax
  8008ad:	eb f0                	jmp    80089f <strchr+0xa>
			return (char *) s;
	return 0;
  8008af:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8008b4:	5d                   	pop    %ebp
  8008b5:	c3                   	ret    

008008b6 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8008b6:	55                   	push   %ebp
  8008b7:	89 e5                	mov    %esp,%ebp
  8008b9:	8b 45 08             	mov    0x8(%ebp),%eax
  8008bc:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8008c0:	eb 03                	jmp    8008c5 <strfind+0xf>
  8008c2:	83 c0 01             	add    $0x1,%eax
  8008c5:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  8008c8:	38 ca                	cmp    %cl,%dl
  8008ca:	74 04                	je     8008d0 <strfind+0x1a>
  8008cc:	84 d2                	test   %dl,%dl
  8008ce:	75 f2                	jne    8008c2 <strfind+0xc>
			break;
	return (char *) s;
}
  8008d0:	5d                   	pop    %ebp
  8008d1:	c3                   	ret    

008008d2 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  8008d2:	55                   	push   %ebp
  8008d3:	89 e5                	mov    %esp,%ebp
  8008d5:	57                   	push   %edi
  8008d6:	56                   	push   %esi
  8008d7:	53                   	push   %ebx
  8008d8:	8b 7d 08             	mov    0x8(%ebp),%edi
  8008db:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  8008de:	85 c9                	test   %ecx,%ecx
  8008e0:	74 13                	je     8008f5 <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  8008e2:	f7 c7 03 00 00 00    	test   $0x3,%edi
  8008e8:	75 05                	jne    8008ef <memset+0x1d>
  8008ea:	f6 c1 03             	test   $0x3,%cl
  8008ed:	74 0d                	je     8008fc <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  8008ef:	8b 45 0c             	mov    0xc(%ebp),%eax
  8008f2:	fc                   	cld    
  8008f3:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  8008f5:	89 f8                	mov    %edi,%eax
  8008f7:	5b                   	pop    %ebx
  8008f8:	5e                   	pop    %esi
  8008f9:	5f                   	pop    %edi
  8008fa:	5d                   	pop    %ebp
  8008fb:	c3                   	ret    
		c &= 0xFF;
  8008fc:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800900:	89 d3                	mov    %edx,%ebx
  800902:	c1 e3 08             	shl    $0x8,%ebx
  800905:	89 d0                	mov    %edx,%eax
  800907:	c1 e0 18             	shl    $0x18,%eax
  80090a:	89 d6                	mov    %edx,%esi
  80090c:	c1 e6 10             	shl    $0x10,%esi
  80090f:	09 f0                	or     %esi,%eax
  800911:	09 c2                	or     %eax,%edx
  800913:	09 da                	or     %ebx,%edx
			:: "D" (v), "a" (c), "c" (n/4)
  800915:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
  800918:	89 d0                	mov    %edx,%eax
  80091a:	fc                   	cld    
  80091b:	f3 ab                	rep stos %eax,%es:(%edi)
  80091d:	eb d6                	jmp    8008f5 <memset+0x23>

0080091f <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  80091f:	55                   	push   %ebp
  800920:	89 e5                	mov    %esp,%ebp
  800922:	57                   	push   %edi
  800923:	56                   	push   %esi
  800924:	8b 45 08             	mov    0x8(%ebp),%eax
  800927:	8b 75 0c             	mov    0xc(%ebp),%esi
  80092a:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  80092d:	39 c6                	cmp    %eax,%esi
  80092f:	73 35                	jae    800966 <memmove+0x47>
  800931:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800934:	39 c2                	cmp    %eax,%edx
  800936:	76 2e                	jbe    800966 <memmove+0x47>
		s += n;
		d += n;
  800938:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  80093b:	89 d6                	mov    %edx,%esi
  80093d:	09 fe                	or     %edi,%esi
  80093f:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800945:	74 0c                	je     800953 <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  800947:	83 ef 01             	sub    $0x1,%edi
  80094a:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
  80094d:	fd                   	std    
  80094e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800950:	fc                   	cld    
  800951:	eb 21                	jmp    800974 <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800953:	f6 c1 03             	test   $0x3,%cl
  800956:	75 ef                	jne    800947 <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  800958:	83 ef 04             	sub    $0x4,%edi
  80095b:	8d 72 fc             	lea    -0x4(%edx),%esi
  80095e:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
  800961:	fd                   	std    
  800962:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800964:	eb ea                	jmp    800950 <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800966:	89 f2                	mov    %esi,%edx
  800968:	09 c2                	or     %eax,%edx
  80096a:	f6 c2 03             	test   $0x3,%dl
  80096d:	74 09                	je     800978 <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  80096f:	89 c7                	mov    %eax,%edi
  800971:	fc                   	cld    
  800972:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800974:	5e                   	pop    %esi
  800975:	5f                   	pop    %edi
  800976:	5d                   	pop    %ebp
  800977:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800978:	f6 c1 03             	test   $0x3,%cl
  80097b:	75 f2                	jne    80096f <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  80097d:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
  800980:	89 c7                	mov    %eax,%edi
  800982:	fc                   	cld    
  800983:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800985:	eb ed                	jmp    800974 <memmove+0x55>

00800987 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800987:	55                   	push   %ebp
  800988:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  80098a:	ff 75 10             	pushl  0x10(%ebp)
  80098d:	ff 75 0c             	pushl  0xc(%ebp)
  800990:	ff 75 08             	pushl  0x8(%ebp)
  800993:	e8 87 ff ff ff       	call   80091f <memmove>
}
  800998:	c9                   	leave  
  800999:	c3                   	ret    

0080099a <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  80099a:	55                   	push   %ebp
  80099b:	89 e5                	mov    %esp,%ebp
  80099d:	56                   	push   %esi
  80099e:	53                   	push   %ebx
  80099f:	8b 45 08             	mov    0x8(%ebp),%eax
  8009a2:	8b 55 0c             	mov    0xc(%ebp),%edx
  8009a5:	89 c6                	mov    %eax,%esi
  8009a7:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009aa:	39 f0                	cmp    %esi,%eax
  8009ac:	74 1c                	je     8009ca <memcmp+0x30>
		if (*s1 != *s2)
  8009ae:	0f b6 08             	movzbl (%eax),%ecx
  8009b1:	0f b6 1a             	movzbl (%edx),%ebx
  8009b4:	38 d9                	cmp    %bl,%cl
  8009b6:	75 08                	jne    8009c0 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
  8009b8:	83 c0 01             	add    $0x1,%eax
  8009bb:	83 c2 01             	add    $0x1,%edx
  8009be:	eb ea                	jmp    8009aa <memcmp+0x10>
			return (int) *s1 - (int) *s2;
  8009c0:	0f b6 c1             	movzbl %cl,%eax
  8009c3:	0f b6 db             	movzbl %bl,%ebx
  8009c6:	29 d8                	sub    %ebx,%eax
  8009c8:	eb 05                	jmp    8009cf <memcmp+0x35>
	}

	return 0;
  8009ca:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8009cf:	5b                   	pop    %ebx
  8009d0:	5e                   	pop    %esi
  8009d1:	5d                   	pop    %ebp
  8009d2:	c3                   	ret    

008009d3 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  8009d3:	55                   	push   %ebp
  8009d4:	89 e5                	mov    %esp,%ebp
  8009d6:	8b 45 08             	mov    0x8(%ebp),%eax
  8009d9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
  8009dc:	89 c2                	mov    %eax,%edx
  8009de:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  8009e1:	39 d0                	cmp    %edx,%eax
  8009e3:	73 09                	jae    8009ee <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
  8009e5:	38 08                	cmp    %cl,(%eax)
  8009e7:	74 05                	je     8009ee <memfind+0x1b>
	for (; s < ends; s++)
  8009e9:	83 c0 01             	add    $0x1,%eax
  8009ec:	eb f3                	jmp    8009e1 <memfind+0xe>
			break;
	return (void *) s;
}
  8009ee:	5d                   	pop    %ebp
  8009ef:	c3                   	ret    

008009f0 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  8009f0:	55                   	push   %ebp
  8009f1:	89 e5                	mov    %esp,%ebp
  8009f3:	57                   	push   %edi
  8009f4:	56                   	push   %esi
  8009f5:	53                   	push   %ebx
  8009f6:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8009f9:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  8009fc:	eb 03                	jmp    800a01 <strtol+0x11>
		s++;
  8009fe:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
  800a01:	0f b6 01             	movzbl (%ecx),%eax
  800a04:	3c 20                	cmp    $0x20,%al
  800a06:	74 f6                	je     8009fe <strtol+0xe>
  800a08:	3c 09                	cmp    $0x9,%al
  800a0a:	74 f2                	je     8009fe <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
  800a0c:	3c 2b                	cmp    $0x2b,%al
  800a0e:	74 2e                	je     800a3e <strtol+0x4e>
	int neg = 0;
  800a10:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
  800a15:	3c 2d                	cmp    $0x2d,%al
  800a17:	74 2f                	je     800a48 <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800a19:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800a1f:	75 05                	jne    800a26 <strtol+0x36>
  800a21:	80 39 30             	cmpb   $0x30,(%ecx)
  800a24:	74 2c                	je     800a52 <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a26:	85 db                	test   %ebx,%ebx
  800a28:	75 0a                	jne    800a34 <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800a2a:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
  800a2f:	80 39 30             	cmpb   $0x30,(%ecx)
  800a32:	74 28                	je     800a5c <strtol+0x6c>
		base = 10;
  800a34:	b8 00 00 00 00       	mov    $0x0,%eax
  800a39:	89 5d 10             	mov    %ebx,0x10(%ebp)
  800a3c:	eb 50                	jmp    800a8e <strtol+0x9e>
		s++;
  800a3e:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
  800a41:	bf 00 00 00 00       	mov    $0x0,%edi
  800a46:	eb d1                	jmp    800a19 <strtol+0x29>
		s++, neg = 1;
  800a48:	83 c1 01             	add    $0x1,%ecx
  800a4b:	bf 01 00 00 00       	mov    $0x1,%edi
  800a50:	eb c7                	jmp    800a19 <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800a52:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800a56:	74 0e                	je     800a66 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
  800a58:	85 db                	test   %ebx,%ebx
  800a5a:	75 d8                	jne    800a34 <strtol+0x44>
		s++, base = 8;
  800a5c:	83 c1 01             	add    $0x1,%ecx
  800a5f:	bb 08 00 00 00       	mov    $0x8,%ebx
  800a64:	eb ce                	jmp    800a34 <strtol+0x44>
		s += 2, base = 16;
  800a66:	83 c1 02             	add    $0x2,%ecx
  800a69:	bb 10 00 00 00       	mov    $0x10,%ebx
  800a6e:	eb c4                	jmp    800a34 <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
  800a70:	8d 72 9f             	lea    -0x61(%edx),%esi
  800a73:	89 f3                	mov    %esi,%ebx
  800a75:	80 fb 19             	cmp    $0x19,%bl
  800a78:	77 29                	ja     800aa3 <strtol+0xb3>
			dig = *s - 'a' + 10;
  800a7a:	0f be d2             	movsbl %dl,%edx
  800a7d:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
  800a80:	3b 55 10             	cmp    0x10(%ebp),%edx
  800a83:	7d 30                	jge    800ab5 <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
  800a85:	83 c1 01             	add    $0x1,%ecx
  800a88:	0f af 45 10          	imul   0x10(%ebp),%eax
  800a8c:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
  800a8e:	0f b6 11             	movzbl (%ecx),%edx
  800a91:	8d 72 d0             	lea    -0x30(%edx),%esi
  800a94:	89 f3                	mov    %esi,%ebx
  800a96:	80 fb 09             	cmp    $0x9,%bl
  800a99:	77 d5                	ja     800a70 <strtol+0x80>
			dig = *s - '0';
  800a9b:	0f be d2             	movsbl %dl,%edx
  800a9e:	83 ea 30             	sub    $0x30,%edx
  800aa1:	eb dd                	jmp    800a80 <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
  800aa3:	8d 72 bf             	lea    -0x41(%edx),%esi
  800aa6:	89 f3                	mov    %esi,%ebx
  800aa8:	80 fb 19             	cmp    $0x19,%bl
  800aab:	77 08                	ja     800ab5 <strtol+0xc5>
			dig = *s - 'A' + 10;
  800aad:	0f be d2             	movsbl %dl,%edx
  800ab0:	83 ea 37             	sub    $0x37,%edx
  800ab3:	eb cb                	jmp    800a80 <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
  800ab5:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800ab9:	74 05                	je     800ac0 <strtol+0xd0>
		*endptr = (char *) s;
  800abb:	8b 75 0c             	mov    0xc(%ebp),%esi
  800abe:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
  800ac0:	89 c2                	mov    %eax,%edx
  800ac2:	f7 da                	neg    %edx
  800ac4:	85 ff                	test   %edi,%edi
  800ac6:	0f 45 c2             	cmovne %edx,%eax
}
  800ac9:	5b                   	pop    %ebx
  800aca:	5e                   	pop    %esi
  800acb:	5f                   	pop    %edi
  800acc:	5d                   	pop    %ebp
  800acd:	c3                   	ret    
  800ace:	66 90                	xchg   %ax,%ax

00800ad0 <__udivdi3>:
  800ad0:	55                   	push   %ebp
  800ad1:	57                   	push   %edi
  800ad2:	56                   	push   %esi
  800ad3:	53                   	push   %ebx
  800ad4:	83 ec 1c             	sub    $0x1c,%esp
  800ad7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  800adb:	8b 6c 24 30          	mov    0x30(%esp),%ebp
  800adf:	8b 74 24 34          	mov    0x34(%esp),%esi
  800ae3:	8b 5c 24 38          	mov    0x38(%esp),%ebx
  800ae7:	85 d2                	test   %edx,%edx
  800ae9:	75 35                	jne    800b20 <__udivdi3+0x50>
  800aeb:	39 f3                	cmp    %esi,%ebx
  800aed:	0f 87 bd 00 00 00    	ja     800bb0 <__udivdi3+0xe0>
  800af3:	85 db                	test   %ebx,%ebx
  800af5:	89 d9                	mov    %ebx,%ecx
  800af7:	75 0b                	jne    800b04 <__udivdi3+0x34>
  800af9:	b8 01 00 00 00       	mov    $0x1,%eax
  800afe:	31 d2                	xor    %edx,%edx
  800b00:	f7 f3                	div    %ebx
  800b02:	89 c1                	mov    %eax,%ecx
  800b04:	31 d2                	xor    %edx,%edx
  800b06:	89 f0                	mov    %esi,%eax
  800b08:	f7 f1                	div    %ecx
  800b0a:	89 c6                	mov    %eax,%esi
  800b0c:	89 e8                	mov    %ebp,%eax
  800b0e:	89 f7                	mov    %esi,%edi
  800b10:	f7 f1                	div    %ecx
  800b12:	89 fa                	mov    %edi,%edx
  800b14:	83 c4 1c             	add    $0x1c,%esp
  800b17:	5b                   	pop    %ebx
  800b18:	5e                   	pop    %esi
  800b19:	5f                   	pop    %edi
  800b1a:	5d                   	pop    %ebp
  800b1b:	c3                   	ret    
  800b1c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800b20:	39 f2                	cmp    %esi,%edx
  800b22:	77 7c                	ja     800ba0 <__udivdi3+0xd0>
  800b24:	0f bd fa             	bsr    %edx,%edi
  800b27:	83 f7 1f             	xor    $0x1f,%edi
  800b2a:	0f 84 98 00 00 00    	je     800bc8 <__udivdi3+0xf8>
  800b30:	89 f9                	mov    %edi,%ecx
  800b32:	b8 20 00 00 00       	mov    $0x20,%eax
  800b37:	29 f8                	sub    %edi,%eax
  800b39:	d3 e2                	shl    %cl,%edx
  800b3b:	89 54 24 08          	mov    %edx,0x8(%esp)
  800b3f:	89 c1                	mov    %eax,%ecx
  800b41:	89 da                	mov    %ebx,%edx
  800b43:	d3 ea                	shr    %cl,%edx
  800b45:	8b 4c 24 08          	mov    0x8(%esp),%ecx
  800b49:	09 d1                	or     %edx,%ecx
  800b4b:	89 f2                	mov    %esi,%edx
  800b4d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800b51:	89 f9                	mov    %edi,%ecx
  800b53:	d3 e3                	shl    %cl,%ebx
  800b55:	89 c1                	mov    %eax,%ecx
  800b57:	d3 ea                	shr    %cl,%edx
  800b59:	89 f9                	mov    %edi,%ecx
  800b5b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  800b5f:	d3 e6                	shl    %cl,%esi
  800b61:	89 eb                	mov    %ebp,%ebx
  800b63:	89 c1                	mov    %eax,%ecx
  800b65:	d3 eb                	shr    %cl,%ebx
  800b67:	09 de                	or     %ebx,%esi
  800b69:	89 f0                	mov    %esi,%eax
  800b6b:	f7 74 24 08          	divl   0x8(%esp)
  800b6f:	89 d6                	mov    %edx,%esi
  800b71:	89 c3                	mov    %eax,%ebx
  800b73:	f7 64 24 0c          	mull   0xc(%esp)
  800b77:	39 d6                	cmp    %edx,%esi
  800b79:	72 0c                	jb     800b87 <__udivdi3+0xb7>
  800b7b:	89 f9                	mov    %edi,%ecx
  800b7d:	d3 e5                	shl    %cl,%ebp
  800b7f:	39 c5                	cmp    %eax,%ebp
  800b81:	73 5d                	jae    800be0 <__udivdi3+0x110>
  800b83:	39 d6                	cmp    %edx,%esi
  800b85:	75 59                	jne    800be0 <__udivdi3+0x110>
  800b87:	8d 43 ff             	lea    -0x1(%ebx),%eax
  800b8a:	31 ff                	xor    %edi,%edi
  800b8c:	89 fa                	mov    %edi,%edx
  800b8e:	83 c4 1c             	add    $0x1c,%esp
  800b91:	5b                   	pop    %ebx
  800b92:	5e                   	pop    %esi
  800b93:	5f                   	pop    %edi
  800b94:	5d                   	pop    %ebp
  800b95:	c3                   	ret    
  800b96:	8d 76 00             	lea    0x0(%esi),%esi
  800b99:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
  800ba0:	31 ff                	xor    %edi,%edi
  800ba2:	31 c0                	xor    %eax,%eax
  800ba4:	89 fa                	mov    %edi,%edx
  800ba6:	83 c4 1c             	add    $0x1c,%esp
  800ba9:	5b                   	pop    %ebx
  800baa:	5e                   	pop    %esi
  800bab:	5f                   	pop    %edi
  800bac:	5d                   	pop    %ebp
  800bad:	c3                   	ret    
  800bae:	66 90                	xchg   %ax,%ax
  800bb0:	31 ff                	xor    %edi,%edi
  800bb2:	89 e8                	mov    %ebp,%eax
  800bb4:	89 f2                	mov    %esi,%edx
  800bb6:	f7 f3                	div    %ebx
  800bb8:	89 fa                	mov    %edi,%edx
  800bba:	83 c4 1c             	add    $0x1c,%esp
  800bbd:	5b                   	pop    %ebx
  800bbe:	5e                   	pop    %esi
  800bbf:	5f                   	pop    %edi
  800bc0:	5d                   	pop    %ebp
  800bc1:	c3                   	ret    
  800bc2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800bc8:	39 f2                	cmp    %esi,%edx
  800bca:	72 06                	jb     800bd2 <__udivdi3+0x102>
  800bcc:	31 c0                	xor    %eax,%eax
  800bce:	39 eb                	cmp    %ebp,%ebx
  800bd0:	77 d2                	ja     800ba4 <__udivdi3+0xd4>
  800bd2:	b8 01 00 00 00       	mov    $0x1,%eax
  800bd7:	eb cb                	jmp    800ba4 <__udivdi3+0xd4>
  800bd9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800be0:	89 d8                	mov    %ebx,%eax
  800be2:	31 ff                	xor    %edi,%edi
  800be4:	eb be                	jmp    800ba4 <__udivdi3+0xd4>
  800be6:	66 90                	xchg   %ax,%ax
  800be8:	66 90                	xchg   %ax,%ax
  800bea:	66 90                	xchg   %ax,%ax
  800bec:	66 90                	xchg   %ax,%ax
  800bee:	66 90                	xchg   %ax,%ax

00800bf0 <__umoddi3>:
  800bf0:	55                   	push   %ebp
  800bf1:	57                   	push   %edi
  800bf2:	56                   	push   %esi
  800bf3:	53                   	push   %ebx
  800bf4:	83 ec 1c             	sub    $0x1c,%esp
  800bf7:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
  800bfb:	8b 74 24 30          	mov    0x30(%esp),%esi
  800bff:	8b 5c 24 34          	mov    0x34(%esp),%ebx
  800c03:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800c07:	85 ed                	test   %ebp,%ebp
  800c09:	89 f0                	mov    %esi,%eax
  800c0b:	89 da                	mov    %ebx,%edx
  800c0d:	75 19                	jne    800c28 <__umoddi3+0x38>
  800c0f:	39 df                	cmp    %ebx,%edi
  800c11:	0f 86 b1 00 00 00    	jbe    800cc8 <__umoddi3+0xd8>
  800c17:	f7 f7                	div    %edi
  800c19:	89 d0                	mov    %edx,%eax
  800c1b:	31 d2                	xor    %edx,%edx
  800c1d:	83 c4 1c             	add    $0x1c,%esp
  800c20:	5b                   	pop    %ebx
  800c21:	5e                   	pop    %esi
  800c22:	5f                   	pop    %edi
  800c23:	5d                   	pop    %ebp
  800c24:	c3                   	ret    
  800c25:	8d 76 00             	lea    0x0(%esi),%esi
  800c28:	39 dd                	cmp    %ebx,%ebp
  800c2a:	77 f1                	ja     800c1d <__umoddi3+0x2d>
  800c2c:	0f bd cd             	bsr    %ebp,%ecx
  800c2f:	83 f1 1f             	xor    $0x1f,%ecx
  800c32:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  800c36:	0f 84 b4 00 00 00    	je     800cf0 <__umoddi3+0x100>
  800c3c:	b8 20 00 00 00       	mov    $0x20,%eax
  800c41:	89 c2                	mov    %eax,%edx
  800c43:	8b 44 24 04          	mov    0x4(%esp),%eax
  800c47:	29 c2                	sub    %eax,%edx
  800c49:	89 c1                	mov    %eax,%ecx
  800c4b:	89 f8                	mov    %edi,%eax
  800c4d:	d3 e5                	shl    %cl,%ebp
  800c4f:	89 d1                	mov    %edx,%ecx
  800c51:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800c55:	d3 e8                	shr    %cl,%eax
  800c57:	09 c5                	or     %eax,%ebp
  800c59:	8b 44 24 04          	mov    0x4(%esp),%eax
  800c5d:	89 c1                	mov    %eax,%ecx
  800c5f:	d3 e7                	shl    %cl,%edi
  800c61:	89 d1                	mov    %edx,%ecx
  800c63:	89 7c 24 08          	mov    %edi,0x8(%esp)
  800c67:	89 df                	mov    %ebx,%edi
  800c69:	d3 ef                	shr    %cl,%edi
  800c6b:	89 c1                	mov    %eax,%ecx
  800c6d:	89 f0                	mov    %esi,%eax
  800c6f:	d3 e3                	shl    %cl,%ebx
  800c71:	89 d1                	mov    %edx,%ecx
  800c73:	89 fa                	mov    %edi,%edx
  800c75:	d3 e8                	shr    %cl,%eax
  800c77:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  800c7c:	09 d8                	or     %ebx,%eax
  800c7e:	f7 f5                	div    %ebp
  800c80:	d3 e6                	shl    %cl,%esi
  800c82:	89 d1                	mov    %edx,%ecx
  800c84:	f7 64 24 08          	mull   0x8(%esp)
  800c88:	39 d1                	cmp    %edx,%ecx
  800c8a:	89 c3                	mov    %eax,%ebx
  800c8c:	89 d7                	mov    %edx,%edi
  800c8e:	72 06                	jb     800c96 <__umoddi3+0xa6>
  800c90:	75 0e                	jne    800ca0 <__umoddi3+0xb0>
  800c92:	39 c6                	cmp    %eax,%esi
  800c94:	73 0a                	jae    800ca0 <__umoddi3+0xb0>
  800c96:	2b 44 24 08          	sub    0x8(%esp),%eax
  800c9a:	19 ea                	sbb    %ebp,%edx
  800c9c:	89 d7                	mov    %edx,%edi
  800c9e:	89 c3                	mov    %eax,%ebx
  800ca0:	89 ca                	mov    %ecx,%edx
  800ca2:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
  800ca7:	29 de                	sub    %ebx,%esi
  800ca9:	19 fa                	sbb    %edi,%edx
  800cab:	8b 5c 24 04          	mov    0x4(%esp),%ebx
  800caf:	89 d0                	mov    %edx,%eax
  800cb1:	d3 e0                	shl    %cl,%eax
  800cb3:	89 d9                	mov    %ebx,%ecx
  800cb5:	d3 ee                	shr    %cl,%esi
  800cb7:	d3 ea                	shr    %cl,%edx
  800cb9:	09 f0                	or     %esi,%eax
  800cbb:	83 c4 1c             	add    $0x1c,%esp
  800cbe:	5b                   	pop    %ebx
  800cbf:	5e                   	pop    %esi
  800cc0:	5f                   	pop    %edi
  800cc1:	5d                   	pop    %ebp
  800cc2:	c3                   	ret    
  800cc3:	90                   	nop
  800cc4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800cc8:	85 ff                	test   %edi,%edi
  800cca:	89 f9                	mov    %edi,%ecx
  800ccc:	75 0b                	jne    800cd9 <__umoddi3+0xe9>
  800cce:	b8 01 00 00 00       	mov    $0x1,%eax
  800cd3:	31 d2                	xor    %edx,%edx
  800cd5:	f7 f7                	div    %edi
  800cd7:	89 c1                	mov    %eax,%ecx
  800cd9:	89 d8                	mov    %ebx,%eax
  800cdb:	31 d2                	xor    %edx,%edx
  800cdd:	f7 f1                	div    %ecx
  800cdf:	89 f0                	mov    %esi,%eax
  800ce1:	f7 f1                	div    %ecx
  800ce3:	e9 31 ff ff ff       	jmp    800c19 <__umoddi3+0x29>
  800ce8:	90                   	nop
  800ce9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800cf0:	39 dd                	cmp    %ebx,%ebp
  800cf2:	72 08                	jb     800cfc <__umoddi3+0x10c>
  800cf4:	39 f7                	cmp    %esi,%edi
  800cf6:	0f 87 21 ff ff ff    	ja     800c1d <__umoddi3+0x2d>
  800cfc:	89 da                	mov    %ebx,%edx
  800cfe:	89 f0                	mov    %esi,%eax
  800d00:	29 f8                	sub    %edi,%eax
  800d02:	19 ea                	sbb    %ebp,%edx
  800d04:	e9 14 ff ff ff       	jmp    800c1d <__umoddi3+0x2d>
