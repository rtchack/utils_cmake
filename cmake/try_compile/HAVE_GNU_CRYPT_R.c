/*
 * Created by Meissa project team in 2020
 */

#include <sys/types.h>
#include <unistd.h>
#include <crypt.h>

int
main()
{
  struct crypt_data cd;
  crypt_r("key", "salt", &cd);
  return 0;
}
