# Radxa Rock 5T Board Documentation

## 1. Overview
- Board name: Radxa Rock 5T
- SoC / CPU: Rockchip RK3588-class SoC
- Vendor / reference design: Radxa
- Use case: High-performance embedded Linux development and evaluation

## 2. Board Specifications
- Processor: Rockchip RK3588 / RK3588-class SoC
- RAM: Board-specific memory configuration
- Storage: eMMC/SD and NVMe-capable storage options depending on carrier
- Connectivity: USB, Ethernet, HDMI, PCIe, and other board interfaces
- Power input: Standard board power input
- Boot media: SD card or onboard storage

## 3. Yocto / Build Setup
- Machine name: rock-5b
- Layers used: Shared Radxa support layers from kas/common/radxa-common.yaml
- Build command: ./run-kas.sh shell kas/boards/radxa-rock-5t.yaml -c "bitbake -c cleanall core-image-full-cmdline && bitbake core-image-full-cmdline"
- Notes / custom configuration: The current board definition uses the Radxa common layer and reports a known kernel fragment warning during build validation

## 4. Flashing and Booting
- Image type: core-image-full-cmdline
- Flashing method: Write the generated image to the target boot media using standard imaging tools
- Boot instructions: Insert the prepared media and boot the board with the supported power and console setup
- Common issues: Kernel configuration warnings and boot media selection issues

## 5. Validation
- Status: Support is under evaluation
- Tested images: core-image-full-cmdline
- Validation notes: The main repository status matrix marks this board as being under evaluation for RK3588 support
- Known issues: Kernel configuration warnings are present in the current board definition

## 6. References
- Vendor documentation: Radxa Rock 5T documentation
- Board support files: kas/boards/radxa-rock-5t.yaml, kas/common/radxa-common.yaml
- Related notes / links: Repository build instructions in README.md

## 7. Boot-Up

Error message while booting from the SD card: [error](error.log)