# Inherit common CRDROID stuff
$(call inherit-product, vendor/crdroid/config/common.mk)

# Bring in all video files
$(call inherit-product, frameworks/base/data/videos/VideoPackage2.mk)

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
    PhotoPhase

PRODUCT_PACKAGES += \
    VideoEditor \
    libvideoeditor_jni \
    libvideoeditor_core \
    libvideoeditor_osal \
    libvideoeditor_videofilters \
    libvideoeditorplayer

# Extra tools in CDROID
PRODUCT_PACKAGES += \
    vim \
    zip \
    unrar
