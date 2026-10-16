#include <algorithm>
#include <cstddef>
#include <exception>
#include <iostream>
#include <limits>
#include <memory>
#include <new>
#include <stdexcept>
#include <sys/types.h>
#include <vector>
class Arena {

private:
  std::size_t capacity_; // total number of bytes
  std::size_t used_; //(actually allocator's current position) bytes consumed
                     // including padding
  std::unique_ptr<std::byte[]> storage_; // memory owner

public:
  explicit Arena(std::size_t capacity)
      : capacity_{capacity}, used_(0),
        storage_(capacity ? std::make_unique<std::byte[]>(capacity) : nullptr) {
  }

  Arena(const Arena &) = delete;
  Arena &operator=(const Arena &) = delete;

  std::size_t used() const noexcept { return used_; }
  std::size_t capacity() const noexcept { return capacity_; }

  // allocate() --> to find a suitable region within the existing allocation
  void *allocate(std::size_t bytes, std::size_t alignment) {
    if (alignment == 0 || (alignment & (alignment - 1)) != 0) {
      throw std::invalid_argument("Alignment must be a non zero power of 2");
    }

    if (bytes == 0) {
      throw std::invalid_argument("Zero byte allocation is not supported");
    }

    if (used_ > capacity_ || !storage_) {
      throw std::bad_alloc{};
    }

    // to get a suitanle aligned address
    void *candidate = storage_.get() + used_;
    std::size_t space = capacity_ - used_;

    // std""align adjusts candidate to a suitable aligned address
    // if a suitable region exists, it returns its alifned address, otherwise
    // nullptr
    void *aligned = std::align(alignment, bytes, candidate, space);

    if (aligned == nullptr) {
      throw std::bad_alloc{};
    }

    // calculating the new cursor

    // convert to std::byte* so we can perform some pointer operations
    auto *aligned_bytes = static_cast<std::byte *>(aligned);
    // records the end of the allocation, includes padding also
    used_ = static_cast<std::size_t>(aligned_bytes - storage_.get()) + bytes;

    return aligned;
  }

  // this doesn't invalidate the now old pointers tho
  void reset() { used_ = 0; }
};

std::size_t check_element_size_boundary(size_t rows, size_t cols){
    if (rows == 0 || cols == 0) {
        throw std::invalid_argument("Tensor dimenstions cannot be zero");
    }

    // before multiplying
    if (rows > std::numeric_limits<std::size_t>::max()/cols) {
        throw std::length_error("Tensor element count overflow");
    }

    const std::size_t element_count = rows * cols;
    // checking element_count * sizeof(double) before multiplying
    if (element_count >
        std::numeric_limits<std::size_t>::max() / sizeof(double)) {
      throw std::length_error("Tensor byte count overflow");
    }

    return element_count;
}

struct Tensor {
  double *data;
  std::size_t rows;
  std::size_t cols;

  std::size_t elements() const { return rows * cols; }

  double &operator()(std::size_t row, std::size_t col) {
    if (row >= rows || col >= cols) {
      throw std::out_of_range("Tensor index out of range");
    }
    return data[row * cols + col];
  }

  const double &operator()(std::size_t row, std::size_t col) const {
    if (row >= rows || col >= cols) {
      throw std::out_of_range("Tensor index out of range");
    }
    return data[row * cols + col];
  }
};

Tensor make_tensor(Arena &arena, std::size_t rows, std::size_t cols) {
  if (rows == 0 || cols == 0) {
    throw std::invalid_argument("Tensor argument cannot be zero");
  }

  if (rows > std::numeric_limits<std::size_t>::max() / cols) {
    throw std::length_error("Tensor element count overfloe");
  }

  const std::size_t element_count = rows * cols;
  if (element_count >
      std::numeric_limits<std::size_t>::max() / sizeof(double)) {
    throw std::length_error("Tensor byte count overflow");
  }

  void *raw_data =
      arena.allocate(element_count * sizeof(double), alignof(double));
  double *data = static_cast<double *>(raw_data);
  return {data, rows, cols};
};

// matrix operations
void add(const Tensor &a, const Tensor &b, Tensor &result) {
  if (a.rows != b.rows || a.cols != b.cols || result.rows != a.rows ||
      result.cols != b.cols) {
    throw std::invalid_argument("Addition Dimension Requirement Violated");
  }

  for (std::size_t i = 0; i < a.elements(); ++i) {
    result.data[i] = a.data[i] + b.data[i];
  }
}

void multiply(const Tensor &a, const Tensor &b, Tensor &result) {
  if (a.cols != b.rows || result.rows != a.rows || result.cols != b.cols) {
    throw std::invalid_argument(
        "Multiplication Dimension Requirement Violation");
  }

  double *a_data = a.data;
  double *b_data = b.data;
  double *result_data = result.data;

  const std::size_t no_of_a_rows = a.rows;
  const std::size_t no_of_a_cols_and_b_rows = a.cols;
  const std::size_t no_of_b_cols = b.cols;

  // initializing all indices of the result, coz we can't perform
  // operation on an uninitalized one
  for (std::size_t i{0}; i < result.elements(); ++i) {
    result.data[i] = 0.0;
  }

  for (std::size_t i{0}; i < no_of_a_rows; ++i) {
    // result.data[i] = 0.0;
    for (std::size_t k{0}; k < no_of_a_cols_and_b_rows; ++k) {
      const double value = a_data[i * no_of_a_cols_and_b_rows + k];

      for (int j{0}; j < no_of_b_cols; ++j) {
        result_data[i * no_of_b_cols + j] +=
            value * b_data[k * no_of_b_cols + j];
      }
    }
  }
}

