# Copyright (c) 2020 ARM Limited. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

target_include_directories(mbed-storage-kvstore
    PUBLIC
        .
        ./include
        ./include/direct_access_devicekey
)

target_sources(mbed-storage-kvstore
    PRIVATE
        source/DirectAccessDevicekey.cpp
)
