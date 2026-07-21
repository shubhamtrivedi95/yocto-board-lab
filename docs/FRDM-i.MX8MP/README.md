```md
# FRDM i.MX8M Plus Board Documentation

## 1. Overview
- Board name: FRDM i.MX8M Plus
- SoC / CPU: NXP i.MX 8M Plus
- Vendor / reference design: NXP Freedom development board
- Use case: Embedded Linux development, connectivity, and multimedia evaluation

## 2. Board Specifications
- Processor: NXP i.MX 8M Plus application processor
- RAM: Board-specific LPDDR4 memory on the FRDM reference design
- Storage: eMMC/SD storage options depending on configuration
- Connectivity: Ethernet, USB, Wi-Fi/Bluetooth depending on add-ons, GPIO, I2C/SPI/UART
- Power input: Standard development-board power input
- Boot media: SD card or onboard storage

## 3. Yocto / Build Setup
- Machine name: imx8mpfrdm
- Layers used: meta-freescale, meta-openembedded, and the shared Yocto layers from common.yaml
- Build command: kas shell kas/boards/frdm-imx8mp.yaml -c "bitbake -c cleanall core-image-full-cmdline && bitbake core-image-full-cmdline"
- Notes / custom configuration: Uses the Poky distro and the shared local configuration from the board YAML. The machine configuration is based on the NXP FRDM reference files for imx8mpfrdm.conf and imx8mp-lpddr4-frdm.conf, adapted for compatibility with Yocto Wrynose.

## 4. Flashing and Booting
- Image type: core-image-full-cmdline for the imx8mpfrdm machine
- Flashing method: Write the generated image to an SD card or internal storage using the board’s supported flashing path
- Boot instructions: Insert boot media, power on the board, and use the serial console if necessary for troubleshooting
- Common issues: Boot device selection and flashing errors on the target storage medium

## 5. Validation
- Status: core-image-full-cmdline was generated successfully and booted successfully
- Tested images: core-image-full-cmdline
- Validation notes: Boot logs are available under the Validation/FRDM-i.MX8MP directory. The boot log shows U-Boot bringing up Linux on the NXP FRDM i.MX8M Plus platform with the kernel booting successfully.
- Known issues: None noted from the verified boot session

## 6. References
- Vendor documentation: [NXP FRDM i.MX8M Plus quick reference and board documentation](https://www.nxp.com/docs/en/quick-reference-guide/FRDMIMX8MPLUSQSG.pdf)
- Board support files: kas/boards/frdm-imx8mp.yaml, layers/meta-boardfarm/conf/machine/imx8mpfrdm.conf, layers/meta-freescale
- Related notes / links: Repository build instructions in README.md and validation logs in Validation/FRDM-i.MX8MP
```

