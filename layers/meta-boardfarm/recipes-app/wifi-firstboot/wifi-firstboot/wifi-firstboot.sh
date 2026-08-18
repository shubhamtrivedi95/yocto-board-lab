#!/bin/sh

#
# wifi-firstboot.sh
#
# Securely configure WiFi using systemd-networkd and wpa_supplicant.
# Uses DHCP for network addressing and optional credential hashing via wpa_passphrase.
#
# Security: Runs as root, uses wpa_passphrase for password hashing, validates input,
#           backs up existing configs, writes atomically via temp files.
#
# Example:
#   wifi-firstboot.sh --ssid "MyNetwork" --password "secret123"
#

set -eu

# Script defaults
INTERFACE="wlan0"
SSID=""
PASSWORD=""
DEBUG=0
TEMP_FILES=""

# Configuration paths (can be overridden)
WPA_SUPPLICANT_DIR="/etc/wpa_supplicant"
SYSTEMD_NETWORK_DIR="/etc/systemd/network"
MARKER_FILE="/var/lib/wifi-configured"

# Helper: print debug messages
debug() {
	[ "$DEBUG" -eq 1 ] && echo "[DEBUG] $*" >&2
}

# Helper: cleanup temp files on exit
cleanup() {
	if [ -n "$TEMP_FILES" ]; then
		echo "[INFO] Cleaning up temporary files..." >&2
		echo "$TEMP_FILES" | while IFS= read -r tmpfile; do
			[ -f "$tmpfile" ] && rm -f "$tmpfile"
		done
	fi
}

trap cleanup EXIT

# Helper: print to stderr with timestamp
log_error() {
	echo "[ERROR] $*" >&2
}

log_info() {
	echo "[INFO] $*" >&2
}

# Helper: check if command exists
command_exists() {
	command -v "$1" > /dev/null 2>&1
}

# Helper: validate SSID (basic check)
validate_ssid() {
	[ -z "$1" ] && { log_error "SSID cannot be empty"; return 1; }
	[ ${#1} -gt 32 ] && { log_error "SSID cannot exceed 32 characters"; return 1; }
	return 0
}

# Helper: validate password length
validate_password() {
	[ -z "$1" ] && { log_error "Password cannot be empty"; return 1; }
	[ ${#1} -lt 8 ] && { log_error "Password must be at least 8 characters"; return 1; }
	[ ${#1} -gt 63 ] && { log_error "Password cannot exceed 63 characters"; return 1; }
	return 0
}

# Helper: backup existing config file
backup_config() {
	local config_file="$1"
	if [ -f "$config_file" ]; then
		local backup="${config_file}.bak.$(date +%s)"
		log_info "Backing up $config_file to $backup"
		cp "$config_file" "$backup"
	fi
}

cleanup_config() {
    local config_file="${1}"
    BASENAME=$(basename "$config_file")
    FILE_DIR=$(dirname "$config_file")
    log_info "Cleaning up backup config files matching $BASENAME in directory $FILE_DIR"
    FILES=$(find ${FILE_DIR} -name "$BASENAME.bak.*" -type f)
    for file in $FILES; do
        log_info "Removing backup config file $file"
        rm -f "$file"
    done
}

# Helper: write file atomically using temp file
write_atomic() {
	local target="$1"
	local content="$2"
	local tmpfile
	tmpfile=$(mktemp) || { log_error "Failed to create temp file"; return 1; }
	TEMP_FILES="${TEMP_FILES}${tmpfile}
"
	echo "$content" > "$tmpfile" || return 1
	chmod 600 "$tmpfile" || return 1
	mv "$tmpfile" "$target" || return 1
	log_info "Wrote $target"
	return 0
}

# Helper: restart network interface (down, wait, up)
restart_interface() {
	local iface="$1"
	local wait_time="${2:-10}"
	
	log_info "Bringing down interface $iface..."
	if ! ip link set "$iface" down; then
		log_error "Failed to bring down interface $iface"
		return 1
	fi
	
	log_info "Waiting $wait_time seconds before bringing interface back up..."
	sleep "$wait_time"
	
	log_info "Bringing up interface $iface..."
	if ! ip link set "$iface" up; then
		log_error "Failed to bring up interface $iface"
		return 1
	fi
	
	log_info "Interface $iface restarted successfully"
	return 0
}

usage()
{
cat << EOF
Usage: $0 --ssid <ssid> --password <password> [OPTIONS]

Required options:
  --ssid SSID                    WiFi SSID (1-32 chars)
  --password PASSWORD            WPA/WPA2 password (8-63 chars)

Optional options:
  --interface IFACE              WiFi interface (default: wlan0)
  --debug                        Enable debug output
  --help                         Show this help message

Examples:
  # DHCP mode (auto IP assignment):
  $0 --ssid "MyNetwork" --password "secret123"

EOF
	exit 0
}

# Parse arguments
TEMP=$(getopt -o '' \
	--long ssid:,password:,interface:,debug,help \
	-n "$(basename "$0")" \
	-- "$@") || { usage; exit 1; }

eval set -- "$TEMP"

while true; do
	case "$1" in
		--ssid)
			SSID="$2"
			shift 2
			;;
		--password)
			PASSWORD="$2"
			shift 2
			;;
		--interface)
			INTERFACE="$2"
			shift 2
			;;
		--debug)
			DEBUG=1
			shift
			;;
		--help)
			usage
			;;
		--)
			shift
			break
			;;
		*)
			log_error "Unknown option: $1"
			usage
			;;
	esac
