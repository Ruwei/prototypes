cmake_minimum_required(VERSION 3.15)
project(LibraryUnitTest)

include(GoogleTest)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON) 
enable_testing()

FILE(GLOB_RECURSE TEST_FILES ${CMAKE_CURRENT_SOURCE_DIR}/*.cpp) 

find_package(GTest REQUIRED)

add_executable(${PROJECT_NAME} ${TEST_FILES})
target_include_directories(${PROJECT_NAME} PRIVATE
    ${CMAKE_SOURCE_DIR}/src
)
target_link_libraries(${PROJECT_NAME} 
    PRIVATE 
    HelloCMake 
    GTest::gtest 
    GTest::gtest_main 
)

# Automatically discover all GoogleTest test cases in the project's binary
gtest_discover_tests(${PROJECT_NAME}
    # Optional: specify a WORKING_DIRECTORY or other properties
)

# Get parent scope variables - these need to be passed down from parent
# or defined locally if this CMakeLists.txt is processed independently
if(DEFINED ENABLE_COVERAGE AND DEFINED ENABLE_TEST AND DEFINED COVERAGE_TYPE)
    setup_coverage_report(ENABLE_COVERAGE ENABLE_TEST COVERAGE_TYPE ${PROJECT_NAME})
else()
    message(STATUS "Coverage variables not defined in this scope - skipping coverage setup")
endif()