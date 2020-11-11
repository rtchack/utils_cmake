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
  struct stat sb;
  openat(AT_FDCWD, ".", O_RDONLY | O_NOFOLLOW);
  fstatat(AT_FDCWD, ".", &sb, AT_SYMLINK_NOFOLLOW);
  return 0;
}
