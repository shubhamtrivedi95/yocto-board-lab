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
- Build command: ./run-kas.sh shell kas/boards/radxa-zero-3w.yaml -c "bitbake -c cleanall core-image-full-cmdline && bitbake core-image-full-cmdline"
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

## 7. Radxa Zero 3W — flashing to eMMC (maskrom / upgrade_tool)

This section describes how to use Radxa's Linux_Upgrade_Tool to program the loader and image into the Radxa Zero 3W eMMC via the USB OTG `rockusb` (maskrom) mode.

### 7.1 Prerequisites

- A Linux host with `wget`, `unzip`, and `sudo` available.
- A USB-A to USB-C (or micro) cable that connects the board's USB_OTG port to the host.
- The generated Yocto image located under `build/boardfarm/images/radxa-zero-3w/` (for example `core-image-full-cmdline-radxa-zero-3w.rootfs.wic`).
- A serial console program if you want to view the board console (optional): `minicom`, ` picocom`, or `screen`.

### 7.2 Flashing

1) Connect a serial console (optional)

    ```bash
    minicom -D /dev/ttyUSB0 -b 1500000
    ```

    Use the appropriate serial device and baud rate for your USB-serial adapter.

2) Download and prepare Radxa's upgrade tool

    ```bash
    pushd tools/radxa
    wget https://dl.radxa.com/tools/linux/Linux_Upgrade_Tool_V2.1.zip
    unzip Linux_Upgrade_Tool_V2.1.zip
    cd Linux_Upgrade_Tool
    chmod +x upgrade_tool
    ```

3) Enter maskrom (rockusb) mode on the board

    - Press and hold the board's maskrom (recovery) button.
    - While holding the button, connect the board's USB_OTG port to the host with the USB cable.
    - Wait until the board indicates maskrom mode (green LED behavior varies by board), then release the button.

4) Verify the host sees the device

    From `tools/radxa/Linux_Upgrade_Tool` run:

    ```bash
    ./upgrade_tool ld
    ```

    Expected output contains a connected rockusb device, for example:

    ```text
    List of rockusb connected(1)
    DevNo=1 Vid=0x2207,Pid=0x350a,...   Mode=Maskrom
    ```

    If the device is not listed:
    - Check cable and USB port (use a USB 2.0 port, avoid unpowered hubs).
    - Re-enter maskrom mode and re-run `./upgrade_tool ld`.

5) Flash the loader (SPL) — required before writing the main image

    The loader filename varies by Rockchip platform. The repository may include a loader in `tools/radxa/` or you may obtain a vendor-provided SPL. Example:

    ```bash
    sudo ./upgrade_tool db ../rk356x_spl_loader_ddr1056_v1.12.109_no_check_todly.bin
    ```

    - `db` writes a loader to the device. Use the loader recommended for your board revision.

6) Flash the Yocto image to eMMC

    - The upgrade tool expects the target partition index or offset; many Radxa tools use `wl <partition-index> <image>` to write an image. The example below writes whole-image file to the default partition index `0` (board-specific):

    ```bash
    sudo ./upgrade_tool wl 0 ../../../build/boardfarm/images/radxa-zero-3w/core-image-full-cmdline-radxa-zero-3w.rootfs.wic
    ```

    - If you have a compressed `.zst` image, decompress or pass the uncompressed `.wic` file. Verify the correct path relative to the `Linux_Upgrade_Tool` folder.

7) Reboot / reset the board

    ```bash
    sudo ./upgrade_tool rd
    ```

8) Post-flash: verify

    - After reboot, detach USB OTG and power-cycle the board.
    - Connect serial console to observe U-Boot and Linux boot messages.

    Safety notes and tips

    - These operations are low-level and can brick the device if wrong files or offsets are used. Confirm the loader and image are correct for the Radxa Zero 3W.
    - Use a reliable USB cable and a direct USB port on your host (avoid hubs).
    - If possible, test the SD-boot image first (write to microSD and boot) before programming eMMC.
    - Keep a serial console or JTAG access available for recovery if a flash operation fails.

9) Return to workspace root:

    ```bash
    popd
    ```
