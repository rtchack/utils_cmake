/*
 * Created by Meissa project team in 2020
 */

#include <stdio.h>
#define var(dummy, ...) sprintf(__VA_ARGS__)

int
main()
{
  char buf[30];
  buf[0] = '0';
  var(0, buf, "%d", 1);
  if (buf[0] != '1') return 1;
}
