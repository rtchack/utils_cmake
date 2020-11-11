/*
 * Created by Meissa project team in 2020
 */

#include <sys/types.h>
#include <unistd.h>
#include <stdlib.h>

int
main()
{
  void *p;
  int n;
  n = posix_memalign(&p, 4096, 4096);
  if (n != 0) return 1;
  return 0;
}
