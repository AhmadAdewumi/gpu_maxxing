
#include <cstddef>
#include <iostream>
#include <utility>
template <typename T> class DoublyLinkedList {
  struct Node {
    T data;
    Node *prev;
    Node *next;

    explicit Node(const T value) : data{value}, prev{nullptr}, next{nullptr} {}
  };

  Node *head{nullptr};
  Node *tail{nullptr};
  std::size_t count{0};

  void clear() {
    while (head != nullptr) {
      Node *oldHead = head;
      head = head->next;
      delete oldHead;
    }
    tail = nullptr;
    count = 0;
  }

public:
  DoublyLinkedList() = default;

  //-- destructor to clean up memory, else i keep getting this error
  // ERROR: LeakSanitizer: detected memory leaks
  // SUMMARY: AddressSanitizer: 16 byte(s) leaked in 1 allocation(s).
  ~DoublyLinkedList() { clear(); }

  // copy constructor (construct and initializes a brand new SLL object)
  DoublyLinkedList(const DoublyLinkedList &other) {
    try {
      for (Node *current = other.head; current != nullptr;
           current = current->next) {
        push_back(current->data);
      }
    } catch (...) {
      clear();
      throw;
    }
  }

  // copy assignment operator (copies data into an object that has aready been
  // created)
  // we can't just do this head = other.head;, coz that will be shallow copy as
  // the 2 lists will both point to the same nodes
  DoublyLinkedList operator=(const DoublyLinkedList &other) {
    if (this != &other) {
      DoublyLinkedList temporary{
          other}; // after swapping and going out of scop, its destructor runs
      swap(temporary);
    }
    return *this;
  }

  void swap(DoublyLinkedList &other) noexcept {
    using std::swap;

    swap(head, other.head);
    swap(tail, other.tail);
    swap(count, other.count);
  }

  // -- move constructor (creating a new object by stealing froma temporary
  // {rvalue})
  DoublyLinkedList(DoublyLinkedList &&other) noexcept
      : head{other.head}, tail{other.tail}, count{other.count} {
    other.head = nullptr;
    other.tail = nullptr;
    other.count = 0;
  }

  // --  move assignment
  DoublyLinkedList operator=(DoublyLinkedList &&other) noexcept {
    if (this != &other) {
      clear(); // we clear the data of the current node (freeing the node)

      head = other.head;
      tail = other.tail;
      count = other.count;

      other.head = nullptr;
      other.tail = nullptr;
      other.count = 0;
    }

    return *this;
  }

  void push_front(const T &value) {
    Node *newNode = new Node(value);
    newNode->next = head;

    if (head != nullptr) {
      head->prev = newNode;
    } else {
      tail = newNode;
    }

    head = newNode;
    ++count;
  }

  void push_back(const T &value) {
    Node *newNode = new Node(value);

    newNode->prev =
        tail; // if the list is even empty, it is going to point to nullptr

    if (tail != nullptr) {
      tail->next = newNode;
    } else {
      head = newNode;
    }

    tail = newNode;
    ++count;
  }

  bool pop_front() {
    if (head == nullptr) {
      return false;
    }

    Node *oldHead = head;
    head = head->next;

    if (head != nullptr) {
      head->prev = nullptr;
    } else {
      tail = nullptr;
    }

    delete oldHead;
    --count;
    return true;
  }

  bool pop_back() {
    if (tail == nullptr) {
      return false;
    }

    Node *oldTail = tail;
    tail = tail->prev;

    if (tail != nullptr) {
      tail->next = nullptr;
    } else {
      head = nullptr;
    }

    delete oldTail;
    --count;
    return true;
  }

  [[nodiscard]] std::size_t size() const { return count; }

  [[nodiscard]] bool empty() const { return head == nullptr; }

  void print_forward() const {
    for (Node *current = head; current != nullptr; current = current->next) {
      std::cout << current->data << " <-> ";
    }

    std::cout << "nullptr\n";
  }

  void print_backward() const {
    for (Node *current = tail; current != nullptr; current = current->prev) {
      std::cout << current->data << " <-> ";
    }
    std::cout << "nullptr\n";
  }
};

int main() {
  DoublyLinkedList<int> list;

  list.push_back(20);
  list.push_front(10);
  list.push_back(30);
  list.push_front(5);

  std::cout << "Forward:  ";
  list.print_forward();

  std::cout << "Backward: ";
  list.print_backward();

  list.pop_front();
  list.pop_back();

  std::cout << "After removing both ends:\n";
  list.print_forward();

  DoublyLinkedList<int> copy = list;
  copy.push_back(99);

  std::cout << "Original: ";
  list.print_forward();

  std::cout << "Copy:     ";
  copy.print_forward();

  DoublyLinkedList<int> moved = std::move(copy);
  std::cout << "Moved-from copy empty: " << std::boolalpha << copy.empty()
            << '\n';

  return 0;
}
