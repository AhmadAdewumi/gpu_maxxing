#include "../include/Matrix.hpp"
#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstddef>
#include <ctime>
#include <iostream>
#include <ratio>
#include <vector>

using Clock = std::chrono::steady_clock;

template <typename Function>
double benchmark_matrix(Function function, const Matrix<double> &a,
                        Matrix<double> &b) {

  // holds the execution times
  std::vector<double> times;
  double checksum = 0.0;

  for (int repitition = 0; repitition < 6; ++repitition) {
    const auto start = Clock::now();
    auto result = function(a, b);
    const auto stop = Clock::now();

    const double time_elapsed =
        std::chrono::duration<double, std::milli>(stop - start).count();

    // to prevent the compiler from optimizing this away, coz it may if it sees
    // it has no observable effect or not being used, dead code elimination, so
    // we use the result we got up there
    for (std::size_t i{0}; i < result.size(); ++i) {
      checksum += result.data()[i];
    }

    if (!std::isfinite(checksum)) {
      std::cerr << "E don go infinity ooo";
    }

    times.push_back(time_elapsed);
  }

  std::sort(times.begin(), times.end());

  std::cout << "Checksum result: " << checksum << "\n";

  // returning the median time
  std::size_t middle = times.size() / 2;
  return (times[middle - 1] + times[middle]) / 2.0;
}

int main() {
  constexpr std::size_t n = 1024;
  Matrix<double> a(n, n);
  Matrix<double> b(n, n);

  for (std::size_t i{0}; i < n; ++i) {
    for (std::size_t j{0}; j < n; ++j) {
      a(i, j) = static_cast<double>((i + j) % 9);
      b(i, j) = static_cast<double>((2 * i) + (0.2 * j));
    }
  }

  std::cout << "Matrix size: " << n << " x " << n << "\n";

  std::cout << "ijk: " << benchmark_matrix(multiply_ijk<double>, a, b)
            << "ms\n";
  std::cout << "ikj: " << benchmark_matrix(multiply_ikj<double>, a, b)
            << "ms\n";

  std::size_t block_size = 32;
  std::cout << "multiply block by block: "
            << benchmark_matrix(
                   [block_size](const auto &x, const auto &y) {
                     return multiply_block_by_block(x, y, block_size);
                   },
                   a, b) << "\n";
}
