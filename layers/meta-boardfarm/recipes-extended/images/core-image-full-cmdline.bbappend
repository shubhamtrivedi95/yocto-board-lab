IMAGE_FSTYPES:prepend = "ext4 ext4.gz "
IMAGE_INSTALL:append = " \
    stress-ng \
    rt-tests \
    util-linux \
    htop \
"
QB_DEFAULT_FSTYPE = "ext4"
IMAGE_INSTALL:append:beagley-ai = " \
    cc33xx-fw \
    kernel-module-cc33xx \
    kernel-module-cc33xx-sdio \
    kernel-module-mac80211 \
    kernel-module-cfg80211 \
    iw \
    wpa-supplicant \
    wifi-firstboot \
"