/*
 * Created by Meissa project team in 2020
 */

#include <sys/types.h>
#include <unistd.h>
#include <linux/capability.h>
#include <sys/syscall.h>

int
main()
{
  struct __user_cap_data_struct data;
  struct __user_cap_header_struct header;
  header.version = _LINUX_CAPABILITY_VERSION_1;
  data.effective = CAP_TO_MASK(CAP_NET_RAW);
  data.permitted = 0;
  (void)header;
  (void)data;
  (void)SYS_capset;
  return 0;
}
