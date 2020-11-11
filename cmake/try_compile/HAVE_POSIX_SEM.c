/*
 * Created by Meissa project team in 2020
 */

#include <sys/types.h>
#include <unistd.h>
#include <semaphore.h>

int
main()
{
  sem_t sem;
  if (sem_init(&sem, 1, 0) == -1) return 1;
  sem_destroy(&sem);
  return 0;
}
