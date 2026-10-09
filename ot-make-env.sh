#!/usr/bin/env bash
# Builds this machine's .env: MiroTalk's .env.template, our settings (ot.env) and fresh random
# secrets (the template's JWT_SECRET / API_KEY_SECRET are public). Leaves an existing .env alone
# unless --force is given.
set -euo pipefail
cd "$(dirname "$0")"

if [ -f .env ] && [ "${1:-}" != "--force" ]; then
    echo ".env exists, left as it is (use --force to rebuild it)"
    exit 0
fi

python3 - <<'PY'
import re, secrets

settings = {}
for line in open("ot.env"):
    m = re.match(r"^([A-Z0-9_]+)=(.*)$", line.rstrip("\n"))
    if m:
        settings[m.group(1)] = m.group(2)
settings["JWT_SECRET"] = secrets.token_hex(32)
settings["API_KEY_SECRET"] = secrets.token_hex(32)

out = []
for line in open(".env.template"):
    m = re.match(r"^([A-Z0-9_]+)=(.*)$", line.rstrip("\n"))
    if m and m.group(1) in settings:
        out.append(f"{m.group(1)}={settings.pop(m.group(1))}\n")
    else:
        out.append(line)
for key, value in settings.items():   # in ot.env but not in the template
    out.append(f"{key}={value}\n")
open(".env", "w").write("".join(out))
PY
chmod 600 .env
echo ".env written (our settings, new secrets)"
