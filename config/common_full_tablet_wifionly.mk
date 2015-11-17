# Inherit common crDroid stuff
$(call inherit-product, vendor/crdroid/config/common_full.mk)

# Required crDroid packages
PRODUCT_PACKAGES += \
    LatinIME

# Include crDroid LatinIME dictionaries
PRODUCT_PACKAGE_OVERLAYS += vendor/crdroid/overlay/dictionaries

# Default notification/alarm sounds
PRODUCT_PROPERTY_OVERRIDES += \
    ro.config.notification_sound=Ceres.ogg \
    ro.config.alarm_alert=Barium.ogg
