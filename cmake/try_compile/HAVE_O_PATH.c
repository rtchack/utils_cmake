/*
 * Created by Meissa project team in 2020
 */

#include <sys/types.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

int
main()
{
  int fd;
  struct stat sb;
  fd = openat(AT_FDCWD, ".", O_PATH | O_DIRECTORY | O_NOFOLLOW);
  if (fstatat(fd, "", &sb, AT_EMPTY_PATH) != 0) return 1;
  return 0;
}
