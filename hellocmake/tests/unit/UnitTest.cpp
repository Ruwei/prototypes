#include "hello.hpp"
#include "internal.h"

#include <gtest/gtest.h>

TEST(InternalTest, Hello) {
    getMaxBufferSize();  // Ensure the function is called to test its existence
    EXPECT_EQ(getMaxBufferSize(), 1024);  // Check if the maximum buffer size is as expected
}