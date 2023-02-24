# Copyright (c) 2022 ARM Limited. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

# Script to automatically generate debug configurations for various IDEs.

# Detect IDEs
# -------------------------------------------------------------

if("$ENV{CLION_IDE}" AND MBED_UPLOAD_SUPPORTS_DEBUG)
	message(STATUS "Mbed: Detected CLion IDE, will generate CLion debug configurations")
	set(MBED_GENERATE_CLION_DEBUG_CFGS TRUE)

	set(MBED_CLION_PROFILE_NAME "" CACHE STRING "Name of the Clion build profile (Settings > Build, Execution, Deployment > CMake > Name textbox")

	if(MBED_CLION_PROFILE_NAME STREQUAL "")
		message(FATAL_ERROR "In order to generate CLion configuration files, Mbed CE needs to know the name of the current CLion build profile.  This name is the string typed into the Name textbox under Settings > Build, Execution, Deployment > CMake.  Pass this name with '-DMBED_CLION_PROFILE_NAME=<name>'.")
	endif()

elseif(CMAKE_EXPORT_COMPILE_COMMANDS AND MBED_UPLOAD_SUPPORTS_DEBUG) # TODO: Is this actually a reliable way of detecting VS Code? Not sure if it will create false positives.
	message(STATUS "Mbed: Detected VS Code IDE, will generate VS Code debug configurations")
	set(MBED_GENERATE_VS_CODE_DEBUG_CFGS TRUE)

elseif(MBED_UPLOAD_SUPPORTS_DEBUG)
	message(STATUS "Mbed: No IDE detected, will generate configurations for command-line debugging (e.g. ninja gdbserver, then ninja debug-SomeProgram)")
endif()

# CLion generator
# -------------------------------------------------------------

