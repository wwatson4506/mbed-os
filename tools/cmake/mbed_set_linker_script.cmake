# Copyright (c) 2021 ARM Limited. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

#
# Sets the linker script for an Mbed target.
# Called once by the buildscripts for each MCU target in the build system.
# Note: Linker script path may be absolute or relative.  If relative, it will be interpreted relative to the current source dir.
#
function(mbed_set_linker_script input_target raw_linker_script_path)

    # Make sure that we have an absolute path so that it can be used from a different directory
    get_filename_component(raw_linker_script_path ${raw_linker_script_path} ABSOLUTE)

    # Use a custom property to store the linker script.  This property will be read and passed up by mbed_create_distro()
    set_property(TARGET ${input_target} PROPERTY INTERFACE_MBED_LINKER_SCRIPT ${raw_linker_script_path})

endfunction(mbed_set_linker_script)


#
# Set up the linker script for the top-level Mbed OS targets.
# If needed, this also creates another target to preprocess the linker script.
#
# mbed_os_target: CMake target for Mbed OS
# mbed_baremetal_target: CMake target for Mbed Baremetal
# target_defines_header: the full path to the header containing all of the Mbed target defines
#
function(mbed_setup_linker_script mbed_os_target mbed_baremetal_target target_defines_header)

    # Find the path to the desired linker script
    # (the property should be set on both the OS and baremetal targets in a sane world)
    get_property(RAW_LINKER_SCRIPT_PATHS TARGET ${mbed_baremetal_target} PROPERTY INTERFACE_MBED_LINKER_SCRIPT)

    # Check if two (or more) different linker scripts got used
    list(REMOVE_DUPLICATES RAW_LINKER_SCRIPT_PATHS)
    list(LENGTH RAW_LINKER_SCRIPT_PATHS NUM_RAW_LINKER_SCRIPT_PATHS)
    if(NUM_RAW_LINKER_SCRIPT_PATHS GREATER 1)
        message(FATAL_ERROR "More than one linker script selected for the current MCU target.  Perhaps multiple targets with linker scripts set were linked together?")
    endif()

    # Make sure the linker script exists
    if(NOT EXISTS "${RAW_LINKER_SCRIPT_PATHS}")
        message(FATAL_ERROR "Selected linker script ${RAW_LINKER_SCRIPT_PATHS} does not exist!")
    endif()

    set(LINKER_SCRIPT_PATH ${CMAKE_BINARY_DIR}/${MBED_TARGET_CMAKE_NAME}.link_script.ld)

    # To avoid path limits on Windows, we create a "response file" and set the path to it as a
    # global property. We need this solely to pass the compile definitions to GCC's preprocessor,
    # so it can expand any macro definitions in the linker script.
    get_property(linker_defs_response_file GLOBAL PROPERTY COMPILE_DEFS_RESPONSE_FILE)

    get_filename_component(RAW_LINKER_SCRIPT_NAME ${RAW_LINKER_SCRIPT_PATHS} NAME)
    get_filename_component(LINKER_SCRIPT_NAME ${LINKER_SCRIPT_PATH} NAME)
    add_custom_command(
        OUTPUT
            ${LINKER_SCRIPT_PATH}
        PRE_LINK
        COMMAND
            ${CMAKE_C_COMPILER} @${linker_defs_response_file}
            -E -x assembler-with-cpp
            -include ${target_defines_header}
            -P ${RAW_LINKER_SCRIPT_PATHS}
            -o ${LINKER_SCRIPT_PATH}
        DEPENDS
            ${RAW_LINKER_SCRIPT_PATHS}
            ${linker_defs_response_file}
            ${target_defines_header}
        WORKING_DIRECTORY
            ${CMAKE_CURRENT_SOURCE_DIR}
        COMMENT
            "Preprocess linker script: ${RAW_LINKER_SCRIPT_NAME} -> ${LINKER_SCRIPT_NAME}"
        VERBATIM
    )

    
    # The job to create the linker script gets attached to the mbed-linker-script target,
    # which is then added as a dependency of the MCU target.  This ensures the linker script will exist
    # by the time we need it.
    add_custom_target(mbed-linker-script DEPENDS ${LINKER_SCRIPT_PATH} VERBATIM)
    foreach(TARGET ${mbed_baremetal_target} ${mbed_os_target})
        add_dependencies(${TARGET} mbed-linker-script)

        # store LINKER_SCRIPT_PATH
        set_target_properties(${TARGET} PROPERTIES LINKER_SCRIPT_PATH  ${LINKER_SCRIPT_PATH})

        # Add linker flags to the MCU target to pick up the preprocessed linker script
        target_link_options(${TARGET}
            INTERFACE
                "-T" "${LINKER_SCRIPT_PATH}"
        )
    endforeach()

