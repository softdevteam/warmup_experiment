/*
 * The Computer Language Benchmarks Game
 * http://shootout.alioth.debian.org/
 *
 * contributed by Ledrug Katz
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <err.h>

#define MAX_N 8
#define EXPECT_CKSUM 1616

/* this depends highly on the platform.  It might be faster to use
   char type on 32-bit systems; it might be faster to use unsigned. */

typedef int elem;

elem s[MAX_N], t[MAX_N];

int maxflips = 0;
int odd = 0;
u_int32_t checksum = 0;


int flip()
{
   printf("int flip()\n");
   register int i;
   register elem *x, *y, c;

   for (x = t, y = s, i = MAX_N; i--; )
   {
      printf("for (x = t, y = s, i = MAX_N; i--; )\n");
      *x++ = *y++;
   }
   i = 1;
   do
   {
      printf("do\n");
      for (x = t, y = t + t[0]; x < y; )
      {
         printf("for (x = t, y = t + t[0]; x < y; )\n");
         c = *x, *x++ = *y, *y-- = c;
      }
      i++;
   } while (t[t[0]]);
   return i;
}

inline void rotate(int n)
{
   printf("inline void rotate(int n)\n");
   elem c;
   register int i;
   c = s[0];
   for (i = 1; i <= n; i++)
   {
      printf("for (i = 1; i <= n; i++)\n");
      s[i-1] = s[i];
   }
   s[n] = c;
}

/* Tompkin-Paige iterative perm generation */
void tk()
{
   printf("void tk()\n");
   int i = 0, f, n = MAX_N;
   elem c[MAX_N] = {0};

   while (i < n)
   {
      printf("while (i < n)\n");
      rotate(i);
      if (c[i] >= i)
      {
         printf("if (c[i] >= i)\n");
         c[i++] = 0;
         continue;
      }

      c[i]++;
      i = 1;
      odd = ~odd;
      if (*s)
      {
         printf("if (*s)\n");
         f = s[s[0]] ? flip() : 1;
         if (f > maxflips) maxflips = f;
         checksum += odd ? -f : f;
      }
   }

   if (checksum != EXPECT_CKSUM)
   {
      printf("if (checksum != EXPECT_CKSUM)\n");
      errx(EXIT_FAILURE, "bad checksum: %d vs %d", checksum, EXPECT_CKSUM);
   }
}

void setup_state(void)
{
   printf("void setup_state(void)\n");
   int i;

   for (i = 0; i < MAX_N; i++)
   {
      printf("for (i = 0; i < MAX_N; i++)\n");
      s[i] = i;
   }
   checksum = 0;
   maxflips = 0;
   odd = 0;
}

void run_iter(int n)
{
   printf("void run_iter(int n)\n");
   int i;

   for (i = 0; i < n; i++)
   {
      printf("for (i = 0; i < n; i++)\n");
      setup_state();
      tk();
   }
}
