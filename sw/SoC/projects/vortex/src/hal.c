#include "hal.h"
#include "print.h"
#include "simplyv.h"
#include <stdarg.h>

void hal_printf(const char *restrict format, ...){
   va_list args;
   va_start(args, format);
   vprintf(format, args);
   va_end(args);
}

void hal_init(){
  simplyv_init();      // TinyIO Initialization
}
