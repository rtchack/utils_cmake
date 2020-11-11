/*
 * Created by Meissa project team in 2020
 */

#include <sys/types.h>
#include <unistd.h>
#include <stdlib.h>
#include <malloc.h>

int
main()
{
  void *p;
  p = memalign(4096, 4096);
  if (p == NULL) return 1;
  return 0;
}
