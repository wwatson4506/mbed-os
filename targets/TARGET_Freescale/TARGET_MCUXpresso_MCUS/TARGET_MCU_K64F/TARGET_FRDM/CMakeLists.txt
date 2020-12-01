# SPDX-License-Identifier: Apache-2.0

target_sources(mbed-baremetal-obj PRIVATE
        crc.c
        fsl_clock_config.c
        fsl_phy.c
        mbed_overrides.c
        PeripheralPins.c
)

target_include_directories(mbed-base-flags
    INTERFACE
        .
)
