/*
 * Created by Meissa project team in 2020
 */

#include <sys/types.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/tcp.h>

int
main()
{
  setsockopt(0, IPPROTO_TCP, TCP_FASTOPEN, NULL, 0);
  return 0;
}
