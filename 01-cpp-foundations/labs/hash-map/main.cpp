
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
  HashMap operator=(const HashMap &other) = delete;

  ~HashMap() { clear(); }

  void clear() noexcept {
    for (Node *current : buckets_) {
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
    const std::size_t index = bucket_index(key);

    // if the key already exist in the bucket, we update
    for (Node *current = buckets_[index]; current != nullptr;
         current = current->next_) {
      if (current->key_ == key) {
        current->value_ = value;
        return;
      }
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

    for (Node *current = buckets_[index]; current != nullptr;
         current = current->next_) {
      if (current->key_ == key) {
        return &current->value_;
      }
    }
    return nullptr;
  }
};


int main(){
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
}