
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
  80002c:	e8 6b 00 00 00       	call   80009c <libmain>
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
  800036:	53                   	push   %ebx
  800037:	83 ec 04             	sub    $0x4,%esp
	uint32_t pid = fork();
  80003a:	e8 19 02 00 00       	call   800258 <fork>
  80003f:	89 c3                	mov    %eax,%ebx
	cprintf("pid:%d\n", pid);
  800041:	83 ec 08             	sub    $0x8,%esp
  800044:	50                   	push   %eax
  800045:	68 1c 0e 80 00       	push   $0x800e1c
  80004a:	e8 0e 01 00 00       	call   80015d <cprintf>
	if (pid == 0) {
  80004f:	83 c4 10             	add    $0x10,%esp
  800052:	85 db                	test   %ebx,%ebx
  800054:	74 28                	je     80007e <umain+0x4b>
		cprintf("Here, I'm child process.\n");
		sleep(1);
	} else {
		cprintf("I'm father.\n");
  800056:	83 ec 0c             	sub    $0xc,%esp
  800059:	68 3e 0e 80 00       	push   $0x800e3e
  80005e:	e8 fa 00 00 00       	call   80015d <cprintf>
		pid = wait();
  800063:	e8 10 02 00 00       	call   800278 <wait>
		cprintf("wait pid %d.\n", pid);
  800068:	83 c4 08             	add    $0x8,%esp
  80006b:	50                   	push   %eax
  80006c:	68 4b 0e 80 00       	push   $0x800e4b
  800071:	e8 e7 00 00 00       	call   80015d <cprintf>
  800076:	83 c4 10             	add    $0x10,%esp
	}
		
}
  800079:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  80007c:	c9                   	leave  
  80007d:	c3                   	ret    
		cprintf("Here, I'm child process.\n");
  80007e:	83 ec 0c             	sub    $0xc,%esp
  800081:	68 24 0e 80 00       	push   $0x800e24
  800086:	e8 d2 00 00 00       	call   80015d <cprintf>
		sleep(1);
  80008b:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  800092:	e8 ce 01 00 00       	call   800265 <sleep>
  800097:	83 c4 10             	add    $0x10,%esp
  80009a:	eb dd                	jmp    800079 <umain+0x46>

0080009c <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  80009c:	55                   	push   %ebp
  80009d:	89 e5                	mov    %esp,%ebp
  80009f:	83 ec 08             	sub    $0x8,%esp
  8000a2:	8b 45 08             	mov    0x8(%ebp),%eax
  8000a5:	8b 55 0c             	mov    0xc(%ebp),%edx
	// LAB 3: Your code here.
	// envid_t envid = sys_getenvid();
	// thisenv = envs + ENVX(envid);

	// save the name of the program so that panic() can use it
	if (argc > 0)
  8000a8:	85 c0                	test   %eax,%eax
  8000aa:	7e 08                	jle    8000b4 <libmain+0x18>
		binaryname = argv[0];
  8000ac:	8b 0a                	mov    (%edx),%ecx
  8000ae:	89 0d 00 20 80 00    	mov    %ecx,0x802000
	// cprintf("argc: %d\n", argc);
	// call user main routine
	umain(argc, argv);
  8000b4:	83 ec 08             	sub    $0x8,%esp
  8000b7:	52                   	push   %edx
  8000b8:	50                   	push   %eax
  8000b9:	e8 75 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  8000be:	e8 88 01 00 00       	call   80024b <exit>
}
  8000c3:	83 c4 10             	add    $0x10,%esp
  8000c6:	c9                   	leave  
  8000c7:	c3                   	ret    

008000c8 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8000c8:	55                   	push   %ebp
  8000c9:	89 e5                	mov    %esp,%ebp
  8000cb:	53                   	push   %ebx
  8000cc:	83 ec 04             	sub    $0x4,%esp
  8000cf:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8000d2:	8b 13                	mov    (%ebx),%edx
  8000d4:	8d 42 01             	lea    0x1(%edx),%eax
  8000d7:	89 03                	mov    %eax,(%ebx)
  8000d9:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8000dc:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8000e0:	3d ff 00 00 00       	cmp    $0xff,%eax
  8000e5:	74 09                	je     8000f0 <putch+0x28>
		sys_cputs(b->buf, b->idx);
		b->idx = 0;
	}
	b->cnt++;
  8000e7:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8000eb:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8000ee:	c9                   	leave  
  8000ef:	c3                   	ret    
		sys_cputs(b->buf, b->idx);
  8000f0:	83 ec 08             	sub    $0x8,%esp
  8000f3:	68 ff 00 00 00       	push   $0xff
  8000f8:	8d 43 08             	lea    0x8(%ebx),%eax
  8000fb:	50                   	push   %eax
  8000fc:	e8 70 00 00 00       	call   800171 <sys_cputs>
		b->idx = 0;
  800101:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  800107:	83 c4 10             	add    $0x10,%esp
  80010a:	eb db                	jmp    8000e7 <putch+0x1f>

0080010c <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  80010c:	55                   	push   %ebp
  80010d:	89 e5                	mov    %esp,%ebp
  80010f:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  800115:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  80011c:	00 00 00 
	b.cnt = 0;
  80011f:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800126:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  800129:	ff 75 0c             	pushl  0xc(%ebp)
  80012c:	ff 75 08             	pushl  0x8(%ebp)
  80012f:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800135:	50                   	push   %eax
  800136:	68 c8 00 80 00       	push   $0x8000c8
  80013b:	e8 3e 02 00 00       	call   80037e <vprintfmt>
	sys_cputs(b.buf, b.idx);
  800140:	83 c4 08             	add    $0x8,%esp
  800143:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  800149:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  80014f:	50                   	push   %eax
  800150:	e8 1c 00 00 00       	call   800171 <sys_cputs>

	return b.cnt;
}
  800155:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  80015b:	c9                   	leave  
  80015c:	c3                   	ret    

0080015d <cprintf>:

int
cprintf(const char *fmt, ...)
{
  80015d:	55                   	push   %ebp
  80015e:	89 e5                	mov    %esp,%ebp
  800160:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800163:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800166:	50                   	push   %eax
  800167:	ff 75 08             	pushl  0x8(%ebp)
  80016a:	e8 9d ff ff ff       	call   80010c <vcprintf>
	va_end(ap);

	return cnt;
}
  80016f:	c9                   	leave  
  800170:	c3                   	ret    

