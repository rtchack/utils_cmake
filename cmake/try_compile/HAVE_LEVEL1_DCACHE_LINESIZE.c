/*
 * Created by Meissa project team in 2020
 */

#include <sys/types.h>
#include <unistd.h>

int
main()
{
  sysconf(_SC_LEVEL1_DCACHE_LINESIZE);
  return 0;
}
