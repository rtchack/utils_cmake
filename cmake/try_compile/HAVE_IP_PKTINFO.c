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
  struct in_pktinfo pkt;
  pkt.ipi_spec_dst.s_addr = INADDR_ANY;
  (void)pkt;
  setsockopt(0, IPPROTO_IP, IP_PKTINFO, NULL, 0);
  return 0;
}