if(MBED_GENERATE_CLION_DEBUG_CFGS)

	# Find CLion run config dir
	set(CLION_RUN_CONF_DIR ${CMAKE_SOURCE_DIR}/.idea/runConfigurations)
	file(MAKE_DIRECTORY ${CLION_RUN_CONF_DIR})

	function(mbed_generate_ide_debug_configuration CMAKE_TARGET)

		# Create name (combine target name, Mbed target, and build type to generate a unique string)
	    set(CONFIG_NAME "GDB ${CMAKE_TARGET} ${MBED_TARGET} ${CMAKE_BUILD_TYPE}")
	    set(RUN_CONF_PATH "${CLION_RUN_CONF_DIR}/${CONFIG_NAME}.xml")

		# Convert the CMake list into the correct format for the run configuration XML
		list(GET MBED_UPLOAD_GDBSERVER_DEBUG_COMMAND 0 GDBSERVER_EXECUTABLE)
		list(SUBLIST MBED_UPLOAD_GDBSERVER_DEBUG_COMMAND 1 -1 GDBSERVER_ARGS)
		set(GDBSERVER_ARGS_STR "")
		set(IS_FIRST_ARG TRUE)
		foreach(ELEMENT ${GDBSERVER_ARGS})

			if(IS_FIRST_ARG)
				set(IS_FIRST_ARG FALSE)
			else()
				string(APPEND GDBSERVER_ARGS_STR " ")
			endif()

			# Escape quotes and ampersands
			string(REPLACE "\"" "&quot;" ELEMENT "${ELEMENT}")
			string(REPLACE "&" "&amp;" ELEMENT "${ELEMENT}")

			if("${ELEMENT}" MATCHES " ")
				string(APPEND GDBSERVER_ARGS_STR "&quot;${ELEMENT}&quot;")
			else()
				string(APPEND GDBSERVER_ARGS_STR "${ELEMENT}")
			endif()
		endforeach()

		# Generate run configuration XML file.
		# This file is based on a generic Embedded GDB Server run configuration generated by CLion,
		# with constant strings replaced by placeholders for CMake.
	    file(GENERATE OUTPUT ${RUN_CONF_PATH} CONTENT
"<!-- Autogenerated by Mbed OS.  Do not edit! -->
<component name=\"ProjectRunConfigurationManager\">
  <configuration default=\"false\" name=\"${CONFIG_NAME}\" type=\"com.jetbrains.cidr.embedded.customgdbserver.type\" PROGRAM_PARAMS=\"${GDBSERVER_ARGS_STR}\" REDIRECT_INPUT=\"false\" ELEVATE=\"false\" USE_EXTERNAL_CONSOLE=\"false\" PASS_PARENT_ENVS_2=\"true\" PROJECT_NAME=\"${PROJECT_NAME}\" TARGET_NAME=\"${CMAKE_TARGET}\" CONFIG_NAME=\"${MBED_CLION_PROFILE_NAME}\" version=\"1\" RUN_TARGET_PROJECT_NAME=\"${PROJECT_NAME}\" RUN_TARGET_NAME=\"${CMAKE_TARGET}\">
    <custom-gdb-server version=\"1\" gdb-connect=\"localhost:${GDB_PORT}\" executable=\"${GDBSERVER_EXECUTABLE}\" warmup-ms=\"0\" download-type=\"UPDATED_ONLY\" reset-cmd=\"monitor reset\" reset-type=\"AFTER_DOWNLOAD\">
      <debugger kind=\"GDB\" isBundled=\"true\" />
    </custom-gdb-server>
    <method v=\"2\">
      <option name=\"CLION.COMPOUND.BUILD\" enabled=\"true\" />
    </method>
  </configuration>
</component>
")
	endfunction(mbed_generate_ide_debug_configuration)

	function(mbed_finalize_ide_debug_configurations)
		# Don't need to do anything
	endfunction(mbed_finalize_ide_debug_configurations)


# VS Code generator
# -------------------------------------------------------------
elseif(MBED_GENERATE_VS_CODE_DEBUG_CFGS)

	set(VSCODE_LAUNCH_JSON_PATH ${CMAKE_SOURCE_DIR}/.vscode/launch.json)

	# Start building up json file.  Needs to be a global property so we can append to it from anywhere.
	# Note: Cannot use a cache variable for this because cache variables aren't allowed to contain newlines.
	set_property(GLOBAL PROPERTY VSCODE_LAUNCH_JSON_CONTENT
"// Auto-generated by Mbed CE.  Edits will be erased when CMake is rerun.
{
    \"configurations\": [")

	set_property(GLOBAL PROPERTY VSCODE_TASKS_JSON_CONTENT
"// Auto-generated by Mbed CE.  Edits will be erased when CMake is rerun.
{
	\"version\": \"2.0.0\",
	\"tasks\": [")

	# Find objdump as the extension uses it.  In a sane world it should be in the compiler bin dir.
	find_program(MBED_OBJDUMP
		NAMES arm-none-eabi-objdump objdump
		HINTS ${CMAKE_COMPILER_BIN_DIR}
		DOC "Path to the GNU objdump program.  Needed for VS Code cortex-debug"
		REQURED)

	function(mbed_generate_ide_debug_configuration CMAKE_TARGET)

	    # Create name (combine target name, Mbed target, and build config to generate a unique string)
	    set(CONFIG_NAME "Debug ${CMAKE_TARGET} ${MBED_TARGET} ${CMAKE_BUILD_TYPE}")

		# Convert CMake lists to json
		list(JOIN MBED_UPLOAD_LAUNCH_COMMANDS "\", \"" UPLOAD_LAUNCH_COMMANDS_FOR_JSON)
		list(JOIN MBED_UPLOAD_RESTART_COMMANDS "\", \"" UPLOAD_RESTART_COMMANDS_FOR_JSON)

	    # property list here: https://github.com/Marus/cortex-debug/blob/master/debug_attributes.md
	    set_property(GLOBAL APPEND_STRING PROPERTY VSCODE_LAUNCH_JSON_CONTENT "
	// Debug launch for target ${CMAKE_TARGET}.
	{
	    \"type\": \"cortex-debug\",
	    \"name\": \"${CONFIG_NAME}\",
	    \"executable\": \"$<TARGET_FILE:${CMAKE_TARGET}>\",
	    \"cwd\": \"\${workspaceRoot}\",
	    \"gdbPath\": \"${MBED_GDB}\",
		\"objdumpPath\": \"${MBED_OBJDUMP}\",
		\"servertype\": \"external\",
		\"gdbTarget\": \"localhost:${GDB_PORT}\",
		\"request\": \"launch\",
		\"preLaunchTask\": \"Build ${CMAKE_TARGET} and start GDB server\",
		// Override the command sequences used by VS Code to be correct for this GDB server
		\"overrideLaunchCommands\": [\"${UPLOAD_LAUNCH_COMMANDS_FOR_JSON}\"],
		\"overrideRestartCommands\": [\"${UPLOAD_RESTART_COMMANDS_FOR_JSON}\"],
	},")

		# Add tasks to both build only, and build and start the GDB server.
		# Schema for tasks.json can be seen here https://code.visualstudio.com/docs/editor/tasks-appendix
		set_property(GLOBAL APPEND_STRING PROPERTY VSCODE_TASKS_JSON_CONTENT "
		// Build for target ${CMAKE_TARGET}
		{
			\"label\": \"Build ${CMAKE_TARGET}\",
			\"type\": \"shell\",
			\"command\": \"${CMAKE_COMMAND}\",
			\"args\": [\"--build\", \"${CMAKE_BINARY_DIR}\", \"--target\", \"${CMAKE_TARGET}\"],
		},
		// Build ${CMAKE_TARGET} and run the GDB server
		{
			\"label\": \"Build ${CMAKE_TARGET} and start GDB server\",
			\"dependsOn\": [\"Build ${CMAKE_TARGET}\", \"GDB Server\"],
			\"dependsOrder\": \"sequence\",
		},")

	endfunction(mbed_generate_ide_debug_configuration)

	# Take all generated debug configurations and write them to launch.json.
	function(mbed_finalize_ide_debug_configurations)


		# Add footer
	    set_property(GLOBAL APPEND_STRING PROPERTY VSCODE_LAUNCH_JSON_CONTENT "
    ]
}")

		get_property(VSCODE_LAUNCH_JSON_CONTENT GLOBAL PROPERTY VSCODE_LAUNCH_JSON_CONTENT)
	    file(GENERATE OUTPUT ${VSCODE_LAUNCH_JSON_PATH} CONTENT ${VSCODE_LAUNCH_JSON_CONTENT})

	
		# Convert the CMake list into the correct format for tasks.json
		list(GET MBED_UPLOAD_GDBSERVER_DEBUG_COMMAND 0 GDBSERVER_EXECUTABLE)
		list(SUBLIST MBED_UPLOAD_GDBSERVER_DEBUG_COMMAND 1 -1 GDBSERVER_ARGS)
		set(GDBSERVER_ARGS_STR "")
		set(IS_FIRST_ARG TRUE)
		foreach(ELEMENT ${GDBSERVER_ARGS})
		
			if(IS_FIRST_ARG)
				set(IS_FIRST_ARG FALSE)
			else()
				string(APPEND GDBSERVER_ARGS_STR ", ")
			endif()

			# Escape any quotes in the element
			string(REPLACE "\"" "\\\"" ELEMENT "${ELEMENT}")

			string(APPEND GDBSERVER_ARGS_STR "\"${ELEMENT}\"")
		endforeach()

		set_property(GLOBAL APPEND_STRING PROPERTY VSCODE_TASKS_JSON_CONTENT "
		{
			\"label\": \"GDB Server\",
			\"type\": \"shell\",
			\"command\": \"${GDBSERVER_EXECUTABLE}\",
			\"args\": [${GDBSERVER_ARGS_STR}],
			\"isBackground\": true,
			// This task is run to start the GDB server, so that the launch configuration can connect to it.
      		// Problem is, it's a GDB server, and since it never exits, VSCode
     	 	// will never start the debug session. All this is needed so VSCode just lets it run.
			\"problemMatcher\": [
				{
					\"pattern\": [
						{
							\"regexp\": \"________________\",
							\"file\": 1,
							\"location\": 2,
							\"message\": 3
						}
					],
					\"background\": {
						\"activeOnStart\": true,
						\"beginsPattern\": \".*\",
						\"endsPattern\": \".*\",
					}
				}
			],
		}
	]

}
	")

		# Write out tasks.json
		set(VSCODE_TASKS_JSON_PATH ${CMAKE_SOURCE_DIR}/.vscode/tasks.json)
		get_property(VSCODE_TASKS_JSON_CONTENT GLOBAL PROPERTY VSCODE_TASKS_JSON_CONTENT)
	    file(GENERATE OUTPUT ${VSCODE_TASKS_JSON_PATH} CONTENT ${VSCODE_TASKS_JSON_CONTENT})

	endfunction(mbed_finalize_ide_debug_configurations)

