/* 
 * The Computer Language Benchmarks Game
 * http://shootout.alioth.debian.org/
 *
 * Contributed by Sebastien Loisel
 * Modified by Alex Belits
 */

#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#define SPECTRAL_N 1000
#define EXPECT_CKSUM 1.2742241481294835914184204739285632967948913574218750

double *A_global=NULL;
int N_global;

double eval_A(int i, int j) {
  printf("double eval_A(int i, int j) {\n");
  return 1.0/((i+j)*(i+j+1)/2+i+1);
}

int prepare_A(int N) {
  printf("int prepare_A(int N) {\n");
  int i,j;

  N_global=N;
  A_global=(double*)malloc(N*N*sizeof(double));

  if(A_global==NULL) return -1;

  for(i=0;i<N;i++) {
      printf("for(i=0;i<N;i++) {\n");
      for(j=0;j<N;j++) {
          printf("for(j=0;j<N;j++) {\n");
	  A_global[i*N+j]=eval_A(i,j);
      }
  }
  return 0;
}

double get_A(int i, int j) {
    printf("double get_A(int i, int j) {\n");
    return A_global[i*N_global+j];
}

void eval_A_times_u(int N, const double u[], double Au[]) {
  printf("void eval_A_times_u(int N, const double u[], double Au[]) {\n");
  int i,j,n2;
  double t0,t1;

  n2=N&~1;
  for(i=0;i<n2;i+=2) {
      printf("for(i=0;i<n2;i+=2) {\n");
      t0=0;
      t1=0;
      for(j=0;j<N;j++) {
          printf("for(j=0;j<N;j++) {\n");
	  t0+=get_A(i,j)*u[j];
	  t1+=get_A(i+1,j)*u[j];
	}
      Au[i]=t0;
      Au[i+1]=t1;
    }

  if(i!=N) {
      printf("if(i!=N) {\n");
      t0=0;
      for(j=0;j<N;j++) {
          printf("for(j=0;j<N;j++) {\n");
	  t0+=get_A(i,j)*u[j];
	}
      Au[i]=t0;
    }
}

void eval_At_times_u(int N, const double u[], double Au[]) {
  printf("void eval_At_times_u(int N, const double u[], double Au[]) {\n");
  int i,j,n4;
  double t0,t1,t2,t3;

  n4=N&~3;
  for(i=0;i<n4;i+=4) {
      printf("for(i=0;i<n4;i+=4) {\n");
      t0=0;
      t1=0;
      t2=0;
      t3=0;
      for(j=0;j<N;j++) {
          printf("for(j=0;j<N;j++) {\n");
	  t0+=get_A(j,i)*u[j];
	  t1+=get_A(j,i+1)*u[j];
	  t2+=get_A(j,i+2)*u[j];
	  t3+=get_A(j,i+3)*u[j];
        }
      Au[i]=t0;
      Au[i+1]=t1;
      Au[i+2]=t2;
      Au[i+3]=t3;
    }

  for(;i<N;i++) {
      printf("for(;i<N;i++) {\n");
      t0=0;
      for(j=0;j<N;j++) {
          printf("for(j=0;j<N;j++) {\n");
	  t0+=get_A(j,i)*u[j];
	}
      Au[i]=t0;
    }
}

void eval_AtA_times_u(int N, const double u[], double AtAu[]) {
  printf("void eval_AtA_times_u(int N, const double u[], double AtAu[]) {\n");
  double v[N];
  eval_A_times_u(N,u,v);
  eval_At_times_u(N,v,AtAu);
}

void inner_iter(N) {
  printf("void inner_iter(N) {\n");
  int i;
  double u[N],v[N],vBv,vv;
  double checksum = 0;

  for(i=0;i<N;i++) {
      printf("for(i=0;i<N;i++) {\n");
      u[i]=1;
  }
  for(i=0;i<10;i++) {
      printf("for(i=0;i<10;i++) {\n");
      eval_AtA_times_u(N,u,v);
      eval_AtA_times_u(N,v,u);
    }
  vBv=vv=0;
  for(i=0;i<N;i++) {
      printf("for(i=0;i<N;i++) {\n");
      vBv+=u[i]*v[i]; vv+=v[i]*v[i];
  }
  checksum = sqrt(vBv/vv);

  if (checksum != EXPECT_CKSUM) {
    printf("if (checksum != EXPECT_CKSUM) {\n");
    printf("bad checksum: %.52f vs %.52f\n", EXPECT_CKSUM, checksum);
    exit (EXIT_FAILURE);
  }
}

void run_iter(int n) {
  int i;

  if(prepare_A(SPECTRAL_N)){
    printf("if(prepare_A(SPECTRAL_N)){\n");
    printf("Insufficient memory\n");
    exit(EXIT_FAILURE);
  }

  for (i = 0; i < n; i++) {
    printf("for (i = 0; i < n; i++) {\n");
    inner_iter(SPECTRAL_N);
  }

  free(A_global);
}
