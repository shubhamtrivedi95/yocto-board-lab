# Raspberry Pi 5 Board Documentation

## 1. Overview
- Board name: Raspberry Pi 5
- SoC / CPU: Broadcom BCM2712 (Arm Cortex-A76)
- Vendor / reference design: Raspberry Pi Foundation
- Use case: General-purpose Linux development, HMI, and embedded prototyping

## 2. Board Specifications
- Processor: Broadcom BCM2712 with Arm Cortex-A76 cores
- RAM: Board-specific LPDDR4X memory
- Storage: microSD card, USB storage, or NVMe via supported add-ons
- Connectivity: Wi-Fi, Bluetooth, Ethernet, USB 3, HDMI, GPIO
- Power input: 5 V via USB-C power input
- Boot media: microSD card or USB/NVMe storage

## 3. Yocto / Build Setup
- Machine name: raspberrypi5
- Layers used: meta-raspberrypi and the shared Yocto layers from common.yaml
- Build command: ./run-kas.sh shell kas/boards/rpi5.yaml -c "bitbake -c cleanall core-image-full-cmdline && bitbake core-image-full-cmdline"
- Notes / custom configuration: Uses the Poky distro and the Raspberry Pi BSP layer for the Pi 5 machine

## 4. Flashing and Booting
- Image type: core-image-full-cmdline
- Flashing method: Write the generated image to a microSD card or bootable storage media using a standard imaging tool
- Boot instructions: Insert the boot media, connect power, and boot the board from the prepared storage device
- Common issues: Power supply issues and incorrect boot-media selection

## 5. Validation
- Status: Successfully booted the core-image-full-cmdline image generated from this repository
- Tested images: core-image-full-cmdline
- Validation notes: The main repository status matrix marks the Raspberry Pi 5 as successfully booted
- Known issues: None noted in the current status matrix

## 6. References
- Vendor documentation: Raspberry Pi documentation and booting guide
- Board support files: kas/boards/rpi5.yaml, layers/meta-raspberrypi
- Related notes / links: Repository build instructions in README.md

