#
# Created by xing in 2019.
#

function(compile_optimize name)
    if (WIN32)
        target_compile_options(${name} PUBLIC -W4)

        foreach (flag_var
                CMAKE_C_LINK_FLAGS
                CMAKE_C_LINK_FLAGS_DEBUG
                CMAKE_C_LINK_FLAGS_RELEASE
                CMAKE_CXX_LINK_FLAGS
                CMAKE_CXX_LINK_FLAGS_DEBUG
                CMAKE_CXX_LINK_FLAGS_RELEASE
                CMAKE_EXE_LINKER_FLAGS
                CMAKE_EXE_LINKER_FLAGS_DEBUG
                CMAKE_EXE_LINKER_FLAGS_RELEASE)
            string(REPLACE "/MD" "/MT" ${flag_var} "${${flag_var}}")
            string(REPLACE "/SAFESEH(:NO)?" "" ${flag_var} "${${flag_var}}")
            set(${flag_var} "${${flag_var}} /SAFESEH:NO")
            cmake_print_variables(name ${flag_var})
        endforeach ()

        foreach (p
                LINK_FLAGS
                LINK_FLAGS_RELEASE
                LINK_FLAGS_DEBUG
                LINK_OPTIONS
                INTERFACE_LINK_OPTIONS)
            get_target_property(flags ${name} ${p})
            if (flags)
                if (ENABLE_MD)
                    string(REPLACE "/MT" "/MD" flags "${flags}")
                else ()
                    string(REPLACE "/MD" "/MT" flags "${flags}")
                endif ()
                string(REPLACE "/SAFESEH(:NO)?" "" flags "${flags}")
                set(flags "${flags} /SAFESEH:NO")
            else ()
                set(flags "/SAFESEH:NO")
            endif ()
            cmake_print_variables(name p flags)
            set_target_properties(${name} PROPERTIES ${p} ${flags})
        endforeach ()
    else ()
        target_compile_options(${name}
                PRIVATE -Wall
                PRIVATE -Werror)

        if (CMAKE_BUILD_TYPE STREQUAL "Debug")
            target_compile_options(${name} PRIVATE -Ddbg)
            if (ENABLE_ASAN)
                # As `target_link_options` needs CMake with version greater than 3.13,
                # use `set_target_properties` on `LINK_FLAGS_DEBUG` instead.
                #
                #      target_link_options(${name}
                #          PUBLIC -fno-omit-frame-pointer
                #          PUBLIC -fsanitize=address)
                set_target_properties(${name}
                        PROPERTIES
                        LINK_FLAGS_DEBUG -fno-omit-frame-pointer
                        LINK_FLAGS_DEBUG -fsanitize=address)
            endif ()
        else ()
            target_compile_options(${name} PRIVATE -O3)
        endif ()
    endif ()
endfunction()

function(target_optimize_perf name)
    phuck_msvc()
    compile_optimize(${name})

    target_compile_features(${name} PUBLIC cxx_std_11)
    set_target_properties(${name} PROPERTIES CXX_EXTENSIONS OFF)

    if (CMAKE_BUILD_TYPE MATCHES Release)
        include(CheckIPOSupported)
        check_ipo_supported(RESULT result)
        if (result)
            message("Enable IPO on ${name}")
            set_target_properties(${name} PROPERTIES INTERPROCEDURAL_OPTIMIZATION TRUE)
        endif ()
    endif ()
endfunction()

function(target_inc_libraries)
    list(GET ARGV 0 tgt)
    list(REMOVE_AT ARGV 0)
    list(GET ARGV 0 type)
    list(REMOVE_AT ARGV 0)

    foreach (dep ${ARGV})
        get_target_property(incs ${dep} INTERFACE_INCLUDE_DIRECTORIES)
        foreach (i ${incs})
            target_include_directories(${tgt} ${type} ${i})
        endforeach ()
    endforeach ()
endfunction()

function(target_link_and_inc_libraries)
    target_link_libraries(${ARGV})
    target_inc_libraries(${ARGV})
endfunction()

