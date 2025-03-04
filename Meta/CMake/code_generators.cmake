#
# Functions for generating sources using host tools
#

function(compile_gml source output string_name)
    set(source ${CMAKE_CURRENT_SOURCE_DIR}/${source})
    add_custom_command(
        OUTPUT ${output}
        COMMAND ${SerenityOS_SOURCE_DIR}/Meta/text-to-cpp-string.sh ${string_name} ${source} > ${output}.tmp
        COMMAND "${CMAKE_COMMAND}" -E copy_if_different ${output}.tmp ${output}
        COMMAND "${CMAKE_COMMAND}" -E remove ${output}.tmp
        VERBATIM
        DEPENDS ${SerenityOS_SOURCE_DIR}/Meta/text-to-cpp-string.sh
        MAIN_DEPENDENCY ${source}
    )
    get_filename_component(output_name ${output} NAME)
    add_custom_target(generate_${output_name} DEPENDS ${output})
    add_dependencies(all_generated generate_${output_name})
endfunction()

function(compile_ipc source output)
    set(source ${CMAKE_CURRENT_SOURCE_DIR}/${source})
    add_custom_command(
        OUTPUT ${output}
        COMMAND $<TARGET_FILE:Lagom::IPCCompiler> ${source} > ${output}.tmp
        COMMAND "${CMAKE_COMMAND}" -E copy_if_different ${output}.tmp ${output}
        COMMAND "${CMAKE_COMMAND}" -E remove ${output}.tmp
        VERBATIM
        DEPENDS Lagom::IPCCompiler
        MAIN_DEPENDENCY ${source}
    )
    get_filename_component(output_name ${output} NAME)
    add_custom_target(generate_${output_name} DEPENDS ${output})
    add_dependencies(all_generated generate_${output_name})

    # TODO: Use cmake_path() when we upgrade the minimum CMake version to 3.20
    #       https://cmake.org/cmake/help/v3.23/command/cmake_path.html#relative-path
    string(LENGTH ${SerenityOS_SOURCE_DIR} root_source_dir_length)
    string(SUBSTRING ${CMAKE_CURRENT_SOURCE_DIR} ${root_source_dir_length} -1 current_source_dir_relative)
    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${output} DESTINATION usr/include${current_source_dir_relative} OPTIONAL)
endfunction()

function(generate_state_machine source header)
    get_filename_component(header_name ${header} NAME)
    set(target_name "generate_${header_name}")
    # Note: This function is called twice with the same header, once in the kernel
    #       and once in Userland/LibVT, this check makes sure that only one target
    #       is generated for that header.
    if(NOT TARGET ${target_name})
        set(source ${CMAKE_CURRENT_SOURCE_DIR}/${source})
        set(output ${CMAKE_CURRENT_BINARY_DIR}/${header})
        add_custom_command(
            OUTPUT ${output}
            COMMAND $<TARGET_FILE:Lagom::StateMachineGenerator> ${source} > ${output}.tmp
            COMMAND "${CMAKE_COMMAND}" -E copy_if_different ${output}.tmp ${output}
            COMMAND "${CMAKE_COMMAND}" -E remove ${output}.tmp
            VERBATIM
            DEPENDS Lagom::StateMachineGenerator
            MAIN_DEPENDENCY ${source}
        )
        add_custom_target(${target_name} DEPENDS ${output})
        add_dependencies(all_generated ${target_name})
    endif()
endfunction()

function(compile_jakt source)
    set(source ${CMAKE_CURRENT_SOURCE_DIR}/${source})
    get_filename_component(source_base ${source} NAME_WE)
    set(output "${source_base}.cpp")
    add_custom_command(
        OUTPUT ${output}
        COMMAND $<TARGET_FILE:Lagom::jakt> -S -o "${CMAKE_CURRENT_BINARY_DIR}/jakt_tmp" ${source}
        COMMAND "${CMAKE_COMMAND}" -E copy_if_different "${CMAKE_CURRENT_BINARY_DIR}/jakt_tmp/${output}" ${output}
        COMMAND "${CMAKE_COMMAND}" -E remove "${CMAKE_CURRENT_BINARY_DIR}/jakt_tmp/${output}"
        VERBATIM
        DEPENDS Lagom::jakt
        MAIN_DEPENDENCY ${source}
    )
    get_property(JAKT_INCLUDE_DIR TARGET Lagom::jakt PROPERTY IMPORTED_INCLUDE_DIRECTORIES)
    set_source_files_properties("${output}" PROPERTIES
        INCLUDE_DIRECTORIES "${JAKT_INCLUDE_DIR}/runtime"
        COMPILE_OPTIONS "-Wno-unused-local-typedefs;-Wno-unused-function")
    get_filename_component(output_name ${output} NAME)
    add_custom_target(generate_${output_name} DEPENDS ${output})
    add_dependencies(all_generated generate_${output_name})
endfunction()
