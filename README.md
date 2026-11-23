# Manejo de Scripts

Actividad escolar: un sitio estático de horarios se prepara en `dist/`, se prueba por HTTP y, al integrar en `main`, GitHub Actions lo publica con GitHub Pages.

## Requisitos

- Git y Bash.
- Python 3 disponible como `python3` y `curl`. En Linux Mint: `sudo apt install python3 curl`.
- En Windows, instala Git for Windows y ejecuta los comandos desde **Git Bash**. La prueba usa Python 3 cuando existe; como alternativa local usa el Perl incluido con Git Bash. Si el comando de Python se llama `python`, usa `PYTHON_BIN=python bash scripts/probar.sh`.

## Ejecución local

En Linux Mint:

```bash
bash scripts/preparar.sh
bash scripts/probar.sh
```

En Windows con Git Bash:

```bash
bash scripts/preparar.sh
bash scripts/probar.sh
```

Para comprobar el caso fallido sin dañar `dist/`, crea una copia temporal, elimina su CSS y dirige la prueba a ella:

```bash
cp -R dist /tmp/horarios-sin-css
rm /tmp/horarios-sin-css/assets/styles.css
DIST_DIR=/tmp/horarios-sin-css bash scripts/probar.sh
bash scripts/probar.sh
```

## Publicación en GitHub Pages

1. Sube el repositorio a GitHub y deja estos archivos en la rama `main`.
2. En el repositorio, abre **Settings > Pages** y selecciona **Source: GitHub Actions**.
3. Abre la pestaña **Actions** para consultar “Liberar y desplegar horarios”. Los pull requests a `main` solo preparan y prueban; los push a `main` también publican si todo pasa.
4. Cuando termine un despliegue exitoso, la URL real aparece en el resumen del trabajo “Publicar en GitHub Pages” y en **Settings > Pages**.

