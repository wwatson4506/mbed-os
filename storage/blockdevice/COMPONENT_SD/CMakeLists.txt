# Copyright (c) 2020 ARM Limited. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

target_sources(mbed-storage-sd
    PRIVATE
        source/SDBlockDevice.cpp
)

target_include_directories(mbed-storage-sd
    PUBLIC
        include
        include/SD
)
