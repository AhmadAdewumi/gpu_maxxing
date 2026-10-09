#pragma once

#include <alloca.h>
#include <cstddef>
#include <memory>
#include <stdexcept>
#include <utility>

//-- refactoring to  solve the problem of tightly coupling memory
// management with the object lifecycle management
// we want to separate allocation from construction, because right now using
// new, it llocates and constructs the ibjecs at the same time, even when we
// don't need it yet and also it can cause heap fragmentnation whereby
// repeatedly releasing and freeing objects which  can scatter thier memory
// address and cause more cache misses. Allocator solves this problem.
template <typename T> class Vector {
private:
  using Allocator = std::allocator<T>;
  using Traits = std::allocator_traits<Allocator>;

  Allocator allocator_;
  T *data_ = nullptr;
  std::size_t size_ = 0;
  std::size_t capacity_ = 0;

  //   void grow() {
  //     const std::size_t new_capacity = capacity_ == 0 ? 2 : capacity_ * 2;
  //     T *new_container = new T[new_capacity];
  //
  //     for (std::size_t i = 0; i < size_; ++i) {
  //       new_container[i] = data_[i];
  //     }
  //
  //     delete[] data_;
  //
  //     data_ = new_container;
  //     capacity_ = new_capacity;
  //   }

public:
  Vector() = default;

  ~Vector() { release(); }

  // // copy constructor
  // Vector(const Vector &other)
  //     : data_{other.capacity_ == 0 ? nullptr : new T[other.capacity_]},
  //       size_{other.size_}, capacity_{other.capacity_} {
  //   for (std::size_t i{0}; i < size_; ++i) {
  //     data_[i] = other.data_[i];
  //   }
  // }

  //-- new copy constructor :: to make an independent copy
  Vector(const Vector &other) : capacity_(other.capacity_) {
    if (capacity_ == 0)
      return;

    data_ = Traits::allocate(allocator_, capacity_);

    try {
      for (; size_ < other.size_; ++size_) {
        Traits::construct(allocator_, data_ + size_, other.data_[size_]);
      }
    } catch (...) {
      release();
      throw;
    }
  }

  // copy assignment
  Vector &operator=(const Vector &other) {
    // detect self initializtion
    if (this == &other) {
      return *this;
    }

    // create a new destination array
    // T *new_container = other.capacity_ == 0 ? nullptr : new
    // T[other.capacity_];

    Vector temporary{other};
    swap(temporary);
    return *this;
  }

  //-- move constructor --> takes a non const r-value
  // noexcept --> to guarantee it won't hrow
  Vector(Vector &&other) noexcept
      : data_{std::exchange(other.data_, nullptr)},
        size_{std::exchange(other.size_, 0)},
        capacity_{std::exchange(other.capacity_, 0)} {}

  // move assignment
  Vector &operator=(Vector &&other) noexcept {
    if (this == &other) {
      return *this;
    }

    release();
    // delete[] data_;

    data_ = std::exchange(other.data_, nullptr);
    size_ = std::exchange(other.size_, 0);
    capacity_ = std::exchange(other.capacity_, 0);

    return *this;
  }

  std::size_t size() const { return size_; }

  std::size_t capacity() const { return capacity_; }

  // pre allocates memory for the container without changeing size(number of
  // elements)
  void reserve(std::size_t new_capacity) {
    if (new_capacity <= capacity_) {
      return;
    }

    if (new_capacity > Traits::max_size(allocator_)) {
      throw std::length_error("Vector capacity is too large");
    }

    T *new_data = Traits::allocate(allocator_, new_capacity);
    std::size_t constructed = 0;

    try {
      //-- we already init constructed
      for (; constructed < size_; ++constructed) {
        Traits::construct(allocator_, new_data + constructed,
                          std::move_if_noexcept(data_[constructed]));
      }
    } catch (...) {
      while (constructed > 0) {
        --constructed;
        Traits::destroy(allocator_, new_data + constructed);
      }
      Traits::deallocate(allocator_, new_data, new_capacity);
      throw;
    }

    // since the new elements exist now, we can now let go of the old one
    for (std::size_t i = size_; i > 0; --i) {
      Traits::destroy(allocator_, data_ + (i - 1));
    }

    if (data_ != nullptr) {
      Traits::deallocate(allocator_, data_, capacity_);
    }
    data_ = new_data;
    capacity_ = new_capacity;
  }

  T &operator[](std::size_t index) {
    if (index >= size_) {
      throw std::out_of_range("index out of range");
    }
    return data_[index];
  }

  const T &operator[](std::size_t index) const {
    if (index >= size_) {
      throw std::out_of_range("index out of range");
    }
    return data_[index];
  }

  void push_back(const T &value) {
    if (size_ == capacity_) {
      T saved{value};

      const std::size_t max_capacity = capacity_ == 0 ? 2 : capacity_ * 2;

      if (capacity_ >= max_capacity) {
        throw std::length_error("Vector capacity exceeded");
      }

      const std::size_t new_capacity =
          capacity_ == 0
              ? (max_capacity < 2 ? max_capacity : 2)
              : (capacity_ > max_capacity / 2 ? max_capacity : capacity_ * 2);
      
      reserve(new_capacity);
      Traits::construct(allocator_, data_ + size_,
                        std::move_if_noexcept(saved));
    } else {
      Traits::construct(allocator_, data_ + size_, value);
    }

    ++size_;
  }

  void swap(Vector &other) noexcept {
    //-- this is advised, technique known as Argument Dependent Lookup swap
    // idiom
    // best practice when dealing with generic templates
    using std::swap;

    swap(data_, other.data_);
    swap(capacity_, other.capacity_);
    swap(size_, other.size_);
  }

  void clear() noexcept {
    for (std::size_t i = size_; i > 0; --i) {
      Traits::destroy(allocator_, data_ + (i - 1));
    }

    size_ = 0;
  }

private:
  void release() noexcept {
    clear();

    if (data_ != nullptr) {
      Traits::deallocate(allocator_, data_, capacity_);
      data_ = nullptr;
    }

    capacity_ = 0;
  }
};
