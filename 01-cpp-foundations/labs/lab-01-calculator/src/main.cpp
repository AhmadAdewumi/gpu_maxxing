#include "../include/Parser.hpp"
#include <iostream>

void test(std::string_view input) {
  std::cout << "Input: " << input << "\n";

  try {
    Parser parser{input};
    double result = parser.parse();

    std::cout << "Result: " << result << "\n";

  } catch (const std::exception &e) {
    std::cerr << "Error: " << e.what() << "\n";
  }

  std::cout << "------------------------" << '\n';
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
