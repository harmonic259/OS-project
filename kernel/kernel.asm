
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	b7010113          	addi	sp,sp,-1168 # 80008b70 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
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
    80000056:	9de70713          	addi	a4,a4,-1570 # 80008a30 <timer_scratch>
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
    80000068:	25c78793          	addi	a5,a5,604 # 800062c0 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc097>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	18a78793          	addi	a5,a5,394 # 80001238 <main>
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
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	746080e7          	jalr	1862(ra) # 80002872 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00001097          	auipc	ra,0x1
    80000140:	b40080e7          	jalr	-1216(ra) # 80000c7c <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	9e650513          	addi	a0,a0,-1562 # 80010b70 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	e04080e7          	jalr	-508(ra) # 80000f96 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	9d648493          	addi	s1,s1,-1578 # 80010b70 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	a6690913          	addi	s2,s2,-1434 # 80010c08 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	bac080e7          	jalr	-1108(ra) # 80001d6c <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	4f4080e7          	jalr	1268(ra) # 800026bc <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	23e080e7          	jalr	574(ra) # 80002414 <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	60a080e7          	jalr	1546(ra) # 8000281c <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	94a50513          	addi	a0,a0,-1718 # 80010b70 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	e1c080e7          	jalr	-484(ra) # 8000104a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	93450513          	addi	a0,a0,-1740 # 80010b70 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	e06080e7          	jalr	-506(ra) # 8000104a <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	98f72b23          	sw	a5,-1642(a4) # 80010c08 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00001097          	auipc	ra,0x1
    80000290:	91e080e7          	jalr	-1762(ra) # 80000baa <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00001097          	auipc	ra,0x1
    800002a2:	90c080e7          	jalr	-1780(ra) # 80000baa <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00001097          	auipc	ra,0x1
    800002ae:	900080e7          	jalr	-1792(ra) # 80000baa <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00001097          	auipc	ra,0x1
    800002b8:	8f6080e7          	jalr	-1802(ra) # 80000baa <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <saveCommand>:
void saveCommand() {
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec22                	sd	s0,24(sp)
    800002c2:	1000                	addi	s0,sp,32
    char historyCommand[8] = {'h', 'i', 's', 't', 'o', 'r', 'y', '\0'};
    800002c4:	00008797          	auipc	a5,0x8
    800002c8:	d4c7b783          	ld	a5,-692(a5) # 80008010 <etext+0x10>
    800002cc:	fef43423          	sd	a5,-24(s0)
    commandLength--;
    800002d0:	00008517          	auipc	a0,0x8
    800002d4:	72052503          	lw	a0,1824(a0) # 800089f0 <commandLength>
    800002d8:	fff5089b          	addiw	a7,a0,-1
    800002dc:	0008831b          	sext.w	t1,a7
    for (int i = 0; i < 7; i++) {
    800002e0:	00011797          	auipc	a5,0x11
    800002e4:	18078793          	addi	a5,a5,384 # 80011460 <historyBuffer+0x848>
    800002e8:	fe840713          	addi	a4,s0,-24
    800002ec:	fef40813          	addi	a6,s0,-17
    commandLength--;
    800002f0:	86be                	mv	a3,a5
        if (historyBuffer.currentCommand[i] != historyCommand[i]) {
    800002f2:	0006c583          	lbu	a1,0(a3)
    800002f6:	00074603          	lbu	a2,0(a4)
    800002fa:	02c59363          	bne	a1,a2,80000320 <saveCommand+0x62>
    for (int i = 0; i < 7; i++) {
    800002fe:	0685                	addi	a3,a3,1
    80000300:	0705                	addi	a4,a4,1
    80000302:	ff0718e3          	bne	a4,a6,800002f2 <saveCommand+0x34>
    commandLength = 0;
    80000306:	00008797          	auipc	a5,0x8
    8000030a:	6e07a523          	sw	zero,1770(a5) # 800089f0 <commandLength>
}
    8000030e:	6462                	ld	s0,24(sp)
    80000310:	6105                	addi	sp,sp,32
    80000312:	8082                	ret
            historyBuffer.numOfCommandsInMem = 16;
    80000314:	4741                	li	a4,16
    80000316:	00011697          	auipc	a3,0x11
    8000031a:	14e6a323          	sw	a4,326(a3) # 8001145c <historyBuffer+0x844>
    8000031e:	a8ad                	j	80000398 <saveCommand+0xda>
        for (int i = 0; i < commandLength; i++) {
    80000320:	02605d63          	blez	t1,8000035a <saveCommand+0x9c>
    80000324:	ffe5071b          	addiw	a4,a0,-2
    80000328:	1702                	slli	a4,a4,0x20
    8000032a:	9301                	srli	a4,a4,0x20
    8000032c:	00011697          	auipc	a3,0x11
    80000330:	13568693          	addi	a3,a3,309 # 80011461 <historyBuffer+0x849>
    80000334:	9736                	add	a4,a4,a3
    80000336:	00011597          	auipc	a1,0x11
    8000033a:	1225e583          	lwu	a1,290(a1) # 80011458 <historyBuffer+0x840>
    8000033e:	059e                	slli	a1,a1,0x7
            historyBuffer.bufferArr[historyBuffer.lastCommandIndex][i] = historyBuffer.currentCommand[i];
    80000340:	76fd                	lui	a3,0xfffff
    80000342:	7b868693          	addi	a3,a3,1976 # fffffffffffff7b8 <end+0xffffffff7ffdd050>
    80000346:	95b6                	add	a1,a1,a3
    80000348:	0007c603          	lbu	a2,0(a5)
    8000034c:	00b786b3          	add	a3,a5,a1
    80000350:	00c68023          	sb	a2,0(a3)
        for (int i = 0; i < commandLength; i++) {
    80000354:	0785                	addi	a5,a5,1
    80000356:	fee799e3          	bne	a5,a4,80000348 <saveCommand+0x8a>
        historyBuffer.lengthArr[historyBuffer.lastCommandIndex] = commandLength;
    8000035a:	00012617          	auipc	a2,0x12
    8000035e:	8be60613          	addi	a2,a2,-1858 # 80011c18 <proc+0x290>
    80000362:	84062783          	lw	a5,-1984(a2)
    80000366:	02079713          	slli	a4,a5,0x20
    8000036a:	9301                	srli	a4,a4,0x20
    8000036c:	20070713          	addi	a4,a4,512
    80000370:	070a                	slli	a4,a4,0x2
    80000372:	00011697          	auipc	a3,0x11
    80000376:	8a668693          	addi	a3,a3,-1882 # 80010c18 <historyBuffer>
    8000037a:	9736                	add	a4,a4,a3
    8000037c:	01172023          	sw	a7,0(a4)
        historyBuffer.numOfCommandsInMem++;
    80000380:	84462703          	lw	a4,-1980(a2)
    80000384:	2705                	addiw	a4,a4,1
    80000386:	0007061b          	sext.w	a2,a4
        if (historyBuffer.numOfCommandsInMem > 16)
    8000038a:	46c1                	li	a3,16
    8000038c:	f8c6c4e3          	blt	a3,a2,80000314 <saveCommand+0x56>
        historyBuffer.numOfCommandsInMem++;
    80000390:	00011697          	auipc	a3,0x11
    80000394:	0ce6a623          	sw	a4,204(a3) # 8001145c <historyBuffer+0x844>
        historyBuffer.lastCommandIndex = (historyBuffer.lastCommandIndex + 1) % MAX_HISTORY;
    80000398:	2785                	addiw	a5,a5,1
    8000039a:	8bbd                	andi	a5,a5,15
    8000039c:	00011717          	auipc	a4,0x11
    800003a0:	0af72e23          	sw	a5,188(a4) # 80011458 <historyBuffer+0x840>
    800003a4:	b78d                	j	80000306 <saveCommand+0x48>

00000000800003a6 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800003a6:	711d                	addi	sp,sp,-96
    800003a8:	ec86                	sd	ra,88(sp)
    800003aa:	e8a2                	sd	s0,80(sp)
    800003ac:	e4a6                	sd	s1,72(sp)
    800003ae:	e0ca                	sd	s2,64(sp)
    800003b0:	fc4e                	sd	s3,56(sp)
    800003b2:	f852                	sd	s4,48(sp)
    800003b4:	f456                	sd	s5,40(sp)
    800003b6:	f05a                	sd	s6,32(sp)
    800003b8:	ec5e                	sd	s7,24(sp)
    800003ba:	e862                	sd	s8,16(sp)
    800003bc:	e466                	sd	s9,8(sp)
    800003be:	e06a                	sd	s10,0(sp)
    800003c0:	1080                	addi	s0,sp,96
    800003c2:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800003c4:	00010517          	auipc	a0,0x10
    800003c8:	7ac50513          	addi	a0,a0,1964 # 80010b70 <cons>
    800003cc:	00001097          	auipc	ra,0x1
    800003d0:	bca080e7          	jalr	-1078(ra) # 80000f96 <acquire>
  int index = 0;

  switch(c){
    800003d4:	47e5                	li	a5,25
    800003d6:	0297c763          	blt	a5,s1,80000404 <consoleintr+0x5e>
    800003da:	479d                	li	a5,7
    800003dc:	3a97dc63          	bge	a5,s1,80000794 <consoleintr+0x3ee>
    800003e0:	ff84879b          	addiw	a5,s1,-8
    800003e4:	0007869b          	sext.w	a3,a5
    800003e8:	4745                	li	a4,17
    800003ea:	3ad76563          	bltu	a4,a3,80000794 <consoleintr+0x3ee>
    800003ee:	1782                	slli	a5,a5,0x20
    800003f0:	9381                	srli	a5,a5,0x20
    800003f2:	078a                	slli	a5,a5,0x2
    800003f4:	00008717          	auipc	a4,0x8
    800003f8:	c2c70713          	addi	a4,a4,-980 # 80008020 <etext+0x20>
    800003fc:	97ba                	add	a5,a5,a4
    800003fe:	439c                	lw	a5,0(a5)
    80000400:	97ba                	add	a5,a5,a4
    80000402:	8782                	jr	a5
    80000404:	07f00793          	li	a5,127
    80000408:	34f48963          	beq	s1,a5,8000075a <consoleintr+0x3b4>
      consputc(BACKSPACE);
      commandLength--;
    }
    break;
  default:
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000040c:	00010717          	auipc	a4,0x10
    80000410:	76470713          	addi	a4,a4,1892 # 80010b70 <cons>
    80000414:	0a072783          	lw	a5,160(a4)
    80000418:	09872703          	lw	a4,152(a4)
    8000041c:	9f99                	subw	a5,a5,a4
    8000041e:	07f00713          	li	a4,127
    80000422:	24f76463          	bltu	a4,a5,8000066a <consoleintr+0x2c4>
      c = (c == '\r') ? '\n' : c;
    80000426:	47b5                	li	a5,13
    80000428:	36f48963          	beq	s1,a5,8000079a <consoleintr+0x3f4>

      // echo back to the user.
      consputc(c);
    8000042c:	8526                	mv	a0,s1
    8000042e:	00000097          	auipc	ra,0x0
    80000432:	e4e080e7          	jalr	-434(ra) # 8000027c <consputc>
      historyBuffer.currentCommand[commandLength] = c;
    80000436:	00008597          	auipc	a1,0x8
    8000043a:	5ba58593          	addi	a1,a1,1466 # 800089f0 <commandLength>
    8000043e:	419c                	lw	a5,0(a1)
    80000440:	0ff4f713          	andi	a4,s1,255
    80000444:	00010697          	auipc	a3,0x10
    80000448:	7d468693          	addi	a3,a3,2004 # 80010c18 <historyBuffer>
    8000044c:	00f68633          	add	a2,a3,a5
    80000450:	6685                	lui	a3,0x1
    80000452:	96b2                	add	a3,a3,a2
    80000454:	84e68423          	sb	a4,-1976(a3) # 848 <_entry-0x7ffff7b8>
      commandLength++;
    80000458:	2785                	addiw	a5,a5,1
    8000045a:	c19c                	sw	a5,0(a1)
      // store for consumption by consoleread().
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    8000045c:	00010797          	auipc	a5,0x10
    80000460:	71478793          	addi	a5,a5,1812 # 80010b70 <cons>
    80000464:	0a07a683          	lw	a3,160(a5)
    80000468:	0016861b          	addiw	a2,a3,1
    8000046c:	0ac7a023          	sw	a2,160(a5)
    80000470:	07f6f693          	andi	a3,a3,127
    80000474:	97b6                	add	a5,a5,a3
    80000476:	00e78c23          	sb	a4,24(a5)

      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000047a:	47a9                	li	a5,10
    8000047c:	36f48563          	beq	s1,a5,800007e6 <consoleintr+0x440>
    80000480:	4791                	li	a5,4
    80000482:	36f48263          	beq	s1,a5,800007e6 <consoleintr+0x440>
    80000486:	00010797          	auipc	a5,0x10
    8000048a:	7827a783          	lw	a5,1922(a5) # 80010c08 <cons+0x98>
    8000048e:	9e1d                	subw	a2,a2,a5
    80000490:	08000793          	li	a5,128
    80000494:	1cf61b63          	bne	a2,a5,8000066a <consoleintr+0x2c4>
    80000498:	a6b9                	j	800007e6 <consoleintr+0x440>
      while (cons.e != cons.w &&
    8000049a:	00010717          	auipc	a4,0x10
    8000049e:	6d670713          	addi	a4,a4,1750 # 80010b70 <cons>
    800004a2:	0a072783          	lw	a5,160(a4)
    800004a6:	09c72703          	lw	a4,156(a4)
              cons.buf[(cons.e - 1) % INPUT_BUF] != '\n') {
    800004aa:	00010497          	auipc	s1,0x10
    800004ae:	6c648493          	addi	s1,s1,1734 # 80010b70 <cons>
      while (cons.e != cons.w &&
    800004b2:	4929                	li	s2,10
    800004b4:	02f70863          	beq	a4,a5,800004e4 <consoleintr+0x13e>
              cons.buf[(cons.e - 1) % INPUT_BUF] != '\n') {
    800004b8:	37fd                	addiw	a5,a5,-1
    800004ba:	07f7f713          	andi	a4,a5,127
    800004be:	9726                	add	a4,a4,s1
      while (cons.e != cons.w &&
    800004c0:	01874703          	lbu	a4,24(a4)
    800004c4:	03270063          	beq	a4,s2,800004e4 <consoleintr+0x13e>
          cons.e--;
    800004c8:	0af4a023          	sw	a5,160(s1)
          consputc(BACKSPACE);
    800004cc:	10000513          	li	a0,256
    800004d0:	00000097          	auipc	ra,0x0
    800004d4:	dac080e7          	jalr	-596(ra) # 8000027c <consputc>
      while (cons.e != cons.w &&
    800004d8:	0a04a783          	lw	a5,160(s1)
    800004dc:	09c4a703          	lw	a4,156(s1)
    800004e0:	fcf71ce3          	bne	a4,a5,800004b8 <consoleintr+0x112>
      hist_index--;
    800004e4:	00008697          	auipc	a3,0x8
    800004e8:	4bc68693          	addi	a3,a3,1212 # 800089a0 <hist_index>
    800004ec:	429c                	lw	a5,0(a3)
    800004ee:	fff7871b          	addiw	a4,a5,-1
    800004f2:	0007061b          	sext.w	a2,a4
    800004f6:	c298                	sw	a4,0(a3)
      index = (historyBuffer.lastCommandIndex - hist_index - 1) % MAX_HISTORY;
    800004f8:	00011697          	auipc	a3,0x11
    800004fc:	72068693          	addi	a3,a3,1824 # 80011c18 <proc+0x290>
    80000500:	8406a783          	lw	a5,-1984(a3)
    80000504:	37fd                	addiw	a5,a5,-1
    80000506:	9f99                	subw	a5,a5,a4
    80000508:	8bbd                	andi	a5,a5,15
      if (index < 0 || index > historyBuffer.numOfCommandsInMem - 1 || hist_index > 15) {
    8000050a:	8446a703          	lw	a4,-1980(a3)
    8000050e:	18e7d463          	bge	a5,a4,80000696 <consoleintr+0x2f0>
    80000512:	473d                	li	a4,15
    80000514:	18c74163          	blt	a4,a2,80000696 <consoleintr+0x2f0>
      for (int i = 0; i < historyBuffer.lengthArr[index]; i++) {
    80000518:	20078713          	addi	a4,a5,512
    8000051c:	00271693          	slli	a3,a4,0x2
    80000520:	00010717          	auipc	a4,0x10
    80000524:	6f870713          	addi	a4,a4,1784 # 80010c18 <historyBuffer>
    80000528:	9736                	add	a4,a4,a3
    8000052a:	4318                	lw	a4,0(a4)
    8000052c:	00779b93          	slli	s7,a5,0x7
    80000530:	4901                	li	s2,0
    80000532:	12070c63          	beqz	a4,8000066a <consoleintr+0x2c4>
          int cc = historyBuffer.bufferArr[index][i];
    80000536:	00010a97          	auipc	s5,0x10
    8000053a:	6e2a8a93          	addi	s5,s5,1762 # 80010c18 <historyBuffer>
          cc = (cc == '\r') ? '\n' : cc;
    8000053e:	4cb5                	li	s9,13
    80000540:	4d29                	li	s10,10
          cons.buf[cons.e++ % INPUT_BUF] = cc;
    80000542:	00010997          	auipc	s3,0x10
    80000546:	62e98993          	addi	s3,s3,1582 # 80010b70 <cons>
          historyBuffer.currentCommand[commandLength] = cc;
    8000054a:	00008b17          	auipc	s6,0x8
    8000054e:	4a6b0b13          	addi	s6,s6,1190 # 800089f0 <commandLength>
    80000552:	6c05                	lui	s8,0x1
      for (int i = 0; i < historyBuffer.lengthArr[index]; i++) {
    80000554:	00da84b3          	add	s1,s5,a3
    80000558:	a271                	j	800006e4 <consoleintr+0x33e>
      while (cons.e != cons.w &&
    8000055a:	00010717          	auipc	a4,0x10
    8000055e:	61670713          	addi	a4,a4,1558 # 80010b70 <cons>
    80000562:	0a072783          	lw	a5,160(a4)
    80000566:	09c72703          	lw	a4,156(a4)
              cons.buf[(cons.e - 1) % INPUT_BUF] != '\n') {
    8000056a:	00010497          	auipc	s1,0x10
    8000056e:	60648493          	addi	s1,s1,1542 # 80010b70 <cons>
      while (cons.e != cons.w &&
    80000572:	4929                	li	s2,10
    80000574:	02f70863          	beq	a4,a5,800005a4 <consoleintr+0x1fe>
              cons.buf[(cons.e - 1) % INPUT_BUF] != '\n') {
    80000578:	37fd                	addiw	a5,a5,-1
    8000057a:	07f7f713          	andi	a4,a5,127
    8000057e:	9726                	add	a4,a4,s1
      while (cons.e != cons.w &&
    80000580:	01874703          	lbu	a4,24(a4)
    80000584:	03270063          	beq	a4,s2,800005a4 <consoleintr+0x1fe>
          cons.e--;
    80000588:	0af4a023          	sw	a5,160(s1)
          consputc(BACKSPACE);
    8000058c:	10000513          	li	a0,256
    80000590:	00000097          	auipc	ra,0x0
    80000594:	cec080e7          	jalr	-788(ra) # 8000027c <consputc>
      while (cons.e != cons.w &&
    80000598:	0a04a783          	lw	a5,160(s1)
    8000059c:	09c4a703          	lw	a4,156(s1)
    800005a0:	fcf71ce3          	bne	a4,a5,80000578 <consoleintr+0x1d2>
      hist_index++;
    800005a4:	00008717          	auipc	a4,0x8
    800005a8:	3fc70713          	addi	a4,a4,1020 # 800089a0 <hist_index>
    800005ac:	431c                	lw	a5,0(a4)
    800005ae:	2785                	addiw	a5,a5,1
    800005b0:	0007861b          	sext.w	a2,a5
    800005b4:	c31c                	sw	a5,0(a4)
      index = (historyBuffer.lastCommandIndex - hist_index - 1) % MAX_HISTORY;
    800005b6:	00011697          	auipc	a3,0x11
    800005ba:	66268693          	addi	a3,a3,1634 # 80011c18 <proc+0x290>
    800005be:	8406a703          	lw	a4,-1984(a3)
    800005c2:	377d                	addiw	a4,a4,-1
    800005c4:	9f1d                	subw	a4,a4,a5
    800005c6:	8b3d                	andi	a4,a4,15
      if (index < 0 || index > historyBuffer.numOfCommandsInMem - 1 || hist_index > 15) {
    800005c8:	8446a683          	lw	a3,-1980(a3)
    800005cc:	12d75563          	bge	a4,a3,800006f6 <consoleintr+0x350>
    800005d0:	45bd                	li	a1,15
    800005d2:	12c5c263          	blt	a1,a2,800006f6 <consoleintr+0x350>
      for (int i = 0; i < historyBuffer.lengthArr[index]; i++) {
    800005d6:	20070793          	addi	a5,a4,512
    800005da:	00279693          	slli	a3,a5,0x2
    800005de:	00010797          	auipc	a5,0x10
    800005e2:	63a78793          	addi	a5,a5,1594 # 80010c18 <historyBuffer>
    800005e6:	97b6                	add	a5,a5,a3
    800005e8:	439c                	lw	a5,0(a5)
    800005ea:	00771b93          	slli	s7,a4,0x7
    800005ee:	4901                	li	s2,0
    800005f0:	cfad                	beqz	a5,8000066a <consoleintr+0x2c4>
          int cc = historyBuffer.bufferArr[index][i];
    800005f2:	00010a97          	auipc	s5,0x10
    800005f6:	626a8a93          	addi	s5,s5,1574 # 80010c18 <historyBuffer>
          cc = (cc == '\r') ? '\n' : cc;
    800005fa:	4cb5                	li	s9,13
    800005fc:	4d29                	li	s10,10
          cons.buf[cons.e++ % INPUT_BUF] = cc;
    800005fe:	00010997          	auipc	s3,0x10
    80000602:	57298993          	addi	s3,s3,1394 # 80010b70 <cons>
          historyBuffer.currentCommand[commandLength] = cc;
    80000606:	00008b17          	auipc	s6,0x8
    8000060a:	3eab0b13          	addi	s6,s6,1002 # 800089f0 <commandLength>
    8000060e:	6c05                	lui	s8,0x1
      for (int i = 0; i < historyBuffer.lengthArr[index]; i++) {
    80000610:	00da84b3          	add	s1,s5,a3
    80000614:	aa15                	j	80000748 <consoleintr+0x3a2>
    while(cons.e != cons.w &&
    80000616:	00010717          	auipc	a4,0x10
    8000061a:	55a70713          	addi	a4,a4,1370 # 80010b70 <cons>
    8000061e:	0a072783          	lw	a5,160(a4)
    80000622:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000626:	00010497          	auipc	s1,0x10
    8000062a:	54a48493          	addi	s1,s1,1354 # 80010b70 <cons>
    while(cons.e != cons.w &&
    8000062e:	4929                	li	s2,10
    80000630:	02f70d63          	beq	a4,a5,8000066a <consoleintr+0x2c4>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000634:	37fd                	addiw	a5,a5,-1
    80000636:	07f7f713          	andi	a4,a5,127
    8000063a:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    8000063c:	01874703          	lbu	a4,24(a4)
    80000640:	03270563          	beq	a4,s2,8000066a <consoleintr+0x2c4>
      cons.e--;
    80000644:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    80000648:	10000513          	li	a0,256
    8000064c:	00000097          	auipc	ra,0x0
    80000650:	c30080e7          	jalr	-976(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    80000654:	0a04a783          	lw	a5,160(s1)
    80000658:	09c4a703          	lw	a4,156(s1)
    8000065c:	fcf71ce3          	bne	a4,a5,80000634 <consoleintr+0x28e>
    80000660:	a029                	j	8000066a <consoleintr+0x2c4>
    procdump();
    80000662:	00002097          	auipc	ra,0x2
    80000666:	266080e7          	jalr	614(ra) # 800028c8 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    8000066a:	00010517          	auipc	a0,0x10
    8000066e:	50650513          	addi	a0,a0,1286 # 80010b70 <cons>
    80000672:	00001097          	auipc	ra,0x1
    80000676:	9d8080e7          	jalr	-1576(ra) # 8000104a <release>
}
    8000067a:	60e6                	ld	ra,88(sp)
    8000067c:	6446                	ld	s0,80(sp)
    8000067e:	64a6                	ld	s1,72(sp)
    80000680:	6906                	ld	s2,64(sp)
    80000682:	79e2                	ld	s3,56(sp)
    80000684:	7a42                	ld	s4,48(sp)
    80000686:	7aa2                	ld	s5,40(sp)
    80000688:	7b02                	ld	s6,32(sp)
    8000068a:	6be2                	ld	s7,24(sp)
    8000068c:	6c42                	ld	s8,16(sp)
    8000068e:	6ca2                	ld	s9,8(sp)
    80000690:	6d02                	ld	s10,0(sp)
    80000692:	6125                	addi	sp,sp,96
    80000694:	8082                	ret
          hist_index = -1;
    80000696:	57fd                	li	a5,-1
    80000698:	00008717          	auipc	a4,0x8
    8000069c:	30f72423          	sw	a5,776(a4) # 800089a0 <hist_index>
          break;
    800006a0:	b7e9                	j	8000066a <consoleintr+0x2c4>
          cons.buf[cons.e++ % INPUT_BUF] = cc;
    800006a2:	0a09a783          	lw	a5,160(s3)
    800006a6:	0017871b          	addiw	a4,a5,1
    800006aa:	0ae9a023          	sw	a4,160(s3)
    800006ae:	0ff57a13          	andi	s4,a0,255
    800006b2:	07f7f793          	andi	a5,a5,127
    800006b6:	97ce                	add	a5,a5,s3
    800006b8:	01478c23          	sb	s4,24(a5)
          consputc(cc);
    800006bc:	00000097          	auipc	ra,0x0
    800006c0:	bc0080e7          	jalr	-1088(ra) # 8000027c <consputc>
          historyBuffer.currentCommand[commandLength] = cc;
    800006c4:	000b2783          	lw	a5,0(s6)
    800006c8:	00fa8733          	add	a4,s5,a5
    800006cc:	9762                	add	a4,a4,s8
    800006ce:	85470423          	sb	s4,-1976(a4)
          commandLength++;
    800006d2:	2785                	addiw	a5,a5,1
    800006d4:	00fb2023          	sw	a5,0(s6)
      for (int i = 0; i < historyBuffer.lengthArr[index]; i++) {
    800006d8:	0905                	addi	s2,s2,1
    800006da:	4098                	lw	a4,0(s1)
    800006dc:	0009079b          	sext.w	a5,s2
    800006e0:	f8e7f5e3          	bgeu	a5,a4,8000066a <consoleintr+0x2c4>
          int cc = historyBuffer.bufferArr[index][i];
    800006e4:	017907b3          	add	a5,s2,s7
    800006e8:	97d6                	add	a5,a5,s5
    800006ea:	0007c503          	lbu	a0,0(a5)
          cc = (cc == '\r') ? '\n' : cc;
    800006ee:	fb951ae3          	bne	a0,s9,800006a2 <consoleintr+0x2fc>
    800006f2:	856a                	mv	a0,s10
    800006f4:	b77d                	j	800006a2 <consoleintr+0x2fc>
          hist_index = hist_index % historyBuffer.numOfCommandsInMem - 1;
    800006f6:	02d7e7bb          	remw	a5,a5,a3
    800006fa:	37fd                	addiw	a5,a5,-1
    800006fc:	00008717          	auipc	a4,0x8
    80000700:	2af72223          	sw	a5,676(a4) # 800089a0 <hist_index>
          break;
    80000704:	b79d                	j	8000066a <consoleintr+0x2c4>
          cons.buf[cons.e++ % INPUT_BUF] = cc;
    80000706:	0a09a783          	lw	a5,160(s3)
    8000070a:	0017871b          	addiw	a4,a5,1
    8000070e:	0ae9a023          	sw	a4,160(s3)
    80000712:	0ff57a13          	andi	s4,a0,255
    80000716:	07f7f793          	andi	a5,a5,127
    8000071a:	97ce                	add	a5,a5,s3
    8000071c:	01478c23          	sb	s4,24(a5)
          consputc(cc);
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b5c080e7          	jalr	-1188(ra) # 8000027c <consputc>
          historyBuffer.currentCommand[commandLength] = cc;
    80000728:	000b2783          	lw	a5,0(s6)
    8000072c:	00fa8733          	add	a4,s5,a5
    80000730:	9762                	add	a4,a4,s8
    80000732:	85470423          	sb	s4,-1976(a4)
          commandLength++;
    80000736:	2785                	addiw	a5,a5,1
    80000738:	00fb2023          	sw	a5,0(s6)
      for (int i = 0; i < historyBuffer.lengthArr[index]; i++) {
    8000073c:	0905                	addi	s2,s2,1
    8000073e:	4098                	lw	a4,0(s1)
    80000740:	0009079b          	sext.w	a5,s2
    80000744:	f2e7f3e3          	bgeu	a5,a4,8000066a <consoleintr+0x2c4>
          int cc = historyBuffer.bufferArr[index][i];
    80000748:	012b87b3          	add	a5,s7,s2
    8000074c:	97d6                	add	a5,a5,s5
    8000074e:	0007c503          	lbu	a0,0(a5)
          cc = (cc == '\r') ? '\n' : cc;
    80000752:	fb951ae3          	bne	a0,s9,80000706 <consoleintr+0x360>
    80000756:	856a                	mv	a0,s10
    80000758:	b77d                	j	80000706 <consoleintr+0x360>
    if(cons.e != cons.w){
    8000075a:	00010717          	auipc	a4,0x10
    8000075e:	41670713          	addi	a4,a4,1046 # 80010b70 <cons>
    80000762:	0a072783          	lw	a5,160(a4)
    80000766:	09c72703          	lw	a4,156(a4)
    8000076a:	f0f700e3          	beq	a4,a5,8000066a <consoleintr+0x2c4>
      cons.e--;
    8000076e:	37fd                	addiw	a5,a5,-1
    80000770:	00010717          	auipc	a4,0x10
    80000774:	4af72023          	sw	a5,1184(a4) # 80010c10 <cons+0xa0>
      consputc(BACKSPACE);
    80000778:	10000513          	li	a0,256
    8000077c:	00000097          	auipc	ra,0x0
    80000780:	b00080e7          	jalr	-1280(ra) # 8000027c <consputc>
      commandLength--;
    80000784:	00008717          	auipc	a4,0x8
    80000788:	26c70713          	addi	a4,a4,620 # 800089f0 <commandLength>
    8000078c:	431c                	lw	a5,0(a4)
    8000078e:	37fd                	addiw	a5,a5,-1
    80000790:	c31c                	sw	a5,0(a4)
    80000792:	bde1                	j	8000066a <consoleintr+0x2c4>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000794:	ec048be3          	beqz	s1,8000066a <consoleintr+0x2c4>
    80000798:	b995                	j	8000040c <consoleintr+0x66>
      consputc(c);
    8000079a:	4529                	li	a0,10
    8000079c:	00000097          	auipc	ra,0x0
    800007a0:	ae0080e7          	jalr	-1312(ra) # 8000027c <consputc>
      historyBuffer.currentCommand[commandLength] = c;
    800007a4:	00008617          	auipc	a2,0x8
    800007a8:	24c60613          	addi	a2,a2,588 # 800089f0 <commandLength>
    800007ac:	421c                	lw	a5,0(a2)
    800007ae:	00010717          	auipc	a4,0x10
    800007b2:	46a70713          	addi	a4,a4,1130 # 80010c18 <historyBuffer>
    800007b6:	00f706b3          	add	a3,a4,a5
    800007ba:	6705                	lui	a4,0x1
    800007bc:	9736                	add	a4,a4,a3
    800007be:	46a9                	li	a3,10
    800007c0:	84d70423          	sb	a3,-1976(a4) # 848 <_entry-0x7ffff7b8>
      commandLength++;
    800007c4:	2785                	addiw	a5,a5,1
    800007c6:	c21c                	sw	a5,0(a2)
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    800007c8:	00010797          	auipc	a5,0x10
    800007cc:	3a878793          	addi	a5,a5,936 # 80010b70 <cons>
    800007d0:	0a07a703          	lw	a4,160(a5)
    800007d4:	0017061b          	addiw	a2,a4,1
    800007d8:	0ac7a023          	sw	a2,160(a5)
    800007dc:	07f77713          	andi	a4,a4,127
    800007e0:	97ba                	add	a5,a5,a4
    800007e2:	00d78c23          	sb	a3,24(a5)
        saveCommand();
    800007e6:	00000097          	auipc	ra,0x0
    800007ea:	ad8080e7          	jalr	-1320(ra) # 800002be <saveCommand>
        cons.w = cons.e;
    800007ee:	00010797          	auipc	a5,0x10
    800007f2:	38278793          	addi	a5,a5,898 # 80010b70 <cons>
    800007f6:	0a07a703          	lw	a4,160(a5)
    800007fa:	08e7ae23          	sw	a4,156(a5)
        wakeup(&cons.r);
    800007fe:	00010517          	auipc	a0,0x10
    80000802:	40a50513          	addi	a0,a0,1034 # 80010c08 <cons+0x98>
    80000806:	00002097          	auipc	ra,0x2
    8000080a:	c72080e7          	jalr	-910(ra) # 80002478 <wakeup>
    8000080e:	bdb1                	j	8000066a <consoleintr+0x2c4>

0000000080000810 <consoleinit>:

void
consoleinit(void)
{
    80000810:	1141                	addi	sp,sp,-16
    80000812:	e406                	sd	ra,8(sp)
    80000814:	e022                	sd	s0,0(sp)
    80000816:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000818:	00008597          	auipc	a1,0x8
    8000081c:	80058593          	addi	a1,a1,-2048 # 80008018 <etext+0x18>
    80000820:	00010517          	auipc	a0,0x10
    80000824:	35050513          	addi	a0,a0,848 # 80010b70 <cons>
    80000828:	00000097          	auipc	ra,0x0
    8000082c:	6de080e7          	jalr	1758(ra) # 80000f06 <initlock>

  uartinit();
    80000830:	00000097          	auipc	ra,0x0
    80000834:	32a080e7          	jalr	810(ra) # 80000b5a <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000838:	00021797          	auipc	a5,0x21
    8000083c:	d9878793          	addi	a5,a5,-616 # 800215d0 <devsw>
    80000840:	00000717          	auipc	a4,0x0
    80000844:	92470713          	addi	a4,a4,-1756 # 80000164 <consoleread>
    80000848:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000084a:	00000717          	auipc	a4,0x0
    8000084e:	8b870713          	addi	a4,a4,-1864 # 80000102 <consolewrite>
    80000852:	ef98                	sd	a4,24(a5)
}
    80000854:	60a2                	ld	ra,8(sp)
    80000856:	6402                	ld	s0,0(sp)
    80000858:	0141                	addi	sp,sp,16
    8000085a:	8082                	ret

000000008000085c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000085c:	7179                	addi	sp,sp,-48
    8000085e:	f406                	sd	ra,40(sp)
    80000860:	f022                	sd	s0,32(sp)
    80000862:	ec26                	sd	s1,24(sp)
    80000864:	e84a                	sd	s2,16(sp)
    80000866:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    80000868:	c219                	beqz	a2,8000086e <printint+0x12>
    8000086a:	08054663          	bltz	a0,800008f6 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    8000086e:	2501                	sext.w	a0,a0
    80000870:	4881                	li	a7,0
    80000872:	fd040693          	addi	a3,s0,-48

  i = 0;
    80000876:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    80000878:	2581                	sext.w	a1,a1
    8000087a:	00008617          	auipc	a2,0x8
    8000087e:	81660613          	addi	a2,a2,-2026 # 80008090 <digits>
    80000882:	883a                	mv	a6,a4
    80000884:	2705                	addiw	a4,a4,1
    80000886:	02b577bb          	remuw	a5,a0,a1
    8000088a:	1782                	slli	a5,a5,0x20
    8000088c:	9381                	srli	a5,a5,0x20
    8000088e:	97b2                	add	a5,a5,a2
    80000890:	0007c783          	lbu	a5,0(a5)
    80000894:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    80000898:	0005079b          	sext.w	a5,a0
    8000089c:	02b5553b          	divuw	a0,a0,a1
    800008a0:	0685                	addi	a3,a3,1
    800008a2:	feb7f0e3          	bgeu	a5,a1,80000882 <printint+0x26>

  if(sign)
    800008a6:	00088b63          	beqz	a7,800008bc <printint+0x60>
    buf[i++] = '-';
    800008aa:	fe040793          	addi	a5,s0,-32
    800008ae:	973e                	add	a4,a4,a5
    800008b0:	02d00793          	li	a5,45
    800008b4:	fef70823          	sb	a5,-16(a4)
    800008b8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800008bc:	02e05763          	blez	a4,800008ea <printint+0x8e>
    800008c0:	fd040793          	addi	a5,s0,-48
    800008c4:	00e784b3          	add	s1,a5,a4
    800008c8:	fff78913          	addi	s2,a5,-1
    800008cc:	993a                	add	s2,s2,a4
    800008ce:	377d                	addiw	a4,a4,-1
    800008d0:	1702                	slli	a4,a4,0x20
    800008d2:	9301                	srli	a4,a4,0x20
    800008d4:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    800008d8:	fff4c503          	lbu	a0,-1(s1)
    800008dc:	00000097          	auipc	ra,0x0
    800008e0:	9a0080e7          	jalr	-1632(ra) # 8000027c <consputc>
  while(--i >= 0)
    800008e4:	14fd                	addi	s1,s1,-1
    800008e6:	ff2499e3          	bne	s1,s2,800008d8 <printint+0x7c>
}
    800008ea:	70a2                	ld	ra,40(sp)
    800008ec:	7402                	ld	s0,32(sp)
    800008ee:	64e2                	ld	s1,24(sp)
    800008f0:	6942                	ld	s2,16(sp)
    800008f2:	6145                	addi	sp,sp,48
    800008f4:	8082                	ret
    x = -xx;
    800008f6:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    800008fa:	4885                	li	a7,1
    x = -xx;
    800008fc:	bf9d                	j	80000872 <printint+0x16>

00000000800008fe <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    800008fe:	1101                	addi	sp,sp,-32
    80000900:	ec06                	sd	ra,24(sp)
    80000902:	e822                	sd	s0,16(sp)
    80000904:	e426                	sd	s1,8(sp)
    80000906:	1000                	addi	s0,sp,32
    80000908:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000090a:	00011797          	auipc	a5,0x11
    8000090e:	be07a723          	sw	zero,-1042(a5) # 800114f8 <pr+0x18>
  printf("panic: ");
    80000912:	00007517          	auipc	a0,0x7
    80000916:	75650513          	addi	a0,a0,1878 # 80008068 <etext+0x68>
    8000091a:	00000097          	auipc	ra,0x0
    8000091e:	02e080e7          	jalr	46(ra) # 80000948 <printf>
  printf(s);
    80000922:	8526                	mv	a0,s1
    80000924:	00000097          	auipc	ra,0x0
    80000928:	024080e7          	jalr	36(ra) # 80000948 <printf>
  printf("\n");
    8000092c:	00008517          	auipc	a0,0x8
    80000930:	a1450513          	addi	a0,a0,-1516 # 80008340 <digits+0x2b0>
    80000934:	00000097          	auipc	ra,0x0
    80000938:	014080e7          	jalr	20(ra) # 80000948 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000093c:	4785                	li	a5,1
    8000093e:	00008717          	auipc	a4,0x8
    80000942:	0af72b23          	sw	a5,182(a4) # 800089f4 <panicked>
  for(;;)
    80000946:	a001                	j	80000946 <panic+0x48>

0000000080000948 <printf>:
{
    80000948:	7131                	addi	sp,sp,-192
    8000094a:	fc86                	sd	ra,120(sp)
    8000094c:	f8a2                	sd	s0,112(sp)
    8000094e:	f4a6                	sd	s1,104(sp)
    80000950:	f0ca                	sd	s2,96(sp)
    80000952:	ecce                	sd	s3,88(sp)
    80000954:	e8d2                	sd	s4,80(sp)
    80000956:	e4d6                	sd	s5,72(sp)
    80000958:	e0da                	sd	s6,64(sp)
    8000095a:	fc5e                	sd	s7,56(sp)
    8000095c:	f862                	sd	s8,48(sp)
    8000095e:	f466                	sd	s9,40(sp)
    80000960:	f06a                	sd	s10,32(sp)
    80000962:	ec6e                	sd	s11,24(sp)
    80000964:	0100                	addi	s0,sp,128
    80000966:	8a2a                	mv	s4,a0
    80000968:	e40c                	sd	a1,8(s0)
    8000096a:	e810                	sd	a2,16(s0)
    8000096c:	ec14                	sd	a3,24(s0)
    8000096e:	f018                	sd	a4,32(s0)
    80000970:	f41c                	sd	a5,40(s0)
    80000972:	03043823          	sd	a6,48(s0)
    80000976:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    8000097a:	00011d97          	auipc	s11,0x11
    8000097e:	b7edad83          	lw	s11,-1154(s11) # 800114f8 <pr+0x18>
  if(locking)
    80000982:	020d9b63          	bnez	s11,800009b8 <printf+0x70>
  if (fmt == 0)
    80000986:	040a0263          	beqz	s4,800009ca <printf+0x82>
  va_start(ap, fmt);
    8000098a:	00840793          	addi	a5,s0,8
    8000098e:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000992:	000a4503          	lbu	a0,0(s4)
    80000996:	14050f63          	beqz	a0,80000af4 <printf+0x1ac>
    8000099a:	4981                	li	s3,0
    if(c != '%'){
    8000099c:	02500a93          	li	s5,37
    switch(c){
    800009a0:	07000b93          	li	s7,112
  consputc('x');
    800009a4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800009a6:	00007b17          	auipc	s6,0x7
    800009aa:	6eab0b13          	addi	s6,s6,1770 # 80008090 <digits>
    switch(c){
    800009ae:	07300c93          	li	s9,115
    800009b2:	06400c13          	li	s8,100
    800009b6:	a82d                	j	800009f0 <printf+0xa8>
    acquire(&pr.lock);
    800009b8:	00011517          	auipc	a0,0x11
    800009bc:	b2850513          	addi	a0,a0,-1240 # 800114e0 <pr>
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	5d6080e7          	jalr	1494(ra) # 80000f96 <acquire>
    800009c8:	bf7d                	j	80000986 <printf+0x3e>
    panic("null fmt");
    800009ca:	00007517          	auipc	a0,0x7
    800009ce:	6ae50513          	addi	a0,a0,1710 # 80008078 <etext+0x78>
    800009d2:	00000097          	auipc	ra,0x0
    800009d6:	f2c080e7          	jalr	-212(ra) # 800008fe <panic>
      consputc(c);
    800009da:	00000097          	auipc	ra,0x0
    800009de:	8a2080e7          	jalr	-1886(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800009e2:	2985                	addiw	s3,s3,1
    800009e4:	013a07b3          	add	a5,s4,s3
    800009e8:	0007c503          	lbu	a0,0(a5)
    800009ec:	10050463          	beqz	a0,80000af4 <printf+0x1ac>
    if(c != '%'){
    800009f0:	ff5515e3          	bne	a0,s5,800009da <printf+0x92>
    c = fmt[++i] & 0xff;
    800009f4:	2985                	addiw	s3,s3,1
    800009f6:	013a07b3          	add	a5,s4,s3
    800009fa:	0007c783          	lbu	a5,0(a5)
    800009fe:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000a02:	cbed                	beqz	a5,80000af4 <printf+0x1ac>
    switch(c){
    80000a04:	05778a63          	beq	a5,s7,80000a58 <printf+0x110>
    80000a08:	02fbf663          	bgeu	s7,a5,80000a34 <printf+0xec>
    80000a0c:	09978863          	beq	a5,s9,80000a9c <printf+0x154>
    80000a10:	07800713          	li	a4,120
    80000a14:	0ce79563          	bne	a5,a4,80000ade <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000a18:	f8843783          	ld	a5,-120(s0)
    80000a1c:	00878713          	addi	a4,a5,8
    80000a20:	f8e43423          	sd	a4,-120(s0)
    80000a24:	4605                	li	a2,1
    80000a26:	85ea                	mv	a1,s10
    80000a28:	4388                	lw	a0,0(a5)
    80000a2a:	00000097          	auipc	ra,0x0
    80000a2e:	e32080e7          	jalr	-462(ra) # 8000085c <printint>
      break;
    80000a32:	bf45                	j	800009e2 <printf+0x9a>
    switch(c){
    80000a34:	09578f63          	beq	a5,s5,80000ad2 <printf+0x18a>
    80000a38:	0b879363          	bne	a5,s8,80000ade <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000a3c:	f8843783          	ld	a5,-120(s0)
    80000a40:	00878713          	addi	a4,a5,8
    80000a44:	f8e43423          	sd	a4,-120(s0)
    80000a48:	4605                	li	a2,1
    80000a4a:	45a9                	li	a1,10
    80000a4c:	4388                	lw	a0,0(a5)
    80000a4e:	00000097          	auipc	ra,0x0
    80000a52:	e0e080e7          	jalr	-498(ra) # 8000085c <printint>
      break;
    80000a56:	b771                	j	800009e2 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000a58:	f8843783          	ld	a5,-120(s0)
    80000a5c:	00878713          	addi	a4,a5,8
    80000a60:	f8e43423          	sd	a4,-120(s0)
    80000a64:	0007b903          	ld	s2,0(a5)
  consputc('0');
    80000a68:	03000513          	li	a0,48
    80000a6c:	00000097          	auipc	ra,0x0
    80000a70:	810080e7          	jalr	-2032(ra) # 8000027c <consputc>
  consputc('x');
    80000a74:	07800513          	li	a0,120
    80000a78:	00000097          	auipc	ra,0x0
    80000a7c:	804080e7          	jalr	-2044(ra) # 8000027c <consputc>
    80000a80:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    80000a82:	03c95793          	srli	a5,s2,0x3c
    80000a86:	97da                	add	a5,a5,s6
    80000a88:	0007c503          	lbu	a0,0(a5)
    80000a8c:	fffff097          	auipc	ra,0xfffff
    80000a90:	7f0080e7          	jalr	2032(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    80000a94:	0912                	slli	s2,s2,0x4
    80000a96:	34fd                	addiw	s1,s1,-1
    80000a98:	f4ed                	bnez	s1,80000a82 <printf+0x13a>
    80000a9a:	b7a1                	j	800009e2 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    80000a9c:	f8843783          	ld	a5,-120(s0)
    80000aa0:	00878713          	addi	a4,a5,8
    80000aa4:	f8e43423          	sd	a4,-120(s0)
    80000aa8:	6384                	ld	s1,0(a5)
    80000aaa:	cc89                	beqz	s1,80000ac4 <printf+0x17c>
      for(; *s; s++)
    80000aac:	0004c503          	lbu	a0,0(s1)
    80000ab0:	d90d                	beqz	a0,800009e2 <printf+0x9a>
        consputc(*s);
    80000ab2:	fffff097          	auipc	ra,0xfffff
    80000ab6:	7ca080e7          	jalr	1994(ra) # 8000027c <consputc>
      for(; *s; s++)
    80000aba:	0485                	addi	s1,s1,1
    80000abc:	0004c503          	lbu	a0,0(s1)
    80000ac0:	f96d                	bnez	a0,80000ab2 <printf+0x16a>
    80000ac2:	b705                	j	800009e2 <printf+0x9a>
        s = "(null)";
    80000ac4:	00007497          	auipc	s1,0x7
    80000ac8:	5ac48493          	addi	s1,s1,1452 # 80008070 <etext+0x70>
      for(; *s; s++)
    80000acc:	02800513          	li	a0,40
    80000ad0:	b7cd                	j	80000ab2 <printf+0x16a>
      consputc('%');
    80000ad2:	8556                	mv	a0,s5
    80000ad4:	fffff097          	auipc	ra,0xfffff
    80000ad8:	7a8080e7          	jalr	1960(ra) # 8000027c <consputc>
      break;
    80000adc:	b719                	j	800009e2 <printf+0x9a>
      consputc('%');
    80000ade:	8556                	mv	a0,s5
    80000ae0:	fffff097          	auipc	ra,0xfffff
    80000ae4:	79c080e7          	jalr	1948(ra) # 8000027c <consputc>
      consputc(c);
    80000ae8:	8526                	mv	a0,s1
    80000aea:	fffff097          	auipc	ra,0xfffff
    80000aee:	792080e7          	jalr	1938(ra) # 8000027c <consputc>
      break;
    80000af2:	bdc5                	j	800009e2 <printf+0x9a>
  if(locking)
    80000af4:	020d9163          	bnez	s11,80000b16 <printf+0x1ce>
}
    80000af8:	70e6                	ld	ra,120(sp)
    80000afa:	7446                	ld	s0,112(sp)
    80000afc:	74a6                	ld	s1,104(sp)
    80000afe:	7906                	ld	s2,96(sp)
    80000b00:	69e6                	ld	s3,88(sp)
    80000b02:	6a46                	ld	s4,80(sp)
    80000b04:	6aa6                	ld	s5,72(sp)
    80000b06:	6b06                	ld	s6,64(sp)
    80000b08:	7be2                	ld	s7,56(sp)
    80000b0a:	7c42                	ld	s8,48(sp)
    80000b0c:	7ca2                	ld	s9,40(sp)
    80000b0e:	7d02                	ld	s10,32(sp)
    80000b10:	6de2                	ld	s11,24(sp)
    80000b12:	6129                	addi	sp,sp,192
    80000b14:	8082                	ret
    release(&pr.lock);
    80000b16:	00011517          	auipc	a0,0x11
    80000b1a:	9ca50513          	addi	a0,a0,-1590 # 800114e0 <pr>
    80000b1e:	00000097          	auipc	ra,0x0
    80000b22:	52c080e7          	jalr	1324(ra) # 8000104a <release>
}
    80000b26:	bfc9                	j	80000af8 <printf+0x1b0>

0000000080000b28 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000b28:	1101                	addi	sp,sp,-32
    80000b2a:	ec06                	sd	ra,24(sp)
    80000b2c:	e822                	sd	s0,16(sp)
    80000b2e:	e426                	sd	s1,8(sp)
    80000b30:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000b32:	00011497          	auipc	s1,0x11
    80000b36:	9ae48493          	addi	s1,s1,-1618 # 800114e0 <pr>
    80000b3a:	00007597          	auipc	a1,0x7
    80000b3e:	54e58593          	addi	a1,a1,1358 # 80008088 <etext+0x88>
    80000b42:	8526                	mv	a0,s1
    80000b44:	00000097          	auipc	ra,0x0
    80000b48:	3c2080e7          	jalr	962(ra) # 80000f06 <initlock>
  pr.locking = 1;
    80000b4c:	4785                	li	a5,1
    80000b4e:	cc9c                	sw	a5,24(s1)
}
    80000b50:	60e2                	ld	ra,24(sp)
    80000b52:	6442                	ld	s0,16(sp)
    80000b54:	64a2                	ld	s1,8(sp)
    80000b56:	6105                	addi	sp,sp,32
    80000b58:	8082                	ret

0000000080000b5a <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000b5a:	1141                	addi	sp,sp,-16
    80000b5c:	e406                	sd	ra,8(sp)
    80000b5e:	e022                	sd	s0,0(sp)
    80000b60:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    80000b62:	100007b7          	lui	a5,0x10000
    80000b66:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    80000b6a:	f8000713          	li	a4,-128
    80000b6e:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    80000b72:	470d                	li	a4,3
    80000b74:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    80000b78:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    80000b7c:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    80000b80:	469d                	li	a3,7
    80000b82:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    80000b86:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    80000b8a:	00007597          	auipc	a1,0x7
    80000b8e:	51e58593          	addi	a1,a1,1310 # 800080a8 <digits+0x18>
    80000b92:	00011517          	auipc	a0,0x11
    80000b96:	96e50513          	addi	a0,a0,-1682 # 80011500 <uart_tx_lock>
    80000b9a:	00000097          	auipc	ra,0x0
    80000b9e:	36c080e7          	jalr	876(ra) # 80000f06 <initlock>
}
    80000ba2:	60a2                	ld	ra,8(sp)
    80000ba4:	6402                	ld	s0,0(sp)
    80000ba6:	0141                	addi	sp,sp,16
    80000ba8:	8082                	ret

0000000080000baa <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    80000baa:	1101                	addi	sp,sp,-32
    80000bac:	ec06                	sd	ra,24(sp)
    80000bae:	e822                	sd	s0,16(sp)
    80000bb0:	e426                	sd	s1,8(sp)
    80000bb2:	1000                	addi	s0,sp,32
    80000bb4:	84aa                	mv	s1,a0
  push_off();
    80000bb6:	00000097          	auipc	ra,0x0
    80000bba:	394080e7          	jalr	916(ra) # 80000f4a <push_off>

  if(panicked){
    80000bbe:	00008797          	auipc	a5,0x8
    80000bc2:	e367a783          	lw	a5,-458(a5) # 800089f4 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000bc6:	10000737          	lui	a4,0x10000
  if(panicked){
    80000bca:	c391                	beqz	a5,80000bce <uartputc_sync+0x24>
    for(;;)
    80000bcc:	a001                	j	80000bcc <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000bce:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000bd2:	0207f793          	andi	a5,a5,32
    80000bd6:	dfe5                	beqz	a5,80000bce <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000bd8:	0ff4f513          	andi	a0,s1,255
    80000bdc:	100007b7          	lui	a5,0x10000
    80000be0:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000be4:	00000097          	auipc	ra,0x0
    80000be8:	406080e7          	jalr	1030(ra) # 80000fea <pop_off>
}
    80000bec:	60e2                	ld	ra,24(sp)
    80000bee:	6442                	ld	s0,16(sp)
    80000bf0:	64a2                	ld	s1,8(sp)
    80000bf2:	6105                	addi	sp,sp,32
    80000bf4:	8082                	ret

0000000080000bf6 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000bf6:	00008797          	auipc	a5,0x8
    80000bfa:	e027b783          	ld	a5,-510(a5) # 800089f8 <uart_tx_r>
    80000bfe:	00008717          	auipc	a4,0x8
    80000c02:	e0273703          	ld	a4,-510(a4) # 80008a00 <uart_tx_w>
    80000c06:	06f70a63          	beq	a4,a5,80000c7a <uartstart+0x84>
{
    80000c0a:	7139                	addi	sp,sp,-64
    80000c0c:	fc06                	sd	ra,56(sp)
    80000c0e:	f822                	sd	s0,48(sp)
    80000c10:	f426                	sd	s1,40(sp)
    80000c12:	f04a                	sd	s2,32(sp)
    80000c14:	ec4e                	sd	s3,24(sp)
    80000c16:	e852                	sd	s4,16(sp)
    80000c18:	e456                	sd	s5,8(sp)
    80000c1a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000c1c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000c20:	00011a17          	auipc	s4,0x11
    80000c24:	8e0a0a13          	addi	s4,s4,-1824 # 80011500 <uart_tx_lock>
    uart_tx_r += 1;
    80000c28:	00008497          	auipc	s1,0x8
    80000c2c:	dd048493          	addi	s1,s1,-560 # 800089f8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000c30:	00008997          	auipc	s3,0x8
    80000c34:	dd098993          	addi	s3,s3,-560 # 80008a00 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000c38:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000c3c:	02077713          	andi	a4,a4,32
    80000c40:	c705                	beqz	a4,80000c68 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000c42:	01f7f713          	andi	a4,a5,31
    80000c46:	9752                	add	a4,a4,s4
    80000c48:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    80000c4c:	0785                	addi	a5,a5,1
    80000c4e:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000c50:	8526                	mv	a0,s1
    80000c52:	00002097          	auipc	ra,0x2
    80000c56:	826080e7          	jalr	-2010(ra) # 80002478 <wakeup>
    
    WriteReg(THR, c);
    80000c5a:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    80000c5e:	609c                	ld	a5,0(s1)
    80000c60:	0009b703          	ld	a4,0(s3)
    80000c64:	fcf71ae3          	bne	a4,a5,80000c38 <uartstart+0x42>
  }
}
    80000c68:	70e2                	ld	ra,56(sp)
    80000c6a:	7442                	ld	s0,48(sp)
    80000c6c:	74a2                	ld	s1,40(sp)
    80000c6e:	7902                	ld	s2,32(sp)
    80000c70:	69e2                	ld	s3,24(sp)
    80000c72:	6a42                	ld	s4,16(sp)
    80000c74:	6aa2                	ld	s5,8(sp)
    80000c76:	6121                	addi	sp,sp,64
    80000c78:	8082                	ret
    80000c7a:	8082                	ret

0000000080000c7c <uartputc>:
{
    80000c7c:	7179                	addi	sp,sp,-48
    80000c7e:	f406                	sd	ra,40(sp)
    80000c80:	f022                	sd	s0,32(sp)
    80000c82:	ec26                	sd	s1,24(sp)
    80000c84:	e84a                	sd	s2,16(sp)
    80000c86:	e44e                	sd	s3,8(sp)
    80000c88:	e052                	sd	s4,0(sp)
    80000c8a:	1800                	addi	s0,sp,48
    80000c8c:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    80000c8e:	00011517          	auipc	a0,0x11
    80000c92:	87250513          	addi	a0,a0,-1934 # 80011500 <uart_tx_lock>
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	300080e7          	jalr	768(ra) # 80000f96 <acquire>
  if(panicked){
    80000c9e:	00008797          	auipc	a5,0x8
    80000ca2:	d567a783          	lw	a5,-682(a5) # 800089f4 <panicked>
    80000ca6:	e7c9                	bnez	a5,80000d30 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000ca8:	00008717          	auipc	a4,0x8
    80000cac:	d5873703          	ld	a4,-680(a4) # 80008a00 <uart_tx_w>
    80000cb0:	00008797          	auipc	a5,0x8
    80000cb4:	d487b783          	ld	a5,-696(a5) # 800089f8 <uart_tx_r>
    80000cb8:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000cbc:	00011997          	auipc	s3,0x11
    80000cc0:	84498993          	addi	s3,s3,-1980 # 80011500 <uart_tx_lock>
    80000cc4:	00008497          	auipc	s1,0x8
    80000cc8:	d3448493          	addi	s1,s1,-716 # 800089f8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000ccc:	00008917          	auipc	s2,0x8
    80000cd0:	d3490913          	addi	s2,s2,-716 # 80008a00 <uart_tx_w>
    80000cd4:	00e79f63          	bne	a5,a4,80000cf2 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000cd8:	85ce                	mv	a1,s3
    80000cda:	8526                	mv	a0,s1
    80000cdc:	00001097          	auipc	ra,0x1
    80000ce0:	738080e7          	jalr	1848(ra) # 80002414 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000ce4:	00093703          	ld	a4,0(s2)
    80000ce8:	609c                	ld	a5,0(s1)
    80000cea:	02078793          	addi	a5,a5,32
    80000cee:	fee785e3          	beq	a5,a4,80000cd8 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000cf2:	00011497          	auipc	s1,0x11
    80000cf6:	80e48493          	addi	s1,s1,-2034 # 80011500 <uart_tx_lock>
    80000cfa:	01f77793          	andi	a5,a4,31
    80000cfe:	97a6                	add	a5,a5,s1
    80000d00:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000d04:	0705                	addi	a4,a4,1
    80000d06:	00008797          	auipc	a5,0x8
    80000d0a:	cee7bd23          	sd	a4,-774(a5) # 80008a00 <uart_tx_w>
  uartstart();
    80000d0e:	00000097          	auipc	ra,0x0
    80000d12:	ee8080e7          	jalr	-280(ra) # 80000bf6 <uartstart>
  release(&uart_tx_lock);
    80000d16:	8526                	mv	a0,s1
    80000d18:	00000097          	auipc	ra,0x0
    80000d1c:	332080e7          	jalr	818(ra) # 8000104a <release>
}
    80000d20:	70a2                	ld	ra,40(sp)
    80000d22:	7402                	ld	s0,32(sp)
    80000d24:	64e2                	ld	s1,24(sp)
    80000d26:	6942                	ld	s2,16(sp)
    80000d28:	69a2                	ld	s3,8(sp)
    80000d2a:	6a02                	ld	s4,0(sp)
    80000d2c:	6145                	addi	sp,sp,48
    80000d2e:	8082                	ret
    for(;;)
    80000d30:	a001                	j	80000d30 <uartputc+0xb4>

0000000080000d32 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000d32:	1141                	addi	sp,sp,-16
    80000d34:	e422                	sd	s0,8(sp)
    80000d36:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000d38:	100007b7          	lui	a5,0x10000
    80000d3c:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000d40:	8b85                	andi	a5,a5,1
    80000d42:	cb91                	beqz	a5,80000d56 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000d44:	100007b7          	lui	a5,0x10000
    80000d48:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    80000d4c:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000d50:	6422                	ld	s0,8(sp)
    80000d52:	0141                	addi	sp,sp,16
    80000d54:	8082                	ret
    return -1;
    80000d56:	557d                	li	a0,-1
    80000d58:	bfe5                	j	80000d50 <uartgetc+0x1e>

0000000080000d5a <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000d5a:	1101                	addi	sp,sp,-32
    80000d5c:	ec06                	sd	ra,24(sp)
    80000d5e:	e822                	sd	s0,16(sp)
    80000d60:	e426                	sd	s1,8(sp)
    80000d62:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000d64:	54fd                	li	s1,-1
    80000d66:	a029                	j	80000d70 <uartintr+0x16>
      break;
    consoleintr(c);
    80000d68:	fffff097          	auipc	ra,0xfffff
    80000d6c:	63e080e7          	jalr	1598(ra) # 800003a6 <consoleintr>
    int c = uartgetc();
    80000d70:	00000097          	auipc	ra,0x0
    80000d74:	fc2080e7          	jalr	-62(ra) # 80000d32 <uartgetc>
    if(c == -1)
    80000d78:	fe9518e3          	bne	a0,s1,80000d68 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    80000d7c:	00010497          	auipc	s1,0x10
    80000d80:	78448493          	addi	s1,s1,1924 # 80011500 <uart_tx_lock>
    80000d84:	8526                	mv	a0,s1
    80000d86:	00000097          	auipc	ra,0x0
    80000d8a:	210080e7          	jalr	528(ra) # 80000f96 <acquire>
  uartstart();
    80000d8e:	00000097          	auipc	ra,0x0
    80000d92:	e68080e7          	jalr	-408(ra) # 80000bf6 <uartstart>
  release(&uart_tx_lock);
    80000d96:	8526                	mv	a0,s1
    80000d98:	00000097          	auipc	ra,0x0
    80000d9c:	2b2080e7          	jalr	690(ra) # 8000104a <release>
}
    80000da0:	60e2                	ld	ra,24(sp)
    80000da2:	6442                	ld	s0,16(sp)
    80000da4:	64a2                	ld	s1,8(sp)
    80000da6:	6105                	addi	sp,sp,32
    80000da8:	8082                	ret

0000000080000daa <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000daa:	1101                	addi	sp,sp,-32
    80000dac:	ec06                	sd	ra,24(sp)
    80000dae:	e822                	sd	s0,16(sp)
    80000db0:	e426                	sd	s1,8(sp)
    80000db2:	e04a                	sd	s2,0(sp)
    80000db4:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000db6:	03451793          	slli	a5,a0,0x34
    80000dba:	ebb9                	bnez	a5,80000e10 <kfree+0x66>
    80000dbc:	84aa                	mv	s1,a0
    80000dbe:	00022797          	auipc	a5,0x22
    80000dc2:	9aa78793          	addi	a5,a5,-1622 # 80022768 <end>
    80000dc6:	04f56563          	bltu	a0,a5,80000e10 <kfree+0x66>
    80000dca:	47c5                	li	a5,17
    80000dcc:	07ee                	slli	a5,a5,0x1b
    80000dce:	04f57163          	bgeu	a0,a5,80000e10 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000dd2:	6605                	lui	a2,0x1
    80000dd4:	4585                	li	a1,1
    80000dd6:	00000097          	auipc	ra,0x0
    80000dda:	2bc080e7          	jalr	700(ra) # 80001092 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000dde:	00010917          	auipc	s2,0x10
    80000de2:	75a90913          	addi	s2,s2,1882 # 80011538 <kmem>
    80000de6:	854a                	mv	a0,s2
    80000de8:	00000097          	auipc	ra,0x0
    80000dec:	1ae080e7          	jalr	430(ra) # 80000f96 <acquire>
  r->next = kmem.freelist;
    80000df0:	01893783          	ld	a5,24(s2)
    80000df4:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000df6:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000dfa:	854a                	mv	a0,s2
    80000dfc:	00000097          	auipc	ra,0x0
    80000e00:	24e080e7          	jalr	590(ra) # 8000104a <release>
}
    80000e04:	60e2                	ld	ra,24(sp)
    80000e06:	6442                	ld	s0,16(sp)
    80000e08:	64a2                	ld	s1,8(sp)
    80000e0a:	6902                	ld	s2,0(sp)
    80000e0c:	6105                	addi	sp,sp,32
    80000e0e:	8082                	ret
    panic("kfree");
    80000e10:	00007517          	auipc	a0,0x7
    80000e14:	2a050513          	addi	a0,a0,672 # 800080b0 <digits+0x20>
    80000e18:	00000097          	auipc	ra,0x0
    80000e1c:	ae6080e7          	jalr	-1306(ra) # 800008fe <panic>

0000000080000e20 <freerange>:
{
    80000e20:	7179                	addi	sp,sp,-48
    80000e22:	f406                	sd	ra,40(sp)
    80000e24:	f022                	sd	s0,32(sp)
    80000e26:	ec26                	sd	s1,24(sp)
    80000e28:	e84a                	sd	s2,16(sp)
    80000e2a:	e44e                	sd	s3,8(sp)
    80000e2c:	e052                	sd	s4,0(sp)
    80000e2e:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000e30:	6785                	lui	a5,0x1
    80000e32:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000e36:	94aa                	add	s1,s1,a0
    80000e38:	757d                	lui	a0,0xfffff
    80000e3a:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000e3c:	94be                	add	s1,s1,a5
    80000e3e:	0095ee63          	bltu	a1,s1,80000e5a <freerange+0x3a>
    80000e42:	892e                	mv	s2,a1
    kfree(p);
    80000e44:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000e46:	6985                	lui	s3,0x1
    kfree(p);
    80000e48:	01448533          	add	a0,s1,s4
    80000e4c:	00000097          	auipc	ra,0x0
    80000e50:	f5e080e7          	jalr	-162(ra) # 80000daa <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000e54:	94ce                	add	s1,s1,s3
    80000e56:	fe9979e3          	bgeu	s2,s1,80000e48 <freerange+0x28>
}
    80000e5a:	70a2                	ld	ra,40(sp)
    80000e5c:	7402                	ld	s0,32(sp)
    80000e5e:	64e2                	ld	s1,24(sp)
    80000e60:	6942                	ld	s2,16(sp)
    80000e62:	69a2                	ld	s3,8(sp)
    80000e64:	6a02                	ld	s4,0(sp)
    80000e66:	6145                	addi	sp,sp,48
    80000e68:	8082                	ret

0000000080000e6a <kinit>:
{
    80000e6a:	1141                	addi	sp,sp,-16
    80000e6c:	e406                	sd	ra,8(sp)
    80000e6e:	e022                	sd	s0,0(sp)
    80000e70:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000e72:	00007597          	auipc	a1,0x7
    80000e76:	24658593          	addi	a1,a1,582 # 800080b8 <digits+0x28>
    80000e7a:	00010517          	auipc	a0,0x10
    80000e7e:	6be50513          	addi	a0,a0,1726 # 80011538 <kmem>
    80000e82:	00000097          	auipc	ra,0x0
    80000e86:	084080e7          	jalr	132(ra) # 80000f06 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000e8a:	45c5                	li	a1,17
    80000e8c:	05ee                	slli	a1,a1,0x1b
    80000e8e:	00022517          	auipc	a0,0x22
    80000e92:	8da50513          	addi	a0,a0,-1830 # 80022768 <end>
    80000e96:	00000097          	auipc	ra,0x0
    80000e9a:	f8a080e7          	jalr	-118(ra) # 80000e20 <freerange>
}
    80000e9e:	60a2                	ld	ra,8(sp)
    80000ea0:	6402                	ld	s0,0(sp)
    80000ea2:	0141                	addi	sp,sp,16
    80000ea4:	8082                	ret

0000000080000ea6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ea6:	1101                	addi	sp,sp,-32
    80000ea8:	ec06                	sd	ra,24(sp)
    80000eaa:	e822                	sd	s0,16(sp)
    80000eac:	e426                	sd	s1,8(sp)
    80000eae:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000eb0:	00010497          	auipc	s1,0x10
    80000eb4:	68848493          	addi	s1,s1,1672 # 80011538 <kmem>
    80000eb8:	8526                	mv	a0,s1
    80000eba:	00000097          	auipc	ra,0x0
    80000ebe:	0dc080e7          	jalr	220(ra) # 80000f96 <acquire>
  r = kmem.freelist;
    80000ec2:	6c84                	ld	s1,24(s1)
  if(r)
    80000ec4:	c885                	beqz	s1,80000ef4 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000ec6:	609c                	ld	a5,0(s1)
    80000ec8:	00010517          	auipc	a0,0x10
    80000ecc:	67050513          	addi	a0,a0,1648 # 80011538 <kmem>
    80000ed0:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000ed2:	00000097          	auipc	ra,0x0
    80000ed6:	178080e7          	jalr	376(ra) # 8000104a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000eda:	6605                	lui	a2,0x1
    80000edc:	4595                	li	a1,5
    80000ede:	8526                	mv	a0,s1
    80000ee0:	00000097          	auipc	ra,0x0
    80000ee4:	1b2080e7          	jalr	434(ra) # 80001092 <memset>
  return (void*)r;
}
    80000ee8:	8526                	mv	a0,s1
    80000eea:	60e2                	ld	ra,24(sp)
    80000eec:	6442                	ld	s0,16(sp)
    80000eee:	64a2                	ld	s1,8(sp)
    80000ef0:	6105                	addi	sp,sp,32
    80000ef2:	8082                	ret
  release(&kmem.lock);
    80000ef4:	00010517          	auipc	a0,0x10
    80000ef8:	64450513          	addi	a0,a0,1604 # 80011538 <kmem>
    80000efc:	00000097          	auipc	ra,0x0
    80000f00:	14e080e7          	jalr	334(ra) # 8000104a <release>
  if(r)
    80000f04:	b7d5                	j	80000ee8 <kalloc+0x42>

0000000080000f06 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000f06:	1141                	addi	sp,sp,-16
    80000f08:	e422                	sd	s0,8(sp)
    80000f0a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000f0c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000f0e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000f12:	00053823          	sd	zero,16(a0)
}
    80000f16:	6422                	ld	s0,8(sp)
    80000f18:	0141                	addi	sp,sp,16
    80000f1a:	8082                	ret

0000000080000f1c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000f1c:	411c                	lw	a5,0(a0)
    80000f1e:	e399                	bnez	a5,80000f24 <holding+0x8>
    80000f20:	4501                	li	a0,0
  return r;
}
    80000f22:	8082                	ret
{
    80000f24:	1101                	addi	sp,sp,-32
    80000f26:	ec06                	sd	ra,24(sp)
    80000f28:	e822                	sd	s0,16(sp)
    80000f2a:	e426                	sd	s1,8(sp)
    80000f2c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000f2e:	6904                	ld	s1,16(a0)
    80000f30:	00001097          	auipc	ra,0x1
    80000f34:	e20080e7          	jalr	-480(ra) # 80001d50 <mycpu>
    80000f38:	40a48533          	sub	a0,s1,a0
    80000f3c:	00153513          	seqz	a0,a0
}
    80000f40:	60e2                	ld	ra,24(sp)
    80000f42:	6442                	ld	s0,16(sp)
    80000f44:	64a2                	ld	s1,8(sp)
    80000f46:	6105                	addi	sp,sp,32
    80000f48:	8082                	ret

0000000080000f4a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000f4a:	1101                	addi	sp,sp,-32
    80000f4c:	ec06                	sd	ra,24(sp)
    80000f4e:	e822                	sd	s0,16(sp)
    80000f50:	e426                	sd	s1,8(sp)
    80000f52:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000f54:	100024f3          	csrr	s1,sstatus
    80000f58:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000f5c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000f5e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000f62:	00001097          	auipc	ra,0x1
    80000f66:	dee080e7          	jalr	-530(ra) # 80001d50 <mycpu>
    80000f6a:	5d3c                	lw	a5,120(a0)
    80000f6c:	cf89                	beqz	a5,80000f86 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000f6e:	00001097          	auipc	ra,0x1
    80000f72:	de2080e7          	jalr	-542(ra) # 80001d50 <mycpu>
    80000f76:	5d3c                	lw	a5,120(a0)
    80000f78:	2785                	addiw	a5,a5,1
    80000f7a:	dd3c                	sw	a5,120(a0)
}
    80000f7c:	60e2                	ld	ra,24(sp)
    80000f7e:	6442                	ld	s0,16(sp)
    80000f80:	64a2                	ld	s1,8(sp)
    80000f82:	6105                	addi	sp,sp,32
    80000f84:	8082                	ret
    mycpu()->intena = old;
    80000f86:	00001097          	auipc	ra,0x1
    80000f8a:	dca080e7          	jalr	-566(ra) # 80001d50 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000f8e:	8085                	srli	s1,s1,0x1
    80000f90:	8885                	andi	s1,s1,1
    80000f92:	dd64                	sw	s1,124(a0)
    80000f94:	bfe9                	j	80000f6e <push_off+0x24>

0000000080000f96 <acquire>:
{
    80000f96:	1101                	addi	sp,sp,-32
    80000f98:	ec06                	sd	ra,24(sp)
    80000f9a:	e822                	sd	s0,16(sp)
    80000f9c:	e426                	sd	s1,8(sp)
    80000f9e:	1000                	addi	s0,sp,32
    80000fa0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000fa2:	00000097          	auipc	ra,0x0
    80000fa6:	fa8080e7          	jalr	-88(ra) # 80000f4a <push_off>
  if(holding(lk))
    80000faa:	8526                	mv	a0,s1
    80000fac:	00000097          	auipc	ra,0x0
    80000fb0:	f70080e7          	jalr	-144(ra) # 80000f1c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000fb4:	4705                	li	a4,1
  if(holding(lk))
    80000fb6:	e115                	bnez	a0,80000fda <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000fb8:	87ba                	mv	a5,a4
    80000fba:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000fbe:	2781                	sext.w	a5,a5
    80000fc0:	ffe5                	bnez	a5,80000fb8 <acquire+0x22>
  __sync_synchronize();
    80000fc2:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000fc6:	00001097          	auipc	ra,0x1
    80000fca:	d8a080e7          	jalr	-630(ra) # 80001d50 <mycpu>
    80000fce:	e888                	sd	a0,16(s1)
}
    80000fd0:	60e2                	ld	ra,24(sp)
    80000fd2:	6442                	ld	s0,16(sp)
    80000fd4:	64a2                	ld	s1,8(sp)
    80000fd6:	6105                	addi	sp,sp,32
    80000fd8:	8082                	ret
    panic("acquire");
    80000fda:	00007517          	auipc	a0,0x7
    80000fde:	0e650513          	addi	a0,a0,230 # 800080c0 <digits+0x30>
    80000fe2:	00000097          	auipc	ra,0x0
    80000fe6:	91c080e7          	jalr	-1764(ra) # 800008fe <panic>

0000000080000fea <pop_off>:

void
pop_off(void)
{
    80000fea:	1141                	addi	sp,sp,-16
    80000fec:	e406                	sd	ra,8(sp)
    80000fee:	e022                	sd	s0,0(sp)
    80000ff0:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000ff2:	00001097          	auipc	ra,0x1
    80000ff6:	d5e080e7          	jalr	-674(ra) # 80001d50 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ffa:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000ffe:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001000:	e78d                	bnez	a5,8000102a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80001002:	5d3c                	lw	a5,120(a0)
    80001004:	02f05b63          	blez	a5,8000103a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80001008:	37fd                	addiw	a5,a5,-1
    8000100a:	0007871b          	sext.w	a4,a5
    8000100e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80001010:	eb09                	bnez	a4,80001022 <pop_off+0x38>
    80001012:	5d7c                	lw	a5,124(a0)
    80001014:	c799                	beqz	a5,80001022 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001016:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000101a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000101e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80001022:	60a2                	ld	ra,8(sp)
    80001024:	6402                	ld	s0,0(sp)
    80001026:	0141                	addi	sp,sp,16
    80001028:	8082                	ret
    panic("pop_off - interruptible");
    8000102a:	00007517          	auipc	a0,0x7
    8000102e:	09e50513          	addi	a0,a0,158 # 800080c8 <digits+0x38>
    80001032:	00000097          	auipc	ra,0x0
    80001036:	8cc080e7          	jalr	-1844(ra) # 800008fe <panic>
    panic("pop_off");
    8000103a:	00007517          	auipc	a0,0x7
    8000103e:	0a650513          	addi	a0,a0,166 # 800080e0 <digits+0x50>
    80001042:	00000097          	auipc	ra,0x0
    80001046:	8bc080e7          	jalr	-1860(ra) # 800008fe <panic>

000000008000104a <release>:
{
    8000104a:	1101                	addi	sp,sp,-32
    8000104c:	ec06                	sd	ra,24(sp)
    8000104e:	e822                	sd	s0,16(sp)
    80001050:	e426                	sd	s1,8(sp)
    80001052:	1000                	addi	s0,sp,32
    80001054:	84aa                	mv	s1,a0
  if(!holding(lk))
    80001056:	00000097          	auipc	ra,0x0
    8000105a:	ec6080e7          	jalr	-314(ra) # 80000f1c <holding>
    8000105e:	c115                	beqz	a0,80001082 <release+0x38>
  lk->cpu = 0;
    80001060:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80001064:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80001068:	0f50000f          	fence	iorw,ow
    8000106c:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80001070:	00000097          	auipc	ra,0x0
    80001074:	f7a080e7          	jalr	-134(ra) # 80000fea <pop_off>
}
    80001078:	60e2                	ld	ra,24(sp)
    8000107a:	6442                	ld	s0,16(sp)
    8000107c:	64a2                	ld	s1,8(sp)
    8000107e:	6105                	addi	sp,sp,32
    80001080:	8082                	ret
    panic("release");
    80001082:	00007517          	auipc	a0,0x7
    80001086:	06650513          	addi	a0,a0,102 # 800080e8 <digits+0x58>
    8000108a:	00000097          	auipc	ra,0x0
    8000108e:	874080e7          	jalr	-1932(ra) # 800008fe <panic>

0000000080001092 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80001092:	1141                	addi	sp,sp,-16
    80001094:	e422                	sd	s0,8(sp)
    80001096:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80001098:	ca19                	beqz	a2,800010ae <memset+0x1c>
    8000109a:	87aa                	mv	a5,a0
    8000109c:	1602                	slli	a2,a2,0x20
    8000109e:	9201                	srli	a2,a2,0x20
    800010a0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    800010a4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    800010a8:	0785                	addi	a5,a5,1
    800010aa:	fee79de3          	bne	a5,a4,800010a4 <memset+0x12>
  }
  return dst;
}
    800010ae:	6422                	ld	s0,8(sp)
    800010b0:	0141                	addi	sp,sp,16
    800010b2:	8082                	ret

00000000800010b4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    800010b4:	1141                	addi	sp,sp,-16
    800010b6:	e422                	sd	s0,8(sp)
    800010b8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    800010ba:	ca05                	beqz	a2,800010ea <memcmp+0x36>
    800010bc:	fff6069b          	addiw	a3,a2,-1
    800010c0:	1682                	slli	a3,a3,0x20
    800010c2:	9281                	srli	a3,a3,0x20
    800010c4:	0685                	addi	a3,a3,1
    800010c6:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    800010c8:	00054783          	lbu	a5,0(a0)
    800010cc:	0005c703          	lbu	a4,0(a1)
    800010d0:	00e79863          	bne	a5,a4,800010e0 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    800010d4:	0505                	addi	a0,a0,1
    800010d6:	0585                	addi	a1,a1,1
  while(n-- > 0){
    800010d8:	fed518e3          	bne	a0,a3,800010c8 <memcmp+0x14>
  }

  return 0;
    800010dc:	4501                	li	a0,0
    800010de:	a019                	j	800010e4 <memcmp+0x30>
      return *s1 - *s2;
    800010e0:	40e7853b          	subw	a0,a5,a4
}
    800010e4:	6422                	ld	s0,8(sp)
    800010e6:	0141                	addi	sp,sp,16
    800010e8:	8082                	ret
  return 0;
    800010ea:	4501                	li	a0,0
    800010ec:	bfe5                	j	800010e4 <memcmp+0x30>

00000000800010ee <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    800010ee:	1141                	addi	sp,sp,-16
    800010f0:	e422                	sd	s0,8(sp)
    800010f2:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    800010f4:	c205                	beqz	a2,80001114 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    800010f6:	02a5e263          	bltu	a1,a0,8000111a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    800010fa:	1602                	slli	a2,a2,0x20
    800010fc:	9201                	srli	a2,a2,0x20
    800010fe:	00c587b3          	add	a5,a1,a2
{
    80001102:	872a                	mv	a4,a0
      *d++ = *s++;
    80001104:	0585                	addi	a1,a1,1
    80001106:	0705                	addi	a4,a4,1
    80001108:	fff5c683          	lbu	a3,-1(a1)
    8000110c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80001110:	fef59ae3          	bne	a1,a5,80001104 <memmove+0x16>

  return dst;
}
    80001114:	6422                	ld	s0,8(sp)
    80001116:	0141                	addi	sp,sp,16
    80001118:	8082                	ret
  if(s < d && s + n > d){
    8000111a:	02061693          	slli	a3,a2,0x20
    8000111e:	9281                	srli	a3,a3,0x20
    80001120:	00d58733          	add	a4,a1,a3
    80001124:	fce57be3          	bgeu	a0,a4,800010fa <memmove+0xc>
    d += n;
    80001128:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    8000112a:	fff6079b          	addiw	a5,a2,-1
    8000112e:	1782                	slli	a5,a5,0x20
    80001130:	9381                	srli	a5,a5,0x20
    80001132:	fff7c793          	not	a5,a5
    80001136:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80001138:	177d                	addi	a4,a4,-1
    8000113a:	16fd                	addi	a3,a3,-1
    8000113c:	00074603          	lbu	a2,0(a4)
    80001140:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80001144:	fee79ae3          	bne	a5,a4,80001138 <memmove+0x4a>
    80001148:	b7f1                	j	80001114 <memmove+0x26>

000000008000114a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    8000114a:	1141                	addi	sp,sp,-16
    8000114c:	e406                	sd	ra,8(sp)
    8000114e:	e022                	sd	s0,0(sp)
    80001150:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80001152:	00000097          	auipc	ra,0x0
    80001156:	f9c080e7          	jalr	-100(ra) # 800010ee <memmove>
}
    8000115a:	60a2                	ld	ra,8(sp)
    8000115c:	6402                	ld	s0,0(sp)
    8000115e:	0141                	addi	sp,sp,16
    80001160:	8082                	ret

0000000080001162 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80001162:	1141                	addi	sp,sp,-16
    80001164:	e422                	sd	s0,8(sp)
    80001166:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80001168:	ce11                	beqz	a2,80001184 <strncmp+0x22>
    8000116a:	00054783          	lbu	a5,0(a0)
    8000116e:	cf89                	beqz	a5,80001188 <strncmp+0x26>
    80001170:	0005c703          	lbu	a4,0(a1)
    80001174:	00f71a63          	bne	a4,a5,80001188 <strncmp+0x26>
    n--, p++, q++;
    80001178:	367d                	addiw	a2,a2,-1
    8000117a:	0505                	addi	a0,a0,1
    8000117c:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    8000117e:	f675                	bnez	a2,8000116a <strncmp+0x8>
  if(n == 0)
    return 0;
    80001180:	4501                	li	a0,0
    80001182:	a809                	j	80001194 <strncmp+0x32>
    80001184:	4501                	li	a0,0
    80001186:	a039                	j	80001194 <strncmp+0x32>
  if(n == 0)
    80001188:	ca09                	beqz	a2,8000119a <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    8000118a:	00054503          	lbu	a0,0(a0)
    8000118e:	0005c783          	lbu	a5,0(a1)
    80001192:	9d1d                	subw	a0,a0,a5
}
    80001194:	6422                	ld	s0,8(sp)
    80001196:	0141                	addi	sp,sp,16
    80001198:	8082                	ret
    return 0;
    8000119a:	4501                	li	a0,0
    8000119c:	bfe5                	j	80001194 <strncmp+0x32>

000000008000119e <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    8000119e:	1141                	addi	sp,sp,-16
    800011a0:	e422                	sd	s0,8(sp)
    800011a2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    800011a4:	872a                	mv	a4,a0
    800011a6:	8832                	mv	a6,a2
    800011a8:	367d                	addiw	a2,a2,-1
    800011aa:	01005963          	blez	a6,800011bc <strncpy+0x1e>
    800011ae:	0705                	addi	a4,a4,1
    800011b0:	0005c783          	lbu	a5,0(a1)
    800011b4:	fef70fa3          	sb	a5,-1(a4)
    800011b8:	0585                	addi	a1,a1,1
    800011ba:	f7f5                	bnez	a5,800011a6 <strncpy+0x8>
    ;
  while(n-- > 0)
    800011bc:	86ba                	mv	a3,a4
    800011be:	00c05c63          	blez	a2,800011d6 <strncpy+0x38>
    *s++ = 0;
    800011c2:	0685                	addi	a3,a3,1
    800011c4:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    800011c8:	fff6c793          	not	a5,a3
    800011cc:	9fb9                	addw	a5,a5,a4
    800011ce:	010787bb          	addw	a5,a5,a6
    800011d2:	fef048e3          	bgtz	a5,800011c2 <strncpy+0x24>
  return os;
}
    800011d6:	6422                	ld	s0,8(sp)
    800011d8:	0141                	addi	sp,sp,16
    800011da:	8082                	ret

00000000800011dc <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    800011dc:	1141                	addi	sp,sp,-16
    800011de:	e422                	sd	s0,8(sp)
    800011e0:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    800011e2:	02c05363          	blez	a2,80001208 <safestrcpy+0x2c>
    800011e6:	fff6069b          	addiw	a3,a2,-1
    800011ea:	1682                	slli	a3,a3,0x20
    800011ec:	9281                	srli	a3,a3,0x20
    800011ee:	96ae                	add	a3,a3,a1
    800011f0:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    800011f2:	00d58963          	beq	a1,a3,80001204 <safestrcpy+0x28>
    800011f6:	0585                	addi	a1,a1,1
    800011f8:	0785                	addi	a5,a5,1
    800011fa:	fff5c703          	lbu	a4,-1(a1)
    800011fe:	fee78fa3          	sb	a4,-1(a5)
    80001202:	fb65                	bnez	a4,800011f2 <safestrcpy+0x16>
    ;
  *s = 0;
    80001204:	00078023          	sb	zero,0(a5)
  return os;
}
    80001208:	6422                	ld	s0,8(sp)
    8000120a:	0141                	addi	sp,sp,16
    8000120c:	8082                	ret

000000008000120e <strlen>:

int
strlen(const char *s)
{
    8000120e:	1141                	addi	sp,sp,-16
    80001210:	e422                	sd	s0,8(sp)
    80001212:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80001214:	00054783          	lbu	a5,0(a0)
    80001218:	cf91                	beqz	a5,80001234 <strlen+0x26>
    8000121a:	0505                	addi	a0,a0,1
    8000121c:	87aa                	mv	a5,a0
    8000121e:	4685                	li	a3,1
    80001220:	9e89                	subw	a3,a3,a0
    80001222:	00f6853b          	addw	a0,a3,a5
    80001226:	0785                	addi	a5,a5,1
    80001228:	fff7c703          	lbu	a4,-1(a5)
    8000122c:	fb7d                	bnez	a4,80001222 <strlen+0x14>
    ;
  return n;
}
    8000122e:	6422                	ld	s0,8(sp)
    80001230:	0141                	addi	sp,sp,16
    80001232:	8082                	ret
  for(n = 0; s[n]; n++)
    80001234:	4501                	li	a0,0
    80001236:	bfe5                	j	8000122e <strlen+0x20>

0000000080001238 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80001238:	1141                	addi	sp,sp,-16
    8000123a:	e406                	sd	ra,8(sp)
    8000123c:	e022                	sd	s0,0(sp)
    8000123e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80001240:	00001097          	auipc	ra,0x1
    80001244:	b00080e7          	jalr	-1280(ra) # 80001d40 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80001248:	00007717          	auipc	a4,0x7
    8000124c:	7c070713          	addi	a4,a4,1984 # 80008a08 <started>
  if(cpuid() == 0){
    80001250:	c139                	beqz	a0,80001296 <main+0x5e>
    while(started == 0)
    80001252:	431c                	lw	a5,0(a4)
    80001254:	2781                	sext.w	a5,a5
    80001256:	dff5                	beqz	a5,80001252 <main+0x1a>
      ;
    __sync_synchronize();
    80001258:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    8000125c:	00001097          	auipc	ra,0x1
    80001260:	ae4080e7          	jalr	-1308(ra) # 80001d40 <cpuid>
    80001264:	85aa                	mv	a1,a0
    80001266:	00007517          	auipc	a0,0x7
    8000126a:	ea250513          	addi	a0,a0,-350 # 80008108 <digits+0x78>
    8000126e:	fffff097          	auipc	ra,0xfffff
    80001272:	6da080e7          	jalr	1754(ra) # 80000948 <printf>
    kvminithart();    // turn on paging
    80001276:	00000097          	auipc	ra,0x0
    8000127a:	0d8080e7          	jalr	216(ra) # 8000134e <kvminithart>
    trapinithart();   // install kernel trap vector
    8000127e:	00002097          	auipc	ra,0x2
    80001282:	a9a080e7          	jalr	-1382(ra) # 80002d18 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80001286:	00005097          	auipc	ra,0x5
    8000128a:	07a080e7          	jalr	122(ra) # 80006300 <plicinithart>
  }

  scheduler();        
    8000128e:	00001097          	auipc	ra,0x1
    80001292:	fd4080e7          	jalr	-44(ra) # 80002262 <scheduler>
    consoleinit();
    80001296:	fffff097          	auipc	ra,0xfffff
    8000129a:	57a080e7          	jalr	1402(ra) # 80000810 <consoleinit>
    printfinit();
    8000129e:	00000097          	auipc	ra,0x0
    800012a2:	88a080e7          	jalr	-1910(ra) # 80000b28 <printfinit>
    printf("\n");
    800012a6:	00007517          	auipc	a0,0x7
    800012aa:	09a50513          	addi	a0,a0,154 # 80008340 <digits+0x2b0>
    800012ae:	fffff097          	auipc	ra,0xfffff
    800012b2:	69a080e7          	jalr	1690(ra) # 80000948 <printf>
    printf("xv6 kernel is booting\n");
    800012b6:	00007517          	auipc	a0,0x7
    800012ba:	e3a50513          	addi	a0,a0,-454 # 800080f0 <digits+0x60>
    800012be:	fffff097          	auipc	ra,0xfffff
    800012c2:	68a080e7          	jalr	1674(ra) # 80000948 <printf>
    printf("\n");
    800012c6:	00007517          	auipc	a0,0x7
    800012ca:	07a50513          	addi	a0,a0,122 # 80008340 <digits+0x2b0>
    800012ce:	fffff097          	auipc	ra,0xfffff
    800012d2:	67a080e7          	jalr	1658(ra) # 80000948 <printf>
    kinit();         // physical page allocator
    800012d6:	00000097          	auipc	ra,0x0
    800012da:	b94080e7          	jalr	-1132(ra) # 80000e6a <kinit>
    kvminit();       // create kernel page table
    800012de:	00000097          	auipc	ra,0x0
    800012e2:	326080e7          	jalr	806(ra) # 80001604 <kvminit>
    kvminithart();   // turn on paging
    800012e6:	00000097          	auipc	ra,0x0
    800012ea:	068080e7          	jalr	104(ra) # 8000134e <kvminithart>
    procinit();      // process table
    800012ee:	00001097          	auipc	ra,0x1
    800012f2:	99e080e7          	jalr	-1634(ra) # 80001c8c <procinit>
    trapinit();      // trap vectors
    800012f6:	00002097          	auipc	ra,0x2
    800012fa:	9fa080e7          	jalr	-1542(ra) # 80002cf0 <trapinit>
    trapinithart();  // install kernel trap vector
    800012fe:	00002097          	auipc	ra,0x2
    80001302:	a1a080e7          	jalr	-1510(ra) # 80002d18 <trapinithart>
    plicinit();      // set up interrupt controller
    80001306:	00005097          	auipc	ra,0x5
    8000130a:	fe4080e7          	jalr	-28(ra) # 800062ea <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    8000130e:	00005097          	auipc	ra,0x5
    80001312:	ff2080e7          	jalr	-14(ra) # 80006300 <plicinithart>
    binit();         // buffer cache
    80001316:	00002097          	auipc	ra,0x2
    8000131a:	190080e7          	jalr	400(ra) # 800034a6 <binit>
    iinit();         // inode table
    8000131e:	00003097          	auipc	ra,0x3
    80001322:	834080e7          	jalr	-1996(ra) # 80003b52 <iinit>
    fileinit();      // file table
    80001326:	00003097          	auipc	ra,0x3
    8000132a:	7d2080e7          	jalr	2002(ra) # 80004af8 <fileinit>
    virtio_disk_init(); // emulated hard disk
    8000132e:	00005097          	auipc	ra,0x5
    80001332:	0da080e7          	jalr	218(ra) # 80006408 <virtio_disk_init>
    userinit();      // first user process
    80001336:	00001097          	auipc	ra,0x1
    8000133a:	d0e080e7          	jalr	-754(ra) # 80002044 <userinit>
    __sync_synchronize();
    8000133e:	0ff0000f          	fence
    started = 1;
    80001342:	4785                	li	a5,1
    80001344:	00007717          	auipc	a4,0x7
    80001348:	6cf72223          	sw	a5,1732(a4) # 80008a08 <started>
    8000134c:	b789                	j	8000128e <main+0x56>

000000008000134e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    8000134e:	1141                	addi	sp,sp,-16
    80001350:	e422                	sd	s0,8(sp)
    80001352:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001354:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80001358:	00007797          	auipc	a5,0x7
    8000135c:	6b87b783          	ld	a5,1720(a5) # 80008a10 <kernel_pagetable>
    80001360:	83b1                	srli	a5,a5,0xc
    80001362:	577d                	li	a4,-1
    80001364:	177e                	slli	a4,a4,0x3f
    80001366:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001368:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    8000136c:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80001370:	6422                	ld	s0,8(sp)
    80001372:	0141                	addi	sp,sp,16
    80001374:	8082                	ret

0000000080001376 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001376:	7139                	addi	sp,sp,-64
    80001378:	fc06                	sd	ra,56(sp)
    8000137a:	f822                	sd	s0,48(sp)
    8000137c:	f426                	sd	s1,40(sp)
    8000137e:	f04a                	sd	s2,32(sp)
    80001380:	ec4e                	sd	s3,24(sp)
    80001382:	e852                	sd	s4,16(sp)
    80001384:	e456                	sd	s5,8(sp)
    80001386:	e05a                	sd	s6,0(sp)
    80001388:	0080                	addi	s0,sp,64
    8000138a:	84aa                	mv	s1,a0
    8000138c:	89ae                	mv	s3,a1
    8000138e:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001390:	57fd                	li	a5,-1
    80001392:	83e9                	srli	a5,a5,0x1a
    80001394:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001396:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001398:	04b7f263          	bgeu	a5,a1,800013dc <walk+0x66>
    panic("walk");
    8000139c:	00007517          	auipc	a0,0x7
    800013a0:	d8450513          	addi	a0,a0,-636 # 80008120 <digits+0x90>
    800013a4:	fffff097          	auipc	ra,0xfffff
    800013a8:	55a080e7          	jalr	1370(ra) # 800008fe <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    800013ac:	060a8663          	beqz	s5,80001418 <walk+0xa2>
    800013b0:	00000097          	auipc	ra,0x0
    800013b4:	af6080e7          	jalr	-1290(ra) # 80000ea6 <kalloc>
    800013b8:	84aa                	mv	s1,a0
    800013ba:	c529                	beqz	a0,80001404 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    800013bc:	6605                	lui	a2,0x1
    800013be:	4581                	li	a1,0
    800013c0:	00000097          	auipc	ra,0x0
    800013c4:	cd2080e7          	jalr	-814(ra) # 80001092 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    800013c8:	00c4d793          	srli	a5,s1,0xc
    800013cc:	07aa                	slli	a5,a5,0xa
    800013ce:	0017e793          	ori	a5,a5,1
    800013d2:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    800013d6:	3a5d                	addiw	s4,s4,-9
    800013d8:	036a0063          	beq	s4,s6,800013f8 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800013dc:	0149d933          	srl	s2,s3,s4
    800013e0:	1ff97913          	andi	s2,s2,511
    800013e4:	090e                	slli	s2,s2,0x3
    800013e6:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800013e8:	00093483          	ld	s1,0(s2)
    800013ec:	0014f793          	andi	a5,s1,1
    800013f0:	dfd5                	beqz	a5,800013ac <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800013f2:	80a9                	srli	s1,s1,0xa
    800013f4:	04b2                	slli	s1,s1,0xc
    800013f6:	b7c5                	j	800013d6 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800013f8:	00c9d513          	srli	a0,s3,0xc
    800013fc:	1ff57513          	andi	a0,a0,511
    80001400:	050e                	slli	a0,a0,0x3
    80001402:	9526                	add	a0,a0,s1
}
    80001404:	70e2                	ld	ra,56(sp)
    80001406:	7442                	ld	s0,48(sp)
    80001408:	74a2                	ld	s1,40(sp)
    8000140a:	7902                	ld	s2,32(sp)
    8000140c:	69e2                	ld	s3,24(sp)
    8000140e:	6a42                	ld	s4,16(sp)
    80001410:	6aa2                	ld	s5,8(sp)
    80001412:	6b02                	ld	s6,0(sp)
    80001414:	6121                	addi	sp,sp,64
    80001416:	8082                	ret
        return 0;
    80001418:	4501                	li	a0,0
    8000141a:	b7ed                	j	80001404 <walk+0x8e>

000000008000141c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000141c:	57fd                	li	a5,-1
    8000141e:	83e9                	srli	a5,a5,0x1a
    80001420:	00b7f463          	bgeu	a5,a1,80001428 <walkaddr+0xc>
    return 0;
    80001424:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001426:	8082                	ret
{
    80001428:	1141                	addi	sp,sp,-16
    8000142a:	e406                	sd	ra,8(sp)
    8000142c:	e022                	sd	s0,0(sp)
    8000142e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001430:	4601                	li	a2,0
    80001432:	00000097          	auipc	ra,0x0
    80001436:	f44080e7          	jalr	-188(ra) # 80001376 <walk>
  if(pte == 0)
    8000143a:	c105                	beqz	a0,8000145a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000143c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000143e:	0117f693          	andi	a3,a5,17
    80001442:	4745                	li	a4,17
    return 0;
    80001444:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001446:	00e68663          	beq	a3,a4,80001452 <walkaddr+0x36>
}
    8000144a:	60a2                	ld	ra,8(sp)
    8000144c:	6402                	ld	s0,0(sp)
    8000144e:	0141                	addi	sp,sp,16
    80001450:	8082                	ret
  pa = PTE2PA(*pte);
    80001452:	00a7d513          	srli	a0,a5,0xa
    80001456:	0532                	slli	a0,a0,0xc
  return pa;
    80001458:	bfcd                	j	8000144a <walkaddr+0x2e>
    return 0;
    8000145a:	4501                	li	a0,0
    8000145c:	b7fd                	j	8000144a <walkaddr+0x2e>

000000008000145e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000145e:	715d                	addi	sp,sp,-80
    80001460:	e486                	sd	ra,72(sp)
    80001462:	e0a2                	sd	s0,64(sp)
    80001464:	fc26                	sd	s1,56(sp)
    80001466:	f84a                	sd	s2,48(sp)
    80001468:	f44e                	sd	s3,40(sp)
    8000146a:	f052                	sd	s4,32(sp)
    8000146c:	ec56                	sd	s5,24(sp)
    8000146e:	e85a                	sd	s6,16(sp)
    80001470:	e45e                	sd	s7,8(sp)
    80001472:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    80001474:	c639                	beqz	a2,800014c2 <mappages+0x64>
    80001476:	8aaa                	mv	s5,a0
    80001478:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    8000147a:	77fd                	lui	a5,0xfffff
    8000147c:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    80001480:	15fd                	addi	a1,a1,-1
    80001482:	00c589b3          	add	s3,a1,a2
    80001486:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    8000148a:	8952                	mv	s2,s4
    8000148c:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001490:	6b85                	lui	s7,0x1
    80001492:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001496:	4605                	li	a2,1
    80001498:	85ca                	mv	a1,s2
    8000149a:	8556                	mv	a0,s5
    8000149c:	00000097          	auipc	ra,0x0
    800014a0:	eda080e7          	jalr	-294(ra) # 80001376 <walk>
    800014a4:	cd1d                	beqz	a0,800014e2 <mappages+0x84>
    if(*pte & PTE_V)
    800014a6:	611c                	ld	a5,0(a0)
    800014a8:	8b85                	andi	a5,a5,1
    800014aa:	e785                	bnez	a5,800014d2 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800014ac:	80b1                	srli	s1,s1,0xc
    800014ae:	04aa                	slli	s1,s1,0xa
    800014b0:	0164e4b3          	or	s1,s1,s6
    800014b4:	0014e493          	ori	s1,s1,1
    800014b8:	e104                	sd	s1,0(a0)
    if(a == last)
    800014ba:	05390063          	beq	s2,s3,800014fa <mappages+0x9c>
    a += PGSIZE;
    800014be:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800014c0:	bfc9                	j	80001492 <mappages+0x34>
    panic("mappages: size");
    800014c2:	00007517          	auipc	a0,0x7
    800014c6:	c6650513          	addi	a0,a0,-922 # 80008128 <digits+0x98>
    800014ca:	fffff097          	auipc	ra,0xfffff
    800014ce:	434080e7          	jalr	1076(ra) # 800008fe <panic>
      panic("mappages: remap");
    800014d2:	00007517          	auipc	a0,0x7
    800014d6:	c6650513          	addi	a0,a0,-922 # 80008138 <digits+0xa8>
    800014da:	fffff097          	auipc	ra,0xfffff
    800014de:	424080e7          	jalr	1060(ra) # 800008fe <panic>
      return -1;
    800014e2:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800014e4:	60a6                	ld	ra,72(sp)
    800014e6:	6406                	ld	s0,64(sp)
    800014e8:	74e2                	ld	s1,56(sp)
    800014ea:	7942                	ld	s2,48(sp)
    800014ec:	79a2                	ld	s3,40(sp)
    800014ee:	7a02                	ld	s4,32(sp)
    800014f0:	6ae2                	ld	s5,24(sp)
    800014f2:	6b42                	ld	s6,16(sp)
    800014f4:	6ba2                	ld	s7,8(sp)
    800014f6:	6161                	addi	sp,sp,80
    800014f8:	8082                	ret
  return 0;
    800014fa:	4501                	li	a0,0
    800014fc:	b7e5                	j	800014e4 <mappages+0x86>

00000000800014fe <kvmmap>:
{
    800014fe:	1141                	addi	sp,sp,-16
    80001500:	e406                	sd	ra,8(sp)
    80001502:	e022                	sd	s0,0(sp)
    80001504:	0800                	addi	s0,sp,16
    80001506:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001508:	86b2                	mv	a3,a2
    8000150a:	863e                	mv	a2,a5
    8000150c:	00000097          	auipc	ra,0x0
    80001510:	f52080e7          	jalr	-174(ra) # 8000145e <mappages>
    80001514:	e509                	bnez	a0,8000151e <kvmmap+0x20>
}
    80001516:	60a2                	ld	ra,8(sp)
    80001518:	6402                	ld	s0,0(sp)
    8000151a:	0141                	addi	sp,sp,16
    8000151c:	8082                	ret
    panic("kvmmap");
    8000151e:	00007517          	auipc	a0,0x7
    80001522:	c2a50513          	addi	a0,a0,-982 # 80008148 <digits+0xb8>
    80001526:	fffff097          	auipc	ra,0xfffff
    8000152a:	3d8080e7          	jalr	984(ra) # 800008fe <panic>

000000008000152e <kvmmake>:
{
    8000152e:	1101                	addi	sp,sp,-32
    80001530:	ec06                	sd	ra,24(sp)
    80001532:	e822                	sd	s0,16(sp)
    80001534:	e426                	sd	s1,8(sp)
    80001536:	e04a                	sd	s2,0(sp)
    80001538:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000153a:	00000097          	auipc	ra,0x0
    8000153e:	96c080e7          	jalr	-1684(ra) # 80000ea6 <kalloc>
    80001542:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001544:	6605                	lui	a2,0x1
    80001546:	4581                	li	a1,0
    80001548:	00000097          	auipc	ra,0x0
    8000154c:	b4a080e7          	jalr	-1206(ra) # 80001092 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001550:	4719                	li	a4,6
    80001552:	6685                	lui	a3,0x1
    80001554:	10000637          	lui	a2,0x10000
    80001558:	100005b7          	lui	a1,0x10000
    8000155c:	8526                	mv	a0,s1
    8000155e:	00000097          	auipc	ra,0x0
    80001562:	fa0080e7          	jalr	-96(ra) # 800014fe <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001566:	4719                	li	a4,6
    80001568:	6685                	lui	a3,0x1
    8000156a:	10001637          	lui	a2,0x10001
    8000156e:	100015b7          	lui	a1,0x10001
    80001572:	8526                	mv	a0,s1
    80001574:	00000097          	auipc	ra,0x0
    80001578:	f8a080e7          	jalr	-118(ra) # 800014fe <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    8000157c:	4719                	li	a4,6
    8000157e:	004006b7          	lui	a3,0x400
    80001582:	0c000637          	lui	a2,0xc000
    80001586:	0c0005b7          	lui	a1,0xc000
    8000158a:	8526                	mv	a0,s1
    8000158c:	00000097          	auipc	ra,0x0
    80001590:	f72080e7          	jalr	-142(ra) # 800014fe <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001594:	00007917          	auipc	s2,0x7
    80001598:	a6c90913          	addi	s2,s2,-1428 # 80008000 <etext>
    8000159c:	4729                	li	a4,10
    8000159e:	80007697          	auipc	a3,0x80007
    800015a2:	a6268693          	addi	a3,a3,-1438 # 8000 <_entry-0x7fff8000>
    800015a6:	4605                	li	a2,1
    800015a8:	067e                	slli	a2,a2,0x1f
    800015aa:	85b2                	mv	a1,a2
    800015ac:	8526                	mv	a0,s1
    800015ae:	00000097          	auipc	ra,0x0
    800015b2:	f50080e7          	jalr	-176(ra) # 800014fe <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800015b6:	4719                	li	a4,6
    800015b8:	46c5                	li	a3,17
    800015ba:	06ee                	slli	a3,a3,0x1b
    800015bc:	412686b3          	sub	a3,a3,s2
    800015c0:	864a                	mv	a2,s2
    800015c2:	85ca                	mv	a1,s2
    800015c4:	8526                	mv	a0,s1
    800015c6:	00000097          	auipc	ra,0x0
    800015ca:	f38080e7          	jalr	-200(ra) # 800014fe <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800015ce:	4729                	li	a4,10
    800015d0:	6685                	lui	a3,0x1
    800015d2:	00006617          	auipc	a2,0x6
    800015d6:	a2e60613          	addi	a2,a2,-1490 # 80007000 <_trampoline>
    800015da:	040005b7          	lui	a1,0x4000
    800015de:	15fd                	addi	a1,a1,-1
    800015e0:	05b2                	slli	a1,a1,0xc
    800015e2:	8526                	mv	a0,s1
    800015e4:	00000097          	auipc	ra,0x0
    800015e8:	f1a080e7          	jalr	-230(ra) # 800014fe <kvmmap>
  proc_mapstacks(kpgtbl);
    800015ec:	8526                	mv	a0,s1
    800015ee:	00000097          	auipc	ra,0x0
    800015f2:	608080e7          	jalr	1544(ra) # 80001bf6 <proc_mapstacks>
}
    800015f6:	8526                	mv	a0,s1
    800015f8:	60e2                	ld	ra,24(sp)
    800015fa:	6442                	ld	s0,16(sp)
    800015fc:	64a2                	ld	s1,8(sp)
    800015fe:	6902                	ld	s2,0(sp)
    80001600:	6105                	addi	sp,sp,32
    80001602:	8082                	ret

0000000080001604 <kvminit>:
{
    80001604:	1141                	addi	sp,sp,-16
    80001606:	e406                	sd	ra,8(sp)
    80001608:	e022                	sd	s0,0(sp)
    8000160a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000160c:	00000097          	auipc	ra,0x0
    80001610:	f22080e7          	jalr	-222(ra) # 8000152e <kvmmake>
    80001614:	00007797          	auipc	a5,0x7
    80001618:	3ea7be23          	sd	a0,1020(a5) # 80008a10 <kernel_pagetable>
}
    8000161c:	60a2                	ld	ra,8(sp)
    8000161e:	6402                	ld	s0,0(sp)
    80001620:	0141                	addi	sp,sp,16
    80001622:	8082                	ret

0000000080001624 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001624:	715d                	addi	sp,sp,-80
    80001626:	e486                	sd	ra,72(sp)
    80001628:	e0a2                	sd	s0,64(sp)
    8000162a:	fc26                	sd	s1,56(sp)
    8000162c:	f84a                	sd	s2,48(sp)
    8000162e:	f44e                	sd	s3,40(sp)
    80001630:	f052                	sd	s4,32(sp)
    80001632:	ec56                	sd	s5,24(sp)
    80001634:	e85a                	sd	s6,16(sp)
    80001636:	e45e                	sd	s7,8(sp)
    80001638:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000163a:	03459793          	slli	a5,a1,0x34
    8000163e:	e795                	bnez	a5,8000166a <uvmunmap+0x46>
    80001640:	8a2a                	mv	s4,a0
    80001642:	892e                	mv	s2,a1
    80001644:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001646:	0632                	slli	a2,a2,0xc
    80001648:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000164c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000164e:	6b05                	lui	s6,0x1
    80001650:	0735e263          	bltu	a1,s3,800016b4 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001654:	60a6                	ld	ra,72(sp)
    80001656:	6406                	ld	s0,64(sp)
    80001658:	74e2                	ld	s1,56(sp)
    8000165a:	7942                	ld	s2,48(sp)
    8000165c:	79a2                	ld	s3,40(sp)
    8000165e:	7a02                	ld	s4,32(sp)
    80001660:	6ae2                	ld	s5,24(sp)
    80001662:	6b42                	ld	s6,16(sp)
    80001664:	6ba2                	ld	s7,8(sp)
    80001666:	6161                	addi	sp,sp,80
    80001668:	8082                	ret
    panic("uvmunmap: not aligned");
    8000166a:	00007517          	auipc	a0,0x7
    8000166e:	ae650513          	addi	a0,a0,-1306 # 80008150 <digits+0xc0>
    80001672:	fffff097          	auipc	ra,0xfffff
    80001676:	28c080e7          	jalr	652(ra) # 800008fe <panic>
      panic("uvmunmap: walk");
    8000167a:	00007517          	auipc	a0,0x7
    8000167e:	aee50513          	addi	a0,a0,-1298 # 80008168 <digits+0xd8>
    80001682:	fffff097          	auipc	ra,0xfffff
    80001686:	27c080e7          	jalr	636(ra) # 800008fe <panic>
      panic("uvmunmap: not mapped");
    8000168a:	00007517          	auipc	a0,0x7
    8000168e:	aee50513          	addi	a0,a0,-1298 # 80008178 <digits+0xe8>
    80001692:	fffff097          	auipc	ra,0xfffff
    80001696:	26c080e7          	jalr	620(ra) # 800008fe <panic>
      panic("uvmunmap: not a leaf");
    8000169a:	00007517          	auipc	a0,0x7
    8000169e:	af650513          	addi	a0,a0,-1290 # 80008190 <digits+0x100>
    800016a2:	fffff097          	auipc	ra,0xfffff
    800016a6:	25c080e7          	jalr	604(ra) # 800008fe <panic>
    *pte = 0;
    800016aa:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800016ae:	995a                	add	s2,s2,s6
    800016b0:	fb3972e3          	bgeu	s2,s3,80001654 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800016b4:	4601                	li	a2,0
    800016b6:	85ca                	mv	a1,s2
    800016b8:	8552                	mv	a0,s4
    800016ba:	00000097          	auipc	ra,0x0
    800016be:	cbc080e7          	jalr	-836(ra) # 80001376 <walk>
    800016c2:	84aa                	mv	s1,a0
    800016c4:	d95d                	beqz	a0,8000167a <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800016c6:	6108                	ld	a0,0(a0)
    800016c8:	00157793          	andi	a5,a0,1
    800016cc:	dfdd                	beqz	a5,8000168a <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800016ce:	3ff57793          	andi	a5,a0,1023
    800016d2:	fd7784e3          	beq	a5,s7,8000169a <uvmunmap+0x76>
    if(do_free){
    800016d6:	fc0a8ae3          	beqz	s5,800016aa <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    800016da:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800016dc:	0532                	slli	a0,a0,0xc
    800016de:	fffff097          	auipc	ra,0xfffff
    800016e2:	6cc080e7          	jalr	1740(ra) # 80000daa <kfree>
    800016e6:	b7d1                	j	800016aa <uvmunmap+0x86>

00000000800016e8 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800016e8:	1101                	addi	sp,sp,-32
    800016ea:	ec06                	sd	ra,24(sp)
    800016ec:	e822                	sd	s0,16(sp)
    800016ee:	e426                	sd	s1,8(sp)
    800016f0:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800016f2:	fffff097          	auipc	ra,0xfffff
    800016f6:	7b4080e7          	jalr	1972(ra) # 80000ea6 <kalloc>
    800016fa:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800016fc:	c519                	beqz	a0,8000170a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800016fe:	6605                	lui	a2,0x1
    80001700:	4581                	li	a1,0
    80001702:	00000097          	auipc	ra,0x0
    80001706:	990080e7          	jalr	-1648(ra) # 80001092 <memset>
  return pagetable;
}
    8000170a:	8526                	mv	a0,s1
    8000170c:	60e2                	ld	ra,24(sp)
    8000170e:	6442                	ld	s0,16(sp)
    80001710:	64a2                	ld	s1,8(sp)
    80001712:	6105                	addi	sp,sp,32
    80001714:	8082                	ret

0000000080001716 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001716:	7179                	addi	sp,sp,-48
    80001718:	f406                	sd	ra,40(sp)
    8000171a:	f022                	sd	s0,32(sp)
    8000171c:	ec26                	sd	s1,24(sp)
    8000171e:	e84a                	sd	s2,16(sp)
    80001720:	e44e                	sd	s3,8(sp)
    80001722:	e052                	sd	s4,0(sp)
    80001724:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001726:	6785                	lui	a5,0x1
    80001728:	04f67863          	bgeu	a2,a5,80001778 <uvmfirst+0x62>
    8000172c:	8a2a                	mv	s4,a0
    8000172e:	89ae                	mv	s3,a1
    80001730:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001732:	fffff097          	auipc	ra,0xfffff
    80001736:	774080e7          	jalr	1908(ra) # 80000ea6 <kalloc>
    8000173a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000173c:	6605                	lui	a2,0x1
    8000173e:	4581                	li	a1,0
    80001740:	00000097          	auipc	ra,0x0
    80001744:	952080e7          	jalr	-1710(ra) # 80001092 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001748:	4779                	li	a4,30
    8000174a:	86ca                	mv	a3,s2
    8000174c:	6605                	lui	a2,0x1
    8000174e:	4581                	li	a1,0
    80001750:	8552                	mv	a0,s4
    80001752:	00000097          	auipc	ra,0x0
    80001756:	d0c080e7          	jalr	-756(ra) # 8000145e <mappages>
  memmove(mem, src, sz);
    8000175a:	8626                	mv	a2,s1
    8000175c:	85ce                	mv	a1,s3
    8000175e:	854a                	mv	a0,s2
    80001760:	00000097          	auipc	ra,0x0
    80001764:	98e080e7          	jalr	-1650(ra) # 800010ee <memmove>
}
    80001768:	70a2                	ld	ra,40(sp)
    8000176a:	7402                	ld	s0,32(sp)
    8000176c:	64e2                	ld	s1,24(sp)
    8000176e:	6942                	ld	s2,16(sp)
    80001770:	69a2                	ld	s3,8(sp)
    80001772:	6a02                	ld	s4,0(sp)
    80001774:	6145                	addi	sp,sp,48
    80001776:	8082                	ret
    panic("uvmfirst: more than a page");
    80001778:	00007517          	auipc	a0,0x7
    8000177c:	a3050513          	addi	a0,a0,-1488 # 800081a8 <digits+0x118>
    80001780:	fffff097          	auipc	ra,0xfffff
    80001784:	17e080e7          	jalr	382(ra) # 800008fe <panic>

0000000080001788 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001788:	1101                	addi	sp,sp,-32
    8000178a:	ec06                	sd	ra,24(sp)
    8000178c:	e822                	sd	s0,16(sp)
    8000178e:	e426                	sd	s1,8(sp)
    80001790:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001792:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001794:	00b67d63          	bgeu	a2,a1,800017ae <uvmdealloc+0x26>
    80001798:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000179a:	6785                	lui	a5,0x1
    8000179c:	17fd                	addi	a5,a5,-1
    8000179e:	00f60733          	add	a4,a2,a5
    800017a2:	767d                	lui	a2,0xfffff
    800017a4:	8f71                	and	a4,a4,a2
    800017a6:	97ae                	add	a5,a5,a1
    800017a8:	8ff1                	and	a5,a5,a2
    800017aa:	00f76863          	bltu	a4,a5,800017ba <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800017ae:	8526                	mv	a0,s1
    800017b0:	60e2                	ld	ra,24(sp)
    800017b2:	6442                	ld	s0,16(sp)
    800017b4:	64a2                	ld	s1,8(sp)
    800017b6:	6105                	addi	sp,sp,32
    800017b8:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800017ba:	8f99                	sub	a5,a5,a4
    800017bc:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800017be:	4685                	li	a3,1
    800017c0:	0007861b          	sext.w	a2,a5
    800017c4:	85ba                	mv	a1,a4
    800017c6:	00000097          	auipc	ra,0x0
    800017ca:	e5e080e7          	jalr	-418(ra) # 80001624 <uvmunmap>
    800017ce:	b7c5                	j	800017ae <uvmdealloc+0x26>

00000000800017d0 <uvmalloc>:
  if(newsz < oldsz)
    800017d0:	0ab66563          	bltu	a2,a1,8000187a <uvmalloc+0xaa>
{
    800017d4:	7139                	addi	sp,sp,-64
    800017d6:	fc06                	sd	ra,56(sp)
    800017d8:	f822                	sd	s0,48(sp)
    800017da:	f426                	sd	s1,40(sp)
    800017dc:	f04a                	sd	s2,32(sp)
    800017de:	ec4e                	sd	s3,24(sp)
    800017e0:	e852                	sd	s4,16(sp)
    800017e2:	e456                	sd	s5,8(sp)
    800017e4:	e05a                	sd	s6,0(sp)
    800017e6:	0080                	addi	s0,sp,64
    800017e8:	8aaa                	mv	s5,a0
    800017ea:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800017ec:	6985                	lui	s3,0x1
    800017ee:	19fd                	addi	s3,s3,-1
    800017f0:	95ce                	add	a1,a1,s3
    800017f2:	79fd                	lui	s3,0xfffff
    800017f4:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    800017f8:	08c9f363          	bgeu	s3,a2,8000187e <uvmalloc+0xae>
    800017fc:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800017fe:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001802:	fffff097          	auipc	ra,0xfffff
    80001806:	6a4080e7          	jalr	1700(ra) # 80000ea6 <kalloc>
    8000180a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000180c:	c51d                	beqz	a0,8000183a <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000180e:	6605                	lui	a2,0x1
    80001810:	4581                	li	a1,0
    80001812:	00000097          	auipc	ra,0x0
    80001816:	880080e7          	jalr	-1920(ra) # 80001092 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000181a:	875a                	mv	a4,s6
    8000181c:	86a6                	mv	a3,s1
    8000181e:	6605                	lui	a2,0x1
    80001820:	85ca                	mv	a1,s2
    80001822:	8556                	mv	a0,s5
    80001824:	00000097          	auipc	ra,0x0
    80001828:	c3a080e7          	jalr	-966(ra) # 8000145e <mappages>
    8000182c:	e90d                	bnez	a0,8000185e <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000182e:	6785                	lui	a5,0x1
    80001830:	993e                	add	s2,s2,a5
    80001832:	fd4968e3          	bltu	s2,s4,80001802 <uvmalloc+0x32>
  return newsz;
    80001836:	8552                	mv	a0,s4
    80001838:	a809                	j	8000184a <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000183a:	864e                	mv	a2,s3
    8000183c:	85ca                	mv	a1,s2
    8000183e:	8556                	mv	a0,s5
    80001840:	00000097          	auipc	ra,0x0
    80001844:	f48080e7          	jalr	-184(ra) # 80001788 <uvmdealloc>
      return 0;
    80001848:	4501                	li	a0,0
}
    8000184a:	70e2                	ld	ra,56(sp)
    8000184c:	7442                	ld	s0,48(sp)
    8000184e:	74a2                	ld	s1,40(sp)
    80001850:	7902                	ld	s2,32(sp)
    80001852:	69e2                	ld	s3,24(sp)
    80001854:	6a42                	ld	s4,16(sp)
    80001856:	6aa2                	ld	s5,8(sp)
    80001858:	6b02                	ld	s6,0(sp)
    8000185a:	6121                	addi	sp,sp,64
    8000185c:	8082                	ret
      kfree(mem);
    8000185e:	8526                	mv	a0,s1
    80001860:	fffff097          	auipc	ra,0xfffff
    80001864:	54a080e7          	jalr	1354(ra) # 80000daa <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001868:	864e                	mv	a2,s3
    8000186a:	85ca                	mv	a1,s2
    8000186c:	8556                	mv	a0,s5
    8000186e:	00000097          	auipc	ra,0x0
    80001872:	f1a080e7          	jalr	-230(ra) # 80001788 <uvmdealloc>
      return 0;
    80001876:	4501                	li	a0,0
    80001878:	bfc9                	j	8000184a <uvmalloc+0x7a>
    return oldsz;
    8000187a:	852e                	mv	a0,a1
}
    8000187c:	8082                	ret
  return newsz;
    8000187e:	8532                	mv	a0,a2
    80001880:	b7e9                	j	8000184a <uvmalloc+0x7a>

0000000080001882 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001882:	7179                	addi	sp,sp,-48
    80001884:	f406                	sd	ra,40(sp)
    80001886:	f022                	sd	s0,32(sp)
    80001888:	ec26                	sd	s1,24(sp)
    8000188a:	e84a                	sd	s2,16(sp)
    8000188c:	e44e                	sd	s3,8(sp)
    8000188e:	e052                	sd	s4,0(sp)
    80001890:	1800                	addi	s0,sp,48
    80001892:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001894:	84aa                	mv	s1,a0
    80001896:	6905                	lui	s2,0x1
    80001898:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000189a:	4985                	li	s3,1
    8000189c:	a821                	j	800018b4 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    8000189e:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800018a0:	0532                	slli	a0,a0,0xc
    800018a2:	00000097          	auipc	ra,0x0
    800018a6:	fe0080e7          	jalr	-32(ra) # 80001882 <freewalk>
      pagetable[i] = 0;
    800018aa:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800018ae:	04a1                	addi	s1,s1,8
    800018b0:	03248163          	beq	s1,s2,800018d2 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800018b4:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800018b6:	00f57793          	andi	a5,a0,15
    800018ba:	ff3782e3          	beq	a5,s3,8000189e <freewalk+0x1c>
    } else if(pte & PTE_V){
    800018be:	8905                	andi	a0,a0,1
    800018c0:	d57d                	beqz	a0,800018ae <freewalk+0x2c>
      panic("freewalk: leaf");
    800018c2:	00007517          	auipc	a0,0x7
    800018c6:	90650513          	addi	a0,a0,-1786 # 800081c8 <digits+0x138>
    800018ca:	fffff097          	auipc	ra,0xfffff
    800018ce:	034080e7          	jalr	52(ra) # 800008fe <panic>
    }
  }
  kfree((void*)pagetable);
    800018d2:	8552                	mv	a0,s4
    800018d4:	fffff097          	auipc	ra,0xfffff
    800018d8:	4d6080e7          	jalr	1238(ra) # 80000daa <kfree>
}
    800018dc:	70a2                	ld	ra,40(sp)
    800018de:	7402                	ld	s0,32(sp)
    800018e0:	64e2                	ld	s1,24(sp)
    800018e2:	6942                	ld	s2,16(sp)
    800018e4:	69a2                	ld	s3,8(sp)
    800018e6:	6a02                	ld	s4,0(sp)
    800018e8:	6145                	addi	sp,sp,48
    800018ea:	8082                	ret

00000000800018ec <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800018ec:	1101                	addi	sp,sp,-32
    800018ee:	ec06                	sd	ra,24(sp)
    800018f0:	e822                	sd	s0,16(sp)
    800018f2:	e426                	sd	s1,8(sp)
    800018f4:	1000                	addi	s0,sp,32
    800018f6:	84aa                	mv	s1,a0
  if(sz > 0)
    800018f8:	e999                	bnez	a1,8000190e <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800018fa:	8526                	mv	a0,s1
    800018fc:	00000097          	auipc	ra,0x0
    80001900:	f86080e7          	jalr	-122(ra) # 80001882 <freewalk>
}
    80001904:	60e2                	ld	ra,24(sp)
    80001906:	6442                	ld	s0,16(sp)
    80001908:	64a2                	ld	s1,8(sp)
    8000190a:	6105                	addi	sp,sp,32
    8000190c:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000190e:	6605                	lui	a2,0x1
    80001910:	167d                	addi	a2,a2,-1
    80001912:	962e                	add	a2,a2,a1
    80001914:	4685                	li	a3,1
    80001916:	8231                	srli	a2,a2,0xc
    80001918:	4581                	li	a1,0
    8000191a:	00000097          	auipc	ra,0x0
    8000191e:	d0a080e7          	jalr	-758(ra) # 80001624 <uvmunmap>
    80001922:	bfe1                	j	800018fa <uvmfree+0xe>

0000000080001924 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001924:	c679                	beqz	a2,800019f2 <uvmcopy+0xce>
{
    80001926:	715d                	addi	sp,sp,-80
    80001928:	e486                	sd	ra,72(sp)
    8000192a:	e0a2                	sd	s0,64(sp)
    8000192c:	fc26                	sd	s1,56(sp)
    8000192e:	f84a                	sd	s2,48(sp)
    80001930:	f44e                	sd	s3,40(sp)
    80001932:	f052                	sd	s4,32(sp)
    80001934:	ec56                	sd	s5,24(sp)
    80001936:	e85a                	sd	s6,16(sp)
    80001938:	e45e                	sd	s7,8(sp)
    8000193a:	0880                	addi	s0,sp,80
    8000193c:	8b2a                	mv	s6,a0
    8000193e:	8aae                	mv	s5,a1
    80001940:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001942:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001944:	4601                	li	a2,0
    80001946:	85ce                	mv	a1,s3
    80001948:	855a                	mv	a0,s6
    8000194a:	00000097          	auipc	ra,0x0
    8000194e:	a2c080e7          	jalr	-1492(ra) # 80001376 <walk>
    80001952:	c531                	beqz	a0,8000199e <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001954:	6118                	ld	a4,0(a0)
    80001956:	00177793          	andi	a5,a4,1
    8000195a:	cbb1                	beqz	a5,800019ae <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000195c:	00a75593          	srli	a1,a4,0xa
    80001960:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001964:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001968:	fffff097          	auipc	ra,0xfffff
    8000196c:	53e080e7          	jalr	1342(ra) # 80000ea6 <kalloc>
    80001970:	892a                	mv	s2,a0
    80001972:	c939                	beqz	a0,800019c8 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001974:	6605                	lui	a2,0x1
    80001976:	85de                	mv	a1,s7
    80001978:	fffff097          	auipc	ra,0xfffff
    8000197c:	776080e7          	jalr	1910(ra) # 800010ee <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001980:	8726                	mv	a4,s1
    80001982:	86ca                	mv	a3,s2
    80001984:	6605                	lui	a2,0x1
    80001986:	85ce                	mv	a1,s3
    80001988:	8556                	mv	a0,s5
    8000198a:	00000097          	auipc	ra,0x0
    8000198e:	ad4080e7          	jalr	-1324(ra) # 8000145e <mappages>
    80001992:	e515                	bnez	a0,800019be <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001994:	6785                	lui	a5,0x1
    80001996:	99be                	add	s3,s3,a5
    80001998:	fb49e6e3          	bltu	s3,s4,80001944 <uvmcopy+0x20>
    8000199c:	a081                	j	800019dc <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    8000199e:	00007517          	auipc	a0,0x7
    800019a2:	83a50513          	addi	a0,a0,-1990 # 800081d8 <digits+0x148>
    800019a6:	fffff097          	auipc	ra,0xfffff
    800019aa:	f58080e7          	jalr	-168(ra) # 800008fe <panic>
      panic("uvmcopy: page not present");
    800019ae:	00007517          	auipc	a0,0x7
    800019b2:	84a50513          	addi	a0,a0,-1974 # 800081f8 <digits+0x168>
    800019b6:	fffff097          	auipc	ra,0xfffff
    800019ba:	f48080e7          	jalr	-184(ra) # 800008fe <panic>
      kfree(mem);
    800019be:	854a                	mv	a0,s2
    800019c0:	fffff097          	auipc	ra,0xfffff
    800019c4:	3ea080e7          	jalr	1002(ra) # 80000daa <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800019c8:	4685                	li	a3,1
    800019ca:	00c9d613          	srli	a2,s3,0xc
    800019ce:	4581                	li	a1,0
    800019d0:	8556                	mv	a0,s5
    800019d2:	00000097          	auipc	ra,0x0
    800019d6:	c52080e7          	jalr	-942(ra) # 80001624 <uvmunmap>
  return -1;
    800019da:	557d                	li	a0,-1
}
    800019dc:	60a6                	ld	ra,72(sp)
    800019de:	6406                	ld	s0,64(sp)
    800019e0:	74e2                	ld	s1,56(sp)
    800019e2:	7942                	ld	s2,48(sp)
    800019e4:	79a2                	ld	s3,40(sp)
    800019e6:	7a02                	ld	s4,32(sp)
    800019e8:	6ae2                	ld	s5,24(sp)
    800019ea:	6b42                	ld	s6,16(sp)
    800019ec:	6ba2                	ld	s7,8(sp)
    800019ee:	6161                	addi	sp,sp,80
    800019f0:	8082                	ret
  return 0;
    800019f2:	4501                	li	a0,0
}
    800019f4:	8082                	ret

00000000800019f6 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800019f6:	1141                	addi	sp,sp,-16
    800019f8:	e406                	sd	ra,8(sp)
    800019fa:	e022                	sd	s0,0(sp)
    800019fc:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800019fe:	4601                	li	a2,0
    80001a00:	00000097          	auipc	ra,0x0
    80001a04:	976080e7          	jalr	-1674(ra) # 80001376 <walk>
  if(pte == 0)
    80001a08:	c901                	beqz	a0,80001a18 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001a0a:	611c                	ld	a5,0(a0)
    80001a0c:	9bbd                	andi	a5,a5,-17
    80001a0e:	e11c                	sd	a5,0(a0)
}
    80001a10:	60a2                	ld	ra,8(sp)
    80001a12:	6402                	ld	s0,0(sp)
    80001a14:	0141                	addi	sp,sp,16
    80001a16:	8082                	ret
    panic("uvmclear");
    80001a18:	00007517          	auipc	a0,0x7
    80001a1c:	80050513          	addi	a0,a0,-2048 # 80008218 <digits+0x188>
    80001a20:	fffff097          	auipc	ra,0xfffff
    80001a24:	ede080e7          	jalr	-290(ra) # 800008fe <panic>

0000000080001a28 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001a28:	c6bd                	beqz	a3,80001a96 <copyout+0x6e>
{
    80001a2a:	715d                	addi	sp,sp,-80
    80001a2c:	e486                	sd	ra,72(sp)
    80001a2e:	e0a2                	sd	s0,64(sp)
    80001a30:	fc26                	sd	s1,56(sp)
    80001a32:	f84a                	sd	s2,48(sp)
    80001a34:	f44e                	sd	s3,40(sp)
    80001a36:	f052                	sd	s4,32(sp)
    80001a38:	ec56                	sd	s5,24(sp)
    80001a3a:	e85a                	sd	s6,16(sp)
    80001a3c:	e45e                	sd	s7,8(sp)
    80001a3e:	e062                	sd	s8,0(sp)
    80001a40:	0880                	addi	s0,sp,80
    80001a42:	8b2a                	mv	s6,a0
    80001a44:	8c2e                	mv	s8,a1
    80001a46:	8a32                	mv	s4,a2
    80001a48:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001a4a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001a4c:	6a85                	lui	s5,0x1
    80001a4e:	a015                	j	80001a72 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001a50:	9562                	add	a0,a0,s8
    80001a52:	0004861b          	sext.w	a2,s1
    80001a56:	85d2                	mv	a1,s4
    80001a58:	41250533          	sub	a0,a0,s2
    80001a5c:	fffff097          	auipc	ra,0xfffff
    80001a60:	692080e7          	jalr	1682(ra) # 800010ee <memmove>

    len -= n;
    80001a64:	409989b3          	sub	s3,s3,s1
    src += n;
    80001a68:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001a6a:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001a6e:	02098263          	beqz	s3,80001a92 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001a72:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001a76:	85ca                	mv	a1,s2
    80001a78:	855a                	mv	a0,s6
    80001a7a:	00000097          	auipc	ra,0x0
    80001a7e:	9a2080e7          	jalr	-1630(ra) # 8000141c <walkaddr>
    if(pa0 == 0)
    80001a82:	cd01                	beqz	a0,80001a9a <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001a84:	418904b3          	sub	s1,s2,s8
    80001a88:	94d6                	add	s1,s1,s5
    if(n > len)
    80001a8a:	fc99f3e3          	bgeu	s3,s1,80001a50 <copyout+0x28>
    80001a8e:	84ce                	mv	s1,s3
    80001a90:	b7c1                	j	80001a50 <copyout+0x28>
  }
  return 0;
    80001a92:	4501                	li	a0,0
    80001a94:	a021                	j	80001a9c <copyout+0x74>
    80001a96:	4501                	li	a0,0
}
    80001a98:	8082                	ret
      return -1;
    80001a9a:	557d                	li	a0,-1
}
    80001a9c:	60a6                	ld	ra,72(sp)
    80001a9e:	6406                	ld	s0,64(sp)
    80001aa0:	74e2                	ld	s1,56(sp)
    80001aa2:	7942                	ld	s2,48(sp)
    80001aa4:	79a2                	ld	s3,40(sp)
    80001aa6:	7a02                	ld	s4,32(sp)
    80001aa8:	6ae2                	ld	s5,24(sp)
    80001aaa:	6b42                	ld	s6,16(sp)
    80001aac:	6ba2                	ld	s7,8(sp)
    80001aae:	6c02                	ld	s8,0(sp)
    80001ab0:	6161                	addi	sp,sp,80
    80001ab2:	8082                	ret

0000000080001ab4 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001ab4:	caa5                	beqz	a3,80001b24 <copyin+0x70>
{
    80001ab6:	715d                	addi	sp,sp,-80
    80001ab8:	e486                	sd	ra,72(sp)
    80001aba:	e0a2                	sd	s0,64(sp)
    80001abc:	fc26                	sd	s1,56(sp)
    80001abe:	f84a                	sd	s2,48(sp)
    80001ac0:	f44e                	sd	s3,40(sp)
    80001ac2:	f052                	sd	s4,32(sp)
    80001ac4:	ec56                	sd	s5,24(sp)
    80001ac6:	e85a                	sd	s6,16(sp)
    80001ac8:	e45e                	sd	s7,8(sp)
    80001aca:	e062                	sd	s8,0(sp)
    80001acc:	0880                	addi	s0,sp,80
    80001ace:	8b2a                	mv	s6,a0
    80001ad0:	8a2e                	mv	s4,a1
    80001ad2:	8c32                	mv	s8,a2
    80001ad4:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001ad6:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001ad8:	6a85                	lui	s5,0x1
    80001ada:	a01d                	j	80001b00 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001adc:	018505b3          	add	a1,a0,s8
    80001ae0:	0004861b          	sext.w	a2,s1
    80001ae4:	412585b3          	sub	a1,a1,s2
    80001ae8:	8552                	mv	a0,s4
    80001aea:	fffff097          	auipc	ra,0xfffff
    80001aee:	604080e7          	jalr	1540(ra) # 800010ee <memmove>

    len -= n;
    80001af2:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001af6:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001af8:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001afc:	02098263          	beqz	s3,80001b20 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001b00:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001b04:	85ca                	mv	a1,s2
    80001b06:	855a                	mv	a0,s6
    80001b08:	00000097          	auipc	ra,0x0
    80001b0c:	914080e7          	jalr	-1772(ra) # 8000141c <walkaddr>
    if(pa0 == 0)
    80001b10:	cd01                	beqz	a0,80001b28 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001b12:	418904b3          	sub	s1,s2,s8
    80001b16:	94d6                	add	s1,s1,s5
    if(n > len)
    80001b18:	fc99f2e3          	bgeu	s3,s1,80001adc <copyin+0x28>
    80001b1c:	84ce                	mv	s1,s3
    80001b1e:	bf7d                	j	80001adc <copyin+0x28>
  }
  return 0;
    80001b20:	4501                	li	a0,0
    80001b22:	a021                	j	80001b2a <copyin+0x76>
    80001b24:	4501                	li	a0,0
}
    80001b26:	8082                	ret
      return -1;
    80001b28:	557d                	li	a0,-1
}
    80001b2a:	60a6                	ld	ra,72(sp)
    80001b2c:	6406                	ld	s0,64(sp)
    80001b2e:	74e2                	ld	s1,56(sp)
    80001b30:	7942                	ld	s2,48(sp)
    80001b32:	79a2                	ld	s3,40(sp)
    80001b34:	7a02                	ld	s4,32(sp)
    80001b36:	6ae2                	ld	s5,24(sp)
    80001b38:	6b42                	ld	s6,16(sp)
    80001b3a:	6ba2                	ld	s7,8(sp)
    80001b3c:	6c02                	ld	s8,0(sp)
    80001b3e:	6161                	addi	sp,sp,80
    80001b40:	8082                	ret

0000000080001b42 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001b42:	c6c5                	beqz	a3,80001bea <copyinstr+0xa8>
{
    80001b44:	715d                	addi	sp,sp,-80
    80001b46:	e486                	sd	ra,72(sp)
    80001b48:	e0a2                	sd	s0,64(sp)
    80001b4a:	fc26                	sd	s1,56(sp)
    80001b4c:	f84a                	sd	s2,48(sp)
    80001b4e:	f44e                	sd	s3,40(sp)
    80001b50:	f052                	sd	s4,32(sp)
    80001b52:	ec56                	sd	s5,24(sp)
    80001b54:	e85a                	sd	s6,16(sp)
    80001b56:	e45e                	sd	s7,8(sp)
    80001b58:	0880                	addi	s0,sp,80
    80001b5a:	8a2a                	mv	s4,a0
    80001b5c:	8b2e                	mv	s6,a1
    80001b5e:	8bb2                	mv	s7,a2
    80001b60:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001b62:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001b64:	6985                	lui	s3,0x1
    80001b66:	a035                	j	80001b92 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001b68:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001b6c:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001b6e:	0017b793          	seqz	a5,a5
    80001b72:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001b76:	60a6                	ld	ra,72(sp)
    80001b78:	6406                	ld	s0,64(sp)
    80001b7a:	74e2                	ld	s1,56(sp)
    80001b7c:	7942                	ld	s2,48(sp)
    80001b7e:	79a2                	ld	s3,40(sp)
    80001b80:	7a02                	ld	s4,32(sp)
    80001b82:	6ae2                	ld	s5,24(sp)
    80001b84:	6b42                	ld	s6,16(sp)
    80001b86:	6ba2                	ld	s7,8(sp)
    80001b88:	6161                	addi	sp,sp,80
    80001b8a:	8082                	ret
    srcva = va0 + PGSIZE;
    80001b8c:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001b90:	c8a9                	beqz	s1,80001be2 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    80001b92:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001b96:	85ca                	mv	a1,s2
    80001b98:	8552                	mv	a0,s4
    80001b9a:	00000097          	auipc	ra,0x0
    80001b9e:	882080e7          	jalr	-1918(ra) # 8000141c <walkaddr>
    if(pa0 == 0)
    80001ba2:	c131                	beqz	a0,80001be6 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001ba4:	41790833          	sub	a6,s2,s7
    80001ba8:	984e                	add	a6,a6,s3
    if(n > max)
    80001baa:	0104f363          	bgeu	s1,a6,80001bb0 <copyinstr+0x6e>
    80001bae:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001bb0:	955e                	add	a0,a0,s7
    80001bb2:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001bb6:	fc080be3          	beqz	a6,80001b8c <copyinstr+0x4a>
    80001bba:	985a                	add	a6,a6,s6
    80001bbc:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001bbe:	41650633          	sub	a2,a0,s6
    80001bc2:	14fd                	addi	s1,s1,-1
    80001bc4:	9b26                	add	s6,s6,s1
    80001bc6:	00f60733          	add	a4,a2,a5
    80001bca:	00074703          	lbu	a4,0(a4)
    80001bce:	df49                	beqz	a4,80001b68 <copyinstr+0x26>
        *dst = *p;
    80001bd0:	00e78023          	sb	a4,0(a5)
      --max;
    80001bd4:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001bd8:	0785                	addi	a5,a5,1
    while(n > 0){
    80001bda:	ff0796e3          	bne	a5,a6,80001bc6 <copyinstr+0x84>
      dst++;
    80001bde:	8b42                	mv	s6,a6
    80001be0:	b775                	j	80001b8c <copyinstr+0x4a>
    80001be2:	4781                	li	a5,0
    80001be4:	b769                	j	80001b6e <copyinstr+0x2c>
      return -1;
    80001be6:	557d                	li	a0,-1
    80001be8:	b779                	j	80001b76 <copyinstr+0x34>
  int got_null = 0;
    80001bea:	4781                	li	a5,0
  if(got_null){
    80001bec:	0017b793          	seqz	a5,a5
    80001bf0:	40f00533          	neg	a0,a5
}
    80001bf4:	8082                	ret

0000000080001bf6 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001bf6:	7139                	addi	sp,sp,-64
    80001bf8:	fc06                	sd	ra,56(sp)
    80001bfa:	f822                	sd	s0,48(sp)
    80001bfc:	f426                	sd	s1,40(sp)
    80001bfe:	f04a                	sd	s2,32(sp)
    80001c00:	ec4e                	sd	s3,24(sp)
    80001c02:	e852                	sd	s4,16(sp)
    80001c04:	e456                	sd	s5,8(sp)
    80001c06:	e05a                	sd	s6,0(sp)
    80001c08:	0080                	addi	s0,sp,64
    80001c0a:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c0c:	00010497          	auipc	s1,0x10
    80001c10:	d7c48493          	addi	s1,s1,-644 # 80011988 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001c14:	8b26                	mv	s6,s1
    80001c16:	00006a97          	auipc	s5,0x6
    80001c1a:	3eaa8a93          	addi	s5,s5,1002 # 80008000 <etext>
    80001c1e:	04000937          	lui	s2,0x4000
    80001c22:	197d                	addi	s2,s2,-1
    80001c24:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c26:	00015a17          	auipc	s4,0x15
    80001c2a:	762a0a13          	addi	s4,s4,1890 # 80017388 <tickslock>
    char *pa = kalloc();
    80001c2e:	fffff097          	auipc	ra,0xfffff
    80001c32:	278080e7          	jalr	632(ra) # 80000ea6 <kalloc>
    80001c36:	862a                	mv	a2,a0
    if(pa == 0)
    80001c38:	c131                	beqz	a0,80001c7c <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001c3a:	416485b3          	sub	a1,s1,s6
    80001c3e:	858d                	srai	a1,a1,0x3
    80001c40:	000ab783          	ld	a5,0(s5)
    80001c44:	02f585b3          	mul	a1,a1,a5
    80001c48:	2585                	addiw	a1,a1,1
    80001c4a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001c4e:	4719                	li	a4,6
    80001c50:	6685                	lui	a3,0x1
    80001c52:	40b905b3          	sub	a1,s2,a1
    80001c56:	854e                	mv	a0,s3
    80001c58:	00000097          	auipc	ra,0x0
    80001c5c:	8a6080e7          	jalr	-1882(ra) # 800014fe <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c60:	16848493          	addi	s1,s1,360
    80001c64:	fd4495e3          	bne	s1,s4,80001c2e <proc_mapstacks+0x38>
  }
}
    80001c68:	70e2                	ld	ra,56(sp)
    80001c6a:	7442                	ld	s0,48(sp)
    80001c6c:	74a2                	ld	s1,40(sp)
    80001c6e:	7902                	ld	s2,32(sp)
    80001c70:	69e2                	ld	s3,24(sp)
    80001c72:	6a42                	ld	s4,16(sp)
    80001c74:	6aa2                	ld	s5,8(sp)
    80001c76:	6b02                	ld	s6,0(sp)
    80001c78:	6121                	addi	sp,sp,64
    80001c7a:	8082                	ret
      panic("kalloc");
    80001c7c:	00006517          	auipc	a0,0x6
    80001c80:	5ac50513          	addi	a0,a0,1452 # 80008228 <digits+0x198>
    80001c84:	fffff097          	auipc	ra,0xfffff
    80001c88:	c7a080e7          	jalr	-902(ra) # 800008fe <panic>

0000000080001c8c <procinit>:

// initialize the proc table.
void
procinit(void)
{
    80001c8c:	7139                	addi	sp,sp,-64
    80001c8e:	fc06                	sd	ra,56(sp)
    80001c90:	f822                	sd	s0,48(sp)
    80001c92:	f426                	sd	s1,40(sp)
    80001c94:	f04a                	sd	s2,32(sp)
    80001c96:	ec4e                	sd	s3,24(sp)
    80001c98:	e852                	sd	s4,16(sp)
    80001c9a:	e456                	sd	s5,8(sp)
    80001c9c:	e05a                	sd	s6,0(sp)
    80001c9e:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001ca0:	00006597          	auipc	a1,0x6
    80001ca4:	59058593          	addi	a1,a1,1424 # 80008230 <digits+0x1a0>
    80001ca8:	00010517          	auipc	a0,0x10
    80001cac:	8b050513          	addi	a0,a0,-1872 # 80011558 <pid_lock>
    80001cb0:	fffff097          	auipc	ra,0xfffff
    80001cb4:	256080e7          	jalr	598(ra) # 80000f06 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001cb8:	00006597          	auipc	a1,0x6
    80001cbc:	58058593          	addi	a1,a1,1408 # 80008238 <digits+0x1a8>
    80001cc0:	00010517          	auipc	a0,0x10
    80001cc4:	8b050513          	addi	a0,a0,-1872 # 80011570 <wait_lock>
    80001cc8:	fffff097          	auipc	ra,0xfffff
    80001ccc:	23e080e7          	jalr	574(ra) # 80000f06 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cd0:	00010497          	auipc	s1,0x10
    80001cd4:	cb848493          	addi	s1,s1,-840 # 80011988 <proc>
      initlock(&p->lock, "proc");
    80001cd8:	00006b17          	auipc	s6,0x6
    80001cdc:	570b0b13          	addi	s6,s6,1392 # 80008248 <digits+0x1b8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001ce0:	8aa6                	mv	s5,s1
    80001ce2:	00006a17          	auipc	s4,0x6
    80001ce6:	31ea0a13          	addi	s4,s4,798 # 80008000 <etext>
    80001cea:	04000937          	lui	s2,0x4000
    80001cee:	197d                	addi	s2,s2,-1
    80001cf0:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cf2:	00015997          	auipc	s3,0x15
    80001cf6:	69698993          	addi	s3,s3,1686 # 80017388 <tickslock>
      initlock(&p->lock, "proc");
    80001cfa:	85da                	mv	a1,s6
    80001cfc:	8526                	mv	a0,s1
    80001cfe:	fffff097          	auipc	ra,0xfffff
    80001d02:	208080e7          	jalr	520(ra) # 80000f06 <initlock>
      p->state = UNUSED;
    80001d06:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    80001d0a:	415487b3          	sub	a5,s1,s5
    80001d0e:	878d                	srai	a5,a5,0x3
    80001d10:	000a3703          	ld	a4,0(s4)
    80001d14:	02e787b3          	mul	a5,a5,a4
    80001d18:	2785                	addiw	a5,a5,1
    80001d1a:	00d7979b          	slliw	a5,a5,0xd
    80001d1e:	40f907b3          	sub	a5,s2,a5
    80001d22:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d24:	16848493          	addi	s1,s1,360
    80001d28:	fd3499e3          	bne	s1,s3,80001cfa <procinit+0x6e>
  }
}
    80001d2c:	70e2                	ld	ra,56(sp)
    80001d2e:	7442                	ld	s0,48(sp)
    80001d30:	74a2                	ld	s1,40(sp)
    80001d32:	7902                	ld	s2,32(sp)
    80001d34:	69e2                	ld	s3,24(sp)
    80001d36:	6a42                	ld	s4,16(sp)
    80001d38:	6aa2                	ld	s5,8(sp)
    80001d3a:	6b02                	ld	s6,0(sp)
    80001d3c:	6121                	addi	sp,sp,64
    80001d3e:	8082                	ret

0000000080001d40 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001d40:	1141                	addi	sp,sp,-16
    80001d42:	e422                	sd	s0,8(sp)
    80001d44:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001d46:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001d48:	2501                	sext.w	a0,a0
    80001d4a:	6422                	ld	s0,8(sp)
    80001d4c:	0141                	addi	sp,sp,16
    80001d4e:	8082                	ret

0000000080001d50 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001d50:	1141                	addi	sp,sp,-16
    80001d52:	e422                	sd	s0,8(sp)
    80001d54:	0800                	addi	s0,sp,16
    80001d56:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001d58:	2781                	sext.w	a5,a5
    80001d5a:	079e                	slli	a5,a5,0x7
  return c;
}
    80001d5c:	00010517          	auipc	a0,0x10
    80001d60:	82c50513          	addi	a0,a0,-2004 # 80011588 <cpus>
    80001d64:	953e                	add	a0,a0,a5
    80001d66:	6422                	ld	s0,8(sp)
    80001d68:	0141                	addi	sp,sp,16
    80001d6a:	8082                	ret

0000000080001d6c <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    80001d6c:	1101                	addi	sp,sp,-32
    80001d6e:	ec06                	sd	ra,24(sp)
    80001d70:	e822                	sd	s0,16(sp)
    80001d72:	e426                	sd	s1,8(sp)
    80001d74:	1000                	addi	s0,sp,32
  push_off();
    80001d76:	fffff097          	auipc	ra,0xfffff
    80001d7a:	1d4080e7          	jalr	468(ra) # 80000f4a <push_off>
    80001d7e:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001d80:	2781                	sext.w	a5,a5
    80001d82:	079e                	slli	a5,a5,0x7
    80001d84:	0000f717          	auipc	a4,0xf
    80001d88:	7d470713          	addi	a4,a4,2004 # 80011558 <pid_lock>
    80001d8c:	97ba                	add	a5,a5,a4
    80001d8e:	7b84                	ld	s1,48(a5)
  pop_off();
    80001d90:	fffff097          	auipc	ra,0xfffff
    80001d94:	25a080e7          	jalr	602(ra) # 80000fea <pop_off>
  return p;
}
    80001d98:	8526                	mv	a0,s1
    80001d9a:	60e2                	ld	ra,24(sp)
    80001d9c:	6442                	ld	s0,16(sp)
    80001d9e:	64a2                	ld	s1,8(sp)
    80001da0:	6105                	addi	sp,sp,32
    80001da2:	8082                	ret

0000000080001da4 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001da4:	1141                	addi	sp,sp,-16
    80001da6:	e406                	sd	ra,8(sp)
    80001da8:	e022                	sd	s0,0(sp)
    80001daa:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001dac:	00000097          	auipc	ra,0x0
    80001db0:	fc0080e7          	jalr	-64(ra) # 80001d6c <myproc>
    80001db4:	fffff097          	auipc	ra,0xfffff
    80001db8:	296080e7          	jalr	662(ra) # 8000104a <release>

  if (first) {
    80001dbc:	00007797          	auipc	a5,0x7
    80001dc0:	be87a783          	lw	a5,-1048(a5) # 800089a4 <first.2>
    80001dc4:	eb89                	bnez	a5,80001dd6 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001dc6:	00001097          	auipc	ra,0x1
    80001dca:	f6a080e7          	jalr	-150(ra) # 80002d30 <usertrapret>
}
    80001dce:	60a2                	ld	ra,8(sp)
    80001dd0:	6402                	ld	s0,0(sp)
    80001dd2:	0141                	addi	sp,sp,16
    80001dd4:	8082                	ret
    first = 0;
    80001dd6:	00007797          	auipc	a5,0x7
    80001dda:	bc07a723          	sw	zero,-1074(a5) # 800089a4 <first.2>
    fsinit(ROOTDEV);
    80001dde:	4505                	li	a0,1
    80001de0:	00002097          	auipc	ra,0x2
    80001de4:	cf2080e7          	jalr	-782(ra) # 80003ad2 <fsinit>
    80001de8:	bff9                	j	80001dc6 <forkret+0x22>

0000000080001dea <allocpid>:
{
    80001dea:	1101                	addi	sp,sp,-32
    80001dec:	ec06                	sd	ra,24(sp)
    80001dee:	e822                	sd	s0,16(sp)
    80001df0:	e426                	sd	s1,8(sp)
    80001df2:	e04a                	sd	s2,0(sp)
    80001df4:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001df6:	0000f917          	auipc	s2,0xf
    80001dfa:	76290913          	addi	s2,s2,1890 # 80011558 <pid_lock>
    80001dfe:	854a                	mv	a0,s2
    80001e00:	fffff097          	auipc	ra,0xfffff
    80001e04:	196080e7          	jalr	406(ra) # 80000f96 <acquire>
  pid = nextpid;
    80001e08:	00007797          	auipc	a5,0x7
    80001e0c:	ba078793          	addi	a5,a5,-1120 # 800089a8 <nextpid>
    80001e10:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001e12:	0014871b          	addiw	a4,s1,1
    80001e16:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001e18:	854a                	mv	a0,s2
    80001e1a:	fffff097          	auipc	ra,0xfffff
    80001e1e:	230080e7          	jalr	560(ra) # 8000104a <release>
}
    80001e22:	8526                	mv	a0,s1
    80001e24:	60e2                	ld	ra,24(sp)
    80001e26:	6442                	ld	s0,16(sp)
    80001e28:	64a2                	ld	s1,8(sp)
    80001e2a:	6902                	ld	s2,0(sp)
    80001e2c:	6105                	addi	sp,sp,32
    80001e2e:	8082                	ret

0000000080001e30 <proc_pagetable>:
{
    80001e30:	1101                	addi	sp,sp,-32
    80001e32:	ec06                	sd	ra,24(sp)
    80001e34:	e822                	sd	s0,16(sp)
    80001e36:	e426                	sd	s1,8(sp)
    80001e38:	e04a                	sd	s2,0(sp)
    80001e3a:	1000                	addi	s0,sp,32
    80001e3c:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001e3e:	00000097          	auipc	ra,0x0
    80001e42:	8aa080e7          	jalr	-1878(ra) # 800016e8 <uvmcreate>
    80001e46:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001e48:	c121                	beqz	a0,80001e88 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001e4a:	4729                	li	a4,10
    80001e4c:	00005697          	auipc	a3,0x5
    80001e50:	1b468693          	addi	a3,a3,436 # 80007000 <_trampoline>
    80001e54:	6605                	lui	a2,0x1
    80001e56:	040005b7          	lui	a1,0x4000
    80001e5a:	15fd                	addi	a1,a1,-1
    80001e5c:	05b2                	slli	a1,a1,0xc
    80001e5e:	fffff097          	auipc	ra,0xfffff
    80001e62:	600080e7          	jalr	1536(ra) # 8000145e <mappages>
    80001e66:	02054863          	bltz	a0,80001e96 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001e6a:	4719                	li	a4,6
    80001e6c:	05893683          	ld	a3,88(s2)
    80001e70:	6605                	lui	a2,0x1
    80001e72:	020005b7          	lui	a1,0x2000
    80001e76:	15fd                	addi	a1,a1,-1
    80001e78:	05b6                	slli	a1,a1,0xd
    80001e7a:	8526                	mv	a0,s1
    80001e7c:	fffff097          	auipc	ra,0xfffff
    80001e80:	5e2080e7          	jalr	1506(ra) # 8000145e <mappages>
    80001e84:	02054163          	bltz	a0,80001ea6 <proc_pagetable+0x76>
}
    80001e88:	8526                	mv	a0,s1
    80001e8a:	60e2                	ld	ra,24(sp)
    80001e8c:	6442                	ld	s0,16(sp)
    80001e8e:	64a2                	ld	s1,8(sp)
    80001e90:	6902                	ld	s2,0(sp)
    80001e92:	6105                	addi	sp,sp,32
    80001e94:	8082                	ret
    uvmfree(pagetable, 0);
    80001e96:	4581                	li	a1,0
    80001e98:	8526                	mv	a0,s1
    80001e9a:	00000097          	auipc	ra,0x0
    80001e9e:	a52080e7          	jalr	-1454(ra) # 800018ec <uvmfree>
    return 0;
    80001ea2:	4481                	li	s1,0
    80001ea4:	b7d5                	j	80001e88 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ea6:	4681                	li	a3,0
    80001ea8:	4605                	li	a2,1
    80001eaa:	040005b7          	lui	a1,0x4000
    80001eae:	15fd                	addi	a1,a1,-1
    80001eb0:	05b2                	slli	a1,a1,0xc
    80001eb2:	8526                	mv	a0,s1
    80001eb4:	fffff097          	auipc	ra,0xfffff
    80001eb8:	770080e7          	jalr	1904(ra) # 80001624 <uvmunmap>
    uvmfree(pagetable, 0);
    80001ebc:	4581                	li	a1,0
    80001ebe:	8526                	mv	a0,s1
    80001ec0:	00000097          	auipc	ra,0x0
    80001ec4:	a2c080e7          	jalr	-1492(ra) # 800018ec <uvmfree>
    return 0;
    80001ec8:	4481                	li	s1,0
    80001eca:	bf7d                	j	80001e88 <proc_pagetable+0x58>

0000000080001ecc <proc_freepagetable>:
{
    80001ecc:	1101                	addi	sp,sp,-32
    80001ece:	ec06                	sd	ra,24(sp)
    80001ed0:	e822                	sd	s0,16(sp)
    80001ed2:	e426                	sd	s1,8(sp)
    80001ed4:	e04a                	sd	s2,0(sp)
    80001ed6:	1000                	addi	s0,sp,32
    80001ed8:	84aa                	mv	s1,a0
    80001eda:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001edc:	4681                	li	a3,0
    80001ede:	4605                	li	a2,1
    80001ee0:	040005b7          	lui	a1,0x4000
    80001ee4:	15fd                	addi	a1,a1,-1
    80001ee6:	05b2                	slli	a1,a1,0xc
    80001ee8:	fffff097          	auipc	ra,0xfffff
    80001eec:	73c080e7          	jalr	1852(ra) # 80001624 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001ef0:	4681                	li	a3,0
    80001ef2:	4605                	li	a2,1
    80001ef4:	020005b7          	lui	a1,0x2000
    80001ef8:	15fd                	addi	a1,a1,-1
    80001efa:	05b6                	slli	a1,a1,0xd
    80001efc:	8526                	mv	a0,s1
    80001efe:	fffff097          	auipc	ra,0xfffff
    80001f02:	726080e7          	jalr	1830(ra) # 80001624 <uvmunmap>
  uvmfree(pagetable, sz);
    80001f06:	85ca                	mv	a1,s2
    80001f08:	8526                	mv	a0,s1
    80001f0a:	00000097          	auipc	ra,0x0
    80001f0e:	9e2080e7          	jalr	-1566(ra) # 800018ec <uvmfree>
}
    80001f12:	60e2                	ld	ra,24(sp)
    80001f14:	6442                	ld	s0,16(sp)
    80001f16:	64a2                	ld	s1,8(sp)
    80001f18:	6902                	ld	s2,0(sp)
    80001f1a:	6105                	addi	sp,sp,32
    80001f1c:	8082                	ret

0000000080001f1e <freeproc>:
{
    80001f1e:	1101                	addi	sp,sp,-32
    80001f20:	ec06                	sd	ra,24(sp)
    80001f22:	e822                	sd	s0,16(sp)
    80001f24:	e426                	sd	s1,8(sp)
    80001f26:	1000                	addi	s0,sp,32
    80001f28:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001f2a:	6d28                	ld	a0,88(a0)
    80001f2c:	c509                	beqz	a0,80001f36 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001f2e:	fffff097          	auipc	ra,0xfffff
    80001f32:	e7c080e7          	jalr	-388(ra) # 80000daa <kfree>
  p->trapframe = 0;
    80001f36:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001f3a:	68a8                	ld	a0,80(s1)
    80001f3c:	c511                	beqz	a0,80001f48 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001f3e:	64ac                	ld	a1,72(s1)
    80001f40:	00000097          	auipc	ra,0x0
    80001f44:	f8c080e7          	jalr	-116(ra) # 80001ecc <proc_freepagetable>
  p->pagetable = 0;
    80001f48:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001f4c:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001f50:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001f54:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001f58:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001f5c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001f60:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001f64:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001f68:	0004ac23          	sw	zero,24(s1)
}
    80001f6c:	60e2                	ld	ra,24(sp)
    80001f6e:	6442                	ld	s0,16(sp)
    80001f70:	64a2                	ld	s1,8(sp)
    80001f72:	6105                	addi	sp,sp,32
    80001f74:	8082                	ret

0000000080001f76 <allocproc>:
{
    80001f76:	1101                	addi	sp,sp,-32
    80001f78:	ec06                	sd	ra,24(sp)
    80001f7a:	e822                	sd	s0,16(sp)
    80001f7c:	e426                	sd	s1,8(sp)
    80001f7e:	e04a                	sd	s2,0(sp)
    80001f80:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001f82:	00010497          	auipc	s1,0x10
    80001f86:	a0648493          	addi	s1,s1,-1530 # 80011988 <proc>
    80001f8a:	00015917          	auipc	s2,0x15
    80001f8e:	3fe90913          	addi	s2,s2,1022 # 80017388 <tickslock>
    acquire(&p->lock);
    80001f92:	8526                	mv	a0,s1
    80001f94:	fffff097          	auipc	ra,0xfffff
    80001f98:	002080e7          	jalr	2(ra) # 80000f96 <acquire>
    if(p->state == UNUSED) {
    80001f9c:	4c9c                	lw	a5,24(s1)
    80001f9e:	cf81                	beqz	a5,80001fb6 <allocproc+0x40>
      release(&p->lock);
    80001fa0:	8526                	mv	a0,s1
    80001fa2:	fffff097          	auipc	ra,0xfffff
    80001fa6:	0a8080e7          	jalr	168(ra) # 8000104a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001faa:	16848493          	addi	s1,s1,360
    80001fae:	ff2492e3          	bne	s1,s2,80001f92 <allocproc+0x1c>
  return 0;
    80001fb2:	4481                	li	s1,0
    80001fb4:	a889                	j	80002006 <allocproc+0x90>
  p->pid = allocpid();
    80001fb6:	00000097          	auipc	ra,0x0
    80001fba:	e34080e7          	jalr	-460(ra) # 80001dea <allocpid>
    80001fbe:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001fc0:	4785                	li	a5,1
    80001fc2:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001fc4:	fffff097          	auipc	ra,0xfffff
    80001fc8:	ee2080e7          	jalr	-286(ra) # 80000ea6 <kalloc>
    80001fcc:	892a                	mv	s2,a0
    80001fce:	eca8                	sd	a0,88(s1)
    80001fd0:	c131                	beqz	a0,80002014 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001fd2:	8526                	mv	a0,s1
    80001fd4:	00000097          	auipc	ra,0x0
    80001fd8:	e5c080e7          	jalr	-420(ra) # 80001e30 <proc_pagetable>
    80001fdc:	892a                	mv	s2,a0
    80001fde:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001fe0:	c531                	beqz	a0,8000202c <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001fe2:	07000613          	li	a2,112
    80001fe6:	4581                	li	a1,0
    80001fe8:	06048513          	addi	a0,s1,96
    80001fec:	fffff097          	auipc	ra,0xfffff
    80001ff0:	0a6080e7          	jalr	166(ra) # 80001092 <memset>
  p->context.ra = (uint64)forkret;
    80001ff4:	00000797          	auipc	a5,0x0
    80001ff8:	db078793          	addi	a5,a5,-592 # 80001da4 <forkret>
    80001ffc:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001ffe:	60bc                	ld	a5,64(s1)
    80002000:	6705                	lui	a4,0x1
    80002002:	97ba                	add	a5,a5,a4
    80002004:	f4bc                	sd	a5,104(s1)
}
    80002006:	8526                	mv	a0,s1
    80002008:	60e2                	ld	ra,24(sp)
    8000200a:	6442                	ld	s0,16(sp)
    8000200c:	64a2                	ld	s1,8(sp)
    8000200e:	6902                	ld	s2,0(sp)
    80002010:	6105                	addi	sp,sp,32
    80002012:	8082                	ret
    freeproc(p);
    80002014:	8526                	mv	a0,s1
    80002016:	00000097          	auipc	ra,0x0
    8000201a:	f08080e7          	jalr	-248(ra) # 80001f1e <freeproc>
    release(&p->lock);
    8000201e:	8526                	mv	a0,s1
    80002020:	fffff097          	auipc	ra,0xfffff
    80002024:	02a080e7          	jalr	42(ra) # 8000104a <release>
    return 0;
    80002028:	84ca                	mv	s1,s2
    8000202a:	bff1                	j	80002006 <allocproc+0x90>
    freeproc(p);
    8000202c:	8526                	mv	a0,s1
    8000202e:	00000097          	auipc	ra,0x0
    80002032:	ef0080e7          	jalr	-272(ra) # 80001f1e <freeproc>
    release(&p->lock);
    80002036:	8526                	mv	a0,s1
    80002038:	fffff097          	auipc	ra,0xfffff
    8000203c:	012080e7          	jalr	18(ra) # 8000104a <release>
    return 0;
    80002040:	84ca                	mv	s1,s2
    80002042:	b7d1                	j	80002006 <allocproc+0x90>

0000000080002044 <userinit>:
{
    80002044:	1101                	addi	sp,sp,-32
    80002046:	ec06                	sd	ra,24(sp)
    80002048:	e822                	sd	s0,16(sp)
    8000204a:	e426                	sd	s1,8(sp)
    8000204c:	1000                	addi	s0,sp,32
  p = allocproc();
    8000204e:	00000097          	auipc	ra,0x0
    80002052:	f28080e7          	jalr	-216(ra) # 80001f76 <allocproc>
    80002056:	84aa                	mv	s1,a0
  initproc = p;
    80002058:	00007797          	auipc	a5,0x7
    8000205c:	9ca7b023          	sd	a0,-1600(a5) # 80008a18 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80002060:	03400613          	li	a2,52
    80002064:	00007597          	auipc	a1,0x7
    80002068:	94c58593          	addi	a1,a1,-1716 # 800089b0 <initcode>
    8000206c:	6928                	ld	a0,80(a0)
    8000206e:	fffff097          	auipc	ra,0xfffff
    80002072:	6a8080e7          	jalr	1704(ra) # 80001716 <uvmfirst>
  p->sz = PGSIZE;
    80002076:	6785                	lui	a5,0x1
    80002078:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    8000207a:	6cb8                	ld	a4,88(s1)
    8000207c:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80002080:	6cb8                	ld	a4,88(s1)
    80002082:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80002084:	4641                	li	a2,16
    80002086:	00006597          	auipc	a1,0x6
    8000208a:	1ca58593          	addi	a1,a1,458 # 80008250 <digits+0x1c0>
    8000208e:	15848513          	addi	a0,s1,344
    80002092:	fffff097          	auipc	ra,0xfffff
    80002096:	14a080e7          	jalr	330(ra) # 800011dc <safestrcpy>
  p->cwd = namei("/");
    8000209a:	00006517          	auipc	a0,0x6
    8000209e:	1c650513          	addi	a0,a0,454 # 80008260 <digits+0x1d0>
    800020a2:	00002097          	auipc	ra,0x2
    800020a6:	452080e7          	jalr	1106(ra) # 800044f4 <namei>
    800020aa:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    800020ae:	478d                	li	a5,3
    800020b0:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    800020b2:	8526                	mv	a0,s1
    800020b4:	fffff097          	auipc	ra,0xfffff
    800020b8:	f96080e7          	jalr	-106(ra) # 8000104a <release>
}
    800020bc:	60e2                	ld	ra,24(sp)
    800020be:	6442                	ld	s0,16(sp)
    800020c0:	64a2                	ld	s1,8(sp)
    800020c2:	6105                	addi	sp,sp,32
    800020c4:	8082                	ret

00000000800020c6 <growproc>:
{
    800020c6:	1101                	addi	sp,sp,-32
    800020c8:	ec06                	sd	ra,24(sp)
    800020ca:	e822                	sd	s0,16(sp)
    800020cc:	e426                	sd	s1,8(sp)
    800020ce:	e04a                	sd	s2,0(sp)
    800020d0:	1000                	addi	s0,sp,32
    800020d2:	892a                	mv	s2,a0
  struct proc *p = myproc();
    800020d4:	00000097          	auipc	ra,0x0
    800020d8:	c98080e7          	jalr	-872(ra) # 80001d6c <myproc>
    800020dc:	84aa                	mv	s1,a0
  sz = p->sz;
    800020de:	652c                	ld	a1,72(a0)
  if(n > 0){
    800020e0:	01204c63          	bgtz	s2,800020f8 <growproc+0x32>
  } else if(n < 0){
    800020e4:	02094663          	bltz	s2,80002110 <growproc+0x4a>
  p->sz = sz;
    800020e8:	e4ac                	sd	a1,72(s1)
  return 0;
    800020ea:	4501                	li	a0,0
}
    800020ec:	60e2                	ld	ra,24(sp)
    800020ee:	6442                	ld	s0,16(sp)
    800020f0:	64a2                	ld	s1,8(sp)
    800020f2:	6902                	ld	s2,0(sp)
    800020f4:	6105                	addi	sp,sp,32
    800020f6:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    800020f8:	4691                	li	a3,4
    800020fa:	00b90633          	add	a2,s2,a1
    800020fe:	6928                	ld	a0,80(a0)
    80002100:	fffff097          	auipc	ra,0xfffff
    80002104:	6d0080e7          	jalr	1744(ra) # 800017d0 <uvmalloc>
    80002108:	85aa                	mv	a1,a0
    8000210a:	fd79                	bnez	a0,800020e8 <growproc+0x22>
      return -1;
    8000210c:	557d                	li	a0,-1
    8000210e:	bff9                	j	800020ec <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80002110:	00b90633          	add	a2,s2,a1
    80002114:	6928                	ld	a0,80(a0)
    80002116:	fffff097          	auipc	ra,0xfffff
    8000211a:	672080e7          	jalr	1650(ra) # 80001788 <uvmdealloc>
    8000211e:	85aa                	mv	a1,a0
    80002120:	b7e1                	j	800020e8 <growproc+0x22>

0000000080002122 <fork>:
{
    80002122:	7139                	addi	sp,sp,-64
    80002124:	fc06                	sd	ra,56(sp)
    80002126:	f822                	sd	s0,48(sp)
    80002128:	f426                	sd	s1,40(sp)
    8000212a:	f04a                	sd	s2,32(sp)
    8000212c:	ec4e                	sd	s3,24(sp)
    8000212e:	e852                	sd	s4,16(sp)
    80002130:	e456                	sd	s5,8(sp)
    80002132:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80002134:	00000097          	auipc	ra,0x0
    80002138:	c38080e7          	jalr	-968(ra) # 80001d6c <myproc>
    8000213c:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    8000213e:	00000097          	auipc	ra,0x0
    80002142:	e38080e7          	jalr	-456(ra) # 80001f76 <allocproc>
    80002146:	10050c63          	beqz	a0,8000225e <fork+0x13c>
    8000214a:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    8000214c:	048ab603          	ld	a2,72(s5)
    80002150:	692c                	ld	a1,80(a0)
    80002152:	050ab503          	ld	a0,80(s5)
    80002156:	fffff097          	auipc	ra,0xfffff
    8000215a:	7ce080e7          	jalr	1998(ra) # 80001924 <uvmcopy>
    8000215e:	04054863          	bltz	a0,800021ae <fork+0x8c>
  np->sz = p->sz;
    80002162:	048ab783          	ld	a5,72(s5)
    80002166:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    8000216a:	058ab683          	ld	a3,88(s5)
    8000216e:	87b6                	mv	a5,a3
    80002170:	058a3703          	ld	a4,88(s4)
    80002174:	12068693          	addi	a3,a3,288
    80002178:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    8000217c:	6788                	ld	a0,8(a5)
    8000217e:	6b8c                	ld	a1,16(a5)
    80002180:	6f90                	ld	a2,24(a5)
    80002182:	01073023          	sd	a6,0(a4)
    80002186:	e708                	sd	a0,8(a4)
    80002188:	eb0c                	sd	a1,16(a4)
    8000218a:	ef10                	sd	a2,24(a4)
    8000218c:	02078793          	addi	a5,a5,32
    80002190:	02070713          	addi	a4,a4,32
    80002194:	fed792e3          	bne	a5,a3,80002178 <fork+0x56>
  np->trapframe->a0 = 0;
    80002198:	058a3783          	ld	a5,88(s4)
    8000219c:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    800021a0:	0d0a8493          	addi	s1,s5,208
    800021a4:	0d0a0913          	addi	s2,s4,208
    800021a8:	150a8993          	addi	s3,s5,336
    800021ac:	a00d                	j	800021ce <fork+0xac>
    freeproc(np);
    800021ae:	8552                	mv	a0,s4
    800021b0:	00000097          	auipc	ra,0x0
    800021b4:	d6e080e7          	jalr	-658(ra) # 80001f1e <freeproc>
    release(&np->lock);
    800021b8:	8552                	mv	a0,s4
    800021ba:	fffff097          	auipc	ra,0xfffff
    800021be:	e90080e7          	jalr	-368(ra) # 8000104a <release>
    return -1;
    800021c2:	597d                	li	s2,-1
    800021c4:	a059                	j	8000224a <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    800021c6:	04a1                	addi	s1,s1,8
    800021c8:	0921                	addi	s2,s2,8
    800021ca:	01348b63          	beq	s1,s3,800021e0 <fork+0xbe>
    if(p->ofile[i])
    800021ce:	6088                	ld	a0,0(s1)
    800021d0:	d97d                	beqz	a0,800021c6 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    800021d2:	00003097          	auipc	ra,0x3
    800021d6:	9b8080e7          	jalr	-1608(ra) # 80004b8a <filedup>
    800021da:	00a93023          	sd	a0,0(s2)
    800021de:	b7e5                	j	800021c6 <fork+0xa4>
  np->cwd = idup(p->cwd);
    800021e0:	150ab503          	ld	a0,336(s5)
    800021e4:	00002097          	auipc	ra,0x2
    800021e8:	b2c080e7          	jalr	-1236(ra) # 80003d10 <idup>
    800021ec:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    800021f0:	4641                	li	a2,16
    800021f2:	158a8593          	addi	a1,s5,344
    800021f6:	158a0513          	addi	a0,s4,344
    800021fa:	fffff097          	auipc	ra,0xfffff
    800021fe:	fe2080e7          	jalr	-30(ra) # 800011dc <safestrcpy>
  pid = np->pid;
    80002202:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80002206:	8552                	mv	a0,s4
    80002208:	fffff097          	auipc	ra,0xfffff
    8000220c:	e42080e7          	jalr	-446(ra) # 8000104a <release>
  acquire(&wait_lock);
    80002210:	0000f497          	auipc	s1,0xf
    80002214:	36048493          	addi	s1,s1,864 # 80011570 <wait_lock>
    80002218:	8526                	mv	a0,s1
    8000221a:	fffff097          	auipc	ra,0xfffff
    8000221e:	d7c080e7          	jalr	-644(ra) # 80000f96 <acquire>
  np->parent = p;
    80002222:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80002226:	8526                	mv	a0,s1
    80002228:	fffff097          	auipc	ra,0xfffff
    8000222c:	e22080e7          	jalr	-478(ra) # 8000104a <release>
  acquire(&np->lock);
    80002230:	8552                	mv	a0,s4
    80002232:	fffff097          	auipc	ra,0xfffff
    80002236:	d64080e7          	jalr	-668(ra) # 80000f96 <acquire>
  np->state = RUNNABLE;
    8000223a:	478d                	li	a5,3
    8000223c:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80002240:	8552                	mv	a0,s4
    80002242:	fffff097          	auipc	ra,0xfffff
    80002246:	e08080e7          	jalr	-504(ra) # 8000104a <release>
}
    8000224a:	854a                	mv	a0,s2
    8000224c:	70e2                	ld	ra,56(sp)
    8000224e:	7442                	ld	s0,48(sp)
    80002250:	74a2                	ld	s1,40(sp)
    80002252:	7902                	ld	s2,32(sp)
    80002254:	69e2                	ld	s3,24(sp)
    80002256:	6a42                	ld	s4,16(sp)
    80002258:	6aa2                	ld	s5,8(sp)
    8000225a:	6121                	addi	sp,sp,64
    8000225c:	8082                	ret
    return -1;
    8000225e:	597d                	li	s2,-1
    80002260:	b7ed                	j	8000224a <fork+0x128>

0000000080002262 <scheduler>:
{
    80002262:	7139                	addi	sp,sp,-64
    80002264:	fc06                	sd	ra,56(sp)
    80002266:	f822                	sd	s0,48(sp)
    80002268:	f426                	sd	s1,40(sp)
    8000226a:	f04a                	sd	s2,32(sp)
    8000226c:	ec4e                	sd	s3,24(sp)
    8000226e:	e852                	sd	s4,16(sp)
    80002270:	e456                	sd	s5,8(sp)
    80002272:	e05a                	sd	s6,0(sp)
    80002274:	0080                	addi	s0,sp,64
    80002276:	8792                	mv	a5,tp
  int id = r_tp();
    80002278:	2781                	sext.w	a5,a5
  c->proc = 0;
    8000227a:	00779a93          	slli	s5,a5,0x7
    8000227e:	0000f717          	auipc	a4,0xf
    80002282:	2da70713          	addi	a4,a4,730 # 80011558 <pid_lock>
    80002286:	9756                	add	a4,a4,s5
    80002288:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    8000228c:	0000f717          	auipc	a4,0xf
    80002290:	30470713          	addi	a4,a4,772 # 80011590 <cpus+0x8>
    80002294:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80002296:	498d                	li	s3,3
        p->state = RUNNING;
    80002298:	4b11                	li	s6,4
        c->proc = p;
    8000229a:	079e                	slli	a5,a5,0x7
    8000229c:	0000fa17          	auipc	s4,0xf
    800022a0:	2bca0a13          	addi	s4,s4,700 # 80011558 <pid_lock>
    800022a4:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    800022a6:	00015917          	auipc	s2,0x15
    800022aa:	0e290913          	addi	s2,s2,226 # 80017388 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800022ae:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800022b2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800022b6:	10079073          	csrw	sstatus,a5
    800022ba:	0000f497          	auipc	s1,0xf
    800022be:	6ce48493          	addi	s1,s1,1742 # 80011988 <proc>
    800022c2:	a811                	j	800022d6 <scheduler+0x74>
      release(&p->lock);
    800022c4:	8526                	mv	a0,s1
    800022c6:	fffff097          	auipc	ra,0xfffff
    800022ca:	d84080e7          	jalr	-636(ra) # 8000104a <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    800022ce:	16848493          	addi	s1,s1,360
    800022d2:	fd248ee3          	beq	s1,s2,800022ae <scheduler+0x4c>
      acquire(&p->lock);
    800022d6:	8526                	mv	a0,s1
    800022d8:	fffff097          	auipc	ra,0xfffff
    800022dc:	cbe080e7          	jalr	-834(ra) # 80000f96 <acquire>
      if(p->state == RUNNABLE) {
    800022e0:	4c9c                	lw	a5,24(s1)
    800022e2:	ff3791e3          	bne	a5,s3,800022c4 <scheduler+0x62>
        p->state = RUNNING;
    800022e6:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    800022ea:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    800022ee:	06048593          	addi	a1,s1,96
    800022f2:	8556                	mv	a0,s5
    800022f4:	00001097          	auipc	ra,0x1
    800022f8:	992080e7          	jalr	-1646(ra) # 80002c86 <swtch>
        c->proc = 0;
    800022fc:	020a3823          	sd	zero,48(s4)
    80002300:	b7d1                	j	800022c4 <scheduler+0x62>

0000000080002302 <sched>:
{
    80002302:	7179                	addi	sp,sp,-48
    80002304:	f406                	sd	ra,40(sp)
    80002306:	f022                	sd	s0,32(sp)
    80002308:	ec26                	sd	s1,24(sp)
    8000230a:	e84a                	sd	s2,16(sp)
    8000230c:	e44e                	sd	s3,8(sp)
    8000230e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002310:	00000097          	auipc	ra,0x0
    80002314:	a5c080e7          	jalr	-1444(ra) # 80001d6c <myproc>
    80002318:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000231a:	fffff097          	auipc	ra,0xfffff
    8000231e:	c02080e7          	jalr	-1022(ra) # 80000f1c <holding>
    80002322:	c93d                	beqz	a0,80002398 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002324:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002326:	2781                	sext.w	a5,a5
    80002328:	079e                	slli	a5,a5,0x7
    8000232a:	0000f717          	auipc	a4,0xf
    8000232e:	22e70713          	addi	a4,a4,558 # 80011558 <pid_lock>
    80002332:	97ba                	add	a5,a5,a4
    80002334:	0a87a703          	lw	a4,168(a5)
    80002338:	4785                	li	a5,1
    8000233a:	06f71763          	bne	a4,a5,800023a8 <sched+0xa6>
  if(p->state == RUNNING)
    8000233e:	4c98                	lw	a4,24(s1)
    80002340:	4791                	li	a5,4
    80002342:	06f70b63          	beq	a4,a5,800023b8 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002346:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000234a:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000234c:	efb5                	bnez	a5,800023c8 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000234e:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002350:	0000f917          	auipc	s2,0xf
    80002354:	20890913          	addi	s2,s2,520 # 80011558 <pid_lock>
    80002358:	2781                	sext.w	a5,a5
    8000235a:	079e                	slli	a5,a5,0x7
    8000235c:	97ca                	add	a5,a5,s2
    8000235e:	0ac7a983          	lw	s3,172(a5)
    80002362:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002364:	2781                	sext.w	a5,a5
    80002366:	079e                	slli	a5,a5,0x7
    80002368:	0000f597          	auipc	a1,0xf
    8000236c:	22858593          	addi	a1,a1,552 # 80011590 <cpus+0x8>
    80002370:	95be                	add	a1,a1,a5
    80002372:	06048513          	addi	a0,s1,96
    80002376:	00001097          	auipc	ra,0x1
    8000237a:	910080e7          	jalr	-1776(ra) # 80002c86 <swtch>
    8000237e:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002380:	2781                	sext.w	a5,a5
    80002382:	079e                	slli	a5,a5,0x7
    80002384:	97ca                	add	a5,a5,s2
    80002386:	0b37a623          	sw	s3,172(a5)
}
    8000238a:	70a2                	ld	ra,40(sp)
    8000238c:	7402                	ld	s0,32(sp)
    8000238e:	64e2                	ld	s1,24(sp)
    80002390:	6942                	ld	s2,16(sp)
    80002392:	69a2                	ld	s3,8(sp)
    80002394:	6145                	addi	sp,sp,48
    80002396:	8082                	ret
    panic("sched p->lock");
    80002398:	00006517          	auipc	a0,0x6
    8000239c:	ed050513          	addi	a0,a0,-304 # 80008268 <digits+0x1d8>
    800023a0:	ffffe097          	auipc	ra,0xffffe
    800023a4:	55e080e7          	jalr	1374(ra) # 800008fe <panic>
    panic("sched locks");
    800023a8:	00006517          	auipc	a0,0x6
    800023ac:	ed050513          	addi	a0,a0,-304 # 80008278 <digits+0x1e8>
    800023b0:	ffffe097          	auipc	ra,0xffffe
    800023b4:	54e080e7          	jalr	1358(ra) # 800008fe <panic>
    panic("sched running");
    800023b8:	00006517          	auipc	a0,0x6
    800023bc:	ed050513          	addi	a0,a0,-304 # 80008288 <digits+0x1f8>
    800023c0:	ffffe097          	auipc	ra,0xffffe
    800023c4:	53e080e7          	jalr	1342(ra) # 800008fe <panic>
    panic("sched interruptible");
    800023c8:	00006517          	auipc	a0,0x6
    800023cc:	ed050513          	addi	a0,a0,-304 # 80008298 <digits+0x208>
    800023d0:	ffffe097          	auipc	ra,0xffffe
    800023d4:	52e080e7          	jalr	1326(ra) # 800008fe <panic>

00000000800023d8 <yield>:
{
    800023d8:	1101                	addi	sp,sp,-32
    800023da:	ec06                	sd	ra,24(sp)
    800023dc:	e822                	sd	s0,16(sp)
    800023de:	e426                	sd	s1,8(sp)
    800023e0:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800023e2:	00000097          	auipc	ra,0x0
    800023e6:	98a080e7          	jalr	-1654(ra) # 80001d6c <myproc>
    800023ea:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800023ec:	fffff097          	auipc	ra,0xfffff
    800023f0:	baa080e7          	jalr	-1110(ra) # 80000f96 <acquire>
  p->state = RUNNABLE;
    800023f4:	478d                	li	a5,3
    800023f6:	cc9c                	sw	a5,24(s1)
  sched();
    800023f8:	00000097          	auipc	ra,0x0
    800023fc:	f0a080e7          	jalr	-246(ra) # 80002302 <sched>
  release(&p->lock);
    80002400:	8526                	mv	a0,s1
    80002402:	fffff097          	auipc	ra,0xfffff
    80002406:	c48080e7          	jalr	-952(ra) # 8000104a <release>
}
    8000240a:	60e2                	ld	ra,24(sp)
    8000240c:	6442                	ld	s0,16(sp)
    8000240e:	64a2                	ld	s1,8(sp)
    80002410:	6105                	addi	sp,sp,32
    80002412:	8082                	ret

0000000080002414 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002414:	7179                	addi	sp,sp,-48
    80002416:	f406                	sd	ra,40(sp)
    80002418:	f022                	sd	s0,32(sp)
    8000241a:	ec26                	sd	s1,24(sp)
    8000241c:	e84a                	sd	s2,16(sp)
    8000241e:	e44e                	sd	s3,8(sp)
    80002420:	1800                	addi	s0,sp,48
    80002422:	89aa                	mv	s3,a0
    80002424:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002426:	00000097          	auipc	ra,0x0
    8000242a:	946080e7          	jalr	-1722(ra) # 80001d6c <myproc>
    8000242e:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002430:	fffff097          	auipc	ra,0xfffff
    80002434:	b66080e7          	jalr	-1178(ra) # 80000f96 <acquire>
  release(lk);
    80002438:	854a                	mv	a0,s2
    8000243a:	fffff097          	auipc	ra,0xfffff
    8000243e:	c10080e7          	jalr	-1008(ra) # 8000104a <release>

  // Go to sleep.
  p->chan = chan;
    80002442:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002446:	4789                	li	a5,2
    80002448:	cc9c                	sw	a5,24(s1)

  sched();
    8000244a:	00000097          	auipc	ra,0x0
    8000244e:	eb8080e7          	jalr	-328(ra) # 80002302 <sched>

  // Tidy up.
  p->chan = 0;
    80002452:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002456:	8526                	mv	a0,s1
    80002458:	fffff097          	auipc	ra,0xfffff
    8000245c:	bf2080e7          	jalr	-1038(ra) # 8000104a <release>
  acquire(lk);
    80002460:	854a                	mv	a0,s2
    80002462:	fffff097          	auipc	ra,0xfffff
    80002466:	b34080e7          	jalr	-1228(ra) # 80000f96 <acquire>
}
    8000246a:	70a2                	ld	ra,40(sp)
    8000246c:	7402                	ld	s0,32(sp)
    8000246e:	64e2                	ld	s1,24(sp)
    80002470:	6942                	ld	s2,16(sp)
    80002472:	69a2                	ld	s3,8(sp)
    80002474:	6145                	addi	sp,sp,48
    80002476:	8082                	ret

0000000080002478 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002478:	7139                	addi	sp,sp,-64
    8000247a:	fc06                	sd	ra,56(sp)
    8000247c:	f822                	sd	s0,48(sp)
    8000247e:	f426                	sd	s1,40(sp)
    80002480:	f04a                	sd	s2,32(sp)
    80002482:	ec4e                	sd	s3,24(sp)
    80002484:	e852                	sd	s4,16(sp)
    80002486:	e456                	sd	s5,8(sp)
    80002488:	0080                	addi	s0,sp,64
    8000248a:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000248c:	0000f497          	auipc	s1,0xf
    80002490:	4fc48493          	addi	s1,s1,1276 # 80011988 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002494:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002496:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002498:	00015917          	auipc	s2,0x15
    8000249c:	ef090913          	addi	s2,s2,-272 # 80017388 <tickslock>
    800024a0:	a811                	j	800024b4 <wakeup+0x3c>
      }
      release(&p->lock);
    800024a2:	8526                	mv	a0,s1
    800024a4:	fffff097          	auipc	ra,0xfffff
    800024a8:	ba6080e7          	jalr	-1114(ra) # 8000104a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800024ac:	16848493          	addi	s1,s1,360
    800024b0:	03248663          	beq	s1,s2,800024dc <wakeup+0x64>
    if(p != myproc()){
    800024b4:	00000097          	auipc	ra,0x0
    800024b8:	8b8080e7          	jalr	-1864(ra) # 80001d6c <myproc>
    800024bc:	fea488e3          	beq	s1,a0,800024ac <wakeup+0x34>
      acquire(&p->lock);
    800024c0:	8526                	mv	a0,s1
    800024c2:	fffff097          	auipc	ra,0xfffff
    800024c6:	ad4080e7          	jalr	-1324(ra) # 80000f96 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800024ca:	4c9c                	lw	a5,24(s1)
    800024cc:	fd379be3          	bne	a5,s3,800024a2 <wakeup+0x2a>
    800024d0:	709c                	ld	a5,32(s1)
    800024d2:	fd4798e3          	bne	a5,s4,800024a2 <wakeup+0x2a>
        p->state = RUNNABLE;
    800024d6:	0154ac23          	sw	s5,24(s1)
    800024da:	b7e1                	j	800024a2 <wakeup+0x2a>
    }
  }
}
    800024dc:	70e2                	ld	ra,56(sp)
    800024de:	7442                	ld	s0,48(sp)
    800024e0:	74a2                	ld	s1,40(sp)
    800024e2:	7902                	ld	s2,32(sp)
    800024e4:	69e2                	ld	s3,24(sp)
    800024e6:	6a42                	ld	s4,16(sp)
    800024e8:	6aa2                	ld	s5,8(sp)
    800024ea:	6121                	addi	sp,sp,64
    800024ec:	8082                	ret

00000000800024ee <reparent>:
{
    800024ee:	7179                	addi	sp,sp,-48
    800024f0:	f406                	sd	ra,40(sp)
    800024f2:	f022                	sd	s0,32(sp)
    800024f4:	ec26                	sd	s1,24(sp)
    800024f6:	e84a                	sd	s2,16(sp)
    800024f8:	e44e                	sd	s3,8(sp)
    800024fa:	e052                	sd	s4,0(sp)
    800024fc:	1800                	addi	s0,sp,48
    800024fe:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002500:	0000f497          	auipc	s1,0xf
    80002504:	48848493          	addi	s1,s1,1160 # 80011988 <proc>
      pp->parent = initproc;
    80002508:	00006a17          	auipc	s4,0x6
    8000250c:	510a0a13          	addi	s4,s4,1296 # 80008a18 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002510:	00015997          	auipc	s3,0x15
    80002514:	e7898993          	addi	s3,s3,-392 # 80017388 <tickslock>
    80002518:	a029                	j	80002522 <reparent+0x34>
    8000251a:	16848493          	addi	s1,s1,360
    8000251e:	01348d63          	beq	s1,s3,80002538 <reparent+0x4a>
    if(pp->parent == p){
    80002522:	7c9c                	ld	a5,56(s1)
    80002524:	ff279be3          	bne	a5,s2,8000251a <reparent+0x2c>
      pp->parent = initproc;
    80002528:	000a3503          	ld	a0,0(s4)
    8000252c:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000252e:	00000097          	auipc	ra,0x0
    80002532:	f4a080e7          	jalr	-182(ra) # 80002478 <wakeup>
    80002536:	b7d5                	j	8000251a <reparent+0x2c>
}
    80002538:	70a2                	ld	ra,40(sp)
    8000253a:	7402                	ld	s0,32(sp)
    8000253c:	64e2                	ld	s1,24(sp)
    8000253e:	6942                	ld	s2,16(sp)
    80002540:	69a2                	ld	s3,8(sp)
    80002542:	6a02                	ld	s4,0(sp)
    80002544:	6145                	addi	sp,sp,48
    80002546:	8082                	ret

0000000080002548 <exit>:
{
    80002548:	7179                	addi	sp,sp,-48
    8000254a:	f406                	sd	ra,40(sp)
    8000254c:	f022                	sd	s0,32(sp)
    8000254e:	ec26                	sd	s1,24(sp)
    80002550:	e84a                	sd	s2,16(sp)
    80002552:	e44e                	sd	s3,8(sp)
    80002554:	e052                	sd	s4,0(sp)
    80002556:	1800                	addi	s0,sp,48
    80002558:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000255a:	00000097          	auipc	ra,0x0
    8000255e:	812080e7          	jalr	-2030(ra) # 80001d6c <myproc>
    80002562:	89aa                	mv	s3,a0
  if(p == initproc)
    80002564:	00006797          	auipc	a5,0x6
    80002568:	4b47b783          	ld	a5,1204(a5) # 80008a18 <initproc>
    8000256c:	0d050493          	addi	s1,a0,208
    80002570:	15050913          	addi	s2,a0,336
    80002574:	02a79363          	bne	a5,a0,8000259a <exit+0x52>
    panic("init exiting");
    80002578:	00006517          	auipc	a0,0x6
    8000257c:	d3850513          	addi	a0,a0,-712 # 800082b0 <digits+0x220>
    80002580:	ffffe097          	auipc	ra,0xffffe
    80002584:	37e080e7          	jalr	894(ra) # 800008fe <panic>
      fileclose(f);
    80002588:	00002097          	auipc	ra,0x2
    8000258c:	654080e7          	jalr	1620(ra) # 80004bdc <fileclose>
      p->ofile[fd] = 0;
    80002590:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002594:	04a1                	addi	s1,s1,8
    80002596:	01248563          	beq	s1,s2,800025a0 <exit+0x58>
    if(p->ofile[fd]){
    8000259a:	6088                	ld	a0,0(s1)
    8000259c:	f575                	bnez	a0,80002588 <exit+0x40>
    8000259e:	bfdd                	j	80002594 <exit+0x4c>
  begin_op();
    800025a0:	00002097          	auipc	ra,0x2
    800025a4:	170080e7          	jalr	368(ra) # 80004710 <begin_op>
  iput(p->cwd);
    800025a8:	1509b503          	ld	a0,336(s3)
    800025ac:	00002097          	auipc	ra,0x2
    800025b0:	95c080e7          	jalr	-1700(ra) # 80003f08 <iput>
  end_op();
    800025b4:	00002097          	auipc	ra,0x2
    800025b8:	1dc080e7          	jalr	476(ra) # 80004790 <end_op>
  p->cwd = 0;
    800025bc:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800025c0:	0000f497          	auipc	s1,0xf
    800025c4:	fb048493          	addi	s1,s1,-80 # 80011570 <wait_lock>
    800025c8:	8526                	mv	a0,s1
    800025ca:	fffff097          	auipc	ra,0xfffff
    800025ce:	9cc080e7          	jalr	-1588(ra) # 80000f96 <acquire>
  reparent(p);
    800025d2:	854e                	mv	a0,s3
    800025d4:	00000097          	auipc	ra,0x0
    800025d8:	f1a080e7          	jalr	-230(ra) # 800024ee <reparent>
  wakeup(p->parent);
    800025dc:	0389b503          	ld	a0,56(s3)
    800025e0:	00000097          	auipc	ra,0x0
    800025e4:	e98080e7          	jalr	-360(ra) # 80002478 <wakeup>
  acquire(&p->lock);
    800025e8:	854e                	mv	a0,s3
    800025ea:	fffff097          	auipc	ra,0xfffff
    800025ee:	9ac080e7          	jalr	-1620(ra) # 80000f96 <acquire>
  p->xstate = status;
    800025f2:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800025f6:	4795                	li	a5,5
    800025f8:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800025fc:	8526                	mv	a0,s1
    800025fe:	fffff097          	auipc	ra,0xfffff
    80002602:	a4c080e7          	jalr	-1460(ra) # 8000104a <release>
  sched();
    80002606:	00000097          	auipc	ra,0x0
    8000260a:	cfc080e7          	jalr	-772(ra) # 80002302 <sched>
  panic("zombie exit");
    8000260e:	00006517          	auipc	a0,0x6
    80002612:	cb250513          	addi	a0,a0,-846 # 800082c0 <digits+0x230>
    80002616:	ffffe097          	auipc	ra,0xffffe
    8000261a:	2e8080e7          	jalr	744(ra) # 800008fe <panic>

000000008000261e <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000261e:	7179                	addi	sp,sp,-48
    80002620:	f406                	sd	ra,40(sp)
    80002622:	f022                	sd	s0,32(sp)
    80002624:	ec26                	sd	s1,24(sp)
    80002626:	e84a                	sd	s2,16(sp)
    80002628:	e44e                	sd	s3,8(sp)
    8000262a:	1800                	addi	s0,sp,48
    8000262c:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000262e:	0000f497          	auipc	s1,0xf
    80002632:	35a48493          	addi	s1,s1,858 # 80011988 <proc>
    80002636:	00015997          	auipc	s3,0x15
    8000263a:	d5298993          	addi	s3,s3,-686 # 80017388 <tickslock>
    acquire(&p->lock);
    8000263e:	8526                	mv	a0,s1
    80002640:	fffff097          	auipc	ra,0xfffff
    80002644:	956080e7          	jalr	-1706(ra) # 80000f96 <acquire>
    if(p->pid == pid){
    80002648:	589c                	lw	a5,48(s1)
    8000264a:	01278d63          	beq	a5,s2,80002664 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000264e:	8526                	mv	a0,s1
    80002650:	fffff097          	auipc	ra,0xfffff
    80002654:	9fa080e7          	jalr	-1542(ra) # 8000104a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002658:	16848493          	addi	s1,s1,360
    8000265c:	ff3491e3          	bne	s1,s3,8000263e <kill+0x20>
  }
  return -1;
    80002660:	557d                	li	a0,-1
    80002662:	a829                	j	8000267c <kill+0x5e>
      p->killed = 1;
    80002664:	4785                	li	a5,1
    80002666:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002668:	4c98                	lw	a4,24(s1)
    8000266a:	4789                	li	a5,2
    8000266c:	00f70f63          	beq	a4,a5,8000268a <kill+0x6c>
      release(&p->lock);
    80002670:	8526                	mv	a0,s1
    80002672:	fffff097          	auipc	ra,0xfffff
    80002676:	9d8080e7          	jalr	-1576(ra) # 8000104a <release>
      return 0;
    8000267a:	4501                	li	a0,0
}
    8000267c:	70a2                	ld	ra,40(sp)
    8000267e:	7402                	ld	s0,32(sp)
    80002680:	64e2                	ld	s1,24(sp)
    80002682:	6942                	ld	s2,16(sp)
    80002684:	69a2                	ld	s3,8(sp)
    80002686:	6145                	addi	sp,sp,48
    80002688:	8082                	ret
        p->state = RUNNABLE;
    8000268a:	478d                	li	a5,3
    8000268c:	cc9c                	sw	a5,24(s1)
    8000268e:	b7cd                	j	80002670 <kill+0x52>

0000000080002690 <setkilled>:

void
setkilled(struct proc *p)
{
    80002690:	1101                	addi	sp,sp,-32
    80002692:	ec06                	sd	ra,24(sp)
    80002694:	e822                	sd	s0,16(sp)
    80002696:	e426                	sd	s1,8(sp)
    80002698:	1000                	addi	s0,sp,32
    8000269a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000269c:	fffff097          	auipc	ra,0xfffff
    800026a0:	8fa080e7          	jalr	-1798(ra) # 80000f96 <acquire>
  p->killed = 1;
    800026a4:	4785                	li	a5,1
    800026a6:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800026a8:	8526                	mv	a0,s1
    800026aa:	fffff097          	auipc	ra,0xfffff
    800026ae:	9a0080e7          	jalr	-1632(ra) # 8000104a <release>
}
    800026b2:	60e2                	ld	ra,24(sp)
    800026b4:	6442                	ld	s0,16(sp)
    800026b6:	64a2                	ld	s1,8(sp)
    800026b8:	6105                	addi	sp,sp,32
    800026ba:	8082                	ret

00000000800026bc <killed>:

int
killed(struct proc *p)
{
    800026bc:	1101                	addi	sp,sp,-32
    800026be:	ec06                	sd	ra,24(sp)
    800026c0:	e822                	sd	s0,16(sp)
    800026c2:	e426                	sd	s1,8(sp)
    800026c4:	e04a                	sd	s2,0(sp)
    800026c6:	1000                	addi	s0,sp,32
    800026c8:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    800026ca:	fffff097          	auipc	ra,0xfffff
    800026ce:	8cc080e7          	jalr	-1844(ra) # 80000f96 <acquire>
  k = p->killed;
    800026d2:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800026d6:	8526                	mv	a0,s1
    800026d8:	fffff097          	auipc	ra,0xfffff
    800026dc:	972080e7          	jalr	-1678(ra) # 8000104a <release>
  return k;
}
    800026e0:	854a                	mv	a0,s2
    800026e2:	60e2                	ld	ra,24(sp)
    800026e4:	6442                	ld	s0,16(sp)
    800026e6:	64a2                	ld	s1,8(sp)
    800026e8:	6902                	ld	s2,0(sp)
    800026ea:	6105                	addi	sp,sp,32
    800026ec:	8082                	ret

00000000800026ee <wait>:
{
    800026ee:	715d                	addi	sp,sp,-80
    800026f0:	e486                	sd	ra,72(sp)
    800026f2:	e0a2                	sd	s0,64(sp)
    800026f4:	fc26                	sd	s1,56(sp)
    800026f6:	f84a                	sd	s2,48(sp)
    800026f8:	f44e                	sd	s3,40(sp)
    800026fa:	f052                	sd	s4,32(sp)
    800026fc:	ec56                	sd	s5,24(sp)
    800026fe:	e85a                	sd	s6,16(sp)
    80002700:	e45e                	sd	s7,8(sp)
    80002702:	e062                	sd	s8,0(sp)
    80002704:	0880                	addi	s0,sp,80
    80002706:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002708:	fffff097          	auipc	ra,0xfffff
    8000270c:	664080e7          	jalr	1636(ra) # 80001d6c <myproc>
    80002710:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002712:	0000f517          	auipc	a0,0xf
    80002716:	e5e50513          	addi	a0,a0,-418 # 80011570 <wait_lock>
    8000271a:	fffff097          	auipc	ra,0xfffff
    8000271e:	87c080e7          	jalr	-1924(ra) # 80000f96 <acquire>
    havekids = 0;
    80002722:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    80002724:	4a15                	li	s4,5
        havekids = 1;
    80002726:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002728:	00015997          	auipc	s3,0x15
    8000272c:	c6098993          	addi	s3,s3,-928 # 80017388 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002730:	0000fc17          	auipc	s8,0xf
    80002734:	e40c0c13          	addi	s8,s8,-448 # 80011570 <wait_lock>
    havekids = 0;
    80002738:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000273a:	0000f497          	auipc	s1,0xf
    8000273e:	24e48493          	addi	s1,s1,590 # 80011988 <proc>
    80002742:	a0bd                	j	800027b0 <wait+0xc2>
          pid = pp->pid;
    80002744:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002748:	000b0e63          	beqz	s6,80002764 <wait+0x76>
    8000274c:	4691                	li	a3,4
    8000274e:	02c48613          	addi	a2,s1,44
    80002752:	85da                	mv	a1,s6
    80002754:	05093503          	ld	a0,80(s2)
    80002758:	fffff097          	auipc	ra,0xfffff
    8000275c:	2d0080e7          	jalr	720(ra) # 80001a28 <copyout>
    80002760:	02054563          	bltz	a0,8000278a <wait+0x9c>
          freeproc(pp);
    80002764:	8526                	mv	a0,s1
    80002766:	fffff097          	auipc	ra,0xfffff
    8000276a:	7b8080e7          	jalr	1976(ra) # 80001f1e <freeproc>
          release(&pp->lock);
    8000276e:	8526                	mv	a0,s1
    80002770:	fffff097          	auipc	ra,0xfffff
    80002774:	8da080e7          	jalr	-1830(ra) # 8000104a <release>
          release(&wait_lock);
    80002778:	0000f517          	auipc	a0,0xf
    8000277c:	df850513          	addi	a0,a0,-520 # 80011570 <wait_lock>
    80002780:	fffff097          	auipc	ra,0xfffff
    80002784:	8ca080e7          	jalr	-1846(ra) # 8000104a <release>
          return pid;
    80002788:	a0b5                	j	800027f4 <wait+0x106>
            release(&pp->lock);
    8000278a:	8526                	mv	a0,s1
    8000278c:	fffff097          	auipc	ra,0xfffff
    80002790:	8be080e7          	jalr	-1858(ra) # 8000104a <release>
            release(&wait_lock);
    80002794:	0000f517          	auipc	a0,0xf
    80002798:	ddc50513          	addi	a0,a0,-548 # 80011570 <wait_lock>
    8000279c:	fffff097          	auipc	ra,0xfffff
    800027a0:	8ae080e7          	jalr	-1874(ra) # 8000104a <release>
            return -1;
    800027a4:	59fd                	li	s3,-1
    800027a6:	a0b9                	j	800027f4 <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800027a8:	16848493          	addi	s1,s1,360
    800027ac:	03348463          	beq	s1,s3,800027d4 <wait+0xe6>
      if(pp->parent == p){
    800027b0:	7c9c                	ld	a5,56(s1)
    800027b2:	ff279be3          	bne	a5,s2,800027a8 <wait+0xba>
        acquire(&pp->lock);
    800027b6:	8526                	mv	a0,s1
    800027b8:	ffffe097          	auipc	ra,0xffffe
    800027bc:	7de080e7          	jalr	2014(ra) # 80000f96 <acquire>
        if(pp->state == ZOMBIE){
    800027c0:	4c9c                	lw	a5,24(s1)
    800027c2:	f94781e3          	beq	a5,s4,80002744 <wait+0x56>
        release(&pp->lock);
    800027c6:	8526                	mv	a0,s1
    800027c8:	fffff097          	auipc	ra,0xfffff
    800027cc:	882080e7          	jalr	-1918(ra) # 8000104a <release>
        havekids = 1;
    800027d0:	8756                	mv	a4,s5
    800027d2:	bfd9                	j	800027a8 <wait+0xba>
    if(!havekids || killed(p)){
    800027d4:	c719                	beqz	a4,800027e2 <wait+0xf4>
    800027d6:	854a                	mv	a0,s2
    800027d8:	00000097          	auipc	ra,0x0
    800027dc:	ee4080e7          	jalr	-284(ra) # 800026bc <killed>
    800027e0:	c51d                	beqz	a0,8000280e <wait+0x120>
      release(&wait_lock);
    800027e2:	0000f517          	auipc	a0,0xf
    800027e6:	d8e50513          	addi	a0,a0,-626 # 80011570 <wait_lock>
    800027ea:	fffff097          	auipc	ra,0xfffff
    800027ee:	860080e7          	jalr	-1952(ra) # 8000104a <release>
      return -1;
    800027f2:	59fd                	li	s3,-1
}
    800027f4:	854e                	mv	a0,s3
    800027f6:	60a6                	ld	ra,72(sp)
    800027f8:	6406                	ld	s0,64(sp)
    800027fa:	74e2                	ld	s1,56(sp)
    800027fc:	7942                	ld	s2,48(sp)
    800027fe:	79a2                	ld	s3,40(sp)
    80002800:	7a02                	ld	s4,32(sp)
    80002802:	6ae2                	ld	s5,24(sp)
    80002804:	6b42                	ld	s6,16(sp)
    80002806:	6ba2                	ld	s7,8(sp)
    80002808:	6c02                	ld	s8,0(sp)
    8000280a:	6161                	addi	sp,sp,80
    8000280c:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000280e:	85e2                	mv	a1,s8
    80002810:	854a                	mv	a0,s2
    80002812:	00000097          	auipc	ra,0x0
    80002816:	c02080e7          	jalr	-1022(ra) # 80002414 <sleep>
    havekids = 0;
    8000281a:	bf39                	j	80002738 <wait+0x4a>

000000008000281c <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000281c:	7179                	addi	sp,sp,-48
    8000281e:	f406                	sd	ra,40(sp)
    80002820:	f022                	sd	s0,32(sp)
    80002822:	ec26                	sd	s1,24(sp)
    80002824:	e84a                	sd	s2,16(sp)
    80002826:	e44e                	sd	s3,8(sp)
    80002828:	e052                	sd	s4,0(sp)
    8000282a:	1800                	addi	s0,sp,48
    8000282c:	84aa                	mv	s1,a0
    8000282e:	892e                	mv	s2,a1
    80002830:	89b2                	mv	s3,a2
    80002832:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002834:	fffff097          	auipc	ra,0xfffff
    80002838:	538080e7          	jalr	1336(ra) # 80001d6c <myproc>
  if(user_dst){
    8000283c:	c08d                	beqz	s1,8000285e <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000283e:	86d2                	mv	a3,s4
    80002840:	864e                	mv	a2,s3
    80002842:	85ca                	mv	a1,s2
    80002844:	6928                	ld	a0,80(a0)
    80002846:	fffff097          	auipc	ra,0xfffff
    8000284a:	1e2080e7          	jalr	482(ra) # 80001a28 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000284e:	70a2                	ld	ra,40(sp)
    80002850:	7402                	ld	s0,32(sp)
    80002852:	64e2                	ld	s1,24(sp)
    80002854:	6942                	ld	s2,16(sp)
    80002856:	69a2                	ld	s3,8(sp)
    80002858:	6a02                	ld	s4,0(sp)
    8000285a:	6145                	addi	sp,sp,48
    8000285c:	8082                	ret
    memmove((char *)dst, src, len);
    8000285e:	000a061b          	sext.w	a2,s4
    80002862:	85ce                	mv	a1,s3
    80002864:	854a                	mv	a0,s2
    80002866:	fffff097          	auipc	ra,0xfffff
    8000286a:	888080e7          	jalr	-1912(ra) # 800010ee <memmove>
    return 0;
    8000286e:	8526                	mv	a0,s1
    80002870:	bff9                	j	8000284e <either_copyout+0x32>

0000000080002872 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002872:	7179                	addi	sp,sp,-48
    80002874:	f406                	sd	ra,40(sp)
    80002876:	f022                	sd	s0,32(sp)
    80002878:	ec26                	sd	s1,24(sp)
    8000287a:	e84a                	sd	s2,16(sp)
    8000287c:	e44e                	sd	s3,8(sp)
    8000287e:	e052                	sd	s4,0(sp)
    80002880:	1800                	addi	s0,sp,48
    80002882:	892a                	mv	s2,a0
    80002884:	84ae                	mv	s1,a1
    80002886:	89b2                	mv	s3,a2
    80002888:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000288a:	fffff097          	auipc	ra,0xfffff
    8000288e:	4e2080e7          	jalr	1250(ra) # 80001d6c <myproc>
  if(user_src){
    80002892:	c08d                	beqz	s1,800028b4 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002894:	86d2                	mv	a3,s4
    80002896:	864e                	mv	a2,s3
    80002898:	85ca                	mv	a1,s2
    8000289a:	6928                	ld	a0,80(a0)
    8000289c:	fffff097          	auipc	ra,0xfffff
    800028a0:	218080e7          	jalr	536(ra) # 80001ab4 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800028a4:	70a2                	ld	ra,40(sp)
    800028a6:	7402                	ld	s0,32(sp)
    800028a8:	64e2                	ld	s1,24(sp)
    800028aa:	6942                	ld	s2,16(sp)
    800028ac:	69a2                	ld	s3,8(sp)
    800028ae:	6a02                	ld	s4,0(sp)
    800028b0:	6145                	addi	sp,sp,48
    800028b2:	8082                	ret
    memmove(dst, (char*)src, len);
    800028b4:	000a061b          	sext.w	a2,s4
    800028b8:	85ce                	mv	a1,s3
    800028ba:	854a                	mv	a0,s2
    800028bc:	fffff097          	auipc	ra,0xfffff
    800028c0:	832080e7          	jalr	-1998(ra) # 800010ee <memmove>
    return 0;
    800028c4:	8526                	mv	a0,s1
    800028c6:	bff9                	j	800028a4 <either_copyin+0x32>

00000000800028c8 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800028c8:	715d                	addi	sp,sp,-80
    800028ca:	e486                	sd	ra,72(sp)
    800028cc:	e0a2                	sd	s0,64(sp)
    800028ce:	fc26                	sd	s1,56(sp)
    800028d0:	f84a                	sd	s2,48(sp)
    800028d2:	f44e                	sd	s3,40(sp)
    800028d4:	f052                	sd	s4,32(sp)
    800028d6:	ec56                	sd	s5,24(sp)
    800028d8:	e85a                	sd	s6,16(sp)
    800028da:	e45e                	sd	s7,8(sp)
    800028dc:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800028de:	00006517          	auipc	a0,0x6
    800028e2:	a6250513          	addi	a0,a0,-1438 # 80008340 <digits+0x2b0>
    800028e6:	ffffe097          	auipc	ra,0xffffe
    800028ea:	062080e7          	jalr	98(ra) # 80000948 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800028ee:	0000f497          	auipc	s1,0xf
    800028f2:	1f248493          	addi	s1,s1,498 # 80011ae0 <proc+0x158>
    800028f6:	00015917          	auipc	s2,0x15
    800028fa:	bea90913          	addi	s2,s2,-1046 # 800174e0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028fe:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002900:	00006997          	auipc	s3,0x6
    80002904:	9d098993          	addi	s3,s3,-1584 # 800082d0 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002908:	00006a97          	auipc	s5,0x6
    8000290c:	9d0a8a93          	addi	s5,s5,-1584 # 800082d8 <digits+0x248>
    printf("\n");
    80002910:	00006a17          	auipc	s4,0x6
    80002914:	a30a0a13          	addi	s4,s4,-1488 # 80008340 <digits+0x2b0>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002918:	00006b97          	auipc	s7,0x6
    8000291c:	ad0b8b93          	addi	s7,s7,-1328 # 800083e8 <states.1>
    80002920:	a00d                	j	80002942 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002922:	ed86a583          	lw	a1,-296(a3)
    80002926:	8556                	mv	a0,s5
    80002928:	ffffe097          	auipc	ra,0xffffe
    8000292c:	020080e7          	jalr	32(ra) # 80000948 <printf>
    printf("\n");
    80002930:	8552                	mv	a0,s4
    80002932:	ffffe097          	auipc	ra,0xffffe
    80002936:	016080e7          	jalr	22(ra) # 80000948 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000293a:	16848493          	addi	s1,s1,360
    8000293e:	03248163          	beq	s1,s2,80002960 <procdump+0x98>
    if(p->state == UNUSED)
    80002942:	86a6                	mv	a3,s1
    80002944:	ec04a783          	lw	a5,-320(s1)
    80002948:	dbed                	beqz	a5,8000293a <procdump+0x72>
      state = "???";
    8000294a:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000294c:	fcfb6be3          	bltu	s6,a5,80002922 <procdump+0x5a>
    80002950:	1782                	slli	a5,a5,0x20
    80002952:	9381                	srli	a5,a5,0x20
    80002954:	078e                	slli	a5,a5,0x3
    80002956:	97de                	add	a5,a5,s7
    80002958:	6390                	ld	a2,0(a5)
    8000295a:	f661                	bnez	a2,80002922 <procdump+0x5a>
      state = "???";
    8000295c:	864e                	mv	a2,s3
    8000295e:	b7d1                	j	80002922 <procdump+0x5a>
  }
}
    80002960:	60a6                	ld	ra,72(sp)
    80002962:	6406                	ld	s0,64(sp)
    80002964:	74e2                	ld	s1,56(sp)
    80002966:	7942                	ld	s2,48(sp)
    80002968:	79a2                	ld	s3,40(sp)
    8000296a:	7a02                	ld	s4,32(sp)
    8000296c:	6ae2                	ld	s5,24(sp)
    8000296e:	6b42                	ld	s6,16(sp)
    80002970:	6ba2                	ld	s7,8(sp)
    80002972:	6161                	addi	sp,sp,80
    80002974:	8082                	ret

0000000080002976 <history>:

void
history(int history_index) {
    80002976:	715d                	addi	sp,sp,-80
    80002978:	e486                	sd	ra,72(sp)
    8000297a:	e0a2                	sd	s0,64(sp)
    8000297c:	fc26                	sd	s1,56(sp)
    8000297e:	f84a                	sd	s2,48(sp)
    80002980:	f44e                	sd	s3,40(sp)
    80002982:	f052                	sd	s4,32(sp)
    80002984:	ec56                	sd	s5,24(sp)
    80002986:	e85a                	sd	s6,16(sp)
    80002988:	e45e                	sd	s7,8(sp)
    8000298a:	e062                	sd	s8,0(sp)
    8000298c:	0880                	addi	s0,sp,80
    int index = (historyBuffer.lastCommandIndex - history_index - 1) % MAX_HISTORY;
    8000298e:	0000f797          	auipc	a5,0xf
    80002992:	28a78793          	addi	a5,a5,650 # 80011c18 <proc+0x290>
    80002996:	8407aa83          	lw	s5,-1984(a5)
    8000299a:	3afd                	addiw	s5,s5,-1
    8000299c:	40aa8abb          	subw	s5,s5,a0
    800029a0:	00fafa93          	andi	s5,s5,15
    if (index < 0) {
        index += MAX_HISTORY;
    }
    if (index < 0 || index > historyBuffer.numOfCommandsInMem - 1 || history_index > 15) {
    800029a4:	8447a783          	lw	a5,-1980(a5)
    800029a8:	00fad563          	bge	s5,a5,800029b2 <history+0x3c>
    800029ac:	47bd                	li	a5,15
    800029ae:	02a7d663          	bge	a5,a0,800029da <history+0x64>
        printf("Index out of range!\n");
    800029b2:	00006517          	auipc	a0,0x6
    800029b6:	93650513          	addi	a0,a0,-1738 # 800082e8 <digits+0x258>
    800029ba:	ffffe097          	auipc	ra,0xffffe
    800029be:	f8e080e7          	jalr	-114(ra) # 80000948 <printf>
            consputc(historyBuffer.bufferArr[index][i]);
        }
        printf("\n");
    }

}
    800029c2:	60a6                	ld	ra,72(sp)
    800029c4:	6406                	ld	s0,64(sp)
    800029c6:	74e2                	ld	s1,56(sp)
    800029c8:	7942                	ld	s2,48(sp)
    800029ca:	79a2                	ld	s3,40(sp)
    800029cc:	7a02                	ld	s4,32(sp)
    800029ce:	6ae2                	ld	s5,24(sp)
    800029d0:	6b42                	ld	s6,16(sp)
    800029d2:	6ba2                	ld	s7,8(sp)
    800029d4:	6c02                	ld	s8,0(sp)
    800029d6:	6161                	addi	sp,sp,80
    800029d8:	8082                	ret
        for (int j = 0; j < historyBuffer.numOfCommandsInMem; j++) {
    800029da:	4b01                	li	s6,0
            int t_index = (historyBuffer.lastCommandIndex - j - 1) % MAX_HISTORY;
    800029dc:	0000e997          	auipc	s3,0xe
    800029e0:	23c98993          	addi	s3,s3,572 # 80010c18 <historyBuffer>
    800029e4:	0000fb97          	auipc	s7,0xf
    800029e8:	234b8b93          	addi	s7,s7,564 # 80011c18 <proc+0x290>
            printf("\n");
    800029ec:	00006c17          	auipc	s8,0x6
    800029f0:	954c0c13          	addi	s8,s8,-1708 # 80008340 <digits+0x2b0>
            int t_index = (historyBuffer.lastCommandIndex - j - 1) % MAX_HISTORY;
    800029f4:	840ba903          	lw	s2,-1984(s7)
    800029f8:	397d                	addiw	s2,s2,-1
    800029fa:	4169093b          	subw	s2,s2,s6
    800029fe:	00f97913          	andi	s2,s2,15
            for (int i = 0; i < historyBuffer.lengthArr[t_index]; i++) {
    80002a02:	20090793          	addi	a5,s2,512
    80002a06:	078a                	slli	a5,a5,0x2
    80002a08:	97ce                	add	a5,a5,s3
    80002a0a:	439c                	lw	a5,0(a5)
    80002a0c:	cb85                	beqz	a5,80002a3c <history+0xc6>
    80002a0e:	00791a13          	slli	s4,s2,0x7
    80002a12:	4481                	li	s1,0
    80002a14:	20090913          	addi	s2,s2,512
    80002a18:	090a                	slli	s2,s2,0x2
    80002a1a:	994e                	add	s2,s2,s3
                consputc(historyBuffer.bufferArr[t_index][i]);
    80002a1c:	014487b3          	add	a5,s1,s4
    80002a20:	97ce                	add	a5,a5,s3
    80002a22:	0007c503          	lbu	a0,0(a5)
    80002a26:	ffffe097          	auipc	ra,0xffffe
    80002a2a:	856080e7          	jalr	-1962(ra) # 8000027c <consputc>
            for (int i = 0; i < historyBuffer.lengthArr[t_index]; i++) {
    80002a2e:	0485                	addi	s1,s1,1
    80002a30:	00092703          	lw	a4,0(s2)
    80002a34:	0004879b          	sext.w	a5,s1
    80002a38:	fee7e2e3          	bltu	a5,a4,80002a1c <history+0xa6>
            printf("\n");
    80002a3c:	8562                	mv	a0,s8
    80002a3e:	ffffe097          	auipc	ra,0xffffe
    80002a42:	f0a080e7          	jalr	-246(ra) # 80000948 <printf>
        for (int j = 0; j < historyBuffer.numOfCommandsInMem; j++) {
    80002a46:	2b05                	addiw	s6,s6,1
    80002a48:	844ba783          	lw	a5,-1980(s7)
    80002a4c:	fafb44e3          	blt	s6,a5,800029f4 <history+0x7e>
        printf("requested command: ");
    80002a50:	00006517          	auipc	a0,0x6
    80002a54:	8b050513          	addi	a0,a0,-1872 # 80008300 <digits+0x270>
    80002a58:	ffffe097          	auipc	ra,0xffffe
    80002a5c:	ef0080e7          	jalr	-272(ra) # 80000948 <printf>
        for (int i = 0; i < historyBuffer.lengthArr[index]; i++) {
    80002a60:	200a8793          	addi	a5,s5,512
    80002a64:	00279713          	slli	a4,a5,0x2
    80002a68:	0000e797          	auipc	a5,0xe
    80002a6c:	1b078793          	addi	a5,a5,432 # 80010c18 <historyBuffer>
    80002a70:	97ba                	add	a5,a5,a4
    80002a72:	439c                	lw	a5,0(a5)
    80002a74:	cb95                	beqz	a5,80002aa8 <history+0x132>
    80002a76:	007a9a13          	slli	s4,s5,0x7
    80002a7a:	4481                	li	s1,0
            consputc(historyBuffer.bufferArr[index][i]);
    80002a7c:	0000e997          	auipc	s3,0xe
    80002a80:	19c98993          	addi	s3,s3,412 # 80010c18 <historyBuffer>
        for (int i = 0; i < historyBuffer.lengthArr[index]; i++) {
    80002a84:	00e98933          	add	s2,s3,a4
            consputc(historyBuffer.bufferArr[index][i]);
    80002a88:	009a07b3          	add	a5,s4,s1
    80002a8c:	97ce                	add	a5,a5,s3
    80002a8e:	0007c503          	lbu	a0,0(a5)
    80002a92:	ffffd097          	auipc	ra,0xffffd
    80002a96:	7ea080e7          	jalr	2026(ra) # 8000027c <consputc>
        for (int i = 0; i < historyBuffer.lengthArr[index]; i++) {
    80002a9a:	0485                	addi	s1,s1,1
    80002a9c:	00092703          	lw	a4,0(s2)
    80002aa0:	0004879b          	sext.w	a5,s1
    80002aa4:	fee7e2e3          	bltu	a5,a4,80002a88 <history+0x112>
        printf("\n");
    80002aa8:	00006517          	auipc	a0,0x6
    80002aac:	89850513          	addi	a0,a0,-1896 # 80008340 <digits+0x2b0>
    80002ab0:	ffffe097          	auipc	ra,0xffffe
    80002ab4:	e98080e7          	jalr	-360(ra) # 80000948 <printf>
}
    80002ab8:	b729                	j	800029c2 <history+0x4c>

0000000080002aba <top>:

void
top(uint64 upt) {
    80002aba:	8a010113          	addi	sp,sp,-1888
    80002abe:	74113c23          	sd	ra,1880(sp)
    80002ac2:	74813823          	sd	s0,1872(sp)
    80002ac6:	74913423          	sd	s1,1864(sp)
    80002aca:	75213023          	sd	s2,1856(sp)
    80002ace:	73313c23          	sd	s3,1848(sp)
    80002ad2:	73413823          	sd	s4,1840(sp)
    80002ad6:	73513423          	sd	s5,1832(sp)
    80002ada:	73613023          	sd	s6,1824(sp)
    80002ade:	76010413          	addi	s0,sp,1888
    80002ae2:	85aa                	mv	a1,a0
    t.total_process = 0;
    t.running_process = 0;
    t.sleeping_process = 0;

    int index = 0;
    for (p = proc; p < &proc[NPROC]; p++) {
    80002ae4:	0000f617          	auipc	a2,0xf
    80002ae8:	00c60613          	addi	a2,a2,12 # 80011af0 <proc+0x168>
    80002aec:	00015e17          	auipc	t3,0x15
    80002af0:	a04e0e13          	addi	t3,t3,-1532 # 800174f0 <bcache+0x150>
    t.sleeping_process = 0;
    80002af4:	4981                	li	s3,0
    t.running_process = 0;
    80002af6:	4901                	li	s2,0
    t.total_process = 0;
    80002af8:	4481                	li	s1,0
    int index = 0;
    80002afa:	4801                	li	a6,0
        t.p_list[index].state = p->state;


        
        t.total_process++;
        if (p->state == RUNNING)
    80002afc:	4e91                	li	t4,4
            t.running_process++;
        else if (p->state == SLEEPING)
    80002afe:	4f09                	li	t5,2
    80002b00:	a039                	j	80002b0e <top+0x54>
            t.running_process++;
    80002b02:	2905                	addiw	s2,s2,1
            t.sleeping_process++;
        index++;
    80002b04:	2805                	addiw	a6,a6,1
    for (p = proc; p < &proc[NPROC]; p++) {
    80002b06:	16860613          	addi	a2,a2,360
    80002b0a:	09c60063          	beq	a2,t3,80002b8a <top+0xd0>
        if (p->state == UNUSED) {
    80002b0e:	8332                	mv	t1,a2
    80002b10:	eb062883          	lw	a7,-336(a2)
    80002b14:	fe0889e3          	beqz	a7,80002b06 <top+0x4c>
    80002b18:	ff060793          	addi	a5,a2,-16
    80002b1c:	00381713          	slli	a4,a6,0x3
    80002b20:	41070733          	sub	a4,a4,a6
    80002b24:	070a                	slli	a4,a4,0x2
    80002b26:	0751                	addi	a4,a4,20
    80002b28:	8a840693          	addi	a3,s0,-1880
    80002b2c:	9736                	add	a4,a4,a3
            t.p_list[index].name[j] = p->name[j];
    80002b2e:	0007c683          	lbu	a3,0(a5)
    80002b32:	00d70023          	sb	a3,0(a4)
            if (p->name[j] == '\0')
    80002b36:	c689                	beqz	a3,80002b40 <top+0x86>
        for (int j = 0; j < 16; j++) {
    80002b38:	0785                	addi	a5,a5,1
    80002b3a:	0705                	addi	a4,a4,1
    80002b3c:	fec799e3          	bne	a5,a2,80002b2e <top+0x74>
        t.p_list[index].pid = p->pid;
    80002b40:	00381793          	slli	a5,a6,0x3
    80002b44:	410787b3          	sub	a5,a5,a6
    80002b48:	078a                	slli	a5,a5,0x2
    80002b4a:	fc040713          	addi	a4,s0,-64
    80002b4e:	97ba                	add	a5,a5,a4
    80002b50:	ec832703          	lw	a4,-312(t1)
    80002b54:	90e7a623          	sw	a4,-1780(a5)
            t.p_list[index].ppid = 0;
    80002b58:	8742                	mv	a4,a6
        if (index != 0) {
    80002b5a:	00080563          	beqz	a6,80002b64 <top+0xaa>
            t.p_list[index].ppid = p->parent->pid;
    80002b5e:	ed033783          	ld	a5,-304(t1)
    80002b62:	5b98                	lw	a4,48(a5)
    80002b64:	00381793          	slli	a5,a6,0x3
    80002b68:	410787b3          	sub	a5,a5,a6
    80002b6c:	078a                	slli	a5,a5,0x2
    80002b6e:	fc040693          	addi	a3,s0,-64
    80002b72:	97b6                	add	a5,a5,a3
    80002b74:	90e7a823          	sw	a4,-1776(a5)
        t.p_list[index].state = p->state;
    80002b78:	9117aa23          	sw	a7,-1772(a5)
        t.total_process++;
    80002b7c:	2485                	addiw	s1,s1,1
        if (p->state == RUNNING)
    80002b7e:	f9d882e3          	beq	a7,t4,80002b02 <top+0x48>
        else if (p->state == SLEEPING)
    80002b82:	f9e891e3          	bne	a7,t5,80002b04 <top+0x4a>
            t.sleeping_process++;
    80002b86:	2985                	addiw	s3,s3,1
    80002b88:	bfb5                	j	80002b04 <top+0x4a>
    }

    printf("uptime:%d ticks\n", upt);
    80002b8a:	00005517          	auipc	a0,0x5
    80002b8e:	78e50513          	addi	a0,a0,1934 # 80008318 <digits+0x288>
    80002b92:	ffffe097          	auipc	ra,0xffffe
    80002b96:	db6080e7          	jalr	-586(ra) # 80000948 <printf>
    printf("total process:%d\n", t.total_process);
    80002b9a:	85a6                	mv	a1,s1
    80002b9c:	00005517          	auipc	a0,0x5
    80002ba0:	79450513          	addi	a0,a0,1940 # 80008330 <digits+0x2a0>
    80002ba4:	ffffe097          	auipc	ra,0xffffe
    80002ba8:	da4080e7          	jalr	-604(ra) # 80000948 <printf>
    printf("running process:%d\n", t.running_process);
    80002bac:	85ca                	mv	a1,s2
    80002bae:	00005517          	auipc	a0,0x5
    80002bb2:	79a50513          	addi	a0,a0,1946 # 80008348 <digits+0x2b8>
    80002bb6:	ffffe097          	auipc	ra,0xffffe
    80002bba:	d92080e7          	jalr	-622(ra) # 80000948 <printf>
    printf("sleeping process:%d\n", t.sleeping_process);
    80002bbe:	85ce                	mv	a1,s3
    80002bc0:	00005517          	auipc	a0,0x5
    80002bc4:	7a050513          	addi	a0,a0,1952 # 80008360 <digits+0x2d0>
    80002bc8:	ffffe097          	auipc	ra,0xffffe
    80002bcc:	d80080e7          	jalr	-640(ra) # 80000948 <printf>
    printf("name    PID     PPID    state\n");
    80002bd0:	00005517          	auipc	a0,0x5
    80002bd4:	7a850513          	addi	a0,a0,1960 # 80008378 <digits+0x2e8>
    80002bd8:	ffffe097          	auipc	ra,0xffffe
    80002bdc:	d70080e7          	jalr	-656(ra) # 80000948 <printf>
    for (int i = 0; i < t.total_process; i++) {
    80002be0:	08905063          	blez	s1,80002c60 <top+0x1a6>
    80002be4:	8b840913          	addi	s2,s0,-1864
    80002be8:	fff4879b          	addiw	a5,s1,-1
    80002bec:	1782                	slli	a5,a5,0x20
    80002bee:	9381                	srli	a5,a5,0x20
    80002bf0:	00379993          	slli	s3,a5,0x3
    80002bf4:	40f989b3          	sub	s3,s3,a5
    80002bf8:	098a                	slli	s3,s3,0x2
    80002bfa:	8d440793          	addi	a5,s0,-1836
    80002bfe:	99be                	add	s3,s3,a5
        for (int j = 0; j < 16; j++) {
            if (t.p_list[i].name[j] == '\0')
                break;
            consputc(t.p_list[i].name[j]);
        }
        printf("    %d    %d    ", t.p_list[i].pid, t.p_list[i].ppid);
    80002c00:	00005b17          	auipc	s6,0x5
    80002c04:	798b0b13          	addi	s6,s6,1944 # 80008398 <digits+0x308>
        state = states[t.p_list[i].state];
    80002c08:	00005a97          	auipc	s5,0x5
    80002c0c:	7e0a8a93          	addi	s5,s5,2016 # 800083e8 <states.1>
        printf("%s\n", state);
    80002c10:	00005a17          	auipc	s4,0x5
    80002c14:	7a0a0a13          	addi	s4,s4,1952 # 800083b0 <digits+0x320>
    80002c18:	a03d                	j	80002c46 <top+0x18c>
        printf("    %d    %d    ", t.p_list[i].pid, t.p_list[i].ppid);
    80002c1a:	01892603          	lw	a2,24(s2)
    80002c1e:	01492583          	lw	a1,20(s2)
    80002c22:	855a                	mv	a0,s6
    80002c24:	ffffe097          	auipc	ra,0xffffe
    80002c28:	d24080e7          	jalr	-732(ra) # 80000948 <printf>
        state = states[t.p_list[i].state];
    80002c2c:	01c96783          	lwu	a5,28(s2)
    80002c30:	078e                	slli	a5,a5,0x3
    80002c32:	97d6                	add	a5,a5,s5
        printf("%s\n", state);
    80002c34:	7b8c                	ld	a1,48(a5)
    80002c36:	8552                	mv	a0,s4
    80002c38:	ffffe097          	auipc	ra,0xffffe
    80002c3c:	d10080e7          	jalr	-752(ra) # 80000948 <printf>
    for (int i = 0; i < t.total_process; i++) {
    80002c40:	0971                	addi	s2,s2,28
    80002c42:	01390f63          	beq	s2,s3,80002c60 <top+0x1a6>
        for (int j = 0; j < 16; j++) {
    80002c46:	ff090493          	addi	s1,s2,-16
            if (t.p_list[i].name[j] == '\0')
    80002c4a:	0144c503          	lbu	a0,20(s1)
    80002c4e:	d571                	beqz	a0,80002c1a <top+0x160>
            consputc(t.p_list[i].name[j]);
    80002c50:	ffffd097          	auipc	ra,0xffffd
    80002c54:	62c080e7          	jalr	1580(ra) # 8000027c <consputc>
        for (int j = 0; j < 16; j++) {
    80002c58:	0485                	addi	s1,s1,1
    80002c5a:	ff2498e3          	bne	s1,s2,80002c4a <top+0x190>
    80002c5e:	bf75                	j	80002c1a <top+0x160>
    }
    80002c60:	75813083          	ld	ra,1880(sp)
    80002c64:	75013403          	ld	s0,1872(sp)
    80002c68:	74813483          	ld	s1,1864(sp)
    80002c6c:	74013903          	ld	s2,1856(sp)
    80002c70:	73813983          	ld	s3,1848(sp)
    80002c74:	73013a03          	ld	s4,1840(sp)
    80002c78:	72813a83          	ld	s5,1832(sp)
    80002c7c:	72013b03          	ld	s6,1824(sp)
    80002c80:	76010113          	addi	sp,sp,1888
    80002c84:	8082                	ret

0000000080002c86 <swtch>:
    80002c86:	00153023          	sd	ra,0(a0)
    80002c8a:	00253423          	sd	sp,8(a0)
    80002c8e:	e900                	sd	s0,16(a0)
    80002c90:	ed04                	sd	s1,24(a0)
    80002c92:	03253023          	sd	s2,32(a0)
    80002c96:	03353423          	sd	s3,40(a0)
    80002c9a:	03453823          	sd	s4,48(a0)
    80002c9e:	03553c23          	sd	s5,56(a0)
    80002ca2:	05653023          	sd	s6,64(a0)
    80002ca6:	05753423          	sd	s7,72(a0)
    80002caa:	05853823          	sd	s8,80(a0)
    80002cae:	05953c23          	sd	s9,88(a0)
    80002cb2:	07a53023          	sd	s10,96(a0)
    80002cb6:	07b53423          	sd	s11,104(a0)
    80002cba:	0005b083          	ld	ra,0(a1)
    80002cbe:	0085b103          	ld	sp,8(a1)
    80002cc2:	6980                	ld	s0,16(a1)
    80002cc4:	6d84                	ld	s1,24(a1)
    80002cc6:	0205b903          	ld	s2,32(a1)
    80002cca:	0285b983          	ld	s3,40(a1)
    80002cce:	0305ba03          	ld	s4,48(a1)
    80002cd2:	0385ba83          	ld	s5,56(a1)
    80002cd6:	0405bb03          	ld	s6,64(a1)
    80002cda:	0485bb83          	ld	s7,72(a1)
    80002cde:	0505bc03          	ld	s8,80(a1)
    80002ce2:	0585bc83          	ld	s9,88(a1)
    80002ce6:	0605bd03          	ld	s10,96(a1)
    80002cea:	0685bd83          	ld	s11,104(a1)
    80002cee:	8082                	ret

0000000080002cf0 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002cf0:	1141                	addi	sp,sp,-16
    80002cf2:	e406                	sd	ra,8(sp)
    80002cf4:	e022                	sd	s0,0(sp)
    80002cf6:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002cf8:	00005597          	auipc	a1,0x5
    80002cfc:	75058593          	addi	a1,a1,1872 # 80008448 <states.0+0x30>
    80002d00:	00014517          	auipc	a0,0x14
    80002d04:	68850513          	addi	a0,a0,1672 # 80017388 <tickslock>
    80002d08:	ffffe097          	auipc	ra,0xffffe
    80002d0c:	1fe080e7          	jalr	510(ra) # 80000f06 <initlock>
}
    80002d10:	60a2                	ld	ra,8(sp)
    80002d12:	6402                	ld	s0,0(sp)
    80002d14:	0141                	addi	sp,sp,16
    80002d16:	8082                	ret

0000000080002d18 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002d18:	1141                	addi	sp,sp,-16
    80002d1a:	e422                	sd	s0,8(sp)
    80002d1c:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d1e:	00003797          	auipc	a5,0x3
    80002d22:	51278793          	addi	a5,a5,1298 # 80006230 <kernelvec>
    80002d26:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002d2a:	6422                	ld	s0,8(sp)
    80002d2c:	0141                	addi	sp,sp,16
    80002d2e:	8082                	ret

0000000080002d30 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002d30:	1141                	addi	sp,sp,-16
    80002d32:	e406                	sd	ra,8(sp)
    80002d34:	e022                	sd	s0,0(sp)
    80002d36:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002d38:	fffff097          	auipc	ra,0xfffff
    80002d3c:	034080e7          	jalr	52(ra) # 80001d6c <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d40:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002d44:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d46:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002d4a:	00004617          	auipc	a2,0x4
    80002d4e:	2b660613          	addi	a2,a2,694 # 80007000 <_trampoline>
    80002d52:	00004697          	auipc	a3,0x4
    80002d56:	2ae68693          	addi	a3,a3,686 # 80007000 <_trampoline>
    80002d5a:	8e91                	sub	a3,a3,a2
    80002d5c:	040007b7          	lui	a5,0x4000
    80002d60:	17fd                	addi	a5,a5,-1
    80002d62:	07b2                	slli	a5,a5,0xc
    80002d64:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d66:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002d6a:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002d6c:	180026f3          	csrr	a3,satp
    80002d70:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002d72:	6d38                	ld	a4,88(a0)
    80002d74:	6134                	ld	a3,64(a0)
    80002d76:	6585                	lui	a1,0x1
    80002d78:	96ae                	add	a3,a3,a1
    80002d7a:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002d7c:	6d38                	ld	a4,88(a0)
    80002d7e:	00000697          	auipc	a3,0x0
    80002d82:	13068693          	addi	a3,a3,304 # 80002eae <usertrap>
    80002d86:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002d88:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002d8a:	8692                	mv	a3,tp
    80002d8c:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d8e:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002d92:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002d96:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d9a:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002d9e:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002da0:	6f18                	ld	a4,24(a4)
    80002da2:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002da6:	6928                	ld	a0,80(a0)
    80002da8:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002daa:	00004717          	auipc	a4,0x4
    80002dae:	2f270713          	addi	a4,a4,754 # 8000709c <userret>
    80002db2:	8f11                	sub	a4,a4,a2
    80002db4:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002db6:	577d                	li	a4,-1
    80002db8:	177e                	slli	a4,a4,0x3f
    80002dba:	8d59                	or	a0,a0,a4
    80002dbc:	9782                	jalr	a5
}
    80002dbe:	60a2                	ld	ra,8(sp)
    80002dc0:	6402                	ld	s0,0(sp)
    80002dc2:	0141                	addi	sp,sp,16
    80002dc4:	8082                	ret

0000000080002dc6 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002dc6:	1101                	addi	sp,sp,-32
    80002dc8:	ec06                	sd	ra,24(sp)
    80002dca:	e822                	sd	s0,16(sp)
    80002dcc:	e426                	sd	s1,8(sp)
    80002dce:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002dd0:	00014497          	auipc	s1,0x14
    80002dd4:	5b848493          	addi	s1,s1,1464 # 80017388 <tickslock>
    80002dd8:	8526                	mv	a0,s1
    80002dda:	ffffe097          	auipc	ra,0xffffe
    80002dde:	1bc080e7          	jalr	444(ra) # 80000f96 <acquire>
  ticks++;
    80002de2:	00006517          	auipc	a0,0x6
    80002de6:	c3e50513          	addi	a0,a0,-962 # 80008a20 <ticks>
    80002dea:	411c                	lw	a5,0(a0)
    80002dec:	2785                	addiw	a5,a5,1
    80002dee:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002df0:	fffff097          	auipc	ra,0xfffff
    80002df4:	688080e7          	jalr	1672(ra) # 80002478 <wakeup>
  release(&tickslock);
    80002df8:	8526                	mv	a0,s1
    80002dfa:	ffffe097          	auipc	ra,0xffffe
    80002dfe:	250080e7          	jalr	592(ra) # 8000104a <release>
}
    80002e02:	60e2                	ld	ra,24(sp)
    80002e04:	6442                	ld	s0,16(sp)
    80002e06:	64a2                	ld	s1,8(sp)
    80002e08:	6105                	addi	sp,sp,32
    80002e0a:	8082                	ret

0000000080002e0c <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002e0c:	1101                	addi	sp,sp,-32
    80002e0e:	ec06                	sd	ra,24(sp)
    80002e10:	e822                	sd	s0,16(sp)
    80002e12:	e426                	sd	s1,8(sp)
    80002e14:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e16:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002e1a:	00074d63          	bltz	a4,80002e34 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002e1e:	57fd                	li	a5,-1
    80002e20:	17fe                	slli	a5,a5,0x3f
    80002e22:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002e24:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002e26:	06f70363          	beq	a4,a5,80002e8c <devintr+0x80>
  }
}
    80002e2a:	60e2                	ld	ra,24(sp)
    80002e2c:	6442                	ld	s0,16(sp)
    80002e2e:	64a2                	ld	s1,8(sp)
    80002e30:	6105                	addi	sp,sp,32
    80002e32:	8082                	ret
     (scause & 0xff) == 9){
    80002e34:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002e38:	46a5                	li	a3,9
    80002e3a:	fed792e3          	bne	a5,a3,80002e1e <devintr+0x12>
    int irq = plic_claim();
    80002e3e:	00003097          	auipc	ra,0x3
    80002e42:	4fa080e7          	jalr	1274(ra) # 80006338 <plic_claim>
    80002e46:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002e48:	47a9                	li	a5,10
    80002e4a:	02f50763          	beq	a0,a5,80002e78 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002e4e:	4785                	li	a5,1
    80002e50:	02f50963          	beq	a0,a5,80002e82 <devintr+0x76>
    return 1;
    80002e54:	4505                	li	a0,1
    } else if(irq){
    80002e56:	d8f1                	beqz	s1,80002e2a <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002e58:	85a6                	mv	a1,s1
    80002e5a:	00005517          	auipc	a0,0x5
    80002e5e:	5f650513          	addi	a0,a0,1526 # 80008450 <states.0+0x38>
    80002e62:	ffffe097          	auipc	ra,0xffffe
    80002e66:	ae6080e7          	jalr	-1306(ra) # 80000948 <printf>
      plic_complete(irq);
    80002e6a:	8526                	mv	a0,s1
    80002e6c:	00003097          	auipc	ra,0x3
    80002e70:	4f0080e7          	jalr	1264(ra) # 8000635c <plic_complete>
    return 1;
    80002e74:	4505                	li	a0,1
    80002e76:	bf55                	j	80002e2a <devintr+0x1e>
      uartintr();
    80002e78:	ffffe097          	auipc	ra,0xffffe
    80002e7c:	ee2080e7          	jalr	-286(ra) # 80000d5a <uartintr>
    80002e80:	b7ed                	j	80002e6a <devintr+0x5e>
      virtio_disk_intr();
    80002e82:	00004097          	auipc	ra,0x4
    80002e86:	9a6080e7          	jalr	-1626(ra) # 80006828 <virtio_disk_intr>
    80002e8a:	b7c5                	j	80002e6a <devintr+0x5e>
    if(cpuid() == 0){
    80002e8c:	fffff097          	auipc	ra,0xfffff
    80002e90:	eb4080e7          	jalr	-332(ra) # 80001d40 <cpuid>
    80002e94:	c901                	beqz	a0,80002ea4 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002e96:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002e9a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002e9c:	14479073          	csrw	sip,a5
    return 2;
    80002ea0:	4509                	li	a0,2
    80002ea2:	b761                	j	80002e2a <devintr+0x1e>
      clockintr();
    80002ea4:	00000097          	auipc	ra,0x0
    80002ea8:	f22080e7          	jalr	-222(ra) # 80002dc6 <clockintr>
    80002eac:	b7ed                	j	80002e96 <devintr+0x8a>

0000000080002eae <usertrap>:
{
    80002eae:	1101                	addi	sp,sp,-32
    80002eb0:	ec06                	sd	ra,24(sp)
    80002eb2:	e822                	sd	s0,16(sp)
    80002eb4:	e426                	sd	s1,8(sp)
    80002eb6:	e04a                	sd	s2,0(sp)
    80002eb8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002eba:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002ebe:	1007f793          	andi	a5,a5,256
    80002ec2:	e3b1                	bnez	a5,80002f06 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ec4:	00003797          	auipc	a5,0x3
    80002ec8:	36c78793          	addi	a5,a5,876 # 80006230 <kernelvec>
    80002ecc:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002ed0:	fffff097          	auipc	ra,0xfffff
    80002ed4:	e9c080e7          	jalr	-356(ra) # 80001d6c <myproc>
    80002ed8:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002eda:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002edc:	14102773          	csrr	a4,sepc
    80002ee0:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ee2:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002ee6:	47a1                	li	a5,8
    80002ee8:	02f70763          	beq	a4,a5,80002f16 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    80002eec:	00000097          	auipc	ra,0x0
    80002ef0:	f20080e7          	jalr	-224(ra) # 80002e0c <devintr>
    80002ef4:	892a                	mv	s2,a0
    80002ef6:	c151                	beqz	a0,80002f7a <usertrap+0xcc>
  if(killed(p))
    80002ef8:	8526                	mv	a0,s1
    80002efa:	fffff097          	auipc	ra,0xfffff
    80002efe:	7c2080e7          	jalr	1986(ra) # 800026bc <killed>
    80002f02:	c929                	beqz	a0,80002f54 <usertrap+0xa6>
    80002f04:	a099                	j	80002f4a <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002f06:	00005517          	auipc	a0,0x5
    80002f0a:	56a50513          	addi	a0,a0,1386 # 80008470 <states.0+0x58>
    80002f0e:	ffffe097          	auipc	ra,0xffffe
    80002f12:	9f0080e7          	jalr	-1552(ra) # 800008fe <panic>
    if(killed(p))
    80002f16:	fffff097          	auipc	ra,0xfffff
    80002f1a:	7a6080e7          	jalr	1958(ra) # 800026bc <killed>
    80002f1e:	e921                	bnez	a0,80002f6e <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002f20:	6cb8                	ld	a4,88(s1)
    80002f22:	6f1c                	ld	a5,24(a4)
    80002f24:	0791                	addi	a5,a5,4
    80002f26:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f28:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002f2c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f30:	10079073          	csrw	sstatus,a5
    syscall();
    80002f34:	00000097          	auipc	ra,0x0
    80002f38:	2d4080e7          	jalr	724(ra) # 80003208 <syscall>
  if(killed(p))
    80002f3c:	8526                	mv	a0,s1
    80002f3e:	fffff097          	auipc	ra,0xfffff
    80002f42:	77e080e7          	jalr	1918(ra) # 800026bc <killed>
    80002f46:	c911                	beqz	a0,80002f5a <usertrap+0xac>
    80002f48:	4901                	li	s2,0
    exit(-1);
    80002f4a:	557d                	li	a0,-1
    80002f4c:	fffff097          	auipc	ra,0xfffff
    80002f50:	5fc080e7          	jalr	1532(ra) # 80002548 <exit>
  if(which_dev == 2)
    80002f54:	4789                	li	a5,2
    80002f56:	04f90f63          	beq	s2,a5,80002fb4 <usertrap+0x106>
  usertrapret();
    80002f5a:	00000097          	auipc	ra,0x0
    80002f5e:	dd6080e7          	jalr	-554(ra) # 80002d30 <usertrapret>
}
    80002f62:	60e2                	ld	ra,24(sp)
    80002f64:	6442                	ld	s0,16(sp)
    80002f66:	64a2                	ld	s1,8(sp)
    80002f68:	6902                	ld	s2,0(sp)
    80002f6a:	6105                	addi	sp,sp,32
    80002f6c:	8082                	ret
      exit(-1);
    80002f6e:	557d                	li	a0,-1
    80002f70:	fffff097          	auipc	ra,0xfffff
    80002f74:	5d8080e7          	jalr	1496(ra) # 80002548 <exit>
    80002f78:	b765                	j	80002f20 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f7a:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002f7e:	5890                	lw	a2,48(s1)
    80002f80:	00005517          	auipc	a0,0x5
    80002f84:	51050513          	addi	a0,a0,1296 # 80008490 <states.0+0x78>
    80002f88:	ffffe097          	auipc	ra,0xffffe
    80002f8c:	9c0080e7          	jalr	-1600(ra) # 80000948 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f90:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f94:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f98:	00005517          	auipc	a0,0x5
    80002f9c:	52850513          	addi	a0,a0,1320 # 800084c0 <states.0+0xa8>
    80002fa0:	ffffe097          	auipc	ra,0xffffe
    80002fa4:	9a8080e7          	jalr	-1624(ra) # 80000948 <printf>
    setkilled(p);
    80002fa8:	8526                	mv	a0,s1
    80002faa:	fffff097          	auipc	ra,0xfffff
    80002fae:	6e6080e7          	jalr	1766(ra) # 80002690 <setkilled>
    80002fb2:	b769                	j	80002f3c <usertrap+0x8e>
    yield();
    80002fb4:	fffff097          	auipc	ra,0xfffff
    80002fb8:	424080e7          	jalr	1060(ra) # 800023d8 <yield>
    80002fbc:	bf79                	j	80002f5a <usertrap+0xac>

0000000080002fbe <kerneltrap>:
{
    80002fbe:	7179                	addi	sp,sp,-48
    80002fc0:	f406                	sd	ra,40(sp)
    80002fc2:	f022                	sd	s0,32(sp)
    80002fc4:	ec26                	sd	s1,24(sp)
    80002fc6:	e84a                	sd	s2,16(sp)
    80002fc8:	e44e                	sd	s3,8(sp)
    80002fca:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002fcc:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fd0:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002fd4:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002fd8:	1004f793          	andi	a5,s1,256
    80002fdc:	cb85                	beqz	a5,8000300c <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fde:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002fe2:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002fe4:	ef85                	bnez	a5,8000301c <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002fe6:	00000097          	auipc	ra,0x0
    80002fea:	e26080e7          	jalr	-474(ra) # 80002e0c <devintr>
    80002fee:	cd1d                	beqz	a0,8000302c <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ff0:	4789                	li	a5,2
    80002ff2:	06f50a63          	beq	a0,a5,80003066 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002ff6:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ffa:	10049073          	csrw	sstatus,s1
}
    80002ffe:	70a2                	ld	ra,40(sp)
    80003000:	7402                	ld	s0,32(sp)
    80003002:	64e2                	ld	s1,24(sp)
    80003004:	6942                	ld	s2,16(sp)
    80003006:	69a2                	ld	s3,8(sp)
    80003008:	6145                	addi	sp,sp,48
    8000300a:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    8000300c:	00005517          	auipc	a0,0x5
    80003010:	4d450513          	addi	a0,a0,1236 # 800084e0 <states.0+0xc8>
    80003014:	ffffe097          	auipc	ra,0xffffe
    80003018:	8ea080e7          	jalr	-1814(ra) # 800008fe <panic>
    panic("kerneltrap: interrupts enabled");
    8000301c:	00005517          	auipc	a0,0x5
    80003020:	4ec50513          	addi	a0,a0,1260 # 80008508 <states.0+0xf0>
    80003024:	ffffe097          	auipc	ra,0xffffe
    80003028:	8da080e7          	jalr	-1830(ra) # 800008fe <panic>
    printf("scause %p\n", scause);
    8000302c:	85ce                	mv	a1,s3
    8000302e:	00005517          	auipc	a0,0x5
    80003032:	4fa50513          	addi	a0,a0,1274 # 80008528 <states.0+0x110>
    80003036:	ffffe097          	auipc	ra,0xffffe
    8000303a:	912080e7          	jalr	-1774(ra) # 80000948 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000303e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003042:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003046:	00005517          	auipc	a0,0x5
    8000304a:	4f250513          	addi	a0,a0,1266 # 80008538 <states.0+0x120>
    8000304e:	ffffe097          	auipc	ra,0xffffe
    80003052:	8fa080e7          	jalr	-1798(ra) # 80000948 <printf>
    panic("kerneltrap");
    80003056:	00005517          	auipc	a0,0x5
    8000305a:	4fa50513          	addi	a0,a0,1274 # 80008550 <states.0+0x138>
    8000305e:	ffffe097          	auipc	ra,0xffffe
    80003062:	8a0080e7          	jalr	-1888(ra) # 800008fe <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003066:	fffff097          	auipc	ra,0xfffff
    8000306a:	d06080e7          	jalr	-762(ra) # 80001d6c <myproc>
    8000306e:	d541                	beqz	a0,80002ff6 <kerneltrap+0x38>
    80003070:	fffff097          	auipc	ra,0xfffff
    80003074:	cfc080e7          	jalr	-772(ra) # 80001d6c <myproc>
    80003078:	4d18                	lw	a4,24(a0)
    8000307a:	4791                	li	a5,4
    8000307c:	f6f71de3          	bne	a4,a5,80002ff6 <kerneltrap+0x38>
    yield();
    80003080:	fffff097          	auipc	ra,0xfffff
    80003084:	358080e7          	jalr	856(ra) # 800023d8 <yield>
    80003088:	b7bd                	j	80002ff6 <kerneltrap+0x38>

000000008000308a <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000308a:	1101                	addi	sp,sp,-32
    8000308c:	ec06                	sd	ra,24(sp)
    8000308e:	e822                	sd	s0,16(sp)
    80003090:	e426                	sd	s1,8(sp)
    80003092:	1000                	addi	s0,sp,32
    80003094:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003096:	fffff097          	auipc	ra,0xfffff
    8000309a:	cd6080e7          	jalr	-810(ra) # 80001d6c <myproc>
  switch (n) {
    8000309e:	4795                	li	a5,5
    800030a0:	0497e163          	bltu	a5,s1,800030e2 <argraw+0x58>
    800030a4:	048a                	slli	s1,s1,0x2
    800030a6:	00005717          	auipc	a4,0x5
    800030aa:	4e270713          	addi	a4,a4,1250 # 80008588 <states.0+0x170>
    800030ae:	94ba                	add	s1,s1,a4
    800030b0:	409c                	lw	a5,0(s1)
    800030b2:	97ba                	add	a5,a5,a4
    800030b4:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800030b6:	6d3c                	ld	a5,88(a0)
    800030b8:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800030ba:	60e2                	ld	ra,24(sp)
    800030bc:	6442                	ld	s0,16(sp)
    800030be:	64a2                	ld	s1,8(sp)
    800030c0:	6105                	addi	sp,sp,32
    800030c2:	8082                	ret
    return p->trapframe->a1;
    800030c4:	6d3c                	ld	a5,88(a0)
    800030c6:	7fa8                	ld	a0,120(a5)
    800030c8:	bfcd                	j	800030ba <argraw+0x30>
    return p->trapframe->a2;
    800030ca:	6d3c                	ld	a5,88(a0)
    800030cc:	63c8                	ld	a0,128(a5)
    800030ce:	b7f5                	j	800030ba <argraw+0x30>
    return p->trapframe->a3;
    800030d0:	6d3c                	ld	a5,88(a0)
    800030d2:	67c8                	ld	a0,136(a5)
    800030d4:	b7dd                	j	800030ba <argraw+0x30>
    return p->trapframe->a4;
    800030d6:	6d3c                	ld	a5,88(a0)
    800030d8:	6bc8                	ld	a0,144(a5)
    800030da:	b7c5                	j	800030ba <argraw+0x30>
    return p->trapframe->a5;
    800030dc:	6d3c                	ld	a5,88(a0)
    800030de:	6fc8                	ld	a0,152(a5)
    800030e0:	bfe9                	j	800030ba <argraw+0x30>
  panic("argraw");
    800030e2:	00005517          	auipc	a0,0x5
    800030e6:	47e50513          	addi	a0,a0,1150 # 80008560 <states.0+0x148>
    800030ea:	ffffe097          	auipc	ra,0xffffe
    800030ee:	814080e7          	jalr	-2028(ra) # 800008fe <panic>

00000000800030f2 <fetchaddr>:
{
    800030f2:	1101                	addi	sp,sp,-32
    800030f4:	ec06                	sd	ra,24(sp)
    800030f6:	e822                	sd	s0,16(sp)
    800030f8:	e426                	sd	s1,8(sp)
    800030fa:	e04a                	sd	s2,0(sp)
    800030fc:	1000                	addi	s0,sp,32
    800030fe:	84aa                	mv	s1,a0
    80003100:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80003102:	fffff097          	auipc	ra,0xfffff
    80003106:	c6a080e7          	jalr	-918(ra) # 80001d6c <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    8000310a:	653c                	ld	a5,72(a0)
    8000310c:	02f4f863          	bgeu	s1,a5,8000313c <fetchaddr+0x4a>
    80003110:	00848713          	addi	a4,s1,8
    80003114:	02e7e663          	bltu	a5,a4,80003140 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80003118:	46a1                	li	a3,8
    8000311a:	8626                	mv	a2,s1
    8000311c:	85ca                	mv	a1,s2
    8000311e:	6928                	ld	a0,80(a0)
    80003120:	fffff097          	auipc	ra,0xfffff
    80003124:	994080e7          	jalr	-1644(ra) # 80001ab4 <copyin>
    80003128:	00a03533          	snez	a0,a0
    8000312c:	40a00533          	neg	a0,a0
}
    80003130:	60e2                	ld	ra,24(sp)
    80003132:	6442                	ld	s0,16(sp)
    80003134:	64a2                	ld	s1,8(sp)
    80003136:	6902                	ld	s2,0(sp)
    80003138:	6105                	addi	sp,sp,32
    8000313a:	8082                	ret
    return -1;
    8000313c:	557d                	li	a0,-1
    8000313e:	bfcd                	j	80003130 <fetchaddr+0x3e>
    80003140:	557d                	li	a0,-1
    80003142:	b7fd                	j	80003130 <fetchaddr+0x3e>

0000000080003144 <fetchstr>:
{
    80003144:	7179                	addi	sp,sp,-48
    80003146:	f406                	sd	ra,40(sp)
    80003148:	f022                	sd	s0,32(sp)
    8000314a:	ec26                	sd	s1,24(sp)
    8000314c:	e84a                	sd	s2,16(sp)
    8000314e:	e44e                	sd	s3,8(sp)
    80003150:	1800                	addi	s0,sp,48
    80003152:	892a                	mv	s2,a0
    80003154:	84ae                	mv	s1,a1
    80003156:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003158:	fffff097          	auipc	ra,0xfffff
    8000315c:	c14080e7          	jalr	-1004(ra) # 80001d6c <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80003160:	86ce                	mv	a3,s3
    80003162:	864a                	mv	a2,s2
    80003164:	85a6                	mv	a1,s1
    80003166:	6928                	ld	a0,80(a0)
    80003168:	fffff097          	auipc	ra,0xfffff
    8000316c:	9da080e7          	jalr	-1574(ra) # 80001b42 <copyinstr>
    80003170:	00054e63          	bltz	a0,8000318c <fetchstr+0x48>
  return strlen(buf);
    80003174:	8526                	mv	a0,s1
    80003176:	ffffe097          	auipc	ra,0xffffe
    8000317a:	098080e7          	jalr	152(ra) # 8000120e <strlen>
}
    8000317e:	70a2                	ld	ra,40(sp)
    80003180:	7402                	ld	s0,32(sp)
    80003182:	64e2                	ld	s1,24(sp)
    80003184:	6942                	ld	s2,16(sp)
    80003186:	69a2                	ld	s3,8(sp)
    80003188:	6145                	addi	sp,sp,48
    8000318a:	8082                	ret
    return -1;
    8000318c:	557d                	li	a0,-1
    8000318e:	bfc5                	j	8000317e <fetchstr+0x3a>

0000000080003190 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80003190:	1101                	addi	sp,sp,-32
    80003192:	ec06                	sd	ra,24(sp)
    80003194:	e822                	sd	s0,16(sp)
    80003196:	e426                	sd	s1,8(sp)
    80003198:	1000                	addi	s0,sp,32
    8000319a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000319c:	00000097          	auipc	ra,0x0
    800031a0:	eee080e7          	jalr	-274(ra) # 8000308a <argraw>
    800031a4:	c088                	sw	a0,0(s1)
}
    800031a6:	60e2                	ld	ra,24(sp)
    800031a8:	6442                	ld	s0,16(sp)
    800031aa:	64a2                	ld	s1,8(sp)
    800031ac:	6105                	addi	sp,sp,32
    800031ae:	8082                	ret

00000000800031b0 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    800031b0:	1101                	addi	sp,sp,-32
    800031b2:	ec06                	sd	ra,24(sp)
    800031b4:	e822                	sd	s0,16(sp)
    800031b6:	e426                	sd	s1,8(sp)
    800031b8:	1000                	addi	s0,sp,32
    800031ba:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800031bc:	00000097          	auipc	ra,0x0
    800031c0:	ece080e7          	jalr	-306(ra) # 8000308a <argraw>
    800031c4:	e088                	sd	a0,0(s1)
}
    800031c6:	60e2                	ld	ra,24(sp)
    800031c8:	6442                	ld	s0,16(sp)
    800031ca:	64a2                	ld	s1,8(sp)
    800031cc:	6105                	addi	sp,sp,32
    800031ce:	8082                	ret

00000000800031d0 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800031d0:	7179                	addi	sp,sp,-48
    800031d2:	f406                	sd	ra,40(sp)
    800031d4:	f022                	sd	s0,32(sp)
    800031d6:	ec26                	sd	s1,24(sp)
    800031d8:	e84a                	sd	s2,16(sp)
    800031da:	1800                	addi	s0,sp,48
    800031dc:	84ae                	mv	s1,a1
    800031de:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    800031e0:	fd840593          	addi	a1,s0,-40
    800031e4:	00000097          	auipc	ra,0x0
    800031e8:	fcc080e7          	jalr	-52(ra) # 800031b0 <argaddr>
  return fetchstr(addr, buf, max);
    800031ec:	864a                	mv	a2,s2
    800031ee:	85a6                	mv	a1,s1
    800031f0:	fd843503          	ld	a0,-40(s0)
    800031f4:	00000097          	auipc	ra,0x0
    800031f8:	f50080e7          	jalr	-176(ra) # 80003144 <fetchstr>
}
    800031fc:	70a2                	ld	ra,40(sp)
    800031fe:	7402                	ld	s0,32(sp)
    80003200:	64e2                	ld	s1,24(sp)
    80003202:	6942                	ld	s2,16(sp)
    80003204:	6145                	addi	sp,sp,48
    80003206:	8082                	ret

0000000080003208 <syscall>:
[SYS_top] sys_top,
};

void
syscall(void)
{
    80003208:	1101                	addi	sp,sp,-32
    8000320a:	ec06                	sd	ra,24(sp)
    8000320c:	e822                	sd	s0,16(sp)
    8000320e:	e426                	sd	s1,8(sp)
    80003210:	e04a                	sd	s2,0(sp)
    80003212:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80003214:	fffff097          	auipc	ra,0xfffff
    80003218:	b58080e7          	jalr	-1192(ra) # 80001d6c <myproc>
    8000321c:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    8000321e:	05853903          	ld	s2,88(a0)
    80003222:	0a893783          	ld	a5,168(s2)
    80003226:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    8000322a:	37fd                	addiw	a5,a5,-1
    8000322c:	4759                	li	a4,22
    8000322e:	00f76f63          	bltu	a4,a5,8000324c <syscall+0x44>
    80003232:	00369713          	slli	a4,a3,0x3
    80003236:	00005797          	auipc	a5,0x5
    8000323a:	36a78793          	addi	a5,a5,874 # 800085a0 <syscalls>
    8000323e:	97ba                	add	a5,a5,a4
    80003240:	639c                	ld	a5,0(a5)
    80003242:	c789                	beqz	a5,8000324c <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80003244:	9782                	jalr	a5
    80003246:	06a93823          	sd	a0,112(s2)
    8000324a:	a839                	j	80003268 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    8000324c:	15848613          	addi	a2,s1,344
    80003250:	588c                	lw	a1,48(s1)
    80003252:	00005517          	auipc	a0,0x5
    80003256:	31650513          	addi	a0,a0,790 # 80008568 <states.0+0x150>
    8000325a:	ffffd097          	auipc	ra,0xffffd
    8000325e:	6ee080e7          	jalr	1774(ra) # 80000948 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003262:	6cbc                	ld	a5,88(s1)
    80003264:	577d                	li	a4,-1
    80003266:	fbb8                	sd	a4,112(a5)
  }
}
    80003268:	60e2                	ld	ra,24(sp)
    8000326a:	6442                	ld	s0,16(sp)
    8000326c:	64a2                	ld	s1,8(sp)
    8000326e:	6902                	ld	s2,0(sp)
    80003270:	6105                	addi	sp,sp,32
    80003272:	8082                	ret

0000000080003274 <sys_exit>:
#include "history.h"
#include "top.h"

uint64
sys_exit(void)
{
    80003274:	1101                	addi	sp,sp,-32
    80003276:	ec06                	sd	ra,24(sp)
    80003278:	e822                	sd	s0,16(sp)
    8000327a:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    8000327c:	fec40593          	addi	a1,s0,-20
    80003280:	4501                	li	a0,0
    80003282:	00000097          	auipc	ra,0x0
    80003286:	f0e080e7          	jalr	-242(ra) # 80003190 <argint>
  exit(n);
    8000328a:	fec42503          	lw	a0,-20(s0)
    8000328e:	fffff097          	auipc	ra,0xfffff
    80003292:	2ba080e7          	jalr	698(ra) # 80002548 <exit>
  return 0;  // not reached
}
    80003296:	4501                	li	a0,0
    80003298:	60e2                	ld	ra,24(sp)
    8000329a:	6442                	ld	s0,16(sp)
    8000329c:	6105                	addi	sp,sp,32
    8000329e:	8082                	ret

00000000800032a0 <sys_getpid>:

uint64
sys_getpid(void)
{
    800032a0:	1141                	addi	sp,sp,-16
    800032a2:	e406                	sd	ra,8(sp)
    800032a4:	e022                	sd	s0,0(sp)
    800032a6:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800032a8:	fffff097          	auipc	ra,0xfffff
    800032ac:	ac4080e7          	jalr	-1340(ra) # 80001d6c <myproc>
}
    800032b0:	5908                	lw	a0,48(a0)
    800032b2:	60a2                	ld	ra,8(sp)
    800032b4:	6402                	ld	s0,0(sp)
    800032b6:	0141                	addi	sp,sp,16
    800032b8:	8082                	ret

00000000800032ba <sys_fork>:

uint64
sys_fork(void)
{
    800032ba:	1141                	addi	sp,sp,-16
    800032bc:	e406                	sd	ra,8(sp)
    800032be:	e022                	sd	s0,0(sp)
    800032c0:	0800                	addi	s0,sp,16
  return fork();
    800032c2:	fffff097          	auipc	ra,0xfffff
    800032c6:	e60080e7          	jalr	-416(ra) # 80002122 <fork>
}
    800032ca:	60a2                	ld	ra,8(sp)
    800032cc:	6402                	ld	s0,0(sp)
    800032ce:	0141                	addi	sp,sp,16
    800032d0:	8082                	ret

00000000800032d2 <sys_wait>:

uint64
sys_wait(void)
{
    800032d2:	1101                	addi	sp,sp,-32
    800032d4:	ec06                	sd	ra,24(sp)
    800032d6:	e822                	sd	s0,16(sp)
    800032d8:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    800032da:	fe840593          	addi	a1,s0,-24
    800032de:	4501                	li	a0,0
    800032e0:	00000097          	auipc	ra,0x0
    800032e4:	ed0080e7          	jalr	-304(ra) # 800031b0 <argaddr>
  return wait(p);
    800032e8:	fe843503          	ld	a0,-24(s0)
    800032ec:	fffff097          	auipc	ra,0xfffff
    800032f0:	402080e7          	jalr	1026(ra) # 800026ee <wait>
}
    800032f4:	60e2                	ld	ra,24(sp)
    800032f6:	6442                	ld	s0,16(sp)
    800032f8:	6105                	addi	sp,sp,32
    800032fa:	8082                	ret

00000000800032fc <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800032fc:	7179                	addi	sp,sp,-48
    800032fe:	f406                	sd	ra,40(sp)
    80003300:	f022                	sd	s0,32(sp)
    80003302:	ec26                	sd	s1,24(sp)
    80003304:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80003306:	fdc40593          	addi	a1,s0,-36
    8000330a:	4501                	li	a0,0
    8000330c:	00000097          	auipc	ra,0x0
    80003310:	e84080e7          	jalr	-380(ra) # 80003190 <argint>
  addr = myproc()->sz;
    80003314:	fffff097          	auipc	ra,0xfffff
    80003318:	a58080e7          	jalr	-1448(ra) # 80001d6c <myproc>
    8000331c:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    8000331e:	fdc42503          	lw	a0,-36(s0)
    80003322:	fffff097          	auipc	ra,0xfffff
    80003326:	da4080e7          	jalr	-604(ra) # 800020c6 <growproc>
    8000332a:	00054863          	bltz	a0,8000333a <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    8000332e:	8526                	mv	a0,s1
    80003330:	70a2                	ld	ra,40(sp)
    80003332:	7402                	ld	s0,32(sp)
    80003334:	64e2                	ld	s1,24(sp)
    80003336:	6145                	addi	sp,sp,48
    80003338:	8082                	ret
    return -1;
    8000333a:	54fd                	li	s1,-1
    8000333c:	bfcd                	j	8000332e <sys_sbrk+0x32>

000000008000333e <sys_sleep>:

uint64
sys_sleep(void)
{
    8000333e:	7139                	addi	sp,sp,-64
    80003340:	fc06                	sd	ra,56(sp)
    80003342:	f822                	sd	s0,48(sp)
    80003344:	f426                	sd	s1,40(sp)
    80003346:	f04a                	sd	s2,32(sp)
    80003348:	ec4e                	sd	s3,24(sp)
    8000334a:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    8000334c:	fcc40593          	addi	a1,s0,-52
    80003350:	4501                	li	a0,0
    80003352:	00000097          	auipc	ra,0x0
    80003356:	e3e080e7          	jalr	-450(ra) # 80003190 <argint>
  acquire(&tickslock);
    8000335a:	00014517          	auipc	a0,0x14
    8000335e:	02e50513          	addi	a0,a0,46 # 80017388 <tickslock>
    80003362:	ffffe097          	auipc	ra,0xffffe
    80003366:	c34080e7          	jalr	-972(ra) # 80000f96 <acquire>
  ticks0 = ticks;
    8000336a:	00005917          	auipc	s2,0x5
    8000336e:	6b692903          	lw	s2,1718(s2) # 80008a20 <ticks>
  while(ticks - ticks0 < n){
    80003372:	fcc42783          	lw	a5,-52(s0)
    80003376:	cf9d                	beqz	a5,800033b4 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003378:	00014997          	auipc	s3,0x14
    8000337c:	01098993          	addi	s3,s3,16 # 80017388 <tickslock>
    80003380:	00005497          	auipc	s1,0x5
    80003384:	6a048493          	addi	s1,s1,1696 # 80008a20 <ticks>
    if(killed(myproc())){
    80003388:	fffff097          	auipc	ra,0xfffff
    8000338c:	9e4080e7          	jalr	-1564(ra) # 80001d6c <myproc>
    80003390:	fffff097          	auipc	ra,0xfffff
    80003394:	32c080e7          	jalr	812(ra) # 800026bc <killed>
    80003398:	ed15                	bnez	a0,800033d4 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    8000339a:	85ce                	mv	a1,s3
    8000339c:	8526                	mv	a0,s1
    8000339e:	fffff097          	auipc	ra,0xfffff
    800033a2:	076080e7          	jalr	118(ra) # 80002414 <sleep>
  while(ticks - ticks0 < n){
    800033a6:	409c                	lw	a5,0(s1)
    800033a8:	412787bb          	subw	a5,a5,s2
    800033ac:	fcc42703          	lw	a4,-52(s0)
    800033b0:	fce7ece3          	bltu	a5,a4,80003388 <sys_sleep+0x4a>
  }
  release(&tickslock);
    800033b4:	00014517          	auipc	a0,0x14
    800033b8:	fd450513          	addi	a0,a0,-44 # 80017388 <tickslock>
    800033bc:	ffffe097          	auipc	ra,0xffffe
    800033c0:	c8e080e7          	jalr	-882(ra) # 8000104a <release>
  return 0;
    800033c4:	4501                	li	a0,0
}
    800033c6:	70e2                	ld	ra,56(sp)
    800033c8:	7442                	ld	s0,48(sp)
    800033ca:	74a2                	ld	s1,40(sp)
    800033cc:	7902                	ld	s2,32(sp)
    800033ce:	69e2                	ld	s3,24(sp)
    800033d0:	6121                	addi	sp,sp,64
    800033d2:	8082                	ret
      release(&tickslock);
    800033d4:	00014517          	auipc	a0,0x14
    800033d8:	fb450513          	addi	a0,a0,-76 # 80017388 <tickslock>
    800033dc:	ffffe097          	auipc	ra,0xffffe
    800033e0:	c6e080e7          	jalr	-914(ra) # 8000104a <release>
      return -1;
    800033e4:	557d                	li	a0,-1
    800033e6:	b7c5                	j	800033c6 <sys_sleep+0x88>

00000000800033e8 <sys_kill>:

uint64
sys_kill(void)
{
    800033e8:	1101                	addi	sp,sp,-32
    800033ea:	ec06                	sd	ra,24(sp)
    800033ec:	e822                	sd	s0,16(sp)
    800033ee:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    800033f0:	fec40593          	addi	a1,s0,-20
    800033f4:	4501                	li	a0,0
    800033f6:	00000097          	auipc	ra,0x0
    800033fa:	d9a080e7          	jalr	-614(ra) # 80003190 <argint>
  return kill(pid);
    800033fe:	fec42503          	lw	a0,-20(s0)
    80003402:	fffff097          	auipc	ra,0xfffff
    80003406:	21c080e7          	jalr	540(ra) # 8000261e <kill>
}
    8000340a:	60e2                	ld	ra,24(sp)
    8000340c:	6442                	ld	s0,16(sp)
    8000340e:	6105                	addi	sp,sp,32
    80003410:	8082                	ret

0000000080003412 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003412:	1101                	addi	sp,sp,-32
    80003414:	ec06                	sd	ra,24(sp)
    80003416:	e822                	sd	s0,16(sp)
    80003418:	e426                	sd	s1,8(sp)
    8000341a:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000341c:	00014517          	auipc	a0,0x14
    80003420:	f6c50513          	addi	a0,a0,-148 # 80017388 <tickslock>
    80003424:	ffffe097          	auipc	ra,0xffffe
    80003428:	b72080e7          	jalr	-1166(ra) # 80000f96 <acquire>
  xticks = ticks;
    8000342c:	00005497          	auipc	s1,0x5
    80003430:	5f44a483          	lw	s1,1524(s1) # 80008a20 <ticks>
  release(&tickslock);
    80003434:	00014517          	auipc	a0,0x14
    80003438:	f5450513          	addi	a0,a0,-172 # 80017388 <tickslock>
    8000343c:	ffffe097          	auipc	ra,0xffffe
    80003440:	c0e080e7          	jalr	-1010(ra) # 8000104a <release>
  return xticks;
}
    80003444:	02049513          	slli	a0,s1,0x20
    80003448:	9101                	srli	a0,a0,0x20
    8000344a:	60e2                	ld	ra,24(sp)
    8000344c:	6442                	ld	s0,16(sp)
    8000344e:	64a2                	ld	s1,8(sp)
    80003450:	6105                	addi	sp,sp,32
    80003452:	8082                	ret

0000000080003454 <sys_history>:

uint64
sys_history(int history_index)
{
    80003454:	1101                	addi	sp,sp,-32
    80003456:	ec06                	sd	ra,24(sp)
    80003458:	e822                	sd	s0,16(sp)
    8000345a:	1000                	addi	s0,sp,32
    8000345c:	fea42623          	sw	a0,-20(s0)
    argint(0, &history_index);
    80003460:	fec40593          	addi	a1,s0,-20
    80003464:	4501                	li	a0,0
    80003466:	00000097          	auipc	ra,0x0
    8000346a:	d2a080e7          	jalr	-726(ra) # 80003190 <argint>
    history(history_index);
    8000346e:	fec42503          	lw	a0,-20(s0)
    80003472:	fffff097          	auipc	ra,0xfffff
    80003476:	504080e7          	jalr	1284(ra) # 80002976 <history>
    return 0;

}
    8000347a:	4501                	li	a0,0
    8000347c:	60e2                	ld	ra,24(sp)
    8000347e:	6442                	ld	s0,16(sp)
    80003480:	6105                	addi	sp,sp,32
    80003482:	8082                	ret

0000000080003484 <sys_top>:

uint64
sys_top(void)
{
    80003484:	1141                	addi	sp,sp,-16
    80003486:	e406                	sd	ra,8(sp)
    80003488:	e022                	sd	s0,0(sp)
    8000348a:	0800                	addi	s0,sp,16
    top(sys_uptime());
    8000348c:	00000097          	auipc	ra,0x0
    80003490:	f86080e7          	jalr	-122(ra) # 80003412 <sys_uptime>
    80003494:	fffff097          	auipc	ra,0xfffff
    80003498:	626080e7          	jalr	1574(ra) # 80002aba <top>
    return 0;
}
    8000349c:	4501                	li	a0,0
    8000349e:	60a2                	ld	ra,8(sp)
    800034a0:	6402                	ld	s0,0(sp)
    800034a2:	0141                	addi	sp,sp,16
    800034a4:	8082                	ret

00000000800034a6 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800034a6:	7179                	addi	sp,sp,-48
    800034a8:	f406                	sd	ra,40(sp)
    800034aa:	f022                	sd	s0,32(sp)
    800034ac:	ec26                	sd	s1,24(sp)
    800034ae:	e84a                	sd	s2,16(sp)
    800034b0:	e44e                	sd	s3,8(sp)
    800034b2:	e052                	sd	s4,0(sp)
    800034b4:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800034b6:	00005597          	auipc	a1,0x5
    800034ba:	1aa58593          	addi	a1,a1,426 # 80008660 <syscalls+0xc0>
    800034be:	00014517          	auipc	a0,0x14
    800034c2:	ee250513          	addi	a0,a0,-286 # 800173a0 <bcache>
    800034c6:	ffffe097          	auipc	ra,0xffffe
    800034ca:	a40080e7          	jalr	-1472(ra) # 80000f06 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800034ce:	0001c797          	auipc	a5,0x1c
    800034d2:	ed278793          	addi	a5,a5,-302 # 8001f3a0 <bcache+0x8000>
    800034d6:	0001c717          	auipc	a4,0x1c
    800034da:	13270713          	addi	a4,a4,306 # 8001f608 <bcache+0x8268>
    800034de:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800034e2:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800034e6:	00014497          	auipc	s1,0x14
    800034ea:	ed248493          	addi	s1,s1,-302 # 800173b8 <bcache+0x18>
    b->next = bcache.head.next;
    800034ee:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800034f0:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800034f2:	00005a17          	auipc	s4,0x5
    800034f6:	176a0a13          	addi	s4,s4,374 # 80008668 <syscalls+0xc8>
    b->next = bcache.head.next;
    800034fa:	2b893783          	ld	a5,696(s2)
    800034fe:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003500:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003504:	85d2                	mv	a1,s4
    80003506:	01048513          	addi	a0,s1,16
    8000350a:	00001097          	auipc	ra,0x1
    8000350e:	4c4080e7          	jalr	1220(ra) # 800049ce <initsleeplock>
    bcache.head.next->prev = b;
    80003512:	2b893783          	ld	a5,696(s2)
    80003516:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003518:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000351c:	45848493          	addi	s1,s1,1112
    80003520:	fd349de3          	bne	s1,s3,800034fa <binit+0x54>
  }
}
    80003524:	70a2                	ld	ra,40(sp)
    80003526:	7402                	ld	s0,32(sp)
    80003528:	64e2                	ld	s1,24(sp)
    8000352a:	6942                	ld	s2,16(sp)
    8000352c:	69a2                	ld	s3,8(sp)
    8000352e:	6a02                	ld	s4,0(sp)
    80003530:	6145                	addi	sp,sp,48
    80003532:	8082                	ret

0000000080003534 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003534:	7179                	addi	sp,sp,-48
    80003536:	f406                	sd	ra,40(sp)
    80003538:	f022                	sd	s0,32(sp)
    8000353a:	ec26                	sd	s1,24(sp)
    8000353c:	e84a                	sd	s2,16(sp)
    8000353e:	e44e                	sd	s3,8(sp)
    80003540:	1800                	addi	s0,sp,48
    80003542:	892a                	mv	s2,a0
    80003544:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003546:	00014517          	auipc	a0,0x14
    8000354a:	e5a50513          	addi	a0,a0,-422 # 800173a0 <bcache>
    8000354e:	ffffe097          	auipc	ra,0xffffe
    80003552:	a48080e7          	jalr	-1464(ra) # 80000f96 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003556:	0001c497          	auipc	s1,0x1c
    8000355a:	1024b483          	ld	s1,258(s1) # 8001f658 <bcache+0x82b8>
    8000355e:	0001c797          	auipc	a5,0x1c
    80003562:	0aa78793          	addi	a5,a5,170 # 8001f608 <bcache+0x8268>
    80003566:	02f48f63          	beq	s1,a5,800035a4 <bread+0x70>
    8000356a:	873e                	mv	a4,a5
    8000356c:	a021                	j	80003574 <bread+0x40>
    8000356e:	68a4                	ld	s1,80(s1)
    80003570:	02e48a63          	beq	s1,a4,800035a4 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003574:	449c                	lw	a5,8(s1)
    80003576:	ff279ce3          	bne	a5,s2,8000356e <bread+0x3a>
    8000357a:	44dc                	lw	a5,12(s1)
    8000357c:	ff3799e3          	bne	a5,s3,8000356e <bread+0x3a>
      b->refcnt++;
    80003580:	40bc                	lw	a5,64(s1)
    80003582:	2785                	addiw	a5,a5,1
    80003584:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003586:	00014517          	auipc	a0,0x14
    8000358a:	e1a50513          	addi	a0,a0,-486 # 800173a0 <bcache>
    8000358e:	ffffe097          	auipc	ra,0xffffe
    80003592:	abc080e7          	jalr	-1348(ra) # 8000104a <release>
      acquiresleep(&b->lock);
    80003596:	01048513          	addi	a0,s1,16
    8000359a:	00001097          	auipc	ra,0x1
    8000359e:	46e080e7          	jalr	1134(ra) # 80004a08 <acquiresleep>
      return b;
    800035a2:	a8b9                	j	80003600 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800035a4:	0001c497          	auipc	s1,0x1c
    800035a8:	0ac4b483          	ld	s1,172(s1) # 8001f650 <bcache+0x82b0>
    800035ac:	0001c797          	auipc	a5,0x1c
    800035b0:	05c78793          	addi	a5,a5,92 # 8001f608 <bcache+0x8268>
    800035b4:	00f48863          	beq	s1,a5,800035c4 <bread+0x90>
    800035b8:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800035ba:	40bc                	lw	a5,64(s1)
    800035bc:	cf81                	beqz	a5,800035d4 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800035be:	64a4                	ld	s1,72(s1)
    800035c0:	fee49de3          	bne	s1,a4,800035ba <bread+0x86>
  panic("bget: no buffers");
    800035c4:	00005517          	auipc	a0,0x5
    800035c8:	0ac50513          	addi	a0,a0,172 # 80008670 <syscalls+0xd0>
    800035cc:	ffffd097          	auipc	ra,0xffffd
    800035d0:	332080e7          	jalr	818(ra) # 800008fe <panic>
      b->dev = dev;
    800035d4:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800035d8:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800035dc:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800035e0:	4785                	li	a5,1
    800035e2:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800035e4:	00014517          	auipc	a0,0x14
    800035e8:	dbc50513          	addi	a0,a0,-580 # 800173a0 <bcache>
    800035ec:	ffffe097          	auipc	ra,0xffffe
    800035f0:	a5e080e7          	jalr	-1442(ra) # 8000104a <release>
      acquiresleep(&b->lock);
    800035f4:	01048513          	addi	a0,s1,16
    800035f8:	00001097          	auipc	ra,0x1
    800035fc:	410080e7          	jalr	1040(ra) # 80004a08 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003600:	409c                	lw	a5,0(s1)
    80003602:	cb89                	beqz	a5,80003614 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003604:	8526                	mv	a0,s1
    80003606:	70a2                	ld	ra,40(sp)
    80003608:	7402                	ld	s0,32(sp)
    8000360a:	64e2                	ld	s1,24(sp)
    8000360c:	6942                	ld	s2,16(sp)
    8000360e:	69a2                	ld	s3,8(sp)
    80003610:	6145                	addi	sp,sp,48
    80003612:	8082                	ret
    virtio_disk_rw(b, 0);
    80003614:	4581                	li	a1,0
    80003616:	8526                	mv	a0,s1
    80003618:	00003097          	auipc	ra,0x3
    8000361c:	fdc080e7          	jalr	-36(ra) # 800065f4 <virtio_disk_rw>
    b->valid = 1;
    80003620:	4785                	li	a5,1
    80003622:	c09c                	sw	a5,0(s1)
  return b;
    80003624:	b7c5                	j	80003604 <bread+0xd0>

0000000080003626 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003626:	1101                	addi	sp,sp,-32
    80003628:	ec06                	sd	ra,24(sp)
    8000362a:	e822                	sd	s0,16(sp)
    8000362c:	e426                	sd	s1,8(sp)
    8000362e:	1000                	addi	s0,sp,32
    80003630:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003632:	0541                	addi	a0,a0,16
    80003634:	00001097          	auipc	ra,0x1
    80003638:	46e080e7          	jalr	1134(ra) # 80004aa2 <holdingsleep>
    8000363c:	cd01                	beqz	a0,80003654 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000363e:	4585                	li	a1,1
    80003640:	8526                	mv	a0,s1
    80003642:	00003097          	auipc	ra,0x3
    80003646:	fb2080e7          	jalr	-78(ra) # 800065f4 <virtio_disk_rw>
}
    8000364a:	60e2                	ld	ra,24(sp)
    8000364c:	6442                	ld	s0,16(sp)
    8000364e:	64a2                	ld	s1,8(sp)
    80003650:	6105                	addi	sp,sp,32
    80003652:	8082                	ret
    panic("bwrite");
    80003654:	00005517          	auipc	a0,0x5
    80003658:	03450513          	addi	a0,a0,52 # 80008688 <syscalls+0xe8>
    8000365c:	ffffd097          	auipc	ra,0xffffd
    80003660:	2a2080e7          	jalr	674(ra) # 800008fe <panic>

0000000080003664 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003664:	1101                	addi	sp,sp,-32
    80003666:	ec06                	sd	ra,24(sp)
    80003668:	e822                	sd	s0,16(sp)
    8000366a:	e426                	sd	s1,8(sp)
    8000366c:	e04a                	sd	s2,0(sp)
    8000366e:	1000                	addi	s0,sp,32
    80003670:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003672:	01050913          	addi	s2,a0,16
    80003676:	854a                	mv	a0,s2
    80003678:	00001097          	auipc	ra,0x1
    8000367c:	42a080e7          	jalr	1066(ra) # 80004aa2 <holdingsleep>
    80003680:	c92d                	beqz	a0,800036f2 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003682:	854a                	mv	a0,s2
    80003684:	00001097          	auipc	ra,0x1
    80003688:	3da080e7          	jalr	986(ra) # 80004a5e <releasesleep>

  acquire(&bcache.lock);
    8000368c:	00014517          	auipc	a0,0x14
    80003690:	d1450513          	addi	a0,a0,-748 # 800173a0 <bcache>
    80003694:	ffffe097          	auipc	ra,0xffffe
    80003698:	902080e7          	jalr	-1790(ra) # 80000f96 <acquire>
  b->refcnt--;
    8000369c:	40bc                	lw	a5,64(s1)
    8000369e:	37fd                	addiw	a5,a5,-1
    800036a0:	0007871b          	sext.w	a4,a5
    800036a4:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800036a6:	eb05                	bnez	a4,800036d6 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800036a8:	68bc                	ld	a5,80(s1)
    800036aa:	64b8                	ld	a4,72(s1)
    800036ac:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800036ae:	64bc                	ld	a5,72(s1)
    800036b0:	68b8                	ld	a4,80(s1)
    800036b2:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800036b4:	0001c797          	auipc	a5,0x1c
    800036b8:	cec78793          	addi	a5,a5,-788 # 8001f3a0 <bcache+0x8000>
    800036bc:	2b87b703          	ld	a4,696(a5)
    800036c0:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800036c2:	0001c717          	auipc	a4,0x1c
    800036c6:	f4670713          	addi	a4,a4,-186 # 8001f608 <bcache+0x8268>
    800036ca:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800036cc:	2b87b703          	ld	a4,696(a5)
    800036d0:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800036d2:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800036d6:	00014517          	auipc	a0,0x14
    800036da:	cca50513          	addi	a0,a0,-822 # 800173a0 <bcache>
    800036de:	ffffe097          	auipc	ra,0xffffe
    800036e2:	96c080e7          	jalr	-1684(ra) # 8000104a <release>
}
    800036e6:	60e2                	ld	ra,24(sp)
    800036e8:	6442                	ld	s0,16(sp)
    800036ea:	64a2                	ld	s1,8(sp)
    800036ec:	6902                	ld	s2,0(sp)
    800036ee:	6105                	addi	sp,sp,32
    800036f0:	8082                	ret
    panic("brelse");
    800036f2:	00005517          	auipc	a0,0x5
    800036f6:	f9e50513          	addi	a0,a0,-98 # 80008690 <syscalls+0xf0>
    800036fa:	ffffd097          	auipc	ra,0xffffd
    800036fe:	204080e7          	jalr	516(ra) # 800008fe <panic>

0000000080003702 <bpin>:

void
bpin(struct buf *b) {
    80003702:	1101                	addi	sp,sp,-32
    80003704:	ec06                	sd	ra,24(sp)
    80003706:	e822                	sd	s0,16(sp)
    80003708:	e426                	sd	s1,8(sp)
    8000370a:	1000                	addi	s0,sp,32
    8000370c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000370e:	00014517          	auipc	a0,0x14
    80003712:	c9250513          	addi	a0,a0,-878 # 800173a0 <bcache>
    80003716:	ffffe097          	auipc	ra,0xffffe
    8000371a:	880080e7          	jalr	-1920(ra) # 80000f96 <acquire>
  b->refcnt++;
    8000371e:	40bc                	lw	a5,64(s1)
    80003720:	2785                	addiw	a5,a5,1
    80003722:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003724:	00014517          	auipc	a0,0x14
    80003728:	c7c50513          	addi	a0,a0,-900 # 800173a0 <bcache>
    8000372c:	ffffe097          	auipc	ra,0xffffe
    80003730:	91e080e7          	jalr	-1762(ra) # 8000104a <release>
}
    80003734:	60e2                	ld	ra,24(sp)
    80003736:	6442                	ld	s0,16(sp)
    80003738:	64a2                	ld	s1,8(sp)
    8000373a:	6105                	addi	sp,sp,32
    8000373c:	8082                	ret

000000008000373e <bunpin>:

void
bunpin(struct buf *b) {
    8000373e:	1101                	addi	sp,sp,-32
    80003740:	ec06                	sd	ra,24(sp)
    80003742:	e822                	sd	s0,16(sp)
    80003744:	e426                	sd	s1,8(sp)
    80003746:	1000                	addi	s0,sp,32
    80003748:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000374a:	00014517          	auipc	a0,0x14
    8000374e:	c5650513          	addi	a0,a0,-938 # 800173a0 <bcache>
    80003752:	ffffe097          	auipc	ra,0xffffe
    80003756:	844080e7          	jalr	-1980(ra) # 80000f96 <acquire>
  b->refcnt--;
    8000375a:	40bc                	lw	a5,64(s1)
    8000375c:	37fd                	addiw	a5,a5,-1
    8000375e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003760:	00014517          	auipc	a0,0x14
    80003764:	c4050513          	addi	a0,a0,-960 # 800173a0 <bcache>
    80003768:	ffffe097          	auipc	ra,0xffffe
    8000376c:	8e2080e7          	jalr	-1822(ra) # 8000104a <release>
}
    80003770:	60e2                	ld	ra,24(sp)
    80003772:	6442                	ld	s0,16(sp)
    80003774:	64a2                	ld	s1,8(sp)
    80003776:	6105                	addi	sp,sp,32
    80003778:	8082                	ret

000000008000377a <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000377a:	1101                	addi	sp,sp,-32
    8000377c:	ec06                	sd	ra,24(sp)
    8000377e:	e822                	sd	s0,16(sp)
    80003780:	e426                	sd	s1,8(sp)
    80003782:	e04a                	sd	s2,0(sp)
    80003784:	1000                	addi	s0,sp,32
    80003786:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003788:	00d5d59b          	srliw	a1,a1,0xd
    8000378c:	0001c797          	auipc	a5,0x1c
    80003790:	2f07a783          	lw	a5,752(a5) # 8001fa7c <sb+0x1c>
    80003794:	9dbd                	addw	a1,a1,a5
    80003796:	00000097          	auipc	ra,0x0
    8000379a:	d9e080e7          	jalr	-610(ra) # 80003534 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000379e:	0074f713          	andi	a4,s1,7
    800037a2:	4785                	li	a5,1
    800037a4:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800037a8:	14ce                	slli	s1,s1,0x33
    800037aa:	90d9                	srli	s1,s1,0x36
    800037ac:	00950733          	add	a4,a0,s1
    800037b0:	05874703          	lbu	a4,88(a4)
    800037b4:	00e7f6b3          	and	a3,a5,a4
    800037b8:	c69d                	beqz	a3,800037e6 <bfree+0x6c>
    800037ba:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800037bc:	94aa                	add	s1,s1,a0
    800037be:	fff7c793          	not	a5,a5
    800037c2:	8ff9                	and	a5,a5,a4
    800037c4:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800037c8:	00001097          	auipc	ra,0x1
    800037cc:	120080e7          	jalr	288(ra) # 800048e8 <log_write>
  brelse(bp);
    800037d0:	854a                	mv	a0,s2
    800037d2:	00000097          	auipc	ra,0x0
    800037d6:	e92080e7          	jalr	-366(ra) # 80003664 <brelse>
}
    800037da:	60e2                	ld	ra,24(sp)
    800037dc:	6442                	ld	s0,16(sp)
    800037de:	64a2                	ld	s1,8(sp)
    800037e0:	6902                	ld	s2,0(sp)
    800037e2:	6105                	addi	sp,sp,32
    800037e4:	8082                	ret
    panic("freeing free block");
    800037e6:	00005517          	auipc	a0,0x5
    800037ea:	eb250513          	addi	a0,a0,-334 # 80008698 <syscalls+0xf8>
    800037ee:	ffffd097          	auipc	ra,0xffffd
    800037f2:	110080e7          	jalr	272(ra) # 800008fe <panic>

00000000800037f6 <balloc>:
{
    800037f6:	711d                	addi	sp,sp,-96
    800037f8:	ec86                	sd	ra,88(sp)
    800037fa:	e8a2                	sd	s0,80(sp)
    800037fc:	e4a6                	sd	s1,72(sp)
    800037fe:	e0ca                	sd	s2,64(sp)
    80003800:	fc4e                	sd	s3,56(sp)
    80003802:	f852                	sd	s4,48(sp)
    80003804:	f456                	sd	s5,40(sp)
    80003806:	f05a                	sd	s6,32(sp)
    80003808:	ec5e                	sd	s7,24(sp)
    8000380a:	e862                	sd	s8,16(sp)
    8000380c:	e466                	sd	s9,8(sp)
    8000380e:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003810:	0001c797          	auipc	a5,0x1c
    80003814:	2547a783          	lw	a5,596(a5) # 8001fa64 <sb+0x4>
    80003818:	10078163          	beqz	a5,8000391a <balloc+0x124>
    8000381c:	8baa                	mv	s7,a0
    8000381e:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003820:	0001cb17          	auipc	s6,0x1c
    80003824:	240b0b13          	addi	s6,s6,576 # 8001fa60 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003828:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000382a:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000382c:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000382e:	6c89                	lui	s9,0x2
    80003830:	a061                	j	800038b8 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003832:	974a                	add	a4,a4,s2
    80003834:	8fd5                	or	a5,a5,a3
    80003836:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000383a:	854a                	mv	a0,s2
    8000383c:	00001097          	auipc	ra,0x1
    80003840:	0ac080e7          	jalr	172(ra) # 800048e8 <log_write>
        brelse(bp);
    80003844:	854a                	mv	a0,s2
    80003846:	00000097          	auipc	ra,0x0
    8000384a:	e1e080e7          	jalr	-482(ra) # 80003664 <brelse>
  bp = bread(dev, bno);
    8000384e:	85a6                	mv	a1,s1
    80003850:	855e                	mv	a0,s7
    80003852:	00000097          	auipc	ra,0x0
    80003856:	ce2080e7          	jalr	-798(ra) # 80003534 <bread>
    8000385a:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000385c:	40000613          	li	a2,1024
    80003860:	4581                	li	a1,0
    80003862:	05850513          	addi	a0,a0,88
    80003866:	ffffe097          	auipc	ra,0xffffe
    8000386a:	82c080e7          	jalr	-2004(ra) # 80001092 <memset>
  log_write(bp);
    8000386e:	854a                	mv	a0,s2
    80003870:	00001097          	auipc	ra,0x1
    80003874:	078080e7          	jalr	120(ra) # 800048e8 <log_write>
  brelse(bp);
    80003878:	854a                	mv	a0,s2
    8000387a:	00000097          	auipc	ra,0x0
    8000387e:	dea080e7          	jalr	-534(ra) # 80003664 <brelse>
}
    80003882:	8526                	mv	a0,s1
    80003884:	60e6                	ld	ra,88(sp)
    80003886:	6446                	ld	s0,80(sp)
    80003888:	64a6                	ld	s1,72(sp)
    8000388a:	6906                	ld	s2,64(sp)
    8000388c:	79e2                	ld	s3,56(sp)
    8000388e:	7a42                	ld	s4,48(sp)
    80003890:	7aa2                	ld	s5,40(sp)
    80003892:	7b02                	ld	s6,32(sp)
    80003894:	6be2                	ld	s7,24(sp)
    80003896:	6c42                	ld	s8,16(sp)
    80003898:	6ca2                	ld	s9,8(sp)
    8000389a:	6125                	addi	sp,sp,96
    8000389c:	8082                	ret
    brelse(bp);
    8000389e:	854a                	mv	a0,s2
    800038a0:	00000097          	auipc	ra,0x0
    800038a4:	dc4080e7          	jalr	-572(ra) # 80003664 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800038a8:	015c87bb          	addw	a5,s9,s5
    800038ac:	00078a9b          	sext.w	s5,a5
    800038b0:	004b2703          	lw	a4,4(s6)
    800038b4:	06eaf363          	bgeu	s5,a4,8000391a <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    800038b8:	41fad79b          	sraiw	a5,s5,0x1f
    800038bc:	0137d79b          	srliw	a5,a5,0x13
    800038c0:	015787bb          	addw	a5,a5,s5
    800038c4:	40d7d79b          	sraiw	a5,a5,0xd
    800038c8:	01cb2583          	lw	a1,28(s6)
    800038cc:	9dbd                	addw	a1,a1,a5
    800038ce:	855e                	mv	a0,s7
    800038d0:	00000097          	auipc	ra,0x0
    800038d4:	c64080e7          	jalr	-924(ra) # 80003534 <bread>
    800038d8:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038da:	004b2503          	lw	a0,4(s6)
    800038de:	000a849b          	sext.w	s1,s5
    800038e2:	8662                	mv	a2,s8
    800038e4:	faa4fde3          	bgeu	s1,a0,8000389e <balloc+0xa8>
      m = 1 << (bi % 8);
    800038e8:	41f6579b          	sraiw	a5,a2,0x1f
    800038ec:	01d7d69b          	srliw	a3,a5,0x1d
    800038f0:	00c6873b          	addw	a4,a3,a2
    800038f4:	00777793          	andi	a5,a4,7
    800038f8:	9f95                	subw	a5,a5,a3
    800038fa:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800038fe:	4037571b          	sraiw	a4,a4,0x3
    80003902:	00e906b3          	add	a3,s2,a4
    80003906:	0586c683          	lbu	a3,88(a3)
    8000390a:	00d7f5b3          	and	a1,a5,a3
    8000390e:	d195                	beqz	a1,80003832 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003910:	2605                	addiw	a2,a2,1
    80003912:	2485                	addiw	s1,s1,1
    80003914:	fd4618e3          	bne	a2,s4,800038e4 <balloc+0xee>
    80003918:	b759                	j	8000389e <balloc+0xa8>
  printf("balloc: out of blocks\n");
    8000391a:	00005517          	auipc	a0,0x5
    8000391e:	d9650513          	addi	a0,a0,-618 # 800086b0 <syscalls+0x110>
    80003922:	ffffd097          	auipc	ra,0xffffd
    80003926:	026080e7          	jalr	38(ra) # 80000948 <printf>
  return 0;
    8000392a:	4481                	li	s1,0
    8000392c:	bf99                	j	80003882 <balloc+0x8c>

000000008000392e <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    8000392e:	7179                	addi	sp,sp,-48
    80003930:	f406                	sd	ra,40(sp)
    80003932:	f022                	sd	s0,32(sp)
    80003934:	ec26                	sd	s1,24(sp)
    80003936:	e84a                	sd	s2,16(sp)
    80003938:	e44e                	sd	s3,8(sp)
    8000393a:	e052                	sd	s4,0(sp)
    8000393c:	1800                	addi	s0,sp,48
    8000393e:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003940:	47ad                	li	a5,11
    80003942:	02b7e763          	bltu	a5,a1,80003970 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    80003946:	02059493          	slli	s1,a1,0x20
    8000394a:	9081                	srli	s1,s1,0x20
    8000394c:	048a                	slli	s1,s1,0x2
    8000394e:	94aa                	add	s1,s1,a0
    80003950:	0504a903          	lw	s2,80(s1)
    80003954:	06091e63          	bnez	s2,800039d0 <bmap+0xa2>
      addr = balloc(ip->dev);
    80003958:	4108                	lw	a0,0(a0)
    8000395a:	00000097          	auipc	ra,0x0
    8000395e:	e9c080e7          	jalr	-356(ra) # 800037f6 <balloc>
    80003962:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003966:	06090563          	beqz	s2,800039d0 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    8000396a:	0524a823          	sw	s2,80(s1)
    8000396e:	a08d                	j	800039d0 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003970:	ff45849b          	addiw	s1,a1,-12
    80003974:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003978:	0ff00793          	li	a5,255
    8000397c:	08e7e563          	bltu	a5,a4,80003a06 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003980:	08052903          	lw	s2,128(a0)
    80003984:	00091d63          	bnez	s2,8000399e <bmap+0x70>
      addr = balloc(ip->dev);
    80003988:	4108                	lw	a0,0(a0)
    8000398a:	00000097          	auipc	ra,0x0
    8000398e:	e6c080e7          	jalr	-404(ra) # 800037f6 <balloc>
    80003992:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003996:	02090d63          	beqz	s2,800039d0 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    8000399a:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    8000399e:	85ca                	mv	a1,s2
    800039a0:	0009a503          	lw	a0,0(s3)
    800039a4:	00000097          	auipc	ra,0x0
    800039a8:	b90080e7          	jalr	-1136(ra) # 80003534 <bread>
    800039ac:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800039ae:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800039b2:	02049593          	slli	a1,s1,0x20
    800039b6:	9181                	srli	a1,a1,0x20
    800039b8:	058a                	slli	a1,a1,0x2
    800039ba:	00b784b3          	add	s1,a5,a1
    800039be:	0004a903          	lw	s2,0(s1)
    800039c2:	02090063          	beqz	s2,800039e2 <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800039c6:	8552                	mv	a0,s4
    800039c8:	00000097          	auipc	ra,0x0
    800039cc:	c9c080e7          	jalr	-868(ra) # 80003664 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800039d0:	854a                	mv	a0,s2
    800039d2:	70a2                	ld	ra,40(sp)
    800039d4:	7402                	ld	s0,32(sp)
    800039d6:	64e2                	ld	s1,24(sp)
    800039d8:	6942                	ld	s2,16(sp)
    800039da:	69a2                	ld	s3,8(sp)
    800039dc:	6a02                	ld	s4,0(sp)
    800039de:	6145                	addi	sp,sp,48
    800039e0:	8082                	ret
      addr = balloc(ip->dev);
    800039e2:	0009a503          	lw	a0,0(s3)
    800039e6:	00000097          	auipc	ra,0x0
    800039ea:	e10080e7          	jalr	-496(ra) # 800037f6 <balloc>
    800039ee:	0005091b          	sext.w	s2,a0
      if(addr){
    800039f2:	fc090ae3          	beqz	s2,800039c6 <bmap+0x98>
        a[bn] = addr;
    800039f6:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800039fa:	8552                	mv	a0,s4
    800039fc:	00001097          	auipc	ra,0x1
    80003a00:	eec080e7          	jalr	-276(ra) # 800048e8 <log_write>
    80003a04:	b7c9                	j	800039c6 <bmap+0x98>
  panic("bmap: out of range");
    80003a06:	00005517          	auipc	a0,0x5
    80003a0a:	cc250513          	addi	a0,a0,-830 # 800086c8 <syscalls+0x128>
    80003a0e:	ffffd097          	auipc	ra,0xffffd
    80003a12:	ef0080e7          	jalr	-272(ra) # 800008fe <panic>

0000000080003a16 <iget>:
{
    80003a16:	7179                	addi	sp,sp,-48
    80003a18:	f406                	sd	ra,40(sp)
    80003a1a:	f022                	sd	s0,32(sp)
    80003a1c:	ec26                	sd	s1,24(sp)
    80003a1e:	e84a                	sd	s2,16(sp)
    80003a20:	e44e                	sd	s3,8(sp)
    80003a22:	e052                	sd	s4,0(sp)
    80003a24:	1800                	addi	s0,sp,48
    80003a26:	89aa                	mv	s3,a0
    80003a28:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003a2a:	0001c517          	auipc	a0,0x1c
    80003a2e:	05650513          	addi	a0,a0,86 # 8001fa80 <itable>
    80003a32:	ffffd097          	auipc	ra,0xffffd
    80003a36:	564080e7          	jalr	1380(ra) # 80000f96 <acquire>
  empty = 0;
    80003a3a:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003a3c:	0001c497          	auipc	s1,0x1c
    80003a40:	05c48493          	addi	s1,s1,92 # 8001fa98 <itable+0x18>
    80003a44:	0001e697          	auipc	a3,0x1e
    80003a48:	ae468693          	addi	a3,a3,-1308 # 80021528 <log>
    80003a4c:	a039                	j	80003a5a <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a4e:	02090b63          	beqz	s2,80003a84 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003a52:	08848493          	addi	s1,s1,136
    80003a56:	02d48a63          	beq	s1,a3,80003a8a <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003a5a:	449c                	lw	a5,8(s1)
    80003a5c:	fef059e3          	blez	a5,80003a4e <iget+0x38>
    80003a60:	4098                	lw	a4,0(s1)
    80003a62:	ff3716e3          	bne	a4,s3,80003a4e <iget+0x38>
    80003a66:	40d8                	lw	a4,4(s1)
    80003a68:	ff4713e3          	bne	a4,s4,80003a4e <iget+0x38>
      ip->ref++;
    80003a6c:	2785                	addiw	a5,a5,1
    80003a6e:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003a70:	0001c517          	auipc	a0,0x1c
    80003a74:	01050513          	addi	a0,a0,16 # 8001fa80 <itable>
    80003a78:	ffffd097          	auipc	ra,0xffffd
    80003a7c:	5d2080e7          	jalr	1490(ra) # 8000104a <release>
      return ip;
    80003a80:	8926                	mv	s2,s1
    80003a82:	a03d                	j	80003ab0 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a84:	f7f9                	bnez	a5,80003a52 <iget+0x3c>
    80003a86:	8926                	mv	s2,s1
    80003a88:	b7e9                	j	80003a52 <iget+0x3c>
  if(empty == 0)
    80003a8a:	02090c63          	beqz	s2,80003ac2 <iget+0xac>
  ip->dev = dev;
    80003a8e:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003a92:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003a96:	4785                	li	a5,1
    80003a98:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003a9c:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003aa0:	0001c517          	auipc	a0,0x1c
    80003aa4:	fe050513          	addi	a0,a0,-32 # 8001fa80 <itable>
    80003aa8:	ffffd097          	auipc	ra,0xffffd
    80003aac:	5a2080e7          	jalr	1442(ra) # 8000104a <release>
}
    80003ab0:	854a                	mv	a0,s2
    80003ab2:	70a2                	ld	ra,40(sp)
    80003ab4:	7402                	ld	s0,32(sp)
    80003ab6:	64e2                	ld	s1,24(sp)
    80003ab8:	6942                	ld	s2,16(sp)
    80003aba:	69a2                	ld	s3,8(sp)
    80003abc:	6a02                	ld	s4,0(sp)
    80003abe:	6145                	addi	sp,sp,48
    80003ac0:	8082                	ret
    panic("iget: no inodes");
    80003ac2:	00005517          	auipc	a0,0x5
    80003ac6:	c1e50513          	addi	a0,a0,-994 # 800086e0 <syscalls+0x140>
    80003aca:	ffffd097          	auipc	ra,0xffffd
    80003ace:	e34080e7          	jalr	-460(ra) # 800008fe <panic>

0000000080003ad2 <fsinit>:
fsinit(int dev) {
    80003ad2:	7179                	addi	sp,sp,-48
    80003ad4:	f406                	sd	ra,40(sp)
    80003ad6:	f022                	sd	s0,32(sp)
    80003ad8:	ec26                	sd	s1,24(sp)
    80003ada:	e84a                	sd	s2,16(sp)
    80003adc:	e44e                	sd	s3,8(sp)
    80003ade:	1800                	addi	s0,sp,48
    80003ae0:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003ae2:	4585                	li	a1,1
    80003ae4:	00000097          	auipc	ra,0x0
    80003ae8:	a50080e7          	jalr	-1456(ra) # 80003534 <bread>
    80003aec:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003aee:	0001c997          	auipc	s3,0x1c
    80003af2:	f7298993          	addi	s3,s3,-142 # 8001fa60 <sb>
    80003af6:	02000613          	li	a2,32
    80003afa:	05850593          	addi	a1,a0,88
    80003afe:	854e                	mv	a0,s3
    80003b00:	ffffd097          	auipc	ra,0xffffd
    80003b04:	5ee080e7          	jalr	1518(ra) # 800010ee <memmove>
  brelse(bp);
    80003b08:	8526                	mv	a0,s1
    80003b0a:	00000097          	auipc	ra,0x0
    80003b0e:	b5a080e7          	jalr	-1190(ra) # 80003664 <brelse>
  if(sb.magic != FSMAGIC)
    80003b12:	0009a703          	lw	a4,0(s3)
    80003b16:	102037b7          	lui	a5,0x10203
    80003b1a:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003b1e:	02f71263          	bne	a4,a5,80003b42 <fsinit+0x70>
  initlog(dev, &sb);
    80003b22:	0001c597          	auipc	a1,0x1c
    80003b26:	f3e58593          	addi	a1,a1,-194 # 8001fa60 <sb>
    80003b2a:	854a                	mv	a0,s2
    80003b2c:	00001097          	auipc	ra,0x1
    80003b30:	b40080e7          	jalr	-1216(ra) # 8000466c <initlog>
}
    80003b34:	70a2                	ld	ra,40(sp)
    80003b36:	7402                	ld	s0,32(sp)
    80003b38:	64e2                	ld	s1,24(sp)
    80003b3a:	6942                	ld	s2,16(sp)
    80003b3c:	69a2                	ld	s3,8(sp)
    80003b3e:	6145                	addi	sp,sp,48
    80003b40:	8082                	ret
    panic("invalid file system");
    80003b42:	00005517          	auipc	a0,0x5
    80003b46:	bae50513          	addi	a0,a0,-1106 # 800086f0 <syscalls+0x150>
    80003b4a:	ffffd097          	auipc	ra,0xffffd
    80003b4e:	db4080e7          	jalr	-588(ra) # 800008fe <panic>

0000000080003b52 <iinit>:
{
    80003b52:	7179                	addi	sp,sp,-48
    80003b54:	f406                	sd	ra,40(sp)
    80003b56:	f022                	sd	s0,32(sp)
    80003b58:	ec26                	sd	s1,24(sp)
    80003b5a:	e84a                	sd	s2,16(sp)
    80003b5c:	e44e                	sd	s3,8(sp)
    80003b5e:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003b60:	00005597          	auipc	a1,0x5
    80003b64:	ba858593          	addi	a1,a1,-1112 # 80008708 <syscalls+0x168>
    80003b68:	0001c517          	auipc	a0,0x1c
    80003b6c:	f1850513          	addi	a0,a0,-232 # 8001fa80 <itable>
    80003b70:	ffffd097          	auipc	ra,0xffffd
    80003b74:	396080e7          	jalr	918(ra) # 80000f06 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003b78:	0001c497          	auipc	s1,0x1c
    80003b7c:	f3048493          	addi	s1,s1,-208 # 8001faa8 <itable+0x28>
    80003b80:	0001e997          	auipc	s3,0x1e
    80003b84:	9b898993          	addi	s3,s3,-1608 # 80021538 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003b88:	00005917          	auipc	s2,0x5
    80003b8c:	b8890913          	addi	s2,s2,-1144 # 80008710 <syscalls+0x170>
    80003b90:	85ca                	mv	a1,s2
    80003b92:	8526                	mv	a0,s1
    80003b94:	00001097          	auipc	ra,0x1
    80003b98:	e3a080e7          	jalr	-454(ra) # 800049ce <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003b9c:	08848493          	addi	s1,s1,136
    80003ba0:	ff3498e3          	bne	s1,s3,80003b90 <iinit+0x3e>
}
    80003ba4:	70a2                	ld	ra,40(sp)
    80003ba6:	7402                	ld	s0,32(sp)
    80003ba8:	64e2                	ld	s1,24(sp)
    80003baa:	6942                	ld	s2,16(sp)
    80003bac:	69a2                	ld	s3,8(sp)
    80003bae:	6145                	addi	sp,sp,48
    80003bb0:	8082                	ret

0000000080003bb2 <ialloc>:
{
    80003bb2:	715d                	addi	sp,sp,-80
    80003bb4:	e486                	sd	ra,72(sp)
    80003bb6:	e0a2                	sd	s0,64(sp)
    80003bb8:	fc26                	sd	s1,56(sp)
    80003bba:	f84a                	sd	s2,48(sp)
    80003bbc:	f44e                	sd	s3,40(sp)
    80003bbe:	f052                	sd	s4,32(sp)
    80003bc0:	ec56                	sd	s5,24(sp)
    80003bc2:	e85a                	sd	s6,16(sp)
    80003bc4:	e45e                	sd	s7,8(sp)
    80003bc6:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003bc8:	0001c717          	auipc	a4,0x1c
    80003bcc:	ea472703          	lw	a4,-348(a4) # 8001fa6c <sb+0xc>
    80003bd0:	4785                	li	a5,1
    80003bd2:	04e7fa63          	bgeu	a5,a4,80003c26 <ialloc+0x74>
    80003bd6:	8aaa                	mv	s5,a0
    80003bd8:	8bae                	mv	s7,a1
    80003bda:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003bdc:	0001ca17          	auipc	s4,0x1c
    80003be0:	e84a0a13          	addi	s4,s4,-380 # 8001fa60 <sb>
    80003be4:	00048b1b          	sext.w	s6,s1
    80003be8:	0044d793          	srli	a5,s1,0x4
    80003bec:	018a2583          	lw	a1,24(s4)
    80003bf0:	9dbd                	addw	a1,a1,a5
    80003bf2:	8556                	mv	a0,s5
    80003bf4:	00000097          	auipc	ra,0x0
    80003bf8:	940080e7          	jalr	-1728(ra) # 80003534 <bread>
    80003bfc:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003bfe:	05850993          	addi	s3,a0,88
    80003c02:	00f4f793          	andi	a5,s1,15
    80003c06:	079a                	slli	a5,a5,0x6
    80003c08:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003c0a:	00099783          	lh	a5,0(s3)
    80003c0e:	c3a1                	beqz	a5,80003c4e <ialloc+0x9c>
    brelse(bp);
    80003c10:	00000097          	auipc	ra,0x0
    80003c14:	a54080e7          	jalr	-1452(ra) # 80003664 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003c18:	0485                	addi	s1,s1,1
    80003c1a:	00ca2703          	lw	a4,12(s4)
    80003c1e:	0004879b          	sext.w	a5,s1
    80003c22:	fce7e1e3          	bltu	a5,a4,80003be4 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003c26:	00005517          	auipc	a0,0x5
    80003c2a:	af250513          	addi	a0,a0,-1294 # 80008718 <syscalls+0x178>
    80003c2e:	ffffd097          	auipc	ra,0xffffd
    80003c32:	d1a080e7          	jalr	-742(ra) # 80000948 <printf>
  return 0;
    80003c36:	4501                	li	a0,0
}
    80003c38:	60a6                	ld	ra,72(sp)
    80003c3a:	6406                	ld	s0,64(sp)
    80003c3c:	74e2                	ld	s1,56(sp)
    80003c3e:	7942                	ld	s2,48(sp)
    80003c40:	79a2                	ld	s3,40(sp)
    80003c42:	7a02                	ld	s4,32(sp)
    80003c44:	6ae2                	ld	s5,24(sp)
    80003c46:	6b42                	ld	s6,16(sp)
    80003c48:	6ba2                	ld	s7,8(sp)
    80003c4a:	6161                	addi	sp,sp,80
    80003c4c:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003c4e:	04000613          	li	a2,64
    80003c52:	4581                	li	a1,0
    80003c54:	854e                	mv	a0,s3
    80003c56:	ffffd097          	auipc	ra,0xffffd
    80003c5a:	43c080e7          	jalr	1084(ra) # 80001092 <memset>
      dip->type = type;
    80003c5e:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003c62:	854a                	mv	a0,s2
    80003c64:	00001097          	auipc	ra,0x1
    80003c68:	c84080e7          	jalr	-892(ra) # 800048e8 <log_write>
      brelse(bp);
    80003c6c:	854a                	mv	a0,s2
    80003c6e:	00000097          	auipc	ra,0x0
    80003c72:	9f6080e7          	jalr	-1546(ra) # 80003664 <brelse>
      return iget(dev, inum);
    80003c76:	85da                	mv	a1,s6
    80003c78:	8556                	mv	a0,s5
    80003c7a:	00000097          	auipc	ra,0x0
    80003c7e:	d9c080e7          	jalr	-612(ra) # 80003a16 <iget>
    80003c82:	bf5d                	j	80003c38 <ialloc+0x86>

0000000080003c84 <iupdate>:
{
    80003c84:	1101                	addi	sp,sp,-32
    80003c86:	ec06                	sd	ra,24(sp)
    80003c88:	e822                	sd	s0,16(sp)
    80003c8a:	e426                	sd	s1,8(sp)
    80003c8c:	e04a                	sd	s2,0(sp)
    80003c8e:	1000                	addi	s0,sp,32
    80003c90:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c92:	415c                	lw	a5,4(a0)
    80003c94:	0047d79b          	srliw	a5,a5,0x4
    80003c98:	0001c597          	auipc	a1,0x1c
    80003c9c:	de05a583          	lw	a1,-544(a1) # 8001fa78 <sb+0x18>
    80003ca0:	9dbd                	addw	a1,a1,a5
    80003ca2:	4108                	lw	a0,0(a0)
    80003ca4:	00000097          	auipc	ra,0x0
    80003ca8:	890080e7          	jalr	-1904(ra) # 80003534 <bread>
    80003cac:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003cae:	05850793          	addi	a5,a0,88
    80003cb2:	40c8                	lw	a0,4(s1)
    80003cb4:	893d                	andi	a0,a0,15
    80003cb6:	051a                	slli	a0,a0,0x6
    80003cb8:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003cba:	04449703          	lh	a4,68(s1)
    80003cbe:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003cc2:	04649703          	lh	a4,70(s1)
    80003cc6:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003cca:	04849703          	lh	a4,72(s1)
    80003cce:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003cd2:	04a49703          	lh	a4,74(s1)
    80003cd6:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003cda:	44f8                	lw	a4,76(s1)
    80003cdc:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003cde:	03400613          	li	a2,52
    80003ce2:	05048593          	addi	a1,s1,80
    80003ce6:	0531                	addi	a0,a0,12
    80003ce8:	ffffd097          	auipc	ra,0xffffd
    80003cec:	406080e7          	jalr	1030(ra) # 800010ee <memmove>
  log_write(bp);
    80003cf0:	854a                	mv	a0,s2
    80003cf2:	00001097          	auipc	ra,0x1
    80003cf6:	bf6080e7          	jalr	-1034(ra) # 800048e8 <log_write>
  brelse(bp);
    80003cfa:	854a                	mv	a0,s2
    80003cfc:	00000097          	auipc	ra,0x0
    80003d00:	968080e7          	jalr	-1688(ra) # 80003664 <brelse>
}
    80003d04:	60e2                	ld	ra,24(sp)
    80003d06:	6442                	ld	s0,16(sp)
    80003d08:	64a2                	ld	s1,8(sp)
    80003d0a:	6902                	ld	s2,0(sp)
    80003d0c:	6105                	addi	sp,sp,32
    80003d0e:	8082                	ret

0000000080003d10 <idup>:
{
    80003d10:	1101                	addi	sp,sp,-32
    80003d12:	ec06                	sd	ra,24(sp)
    80003d14:	e822                	sd	s0,16(sp)
    80003d16:	e426                	sd	s1,8(sp)
    80003d18:	1000                	addi	s0,sp,32
    80003d1a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003d1c:	0001c517          	auipc	a0,0x1c
    80003d20:	d6450513          	addi	a0,a0,-668 # 8001fa80 <itable>
    80003d24:	ffffd097          	auipc	ra,0xffffd
    80003d28:	272080e7          	jalr	626(ra) # 80000f96 <acquire>
  ip->ref++;
    80003d2c:	449c                	lw	a5,8(s1)
    80003d2e:	2785                	addiw	a5,a5,1
    80003d30:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003d32:	0001c517          	auipc	a0,0x1c
    80003d36:	d4e50513          	addi	a0,a0,-690 # 8001fa80 <itable>
    80003d3a:	ffffd097          	auipc	ra,0xffffd
    80003d3e:	310080e7          	jalr	784(ra) # 8000104a <release>
}
    80003d42:	8526                	mv	a0,s1
    80003d44:	60e2                	ld	ra,24(sp)
    80003d46:	6442                	ld	s0,16(sp)
    80003d48:	64a2                	ld	s1,8(sp)
    80003d4a:	6105                	addi	sp,sp,32
    80003d4c:	8082                	ret

0000000080003d4e <ilock>:
{
    80003d4e:	1101                	addi	sp,sp,-32
    80003d50:	ec06                	sd	ra,24(sp)
    80003d52:	e822                	sd	s0,16(sp)
    80003d54:	e426                	sd	s1,8(sp)
    80003d56:	e04a                	sd	s2,0(sp)
    80003d58:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003d5a:	c115                	beqz	a0,80003d7e <ilock+0x30>
    80003d5c:	84aa                	mv	s1,a0
    80003d5e:	451c                	lw	a5,8(a0)
    80003d60:	00f05f63          	blez	a5,80003d7e <ilock+0x30>
  acquiresleep(&ip->lock);
    80003d64:	0541                	addi	a0,a0,16
    80003d66:	00001097          	auipc	ra,0x1
    80003d6a:	ca2080e7          	jalr	-862(ra) # 80004a08 <acquiresleep>
  if(ip->valid == 0){
    80003d6e:	40bc                	lw	a5,64(s1)
    80003d70:	cf99                	beqz	a5,80003d8e <ilock+0x40>
}
    80003d72:	60e2                	ld	ra,24(sp)
    80003d74:	6442                	ld	s0,16(sp)
    80003d76:	64a2                	ld	s1,8(sp)
    80003d78:	6902                	ld	s2,0(sp)
    80003d7a:	6105                	addi	sp,sp,32
    80003d7c:	8082                	ret
    panic("ilock");
    80003d7e:	00005517          	auipc	a0,0x5
    80003d82:	9b250513          	addi	a0,a0,-1614 # 80008730 <syscalls+0x190>
    80003d86:	ffffd097          	auipc	ra,0xffffd
    80003d8a:	b78080e7          	jalr	-1160(ra) # 800008fe <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d8e:	40dc                	lw	a5,4(s1)
    80003d90:	0047d79b          	srliw	a5,a5,0x4
    80003d94:	0001c597          	auipc	a1,0x1c
    80003d98:	ce45a583          	lw	a1,-796(a1) # 8001fa78 <sb+0x18>
    80003d9c:	9dbd                	addw	a1,a1,a5
    80003d9e:	4088                	lw	a0,0(s1)
    80003da0:	fffff097          	auipc	ra,0xfffff
    80003da4:	794080e7          	jalr	1940(ra) # 80003534 <bread>
    80003da8:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003daa:	05850593          	addi	a1,a0,88
    80003dae:	40dc                	lw	a5,4(s1)
    80003db0:	8bbd                	andi	a5,a5,15
    80003db2:	079a                	slli	a5,a5,0x6
    80003db4:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003db6:	00059783          	lh	a5,0(a1)
    80003dba:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003dbe:	00259783          	lh	a5,2(a1)
    80003dc2:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003dc6:	00459783          	lh	a5,4(a1)
    80003dca:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003dce:	00659783          	lh	a5,6(a1)
    80003dd2:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003dd6:	459c                	lw	a5,8(a1)
    80003dd8:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003dda:	03400613          	li	a2,52
    80003dde:	05b1                	addi	a1,a1,12
    80003de0:	05048513          	addi	a0,s1,80
    80003de4:	ffffd097          	auipc	ra,0xffffd
    80003de8:	30a080e7          	jalr	778(ra) # 800010ee <memmove>
    brelse(bp);
    80003dec:	854a                	mv	a0,s2
    80003dee:	00000097          	auipc	ra,0x0
    80003df2:	876080e7          	jalr	-1930(ra) # 80003664 <brelse>
    ip->valid = 1;
    80003df6:	4785                	li	a5,1
    80003df8:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003dfa:	04449783          	lh	a5,68(s1)
    80003dfe:	fbb5                	bnez	a5,80003d72 <ilock+0x24>
      panic("ilock: no type");
    80003e00:	00005517          	auipc	a0,0x5
    80003e04:	93850513          	addi	a0,a0,-1736 # 80008738 <syscalls+0x198>
    80003e08:	ffffd097          	auipc	ra,0xffffd
    80003e0c:	af6080e7          	jalr	-1290(ra) # 800008fe <panic>

0000000080003e10 <iunlock>:
{
    80003e10:	1101                	addi	sp,sp,-32
    80003e12:	ec06                	sd	ra,24(sp)
    80003e14:	e822                	sd	s0,16(sp)
    80003e16:	e426                	sd	s1,8(sp)
    80003e18:	e04a                	sd	s2,0(sp)
    80003e1a:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003e1c:	c905                	beqz	a0,80003e4c <iunlock+0x3c>
    80003e1e:	84aa                	mv	s1,a0
    80003e20:	01050913          	addi	s2,a0,16
    80003e24:	854a                	mv	a0,s2
    80003e26:	00001097          	auipc	ra,0x1
    80003e2a:	c7c080e7          	jalr	-900(ra) # 80004aa2 <holdingsleep>
    80003e2e:	cd19                	beqz	a0,80003e4c <iunlock+0x3c>
    80003e30:	449c                	lw	a5,8(s1)
    80003e32:	00f05d63          	blez	a5,80003e4c <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003e36:	854a                	mv	a0,s2
    80003e38:	00001097          	auipc	ra,0x1
    80003e3c:	c26080e7          	jalr	-986(ra) # 80004a5e <releasesleep>
}
    80003e40:	60e2                	ld	ra,24(sp)
    80003e42:	6442                	ld	s0,16(sp)
    80003e44:	64a2                	ld	s1,8(sp)
    80003e46:	6902                	ld	s2,0(sp)
    80003e48:	6105                	addi	sp,sp,32
    80003e4a:	8082                	ret
    panic("iunlock");
    80003e4c:	00005517          	auipc	a0,0x5
    80003e50:	8fc50513          	addi	a0,a0,-1796 # 80008748 <syscalls+0x1a8>
    80003e54:	ffffd097          	auipc	ra,0xffffd
    80003e58:	aaa080e7          	jalr	-1366(ra) # 800008fe <panic>

0000000080003e5c <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003e5c:	7179                	addi	sp,sp,-48
    80003e5e:	f406                	sd	ra,40(sp)
    80003e60:	f022                	sd	s0,32(sp)
    80003e62:	ec26                	sd	s1,24(sp)
    80003e64:	e84a                	sd	s2,16(sp)
    80003e66:	e44e                	sd	s3,8(sp)
    80003e68:	e052                	sd	s4,0(sp)
    80003e6a:	1800                	addi	s0,sp,48
    80003e6c:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003e6e:	05050493          	addi	s1,a0,80
    80003e72:	08050913          	addi	s2,a0,128
    80003e76:	a021                	j	80003e7e <itrunc+0x22>
    80003e78:	0491                	addi	s1,s1,4
    80003e7a:	01248d63          	beq	s1,s2,80003e94 <itrunc+0x38>
    if(ip->addrs[i]){
    80003e7e:	408c                	lw	a1,0(s1)
    80003e80:	dde5                	beqz	a1,80003e78 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003e82:	0009a503          	lw	a0,0(s3)
    80003e86:	00000097          	auipc	ra,0x0
    80003e8a:	8f4080e7          	jalr	-1804(ra) # 8000377a <bfree>
      ip->addrs[i] = 0;
    80003e8e:	0004a023          	sw	zero,0(s1)
    80003e92:	b7dd                	j	80003e78 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003e94:	0809a583          	lw	a1,128(s3)
    80003e98:	e185                	bnez	a1,80003eb8 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003e9a:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003e9e:	854e                	mv	a0,s3
    80003ea0:	00000097          	auipc	ra,0x0
    80003ea4:	de4080e7          	jalr	-540(ra) # 80003c84 <iupdate>
}
    80003ea8:	70a2                	ld	ra,40(sp)
    80003eaa:	7402                	ld	s0,32(sp)
    80003eac:	64e2                	ld	s1,24(sp)
    80003eae:	6942                	ld	s2,16(sp)
    80003eb0:	69a2                	ld	s3,8(sp)
    80003eb2:	6a02                	ld	s4,0(sp)
    80003eb4:	6145                	addi	sp,sp,48
    80003eb6:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003eb8:	0009a503          	lw	a0,0(s3)
    80003ebc:	fffff097          	auipc	ra,0xfffff
    80003ec0:	678080e7          	jalr	1656(ra) # 80003534 <bread>
    80003ec4:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003ec6:	05850493          	addi	s1,a0,88
    80003eca:	45850913          	addi	s2,a0,1112
    80003ece:	a021                	j	80003ed6 <itrunc+0x7a>
    80003ed0:	0491                	addi	s1,s1,4
    80003ed2:	01248b63          	beq	s1,s2,80003ee8 <itrunc+0x8c>
      if(a[j])
    80003ed6:	408c                	lw	a1,0(s1)
    80003ed8:	dde5                	beqz	a1,80003ed0 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003eda:	0009a503          	lw	a0,0(s3)
    80003ede:	00000097          	auipc	ra,0x0
    80003ee2:	89c080e7          	jalr	-1892(ra) # 8000377a <bfree>
    80003ee6:	b7ed                	j	80003ed0 <itrunc+0x74>
    brelse(bp);
    80003ee8:	8552                	mv	a0,s4
    80003eea:	fffff097          	auipc	ra,0xfffff
    80003eee:	77a080e7          	jalr	1914(ra) # 80003664 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003ef2:	0809a583          	lw	a1,128(s3)
    80003ef6:	0009a503          	lw	a0,0(s3)
    80003efa:	00000097          	auipc	ra,0x0
    80003efe:	880080e7          	jalr	-1920(ra) # 8000377a <bfree>
    ip->addrs[NDIRECT] = 0;
    80003f02:	0809a023          	sw	zero,128(s3)
    80003f06:	bf51                	j	80003e9a <itrunc+0x3e>

0000000080003f08 <iput>:
{
    80003f08:	1101                	addi	sp,sp,-32
    80003f0a:	ec06                	sd	ra,24(sp)
    80003f0c:	e822                	sd	s0,16(sp)
    80003f0e:	e426                	sd	s1,8(sp)
    80003f10:	e04a                	sd	s2,0(sp)
    80003f12:	1000                	addi	s0,sp,32
    80003f14:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003f16:	0001c517          	auipc	a0,0x1c
    80003f1a:	b6a50513          	addi	a0,a0,-1174 # 8001fa80 <itable>
    80003f1e:	ffffd097          	auipc	ra,0xffffd
    80003f22:	078080e7          	jalr	120(ra) # 80000f96 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003f26:	4498                	lw	a4,8(s1)
    80003f28:	4785                	li	a5,1
    80003f2a:	02f70363          	beq	a4,a5,80003f50 <iput+0x48>
  ip->ref--;
    80003f2e:	449c                	lw	a5,8(s1)
    80003f30:	37fd                	addiw	a5,a5,-1
    80003f32:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003f34:	0001c517          	auipc	a0,0x1c
    80003f38:	b4c50513          	addi	a0,a0,-1204 # 8001fa80 <itable>
    80003f3c:	ffffd097          	auipc	ra,0xffffd
    80003f40:	10e080e7          	jalr	270(ra) # 8000104a <release>
}
    80003f44:	60e2                	ld	ra,24(sp)
    80003f46:	6442                	ld	s0,16(sp)
    80003f48:	64a2                	ld	s1,8(sp)
    80003f4a:	6902                	ld	s2,0(sp)
    80003f4c:	6105                	addi	sp,sp,32
    80003f4e:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003f50:	40bc                	lw	a5,64(s1)
    80003f52:	dff1                	beqz	a5,80003f2e <iput+0x26>
    80003f54:	04a49783          	lh	a5,74(s1)
    80003f58:	fbf9                	bnez	a5,80003f2e <iput+0x26>
    acquiresleep(&ip->lock);
    80003f5a:	01048913          	addi	s2,s1,16
    80003f5e:	854a                	mv	a0,s2
    80003f60:	00001097          	auipc	ra,0x1
    80003f64:	aa8080e7          	jalr	-1368(ra) # 80004a08 <acquiresleep>
    release(&itable.lock);
    80003f68:	0001c517          	auipc	a0,0x1c
    80003f6c:	b1850513          	addi	a0,a0,-1256 # 8001fa80 <itable>
    80003f70:	ffffd097          	auipc	ra,0xffffd
    80003f74:	0da080e7          	jalr	218(ra) # 8000104a <release>
    itrunc(ip);
    80003f78:	8526                	mv	a0,s1
    80003f7a:	00000097          	auipc	ra,0x0
    80003f7e:	ee2080e7          	jalr	-286(ra) # 80003e5c <itrunc>
    ip->type = 0;
    80003f82:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003f86:	8526                	mv	a0,s1
    80003f88:	00000097          	auipc	ra,0x0
    80003f8c:	cfc080e7          	jalr	-772(ra) # 80003c84 <iupdate>
    ip->valid = 0;
    80003f90:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003f94:	854a                	mv	a0,s2
    80003f96:	00001097          	auipc	ra,0x1
    80003f9a:	ac8080e7          	jalr	-1336(ra) # 80004a5e <releasesleep>
    acquire(&itable.lock);
    80003f9e:	0001c517          	auipc	a0,0x1c
    80003fa2:	ae250513          	addi	a0,a0,-1310 # 8001fa80 <itable>
    80003fa6:	ffffd097          	auipc	ra,0xffffd
    80003faa:	ff0080e7          	jalr	-16(ra) # 80000f96 <acquire>
    80003fae:	b741                	j	80003f2e <iput+0x26>

0000000080003fb0 <iunlockput>:
{
    80003fb0:	1101                	addi	sp,sp,-32
    80003fb2:	ec06                	sd	ra,24(sp)
    80003fb4:	e822                	sd	s0,16(sp)
    80003fb6:	e426                	sd	s1,8(sp)
    80003fb8:	1000                	addi	s0,sp,32
    80003fba:	84aa                	mv	s1,a0
  iunlock(ip);
    80003fbc:	00000097          	auipc	ra,0x0
    80003fc0:	e54080e7          	jalr	-428(ra) # 80003e10 <iunlock>
  iput(ip);
    80003fc4:	8526                	mv	a0,s1
    80003fc6:	00000097          	auipc	ra,0x0
    80003fca:	f42080e7          	jalr	-190(ra) # 80003f08 <iput>
}
    80003fce:	60e2                	ld	ra,24(sp)
    80003fd0:	6442                	ld	s0,16(sp)
    80003fd2:	64a2                	ld	s1,8(sp)
    80003fd4:	6105                	addi	sp,sp,32
    80003fd6:	8082                	ret

0000000080003fd8 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003fd8:	1141                	addi	sp,sp,-16
    80003fda:	e422                	sd	s0,8(sp)
    80003fdc:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003fde:	411c                	lw	a5,0(a0)
    80003fe0:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003fe2:	415c                	lw	a5,4(a0)
    80003fe4:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003fe6:	04451783          	lh	a5,68(a0)
    80003fea:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003fee:	04a51783          	lh	a5,74(a0)
    80003ff2:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003ff6:	04c56783          	lwu	a5,76(a0)
    80003ffa:	e99c                	sd	a5,16(a1)
}
    80003ffc:	6422                	ld	s0,8(sp)
    80003ffe:	0141                	addi	sp,sp,16
    80004000:	8082                	ret

0000000080004002 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004002:	457c                	lw	a5,76(a0)
    80004004:	0ed7e963          	bltu	a5,a3,800040f6 <readi+0xf4>
{
    80004008:	7159                	addi	sp,sp,-112
    8000400a:	f486                	sd	ra,104(sp)
    8000400c:	f0a2                	sd	s0,96(sp)
    8000400e:	eca6                	sd	s1,88(sp)
    80004010:	e8ca                	sd	s2,80(sp)
    80004012:	e4ce                	sd	s3,72(sp)
    80004014:	e0d2                	sd	s4,64(sp)
    80004016:	fc56                	sd	s5,56(sp)
    80004018:	f85a                	sd	s6,48(sp)
    8000401a:	f45e                	sd	s7,40(sp)
    8000401c:	f062                	sd	s8,32(sp)
    8000401e:	ec66                	sd	s9,24(sp)
    80004020:	e86a                	sd	s10,16(sp)
    80004022:	e46e                	sd	s11,8(sp)
    80004024:	1880                	addi	s0,sp,112
    80004026:	8b2a                	mv	s6,a0
    80004028:	8bae                	mv	s7,a1
    8000402a:	8a32                	mv	s4,a2
    8000402c:	84b6                	mv	s1,a3
    8000402e:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80004030:	9f35                	addw	a4,a4,a3
    return 0;
    80004032:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004034:	0ad76063          	bltu	a4,a3,800040d4 <readi+0xd2>
  if(off + n > ip->size)
    80004038:	00e7f463          	bgeu	a5,a4,80004040 <readi+0x3e>
    n = ip->size - off;
    8000403c:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004040:	0a0a8963          	beqz	s5,800040f2 <readi+0xf0>
    80004044:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004046:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    8000404a:	5c7d                	li	s8,-1
    8000404c:	a82d                	j	80004086 <readi+0x84>
    8000404e:	020d1d93          	slli	s11,s10,0x20
    80004052:	020ddd93          	srli	s11,s11,0x20
    80004056:	05890793          	addi	a5,s2,88
    8000405a:	86ee                	mv	a3,s11
    8000405c:	963e                	add	a2,a2,a5
    8000405e:	85d2                	mv	a1,s4
    80004060:	855e                	mv	a0,s7
    80004062:	ffffe097          	auipc	ra,0xffffe
    80004066:	7ba080e7          	jalr	1978(ra) # 8000281c <either_copyout>
    8000406a:	05850d63          	beq	a0,s8,800040c4 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    8000406e:	854a                	mv	a0,s2
    80004070:	fffff097          	auipc	ra,0xfffff
    80004074:	5f4080e7          	jalr	1524(ra) # 80003664 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004078:	013d09bb          	addw	s3,s10,s3
    8000407c:	009d04bb          	addw	s1,s10,s1
    80004080:	9a6e                	add	s4,s4,s11
    80004082:	0559f763          	bgeu	s3,s5,800040d0 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80004086:	00a4d59b          	srliw	a1,s1,0xa
    8000408a:	855a                	mv	a0,s6
    8000408c:	00000097          	auipc	ra,0x0
    80004090:	8a2080e7          	jalr	-1886(ra) # 8000392e <bmap>
    80004094:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004098:	cd85                	beqz	a1,800040d0 <readi+0xce>
    bp = bread(ip->dev, addr);
    8000409a:	000b2503          	lw	a0,0(s6)
    8000409e:	fffff097          	auipc	ra,0xfffff
    800040a2:	496080e7          	jalr	1174(ra) # 80003534 <bread>
    800040a6:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800040a8:	3ff4f613          	andi	a2,s1,1023
    800040ac:	40cc87bb          	subw	a5,s9,a2
    800040b0:	413a873b          	subw	a4,s5,s3
    800040b4:	8d3e                	mv	s10,a5
    800040b6:	2781                	sext.w	a5,a5
    800040b8:	0007069b          	sext.w	a3,a4
    800040bc:	f8f6f9e3          	bgeu	a3,a5,8000404e <readi+0x4c>
    800040c0:	8d3a                	mv	s10,a4
    800040c2:	b771                	j	8000404e <readi+0x4c>
      brelse(bp);
    800040c4:	854a                	mv	a0,s2
    800040c6:	fffff097          	auipc	ra,0xfffff
    800040ca:	59e080e7          	jalr	1438(ra) # 80003664 <brelse>
      tot = -1;
    800040ce:	59fd                	li	s3,-1
  }
  return tot;
    800040d0:	0009851b          	sext.w	a0,s3
}
    800040d4:	70a6                	ld	ra,104(sp)
    800040d6:	7406                	ld	s0,96(sp)
    800040d8:	64e6                	ld	s1,88(sp)
    800040da:	6946                	ld	s2,80(sp)
    800040dc:	69a6                	ld	s3,72(sp)
    800040de:	6a06                	ld	s4,64(sp)
    800040e0:	7ae2                	ld	s5,56(sp)
    800040e2:	7b42                	ld	s6,48(sp)
    800040e4:	7ba2                	ld	s7,40(sp)
    800040e6:	7c02                	ld	s8,32(sp)
    800040e8:	6ce2                	ld	s9,24(sp)
    800040ea:	6d42                	ld	s10,16(sp)
    800040ec:	6da2                	ld	s11,8(sp)
    800040ee:	6165                	addi	sp,sp,112
    800040f0:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800040f2:	89d6                	mv	s3,s5
    800040f4:	bff1                	j	800040d0 <readi+0xce>
    return 0;
    800040f6:	4501                	li	a0,0
}
    800040f8:	8082                	ret

00000000800040fa <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800040fa:	457c                	lw	a5,76(a0)
    800040fc:	10d7e863          	bltu	a5,a3,8000420c <writei+0x112>
{
    80004100:	7159                	addi	sp,sp,-112
    80004102:	f486                	sd	ra,104(sp)
    80004104:	f0a2                	sd	s0,96(sp)
    80004106:	eca6                	sd	s1,88(sp)
    80004108:	e8ca                	sd	s2,80(sp)
    8000410a:	e4ce                	sd	s3,72(sp)
    8000410c:	e0d2                	sd	s4,64(sp)
    8000410e:	fc56                	sd	s5,56(sp)
    80004110:	f85a                	sd	s6,48(sp)
    80004112:	f45e                	sd	s7,40(sp)
    80004114:	f062                	sd	s8,32(sp)
    80004116:	ec66                	sd	s9,24(sp)
    80004118:	e86a                	sd	s10,16(sp)
    8000411a:	e46e                	sd	s11,8(sp)
    8000411c:	1880                	addi	s0,sp,112
    8000411e:	8aaa                	mv	s5,a0
    80004120:	8bae                	mv	s7,a1
    80004122:	8a32                	mv	s4,a2
    80004124:	8936                	mv	s2,a3
    80004126:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004128:	00e687bb          	addw	a5,a3,a4
    8000412c:	0ed7e263          	bltu	a5,a3,80004210 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004130:	00043737          	lui	a4,0x43
    80004134:	0ef76063          	bltu	a4,a5,80004214 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004138:	0c0b0863          	beqz	s6,80004208 <writei+0x10e>
    8000413c:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    8000413e:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004142:	5c7d                	li	s8,-1
    80004144:	a091                	j	80004188 <writei+0x8e>
    80004146:	020d1d93          	slli	s11,s10,0x20
    8000414a:	020ddd93          	srli	s11,s11,0x20
    8000414e:	05848793          	addi	a5,s1,88
    80004152:	86ee                	mv	a3,s11
    80004154:	8652                	mv	a2,s4
    80004156:	85de                	mv	a1,s7
    80004158:	953e                	add	a0,a0,a5
    8000415a:	ffffe097          	auipc	ra,0xffffe
    8000415e:	718080e7          	jalr	1816(ra) # 80002872 <either_copyin>
    80004162:	07850263          	beq	a0,s8,800041c6 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004166:	8526                	mv	a0,s1
    80004168:	00000097          	auipc	ra,0x0
    8000416c:	780080e7          	jalr	1920(ra) # 800048e8 <log_write>
    brelse(bp);
    80004170:	8526                	mv	a0,s1
    80004172:	fffff097          	auipc	ra,0xfffff
    80004176:	4f2080e7          	jalr	1266(ra) # 80003664 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000417a:	013d09bb          	addw	s3,s10,s3
    8000417e:	012d093b          	addw	s2,s10,s2
    80004182:	9a6e                	add	s4,s4,s11
    80004184:	0569f663          	bgeu	s3,s6,800041d0 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80004188:	00a9559b          	srliw	a1,s2,0xa
    8000418c:	8556                	mv	a0,s5
    8000418e:	fffff097          	auipc	ra,0xfffff
    80004192:	7a0080e7          	jalr	1952(ra) # 8000392e <bmap>
    80004196:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    8000419a:	c99d                	beqz	a1,800041d0 <writei+0xd6>
    bp = bread(ip->dev, addr);
    8000419c:	000aa503          	lw	a0,0(s5)
    800041a0:	fffff097          	auipc	ra,0xfffff
    800041a4:	394080e7          	jalr	916(ra) # 80003534 <bread>
    800041a8:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800041aa:	3ff97513          	andi	a0,s2,1023
    800041ae:	40ac87bb          	subw	a5,s9,a0
    800041b2:	413b073b          	subw	a4,s6,s3
    800041b6:	8d3e                	mv	s10,a5
    800041b8:	2781                	sext.w	a5,a5
    800041ba:	0007069b          	sext.w	a3,a4
    800041be:	f8f6f4e3          	bgeu	a3,a5,80004146 <writei+0x4c>
    800041c2:	8d3a                	mv	s10,a4
    800041c4:	b749                	j	80004146 <writei+0x4c>
      brelse(bp);
    800041c6:	8526                	mv	a0,s1
    800041c8:	fffff097          	auipc	ra,0xfffff
    800041cc:	49c080e7          	jalr	1180(ra) # 80003664 <brelse>
  }

  if(off > ip->size)
    800041d0:	04caa783          	lw	a5,76(s5)
    800041d4:	0127f463          	bgeu	a5,s2,800041dc <writei+0xe2>
    ip->size = off;
    800041d8:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800041dc:	8556                	mv	a0,s5
    800041de:	00000097          	auipc	ra,0x0
    800041e2:	aa6080e7          	jalr	-1370(ra) # 80003c84 <iupdate>

  return tot;
    800041e6:	0009851b          	sext.w	a0,s3
}
    800041ea:	70a6                	ld	ra,104(sp)
    800041ec:	7406                	ld	s0,96(sp)
    800041ee:	64e6                	ld	s1,88(sp)
    800041f0:	6946                	ld	s2,80(sp)
    800041f2:	69a6                	ld	s3,72(sp)
    800041f4:	6a06                	ld	s4,64(sp)
    800041f6:	7ae2                	ld	s5,56(sp)
    800041f8:	7b42                	ld	s6,48(sp)
    800041fa:	7ba2                	ld	s7,40(sp)
    800041fc:	7c02                	ld	s8,32(sp)
    800041fe:	6ce2                	ld	s9,24(sp)
    80004200:	6d42                	ld	s10,16(sp)
    80004202:	6da2                	ld	s11,8(sp)
    80004204:	6165                	addi	sp,sp,112
    80004206:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004208:	89da                	mv	s3,s6
    8000420a:	bfc9                	j	800041dc <writei+0xe2>
    return -1;
    8000420c:	557d                	li	a0,-1
}
    8000420e:	8082                	ret
    return -1;
    80004210:	557d                	li	a0,-1
    80004212:	bfe1                	j	800041ea <writei+0xf0>
    return -1;
    80004214:	557d                	li	a0,-1
    80004216:	bfd1                	j	800041ea <writei+0xf0>

0000000080004218 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004218:	1141                	addi	sp,sp,-16
    8000421a:	e406                	sd	ra,8(sp)
    8000421c:	e022                	sd	s0,0(sp)
    8000421e:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004220:	4639                	li	a2,14
    80004222:	ffffd097          	auipc	ra,0xffffd
    80004226:	f40080e7          	jalr	-192(ra) # 80001162 <strncmp>
}
    8000422a:	60a2                	ld	ra,8(sp)
    8000422c:	6402                	ld	s0,0(sp)
    8000422e:	0141                	addi	sp,sp,16
    80004230:	8082                	ret

0000000080004232 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004232:	7139                	addi	sp,sp,-64
    80004234:	fc06                	sd	ra,56(sp)
    80004236:	f822                	sd	s0,48(sp)
    80004238:	f426                	sd	s1,40(sp)
    8000423a:	f04a                	sd	s2,32(sp)
    8000423c:	ec4e                	sd	s3,24(sp)
    8000423e:	e852                	sd	s4,16(sp)
    80004240:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004242:	04451703          	lh	a4,68(a0)
    80004246:	4785                	li	a5,1
    80004248:	00f71a63          	bne	a4,a5,8000425c <dirlookup+0x2a>
    8000424c:	892a                	mv	s2,a0
    8000424e:	89ae                	mv	s3,a1
    80004250:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004252:	457c                	lw	a5,76(a0)
    80004254:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004256:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004258:	e79d                	bnez	a5,80004286 <dirlookup+0x54>
    8000425a:	a8a5                	j	800042d2 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000425c:	00004517          	auipc	a0,0x4
    80004260:	4f450513          	addi	a0,a0,1268 # 80008750 <syscalls+0x1b0>
    80004264:	ffffc097          	auipc	ra,0xffffc
    80004268:	69a080e7          	jalr	1690(ra) # 800008fe <panic>
      panic("dirlookup read");
    8000426c:	00004517          	auipc	a0,0x4
    80004270:	4fc50513          	addi	a0,a0,1276 # 80008768 <syscalls+0x1c8>
    80004274:	ffffc097          	auipc	ra,0xffffc
    80004278:	68a080e7          	jalr	1674(ra) # 800008fe <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000427c:	24c1                	addiw	s1,s1,16
    8000427e:	04c92783          	lw	a5,76(s2)
    80004282:	04f4f763          	bgeu	s1,a5,800042d0 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004286:	4741                	li	a4,16
    80004288:	86a6                	mv	a3,s1
    8000428a:	fc040613          	addi	a2,s0,-64
    8000428e:	4581                	li	a1,0
    80004290:	854a                	mv	a0,s2
    80004292:	00000097          	auipc	ra,0x0
    80004296:	d70080e7          	jalr	-656(ra) # 80004002 <readi>
    8000429a:	47c1                	li	a5,16
    8000429c:	fcf518e3          	bne	a0,a5,8000426c <dirlookup+0x3a>
    if(de.inum == 0)
    800042a0:	fc045783          	lhu	a5,-64(s0)
    800042a4:	dfe1                	beqz	a5,8000427c <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800042a6:	fc240593          	addi	a1,s0,-62
    800042aa:	854e                	mv	a0,s3
    800042ac:	00000097          	auipc	ra,0x0
    800042b0:	f6c080e7          	jalr	-148(ra) # 80004218 <namecmp>
    800042b4:	f561                	bnez	a0,8000427c <dirlookup+0x4a>
      if(poff)
    800042b6:	000a0463          	beqz	s4,800042be <dirlookup+0x8c>
        *poff = off;
    800042ba:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800042be:	fc045583          	lhu	a1,-64(s0)
    800042c2:	00092503          	lw	a0,0(s2)
    800042c6:	fffff097          	auipc	ra,0xfffff
    800042ca:	750080e7          	jalr	1872(ra) # 80003a16 <iget>
    800042ce:	a011                	j	800042d2 <dirlookup+0xa0>
  return 0;
    800042d0:	4501                	li	a0,0
}
    800042d2:	70e2                	ld	ra,56(sp)
    800042d4:	7442                	ld	s0,48(sp)
    800042d6:	74a2                	ld	s1,40(sp)
    800042d8:	7902                	ld	s2,32(sp)
    800042da:	69e2                	ld	s3,24(sp)
    800042dc:	6a42                	ld	s4,16(sp)
    800042de:	6121                	addi	sp,sp,64
    800042e0:	8082                	ret

00000000800042e2 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800042e2:	711d                	addi	sp,sp,-96
    800042e4:	ec86                	sd	ra,88(sp)
    800042e6:	e8a2                	sd	s0,80(sp)
    800042e8:	e4a6                	sd	s1,72(sp)
    800042ea:	e0ca                	sd	s2,64(sp)
    800042ec:	fc4e                	sd	s3,56(sp)
    800042ee:	f852                	sd	s4,48(sp)
    800042f0:	f456                	sd	s5,40(sp)
    800042f2:	f05a                	sd	s6,32(sp)
    800042f4:	ec5e                	sd	s7,24(sp)
    800042f6:	e862                	sd	s8,16(sp)
    800042f8:	e466                	sd	s9,8(sp)
    800042fa:	1080                	addi	s0,sp,96
    800042fc:	84aa                	mv	s1,a0
    800042fe:	8aae                	mv	s5,a1
    80004300:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004302:	00054703          	lbu	a4,0(a0)
    80004306:	02f00793          	li	a5,47
    8000430a:	02f70363          	beq	a4,a5,80004330 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000430e:	ffffe097          	auipc	ra,0xffffe
    80004312:	a5e080e7          	jalr	-1442(ra) # 80001d6c <myproc>
    80004316:	15053503          	ld	a0,336(a0)
    8000431a:	00000097          	auipc	ra,0x0
    8000431e:	9f6080e7          	jalr	-1546(ra) # 80003d10 <idup>
    80004322:	89aa                	mv	s3,a0
  while(*path == '/')
    80004324:	02f00913          	li	s2,47
  len = path - s;
    80004328:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    8000432a:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000432c:	4b85                	li	s7,1
    8000432e:	a865                	j	800043e6 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004330:	4585                	li	a1,1
    80004332:	4505                	li	a0,1
    80004334:	fffff097          	auipc	ra,0xfffff
    80004338:	6e2080e7          	jalr	1762(ra) # 80003a16 <iget>
    8000433c:	89aa                	mv	s3,a0
    8000433e:	b7dd                	j	80004324 <namex+0x42>
      iunlockput(ip);
    80004340:	854e                	mv	a0,s3
    80004342:	00000097          	auipc	ra,0x0
    80004346:	c6e080e7          	jalr	-914(ra) # 80003fb0 <iunlockput>
      return 0;
    8000434a:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000434c:	854e                	mv	a0,s3
    8000434e:	60e6                	ld	ra,88(sp)
    80004350:	6446                	ld	s0,80(sp)
    80004352:	64a6                	ld	s1,72(sp)
    80004354:	6906                	ld	s2,64(sp)
    80004356:	79e2                	ld	s3,56(sp)
    80004358:	7a42                	ld	s4,48(sp)
    8000435a:	7aa2                	ld	s5,40(sp)
    8000435c:	7b02                	ld	s6,32(sp)
    8000435e:	6be2                	ld	s7,24(sp)
    80004360:	6c42                	ld	s8,16(sp)
    80004362:	6ca2                	ld	s9,8(sp)
    80004364:	6125                	addi	sp,sp,96
    80004366:	8082                	ret
      iunlock(ip);
    80004368:	854e                	mv	a0,s3
    8000436a:	00000097          	auipc	ra,0x0
    8000436e:	aa6080e7          	jalr	-1370(ra) # 80003e10 <iunlock>
      return ip;
    80004372:	bfe9                	j	8000434c <namex+0x6a>
      iunlockput(ip);
    80004374:	854e                	mv	a0,s3
    80004376:	00000097          	auipc	ra,0x0
    8000437a:	c3a080e7          	jalr	-966(ra) # 80003fb0 <iunlockput>
      return 0;
    8000437e:	89e6                	mv	s3,s9
    80004380:	b7f1                	j	8000434c <namex+0x6a>
  len = path - s;
    80004382:	40b48633          	sub	a2,s1,a1
    80004386:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    8000438a:	099c5463          	bge	s8,s9,80004412 <namex+0x130>
    memmove(name, s, DIRSIZ);
    8000438e:	4639                	li	a2,14
    80004390:	8552                	mv	a0,s4
    80004392:	ffffd097          	auipc	ra,0xffffd
    80004396:	d5c080e7          	jalr	-676(ra) # 800010ee <memmove>
  while(*path == '/')
    8000439a:	0004c783          	lbu	a5,0(s1)
    8000439e:	01279763          	bne	a5,s2,800043ac <namex+0xca>
    path++;
    800043a2:	0485                	addi	s1,s1,1
  while(*path == '/')
    800043a4:	0004c783          	lbu	a5,0(s1)
    800043a8:	ff278de3          	beq	a5,s2,800043a2 <namex+0xc0>
    ilock(ip);
    800043ac:	854e                	mv	a0,s3
    800043ae:	00000097          	auipc	ra,0x0
    800043b2:	9a0080e7          	jalr	-1632(ra) # 80003d4e <ilock>
    if(ip->type != T_DIR){
    800043b6:	04499783          	lh	a5,68(s3)
    800043ba:	f97793e3          	bne	a5,s7,80004340 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800043be:	000a8563          	beqz	s5,800043c8 <namex+0xe6>
    800043c2:	0004c783          	lbu	a5,0(s1)
    800043c6:	d3cd                	beqz	a5,80004368 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800043c8:	865a                	mv	a2,s6
    800043ca:	85d2                	mv	a1,s4
    800043cc:	854e                	mv	a0,s3
    800043ce:	00000097          	auipc	ra,0x0
    800043d2:	e64080e7          	jalr	-412(ra) # 80004232 <dirlookup>
    800043d6:	8caa                	mv	s9,a0
    800043d8:	dd51                	beqz	a0,80004374 <namex+0x92>
    iunlockput(ip);
    800043da:	854e                	mv	a0,s3
    800043dc:	00000097          	auipc	ra,0x0
    800043e0:	bd4080e7          	jalr	-1068(ra) # 80003fb0 <iunlockput>
    ip = next;
    800043e4:	89e6                	mv	s3,s9
  while(*path == '/')
    800043e6:	0004c783          	lbu	a5,0(s1)
    800043ea:	05279763          	bne	a5,s2,80004438 <namex+0x156>
    path++;
    800043ee:	0485                	addi	s1,s1,1
  while(*path == '/')
    800043f0:	0004c783          	lbu	a5,0(s1)
    800043f4:	ff278de3          	beq	a5,s2,800043ee <namex+0x10c>
  if(*path == 0)
    800043f8:	c79d                	beqz	a5,80004426 <namex+0x144>
    path++;
    800043fa:	85a6                	mv	a1,s1
  len = path - s;
    800043fc:	8cda                	mv	s9,s6
    800043fe:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80004400:	01278963          	beq	a5,s2,80004412 <namex+0x130>
    80004404:	dfbd                	beqz	a5,80004382 <namex+0xa0>
    path++;
    80004406:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004408:	0004c783          	lbu	a5,0(s1)
    8000440c:	ff279ce3          	bne	a5,s2,80004404 <namex+0x122>
    80004410:	bf8d                	j	80004382 <namex+0xa0>
    memmove(name, s, len);
    80004412:	2601                	sext.w	a2,a2
    80004414:	8552                	mv	a0,s4
    80004416:	ffffd097          	auipc	ra,0xffffd
    8000441a:	cd8080e7          	jalr	-808(ra) # 800010ee <memmove>
    name[len] = 0;
    8000441e:	9cd2                	add	s9,s9,s4
    80004420:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004424:	bf9d                	j	8000439a <namex+0xb8>
  if(nameiparent){
    80004426:	f20a83e3          	beqz	s5,8000434c <namex+0x6a>
    iput(ip);
    8000442a:	854e                	mv	a0,s3
    8000442c:	00000097          	auipc	ra,0x0
    80004430:	adc080e7          	jalr	-1316(ra) # 80003f08 <iput>
    return 0;
    80004434:	4981                	li	s3,0
    80004436:	bf19                	j	8000434c <namex+0x6a>
  if(*path == 0)
    80004438:	d7fd                	beqz	a5,80004426 <namex+0x144>
  while(*path != '/' && *path != 0)
    8000443a:	0004c783          	lbu	a5,0(s1)
    8000443e:	85a6                	mv	a1,s1
    80004440:	b7d1                	j	80004404 <namex+0x122>

0000000080004442 <dirlink>:
{
    80004442:	7139                	addi	sp,sp,-64
    80004444:	fc06                	sd	ra,56(sp)
    80004446:	f822                	sd	s0,48(sp)
    80004448:	f426                	sd	s1,40(sp)
    8000444a:	f04a                	sd	s2,32(sp)
    8000444c:	ec4e                	sd	s3,24(sp)
    8000444e:	e852                	sd	s4,16(sp)
    80004450:	0080                	addi	s0,sp,64
    80004452:	892a                	mv	s2,a0
    80004454:	8a2e                	mv	s4,a1
    80004456:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004458:	4601                	li	a2,0
    8000445a:	00000097          	auipc	ra,0x0
    8000445e:	dd8080e7          	jalr	-552(ra) # 80004232 <dirlookup>
    80004462:	e93d                	bnez	a0,800044d8 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004464:	04c92483          	lw	s1,76(s2)
    80004468:	c49d                	beqz	s1,80004496 <dirlink+0x54>
    8000446a:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000446c:	4741                	li	a4,16
    8000446e:	86a6                	mv	a3,s1
    80004470:	fc040613          	addi	a2,s0,-64
    80004474:	4581                	li	a1,0
    80004476:	854a                	mv	a0,s2
    80004478:	00000097          	auipc	ra,0x0
    8000447c:	b8a080e7          	jalr	-1142(ra) # 80004002 <readi>
    80004480:	47c1                	li	a5,16
    80004482:	06f51163          	bne	a0,a5,800044e4 <dirlink+0xa2>
    if(de.inum == 0)
    80004486:	fc045783          	lhu	a5,-64(s0)
    8000448a:	c791                	beqz	a5,80004496 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000448c:	24c1                	addiw	s1,s1,16
    8000448e:	04c92783          	lw	a5,76(s2)
    80004492:	fcf4ede3          	bltu	s1,a5,8000446c <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004496:	4639                	li	a2,14
    80004498:	85d2                	mv	a1,s4
    8000449a:	fc240513          	addi	a0,s0,-62
    8000449e:	ffffd097          	auipc	ra,0xffffd
    800044a2:	d00080e7          	jalr	-768(ra) # 8000119e <strncpy>
  de.inum = inum;
    800044a6:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800044aa:	4741                	li	a4,16
    800044ac:	86a6                	mv	a3,s1
    800044ae:	fc040613          	addi	a2,s0,-64
    800044b2:	4581                	li	a1,0
    800044b4:	854a                	mv	a0,s2
    800044b6:	00000097          	auipc	ra,0x0
    800044ba:	c44080e7          	jalr	-956(ra) # 800040fa <writei>
    800044be:	1541                	addi	a0,a0,-16
    800044c0:	00a03533          	snez	a0,a0
    800044c4:	40a00533          	neg	a0,a0
}
    800044c8:	70e2                	ld	ra,56(sp)
    800044ca:	7442                	ld	s0,48(sp)
    800044cc:	74a2                	ld	s1,40(sp)
    800044ce:	7902                	ld	s2,32(sp)
    800044d0:	69e2                	ld	s3,24(sp)
    800044d2:	6a42                	ld	s4,16(sp)
    800044d4:	6121                	addi	sp,sp,64
    800044d6:	8082                	ret
    iput(ip);
    800044d8:	00000097          	auipc	ra,0x0
    800044dc:	a30080e7          	jalr	-1488(ra) # 80003f08 <iput>
    return -1;
    800044e0:	557d                	li	a0,-1
    800044e2:	b7dd                	j	800044c8 <dirlink+0x86>
      panic("dirlink read");
    800044e4:	00004517          	auipc	a0,0x4
    800044e8:	29450513          	addi	a0,a0,660 # 80008778 <syscalls+0x1d8>
    800044ec:	ffffc097          	auipc	ra,0xffffc
    800044f0:	412080e7          	jalr	1042(ra) # 800008fe <panic>

00000000800044f4 <namei>:

struct inode*
namei(char *path)
{
    800044f4:	1101                	addi	sp,sp,-32
    800044f6:	ec06                	sd	ra,24(sp)
    800044f8:	e822                	sd	s0,16(sp)
    800044fa:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800044fc:	fe040613          	addi	a2,s0,-32
    80004500:	4581                	li	a1,0
    80004502:	00000097          	auipc	ra,0x0
    80004506:	de0080e7          	jalr	-544(ra) # 800042e2 <namex>
}
    8000450a:	60e2                	ld	ra,24(sp)
    8000450c:	6442                	ld	s0,16(sp)
    8000450e:	6105                	addi	sp,sp,32
    80004510:	8082                	ret

0000000080004512 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004512:	1141                	addi	sp,sp,-16
    80004514:	e406                	sd	ra,8(sp)
    80004516:	e022                	sd	s0,0(sp)
    80004518:	0800                	addi	s0,sp,16
    8000451a:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000451c:	4585                	li	a1,1
    8000451e:	00000097          	auipc	ra,0x0
    80004522:	dc4080e7          	jalr	-572(ra) # 800042e2 <namex>
}
    80004526:	60a2                	ld	ra,8(sp)
    80004528:	6402                	ld	s0,0(sp)
    8000452a:	0141                	addi	sp,sp,16
    8000452c:	8082                	ret

000000008000452e <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000452e:	1101                	addi	sp,sp,-32
    80004530:	ec06                	sd	ra,24(sp)
    80004532:	e822                	sd	s0,16(sp)
    80004534:	e426                	sd	s1,8(sp)
    80004536:	e04a                	sd	s2,0(sp)
    80004538:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000453a:	0001d917          	auipc	s2,0x1d
    8000453e:	fee90913          	addi	s2,s2,-18 # 80021528 <log>
    80004542:	01892583          	lw	a1,24(s2)
    80004546:	02892503          	lw	a0,40(s2)
    8000454a:	fffff097          	auipc	ra,0xfffff
    8000454e:	fea080e7          	jalr	-22(ra) # 80003534 <bread>
    80004552:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004554:	02c92683          	lw	a3,44(s2)
    80004558:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000455a:	02d05763          	blez	a3,80004588 <write_head+0x5a>
    8000455e:	0001d797          	auipc	a5,0x1d
    80004562:	ffa78793          	addi	a5,a5,-6 # 80021558 <log+0x30>
    80004566:	05c50713          	addi	a4,a0,92
    8000456a:	36fd                	addiw	a3,a3,-1
    8000456c:	1682                	slli	a3,a3,0x20
    8000456e:	9281                	srli	a3,a3,0x20
    80004570:	068a                	slli	a3,a3,0x2
    80004572:	0001d617          	auipc	a2,0x1d
    80004576:	fea60613          	addi	a2,a2,-22 # 8002155c <log+0x34>
    8000457a:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000457c:	4390                	lw	a2,0(a5)
    8000457e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004580:	0791                	addi	a5,a5,4
    80004582:	0711                	addi	a4,a4,4
    80004584:	fed79ce3          	bne	a5,a3,8000457c <write_head+0x4e>
  }
  bwrite(buf);
    80004588:	8526                	mv	a0,s1
    8000458a:	fffff097          	auipc	ra,0xfffff
    8000458e:	09c080e7          	jalr	156(ra) # 80003626 <bwrite>
  brelse(buf);
    80004592:	8526                	mv	a0,s1
    80004594:	fffff097          	auipc	ra,0xfffff
    80004598:	0d0080e7          	jalr	208(ra) # 80003664 <brelse>
}
    8000459c:	60e2                	ld	ra,24(sp)
    8000459e:	6442                	ld	s0,16(sp)
    800045a0:	64a2                	ld	s1,8(sp)
    800045a2:	6902                	ld	s2,0(sp)
    800045a4:	6105                	addi	sp,sp,32
    800045a6:	8082                	ret

00000000800045a8 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800045a8:	0001d797          	auipc	a5,0x1d
    800045ac:	fac7a783          	lw	a5,-84(a5) # 80021554 <log+0x2c>
    800045b0:	0af05d63          	blez	a5,8000466a <install_trans+0xc2>
{
    800045b4:	7139                	addi	sp,sp,-64
    800045b6:	fc06                	sd	ra,56(sp)
    800045b8:	f822                	sd	s0,48(sp)
    800045ba:	f426                	sd	s1,40(sp)
    800045bc:	f04a                	sd	s2,32(sp)
    800045be:	ec4e                	sd	s3,24(sp)
    800045c0:	e852                	sd	s4,16(sp)
    800045c2:	e456                	sd	s5,8(sp)
    800045c4:	e05a                	sd	s6,0(sp)
    800045c6:	0080                	addi	s0,sp,64
    800045c8:	8b2a                	mv	s6,a0
    800045ca:	0001da97          	auipc	s5,0x1d
    800045ce:	f8ea8a93          	addi	s5,s5,-114 # 80021558 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045d2:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800045d4:	0001d997          	auipc	s3,0x1d
    800045d8:	f5498993          	addi	s3,s3,-172 # 80021528 <log>
    800045dc:	a00d                	j	800045fe <install_trans+0x56>
    brelse(lbuf);
    800045de:	854a                	mv	a0,s2
    800045e0:	fffff097          	auipc	ra,0xfffff
    800045e4:	084080e7          	jalr	132(ra) # 80003664 <brelse>
    brelse(dbuf);
    800045e8:	8526                	mv	a0,s1
    800045ea:	fffff097          	auipc	ra,0xfffff
    800045ee:	07a080e7          	jalr	122(ra) # 80003664 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045f2:	2a05                	addiw	s4,s4,1
    800045f4:	0a91                	addi	s5,s5,4
    800045f6:	02c9a783          	lw	a5,44(s3)
    800045fa:	04fa5e63          	bge	s4,a5,80004656 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800045fe:	0189a583          	lw	a1,24(s3)
    80004602:	014585bb          	addw	a1,a1,s4
    80004606:	2585                	addiw	a1,a1,1
    80004608:	0289a503          	lw	a0,40(s3)
    8000460c:	fffff097          	auipc	ra,0xfffff
    80004610:	f28080e7          	jalr	-216(ra) # 80003534 <bread>
    80004614:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004616:	000aa583          	lw	a1,0(s5)
    8000461a:	0289a503          	lw	a0,40(s3)
    8000461e:	fffff097          	auipc	ra,0xfffff
    80004622:	f16080e7          	jalr	-234(ra) # 80003534 <bread>
    80004626:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004628:	40000613          	li	a2,1024
    8000462c:	05890593          	addi	a1,s2,88
    80004630:	05850513          	addi	a0,a0,88
    80004634:	ffffd097          	auipc	ra,0xffffd
    80004638:	aba080e7          	jalr	-1350(ra) # 800010ee <memmove>
    bwrite(dbuf);  // write dst to disk
    8000463c:	8526                	mv	a0,s1
    8000463e:	fffff097          	auipc	ra,0xfffff
    80004642:	fe8080e7          	jalr	-24(ra) # 80003626 <bwrite>
    if(recovering == 0)
    80004646:	f80b1ce3          	bnez	s6,800045de <install_trans+0x36>
      bunpin(dbuf);
    8000464a:	8526                	mv	a0,s1
    8000464c:	fffff097          	auipc	ra,0xfffff
    80004650:	0f2080e7          	jalr	242(ra) # 8000373e <bunpin>
    80004654:	b769                	j	800045de <install_trans+0x36>
}
    80004656:	70e2                	ld	ra,56(sp)
    80004658:	7442                	ld	s0,48(sp)
    8000465a:	74a2                	ld	s1,40(sp)
    8000465c:	7902                	ld	s2,32(sp)
    8000465e:	69e2                	ld	s3,24(sp)
    80004660:	6a42                	ld	s4,16(sp)
    80004662:	6aa2                	ld	s5,8(sp)
    80004664:	6b02                	ld	s6,0(sp)
    80004666:	6121                	addi	sp,sp,64
    80004668:	8082                	ret
    8000466a:	8082                	ret

000000008000466c <initlog>:
{
    8000466c:	7179                	addi	sp,sp,-48
    8000466e:	f406                	sd	ra,40(sp)
    80004670:	f022                	sd	s0,32(sp)
    80004672:	ec26                	sd	s1,24(sp)
    80004674:	e84a                	sd	s2,16(sp)
    80004676:	e44e                	sd	s3,8(sp)
    80004678:	1800                	addi	s0,sp,48
    8000467a:	892a                	mv	s2,a0
    8000467c:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000467e:	0001d497          	auipc	s1,0x1d
    80004682:	eaa48493          	addi	s1,s1,-342 # 80021528 <log>
    80004686:	00004597          	auipc	a1,0x4
    8000468a:	10258593          	addi	a1,a1,258 # 80008788 <syscalls+0x1e8>
    8000468e:	8526                	mv	a0,s1
    80004690:	ffffd097          	auipc	ra,0xffffd
    80004694:	876080e7          	jalr	-1930(ra) # 80000f06 <initlock>
  log.start = sb->logstart;
    80004698:	0149a583          	lw	a1,20(s3)
    8000469c:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000469e:	0109a783          	lw	a5,16(s3)
    800046a2:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800046a4:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800046a8:	854a                	mv	a0,s2
    800046aa:	fffff097          	auipc	ra,0xfffff
    800046ae:	e8a080e7          	jalr	-374(ra) # 80003534 <bread>
  log.lh.n = lh->n;
    800046b2:	4d34                	lw	a3,88(a0)
    800046b4:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800046b6:	02d05563          	blez	a3,800046e0 <initlog+0x74>
    800046ba:	05c50793          	addi	a5,a0,92
    800046be:	0001d717          	auipc	a4,0x1d
    800046c2:	e9a70713          	addi	a4,a4,-358 # 80021558 <log+0x30>
    800046c6:	36fd                	addiw	a3,a3,-1
    800046c8:	1682                	slli	a3,a3,0x20
    800046ca:	9281                	srli	a3,a3,0x20
    800046cc:	068a                	slli	a3,a3,0x2
    800046ce:	06050613          	addi	a2,a0,96
    800046d2:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800046d4:	4390                	lw	a2,0(a5)
    800046d6:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800046d8:	0791                	addi	a5,a5,4
    800046da:	0711                	addi	a4,a4,4
    800046dc:	fed79ce3          	bne	a5,a3,800046d4 <initlog+0x68>
  brelse(buf);
    800046e0:	fffff097          	auipc	ra,0xfffff
    800046e4:	f84080e7          	jalr	-124(ra) # 80003664 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800046e8:	4505                	li	a0,1
    800046ea:	00000097          	auipc	ra,0x0
    800046ee:	ebe080e7          	jalr	-322(ra) # 800045a8 <install_trans>
  log.lh.n = 0;
    800046f2:	0001d797          	auipc	a5,0x1d
    800046f6:	e607a123          	sw	zero,-414(a5) # 80021554 <log+0x2c>
  write_head(); // clear the log
    800046fa:	00000097          	auipc	ra,0x0
    800046fe:	e34080e7          	jalr	-460(ra) # 8000452e <write_head>
}
    80004702:	70a2                	ld	ra,40(sp)
    80004704:	7402                	ld	s0,32(sp)
    80004706:	64e2                	ld	s1,24(sp)
    80004708:	6942                	ld	s2,16(sp)
    8000470a:	69a2                	ld	s3,8(sp)
    8000470c:	6145                	addi	sp,sp,48
    8000470e:	8082                	ret

0000000080004710 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004710:	1101                	addi	sp,sp,-32
    80004712:	ec06                	sd	ra,24(sp)
    80004714:	e822                	sd	s0,16(sp)
    80004716:	e426                	sd	s1,8(sp)
    80004718:	e04a                	sd	s2,0(sp)
    8000471a:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000471c:	0001d517          	auipc	a0,0x1d
    80004720:	e0c50513          	addi	a0,a0,-500 # 80021528 <log>
    80004724:	ffffd097          	auipc	ra,0xffffd
    80004728:	872080e7          	jalr	-1934(ra) # 80000f96 <acquire>
  while(1){
    if(log.committing){
    8000472c:	0001d497          	auipc	s1,0x1d
    80004730:	dfc48493          	addi	s1,s1,-516 # 80021528 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004734:	4979                	li	s2,30
    80004736:	a039                	j	80004744 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004738:	85a6                	mv	a1,s1
    8000473a:	8526                	mv	a0,s1
    8000473c:	ffffe097          	auipc	ra,0xffffe
    80004740:	cd8080e7          	jalr	-808(ra) # 80002414 <sleep>
    if(log.committing){
    80004744:	50dc                	lw	a5,36(s1)
    80004746:	fbed                	bnez	a5,80004738 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004748:	509c                	lw	a5,32(s1)
    8000474a:	0017871b          	addiw	a4,a5,1
    8000474e:	0007069b          	sext.w	a3,a4
    80004752:	0027179b          	slliw	a5,a4,0x2
    80004756:	9fb9                	addw	a5,a5,a4
    80004758:	0017979b          	slliw	a5,a5,0x1
    8000475c:	54d8                	lw	a4,44(s1)
    8000475e:	9fb9                	addw	a5,a5,a4
    80004760:	00f95963          	bge	s2,a5,80004772 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004764:	85a6                	mv	a1,s1
    80004766:	8526                	mv	a0,s1
    80004768:	ffffe097          	auipc	ra,0xffffe
    8000476c:	cac080e7          	jalr	-852(ra) # 80002414 <sleep>
    80004770:	bfd1                	j	80004744 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004772:	0001d517          	auipc	a0,0x1d
    80004776:	db650513          	addi	a0,a0,-586 # 80021528 <log>
    8000477a:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000477c:	ffffd097          	auipc	ra,0xffffd
    80004780:	8ce080e7          	jalr	-1842(ra) # 8000104a <release>
      break;
    }
  }
}
    80004784:	60e2                	ld	ra,24(sp)
    80004786:	6442                	ld	s0,16(sp)
    80004788:	64a2                	ld	s1,8(sp)
    8000478a:	6902                	ld	s2,0(sp)
    8000478c:	6105                	addi	sp,sp,32
    8000478e:	8082                	ret

0000000080004790 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004790:	7139                	addi	sp,sp,-64
    80004792:	fc06                	sd	ra,56(sp)
    80004794:	f822                	sd	s0,48(sp)
    80004796:	f426                	sd	s1,40(sp)
    80004798:	f04a                	sd	s2,32(sp)
    8000479a:	ec4e                	sd	s3,24(sp)
    8000479c:	e852                	sd	s4,16(sp)
    8000479e:	e456                	sd	s5,8(sp)
    800047a0:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800047a2:	0001d497          	auipc	s1,0x1d
    800047a6:	d8648493          	addi	s1,s1,-634 # 80021528 <log>
    800047aa:	8526                	mv	a0,s1
    800047ac:	ffffc097          	auipc	ra,0xffffc
    800047b0:	7ea080e7          	jalr	2026(ra) # 80000f96 <acquire>
  log.outstanding -= 1;
    800047b4:	509c                	lw	a5,32(s1)
    800047b6:	37fd                	addiw	a5,a5,-1
    800047b8:	0007891b          	sext.w	s2,a5
    800047bc:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800047be:	50dc                	lw	a5,36(s1)
    800047c0:	e7b9                	bnez	a5,8000480e <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800047c2:	04091e63          	bnez	s2,8000481e <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800047c6:	0001d497          	auipc	s1,0x1d
    800047ca:	d6248493          	addi	s1,s1,-670 # 80021528 <log>
    800047ce:	4785                	li	a5,1
    800047d0:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800047d2:	8526                	mv	a0,s1
    800047d4:	ffffd097          	auipc	ra,0xffffd
    800047d8:	876080e7          	jalr	-1930(ra) # 8000104a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800047dc:	54dc                	lw	a5,44(s1)
    800047de:	06f04763          	bgtz	a5,8000484c <end_op+0xbc>
    acquire(&log.lock);
    800047e2:	0001d497          	auipc	s1,0x1d
    800047e6:	d4648493          	addi	s1,s1,-698 # 80021528 <log>
    800047ea:	8526                	mv	a0,s1
    800047ec:	ffffc097          	auipc	ra,0xffffc
    800047f0:	7aa080e7          	jalr	1962(ra) # 80000f96 <acquire>
    log.committing = 0;
    800047f4:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800047f8:	8526                	mv	a0,s1
    800047fa:	ffffe097          	auipc	ra,0xffffe
    800047fe:	c7e080e7          	jalr	-898(ra) # 80002478 <wakeup>
    release(&log.lock);
    80004802:	8526                	mv	a0,s1
    80004804:	ffffd097          	auipc	ra,0xffffd
    80004808:	846080e7          	jalr	-1978(ra) # 8000104a <release>
}
    8000480c:	a03d                	j	8000483a <end_op+0xaa>
    panic("log.committing");
    8000480e:	00004517          	auipc	a0,0x4
    80004812:	f8250513          	addi	a0,a0,-126 # 80008790 <syscalls+0x1f0>
    80004816:	ffffc097          	auipc	ra,0xffffc
    8000481a:	0e8080e7          	jalr	232(ra) # 800008fe <panic>
    wakeup(&log);
    8000481e:	0001d497          	auipc	s1,0x1d
    80004822:	d0a48493          	addi	s1,s1,-758 # 80021528 <log>
    80004826:	8526                	mv	a0,s1
    80004828:	ffffe097          	auipc	ra,0xffffe
    8000482c:	c50080e7          	jalr	-944(ra) # 80002478 <wakeup>
  release(&log.lock);
    80004830:	8526                	mv	a0,s1
    80004832:	ffffd097          	auipc	ra,0xffffd
    80004836:	818080e7          	jalr	-2024(ra) # 8000104a <release>
}
    8000483a:	70e2                	ld	ra,56(sp)
    8000483c:	7442                	ld	s0,48(sp)
    8000483e:	74a2                	ld	s1,40(sp)
    80004840:	7902                	ld	s2,32(sp)
    80004842:	69e2                	ld	s3,24(sp)
    80004844:	6a42                	ld	s4,16(sp)
    80004846:	6aa2                	ld	s5,8(sp)
    80004848:	6121                	addi	sp,sp,64
    8000484a:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000484c:	0001da97          	auipc	s5,0x1d
    80004850:	d0ca8a93          	addi	s5,s5,-756 # 80021558 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004854:	0001da17          	auipc	s4,0x1d
    80004858:	cd4a0a13          	addi	s4,s4,-812 # 80021528 <log>
    8000485c:	018a2583          	lw	a1,24(s4)
    80004860:	012585bb          	addw	a1,a1,s2
    80004864:	2585                	addiw	a1,a1,1
    80004866:	028a2503          	lw	a0,40(s4)
    8000486a:	fffff097          	auipc	ra,0xfffff
    8000486e:	cca080e7          	jalr	-822(ra) # 80003534 <bread>
    80004872:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004874:	000aa583          	lw	a1,0(s5)
    80004878:	028a2503          	lw	a0,40(s4)
    8000487c:	fffff097          	auipc	ra,0xfffff
    80004880:	cb8080e7          	jalr	-840(ra) # 80003534 <bread>
    80004884:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004886:	40000613          	li	a2,1024
    8000488a:	05850593          	addi	a1,a0,88
    8000488e:	05848513          	addi	a0,s1,88
    80004892:	ffffd097          	auipc	ra,0xffffd
    80004896:	85c080e7          	jalr	-1956(ra) # 800010ee <memmove>
    bwrite(to);  // write the log
    8000489a:	8526                	mv	a0,s1
    8000489c:	fffff097          	auipc	ra,0xfffff
    800048a0:	d8a080e7          	jalr	-630(ra) # 80003626 <bwrite>
    brelse(from);
    800048a4:	854e                	mv	a0,s3
    800048a6:	fffff097          	auipc	ra,0xfffff
    800048aa:	dbe080e7          	jalr	-578(ra) # 80003664 <brelse>
    brelse(to);
    800048ae:	8526                	mv	a0,s1
    800048b0:	fffff097          	auipc	ra,0xfffff
    800048b4:	db4080e7          	jalr	-588(ra) # 80003664 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800048b8:	2905                	addiw	s2,s2,1
    800048ba:	0a91                	addi	s5,s5,4
    800048bc:	02ca2783          	lw	a5,44(s4)
    800048c0:	f8f94ee3          	blt	s2,a5,8000485c <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800048c4:	00000097          	auipc	ra,0x0
    800048c8:	c6a080e7          	jalr	-918(ra) # 8000452e <write_head>
    install_trans(0); // Now install writes to home locations
    800048cc:	4501                	li	a0,0
    800048ce:	00000097          	auipc	ra,0x0
    800048d2:	cda080e7          	jalr	-806(ra) # 800045a8 <install_trans>
    log.lh.n = 0;
    800048d6:	0001d797          	auipc	a5,0x1d
    800048da:	c607af23          	sw	zero,-898(a5) # 80021554 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800048de:	00000097          	auipc	ra,0x0
    800048e2:	c50080e7          	jalr	-944(ra) # 8000452e <write_head>
    800048e6:	bdf5                	j	800047e2 <end_op+0x52>

00000000800048e8 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800048e8:	1101                	addi	sp,sp,-32
    800048ea:	ec06                	sd	ra,24(sp)
    800048ec:	e822                	sd	s0,16(sp)
    800048ee:	e426                	sd	s1,8(sp)
    800048f0:	e04a                	sd	s2,0(sp)
    800048f2:	1000                	addi	s0,sp,32
    800048f4:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800048f6:	0001d917          	auipc	s2,0x1d
    800048fa:	c3290913          	addi	s2,s2,-974 # 80021528 <log>
    800048fe:	854a                	mv	a0,s2
    80004900:	ffffc097          	auipc	ra,0xffffc
    80004904:	696080e7          	jalr	1686(ra) # 80000f96 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004908:	02c92603          	lw	a2,44(s2)
    8000490c:	47f5                	li	a5,29
    8000490e:	06c7c563          	blt	a5,a2,80004978 <log_write+0x90>
    80004912:	0001d797          	auipc	a5,0x1d
    80004916:	c327a783          	lw	a5,-974(a5) # 80021544 <log+0x1c>
    8000491a:	37fd                	addiw	a5,a5,-1
    8000491c:	04f65e63          	bge	a2,a5,80004978 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004920:	0001d797          	auipc	a5,0x1d
    80004924:	c287a783          	lw	a5,-984(a5) # 80021548 <log+0x20>
    80004928:	06f05063          	blez	a5,80004988 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000492c:	4781                	li	a5,0
    8000492e:	06c05563          	blez	a2,80004998 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004932:	44cc                	lw	a1,12(s1)
    80004934:	0001d717          	auipc	a4,0x1d
    80004938:	c2470713          	addi	a4,a4,-988 # 80021558 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000493c:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000493e:	4314                	lw	a3,0(a4)
    80004940:	04b68c63          	beq	a3,a1,80004998 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004944:	2785                	addiw	a5,a5,1
    80004946:	0711                	addi	a4,a4,4
    80004948:	fef61be3          	bne	a2,a5,8000493e <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000494c:	0621                	addi	a2,a2,8
    8000494e:	060a                	slli	a2,a2,0x2
    80004950:	0001d797          	auipc	a5,0x1d
    80004954:	bd878793          	addi	a5,a5,-1064 # 80021528 <log>
    80004958:	963e                	add	a2,a2,a5
    8000495a:	44dc                	lw	a5,12(s1)
    8000495c:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000495e:	8526                	mv	a0,s1
    80004960:	fffff097          	auipc	ra,0xfffff
    80004964:	da2080e7          	jalr	-606(ra) # 80003702 <bpin>
    log.lh.n++;
    80004968:	0001d717          	auipc	a4,0x1d
    8000496c:	bc070713          	addi	a4,a4,-1088 # 80021528 <log>
    80004970:	575c                	lw	a5,44(a4)
    80004972:	2785                	addiw	a5,a5,1
    80004974:	d75c                	sw	a5,44(a4)
    80004976:	a835                	j	800049b2 <log_write+0xca>
    panic("too big a transaction");
    80004978:	00004517          	auipc	a0,0x4
    8000497c:	e2850513          	addi	a0,a0,-472 # 800087a0 <syscalls+0x200>
    80004980:	ffffc097          	auipc	ra,0xffffc
    80004984:	f7e080e7          	jalr	-130(ra) # 800008fe <panic>
    panic("log_write outside of trans");
    80004988:	00004517          	auipc	a0,0x4
    8000498c:	e3050513          	addi	a0,a0,-464 # 800087b8 <syscalls+0x218>
    80004990:	ffffc097          	auipc	ra,0xffffc
    80004994:	f6e080e7          	jalr	-146(ra) # 800008fe <panic>
  log.lh.block[i] = b->blockno;
    80004998:	00878713          	addi	a4,a5,8
    8000499c:	00271693          	slli	a3,a4,0x2
    800049a0:	0001d717          	auipc	a4,0x1d
    800049a4:	b8870713          	addi	a4,a4,-1144 # 80021528 <log>
    800049a8:	9736                	add	a4,a4,a3
    800049aa:	44d4                	lw	a3,12(s1)
    800049ac:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800049ae:	faf608e3          	beq	a2,a5,8000495e <log_write+0x76>
  }
  release(&log.lock);
    800049b2:	0001d517          	auipc	a0,0x1d
    800049b6:	b7650513          	addi	a0,a0,-1162 # 80021528 <log>
    800049ba:	ffffc097          	auipc	ra,0xffffc
    800049be:	690080e7          	jalr	1680(ra) # 8000104a <release>
}
    800049c2:	60e2                	ld	ra,24(sp)
    800049c4:	6442                	ld	s0,16(sp)
    800049c6:	64a2                	ld	s1,8(sp)
    800049c8:	6902                	ld	s2,0(sp)
    800049ca:	6105                	addi	sp,sp,32
    800049cc:	8082                	ret

00000000800049ce <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800049ce:	1101                	addi	sp,sp,-32
    800049d0:	ec06                	sd	ra,24(sp)
    800049d2:	e822                	sd	s0,16(sp)
    800049d4:	e426                	sd	s1,8(sp)
    800049d6:	e04a                	sd	s2,0(sp)
    800049d8:	1000                	addi	s0,sp,32
    800049da:	84aa                	mv	s1,a0
    800049dc:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800049de:	00004597          	auipc	a1,0x4
    800049e2:	dfa58593          	addi	a1,a1,-518 # 800087d8 <syscalls+0x238>
    800049e6:	0521                	addi	a0,a0,8
    800049e8:	ffffc097          	auipc	ra,0xffffc
    800049ec:	51e080e7          	jalr	1310(ra) # 80000f06 <initlock>
  lk->name = name;
    800049f0:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800049f4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800049f8:	0204a423          	sw	zero,40(s1)
}
    800049fc:	60e2                	ld	ra,24(sp)
    800049fe:	6442                	ld	s0,16(sp)
    80004a00:	64a2                	ld	s1,8(sp)
    80004a02:	6902                	ld	s2,0(sp)
    80004a04:	6105                	addi	sp,sp,32
    80004a06:	8082                	ret

0000000080004a08 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004a08:	1101                	addi	sp,sp,-32
    80004a0a:	ec06                	sd	ra,24(sp)
    80004a0c:	e822                	sd	s0,16(sp)
    80004a0e:	e426                	sd	s1,8(sp)
    80004a10:	e04a                	sd	s2,0(sp)
    80004a12:	1000                	addi	s0,sp,32
    80004a14:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004a16:	00850913          	addi	s2,a0,8
    80004a1a:	854a                	mv	a0,s2
    80004a1c:	ffffc097          	auipc	ra,0xffffc
    80004a20:	57a080e7          	jalr	1402(ra) # 80000f96 <acquire>
  while (lk->locked) {
    80004a24:	409c                	lw	a5,0(s1)
    80004a26:	cb89                	beqz	a5,80004a38 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004a28:	85ca                	mv	a1,s2
    80004a2a:	8526                	mv	a0,s1
    80004a2c:	ffffe097          	auipc	ra,0xffffe
    80004a30:	9e8080e7          	jalr	-1560(ra) # 80002414 <sleep>
  while (lk->locked) {
    80004a34:	409c                	lw	a5,0(s1)
    80004a36:	fbed                	bnez	a5,80004a28 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004a38:	4785                	li	a5,1
    80004a3a:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004a3c:	ffffd097          	auipc	ra,0xffffd
    80004a40:	330080e7          	jalr	816(ra) # 80001d6c <myproc>
    80004a44:	591c                	lw	a5,48(a0)
    80004a46:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004a48:	854a                	mv	a0,s2
    80004a4a:	ffffc097          	auipc	ra,0xffffc
    80004a4e:	600080e7          	jalr	1536(ra) # 8000104a <release>
}
    80004a52:	60e2                	ld	ra,24(sp)
    80004a54:	6442                	ld	s0,16(sp)
    80004a56:	64a2                	ld	s1,8(sp)
    80004a58:	6902                	ld	s2,0(sp)
    80004a5a:	6105                	addi	sp,sp,32
    80004a5c:	8082                	ret

0000000080004a5e <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004a5e:	1101                	addi	sp,sp,-32
    80004a60:	ec06                	sd	ra,24(sp)
    80004a62:	e822                	sd	s0,16(sp)
    80004a64:	e426                	sd	s1,8(sp)
    80004a66:	e04a                	sd	s2,0(sp)
    80004a68:	1000                	addi	s0,sp,32
    80004a6a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004a6c:	00850913          	addi	s2,a0,8
    80004a70:	854a                	mv	a0,s2
    80004a72:	ffffc097          	auipc	ra,0xffffc
    80004a76:	524080e7          	jalr	1316(ra) # 80000f96 <acquire>
  lk->locked = 0;
    80004a7a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004a7e:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004a82:	8526                	mv	a0,s1
    80004a84:	ffffe097          	auipc	ra,0xffffe
    80004a88:	9f4080e7          	jalr	-1548(ra) # 80002478 <wakeup>
  release(&lk->lk);
    80004a8c:	854a                	mv	a0,s2
    80004a8e:	ffffc097          	auipc	ra,0xffffc
    80004a92:	5bc080e7          	jalr	1468(ra) # 8000104a <release>
}
    80004a96:	60e2                	ld	ra,24(sp)
    80004a98:	6442                	ld	s0,16(sp)
    80004a9a:	64a2                	ld	s1,8(sp)
    80004a9c:	6902                	ld	s2,0(sp)
    80004a9e:	6105                	addi	sp,sp,32
    80004aa0:	8082                	ret

0000000080004aa2 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004aa2:	7179                	addi	sp,sp,-48
    80004aa4:	f406                	sd	ra,40(sp)
    80004aa6:	f022                	sd	s0,32(sp)
    80004aa8:	ec26                	sd	s1,24(sp)
    80004aaa:	e84a                	sd	s2,16(sp)
    80004aac:	e44e                	sd	s3,8(sp)
    80004aae:	1800                	addi	s0,sp,48
    80004ab0:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004ab2:	00850913          	addi	s2,a0,8
    80004ab6:	854a                	mv	a0,s2
    80004ab8:	ffffc097          	auipc	ra,0xffffc
    80004abc:	4de080e7          	jalr	1246(ra) # 80000f96 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004ac0:	409c                	lw	a5,0(s1)
    80004ac2:	ef99                	bnez	a5,80004ae0 <holdingsleep+0x3e>
    80004ac4:	4481                	li	s1,0
  release(&lk->lk);
    80004ac6:	854a                	mv	a0,s2
    80004ac8:	ffffc097          	auipc	ra,0xffffc
    80004acc:	582080e7          	jalr	1410(ra) # 8000104a <release>
  return r;
}
    80004ad0:	8526                	mv	a0,s1
    80004ad2:	70a2                	ld	ra,40(sp)
    80004ad4:	7402                	ld	s0,32(sp)
    80004ad6:	64e2                	ld	s1,24(sp)
    80004ad8:	6942                	ld	s2,16(sp)
    80004ada:	69a2                	ld	s3,8(sp)
    80004adc:	6145                	addi	sp,sp,48
    80004ade:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004ae0:	0284a983          	lw	s3,40(s1)
    80004ae4:	ffffd097          	auipc	ra,0xffffd
    80004ae8:	288080e7          	jalr	648(ra) # 80001d6c <myproc>
    80004aec:	5904                	lw	s1,48(a0)
    80004aee:	413484b3          	sub	s1,s1,s3
    80004af2:	0014b493          	seqz	s1,s1
    80004af6:	bfc1                	j	80004ac6 <holdingsleep+0x24>

0000000080004af8 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004af8:	1141                	addi	sp,sp,-16
    80004afa:	e406                	sd	ra,8(sp)
    80004afc:	e022                	sd	s0,0(sp)
    80004afe:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004b00:	00004597          	auipc	a1,0x4
    80004b04:	ce858593          	addi	a1,a1,-792 # 800087e8 <syscalls+0x248>
    80004b08:	0001d517          	auipc	a0,0x1d
    80004b0c:	b6850513          	addi	a0,a0,-1176 # 80021670 <ftable>
    80004b10:	ffffc097          	auipc	ra,0xffffc
    80004b14:	3f6080e7          	jalr	1014(ra) # 80000f06 <initlock>
}
    80004b18:	60a2                	ld	ra,8(sp)
    80004b1a:	6402                	ld	s0,0(sp)
    80004b1c:	0141                	addi	sp,sp,16
    80004b1e:	8082                	ret

0000000080004b20 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004b20:	1101                	addi	sp,sp,-32
    80004b22:	ec06                	sd	ra,24(sp)
    80004b24:	e822                	sd	s0,16(sp)
    80004b26:	e426                	sd	s1,8(sp)
    80004b28:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004b2a:	0001d517          	auipc	a0,0x1d
    80004b2e:	b4650513          	addi	a0,a0,-1210 # 80021670 <ftable>
    80004b32:	ffffc097          	auipc	ra,0xffffc
    80004b36:	464080e7          	jalr	1124(ra) # 80000f96 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b3a:	0001d497          	auipc	s1,0x1d
    80004b3e:	b4e48493          	addi	s1,s1,-1202 # 80021688 <ftable+0x18>
    80004b42:	0001e717          	auipc	a4,0x1e
    80004b46:	ae670713          	addi	a4,a4,-1306 # 80022628 <disk>
    if(f->ref == 0){
    80004b4a:	40dc                	lw	a5,4(s1)
    80004b4c:	cf99                	beqz	a5,80004b6a <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b4e:	02848493          	addi	s1,s1,40
    80004b52:	fee49ce3          	bne	s1,a4,80004b4a <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004b56:	0001d517          	auipc	a0,0x1d
    80004b5a:	b1a50513          	addi	a0,a0,-1254 # 80021670 <ftable>
    80004b5e:	ffffc097          	auipc	ra,0xffffc
    80004b62:	4ec080e7          	jalr	1260(ra) # 8000104a <release>
  return 0;
    80004b66:	4481                	li	s1,0
    80004b68:	a819                	j	80004b7e <filealloc+0x5e>
      f->ref = 1;
    80004b6a:	4785                	li	a5,1
    80004b6c:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004b6e:	0001d517          	auipc	a0,0x1d
    80004b72:	b0250513          	addi	a0,a0,-1278 # 80021670 <ftable>
    80004b76:	ffffc097          	auipc	ra,0xffffc
    80004b7a:	4d4080e7          	jalr	1236(ra) # 8000104a <release>
}
    80004b7e:	8526                	mv	a0,s1
    80004b80:	60e2                	ld	ra,24(sp)
    80004b82:	6442                	ld	s0,16(sp)
    80004b84:	64a2                	ld	s1,8(sp)
    80004b86:	6105                	addi	sp,sp,32
    80004b88:	8082                	ret

0000000080004b8a <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004b8a:	1101                	addi	sp,sp,-32
    80004b8c:	ec06                	sd	ra,24(sp)
    80004b8e:	e822                	sd	s0,16(sp)
    80004b90:	e426                	sd	s1,8(sp)
    80004b92:	1000                	addi	s0,sp,32
    80004b94:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004b96:	0001d517          	auipc	a0,0x1d
    80004b9a:	ada50513          	addi	a0,a0,-1318 # 80021670 <ftable>
    80004b9e:	ffffc097          	auipc	ra,0xffffc
    80004ba2:	3f8080e7          	jalr	1016(ra) # 80000f96 <acquire>
  if(f->ref < 1)
    80004ba6:	40dc                	lw	a5,4(s1)
    80004ba8:	02f05263          	blez	a5,80004bcc <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004bac:	2785                	addiw	a5,a5,1
    80004bae:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004bb0:	0001d517          	auipc	a0,0x1d
    80004bb4:	ac050513          	addi	a0,a0,-1344 # 80021670 <ftable>
    80004bb8:	ffffc097          	auipc	ra,0xffffc
    80004bbc:	492080e7          	jalr	1170(ra) # 8000104a <release>
  return f;
}
    80004bc0:	8526                	mv	a0,s1
    80004bc2:	60e2                	ld	ra,24(sp)
    80004bc4:	6442                	ld	s0,16(sp)
    80004bc6:	64a2                	ld	s1,8(sp)
    80004bc8:	6105                	addi	sp,sp,32
    80004bca:	8082                	ret
    panic("filedup");
    80004bcc:	00004517          	auipc	a0,0x4
    80004bd0:	c2450513          	addi	a0,a0,-988 # 800087f0 <syscalls+0x250>
    80004bd4:	ffffc097          	auipc	ra,0xffffc
    80004bd8:	d2a080e7          	jalr	-726(ra) # 800008fe <panic>

0000000080004bdc <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004bdc:	7139                	addi	sp,sp,-64
    80004bde:	fc06                	sd	ra,56(sp)
    80004be0:	f822                	sd	s0,48(sp)
    80004be2:	f426                	sd	s1,40(sp)
    80004be4:	f04a                	sd	s2,32(sp)
    80004be6:	ec4e                	sd	s3,24(sp)
    80004be8:	e852                	sd	s4,16(sp)
    80004bea:	e456                	sd	s5,8(sp)
    80004bec:	0080                	addi	s0,sp,64
    80004bee:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004bf0:	0001d517          	auipc	a0,0x1d
    80004bf4:	a8050513          	addi	a0,a0,-1408 # 80021670 <ftable>
    80004bf8:	ffffc097          	auipc	ra,0xffffc
    80004bfc:	39e080e7          	jalr	926(ra) # 80000f96 <acquire>
  if(f->ref < 1)
    80004c00:	40dc                	lw	a5,4(s1)
    80004c02:	06f05163          	blez	a5,80004c64 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004c06:	37fd                	addiw	a5,a5,-1
    80004c08:	0007871b          	sext.w	a4,a5
    80004c0c:	c0dc                	sw	a5,4(s1)
    80004c0e:	06e04363          	bgtz	a4,80004c74 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004c12:	0004a903          	lw	s2,0(s1)
    80004c16:	0094ca83          	lbu	s5,9(s1)
    80004c1a:	0104ba03          	ld	s4,16(s1)
    80004c1e:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004c22:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004c26:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004c2a:	0001d517          	auipc	a0,0x1d
    80004c2e:	a4650513          	addi	a0,a0,-1466 # 80021670 <ftable>
    80004c32:	ffffc097          	auipc	ra,0xffffc
    80004c36:	418080e7          	jalr	1048(ra) # 8000104a <release>

  if(ff.type == FD_PIPE){
    80004c3a:	4785                	li	a5,1
    80004c3c:	04f90d63          	beq	s2,a5,80004c96 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004c40:	3979                	addiw	s2,s2,-2
    80004c42:	4785                	li	a5,1
    80004c44:	0527e063          	bltu	a5,s2,80004c84 <fileclose+0xa8>
    begin_op();
    80004c48:	00000097          	auipc	ra,0x0
    80004c4c:	ac8080e7          	jalr	-1336(ra) # 80004710 <begin_op>
    iput(ff.ip);
    80004c50:	854e                	mv	a0,s3
    80004c52:	fffff097          	auipc	ra,0xfffff
    80004c56:	2b6080e7          	jalr	694(ra) # 80003f08 <iput>
    end_op();
    80004c5a:	00000097          	auipc	ra,0x0
    80004c5e:	b36080e7          	jalr	-1226(ra) # 80004790 <end_op>
    80004c62:	a00d                	j	80004c84 <fileclose+0xa8>
    panic("fileclose");
    80004c64:	00004517          	auipc	a0,0x4
    80004c68:	b9450513          	addi	a0,a0,-1132 # 800087f8 <syscalls+0x258>
    80004c6c:	ffffc097          	auipc	ra,0xffffc
    80004c70:	c92080e7          	jalr	-878(ra) # 800008fe <panic>
    release(&ftable.lock);
    80004c74:	0001d517          	auipc	a0,0x1d
    80004c78:	9fc50513          	addi	a0,a0,-1540 # 80021670 <ftable>
    80004c7c:	ffffc097          	auipc	ra,0xffffc
    80004c80:	3ce080e7          	jalr	974(ra) # 8000104a <release>
  }
}
    80004c84:	70e2                	ld	ra,56(sp)
    80004c86:	7442                	ld	s0,48(sp)
    80004c88:	74a2                	ld	s1,40(sp)
    80004c8a:	7902                	ld	s2,32(sp)
    80004c8c:	69e2                	ld	s3,24(sp)
    80004c8e:	6a42                	ld	s4,16(sp)
    80004c90:	6aa2                	ld	s5,8(sp)
    80004c92:	6121                	addi	sp,sp,64
    80004c94:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004c96:	85d6                	mv	a1,s5
    80004c98:	8552                	mv	a0,s4
    80004c9a:	00000097          	auipc	ra,0x0
    80004c9e:	34c080e7          	jalr	844(ra) # 80004fe6 <pipeclose>
    80004ca2:	b7cd                	j	80004c84 <fileclose+0xa8>

0000000080004ca4 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004ca4:	715d                	addi	sp,sp,-80
    80004ca6:	e486                	sd	ra,72(sp)
    80004ca8:	e0a2                	sd	s0,64(sp)
    80004caa:	fc26                	sd	s1,56(sp)
    80004cac:	f84a                	sd	s2,48(sp)
    80004cae:	f44e                	sd	s3,40(sp)
    80004cb0:	0880                	addi	s0,sp,80
    80004cb2:	84aa                	mv	s1,a0
    80004cb4:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004cb6:	ffffd097          	auipc	ra,0xffffd
    80004cba:	0b6080e7          	jalr	182(ra) # 80001d6c <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004cbe:	409c                	lw	a5,0(s1)
    80004cc0:	37f9                	addiw	a5,a5,-2
    80004cc2:	4705                	li	a4,1
    80004cc4:	04f76763          	bltu	a4,a5,80004d12 <filestat+0x6e>
    80004cc8:	892a                	mv	s2,a0
    ilock(f->ip);
    80004cca:	6c88                	ld	a0,24(s1)
    80004ccc:	fffff097          	auipc	ra,0xfffff
    80004cd0:	082080e7          	jalr	130(ra) # 80003d4e <ilock>
    stati(f->ip, &st);
    80004cd4:	fb840593          	addi	a1,s0,-72
    80004cd8:	6c88                	ld	a0,24(s1)
    80004cda:	fffff097          	auipc	ra,0xfffff
    80004cde:	2fe080e7          	jalr	766(ra) # 80003fd8 <stati>
    iunlock(f->ip);
    80004ce2:	6c88                	ld	a0,24(s1)
    80004ce4:	fffff097          	auipc	ra,0xfffff
    80004ce8:	12c080e7          	jalr	300(ra) # 80003e10 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004cec:	46e1                	li	a3,24
    80004cee:	fb840613          	addi	a2,s0,-72
    80004cf2:	85ce                	mv	a1,s3
    80004cf4:	05093503          	ld	a0,80(s2)
    80004cf8:	ffffd097          	auipc	ra,0xffffd
    80004cfc:	d30080e7          	jalr	-720(ra) # 80001a28 <copyout>
    80004d00:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004d04:	60a6                	ld	ra,72(sp)
    80004d06:	6406                	ld	s0,64(sp)
    80004d08:	74e2                	ld	s1,56(sp)
    80004d0a:	7942                	ld	s2,48(sp)
    80004d0c:	79a2                	ld	s3,40(sp)
    80004d0e:	6161                	addi	sp,sp,80
    80004d10:	8082                	ret
  return -1;
    80004d12:	557d                	li	a0,-1
    80004d14:	bfc5                	j	80004d04 <filestat+0x60>

0000000080004d16 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004d16:	7179                	addi	sp,sp,-48
    80004d18:	f406                	sd	ra,40(sp)
    80004d1a:	f022                	sd	s0,32(sp)
    80004d1c:	ec26                	sd	s1,24(sp)
    80004d1e:	e84a                	sd	s2,16(sp)
    80004d20:	e44e                	sd	s3,8(sp)
    80004d22:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004d24:	00854783          	lbu	a5,8(a0)
    80004d28:	c3d5                	beqz	a5,80004dcc <fileread+0xb6>
    80004d2a:	84aa                	mv	s1,a0
    80004d2c:	89ae                	mv	s3,a1
    80004d2e:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004d30:	411c                	lw	a5,0(a0)
    80004d32:	4705                	li	a4,1
    80004d34:	04e78963          	beq	a5,a4,80004d86 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004d38:	470d                	li	a4,3
    80004d3a:	04e78d63          	beq	a5,a4,80004d94 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004d3e:	4709                	li	a4,2
    80004d40:	06e79e63          	bne	a5,a4,80004dbc <fileread+0xa6>
    ilock(f->ip);
    80004d44:	6d08                	ld	a0,24(a0)
    80004d46:	fffff097          	auipc	ra,0xfffff
    80004d4a:	008080e7          	jalr	8(ra) # 80003d4e <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004d4e:	874a                	mv	a4,s2
    80004d50:	5094                	lw	a3,32(s1)
    80004d52:	864e                	mv	a2,s3
    80004d54:	4585                	li	a1,1
    80004d56:	6c88                	ld	a0,24(s1)
    80004d58:	fffff097          	auipc	ra,0xfffff
    80004d5c:	2aa080e7          	jalr	682(ra) # 80004002 <readi>
    80004d60:	892a                	mv	s2,a0
    80004d62:	00a05563          	blez	a0,80004d6c <fileread+0x56>
      f->off += r;
    80004d66:	509c                	lw	a5,32(s1)
    80004d68:	9fa9                	addw	a5,a5,a0
    80004d6a:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004d6c:	6c88                	ld	a0,24(s1)
    80004d6e:	fffff097          	auipc	ra,0xfffff
    80004d72:	0a2080e7          	jalr	162(ra) # 80003e10 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004d76:	854a                	mv	a0,s2
    80004d78:	70a2                	ld	ra,40(sp)
    80004d7a:	7402                	ld	s0,32(sp)
    80004d7c:	64e2                	ld	s1,24(sp)
    80004d7e:	6942                	ld	s2,16(sp)
    80004d80:	69a2                	ld	s3,8(sp)
    80004d82:	6145                	addi	sp,sp,48
    80004d84:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004d86:	6908                	ld	a0,16(a0)
    80004d88:	00000097          	auipc	ra,0x0
    80004d8c:	3c6080e7          	jalr	966(ra) # 8000514e <piperead>
    80004d90:	892a                	mv	s2,a0
    80004d92:	b7d5                	j	80004d76 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004d94:	02451783          	lh	a5,36(a0)
    80004d98:	03079693          	slli	a3,a5,0x30
    80004d9c:	92c1                	srli	a3,a3,0x30
    80004d9e:	4725                	li	a4,9
    80004da0:	02d76863          	bltu	a4,a3,80004dd0 <fileread+0xba>
    80004da4:	0792                	slli	a5,a5,0x4
    80004da6:	0001d717          	auipc	a4,0x1d
    80004daa:	82a70713          	addi	a4,a4,-2006 # 800215d0 <devsw>
    80004dae:	97ba                	add	a5,a5,a4
    80004db0:	639c                	ld	a5,0(a5)
    80004db2:	c38d                	beqz	a5,80004dd4 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004db4:	4505                	li	a0,1
    80004db6:	9782                	jalr	a5
    80004db8:	892a                	mv	s2,a0
    80004dba:	bf75                	j	80004d76 <fileread+0x60>
    panic("fileread");
    80004dbc:	00004517          	auipc	a0,0x4
    80004dc0:	a4c50513          	addi	a0,a0,-1460 # 80008808 <syscalls+0x268>
    80004dc4:	ffffc097          	auipc	ra,0xffffc
    80004dc8:	b3a080e7          	jalr	-1222(ra) # 800008fe <panic>
    return -1;
    80004dcc:	597d                	li	s2,-1
    80004dce:	b765                	j	80004d76 <fileread+0x60>
      return -1;
    80004dd0:	597d                	li	s2,-1
    80004dd2:	b755                	j	80004d76 <fileread+0x60>
    80004dd4:	597d                	li	s2,-1
    80004dd6:	b745                	j	80004d76 <fileread+0x60>

0000000080004dd8 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004dd8:	715d                	addi	sp,sp,-80
    80004dda:	e486                	sd	ra,72(sp)
    80004ddc:	e0a2                	sd	s0,64(sp)
    80004dde:	fc26                	sd	s1,56(sp)
    80004de0:	f84a                	sd	s2,48(sp)
    80004de2:	f44e                	sd	s3,40(sp)
    80004de4:	f052                	sd	s4,32(sp)
    80004de6:	ec56                	sd	s5,24(sp)
    80004de8:	e85a                	sd	s6,16(sp)
    80004dea:	e45e                	sd	s7,8(sp)
    80004dec:	e062                	sd	s8,0(sp)
    80004dee:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004df0:	00954783          	lbu	a5,9(a0)
    80004df4:	10078663          	beqz	a5,80004f00 <filewrite+0x128>
    80004df8:	892a                	mv	s2,a0
    80004dfa:	8aae                	mv	s5,a1
    80004dfc:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004dfe:	411c                	lw	a5,0(a0)
    80004e00:	4705                	li	a4,1
    80004e02:	02e78263          	beq	a5,a4,80004e26 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004e06:	470d                	li	a4,3
    80004e08:	02e78663          	beq	a5,a4,80004e34 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004e0c:	4709                	li	a4,2
    80004e0e:	0ee79163          	bne	a5,a4,80004ef0 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004e12:	0ac05d63          	blez	a2,80004ecc <filewrite+0xf4>
    int i = 0;
    80004e16:	4981                	li	s3,0
    80004e18:	6b05                	lui	s6,0x1
    80004e1a:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004e1e:	6b85                	lui	s7,0x1
    80004e20:	c00b8b9b          	addiw	s7,s7,-1024
    80004e24:	a861                	j	80004ebc <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004e26:	6908                	ld	a0,16(a0)
    80004e28:	00000097          	auipc	ra,0x0
    80004e2c:	22e080e7          	jalr	558(ra) # 80005056 <pipewrite>
    80004e30:	8a2a                	mv	s4,a0
    80004e32:	a045                	j	80004ed2 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004e34:	02451783          	lh	a5,36(a0)
    80004e38:	03079693          	slli	a3,a5,0x30
    80004e3c:	92c1                	srli	a3,a3,0x30
    80004e3e:	4725                	li	a4,9
    80004e40:	0cd76263          	bltu	a4,a3,80004f04 <filewrite+0x12c>
    80004e44:	0792                	slli	a5,a5,0x4
    80004e46:	0001c717          	auipc	a4,0x1c
    80004e4a:	78a70713          	addi	a4,a4,1930 # 800215d0 <devsw>
    80004e4e:	97ba                	add	a5,a5,a4
    80004e50:	679c                	ld	a5,8(a5)
    80004e52:	cbdd                	beqz	a5,80004f08 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004e54:	4505                	li	a0,1
    80004e56:	9782                	jalr	a5
    80004e58:	8a2a                	mv	s4,a0
    80004e5a:	a8a5                	j	80004ed2 <filewrite+0xfa>
    80004e5c:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004e60:	00000097          	auipc	ra,0x0
    80004e64:	8b0080e7          	jalr	-1872(ra) # 80004710 <begin_op>
      ilock(f->ip);
    80004e68:	01893503          	ld	a0,24(s2)
    80004e6c:	fffff097          	auipc	ra,0xfffff
    80004e70:	ee2080e7          	jalr	-286(ra) # 80003d4e <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004e74:	8762                	mv	a4,s8
    80004e76:	02092683          	lw	a3,32(s2)
    80004e7a:	01598633          	add	a2,s3,s5
    80004e7e:	4585                	li	a1,1
    80004e80:	01893503          	ld	a0,24(s2)
    80004e84:	fffff097          	auipc	ra,0xfffff
    80004e88:	276080e7          	jalr	630(ra) # 800040fa <writei>
    80004e8c:	84aa                	mv	s1,a0
    80004e8e:	00a05763          	blez	a0,80004e9c <filewrite+0xc4>
        f->off += r;
    80004e92:	02092783          	lw	a5,32(s2)
    80004e96:	9fa9                	addw	a5,a5,a0
    80004e98:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004e9c:	01893503          	ld	a0,24(s2)
    80004ea0:	fffff097          	auipc	ra,0xfffff
    80004ea4:	f70080e7          	jalr	-144(ra) # 80003e10 <iunlock>
      end_op();
    80004ea8:	00000097          	auipc	ra,0x0
    80004eac:	8e8080e7          	jalr	-1816(ra) # 80004790 <end_op>

      if(r != n1){
    80004eb0:	009c1f63          	bne	s8,s1,80004ece <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004eb4:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004eb8:	0149db63          	bge	s3,s4,80004ece <filewrite+0xf6>
      int n1 = n - i;
    80004ebc:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004ec0:	84be                	mv	s1,a5
    80004ec2:	2781                	sext.w	a5,a5
    80004ec4:	f8fb5ce3          	bge	s6,a5,80004e5c <filewrite+0x84>
    80004ec8:	84de                	mv	s1,s7
    80004eca:	bf49                	j	80004e5c <filewrite+0x84>
    int i = 0;
    80004ecc:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004ece:	013a1f63          	bne	s4,s3,80004eec <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004ed2:	8552                	mv	a0,s4
    80004ed4:	60a6                	ld	ra,72(sp)
    80004ed6:	6406                	ld	s0,64(sp)
    80004ed8:	74e2                	ld	s1,56(sp)
    80004eda:	7942                	ld	s2,48(sp)
    80004edc:	79a2                	ld	s3,40(sp)
    80004ede:	7a02                	ld	s4,32(sp)
    80004ee0:	6ae2                	ld	s5,24(sp)
    80004ee2:	6b42                	ld	s6,16(sp)
    80004ee4:	6ba2                	ld	s7,8(sp)
    80004ee6:	6c02                	ld	s8,0(sp)
    80004ee8:	6161                	addi	sp,sp,80
    80004eea:	8082                	ret
    ret = (i == n ? n : -1);
    80004eec:	5a7d                	li	s4,-1
    80004eee:	b7d5                	j	80004ed2 <filewrite+0xfa>
    panic("filewrite");
    80004ef0:	00004517          	auipc	a0,0x4
    80004ef4:	92850513          	addi	a0,a0,-1752 # 80008818 <syscalls+0x278>
    80004ef8:	ffffc097          	auipc	ra,0xffffc
    80004efc:	a06080e7          	jalr	-1530(ra) # 800008fe <panic>
    return -1;
    80004f00:	5a7d                	li	s4,-1
    80004f02:	bfc1                	j	80004ed2 <filewrite+0xfa>
      return -1;
    80004f04:	5a7d                	li	s4,-1
    80004f06:	b7f1                	j	80004ed2 <filewrite+0xfa>
    80004f08:	5a7d                	li	s4,-1
    80004f0a:	b7e1                	j	80004ed2 <filewrite+0xfa>

0000000080004f0c <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004f0c:	7179                	addi	sp,sp,-48
    80004f0e:	f406                	sd	ra,40(sp)
    80004f10:	f022                	sd	s0,32(sp)
    80004f12:	ec26                	sd	s1,24(sp)
    80004f14:	e84a                	sd	s2,16(sp)
    80004f16:	e44e                	sd	s3,8(sp)
    80004f18:	e052                	sd	s4,0(sp)
    80004f1a:	1800                	addi	s0,sp,48
    80004f1c:	84aa                	mv	s1,a0
    80004f1e:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004f20:	0005b023          	sd	zero,0(a1)
    80004f24:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004f28:	00000097          	auipc	ra,0x0
    80004f2c:	bf8080e7          	jalr	-1032(ra) # 80004b20 <filealloc>
    80004f30:	e088                	sd	a0,0(s1)
    80004f32:	c551                	beqz	a0,80004fbe <pipealloc+0xb2>
    80004f34:	00000097          	auipc	ra,0x0
    80004f38:	bec080e7          	jalr	-1044(ra) # 80004b20 <filealloc>
    80004f3c:	00aa3023          	sd	a0,0(s4)
    80004f40:	c92d                	beqz	a0,80004fb2 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004f42:	ffffc097          	auipc	ra,0xffffc
    80004f46:	f64080e7          	jalr	-156(ra) # 80000ea6 <kalloc>
    80004f4a:	892a                	mv	s2,a0
    80004f4c:	c125                	beqz	a0,80004fac <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004f4e:	4985                	li	s3,1
    80004f50:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004f54:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004f58:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004f5c:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004f60:	00004597          	auipc	a1,0x4
    80004f64:	8c858593          	addi	a1,a1,-1848 # 80008828 <syscalls+0x288>
    80004f68:	ffffc097          	auipc	ra,0xffffc
    80004f6c:	f9e080e7          	jalr	-98(ra) # 80000f06 <initlock>
  (*f0)->type = FD_PIPE;
    80004f70:	609c                	ld	a5,0(s1)
    80004f72:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004f76:	609c                	ld	a5,0(s1)
    80004f78:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004f7c:	609c                	ld	a5,0(s1)
    80004f7e:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004f82:	609c                	ld	a5,0(s1)
    80004f84:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004f88:	000a3783          	ld	a5,0(s4)
    80004f8c:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004f90:	000a3783          	ld	a5,0(s4)
    80004f94:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004f98:	000a3783          	ld	a5,0(s4)
    80004f9c:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004fa0:	000a3783          	ld	a5,0(s4)
    80004fa4:	0127b823          	sd	s2,16(a5)
  return 0;
    80004fa8:	4501                	li	a0,0
    80004faa:	a025                	j	80004fd2 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004fac:	6088                	ld	a0,0(s1)
    80004fae:	e501                	bnez	a0,80004fb6 <pipealloc+0xaa>
    80004fb0:	a039                	j	80004fbe <pipealloc+0xb2>
    80004fb2:	6088                	ld	a0,0(s1)
    80004fb4:	c51d                	beqz	a0,80004fe2 <pipealloc+0xd6>
    fileclose(*f0);
    80004fb6:	00000097          	auipc	ra,0x0
    80004fba:	c26080e7          	jalr	-986(ra) # 80004bdc <fileclose>
  if(*f1)
    80004fbe:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004fc2:	557d                	li	a0,-1
  if(*f1)
    80004fc4:	c799                	beqz	a5,80004fd2 <pipealloc+0xc6>
    fileclose(*f1);
    80004fc6:	853e                	mv	a0,a5
    80004fc8:	00000097          	auipc	ra,0x0
    80004fcc:	c14080e7          	jalr	-1004(ra) # 80004bdc <fileclose>
  return -1;
    80004fd0:	557d                	li	a0,-1
}
    80004fd2:	70a2                	ld	ra,40(sp)
    80004fd4:	7402                	ld	s0,32(sp)
    80004fd6:	64e2                	ld	s1,24(sp)
    80004fd8:	6942                	ld	s2,16(sp)
    80004fda:	69a2                	ld	s3,8(sp)
    80004fdc:	6a02                	ld	s4,0(sp)
    80004fde:	6145                	addi	sp,sp,48
    80004fe0:	8082                	ret
  return -1;
    80004fe2:	557d                	li	a0,-1
    80004fe4:	b7fd                	j	80004fd2 <pipealloc+0xc6>

0000000080004fe6 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004fe6:	1101                	addi	sp,sp,-32
    80004fe8:	ec06                	sd	ra,24(sp)
    80004fea:	e822                	sd	s0,16(sp)
    80004fec:	e426                	sd	s1,8(sp)
    80004fee:	e04a                	sd	s2,0(sp)
    80004ff0:	1000                	addi	s0,sp,32
    80004ff2:	84aa                	mv	s1,a0
    80004ff4:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004ff6:	ffffc097          	auipc	ra,0xffffc
    80004ffa:	fa0080e7          	jalr	-96(ra) # 80000f96 <acquire>
  if(writable){
    80004ffe:	02090d63          	beqz	s2,80005038 <pipeclose+0x52>
    pi->writeopen = 0;
    80005002:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005006:	21848513          	addi	a0,s1,536
    8000500a:	ffffd097          	auipc	ra,0xffffd
    8000500e:	46e080e7          	jalr	1134(ra) # 80002478 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005012:	2204b783          	ld	a5,544(s1)
    80005016:	eb95                	bnez	a5,8000504a <pipeclose+0x64>
    release(&pi->lock);
    80005018:	8526                	mv	a0,s1
    8000501a:	ffffc097          	auipc	ra,0xffffc
    8000501e:	030080e7          	jalr	48(ra) # 8000104a <release>
    kfree((char*)pi);
    80005022:	8526                	mv	a0,s1
    80005024:	ffffc097          	auipc	ra,0xffffc
    80005028:	d86080e7          	jalr	-634(ra) # 80000daa <kfree>
  } else
    release(&pi->lock);
}
    8000502c:	60e2                	ld	ra,24(sp)
    8000502e:	6442                	ld	s0,16(sp)
    80005030:	64a2                	ld	s1,8(sp)
    80005032:	6902                	ld	s2,0(sp)
    80005034:	6105                	addi	sp,sp,32
    80005036:	8082                	ret
    pi->readopen = 0;
    80005038:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    8000503c:	21c48513          	addi	a0,s1,540
    80005040:	ffffd097          	auipc	ra,0xffffd
    80005044:	438080e7          	jalr	1080(ra) # 80002478 <wakeup>
    80005048:	b7e9                	j	80005012 <pipeclose+0x2c>
    release(&pi->lock);
    8000504a:	8526                	mv	a0,s1
    8000504c:	ffffc097          	auipc	ra,0xffffc
    80005050:	ffe080e7          	jalr	-2(ra) # 8000104a <release>
}
    80005054:	bfe1                	j	8000502c <pipeclose+0x46>

0000000080005056 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005056:	711d                	addi	sp,sp,-96
    80005058:	ec86                	sd	ra,88(sp)
    8000505a:	e8a2                	sd	s0,80(sp)
    8000505c:	e4a6                	sd	s1,72(sp)
    8000505e:	e0ca                	sd	s2,64(sp)
    80005060:	fc4e                	sd	s3,56(sp)
    80005062:	f852                	sd	s4,48(sp)
    80005064:	f456                	sd	s5,40(sp)
    80005066:	f05a                	sd	s6,32(sp)
    80005068:	ec5e                	sd	s7,24(sp)
    8000506a:	e862                	sd	s8,16(sp)
    8000506c:	1080                	addi	s0,sp,96
    8000506e:	84aa                	mv	s1,a0
    80005070:	8aae                	mv	s5,a1
    80005072:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005074:	ffffd097          	auipc	ra,0xffffd
    80005078:	cf8080e7          	jalr	-776(ra) # 80001d6c <myproc>
    8000507c:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000507e:	8526                	mv	a0,s1
    80005080:	ffffc097          	auipc	ra,0xffffc
    80005084:	f16080e7          	jalr	-234(ra) # 80000f96 <acquire>
  while(i < n){
    80005088:	0b405663          	blez	s4,80005134 <pipewrite+0xde>
  int i = 0;
    8000508c:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000508e:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005090:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005094:	21c48b93          	addi	s7,s1,540
    80005098:	a089                	j	800050da <pipewrite+0x84>
      release(&pi->lock);
    8000509a:	8526                	mv	a0,s1
    8000509c:	ffffc097          	auipc	ra,0xffffc
    800050a0:	fae080e7          	jalr	-82(ra) # 8000104a <release>
      return -1;
    800050a4:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800050a6:	854a                	mv	a0,s2
    800050a8:	60e6                	ld	ra,88(sp)
    800050aa:	6446                	ld	s0,80(sp)
    800050ac:	64a6                	ld	s1,72(sp)
    800050ae:	6906                	ld	s2,64(sp)
    800050b0:	79e2                	ld	s3,56(sp)
    800050b2:	7a42                	ld	s4,48(sp)
    800050b4:	7aa2                	ld	s5,40(sp)
    800050b6:	7b02                	ld	s6,32(sp)
    800050b8:	6be2                	ld	s7,24(sp)
    800050ba:	6c42                	ld	s8,16(sp)
    800050bc:	6125                	addi	sp,sp,96
    800050be:	8082                	ret
      wakeup(&pi->nread);
    800050c0:	8562                	mv	a0,s8
    800050c2:	ffffd097          	auipc	ra,0xffffd
    800050c6:	3b6080e7          	jalr	950(ra) # 80002478 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800050ca:	85a6                	mv	a1,s1
    800050cc:	855e                	mv	a0,s7
    800050ce:	ffffd097          	auipc	ra,0xffffd
    800050d2:	346080e7          	jalr	838(ra) # 80002414 <sleep>
  while(i < n){
    800050d6:	07495063          	bge	s2,s4,80005136 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    800050da:	2204a783          	lw	a5,544(s1)
    800050de:	dfd5                	beqz	a5,8000509a <pipewrite+0x44>
    800050e0:	854e                	mv	a0,s3
    800050e2:	ffffd097          	auipc	ra,0xffffd
    800050e6:	5da080e7          	jalr	1498(ra) # 800026bc <killed>
    800050ea:	f945                	bnez	a0,8000509a <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800050ec:	2184a783          	lw	a5,536(s1)
    800050f0:	21c4a703          	lw	a4,540(s1)
    800050f4:	2007879b          	addiw	a5,a5,512
    800050f8:	fcf704e3          	beq	a4,a5,800050c0 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800050fc:	4685                	li	a3,1
    800050fe:	01590633          	add	a2,s2,s5
    80005102:	faf40593          	addi	a1,s0,-81
    80005106:	0509b503          	ld	a0,80(s3)
    8000510a:	ffffd097          	auipc	ra,0xffffd
    8000510e:	9aa080e7          	jalr	-1622(ra) # 80001ab4 <copyin>
    80005112:	03650263          	beq	a0,s6,80005136 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005116:	21c4a783          	lw	a5,540(s1)
    8000511a:	0017871b          	addiw	a4,a5,1
    8000511e:	20e4ae23          	sw	a4,540(s1)
    80005122:	1ff7f793          	andi	a5,a5,511
    80005126:	97a6                	add	a5,a5,s1
    80005128:	faf44703          	lbu	a4,-81(s0)
    8000512c:	00e78c23          	sb	a4,24(a5)
      i++;
    80005130:	2905                	addiw	s2,s2,1
    80005132:	b755                	j	800050d6 <pipewrite+0x80>
  int i = 0;
    80005134:	4901                	li	s2,0
  wakeup(&pi->nread);
    80005136:	21848513          	addi	a0,s1,536
    8000513a:	ffffd097          	auipc	ra,0xffffd
    8000513e:	33e080e7          	jalr	830(ra) # 80002478 <wakeup>
  release(&pi->lock);
    80005142:	8526                	mv	a0,s1
    80005144:	ffffc097          	auipc	ra,0xffffc
    80005148:	f06080e7          	jalr	-250(ra) # 8000104a <release>
  return i;
    8000514c:	bfa9                	j	800050a6 <pipewrite+0x50>

000000008000514e <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    8000514e:	715d                	addi	sp,sp,-80
    80005150:	e486                	sd	ra,72(sp)
    80005152:	e0a2                	sd	s0,64(sp)
    80005154:	fc26                	sd	s1,56(sp)
    80005156:	f84a                	sd	s2,48(sp)
    80005158:	f44e                	sd	s3,40(sp)
    8000515a:	f052                	sd	s4,32(sp)
    8000515c:	ec56                	sd	s5,24(sp)
    8000515e:	e85a                	sd	s6,16(sp)
    80005160:	0880                	addi	s0,sp,80
    80005162:	84aa                	mv	s1,a0
    80005164:	892e                	mv	s2,a1
    80005166:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005168:	ffffd097          	auipc	ra,0xffffd
    8000516c:	c04080e7          	jalr	-1020(ra) # 80001d6c <myproc>
    80005170:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005172:	8526                	mv	a0,s1
    80005174:	ffffc097          	auipc	ra,0xffffc
    80005178:	e22080e7          	jalr	-478(ra) # 80000f96 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000517c:	2184a703          	lw	a4,536(s1)
    80005180:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005184:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005188:	02f71763          	bne	a4,a5,800051b6 <piperead+0x68>
    8000518c:	2244a783          	lw	a5,548(s1)
    80005190:	c39d                	beqz	a5,800051b6 <piperead+0x68>
    if(killed(pr)){
    80005192:	8552                	mv	a0,s4
    80005194:	ffffd097          	auipc	ra,0xffffd
    80005198:	528080e7          	jalr	1320(ra) # 800026bc <killed>
    8000519c:	e941                	bnez	a0,8000522c <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000519e:	85a6                	mv	a1,s1
    800051a0:	854e                	mv	a0,s3
    800051a2:	ffffd097          	auipc	ra,0xffffd
    800051a6:	272080e7          	jalr	626(ra) # 80002414 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800051aa:	2184a703          	lw	a4,536(s1)
    800051ae:	21c4a783          	lw	a5,540(s1)
    800051b2:	fcf70de3          	beq	a4,a5,8000518c <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800051b6:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800051b8:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800051ba:	05505363          	blez	s5,80005200 <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    800051be:	2184a783          	lw	a5,536(s1)
    800051c2:	21c4a703          	lw	a4,540(s1)
    800051c6:	02f70d63          	beq	a4,a5,80005200 <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800051ca:	0017871b          	addiw	a4,a5,1
    800051ce:	20e4ac23          	sw	a4,536(s1)
    800051d2:	1ff7f793          	andi	a5,a5,511
    800051d6:	97a6                	add	a5,a5,s1
    800051d8:	0187c783          	lbu	a5,24(a5)
    800051dc:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800051e0:	4685                	li	a3,1
    800051e2:	fbf40613          	addi	a2,s0,-65
    800051e6:	85ca                	mv	a1,s2
    800051e8:	050a3503          	ld	a0,80(s4)
    800051ec:	ffffd097          	auipc	ra,0xffffd
    800051f0:	83c080e7          	jalr	-1988(ra) # 80001a28 <copyout>
    800051f4:	01650663          	beq	a0,s6,80005200 <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800051f8:	2985                	addiw	s3,s3,1
    800051fa:	0905                	addi	s2,s2,1
    800051fc:	fd3a91e3          	bne	s5,s3,800051be <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005200:	21c48513          	addi	a0,s1,540
    80005204:	ffffd097          	auipc	ra,0xffffd
    80005208:	274080e7          	jalr	628(ra) # 80002478 <wakeup>
  release(&pi->lock);
    8000520c:	8526                	mv	a0,s1
    8000520e:	ffffc097          	auipc	ra,0xffffc
    80005212:	e3c080e7          	jalr	-452(ra) # 8000104a <release>
  return i;
}
    80005216:	854e                	mv	a0,s3
    80005218:	60a6                	ld	ra,72(sp)
    8000521a:	6406                	ld	s0,64(sp)
    8000521c:	74e2                	ld	s1,56(sp)
    8000521e:	7942                	ld	s2,48(sp)
    80005220:	79a2                	ld	s3,40(sp)
    80005222:	7a02                	ld	s4,32(sp)
    80005224:	6ae2                	ld	s5,24(sp)
    80005226:	6b42                	ld	s6,16(sp)
    80005228:	6161                	addi	sp,sp,80
    8000522a:	8082                	ret
      release(&pi->lock);
    8000522c:	8526                	mv	a0,s1
    8000522e:	ffffc097          	auipc	ra,0xffffc
    80005232:	e1c080e7          	jalr	-484(ra) # 8000104a <release>
      return -1;
    80005236:	59fd                	li	s3,-1
    80005238:	bff9                	j	80005216 <piperead+0xc8>

000000008000523a <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    8000523a:	1141                	addi	sp,sp,-16
    8000523c:	e422                	sd	s0,8(sp)
    8000523e:	0800                	addi	s0,sp,16
    80005240:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80005242:	8905                	andi	a0,a0,1
    80005244:	c111                	beqz	a0,80005248 <flags2perm+0xe>
      perm = PTE_X;
    80005246:	4521                	li	a0,8
    if(flags & 0x2)
    80005248:	8b89                	andi	a5,a5,2
    8000524a:	c399                	beqz	a5,80005250 <flags2perm+0x16>
      perm |= PTE_W;
    8000524c:	00456513          	ori	a0,a0,4
    return perm;
}
    80005250:	6422                	ld	s0,8(sp)
    80005252:	0141                	addi	sp,sp,16
    80005254:	8082                	ret

0000000080005256 <exec>:

int
exec(char *path, char **argv)
{
    80005256:	de010113          	addi	sp,sp,-544
    8000525a:	20113c23          	sd	ra,536(sp)
    8000525e:	20813823          	sd	s0,528(sp)
    80005262:	20913423          	sd	s1,520(sp)
    80005266:	21213023          	sd	s2,512(sp)
    8000526a:	ffce                	sd	s3,504(sp)
    8000526c:	fbd2                	sd	s4,496(sp)
    8000526e:	f7d6                	sd	s5,488(sp)
    80005270:	f3da                	sd	s6,480(sp)
    80005272:	efde                	sd	s7,472(sp)
    80005274:	ebe2                	sd	s8,464(sp)
    80005276:	e7e6                	sd	s9,456(sp)
    80005278:	e3ea                	sd	s10,448(sp)
    8000527a:	ff6e                	sd	s11,440(sp)
    8000527c:	1400                	addi	s0,sp,544
    8000527e:	892a                	mv	s2,a0
    80005280:	dea43423          	sd	a0,-536(s0)
    80005284:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005288:	ffffd097          	auipc	ra,0xffffd
    8000528c:	ae4080e7          	jalr	-1308(ra) # 80001d6c <myproc>
    80005290:	84aa                	mv	s1,a0

  begin_op();
    80005292:	fffff097          	auipc	ra,0xfffff
    80005296:	47e080e7          	jalr	1150(ra) # 80004710 <begin_op>

  if((ip = namei(path)) == 0){
    8000529a:	854a                	mv	a0,s2
    8000529c:	fffff097          	auipc	ra,0xfffff
    800052a0:	258080e7          	jalr	600(ra) # 800044f4 <namei>
    800052a4:	c93d                	beqz	a0,8000531a <exec+0xc4>
    800052a6:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800052a8:	fffff097          	auipc	ra,0xfffff
    800052ac:	aa6080e7          	jalr	-1370(ra) # 80003d4e <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800052b0:	04000713          	li	a4,64
    800052b4:	4681                	li	a3,0
    800052b6:	e5040613          	addi	a2,s0,-432
    800052ba:	4581                	li	a1,0
    800052bc:	8556                	mv	a0,s5
    800052be:	fffff097          	auipc	ra,0xfffff
    800052c2:	d44080e7          	jalr	-700(ra) # 80004002 <readi>
    800052c6:	04000793          	li	a5,64
    800052ca:	00f51a63          	bne	a0,a5,800052de <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    800052ce:	e5042703          	lw	a4,-432(s0)
    800052d2:	464c47b7          	lui	a5,0x464c4
    800052d6:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800052da:	04f70663          	beq	a4,a5,80005326 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800052de:	8556                	mv	a0,s5
    800052e0:	fffff097          	auipc	ra,0xfffff
    800052e4:	cd0080e7          	jalr	-816(ra) # 80003fb0 <iunlockput>
    end_op();
    800052e8:	fffff097          	auipc	ra,0xfffff
    800052ec:	4a8080e7          	jalr	1192(ra) # 80004790 <end_op>
  }
  return -1;
    800052f0:	557d                	li	a0,-1
}
    800052f2:	21813083          	ld	ra,536(sp)
    800052f6:	21013403          	ld	s0,528(sp)
    800052fa:	20813483          	ld	s1,520(sp)
    800052fe:	20013903          	ld	s2,512(sp)
    80005302:	79fe                	ld	s3,504(sp)
    80005304:	7a5e                	ld	s4,496(sp)
    80005306:	7abe                	ld	s5,488(sp)
    80005308:	7b1e                	ld	s6,480(sp)
    8000530a:	6bfe                	ld	s7,472(sp)
    8000530c:	6c5e                	ld	s8,464(sp)
    8000530e:	6cbe                	ld	s9,456(sp)
    80005310:	6d1e                	ld	s10,448(sp)
    80005312:	7dfa                	ld	s11,440(sp)
    80005314:	22010113          	addi	sp,sp,544
    80005318:	8082                	ret
    end_op();
    8000531a:	fffff097          	auipc	ra,0xfffff
    8000531e:	476080e7          	jalr	1142(ra) # 80004790 <end_op>
    return -1;
    80005322:	557d                	li	a0,-1
    80005324:	b7f9                	j	800052f2 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80005326:	8526                	mv	a0,s1
    80005328:	ffffd097          	auipc	ra,0xffffd
    8000532c:	b08080e7          	jalr	-1272(ra) # 80001e30 <proc_pagetable>
    80005330:	8b2a                	mv	s6,a0
    80005332:	d555                	beqz	a0,800052de <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005334:	e7042783          	lw	a5,-400(s0)
    80005338:	e8845703          	lhu	a4,-376(s0)
    8000533c:	c735                	beqz	a4,800053a8 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000533e:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005340:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80005344:	6a05                	lui	s4,0x1
    80005346:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    8000534a:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    8000534e:	6d85                	lui	s11,0x1
    80005350:	7d7d                	lui	s10,0xfffff
    80005352:	a481                	j	80005592 <exec+0x33c>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005354:	00003517          	auipc	a0,0x3
    80005358:	4dc50513          	addi	a0,a0,1244 # 80008830 <syscalls+0x290>
    8000535c:	ffffb097          	auipc	ra,0xffffb
    80005360:	5a2080e7          	jalr	1442(ra) # 800008fe <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005364:	874a                	mv	a4,s2
    80005366:	009c86bb          	addw	a3,s9,s1
    8000536a:	4581                	li	a1,0
    8000536c:	8556                	mv	a0,s5
    8000536e:	fffff097          	auipc	ra,0xfffff
    80005372:	c94080e7          	jalr	-876(ra) # 80004002 <readi>
    80005376:	2501                	sext.w	a0,a0
    80005378:	1aa91a63          	bne	s2,a0,8000552c <exec+0x2d6>
  for(i = 0; i < sz; i += PGSIZE){
    8000537c:	009d84bb          	addw	s1,s11,s1
    80005380:	013d09bb          	addw	s3,s10,s3
    80005384:	1f74f763          	bgeu	s1,s7,80005572 <exec+0x31c>
    pa = walkaddr(pagetable, va + i);
    80005388:	02049593          	slli	a1,s1,0x20
    8000538c:	9181                	srli	a1,a1,0x20
    8000538e:	95e2                	add	a1,a1,s8
    80005390:	855a                	mv	a0,s6
    80005392:	ffffc097          	auipc	ra,0xffffc
    80005396:	08a080e7          	jalr	138(ra) # 8000141c <walkaddr>
    8000539a:	862a                	mv	a2,a0
    if(pa == 0)
    8000539c:	dd45                	beqz	a0,80005354 <exec+0xfe>
      n = PGSIZE;
    8000539e:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    800053a0:	fd49f2e3          	bgeu	s3,s4,80005364 <exec+0x10e>
      n = sz - i;
    800053a4:	894e                	mv	s2,s3
    800053a6:	bf7d                	j	80005364 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800053a8:	4901                	li	s2,0
  iunlockput(ip);
    800053aa:	8556                	mv	a0,s5
    800053ac:	fffff097          	auipc	ra,0xfffff
    800053b0:	c04080e7          	jalr	-1020(ra) # 80003fb0 <iunlockput>
  end_op();
    800053b4:	fffff097          	auipc	ra,0xfffff
    800053b8:	3dc080e7          	jalr	988(ra) # 80004790 <end_op>
  p = myproc();
    800053bc:	ffffd097          	auipc	ra,0xffffd
    800053c0:	9b0080e7          	jalr	-1616(ra) # 80001d6c <myproc>
    800053c4:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    800053c6:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    800053ca:	6785                	lui	a5,0x1
    800053cc:	17fd                	addi	a5,a5,-1
    800053ce:	993e                	add	s2,s2,a5
    800053d0:	77fd                	lui	a5,0xfffff
    800053d2:	00f977b3          	and	a5,s2,a5
    800053d6:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800053da:	4691                	li	a3,4
    800053dc:	6609                	lui	a2,0x2
    800053de:	963e                	add	a2,a2,a5
    800053e0:	85be                	mv	a1,a5
    800053e2:	855a                	mv	a0,s6
    800053e4:	ffffc097          	auipc	ra,0xffffc
    800053e8:	3ec080e7          	jalr	1004(ra) # 800017d0 <uvmalloc>
    800053ec:	8c2a                	mv	s8,a0
  ip = 0;
    800053ee:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800053f0:	12050e63          	beqz	a0,8000552c <exec+0x2d6>
  uvmclear(pagetable, sz-2*PGSIZE);
    800053f4:	75f9                	lui	a1,0xffffe
    800053f6:	95aa                	add	a1,a1,a0
    800053f8:	855a                	mv	a0,s6
    800053fa:	ffffc097          	auipc	ra,0xffffc
    800053fe:	5fc080e7          	jalr	1532(ra) # 800019f6 <uvmclear>
  stackbase = sp - PGSIZE;
    80005402:	7afd                	lui	s5,0xfffff
    80005404:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80005406:	df043783          	ld	a5,-528(s0)
    8000540a:	6388                	ld	a0,0(a5)
    8000540c:	c925                	beqz	a0,8000547c <exec+0x226>
    8000540e:	e9040993          	addi	s3,s0,-368
    80005412:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005416:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005418:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    8000541a:	ffffc097          	auipc	ra,0xffffc
    8000541e:	df4080e7          	jalr	-524(ra) # 8000120e <strlen>
    80005422:	0015079b          	addiw	a5,a0,1
    80005426:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000542a:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    8000542e:	13596663          	bltu	s2,s5,8000555a <exec+0x304>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005432:	df043d83          	ld	s11,-528(s0)
    80005436:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    8000543a:	8552                	mv	a0,s4
    8000543c:	ffffc097          	auipc	ra,0xffffc
    80005440:	dd2080e7          	jalr	-558(ra) # 8000120e <strlen>
    80005444:	0015069b          	addiw	a3,a0,1
    80005448:	8652                	mv	a2,s4
    8000544a:	85ca                	mv	a1,s2
    8000544c:	855a                	mv	a0,s6
    8000544e:	ffffc097          	auipc	ra,0xffffc
    80005452:	5da080e7          	jalr	1498(ra) # 80001a28 <copyout>
    80005456:	10054663          	bltz	a0,80005562 <exec+0x30c>
    ustack[argc] = sp;
    8000545a:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000545e:	0485                	addi	s1,s1,1
    80005460:	008d8793          	addi	a5,s11,8
    80005464:	def43823          	sd	a5,-528(s0)
    80005468:	008db503          	ld	a0,8(s11)
    8000546c:	c911                	beqz	a0,80005480 <exec+0x22a>
    if(argc >= MAXARG)
    8000546e:	09a1                	addi	s3,s3,8
    80005470:	fb3c95e3          	bne	s9,s3,8000541a <exec+0x1c4>
  sz = sz1;
    80005474:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005478:	4a81                	li	s5,0
    8000547a:	a84d                	j	8000552c <exec+0x2d6>
  sp = sz;
    8000547c:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000547e:	4481                	li	s1,0
  ustack[argc] = 0;
    80005480:	00349793          	slli	a5,s1,0x3
    80005484:	f9040713          	addi	a4,s0,-112
    80005488:	97ba                	add	a5,a5,a4
    8000548a:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffdc798>
  sp -= (argc+1) * sizeof(uint64);
    8000548e:	00148693          	addi	a3,s1,1
    80005492:	068e                	slli	a3,a3,0x3
    80005494:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005498:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000549c:	01597663          	bgeu	s2,s5,800054a8 <exec+0x252>
  sz = sz1;
    800054a0:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800054a4:	4a81                	li	s5,0
    800054a6:	a059                	j	8000552c <exec+0x2d6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800054a8:	e9040613          	addi	a2,s0,-368
    800054ac:	85ca                	mv	a1,s2
    800054ae:	855a                	mv	a0,s6
    800054b0:	ffffc097          	auipc	ra,0xffffc
    800054b4:	578080e7          	jalr	1400(ra) # 80001a28 <copyout>
    800054b8:	0a054963          	bltz	a0,8000556a <exec+0x314>
  p->trapframe->a1 = sp;
    800054bc:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    800054c0:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800054c4:	de843783          	ld	a5,-536(s0)
    800054c8:	0007c703          	lbu	a4,0(a5)
    800054cc:	cf11                	beqz	a4,800054e8 <exec+0x292>
    800054ce:	0785                	addi	a5,a5,1
    if(*s == '/')
    800054d0:	02f00693          	li	a3,47
    800054d4:	a039                	j	800054e2 <exec+0x28c>
      last = s+1;
    800054d6:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    800054da:	0785                	addi	a5,a5,1
    800054dc:	fff7c703          	lbu	a4,-1(a5)
    800054e0:	c701                	beqz	a4,800054e8 <exec+0x292>
    if(*s == '/')
    800054e2:	fed71ce3          	bne	a4,a3,800054da <exec+0x284>
    800054e6:	bfc5                	j	800054d6 <exec+0x280>
  safestrcpy(p->name, last, sizeof(p->name));
    800054e8:	4641                	li	a2,16
    800054ea:	de843583          	ld	a1,-536(s0)
    800054ee:	158b8513          	addi	a0,s7,344
    800054f2:	ffffc097          	auipc	ra,0xffffc
    800054f6:	cea080e7          	jalr	-790(ra) # 800011dc <safestrcpy>
  oldpagetable = p->pagetable;
    800054fa:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    800054fe:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80005502:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005506:	058bb783          	ld	a5,88(s7)
    8000550a:	e6843703          	ld	a4,-408(s0)
    8000550e:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005510:	058bb783          	ld	a5,88(s7)
    80005514:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005518:	85ea                	mv	a1,s10
    8000551a:	ffffd097          	auipc	ra,0xffffd
    8000551e:	9b2080e7          	jalr	-1614(ra) # 80001ecc <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005522:	0004851b          	sext.w	a0,s1
    80005526:	b3f1                	j	800052f2 <exec+0x9c>
    80005528:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    8000552c:	df843583          	ld	a1,-520(s0)
    80005530:	855a                	mv	a0,s6
    80005532:	ffffd097          	auipc	ra,0xffffd
    80005536:	99a080e7          	jalr	-1638(ra) # 80001ecc <proc_freepagetable>
  if(ip){
    8000553a:	da0a92e3          	bnez	s5,800052de <exec+0x88>
  return -1;
    8000553e:	557d                	li	a0,-1
    80005540:	bb4d                	j	800052f2 <exec+0x9c>
    80005542:	df243c23          	sd	s2,-520(s0)
    80005546:	b7dd                	j	8000552c <exec+0x2d6>
    80005548:	df243c23          	sd	s2,-520(s0)
    8000554c:	b7c5                	j	8000552c <exec+0x2d6>
    8000554e:	df243c23          	sd	s2,-520(s0)
    80005552:	bfe9                	j	8000552c <exec+0x2d6>
    80005554:	df243c23          	sd	s2,-520(s0)
    80005558:	bfd1                	j	8000552c <exec+0x2d6>
  sz = sz1;
    8000555a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000555e:	4a81                	li	s5,0
    80005560:	b7f1                	j	8000552c <exec+0x2d6>
  sz = sz1;
    80005562:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005566:	4a81                	li	s5,0
    80005568:	b7d1                	j	8000552c <exec+0x2d6>
  sz = sz1;
    8000556a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000556e:	4a81                	li	s5,0
    80005570:	bf75                	j	8000552c <exec+0x2d6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005572:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005576:	e0843783          	ld	a5,-504(s0)
    8000557a:	0017869b          	addiw	a3,a5,1
    8000557e:	e0d43423          	sd	a3,-504(s0)
    80005582:	e0043783          	ld	a5,-512(s0)
    80005586:	0387879b          	addiw	a5,a5,56
    8000558a:	e8845703          	lhu	a4,-376(s0)
    8000558e:	e0e6dee3          	bge	a3,a4,800053aa <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005592:	2781                	sext.w	a5,a5
    80005594:	e0f43023          	sd	a5,-512(s0)
    80005598:	03800713          	li	a4,56
    8000559c:	86be                	mv	a3,a5
    8000559e:	e1840613          	addi	a2,s0,-488
    800055a2:	4581                	li	a1,0
    800055a4:	8556                	mv	a0,s5
    800055a6:	fffff097          	auipc	ra,0xfffff
    800055aa:	a5c080e7          	jalr	-1444(ra) # 80004002 <readi>
    800055ae:	03800793          	li	a5,56
    800055b2:	f6f51be3          	bne	a0,a5,80005528 <exec+0x2d2>
    if(ph.type != ELF_PROG_LOAD)
    800055b6:	e1842783          	lw	a5,-488(s0)
    800055ba:	4705                	li	a4,1
    800055bc:	fae79de3          	bne	a5,a4,80005576 <exec+0x320>
    if(ph.memsz < ph.filesz)
    800055c0:	e4043483          	ld	s1,-448(s0)
    800055c4:	e3843783          	ld	a5,-456(s0)
    800055c8:	f6f4ede3          	bltu	s1,a5,80005542 <exec+0x2ec>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800055cc:	e2843783          	ld	a5,-472(s0)
    800055d0:	94be                	add	s1,s1,a5
    800055d2:	f6f4ebe3          	bltu	s1,a5,80005548 <exec+0x2f2>
    if(ph.vaddr % PGSIZE != 0)
    800055d6:	de043703          	ld	a4,-544(s0)
    800055da:	8ff9                	and	a5,a5,a4
    800055dc:	fbad                	bnez	a5,8000554e <exec+0x2f8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800055de:	e1c42503          	lw	a0,-484(s0)
    800055e2:	00000097          	auipc	ra,0x0
    800055e6:	c58080e7          	jalr	-936(ra) # 8000523a <flags2perm>
    800055ea:	86aa                	mv	a3,a0
    800055ec:	8626                	mv	a2,s1
    800055ee:	85ca                	mv	a1,s2
    800055f0:	855a                	mv	a0,s6
    800055f2:	ffffc097          	auipc	ra,0xffffc
    800055f6:	1de080e7          	jalr	478(ra) # 800017d0 <uvmalloc>
    800055fa:	dea43c23          	sd	a0,-520(s0)
    800055fe:	d939                	beqz	a0,80005554 <exec+0x2fe>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005600:	e2843c03          	ld	s8,-472(s0)
    80005604:	e2042c83          	lw	s9,-480(s0)
    80005608:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000560c:	f60b83e3          	beqz	s7,80005572 <exec+0x31c>
    80005610:	89de                	mv	s3,s7
    80005612:	4481                	li	s1,0
    80005614:	bb95                	j	80005388 <exec+0x132>

0000000080005616 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005616:	7179                	addi	sp,sp,-48
    80005618:	f406                	sd	ra,40(sp)
    8000561a:	f022                	sd	s0,32(sp)
    8000561c:	ec26                	sd	s1,24(sp)
    8000561e:	e84a                	sd	s2,16(sp)
    80005620:	1800                	addi	s0,sp,48
    80005622:	892e                	mv	s2,a1
    80005624:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005626:	fdc40593          	addi	a1,s0,-36
    8000562a:	ffffe097          	auipc	ra,0xffffe
    8000562e:	b66080e7          	jalr	-1178(ra) # 80003190 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005632:	fdc42703          	lw	a4,-36(s0)
    80005636:	47bd                	li	a5,15
    80005638:	02e7eb63          	bltu	a5,a4,8000566e <argfd+0x58>
    8000563c:	ffffc097          	auipc	ra,0xffffc
    80005640:	730080e7          	jalr	1840(ra) # 80001d6c <myproc>
    80005644:	fdc42703          	lw	a4,-36(s0)
    80005648:	01a70793          	addi	a5,a4,26
    8000564c:	078e                	slli	a5,a5,0x3
    8000564e:	953e                	add	a0,a0,a5
    80005650:	611c                	ld	a5,0(a0)
    80005652:	c385                	beqz	a5,80005672 <argfd+0x5c>
    return -1;
  if(pfd)
    80005654:	00090463          	beqz	s2,8000565c <argfd+0x46>
    *pfd = fd;
    80005658:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000565c:	4501                	li	a0,0
  if(pf)
    8000565e:	c091                	beqz	s1,80005662 <argfd+0x4c>
    *pf = f;
    80005660:	e09c                	sd	a5,0(s1)
}
    80005662:	70a2                	ld	ra,40(sp)
    80005664:	7402                	ld	s0,32(sp)
    80005666:	64e2                	ld	s1,24(sp)
    80005668:	6942                	ld	s2,16(sp)
    8000566a:	6145                	addi	sp,sp,48
    8000566c:	8082                	ret
    return -1;
    8000566e:	557d                	li	a0,-1
    80005670:	bfcd                	j	80005662 <argfd+0x4c>
    80005672:	557d                	li	a0,-1
    80005674:	b7fd                	j	80005662 <argfd+0x4c>

0000000080005676 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005676:	1101                	addi	sp,sp,-32
    80005678:	ec06                	sd	ra,24(sp)
    8000567a:	e822                	sd	s0,16(sp)
    8000567c:	e426                	sd	s1,8(sp)
    8000567e:	1000                	addi	s0,sp,32
    80005680:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005682:	ffffc097          	auipc	ra,0xffffc
    80005686:	6ea080e7          	jalr	1770(ra) # 80001d6c <myproc>
    8000568a:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000568c:	0d050793          	addi	a5,a0,208
    80005690:	4501                	li	a0,0
    80005692:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005694:	6398                	ld	a4,0(a5)
    80005696:	cb19                	beqz	a4,800056ac <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005698:	2505                	addiw	a0,a0,1
    8000569a:	07a1                	addi	a5,a5,8
    8000569c:	fed51ce3          	bne	a0,a3,80005694 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800056a0:	557d                	li	a0,-1
}
    800056a2:	60e2                	ld	ra,24(sp)
    800056a4:	6442                	ld	s0,16(sp)
    800056a6:	64a2                	ld	s1,8(sp)
    800056a8:	6105                	addi	sp,sp,32
    800056aa:	8082                	ret
      p->ofile[fd] = f;
    800056ac:	01a50793          	addi	a5,a0,26
    800056b0:	078e                	slli	a5,a5,0x3
    800056b2:	963e                	add	a2,a2,a5
    800056b4:	e204                	sd	s1,0(a2)
      return fd;
    800056b6:	b7f5                	j	800056a2 <fdalloc+0x2c>

00000000800056b8 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800056b8:	715d                	addi	sp,sp,-80
    800056ba:	e486                	sd	ra,72(sp)
    800056bc:	e0a2                	sd	s0,64(sp)
    800056be:	fc26                	sd	s1,56(sp)
    800056c0:	f84a                	sd	s2,48(sp)
    800056c2:	f44e                	sd	s3,40(sp)
    800056c4:	f052                	sd	s4,32(sp)
    800056c6:	ec56                	sd	s5,24(sp)
    800056c8:	e85a                	sd	s6,16(sp)
    800056ca:	0880                	addi	s0,sp,80
    800056cc:	8b2e                	mv	s6,a1
    800056ce:	89b2                	mv	s3,a2
    800056d0:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800056d2:	fb040593          	addi	a1,s0,-80
    800056d6:	fffff097          	auipc	ra,0xfffff
    800056da:	e3c080e7          	jalr	-452(ra) # 80004512 <nameiparent>
    800056de:	84aa                	mv	s1,a0
    800056e0:	14050f63          	beqz	a0,8000583e <create+0x186>
    return 0;

  ilock(dp);
    800056e4:	ffffe097          	auipc	ra,0xffffe
    800056e8:	66a080e7          	jalr	1642(ra) # 80003d4e <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800056ec:	4601                	li	a2,0
    800056ee:	fb040593          	addi	a1,s0,-80
    800056f2:	8526                	mv	a0,s1
    800056f4:	fffff097          	auipc	ra,0xfffff
    800056f8:	b3e080e7          	jalr	-1218(ra) # 80004232 <dirlookup>
    800056fc:	8aaa                	mv	s5,a0
    800056fe:	c931                	beqz	a0,80005752 <create+0x9a>
    iunlockput(dp);
    80005700:	8526                	mv	a0,s1
    80005702:	fffff097          	auipc	ra,0xfffff
    80005706:	8ae080e7          	jalr	-1874(ra) # 80003fb0 <iunlockput>
    ilock(ip);
    8000570a:	8556                	mv	a0,s5
    8000570c:	ffffe097          	auipc	ra,0xffffe
    80005710:	642080e7          	jalr	1602(ra) # 80003d4e <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005714:	000b059b          	sext.w	a1,s6
    80005718:	4789                	li	a5,2
    8000571a:	02f59563          	bne	a1,a5,80005744 <create+0x8c>
    8000571e:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdc8dc>
    80005722:	37f9                	addiw	a5,a5,-2
    80005724:	17c2                	slli	a5,a5,0x30
    80005726:	93c1                	srli	a5,a5,0x30
    80005728:	4705                	li	a4,1
    8000572a:	00f76d63          	bltu	a4,a5,80005744 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    8000572e:	8556                	mv	a0,s5
    80005730:	60a6                	ld	ra,72(sp)
    80005732:	6406                	ld	s0,64(sp)
    80005734:	74e2                	ld	s1,56(sp)
    80005736:	7942                	ld	s2,48(sp)
    80005738:	79a2                	ld	s3,40(sp)
    8000573a:	7a02                	ld	s4,32(sp)
    8000573c:	6ae2                	ld	s5,24(sp)
    8000573e:	6b42                	ld	s6,16(sp)
    80005740:	6161                	addi	sp,sp,80
    80005742:	8082                	ret
    iunlockput(ip);
    80005744:	8556                	mv	a0,s5
    80005746:	fffff097          	auipc	ra,0xfffff
    8000574a:	86a080e7          	jalr	-1942(ra) # 80003fb0 <iunlockput>
    return 0;
    8000574e:	4a81                	li	s5,0
    80005750:	bff9                	j	8000572e <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005752:	85da                	mv	a1,s6
    80005754:	4088                	lw	a0,0(s1)
    80005756:	ffffe097          	auipc	ra,0xffffe
    8000575a:	45c080e7          	jalr	1116(ra) # 80003bb2 <ialloc>
    8000575e:	8a2a                	mv	s4,a0
    80005760:	c539                	beqz	a0,800057ae <create+0xf6>
  ilock(ip);
    80005762:	ffffe097          	auipc	ra,0xffffe
    80005766:	5ec080e7          	jalr	1516(ra) # 80003d4e <ilock>
  ip->major = major;
    8000576a:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    8000576e:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005772:	4905                	li	s2,1
    80005774:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005778:	8552                	mv	a0,s4
    8000577a:	ffffe097          	auipc	ra,0xffffe
    8000577e:	50a080e7          	jalr	1290(ra) # 80003c84 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005782:	000b059b          	sext.w	a1,s6
    80005786:	03258b63          	beq	a1,s2,800057bc <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    8000578a:	004a2603          	lw	a2,4(s4)
    8000578e:	fb040593          	addi	a1,s0,-80
    80005792:	8526                	mv	a0,s1
    80005794:	fffff097          	auipc	ra,0xfffff
    80005798:	cae080e7          	jalr	-850(ra) # 80004442 <dirlink>
    8000579c:	06054f63          	bltz	a0,8000581a <create+0x162>
  iunlockput(dp);
    800057a0:	8526                	mv	a0,s1
    800057a2:	fffff097          	auipc	ra,0xfffff
    800057a6:	80e080e7          	jalr	-2034(ra) # 80003fb0 <iunlockput>
  return ip;
    800057aa:	8ad2                	mv	s5,s4
    800057ac:	b749                	j	8000572e <create+0x76>
    iunlockput(dp);
    800057ae:	8526                	mv	a0,s1
    800057b0:	fffff097          	auipc	ra,0xfffff
    800057b4:	800080e7          	jalr	-2048(ra) # 80003fb0 <iunlockput>
    return 0;
    800057b8:	8ad2                	mv	s5,s4
    800057ba:	bf95                	j	8000572e <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800057bc:	004a2603          	lw	a2,4(s4)
    800057c0:	00003597          	auipc	a1,0x3
    800057c4:	09058593          	addi	a1,a1,144 # 80008850 <syscalls+0x2b0>
    800057c8:	8552                	mv	a0,s4
    800057ca:	fffff097          	auipc	ra,0xfffff
    800057ce:	c78080e7          	jalr	-904(ra) # 80004442 <dirlink>
    800057d2:	04054463          	bltz	a0,8000581a <create+0x162>
    800057d6:	40d0                	lw	a2,4(s1)
    800057d8:	00003597          	auipc	a1,0x3
    800057dc:	08058593          	addi	a1,a1,128 # 80008858 <syscalls+0x2b8>
    800057e0:	8552                	mv	a0,s4
    800057e2:	fffff097          	auipc	ra,0xfffff
    800057e6:	c60080e7          	jalr	-928(ra) # 80004442 <dirlink>
    800057ea:	02054863          	bltz	a0,8000581a <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    800057ee:	004a2603          	lw	a2,4(s4)
    800057f2:	fb040593          	addi	a1,s0,-80
    800057f6:	8526                	mv	a0,s1
    800057f8:	fffff097          	auipc	ra,0xfffff
    800057fc:	c4a080e7          	jalr	-950(ra) # 80004442 <dirlink>
    80005800:	00054d63          	bltz	a0,8000581a <create+0x162>
    dp->nlink++;  // for ".."
    80005804:	04a4d783          	lhu	a5,74(s1)
    80005808:	2785                	addiw	a5,a5,1
    8000580a:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000580e:	8526                	mv	a0,s1
    80005810:	ffffe097          	auipc	ra,0xffffe
    80005814:	474080e7          	jalr	1140(ra) # 80003c84 <iupdate>
    80005818:	b761                	j	800057a0 <create+0xe8>
  ip->nlink = 0;
    8000581a:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    8000581e:	8552                	mv	a0,s4
    80005820:	ffffe097          	auipc	ra,0xffffe
    80005824:	464080e7          	jalr	1124(ra) # 80003c84 <iupdate>
  iunlockput(ip);
    80005828:	8552                	mv	a0,s4
    8000582a:	ffffe097          	auipc	ra,0xffffe
    8000582e:	786080e7          	jalr	1926(ra) # 80003fb0 <iunlockput>
  iunlockput(dp);
    80005832:	8526                	mv	a0,s1
    80005834:	ffffe097          	auipc	ra,0xffffe
    80005838:	77c080e7          	jalr	1916(ra) # 80003fb0 <iunlockput>
  return 0;
    8000583c:	bdcd                	j	8000572e <create+0x76>
    return 0;
    8000583e:	8aaa                	mv	s5,a0
    80005840:	b5fd                	j	8000572e <create+0x76>

0000000080005842 <sys_dup>:
{
    80005842:	7179                	addi	sp,sp,-48
    80005844:	f406                	sd	ra,40(sp)
    80005846:	f022                	sd	s0,32(sp)
    80005848:	ec26                	sd	s1,24(sp)
    8000584a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000584c:	fd840613          	addi	a2,s0,-40
    80005850:	4581                	li	a1,0
    80005852:	4501                	li	a0,0
    80005854:	00000097          	auipc	ra,0x0
    80005858:	dc2080e7          	jalr	-574(ra) # 80005616 <argfd>
    return -1;
    8000585c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000585e:	02054363          	bltz	a0,80005884 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005862:	fd843503          	ld	a0,-40(s0)
    80005866:	00000097          	auipc	ra,0x0
    8000586a:	e10080e7          	jalr	-496(ra) # 80005676 <fdalloc>
    8000586e:	84aa                	mv	s1,a0
    return -1;
    80005870:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005872:	00054963          	bltz	a0,80005884 <sys_dup+0x42>
  filedup(f);
    80005876:	fd843503          	ld	a0,-40(s0)
    8000587a:	fffff097          	auipc	ra,0xfffff
    8000587e:	310080e7          	jalr	784(ra) # 80004b8a <filedup>
  return fd;
    80005882:	87a6                	mv	a5,s1
}
    80005884:	853e                	mv	a0,a5
    80005886:	70a2                	ld	ra,40(sp)
    80005888:	7402                	ld	s0,32(sp)
    8000588a:	64e2                	ld	s1,24(sp)
    8000588c:	6145                	addi	sp,sp,48
    8000588e:	8082                	ret

0000000080005890 <sys_read>:
{
    80005890:	7179                	addi	sp,sp,-48
    80005892:	f406                	sd	ra,40(sp)
    80005894:	f022                	sd	s0,32(sp)
    80005896:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005898:	fd840593          	addi	a1,s0,-40
    8000589c:	4505                	li	a0,1
    8000589e:	ffffe097          	auipc	ra,0xffffe
    800058a2:	912080e7          	jalr	-1774(ra) # 800031b0 <argaddr>
  argint(2, &n);
    800058a6:	fe440593          	addi	a1,s0,-28
    800058aa:	4509                	li	a0,2
    800058ac:	ffffe097          	auipc	ra,0xffffe
    800058b0:	8e4080e7          	jalr	-1820(ra) # 80003190 <argint>
  if(argfd(0, 0, &f) < 0)
    800058b4:	fe840613          	addi	a2,s0,-24
    800058b8:	4581                	li	a1,0
    800058ba:	4501                	li	a0,0
    800058bc:	00000097          	auipc	ra,0x0
    800058c0:	d5a080e7          	jalr	-678(ra) # 80005616 <argfd>
    800058c4:	87aa                	mv	a5,a0
    return -1;
    800058c6:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800058c8:	0007cc63          	bltz	a5,800058e0 <sys_read+0x50>
  return fileread(f, p, n);
    800058cc:	fe442603          	lw	a2,-28(s0)
    800058d0:	fd843583          	ld	a1,-40(s0)
    800058d4:	fe843503          	ld	a0,-24(s0)
    800058d8:	fffff097          	auipc	ra,0xfffff
    800058dc:	43e080e7          	jalr	1086(ra) # 80004d16 <fileread>
}
    800058e0:	70a2                	ld	ra,40(sp)
    800058e2:	7402                	ld	s0,32(sp)
    800058e4:	6145                	addi	sp,sp,48
    800058e6:	8082                	ret

00000000800058e8 <sys_write>:
{
    800058e8:	7179                	addi	sp,sp,-48
    800058ea:	f406                	sd	ra,40(sp)
    800058ec:	f022                	sd	s0,32(sp)
    800058ee:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800058f0:	fd840593          	addi	a1,s0,-40
    800058f4:	4505                	li	a0,1
    800058f6:	ffffe097          	auipc	ra,0xffffe
    800058fa:	8ba080e7          	jalr	-1862(ra) # 800031b0 <argaddr>
  argint(2, &n);
    800058fe:	fe440593          	addi	a1,s0,-28
    80005902:	4509                	li	a0,2
    80005904:	ffffe097          	auipc	ra,0xffffe
    80005908:	88c080e7          	jalr	-1908(ra) # 80003190 <argint>
  if(argfd(0, 0, &f) < 0)
    8000590c:	fe840613          	addi	a2,s0,-24
    80005910:	4581                	li	a1,0
    80005912:	4501                	li	a0,0
    80005914:	00000097          	auipc	ra,0x0
    80005918:	d02080e7          	jalr	-766(ra) # 80005616 <argfd>
    8000591c:	87aa                	mv	a5,a0
    return -1;
    8000591e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005920:	0007cc63          	bltz	a5,80005938 <sys_write+0x50>
  return filewrite(f, p, n);
    80005924:	fe442603          	lw	a2,-28(s0)
    80005928:	fd843583          	ld	a1,-40(s0)
    8000592c:	fe843503          	ld	a0,-24(s0)
    80005930:	fffff097          	auipc	ra,0xfffff
    80005934:	4a8080e7          	jalr	1192(ra) # 80004dd8 <filewrite>
}
    80005938:	70a2                	ld	ra,40(sp)
    8000593a:	7402                	ld	s0,32(sp)
    8000593c:	6145                	addi	sp,sp,48
    8000593e:	8082                	ret

0000000080005940 <sys_close>:
{
    80005940:	1101                	addi	sp,sp,-32
    80005942:	ec06                	sd	ra,24(sp)
    80005944:	e822                	sd	s0,16(sp)
    80005946:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005948:	fe040613          	addi	a2,s0,-32
    8000594c:	fec40593          	addi	a1,s0,-20
    80005950:	4501                	li	a0,0
    80005952:	00000097          	auipc	ra,0x0
    80005956:	cc4080e7          	jalr	-828(ra) # 80005616 <argfd>
    return -1;
    8000595a:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000595c:	02054463          	bltz	a0,80005984 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005960:	ffffc097          	auipc	ra,0xffffc
    80005964:	40c080e7          	jalr	1036(ra) # 80001d6c <myproc>
    80005968:	fec42783          	lw	a5,-20(s0)
    8000596c:	07e9                	addi	a5,a5,26
    8000596e:	078e                	slli	a5,a5,0x3
    80005970:	97aa                	add	a5,a5,a0
    80005972:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005976:	fe043503          	ld	a0,-32(s0)
    8000597a:	fffff097          	auipc	ra,0xfffff
    8000597e:	262080e7          	jalr	610(ra) # 80004bdc <fileclose>
  return 0;
    80005982:	4781                	li	a5,0
}
    80005984:	853e                	mv	a0,a5
    80005986:	60e2                	ld	ra,24(sp)
    80005988:	6442                	ld	s0,16(sp)
    8000598a:	6105                	addi	sp,sp,32
    8000598c:	8082                	ret

000000008000598e <sys_fstat>:
{
    8000598e:	1101                	addi	sp,sp,-32
    80005990:	ec06                	sd	ra,24(sp)
    80005992:	e822                	sd	s0,16(sp)
    80005994:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005996:	fe040593          	addi	a1,s0,-32
    8000599a:	4505                	li	a0,1
    8000599c:	ffffe097          	auipc	ra,0xffffe
    800059a0:	814080e7          	jalr	-2028(ra) # 800031b0 <argaddr>
  if(argfd(0, 0, &f) < 0)
    800059a4:	fe840613          	addi	a2,s0,-24
    800059a8:	4581                	li	a1,0
    800059aa:	4501                	li	a0,0
    800059ac:	00000097          	auipc	ra,0x0
    800059b0:	c6a080e7          	jalr	-918(ra) # 80005616 <argfd>
    800059b4:	87aa                	mv	a5,a0
    return -1;
    800059b6:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800059b8:	0007ca63          	bltz	a5,800059cc <sys_fstat+0x3e>
  return filestat(f, st);
    800059bc:	fe043583          	ld	a1,-32(s0)
    800059c0:	fe843503          	ld	a0,-24(s0)
    800059c4:	fffff097          	auipc	ra,0xfffff
    800059c8:	2e0080e7          	jalr	736(ra) # 80004ca4 <filestat>
}
    800059cc:	60e2                	ld	ra,24(sp)
    800059ce:	6442                	ld	s0,16(sp)
    800059d0:	6105                	addi	sp,sp,32
    800059d2:	8082                	ret

00000000800059d4 <sys_link>:
{
    800059d4:	7169                	addi	sp,sp,-304
    800059d6:	f606                	sd	ra,296(sp)
    800059d8:	f222                	sd	s0,288(sp)
    800059da:	ee26                	sd	s1,280(sp)
    800059dc:	ea4a                	sd	s2,272(sp)
    800059de:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800059e0:	08000613          	li	a2,128
    800059e4:	ed040593          	addi	a1,s0,-304
    800059e8:	4501                	li	a0,0
    800059ea:	ffffd097          	auipc	ra,0xffffd
    800059ee:	7e6080e7          	jalr	2022(ra) # 800031d0 <argstr>
    return -1;
    800059f2:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800059f4:	10054e63          	bltz	a0,80005b10 <sys_link+0x13c>
    800059f8:	08000613          	li	a2,128
    800059fc:	f5040593          	addi	a1,s0,-176
    80005a00:	4505                	li	a0,1
    80005a02:	ffffd097          	auipc	ra,0xffffd
    80005a06:	7ce080e7          	jalr	1998(ra) # 800031d0 <argstr>
    return -1;
    80005a0a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a0c:	10054263          	bltz	a0,80005b10 <sys_link+0x13c>
  begin_op();
    80005a10:	fffff097          	auipc	ra,0xfffff
    80005a14:	d00080e7          	jalr	-768(ra) # 80004710 <begin_op>
  if((ip = namei(old)) == 0){
    80005a18:	ed040513          	addi	a0,s0,-304
    80005a1c:	fffff097          	auipc	ra,0xfffff
    80005a20:	ad8080e7          	jalr	-1320(ra) # 800044f4 <namei>
    80005a24:	84aa                	mv	s1,a0
    80005a26:	c551                	beqz	a0,80005ab2 <sys_link+0xde>
  ilock(ip);
    80005a28:	ffffe097          	auipc	ra,0xffffe
    80005a2c:	326080e7          	jalr	806(ra) # 80003d4e <ilock>
  if(ip->type == T_DIR){
    80005a30:	04449703          	lh	a4,68(s1)
    80005a34:	4785                	li	a5,1
    80005a36:	08f70463          	beq	a4,a5,80005abe <sys_link+0xea>
  ip->nlink++;
    80005a3a:	04a4d783          	lhu	a5,74(s1)
    80005a3e:	2785                	addiw	a5,a5,1
    80005a40:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005a44:	8526                	mv	a0,s1
    80005a46:	ffffe097          	auipc	ra,0xffffe
    80005a4a:	23e080e7          	jalr	574(ra) # 80003c84 <iupdate>
  iunlock(ip);
    80005a4e:	8526                	mv	a0,s1
    80005a50:	ffffe097          	auipc	ra,0xffffe
    80005a54:	3c0080e7          	jalr	960(ra) # 80003e10 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005a58:	fd040593          	addi	a1,s0,-48
    80005a5c:	f5040513          	addi	a0,s0,-176
    80005a60:	fffff097          	auipc	ra,0xfffff
    80005a64:	ab2080e7          	jalr	-1358(ra) # 80004512 <nameiparent>
    80005a68:	892a                	mv	s2,a0
    80005a6a:	c935                	beqz	a0,80005ade <sys_link+0x10a>
  ilock(dp);
    80005a6c:	ffffe097          	auipc	ra,0xffffe
    80005a70:	2e2080e7          	jalr	738(ra) # 80003d4e <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005a74:	00092703          	lw	a4,0(s2)
    80005a78:	409c                	lw	a5,0(s1)
    80005a7a:	04f71d63          	bne	a4,a5,80005ad4 <sys_link+0x100>
    80005a7e:	40d0                	lw	a2,4(s1)
    80005a80:	fd040593          	addi	a1,s0,-48
    80005a84:	854a                	mv	a0,s2
    80005a86:	fffff097          	auipc	ra,0xfffff
    80005a8a:	9bc080e7          	jalr	-1604(ra) # 80004442 <dirlink>
    80005a8e:	04054363          	bltz	a0,80005ad4 <sys_link+0x100>
  iunlockput(dp);
    80005a92:	854a                	mv	a0,s2
    80005a94:	ffffe097          	auipc	ra,0xffffe
    80005a98:	51c080e7          	jalr	1308(ra) # 80003fb0 <iunlockput>
  iput(ip);
    80005a9c:	8526                	mv	a0,s1
    80005a9e:	ffffe097          	auipc	ra,0xffffe
    80005aa2:	46a080e7          	jalr	1130(ra) # 80003f08 <iput>
  end_op();
    80005aa6:	fffff097          	auipc	ra,0xfffff
    80005aaa:	cea080e7          	jalr	-790(ra) # 80004790 <end_op>
  return 0;
    80005aae:	4781                	li	a5,0
    80005ab0:	a085                	j	80005b10 <sys_link+0x13c>
    end_op();
    80005ab2:	fffff097          	auipc	ra,0xfffff
    80005ab6:	cde080e7          	jalr	-802(ra) # 80004790 <end_op>
    return -1;
    80005aba:	57fd                	li	a5,-1
    80005abc:	a891                	j	80005b10 <sys_link+0x13c>
    iunlockput(ip);
    80005abe:	8526                	mv	a0,s1
    80005ac0:	ffffe097          	auipc	ra,0xffffe
    80005ac4:	4f0080e7          	jalr	1264(ra) # 80003fb0 <iunlockput>
    end_op();
    80005ac8:	fffff097          	auipc	ra,0xfffff
    80005acc:	cc8080e7          	jalr	-824(ra) # 80004790 <end_op>
    return -1;
    80005ad0:	57fd                	li	a5,-1
    80005ad2:	a83d                	j	80005b10 <sys_link+0x13c>
    iunlockput(dp);
    80005ad4:	854a                	mv	a0,s2
    80005ad6:	ffffe097          	auipc	ra,0xffffe
    80005ada:	4da080e7          	jalr	1242(ra) # 80003fb0 <iunlockput>
  ilock(ip);
    80005ade:	8526                	mv	a0,s1
    80005ae0:	ffffe097          	auipc	ra,0xffffe
    80005ae4:	26e080e7          	jalr	622(ra) # 80003d4e <ilock>
  ip->nlink--;
    80005ae8:	04a4d783          	lhu	a5,74(s1)
    80005aec:	37fd                	addiw	a5,a5,-1
    80005aee:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005af2:	8526                	mv	a0,s1
    80005af4:	ffffe097          	auipc	ra,0xffffe
    80005af8:	190080e7          	jalr	400(ra) # 80003c84 <iupdate>
  iunlockput(ip);
    80005afc:	8526                	mv	a0,s1
    80005afe:	ffffe097          	auipc	ra,0xffffe
    80005b02:	4b2080e7          	jalr	1202(ra) # 80003fb0 <iunlockput>
  end_op();
    80005b06:	fffff097          	auipc	ra,0xfffff
    80005b0a:	c8a080e7          	jalr	-886(ra) # 80004790 <end_op>
  return -1;
    80005b0e:	57fd                	li	a5,-1
}
    80005b10:	853e                	mv	a0,a5
    80005b12:	70b2                	ld	ra,296(sp)
    80005b14:	7412                	ld	s0,288(sp)
    80005b16:	64f2                	ld	s1,280(sp)
    80005b18:	6952                	ld	s2,272(sp)
    80005b1a:	6155                	addi	sp,sp,304
    80005b1c:	8082                	ret

0000000080005b1e <sys_unlink>:
{
    80005b1e:	7151                	addi	sp,sp,-240
    80005b20:	f586                	sd	ra,232(sp)
    80005b22:	f1a2                	sd	s0,224(sp)
    80005b24:	eda6                	sd	s1,216(sp)
    80005b26:	e9ca                	sd	s2,208(sp)
    80005b28:	e5ce                	sd	s3,200(sp)
    80005b2a:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005b2c:	08000613          	li	a2,128
    80005b30:	f3040593          	addi	a1,s0,-208
    80005b34:	4501                	li	a0,0
    80005b36:	ffffd097          	auipc	ra,0xffffd
    80005b3a:	69a080e7          	jalr	1690(ra) # 800031d0 <argstr>
    80005b3e:	18054163          	bltz	a0,80005cc0 <sys_unlink+0x1a2>
  begin_op();
    80005b42:	fffff097          	auipc	ra,0xfffff
    80005b46:	bce080e7          	jalr	-1074(ra) # 80004710 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005b4a:	fb040593          	addi	a1,s0,-80
    80005b4e:	f3040513          	addi	a0,s0,-208
    80005b52:	fffff097          	auipc	ra,0xfffff
    80005b56:	9c0080e7          	jalr	-1600(ra) # 80004512 <nameiparent>
    80005b5a:	84aa                	mv	s1,a0
    80005b5c:	c979                	beqz	a0,80005c32 <sys_unlink+0x114>
  ilock(dp);
    80005b5e:	ffffe097          	auipc	ra,0xffffe
    80005b62:	1f0080e7          	jalr	496(ra) # 80003d4e <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005b66:	00003597          	auipc	a1,0x3
    80005b6a:	cea58593          	addi	a1,a1,-790 # 80008850 <syscalls+0x2b0>
    80005b6e:	fb040513          	addi	a0,s0,-80
    80005b72:	ffffe097          	auipc	ra,0xffffe
    80005b76:	6a6080e7          	jalr	1702(ra) # 80004218 <namecmp>
    80005b7a:	14050a63          	beqz	a0,80005cce <sys_unlink+0x1b0>
    80005b7e:	00003597          	auipc	a1,0x3
    80005b82:	cda58593          	addi	a1,a1,-806 # 80008858 <syscalls+0x2b8>
    80005b86:	fb040513          	addi	a0,s0,-80
    80005b8a:	ffffe097          	auipc	ra,0xffffe
    80005b8e:	68e080e7          	jalr	1678(ra) # 80004218 <namecmp>
    80005b92:	12050e63          	beqz	a0,80005cce <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005b96:	f2c40613          	addi	a2,s0,-212
    80005b9a:	fb040593          	addi	a1,s0,-80
    80005b9e:	8526                	mv	a0,s1
    80005ba0:	ffffe097          	auipc	ra,0xffffe
    80005ba4:	692080e7          	jalr	1682(ra) # 80004232 <dirlookup>
    80005ba8:	892a                	mv	s2,a0
    80005baa:	12050263          	beqz	a0,80005cce <sys_unlink+0x1b0>
  ilock(ip);
    80005bae:	ffffe097          	auipc	ra,0xffffe
    80005bb2:	1a0080e7          	jalr	416(ra) # 80003d4e <ilock>
  if(ip->nlink < 1)
    80005bb6:	04a91783          	lh	a5,74(s2)
    80005bba:	08f05263          	blez	a5,80005c3e <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005bbe:	04491703          	lh	a4,68(s2)
    80005bc2:	4785                	li	a5,1
    80005bc4:	08f70563          	beq	a4,a5,80005c4e <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005bc8:	4641                	li	a2,16
    80005bca:	4581                	li	a1,0
    80005bcc:	fc040513          	addi	a0,s0,-64
    80005bd0:	ffffb097          	auipc	ra,0xffffb
    80005bd4:	4c2080e7          	jalr	1218(ra) # 80001092 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005bd8:	4741                	li	a4,16
    80005bda:	f2c42683          	lw	a3,-212(s0)
    80005bde:	fc040613          	addi	a2,s0,-64
    80005be2:	4581                	li	a1,0
    80005be4:	8526                	mv	a0,s1
    80005be6:	ffffe097          	auipc	ra,0xffffe
    80005bea:	514080e7          	jalr	1300(ra) # 800040fa <writei>
    80005bee:	47c1                	li	a5,16
    80005bf0:	0af51563          	bne	a0,a5,80005c9a <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005bf4:	04491703          	lh	a4,68(s2)
    80005bf8:	4785                	li	a5,1
    80005bfa:	0af70863          	beq	a4,a5,80005caa <sys_unlink+0x18c>
  iunlockput(dp);
    80005bfe:	8526                	mv	a0,s1
    80005c00:	ffffe097          	auipc	ra,0xffffe
    80005c04:	3b0080e7          	jalr	944(ra) # 80003fb0 <iunlockput>
  ip->nlink--;
    80005c08:	04a95783          	lhu	a5,74(s2)
    80005c0c:	37fd                	addiw	a5,a5,-1
    80005c0e:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005c12:	854a                	mv	a0,s2
    80005c14:	ffffe097          	auipc	ra,0xffffe
    80005c18:	070080e7          	jalr	112(ra) # 80003c84 <iupdate>
  iunlockput(ip);
    80005c1c:	854a                	mv	a0,s2
    80005c1e:	ffffe097          	auipc	ra,0xffffe
    80005c22:	392080e7          	jalr	914(ra) # 80003fb0 <iunlockput>
  end_op();
    80005c26:	fffff097          	auipc	ra,0xfffff
    80005c2a:	b6a080e7          	jalr	-1174(ra) # 80004790 <end_op>
  return 0;
    80005c2e:	4501                	li	a0,0
    80005c30:	a84d                	j	80005ce2 <sys_unlink+0x1c4>
    end_op();
    80005c32:	fffff097          	auipc	ra,0xfffff
    80005c36:	b5e080e7          	jalr	-1186(ra) # 80004790 <end_op>
    return -1;
    80005c3a:	557d                	li	a0,-1
    80005c3c:	a05d                	j	80005ce2 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005c3e:	00003517          	auipc	a0,0x3
    80005c42:	c2250513          	addi	a0,a0,-990 # 80008860 <syscalls+0x2c0>
    80005c46:	ffffb097          	auipc	ra,0xffffb
    80005c4a:	cb8080e7          	jalr	-840(ra) # 800008fe <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005c4e:	04c92703          	lw	a4,76(s2)
    80005c52:	02000793          	li	a5,32
    80005c56:	f6e7f9e3          	bgeu	a5,a4,80005bc8 <sys_unlink+0xaa>
    80005c5a:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005c5e:	4741                	li	a4,16
    80005c60:	86ce                	mv	a3,s3
    80005c62:	f1840613          	addi	a2,s0,-232
    80005c66:	4581                	li	a1,0
    80005c68:	854a                	mv	a0,s2
    80005c6a:	ffffe097          	auipc	ra,0xffffe
    80005c6e:	398080e7          	jalr	920(ra) # 80004002 <readi>
    80005c72:	47c1                	li	a5,16
    80005c74:	00f51b63          	bne	a0,a5,80005c8a <sys_unlink+0x16c>
    if(de.inum != 0)
    80005c78:	f1845783          	lhu	a5,-232(s0)
    80005c7c:	e7a1                	bnez	a5,80005cc4 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005c7e:	29c1                	addiw	s3,s3,16
    80005c80:	04c92783          	lw	a5,76(s2)
    80005c84:	fcf9ede3          	bltu	s3,a5,80005c5e <sys_unlink+0x140>
    80005c88:	b781                	j	80005bc8 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005c8a:	00003517          	auipc	a0,0x3
    80005c8e:	bee50513          	addi	a0,a0,-1042 # 80008878 <syscalls+0x2d8>
    80005c92:	ffffb097          	auipc	ra,0xffffb
    80005c96:	c6c080e7          	jalr	-916(ra) # 800008fe <panic>
    panic("unlink: writei");
    80005c9a:	00003517          	auipc	a0,0x3
    80005c9e:	bf650513          	addi	a0,a0,-1034 # 80008890 <syscalls+0x2f0>
    80005ca2:	ffffb097          	auipc	ra,0xffffb
    80005ca6:	c5c080e7          	jalr	-932(ra) # 800008fe <panic>
    dp->nlink--;
    80005caa:	04a4d783          	lhu	a5,74(s1)
    80005cae:	37fd                	addiw	a5,a5,-1
    80005cb0:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005cb4:	8526                	mv	a0,s1
    80005cb6:	ffffe097          	auipc	ra,0xffffe
    80005cba:	fce080e7          	jalr	-50(ra) # 80003c84 <iupdate>
    80005cbe:	b781                	j	80005bfe <sys_unlink+0xe0>
    return -1;
    80005cc0:	557d                	li	a0,-1
    80005cc2:	a005                	j	80005ce2 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005cc4:	854a                	mv	a0,s2
    80005cc6:	ffffe097          	auipc	ra,0xffffe
    80005cca:	2ea080e7          	jalr	746(ra) # 80003fb0 <iunlockput>
  iunlockput(dp);
    80005cce:	8526                	mv	a0,s1
    80005cd0:	ffffe097          	auipc	ra,0xffffe
    80005cd4:	2e0080e7          	jalr	736(ra) # 80003fb0 <iunlockput>
  end_op();
    80005cd8:	fffff097          	auipc	ra,0xfffff
    80005cdc:	ab8080e7          	jalr	-1352(ra) # 80004790 <end_op>
  return -1;
    80005ce0:	557d                	li	a0,-1
}
    80005ce2:	70ae                	ld	ra,232(sp)
    80005ce4:	740e                	ld	s0,224(sp)
    80005ce6:	64ee                	ld	s1,216(sp)
    80005ce8:	694e                	ld	s2,208(sp)
    80005cea:	69ae                	ld	s3,200(sp)
    80005cec:	616d                	addi	sp,sp,240
    80005cee:	8082                	ret

0000000080005cf0 <sys_open>:

uint64
sys_open(void)
{
    80005cf0:	7131                	addi	sp,sp,-192
    80005cf2:	fd06                	sd	ra,184(sp)
    80005cf4:	f922                	sd	s0,176(sp)
    80005cf6:	f526                	sd	s1,168(sp)
    80005cf8:	f14a                	sd	s2,160(sp)
    80005cfa:	ed4e                	sd	s3,152(sp)
    80005cfc:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005cfe:	f4c40593          	addi	a1,s0,-180
    80005d02:	4505                	li	a0,1
    80005d04:	ffffd097          	auipc	ra,0xffffd
    80005d08:	48c080e7          	jalr	1164(ra) # 80003190 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005d0c:	08000613          	li	a2,128
    80005d10:	f5040593          	addi	a1,s0,-176
    80005d14:	4501                	li	a0,0
    80005d16:	ffffd097          	auipc	ra,0xffffd
    80005d1a:	4ba080e7          	jalr	1210(ra) # 800031d0 <argstr>
    80005d1e:	87aa                	mv	a5,a0
    return -1;
    80005d20:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005d22:	0a07c963          	bltz	a5,80005dd4 <sys_open+0xe4>

  begin_op();
    80005d26:	fffff097          	auipc	ra,0xfffff
    80005d2a:	9ea080e7          	jalr	-1558(ra) # 80004710 <begin_op>

  if(omode & O_CREATE){
    80005d2e:	f4c42783          	lw	a5,-180(s0)
    80005d32:	2007f793          	andi	a5,a5,512
    80005d36:	cfc5                	beqz	a5,80005dee <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005d38:	4681                	li	a3,0
    80005d3a:	4601                	li	a2,0
    80005d3c:	4589                	li	a1,2
    80005d3e:	f5040513          	addi	a0,s0,-176
    80005d42:	00000097          	auipc	ra,0x0
    80005d46:	976080e7          	jalr	-1674(ra) # 800056b8 <create>
    80005d4a:	84aa                	mv	s1,a0
    if(ip == 0){
    80005d4c:	c959                	beqz	a0,80005de2 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005d4e:	04449703          	lh	a4,68(s1)
    80005d52:	478d                	li	a5,3
    80005d54:	00f71763          	bne	a4,a5,80005d62 <sys_open+0x72>
    80005d58:	0464d703          	lhu	a4,70(s1)
    80005d5c:	47a5                	li	a5,9
    80005d5e:	0ce7ed63          	bltu	a5,a4,80005e38 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005d62:	fffff097          	auipc	ra,0xfffff
    80005d66:	dbe080e7          	jalr	-578(ra) # 80004b20 <filealloc>
    80005d6a:	89aa                	mv	s3,a0
    80005d6c:	10050363          	beqz	a0,80005e72 <sys_open+0x182>
    80005d70:	00000097          	auipc	ra,0x0
    80005d74:	906080e7          	jalr	-1786(ra) # 80005676 <fdalloc>
    80005d78:	892a                	mv	s2,a0
    80005d7a:	0e054763          	bltz	a0,80005e68 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005d7e:	04449703          	lh	a4,68(s1)
    80005d82:	478d                	li	a5,3
    80005d84:	0cf70563          	beq	a4,a5,80005e4e <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005d88:	4789                	li	a5,2
    80005d8a:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005d8e:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005d92:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005d96:	f4c42783          	lw	a5,-180(s0)
    80005d9a:	0017c713          	xori	a4,a5,1
    80005d9e:	8b05                	andi	a4,a4,1
    80005da0:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005da4:	0037f713          	andi	a4,a5,3
    80005da8:	00e03733          	snez	a4,a4
    80005dac:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005db0:	4007f793          	andi	a5,a5,1024
    80005db4:	c791                	beqz	a5,80005dc0 <sys_open+0xd0>
    80005db6:	04449703          	lh	a4,68(s1)
    80005dba:	4789                	li	a5,2
    80005dbc:	0af70063          	beq	a4,a5,80005e5c <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005dc0:	8526                	mv	a0,s1
    80005dc2:	ffffe097          	auipc	ra,0xffffe
    80005dc6:	04e080e7          	jalr	78(ra) # 80003e10 <iunlock>
  end_op();
    80005dca:	fffff097          	auipc	ra,0xfffff
    80005dce:	9c6080e7          	jalr	-1594(ra) # 80004790 <end_op>

  return fd;
    80005dd2:	854a                	mv	a0,s2
}
    80005dd4:	70ea                	ld	ra,184(sp)
    80005dd6:	744a                	ld	s0,176(sp)
    80005dd8:	74aa                	ld	s1,168(sp)
    80005dda:	790a                	ld	s2,160(sp)
    80005ddc:	69ea                	ld	s3,152(sp)
    80005dde:	6129                	addi	sp,sp,192
    80005de0:	8082                	ret
      end_op();
    80005de2:	fffff097          	auipc	ra,0xfffff
    80005de6:	9ae080e7          	jalr	-1618(ra) # 80004790 <end_op>
      return -1;
    80005dea:	557d                	li	a0,-1
    80005dec:	b7e5                	j	80005dd4 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005dee:	f5040513          	addi	a0,s0,-176
    80005df2:	ffffe097          	auipc	ra,0xffffe
    80005df6:	702080e7          	jalr	1794(ra) # 800044f4 <namei>
    80005dfa:	84aa                	mv	s1,a0
    80005dfc:	c905                	beqz	a0,80005e2c <sys_open+0x13c>
    ilock(ip);
    80005dfe:	ffffe097          	auipc	ra,0xffffe
    80005e02:	f50080e7          	jalr	-176(ra) # 80003d4e <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005e06:	04449703          	lh	a4,68(s1)
    80005e0a:	4785                	li	a5,1
    80005e0c:	f4f711e3          	bne	a4,a5,80005d4e <sys_open+0x5e>
    80005e10:	f4c42783          	lw	a5,-180(s0)
    80005e14:	d7b9                	beqz	a5,80005d62 <sys_open+0x72>
      iunlockput(ip);
    80005e16:	8526                	mv	a0,s1
    80005e18:	ffffe097          	auipc	ra,0xffffe
    80005e1c:	198080e7          	jalr	408(ra) # 80003fb0 <iunlockput>
      end_op();
    80005e20:	fffff097          	auipc	ra,0xfffff
    80005e24:	970080e7          	jalr	-1680(ra) # 80004790 <end_op>
      return -1;
    80005e28:	557d                	li	a0,-1
    80005e2a:	b76d                	j	80005dd4 <sys_open+0xe4>
      end_op();
    80005e2c:	fffff097          	auipc	ra,0xfffff
    80005e30:	964080e7          	jalr	-1692(ra) # 80004790 <end_op>
      return -1;
    80005e34:	557d                	li	a0,-1
    80005e36:	bf79                	j	80005dd4 <sys_open+0xe4>
    iunlockput(ip);
    80005e38:	8526                	mv	a0,s1
    80005e3a:	ffffe097          	auipc	ra,0xffffe
    80005e3e:	176080e7          	jalr	374(ra) # 80003fb0 <iunlockput>
    end_op();
    80005e42:	fffff097          	auipc	ra,0xfffff
    80005e46:	94e080e7          	jalr	-1714(ra) # 80004790 <end_op>
    return -1;
    80005e4a:	557d                	li	a0,-1
    80005e4c:	b761                	j	80005dd4 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005e4e:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005e52:	04649783          	lh	a5,70(s1)
    80005e56:	02f99223          	sh	a5,36(s3)
    80005e5a:	bf25                	j	80005d92 <sys_open+0xa2>
    itrunc(ip);
    80005e5c:	8526                	mv	a0,s1
    80005e5e:	ffffe097          	auipc	ra,0xffffe
    80005e62:	ffe080e7          	jalr	-2(ra) # 80003e5c <itrunc>
    80005e66:	bfa9                	j	80005dc0 <sys_open+0xd0>
      fileclose(f);
    80005e68:	854e                	mv	a0,s3
    80005e6a:	fffff097          	auipc	ra,0xfffff
    80005e6e:	d72080e7          	jalr	-654(ra) # 80004bdc <fileclose>
    iunlockput(ip);
    80005e72:	8526                	mv	a0,s1
    80005e74:	ffffe097          	auipc	ra,0xffffe
    80005e78:	13c080e7          	jalr	316(ra) # 80003fb0 <iunlockput>
    end_op();
    80005e7c:	fffff097          	auipc	ra,0xfffff
    80005e80:	914080e7          	jalr	-1772(ra) # 80004790 <end_op>
    return -1;
    80005e84:	557d                	li	a0,-1
    80005e86:	b7b9                	j	80005dd4 <sys_open+0xe4>

0000000080005e88 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005e88:	7175                	addi	sp,sp,-144
    80005e8a:	e506                	sd	ra,136(sp)
    80005e8c:	e122                	sd	s0,128(sp)
    80005e8e:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005e90:	fffff097          	auipc	ra,0xfffff
    80005e94:	880080e7          	jalr	-1920(ra) # 80004710 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005e98:	08000613          	li	a2,128
    80005e9c:	f7040593          	addi	a1,s0,-144
    80005ea0:	4501                	li	a0,0
    80005ea2:	ffffd097          	auipc	ra,0xffffd
    80005ea6:	32e080e7          	jalr	814(ra) # 800031d0 <argstr>
    80005eaa:	02054963          	bltz	a0,80005edc <sys_mkdir+0x54>
    80005eae:	4681                	li	a3,0
    80005eb0:	4601                	li	a2,0
    80005eb2:	4585                	li	a1,1
    80005eb4:	f7040513          	addi	a0,s0,-144
    80005eb8:	00000097          	auipc	ra,0x0
    80005ebc:	800080e7          	jalr	-2048(ra) # 800056b8 <create>
    80005ec0:	cd11                	beqz	a0,80005edc <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005ec2:	ffffe097          	auipc	ra,0xffffe
    80005ec6:	0ee080e7          	jalr	238(ra) # 80003fb0 <iunlockput>
  end_op();
    80005eca:	fffff097          	auipc	ra,0xfffff
    80005ece:	8c6080e7          	jalr	-1850(ra) # 80004790 <end_op>
  return 0;
    80005ed2:	4501                	li	a0,0
}
    80005ed4:	60aa                	ld	ra,136(sp)
    80005ed6:	640a                	ld	s0,128(sp)
    80005ed8:	6149                	addi	sp,sp,144
    80005eda:	8082                	ret
    end_op();
    80005edc:	fffff097          	auipc	ra,0xfffff
    80005ee0:	8b4080e7          	jalr	-1868(ra) # 80004790 <end_op>
    return -1;
    80005ee4:	557d                	li	a0,-1
    80005ee6:	b7fd                	j	80005ed4 <sys_mkdir+0x4c>

0000000080005ee8 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005ee8:	7135                	addi	sp,sp,-160
    80005eea:	ed06                	sd	ra,152(sp)
    80005eec:	e922                	sd	s0,144(sp)
    80005eee:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005ef0:	fffff097          	auipc	ra,0xfffff
    80005ef4:	820080e7          	jalr	-2016(ra) # 80004710 <begin_op>
  argint(1, &major);
    80005ef8:	f6c40593          	addi	a1,s0,-148
    80005efc:	4505                	li	a0,1
    80005efe:	ffffd097          	auipc	ra,0xffffd
    80005f02:	292080e7          	jalr	658(ra) # 80003190 <argint>
  argint(2, &minor);
    80005f06:	f6840593          	addi	a1,s0,-152
    80005f0a:	4509                	li	a0,2
    80005f0c:	ffffd097          	auipc	ra,0xffffd
    80005f10:	284080e7          	jalr	644(ra) # 80003190 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005f14:	08000613          	li	a2,128
    80005f18:	f7040593          	addi	a1,s0,-144
    80005f1c:	4501                	li	a0,0
    80005f1e:	ffffd097          	auipc	ra,0xffffd
    80005f22:	2b2080e7          	jalr	690(ra) # 800031d0 <argstr>
    80005f26:	02054b63          	bltz	a0,80005f5c <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005f2a:	f6841683          	lh	a3,-152(s0)
    80005f2e:	f6c41603          	lh	a2,-148(s0)
    80005f32:	458d                	li	a1,3
    80005f34:	f7040513          	addi	a0,s0,-144
    80005f38:	fffff097          	auipc	ra,0xfffff
    80005f3c:	780080e7          	jalr	1920(ra) # 800056b8 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005f40:	cd11                	beqz	a0,80005f5c <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005f42:	ffffe097          	auipc	ra,0xffffe
    80005f46:	06e080e7          	jalr	110(ra) # 80003fb0 <iunlockput>
  end_op();
    80005f4a:	fffff097          	auipc	ra,0xfffff
    80005f4e:	846080e7          	jalr	-1978(ra) # 80004790 <end_op>
  return 0;
    80005f52:	4501                	li	a0,0
}
    80005f54:	60ea                	ld	ra,152(sp)
    80005f56:	644a                	ld	s0,144(sp)
    80005f58:	610d                	addi	sp,sp,160
    80005f5a:	8082                	ret
    end_op();
    80005f5c:	fffff097          	auipc	ra,0xfffff
    80005f60:	834080e7          	jalr	-1996(ra) # 80004790 <end_op>
    return -1;
    80005f64:	557d                	li	a0,-1
    80005f66:	b7fd                	j	80005f54 <sys_mknod+0x6c>

0000000080005f68 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005f68:	7135                	addi	sp,sp,-160
    80005f6a:	ed06                	sd	ra,152(sp)
    80005f6c:	e922                	sd	s0,144(sp)
    80005f6e:	e526                	sd	s1,136(sp)
    80005f70:	e14a                	sd	s2,128(sp)
    80005f72:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005f74:	ffffc097          	auipc	ra,0xffffc
    80005f78:	df8080e7          	jalr	-520(ra) # 80001d6c <myproc>
    80005f7c:	892a                	mv	s2,a0
  
  begin_op();
    80005f7e:	ffffe097          	auipc	ra,0xffffe
    80005f82:	792080e7          	jalr	1938(ra) # 80004710 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005f86:	08000613          	li	a2,128
    80005f8a:	f6040593          	addi	a1,s0,-160
    80005f8e:	4501                	li	a0,0
    80005f90:	ffffd097          	auipc	ra,0xffffd
    80005f94:	240080e7          	jalr	576(ra) # 800031d0 <argstr>
    80005f98:	04054b63          	bltz	a0,80005fee <sys_chdir+0x86>
    80005f9c:	f6040513          	addi	a0,s0,-160
    80005fa0:	ffffe097          	auipc	ra,0xffffe
    80005fa4:	554080e7          	jalr	1364(ra) # 800044f4 <namei>
    80005fa8:	84aa                	mv	s1,a0
    80005faa:	c131                	beqz	a0,80005fee <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005fac:	ffffe097          	auipc	ra,0xffffe
    80005fb0:	da2080e7          	jalr	-606(ra) # 80003d4e <ilock>
  if(ip->type != T_DIR){
    80005fb4:	04449703          	lh	a4,68(s1)
    80005fb8:	4785                	li	a5,1
    80005fba:	04f71063          	bne	a4,a5,80005ffa <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005fbe:	8526                	mv	a0,s1
    80005fc0:	ffffe097          	auipc	ra,0xffffe
    80005fc4:	e50080e7          	jalr	-432(ra) # 80003e10 <iunlock>
  iput(p->cwd);
    80005fc8:	15093503          	ld	a0,336(s2)
    80005fcc:	ffffe097          	auipc	ra,0xffffe
    80005fd0:	f3c080e7          	jalr	-196(ra) # 80003f08 <iput>
  end_op();
    80005fd4:	ffffe097          	auipc	ra,0xffffe
    80005fd8:	7bc080e7          	jalr	1980(ra) # 80004790 <end_op>
  p->cwd = ip;
    80005fdc:	14993823          	sd	s1,336(s2)
  return 0;
    80005fe0:	4501                	li	a0,0
}
    80005fe2:	60ea                	ld	ra,152(sp)
    80005fe4:	644a                	ld	s0,144(sp)
    80005fe6:	64aa                	ld	s1,136(sp)
    80005fe8:	690a                	ld	s2,128(sp)
    80005fea:	610d                	addi	sp,sp,160
    80005fec:	8082                	ret
    end_op();
    80005fee:	ffffe097          	auipc	ra,0xffffe
    80005ff2:	7a2080e7          	jalr	1954(ra) # 80004790 <end_op>
    return -1;
    80005ff6:	557d                	li	a0,-1
    80005ff8:	b7ed                	j	80005fe2 <sys_chdir+0x7a>
    iunlockput(ip);
    80005ffa:	8526                	mv	a0,s1
    80005ffc:	ffffe097          	auipc	ra,0xffffe
    80006000:	fb4080e7          	jalr	-76(ra) # 80003fb0 <iunlockput>
    end_op();
    80006004:	ffffe097          	auipc	ra,0xffffe
    80006008:	78c080e7          	jalr	1932(ra) # 80004790 <end_op>
    return -1;
    8000600c:	557d                	li	a0,-1
    8000600e:	bfd1                	j	80005fe2 <sys_chdir+0x7a>

0000000080006010 <sys_exec>:

uint64
sys_exec(void)
{
    80006010:	7145                	addi	sp,sp,-464
    80006012:	e786                	sd	ra,456(sp)
    80006014:	e3a2                	sd	s0,448(sp)
    80006016:	ff26                	sd	s1,440(sp)
    80006018:	fb4a                	sd	s2,432(sp)
    8000601a:	f74e                	sd	s3,424(sp)
    8000601c:	f352                	sd	s4,416(sp)
    8000601e:	ef56                	sd	s5,408(sp)
    80006020:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80006022:	e3840593          	addi	a1,s0,-456
    80006026:	4505                	li	a0,1
    80006028:	ffffd097          	auipc	ra,0xffffd
    8000602c:	188080e7          	jalr	392(ra) # 800031b0 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80006030:	08000613          	li	a2,128
    80006034:	f4040593          	addi	a1,s0,-192
    80006038:	4501                	li	a0,0
    8000603a:	ffffd097          	auipc	ra,0xffffd
    8000603e:	196080e7          	jalr	406(ra) # 800031d0 <argstr>
    80006042:	87aa                	mv	a5,a0
    return -1;
    80006044:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80006046:	0c07c263          	bltz	a5,8000610a <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    8000604a:	10000613          	li	a2,256
    8000604e:	4581                	li	a1,0
    80006050:	e4040513          	addi	a0,s0,-448
    80006054:	ffffb097          	auipc	ra,0xffffb
    80006058:	03e080e7          	jalr	62(ra) # 80001092 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    8000605c:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006060:	89a6                	mv	s3,s1
    80006062:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006064:	02000a13          	li	s4,32
    80006068:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    8000606c:	00391793          	slli	a5,s2,0x3
    80006070:	e3040593          	addi	a1,s0,-464
    80006074:	e3843503          	ld	a0,-456(s0)
    80006078:	953e                	add	a0,a0,a5
    8000607a:	ffffd097          	auipc	ra,0xffffd
    8000607e:	078080e7          	jalr	120(ra) # 800030f2 <fetchaddr>
    80006082:	02054a63          	bltz	a0,800060b6 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80006086:	e3043783          	ld	a5,-464(s0)
    8000608a:	c3b9                	beqz	a5,800060d0 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    8000608c:	ffffb097          	auipc	ra,0xffffb
    80006090:	e1a080e7          	jalr	-486(ra) # 80000ea6 <kalloc>
    80006094:	85aa                	mv	a1,a0
    80006096:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    8000609a:	cd11                	beqz	a0,800060b6 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    8000609c:	6605                	lui	a2,0x1
    8000609e:	e3043503          	ld	a0,-464(s0)
    800060a2:	ffffd097          	auipc	ra,0xffffd
    800060a6:	0a2080e7          	jalr	162(ra) # 80003144 <fetchstr>
    800060aa:	00054663          	bltz	a0,800060b6 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    800060ae:	0905                	addi	s2,s2,1
    800060b0:	09a1                	addi	s3,s3,8
    800060b2:	fb491be3          	bne	s2,s4,80006068 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800060b6:	10048913          	addi	s2,s1,256
    800060ba:	6088                	ld	a0,0(s1)
    800060bc:	c531                	beqz	a0,80006108 <sys_exec+0xf8>
    kfree(argv[i]);
    800060be:	ffffb097          	auipc	ra,0xffffb
    800060c2:	cec080e7          	jalr	-788(ra) # 80000daa <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800060c6:	04a1                	addi	s1,s1,8
    800060c8:	ff2499e3          	bne	s1,s2,800060ba <sys_exec+0xaa>
  return -1;
    800060cc:	557d                	li	a0,-1
    800060ce:	a835                	j	8000610a <sys_exec+0xfa>
      argv[i] = 0;
    800060d0:	0a8e                	slli	s5,s5,0x3
    800060d2:	fc040793          	addi	a5,s0,-64
    800060d6:	9abe                	add	s5,s5,a5
    800060d8:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    800060dc:	e4040593          	addi	a1,s0,-448
    800060e0:	f4040513          	addi	a0,s0,-192
    800060e4:	fffff097          	auipc	ra,0xfffff
    800060e8:	172080e7          	jalr	370(ra) # 80005256 <exec>
    800060ec:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800060ee:	10048993          	addi	s3,s1,256
    800060f2:	6088                	ld	a0,0(s1)
    800060f4:	c901                	beqz	a0,80006104 <sys_exec+0xf4>
    kfree(argv[i]);
    800060f6:	ffffb097          	auipc	ra,0xffffb
    800060fa:	cb4080e7          	jalr	-844(ra) # 80000daa <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800060fe:	04a1                	addi	s1,s1,8
    80006100:	ff3499e3          	bne	s1,s3,800060f2 <sys_exec+0xe2>
  return ret;
    80006104:	854a                	mv	a0,s2
    80006106:	a011                	j	8000610a <sys_exec+0xfa>
  return -1;
    80006108:	557d                	li	a0,-1
}
    8000610a:	60be                	ld	ra,456(sp)
    8000610c:	641e                	ld	s0,448(sp)
    8000610e:	74fa                	ld	s1,440(sp)
    80006110:	795a                	ld	s2,432(sp)
    80006112:	79ba                	ld	s3,424(sp)
    80006114:	7a1a                	ld	s4,416(sp)
    80006116:	6afa                	ld	s5,408(sp)
    80006118:	6179                	addi	sp,sp,464
    8000611a:	8082                	ret

000000008000611c <sys_pipe>:

uint64
sys_pipe(void)
{
    8000611c:	7139                	addi	sp,sp,-64
    8000611e:	fc06                	sd	ra,56(sp)
    80006120:	f822                	sd	s0,48(sp)
    80006122:	f426                	sd	s1,40(sp)
    80006124:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006126:	ffffc097          	auipc	ra,0xffffc
    8000612a:	c46080e7          	jalr	-954(ra) # 80001d6c <myproc>
    8000612e:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80006130:	fd840593          	addi	a1,s0,-40
    80006134:	4501                	li	a0,0
    80006136:	ffffd097          	auipc	ra,0xffffd
    8000613a:	07a080e7          	jalr	122(ra) # 800031b0 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    8000613e:	fc840593          	addi	a1,s0,-56
    80006142:	fd040513          	addi	a0,s0,-48
    80006146:	fffff097          	auipc	ra,0xfffff
    8000614a:	dc6080e7          	jalr	-570(ra) # 80004f0c <pipealloc>
    return -1;
    8000614e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006150:	0c054463          	bltz	a0,80006218 <sys_pipe+0xfc>
  fd0 = -1;
    80006154:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006158:	fd043503          	ld	a0,-48(s0)
    8000615c:	fffff097          	auipc	ra,0xfffff
    80006160:	51a080e7          	jalr	1306(ra) # 80005676 <fdalloc>
    80006164:	fca42223          	sw	a0,-60(s0)
    80006168:	08054b63          	bltz	a0,800061fe <sys_pipe+0xe2>
    8000616c:	fc843503          	ld	a0,-56(s0)
    80006170:	fffff097          	auipc	ra,0xfffff
    80006174:	506080e7          	jalr	1286(ra) # 80005676 <fdalloc>
    80006178:	fca42023          	sw	a0,-64(s0)
    8000617c:	06054863          	bltz	a0,800061ec <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006180:	4691                	li	a3,4
    80006182:	fc440613          	addi	a2,s0,-60
    80006186:	fd843583          	ld	a1,-40(s0)
    8000618a:	68a8                	ld	a0,80(s1)
    8000618c:	ffffc097          	auipc	ra,0xffffc
    80006190:	89c080e7          	jalr	-1892(ra) # 80001a28 <copyout>
    80006194:	02054063          	bltz	a0,800061b4 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006198:	4691                	li	a3,4
    8000619a:	fc040613          	addi	a2,s0,-64
    8000619e:	fd843583          	ld	a1,-40(s0)
    800061a2:	0591                	addi	a1,a1,4
    800061a4:	68a8                	ld	a0,80(s1)
    800061a6:	ffffc097          	auipc	ra,0xffffc
    800061aa:	882080e7          	jalr	-1918(ra) # 80001a28 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800061ae:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800061b0:	06055463          	bgez	a0,80006218 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    800061b4:	fc442783          	lw	a5,-60(s0)
    800061b8:	07e9                	addi	a5,a5,26
    800061ba:	078e                	slli	a5,a5,0x3
    800061bc:	97a6                	add	a5,a5,s1
    800061be:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800061c2:	fc042503          	lw	a0,-64(s0)
    800061c6:	0569                	addi	a0,a0,26
    800061c8:	050e                	slli	a0,a0,0x3
    800061ca:	94aa                	add	s1,s1,a0
    800061cc:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    800061d0:	fd043503          	ld	a0,-48(s0)
    800061d4:	fffff097          	auipc	ra,0xfffff
    800061d8:	a08080e7          	jalr	-1528(ra) # 80004bdc <fileclose>
    fileclose(wf);
    800061dc:	fc843503          	ld	a0,-56(s0)
    800061e0:	fffff097          	auipc	ra,0xfffff
    800061e4:	9fc080e7          	jalr	-1540(ra) # 80004bdc <fileclose>
    return -1;
    800061e8:	57fd                	li	a5,-1
    800061ea:	a03d                	j	80006218 <sys_pipe+0xfc>
    if(fd0 >= 0)
    800061ec:	fc442783          	lw	a5,-60(s0)
    800061f0:	0007c763          	bltz	a5,800061fe <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    800061f4:	07e9                	addi	a5,a5,26
    800061f6:	078e                	slli	a5,a5,0x3
    800061f8:	94be                	add	s1,s1,a5
    800061fa:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    800061fe:	fd043503          	ld	a0,-48(s0)
    80006202:	fffff097          	auipc	ra,0xfffff
    80006206:	9da080e7          	jalr	-1574(ra) # 80004bdc <fileclose>
    fileclose(wf);
    8000620a:	fc843503          	ld	a0,-56(s0)
    8000620e:	fffff097          	auipc	ra,0xfffff
    80006212:	9ce080e7          	jalr	-1586(ra) # 80004bdc <fileclose>
    return -1;
    80006216:	57fd                	li	a5,-1
}
    80006218:	853e                	mv	a0,a5
    8000621a:	70e2                	ld	ra,56(sp)
    8000621c:	7442                	ld	s0,48(sp)
    8000621e:	74a2                	ld	s1,40(sp)
    80006220:	6121                	addi	sp,sp,64
    80006222:	8082                	ret
	...

0000000080006230 <kernelvec>:
    80006230:	7111                	addi	sp,sp,-256
    80006232:	e006                	sd	ra,0(sp)
    80006234:	e40a                	sd	sp,8(sp)
    80006236:	e80e                	sd	gp,16(sp)
    80006238:	ec12                	sd	tp,24(sp)
    8000623a:	f016                	sd	t0,32(sp)
    8000623c:	f41a                	sd	t1,40(sp)
    8000623e:	f81e                	sd	t2,48(sp)
    80006240:	fc22                	sd	s0,56(sp)
    80006242:	e0a6                	sd	s1,64(sp)
    80006244:	e4aa                	sd	a0,72(sp)
    80006246:	e8ae                	sd	a1,80(sp)
    80006248:	ecb2                	sd	a2,88(sp)
    8000624a:	f0b6                	sd	a3,96(sp)
    8000624c:	f4ba                	sd	a4,104(sp)
    8000624e:	f8be                	sd	a5,112(sp)
    80006250:	fcc2                	sd	a6,120(sp)
    80006252:	e146                	sd	a7,128(sp)
    80006254:	e54a                	sd	s2,136(sp)
    80006256:	e94e                	sd	s3,144(sp)
    80006258:	ed52                	sd	s4,152(sp)
    8000625a:	f156                	sd	s5,160(sp)
    8000625c:	f55a                	sd	s6,168(sp)
    8000625e:	f95e                	sd	s7,176(sp)
    80006260:	fd62                	sd	s8,184(sp)
    80006262:	e1e6                	sd	s9,192(sp)
    80006264:	e5ea                	sd	s10,200(sp)
    80006266:	e9ee                	sd	s11,208(sp)
    80006268:	edf2                	sd	t3,216(sp)
    8000626a:	f1f6                	sd	t4,224(sp)
    8000626c:	f5fa                	sd	t5,232(sp)
    8000626e:	f9fe                	sd	t6,240(sp)
    80006270:	d4ffc0ef          	jal	ra,80002fbe <kerneltrap>
    80006274:	6082                	ld	ra,0(sp)
    80006276:	6122                	ld	sp,8(sp)
    80006278:	61c2                	ld	gp,16(sp)
    8000627a:	7282                	ld	t0,32(sp)
    8000627c:	7322                	ld	t1,40(sp)
    8000627e:	73c2                	ld	t2,48(sp)
    80006280:	7462                	ld	s0,56(sp)
    80006282:	6486                	ld	s1,64(sp)
    80006284:	6526                	ld	a0,72(sp)
    80006286:	65c6                	ld	a1,80(sp)
    80006288:	6666                	ld	a2,88(sp)
    8000628a:	7686                	ld	a3,96(sp)
    8000628c:	7726                	ld	a4,104(sp)
    8000628e:	77c6                	ld	a5,112(sp)
    80006290:	7866                	ld	a6,120(sp)
    80006292:	688a                	ld	a7,128(sp)
    80006294:	692a                	ld	s2,136(sp)
    80006296:	69ca                	ld	s3,144(sp)
    80006298:	6a6a                	ld	s4,152(sp)
    8000629a:	7a8a                	ld	s5,160(sp)
    8000629c:	7b2a                	ld	s6,168(sp)
    8000629e:	7bca                	ld	s7,176(sp)
    800062a0:	7c6a                	ld	s8,184(sp)
    800062a2:	6c8e                	ld	s9,192(sp)
    800062a4:	6d2e                	ld	s10,200(sp)
    800062a6:	6dce                	ld	s11,208(sp)
    800062a8:	6e6e                	ld	t3,216(sp)
    800062aa:	7e8e                	ld	t4,224(sp)
    800062ac:	7f2e                	ld	t5,232(sp)
    800062ae:	7fce                	ld	t6,240(sp)
    800062b0:	6111                	addi	sp,sp,256
    800062b2:	10200073          	sret
    800062b6:	00000013          	nop
    800062ba:	00000013          	nop
    800062be:	0001                	nop

00000000800062c0 <timervec>:
    800062c0:	34051573          	csrrw	a0,mscratch,a0
    800062c4:	e10c                	sd	a1,0(a0)
    800062c6:	e510                	sd	a2,8(a0)
    800062c8:	e914                	sd	a3,16(a0)
    800062ca:	6d0c                	ld	a1,24(a0)
    800062cc:	7110                	ld	a2,32(a0)
    800062ce:	6194                	ld	a3,0(a1)
    800062d0:	96b2                	add	a3,a3,a2
    800062d2:	e194                	sd	a3,0(a1)
    800062d4:	4589                	li	a1,2
    800062d6:	14459073          	csrw	sip,a1
    800062da:	6914                	ld	a3,16(a0)
    800062dc:	6510                	ld	a2,8(a0)
    800062de:	610c                	ld	a1,0(a0)
    800062e0:	34051573          	csrrw	a0,mscratch,a0
    800062e4:	30200073          	mret
	...

00000000800062ea <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800062ea:	1141                	addi	sp,sp,-16
    800062ec:	e422                	sd	s0,8(sp)
    800062ee:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800062f0:	0c0007b7          	lui	a5,0xc000
    800062f4:	4705                	li	a4,1
    800062f6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800062f8:	c3d8                	sw	a4,4(a5)
}
    800062fa:	6422                	ld	s0,8(sp)
    800062fc:	0141                	addi	sp,sp,16
    800062fe:	8082                	ret

0000000080006300 <plicinithart>:

void
plicinithart(void)
{
    80006300:	1141                	addi	sp,sp,-16
    80006302:	e406                	sd	ra,8(sp)
    80006304:	e022                	sd	s0,0(sp)
    80006306:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006308:	ffffc097          	auipc	ra,0xffffc
    8000630c:	a38080e7          	jalr	-1480(ra) # 80001d40 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006310:	0085171b          	slliw	a4,a0,0x8
    80006314:	0c0027b7          	lui	a5,0xc002
    80006318:	97ba                	add	a5,a5,a4
    8000631a:	40200713          	li	a4,1026
    8000631e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006322:	00d5151b          	slliw	a0,a0,0xd
    80006326:	0c2017b7          	lui	a5,0xc201
    8000632a:	953e                	add	a0,a0,a5
    8000632c:	00052023          	sw	zero,0(a0)
}
    80006330:	60a2                	ld	ra,8(sp)
    80006332:	6402                	ld	s0,0(sp)
    80006334:	0141                	addi	sp,sp,16
    80006336:	8082                	ret

0000000080006338 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006338:	1141                	addi	sp,sp,-16
    8000633a:	e406                	sd	ra,8(sp)
    8000633c:	e022                	sd	s0,0(sp)
    8000633e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006340:	ffffc097          	auipc	ra,0xffffc
    80006344:	a00080e7          	jalr	-1536(ra) # 80001d40 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006348:	00d5179b          	slliw	a5,a0,0xd
    8000634c:	0c201537          	lui	a0,0xc201
    80006350:	953e                	add	a0,a0,a5
  return irq;
}
    80006352:	4148                	lw	a0,4(a0)
    80006354:	60a2                	ld	ra,8(sp)
    80006356:	6402                	ld	s0,0(sp)
    80006358:	0141                	addi	sp,sp,16
    8000635a:	8082                	ret

000000008000635c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000635c:	1101                	addi	sp,sp,-32
    8000635e:	ec06                	sd	ra,24(sp)
    80006360:	e822                	sd	s0,16(sp)
    80006362:	e426                	sd	s1,8(sp)
    80006364:	1000                	addi	s0,sp,32
    80006366:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006368:	ffffc097          	auipc	ra,0xffffc
    8000636c:	9d8080e7          	jalr	-1576(ra) # 80001d40 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006370:	00d5151b          	slliw	a0,a0,0xd
    80006374:	0c2017b7          	lui	a5,0xc201
    80006378:	97aa                	add	a5,a5,a0
    8000637a:	c3c4                	sw	s1,4(a5)
}
    8000637c:	60e2                	ld	ra,24(sp)
    8000637e:	6442                	ld	s0,16(sp)
    80006380:	64a2                	ld	s1,8(sp)
    80006382:	6105                	addi	sp,sp,32
    80006384:	8082                	ret

0000000080006386 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006386:	1141                	addi	sp,sp,-16
    80006388:	e406                	sd	ra,8(sp)
    8000638a:	e022                	sd	s0,0(sp)
    8000638c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000638e:	479d                	li	a5,7
    80006390:	04a7cc63          	blt	a5,a0,800063e8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006394:	0001c797          	auipc	a5,0x1c
    80006398:	29478793          	addi	a5,a5,660 # 80022628 <disk>
    8000639c:	97aa                	add	a5,a5,a0
    8000639e:	0187c783          	lbu	a5,24(a5)
    800063a2:	ebb9                	bnez	a5,800063f8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800063a4:	00451613          	slli	a2,a0,0x4
    800063a8:	0001c797          	auipc	a5,0x1c
    800063ac:	28078793          	addi	a5,a5,640 # 80022628 <disk>
    800063b0:	6394                	ld	a3,0(a5)
    800063b2:	96b2                	add	a3,a3,a2
    800063b4:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800063b8:	6398                	ld	a4,0(a5)
    800063ba:	9732                	add	a4,a4,a2
    800063bc:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800063c0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800063c4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800063c8:	953e                	add	a0,a0,a5
    800063ca:	4785                	li	a5,1
    800063cc:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    800063d0:	0001c517          	auipc	a0,0x1c
    800063d4:	27050513          	addi	a0,a0,624 # 80022640 <disk+0x18>
    800063d8:	ffffc097          	auipc	ra,0xffffc
    800063dc:	0a0080e7          	jalr	160(ra) # 80002478 <wakeup>
}
    800063e0:	60a2                	ld	ra,8(sp)
    800063e2:	6402                	ld	s0,0(sp)
    800063e4:	0141                	addi	sp,sp,16
    800063e6:	8082                	ret
    panic("free_desc 1");
    800063e8:	00002517          	auipc	a0,0x2
    800063ec:	4b850513          	addi	a0,a0,1208 # 800088a0 <syscalls+0x300>
    800063f0:	ffffa097          	auipc	ra,0xffffa
    800063f4:	50e080e7          	jalr	1294(ra) # 800008fe <panic>
    panic("free_desc 2");
    800063f8:	00002517          	auipc	a0,0x2
    800063fc:	4b850513          	addi	a0,a0,1208 # 800088b0 <syscalls+0x310>
    80006400:	ffffa097          	auipc	ra,0xffffa
    80006404:	4fe080e7          	jalr	1278(ra) # 800008fe <panic>

0000000080006408 <virtio_disk_init>:
{
    80006408:	1101                	addi	sp,sp,-32
    8000640a:	ec06                	sd	ra,24(sp)
    8000640c:	e822                	sd	s0,16(sp)
    8000640e:	e426                	sd	s1,8(sp)
    80006410:	e04a                	sd	s2,0(sp)
    80006412:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006414:	00002597          	auipc	a1,0x2
    80006418:	4ac58593          	addi	a1,a1,1196 # 800088c0 <syscalls+0x320>
    8000641c:	0001c517          	auipc	a0,0x1c
    80006420:	33450513          	addi	a0,a0,820 # 80022750 <disk+0x128>
    80006424:	ffffb097          	auipc	ra,0xffffb
    80006428:	ae2080e7          	jalr	-1310(ra) # 80000f06 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000642c:	100017b7          	lui	a5,0x10001
    80006430:	4398                	lw	a4,0(a5)
    80006432:	2701                	sext.w	a4,a4
    80006434:	747277b7          	lui	a5,0x74727
    80006438:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000643c:	14f71c63          	bne	a4,a5,80006594 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006440:	100017b7          	lui	a5,0x10001
    80006444:	43dc                	lw	a5,4(a5)
    80006446:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006448:	4709                	li	a4,2
    8000644a:	14e79563          	bne	a5,a4,80006594 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000644e:	100017b7          	lui	a5,0x10001
    80006452:	479c                	lw	a5,8(a5)
    80006454:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006456:	12e79f63          	bne	a5,a4,80006594 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000645a:	100017b7          	lui	a5,0x10001
    8000645e:	47d8                	lw	a4,12(a5)
    80006460:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006462:	554d47b7          	lui	a5,0x554d4
    80006466:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000646a:	12f71563          	bne	a4,a5,80006594 <virtio_disk_init+0x18c>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000646e:	100017b7          	lui	a5,0x10001
    80006472:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006476:	4705                	li	a4,1
    80006478:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000647a:	470d                	li	a4,3
    8000647c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000647e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006480:	c7ffe737          	lui	a4,0xc7ffe
    80006484:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdbff7>
    80006488:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000648a:	2701                	sext.w	a4,a4
    8000648c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000648e:	472d                	li	a4,11
    80006490:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006492:	5bbc                	lw	a5,112(a5)
    80006494:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006498:	8ba1                	andi	a5,a5,8
    8000649a:	10078563          	beqz	a5,800065a4 <virtio_disk_init+0x19c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000649e:	100017b7          	lui	a5,0x10001
    800064a2:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800064a6:	43fc                	lw	a5,68(a5)
    800064a8:	2781                	sext.w	a5,a5
    800064aa:	10079563          	bnez	a5,800065b4 <virtio_disk_init+0x1ac>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800064ae:	100017b7          	lui	a5,0x10001
    800064b2:	5bdc                	lw	a5,52(a5)
    800064b4:	2781                	sext.w	a5,a5
  if(max == 0)
    800064b6:	10078763          	beqz	a5,800065c4 <virtio_disk_init+0x1bc>
  if(max < NUM)
    800064ba:	471d                	li	a4,7
    800064bc:	10f77c63          	bgeu	a4,a5,800065d4 <virtio_disk_init+0x1cc>
  disk.desc = kalloc();
    800064c0:	ffffb097          	auipc	ra,0xffffb
    800064c4:	9e6080e7          	jalr	-1562(ra) # 80000ea6 <kalloc>
    800064c8:	0001c497          	auipc	s1,0x1c
    800064cc:	16048493          	addi	s1,s1,352 # 80022628 <disk>
    800064d0:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800064d2:	ffffb097          	auipc	ra,0xffffb
    800064d6:	9d4080e7          	jalr	-1580(ra) # 80000ea6 <kalloc>
    800064da:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800064dc:	ffffb097          	auipc	ra,0xffffb
    800064e0:	9ca080e7          	jalr	-1590(ra) # 80000ea6 <kalloc>
    800064e4:	87aa                	mv	a5,a0
    800064e6:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800064e8:	6088                	ld	a0,0(s1)
    800064ea:	cd6d                	beqz	a0,800065e4 <virtio_disk_init+0x1dc>
    800064ec:	0001c717          	auipc	a4,0x1c
    800064f0:	14473703          	ld	a4,324(a4) # 80022630 <disk+0x8>
    800064f4:	cb65                	beqz	a4,800065e4 <virtio_disk_init+0x1dc>
    800064f6:	c7fd                	beqz	a5,800065e4 <virtio_disk_init+0x1dc>
  memset(disk.desc, 0, PGSIZE);
    800064f8:	6605                	lui	a2,0x1
    800064fa:	4581                	li	a1,0
    800064fc:	ffffb097          	auipc	ra,0xffffb
    80006500:	b96080e7          	jalr	-1130(ra) # 80001092 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006504:	0001c497          	auipc	s1,0x1c
    80006508:	12448493          	addi	s1,s1,292 # 80022628 <disk>
    8000650c:	6605                	lui	a2,0x1
    8000650e:	4581                	li	a1,0
    80006510:	6488                	ld	a0,8(s1)
    80006512:	ffffb097          	auipc	ra,0xffffb
    80006516:	b80080e7          	jalr	-1152(ra) # 80001092 <memset>
  memset(disk.used, 0, PGSIZE);
    8000651a:	6605                	lui	a2,0x1
    8000651c:	4581                	li	a1,0
    8000651e:	6888                	ld	a0,16(s1)
    80006520:	ffffb097          	auipc	ra,0xffffb
    80006524:	b72080e7          	jalr	-1166(ra) # 80001092 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006528:	100017b7          	lui	a5,0x10001
    8000652c:	4721                	li	a4,8
    8000652e:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006530:	4098                	lw	a4,0(s1)
    80006532:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006536:	40d8                	lw	a4,4(s1)
    80006538:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000653c:	6498                	ld	a4,8(s1)
    8000653e:	0007069b          	sext.w	a3,a4
    80006542:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006546:	9701                	srai	a4,a4,0x20
    80006548:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000654c:	6898                	ld	a4,16(s1)
    8000654e:	0007069b          	sext.w	a3,a4
    80006552:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006556:	9701                	srai	a4,a4,0x20
    80006558:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000655c:	4705                	li	a4,1
    8000655e:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80006560:	00e48c23          	sb	a4,24(s1)
    80006564:	00e48ca3          	sb	a4,25(s1)
    80006568:	00e48d23          	sb	a4,26(s1)
    8000656c:	00e48da3          	sb	a4,27(s1)
    80006570:	00e48e23          	sb	a4,28(s1)
    80006574:	00e48ea3          	sb	a4,29(s1)
    80006578:	00e48f23          	sb	a4,30(s1)
    8000657c:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006580:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006584:	0727a823          	sw	s2,112(a5)
}
    80006588:	60e2                	ld	ra,24(sp)
    8000658a:	6442                	ld	s0,16(sp)
    8000658c:	64a2                	ld	s1,8(sp)
    8000658e:	6902                	ld	s2,0(sp)
    80006590:	6105                	addi	sp,sp,32
    80006592:	8082                	ret
    panic("could not find virtio disk");
    80006594:	00002517          	auipc	a0,0x2
    80006598:	33c50513          	addi	a0,a0,828 # 800088d0 <syscalls+0x330>
    8000659c:	ffffa097          	auipc	ra,0xffffa
    800065a0:	362080e7          	jalr	866(ra) # 800008fe <panic>
    panic("virtio disk FEATURES_OK unset");
    800065a4:	00002517          	auipc	a0,0x2
    800065a8:	34c50513          	addi	a0,a0,844 # 800088f0 <syscalls+0x350>
    800065ac:	ffffa097          	auipc	ra,0xffffa
    800065b0:	352080e7          	jalr	850(ra) # 800008fe <panic>
    panic("virtio disk should not be ready");
    800065b4:	00002517          	auipc	a0,0x2
    800065b8:	35c50513          	addi	a0,a0,860 # 80008910 <syscalls+0x370>
    800065bc:	ffffa097          	auipc	ra,0xffffa
    800065c0:	342080e7          	jalr	834(ra) # 800008fe <panic>
    panic("virtio disk has no queue 0");
    800065c4:	00002517          	auipc	a0,0x2
    800065c8:	36c50513          	addi	a0,a0,876 # 80008930 <syscalls+0x390>
    800065cc:	ffffa097          	auipc	ra,0xffffa
    800065d0:	332080e7          	jalr	818(ra) # 800008fe <panic>
    panic("virtio disk max queue too short");
    800065d4:	00002517          	auipc	a0,0x2
    800065d8:	37c50513          	addi	a0,a0,892 # 80008950 <syscalls+0x3b0>
    800065dc:	ffffa097          	auipc	ra,0xffffa
    800065e0:	322080e7          	jalr	802(ra) # 800008fe <panic>
    panic("virtio disk kalloc");
    800065e4:	00002517          	auipc	a0,0x2
    800065e8:	38c50513          	addi	a0,a0,908 # 80008970 <syscalls+0x3d0>
    800065ec:	ffffa097          	auipc	ra,0xffffa
    800065f0:	312080e7          	jalr	786(ra) # 800008fe <panic>

00000000800065f4 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800065f4:	7119                	addi	sp,sp,-128
    800065f6:	fc86                	sd	ra,120(sp)
    800065f8:	f8a2                	sd	s0,112(sp)
    800065fa:	f4a6                	sd	s1,104(sp)
    800065fc:	f0ca                	sd	s2,96(sp)
    800065fe:	ecce                	sd	s3,88(sp)
    80006600:	e8d2                	sd	s4,80(sp)
    80006602:	e4d6                	sd	s5,72(sp)
    80006604:	e0da                	sd	s6,64(sp)
    80006606:	fc5e                	sd	s7,56(sp)
    80006608:	f862                	sd	s8,48(sp)
    8000660a:	f466                	sd	s9,40(sp)
    8000660c:	f06a                	sd	s10,32(sp)
    8000660e:	ec6e                	sd	s11,24(sp)
    80006610:	0100                	addi	s0,sp,128
    80006612:	8aaa                	mv	s5,a0
    80006614:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006616:	00c52d03          	lw	s10,12(a0)
    8000661a:	001d1d1b          	slliw	s10,s10,0x1
    8000661e:	1d02                	slli	s10,s10,0x20
    80006620:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006624:	0001c517          	auipc	a0,0x1c
    80006628:	12c50513          	addi	a0,a0,300 # 80022750 <disk+0x128>
    8000662c:	ffffb097          	auipc	ra,0xffffb
    80006630:	96a080e7          	jalr	-1686(ra) # 80000f96 <acquire>
  for(int i = 0; i < 3; i++){
    80006634:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006636:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006638:	0001cb97          	auipc	s7,0x1c
    8000663c:	ff0b8b93          	addi	s7,s7,-16 # 80022628 <disk>
  for(int i = 0; i < 3; i++){
    80006640:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006642:	0001cc97          	auipc	s9,0x1c
    80006646:	10ec8c93          	addi	s9,s9,270 # 80022750 <disk+0x128>
    8000664a:	a08d                	j	800066ac <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000664c:	00fb8733          	add	a4,s7,a5
    80006650:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006654:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006656:	0207c563          	bltz	a5,80006680 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    8000665a:	2905                	addiw	s2,s2,1
    8000665c:	0611                	addi	a2,a2,4
    8000665e:	05690c63          	beq	s2,s6,800066b6 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006662:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006664:	0001c717          	auipc	a4,0x1c
    80006668:	fc470713          	addi	a4,a4,-60 # 80022628 <disk>
    8000666c:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000666e:	01874683          	lbu	a3,24(a4)
    80006672:	fee9                	bnez	a3,8000664c <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006674:	2785                	addiw	a5,a5,1
    80006676:	0705                	addi	a4,a4,1
    80006678:	fe979be3          	bne	a5,s1,8000666e <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000667c:	57fd                	li	a5,-1
    8000667e:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006680:	01205d63          	blez	s2,8000669a <virtio_disk_rw+0xa6>
    80006684:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006686:	000a2503          	lw	a0,0(s4)
    8000668a:	00000097          	auipc	ra,0x0
    8000668e:	cfc080e7          	jalr	-772(ra) # 80006386 <free_desc>
      for(int j = 0; j < i; j++)
    80006692:	2d85                	addiw	s11,s11,1
    80006694:	0a11                	addi	s4,s4,4
    80006696:	ffb918e3          	bne	s2,s11,80006686 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000669a:	85e6                	mv	a1,s9
    8000669c:	0001c517          	auipc	a0,0x1c
    800066a0:	fa450513          	addi	a0,a0,-92 # 80022640 <disk+0x18>
    800066a4:	ffffc097          	auipc	ra,0xffffc
    800066a8:	d70080e7          	jalr	-656(ra) # 80002414 <sleep>
  for(int i = 0; i < 3; i++){
    800066ac:	f8040a13          	addi	s4,s0,-128
{
    800066b0:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800066b2:	894e                	mv	s2,s3
    800066b4:	b77d                	j	80006662 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800066b6:	f8042583          	lw	a1,-128(s0)
    800066ba:	00a58793          	addi	a5,a1,10
    800066be:	0792                	slli	a5,a5,0x4

  if(write)
    800066c0:	0001c617          	auipc	a2,0x1c
    800066c4:	f6860613          	addi	a2,a2,-152 # 80022628 <disk>
    800066c8:	00f60733          	add	a4,a2,a5
    800066cc:	018036b3          	snez	a3,s8
    800066d0:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800066d2:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    800066d6:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800066da:	f6078693          	addi	a3,a5,-160
    800066de:	6218                	ld	a4,0(a2)
    800066e0:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800066e2:	00878513          	addi	a0,a5,8
    800066e6:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    800066e8:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800066ea:	6208                	ld	a0,0(a2)
    800066ec:	96aa                	add	a3,a3,a0
    800066ee:	4741                	li	a4,16
    800066f0:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800066f2:	4705                	li	a4,1
    800066f4:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    800066f8:	f8442703          	lw	a4,-124(s0)
    800066fc:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006700:	0712                	slli	a4,a4,0x4
    80006702:	953a                	add	a0,a0,a4
    80006704:	058a8693          	addi	a3,s5,88
    80006708:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000670a:	6208                	ld	a0,0(a2)
    8000670c:	972a                	add	a4,a4,a0
    8000670e:	40000693          	li	a3,1024
    80006712:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006714:	001c3c13          	seqz	s8,s8
    80006718:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000671a:	001c6c13          	ori	s8,s8,1
    8000671e:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    80006722:	f8842603          	lw	a2,-120(s0)
    80006726:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    8000672a:	0001c697          	auipc	a3,0x1c
    8000672e:	efe68693          	addi	a3,a3,-258 # 80022628 <disk>
    80006732:	00258713          	addi	a4,a1,2
    80006736:	0712                	slli	a4,a4,0x4
    80006738:	9736                	add	a4,a4,a3
    8000673a:	587d                	li	a6,-1
    8000673c:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006740:	0612                	slli	a2,a2,0x4
    80006742:	9532                	add	a0,a0,a2
    80006744:	f9078793          	addi	a5,a5,-112
    80006748:	97b6                	add	a5,a5,a3
    8000674a:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    8000674c:	629c                	ld	a5,0(a3)
    8000674e:	97b2                	add	a5,a5,a2
    80006750:	4605                	li	a2,1
    80006752:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006754:	4509                	li	a0,2
    80006756:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    8000675a:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000675e:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006762:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006766:	6698                	ld	a4,8(a3)
    80006768:	00275783          	lhu	a5,2(a4)
    8000676c:	8b9d                	andi	a5,a5,7
    8000676e:	0786                	slli	a5,a5,0x1
    80006770:	97ba                	add	a5,a5,a4
    80006772:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006776:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000677a:	6698                	ld	a4,8(a3)
    8000677c:	00275783          	lhu	a5,2(a4)
    80006780:	2785                	addiw	a5,a5,1
    80006782:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006786:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000678a:	100017b7          	lui	a5,0x10001
    8000678e:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006792:	004aa783          	lw	a5,4(s5)
    80006796:	02c79163          	bne	a5,a2,800067b8 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    8000679a:	0001c917          	auipc	s2,0x1c
    8000679e:	fb690913          	addi	s2,s2,-74 # 80022750 <disk+0x128>
  while(b->disk == 1) {
    800067a2:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800067a4:	85ca                	mv	a1,s2
    800067a6:	8556                	mv	a0,s5
    800067a8:	ffffc097          	auipc	ra,0xffffc
    800067ac:	c6c080e7          	jalr	-916(ra) # 80002414 <sleep>
  while(b->disk == 1) {
    800067b0:	004aa783          	lw	a5,4(s5)
    800067b4:	fe9788e3          	beq	a5,s1,800067a4 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    800067b8:	f8042903          	lw	s2,-128(s0)
    800067bc:	00290793          	addi	a5,s2,2
    800067c0:	00479713          	slli	a4,a5,0x4
    800067c4:	0001c797          	auipc	a5,0x1c
    800067c8:	e6478793          	addi	a5,a5,-412 # 80022628 <disk>
    800067cc:	97ba                	add	a5,a5,a4
    800067ce:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800067d2:	0001c997          	auipc	s3,0x1c
    800067d6:	e5698993          	addi	s3,s3,-426 # 80022628 <disk>
    800067da:	00491713          	slli	a4,s2,0x4
    800067de:	0009b783          	ld	a5,0(s3)
    800067e2:	97ba                	add	a5,a5,a4
    800067e4:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800067e8:	854a                	mv	a0,s2
    800067ea:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800067ee:	00000097          	auipc	ra,0x0
    800067f2:	b98080e7          	jalr	-1128(ra) # 80006386 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800067f6:	8885                	andi	s1,s1,1
    800067f8:	f0ed                	bnez	s1,800067da <virtio_disk_rw+0x1e6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800067fa:	0001c517          	auipc	a0,0x1c
    800067fe:	f5650513          	addi	a0,a0,-170 # 80022750 <disk+0x128>
    80006802:	ffffb097          	auipc	ra,0xffffb
    80006806:	848080e7          	jalr	-1976(ra) # 8000104a <release>
}
    8000680a:	70e6                	ld	ra,120(sp)
    8000680c:	7446                	ld	s0,112(sp)
    8000680e:	74a6                	ld	s1,104(sp)
    80006810:	7906                	ld	s2,96(sp)
    80006812:	69e6                	ld	s3,88(sp)
    80006814:	6a46                	ld	s4,80(sp)
    80006816:	6aa6                	ld	s5,72(sp)
    80006818:	6b06                	ld	s6,64(sp)
    8000681a:	7be2                	ld	s7,56(sp)
    8000681c:	7c42                	ld	s8,48(sp)
    8000681e:	7ca2                	ld	s9,40(sp)
    80006820:	7d02                	ld	s10,32(sp)
    80006822:	6de2                	ld	s11,24(sp)
    80006824:	6109                	addi	sp,sp,128
    80006826:	8082                	ret

0000000080006828 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006828:	1101                	addi	sp,sp,-32
    8000682a:	ec06                	sd	ra,24(sp)
    8000682c:	e822                	sd	s0,16(sp)
    8000682e:	e426                	sd	s1,8(sp)
    80006830:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006832:	0001c497          	auipc	s1,0x1c
    80006836:	df648493          	addi	s1,s1,-522 # 80022628 <disk>
    8000683a:	0001c517          	auipc	a0,0x1c
    8000683e:	f1650513          	addi	a0,a0,-234 # 80022750 <disk+0x128>
    80006842:	ffffa097          	auipc	ra,0xffffa
    80006846:	754080e7          	jalr	1876(ra) # 80000f96 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000684a:	10001737          	lui	a4,0x10001
    8000684e:	533c                	lw	a5,96(a4)
    80006850:	8b8d                	andi	a5,a5,3
    80006852:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006854:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006858:	689c                	ld	a5,16(s1)
    8000685a:	0204d703          	lhu	a4,32(s1)
    8000685e:	0027d783          	lhu	a5,2(a5)
    80006862:	04f70863          	beq	a4,a5,800068b2 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006866:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000686a:	6898                	ld	a4,16(s1)
    8000686c:	0204d783          	lhu	a5,32(s1)
    80006870:	8b9d                	andi	a5,a5,7
    80006872:	078e                	slli	a5,a5,0x3
    80006874:	97ba                	add	a5,a5,a4
    80006876:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006878:	00278713          	addi	a4,a5,2
    8000687c:	0712                	slli	a4,a4,0x4
    8000687e:	9726                	add	a4,a4,s1
    80006880:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006884:	e721                	bnez	a4,800068cc <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006886:	0789                	addi	a5,a5,2
    80006888:	0792                	slli	a5,a5,0x4
    8000688a:	97a6                	add	a5,a5,s1
    8000688c:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000688e:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006892:	ffffc097          	auipc	ra,0xffffc
    80006896:	be6080e7          	jalr	-1050(ra) # 80002478 <wakeup>

    disk.used_idx += 1;
    8000689a:	0204d783          	lhu	a5,32(s1)
    8000689e:	2785                	addiw	a5,a5,1
    800068a0:	17c2                	slli	a5,a5,0x30
    800068a2:	93c1                	srli	a5,a5,0x30
    800068a4:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800068a8:	6898                	ld	a4,16(s1)
    800068aa:	00275703          	lhu	a4,2(a4)
    800068ae:	faf71ce3          	bne	a4,a5,80006866 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800068b2:	0001c517          	auipc	a0,0x1c
    800068b6:	e9e50513          	addi	a0,a0,-354 # 80022750 <disk+0x128>
    800068ba:	ffffa097          	auipc	ra,0xffffa
    800068be:	790080e7          	jalr	1936(ra) # 8000104a <release>
}
    800068c2:	60e2                	ld	ra,24(sp)
    800068c4:	6442                	ld	s0,16(sp)
    800068c6:	64a2                	ld	s1,8(sp)
    800068c8:	6105                	addi	sp,sp,32
    800068ca:	8082                	ret
      panic("virtio_disk_intr status");
    800068cc:	00002517          	auipc	a0,0x2
    800068d0:	0bc50513          	addi	a0,a0,188 # 80008988 <syscalls+0x3e8>
    800068d4:	ffffa097          	auipc	ra,0xffffa
    800068d8:	02a080e7          	jalr	42(ra) # 800008fe <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
