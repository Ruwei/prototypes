cmake_minimum_required(VERSION 3.15)
project(HelloCMake VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

Setup_Version()

# sources
file(GLOB_RECURSE sources RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "*.h" "*.hpp" "*.inl" "*.cpp")
source_group(TREE ${CMAKE_CURRENT_SOURCE_DIR} FILES ${sources})


add_library(${PROJECT_NAME} ${sources})


target_link_libraries(${PROJECT_NAME} PRIVATE nlohmann_json::nlohmann_json Boost::graph)
# Set public include directories
target_include_directories(${PROJECT_NAME} PUBLIC
    $<INSTALL_INTERFACE:include>
)
# Set private include directories
target_include_directories(${PROJECT_NAME} PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
)


# public headers 
file(GLOB_RECURSE public_headers RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "*.hpp")
foreach(file ${public_headers})
  get_filename_component(dir ${file} DIRECTORY)
  install(FILES ${file} DESTINATION include/${dir})
endforeach()


# install
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX ${PROJECT_BINARY_DIR}/install CACHE PATH "..." FORCE)
endif()
if(MSVC)
  target_sources(${PROJECT_NAME} PRIVATE "Version.rc")
  install(TARGETS ${PROJECT_NAME}
    EXPORT ${PROJECT_NAME}Targets
    LIBRARY DESTINATION lib/$<CONFIG>
    ARCHIVE DESTINATION lib/$<CONFIG>
    RUNTIME DESTINATION bin/$<CONFIG>
  )
else()
  install(TARGETS ${PROJECT_NAME}
    EXPORT ${PROJECT_NAME}Targets
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    RUNTIME DESTINATION bin
  )
endif()
install(EXPORT ${PROJECT_NAME}Targets
  FILE ${PROJECT_NAME}Targets.cmake
  DESTINATION lib/cmake/${PROJECT_NAME}
)

# Find package settings
configure_file(../cmake/${PROJECT_NAME}Config.cmake.in ${PROJECT_NAME}Config.cmake @ONLY)
