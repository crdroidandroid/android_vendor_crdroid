$(call inherit-product, vendor/crdroid/config/common_mini.mk)

# Required crDroid packages
PRODUCT_PACKAGES += \
    LatinIME

$(call inherit-product, vendor/crdroid/config/telephony.mk)

