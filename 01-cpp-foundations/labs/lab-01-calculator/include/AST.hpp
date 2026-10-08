#pragma once

#include "Token.hpp"
#include <algorithm>
#include <memory>
class Expr {
public:
  //-- rule of thumb --> if your class is going to be inherited by other classes
  // -- that is it has a virtual function, we must make the destructor virtual
  // also to ensure safe cleanup
  virtual ~Expr() = default;
};

//-- using final so the class cannot be inherited
class NumberExpr final : public Expr {
private:
  double value_;

public:
  explicit NumberExpr(double value) : value_{value} {}

  double value() const { return value_; }
};

class BinaryExpr final : public Expr {
private:
  std::unique_ptr<Expr> left_;
  TokenType operation_;
  std::unique_ptr<Expr> right_;

public:
  //-- using move to transfer the ownership
  // -- readson for amkeing left_ and right_ pointers
  // - to facilitate dynamic polymorhpism
  // - to prevent recursive strucure, like if we pass in Expr,
  // - it may contain a BinaryExpr, which conatains an Expr and that could contain BinaryExpr also
  BinaryExpr(std::unique_ptr<Expr> left, TokenType operation,
             std::unique_ptr<Expr> right)
      : left_{std::move(left)}, operation_{operation},
        right_{std::move(right)} {}

  const Expr &left() const { return *left_; }

  const Expr &right() const { return *right_; }

  TokenType operation() const { return operation_; }
};
