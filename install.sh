#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -Eeuo pipefail
readonly SCRIPT_URL="https://raw.githubusercontent.com/0157Martin/caddy-manager/main/caddy-manager.sh"
readonly COMMAND="/usr/local/bin/caddy-manager"

[[ ${EUID:-$(id -u)} -eq 0 ]] || { echo '请使用 root 运行。' >&2; exit 1; }
action=${1:-install}
case "$action" in
  install)
    temporary=$(mktemp)
    trap 'rm -f -- "$temporary"' EXIT
    curl --fail --show-error --location --retry 3 "$SCRIPT_URL" -o "$temporary"
    bash -n "$temporary"
    grep -q '^# SPDX-License-Identifier: GPL-3.0-or-later$' "$temporary"
    install -m 755 "$temporary" "$COMMAND"
    "$COMMAND" install
    ;;
  verify|test) [[ -x $COMMAND ]] || { echo 'caddy-manager 尚未安装。' >&2; exit 1; }; "$COMMAND" verify ;;
  uninstall)
    if [[ -x $COMMAND ]]; then "$COMMAND" uninstall; fi
    rm -f -- "$COMMAND"
    ;;
  *) echo '用法：install.sh <install|verify|uninstall>' >&2; exit 1 ;;
esac
