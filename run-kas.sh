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
    $0 [--build-type <normal|master>] [--shared-dir <directory>] [--no-host-network] -- <kas-container arguments>

Options:
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
EOF
}

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------

SHARED_DIR=""
KAS_ARGS=()

BUILD_TYPE="normal"
HOST_NETWORK=true

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
# Execute kas-container
# -----------------------------------------------------------------------------

if [[ -n "$RUNTIME_ARGS" ]]; then

    echo "Running:"
    echo "  $KAS_CONTAINER --runtime-args \"$RUNTIME_ARGS\" ${KAS_ARGS[*]}"
    echo

    exec "$KAS_CONTAINER" \
        --runtime-args "$RUNTIME_ARGS" \
        "${KAS_ARGS[@]}"

else

    echo "Running:"
    echo "  $KAS_CONTAINER ${KAS_ARGS[*]}"
    echo

    exec "$KAS_CONTAINER" "${KAS_ARGS[@]}"

fi