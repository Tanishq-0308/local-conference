#!/usr/bin/env bash
#
# Starts MiroTalk SFU with the announced WebRTC IP auto-detected from the
# machine's current active network. Re-detects on every launch, so moving the
# system to a different WiFi/LAN just works — no need to edit .env by hand.
#
set -euo pipefail

cd "$(dirname "$0")"

# Active LAN IP = the source address the kernel would use to reach the internet
# (i.e. the IP on the interface with the default route). Falls back gracefully.
detect_ip() {
    local ip
    ip="$(ip -o route get 8.8.8.8 2>/dev/null | awk '{for (i=1;i<=NF;i++) if ($i=="src") {print $(i+1); exit}}')"
    if [ -z "${ip:-}" ]; then
        # Fallback: first non-loopback, non-docker IPv4.
        ip="$(ip -4 -o addr show scope global 2>/dev/null \
              | awk '{print $4}' | cut -d/ -f1 \
              | grep -vE '^(172\.1[7-9]|172\.2[0-9]|172\.3[01])\.' | head -1)"
    fi
    echo "${ip:-127.0.0.1}"
}

LAN_IP="$(detect_ip)"
export SFU_ANNOUNCED_IP="$LAN_IP"

echo "================================================================"
echo " MiroTalk SFU starting"
echo "   Announced WebRTC IP : $SFU_ANNOUNCED_IP   (auto-detected)"
echo "   Join from this PC   : https://localhost:3010"
echo "   Join from LAN       : https://$LAN_IP:3010"
echo "================================================================"

exec npm start
