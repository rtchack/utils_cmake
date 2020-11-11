/*
 * Created by Meissa project team in 2020
 */

#include <sys/types.h>
#include <unistd.h>

int
main()
{
  char buf[1];
  ssize_t n;
  n = pread(0, buf, 1, 0);
  if (n == -1) return 1;
  return 0;
}
