#!/bin/bash
# Copia ficheros a /pnfs/dune/persistent/users/$USER (en dunegpvm) con ifdh, la herramienta
# recomendada por DUNE para mover datos a dCache. Nunca por NFS.
#
#   to_persistent.sh <origen> <destino_en_persistent> [patrón]
#
# <origen>: un directorio local (p. ej. /exp/dune/data/...) o uno de /pnfs/dune/... (p. ej. el
# scratch). <destino_en_persistent>: ruta /pnfs/dune/persistent/users/$USER/...
# [patrón]: glob de los ficheros (por defecto '*.root').
#
# Autenticación: token interactivo de DUNE (en un fichero propio, ver BEARER_TOKEN_FILE abajo), el que tiene storage.create:/persistent/users/$USER
# (el de por defecto no; 20-nov-2026). ifdh usa el token de $BEARER_TOKEN_FILE con
# IFDH_TOKEN_ENABLE=1, y con IFDH_PROXY_ENABLE=0 no intenta el proxy X.509 (en la dunegpvm del
# token interactivo no suele haber uno válido: "Auth failed", 23-nov-2026).
# El token se renueva cada RENEW ficheros (100 por defecto) con el refresh token, sin navegador.
# ifdh elige el protocolo para las rutas /pnfs; IFDH_FORCE (por defecto https, WebDAV) lo fija.
#
# No sobrescribe: salta los ficheros que ya están en el destino con el mismo tamaño (se puede
# relanzar tal cual si se corta). Escribe los fallos de esta ejecución, con el error de ifdh, en
# to_persistent_failed.txt (directorio actual) y para tras MAXCONSEC (20) fallos seguidos.
# Variables: RENEW, MAXCONSEC, IFDH_FORCE, DRYRUN=1 (solo dice qué haría).
set -u
[[ $# -lt 2 ]] && { sed -n '2,22p' "$0"; exit 1; }
SRC=${1%/}; DEST=${2%/}; PATTERN=${3:-*.root}
RENEW=${RENEW:-100}
MAXCONSEC=${MAXCONSEC:-20}
FORCE=${IFDH_FORCE:-https}
FAILED=$PWD/to_persistent_failed.txt

[[ "$DEST" == /pnfs/dune/persistent/users/* ]] || { echo "ERROR: el destino tiene que estar en /pnfs/dune/persistent/users/"; exit 1; }
command -v ifdh > /dev/null || { echo "ERROR: no hay ifdh (carga el entorno de dunesw)"; exit 1; }
# Fichero de token propio: el de por defecto (/run/user/<uid>/bt_u<uid>) lo comparten todas las sesiones de la máquina
# y samweb o justIN lo cambian por el suyo. htgettoken e ifdh leen y escriben el de BEARER_TOKEN_FILE.
export BEARER_TOKEN_FILE=${PERSIST_TOKEN_FILE:-/tmp/bt_interactive_u$(id -u)}
export IFDH_TOKEN_ENABLE=1
export IFDH_PROXY_ENABLE=0
# Sin proxy X.509 (26-nov-2026): aunque IFDH_PROXY_ENABLE=0, Davix (gfal) presenta el proxy de /tmp/x509up_u<uid> si
# existe, y el que deja "justin get-token" (CN=justin-jobs-no-roles) hace que dCache responda HTTP 401 al leer, con un
# token válido. Apuntando a un fichero que no existe, Davix avisa ("impossible to open") y usa solo el token.
export X509_USER_PROXY=${PERSIST_X509_USER_PROXY:-/tmp/no_proxy_to_persistent_u$(id -u)}
export IFDH_CP_MAXRETRIES=${IFDH_CP_MAXRETRIES:-2}

renew(){ htgettoken -i dune --vaultserver htvaultprod.fnal.gov -r interactive > /dev/null 2>&1 \
           || { echo "ERROR: no se pudo renovar el token (htgettoken -r interactive a mano)"; exit 1; }; }
size_of(){ stat -c %s "$1" 2>/dev/null || echo -1; }   # solo lee metadatos (también en /pnfs)

renew
httokendecode -H 2>/dev/null | grep -q "storage.create:/persistent/users/$USER" \
  || { echo "ERROR: el token no tiene storage.create:/persistent/users/$USER (¿-r interactive?)"; exit 1; }

[[ -n "${DRYRUN:-}" ]] || ifdh mkdir_p "$DEST" --force=$FORCE > /dev/null 2>&1 || true

mapfile -t FILES < <(find "$SRC/" -maxdepth 1 -type f -name "$PATTERN" -printf '%f\n' | sort)
echo "Ficheros en $SRC ($PATTERN): ${#FILES[@]} -> $DEST (ifdh, --force=$FORCE)"
n=0; ok=0; skip=0; bad=0; consec=0
: > "$FAILED"
fin(){ echo "Fin: copiados $ok, ya estaban $skip, fallos $bad (de ${#FILES[@]})"; }
check_consec(){ (( consec >= MAXCONSEC )) && { echo "ERROR: $consec fallos seguidos; para. Último: $(tail -1 "$FAILED")"; fin; exit 1; }; }
for f in "${FILES[@]}"; do
  n=$((n+1))
  ssize=$(size_of "$SRC/$f")
  if [[ "$(size_of "$DEST/$f")" == "$ssize" ]]; then skip=$((skip+1)); continue; fi
  if [[ -n "${DRYRUN:-}" ]]; then echo "copiaría $f ($ssize B)"; continue; fi
  (( (ok+bad) % RENEW == RENEW-1 )) && renew
  if err=$(ifdh cp --force=$FORCE "$SRC/$f" "$DEST/$f" 2>&1) && [[ "$(size_of "$DEST/$f")" == "$ssize" ]]; then
    ok=$((ok+1)); consec=0
  else
    echo "$f ifdh: $(echo "$err" | grep -v '^\s*$' | tail -1) (tamaño en destino $(size_of "$DEST/$f") de $ssize)" >> "$FAILED"
    bad=$((bad+1)); consec=$((consec+1)); check_consec
  fi
  (( n % 100 == 0 )) && echo "[avance] $n de ${#FILES[@]}: copiados $ok, ya estaban $skip, fallos $bad"
done
fin
(( bad > 0 )) && echo "Fallos en $FAILED: relanzar el mismo comando (salta los que ya están)"
exit 0
