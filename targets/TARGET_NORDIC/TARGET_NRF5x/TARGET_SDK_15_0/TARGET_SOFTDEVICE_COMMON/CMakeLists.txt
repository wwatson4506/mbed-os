# Copyright (c) 2020 ARM Limited. All rights reserved.
# SPDX-License-Identifier: Apache-2.0


target_include_directories(mbed-base-flags
    INTERFACE
        ./ble
        ./ble/ble_radio_notification
        ./libraries/bootloader
        ./libraries/bootloader/dfu
        ./libraries/fstorage
)

target_sources(mbed-baremetal-obj PRIVATE
        ble/ble_radio_notification/ble_radio_notification.c

        libraries/bootloader/dfu/nrf_dfu_mbr.c

        libraries/fstorage/nrf_fstorage_sd.c
)
