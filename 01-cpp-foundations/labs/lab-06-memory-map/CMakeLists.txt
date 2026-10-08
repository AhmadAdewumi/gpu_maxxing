cmake_minimum_required(VERSION 3.20)
project(lab06_memory_map CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_compile_options(
-Wall -Wextra -Wpedantic -fsanitize=address,undefined -g -O0)

add_link_options(-fsanitize=address,undefined)

add_executable(lab06 main.cpp)
