#include "../include/Vector.hpp"
#include <cassert>

int main() {
  Vector<int> first;
  first.push_back(10);
  first.push_back(20);

  Vector<int> second = first; // copy construction
  assert(second.size() == 2);
  assert(second[1] == 20);

  // test if modifying second doesn't affect the ifrst
  second[0] = 2;
  assert(first[0] == 10);

  // for asignment, he object exists already
  Vector<int> third;
  third = first; // Copy assignment
  assert(third[1] == 20);

  Vector<int> fourth = std::move(first); // move construction
  assert(fourth.size() == 2);
  assert(fourth[1] == 20);

  Vector<int> fifth;
  fifth.push_back(50);
  fifth = std::move(fourth);
  assert(fifth[0] == 10);
  assert(fourth.size() == 0);

  return 0;
}
