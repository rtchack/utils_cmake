/*
 * Created by Meissa project team in 2020
 */

int
main()
{
  long n = 0;
  if (!__sync_bool_compare_and_swap(&n, 0, 1)) return 1;
  if (__sync_fetch_and_add(&n, 1) != 1) return 1;
  if (n != 2) return 1;
  __sync_synchronize();
}
