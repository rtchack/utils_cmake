/*
 * Created by Meissa project team in 2020
 */

#include <sys/types.h>
#include <unistd.h>
#include <sys/event.h>
#include <sys/time.h>

int
main()
{
  int kq;
  struct kevent kev;
  struct timespec ts;
  if ((kq = kqueue()) == -1) return 1;
  kev.ident = 0;
  kev.filter = EVFILT_TIMER;
  kev.flags = EV_ADD | EV_ENABLE;
  kev.fflags = 0;
  kev.data = 1000;
  kev.udata = 0;
  ts.tv_sec = 0;
  ts.tv_nsec = 0;
  if (kevent(kq, &kev, 1, &kev, 1, &ts) == -1) return 1;
  if (kev.flags & EV_ERROR) return 1;
  return 0;
}
