# Product version should match Android version
PRODUCT_VERSION_MAJOR = 8
PRODUCT_VERSION_MINOR = 1

# Increase CR Version with each major release.
CR_VERSION := 4.1

LINEAGE_VERSION := crDroidAndroid-$(PRODUCT_VERSION_MAJOR).$(PRODUCT_VERSION_MINOR)-$(shell date -u +%Y%m%d)-$(LINEAGE_BUILD)-v$(CR_VERSION)
LINEAGE_DISPLAY_VERSION := crDroidAndroid-$(PRODUCT_VERSION_MAJOR).$(PRODUCT_VERSION_MINOR)-$(LINEAGE_BUILD)-v$(CR_VERSION)

# Do not edit. These values are parsed by OTA and Settings.
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    ro.crdroid.build.version=$(LINEAGE_VERSION) \
    ro.crdroid.display.version=$(LINEAGE_DISPLAY_VERSION) \
    ro.crdroid.version=$(PRODUCT_VERSION_MAJOR).$(PRODUCT_VERSION_MINOR) \
    ro.modversion=$(CR_VERSION)

# Additional props
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    ro.url.legal=http://www.google.com/intl/%s/mobile/android/basic/phone-legal.html \
    ro.url.legal.android_privacy=http://www.google.com/intl/%s/mobile/android/basic/privacy.html \
    ro.error.receiver.system.apps=com.google.android.gms \
    ro.setupwizard.enterprise_mode=1 \
    ro.com.android.dataroaming=false \
    ro.atrace.core.services=com.google.android.gms,com.google.android.gms.ui,com.google.android.gms.persistent \
    ro.setupwizard.rotation_locked=true \
    ro.com.google.ime.theme_id=5 \
    ro.storage_manager.enabled=1 \
    ro.opa.eligible_device=true \
    ro.com.android.wifi-watchlist=GoogleGuest \
    ro.setupwizard.network_required=false \
    ro.setupwizard.gservices_delay=-1 \
    drm.service.enabled=true \
    net.tethering.noprovisioning=true \
    persist.sys.dun.override=0 \
    keyguard.no_require_sim=true \
    persist.sys.disable_rescue=true

EXCLUDE_SYSTEMUI_TESTS := true

# Custom packages
PRODUCT_PACKAGES += \
    crDroidHome \
    crDroidMusic \
    crDroidWallpapers \
    OmniJaws \
    OmniStyle

# Additional themes
PRODUCT_PACKAGES += \
    crDroidHomeBlackTheme \
    crDroidHomeDarkTheme \
    SettingsBlackTheme \
    SettingsDarkTheme \
    SystemBlackTheme \
    SystemDarkTheme \
    SystemUIBlackTheme \
    SystemUIDarkTheme

# DU Utils Library
PRODUCT_BOOT_JARS += \
   org.dirtyunicorns.utils

PRODUCT_PACKAGES += \
   org.dirtyunicorns.utils

