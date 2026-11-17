#!/bin/bash
# Lanza el workflow de justIN (en dunegpvm, tras justin get-token).
#
#   submit.sh <mc|data> <N> <INPUT_TAR_DIR_LOCAL> [nevents]
#
# Salida en /pnfs/dune/scratch/users/$USER/pdsp/<mode>/<AAAAMMDD>/ (fecha de lanzamiento).
# Variables opcionales: IMAGE (imagen de SL7), RSS_MIB, WALL_SECONDS, OUTDIR_TAG (sufijo de la
# carpeta, p. ej. _prueba), DRYRUN=1 (solo imprime el comando).
set -eu
[[ $# -lt 3 ]] && { sed -n '2,9p' "$0"; exit 1; }
MODE=$1; N=$2; TARDIR=$3; NEV=${4:--1}
[[ "$MODE" == mc || "$MODE" == data ]] || { echo "ERROR: mode tiene que ser mc o data"; exit 1; }

HERE="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
DATE=$(date +%Y%m%d)
SUBDIR="pdsp/$MODE/${DATE}${OUTDIR_TAG:-}"
PNFS="/pnfs/dune/scratch/users/$USER/$SUBDIR"
# Mismo sitio visto por WebDAV desde los nodos. $FNALURL y $USERF los expande justIN en el
# trabajo (FNALURL = https://fndcadoor.fnal.gov:2880/dune/scratch/users, USERF = usuario).
DEST='$FNALURL/$USERF'"/$SUBDIR"

IMAGE=${IMAGE:-/cvmfs/singularity.opensciencegrid.org/fermilab/fnal-wn-sl7:latest}

mkdir -p "$PNFS"
echo "Salida: $PNFS"

CMD=(justin simple-workflow
     --description "pdsp minitree $MODE $DATE"
     --monte-carlo "$N"
     --jobscript "$HERE/pdsp_minitree.jobscript"
     --image "$IMAGE"
     --rss-mib "${RSS_MIB:-5000}"
     --wall-seconds "${WALL_SECONDS:-14400}"
     --env MODE="$MODE"
     --env NEVENTS="$NEV"
     --env INPUT_TAR_DIR_LOCAL="$TARDIR"
     --output-pattern "minitree_*.root:$DEST"
     --output-pattern "stats_*.txt:$DEST")

printf '%q ' "${CMD[@]}"; echo
[[ -n "${DRYRUN:-}" ]] && exit 0
"${CMD[@]}"
