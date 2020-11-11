/*
 * Created by Meissa project team in 2020
 */

#include <sys/types.h>
#include <unistd.h>
#include <time.h>
#include <stdio.h>

int
main()
{
  struct tm tm;
  tm.tm_gmtoff = 0;
  printf("%d", (int)tm.tm_gmtoff);
  return 0;
}
