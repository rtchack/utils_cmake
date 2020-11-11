/*
 * Created by Meissa project team in 2020
 */

#include <sys/types.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

int
main()
{
  struct sockaddr_in6 sin6;
  sin6.sin6_family = AF_INET6;
  (void)sin6;
  return 0;
}
