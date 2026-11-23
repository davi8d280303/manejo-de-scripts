#!/usr/bin/env bash
# Sirve dist/ por HTTP y comprueba HTML, horarios y CSS. Siempre cierra el servidor.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="${DIST_DIR:-$ROOT_DIR/dist}"
SERVER_PID=""
PYTHON_CMD=()

cleanup() {
  if [[ -n "$SERVER_PID" ]] && kill -0 "$SERVER_PID" 2>/dev/null; then
    kill "$SERVER_PID" 2>/dev/null || true
    wait "$SERVER_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT INT TERM
fail() { echo "Error de prueba: $*" >&2; exit 1; }

command -v curl >/dev/null 2>&1 || fail "falta curl"
[[ -f "$DIST_DIR/index.html" ]] || fail "no existe $DIST_DIR/index.html"

# En Git Bash para Windows, `py -3` selecciona Python 3 aunque `python3` sea el
# alias de Microsoft Store. En Linux normalmente solo existe `python3`.
if command -v py >/dev/null 2>&1 && py -3 -c 'import sys; assert sys.version_info.major == 3' >/dev/null 2>&1; then
  PYTHON_CMD=(py -3)
elif command -v python3 >/dev/null 2>&1 && python3 -c 'import sys; assert sys.version_info.major == 3' >/dev/null 2>&1; then
  PYTHON_CMD=(python3)
else
  fail "no se encontró un intérprete funcional de Python 3 (se probaron: py -3 y python3)"
fi

PORT="$("${PYTHON_CMD[@]}" -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1]); s.close()')"
"${PYTHON_CMD[@]}" -m http.server "$PORT" --bind 127.0.0.1 --directory "$DIST_DIR" >"${TMPDIR:-/tmp}/horarios-http.log" 2>&1 &
SERVER_PID=$!

for _ in 1 2 3 4 5; do
  if curl --fail --silent --show-error "http://127.0.0.1:$PORT/" -o /tmp/horarios-index.html; then break; fi
  sleep 1
done
[[ -s /tmp/horarios-index.html ]] || fail "la página no respondió por HTTP"

grep -qi '<table' /tmp/horarios-index.html || fail "la página no contiene una tabla"
grep -qi '<tbody' /tmp/horarios-index.html || fail "la tabla no contiene horarios"
grep -qi 'Laboratorio' /tmp/horarios-index.html || fail "no se encontró al menos un horario de laboratorio"

CSS_PATH="$(sed -nE "s/.*href=[\\\"']([^\\\"']+\\.css)[\\\"'].*/\\1/p" /tmp/horarios-index.html | head -n 1)"
[[ -n "$CSS_PATH" ]] || fail "no se encontró una hoja de estilos CSS referenciada"
[[ -f "$DIST_DIR/$CSS_PATH" ]] || fail "no existe el CSS referenciado: $CSS_PATH"
curl --fail --silent --show-error "http://127.0.0.1:$PORT/$CSS_PATH" -o /tmp/horarios-styles.css \
  || fail "el CSS no se sirve correctamente: $CSS_PATH"
[[ -s /tmp/horarios-styles.css ]] || fail "el CSS servido está vacío: $CSS_PATH"

echo "Pruebas correctas: página, tabla con horarios y CSS disponibles por HTTP."
