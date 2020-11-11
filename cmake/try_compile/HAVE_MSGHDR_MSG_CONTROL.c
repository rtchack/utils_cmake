/*
 * Created by Meissa project team in 2020
 */

#include <sys/types.h>
#include <unistd.h>
#include <sys/socket.h>
#include <stdio.h>

int
main()
{
  struct msghdr msg;
  printf("%d", (int)sizeof(msg.msg_control));
  return 0;
}
