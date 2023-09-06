if(NOT AVR_TOOLCHAIN_PATH)
    if(DEFINED ENV{AVR_TOOLCHAIN_PATH})
        message(STATUS "Detected toolchain path AVR_TOOLCHAIN_PATH in environmental variables: ")
        message(STATUS "$ENV{AVR_TOOLCHAIN_PATH}")
        set(AVR_TOOLCHAIN_PATH $ENV{AVR_TOOLCHAIN_PATH})
    else()
        if(NOT CMAKE_C_COMPILER)
            set(AVR_TOOLCHAIN_PATH "/usr")
            message(STATUS "No AVR_TOOLCHAIN_PATH specified, using default: " ${AVR_TOOLCHAIN_PATH})
        else()
            # keep only directory of compiler
            get_filename_component(AVR_TOOLCHAIN_PATH ${CMAKE_C_COMPILER} DIRECTORY)
            # remove the last /bin directory
            get_filename_component(AVR_TOOLCHAIN_PATH ${AVR_TOOLCHAIN_PATH} DIRECTORY)
        endif()
    endif()
    file(TO_CMAKE_PATH "${AVR_TOOLCHAIN_PATH}" AVR_TOOLCHAIN_PATH)
endif()

if(NOT AVR_TARGET)
    set(AVR_TARGET "avr")
    message(STATUS "No AVR_TARGET specified, using default: " ${AVR_TARGET})
endif()

set(CMAKE_SYSTEM_NAME generic)
set(CMAKE_SYSTEM_PROCESSOR avr)

set(TOOLCHAIN_SYSROOT  "${AVR_TOOLCHAIN_PATH}/")
set(TOOLCHAIN_BIN_PATH "${AVR_TOOLCHAIN_PATH}/bin")
set(TOOLCHAIN_INC_PATH "${AVR_TOOLCHAIN_PATH}/avr/include")
set(TOOLCHAIN_LIB_PATH "${AVR_TOOLCHAIN_PATH}/avr/lib")

set(CMAKE_SYSROOT ${TOOLCHAIN_SYSROOT})

find_program(CMAKE_OBJCOPY NAMES ${AVR_TARGET}-objcopy HINTS ${TOOLCHAIN_BIN_PATH})
find_program(CMAKE_OBJDUMP NAMES ${AVR_TARGET}-objdump HINTS ${TOOLCHAIN_BIN_PATH})
find_program(CMAKE_SIZE NAMES ${AVR_TARGET}-size HINTS ${TOOLCHAIN_BIN_PATH})
find_program(CMAKE_DEBUGGER NAMES ${AVR_TARGET}-gdb HINTS ${TOOLCHAIN_BIN_PATH})
find_program(CMAKE_CPPFILT NAMES ${AVR_TARGET}-c++filt HINTS ${TOOLCHAIN_BIN_PATH})

# This function adds a target with name '${TARGET}_always_display_size'. The new
# target builds a TARGET and then calls the program defined in CMAKE_SIZE to
# display the size of the final ELF.
function(avr_print_size_of_target TARGET)
    add_custom_target(${TARGET}_always_display_size
        ALL COMMAND ${CMAKE_SIZE} "$<TARGET_FILE:${TARGET}>"
        COMMENT "Target Sizes: "
        DEPENDS ${TARGET}
    )
endfunction()

function(avr_add_linker_script TARGET VISIBILITY SCRIPT)
    get_filename_component(SCRIPT "${SCRIPT}" ABSOLUTE)
    target_link_options(${TARGET} ${VISIBILITY} -T "${SCRIPT}")

    get_target_property(TARGET_TYPE ${TARGET} TYPE)
    if(TARGET_TYPE STREQUAL "INTERFACE_LIBRARY")
        set(INTERFACE_PREFIX "INTERFACE_")
    endif()

    get_target_property(LINK_DEPENDS ${TARGET} ${INTERFACE_PREFIX}LINK_DEPENDS)
    if(LINK_DEPENDS)
        list(APPEND LINK_DEPENDS "${SCRIPT}")
    else()
        set(LINK_DEPENDS "${SCRIPT}")
    endif()


    set_target_properties(${TARGET} PROPERTIES ${INTERFACE_PREFIX}LINK_DEPENDS "${LINK_DEPENDS}")
