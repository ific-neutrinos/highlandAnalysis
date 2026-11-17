#!/bin/bash
# Lanza el workflow de justIN (en dunegpvm, tras justin get-token).
#
#   submit.sh <mc|data> <N> <INPUT_TAR_DIR_LOCAL> [nevents]
#
# justIN escribe en /pnfs/dune/scratch/users/$USER/fnal/<workflow>/<stage>/<lote>/ (destino
# .../fnal más las subcarpetas que añade él, igual que en el workflow 23119); al acabar, collect.sh <workflow> la mueve a pdsp/<mode>/<AAAAMMDD>/ (fecha de
# lanzamiento). Este script apunta "<workflow> <mode> <fecha>" en workflows.txt.
# Variables opcionales: IMAGE (--image, hace falta SL7 para dunesw v09), RSS_MIB,
# WALL_SECONDS, DRYRUN=1 (solo imprime el comando).
set -eu
[[ $# -lt 3 ]] && { sed -n '2,11p' "$0"; exit 1; }
MODE=$1; N=$2; TARDIR=$3; NEV=${4:--1}
[[ "$MODE" == mc || "$MODE" == data ]] || { echo "ERROR: mode tiene que ser mc o data"; exit 1; }

HERE="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
DATE=$(date +%Y%m%d)
WFFILE=$(mktemp)
DEST="https://fndcadoor.fnal.gov:2880/dune/scratch/users/$USER/fnal"

CMD=(justin simple-workflow
     --description "pdsp minitree $MODE $DATE"
     --monte-carlo "$N"
     --jobscript "$HERE/pdsp_minitree.jobscript"
     --rss-mib "${RSS_MIB:-5000}"
     --wall-seconds "${WALL_SECONDS:-14400}"
     --env MODE="$MODE"
     --env NEVENTS="$NEV"
     --env INPUT_TAR_DIR_LOCAL="$TARDIR"
     --scope usertests
     --output-pattern "minitree_*.root:$DEST"
     --output-pattern "stats_*.txt:$DEST"
     --workflow-id-file "$WFFILE")
[[ -n "${IMAGE:-}" ]] && CMD+=(--image "$IMAGE")

printf '%q ' "${CMD[@]}"; echo
[[ -n "${DRYRUN:-}" ]] && { rm -f "$WFFILE"; exit 0; }
"${CMD[@]}"

WF=$(tr -dc '0-9' < "$WFFILE"); rm -f "$WFFILE"
if [[ -n "$WF" ]]; then
    echo "$WF $MODE $DATE" >> "$HERE/workflows.txt"
    echo "Workflow $WF -> al acabar: $HERE/collect.sh $WF"
else
    echo "AVISO: no he podido leer el número de workflow; apúntalo a mano en $HERE/workflows.txt como '<workflow> $MODE $DATE'"
fi
