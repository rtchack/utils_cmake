/*
 * Created by Meissa project team in 2020
 */

#include <sys/types.h>
#include <unistd.h>
#include <sys/socket.h>

int
main()
{
  setsockopt(0, SOL_SOCKET, SO_REUSEPORT, NULL, 0);
  return 0;
}
