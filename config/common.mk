PRODUCT_BRAND ?= crdroid

SUPERUSER_EMBEDDED := true
SUPERUSER_PACKAGE_PREFIX := com.android.settings.cyanogenmod.superuser

#ifneq ($(TARGET_SCREEN_WIDTH) $(TARGET_SCREEN_HEIGHT),$(space))
# determine the smaller dimension
#TARGET_BOOTANIMATION_SIZE := $(shell \
#  if [ $(TARGET_SCREEN_WIDTH) -lt $(TARGET_SCREEN_HEIGHT) ]; then \
#    echo $(TARGET_SCREEN_WIDTH); \
#  else \
#    echo $(TARGET_SCREEN_HEIGHT); \
#  fi )

# get a sorted list of the sizes
#bootanimation_sizes := $(subst .zip,, $(shell ls vendor/crdroid/prebuilt/common/bootanimation))
#bootanimation_sizes := $(shell echo -e $(subst $(space),'\n',$(bootanimation_sizes)) | sort -rn)

# find the appropriate size and set
#define check_and_set_bootanimation
#$(eval TARGET_BOOTANIMATION_NAME := $(shell \
#  if [ -z "$(TARGET_BOOTANIMATION_NAME)" ]; then
#    if [ $(1) -le $(TARGET_BOOTANIMATION_SIZE) ]; then \
#      echo $(1); \
#      exit 0; \
#    fi;
#  fi;
#  echo $(TARGET_BOOTANIMATION_NAME); ))
#endef
#$(foreach size,$(bootanimation_sizes), $(call check_and_set_bootanimation,$(size)))

#ifeq ($(TARGET_BOOTANIMATION_HALF_RES),true)
#PRODUCT_BOOTANIMATION := vendor/crdroid/prebuilt/common/bootanimation/halfres/$(TARGET_BOOTANIMATION_NAME).zip
#else
#PRODUCT_BOOTANIMATION := vendor/crdroid/prebuilt/common/bootanimation/$(TARGET_BOOTANIMATION_NAME).zip
#endif
#endif

# temp crDroid global bootanimation
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

# Disable multithreaded dexopt by default
PRODUCT_PROPERTY_OVERRIDES += \
    persist.sys.dalvik.multithread=false

# Thank you, please drive thru!
PRODUCT_PROPERTY_OVERRIDES += persist.sys.dun.override=0

ifneq ($(TARGET_BUILD_VARIANT),eng)
# Enable ADB authentication
ADDITIONAL_DEFAULT_PROPERTIES += ro.adb.secure=1
endif

# Backup Tool
ifneq ($(WITH_GMS),true)
PRODUCT_COPY_FILES += \
    vendor/crdroid/prebuilt/common/bin/backuptool.sh:system/bin/backuptool.sh \
    vendor/crdroid/prebuilt/common/bin/backuptool.functions:system/bin/backuptool.functions \
    vendor/crdroid/prebuilt/common/bin/50-crdroid.sh:system/addon.d/50-crdroid.sh \
    vendor/crdroid/prebuilt/common/bin/blacklist:system/addon.d/blacklist
endif

# Signature compatibility validation
PRODUCT_COPY_FILES += \
    vendor/crdroid/prebuilt/common/bin/otasigcheck.sh:system/bin/otasigcheck.sh

# init.d support
PRODUCT_COPY_FILES += \
    vendor/crdroid/prebuilt/common/etc/init.d/00banner:system/etc/init.d/00banner \
    vendor/crdroid/prebuilt/common/bin/sysinit:system/bin/sysinit

# userinit support
PRODUCT_COPY_FILES += \
    vendor/crdroid/prebuilt/common/etc/init.d/90userinit:system/etc/init.d/90userinit

# CRDROID-specific init file
PRODUCT_COPY_FILES += \
    vendor/crdroid/prebuilt/common/etc/init.local.rc:root/init.crdroid.rc

# Bring in camera effects
PRODUCT_COPY_FILES +=  \
    vendor/crdroid/prebuilt/common/media/LMprec_508.emd:system/media/LMprec_508.emd \
    vendor/crdroid/prebuilt/common/media/PFFprec_600.emd:system/media/PFFprec_600.emd

# Enable SIP+VoIP on all targets
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.software.sip.voip.xml:system/etc/permissions/android.software.sip.voip.xml

