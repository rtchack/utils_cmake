include(CheckIncludeFile)

find_program(protobufc_PROTOC_EXECUTABLE protoc-c)

execute_process(COMMAND ${protobufc_PROTOC_EXECUTABLE} --version
        OUTPUT_VARIABLE _PROTOBUFC_PROTOC_EXECUTABLE_VERSION)
if ("${_PROTOBUFC_PROTOC_EXECUTABLE_VERSION}"
        MATCHES
        "protobuf-c (\\d+.\\d+.\\d+)")
    set(_PROTOBUFC_PROTOC_EXECUTABLE_VERSION "${CMAKE_MATCH_1}")
endif ()
set(protobufc_VERSION ${_PROTOBUFC_PROTOC_EXECUTABLE_VERSION})

find_library(libprotobufc
        NAMES
        ${CMAKE_STATIC_LIBRARY_PREFIX}protobuf-c${CMAKE_STATIC_LIBRARY_SUFFIX})
set(protobufc_LIBRARY ${libprotobufc})
set(protobufc_LIBRARIES ${protobufc_LIBRARY})

execute_process(COMMAND which ${protobufc_PROTOC_EXECUTABLE}
        OUTPUT_VARIABLE _PROTOBUFC_PROTOC_EXECUTABLE_DIR)
get_filename_component(protobufc_INCLUDE_DIR ${_PROTOBUFC_PROTOC_EXECUTABLE_DIR} DIRECTORY)
if ("${protobufc_INCLUDE_DIR}" MATCHES "^(.+)/bin$")
    set(protobufc_INCLUDE_DIR "${CMAKE_MATCH_1}/include")
endif ()
set(protobufc_INCLUDE_DIRS ${protobufc_INCLUDE_DIR})

