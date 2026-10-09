cmake_minimum_required(VERSION 3.20)
project(vector_implementation LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

add_executable(vector_demo src/main.cpp)


target_include_directories(vector_demo PRIVATE include)
add_compile_options(
-Wall -Wextra -Wpedantic -fsanitize=address,undefined -g -O0)

add_link_options(-fsanitize=address,undefined)