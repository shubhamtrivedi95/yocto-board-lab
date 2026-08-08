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
- Build command: ./run-kas.sh shell kas/boards/frdm-imx8mp.yaml -c "bitbake -c cleanall core-image-full-cmdline && bitbake core-image-full-cmdline"
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


## 7. Flashing and SD boot recovery

This section explains how to flash the built FRDM i.MX8M Plus image to a microSD card and how to optionally program the onboard eMMC.

### 7.1 Locate the built image

After a successful build the artifacts are under:

```bash
build/boardfarm/images/imx8mpfrdm/
```

Key files:

- `core-image-full-cmdline-imx8mpfrdm.rootfs.wic.zst`
- `core-image-full-cmdline-imx8mpfrdm.rootfs.wic.bmap`

Prefer using `bmaptool` with the `.bmap` file when available — it writes only used blocks and is faster.

### 7.2 Identify the host SD card device

Attach the microSD card to your host and discover the device path:

```bash
sudo dmesg | tail -n 20
lsblk
```

Note the new block device (for example `/dev/sdX`). Double-check the device path before writing — writing to the wrong device will destroy data.

### 7.3 Flash the microSD card (recommended: `bmaptool`)

From the workspace root:

```bash
pushd build/boardfarm/images/imx8mpfrdm
sudo bmaptool copy --bmap core-image-full-cmdline-imx8mpfrdm.rootfs.wic.bmap core-image-full-cmdline-imx8mpfrdm.rootfs.wic.zst /dev/sdX
sudo sync
popd
```

- Replace `/dev/sdX` with the correct device for your SD card.
- `bmaptool copy` uses the `.bmap` to speed up and minimize writes.

Fallback (if `bmaptool` is not available):

```bash
pushd build/boardfarm/images/imx8mpfrdm
zstd -dc core-image-full-cmdline-imx8mpfrdm.rootfs.wic.zst | sudo dd of=/dev/sdX bs=4M conv=fsync status=progress
sudo sync
popd
```

### 7.4 Boot from microSD

Insert the flashed microSD card into the board, set the boot-mode switches to boot from SD Card, and power on. See the FRDM i.MX8M Plus quick start guide for switch settings:

[FRDM-IMX8MPLUS Quick Start Guide](https://www.nxp.com/docs/en/quick-reference-guide/FRDMIMX8MPLUSQSG.pdf)

### 7.5 Optional: Flash eMMC from a running target

If the board is booted from an SD card and you want to update the onboard eMMC, copy the image file to the board and flash it there.

1. Ensure the board is reachable over network and that you have a secure login method.

2. Allow empty password over ssh for Beaglebone Black

    (Execute on Beaglebone Black)

    ```bash
    sed -i 's/^#PermitEmptyPasswords no/PermitEmptyPasswords yes/' /etc/ssh/sshd_config
    systemctl restart ssh.socket
    ```

3. Copy the image to the target board from the host:

    ```bash
    pushd build/boardfarm/images/imx8mpfrdm
    scp core-image-full-cmdline-imx8mpfrdm.rootfs.wic.zst root@<board-ip>:
    popd
    ```

4. On the board, verify the eMMC device path (commonly `/dev/mmcblk1` when booted from SD):

    ```bash
    lsblk
    ```

5. Flash the eMMC from the board:

    ```bash
    cd ~
    zstd -dc core-image-full-cmdline-imx8mpfrdm.rootfs.wic.zst | sudo dd of=/dev/mmcblk1 bs=4M conv=fsync status=progress
    sudo sync
    ```

    - Use `lsblk` to confirm the eMMC device before writing.
    - Prefer SSH keys or console access; if you must enable password login temporarily, set a secure password and revert changes afterward.

### 7.6 Safety notes

- Always validate the target device name with `lsblk` or `fdisk -l` before running write commands.
- Use `bmaptool` when possible — it's faster and reduces write size.
- Keep a serial console or JTAG access available for recovery if a flash operation fails.

Always validate the target device name and do not use these commands on the wrong device.
