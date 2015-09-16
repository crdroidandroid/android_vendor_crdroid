# Inherit common CRDROID stuff
$(call inherit-product, vendor/crdroid/config/common.mk)

# Include CRDROID audio files
include vendor/crdroid/config/crdroid_audio.mk

# Include CRDROID LatinIME dictionaries
PRODUCT_PACKAGE_OVERLAYS += vendor/crdroid/overlay/dictionaries

# Optional CRDROID packages
PRODUCT_PACKAGES += \
    Galaxy4 \
    HoloSpiralWallpaper \
    LiveWallpapers \
    LiveWallpapersPicker \
    MagicSmokeWallpapers \
    NoiseField \
    PhaseBeam \
    VisualizationWallpapers \
    PhotoTable \
    SoundRecorder \
    PhotoPhase \
    CMSettingsProvider \
    CMResolver

# Extra tools in CRDROID
PRODUCT_PACKAGES += \
    vim \
    zip \
    unrar \
    curl
