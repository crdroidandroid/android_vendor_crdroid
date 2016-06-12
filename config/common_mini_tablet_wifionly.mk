# Inherit common crDroid stuff
$(call inherit-product, vendor/crdroid/config/common_mini.mk)

# Required crDroid packages
PRODUCT_PACKAGES += \
    LatinIME