00800171 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800171:	55                   	push   %ebp
  800172:	89 e5                	mov    %esp,%ebp
  800174:	57                   	push   %edi
  800175:	56                   	push   %esi
  800176:	53                   	push   %ebx
	asm volatile("int %1\n"
  800177:	b8 00 00 00 00       	mov    $0x0,%eax
  80017c:	8b 55 08             	mov    0x8(%ebp),%edx
  80017f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800182:	89 c3                	mov    %eax,%ebx
  800184:	89 c7                	mov    %eax,%edi
  800186:	89 c6                	mov    %eax,%esi
  800188:	cd 40                	int    $0x40
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  80018a:	5b                   	pop    %ebx
  80018b:	5e                   	pop    %esi
  80018c:	5f                   	pop    %edi
  80018d:	5d                   	pop    %ebp
  80018e:	c3                   	ret    

0080018f <sys_cgetc>:

int
sys_cgetc(void)
{
  80018f:	55                   	push   %ebp
  800190:	89 e5                	mov    %esp,%ebp
  800192:	57                   	push   %edi
  800193:	56                   	push   %esi
  800194:	53                   	push   %ebx
	asm volatile("int %1\n"
  800195:	ba 00 00 00 00       	mov    $0x0,%edx
  80019a:	b8 01 00 00 00       	mov    $0x1,%eax
  80019f:	89 d1                	mov    %edx,%ecx
  8001a1:	89 d3                	mov    %edx,%ebx
  8001a3:	89 d7                	mov    %edx,%edi
  8001a5:	89 d6                	mov    %edx,%esi
  8001a7:	cd 40                	int    $0x40
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  8001a9:	5b                   	pop    %ebx
  8001aa:	5e                   	pop    %esi
  8001ab:	5f                   	pop    %edi
  8001ac:	5d                   	pop    %ebp
  8001ad:	c3                   	ret    

008001ae <sys_exit>:

void
sys_exit(void)
{
  8001ae:	55                   	push   %ebp
  8001af:	89 e5                	mov    %esp,%ebp
  8001b1:	57                   	push   %edi
  8001b2:	56                   	push   %esi
  8001b3:	53                   	push   %ebx
	asm volatile("int %1\n"
  8001b4:	ba 00 00 00 00       	mov    $0x0,%edx
  8001b9:	b8 02 00 00 00       	mov    $0x2,%eax
  8001be:	89 d1                	mov    %edx,%ecx
  8001c0:	89 d3                	mov    %edx,%ebx
  8001c2:	89 d7                	mov    %edx,%edi
  8001c4:	89 d6                	mov    %edx,%esi
  8001c6:	cd 40                	int    $0x40
	syscall(SYS_exit, 0, 0, 0, 0, 0, 0);
}
  8001c8:	5b                   	pop    %ebx
  8001c9:	5e                   	pop    %esi
  8001ca:	5f                   	pop    %edi
  8001cb:	5d                   	pop    %ebp
  8001cc:	c3                   	ret    

008001cd <sys_fork>:

int
sys_fork(void)
{
  8001cd:	55                   	push   %ebp
  8001ce:	89 e5                	mov    %esp,%ebp
  8001d0:	57                   	push   %edi
  8001d1:	56                   	push   %esi
  8001d2:	53                   	push   %ebx
	asm volatile("int %1\n"
  8001d3:	ba 00 00 00 00       	mov    $0x0,%edx
  8001d8:	b8 03 00 00 00       	mov    $0x3,%eax
  8001dd:	89 d1                	mov    %edx,%ecx
  8001df:	89 d3                	mov    %edx,%ebx
  8001e1:	89 d7                	mov    %edx,%edi
  8001e3:	89 d6                	mov    %edx,%esi
  8001e5:	cd 40                	int    $0x40
	return syscall(SYS_fork, 0, 0, 0, 0, 0, 0); // TODO check the number of arguments
}
  8001e7:	5b                   	pop    %ebx
  8001e8:	5e                   	pop    %esi
  8001e9:	5f                   	pop    %edi
  8001ea:	5d                   	pop    %ebp
  8001eb:	c3                   	ret    

008001ec <sys_sleep>:

void
sys_sleep(uint32_t n)
{
  8001ec:	55                   	push   %ebp
  8001ed:	89 e5                	mov    %esp,%ebp
  8001ef:	57                   	push   %edi
  8001f0:	56                   	push   %esi
  8001f1:	53                   	push   %ebx
	asm volatile("int %1\n"
  8001f2:	b9 00 00 00 00       	mov    $0x0,%ecx
  8001f7:	8b 55 08             	mov    0x8(%ebp),%edx
  8001fa:	b8 04 00 00 00       	mov    $0x4,%eax
  8001ff:	89 cb                	mov    %ecx,%ebx
  800201:	89 cf                	mov    %ecx,%edi
  800203:	89 ce                	mov    %ecx,%esi
  800205:	cd 40                	int    $0x40
	syscall(SYS_sleep, 0, n, 0, 0, 0, 0);
}
  800207:	5b                   	pop    %ebx
  800208:	5e                   	pop    %esi
  800209:	5f                   	pop    %edi
  80020a:	5d                   	pop    %ebp
  80020b:	c3                   	ret    

0080020c <sys_wait>:

int
sys_wait(void)
{
  80020c:	55                   	push   %ebp
  80020d:	89 e5                	mov    %esp,%ebp
  80020f:	57                   	push   %edi
  800210:	56                   	push   %esi
  800211:	53                   	push   %ebx
	asm volatile("int %1\n"
  800212:	ba 00 00 00 00       	mov    $0x0,%edx
  800217:	b8 05 00 00 00       	mov    $0x5,%eax
  80021c:	89 d1                	mov    %edx,%ecx
  80021e:	89 d3                	mov    %edx,%ebx
  800220:	89 d7                	mov    %edx,%edi
  800222:	89 d6                	mov    %edx,%esi
  800224:	cd 40                	int    $0x40
	return syscall(SYS_wait, 0, 0, 0, 0, 0, 0);
}
  800226:	5b                   	pop    %ebx
  800227:	5e                   	pop    %esi
  800228:	5f                   	pop    %edi
  800229:	5d                   	pop    %ebp
  80022a:	c3                   	ret    

0080022b <sys_kill>:

int
sys_kill(uint32_t pid)
{
  80022b:	55                   	push   %ebp
  80022c:	89 e5                	mov    %esp,%ebp
  80022e:	57                   	push   %edi
  80022f:	56                   	push   %esi
  800230:	53                   	push   %ebx
	asm volatile("int %1\n"
  800231:	b9 00 00 00 00       	mov    $0x0,%ecx
  800236:	8b 55 08             	mov    0x8(%ebp),%edx
  800239:	b8 06 00 00 00       	mov    $0x6,%eax
  80023e:	89 cb                	mov    %ecx,%ebx
  800240:	89 cf                	mov    %ecx,%edi
  800242:	89 ce                	mov    %ecx,%esi
  800244:	cd 40                	int    $0x40
	return syscall(SYS_kill, 0, pid, 0, 0, 0, 0);
  800246:	5b                   	pop    %ebx
  800247:	5e                   	pop    %esi
  800248:	5f                   	pop    %edi
  800249:	5d                   	pop    %ebp
  80024a:	c3                   	ret    

0080024b <exit>:
#include <inc/lib.h>

void
exit(void)
{
  80024b:	55                   	push   %ebp
  80024c:	89 e5                	mov    %esp,%ebp
  80024e:	83 ec 08             	sub    $0x8,%esp
	sys_exit();
  800251:	e8 58 ff ff ff       	call   8001ae <sys_exit>
}
  800256:	c9                   	leave  
  800257:	c3                   	ret    

00800258 <fork>:

int
fork(void)
{
  800258:	55                   	push   %ebp
  800259:	89 e5                	mov    %esp,%ebp
  80025b:	83 ec 08             	sub    $0x8,%esp
	return sys_fork();
  80025e:	e8 6a ff ff ff       	call   8001cd <sys_fork>
}
  800263:	c9                   	leave  
  800264:	c3                   	ret    

00800265 <sleep>:

void
sleep(uint32_t n)
{
  800265:	55                   	push   %ebp
  800266:	89 e5                	mov    %esp,%ebp
  800268:	83 ec 14             	sub    $0x14,%esp
	sys_sleep(n);
  80026b:	ff 75 08             	pushl  0x8(%ebp)
  80026e:	e8 79 ff ff ff       	call   8001ec <sys_sleep>
}
  800273:	83 c4 10             	add    $0x10,%esp
  800276:	c9                   	leave  
  800277:	c3                   	ret    

00800278 <wait>:

int
wait(void)
{
  800278:	55                   	push   %ebp
  800279:	89 e5                	mov    %esp,%ebp
  80027b:	83 ec 08             	sub    $0x8,%esp
	return sys_wait();
  80027e:	e8 89 ff ff ff       	call   80020c <sys_wait>
}
  800283:	c9                   	leave  
  800284:	c3                   	ret    

00800285 <kill>:

int
kill(uint32_t pid)
{
  800285:	55                   	push   %ebp
  800286:	89 e5                	mov    %esp,%ebp
  800288:	83 ec 14             	sub    $0x14,%esp
	return sys_kill(pid);
  80028b:	ff 75 08             	pushl  0x8(%ebp)
  80028e:	e8 98 ff ff ff       	call   80022b <sys_kill>
  800293:	c9                   	leave  
  800294:	c3                   	ret    

00800295 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800295:	55                   	push   %ebp
  800296:	89 e5                	mov    %esp,%ebp
  800298:	57                   	push   %edi
  800299:	56                   	push   %esi
  80029a:	53                   	push   %ebx
  80029b:	83 ec 1c             	sub    $0x1c,%esp
  80029e:	89 c7                	mov    %eax,%edi
  8002a0:	89 d6                	mov    %edx,%esi
  8002a2:	8b 45 08             	mov    0x8(%ebp),%eax
  8002a5:	8b 55 0c             	mov    0xc(%ebp),%edx
  8002a8:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8002ab:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  8002ae:	8b 4d 10             	mov    0x10(%ebp),%ecx
  8002b1:	bb 00 00 00 00       	mov    $0x0,%ebx
  8002b6:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  8002b9:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  8002bc:	39 d3                	cmp    %edx,%ebx
  8002be:	72 05                	jb     8002c5 <printnum+0x30>
  8002c0:	39 45 10             	cmp    %eax,0x10(%ebp)
  8002c3:	77 7a                	ja     80033f <printnum+0xaa>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  8002c5:	83 ec 0c             	sub    $0xc,%esp
  8002c8:	ff 75 18             	pushl  0x18(%ebp)
  8002cb:	8b 45 14             	mov    0x14(%ebp),%eax
  8002ce:	8d 58 ff             	lea    -0x1(%eax),%ebx
  8002d1:	53                   	push   %ebx
  8002d2:	ff 75 10             	pushl  0x10(%ebp)
  8002d5:	83 ec 08             	sub    $0x8,%esp
  8002d8:	ff 75 e4             	pushl  -0x1c(%ebp)
  8002db:	ff 75 e0             	pushl  -0x20(%ebp)
  8002de:	ff 75 dc             	pushl  -0x24(%ebp)
  8002e1:	ff 75 d8             	pushl  -0x28(%ebp)
  8002e4:	e8 f7 08 00 00       	call   800be0 <__udivdi3>
  8002e9:	83 c4 18             	add    $0x18,%esp
  8002ec:	52                   	push   %edx
  8002ed:	50                   	push   %eax
  8002ee:	89 f2                	mov    %esi,%edx
  8002f0:	89 f8                	mov    %edi,%eax
  8002f2:	e8 9e ff ff ff       	call   800295 <printnum>
  8002f7:	83 c4 20             	add    $0x20,%esp
  8002fa:	eb 13                	jmp    80030f <printnum+0x7a>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8002fc:	83 ec 08             	sub    $0x8,%esp
  8002ff:	56                   	push   %esi
  800300:	ff 75 18             	pushl  0x18(%ebp)
  800303:	ff d7                	call   *%edi
  800305:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
  800308:	83 eb 01             	sub    $0x1,%ebx
  80030b:	85 db                	test   %ebx,%ebx
  80030d:	7f ed                	jg     8002fc <printnum+0x67>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80030f:	83 ec 08             	sub    $0x8,%esp
  800312:	56                   	push   %esi
  800313:	83 ec 04             	sub    $0x4,%esp
  800316:	ff 75 e4             	pushl  -0x1c(%ebp)
  800319:	ff 75 e0             	pushl  -0x20(%ebp)
  80031c:	ff 75 dc             	pushl  -0x24(%ebp)
  80031f:	ff 75 d8             	pushl  -0x28(%ebp)
  800322:	e8 d9 09 00 00       	call   800d00 <__umoddi3>
  800327:	83 c4 14             	add    $0x14,%esp
  80032a:	0f be 80 63 0e 80 00 	movsbl 0x800e63(%eax),%eax
  800331:	50                   	push   %eax
  800332:	ff d7                	call   *%edi
}
  800334:	83 c4 10             	add    $0x10,%esp
  800337:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80033a:	5b                   	pop    %ebx
  80033b:	5e                   	pop    %esi
  80033c:	5f                   	pop    %edi
  80033d:	5d                   	pop    %ebp
  80033e:	c3                   	ret    
  80033f:	8b 5d 14             	mov    0x14(%ebp),%ebx
  800342:	eb c4                	jmp    800308 <printnum+0x73>

00800344 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  800344:	55                   	push   %ebp
  800345:	89 e5                	mov    %esp,%ebp
  800347:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  80034a:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  80034e:	8b 10                	mov    (%eax),%edx
  800350:	3b 50 04             	cmp    0x4(%eax),%edx
  800353:	73 0a                	jae    80035f <sprintputch+0x1b>
		*b->buf++ = ch;
  800355:	8d 4a 01             	lea    0x1(%edx),%ecx
  800358:	89 08                	mov    %ecx,(%eax)
  80035a:	8b 45 08             	mov    0x8(%ebp),%eax
  80035d:	88 02                	mov    %al,(%edx)
}
  80035f:	5d                   	pop    %ebp
  800360:	c3                   	ret    

00800361 <printfmt>:
{
  800361:	55                   	push   %ebp
  800362:	89 e5                	mov    %esp,%ebp
  800364:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
  800367:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  80036a:	50                   	push   %eax
  80036b:	ff 75 10             	pushl  0x10(%ebp)
  80036e:	ff 75 0c             	pushl  0xc(%ebp)
  800371:	ff 75 08             	pushl  0x8(%ebp)
  800374:	e8 05 00 00 00       	call   80037e <vprintfmt>
}
  800379:	83 c4 10             	add    $0x10,%esp
  80037c:	c9                   	leave  
  80037d:	c3                   	ret    

0080037e <vprintfmt>:
{
  80037e:	55                   	push   %ebp
  80037f:	89 e5                	mov    %esp,%ebp
  800381:	57                   	push   %edi
  800382:	56                   	push   %esi
  800383:	53                   	push   %ebx
  800384:	83 ec 2c             	sub    $0x2c,%esp
  800387:	8b 75 08             	mov    0x8(%ebp),%esi
  80038a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80038d:	8b 7d 10             	mov    0x10(%ebp),%edi
  800390:	e9 c1 03 00 00       	jmp    800756 <vprintfmt+0x3d8>
		padc = ' ';
  800395:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
  800399:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
  8003a0:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
		width = -1;
  8003a7:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
  8003ae:	b9 00 00 00 00       	mov    $0x0,%ecx
		switch (ch = *(unsigned char *) fmt++) {
  8003b3:	8d 47 01             	lea    0x1(%edi),%eax
  8003b6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8003b9:	0f b6 17             	movzbl (%edi),%edx
  8003bc:	8d 42 dd             	lea    -0x23(%edx),%eax
  8003bf:	3c 55                	cmp    $0x55,%al
  8003c1:	0f 87 12 04 00 00    	ja     8007d9 <vprintfmt+0x45b>
  8003c7:	0f b6 c0             	movzbl %al,%eax
  8003ca:	ff 24 85 f0 0e 80 00 	jmp    *0x800ef0(,%eax,4)
  8003d1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
  8003d4:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
  8003d8:	eb d9                	jmp    8003b3 <vprintfmt+0x35>
		switch (ch = *(unsigned char *) fmt++) {
  8003da:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '0';
  8003dd:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  8003e1:	eb d0                	jmp    8003b3 <vprintfmt+0x35>
		switch (ch = *(unsigned char *) fmt++) {
  8003e3:	0f b6 d2             	movzbl %dl,%edx
  8003e6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
  8003e9:	b8 00 00 00 00       	mov    $0x0,%eax
  8003ee:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
				precision = precision * 10 + ch - '0';
  8003f1:	8d 04 80             	lea    (%eax,%eax,4),%eax
  8003f4:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
  8003f8:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
  8003fb:	8d 4a d0             	lea    -0x30(%edx),%ecx
  8003fe:	83 f9 09             	cmp    $0x9,%ecx
  800401:	77 55                	ja     800458 <vprintfmt+0xda>
			for (precision = 0; ; ++fmt) {
  800403:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
  800406:	eb e9                	jmp    8003f1 <vprintfmt+0x73>
			precision = va_arg(ap, int);
  800408:	8b 45 14             	mov    0x14(%ebp),%eax
  80040b:	8b 00                	mov    (%eax),%eax
  80040d:	89 45 d0             	mov    %eax,-0x30(%ebp)
  800410:	8b 45 14             	mov    0x14(%ebp),%eax
  800413:	8d 40 04             	lea    0x4(%eax),%eax
  800416:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
  800419:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
  80041c:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800420:	79 91                	jns    8003b3 <vprintfmt+0x35>
				width = precision, precision = -1;
  800422:	8b 45 d0             	mov    -0x30(%ebp),%eax
  800425:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800428:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  80042f:	eb 82                	jmp    8003b3 <vprintfmt+0x35>
  800431:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800434:	85 c0                	test   %eax,%eax
  800436:	ba 00 00 00 00       	mov    $0x0,%edx
  80043b:	0f 49 d0             	cmovns %eax,%edx
  80043e:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
  800441:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800444:	e9 6a ff ff ff       	jmp    8003b3 <vprintfmt+0x35>
  800449:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
  80044c:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  800453:	e9 5b ff ff ff       	jmp    8003b3 <vprintfmt+0x35>
  800458:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  80045b:	89 45 d0             	mov    %eax,-0x30(%ebp)
  80045e:	eb bc                	jmp    80041c <vprintfmt+0x9e>
			lflag++;
  800460:	83 c1 01             	add    $0x1,%ecx
		switch (ch = *(unsigned char *) fmt++) {
  800463:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
  800466:	e9 48 ff ff ff       	jmp    8003b3 <vprintfmt+0x35>
			putch(va_arg(ap, int), putdat);
  80046b:	8b 45 14             	mov    0x14(%ebp),%eax
  80046e:	8d 78 04             	lea    0x4(%eax),%edi
  800471:	83 ec 08             	sub    $0x8,%esp
  800474:	53                   	push   %ebx
  800475:	ff 30                	pushl  (%eax)
  800477:	ff d6                	call   *%esi
			break;
  800479:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
  80047c:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
  80047f:	e9 cf 02 00 00       	jmp    800753 <vprintfmt+0x3d5>
			err = va_arg(ap, int);
  800484:	8b 45 14             	mov    0x14(%ebp),%eax
  800487:	8d 78 04             	lea    0x4(%eax),%edi
  80048a:	8b 00                	mov    (%eax),%eax
  80048c:	99                   	cltd   
  80048d:	31 d0                	xor    %edx,%eax
  80048f:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800491:	83 f8 06             	cmp    $0x6,%eax
  800494:	7f 23                	jg     8004b9 <vprintfmt+0x13b>
  800496:	8b 14 85 48 10 80 00 	mov    0x801048(,%eax,4),%edx
  80049d:	85 d2                	test   %edx,%edx
  80049f:	74 18                	je     8004b9 <vprintfmt+0x13b>
				printfmt(putch, putdat, "%s", p);
  8004a1:	52                   	push   %edx
  8004a2:	68 84 0e 80 00       	push   $0x800e84
  8004a7:	53                   	push   %ebx
  8004a8:	56                   	push   %esi
  8004a9:	e8 b3 fe ff ff       	call   800361 <printfmt>
  8004ae:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
  8004b1:	89 7d 14             	mov    %edi,0x14(%ebp)
  8004b4:	e9 9a 02 00 00       	jmp    800753 <vprintfmt+0x3d5>
				printfmt(putch, putdat, "error %d", err);
  8004b9:	50                   	push   %eax
  8004ba:	68 7b 0e 80 00       	push   $0x800e7b
  8004bf:	53                   	push   %ebx
  8004c0:	56                   	push   %esi
  8004c1:	e8 9b fe ff ff       	call   800361 <printfmt>
  8004c6:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
  8004c9:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
  8004cc:	e9 82 02 00 00       	jmp    800753 <vprintfmt+0x3d5>
			if ((p = va_arg(ap, char *)) == NULL)
  8004d1:	8b 45 14             	mov    0x14(%ebp),%eax
  8004d4:	83 c0 04             	add    $0x4,%eax
  8004d7:	89 45 cc             	mov    %eax,-0x34(%ebp)
  8004da:	8b 45 14             	mov    0x14(%ebp),%eax
  8004dd:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  8004df:	85 ff                	test   %edi,%edi
  8004e1:	b8 74 0e 80 00       	mov    $0x800e74,%eax
  8004e6:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  8004e9:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8004ed:	0f 8e bd 00 00 00    	jle    8005b0 <vprintfmt+0x232>
  8004f3:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  8004f7:	75 0e                	jne    800507 <vprintfmt+0x189>
  8004f9:	89 75 08             	mov    %esi,0x8(%ebp)
  8004fc:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8004ff:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800502:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800505:	eb 6d                	jmp    800574 <vprintfmt+0x1f6>
				for (width -= strnlen(p, precision); width > 0; width--)
  800507:	83 ec 08             	sub    $0x8,%esp
  80050a:	ff 75 d0             	pushl  -0x30(%ebp)
  80050d:	57                   	push   %edi
  80050e:	e8 6e 03 00 00       	call   800881 <strnlen>
  800513:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  800516:	29 c1                	sub    %eax,%ecx
  800518:	89 4d c8             	mov    %ecx,-0x38(%ebp)
  80051b:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  80051e:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  800522:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800525:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  800528:	89 cf                	mov    %ecx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
  80052a:	eb 0f                	jmp    80053b <vprintfmt+0x1bd>
					putch(padc, putdat);
  80052c:	83 ec 08             	sub    $0x8,%esp
  80052f:	53                   	push   %ebx
  800530:	ff 75 e0             	pushl  -0x20(%ebp)
  800533:	ff d6                	call   *%esi
				for (width -= strnlen(p, precision); width > 0; width--)
  800535:	83 ef 01             	sub    $0x1,%edi
  800538:	83 c4 10             	add    $0x10,%esp
  80053b:	85 ff                	test   %edi,%edi
  80053d:	7f ed                	jg     80052c <vprintfmt+0x1ae>
  80053f:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  800542:	8b 4d c8             	mov    -0x38(%ebp),%ecx
  800545:	85 c9                	test   %ecx,%ecx
  800547:	b8 00 00 00 00       	mov    $0x0,%eax
  80054c:	0f 49 c1             	cmovns %ecx,%eax
  80054f:	29 c1                	sub    %eax,%ecx
  800551:	89 75 08             	mov    %esi,0x8(%ebp)
  800554:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800557:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80055a:	89 cb                	mov    %ecx,%ebx
  80055c:	eb 16                	jmp    800574 <vprintfmt+0x1f6>
				if (altflag && (ch < ' ' || ch > '~'))
  80055e:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  800562:	75 31                	jne    800595 <vprintfmt+0x217>
					putch(ch, putdat);
  800564:	83 ec 08             	sub    $0x8,%esp
  800567:	ff 75 0c             	pushl  0xc(%ebp)
  80056a:	50                   	push   %eax
  80056b:	ff 55 08             	call   *0x8(%ebp)
  80056e:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800571:	83 eb 01             	sub    $0x1,%ebx
  800574:	83 c7 01             	add    $0x1,%edi
  800577:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
  80057b:	0f be c2             	movsbl %dl,%eax
  80057e:	85 c0                	test   %eax,%eax
  800580:	74 59                	je     8005db <vprintfmt+0x25d>
  800582:	85 f6                	test   %esi,%esi
  800584:	78 d8                	js     80055e <vprintfmt+0x1e0>
  800586:	83 ee 01             	sub    $0x1,%esi
  800589:	79 d3                	jns    80055e <vprintfmt+0x1e0>
  80058b:	89 df                	mov    %ebx,%edi
  80058d:	8b 75 08             	mov    0x8(%ebp),%esi
  800590:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800593:	eb 37                	jmp    8005cc <vprintfmt+0x24e>
				if (altflag && (ch < ' ' || ch > '~'))
  800595:	0f be d2             	movsbl %dl,%edx
  800598:	83 ea 20             	sub    $0x20,%edx
  80059b:	83 fa 5e             	cmp    $0x5e,%edx
  80059e:	76 c4                	jbe    800564 <vprintfmt+0x1e6>
					putch('?', putdat);
  8005a0:	83 ec 08             	sub    $0x8,%esp
  8005a3:	ff 75 0c             	pushl  0xc(%ebp)
  8005a6:	6a 3f                	push   $0x3f
  8005a8:	ff 55 08             	call   *0x8(%ebp)
  8005ab:	83 c4 10             	add    $0x10,%esp
  8005ae:	eb c1                	jmp    800571 <vprintfmt+0x1f3>
  8005b0:	89 75 08             	mov    %esi,0x8(%ebp)
  8005b3:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8005b6:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8005b9:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  8005bc:	eb b6                	jmp    800574 <vprintfmt+0x1f6>
				putch(' ', putdat);
  8005be:	83 ec 08             	sub    $0x8,%esp
  8005c1:	53                   	push   %ebx
  8005c2:	6a 20                	push   $0x20
  8005c4:	ff d6                	call   *%esi
			for (; width > 0; width--)
  8005c6:	83 ef 01             	sub    $0x1,%edi
  8005c9:	83 c4 10             	add    $0x10,%esp
  8005cc:	85 ff                	test   %edi,%edi
  8005ce:	7f ee                	jg     8005be <vprintfmt+0x240>
			if ((p = va_arg(ap, char *)) == NULL)
  8005d0:	8b 45 cc             	mov    -0x34(%ebp),%eax
  8005d3:	89 45 14             	mov    %eax,0x14(%ebp)
  8005d6:	e9 78 01 00 00       	jmp    800753 <vprintfmt+0x3d5>
  8005db:	89 df                	mov    %ebx,%edi
  8005dd:	8b 75 08             	mov    0x8(%ebp),%esi
  8005e0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8005e3:	eb e7                	jmp    8005cc <vprintfmt+0x24e>
	if (lflag >= 2)
  8005e5:	83 f9 01             	cmp    $0x1,%ecx
  8005e8:	7e 3f                	jle    800629 <vprintfmt+0x2ab>
		return va_arg(*ap, long long);
  8005ea:	8b 45 14             	mov    0x14(%ebp),%eax
  8005ed:	8b 50 04             	mov    0x4(%eax),%edx
  8005f0:	8b 00                	mov    (%eax),%eax
  8005f2:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005f5:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8005f8:	8b 45 14             	mov    0x14(%ebp),%eax
  8005fb:	8d 40 08             	lea    0x8(%eax),%eax
  8005fe:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
  800601:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800605:	79 5c                	jns    800663 <vprintfmt+0x2e5>
				putch('-', putdat);
  800607:	83 ec 08             	sub    $0x8,%esp
  80060a:	53                   	push   %ebx
  80060b:	6a 2d                	push   $0x2d
  80060d:	ff d6                	call   *%esi
				num = -(long long) num;
  80060f:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800612:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  800615:	f7 da                	neg    %edx
  800617:	83 d1 00             	adc    $0x0,%ecx
  80061a:	f7 d9                	neg    %ecx
  80061c:	83 c4 10             	add    $0x10,%esp
			base = 10;
  80061f:	b8 0a 00 00 00       	mov    $0xa,%eax
  800624:	e9 10 01 00 00       	jmp    800739 <vprintfmt+0x3bb>
	else if (lflag)
  800629:	85 c9                	test   %ecx,%ecx
  80062b:	75 1b                	jne    800648 <vprintfmt+0x2ca>
		return va_arg(*ap, int);
  80062d:	8b 45 14             	mov    0x14(%ebp),%eax
  800630:	8b 00                	mov    (%eax),%eax
  800632:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800635:	89 c1                	mov    %eax,%ecx
  800637:	c1 f9 1f             	sar    $0x1f,%ecx
  80063a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  80063d:	8b 45 14             	mov    0x14(%ebp),%eax
  800640:	8d 40 04             	lea    0x4(%eax),%eax
  800643:	89 45 14             	mov    %eax,0x14(%ebp)
  800646:	eb b9                	jmp    800601 <vprintfmt+0x283>
		return va_arg(*ap, long);
  800648:	8b 45 14             	mov    0x14(%ebp),%eax
  80064b:	8b 00                	mov    (%eax),%eax
  80064d:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800650:	89 c1                	mov    %eax,%ecx
  800652:	c1 f9 1f             	sar    $0x1f,%ecx
  800655:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  800658:	8b 45 14             	mov    0x14(%ebp),%eax
  80065b:	8d 40 04             	lea    0x4(%eax),%eax
  80065e:	89 45 14             	mov    %eax,0x14(%ebp)
  800661:	eb 9e                	jmp    800601 <vprintfmt+0x283>
			num = getint(&ap, lflag);
  800663:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800666:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
  800669:	b8 0a 00 00 00       	mov    $0xa,%eax
  80066e:	e9 c6 00 00 00       	jmp    800739 <vprintfmt+0x3bb>
	if (lflag >= 2)
  800673:	83 f9 01             	cmp    $0x1,%ecx
  800676:	7e 18                	jle    800690 <vprintfmt+0x312>
		return va_arg(*ap, unsigned long long);
  800678:	8b 45 14             	mov    0x14(%ebp),%eax
  80067b:	8b 10                	mov    (%eax),%edx
  80067d:	8b 48 04             	mov    0x4(%eax),%ecx
  800680:	8d 40 08             	lea    0x8(%eax),%eax
  800683:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
  800686:	b8 0a 00 00 00       	mov    $0xa,%eax
  80068b:	e9 a9 00 00 00       	jmp    800739 <vprintfmt+0x3bb>
	else if (lflag)
  800690:	85 c9                	test   %ecx,%ecx
  800692:	75 1a                	jne    8006ae <vprintfmt+0x330>
		return va_arg(*ap, unsigned int);
  800694:	8b 45 14             	mov    0x14(%ebp),%eax
  800697:	8b 10                	mov    (%eax),%edx
  800699:	b9 00 00 00 00       	mov    $0x0,%ecx
  80069e:	8d 40 04             	lea    0x4(%eax),%eax
  8006a1:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
  8006a4:	b8 0a 00 00 00       	mov    $0xa,%eax
  8006a9:	e9 8b 00 00 00       	jmp    800739 <vprintfmt+0x3bb>
		return va_arg(*ap, unsigned long);
  8006ae:	8b 45 14             	mov    0x14(%ebp),%eax
  8006b1:	8b 10                	mov    (%eax),%edx
  8006b3:	b9 00 00 00 00       	mov    $0x0,%ecx
  8006b8:	8d 40 04             	lea    0x4(%eax),%eax
  8006bb:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
  8006be:	b8 0a 00 00 00       	mov    $0xa,%eax
  8006c3:	eb 74                	jmp    800739 <vprintfmt+0x3bb>
	if (lflag >= 2)
  8006c5:	83 f9 01             	cmp    $0x1,%ecx
  8006c8:	7e 15                	jle    8006df <vprintfmt+0x361>
		return va_arg(*ap, unsigned long long);
  8006ca:	8b 45 14             	mov    0x14(%ebp),%eax
  8006cd:	8b 10                	mov    (%eax),%edx
  8006cf:	8b 48 04             	mov    0x4(%eax),%ecx
  8006d2:	8d 40 08             	lea    0x8(%eax),%eax
  8006d5:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
  8006d8:	b8 08 00 00 00       	mov    $0x8,%eax
  8006dd:	eb 5a                	jmp    800739 <vprintfmt+0x3bb>
	else if (lflag)
  8006df:	85 c9                	test   %ecx,%ecx
  8006e1:	75 17                	jne    8006fa <vprintfmt+0x37c>
		return va_arg(*ap, unsigned int);
  8006e3:	8b 45 14             	mov    0x14(%ebp),%eax
  8006e6:	8b 10                	mov    (%eax),%edx
  8006e8:	b9 00 00 00 00       	mov    $0x0,%ecx
  8006ed:	8d 40 04             	lea    0x4(%eax),%eax
  8006f0:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
  8006f3:	b8 08 00 00 00       	mov    $0x8,%eax
  8006f8:	eb 3f                	jmp    800739 <vprintfmt+0x3bb>
		return va_arg(*ap, unsigned long);
  8006fa:	8b 45 14             	mov    0x14(%ebp),%eax
  8006fd:	8b 10                	mov    (%eax),%edx
  8006ff:	b9 00 00 00 00       	mov    $0x0,%ecx
  800704:	8d 40 04             	lea    0x4(%eax),%eax
  800707:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
  80070a:	b8 08 00 00 00       	mov    $0x8,%eax
  80070f:	eb 28                	jmp    800739 <vprintfmt+0x3bb>
			putch('0', putdat);
  800711:	83 ec 08             	sub    $0x8,%esp
  800714:	53                   	push   %ebx
  800715:	6a 30                	push   $0x30
  800717:	ff d6                	call   *%esi
			putch('x', putdat);
  800719:	83 c4 08             	add    $0x8,%esp
  80071c:	53                   	push   %ebx
  80071d:	6a 78                	push   $0x78
  80071f:	ff d6                	call   *%esi
			num = (unsigned long long)
  800721:	8b 45 14             	mov    0x14(%ebp),%eax
  800724:	8b 10                	mov    (%eax),%edx
  800726:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
  80072b:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
  80072e:	8d 40 04             	lea    0x4(%eax),%eax
  800731:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  800734:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
  800739:	83 ec 0c             	sub    $0xc,%esp
  80073c:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  800740:	57                   	push   %edi
  800741:	ff 75 e0             	pushl  -0x20(%ebp)
  800744:	50                   	push   %eax
  800745:	51                   	push   %ecx
  800746:	52                   	push   %edx
  800747:	89 da                	mov    %ebx,%edx
  800749:	89 f0                	mov    %esi,%eax
  80074b:	e8 45 fb ff ff       	call   800295 <printnum>
			break;
  800750:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
  800753:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800756:	83 c7 01             	add    $0x1,%edi
  800759:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  80075d:	83 f8 25             	cmp    $0x25,%eax
  800760:	0f 84 2f fc ff ff    	je     800395 <vprintfmt+0x17>
			if (ch == '\0')
  800766:	85 c0                	test   %eax,%eax
  800768:	0f 84 8b 00 00 00    	je     8007f9 <vprintfmt+0x47b>
			putch(ch, putdat);
  80076e:	83 ec 08             	sub    $0x8,%esp
  800771:	53                   	push   %ebx
  800772:	50                   	push   %eax
  800773:	ff d6                	call   *%esi
  800775:	83 c4 10             	add    $0x10,%esp
  800778:	eb dc                	jmp    800756 <vprintfmt+0x3d8>
	if (lflag >= 2)
  80077a:	83 f9 01             	cmp    $0x1,%ecx
  80077d:	7e 15                	jle    800794 <vprintfmt+0x416>
		return va_arg(*ap, unsigned long long);
  80077f:	8b 45 14             	mov    0x14(%ebp),%eax
  800782:	8b 10                	mov    (%eax),%edx
  800784:	8b 48 04             	mov    0x4(%eax),%ecx
  800787:	8d 40 08             	lea    0x8(%eax),%eax
  80078a:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  80078d:	b8 10 00 00 00       	mov    $0x10,%eax
  800792:	eb a5                	jmp    800739 <vprintfmt+0x3bb>
	else if (lflag)
  800794:	85 c9                	test   %ecx,%ecx
  800796:	75 17                	jne    8007af <vprintfmt+0x431>
		return va_arg(*ap, unsigned int);
  800798:	8b 45 14             	mov    0x14(%ebp),%eax
  80079b:	8b 10                	mov    (%eax),%edx
  80079d:	b9 00 00 00 00       	mov    $0x0,%ecx
  8007a2:	8d 40 04             	lea    0x4(%eax),%eax
  8007a5:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  8007a8:	b8 10 00 00 00       	mov    $0x10,%eax
  8007ad:	eb 8a                	jmp    800739 <vprintfmt+0x3bb>
		return va_arg(*ap, unsigned long);
  8007af:	8b 45 14             	mov    0x14(%ebp),%eax
  8007b2:	8b 10                	mov    (%eax),%edx
  8007b4:	b9 00 00 00 00       	mov    $0x0,%ecx
  8007b9:	8d 40 04             	lea    0x4(%eax),%eax
  8007bc:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  8007bf:	b8 10 00 00 00       	mov    $0x10,%eax
  8007c4:	e9 70 ff ff ff       	jmp    800739 <vprintfmt+0x3bb>
			putch(ch, putdat);
  8007c9:	83 ec 08             	sub    $0x8,%esp
  8007cc:	53                   	push   %ebx
  8007cd:	6a 25                	push   $0x25
  8007cf:	ff d6                	call   *%esi
			break;
  8007d1:	83 c4 10             	add    $0x10,%esp
  8007d4:	e9 7a ff ff ff       	jmp    800753 <vprintfmt+0x3d5>
			putch('%', putdat);
  8007d9:	83 ec 08             	sub    $0x8,%esp
  8007dc:	53                   	push   %ebx
  8007dd:	6a 25                	push   $0x25
  8007df:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  8007e1:	83 c4 10             	add    $0x10,%esp
  8007e4:	89 f8                	mov    %edi,%eax
  8007e6:	eb 03                	jmp    8007eb <vprintfmt+0x46d>
  8007e8:	83 e8 01             	sub    $0x1,%eax
  8007eb:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
  8007ef:	75 f7                	jne    8007e8 <vprintfmt+0x46a>
  8007f1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8007f4:	e9 5a ff ff ff       	jmp    800753 <vprintfmt+0x3d5>
}
  8007f9:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8007fc:	5b                   	pop    %ebx
  8007fd:	5e                   	pop    %esi
  8007fe:	5f                   	pop    %edi
  8007ff:	5d                   	pop    %ebp
  800800:	c3                   	ret    

00800801 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800801:	55                   	push   %ebp
  800802:	89 e5                	mov    %esp,%ebp
  800804:	83 ec 18             	sub    $0x18,%esp
  800807:	8b 45 08             	mov    0x8(%ebp),%eax
  80080a:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  80080d:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800810:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800814:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800817:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  80081e:	85 c0                	test   %eax,%eax
  800820:	74 26                	je     800848 <vsnprintf+0x47>
  800822:	85 d2                	test   %edx,%edx
  800824:	7e 22                	jle    800848 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800826:	ff 75 14             	pushl  0x14(%ebp)
  800829:	ff 75 10             	pushl  0x10(%ebp)
  80082c:	8d 45 ec             	lea    -0x14(%ebp),%eax
  80082f:	50                   	push   %eax
  800830:	68 44 03 80 00       	push   $0x800344
  800835:	e8 44 fb ff ff       	call   80037e <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  80083a:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80083d:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800840:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800843:	83 c4 10             	add    $0x10,%esp
}
  800846:	c9                   	leave  
  800847:	c3                   	ret    
		return -E_INVAL;
  800848:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
  80084d:	eb f7                	jmp    800846 <vsnprintf+0x45>

0080084f <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  80084f:	55                   	push   %ebp
  800850:	89 e5                	mov    %esp,%ebp
  800852:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800855:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800858:	50                   	push   %eax
  800859:	ff 75 10             	pushl  0x10(%ebp)
  80085c:	ff 75 0c             	pushl  0xc(%ebp)
  80085f:	ff 75 08             	pushl  0x8(%ebp)
  800862:	e8 9a ff ff ff       	call   800801 <vsnprintf>
	va_end(ap);

	return rc;
}
  800867:	c9                   	leave  
  800868:	c3                   	ret    

00800869 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800869:	55                   	push   %ebp
  80086a:	89 e5                	mov    %esp,%ebp
  80086c:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  80086f:	b8 00 00 00 00       	mov    $0x0,%eax
  800874:	eb 03                	jmp    800879 <strlen+0x10>
		n++;
  800876:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
  800879:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  80087d:	75 f7                	jne    800876 <strlen+0xd>
	return n;
}
  80087f:	5d                   	pop    %ebp
  800880:	c3                   	ret    

00800881 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800881:	55                   	push   %ebp
  800882:	89 e5                	mov    %esp,%ebp
  800884:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800887:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80088a:	b8 00 00 00 00       	mov    $0x0,%eax
  80088f:	eb 03                	jmp    800894 <strnlen+0x13>
		n++;
  800891:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800894:	39 d0                	cmp    %edx,%eax
  800896:	74 06                	je     80089e <strnlen+0x1d>
  800898:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
  80089c:	75 f3                	jne    800891 <strnlen+0x10>
	return n;
}
  80089e:	5d                   	pop    %ebp
  80089f:	c3                   	ret    

008008a0 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8008a0:	55                   	push   %ebp
  8008a1:	89 e5                	mov    %esp,%ebp
  8008a3:	53                   	push   %ebx
  8008a4:	8b 45 08             	mov    0x8(%ebp),%eax
  8008a7:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8008aa:	89 c2                	mov    %eax,%edx
  8008ac:	83 c1 01             	add    $0x1,%ecx
  8008af:	83 c2 01             	add    $0x1,%edx
  8008b2:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  8008b6:	88 5a ff             	mov    %bl,-0x1(%edx)
  8008b9:	84 db                	test   %bl,%bl
  8008bb:	75 ef                	jne    8008ac <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8008bd:	5b                   	pop    %ebx
  8008be:	5d                   	pop    %ebp
  8008bf:	c3                   	ret    

008008c0 <strcat>:

char *
strcat(char *dst, const char *src)
{
  8008c0:	55                   	push   %ebp
  8008c1:	89 e5                	mov    %esp,%ebp
  8008c3:	53                   	push   %ebx
  8008c4:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8008c7:	53                   	push   %ebx
  8008c8:	e8 9c ff ff ff       	call   800869 <strlen>
  8008cd:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  8008d0:	ff 75 0c             	pushl  0xc(%ebp)
  8008d3:	01 d8                	add    %ebx,%eax
  8008d5:	50                   	push   %eax
  8008d6:	e8 c5 ff ff ff       	call   8008a0 <strcpy>
	return dst;
}
  8008db:	89 d8                	mov    %ebx,%eax
  8008dd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8008e0:	c9                   	leave  
  8008e1:	c3                   	ret    

008008e2 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8008e2:	55                   	push   %ebp
  8008e3:	89 e5                	mov    %esp,%ebp
  8008e5:	56                   	push   %esi
  8008e6:	53                   	push   %ebx
  8008e7:	8b 75 08             	mov    0x8(%ebp),%esi
  8008ea:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8008ed:	89 f3                	mov    %esi,%ebx
  8008ef:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8008f2:	89 f2                	mov    %esi,%edx
  8008f4:	eb 0f                	jmp    800905 <strncpy+0x23>
		*dst++ = *src;
  8008f6:	83 c2 01             	add    $0x1,%edx
  8008f9:	0f b6 01             	movzbl (%ecx),%eax
  8008fc:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  8008ff:	80 39 01             	cmpb   $0x1,(%ecx)
  800902:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
  800905:	39 da                	cmp    %ebx,%edx
  800907:	75 ed                	jne    8008f6 <strncpy+0x14>
	}
	return ret;
}
  800909:	89 f0                	mov    %esi,%eax
  80090b:	5b                   	pop    %ebx
  80090c:	5e                   	pop    %esi
  80090d:	5d                   	pop    %ebp
  80090e:	c3                   	ret    

0080090f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  80090f:	55                   	push   %ebp
  800910:	89 e5                	mov    %esp,%ebp
  800912:	56                   	push   %esi
  800913:	53                   	push   %ebx
  800914:	8b 75 08             	mov    0x8(%ebp),%esi
  800917:	8b 55 0c             	mov    0xc(%ebp),%edx
  80091a:	8b 4d 10             	mov    0x10(%ebp),%ecx
  80091d:	89 f0                	mov    %esi,%eax
  80091f:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800923:	85 c9                	test   %ecx,%ecx
  800925:	75 0b                	jne    800932 <strlcpy+0x23>
  800927:	eb 17                	jmp    800940 <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800929:	83 c2 01             	add    $0x1,%edx
  80092c:	83 c0 01             	add    $0x1,%eax
  80092f:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
  800932:	39 d8                	cmp    %ebx,%eax
  800934:	74 07                	je     80093d <strlcpy+0x2e>
  800936:	0f b6 0a             	movzbl (%edx),%ecx
  800939:	84 c9                	test   %cl,%cl
  80093b:	75 ec                	jne    800929 <strlcpy+0x1a>
		*dst = '\0';
  80093d:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800940:	29 f0                	sub    %esi,%eax
}
  800942:	5b                   	pop    %ebx
  800943:	5e                   	pop    %esi
  800944:	5d                   	pop    %ebp
  800945:	c3                   	ret    

00800946 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800946:	55                   	push   %ebp
  800947:	89 e5                	mov    %esp,%ebp
  800949:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80094c:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  80094f:	eb 06                	jmp    800957 <strcmp+0x11>
		p++, q++;
  800951:	83 c1 01             	add    $0x1,%ecx
  800954:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
  800957:	0f b6 01             	movzbl (%ecx),%eax
  80095a:	84 c0                	test   %al,%al
  80095c:	74 04                	je     800962 <strcmp+0x1c>
  80095e:	3a 02                	cmp    (%edx),%al
  800960:	74 ef                	je     800951 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800962:	0f b6 c0             	movzbl %al,%eax
  800965:	0f b6 12             	movzbl (%edx),%edx
  800968:	29 d0                	sub    %edx,%eax
}
  80096a:	5d                   	pop    %ebp
  80096b:	c3                   	ret    

0080096c <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  80096c:	55                   	push   %ebp
  80096d:	89 e5                	mov    %esp,%ebp
  80096f:	53                   	push   %ebx
  800970:	8b 45 08             	mov    0x8(%ebp),%eax
  800973:	8b 55 0c             	mov    0xc(%ebp),%edx
  800976:	89 c3                	mov    %eax,%ebx
  800978:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  80097b:	eb 06                	jmp    800983 <strncmp+0x17>
		n--, p++, q++;
  80097d:	83 c0 01             	add    $0x1,%eax
  800980:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
  800983:	39 d8                	cmp    %ebx,%eax
  800985:	74 16                	je     80099d <strncmp+0x31>
  800987:	0f b6 08             	movzbl (%eax),%ecx
  80098a:	84 c9                	test   %cl,%cl
  80098c:	74 04                	je     800992 <strncmp+0x26>
  80098e:	3a 0a                	cmp    (%edx),%cl
  800990:	74 eb                	je     80097d <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800992:	0f b6 00             	movzbl (%eax),%eax
  800995:	0f b6 12             	movzbl (%edx),%edx
  800998:	29 d0                	sub    %edx,%eax
}
  80099a:	5b                   	pop    %ebx
  80099b:	5d                   	pop    %ebp
  80099c:	c3                   	ret    
		return 0;
  80099d:	b8 00 00 00 00       	mov    $0x0,%eax
  8009a2:	eb f6                	jmp    80099a <strncmp+0x2e>

008009a4 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  8009a4:	55                   	push   %ebp
  8009a5:	89 e5                	mov    %esp,%ebp
  8009a7:	8b 45 08             	mov    0x8(%ebp),%eax
  8009aa:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8009ae:	0f b6 10             	movzbl (%eax),%edx
  8009b1:	84 d2                	test   %dl,%dl
  8009b3:	74 09                	je     8009be <strchr+0x1a>
		if (*s == c)
  8009b5:	38 ca                	cmp    %cl,%dl
  8009b7:	74 0a                	je     8009c3 <strchr+0x1f>
	for (; *s; s++)
  8009b9:	83 c0 01             	add    $0x1,%eax
  8009bc:	eb f0                	jmp    8009ae <strchr+0xa>
			return (char *) s;
	return 0;
  8009be:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8009c3:	5d                   	pop    %ebp
  8009c4:	c3                   	ret    

008009c5 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8009c5:	55                   	push   %ebp
  8009c6:	89 e5                	mov    %esp,%ebp
  8009c8:	8b 45 08             	mov    0x8(%ebp),%eax
  8009cb:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8009cf:	eb 03                	jmp    8009d4 <strfind+0xf>
  8009d1:	83 c0 01             	add    $0x1,%eax
  8009d4:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  8009d7:	38 ca                	cmp    %cl,%dl
  8009d9:	74 04                	je     8009df <strfind+0x1a>
  8009db:	84 d2                	test   %dl,%dl
  8009dd:	75 f2                	jne    8009d1 <strfind+0xc>
			break;
	return (char *) s;
}
  8009df:	5d                   	pop    %ebp
  8009e0:	c3                   	ret    

008009e1 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  8009e1:	55                   	push   %ebp
  8009e2:	89 e5                	mov    %esp,%ebp
  8009e4:	57                   	push   %edi
  8009e5:	56                   	push   %esi
  8009e6:	53                   	push   %ebx
  8009e7:	8b 7d 08             	mov    0x8(%ebp),%edi
  8009ea:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  8009ed:	85 c9                	test   %ecx,%ecx
  8009ef:	74 13                	je     800a04 <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  8009f1:	f7 c7 03 00 00 00    	test   $0x3,%edi
  8009f7:	75 05                	jne    8009fe <memset+0x1d>
  8009f9:	f6 c1 03             	test   $0x3,%cl
  8009fc:	74 0d                	je     800a0b <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  8009fe:	8b 45 0c             	mov    0xc(%ebp),%eax
  800a01:	fc                   	cld    
  800a02:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800a04:	89 f8                	mov    %edi,%eax
  800a06:	5b                   	pop    %ebx
  800a07:	5e                   	pop    %esi
  800a08:	5f                   	pop    %edi
  800a09:	5d                   	pop    %ebp
  800a0a:	c3                   	ret    
		c &= 0xFF;
  800a0b:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800a0f:	89 d3                	mov    %edx,%ebx
  800a11:	c1 e3 08             	shl    $0x8,%ebx
  800a14:	89 d0                	mov    %edx,%eax
  800a16:	c1 e0 18             	shl    $0x18,%eax
  800a19:	89 d6                	mov    %edx,%esi
  800a1b:	c1 e6 10             	shl    $0x10,%esi
  800a1e:	09 f0                	or     %esi,%eax
  800a20:	09 c2                	or     %eax,%edx
  800a22:	09 da                	or     %ebx,%edx
			:: "D" (v), "a" (c), "c" (n/4)
  800a24:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
  800a27:	89 d0                	mov    %edx,%eax
  800a29:	fc                   	cld    
  800a2a:	f3 ab                	rep stos %eax,%es:(%edi)
  800a2c:	eb d6                	jmp    800a04 <memset+0x23>

00800a2e <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800a2e:	55                   	push   %ebp
  800a2f:	89 e5                	mov    %esp,%ebp
  800a31:	57                   	push   %edi
  800a32:	56                   	push   %esi
  800a33:	8b 45 08             	mov    0x8(%ebp),%eax
  800a36:	8b 75 0c             	mov    0xc(%ebp),%esi
  800a39:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800a3c:	39 c6                	cmp    %eax,%esi
  800a3e:	73 35                	jae    800a75 <memmove+0x47>
  800a40:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800a43:	39 c2                	cmp    %eax,%edx
  800a45:	76 2e                	jbe    800a75 <memmove+0x47>
		s += n;
		d += n;
  800a47:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a4a:	89 d6                	mov    %edx,%esi
  800a4c:	09 fe                	or     %edi,%esi
  800a4e:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800a54:	74 0c                	je     800a62 <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  800a56:	83 ef 01             	sub    $0x1,%edi
  800a59:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
  800a5c:	fd                   	std    
  800a5d:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800a5f:	fc                   	cld    
  800a60:	eb 21                	jmp    800a83 <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a62:	f6 c1 03             	test   $0x3,%cl
  800a65:	75 ef                	jne    800a56 <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  800a67:	83 ef 04             	sub    $0x4,%edi
  800a6a:	8d 72 fc             	lea    -0x4(%edx),%esi
  800a6d:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
  800a70:	fd                   	std    
  800a71:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800a73:	eb ea                	jmp    800a5f <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a75:	89 f2                	mov    %esi,%edx
  800a77:	09 c2                	or     %eax,%edx
  800a79:	f6 c2 03             	test   $0x3,%dl
  800a7c:	74 09                	je     800a87 <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800a7e:	89 c7                	mov    %eax,%edi
  800a80:	fc                   	cld    
  800a81:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800a83:	5e                   	pop    %esi
  800a84:	5f                   	pop    %edi
  800a85:	5d                   	pop    %ebp
  800a86:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a87:	f6 c1 03             	test   $0x3,%cl
  800a8a:	75 f2                	jne    800a7e <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  800a8c:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
  800a8f:	89 c7                	mov    %eax,%edi
  800a91:	fc                   	cld    
  800a92:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800a94:	eb ed                	jmp    800a83 <memmove+0x55>

00800a96 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800a96:	55                   	push   %ebp
  800a97:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  800a99:	ff 75 10             	pushl  0x10(%ebp)
  800a9c:	ff 75 0c             	pushl  0xc(%ebp)
  800a9f:	ff 75 08             	pushl  0x8(%ebp)
  800aa2:	e8 87 ff ff ff       	call   800a2e <memmove>
}
  800aa7:	c9                   	leave  
  800aa8:	c3                   	ret    

00800aa9 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800aa9:	55                   	push   %ebp
  800aaa:	89 e5                	mov    %esp,%ebp
  800aac:	56                   	push   %esi
  800aad:	53                   	push   %ebx
  800aae:	8b 45 08             	mov    0x8(%ebp),%eax
  800ab1:	8b 55 0c             	mov    0xc(%ebp),%edx
  800ab4:	89 c6                	mov    %eax,%esi
  800ab6:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800ab9:	39 f0                	cmp    %esi,%eax
  800abb:	74 1c                	je     800ad9 <memcmp+0x30>
		if (*s1 != *s2)
  800abd:	0f b6 08             	movzbl (%eax),%ecx
  800ac0:	0f b6 1a             	movzbl (%edx),%ebx
  800ac3:	38 d9                	cmp    %bl,%cl
  800ac5:	75 08                	jne    800acf <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
  800ac7:	83 c0 01             	add    $0x1,%eax
  800aca:	83 c2 01             	add    $0x1,%edx
  800acd:	eb ea                	jmp    800ab9 <memcmp+0x10>
			return (int) *s1 - (int) *s2;
  800acf:	0f b6 c1             	movzbl %cl,%eax
  800ad2:	0f b6 db             	movzbl %bl,%ebx
  800ad5:	29 d8                	sub    %ebx,%eax
  800ad7:	eb 05                	jmp    800ade <memcmp+0x35>
	}

	return 0;
  800ad9:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800ade:	5b                   	pop    %ebx
  800adf:	5e                   	pop    %esi
  800ae0:	5d                   	pop    %ebp
  800ae1:	c3                   	ret    

00800ae2 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800ae2:	55                   	push   %ebp
  800ae3:	89 e5                	mov    %esp,%ebp
  800ae5:	8b 45 08             	mov    0x8(%ebp),%eax
  800ae8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
  800aeb:	89 c2                	mov    %eax,%edx
  800aed:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800af0:	39 d0                	cmp    %edx,%eax
  800af2:	73 09                	jae    800afd <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
  800af4:	38 08                	cmp    %cl,(%eax)
  800af6:	74 05                	je     800afd <memfind+0x1b>
	for (; s < ends; s++)
  800af8:	83 c0 01             	add    $0x1,%eax
  800afb:	eb f3                	jmp    800af0 <memfind+0xe>
			break;
	return (void *) s;
}
  800afd:	5d                   	pop    %ebp
  800afe:	c3                   	ret    

