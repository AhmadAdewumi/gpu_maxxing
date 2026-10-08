#include <iostream>
#include <unistd.h>

int global = 42;
int global_uninitialized;

void foo() {
  int x = 23;
  std::cout << "Foo Local: " << &x << "\n";
}

int main() {
  int local = 10;

  int *heap = new int{20};

  std::cout << "PID: " << getpid() << "\n";
  std::cout << "Global: " << &global << "\n";
  std::cout << "Global uninitalized: " << &global_uninitialized << "\n";
  std::cout << "Local: " << &local << "\n";
  std::cout << "Heap: " << heap << "\n";
  std::cout << "Foo: " << reinterpret_cast<int *>(&foo) << "\n";

  std::cout << "Press Enter..\n";
  std::cin.get();

  delete heap;
}
