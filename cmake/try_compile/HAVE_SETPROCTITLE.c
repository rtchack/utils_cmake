/*
 * Created by Meissa project team in 2020
 */

#include <sys/types.h>
#include <unistd.h>
#include <stdlib.h>

int
main()
{
  setproctitle("test");
  return 0;
}