endfunction(mbed_setup_linker_script)

#
# Removes the specified compile flag from the specified target.
#   _target     - The target to remove the compile flag from
#   _flag       - The compile flag to remove
#
# Pre: apply_global_cxx_flags_to_all_targets() must be invoked.
#
# modified: remove last two entries, ignoring flag
#
macro(remove_flag_from_target _target _flag)
    get_target_property(_target_cxx_flags ${_target} INTERFACE_LINK_OPTIONS)
    if(_target_cxx_flags)
        list(REMOVE_ITEM _target_cxx_flags ${_flag})
        set_target_properties(${_target} PROPERTIES INTERFACE_LINK_OPTIONS "${_target_cxx_flags}")
    endif()
endmacro()

#
# Change the linker script to a custom supplied script instead of the built in.
#
# target: CMake target for Mbed OS
# mbed_baremetal_target: CMake target for Mbed Baremetal
#
function(mbed_set_custom_linker_script target new_linker_script_path)

    set(RAW_LINKER_SCRIPT_PATHS  ${CMAKE_CURRENT_SOURCE_DIR}/${new_linker_script_path})
    set(CUSTOM_LINKER_SCRIPT_PATH ${CMAKE_CURRENT_BINARY_DIR}/${target}.link_spript.ld)

    message("*** mbed_set_custom_linker_script: "  ${RAW_LINKER_SCRIPT_PATHS} ": " ${CUSTOM_LINKER_SCRIPT_PATH})

    # To avoid path limits on Windows, we create a "response file" and set the path to it as a
    # global property. We need this solely to pass the compile definitions to GCC's preprocessor,
    # so it can expand any macro definitions in the linker script.
    get_property(linker_defs_response_file GLOBAL PROPERTY COMPILE_DEFS_RESPONSE_FILE)

    get_filename_component(RAW_LINKER_SCRIPT_NAME ${RAW_LINKER_SCRIPT_PATHS} NAME)
    get_filename_component(LINKER_SCRIPT_NAME ${CUSTOM_LINKER_SCRIPT_PATH} NAME)

    message("linker scipt name:  " ${LINKER_SCRIPT_NAME} ": " ${linker_defs_response_file})

    add_custom_command(
        TARGET
            ${target}
        PRE_LINK
        COMMAND
            ${CMAKE_C_COMPILER} @${linker_defs_response_file}
            -E -x assembler-with-cpp
            -include ${CMAKE_BINARY_DIR}/mbed-os/mbed-target-config.h
            -P ${RAW_LINKER_SCRIPT_PATHS}
            -o ${CUSTOM_LINKER_SCRIPT_PATH}
        DEPENDS
            ${RAW_LINKER_SCRIPT_PATHS}
            ${linker_defs_response_file}
            ${target_defines_header}
        WORKING_DIRECTORY
            ${CMAKE_CURRENT_SOURCE_DIR}
        COMMENT
            "Preprocess custom linker script: ${RAW_LINKER_SCRIPT_NAME} -> ${LINKER_SCRIPT_NAME}"
        VERBATIM
    )

    # The job to create the linker script gets attached to the mbed-linker-script target,
    # which is then added as a dependency of the MCU target.  This ensures the linker script will exist
    # by the time we need it.
    # foreach(TARGET mbed-baremetal mbed-os)
    #     # remove default linker script 
    #     get_target_property(linker_script_path ${TARGET} LINKER_SCRIPT_PATH)
    #     message("LINKER_SCRIPT_PATH: " ${linker_script_path})
    #     remove_flag_from_target(${TARGET} "-T")
    #     remove_flag_from_target(${TARGET} "${linker_script_path}")
    # endforeach()

    # Add linker flags to the MCU target to pick up the preprocessed linker script
    # add_custom_target(mbed-custom-linker-script DEPENDS ${CUSTOM_LINKER_SCRIPT_PATH} VERBATIM)
    # add_dependencies(${target} mbed-custom-linker-script)
    target_link_options(${target}
        PRIVATE
            "-T" "${CUSTOM_LINKER_SCRIPT_PATH}"
    )

    # print resulting link options
    get_target_property(INTERFACE_LINK_OPTIONS mbed-os-nolink INTERFACE_LINK_OPTIONS)
    message("INTERFACE_LINK_OPTIONS in mbed-os-nolink: " ${INTERFACE_LINK_OPTIONS})
    get_target_property(LINK_OPTIONS ${target} LINK_OPTIONS)
    message("LINK_OPTIONS in ${target}: " ${LINK_OPTIONS})


endfunction(mbed_set_custom_linker_script)