# Borrowed from GoogleTest
macro(phuck_msvc)
    if (MSVC)
        # For MSVC, CMake sets certain flags to defaults we want to override.
        # This replacement code is taken from sample in the CMake Wiki at
        # https://gitlab.kitware.com/cmake/community/wikis/FAQ#dynamic-replace.
        foreach (flag_var
                CMAKE_C_FLAGS CMAKE_C_FLAGS_DEBUG CMAKE_C_FLAGS_RELEASE
                CMAKE_C_FLAGS_MINSIZEREL CMAKE_C_FLAGS_RELWITHDEBINFO
                CMAKE_CXX_FLAGS CMAKE_CXX_FLAGS_DEBUG CMAKE_CXX_FLAGS_RELEASE
                CMAKE_CXX_FLAGS_MINSIZEREL CMAKE_CXX_FLAGS_RELWITHDEBINFO)
            #      if (NOT BUILD_SHARED_LIBS AND NOT gtest_force_shared_crt)
            # When Google Test is built as a shared library, it should also use
            # shared runtime libraries.  Otherwise, it may end up with multiple
            # copies of runtime library data in different modules, resulting in
            # hard-to-find crashes. When it is built as a static library, it is
            # preferable to use CRT as static libraries, as we don't have to rely
            # on CRT DLLs being available. CMake always defaults to using shared
            # CRT libraries, so we override that default here.
            if (ENABLE_MD)
                string(REPLACE "/MT" "/MD" ${flag_var} "${${flag_var}}")
            else ()
                string(REPLACE "/MD" "/MT" ${flag_var} "${${flag_var}}")
            endif ()
            #      endif ()

            # We prefer more strict warning checking for building Google Test.
            # Replaces /W3 with /W4 in defaults.
            string(REPLACE "/W3" "/W4" ${flag_var} "${${flag_var}}")

            # Prevent D9025 warning for targets that have exception handling
            # turned off (/EHs-c- flag). Where required, exceptions are explicitly
            # re-enabled using the cxx_exception_flags variable.
            string(REPLACE "/EHsc" "" ${flag_var} "${${flag_var}}")
        endforeach ()
    endif ()
endmacro()

macro(config_current_platform)
    if (CMAKE_SOURCE_DIR STREQUAL PROJECT_SOURCE_DIR)
        set(IS_TOPMOST_PROJECT TRUE)
    else ()
        set(IS_TOPMOST_PROJECT FALSE)
    endif ()

    if (WIN32)
        set(CURRENT_OS WINDOWS)

        set(OS_WIN32 1)
        set(OS_WINDOWS 1)
        set(OS_NTKERNEL 1)
        add_definitions(-DOS_WIN32=1)
        add_definitions(-DOS_WINDOWS=1)
        add_definitions(-DOS_NTKERNEL=1)
        list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR}/config/win)

    else ()
        list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR}/config/unix)

        if (APPLE)
            # Cmake on Apple would not search packages from home brew by default
            find_program(brew_bin_path brew)
            if (brew_bin_path)
                string(REGEX MATCH "^.+homebrew" brew_prefix ${brew_bin_path})
                list(APPEND CMAKE_SYSTEM_PREFIX_PATH ${brew_prefix})
                link_directories(${brew_prefix}/lib)
                include_directories(${brew_prefix}/include)
            endif ()

            set(OS_UNIX 1)
            set(OS_XNU 1)
            add_definitions(-DOS_UNIX=1)
            add_definitions(-DOS_XNU=1)

            if (IOS)
                #cmake_minimum_required(VERSION 3.15)
                set(CURRENT_OS IOS)
                set(OS_IOS 1)
                add_definitions(-DOS_IOS=1)
            else ()
                set(CURRENT_OS MACOS)
                set(OS_MACOSX 1)
                add_definitions(-DOS_MACOSX=1)
            endif ()

        elseif (UNIX)
            set(CURRENT_OS LINUX)

            set(OS_UNIX 1)
            set(OS_LINUX 1)
            add_definitions(-DOS_UNIX=1)
            add_definitions(-DOS_LINUX=1)
            if (ANDROID)
                set(OS_ANDROID 1)
                add_definitions(-DOS_ANDROID=1)
            endif ()

        else ()
            set(CURRENT_OS UNKNOWN)
        endif ()
    endif ()

    cmake_print_variables(CURRENT_OS CMAKE_CXX_COMPILER_ID CMAKE_C_COMPILER_ID)
endmacro()

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
include(CheckTypeSize)
include(CMakePrintHelpers)
config_current_platform()
phuck_msvc()
