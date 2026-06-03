# yocto-board-lab
This Repository is created to support the multiple Embedded Linux board for Yocto Builds

## Available Boards

1. Beaglebone Black
2. Beagle-Y AI

## Install Pre-requisite

```bash
sudo apt update
sudo apt-get install build-essential chrpath cpio debianutils diffstat file gawk gcc git iputils-ping libacl1 libcrypt-dev locales python3 python3-git python3-jinja2 python3-pexpect python3-pip python3-subunit socat texinfo unzip wget xz-utils zstd python3-venv
locale --all-locales | grep en_US.utf8
pip3 install pip --upgrade
python3 -m venv .venv
pip3 install -r requirements.txt
sudo locale-gen en_US.UTF-8
```

## Build armqemu machine
```bash
kas shell kas/boards/armqemu.yaml -c "bitbake -c cleanall core-image-full-cmdline && bitbake core-image-full-cmdline"
```

## Build bbb machine
```bash
kas shell kas/boards/bbb.yaml -c "bitbake -c cleanall core-image-full-cmdline && bitbake core-image-full-cmdline"
```

## Build beagley-ai machine
```bash
kas shell kas/boards/beagley-ai.yaml -c "bitbake -c cleanall tisdk-base-image && bitbake tisdk-base-image"
```

## Build radxa-zero-3w machine
```bash
kas shell kas/boards/radxa-zero-3w.yaml -c "bitbake -c cleanall core-image-full-cmdline && bitbake core-image-full-cmdline"
```

## Run the qemu image
```bash
runqemu qemuarm nographic
```
