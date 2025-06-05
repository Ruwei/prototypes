function(disable_coverage COVERAGE_OPTION_VAR)
  set(${COVERAGE_OPTION_VAR} OFF PARENT_SCOPE)
  set(${COVERAGE_OPTION_VAR} OFF CACHE BOOL "Enable code coverage" FORCE)
endfunction()

# Define the function to check and set up coverage, will define COVERAGE_TYPE variable to be used later
function(check_and_setup_coverage ENABLE_TEST_VAR ENABLE_COVERAGE_VAR)
    set(COVERAGE_TYPE "" PARENT_SCOPE)

    message("check and setup coverage")
    if(NOT ${ENABLE_COVERAGE_VAR})
        return()  # Early exit if not enabled
    endif()

    # Check 1: Build type must be Debug or RelWithDebInfo
    # Handle both single-config and multi-config generators
    set(BUILD_TYPE_TO_CHECK "")
    if(CMAKE_CONFIGURATION_TYPES)
        # Multi-config generator (Visual Studio, Xcode)
        # For multi-config, we'll assume Debug is available and defer the actual check to build time
        message(STATUS "Multi-config generator detected. Available configurations: ${CMAKE_CONFIGURATION_TYPES}")
        # Check if Debug is in the available configurations
        list(FIND CMAKE_CONFIGURATION_TYPES "Debug" DEBUG_INDEX)
        list(FIND CMAKE_CONFIGURATION_TYPES "RelWithDebInfo" RELWITHDEBINFO_INDEX)
        if(DEBUG_INDEX EQUAL -1 AND RELWITHDEBINFO_INDEX EQUAL -1)
            message(WARNING "Coverage disabled: Neither Debug nor RelWithDebInfo configuration available")
            disable_coverage(${ENABLE_COVERAGE_VAR})
            return()
        endif()
        set(BUILD_TYPE_TO_CHECK "Debug") # Assume Debug for now
    else()
        # Single-config generator (Makefiles, Ninja)
        set(BUILD_TYPE_TO_CHECK "${CMAKE_BUILD_TYPE}")
    endif()

    # Check 2: Handle MSVC and ClangCL
    if(MSVC AND NOT CMAKE_CXX_COMPILER_ID MATCHES "Clang")
        message(WARNING "Coverage disabled: MSVC compiler detected (ClangCL is supported)")
        disable_coverage(${ENABLE_COVERAGE_VAR})
        return()
    endif()

    # Check 3: ENABLE_TEST must be ON
    if(NOT ${ENABLE_TEST_VAR})
        message(WARNING "Coverage disabled: ENABLE_TEST is OFF")
        disable_coverage(${ENABLE_COVERAGE_VAR})
        return()
    endif()

    # Detect actual compiler - handle ClangCL case
    set(ACTUAL_COMPILER_ID "")
    if(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
        set(ACTUAL_COMPILER_ID "Clang")
    elseif(CMAKE_GENERATOR_TOOLSET MATCHES "ClangCL" OR CMAKE_VS_PLATFORM_TOOLSET MATCHES "ClangCL")
        set(ACTUAL_COMPILER_ID "Clang")
        message(STATUS "Detected ClangCL toolset - treating as Clang for coverage")
    elseif(CMAKE_CXX_COMPILER_ID MATCHES "GNU")
        set(ACTUAL_COMPILER_ID "GNU")
    else()
        message(STATUS "Compiler ID: '${CMAKE_CXX_COMPILER_ID}', Toolset: '${CMAKE_GENERATOR_TOOLSET}', Platform Toolset: '${CMAKE_VS_PLATFORM_TOOLSET}'")
        message(WARNING "Coverage disabled: Unsupported compiler")
        disable_coverage(${ENABLE_COVERAGE_VAR})
        return()
    endif()

    # Check 4: Compiler version (skip for ClangCL as version detection may be tricky)
    if(ACTUAL_COMPILER_ID STREQUAL "GNU" AND CMAKE_CXX_COMPILER_VERSION VERSION_LESS "5.0")
        message(WARNING "Coverage disabled: GCC version too old (requires 5.0+), found ${CMAKE_CXX_COMPILER_VERSION}")
        disable_coverage(${ENABLE_COVERAGE_VAR})
        return()
    elseif(ACTUAL_COMPILER_ID STREQUAL "Clang" AND CMAKE_CXX_COMPILER_VERSION AND CMAKE_CXX_COMPILER_VERSION VERSION_LESS "3.6")
        message(WARNING "Coverage disabled: Clang version too old (requires 3.6+), found ${CMAKE_CXX_COMPILER_VERSION}")
        disable_coverage(${ENABLE_COVERAGE_VAR})
        return()
    endif()

    # Check 5: Coverage tools
    set(COVERAGE_TOOL_FOUND FALSE)
    set(COVERAGE_TOOL_NAME "")

    get_filename_component(COMPILER_DIR ${CMAKE_CXX_COMPILER} DIRECTORY)

    if(ACTUAL_COMPILER_ID STREQUAL "GNU")
        find_program(GCOV_EXECUTABLE gcov)
        if(GCOV_EXECUTABLE)
            set(COVERAGE_TOOL_FOUND TRUE)
            set(COVERAGE_TOOL_NAME "gcov")
            set(COVERAGE_TYPE "gcov")
            message(STATUS "Found gcov: ${GCOV_EXECUTABLE}")
        endif()
    elseif(ACTUAL_COMPILER_ID STREQUAL "Clang")
        find_program(LLVM_COV_EXECUTABLE llvm-cov HINTS ${COMPILER_DIR})
        find_program(LLVM_PROFDATA_EXECUTABLE llvm-profdata HINTS ${COMPILER_DIR}) 
        if(LLVM_COV_EXECUTABLE AND LLVM_PROFDATA_EXECUTABLE)
            set(COVERAGE_TOOL_FOUND TRUE)
            set(COVERAGE_TOOL_NAME "llvm-cov")
            set(COVERAGE_TYPE "llvm")
            message(STATUS "Found llvm-cov: ${LLVM_COV_EXECUTABLE}")
            message(STATUS "Found llvm-profdata: ${LLVM_PROFDATA_EXECUTABLE}")
        elseif(LLVM_COV_EXECUTABLE)
            message(WARNING "Found llvm-cov but missing llvm-profdata - coverage may not work")
        else()
            message(WARNING "llvm-cov and llvm-profdata not found in PATH")
        endif()
    endif()

    if(NOT COVERAGE_TOOL_FOUND)
        find_program(LCOV_EXECUTABLE lcov)
        find_program(GCOV_EXECUTABLE gcov)  # Re-check for lcov dependency
        if(LCOV_EXECUTABLE AND GCOV_EXECUTABLE)
            set(COVERAGE_TOOL_FOUND TRUE)
            set(COVERAGE_TOOL_NAME "lcov")
            message(STATUS "Found lcov: ${LCOV_EXECUTABLE}")
        else()
            message(WARNING "Coverage disabled: No coverage tools found")
        endif()
    endif()

    if(NOT COVERAGE_TOOL_FOUND)
        disable_coverage(${ENABLE_COVERAGE_VAR})
        return()
    endif()

    # Set coverage flags if all checks pass
    if(ACTUAL_COMPILER_ID STREQUAL "GNU")
        add_compile_options(--coverage -g -O0)
        add_link_options(--coverage)
    elseif(ACTUAL_COMPILER_ID STREQUAL "Clang")
        add_compile_options(-fprofile-instr-generate -fcoverage-mapping -g -O0)
        add_link_options(-fprofile-instr-generate)
        set(ENV{LLVM_PROFILE_FILE} "${CMAKE_BINARY_DIR}/default.profraw")  # More scoped
    endif()

    message(STATUS "Code coverage is ENABLED using ${COVERAGE_TOOL_NAME} (${COVERAGE_TYPE}) with ${ACTUAL_COMPILER_ID}")
    set(COVERAGE_TYPE "${COVERAGE_TYPE}" PARENT_SCOPE)

endfunction()

function(setup_coverage_report ENABLE_COVERAGE_VAR ENABLE_TEST_VAR COVERAGE_TYPE_VAR test_target)
    if(NOT ${ENABLE_TEST_VAR})
        return()  # Early exit if testing is not enabled
    endif()

    include(CTest)
    enable_testing()
    find_package(GTest REQUIRED)  # Ensure this is handled properly

    if(${ENABLE_COVERAGE_VAR})
        if(${COVERAGE_TYPE_VAR} STREQUAL "llvm")
            # Create coverage directory
            file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/coverage)

            # Create coverage report target for LLVM
            add_custom_target(coverage-${PROJECT_NAME}
                COMMAND ${CMAKE_COMMAND} -E env LLVM_PROFILE_FILE=${CMAKE_BINARY_DIR}/default.profraw ${CMAKE_CTEST_COMMAND} --output-on-failure
                COMMAND ${LLVM_PROFDATA_EXECUTABLE} merge -sparse ${CMAKE_BINARY_DIR}/default.profraw -o ${CMAKE_BINARY_DIR}/default.profdata
                COMMAND ${LLVM_COV_EXECUTABLE} show $<TARGET_FILE:${test_target}> -instr-profile=${CMAKE_BINARY_DIR}/default.profdata
                COMMAND ${LLVM_COV_EXECUTABLE} export $<TARGET_FILE:${test_target}> -instr-profile=${CMAKE_BINARY_DIR}/default.profdata -format=lcov > ${CMAKE_BINARY_DIR}/lcov.info
                COMMAND ${LLVM_COV_EXECUTABLE} report $<TARGET_FILE:${test_target}> -instr-profile=${CMAKE_BINARY_DIR}/default.profdata
                WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
                COMMENT "Running tests and generating LLVM coverage report"
                DEPENDS ${test_target}
            )

            # Create HTML coverage report target for LLVM
            add_custom_target(coverage-html-${PROJECT_NAME}
                COMMAND ${CMAKE_COMMAND} -E env LLVM_PROFILE_FILE=${CMAKE_BINARY_DIR}/default.profraw ${CMAKE_CTEST_COMMAND} --output-on-failure
                COMMAND ${LLVM_PROFDATA_EXECUTABLE} merge -sparse ${CMAKE_BINARY_DIR}/default.profraw -o ${CMAKE_BINARY_DIR}/default.profdata
                COMMAND ${LLVM_COV_EXECUTABLE} show $<TARGET_FILE:${test_target}> -instr-profile=${CMAKE_BINARY_DIR}/default.profdata -format=html -output-dir=${CMAKE_BINARY_DIR}/coverage-html
                WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
                COMMENT "Running tests and generating LLVM HTML coverage report"
                DEPENDS ${test_target}
            )
            
            # Set test environment for the target   
            message(STATUS "Coverage targets created: 'coverage-${PROJECT_NAME}', 'coverage-html-${PROJECT_NAME}'")
            
        elseif(${COVERAGE_TYPE_VAR} STREQUAL "gcov")  # GCC/gcov
            find_program(LCOV_EXECUTABLE lcov)
            find_program(GENHTML_EXECUTABLE genhtml)
            if(LCOV_EXECUTABLE AND GENHTML_EXECUTABLE)
                add_custom_target(coverage-html-${PROJECT_NAME}
                    COMMAND ${CMAKE_CTEST_COMMAND} --output-on-failure
                    COMMAND ${LCOV_EXECUTABLE} --capture --directory ${CMAKE_BINARY_DIR} --output-file coverage.info
                    COMMAND ${LCOV_EXECUTABLE} --remove coverage.info '/usr/*' --output-file coverage.info.cleaned
                    COMMAND ${GENHTML_EXECUTABLE} coverage.info.cleaned --output-directory coverage-html
                    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
                    COMMENT "Generating HTML coverage report"
                    DEPENDS ${test_target}
                )
                
                add_custom_target(coverage-summary-${PROJECT_NAME}
                    COMMAND ${CMAKE_CTEST_COMMAND} --output-on-failure
                    COMMAND ${LCOV_EXECUTABLE} --capture --directory ${CMAKE_BINARY_DIR} --output-file coverage.info
                    COMMAND ${LCOV_EXECUTABLE} --summary coverage.info
                    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
                    COMMENT "Generating coverage summary"
                    DEPENDS ${test_target}
                )
                
                message(STATUS "Coverage targets created: 'coverage-html-${PROJECT_NAME}', 'coverage-summary-${PROJECT_NAME}'")
            else()
                message(WARNING "Cannot generate HTML report: lcov or genhtml not found")
            endif()
        else()
            message(WARNING "Unknown coverage type: ${COVERAGE_TYPE_VAR}")
        endif()
    endif()
endfunction()