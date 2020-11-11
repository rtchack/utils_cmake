/*
 * Created by Meissa project team in 2020.
 */
#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>

int
main()
{
  void *p;
  int fd;
  fd = open("/dev/zero", O_RDWR);
  p = mmap(NULL, 4096, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
  if (p == MAP_FAILED) return 1;
}
