
#include <cstddef>
#include <ios>
#include <iostream>

template <typename T> class SinglyLinkedList {
private:
  struct Node {
    T data;
    Node *next;

    explicit Node(const T &value) : data{value}, next{nullptr} {}
  };

  Node *head{nullptr};
  Node *tail{nullptr};
  std::size_t count{0};

  // cleanup helper
  void clear() noexcept {
    while (head != nullptr) {
      Node *oldHead = head;
      head = head->next;
      delete oldHead;
    }
    tail = nullptr;
    count = 0;
  }

  /**
   * The rule of five states that:
   * when a class manually manages resources, we must control how the resource
   * is created, copied, transferred and destroyed, i.e. we need to handle the:
   * 1. destructor 2. copy constructor 3.copy assignment operator 4. move
   * constructor and
   * 5. move assignment operator
   */
public:
  SinglyLinkedList() = default;

  //-- destructor to clean up memory, else i keep getting this error
  // ERROR: LeakSanitizer: detected memory leaks
  // SUMMARY: AddressSanitizer: 16 byte(s) leaked in 1 allocation(s).
  ~SinglyLinkedList() { clear(); }

  // copy constructor (construct and initializes a brand new SLL object)
  SinglyLinkedList(const SinglyLinkedList &other) {
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
  SinglyLinkedList operator=(const SinglyLinkedList &other) {
    if (this != &other) {
      SinglyLinkedList temporary{
          other}; // after swapping and going out of scop, its destructor runs
      swap(temporary);
    }
    return *this;
  }

  void swap(SinglyLinkedList &other) {
    using std::swap;

    swap(head, other.head);
    swap(tail, other.tail);
    swap(count, other.count);
  }

  // -- move constructor (creating a new object by stealing froma temporary
  // {rvalue})
  SinglyLinkedList(SinglyLinkedList &&other) noexcept
      : head{other.head}, tail{other.tail}, count{other.count} {
    other.head = nullptr;
    other.tail = nullptr;
    other.count = 0;
  }

  // --  move assignment
  SinglyLinkedList operator=(SinglyLinkedList &&other) noexcept {
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

  // diable copy for now because copying naively could lead to nly copying the
  // head pointer and leave out the remaining nodes
  // SinglyLinkedList(const SinglyLinkedList &) = delete;
  // SinglyLinkedList &operator=(const SinglyLinkedList &) = delete;

  void push_front(const T &value) {
    Node *newNode = new Node(value);
    newNode->next = head;
    head = newNode;

    if (tail == nullptr) {
      tail = newNode;
    }
    ++count;
  }

  void push_back(const T &value) {
    Node *newNode = new Node(value);
    if (tail == nullptr) {
      head = newNode;
      tail = newNode;
    } else {
      tail->next = newNode;
      tail = newNode;
    }

    ++count;
  }

  bool pop_front() {
    if (head == nullptr) {
      return false;
    }

    Node *oldHead = head;
    head = head->next;

    //-- coz both pointers must represent an empty list, else i get the error
    // ERROR: AddressSanitizer: heap-use-after-free on address
    if (head == nullptr) {
      tail = nullptr;
    }

    delete oldHead;
    --count;
    return true;
  }

  //-- no_discard tells the compiler to issue a warning in case the function's
  // return value is ignored
  [[nodiscard]] std::size_t size() const { return count; }

  [[nodiscard]] bool empty() const { return head == nullptr; }

  void print() const {
    Node *current = head;

    while (current != nullptr) {
      std::cout << current->data << " -> ";
      current = current->next;
    }
    std::cout << "nullptr\n";
  }
};


int main() {
    SinglyLinkedList<int> a;
    a.push_back(10);
    a.push_back(20);
    a.push_back(30);

    // Copy construction
    SinglyLinkedList<int> b = a;
    b.push_back(40);

    std::cout << "Original: ";
    a.print();

    std::cout << "Copy: ";
    b.print();

    // Copy assignment over an existing list
    SinglyLinkedList<int> c;
    c.push_back(999);
    c = a;

    std::cout << "Copy-assigned: ";
    c.print();

    // Move construction
    SinglyLinkedList<int> d = std::move(a);

    std::cout << "Moved-to: ";
    d.print();

    std::cout << "Moved-from: a, is empty: "
              << std::boolalpha << a.empty() << '\n';

    // Move assignment over an existing list
    c = std::move(b);

    std::cout << "Move-assigned: ";
    c.print();

    std::cout << "Moved-from: b, is empty: "
              << b.empty() << '\n';

    // Self-assignment checks
    c = c;
    c = std::move(c);

    std::cout << "After self-assignment: ";
    c.print();

    return 0;
}

