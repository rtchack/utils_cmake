/*
 * Created by Meissa project team in 2020
 */

#include <sys/types.h>
#include <unistd.h>
#include <linux/aio_abi.h>
#include <sys/eventfd.h>

int
main()
{
  struct iocb iocb;
  iocb.aio_lio_opcode = IOCB_CMD_PREAD;
  iocb.aio_flags = IOCB_FLAG_RESFD;
  iocb.aio_resfd = -1;
  (void)iocb;
  (void)eventfd(0, 0);
  return 0;
}
