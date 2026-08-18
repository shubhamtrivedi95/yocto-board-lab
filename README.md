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
- Radxa Zero 3W

## Upcoming Boards

- Nvidia Jetson Orin Nano DevKit/Nvidia Jeston Orin Nano Module 8GB
- Radxa Rock 5T
- MilkV Duo S

## Prerequisites

Install the required packages on Ubuntu/Debian:

```bash
sudo apt update
sudo apt install -y python3 python3-pip python3-venv docker.io containerd bmap-tools
```

Validate docker support:

### Start the docker service

```bash
sudo systemctl start docker
```

### Add current user to the docker group

```bash
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker
```

### Run the hello world docker image

```bash
docker run hello-world
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

Use `./run-kas.sh shell <kas-file-path>` to enter the build environment and run `bitbake`.

### BeagleBone Black

```bash
./run-kas.sh shell kas/boards/bbb.yaml -c "bitbake -c cleanall core-image-full-cmdline && bitbake core-image-full-cmdline"
```

### BeagleY-AI

```bash
./run-kas.sh shell kas/boards/beagley-ai.yaml -c "bitbake -c cleanall arago-base-image && bitbake arago-base-image"
```

### Raspberry Pi 5

```bash
./run-kas.sh shell kas/boards/rpi5.yaml -c "bitbake -c cleanall core-image-full-cmdline && bitbake core-image-full-cmdline"
```

### Radxa Zero 3W

```bash
./run-kas.sh shell kas/boards/radxa-zero-3w.yaml -c "bitbake -c cleanall core-image-full-cmdline && bitbake core-image-full-cmdline"
```

### FRDM-iMX8M Plus

```bash
./run-kas.sh shell kas/boards/frdm-imx8mp.yaml -c "bitbake -c cleanall core-image-full-cmdline && bitbake core-image-full-cmdline"
```

### Arm QEMU (qemuarm)

```bash
./run-kas.sh shell kas/boards/qemuarm.yaml -c "bitbake -c cleanall core-image-full-cmdline && bitbake core-image-full-cmdline"
```

### Arm64 QEMU (qemuarm64)

```bash
./run-kas.sh shell kas/boards/qemuarm64.yaml -c "bitbake -c cleanall core-image-full-cmdline && bitbake core-image-full-cmdline"
```

## Running QEMU

To boot the QEMU-built image:

```bash
# Build the image first using kas-container
./run-kas.sh shell kas/boards/qemuarm.yaml -c "bitbake -c cleanall core-image-full-cmdline && bitbake core-image-full-cmdline"
# Run the image in qemu using kas command
kas shell kas/boards/armqemu.yaml -c "runqemu qemuarm nographic"
```

## Status Matrix

| Status | Board                          | Image                     | Notes                                     |
|--------|--------------------------------|---------------------------|-------------------------------------------|
| ⬜     | qemuarm                        | core-image-full-cmdline   | Successfully boots in QEMU when built with `kas`; currently fails to boot when built with `run-kas.sh`.  |
| ⬜     | qemuarm64                      | core-image-full-cmdline   | Successfully boots in QEMU when built with `kas`; currently fails to boot when built with `run-kas.sh`.  |
| ✅     | Raspberry Pi 5                 | core-image-full-cmdline   | Successfully booted                       |
| ✅     | FRDM-iMX8MP                    | core-image-full-cmdline   | Successfully booted, AI Validation pending|
| ✅     | BeagleBone Black               | core-image-full-cmdline   | Successfully booted                       |
| ✅     | BeagleY-AI Rev-A               | arago-base-image          | Successfully booted, AI validation pending|
| ✅     | Radxa Zero 3W                  | core-image-full-cmdline   | Successfully booted                 |
| ⬜     | Radxa Rock 5T                  | core-image-full-cmdline   | RK3588 support evaluation                 |
| ⬜     | MilkV Duo S                    | core-image-full-cmdline   | Vendor BSP review required                |
| ⬜     | NVIDIA Jetson Orin Nano DevKit | demo-image-base   | Image build complete successfully, boot up is pending    |

## Notes

- Update `kas/boards/*.yaml` if you add or modify board support.
- Use `bitbake -c cleanall <image>` to ensure clean builds after recipe or layer changes.
- If you encounter missing dependencies, verify the current Yocto and KAS documentation for your host distribution.

## Using `run-kas.sh` with shared downloads and sstate-cache

The wrapper script will create a Python virtual environment in `.venv` and install `kas==5.4` automatically if needed. It forwards the arguments after `--` directly to `kas-container`.

- `--shared-dir <directory>` mounts the host directory at `/builder/yocto_data` inside the container.
- `BUILD_TYPE=normal` is the default mode and does not require `--shared-dir` unless you want to reuse or persist caches on the host.
- `BUILD_TYPE=master` requires `--shared-dir` and is used when you want the container to read from and write to a host-side shared `downloads`/`sstate-cache` directory.

### Example: use existing pre-fetched downloads and sstate-cache

If you already have the host cache in `$HOME/yocto/yocto_data`, run:

```bash
./run-kas.sh --shared-dir "$HOME/yocto/yocto_data" -- shell kas/boards/bbb.yaml
```

This mounts the existing host cache into the container so the build can reuse it.

### Example: populate the shared cache directory from the container

If you want the build to populate or update the shared host cache, run:

```bash
BUILD_TYPE="master" ./run-kas.sh --shared-dir "$HOME/yocto/yocto_data" -- shell kas/boards/bbb.yaml
```

`BUILD_TYPE=master` makes the wrapper enforce the shared directory requirement and enables the build environment to persist downloads and `sstate-cache` to the host path.

## Inspect a generated root filesystem image

1. `sudo mkdir -p /mnt/image/`  
   Create the mount point directory as root, including parent directories if needed.

2. `pushd build/boardfarm/images/radxa-zero-3w`  
   Change into the image output directory and save the previous location.

3. `sudo mount -o loop core-image-full-cmdline-radxa-zero-3w.rootfs.ext4 /mnt/image/`  
   Mount the `.ext4` rootfs image file to image using a loopback device.

4. `ls -al /mnt/image`  
   List the mounted filesystem contents in long format, including hidden files.

5. `popd`  
   Return to the original directory saved by `pushd`.

## Contributing

Contributions are welcome. Please open issues or provide patches for:

- new board support
- BSP updates
- image configuration improvements
- build and runtime troubleshooting
