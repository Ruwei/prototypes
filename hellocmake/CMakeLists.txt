cmake_minimum_required(VERSION 3.15)
project(HelloProject VERSION 1.0.0)

include(cmake/setup_coverage.cmake)
include(cmake/setup_version.cmake)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_INSTALL_PREFIX ${CMAKE_BINARY_DIR}/install)

option(ENABLE_TEST "Enable tests" ON)
option(ENABLE_COVERAGE "Enable code coverage reporting" ON)

# Pass variable names as strings, not values
check_and_setup_coverage(ENABLE_TEST ENABLE_COVERAGE)

find_package(nlohmann_json REQUIRED)
find_package(Boost REQUIRED COMPONENTS graph)

add_subdirectory(src)

if (ENABLE_TEST)
    include(CTest)
    add_subdirectory(tests)
endif()