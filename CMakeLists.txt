cmake_minimum_required(VERSION 3.17)
project(Elaborato_mid_term CUDA)

set(CMAKE_CUDA_STANDARD 14)
set(CMAKE_VERBOSE_MAKEFILE ON)

add_executable(Elaborato_mid_term bit_utils.h c_utils.h cuda_utils.h des.h des_consts.h des-cuda.cu des_utils.h des_kernel.h utils.h)

set_target_properties(
        Elaborato_mid_term
        PROPERTIES
        CUDA_SEPARABLE_COMPILATION ON)