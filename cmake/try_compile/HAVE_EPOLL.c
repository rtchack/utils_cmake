/*
 * Created by Meissa project team in 2020
 */

#include <sys/types.h>
#include <unistd.h>
#include <sys/epoll.h>

int
main()
{
  int efd = 0;
  struct epoll_event ee;
  ee.events = EPOLLIN | EPOLLOUT | EPOLLET;
  ee.data.ptr = NULL;
  (void)ee;
  efd = epoll_create(100);
  if (efd == -1) return 1;
  return 0;
}
