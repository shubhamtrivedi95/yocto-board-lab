```md
# BeagleY-AI Board Documentation

## 1. Overview
- Board name: BeagleY-AI
- SoC / CPU: Texas Instruments AM67A (Arm Cortex-A53 + Cortex-R5F)
- Vendor / reference design: BeagleBoard.org
- Use case: Embedded Linux development, AI/ML experimentation, and general-purpose prototyping

## 2. Board Specifications
- Processor: TI AM67A SoC with Arm Cortex-A53 and Cortex-R5F cores
- RAM: Board-specific LPDDR4 memory (reference design)
- Storage: microSD or NVMe base memory options
- Connectivity: Ethernet, USB, HDMI, GPIO, I2C/SPI/UART interfaces
- Power input: 5 V supply via board power input
- Boot media: microSD card or NVMe SSD

## 3. Yocto / Build Setup
- Machine name: beagley-ai
- Layers used: meta-ti, meta-arago, meta-openembedded, meta-virtualization, meta-clang, meta-lts-mixins
- Build command: kas shell kas/boards/beagley-ai.yaml -c "bitbake -c cleanall arago-base-image && bitbake arago-base-image"
- Notes / custom configuration: Uses the Arago distro and the arago-base-image target with TI-specific layer support

## 4. Flashing and Booting
- Image type: Arago-based bootable image for the beagley-ai machine
- Flashing method: Write the generated image to a microSD card using dd or a standard imaging tool
- Boot instructions: Insert the boot media, connect serial/console access if needed, and power on the board
- Common issues: Boot media selection issues and missing console access for early boot debugging

## 5. Validation
- Status: Successfully built and booted from the image generated from this repository; AI validation is still pending
- Tested images: arago-base-image
- Validation notes: The main repository status matrix marks this board as successfully booted with AI validation pending
- Known issues: Additional AI-focused validation remains to be completed

## 6. References
- Vendor documentation: BeagleBoard.org BeagleY-AI documentation and TI BSP references
- Board support files: kas/boards/beagley-ai.yaml, layers/meta-ti/meta-beagle/conf/machine/beagley-ai.conf, layers/meta-arago
- Related notes / links: Repository build instructions in README.md
```

