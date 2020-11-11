/*
 * Created by Meissa project team in 2020
 */

#include <sys/types.h>
#include <unistd.h>
#include <sys/eventfd.h>

int
main()
{
  (void)eventfd(0, 0);
  return 0;
}
