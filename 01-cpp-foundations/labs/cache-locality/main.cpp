#include "chrono"
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <iostream>
#include <ratio>
#include <vector>

/**
 *  -- - results - --
 *  Row checksum: 207617856
    Column checksum: 207617856
    Row first traversal time: 11.2979 ms
    Col first traversal time: 37.5 ms
 */

// row wise traversal is faster because the CPU fetches memory in cache lines
int main() {
  // flattened matrix of N X N
  constexpr std::size_t N = 2048;
  std::vector<int> matrix(N * N);

  // initializing the matrix outside the timed region to avoid
  //  benchmarking the time used in setting up the data
  for (std::size_t i{0}; i < N * N; i++) {
    matrix[i] = static_cast<int>(i % 100);
  }

  std::uint64_t rowCheckSum = 0;
  std::uint64_t colCheckSum = 0;

  //-- row first traversal
  // inner loop visits an entire row before outer loop moves to the next row
  auto startRow = std::chrono::steady_clock::now();
  for (std::size_t i = 0; i < N; ++i) {
    for (std::size_t j = 0; j < N; ++j) {
      // row * number of columns + column
      rowCheckSum += matrix[i * N + j];
    }
  }
  auto endRow = std::chrono::steady_clock::now();

  const std::chrono::duration<double, std::milli> rowDuration =
      endRow - startRow;

  //-- col wise traversal
  // the columns are accessed first, instead of accessing adjacent elements
  // say we  N =4, the access will be 0,4,8,12 then 1,5,9,13 and so on
  auto startCol = std::chrono::steady_clock::now();
  for (std::size_t j = 0; j < N; ++j) {
    for (std::size_t i = 0; i < N; ++i) {
      colCheckSum += matrix[i * N + j];
    }
  }
  auto endCol = std::chrono::steady_clock::now();

  const std::chrono::duration<double, std::milli> colDuration =
      endCol - startCol;

  std::cout << "Row checksum: " << rowCheckSum << '\n';
  std::cout << "Column checksum: " << colCheckSum << '\n';

  std::cout << "Row first traversal time: " << rowDuration.count() << " ms\n";
  std::cout << "Col first traversal time: " << colDuration.count() << " ms\n";

  return 0;
}
