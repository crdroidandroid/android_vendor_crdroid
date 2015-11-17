# Inherit common crDroid stuff
$(call inherit-product, vendor/crdroid/config/common_full.mk)

# Default notification/alarm sounds
PRODUCT_PROPERTY_OVERRIDES += \
    ro.config.notification_sound=Ceres.ogg \
    ro.config.alarm_alert=Barium.ogg
