#pragma once

#include "Token.hpp"
#include <cstddef>
#include <string_view>

class Lexer {
private:
  std::string_view input_; //-- a view of the src text
  std::size_t position_{0}; //-- to keep track of the current position, it counts whitespace also

public:
  //-- using explicit to avoid implicit conversion(that may happen to
  // cnstructors with one arg)
  //-- so, we have to explicitly init the constructor when we need it
  explicit Lexer(std::string_view input);
  Token next();
  Token number();
};
