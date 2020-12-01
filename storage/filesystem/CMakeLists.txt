# Copyright (c) 2020 ARM Limited. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

add_subdirectory(fat)
add_subdirectory(littlefs)
add_subdirectory(littlefsv2)

target_include_directories(mbed-storage-filesystem
    PUBLIC
        .
        ./include
        ./include/filesystem
)

target_sources(mbed-storage-filesystem
    PRIVATE
        source/Dir.cpp
        source/File.cpp
        source/FileSystem.cpp
)

target_link_libraries(mbed-storage-filesystem
	PUBLIC
	mbed-base-flags
	mbed-storage-blockdevice
	)
