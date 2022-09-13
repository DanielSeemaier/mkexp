project(InMemoryDriver CXX)
cmake_minimum_required(VERSION 3.10)

find_package(MPI REQUIRED)

find_package(CGAL QUIET)
if (CGAL_FOUND)
    include(${CGAL_USE_FILE})
endif ()

set(LIBS MPI::MPI_CXX kagen spooky sampling tlx)

add_executable(InMemoryParhip parhip.cpp)
target_link_libraries(InMemoryParhip PUBLIC ${LIBS} parhip kahip)

add_executable(InMemoryParmetis parmetis.cpp)
target_link_libraries(InMemoryParmetis PUBLIC ${LIBS} parmetis metis GKlib)

find_package(OpenMP)

add_executable(InMemoryXtraPuLP xtrapulp.cpp)
target_link_libraries(InMemoryXtraPuLP PUBLIC ${LIBS} xtrapulp OpenMP::OpenMP_CXX)
