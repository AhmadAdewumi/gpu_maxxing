#pragma once

enum class TokenType {
  Number,
  Plus,
  Minus,
  Star,
  Slash,
  Percent,
  LeftParen,
  RightParen,
  End
};

struct Token {
  TokenType type;
  double value{};
};
