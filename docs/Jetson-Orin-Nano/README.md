# NVIDIA Jetson Orin Nano Board Documentation

## 1. Overview
- Board name: NVIDIA Jetson Orin Nano DevKit
- SoC / CPU: NVIDIA Jetson Orin Nano
- Vendor / reference design: NVIDIA
- Use case: Embedded AI/vision platforms, Linux development, and edge computing

## 2. Board Specifications
- Processor: NVIDIA Ampere-based Jetson Orin Nano SoC
- RAM: Board-specific LPDDR5 memory
- Storage: NVMe SSD or microSD depending on carrier and configuration
- Connectivity: USB, Ethernet, HDMI, GPIO, PCIe, camera interfaces
- Power input: 19 V supply via devkit power input
- Boot media: NVMe or SD card depending on configuration

## 3. Yocto / Build Setup
- Machine name: jetson-orin-nano-devkit
- Layers used: meta-tegra, tegra-demo-distro, meta-tegra-community, meta-openembedded
- Build command: kas shell kas/boards/jetson-orin-nano.yaml -c "bitbake demo-image-base"
- Notes / custom configuration: Uses the tegrademo distro and the shared tegra-specific local configuration

## 4. Flashing and Booting
- Image type: demo-image-base for the Jetson Orin Nano devkit
- Flashing method: Flash the generated image by following NVIDIA’s Jetson flashing procedure for the target storage device
- Boot instructions: Power the board with the supported supply, boot from the programmed storage device, and monitor the serial console if needed
- Common issues: Power supply issues, flashing errors, and boot selection mismatches

## 5. Validation
- Status: Build completed successfully; boot validation is still pending
- Tested images: demo-image-base
- Validation notes: The main repository status matrix lists this board as having a completed image build with boot-up still pending
- Known issues: Runtime boot validation remains outstanding

## 6. References
- Vendor documentation: NVIDIA Jetson Orin Nano developer documentation
- Board support files: kas/boards/jetson-orin-nano.yaml, layers/meta-tegra, layers/tegra-demo-distro
- Related notes / links: Repository build instructions in README.md

