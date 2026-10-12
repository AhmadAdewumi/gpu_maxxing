#include "utility"
#include <cassert>
#include <cstddef>
#include <cstring>
#include <iostream>

class String {
private:
  static constexpr std::size_t SSO_CAPACITY = 15;

  // large and small share the same storage space, only one can hold the storage
  // at a time
  //  small contains an array fo the 16 chars
  //  and then the large will have a pointer to the string on the heap,
  //  when the string is greater than 16 characters
  union Storage {
    //-- if the sting is short, it is stored inside the string object itself
    // else, it is stored on the heap
    char small[SSO_CAPACITY + 1]; // +1 coz of the null terminating char '\0'
    char *large;

    Storage(){};
    ~Storage(){};
  };

  Storage storage_;
  std::size_t size_{0};
  std::size_t capacity_{SSO_CAPACITY};

  // is small and data
  bool is_small() const noexcept { return capacity_ == SSO_CAPACITY; }

  // this answers the question, where are the string stored right now, coz we
  // have 2 locations, in the string object if small and on the heap if large
  //
  // mutable--> we can use it to modify the characters
  char *data() noexcept { return is_small() ? storage_.small : storage_.large; }

  //-- immutable
  const char *data() const noexcept {
    return is_small() ? storage_.small : storage_.large;
  }

  // this guarantees we have sufficient capacity for the requested number of
  // characters and allocate anew one if necessary
  void ensure_capacity(std::size_t required) {
    if (required <= capacity_) {
      return;
    }

    const std::size_t new_capacity =
        capacity_ * 2 > required ? capacity_ * 2 : required;

    char *new_data = new char[new_capacity + 1];

    std::memcpy(new_data, data(), size_ + 1);

    // if the string uses a heap before, then we must free the memory
    if (!is_small()) {
      delete[] storage_.large;
    }

    // we switch to the new heap allocation
    storage_.large = new_data;
    capacity_ = new_capacity;
  }

public:
  String() { // default constructor
    storage_.small[0] = '\0';
  }

  //-- delegating constructor, calls the default constructor first
  explicit String(const char *text) : String() {
    if (text == nullptr) {
      return;
    }

    std::size_t length = std::strlen(text);

    const std::size_t length_plus_one = length + 1;
    if (length <= SSO_CAPACITY) {
      std::memcpy(storage_.small, text, length_plus_one);
    } else {
      char *new_data = new char[length_plus_one];
      std::memcpy(new_data, text, length_plus_one);

      storage_.large = new_data;
      capacity_ = length;
    }

    size_ = length;
  }

  ~String() {
    if (!is_small()) {
      delete[] storage_.large;
    }
  }

  // copy constructor --> deep copy
  // still delegates to the default constructor
  String(const String &other) : String() {
    if (other.is_small()) {
      // copying only the meaningful part, or should i just copy all
      std::memcpy(storage_.small, other.storage_.small, other.size_ + 1);
    } else {
      char *new_data = new char[other.capacity_ + 1];

      std::memcpy(new_data, other.storage_.large, other.size_ + 1);

      storage_.large = new_data;
      capacity_ = other.capacity_;
    }

    size_ = other.size_;
  }

  // move constructor
  String(String &&other) noexcept : String() {
    if (other.is_small()) {
      //-- here we are copying all
      std::memcpy(storage_.small, other.storage_.small, SSO_CAPACITY + 1);
    } else {
      storage_.large = other.storage_.large;
      capacity_ = other.capacity_;
    }

    size_ = other.size_;

    other.storage_.small[0] = '\0';
    other.capacity_ = SSO_CAPACITY;
    other.size_ = 0;
  }

  // copy assignmenr
  String &operator=(const String &other) {
    if (this != &other) {
      String temporary(other);      // initializes the copy constructor
      *this = std::move(temporary); // using move to replace the destination
                                    // existing content with that of temporary
    }

    return *this;
  }

  String &operator=(String &&other) {
    if (this == &other) {
      return *this;
    }

    // if not a small string, free the storage of the current string first
    // overwriteing the pointer could cause memory leakage as it could lose
    // reference to the old allocation
    if (!is_small()) {
      delete[] storage_.large;
    }

    if (other.is_small()) {
      std::memcpy(storage_.small, other.storage_.small, SSO_CAPACITY + 1);
    } else {
      storage_.large = other.storage_.large;
      capacity_ = other.capacity_;
    }

    size_ = other.size_;

    other.storage_.small[0] = '\0';
    other.size_ = 0;
    other.capacity_ = SSO_CAPACITY;

    // reset capacity if tis destination conain a short string i.e. <= 15 chars
    if (size_ <= SSO_CAPACITY) {
      capacity_ = SSO_CAPACITY;
    }

    return *this;
  }

