# Manejo de Scripts para la liberación y despliegue continuo de un sitio de horarios de laboratorio

## Introducción

El laboratorio universitario necesita publicar horarios sin que una edición incompleta llegue al sitio. El objetivo de esta práctica es automatizar la creación de una versión candidata, sus pruebas y su despliegue en GitHub Pages. Se emplean HTML y CSS para el sitio, Bash para los scripts y GitHub Actions para la integración y la publicación continua.

## 1. Justificación del flujo de trabajo

El flujo definido en `.github/workflows/release.yml` se activa en cada `pull_request` dirigido a `main` y en cada `push` a `main`. En ambos casos, el trabajo `verificar` prepara `dist/` y ejecuta las pruebas. Por tanto, un cambio propuesto se revisa antes de integrarse. En un `push` a `main`, el trabajo `desplegar` depende de `verificar` mediante `needs: verificar`; GitHub Actions no lo inicia si falla la preparación o una prueba.

Las pruebas se realizan antes del despliegue para evitar errores concretos: una respuesta HTTP inexistente detecta que el sitio no puede servirse; la ausencia de `table`, `tbody` o “Laboratorio” detecta un horario omitido o una página equivocada; y la ausencia o respuesta fallida del CSS detecta una referencia rota. La versión que supera esas pruebas se guarda como el artefacto `sitio-verificado`; el trabajo de despliegue descarga ese mismo artefacto, valida su estructura con `desplegar.sh` y lo entrega a Pages. Así, no se vuelve a construir un contenido diferente para publicar.

## 2. Entorno requerido para la liberación y el despliegue continuo

El ejecutor remoto es `ubuntu-latest`, que proporciona Bash, Python 3, `curl`, Git y el entorno de GitHub Actions. `scripts/preparar.sh` verifica Bash, `cp` y `find`, y crea una carpeta `dist/` limpia con `index.html` y `assets/styles.css`. `scripts/probar.sh` usa Python 3 para servir esta carpeta y `curl` para consultarla. Como ayuda para ejecución local en Git Bash sin Python, el mismo script puede usar `scripts/servidor.pl`, incluido para ese caso.

El destino de publicación es el entorno protegido `github-pages`. La publicación remota no la hace Bash: `scripts/desplegar.sh` únicamente confirma que la versión probada sigue completa. Los pasos `actions/upload-pages-artifact@v3` y `actions/deploy-pages@v4` suben el artefacto y realizan la publicación, respectivamente. En GitHub se debe configurar **Settings > Pages > Source > GitHub Actions** y permitir Actions en el repositorio.

## 3. Niveles de servicio acordados

Los siguientes valores son metas propuestas para un caso académico, no resultados medidos. La disponibilidad mensual objetivo es de 99 %. Se comprobaría con una sonda HTTP externa que registre respuestas exitosas frente al total de mediciones; la fórmula sería `(mediciones correctas / mediciones totales) × 100`.

La segunda meta es que un cambio integrado en `main` sea visible en un máximo de 10 minutos. Se mediría restando la hora del `push` integrado de la hora en que el trabajo de Pages informa la URL o una sonda externa observa el cambio. Aunque ya existe una ejecución remota exitosa, no se reporta un tiempo medido mientras no se registren ambos momentos para ese cálculo.

## 4. Métricas para el monitoreo de la aplicación

