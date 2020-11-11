/*
 * Created by Meissa project team in 2020
 */

#include <sys/types.h>
#include <unistd.h>
#include <sys/socket.h>

int
main()
{
  accept4(0, NULL, NULL, SOCK_NONBLOCK);
  return 0;
}