00800aff <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800aff:	55                   	push   %ebp
  800b00:	89 e5                	mov    %esp,%ebp
  800b02:	57                   	push   %edi
  800b03:	56                   	push   %esi
  800b04:	53                   	push   %ebx
  800b05:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800b08:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800b0b:	eb 03                	jmp    800b10 <strtol+0x11>
		s++;
  800b0d:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
  800b10:	0f b6 01             	movzbl (%ecx),%eax
  800b13:	3c 20                	cmp    $0x20,%al
  800b15:	74 f6                	je     800b0d <strtol+0xe>
  800b17:	3c 09                	cmp    $0x9,%al
  800b19:	74 f2                	je     800b0d <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
  800b1b:	3c 2b                	cmp    $0x2b,%al
  800b1d:	74 2e                	je     800b4d <strtol+0x4e>
	int neg = 0;
  800b1f:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
  800b24:	3c 2d                	cmp    $0x2d,%al
  800b26:	74 2f                	je     800b57 <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800b28:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800b2e:	75 05                	jne    800b35 <strtol+0x36>
  800b30:	80 39 30             	cmpb   $0x30,(%ecx)
  800b33:	74 2c                	je     800b61 <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800b35:	85 db                	test   %ebx,%ebx
  800b37:	75 0a                	jne    800b43 <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800b39:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
  800b3e:	80 39 30             	cmpb   $0x30,(%ecx)
  800b41:	74 28                	je     800b6b <strtol+0x6c>
		base = 10;
  800b43:	b8 00 00 00 00       	mov    $0x0,%eax
  800b48:	89 5d 10             	mov    %ebx,0x10(%ebp)
  800b4b:	eb 50                	jmp    800b9d <strtol+0x9e>
		s++;
  800b4d:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
  800b50:	bf 00 00 00 00       	mov    $0x0,%edi
  800b55:	eb d1                	jmp    800b28 <strtol+0x29>
		s++, neg = 1;
  800b57:	83 c1 01             	add    $0x1,%ecx
  800b5a:	bf 01 00 00 00       	mov    $0x1,%edi
  800b5f:	eb c7                	jmp    800b28 <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800b61:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800b65:	74 0e                	je     800b75 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
  800b67:	85 db                	test   %ebx,%ebx
  800b69:	75 d8                	jne    800b43 <strtol+0x44>
		s++, base = 8;
  800b6b:	83 c1 01             	add    $0x1,%ecx
  800b6e:	bb 08 00 00 00       	mov    $0x8,%ebx
  800b73:	eb ce                	jmp    800b43 <strtol+0x44>
		s += 2, base = 16;
  800b75:	83 c1 02             	add    $0x2,%ecx
  800b78:	bb 10 00 00 00       	mov    $0x10,%ebx
  800b7d:	eb c4                	jmp    800b43 <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
  800b7f:	8d 72 9f             	lea    -0x61(%edx),%esi
  800b82:	89 f3                	mov    %esi,%ebx
  800b84:	80 fb 19             	cmp    $0x19,%bl
  800b87:	77 29                	ja     800bb2 <strtol+0xb3>
			dig = *s - 'a' + 10;
  800b89:	0f be d2             	movsbl %dl,%edx
  800b8c:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
  800b8f:	3b 55 10             	cmp    0x10(%ebp),%edx
  800b92:	7d 30                	jge    800bc4 <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
  800b94:	83 c1 01             	add    $0x1,%ecx
  800b97:	0f af 45 10          	imul   0x10(%ebp),%eax
  800b9b:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
  800b9d:	0f b6 11             	movzbl (%ecx),%edx
  800ba0:	8d 72 d0             	lea    -0x30(%edx),%esi
  800ba3:	89 f3                	mov    %esi,%ebx
  800ba5:	80 fb 09             	cmp    $0x9,%bl
  800ba8:	77 d5                	ja     800b7f <strtol+0x80>
			dig = *s - '0';
  800baa:	0f be d2             	movsbl %dl,%edx
  800bad:	83 ea 30             	sub    $0x30,%edx
  800bb0:	eb dd                	jmp    800b8f <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
  800bb2:	8d 72 bf             	lea    -0x41(%edx),%esi
  800bb5:	89 f3                	mov    %esi,%ebx
  800bb7:	80 fb 19             	cmp    $0x19,%bl
  800bba:	77 08                	ja     800bc4 <strtol+0xc5>
			dig = *s - 'A' + 10;
  800bbc:	0f be d2             	movsbl %dl,%edx
  800bbf:	83 ea 37             	sub    $0x37,%edx
  800bc2:	eb cb                	jmp    800b8f <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
  800bc4:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800bc8:	74 05                	je     800bcf <strtol+0xd0>
		*endptr = (char *) s;
  800bca:	8b 75 0c             	mov    0xc(%ebp),%esi
  800bcd:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
  800bcf:	89 c2                	mov    %eax,%edx
  800bd1:	f7 da                	neg    %edx
  800bd3:	85 ff                	test   %edi,%edi
  800bd5:	0f 45 c2             	cmovne %edx,%eax
}
  800bd8:	5b                   	pop    %ebx
  800bd9:	5e                   	pop    %esi
  800bda:	5f                   	pop    %edi
  800bdb:	5d                   	pop    %ebp
  800bdc:	c3                   	ret    
  800bdd:	66 90                	xchg   %ax,%ax
  800bdf:	90                   	nop

