IMAGE_FSTYPES:prepend = "ext4 ext4.gz wic wic.zst "
IMAGE_INSTALL:append = " \
    stress-ng \
    rt-tests \
    util-linux \
    htop \
    swupdate \
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

IMAGE_INSTALL:append:beaglebone-yocto:imx8mpfrdm = " \
    zstd \
"

IMAGE_INSTALL:append = " e2fsprogs-resize2fs"

IMAGE_FSTYPES:remove:qemuarm = "wic wic.zst"
IMAGE_FSTYPES:remove:qemuarm64 = "wic wic.zst"
WKS_FILE:rock-5t = "generic-gptdisk.wks.in"
RK_ROOTFS_TYPE:rock-5t = "ext4"
RK_ROOTDEV_UUID:rock-5t = "614e0000-0000-4b53-8000-1d28000054a9"
RK_ROOTFS_EXTRAOPTS:rock-5t = "-F -i 8192 -b 4096"
