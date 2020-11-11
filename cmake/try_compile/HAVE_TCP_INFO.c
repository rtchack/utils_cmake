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
  socklen_t optlen = sizeof(struct tcp_info);
  struct tcp_info ti;
  ti.tcpi_rtt = 0;
  ti.tcpi_rttvar = 0;
  ti.tcpi_snd_cwnd = 0;
  ti.tcpi_rcv_space = 0;
  getsockopt(0, IPPROTO_TCP, TCP_INFO, &ti, &optlen);
  return 0;
}
