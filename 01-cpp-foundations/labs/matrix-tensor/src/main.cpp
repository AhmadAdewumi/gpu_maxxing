#include "../include/Matrix.hpp"
#include <cassert>

int main() {
  Matrix<int> matrix(3, 4);

  matrix(1, 2) = 87;

  assert(matrix.rows() == 3);
  assert(matrix.cols() == 4);
  assert(matrix(1, 2) == 87);
}
