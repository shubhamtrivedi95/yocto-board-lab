#!/usr/bin/env bash

set -euo pipefail

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="${SCRIPT_DIR}/.venv"
KAS_VERSION="5.4"

# -----------------------------------------------------------------------------
# Usage
# -----------------------------------------------------------------------------

usage()
{
    cat <<EOF
Usage:
    $0 [--build-type <normal|master>] [--shared-dir <directory>] [--no-host-network]
       [--ssh-key <private-key-file>] [--ssh-known-hosts-file <file>]
       [--ssh-known-host <host>]...
       [--ssh-accept-new-hosts] [--dockerfile <file>] [--image-name <name>]
       -- <kas-container arguments>

Options:
    --ssh-known-hosts-file <file>
        Copy this OpenSSH known_hosts file into the container's SSH directory.
        May be combined with --ssh-known-host and --ssh-accept-new-hosts.
        Requires --ssh-key.

    --ssh-known-host <host>
        Trust the SSH host key of <host> (e.g. github.com or
        git.example.com:2222) so git does not stop at the "unknown host
        identity" prompt. The key is fetched with ssh-keyscan and its
        fingerprint is printed so it can be verified. May be repeated.
        Requires --ssh-key.

    --ssh-accept-new-hosts
        Let ssh automatically trust host keys of hosts seen for the first
        time (StrictHostKeyChecking=accept-new). Changed keys are still
        rejected. Less strict than --ssh-known-host. Requires --ssh-key.

    --ssh-key <private-key-file>
        Add the private SSH key to an ssh-agent and forward the agent to the
        container (kas-container --ssh-agent), so private repositories can be
        fetched. An already running agent (SSH_AUTH_SOCK) is reused; otherwise
        a temporary agent is started and stopped when the script exits.
        You may be prompted for the key's passphrase.

    --dockerfile <file>
        Build a Docker image from this Dockerfile (context: its directory
        unless --docker-context is given) and run kas-container with that
        image instead of the default kas image. The image must provide kas.

    --docker-context <directory>
        Build context for --dockerfile. Defaults to the Dockerfile's directory.

    --image-name <name>
        Tag for the image built from --dockerfile.
        Defaults to yocto-board-lab-custom.

    --build-type <normal|master>
        Value exported to the container as BUILD_TYPE.
        Optional. Defaults to normal when not specified.

    --no-host-network
        Do not pass --network host to kas-container.
        Host networking is enabled by default.

    --shared-dir <directory>
        Optional host directory mounted as:
        /builder/yocto_data

        Required when --build-type is master.

If --build-type is master, --shared-dir is required.

Examples:

    $0 -- shell kas/boards/bbb.yaml

    $0 --shared-dir "\$HOME/yocto/yocto_data" -- shell kas/boards/bbb.yaml

    $0 --build-type normal -- shell kas/boards/bbb.yaml

    $0 --no-host-network -- shell kas/boards/qemuarm.yaml

    $0 --build-type master \\
        --shared-dir "\$HOME/yocto/yocto_data" \\
        -- shell kas/boards/bbb.yaml

    $0 --ssh-key ~/.ssh/id_ed25519 -- shell kas/boards/bbb.yaml

    $0 --ssh-key ~/.ssh/id_ed25519 --ssh-known-host github.com \\
        -- shell kas/boards/bbb.yaml

    $0 --ssh-key ~/.ssh/id_ed25519 --ssh-known-hosts-file ~/.ssh/known_hosts \\
        -- shell kas/boards/bbb.yaml

    $0 --dockerfile board_farm.DockerFile \\
        --shared-dir "\$HOME/yocto/yocto_data" \\
        -- shell kas/boards/bbb.yaml
EOF
}

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------

SHARED_DIR=""
KAS_ARGS=()

BUILD_TYPE="normal"
HOST_NETWORK=true

