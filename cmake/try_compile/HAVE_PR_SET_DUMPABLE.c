/*
 * Created by Meissa project team in 2020
 */

#include <sys/types.h>
#include <unistd.h>
#include <sys/prctl.h>

int
main()
{
  if (prctl(PR_SET_DUMPABLE, 1, 0, 0, 0) == -1) return 1;
  return 0;
}
