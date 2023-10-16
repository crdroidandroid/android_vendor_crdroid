# Inherit common Lineage stuff
$(call inherit-product, vendor/lineage/config/common_mobile.mk)

PRODUCT_SIZE := full

# Apps
PRODUCT_PACKAGES += \
    Eleven \
    Etar \
    Profiles \
    Recorder \
    Seedvault

ifneq ($(PRODUCT_NO_CAMERA),true)
PRODUCT_PACKAGES += \
    Aperture
endif

ifneq ($(TARGET_EXCLUDES_AUDIOFX),true)
PRODUCT_PACKAGES += \
    AudioFX
endif

# Extra cmdline tools
PRODUCT_PACKAGES += \
    unrar \
    zstd

# Include Lineage LatinIME dictionaries
PRODUCT_PACKAGE_OVERLAYS += vendor/lineage/overlay/dictionaries
PRODUCT_ENFORCE_RRO_EXCLUDED_OVERLAYS += vendor/lineage/overlay/dictionaries
