include(CheckCSourceCompiles)

set(TC_SRC_DIR ${CMAKE_CURRENT_LIST_DIR})

function(check_by_tc)
    # TODO(xing) Need a nicer way to filter out external C flags.
    set(ENV_CMAKE_C_FLAGS ${CMAKE_C_FLAGS})
    set(CMAKE_C_FLAGS)

    if (WIN32)
    else ()
        if (APPLE)
        elseif (UNIX)
            set(CMAKE_C_FLAGS -D_GNU_SOURCE=1)
        endif ()
    endif ()

    foreach (arg ${ARGV})
        set(lib_file "${TC_SRC_DIR}/${arg}.libs")
        if (EXISTS "${lib_file}")
            file(READ ${lib_file} libs)
            try_compile(
                    ${arg}
                    "${PROJECT_BINARY_DIR}/try_compile"
                    "${TC_SRC_DIR}/${arg}.c"
                    LINK_LIBRARIES ${libs}
            )
        else ()
            try_compile(
                    ${arg}
                    "${PROJECT_BINARY_DIR}/try_compile"
                    "${TC_SRC_DIR}/${arg}.c"
            )
        endif ()
    endforeach ()

    set(CMAKE_C_FLAGS ${ENV_CMAKE_C_FLAGS})

endfunction()