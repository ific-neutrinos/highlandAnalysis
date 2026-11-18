#!/bin/bash
# Lista de URLs xrootd para el jobscript, a partir de una definición de SAM (en dunegpvm).
#
#   make_filelist.sh <definicion_sam> <N> <salida.txt>
#
# Toma N ficheros de la definición, escribe sus URLs xrootd en <salida.txt> y crea la definición
# ${USER}_<definicion>_N<N> con exactamente esos ficheros, para el prestage (sacarlos de cinta):
#   samweb prestage-dataset --defname=<esa definición>
# Si N cubre toda la definición, no crea ninguna: el prestage se hace con la original.
set -u
# Opciones globales de samweb, p. ej. SAMWEB_OPTS=--no-cert-auth (con token: justin get-token)
SAMWEB_OPTS=${SAMWEB_OPTS:-}
[[ $# -lt 3 ]] && { sed -n '2,9p' "$0"; exit 1; }
DEF=$1; N=$2; OUT=$3
SUB="${USER}_${DEF}_N${N}"

files=$(samweb $SAMWEB_OPTS list-files "defname: $DEF with limit $N") || { echo "ERROR: samweb list-files"; exit 1; }
[[ -z "$files" ]] && { echo "ERROR: la definición $DEF no tiene ficheros"; exit 1; }

{
    echo "# $N ficheros de $DEF ($(date -I)); definición para el prestage: $SUB"
    for f in $files; do
        url=$(samweb $SAMWEB_OPTS get-file-access-url --schema=root "$f" | head -1)
        [[ -z "$url" ]] && { echo "AVISO: sin URL para $f" >&2; continue; }
        echo "$url"
    done
} > "$OUT"
echo "$(grep -c -v '^#' "$OUT") ficheros en $OUT"

# Definición con exactamente estos ficheros (no "with limit", cuyo orden no es fijo). Si son
# todos los de la definición, basta con ella. Si no, por bloques de 500 nombres (todos en un
# argumento pasan del límite de la línea de comandos: "Argument list too long" con 7.307) y una
# definición que los une.
ntot=$(samweb $SAMWEB_OPTS count-definition-files "$DEF")
if [[ "$N" -ge "$ntot" ]]; then
    SUB=$DEF
    echo "La lista tiene todos los ficheros de $DEF ($ntot): para el prestage, la propia $DEF"
else
    mapfile -t names < <(grep -v '^#' "$OUT" | xargs -n1 basename)
    parts=()
    ok=1
    for ((i = 0; i < ${#names[@]}; i += 500)); do
        part="${SUB}_p$((i/500))"
        list=$(printf '%s\n' "${names[@]:i:500}" | paste -sd, -)
        if samweb $SAMWEB_OPTS create-definition "$part" "file_name $list"; then parts+=("defname: $part")
        else ok=0; echo "AVISO: no se pudo crear $part (¿ya existe? samweb delete-definition $part)"; fi
    done
    union=$(printf '%s\n' "${parts[@]}" | paste -sd' ' - | sed 's/ defname:/ or defname:/g')
    if [[ $ok -eq 1 ]] && samweb $SAMWEB_OPTS create-definition "$SUB" "$union"; then
        echo "Creada la definición $SUB (${#parts[@]} bloques de 500)"
    else
        echo "AVISO: no se pudo crear $SUB (¿ya existe? samweb delete-definition $SUB y sus ${SUB}_p*, y repetir)"
    fi
fi
echo "Ficheros en $SUB: $(samweb $SAMWEB_OPTS count-definition-files "$SUB")"
echo "Prestage: samweb $SAMWEB_OPTS prestage-dataset --defname=$SUB"
echo "Localización del primer fichero (enstore = cinta):"
samweb $SAMWEB_OPTS locate-file "$(echo "$files" | head -1)"