  void append(const String &other) {
    const bool is_self_append = this == &other;
    const std::size_t suffix_size = other.size_;

    // if the other string is empty, nothing to do
    if (other.size_ == 0) {
      return;
    }

    // we call our ensure_capacity() function to allocate more if needed
    ensure_capacity(size_ + suffix_size);

    // to get the source, if we are appending to itself, we use the object's
    // data, else we use other.data()
    // normally, this should be const also, as we do not want to modify, whar we
    // want to perform move operation on, but still, the reason there must be a
    // const here is that, the other reference we are passing in is const, so
    // the second overloaded function which suports const will be the one
    // selected, so automatically the source pointer fatz be const also
    const char *source = is_self_append ? data() : other.data();

    // whys use memmove and not memcpy here, it is because our source and
    // destination memory may overlap such as when we are self appending, memcpy
    // may cause undefined behaviour which may lead to data corruption, but
    // std::memmove avoids this by copying the data as if it uses an
    // intermediate buffer
    //
    // -- data() --:> pointer to the beginning of the destination buffer
    // -- data()+size_ --> pointer to the position where the new characters
    // should begin, e.g
    // -- for "Hello" + "World", we wil have data() + size_ point to index 5
    // source --> pointer to the characters being appended
    // suffix_size --:> number of bytes to copy
    std::memmove(data() + size_, source, suffix_size);

    size_ += suffix_size;
    data()[size_] = '\0'; // putting the null terminator at the end
  }

  const char *c_style_string() const noexcept { return data(); }

  // these guys don't need const as they are returned by value, that is they
  // receive thier own copy, so changing the local value doesn't affect the
  // objec's own
  std::size_t size() const noexcept { return size_; }

  std::size_t capacity() const noexcept { return capacity_; }

  bool uses_sso() const noexcept { return is_small(); }
};

int main() {
  String empty;

  assert(empty.size() == 0);
  assert(empty.uses_sso());

  String short_text{"Ahmad"};
  assert(short_text.size() == 5);
  assert(short_text.uses_sso());

  // Exactly 15 characters: still fits inline.
  String boundary_check("123456789012345");
  assert(boundary_check.uses_sso());

  // 16 characters: requires heap storage.
  String longer("1234567890123456");
  assert(!longer.uses_sso());
  assert(longer.size() == 16);

  String copied{short_text};
  assert(copied.uses_sso());
  assert(std::strcmp(copied.c_style_string(), "Ahmad") == 0);

  // copying a long string, its allocation must be different
  String long_copy{longer};
  assert(!long_copy.uses_sso());
  assert(std::strcmp(long_copy.c_style_string(), longer.c_style_string()) == 0);

  // appending
  String text{"Ahmad now writes program using: "};
  std::size_t initial_text_size = text.size();

  String suffix{"C++"};
  text.append(suffix);
  assert(!text.uses_sso());
  assert(text.size() == initial_text_size + suffix.size());
  assert(std::strcmp(text.c_style_string(),
                     "Ahmad now writes program using: C++") == 0);

  // self append
  String suffix_self{"C++"};
  suffix_self.append(suffix_self);
  assert(std::strcmp(suffix_self.c_style_string(), "C++C++") == 0);

  // Copy assignment.
  String assigned;
  assigned = longer;
  assert(std::strcmp(assigned.c_style_string(), longer.c_style_string()) == 0);

  // Move a long string.
  String moved(std::move(longer));
  assert(moved.size() == 16);
  assert(longer.size() == 0);
  assert(longer.uses_sso());

  // Move assignment.
  String move_assigned;
  move_assigned = std::move(moved);
  assert(move_assigned.size() == 16);
  assert(moved.size() == 0);

  std::cout << "All SSO tests passed.\n";
  std::cout << "sizeof(String): " << sizeof(String) << '\n';
  std::cout << "alignof(String): " << alignof(String) << '\n';
  std::cout << "Short string uses SSO: " << std::boolalpha
            << short_text.uses_sso() << '\n';
  std::cout << "Long string uses SSO: " << longer.uses_sso() << '\n';
}
