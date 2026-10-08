#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -Eeuo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
sandbox=$(mktemp -d)
trap 'rm -rf -- "$sandbox"' EXIT
export CADDY_CONFIG="$sandbox/Caddyfile"
export CADDY_SITE_DIR="$sandbox/sites"
export CADDY_WEB_ROOT="$sandbox/www"
export CADDY_BACKUP_DIR="$sandbox/backups"
export V2M_NODES_DIR="$sandbox/nodes"
export V2M_XRAY_CONFIG="$sandbox/xray.json"
# shellcheck disable=SC1091
source "$root/caddy-manager.sh"
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
mkdir -p "$CADDY_SITE_DIR" "$V2M_NODES_DIR"

static=$(mktemp); reverse=$(mktemp); xray=$(mktemp)
render_caddy_site static example.com '' "$static" || fail 'static render failed'
grep -Fq 'root *' "$static" || fail 'static root missing'
render_caddy_site reverse app.example.com 127.0.0.1:8080 "$reverse" || fail 'reverse render failed'
grep -Fq 'reverse_proxy 127.0.0.1:8080' "$reverse" || fail 'reverse upstream missing'
! valid_caddy_upstream 0.0.0.0:8080 || fail 'public upstream accepted'

cat > "$V2M_NODES_DIR/m1.env" <<'EOF'
PROFILE=vless-tls-xhttp
SERVER_NAME=cdn.example.com
PORT=24443
PATH_VALUE=/xhttp
EOF
cat > "$V2M_NODES_DIR/m2.env" <<'EOF'
PROFILE=vless-tls-ws
SERVER_NAME=cdn.example.com
PORT=24444
PATH_VALUE=/websocket
EOF
render_caddy_site xray cdn.example.com 127.0.0.1:24443 "$xray" /xhttp || fail 'xray render failed'
grep -Fq 'h2c://127.0.0.1:24443' "$xray" || fail 'h2c route missing'
grep -Fq '@xray_0 path /xhttp /xhttp/*' "$xray" || fail 'path matcher missing'
grep -Fq '@xray_1 path /websocket /websocket/*' "$xray" || fail 'WebSocket route missing'
grep -Fq 'https://127.0.0.1:24444' "$xray" || fail 'WebSocket upstream missing'
grep -Fq 'versions 1.1' "$xray" || fail 'WebSocket upstream did not require HTTP/1.1'
! render_caddy_site xray cdn.example.com 127.0.0.1:24443 "$xray" '/bad path' || fail 'invalid path accepted'
printf '%s\n' 'Caddy unit tests passed.'
