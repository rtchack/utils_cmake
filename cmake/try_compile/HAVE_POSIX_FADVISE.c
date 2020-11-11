/*
 * Created by Meissa project team in 2020
 */

#include <sys/types.h>
#include <unistd.h>
#include <fcntl.h>

int
main()
{
  posix_fadvise(0, 0, 0, POSIX_FADV_SEQUENTIAL);
  return 0;
}
