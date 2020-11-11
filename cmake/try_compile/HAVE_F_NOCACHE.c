/*
 * Created by Meissa project team in 2020
 */

#include <sys/types.h>
#include <unistd.h>
#include <fcntl.h>

int
main()
{
  fcntl(0, F_NOCACHE, 1);
  return 0;
}
