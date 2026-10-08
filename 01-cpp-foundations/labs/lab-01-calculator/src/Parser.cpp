#include "../include/Parser.hpp"
#include <cmath>
#include <stdexcept>
#include <string_view>

Parser::Parser(std::string_view input)
    : lexer_{input}, current_(lexer_.next()) {}

void Parser::advance() { current_ = lexer_.next(); }

void Parser::expect(TokenType tokenType) {
  if (current_.type != tokenType) {
    throw std::runtime_error("Unexpected Token");
  }

  advance();
}

double Parser::parseFactor() {
  if (current_.type == TokenType::Number) {
    double value = current_.value;
    advance();
    return value;
  }

  if (current_.type == TokenType::LeftParen) {
    advance();
    double value = parseExpression();
    expect(TokenType::RightParen);
    return value;
  }

  throw std::runtime_error("Expected number or '(' ");
}

double Parser::parseTerm() {
  double left = parseFactor();

  while (current_.type == TokenType::Star ||
         current_.type == TokenType::Slash ||
         current_.type == TokenType::Percent) {
    TokenType operation = current_.type;
    advance();
    double right = parseFactor();

    switch (operation) {
    case TokenType::Star:
      left *= right;
      break;
    case TokenType::Slash:
      left /= right;
      break;
    case TokenType::Percent:
      left = std::fmod(left, right);
      break;
    default:
      break;
    }
  }

  return left;
}

double Parser::parseExpression() {
  double left = parseTerm();

  while (current_.type == TokenType::Plus ||
         current_.type == TokenType::Minus) {
    TokenType operation = current_.type;
    advance();
    double right = parseTerm();

    switch (operation) {
    case TokenType::Plus:
      left += right;
      break;
    case TokenType::Minus:
      left -= right;
      break;
    default:
      break;
    }
  }

  return left;
}

double Parser::parse() {
  double result = parseExpression();
  expect(TokenType::End);
  return result;
}
