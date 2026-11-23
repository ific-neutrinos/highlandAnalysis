#!/bin/bash
# Copia ficheros a /pnfs/dune/persistent/users/$USER (en dunegpvm), sin copias por NFS a dCache.
#
#   to_persistent.sh <origen> <destino_en_persistent> [patrón]
#
# <origen>: un directorio local (p. ej. /exp/dune/data/...) o uno de /pnfs/dune/... (se baja cada
# fichero por WebDAV a un temporal, con el mismo token; no hace falta proxy X.509). <destino_en_persistent>: ruta /pnfs/dune/persistent/users/$USER/...
# [patrón]: glob de los ficheros (por defecto '*.root').
#
# Sube por HTTPS (WebDAV de dCache, puerto 2880) con curl y el token interactivo de DUNE, que es el
# que tiene storage.create:/persistent/users/$USER (el de por defecto no; 20-nov-2026). El xrdcp
# del contenedor SL7 no sabe usar tokens (aviso de secztn), por eso curl, también para bajar.
# Antes, una vez: htgettoken -i dune --vaultserver htvaultprod.fnal.gov -r interactive
# El token se renueva cada RENEW ficheros (100 por defecto) con el refresh token, sin navegador.
#
# No sobrescribe: salta los ficheros que ya están en el destino con el mismo tamaño (se puede
# relanzar tal cual si se corta). Escribe los fallos en to_persistent_failed.txt (directorio
# actual; se vacía en cada ejecución) con el mensaje de error. Para tras MAXCONSEC (20) fallos
# seguidos. Variables: RENEW, TMPDIR_COPY (temporal para los de /pnfs; por defecto
# /tmp/to_persistent_$USER), DRYRUN=1 (solo dice qué haría).
set -u
[[ $# -lt 2 ]] && { sed -n '2,20p' "$0"; exit 1; }
SRC=${1%/}; DEST=${2%/}; PATTERN=${3:-*.root}
RENEW=${RENEW:-100}
TMPC=${TMPDIR_COPY:-/tmp/to_persistent_$USER}
FAILED=$PWD/to_persistent_failed.txt

[[ "$DEST" == /pnfs/dune/persistent/users/* ]] || { echo "ERROR: el destino tiene que estar en /pnfs/dune/persistent/users/"; exit 1; }
export BEARER_TOKEN_FILE=${BEARER_TOKEN_FILE:-/run/user/$(id -u)/bt_u$(id -u)}
export X509_CERT_DIR=${X509_CERT_DIR:-/cvmfs/oasis.opensciencegrid.org/mis/certificates}

renew(){ htgettoken -i dune --vaultserver htvaultprod.fnal.gov -r interactive > /dev/null 2>&1 \
           || { echo "ERROR: no se pudo renovar el token (htgettoken -r interactive a mano)"; exit 1; }; }
https_of(){ echo "https://fndcadoor.fnal.gov:2880/dune/${1#/pnfs/dune/}"; }
size_of(){  stat -c %s "$1" 2>/dev/null || echo -1; }   # solo lee metadatos (también en /pnfs)
# -L --location-trusted: la puerta de dCache responde 307 y manda los datos a un pool (otro host);
# sin -L curl crea el fichero vacío y para, y sin --location-trusted no reenvía el token al pool
dav(){ curl -sS -L --location-trusted --capath "$X509_CERT_DIR" -H "Authorization: Bearer $(cat "$BEARER_TOKEN_FILE")" "$@"; }

renew
httokendecode -H 2>/dev/null | grep -q "storage.create:/persistent/users/$USER" \
  || { echo "ERROR: el token no tiene storage.create:/persistent/users/$USER (¿-r interactive?)"; exit 1; }

# crea el destino (y sus padres) por WebDAV: 201 creado, 405 ya existía
path=/pnfs/dune/persistent/users/$USER
for part in $(echo "${DEST#/pnfs/dune/persistent/users/$USER}" | tr '/' ' '); do
  path=$path/$part
  [[ -n "${DRYRUN:-}" ]] || dav -X MKCOL "$(https_of "$path")" -o /dev/null
done

FROM_PNFS=0; [[ "$SRC" == /pnfs/dune/* ]] && { FROM_PNFS=1; mkdir -p "$TMPC"; }
mapfile -t FILES < <(find "$SRC/" -maxdepth 1 -type f -name "$PATTERN" -printf '%f\n' | sort)
echo "Ficheros en $SRC ($PATTERN): ${#FILES[@]} -> $DEST"
n=0; ok=0; skip=0; bad=0; consec=0
MAXCONSEC=${MAXCONSEC:-20}
# con MAXCONSEC fallos seguidos para (algo general: token, proxy, /tmp lleno...) en vez de recorrer la lista entera
check_consec(){ (( consec >= MAXCONSEC )) && { echo "ERROR: $consec fallos seguidos; para. Último: $(tail -1 "$FAILED")"; echo "Fin: copiados $ok, ya estaban $skip, fallos $bad (de ${#FILES[@]})"; exit 1; }; }
: > "$FAILED"   # solo los fallos de esta ejecución
for f in "${FILES[@]}"; do
  n=$((n+1))
  ssize=$(size_of "$SRC/$f")
  if [[ "$(size_of "$DEST/$f")" == "$ssize" ]]; then skip=$((skip+1)); continue; fi
  if [[ -n "${DRYRUN:-}" ]]; then echo "copiaría $f ($ssize B)"; continue; fi
  (( (ok+bad) % RENEW == RENEW-1 )) && renew
  local_file="$SRC/$f"
  if (( FROM_PNFS )); then
    local_file="$TMPC/$f"
    # bajada por WebDAV con el mismo token (el xrdcp del contenedor usa el proxy X.509, que en una
    # dunegpvm con el token interactivo no suele estar: "Auth failed (source)", 23-nov-2026)
    gcode=$(dav "$(https_of "$SRC/$f")" -o "$local_file" -w "%{http_code}" 2>&1 | tail -c 3)
    if [[ "$gcode" != 200 || "$(size_of "$local_file")" != "$ssize" ]]; then
      echo "$f bajada http=$gcode (tamaño $(size_of "$local_file") de $ssize)" >> "$FAILED"; rm -f "$local_file"
      bad=$((bad+1)); consec=$((consec+1)); check_consec; continue
    fi
  fi
  code=$(dav -T "$local_file" "$(https_of "$DEST/$f")" -o /dev/null -w "%{http_code}")
  (( FROM_PNFS )) && rm -f "$local_file"
  if [[ "$code" == 201 || "$code" == 204 ]] && [[ "$(size_of "$DEST/$f")" == "$ssize" ]]; then ok=$((ok+1)); consec=0
  else echo "$f http=$code" >> "$FAILED"; bad=$((bad+1)); consec=$((consec+1)); check_consec; fi
  (( n % 100 == 0 )) && echo "[avance] $n de ${#FILES[@]}: copiados $ok, ya estaban $skip, fallos $bad"
done
echo "Fin: copiados $ok, ya estaban $skip, fallos $bad (de ${#FILES[@]})"
(( bad > 0 )) && echo "Fallos en $FAILED: relanzar el mismo comando (salta los que ya están)"
