#!/bin/bash
# Lista de URLs xrootd para el jobscript, a partir de una definición de SAM (en dunegpvm).
#
#   make_filelist.sh <definicion_sam> <N> <salida.txt> [--prestage]
#
# Con --prestage crea la definición ${USER}_<definicion>_N<N> con los mismos N ficheros y pide
# que se traigan de cinta a disco (si no, los trabajos se quedan esperando la cinta).
set -u
# Opciones globales de samweb, p. ej. SAMWEB_OPTS=--no-cert-auth (con token: justin get-token)
SAMWEB_OPTS=${SAMWEB_OPTS:-}
[[ $# -lt 3 ]] && { sed -n '2,7p' "$0"; exit 1; }
DEF=$1; N=$2; OUT=$3; PRESTAGE=${4:-}

DIM="defname: $DEF with limit $N"
files=$(samweb $SAMWEB_OPTS list-files "$DIM") || { echo "ERROR: samweb list-files"; exit 1; }
[[ -z "$files" ]] && { echo "ERROR: la definición $DEF no tiene ficheros"; exit 1; }

{
    echo "# $DIM  ($(date -I))"
    for f in $files; do
        url=$(samweb $SAMWEB_OPTS get-file-access-url --schema=root "$f" | head -1)
        [[ -z "$url" ]] && { echo "AVISO: sin URL para $f" >&2; continue; }
        echo "$url"
    done
} > "$OUT"
echo "$(grep -c -v '^#' "$OUT") ficheros en $OUT"

# Dónde están (enstore = cinta detrás de dCache)
echo "Localizaciones del primer fichero:"
samweb $SAMWEB_OPTS locate-file "$(echo "$files" | head -1)"

if [[ "$PRESTAGE" == "--prestage" ]]; then
    SUB="${USER}_${DEF}_N${N}"
    samweb $SAMWEB_OPTS create-definition "$SUB" "$DIM" || echo "AVISO: no se pudo crear $SUB (¿ya existe?)"
    echo "Prestage de $SUB (puede tardar; se puede cortar y volver a lanzar):"
    samweb $SAMWEB_OPTS prestage-dataset --defname="$SUB"
fi
