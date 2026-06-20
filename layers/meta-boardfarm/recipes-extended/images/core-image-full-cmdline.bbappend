IMAGE_FSTYPES:prepend = "ext4 ext4.gz "
IMAGE_INSTALL:append = " \
    stress-ng \
    rt-tests \
    util-linux \
    htop \
"
QB_DEFAULT_FSTYPE = "ext4"