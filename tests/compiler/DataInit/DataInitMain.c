#include "DataInit.h"
#include <stdio.h>
#include <stdlib.h>

void Input(int* a) {
  if (scanf("%d", a) == EOF) {
    exit(0);
  }
}

void Output(int* x1, int* x2, int* acc) {
  printf("%d %d %d\n", *x1, *x2, *acc);
}

int main() {
  ActivateDataInit();
}
