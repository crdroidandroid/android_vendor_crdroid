#
# This policy configuration will be used by all products that
# inherit from CRDROID
#

BOARD_SEPOLICY_DIRS += \
    vendor/crdroid/sepolicy

BOARD_SEPOLICY_UNION += \
    file.te \
    file_contexts \
    fs_use \
    genfs_contexts \
    seapp_contexts \
    installd.te \
    netd.te \
    system.te \
    ueventd.te \
    vold.te \
    mac_permissions.xml
