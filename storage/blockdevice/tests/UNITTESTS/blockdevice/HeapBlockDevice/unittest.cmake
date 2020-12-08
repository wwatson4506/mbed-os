####################
# UNIT TESTS
####################

set(unittest-includes ${unittest-includes} . .. ../storage/blockdevice/include)

set(unittest-sources ../storage/blockdevice/source/HeapBlockDevice.cpp
                     stubs/mbed_atomic_stub.c stubs/mbed_assert_stub.cpp
)

set(unittest-test-sources ${CMAKE_CURRENT_LIST_DIR}/test.cpp)

set(unittest-test-flags
    -DMBED_CONF_FAT_CHAN_FFS_DBG=0
    -DMBED_CONF_FAT_CHAN_FF_FS_READONLY=0
    -DMBED_CONF_FAT_CHAN_FF_FS_MINIMIZE=0
    -DMBED_CONF_FAT_CHAN_FF_USE_STRFUNC=0
    -DMBED_CONF_FAT_CHAN_FF_USE_FIND=0
    -DMBED_CONF_FAT_CHAN_FF_USE_MKFS=1
    -DMBED_CONF_FAT_CHAN_FF_USE_FASTSEEK=0
    -DMBED_CONF_FAT_CHAN_FF_USE_EXPAND=0
    -DMBED_CONF_FAT_CHAN_FF_USE_CHMOD=0
    -DMBED_CONF_FAT_CHAN_FF_USE_LABEL=0
    -DMBED_CONF_FAT_CHAN_FF_USE_FORWARD=0
    -DMBED_CONF_FAT_CHAN_FF_CODE_PAGE=437
    -DMBED_CONF_FAT_CHAN_FF_USE_LFN=3
    -DMBED_CONF_FAT_CHAN_FF_MAX_LFN=255
    -DMBED_CONF_FAT_CHAN_FF_LFN_UNICODE=0
    -DMBED_CONF_FAT_CHAN_FF_LFN_BUF=255
    -DMBED_CONF_FAT_CHAN_FF_SFN_BUF=12
    -DMBED_CONF_FAT_CHAN_FF_STRF_ENCODE=3
    -DMBED_CONF_FAT_CHAN_FF_FS_RPATH=1
    -DMBED_CONF_FAT_CHAN_FF_VOLUMES=4
    -DMBED_CONF_FAT_CHAN_FF_STR_VOLUME_ID=0
    -DMBED_CONF_FAT_CHAN_FF_VOLUME_STRS=\"RAM\",\"NAND\",\"CF\",\"SD\",\"SD2\",\"USB\",\"USB2\",\"USB3\"
    -DMBED_CONF_FAT_CHAN_FF_MULTI_PARTITION=0
    -DMBED_CONF_FAT_CHAN_FF_MIN_SS=512
    -DMBED_CONF_FAT_CHAN_FF_MAX_SS=4096
    -DMBED_CONF_FAT_CHAN_FF_USE_TRIM=1
    -DMBED_CONF_FAT_CHAN_FF_FS_NOFSINFO=0
    -DMBED_CONF_FAT_CHAN_FF_FS_TINY=1
    -DMBED_CONF_FAT_CHAN_FF_FS_EXFAT=0
    -DMBED_CONF_FAT_CHAN_FF_FS_HEAPBUF=1
    -DMBED_CONF_FAT_CHAN_FF_FS_NORTC=0
    -DMBED_CONF_FAT_CHAN_FF_NORTC_MON=1
    -DMBED_CONF_FAT_CHAN_FF_NORTC_MDAY=1
    -DMBED_CONF_FAT_CHAN_FF_NORTC_YEAR=2017
    -DMBED_CONF_FAT_CHAN_FF_FS_LOCK=0
    -DMBED_CONF_FAT_CHAN_FF_FS_REENTRANT=0
    -DMBED_CONF_FAT_CHAN_FF_FS_TIMEOUT=1000
    -DMBED_CONF_FAT_CHAN_FF_SYNC_t=HANDLE
    -DMBED_CONF_FAT_CHAN_FLUSH_ON_NEW_CLUSTER=0
    -DMBED_CONF_FAT_CHAN_FLUSH_ON_NEW_SECTOR=1
)
