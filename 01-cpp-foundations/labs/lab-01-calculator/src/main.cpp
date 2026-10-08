#include "../include/Parser.hpp"
#include <cstddef>
#include <iostream>
#include <memory>
#include <string>
#include <string_view>

// void printAST(std::string_view input) {
//   std::cout << "Input: " << input << "\n";
//
//   try {
//     Parser parser{input};
//     std::unique_ptr<Expr> result = parser.parse();
//
//     std::cout << "Result: " << result << "\n";
//
//   } catch (const std::exception &e) {
//     std::cerr << "Error: " << e.what() << "\n";
//   }
//
//   std::cout << "------------------------" << '\n';
// }

void printAST(const Expr &expression, int depth = 0) {
  const std::string indent(static_cast<std::size_t>(depth) * 2, ' ');

  // if expression is a NumberExpr
  if (const auto *number = dynamic_cast<const NumberExpr *>(&expression)) {
    std::cout << indent << "NumberExpr: " << number->value() << "\n";
    return;
  }

  // if expression is a BinaryExpr
  if (const auto *binary = dynamic_cast<const BinaryExpr *>(&expression)) {
    std::cout << indent << "BinaryExpr(";

    switch (binary->operation()) {
    case TokenType::Plus:
      std::cout << "+";
      break;
    case TokenType::Minus:
      std::cout << "-";
      break;
    case TokenType::Star:
      std::cout << "*";
      break;
    case TokenType::Slash:
      std::cout << "/";
      break;
    case TokenType::Percent:
      std::cout << "%";
      break;
    default:
      std::cout << "?";
      break;
    }

    std::cout << ")\n";
    printAST(binary->left(), depth + 1);
    printAST(binary->right(), depth + 1);

    return;
  }

  std::cout << indent << "Unknown Expression \n";
}

void test(std::string_view input) {
  std::cout << "Input: " << input << '\n';

  try {
    Parser parser{input};
    std::unique_ptr<Expr> result = parser.parse();

    std::cout << "AST:\n";
    printAST(*result);
  } catch (const std::exception &e) {
    std::cout << "Error: " << e.what() << '\n';
  }

  std::cout << "------------------------\n";
}

int main() {
  // Valid inputs
  test("2 + 3");
  test("2 * 3");
  test("2 + 3 * 4");
  test("(2 + 3) * 4");
  test("2 * (3 + 4)");
  test("10 - 4 - 2");
  test("20 / 5 / 2");
  test("10 % 3");
  test("2 + 3 * 4 - 5");
  test("2 * (3 + 4) - 5");

  // Malformed inputs
  test("2 +");
  test("* 3");
  test("2 + * 3");
  test("(2 + 3");
  test("2 + 3)");
  test("()");
  test("2 / / 3");

  return 0;
}
