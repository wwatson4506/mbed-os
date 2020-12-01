# Copyright (c) 2020 ARM Limited. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

target_include_directories(mbed-storage-kvstore
    PUBLIC
        .
        ./include
        ./include/securestore
)

target_sources(mbed-storage-kvstore
    PRIVATE
        source/SecureStore.cpp
)

target_link_libraries(mbed-storage-kvstore
	PUBLIC
	mbed-mbedtls)