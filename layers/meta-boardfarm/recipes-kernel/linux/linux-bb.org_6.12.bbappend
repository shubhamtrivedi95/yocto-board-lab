FILESEXTRAPATHS:append := "${THISDIR}/${PN}:"
SRC_URI:append = " file://fan.cfg"

KERNEL_CONFIG_FRAGMENTS:append = " ${UNPACKDIR}/fan.cfg"