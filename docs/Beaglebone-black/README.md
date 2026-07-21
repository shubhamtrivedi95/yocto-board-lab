# BeagleBone Black Board Documentation

## 1. Overview
- Board name: BeagleBone Black
- SoC / CPU: TI AM3358
- Vendor / reference design: BeagleBoard.org
- Use case: General-purpose embedded development and prototyping

## 2. Board Specifications
- Processor: TI AM3358 ARM Cortex-A8
- RAM: 512 MB DDR3
- Storage: 4 GB onboard eMMC (on supported variants) and microSD slot
- Connectivity: Ethernet, USB host/device, HDMI, UART serial, GPIO
- Power input: 5 V via barrel jack or USB
- Boot media: microSD card or onboard eMMC

## 3. Yocto / Build Setup
- Machine name: beaglebone-yocto
- Layers used: meta-yocto, meta-yocto-bsp, openembedded-core, meta-openembedded, meta-swupdate, meta-boardfarm
- Build command: kas shell kas/boards/bbb.yaml -c "bitbake -c cleanall core-image-full-cmdline && bitbake core-image-full-cmdline"
- Notes / custom configuration: Uses the Poky distro, targets core-image-full-cmdline, enables systemd, and applies build-history and root-login related configuration from the shared KAS settings

## 4. Flashing and Booting
- Image type: WIC-based SD/eMMC image produced for the beaglebone-yocto machine
- Flashing method: Write the generated .wic.bz2 or .sdimg image to a microSD card with dd or a flashing tool such as balenaEtcher
- Boot instructions: Insert the boot media, connect a serial console if needed, power on the board, and wait for U-Boot/Linux to boot
- Common issues: Incorrect boot media selection, failed image write, or lack of serial console access for debugging

## 5. Validation
- Status: Validated in this repository for core-image-full-cmdline
- Tested images: core-image-full-cmdline
- Validation notes: Built successfully with the provided KAS configuration and booted in the lab environment
- Known issues: Booting may require the correct media selection and console access for troubleshooting

## 6. References
- Vendor documentation: BeagleBoard.org BeagleBone Black documentation and booting guide
- Board support files: kas/boards/bbb.yaml, layers/meta-yocto/meta-yocto-bsp/conf/machine/beaglebone-yocto.conf, layers/meta-yocto/meta-yocto-bsp/wic/beaglebone-yocto.wks, layers/meta-yocto/meta-yocto-bsp/README.hardware.md
- Related notes / links: Repository build instructions in README.md

---

