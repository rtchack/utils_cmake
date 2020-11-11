/*
 * Created by Meissa project team in 2020
 */

#include <sys/types.h>
#include <unistd.h>
#include <sys/ipc.h>
#include <sys/shm.h>

int
main()
{
  int id;
  id = shmget(IPC_PRIVATE, 4096, (SHM_R | SHM_W | IPC_CREAT));
  if (id == -1) return 1;
  shmctl(id, IPC_RMID, NULL);
  return 0;
}
