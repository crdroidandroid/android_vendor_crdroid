PRODUCT_BRAND ?= crdroidandroid

PRODUCT_BOOTANIMATION := vendor/crdroid/prebuilt/common/bootanimation/bootanimation.zip

PRODUCT_BUILD_PROP_OVERRIDES += BUILD_UTC_DATE=0

ifeq ($(PRODUCT_GMS_CLIENTID_BASE),)
PRODUCT_PROPERTY_OVERRIDES += \
    ro.com.google.clientidbase=android-google
else
PRODUCT_PROPERTY_OVERRIDES += \
    ro.com.google.clientidbase=$(PRODUCT_GMS_CLIENTID_BASE)
endif

PRODUCT_PROPERTY_OVERRIDES += \
    keyguard.no_require_sim=true \
    ro.url.legal=http://www.google.com/intl/%s/mobile/android/basic/phone-legal.html \
    ro.url.legal.android_privacy=http://www.google.com/intl/%s/mobile/android/basic/privacy.html \
    ro.com.android.wifi-watchlist=GoogleGuest \
    ro.setupwizard.enterprise_mode=1 \
    ro.com.android.dateformat=MM-dd-yyyy \
    ro.com.android.dataroaming=false

PRODUCT_PROPERTY_OVERRIDES += \
    ro.build.selinux=1

ifneq ($(TARGET_BUILD_VARIANT),user)
# Thank you, please drive thru!
PRODUCT_PROPERTY_OVERRIDES += persist.sys.dun.override=0
endif

ifneq ($(TARGET_BUILD_VARIANT),eng)
# Enable ADB authentication
ADDITIONAL_DEFAULT_PROPERTIES += ro.adb.secure=1
endif

# Backup Tool
ifneq ($(WITH_GMS),true)
PRODUCT_COPY_FILES += \
    vendor/crdroid/prebuilt/common/bin/backuptool.sh:install/bin/backuptool.sh \
    vendor/crdroid/prebuilt/common/bin/backuptool.functions:install/bin/backuptool.functions \
    vendor/crdroid/prebuilt/common/bin/50-crdroid.sh:system/addon.d/50-crdroid.sh \
    vendor/crdroid/prebuilt/common/bin/blacklist:system/addon.d/blacklist
endif

# Signature compatibility validation
PRODUCT_COPY_FILES += \
    vendor/crdroid/prebuilt/common/bin/otasigcheck.sh:install/bin/otasigcheck.sh

# init.d support
PRODUCT_COPY_FILES += \
    vendor/crdroid/prebuilt/common/etc/init.d/00banner:system/etc/init.d/00banner \
    vendor/crdroid/prebuilt/common/bin/sysinit:system/bin/sysinit

ifneq ($(TARGET_BUILD_VARIANT),user)
# userinit support
PRODUCT_COPY_FILES += \
    vendor/crdroid/prebuilt/common/etc/init.d/90userinit:system/etc/init.d/90userinit
endif

# crDroid-specific init file
PRODUCT_COPY_FILES += \
    vendor/crdroid/prebuilt/common/etc/init.local.rc:root/init.crdroid.rc

# crDroid Maintainers list
PRODUCT_COPY_FILES += \
    vendor/crdroid/Maintainers.txt:system/etc/Maintainers.txt

# Copy over added mimetype supported in libcore.net.MimeUtils
PRODUCT_COPY_FILES += \
    vendor/crdroid/prebuilt/common/lib/content-types.properties:system/lib/content-types.properties

# Enable SIP+VoIP on all targets
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.software.sip.voip.xml:system/etc/permissions/android.software.sip.voip.xml

# Enable wireless Xbox 360 controller support
PRODUCT_COPY_FILES += \
    frameworks/base/data/keyboards/Vendor_045e_Product_028e.kl:system/usr/keylayout/Vendor_045e_Product_0719.kl

# This is crDroid based on CyanogenMod!
PRODUCT_COPY_FILES += \
    vendor/crdroid/config/permissions/com.cyanogenmod.android.xml:system/etc/permissions/com.cyanogenmod.android.xml

# Live lockscreen
PRODUCT_COPY_FILES += \
    vendor/crdroid/config/permissions/org.cyanogenmod.livelockscreen.xml:system/etc/permissions/org.cyanogenmod.livelockscreen.xml

