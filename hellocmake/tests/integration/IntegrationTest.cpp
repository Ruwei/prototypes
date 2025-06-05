#include "hello.hpp"
#include <gtest/gtest.h>

TEST(HelloTest, Hello) {
    testing::internal::CaptureStdout();
    hello("World");
    std::string output = testing::internal::GetCapturedStdout();
    EXPECT_EQ(output, "Hello, World!");
}