void print(const char *name, const Tensor &t) {
  std::cout << name << " (" << t.rows << " x " << t.cols << "):\n";

  const double *t_data = t.data;
  for (std::size_t i = 0; i < t.rows; ++i) {
    for (std::size_t j = 0; j < t.cols; ++j) {
      std::cout << t_data[i * t.cols + j] << ' ';
    }
    std::cout << '\n';
  }
}

struct TensorLifetime {
  std::string name;
  std::size_t first_use;
  std::size_t last_use;
  // identifies the reusable storage region, maybe for a tensor whose lifetime
  // expires
  std::size_t slot;
};

std::size_t plan_memory(std::vector<TensorLifetime> &tensors) {
  // we wanna process the tennsors in order of first use
  std::vector<std::size_t> order(tensors.size());

  // index the order
  for (std::size_t i{0}; i < order.size(); ++i) {
    order[i] = i;
  }

  // sorting the tensor lifetimes by first use,
  // if  the virst_use is the same vaiule, their initial order is preserved
  // using stable sort
  std::stable_sort(order.begin(), order.end(),
                   [&](std::size_t a, std::size_t b) {
                     return tensors[a].first_use < tensors[b].first_use;
                   });

  // this record the last use value of the tensor currently attached to each
  // slot
  /** e.g
   * slot_last_use = []
   * slot_last_use = [2, 5]
   * Slot 0: its currently assigned tensor has last_use = 2
   * Slot 1: its currently assigned tensor has last_use = 5
   */
  std::vector<std::size_t> slot_last_use;

  for (std::size_t index : order) {
    TensorLifetime &tensor = tensors[index];

    if (tensor.first_use > tensor.last_use) {
      throw std::invalid_argument("Invalid tensor lifetime");
    }

    bool assigned = false;

    for (std::size_t slot{0}; slot < slot_last_use.size(); ++slot) {
      /*
       * Has the tensor previously assigned to this slot finished its last
       * required use before the new tensor begins its first use
       * Existing slot's last_use = 2
       * New tensor's first_use   = 3 , then 2 < 3, the slot is reusable
       */
      if (slot_last_use[slot] < tensor.first_use) {
        tensor.slot =
            slot; // assign the existing slot to the current tensor
                  // update our record to refect the new tensor's last use
        slot_last_use[slot] = tensor.last_use;
        assigned = true; // record successful selextion of a slot
        break;
      }
    }

    // if we do not find a reusable slot
    if (!assigned) {
      //-- say there are two slots before  0 and 1
      // this one gets 2 , coz of zero indexing
      tensor.last_use = slot_last_use.size();
      // we record when this one finishes also
      slot_last_use.push_back(tensor.last_use);
    }
  }
}

// Fixed graph:
// A = X * W
// B = A + R
// Y = B + S
int main() {
  try {
    // 7 matrices each containing 4 doubles = 224 bytes
    Arena arena(256);

    Tensor x = make_tensor(arena, 2, 2);
    Tensor w = make_tensor(arena, 2, 2);
    Tensor r = make_tensor(arena, 2, 2);
    Tensor s = make_tensor(arena, 2, 2);

    Tensor a = make_tensor(arena, 2, 2);
    Tensor b = make_tensor(arena, 2, 2);
    Tensor y = make_tensor(arena, 2, 2);

    const double x_values[] = {1, 2, 3, 4};
    const double w_values[] = {5, 6, 7, 8};
    const double r_values[] = {1, 1, 1, 1};
    const double s_values[] = {2, 2, 2, 2};

    for (std::size_t i{0}; i < 4; ++i) {
      x.data[i] = x_values[i];
      w.data[i] = w_values[i];
      r.data[i] = r_values[i];
      s.data[i] = s_values[i];
    }

    multiply(x, w, a);
    add(a, r, b);
    add(b, s, y);

    print("A", a);
    print("B", b);
    print("Y", y);

    std::cout << "\nArena used: " << arena.used() << " / " << arena.capacity()
              << " bytes\n";

    // Expected Y = [[24, 27], [50, 57]].
    const double expected[] = {22, 25, 46, 53};

    for (std::size_t i = 0; i < 4; ++i) {
      if (y.data[i] != expected[i]) {
        throw std::runtime_error("Numerical tensor test failed");
      }
    }

    std::cout << "Numerical tensor test passed.\n";
  } catch (std::exception &e) {
    std::cerr << "Error in our MiniRt engine: " << e.what() << "\n";
    return 1;
  }

  return 0;
}