| Métrica | Forma de cálculo | Fuente de datos | Frecuencia | Estado actual |
| --- | --- | --- | --- | --- |
| Disponibilidad del sitio | `(HTTP 2xx / solicitudes totales) × 100` | Sonda HTTP externa y registros de GitHub Pages | Cada 5 minutos; resumen mensual | Sitio publicado; disponibilidad mensual aún sin medir. |
| Éxito del pipeline | `(ejecuciones exitosas / ejecuciones totales) × 100` | [Ejecución #2, intento 2 de GitHub Actions](https://github.com/davi8d280303/manejo-de-scripts/actions/runs/45101791254/attempts/2) | Por ejecución y resumen mensual | Observado: la ejecución #2, intento 2, terminó correctamente. No se calcula un porcentaje con una sola evidencia registrada. |
| Duración de liberación | Hora final de despliegue − hora del push a `main` | Tiempos del workflow y del despliegue | Cada integración | Despliegue remoto observado en la ejecución #2, intento 2; tiempo total aún sin medir. |
| Resultado local de preparación | Código de salida de `bash scripts/preparar.sh` | Consola local | Antes de entregar | Medido: correcto en esta sesión; creó `dist/index.html` y `dist/assets/styles.css`. |
| Resultado local de prueba HTTP | Código de salida de `bash scripts/probar.sh` | Consola local | Antes de entregar | Medido: caso exitoso con código `0`; caso sin CSS con código `1` esperado. |

La disponibilidad del sitio y el resultado del pipeline son métricas distintas: una URL puede responder aunque un pipeline posterior falle, y un pipeline puede pasar sin que una sonda externa haya medido la URL.

## 5. Parámetros de configuración de las herramientas utilizadas

| Parámetro | Valor real | Archivo o lugar | Función |
| --- | --- | --- | --- |
| Rama | `main` | `release.yml` | Limita PR y push que activan el flujo. |
| Eventos | `pull_request`, `push` | `release.yml` | Verifica propuestas e integra/publica cambios. |
| Ejecutor | `ubuntu-latest` | `release.yml` | Aporta el entorno de CI. |
| Versión candidata | `dist/` | `scripts/preparar.sh` | Contiene solo los archivos estáticos que se prueban. |
| Preparación | `bash scripts/preparar.sh` | `release.yml` | Genera la versión candidata limpia. |
| Pruebas | `bash scripts/probar.sh` | `release.yml` | Sirve y verifica HTML, horarios y CSS. |
| Artefacto | `sitio-verificado` | `release.yml` | Conserva exactamente el contenido aprobado. |
| Ruta del artefacto Pages | `dist` | `release.yml` | Indica el contenido que se carga a Pages. |
| Entorno | `github-pages` | `release.yml` | Identifica el destino de despliegue. |
| Acción de publicación | `actions/deploy-pages@v4` | `release.yml` | Publica remotamente el artefacto. |

## Evidencia de los cuatro tipos de scripts

| Tipo solicitado | Archivo | Evidencia verificable |
| --- | --- | --- |
| Flujo de trabajo | `.github/workflows/release.yml` | Eventos para `main`, trabajos `verificar` y `desplegar`, y dependencia `needs: verificar`. [Ejecución #2, intento 2](https://github.com/davi8d280303/manejo-de-scripts/actions/runs/45101791254/attempts/2) correcta para el commit `83615a2`. |
| Generación del entorno de liberación | `scripts/preparar.sh` | Crea `dist/` limpio y lista sus archivos. Ejecución local observada: correcta. |
| Pruebas en el entorno de liberación | `scripts/probar.sh` | Inicia servidor HTTP, verifica tabla/horario/CSS y usa `trap` para cerrarlo. Sintaxis y caso exitoso: código `0`; copia sin CSS: código `1` esperado y mensaje de error específico. |
| Generación del despliegue | `scripts/desplegar.sh` | Valida `dist/`; `upload-pages-artifact` y `deploy-pages` del workflow hacen la publicación remota. La ejecución correcta publicó el [sitio en GitHub Pages](https://davi8d280303.github.io/manejo-de-scripts/). |

Evidencia remota disponible: [repositorio de GitHub](https://github.com/davi8d280303/manejo-de-scripts), [ejecución exitosa de GitHub Actions (#2, intento 2)](https://github.com/davi8d280303/manejo-de-scripts/actions/runs/45101791254/attempts/2) y [sitio publicado en GitHub Pages](https://davi8d280303.github.io/manejo-de-scripts/). La ejecución publicada corresponde al commit `83615a2`.

## Registro de verificación local

Comandos ejecutados en esta sesión:

```bash
bash scripts/preparar.sh
bash scripts/probar.sh
```

La preparación terminó correctamente y generó `dist/index.html` y `dist/assets/styles.css`. También se ejecutó la revisión de sintaxis `bash -n scripts/probar.sh`, que terminó con código `0`. Con `dist/` intacto, `bash scripts/probar.sh` terminó con código `0`: la página, la tabla de horarios y el CSS respondieron correctamente por HTTP.

```bash
bash scripts/preparar.sh
bash scripts/probar.sh
cp -R dist /tmp/horarios-sin-css
rm /tmp/horarios-sin-css/assets/styles.css
DIST_DIR=/tmp/horarios-sin-css bash scripts/probar.sh
bash scripts/probar.sh
```

Sobre una copia temporal sin `assets/styles.css`, la prueba terminó con código `1` y mostró exactamente `Error de prueba: no existe el CSS referenciado: assets/styles.css`. El código `1` era el resultado esperado del caso de fallo controlado: demuestra que el script detecta que falta la hoja de estilos referenciada. Al finalizar se confirmó que `dist/index.html` y `dist/assets/styles.css` seguían presentes en la versión original. Esta evidencia local es distinta de la ejecución remota: la [ejecución #2, intento 2](https://github.com/davi8d280303/manejo-de-scripts/actions/runs/45101791254/attempts/2) pasó las pruebas y publicó correctamente en GitHub Pages el commit `83615a2`. La dependencia `needs: verificar` impide que el trabajo de despliegue se ejecute si las pruebas fallan.
