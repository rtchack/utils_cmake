/*
 * Created by Meissa project team in 2020
 */

#include <sys/types.h>
#include <unistd.h>

int
main()
{
  if (__builtin_bswap64(0)) return 1;
  return 0;
}
