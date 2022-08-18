
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	17010113          	addi	sp,sp,368 # 80009170 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fde70713          	addi	a4,a4,-34 # 80009030 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	0bc78793          	addi	a5,a5,188 # 80006120 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd27d7>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	25078793          	addi	a5,a5,592 # 800012fe <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  timerinit();
    800000d8:	00000097          	auipc	ra,0x0
    800000dc:	f44080e7          	jalr	-188(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000e0:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000e4:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000e6:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e8:	30200073          	mret
}
    800000ec:	60a2                	ld	ra,8(sp)
    800000ee:	6402                	ld	s0,0(sp)
    800000f0:	0141                	addi	sp,sp,16
    800000f2:	8082                	ret

00000000800000f4 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000f4:	715d                	addi	sp,sp,-80
    800000f6:	e486                	sd	ra,72(sp)
    800000f8:	e0a2                	sd	s0,64(sp)
    800000fa:	fc26                	sd	s1,56(sp)
    800000fc:	f84a                	sd	s2,48(sp)
    800000fe:	f44e                	sd	s3,40(sp)
    80000100:	f052                	sd	s4,32(sp)
    80000102:	ec56                	sd	s5,24(sp)
    80000104:	0880                	addi	s0,sp,80
    80000106:	8a2a                	mv	s4,a0
    80000108:	84ae                	mv	s1,a1
    8000010a:	89b2                	mv	s3,a2
  int i;

  acquire(&cons.lock);
    8000010c:	00011517          	auipc	a0,0x11
    80000110:	06450513          	addi	a0,a0,100 # 80011170 <cons>
    80000114:	00001097          	auipc	ra,0x1
    80000118:	c58080e7          	jalr	-936(ra) # 80000d6c <acquire>
  for(i = 0; i < n; i++){
    8000011c:	05305b63          	blez	s3,80000172 <consolewrite+0x7e>
    80000120:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000122:	5afd                	li	s5,-1
    80000124:	4685                	li	a3,1
    80000126:	8626                	mv	a2,s1
    80000128:	85d2                	mv	a1,s4
    8000012a:	fbf40513          	addi	a0,s0,-65
    8000012e:	00002097          	auipc	ra,0x2
    80000132:	74e080e7          	jalr	1870(ra) # 8000287c <either_copyin>
    80000136:	01550c63          	beq	a0,s5,8000014e <consolewrite+0x5a>
      break;
    uartputc(c);
    8000013a:	fbf44503          	lbu	a0,-65(s0)
    8000013e:	00000097          	auipc	ra,0x0
    80000142:	7aa080e7          	jalr	1962(ra) # 800008e8 <uartputc>
  for(i = 0; i < n; i++){
    80000146:	2905                	addiw	s2,s2,1
    80000148:	0485                	addi	s1,s1,1
    8000014a:	fd299de3          	bne	s3,s2,80000124 <consolewrite+0x30>
  }
  release(&cons.lock);
    8000014e:	00011517          	auipc	a0,0x11
    80000152:	02250513          	addi	a0,a0,34 # 80011170 <cons>
    80000156:	00001097          	auipc	ra,0x1
    8000015a:	ce6080e7          	jalr	-794(ra) # 80000e3c <release>

  return i;
}
    8000015e:	854a                	mv	a0,s2
    80000160:	60a6                	ld	ra,72(sp)
    80000162:	6406                	ld	s0,64(sp)
    80000164:	74e2                	ld	s1,56(sp)
    80000166:	7942                	ld	s2,48(sp)
    80000168:	79a2                	ld	s3,40(sp)
    8000016a:	7a02                	ld	s4,32(sp)
    8000016c:	6ae2                	ld	s5,24(sp)
    8000016e:	6161                	addi	sp,sp,80
    80000170:	8082                	ret
  for(i = 0; i < n; i++){
    80000172:	4901                	li	s2,0
    80000174:	bfe9                	j	8000014e <consolewrite+0x5a>

0000000080000176 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000176:	7119                	addi	sp,sp,-128
    80000178:	fc86                	sd	ra,120(sp)
    8000017a:	f8a2                	sd	s0,112(sp)
    8000017c:	f4a6                	sd	s1,104(sp)
    8000017e:	f0ca                	sd	s2,96(sp)
    80000180:	ecce                	sd	s3,88(sp)
    80000182:	e8d2                	sd	s4,80(sp)
    80000184:	e4d6                	sd	s5,72(sp)
    80000186:	e0da                	sd	s6,64(sp)
    80000188:	fc5e                	sd	s7,56(sp)
    8000018a:	f862                	sd	s8,48(sp)
    8000018c:	f466                	sd	s9,40(sp)
    8000018e:	f06a                	sd	s10,32(sp)
    80000190:	ec6e                	sd	s11,24(sp)
    80000192:	0100                	addi	s0,sp,128
    80000194:	8b2a                	mv	s6,a0
    80000196:	8aae                	mv	s5,a1
    80000198:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    8000019a:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000019e:	00011517          	auipc	a0,0x11
    800001a2:	fd250513          	addi	a0,a0,-46 # 80011170 <cons>
    800001a6:	00001097          	auipc	ra,0x1
    800001aa:	bc6080e7          	jalr	-1082(ra) # 80000d6c <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001ae:	00011497          	auipc	s1,0x11
    800001b2:	fc248493          	addi	s1,s1,-62 # 80011170 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001b6:	89a6                	mv	s3,s1
    800001b8:	00011917          	auipc	s2,0x11
    800001bc:	05890913          	addi	s2,s2,88 # 80011210 <cons+0xa0>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001c0:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001c2:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001c4:	4da9                	li	s11,10
  while(n > 0){
    800001c6:	07405863          	blez	s4,80000236 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001ca:	0a04a783          	lw	a5,160(s1)
    800001ce:	0a44a703          	lw	a4,164(s1)
    800001d2:	02f71463          	bne	a4,a5,800001fa <consoleread+0x84>
      if(myproc()->killed){
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	bde080e7          	jalr	-1058(ra) # 80001db4 <myproc>
    800001de:	5d1c                	lw	a5,56(a0)
    800001e0:	e7b5                	bnez	a5,8000024c <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001e2:	85ce                	mv	a1,s3
    800001e4:	854a                	mv	a0,s2
    800001e6:	00002097          	auipc	ra,0x2
    800001ea:	3de080e7          	jalr	990(ra) # 800025c4 <sleep>
    while(cons.r == cons.w){
    800001ee:	0a04a783          	lw	a5,160(s1)
    800001f2:	0a44a703          	lw	a4,164(s1)
    800001f6:	fef700e3          	beq	a4,a5,800001d6 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001fa:	0017871b          	addiw	a4,a5,1
    800001fe:	0ae4a023          	sw	a4,160(s1)
    80000202:	07f7f713          	andi	a4,a5,127
    80000206:	9726                	add	a4,a4,s1
    80000208:	02074703          	lbu	a4,32(a4)
    8000020c:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    80000210:	079c0663          	beq	s8,s9,8000027c <consoleread+0x106>
    cbuf = c;
    80000214:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000218:	4685                	li	a3,1
    8000021a:	f8f40613          	addi	a2,s0,-113
    8000021e:	85d6                	mv	a1,s5
    80000220:	855a                	mv	a0,s6
    80000222:	00002097          	auipc	ra,0x2
    80000226:	604080e7          	jalr	1540(ra) # 80002826 <either_copyout>
    8000022a:	01a50663          	beq	a0,s10,80000236 <consoleread+0xc0>
    dst++;
    8000022e:	0a85                	addi	s5,s5,1
    --n;
    80000230:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000232:	f9bc1ae3          	bne	s8,s11,800001c6 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000236:	00011517          	auipc	a0,0x11
    8000023a:	f3a50513          	addi	a0,a0,-198 # 80011170 <cons>
    8000023e:	00001097          	auipc	ra,0x1
    80000242:	bfe080e7          	jalr	-1026(ra) # 80000e3c <release>

  return target - n;
    80000246:	414b853b          	subw	a0,s7,s4
    8000024a:	a811                	j	8000025e <consoleread+0xe8>
        release(&cons.lock);
    8000024c:	00011517          	auipc	a0,0x11
    80000250:	f2450513          	addi	a0,a0,-220 # 80011170 <cons>
    80000254:	00001097          	auipc	ra,0x1
    80000258:	be8080e7          	jalr	-1048(ra) # 80000e3c <release>
        return -1;
    8000025c:	557d                	li	a0,-1
}
    8000025e:	70e6                	ld	ra,120(sp)
    80000260:	7446                	ld	s0,112(sp)
    80000262:	74a6                	ld	s1,104(sp)
    80000264:	7906                	ld	s2,96(sp)
    80000266:	69e6                	ld	s3,88(sp)
    80000268:	6a46                	ld	s4,80(sp)
    8000026a:	6aa6                	ld	s5,72(sp)
    8000026c:	6b06                	ld	s6,64(sp)
    8000026e:	7be2                	ld	s7,56(sp)
    80000270:	7c42                	ld	s8,48(sp)
    80000272:	7ca2                	ld	s9,40(sp)
    80000274:	7d02                	ld	s10,32(sp)
    80000276:	6de2                	ld	s11,24(sp)
    80000278:	6109                	addi	sp,sp,128
    8000027a:	8082                	ret
      if(n < target){
    8000027c:	000a071b          	sext.w	a4,s4
    80000280:	fb777be3          	bgeu	a4,s7,80000236 <consoleread+0xc0>
        cons.r--;
    80000284:	00011717          	auipc	a4,0x11
    80000288:	f8f72623          	sw	a5,-116(a4) # 80011210 <cons+0xa0>
    8000028c:	b76d                	j	80000236 <consoleread+0xc0>

000000008000028e <consputc>:
{
    8000028e:	1141                	addi	sp,sp,-16
    80000290:	e406                	sd	ra,8(sp)
    80000292:	e022                	sd	s0,0(sp)
    80000294:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000296:	10000793          	li	a5,256
    8000029a:	00f50a63          	beq	a0,a5,800002ae <consputc+0x20>
    uartputc_sync(c);
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	564080e7          	jalr	1380(ra) # 80000802 <uartputc_sync>
}
    800002a6:	60a2                	ld	ra,8(sp)
    800002a8:	6402                	ld	s0,0(sp)
    800002aa:	0141                	addi	sp,sp,16
    800002ac:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002ae:	4521                	li	a0,8
    800002b0:	00000097          	auipc	ra,0x0
    800002b4:	552080e7          	jalr	1362(ra) # 80000802 <uartputc_sync>
    800002b8:	02000513          	li	a0,32
    800002bc:	00000097          	auipc	ra,0x0
    800002c0:	546080e7          	jalr	1350(ra) # 80000802 <uartputc_sync>
    800002c4:	4521                	li	a0,8
    800002c6:	00000097          	auipc	ra,0x0
    800002ca:	53c080e7          	jalr	1340(ra) # 80000802 <uartputc_sync>
    800002ce:	bfe1                	j	800002a6 <consputc+0x18>

00000000800002d0 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002d0:	1101                	addi	sp,sp,-32
    800002d2:	ec06                	sd	ra,24(sp)
    800002d4:	e822                	sd	s0,16(sp)
    800002d6:	e426                	sd	s1,8(sp)
    800002d8:	e04a                	sd	s2,0(sp)
    800002da:	1000                	addi	s0,sp,32
    800002dc:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002de:	00011517          	auipc	a0,0x11
    800002e2:	e9250513          	addi	a0,a0,-366 # 80011170 <cons>
    800002e6:	00001097          	auipc	ra,0x1
    800002ea:	a86080e7          	jalr	-1402(ra) # 80000d6c <acquire>

  switch(c){
    800002ee:	47d5                	li	a5,21
    800002f0:	0af48663          	beq	s1,a5,8000039c <consoleintr+0xcc>
    800002f4:	0297ca63          	blt	a5,s1,80000328 <consoleintr+0x58>
    800002f8:	47a1                	li	a5,8
    800002fa:	0ef48763          	beq	s1,a5,800003e8 <consoleintr+0x118>
    800002fe:	47c1                	li	a5,16
    80000300:	10f49a63          	bne	s1,a5,80000414 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    80000304:	00002097          	auipc	ra,0x2
    80000308:	5ce080e7          	jalr	1486(ra) # 800028d2 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    8000030c:	00011517          	auipc	a0,0x11
    80000310:	e6450513          	addi	a0,a0,-412 # 80011170 <cons>
    80000314:	00001097          	auipc	ra,0x1
    80000318:	b28080e7          	jalr	-1240(ra) # 80000e3c <release>
}
    8000031c:	60e2                	ld	ra,24(sp)
    8000031e:	6442                	ld	s0,16(sp)
    80000320:	64a2                	ld	s1,8(sp)
    80000322:	6902                	ld	s2,0(sp)
    80000324:	6105                	addi	sp,sp,32
    80000326:	8082                	ret
  switch(c){
    80000328:	07f00793          	li	a5,127
    8000032c:	0af48e63          	beq	s1,a5,800003e8 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000330:	00011717          	auipc	a4,0x11
    80000334:	e4070713          	addi	a4,a4,-448 # 80011170 <cons>
    80000338:	0a872783          	lw	a5,168(a4)
    8000033c:	0a072703          	lw	a4,160(a4)
    80000340:	9f99                	subw	a5,a5,a4
    80000342:	07f00713          	li	a4,127
    80000346:	fcf763e3          	bltu	a4,a5,8000030c <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000034a:	47b5                	li	a5,13
    8000034c:	0cf48763          	beq	s1,a5,8000041a <consoleintr+0x14a>
      consputc(c);
    80000350:	8526                	mv	a0,s1
    80000352:	00000097          	auipc	ra,0x0
    80000356:	f3c080e7          	jalr	-196(ra) # 8000028e <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000035a:	00011797          	auipc	a5,0x11
    8000035e:	e1678793          	addi	a5,a5,-490 # 80011170 <cons>
    80000362:	0a87a703          	lw	a4,168(a5)
    80000366:	0017069b          	addiw	a3,a4,1
    8000036a:	0006861b          	sext.w	a2,a3
    8000036e:	0ad7a423          	sw	a3,168(a5)
    80000372:	07f77713          	andi	a4,a4,127
    80000376:	97ba                	add	a5,a5,a4
    80000378:	02978023          	sb	s1,32(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000037c:	47a9                	li	a5,10
    8000037e:	0cf48563          	beq	s1,a5,80000448 <consoleintr+0x178>
    80000382:	4791                	li	a5,4
    80000384:	0cf48263          	beq	s1,a5,80000448 <consoleintr+0x178>
    80000388:	00011797          	auipc	a5,0x11
    8000038c:	e887a783          	lw	a5,-376(a5) # 80011210 <cons+0xa0>
    80000390:	0807879b          	addiw	a5,a5,128
    80000394:	f6f61ce3          	bne	a2,a5,8000030c <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000398:	863e                	mv	a2,a5
    8000039a:	a07d                	j	80000448 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000039c:	00011717          	auipc	a4,0x11
    800003a0:	dd470713          	addi	a4,a4,-556 # 80011170 <cons>
    800003a4:	0a872783          	lw	a5,168(a4)
    800003a8:	0a472703          	lw	a4,164(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003ac:	00011497          	auipc	s1,0x11
    800003b0:	dc448493          	addi	s1,s1,-572 # 80011170 <cons>
    while(cons.e != cons.w &&
    800003b4:	4929                	li	s2,10
    800003b6:	f4f70be3          	beq	a4,a5,8000030c <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003ba:	37fd                	addiw	a5,a5,-1
    800003bc:	07f7f713          	andi	a4,a5,127
    800003c0:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003c2:	02074703          	lbu	a4,32(a4)
    800003c6:	f52703e3          	beq	a4,s2,8000030c <consoleintr+0x3c>
      cons.e--;
    800003ca:	0af4a423          	sw	a5,168(s1)
      consputc(BACKSPACE);
    800003ce:	10000513          	li	a0,256
    800003d2:	00000097          	auipc	ra,0x0
    800003d6:	ebc080e7          	jalr	-324(ra) # 8000028e <consputc>
    while(cons.e != cons.w &&
    800003da:	0a84a783          	lw	a5,168(s1)
    800003de:	0a44a703          	lw	a4,164(s1)
    800003e2:	fcf71ce3          	bne	a4,a5,800003ba <consoleintr+0xea>
    800003e6:	b71d                	j	8000030c <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003e8:	00011717          	auipc	a4,0x11
    800003ec:	d8870713          	addi	a4,a4,-632 # 80011170 <cons>
    800003f0:	0a872783          	lw	a5,168(a4)
    800003f4:	0a472703          	lw	a4,164(a4)
    800003f8:	f0f70ae3          	beq	a4,a5,8000030c <consoleintr+0x3c>
      cons.e--;
    800003fc:	37fd                	addiw	a5,a5,-1
    800003fe:	00011717          	auipc	a4,0x11
    80000402:	e0f72d23          	sw	a5,-486(a4) # 80011218 <cons+0xa8>
      consputc(BACKSPACE);
    80000406:	10000513          	li	a0,256
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e84080e7          	jalr	-380(ra) # 8000028e <consputc>
    80000412:	bded                	j	8000030c <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000414:	ee048ce3          	beqz	s1,8000030c <consoleintr+0x3c>
    80000418:	bf21                	j	80000330 <consoleintr+0x60>
      consputc(c);
    8000041a:	4529                	li	a0,10
    8000041c:	00000097          	auipc	ra,0x0
    80000420:	e72080e7          	jalr	-398(ra) # 8000028e <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000424:	00011797          	auipc	a5,0x11
    80000428:	d4c78793          	addi	a5,a5,-692 # 80011170 <cons>
    8000042c:	0a87a703          	lw	a4,168(a5)
    80000430:	0017069b          	addiw	a3,a4,1
    80000434:	0006861b          	sext.w	a2,a3
    80000438:	0ad7a423          	sw	a3,168(a5)
    8000043c:	07f77713          	andi	a4,a4,127
    80000440:	97ba                	add	a5,a5,a4
    80000442:	4729                	li	a4,10
    80000444:	02e78023          	sb	a4,32(a5)
        cons.w = cons.e;
    80000448:	00011797          	auipc	a5,0x11
    8000044c:	dcc7a623          	sw	a2,-564(a5) # 80011214 <cons+0xa4>
        wakeup(&cons.r);
    80000450:	00011517          	auipc	a0,0x11
    80000454:	dc050513          	addi	a0,a0,-576 # 80011210 <cons+0xa0>
    80000458:	00002097          	auipc	ra,0x2
    8000045c:	2f2080e7          	jalr	754(ra) # 8000274a <wakeup>
    80000460:	b575                	j	8000030c <consoleintr+0x3c>

0000000080000462 <consoleinit>:

void
consoleinit(void)
{
    80000462:	1141                	addi	sp,sp,-16
    80000464:	e406                	sd	ra,8(sp)
    80000466:	e022                	sd	s0,0(sp)
    80000468:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000046a:	00008597          	auipc	a1,0x8
    8000046e:	ba658593          	addi	a1,a1,-1114 # 80008010 <etext+0x10>
    80000472:	00011517          	auipc	a0,0x11
    80000476:	cfe50513          	addi	a0,a0,-770 # 80011170 <cons>
    8000047a:	00001097          	auipc	ra,0x1
    8000047e:	a6e080e7          	jalr	-1426(ra) # 80000ee8 <initlock>

  uartinit();
    80000482:	00000097          	auipc	ra,0x0
    80000486:	330080e7          	jalr	816(ra) # 800007b2 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000048a:	00026797          	auipc	a5,0x26
    8000048e:	b8678793          	addi	a5,a5,-1146 # 80026010 <devsw>
    80000492:	00000717          	auipc	a4,0x0
    80000496:	ce470713          	addi	a4,a4,-796 # 80000176 <consoleread>
    8000049a:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000049c:	00000717          	auipc	a4,0x0
    800004a0:	c5870713          	addi	a4,a4,-936 # 800000f4 <consolewrite>
    800004a4:	ef98                	sd	a4,24(a5)
}
    800004a6:	60a2                	ld	ra,8(sp)
    800004a8:	6402                	ld	s0,0(sp)
    800004aa:	0141                	addi	sp,sp,16
    800004ac:	8082                	ret

00000000800004ae <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004ae:	7179                	addi	sp,sp,-48
    800004b0:	f406                	sd	ra,40(sp)
    800004b2:	f022                	sd	s0,32(sp)
    800004b4:	ec26                	sd	s1,24(sp)
    800004b6:	e84a                	sd	s2,16(sp)
    800004b8:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004ba:	c219                	beqz	a2,800004c0 <printint+0x12>
    800004bc:	08054663          	bltz	a0,80000548 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004c0:	2501                	sext.w	a0,a0
    800004c2:	4881                	li	a7,0
    800004c4:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004c8:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004ca:	2581                	sext.w	a1,a1
    800004cc:	00008617          	auipc	a2,0x8
    800004d0:	b7460613          	addi	a2,a2,-1164 # 80008040 <digits>
    800004d4:	883a                	mv	a6,a4
    800004d6:	2705                	addiw	a4,a4,1
    800004d8:	02b577bb          	remuw	a5,a0,a1
    800004dc:	1782                	slli	a5,a5,0x20
    800004de:	9381                	srli	a5,a5,0x20
    800004e0:	97b2                	add	a5,a5,a2
    800004e2:	0007c783          	lbu	a5,0(a5)
    800004e6:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004ea:	0005079b          	sext.w	a5,a0
    800004ee:	02b5553b          	divuw	a0,a0,a1
    800004f2:	0685                	addi	a3,a3,1
    800004f4:	feb7f0e3          	bgeu	a5,a1,800004d4 <printint+0x26>

  if(sign)
    800004f8:	00088b63          	beqz	a7,8000050e <printint+0x60>
    buf[i++] = '-';
    800004fc:	fe040793          	addi	a5,s0,-32
    80000500:	973e                	add	a4,a4,a5
    80000502:	02d00793          	li	a5,45
    80000506:	fef70823          	sb	a5,-16(a4)
    8000050a:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    8000050e:	02e05763          	blez	a4,8000053c <printint+0x8e>
    80000512:	fd040793          	addi	a5,s0,-48
    80000516:	00e784b3          	add	s1,a5,a4
    8000051a:	fff78913          	addi	s2,a5,-1
    8000051e:	993a                	add	s2,s2,a4
    80000520:	377d                	addiw	a4,a4,-1
    80000522:	1702                	slli	a4,a4,0x20
    80000524:	9301                	srli	a4,a4,0x20
    80000526:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000052a:	fff4c503          	lbu	a0,-1(s1)
    8000052e:	00000097          	auipc	ra,0x0
    80000532:	d60080e7          	jalr	-672(ra) # 8000028e <consputc>
  while(--i >= 0)
    80000536:	14fd                	addi	s1,s1,-1
    80000538:	ff2499e3          	bne	s1,s2,8000052a <printint+0x7c>
}
    8000053c:	70a2                	ld	ra,40(sp)
    8000053e:	7402                	ld	s0,32(sp)
    80000540:	64e2                	ld	s1,24(sp)
    80000542:	6942                	ld	s2,16(sp)
    80000544:	6145                	addi	sp,sp,48
    80000546:	8082                	ret
    x = -xx;
    80000548:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000054c:	4885                	li	a7,1
    x = -xx;
    8000054e:	bf9d                	j	800004c4 <printint+0x16>

0000000080000550 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000550:	1101                	addi	sp,sp,-32
    80000552:	ec06                	sd	ra,24(sp)
    80000554:	e822                	sd	s0,16(sp)
    80000556:	e426                	sd	s1,8(sp)
    80000558:	1000                	addi	s0,sp,32
    8000055a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000055c:	00011797          	auipc	a5,0x11
    80000560:	ce07a223          	sw	zero,-796(a5) # 80011240 <pr+0x20>
  printf("panic: ");
    80000564:	00008517          	auipc	a0,0x8
    80000568:	ab450513          	addi	a0,a0,-1356 # 80008018 <etext+0x18>
    8000056c:	00000097          	auipc	ra,0x0
    80000570:	02e080e7          	jalr	46(ra) # 8000059a <printf>
  printf(s);
    80000574:	8526                	mv	a0,s1
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	024080e7          	jalr	36(ra) # 8000059a <printf>
  printf("\n");
    8000057e:	00008517          	auipc	a0,0x8
    80000582:	bfa50513          	addi	a0,a0,-1030 # 80008178 <digits+0x138>
    80000586:	00000097          	auipc	ra,0x0
    8000058a:	014080e7          	jalr	20(ra) # 8000059a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000058e:	4785                	li	a5,1
    80000590:	00009717          	auipc	a4,0x9
    80000594:	a6f72823          	sw	a5,-1424(a4) # 80009000 <panicked>
  for(;;)
    80000598:	a001                	j	80000598 <panic+0x48>

000000008000059a <printf>:
{
    8000059a:	7131                	addi	sp,sp,-192
    8000059c:	fc86                	sd	ra,120(sp)
    8000059e:	f8a2                	sd	s0,112(sp)
    800005a0:	f4a6                	sd	s1,104(sp)
    800005a2:	f0ca                	sd	s2,96(sp)
    800005a4:	ecce                	sd	s3,88(sp)
    800005a6:	e8d2                	sd	s4,80(sp)
    800005a8:	e4d6                	sd	s5,72(sp)
    800005aa:	e0da                	sd	s6,64(sp)
    800005ac:	fc5e                	sd	s7,56(sp)
    800005ae:	f862                	sd	s8,48(sp)
    800005b0:	f466                	sd	s9,40(sp)
    800005b2:	f06a                	sd	s10,32(sp)
    800005b4:	ec6e                	sd	s11,24(sp)
    800005b6:	0100                	addi	s0,sp,128
    800005b8:	8a2a                	mv	s4,a0
    800005ba:	e40c                	sd	a1,8(s0)
    800005bc:	e810                	sd	a2,16(s0)
    800005be:	ec14                	sd	a3,24(s0)
    800005c0:	f018                	sd	a4,32(s0)
    800005c2:	f41c                	sd	a5,40(s0)
    800005c4:	03043823          	sd	a6,48(s0)
    800005c8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005cc:	00011d97          	auipc	s11,0x11
    800005d0:	c74dad83          	lw	s11,-908(s11) # 80011240 <pr+0x20>
  if(locking)
    800005d4:	020d9b63          	bnez	s11,8000060a <printf+0x70>
  if (fmt == 0)
    800005d8:	040a0263          	beqz	s4,8000061c <printf+0x82>
  va_start(ap, fmt);
    800005dc:	00840793          	addi	a5,s0,8
    800005e0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005e4:	000a4503          	lbu	a0,0(s4)
    800005e8:	16050263          	beqz	a0,8000074c <printf+0x1b2>
    800005ec:	4481                	li	s1,0
    if(c != '%'){
    800005ee:	02500a93          	li	s5,37
    switch(c){
    800005f2:	07000b13          	li	s6,112
  consputc('x');
    800005f6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005f8:	00008b97          	auipc	s7,0x8
    800005fc:	a48b8b93          	addi	s7,s7,-1464 # 80008040 <digits>
    switch(c){
    80000600:	07300c93          	li	s9,115
    80000604:	06400c13          	li	s8,100
    80000608:	a82d                	j	80000642 <printf+0xa8>
    acquire(&pr.lock);
    8000060a:	00011517          	auipc	a0,0x11
    8000060e:	c1650513          	addi	a0,a0,-1002 # 80011220 <pr>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	75a080e7          	jalr	1882(ra) # 80000d6c <acquire>
    8000061a:	bf7d                	j	800005d8 <printf+0x3e>
    panic("null fmt");
    8000061c:	00008517          	auipc	a0,0x8
    80000620:	a0c50513          	addi	a0,a0,-1524 # 80008028 <etext+0x28>
    80000624:	00000097          	auipc	ra,0x0
    80000628:	f2c080e7          	jalr	-212(ra) # 80000550 <panic>
      consputc(c);
    8000062c:	00000097          	auipc	ra,0x0
    80000630:	c62080e7          	jalr	-926(ra) # 8000028e <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c503          	lbu	a0,0(a5)
    8000063e:	10050763          	beqz	a0,8000074c <printf+0x1b2>
    if(c != '%'){
    80000642:	ff5515e3          	bne	a0,s5,8000062c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000646:	2485                	addiw	s1,s1,1
    80000648:	009a07b3          	add	a5,s4,s1
    8000064c:	0007c783          	lbu	a5,0(a5)
    80000650:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000654:	cfe5                	beqz	a5,8000074c <printf+0x1b2>
    switch(c){
    80000656:	05678a63          	beq	a5,s6,800006aa <printf+0x110>
    8000065a:	02fb7663          	bgeu	s6,a5,80000686 <printf+0xec>
    8000065e:	09978963          	beq	a5,s9,800006f0 <printf+0x156>
    80000662:	07800713          	li	a4,120
    80000666:	0ce79863          	bne	a5,a4,80000736 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    8000066a:	f8843783          	ld	a5,-120(s0)
    8000066e:	00878713          	addi	a4,a5,8
    80000672:	f8e43423          	sd	a4,-120(s0)
    80000676:	4605                	li	a2,1
    80000678:	85ea                	mv	a1,s10
    8000067a:	4388                	lw	a0,0(a5)
    8000067c:	00000097          	auipc	ra,0x0
    80000680:	e32080e7          	jalr	-462(ra) # 800004ae <printint>
      break;
    80000684:	bf45                	j	80000634 <printf+0x9a>
    switch(c){
    80000686:	0b578263          	beq	a5,s5,8000072a <printf+0x190>
    8000068a:	0b879663          	bne	a5,s8,80000736 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000068e:	f8843783          	ld	a5,-120(s0)
    80000692:	00878713          	addi	a4,a5,8
    80000696:	f8e43423          	sd	a4,-120(s0)
    8000069a:	4605                	li	a2,1
    8000069c:	45a9                	li	a1,10
    8000069e:	4388                	lw	a0,0(a5)
    800006a0:	00000097          	auipc	ra,0x0
    800006a4:	e0e080e7          	jalr	-498(ra) # 800004ae <printint>
      break;
    800006a8:	b771                	j	80000634 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    800006aa:	f8843783          	ld	a5,-120(s0)
    800006ae:	00878713          	addi	a4,a5,8
    800006b2:	f8e43423          	sd	a4,-120(s0)
    800006b6:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006ba:	03000513          	li	a0,48
    800006be:	00000097          	auipc	ra,0x0
    800006c2:	bd0080e7          	jalr	-1072(ra) # 8000028e <consputc>
  consputc('x');
    800006c6:	07800513          	li	a0,120
    800006ca:	00000097          	auipc	ra,0x0
    800006ce:	bc4080e7          	jalr	-1084(ra) # 8000028e <consputc>
    800006d2:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006d4:	03c9d793          	srli	a5,s3,0x3c
    800006d8:	97de                	add	a5,a5,s7
    800006da:	0007c503          	lbu	a0,0(a5)
    800006de:	00000097          	auipc	ra,0x0
    800006e2:	bb0080e7          	jalr	-1104(ra) # 8000028e <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006e6:	0992                	slli	s3,s3,0x4
    800006e8:	397d                	addiw	s2,s2,-1
    800006ea:	fe0915e3          	bnez	s2,800006d4 <printf+0x13a>
    800006ee:	b799                	j	80000634 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006f0:	f8843783          	ld	a5,-120(s0)
    800006f4:	00878713          	addi	a4,a5,8
    800006f8:	f8e43423          	sd	a4,-120(s0)
    800006fc:	0007b903          	ld	s2,0(a5)
    80000700:	00090e63          	beqz	s2,8000071c <printf+0x182>
      for(; *s; s++)
    80000704:	00094503          	lbu	a0,0(s2)
    80000708:	d515                	beqz	a0,80000634 <printf+0x9a>
        consputc(*s);
    8000070a:	00000097          	auipc	ra,0x0
    8000070e:	b84080e7          	jalr	-1148(ra) # 8000028e <consputc>
      for(; *s; s++)
    80000712:	0905                	addi	s2,s2,1
    80000714:	00094503          	lbu	a0,0(s2)
    80000718:	f96d                	bnez	a0,8000070a <printf+0x170>
    8000071a:	bf29                	j	80000634 <printf+0x9a>
        s = "(null)";
    8000071c:	00008917          	auipc	s2,0x8
    80000720:	90490913          	addi	s2,s2,-1788 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000724:	02800513          	li	a0,40
    80000728:	b7cd                	j	8000070a <printf+0x170>
      consputc('%');
    8000072a:	8556                	mv	a0,s5
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b62080e7          	jalr	-1182(ra) # 8000028e <consputc>
      break;
    80000734:	b701                	j	80000634 <printf+0x9a>
      consputc('%');
    80000736:	8556                	mv	a0,s5
    80000738:	00000097          	auipc	ra,0x0
    8000073c:	b56080e7          	jalr	-1194(ra) # 8000028e <consputc>
      consputc(c);
    80000740:	854a                	mv	a0,s2
    80000742:	00000097          	auipc	ra,0x0
    80000746:	b4c080e7          	jalr	-1204(ra) # 8000028e <consputc>
      break;
    8000074a:	b5ed                	j	80000634 <printf+0x9a>
  if(locking)
    8000074c:	020d9163          	bnez	s11,8000076e <printf+0x1d4>
}
    80000750:	70e6                	ld	ra,120(sp)
    80000752:	7446                	ld	s0,112(sp)
    80000754:	74a6                	ld	s1,104(sp)
    80000756:	7906                	ld	s2,96(sp)
    80000758:	69e6                	ld	s3,88(sp)
    8000075a:	6a46                	ld	s4,80(sp)
    8000075c:	6aa6                	ld	s5,72(sp)
    8000075e:	6b06                	ld	s6,64(sp)
    80000760:	7be2                	ld	s7,56(sp)
    80000762:	7c42                	ld	s8,48(sp)
    80000764:	7ca2                	ld	s9,40(sp)
    80000766:	7d02                	ld	s10,32(sp)
    80000768:	6de2                	ld	s11,24(sp)
    8000076a:	6129                	addi	sp,sp,192
    8000076c:	8082                	ret
    release(&pr.lock);
    8000076e:	00011517          	auipc	a0,0x11
    80000772:	ab250513          	addi	a0,a0,-1358 # 80011220 <pr>
    80000776:	00000097          	auipc	ra,0x0
    8000077a:	6c6080e7          	jalr	1734(ra) # 80000e3c <release>
}
    8000077e:	bfc9                	j	80000750 <printf+0x1b6>

0000000080000780 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000780:	1101                	addi	sp,sp,-32
    80000782:	ec06                	sd	ra,24(sp)
    80000784:	e822                	sd	s0,16(sp)
    80000786:	e426                	sd	s1,8(sp)
    80000788:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000078a:	00011497          	auipc	s1,0x11
    8000078e:	a9648493          	addi	s1,s1,-1386 # 80011220 <pr>
    80000792:	00008597          	auipc	a1,0x8
    80000796:	8a658593          	addi	a1,a1,-1882 # 80008038 <etext+0x38>
    8000079a:	8526                	mv	a0,s1
    8000079c:	00000097          	auipc	ra,0x0
    800007a0:	74c080e7          	jalr	1868(ra) # 80000ee8 <initlock>
  pr.locking = 1;
    800007a4:	4785                	li	a5,1
    800007a6:	d09c                	sw	a5,32(s1)
}
    800007a8:	60e2                	ld	ra,24(sp)
    800007aa:	6442                	ld	s0,16(sp)
    800007ac:	64a2                	ld	s1,8(sp)
    800007ae:	6105                	addi	sp,sp,32
    800007b0:	8082                	ret

00000000800007b2 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007b2:	1141                	addi	sp,sp,-16
    800007b4:	e406                	sd	ra,8(sp)
    800007b6:	e022                	sd	s0,0(sp)
    800007b8:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007ba:	100007b7          	lui	a5,0x10000
    800007be:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007c2:	f8000713          	li	a4,-128
    800007c6:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007ca:	470d                	li	a4,3
    800007cc:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007d0:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007d4:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007d8:	469d                	li	a3,7
    800007da:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007de:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007e2:	00008597          	auipc	a1,0x8
    800007e6:	87658593          	addi	a1,a1,-1930 # 80008058 <digits+0x18>
    800007ea:	00011517          	auipc	a0,0x11
    800007ee:	a5e50513          	addi	a0,a0,-1442 # 80011248 <uart_tx_lock>
    800007f2:	00000097          	auipc	ra,0x0
    800007f6:	6f6080e7          	jalr	1782(ra) # 80000ee8 <initlock>
}
    800007fa:	60a2                	ld	ra,8(sp)
    800007fc:	6402                	ld	s0,0(sp)
    800007fe:	0141                	addi	sp,sp,16
    80000800:	8082                	ret

0000000080000802 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    80000802:	1101                	addi	sp,sp,-32
    80000804:	ec06                	sd	ra,24(sp)
    80000806:	e822                	sd	s0,16(sp)
    80000808:	e426                	sd	s1,8(sp)
    8000080a:	1000                	addi	s0,sp,32
    8000080c:	84aa                	mv	s1,a0
  push_off();
    8000080e:	00000097          	auipc	ra,0x0
    80000812:	512080e7          	jalr	1298(ra) # 80000d20 <push_off>

  if(panicked){
    80000816:	00008797          	auipc	a5,0x8
    8000081a:	7ea7a783          	lw	a5,2026(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081e:	10000737          	lui	a4,0x10000
  if(panicked){
    80000822:	c391                	beqz	a5,80000826 <uartputc_sync+0x24>
    for(;;)
    80000824:	a001                	j	80000824 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000826:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000082a:	0ff7f793          	andi	a5,a5,255
    8000082e:	0207f793          	andi	a5,a5,32
    80000832:	dbf5                	beqz	a5,80000826 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000834:	0ff4f793          	andi	a5,s1,255
    80000838:	10000737          	lui	a4,0x10000
    8000083c:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000840:	00000097          	auipc	ra,0x0
    80000844:	59c080e7          	jalr	1436(ra) # 80000ddc <pop_off>
}
    80000848:	60e2                	ld	ra,24(sp)
    8000084a:	6442                	ld	s0,16(sp)
    8000084c:	64a2                	ld	s1,8(sp)
    8000084e:	6105                	addi	sp,sp,32
    80000850:	8082                	ret

0000000080000852 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000852:	00008797          	auipc	a5,0x8
    80000856:	7b27a783          	lw	a5,1970(a5) # 80009004 <uart_tx_r>
    8000085a:	00008717          	auipc	a4,0x8
    8000085e:	7ae72703          	lw	a4,1966(a4) # 80009008 <uart_tx_w>
    80000862:	08f70263          	beq	a4,a5,800008e6 <uartstart+0x94>
{
    80000866:	7139                	addi	sp,sp,-64
    80000868:	fc06                	sd	ra,56(sp)
    8000086a:	f822                	sd	s0,48(sp)
    8000086c:	f426                	sd	s1,40(sp)
    8000086e:	f04a                	sd	s2,32(sp)
    80000870:	ec4e                	sd	s3,24(sp)
    80000872:	e852                	sd	s4,16(sp)
    80000874:	e456                	sd	s5,8(sp)
    80000876:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000878:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    8000087c:	00011a17          	auipc	s4,0x11
    80000880:	9cca0a13          	addi	s4,s4,-1588 # 80011248 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    80000884:	00008497          	auipc	s1,0x8
    80000888:	78048493          	addi	s1,s1,1920 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000088c:	00008997          	auipc	s3,0x8
    80000890:	77c98993          	addi	s3,s3,1916 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000894:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000898:	0ff77713          	andi	a4,a4,255
    8000089c:	02077713          	andi	a4,a4,32
    800008a0:	cb15                	beqz	a4,800008d4 <uartstart+0x82>
    int c = uart_tx_buf[uart_tx_r];
    800008a2:	00fa0733          	add	a4,s4,a5
    800008a6:	02074a83          	lbu	s5,32(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    800008aa:	2785                	addiw	a5,a5,1
    800008ac:	41f7d71b          	sraiw	a4,a5,0x1f
    800008b0:	01b7571b          	srliw	a4,a4,0x1b
    800008b4:	9fb9                	addw	a5,a5,a4
    800008b6:	8bfd                	andi	a5,a5,31
    800008b8:	9f99                	subw	a5,a5,a4
    800008ba:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008bc:	8526                	mv	a0,s1
    800008be:	00002097          	auipc	ra,0x2
    800008c2:	e8c080e7          	jalr	-372(ra) # 8000274a <wakeup>
    
    WriteReg(THR, c);
    800008c6:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ca:	409c                	lw	a5,0(s1)
    800008cc:	0009a703          	lw	a4,0(s3)
    800008d0:	fcf712e3          	bne	a4,a5,80000894 <uartstart+0x42>
  }
}
    800008d4:	70e2                	ld	ra,56(sp)
    800008d6:	7442                	ld	s0,48(sp)
    800008d8:	74a2                	ld	s1,40(sp)
    800008da:	7902                	ld	s2,32(sp)
    800008dc:	69e2                	ld	s3,24(sp)
    800008de:	6a42                	ld	s4,16(sp)
    800008e0:	6aa2                	ld	s5,8(sp)
    800008e2:	6121                	addi	sp,sp,64
    800008e4:	8082                	ret
    800008e6:	8082                	ret

00000000800008e8 <uartputc>:
{
    800008e8:	7179                	addi	sp,sp,-48
    800008ea:	f406                	sd	ra,40(sp)
    800008ec:	f022                	sd	s0,32(sp)
    800008ee:	ec26                	sd	s1,24(sp)
    800008f0:	e84a                	sd	s2,16(sp)
    800008f2:	e44e                	sd	s3,8(sp)
    800008f4:	e052                	sd	s4,0(sp)
    800008f6:	1800                	addi	s0,sp,48
    800008f8:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008fa:	00011517          	auipc	a0,0x11
    800008fe:	94e50513          	addi	a0,a0,-1714 # 80011248 <uart_tx_lock>
    80000902:	00000097          	auipc	ra,0x0
    80000906:	46a080e7          	jalr	1130(ra) # 80000d6c <acquire>
  if(panicked){
    8000090a:	00008797          	auipc	a5,0x8
    8000090e:	6f67a783          	lw	a5,1782(a5) # 80009000 <panicked>
    80000912:	c391                	beqz	a5,80000916 <uartputc+0x2e>
    for(;;)
    80000914:	a001                	j	80000914 <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000916:	00008717          	auipc	a4,0x8
    8000091a:	6f272703          	lw	a4,1778(a4) # 80009008 <uart_tx_w>
    8000091e:	0017079b          	addiw	a5,a4,1
    80000922:	41f7d69b          	sraiw	a3,a5,0x1f
    80000926:	01b6d69b          	srliw	a3,a3,0x1b
    8000092a:	9fb5                	addw	a5,a5,a3
    8000092c:	8bfd                	andi	a5,a5,31
    8000092e:	9f95                	subw	a5,a5,a3
    80000930:	00008697          	auipc	a3,0x8
    80000934:	6d46a683          	lw	a3,1748(a3) # 80009004 <uart_tx_r>
    80000938:	04f69263          	bne	a3,a5,8000097c <uartputc+0x94>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000093c:	00011a17          	auipc	s4,0x11
    80000940:	90ca0a13          	addi	s4,s4,-1780 # 80011248 <uart_tx_lock>
    80000944:	00008497          	auipc	s1,0x8
    80000948:	6c048493          	addi	s1,s1,1728 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    8000094c:	00008917          	auipc	s2,0x8
    80000950:	6bc90913          	addi	s2,s2,1724 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000954:	85d2                	mv	a1,s4
    80000956:	8526                	mv	a0,s1
    80000958:	00002097          	auipc	ra,0x2
    8000095c:	c6c080e7          	jalr	-916(ra) # 800025c4 <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000960:	00092703          	lw	a4,0(s2)
    80000964:	0017079b          	addiw	a5,a4,1
    80000968:	41f7d69b          	sraiw	a3,a5,0x1f
    8000096c:	01b6d69b          	srliw	a3,a3,0x1b
    80000970:	9fb5                	addw	a5,a5,a3
    80000972:	8bfd                	andi	a5,a5,31
    80000974:	9f95                	subw	a5,a5,a3
    80000976:	4094                	lw	a3,0(s1)
    80000978:	fcf68ee3          	beq	a3,a5,80000954 <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    8000097c:	00011497          	auipc	s1,0x11
    80000980:	8cc48493          	addi	s1,s1,-1844 # 80011248 <uart_tx_lock>
    80000984:	9726                	add	a4,a4,s1
    80000986:	03370023          	sb	s3,32(a4)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    8000098a:	00008717          	auipc	a4,0x8
    8000098e:	66f72f23          	sw	a5,1662(a4) # 80009008 <uart_tx_w>
      uartstart();
    80000992:	00000097          	auipc	ra,0x0
    80000996:	ec0080e7          	jalr	-320(ra) # 80000852 <uartstart>
      release(&uart_tx_lock);
    8000099a:	8526                	mv	a0,s1
    8000099c:	00000097          	auipc	ra,0x0
    800009a0:	4a0080e7          	jalr	1184(ra) # 80000e3c <release>
}
    800009a4:	70a2                	ld	ra,40(sp)
    800009a6:	7402                	ld	s0,32(sp)
    800009a8:	64e2                	ld	s1,24(sp)
    800009aa:	6942                	ld	s2,16(sp)
    800009ac:	69a2                	ld	s3,8(sp)
    800009ae:	6a02                	ld	s4,0(sp)
    800009b0:	6145                	addi	sp,sp,48
    800009b2:	8082                	ret

00000000800009b4 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800009b4:	1141                	addi	sp,sp,-16
    800009b6:	e422                	sd	s0,8(sp)
    800009b8:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009ba:	100007b7          	lui	a5,0x10000
    800009be:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009c2:	8b85                	andi	a5,a5,1
    800009c4:	cb91                	beqz	a5,800009d8 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    800009c6:	100007b7          	lui	a5,0x10000
    800009ca:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009ce:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009d2:	6422                	ld	s0,8(sp)
    800009d4:	0141                	addi	sp,sp,16
    800009d6:	8082                	ret
    return -1;
    800009d8:	557d                	li	a0,-1
    800009da:	bfe5                	j	800009d2 <uartgetc+0x1e>

00000000800009dc <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009dc:	1101                	addi	sp,sp,-32
    800009de:	ec06                	sd	ra,24(sp)
    800009e0:	e822                	sd	s0,16(sp)
    800009e2:	e426                	sd	s1,8(sp)
    800009e4:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009e6:	54fd                	li	s1,-1
    int c = uartgetc();
    800009e8:	00000097          	auipc	ra,0x0
    800009ec:	fcc080e7          	jalr	-52(ra) # 800009b4 <uartgetc>
    if(c == -1)
    800009f0:	00950763          	beq	a0,s1,800009fe <uartintr+0x22>
      break;
    consoleintr(c);
    800009f4:	00000097          	auipc	ra,0x0
    800009f8:	8dc080e7          	jalr	-1828(ra) # 800002d0 <consoleintr>
  while(1){
    800009fc:	b7f5                	j	800009e8 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009fe:	00011497          	auipc	s1,0x11
    80000a02:	84a48493          	addi	s1,s1,-1974 # 80011248 <uart_tx_lock>
    80000a06:	8526                	mv	a0,s1
    80000a08:	00000097          	auipc	ra,0x0
    80000a0c:	364080e7          	jalr	868(ra) # 80000d6c <acquire>
  uartstart();
    80000a10:	00000097          	auipc	ra,0x0
    80000a14:	e42080e7          	jalr	-446(ra) # 80000852 <uartstart>
  release(&uart_tx_lock);
    80000a18:	8526                	mv	a0,s1
    80000a1a:	00000097          	auipc	ra,0x0
    80000a1e:	422080e7          	jalr	1058(ra) # 80000e3c <release>
}
    80000a22:	60e2                	ld	ra,24(sp)
    80000a24:	6442                	ld	s0,16(sp)
    80000a26:	64a2                	ld	s1,8(sp)
    80000a28:	6105                	addi	sp,sp,32
    80000a2a:	8082                	ret

0000000080000a2c <kfree>:
*/

//释放pa块
void
kfree(void *pa)
{
    80000a2c:	7139                	addi	sp,sp,-64
    80000a2e:	fc06                	sd	ra,56(sp)
    80000a30:	f822                	sd	s0,48(sp)
    80000a32:	f426                	sd	s1,40(sp)
    80000a34:	f04a                	sd	s2,32(sp)
    80000a36:	ec4e                	sd	s3,24(sp)
    80000a38:	e852                	sd	s4,16(sp)
    80000a3a:	e456                	sd	s5,8(sp)
    80000a3c:	0080                	addi	s0,sp,64
  //新的空闲链表
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a3e:	03451793          	slli	a5,a0,0x34
    80000a42:	e3c9                	bnez	a5,80000ac4 <kfree+0x98>
    80000a44:	84aa                	mv	s1,a0
    80000a46:	0002b797          	auipc	a5,0x2b
    80000a4a:	5e278793          	addi	a5,a5,1506 # 8002c028 <end>
    80000a4e:	06f56b63          	bltu	a0,a5,80000ac4 <kfree+0x98>
    80000a52:	47c5                	li	a5,17
    80000a54:	07ee                	slli	a5,a5,0x1b
    80000a56:	06f57763          	bgeu	a0,a5,80000ac4 <kfree+0x98>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a5a:	6605                	lui	a2,0x1
    80000a5c:	4585                	li	a1,1
    80000a5e:	00000097          	auipc	ra,0x0
    80000a62:	6ee080e7          	jalr	1774(ra) # 8000114c <memset>

  r = (struct run*)pa;

  //获取当前内核id
  push_off();
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	2ba080e7          	jalr	698(ra) # 80000d20 <push_off>
  int currentid=cpuid();
    80000a6e:	00001097          	auipc	ra,0x1
    80000a72:	31a080e7          	jalr	794(ra) # 80001d88 <cpuid>
    80000a76:	8a2a                	mv	s4,a0
  pop_off();
    80000a78:	00000097          	auipc	ra,0x0
    80000a7c:	364080e7          	jalr	868(ra) # 80000ddc <pop_off>

  acquire(&kmems[currentid].lock);
    80000a80:	00011a97          	auipc	s5,0x11
    80000a84:	808a8a93          	addi	s5,s5,-2040 # 80011288 <kmems>
    80000a88:	002a1993          	slli	s3,s4,0x2
    80000a8c:	01498933          	add	s2,s3,s4
    80000a90:	090e                	slli	s2,s2,0x3
    80000a92:	9956                	add	s2,s2,s5
    80000a94:	854a                	mv	a0,s2
    80000a96:	00000097          	auipc	ra,0x0
    80000a9a:	2d6080e7          	jalr	726(ra) # 80000d6c <acquire>
  r->next = kmems[currentid].freelist;
    80000a9e:	02093783          	ld	a5,32(s2)
    80000aa2:	e09c                	sd	a5,0(s1)
  kmems[currentid].freelist = r;
    80000aa4:	02993023          	sd	s1,32(s2)
  release(&kmems[currentid].lock);
    80000aa8:	854a                	mv	a0,s2
    80000aaa:	00000097          	auipc	ra,0x0
    80000aae:	392080e7          	jalr	914(ra) # 80000e3c <release>

}
    80000ab2:	70e2                	ld	ra,56(sp)
    80000ab4:	7442                	ld	s0,48(sp)
    80000ab6:	74a2                	ld	s1,40(sp)
    80000ab8:	7902                	ld	s2,32(sp)
    80000aba:	69e2                	ld	s3,24(sp)
    80000abc:	6a42                	ld	s4,16(sp)
    80000abe:	6aa2                	ld	s5,8(sp)
    80000ac0:	6121                	addi	sp,sp,64
    80000ac2:	8082                	ret
    panic("kfree");
    80000ac4:	00007517          	auipc	a0,0x7
    80000ac8:	59c50513          	addi	a0,a0,1436 # 80008060 <digits+0x20>
    80000acc:	00000097          	auipc	ra,0x0
    80000ad0:	a84080e7          	jalr	-1404(ra) # 80000550 <panic>

0000000080000ad4 <freerange>:
{
    80000ad4:	7179                	addi	sp,sp,-48
    80000ad6:	f406                	sd	ra,40(sp)
    80000ad8:	f022                	sd	s0,32(sp)
    80000ada:	ec26                	sd	s1,24(sp)
    80000adc:	e84a                	sd	s2,16(sp)
    80000ade:	e44e                	sd	s3,8(sp)
    80000ae0:	e052                	sd	s4,0(sp)
    80000ae2:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000ae4:	6785                	lui	a5,0x1
    80000ae6:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000aea:	94aa                	add	s1,s1,a0
    80000aec:	757d                	lui	a0,0xfffff
    80000aee:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000af0:	94be                	add	s1,s1,a5
    80000af2:	0095ee63          	bltu	a1,s1,80000b0e <freerange+0x3a>
    80000af6:	892e                	mv	s2,a1
    kfree(p);
    80000af8:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000afa:	6985                	lui	s3,0x1
    kfree(p);
    80000afc:	01448533          	add	a0,s1,s4
    80000b00:	00000097          	auipc	ra,0x0
    80000b04:	f2c080e7          	jalr	-212(ra) # 80000a2c <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b08:	94ce                	add	s1,s1,s3
    80000b0a:	fe9979e3          	bgeu	s2,s1,80000afc <freerange+0x28>
}
    80000b0e:	70a2                	ld	ra,40(sp)
    80000b10:	7402                	ld	s0,32(sp)
    80000b12:	64e2                	ld	s1,24(sp)
    80000b14:	6942                	ld	s2,16(sp)
    80000b16:	69a2                	ld	s3,8(sp)
    80000b18:	6a02                	ld	s4,0(sp)
    80000b1a:	6145                	addi	sp,sp,48
    80000b1c:	8082                	ret

0000000080000b1e <kinit>:
{
    80000b1e:	7179                	addi	sp,sp,-48
    80000b20:	f406                	sd	ra,40(sp)
    80000b22:	f022                	sd	s0,32(sp)
    80000b24:	ec26                	sd	s1,24(sp)
    80000b26:	e84a                	sd	s2,16(sp)
    80000b28:	e44e                	sd	s3,8(sp)
    80000b2a:	1800                	addi	s0,sp,48
  for(int i=0;i<NCPU;i++)
    80000b2c:	00010497          	auipc	s1,0x10
    80000b30:	75c48493          	addi	s1,s1,1884 # 80011288 <kmems>
    80000b34:	00011997          	auipc	s3,0x11
    80000b38:	89498993          	addi	s3,s3,-1900 # 800113c8 <lock_locks>
    initlock(&kmems[i].lock,"kmem");
    80000b3c:	00007917          	auipc	s2,0x7
    80000b40:	52c90913          	addi	s2,s2,1324 # 80008068 <digits+0x28>
    80000b44:	85ca                	mv	a1,s2
    80000b46:	8526                	mv	a0,s1
    80000b48:	00000097          	auipc	ra,0x0
    80000b4c:	3a0080e7          	jalr	928(ra) # 80000ee8 <initlock>
  for(int i=0;i<NCPU;i++)
    80000b50:	02848493          	addi	s1,s1,40
    80000b54:	ff3498e3          	bne	s1,s3,80000b44 <kinit+0x26>
  freerange(end,(void*)PHYSTOP);
    80000b58:	45c5                	li	a1,17
    80000b5a:	05ee                	slli	a1,a1,0x1b
    80000b5c:	0002b517          	auipc	a0,0x2b
    80000b60:	4cc50513          	addi	a0,a0,1228 # 8002c028 <end>
    80000b64:	00000097          	auipc	ra,0x0
    80000b68:	f70080e7          	jalr	-144(ra) # 80000ad4 <freerange>
}
    80000b6c:	70a2                	ld	ra,40(sp)
    80000b6e:	7402                	ld	s0,32(sp)
    80000b70:	64e2                	ld	s1,24(sp)
    80000b72:	6942                	ld	s2,16(sp)
    80000b74:	69a2                	ld	s3,8(sp)
    80000b76:	6145                	addi	sp,sp,48
    80000b78:	8082                	ret

0000000080000b7a <popr>:
  return (void*)r;
}

struct run *
popr(int id)
{
    80000b7a:	1141                	addi	sp,sp,-16
    80000b7c:	e422                	sd	s0,8(sp)
    80000b7e:	0800                	addi	s0,sp,16
    80000b80:	87aa                	mv	a5,a0
  struct run *r;
  r =kmems[id].freelist;
    80000b82:	00251713          	slli	a4,a0,0x2
    80000b86:	972a                	add	a4,a4,a0
    80000b88:	070e                	slli	a4,a4,0x3
    80000b8a:	00010697          	auipc	a3,0x10
    80000b8e:	6fe68693          	addi	a3,a3,1790 # 80011288 <kmems>
    80000b92:	9736                	add	a4,a4,a3
    80000b94:	7308                	ld	a0,32(a4)
  if(r)
    80000b96:	cd01                	beqz	a0,80000bae <popr+0x34>
    kmems[id].freelist=r->next;
    80000b98:	6114                	ld	a3,0(a0)
    80000b9a:	00279713          	slli	a4,a5,0x2
    80000b9e:	97ba                	add	a5,a5,a4
    80000ba0:	078e                	slli	a5,a5,0x3
    80000ba2:	00010717          	auipc	a4,0x10
    80000ba6:	6e670713          	addi	a4,a4,1766 # 80011288 <kmems>
    80000baa:	97ba                	add	a5,a5,a4
    80000bac:	f394                	sd	a3,32(a5)
  return r;
}
    80000bae:	6422                	ld	s0,8(sp)
    80000bb0:	0141                	addi	sp,sp,16
    80000bb2:	8082                	ret

0000000080000bb4 <pushr>:

void 
pushr(int id, struct run *r)
{
  if(r){
    80000bb4:	c195                	beqz	a1,80000bd8 <pushr+0x24>
    r->next=kmems[id].freelist;
    80000bb6:	00010697          	auipc	a3,0x10
    80000bba:	6d268693          	addi	a3,a3,1746 # 80011288 <kmems>
    80000bbe:	00251793          	slli	a5,a0,0x2
    80000bc2:	00a78733          	add	a4,a5,a0
    80000bc6:	070e                	slli	a4,a4,0x3
    80000bc8:	9736                	add	a4,a4,a3
    80000bca:	7318                	ld	a4,32(a4)
    80000bcc:	e198                	sd	a4,0(a1)
    kmems[id].freelist = r;
    80000bce:	97aa                	add	a5,a5,a0
    80000bd0:	078e                	slli	a5,a5,0x3
    80000bd2:	97b6                	add	a5,a5,a3
    80000bd4:	f38c                	sd	a1,32(a5)
    80000bd6:	8082                	ret
{
    80000bd8:	1141                	addi	sp,sp,-16
    80000bda:	e406                	sd	ra,8(sp)
    80000bdc:	e022                	sd	s0,0(sp)
    80000bde:	0800                	addi	s0,sp,16
  }
  else{
    panic("cannot push null run");
    80000be0:	00007517          	auipc	a0,0x7
    80000be4:	49050513          	addi	a0,a0,1168 # 80008070 <digits+0x30>
    80000be8:	00000097          	auipc	ra,0x0
    80000bec:	968080e7          	jalr	-1688(ra) # 80000550 <panic>

0000000080000bf0 <kalloc>:
{
    80000bf0:	7179                	addi	sp,sp,-48
    80000bf2:	f406                	sd	ra,40(sp)
    80000bf4:	f022                	sd	s0,32(sp)
    80000bf6:	ec26                	sd	s1,24(sp)
    80000bf8:	e84a                	sd	s2,16(sp)
    80000bfa:	e44e                	sd	s3,8(sp)
    80000bfc:	e052                	sd	s4,0(sp)
    80000bfe:	1800                	addi	s0,sp,48
  push_off();
    80000c00:	00000097          	auipc	ra,0x0
    80000c04:	120080e7          	jalr	288(ra) # 80000d20 <push_off>
  int currentid = cpuid();
    80000c08:	00001097          	auipc	ra,0x1
    80000c0c:	180080e7          	jalr	384(ra) # 80001d88 <cpuid>
    80000c10:	84aa                	mv	s1,a0
  pop_off();
    80000c12:	00000097          	auipc	ra,0x0
    80000c16:	1ca080e7          	jalr	458(ra) # 80000ddc <pop_off>
  acquire(&kmems[currentid].lock);
    80000c1a:	00249793          	slli	a5,s1,0x2
    80000c1e:	97a6                	add	a5,a5,s1
    80000c20:	078e                	slli	a5,a5,0x3
    80000c22:	00010a17          	auipc	s4,0x10
    80000c26:	666a0a13          	addi	s4,s4,1638 # 80011288 <kmems>
    80000c2a:	9a3e                	add	s4,s4,a5
    80000c2c:	8552                	mv	a0,s4
    80000c2e:	00000097          	auipc	ra,0x0
    80000c32:	13e080e7          	jalr	318(ra) # 80000d6c <acquire>
  r = popr(currentid);//返回值为原列表
    80000c36:	8526                	mv	a0,s1
    80000c38:	00000097          	auipc	ra,0x0
    80000c3c:	f42080e7          	jalr	-190(ra) # 80000b7a <popr>
    80000c40:	89aa                	mv	s3,a0
  if(!r)//原列表是空的
    80000c42:	c515                	beqz	a0,80000c6e <kalloc+0x7e>
  release(&kmems[currentid].lock);
    80000c44:	8552                	mv	a0,s4
    80000c46:	00000097          	auipc	ra,0x0
    80000c4a:	1f6080e7          	jalr	502(ra) # 80000e3c <release>
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000c4e:	6605                	lui	a2,0x1
    80000c50:	4595                	li	a1,5
    80000c52:	854e                	mv	a0,s3
    80000c54:	00000097          	auipc	ra,0x0
    80000c58:	4f8080e7          	jalr	1272(ra) # 8000114c <memset>
}
    80000c5c:	854e                	mv	a0,s3
    80000c5e:	70a2                	ld	ra,40(sp)
    80000c60:	7402                	ld	s0,32(sp)
    80000c62:	64e2                	ld	s1,24(sp)
    80000c64:	6942                	ld	s2,16(sp)
    80000c66:	69a2                	ld	s3,8(sp)
    80000c68:	6a02                	ld	s4,0(sp)
    80000c6a:	6145                	addi	sp,sp,48
    80000c6c:	8082                	ret
    80000c6e:	00010797          	auipc	a5,0x10
    80000c72:	61a78793          	addi	a5,a5,1562 # 80011288 <kmems>
    for(int id=0;id<NCPU;id++)
    80000c76:	4901                	li	s2,0
    80000c78:	46a1                	li	a3,8
    80000c7a:	a031                	j	80000c86 <kalloc+0x96>
    80000c7c:	2905                	addiw	s2,s2,1
    80000c7e:	02878793          	addi	a5,a5,40
    80000c82:	06d90263          	beq	s2,a3,80000ce6 <kalloc+0xf6>
      if(id==currentid)continue;
    80000c86:	ff248be3          	beq	s1,s2,80000c7c <kalloc+0x8c>
      if(kmems[id].freelist)//有空闲块
    80000c8a:	7398                	ld	a4,32(a5)
    80000c8c:	db65                	beqz	a4,80000c7c <kalloc+0x8c>
        acquire(&kmems[id].lock);
    80000c8e:	00291793          	slli	a5,s2,0x2
    80000c92:	97ca                	add	a5,a5,s2
    80000c94:	078e                	slli	a5,a5,0x3
    80000c96:	00010997          	auipc	s3,0x10
    80000c9a:	5f298993          	addi	s3,s3,1522 # 80011288 <kmems>
    80000c9e:	99be                	add	s3,s3,a5
    80000ca0:	854e                	mv	a0,s3
    80000ca2:	00000097          	auipc	ra,0x0
    80000ca6:	0ca080e7          	jalr	202(ra) # 80000d6c <acquire>
        r=popr(id);
    80000caa:	854a                	mv	a0,s2
    80000cac:	00000097          	auipc	ra,0x0
    80000cb0:	ece080e7          	jalr	-306(ra) # 80000b7a <popr>
    80000cb4:	85aa                	mv	a1,a0
        pushr(currentid,r);
    80000cb6:	8526                	mv	a0,s1
    80000cb8:	00000097          	auipc	ra,0x0
    80000cbc:	efc080e7          	jalr	-260(ra) # 80000bb4 <pushr>
        release(&kmems[id].lock);
    80000cc0:	854e                	mv	a0,s3
    80000cc2:	00000097          	auipc	ra,0x0
    80000cc6:	17a080e7          	jalr	378(ra) # 80000e3c <release>
    r=popr(currentid);
    80000cca:	8526                	mv	a0,s1
    80000ccc:	00000097          	auipc	ra,0x0
    80000cd0:	eae080e7          	jalr	-338(ra) # 80000b7a <popr>
    80000cd4:	89aa                	mv	s3,a0
  release(&kmems[currentid].lock);
    80000cd6:	8552                	mv	a0,s4
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	164080e7          	jalr	356(ra) # 80000e3c <release>
  if(r)
    80000ce0:	f6098ee3          	beqz	s3,80000c5c <kalloc+0x6c>
    80000ce4:	b7ad                	j	80000c4e <kalloc+0x5e>
  release(&kmems[currentid].lock);
    80000ce6:	8552                	mv	a0,s4
    80000ce8:	00000097          	auipc	ra,0x0
    80000cec:	154080e7          	jalr	340(ra) # 80000e3c <release>
  if(r)
    80000cf0:	b7b5                	j	80000c5c <kalloc+0x6c>

0000000080000cf2 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000cf2:	411c                	lw	a5,0(a0)
    80000cf4:	e399                	bnez	a5,80000cfa <holding+0x8>
    80000cf6:	4501                	li	a0,0
  return r;
}
    80000cf8:	8082                	ret
{
    80000cfa:	1101                	addi	sp,sp,-32
    80000cfc:	ec06                	sd	ra,24(sp)
    80000cfe:	e822                	sd	s0,16(sp)
    80000d00:	e426                	sd	s1,8(sp)
    80000d02:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000d04:	6904                	ld	s1,16(a0)
    80000d06:	00001097          	auipc	ra,0x1
    80000d0a:	092080e7          	jalr	146(ra) # 80001d98 <mycpu>
    80000d0e:	40a48533          	sub	a0,s1,a0
    80000d12:	00153513          	seqz	a0,a0
}
    80000d16:	60e2                	ld	ra,24(sp)
    80000d18:	6442                	ld	s0,16(sp)
    80000d1a:	64a2                	ld	s1,8(sp)
    80000d1c:	6105                	addi	sp,sp,32
    80000d1e:	8082                	ret

0000000080000d20 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000d20:	1101                	addi	sp,sp,-32
    80000d22:	ec06                	sd	ra,24(sp)
    80000d24:	e822                	sd	s0,16(sp)
    80000d26:	e426                	sd	s1,8(sp)
    80000d28:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d2a:	100024f3          	csrr	s1,sstatus
    80000d2e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000d32:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d34:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000d38:	00001097          	auipc	ra,0x1
    80000d3c:	060080e7          	jalr	96(ra) # 80001d98 <mycpu>
    80000d40:	5d3c                	lw	a5,120(a0)
    80000d42:	cf89                	beqz	a5,80000d5c <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000d44:	00001097          	auipc	ra,0x1
    80000d48:	054080e7          	jalr	84(ra) # 80001d98 <mycpu>
    80000d4c:	5d3c                	lw	a5,120(a0)
    80000d4e:	2785                	addiw	a5,a5,1
    80000d50:	dd3c                	sw	a5,120(a0)
}
    80000d52:	60e2                	ld	ra,24(sp)
    80000d54:	6442                	ld	s0,16(sp)
    80000d56:	64a2                	ld	s1,8(sp)
    80000d58:	6105                	addi	sp,sp,32
    80000d5a:	8082                	ret
    mycpu()->intena = old;
    80000d5c:	00001097          	auipc	ra,0x1
    80000d60:	03c080e7          	jalr	60(ra) # 80001d98 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000d64:	8085                	srli	s1,s1,0x1
    80000d66:	8885                	andi	s1,s1,1
    80000d68:	dd64                	sw	s1,124(a0)
    80000d6a:	bfe9                	j	80000d44 <push_off+0x24>

0000000080000d6c <acquire>:
{
    80000d6c:	1101                	addi	sp,sp,-32
    80000d6e:	ec06                	sd	ra,24(sp)
    80000d70:	e822                	sd	s0,16(sp)
    80000d72:	e426                	sd	s1,8(sp)
    80000d74:	1000                	addi	s0,sp,32
    80000d76:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000d78:	00000097          	auipc	ra,0x0
    80000d7c:	fa8080e7          	jalr	-88(ra) # 80000d20 <push_off>
  if(holding(lk))
    80000d80:	8526                	mv	a0,s1
    80000d82:	00000097          	auipc	ra,0x0
    80000d86:	f70080e7          	jalr	-144(ra) # 80000cf2 <holding>
    80000d8a:	e911                	bnez	a0,80000d9e <acquire+0x32>
    __sync_fetch_and_add(&(lk->n), 1);
    80000d8c:	4785                	li	a5,1
    80000d8e:	01c48713          	addi	a4,s1,28
    80000d92:	0f50000f          	fence	iorw,ow
    80000d96:	04f7202f          	amoadd.w.aq	zero,a5,(a4)
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0) {
    80000d9a:	4705                	li	a4,1
    80000d9c:	a839                	j	80000dba <acquire+0x4e>
    panic("acquire");
    80000d9e:	00007517          	auipc	a0,0x7
    80000da2:	2ea50513          	addi	a0,a0,746 # 80008088 <digits+0x48>
    80000da6:	fffff097          	auipc	ra,0xfffff
    80000daa:	7aa080e7          	jalr	1962(ra) # 80000550 <panic>
    __sync_fetch_and_add(&(lk->nts), 1);
    80000dae:	01848793          	addi	a5,s1,24
    80000db2:	0f50000f          	fence	iorw,ow
    80000db6:	04e7a02f          	amoadd.w.aq	zero,a4,(a5)
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0) {
    80000dba:	87ba                	mv	a5,a4
    80000dbc:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000dc0:	2781                	sext.w	a5,a5
    80000dc2:	f7f5                	bnez	a5,80000dae <acquire+0x42>
  __sync_synchronize();
    80000dc4:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000dc8:	00001097          	auipc	ra,0x1
    80000dcc:	fd0080e7          	jalr	-48(ra) # 80001d98 <mycpu>
    80000dd0:	e888                	sd	a0,16(s1)
}
    80000dd2:	60e2                	ld	ra,24(sp)
    80000dd4:	6442                	ld	s0,16(sp)
    80000dd6:	64a2                	ld	s1,8(sp)
    80000dd8:	6105                	addi	sp,sp,32
    80000dda:	8082                	ret

0000000080000ddc <pop_off>:

void
pop_off(void)
{
    80000ddc:	1141                	addi	sp,sp,-16
    80000dde:	e406                	sd	ra,8(sp)
    80000de0:	e022                	sd	s0,0(sp)
    80000de2:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000de4:	00001097          	auipc	ra,0x1
    80000de8:	fb4080e7          	jalr	-76(ra) # 80001d98 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000dec:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000df0:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000df2:	e78d                	bnez	a5,80000e1c <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000df4:	5d3c                	lw	a5,120(a0)
    80000df6:	02f05b63          	blez	a5,80000e2c <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000dfa:	37fd                	addiw	a5,a5,-1
    80000dfc:	0007871b          	sext.w	a4,a5
    80000e00:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000e02:	eb09                	bnez	a4,80000e14 <pop_off+0x38>
    80000e04:	5d7c                	lw	a5,124(a0)
    80000e06:	c799                	beqz	a5,80000e14 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000e08:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000e0c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000e10:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000e14:	60a2                	ld	ra,8(sp)
    80000e16:	6402                	ld	s0,0(sp)
    80000e18:	0141                	addi	sp,sp,16
    80000e1a:	8082                	ret
    panic("pop_off - interruptible");
    80000e1c:	00007517          	auipc	a0,0x7
    80000e20:	27450513          	addi	a0,a0,628 # 80008090 <digits+0x50>
    80000e24:	fffff097          	auipc	ra,0xfffff
    80000e28:	72c080e7          	jalr	1836(ra) # 80000550 <panic>
    panic("pop_off");
    80000e2c:	00007517          	auipc	a0,0x7
    80000e30:	27c50513          	addi	a0,a0,636 # 800080a8 <digits+0x68>
    80000e34:	fffff097          	auipc	ra,0xfffff
    80000e38:	71c080e7          	jalr	1820(ra) # 80000550 <panic>

0000000080000e3c <release>:
{
    80000e3c:	1101                	addi	sp,sp,-32
    80000e3e:	ec06                	sd	ra,24(sp)
    80000e40:	e822                	sd	s0,16(sp)
    80000e42:	e426                	sd	s1,8(sp)
    80000e44:	1000                	addi	s0,sp,32
    80000e46:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000e48:	00000097          	auipc	ra,0x0
    80000e4c:	eaa080e7          	jalr	-342(ra) # 80000cf2 <holding>
    80000e50:	c115                	beqz	a0,80000e74 <release+0x38>
  lk->cpu = 0;
    80000e52:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000e56:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000e5a:	0f50000f          	fence	iorw,ow
    80000e5e:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000e62:	00000097          	auipc	ra,0x0
    80000e66:	f7a080e7          	jalr	-134(ra) # 80000ddc <pop_off>
}
    80000e6a:	60e2                	ld	ra,24(sp)
    80000e6c:	6442                	ld	s0,16(sp)
    80000e6e:	64a2                	ld	s1,8(sp)
    80000e70:	6105                	addi	sp,sp,32
    80000e72:	8082                	ret
    panic("release");
    80000e74:	00007517          	auipc	a0,0x7
    80000e78:	23c50513          	addi	a0,a0,572 # 800080b0 <digits+0x70>
    80000e7c:	fffff097          	auipc	ra,0xfffff
    80000e80:	6d4080e7          	jalr	1748(ra) # 80000550 <panic>

0000000080000e84 <freelock>:
{
    80000e84:	1101                	addi	sp,sp,-32
    80000e86:	ec06                	sd	ra,24(sp)
    80000e88:	e822                	sd	s0,16(sp)
    80000e8a:	e426                	sd	s1,8(sp)
    80000e8c:	1000                	addi	s0,sp,32
    80000e8e:	84aa                	mv	s1,a0
  acquire(&lock_locks);
    80000e90:	00010517          	auipc	a0,0x10
    80000e94:	53850513          	addi	a0,a0,1336 # 800113c8 <lock_locks>
    80000e98:	00000097          	auipc	ra,0x0
    80000e9c:	ed4080e7          	jalr	-300(ra) # 80000d6c <acquire>
  for (i = 0; i < NLOCK; i++) {
    80000ea0:	00010717          	auipc	a4,0x10
    80000ea4:	54870713          	addi	a4,a4,1352 # 800113e8 <locks>
    80000ea8:	4781                	li	a5,0
    80000eaa:	1f400613          	li	a2,500
    if(locks[i] == lk) {
    80000eae:	6314                	ld	a3,0(a4)
    80000eb0:	00968763          	beq	a3,s1,80000ebe <freelock+0x3a>
  for (i = 0; i < NLOCK; i++) {
    80000eb4:	2785                	addiw	a5,a5,1
    80000eb6:	0721                	addi	a4,a4,8
    80000eb8:	fec79be3          	bne	a5,a2,80000eae <freelock+0x2a>
    80000ebc:	a809                	j	80000ece <freelock+0x4a>
      locks[i] = 0;
    80000ebe:	078e                	slli	a5,a5,0x3
    80000ec0:	00010717          	auipc	a4,0x10
    80000ec4:	52870713          	addi	a4,a4,1320 # 800113e8 <locks>
    80000ec8:	97ba                	add	a5,a5,a4
    80000eca:	0007b023          	sd	zero,0(a5)
  release(&lock_locks);
    80000ece:	00010517          	auipc	a0,0x10
    80000ed2:	4fa50513          	addi	a0,a0,1274 # 800113c8 <lock_locks>
    80000ed6:	00000097          	auipc	ra,0x0
    80000eda:	f66080e7          	jalr	-154(ra) # 80000e3c <release>
}
    80000ede:	60e2                	ld	ra,24(sp)
    80000ee0:	6442                	ld	s0,16(sp)
    80000ee2:	64a2                	ld	s1,8(sp)
    80000ee4:	6105                	addi	sp,sp,32
    80000ee6:	8082                	ret

0000000080000ee8 <initlock>:
{
    80000ee8:	1101                	addi	sp,sp,-32
    80000eea:	ec06                	sd	ra,24(sp)
    80000eec:	e822                	sd	s0,16(sp)
    80000eee:	e426                	sd	s1,8(sp)
    80000ef0:	1000                	addi	s0,sp,32
    80000ef2:	84aa                	mv	s1,a0
  lk->name = name;
    80000ef4:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000ef6:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000efa:	00053823          	sd	zero,16(a0)
  lk->nts = 0;
    80000efe:	00052c23          	sw	zero,24(a0)
  lk->n = 0;
    80000f02:	00052e23          	sw	zero,28(a0)
  acquire(&lock_locks);
    80000f06:	00010517          	auipc	a0,0x10
    80000f0a:	4c250513          	addi	a0,a0,1218 # 800113c8 <lock_locks>
    80000f0e:	00000097          	auipc	ra,0x0
    80000f12:	e5e080e7          	jalr	-418(ra) # 80000d6c <acquire>
  for (i = 0; i < NLOCK; i++) {
    80000f16:	00010717          	auipc	a4,0x10
    80000f1a:	4d270713          	addi	a4,a4,1234 # 800113e8 <locks>
    80000f1e:	4781                	li	a5,0
    80000f20:	1f400693          	li	a3,500
    if(locks[i] == 0) {
    80000f24:	6310                	ld	a2,0(a4)
    80000f26:	ce09                	beqz	a2,80000f40 <initlock+0x58>
  for (i = 0; i < NLOCK; i++) {
    80000f28:	2785                	addiw	a5,a5,1
    80000f2a:	0721                	addi	a4,a4,8
    80000f2c:	fed79ce3          	bne	a5,a3,80000f24 <initlock+0x3c>
  panic("findslot");
    80000f30:	00007517          	auipc	a0,0x7
    80000f34:	18850513          	addi	a0,a0,392 # 800080b8 <digits+0x78>
    80000f38:	fffff097          	auipc	ra,0xfffff
    80000f3c:	618080e7          	jalr	1560(ra) # 80000550 <panic>
      locks[i] = lk;
    80000f40:	078e                	slli	a5,a5,0x3
    80000f42:	00010717          	auipc	a4,0x10
    80000f46:	4a670713          	addi	a4,a4,1190 # 800113e8 <locks>
    80000f4a:	97ba                	add	a5,a5,a4
    80000f4c:	e384                	sd	s1,0(a5)
      release(&lock_locks);
    80000f4e:	00010517          	auipc	a0,0x10
    80000f52:	47a50513          	addi	a0,a0,1146 # 800113c8 <lock_locks>
    80000f56:	00000097          	auipc	ra,0x0
    80000f5a:	ee6080e7          	jalr	-282(ra) # 80000e3c <release>
}
    80000f5e:	60e2                	ld	ra,24(sp)
    80000f60:	6442                	ld	s0,16(sp)
    80000f62:	64a2                	ld	s1,8(sp)
    80000f64:	6105                	addi	sp,sp,32
    80000f66:	8082                	ret

0000000080000f68 <snprint_lock>:
#ifdef LAB_LOCK
int
snprint_lock(char *buf, int sz, struct spinlock *lk)
{
  int n = 0;
  if(lk->n > 0) {
    80000f68:	4e5c                	lw	a5,28(a2)
    80000f6a:	00f04463          	bgtz	a5,80000f72 <snprint_lock+0xa>
  int n = 0;
    80000f6e:	4501                	li	a0,0
    n = snprintf(buf, sz, "lock: %s: #fetch-and-add %d #acquire() %d\n",
                 lk->name, lk->nts, lk->n);
  }
  return n;
}
    80000f70:	8082                	ret
{
    80000f72:	1141                	addi	sp,sp,-16
    80000f74:	e406                	sd	ra,8(sp)
    80000f76:	e022                	sd	s0,0(sp)
    80000f78:	0800                	addi	s0,sp,16
    n = snprintf(buf, sz, "lock: %s: #fetch-and-add %d #acquire() %d\n",
    80000f7a:	4e18                	lw	a4,24(a2)
    80000f7c:	6614                	ld	a3,8(a2)
    80000f7e:	00007617          	auipc	a2,0x7
    80000f82:	14a60613          	addi	a2,a2,330 # 800080c8 <digits+0x88>
    80000f86:	00006097          	auipc	ra,0x6
    80000f8a:	99c080e7          	jalr	-1636(ra) # 80006922 <snprintf>
}
    80000f8e:	60a2                	ld	ra,8(sp)
    80000f90:	6402                	ld	s0,0(sp)
    80000f92:	0141                	addi	sp,sp,16
    80000f94:	8082                	ret

0000000080000f96 <statslock>:

int
statslock(char *buf, int sz) {
    80000f96:	7159                	addi	sp,sp,-112
    80000f98:	f486                	sd	ra,104(sp)
    80000f9a:	f0a2                	sd	s0,96(sp)
    80000f9c:	eca6                	sd	s1,88(sp)
    80000f9e:	e8ca                	sd	s2,80(sp)
    80000fa0:	e4ce                	sd	s3,72(sp)
    80000fa2:	e0d2                	sd	s4,64(sp)
    80000fa4:	fc56                	sd	s5,56(sp)
    80000fa6:	f85a                	sd	s6,48(sp)
    80000fa8:	f45e                	sd	s7,40(sp)
    80000faa:	f062                	sd	s8,32(sp)
    80000fac:	ec66                	sd	s9,24(sp)
    80000fae:	e86a                	sd	s10,16(sp)
    80000fb0:	e46e                	sd	s11,8(sp)
    80000fb2:	1880                	addi	s0,sp,112
    80000fb4:	8aaa                	mv	s5,a0
    80000fb6:	8b2e                	mv	s6,a1
  int n;
  int tot = 0;

  acquire(&lock_locks);
    80000fb8:	00010517          	auipc	a0,0x10
    80000fbc:	41050513          	addi	a0,a0,1040 # 800113c8 <lock_locks>
    80000fc0:	00000097          	auipc	ra,0x0
    80000fc4:	dac080e7          	jalr	-596(ra) # 80000d6c <acquire>
  n = snprintf(buf, sz, "--- lock kmem/bcache stats\n");
    80000fc8:	00007617          	auipc	a2,0x7
    80000fcc:	13060613          	addi	a2,a2,304 # 800080f8 <digits+0xb8>
    80000fd0:	85da                	mv	a1,s6
    80000fd2:	8556                	mv	a0,s5
    80000fd4:	00006097          	auipc	ra,0x6
    80000fd8:	94e080e7          	jalr	-1714(ra) # 80006922 <snprintf>
    80000fdc:	892a                	mv	s2,a0
  for(int i = 0; i < NLOCK; i++) {
    80000fde:	00010c97          	auipc	s9,0x10
    80000fe2:	40ac8c93          	addi	s9,s9,1034 # 800113e8 <locks>
    80000fe6:	00011c17          	auipc	s8,0x11
    80000fea:	3a2c0c13          	addi	s8,s8,930 # 80012388 <pid_lock>
  n = snprintf(buf, sz, "--- lock kmem/bcache stats\n");
    80000fee:	84e6                	mv	s1,s9
  int tot = 0;
    80000ff0:	4a01                	li	s4,0
    if(locks[i] == 0)
      break;
    if(strncmp(locks[i]->name, "bcache", strlen("bcache")) == 0 ||
    80000ff2:	00007b97          	auipc	s7,0x7
    80000ff6:	126b8b93          	addi	s7,s7,294 # 80008118 <digits+0xd8>
       strncmp(locks[i]->name, "kmem", strlen("kmem")) == 0) {
    80000ffa:	00007d17          	auipc	s10,0x7
    80000ffe:	06ed0d13          	addi	s10,s10,110 # 80008068 <digits+0x28>
    80001002:	a01d                	j	80001028 <statslock+0x92>
      tot += locks[i]->nts;
    80001004:	0009b603          	ld	a2,0(s3)
    80001008:	4e1c                	lw	a5,24(a2)
    8000100a:	01478a3b          	addw	s4,a5,s4
      n += snprint_lock(buf +n, sz-n, locks[i]);
    8000100e:	412b05bb          	subw	a1,s6,s2
    80001012:	012a8533          	add	a0,s5,s2
    80001016:	00000097          	auipc	ra,0x0
    8000101a:	f52080e7          	jalr	-174(ra) # 80000f68 <snprint_lock>
    8000101e:	0125093b          	addw	s2,a0,s2
  for(int i = 0; i < NLOCK; i++) {
    80001022:	04a1                	addi	s1,s1,8
    80001024:	05848763          	beq	s1,s8,80001072 <statslock+0xdc>
    if(locks[i] == 0)
    80001028:	89a6                	mv	s3,s1
    8000102a:	609c                	ld	a5,0(s1)
    8000102c:	c3b9                	beqz	a5,80001072 <statslock+0xdc>
    if(strncmp(locks[i]->name, "bcache", strlen("bcache")) == 0 ||
    8000102e:	0087bd83          	ld	s11,8(a5)
    80001032:	855e                	mv	a0,s7
    80001034:	00000097          	auipc	ra,0x0
    80001038:	2a0080e7          	jalr	672(ra) # 800012d4 <strlen>
    8000103c:	0005061b          	sext.w	a2,a0
    80001040:	85de                	mv	a1,s7
    80001042:	856e                	mv	a0,s11
    80001044:	00000097          	auipc	ra,0x0
    80001048:	1e4080e7          	jalr	484(ra) # 80001228 <strncmp>
    8000104c:	dd45                	beqz	a0,80001004 <statslock+0x6e>
       strncmp(locks[i]->name, "kmem", strlen("kmem")) == 0) {
    8000104e:	609c                	ld	a5,0(s1)
    80001050:	0087bd83          	ld	s11,8(a5)
    80001054:	856a                	mv	a0,s10
    80001056:	00000097          	auipc	ra,0x0
    8000105a:	27e080e7          	jalr	638(ra) # 800012d4 <strlen>
    8000105e:	0005061b          	sext.w	a2,a0
    80001062:	85ea                	mv	a1,s10
    80001064:	856e                	mv	a0,s11
    80001066:	00000097          	auipc	ra,0x0
    8000106a:	1c2080e7          	jalr	450(ra) # 80001228 <strncmp>
    if(strncmp(locks[i]->name, "bcache", strlen("bcache")) == 0 ||
    8000106e:	f955                	bnez	a0,80001022 <statslock+0x8c>
    80001070:	bf51                	j	80001004 <statslock+0x6e>
    }
  }
  
  n += snprintf(buf+n, sz-n, "--- top 5 contended locks:\n");
    80001072:	00007617          	auipc	a2,0x7
    80001076:	0ae60613          	addi	a2,a2,174 # 80008120 <digits+0xe0>
    8000107a:	412b05bb          	subw	a1,s6,s2
    8000107e:	012a8533          	add	a0,s5,s2
    80001082:	00006097          	auipc	ra,0x6
    80001086:	8a0080e7          	jalr	-1888(ra) # 80006922 <snprintf>
    8000108a:	012509bb          	addw	s3,a0,s2
    8000108e:	4b95                	li	s7,5
  int last = 100000000;
    80001090:	05f5e537          	lui	a0,0x5f5e
    80001094:	10050513          	addi	a0,a0,256 # 5f5e100 <_entry-0x7a0a1f00>
  // stupid way to compute top 5 contended locks
  for(int t = 0; t < 5; t++) {
    int top = 0;
    for(int i = 0; i < NLOCK; i++) {
    80001098:	4c01                	li	s8,0
      if(locks[i] == 0)
        break;
      if(locks[i]->nts > locks[top]->nts && locks[i]->nts < last) {
    8000109a:	00010497          	auipc	s1,0x10
    8000109e:	34e48493          	addi	s1,s1,846 # 800113e8 <locks>
    for(int i = 0; i < NLOCK; i++) {
    800010a2:	1f400913          	li	s2,500
    800010a6:	a881                	j	800010f6 <statslock+0x160>
    800010a8:	2705                	addiw	a4,a4,1
    800010aa:	06a1                	addi	a3,a3,8
    800010ac:	03270063          	beq	a4,s2,800010cc <statslock+0x136>
      if(locks[i] == 0)
    800010b0:	629c                	ld	a5,0(a3)
    800010b2:	cf89                	beqz	a5,800010cc <statslock+0x136>
      if(locks[i]->nts > locks[top]->nts && locks[i]->nts < last) {
    800010b4:	4f90                	lw	a2,24(a5)
    800010b6:	00359793          	slli	a5,a1,0x3
    800010ba:	97a6                	add	a5,a5,s1
    800010bc:	639c                	ld	a5,0(a5)
    800010be:	4f9c                	lw	a5,24(a5)
    800010c0:	fec7d4e3          	bge	a5,a2,800010a8 <statslock+0x112>
    800010c4:	fea652e3          	bge	a2,a0,800010a8 <statslock+0x112>
    800010c8:	85ba                	mv	a1,a4
    800010ca:	bff9                	j	800010a8 <statslock+0x112>
        top = i;
      }
    }
    n += snprint_lock(buf+n, sz-n, locks[top]);
    800010cc:	058e                	slli	a1,a1,0x3
    800010ce:	00b48d33          	add	s10,s1,a1
    800010d2:	000d3603          	ld	a2,0(s10)
    800010d6:	413b05bb          	subw	a1,s6,s3
    800010da:	013a8533          	add	a0,s5,s3
    800010de:	00000097          	auipc	ra,0x0
    800010e2:	e8a080e7          	jalr	-374(ra) # 80000f68 <snprint_lock>
    800010e6:	013509bb          	addw	s3,a0,s3
    last = locks[top]->nts;
    800010ea:	000d3783          	ld	a5,0(s10)
    800010ee:	4f88                	lw	a0,24(a5)
  for(int t = 0; t < 5; t++) {
    800010f0:	3bfd                	addiw	s7,s7,-1
    800010f2:	000b8663          	beqz	s7,800010fe <statslock+0x168>
  int tot = 0;
    800010f6:	86e6                	mv	a3,s9
    for(int i = 0; i < NLOCK; i++) {
    800010f8:	8762                	mv	a4,s8
    int top = 0;
    800010fa:	85e2                	mv	a1,s8
    800010fc:	bf55                	j	800010b0 <statslock+0x11a>
  }
  n += snprintf(buf+n, sz-n, "tot= %d\n", tot);
    800010fe:	86d2                	mv	a3,s4
    80001100:	00007617          	auipc	a2,0x7
    80001104:	04060613          	addi	a2,a2,64 # 80008140 <digits+0x100>
    80001108:	413b05bb          	subw	a1,s6,s3
    8000110c:	013a8533          	add	a0,s5,s3
    80001110:	00006097          	auipc	ra,0x6
    80001114:	812080e7          	jalr	-2030(ra) # 80006922 <snprintf>
    80001118:	013509bb          	addw	s3,a0,s3
  release(&lock_locks);  
    8000111c:	00010517          	auipc	a0,0x10
    80001120:	2ac50513          	addi	a0,a0,684 # 800113c8 <lock_locks>
    80001124:	00000097          	auipc	ra,0x0
    80001128:	d18080e7          	jalr	-744(ra) # 80000e3c <release>
  return n;
}
    8000112c:	854e                	mv	a0,s3
    8000112e:	70a6                	ld	ra,104(sp)
    80001130:	7406                	ld	s0,96(sp)
    80001132:	64e6                	ld	s1,88(sp)
    80001134:	6946                	ld	s2,80(sp)
    80001136:	69a6                	ld	s3,72(sp)
    80001138:	6a06                	ld	s4,64(sp)
    8000113a:	7ae2                	ld	s5,56(sp)
    8000113c:	7b42                	ld	s6,48(sp)
    8000113e:	7ba2                	ld	s7,40(sp)
    80001140:	7c02                	ld	s8,32(sp)
    80001142:	6ce2                	ld	s9,24(sp)
    80001144:	6d42                	ld	s10,16(sp)
    80001146:	6da2                	ld	s11,8(sp)
    80001148:	6165                	addi	sp,sp,112
    8000114a:	8082                	ret

000000008000114c <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    8000114c:	1141                	addi	sp,sp,-16
    8000114e:	e422                	sd	s0,8(sp)
    80001150:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80001152:	ce09                	beqz	a2,8000116c <memset+0x20>
    80001154:	87aa                	mv	a5,a0
    80001156:	fff6071b          	addiw	a4,a2,-1
    8000115a:	1702                	slli	a4,a4,0x20
    8000115c:	9301                	srli	a4,a4,0x20
    8000115e:	0705                	addi	a4,a4,1
    80001160:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80001162:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80001166:	0785                	addi	a5,a5,1
    80001168:	fee79de3          	bne	a5,a4,80001162 <memset+0x16>
  }
  return dst;
}
    8000116c:	6422                	ld	s0,8(sp)
    8000116e:	0141                	addi	sp,sp,16
    80001170:	8082                	ret

0000000080001172 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80001172:	1141                	addi	sp,sp,-16
    80001174:	e422                	sd	s0,8(sp)
    80001176:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80001178:	ca05                	beqz	a2,800011a8 <memcmp+0x36>
    8000117a:	fff6069b          	addiw	a3,a2,-1
    8000117e:	1682                	slli	a3,a3,0x20
    80001180:	9281                	srli	a3,a3,0x20
    80001182:	0685                	addi	a3,a3,1
    80001184:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80001186:	00054783          	lbu	a5,0(a0)
    8000118a:	0005c703          	lbu	a4,0(a1)
    8000118e:	00e79863          	bne	a5,a4,8000119e <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80001192:	0505                	addi	a0,a0,1
    80001194:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80001196:	fed518e3          	bne	a0,a3,80001186 <memcmp+0x14>
  }

  return 0;
    8000119a:	4501                	li	a0,0
    8000119c:	a019                	j	800011a2 <memcmp+0x30>
      return *s1 - *s2;
    8000119e:	40e7853b          	subw	a0,a5,a4
}
    800011a2:	6422                	ld	s0,8(sp)
    800011a4:	0141                	addi	sp,sp,16
    800011a6:	8082                	ret
  return 0;
    800011a8:	4501                	li	a0,0
    800011aa:	bfe5                	j	800011a2 <memcmp+0x30>

00000000800011ac <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    800011ac:	1141                	addi	sp,sp,-16
    800011ae:	e422                	sd	s0,8(sp)
    800011b0:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    800011b2:	00a5f963          	bgeu	a1,a0,800011c4 <memmove+0x18>
    800011b6:	02061713          	slli	a4,a2,0x20
    800011ba:	9301                	srli	a4,a4,0x20
    800011bc:	00e587b3          	add	a5,a1,a4
    800011c0:	02f56563          	bltu	a0,a5,800011ea <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    800011c4:	fff6069b          	addiw	a3,a2,-1
    800011c8:	ce11                	beqz	a2,800011e4 <memmove+0x38>
    800011ca:	1682                	slli	a3,a3,0x20
    800011cc:	9281                	srli	a3,a3,0x20
    800011ce:	0685                	addi	a3,a3,1
    800011d0:	96ae                	add	a3,a3,a1
    800011d2:	87aa                	mv	a5,a0
      *d++ = *s++;
    800011d4:	0585                	addi	a1,a1,1
    800011d6:	0785                	addi	a5,a5,1
    800011d8:	fff5c703          	lbu	a4,-1(a1)
    800011dc:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    800011e0:	fed59ae3          	bne	a1,a3,800011d4 <memmove+0x28>

  return dst;
}
    800011e4:	6422                	ld	s0,8(sp)
    800011e6:	0141                	addi	sp,sp,16
    800011e8:	8082                	ret
    d += n;
    800011ea:	972a                	add	a4,a4,a0
    while(n-- > 0)
    800011ec:	fff6069b          	addiw	a3,a2,-1
    800011f0:	da75                	beqz	a2,800011e4 <memmove+0x38>
    800011f2:	02069613          	slli	a2,a3,0x20
    800011f6:	9201                	srli	a2,a2,0x20
    800011f8:	fff64613          	not	a2,a2
    800011fc:	963e                	add	a2,a2,a5
      *--d = *--s;
    800011fe:	17fd                	addi	a5,a5,-1
    80001200:	177d                	addi	a4,a4,-1
    80001202:	0007c683          	lbu	a3,0(a5)
    80001206:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    8000120a:	fec79ae3          	bne	a5,a2,800011fe <memmove+0x52>
    8000120e:	bfd9                	j	800011e4 <memmove+0x38>

0000000080001210 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80001210:	1141                	addi	sp,sp,-16
    80001212:	e406                	sd	ra,8(sp)
    80001214:	e022                	sd	s0,0(sp)
    80001216:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80001218:	00000097          	auipc	ra,0x0
    8000121c:	f94080e7          	jalr	-108(ra) # 800011ac <memmove>
}
    80001220:	60a2                	ld	ra,8(sp)
    80001222:	6402                	ld	s0,0(sp)
    80001224:	0141                	addi	sp,sp,16
    80001226:	8082                	ret

0000000080001228 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80001228:	1141                	addi	sp,sp,-16
    8000122a:	e422                	sd	s0,8(sp)
    8000122c:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    8000122e:	ce11                	beqz	a2,8000124a <strncmp+0x22>
    80001230:	00054783          	lbu	a5,0(a0)
    80001234:	cf89                	beqz	a5,8000124e <strncmp+0x26>
    80001236:	0005c703          	lbu	a4,0(a1)
    8000123a:	00f71a63          	bne	a4,a5,8000124e <strncmp+0x26>
    n--, p++, q++;
    8000123e:	367d                	addiw	a2,a2,-1
    80001240:	0505                	addi	a0,a0,1
    80001242:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80001244:	f675                	bnez	a2,80001230 <strncmp+0x8>
  if(n == 0)
    return 0;
    80001246:	4501                	li	a0,0
    80001248:	a809                	j	8000125a <strncmp+0x32>
    8000124a:	4501                	li	a0,0
    8000124c:	a039                	j	8000125a <strncmp+0x32>
  if(n == 0)
    8000124e:	ca09                	beqz	a2,80001260 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80001250:	00054503          	lbu	a0,0(a0)
    80001254:	0005c783          	lbu	a5,0(a1)
    80001258:	9d1d                	subw	a0,a0,a5
}
    8000125a:	6422                	ld	s0,8(sp)
    8000125c:	0141                	addi	sp,sp,16
    8000125e:	8082                	ret
    return 0;
    80001260:	4501                	li	a0,0
    80001262:	bfe5                	j	8000125a <strncmp+0x32>

0000000080001264 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80001264:	1141                	addi	sp,sp,-16
    80001266:	e422                	sd	s0,8(sp)
    80001268:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    8000126a:	872a                	mv	a4,a0
    8000126c:	8832                	mv	a6,a2
    8000126e:	367d                	addiw	a2,a2,-1
    80001270:	01005963          	blez	a6,80001282 <strncpy+0x1e>
    80001274:	0705                	addi	a4,a4,1
    80001276:	0005c783          	lbu	a5,0(a1)
    8000127a:	fef70fa3          	sb	a5,-1(a4)
    8000127e:	0585                	addi	a1,a1,1
    80001280:	f7f5                	bnez	a5,8000126c <strncpy+0x8>
    ;
  while(n-- > 0)
    80001282:	00c05d63          	blez	a2,8000129c <strncpy+0x38>
    80001286:	86ba                	mv	a3,a4
    *s++ = 0;
    80001288:	0685                	addi	a3,a3,1
    8000128a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    8000128e:	fff6c793          	not	a5,a3
    80001292:	9fb9                	addw	a5,a5,a4
    80001294:	010787bb          	addw	a5,a5,a6
    80001298:	fef048e3          	bgtz	a5,80001288 <strncpy+0x24>
  return os;
}
    8000129c:	6422                	ld	s0,8(sp)
    8000129e:	0141                	addi	sp,sp,16
    800012a0:	8082                	ret

00000000800012a2 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    800012a2:	1141                	addi	sp,sp,-16
    800012a4:	e422                	sd	s0,8(sp)
    800012a6:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    800012a8:	02c05363          	blez	a2,800012ce <safestrcpy+0x2c>
    800012ac:	fff6069b          	addiw	a3,a2,-1
    800012b0:	1682                	slli	a3,a3,0x20
    800012b2:	9281                	srli	a3,a3,0x20
    800012b4:	96ae                	add	a3,a3,a1
    800012b6:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    800012b8:	00d58963          	beq	a1,a3,800012ca <safestrcpy+0x28>
    800012bc:	0585                	addi	a1,a1,1
    800012be:	0785                	addi	a5,a5,1
    800012c0:	fff5c703          	lbu	a4,-1(a1)
    800012c4:	fee78fa3          	sb	a4,-1(a5)
    800012c8:	fb65                	bnez	a4,800012b8 <safestrcpy+0x16>
    ;
  *s = 0;
    800012ca:	00078023          	sb	zero,0(a5)
  return os;
}
    800012ce:	6422                	ld	s0,8(sp)
    800012d0:	0141                	addi	sp,sp,16
    800012d2:	8082                	ret

00000000800012d4 <strlen>:

int
strlen(const char *s)
{
    800012d4:	1141                	addi	sp,sp,-16
    800012d6:	e422                	sd	s0,8(sp)
    800012d8:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    800012da:	00054783          	lbu	a5,0(a0)
    800012de:	cf91                	beqz	a5,800012fa <strlen+0x26>
    800012e0:	0505                	addi	a0,a0,1
    800012e2:	87aa                	mv	a5,a0
    800012e4:	4685                	li	a3,1
    800012e6:	9e89                	subw	a3,a3,a0
    800012e8:	00f6853b          	addw	a0,a3,a5
    800012ec:	0785                	addi	a5,a5,1
    800012ee:	fff7c703          	lbu	a4,-1(a5)
    800012f2:	fb7d                	bnez	a4,800012e8 <strlen+0x14>
    ;
  return n;
}
    800012f4:	6422                	ld	s0,8(sp)
    800012f6:	0141                	addi	sp,sp,16
    800012f8:	8082                	ret
  for(n = 0; s[n]; n++)
    800012fa:	4501                	li	a0,0
    800012fc:	bfe5                	j	800012f4 <strlen+0x20>

00000000800012fe <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    800012fe:	1141                	addi	sp,sp,-16
    80001300:	e406                	sd	ra,8(sp)
    80001302:	e022                	sd	s0,0(sp)
    80001304:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80001306:	00001097          	auipc	ra,0x1
    8000130a:	a82080e7          	jalr	-1406(ra) # 80001d88 <cpuid>
#endif    
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    8000130e:	00008717          	auipc	a4,0x8
    80001312:	cfe70713          	addi	a4,a4,-770 # 8000900c <started>
  if(cpuid() == 0){
    80001316:	c139                	beqz	a0,8000135c <main+0x5e>
    while(started == 0)
    80001318:	431c                	lw	a5,0(a4)
    8000131a:	2781                	sext.w	a5,a5
    8000131c:	dff5                	beqz	a5,80001318 <main+0x1a>
      ;
    __sync_synchronize();
    8000131e:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80001322:	00001097          	auipc	ra,0x1
    80001326:	a66080e7          	jalr	-1434(ra) # 80001d88 <cpuid>
    8000132a:	85aa                	mv	a1,a0
    8000132c:	00007517          	auipc	a0,0x7
    80001330:	e3c50513          	addi	a0,a0,-452 # 80008168 <digits+0x128>
    80001334:	fffff097          	auipc	ra,0xfffff
    80001338:	266080e7          	jalr	614(ra) # 8000059a <printf>
    kvminithart();    // turn on paging
    8000133c:	00000097          	auipc	ra,0x0
    80001340:	186080e7          	jalr	390(ra) # 800014c2 <kvminithart>
    trapinithart();   // install kernel trap vector
    80001344:	00001097          	auipc	ra,0x1
    80001348:	6ce080e7          	jalr	1742(ra) # 80002a12 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    8000134c:	00005097          	auipc	ra,0x5
    80001350:	e14080e7          	jalr	-492(ra) # 80006160 <plicinithart>
  }

  scheduler();        
    80001354:	00001097          	auipc	ra,0x1
    80001358:	f90080e7          	jalr	-112(ra) # 800022e4 <scheduler>
    consoleinit();
    8000135c:	fffff097          	auipc	ra,0xfffff
    80001360:	106080e7          	jalr	262(ra) # 80000462 <consoleinit>
    statsinit();
    80001364:	00005097          	auipc	ra,0x5
    80001368:	4e2080e7          	jalr	1250(ra) # 80006846 <statsinit>
    printfinit();
    8000136c:	fffff097          	auipc	ra,0xfffff
    80001370:	414080e7          	jalr	1044(ra) # 80000780 <printfinit>
    printf("\n");
    80001374:	00007517          	auipc	a0,0x7
    80001378:	e0450513          	addi	a0,a0,-508 # 80008178 <digits+0x138>
    8000137c:	fffff097          	auipc	ra,0xfffff
    80001380:	21e080e7          	jalr	542(ra) # 8000059a <printf>
    printf("xv6 kernel is booting\n");
    80001384:	00007517          	auipc	a0,0x7
    80001388:	dcc50513          	addi	a0,a0,-564 # 80008150 <digits+0x110>
    8000138c:	fffff097          	auipc	ra,0xfffff
    80001390:	20e080e7          	jalr	526(ra) # 8000059a <printf>
    printf("\n");
    80001394:	00007517          	auipc	a0,0x7
    80001398:	de450513          	addi	a0,a0,-540 # 80008178 <digits+0x138>
    8000139c:	fffff097          	auipc	ra,0xfffff
    800013a0:	1fe080e7          	jalr	510(ra) # 8000059a <printf>
    kinit();         // physical page allocator
    800013a4:	fffff097          	auipc	ra,0xfffff
    800013a8:	77a080e7          	jalr	1914(ra) # 80000b1e <kinit>
    kvminit();       // create kernel page table
    800013ac:	00000097          	auipc	ra,0x0
    800013b0:	242080e7          	jalr	578(ra) # 800015ee <kvminit>
    kvminithart();   // turn on paging
    800013b4:	00000097          	auipc	ra,0x0
    800013b8:	10e080e7          	jalr	270(ra) # 800014c2 <kvminithart>
    procinit();      // process table
    800013bc:	00001097          	auipc	ra,0x1
    800013c0:	8fc080e7          	jalr	-1796(ra) # 80001cb8 <procinit>
    trapinit();      // trap vectors
    800013c4:	00001097          	auipc	ra,0x1
    800013c8:	626080e7          	jalr	1574(ra) # 800029ea <trapinit>
    trapinithart();  // install kernel trap vector
    800013cc:	00001097          	auipc	ra,0x1
    800013d0:	646080e7          	jalr	1606(ra) # 80002a12 <trapinithart>
    plicinit();      // set up interrupt controller
    800013d4:	00005097          	auipc	ra,0x5
    800013d8:	d76080e7          	jalr	-650(ra) # 8000614a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    800013dc:	00005097          	auipc	ra,0x5
    800013e0:	d84080e7          	jalr	-636(ra) # 80006160 <plicinithart>
    binit();         // buffer cache
    800013e4:	00002097          	auipc	ra,0x2
    800013e8:	d94080e7          	jalr	-620(ra) # 80003178 <binit>
    iinit();         // inode cache
    800013ec:	00002097          	auipc	ra,0x2
    800013f0:	594080e7          	jalr	1428(ra) # 80003980 <iinit>
    fileinit();      // file table
    800013f4:	00003097          	auipc	ra,0x3
    800013f8:	544080e7          	jalr	1348(ra) # 80004938 <fileinit>
    virtio_disk_init(); // emulated hard disk
    800013fc:	00005097          	auipc	ra,0x5
    80001400:	e86080e7          	jalr	-378(ra) # 80006282 <virtio_disk_init>
    userinit();      // first user process
    80001404:	00001097          	auipc	ra,0x1
    80001408:	c7a080e7          	jalr	-902(ra) # 8000207e <userinit>
    __sync_synchronize();
    8000140c:	0ff0000f          	fence
    started = 1;
    80001410:	4785                	li	a5,1
    80001412:	00008717          	auipc	a4,0x8
    80001416:	bef72d23          	sw	a5,-1030(a4) # 8000900c <started>
    8000141a:	bf2d                	j	80001354 <main+0x56>

000000008000141c <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
static pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    8000141c:	7139                	addi	sp,sp,-64
    8000141e:	fc06                	sd	ra,56(sp)
    80001420:	f822                	sd	s0,48(sp)
    80001422:	f426                	sd	s1,40(sp)
    80001424:	f04a                	sd	s2,32(sp)
    80001426:	ec4e                	sd	s3,24(sp)
    80001428:	e852                	sd	s4,16(sp)
    8000142a:	e456                	sd	s5,8(sp)
    8000142c:	e05a                	sd	s6,0(sp)
    8000142e:	0080                	addi	s0,sp,64
    80001430:	84aa                	mv	s1,a0
    80001432:	89ae                	mv	s3,a1
    80001434:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001436:	57fd                	li	a5,-1
    80001438:	83e9                	srli	a5,a5,0x1a
    8000143a:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    8000143c:	4b31                	li	s6,12
  if(va >= MAXVA)
    8000143e:	04b7f263          	bgeu	a5,a1,80001482 <walk+0x66>
    panic("walk");
    80001442:	00007517          	auipc	a0,0x7
    80001446:	d3e50513          	addi	a0,a0,-706 # 80008180 <digits+0x140>
    8000144a:	fffff097          	auipc	ra,0xfffff
    8000144e:	106080e7          	jalr	262(ra) # 80000550 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001452:	060a8663          	beqz	s5,800014be <walk+0xa2>
    80001456:	fffff097          	auipc	ra,0xfffff
    8000145a:	79a080e7          	jalr	1946(ra) # 80000bf0 <kalloc>
    8000145e:	84aa                	mv	s1,a0
    80001460:	c529                	beqz	a0,800014aa <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001462:	6605                	lui	a2,0x1
    80001464:	4581                	li	a1,0
    80001466:	00000097          	auipc	ra,0x0
    8000146a:	ce6080e7          	jalr	-794(ra) # 8000114c <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000146e:	00c4d793          	srli	a5,s1,0xc
    80001472:	07aa                	slli	a5,a5,0xa
    80001474:	0017e793          	ori	a5,a5,1
    80001478:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000147c:	3a5d                	addiw	s4,s4,-9
    8000147e:	036a0063          	beq	s4,s6,8000149e <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001482:	0149d933          	srl	s2,s3,s4
    80001486:	1ff97913          	andi	s2,s2,511
    8000148a:	090e                	slli	s2,s2,0x3
    8000148c:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000148e:	00093483          	ld	s1,0(s2)
    80001492:	0014f793          	andi	a5,s1,1
    80001496:	dfd5                	beqz	a5,80001452 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001498:	80a9                	srli	s1,s1,0xa
    8000149a:	04b2                	slli	s1,s1,0xc
    8000149c:	b7c5                	j	8000147c <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000149e:	00c9d513          	srli	a0,s3,0xc
    800014a2:	1ff57513          	andi	a0,a0,511
    800014a6:	050e                	slli	a0,a0,0x3
    800014a8:	9526                	add	a0,a0,s1
}
    800014aa:	70e2                	ld	ra,56(sp)
    800014ac:	7442                	ld	s0,48(sp)
    800014ae:	74a2                	ld	s1,40(sp)
    800014b0:	7902                	ld	s2,32(sp)
    800014b2:	69e2                	ld	s3,24(sp)
    800014b4:	6a42                	ld	s4,16(sp)
    800014b6:	6aa2                	ld	s5,8(sp)
    800014b8:	6b02                	ld	s6,0(sp)
    800014ba:	6121                	addi	sp,sp,64
    800014bc:	8082                	ret
        return 0;
    800014be:	4501                	li	a0,0
    800014c0:	b7ed                	j	800014aa <walk+0x8e>

00000000800014c2 <kvminithart>:
{
    800014c2:	1141                	addi	sp,sp,-16
    800014c4:	e422                	sd	s0,8(sp)
    800014c6:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    800014c8:	00008797          	auipc	a5,0x8
    800014cc:	b487b783          	ld	a5,-1208(a5) # 80009010 <kernel_pagetable>
    800014d0:	83b1                	srli	a5,a5,0xc
    800014d2:	577d                	li	a4,-1
    800014d4:	177e                	slli	a4,a4,0x3f
    800014d6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    800014d8:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    800014dc:	12000073          	sfence.vma
}
    800014e0:	6422                	ld	s0,8(sp)
    800014e2:	0141                	addi	sp,sp,16
    800014e4:	8082                	ret

00000000800014e6 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800014e6:	57fd                	li	a5,-1
    800014e8:	83e9                	srli	a5,a5,0x1a
    800014ea:	00b7f463          	bgeu	a5,a1,800014f2 <walkaddr+0xc>
    return 0;
    800014ee:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800014f0:	8082                	ret
{
    800014f2:	1141                	addi	sp,sp,-16
    800014f4:	e406                	sd	ra,8(sp)
    800014f6:	e022                	sd	s0,0(sp)
    800014f8:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800014fa:	4601                	li	a2,0
    800014fc:	00000097          	auipc	ra,0x0
    80001500:	f20080e7          	jalr	-224(ra) # 8000141c <walk>
  if(pte == 0)
    80001504:	c105                	beqz	a0,80001524 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001506:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001508:	0117f693          	andi	a3,a5,17
    8000150c:	4745                	li	a4,17
    return 0;
    8000150e:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001510:	00e68663          	beq	a3,a4,8000151c <walkaddr+0x36>
}
    80001514:	60a2                	ld	ra,8(sp)
    80001516:	6402                	ld	s0,0(sp)
    80001518:	0141                	addi	sp,sp,16
    8000151a:	8082                	ret
  pa = PTE2PA(*pte);
    8000151c:	00a7d513          	srli	a0,a5,0xa
    80001520:	0532                	slli	a0,a0,0xc
  return pa;
    80001522:	bfcd                	j	80001514 <walkaddr+0x2e>
    return 0;
    80001524:	4501                	li	a0,0
    80001526:	b7fd                	j	80001514 <walkaddr+0x2e>

0000000080001528 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001528:	715d                	addi	sp,sp,-80
    8000152a:	e486                	sd	ra,72(sp)
    8000152c:	e0a2                	sd	s0,64(sp)
    8000152e:	fc26                	sd	s1,56(sp)
    80001530:	f84a                	sd	s2,48(sp)
    80001532:	f44e                	sd	s3,40(sp)
    80001534:	f052                	sd	s4,32(sp)
    80001536:	ec56                	sd	s5,24(sp)
    80001538:	e85a                	sd	s6,16(sp)
    8000153a:	e45e                	sd	s7,8(sp)
    8000153c:	0880                	addi	s0,sp,80
    8000153e:	8aaa                	mv	s5,a0
    80001540:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    80001542:	777d                	lui	a4,0xfffff
    80001544:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001548:	167d                	addi	a2,a2,-1
    8000154a:	00b609b3          	add	s3,a2,a1
    8000154e:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001552:	893e                	mv	s2,a5
    80001554:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001558:	6b85                	lui	s7,0x1
    8000155a:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000155e:	4605                	li	a2,1
    80001560:	85ca                	mv	a1,s2
    80001562:	8556                	mv	a0,s5
    80001564:	00000097          	auipc	ra,0x0
    80001568:	eb8080e7          	jalr	-328(ra) # 8000141c <walk>
    8000156c:	c51d                	beqz	a0,8000159a <mappages+0x72>
    if(*pte & PTE_V)
    8000156e:	611c                	ld	a5,0(a0)
    80001570:	8b85                	andi	a5,a5,1
    80001572:	ef81                	bnez	a5,8000158a <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001574:	80b1                	srli	s1,s1,0xc
    80001576:	04aa                	slli	s1,s1,0xa
    80001578:	0164e4b3          	or	s1,s1,s6
    8000157c:	0014e493          	ori	s1,s1,1
    80001580:	e104                	sd	s1,0(a0)
    if(a == last)
    80001582:	03390863          	beq	s2,s3,800015b2 <mappages+0x8a>
    a += PGSIZE;
    80001586:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001588:	bfc9                	j	8000155a <mappages+0x32>
      panic("remap");
    8000158a:	00007517          	auipc	a0,0x7
    8000158e:	bfe50513          	addi	a0,a0,-1026 # 80008188 <digits+0x148>
    80001592:	fffff097          	auipc	ra,0xfffff
    80001596:	fbe080e7          	jalr	-66(ra) # 80000550 <panic>
      return -1;
    8000159a:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000159c:	60a6                	ld	ra,72(sp)
    8000159e:	6406                	ld	s0,64(sp)
    800015a0:	74e2                	ld	s1,56(sp)
    800015a2:	7942                	ld	s2,48(sp)
    800015a4:	79a2                	ld	s3,40(sp)
    800015a6:	7a02                	ld	s4,32(sp)
    800015a8:	6ae2                	ld	s5,24(sp)
    800015aa:	6b42                	ld	s6,16(sp)
    800015ac:	6ba2                	ld	s7,8(sp)
    800015ae:	6161                	addi	sp,sp,80
    800015b0:	8082                	ret
  return 0;
    800015b2:	4501                	li	a0,0
    800015b4:	b7e5                	j	8000159c <mappages+0x74>

00000000800015b6 <kvmmap>:
{
    800015b6:	1141                	addi	sp,sp,-16
    800015b8:	e406                	sd	ra,8(sp)
    800015ba:	e022                	sd	s0,0(sp)
    800015bc:	0800                	addi	s0,sp,16
    800015be:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    800015c0:	86ae                	mv	a3,a1
    800015c2:	85aa                	mv	a1,a0
    800015c4:	00008517          	auipc	a0,0x8
    800015c8:	a4c53503          	ld	a0,-1460(a0) # 80009010 <kernel_pagetable>
    800015cc:	00000097          	auipc	ra,0x0
    800015d0:	f5c080e7          	jalr	-164(ra) # 80001528 <mappages>
    800015d4:	e509                	bnez	a0,800015de <kvmmap+0x28>
}
    800015d6:	60a2                	ld	ra,8(sp)
    800015d8:	6402                	ld	s0,0(sp)
    800015da:	0141                	addi	sp,sp,16
    800015dc:	8082                	ret
    panic("kvmmap");
    800015de:	00007517          	auipc	a0,0x7
    800015e2:	bb250513          	addi	a0,a0,-1102 # 80008190 <digits+0x150>
    800015e6:	fffff097          	auipc	ra,0xfffff
    800015ea:	f6a080e7          	jalr	-150(ra) # 80000550 <panic>

00000000800015ee <kvminit>:
{
    800015ee:	1101                	addi	sp,sp,-32
    800015f0:	ec06                	sd	ra,24(sp)
    800015f2:	e822                	sd	s0,16(sp)
    800015f4:	e426                	sd	s1,8(sp)
    800015f6:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    800015f8:	fffff097          	auipc	ra,0xfffff
    800015fc:	5f8080e7          	jalr	1528(ra) # 80000bf0 <kalloc>
    80001600:	00008797          	auipc	a5,0x8
    80001604:	a0a7b823          	sd	a0,-1520(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    80001608:	6605                	lui	a2,0x1
    8000160a:	4581                	li	a1,0
    8000160c:	00000097          	auipc	ra,0x0
    80001610:	b40080e7          	jalr	-1216(ra) # 8000114c <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001614:	4699                	li	a3,6
    80001616:	6605                	lui	a2,0x1
    80001618:	100005b7          	lui	a1,0x10000
    8000161c:	10000537          	lui	a0,0x10000
    80001620:	00000097          	auipc	ra,0x0
    80001624:	f96080e7          	jalr	-106(ra) # 800015b6 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001628:	4699                	li	a3,6
    8000162a:	6605                	lui	a2,0x1
    8000162c:	100015b7          	lui	a1,0x10001
    80001630:	10001537          	lui	a0,0x10001
    80001634:	00000097          	auipc	ra,0x0
    80001638:	f82080e7          	jalr	-126(ra) # 800015b6 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    8000163c:	4699                	li	a3,6
    8000163e:	00400637          	lui	a2,0x400
    80001642:	0c0005b7          	lui	a1,0xc000
    80001646:	0c000537          	lui	a0,0xc000
    8000164a:	00000097          	auipc	ra,0x0
    8000164e:	f6c080e7          	jalr	-148(ra) # 800015b6 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001652:	00007497          	auipc	s1,0x7
    80001656:	9ae48493          	addi	s1,s1,-1618 # 80008000 <etext>
    8000165a:	46a9                	li	a3,10
    8000165c:	80007617          	auipc	a2,0x80007
    80001660:	9a460613          	addi	a2,a2,-1628 # 8000 <_entry-0x7fff8000>
    80001664:	4585                	li	a1,1
    80001666:	05fe                	slli	a1,a1,0x1f
    80001668:	852e                	mv	a0,a1
    8000166a:	00000097          	auipc	ra,0x0
    8000166e:	f4c080e7          	jalr	-180(ra) # 800015b6 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001672:	4699                	li	a3,6
    80001674:	4645                	li	a2,17
    80001676:	066e                	slli	a2,a2,0x1b
    80001678:	8e05                	sub	a2,a2,s1
    8000167a:	85a6                	mv	a1,s1
    8000167c:	8526                	mv	a0,s1
    8000167e:	00000097          	auipc	ra,0x0
    80001682:	f38080e7          	jalr	-200(ra) # 800015b6 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001686:	46a9                	li	a3,10
    80001688:	6605                	lui	a2,0x1
    8000168a:	00006597          	auipc	a1,0x6
    8000168e:	97658593          	addi	a1,a1,-1674 # 80007000 <_trampoline>
    80001692:	04000537          	lui	a0,0x4000
    80001696:	157d                	addi	a0,a0,-1
    80001698:	0532                	slli	a0,a0,0xc
    8000169a:	00000097          	auipc	ra,0x0
    8000169e:	f1c080e7          	jalr	-228(ra) # 800015b6 <kvmmap>
}
    800016a2:	60e2                	ld	ra,24(sp)
    800016a4:	6442                	ld	s0,16(sp)
    800016a6:	64a2                	ld	s1,8(sp)
    800016a8:	6105                	addi	sp,sp,32
    800016aa:	8082                	ret

00000000800016ac <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800016ac:	715d                	addi	sp,sp,-80
    800016ae:	e486                	sd	ra,72(sp)
    800016b0:	e0a2                	sd	s0,64(sp)
    800016b2:	fc26                	sd	s1,56(sp)
    800016b4:	f84a                	sd	s2,48(sp)
    800016b6:	f44e                	sd	s3,40(sp)
    800016b8:	f052                	sd	s4,32(sp)
    800016ba:	ec56                	sd	s5,24(sp)
    800016bc:	e85a                	sd	s6,16(sp)
    800016be:	e45e                	sd	s7,8(sp)
    800016c0:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800016c2:	03459793          	slli	a5,a1,0x34
    800016c6:	e795                	bnez	a5,800016f2 <uvmunmap+0x46>
    800016c8:	8a2a                	mv	s4,a0
    800016ca:	892e                	mv	s2,a1
    800016cc:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800016ce:	0632                	slli	a2,a2,0xc
    800016d0:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800016d4:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800016d6:	6b05                	lui	s6,0x1
    800016d8:	0735e863          	bltu	a1,s3,80001748 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800016dc:	60a6                	ld	ra,72(sp)
    800016de:	6406                	ld	s0,64(sp)
    800016e0:	74e2                	ld	s1,56(sp)
    800016e2:	7942                	ld	s2,48(sp)
    800016e4:	79a2                	ld	s3,40(sp)
    800016e6:	7a02                	ld	s4,32(sp)
    800016e8:	6ae2                	ld	s5,24(sp)
    800016ea:	6b42                	ld	s6,16(sp)
    800016ec:	6ba2                	ld	s7,8(sp)
    800016ee:	6161                	addi	sp,sp,80
    800016f0:	8082                	ret
    panic("uvmunmap: not aligned");
    800016f2:	00007517          	auipc	a0,0x7
    800016f6:	aa650513          	addi	a0,a0,-1370 # 80008198 <digits+0x158>
    800016fa:	fffff097          	auipc	ra,0xfffff
    800016fe:	e56080e7          	jalr	-426(ra) # 80000550 <panic>
      panic("uvmunmap: walk");
    80001702:	00007517          	auipc	a0,0x7
    80001706:	aae50513          	addi	a0,a0,-1362 # 800081b0 <digits+0x170>
    8000170a:	fffff097          	auipc	ra,0xfffff
    8000170e:	e46080e7          	jalr	-442(ra) # 80000550 <panic>
      panic("uvmunmap: not mapped");
    80001712:	00007517          	auipc	a0,0x7
    80001716:	aae50513          	addi	a0,a0,-1362 # 800081c0 <digits+0x180>
    8000171a:	fffff097          	auipc	ra,0xfffff
    8000171e:	e36080e7          	jalr	-458(ra) # 80000550 <panic>
      panic("uvmunmap: not a leaf");
    80001722:	00007517          	auipc	a0,0x7
    80001726:	ab650513          	addi	a0,a0,-1354 # 800081d8 <digits+0x198>
    8000172a:	fffff097          	auipc	ra,0xfffff
    8000172e:	e26080e7          	jalr	-474(ra) # 80000550 <panic>
      uint64 pa = PTE2PA(*pte);
    80001732:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001734:	0532                	slli	a0,a0,0xc
    80001736:	fffff097          	auipc	ra,0xfffff
    8000173a:	2f6080e7          	jalr	758(ra) # 80000a2c <kfree>
    *pte = 0;
    8000173e:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001742:	995a                	add	s2,s2,s6
    80001744:	f9397ce3          	bgeu	s2,s3,800016dc <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001748:	4601                	li	a2,0
    8000174a:	85ca                	mv	a1,s2
    8000174c:	8552                	mv	a0,s4
    8000174e:	00000097          	auipc	ra,0x0
    80001752:	cce080e7          	jalr	-818(ra) # 8000141c <walk>
    80001756:	84aa                	mv	s1,a0
    80001758:	d54d                	beqz	a0,80001702 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000175a:	6108                	ld	a0,0(a0)
    8000175c:	00157793          	andi	a5,a0,1
    80001760:	dbcd                	beqz	a5,80001712 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001762:	3ff57793          	andi	a5,a0,1023
    80001766:	fb778ee3          	beq	a5,s7,80001722 <uvmunmap+0x76>
    if(do_free){
    8000176a:	fc0a8ae3          	beqz	s5,8000173e <uvmunmap+0x92>
    8000176e:	b7d1                	j	80001732 <uvmunmap+0x86>

0000000080001770 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001770:	1101                	addi	sp,sp,-32
    80001772:	ec06                	sd	ra,24(sp)
    80001774:	e822                	sd	s0,16(sp)
    80001776:	e426                	sd	s1,8(sp)
    80001778:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000177a:	fffff097          	auipc	ra,0xfffff
    8000177e:	476080e7          	jalr	1142(ra) # 80000bf0 <kalloc>
    80001782:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001784:	c519                	beqz	a0,80001792 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001786:	6605                	lui	a2,0x1
    80001788:	4581                	li	a1,0
    8000178a:	00000097          	auipc	ra,0x0
    8000178e:	9c2080e7          	jalr	-1598(ra) # 8000114c <memset>
  return pagetable;
}
    80001792:	8526                	mv	a0,s1
    80001794:	60e2                	ld	ra,24(sp)
    80001796:	6442                	ld	s0,16(sp)
    80001798:	64a2                	ld	s1,8(sp)
    8000179a:	6105                	addi	sp,sp,32
    8000179c:	8082                	ret

000000008000179e <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000179e:	7179                	addi	sp,sp,-48
    800017a0:	f406                	sd	ra,40(sp)
    800017a2:	f022                	sd	s0,32(sp)
    800017a4:	ec26                	sd	s1,24(sp)
    800017a6:	e84a                	sd	s2,16(sp)
    800017a8:	e44e                	sd	s3,8(sp)
    800017aa:	e052                	sd	s4,0(sp)
    800017ac:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800017ae:	6785                	lui	a5,0x1
    800017b0:	04f67863          	bgeu	a2,a5,80001800 <uvminit+0x62>
    800017b4:	8a2a                	mv	s4,a0
    800017b6:	89ae                	mv	s3,a1
    800017b8:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800017ba:	fffff097          	auipc	ra,0xfffff
    800017be:	436080e7          	jalr	1078(ra) # 80000bf0 <kalloc>
    800017c2:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800017c4:	6605                	lui	a2,0x1
    800017c6:	4581                	li	a1,0
    800017c8:	00000097          	auipc	ra,0x0
    800017cc:	984080e7          	jalr	-1660(ra) # 8000114c <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800017d0:	4779                	li	a4,30
    800017d2:	86ca                	mv	a3,s2
    800017d4:	6605                	lui	a2,0x1
    800017d6:	4581                	li	a1,0
    800017d8:	8552                	mv	a0,s4
    800017da:	00000097          	auipc	ra,0x0
    800017de:	d4e080e7          	jalr	-690(ra) # 80001528 <mappages>
  memmove(mem, src, sz);
    800017e2:	8626                	mv	a2,s1
    800017e4:	85ce                	mv	a1,s3
    800017e6:	854a                	mv	a0,s2
    800017e8:	00000097          	auipc	ra,0x0
    800017ec:	9c4080e7          	jalr	-1596(ra) # 800011ac <memmove>
}
    800017f0:	70a2                	ld	ra,40(sp)
    800017f2:	7402                	ld	s0,32(sp)
    800017f4:	64e2                	ld	s1,24(sp)
    800017f6:	6942                	ld	s2,16(sp)
    800017f8:	69a2                	ld	s3,8(sp)
    800017fa:	6a02                	ld	s4,0(sp)
    800017fc:	6145                	addi	sp,sp,48
    800017fe:	8082                	ret
    panic("inituvm: more than a page");
    80001800:	00007517          	auipc	a0,0x7
    80001804:	9f050513          	addi	a0,a0,-1552 # 800081f0 <digits+0x1b0>
    80001808:	fffff097          	auipc	ra,0xfffff
    8000180c:	d48080e7          	jalr	-696(ra) # 80000550 <panic>

0000000080001810 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001810:	1101                	addi	sp,sp,-32
    80001812:	ec06                	sd	ra,24(sp)
    80001814:	e822                	sd	s0,16(sp)
    80001816:	e426                	sd	s1,8(sp)
    80001818:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000181a:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000181c:	00b67d63          	bgeu	a2,a1,80001836 <uvmdealloc+0x26>
    80001820:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001822:	6785                	lui	a5,0x1
    80001824:	17fd                	addi	a5,a5,-1
    80001826:	00f60733          	add	a4,a2,a5
    8000182a:	767d                	lui	a2,0xfffff
    8000182c:	8f71                	and	a4,a4,a2
    8000182e:	97ae                	add	a5,a5,a1
    80001830:	8ff1                	and	a5,a5,a2
    80001832:	00f76863          	bltu	a4,a5,80001842 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001836:	8526                	mv	a0,s1
    80001838:	60e2                	ld	ra,24(sp)
    8000183a:	6442                	ld	s0,16(sp)
    8000183c:	64a2                	ld	s1,8(sp)
    8000183e:	6105                	addi	sp,sp,32
    80001840:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001842:	8f99                	sub	a5,a5,a4
    80001844:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001846:	4685                	li	a3,1
    80001848:	0007861b          	sext.w	a2,a5
    8000184c:	85ba                	mv	a1,a4
    8000184e:	00000097          	auipc	ra,0x0
    80001852:	e5e080e7          	jalr	-418(ra) # 800016ac <uvmunmap>
    80001856:	b7c5                	j	80001836 <uvmdealloc+0x26>

0000000080001858 <uvmalloc>:
  if(newsz < oldsz)
    80001858:	0ab66163          	bltu	a2,a1,800018fa <uvmalloc+0xa2>
{
    8000185c:	7139                	addi	sp,sp,-64
    8000185e:	fc06                	sd	ra,56(sp)
    80001860:	f822                	sd	s0,48(sp)
    80001862:	f426                	sd	s1,40(sp)
    80001864:	f04a                	sd	s2,32(sp)
    80001866:	ec4e                	sd	s3,24(sp)
    80001868:	e852                	sd	s4,16(sp)
    8000186a:	e456                	sd	s5,8(sp)
    8000186c:	0080                	addi	s0,sp,64
    8000186e:	8aaa                	mv	s5,a0
    80001870:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001872:	6985                	lui	s3,0x1
    80001874:	19fd                	addi	s3,s3,-1
    80001876:	95ce                	add	a1,a1,s3
    80001878:	79fd                	lui	s3,0xfffff
    8000187a:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000187e:	08c9f063          	bgeu	s3,a2,800018fe <uvmalloc+0xa6>
    80001882:	894e                	mv	s2,s3
    mem = kalloc();
    80001884:	fffff097          	auipc	ra,0xfffff
    80001888:	36c080e7          	jalr	876(ra) # 80000bf0 <kalloc>
    8000188c:	84aa                	mv	s1,a0
    if(mem == 0){
    8000188e:	c51d                	beqz	a0,800018bc <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001890:	6605                	lui	a2,0x1
    80001892:	4581                	li	a1,0
    80001894:	00000097          	auipc	ra,0x0
    80001898:	8b8080e7          	jalr	-1864(ra) # 8000114c <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000189c:	4779                	li	a4,30
    8000189e:	86a6                	mv	a3,s1
    800018a0:	6605                	lui	a2,0x1
    800018a2:	85ca                	mv	a1,s2
    800018a4:	8556                	mv	a0,s5
    800018a6:	00000097          	auipc	ra,0x0
    800018aa:	c82080e7          	jalr	-894(ra) # 80001528 <mappages>
    800018ae:	e905                	bnez	a0,800018de <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800018b0:	6785                	lui	a5,0x1
    800018b2:	993e                	add	s2,s2,a5
    800018b4:	fd4968e3          	bltu	s2,s4,80001884 <uvmalloc+0x2c>
  return newsz;
    800018b8:	8552                	mv	a0,s4
    800018ba:	a809                	j	800018cc <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800018bc:	864e                	mv	a2,s3
    800018be:	85ca                	mv	a1,s2
    800018c0:	8556                	mv	a0,s5
    800018c2:	00000097          	auipc	ra,0x0
    800018c6:	f4e080e7          	jalr	-178(ra) # 80001810 <uvmdealloc>
      return 0;
    800018ca:	4501                	li	a0,0
}
    800018cc:	70e2                	ld	ra,56(sp)
    800018ce:	7442                	ld	s0,48(sp)
    800018d0:	74a2                	ld	s1,40(sp)
    800018d2:	7902                	ld	s2,32(sp)
    800018d4:	69e2                	ld	s3,24(sp)
    800018d6:	6a42                	ld	s4,16(sp)
    800018d8:	6aa2                	ld	s5,8(sp)
    800018da:	6121                	addi	sp,sp,64
    800018dc:	8082                	ret
      kfree(mem);
    800018de:	8526                	mv	a0,s1
    800018e0:	fffff097          	auipc	ra,0xfffff
    800018e4:	14c080e7          	jalr	332(ra) # 80000a2c <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800018e8:	864e                	mv	a2,s3
    800018ea:	85ca                	mv	a1,s2
    800018ec:	8556                	mv	a0,s5
    800018ee:	00000097          	auipc	ra,0x0
    800018f2:	f22080e7          	jalr	-222(ra) # 80001810 <uvmdealloc>
      return 0;
    800018f6:	4501                	li	a0,0
    800018f8:	bfd1                	j	800018cc <uvmalloc+0x74>
    return oldsz;
    800018fa:	852e                	mv	a0,a1
}
    800018fc:	8082                	ret
  return newsz;
    800018fe:	8532                	mv	a0,a2
    80001900:	b7f1                	j	800018cc <uvmalloc+0x74>

0000000080001902 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001902:	7179                	addi	sp,sp,-48
    80001904:	f406                	sd	ra,40(sp)
    80001906:	f022                	sd	s0,32(sp)
    80001908:	ec26                	sd	s1,24(sp)
    8000190a:	e84a                	sd	s2,16(sp)
    8000190c:	e44e                	sd	s3,8(sp)
    8000190e:	e052                	sd	s4,0(sp)
    80001910:	1800                	addi	s0,sp,48
    80001912:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001914:	84aa                	mv	s1,a0
    80001916:	6905                	lui	s2,0x1
    80001918:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000191a:	4985                	li	s3,1
    8000191c:	a821                	j	80001934 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    8000191e:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001920:	0532                	slli	a0,a0,0xc
    80001922:	00000097          	auipc	ra,0x0
    80001926:	fe0080e7          	jalr	-32(ra) # 80001902 <freewalk>
      pagetable[i] = 0;
    8000192a:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000192e:	04a1                	addi	s1,s1,8
    80001930:	03248163          	beq	s1,s2,80001952 <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001934:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001936:	00f57793          	andi	a5,a0,15
    8000193a:	ff3782e3          	beq	a5,s3,8000191e <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000193e:	8905                	andi	a0,a0,1
    80001940:	d57d                	beqz	a0,8000192e <freewalk+0x2c>
      panic("freewalk: leaf");
    80001942:	00007517          	auipc	a0,0x7
    80001946:	8ce50513          	addi	a0,a0,-1842 # 80008210 <digits+0x1d0>
    8000194a:	fffff097          	auipc	ra,0xfffff
    8000194e:	c06080e7          	jalr	-1018(ra) # 80000550 <panic>
    }
  }
  kfree((void*)pagetable);
    80001952:	8552                	mv	a0,s4
    80001954:	fffff097          	auipc	ra,0xfffff
    80001958:	0d8080e7          	jalr	216(ra) # 80000a2c <kfree>
}
    8000195c:	70a2                	ld	ra,40(sp)
    8000195e:	7402                	ld	s0,32(sp)
    80001960:	64e2                	ld	s1,24(sp)
    80001962:	6942                	ld	s2,16(sp)
    80001964:	69a2                	ld	s3,8(sp)
    80001966:	6a02                	ld	s4,0(sp)
    80001968:	6145                	addi	sp,sp,48
    8000196a:	8082                	ret

000000008000196c <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000196c:	1101                	addi	sp,sp,-32
    8000196e:	ec06                	sd	ra,24(sp)
    80001970:	e822                	sd	s0,16(sp)
    80001972:	e426                	sd	s1,8(sp)
    80001974:	1000                	addi	s0,sp,32
    80001976:	84aa                	mv	s1,a0
  if(sz > 0)
    80001978:	e999                	bnez	a1,8000198e <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000197a:	8526                	mv	a0,s1
    8000197c:	00000097          	auipc	ra,0x0
    80001980:	f86080e7          	jalr	-122(ra) # 80001902 <freewalk>
}
    80001984:	60e2                	ld	ra,24(sp)
    80001986:	6442                	ld	s0,16(sp)
    80001988:	64a2                	ld	s1,8(sp)
    8000198a:	6105                	addi	sp,sp,32
    8000198c:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000198e:	6605                	lui	a2,0x1
    80001990:	167d                	addi	a2,a2,-1
    80001992:	962e                	add	a2,a2,a1
    80001994:	4685                	li	a3,1
    80001996:	8231                	srli	a2,a2,0xc
    80001998:	4581                	li	a1,0
    8000199a:	00000097          	auipc	ra,0x0
    8000199e:	d12080e7          	jalr	-750(ra) # 800016ac <uvmunmap>
    800019a2:	bfe1                	j	8000197a <uvmfree+0xe>

00000000800019a4 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800019a4:	c679                	beqz	a2,80001a72 <uvmcopy+0xce>
{
    800019a6:	715d                	addi	sp,sp,-80
    800019a8:	e486                	sd	ra,72(sp)
    800019aa:	e0a2                	sd	s0,64(sp)
    800019ac:	fc26                	sd	s1,56(sp)
    800019ae:	f84a                	sd	s2,48(sp)
    800019b0:	f44e                	sd	s3,40(sp)
    800019b2:	f052                	sd	s4,32(sp)
    800019b4:	ec56                	sd	s5,24(sp)
    800019b6:	e85a                	sd	s6,16(sp)
    800019b8:	e45e                	sd	s7,8(sp)
    800019ba:	0880                	addi	s0,sp,80
    800019bc:	8b2a                	mv	s6,a0
    800019be:	8aae                	mv	s5,a1
    800019c0:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800019c2:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800019c4:	4601                	li	a2,0
    800019c6:	85ce                	mv	a1,s3
    800019c8:	855a                	mv	a0,s6
    800019ca:	00000097          	auipc	ra,0x0
    800019ce:	a52080e7          	jalr	-1454(ra) # 8000141c <walk>
    800019d2:	c531                	beqz	a0,80001a1e <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800019d4:	6118                	ld	a4,0(a0)
    800019d6:	00177793          	andi	a5,a4,1
    800019da:	cbb1                	beqz	a5,80001a2e <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800019dc:	00a75593          	srli	a1,a4,0xa
    800019e0:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800019e4:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800019e8:	fffff097          	auipc	ra,0xfffff
    800019ec:	208080e7          	jalr	520(ra) # 80000bf0 <kalloc>
    800019f0:	892a                	mv	s2,a0
    800019f2:	c939                	beqz	a0,80001a48 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800019f4:	6605                	lui	a2,0x1
    800019f6:	85de                	mv	a1,s7
    800019f8:	fffff097          	auipc	ra,0xfffff
    800019fc:	7b4080e7          	jalr	1972(ra) # 800011ac <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001a00:	8726                	mv	a4,s1
    80001a02:	86ca                	mv	a3,s2
    80001a04:	6605                	lui	a2,0x1
    80001a06:	85ce                	mv	a1,s3
    80001a08:	8556                	mv	a0,s5
    80001a0a:	00000097          	auipc	ra,0x0
    80001a0e:	b1e080e7          	jalr	-1250(ra) # 80001528 <mappages>
    80001a12:	e515                	bnez	a0,80001a3e <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001a14:	6785                	lui	a5,0x1
    80001a16:	99be                	add	s3,s3,a5
    80001a18:	fb49e6e3          	bltu	s3,s4,800019c4 <uvmcopy+0x20>
    80001a1c:	a081                	j	80001a5c <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001a1e:	00007517          	auipc	a0,0x7
    80001a22:	80250513          	addi	a0,a0,-2046 # 80008220 <digits+0x1e0>
    80001a26:	fffff097          	auipc	ra,0xfffff
    80001a2a:	b2a080e7          	jalr	-1238(ra) # 80000550 <panic>
      panic("uvmcopy: page not present");
    80001a2e:	00007517          	auipc	a0,0x7
    80001a32:	81250513          	addi	a0,a0,-2030 # 80008240 <digits+0x200>
    80001a36:	fffff097          	auipc	ra,0xfffff
    80001a3a:	b1a080e7          	jalr	-1254(ra) # 80000550 <panic>
      kfree(mem);
    80001a3e:	854a                	mv	a0,s2
    80001a40:	fffff097          	auipc	ra,0xfffff
    80001a44:	fec080e7          	jalr	-20(ra) # 80000a2c <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001a48:	4685                	li	a3,1
    80001a4a:	00c9d613          	srli	a2,s3,0xc
    80001a4e:	4581                	li	a1,0
    80001a50:	8556                	mv	a0,s5
    80001a52:	00000097          	auipc	ra,0x0
    80001a56:	c5a080e7          	jalr	-934(ra) # 800016ac <uvmunmap>
  return -1;
    80001a5a:	557d                	li	a0,-1
}
    80001a5c:	60a6                	ld	ra,72(sp)
    80001a5e:	6406                	ld	s0,64(sp)
    80001a60:	74e2                	ld	s1,56(sp)
    80001a62:	7942                	ld	s2,48(sp)
    80001a64:	79a2                	ld	s3,40(sp)
    80001a66:	7a02                	ld	s4,32(sp)
    80001a68:	6ae2                	ld	s5,24(sp)
    80001a6a:	6b42                	ld	s6,16(sp)
    80001a6c:	6ba2                	ld	s7,8(sp)
    80001a6e:	6161                	addi	sp,sp,80
    80001a70:	8082                	ret
  return 0;
    80001a72:	4501                	li	a0,0
}
    80001a74:	8082                	ret

0000000080001a76 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001a76:	1141                	addi	sp,sp,-16
    80001a78:	e406                	sd	ra,8(sp)
    80001a7a:	e022                	sd	s0,0(sp)
    80001a7c:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001a7e:	4601                	li	a2,0
    80001a80:	00000097          	auipc	ra,0x0
    80001a84:	99c080e7          	jalr	-1636(ra) # 8000141c <walk>
  if(pte == 0)
    80001a88:	c901                	beqz	a0,80001a98 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001a8a:	611c                	ld	a5,0(a0)
    80001a8c:	9bbd                	andi	a5,a5,-17
    80001a8e:	e11c                	sd	a5,0(a0)
}
    80001a90:	60a2                	ld	ra,8(sp)
    80001a92:	6402                	ld	s0,0(sp)
    80001a94:	0141                	addi	sp,sp,16
    80001a96:	8082                	ret
    panic("uvmclear");
    80001a98:	00006517          	auipc	a0,0x6
    80001a9c:	7c850513          	addi	a0,a0,1992 # 80008260 <digits+0x220>
    80001aa0:	fffff097          	auipc	ra,0xfffff
    80001aa4:	ab0080e7          	jalr	-1360(ra) # 80000550 <panic>

0000000080001aa8 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001aa8:	c6bd                	beqz	a3,80001b16 <copyout+0x6e>
{
    80001aaa:	715d                	addi	sp,sp,-80
    80001aac:	e486                	sd	ra,72(sp)
    80001aae:	e0a2                	sd	s0,64(sp)
    80001ab0:	fc26                	sd	s1,56(sp)
    80001ab2:	f84a                	sd	s2,48(sp)
    80001ab4:	f44e                	sd	s3,40(sp)
    80001ab6:	f052                	sd	s4,32(sp)
    80001ab8:	ec56                	sd	s5,24(sp)
    80001aba:	e85a                	sd	s6,16(sp)
    80001abc:	e45e                	sd	s7,8(sp)
    80001abe:	e062                	sd	s8,0(sp)
    80001ac0:	0880                	addi	s0,sp,80
    80001ac2:	8b2a                	mv	s6,a0
    80001ac4:	8c2e                	mv	s8,a1
    80001ac6:	8a32                	mv	s4,a2
    80001ac8:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001aca:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001acc:	6a85                	lui	s5,0x1
    80001ace:	a015                	j	80001af2 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001ad0:	9562                	add	a0,a0,s8
    80001ad2:	0004861b          	sext.w	a2,s1
    80001ad6:	85d2                	mv	a1,s4
    80001ad8:	41250533          	sub	a0,a0,s2
    80001adc:	fffff097          	auipc	ra,0xfffff
    80001ae0:	6d0080e7          	jalr	1744(ra) # 800011ac <memmove>

    len -= n;
    80001ae4:	409989b3          	sub	s3,s3,s1
    src += n;
    80001ae8:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001aea:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001aee:	02098263          	beqz	s3,80001b12 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001af2:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001af6:	85ca                	mv	a1,s2
    80001af8:	855a                	mv	a0,s6
    80001afa:	00000097          	auipc	ra,0x0
    80001afe:	9ec080e7          	jalr	-1556(ra) # 800014e6 <walkaddr>
    if(pa0 == 0)
    80001b02:	cd01                	beqz	a0,80001b1a <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001b04:	418904b3          	sub	s1,s2,s8
    80001b08:	94d6                	add	s1,s1,s5
    if(n > len)
    80001b0a:	fc99f3e3          	bgeu	s3,s1,80001ad0 <copyout+0x28>
    80001b0e:	84ce                	mv	s1,s3
    80001b10:	b7c1                	j	80001ad0 <copyout+0x28>
  }
  return 0;
    80001b12:	4501                	li	a0,0
    80001b14:	a021                	j	80001b1c <copyout+0x74>
    80001b16:	4501                	li	a0,0
}
    80001b18:	8082                	ret
      return -1;
    80001b1a:	557d                	li	a0,-1
}
    80001b1c:	60a6                	ld	ra,72(sp)
    80001b1e:	6406                	ld	s0,64(sp)
    80001b20:	74e2                	ld	s1,56(sp)
    80001b22:	7942                	ld	s2,48(sp)
    80001b24:	79a2                	ld	s3,40(sp)
    80001b26:	7a02                	ld	s4,32(sp)
    80001b28:	6ae2                	ld	s5,24(sp)
    80001b2a:	6b42                	ld	s6,16(sp)
    80001b2c:	6ba2                	ld	s7,8(sp)
    80001b2e:	6c02                	ld	s8,0(sp)
    80001b30:	6161                	addi	sp,sp,80
    80001b32:	8082                	ret

0000000080001b34 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001b34:	c6bd                	beqz	a3,80001ba2 <copyin+0x6e>
{
    80001b36:	715d                	addi	sp,sp,-80
    80001b38:	e486                	sd	ra,72(sp)
    80001b3a:	e0a2                	sd	s0,64(sp)
    80001b3c:	fc26                	sd	s1,56(sp)
    80001b3e:	f84a                	sd	s2,48(sp)
    80001b40:	f44e                	sd	s3,40(sp)
    80001b42:	f052                	sd	s4,32(sp)
    80001b44:	ec56                	sd	s5,24(sp)
    80001b46:	e85a                	sd	s6,16(sp)
    80001b48:	e45e                	sd	s7,8(sp)
    80001b4a:	e062                	sd	s8,0(sp)
    80001b4c:	0880                	addi	s0,sp,80
    80001b4e:	8b2a                	mv	s6,a0
    80001b50:	8a2e                	mv	s4,a1
    80001b52:	8c32                	mv	s8,a2
    80001b54:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001b56:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001b58:	6a85                	lui	s5,0x1
    80001b5a:	a015                	j	80001b7e <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001b5c:	9562                	add	a0,a0,s8
    80001b5e:	0004861b          	sext.w	a2,s1
    80001b62:	412505b3          	sub	a1,a0,s2
    80001b66:	8552                	mv	a0,s4
    80001b68:	fffff097          	auipc	ra,0xfffff
    80001b6c:	644080e7          	jalr	1604(ra) # 800011ac <memmove>

    len -= n;
    80001b70:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001b74:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001b76:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001b7a:	02098263          	beqz	s3,80001b9e <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001b7e:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001b82:	85ca                	mv	a1,s2
    80001b84:	855a                	mv	a0,s6
    80001b86:	00000097          	auipc	ra,0x0
    80001b8a:	960080e7          	jalr	-1696(ra) # 800014e6 <walkaddr>
    if(pa0 == 0)
    80001b8e:	cd01                	beqz	a0,80001ba6 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    80001b90:	418904b3          	sub	s1,s2,s8
    80001b94:	94d6                	add	s1,s1,s5
    if(n > len)
    80001b96:	fc99f3e3          	bgeu	s3,s1,80001b5c <copyin+0x28>
    80001b9a:	84ce                	mv	s1,s3
    80001b9c:	b7c1                	j	80001b5c <copyin+0x28>
  }
  return 0;
    80001b9e:	4501                	li	a0,0
    80001ba0:	a021                	j	80001ba8 <copyin+0x74>
    80001ba2:	4501                	li	a0,0
}
    80001ba4:	8082                	ret
      return -1;
    80001ba6:	557d                	li	a0,-1
}
    80001ba8:	60a6                	ld	ra,72(sp)
    80001baa:	6406                	ld	s0,64(sp)
    80001bac:	74e2                	ld	s1,56(sp)
    80001bae:	7942                	ld	s2,48(sp)
    80001bb0:	79a2                	ld	s3,40(sp)
    80001bb2:	7a02                	ld	s4,32(sp)
    80001bb4:	6ae2                	ld	s5,24(sp)
    80001bb6:	6b42                	ld	s6,16(sp)
    80001bb8:	6ba2                	ld	s7,8(sp)
    80001bba:	6c02                	ld	s8,0(sp)
    80001bbc:	6161                	addi	sp,sp,80
    80001bbe:	8082                	ret

0000000080001bc0 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001bc0:	c6c5                	beqz	a3,80001c68 <copyinstr+0xa8>
{
    80001bc2:	715d                	addi	sp,sp,-80
    80001bc4:	e486                	sd	ra,72(sp)
    80001bc6:	e0a2                	sd	s0,64(sp)
    80001bc8:	fc26                	sd	s1,56(sp)
    80001bca:	f84a                	sd	s2,48(sp)
    80001bcc:	f44e                	sd	s3,40(sp)
    80001bce:	f052                	sd	s4,32(sp)
    80001bd0:	ec56                	sd	s5,24(sp)
    80001bd2:	e85a                	sd	s6,16(sp)
    80001bd4:	e45e                	sd	s7,8(sp)
    80001bd6:	0880                	addi	s0,sp,80
    80001bd8:	8a2a                	mv	s4,a0
    80001bda:	8b2e                	mv	s6,a1
    80001bdc:	8bb2                	mv	s7,a2
    80001bde:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001be0:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001be2:	6985                	lui	s3,0x1
    80001be4:	a035                	j	80001c10 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001be6:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001bea:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001bec:	0017b793          	seqz	a5,a5
    80001bf0:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001bf4:	60a6                	ld	ra,72(sp)
    80001bf6:	6406                	ld	s0,64(sp)
    80001bf8:	74e2                	ld	s1,56(sp)
    80001bfa:	7942                	ld	s2,48(sp)
    80001bfc:	79a2                	ld	s3,40(sp)
    80001bfe:	7a02                	ld	s4,32(sp)
    80001c00:	6ae2                	ld	s5,24(sp)
    80001c02:	6b42                	ld	s6,16(sp)
    80001c04:	6ba2                	ld	s7,8(sp)
    80001c06:	6161                	addi	sp,sp,80
    80001c08:	8082                	ret
    srcva = va0 + PGSIZE;
    80001c0a:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001c0e:	c8a9                	beqz	s1,80001c60 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    80001c10:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001c14:	85ca                	mv	a1,s2
    80001c16:	8552                	mv	a0,s4
    80001c18:	00000097          	auipc	ra,0x0
    80001c1c:	8ce080e7          	jalr	-1842(ra) # 800014e6 <walkaddr>
    if(pa0 == 0)
    80001c20:	c131                	beqz	a0,80001c64 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001c22:	41790833          	sub	a6,s2,s7
    80001c26:	984e                	add	a6,a6,s3
    if(n > max)
    80001c28:	0104f363          	bgeu	s1,a6,80001c2e <copyinstr+0x6e>
    80001c2c:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001c2e:	955e                	add	a0,a0,s7
    80001c30:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001c34:	fc080be3          	beqz	a6,80001c0a <copyinstr+0x4a>
    80001c38:	985a                	add	a6,a6,s6
    80001c3a:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001c3c:	41650633          	sub	a2,a0,s6
    80001c40:	14fd                	addi	s1,s1,-1
    80001c42:	9b26                	add	s6,s6,s1
    80001c44:	00f60733          	add	a4,a2,a5
    80001c48:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd2fd8>
    80001c4c:	df49                	beqz	a4,80001be6 <copyinstr+0x26>
        *dst = *p;
    80001c4e:	00e78023          	sb	a4,0(a5)
      --max;
    80001c52:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001c56:	0785                	addi	a5,a5,1
    while(n > 0){
    80001c58:	ff0796e3          	bne	a5,a6,80001c44 <copyinstr+0x84>
      dst++;
    80001c5c:	8b42                	mv	s6,a6
    80001c5e:	b775                	j	80001c0a <copyinstr+0x4a>
    80001c60:	4781                	li	a5,0
    80001c62:	b769                	j	80001bec <copyinstr+0x2c>
      return -1;
    80001c64:	557d                	li	a0,-1
    80001c66:	b779                	j	80001bf4 <copyinstr+0x34>
  int got_null = 0;
    80001c68:	4781                	li	a5,0
  if(got_null){
    80001c6a:	0017b793          	seqz	a5,a5
    80001c6e:	40f00533          	neg	a0,a5
}
    80001c72:	8082                	ret

0000000080001c74 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001c74:	1101                	addi	sp,sp,-32
    80001c76:	ec06                	sd	ra,24(sp)
    80001c78:	e822                	sd	s0,16(sp)
    80001c7a:	e426                	sd	s1,8(sp)
    80001c7c:	1000                	addi	s0,sp,32
    80001c7e:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001c80:	fffff097          	auipc	ra,0xfffff
    80001c84:	072080e7          	jalr	114(ra) # 80000cf2 <holding>
    80001c88:	c909                	beqz	a0,80001c9a <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001c8a:	789c                	ld	a5,48(s1)
    80001c8c:	00978f63          	beq	a5,s1,80001caa <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001c90:	60e2                	ld	ra,24(sp)
    80001c92:	6442                	ld	s0,16(sp)
    80001c94:	64a2                	ld	s1,8(sp)
    80001c96:	6105                	addi	sp,sp,32
    80001c98:	8082                	ret
    panic("wakeup1");
    80001c9a:	00006517          	auipc	a0,0x6
    80001c9e:	5d650513          	addi	a0,a0,1494 # 80008270 <digits+0x230>
    80001ca2:	fffff097          	auipc	ra,0xfffff
    80001ca6:	8ae080e7          	jalr	-1874(ra) # 80000550 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001caa:	5098                	lw	a4,32(s1)
    80001cac:	4785                	li	a5,1
    80001cae:	fef711e3          	bne	a4,a5,80001c90 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001cb2:	4789                	li	a5,2
    80001cb4:	d09c                	sw	a5,32(s1)
}
    80001cb6:	bfe9                	j	80001c90 <wakeup1+0x1c>

0000000080001cb8 <procinit>:
{
    80001cb8:	715d                	addi	sp,sp,-80
    80001cba:	e486                	sd	ra,72(sp)
    80001cbc:	e0a2                	sd	s0,64(sp)
    80001cbe:	fc26                	sd	s1,56(sp)
    80001cc0:	f84a                	sd	s2,48(sp)
    80001cc2:	f44e                	sd	s3,40(sp)
    80001cc4:	f052                	sd	s4,32(sp)
    80001cc6:	ec56                	sd	s5,24(sp)
    80001cc8:	e85a                	sd	s6,16(sp)
    80001cca:	e45e                	sd	s7,8(sp)
    80001ccc:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001cce:	00006597          	auipc	a1,0x6
    80001cd2:	5aa58593          	addi	a1,a1,1450 # 80008278 <digits+0x238>
    80001cd6:	00010517          	auipc	a0,0x10
    80001cda:	6b250513          	addi	a0,a0,1714 # 80012388 <pid_lock>
    80001cde:	fffff097          	auipc	ra,0xfffff
    80001ce2:	20a080e7          	jalr	522(ra) # 80000ee8 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ce6:	00011917          	auipc	s2,0x11
    80001cea:	ac290913          	addi	s2,s2,-1342 # 800127a8 <proc>
      initlock(&p->lock, "proc");
    80001cee:	00006b97          	auipc	s7,0x6
    80001cf2:	592b8b93          	addi	s7,s7,1426 # 80008280 <digits+0x240>
      uint64 va = KSTACK((int) (p - proc));
    80001cf6:	8b4a                	mv	s6,s2
    80001cf8:	00006a97          	auipc	s5,0x6
    80001cfc:	308a8a93          	addi	s5,s5,776 # 80008000 <etext>
    80001d00:	040009b7          	lui	s3,0x4000
    80001d04:	19fd                	addi	s3,s3,-1
    80001d06:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d08:	00016a17          	auipc	s4,0x16
    80001d0c:	6a0a0a13          	addi	s4,s4,1696 # 800183a8 <tickslock>
      initlock(&p->lock, "proc");
    80001d10:	85de                	mv	a1,s7
    80001d12:	854a                	mv	a0,s2
    80001d14:	fffff097          	auipc	ra,0xfffff
    80001d18:	1d4080e7          	jalr	468(ra) # 80000ee8 <initlock>
      char *pa = kalloc();
    80001d1c:	fffff097          	auipc	ra,0xfffff
    80001d20:	ed4080e7          	jalr	-300(ra) # 80000bf0 <kalloc>
    80001d24:	85aa                	mv	a1,a0
      if(pa == 0)
    80001d26:	c929                	beqz	a0,80001d78 <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    80001d28:	416904b3          	sub	s1,s2,s6
    80001d2c:	8491                	srai	s1,s1,0x4
    80001d2e:	000ab783          	ld	a5,0(s5)
    80001d32:	02f484b3          	mul	s1,s1,a5
    80001d36:	2485                	addiw	s1,s1,1
    80001d38:	00d4949b          	slliw	s1,s1,0xd
    80001d3c:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001d40:	4699                	li	a3,6
    80001d42:	6605                	lui	a2,0x1
    80001d44:	8526                	mv	a0,s1
    80001d46:	00000097          	auipc	ra,0x0
    80001d4a:	870080e7          	jalr	-1936(ra) # 800015b6 <kvmmap>
      p->kstack = va;
    80001d4e:	04993423          	sd	s1,72(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d52:	17090913          	addi	s2,s2,368
    80001d56:	fb491de3          	bne	s2,s4,80001d10 <procinit+0x58>
  kvminithart();
    80001d5a:	fffff097          	auipc	ra,0xfffff
    80001d5e:	768080e7          	jalr	1896(ra) # 800014c2 <kvminithart>
}
    80001d62:	60a6                	ld	ra,72(sp)
    80001d64:	6406                	ld	s0,64(sp)
    80001d66:	74e2                	ld	s1,56(sp)
    80001d68:	7942                	ld	s2,48(sp)
    80001d6a:	79a2                	ld	s3,40(sp)
    80001d6c:	7a02                	ld	s4,32(sp)
    80001d6e:	6ae2                	ld	s5,24(sp)
    80001d70:	6b42                	ld	s6,16(sp)
    80001d72:	6ba2                	ld	s7,8(sp)
    80001d74:	6161                	addi	sp,sp,80
    80001d76:	8082                	ret
        panic("kalloc");
    80001d78:	00006517          	auipc	a0,0x6
    80001d7c:	51050513          	addi	a0,a0,1296 # 80008288 <digits+0x248>
    80001d80:	ffffe097          	auipc	ra,0xffffe
    80001d84:	7d0080e7          	jalr	2000(ra) # 80000550 <panic>

0000000080001d88 <cpuid>:
{
    80001d88:	1141                	addi	sp,sp,-16
    80001d8a:	e422                	sd	s0,8(sp)
    80001d8c:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001d8e:	8512                	mv	a0,tp
}
    80001d90:	2501                	sext.w	a0,a0
    80001d92:	6422                	ld	s0,8(sp)
    80001d94:	0141                	addi	sp,sp,16
    80001d96:	8082                	ret

0000000080001d98 <mycpu>:
mycpu(void) {
    80001d98:	1141                	addi	sp,sp,-16
    80001d9a:	e422                	sd	s0,8(sp)
    80001d9c:	0800                	addi	s0,sp,16
    80001d9e:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001da0:	2781                	sext.w	a5,a5
    80001da2:	079e                	slli	a5,a5,0x7
}
    80001da4:	00010517          	auipc	a0,0x10
    80001da8:	60450513          	addi	a0,a0,1540 # 800123a8 <cpus>
    80001dac:	953e                	add	a0,a0,a5
    80001dae:	6422                	ld	s0,8(sp)
    80001db0:	0141                	addi	sp,sp,16
    80001db2:	8082                	ret

0000000080001db4 <myproc>:
myproc(void) {
    80001db4:	1101                	addi	sp,sp,-32
    80001db6:	ec06                	sd	ra,24(sp)
    80001db8:	e822                	sd	s0,16(sp)
    80001dba:	e426                	sd	s1,8(sp)
    80001dbc:	1000                	addi	s0,sp,32
  push_off();
    80001dbe:	fffff097          	auipc	ra,0xfffff
    80001dc2:	f62080e7          	jalr	-158(ra) # 80000d20 <push_off>
    80001dc6:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001dc8:	2781                	sext.w	a5,a5
    80001dca:	079e                	slli	a5,a5,0x7
    80001dcc:	00010717          	auipc	a4,0x10
    80001dd0:	5bc70713          	addi	a4,a4,1468 # 80012388 <pid_lock>
    80001dd4:	97ba                	add	a5,a5,a4
    80001dd6:	7384                	ld	s1,32(a5)
  pop_off();
    80001dd8:	fffff097          	auipc	ra,0xfffff
    80001ddc:	004080e7          	jalr	4(ra) # 80000ddc <pop_off>
}
    80001de0:	8526                	mv	a0,s1
    80001de2:	60e2                	ld	ra,24(sp)
    80001de4:	6442                	ld	s0,16(sp)
    80001de6:	64a2                	ld	s1,8(sp)
    80001de8:	6105                	addi	sp,sp,32
    80001dea:	8082                	ret

0000000080001dec <forkret>:
{
    80001dec:	1141                	addi	sp,sp,-16
    80001dee:	e406                	sd	ra,8(sp)
    80001df0:	e022                	sd	s0,0(sp)
    80001df2:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001df4:	00000097          	auipc	ra,0x0
    80001df8:	fc0080e7          	jalr	-64(ra) # 80001db4 <myproc>
    80001dfc:	fffff097          	auipc	ra,0xfffff
    80001e00:	040080e7          	jalr	64(ra) # 80000e3c <release>
  if (first) {
    80001e04:	00007797          	auipc	a5,0x7
    80001e08:	acc7a783          	lw	a5,-1332(a5) # 800088d0 <first.1672>
    80001e0c:	eb89                	bnez	a5,80001e1e <forkret+0x32>
  usertrapret();
    80001e0e:	00001097          	auipc	ra,0x1
    80001e12:	c1c080e7          	jalr	-996(ra) # 80002a2a <usertrapret>
}
    80001e16:	60a2                	ld	ra,8(sp)
    80001e18:	6402                	ld	s0,0(sp)
    80001e1a:	0141                	addi	sp,sp,16
    80001e1c:	8082                	ret
    first = 0;
    80001e1e:	00007797          	auipc	a5,0x7
    80001e22:	aa07a923          	sw	zero,-1358(a5) # 800088d0 <first.1672>
    fsinit(ROOTDEV);
    80001e26:	4505                	li	a0,1
    80001e28:	00002097          	auipc	ra,0x2
    80001e2c:	ad8080e7          	jalr	-1320(ra) # 80003900 <fsinit>
    80001e30:	bff9                	j	80001e0e <forkret+0x22>

0000000080001e32 <allocpid>:
allocpid() {
    80001e32:	1101                	addi	sp,sp,-32
    80001e34:	ec06                	sd	ra,24(sp)
    80001e36:	e822                	sd	s0,16(sp)
    80001e38:	e426                	sd	s1,8(sp)
    80001e3a:	e04a                	sd	s2,0(sp)
    80001e3c:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001e3e:	00010917          	auipc	s2,0x10
    80001e42:	54a90913          	addi	s2,s2,1354 # 80012388 <pid_lock>
    80001e46:	854a                	mv	a0,s2
    80001e48:	fffff097          	auipc	ra,0xfffff
    80001e4c:	f24080e7          	jalr	-220(ra) # 80000d6c <acquire>
  pid = nextpid;
    80001e50:	00007797          	auipc	a5,0x7
    80001e54:	a8478793          	addi	a5,a5,-1404 # 800088d4 <nextpid>
    80001e58:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001e5a:	0014871b          	addiw	a4,s1,1
    80001e5e:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001e60:	854a                	mv	a0,s2
    80001e62:	fffff097          	auipc	ra,0xfffff
    80001e66:	fda080e7          	jalr	-38(ra) # 80000e3c <release>
}
    80001e6a:	8526                	mv	a0,s1
    80001e6c:	60e2                	ld	ra,24(sp)
    80001e6e:	6442                	ld	s0,16(sp)
    80001e70:	64a2                	ld	s1,8(sp)
    80001e72:	6902                	ld	s2,0(sp)
    80001e74:	6105                	addi	sp,sp,32
    80001e76:	8082                	ret

0000000080001e78 <proc_pagetable>:
{
    80001e78:	1101                	addi	sp,sp,-32
    80001e7a:	ec06                	sd	ra,24(sp)
    80001e7c:	e822                	sd	s0,16(sp)
    80001e7e:	e426                	sd	s1,8(sp)
    80001e80:	e04a                	sd	s2,0(sp)
    80001e82:	1000                	addi	s0,sp,32
    80001e84:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001e86:	00000097          	auipc	ra,0x0
    80001e8a:	8ea080e7          	jalr	-1814(ra) # 80001770 <uvmcreate>
    80001e8e:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001e90:	c121                	beqz	a0,80001ed0 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001e92:	4729                	li	a4,10
    80001e94:	00005697          	auipc	a3,0x5
    80001e98:	16c68693          	addi	a3,a3,364 # 80007000 <_trampoline>
    80001e9c:	6605                	lui	a2,0x1
    80001e9e:	040005b7          	lui	a1,0x4000
    80001ea2:	15fd                	addi	a1,a1,-1
    80001ea4:	05b2                	slli	a1,a1,0xc
    80001ea6:	fffff097          	auipc	ra,0xfffff
    80001eaa:	682080e7          	jalr	1666(ra) # 80001528 <mappages>
    80001eae:	02054863          	bltz	a0,80001ede <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001eb2:	4719                	li	a4,6
    80001eb4:	06093683          	ld	a3,96(s2)
    80001eb8:	6605                	lui	a2,0x1
    80001eba:	020005b7          	lui	a1,0x2000
    80001ebe:	15fd                	addi	a1,a1,-1
    80001ec0:	05b6                	slli	a1,a1,0xd
    80001ec2:	8526                	mv	a0,s1
    80001ec4:	fffff097          	auipc	ra,0xfffff
    80001ec8:	664080e7          	jalr	1636(ra) # 80001528 <mappages>
    80001ecc:	02054163          	bltz	a0,80001eee <proc_pagetable+0x76>
}
    80001ed0:	8526                	mv	a0,s1
    80001ed2:	60e2                	ld	ra,24(sp)
    80001ed4:	6442                	ld	s0,16(sp)
    80001ed6:	64a2                	ld	s1,8(sp)
    80001ed8:	6902                	ld	s2,0(sp)
    80001eda:	6105                	addi	sp,sp,32
    80001edc:	8082                	ret
    uvmfree(pagetable, 0);
    80001ede:	4581                	li	a1,0
    80001ee0:	8526                	mv	a0,s1
    80001ee2:	00000097          	auipc	ra,0x0
    80001ee6:	a8a080e7          	jalr	-1398(ra) # 8000196c <uvmfree>
    return 0;
    80001eea:	4481                	li	s1,0
    80001eec:	b7d5                	j	80001ed0 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001eee:	4681                	li	a3,0
    80001ef0:	4605                	li	a2,1
    80001ef2:	040005b7          	lui	a1,0x4000
    80001ef6:	15fd                	addi	a1,a1,-1
    80001ef8:	05b2                	slli	a1,a1,0xc
    80001efa:	8526                	mv	a0,s1
    80001efc:	fffff097          	auipc	ra,0xfffff
    80001f00:	7b0080e7          	jalr	1968(ra) # 800016ac <uvmunmap>
    uvmfree(pagetable, 0);
    80001f04:	4581                	li	a1,0
    80001f06:	8526                	mv	a0,s1
    80001f08:	00000097          	auipc	ra,0x0
    80001f0c:	a64080e7          	jalr	-1436(ra) # 8000196c <uvmfree>
    return 0;
    80001f10:	4481                	li	s1,0
    80001f12:	bf7d                	j	80001ed0 <proc_pagetable+0x58>

0000000080001f14 <proc_freepagetable>:
{
    80001f14:	1101                	addi	sp,sp,-32
    80001f16:	ec06                	sd	ra,24(sp)
    80001f18:	e822                	sd	s0,16(sp)
    80001f1a:	e426                	sd	s1,8(sp)
    80001f1c:	e04a                	sd	s2,0(sp)
    80001f1e:	1000                	addi	s0,sp,32
    80001f20:	84aa                	mv	s1,a0
    80001f22:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001f24:	4681                	li	a3,0
    80001f26:	4605                	li	a2,1
    80001f28:	040005b7          	lui	a1,0x4000
    80001f2c:	15fd                	addi	a1,a1,-1
    80001f2e:	05b2                	slli	a1,a1,0xc
    80001f30:	fffff097          	auipc	ra,0xfffff
    80001f34:	77c080e7          	jalr	1916(ra) # 800016ac <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001f38:	4681                	li	a3,0
    80001f3a:	4605                	li	a2,1
    80001f3c:	020005b7          	lui	a1,0x2000
    80001f40:	15fd                	addi	a1,a1,-1
    80001f42:	05b6                	slli	a1,a1,0xd
    80001f44:	8526                	mv	a0,s1
    80001f46:	fffff097          	auipc	ra,0xfffff
    80001f4a:	766080e7          	jalr	1894(ra) # 800016ac <uvmunmap>
  uvmfree(pagetable, sz);
    80001f4e:	85ca                	mv	a1,s2
    80001f50:	8526                	mv	a0,s1
    80001f52:	00000097          	auipc	ra,0x0
    80001f56:	a1a080e7          	jalr	-1510(ra) # 8000196c <uvmfree>
}
    80001f5a:	60e2                	ld	ra,24(sp)
    80001f5c:	6442                	ld	s0,16(sp)
    80001f5e:	64a2                	ld	s1,8(sp)
    80001f60:	6902                	ld	s2,0(sp)
    80001f62:	6105                	addi	sp,sp,32
    80001f64:	8082                	ret

0000000080001f66 <freeproc>:
{
    80001f66:	1101                	addi	sp,sp,-32
    80001f68:	ec06                	sd	ra,24(sp)
    80001f6a:	e822                	sd	s0,16(sp)
    80001f6c:	e426                	sd	s1,8(sp)
    80001f6e:	1000                	addi	s0,sp,32
    80001f70:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001f72:	7128                	ld	a0,96(a0)
    80001f74:	c509                	beqz	a0,80001f7e <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001f76:	fffff097          	auipc	ra,0xfffff
    80001f7a:	ab6080e7          	jalr	-1354(ra) # 80000a2c <kfree>
  p->trapframe = 0;
    80001f7e:	0604b023          	sd	zero,96(s1)
  if(p->pagetable)
    80001f82:	6ca8                	ld	a0,88(s1)
    80001f84:	c511                	beqz	a0,80001f90 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001f86:	68ac                	ld	a1,80(s1)
    80001f88:	00000097          	auipc	ra,0x0
    80001f8c:	f8c080e7          	jalr	-116(ra) # 80001f14 <proc_freepagetable>
  p->pagetable = 0;
    80001f90:	0404bc23          	sd	zero,88(s1)
  p->sz = 0;
    80001f94:	0404b823          	sd	zero,80(s1)
  p->pid = 0;
    80001f98:	0404a023          	sw	zero,64(s1)
  p->parent = 0;
    80001f9c:	0204b423          	sd	zero,40(s1)
  p->name[0] = 0;
    80001fa0:	16048023          	sb	zero,352(s1)
  p->chan = 0;
    80001fa4:	0204b823          	sd	zero,48(s1)
  p->killed = 0;
    80001fa8:	0204ac23          	sw	zero,56(s1)
  p->xstate = 0;
    80001fac:	0204ae23          	sw	zero,60(s1)
  p->state = UNUSED;
    80001fb0:	0204a023          	sw	zero,32(s1)
}
    80001fb4:	60e2                	ld	ra,24(sp)
    80001fb6:	6442                	ld	s0,16(sp)
    80001fb8:	64a2                	ld	s1,8(sp)
    80001fba:	6105                	addi	sp,sp,32
    80001fbc:	8082                	ret

0000000080001fbe <allocproc>:
{
    80001fbe:	1101                	addi	sp,sp,-32
    80001fc0:	ec06                	sd	ra,24(sp)
    80001fc2:	e822                	sd	s0,16(sp)
    80001fc4:	e426                	sd	s1,8(sp)
    80001fc6:	e04a                	sd	s2,0(sp)
    80001fc8:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001fca:	00010497          	auipc	s1,0x10
    80001fce:	7de48493          	addi	s1,s1,2014 # 800127a8 <proc>
    80001fd2:	00016917          	auipc	s2,0x16
    80001fd6:	3d690913          	addi	s2,s2,982 # 800183a8 <tickslock>
    acquire(&p->lock);
    80001fda:	8526                	mv	a0,s1
    80001fdc:	fffff097          	auipc	ra,0xfffff
    80001fe0:	d90080e7          	jalr	-624(ra) # 80000d6c <acquire>
    if(p->state == UNUSED) {
    80001fe4:	509c                	lw	a5,32(s1)
    80001fe6:	cf81                	beqz	a5,80001ffe <allocproc+0x40>
      release(&p->lock);
    80001fe8:	8526                	mv	a0,s1
    80001fea:	fffff097          	auipc	ra,0xfffff
    80001fee:	e52080e7          	jalr	-430(ra) # 80000e3c <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ff2:	17048493          	addi	s1,s1,368
    80001ff6:	ff2492e3          	bne	s1,s2,80001fda <allocproc+0x1c>
  return 0;
    80001ffa:	4481                	li	s1,0
    80001ffc:	a0b9                	j	8000204a <allocproc+0x8c>
  p->pid = allocpid();
    80001ffe:	00000097          	auipc	ra,0x0
    80002002:	e34080e7          	jalr	-460(ra) # 80001e32 <allocpid>
    80002006:	c0a8                	sw	a0,64(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80002008:	fffff097          	auipc	ra,0xfffff
    8000200c:	be8080e7          	jalr	-1048(ra) # 80000bf0 <kalloc>
    80002010:	892a                	mv	s2,a0
    80002012:	f0a8                	sd	a0,96(s1)
    80002014:	c131                	beqz	a0,80002058 <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80002016:	8526                	mv	a0,s1
    80002018:	00000097          	auipc	ra,0x0
    8000201c:	e60080e7          	jalr	-416(ra) # 80001e78 <proc_pagetable>
    80002020:	892a                	mv	s2,a0
    80002022:	eca8                	sd	a0,88(s1)
  if(p->pagetable == 0){
    80002024:	c129                	beqz	a0,80002066 <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80002026:	07000613          	li	a2,112
    8000202a:	4581                	li	a1,0
    8000202c:	06848513          	addi	a0,s1,104
    80002030:	fffff097          	auipc	ra,0xfffff
    80002034:	11c080e7          	jalr	284(ra) # 8000114c <memset>
  p->context.ra = (uint64)forkret;
    80002038:	00000797          	auipc	a5,0x0
    8000203c:	db478793          	addi	a5,a5,-588 # 80001dec <forkret>
    80002040:	f4bc                	sd	a5,104(s1)
  p->context.sp = p->kstack + PGSIZE;
    80002042:	64bc                	ld	a5,72(s1)
    80002044:	6705                	lui	a4,0x1
    80002046:	97ba                	add	a5,a5,a4
    80002048:	f8bc                	sd	a5,112(s1)
}
    8000204a:	8526                	mv	a0,s1
    8000204c:	60e2                	ld	ra,24(sp)
    8000204e:	6442                	ld	s0,16(sp)
    80002050:	64a2                	ld	s1,8(sp)
    80002052:	6902                	ld	s2,0(sp)
    80002054:	6105                	addi	sp,sp,32
    80002056:	8082                	ret
    release(&p->lock);
    80002058:	8526                	mv	a0,s1
    8000205a:	fffff097          	auipc	ra,0xfffff
    8000205e:	de2080e7          	jalr	-542(ra) # 80000e3c <release>
    return 0;
    80002062:	84ca                	mv	s1,s2
    80002064:	b7dd                	j	8000204a <allocproc+0x8c>
    freeproc(p);
    80002066:	8526                	mv	a0,s1
    80002068:	00000097          	auipc	ra,0x0
    8000206c:	efe080e7          	jalr	-258(ra) # 80001f66 <freeproc>
    release(&p->lock);
    80002070:	8526                	mv	a0,s1
    80002072:	fffff097          	auipc	ra,0xfffff
    80002076:	dca080e7          	jalr	-566(ra) # 80000e3c <release>
    return 0;
    8000207a:	84ca                	mv	s1,s2
    8000207c:	b7f9                	j	8000204a <allocproc+0x8c>

000000008000207e <userinit>:
{
    8000207e:	1101                	addi	sp,sp,-32
    80002080:	ec06                	sd	ra,24(sp)
    80002082:	e822                	sd	s0,16(sp)
    80002084:	e426                	sd	s1,8(sp)
    80002086:	1000                	addi	s0,sp,32
  p = allocproc();
    80002088:	00000097          	auipc	ra,0x0
    8000208c:	f36080e7          	jalr	-202(ra) # 80001fbe <allocproc>
    80002090:	84aa                	mv	s1,a0
  initproc = p;
    80002092:	00007797          	auipc	a5,0x7
    80002096:	f8a7b323          	sd	a0,-122(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    8000209a:	03400613          	li	a2,52
    8000209e:	00007597          	auipc	a1,0x7
    800020a2:	84258593          	addi	a1,a1,-1982 # 800088e0 <initcode>
    800020a6:	6d28                	ld	a0,88(a0)
    800020a8:	fffff097          	auipc	ra,0xfffff
    800020ac:	6f6080e7          	jalr	1782(ra) # 8000179e <uvminit>
  p->sz = PGSIZE;
    800020b0:	6785                	lui	a5,0x1
    800020b2:	e8bc                	sd	a5,80(s1)
  p->trapframe->epc = 0;      // user program counter
    800020b4:	70b8                	ld	a4,96(s1)
    800020b6:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    800020ba:	70b8                	ld	a4,96(s1)
    800020bc:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    800020be:	4641                	li	a2,16
    800020c0:	00006597          	auipc	a1,0x6
    800020c4:	1d058593          	addi	a1,a1,464 # 80008290 <digits+0x250>
    800020c8:	16048513          	addi	a0,s1,352
    800020cc:	fffff097          	auipc	ra,0xfffff
    800020d0:	1d6080e7          	jalr	470(ra) # 800012a2 <safestrcpy>
  p->cwd = namei("/");
    800020d4:	00006517          	auipc	a0,0x6
    800020d8:	1cc50513          	addi	a0,a0,460 # 800082a0 <digits+0x260>
    800020dc:	00002097          	auipc	ra,0x2
    800020e0:	250080e7          	jalr	592(ra) # 8000432c <namei>
    800020e4:	14a4bc23          	sd	a0,344(s1)
  p->state = RUNNABLE;
    800020e8:	4789                	li	a5,2
    800020ea:	d09c                	sw	a5,32(s1)
  release(&p->lock);
    800020ec:	8526                	mv	a0,s1
    800020ee:	fffff097          	auipc	ra,0xfffff
    800020f2:	d4e080e7          	jalr	-690(ra) # 80000e3c <release>
}
    800020f6:	60e2                	ld	ra,24(sp)
    800020f8:	6442                	ld	s0,16(sp)
    800020fa:	64a2                	ld	s1,8(sp)
    800020fc:	6105                	addi	sp,sp,32
    800020fe:	8082                	ret

0000000080002100 <growproc>:
{
    80002100:	1101                	addi	sp,sp,-32
    80002102:	ec06                	sd	ra,24(sp)
    80002104:	e822                	sd	s0,16(sp)
    80002106:	e426                	sd	s1,8(sp)
    80002108:	e04a                	sd	s2,0(sp)
    8000210a:	1000                	addi	s0,sp,32
    8000210c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000210e:	00000097          	auipc	ra,0x0
    80002112:	ca6080e7          	jalr	-858(ra) # 80001db4 <myproc>
    80002116:	892a                	mv	s2,a0
  sz = p->sz;
    80002118:	692c                	ld	a1,80(a0)
    8000211a:	0005861b          	sext.w	a2,a1
  if(n > 0){
    8000211e:	00904f63          	bgtz	s1,8000213c <growproc+0x3c>
  } else if(n < 0){
    80002122:	0204cc63          	bltz	s1,8000215a <growproc+0x5a>
  p->sz = sz;
    80002126:	1602                	slli	a2,a2,0x20
    80002128:	9201                	srli	a2,a2,0x20
    8000212a:	04c93823          	sd	a2,80(s2)
  return 0;
    8000212e:	4501                	li	a0,0
}
    80002130:	60e2                	ld	ra,24(sp)
    80002132:	6442                	ld	s0,16(sp)
    80002134:	64a2                	ld	s1,8(sp)
    80002136:	6902                	ld	s2,0(sp)
    80002138:	6105                	addi	sp,sp,32
    8000213a:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    8000213c:	9e25                	addw	a2,a2,s1
    8000213e:	1602                	slli	a2,a2,0x20
    80002140:	9201                	srli	a2,a2,0x20
    80002142:	1582                	slli	a1,a1,0x20
    80002144:	9181                	srli	a1,a1,0x20
    80002146:	6d28                	ld	a0,88(a0)
    80002148:	fffff097          	auipc	ra,0xfffff
    8000214c:	710080e7          	jalr	1808(ra) # 80001858 <uvmalloc>
    80002150:	0005061b          	sext.w	a2,a0
    80002154:	fa69                	bnez	a2,80002126 <growproc+0x26>
      return -1;
    80002156:	557d                	li	a0,-1
    80002158:	bfe1                	j	80002130 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    8000215a:	9e25                	addw	a2,a2,s1
    8000215c:	1602                	slli	a2,a2,0x20
    8000215e:	9201                	srli	a2,a2,0x20
    80002160:	1582                	slli	a1,a1,0x20
    80002162:	9181                	srli	a1,a1,0x20
    80002164:	6d28                	ld	a0,88(a0)
    80002166:	fffff097          	auipc	ra,0xfffff
    8000216a:	6aa080e7          	jalr	1706(ra) # 80001810 <uvmdealloc>
    8000216e:	0005061b          	sext.w	a2,a0
    80002172:	bf55                	j	80002126 <growproc+0x26>

0000000080002174 <fork>:
{
    80002174:	7179                	addi	sp,sp,-48
    80002176:	f406                	sd	ra,40(sp)
    80002178:	f022                	sd	s0,32(sp)
    8000217a:	ec26                	sd	s1,24(sp)
    8000217c:	e84a                	sd	s2,16(sp)
    8000217e:	e44e                	sd	s3,8(sp)
    80002180:	e052                	sd	s4,0(sp)
    80002182:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002184:	00000097          	auipc	ra,0x0
    80002188:	c30080e7          	jalr	-976(ra) # 80001db4 <myproc>
    8000218c:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    8000218e:	00000097          	auipc	ra,0x0
    80002192:	e30080e7          	jalr	-464(ra) # 80001fbe <allocproc>
    80002196:	c175                	beqz	a0,8000227a <fork+0x106>
    80002198:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    8000219a:	05093603          	ld	a2,80(s2)
    8000219e:	6d2c                	ld	a1,88(a0)
    800021a0:	05893503          	ld	a0,88(s2)
    800021a4:	00000097          	auipc	ra,0x0
    800021a8:	800080e7          	jalr	-2048(ra) # 800019a4 <uvmcopy>
    800021ac:	04054863          	bltz	a0,800021fc <fork+0x88>
  np->sz = p->sz;
    800021b0:	05093783          	ld	a5,80(s2)
    800021b4:	04f9b823          	sd	a5,80(s3) # 4000050 <_entry-0x7bffffb0>
  np->parent = p;
    800021b8:	0329b423          	sd	s2,40(s3)
  *(np->trapframe) = *(p->trapframe);
    800021bc:	06093683          	ld	a3,96(s2)
    800021c0:	87b6                	mv	a5,a3
    800021c2:	0609b703          	ld	a4,96(s3)
    800021c6:	12068693          	addi	a3,a3,288
    800021ca:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    800021ce:	6788                	ld	a0,8(a5)
    800021d0:	6b8c                	ld	a1,16(a5)
    800021d2:	6f90                	ld	a2,24(a5)
    800021d4:	01073023          	sd	a6,0(a4)
    800021d8:	e708                	sd	a0,8(a4)
    800021da:	eb0c                	sd	a1,16(a4)
    800021dc:	ef10                	sd	a2,24(a4)
    800021de:	02078793          	addi	a5,a5,32
    800021e2:	02070713          	addi	a4,a4,32
    800021e6:	fed792e3          	bne	a5,a3,800021ca <fork+0x56>
  np->trapframe->a0 = 0;
    800021ea:	0609b783          	ld	a5,96(s3)
    800021ee:	0607b823          	sd	zero,112(a5)
    800021f2:	0d800493          	li	s1,216
  for(i = 0; i < NOFILE; i++)
    800021f6:	15800a13          	li	s4,344
    800021fa:	a03d                	j	80002228 <fork+0xb4>
    freeproc(np);
    800021fc:	854e                	mv	a0,s3
    800021fe:	00000097          	auipc	ra,0x0
    80002202:	d68080e7          	jalr	-664(ra) # 80001f66 <freeproc>
    release(&np->lock);
    80002206:	854e                	mv	a0,s3
    80002208:	fffff097          	auipc	ra,0xfffff
    8000220c:	c34080e7          	jalr	-972(ra) # 80000e3c <release>
    return -1;
    80002210:	54fd                	li	s1,-1
    80002212:	a899                	j	80002268 <fork+0xf4>
      np->ofile[i] = filedup(p->ofile[i]);
    80002214:	00002097          	auipc	ra,0x2
    80002218:	7b6080e7          	jalr	1974(ra) # 800049ca <filedup>
    8000221c:	009987b3          	add	a5,s3,s1
    80002220:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002222:	04a1                	addi	s1,s1,8
    80002224:	01448763          	beq	s1,s4,80002232 <fork+0xbe>
    if(p->ofile[i])
    80002228:	009907b3          	add	a5,s2,s1
    8000222c:	6388                	ld	a0,0(a5)
    8000222e:	f17d                	bnez	a0,80002214 <fork+0xa0>
    80002230:	bfcd                	j	80002222 <fork+0xae>
  np->cwd = idup(p->cwd);
    80002232:	15893503          	ld	a0,344(s2)
    80002236:	00002097          	auipc	ra,0x2
    8000223a:	904080e7          	jalr	-1788(ra) # 80003b3a <idup>
    8000223e:	14a9bc23          	sd	a0,344(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002242:	4641                	li	a2,16
    80002244:	16090593          	addi	a1,s2,352
    80002248:	16098513          	addi	a0,s3,352
    8000224c:	fffff097          	auipc	ra,0xfffff
    80002250:	056080e7          	jalr	86(ra) # 800012a2 <safestrcpy>
  pid = np->pid;
    80002254:	0409a483          	lw	s1,64(s3)
  np->state = RUNNABLE;
    80002258:	4789                	li	a5,2
    8000225a:	02f9a023          	sw	a5,32(s3)
  release(&np->lock);
    8000225e:	854e                	mv	a0,s3
    80002260:	fffff097          	auipc	ra,0xfffff
    80002264:	bdc080e7          	jalr	-1060(ra) # 80000e3c <release>
}
    80002268:	8526                	mv	a0,s1
    8000226a:	70a2                	ld	ra,40(sp)
    8000226c:	7402                	ld	s0,32(sp)
    8000226e:	64e2                	ld	s1,24(sp)
    80002270:	6942                	ld	s2,16(sp)
    80002272:	69a2                	ld	s3,8(sp)
    80002274:	6a02                	ld	s4,0(sp)
    80002276:	6145                	addi	sp,sp,48
    80002278:	8082                	ret
    return -1;
    8000227a:	54fd                	li	s1,-1
    8000227c:	b7f5                	j	80002268 <fork+0xf4>

000000008000227e <reparent>:
{
    8000227e:	7179                	addi	sp,sp,-48
    80002280:	f406                	sd	ra,40(sp)
    80002282:	f022                	sd	s0,32(sp)
    80002284:	ec26                	sd	s1,24(sp)
    80002286:	e84a                	sd	s2,16(sp)
    80002288:	e44e                	sd	s3,8(sp)
    8000228a:	e052                	sd	s4,0(sp)
    8000228c:	1800                	addi	s0,sp,48
    8000228e:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002290:	00010497          	auipc	s1,0x10
    80002294:	51848493          	addi	s1,s1,1304 # 800127a8 <proc>
      pp->parent = initproc;
    80002298:	00007a17          	auipc	s4,0x7
    8000229c:	d80a0a13          	addi	s4,s4,-640 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800022a0:	00016997          	auipc	s3,0x16
    800022a4:	10898993          	addi	s3,s3,264 # 800183a8 <tickslock>
    800022a8:	a029                	j	800022b2 <reparent+0x34>
    800022aa:	17048493          	addi	s1,s1,368
    800022ae:	03348363          	beq	s1,s3,800022d4 <reparent+0x56>
    if(pp->parent == p){
    800022b2:	749c                	ld	a5,40(s1)
    800022b4:	ff279be3          	bne	a5,s2,800022aa <reparent+0x2c>
      acquire(&pp->lock);
    800022b8:	8526                	mv	a0,s1
    800022ba:	fffff097          	auipc	ra,0xfffff
    800022be:	ab2080e7          	jalr	-1358(ra) # 80000d6c <acquire>
      pp->parent = initproc;
    800022c2:	000a3783          	ld	a5,0(s4)
    800022c6:	f49c                	sd	a5,40(s1)
      release(&pp->lock);
    800022c8:	8526                	mv	a0,s1
    800022ca:	fffff097          	auipc	ra,0xfffff
    800022ce:	b72080e7          	jalr	-1166(ra) # 80000e3c <release>
    800022d2:	bfe1                	j	800022aa <reparent+0x2c>
}
    800022d4:	70a2                	ld	ra,40(sp)
    800022d6:	7402                	ld	s0,32(sp)
    800022d8:	64e2                	ld	s1,24(sp)
    800022da:	6942                	ld	s2,16(sp)
    800022dc:	69a2                	ld	s3,8(sp)
    800022de:	6a02                	ld	s4,0(sp)
    800022e0:	6145                	addi	sp,sp,48
    800022e2:	8082                	ret

00000000800022e4 <scheduler>:
{
    800022e4:	711d                	addi	sp,sp,-96
    800022e6:	ec86                	sd	ra,88(sp)
    800022e8:	e8a2                	sd	s0,80(sp)
    800022ea:	e4a6                	sd	s1,72(sp)
    800022ec:	e0ca                	sd	s2,64(sp)
    800022ee:	fc4e                	sd	s3,56(sp)
    800022f0:	f852                	sd	s4,48(sp)
    800022f2:	f456                	sd	s5,40(sp)
    800022f4:	f05a                	sd	s6,32(sp)
    800022f6:	ec5e                	sd	s7,24(sp)
    800022f8:	e862                	sd	s8,16(sp)
    800022fa:	e466                	sd	s9,8(sp)
    800022fc:	1080                	addi	s0,sp,96
    800022fe:	8792                	mv	a5,tp
  int id = r_tp();
    80002300:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002302:	00779c13          	slli	s8,a5,0x7
    80002306:	00010717          	auipc	a4,0x10
    8000230a:	08270713          	addi	a4,a4,130 # 80012388 <pid_lock>
    8000230e:	9762                	add	a4,a4,s8
    80002310:	02073023          	sd	zero,32(a4)
        swtch(&c->context, &p->context);
    80002314:	00010717          	auipc	a4,0x10
    80002318:	09c70713          	addi	a4,a4,156 # 800123b0 <cpus+0x8>
    8000231c:	9c3a                	add	s8,s8,a4
      if(p->state == RUNNABLE) {
    8000231e:	4a89                	li	s5,2
        c->proc = p;
    80002320:	079e                	slli	a5,a5,0x7
    80002322:	00010b17          	auipc	s6,0x10
    80002326:	066b0b13          	addi	s6,s6,102 # 80012388 <pid_lock>
    8000232a:	9b3e                	add	s6,s6,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    8000232c:	00016a17          	auipc	s4,0x16
    80002330:	07ca0a13          	addi	s4,s4,124 # 800183a8 <tickslock>
    int nproc = 0;
    80002334:	4c81                	li	s9,0
    80002336:	a8a1                	j	8000238e <scheduler+0xaa>
        p->state = RUNNING;
    80002338:	0374a023          	sw	s7,32(s1)
        c->proc = p;
    8000233c:	029b3023          	sd	s1,32(s6)
        swtch(&c->context, &p->context);
    80002340:	06848593          	addi	a1,s1,104
    80002344:	8562                	mv	a0,s8
    80002346:	00000097          	auipc	ra,0x0
    8000234a:	63a080e7          	jalr	1594(ra) # 80002980 <swtch>
        c->proc = 0;
    8000234e:	020b3023          	sd	zero,32(s6)
      release(&p->lock);
    80002352:	8526                	mv	a0,s1
    80002354:	fffff097          	auipc	ra,0xfffff
    80002358:	ae8080e7          	jalr	-1304(ra) # 80000e3c <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    8000235c:	17048493          	addi	s1,s1,368
    80002360:	01448d63          	beq	s1,s4,8000237a <scheduler+0x96>
      acquire(&p->lock);
    80002364:	8526                	mv	a0,s1
    80002366:	fffff097          	auipc	ra,0xfffff
    8000236a:	a06080e7          	jalr	-1530(ra) # 80000d6c <acquire>
      if(p->state != UNUSED) {
    8000236e:	509c                	lw	a5,32(s1)
    80002370:	d3ed                	beqz	a5,80002352 <scheduler+0x6e>
        nproc++;
    80002372:	2985                	addiw	s3,s3,1
      if(p->state == RUNNABLE) {
    80002374:	fd579fe3          	bne	a5,s5,80002352 <scheduler+0x6e>
    80002378:	b7c1                	j	80002338 <scheduler+0x54>
    if(nproc <= 2) {   // only init and sh exist
    8000237a:	013aca63          	blt	s5,s3,8000238e <scheduler+0xaa>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000237e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002382:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002386:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    8000238a:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000238e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002392:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002396:	10079073          	csrw	sstatus,a5
    int nproc = 0;
    8000239a:	89e6                	mv	s3,s9
    for(p = proc; p < &proc[NPROC]; p++) {
    8000239c:	00010497          	auipc	s1,0x10
    800023a0:	40c48493          	addi	s1,s1,1036 # 800127a8 <proc>
        p->state = RUNNING;
    800023a4:	4b8d                	li	s7,3
    800023a6:	bf7d                	j	80002364 <scheduler+0x80>

00000000800023a8 <sched>:
{
    800023a8:	7179                	addi	sp,sp,-48
    800023aa:	f406                	sd	ra,40(sp)
    800023ac:	f022                	sd	s0,32(sp)
    800023ae:	ec26                	sd	s1,24(sp)
    800023b0:	e84a                	sd	s2,16(sp)
    800023b2:	e44e                	sd	s3,8(sp)
    800023b4:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800023b6:	00000097          	auipc	ra,0x0
    800023ba:	9fe080e7          	jalr	-1538(ra) # 80001db4 <myproc>
    800023be:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800023c0:	fffff097          	auipc	ra,0xfffff
    800023c4:	932080e7          	jalr	-1742(ra) # 80000cf2 <holding>
    800023c8:	c93d                	beqz	a0,8000243e <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800023ca:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800023cc:	2781                	sext.w	a5,a5
    800023ce:	079e                	slli	a5,a5,0x7
    800023d0:	00010717          	auipc	a4,0x10
    800023d4:	fb870713          	addi	a4,a4,-72 # 80012388 <pid_lock>
    800023d8:	97ba                	add	a5,a5,a4
    800023da:	0987a703          	lw	a4,152(a5)
    800023de:	4785                	li	a5,1
    800023e0:	06f71763          	bne	a4,a5,8000244e <sched+0xa6>
  if(p->state == RUNNING)
    800023e4:	5098                	lw	a4,32(s1)
    800023e6:	478d                	li	a5,3
    800023e8:	06f70b63          	beq	a4,a5,8000245e <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800023ec:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800023f0:	8b89                	andi	a5,a5,2
  if(intr_get())
    800023f2:	efb5                	bnez	a5,8000246e <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800023f4:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800023f6:	00010917          	auipc	s2,0x10
    800023fa:	f9290913          	addi	s2,s2,-110 # 80012388 <pid_lock>
    800023fe:	2781                	sext.w	a5,a5
    80002400:	079e                	slli	a5,a5,0x7
    80002402:	97ca                	add	a5,a5,s2
    80002404:	09c7a983          	lw	s3,156(a5)
    80002408:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000240a:	2781                	sext.w	a5,a5
    8000240c:	079e                	slli	a5,a5,0x7
    8000240e:	00010597          	auipc	a1,0x10
    80002412:	fa258593          	addi	a1,a1,-94 # 800123b0 <cpus+0x8>
    80002416:	95be                	add	a1,a1,a5
    80002418:	06848513          	addi	a0,s1,104
    8000241c:	00000097          	auipc	ra,0x0
    80002420:	564080e7          	jalr	1380(ra) # 80002980 <swtch>
    80002424:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002426:	2781                	sext.w	a5,a5
    80002428:	079e                	slli	a5,a5,0x7
    8000242a:	97ca                	add	a5,a5,s2
    8000242c:	0937ae23          	sw	s3,156(a5)
}
    80002430:	70a2                	ld	ra,40(sp)
    80002432:	7402                	ld	s0,32(sp)
    80002434:	64e2                	ld	s1,24(sp)
    80002436:	6942                	ld	s2,16(sp)
    80002438:	69a2                	ld	s3,8(sp)
    8000243a:	6145                	addi	sp,sp,48
    8000243c:	8082                	ret
    panic("sched p->lock");
    8000243e:	00006517          	auipc	a0,0x6
    80002442:	e6a50513          	addi	a0,a0,-406 # 800082a8 <digits+0x268>
    80002446:	ffffe097          	auipc	ra,0xffffe
    8000244a:	10a080e7          	jalr	266(ra) # 80000550 <panic>
    panic("sched locks");
    8000244e:	00006517          	auipc	a0,0x6
    80002452:	e6a50513          	addi	a0,a0,-406 # 800082b8 <digits+0x278>
    80002456:	ffffe097          	auipc	ra,0xffffe
    8000245a:	0fa080e7          	jalr	250(ra) # 80000550 <panic>
    panic("sched running");
    8000245e:	00006517          	auipc	a0,0x6
    80002462:	e6a50513          	addi	a0,a0,-406 # 800082c8 <digits+0x288>
    80002466:	ffffe097          	auipc	ra,0xffffe
    8000246a:	0ea080e7          	jalr	234(ra) # 80000550 <panic>
    panic("sched interruptible");
    8000246e:	00006517          	auipc	a0,0x6
    80002472:	e6a50513          	addi	a0,a0,-406 # 800082d8 <digits+0x298>
    80002476:	ffffe097          	auipc	ra,0xffffe
    8000247a:	0da080e7          	jalr	218(ra) # 80000550 <panic>

000000008000247e <exit>:
{
    8000247e:	7179                	addi	sp,sp,-48
    80002480:	f406                	sd	ra,40(sp)
    80002482:	f022                	sd	s0,32(sp)
    80002484:	ec26                	sd	s1,24(sp)
    80002486:	e84a                	sd	s2,16(sp)
    80002488:	e44e                	sd	s3,8(sp)
    8000248a:	e052                	sd	s4,0(sp)
    8000248c:	1800                	addi	s0,sp,48
    8000248e:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002490:	00000097          	auipc	ra,0x0
    80002494:	924080e7          	jalr	-1756(ra) # 80001db4 <myproc>
    80002498:	89aa                	mv	s3,a0
  if(p == initproc)
    8000249a:	00007797          	auipc	a5,0x7
    8000249e:	b7e7b783          	ld	a5,-1154(a5) # 80009018 <initproc>
    800024a2:	0d850493          	addi	s1,a0,216
    800024a6:	15850913          	addi	s2,a0,344
    800024aa:	02a79363          	bne	a5,a0,800024d0 <exit+0x52>
    panic("init exiting");
    800024ae:	00006517          	auipc	a0,0x6
    800024b2:	e4250513          	addi	a0,a0,-446 # 800082f0 <digits+0x2b0>
    800024b6:	ffffe097          	auipc	ra,0xffffe
    800024ba:	09a080e7          	jalr	154(ra) # 80000550 <panic>
      fileclose(f);
    800024be:	00002097          	auipc	ra,0x2
    800024c2:	55e080e7          	jalr	1374(ra) # 80004a1c <fileclose>
      p->ofile[fd] = 0;
    800024c6:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800024ca:	04a1                	addi	s1,s1,8
    800024cc:	01248563          	beq	s1,s2,800024d6 <exit+0x58>
    if(p->ofile[fd]){
    800024d0:	6088                	ld	a0,0(s1)
    800024d2:	f575                	bnez	a0,800024be <exit+0x40>
    800024d4:	bfdd                	j	800024ca <exit+0x4c>
  begin_op();
    800024d6:	00002097          	auipc	ra,0x2
    800024da:	072080e7          	jalr	114(ra) # 80004548 <begin_op>
  iput(p->cwd);
    800024de:	1589b503          	ld	a0,344(s3)
    800024e2:	00002097          	auipc	ra,0x2
    800024e6:	850080e7          	jalr	-1968(ra) # 80003d32 <iput>
  end_op();
    800024ea:	00002097          	auipc	ra,0x2
    800024ee:	0de080e7          	jalr	222(ra) # 800045c8 <end_op>
  p->cwd = 0;
    800024f2:	1409bc23          	sd	zero,344(s3)
  acquire(&initproc->lock);
    800024f6:	00007497          	auipc	s1,0x7
    800024fa:	b2248493          	addi	s1,s1,-1246 # 80009018 <initproc>
    800024fe:	6088                	ld	a0,0(s1)
    80002500:	fffff097          	auipc	ra,0xfffff
    80002504:	86c080e7          	jalr	-1940(ra) # 80000d6c <acquire>
  wakeup1(initproc);
    80002508:	6088                	ld	a0,0(s1)
    8000250a:	fffff097          	auipc	ra,0xfffff
    8000250e:	76a080e7          	jalr	1898(ra) # 80001c74 <wakeup1>
  release(&initproc->lock);
    80002512:	6088                	ld	a0,0(s1)
    80002514:	fffff097          	auipc	ra,0xfffff
    80002518:	928080e7          	jalr	-1752(ra) # 80000e3c <release>
  acquire(&p->lock);
    8000251c:	854e                	mv	a0,s3
    8000251e:	fffff097          	auipc	ra,0xfffff
    80002522:	84e080e7          	jalr	-1970(ra) # 80000d6c <acquire>
  struct proc *original_parent = p->parent;
    80002526:	0289b483          	ld	s1,40(s3)
  release(&p->lock);
    8000252a:	854e                	mv	a0,s3
    8000252c:	fffff097          	auipc	ra,0xfffff
    80002530:	910080e7          	jalr	-1776(ra) # 80000e3c <release>
  acquire(&original_parent->lock);
    80002534:	8526                	mv	a0,s1
    80002536:	fffff097          	auipc	ra,0xfffff
    8000253a:	836080e7          	jalr	-1994(ra) # 80000d6c <acquire>
  acquire(&p->lock);
    8000253e:	854e                	mv	a0,s3
    80002540:	fffff097          	auipc	ra,0xfffff
    80002544:	82c080e7          	jalr	-2004(ra) # 80000d6c <acquire>
  reparent(p);
    80002548:	854e                	mv	a0,s3
    8000254a:	00000097          	auipc	ra,0x0
    8000254e:	d34080e7          	jalr	-716(ra) # 8000227e <reparent>
  wakeup1(original_parent);
    80002552:	8526                	mv	a0,s1
    80002554:	fffff097          	auipc	ra,0xfffff
    80002558:	720080e7          	jalr	1824(ra) # 80001c74 <wakeup1>
  p->xstate = status;
    8000255c:	0349ae23          	sw	s4,60(s3)
  p->state = ZOMBIE;
    80002560:	4791                	li	a5,4
    80002562:	02f9a023          	sw	a5,32(s3)
  release(&original_parent->lock);
    80002566:	8526                	mv	a0,s1
    80002568:	fffff097          	auipc	ra,0xfffff
    8000256c:	8d4080e7          	jalr	-1836(ra) # 80000e3c <release>
  sched();
    80002570:	00000097          	auipc	ra,0x0
    80002574:	e38080e7          	jalr	-456(ra) # 800023a8 <sched>
  panic("zombie exit");
    80002578:	00006517          	auipc	a0,0x6
    8000257c:	d8850513          	addi	a0,a0,-632 # 80008300 <digits+0x2c0>
    80002580:	ffffe097          	auipc	ra,0xffffe
    80002584:	fd0080e7          	jalr	-48(ra) # 80000550 <panic>

0000000080002588 <yield>:
{
    80002588:	1101                	addi	sp,sp,-32
    8000258a:	ec06                	sd	ra,24(sp)
    8000258c:	e822                	sd	s0,16(sp)
    8000258e:	e426                	sd	s1,8(sp)
    80002590:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002592:	00000097          	auipc	ra,0x0
    80002596:	822080e7          	jalr	-2014(ra) # 80001db4 <myproc>
    8000259a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000259c:	ffffe097          	auipc	ra,0xffffe
    800025a0:	7d0080e7          	jalr	2000(ra) # 80000d6c <acquire>
  p->state = RUNNABLE;
    800025a4:	4789                	li	a5,2
    800025a6:	d09c                	sw	a5,32(s1)
  sched();
    800025a8:	00000097          	auipc	ra,0x0
    800025ac:	e00080e7          	jalr	-512(ra) # 800023a8 <sched>
  release(&p->lock);
    800025b0:	8526                	mv	a0,s1
    800025b2:	fffff097          	auipc	ra,0xfffff
    800025b6:	88a080e7          	jalr	-1910(ra) # 80000e3c <release>
}
    800025ba:	60e2                	ld	ra,24(sp)
    800025bc:	6442                	ld	s0,16(sp)
    800025be:	64a2                	ld	s1,8(sp)
    800025c0:	6105                	addi	sp,sp,32
    800025c2:	8082                	ret

00000000800025c4 <sleep>:
{
    800025c4:	7179                	addi	sp,sp,-48
    800025c6:	f406                	sd	ra,40(sp)
    800025c8:	f022                	sd	s0,32(sp)
    800025ca:	ec26                	sd	s1,24(sp)
    800025cc:	e84a                	sd	s2,16(sp)
    800025ce:	e44e                	sd	s3,8(sp)
    800025d0:	1800                	addi	s0,sp,48
    800025d2:	89aa                	mv	s3,a0
    800025d4:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800025d6:	fffff097          	auipc	ra,0xfffff
    800025da:	7de080e7          	jalr	2014(ra) # 80001db4 <myproc>
    800025de:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    800025e0:	05250663          	beq	a0,s2,8000262c <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    800025e4:	ffffe097          	auipc	ra,0xffffe
    800025e8:	788080e7          	jalr	1928(ra) # 80000d6c <acquire>
    release(lk);
    800025ec:	854a                	mv	a0,s2
    800025ee:	fffff097          	auipc	ra,0xfffff
    800025f2:	84e080e7          	jalr	-1970(ra) # 80000e3c <release>
  p->chan = chan;
    800025f6:	0334b823          	sd	s3,48(s1)
  p->state = SLEEPING;
    800025fa:	4785                	li	a5,1
    800025fc:	d09c                	sw	a5,32(s1)
  sched();
    800025fe:	00000097          	auipc	ra,0x0
    80002602:	daa080e7          	jalr	-598(ra) # 800023a8 <sched>
  p->chan = 0;
    80002606:	0204b823          	sd	zero,48(s1)
    release(&p->lock);
    8000260a:	8526                	mv	a0,s1
    8000260c:	fffff097          	auipc	ra,0xfffff
    80002610:	830080e7          	jalr	-2000(ra) # 80000e3c <release>
    acquire(lk);
    80002614:	854a                	mv	a0,s2
    80002616:	ffffe097          	auipc	ra,0xffffe
    8000261a:	756080e7          	jalr	1878(ra) # 80000d6c <acquire>
}
    8000261e:	70a2                	ld	ra,40(sp)
    80002620:	7402                	ld	s0,32(sp)
    80002622:	64e2                	ld	s1,24(sp)
    80002624:	6942                	ld	s2,16(sp)
    80002626:	69a2                	ld	s3,8(sp)
    80002628:	6145                	addi	sp,sp,48
    8000262a:	8082                	ret
  p->chan = chan;
    8000262c:	03353823          	sd	s3,48(a0)
  p->state = SLEEPING;
    80002630:	4785                	li	a5,1
    80002632:	d11c                	sw	a5,32(a0)
  sched();
    80002634:	00000097          	auipc	ra,0x0
    80002638:	d74080e7          	jalr	-652(ra) # 800023a8 <sched>
  p->chan = 0;
    8000263c:	0204b823          	sd	zero,48(s1)
  if(lk != &p->lock){
    80002640:	bff9                	j	8000261e <sleep+0x5a>

0000000080002642 <wait>:
{
    80002642:	715d                	addi	sp,sp,-80
    80002644:	e486                	sd	ra,72(sp)
    80002646:	e0a2                	sd	s0,64(sp)
    80002648:	fc26                	sd	s1,56(sp)
    8000264a:	f84a                	sd	s2,48(sp)
    8000264c:	f44e                	sd	s3,40(sp)
    8000264e:	f052                	sd	s4,32(sp)
    80002650:	ec56                	sd	s5,24(sp)
    80002652:	e85a                	sd	s6,16(sp)
    80002654:	e45e                	sd	s7,8(sp)
    80002656:	e062                	sd	s8,0(sp)
    80002658:	0880                	addi	s0,sp,80
    8000265a:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000265c:	fffff097          	auipc	ra,0xfffff
    80002660:	758080e7          	jalr	1880(ra) # 80001db4 <myproc>
    80002664:	892a                	mv	s2,a0
  acquire(&p->lock);
    80002666:	8c2a                	mv	s8,a0
    80002668:	ffffe097          	auipc	ra,0xffffe
    8000266c:	704080e7          	jalr	1796(ra) # 80000d6c <acquire>
    havekids = 0;
    80002670:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002672:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    80002674:	00016997          	auipc	s3,0x16
    80002678:	d3498993          	addi	s3,s3,-716 # 800183a8 <tickslock>
        havekids = 1;
    8000267c:	4a85                	li	s5,1
    havekids = 0;
    8000267e:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002680:	00010497          	auipc	s1,0x10
    80002684:	12848493          	addi	s1,s1,296 # 800127a8 <proc>
    80002688:	a08d                	j	800026ea <wait+0xa8>
          pid = np->pid;
    8000268a:	0404a983          	lw	s3,64(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000268e:	000b0e63          	beqz	s6,800026aa <wait+0x68>
    80002692:	4691                	li	a3,4
    80002694:	03c48613          	addi	a2,s1,60
    80002698:	85da                	mv	a1,s6
    8000269a:	05893503          	ld	a0,88(s2)
    8000269e:	fffff097          	auipc	ra,0xfffff
    800026a2:	40a080e7          	jalr	1034(ra) # 80001aa8 <copyout>
    800026a6:	02054263          	bltz	a0,800026ca <wait+0x88>
          freeproc(np);
    800026aa:	8526                	mv	a0,s1
    800026ac:	00000097          	auipc	ra,0x0
    800026b0:	8ba080e7          	jalr	-1862(ra) # 80001f66 <freeproc>
          release(&np->lock);
    800026b4:	8526                	mv	a0,s1
    800026b6:	ffffe097          	auipc	ra,0xffffe
    800026ba:	786080e7          	jalr	1926(ra) # 80000e3c <release>
          release(&p->lock);
    800026be:	854a                	mv	a0,s2
    800026c0:	ffffe097          	auipc	ra,0xffffe
    800026c4:	77c080e7          	jalr	1916(ra) # 80000e3c <release>
          return pid;
    800026c8:	a8a9                	j	80002722 <wait+0xe0>
            release(&np->lock);
    800026ca:	8526                	mv	a0,s1
    800026cc:	ffffe097          	auipc	ra,0xffffe
    800026d0:	770080e7          	jalr	1904(ra) # 80000e3c <release>
            release(&p->lock);
    800026d4:	854a                	mv	a0,s2
    800026d6:	ffffe097          	auipc	ra,0xffffe
    800026da:	766080e7          	jalr	1894(ra) # 80000e3c <release>
            return -1;
    800026de:	59fd                	li	s3,-1
    800026e0:	a089                	j	80002722 <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    800026e2:	17048493          	addi	s1,s1,368
    800026e6:	03348463          	beq	s1,s3,8000270e <wait+0xcc>
      if(np->parent == p){
    800026ea:	749c                	ld	a5,40(s1)
    800026ec:	ff279be3          	bne	a5,s2,800026e2 <wait+0xa0>
        acquire(&np->lock);
    800026f0:	8526                	mv	a0,s1
    800026f2:	ffffe097          	auipc	ra,0xffffe
    800026f6:	67a080e7          	jalr	1658(ra) # 80000d6c <acquire>
        if(np->state == ZOMBIE){
    800026fa:	509c                	lw	a5,32(s1)
    800026fc:	f94787e3          	beq	a5,s4,8000268a <wait+0x48>
        release(&np->lock);
    80002700:	8526                	mv	a0,s1
    80002702:	ffffe097          	auipc	ra,0xffffe
    80002706:	73a080e7          	jalr	1850(ra) # 80000e3c <release>
        havekids = 1;
    8000270a:	8756                	mv	a4,s5
    8000270c:	bfd9                	j	800026e2 <wait+0xa0>
    if(!havekids || p->killed){
    8000270e:	c701                	beqz	a4,80002716 <wait+0xd4>
    80002710:	03892783          	lw	a5,56(s2)
    80002714:	c785                	beqz	a5,8000273c <wait+0xfa>
      release(&p->lock);
    80002716:	854a                	mv	a0,s2
    80002718:	ffffe097          	auipc	ra,0xffffe
    8000271c:	724080e7          	jalr	1828(ra) # 80000e3c <release>
      return -1;
    80002720:	59fd                	li	s3,-1
}
    80002722:	854e                	mv	a0,s3
    80002724:	60a6                	ld	ra,72(sp)
    80002726:	6406                	ld	s0,64(sp)
    80002728:	74e2                	ld	s1,56(sp)
    8000272a:	7942                	ld	s2,48(sp)
    8000272c:	79a2                	ld	s3,40(sp)
    8000272e:	7a02                	ld	s4,32(sp)
    80002730:	6ae2                	ld	s5,24(sp)
    80002732:	6b42                	ld	s6,16(sp)
    80002734:	6ba2                	ld	s7,8(sp)
    80002736:	6c02                	ld	s8,0(sp)
    80002738:	6161                	addi	sp,sp,80
    8000273a:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    8000273c:	85e2                	mv	a1,s8
    8000273e:	854a                	mv	a0,s2
    80002740:	00000097          	auipc	ra,0x0
    80002744:	e84080e7          	jalr	-380(ra) # 800025c4 <sleep>
    havekids = 0;
    80002748:	bf1d                	j	8000267e <wait+0x3c>

000000008000274a <wakeup>:
{
    8000274a:	7139                	addi	sp,sp,-64
    8000274c:	fc06                	sd	ra,56(sp)
    8000274e:	f822                	sd	s0,48(sp)
    80002750:	f426                	sd	s1,40(sp)
    80002752:	f04a                	sd	s2,32(sp)
    80002754:	ec4e                	sd	s3,24(sp)
    80002756:	e852                	sd	s4,16(sp)
    80002758:	e456                	sd	s5,8(sp)
    8000275a:	0080                	addi	s0,sp,64
    8000275c:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    8000275e:	00010497          	auipc	s1,0x10
    80002762:	04a48493          	addi	s1,s1,74 # 800127a8 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    80002766:	4985                	li	s3,1
      p->state = RUNNABLE;
    80002768:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    8000276a:	00016917          	auipc	s2,0x16
    8000276e:	c3e90913          	addi	s2,s2,-962 # 800183a8 <tickslock>
    80002772:	a821                	j	8000278a <wakeup+0x40>
      p->state = RUNNABLE;
    80002774:	0354a023          	sw	s5,32(s1)
    release(&p->lock);
    80002778:	8526                	mv	a0,s1
    8000277a:	ffffe097          	auipc	ra,0xffffe
    8000277e:	6c2080e7          	jalr	1730(ra) # 80000e3c <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002782:	17048493          	addi	s1,s1,368
    80002786:	01248e63          	beq	s1,s2,800027a2 <wakeup+0x58>
    acquire(&p->lock);
    8000278a:	8526                	mv	a0,s1
    8000278c:	ffffe097          	auipc	ra,0xffffe
    80002790:	5e0080e7          	jalr	1504(ra) # 80000d6c <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    80002794:	509c                	lw	a5,32(s1)
    80002796:	ff3791e3          	bne	a5,s3,80002778 <wakeup+0x2e>
    8000279a:	789c                	ld	a5,48(s1)
    8000279c:	fd479ee3          	bne	a5,s4,80002778 <wakeup+0x2e>
    800027a0:	bfd1                	j	80002774 <wakeup+0x2a>
}
    800027a2:	70e2                	ld	ra,56(sp)
    800027a4:	7442                	ld	s0,48(sp)
    800027a6:	74a2                	ld	s1,40(sp)
    800027a8:	7902                	ld	s2,32(sp)
    800027aa:	69e2                	ld	s3,24(sp)
    800027ac:	6a42                	ld	s4,16(sp)
    800027ae:	6aa2                	ld	s5,8(sp)
    800027b0:	6121                	addi	sp,sp,64
    800027b2:	8082                	ret

00000000800027b4 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800027b4:	7179                	addi	sp,sp,-48
    800027b6:	f406                	sd	ra,40(sp)
    800027b8:	f022                	sd	s0,32(sp)
    800027ba:	ec26                	sd	s1,24(sp)
    800027bc:	e84a                	sd	s2,16(sp)
    800027be:	e44e                	sd	s3,8(sp)
    800027c0:	1800                	addi	s0,sp,48
    800027c2:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800027c4:	00010497          	auipc	s1,0x10
    800027c8:	fe448493          	addi	s1,s1,-28 # 800127a8 <proc>
    800027cc:	00016997          	auipc	s3,0x16
    800027d0:	bdc98993          	addi	s3,s3,-1060 # 800183a8 <tickslock>
    acquire(&p->lock);
    800027d4:	8526                	mv	a0,s1
    800027d6:	ffffe097          	auipc	ra,0xffffe
    800027da:	596080e7          	jalr	1430(ra) # 80000d6c <acquire>
    if(p->pid == pid){
    800027de:	40bc                	lw	a5,64(s1)
    800027e0:	01278d63          	beq	a5,s2,800027fa <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800027e4:	8526                	mv	a0,s1
    800027e6:	ffffe097          	auipc	ra,0xffffe
    800027ea:	656080e7          	jalr	1622(ra) # 80000e3c <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800027ee:	17048493          	addi	s1,s1,368
    800027f2:	ff3491e3          	bne	s1,s3,800027d4 <kill+0x20>
  }
  return -1;
    800027f6:	557d                	li	a0,-1
    800027f8:	a829                	j	80002812 <kill+0x5e>
      p->killed = 1;
    800027fa:	4785                	li	a5,1
    800027fc:	dc9c                	sw	a5,56(s1)
      if(p->state == SLEEPING){
    800027fe:	5098                	lw	a4,32(s1)
    80002800:	4785                	li	a5,1
    80002802:	00f70f63          	beq	a4,a5,80002820 <kill+0x6c>
      release(&p->lock);
    80002806:	8526                	mv	a0,s1
    80002808:	ffffe097          	auipc	ra,0xffffe
    8000280c:	634080e7          	jalr	1588(ra) # 80000e3c <release>
      return 0;
    80002810:	4501                	li	a0,0
}
    80002812:	70a2                	ld	ra,40(sp)
    80002814:	7402                	ld	s0,32(sp)
    80002816:	64e2                	ld	s1,24(sp)
    80002818:	6942                	ld	s2,16(sp)
    8000281a:	69a2                	ld	s3,8(sp)
    8000281c:	6145                	addi	sp,sp,48
    8000281e:	8082                	ret
        p->state = RUNNABLE;
    80002820:	4789                	li	a5,2
    80002822:	d09c                	sw	a5,32(s1)
    80002824:	b7cd                	j	80002806 <kill+0x52>

0000000080002826 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002826:	7179                	addi	sp,sp,-48
    80002828:	f406                	sd	ra,40(sp)
    8000282a:	f022                	sd	s0,32(sp)
    8000282c:	ec26                	sd	s1,24(sp)
    8000282e:	e84a                	sd	s2,16(sp)
    80002830:	e44e                	sd	s3,8(sp)
    80002832:	e052                	sd	s4,0(sp)
    80002834:	1800                	addi	s0,sp,48
    80002836:	84aa                	mv	s1,a0
    80002838:	892e                	mv	s2,a1
    8000283a:	89b2                	mv	s3,a2
    8000283c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000283e:	fffff097          	auipc	ra,0xfffff
    80002842:	576080e7          	jalr	1398(ra) # 80001db4 <myproc>
  if(user_dst){
    80002846:	c08d                	beqz	s1,80002868 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002848:	86d2                	mv	a3,s4
    8000284a:	864e                	mv	a2,s3
    8000284c:	85ca                	mv	a1,s2
    8000284e:	6d28                	ld	a0,88(a0)
    80002850:	fffff097          	auipc	ra,0xfffff
    80002854:	258080e7          	jalr	600(ra) # 80001aa8 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002858:	70a2                	ld	ra,40(sp)
    8000285a:	7402                	ld	s0,32(sp)
    8000285c:	64e2                	ld	s1,24(sp)
    8000285e:	6942                	ld	s2,16(sp)
    80002860:	69a2                	ld	s3,8(sp)
    80002862:	6a02                	ld	s4,0(sp)
    80002864:	6145                	addi	sp,sp,48
    80002866:	8082                	ret
    memmove((char *)dst, src, len);
    80002868:	000a061b          	sext.w	a2,s4
    8000286c:	85ce                	mv	a1,s3
    8000286e:	854a                	mv	a0,s2
    80002870:	fffff097          	auipc	ra,0xfffff
    80002874:	93c080e7          	jalr	-1732(ra) # 800011ac <memmove>
    return 0;
    80002878:	8526                	mv	a0,s1
    8000287a:	bff9                	j	80002858 <either_copyout+0x32>

000000008000287c <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000287c:	7179                	addi	sp,sp,-48
    8000287e:	f406                	sd	ra,40(sp)
    80002880:	f022                	sd	s0,32(sp)
    80002882:	ec26                	sd	s1,24(sp)
    80002884:	e84a                	sd	s2,16(sp)
    80002886:	e44e                	sd	s3,8(sp)
    80002888:	e052                	sd	s4,0(sp)
    8000288a:	1800                	addi	s0,sp,48
    8000288c:	892a                	mv	s2,a0
    8000288e:	84ae                	mv	s1,a1
    80002890:	89b2                	mv	s3,a2
    80002892:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002894:	fffff097          	auipc	ra,0xfffff
    80002898:	520080e7          	jalr	1312(ra) # 80001db4 <myproc>
  if(user_src){
    8000289c:	c08d                	beqz	s1,800028be <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000289e:	86d2                	mv	a3,s4
    800028a0:	864e                	mv	a2,s3
    800028a2:	85ca                	mv	a1,s2
    800028a4:	6d28                	ld	a0,88(a0)
    800028a6:	fffff097          	auipc	ra,0xfffff
    800028aa:	28e080e7          	jalr	654(ra) # 80001b34 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800028ae:	70a2                	ld	ra,40(sp)
    800028b0:	7402                	ld	s0,32(sp)
    800028b2:	64e2                	ld	s1,24(sp)
    800028b4:	6942                	ld	s2,16(sp)
    800028b6:	69a2                	ld	s3,8(sp)
    800028b8:	6a02                	ld	s4,0(sp)
    800028ba:	6145                	addi	sp,sp,48
    800028bc:	8082                	ret
    memmove(dst, (char*)src, len);
    800028be:	000a061b          	sext.w	a2,s4
    800028c2:	85ce                	mv	a1,s3
    800028c4:	854a                	mv	a0,s2
    800028c6:	fffff097          	auipc	ra,0xfffff
    800028ca:	8e6080e7          	jalr	-1818(ra) # 800011ac <memmove>
    return 0;
    800028ce:	8526                	mv	a0,s1
    800028d0:	bff9                	j	800028ae <either_copyin+0x32>

00000000800028d2 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800028d2:	715d                	addi	sp,sp,-80
    800028d4:	e486                	sd	ra,72(sp)
    800028d6:	e0a2                	sd	s0,64(sp)
    800028d8:	fc26                	sd	s1,56(sp)
    800028da:	f84a                	sd	s2,48(sp)
    800028dc:	f44e                	sd	s3,40(sp)
    800028de:	f052                	sd	s4,32(sp)
    800028e0:	ec56                	sd	s5,24(sp)
    800028e2:	e85a                	sd	s6,16(sp)
    800028e4:	e45e                	sd	s7,8(sp)
    800028e6:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800028e8:	00006517          	auipc	a0,0x6
    800028ec:	89050513          	addi	a0,a0,-1904 # 80008178 <digits+0x138>
    800028f0:	ffffe097          	auipc	ra,0xffffe
    800028f4:	caa080e7          	jalr	-854(ra) # 8000059a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800028f8:	00010497          	auipc	s1,0x10
    800028fc:	01048493          	addi	s1,s1,16 # 80012908 <proc+0x160>
    80002900:	00016917          	auipc	s2,0x16
    80002904:	c0890913          	addi	s2,s2,-1016 # 80018508 <hashTable+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002908:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    8000290a:	00006997          	auipc	s3,0x6
    8000290e:	a0698993          	addi	s3,s3,-1530 # 80008310 <digits+0x2d0>
    printf("%d %s %s", p->pid, state, p->name);
    80002912:	00006a97          	auipc	s5,0x6
    80002916:	a06a8a93          	addi	s5,s5,-1530 # 80008318 <digits+0x2d8>
    printf("\n");
    8000291a:	00006a17          	auipc	s4,0x6
    8000291e:	85ea0a13          	addi	s4,s4,-1954 # 80008178 <digits+0x138>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002922:	00006b97          	auipc	s7,0x6
    80002926:	a2eb8b93          	addi	s7,s7,-1490 # 80008350 <states.1712>
    8000292a:	a00d                	j	8000294c <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000292c:	ee06a583          	lw	a1,-288(a3)
    80002930:	8556                	mv	a0,s5
    80002932:	ffffe097          	auipc	ra,0xffffe
    80002936:	c68080e7          	jalr	-920(ra) # 8000059a <printf>
    printf("\n");
    8000293a:	8552                	mv	a0,s4
    8000293c:	ffffe097          	auipc	ra,0xffffe
    80002940:	c5e080e7          	jalr	-930(ra) # 8000059a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002944:	17048493          	addi	s1,s1,368
    80002948:	03248163          	beq	s1,s2,8000296a <procdump+0x98>
    if(p->state == UNUSED)
    8000294c:	86a6                	mv	a3,s1
    8000294e:	ec04a783          	lw	a5,-320(s1)
    80002952:	dbed                	beqz	a5,80002944 <procdump+0x72>
      state = "???";
    80002954:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002956:	fcfb6be3          	bltu	s6,a5,8000292c <procdump+0x5a>
    8000295a:	1782                	slli	a5,a5,0x20
    8000295c:	9381                	srli	a5,a5,0x20
    8000295e:	078e                	slli	a5,a5,0x3
    80002960:	97de                	add	a5,a5,s7
    80002962:	6390                	ld	a2,0(a5)
    80002964:	f661                	bnez	a2,8000292c <procdump+0x5a>
      state = "???";
    80002966:	864e                	mv	a2,s3
    80002968:	b7d1                	j	8000292c <procdump+0x5a>
  }
}
    8000296a:	60a6                	ld	ra,72(sp)
    8000296c:	6406                	ld	s0,64(sp)
    8000296e:	74e2                	ld	s1,56(sp)
    80002970:	7942                	ld	s2,48(sp)
    80002972:	79a2                	ld	s3,40(sp)
    80002974:	7a02                	ld	s4,32(sp)
    80002976:	6ae2                	ld	s5,24(sp)
    80002978:	6b42                	ld	s6,16(sp)
    8000297a:	6ba2                	ld	s7,8(sp)
    8000297c:	6161                	addi	sp,sp,80
    8000297e:	8082                	ret

0000000080002980 <swtch>:
    80002980:	00153023          	sd	ra,0(a0)
    80002984:	00253423          	sd	sp,8(a0)
    80002988:	e900                	sd	s0,16(a0)
    8000298a:	ed04                	sd	s1,24(a0)
    8000298c:	03253023          	sd	s2,32(a0)
    80002990:	03353423          	sd	s3,40(a0)
    80002994:	03453823          	sd	s4,48(a0)
    80002998:	03553c23          	sd	s5,56(a0)
    8000299c:	05653023          	sd	s6,64(a0)
    800029a0:	05753423          	sd	s7,72(a0)
    800029a4:	05853823          	sd	s8,80(a0)
    800029a8:	05953c23          	sd	s9,88(a0)
    800029ac:	07a53023          	sd	s10,96(a0)
    800029b0:	07b53423          	sd	s11,104(a0)
    800029b4:	0005b083          	ld	ra,0(a1)
    800029b8:	0085b103          	ld	sp,8(a1)
    800029bc:	6980                	ld	s0,16(a1)
    800029be:	6d84                	ld	s1,24(a1)
    800029c0:	0205b903          	ld	s2,32(a1)
    800029c4:	0285b983          	ld	s3,40(a1)
    800029c8:	0305ba03          	ld	s4,48(a1)
    800029cc:	0385ba83          	ld	s5,56(a1)
    800029d0:	0405bb03          	ld	s6,64(a1)
    800029d4:	0485bb83          	ld	s7,72(a1)
    800029d8:	0505bc03          	ld	s8,80(a1)
    800029dc:	0585bc83          	ld	s9,88(a1)
    800029e0:	0605bd03          	ld	s10,96(a1)
    800029e4:	0685bd83          	ld	s11,104(a1)
    800029e8:	8082                	ret

00000000800029ea <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800029ea:	1141                	addi	sp,sp,-16
    800029ec:	e406                	sd	ra,8(sp)
    800029ee:	e022                	sd	s0,0(sp)
    800029f0:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800029f2:	00006597          	auipc	a1,0x6
    800029f6:	98658593          	addi	a1,a1,-1658 # 80008378 <states.1712+0x28>
    800029fa:	00016517          	auipc	a0,0x16
    800029fe:	9ae50513          	addi	a0,a0,-1618 # 800183a8 <tickslock>
    80002a02:	ffffe097          	auipc	ra,0xffffe
    80002a06:	4e6080e7          	jalr	1254(ra) # 80000ee8 <initlock>
}
    80002a0a:	60a2                	ld	ra,8(sp)
    80002a0c:	6402                	ld	s0,0(sp)
    80002a0e:	0141                	addi	sp,sp,16
    80002a10:	8082                	ret

0000000080002a12 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002a12:	1141                	addi	sp,sp,-16
    80002a14:	e422                	sd	s0,8(sp)
    80002a16:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a18:	00003797          	auipc	a5,0x3
    80002a1c:	67878793          	addi	a5,a5,1656 # 80006090 <kernelvec>
    80002a20:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002a24:	6422                	ld	s0,8(sp)
    80002a26:	0141                	addi	sp,sp,16
    80002a28:	8082                	ret

0000000080002a2a <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002a2a:	1141                	addi	sp,sp,-16
    80002a2c:	e406                	sd	ra,8(sp)
    80002a2e:	e022                	sd	s0,0(sp)
    80002a30:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002a32:	fffff097          	auipc	ra,0xfffff
    80002a36:	382080e7          	jalr	898(ra) # 80001db4 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a3a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002a3e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a40:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002a44:	00004617          	auipc	a2,0x4
    80002a48:	5bc60613          	addi	a2,a2,1468 # 80007000 <_trampoline>
    80002a4c:	00004697          	auipc	a3,0x4
    80002a50:	5b468693          	addi	a3,a3,1460 # 80007000 <_trampoline>
    80002a54:	8e91                	sub	a3,a3,a2
    80002a56:	040007b7          	lui	a5,0x4000
    80002a5a:	17fd                	addi	a5,a5,-1
    80002a5c:	07b2                	slli	a5,a5,0xc
    80002a5e:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a60:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002a64:	7138                	ld	a4,96(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002a66:	180026f3          	csrr	a3,satp
    80002a6a:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002a6c:	7138                	ld	a4,96(a0)
    80002a6e:	6534                	ld	a3,72(a0)
    80002a70:	6585                	lui	a1,0x1
    80002a72:	96ae                	add	a3,a3,a1
    80002a74:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002a76:	7138                	ld	a4,96(a0)
    80002a78:	00000697          	auipc	a3,0x0
    80002a7c:	13868693          	addi	a3,a3,312 # 80002bb0 <usertrap>
    80002a80:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002a82:	7138                	ld	a4,96(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002a84:	8692                	mv	a3,tp
    80002a86:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a88:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002a8c:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002a90:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a94:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002a98:	7138                	ld	a4,96(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a9a:	6f18                	ld	a4,24(a4)
    80002a9c:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002aa0:	6d2c                	ld	a1,88(a0)
    80002aa2:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002aa4:	00004717          	auipc	a4,0x4
    80002aa8:	5ec70713          	addi	a4,a4,1516 # 80007090 <userret>
    80002aac:	8f11                	sub	a4,a4,a2
    80002aae:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002ab0:	577d                	li	a4,-1
    80002ab2:	177e                	slli	a4,a4,0x3f
    80002ab4:	8dd9                	or	a1,a1,a4
    80002ab6:	02000537          	lui	a0,0x2000
    80002aba:	157d                	addi	a0,a0,-1
    80002abc:	0536                	slli	a0,a0,0xd
    80002abe:	9782                	jalr	a5
}
    80002ac0:	60a2                	ld	ra,8(sp)
    80002ac2:	6402                	ld	s0,0(sp)
    80002ac4:	0141                	addi	sp,sp,16
    80002ac6:	8082                	ret

0000000080002ac8 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002ac8:	1101                	addi	sp,sp,-32
    80002aca:	ec06                	sd	ra,24(sp)
    80002acc:	e822                	sd	s0,16(sp)
    80002ace:	e426                	sd	s1,8(sp)
    80002ad0:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002ad2:	00016497          	auipc	s1,0x16
    80002ad6:	8d648493          	addi	s1,s1,-1834 # 800183a8 <tickslock>
    80002ada:	8526                	mv	a0,s1
    80002adc:	ffffe097          	auipc	ra,0xffffe
    80002ae0:	290080e7          	jalr	656(ra) # 80000d6c <acquire>
  ticks++;
    80002ae4:	00006517          	auipc	a0,0x6
    80002ae8:	53c50513          	addi	a0,a0,1340 # 80009020 <ticks>
    80002aec:	411c                	lw	a5,0(a0)
    80002aee:	2785                	addiw	a5,a5,1
    80002af0:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002af2:	00000097          	auipc	ra,0x0
    80002af6:	c58080e7          	jalr	-936(ra) # 8000274a <wakeup>
  release(&tickslock);
    80002afa:	8526                	mv	a0,s1
    80002afc:	ffffe097          	auipc	ra,0xffffe
    80002b00:	340080e7          	jalr	832(ra) # 80000e3c <release>
}
    80002b04:	60e2                	ld	ra,24(sp)
    80002b06:	6442                	ld	s0,16(sp)
    80002b08:	64a2                	ld	s1,8(sp)
    80002b0a:	6105                	addi	sp,sp,32
    80002b0c:	8082                	ret

0000000080002b0e <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002b0e:	1101                	addi	sp,sp,-32
    80002b10:	ec06                	sd	ra,24(sp)
    80002b12:	e822                	sd	s0,16(sp)
    80002b14:	e426                	sd	s1,8(sp)
    80002b16:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b18:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002b1c:	00074d63          	bltz	a4,80002b36 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002b20:	57fd                	li	a5,-1
    80002b22:	17fe                	slli	a5,a5,0x3f
    80002b24:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002b26:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002b28:	06f70363          	beq	a4,a5,80002b8e <devintr+0x80>
  }
}
    80002b2c:	60e2                	ld	ra,24(sp)
    80002b2e:	6442                	ld	s0,16(sp)
    80002b30:	64a2                	ld	s1,8(sp)
    80002b32:	6105                	addi	sp,sp,32
    80002b34:	8082                	ret
     (scause & 0xff) == 9){
    80002b36:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002b3a:	46a5                	li	a3,9
    80002b3c:	fed792e3          	bne	a5,a3,80002b20 <devintr+0x12>
    int irq = plic_claim();
    80002b40:	00003097          	auipc	ra,0x3
    80002b44:	658080e7          	jalr	1624(ra) # 80006198 <plic_claim>
    80002b48:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002b4a:	47a9                	li	a5,10
    80002b4c:	02f50763          	beq	a0,a5,80002b7a <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002b50:	4785                	li	a5,1
    80002b52:	02f50963          	beq	a0,a5,80002b84 <devintr+0x76>
    return 1;
    80002b56:	4505                	li	a0,1
    } else if(irq){
    80002b58:	d8f1                	beqz	s1,80002b2c <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002b5a:	85a6                	mv	a1,s1
    80002b5c:	00006517          	auipc	a0,0x6
    80002b60:	82450513          	addi	a0,a0,-2012 # 80008380 <states.1712+0x30>
    80002b64:	ffffe097          	auipc	ra,0xffffe
    80002b68:	a36080e7          	jalr	-1482(ra) # 8000059a <printf>
      plic_complete(irq);
    80002b6c:	8526                	mv	a0,s1
    80002b6e:	00003097          	auipc	ra,0x3
    80002b72:	64e080e7          	jalr	1614(ra) # 800061bc <plic_complete>
    return 1;
    80002b76:	4505                	li	a0,1
    80002b78:	bf55                	j	80002b2c <devintr+0x1e>
      uartintr();
    80002b7a:	ffffe097          	auipc	ra,0xffffe
    80002b7e:	e62080e7          	jalr	-414(ra) # 800009dc <uartintr>
    80002b82:	b7ed                	j	80002b6c <devintr+0x5e>
      virtio_disk_intr();
    80002b84:	00004097          	auipc	ra,0x4
    80002b88:	b18080e7          	jalr	-1256(ra) # 8000669c <virtio_disk_intr>
    80002b8c:	b7c5                	j	80002b6c <devintr+0x5e>
    if(cpuid() == 0){
    80002b8e:	fffff097          	auipc	ra,0xfffff
    80002b92:	1fa080e7          	jalr	506(ra) # 80001d88 <cpuid>
    80002b96:	c901                	beqz	a0,80002ba6 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002b98:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002b9e:	14479073          	csrw	sip,a5
    return 2;
    80002ba2:	4509                	li	a0,2
    80002ba4:	b761                	j	80002b2c <devintr+0x1e>
      clockintr();
    80002ba6:	00000097          	auipc	ra,0x0
    80002baa:	f22080e7          	jalr	-222(ra) # 80002ac8 <clockintr>
    80002bae:	b7ed                	j	80002b98 <devintr+0x8a>

0000000080002bb0 <usertrap>:
{
    80002bb0:	1101                	addi	sp,sp,-32
    80002bb2:	ec06                	sd	ra,24(sp)
    80002bb4:	e822                	sd	s0,16(sp)
    80002bb6:	e426                	sd	s1,8(sp)
    80002bb8:	e04a                	sd	s2,0(sp)
    80002bba:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bbc:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002bc0:	1007f793          	andi	a5,a5,256
    80002bc4:	e3ad                	bnez	a5,80002c26 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002bc6:	00003797          	auipc	a5,0x3
    80002bca:	4ca78793          	addi	a5,a5,1226 # 80006090 <kernelvec>
    80002bce:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002bd2:	fffff097          	auipc	ra,0xfffff
    80002bd6:	1e2080e7          	jalr	482(ra) # 80001db4 <myproc>
    80002bda:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002bdc:	713c                	ld	a5,96(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bde:	14102773          	csrr	a4,sepc
    80002be2:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002be4:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002be8:	47a1                	li	a5,8
    80002bea:	04f71c63          	bne	a4,a5,80002c42 <usertrap+0x92>
    if(p->killed)
    80002bee:	5d1c                	lw	a5,56(a0)
    80002bf0:	e3b9                	bnez	a5,80002c36 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002bf2:	70b8                	ld	a4,96(s1)
    80002bf4:	6f1c                	ld	a5,24(a4)
    80002bf6:	0791                	addi	a5,a5,4
    80002bf8:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bfa:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002bfe:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c02:	10079073          	csrw	sstatus,a5
    syscall();
    80002c06:	00000097          	auipc	ra,0x0
    80002c0a:	2e0080e7          	jalr	736(ra) # 80002ee6 <syscall>
  if(p->killed)
    80002c0e:	5c9c                	lw	a5,56(s1)
    80002c10:	ebc1                	bnez	a5,80002ca0 <usertrap+0xf0>
  usertrapret();
    80002c12:	00000097          	auipc	ra,0x0
    80002c16:	e18080e7          	jalr	-488(ra) # 80002a2a <usertrapret>
}
    80002c1a:	60e2                	ld	ra,24(sp)
    80002c1c:	6442                	ld	s0,16(sp)
    80002c1e:	64a2                	ld	s1,8(sp)
    80002c20:	6902                	ld	s2,0(sp)
    80002c22:	6105                	addi	sp,sp,32
    80002c24:	8082                	ret
    panic("usertrap: not from user mode");
    80002c26:	00005517          	auipc	a0,0x5
    80002c2a:	77a50513          	addi	a0,a0,1914 # 800083a0 <states.1712+0x50>
    80002c2e:	ffffe097          	auipc	ra,0xffffe
    80002c32:	922080e7          	jalr	-1758(ra) # 80000550 <panic>
      exit(-1);
    80002c36:	557d                	li	a0,-1
    80002c38:	00000097          	auipc	ra,0x0
    80002c3c:	846080e7          	jalr	-1978(ra) # 8000247e <exit>
    80002c40:	bf4d                	j	80002bf2 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002c42:	00000097          	auipc	ra,0x0
    80002c46:	ecc080e7          	jalr	-308(ra) # 80002b0e <devintr>
    80002c4a:	892a                	mv	s2,a0
    80002c4c:	c501                	beqz	a0,80002c54 <usertrap+0xa4>
  if(p->killed)
    80002c4e:	5c9c                	lw	a5,56(s1)
    80002c50:	c3a1                	beqz	a5,80002c90 <usertrap+0xe0>
    80002c52:	a815                	j	80002c86 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c54:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002c58:	40b0                	lw	a2,64(s1)
    80002c5a:	00005517          	auipc	a0,0x5
    80002c5e:	76650513          	addi	a0,a0,1894 # 800083c0 <states.1712+0x70>
    80002c62:	ffffe097          	auipc	ra,0xffffe
    80002c66:	938080e7          	jalr	-1736(ra) # 8000059a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c6a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c6e:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c72:	00005517          	auipc	a0,0x5
    80002c76:	77e50513          	addi	a0,a0,1918 # 800083f0 <states.1712+0xa0>
    80002c7a:	ffffe097          	auipc	ra,0xffffe
    80002c7e:	920080e7          	jalr	-1760(ra) # 8000059a <printf>
    p->killed = 1;
    80002c82:	4785                	li	a5,1
    80002c84:	dc9c                	sw	a5,56(s1)
    exit(-1);
    80002c86:	557d                	li	a0,-1
    80002c88:	fffff097          	auipc	ra,0xfffff
    80002c8c:	7f6080e7          	jalr	2038(ra) # 8000247e <exit>
  if(which_dev == 2)
    80002c90:	4789                	li	a5,2
    80002c92:	f8f910e3          	bne	s2,a5,80002c12 <usertrap+0x62>
    yield();
    80002c96:	00000097          	auipc	ra,0x0
    80002c9a:	8f2080e7          	jalr	-1806(ra) # 80002588 <yield>
    80002c9e:	bf95                	j	80002c12 <usertrap+0x62>
  int which_dev = 0;
    80002ca0:	4901                	li	s2,0
    80002ca2:	b7d5                	j	80002c86 <usertrap+0xd6>

0000000080002ca4 <kerneltrap>:
{
    80002ca4:	7179                	addi	sp,sp,-48
    80002ca6:	f406                	sd	ra,40(sp)
    80002ca8:	f022                	sd	s0,32(sp)
    80002caa:	ec26                	sd	s1,24(sp)
    80002cac:	e84a                	sd	s2,16(sp)
    80002cae:	e44e                	sd	s3,8(sp)
    80002cb0:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002cb2:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cb6:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002cba:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002cbe:	1004f793          	andi	a5,s1,256
    80002cc2:	cb85                	beqz	a5,80002cf2 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cc4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002cc8:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002cca:	ef85                	bnez	a5,80002d02 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002ccc:	00000097          	auipc	ra,0x0
    80002cd0:	e42080e7          	jalr	-446(ra) # 80002b0e <devintr>
    80002cd4:	cd1d                	beqz	a0,80002d12 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002cd6:	4789                	li	a5,2
    80002cd8:	06f50a63          	beq	a0,a5,80002d4c <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002cdc:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ce0:	10049073          	csrw	sstatus,s1
}
    80002ce4:	70a2                	ld	ra,40(sp)
    80002ce6:	7402                	ld	s0,32(sp)
    80002ce8:	64e2                	ld	s1,24(sp)
    80002cea:	6942                	ld	s2,16(sp)
    80002cec:	69a2                	ld	s3,8(sp)
    80002cee:	6145                	addi	sp,sp,48
    80002cf0:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002cf2:	00005517          	auipc	a0,0x5
    80002cf6:	71e50513          	addi	a0,a0,1822 # 80008410 <states.1712+0xc0>
    80002cfa:	ffffe097          	auipc	ra,0xffffe
    80002cfe:	856080e7          	jalr	-1962(ra) # 80000550 <panic>
    panic("kerneltrap: interrupts enabled");
    80002d02:	00005517          	auipc	a0,0x5
    80002d06:	73650513          	addi	a0,a0,1846 # 80008438 <states.1712+0xe8>
    80002d0a:	ffffe097          	auipc	ra,0xffffe
    80002d0e:	846080e7          	jalr	-1978(ra) # 80000550 <panic>
    printf("scause %p\n", scause);
    80002d12:	85ce                	mv	a1,s3
    80002d14:	00005517          	auipc	a0,0x5
    80002d18:	74450513          	addi	a0,a0,1860 # 80008458 <states.1712+0x108>
    80002d1c:	ffffe097          	auipc	ra,0xffffe
    80002d20:	87e080e7          	jalr	-1922(ra) # 8000059a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d24:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002d28:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002d2c:	00005517          	auipc	a0,0x5
    80002d30:	73c50513          	addi	a0,a0,1852 # 80008468 <states.1712+0x118>
    80002d34:	ffffe097          	auipc	ra,0xffffe
    80002d38:	866080e7          	jalr	-1946(ra) # 8000059a <printf>
    panic("kerneltrap");
    80002d3c:	00005517          	auipc	a0,0x5
    80002d40:	74450513          	addi	a0,a0,1860 # 80008480 <states.1712+0x130>
    80002d44:	ffffe097          	auipc	ra,0xffffe
    80002d48:	80c080e7          	jalr	-2036(ra) # 80000550 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002d4c:	fffff097          	auipc	ra,0xfffff
    80002d50:	068080e7          	jalr	104(ra) # 80001db4 <myproc>
    80002d54:	d541                	beqz	a0,80002cdc <kerneltrap+0x38>
    80002d56:	fffff097          	auipc	ra,0xfffff
    80002d5a:	05e080e7          	jalr	94(ra) # 80001db4 <myproc>
    80002d5e:	5118                	lw	a4,32(a0)
    80002d60:	478d                	li	a5,3
    80002d62:	f6f71de3          	bne	a4,a5,80002cdc <kerneltrap+0x38>
    yield();
    80002d66:	00000097          	auipc	ra,0x0
    80002d6a:	822080e7          	jalr	-2014(ra) # 80002588 <yield>
    80002d6e:	b7bd                	j	80002cdc <kerneltrap+0x38>

0000000080002d70 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002d70:	1101                	addi	sp,sp,-32
    80002d72:	ec06                	sd	ra,24(sp)
    80002d74:	e822                	sd	s0,16(sp)
    80002d76:	e426                	sd	s1,8(sp)
    80002d78:	1000                	addi	s0,sp,32
    80002d7a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002d7c:	fffff097          	auipc	ra,0xfffff
    80002d80:	038080e7          	jalr	56(ra) # 80001db4 <myproc>
  switch (n) {
    80002d84:	4795                	li	a5,5
    80002d86:	0497e163          	bltu	a5,s1,80002dc8 <argraw+0x58>
    80002d8a:	048a                	slli	s1,s1,0x2
    80002d8c:	00005717          	auipc	a4,0x5
    80002d90:	72c70713          	addi	a4,a4,1836 # 800084b8 <states.1712+0x168>
    80002d94:	94ba                	add	s1,s1,a4
    80002d96:	409c                	lw	a5,0(s1)
    80002d98:	97ba                	add	a5,a5,a4
    80002d9a:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002d9c:	713c                	ld	a5,96(a0)
    80002d9e:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002da0:	60e2                	ld	ra,24(sp)
    80002da2:	6442                	ld	s0,16(sp)
    80002da4:	64a2                	ld	s1,8(sp)
    80002da6:	6105                	addi	sp,sp,32
    80002da8:	8082                	ret
    return p->trapframe->a1;
    80002daa:	713c                	ld	a5,96(a0)
    80002dac:	7fa8                	ld	a0,120(a5)
    80002dae:	bfcd                	j	80002da0 <argraw+0x30>
    return p->trapframe->a2;
    80002db0:	713c                	ld	a5,96(a0)
    80002db2:	63c8                	ld	a0,128(a5)
    80002db4:	b7f5                	j	80002da0 <argraw+0x30>
    return p->trapframe->a3;
    80002db6:	713c                	ld	a5,96(a0)
    80002db8:	67c8                	ld	a0,136(a5)
    80002dba:	b7dd                	j	80002da0 <argraw+0x30>
    return p->trapframe->a4;
    80002dbc:	713c                	ld	a5,96(a0)
    80002dbe:	6bc8                	ld	a0,144(a5)
    80002dc0:	b7c5                	j	80002da0 <argraw+0x30>
    return p->trapframe->a5;
    80002dc2:	713c                	ld	a5,96(a0)
    80002dc4:	6fc8                	ld	a0,152(a5)
    80002dc6:	bfe9                	j	80002da0 <argraw+0x30>
  panic("argraw");
    80002dc8:	00005517          	auipc	a0,0x5
    80002dcc:	6c850513          	addi	a0,a0,1736 # 80008490 <states.1712+0x140>
    80002dd0:	ffffd097          	auipc	ra,0xffffd
    80002dd4:	780080e7          	jalr	1920(ra) # 80000550 <panic>

0000000080002dd8 <fetchaddr>:
{
    80002dd8:	1101                	addi	sp,sp,-32
    80002dda:	ec06                	sd	ra,24(sp)
    80002ddc:	e822                	sd	s0,16(sp)
    80002dde:	e426                	sd	s1,8(sp)
    80002de0:	e04a                	sd	s2,0(sp)
    80002de2:	1000                	addi	s0,sp,32
    80002de4:	84aa                	mv	s1,a0
    80002de6:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002de8:	fffff097          	auipc	ra,0xfffff
    80002dec:	fcc080e7          	jalr	-52(ra) # 80001db4 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002df0:	693c                	ld	a5,80(a0)
    80002df2:	02f4f863          	bgeu	s1,a5,80002e22 <fetchaddr+0x4a>
    80002df6:	00848713          	addi	a4,s1,8
    80002dfa:	02e7e663          	bltu	a5,a4,80002e26 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002dfe:	46a1                	li	a3,8
    80002e00:	8626                	mv	a2,s1
    80002e02:	85ca                	mv	a1,s2
    80002e04:	6d28                	ld	a0,88(a0)
    80002e06:	fffff097          	auipc	ra,0xfffff
    80002e0a:	d2e080e7          	jalr	-722(ra) # 80001b34 <copyin>
    80002e0e:	00a03533          	snez	a0,a0
    80002e12:	40a00533          	neg	a0,a0
}
    80002e16:	60e2                	ld	ra,24(sp)
    80002e18:	6442                	ld	s0,16(sp)
    80002e1a:	64a2                	ld	s1,8(sp)
    80002e1c:	6902                	ld	s2,0(sp)
    80002e1e:	6105                	addi	sp,sp,32
    80002e20:	8082                	ret
    return -1;
    80002e22:	557d                	li	a0,-1
    80002e24:	bfcd                	j	80002e16 <fetchaddr+0x3e>
    80002e26:	557d                	li	a0,-1
    80002e28:	b7fd                	j	80002e16 <fetchaddr+0x3e>

0000000080002e2a <fetchstr>:
{
    80002e2a:	7179                	addi	sp,sp,-48
    80002e2c:	f406                	sd	ra,40(sp)
    80002e2e:	f022                	sd	s0,32(sp)
    80002e30:	ec26                	sd	s1,24(sp)
    80002e32:	e84a                	sd	s2,16(sp)
    80002e34:	e44e                	sd	s3,8(sp)
    80002e36:	1800                	addi	s0,sp,48
    80002e38:	892a                	mv	s2,a0
    80002e3a:	84ae                	mv	s1,a1
    80002e3c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002e3e:	fffff097          	auipc	ra,0xfffff
    80002e42:	f76080e7          	jalr	-138(ra) # 80001db4 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002e46:	86ce                	mv	a3,s3
    80002e48:	864a                	mv	a2,s2
    80002e4a:	85a6                	mv	a1,s1
    80002e4c:	6d28                	ld	a0,88(a0)
    80002e4e:	fffff097          	auipc	ra,0xfffff
    80002e52:	d72080e7          	jalr	-654(ra) # 80001bc0 <copyinstr>
  if(err < 0)
    80002e56:	00054763          	bltz	a0,80002e64 <fetchstr+0x3a>
  return strlen(buf);
    80002e5a:	8526                	mv	a0,s1
    80002e5c:	ffffe097          	auipc	ra,0xffffe
    80002e60:	478080e7          	jalr	1144(ra) # 800012d4 <strlen>
}
    80002e64:	70a2                	ld	ra,40(sp)
    80002e66:	7402                	ld	s0,32(sp)
    80002e68:	64e2                	ld	s1,24(sp)
    80002e6a:	6942                	ld	s2,16(sp)
    80002e6c:	69a2                	ld	s3,8(sp)
    80002e6e:	6145                	addi	sp,sp,48
    80002e70:	8082                	ret

0000000080002e72 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002e72:	1101                	addi	sp,sp,-32
    80002e74:	ec06                	sd	ra,24(sp)
    80002e76:	e822                	sd	s0,16(sp)
    80002e78:	e426                	sd	s1,8(sp)
    80002e7a:	1000                	addi	s0,sp,32
    80002e7c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e7e:	00000097          	auipc	ra,0x0
    80002e82:	ef2080e7          	jalr	-270(ra) # 80002d70 <argraw>
    80002e86:	c088                	sw	a0,0(s1)
  return 0;
}
    80002e88:	4501                	li	a0,0
    80002e8a:	60e2                	ld	ra,24(sp)
    80002e8c:	6442                	ld	s0,16(sp)
    80002e8e:	64a2                	ld	s1,8(sp)
    80002e90:	6105                	addi	sp,sp,32
    80002e92:	8082                	ret

0000000080002e94 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002e94:	1101                	addi	sp,sp,-32
    80002e96:	ec06                	sd	ra,24(sp)
    80002e98:	e822                	sd	s0,16(sp)
    80002e9a:	e426                	sd	s1,8(sp)
    80002e9c:	1000                	addi	s0,sp,32
    80002e9e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ea0:	00000097          	auipc	ra,0x0
    80002ea4:	ed0080e7          	jalr	-304(ra) # 80002d70 <argraw>
    80002ea8:	e088                	sd	a0,0(s1)
  return 0;
}
    80002eaa:	4501                	li	a0,0
    80002eac:	60e2                	ld	ra,24(sp)
    80002eae:	6442                	ld	s0,16(sp)
    80002eb0:	64a2                	ld	s1,8(sp)
    80002eb2:	6105                	addi	sp,sp,32
    80002eb4:	8082                	ret

0000000080002eb6 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002eb6:	1101                	addi	sp,sp,-32
    80002eb8:	ec06                	sd	ra,24(sp)
    80002eba:	e822                	sd	s0,16(sp)
    80002ebc:	e426                	sd	s1,8(sp)
    80002ebe:	e04a                	sd	s2,0(sp)
    80002ec0:	1000                	addi	s0,sp,32
    80002ec2:	84ae                	mv	s1,a1
    80002ec4:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002ec6:	00000097          	auipc	ra,0x0
    80002eca:	eaa080e7          	jalr	-342(ra) # 80002d70 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002ece:	864a                	mv	a2,s2
    80002ed0:	85a6                	mv	a1,s1
    80002ed2:	00000097          	auipc	ra,0x0
    80002ed6:	f58080e7          	jalr	-168(ra) # 80002e2a <fetchstr>
}
    80002eda:	60e2                	ld	ra,24(sp)
    80002edc:	6442                	ld	s0,16(sp)
    80002ede:	64a2                	ld	s1,8(sp)
    80002ee0:	6902                	ld	s2,0(sp)
    80002ee2:	6105                	addi	sp,sp,32
    80002ee4:	8082                	ret

0000000080002ee6 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002ee6:	1101                	addi	sp,sp,-32
    80002ee8:	ec06                	sd	ra,24(sp)
    80002eea:	e822                	sd	s0,16(sp)
    80002eec:	e426                	sd	s1,8(sp)
    80002eee:	e04a                	sd	s2,0(sp)
    80002ef0:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002ef2:	fffff097          	auipc	ra,0xfffff
    80002ef6:	ec2080e7          	jalr	-318(ra) # 80001db4 <myproc>
    80002efa:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002efc:	06053903          	ld	s2,96(a0)
    80002f00:	0a893783          	ld	a5,168(s2)
    80002f04:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002f08:	37fd                	addiw	a5,a5,-1
    80002f0a:	4751                	li	a4,20
    80002f0c:	00f76f63          	bltu	a4,a5,80002f2a <syscall+0x44>
    80002f10:	00369713          	slli	a4,a3,0x3
    80002f14:	00005797          	auipc	a5,0x5
    80002f18:	5bc78793          	addi	a5,a5,1468 # 800084d0 <syscalls>
    80002f1c:	97ba                	add	a5,a5,a4
    80002f1e:	639c                	ld	a5,0(a5)
    80002f20:	c789                	beqz	a5,80002f2a <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002f22:	9782                	jalr	a5
    80002f24:	06a93823          	sd	a0,112(s2)
    80002f28:	a839                	j	80002f46 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002f2a:	16048613          	addi	a2,s1,352
    80002f2e:	40ac                	lw	a1,64(s1)
    80002f30:	00005517          	auipc	a0,0x5
    80002f34:	56850513          	addi	a0,a0,1384 # 80008498 <states.1712+0x148>
    80002f38:	ffffd097          	auipc	ra,0xffffd
    80002f3c:	662080e7          	jalr	1634(ra) # 8000059a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002f40:	70bc                	ld	a5,96(s1)
    80002f42:	577d                	li	a4,-1
    80002f44:	fbb8                	sd	a4,112(a5)
  }
}
    80002f46:	60e2                	ld	ra,24(sp)
    80002f48:	6442                	ld	s0,16(sp)
    80002f4a:	64a2                	ld	s1,8(sp)
    80002f4c:	6902                	ld	s2,0(sp)
    80002f4e:	6105                	addi	sp,sp,32
    80002f50:	8082                	ret

0000000080002f52 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002f52:	1101                	addi	sp,sp,-32
    80002f54:	ec06                	sd	ra,24(sp)
    80002f56:	e822                	sd	s0,16(sp)
    80002f58:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002f5a:	fec40593          	addi	a1,s0,-20
    80002f5e:	4501                	li	a0,0
    80002f60:	00000097          	auipc	ra,0x0
    80002f64:	f12080e7          	jalr	-238(ra) # 80002e72 <argint>
    return -1;
    80002f68:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f6a:	00054963          	bltz	a0,80002f7c <sys_exit+0x2a>
  exit(n);
    80002f6e:	fec42503          	lw	a0,-20(s0)
    80002f72:	fffff097          	auipc	ra,0xfffff
    80002f76:	50c080e7          	jalr	1292(ra) # 8000247e <exit>
  return 0;  // not reached
    80002f7a:	4781                	li	a5,0
}
    80002f7c:	853e                	mv	a0,a5
    80002f7e:	60e2                	ld	ra,24(sp)
    80002f80:	6442                	ld	s0,16(sp)
    80002f82:	6105                	addi	sp,sp,32
    80002f84:	8082                	ret

0000000080002f86 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002f86:	1141                	addi	sp,sp,-16
    80002f88:	e406                	sd	ra,8(sp)
    80002f8a:	e022                	sd	s0,0(sp)
    80002f8c:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002f8e:	fffff097          	auipc	ra,0xfffff
    80002f92:	e26080e7          	jalr	-474(ra) # 80001db4 <myproc>
}
    80002f96:	4128                	lw	a0,64(a0)
    80002f98:	60a2                	ld	ra,8(sp)
    80002f9a:	6402                	ld	s0,0(sp)
    80002f9c:	0141                	addi	sp,sp,16
    80002f9e:	8082                	ret

0000000080002fa0 <sys_fork>:

uint64
sys_fork(void)
{
    80002fa0:	1141                	addi	sp,sp,-16
    80002fa2:	e406                	sd	ra,8(sp)
    80002fa4:	e022                	sd	s0,0(sp)
    80002fa6:	0800                	addi	s0,sp,16
  return fork();
    80002fa8:	fffff097          	auipc	ra,0xfffff
    80002fac:	1cc080e7          	jalr	460(ra) # 80002174 <fork>
}
    80002fb0:	60a2                	ld	ra,8(sp)
    80002fb2:	6402                	ld	s0,0(sp)
    80002fb4:	0141                	addi	sp,sp,16
    80002fb6:	8082                	ret

0000000080002fb8 <sys_wait>:

uint64
sys_wait(void)
{
    80002fb8:	1101                	addi	sp,sp,-32
    80002fba:	ec06                	sd	ra,24(sp)
    80002fbc:	e822                	sd	s0,16(sp)
    80002fbe:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002fc0:	fe840593          	addi	a1,s0,-24
    80002fc4:	4501                	li	a0,0
    80002fc6:	00000097          	auipc	ra,0x0
    80002fca:	ece080e7          	jalr	-306(ra) # 80002e94 <argaddr>
    80002fce:	87aa                	mv	a5,a0
    return -1;
    80002fd0:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002fd2:	0007c863          	bltz	a5,80002fe2 <sys_wait+0x2a>
  return wait(p);
    80002fd6:	fe843503          	ld	a0,-24(s0)
    80002fda:	fffff097          	auipc	ra,0xfffff
    80002fde:	668080e7          	jalr	1640(ra) # 80002642 <wait>
}
    80002fe2:	60e2                	ld	ra,24(sp)
    80002fe4:	6442                	ld	s0,16(sp)
    80002fe6:	6105                	addi	sp,sp,32
    80002fe8:	8082                	ret

0000000080002fea <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002fea:	7179                	addi	sp,sp,-48
    80002fec:	f406                	sd	ra,40(sp)
    80002fee:	f022                	sd	s0,32(sp)
    80002ff0:	ec26                	sd	s1,24(sp)
    80002ff2:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002ff4:	fdc40593          	addi	a1,s0,-36
    80002ff8:	4501                	li	a0,0
    80002ffa:	00000097          	auipc	ra,0x0
    80002ffe:	e78080e7          	jalr	-392(ra) # 80002e72 <argint>
    80003002:	87aa                	mv	a5,a0
    return -1;
    80003004:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80003006:	0207c063          	bltz	a5,80003026 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    8000300a:	fffff097          	auipc	ra,0xfffff
    8000300e:	daa080e7          	jalr	-598(ra) # 80001db4 <myproc>
    80003012:	4924                	lw	s1,80(a0)
  if(growproc(n) < 0)
    80003014:	fdc42503          	lw	a0,-36(s0)
    80003018:	fffff097          	auipc	ra,0xfffff
    8000301c:	0e8080e7          	jalr	232(ra) # 80002100 <growproc>
    80003020:	00054863          	bltz	a0,80003030 <sys_sbrk+0x46>
    return -1;
  return addr;
    80003024:	8526                	mv	a0,s1
}
    80003026:	70a2                	ld	ra,40(sp)
    80003028:	7402                	ld	s0,32(sp)
    8000302a:	64e2                	ld	s1,24(sp)
    8000302c:	6145                	addi	sp,sp,48
    8000302e:	8082                	ret
    return -1;
    80003030:	557d                	li	a0,-1
    80003032:	bfd5                	j	80003026 <sys_sbrk+0x3c>

0000000080003034 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003034:	7139                	addi	sp,sp,-64
    80003036:	fc06                	sd	ra,56(sp)
    80003038:	f822                	sd	s0,48(sp)
    8000303a:	f426                	sd	s1,40(sp)
    8000303c:	f04a                	sd	s2,32(sp)
    8000303e:	ec4e                	sd	s3,24(sp)
    80003040:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003042:	fcc40593          	addi	a1,s0,-52
    80003046:	4501                	li	a0,0
    80003048:	00000097          	auipc	ra,0x0
    8000304c:	e2a080e7          	jalr	-470(ra) # 80002e72 <argint>
    return -1;
    80003050:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003052:	06054563          	bltz	a0,800030bc <sys_sleep+0x88>
  acquire(&tickslock);
    80003056:	00015517          	auipc	a0,0x15
    8000305a:	35250513          	addi	a0,a0,850 # 800183a8 <tickslock>
    8000305e:	ffffe097          	auipc	ra,0xffffe
    80003062:	d0e080e7          	jalr	-754(ra) # 80000d6c <acquire>
  ticks0 = ticks;
    80003066:	00006917          	auipc	s2,0x6
    8000306a:	fba92903          	lw	s2,-70(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    8000306e:	fcc42783          	lw	a5,-52(s0)
    80003072:	cf85                	beqz	a5,800030aa <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003074:	00015997          	auipc	s3,0x15
    80003078:	33498993          	addi	s3,s3,820 # 800183a8 <tickslock>
    8000307c:	00006497          	auipc	s1,0x6
    80003080:	fa448493          	addi	s1,s1,-92 # 80009020 <ticks>
    if(myproc()->killed){
    80003084:	fffff097          	auipc	ra,0xfffff
    80003088:	d30080e7          	jalr	-720(ra) # 80001db4 <myproc>
    8000308c:	5d1c                	lw	a5,56(a0)
    8000308e:	ef9d                	bnez	a5,800030cc <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003090:	85ce                	mv	a1,s3
    80003092:	8526                	mv	a0,s1
    80003094:	fffff097          	auipc	ra,0xfffff
    80003098:	530080e7          	jalr	1328(ra) # 800025c4 <sleep>
  while(ticks - ticks0 < n){
    8000309c:	409c                	lw	a5,0(s1)
    8000309e:	412787bb          	subw	a5,a5,s2
    800030a2:	fcc42703          	lw	a4,-52(s0)
    800030a6:	fce7efe3          	bltu	a5,a4,80003084 <sys_sleep+0x50>
  }
  release(&tickslock);
    800030aa:	00015517          	auipc	a0,0x15
    800030ae:	2fe50513          	addi	a0,a0,766 # 800183a8 <tickslock>
    800030b2:	ffffe097          	auipc	ra,0xffffe
    800030b6:	d8a080e7          	jalr	-630(ra) # 80000e3c <release>
  return 0;
    800030ba:	4781                	li	a5,0
}
    800030bc:	853e                	mv	a0,a5
    800030be:	70e2                	ld	ra,56(sp)
    800030c0:	7442                	ld	s0,48(sp)
    800030c2:	74a2                	ld	s1,40(sp)
    800030c4:	7902                	ld	s2,32(sp)
    800030c6:	69e2                	ld	s3,24(sp)
    800030c8:	6121                	addi	sp,sp,64
    800030ca:	8082                	ret
      release(&tickslock);
    800030cc:	00015517          	auipc	a0,0x15
    800030d0:	2dc50513          	addi	a0,a0,732 # 800183a8 <tickslock>
    800030d4:	ffffe097          	auipc	ra,0xffffe
    800030d8:	d68080e7          	jalr	-664(ra) # 80000e3c <release>
      return -1;
    800030dc:	57fd                	li	a5,-1
    800030de:	bff9                	j	800030bc <sys_sleep+0x88>

00000000800030e0 <sys_kill>:

uint64
sys_kill(void)
{
    800030e0:	1101                	addi	sp,sp,-32
    800030e2:	ec06                	sd	ra,24(sp)
    800030e4:	e822                	sd	s0,16(sp)
    800030e6:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800030e8:	fec40593          	addi	a1,s0,-20
    800030ec:	4501                	li	a0,0
    800030ee:	00000097          	auipc	ra,0x0
    800030f2:	d84080e7          	jalr	-636(ra) # 80002e72 <argint>
    800030f6:	87aa                	mv	a5,a0
    return -1;
    800030f8:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800030fa:	0007c863          	bltz	a5,8000310a <sys_kill+0x2a>
  return kill(pid);
    800030fe:	fec42503          	lw	a0,-20(s0)
    80003102:	fffff097          	auipc	ra,0xfffff
    80003106:	6b2080e7          	jalr	1714(ra) # 800027b4 <kill>
}
    8000310a:	60e2                	ld	ra,24(sp)
    8000310c:	6442                	ld	s0,16(sp)
    8000310e:	6105                	addi	sp,sp,32
    80003110:	8082                	ret

0000000080003112 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003112:	1101                	addi	sp,sp,-32
    80003114:	ec06                	sd	ra,24(sp)
    80003116:	e822                	sd	s0,16(sp)
    80003118:	e426                	sd	s1,8(sp)
    8000311a:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000311c:	00015517          	auipc	a0,0x15
    80003120:	28c50513          	addi	a0,a0,652 # 800183a8 <tickslock>
    80003124:	ffffe097          	auipc	ra,0xffffe
    80003128:	c48080e7          	jalr	-952(ra) # 80000d6c <acquire>
  xticks = ticks;
    8000312c:	00006497          	auipc	s1,0x6
    80003130:	ef44a483          	lw	s1,-268(s1) # 80009020 <ticks>
  release(&tickslock);
    80003134:	00015517          	auipc	a0,0x15
    80003138:	27450513          	addi	a0,a0,628 # 800183a8 <tickslock>
    8000313c:	ffffe097          	auipc	ra,0xffffe
    80003140:	d00080e7          	jalr	-768(ra) # 80000e3c <release>
  return xticks;
}
    80003144:	02049513          	slli	a0,s1,0x20
    80003148:	9101                	srli	a0,a0,0x20
    8000314a:	60e2                	ld	ra,24(sp)
    8000314c:	6442                	ld	s0,16(sp)
    8000314e:	64a2                	ld	s1,8(sp)
    80003150:	6105                	addi	sp,sp,32
    80003152:	8082                	ret

0000000080003154 <replacebuf>:

static struct bucket hashTable[NBUC];

void
replacebuf(struct buf *lrubuf,uint dev, uint blockno)
{
    80003154:	1141                	addi	sp,sp,-16
    80003156:	e422                	sd	s0,8(sp)
    80003158:	0800                	addi	s0,sp,16
  lrubuf->dev = dev;
    8000315a:	c50c                	sw	a1,8(a0)
  lrubuf->blockno = blockno;
    8000315c:	c550                	sw	a2,12(a0)
  lrubuf->valid = 0;
    8000315e:	00052023          	sw	zero,0(a0)
  lrubuf->refcnt = 1;
    80003162:	4785                	li	a5,1
    80003164:	c53c                	sw	a5,72(a0)
  lrubuf->tick =ticks;
    80003166:	00006797          	auipc	a5,0x6
    8000316a:	eba7a783          	lw	a5,-326(a5) # 80009020 <ticks>
    8000316e:	46f52023          	sw	a5,1120(a0)
}
    80003172:	6422                	ld	s0,8(sp)
    80003174:	0141                	addi	sp,sp,16
    80003176:	8082                	ret

0000000080003178 <binit>:

void
binit(void)
{
    80003178:	7179                	addi	sp,sp,-48
    8000317a:	f406                	sd	ra,40(sp)
    8000317c:	f022                	sd	s0,32(sp)
    8000317e:	ec26                	sd	s1,24(sp)
    80003180:	e84a                	sd	s2,16(sp)
    80003182:	e44e                	sd	s3,8(sp)
    80003184:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003186:	00005597          	auipc	a1,0x5
    8000318a:	f9258593          	addi	a1,a1,-110 # 80008118 <digits+0xd8>
    8000318e:	00019517          	auipc	a0,0x19
    80003192:	d2250513          	addi	a0,a0,-734 # 8001beb0 <bcache>
    80003196:	ffffe097          	auipc	ra,0xffffe
    8000319a:	d52080e7          	jalr	-686(ra) # 80000ee8 <initlock>

  for(b = bcache.buf; b < bcache.buf+NBUF; b++)
    8000319e:	00019497          	auipc	s1,0x19
    800031a2:	d4248493          	addi	s1,s1,-702 # 8001bee0 <bcache+0x30>
    800031a6:	00021997          	auipc	s3,0x21
    800031aa:	16a98993          	addi	s3,s3,362 # 80024310 <sb+0x10>
  {
    initsleeplock(&b->lock, "buffer");
    800031ae:	00005917          	auipc	s2,0x5
    800031b2:	3d290913          	addi	s2,s2,978 # 80008580 <syscalls+0xb0>
    800031b6:	85ca                	mv	a1,s2
    800031b8:	8526                	mv	a0,s1
    800031ba:	00001097          	auipc	ra,0x1
    800031be:	654080e7          	jalr	1620(ra) # 8000480e <initsleeplock>
    b->tick = 0;
    800031c2:	4404a823          	sw	zero,1104(s1)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++)
    800031c6:	46848493          	addi	s1,s1,1128
    800031ca:	ff3496e3          	bne	s1,s3,800031b6 <binit+0x3e>
    800031ce:	00015497          	auipc	s1,0x15
    800031d2:	1fa48493          	addi	s1,s1,506 # 800183c8 <hashTable>
    800031d6:	00019997          	auipc	s3,0x19
    800031da:	cda98993          	addi	s3,s3,-806 # 8001beb0 <bcache>
  }
  for(int i=0; i<NBUC; i++)
  {
    initlock(&hashTable[i].lock,"bcache.bucket");
    800031de:	00005917          	auipc	s2,0x5
    800031e2:	3aa90913          	addi	s2,s2,938 # 80008588 <syscalls+0xb8>
    800031e6:	85ca                	mv	a1,s2
    800031e8:	8526                	mv	a0,s1
    800031ea:	ffffe097          	auipc	ra,0xffffe
    800031ee:	cfe080e7          	jalr	-770(ra) # 80000ee8 <initlock>
    hashTable[i].head.next = 0;
    800031f2:	0604b823          	sd	zero,112(s1)
    hashTable[i].head.prev = 0;
    800031f6:	0604bc23          	sd	zero,120(s1)
  for(int i=0; i<NBUC; i++)
    800031fa:	48848493          	addi	s1,s1,1160
    800031fe:	ff3494e3          	bne	s1,s3,800031e6 <binit+0x6e>
  }
}
    80003202:	70a2                	ld	ra,40(sp)
    80003204:	7402                	ld	s0,32(sp)
    80003206:	64e2                	ld	s1,24(sp)
    80003208:	6942                	ld	s2,16(sp)
    8000320a:	69a2                	ld	s3,8(sp)
    8000320c:	6145                	addi	sp,sp,48
    8000320e:	8082                	ret

0000000080003210 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003210:	715d                	addi	sp,sp,-80
    80003212:	e486                	sd	ra,72(sp)
    80003214:	e0a2                	sd	s0,64(sp)
    80003216:	fc26                	sd	s1,56(sp)
    80003218:	f84a                	sd	s2,48(sp)
    8000321a:	f44e                	sd	s3,40(sp)
    8000321c:	f052                	sd	s4,32(sp)
    8000321e:	ec56                	sd	s5,24(sp)
    80003220:	e85a                	sd	s6,16(sp)
    80003222:	e45e                	sd	s7,8(sp)
    80003224:	0880                	addi	s0,sp,80
    80003226:	8baa                	mv	s7,a0
    80003228:	8b2e                	mv	s6,a1
  uint64 hash = blockno%NBUC;
    8000322a:	4935                	li	s2,13
    8000322c:	0325f93b          	remuw	s2,a1,s2
    80003230:	1902                	slli	s2,s2,0x20
    80003232:	02095913          	srli	s2,s2,0x20
  acquire(&hashTable[hash].lock);
    80003236:	48800993          	li	s3,1160
    8000323a:	033909b3          	mul	s3,s2,s3
    8000323e:	00015a97          	auipc	s5,0x15
    80003242:	18aa8a93          	addi	s5,s5,394 # 800183c8 <hashTable>
    80003246:	9ace                	add	s5,s5,s3
    80003248:	8556                	mv	a0,s5
    8000324a:	ffffe097          	auipc	ra,0xffffe
    8000324e:	b22080e7          	jalr	-1246(ra) # 80000d6c <acquire>
  for(b = hashTable[hash].head.next; b; b = b->next){
    80003252:	070ab483          	ld	s1,112(s5)
    80003256:	e495                	bnez	s1,80003282 <bread+0x72>
  acquire(&bcache.lock);
    80003258:	00019517          	auipc	a0,0x19
    8000325c:	c5850513          	addi	a0,a0,-936 # 8001beb0 <bcache>
    80003260:	ffffe097          	auipc	ra,0xffffe
    80003264:	b0c080e7          	jalr	-1268(ra) # 80000d6c <acquire>
  uint64 mintick = 0;
    80003268:	4701                	li	a4,0
  struct buf *lrubuf = 0;
    8000326a:	4481                	li	s1,0
  for(b = bcache.buf; b <bcache.buf+NBUF; b++){
    8000326c:	00019797          	auipc	a5,0x19
    80003270:	c6478793          	addi	a5,a5,-924 # 8001bed0 <bcache+0x20>
    80003274:	00021617          	auipc	a2,0x21
    80003278:	08c60613          	addi	a2,a2,140 # 80024300 <sb>
    8000327c:	a83d                	j	800032ba <bread+0xaa>
  for(b = hashTable[hash].head.next; b; b = b->next){
    8000327e:	68a4                	ld	s1,80(s1)
    80003280:	dce1                	beqz	s1,80003258 <bread+0x48>
    if(b->dev == dev && b->blockno == blockno){
    80003282:	449c                	lw	a5,8(s1)
    80003284:	ff779de3          	bne	a5,s7,8000327e <bread+0x6e>
    80003288:	44dc                	lw	a5,12(s1)
    8000328a:	ff679ae3          	bne	a5,s6,8000327e <bread+0x6e>
      b->refcnt++;
    8000328e:	44bc                	lw	a5,72(s1)
    80003290:	2785                	addiw	a5,a5,1
    80003292:	c4bc                	sw	a5,72(s1)
      release(&hashTable[hash].lock);
    80003294:	8556                	mv	a0,s5
    80003296:	ffffe097          	auipc	ra,0xffffe
    8000329a:	ba6080e7          	jalr	-1114(ra) # 80000e3c <release>
      acquiresleep(&b->lock);
    8000329e:	01048513          	addi	a0,s1,16
    800032a2:	00001097          	auipc	ra,0x1
    800032a6:	5a6080e7          	jalr	1446(ra) # 80004848 <acquiresleep>
      return b;
    800032aa:	a8dd                	j	800033a0 <bread+0x190>
        mintick = b->tick;
    800032ac:	4607e703          	lwu	a4,1120(a5)
        continue;
    800032b0:	84be                	mv	s1,a5
  for(b = bcache.buf; b <bcache.buf+NBUF; b++){
    800032b2:	46878793          	addi	a5,a5,1128
    800032b6:	00c78c63          	beq	a5,a2,800032ce <bread+0xbe>
    if(b->refcnt == 0) 
    800032ba:	47b4                	lw	a3,72(a5)
    800032bc:	fafd                	bnez	a3,800032b2 <bread+0xa2>
      if(lrubuf ==0)
    800032be:	d4fd                	beqz	s1,800032ac <bread+0x9c>
      if(b->tick<mintick)
    800032c0:	4607e683          	lwu	a3,1120(a5)
    800032c4:	fee6f7e3          	bgeu	a3,a4,800032b2 <bread+0xa2>
        mintick = b->tick;
    800032c8:	8736                	mv	a4,a3
      if(b->tick<mintick)
    800032ca:	84be                	mv	s1,a5
    800032cc:	b7dd                	j	800032b2 <bread+0xa2>
  if(lrubuf)
    800032ce:	16048063          	beqz	s1,8000342e <bread+0x21e>
    uint64 oldblockno = lrubuf->blockno;
    800032d2:	00c4ea03          	lwu	s4,12(s1)
    if(oldtick == 0)
    800032d6:	4604a783          	lw	a5,1120(s1)
    800032da:	c3ed                	beqz	a5,800033bc <bread+0x1ac>
      if(hash != oldblockno%NBUC)
    800032dc:	47b5                	li	a5,13
    800032de:	02fa7a33          	remu	s4,s4,a5
    800032e2:	11490463          	beq	s2,s4,800033ea <bread+0x1da>
        if(holding(&hashTable[oldblockno%NBUC].lock))
    800032e6:	48800793          	li	a5,1160
    800032ea:	02fa0a33          	mul	s4,s4,a5
    800032ee:	00015797          	auipc	a5,0x15
    800032f2:	0da78793          	addi	a5,a5,218 # 800183c8 <hashTable>
    800032f6:	9a3e                	add	s4,s4,a5
    800032f8:	8552                	mv	a0,s4
    800032fa:	ffffe097          	auipc	ra,0xffffe
    800032fe:	9f8080e7          	jalr	-1544(ra) # 80000cf2 <holding>
    80003302:	ed61                	bnez	a0,800033da <bread+0x1ca>
        acquire(&hashTable[oldblockno%NBUC].lock);
    80003304:	8552                	mv	a0,s4
    80003306:	ffffe097          	auipc	ra,0xffffe
    8000330a:	a66080e7          	jalr	-1434(ra) # 80000d6c <acquire>
  lrubuf->dev = dev;
    8000330e:	0174a423          	sw	s7,8(s1)
  lrubuf->blockno = blockno;
    80003312:	0164a623          	sw	s6,12(s1)
  lrubuf->valid = 0;
    80003316:	0004a023          	sw	zero,0(s1)
  lrubuf->refcnt = 1;
    8000331a:	4785                	li	a5,1
    8000331c:	c4bc                	sw	a5,72(s1)
  lrubuf->tick =ticks;
    8000331e:	00006797          	auipc	a5,0x6
    80003322:	d027a783          	lw	a5,-766(a5) # 80009020 <ticks>
    80003326:	46f4a023          	sw	a5,1120(s1)
        lrubuf->prev->next = lrubuf->next;
    8000332a:	6cb8                	ld	a4,88(s1)
    8000332c:	68bc                	ld	a5,80(s1)
    8000332e:	eb3c                	sd	a5,80(a4)
        if(lrubuf->next)
    80003330:	c399                	beqz	a5,80003336 <bread+0x126>
          lrubuf->next->prev = lrubuf->prev;
    80003332:	6cb8                	ld	a4,88(s1)
    80003334:	efb8                	sd	a4,88(a5)
        release(&hashTable[oldblockno%NBUC].lock);
    80003336:	8552                	mv	a0,s4
    80003338:	ffffe097          	auipc	ra,0xffffe
    8000333c:	b04080e7          	jalr	-1276(ra) # 80000e3c <release>
    lrubuf->next = hashTable[hash].head.next;
    80003340:	00015717          	auipc	a4,0x15
    80003344:	08870713          	addi	a4,a4,136 # 800183c8 <hashTable>
    80003348:	48800793          	li	a5,1160
    8000334c:	02f907b3          	mul	a5,s2,a5
    80003350:	97ba                	add	a5,a5,a4
    80003352:	7bbc                	ld	a5,112(a5)
    80003354:	e8bc                	sd	a5,80(s1)
    lrubuf->prev = &hashTable[hash].head;
    80003356:	02098993          	addi	s3,s3,32
    8000335a:	99ba                	add	s3,s3,a4
    8000335c:	0534bc23          	sd	s3,88(s1)
    if(hashTable[hash].head.next)
    80003360:	c391                	beqz	a5,80003364 <bread+0x154>
      hashTable[hash].head.next->prev = lrubuf;
    80003362:	efa4                	sd	s1,88(a5)
    hashTable[hash].head.next = lrubuf;
    80003364:	48800793          	li	a5,1160
    80003368:	02f90933          	mul	s2,s2,a5
    8000336c:	00015797          	auipc	a5,0x15
    80003370:	05c78793          	addi	a5,a5,92 # 800183c8 <hashTable>
    80003374:	993e                	add	s2,s2,a5
    80003376:	06993823          	sd	s1,112(s2)
    release(&bcache.lock);
    8000337a:	00019517          	auipc	a0,0x19
    8000337e:	b3650513          	addi	a0,a0,-1226 # 8001beb0 <bcache>
    80003382:	ffffe097          	auipc	ra,0xffffe
    80003386:	aba080e7          	jalr	-1350(ra) # 80000e3c <release>
    release(&hashTable[hash].lock);
    8000338a:	8556                	mv	a0,s5
    8000338c:	ffffe097          	auipc	ra,0xffffe
    80003390:	ab0080e7          	jalr	-1360(ra) # 80000e3c <release>
    acquiresleep(&lrubuf->lock);
    80003394:	01048513          	addi	a0,s1,16
    80003398:	00001097          	auipc	ra,0x1
    8000339c:	4b0080e7          	jalr	1200(ra) # 80004848 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800033a0:	409c                	lw	a5,0(s1)
    800033a2:	cfd1                	beqz	a5,8000343e <bread+0x22e>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800033a4:	8526                	mv	a0,s1
    800033a6:	60a6                	ld	ra,72(sp)
    800033a8:	6406                	ld	s0,64(sp)
    800033aa:	74e2                	ld	s1,56(sp)
    800033ac:	7942                	ld	s2,48(sp)
    800033ae:	79a2                	ld	s3,40(sp)
    800033b0:	7a02                	ld	s4,32(sp)
    800033b2:	6ae2                	ld	s5,24(sp)
    800033b4:	6b42                	ld	s6,16(sp)
    800033b6:	6ba2                	ld	s7,8(sp)
    800033b8:	6161                	addi	sp,sp,80
    800033ba:	8082                	ret
  lrubuf->dev = dev;
    800033bc:	0174a423          	sw	s7,8(s1)
  lrubuf->blockno = blockno;
    800033c0:	0164a623          	sw	s6,12(s1)
  lrubuf->valid = 0;
    800033c4:	0004a023          	sw	zero,0(s1)
  lrubuf->refcnt = 1;
    800033c8:	4785                	li	a5,1
    800033ca:	c4bc                	sw	a5,72(s1)
  lrubuf->tick =ticks;
    800033cc:	00006797          	auipc	a5,0x6
    800033d0:	c547a783          	lw	a5,-940(a5) # 80009020 <ticks>
    800033d4:	46f4a023          	sw	a5,1120(s1)
}
    800033d8:	b7a5                	j	80003340 <bread+0x130>
          panic("???");
    800033da:	00005517          	auipc	a0,0x5
    800033de:	f3650513          	addi	a0,a0,-202 # 80008310 <digits+0x2d0>
    800033e2:	ffffd097          	auipc	ra,0xffffd
    800033e6:	16e080e7          	jalr	366(ra) # 80000550 <panic>
  lrubuf->dev = dev;
    800033ea:	0174a423          	sw	s7,8(s1)
  lrubuf->blockno = blockno;
    800033ee:	0164a623          	sw	s6,12(s1)
  lrubuf->valid = 0;
    800033f2:	0004a023          	sw	zero,0(s1)
  lrubuf->refcnt = 1;
    800033f6:	4785                	li	a5,1
    800033f8:	c4bc                	sw	a5,72(s1)
  lrubuf->tick =ticks;
    800033fa:	00006797          	auipc	a5,0x6
    800033fe:	c267a783          	lw	a5,-986(a5) # 80009020 <ticks>
    80003402:	46f4a023          	sw	a5,1120(s1)
        release(&bcache.lock);
    80003406:	00019517          	auipc	a0,0x19
    8000340a:	aaa50513          	addi	a0,a0,-1366 # 8001beb0 <bcache>
    8000340e:	ffffe097          	auipc	ra,0xffffe
    80003412:	a2e080e7          	jalr	-1490(ra) # 80000e3c <release>
        release(&hashTable[hash].lock);
    80003416:	8556                	mv	a0,s5
    80003418:	ffffe097          	auipc	ra,0xffffe
    8000341c:	a24080e7          	jalr	-1500(ra) # 80000e3c <release>
        acquiresleep(&lrubuf->lock);
    80003420:	01048513          	addi	a0,s1,16
    80003424:	00001097          	auipc	ra,0x1
    80003428:	424080e7          	jalr	1060(ra) # 80004848 <acquiresleep>
        return lrubuf;
    8000342c:	bf95                	j	800033a0 <bread+0x190>
  panic("bget: no buffers");
    8000342e:	00005517          	auipc	a0,0x5
    80003432:	16a50513          	addi	a0,a0,362 # 80008598 <syscalls+0xc8>
    80003436:	ffffd097          	auipc	ra,0xffffd
    8000343a:	11a080e7          	jalr	282(ra) # 80000550 <panic>
    virtio_disk_rw(b, 0);
    8000343e:	4581                	li	a1,0
    80003440:	8526                	mv	a0,s1
    80003442:	00003097          	auipc	ra,0x3
    80003446:	f84080e7          	jalr	-124(ra) # 800063c6 <virtio_disk_rw>
    b->valid = 1;
    8000344a:	4785                	li	a5,1
    8000344c:	c09c                	sw	a5,0(s1)
  return b;
    8000344e:	bf99                	j	800033a4 <bread+0x194>

0000000080003450 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003450:	1101                	addi	sp,sp,-32
    80003452:	ec06                	sd	ra,24(sp)
    80003454:	e822                	sd	s0,16(sp)
    80003456:	e426                	sd	s1,8(sp)
    80003458:	1000                	addi	s0,sp,32
    8000345a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000345c:	0541                	addi	a0,a0,16
    8000345e:	00001097          	auipc	ra,0x1
    80003462:	484080e7          	jalr	1156(ra) # 800048e2 <holdingsleep>
    80003466:	cd01                	beqz	a0,8000347e <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003468:	4585                	li	a1,1
    8000346a:	8526                	mv	a0,s1
    8000346c:	00003097          	auipc	ra,0x3
    80003470:	f5a080e7          	jalr	-166(ra) # 800063c6 <virtio_disk_rw>
}
    80003474:	60e2                	ld	ra,24(sp)
    80003476:	6442                	ld	s0,16(sp)
    80003478:	64a2                	ld	s1,8(sp)
    8000347a:	6105                	addi	sp,sp,32
    8000347c:	8082                	ret
    panic("bwrite");
    8000347e:	00005517          	auipc	a0,0x5
    80003482:	13250513          	addi	a0,a0,306 # 800085b0 <syscalls+0xe0>
    80003486:	ffffd097          	auipc	ra,0xffffd
    8000348a:	0ca080e7          	jalr	202(ra) # 80000550 <panic>

000000008000348e <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000348e:	1101                	addi	sp,sp,-32
    80003490:	ec06                	sd	ra,24(sp)
    80003492:	e822                	sd	s0,16(sp)
    80003494:	e426                	sd	s1,8(sp)
    80003496:	e04a                	sd	s2,0(sp)
    80003498:	1000                	addi	s0,sp,32
    8000349a:	892a                	mv	s2,a0
  if(!holdingsleep(&b->lock))
    8000349c:	01050493          	addi	s1,a0,16
    800034a0:	8526                	mv	a0,s1
    800034a2:	00001097          	auipc	ra,0x1
    800034a6:	440080e7          	jalr	1088(ra) # 800048e2 <holdingsleep>
    800034aa:	c939                	beqz	a0,80003500 <brelse+0x72>
    panic("brelse");

  releasesleep(&b->lock);
    800034ac:	8526                	mv	a0,s1
    800034ae:	00001097          	auipc	ra,0x1
    800034b2:	3f0080e7          	jalr	1008(ra) # 8000489e <releasesleep>

  uint64 hash = b->blockno%NBUC;
    800034b6:	00c92483          	lw	s1,12(s2)
    800034ba:	47b5                	li	a5,13
    800034bc:	02f4f4bb          	remuw	s1,s1,a5
    800034c0:	1482                	slli	s1,s1,0x20
    800034c2:	9081                	srli	s1,s1,0x20
  acquire(&hashTable[hash].lock);
    800034c4:	48800793          	li	a5,1160
    800034c8:	02f484b3          	mul	s1,s1,a5
    800034cc:	00015797          	auipc	a5,0x15
    800034d0:	efc78793          	addi	a5,a5,-260 # 800183c8 <hashTable>
    800034d4:	94be                	add	s1,s1,a5
    800034d6:	8526                	mv	a0,s1
    800034d8:	ffffe097          	auipc	ra,0xffffe
    800034dc:	894080e7          	jalr	-1900(ra) # 80000d6c <acquire>
  b->refcnt--;
    800034e0:	04892783          	lw	a5,72(s2)
    800034e4:	37fd                	addiw	a5,a5,-1
    800034e6:	04f92423          	sw	a5,72(s2)
  release(&hashTable[hash].lock);
    800034ea:	8526                	mv	a0,s1
    800034ec:	ffffe097          	auipc	ra,0xffffe
    800034f0:	950080e7          	jalr	-1712(ra) # 80000e3c <release>
}
    800034f4:	60e2                	ld	ra,24(sp)
    800034f6:	6442                	ld	s0,16(sp)
    800034f8:	64a2                	ld	s1,8(sp)
    800034fa:	6902                	ld	s2,0(sp)
    800034fc:	6105                	addi	sp,sp,32
    800034fe:	8082                	ret
    panic("brelse");
    80003500:	00005517          	auipc	a0,0x5
    80003504:	0b850513          	addi	a0,a0,184 # 800085b8 <syscalls+0xe8>
    80003508:	ffffd097          	auipc	ra,0xffffd
    8000350c:	048080e7          	jalr	72(ra) # 80000550 <panic>

0000000080003510 <bpin>:

void
bpin(struct buf *b) {
    80003510:	1101                	addi	sp,sp,-32
    80003512:	ec06                	sd	ra,24(sp)
    80003514:	e822                	sd	s0,16(sp)
    80003516:	e426                	sd	s1,8(sp)
    80003518:	e04a                	sd	s2,0(sp)
    8000351a:	1000                	addi	s0,sp,32
    8000351c:	892a                	mv	s2,a0
  uint64 hash = b->blockno%NBUC;
    8000351e:	4544                	lw	s1,12(a0)
    80003520:	47b5                	li	a5,13
    80003522:	02f4f4bb          	remuw	s1,s1,a5
    80003526:	1482                	slli	s1,s1,0x20
    80003528:	9081                	srli	s1,s1,0x20
  acquire(&hashTable[hash].lock);
    8000352a:	48800793          	li	a5,1160
    8000352e:	02f484b3          	mul	s1,s1,a5
    80003532:	00015797          	auipc	a5,0x15
    80003536:	e9678793          	addi	a5,a5,-362 # 800183c8 <hashTable>
    8000353a:	94be                	add	s1,s1,a5
    8000353c:	8526                	mv	a0,s1
    8000353e:	ffffe097          	auipc	ra,0xffffe
    80003542:	82e080e7          	jalr	-2002(ra) # 80000d6c <acquire>
  b->refcnt++;
    80003546:	04892783          	lw	a5,72(s2)
    8000354a:	2785                	addiw	a5,a5,1
    8000354c:	04f92423          	sw	a5,72(s2)
  release(&hashTable[hash].lock);
    80003550:	8526                	mv	a0,s1
    80003552:	ffffe097          	auipc	ra,0xffffe
    80003556:	8ea080e7          	jalr	-1814(ra) # 80000e3c <release>
}
    8000355a:	60e2                	ld	ra,24(sp)
    8000355c:	6442                	ld	s0,16(sp)
    8000355e:	64a2                	ld	s1,8(sp)
    80003560:	6902                	ld	s2,0(sp)
    80003562:	6105                	addi	sp,sp,32
    80003564:	8082                	ret

0000000080003566 <bunpin>:

void
bunpin(struct buf *b) {
    80003566:	1101                	addi	sp,sp,-32
    80003568:	ec06                	sd	ra,24(sp)
    8000356a:	e822                	sd	s0,16(sp)
    8000356c:	e426                	sd	s1,8(sp)
    8000356e:	e04a                	sd	s2,0(sp)
    80003570:	1000                	addi	s0,sp,32
    80003572:	892a                	mv	s2,a0
  uint64 hash = b->blockno%NBUC;
    80003574:	4544                	lw	s1,12(a0)
    80003576:	47b5                	li	a5,13
    80003578:	02f4f4bb          	remuw	s1,s1,a5
    8000357c:	1482                	slli	s1,s1,0x20
    8000357e:	9081                	srli	s1,s1,0x20
  acquire(&hashTable[hash].lock);
    80003580:	48800793          	li	a5,1160
    80003584:	02f484b3          	mul	s1,s1,a5
    80003588:	00015797          	auipc	a5,0x15
    8000358c:	e4078793          	addi	a5,a5,-448 # 800183c8 <hashTable>
    80003590:	94be                	add	s1,s1,a5
    80003592:	8526                	mv	a0,s1
    80003594:	ffffd097          	auipc	ra,0xffffd
    80003598:	7d8080e7          	jalr	2008(ra) # 80000d6c <acquire>
  b->refcnt--;
    8000359c:	04892783          	lw	a5,72(s2)
    800035a0:	37fd                	addiw	a5,a5,-1
    800035a2:	04f92423          	sw	a5,72(s2)
  release(&hashTable[hash].lock);
    800035a6:	8526                	mv	a0,s1
    800035a8:	ffffe097          	auipc	ra,0xffffe
    800035ac:	894080e7          	jalr	-1900(ra) # 80000e3c <release>
}
    800035b0:	60e2                	ld	ra,24(sp)
    800035b2:	6442                	ld	s0,16(sp)
    800035b4:	64a2                	ld	s1,8(sp)
    800035b6:	6902                	ld	s2,0(sp)
    800035b8:	6105                	addi	sp,sp,32
    800035ba:	8082                	ret

00000000800035bc <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800035bc:	1101                	addi	sp,sp,-32
    800035be:	ec06                	sd	ra,24(sp)
    800035c0:	e822                	sd	s0,16(sp)
    800035c2:	e426                	sd	s1,8(sp)
    800035c4:	e04a                	sd	s2,0(sp)
    800035c6:	1000                	addi	s0,sp,32
    800035c8:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800035ca:	00d5d59b          	srliw	a1,a1,0xd
    800035ce:	00021797          	auipc	a5,0x21
    800035d2:	d4e7a783          	lw	a5,-690(a5) # 8002431c <sb+0x1c>
    800035d6:	9dbd                	addw	a1,a1,a5
    800035d8:	00000097          	auipc	ra,0x0
    800035dc:	c38080e7          	jalr	-968(ra) # 80003210 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800035e0:	0074f713          	andi	a4,s1,7
    800035e4:	4785                	li	a5,1
    800035e6:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800035ea:	14ce                	slli	s1,s1,0x33
    800035ec:	90d9                	srli	s1,s1,0x36
    800035ee:	00950733          	add	a4,a0,s1
    800035f2:	06074703          	lbu	a4,96(a4)
    800035f6:	00e7f6b3          	and	a3,a5,a4
    800035fa:	c69d                	beqz	a3,80003628 <bfree+0x6c>
    800035fc:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800035fe:	94aa                	add	s1,s1,a0
    80003600:	fff7c793          	not	a5,a5
    80003604:	8ff9                	and	a5,a5,a4
    80003606:	06f48023          	sb	a5,96(s1)
  log_write(bp);
    8000360a:	00001097          	auipc	ra,0x1
    8000360e:	116080e7          	jalr	278(ra) # 80004720 <log_write>
  brelse(bp);
    80003612:	854a                	mv	a0,s2
    80003614:	00000097          	auipc	ra,0x0
    80003618:	e7a080e7          	jalr	-390(ra) # 8000348e <brelse>
}
    8000361c:	60e2                	ld	ra,24(sp)
    8000361e:	6442                	ld	s0,16(sp)
    80003620:	64a2                	ld	s1,8(sp)
    80003622:	6902                	ld	s2,0(sp)
    80003624:	6105                	addi	sp,sp,32
    80003626:	8082                	ret
    panic("freeing free block");
    80003628:	00005517          	auipc	a0,0x5
    8000362c:	f9850513          	addi	a0,a0,-104 # 800085c0 <syscalls+0xf0>
    80003630:	ffffd097          	auipc	ra,0xffffd
    80003634:	f20080e7          	jalr	-224(ra) # 80000550 <panic>

0000000080003638 <balloc>:
{
    80003638:	711d                	addi	sp,sp,-96
    8000363a:	ec86                	sd	ra,88(sp)
    8000363c:	e8a2                	sd	s0,80(sp)
    8000363e:	e4a6                	sd	s1,72(sp)
    80003640:	e0ca                	sd	s2,64(sp)
    80003642:	fc4e                	sd	s3,56(sp)
    80003644:	f852                	sd	s4,48(sp)
    80003646:	f456                	sd	s5,40(sp)
    80003648:	f05a                	sd	s6,32(sp)
    8000364a:	ec5e                	sd	s7,24(sp)
    8000364c:	e862                	sd	s8,16(sp)
    8000364e:	e466                	sd	s9,8(sp)
    80003650:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003652:	00021797          	auipc	a5,0x21
    80003656:	cb27a783          	lw	a5,-846(a5) # 80024304 <sb+0x4>
    8000365a:	cbd1                	beqz	a5,800036ee <balloc+0xb6>
    8000365c:	8baa                	mv	s7,a0
    8000365e:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003660:	00021b17          	auipc	s6,0x21
    80003664:	ca0b0b13          	addi	s6,s6,-864 # 80024300 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003668:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000366a:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000366c:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000366e:	6c89                	lui	s9,0x2
    80003670:	a831                	j	8000368c <balloc+0x54>
    brelse(bp);
    80003672:	854a                	mv	a0,s2
    80003674:	00000097          	auipc	ra,0x0
    80003678:	e1a080e7          	jalr	-486(ra) # 8000348e <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000367c:	015c87bb          	addw	a5,s9,s5
    80003680:	00078a9b          	sext.w	s5,a5
    80003684:	004b2703          	lw	a4,4(s6)
    80003688:	06eaf363          	bgeu	s5,a4,800036ee <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000368c:	41fad79b          	sraiw	a5,s5,0x1f
    80003690:	0137d79b          	srliw	a5,a5,0x13
    80003694:	015787bb          	addw	a5,a5,s5
    80003698:	40d7d79b          	sraiw	a5,a5,0xd
    8000369c:	01cb2583          	lw	a1,28(s6)
    800036a0:	9dbd                	addw	a1,a1,a5
    800036a2:	855e                	mv	a0,s7
    800036a4:	00000097          	auipc	ra,0x0
    800036a8:	b6c080e7          	jalr	-1172(ra) # 80003210 <bread>
    800036ac:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036ae:	004b2503          	lw	a0,4(s6)
    800036b2:	000a849b          	sext.w	s1,s5
    800036b6:	8662                	mv	a2,s8
    800036b8:	faa4fde3          	bgeu	s1,a0,80003672 <balloc+0x3a>
      m = 1 << (bi % 8);
    800036bc:	41f6579b          	sraiw	a5,a2,0x1f
    800036c0:	01d7d69b          	srliw	a3,a5,0x1d
    800036c4:	00c6873b          	addw	a4,a3,a2
    800036c8:	00777793          	andi	a5,a4,7
    800036cc:	9f95                	subw	a5,a5,a3
    800036ce:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800036d2:	4037571b          	sraiw	a4,a4,0x3
    800036d6:	00e906b3          	add	a3,s2,a4
    800036da:	0606c683          	lbu	a3,96(a3)
    800036de:	00d7f5b3          	and	a1,a5,a3
    800036e2:	cd91                	beqz	a1,800036fe <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036e4:	2605                	addiw	a2,a2,1
    800036e6:	2485                	addiw	s1,s1,1
    800036e8:	fd4618e3          	bne	a2,s4,800036b8 <balloc+0x80>
    800036ec:	b759                	j	80003672 <balloc+0x3a>
  panic("balloc: out of blocks");
    800036ee:	00005517          	auipc	a0,0x5
    800036f2:	eea50513          	addi	a0,a0,-278 # 800085d8 <syscalls+0x108>
    800036f6:	ffffd097          	auipc	ra,0xffffd
    800036fa:	e5a080e7          	jalr	-422(ra) # 80000550 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800036fe:	974a                	add	a4,a4,s2
    80003700:	8fd5                	or	a5,a5,a3
    80003702:	06f70023          	sb	a5,96(a4)
        log_write(bp);
    80003706:	854a                	mv	a0,s2
    80003708:	00001097          	auipc	ra,0x1
    8000370c:	018080e7          	jalr	24(ra) # 80004720 <log_write>
        brelse(bp);
    80003710:	854a                	mv	a0,s2
    80003712:	00000097          	auipc	ra,0x0
    80003716:	d7c080e7          	jalr	-644(ra) # 8000348e <brelse>
  bp = bread(dev, bno);
    8000371a:	85a6                	mv	a1,s1
    8000371c:	855e                	mv	a0,s7
    8000371e:	00000097          	auipc	ra,0x0
    80003722:	af2080e7          	jalr	-1294(ra) # 80003210 <bread>
    80003726:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003728:	40000613          	li	a2,1024
    8000372c:	4581                	li	a1,0
    8000372e:	06050513          	addi	a0,a0,96
    80003732:	ffffe097          	auipc	ra,0xffffe
    80003736:	a1a080e7          	jalr	-1510(ra) # 8000114c <memset>
  log_write(bp);
    8000373a:	854a                	mv	a0,s2
    8000373c:	00001097          	auipc	ra,0x1
    80003740:	fe4080e7          	jalr	-28(ra) # 80004720 <log_write>
  brelse(bp);
    80003744:	854a                	mv	a0,s2
    80003746:	00000097          	auipc	ra,0x0
    8000374a:	d48080e7          	jalr	-696(ra) # 8000348e <brelse>
}
    8000374e:	8526                	mv	a0,s1
    80003750:	60e6                	ld	ra,88(sp)
    80003752:	6446                	ld	s0,80(sp)
    80003754:	64a6                	ld	s1,72(sp)
    80003756:	6906                	ld	s2,64(sp)
    80003758:	79e2                	ld	s3,56(sp)
    8000375a:	7a42                	ld	s4,48(sp)
    8000375c:	7aa2                	ld	s5,40(sp)
    8000375e:	7b02                	ld	s6,32(sp)
    80003760:	6be2                	ld	s7,24(sp)
    80003762:	6c42                	ld	s8,16(sp)
    80003764:	6ca2                	ld	s9,8(sp)
    80003766:	6125                	addi	sp,sp,96
    80003768:	8082                	ret

000000008000376a <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000376a:	7179                	addi	sp,sp,-48
    8000376c:	f406                	sd	ra,40(sp)
    8000376e:	f022                	sd	s0,32(sp)
    80003770:	ec26                	sd	s1,24(sp)
    80003772:	e84a                	sd	s2,16(sp)
    80003774:	e44e                	sd	s3,8(sp)
    80003776:	e052                	sd	s4,0(sp)
    80003778:	1800                	addi	s0,sp,48
    8000377a:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000377c:	47ad                	li	a5,11
    8000377e:	04b7fe63          	bgeu	a5,a1,800037da <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003782:	ff45849b          	addiw	s1,a1,-12
    80003786:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000378a:	0ff00793          	li	a5,255
    8000378e:	0ae7e363          	bltu	a5,a4,80003834 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003792:	08852583          	lw	a1,136(a0)
    80003796:	c5ad                	beqz	a1,80003800 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003798:	00092503          	lw	a0,0(s2)
    8000379c:	00000097          	auipc	ra,0x0
    800037a0:	a74080e7          	jalr	-1420(ra) # 80003210 <bread>
    800037a4:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800037a6:	06050793          	addi	a5,a0,96
    if((addr = a[bn]) == 0){
    800037aa:	02049593          	slli	a1,s1,0x20
    800037ae:	9181                	srli	a1,a1,0x20
    800037b0:	058a                	slli	a1,a1,0x2
    800037b2:	00b784b3          	add	s1,a5,a1
    800037b6:	0004a983          	lw	s3,0(s1)
    800037ba:	04098d63          	beqz	s3,80003814 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800037be:	8552                	mv	a0,s4
    800037c0:	00000097          	auipc	ra,0x0
    800037c4:	cce080e7          	jalr	-818(ra) # 8000348e <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800037c8:	854e                	mv	a0,s3
    800037ca:	70a2                	ld	ra,40(sp)
    800037cc:	7402                	ld	s0,32(sp)
    800037ce:	64e2                	ld	s1,24(sp)
    800037d0:	6942                	ld	s2,16(sp)
    800037d2:	69a2                	ld	s3,8(sp)
    800037d4:	6a02                	ld	s4,0(sp)
    800037d6:	6145                	addi	sp,sp,48
    800037d8:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800037da:	02059493          	slli	s1,a1,0x20
    800037de:	9081                	srli	s1,s1,0x20
    800037e0:	048a                	slli	s1,s1,0x2
    800037e2:	94aa                	add	s1,s1,a0
    800037e4:	0584a983          	lw	s3,88(s1)
    800037e8:	fe0990e3          	bnez	s3,800037c8 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800037ec:	4108                	lw	a0,0(a0)
    800037ee:	00000097          	auipc	ra,0x0
    800037f2:	e4a080e7          	jalr	-438(ra) # 80003638 <balloc>
    800037f6:	0005099b          	sext.w	s3,a0
    800037fa:	0534ac23          	sw	s3,88(s1)
    800037fe:	b7e9                	j	800037c8 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003800:	4108                	lw	a0,0(a0)
    80003802:	00000097          	auipc	ra,0x0
    80003806:	e36080e7          	jalr	-458(ra) # 80003638 <balloc>
    8000380a:	0005059b          	sext.w	a1,a0
    8000380e:	08b92423          	sw	a1,136(s2)
    80003812:	b759                	j	80003798 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003814:	00092503          	lw	a0,0(s2)
    80003818:	00000097          	auipc	ra,0x0
    8000381c:	e20080e7          	jalr	-480(ra) # 80003638 <balloc>
    80003820:	0005099b          	sext.w	s3,a0
    80003824:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003828:	8552                	mv	a0,s4
    8000382a:	00001097          	auipc	ra,0x1
    8000382e:	ef6080e7          	jalr	-266(ra) # 80004720 <log_write>
    80003832:	b771                	j	800037be <bmap+0x54>
  panic("bmap: out of range");
    80003834:	00005517          	auipc	a0,0x5
    80003838:	dbc50513          	addi	a0,a0,-580 # 800085f0 <syscalls+0x120>
    8000383c:	ffffd097          	auipc	ra,0xffffd
    80003840:	d14080e7          	jalr	-748(ra) # 80000550 <panic>

0000000080003844 <iget>:
{
    80003844:	7179                	addi	sp,sp,-48
    80003846:	f406                	sd	ra,40(sp)
    80003848:	f022                	sd	s0,32(sp)
    8000384a:	ec26                	sd	s1,24(sp)
    8000384c:	e84a                	sd	s2,16(sp)
    8000384e:	e44e                	sd	s3,8(sp)
    80003850:	e052                	sd	s4,0(sp)
    80003852:	1800                	addi	s0,sp,48
    80003854:	89aa                	mv	s3,a0
    80003856:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    80003858:	00021517          	auipc	a0,0x21
    8000385c:	ac850513          	addi	a0,a0,-1336 # 80024320 <icache>
    80003860:	ffffd097          	auipc	ra,0xffffd
    80003864:	50c080e7          	jalr	1292(ra) # 80000d6c <acquire>
  empty = 0;
    80003868:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    8000386a:	00021497          	auipc	s1,0x21
    8000386e:	ad648493          	addi	s1,s1,-1322 # 80024340 <icache+0x20>
    80003872:	00022697          	auipc	a3,0x22
    80003876:	6ee68693          	addi	a3,a3,1774 # 80025f60 <log>
    8000387a:	a039                	j	80003888 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000387c:	02090b63          	beqz	s2,800038b2 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003880:	09048493          	addi	s1,s1,144
    80003884:	02d48a63          	beq	s1,a3,800038b8 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003888:	449c                	lw	a5,8(s1)
    8000388a:	fef059e3          	blez	a5,8000387c <iget+0x38>
    8000388e:	4098                	lw	a4,0(s1)
    80003890:	ff3716e3          	bne	a4,s3,8000387c <iget+0x38>
    80003894:	40d8                	lw	a4,4(s1)
    80003896:	ff4713e3          	bne	a4,s4,8000387c <iget+0x38>
      ip->ref++;
    8000389a:	2785                	addiw	a5,a5,1
    8000389c:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    8000389e:	00021517          	auipc	a0,0x21
    800038a2:	a8250513          	addi	a0,a0,-1406 # 80024320 <icache>
    800038a6:	ffffd097          	auipc	ra,0xffffd
    800038aa:	596080e7          	jalr	1430(ra) # 80000e3c <release>
      return ip;
    800038ae:	8926                	mv	s2,s1
    800038b0:	a03d                	j	800038de <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800038b2:	f7f9                	bnez	a5,80003880 <iget+0x3c>
    800038b4:	8926                	mv	s2,s1
    800038b6:	b7e9                	j	80003880 <iget+0x3c>
  if(empty == 0)
    800038b8:	02090c63          	beqz	s2,800038f0 <iget+0xac>
  ip->dev = dev;
    800038bc:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800038c0:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800038c4:	4785                	li	a5,1
    800038c6:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800038ca:	04092423          	sw	zero,72(s2)
  release(&icache.lock);
    800038ce:	00021517          	auipc	a0,0x21
    800038d2:	a5250513          	addi	a0,a0,-1454 # 80024320 <icache>
    800038d6:	ffffd097          	auipc	ra,0xffffd
    800038da:	566080e7          	jalr	1382(ra) # 80000e3c <release>
}
    800038de:	854a                	mv	a0,s2
    800038e0:	70a2                	ld	ra,40(sp)
    800038e2:	7402                	ld	s0,32(sp)
    800038e4:	64e2                	ld	s1,24(sp)
    800038e6:	6942                	ld	s2,16(sp)
    800038e8:	69a2                	ld	s3,8(sp)
    800038ea:	6a02                	ld	s4,0(sp)
    800038ec:	6145                	addi	sp,sp,48
    800038ee:	8082                	ret
    panic("iget: no inodes");
    800038f0:	00005517          	auipc	a0,0x5
    800038f4:	d1850513          	addi	a0,a0,-744 # 80008608 <syscalls+0x138>
    800038f8:	ffffd097          	auipc	ra,0xffffd
    800038fc:	c58080e7          	jalr	-936(ra) # 80000550 <panic>

0000000080003900 <fsinit>:
fsinit(int dev) {
    80003900:	7179                	addi	sp,sp,-48
    80003902:	f406                	sd	ra,40(sp)
    80003904:	f022                	sd	s0,32(sp)
    80003906:	ec26                	sd	s1,24(sp)
    80003908:	e84a                	sd	s2,16(sp)
    8000390a:	e44e                	sd	s3,8(sp)
    8000390c:	1800                	addi	s0,sp,48
    8000390e:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003910:	4585                	li	a1,1
    80003912:	00000097          	auipc	ra,0x0
    80003916:	8fe080e7          	jalr	-1794(ra) # 80003210 <bread>
    8000391a:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000391c:	00021997          	auipc	s3,0x21
    80003920:	9e498993          	addi	s3,s3,-1564 # 80024300 <sb>
    80003924:	02000613          	li	a2,32
    80003928:	06050593          	addi	a1,a0,96
    8000392c:	854e                	mv	a0,s3
    8000392e:	ffffe097          	auipc	ra,0xffffe
    80003932:	87e080e7          	jalr	-1922(ra) # 800011ac <memmove>
  brelse(bp);
    80003936:	8526                	mv	a0,s1
    80003938:	00000097          	auipc	ra,0x0
    8000393c:	b56080e7          	jalr	-1194(ra) # 8000348e <brelse>
  if(sb.magic != FSMAGIC)
    80003940:	0009a703          	lw	a4,0(s3)
    80003944:	102037b7          	lui	a5,0x10203
    80003948:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000394c:	02f71263          	bne	a4,a5,80003970 <fsinit+0x70>
  initlog(dev, &sb);
    80003950:	00021597          	auipc	a1,0x21
    80003954:	9b058593          	addi	a1,a1,-1616 # 80024300 <sb>
    80003958:	854a                	mv	a0,s2
    8000395a:	00001097          	auipc	ra,0x1
    8000395e:	b4a080e7          	jalr	-1206(ra) # 800044a4 <initlog>
}
    80003962:	70a2                	ld	ra,40(sp)
    80003964:	7402                	ld	s0,32(sp)
    80003966:	64e2                	ld	s1,24(sp)
    80003968:	6942                	ld	s2,16(sp)
    8000396a:	69a2                	ld	s3,8(sp)
    8000396c:	6145                	addi	sp,sp,48
    8000396e:	8082                	ret
    panic("invalid file system");
    80003970:	00005517          	auipc	a0,0x5
    80003974:	ca850513          	addi	a0,a0,-856 # 80008618 <syscalls+0x148>
    80003978:	ffffd097          	auipc	ra,0xffffd
    8000397c:	bd8080e7          	jalr	-1064(ra) # 80000550 <panic>

0000000080003980 <iinit>:
{
    80003980:	7179                	addi	sp,sp,-48
    80003982:	f406                	sd	ra,40(sp)
    80003984:	f022                	sd	s0,32(sp)
    80003986:	ec26                	sd	s1,24(sp)
    80003988:	e84a                	sd	s2,16(sp)
    8000398a:	e44e                	sd	s3,8(sp)
    8000398c:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    8000398e:	00005597          	auipc	a1,0x5
    80003992:	ca258593          	addi	a1,a1,-862 # 80008630 <syscalls+0x160>
    80003996:	00021517          	auipc	a0,0x21
    8000399a:	98a50513          	addi	a0,a0,-1654 # 80024320 <icache>
    8000399e:	ffffd097          	auipc	ra,0xffffd
    800039a2:	54a080e7          	jalr	1354(ra) # 80000ee8 <initlock>
  for(i = 0; i < NINODE; i++) {
    800039a6:	00021497          	auipc	s1,0x21
    800039aa:	9aa48493          	addi	s1,s1,-1622 # 80024350 <icache+0x30>
    800039ae:	00022997          	auipc	s3,0x22
    800039b2:	5c298993          	addi	s3,s3,1474 # 80025f70 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    800039b6:	00005917          	auipc	s2,0x5
    800039ba:	c8290913          	addi	s2,s2,-894 # 80008638 <syscalls+0x168>
    800039be:	85ca                	mv	a1,s2
    800039c0:	8526                	mv	a0,s1
    800039c2:	00001097          	auipc	ra,0x1
    800039c6:	e4c080e7          	jalr	-436(ra) # 8000480e <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800039ca:	09048493          	addi	s1,s1,144
    800039ce:	ff3498e3          	bne	s1,s3,800039be <iinit+0x3e>
}
    800039d2:	70a2                	ld	ra,40(sp)
    800039d4:	7402                	ld	s0,32(sp)
    800039d6:	64e2                	ld	s1,24(sp)
    800039d8:	6942                	ld	s2,16(sp)
    800039da:	69a2                	ld	s3,8(sp)
    800039dc:	6145                	addi	sp,sp,48
    800039de:	8082                	ret

00000000800039e0 <ialloc>:
{
    800039e0:	715d                	addi	sp,sp,-80
    800039e2:	e486                	sd	ra,72(sp)
    800039e4:	e0a2                	sd	s0,64(sp)
    800039e6:	fc26                	sd	s1,56(sp)
    800039e8:	f84a                	sd	s2,48(sp)
    800039ea:	f44e                	sd	s3,40(sp)
    800039ec:	f052                	sd	s4,32(sp)
    800039ee:	ec56                	sd	s5,24(sp)
    800039f0:	e85a                	sd	s6,16(sp)
    800039f2:	e45e                	sd	s7,8(sp)
    800039f4:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800039f6:	00021717          	auipc	a4,0x21
    800039fa:	91672703          	lw	a4,-1770(a4) # 8002430c <sb+0xc>
    800039fe:	4785                	li	a5,1
    80003a00:	04e7fa63          	bgeu	a5,a4,80003a54 <ialloc+0x74>
    80003a04:	8aaa                	mv	s5,a0
    80003a06:	8bae                	mv	s7,a1
    80003a08:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003a0a:	00021a17          	auipc	s4,0x21
    80003a0e:	8f6a0a13          	addi	s4,s4,-1802 # 80024300 <sb>
    80003a12:	00048b1b          	sext.w	s6,s1
    80003a16:	0044d593          	srli	a1,s1,0x4
    80003a1a:	018a2783          	lw	a5,24(s4)
    80003a1e:	9dbd                	addw	a1,a1,a5
    80003a20:	8556                	mv	a0,s5
    80003a22:	fffff097          	auipc	ra,0xfffff
    80003a26:	7ee080e7          	jalr	2030(ra) # 80003210 <bread>
    80003a2a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003a2c:	06050993          	addi	s3,a0,96
    80003a30:	00f4f793          	andi	a5,s1,15
    80003a34:	079a                	slli	a5,a5,0x6
    80003a36:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003a38:	00099783          	lh	a5,0(s3)
    80003a3c:	c785                	beqz	a5,80003a64 <ialloc+0x84>
    brelse(bp);
    80003a3e:	00000097          	auipc	ra,0x0
    80003a42:	a50080e7          	jalr	-1456(ra) # 8000348e <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a46:	0485                	addi	s1,s1,1
    80003a48:	00ca2703          	lw	a4,12(s4)
    80003a4c:	0004879b          	sext.w	a5,s1
    80003a50:	fce7e1e3          	bltu	a5,a4,80003a12 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003a54:	00005517          	auipc	a0,0x5
    80003a58:	bec50513          	addi	a0,a0,-1044 # 80008640 <syscalls+0x170>
    80003a5c:	ffffd097          	auipc	ra,0xffffd
    80003a60:	af4080e7          	jalr	-1292(ra) # 80000550 <panic>
      memset(dip, 0, sizeof(*dip));
    80003a64:	04000613          	li	a2,64
    80003a68:	4581                	li	a1,0
    80003a6a:	854e                	mv	a0,s3
    80003a6c:	ffffd097          	auipc	ra,0xffffd
    80003a70:	6e0080e7          	jalr	1760(ra) # 8000114c <memset>
      dip->type = type;
    80003a74:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003a78:	854a                	mv	a0,s2
    80003a7a:	00001097          	auipc	ra,0x1
    80003a7e:	ca6080e7          	jalr	-858(ra) # 80004720 <log_write>
      brelse(bp);
    80003a82:	854a                	mv	a0,s2
    80003a84:	00000097          	auipc	ra,0x0
    80003a88:	a0a080e7          	jalr	-1526(ra) # 8000348e <brelse>
      return iget(dev, inum);
    80003a8c:	85da                	mv	a1,s6
    80003a8e:	8556                	mv	a0,s5
    80003a90:	00000097          	auipc	ra,0x0
    80003a94:	db4080e7          	jalr	-588(ra) # 80003844 <iget>
}
    80003a98:	60a6                	ld	ra,72(sp)
    80003a9a:	6406                	ld	s0,64(sp)
    80003a9c:	74e2                	ld	s1,56(sp)
    80003a9e:	7942                	ld	s2,48(sp)
    80003aa0:	79a2                	ld	s3,40(sp)
    80003aa2:	7a02                	ld	s4,32(sp)
    80003aa4:	6ae2                	ld	s5,24(sp)
    80003aa6:	6b42                	ld	s6,16(sp)
    80003aa8:	6ba2                	ld	s7,8(sp)
    80003aaa:	6161                	addi	sp,sp,80
    80003aac:	8082                	ret

0000000080003aae <iupdate>:
{
    80003aae:	1101                	addi	sp,sp,-32
    80003ab0:	ec06                	sd	ra,24(sp)
    80003ab2:	e822                	sd	s0,16(sp)
    80003ab4:	e426                	sd	s1,8(sp)
    80003ab6:	e04a                	sd	s2,0(sp)
    80003ab8:	1000                	addi	s0,sp,32
    80003aba:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003abc:	415c                	lw	a5,4(a0)
    80003abe:	0047d79b          	srliw	a5,a5,0x4
    80003ac2:	00021597          	auipc	a1,0x21
    80003ac6:	8565a583          	lw	a1,-1962(a1) # 80024318 <sb+0x18>
    80003aca:	9dbd                	addw	a1,a1,a5
    80003acc:	4108                	lw	a0,0(a0)
    80003ace:	fffff097          	auipc	ra,0xfffff
    80003ad2:	742080e7          	jalr	1858(ra) # 80003210 <bread>
    80003ad6:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003ad8:	06050793          	addi	a5,a0,96
    80003adc:	40c8                	lw	a0,4(s1)
    80003ade:	893d                	andi	a0,a0,15
    80003ae0:	051a                	slli	a0,a0,0x6
    80003ae2:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003ae4:	04c49703          	lh	a4,76(s1)
    80003ae8:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003aec:	04e49703          	lh	a4,78(s1)
    80003af0:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003af4:	05049703          	lh	a4,80(s1)
    80003af8:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003afc:	05249703          	lh	a4,82(s1)
    80003b00:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003b04:	48f8                	lw	a4,84(s1)
    80003b06:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003b08:	03400613          	li	a2,52
    80003b0c:	05848593          	addi	a1,s1,88
    80003b10:	0531                	addi	a0,a0,12
    80003b12:	ffffd097          	auipc	ra,0xffffd
    80003b16:	69a080e7          	jalr	1690(ra) # 800011ac <memmove>
  log_write(bp);
    80003b1a:	854a                	mv	a0,s2
    80003b1c:	00001097          	auipc	ra,0x1
    80003b20:	c04080e7          	jalr	-1020(ra) # 80004720 <log_write>
  brelse(bp);
    80003b24:	854a                	mv	a0,s2
    80003b26:	00000097          	auipc	ra,0x0
    80003b2a:	968080e7          	jalr	-1688(ra) # 8000348e <brelse>
}
    80003b2e:	60e2                	ld	ra,24(sp)
    80003b30:	6442                	ld	s0,16(sp)
    80003b32:	64a2                	ld	s1,8(sp)
    80003b34:	6902                	ld	s2,0(sp)
    80003b36:	6105                	addi	sp,sp,32
    80003b38:	8082                	ret

0000000080003b3a <idup>:
{
    80003b3a:	1101                	addi	sp,sp,-32
    80003b3c:	ec06                	sd	ra,24(sp)
    80003b3e:	e822                	sd	s0,16(sp)
    80003b40:	e426                	sd	s1,8(sp)
    80003b42:	1000                	addi	s0,sp,32
    80003b44:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003b46:	00020517          	auipc	a0,0x20
    80003b4a:	7da50513          	addi	a0,a0,2010 # 80024320 <icache>
    80003b4e:	ffffd097          	auipc	ra,0xffffd
    80003b52:	21e080e7          	jalr	542(ra) # 80000d6c <acquire>
  ip->ref++;
    80003b56:	449c                	lw	a5,8(s1)
    80003b58:	2785                	addiw	a5,a5,1
    80003b5a:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003b5c:	00020517          	auipc	a0,0x20
    80003b60:	7c450513          	addi	a0,a0,1988 # 80024320 <icache>
    80003b64:	ffffd097          	auipc	ra,0xffffd
    80003b68:	2d8080e7          	jalr	728(ra) # 80000e3c <release>
}
    80003b6c:	8526                	mv	a0,s1
    80003b6e:	60e2                	ld	ra,24(sp)
    80003b70:	6442                	ld	s0,16(sp)
    80003b72:	64a2                	ld	s1,8(sp)
    80003b74:	6105                	addi	sp,sp,32
    80003b76:	8082                	ret

0000000080003b78 <ilock>:
{
    80003b78:	1101                	addi	sp,sp,-32
    80003b7a:	ec06                	sd	ra,24(sp)
    80003b7c:	e822                	sd	s0,16(sp)
    80003b7e:	e426                	sd	s1,8(sp)
    80003b80:	e04a                	sd	s2,0(sp)
    80003b82:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003b84:	c115                	beqz	a0,80003ba8 <ilock+0x30>
    80003b86:	84aa                	mv	s1,a0
    80003b88:	451c                	lw	a5,8(a0)
    80003b8a:	00f05f63          	blez	a5,80003ba8 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003b8e:	0541                	addi	a0,a0,16
    80003b90:	00001097          	auipc	ra,0x1
    80003b94:	cb8080e7          	jalr	-840(ra) # 80004848 <acquiresleep>
  if(ip->valid == 0){
    80003b98:	44bc                	lw	a5,72(s1)
    80003b9a:	cf99                	beqz	a5,80003bb8 <ilock+0x40>
}
    80003b9c:	60e2                	ld	ra,24(sp)
    80003b9e:	6442                	ld	s0,16(sp)
    80003ba0:	64a2                	ld	s1,8(sp)
    80003ba2:	6902                	ld	s2,0(sp)
    80003ba4:	6105                	addi	sp,sp,32
    80003ba6:	8082                	ret
    panic("ilock");
    80003ba8:	00005517          	auipc	a0,0x5
    80003bac:	ab050513          	addi	a0,a0,-1360 # 80008658 <syscalls+0x188>
    80003bb0:	ffffd097          	auipc	ra,0xffffd
    80003bb4:	9a0080e7          	jalr	-1632(ra) # 80000550 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003bb8:	40dc                	lw	a5,4(s1)
    80003bba:	0047d79b          	srliw	a5,a5,0x4
    80003bbe:	00020597          	auipc	a1,0x20
    80003bc2:	75a5a583          	lw	a1,1882(a1) # 80024318 <sb+0x18>
    80003bc6:	9dbd                	addw	a1,a1,a5
    80003bc8:	4088                	lw	a0,0(s1)
    80003bca:	fffff097          	auipc	ra,0xfffff
    80003bce:	646080e7          	jalr	1606(ra) # 80003210 <bread>
    80003bd2:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003bd4:	06050593          	addi	a1,a0,96
    80003bd8:	40dc                	lw	a5,4(s1)
    80003bda:	8bbd                	andi	a5,a5,15
    80003bdc:	079a                	slli	a5,a5,0x6
    80003bde:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003be0:	00059783          	lh	a5,0(a1)
    80003be4:	04f49623          	sh	a5,76(s1)
    ip->major = dip->major;
    80003be8:	00259783          	lh	a5,2(a1)
    80003bec:	04f49723          	sh	a5,78(s1)
    ip->minor = dip->minor;
    80003bf0:	00459783          	lh	a5,4(a1)
    80003bf4:	04f49823          	sh	a5,80(s1)
    ip->nlink = dip->nlink;
    80003bf8:	00659783          	lh	a5,6(a1)
    80003bfc:	04f49923          	sh	a5,82(s1)
    ip->size = dip->size;
    80003c00:	459c                	lw	a5,8(a1)
    80003c02:	c8fc                	sw	a5,84(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003c04:	03400613          	li	a2,52
    80003c08:	05b1                	addi	a1,a1,12
    80003c0a:	05848513          	addi	a0,s1,88
    80003c0e:	ffffd097          	auipc	ra,0xffffd
    80003c12:	59e080e7          	jalr	1438(ra) # 800011ac <memmove>
    brelse(bp);
    80003c16:	854a                	mv	a0,s2
    80003c18:	00000097          	auipc	ra,0x0
    80003c1c:	876080e7          	jalr	-1930(ra) # 8000348e <brelse>
    ip->valid = 1;
    80003c20:	4785                	li	a5,1
    80003c22:	c4bc                	sw	a5,72(s1)
    if(ip->type == 0)
    80003c24:	04c49783          	lh	a5,76(s1)
    80003c28:	fbb5                	bnez	a5,80003b9c <ilock+0x24>
      panic("ilock: no type");
    80003c2a:	00005517          	auipc	a0,0x5
    80003c2e:	a3650513          	addi	a0,a0,-1482 # 80008660 <syscalls+0x190>
    80003c32:	ffffd097          	auipc	ra,0xffffd
    80003c36:	91e080e7          	jalr	-1762(ra) # 80000550 <panic>

0000000080003c3a <iunlock>:
{
    80003c3a:	1101                	addi	sp,sp,-32
    80003c3c:	ec06                	sd	ra,24(sp)
    80003c3e:	e822                	sd	s0,16(sp)
    80003c40:	e426                	sd	s1,8(sp)
    80003c42:	e04a                	sd	s2,0(sp)
    80003c44:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003c46:	c905                	beqz	a0,80003c76 <iunlock+0x3c>
    80003c48:	84aa                	mv	s1,a0
    80003c4a:	01050913          	addi	s2,a0,16
    80003c4e:	854a                	mv	a0,s2
    80003c50:	00001097          	auipc	ra,0x1
    80003c54:	c92080e7          	jalr	-878(ra) # 800048e2 <holdingsleep>
    80003c58:	cd19                	beqz	a0,80003c76 <iunlock+0x3c>
    80003c5a:	449c                	lw	a5,8(s1)
    80003c5c:	00f05d63          	blez	a5,80003c76 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003c60:	854a                	mv	a0,s2
    80003c62:	00001097          	auipc	ra,0x1
    80003c66:	c3c080e7          	jalr	-964(ra) # 8000489e <releasesleep>
}
    80003c6a:	60e2                	ld	ra,24(sp)
    80003c6c:	6442                	ld	s0,16(sp)
    80003c6e:	64a2                	ld	s1,8(sp)
    80003c70:	6902                	ld	s2,0(sp)
    80003c72:	6105                	addi	sp,sp,32
    80003c74:	8082                	ret
    panic("iunlock");
    80003c76:	00005517          	auipc	a0,0x5
    80003c7a:	9fa50513          	addi	a0,a0,-1542 # 80008670 <syscalls+0x1a0>
    80003c7e:	ffffd097          	auipc	ra,0xffffd
    80003c82:	8d2080e7          	jalr	-1838(ra) # 80000550 <panic>

0000000080003c86 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003c86:	7179                	addi	sp,sp,-48
    80003c88:	f406                	sd	ra,40(sp)
    80003c8a:	f022                	sd	s0,32(sp)
    80003c8c:	ec26                	sd	s1,24(sp)
    80003c8e:	e84a                	sd	s2,16(sp)
    80003c90:	e44e                	sd	s3,8(sp)
    80003c92:	e052                	sd	s4,0(sp)
    80003c94:	1800                	addi	s0,sp,48
    80003c96:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003c98:	05850493          	addi	s1,a0,88
    80003c9c:	08850913          	addi	s2,a0,136
    80003ca0:	a021                	j	80003ca8 <itrunc+0x22>
    80003ca2:	0491                	addi	s1,s1,4
    80003ca4:	01248d63          	beq	s1,s2,80003cbe <itrunc+0x38>
    if(ip->addrs[i]){
    80003ca8:	408c                	lw	a1,0(s1)
    80003caa:	dde5                	beqz	a1,80003ca2 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003cac:	0009a503          	lw	a0,0(s3)
    80003cb0:	00000097          	auipc	ra,0x0
    80003cb4:	90c080e7          	jalr	-1780(ra) # 800035bc <bfree>
      ip->addrs[i] = 0;
    80003cb8:	0004a023          	sw	zero,0(s1)
    80003cbc:	b7dd                	j	80003ca2 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003cbe:	0889a583          	lw	a1,136(s3)
    80003cc2:	e185                	bnez	a1,80003ce2 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003cc4:	0409aa23          	sw	zero,84(s3)
  iupdate(ip);
    80003cc8:	854e                	mv	a0,s3
    80003cca:	00000097          	auipc	ra,0x0
    80003cce:	de4080e7          	jalr	-540(ra) # 80003aae <iupdate>
}
    80003cd2:	70a2                	ld	ra,40(sp)
    80003cd4:	7402                	ld	s0,32(sp)
    80003cd6:	64e2                	ld	s1,24(sp)
    80003cd8:	6942                	ld	s2,16(sp)
    80003cda:	69a2                	ld	s3,8(sp)
    80003cdc:	6a02                	ld	s4,0(sp)
    80003cde:	6145                	addi	sp,sp,48
    80003ce0:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003ce2:	0009a503          	lw	a0,0(s3)
    80003ce6:	fffff097          	auipc	ra,0xfffff
    80003cea:	52a080e7          	jalr	1322(ra) # 80003210 <bread>
    80003cee:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003cf0:	06050493          	addi	s1,a0,96
    80003cf4:	46050913          	addi	s2,a0,1120
    80003cf8:	a811                	j	80003d0c <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003cfa:	0009a503          	lw	a0,0(s3)
    80003cfe:	00000097          	auipc	ra,0x0
    80003d02:	8be080e7          	jalr	-1858(ra) # 800035bc <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003d06:	0491                	addi	s1,s1,4
    80003d08:	01248563          	beq	s1,s2,80003d12 <itrunc+0x8c>
      if(a[j])
    80003d0c:	408c                	lw	a1,0(s1)
    80003d0e:	dde5                	beqz	a1,80003d06 <itrunc+0x80>
    80003d10:	b7ed                	j	80003cfa <itrunc+0x74>
    brelse(bp);
    80003d12:	8552                	mv	a0,s4
    80003d14:	fffff097          	auipc	ra,0xfffff
    80003d18:	77a080e7          	jalr	1914(ra) # 8000348e <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003d1c:	0889a583          	lw	a1,136(s3)
    80003d20:	0009a503          	lw	a0,0(s3)
    80003d24:	00000097          	auipc	ra,0x0
    80003d28:	898080e7          	jalr	-1896(ra) # 800035bc <bfree>
    ip->addrs[NDIRECT] = 0;
    80003d2c:	0809a423          	sw	zero,136(s3)
    80003d30:	bf51                	j	80003cc4 <itrunc+0x3e>

0000000080003d32 <iput>:
{
    80003d32:	1101                	addi	sp,sp,-32
    80003d34:	ec06                	sd	ra,24(sp)
    80003d36:	e822                	sd	s0,16(sp)
    80003d38:	e426                	sd	s1,8(sp)
    80003d3a:	e04a                	sd	s2,0(sp)
    80003d3c:	1000                	addi	s0,sp,32
    80003d3e:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003d40:	00020517          	auipc	a0,0x20
    80003d44:	5e050513          	addi	a0,a0,1504 # 80024320 <icache>
    80003d48:	ffffd097          	auipc	ra,0xffffd
    80003d4c:	024080e7          	jalr	36(ra) # 80000d6c <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d50:	4498                	lw	a4,8(s1)
    80003d52:	4785                	li	a5,1
    80003d54:	02f70363          	beq	a4,a5,80003d7a <iput+0x48>
  ip->ref--;
    80003d58:	449c                	lw	a5,8(s1)
    80003d5a:	37fd                	addiw	a5,a5,-1
    80003d5c:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003d5e:	00020517          	auipc	a0,0x20
    80003d62:	5c250513          	addi	a0,a0,1474 # 80024320 <icache>
    80003d66:	ffffd097          	auipc	ra,0xffffd
    80003d6a:	0d6080e7          	jalr	214(ra) # 80000e3c <release>
}
    80003d6e:	60e2                	ld	ra,24(sp)
    80003d70:	6442                	ld	s0,16(sp)
    80003d72:	64a2                	ld	s1,8(sp)
    80003d74:	6902                	ld	s2,0(sp)
    80003d76:	6105                	addi	sp,sp,32
    80003d78:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d7a:	44bc                	lw	a5,72(s1)
    80003d7c:	dff1                	beqz	a5,80003d58 <iput+0x26>
    80003d7e:	05249783          	lh	a5,82(s1)
    80003d82:	fbf9                	bnez	a5,80003d58 <iput+0x26>
    acquiresleep(&ip->lock);
    80003d84:	01048913          	addi	s2,s1,16
    80003d88:	854a                	mv	a0,s2
    80003d8a:	00001097          	auipc	ra,0x1
    80003d8e:	abe080e7          	jalr	-1346(ra) # 80004848 <acquiresleep>
    release(&icache.lock);
    80003d92:	00020517          	auipc	a0,0x20
    80003d96:	58e50513          	addi	a0,a0,1422 # 80024320 <icache>
    80003d9a:	ffffd097          	auipc	ra,0xffffd
    80003d9e:	0a2080e7          	jalr	162(ra) # 80000e3c <release>
    itrunc(ip);
    80003da2:	8526                	mv	a0,s1
    80003da4:	00000097          	auipc	ra,0x0
    80003da8:	ee2080e7          	jalr	-286(ra) # 80003c86 <itrunc>
    ip->type = 0;
    80003dac:	04049623          	sh	zero,76(s1)
    iupdate(ip);
    80003db0:	8526                	mv	a0,s1
    80003db2:	00000097          	auipc	ra,0x0
    80003db6:	cfc080e7          	jalr	-772(ra) # 80003aae <iupdate>
    ip->valid = 0;
    80003dba:	0404a423          	sw	zero,72(s1)
    releasesleep(&ip->lock);
    80003dbe:	854a                	mv	a0,s2
    80003dc0:	00001097          	auipc	ra,0x1
    80003dc4:	ade080e7          	jalr	-1314(ra) # 8000489e <releasesleep>
    acquire(&icache.lock);
    80003dc8:	00020517          	auipc	a0,0x20
    80003dcc:	55850513          	addi	a0,a0,1368 # 80024320 <icache>
    80003dd0:	ffffd097          	auipc	ra,0xffffd
    80003dd4:	f9c080e7          	jalr	-100(ra) # 80000d6c <acquire>
    80003dd8:	b741                	j	80003d58 <iput+0x26>

0000000080003dda <iunlockput>:
{
    80003dda:	1101                	addi	sp,sp,-32
    80003ddc:	ec06                	sd	ra,24(sp)
    80003dde:	e822                	sd	s0,16(sp)
    80003de0:	e426                	sd	s1,8(sp)
    80003de2:	1000                	addi	s0,sp,32
    80003de4:	84aa                	mv	s1,a0
  iunlock(ip);
    80003de6:	00000097          	auipc	ra,0x0
    80003dea:	e54080e7          	jalr	-428(ra) # 80003c3a <iunlock>
  iput(ip);
    80003dee:	8526                	mv	a0,s1
    80003df0:	00000097          	auipc	ra,0x0
    80003df4:	f42080e7          	jalr	-190(ra) # 80003d32 <iput>
}
    80003df8:	60e2                	ld	ra,24(sp)
    80003dfa:	6442                	ld	s0,16(sp)
    80003dfc:	64a2                	ld	s1,8(sp)
    80003dfe:	6105                	addi	sp,sp,32
    80003e00:	8082                	ret

0000000080003e02 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003e02:	1141                	addi	sp,sp,-16
    80003e04:	e422                	sd	s0,8(sp)
    80003e06:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003e08:	411c                	lw	a5,0(a0)
    80003e0a:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003e0c:	415c                	lw	a5,4(a0)
    80003e0e:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003e10:	04c51783          	lh	a5,76(a0)
    80003e14:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003e18:	05251783          	lh	a5,82(a0)
    80003e1c:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003e20:	05456783          	lwu	a5,84(a0)
    80003e24:	e99c                	sd	a5,16(a1)
}
    80003e26:	6422                	ld	s0,8(sp)
    80003e28:	0141                	addi	sp,sp,16
    80003e2a:	8082                	ret

0000000080003e2c <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003e2c:	497c                	lw	a5,84(a0)
    80003e2e:	0ed7e963          	bltu	a5,a3,80003f20 <readi+0xf4>
{
    80003e32:	7159                	addi	sp,sp,-112
    80003e34:	f486                	sd	ra,104(sp)
    80003e36:	f0a2                	sd	s0,96(sp)
    80003e38:	eca6                	sd	s1,88(sp)
    80003e3a:	e8ca                	sd	s2,80(sp)
    80003e3c:	e4ce                	sd	s3,72(sp)
    80003e3e:	e0d2                	sd	s4,64(sp)
    80003e40:	fc56                	sd	s5,56(sp)
    80003e42:	f85a                	sd	s6,48(sp)
    80003e44:	f45e                	sd	s7,40(sp)
    80003e46:	f062                	sd	s8,32(sp)
    80003e48:	ec66                	sd	s9,24(sp)
    80003e4a:	e86a                	sd	s10,16(sp)
    80003e4c:	e46e                	sd	s11,8(sp)
    80003e4e:	1880                	addi	s0,sp,112
    80003e50:	8baa                	mv	s7,a0
    80003e52:	8c2e                	mv	s8,a1
    80003e54:	8ab2                	mv	s5,a2
    80003e56:	84b6                	mv	s1,a3
    80003e58:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003e5a:	9f35                	addw	a4,a4,a3
    return 0;
    80003e5c:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003e5e:	0ad76063          	bltu	a4,a3,80003efe <readi+0xd2>
  if(off + n > ip->size)
    80003e62:	00e7f463          	bgeu	a5,a4,80003e6a <readi+0x3e>
    n = ip->size - off;
    80003e66:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e6a:	0a0b0963          	beqz	s6,80003f1c <readi+0xf0>
    80003e6e:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e70:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003e74:	5cfd                	li	s9,-1
    80003e76:	a82d                	j	80003eb0 <readi+0x84>
    80003e78:	020a1d93          	slli	s11,s4,0x20
    80003e7c:	020ddd93          	srli	s11,s11,0x20
    80003e80:	06090613          	addi	a2,s2,96
    80003e84:	86ee                	mv	a3,s11
    80003e86:	963a                	add	a2,a2,a4
    80003e88:	85d6                	mv	a1,s5
    80003e8a:	8562                	mv	a0,s8
    80003e8c:	fffff097          	auipc	ra,0xfffff
    80003e90:	99a080e7          	jalr	-1638(ra) # 80002826 <either_copyout>
    80003e94:	05950d63          	beq	a0,s9,80003eee <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003e98:	854a                	mv	a0,s2
    80003e9a:	fffff097          	auipc	ra,0xfffff
    80003e9e:	5f4080e7          	jalr	1524(ra) # 8000348e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ea2:	013a09bb          	addw	s3,s4,s3
    80003ea6:	009a04bb          	addw	s1,s4,s1
    80003eaa:	9aee                	add	s5,s5,s11
    80003eac:	0569f763          	bgeu	s3,s6,80003efa <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003eb0:	000ba903          	lw	s2,0(s7)
    80003eb4:	00a4d59b          	srliw	a1,s1,0xa
    80003eb8:	855e                	mv	a0,s7
    80003eba:	00000097          	auipc	ra,0x0
    80003ebe:	8b0080e7          	jalr	-1872(ra) # 8000376a <bmap>
    80003ec2:	0005059b          	sext.w	a1,a0
    80003ec6:	854a                	mv	a0,s2
    80003ec8:	fffff097          	auipc	ra,0xfffff
    80003ecc:	348080e7          	jalr	840(ra) # 80003210 <bread>
    80003ed0:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ed2:	3ff4f713          	andi	a4,s1,1023
    80003ed6:	40ed07bb          	subw	a5,s10,a4
    80003eda:	413b06bb          	subw	a3,s6,s3
    80003ede:	8a3e                	mv	s4,a5
    80003ee0:	2781                	sext.w	a5,a5
    80003ee2:	0006861b          	sext.w	a2,a3
    80003ee6:	f8f679e3          	bgeu	a2,a5,80003e78 <readi+0x4c>
    80003eea:	8a36                	mv	s4,a3
    80003eec:	b771                	j	80003e78 <readi+0x4c>
      brelse(bp);
    80003eee:	854a                	mv	a0,s2
    80003ef0:	fffff097          	auipc	ra,0xfffff
    80003ef4:	59e080e7          	jalr	1438(ra) # 8000348e <brelse>
      tot = -1;
    80003ef8:	59fd                	li	s3,-1
  }
  return tot;
    80003efa:	0009851b          	sext.w	a0,s3
}
    80003efe:	70a6                	ld	ra,104(sp)
    80003f00:	7406                	ld	s0,96(sp)
    80003f02:	64e6                	ld	s1,88(sp)
    80003f04:	6946                	ld	s2,80(sp)
    80003f06:	69a6                	ld	s3,72(sp)
    80003f08:	6a06                	ld	s4,64(sp)
    80003f0a:	7ae2                	ld	s5,56(sp)
    80003f0c:	7b42                	ld	s6,48(sp)
    80003f0e:	7ba2                	ld	s7,40(sp)
    80003f10:	7c02                	ld	s8,32(sp)
    80003f12:	6ce2                	ld	s9,24(sp)
    80003f14:	6d42                	ld	s10,16(sp)
    80003f16:	6da2                	ld	s11,8(sp)
    80003f18:	6165                	addi	sp,sp,112
    80003f1a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f1c:	89da                	mv	s3,s6
    80003f1e:	bff1                	j	80003efa <readi+0xce>
    return 0;
    80003f20:	4501                	li	a0,0
}
    80003f22:	8082                	ret

0000000080003f24 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f24:	497c                	lw	a5,84(a0)
    80003f26:	10d7e763          	bltu	a5,a3,80004034 <writei+0x110>
{
    80003f2a:	7159                	addi	sp,sp,-112
    80003f2c:	f486                	sd	ra,104(sp)
    80003f2e:	f0a2                	sd	s0,96(sp)
    80003f30:	eca6                	sd	s1,88(sp)
    80003f32:	e8ca                	sd	s2,80(sp)
    80003f34:	e4ce                	sd	s3,72(sp)
    80003f36:	e0d2                	sd	s4,64(sp)
    80003f38:	fc56                	sd	s5,56(sp)
    80003f3a:	f85a                	sd	s6,48(sp)
    80003f3c:	f45e                	sd	s7,40(sp)
    80003f3e:	f062                	sd	s8,32(sp)
    80003f40:	ec66                	sd	s9,24(sp)
    80003f42:	e86a                	sd	s10,16(sp)
    80003f44:	e46e                	sd	s11,8(sp)
    80003f46:	1880                	addi	s0,sp,112
    80003f48:	8baa                	mv	s7,a0
    80003f4a:	8c2e                	mv	s8,a1
    80003f4c:	8ab2                	mv	s5,a2
    80003f4e:	8936                	mv	s2,a3
    80003f50:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003f52:	00e687bb          	addw	a5,a3,a4
    80003f56:	0ed7e163          	bltu	a5,a3,80004038 <writei+0x114>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003f5a:	00043737          	lui	a4,0x43
    80003f5e:	0cf76f63          	bltu	a4,a5,8000403c <writei+0x118>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f62:	0a0b0863          	beqz	s6,80004012 <writei+0xee>
    80003f66:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f68:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003f6c:	5cfd                	li	s9,-1
    80003f6e:	a091                	j	80003fb2 <writei+0x8e>
    80003f70:	02099d93          	slli	s11,s3,0x20
    80003f74:	020ddd93          	srli	s11,s11,0x20
    80003f78:	06048513          	addi	a0,s1,96
    80003f7c:	86ee                	mv	a3,s11
    80003f7e:	8656                	mv	a2,s5
    80003f80:	85e2                	mv	a1,s8
    80003f82:	953a                	add	a0,a0,a4
    80003f84:	fffff097          	auipc	ra,0xfffff
    80003f88:	8f8080e7          	jalr	-1800(ra) # 8000287c <either_copyin>
    80003f8c:	07950263          	beq	a0,s9,80003ff0 <writei+0xcc>
      brelse(bp);
      n = -1;
      break;
    }
    log_write(bp);
    80003f90:	8526                	mv	a0,s1
    80003f92:	00000097          	auipc	ra,0x0
    80003f96:	78e080e7          	jalr	1934(ra) # 80004720 <log_write>
    brelse(bp);
    80003f9a:	8526                	mv	a0,s1
    80003f9c:	fffff097          	auipc	ra,0xfffff
    80003fa0:	4f2080e7          	jalr	1266(ra) # 8000348e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003fa4:	01498a3b          	addw	s4,s3,s4
    80003fa8:	0129893b          	addw	s2,s3,s2
    80003fac:	9aee                	add	s5,s5,s11
    80003fae:	056a7763          	bgeu	s4,s6,80003ffc <writei+0xd8>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003fb2:	000ba483          	lw	s1,0(s7)
    80003fb6:	00a9559b          	srliw	a1,s2,0xa
    80003fba:	855e                	mv	a0,s7
    80003fbc:	fffff097          	auipc	ra,0xfffff
    80003fc0:	7ae080e7          	jalr	1966(ra) # 8000376a <bmap>
    80003fc4:	0005059b          	sext.w	a1,a0
    80003fc8:	8526                	mv	a0,s1
    80003fca:	fffff097          	auipc	ra,0xfffff
    80003fce:	246080e7          	jalr	582(ra) # 80003210 <bread>
    80003fd2:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fd4:	3ff97713          	andi	a4,s2,1023
    80003fd8:	40ed07bb          	subw	a5,s10,a4
    80003fdc:	414b06bb          	subw	a3,s6,s4
    80003fe0:	89be                	mv	s3,a5
    80003fe2:	2781                	sext.w	a5,a5
    80003fe4:	0006861b          	sext.w	a2,a3
    80003fe8:	f8f674e3          	bgeu	a2,a5,80003f70 <writei+0x4c>
    80003fec:	89b6                	mv	s3,a3
    80003fee:	b749                	j	80003f70 <writei+0x4c>
      brelse(bp);
    80003ff0:	8526                	mv	a0,s1
    80003ff2:	fffff097          	auipc	ra,0xfffff
    80003ff6:	49c080e7          	jalr	1180(ra) # 8000348e <brelse>
      n = -1;
    80003ffa:	5b7d                	li	s6,-1
  }

  if(n > 0){
    if(off > ip->size)
    80003ffc:	054ba783          	lw	a5,84(s7)
    80004000:	0127f463          	bgeu	a5,s2,80004008 <writei+0xe4>
      ip->size = off;
    80004004:	052baa23          	sw	s2,84(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80004008:	855e                	mv	a0,s7
    8000400a:	00000097          	auipc	ra,0x0
    8000400e:	aa4080e7          	jalr	-1372(ra) # 80003aae <iupdate>
  }

  return n;
    80004012:	000b051b          	sext.w	a0,s6
}
    80004016:	70a6                	ld	ra,104(sp)
    80004018:	7406                	ld	s0,96(sp)
    8000401a:	64e6                	ld	s1,88(sp)
    8000401c:	6946                	ld	s2,80(sp)
    8000401e:	69a6                	ld	s3,72(sp)
    80004020:	6a06                	ld	s4,64(sp)
    80004022:	7ae2                	ld	s5,56(sp)
    80004024:	7b42                	ld	s6,48(sp)
    80004026:	7ba2                	ld	s7,40(sp)
    80004028:	7c02                	ld	s8,32(sp)
    8000402a:	6ce2                	ld	s9,24(sp)
    8000402c:	6d42                	ld	s10,16(sp)
    8000402e:	6da2                	ld	s11,8(sp)
    80004030:	6165                	addi	sp,sp,112
    80004032:	8082                	ret
    return -1;
    80004034:	557d                	li	a0,-1
}
    80004036:	8082                	ret
    return -1;
    80004038:	557d                	li	a0,-1
    8000403a:	bff1                	j	80004016 <writei+0xf2>
    return -1;
    8000403c:	557d                	li	a0,-1
    8000403e:	bfe1                	j	80004016 <writei+0xf2>

0000000080004040 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004040:	1141                	addi	sp,sp,-16
    80004042:	e406                	sd	ra,8(sp)
    80004044:	e022                	sd	s0,0(sp)
    80004046:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004048:	4639                	li	a2,14
    8000404a:	ffffd097          	auipc	ra,0xffffd
    8000404e:	1de080e7          	jalr	478(ra) # 80001228 <strncmp>
}
    80004052:	60a2                	ld	ra,8(sp)
    80004054:	6402                	ld	s0,0(sp)
    80004056:	0141                	addi	sp,sp,16
    80004058:	8082                	ret

000000008000405a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000405a:	7139                	addi	sp,sp,-64
    8000405c:	fc06                	sd	ra,56(sp)
    8000405e:	f822                	sd	s0,48(sp)
    80004060:	f426                	sd	s1,40(sp)
    80004062:	f04a                	sd	s2,32(sp)
    80004064:	ec4e                	sd	s3,24(sp)
    80004066:	e852                	sd	s4,16(sp)
    80004068:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000406a:	04c51703          	lh	a4,76(a0)
    8000406e:	4785                	li	a5,1
    80004070:	00f71a63          	bne	a4,a5,80004084 <dirlookup+0x2a>
    80004074:	892a                	mv	s2,a0
    80004076:	89ae                	mv	s3,a1
    80004078:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000407a:	497c                	lw	a5,84(a0)
    8000407c:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000407e:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004080:	e79d                	bnez	a5,800040ae <dirlookup+0x54>
    80004082:	a8a5                	j	800040fa <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004084:	00004517          	auipc	a0,0x4
    80004088:	5f450513          	addi	a0,a0,1524 # 80008678 <syscalls+0x1a8>
    8000408c:	ffffc097          	auipc	ra,0xffffc
    80004090:	4c4080e7          	jalr	1220(ra) # 80000550 <panic>
      panic("dirlookup read");
    80004094:	00004517          	auipc	a0,0x4
    80004098:	5fc50513          	addi	a0,a0,1532 # 80008690 <syscalls+0x1c0>
    8000409c:	ffffc097          	auipc	ra,0xffffc
    800040a0:	4b4080e7          	jalr	1204(ra) # 80000550 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040a4:	24c1                	addiw	s1,s1,16
    800040a6:	05492783          	lw	a5,84(s2)
    800040aa:	04f4f763          	bgeu	s1,a5,800040f8 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040ae:	4741                	li	a4,16
    800040b0:	86a6                	mv	a3,s1
    800040b2:	fc040613          	addi	a2,s0,-64
    800040b6:	4581                	li	a1,0
    800040b8:	854a                	mv	a0,s2
    800040ba:	00000097          	auipc	ra,0x0
    800040be:	d72080e7          	jalr	-654(ra) # 80003e2c <readi>
    800040c2:	47c1                	li	a5,16
    800040c4:	fcf518e3          	bne	a0,a5,80004094 <dirlookup+0x3a>
    if(de.inum == 0)
    800040c8:	fc045783          	lhu	a5,-64(s0)
    800040cc:	dfe1                	beqz	a5,800040a4 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800040ce:	fc240593          	addi	a1,s0,-62
    800040d2:	854e                	mv	a0,s3
    800040d4:	00000097          	auipc	ra,0x0
    800040d8:	f6c080e7          	jalr	-148(ra) # 80004040 <namecmp>
    800040dc:	f561                	bnez	a0,800040a4 <dirlookup+0x4a>
      if(poff)
    800040de:	000a0463          	beqz	s4,800040e6 <dirlookup+0x8c>
        *poff = off;
    800040e2:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800040e6:	fc045583          	lhu	a1,-64(s0)
    800040ea:	00092503          	lw	a0,0(s2)
    800040ee:	fffff097          	auipc	ra,0xfffff
    800040f2:	756080e7          	jalr	1878(ra) # 80003844 <iget>
    800040f6:	a011                	j	800040fa <dirlookup+0xa0>
  return 0;
    800040f8:	4501                	li	a0,0
}
    800040fa:	70e2                	ld	ra,56(sp)
    800040fc:	7442                	ld	s0,48(sp)
    800040fe:	74a2                	ld	s1,40(sp)
    80004100:	7902                	ld	s2,32(sp)
    80004102:	69e2                	ld	s3,24(sp)
    80004104:	6a42                	ld	s4,16(sp)
    80004106:	6121                	addi	sp,sp,64
    80004108:	8082                	ret

000000008000410a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000410a:	711d                	addi	sp,sp,-96
    8000410c:	ec86                	sd	ra,88(sp)
    8000410e:	e8a2                	sd	s0,80(sp)
    80004110:	e4a6                	sd	s1,72(sp)
    80004112:	e0ca                	sd	s2,64(sp)
    80004114:	fc4e                	sd	s3,56(sp)
    80004116:	f852                	sd	s4,48(sp)
    80004118:	f456                	sd	s5,40(sp)
    8000411a:	f05a                	sd	s6,32(sp)
    8000411c:	ec5e                	sd	s7,24(sp)
    8000411e:	e862                	sd	s8,16(sp)
    80004120:	e466                	sd	s9,8(sp)
    80004122:	1080                	addi	s0,sp,96
    80004124:	84aa                	mv	s1,a0
    80004126:	8b2e                	mv	s6,a1
    80004128:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000412a:	00054703          	lbu	a4,0(a0)
    8000412e:	02f00793          	li	a5,47
    80004132:	02f70363          	beq	a4,a5,80004158 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004136:	ffffe097          	auipc	ra,0xffffe
    8000413a:	c7e080e7          	jalr	-898(ra) # 80001db4 <myproc>
    8000413e:	15853503          	ld	a0,344(a0)
    80004142:	00000097          	auipc	ra,0x0
    80004146:	9f8080e7          	jalr	-1544(ra) # 80003b3a <idup>
    8000414a:	89aa                	mv	s3,a0
  while(*path == '/')
    8000414c:	02f00913          	li	s2,47
  len = path - s;
    80004150:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80004152:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004154:	4c05                	li	s8,1
    80004156:	a865                	j	8000420e <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004158:	4585                	li	a1,1
    8000415a:	4505                	li	a0,1
    8000415c:	fffff097          	auipc	ra,0xfffff
    80004160:	6e8080e7          	jalr	1768(ra) # 80003844 <iget>
    80004164:	89aa                	mv	s3,a0
    80004166:	b7dd                	j	8000414c <namex+0x42>
      iunlockput(ip);
    80004168:	854e                	mv	a0,s3
    8000416a:	00000097          	auipc	ra,0x0
    8000416e:	c70080e7          	jalr	-912(ra) # 80003dda <iunlockput>
      return 0;
    80004172:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004174:	854e                	mv	a0,s3
    80004176:	60e6                	ld	ra,88(sp)
    80004178:	6446                	ld	s0,80(sp)
    8000417a:	64a6                	ld	s1,72(sp)
    8000417c:	6906                	ld	s2,64(sp)
    8000417e:	79e2                	ld	s3,56(sp)
    80004180:	7a42                	ld	s4,48(sp)
    80004182:	7aa2                	ld	s5,40(sp)
    80004184:	7b02                	ld	s6,32(sp)
    80004186:	6be2                	ld	s7,24(sp)
    80004188:	6c42                	ld	s8,16(sp)
    8000418a:	6ca2                	ld	s9,8(sp)
    8000418c:	6125                	addi	sp,sp,96
    8000418e:	8082                	ret
      iunlock(ip);
    80004190:	854e                	mv	a0,s3
    80004192:	00000097          	auipc	ra,0x0
    80004196:	aa8080e7          	jalr	-1368(ra) # 80003c3a <iunlock>
      return ip;
    8000419a:	bfe9                	j	80004174 <namex+0x6a>
      iunlockput(ip);
    8000419c:	854e                	mv	a0,s3
    8000419e:	00000097          	auipc	ra,0x0
    800041a2:	c3c080e7          	jalr	-964(ra) # 80003dda <iunlockput>
      return 0;
    800041a6:	89d2                	mv	s3,s4
    800041a8:	b7f1                	j	80004174 <namex+0x6a>
  len = path - s;
    800041aa:	40b48633          	sub	a2,s1,a1
    800041ae:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    800041b2:	094cd463          	bge	s9,s4,8000423a <namex+0x130>
    memmove(name, s, DIRSIZ);
    800041b6:	4639                	li	a2,14
    800041b8:	8556                	mv	a0,s5
    800041ba:	ffffd097          	auipc	ra,0xffffd
    800041be:	ff2080e7          	jalr	-14(ra) # 800011ac <memmove>
  while(*path == '/')
    800041c2:	0004c783          	lbu	a5,0(s1)
    800041c6:	01279763          	bne	a5,s2,800041d4 <namex+0xca>
    path++;
    800041ca:	0485                	addi	s1,s1,1
  while(*path == '/')
    800041cc:	0004c783          	lbu	a5,0(s1)
    800041d0:	ff278de3          	beq	a5,s2,800041ca <namex+0xc0>
    ilock(ip);
    800041d4:	854e                	mv	a0,s3
    800041d6:	00000097          	auipc	ra,0x0
    800041da:	9a2080e7          	jalr	-1630(ra) # 80003b78 <ilock>
    if(ip->type != T_DIR){
    800041de:	04c99783          	lh	a5,76(s3)
    800041e2:	f98793e3          	bne	a5,s8,80004168 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800041e6:	000b0563          	beqz	s6,800041f0 <namex+0xe6>
    800041ea:	0004c783          	lbu	a5,0(s1)
    800041ee:	d3cd                	beqz	a5,80004190 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800041f0:	865e                	mv	a2,s7
    800041f2:	85d6                	mv	a1,s5
    800041f4:	854e                	mv	a0,s3
    800041f6:	00000097          	auipc	ra,0x0
    800041fa:	e64080e7          	jalr	-412(ra) # 8000405a <dirlookup>
    800041fe:	8a2a                	mv	s4,a0
    80004200:	dd51                	beqz	a0,8000419c <namex+0x92>
    iunlockput(ip);
    80004202:	854e                	mv	a0,s3
    80004204:	00000097          	auipc	ra,0x0
    80004208:	bd6080e7          	jalr	-1066(ra) # 80003dda <iunlockput>
    ip = next;
    8000420c:	89d2                	mv	s3,s4
  while(*path == '/')
    8000420e:	0004c783          	lbu	a5,0(s1)
    80004212:	05279763          	bne	a5,s2,80004260 <namex+0x156>
    path++;
    80004216:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004218:	0004c783          	lbu	a5,0(s1)
    8000421c:	ff278de3          	beq	a5,s2,80004216 <namex+0x10c>
  if(*path == 0)
    80004220:	c79d                	beqz	a5,8000424e <namex+0x144>
    path++;
    80004222:	85a6                	mv	a1,s1
  len = path - s;
    80004224:	8a5e                	mv	s4,s7
    80004226:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004228:	01278963          	beq	a5,s2,8000423a <namex+0x130>
    8000422c:	dfbd                	beqz	a5,800041aa <namex+0xa0>
    path++;
    8000422e:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004230:	0004c783          	lbu	a5,0(s1)
    80004234:	ff279ce3          	bne	a5,s2,8000422c <namex+0x122>
    80004238:	bf8d                	j	800041aa <namex+0xa0>
    memmove(name, s, len);
    8000423a:	2601                	sext.w	a2,a2
    8000423c:	8556                	mv	a0,s5
    8000423e:	ffffd097          	auipc	ra,0xffffd
    80004242:	f6e080e7          	jalr	-146(ra) # 800011ac <memmove>
    name[len] = 0;
    80004246:	9a56                	add	s4,s4,s5
    80004248:	000a0023          	sb	zero,0(s4)
    8000424c:	bf9d                	j	800041c2 <namex+0xb8>
  if(nameiparent){
    8000424e:	f20b03e3          	beqz	s6,80004174 <namex+0x6a>
    iput(ip);
    80004252:	854e                	mv	a0,s3
    80004254:	00000097          	auipc	ra,0x0
    80004258:	ade080e7          	jalr	-1314(ra) # 80003d32 <iput>
    return 0;
    8000425c:	4981                	li	s3,0
    8000425e:	bf19                	j	80004174 <namex+0x6a>
  if(*path == 0)
    80004260:	d7fd                	beqz	a5,8000424e <namex+0x144>
  while(*path != '/' && *path != 0)
    80004262:	0004c783          	lbu	a5,0(s1)
    80004266:	85a6                	mv	a1,s1
    80004268:	b7d1                	j	8000422c <namex+0x122>

000000008000426a <dirlink>:
{
    8000426a:	7139                	addi	sp,sp,-64
    8000426c:	fc06                	sd	ra,56(sp)
    8000426e:	f822                	sd	s0,48(sp)
    80004270:	f426                	sd	s1,40(sp)
    80004272:	f04a                	sd	s2,32(sp)
    80004274:	ec4e                	sd	s3,24(sp)
    80004276:	e852                	sd	s4,16(sp)
    80004278:	0080                	addi	s0,sp,64
    8000427a:	892a                	mv	s2,a0
    8000427c:	8a2e                	mv	s4,a1
    8000427e:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004280:	4601                	li	a2,0
    80004282:	00000097          	auipc	ra,0x0
    80004286:	dd8080e7          	jalr	-552(ra) # 8000405a <dirlookup>
    8000428a:	e93d                	bnez	a0,80004300 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000428c:	05492483          	lw	s1,84(s2)
    80004290:	c49d                	beqz	s1,800042be <dirlink+0x54>
    80004292:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004294:	4741                	li	a4,16
    80004296:	86a6                	mv	a3,s1
    80004298:	fc040613          	addi	a2,s0,-64
    8000429c:	4581                	li	a1,0
    8000429e:	854a                	mv	a0,s2
    800042a0:	00000097          	auipc	ra,0x0
    800042a4:	b8c080e7          	jalr	-1140(ra) # 80003e2c <readi>
    800042a8:	47c1                	li	a5,16
    800042aa:	06f51163          	bne	a0,a5,8000430c <dirlink+0xa2>
    if(de.inum == 0)
    800042ae:	fc045783          	lhu	a5,-64(s0)
    800042b2:	c791                	beqz	a5,800042be <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042b4:	24c1                	addiw	s1,s1,16
    800042b6:	05492783          	lw	a5,84(s2)
    800042ba:	fcf4ede3          	bltu	s1,a5,80004294 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800042be:	4639                	li	a2,14
    800042c0:	85d2                	mv	a1,s4
    800042c2:	fc240513          	addi	a0,s0,-62
    800042c6:	ffffd097          	auipc	ra,0xffffd
    800042ca:	f9e080e7          	jalr	-98(ra) # 80001264 <strncpy>
  de.inum = inum;
    800042ce:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042d2:	4741                	li	a4,16
    800042d4:	86a6                	mv	a3,s1
    800042d6:	fc040613          	addi	a2,s0,-64
    800042da:	4581                	li	a1,0
    800042dc:	854a                	mv	a0,s2
    800042de:	00000097          	auipc	ra,0x0
    800042e2:	c46080e7          	jalr	-954(ra) # 80003f24 <writei>
    800042e6:	872a                	mv	a4,a0
    800042e8:	47c1                	li	a5,16
  return 0;
    800042ea:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042ec:	02f71863          	bne	a4,a5,8000431c <dirlink+0xb2>
}
    800042f0:	70e2                	ld	ra,56(sp)
    800042f2:	7442                	ld	s0,48(sp)
    800042f4:	74a2                	ld	s1,40(sp)
    800042f6:	7902                	ld	s2,32(sp)
    800042f8:	69e2                	ld	s3,24(sp)
    800042fa:	6a42                	ld	s4,16(sp)
    800042fc:	6121                	addi	sp,sp,64
    800042fe:	8082                	ret
    iput(ip);
    80004300:	00000097          	auipc	ra,0x0
    80004304:	a32080e7          	jalr	-1486(ra) # 80003d32 <iput>
    return -1;
    80004308:	557d                	li	a0,-1
    8000430a:	b7dd                	j	800042f0 <dirlink+0x86>
      panic("dirlink read");
    8000430c:	00004517          	auipc	a0,0x4
    80004310:	39450513          	addi	a0,a0,916 # 800086a0 <syscalls+0x1d0>
    80004314:	ffffc097          	auipc	ra,0xffffc
    80004318:	23c080e7          	jalr	572(ra) # 80000550 <panic>
    panic("dirlink");
    8000431c:	00004517          	auipc	a0,0x4
    80004320:	4a450513          	addi	a0,a0,1188 # 800087c0 <syscalls+0x2f0>
    80004324:	ffffc097          	auipc	ra,0xffffc
    80004328:	22c080e7          	jalr	556(ra) # 80000550 <panic>

000000008000432c <namei>:

struct inode*
namei(char *path)
{
    8000432c:	1101                	addi	sp,sp,-32
    8000432e:	ec06                	sd	ra,24(sp)
    80004330:	e822                	sd	s0,16(sp)
    80004332:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004334:	fe040613          	addi	a2,s0,-32
    80004338:	4581                	li	a1,0
    8000433a:	00000097          	auipc	ra,0x0
    8000433e:	dd0080e7          	jalr	-560(ra) # 8000410a <namex>
}
    80004342:	60e2                	ld	ra,24(sp)
    80004344:	6442                	ld	s0,16(sp)
    80004346:	6105                	addi	sp,sp,32
    80004348:	8082                	ret

000000008000434a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000434a:	1141                	addi	sp,sp,-16
    8000434c:	e406                	sd	ra,8(sp)
    8000434e:	e022                	sd	s0,0(sp)
    80004350:	0800                	addi	s0,sp,16
    80004352:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004354:	4585                	li	a1,1
    80004356:	00000097          	auipc	ra,0x0
    8000435a:	db4080e7          	jalr	-588(ra) # 8000410a <namex>
}
    8000435e:	60a2                	ld	ra,8(sp)
    80004360:	6402                	ld	s0,0(sp)
    80004362:	0141                	addi	sp,sp,16
    80004364:	8082                	ret

0000000080004366 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004366:	1101                	addi	sp,sp,-32
    80004368:	ec06                	sd	ra,24(sp)
    8000436a:	e822                	sd	s0,16(sp)
    8000436c:	e426                	sd	s1,8(sp)
    8000436e:	e04a                	sd	s2,0(sp)
    80004370:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004372:	00022917          	auipc	s2,0x22
    80004376:	bee90913          	addi	s2,s2,-1042 # 80025f60 <log>
    8000437a:	02092583          	lw	a1,32(s2)
    8000437e:	03092503          	lw	a0,48(s2)
    80004382:	fffff097          	auipc	ra,0xfffff
    80004386:	e8e080e7          	jalr	-370(ra) # 80003210 <bread>
    8000438a:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000438c:	03492683          	lw	a3,52(s2)
    80004390:	d134                	sw	a3,96(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004392:	02d05763          	blez	a3,800043c0 <write_head+0x5a>
    80004396:	00022797          	auipc	a5,0x22
    8000439a:	c0278793          	addi	a5,a5,-1022 # 80025f98 <log+0x38>
    8000439e:	06450713          	addi	a4,a0,100
    800043a2:	36fd                	addiw	a3,a3,-1
    800043a4:	1682                	slli	a3,a3,0x20
    800043a6:	9281                	srli	a3,a3,0x20
    800043a8:	068a                	slli	a3,a3,0x2
    800043aa:	00022617          	auipc	a2,0x22
    800043ae:	bf260613          	addi	a2,a2,-1038 # 80025f9c <log+0x3c>
    800043b2:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800043b4:	4390                	lw	a2,0(a5)
    800043b6:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800043b8:	0791                	addi	a5,a5,4
    800043ba:	0711                	addi	a4,a4,4
    800043bc:	fed79ce3          	bne	a5,a3,800043b4 <write_head+0x4e>
  }
  bwrite(buf);
    800043c0:	8526                	mv	a0,s1
    800043c2:	fffff097          	auipc	ra,0xfffff
    800043c6:	08e080e7          	jalr	142(ra) # 80003450 <bwrite>
  brelse(buf);
    800043ca:	8526                	mv	a0,s1
    800043cc:	fffff097          	auipc	ra,0xfffff
    800043d0:	0c2080e7          	jalr	194(ra) # 8000348e <brelse>
}
    800043d4:	60e2                	ld	ra,24(sp)
    800043d6:	6442                	ld	s0,16(sp)
    800043d8:	64a2                	ld	s1,8(sp)
    800043da:	6902                	ld	s2,0(sp)
    800043dc:	6105                	addi	sp,sp,32
    800043de:	8082                	ret

00000000800043e0 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800043e0:	00022797          	auipc	a5,0x22
    800043e4:	bb47a783          	lw	a5,-1100(a5) # 80025f94 <log+0x34>
    800043e8:	0af05d63          	blez	a5,800044a2 <install_trans+0xc2>
{
    800043ec:	7139                	addi	sp,sp,-64
    800043ee:	fc06                	sd	ra,56(sp)
    800043f0:	f822                	sd	s0,48(sp)
    800043f2:	f426                	sd	s1,40(sp)
    800043f4:	f04a                	sd	s2,32(sp)
    800043f6:	ec4e                	sd	s3,24(sp)
    800043f8:	e852                	sd	s4,16(sp)
    800043fa:	e456                	sd	s5,8(sp)
    800043fc:	e05a                	sd	s6,0(sp)
    800043fe:	0080                	addi	s0,sp,64
    80004400:	8b2a                	mv	s6,a0
    80004402:	00022a97          	auipc	s5,0x22
    80004406:	b96a8a93          	addi	s5,s5,-1130 # 80025f98 <log+0x38>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000440a:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000440c:	00022997          	auipc	s3,0x22
    80004410:	b5498993          	addi	s3,s3,-1196 # 80025f60 <log>
    80004414:	a035                	j	80004440 <install_trans+0x60>
      bunpin(dbuf);
    80004416:	8526                	mv	a0,s1
    80004418:	fffff097          	auipc	ra,0xfffff
    8000441c:	14e080e7          	jalr	334(ra) # 80003566 <bunpin>
    brelse(lbuf);
    80004420:	854a                	mv	a0,s2
    80004422:	fffff097          	auipc	ra,0xfffff
    80004426:	06c080e7          	jalr	108(ra) # 8000348e <brelse>
    brelse(dbuf);
    8000442a:	8526                	mv	a0,s1
    8000442c:	fffff097          	auipc	ra,0xfffff
    80004430:	062080e7          	jalr	98(ra) # 8000348e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004434:	2a05                	addiw	s4,s4,1
    80004436:	0a91                	addi	s5,s5,4
    80004438:	0349a783          	lw	a5,52(s3)
    8000443c:	04fa5963          	bge	s4,a5,8000448e <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004440:	0209a583          	lw	a1,32(s3)
    80004444:	014585bb          	addw	a1,a1,s4
    80004448:	2585                	addiw	a1,a1,1
    8000444a:	0309a503          	lw	a0,48(s3)
    8000444e:	fffff097          	auipc	ra,0xfffff
    80004452:	dc2080e7          	jalr	-574(ra) # 80003210 <bread>
    80004456:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004458:	000aa583          	lw	a1,0(s5)
    8000445c:	0309a503          	lw	a0,48(s3)
    80004460:	fffff097          	auipc	ra,0xfffff
    80004464:	db0080e7          	jalr	-592(ra) # 80003210 <bread>
    80004468:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000446a:	40000613          	li	a2,1024
    8000446e:	06090593          	addi	a1,s2,96
    80004472:	06050513          	addi	a0,a0,96
    80004476:	ffffd097          	auipc	ra,0xffffd
    8000447a:	d36080e7          	jalr	-714(ra) # 800011ac <memmove>
    bwrite(dbuf);  // write dst to disk
    8000447e:	8526                	mv	a0,s1
    80004480:	fffff097          	auipc	ra,0xfffff
    80004484:	fd0080e7          	jalr	-48(ra) # 80003450 <bwrite>
    if(recovering == 0)
    80004488:	f80b1ce3          	bnez	s6,80004420 <install_trans+0x40>
    8000448c:	b769                	j	80004416 <install_trans+0x36>
}
    8000448e:	70e2                	ld	ra,56(sp)
    80004490:	7442                	ld	s0,48(sp)
    80004492:	74a2                	ld	s1,40(sp)
    80004494:	7902                	ld	s2,32(sp)
    80004496:	69e2                	ld	s3,24(sp)
    80004498:	6a42                	ld	s4,16(sp)
    8000449a:	6aa2                	ld	s5,8(sp)
    8000449c:	6b02                	ld	s6,0(sp)
    8000449e:	6121                	addi	sp,sp,64
    800044a0:	8082                	ret
    800044a2:	8082                	ret

00000000800044a4 <initlog>:
{
    800044a4:	7179                	addi	sp,sp,-48
    800044a6:	f406                	sd	ra,40(sp)
    800044a8:	f022                	sd	s0,32(sp)
    800044aa:	ec26                	sd	s1,24(sp)
    800044ac:	e84a                	sd	s2,16(sp)
    800044ae:	e44e                	sd	s3,8(sp)
    800044b0:	1800                	addi	s0,sp,48
    800044b2:	892a                	mv	s2,a0
    800044b4:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800044b6:	00022497          	auipc	s1,0x22
    800044ba:	aaa48493          	addi	s1,s1,-1366 # 80025f60 <log>
    800044be:	00004597          	auipc	a1,0x4
    800044c2:	1f258593          	addi	a1,a1,498 # 800086b0 <syscalls+0x1e0>
    800044c6:	8526                	mv	a0,s1
    800044c8:	ffffd097          	auipc	ra,0xffffd
    800044cc:	a20080e7          	jalr	-1504(ra) # 80000ee8 <initlock>
  log.start = sb->logstart;
    800044d0:	0149a583          	lw	a1,20(s3)
    800044d4:	d08c                	sw	a1,32(s1)
  log.size = sb->nlog;
    800044d6:	0109a783          	lw	a5,16(s3)
    800044da:	d0dc                	sw	a5,36(s1)
  log.dev = dev;
    800044dc:	0324a823          	sw	s2,48(s1)
  struct buf *buf = bread(log.dev, log.start);
    800044e0:	854a                	mv	a0,s2
    800044e2:	fffff097          	auipc	ra,0xfffff
    800044e6:	d2e080e7          	jalr	-722(ra) # 80003210 <bread>
  log.lh.n = lh->n;
    800044ea:	513c                	lw	a5,96(a0)
    800044ec:	d8dc                	sw	a5,52(s1)
  for (i = 0; i < log.lh.n; i++) {
    800044ee:	02f05563          	blez	a5,80004518 <initlog+0x74>
    800044f2:	06450713          	addi	a4,a0,100
    800044f6:	00022697          	auipc	a3,0x22
    800044fa:	aa268693          	addi	a3,a3,-1374 # 80025f98 <log+0x38>
    800044fe:	37fd                	addiw	a5,a5,-1
    80004500:	1782                	slli	a5,a5,0x20
    80004502:	9381                	srli	a5,a5,0x20
    80004504:	078a                	slli	a5,a5,0x2
    80004506:	06850613          	addi	a2,a0,104
    8000450a:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000450c:	4310                	lw	a2,0(a4)
    8000450e:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004510:	0711                	addi	a4,a4,4
    80004512:	0691                	addi	a3,a3,4
    80004514:	fef71ce3          	bne	a4,a5,8000450c <initlog+0x68>
  brelse(buf);
    80004518:	fffff097          	auipc	ra,0xfffff
    8000451c:	f76080e7          	jalr	-138(ra) # 8000348e <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004520:	4505                	li	a0,1
    80004522:	00000097          	auipc	ra,0x0
    80004526:	ebe080e7          	jalr	-322(ra) # 800043e0 <install_trans>
  log.lh.n = 0;
    8000452a:	00022797          	auipc	a5,0x22
    8000452e:	a607a523          	sw	zero,-1430(a5) # 80025f94 <log+0x34>
  write_head(); // clear the log
    80004532:	00000097          	auipc	ra,0x0
    80004536:	e34080e7          	jalr	-460(ra) # 80004366 <write_head>
}
    8000453a:	70a2                	ld	ra,40(sp)
    8000453c:	7402                	ld	s0,32(sp)
    8000453e:	64e2                	ld	s1,24(sp)
    80004540:	6942                	ld	s2,16(sp)
    80004542:	69a2                	ld	s3,8(sp)
    80004544:	6145                	addi	sp,sp,48
    80004546:	8082                	ret

0000000080004548 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004548:	1101                	addi	sp,sp,-32
    8000454a:	ec06                	sd	ra,24(sp)
    8000454c:	e822                	sd	s0,16(sp)
    8000454e:	e426                	sd	s1,8(sp)
    80004550:	e04a                	sd	s2,0(sp)
    80004552:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004554:	00022517          	auipc	a0,0x22
    80004558:	a0c50513          	addi	a0,a0,-1524 # 80025f60 <log>
    8000455c:	ffffd097          	auipc	ra,0xffffd
    80004560:	810080e7          	jalr	-2032(ra) # 80000d6c <acquire>
  while(1){
    if(log.committing){
    80004564:	00022497          	auipc	s1,0x22
    80004568:	9fc48493          	addi	s1,s1,-1540 # 80025f60 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000456c:	4979                	li	s2,30
    8000456e:	a039                	j	8000457c <begin_op+0x34>
      sleep(&log, &log.lock);
    80004570:	85a6                	mv	a1,s1
    80004572:	8526                	mv	a0,s1
    80004574:	ffffe097          	auipc	ra,0xffffe
    80004578:	050080e7          	jalr	80(ra) # 800025c4 <sleep>
    if(log.committing){
    8000457c:	54dc                	lw	a5,44(s1)
    8000457e:	fbed                	bnez	a5,80004570 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004580:	549c                	lw	a5,40(s1)
    80004582:	0017871b          	addiw	a4,a5,1
    80004586:	0007069b          	sext.w	a3,a4
    8000458a:	0027179b          	slliw	a5,a4,0x2
    8000458e:	9fb9                	addw	a5,a5,a4
    80004590:	0017979b          	slliw	a5,a5,0x1
    80004594:	58d8                	lw	a4,52(s1)
    80004596:	9fb9                	addw	a5,a5,a4
    80004598:	00f95963          	bge	s2,a5,800045aa <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000459c:	85a6                	mv	a1,s1
    8000459e:	8526                	mv	a0,s1
    800045a0:	ffffe097          	auipc	ra,0xffffe
    800045a4:	024080e7          	jalr	36(ra) # 800025c4 <sleep>
    800045a8:	bfd1                	j	8000457c <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800045aa:	00022517          	auipc	a0,0x22
    800045ae:	9b650513          	addi	a0,a0,-1610 # 80025f60 <log>
    800045b2:	d514                	sw	a3,40(a0)
      release(&log.lock);
    800045b4:	ffffd097          	auipc	ra,0xffffd
    800045b8:	888080e7          	jalr	-1912(ra) # 80000e3c <release>
      break;
    }
  }
}
    800045bc:	60e2                	ld	ra,24(sp)
    800045be:	6442                	ld	s0,16(sp)
    800045c0:	64a2                	ld	s1,8(sp)
    800045c2:	6902                	ld	s2,0(sp)
    800045c4:	6105                	addi	sp,sp,32
    800045c6:	8082                	ret

00000000800045c8 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800045c8:	7139                	addi	sp,sp,-64
    800045ca:	fc06                	sd	ra,56(sp)
    800045cc:	f822                	sd	s0,48(sp)
    800045ce:	f426                	sd	s1,40(sp)
    800045d0:	f04a                	sd	s2,32(sp)
    800045d2:	ec4e                	sd	s3,24(sp)
    800045d4:	e852                	sd	s4,16(sp)
    800045d6:	e456                	sd	s5,8(sp)
    800045d8:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800045da:	00022497          	auipc	s1,0x22
    800045de:	98648493          	addi	s1,s1,-1658 # 80025f60 <log>
    800045e2:	8526                	mv	a0,s1
    800045e4:	ffffc097          	auipc	ra,0xffffc
    800045e8:	788080e7          	jalr	1928(ra) # 80000d6c <acquire>
  log.outstanding -= 1;
    800045ec:	549c                	lw	a5,40(s1)
    800045ee:	37fd                	addiw	a5,a5,-1
    800045f0:	0007891b          	sext.w	s2,a5
    800045f4:	d49c                	sw	a5,40(s1)
  if(log.committing)
    800045f6:	54dc                	lw	a5,44(s1)
    800045f8:	efb9                	bnez	a5,80004656 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800045fa:	06091663          	bnez	s2,80004666 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800045fe:	00022497          	auipc	s1,0x22
    80004602:	96248493          	addi	s1,s1,-1694 # 80025f60 <log>
    80004606:	4785                	li	a5,1
    80004608:	d4dc                	sw	a5,44(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000460a:	8526                	mv	a0,s1
    8000460c:	ffffd097          	auipc	ra,0xffffd
    80004610:	830080e7          	jalr	-2000(ra) # 80000e3c <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004614:	58dc                	lw	a5,52(s1)
    80004616:	06f04763          	bgtz	a5,80004684 <end_op+0xbc>
    acquire(&log.lock);
    8000461a:	00022497          	auipc	s1,0x22
    8000461e:	94648493          	addi	s1,s1,-1722 # 80025f60 <log>
    80004622:	8526                	mv	a0,s1
    80004624:	ffffc097          	auipc	ra,0xffffc
    80004628:	748080e7          	jalr	1864(ra) # 80000d6c <acquire>
    log.committing = 0;
    8000462c:	0204a623          	sw	zero,44(s1)
    wakeup(&log);
    80004630:	8526                	mv	a0,s1
    80004632:	ffffe097          	auipc	ra,0xffffe
    80004636:	118080e7          	jalr	280(ra) # 8000274a <wakeup>
    release(&log.lock);
    8000463a:	8526                	mv	a0,s1
    8000463c:	ffffd097          	auipc	ra,0xffffd
    80004640:	800080e7          	jalr	-2048(ra) # 80000e3c <release>
}
    80004644:	70e2                	ld	ra,56(sp)
    80004646:	7442                	ld	s0,48(sp)
    80004648:	74a2                	ld	s1,40(sp)
    8000464a:	7902                	ld	s2,32(sp)
    8000464c:	69e2                	ld	s3,24(sp)
    8000464e:	6a42                	ld	s4,16(sp)
    80004650:	6aa2                	ld	s5,8(sp)
    80004652:	6121                	addi	sp,sp,64
    80004654:	8082                	ret
    panic("log.committing");
    80004656:	00004517          	auipc	a0,0x4
    8000465a:	06250513          	addi	a0,a0,98 # 800086b8 <syscalls+0x1e8>
    8000465e:	ffffc097          	auipc	ra,0xffffc
    80004662:	ef2080e7          	jalr	-270(ra) # 80000550 <panic>
    wakeup(&log);
    80004666:	00022497          	auipc	s1,0x22
    8000466a:	8fa48493          	addi	s1,s1,-1798 # 80025f60 <log>
    8000466e:	8526                	mv	a0,s1
    80004670:	ffffe097          	auipc	ra,0xffffe
    80004674:	0da080e7          	jalr	218(ra) # 8000274a <wakeup>
  release(&log.lock);
    80004678:	8526                	mv	a0,s1
    8000467a:	ffffc097          	auipc	ra,0xffffc
    8000467e:	7c2080e7          	jalr	1986(ra) # 80000e3c <release>
  if(do_commit){
    80004682:	b7c9                	j	80004644 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004684:	00022a97          	auipc	s5,0x22
    80004688:	914a8a93          	addi	s5,s5,-1772 # 80025f98 <log+0x38>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000468c:	00022a17          	auipc	s4,0x22
    80004690:	8d4a0a13          	addi	s4,s4,-1836 # 80025f60 <log>
    80004694:	020a2583          	lw	a1,32(s4)
    80004698:	012585bb          	addw	a1,a1,s2
    8000469c:	2585                	addiw	a1,a1,1
    8000469e:	030a2503          	lw	a0,48(s4)
    800046a2:	fffff097          	auipc	ra,0xfffff
    800046a6:	b6e080e7          	jalr	-1170(ra) # 80003210 <bread>
    800046aa:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800046ac:	000aa583          	lw	a1,0(s5)
    800046b0:	030a2503          	lw	a0,48(s4)
    800046b4:	fffff097          	auipc	ra,0xfffff
    800046b8:	b5c080e7          	jalr	-1188(ra) # 80003210 <bread>
    800046bc:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800046be:	40000613          	li	a2,1024
    800046c2:	06050593          	addi	a1,a0,96
    800046c6:	06048513          	addi	a0,s1,96
    800046ca:	ffffd097          	auipc	ra,0xffffd
    800046ce:	ae2080e7          	jalr	-1310(ra) # 800011ac <memmove>
    bwrite(to);  // write the log
    800046d2:	8526                	mv	a0,s1
    800046d4:	fffff097          	auipc	ra,0xfffff
    800046d8:	d7c080e7          	jalr	-644(ra) # 80003450 <bwrite>
    brelse(from);
    800046dc:	854e                	mv	a0,s3
    800046de:	fffff097          	auipc	ra,0xfffff
    800046e2:	db0080e7          	jalr	-592(ra) # 8000348e <brelse>
    brelse(to);
    800046e6:	8526                	mv	a0,s1
    800046e8:	fffff097          	auipc	ra,0xfffff
    800046ec:	da6080e7          	jalr	-602(ra) # 8000348e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800046f0:	2905                	addiw	s2,s2,1
    800046f2:	0a91                	addi	s5,s5,4
    800046f4:	034a2783          	lw	a5,52(s4)
    800046f8:	f8f94ee3          	blt	s2,a5,80004694 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800046fc:	00000097          	auipc	ra,0x0
    80004700:	c6a080e7          	jalr	-918(ra) # 80004366 <write_head>
    install_trans(0); // Now install writes to home locations
    80004704:	4501                	li	a0,0
    80004706:	00000097          	auipc	ra,0x0
    8000470a:	cda080e7          	jalr	-806(ra) # 800043e0 <install_trans>
    log.lh.n = 0;
    8000470e:	00022797          	auipc	a5,0x22
    80004712:	8807a323          	sw	zero,-1914(a5) # 80025f94 <log+0x34>
    write_head();    // Erase the transaction from the log
    80004716:	00000097          	auipc	ra,0x0
    8000471a:	c50080e7          	jalr	-944(ra) # 80004366 <write_head>
    8000471e:	bdf5                	j	8000461a <end_op+0x52>

0000000080004720 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004720:	1101                	addi	sp,sp,-32
    80004722:	ec06                	sd	ra,24(sp)
    80004724:	e822                	sd	s0,16(sp)
    80004726:	e426                	sd	s1,8(sp)
    80004728:	e04a                	sd	s2,0(sp)
    8000472a:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000472c:	00022717          	auipc	a4,0x22
    80004730:	86872703          	lw	a4,-1944(a4) # 80025f94 <log+0x34>
    80004734:	47f5                	li	a5,29
    80004736:	08e7c063          	blt	a5,a4,800047b6 <log_write+0x96>
    8000473a:	84aa                	mv	s1,a0
    8000473c:	00022797          	auipc	a5,0x22
    80004740:	8487a783          	lw	a5,-1976(a5) # 80025f84 <log+0x24>
    80004744:	37fd                	addiw	a5,a5,-1
    80004746:	06f75863          	bge	a4,a5,800047b6 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000474a:	00022797          	auipc	a5,0x22
    8000474e:	83e7a783          	lw	a5,-1986(a5) # 80025f88 <log+0x28>
    80004752:	06f05a63          	blez	a5,800047c6 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004756:	00022917          	auipc	s2,0x22
    8000475a:	80a90913          	addi	s2,s2,-2038 # 80025f60 <log>
    8000475e:	854a                	mv	a0,s2
    80004760:	ffffc097          	auipc	ra,0xffffc
    80004764:	60c080e7          	jalr	1548(ra) # 80000d6c <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004768:	03492603          	lw	a2,52(s2)
    8000476c:	06c05563          	blez	a2,800047d6 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004770:	44cc                	lw	a1,12(s1)
    80004772:	00022717          	auipc	a4,0x22
    80004776:	82670713          	addi	a4,a4,-2010 # 80025f98 <log+0x38>
  for (i = 0; i < log.lh.n; i++) {
    8000477a:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000477c:	4314                	lw	a3,0(a4)
    8000477e:	04b68d63          	beq	a3,a1,800047d8 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    80004782:	2785                	addiw	a5,a5,1
    80004784:	0711                	addi	a4,a4,4
    80004786:	fec79be3          	bne	a5,a2,8000477c <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000478a:	0631                	addi	a2,a2,12
    8000478c:	060a                	slli	a2,a2,0x2
    8000478e:	00021797          	auipc	a5,0x21
    80004792:	7d278793          	addi	a5,a5,2002 # 80025f60 <log>
    80004796:	963e                	add	a2,a2,a5
    80004798:	44dc                	lw	a5,12(s1)
    8000479a:	c61c                	sw	a5,8(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000479c:	8526                	mv	a0,s1
    8000479e:	fffff097          	auipc	ra,0xfffff
    800047a2:	d72080e7          	jalr	-654(ra) # 80003510 <bpin>
    log.lh.n++;
    800047a6:	00021717          	auipc	a4,0x21
    800047aa:	7ba70713          	addi	a4,a4,1978 # 80025f60 <log>
    800047ae:	5b5c                	lw	a5,52(a4)
    800047b0:	2785                	addiw	a5,a5,1
    800047b2:	db5c                	sw	a5,52(a4)
    800047b4:	a83d                	j	800047f2 <log_write+0xd2>
    panic("too big a transaction");
    800047b6:	00004517          	auipc	a0,0x4
    800047ba:	f1250513          	addi	a0,a0,-238 # 800086c8 <syscalls+0x1f8>
    800047be:	ffffc097          	auipc	ra,0xffffc
    800047c2:	d92080e7          	jalr	-622(ra) # 80000550 <panic>
    panic("log_write outside of trans");
    800047c6:	00004517          	auipc	a0,0x4
    800047ca:	f1a50513          	addi	a0,a0,-230 # 800086e0 <syscalls+0x210>
    800047ce:	ffffc097          	auipc	ra,0xffffc
    800047d2:	d82080e7          	jalr	-638(ra) # 80000550 <panic>
  for (i = 0; i < log.lh.n; i++) {
    800047d6:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    800047d8:	00c78713          	addi	a4,a5,12
    800047dc:	00271693          	slli	a3,a4,0x2
    800047e0:	00021717          	auipc	a4,0x21
    800047e4:	78070713          	addi	a4,a4,1920 # 80025f60 <log>
    800047e8:	9736                	add	a4,a4,a3
    800047ea:	44d4                	lw	a3,12(s1)
    800047ec:	c714                	sw	a3,8(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800047ee:	faf607e3          	beq	a2,a5,8000479c <log_write+0x7c>
  }
  release(&log.lock);
    800047f2:	00021517          	auipc	a0,0x21
    800047f6:	76e50513          	addi	a0,a0,1902 # 80025f60 <log>
    800047fa:	ffffc097          	auipc	ra,0xffffc
    800047fe:	642080e7          	jalr	1602(ra) # 80000e3c <release>
}
    80004802:	60e2                	ld	ra,24(sp)
    80004804:	6442                	ld	s0,16(sp)
    80004806:	64a2                	ld	s1,8(sp)
    80004808:	6902                	ld	s2,0(sp)
    8000480a:	6105                	addi	sp,sp,32
    8000480c:	8082                	ret

000000008000480e <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000480e:	1101                	addi	sp,sp,-32
    80004810:	ec06                	sd	ra,24(sp)
    80004812:	e822                	sd	s0,16(sp)
    80004814:	e426                	sd	s1,8(sp)
    80004816:	e04a                	sd	s2,0(sp)
    80004818:	1000                	addi	s0,sp,32
    8000481a:	84aa                	mv	s1,a0
    8000481c:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000481e:	00004597          	auipc	a1,0x4
    80004822:	ee258593          	addi	a1,a1,-286 # 80008700 <syscalls+0x230>
    80004826:	0521                	addi	a0,a0,8
    80004828:	ffffc097          	auipc	ra,0xffffc
    8000482c:	6c0080e7          	jalr	1728(ra) # 80000ee8 <initlock>
  lk->name = name;
    80004830:	0324b423          	sd	s2,40(s1)
  lk->locked = 0;
    80004834:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004838:	0204a823          	sw	zero,48(s1)
}
    8000483c:	60e2                	ld	ra,24(sp)
    8000483e:	6442                	ld	s0,16(sp)
    80004840:	64a2                	ld	s1,8(sp)
    80004842:	6902                	ld	s2,0(sp)
    80004844:	6105                	addi	sp,sp,32
    80004846:	8082                	ret

0000000080004848 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004848:	1101                	addi	sp,sp,-32
    8000484a:	ec06                	sd	ra,24(sp)
    8000484c:	e822                	sd	s0,16(sp)
    8000484e:	e426                	sd	s1,8(sp)
    80004850:	e04a                	sd	s2,0(sp)
    80004852:	1000                	addi	s0,sp,32
    80004854:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004856:	00850913          	addi	s2,a0,8
    8000485a:	854a                	mv	a0,s2
    8000485c:	ffffc097          	auipc	ra,0xffffc
    80004860:	510080e7          	jalr	1296(ra) # 80000d6c <acquire>
  while (lk->locked) {
    80004864:	409c                	lw	a5,0(s1)
    80004866:	cb89                	beqz	a5,80004878 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004868:	85ca                	mv	a1,s2
    8000486a:	8526                	mv	a0,s1
    8000486c:	ffffe097          	auipc	ra,0xffffe
    80004870:	d58080e7          	jalr	-680(ra) # 800025c4 <sleep>
  while (lk->locked) {
    80004874:	409c                	lw	a5,0(s1)
    80004876:	fbed                	bnez	a5,80004868 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004878:	4785                	li	a5,1
    8000487a:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000487c:	ffffd097          	auipc	ra,0xffffd
    80004880:	538080e7          	jalr	1336(ra) # 80001db4 <myproc>
    80004884:	413c                	lw	a5,64(a0)
    80004886:	d89c                	sw	a5,48(s1)
  release(&lk->lk);
    80004888:	854a                	mv	a0,s2
    8000488a:	ffffc097          	auipc	ra,0xffffc
    8000488e:	5b2080e7          	jalr	1458(ra) # 80000e3c <release>
}
    80004892:	60e2                	ld	ra,24(sp)
    80004894:	6442                	ld	s0,16(sp)
    80004896:	64a2                	ld	s1,8(sp)
    80004898:	6902                	ld	s2,0(sp)
    8000489a:	6105                	addi	sp,sp,32
    8000489c:	8082                	ret

000000008000489e <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000489e:	1101                	addi	sp,sp,-32
    800048a0:	ec06                	sd	ra,24(sp)
    800048a2:	e822                	sd	s0,16(sp)
    800048a4:	e426                	sd	s1,8(sp)
    800048a6:	e04a                	sd	s2,0(sp)
    800048a8:	1000                	addi	s0,sp,32
    800048aa:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800048ac:	00850913          	addi	s2,a0,8
    800048b0:	854a                	mv	a0,s2
    800048b2:	ffffc097          	auipc	ra,0xffffc
    800048b6:	4ba080e7          	jalr	1210(ra) # 80000d6c <acquire>
  lk->locked = 0;
    800048ba:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800048be:	0204a823          	sw	zero,48(s1)
  wakeup(lk);
    800048c2:	8526                	mv	a0,s1
    800048c4:	ffffe097          	auipc	ra,0xffffe
    800048c8:	e86080e7          	jalr	-378(ra) # 8000274a <wakeup>
  release(&lk->lk);
    800048cc:	854a                	mv	a0,s2
    800048ce:	ffffc097          	auipc	ra,0xffffc
    800048d2:	56e080e7          	jalr	1390(ra) # 80000e3c <release>
}
    800048d6:	60e2                	ld	ra,24(sp)
    800048d8:	6442                	ld	s0,16(sp)
    800048da:	64a2                	ld	s1,8(sp)
    800048dc:	6902                	ld	s2,0(sp)
    800048de:	6105                	addi	sp,sp,32
    800048e0:	8082                	ret

00000000800048e2 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800048e2:	7179                	addi	sp,sp,-48
    800048e4:	f406                	sd	ra,40(sp)
    800048e6:	f022                	sd	s0,32(sp)
    800048e8:	ec26                	sd	s1,24(sp)
    800048ea:	e84a                	sd	s2,16(sp)
    800048ec:	e44e                	sd	s3,8(sp)
    800048ee:	1800                	addi	s0,sp,48
    800048f0:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800048f2:	00850913          	addi	s2,a0,8
    800048f6:	854a                	mv	a0,s2
    800048f8:	ffffc097          	auipc	ra,0xffffc
    800048fc:	474080e7          	jalr	1140(ra) # 80000d6c <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004900:	409c                	lw	a5,0(s1)
    80004902:	ef99                	bnez	a5,80004920 <holdingsleep+0x3e>
    80004904:	4481                	li	s1,0
  release(&lk->lk);
    80004906:	854a                	mv	a0,s2
    80004908:	ffffc097          	auipc	ra,0xffffc
    8000490c:	534080e7          	jalr	1332(ra) # 80000e3c <release>
  return r;
}
    80004910:	8526                	mv	a0,s1
    80004912:	70a2                	ld	ra,40(sp)
    80004914:	7402                	ld	s0,32(sp)
    80004916:	64e2                	ld	s1,24(sp)
    80004918:	6942                	ld	s2,16(sp)
    8000491a:	69a2                	ld	s3,8(sp)
    8000491c:	6145                	addi	sp,sp,48
    8000491e:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004920:	0304a983          	lw	s3,48(s1)
    80004924:	ffffd097          	auipc	ra,0xffffd
    80004928:	490080e7          	jalr	1168(ra) # 80001db4 <myproc>
    8000492c:	4124                	lw	s1,64(a0)
    8000492e:	413484b3          	sub	s1,s1,s3
    80004932:	0014b493          	seqz	s1,s1
    80004936:	bfc1                	j	80004906 <holdingsleep+0x24>

0000000080004938 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004938:	1141                	addi	sp,sp,-16
    8000493a:	e406                	sd	ra,8(sp)
    8000493c:	e022                	sd	s0,0(sp)
    8000493e:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004940:	00004597          	auipc	a1,0x4
    80004944:	dd058593          	addi	a1,a1,-560 # 80008710 <syscalls+0x240>
    80004948:	00021517          	auipc	a0,0x21
    8000494c:	76850513          	addi	a0,a0,1896 # 800260b0 <ftable>
    80004950:	ffffc097          	auipc	ra,0xffffc
    80004954:	598080e7          	jalr	1432(ra) # 80000ee8 <initlock>
}
    80004958:	60a2                	ld	ra,8(sp)
    8000495a:	6402                	ld	s0,0(sp)
    8000495c:	0141                	addi	sp,sp,16
    8000495e:	8082                	ret

0000000080004960 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004960:	1101                	addi	sp,sp,-32
    80004962:	ec06                	sd	ra,24(sp)
    80004964:	e822                	sd	s0,16(sp)
    80004966:	e426                	sd	s1,8(sp)
    80004968:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000496a:	00021517          	auipc	a0,0x21
    8000496e:	74650513          	addi	a0,a0,1862 # 800260b0 <ftable>
    80004972:	ffffc097          	auipc	ra,0xffffc
    80004976:	3fa080e7          	jalr	1018(ra) # 80000d6c <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000497a:	00021497          	auipc	s1,0x21
    8000497e:	75648493          	addi	s1,s1,1878 # 800260d0 <ftable+0x20>
    80004982:	00022717          	auipc	a4,0x22
    80004986:	6ee70713          	addi	a4,a4,1774 # 80027070 <ftable+0xfc0>
    if(f->ref == 0){
    8000498a:	40dc                	lw	a5,4(s1)
    8000498c:	cf99                	beqz	a5,800049aa <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000498e:	02848493          	addi	s1,s1,40
    80004992:	fee49ce3          	bne	s1,a4,8000498a <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004996:	00021517          	auipc	a0,0x21
    8000499a:	71a50513          	addi	a0,a0,1818 # 800260b0 <ftable>
    8000499e:	ffffc097          	auipc	ra,0xffffc
    800049a2:	49e080e7          	jalr	1182(ra) # 80000e3c <release>
  return 0;
    800049a6:	4481                	li	s1,0
    800049a8:	a819                	j	800049be <filealloc+0x5e>
      f->ref = 1;
    800049aa:	4785                	li	a5,1
    800049ac:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800049ae:	00021517          	auipc	a0,0x21
    800049b2:	70250513          	addi	a0,a0,1794 # 800260b0 <ftable>
    800049b6:	ffffc097          	auipc	ra,0xffffc
    800049ba:	486080e7          	jalr	1158(ra) # 80000e3c <release>
}
    800049be:	8526                	mv	a0,s1
    800049c0:	60e2                	ld	ra,24(sp)
    800049c2:	6442                	ld	s0,16(sp)
    800049c4:	64a2                	ld	s1,8(sp)
    800049c6:	6105                	addi	sp,sp,32
    800049c8:	8082                	ret

00000000800049ca <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800049ca:	1101                	addi	sp,sp,-32
    800049cc:	ec06                	sd	ra,24(sp)
    800049ce:	e822                	sd	s0,16(sp)
    800049d0:	e426                	sd	s1,8(sp)
    800049d2:	1000                	addi	s0,sp,32
    800049d4:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800049d6:	00021517          	auipc	a0,0x21
    800049da:	6da50513          	addi	a0,a0,1754 # 800260b0 <ftable>
    800049de:	ffffc097          	auipc	ra,0xffffc
    800049e2:	38e080e7          	jalr	910(ra) # 80000d6c <acquire>
  if(f->ref < 1)
    800049e6:	40dc                	lw	a5,4(s1)
    800049e8:	02f05263          	blez	a5,80004a0c <filedup+0x42>
    panic("filedup");
  f->ref++;
    800049ec:	2785                	addiw	a5,a5,1
    800049ee:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800049f0:	00021517          	auipc	a0,0x21
    800049f4:	6c050513          	addi	a0,a0,1728 # 800260b0 <ftable>
    800049f8:	ffffc097          	auipc	ra,0xffffc
    800049fc:	444080e7          	jalr	1092(ra) # 80000e3c <release>
  return f;
}
    80004a00:	8526                	mv	a0,s1
    80004a02:	60e2                	ld	ra,24(sp)
    80004a04:	6442                	ld	s0,16(sp)
    80004a06:	64a2                	ld	s1,8(sp)
    80004a08:	6105                	addi	sp,sp,32
    80004a0a:	8082                	ret
    panic("filedup");
    80004a0c:	00004517          	auipc	a0,0x4
    80004a10:	d0c50513          	addi	a0,a0,-756 # 80008718 <syscalls+0x248>
    80004a14:	ffffc097          	auipc	ra,0xffffc
    80004a18:	b3c080e7          	jalr	-1220(ra) # 80000550 <panic>

0000000080004a1c <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004a1c:	7139                	addi	sp,sp,-64
    80004a1e:	fc06                	sd	ra,56(sp)
    80004a20:	f822                	sd	s0,48(sp)
    80004a22:	f426                	sd	s1,40(sp)
    80004a24:	f04a                	sd	s2,32(sp)
    80004a26:	ec4e                	sd	s3,24(sp)
    80004a28:	e852                	sd	s4,16(sp)
    80004a2a:	e456                	sd	s5,8(sp)
    80004a2c:	0080                	addi	s0,sp,64
    80004a2e:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004a30:	00021517          	auipc	a0,0x21
    80004a34:	68050513          	addi	a0,a0,1664 # 800260b0 <ftable>
    80004a38:	ffffc097          	auipc	ra,0xffffc
    80004a3c:	334080e7          	jalr	820(ra) # 80000d6c <acquire>
  if(f->ref < 1)
    80004a40:	40dc                	lw	a5,4(s1)
    80004a42:	06f05163          	blez	a5,80004aa4 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004a46:	37fd                	addiw	a5,a5,-1
    80004a48:	0007871b          	sext.w	a4,a5
    80004a4c:	c0dc                	sw	a5,4(s1)
    80004a4e:	06e04363          	bgtz	a4,80004ab4 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004a52:	0004a903          	lw	s2,0(s1)
    80004a56:	0094ca83          	lbu	s5,9(s1)
    80004a5a:	0104ba03          	ld	s4,16(s1)
    80004a5e:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004a62:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004a66:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004a6a:	00021517          	auipc	a0,0x21
    80004a6e:	64650513          	addi	a0,a0,1606 # 800260b0 <ftable>
    80004a72:	ffffc097          	auipc	ra,0xffffc
    80004a76:	3ca080e7          	jalr	970(ra) # 80000e3c <release>

  if(ff.type == FD_PIPE){
    80004a7a:	4785                	li	a5,1
    80004a7c:	04f90d63          	beq	s2,a5,80004ad6 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004a80:	3979                	addiw	s2,s2,-2
    80004a82:	4785                	li	a5,1
    80004a84:	0527e063          	bltu	a5,s2,80004ac4 <fileclose+0xa8>
    begin_op();
    80004a88:	00000097          	auipc	ra,0x0
    80004a8c:	ac0080e7          	jalr	-1344(ra) # 80004548 <begin_op>
    iput(ff.ip);
    80004a90:	854e                	mv	a0,s3
    80004a92:	fffff097          	auipc	ra,0xfffff
    80004a96:	2a0080e7          	jalr	672(ra) # 80003d32 <iput>
    end_op();
    80004a9a:	00000097          	auipc	ra,0x0
    80004a9e:	b2e080e7          	jalr	-1234(ra) # 800045c8 <end_op>
    80004aa2:	a00d                	j	80004ac4 <fileclose+0xa8>
    panic("fileclose");
    80004aa4:	00004517          	auipc	a0,0x4
    80004aa8:	c7c50513          	addi	a0,a0,-900 # 80008720 <syscalls+0x250>
    80004aac:	ffffc097          	auipc	ra,0xffffc
    80004ab0:	aa4080e7          	jalr	-1372(ra) # 80000550 <panic>
    release(&ftable.lock);
    80004ab4:	00021517          	auipc	a0,0x21
    80004ab8:	5fc50513          	addi	a0,a0,1532 # 800260b0 <ftable>
    80004abc:	ffffc097          	auipc	ra,0xffffc
    80004ac0:	380080e7          	jalr	896(ra) # 80000e3c <release>
  }
}
    80004ac4:	70e2                	ld	ra,56(sp)
    80004ac6:	7442                	ld	s0,48(sp)
    80004ac8:	74a2                	ld	s1,40(sp)
    80004aca:	7902                	ld	s2,32(sp)
    80004acc:	69e2                	ld	s3,24(sp)
    80004ace:	6a42                	ld	s4,16(sp)
    80004ad0:	6aa2                	ld	s5,8(sp)
    80004ad2:	6121                	addi	sp,sp,64
    80004ad4:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004ad6:	85d6                	mv	a1,s5
    80004ad8:	8552                	mv	a0,s4
    80004ada:	00000097          	auipc	ra,0x0
    80004ade:	372080e7          	jalr	882(ra) # 80004e4c <pipeclose>
    80004ae2:	b7cd                	j	80004ac4 <fileclose+0xa8>

0000000080004ae4 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004ae4:	715d                	addi	sp,sp,-80
    80004ae6:	e486                	sd	ra,72(sp)
    80004ae8:	e0a2                	sd	s0,64(sp)
    80004aea:	fc26                	sd	s1,56(sp)
    80004aec:	f84a                	sd	s2,48(sp)
    80004aee:	f44e                	sd	s3,40(sp)
    80004af0:	0880                	addi	s0,sp,80
    80004af2:	84aa                	mv	s1,a0
    80004af4:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004af6:	ffffd097          	auipc	ra,0xffffd
    80004afa:	2be080e7          	jalr	702(ra) # 80001db4 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004afe:	409c                	lw	a5,0(s1)
    80004b00:	37f9                	addiw	a5,a5,-2
    80004b02:	4705                	li	a4,1
    80004b04:	04f76763          	bltu	a4,a5,80004b52 <filestat+0x6e>
    80004b08:	892a                	mv	s2,a0
    ilock(f->ip);
    80004b0a:	6c88                	ld	a0,24(s1)
    80004b0c:	fffff097          	auipc	ra,0xfffff
    80004b10:	06c080e7          	jalr	108(ra) # 80003b78 <ilock>
    stati(f->ip, &st);
    80004b14:	fb840593          	addi	a1,s0,-72
    80004b18:	6c88                	ld	a0,24(s1)
    80004b1a:	fffff097          	auipc	ra,0xfffff
    80004b1e:	2e8080e7          	jalr	744(ra) # 80003e02 <stati>
    iunlock(f->ip);
    80004b22:	6c88                	ld	a0,24(s1)
    80004b24:	fffff097          	auipc	ra,0xfffff
    80004b28:	116080e7          	jalr	278(ra) # 80003c3a <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004b2c:	46e1                	li	a3,24
    80004b2e:	fb840613          	addi	a2,s0,-72
    80004b32:	85ce                	mv	a1,s3
    80004b34:	05893503          	ld	a0,88(s2)
    80004b38:	ffffd097          	auipc	ra,0xffffd
    80004b3c:	f70080e7          	jalr	-144(ra) # 80001aa8 <copyout>
    80004b40:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004b44:	60a6                	ld	ra,72(sp)
    80004b46:	6406                	ld	s0,64(sp)
    80004b48:	74e2                	ld	s1,56(sp)
    80004b4a:	7942                	ld	s2,48(sp)
    80004b4c:	79a2                	ld	s3,40(sp)
    80004b4e:	6161                	addi	sp,sp,80
    80004b50:	8082                	ret
  return -1;
    80004b52:	557d                	li	a0,-1
    80004b54:	bfc5                	j	80004b44 <filestat+0x60>

0000000080004b56 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004b56:	7179                	addi	sp,sp,-48
    80004b58:	f406                	sd	ra,40(sp)
    80004b5a:	f022                	sd	s0,32(sp)
    80004b5c:	ec26                	sd	s1,24(sp)
    80004b5e:	e84a                	sd	s2,16(sp)
    80004b60:	e44e                	sd	s3,8(sp)
    80004b62:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004b64:	00854783          	lbu	a5,8(a0)
    80004b68:	c3d5                	beqz	a5,80004c0c <fileread+0xb6>
    80004b6a:	84aa                	mv	s1,a0
    80004b6c:	89ae                	mv	s3,a1
    80004b6e:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004b70:	411c                	lw	a5,0(a0)
    80004b72:	4705                	li	a4,1
    80004b74:	04e78963          	beq	a5,a4,80004bc6 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b78:	470d                	li	a4,3
    80004b7a:	04e78d63          	beq	a5,a4,80004bd4 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b7e:	4709                	li	a4,2
    80004b80:	06e79e63          	bne	a5,a4,80004bfc <fileread+0xa6>
    ilock(f->ip);
    80004b84:	6d08                	ld	a0,24(a0)
    80004b86:	fffff097          	auipc	ra,0xfffff
    80004b8a:	ff2080e7          	jalr	-14(ra) # 80003b78 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004b8e:	874a                	mv	a4,s2
    80004b90:	5094                	lw	a3,32(s1)
    80004b92:	864e                	mv	a2,s3
    80004b94:	4585                	li	a1,1
    80004b96:	6c88                	ld	a0,24(s1)
    80004b98:	fffff097          	auipc	ra,0xfffff
    80004b9c:	294080e7          	jalr	660(ra) # 80003e2c <readi>
    80004ba0:	892a                	mv	s2,a0
    80004ba2:	00a05563          	blez	a0,80004bac <fileread+0x56>
      f->off += r;
    80004ba6:	509c                	lw	a5,32(s1)
    80004ba8:	9fa9                	addw	a5,a5,a0
    80004baa:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004bac:	6c88                	ld	a0,24(s1)
    80004bae:	fffff097          	auipc	ra,0xfffff
    80004bb2:	08c080e7          	jalr	140(ra) # 80003c3a <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004bb6:	854a                	mv	a0,s2
    80004bb8:	70a2                	ld	ra,40(sp)
    80004bba:	7402                	ld	s0,32(sp)
    80004bbc:	64e2                	ld	s1,24(sp)
    80004bbe:	6942                	ld	s2,16(sp)
    80004bc0:	69a2                	ld	s3,8(sp)
    80004bc2:	6145                	addi	sp,sp,48
    80004bc4:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004bc6:	6908                	ld	a0,16(a0)
    80004bc8:	00000097          	auipc	ra,0x0
    80004bcc:	422080e7          	jalr	1058(ra) # 80004fea <piperead>
    80004bd0:	892a                	mv	s2,a0
    80004bd2:	b7d5                	j	80004bb6 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004bd4:	02451783          	lh	a5,36(a0)
    80004bd8:	03079693          	slli	a3,a5,0x30
    80004bdc:	92c1                	srli	a3,a3,0x30
    80004bde:	4725                	li	a4,9
    80004be0:	02d76863          	bltu	a4,a3,80004c10 <fileread+0xba>
    80004be4:	0792                	slli	a5,a5,0x4
    80004be6:	00021717          	auipc	a4,0x21
    80004bea:	42a70713          	addi	a4,a4,1066 # 80026010 <devsw>
    80004bee:	97ba                	add	a5,a5,a4
    80004bf0:	639c                	ld	a5,0(a5)
    80004bf2:	c38d                	beqz	a5,80004c14 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004bf4:	4505                	li	a0,1
    80004bf6:	9782                	jalr	a5
    80004bf8:	892a                	mv	s2,a0
    80004bfa:	bf75                	j	80004bb6 <fileread+0x60>
    panic("fileread");
    80004bfc:	00004517          	auipc	a0,0x4
    80004c00:	b3450513          	addi	a0,a0,-1228 # 80008730 <syscalls+0x260>
    80004c04:	ffffc097          	auipc	ra,0xffffc
    80004c08:	94c080e7          	jalr	-1716(ra) # 80000550 <panic>
    return -1;
    80004c0c:	597d                	li	s2,-1
    80004c0e:	b765                	j	80004bb6 <fileread+0x60>
      return -1;
    80004c10:	597d                	li	s2,-1
    80004c12:	b755                	j	80004bb6 <fileread+0x60>
    80004c14:	597d                	li	s2,-1
    80004c16:	b745                	j	80004bb6 <fileread+0x60>

0000000080004c18 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004c18:	00954783          	lbu	a5,9(a0)
    80004c1c:	14078563          	beqz	a5,80004d66 <filewrite+0x14e>
{
    80004c20:	715d                	addi	sp,sp,-80
    80004c22:	e486                	sd	ra,72(sp)
    80004c24:	e0a2                	sd	s0,64(sp)
    80004c26:	fc26                	sd	s1,56(sp)
    80004c28:	f84a                	sd	s2,48(sp)
    80004c2a:	f44e                	sd	s3,40(sp)
    80004c2c:	f052                	sd	s4,32(sp)
    80004c2e:	ec56                	sd	s5,24(sp)
    80004c30:	e85a                	sd	s6,16(sp)
    80004c32:	e45e                	sd	s7,8(sp)
    80004c34:	e062                	sd	s8,0(sp)
    80004c36:	0880                	addi	s0,sp,80
    80004c38:	892a                	mv	s2,a0
    80004c3a:	8aae                	mv	s5,a1
    80004c3c:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c3e:	411c                	lw	a5,0(a0)
    80004c40:	4705                	li	a4,1
    80004c42:	02e78263          	beq	a5,a4,80004c66 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c46:	470d                	li	a4,3
    80004c48:	02e78563          	beq	a5,a4,80004c72 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c4c:	4709                	li	a4,2
    80004c4e:	10e79463          	bne	a5,a4,80004d56 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004c52:	0ec05e63          	blez	a2,80004d4e <filewrite+0x136>
    int i = 0;
    80004c56:	4981                	li	s3,0
    80004c58:	6b05                	lui	s6,0x1
    80004c5a:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004c5e:	6b85                	lui	s7,0x1
    80004c60:	c00b8b9b          	addiw	s7,s7,-1024
    80004c64:	a851                	j	80004cf8 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004c66:	6908                	ld	a0,16(a0)
    80004c68:	00000097          	auipc	ra,0x0
    80004c6c:	25e080e7          	jalr	606(ra) # 80004ec6 <pipewrite>
    80004c70:	a85d                	j	80004d26 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004c72:	02451783          	lh	a5,36(a0)
    80004c76:	03079693          	slli	a3,a5,0x30
    80004c7a:	92c1                	srli	a3,a3,0x30
    80004c7c:	4725                	li	a4,9
    80004c7e:	0ed76663          	bltu	a4,a3,80004d6a <filewrite+0x152>
    80004c82:	0792                	slli	a5,a5,0x4
    80004c84:	00021717          	auipc	a4,0x21
    80004c88:	38c70713          	addi	a4,a4,908 # 80026010 <devsw>
    80004c8c:	97ba                	add	a5,a5,a4
    80004c8e:	679c                	ld	a5,8(a5)
    80004c90:	cff9                	beqz	a5,80004d6e <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    80004c92:	4505                	li	a0,1
    80004c94:	9782                	jalr	a5
    80004c96:	a841                	j	80004d26 <filewrite+0x10e>
    80004c98:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004c9c:	00000097          	auipc	ra,0x0
    80004ca0:	8ac080e7          	jalr	-1876(ra) # 80004548 <begin_op>
      ilock(f->ip);
    80004ca4:	01893503          	ld	a0,24(s2)
    80004ca8:	fffff097          	auipc	ra,0xfffff
    80004cac:	ed0080e7          	jalr	-304(ra) # 80003b78 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004cb0:	8762                	mv	a4,s8
    80004cb2:	02092683          	lw	a3,32(s2)
    80004cb6:	01598633          	add	a2,s3,s5
    80004cba:	4585                	li	a1,1
    80004cbc:	01893503          	ld	a0,24(s2)
    80004cc0:	fffff097          	auipc	ra,0xfffff
    80004cc4:	264080e7          	jalr	612(ra) # 80003f24 <writei>
    80004cc8:	84aa                	mv	s1,a0
    80004cca:	02a05f63          	blez	a0,80004d08 <filewrite+0xf0>
        f->off += r;
    80004cce:	02092783          	lw	a5,32(s2)
    80004cd2:	9fa9                	addw	a5,a5,a0
    80004cd4:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004cd8:	01893503          	ld	a0,24(s2)
    80004cdc:	fffff097          	auipc	ra,0xfffff
    80004ce0:	f5e080e7          	jalr	-162(ra) # 80003c3a <iunlock>
      end_op();
    80004ce4:	00000097          	auipc	ra,0x0
    80004ce8:	8e4080e7          	jalr	-1820(ra) # 800045c8 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004cec:	049c1963          	bne	s8,s1,80004d3e <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004cf0:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004cf4:	0349d663          	bge	s3,s4,80004d20 <filewrite+0x108>
      int n1 = n - i;
    80004cf8:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004cfc:	84be                	mv	s1,a5
    80004cfe:	2781                	sext.w	a5,a5
    80004d00:	f8fb5ce3          	bge	s6,a5,80004c98 <filewrite+0x80>
    80004d04:	84de                	mv	s1,s7
    80004d06:	bf49                	j	80004c98 <filewrite+0x80>
      iunlock(f->ip);
    80004d08:	01893503          	ld	a0,24(s2)
    80004d0c:	fffff097          	auipc	ra,0xfffff
    80004d10:	f2e080e7          	jalr	-210(ra) # 80003c3a <iunlock>
      end_op();
    80004d14:	00000097          	auipc	ra,0x0
    80004d18:	8b4080e7          	jalr	-1868(ra) # 800045c8 <end_op>
      if(r < 0)
    80004d1c:	fc04d8e3          	bgez	s1,80004cec <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004d20:	8552                	mv	a0,s4
    80004d22:	033a1863          	bne	s4,s3,80004d52 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004d26:	60a6                	ld	ra,72(sp)
    80004d28:	6406                	ld	s0,64(sp)
    80004d2a:	74e2                	ld	s1,56(sp)
    80004d2c:	7942                	ld	s2,48(sp)
    80004d2e:	79a2                	ld	s3,40(sp)
    80004d30:	7a02                	ld	s4,32(sp)
    80004d32:	6ae2                	ld	s5,24(sp)
    80004d34:	6b42                	ld	s6,16(sp)
    80004d36:	6ba2                	ld	s7,8(sp)
    80004d38:	6c02                	ld	s8,0(sp)
    80004d3a:	6161                	addi	sp,sp,80
    80004d3c:	8082                	ret
        panic("short filewrite");
    80004d3e:	00004517          	auipc	a0,0x4
    80004d42:	a0250513          	addi	a0,a0,-1534 # 80008740 <syscalls+0x270>
    80004d46:	ffffc097          	auipc	ra,0xffffc
    80004d4a:	80a080e7          	jalr	-2038(ra) # 80000550 <panic>
    int i = 0;
    80004d4e:	4981                	li	s3,0
    80004d50:	bfc1                	j	80004d20 <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004d52:	557d                	li	a0,-1
    80004d54:	bfc9                	j	80004d26 <filewrite+0x10e>
    panic("filewrite");
    80004d56:	00004517          	auipc	a0,0x4
    80004d5a:	9fa50513          	addi	a0,a0,-1542 # 80008750 <syscalls+0x280>
    80004d5e:	ffffb097          	auipc	ra,0xffffb
    80004d62:	7f2080e7          	jalr	2034(ra) # 80000550 <panic>
    return -1;
    80004d66:	557d                	li	a0,-1
}
    80004d68:	8082                	ret
      return -1;
    80004d6a:	557d                	li	a0,-1
    80004d6c:	bf6d                	j	80004d26 <filewrite+0x10e>
    80004d6e:	557d                	li	a0,-1
    80004d70:	bf5d                	j	80004d26 <filewrite+0x10e>

0000000080004d72 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004d72:	7179                	addi	sp,sp,-48
    80004d74:	f406                	sd	ra,40(sp)
    80004d76:	f022                	sd	s0,32(sp)
    80004d78:	ec26                	sd	s1,24(sp)
    80004d7a:	e84a                	sd	s2,16(sp)
    80004d7c:	e44e                	sd	s3,8(sp)
    80004d7e:	e052                	sd	s4,0(sp)
    80004d80:	1800                	addi	s0,sp,48
    80004d82:	84aa                	mv	s1,a0
    80004d84:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004d86:	0005b023          	sd	zero,0(a1)
    80004d8a:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004d8e:	00000097          	auipc	ra,0x0
    80004d92:	bd2080e7          	jalr	-1070(ra) # 80004960 <filealloc>
    80004d96:	e088                	sd	a0,0(s1)
    80004d98:	c551                	beqz	a0,80004e24 <pipealloc+0xb2>
    80004d9a:	00000097          	auipc	ra,0x0
    80004d9e:	bc6080e7          	jalr	-1082(ra) # 80004960 <filealloc>
    80004da2:	00aa3023          	sd	a0,0(s4)
    80004da6:	c92d                	beqz	a0,80004e18 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004da8:	ffffc097          	auipc	ra,0xffffc
    80004dac:	e48080e7          	jalr	-440(ra) # 80000bf0 <kalloc>
    80004db0:	892a                	mv	s2,a0
    80004db2:	c125                	beqz	a0,80004e12 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004db4:	4985                	li	s3,1
    80004db6:	23352423          	sw	s3,552(a0)
  pi->writeopen = 1;
    80004dba:	23352623          	sw	s3,556(a0)
  pi->nwrite = 0;
    80004dbe:	22052223          	sw	zero,548(a0)
  pi->nread = 0;
    80004dc2:	22052023          	sw	zero,544(a0)
  initlock(&pi->lock, "pipe");
    80004dc6:	00004597          	auipc	a1,0x4
    80004dca:	99a58593          	addi	a1,a1,-1638 # 80008760 <syscalls+0x290>
    80004dce:	ffffc097          	auipc	ra,0xffffc
    80004dd2:	11a080e7          	jalr	282(ra) # 80000ee8 <initlock>
  (*f0)->type = FD_PIPE;
    80004dd6:	609c                	ld	a5,0(s1)
    80004dd8:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004ddc:	609c                	ld	a5,0(s1)
    80004dde:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004de2:	609c                	ld	a5,0(s1)
    80004de4:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004de8:	609c                	ld	a5,0(s1)
    80004dea:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004dee:	000a3783          	ld	a5,0(s4)
    80004df2:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004df6:	000a3783          	ld	a5,0(s4)
    80004dfa:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004dfe:	000a3783          	ld	a5,0(s4)
    80004e02:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004e06:	000a3783          	ld	a5,0(s4)
    80004e0a:	0127b823          	sd	s2,16(a5)
  return 0;
    80004e0e:	4501                	li	a0,0
    80004e10:	a025                	j	80004e38 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004e12:	6088                	ld	a0,0(s1)
    80004e14:	e501                	bnez	a0,80004e1c <pipealloc+0xaa>
    80004e16:	a039                	j	80004e24 <pipealloc+0xb2>
    80004e18:	6088                	ld	a0,0(s1)
    80004e1a:	c51d                	beqz	a0,80004e48 <pipealloc+0xd6>
    fileclose(*f0);
    80004e1c:	00000097          	auipc	ra,0x0
    80004e20:	c00080e7          	jalr	-1024(ra) # 80004a1c <fileclose>
  if(*f1)
    80004e24:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004e28:	557d                	li	a0,-1
  if(*f1)
    80004e2a:	c799                	beqz	a5,80004e38 <pipealloc+0xc6>
    fileclose(*f1);
    80004e2c:	853e                	mv	a0,a5
    80004e2e:	00000097          	auipc	ra,0x0
    80004e32:	bee080e7          	jalr	-1042(ra) # 80004a1c <fileclose>
  return -1;
    80004e36:	557d                	li	a0,-1
}
    80004e38:	70a2                	ld	ra,40(sp)
    80004e3a:	7402                	ld	s0,32(sp)
    80004e3c:	64e2                	ld	s1,24(sp)
    80004e3e:	6942                	ld	s2,16(sp)
    80004e40:	69a2                	ld	s3,8(sp)
    80004e42:	6a02                	ld	s4,0(sp)
    80004e44:	6145                	addi	sp,sp,48
    80004e46:	8082                	ret
  return -1;
    80004e48:	557d                	li	a0,-1
    80004e4a:	b7fd                	j	80004e38 <pipealloc+0xc6>

0000000080004e4c <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004e4c:	1101                	addi	sp,sp,-32
    80004e4e:	ec06                	sd	ra,24(sp)
    80004e50:	e822                	sd	s0,16(sp)
    80004e52:	e426                	sd	s1,8(sp)
    80004e54:	e04a                	sd	s2,0(sp)
    80004e56:	1000                	addi	s0,sp,32
    80004e58:	84aa                	mv	s1,a0
    80004e5a:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004e5c:	ffffc097          	auipc	ra,0xffffc
    80004e60:	f10080e7          	jalr	-240(ra) # 80000d6c <acquire>
  if(writable){
    80004e64:	04090263          	beqz	s2,80004ea8 <pipeclose+0x5c>
    pi->writeopen = 0;
    80004e68:	2204a623          	sw	zero,556(s1)
    wakeup(&pi->nread);
    80004e6c:	22048513          	addi	a0,s1,544
    80004e70:	ffffe097          	auipc	ra,0xffffe
    80004e74:	8da080e7          	jalr	-1830(ra) # 8000274a <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004e78:	2284b783          	ld	a5,552(s1)
    80004e7c:	ef9d                	bnez	a5,80004eba <pipeclose+0x6e>
    release(&pi->lock);
    80004e7e:	8526                	mv	a0,s1
    80004e80:	ffffc097          	auipc	ra,0xffffc
    80004e84:	fbc080e7          	jalr	-68(ra) # 80000e3c <release>
#ifdef LAB_LOCK
    freelock(&pi->lock);
    80004e88:	8526                	mv	a0,s1
    80004e8a:	ffffc097          	auipc	ra,0xffffc
    80004e8e:	ffa080e7          	jalr	-6(ra) # 80000e84 <freelock>
#endif    
    kfree((char*)pi);
    80004e92:	8526                	mv	a0,s1
    80004e94:	ffffc097          	auipc	ra,0xffffc
    80004e98:	b98080e7          	jalr	-1128(ra) # 80000a2c <kfree>
  } else
    release(&pi->lock);
}
    80004e9c:	60e2                	ld	ra,24(sp)
    80004e9e:	6442                	ld	s0,16(sp)
    80004ea0:	64a2                	ld	s1,8(sp)
    80004ea2:	6902                	ld	s2,0(sp)
    80004ea4:	6105                	addi	sp,sp,32
    80004ea6:	8082                	ret
    pi->readopen = 0;
    80004ea8:	2204a423          	sw	zero,552(s1)
    wakeup(&pi->nwrite);
    80004eac:	22448513          	addi	a0,s1,548
    80004eb0:	ffffe097          	auipc	ra,0xffffe
    80004eb4:	89a080e7          	jalr	-1894(ra) # 8000274a <wakeup>
    80004eb8:	b7c1                	j	80004e78 <pipeclose+0x2c>
    release(&pi->lock);
    80004eba:	8526                	mv	a0,s1
    80004ebc:	ffffc097          	auipc	ra,0xffffc
    80004ec0:	f80080e7          	jalr	-128(ra) # 80000e3c <release>
}
    80004ec4:	bfe1                	j	80004e9c <pipeclose+0x50>

0000000080004ec6 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004ec6:	7119                	addi	sp,sp,-128
    80004ec8:	fc86                	sd	ra,120(sp)
    80004eca:	f8a2                	sd	s0,112(sp)
    80004ecc:	f4a6                	sd	s1,104(sp)
    80004ece:	f0ca                	sd	s2,96(sp)
    80004ed0:	ecce                	sd	s3,88(sp)
    80004ed2:	e8d2                	sd	s4,80(sp)
    80004ed4:	e4d6                	sd	s5,72(sp)
    80004ed6:	e0da                	sd	s6,64(sp)
    80004ed8:	fc5e                	sd	s7,56(sp)
    80004eda:	f862                	sd	s8,48(sp)
    80004edc:	f466                	sd	s9,40(sp)
    80004ede:	f06a                	sd	s10,32(sp)
    80004ee0:	ec6e                	sd	s11,24(sp)
    80004ee2:	0100                	addi	s0,sp,128
    80004ee4:	84aa                	mv	s1,a0
    80004ee6:	8cae                	mv	s9,a1
    80004ee8:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004eea:	ffffd097          	auipc	ra,0xffffd
    80004eee:	eca080e7          	jalr	-310(ra) # 80001db4 <myproc>
    80004ef2:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004ef4:	8526                	mv	a0,s1
    80004ef6:	ffffc097          	auipc	ra,0xffffc
    80004efa:	e76080e7          	jalr	-394(ra) # 80000d6c <acquire>
  for(i = 0; i < n; i++){
    80004efe:	0d605963          	blez	s6,80004fd0 <pipewrite+0x10a>
    80004f02:	89a6                	mv	s3,s1
    80004f04:	3b7d                	addiw	s6,s6,-1
    80004f06:	1b02                	slli	s6,s6,0x20
    80004f08:	020b5b13          	srli	s6,s6,0x20
    80004f0c:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004f0e:	22048a93          	addi	s5,s1,544
      sleep(&pi->nwrite, &pi->lock);
    80004f12:	22448a13          	addi	s4,s1,548
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f16:	5dfd                	li	s11,-1
    80004f18:	000b8d1b          	sext.w	s10,s7
    80004f1c:	8c6a                	mv	s8,s10
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004f1e:	2204a783          	lw	a5,544(s1)
    80004f22:	2244a703          	lw	a4,548(s1)
    80004f26:	2007879b          	addiw	a5,a5,512
    80004f2a:	02f71b63          	bne	a4,a5,80004f60 <pipewrite+0x9a>
      if(pi->readopen == 0 || pr->killed){
    80004f2e:	2284a783          	lw	a5,552(s1)
    80004f32:	cbad                	beqz	a5,80004fa4 <pipewrite+0xde>
    80004f34:	03892783          	lw	a5,56(s2)
    80004f38:	e7b5                	bnez	a5,80004fa4 <pipewrite+0xde>
      wakeup(&pi->nread);
    80004f3a:	8556                	mv	a0,s5
    80004f3c:	ffffe097          	auipc	ra,0xffffe
    80004f40:	80e080e7          	jalr	-2034(ra) # 8000274a <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004f44:	85ce                	mv	a1,s3
    80004f46:	8552                	mv	a0,s4
    80004f48:	ffffd097          	auipc	ra,0xffffd
    80004f4c:	67c080e7          	jalr	1660(ra) # 800025c4 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004f50:	2204a783          	lw	a5,544(s1)
    80004f54:	2244a703          	lw	a4,548(s1)
    80004f58:	2007879b          	addiw	a5,a5,512
    80004f5c:	fcf709e3          	beq	a4,a5,80004f2e <pipewrite+0x68>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f60:	4685                	li	a3,1
    80004f62:	019b8633          	add	a2,s7,s9
    80004f66:	f8f40593          	addi	a1,s0,-113
    80004f6a:	05893503          	ld	a0,88(s2)
    80004f6e:	ffffd097          	auipc	ra,0xffffd
    80004f72:	bc6080e7          	jalr	-1082(ra) # 80001b34 <copyin>
    80004f76:	05b50e63          	beq	a0,s11,80004fd2 <pipewrite+0x10c>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004f7a:	2244a783          	lw	a5,548(s1)
    80004f7e:	0017871b          	addiw	a4,a5,1
    80004f82:	22e4a223          	sw	a4,548(s1)
    80004f86:	1ff7f793          	andi	a5,a5,511
    80004f8a:	97a6                	add	a5,a5,s1
    80004f8c:	f8f44703          	lbu	a4,-113(s0)
    80004f90:	02e78023          	sb	a4,32(a5)
  for(i = 0; i < n; i++){
    80004f94:	001d0c1b          	addiw	s8,s10,1
    80004f98:	001b8793          	addi	a5,s7,1 # 1001 <_entry-0x7fffefff>
    80004f9c:	036b8b63          	beq	s7,s6,80004fd2 <pipewrite+0x10c>
    80004fa0:	8bbe                	mv	s7,a5
    80004fa2:	bf9d                	j	80004f18 <pipewrite+0x52>
        release(&pi->lock);
    80004fa4:	8526                	mv	a0,s1
    80004fa6:	ffffc097          	auipc	ra,0xffffc
    80004faa:	e96080e7          	jalr	-362(ra) # 80000e3c <release>
        return -1;
    80004fae:	5c7d                	li	s8,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004fb0:	8562                	mv	a0,s8
    80004fb2:	70e6                	ld	ra,120(sp)
    80004fb4:	7446                	ld	s0,112(sp)
    80004fb6:	74a6                	ld	s1,104(sp)
    80004fb8:	7906                	ld	s2,96(sp)
    80004fba:	69e6                	ld	s3,88(sp)
    80004fbc:	6a46                	ld	s4,80(sp)
    80004fbe:	6aa6                	ld	s5,72(sp)
    80004fc0:	6b06                	ld	s6,64(sp)
    80004fc2:	7be2                	ld	s7,56(sp)
    80004fc4:	7c42                	ld	s8,48(sp)
    80004fc6:	7ca2                	ld	s9,40(sp)
    80004fc8:	7d02                	ld	s10,32(sp)
    80004fca:	6de2                	ld	s11,24(sp)
    80004fcc:	6109                	addi	sp,sp,128
    80004fce:	8082                	ret
  for(i = 0; i < n; i++){
    80004fd0:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80004fd2:	22048513          	addi	a0,s1,544
    80004fd6:	ffffd097          	auipc	ra,0xffffd
    80004fda:	774080e7          	jalr	1908(ra) # 8000274a <wakeup>
  release(&pi->lock);
    80004fde:	8526                	mv	a0,s1
    80004fe0:	ffffc097          	auipc	ra,0xffffc
    80004fe4:	e5c080e7          	jalr	-420(ra) # 80000e3c <release>
  return i;
    80004fe8:	b7e1                	j	80004fb0 <pipewrite+0xea>

0000000080004fea <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004fea:	715d                	addi	sp,sp,-80
    80004fec:	e486                	sd	ra,72(sp)
    80004fee:	e0a2                	sd	s0,64(sp)
    80004ff0:	fc26                	sd	s1,56(sp)
    80004ff2:	f84a                	sd	s2,48(sp)
    80004ff4:	f44e                	sd	s3,40(sp)
    80004ff6:	f052                	sd	s4,32(sp)
    80004ff8:	ec56                	sd	s5,24(sp)
    80004ffa:	e85a                	sd	s6,16(sp)
    80004ffc:	0880                	addi	s0,sp,80
    80004ffe:	84aa                	mv	s1,a0
    80005000:	892e                	mv	s2,a1
    80005002:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005004:	ffffd097          	auipc	ra,0xffffd
    80005008:	db0080e7          	jalr	-592(ra) # 80001db4 <myproc>
    8000500c:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000500e:	8b26                	mv	s6,s1
    80005010:	8526                	mv	a0,s1
    80005012:	ffffc097          	auipc	ra,0xffffc
    80005016:	d5a080e7          	jalr	-678(ra) # 80000d6c <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000501a:	2204a703          	lw	a4,544(s1)
    8000501e:	2244a783          	lw	a5,548(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005022:	22048993          	addi	s3,s1,544
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005026:	02f71463          	bne	a4,a5,8000504e <piperead+0x64>
    8000502a:	22c4a783          	lw	a5,556(s1)
    8000502e:	c385                	beqz	a5,8000504e <piperead+0x64>
    if(pr->killed){
    80005030:	038a2783          	lw	a5,56(s4)
    80005034:	ebc1                	bnez	a5,800050c4 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005036:	85da                	mv	a1,s6
    80005038:	854e                	mv	a0,s3
    8000503a:	ffffd097          	auipc	ra,0xffffd
    8000503e:	58a080e7          	jalr	1418(ra) # 800025c4 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005042:	2204a703          	lw	a4,544(s1)
    80005046:	2244a783          	lw	a5,548(s1)
    8000504a:	fef700e3          	beq	a4,a5,8000502a <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000504e:	09505263          	blez	s5,800050d2 <piperead+0xe8>
    80005052:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005054:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80005056:	2204a783          	lw	a5,544(s1)
    8000505a:	2244a703          	lw	a4,548(s1)
    8000505e:	02f70d63          	beq	a4,a5,80005098 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005062:	0017871b          	addiw	a4,a5,1
    80005066:	22e4a023          	sw	a4,544(s1)
    8000506a:	1ff7f793          	andi	a5,a5,511
    8000506e:	97a6                	add	a5,a5,s1
    80005070:	0207c783          	lbu	a5,32(a5)
    80005074:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005078:	4685                	li	a3,1
    8000507a:	fbf40613          	addi	a2,s0,-65
    8000507e:	85ca                	mv	a1,s2
    80005080:	058a3503          	ld	a0,88(s4)
    80005084:	ffffd097          	auipc	ra,0xffffd
    80005088:	a24080e7          	jalr	-1500(ra) # 80001aa8 <copyout>
    8000508c:	01650663          	beq	a0,s6,80005098 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005090:	2985                	addiw	s3,s3,1
    80005092:	0905                	addi	s2,s2,1
    80005094:	fd3a91e3          	bne	s5,s3,80005056 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005098:	22448513          	addi	a0,s1,548
    8000509c:	ffffd097          	auipc	ra,0xffffd
    800050a0:	6ae080e7          	jalr	1710(ra) # 8000274a <wakeup>
  release(&pi->lock);
    800050a4:	8526                	mv	a0,s1
    800050a6:	ffffc097          	auipc	ra,0xffffc
    800050aa:	d96080e7          	jalr	-618(ra) # 80000e3c <release>
  return i;
}
    800050ae:	854e                	mv	a0,s3
    800050b0:	60a6                	ld	ra,72(sp)
    800050b2:	6406                	ld	s0,64(sp)
    800050b4:	74e2                	ld	s1,56(sp)
    800050b6:	7942                	ld	s2,48(sp)
    800050b8:	79a2                	ld	s3,40(sp)
    800050ba:	7a02                	ld	s4,32(sp)
    800050bc:	6ae2                	ld	s5,24(sp)
    800050be:	6b42                	ld	s6,16(sp)
    800050c0:	6161                	addi	sp,sp,80
    800050c2:	8082                	ret
      release(&pi->lock);
    800050c4:	8526                	mv	a0,s1
    800050c6:	ffffc097          	auipc	ra,0xffffc
    800050ca:	d76080e7          	jalr	-650(ra) # 80000e3c <release>
      return -1;
    800050ce:	59fd                	li	s3,-1
    800050d0:	bff9                	j	800050ae <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800050d2:	4981                	li	s3,0
    800050d4:	b7d1                	j	80005098 <piperead+0xae>

00000000800050d6 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800050d6:	df010113          	addi	sp,sp,-528
    800050da:	20113423          	sd	ra,520(sp)
    800050de:	20813023          	sd	s0,512(sp)
    800050e2:	ffa6                	sd	s1,504(sp)
    800050e4:	fbca                	sd	s2,496(sp)
    800050e6:	f7ce                	sd	s3,488(sp)
    800050e8:	f3d2                	sd	s4,480(sp)
    800050ea:	efd6                	sd	s5,472(sp)
    800050ec:	ebda                	sd	s6,464(sp)
    800050ee:	e7de                	sd	s7,456(sp)
    800050f0:	e3e2                	sd	s8,448(sp)
    800050f2:	ff66                	sd	s9,440(sp)
    800050f4:	fb6a                	sd	s10,432(sp)
    800050f6:	f76e                	sd	s11,424(sp)
    800050f8:	0c00                	addi	s0,sp,528
    800050fa:	84aa                	mv	s1,a0
    800050fc:	dea43c23          	sd	a0,-520(s0)
    80005100:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005104:	ffffd097          	auipc	ra,0xffffd
    80005108:	cb0080e7          	jalr	-848(ra) # 80001db4 <myproc>
    8000510c:	892a                	mv	s2,a0

  begin_op();
    8000510e:	fffff097          	auipc	ra,0xfffff
    80005112:	43a080e7          	jalr	1082(ra) # 80004548 <begin_op>

  if((ip = namei(path)) == 0){
    80005116:	8526                	mv	a0,s1
    80005118:	fffff097          	auipc	ra,0xfffff
    8000511c:	214080e7          	jalr	532(ra) # 8000432c <namei>
    80005120:	c92d                	beqz	a0,80005192 <exec+0xbc>
    80005122:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005124:	fffff097          	auipc	ra,0xfffff
    80005128:	a54080e7          	jalr	-1452(ra) # 80003b78 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000512c:	04000713          	li	a4,64
    80005130:	4681                	li	a3,0
    80005132:	e4840613          	addi	a2,s0,-440
    80005136:	4581                	li	a1,0
    80005138:	8526                	mv	a0,s1
    8000513a:	fffff097          	auipc	ra,0xfffff
    8000513e:	cf2080e7          	jalr	-782(ra) # 80003e2c <readi>
    80005142:	04000793          	li	a5,64
    80005146:	00f51a63          	bne	a0,a5,8000515a <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    8000514a:	e4842703          	lw	a4,-440(s0)
    8000514e:	464c47b7          	lui	a5,0x464c4
    80005152:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005156:	04f70463          	beq	a4,a5,8000519e <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000515a:	8526                	mv	a0,s1
    8000515c:	fffff097          	auipc	ra,0xfffff
    80005160:	c7e080e7          	jalr	-898(ra) # 80003dda <iunlockput>
    end_op();
    80005164:	fffff097          	auipc	ra,0xfffff
    80005168:	464080e7          	jalr	1124(ra) # 800045c8 <end_op>
  }
  return -1;
    8000516c:	557d                	li	a0,-1
}
    8000516e:	20813083          	ld	ra,520(sp)
    80005172:	20013403          	ld	s0,512(sp)
    80005176:	74fe                	ld	s1,504(sp)
    80005178:	795e                	ld	s2,496(sp)
    8000517a:	79be                	ld	s3,488(sp)
    8000517c:	7a1e                	ld	s4,480(sp)
    8000517e:	6afe                	ld	s5,472(sp)
    80005180:	6b5e                	ld	s6,464(sp)
    80005182:	6bbe                	ld	s7,456(sp)
    80005184:	6c1e                	ld	s8,448(sp)
    80005186:	7cfa                	ld	s9,440(sp)
    80005188:	7d5a                	ld	s10,432(sp)
    8000518a:	7dba                	ld	s11,424(sp)
    8000518c:	21010113          	addi	sp,sp,528
    80005190:	8082                	ret
    end_op();
    80005192:	fffff097          	auipc	ra,0xfffff
    80005196:	436080e7          	jalr	1078(ra) # 800045c8 <end_op>
    return -1;
    8000519a:	557d                	li	a0,-1
    8000519c:	bfc9                	j	8000516e <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    8000519e:	854a                	mv	a0,s2
    800051a0:	ffffd097          	auipc	ra,0xffffd
    800051a4:	cd8080e7          	jalr	-808(ra) # 80001e78 <proc_pagetable>
    800051a8:	8baa                	mv	s7,a0
    800051aa:	d945                	beqz	a0,8000515a <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051ac:	e6842983          	lw	s3,-408(s0)
    800051b0:	e8045783          	lhu	a5,-384(s0)
    800051b4:	c7ad                	beqz	a5,8000521e <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    800051b6:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051b8:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    800051ba:	6c85                	lui	s9,0x1
    800051bc:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800051c0:	def43823          	sd	a5,-528(s0)
    800051c4:	a42d                	j	800053ee <exec+0x318>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800051c6:	00003517          	auipc	a0,0x3
    800051ca:	5a250513          	addi	a0,a0,1442 # 80008768 <syscalls+0x298>
    800051ce:	ffffb097          	auipc	ra,0xffffb
    800051d2:	382080e7          	jalr	898(ra) # 80000550 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800051d6:	8756                	mv	a4,s5
    800051d8:	012d86bb          	addw	a3,s11,s2
    800051dc:	4581                	li	a1,0
    800051de:	8526                	mv	a0,s1
    800051e0:	fffff097          	auipc	ra,0xfffff
    800051e4:	c4c080e7          	jalr	-948(ra) # 80003e2c <readi>
    800051e8:	2501                	sext.w	a0,a0
    800051ea:	1aaa9963          	bne	s5,a0,8000539c <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    800051ee:	6785                	lui	a5,0x1
    800051f0:	0127893b          	addw	s2,a5,s2
    800051f4:	77fd                	lui	a5,0xfffff
    800051f6:	01478a3b          	addw	s4,a5,s4
    800051fa:	1f897163          	bgeu	s2,s8,800053dc <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    800051fe:	02091593          	slli	a1,s2,0x20
    80005202:	9181                	srli	a1,a1,0x20
    80005204:	95ea                	add	a1,a1,s10
    80005206:	855e                	mv	a0,s7
    80005208:	ffffc097          	auipc	ra,0xffffc
    8000520c:	2de080e7          	jalr	734(ra) # 800014e6 <walkaddr>
    80005210:	862a                	mv	a2,a0
    if(pa == 0)
    80005212:	d955                	beqz	a0,800051c6 <exec+0xf0>
      n = PGSIZE;
    80005214:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005216:	fd9a70e3          	bgeu	s4,s9,800051d6 <exec+0x100>
      n = sz - i;
    8000521a:	8ad2                	mv	s5,s4
    8000521c:	bf6d                	j	800051d6 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    8000521e:	4901                	li	s2,0
  iunlockput(ip);
    80005220:	8526                	mv	a0,s1
    80005222:	fffff097          	auipc	ra,0xfffff
    80005226:	bb8080e7          	jalr	-1096(ra) # 80003dda <iunlockput>
  end_op();
    8000522a:	fffff097          	auipc	ra,0xfffff
    8000522e:	39e080e7          	jalr	926(ra) # 800045c8 <end_op>
  p = myproc();
    80005232:	ffffd097          	auipc	ra,0xffffd
    80005236:	b82080e7          	jalr	-1150(ra) # 80001db4 <myproc>
    8000523a:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    8000523c:	05053d03          	ld	s10,80(a0)
  sz = PGROUNDUP(sz);
    80005240:	6785                	lui	a5,0x1
    80005242:	17fd                	addi	a5,a5,-1
    80005244:	993e                	add	s2,s2,a5
    80005246:	757d                	lui	a0,0xfffff
    80005248:	00a977b3          	and	a5,s2,a0
    8000524c:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005250:	6609                	lui	a2,0x2
    80005252:	963e                	add	a2,a2,a5
    80005254:	85be                	mv	a1,a5
    80005256:	855e                	mv	a0,s7
    80005258:	ffffc097          	auipc	ra,0xffffc
    8000525c:	600080e7          	jalr	1536(ra) # 80001858 <uvmalloc>
    80005260:	8b2a                	mv	s6,a0
  ip = 0;
    80005262:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005264:	12050c63          	beqz	a0,8000539c <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005268:	75f9                	lui	a1,0xffffe
    8000526a:	95aa                	add	a1,a1,a0
    8000526c:	855e                	mv	a0,s7
    8000526e:	ffffd097          	auipc	ra,0xffffd
    80005272:	808080e7          	jalr	-2040(ra) # 80001a76 <uvmclear>
  stackbase = sp - PGSIZE;
    80005276:	7c7d                	lui	s8,0xfffff
    80005278:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    8000527a:	e0043783          	ld	a5,-512(s0)
    8000527e:	6388                	ld	a0,0(a5)
    80005280:	c535                	beqz	a0,800052ec <exec+0x216>
    80005282:	e8840993          	addi	s3,s0,-376
    80005286:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    8000528a:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    8000528c:	ffffc097          	auipc	ra,0xffffc
    80005290:	048080e7          	jalr	72(ra) # 800012d4 <strlen>
    80005294:	2505                	addiw	a0,a0,1
    80005296:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000529a:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    8000529e:	13896363          	bltu	s2,s8,800053c4 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800052a2:	e0043d83          	ld	s11,-512(s0)
    800052a6:	000dba03          	ld	s4,0(s11)
    800052aa:	8552                	mv	a0,s4
    800052ac:	ffffc097          	auipc	ra,0xffffc
    800052b0:	028080e7          	jalr	40(ra) # 800012d4 <strlen>
    800052b4:	0015069b          	addiw	a3,a0,1
    800052b8:	8652                	mv	a2,s4
    800052ba:	85ca                	mv	a1,s2
    800052bc:	855e                	mv	a0,s7
    800052be:	ffffc097          	auipc	ra,0xffffc
    800052c2:	7ea080e7          	jalr	2026(ra) # 80001aa8 <copyout>
    800052c6:	10054363          	bltz	a0,800053cc <exec+0x2f6>
    ustack[argc] = sp;
    800052ca:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800052ce:	0485                	addi	s1,s1,1
    800052d0:	008d8793          	addi	a5,s11,8
    800052d4:	e0f43023          	sd	a5,-512(s0)
    800052d8:	008db503          	ld	a0,8(s11)
    800052dc:	c911                	beqz	a0,800052f0 <exec+0x21a>
    if(argc >= MAXARG)
    800052de:	09a1                	addi	s3,s3,8
    800052e0:	fb3c96e3          	bne	s9,s3,8000528c <exec+0x1b6>
  sz = sz1;
    800052e4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800052e8:	4481                	li	s1,0
    800052ea:	a84d                	j	8000539c <exec+0x2c6>
  sp = sz;
    800052ec:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800052ee:	4481                	li	s1,0
  ustack[argc] = 0;
    800052f0:	00349793          	slli	a5,s1,0x3
    800052f4:	f9040713          	addi	a4,s0,-112
    800052f8:	97ba                	add	a5,a5,a4
    800052fa:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    800052fe:	00148693          	addi	a3,s1,1
    80005302:	068e                	slli	a3,a3,0x3
    80005304:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005308:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000530c:	01897663          	bgeu	s2,s8,80005318 <exec+0x242>
  sz = sz1;
    80005310:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005314:	4481                	li	s1,0
    80005316:	a059                	j	8000539c <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005318:	e8840613          	addi	a2,s0,-376
    8000531c:	85ca                	mv	a1,s2
    8000531e:	855e                	mv	a0,s7
    80005320:	ffffc097          	auipc	ra,0xffffc
    80005324:	788080e7          	jalr	1928(ra) # 80001aa8 <copyout>
    80005328:	0a054663          	bltz	a0,800053d4 <exec+0x2fe>
  p->trapframe->a1 = sp;
    8000532c:	060ab783          	ld	a5,96(s5)
    80005330:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005334:	df843783          	ld	a5,-520(s0)
    80005338:	0007c703          	lbu	a4,0(a5)
    8000533c:	cf11                	beqz	a4,80005358 <exec+0x282>
    8000533e:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005340:	02f00693          	li	a3,47
    80005344:	a029                	j	8000534e <exec+0x278>
  for(last=s=path; *s; s++)
    80005346:	0785                	addi	a5,a5,1
    80005348:	fff7c703          	lbu	a4,-1(a5)
    8000534c:	c711                	beqz	a4,80005358 <exec+0x282>
    if(*s == '/')
    8000534e:	fed71ce3          	bne	a4,a3,80005346 <exec+0x270>
      last = s+1;
    80005352:	def43c23          	sd	a5,-520(s0)
    80005356:	bfc5                	j	80005346 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005358:	4641                	li	a2,16
    8000535a:	df843583          	ld	a1,-520(s0)
    8000535e:	160a8513          	addi	a0,s5,352
    80005362:	ffffc097          	auipc	ra,0xffffc
    80005366:	f40080e7          	jalr	-192(ra) # 800012a2 <safestrcpy>
  oldpagetable = p->pagetable;
    8000536a:	058ab503          	ld	a0,88(s5)
  p->pagetable = pagetable;
    8000536e:	057abc23          	sd	s7,88(s5)
  p->sz = sz;
    80005372:	056ab823          	sd	s6,80(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005376:	060ab783          	ld	a5,96(s5)
    8000537a:	e6043703          	ld	a4,-416(s0)
    8000537e:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005380:	060ab783          	ld	a5,96(s5)
    80005384:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005388:	85ea                	mv	a1,s10
    8000538a:	ffffd097          	auipc	ra,0xffffd
    8000538e:	b8a080e7          	jalr	-1142(ra) # 80001f14 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005392:	0004851b          	sext.w	a0,s1
    80005396:	bbe1                	j	8000516e <exec+0x98>
    80005398:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    8000539c:	e0843583          	ld	a1,-504(s0)
    800053a0:	855e                	mv	a0,s7
    800053a2:	ffffd097          	auipc	ra,0xffffd
    800053a6:	b72080e7          	jalr	-1166(ra) # 80001f14 <proc_freepagetable>
  if(ip){
    800053aa:	da0498e3          	bnez	s1,8000515a <exec+0x84>
  return -1;
    800053ae:	557d                	li	a0,-1
    800053b0:	bb7d                	j	8000516e <exec+0x98>
    800053b2:	e1243423          	sd	s2,-504(s0)
    800053b6:	b7dd                	j	8000539c <exec+0x2c6>
    800053b8:	e1243423          	sd	s2,-504(s0)
    800053bc:	b7c5                	j	8000539c <exec+0x2c6>
    800053be:	e1243423          	sd	s2,-504(s0)
    800053c2:	bfe9                	j	8000539c <exec+0x2c6>
  sz = sz1;
    800053c4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800053c8:	4481                	li	s1,0
    800053ca:	bfc9                	j	8000539c <exec+0x2c6>
  sz = sz1;
    800053cc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800053d0:	4481                	li	s1,0
    800053d2:	b7e9                	j	8000539c <exec+0x2c6>
  sz = sz1;
    800053d4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800053d8:	4481                	li	s1,0
    800053da:	b7c9                	j	8000539c <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800053dc:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053e0:	2b05                	addiw	s6,s6,1
    800053e2:	0389899b          	addiw	s3,s3,56
    800053e6:	e8045783          	lhu	a5,-384(s0)
    800053ea:	e2fb5be3          	bge	s6,a5,80005220 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800053ee:	2981                	sext.w	s3,s3
    800053f0:	03800713          	li	a4,56
    800053f4:	86ce                	mv	a3,s3
    800053f6:	e1040613          	addi	a2,s0,-496
    800053fa:	4581                	li	a1,0
    800053fc:	8526                	mv	a0,s1
    800053fe:	fffff097          	auipc	ra,0xfffff
    80005402:	a2e080e7          	jalr	-1490(ra) # 80003e2c <readi>
    80005406:	03800793          	li	a5,56
    8000540a:	f8f517e3          	bne	a0,a5,80005398 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    8000540e:	e1042783          	lw	a5,-496(s0)
    80005412:	4705                	li	a4,1
    80005414:	fce796e3          	bne	a5,a4,800053e0 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005418:	e3843603          	ld	a2,-456(s0)
    8000541c:	e3043783          	ld	a5,-464(s0)
    80005420:	f8f669e3          	bltu	a2,a5,800053b2 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005424:	e2043783          	ld	a5,-480(s0)
    80005428:	963e                	add	a2,a2,a5
    8000542a:	f8f667e3          	bltu	a2,a5,800053b8 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000542e:	85ca                	mv	a1,s2
    80005430:	855e                	mv	a0,s7
    80005432:	ffffc097          	auipc	ra,0xffffc
    80005436:	426080e7          	jalr	1062(ra) # 80001858 <uvmalloc>
    8000543a:	e0a43423          	sd	a0,-504(s0)
    8000543e:	d141                	beqz	a0,800053be <exec+0x2e8>
    if(ph.vaddr % PGSIZE != 0)
    80005440:	e2043d03          	ld	s10,-480(s0)
    80005444:	df043783          	ld	a5,-528(s0)
    80005448:	00fd77b3          	and	a5,s10,a5
    8000544c:	fba1                	bnez	a5,8000539c <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000544e:	e1842d83          	lw	s11,-488(s0)
    80005452:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005456:	f80c03e3          	beqz	s8,800053dc <exec+0x306>
    8000545a:	8a62                	mv	s4,s8
    8000545c:	4901                	li	s2,0
    8000545e:	b345                	j	800051fe <exec+0x128>

0000000080005460 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005460:	7179                	addi	sp,sp,-48
    80005462:	f406                	sd	ra,40(sp)
    80005464:	f022                	sd	s0,32(sp)
    80005466:	ec26                	sd	s1,24(sp)
    80005468:	e84a                	sd	s2,16(sp)
    8000546a:	1800                	addi	s0,sp,48
    8000546c:	892e                	mv	s2,a1
    8000546e:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005470:	fdc40593          	addi	a1,s0,-36
    80005474:	ffffe097          	auipc	ra,0xffffe
    80005478:	9fe080e7          	jalr	-1538(ra) # 80002e72 <argint>
    8000547c:	04054063          	bltz	a0,800054bc <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005480:	fdc42703          	lw	a4,-36(s0)
    80005484:	47bd                	li	a5,15
    80005486:	02e7ed63          	bltu	a5,a4,800054c0 <argfd+0x60>
    8000548a:	ffffd097          	auipc	ra,0xffffd
    8000548e:	92a080e7          	jalr	-1750(ra) # 80001db4 <myproc>
    80005492:	fdc42703          	lw	a4,-36(s0)
    80005496:	01a70793          	addi	a5,a4,26
    8000549a:	078e                	slli	a5,a5,0x3
    8000549c:	953e                	add	a0,a0,a5
    8000549e:	651c                	ld	a5,8(a0)
    800054a0:	c395                	beqz	a5,800054c4 <argfd+0x64>
    return -1;
  if(pfd)
    800054a2:	00090463          	beqz	s2,800054aa <argfd+0x4a>
    *pfd = fd;
    800054a6:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800054aa:	4501                	li	a0,0
  if(pf)
    800054ac:	c091                	beqz	s1,800054b0 <argfd+0x50>
    *pf = f;
    800054ae:	e09c                	sd	a5,0(s1)
}
    800054b0:	70a2                	ld	ra,40(sp)
    800054b2:	7402                	ld	s0,32(sp)
    800054b4:	64e2                	ld	s1,24(sp)
    800054b6:	6942                	ld	s2,16(sp)
    800054b8:	6145                	addi	sp,sp,48
    800054ba:	8082                	ret
    return -1;
    800054bc:	557d                	li	a0,-1
    800054be:	bfcd                	j	800054b0 <argfd+0x50>
    return -1;
    800054c0:	557d                	li	a0,-1
    800054c2:	b7fd                	j	800054b0 <argfd+0x50>
    800054c4:	557d                	li	a0,-1
    800054c6:	b7ed                	j	800054b0 <argfd+0x50>

00000000800054c8 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800054c8:	1101                	addi	sp,sp,-32
    800054ca:	ec06                	sd	ra,24(sp)
    800054cc:	e822                	sd	s0,16(sp)
    800054ce:	e426                	sd	s1,8(sp)
    800054d0:	1000                	addi	s0,sp,32
    800054d2:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800054d4:	ffffd097          	auipc	ra,0xffffd
    800054d8:	8e0080e7          	jalr	-1824(ra) # 80001db4 <myproc>
    800054dc:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800054de:	0d850793          	addi	a5,a0,216 # fffffffffffff0d8 <end+0xffffffff7ffd30b0>
    800054e2:	4501                	li	a0,0
    800054e4:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800054e6:	6398                	ld	a4,0(a5)
    800054e8:	cb19                	beqz	a4,800054fe <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800054ea:	2505                	addiw	a0,a0,1
    800054ec:	07a1                	addi	a5,a5,8
    800054ee:	fed51ce3          	bne	a0,a3,800054e6 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800054f2:	557d                	li	a0,-1
}
    800054f4:	60e2                	ld	ra,24(sp)
    800054f6:	6442                	ld	s0,16(sp)
    800054f8:	64a2                	ld	s1,8(sp)
    800054fa:	6105                	addi	sp,sp,32
    800054fc:	8082                	ret
      p->ofile[fd] = f;
    800054fe:	01a50793          	addi	a5,a0,26
    80005502:	078e                	slli	a5,a5,0x3
    80005504:	963e                	add	a2,a2,a5
    80005506:	e604                	sd	s1,8(a2)
      return fd;
    80005508:	b7f5                	j	800054f4 <fdalloc+0x2c>

000000008000550a <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000550a:	715d                	addi	sp,sp,-80
    8000550c:	e486                	sd	ra,72(sp)
    8000550e:	e0a2                	sd	s0,64(sp)
    80005510:	fc26                	sd	s1,56(sp)
    80005512:	f84a                	sd	s2,48(sp)
    80005514:	f44e                	sd	s3,40(sp)
    80005516:	f052                	sd	s4,32(sp)
    80005518:	ec56                	sd	s5,24(sp)
    8000551a:	0880                	addi	s0,sp,80
    8000551c:	89ae                	mv	s3,a1
    8000551e:	8ab2                	mv	s5,a2
    80005520:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005522:	fb040593          	addi	a1,s0,-80
    80005526:	fffff097          	auipc	ra,0xfffff
    8000552a:	e24080e7          	jalr	-476(ra) # 8000434a <nameiparent>
    8000552e:	892a                	mv	s2,a0
    80005530:	12050f63          	beqz	a0,8000566e <create+0x164>
    return 0;

  ilock(dp);
    80005534:	ffffe097          	auipc	ra,0xffffe
    80005538:	644080e7          	jalr	1604(ra) # 80003b78 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000553c:	4601                	li	a2,0
    8000553e:	fb040593          	addi	a1,s0,-80
    80005542:	854a                	mv	a0,s2
    80005544:	fffff097          	auipc	ra,0xfffff
    80005548:	b16080e7          	jalr	-1258(ra) # 8000405a <dirlookup>
    8000554c:	84aa                	mv	s1,a0
    8000554e:	c921                	beqz	a0,8000559e <create+0x94>
    iunlockput(dp);
    80005550:	854a                	mv	a0,s2
    80005552:	fffff097          	auipc	ra,0xfffff
    80005556:	888080e7          	jalr	-1912(ra) # 80003dda <iunlockput>
    ilock(ip);
    8000555a:	8526                	mv	a0,s1
    8000555c:	ffffe097          	auipc	ra,0xffffe
    80005560:	61c080e7          	jalr	1564(ra) # 80003b78 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005564:	2981                	sext.w	s3,s3
    80005566:	4789                	li	a5,2
    80005568:	02f99463          	bne	s3,a5,80005590 <create+0x86>
    8000556c:	04c4d783          	lhu	a5,76(s1)
    80005570:	37f9                	addiw	a5,a5,-2
    80005572:	17c2                	slli	a5,a5,0x30
    80005574:	93c1                	srli	a5,a5,0x30
    80005576:	4705                	li	a4,1
    80005578:	00f76c63          	bltu	a4,a5,80005590 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000557c:	8526                	mv	a0,s1
    8000557e:	60a6                	ld	ra,72(sp)
    80005580:	6406                	ld	s0,64(sp)
    80005582:	74e2                	ld	s1,56(sp)
    80005584:	7942                	ld	s2,48(sp)
    80005586:	79a2                	ld	s3,40(sp)
    80005588:	7a02                	ld	s4,32(sp)
    8000558a:	6ae2                	ld	s5,24(sp)
    8000558c:	6161                	addi	sp,sp,80
    8000558e:	8082                	ret
    iunlockput(ip);
    80005590:	8526                	mv	a0,s1
    80005592:	fffff097          	auipc	ra,0xfffff
    80005596:	848080e7          	jalr	-1976(ra) # 80003dda <iunlockput>
    return 0;
    8000559a:	4481                	li	s1,0
    8000559c:	b7c5                	j	8000557c <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000559e:	85ce                	mv	a1,s3
    800055a0:	00092503          	lw	a0,0(s2)
    800055a4:	ffffe097          	auipc	ra,0xffffe
    800055a8:	43c080e7          	jalr	1084(ra) # 800039e0 <ialloc>
    800055ac:	84aa                	mv	s1,a0
    800055ae:	c529                	beqz	a0,800055f8 <create+0xee>
  ilock(ip);
    800055b0:	ffffe097          	auipc	ra,0xffffe
    800055b4:	5c8080e7          	jalr	1480(ra) # 80003b78 <ilock>
  ip->major = major;
    800055b8:	05549723          	sh	s5,78(s1)
  ip->minor = minor;
    800055bc:	05449823          	sh	s4,80(s1)
  ip->nlink = 1;
    800055c0:	4785                	li	a5,1
    800055c2:	04f49923          	sh	a5,82(s1)
  iupdate(ip);
    800055c6:	8526                	mv	a0,s1
    800055c8:	ffffe097          	auipc	ra,0xffffe
    800055cc:	4e6080e7          	jalr	1254(ra) # 80003aae <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800055d0:	2981                	sext.w	s3,s3
    800055d2:	4785                	li	a5,1
    800055d4:	02f98a63          	beq	s3,a5,80005608 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800055d8:	40d0                	lw	a2,4(s1)
    800055da:	fb040593          	addi	a1,s0,-80
    800055de:	854a                	mv	a0,s2
    800055e0:	fffff097          	auipc	ra,0xfffff
    800055e4:	c8a080e7          	jalr	-886(ra) # 8000426a <dirlink>
    800055e8:	06054b63          	bltz	a0,8000565e <create+0x154>
  iunlockput(dp);
    800055ec:	854a                	mv	a0,s2
    800055ee:	ffffe097          	auipc	ra,0xffffe
    800055f2:	7ec080e7          	jalr	2028(ra) # 80003dda <iunlockput>
  return ip;
    800055f6:	b759                	j	8000557c <create+0x72>
    panic("create: ialloc");
    800055f8:	00003517          	auipc	a0,0x3
    800055fc:	19050513          	addi	a0,a0,400 # 80008788 <syscalls+0x2b8>
    80005600:	ffffb097          	auipc	ra,0xffffb
    80005604:	f50080e7          	jalr	-176(ra) # 80000550 <panic>
    dp->nlink++;  // for ".."
    80005608:	05295783          	lhu	a5,82(s2)
    8000560c:	2785                	addiw	a5,a5,1
    8000560e:	04f91923          	sh	a5,82(s2)
    iupdate(dp);
    80005612:	854a                	mv	a0,s2
    80005614:	ffffe097          	auipc	ra,0xffffe
    80005618:	49a080e7          	jalr	1178(ra) # 80003aae <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000561c:	40d0                	lw	a2,4(s1)
    8000561e:	00003597          	auipc	a1,0x3
    80005622:	17a58593          	addi	a1,a1,378 # 80008798 <syscalls+0x2c8>
    80005626:	8526                	mv	a0,s1
    80005628:	fffff097          	auipc	ra,0xfffff
    8000562c:	c42080e7          	jalr	-958(ra) # 8000426a <dirlink>
    80005630:	00054f63          	bltz	a0,8000564e <create+0x144>
    80005634:	00492603          	lw	a2,4(s2)
    80005638:	00003597          	auipc	a1,0x3
    8000563c:	16858593          	addi	a1,a1,360 # 800087a0 <syscalls+0x2d0>
    80005640:	8526                	mv	a0,s1
    80005642:	fffff097          	auipc	ra,0xfffff
    80005646:	c28080e7          	jalr	-984(ra) # 8000426a <dirlink>
    8000564a:	f80557e3          	bgez	a0,800055d8 <create+0xce>
      panic("create dots");
    8000564e:	00003517          	auipc	a0,0x3
    80005652:	15a50513          	addi	a0,a0,346 # 800087a8 <syscalls+0x2d8>
    80005656:	ffffb097          	auipc	ra,0xffffb
    8000565a:	efa080e7          	jalr	-262(ra) # 80000550 <panic>
    panic("create: dirlink");
    8000565e:	00003517          	auipc	a0,0x3
    80005662:	15a50513          	addi	a0,a0,346 # 800087b8 <syscalls+0x2e8>
    80005666:	ffffb097          	auipc	ra,0xffffb
    8000566a:	eea080e7          	jalr	-278(ra) # 80000550 <panic>
    return 0;
    8000566e:	84aa                	mv	s1,a0
    80005670:	b731                	j	8000557c <create+0x72>

0000000080005672 <sys_dup>:
{
    80005672:	7179                	addi	sp,sp,-48
    80005674:	f406                	sd	ra,40(sp)
    80005676:	f022                	sd	s0,32(sp)
    80005678:	ec26                	sd	s1,24(sp)
    8000567a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000567c:	fd840613          	addi	a2,s0,-40
    80005680:	4581                	li	a1,0
    80005682:	4501                	li	a0,0
    80005684:	00000097          	auipc	ra,0x0
    80005688:	ddc080e7          	jalr	-548(ra) # 80005460 <argfd>
    return -1;
    8000568c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000568e:	02054363          	bltz	a0,800056b4 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005692:	fd843503          	ld	a0,-40(s0)
    80005696:	00000097          	auipc	ra,0x0
    8000569a:	e32080e7          	jalr	-462(ra) # 800054c8 <fdalloc>
    8000569e:	84aa                	mv	s1,a0
    return -1;
    800056a0:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800056a2:	00054963          	bltz	a0,800056b4 <sys_dup+0x42>
  filedup(f);
    800056a6:	fd843503          	ld	a0,-40(s0)
    800056aa:	fffff097          	auipc	ra,0xfffff
    800056ae:	320080e7          	jalr	800(ra) # 800049ca <filedup>
  return fd;
    800056b2:	87a6                	mv	a5,s1
}
    800056b4:	853e                	mv	a0,a5
    800056b6:	70a2                	ld	ra,40(sp)
    800056b8:	7402                	ld	s0,32(sp)
    800056ba:	64e2                	ld	s1,24(sp)
    800056bc:	6145                	addi	sp,sp,48
    800056be:	8082                	ret

00000000800056c0 <sys_read>:
{
    800056c0:	7179                	addi	sp,sp,-48
    800056c2:	f406                	sd	ra,40(sp)
    800056c4:	f022                	sd	s0,32(sp)
    800056c6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056c8:	fe840613          	addi	a2,s0,-24
    800056cc:	4581                	li	a1,0
    800056ce:	4501                	li	a0,0
    800056d0:	00000097          	auipc	ra,0x0
    800056d4:	d90080e7          	jalr	-624(ra) # 80005460 <argfd>
    return -1;
    800056d8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056da:	04054163          	bltz	a0,8000571c <sys_read+0x5c>
    800056de:	fe440593          	addi	a1,s0,-28
    800056e2:	4509                	li	a0,2
    800056e4:	ffffd097          	auipc	ra,0xffffd
    800056e8:	78e080e7          	jalr	1934(ra) # 80002e72 <argint>
    return -1;
    800056ec:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056ee:	02054763          	bltz	a0,8000571c <sys_read+0x5c>
    800056f2:	fd840593          	addi	a1,s0,-40
    800056f6:	4505                	li	a0,1
    800056f8:	ffffd097          	auipc	ra,0xffffd
    800056fc:	79c080e7          	jalr	1948(ra) # 80002e94 <argaddr>
    return -1;
    80005700:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005702:	00054d63          	bltz	a0,8000571c <sys_read+0x5c>
  return fileread(f, p, n);
    80005706:	fe442603          	lw	a2,-28(s0)
    8000570a:	fd843583          	ld	a1,-40(s0)
    8000570e:	fe843503          	ld	a0,-24(s0)
    80005712:	fffff097          	auipc	ra,0xfffff
    80005716:	444080e7          	jalr	1092(ra) # 80004b56 <fileread>
    8000571a:	87aa                	mv	a5,a0
}
    8000571c:	853e                	mv	a0,a5
    8000571e:	70a2                	ld	ra,40(sp)
    80005720:	7402                	ld	s0,32(sp)
    80005722:	6145                	addi	sp,sp,48
    80005724:	8082                	ret

0000000080005726 <sys_write>:
{
    80005726:	7179                	addi	sp,sp,-48
    80005728:	f406                	sd	ra,40(sp)
    8000572a:	f022                	sd	s0,32(sp)
    8000572c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000572e:	fe840613          	addi	a2,s0,-24
    80005732:	4581                	li	a1,0
    80005734:	4501                	li	a0,0
    80005736:	00000097          	auipc	ra,0x0
    8000573a:	d2a080e7          	jalr	-726(ra) # 80005460 <argfd>
    return -1;
    8000573e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005740:	04054163          	bltz	a0,80005782 <sys_write+0x5c>
    80005744:	fe440593          	addi	a1,s0,-28
    80005748:	4509                	li	a0,2
    8000574a:	ffffd097          	auipc	ra,0xffffd
    8000574e:	728080e7          	jalr	1832(ra) # 80002e72 <argint>
    return -1;
    80005752:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005754:	02054763          	bltz	a0,80005782 <sys_write+0x5c>
    80005758:	fd840593          	addi	a1,s0,-40
    8000575c:	4505                	li	a0,1
    8000575e:	ffffd097          	auipc	ra,0xffffd
    80005762:	736080e7          	jalr	1846(ra) # 80002e94 <argaddr>
    return -1;
    80005766:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005768:	00054d63          	bltz	a0,80005782 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000576c:	fe442603          	lw	a2,-28(s0)
    80005770:	fd843583          	ld	a1,-40(s0)
    80005774:	fe843503          	ld	a0,-24(s0)
    80005778:	fffff097          	auipc	ra,0xfffff
    8000577c:	4a0080e7          	jalr	1184(ra) # 80004c18 <filewrite>
    80005780:	87aa                	mv	a5,a0
}
    80005782:	853e                	mv	a0,a5
    80005784:	70a2                	ld	ra,40(sp)
    80005786:	7402                	ld	s0,32(sp)
    80005788:	6145                	addi	sp,sp,48
    8000578a:	8082                	ret

000000008000578c <sys_close>:
{
    8000578c:	1101                	addi	sp,sp,-32
    8000578e:	ec06                	sd	ra,24(sp)
    80005790:	e822                	sd	s0,16(sp)
    80005792:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005794:	fe040613          	addi	a2,s0,-32
    80005798:	fec40593          	addi	a1,s0,-20
    8000579c:	4501                	li	a0,0
    8000579e:	00000097          	auipc	ra,0x0
    800057a2:	cc2080e7          	jalr	-830(ra) # 80005460 <argfd>
    return -1;
    800057a6:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800057a8:	02054463          	bltz	a0,800057d0 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800057ac:	ffffc097          	auipc	ra,0xffffc
    800057b0:	608080e7          	jalr	1544(ra) # 80001db4 <myproc>
    800057b4:	fec42783          	lw	a5,-20(s0)
    800057b8:	07e9                	addi	a5,a5,26
    800057ba:	078e                	slli	a5,a5,0x3
    800057bc:	97aa                	add	a5,a5,a0
    800057be:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    800057c2:	fe043503          	ld	a0,-32(s0)
    800057c6:	fffff097          	auipc	ra,0xfffff
    800057ca:	256080e7          	jalr	598(ra) # 80004a1c <fileclose>
  return 0;
    800057ce:	4781                	li	a5,0
}
    800057d0:	853e                	mv	a0,a5
    800057d2:	60e2                	ld	ra,24(sp)
    800057d4:	6442                	ld	s0,16(sp)
    800057d6:	6105                	addi	sp,sp,32
    800057d8:	8082                	ret

00000000800057da <sys_fstat>:
{
    800057da:	1101                	addi	sp,sp,-32
    800057dc:	ec06                	sd	ra,24(sp)
    800057de:	e822                	sd	s0,16(sp)
    800057e0:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800057e2:	fe840613          	addi	a2,s0,-24
    800057e6:	4581                	li	a1,0
    800057e8:	4501                	li	a0,0
    800057ea:	00000097          	auipc	ra,0x0
    800057ee:	c76080e7          	jalr	-906(ra) # 80005460 <argfd>
    return -1;
    800057f2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800057f4:	02054563          	bltz	a0,8000581e <sys_fstat+0x44>
    800057f8:	fe040593          	addi	a1,s0,-32
    800057fc:	4505                	li	a0,1
    800057fe:	ffffd097          	auipc	ra,0xffffd
    80005802:	696080e7          	jalr	1686(ra) # 80002e94 <argaddr>
    return -1;
    80005806:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005808:	00054b63          	bltz	a0,8000581e <sys_fstat+0x44>
  return filestat(f, st);
    8000580c:	fe043583          	ld	a1,-32(s0)
    80005810:	fe843503          	ld	a0,-24(s0)
    80005814:	fffff097          	auipc	ra,0xfffff
    80005818:	2d0080e7          	jalr	720(ra) # 80004ae4 <filestat>
    8000581c:	87aa                	mv	a5,a0
}
    8000581e:	853e                	mv	a0,a5
    80005820:	60e2                	ld	ra,24(sp)
    80005822:	6442                	ld	s0,16(sp)
    80005824:	6105                	addi	sp,sp,32
    80005826:	8082                	ret

0000000080005828 <sys_link>:
{
    80005828:	7169                	addi	sp,sp,-304
    8000582a:	f606                	sd	ra,296(sp)
    8000582c:	f222                	sd	s0,288(sp)
    8000582e:	ee26                	sd	s1,280(sp)
    80005830:	ea4a                	sd	s2,272(sp)
    80005832:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005834:	08000613          	li	a2,128
    80005838:	ed040593          	addi	a1,s0,-304
    8000583c:	4501                	li	a0,0
    8000583e:	ffffd097          	auipc	ra,0xffffd
    80005842:	678080e7          	jalr	1656(ra) # 80002eb6 <argstr>
    return -1;
    80005846:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005848:	10054e63          	bltz	a0,80005964 <sys_link+0x13c>
    8000584c:	08000613          	li	a2,128
    80005850:	f5040593          	addi	a1,s0,-176
    80005854:	4505                	li	a0,1
    80005856:	ffffd097          	auipc	ra,0xffffd
    8000585a:	660080e7          	jalr	1632(ra) # 80002eb6 <argstr>
    return -1;
    8000585e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005860:	10054263          	bltz	a0,80005964 <sys_link+0x13c>
  begin_op();
    80005864:	fffff097          	auipc	ra,0xfffff
    80005868:	ce4080e7          	jalr	-796(ra) # 80004548 <begin_op>
  if((ip = namei(old)) == 0){
    8000586c:	ed040513          	addi	a0,s0,-304
    80005870:	fffff097          	auipc	ra,0xfffff
    80005874:	abc080e7          	jalr	-1348(ra) # 8000432c <namei>
    80005878:	84aa                	mv	s1,a0
    8000587a:	c551                	beqz	a0,80005906 <sys_link+0xde>
  ilock(ip);
    8000587c:	ffffe097          	auipc	ra,0xffffe
    80005880:	2fc080e7          	jalr	764(ra) # 80003b78 <ilock>
  if(ip->type == T_DIR){
    80005884:	04c49703          	lh	a4,76(s1)
    80005888:	4785                	li	a5,1
    8000588a:	08f70463          	beq	a4,a5,80005912 <sys_link+0xea>
  ip->nlink++;
    8000588e:	0524d783          	lhu	a5,82(s1)
    80005892:	2785                	addiw	a5,a5,1
    80005894:	04f49923          	sh	a5,82(s1)
  iupdate(ip);
    80005898:	8526                	mv	a0,s1
    8000589a:	ffffe097          	auipc	ra,0xffffe
    8000589e:	214080e7          	jalr	532(ra) # 80003aae <iupdate>
  iunlock(ip);
    800058a2:	8526                	mv	a0,s1
    800058a4:	ffffe097          	auipc	ra,0xffffe
    800058a8:	396080e7          	jalr	918(ra) # 80003c3a <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800058ac:	fd040593          	addi	a1,s0,-48
    800058b0:	f5040513          	addi	a0,s0,-176
    800058b4:	fffff097          	auipc	ra,0xfffff
    800058b8:	a96080e7          	jalr	-1386(ra) # 8000434a <nameiparent>
    800058bc:	892a                	mv	s2,a0
    800058be:	c935                	beqz	a0,80005932 <sys_link+0x10a>
  ilock(dp);
    800058c0:	ffffe097          	auipc	ra,0xffffe
    800058c4:	2b8080e7          	jalr	696(ra) # 80003b78 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800058c8:	00092703          	lw	a4,0(s2)
    800058cc:	409c                	lw	a5,0(s1)
    800058ce:	04f71d63          	bne	a4,a5,80005928 <sys_link+0x100>
    800058d2:	40d0                	lw	a2,4(s1)
    800058d4:	fd040593          	addi	a1,s0,-48
    800058d8:	854a                	mv	a0,s2
    800058da:	fffff097          	auipc	ra,0xfffff
    800058de:	990080e7          	jalr	-1648(ra) # 8000426a <dirlink>
    800058e2:	04054363          	bltz	a0,80005928 <sys_link+0x100>
  iunlockput(dp);
    800058e6:	854a                	mv	a0,s2
    800058e8:	ffffe097          	auipc	ra,0xffffe
    800058ec:	4f2080e7          	jalr	1266(ra) # 80003dda <iunlockput>
  iput(ip);
    800058f0:	8526                	mv	a0,s1
    800058f2:	ffffe097          	auipc	ra,0xffffe
    800058f6:	440080e7          	jalr	1088(ra) # 80003d32 <iput>
  end_op();
    800058fa:	fffff097          	auipc	ra,0xfffff
    800058fe:	cce080e7          	jalr	-818(ra) # 800045c8 <end_op>
  return 0;
    80005902:	4781                	li	a5,0
    80005904:	a085                	j	80005964 <sys_link+0x13c>
    end_op();
    80005906:	fffff097          	auipc	ra,0xfffff
    8000590a:	cc2080e7          	jalr	-830(ra) # 800045c8 <end_op>
    return -1;
    8000590e:	57fd                	li	a5,-1
    80005910:	a891                	j	80005964 <sys_link+0x13c>
    iunlockput(ip);
    80005912:	8526                	mv	a0,s1
    80005914:	ffffe097          	auipc	ra,0xffffe
    80005918:	4c6080e7          	jalr	1222(ra) # 80003dda <iunlockput>
    end_op();
    8000591c:	fffff097          	auipc	ra,0xfffff
    80005920:	cac080e7          	jalr	-852(ra) # 800045c8 <end_op>
    return -1;
    80005924:	57fd                	li	a5,-1
    80005926:	a83d                	j	80005964 <sys_link+0x13c>
    iunlockput(dp);
    80005928:	854a                	mv	a0,s2
    8000592a:	ffffe097          	auipc	ra,0xffffe
    8000592e:	4b0080e7          	jalr	1200(ra) # 80003dda <iunlockput>
  ilock(ip);
    80005932:	8526                	mv	a0,s1
    80005934:	ffffe097          	auipc	ra,0xffffe
    80005938:	244080e7          	jalr	580(ra) # 80003b78 <ilock>
  ip->nlink--;
    8000593c:	0524d783          	lhu	a5,82(s1)
    80005940:	37fd                	addiw	a5,a5,-1
    80005942:	04f49923          	sh	a5,82(s1)
  iupdate(ip);
    80005946:	8526                	mv	a0,s1
    80005948:	ffffe097          	auipc	ra,0xffffe
    8000594c:	166080e7          	jalr	358(ra) # 80003aae <iupdate>
  iunlockput(ip);
    80005950:	8526                	mv	a0,s1
    80005952:	ffffe097          	auipc	ra,0xffffe
    80005956:	488080e7          	jalr	1160(ra) # 80003dda <iunlockput>
  end_op();
    8000595a:	fffff097          	auipc	ra,0xfffff
    8000595e:	c6e080e7          	jalr	-914(ra) # 800045c8 <end_op>
  return -1;
    80005962:	57fd                	li	a5,-1
}
    80005964:	853e                	mv	a0,a5
    80005966:	70b2                	ld	ra,296(sp)
    80005968:	7412                	ld	s0,288(sp)
    8000596a:	64f2                	ld	s1,280(sp)
    8000596c:	6952                	ld	s2,272(sp)
    8000596e:	6155                	addi	sp,sp,304
    80005970:	8082                	ret

0000000080005972 <sys_unlink>:
{
    80005972:	7151                	addi	sp,sp,-240
    80005974:	f586                	sd	ra,232(sp)
    80005976:	f1a2                	sd	s0,224(sp)
    80005978:	eda6                	sd	s1,216(sp)
    8000597a:	e9ca                	sd	s2,208(sp)
    8000597c:	e5ce                	sd	s3,200(sp)
    8000597e:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005980:	08000613          	li	a2,128
    80005984:	f3040593          	addi	a1,s0,-208
    80005988:	4501                	li	a0,0
    8000598a:	ffffd097          	auipc	ra,0xffffd
    8000598e:	52c080e7          	jalr	1324(ra) # 80002eb6 <argstr>
    80005992:	18054163          	bltz	a0,80005b14 <sys_unlink+0x1a2>
  begin_op();
    80005996:	fffff097          	auipc	ra,0xfffff
    8000599a:	bb2080e7          	jalr	-1102(ra) # 80004548 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000599e:	fb040593          	addi	a1,s0,-80
    800059a2:	f3040513          	addi	a0,s0,-208
    800059a6:	fffff097          	auipc	ra,0xfffff
    800059aa:	9a4080e7          	jalr	-1628(ra) # 8000434a <nameiparent>
    800059ae:	84aa                	mv	s1,a0
    800059b0:	c979                	beqz	a0,80005a86 <sys_unlink+0x114>
  ilock(dp);
    800059b2:	ffffe097          	auipc	ra,0xffffe
    800059b6:	1c6080e7          	jalr	454(ra) # 80003b78 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800059ba:	00003597          	auipc	a1,0x3
    800059be:	dde58593          	addi	a1,a1,-546 # 80008798 <syscalls+0x2c8>
    800059c2:	fb040513          	addi	a0,s0,-80
    800059c6:	ffffe097          	auipc	ra,0xffffe
    800059ca:	67a080e7          	jalr	1658(ra) # 80004040 <namecmp>
    800059ce:	14050a63          	beqz	a0,80005b22 <sys_unlink+0x1b0>
    800059d2:	00003597          	auipc	a1,0x3
    800059d6:	dce58593          	addi	a1,a1,-562 # 800087a0 <syscalls+0x2d0>
    800059da:	fb040513          	addi	a0,s0,-80
    800059de:	ffffe097          	auipc	ra,0xffffe
    800059e2:	662080e7          	jalr	1634(ra) # 80004040 <namecmp>
    800059e6:	12050e63          	beqz	a0,80005b22 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800059ea:	f2c40613          	addi	a2,s0,-212
    800059ee:	fb040593          	addi	a1,s0,-80
    800059f2:	8526                	mv	a0,s1
    800059f4:	ffffe097          	auipc	ra,0xffffe
    800059f8:	666080e7          	jalr	1638(ra) # 8000405a <dirlookup>
    800059fc:	892a                	mv	s2,a0
    800059fe:	12050263          	beqz	a0,80005b22 <sys_unlink+0x1b0>
  ilock(ip);
    80005a02:	ffffe097          	auipc	ra,0xffffe
    80005a06:	176080e7          	jalr	374(ra) # 80003b78 <ilock>
  if(ip->nlink < 1)
    80005a0a:	05291783          	lh	a5,82(s2)
    80005a0e:	08f05263          	blez	a5,80005a92 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005a12:	04c91703          	lh	a4,76(s2)
    80005a16:	4785                	li	a5,1
    80005a18:	08f70563          	beq	a4,a5,80005aa2 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005a1c:	4641                	li	a2,16
    80005a1e:	4581                	li	a1,0
    80005a20:	fc040513          	addi	a0,s0,-64
    80005a24:	ffffb097          	auipc	ra,0xffffb
    80005a28:	728080e7          	jalr	1832(ra) # 8000114c <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a2c:	4741                	li	a4,16
    80005a2e:	f2c42683          	lw	a3,-212(s0)
    80005a32:	fc040613          	addi	a2,s0,-64
    80005a36:	4581                	li	a1,0
    80005a38:	8526                	mv	a0,s1
    80005a3a:	ffffe097          	auipc	ra,0xffffe
    80005a3e:	4ea080e7          	jalr	1258(ra) # 80003f24 <writei>
    80005a42:	47c1                	li	a5,16
    80005a44:	0af51563          	bne	a0,a5,80005aee <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005a48:	04c91703          	lh	a4,76(s2)
    80005a4c:	4785                	li	a5,1
    80005a4e:	0af70863          	beq	a4,a5,80005afe <sys_unlink+0x18c>
  iunlockput(dp);
    80005a52:	8526                	mv	a0,s1
    80005a54:	ffffe097          	auipc	ra,0xffffe
    80005a58:	386080e7          	jalr	902(ra) # 80003dda <iunlockput>
  ip->nlink--;
    80005a5c:	05295783          	lhu	a5,82(s2)
    80005a60:	37fd                	addiw	a5,a5,-1
    80005a62:	04f91923          	sh	a5,82(s2)
  iupdate(ip);
    80005a66:	854a                	mv	a0,s2
    80005a68:	ffffe097          	auipc	ra,0xffffe
    80005a6c:	046080e7          	jalr	70(ra) # 80003aae <iupdate>
  iunlockput(ip);
    80005a70:	854a                	mv	a0,s2
    80005a72:	ffffe097          	auipc	ra,0xffffe
    80005a76:	368080e7          	jalr	872(ra) # 80003dda <iunlockput>
  end_op();
    80005a7a:	fffff097          	auipc	ra,0xfffff
    80005a7e:	b4e080e7          	jalr	-1202(ra) # 800045c8 <end_op>
  return 0;
    80005a82:	4501                	li	a0,0
    80005a84:	a84d                	j	80005b36 <sys_unlink+0x1c4>
    end_op();
    80005a86:	fffff097          	auipc	ra,0xfffff
    80005a8a:	b42080e7          	jalr	-1214(ra) # 800045c8 <end_op>
    return -1;
    80005a8e:	557d                	li	a0,-1
    80005a90:	a05d                	j	80005b36 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005a92:	00003517          	auipc	a0,0x3
    80005a96:	d3650513          	addi	a0,a0,-714 # 800087c8 <syscalls+0x2f8>
    80005a9a:	ffffb097          	auipc	ra,0xffffb
    80005a9e:	ab6080e7          	jalr	-1354(ra) # 80000550 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005aa2:	05492703          	lw	a4,84(s2)
    80005aa6:	02000793          	li	a5,32
    80005aaa:	f6e7f9e3          	bgeu	a5,a4,80005a1c <sys_unlink+0xaa>
    80005aae:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005ab2:	4741                	li	a4,16
    80005ab4:	86ce                	mv	a3,s3
    80005ab6:	f1840613          	addi	a2,s0,-232
    80005aba:	4581                	li	a1,0
    80005abc:	854a                	mv	a0,s2
    80005abe:	ffffe097          	auipc	ra,0xffffe
    80005ac2:	36e080e7          	jalr	878(ra) # 80003e2c <readi>
    80005ac6:	47c1                	li	a5,16
    80005ac8:	00f51b63          	bne	a0,a5,80005ade <sys_unlink+0x16c>
    if(de.inum != 0)
    80005acc:	f1845783          	lhu	a5,-232(s0)
    80005ad0:	e7a1                	bnez	a5,80005b18 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005ad2:	29c1                	addiw	s3,s3,16
    80005ad4:	05492783          	lw	a5,84(s2)
    80005ad8:	fcf9ede3          	bltu	s3,a5,80005ab2 <sys_unlink+0x140>
    80005adc:	b781                	j	80005a1c <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005ade:	00003517          	auipc	a0,0x3
    80005ae2:	d0250513          	addi	a0,a0,-766 # 800087e0 <syscalls+0x310>
    80005ae6:	ffffb097          	auipc	ra,0xffffb
    80005aea:	a6a080e7          	jalr	-1430(ra) # 80000550 <panic>
    panic("unlink: writei");
    80005aee:	00003517          	auipc	a0,0x3
    80005af2:	d0a50513          	addi	a0,a0,-758 # 800087f8 <syscalls+0x328>
    80005af6:	ffffb097          	auipc	ra,0xffffb
    80005afa:	a5a080e7          	jalr	-1446(ra) # 80000550 <panic>
    dp->nlink--;
    80005afe:	0524d783          	lhu	a5,82(s1)
    80005b02:	37fd                	addiw	a5,a5,-1
    80005b04:	04f49923          	sh	a5,82(s1)
    iupdate(dp);
    80005b08:	8526                	mv	a0,s1
    80005b0a:	ffffe097          	auipc	ra,0xffffe
    80005b0e:	fa4080e7          	jalr	-92(ra) # 80003aae <iupdate>
    80005b12:	b781                	j	80005a52 <sys_unlink+0xe0>
    return -1;
    80005b14:	557d                	li	a0,-1
    80005b16:	a005                	j	80005b36 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005b18:	854a                	mv	a0,s2
    80005b1a:	ffffe097          	auipc	ra,0xffffe
    80005b1e:	2c0080e7          	jalr	704(ra) # 80003dda <iunlockput>
  iunlockput(dp);
    80005b22:	8526                	mv	a0,s1
    80005b24:	ffffe097          	auipc	ra,0xffffe
    80005b28:	2b6080e7          	jalr	694(ra) # 80003dda <iunlockput>
  end_op();
    80005b2c:	fffff097          	auipc	ra,0xfffff
    80005b30:	a9c080e7          	jalr	-1380(ra) # 800045c8 <end_op>
  return -1;
    80005b34:	557d                	li	a0,-1
}
    80005b36:	70ae                	ld	ra,232(sp)
    80005b38:	740e                	ld	s0,224(sp)
    80005b3a:	64ee                	ld	s1,216(sp)
    80005b3c:	694e                	ld	s2,208(sp)
    80005b3e:	69ae                	ld	s3,200(sp)
    80005b40:	616d                	addi	sp,sp,240
    80005b42:	8082                	ret

0000000080005b44 <sys_open>:

uint64
sys_open(void)
{
    80005b44:	7131                	addi	sp,sp,-192
    80005b46:	fd06                	sd	ra,184(sp)
    80005b48:	f922                	sd	s0,176(sp)
    80005b4a:	f526                	sd	s1,168(sp)
    80005b4c:	f14a                	sd	s2,160(sp)
    80005b4e:	ed4e                	sd	s3,152(sp)
    80005b50:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005b52:	08000613          	li	a2,128
    80005b56:	f5040593          	addi	a1,s0,-176
    80005b5a:	4501                	li	a0,0
    80005b5c:	ffffd097          	auipc	ra,0xffffd
    80005b60:	35a080e7          	jalr	858(ra) # 80002eb6 <argstr>
    return -1;
    80005b64:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005b66:	0c054163          	bltz	a0,80005c28 <sys_open+0xe4>
    80005b6a:	f4c40593          	addi	a1,s0,-180
    80005b6e:	4505                	li	a0,1
    80005b70:	ffffd097          	auipc	ra,0xffffd
    80005b74:	302080e7          	jalr	770(ra) # 80002e72 <argint>
    80005b78:	0a054863          	bltz	a0,80005c28 <sys_open+0xe4>

  begin_op();
    80005b7c:	fffff097          	auipc	ra,0xfffff
    80005b80:	9cc080e7          	jalr	-1588(ra) # 80004548 <begin_op>

  if(omode & O_CREATE){
    80005b84:	f4c42783          	lw	a5,-180(s0)
    80005b88:	2007f793          	andi	a5,a5,512
    80005b8c:	cbdd                	beqz	a5,80005c42 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005b8e:	4681                	li	a3,0
    80005b90:	4601                	li	a2,0
    80005b92:	4589                	li	a1,2
    80005b94:	f5040513          	addi	a0,s0,-176
    80005b98:	00000097          	auipc	ra,0x0
    80005b9c:	972080e7          	jalr	-1678(ra) # 8000550a <create>
    80005ba0:	892a                	mv	s2,a0
    if(ip == 0){
    80005ba2:	c959                	beqz	a0,80005c38 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005ba4:	04c91703          	lh	a4,76(s2)
    80005ba8:	478d                	li	a5,3
    80005baa:	00f71763          	bne	a4,a5,80005bb8 <sys_open+0x74>
    80005bae:	04e95703          	lhu	a4,78(s2)
    80005bb2:	47a5                	li	a5,9
    80005bb4:	0ce7ec63          	bltu	a5,a4,80005c8c <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005bb8:	fffff097          	auipc	ra,0xfffff
    80005bbc:	da8080e7          	jalr	-600(ra) # 80004960 <filealloc>
    80005bc0:	89aa                	mv	s3,a0
    80005bc2:	10050263          	beqz	a0,80005cc6 <sys_open+0x182>
    80005bc6:	00000097          	auipc	ra,0x0
    80005bca:	902080e7          	jalr	-1790(ra) # 800054c8 <fdalloc>
    80005bce:	84aa                	mv	s1,a0
    80005bd0:	0e054663          	bltz	a0,80005cbc <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005bd4:	04c91703          	lh	a4,76(s2)
    80005bd8:	478d                	li	a5,3
    80005bda:	0cf70463          	beq	a4,a5,80005ca2 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005bde:	4789                	li	a5,2
    80005be0:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005be4:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005be8:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005bec:	f4c42783          	lw	a5,-180(s0)
    80005bf0:	0017c713          	xori	a4,a5,1
    80005bf4:	8b05                	andi	a4,a4,1
    80005bf6:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005bfa:	0037f713          	andi	a4,a5,3
    80005bfe:	00e03733          	snez	a4,a4
    80005c02:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005c06:	4007f793          	andi	a5,a5,1024
    80005c0a:	c791                	beqz	a5,80005c16 <sys_open+0xd2>
    80005c0c:	04c91703          	lh	a4,76(s2)
    80005c10:	4789                	li	a5,2
    80005c12:	08f70f63          	beq	a4,a5,80005cb0 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005c16:	854a                	mv	a0,s2
    80005c18:	ffffe097          	auipc	ra,0xffffe
    80005c1c:	022080e7          	jalr	34(ra) # 80003c3a <iunlock>
  end_op();
    80005c20:	fffff097          	auipc	ra,0xfffff
    80005c24:	9a8080e7          	jalr	-1624(ra) # 800045c8 <end_op>

  return fd;
}
    80005c28:	8526                	mv	a0,s1
    80005c2a:	70ea                	ld	ra,184(sp)
    80005c2c:	744a                	ld	s0,176(sp)
    80005c2e:	74aa                	ld	s1,168(sp)
    80005c30:	790a                	ld	s2,160(sp)
    80005c32:	69ea                	ld	s3,152(sp)
    80005c34:	6129                	addi	sp,sp,192
    80005c36:	8082                	ret
      end_op();
    80005c38:	fffff097          	auipc	ra,0xfffff
    80005c3c:	990080e7          	jalr	-1648(ra) # 800045c8 <end_op>
      return -1;
    80005c40:	b7e5                	j	80005c28 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005c42:	f5040513          	addi	a0,s0,-176
    80005c46:	ffffe097          	auipc	ra,0xffffe
    80005c4a:	6e6080e7          	jalr	1766(ra) # 8000432c <namei>
    80005c4e:	892a                	mv	s2,a0
    80005c50:	c905                	beqz	a0,80005c80 <sys_open+0x13c>
    ilock(ip);
    80005c52:	ffffe097          	auipc	ra,0xffffe
    80005c56:	f26080e7          	jalr	-218(ra) # 80003b78 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005c5a:	04c91703          	lh	a4,76(s2)
    80005c5e:	4785                	li	a5,1
    80005c60:	f4f712e3          	bne	a4,a5,80005ba4 <sys_open+0x60>
    80005c64:	f4c42783          	lw	a5,-180(s0)
    80005c68:	dba1                	beqz	a5,80005bb8 <sys_open+0x74>
      iunlockput(ip);
    80005c6a:	854a                	mv	a0,s2
    80005c6c:	ffffe097          	auipc	ra,0xffffe
    80005c70:	16e080e7          	jalr	366(ra) # 80003dda <iunlockput>
      end_op();
    80005c74:	fffff097          	auipc	ra,0xfffff
    80005c78:	954080e7          	jalr	-1708(ra) # 800045c8 <end_op>
      return -1;
    80005c7c:	54fd                	li	s1,-1
    80005c7e:	b76d                	j	80005c28 <sys_open+0xe4>
      end_op();
    80005c80:	fffff097          	auipc	ra,0xfffff
    80005c84:	948080e7          	jalr	-1720(ra) # 800045c8 <end_op>
      return -1;
    80005c88:	54fd                	li	s1,-1
    80005c8a:	bf79                	j	80005c28 <sys_open+0xe4>
    iunlockput(ip);
    80005c8c:	854a                	mv	a0,s2
    80005c8e:	ffffe097          	auipc	ra,0xffffe
    80005c92:	14c080e7          	jalr	332(ra) # 80003dda <iunlockput>
    end_op();
    80005c96:	fffff097          	auipc	ra,0xfffff
    80005c9a:	932080e7          	jalr	-1742(ra) # 800045c8 <end_op>
    return -1;
    80005c9e:	54fd                	li	s1,-1
    80005ca0:	b761                	j	80005c28 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005ca2:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005ca6:	04e91783          	lh	a5,78(s2)
    80005caa:	02f99223          	sh	a5,36(s3)
    80005cae:	bf2d                	j	80005be8 <sys_open+0xa4>
    itrunc(ip);
    80005cb0:	854a                	mv	a0,s2
    80005cb2:	ffffe097          	auipc	ra,0xffffe
    80005cb6:	fd4080e7          	jalr	-44(ra) # 80003c86 <itrunc>
    80005cba:	bfb1                	j	80005c16 <sys_open+0xd2>
      fileclose(f);
    80005cbc:	854e                	mv	a0,s3
    80005cbe:	fffff097          	auipc	ra,0xfffff
    80005cc2:	d5e080e7          	jalr	-674(ra) # 80004a1c <fileclose>
    iunlockput(ip);
    80005cc6:	854a                	mv	a0,s2
    80005cc8:	ffffe097          	auipc	ra,0xffffe
    80005ccc:	112080e7          	jalr	274(ra) # 80003dda <iunlockput>
    end_op();
    80005cd0:	fffff097          	auipc	ra,0xfffff
    80005cd4:	8f8080e7          	jalr	-1800(ra) # 800045c8 <end_op>
    return -1;
    80005cd8:	54fd                	li	s1,-1
    80005cda:	b7b9                	j	80005c28 <sys_open+0xe4>

0000000080005cdc <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005cdc:	7175                	addi	sp,sp,-144
    80005cde:	e506                	sd	ra,136(sp)
    80005ce0:	e122                	sd	s0,128(sp)
    80005ce2:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005ce4:	fffff097          	auipc	ra,0xfffff
    80005ce8:	864080e7          	jalr	-1948(ra) # 80004548 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005cec:	08000613          	li	a2,128
    80005cf0:	f7040593          	addi	a1,s0,-144
    80005cf4:	4501                	li	a0,0
    80005cf6:	ffffd097          	auipc	ra,0xffffd
    80005cfa:	1c0080e7          	jalr	448(ra) # 80002eb6 <argstr>
    80005cfe:	02054963          	bltz	a0,80005d30 <sys_mkdir+0x54>
    80005d02:	4681                	li	a3,0
    80005d04:	4601                	li	a2,0
    80005d06:	4585                	li	a1,1
    80005d08:	f7040513          	addi	a0,s0,-144
    80005d0c:	fffff097          	auipc	ra,0xfffff
    80005d10:	7fe080e7          	jalr	2046(ra) # 8000550a <create>
    80005d14:	cd11                	beqz	a0,80005d30 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d16:	ffffe097          	auipc	ra,0xffffe
    80005d1a:	0c4080e7          	jalr	196(ra) # 80003dda <iunlockput>
  end_op();
    80005d1e:	fffff097          	auipc	ra,0xfffff
    80005d22:	8aa080e7          	jalr	-1878(ra) # 800045c8 <end_op>
  return 0;
    80005d26:	4501                	li	a0,0
}
    80005d28:	60aa                	ld	ra,136(sp)
    80005d2a:	640a                	ld	s0,128(sp)
    80005d2c:	6149                	addi	sp,sp,144
    80005d2e:	8082                	ret
    end_op();
    80005d30:	fffff097          	auipc	ra,0xfffff
    80005d34:	898080e7          	jalr	-1896(ra) # 800045c8 <end_op>
    return -1;
    80005d38:	557d                	li	a0,-1
    80005d3a:	b7fd                	j	80005d28 <sys_mkdir+0x4c>

0000000080005d3c <sys_mknod>:

uint64
sys_mknod(void)
{
    80005d3c:	7135                	addi	sp,sp,-160
    80005d3e:	ed06                	sd	ra,152(sp)
    80005d40:	e922                	sd	s0,144(sp)
    80005d42:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005d44:	fffff097          	auipc	ra,0xfffff
    80005d48:	804080e7          	jalr	-2044(ra) # 80004548 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d4c:	08000613          	li	a2,128
    80005d50:	f7040593          	addi	a1,s0,-144
    80005d54:	4501                	li	a0,0
    80005d56:	ffffd097          	auipc	ra,0xffffd
    80005d5a:	160080e7          	jalr	352(ra) # 80002eb6 <argstr>
    80005d5e:	04054a63          	bltz	a0,80005db2 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005d62:	f6c40593          	addi	a1,s0,-148
    80005d66:	4505                	li	a0,1
    80005d68:	ffffd097          	auipc	ra,0xffffd
    80005d6c:	10a080e7          	jalr	266(ra) # 80002e72 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d70:	04054163          	bltz	a0,80005db2 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005d74:	f6840593          	addi	a1,s0,-152
    80005d78:	4509                	li	a0,2
    80005d7a:	ffffd097          	auipc	ra,0xffffd
    80005d7e:	0f8080e7          	jalr	248(ra) # 80002e72 <argint>
     argint(1, &major) < 0 ||
    80005d82:	02054863          	bltz	a0,80005db2 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005d86:	f6841683          	lh	a3,-152(s0)
    80005d8a:	f6c41603          	lh	a2,-148(s0)
    80005d8e:	458d                	li	a1,3
    80005d90:	f7040513          	addi	a0,s0,-144
    80005d94:	fffff097          	auipc	ra,0xfffff
    80005d98:	776080e7          	jalr	1910(ra) # 8000550a <create>
     argint(2, &minor) < 0 ||
    80005d9c:	c919                	beqz	a0,80005db2 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d9e:	ffffe097          	auipc	ra,0xffffe
    80005da2:	03c080e7          	jalr	60(ra) # 80003dda <iunlockput>
  end_op();
    80005da6:	fffff097          	auipc	ra,0xfffff
    80005daa:	822080e7          	jalr	-2014(ra) # 800045c8 <end_op>
  return 0;
    80005dae:	4501                	li	a0,0
    80005db0:	a031                	j	80005dbc <sys_mknod+0x80>
    end_op();
    80005db2:	fffff097          	auipc	ra,0xfffff
    80005db6:	816080e7          	jalr	-2026(ra) # 800045c8 <end_op>
    return -1;
    80005dba:	557d                	li	a0,-1
}
    80005dbc:	60ea                	ld	ra,152(sp)
    80005dbe:	644a                	ld	s0,144(sp)
    80005dc0:	610d                	addi	sp,sp,160
    80005dc2:	8082                	ret

0000000080005dc4 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005dc4:	7135                	addi	sp,sp,-160
    80005dc6:	ed06                	sd	ra,152(sp)
    80005dc8:	e922                	sd	s0,144(sp)
    80005dca:	e526                	sd	s1,136(sp)
    80005dcc:	e14a                	sd	s2,128(sp)
    80005dce:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005dd0:	ffffc097          	auipc	ra,0xffffc
    80005dd4:	fe4080e7          	jalr	-28(ra) # 80001db4 <myproc>
    80005dd8:	892a                	mv	s2,a0
  
  begin_op();
    80005dda:	ffffe097          	auipc	ra,0xffffe
    80005dde:	76e080e7          	jalr	1902(ra) # 80004548 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005de2:	08000613          	li	a2,128
    80005de6:	f6040593          	addi	a1,s0,-160
    80005dea:	4501                	li	a0,0
    80005dec:	ffffd097          	auipc	ra,0xffffd
    80005df0:	0ca080e7          	jalr	202(ra) # 80002eb6 <argstr>
    80005df4:	04054b63          	bltz	a0,80005e4a <sys_chdir+0x86>
    80005df8:	f6040513          	addi	a0,s0,-160
    80005dfc:	ffffe097          	auipc	ra,0xffffe
    80005e00:	530080e7          	jalr	1328(ra) # 8000432c <namei>
    80005e04:	84aa                	mv	s1,a0
    80005e06:	c131                	beqz	a0,80005e4a <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005e08:	ffffe097          	auipc	ra,0xffffe
    80005e0c:	d70080e7          	jalr	-656(ra) # 80003b78 <ilock>
  if(ip->type != T_DIR){
    80005e10:	04c49703          	lh	a4,76(s1)
    80005e14:	4785                	li	a5,1
    80005e16:	04f71063          	bne	a4,a5,80005e56 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005e1a:	8526                	mv	a0,s1
    80005e1c:	ffffe097          	auipc	ra,0xffffe
    80005e20:	e1e080e7          	jalr	-482(ra) # 80003c3a <iunlock>
  iput(p->cwd);
    80005e24:	15893503          	ld	a0,344(s2)
    80005e28:	ffffe097          	auipc	ra,0xffffe
    80005e2c:	f0a080e7          	jalr	-246(ra) # 80003d32 <iput>
  end_op();
    80005e30:	ffffe097          	auipc	ra,0xffffe
    80005e34:	798080e7          	jalr	1944(ra) # 800045c8 <end_op>
  p->cwd = ip;
    80005e38:	14993c23          	sd	s1,344(s2)
  return 0;
    80005e3c:	4501                	li	a0,0
}
    80005e3e:	60ea                	ld	ra,152(sp)
    80005e40:	644a                	ld	s0,144(sp)
    80005e42:	64aa                	ld	s1,136(sp)
    80005e44:	690a                	ld	s2,128(sp)
    80005e46:	610d                	addi	sp,sp,160
    80005e48:	8082                	ret
    end_op();
    80005e4a:	ffffe097          	auipc	ra,0xffffe
    80005e4e:	77e080e7          	jalr	1918(ra) # 800045c8 <end_op>
    return -1;
    80005e52:	557d                	li	a0,-1
    80005e54:	b7ed                	j	80005e3e <sys_chdir+0x7a>
    iunlockput(ip);
    80005e56:	8526                	mv	a0,s1
    80005e58:	ffffe097          	auipc	ra,0xffffe
    80005e5c:	f82080e7          	jalr	-126(ra) # 80003dda <iunlockput>
    end_op();
    80005e60:	ffffe097          	auipc	ra,0xffffe
    80005e64:	768080e7          	jalr	1896(ra) # 800045c8 <end_op>
    return -1;
    80005e68:	557d                	li	a0,-1
    80005e6a:	bfd1                	j	80005e3e <sys_chdir+0x7a>

0000000080005e6c <sys_exec>:

uint64
sys_exec(void)
{
    80005e6c:	7145                	addi	sp,sp,-464
    80005e6e:	e786                	sd	ra,456(sp)
    80005e70:	e3a2                	sd	s0,448(sp)
    80005e72:	ff26                	sd	s1,440(sp)
    80005e74:	fb4a                	sd	s2,432(sp)
    80005e76:	f74e                	sd	s3,424(sp)
    80005e78:	f352                	sd	s4,416(sp)
    80005e7a:	ef56                	sd	s5,408(sp)
    80005e7c:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005e7e:	08000613          	li	a2,128
    80005e82:	f4040593          	addi	a1,s0,-192
    80005e86:	4501                	li	a0,0
    80005e88:	ffffd097          	auipc	ra,0xffffd
    80005e8c:	02e080e7          	jalr	46(ra) # 80002eb6 <argstr>
    return -1;
    80005e90:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005e92:	0c054a63          	bltz	a0,80005f66 <sys_exec+0xfa>
    80005e96:	e3840593          	addi	a1,s0,-456
    80005e9a:	4505                	li	a0,1
    80005e9c:	ffffd097          	auipc	ra,0xffffd
    80005ea0:	ff8080e7          	jalr	-8(ra) # 80002e94 <argaddr>
    80005ea4:	0c054163          	bltz	a0,80005f66 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005ea8:	10000613          	li	a2,256
    80005eac:	4581                	li	a1,0
    80005eae:	e4040513          	addi	a0,s0,-448
    80005eb2:	ffffb097          	auipc	ra,0xffffb
    80005eb6:	29a080e7          	jalr	666(ra) # 8000114c <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005eba:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005ebe:	89a6                	mv	s3,s1
    80005ec0:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005ec2:	02000a13          	li	s4,32
    80005ec6:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005eca:	00391513          	slli	a0,s2,0x3
    80005ece:	e3040593          	addi	a1,s0,-464
    80005ed2:	e3843783          	ld	a5,-456(s0)
    80005ed6:	953e                	add	a0,a0,a5
    80005ed8:	ffffd097          	auipc	ra,0xffffd
    80005edc:	f00080e7          	jalr	-256(ra) # 80002dd8 <fetchaddr>
    80005ee0:	02054a63          	bltz	a0,80005f14 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005ee4:	e3043783          	ld	a5,-464(s0)
    80005ee8:	c3b9                	beqz	a5,80005f2e <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005eea:	ffffb097          	auipc	ra,0xffffb
    80005eee:	d06080e7          	jalr	-762(ra) # 80000bf0 <kalloc>
    80005ef2:	85aa                	mv	a1,a0
    80005ef4:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005ef8:	cd11                	beqz	a0,80005f14 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005efa:	6605                	lui	a2,0x1
    80005efc:	e3043503          	ld	a0,-464(s0)
    80005f00:	ffffd097          	auipc	ra,0xffffd
    80005f04:	f2a080e7          	jalr	-214(ra) # 80002e2a <fetchstr>
    80005f08:	00054663          	bltz	a0,80005f14 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005f0c:	0905                	addi	s2,s2,1
    80005f0e:	09a1                	addi	s3,s3,8
    80005f10:	fb491be3          	bne	s2,s4,80005ec6 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f14:	10048913          	addi	s2,s1,256
    80005f18:	6088                	ld	a0,0(s1)
    80005f1a:	c529                	beqz	a0,80005f64 <sys_exec+0xf8>
    kfree(argv[i]);
    80005f1c:	ffffb097          	auipc	ra,0xffffb
    80005f20:	b10080e7          	jalr	-1264(ra) # 80000a2c <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f24:	04a1                	addi	s1,s1,8
    80005f26:	ff2499e3          	bne	s1,s2,80005f18 <sys_exec+0xac>
  return -1;
    80005f2a:	597d                	li	s2,-1
    80005f2c:	a82d                	j	80005f66 <sys_exec+0xfa>
      argv[i] = 0;
    80005f2e:	0a8e                	slli	s5,s5,0x3
    80005f30:	fc040793          	addi	a5,s0,-64
    80005f34:	9abe                	add	s5,s5,a5
    80005f36:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005f3a:	e4040593          	addi	a1,s0,-448
    80005f3e:	f4040513          	addi	a0,s0,-192
    80005f42:	fffff097          	auipc	ra,0xfffff
    80005f46:	194080e7          	jalr	404(ra) # 800050d6 <exec>
    80005f4a:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f4c:	10048993          	addi	s3,s1,256
    80005f50:	6088                	ld	a0,0(s1)
    80005f52:	c911                	beqz	a0,80005f66 <sys_exec+0xfa>
    kfree(argv[i]);
    80005f54:	ffffb097          	auipc	ra,0xffffb
    80005f58:	ad8080e7          	jalr	-1320(ra) # 80000a2c <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f5c:	04a1                	addi	s1,s1,8
    80005f5e:	ff3499e3          	bne	s1,s3,80005f50 <sys_exec+0xe4>
    80005f62:	a011                	j	80005f66 <sys_exec+0xfa>
  return -1;
    80005f64:	597d                	li	s2,-1
}
    80005f66:	854a                	mv	a0,s2
    80005f68:	60be                	ld	ra,456(sp)
    80005f6a:	641e                	ld	s0,448(sp)
    80005f6c:	74fa                	ld	s1,440(sp)
    80005f6e:	795a                	ld	s2,432(sp)
    80005f70:	79ba                	ld	s3,424(sp)
    80005f72:	7a1a                	ld	s4,416(sp)
    80005f74:	6afa                	ld	s5,408(sp)
    80005f76:	6179                	addi	sp,sp,464
    80005f78:	8082                	ret

0000000080005f7a <sys_pipe>:

uint64
sys_pipe(void)
{
    80005f7a:	7139                	addi	sp,sp,-64
    80005f7c:	fc06                	sd	ra,56(sp)
    80005f7e:	f822                	sd	s0,48(sp)
    80005f80:	f426                	sd	s1,40(sp)
    80005f82:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005f84:	ffffc097          	auipc	ra,0xffffc
    80005f88:	e30080e7          	jalr	-464(ra) # 80001db4 <myproc>
    80005f8c:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005f8e:	fd840593          	addi	a1,s0,-40
    80005f92:	4501                	li	a0,0
    80005f94:	ffffd097          	auipc	ra,0xffffd
    80005f98:	f00080e7          	jalr	-256(ra) # 80002e94 <argaddr>
    return -1;
    80005f9c:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005f9e:	0e054063          	bltz	a0,8000607e <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005fa2:	fc840593          	addi	a1,s0,-56
    80005fa6:	fd040513          	addi	a0,s0,-48
    80005faa:	fffff097          	auipc	ra,0xfffff
    80005fae:	dc8080e7          	jalr	-568(ra) # 80004d72 <pipealloc>
    return -1;
    80005fb2:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005fb4:	0c054563          	bltz	a0,8000607e <sys_pipe+0x104>
  fd0 = -1;
    80005fb8:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005fbc:	fd043503          	ld	a0,-48(s0)
    80005fc0:	fffff097          	auipc	ra,0xfffff
    80005fc4:	508080e7          	jalr	1288(ra) # 800054c8 <fdalloc>
    80005fc8:	fca42223          	sw	a0,-60(s0)
    80005fcc:	08054c63          	bltz	a0,80006064 <sys_pipe+0xea>
    80005fd0:	fc843503          	ld	a0,-56(s0)
    80005fd4:	fffff097          	auipc	ra,0xfffff
    80005fd8:	4f4080e7          	jalr	1268(ra) # 800054c8 <fdalloc>
    80005fdc:	fca42023          	sw	a0,-64(s0)
    80005fe0:	06054863          	bltz	a0,80006050 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005fe4:	4691                	li	a3,4
    80005fe6:	fc440613          	addi	a2,s0,-60
    80005fea:	fd843583          	ld	a1,-40(s0)
    80005fee:	6ca8                	ld	a0,88(s1)
    80005ff0:	ffffc097          	auipc	ra,0xffffc
    80005ff4:	ab8080e7          	jalr	-1352(ra) # 80001aa8 <copyout>
    80005ff8:	02054063          	bltz	a0,80006018 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005ffc:	4691                	li	a3,4
    80005ffe:	fc040613          	addi	a2,s0,-64
    80006002:	fd843583          	ld	a1,-40(s0)
    80006006:	0591                	addi	a1,a1,4
    80006008:	6ca8                	ld	a0,88(s1)
    8000600a:	ffffc097          	auipc	ra,0xffffc
    8000600e:	a9e080e7          	jalr	-1378(ra) # 80001aa8 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006012:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006014:	06055563          	bgez	a0,8000607e <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006018:	fc442783          	lw	a5,-60(s0)
    8000601c:	07e9                	addi	a5,a5,26
    8000601e:	078e                	slli	a5,a5,0x3
    80006020:	97a6                	add	a5,a5,s1
    80006022:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80006026:	fc042503          	lw	a0,-64(s0)
    8000602a:	0569                	addi	a0,a0,26
    8000602c:	050e                	slli	a0,a0,0x3
    8000602e:	9526                	add	a0,a0,s1
    80006030:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80006034:	fd043503          	ld	a0,-48(s0)
    80006038:	fffff097          	auipc	ra,0xfffff
    8000603c:	9e4080e7          	jalr	-1564(ra) # 80004a1c <fileclose>
    fileclose(wf);
    80006040:	fc843503          	ld	a0,-56(s0)
    80006044:	fffff097          	auipc	ra,0xfffff
    80006048:	9d8080e7          	jalr	-1576(ra) # 80004a1c <fileclose>
    return -1;
    8000604c:	57fd                	li	a5,-1
    8000604e:	a805                	j	8000607e <sys_pipe+0x104>
    if(fd0 >= 0)
    80006050:	fc442783          	lw	a5,-60(s0)
    80006054:	0007c863          	bltz	a5,80006064 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006058:	01a78513          	addi	a0,a5,26
    8000605c:	050e                	slli	a0,a0,0x3
    8000605e:	9526                	add	a0,a0,s1
    80006060:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80006064:	fd043503          	ld	a0,-48(s0)
    80006068:	fffff097          	auipc	ra,0xfffff
    8000606c:	9b4080e7          	jalr	-1612(ra) # 80004a1c <fileclose>
    fileclose(wf);
    80006070:	fc843503          	ld	a0,-56(s0)
    80006074:	fffff097          	auipc	ra,0xfffff
    80006078:	9a8080e7          	jalr	-1624(ra) # 80004a1c <fileclose>
    return -1;
    8000607c:	57fd                	li	a5,-1
}
    8000607e:	853e                	mv	a0,a5
    80006080:	70e2                	ld	ra,56(sp)
    80006082:	7442                	ld	s0,48(sp)
    80006084:	74a2                	ld	s1,40(sp)
    80006086:	6121                	addi	sp,sp,64
    80006088:	8082                	ret
    8000608a:	0000                	unimp
    8000608c:	0000                	unimp
	...

0000000080006090 <kernelvec>:
    80006090:	7111                	addi	sp,sp,-256
    80006092:	e006                	sd	ra,0(sp)
    80006094:	e40a                	sd	sp,8(sp)
    80006096:	e80e                	sd	gp,16(sp)
    80006098:	ec12                	sd	tp,24(sp)
    8000609a:	f016                	sd	t0,32(sp)
    8000609c:	f41a                	sd	t1,40(sp)
    8000609e:	f81e                	sd	t2,48(sp)
    800060a0:	fc22                	sd	s0,56(sp)
    800060a2:	e0a6                	sd	s1,64(sp)
    800060a4:	e4aa                	sd	a0,72(sp)
    800060a6:	e8ae                	sd	a1,80(sp)
    800060a8:	ecb2                	sd	a2,88(sp)
    800060aa:	f0b6                	sd	a3,96(sp)
    800060ac:	f4ba                	sd	a4,104(sp)
    800060ae:	f8be                	sd	a5,112(sp)
    800060b0:	fcc2                	sd	a6,120(sp)
    800060b2:	e146                	sd	a7,128(sp)
    800060b4:	e54a                	sd	s2,136(sp)
    800060b6:	e94e                	sd	s3,144(sp)
    800060b8:	ed52                	sd	s4,152(sp)
    800060ba:	f156                	sd	s5,160(sp)
    800060bc:	f55a                	sd	s6,168(sp)
    800060be:	f95e                	sd	s7,176(sp)
    800060c0:	fd62                	sd	s8,184(sp)
    800060c2:	e1e6                	sd	s9,192(sp)
    800060c4:	e5ea                	sd	s10,200(sp)
    800060c6:	e9ee                	sd	s11,208(sp)
    800060c8:	edf2                	sd	t3,216(sp)
    800060ca:	f1f6                	sd	t4,224(sp)
    800060cc:	f5fa                	sd	t5,232(sp)
    800060ce:	f9fe                	sd	t6,240(sp)
    800060d0:	bd5fc0ef          	jal	ra,80002ca4 <kerneltrap>
    800060d4:	6082                	ld	ra,0(sp)
    800060d6:	6122                	ld	sp,8(sp)
    800060d8:	61c2                	ld	gp,16(sp)
    800060da:	7282                	ld	t0,32(sp)
    800060dc:	7322                	ld	t1,40(sp)
    800060de:	73c2                	ld	t2,48(sp)
    800060e0:	7462                	ld	s0,56(sp)
    800060e2:	6486                	ld	s1,64(sp)
    800060e4:	6526                	ld	a0,72(sp)
    800060e6:	65c6                	ld	a1,80(sp)
    800060e8:	6666                	ld	a2,88(sp)
    800060ea:	7686                	ld	a3,96(sp)
    800060ec:	7726                	ld	a4,104(sp)
    800060ee:	77c6                	ld	a5,112(sp)
    800060f0:	7866                	ld	a6,120(sp)
    800060f2:	688a                	ld	a7,128(sp)
    800060f4:	692a                	ld	s2,136(sp)
    800060f6:	69ca                	ld	s3,144(sp)
    800060f8:	6a6a                	ld	s4,152(sp)
    800060fa:	7a8a                	ld	s5,160(sp)
    800060fc:	7b2a                	ld	s6,168(sp)
    800060fe:	7bca                	ld	s7,176(sp)
    80006100:	7c6a                	ld	s8,184(sp)
    80006102:	6c8e                	ld	s9,192(sp)
    80006104:	6d2e                	ld	s10,200(sp)
    80006106:	6dce                	ld	s11,208(sp)
    80006108:	6e6e                	ld	t3,216(sp)
    8000610a:	7e8e                	ld	t4,224(sp)
    8000610c:	7f2e                	ld	t5,232(sp)
    8000610e:	7fce                	ld	t6,240(sp)
    80006110:	6111                	addi	sp,sp,256
    80006112:	10200073          	sret
    80006116:	00000013          	nop
    8000611a:	00000013          	nop
    8000611e:	0001                	nop

0000000080006120 <timervec>:
    80006120:	34051573          	csrrw	a0,mscratch,a0
    80006124:	e10c                	sd	a1,0(a0)
    80006126:	e510                	sd	a2,8(a0)
    80006128:	e914                	sd	a3,16(a0)
    8000612a:	6d0c                	ld	a1,24(a0)
    8000612c:	7110                	ld	a2,32(a0)
    8000612e:	6194                	ld	a3,0(a1)
    80006130:	96b2                	add	a3,a3,a2
    80006132:	e194                	sd	a3,0(a1)
    80006134:	4589                	li	a1,2
    80006136:	14459073          	csrw	sip,a1
    8000613a:	6914                	ld	a3,16(a0)
    8000613c:	6510                	ld	a2,8(a0)
    8000613e:	610c                	ld	a1,0(a0)
    80006140:	34051573          	csrrw	a0,mscratch,a0
    80006144:	30200073          	mret
	...

000000008000614a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000614a:	1141                	addi	sp,sp,-16
    8000614c:	e422                	sd	s0,8(sp)
    8000614e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006150:	0c0007b7          	lui	a5,0xc000
    80006154:	4705                	li	a4,1
    80006156:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006158:	c3d8                	sw	a4,4(a5)
}
    8000615a:	6422                	ld	s0,8(sp)
    8000615c:	0141                	addi	sp,sp,16
    8000615e:	8082                	ret

0000000080006160 <plicinithart>:

void
plicinithart(void)
{
    80006160:	1141                	addi	sp,sp,-16
    80006162:	e406                	sd	ra,8(sp)
    80006164:	e022                	sd	s0,0(sp)
    80006166:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006168:	ffffc097          	auipc	ra,0xffffc
    8000616c:	c20080e7          	jalr	-992(ra) # 80001d88 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006170:	0085171b          	slliw	a4,a0,0x8
    80006174:	0c0027b7          	lui	a5,0xc002
    80006178:	97ba                	add	a5,a5,a4
    8000617a:	40200713          	li	a4,1026
    8000617e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006182:	00d5151b          	slliw	a0,a0,0xd
    80006186:	0c2017b7          	lui	a5,0xc201
    8000618a:	953e                	add	a0,a0,a5
    8000618c:	00052023          	sw	zero,0(a0)
}
    80006190:	60a2                	ld	ra,8(sp)
    80006192:	6402                	ld	s0,0(sp)
    80006194:	0141                	addi	sp,sp,16
    80006196:	8082                	ret

0000000080006198 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006198:	1141                	addi	sp,sp,-16
    8000619a:	e406                	sd	ra,8(sp)
    8000619c:	e022                	sd	s0,0(sp)
    8000619e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800061a0:	ffffc097          	auipc	ra,0xffffc
    800061a4:	be8080e7          	jalr	-1048(ra) # 80001d88 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800061a8:	00d5179b          	slliw	a5,a0,0xd
    800061ac:	0c201537          	lui	a0,0xc201
    800061b0:	953e                	add	a0,a0,a5
  return irq;
}
    800061b2:	4148                	lw	a0,4(a0)
    800061b4:	60a2                	ld	ra,8(sp)
    800061b6:	6402                	ld	s0,0(sp)
    800061b8:	0141                	addi	sp,sp,16
    800061ba:	8082                	ret

00000000800061bc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800061bc:	1101                	addi	sp,sp,-32
    800061be:	ec06                	sd	ra,24(sp)
    800061c0:	e822                	sd	s0,16(sp)
    800061c2:	e426                	sd	s1,8(sp)
    800061c4:	1000                	addi	s0,sp,32
    800061c6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800061c8:	ffffc097          	auipc	ra,0xffffc
    800061cc:	bc0080e7          	jalr	-1088(ra) # 80001d88 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800061d0:	00d5151b          	slliw	a0,a0,0xd
    800061d4:	0c2017b7          	lui	a5,0xc201
    800061d8:	97aa                	add	a5,a5,a0
    800061da:	c3c4                	sw	s1,4(a5)
}
    800061dc:	60e2                	ld	ra,24(sp)
    800061de:	6442                	ld	s0,16(sp)
    800061e0:	64a2                	ld	s1,8(sp)
    800061e2:	6105                	addi	sp,sp,32
    800061e4:	8082                	ret

00000000800061e6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800061e6:	1141                	addi	sp,sp,-16
    800061e8:	e406                	sd	ra,8(sp)
    800061ea:	e022                	sd	s0,0(sp)
    800061ec:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800061ee:	479d                	li	a5,7
    800061f0:	06a7c963          	blt	a5,a0,80006262 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    800061f4:	00022797          	auipc	a5,0x22
    800061f8:	e0c78793          	addi	a5,a5,-500 # 80028000 <disk>
    800061fc:	00a78733          	add	a4,a5,a0
    80006200:	6789                	lui	a5,0x2
    80006202:	97ba                	add	a5,a5,a4
    80006204:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006208:	e7ad                	bnez	a5,80006272 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000620a:	00451793          	slli	a5,a0,0x4
    8000620e:	00024717          	auipc	a4,0x24
    80006212:	df270713          	addi	a4,a4,-526 # 8002a000 <disk+0x2000>
    80006216:	6314                	ld	a3,0(a4)
    80006218:	96be                	add	a3,a3,a5
    8000621a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000621e:	6314                	ld	a3,0(a4)
    80006220:	96be                	add	a3,a3,a5
    80006222:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006226:	6314                	ld	a3,0(a4)
    80006228:	96be                	add	a3,a3,a5
    8000622a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000622e:	6318                	ld	a4,0(a4)
    80006230:	97ba                	add	a5,a5,a4
    80006232:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006236:	00022797          	auipc	a5,0x22
    8000623a:	dca78793          	addi	a5,a5,-566 # 80028000 <disk>
    8000623e:	97aa                	add	a5,a5,a0
    80006240:	6509                	lui	a0,0x2
    80006242:	953e                	add	a0,a0,a5
    80006244:	4785                	li	a5,1
    80006246:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000624a:	00024517          	auipc	a0,0x24
    8000624e:	dce50513          	addi	a0,a0,-562 # 8002a018 <disk+0x2018>
    80006252:	ffffc097          	auipc	ra,0xffffc
    80006256:	4f8080e7          	jalr	1272(ra) # 8000274a <wakeup>
}
    8000625a:	60a2                	ld	ra,8(sp)
    8000625c:	6402                	ld	s0,0(sp)
    8000625e:	0141                	addi	sp,sp,16
    80006260:	8082                	ret
    panic("free_desc 1");
    80006262:	00002517          	auipc	a0,0x2
    80006266:	5a650513          	addi	a0,a0,1446 # 80008808 <syscalls+0x338>
    8000626a:	ffffa097          	auipc	ra,0xffffa
    8000626e:	2e6080e7          	jalr	742(ra) # 80000550 <panic>
    panic("free_desc 2");
    80006272:	00002517          	auipc	a0,0x2
    80006276:	5a650513          	addi	a0,a0,1446 # 80008818 <syscalls+0x348>
    8000627a:	ffffa097          	auipc	ra,0xffffa
    8000627e:	2d6080e7          	jalr	726(ra) # 80000550 <panic>

0000000080006282 <virtio_disk_init>:
{
    80006282:	1101                	addi	sp,sp,-32
    80006284:	ec06                	sd	ra,24(sp)
    80006286:	e822                	sd	s0,16(sp)
    80006288:	e426                	sd	s1,8(sp)
    8000628a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000628c:	00002597          	auipc	a1,0x2
    80006290:	59c58593          	addi	a1,a1,1436 # 80008828 <syscalls+0x358>
    80006294:	00024517          	auipc	a0,0x24
    80006298:	e9450513          	addi	a0,a0,-364 # 8002a128 <disk+0x2128>
    8000629c:	ffffb097          	auipc	ra,0xffffb
    800062a0:	c4c080e7          	jalr	-948(ra) # 80000ee8 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800062a4:	100017b7          	lui	a5,0x10001
    800062a8:	4398                	lw	a4,0(a5)
    800062aa:	2701                	sext.w	a4,a4
    800062ac:	747277b7          	lui	a5,0x74727
    800062b0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800062b4:	0ef71163          	bne	a4,a5,80006396 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800062b8:	100017b7          	lui	a5,0x10001
    800062bc:	43dc                	lw	a5,4(a5)
    800062be:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800062c0:	4705                	li	a4,1
    800062c2:	0ce79a63          	bne	a5,a4,80006396 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800062c6:	100017b7          	lui	a5,0x10001
    800062ca:	479c                	lw	a5,8(a5)
    800062cc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800062ce:	4709                	li	a4,2
    800062d0:	0ce79363          	bne	a5,a4,80006396 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800062d4:	100017b7          	lui	a5,0x10001
    800062d8:	47d8                	lw	a4,12(a5)
    800062da:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800062dc:	554d47b7          	lui	a5,0x554d4
    800062e0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800062e4:	0af71963          	bne	a4,a5,80006396 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800062e8:	100017b7          	lui	a5,0x10001
    800062ec:	4705                	li	a4,1
    800062ee:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800062f0:	470d                	li	a4,3
    800062f2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800062f4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800062f6:	c7ffe737          	lui	a4,0xc7ffe
    800062fa:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd2737>
    800062fe:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006300:	2701                	sext.w	a4,a4
    80006302:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006304:	472d                	li	a4,11
    80006306:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006308:	473d                	li	a4,15
    8000630a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000630c:	6705                	lui	a4,0x1
    8000630e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006310:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006314:	5bdc                	lw	a5,52(a5)
    80006316:	2781                	sext.w	a5,a5
  if(max == 0)
    80006318:	c7d9                	beqz	a5,800063a6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000631a:	471d                	li	a4,7
    8000631c:	08f77d63          	bgeu	a4,a5,800063b6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006320:	100014b7          	lui	s1,0x10001
    80006324:	47a1                	li	a5,8
    80006326:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006328:	6609                	lui	a2,0x2
    8000632a:	4581                	li	a1,0
    8000632c:	00022517          	auipc	a0,0x22
    80006330:	cd450513          	addi	a0,a0,-812 # 80028000 <disk>
    80006334:	ffffb097          	auipc	ra,0xffffb
    80006338:	e18080e7          	jalr	-488(ra) # 8000114c <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000633c:	00022717          	auipc	a4,0x22
    80006340:	cc470713          	addi	a4,a4,-828 # 80028000 <disk>
    80006344:	00c75793          	srli	a5,a4,0xc
    80006348:	2781                	sext.w	a5,a5
    8000634a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000634c:	00024797          	auipc	a5,0x24
    80006350:	cb478793          	addi	a5,a5,-844 # 8002a000 <disk+0x2000>
    80006354:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006356:	00022717          	auipc	a4,0x22
    8000635a:	d2a70713          	addi	a4,a4,-726 # 80028080 <disk+0x80>
    8000635e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006360:	00023717          	auipc	a4,0x23
    80006364:	ca070713          	addi	a4,a4,-864 # 80029000 <disk+0x1000>
    80006368:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000636a:	4705                	li	a4,1
    8000636c:	00e78c23          	sb	a4,24(a5)
    80006370:	00e78ca3          	sb	a4,25(a5)
    80006374:	00e78d23          	sb	a4,26(a5)
    80006378:	00e78da3          	sb	a4,27(a5)
    8000637c:	00e78e23          	sb	a4,28(a5)
    80006380:	00e78ea3          	sb	a4,29(a5)
    80006384:	00e78f23          	sb	a4,30(a5)
    80006388:	00e78fa3          	sb	a4,31(a5)
}
    8000638c:	60e2                	ld	ra,24(sp)
    8000638e:	6442                	ld	s0,16(sp)
    80006390:	64a2                	ld	s1,8(sp)
    80006392:	6105                	addi	sp,sp,32
    80006394:	8082                	ret
    panic("could not find virtio disk");
    80006396:	00002517          	auipc	a0,0x2
    8000639a:	4a250513          	addi	a0,a0,1186 # 80008838 <syscalls+0x368>
    8000639e:	ffffa097          	auipc	ra,0xffffa
    800063a2:	1b2080e7          	jalr	434(ra) # 80000550 <panic>
    panic("virtio disk has no queue 0");
    800063a6:	00002517          	auipc	a0,0x2
    800063aa:	4b250513          	addi	a0,a0,1202 # 80008858 <syscalls+0x388>
    800063ae:	ffffa097          	auipc	ra,0xffffa
    800063b2:	1a2080e7          	jalr	418(ra) # 80000550 <panic>
    panic("virtio disk max queue too short");
    800063b6:	00002517          	auipc	a0,0x2
    800063ba:	4c250513          	addi	a0,a0,1218 # 80008878 <syscalls+0x3a8>
    800063be:	ffffa097          	auipc	ra,0xffffa
    800063c2:	192080e7          	jalr	402(ra) # 80000550 <panic>

00000000800063c6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800063c6:	7159                	addi	sp,sp,-112
    800063c8:	f486                	sd	ra,104(sp)
    800063ca:	f0a2                	sd	s0,96(sp)
    800063cc:	eca6                	sd	s1,88(sp)
    800063ce:	e8ca                	sd	s2,80(sp)
    800063d0:	e4ce                	sd	s3,72(sp)
    800063d2:	e0d2                	sd	s4,64(sp)
    800063d4:	fc56                	sd	s5,56(sp)
    800063d6:	f85a                	sd	s6,48(sp)
    800063d8:	f45e                	sd	s7,40(sp)
    800063da:	f062                	sd	s8,32(sp)
    800063dc:	ec66                	sd	s9,24(sp)
    800063de:	e86a                	sd	s10,16(sp)
    800063e0:	1880                	addi	s0,sp,112
    800063e2:	892a                	mv	s2,a0
    800063e4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800063e6:	00c52c83          	lw	s9,12(a0)
    800063ea:	001c9c9b          	slliw	s9,s9,0x1
    800063ee:	1c82                	slli	s9,s9,0x20
    800063f0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800063f4:	00024517          	auipc	a0,0x24
    800063f8:	d3450513          	addi	a0,a0,-716 # 8002a128 <disk+0x2128>
    800063fc:	ffffb097          	auipc	ra,0xffffb
    80006400:	970080e7          	jalr	-1680(ra) # 80000d6c <acquire>
  for(int i = 0; i < 3; i++){
    80006404:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006406:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006408:	00022b97          	auipc	s7,0x22
    8000640c:	bf8b8b93          	addi	s7,s7,-1032 # 80028000 <disk>
    80006410:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006412:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006414:	8a4e                	mv	s4,s3
    80006416:	a051                	j	8000649a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006418:	00fb86b3          	add	a3,s7,a5
    8000641c:	96da                	add	a3,a3,s6
    8000641e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006422:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006424:	0207c563          	bltz	a5,8000644e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006428:	2485                	addiw	s1,s1,1
    8000642a:	0711                	addi	a4,a4,4
    8000642c:	25548063          	beq	s1,s5,8000666c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006430:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006432:	00024697          	auipc	a3,0x24
    80006436:	be668693          	addi	a3,a3,-1050 # 8002a018 <disk+0x2018>
    8000643a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000643c:	0006c583          	lbu	a1,0(a3)
    80006440:	fde1                	bnez	a1,80006418 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006442:	2785                	addiw	a5,a5,1
    80006444:	0685                	addi	a3,a3,1
    80006446:	ff879be3          	bne	a5,s8,8000643c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000644a:	57fd                	li	a5,-1
    8000644c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000644e:	02905a63          	blez	s1,80006482 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006452:	f9042503          	lw	a0,-112(s0)
    80006456:	00000097          	auipc	ra,0x0
    8000645a:	d90080e7          	jalr	-624(ra) # 800061e6 <free_desc>
      for(int j = 0; j < i; j++)
    8000645e:	4785                	li	a5,1
    80006460:	0297d163          	bge	a5,s1,80006482 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006464:	f9442503          	lw	a0,-108(s0)
    80006468:	00000097          	auipc	ra,0x0
    8000646c:	d7e080e7          	jalr	-642(ra) # 800061e6 <free_desc>
      for(int j = 0; j < i; j++)
    80006470:	4789                	li	a5,2
    80006472:	0097d863          	bge	a5,s1,80006482 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006476:	f9842503          	lw	a0,-104(s0)
    8000647a:	00000097          	auipc	ra,0x0
    8000647e:	d6c080e7          	jalr	-660(ra) # 800061e6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006482:	00024597          	auipc	a1,0x24
    80006486:	ca658593          	addi	a1,a1,-858 # 8002a128 <disk+0x2128>
    8000648a:	00024517          	auipc	a0,0x24
    8000648e:	b8e50513          	addi	a0,a0,-1138 # 8002a018 <disk+0x2018>
    80006492:	ffffc097          	auipc	ra,0xffffc
    80006496:	132080e7          	jalr	306(ra) # 800025c4 <sleep>
  for(int i = 0; i < 3; i++){
    8000649a:	f9040713          	addi	a4,s0,-112
    8000649e:	84ce                	mv	s1,s3
    800064a0:	bf41                	j	80006430 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800064a2:	20058713          	addi	a4,a1,512
    800064a6:	00471693          	slli	a3,a4,0x4
    800064aa:	00022717          	auipc	a4,0x22
    800064ae:	b5670713          	addi	a4,a4,-1194 # 80028000 <disk>
    800064b2:	9736                	add	a4,a4,a3
    800064b4:	4685                	li	a3,1
    800064b6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800064ba:	20058713          	addi	a4,a1,512
    800064be:	00471693          	slli	a3,a4,0x4
    800064c2:	00022717          	auipc	a4,0x22
    800064c6:	b3e70713          	addi	a4,a4,-1218 # 80028000 <disk>
    800064ca:	9736                	add	a4,a4,a3
    800064cc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800064d0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800064d4:	7679                	lui	a2,0xffffe
    800064d6:	963e                	add	a2,a2,a5
    800064d8:	00024697          	auipc	a3,0x24
    800064dc:	b2868693          	addi	a3,a3,-1240 # 8002a000 <disk+0x2000>
    800064e0:	6298                	ld	a4,0(a3)
    800064e2:	9732                	add	a4,a4,a2
    800064e4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800064e6:	6298                	ld	a4,0(a3)
    800064e8:	9732                	add	a4,a4,a2
    800064ea:	4541                	li	a0,16
    800064ec:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800064ee:	6298                	ld	a4,0(a3)
    800064f0:	9732                	add	a4,a4,a2
    800064f2:	4505                	li	a0,1
    800064f4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800064f8:	f9442703          	lw	a4,-108(s0)
    800064fc:	6288                	ld	a0,0(a3)
    800064fe:	962a                	add	a2,a2,a0
    80006500:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd1fe6>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006504:	0712                	slli	a4,a4,0x4
    80006506:	6290                	ld	a2,0(a3)
    80006508:	963a                	add	a2,a2,a4
    8000650a:	06090513          	addi	a0,s2,96
    8000650e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006510:	6294                	ld	a3,0(a3)
    80006512:	96ba                	add	a3,a3,a4
    80006514:	40000613          	li	a2,1024
    80006518:	c690                	sw	a2,8(a3)
  if(write)
    8000651a:	140d0063          	beqz	s10,8000665a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000651e:	00024697          	auipc	a3,0x24
    80006522:	ae26b683          	ld	a3,-1310(a3) # 8002a000 <disk+0x2000>
    80006526:	96ba                	add	a3,a3,a4
    80006528:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000652c:	00022817          	auipc	a6,0x22
    80006530:	ad480813          	addi	a6,a6,-1324 # 80028000 <disk>
    80006534:	00024517          	auipc	a0,0x24
    80006538:	acc50513          	addi	a0,a0,-1332 # 8002a000 <disk+0x2000>
    8000653c:	6114                	ld	a3,0(a0)
    8000653e:	96ba                	add	a3,a3,a4
    80006540:	00c6d603          	lhu	a2,12(a3)
    80006544:	00166613          	ori	a2,a2,1
    80006548:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000654c:	f9842683          	lw	a3,-104(s0)
    80006550:	6110                	ld	a2,0(a0)
    80006552:	9732                	add	a4,a4,a2
    80006554:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006558:	20058613          	addi	a2,a1,512
    8000655c:	0612                	slli	a2,a2,0x4
    8000655e:	9642                	add	a2,a2,a6
    80006560:	577d                	li	a4,-1
    80006562:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006566:	00469713          	slli	a4,a3,0x4
    8000656a:	6114                	ld	a3,0(a0)
    8000656c:	96ba                	add	a3,a3,a4
    8000656e:	03078793          	addi	a5,a5,48
    80006572:	97c2                	add	a5,a5,a6
    80006574:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006576:	611c                	ld	a5,0(a0)
    80006578:	97ba                	add	a5,a5,a4
    8000657a:	4685                	li	a3,1
    8000657c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000657e:	611c                	ld	a5,0(a0)
    80006580:	97ba                	add	a5,a5,a4
    80006582:	4809                	li	a6,2
    80006584:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006588:	611c                	ld	a5,0(a0)
    8000658a:	973e                	add	a4,a4,a5
    8000658c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006590:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006594:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006598:	6518                	ld	a4,8(a0)
    8000659a:	00275783          	lhu	a5,2(a4)
    8000659e:	8b9d                	andi	a5,a5,7
    800065a0:	0786                	slli	a5,a5,0x1
    800065a2:	97ba                	add	a5,a5,a4
    800065a4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800065a8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800065ac:	6518                	ld	a4,8(a0)
    800065ae:	00275783          	lhu	a5,2(a4)
    800065b2:	2785                	addiw	a5,a5,1
    800065b4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800065b8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800065bc:	100017b7          	lui	a5,0x10001
    800065c0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800065c4:	00492703          	lw	a4,4(s2)
    800065c8:	4785                	li	a5,1
    800065ca:	02f71163          	bne	a4,a5,800065ec <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800065ce:	00024997          	auipc	s3,0x24
    800065d2:	b5a98993          	addi	s3,s3,-1190 # 8002a128 <disk+0x2128>
  while(b->disk == 1) {
    800065d6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800065d8:	85ce                	mv	a1,s3
    800065da:	854a                	mv	a0,s2
    800065dc:	ffffc097          	auipc	ra,0xffffc
    800065e0:	fe8080e7          	jalr	-24(ra) # 800025c4 <sleep>
  while(b->disk == 1) {
    800065e4:	00492783          	lw	a5,4(s2)
    800065e8:	fe9788e3          	beq	a5,s1,800065d8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800065ec:	f9042903          	lw	s2,-112(s0)
    800065f0:	20090793          	addi	a5,s2,512
    800065f4:	00479713          	slli	a4,a5,0x4
    800065f8:	00022797          	auipc	a5,0x22
    800065fc:	a0878793          	addi	a5,a5,-1528 # 80028000 <disk>
    80006600:	97ba                	add	a5,a5,a4
    80006602:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006606:	00024997          	auipc	s3,0x24
    8000660a:	9fa98993          	addi	s3,s3,-1542 # 8002a000 <disk+0x2000>
    8000660e:	00491713          	slli	a4,s2,0x4
    80006612:	0009b783          	ld	a5,0(s3)
    80006616:	97ba                	add	a5,a5,a4
    80006618:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000661c:	854a                	mv	a0,s2
    8000661e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006622:	00000097          	auipc	ra,0x0
    80006626:	bc4080e7          	jalr	-1084(ra) # 800061e6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000662a:	8885                	andi	s1,s1,1
    8000662c:	f0ed                	bnez	s1,8000660e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000662e:	00024517          	auipc	a0,0x24
    80006632:	afa50513          	addi	a0,a0,-1286 # 8002a128 <disk+0x2128>
    80006636:	ffffb097          	auipc	ra,0xffffb
    8000663a:	806080e7          	jalr	-2042(ra) # 80000e3c <release>
}
    8000663e:	70a6                	ld	ra,104(sp)
    80006640:	7406                	ld	s0,96(sp)
    80006642:	64e6                	ld	s1,88(sp)
    80006644:	6946                	ld	s2,80(sp)
    80006646:	69a6                	ld	s3,72(sp)
    80006648:	6a06                	ld	s4,64(sp)
    8000664a:	7ae2                	ld	s5,56(sp)
    8000664c:	7b42                	ld	s6,48(sp)
    8000664e:	7ba2                	ld	s7,40(sp)
    80006650:	7c02                	ld	s8,32(sp)
    80006652:	6ce2                	ld	s9,24(sp)
    80006654:	6d42                	ld	s10,16(sp)
    80006656:	6165                	addi	sp,sp,112
    80006658:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000665a:	00024697          	auipc	a3,0x24
    8000665e:	9a66b683          	ld	a3,-1626(a3) # 8002a000 <disk+0x2000>
    80006662:	96ba                	add	a3,a3,a4
    80006664:	4609                	li	a2,2
    80006666:	00c69623          	sh	a2,12(a3)
    8000666a:	b5c9                	j	8000652c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000666c:	f9042583          	lw	a1,-112(s0)
    80006670:	20058793          	addi	a5,a1,512
    80006674:	0792                	slli	a5,a5,0x4
    80006676:	00022517          	auipc	a0,0x22
    8000667a:	a3250513          	addi	a0,a0,-1486 # 800280a8 <disk+0xa8>
    8000667e:	953e                	add	a0,a0,a5
  if(write)
    80006680:	e20d11e3          	bnez	s10,800064a2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006684:	20058713          	addi	a4,a1,512
    80006688:	00471693          	slli	a3,a4,0x4
    8000668c:	00022717          	auipc	a4,0x22
    80006690:	97470713          	addi	a4,a4,-1676 # 80028000 <disk>
    80006694:	9736                	add	a4,a4,a3
    80006696:	0a072423          	sw	zero,168(a4)
    8000669a:	b505                	j	800064ba <virtio_disk_rw+0xf4>

000000008000669c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000669c:	1101                	addi	sp,sp,-32
    8000669e:	ec06                	sd	ra,24(sp)
    800066a0:	e822                	sd	s0,16(sp)
    800066a2:	e426                	sd	s1,8(sp)
    800066a4:	e04a                	sd	s2,0(sp)
    800066a6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800066a8:	00024517          	auipc	a0,0x24
    800066ac:	a8050513          	addi	a0,a0,-1408 # 8002a128 <disk+0x2128>
    800066b0:	ffffa097          	auipc	ra,0xffffa
    800066b4:	6bc080e7          	jalr	1724(ra) # 80000d6c <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800066b8:	10001737          	lui	a4,0x10001
    800066bc:	533c                	lw	a5,96(a4)
    800066be:	8b8d                	andi	a5,a5,3
    800066c0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800066c2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800066c6:	00024797          	auipc	a5,0x24
    800066ca:	93a78793          	addi	a5,a5,-1734 # 8002a000 <disk+0x2000>
    800066ce:	6b94                	ld	a3,16(a5)
    800066d0:	0207d703          	lhu	a4,32(a5)
    800066d4:	0026d783          	lhu	a5,2(a3)
    800066d8:	06f70163          	beq	a4,a5,8000673a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800066dc:	00022917          	auipc	s2,0x22
    800066e0:	92490913          	addi	s2,s2,-1756 # 80028000 <disk>
    800066e4:	00024497          	auipc	s1,0x24
    800066e8:	91c48493          	addi	s1,s1,-1764 # 8002a000 <disk+0x2000>
    __sync_synchronize();
    800066ec:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800066f0:	6898                	ld	a4,16(s1)
    800066f2:	0204d783          	lhu	a5,32(s1)
    800066f6:	8b9d                	andi	a5,a5,7
    800066f8:	078e                	slli	a5,a5,0x3
    800066fa:	97ba                	add	a5,a5,a4
    800066fc:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800066fe:	20078713          	addi	a4,a5,512
    80006702:	0712                	slli	a4,a4,0x4
    80006704:	974a                	add	a4,a4,s2
    80006706:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000670a:	e731                	bnez	a4,80006756 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000670c:	20078793          	addi	a5,a5,512
    80006710:	0792                	slli	a5,a5,0x4
    80006712:	97ca                	add	a5,a5,s2
    80006714:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006716:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000671a:	ffffc097          	auipc	ra,0xffffc
    8000671e:	030080e7          	jalr	48(ra) # 8000274a <wakeup>

    disk.used_idx += 1;
    80006722:	0204d783          	lhu	a5,32(s1)
    80006726:	2785                	addiw	a5,a5,1
    80006728:	17c2                	slli	a5,a5,0x30
    8000672a:	93c1                	srli	a5,a5,0x30
    8000672c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006730:	6898                	ld	a4,16(s1)
    80006732:	00275703          	lhu	a4,2(a4)
    80006736:	faf71be3          	bne	a4,a5,800066ec <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000673a:	00024517          	auipc	a0,0x24
    8000673e:	9ee50513          	addi	a0,a0,-1554 # 8002a128 <disk+0x2128>
    80006742:	ffffa097          	auipc	ra,0xffffa
    80006746:	6fa080e7          	jalr	1786(ra) # 80000e3c <release>
}
    8000674a:	60e2                	ld	ra,24(sp)
    8000674c:	6442                	ld	s0,16(sp)
    8000674e:	64a2                	ld	s1,8(sp)
    80006750:	6902                	ld	s2,0(sp)
    80006752:	6105                	addi	sp,sp,32
    80006754:	8082                	ret
      panic("virtio_disk_intr status");
    80006756:	00002517          	auipc	a0,0x2
    8000675a:	14250513          	addi	a0,a0,322 # 80008898 <syscalls+0x3c8>
    8000675e:	ffffa097          	auipc	ra,0xffffa
    80006762:	df2080e7          	jalr	-526(ra) # 80000550 <panic>

0000000080006766 <statswrite>:
int statscopyin(char*, int);
int statslock(char*, int);
  
int
statswrite(int user_src, uint64 src, int n)
{
    80006766:	1141                	addi	sp,sp,-16
    80006768:	e422                	sd	s0,8(sp)
    8000676a:	0800                	addi	s0,sp,16
  return -1;
}
    8000676c:	557d                	li	a0,-1
    8000676e:	6422                	ld	s0,8(sp)
    80006770:	0141                	addi	sp,sp,16
    80006772:	8082                	ret

0000000080006774 <statsread>:

int
statsread(int user_dst, uint64 dst, int n)
{
    80006774:	7179                	addi	sp,sp,-48
    80006776:	f406                	sd	ra,40(sp)
    80006778:	f022                	sd	s0,32(sp)
    8000677a:	ec26                	sd	s1,24(sp)
    8000677c:	e84a                	sd	s2,16(sp)
    8000677e:	e44e                	sd	s3,8(sp)
    80006780:	e052                	sd	s4,0(sp)
    80006782:	1800                	addi	s0,sp,48
    80006784:	892a                	mv	s2,a0
    80006786:	89ae                	mv	s3,a1
    80006788:	84b2                	mv	s1,a2
  int m;

  acquire(&stats.lock);
    8000678a:	00025517          	auipc	a0,0x25
    8000678e:	87650513          	addi	a0,a0,-1930 # 8002b000 <stats>
    80006792:	ffffa097          	auipc	ra,0xffffa
    80006796:	5da080e7          	jalr	1498(ra) # 80000d6c <acquire>

  if(stats.sz == 0) {
    8000679a:	00026797          	auipc	a5,0x26
    8000679e:	8867a783          	lw	a5,-1914(a5) # 8002c020 <stats+0x1020>
    800067a2:	cbb5                	beqz	a5,80006816 <statsread+0xa2>
#endif
#ifdef LAB_LOCK
    stats.sz = statslock(stats.buf, BUFSZ);
#endif
  }
  m = stats.sz - stats.off;
    800067a4:	00026797          	auipc	a5,0x26
    800067a8:	85c78793          	addi	a5,a5,-1956 # 8002c000 <stats+0x1000>
    800067ac:	53d8                	lw	a4,36(a5)
    800067ae:	539c                	lw	a5,32(a5)
    800067b0:	9f99                	subw	a5,a5,a4
    800067b2:	0007869b          	sext.w	a3,a5

  if (m > 0) {
    800067b6:	06d05e63          	blez	a3,80006832 <statsread+0xbe>
    if(m > n)
    800067ba:	8a3e                	mv	s4,a5
    800067bc:	00d4d363          	bge	s1,a3,800067c2 <statsread+0x4e>
    800067c0:	8a26                	mv	s4,s1
    800067c2:	000a049b          	sext.w	s1,s4
      m  = n;
    if(either_copyout(user_dst, dst, stats.buf+stats.off, m) != -1) {
    800067c6:	86a6                	mv	a3,s1
    800067c8:	00025617          	auipc	a2,0x25
    800067cc:	85860613          	addi	a2,a2,-1960 # 8002b020 <stats+0x20>
    800067d0:	963a                	add	a2,a2,a4
    800067d2:	85ce                	mv	a1,s3
    800067d4:	854a                	mv	a0,s2
    800067d6:	ffffc097          	auipc	ra,0xffffc
    800067da:	050080e7          	jalr	80(ra) # 80002826 <either_copyout>
    800067de:	57fd                	li	a5,-1
    800067e0:	00f50a63          	beq	a0,a5,800067f4 <statsread+0x80>
      stats.off += m;
    800067e4:	00026717          	auipc	a4,0x26
    800067e8:	81c70713          	addi	a4,a4,-2020 # 8002c000 <stats+0x1000>
    800067ec:	535c                	lw	a5,36(a4)
    800067ee:	014787bb          	addw	a5,a5,s4
    800067f2:	d35c                	sw	a5,36(a4)
  } else {
    m = -1;
    stats.sz = 0;
    stats.off = 0;
  }
  release(&stats.lock);
    800067f4:	00025517          	auipc	a0,0x25
    800067f8:	80c50513          	addi	a0,a0,-2036 # 8002b000 <stats>
    800067fc:	ffffa097          	auipc	ra,0xffffa
    80006800:	640080e7          	jalr	1600(ra) # 80000e3c <release>
  return m;
}
    80006804:	8526                	mv	a0,s1
    80006806:	70a2                	ld	ra,40(sp)
    80006808:	7402                	ld	s0,32(sp)
    8000680a:	64e2                	ld	s1,24(sp)
    8000680c:	6942                	ld	s2,16(sp)
    8000680e:	69a2                	ld	s3,8(sp)
    80006810:	6a02                	ld	s4,0(sp)
    80006812:	6145                	addi	sp,sp,48
    80006814:	8082                	ret
    stats.sz = statslock(stats.buf, BUFSZ);
    80006816:	6585                	lui	a1,0x1
    80006818:	00025517          	auipc	a0,0x25
    8000681c:	80850513          	addi	a0,a0,-2040 # 8002b020 <stats+0x20>
    80006820:	ffffa097          	auipc	ra,0xffffa
    80006824:	776080e7          	jalr	1910(ra) # 80000f96 <statslock>
    80006828:	00025797          	auipc	a5,0x25
    8000682c:	7ea7ac23          	sw	a0,2040(a5) # 8002c020 <stats+0x1020>
    80006830:	bf95                	j	800067a4 <statsread+0x30>
    stats.sz = 0;
    80006832:	00025797          	auipc	a5,0x25
    80006836:	7ce78793          	addi	a5,a5,1998 # 8002c000 <stats+0x1000>
    8000683a:	0207a023          	sw	zero,32(a5)
    stats.off = 0;
    8000683e:	0207a223          	sw	zero,36(a5)
    m = -1;
    80006842:	54fd                	li	s1,-1
    80006844:	bf45                	j	800067f4 <statsread+0x80>

0000000080006846 <statsinit>:

void
statsinit(void)
{
    80006846:	1141                	addi	sp,sp,-16
    80006848:	e406                	sd	ra,8(sp)
    8000684a:	e022                	sd	s0,0(sp)
    8000684c:	0800                	addi	s0,sp,16
  initlock(&stats.lock, "stats");
    8000684e:	00002597          	auipc	a1,0x2
    80006852:	06258593          	addi	a1,a1,98 # 800088b0 <syscalls+0x3e0>
    80006856:	00024517          	auipc	a0,0x24
    8000685a:	7aa50513          	addi	a0,a0,1962 # 8002b000 <stats>
    8000685e:	ffffa097          	auipc	ra,0xffffa
    80006862:	68a080e7          	jalr	1674(ra) # 80000ee8 <initlock>

  devsw[STATS].read = statsread;
    80006866:	0001f797          	auipc	a5,0x1f
    8000686a:	7aa78793          	addi	a5,a5,1962 # 80026010 <devsw>
    8000686e:	00000717          	auipc	a4,0x0
    80006872:	f0670713          	addi	a4,a4,-250 # 80006774 <statsread>
    80006876:	f398                	sd	a4,32(a5)
  devsw[STATS].write = statswrite;
    80006878:	00000717          	auipc	a4,0x0
    8000687c:	eee70713          	addi	a4,a4,-274 # 80006766 <statswrite>
    80006880:	f798                	sd	a4,40(a5)
}
    80006882:	60a2                	ld	ra,8(sp)
    80006884:	6402                	ld	s0,0(sp)
    80006886:	0141                	addi	sp,sp,16
    80006888:	8082                	ret

000000008000688a <sprintint>:
  return 1;
}

static int
sprintint(char *s, int xx, int base, int sign)
{
    8000688a:	1101                	addi	sp,sp,-32
    8000688c:	ec22                	sd	s0,24(sp)
    8000688e:	1000                	addi	s0,sp,32
    80006890:	882a                	mv	a6,a0
  char buf[16];
  int i, n;
  uint x;

  if(sign && (sign = xx < 0))
    80006892:	c299                	beqz	a3,80006898 <sprintint+0xe>
    80006894:	0805c163          	bltz	a1,80006916 <sprintint+0x8c>
    x = -xx;
  else
    x = xx;
    80006898:	2581                	sext.w	a1,a1
    8000689a:	4301                	li	t1,0

  i = 0;
    8000689c:	fe040713          	addi	a4,s0,-32
    800068a0:	4501                	li	a0,0
  do {
    buf[i++] = digits[x % base];
    800068a2:	2601                	sext.w	a2,a2
    800068a4:	00002697          	auipc	a3,0x2
    800068a8:	01468693          	addi	a3,a3,20 # 800088b8 <digits>
    800068ac:	88aa                	mv	a7,a0
    800068ae:	2505                	addiw	a0,a0,1
    800068b0:	02c5f7bb          	remuw	a5,a1,a2
    800068b4:	1782                	slli	a5,a5,0x20
    800068b6:	9381                	srli	a5,a5,0x20
    800068b8:	97b6                	add	a5,a5,a3
    800068ba:	0007c783          	lbu	a5,0(a5)
    800068be:	00f70023          	sb	a5,0(a4)
  } while((x /= base) != 0);
    800068c2:	0005879b          	sext.w	a5,a1
    800068c6:	02c5d5bb          	divuw	a1,a1,a2
    800068ca:	0705                	addi	a4,a4,1
    800068cc:	fec7f0e3          	bgeu	a5,a2,800068ac <sprintint+0x22>

  if(sign)
    800068d0:	00030b63          	beqz	t1,800068e6 <sprintint+0x5c>
    buf[i++] = '-';
    800068d4:	ff040793          	addi	a5,s0,-16
    800068d8:	97aa                	add	a5,a5,a0
    800068da:	02d00713          	li	a4,45
    800068de:	fee78823          	sb	a4,-16(a5)
    800068e2:	0028851b          	addiw	a0,a7,2

  n = 0;
  while(--i >= 0)
    800068e6:	02a05c63          	blez	a0,8000691e <sprintint+0x94>
    800068ea:	fe040793          	addi	a5,s0,-32
    800068ee:	00a78733          	add	a4,a5,a0
    800068f2:	87c2                	mv	a5,a6
    800068f4:	0805                	addi	a6,a6,1
    800068f6:	fff5061b          	addiw	a2,a0,-1
    800068fa:	1602                	slli	a2,a2,0x20
    800068fc:	9201                	srli	a2,a2,0x20
    800068fe:	9642                	add	a2,a2,a6
  *s = c;
    80006900:	fff74683          	lbu	a3,-1(a4)
    80006904:	00d78023          	sb	a3,0(a5)
  while(--i >= 0)
    80006908:	177d                	addi	a4,a4,-1
    8000690a:	0785                	addi	a5,a5,1
    8000690c:	fec79ae3          	bne	a5,a2,80006900 <sprintint+0x76>
    n += sputc(s+n, buf[i]);
  return n;
}
    80006910:	6462                	ld	s0,24(sp)
    80006912:	6105                	addi	sp,sp,32
    80006914:	8082                	ret
    x = -xx;
    80006916:	40b005bb          	negw	a1,a1
  if(sign && (sign = xx < 0))
    8000691a:	4305                	li	t1,1
    x = -xx;
    8000691c:	b741                	j	8000689c <sprintint+0x12>
  while(--i >= 0)
    8000691e:	4501                	li	a0,0
    80006920:	bfc5                	j	80006910 <sprintint+0x86>

0000000080006922 <snprintf>:

int
snprintf(char *buf, int sz, char *fmt, ...)
{
    80006922:	7171                	addi	sp,sp,-176
    80006924:	fc86                	sd	ra,120(sp)
    80006926:	f8a2                	sd	s0,112(sp)
    80006928:	f4a6                	sd	s1,104(sp)
    8000692a:	f0ca                	sd	s2,96(sp)
    8000692c:	ecce                	sd	s3,88(sp)
    8000692e:	e8d2                	sd	s4,80(sp)
    80006930:	e4d6                	sd	s5,72(sp)
    80006932:	e0da                	sd	s6,64(sp)
    80006934:	fc5e                	sd	s7,56(sp)
    80006936:	f862                	sd	s8,48(sp)
    80006938:	f466                	sd	s9,40(sp)
    8000693a:	f06a                	sd	s10,32(sp)
    8000693c:	ec6e                	sd	s11,24(sp)
    8000693e:	0100                	addi	s0,sp,128
    80006940:	e414                	sd	a3,8(s0)
    80006942:	e818                	sd	a4,16(s0)
    80006944:	ec1c                	sd	a5,24(s0)
    80006946:	03043023          	sd	a6,32(s0)
    8000694a:	03143423          	sd	a7,40(s0)
  va_list ap;
  int i, c;
  int off = 0;
  char *s;

  if (fmt == 0)
    8000694e:	ca0d                	beqz	a2,80006980 <snprintf+0x5e>
    80006950:	8baa                	mv	s7,a0
    80006952:	89ae                	mv	s3,a1
    80006954:	8a32                	mv	s4,a2
    panic("null fmt");

  va_start(ap, fmt);
    80006956:	00840793          	addi	a5,s0,8
    8000695a:	f8f43423          	sd	a5,-120(s0)
  int off = 0;
    8000695e:	4481                	li	s1,0
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    80006960:	4901                	li	s2,0
    80006962:	02b05763          	blez	a1,80006990 <snprintf+0x6e>
    if(c != '%'){
    80006966:	02500a93          	li	s5,37
      continue;
    }
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
    switch(c){
    8000696a:	07300b13          	li	s6,115
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
      break;
    case 's':
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s && off < sz; s++)
    8000696e:	02800d93          	li	s11,40
  *s = c;
    80006972:	02500d13          	li	s10,37
    switch(c){
    80006976:	07800c93          	li	s9,120
    8000697a:	06400c13          	li	s8,100
    8000697e:	a01d                	j	800069a4 <snprintf+0x82>
    panic("null fmt");
    80006980:	00001517          	auipc	a0,0x1
    80006984:	6a850513          	addi	a0,a0,1704 # 80008028 <etext+0x28>
    80006988:	ffffa097          	auipc	ra,0xffffa
    8000698c:	bc8080e7          	jalr	-1080(ra) # 80000550 <panic>
  int off = 0;
    80006990:	4481                	li	s1,0
    80006992:	a86d                	j	80006a4c <snprintf+0x12a>
  *s = c;
    80006994:	009b8733          	add	a4,s7,s1
    80006998:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    8000699c:	2485                	addiw	s1,s1,1
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    8000699e:	2905                	addiw	s2,s2,1
    800069a0:	0b34d663          	bge	s1,s3,80006a4c <snprintf+0x12a>
    800069a4:	012a07b3          	add	a5,s4,s2
    800069a8:	0007c783          	lbu	a5,0(a5)
    800069ac:	0007871b          	sext.w	a4,a5
    800069b0:	cfd1                	beqz	a5,80006a4c <snprintf+0x12a>
    if(c != '%'){
    800069b2:	ff5711e3          	bne	a4,s5,80006994 <snprintf+0x72>
    c = fmt[++i] & 0xff;
    800069b6:	2905                	addiw	s2,s2,1
    800069b8:	012a07b3          	add	a5,s4,s2
    800069bc:	0007c783          	lbu	a5,0(a5)
    if(c == 0)
    800069c0:	c7d1                	beqz	a5,80006a4c <snprintf+0x12a>
    switch(c){
    800069c2:	05678c63          	beq	a5,s6,80006a1a <snprintf+0xf8>
    800069c6:	02fb6763          	bltu	s6,a5,800069f4 <snprintf+0xd2>
    800069ca:	0b578763          	beq	a5,s5,80006a78 <snprintf+0x156>
    800069ce:	0b879b63          	bne	a5,s8,80006a84 <snprintf+0x162>
      off += sprintint(buf+off, va_arg(ap, int), 10, 1);
    800069d2:	f8843783          	ld	a5,-120(s0)
    800069d6:	00878713          	addi	a4,a5,8
    800069da:	f8e43423          	sd	a4,-120(s0)
    800069de:	4685                	li	a3,1
    800069e0:	4629                	li	a2,10
    800069e2:	438c                	lw	a1,0(a5)
    800069e4:	009b8533          	add	a0,s7,s1
    800069e8:	00000097          	auipc	ra,0x0
    800069ec:	ea2080e7          	jalr	-350(ra) # 8000688a <sprintint>
    800069f0:	9ca9                	addw	s1,s1,a0
      break;
    800069f2:	b775                	j	8000699e <snprintf+0x7c>
    switch(c){
    800069f4:	09979863          	bne	a5,s9,80006a84 <snprintf+0x162>
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
    800069f8:	f8843783          	ld	a5,-120(s0)
    800069fc:	00878713          	addi	a4,a5,8
    80006a00:	f8e43423          	sd	a4,-120(s0)
    80006a04:	4685                	li	a3,1
    80006a06:	4641                	li	a2,16
    80006a08:	438c                	lw	a1,0(a5)
    80006a0a:	009b8533          	add	a0,s7,s1
    80006a0e:	00000097          	auipc	ra,0x0
    80006a12:	e7c080e7          	jalr	-388(ra) # 8000688a <sprintint>
    80006a16:	9ca9                	addw	s1,s1,a0
      break;
    80006a18:	b759                	j	8000699e <snprintf+0x7c>
      if((s = va_arg(ap, char*)) == 0)
    80006a1a:	f8843783          	ld	a5,-120(s0)
    80006a1e:	00878713          	addi	a4,a5,8
    80006a22:	f8e43423          	sd	a4,-120(s0)
    80006a26:	639c                	ld	a5,0(a5)
    80006a28:	c3b1                	beqz	a5,80006a6c <snprintf+0x14a>
      for(; *s && off < sz; s++)
    80006a2a:	0007c703          	lbu	a4,0(a5)
    80006a2e:	db25                	beqz	a4,8000699e <snprintf+0x7c>
    80006a30:	0134de63          	bge	s1,s3,80006a4c <snprintf+0x12a>
    80006a34:	009b86b3          	add	a3,s7,s1
  *s = c;
    80006a38:	00e68023          	sb	a4,0(a3)
        off += sputc(buf+off, *s);
    80006a3c:	2485                	addiw	s1,s1,1
      for(; *s && off < sz; s++)
    80006a3e:	0785                	addi	a5,a5,1
    80006a40:	0007c703          	lbu	a4,0(a5)
    80006a44:	df29                	beqz	a4,8000699e <snprintf+0x7c>
    80006a46:	0685                	addi	a3,a3,1
    80006a48:	fe9998e3          	bne	s3,s1,80006a38 <snprintf+0x116>
      off += sputc(buf+off, c);
      break;
    }
  }
  return off;
}
    80006a4c:	8526                	mv	a0,s1
    80006a4e:	70e6                	ld	ra,120(sp)
    80006a50:	7446                	ld	s0,112(sp)
    80006a52:	74a6                	ld	s1,104(sp)
    80006a54:	7906                	ld	s2,96(sp)
    80006a56:	69e6                	ld	s3,88(sp)
    80006a58:	6a46                	ld	s4,80(sp)
    80006a5a:	6aa6                	ld	s5,72(sp)
    80006a5c:	6b06                	ld	s6,64(sp)
    80006a5e:	7be2                	ld	s7,56(sp)
    80006a60:	7c42                	ld	s8,48(sp)
    80006a62:	7ca2                	ld	s9,40(sp)
    80006a64:	7d02                	ld	s10,32(sp)
    80006a66:	6de2                	ld	s11,24(sp)
    80006a68:	614d                	addi	sp,sp,176
    80006a6a:	8082                	ret
        s = "(null)";
    80006a6c:	00001797          	auipc	a5,0x1
    80006a70:	5b478793          	addi	a5,a5,1460 # 80008020 <etext+0x20>
      for(; *s && off < sz; s++)
    80006a74:	876e                	mv	a4,s11
    80006a76:	bf6d                	j	80006a30 <snprintf+0x10e>
  *s = c;
    80006a78:	009b87b3          	add	a5,s7,s1
    80006a7c:	01a78023          	sb	s10,0(a5)
      off += sputc(buf+off, '%');
    80006a80:	2485                	addiw	s1,s1,1
      break;
    80006a82:	bf31                	j	8000699e <snprintf+0x7c>
  *s = c;
    80006a84:	009b8733          	add	a4,s7,s1
    80006a88:	01a70023          	sb	s10,0(a4)
      off += sputc(buf+off, c);
    80006a8c:	0014871b          	addiw	a4,s1,1
  *s = c;
    80006a90:	975e                	add	a4,a4,s7
    80006a92:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    80006a96:	2489                	addiw	s1,s1,2
      break;
    80006a98:	b719                	j	8000699e <snprintf+0x7c>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
