/*
 * Created by Meissa project team in 2020
 */

#include <sys/types.h>
#include <unistd.h>
#include <time.h>

int
main()
{
  struct timespec ts;
  clock_gettime(CLOCK_MONOTONIC, &ts);
  return 0;
}
