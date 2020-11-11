/*
 * Created by Meissa project team in 2020.
 */

#include <sys/uio.h>

int
main()
{
  char buf[1];
  struct iovec vec[1];
  ssize_t n;
  vec[0].iov_base = buf;
  vec[0].iov_len = 1;
  n = pwritev(1, vec, 1, 0);
  if (n == -1) return 1;
}
