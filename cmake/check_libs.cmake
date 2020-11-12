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

if (CMAKE_BUILD_TYPE STREQUAL "Debug")
    if (CMAKE_C_COMPILER_ID STREQUAL "GNU")
        if (ENABLE_ASAN)
            find_library(LIBASAN
                    NAMES asan libasan.so.0 libasan.so.3 libasan.so.4 libasan.so.5
                    REQUIRED)
            if (LIBASAN MATCHES "NOTFOUND$")
                message(FATAL_ERROR ${LIBASAN})
            endif ()
        endif ()
    endif ()
endif ()
