/*
 * Created by Meissa project team in 2020
 */

#include <sys/types.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>

int
main()
{
  setsockopt(0, IPPROTO_IP, IP_BIND_ADDRESS_NO_PORT, NULL, 0);
  return 0;
}
