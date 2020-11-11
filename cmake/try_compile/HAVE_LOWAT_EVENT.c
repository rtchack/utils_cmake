/*
 * Created by Meissa project team in 2020
 */

#include <sys/types.h>
#include <unistd.h>
#include <sys/event.h>

int
main()
{
  struct kevent kev;
  kev.fflags = NOTE_LOWAT;
  (void)kev;
  return 0;
}
