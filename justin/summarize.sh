#!/bin/bash
# Resumen de los stats_*.txt de un workflow (bajados de la salida de justIN).
#
#   summarize.sh <dir_con_stats> [lista_de_entrada.txt]
#
# Con la lista, dice también qué ficheros no tienen stats (trabajos que no llegaron a correr lar).
# Con RETRY_LIST=<fichero> (y la lista) escribe ahí los ficheros sin stats y los que fallaron, con
# la primera línea de la lista como cabecera: para relanzarlos con LIST=... en submit.sh.
set -u
DIR=${1:?uso: summarize.sh <dir> [lista]}
LIST=${2:-}

cat "$DIR"/stats_*.txt 2>/dev/null | awk '
function v(k,  i,a){ for(i=1;i<=NF;i++){ split($i,a,"="); if(a[1]==k) return a[2] } return "" }
{
  n++; st=v("status"); ev=v("events"); w=v("wall_s"); r=v("maxrss_kb"); h=v("vmhwm_kb"); b=v("out_bytes")
  if (h!="") { nh++; H+=h; if (h+0>HM) HM=h+0 }   # también los que fallan (¿memoria?)
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
    printf "Memoria máxima según time: %.2f GB (poco fiable en algunos sitios)\n", R/1024/1024
    if (nh) printf "Memoria de lar (VmHWM, también los fallidos): media %.2f GB, máxima %.2f GB (%d ficheros)\n", H/nh/1024/1024, HM/1024/1024, nh
    printf "Salida: %.3f MB/evento, %.1f MB/fichero\n", (E? B/E/1e6:0), B/ok/1e6
  }
}'

if [[ -n "$LIST" ]]; then
    # Con VERBOSE=1 lista siempre los que faltan; si no, solo cuando son pocos (en una prueba
    # con N trabajos faltan casi todos los de la lista y no interesa verlos)
    missing=()
    while read -r url; do
        [[ -z "$url" || "$url" == \#* ]] && continue
        name=$(basename "$url" .root | sed 's/[^A-Za-z0-9_.-]/_/g')
        [[ -f "$DIR/stats_${name}.txt" ]] || missing+=("$url")
    done < "$LIST"
    nmiss=${#missing[@]}
    if [[ $nmiss -le 10 || -n "${VERBOSE:-}" ]]; then
        # ${a[@]+...}: con set -u, bash 4.2 (SL7) da "unbound variable" al expandir un array vacío
        for url in ${missing[@]+"${missing[@]}"}; do echo "SIN STATS: $url"; done
        echo "Ficheros de la lista sin stats: $nmiss"
    else
        echo "Ficheros de la lista sin stats: $nmiss (VERBOSE=1 para listarlos)"
    fi
    if [[ -n "${RETRY_LIST:-}" ]]; then
        # cabecera de la lista, los que no tienen stats y los que fallaron (status != 0)
        {
            grep -m1 '^#' "$LIST" || true
            for url in ${missing[@]+"${missing[@]}"}; do echo "$url"; done
            cat "$DIR"/stats_*.txt 2>/dev/null | awk '{ st=""; inp=""; for(i=1;i<=NF;i++){ split($i,a,"="); if(a[1]=="status")st=a[2]; if(a[1]=="input")inp=substr($i,7) } if(st!="0" && inp!="")print inp }'
        } > "$RETRY_LIST"
        echo "Lista para relanzar: $RETRY_LIST ($(grep -c -v '^#' "$RETRY_LIST") ficheros)"
    fi
fi
