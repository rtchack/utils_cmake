find_package(Git REQUIRED)
if (GIT_FOUND)
    execute_process(
            COMMAND ${GIT_EXECUTABLE} rev-parse --short HEAD
            WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
            OUTPUT_VARIABLE GIT_COMMIT_VERSION
            OUTPUT_STRIP_TRAILING_WHITESPACE
    )
else ()
    message(FATAL_ERROR "Could not find Git")
endif ()

set(PROGRAM_VERSION_MAJOR 0 CACHE STRING "Program major version")
set(PROGRAM_VERSION_MINOR 1 CACHE STRING "Program minor version")
set(PROGRAM_VERSION_PATCH 0 CACHE STRING "Program patch version")
set(PROGRAM_VERSION
        ${PROGRAM_VERSION_MAJOR}.${PROGRAM_VERSION_MINOR}.${PROGRAM_VERSION_PATCH}
        STRING
        "Program version")

macro(check_pkg_ver ver)
    set(PACKAGE_VERSION ${ver})

    if (NOT ver OR
    (PACKAGE_FIND_VERSION VERSION_EQUAL PACKAGE_VERSION))
        set(PACKAGE_VERSION_EXACT TRUE)
        set(PACKAGE_VERSION_COMPATIBLE TRUE)
        set(PACKAGE_VERSION_UNSUITABLE FALSE)
    else ()
        set(PACKAGE_VERSION_EXACT FALSE)

        if (PACKAGE_FIND_VERSION VERSION_GREATER PACKAGE_VERSION)
            set(PACKAGE_VERSION_COMPATIBLE TRUE)
            set(PACKAGE_VERSION_UNSUITABLE FALSE)
        else ()
            set(PACKAGE_VERSION_COMPATIBLE FALSE)
            set(PACKAGE_VERSION_UNSUITABLE TRUE)
        endif ()
    endif ()
endmacro()

cmake_print_variables(
        PROGRAM_GIT_VERSION
        PROGRAM_VERSION_MAJOR
        PROGRAM_VERSION_MINOR
        PROGRAM_VERSION_PATCH
        PROGRAM_VERSION
)
