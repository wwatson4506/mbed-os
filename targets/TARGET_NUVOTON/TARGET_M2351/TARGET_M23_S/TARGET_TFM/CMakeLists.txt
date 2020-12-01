# Copyright (c) 2020 ARM Limited. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

target_sources(mbed-baremetal-obj PRIVATE
        target_cfg.cpp
        spm_hal.c
)

target_include_directories(mbed-base-flags
    INTERFACE
        .
)
