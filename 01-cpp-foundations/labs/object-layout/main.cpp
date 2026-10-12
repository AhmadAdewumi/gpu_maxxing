

#include <cstddef>
#include <iomanip>
#include <ios>
#include <iostream>
#include <ratio>
struct Example1 {
  char a;
  int b;
};

struct Example2 {
  int a;
  char b;
};

struct A {
  char a;
  int b;
  char c;
};

struct B {
  int b;
  char a;
  char c;
};

template <typename T> void print_layout(const char *name) {
  std::cout << "\n"
            << "name" << "\n";
  std::cout << "sizeof: " << sizeof(T) << "\n";
  std::cout << "alignof: " << alignof(T) << "\n";
}

template <typename T> void print_bytes(const char *name, const T &object) {
  const auto *bytes = reinterpret_cast<const unsigned char *>(&object);

  std::cout << name << " bytes ";

  for (std::size_t i{0}; i < sizeof(T); ++i) {
    std::cout << std::hex << std::setw(2) << std::setfill('0')
              << static_cast<unsigned int>(bytes[i]) << ' ';
  }

  std::cout << std::dec << "\n";
}

int main() {
    print_layout<Example1>("Example");
    std::cout << "a offset = " << offsetof(Example1, a) << '\n';
    std::cout << "b offset = " << offsetof(Example1, b) << '\n';

    print_layout<Example2>("Example2");
    std::cout << "a offset = " << offsetof(Example2, a) << '\n';
    std::cout << "b offset = " << offsetof(Example2, b) << '\n';

    print_layout<A>("A");
    std::cout << "a offset = " << offsetof(A, a) << '\n';
    std::cout << "b offset = " << offsetof(A, b) << '\n';
    std::cout << "c offset = " << offsetof(A, c) << '\n';

    print_layout<B>("B");
    std::cout << "b offset = " << offsetof(B, b) << '\n';
    std::cout << "a offset = " << offsetof(B, a) << '\n';
    std::cout << "c offset = " << offsetof(B, c) << '\n';

    Example1 object{'X', 0x12345678};
    print_bytes("Example", object);
}