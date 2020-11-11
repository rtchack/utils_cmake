/*
 * Created by Meissa project team in 2020
 */

#include <sys/types.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/statvfs.h>

int
main()
{
  struct statvfs fs;
  statvfs(".", &fs);
  return 0;
}
