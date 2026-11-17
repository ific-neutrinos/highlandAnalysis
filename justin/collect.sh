#!/bin/bash
# Mueve la salida de un workflow desde el sitio por defecto de justIN a pdsp/<mode>/<fecha>/.
#
#   collect.sh <workflow> [mode fecha]
#
# Sin mode y fecha los toma de workflows.txt (lo escribe submit.sh). En /pnfs, mv es un cambio
# de nombre dentro de dCache: no copia datos. No sobrescribe: si un fichero ya existe en el
# destino, lo deja donde estaba y avisa.
set -eu
[[ $# -lt 1 ]] && { sed -n '2,8p' "$0"; exit 1; }
WF=$1
HERE="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
if [[ $# -ge 3 ]]; then
    MODE=$2; DATE=$3
else
    read -r _ MODE DATE < <(awk -v w="$WF" '$1==w' "$HERE/workflows.txt" 2>/dev/null | tail -1) || true
    [[ -n "${MODE:-}" && -n "${DATE:-}" ]] || { echo "ERROR: workflow $WF no está en workflows.txt; pasa mode y fecha"; exit 1; }
fi

BASE=/pnfs/dune/scratch/users/$USER
SRC=$BASE/fnal/$WF
DST=$BASE/pdsp/$MODE/$DATE
[[ -d "$SRC" ]] || { echo "ERROR: no existe $SRC"; exit 1; }
mkdir -p "$DST"

moved=0; skipped=0
while IFS= read -r -d '' f; do
    if [[ -e "$DST/$(basename "$f")" ]]; then
        echo "YA EXISTE, no se mueve: $f"; skipped=$((skipped+1))
    else
        mv "$f" "$DST/"; moved=$((moved+1))
    fi
done < <(find "$SRC" -type f \( -name 'minitree_*.root' -o -name 'stats_*.txt' \) -print0)

echo "Workflow $WF: $moved ficheros movidos a $DST, $skipped sin mover"
# Quitar las carpetas vacías que deja justIN
find "$SRC" -depth -type d -empty -delete 2>/dev/null || true