# Command-line generator
# -------------------------------------------------------------
elseif(MBED_UPLOAD_SUPPORTS_DEBUG)

	function(mbed_generate_ide_debug_configuration CMAKE_TARGET)

			# add debug target
			if(MBED_UPLOAD_SUPPORTS_DEBUG AND MBED_GDB_FOUND)
			add_custom_target(debug-${target}
				COMMENT "Starting GDB to debug ${target}..."
				COMMAND ${MBED_GDB}
				--command=${CMAKE_BINARY_DIR}/mbed-cmake.gdbinit
				$<TARGET_FILE:${target}>
				USES_TERMINAL)
			endif()

	endfunction(mbed_generate_ide_debug_configuration)

	function(mbed_finalize_ide_debug_configurations)

		# create init file for GDB client
		if(MBED_UPLOAD_WANTS_EXTENDED_REMOTE)
			set(UPLOAD_GDB_REMOTE_KEYWORD "extended-remote")
		else()
			set(UPLOAD_GDB_REMOTE_KEYWORD "remote")
		endif()

		list(JOIN MBED_UPLOAD_LAUNCH_COMMANDS "\n" MBED_UPLOAD_LAUNCH_COMMANDS_FOR_GDBINIT)

		file(GENERATE OUTPUT ${CMAKE_BINARY_DIR}/mbed-cmake.gdbinit CONTENT
"# connect to GDB server
target ${UPLOAD_GDB_REMOTE_KEYWORD} localhost:${GDB_PORT}
${MBED_UPLOAD_LAUNCH_COMMANDS_FOR_GDBINIT}
c"
)

		# Create target to start the GDB server
		add_custom_target(gdbserver
			COMMENT "Starting ${UPLOAD_METHOD} GDB server"
			COMMAND ${MBED_UPLOAD_GDBSERVER_DEBUG_COMMAND}
			USES_TERMINAL
			VERBATIM)
	endfunction(mbed_finalize_ide_debug_configurations)

else()

	# No-ops
	function(mbed_generate_ide_debug_configuration CMAKE_TARGET)
	endfunction()

	function(mbed_finalize_ide_debug_configurations)
	endfunction()

endif()