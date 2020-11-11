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
  setsockopt(0, IPPROTO_IP, IP_SENDSRCADDR, NULL, 0);
  return 0;
}
