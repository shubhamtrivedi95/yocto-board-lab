# yocto-board-lab Build Documentation

This Repository is created to support the multiple Embedded Linux board for Yocto Builds.
To optimize build times, this project heavily relies on a pre-populated `downloads` directory and `sstate-cache`.

> Note: hosting for the `yocto_data.zip` archive is still pending, so this document is currently incomplete and some cache setup instructions may change.

## 📌 Prerequisites & Common Setup

Before proceeding with any of the build workflows, you must prepare your host environment. To significantly reduce build times, all three workflows bypass downloading sources and recompiling unchanged components by reusing a pre-populated Yocto cache.

### Step 1: Install the Common packages

1. Install the python and kas to make sure that commands used in the subsequent section to work

```bash
sudo apt update
sudo apt install python3 python3-pip python3-venv
```

2. Create the virtual environment
```
python3 -m venv .venv
```

3. Start the virtual environment
```bash
source .venv/bin/activate
```

4. Install the kas

```bash
pip install kas==5.3
```

### Step 2: Extract the Yocto Cache
You need the archive containing the pre-fetched Yocto data (e.g., `yocto_data.zip`). This archive contains the `downloads` and `sstate-cache` directories that the build tools will reuse.

1. **Copy the archive** (`yocto_data.zip`) into your home directory on your Linux host.

2. **Extract the archive:**
```bash
   cd ~
   unzip yocto_data.zip

```

3. **Verify the extracted directories:**
Check that the cache and download folders were successfully created in the correct target directory.
```bash
ls -al $HOME/yocto/yocto_data

```


> **Note:** The output of the above command should explicitly show the **`downloads`** and **`sstate-cache`** directories.



### Step 3: System Assumptions & Requirements

* **Operating System:** You are operating on a Linux host (instructions are optimized for Ubuntu 26.04).
* **SSH Keys:** You have a valid SSH key (e.g., `~/.ssh/id_ed25519`) configured and known to your Git repository provider (e.g., GitHub) to pull private sources.
* **Build Modes:** * `normal` (Default): Uses local mirrors for fast, reproducible builds.
* `master`: Writes fetched downloads and sstate data into the mirror path to refresh the cache.

---

## Workflow 1: Build using the `kas` command (Local Host)

This workflow runs directly on your host machine. It requires installing all build dependencies manually.

### 1. Install Prerequisites

Update your system and install the required packages and the `kas` tool:

```bash
sudo apt update
sudo apt-get install build-essential chrpath cpio debianutils diffstat file gawk gcc git iputils-ping libacl1 libcrypt-dev locales python3 python3-git python3-jinja2 python3-pexpect python3-pip python3-subunit socat texinfo unzip wget xz-utils zstd python3-venv
```

### 2. Set the Cache Path and Build

Define the `MIRROR_DATA_PATH` to ensure the local `kas` installation uses your pre-fetched `sstate-cache` and `downloads`. Then, launch the kas shell.

```bash
export MIRROR_DATA_PATH=$HOME/yocto/yocto_data
kas shell -c "bitbake core-image-full-cmdline"

```

*(To refresh the cache instead of just reading from it, prefix the command with `BUILD_TYPE=master`.)*

---

## Workflow 2: Build using the `kas-container` command

This workflow uses the official Siemens `kas` Docker image. It avoids installing heavy host dependencies but requires passing SSH keys into the container so BitBake can access private repositories.

### 1. Install Docker