endfunction()

# This function calls the objcopy program defined in CMAKE_OBJCOPY to generate
# file with object format specified in OBJCOPY_BFD_OUTPUT.
# The generated file has the name of the target output but with extension
# corresponding to the OUTPUT_EXTENSION argument value.
# The generated file will be placed in the same directory as the target output file.
function(_avr_generate_file TARGET OUTPUT_EXTENSION OBJCOPY_BFD_OUTPUT)
    get_target_property(TARGET_OUTPUT_NAME ${TARGET} OUTPUT_NAME)
    if (TARGET_OUTPUT_NAME)
        set(OUTPUT_FILE_NAME "${TARGET_OUTPUT_NAME}.${OUTPUT_EXTENSION}")
    else()
        set(OUTPUT_FILE_NAME "${TARGET}.${OUTPUT_EXTENSION}")
    endif()

    get_target_property(RUNTIME_OUTPUT_DIRECTORY ${TARGET} RUNTIME_OUTPUT_DIRECTORY)
    if(RUNTIME_OUTPUT_DIRECTORY)
        set(OUTPUT_FILE_PATH "${RUNTIME_OUTPUT_DIRECTORY}/${OUTPUT_FILE_NAME}")
    else()
        set(OUTPUT_FILE_PATH "${OUTPUT_FILE_NAME}")
    endif()

    add_custom_command(
        TARGET ${TARGET}
        POST_BUILD
        COMMAND ${CMAKE_OBJCOPY} -O ${OBJCOPY_BFD_OUTPUT} "$<TARGET_FILE:${TARGET}>" ${OUTPUT_FILE_PATH}
        BYPRODUCTS ${OUTPUT_FILE_PATH}
        COMMENT "Generating ${OBJCOPY_BFD_OUTPUT} file ${OUTPUT_FILE_NAME}"
    )
endfunction()

# This function adds post-build generation of the binary file from the target ELF.
# The generated file will be placed in the same directory as the ELF file.
function(avr_generate_binary_file TARGET)
    _avr_generate_file(${TARGET} "bin" "binary")
endfunction()

# This function adds post-build generation of the Motorola S-record file from the target ELF.
# The generated file will be placed in the same directory as the ELF file.
function(avr_generate_srec_file TARGET)
    _avr_generate_file(${TARGET} "srec" "srec")
endfunction()

# This function adds post-build generation of the Intel hex file from the target ELF.
# The generated file will be placed in the same directory as the ELF file.
function(avr_generate_hex_file TARGET)
    _avr_generate_file(${TARGET} "hex" "ihex")
endfunction()

function(avr_generate_lss_file TARGET)
    set(OUTPUT_FILE_NAME "${TARGET}.lss")

    get_target_property(RUNTIME_OUTPUT_DIRECTORY ${TARGET} RUNTIME_OUTPUT_DIRECTORY)
    if(RUNTIME_OUTPUT_DIRECTORY)
        set(OUTPUT_FILE_PATH "${RUNTIME_OUTPUT_DIRECTORY}/${OUTPUT_FILE_NAME}")
    else()
        set(OUTPUT_FILE_PATH "${OUTPUT_FILE_NAME}")
    endif()

    add_custom_command(
        TARGET ${TARGET}
        POST_BUILD
        COMMAND ${CMAKE_OBJDUMP} -h -S "$<TARGET_FILE:${TARGET}>" > ${OUTPUT_FILE_PATH}
        BYPRODUCTS ${OUTPUT_FILE_PATH}
        COMMENT "Generating extended listing file ${OUTPUT_FILE_NAME} from ELF output file."
    )
endfunction()
