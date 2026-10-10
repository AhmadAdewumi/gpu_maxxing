
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

public:
  SinglyLinkedList() = default;

  //-- destructor to clean up memory, else i keep getting this error
  // ERROR: LeakSanitizer: detected memory leaks
  // SUMMARY: AddressSanitizer: 16 byte(s) leaked in 1 allocation(s).
  ~SinglyLinkedList(){
      while (head != nullptr) {
          Node* oldHead = head;
          head = head->next;
          delete oldHead;
      }

      tail = nullptr;
      count = 0;
  }

  // diable copy for now because copying naively could lead to nly copying the
  // head pointer and leave out the remaining nodes
  SinglyLinkedList(const SinglyLinkedList &) = delete;
  SinglyLinkedList &operator=(const SinglyLinkedList &) = delete;

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

  //-- no_discard tells the compiler to issue a warning in casea function's
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
    SinglyLinkedList<int> list;

    // Empty list
    std::cout << std::boolalpha;
    std::cout << "Initially empty: " << list.empty() << '\n';

    // Append to an empty list, then prepend
    list.push_back(10);
    list.push_front(5);
    list.push_back(20);
    list.print(); // 5 -> 10 -> 20 -> nullptr

    // Remove everything, including the final node
    while (list.pop_front()) {}

    std::cout << "Empty after removals: "
              << list.empty() << '\n';
    std::cout << "Size: " << list.size() << '\n';

    // Reuse the list after it becomes empty
    list.push_back(99);
    list.print(); // 99 -> nullptr

    return 0;
}
