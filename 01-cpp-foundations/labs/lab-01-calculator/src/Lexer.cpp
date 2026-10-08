#include "../include/Lexer.hpp"
#include <cctype>
#include <cstddef>
#include <cstdio>
#include <iostream>
#include <stdexcept>
#include <string>
#include <string_view>

Lexer::Lexer(std::string_view input) : input_(input) {}

Token Lexer::next() {
  // increment pos if it is whitespace
  //  check if we haven't reach end
  //  get the current character
  //  if not number, map to the correct token type
  //  consume number sthat are curretnlyn int he being read literal as chunk
  //  map to the number tokenType

  while (position_ < input_.size() &&
         std::isspace(static_cast<unsigned char>(input_[position_]))) {
    ++position_;
  }

  if (position_ >= input_.size()) {
    return Token{TokenType::End};
  }

  char current = input_[position_];

  switch (current) {
  case '+':
    ++position_;
    return Token{TokenType::Plus};
  case '-':
    ++position_;
    return Token{TokenType::Minus};
  case '*':
    ++position_;
    return Token{TokenType::Star};
  case '/':
    ++position_;
    return Token{TokenType::Slash};
  case '%':
    ++position_;
    return Token{TokenType::Percent};
  case '(':
    ++position_;
    return Token{TokenType::LeftParen};
  case ')':
    ++position_;
    return Token{TokenType::RightParen};
  default:
    break;
  }

  if (std::isdigit(static_cast<unsigned char>(current))) {
    return number();
  }

  throw std::runtime_error("Unexpected character");
}

Token Lexer::number() {
  std::size_t startPos = position_;

  while (position_ < input_.size() &&
         std::isdigit(static_cast<unsigned char>(input_[position_]))) {
    ++position_;
  }

  // if the number is a decimal one
  if (position_ < input_.size() && input_[position_] == '.') {
    ++position_;

    while (position_ < input_.size() &&
           std::isdigit(static_cast<unsigned char>(input_[position_]))) {
      ++position_;
    }
  }

  //-- stod --> string to double and it requires std::string not
  // std::string_view
  double value =
      std::stod(std::string{input_.substr(startPos, position_ - startPos)});

  return Token{TokenType::Number, value};
}
