/*
 * Created by Meissa project team in 2020
 */

#include <sys/types.h>
#include <unistd.h>
#include <sys/sendfile.h>
#include <errno.h>

int
main()
{
  int s = 0, fd = 1;
  ssize_t n;
  off_t off = 0;
  n = sendfile(s, fd, &off, 1);
  if (n == -1 && errno == ENOSYS) return 1;
  return 0;
}
