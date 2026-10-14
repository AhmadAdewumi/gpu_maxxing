
#include <cstddef>
#include <limits>
#include <stdexcept>
#include <vector>

template <typename T> class Matrix {
private:
  std::size_t rows_;
  std::size_t cols_;
  std::vector<T> data_;

  /*
   * std::size_t has a maximum representable value, row*col may exceed the max
   * value and wraparound, so we need to guard agaisnt that,
   * i.e rows * cols <= SIZE_MAX, ==> rows  <= SiZE_MAX/cols
   */
  static std::size_t check_size_boundary(std::size_t rows, std::size_t cols) {
    if (cols != 0 && rows > std::numeric_limits<std::size_t>::max() / cols) {
      throw std::length_error("Matrix dimension overflow");
    }

    return rows * cols;
  }

public:
  Matrix(std::size_t rows, std::size_t cols)
      : rows_{rows}, cols_{cols}, data_(check_size_boundary(rows, cols)) {}

  std::size_t rows() const { return rows_; }

  std::size_t cols() const { return cols_; }
  std::size_t size() const { return data_.size(); }

  T *data() noexcept { return data_.data(); }

  const T *data() const noexcept { return data_.data(); }

  T &operator()(std::size_t row, std::size_t col) {
    if (row >= rows_ || col >= cols_) {
      throw std::out_of_range("Matrix index out of range");
    }

    return data_[row * cols_ + col];
  }

  const T &operator()(std::size_t row, std::size_t col) const {
    if (row >= rows_ || col >= cols_) {
      throw std::out_of_range("Matrix index out of range");
    }

    return data_[row * cols_ + col];
  }

  //  matrix addition (only for square matrices)
  Matrix operator+(const Matrix &other) {
    if (rows_ != other.rows_ || cols_ != other.cols_) {
      throw std::invalid_argument("Matrix dimensions must match for addition");
    }

    Matrix result(rows_, cols_);

    for (std::size_t i = 0; i < size(); ++i) {
      result[i] = data_[i] + other.data_[i];
    }

    return result;
  }
};

// for matrix multiplication, the inner dimension must match
// say we have matrix A(2,3) and B(3, 2) , and our result is C,
// the numbers of rows of A (2) will be the number of rows for C
//
// here, we pick one result cell, compute the sum before moving to the next cell
template <typename T>
Matrix<T> multiply_ijk(const Matrix<T> &a, const Matrix<T> &b) {
  if (a.cols() != b.rows()) {
    throw std::invalid_argument(
        "Incomaptible matrix dimensions for multiplication");
  }

  Matrix<T> results(a.rows(), b.cols());

  const std::size_t no_of_a_rows = a.rows();
  const std::size_t no_of_a_cols_and_no_of_b_rows =
      a.cols(); // a number column and same as b number of rows
  const std::size_t no_of_b_cols = b.cols();

  // iterate thru a rows
  for (std::size_t i{0}; i < no_of_a_rows;
       ++i) { //-- choose the row from a, say [2, 3]

    // iterate thru b cols                                                [5]
    for (std::size_t j{0}; j < no_of_b_cols;
         ++j) { // choose the column from b, say [6]
      T sum{};
      // --walks thru each choosen row and col, take matching elements,
      // multiply them and add it to our sum
      for (std::size_t k{0}; k < no_of_a_cols_and_no_of_b_rows; ++k) {
        sum += a(i, k) * b(k, j);
      }

      results(i, j) = sum;
    }
  }

  return results;
}

template <typename T>
Matrix<T> multiply_ikj(const Matrix<T> &a, const Matrix<T> &b) {
  if (a.cols() != b.rows()) {
    throw std::invalid_argument(
        "Incomaptible matrix dimensions for multiplication");
  }

  Matrix<T> results(a.rows(), b.cols());

  const std::size_t no_of_a_rows = a.rows();
  const std::size_t no_of_a_cols_and_no_of_b_rows =
      a.cols(); // a number column and same as b number of rows
  const std::size_t no_of_b_cols = b.cols();
  // i chooses a row of matrix a
  for (std::size_t i{0}; i < no_of_a_rows; ++i) {
    // k loop is responsible for choosing an element of the row of matrix a
    for (std::size_t k{0}; k < no_of_a_cols_and_no_of_b_rows; ++k) {
      const T value = a(i, k);

      // j visits every column of b and then we multiply our earlier value with
      // each element there
      for (std::size_t j{0}; j < no_of_b_cols; ++j) {
        results(i, j) += value * b(k, j);
      }
    }
  }

  return results;
}


// actually, this should be fast when n is large like 1024, but tf, it is so slowwwww
template <typename T>
Matrix<T> multiply_block_by_block(const Matrix<T> &a, const Matrix<T> &b,
                                  std::size_t block_size = 32) {
  if (a.cols() != b.rows()) {
    throw std::invalid_argument(
        "Incomaptible matrix dimensions for multiplication");
  }

  if (block_size == 0) {
    throw std::invalid_argument("Block size must be positive");
  }

  Matrix<T> results(a.rows(), b.cols());

  const std::size_t no_of_a_rows = a.rows();
  const std::size_t no_of_a_cols_and_no_of_b_rows =
      a.cols(); // a number column and same as b number of rows
  const std::size_t no_of_b_cols = b.cols();

  //-- these 3 outer loops choose which block should be worked on
  for (std::size_t ii{0}; ii < no_of_a_rows; ii += block_size) {
    for (std::size_t kk = 0; kk < no_of_a_cols_and_no_of_b_rows;
         kk += block_size) {
      for (std::size_t jj = 0; jj < no_of_b_cols; jj += block_size) {
        // to get the min between block size and matrix dimensions, so we do not
        // go out of scope
        const std::size_t i_end = ii + std::min(block_size, no_of_a_rows - ii);
        const std::size_t k_end =
            ii + std::min(block_size, no_of_a_cols_and_no_of_b_rows - kk);
        const std::size_t j_end = ii + std::min(block_size, no_of_b_cols - jj);

        for (std::size_t i{ii}; i < i_end; ++i) {
          for (std::size_t k{kk}; k < k_end; ++k) {
            const T value = a(i, k);
            for (std::size_t j{jj}; j < j_end; ++j) {
              results(i, j) += value * b(k, j);
            }
          }
        }
      }
    }
  }
  return results;
}
