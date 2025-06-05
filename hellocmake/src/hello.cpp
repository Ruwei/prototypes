#include <hello.hpp>
#include "internal.h"


void hello(const char *name) {
    printf("Hello, %s!", name);
}

int getMaxBufferSize()  // Function to retrieve the maximum buffer size
 {
    return MAX_BUFFER_SIZE; 
 }