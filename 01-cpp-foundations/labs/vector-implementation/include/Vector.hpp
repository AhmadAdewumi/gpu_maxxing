#pragma once

#include <cstddef>
#include <iterator>
#include <stdexcept>
#include <utility>


template <typename T> class Vector {
private:
  T *data_ = nullptr;
  std::size_t size_ = 0;
  std::size_t capacity_ = 0;

  void grow() {
    const std::size_t new_capacity = capacity_ == 0 ? 2 : capacity_ * 2;
    T *new_container = new T[new_capacity];

    for (std::size_t i = 0; i < size_; ++i) {
      new_container[i] = data_[i];
    }

    delete[] data_;

    data_ = new_container;
    capacity_ = new_capacity;
  }

public:
  Vector() = default;

  ~Vector() { delete[] data_; }

  // copy constructor
  Vector(const Vector &other)
      : data_{other.capacity_ == 0 ? nullptr : new T[other.capacity_]},
        size_{other.size_}, capacity_{other.capacity_} {
            for (std::size_t i{0}; i < size_; ++i) {
                data_[i] = other.data_[i];            
            }
        }

  // copy assignment
  Vector &operator=(const Vector &other) {
    // detect self initializtion
    if (this == &other) {
      return *this;
    }

    // create a new destination array
    T *new_container = other.capacity_ == 0 ? nullptr : new T[other.capacity_];

    try {
      for (std::size_t i{0}; i < other.size_; ++i) {
        new_container[i] = other.data_[i];
      }

    } catch (...) {
      delete[] new_container;
      throw;
    }

    delete[] data_;

    data_ = new_container;
    size_ = other.size_;
    capacity_ = other.capacity_;

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

    delete[] data_;

    data_ = std::exchange(other.data_, nullptr);
    size_ = std::exchange(other.size_, 0);
    capacity_ = std::exchange(other.capacity_, 0);

    return *this;
  }

  std::size_t size() const { return size_; }

  std::size_t capacity() const { return capacity_; }

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
      grow();
    }
    data_[size_] = value;
    ++size_;
  }
};
