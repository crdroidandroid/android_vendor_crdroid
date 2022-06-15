# Additional props
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    ro.error.receiver.system.apps=com.google.android.gms \
    ro.atrace.core.services=com.google.android.gms,com.google.android.gms.ui,com.google.android.gms.persistent \
    ro.com.google.ime.theme_id=5 \
    drm.service.enabled=true \
    media.mediadrmservice.enable=true \
    persist.sys.disable_rescue=true \
    ro.opa.eligible_device=true

# Setupwizard
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    ro.setupwizard.enterprise_mode=1 \
    ro.setupwizard.esim_cid_ignore=00000001 \
    ro.setupwizard.rotation_locked=true \
    setupwizard.feature.baseline_setupwizard_enabled=true \
    setupwizard.feature.day_night_mode_enabled=true \
    setupwizard.feature.lifecycle_refactoring=true \
    setupwizard.feature.notification_refactoring=true \
    setupwizard.feature.portal_notification=true \
    setupwizard.feature.show_pai_screen_in_main_flow.carrier1839=false \
    setupwizard.feature.show_pixel_tos=true \
    setupwizard.feature.show_support_link_in_deferred_setup=false \
    setupwizard.feature.skip_button_use_mobile_data.carrier1839=true \
    setupwizard.theme=glif_v3_light

# Disable touch video heatmap to reduce latency, motion jitter, and CPU usage
# on supported devices with Deep Press input classifier HALs and models
PRODUCT_PRODUCT_PROPERTIES += \
    ro.input.video_enabled=false

# Blurs
ifeq ($(TARGET_ENABLE_BLUR), true)
PRODUCT_SYSTEM_EXT_PROPERTIES += \
    ro.sf.blurs_are_expensive=1 \
    ro.surface_flinger.supports_background_blur=1 \
    ro.launcher.blur.appLaunch=0
endif

# Disable async MTE on system_server
PRODUCT_SYSTEM_EXT_PROPERTIES += \
    arm64.memtag.process.system_server=off

# Enable dex2oat64 to do dexopt
PRODUCT_SYSTEM_EXT_PROPERTIES += \
    dalvik.vm.dex2oat64.enabled=true

# Extra packages
PRODUCT_PACKAGES += \
    GameSpace \
    MatLog
