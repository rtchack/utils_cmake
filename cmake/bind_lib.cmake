#
# Created by xing in 2019.
#
# It's realy painful to bundle static binaries together for all platforms, so
# after days of study, finally I figured out this thing.
#

cmake_minimum_required(VERSION 3.10)

function(bind_static_lib)
    list(GET ARGV 0 dst)
    list(REMOVE_AT ARGV 0)

    MESSAGE("Bind ${dst}: ${ARGV}")

    if (IOS)
        find_program(does_sed_exist sed)
        if (NOT does_sed_exist)
            MESSAGE(FATAL_ERROR "For no-EPN iOS we need sed!")
        endif ()

        get_property(xcode GLOBAL PROPERTY XCODE_EMIT_EFFECTIVE_PLATFORM_NAME)
        if (xcode)
            message('XCODE_EMIT_EFFECTIVE_PLATFORM_NAME is: ' ${xcode})
        else ()
            set_property(GLOBAL PROPERTY XCODE_EMIT_EFFECTIVE_PLATFORM_NAME ON)
            message("Force XCODE_EMIT_EFFECTIVE_PLATFORM_NAME on!")

            if (NOT TARGET_IOS_PLATFORM)
                MESSAGE("TARGET_IOS_PLATFORM not set, use `iphoneos`.")
            endif ()
            set(TARGET_IOS_PLATFORM iphoneos
                    CACHE STRING
                    "The sdk target, `iphoneos` or `iphonesimulator`")

            if (NOT (TARGET_IOS_PLATFORM MATCHES "^iphone(os|simulator)$"))
                MESSAGE(FATAL_ERROR
                        "TARGET_IOS_PLATFORM must be `iphoneos` or `iphonesimulator`!")
            endif ()
        endif ()
    endif ()

    set(full_dst
            ${PROJECT_BINARY_DIR}/${CMAKE_STATIC_LIBRARY_PREFIX}${dst}${CMAKE_STATIC_LIBRARY_SUFFIX})

    add_custom_target(${dst}_target ALL DEPENDS ${full_dst})

    if (${CMAKE_C_COMPILER_ID} MATCHES "^(Clang|GNU)$")
        set(cmd "CREATE ${full_dst}")

    elseif (${CMAKE_C_COMPILER_ID} STREQUAL AppleClang)
        set(cmd libtool -static -o ${full_dst})

    elseif (MSVC)
        get_filename_component(vs_bin_path ${CMAKE_LINKER} DIRECTORY)
        set(cmd ${vs_bin_path}/lib.exe /NOLOGO /VERBOSE /OUT:${full_dst})
    else ()
        message(FATAL_ERROR "Unknown bundle scenario ${CMAKE_C_COMPILER_ID}!")
    endif ()

    foreach (src ${ARGV})
        if (${CMAKE_C_COMPILER_ID} MATCHES "^(Clang|GNU)$")
            set(cmd "${cmd}\\nADDLIB $<TARGET_FILE:${src}>")

        elseif (${CMAKE_C_COMPILER_ID} STREQUAL AppleClang)
            set(cmd ${cmd} $<TARGET_FILE:${src}>)

        elseif (MSVC)
            set(cmd ${cmd} $<TARGET_FILE:${src}>)
        endif ()

        add_dependencies(${dst}_target ${src})
    endforeach ()

    if (${CMAKE_C_COMPILER_ID} MATCHES "^(Clang|GNU)$")
        set(cmd "${cmd}\\nSAVE\\nEND\\n")
        if (CMAKE_INTERPROCEDURAL_OPTIMIZATION)
            set(ar_tool ${CMAKE_CXX_COMPILER_AR})
        else ()
            set(ar_tool ${CMAKE_AR})
        endif ()
        add_custom_command(
                COMMAND echo "${cmd}" | ${ar_tool} -M
                OUTPUT ${full_dst}
                COMMENT "Bundling ${full_dst}"
                VERBATIM)

    elseif (${CMAKE_C_COMPILER_ID} STREQUAL AppleClang)
        if (IOS)
            add_custom_command(
                    COMMAND echo ${cmd} | sed s/\${EFFECTIVE_PLATFORM_NAME}/-${TARGET_IOS_PLATFORM}/g | bash
                    OUTPUT ${full_dst}
                    COMMENT "Bundling ${full_dst}"
                    VERBATIM)
        else ()
            add_custom_command(
                    COMMAND ${cmd}
                    OUTPUT ${full_dst}
                    COMMENT "Bundling ${full_dst}"
                    VERBATIM)
        endif ()

    elseif (MSVC)
        # Phuck Windows!
        add_custom_command(
                COMMAND ${cmd}
                OUTPUT ${full_dst}
                COMMENT "Bundling ${full_dst}"
                VERBATIM)
    endif ()

    add_library(${dst} STATIC IMPORTED)
    set_target_properties(${dst}
            PROPERTIES
            IMPORTED_LOCATION ${full_dst})
    target_include_directories(${dst} INTERFACE ${ARGV})
    add_dependencies(${dst} ${dst}_target)
    message("Bind ${dst} => ${full_dst}")
endfunction()

function(bind_static_self name new_name)
    get_target_property(interface_incs ${name} INTERFACE_INCLUDE_DIRECTORIES)
    get_target_property(incs ${name} INCLUDE_DIRECTORIES)

    get_target_property(interface_links ${name} INTERFACE_LINK_LIBRARIES)
    get_target_property(links ${name} LINK_LIBRARIES)
    bind_static_lib(${new_name} ${name} ${links} ${interface_links})

    target_include_directories(${new_name} INTERFACE ${interface_incs})
    target_include_directories(${new_name} INTERFACE ${incs})
endfunction()
