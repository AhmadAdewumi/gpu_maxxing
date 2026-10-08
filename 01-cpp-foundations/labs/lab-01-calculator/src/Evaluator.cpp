#include "../include/Evaluator.hpp"
#include <cmath>
#include <stdexcept>

double evaluate(const Expr &expression) {
  if (const auto *number = dynamic_cast<const NumberExpr *>(&expression)) {
    return number->value();
  }

  if (const auto *binary = dynamic_cast<const BinaryExpr *>(&expression)) {

    const double left = evaluate(binary->left());
    const double right = evaluate(binary->right());

    switch (binary->operation()) {
    case TokenType::Plus:
      return left + right;
    case TokenType::Minus:
      return left - right;

    case TokenType::Star:
      return left * right;

    case TokenType::Slash:
      if (right == 0.0) {
        throw std::runtime_error("Division by zero");
      }
      return left / right;

    case TokenType::Percent:
      if (right == 0.0) {
        throw std::runtime_error("Modulo by zero");
      }
      return std::fmod(left, right);
    default:
      throw std::runtime_error("Uknown binary operator");
    }
  }

  throw std::runtime_error("Unknown expression type");
}
