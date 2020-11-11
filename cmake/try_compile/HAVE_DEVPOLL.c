/*
 * Created by Meissa project team in 2020
 */

#include <sys/types.h>
#include <unistd.h>
#include <sys/devpoll.h>

int
main()
{
  int n, dp;
  struct dvpoll dvp;
  dp = 0;
  dvp.dp_fds = NULL;
  dvp.dp_nfds = 0;
  dvp.dp_timeout = 0;
  n = ioctl(dp, DP_POLL, &dvp);
  if (n == -1) return 1;
  return 0;
}
