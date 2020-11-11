/*
 * Created by Meissa project team in 2020
 */

#include <sys/types.h>
#include <unistd.h>
#include <dlfcn.h>

int
main()
{
  dlopen(NULL, RTLD_NOW | RTLD_GLOBAL);
  dlsym(NULL, "");
  return 0;
}
