/*
 * Created by Meissa project team in 2020
 */

#include <sys/types.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/fcntl.h>

int
main()
{
  directio(0, DIRECTIO_ON);
  return 0;
}
