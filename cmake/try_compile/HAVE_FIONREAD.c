/*
 * Created by Meissa project team in 2020
 */

#include <sys/types.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <stdio.h>
#include <sys/filio.h>

int
main()
{
  int i = FIONREAD;
  printf("%d", i);
  return 0;
}
