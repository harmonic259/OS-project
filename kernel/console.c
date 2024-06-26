//
// Console input and output, to the uart.
// Reads are line at a time.
// Implements special input characters:
//   newline -- end of line
//   control-h -- backspace
//   control-u -- kill line
//   control-d -- end of file
//   control-p -- print process list
//

#include <stdarg.h>

#include "types.h"
#include "param.h"
#include "spinlock.h"
#include "sleeplock.h"
#include "fs.h"
#include "file.h"
#include "memlayout.h"
#include "riscv.h"
#include "defs.h"
#include "proc.h"
#include "history.h"

#define BACKSPACE 0x100
#define C(x)  ((x)-'@')  // Control-x

//
// send one character to the uart.
// called by printf(), and to echo input characters,
// but not from write().
//
void
consputc(int c)
{
  if(c == BACKSPACE){
    // if the user typed backspace, overwrite with a space.
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
  } else {
    uartputc_sync(c);
  }
}

struct {
  struct spinlock lock;
  
  // input
#define INPUT_BUF_SIZE 128
  char buf[INPUT_BUF_SIZE];
  uint r;  // Read index
  uint w;  // Write index
  uint e;  // Edit index
} cons;

int hist_index = -1;
int commandLength;
struct historyBufferArray historyBuffer;


void saveCommand() {
    char historyCommand[8] = {'h', 'i', 's', 't', 'o', 'r', 'y', '\0'};
    commandLength--;
    int isHistory = 1;
    for (int i = 0; i < 7; i++) {
        if (historyBuffer.currentCommand[i] != historyCommand[i]) {
            isHistory = 0;
            break;
        }
    }

    if (isHistory == 0) {
        for (int i = 0; i < commandLength; i++) {
            historyBuffer.bufferArr[historyBuffer.lastCommandIndex][i] = historyBuffer.currentCommand[i];
        }
        historyBuffer.lengthArr[historyBuffer.lastCommandIndex] = commandLength;
        historyBuffer.numOfCommandsInMem++;
        if (historyBuffer.numOfCommandsInMem > 16)
            historyBuffer.numOfCommandsInMem = 16;
        historyBuffer.lastCommandIndex = (historyBuffer.lastCommandIndex + 1) % MAX_HISTORY;
    }

    commandLength = 0;


}

//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
  int i;

  for(i = 0; i < n; i++){
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
      break;
    uartputc(c);
  }

  return i;
}

//
// user read()s from the console go here.
// copy (up to) a whole input line to dst.
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
  uint target;
  int c;
  char cbuf;

  target = n;
  acquire(&cons.lock);
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
      if(n < target){
        // Save ^D for next time, to make sure
        // caller gets a 0-byte result.
        cons.r--;
      }
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
      break;

    dst++;
    --n;

    if(c == '\n'){
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);

  return target - n;
}

//
// the console input interrupt handler.
// uartintr() calls this for input character.
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
  acquire(&cons.lock);
  int index = 0;

  switch(c){
  case C('P'):  // Print process list.
    procdump();
    break;
  case C('Y'): //pgdn
      while (cons.e != cons.w &&
              cons.buf[(cons.e - 1) % INPUT_BUF] != '\n') {
          cons.e--;
          consputc(BACKSPACE);
      }
      hist_index--;
      index = (historyBuffer.lastCommandIndex - hist_index - 1) % MAX_HISTORY;
      if (index < 0) {
          index += MAX_HISTORY;
      }
      if (index < 0 || index > historyBuffer.numOfCommandsInMem - 1 || hist_index > 15) {
          hist_index = -1;
          break;
      }
      for (int i = 0; i < historyBuffer.lengthArr[index]; i++) {
          int cc = historyBuffer.bufferArr[index][i];
          cc = (cc == '\r') ? '\n' : cc;
          cons.buf[cons.e++ % INPUT_BUF] = cc;
          consputc(cc);
          historyBuffer.currentCommand[commandLength] = cc;
          commandLength++;
      }
      break;
  case C('X'): //pgup
      while (cons.e != cons.w &&
              cons.buf[(cons.e - 1) % INPUT_BUF] != '\n') {
          cons.e--;
          consputc(BACKSPACE);
      }
      hist_index++;
      index = (historyBuffer.lastCommandIndex - hist_index - 1) % MAX_HISTORY;
      if (index < 0) {
          index += MAX_HISTORY;
      }
      if (index < 0 || index > historyBuffer.numOfCommandsInMem - 1 || hist_index > 15) {
          hist_index = hist_index % historyBuffer.numOfCommandsInMem - 1;
          break;
      }
      for (int i = 0; i < historyBuffer.lengthArr[index]; i++) {
          int cc = historyBuffer.bufferArr[index][i];
          cc = (cc == '\r') ? '\n' : cc;
          cons.buf[cons.e++ % INPUT_BUF] = cc;
          consputc(cc);
          historyBuffer.currentCommand[commandLength] = cc;
          commandLength++;
      }
      break;


  case C('U'):  // Kill line.
    while(cons.e != cons.w &&
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
      cons.e--;
      consputc(BACKSPACE);
    }
    break;
  case C('H'): // Backspace
  case '\x7f': // Delete key
    if(cons.e != cons.w){
      cons.e--;
      consputc(BACKSPACE);
      commandLength--;
    }
    break;
  default:
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
      c = (c == '\r') ? '\n' : c;

      // echo back to the user.
      consputc(c);
      historyBuffer.currentCommand[commandLength] = c;
      commandLength++;
      // store for consumption by consoleread().
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;

      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
        // wake up consoleread() if a whole line (or end-of-file)
        // has arrived.
        saveCommand();
        cons.w = cons.e;
        wakeup(&cons.r);
      }
    }
    break;
  }
  
  release(&cons.lock);
}

void
consoleinit(void)
{
  initlock(&cons.lock, "cons");

  uartinit();

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
  devsw[CONSOLE].write = consolewrite;
}
