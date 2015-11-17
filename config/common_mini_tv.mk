# Inherit common crDroid stuff
$(call inherit-product, vendor/crdroid/config/common.mk)

# Include crDroid audio files
include vendor/crdroid/config/crdroid_audio.mk

# Default notification/alarm sounds
PRODUCT_PROPERTY_OVERRIDES += \
    ro.config.notification_sound=Ceres.ogg \
    ro.config.alarm_alert=Barium.ogg
