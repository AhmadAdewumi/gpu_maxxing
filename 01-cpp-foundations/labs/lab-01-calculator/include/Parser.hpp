#pragma once

#include "Lexer.hpp"
#include "Token.hpp"
#include <string_view>
class Parser{
    public:
        explicit Parser(std::string_view input);
        double parse();

    private:
        Lexer lexer_; //-- the parser's lexer
        Token current_; // for the parser to remember the token it is currently looking at
        void advance(); // to move the parser to the next token
        void expect(TokenType tokenType); // to ascertain the token is the type we want or is expecting

        //-- grammar rule functions
        double parseExpression();
        double parseTerm();
        double parseFactor();
};