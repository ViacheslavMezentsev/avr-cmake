if(${CMAKE_VERSION} VERSION_LESS "3.16.0") 
    message(WARNING "Current CMake version is ${CMAKE_VERSION}. stm32-cmake requires CMake 3.16 or greater")
endif()

get_filename_component(AVR_CMAKE_DIR ${CMAKE_CURRENT_LIST_FILE} DIRECTORY)
list(APPEND CMAKE_MODULE_PATH ${AVR_CMAKE_DIR})

include(avr/common)

set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

find_program(CMAKE_C_COMPILER NAMES ${AVR_TARGET}-gcc HINTS ${TOOLCHAIN_BIN_PATH})
find_program(CMAKE_CXX_COMPILER NAMES ${AVR_TARGET}-g++ HINTS ${TOOLCHAIN_BIN_PATH})
find_program(CMAKE_ASM_COMPILER NAMES ${AVR_TARGET}-gcc HINTS ${TOOLCHAIN_BIN_PATH})

set(CMAKE_EXECUTABLE_SUFFIX_C   .elf)
set(CMAKE_EXECUTABLE_SUFFIX_CXX .elf)
set(CMAKE_EXECUTABLE_SUFFIX_ASM .elf)

# This should be safe to set for a bare-metal cross-compiler
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
