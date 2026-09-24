#include "StaticType.h"
#include <stdio.h>
#include <stdlib.h>

void Input(int* a) {
  if (scanf("%d", a) == EOF) {
    exit(0);
  }
}

void Output(int* x, int* y, int* z) {
  printf("%d %d %d\n", *x, *y, *z);
}

int main() {
  ActivateStaticType();
}
