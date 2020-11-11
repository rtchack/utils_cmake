/*
 * Created by Meissa project team in 2020
 */

#include <sys/types.h>
#include <unistd.h>
#include <sys/mman.h>

int
main()
{
  void *p;
  p = mmap(NULL, 4096, PROT_READ | PROT_WRITE, MAP_ANON | MAP_SHARED, -1, 0);
  if (p == MAP_FAILED) return 1;
  return 0;
}