00800be0 <__udivdi3>:
  800be0:	55                   	push   %ebp
  800be1:	57                   	push   %edi
  800be2:	56                   	push   %esi
  800be3:	53                   	push   %ebx
  800be4:	83 ec 1c             	sub    $0x1c,%esp
  800be7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  800beb:	8b 6c 24 30          	mov    0x30(%esp),%ebp
  800bef:	8b 74 24 34          	mov    0x34(%esp),%esi
  800bf3:	8b 5c 24 38          	mov    0x38(%esp),%ebx
  800bf7:	85 d2                	test   %edx,%edx
  800bf9:	75 35                	jne    800c30 <__udivdi3+0x50>
  800bfb:	39 f3                	cmp    %esi,%ebx
  800bfd:	0f 87 bd 00 00 00    	ja     800cc0 <__udivdi3+0xe0>
  800c03:	85 db                	test   %ebx,%ebx
  800c05:	89 d9                	mov    %ebx,%ecx
  800c07:	75 0b                	jne    800c14 <__udivdi3+0x34>
  800c09:	b8 01 00 00 00       	mov    $0x1,%eax
  800c0e:	31 d2                	xor    %edx,%edx
  800c10:	f7 f3                	div    %ebx
  800c12:	89 c1                	mov    %eax,%ecx
  800c14:	31 d2                	xor    %edx,%edx
  800c16:	89 f0                	mov    %esi,%eax
  800c18:	f7 f1                	div    %ecx
  800c1a:	89 c6                	mov    %eax,%esi
  800c1c:	89 e8                	mov    %ebp,%eax
  800c1e:	89 f7                	mov    %esi,%edi
  800c20:	f7 f1                	div    %ecx
  800c22:	89 fa                	mov    %edi,%edx
  800c24:	83 c4 1c             	add    $0x1c,%esp
  800c27:	5b                   	pop    %ebx
  800c28:	5e                   	pop    %esi
  800c29:	5f                   	pop    %edi
  800c2a:	5d                   	pop    %ebp
  800c2b:	c3                   	ret    
  800c2c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800c30:	39 f2                	cmp    %esi,%edx
  800c32:	77 7c                	ja     800cb0 <__udivdi3+0xd0>
  800c34:	0f bd fa             	bsr    %edx,%edi
  800c37:	83 f7 1f             	xor    $0x1f,%edi
  800c3a:	0f 84 98 00 00 00    	je     800cd8 <__udivdi3+0xf8>
  800c40:	89 f9                	mov    %edi,%ecx
  800c42:	b8 20 00 00 00       	mov    $0x20,%eax
  800c47:	29 f8                	sub    %edi,%eax
  800c49:	d3 e2                	shl    %cl,%edx
  800c4b:	89 54 24 08          	mov    %edx,0x8(%esp)
  800c4f:	89 c1                	mov    %eax,%ecx
  800c51:	89 da                	mov    %ebx,%edx
  800c53:	d3 ea                	shr    %cl,%edx
  800c55:	8b 4c 24 08          	mov    0x8(%esp),%ecx
  800c59:	09 d1                	or     %edx,%ecx
  800c5b:	89 f2                	mov    %esi,%edx
  800c5d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800c61:	89 f9                	mov    %edi,%ecx
  800c63:	d3 e3                	shl    %cl,%ebx
  800c65:	89 c1                	mov    %eax,%ecx
  800c67:	d3 ea                	shr    %cl,%edx
  800c69:	89 f9                	mov    %edi,%ecx
  800c6b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  800c6f:	d3 e6                	shl    %cl,%esi
  800c71:	89 eb                	mov    %ebp,%ebx
  800c73:	89 c1                	mov    %eax,%ecx
  800c75:	d3 eb                	shr    %cl,%ebx
  800c77:	09 de                	or     %ebx,%esi
  800c79:	89 f0                	mov    %esi,%eax
  800c7b:	f7 74 24 08          	divl   0x8(%esp)
  800c7f:	89 d6                	mov    %edx,%esi
  800c81:	89 c3                	mov    %eax,%ebx
  800c83:	f7 64 24 0c          	mull   0xc(%esp)
  800c87:	39 d6                	cmp    %edx,%esi
  800c89:	72 0c                	jb     800c97 <__udivdi3+0xb7>
  800c8b:	89 f9                	mov    %edi,%ecx
  800c8d:	d3 e5                	shl    %cl,%ebp
  800c8f:	39 c5                	cmp    %eax,%ebp
  800c91:	73 5d                	jae    800cf0 <__udivdi3+0x110>
  800c93:	39 d6                	cmp    %edx,%esi
  800c95:	75 59                	jne    800cf0 <__udivdi3+0x110>
  800c97:	8d 43 ff             	lea    -0x1(%ebx),%eax
  800c9a:	31 ff                	xor    %edi,%edi
  800c9c:	89 fa                	mov    %edi,%edx
  800c9e:	83 c4 1c             	add    $0x1c,%esp
  800ca1:	5b                   	pop    %ebx
  800ca2:	5e                   	pop    %esi
  800ca3:	5f                   	pop    %edi
  800ca4:	5d                   	pop    %ebp
  800ca5:	c3                   	ret    
  800ca6:	8d 76 00             	lea    0x0(%esi),%esi
  800ca9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
  800cb0:	31 ff                	xor    %edi,%edi
  800cb2:	31 c0                	xor    %eax,%eax
  800cb4:	89 fa                	mov    %edi,%edx
  800cb6:	83 c4 1c             	add    $0x1c,%esp
  800cb9:	5b                   	pop    %ebx
  800cba:	5e                   	pop    %esi
  800cbb:	5f                   	pop    %edi
  800cbc:	5d                   	pop    %ebp
  800cbd:	c3                   	ret    
  800cbe:	66 90                	xchg   %ax,%ax
  800cc0:	31 ff                	xor    %edi,%edi
  800cc2:	89 e8                	mov    %ebp,%eax
  800cc4:	89 f2                	mov    %esi,%edx
  800cc6:	f7 f3                	div    %ebx
  800cc8:	89 fa                	mov    %edi,%edx
  800cca:	83 c4 1c             	add    $0x1c,%esp
  800ccd:	5b                   	pop    %ebx
  800cce:	5e                   	pop    %esi
  800ccf:	5f                   	pop    %edi
  800cd0:	5d                   	pop    %ebp
  800cd1:	c3                   	ret    
  800cd2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800cd8:	39 f2                	cmp    %esi,%edx
  800cda:	72 06                	jb     800ce2 <__udivdi3+0x102>
  800cdc:	31 c0                	xor    %eax,%eax
  800cde:	39 eb                	cmp    %ebp,%ebx
  800ce0:	77 d2                	ja     800cb4 <__udivdi3+0xd4>
  800ce2:	b8 01 00 00 00       	mov    $0x1,%eax
  800ce7:	eb cb                	jmp    800cb4 <__udivdi3+0xd4>
  800ce9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800cf0:	89 d8                	mov    %ebx,%eax
  800cf2:	31 ff                	xor    %edi,%edi
  800cf4:	eb be                	jmp    800cb4 <__udivdi3+0xd4>
  800cf6:	66 90                	xchg   %ax,%ax
  800cf8:	66 90                	xchg   %ax,%ax
  800cfa:	66 90                	xchg   %ax,%ax
  800cfc:	66 90                	xchg   %ax,%ax
  800cfe:	66 90                	xchg   %ax,%ax