Ensure Docker Engine is installed on your host system.
Refer the [Install the Docker](#install-the-docker) sections to know the exact install steps

### 2. Configure SSH Key Forwarding

To safely pass your credentials without copying private keys into the container, forward your host's SSH agent:

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

```

### 3. Launch the Official Kas Container

Use `--runtime-args` to mount your local `yocto_data` directory into the container at `/builder/yocto_data`. The `--ssh-agent` flag ensures Git can authenticate.

```bash
KAS_BUILD_DIR=build_container KAS_CONTAINER_IMAGE=ghcr.io/siemens/kas/kas:5.3 kas-container \
  --runtime-args "-v $HOME/yocto/yocto_data:/builder/yocto_data" \
  --ssh-agent shell

```

> *(Once inside the shell, you can run your `bitbake` commands. The system will automatically utilize the mounted caches).*

> *(To refresh the cache instead of just reading from it, add the following command inside --runtime-args **-e BUILD_TYPE=master**.)*

---

## Workflow 3: Build using a Custom Docker Container with `kas-container`

If you are on an incompatible host OS (like a newer Ubuntu version) and need a specific Ubuntu 24.04 environment, you can build a custom Docker image using the provided `board_farm.DockerFile` and execute it via `kas-container`.

### 1. Install Docker

Ensure Docker Engine is installed on your host system.
Refer the [Install the Docker](#install-the-docker) sections to know the exact install steps

### 2. Build the Custom Docker Image

Build the container from the root of this repository:

```bash
docker build -t yocto-board-lab -f board_farm.DockerFile .

```

### 3. Configure SSH Key Forwarding

Just like Workflow 2, activate your SSH agent to handle private repository access:

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

```

### 4. Launch the Custom Container via `kas-container`

Override the default `kas-container` image by setting the `KAS_CONTAINER_IMAGE` variable to your newly built `yocto-board-lab` image. Map the cache directories as usual.

```bash
KAS_CONTAINER_IMAGE=yocto-board-lab kas-container \
  --runtime-args "-v $HOME/yocto/yocto_data:/home/yocto/yocto_data -e MIRROR_DATA_PATH=/home/yocto/yocto_data" \
  --ssh-agent shell

```

> *(Note: Inside the custom container, the cache path is mapped to `/home/yocto/yocto_data` to match the expected environment of the `board_farm.DockerFile`.)*

> *(To refresh the cache instead of just reading from it, add the following command inside --runtime-args **-e BUILD_TYPE=master**.)*
---

## 🛠️ Common Build Commands

Regardless of which workflow you used to open your `kas shell`, use the following commands inside the shell to execute your builds:

**Build the custom applications (Clean and rebuild using cache):**

```bash
bitbake -c cleanall example && bitbake example

```

*(Note: You can append `-f` to force execution of a specific task without relying on the cached data.)*

**Build the complete image:**

```bash
bitbake core-image-full-cmdline

```

**Build Complete SDK:**

```bash
bitbake -c populate_sdk core-image-full-cmdline

```

> The SDK will be located in the `<build-dir>/deploy/<machine>/sdk/` directory.

## Install the docker

Here is the step-by-step guide to installing the official, latest version of **Docker Engine** on **Ubuntu 26.04 (Resolute)**.

---

### Step 1: Remove Existing/Conflicting Packages

Before installing the official Docker engine, clean up any unofficial or older components that might conflict:

```bash
sudo apt-get remove docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc

```

### Step 2: Set Up Docker's Official Repository

To get the latest updates and security patches directly from Docker, you need to add their official APT repository.

1. **Update your local package index and install initial prerequisites:**
```bash
sudo apt-get update
sudo apt-get install ca-certificates curl

```


2. **Add Docker's official GPG key:**
```bash
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

```


3. **Add the repository to your Apt sources:**
```bash
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

```



---

### Step 3: Install Docker Engine

Now that the repository is configured, update `apt` and install Docker alongside the required plugins (including Docker Compose).

```bash
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

```

---

### Step 4: Verify the Installation

On Ubuntu, the Docker service should automatically start. You can check its operational status:

```bash
sudo systemctl status docker

```

To confirm it's running correctly, trigger the classic `hello-world` test container:

```bash
sudo docker run hello-world

```

*(If successful, Docker will pull the test image and output a "Hello from Docker!" confirmation message).*

---

### Step 5: Run Docker Without `sudo` (Optional)

By default, managing Docker requires root privileges. If you want to run `docker` commands as your current non-root user without prepending `sudo`:

1. **Create the docker group (usually already created during install):**
```bash
sudo groupadd docker

```


2. **Add your active user to the group:**
```bash
sudo usermod -aG docker $USER

```


3. **Apply the changes right away:**
```bash
newgrp docker

```

---