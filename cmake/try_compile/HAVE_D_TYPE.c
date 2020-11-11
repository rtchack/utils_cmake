/*
 * Created by Meissa project team in 2020
 */

#include <sys/types.h>
#include <unistd.h>
#include <dirent.h>
#include <stdio.h>

int
main()
{
  struct dirent dir;
  dir.d_type = DT_REG;
  printf("%d", (int)dir.d_type);
  return 0;
}
