# Product version should match Android version
PRODUCT_VERSION_MAJOR = 7
PRODUCT_VERSION_MINOR = 1.1

# Increase CR Version with each major release.
CR_VERSION := 2.4

LINEAGE_VERSION := crDroidAndroid-$(PRODUCT_VERSION_MAJOR).$(PRODUCT_VERSION_MINOR)-$(shell date -u +%Y%m%d)-$(CM_BUILD)-v$(CR_VERSION)
LINEAGE_DISPLAY_VERSION := crDroidAndroid-$(PRODUCT_VERSION_MAJOR).$(PRODUCT_VERSION_MINOR)-$(shell date -u +%Y%m%d)-v$(CR_VERSION)

PRODUCT_PROPERTY_OVERRIDES += \
  ro.crdroid.version=$(PRODUCT_VERSION_MAJOR).$(PRODUCT_VERSION_MINOR) \
  ro.modversion=$(LINEAGE_VERSION) \
  ro.cm.display.version=$(LINEAGE_VERSION)

# Don't compile SystemUITests
EXCLUDE_SYSTEMUI_TESTS := true
