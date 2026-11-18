#!/bin/bash
# Estado del prestage de una lista de make_filelist.sh (en dunegpvm, donde /pnfs está montado).
#
#   check_locality.sh <lista.txt> [cada]
#
# Para cada URL xrootd de la lista lee la locality de dCache (fichero especial
# ".(get)(<nombre>)(locality)" en /pnfs) y cuenta cuántos hay de cada:
#   ONLINE_AND_NEARLINE  en disco (y en cinta): listo para leer
#   NEARLINE             solo en cinta: falta el prestage
#   ONLINE               solo en disco
# Con [cada] = k mira solo uno de cada k ficheros (para listas grandes; 7.300 ficheros tardan
# unos minutos). Con VERBOSE=1 escribe también los que no están en disco.
set -u
[[ $# -lt 1 ]] && { sed -n '2,12p' "$0"; exit 1; }
LIST=$1
STEP=${2:-1}

declare -A count
n=0
i=0
while read -r url; do
    [[ -z "$url" || "$url" == \#* ]] && continue
    i=$((i+1))
    (( (i-1) % STEP == 0 )) || continue
    # root://fndcadoor.fnal.gov:1094/pnfs/fnal.gov/usr/dune/... -> /pnfs/dune/...
    path=$(echo "$url" | sed -e 's|^root://[^/]*/||' -e 's|^/*pnfs/fnal.gov/usr/|/pnfs/|')
    [[ "$path" == /* ]] || path="/$path"
    loc=$(cat "$(dirname "$path")/.(get)($(basename "$path"))(locality)" 2>/dev/null | tr -d '[:space:]')
    [[ -z "$loc" ]] && loc="SIN_RESPUESTA"
    count[$loc]=$(( ${count[$loc]:-0} + 1 ))
    n=$((n+1))
    [[ -n "${VERBOSE:-}" && "$loc" != ONLINE* ]] && echo "$loc $path"
    (( n % 500 == 0 )) && echo "... $n ficheros mirados" >&2
done < "$LIST"

echo "Ficheros mirados: $n (uno de cada $STEP de la lista)"
for k in "${!count[@]}"; do
    printf "  %-22s %6d (%5.1f %%)\n" "$k" "${count[$k]}" "$(echo "100*${count[$k]}/$n" | bc -l)"
done | sort
