#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <exception>
#include <iostream>
#include <iterator>
#include <limits>
#include <memory>
#include <new>
#include <stdexcept>
#include <string>
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

std::size_t checked_element_count(size_t rows, size_t cols) {
  if (rows == 0 || cols == 0) {
    throw std::invalid_argument("Tensor dimenstions cannot be zero");
  }

  // before multiplying
  if (rows > std::numeric_limits<std::size_t>::max() / cols) {
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

// describes what storage a tensor needs and when it needs the storage
struct TensorSpec {
  std::string name; // e.g "X", "A"
  std::size_t rows;
  std::size_t cols;

  // these guys describes the interval diring which the tensor's contents must
  // be preserved
  std::size_t live_from;
  std::size_t last_use;

  // identifies the reusable storage region, maybe for a tensor whose lifetime
  // expires
  std::size_t slot;
};

// describes one reusable storage slot
struct SlotSpec {
  std::size_t capacity_bytes; // records how manybytes the slot can accomodate
  // end of lifetime of the most recently asigned tensor to this slot
  std::size_t last_used;
};

struct MemoryPlan {
  std::vector<TensorSpec> tensors;
  std::vector<SlotSpec> slots;
};

// gets the tensors descriptions, work out a memory plan and returns it
// we are passing by value, because the slot  field of the tensor spec
// might change, and we do not want it affecting the caller's original vector
// because there are two major responsibilities, we have the storage order(how
// the tensor specs are stored)
//  and the processing order (the sequence in which the planner consider those
//  tensors), if we sort it diretly the original tensor record is reordered
MemoryPlan plan_memory(std::vector<TensorSpec> tensors) {
  // we wanna process the tennsors in order of first use
  std::vector<std::size_t> order(tensors.size());

  // index the order
  for (std::size_t i{0}; i < order.size(); ++i) {
    order[i] = i;
  }

  // validate sizes, lifetime and unique tensor names
  for (std::size_t i = 0; i < tensors.size(); ++i) {
    const TensorSpec &tensor = tensors[i];
    checked_element_count(tensor.rows, tensor.cols);
    // if using the void asted version, we are just explicitly saying the
    // returned count is discarded
    // (void)check_element_size_boundary(tensor.rows, tensor.cols);

    if (tensor.live_from > tensor.last_use) {
      throw std::invalid_argument("Invalid tensor lifetime for tensor: " +
                                  tensor.name);
    }

    for (std::size_t j = i + 1; j < tensors.size(); ++j) {
      if (tensors[j].name == tensor.name) {
        throw std::invalid_argument("Duplicate tensor name: " + tensor.name);
      }
    }
  }

  // sorting the tensor lifetimes by first use,
  std::stable_sort(order.begin(), order.end(),
                   [&](std::size_t a, std::size_t b) {
                     return tensors[a].live_from < tensors[b].live_from;
                   });

  // slot assignment
  std::vector<SlotSpec> slots;
  for (std::size_t index : order) {
    // non const and referenced, coz we need to modify thte slot
    TensorSpec &tensor = tensors[index];

    const std::size_t tensor_bytes =
        checked_element_count(tensor.rows, tensor.cols) * sizeof(double);

    bool assigned = false;
    // searching the existing slots
    for (std::size_t slot{0}; slot < slots.size(); ++slot) {
      const bool has_previous_tensor_finished =
          slots[slot].last_used < tensor.live_from;
      const bool has_enough_capacity =
          slots[slot].capacity_bytes >= tensor_bytes;

      if (has_previous_tensor_finished && has_enough_capacity) {
        tensor.slot = slot;
        slots[slot].last_used = tensor.last_use;
        assigned = true;
        break;
      }
    }

    if (!assigned) {
      tensor.slot = slots.size(); // assign a new slot position, e.g for first
      // tensor, 0 is assigned
      slots.push_back({tensor_bytes, tensor.last_use});
    }
  }

  // verify two tensors assigned to the same slot must not have overlapping
  // lifetimes
  for (std::size_t i{0}; i < tensors.size(); ++i) {
    for (std::size_t j = i + 1; j < tensors.size(); ++j) {
      if (tensors[i].slot != tensors[j].slot) {
        continue;
      }

      const bool lifetimes_do_not_overlap =
          tensors[i].last_use < tensors[j].live_from ||
          tensors[j].last_use < tensors[i].live_from;

      if (!lifetimes_do_not_overlap) {
        throw std::logic_error("Overlapping tensors share a slot");
      }
    }
  }

  return {std::move(tensors), std::move(slots)};
}

/**
 * Memory plan tells us A uses slot 2 and slot_data tells us where slot 2
 * actually lives in memory, this fnxtn looks up a tensor specification
 * finds its assigned slot and returns a tensor that points to the slots memory
 * BRIDGE BETWEEN THE PLAN AND THE ADDRESS
 */
Tensor get_tensor_view(const MemoryPlan &memory_plan,
                       std::vector<double *> &slot_data,
                       const std::string &name) {
  for (const auto &spec : memory_plan.tensors) {
    if (spec.name == name) {
      return {slot_data.at(spec.slot), // gives the ptr to that slot
              spec.rows, spec.cols};
    }
  }

  throw std::logic_error("Unknown tensor: " + name);
}

// TEST HELPERS
void require(bool condition, const char *message) {
  if (!condition) {
    throw std::runtime_error(message);
  }
}

void test_arena() {

  Arena arena(32);
  void *first = arena.allocate(8, 8);
  void *second = arena.allocate(8, 16);

  // test alignment
  require(reinterpret_cast<std::uintptr_t>(first) % 8 == 0,
          "Arena failed 8 bytes alignment");
  require(reinterpret_cast<std::uintptr_t>(second) % 16 == 0,
          "Arena failed 16 bytes alignment");

  // test capacity not exceeded
  require(arena.used() < arena.capacity(), "Arena usage exceeded capacity");

  // test capacity limit
  bool exhausted = false;
  try {
    arena.allocate(16, 8);
  } catch (const std::bad_alloc &) {
    exhausted = true;
  }

  require(exhausted, "Arena accepted allocation beyond its capacity");

  // testing invalid alignment
  bool bad_alignment = false;
  try {
    arena.allocate(8, 3); // the power of 2 clause should catch it
  } catch (const std::invalid_argument &) {
    bad_alignment = true;
  }

  require(bad_alignment, "Arena accepted invalid alignment");

  bool zero_bytes_alloc = false;
  try {
    arena.allocate(0, 8);
  } catch (const std::invalid_argument &) {
    zero_bytes_alloc = true;
  }
  require(zero_bytes_alloc,
          "You wanna allocate zero bytes, huh?? you stingy...");

  std::cout << "All arena tests passed!!!!!!!!" << "\n";
}

MemoryPlan example_plan() {
  return plan_memory({// name, rows, cols, live_from, last_use
                      {"X", 2, 2, 0, 1},
                      {"W", 2, 2, 0, 1},
                      {"R", 2, 2, 0, 2},
                      {"S", 2, 2, 0, 3},
                      {"A", 2, 2, 1, 2},
                      {"B", 2, 2, 2, 3},
                      {"Y", 2, 2, 3, 3}});
}

void test_planner() {
  const MemoryPlan plan = example_plan();

  require(plan.slots.size() == 5, "Planner should produce five slots");

  bool rejected = false;

  try {
    (void)plan_memory({{"bad", 2, 2, 3, 1}});
  } catch (const std::invalid_argument &) {
    rejected = true;
  }

  require(rejected, "Planner accepted an invalid lifetime");

  bool overflow_rejected = false;

  try {
    (void)checked_element_count(std::numeric_limits<std::size_t>::max(), 2);
  } catch (const std::length_error &) {
    overflow_rejected = true;
  }

  require(overflow_rejected, "Tensor size overflow was not rejected");

  std::cout << "Planner tests passed.\n";
}

// this doesn't automaitcally derive the graph and discover thier lifetimes

// EXECUTION
int main() {
  try {

    // running the tests
    test_arena();
    test_planner();

    MemoryPlan plan = example_plan();

    // Calculate the total capacity required by the slots.
    std::size_t total_bytes = 0;

    for (const auto &slot : plan.slots) {
      if (slot.capacity_bytes >
          std::numeric_limits<std::size_t>::max() - total_bytes) {
        throw std::length_error("Total arena capacity overflow");
      }

      total_bytes += slot.capacity_bytes;
    }

    // The planner's slot layout now determines arena size.
    // holds tensor values
    Arena arena(total_bytes);

    std::vector<double *> slot_data; // holds the ptr for tensor values in arena
    slot_data.reserve(plan.slots.size());

    // Allocate each physical slot exactly once.
    for (const auto &slot : plan.slots) {
      // cast to double as allocate() returns void
      auto *data = static_cast<double *>(
          arena.allocate(slot.capacity_bytes, alignof(double)));

      const std::size_t count = slot.capacity_bytes / sizeof(double);

      // placement new contructs an object in an existing storage, here(in data)
      //  instead of new memory on the heap like the normal new
      //  data+i performs the double offset, 8 bytes at a time
      //  for desruction, if it were a class, we will need to call the
      //  destructor but double is primitive, so we do not need that
      for (std::size_t i = 0; i < count; ++i) {
        ::new (static_cast<void *>(data + i)) double{};
      }

      slot_data.push_back(data);
    }

    // each Tensor now points to its planned slot.
    Tensor x = get_tensor_view(plan, slot_data, "X");
    Tensor w = get_tensor_view(plan, slot_data, "W");
    Tensor r = get_tensor_view(plan, slot_data, "R");
    Tensor s = get_tensor_view(plan, slot_data, "S");

    Tensor a = get_tensor_view(plan, slot_data, "A");
    Tensor b = get_tensor_view(plan, slot_data, "B");
    Tensor y = get_tensor_view(plan, slot_data, "Y");

    const double x_values[] = {1, 2, 3, 4};
    const double w_values[] = {5, 6, 7, 8};
    const double r_values[] = {1, 1, 1, 1};
    const double s_values[] = {2, 2, 2, 2};

    for (std::size_t i = 0; i < 4; ++i) {
      x.data[i] = x_values[i];
      w.data[i] = w_values[i];
      r.data[i] = r_values[i];
      s.data[i] = s_values[i];
    }

    // executing our computation
    // A = X * W
    // B = A + R
    // Y = B + S
    multiply(x, w, a);
    add(a, r, b);
    add(b, s, y);

    print("A", a);
    print("B", b);
    print("Y", y);

    std::cout << "\nMemory plan:\n";

    for (const auto &t : plan.tensors) {
      std::cout << t.name << " -> slot " << t.slot
                << " (live_from=" << t.live_from << ", last_use=" << t.last_use
                << ")\n";
    }

    // answer correctness validation
    const double expected[] = {22, 25, 46, 53};

    for (std::size_t i = 0; i < 4; ++i) {
      // alternative, exact comparison using (y.data[i] != expected[i])
      // we are comparing using a tolerance, fails if diff exceeds
      // (0.000000000001)
      if (std::abs(y.data[i] - expected[i]) > 1e-12) {
        throw std::runtime_error("Numerical tensor test failed");
      }
    }

    // Seven separate 2x2 double tensors gives:
    // 7 * 4 * sizeof(double) i.e 8 bytes = 224 bytes.
    constexpr std::size_t naive_bytes = 7 * 4 * sizeof(double);

    std::cout << "\nNaive tensor payload: " << naive_bytes << " bytes\n";

    std::cout << "Planned slot payload: " << total_bytes << " bytes\n";

    std::cout << "Arena used: " << arena.used() << " / " << arena.capacity()
              << " bytes\n";

    const double saved_percent =
        100.0 * static_cast<double>(naive_bytes - total_bytes) /
        static_cast<double>(naive_bytes);

    std::cout << "Payload reduction: " << saved_percent << "%\n";

    std::cout << "Numerical tensor test passed.\n";

  } catch (const std::exception &e) {
    std::cerr << "MiniRT error: " << e.what() << '\n';
    return 1;
  }

  return 0;
}

// Fixed graph:
// A = X * W
// B = A + R
// Y = B + S

// ..---- RESULT ----
/**
 * All arena tests passed!!!!!!!!
 Planner tests passed.
 A (2 x 2):
 19 22
 43 50
 B (2 x 2):
 20 23
 44 51
 Y (2 x 2):
 22 25
 46 53

 Memory plan:
 X -> slot 0 (live_from=0, last_use=1)
 W -> slot 1 (live_from=0, last_use=1)
 R -> slot 2 (live_from=0, last_use=2)
 S -> slot 3 (live_from=0, last_use=3)
 A -> slot 4 (live_from=1, last_use=2)
 B -> slot 0 (live_from=2, last_use=3)
 Y -> slot 1 (live_from=3, last_use=3)

 Naive tensor payload: 224 bytes
 Planned slot payload: 160 bytes
 Arena used: 160 / 160 bytes
 Payload reduction: 28.5714%
 Numerical tensor test passed.
 */
