cmake_minimum_required(VERSION 3.20)

project(MatrixTensor LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_executable(matrix_demo benchmarks/matrix_benchmark.cpp)
add_executable(matrix_benchmark benchmarks/matrix_benchmark.cpp)

add_link_options(-fsanitize=address,undefined)


add_compile_options(
-Wall -Wextra -Wpedantic -fsanitize=address,undefined -g -O0)

