```md
# Radxa Zero 3W Board Documentation

## 1. Overview
- Board name: Radxa Zero 3W
- SoC / CPU: Rockchip RK3566-class SoC
- Vendor / reference design: Radxa
- Use case: Compact embedded Linux development and low-cost prototyping

## 2. Board Specifications
- Processor: Rockchip RK3566-family SoC
- RAM: Board-specific memory configuration
- Storage: microSD and onboard storage options depending on board variant
- Connectivity: USB, Ethernet, Wi-Fi/Bluetooth depending on design, GPIO, serial interfaces
- Power input: Standard board power input
- Boot media: microSD card or onboard storage

## 3. Yocto / Build Setup
- Machine name: radxa-zero-3w
- Layers used: Shared Radxa support layers from kas/common/radxa-common.yaml
- Build command: kas shell kas/boards/radxa-zero-3w.yaml -c "bitbake -c cleanall core-image-full-cmdline && bitbake core-image-full-cmdline"
- Notes / custom configuration: Uses the Radxa common layer and is currently listed as in-progress support in the repository

## 4. Flashing and Booting
- Image type: core-image-full-cmdline
- Flashing method: Write the generated image to the boot media using a standard imaging tool
- Boot instructions: Boot from the prepared media and use the serial console for debugging if needed
- Common issues: Early bring-up and boot media selection issues

## 5. Validation
- Status: Board support is in progress
- Tested images: core-image-full-cmdline
- Validation notes: The main repository status matrix lists this board as having support work still in progress
- Known issues: Full validation and runtime bring-up remain pending

## 6. References
- Vendor documentation: Radxa Zero 3W documentation
- Board support files: kas/boards/radxa-zero-3w.yaml, kas/common/radxa-common.yaml
- Related notes / links: Repository build instructions in README.md
```