SSH_KEY=""
DOCKERFILE=""
DOCKER_CONTEXT=""
IMAGE_NAME="yocto-board-lab-custom"
STARTED_SSH_AGENT_PID=""
SSH_KNOWN_HOSTS=()
SSH_KNOWN_HOSTS_FILE=""
SSH_ACCEPT_NEW=false
SSH_CONFIG_DIR=""

cleanup()
{
    if [[ -n "$STARTED_SSH_AGENT_PID" ]]; then
        kill "$STARTED_SSH_AGENT_PID" >/dev/null 2>&1 || true
    fi

    if [[ -n "$SSH_CONFIG_DIR" ]]; then
        rm -rf "$SSH_CONFIG_DIR"
    fi
}

trap cleanup EXIT

# -----------------------------------------------------------------------------
# Parse wrapper arguments
# -----------------------------------------------------------------------------

while [[ $# -gt 0 ]]; do
    case "$1" in
        --shared-dir)
            if [[ $# -lt 2 ]]; then
                echo "ERROR: --shared-dir requires an argument." >&2
                exit 1
            fi

            SHARED_DIR="$2"
            shift 2
            ;;

        --build-type)
            if [[ $# -lt 2 ]]; then
                echo "ERROR: --build-type requires an argument." >&2
                exit 1
            fi

            BUILD_TYPE="$2"
            shift 2
            ;;

        --no-host-network)
            HOST_NETWORK=false
            shift
            ;;

        --ssh-key)
            if [[ $# -lt 2 ]]; then
                echo "ERROR: --ssh-key requires an argument." >&2
                exit 1
            fi

            SSH_KEY="$2"
            shift 2
            ;;

        --ssh-known-host)
            if [[ $# -lt 2 ]]; then
                echo "ERROR: --ssh-known-host requires an argument." >&2
                exit 1
            fi

            SSH_KNOWN_HOSTS+=("$2")
            shift 2
            ;;

        --ssh-known-hosts-file)
            if [[ $# -lt 2 ]]; then
                echo "ERROR: --ssh-known-hosts-file requires an argument." >&2
                exit 1
            fi

            SSH_KNOWN_HOSTS_FILE="$2"
            shift 2
            ;;

        --ssh-accept-new-hosts)
            SSH_ACCEPT_NEW=true
            shift
            ;;

        --dockerfile)
            if [[ $# -lt 2 ]]; then
                echo "ERROR: --dockerfile requires an argument." >&2
                exit 1
            fi

            DOCKERFILE="$2"
            shift 2
            ;;

        --docker-context)
            if [[ $# -lt 2 ]]; then
                echo "ERROR: --docker-context requires an argument." >&2
                exit 1
            fi

            DOCKER_CONTEXT="$2"
            shift 2
            ;;

        --image-name)
            if [[ $# -lt 2 ]]; then
                echo "ERROR: --image-name requires an argument." >&2
                exit 1
            fi

            IMAGE_NAME="$2"
            shift 2
            ;;

        -h|--help)
            usage
            exit 0
            ;;

        --)
            shift
            KAS_ARGS=("$@")
            break
            ;;

        *)
            echo "ERROR: Unknown wrapper argument: $1" >&2
            echo
            usage
            exit 1
            ;;
    esac
done

# -----------------------------------------------------------------------------
# Validate BUILD_TYPE
# -----------------------------------------------------------------------------

case "$BUILD_TYPE" in
    normal|master)
        ;;
    *)
        echo "ERROR: Invalid build type: '$BUILD_TYPE'" >&2
        echo "       --build-type must be either 'normal' or 'master'." >&2
        exit 1
        ;;
esac

# -----------------------------------------------------------------------------
# Validate kas arguments
# -----------------------------------------------------------------------------

if [[ ${#KAS_ARGS[@]} -eq 0 ]]; then
    echo "ERROR: No kas-container arguments specified." >&2
    echo
    usage
    exit 1
fi

# -----------------------------------------------------------------------------
# BUILD_TYPE=master requires --shared-dir
# -----------------------------------------------------------------------------

if [[ "$BUILD_TYPE" == "master" && -z "$SHARED_DIR" ]]; then
    echo "ERROR: --shared-dir is required when BUILD_TYPE=master." >&2
    echo
    usage
    exit 1
fi

# -----------------------------------------------------------------------------
# Check Python
# -----------------------------------------------------------------------------

if ! command -v python3 >/dev/null 2>&1; then
    echo "ERROR: python3 is not installed." >&2
    exit 1
fi

# -----------------------------------------------------------------------------
# Create virtual environment if necessary
# -----------------------------------------------------------------------------

if [[ ! -x "${VENV_DIR}/bin/python" ]]; then
    echo "Creating Python virtual environment:"
    echo "    ${VENV_DIR}"

    python3 -m venv "$VENV_DIR"
fi

# -----------------------------------------------------------------------------
# Install kas 5.4 if necessary
# -----------------------------------------------------------------------------

KAS="${VENV_DIR}/bin/kas"
KAS_CONTAINER="${VENV_DIR}/bin/kas-container"

if [[ ! -x "$KAS" ]] || \
   ! "$KAS" --version 2>/dev/null | grep -qE '(^|[[:space:]])5\.4([[:space:]]|$)'; then

    echo "Installing kas ${KAS_VERSION}..."

    "${VENV_DIR}/bin/python" -m pip install --upgrade pip
    "${VENV_DIR}/bin/python" -m pip install "kas==${KAS_VERSION}"
fi

if [[ ! -x "$KAS_CONTAINER" ]]; then
    echo "ERROR: kas-container was not installed correctly." >&2
    exit 1
fi

# -----------------------------------------------------------------------------
# Build kas-container runtime arguments
# -----------------------------------------------------------------------------

RUNTIME_ARGS=""

# Add shared directory only when explicitly specified
if [[ -n "$SHARED_DIR" ]]; then

    SHARED_DIR="$(realpath -m "$SHARED_DIR")"

    if [[ ! -d "$SHARED_DIR" ]]; then
        echo "Creating shared directory: $SHARED_DIR"
        mkdir -p "$SHARED_DIR"
    fi

    RUNTIME_ARGS="-v ${SHARED_DIR}:/builder/yocto_data"
fi

# Always pass the validated BUILD_TYPE to the container
if [[ -n "$RUNTIME_ARGS" ]]; then
    RUNTIME_ARGS+=" "
fi

RUNTIME_ARGS+="-e BUILD_TYPE=${BUILD_TYPE}"

if [[ "$HOST_NETWORK" == true ]]; then
    RUNTIME_ARGS+=" --network host"
fi

# -----------------------------------------------------------------------------
# Build and select a custom Docker image
# -----------------------------------------------------------------------------

if [[ -n "$DOCKERFILE" ]]; then

    if [[ ! -f "$DOCKERFILE" ]]; then
        echo "ERROR: Dockerfile not found: $DOCKERFILE" >&2
        exit 1
    fi

    DOCKERFILE="$(realpath "$DOCKERFILE")"
    DOCKER_CONTEXT="$(realpath "${DOCKER_CONTEXT:-$(dirname "$DOCKERFILE")}")"

    if ! command -v docker >/dev/null 2>&1; then
        echo "ERROR: docker is not installed." >&2
        exit 1
    fi

    echo "Building custom Docker image '${IMAGE_NAME}' from ${DOCKERFILE}"
    docker build -t "$IMAGE_NAME" -f "$DOCKERFILE" "$DOCKER_CONTEXT"

    export KAS_CONTAINER_IMAGE="$IMAGE_NAME"

    if [[ -n "$SHARED_DIR" ]]; then
        RUNTIME_ARGS+=" -e MIRROR_DATA_PATH=/builder/yocto_data"
    fi
fi

# -----------------------------------------------------------------------------
# Forward an SSH key through ssh-agent
# -----------------------------------------------------------------------------

KAS_GLOBAL_ARGS=()

if [[ -n "$SSH_KEY" ]]; then

    if [[ ! -f "$SSH_KEY" ]]; then
        echo "ERROR: SSH key not found: $SSH_KEY" >&2
        exit 1
    fi

    for tool in ssh-agent ssh-add; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            echo "ERROR: $tool is not installed." >&2
            exit 1
        fi
    done

    if [[ -z "${SSH_AUTH_SOCK:-}" || ! -S "${SSH_AUTH_SOCK}" ]]; then
        eval "$(ssh-agent -s)" >/dev/null
        STARTED_SSH_AGENT_PID="$SSH_AGENT_PID"
    fi

    ssh-add "$SSH_KEY"

    KAS_GLOBAL_ARGS+=(--ssh-agent)
fi

# -----------------------------------------------------------------------------
# Trust SSH server identities (host keys)
# -----------------------------------------------------------------------------

if [[ -n "$SSH_KNOWN_HOSTS_FILE" || ${#SSH_KNOWN_HOSTS[@]} -gt 0 || "$SSH_ACCEPT_NEW" == true ]]; then

    if [[ -z "$SSH_KEY" ]]; then
        echo "ERROR: SSH host identity options require --ssh-key." >&2
        exit 1
    fi

    SSH_CONFIG_DIR="$(mktemp -d)"

    if [[ -n "$SSH_KNOWN_HOSTS_FILE" ]]; then
        if [[ ! -f "$SSH_KNOWN_HOSTS_FILE" || ! -r "$SSH_KNOWN_HOSTS_FILE" ]]; then
            echo "ERROR: known_hosts file is missing or unreadable: $SSH_KNOWN_HOSTS_FILE" >&2
            exit 1
        fi

        cp -- "$SSH_KNOWN_HOSTS_FILE" "${SSH_CONFIG_DIR}/known_hosts"
    else
        touch "${SSH_CONFIG_DIR}/known_hosts"
    fi

    for entry in "${SSH_KNOWN_HOSTS[@]+"${SSH_KNOWN_HOSTS[@]}"}"; do
        host="${entry%%:*}"
        port=""
        [[ "$entry" == *:* ]] && port="${entry##*:}"

        if ! command -v ssh-keyscan >/dev/null 2>&1; then
            echo "ERROR: ssh-keyscan is not installed." >&2
            exit 1
        fi

        echo "Fetching SSH host key for ${entry}"
        scanned="$(ssh-keyscan ${port:+-p "$port"} -T 10 "$host" 2>/dev/null || true)"

        if [[ -z "$scanned" ]]; then
            echo "ERROR: could not fetch the SSH host key for ${entry}." >&2
            exit 1
        fi

        printf '%s\n' "$scanned" >> "${SSH_CONFIG_DIR}/known_hosts"
        printf '%s\n' "$scanned" | ssh-keygen -lf - | sed 's/^/  /'
    done

    if [[ "$SSH_ACCEPT_NEW" == true ]]; then
        printf 'Host *\n    StrictHostKeyChecking accept-new\n' > "${SSH_CONFIG_DIR}/config"
    fi

    KAS_GLOBAL_ARGS+=(--ssh-dir "$SSH_CONFIG_DIR")
fi

# -----------------------------------------------------------------------------
# Execute kas-container
# -----------------------------------------------------------------------------

echo "Running:"
echo "  $KAS_CONTAINER --runtime-args \"$RUNTIME_ARGS\" ${KAS_GLOBAL_ARGS[*]:-} ${KAS_ARGS[*]}"
echo

# Not exec'd so the EXIT trap can stop an ssh-agent started by this script
set +e
"$KAS_CONTAINER" \
    --runtime-args "$RUNTIME_ARGS" \
    ${KAS_GLOBAL_ARGS[@]+"${KAS_GLOBAL_ARGS[@]}"} \
    "${KAS_ARGS[@]}"
exit $?