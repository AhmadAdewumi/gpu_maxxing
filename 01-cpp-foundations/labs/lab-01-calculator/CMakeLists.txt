cmake_minimum_required(VERSION 3.20)
project(lab-01-calculator CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_compile_options(
-Wall -Wextra -Wpedantic -fsanitize=address,undefined -g -O0)

add_link_options(-fsanitize=address,undefined)

add_executable(
lab01_calc src/main.cpp
    src/Lexer.cpp
    src/Parser.cpp
    src/Evaluator.cpp
)

target_include_directories(lab01_calc PRIVATE include)
