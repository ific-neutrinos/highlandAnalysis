#!/bin/bash
# Resumen de los stats_*.txt de un workflow (bajados de la salida de justIN).
#
#   summarize.sh <dir_con_stats> [lista_de_entrada.txt]
#
# Con la lista, dice también qué ficheros no tienen stats (trabajos que no llegaron a correr lar).
set -u
DIR=${1:?uso: summarize.sh <dir> [lista]}
LIST=${2:-}

cat "$DIR"/stats_*.txt 2>/dev/null | awk '
function v(k,  i,a){ for(i=1;i<=NF;i++){ split($i,a,"="); if(a[1]==k) return a[2] } return "" }
{
  n++; st=v("status"); ev=v("events"); w=v("wall_s"); r=v("maxrss_kb"); b=v("out_bytes")
  if (st!=0) { nfail++; print "FALLO (status " st "): " v("input"); next }
  ok++; E+=ev; W+=w; B+=b
  if (r!="NA" && r+0>R) R=r+0
  if (ev>0) { s=w/ev; if(s>smax) smax=s }
  if (ev==0) nzero++
}
END {
  if (!n) { print "No hay stats_*.txt"; exit 1 }
  printf "Trabajos con stats: %d  (bien: %d, fallos: %d, con 0 eventos: %d)\n", n, ok, nfail, nzero
  if (ok) {
    printf "Eventos: %d en total, %.1f por fichero\n", E, E/ok
    printf "Tiempo: %.2f s/evento de media (pared, incluye lectura por xrootd); peor fichero %.2f s/evento\n", (E? W/E:0), smax
    printf "Memoria máxima: %.2f GB\n", R/1024/1024
    printf "Salida: %.3f MB/evento, %.1f MB/fichero\n", (E? B/E/1e6:0), B/ok/1e6
  }
}'

if [[ -n "$LIST" ]]; then
    missing=0
    while read -r url; do
        [[ -z "$url" || "$url" == \#* ]] && continue
        name=$(basename "$url" .root | sed 's/[^A-Za-z0-9_.-]/_/g')
        [[ -f "$DIR/stats_${name}.txt" ]] || { echo "SIN STATS: $url"; missing=$((missing+1)); }
    done < "$LIST"
    echo "Ficheros de la lista sin stats: $missing"
fi
