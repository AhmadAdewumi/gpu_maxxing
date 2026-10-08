#pragma once

#include "AST.hpp"
#include "Lexer.hpp"
#include "Token.hpp"
#include <memory>
#include <string_view>
class Parser{
    public:
        explicit Parser(std::string_view input);
        std::unique_ptr<Expr> parse();

    private:
        Lexer lexer_; //-- the parser's lexer
        Token current_; // for the parser to remember the token it is currently looking at
        void advance(); // to move the parser to the next token
        void expect(TokenType tokenType); // to ascertain the token is the type we want or is expecting

        //-- grammar rule functions
        std::unique_ptr<Expr> parseExpression();
        std::unique_ptr<Expr> parseTerm();
        std::unique_ptr<Expr> parseFactor();
};