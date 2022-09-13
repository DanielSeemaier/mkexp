project(Driver CXX)
cmake_minimum_required(VERSION 3.10)

find_package(MPI REQUIRED)
find_package(OpenMP)

add_executable(FromBinaryXtraPuLP xtrapulp.cpp)
target_link_libraries(FromBinaryXtraPuLP PUBLIC MPI::MPI_CXX xtrapulp OpenMP::OpenMP_CXX)
