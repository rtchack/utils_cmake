/*
 * Created by Meissa project team in 2020
 */

#include <sys/types.h>
#include <unistd.h>
#include <time.h>

int
main()
{
  struct tm t;
  time_t c = 0;
  localtime_r(&c, &t);
  return 0;
}
