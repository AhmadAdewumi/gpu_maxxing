
#include <cassert>
#include <cstddef>
#include <functional>
#include <iterator>
#include <vector>
template <typename Key, typename Value> class HashMap {
private:
  struct Node {
    Key key_;
    Value value_;
    Node *next_;

    Node(const Key &key, const Value &value, Node *next)
        : key_{key}, value_{value}, next_{next} {}
  };

  std::vector<Node *> buckets_;
  std::size_t count_{0};

  static constexpr double max_load_factor = 0.75;

  std::size_t bucket_index(const Key &key) const {
    //-- creates a temporary hash fnction object of type Key and calls it with
    // the key
    return std::hash<Key>{}(key) % buckets_.size();
  }

public:
  //-- we provide default capacity of 8
  explicit HashMap(std::size_t capacity = 8)
      : buckets_(capacity == 0 ? 8 : capacity, nullptr) {}

  //-- disablin copy constructor and copy assignment for now
  HashMap(const HashMap &other) = delete;
  HashMap &operator=(const HashMap &other) = delete;

  ~HashMap() { clear(); }

  void clear() noexcept {
    for (Node *&current : buckets_) {
      while (current != nullptr) {
        Node *old = current;
        current = current->next_;
        delete old;
      }
    }

    count_ = 0;
  }

  std::size_t size() const noexcept { return count_; }

  bool empty() const noexcept { return count_ == 0; }

  void insert(const Key &key, const Value &value) {
    std::size_t index = bucket_index(key);

    // if the key already exist in the bucket, we update
    for (Node *current = buckets_[index]; current != nullptr;
         current = current->next_) {
      if (current->key_ == key) {
        current->value_ = value;
        return;
      }
    }

    //-- we grow the bucket array if inserting would exceed 0.75
    const double insert_load_factor_change =
        static_cast<double>(count_ + 1) / static_cast<double>(buckets_.size());
    if (insert_load_factor_change > max_load_factor) {
      rehash(buckets_.size() * 2);

      // rehashing changes the bucket indices so we recalculate
      index = bucket_index(key);
    }

    //-- our insertion is at the head of the chain, so the next pointer of the
    // the new node points to that of the oldNode
    // at first, the bucket_[index] is nullptr, which makes the next pointer of
    // the first node point to the nullptr, but subsequent next points to that
    // of the old node
    buckets_[index] = new Node(key, value, buckets_[index]);
    ++count_;
  }

  //-- man, why tf will we need to modify through a fvckin find fnxtn, and the
  // standard implementation has that, well maybe not to peovide another update
  // function
  Value *find(const Key &key) {
    const std::size_t index = bucket_index(key);

    for (Node *current = buckets_[index]; current != nullptr;
         current = current->next_) {
      if (current->key_ == key) {
        return &current->value_;
      }
    }
    return nullptr;
  }

  const Value *find(const Key &key) const {
    const std::size_t index = bucket_index(key);

    for (const Node *current = buckets_[index]; current != nullptr;
         current = current->next_) {
      if (current->key_ == key) {
        return &current->value_;
      }
    }
    return nullptr;
  }

  bool erase(const Key &key) {
    const std::size_t index = bucket_index(key);

    Node *current = buckets_[index];
    Node *previous = nullptr;

    while (current != nullptr) {
      if (current->key_ == key) {
        // there are 2 cases, if the node is the head of the chain or if it is
        // not
        if (previous == nullptr) {
          // the node is head of the chain
          buckets_[index] = current->next_;
        } else {
          //-- we make the previous next pointer point to the node after current
          previous->next_ = current->next_;
        }

        delete current;
        --count_;
        return true;
      }

      previous = current;
      current = current->next_;
    }

    return false;
  }

  // load factor --> measures how full the bucket array is relative to the
  //  number of stored entries, say we have 12 entries and 8 buckets, load
  //  factor = 1.5, i.e there are more entries than buckets which means some
  //  chains are gonna contain multiple nodes
  double load_factor() const noexcept {
    return static_cast<double>(count_) / static_cast<double>(buckets_.size());
  }

  void rehash(std::size_t new_capacity) {
    if (new_capacity == 0) {
      new_capacity = 1;
    }

    std::vector<Node *> new_buckets(new_capacity, nullptr);

    for (Node *head : buckets_) {
      Node *current = head;

      while (current != nullptr) {
        //-- we store the next node so we know where to continue from
        Node *next = current->next_;

        const std::size_t new_index =
            std::hash<Key>{}(current->key_) % new_capacity;

        //-- make the current next pointer point to the node at the new location
        //(nullptr at first)
        current->next_ = new_buckets[new_index];
        //-- then, we place the node at the bucket
        new_buckets[new_index] = current;

        // then, our current = the next node we saved the other time
        current = next;
      }
    }

    //-- we swap the old bucket with the new bucket
    buckets_.swap(new_buckets);
  }
};

int main() {
  HashMap<std::string, int> map;

  map.insert("Ahmad", 50);
  map.insert("Ade", 70);
  map.insert("Segun", 90);
  map.insert("Ibraheem", 110);

  assert(map.size() == 4);
  assert(map.find("Ahmad") != nullptr);
  assert(*map.find("Ahmad") == 50);
  assert(*map.find("Ade") == 70);
  assert(map.find("missing") == nullptr);

  // update test
  map.insert("Ahmad", 100);
  assert(*map.find("Ahmad") == 100);
  assert(map.size() == 4);

  HashMap<int, int> collisions(2);

  collisions.insert(0, 100);
  collisions.insert(2, 200);
  collisions.insert(4, 400);

  // All three keys map to bucket 0: key % 2.
  assert(*collisions.find(0) == 100);
  assert(*collisions.find(2) == 200);
  assert(*collisions.find(4) == 400);
  assert(collisions.size() == 3);

  HashMap<int, int> growing(2);

  for (int i = 0; i < 20; ++i) {
    growing.insert(i, i * 10);
  }

  assert(growing.size() == 20);

  for (int i = 0; i < 20; ++i) {
    assert(growing.find(i) != nullptr);
    assert(*growing.find(i) == i * 10);
  }

  assert(growing.load_factor() <= 0.75);
}
