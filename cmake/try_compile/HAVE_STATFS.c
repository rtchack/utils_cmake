/*
 * Created by Meissa project team in 2020
 */

#include <sys/types.h>
#include <unistd.h>
#include <sys/param.h>
#include <sys/mount.h>
#include <sys/vfs.h>

int
main()
{
  struct statfs fs;
  statfs(".", &fs);
  return 0;
}