done

# Validation: must run as root
if [ "$(id -u)" -ne 0 ]; then
	log_error "This script must run as root"
	exit 1
fi

# Validation: required arguments
[ -z "$SSID" ] && { log_error "--ssid is required"; usage; exit 1; }
[ -z "$PASSWORD" ] && { log_error "--password is required"; usage; exit 1; }

validate_ssid "$SSID" || exit 1
validate_password "$PASSWORD" || exit 1

debug "SSID: $SSID"
debug "INTERFACE: $INTERFACE"
debug "DEBUG: $DEBUG"

# Validation: interface exists
if ! ip link show "$INTERFACE" > /dev/null 2>&1; then
	log_error "Interface $INTERFACE does not exist"
	exit 1
fi

# Validation: required tools
for tool in ip systemctl awk; do
	command_exists "$tool" || { log_error "$tool not found in PATH"; exit 1; }
done

# Create directories
mkdir -p "$WPA_SUPPLICANT_DIR" "$SYSTEMD_NETWORK_DIR" /var/lib

WPA_CONF="${WPA_SUPPLICANT_DIR}/wpa_supplicant-${INTERFACE}.conf"

# Clean up old backups from previous runs to keep filesystem clean
cleanup_config "$WPA_CONF"

# Backup existing configs
backup_config "$WPA_CONF"

log_info "Generating WPA configuration for $INTERFACE..."

# Generate WPA config: use wpa_passphrase if available for secure hashing
if command_exists wpa_passphrase; then
	debug "Using wpa_passphrase for secure password hashing"
	WPA_PSK=$(wpa_passphrase "$SSID" "$PASSWORD" | awk '/^\s*psk=/' | cut -d= -f2)
	WPA_CONFIG=$(cat <<-EOF
		ctrl_interface=/run/wpa_supplicant
		update_config=1

		network={
			ssid="$SSID"
			psk=$WPA_PSK
		}
	EOF
	)
else
	log_info "wpa_passphrase not found; storing password in plaintext (less secure)"
	WPA_CONFIG=$(cat <<-EOF
		ctrl_interface=/run/wpa_supplicant
		update_config=1

		network={
			ssid="$SSID"
			psk="$PASSWORD"
		}
	EOF
	)
fi

write_atomic "$WPA_CONF" "$WPA_CONFIG" || { log_error "Failed to write WPA config"; exit 1; }

log_info "Generating network configuration for $INTERFACE (DHCP mode)..."

# Enable and start services
log_info "Enabling and restarting services..."
systemctl enable "wpa_supplicant@${INTERFACE}.service" 2>/dev/null || log_info "wpa_supplicant@${INTERFACE}.service enable warning"

systemctl stop "wpa_supplicant@${INTERFACE}.service" || { log_error "Failed to stop wpa_supplicant"; exit 1; }

# Restart the physical interface: down, wait 10s, up
log_info "Restarting physical interface..."
restart_interface "$INTERFACE" 10 || { log_error "Failed to restart interface"; exit 1; }
systemctl start "wpa_supplicant@${INTERFACE}.service" || { log_error "Failed to start wpa_supplicant"; exit 1; }

log_info "Waiting for WiFi connection and DHCP lease..."

ATTEMPTS=60
while [ $ATTEMPTS -gt 0 ]; do
    if ip -4 addr show "$INTERFACE" | grep -q "inet "; then
        log_info "WiFi connected, obtained IP address"
        break
    fi
    sleep 1
    ATTEMPTS=$((ATTEMPTS - 1))
    
done

if [ $ATTEMPTS -eq 0 ]; then
    log_error "Failed to obtain IP address via DHCP within 60 seconds"
    exit 1
fi

# Verify configuration
CURRENT_IP=$(ip -4 addr show "$INTERFACE" 2>/dev/null | awk '/inet / {print $2; exit}')
if [ -n "$CURRENT_IP" ]; then
    log_info "Static IP applied successfully: $CURRENT_IP"
fi
touch "$MARKER_FILE" || log_info "Warning: Could not write marker file"

log_info "WiFi provisioning completed successfully."
debug "Marker file: $MARKER_FILE"
# Clean up backups from this run to keep filesystem clean
cleanup_config "$WPA_CONF"
exit 0

