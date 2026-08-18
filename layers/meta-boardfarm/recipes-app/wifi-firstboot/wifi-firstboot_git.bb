SUMMARY = "WiFi first boot provisioning"
DESCRIPTION = "Configure WiFi on first boot"
LICENSE = "MIT"

LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"
PV = "1.0.0"
SRC_URI = "file://wifi-firstboot.sh"

S = "${UNPACKDIR}"

inherit allarch
RDEPENDS:${PN} = "wpa-supplicant systemd"
do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${S}/wifi-firstboot.sh \
        ${D}${bindir}/wifi-firstboot
}

FILES:${PN} += "${bindir}/wifi-firstboot"