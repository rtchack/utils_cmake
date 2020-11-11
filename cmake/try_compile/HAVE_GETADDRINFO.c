/*
 * Created by Meissa project team in 2020.
 */
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>

int
main()
{
  struct addrinfo *res;
  if (getaddrinfo("localhost", NULL, NULL, &res) != 0) return 1;
  freeaddrinfo(res);
}
