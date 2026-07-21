# yocto-board-lab

A Yocto project repository for building Embedded Linux images across multiple development boards.

## Overview

This repository provides Yocto build support, board metadata, and example commands for:

- BeagleBone Black
- BeagleY-AI
- Raspberry Pi 5

It also includes work-in-progress support for additional boards and planned BSP integrations.

## Supported Boards

- BeagleBone Black
- BeagleY-AI
- Raspberry Pi 5
- FRDM-iMX8MP

## Upcoming Boards

- NVIDIA Jetson Orin Nano DevKit
- Radxa Rock 5T
- Radxa Zero 3W
- MilkV Duo S

## Prerequisites

Install the required packages on Ubuntu/Debian:

```bash
sudo apt update
sudo apt install -y build-essential chrpath cpio debianutils diffstat file gawk gcc git iputils-ping libacl1 libcrypt-dev locales python3 python3-git python3-jinja2 python3-pexpect python3-pip python3-subunit socat texinfo unzip wget xz-utils zstd python3-venv lz4
```

Set up locale support:

```bash
sudo locale-gen en_US.UTF-8
locale --all-locales | grep en_US.utf8
```

Create and activate the Python virtual environment:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

## Board Documentation

Board-specific documentation for supported and in-progress targets is available under the docs folder:

- [Beaglebone-black](docs/Beaglebone-black/README.md)
- [BeagleY-AI](docs/BeagleY-AI/README.md)
- [FRDM-i.MX8MP](docs/FRDM-i.MX8MP/README.md)
- [Jetson-Orin-Nano](docs/Jetson-Orin-Nano/README.md)
- [MilkV-Duo-S](docs/MilkV-Duo-S/README.md)
- [Qemu-arm](docs/Qemu-arm/README.md)
- [Qemu-arm64](docs/Qemu-arm64/README.md)
- [Radxa-Rock-5T](docs/Radxa-Rock-5T/README.md)
- [Radxa-Zero-3W](docs/Radxa-Zero-3W/README.md)
- [Raspberry-Pi-5](docs/Raspberry-Pi-5/README.md)

## Build Instructions

Use `kas shell` to enter the build environment and run `bitbake`.

### BeagleBone Black

```bash
kas shell kas/boards/bbb.yaml -c "bitbake -c cleanall core-image-full-cmdline && bitbake core-image-full-cmdline"
```

### BeagleY-AI

```bash
kas shell kas/boards/beagley-ai.yaml -c "bitbake -c cleanall arago-base-image && bitbake arago-base-image"
```

### Raspberry Pi 5

```bash
kas shell kas/boards/rpi5.yaml -c "bitbake -c cleanall core-image-full-cmdline && bitbake core-image-full-cmdline"
```

### Radxa Zero 3W

```bash
kas shell kas/boards/radxa-zero-3w.yaml -c "bitbake -c cleanall core-image-full-cmdline && bitbake core-image-full-cmdline"
```

### FRDM-iMX8M Plus

```bash
kas shell kas/boards/frdm-imx8mp.yaml -c "bitbake -c cleanall core-image-full-cmdline && bitbake core-image-full-cmdline"
```

### Arm QEMU (qemuarm)

```bash
kas shell kas/boards/qemuarm.yaml -c "bitbake -c cleanall core-image-full-cmdline && bitbake core-image-full-cmdline"
```

### Arm64 QEMU (qemuarm64)

```bash
kas shell kas/boards/qemuarm64.yaml -c "bitbake -c cleanall core-image-full-cmdline && bitbake core-image-full-cmdline"
```

## Running QEMU

To boot the QEMU-built image:

```bash
kas shell kas/boards/armqemu.yaml -c "runqemu qemuarm nographic"
```

## Status Matrix

| Status | Board                          | Image                     | Notes                                     |
|--------|--------------------------------|---------------------------|-------------------------------------------|
| ✅     | qemuarm                        | core-image-full-cmdline   | Successfully booted in QEMU               |
| ✅     | qemuarm64                      | core-image-full-cmdline   | Successfully booted in QEMU               |
| ✅     | Raspberry Pi 5                 | core-image-full-cmdline   | Successfully booted                       |
| ✅     | FRDM-iMX8MP                    | core-image-full-cmdline   | Successfully booted, AI Validation pending|
| ✅     | BeagleBone Black               | core-image-full-cmdline   | Successfully booted                       |
| ✅     | BeagleY-AI Rev-A               | arago-base-image          | Successfully booted, AI validation pending|
| ⬜     | Radxa Zero 3W                  | core-image-full-cmdline   | Board support in progress                 |
| ⬜     | Radxa Rock 5T                  | core-image-full-cmdline   | RK3588 support evaluation                 |
| ⬜     | MilkV Duo S                    | core-image-full-cmdline   | Vendor BSP review required                |
| ⬜     | NVIDIA Jetson Orin Nano DevKit | demo-image-base   | Image build complete successfully, boot up is pending    |

## Notes

- Update `kas/boards/*.yaml` if you add or modify board support.
- Use `bitbake -c cleanall <image>` to ensure clean builds after recipe or layer changes.
- If you encounter missing dependencies, verify the current Yocto and KAS documentation for your host distribution.

## Contributing

Contributions are welcome. Please open issues or provide patches for:

- new board support
- BSP updates
- image configuration improvements
- build and runtime troubleshooting
