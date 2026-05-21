#include <stdlib.h>
#include <sys/utsname.h>
__attribute__((constructor)) static void inject() {
  setenv("QEMU_CPU", "max", 1);
}
