#!/usr/bin/env bash
#
# Starts MiroTalk SFU in Docker with the announced WebRTC IP auto-detected from
# the machine's current active network. Re-detects on every launch, so moving
# the system to a different WiFi/LAN just works.
#
set -euo pipefail

cd "$(dirname "$0")"

source ./ot-prepare.sh

echo "================================================================"
echo " MiroTalk SFU (Docker) starting"
echo "   Announced WebRTC IP : $SFU_ANNOUNCED_IP   (auto-detected)"
echo "   Join from this PC   : https://localhost:3010"
echo "   Join from LAN       : ${LAN_ORIGIN:-https://$LAN_IP:3010}${FALLBACK_ORIGIN:+   (or $FALLBACK_ORIGIN)}"
echo "================================================================"

# Use `docker run` directly — the Compose v1 binary on this host is broken and
# the v2 plugin isn't installed. These flags mirror docker-compose.yml.
# Fully local: no `docker pull`. It downloaded ~1.3 GB from the internet on every start,
# delayed the server (the app's window opened on a "not found" page) and could switch to a
# newer MiroTalk version silently. The image is pinned to the local tag `ot-local`; to
# update on purpose: docker pull mirotalk/sfu:latest && docker tag mirotalk/sfu:latest mirotalk/sfu:ot-local
docker rm -f mirotalksfu >/dev/null 2>&1 || true

SSL_MOUNT=()
if [ "$OT_HAS_OWN_CERT" = 1 ]; then
    SSL_MOUNT=(-v "$PWD/app/ssl-ot/cert.pem:/src/app/ssl/cert.pem:ro" -v "$PWD/app/ssl-ot/key.pem:/src/app/ssl/key.pem:ro")
    echo "   Certificate         : this machine's own (app/ssl-ot)"
else
    echo "   Certificate         : MiroTalk demo certificate - run ot_qt_app/scripts/setup-conference.sh"
fi

exec docker run -d \
    --name mirotalksfu \
    --hostname mirotalksfu \
    --restart unless-stopped \
    --network host \
    -e SFU_ANNOUNCED_IP="$SFU_ANNOUNCED_IP" \
    -v "$PWD/app/src/config.js:/src/app/src/config.js:ro" \
    -v "$PWD/.env:/src/.env:ro" \
    -v "$PWD/public:/src/public:ro" \
    "${SSL_MOUNT[@]}" \
    mirotalk/sfu:ot-local
