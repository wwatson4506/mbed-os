# Copyright (c) 2020 ARM Limited. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

### OpenOCD Upload Method
# This method needs the following parameters:
# OPENOCD_CHIP_CONFIG_COMMANDS - Specifies all OpenOCD commands needed to configure openocd for your target processor.
# This method creates the following options:
# OPENOCD_ADAPTER_SERIAL - Serial number of the debug adapter to select for OpenOCD.  Set to empty to detect any matching adapter.

set(UPLOAD_SUPPORTS_DEBUG TRUE)

### Check if upload method can be enabled on this machine
find_package(OpenOCD)
set(UPLOAD_OPENOCD_FOUND ${OpenOCD_FOUND})

### Setup options
set(OPENOCD_ADAPTER_SERIAL "" CACHE STRING "Serial number of the debug adapter to select for OpenOCD.  Set to empty to detect any matching adapter.")

### Function to generate upload target
set(OPENOCD_ADAPTER_SERIAL_COMMAND "" CACHE INTERNAL "" FORCE)
if(NOT "${OPENOCD_ADAPTER_SERIAL}" STREQUAL "")

	# Generate script file that tells OpenOCD how to find the correct debug adapter.
	file(GENERATE OUTPUT ${CMAKE_BINARY_DIR}/openocd_adapter_config.cfg CONTENT
"# Script to select the correct debug adapter with OpenOCD.
# This file is generated by UploadMethodOPENOCD.cmake.  Your edits will be overwritten.

# There's supposed to be a standard command to select the adapter serial ('adapter serial'), but it seems
# like not all adapters support this yet so extra work is needed.
set adapter_serial \"${OPENOCD_ADAPTER_SERIAL}\"
if { [adapter name] == \"hla\" } {
	hla_serial $adapter_serial
} elseif { [adapter name] == \"cmsis-dap\" } {
	cmsis_dap_serial $adapter_serial
} else {
	adapter serial $adapter_serial
}")

	set(OPENOCD_ADAPTER_SERIAL_COMMAND -f ${CMAKE_BINARY_DIR}/openocd_adapter_config.cfg CACHE INTERNAL "" FORCE)
endif()

function(gen_upload_target TARGET_NAME BIN_FILE)

	# unlike other upload methods, OpenOCD uses the elf file
	add_custom_target(flash-${TARGET_NAME}
		COMMENT "Flashing ${TARGET_NAME} with OpenOCD..."
		COMMAND ${OpenOCD}
		${OPENOCD_CHIP_CONFIG_COMMANDS}
		${OPENOCD_ADAPTER_SERIAL_COMMAND}
		-c "program $<TARGET_FILE:${TARGET_NAME}> reset exit"
		VERBATIM)

	add_dependencies(flash-${TARGET_NAME} ${TARGET_NAME})
endfunction(gen_upload_target)

### Commands to run the debug server.
set(UPLOAD_GDBSERVER_DEBUG_COMMAND
	${OpenOCD}
	${OPENOCD_CHIP_CONFIG_COMMANDS}
	${OPENOCD_ADAPTER_SERIAL_COMMAND}
	# Shut down OpenOCD when GDB disconnects.
	# see https://github.com/Marus/cortex-debug/issues/371#issuecomment-999727626
	-c "[target current] configure -event gdb-detach {shutdown}"
	-c "gdb_port ${GDB_PORT}")

# request extended-remote GDB sessions
set(UPLOAD_WANTS_EXTENDED_REMOTE TRUE)

# Reference: https://github.com/Marus/cortex-debug/blob/056c03f01e008828e6527c571ef5c9adaf64083f/src/openocd.ts#L100
set(UPLOAD_LAUNCH_COMMANDS
	"monitor reset halt"
	"load"
	"break main"
	"monitor reset halt"
)
set(UPLOAD_RESTART_COMMANDS
	"monitor reset halt"

	# The following will force an sync between gdb and openocd
	"monitor gdb_sync"
	"stepi"
)