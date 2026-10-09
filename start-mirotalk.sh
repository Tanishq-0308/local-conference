#!/usr/bin/env bash
#
# Runs MiroTalk SFU natively with Node.js (22 or newer), in the foreground: started by the
# ot-conference user service (ot-conference.service), which the OT app starts and stops.
# Re-detects the LAN IP on every start, so moving the machine to another network just works.
#
#   one-time: npm ci   (installs node_modules; needs internet)
#   run:      ./start-mirotalk.sh        or   systemctl --user start ot-conference
#
set -euo pipefail

cd "$(dirname "$0")"

NODE="${OT_NODE:-node}"
if ! command -v "$NODE" >/dev/null 2>&1; then
    echo "Node.js not found (install Node.js 22, or set OT_NODE)" >&2
    exit 1
fi
NODE_MAJOR="$("$NODE" -p 'process.versions.node.split(".")[0]')"
if [ "$NODE_MAJOR" -lt 22 ]; then
    echo "Node.js $("$NODE" --version) is too old: MiroTalk needs 22 or newer" >&2
    exit 1
fi
if [ ! -d node_modules ]; then
    echo "node_modules missing: run 'npm ci' in $(pwd) once" >&2
    exit 1
fi

source ./ot-prepare.sh

if [ "$OT_HAS_OWN_CERT" = 1 ]; then
    # Paths are relative to app/src (Server.js)
    export SERVER_SSL_CERT=../ssl-ot/cert.pem
    export SERVER_SSL_KEY=../ssl-ot/key.pem
    CERT_TEXT="this machine's own (app/ssl-ot)"
else
    CERT_TEXT="MiroTalk demo certificate - run ot_qt_app/scripts/setup-conference.sh"
fi

echo "================================================================"
echo " MiroTalk SFU (native, Node $("$NODE" --version)) starting"
echo "   Announced WebRTC IP : $SFU_ANNOUNCED_IP   (auto-detected)"
echo "   Join from this PC   : https://localhost:3010"
echo "   Join from LAN       : ${LAN_ORIGIN:-https://$LAN_IP:3010}${FALLBACK_ORIGIN:+   (or $FALLBACK_ORIGIN)}"
echo "   Certificate         : $CERT_TEXT"
echo "================================================================"

exec "$NODE" app/src/Server.js
