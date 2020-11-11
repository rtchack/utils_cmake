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
  setsockopt(0, IPPROTO_IPV6, IPV6_RECVPKTINFO, NULL, 0);
  return 0;
}
