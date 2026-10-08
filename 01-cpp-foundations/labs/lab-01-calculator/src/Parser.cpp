#include "../include/Parser.hpp"
#include <algorithm>
#include <cmath>
#include <memory>
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

std::unique_ptr<Expr> Parser::parseFactor() {
  if (current_.type == TokenType::Number) {
    const double value = current_.value;
    advance();
    return std::make_unique<NumberExpr>(value);
  }

  if (current_.type == TokenType::LeftParen) {
    advance();
    std::unique_ptr<Expr> expression = parseExpression();
    expect(TokenType::RightParen);
    return expression;
  }

  throw std::runtime_error("Expected number or '(' ");
}

std::unique_ptr<Expr> Parser::parseTerm() {
  std::unique_ptr<Expr> left = parseFactor();

  while (current_.type == TokenType::Star ||
         current_.type == TokenType::Slash ||
         current_.type == TokenType::Percent) {
    const TokenType operation = current_.type;
    advance();
    std::unique_ptr<Expr> right = parseFactor();

    left = std::make_unique<BinaryExpr>(
        std::move(left), operation, std::move(right)
    );
  }

  return left;
}

std::unique_ptr<Expr> Parser::parseExpression() {
  std::unique_ptr<Expr> left = parseTerm();

  while (current_.type == TokenType::Plus ||
         current_.type == TokenType::Minus) {

    const TokenType operation = current_.type;
    advance();

    std::unique_ptr<Expr> right = parseTerm();

    left = std::make_unique<BinaryExpr>(std::move(left), operation,
                                        std::move(right));
  }

  return left;
}

std::unique_ptr<Expr> Parser::parse() {
  std::unique_ptr<Expr> expression = parseExpression();
  expect(TokenType::End);
  return expression;
}