00800d00 <__umoddi3>:
  800d00:	55                   	push   %ebp
  800d01:	57                   	push   %edi
  800d02:	56                   	push   %esi
  800d03:	53                   	push   %ebx
  800d04:	83 ec 1c             	sub    $0x1c,%esp
  800d07:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
  800d0b:	8b 74 24 30          	mov    0x30(%esp),%esi
  800d0f:	8b 5c 24 34          	mov    0x34(%esp),%ebx
  800d13:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800d17:	85 ed                	test   %ebp,%ebp
  800d19:	89 f0                	mov    %esi,%eax
  800d1b:	89 da                	mov    %ebx,%edx
  800d1d:	75 19                	jne    800d38 <__umoddi3+0x38>
  800d1f:	39 df                	cmp    %ebx,%edi
  800d21:	0f 86 b1 00 00 00    	jbe    800dd8 <__umoddi3+0xd8>
  800d27:	f7 f7                	div    %edi
  800d29:	89 d0                	mov    %edx,%eax
  800d2b:	31 d2                	xor    %edx,%edx
  800d2d:	83 c4 1c             	add    $0x1c,%esp
  800d30:	5b                   	pop    %ebx
  800d31:	5e                   	pop    %esi
  800d32:	5f                   	pop    %edi
  800d33:	5d                   	pop    %ebp
  800d34:	c3                   	ret    
  800d35:	8d 76 00             	lea    0x0(%esi),%esi
  800d38:	39 dd                	cmp    %ebx,%ebp
  800d3a:	77 f1                	ja     800d2d <__umoddi3+0x2d>
  800d3c:	0f bd cd             	bsr    %ebp,%ecx
  800d3f:	83 f1 1f             	xor    $0x1f,%ecx
  800d42:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  800d46:	0f 84 b4 00 00 00    	je     800e00 <__umoddi3+0x100>
  800d4c:	b8 20 00 00 00       	mov    $0x20,%eax
  800d51:	89 c2                	mov    %eax,%edx
  800d53:	8b 44 24 04          	mov    0x4(%esp),%eax
  800d57:	29 c2                	sub    %eax,%edx
  800d59:	89 c1                	mov    %eax,%ecx
  800d5b:	89 f8                	mov    %edi,%eax
  800d5d:	d3 e5                	shl    %cl,%ebp
  800d5f:	89 d1                	mov    %edx,%ecx
  800d61:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800d65:	d3 e8                	shr    %cl,%eax
  800d67:	09 c5                	or     %eax,%ebp
  800d69:	8b 44 24 04          	mov    0x4(%esp),%eax
  800d6d:	89 c1                	mov    %eax,%ecx
  800d6f:	d3 e7                	shl    %cl,%edi
  800d71:	89 d1                	mov    %edx,%ecx
  800d73:	89 7c 24 08          	mov    %edi,0x8(%esp)
  800d77:	89 df                	mov    %ebx,%edi
  800d79:	d3 ef                	shr    %cl,%edi
  800d7b:	89 c1                	mov    %eax,%ecx
  800d7d:	89 f0                	mov    %esi,%eax
  800d7f:	d3 e3                	shl    %cl,%ebx
  800d81:	89 d1                	mov    %edx,%ecx
  800d83:	89 fa                	mov    %edi,%edx
  800d85:	d3 e8                	shr    %cl,%eax
  800d87:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  800d8c:	09 d8                	or     %ebx,%eax
  800d8e:	f7 f5                	div    %ebp
  800d90:	d3 e6                	shl    %cl,%esi
  800d92:	89 d1                	mov    %edx,%ecx
  800d94:	f7 64 24 08          	mull   0x8(%esp)
  800d98:	39 d1                	cmp    %edx,%ecx
  800d9a:	89 c3                	mov    %eax,%ebx
  800d9c:	89 d7                	mov    %edx,%edi
  800d9e:	72 06                	jb     800da6 <__umoddi3+0xa6>
  800da0:	75 0e                	jne    800db0 <__umoddi3+0xb0>
  800da2:	39 c6                	cmp    %eax,%esi
  800da4:	73 0a                	jae    800db0 <__umoddi3+0xb0>
  800da6:	2b 44 24 08          	sub    0x8(%esp),%eax
  800daa:	19 ea                	sbb    %ebp,%edx
  800dac:	89 d7                	mov    %edx,%edi
  800dae:	89 c3                	mov    %eax,%ebx
  800db0:	89 ca                	mov    %ecx,%edx
  800db2:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
  800db7:	29 de                	sub    %ebx,%esi
  800db9:	19 fa                	sbb    %edi,%edx
  800dbb:	8b 5c 24 04          	mov    0x4(%esp),%ebx
  800dbf:	89 d0                	mov    %edx,%eax
  800dc1:	d3 e0                	shl    %cl,%eax
  800dc3:	89 d9                	mov    %ebx,%ecx
  800dc5:	d3 ee                	shr    %cl,%esi
  800dc7:	d3 ea                	shr    %cl,%edx
  800dc9:	09 f0                	or     %esi,%eax
  800dcb:	83 c4 1c             	add    $0x1c,%esp
  800dce:	5b                   	pop    %ebx
  800dcf:	5e                   	pop    %esi
  800dd0:	5f                   	pop    %edi
  800dd1:	5d                   	pop    %ebp
  800dd2:	c3                   	ret    
  800dd3:	90                   	nop
  800dd4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800dd8:	85 ff                	test   %edi,%edi
  800dda:	89 f9                	mov    %edi,%ecx
  800ddc:	75 0b                	jne    800de9 <__umoddi3+0xe9>
  800dde:	b8 01 00 00 00       	mov    $0x1,%eax
  800de3:	31 d2                	xor    %edx,%edx
  800de5:	f7 f7                	div    %edi
  800de7:	89 c1                	mov    %eax,%ecx
  800de9:	89 d8                	mov    %ebx,%eax
  800deb:	31 d2                	xor    %edx,%edx
  800ded:	f7 f1                	div    %ecx
  800def:	89 f0                	mov    %esi,%eax
  800df1:	f7 f1                	div    %ecx
  800df3:	e9 31 ff ff ff       	jmp    800d29 <__umoddi3+0x29>
  800df8:	90                   	nop
  800df9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800e00:	39 dd                	cmp    %ebx,%ebp
  800e02:	72 08                	jb     800e0c <__umoddi3+0x10c>
  800e04:	39 f7                	cmp    %esi,%edi
  800e06:	0f 87 21 ff ff ff    	ja     800d2d <__umoddi3+0x2d>
  800e0c:	89 da                	mov    %ebx,%edx
  800e0e:	89 f0                	mov    %esi,%eax
  800e10:	29 f8                	sub    %edi,%eax
  800e12:	19 ea                	sbb    %ebp,%edx
  800e14:	e9 14 ff ff ff       	jmp    800d2d <__umoddi3+0x2d>
