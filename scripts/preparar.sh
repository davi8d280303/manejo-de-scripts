#!/usr/bin/env bash
# Genera en dist/ una copia limpia y reproducible de los archivos estáticos.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="${DIST_DIR:-$ROOT_DIR/dist}"

for tool in bash cp find; do
  command -v "$tool" >/dev/null 2>&1 || { echo "Error: falta la herramienta requerida: $tool" >&2; exit 1; }
done

for source_file in "$ROOT_DIR/index.html" "$ROOT_DIR/assets/styles.css"; do
  [[ -f "$source_file" ]] || { echo "Error: no existe el archivo fuente $source_file" >&2; exit 1; }
done

[[ "$DIST_DIR" != "/" && -n "$DIST_DIR" ]] || { echo "Error: ruta dist no segura" >&2; exit 1; }
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR/assets"
cp "$ROOT_DIR/index.html" "$DIST_DIR/index.html"
cp "$ROOT_DIR/assets/styles.css" "$DIST_DIR/assets/styles.css"

echo "Versión candidata preparada en: $DIST_DIR"
find "$DIST_DIR" -type f -print | sort
