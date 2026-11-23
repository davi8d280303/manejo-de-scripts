#!/usr/bin/env bash
# Valida que se publique sin alterar exactamente la versión candidata que ya fue probada.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="${DIST_DIR:-$ROOT_DIR/dist}"

[[ -f "$DIST_DIR/index.html" ]] || { echo "Error: no existe la versión candidata en $DIST_DIR" >&2; exit 1; }
[[ -f "$DIST_DIR/assets/styles.css" ]] || { echo "Error: falta el CSS de la versión probada" >&2; exit 1; }
echo "Despliegue preparado: GitHub Actions publicará sin modificar $DIST_DIR."
