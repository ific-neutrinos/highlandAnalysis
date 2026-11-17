#!/bin/bash
# Prepara el tarball para justin-cvmfs-upload (en dunegpvm, con el entorno de mrb cargado:
# setup_larsoft.sh + mrbsetenv + fixcmake).
#
#   pack_runtime.sh <dir_listas> [salida.tar.gz]
#
# Contenido (lo que espera pdsp_minitree.jobscript):
#   pdsp_runtime/lib/        el módulo y las librerías del área local de las que depende
#   pdsp_runtime/fcl/        CreateHighlandMiniTree*.fcl
#   pdsp_runtime/data/       dEdxrestemplates.root
#   pdsp_runtime/lists/      las listas de make_filelist.sh
#   pdsp_runtime/highland/{highland,highlandPD}   instalaciones (sin build/ ni .git)
set -eu
[[ $# -lt 1 ]] && { sed -n '2,13p' "$0"; exit 1; }
LISTS=$1
OUT=${2:-pdsp_runtime.tar.gz}
HERE="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"   # fuentes de highlandAnalysis
: "${MRB_INSTALL:?Falta el entorno de mrb (MRB_INSTALL)}"

TMP=$(mktemp -d)
RT="$TMP/pdsp_runtime"
mkdir -p "$RT"/{lib,fcl,data,lists,highland}

# Módulo
MOD=$(find "$MRB_INSTALL" -name '*CreateHighlandMiniTree*_module.so' | head -1)
[[ -n "$MOD" ]] || { echo "ERROR: no encuentro el módulo en $MRB_INSTALL"; exit 1; }
echo "Módulo: $MOD"
cp -L "$MOD" "$RT/lib/"

# Dependencias que resuelven al área local (no las de cvmfs, que ya están en el nodo;
# las de highland van en su propio directorio)
ldd "$MOD" | awk '/=>/ {print $3}' | grep "^$MRB_INSTALL" | grep -v "/highland/" | while read -r lib; do
    echo "  dependencia local: $lib"
    cp -L "$lib" "$RT/lib/"
done
if ldd "$MOD" | grep -q 'not found'; then
    echo "AVISO: dependencias sin resolver en este entorno:"; ldd "$MOD" | grep 'not found'
fi

cp "$HERE"/CreateHighlandMiniTree*.fcl "$RT/fcl/"
cp "$HERE/dEdxrestemplates.root" "$RT/data/"
cp "$LISTS"/*.txt "$RT/lists/"

for pkg in highland highlandPD; do
    src="$MRB_INSTALL/highland/$pkg"
    [[ -d "$src" ]] || { echo "ERROR: no existe $src"; exit 1; }
    rsync -a --exclude build --exclude .git --exclude '*.o' "$src" "$RT/highland/"
done

tar -C "$TMP" -czf "$OUT" pdsp_runtime
rm -rf "$TMP"
du -h "$OUT"
echo "Siguiente: INPUT_TAR_DIR_LOCAL=\$(justin-cvmfs-upload $OUT)"
