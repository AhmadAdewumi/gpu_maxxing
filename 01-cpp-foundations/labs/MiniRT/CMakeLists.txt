cmake_minimum_required(VERSION 3.20)
project(MiniRT LANGUAGES CXX)

add_executable(minirt src/main.cpp)
target_compile_features(minirt PRIVATE cxx_std_17)

target_compile_options(minirt PRIVATE -Wall -Wextra -Wpedantic)

option(MINIRT_SANITIZERS "Enable address and undefined behavior sanitizers" OFF)

if(MINIRT_SANITIZERS AND CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    target_compile_options(minirt PRIVATE
        -fsanitize=address,undefined
        -fno-omit-frame-pointer
        -g
    )
    target_link_options(minirt PRIVATE
        -fsanitize=address,undefined
    )
endif()
