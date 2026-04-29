#!/usr/bin/env bash
set -euo pipefail

step() { printf '\033[1;34m==> %s\033[0m\n' "$*"; }
ok()   { printf '\033[1;32mok %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m!! %s\033[0m\n' "$*"; }

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${ROOT_DIR}"

UNIT="uavlogviewer.service"
UNIT_SRC="${ROOT_DIR}/systemd/${UNIT}"
UNIT_DST="/etc/systemd/system/${UNIT}"

step "ensure .env"
if [ ! -f .env ]; then
  cp .env.example .env
  warn ".env created from .env.example — fill in VUE_APP_CESIUM_TOKEN before continuing"
  exit 1
fi

step "build image"
docker compose build

step "install systemd unit"
sudo install -m 0644 "${UNIT_SRC}" "${UNIT_DST}"
sudo systemctl daemon-reload
sudo systemctl enable "${UNIT}"
sudo systemctl restart "${UNIT}"

step "smoke test"
sleep 2
if curl -fsS -o /dev/null http://127.0.0.1:8080; then
  ok "uavlogviewer responding on 127.0.0.1:8080"
else
  warn "uavlogviewer not responding yet — check: journalctl -u ${UNIT} -e"
  exit 1
fi

step "done. catalog in gg-env/services.yaml uses container 'uavlogviewer-web-1'."
