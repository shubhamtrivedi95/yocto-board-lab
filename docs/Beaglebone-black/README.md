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
- Build command: ./run-kas.sh shell kas/boards/bbb.yaml -c "bitbake -c cleanall core-image-full-cmdline && bitbake core-image-full-cmdline"
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

## 7. Flashing and SD boot recovery

This section covers how to flash the built BeagleBone Black image to a microSD card and how to recover by booting from SD if the board is currently using eMMC.

### 7.1 Identify the output image

After a successful build, the generated image files are typically located under:

```bash
build/boardfarm/images/beaglebone-yocto/
```

The main artifacts are:

- `core-image-full-cmdline-beaglebone-yocto.rootfs.wic.zst`
- `core-image-full-cmdline-beaglebone-yocto.rootfs.wic.bmap`

Use the compressed `.wic.zst` image with `bmaptool` for the fastest and safest write.

### 7.2 Prepare the host SD card device

Connect the microSD card to the host system and identify the device path before writing. Example:

```bash
sudo dmesg | tail -n 20
lsblk
```

Look for the new device entry for the SD card, such as `/dev/sda` or `/dev/sdb`. Confirm the device path carefully before flashing.

### 7.3 Flash the microSD card with `bmaptool`

From the workspace root:

```bash
pushd build/boardfarm/images/beaglebone-yocto
sudo bmaptool copy --bmap core-image-full-cmdline-beaglebone-yocto.rootfs.wic.bmap core-image-full-cmdline-beaglebone-yocto.rootfs.wic.zst /dev/sdX
sudo sync
popd
```

- `bmaptool copy` uses the block map to write only the used blocks.
- `--bmap` points to the `.bmap` file generated with the image.
- `/dev/sdX` must be replaced with the actual SD card block device.
- `sudo sync` ensures the write is fully committed.

If `bmaptool` is unavailable, the fallback command is:

```bash
pushd build/boardfarm/images/beaglebone-yocto
zstd -dc core-image-full-cmdline-beaglebone-yocto.rootfs.wic.zst | sudo dd of=/dev/sdX bs=4M conv=fsync status=progress
sudo sync
popd
```
> Warning: Do not flash the wrong block device. Always verify the target device path with `lsblk` before running the write command.

### 7.4 Boot the board from microSD

For normal SD boot, insert the flashed microSD card into the BeagleBone Black and power it on.

Some BeagleBone Black variants boot from the SD card automatically when a valid SD image is present. If the board still prefers eMMC, use the board's boot selection mechanism or hold the boot button during power-on according to the board hardware documentation.


### 7.5 Optional: force SD boot by invalidating the eMMC boot area

If you must force the board to boot from microSD and the board does not honor the SD boot path, you can invalidate the eMMC boot area. This is destructive and should only be used when you have verified the device path and understand the risks.

```bash
sudo dd if=/dev/zero of=/dev/mmcblk0 bs=1M count=16 conv=fsync
sudo sync
```

- `/dev/mmcblk0` is normally the internal eMMC device.
- This command zeroes the first 16 MiB of the eMMC boot region, preventing the boot ROM from using eMMC.
- Use this only as a recovery action, not as a routine workflow.

### 7.6 Optional: flash eMMC from a running system

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
pushd build/boardfarm/images/beaglebone-yocto
scp core-image-full-cmdline-beaglebone-yocto.rootfs.wic.zst root@<board-ip>:
popd
```

4. On the target board, verify the eMMC device path (usually `/dev/mmcblk1` when booted from SD):

```bash
lsblk
```

5. Flash the eMMC from the board:

```bash
cd ~
zstd -dc core-image-full-cmdline-beaglebone-yocto.rootfs.wic.zst | sudo dd of=/dev/mmcblk1 bs=4M conv=fsync status=progress
sudo sync
```

- `zstd -dc` decompresses the image to stdout.
- `dd of=/dev/mmcblk1` writes the image to the eMMC device.
- `bs=4M` improves write throughput.
- `status=progress` shows progress while writing.
- `sudo sync` flushes buffers to the device.

Always validate the target device name and do not use this command on the wrong device.

