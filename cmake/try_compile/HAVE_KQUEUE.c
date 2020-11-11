/*
 * Created by Meissa project team in 2020
 */

#include <sys/types.h>
#include <unistd.h>
#include <sys/event.h>

int
main()
{
  (void)kqueue();
  return 0;
}
