# Copyright (c) 2020 ARM Limited. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

# This is a specific driver for the mbed-storage CMake target.
# TODO CMake: Perhaps move this/these file(s)
target_include_directories(mbed-device_key
    PUBLIC
        ./include
        ./include/device_key
)

target_sources(mbed-device_key
    PRIVATE
        source/DeviceKey.cpp
        ../source/SFDP.cpp
)

target_link_libraries(mbed-device_key
    PUBLIC
		mbed-base-flags
		mbed-mbedtls
)

# work around circular reference with kvstore (CMake doesn't allow object libraries to link circularly)
# Apply flags from kvstore and add an interface dependency on it so they will get linked together later.
target_link_libraries(mbed-device_key INTERFACE mbed-storage-kvstore)
target_compile_definitions(mbed-device_key PRIVATE $<TARGET_PROPERTY:mbed-storage-kvstore,COMPILE_DEFINITIONS>)
target_include_directories(mbed-device_key PRIVATE $<TARGET_PROPERTY:mbed-storage-kvstore,INCLUDE_DIRECTORIES>)