# Theme engine
include vendor/crdroid/config/themes_common.mk

# CMSDK
include vendor/crdroid/config/cmsdk_common.mk

# Required crDroid packages
PRODUCT_PACKAGES += \
    Development \
    BluetoothExt \
    Profiles

# Optional crDroid packages
PRODUCT_PACKAGES += \
    VoicePlus \
    Basic \
    libemoji \
    Terminal

# Include librsjni explicitly to workaround GMS issue
PRODUCT_PACKAGES += \
    librsjni

# Custom crDroid packages
PRODUCT_PACKAGES += \
    Launcher3 \
    Trebuchet \
    AudioFX \
    CMFileManager \
    Eleven \
    LockClock \
    CyanogenSetupWizard \
    CMSettingsProvider \
    ExactCalculator \
    LiveLockScreenService \
    WeatherProvider

# Exchange support
PRODUCT_PACKAGES += \
    Exchange2

# Extra tools in crDroid
PRODUCT_PACKAGES += \
    libsepol \
    mke2fs \
    tune2fs \
    nano \
    htop \
    mkfs.ntfs \
    fsck.ntfs \
    mount.ntfs \
    gdbserver \
    micro_bench \
    oprofiled \
    sqlite3 \
    strace \
    pigz

WITH_EXFAT ?= true
ifeq ($(WITH_EXFAT),true)
TARGET_USES_EXFAT := true
PRODUCT_PACKAGES += \
    mount.exfat \
    fsck.exfat \
    mkfs.exfat
endif

# OmniSwitch
PRODUCT_PACKAGES += \
    OmniSwitch

# Openssh
PRODUCT_PACKAGES += \
    scp \
    sftp \
    ssh \
    sshd \
    sshd_config \
    ssh-keygen \
    start-ssh

# rsync
PRODUCT_PACKAGES += \
    rsync

# Stagefright FFMPEG plugin
PRODUCT_PACKAGES += \
    libffmpeg_extractor \
    libffmpeg_omx \
    media_codecs_ffmpeg.xml

PRODUCT_PROPERTY_OVERRIDES += \
    media.sf.omx-plugin=libffmpeg_omx.so \
    media.sf.extractor-plugin=libffmpeg_extractor.so

# TCM (TCP Connection Management)
PRODUCT_PACKAGES += \
    tcmiface

PRODUCT_BOOT_JARS += \
    tcmiface

# These packages are excluded from user builds
ifneq ($(TARGET_BUILD_VARIANT),user)
PRODUCT_PACKAGES += \
    procmem \
    procrank \
    su
endif

PRODUCT_PROPERTY_OVERRIDES += \
    persist.sys.root_access=0

PRODUCT_PACKAGE_OVERLAYS += vendor/crdroid/overlay/common

# crDroid version
CRDROID_RELEASE = false
CRDROID_VERSION_MAJOR = 6.0
CRDROID_VERSION_MINOR = 1

# Release
ifeq ($(CRDROID_RELEASE),true)
    CRDROID_VERSION := crdroid-$(CRDROID_VERSION_MAJOR).$(CRDROID_VERSION_MINOR)-$MILESTONE-$(shell date -u +%Y%m%d)-$(CRDROID_BUILD)
else
    CRDROID_VERSION := crdroid-$(CRDROID_VERSION_MAJOR).$(CRDROID_VERSION_MINOR)-$(shell date -u +%Y%m%d)-$(CRDROID_BUILD)
endif

CRDROID_DISPLAY_VERSION := $(CRDROID_VERSION)

PRODUCT_PROPERTY_OVERRIDES += \
  ro.crdroid.version=$(CRDROID_VERSION) \
  ro.modversion=$(CRDROID_VERSION)

PRODUCT_PROPERTY_OVERRIDES += \
  ro.crdroid.display.version=$(CRDROID_DISPLAY_VERSION)

-include vendor/crdroid-priv/keys/keys.mk

-include $(WORKSPACE)/build_env/image-auto-bits.mk

-include vendor/cyngn/product.mk

$(call prepend-product-if-exists, vendor/extra/product.mk)
