cmake_minimum_required(VERSION 3.15)
project(LibraryIntegrationTest)

include(GoogleTest)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

enable_testing()

# setup temporary install folder for integration tests
set(integration_install_dir ${CMAKE_BINARY_DIR}/integration_install)

# add a custom command to install the SDK for integration tests
add_custom_command(OUTPUT ${integration_install_dir}/.installed
    COMMAND ${CMAKE_COMMAND} --install ${CMAKE_BINARY_DIR} --prefix ${integration_install_dir} --config $<CONFIG>
    COMMAND ${CMAKE_COMMAND} -E touch ${integration_install_dir}/.installed
    COMMENT "Installing SDK for integration tests"
    VERBATIM
)

# create a custom target that depends on the installation command
add_custom_target(install_sdk_for_integration DEPENDS ${integration_install_dir}/.installed)

FILE(GLOB_RECURSE TEST_FILES ${CMAKE_CURRENT_SOURCE_DIR}/*.cpp)

find_package(GTest REQUIRED)

add_executable(${PROJECT_NAME} ${TEST_FILES})
add_dependencies(${PROJECT_NAME} HelloCMake)  # Ensure the main library is built first
add_dependencies(${PROJECT_NAME} install_sdk_for_integration)

target_include_directories(${PROJECT_NAME} PRIVATE
    $<BUILD_INTERFACE:${integration_install_dir}/include>
)

target_link_directories(${PROJECT_NAME} PRIVATE
    $<BUILD_INTERFACE:${integration_install_dir}/lib/$<CONFIG>>
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