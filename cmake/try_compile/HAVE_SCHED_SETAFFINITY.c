/*
 * Created by Meissa project team in 2020
 */

#include <sys/types.h>
#include <unistd.h>
#include <sched.h>

int
main()
{
  cpu_set_t mask;
  CPU_ZERO(&mask);
  sched_setaffinity(0, sizeof(cpu_set_t), &mask);
  return 0;
}
