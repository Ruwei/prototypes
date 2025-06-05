# HelloCmake

This is a sample Conan + CMake project, which uses gtest as the test framework. 

## Getting started
- Step up conan2.0 
  Please refer to https://docs.conan.io/2/tutorial.html

- Dependency management  
  Use conan to pull the dependency binaries with the following command:
  	```
	cd hellocmake
	conan install . -of=build --build=missing -pr:a=llvm
	```   
  note: the parameter '-pr:a=llvm' is optional.  

- Build with CMake  

	```
  cd build
  cmake --preset conan-default ..
	cmake --build .
	```  

- Test with CMake  


## Generate coverage report 

### Prerequisites 
- VSCode preparision 
  Install "Coverage Gutters" VSCode extension and edit plugin settings.json to add the following option: 
  ```
      "coverage-gutters.coverageFileNames": [
        "coverage.info"
      ]
  ``` 

- Windows 
  1. Install "CLang/LLVM Support" for you Visual Studio. Please refer to https://learn.microsoft.com/zh-cn/cpp/build/clang-support-msbuild?view=msvc-170 for details.

- Linux
  Install "lcov".
  ```
    sudo apt-get install lcov
  ```
 
### Generate & view coverage report 
 
 - VSCode
    1. Reopen VSCode after run "conan install" to pull the dependency and then you will see ['conan-default config] at the bottom available as one of the CMake active configure preset. 
    ![conan-default](/docs/cmake-preset.png "CMake active configure preset")
 
    2. Press "Ctrl + Shift + P" and select "CMake: Build Target", choose either "coverage-LibraryIntegrationTest" or "coverage-LibraryUnitTest"
    You will see in the output window some coverage report info. 

    3. Press "Ctrl + Shift + P" and select "Coverage Gutters: Display Coverage" and check out the source code file, the test code coverage will display. 
     ![conan-default](/docs/coverage.png "CMake active configure preset")
   
 - Command Line  
    1. Config project with ENABLE_COVERAGE option on: 
      ```
      cd build
      cmake .. -G "Visual Studio 17 2022" -DCMAKE_TOOLCHAIN_FILE="conan_toolchain.cmake"  -DCMAKE_POLICY_DEFAULT_CMP0091=NEW -DENABLE_COVERAGE=ON
      ```
  
    2. Build the project 
      ```
      cmake --build . --parallel 3 --config Debug 
      // Or alternately: 
      // cmake --build . --preset conan-debug 
      ```

    3. Get coverage report. 
      ```
      cmake --build . --target ${coverage_target} //replace ${coverage_target} with either "coverage-LibraryIntegrationTest" or "coverage-LibraryUnitTest"
      ```

### TODO

Consider combine the UT coverage report & integration test coverage report together.  