# Enable wireless Xbox 360 controller support
PRODUCT_COPY_FILES += \
    frameworks/base/data/keyboards/Vendor_045e_Product_028e.kl:system/usr/keylayout/Vendor_045e_Product_0719.kl

# This is CRDROID!
PRODUCT_COPY_FILES += \
    vendor/crdroid/config/permissions/com.crdroid.android.xml:system/etc/permissions/com.crdroid.android.xml

# T-Mobile theme engine
include vendor/crdroid/config/themes_common.mk

# Required CRDROID packages
PRODUCT_PACKAGES += \
    Development \
    LatinIME \
    BluetoothExt

# Optional CRDROID packages
PRODUCT_PACKAGES += \
    VoicePlus \
    Basic \
    libemoji

# ChameleonOS Screen recorder
PRODUCT_PACKAGES += \
    ScreenRecorder \
    libscreenrecorder

# Custom CRDROID packages
PRODUCT_PACKAGES += \
    Launcher3 \
    Trebuchet \
    DSPManager \
    libcyanogen-dsp \
    audio_effects.conf \
    Apollo \
    CMFileManager \
    LockClock \
    CMFota \
    CMAccount \
    CMHome

# CRDROID (from CM) Hardware Abstraction Framework
PRODUCT_PACKAGES += \
    org.cyanogenmod.hardware \
    org.cyanogenmod.hardware.xml

# Extra tools in CRDROID
PRODUCT_PACKAGES += \
    libsepol \
    openvpn \
    e2fsck \
    mke2fs \
    tune2fs \
    bash \
    nano \
    htop \
    powertop \
    lsof \
    mount.exfat \
    fsck.exfat \
    mkfs.exfat \
    mkfs.f2fs \
    fsck.f2fs \
    fibmap.f2fs \
    ntfsfix \
    ntfs-3g \
    gdbserver \
    micro_bench \
    oprofiled \
    sqlite3 \
    strace

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
    libstagefright_soft_ffmpegadec \
    libstagefright_soft_ffmpegvdec \
    libFFmpegExtractor \
    libnamparser

# These packages are excluded from user builds
ifneq ($(TARGET_BUILD_VARIANT),user)

PRODUCT_PACKAGES += \
    procmem \
    procrank \
    Superuser \
    su

# Terminal Emulator
PRODUCT_COPY_FILES +=  \
    vendor/crdroid/proprietary/Term.apk:system/app/Term/Term.apk \
    vendor/crdroid/proprietary/lib/armeabi/libjackpal-androidterm4.so:system/app/Term/lib/arm/libjackpal-androidterm4.so

# AdAway
#PRODUCT_COPY_FILES += \
#    vendor/crdroid/prebuilt/common/app/org.adaway.apk:system/app/org.adaway.apk

PRODUCT_PROPERTY_OVERRIDES += \
    persist.sys.root_access=3
else

PRODUCT_PROPERTY_OVERRIDES += \
    persist.sys.root_access=0

endif

PRODUCT_PACKAGE_OVERLAYS += vendor/crdroid/overlay/common

# version
CRDROID_RELEASE = false
CRDROID_VERSION_MAJOR = 5.0
CRDROID_VERSION_MINOR = 0

# release
ifeq ($(CRDROID_RELEASE),true)
    CRDROID_VERSION := crdroid-$(CRDROID_VERSION_MAJOR).$(CRDROID_VERSION_MINOR)-$MILESTONE-$(shell date -u +%Y%m%d)-$(CRDROID_BUILD)
else
    CRDROID_VERSION := crdroid-$(CRDROID_VERSION_MAJOR).$(CRDROID_VERSION_MINOR)-$(shell date -u +%Y%m%d)-$(CRDROID_BUILD)
endif

CRDROID_DISPLAY_VERSION := $(CRDROID_VERSION)

# statistics identity
PRODUCT_PROPERTY_OVERRIDES += \
    ro.crdroid.version=$(CRDROID_VERSION) \
    ro.modversion=$(CRDROID_VERSION)

PRODUCT_PROPERTY_OVERRIDES += \
  ro.crdroid.display.version=$(CRDROID_DISPLAY_VERSION)

# by default, do not update the recovery with system updates
PRODUCT_PROPERTY_OVERRIDES += persist.sys.recovery_update=false

-include $(WORKSPACE)/build_env/image-auto-bits.mk

-include vendor/cyngn/product.mk

$(call inherit-product-if-exists, vendor/extra/product.mk)
