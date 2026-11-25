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
#   pdsp_runtime/highland/{highland,highlandPD}   árboles completos (menos .git)
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
    # Árbol completo (menos .git): seleccionar ficheros acaba fallando en la grid (rutas de
    # getenv, datos, cabeceras...). "$src/" con barra: copia el contenido aunque $src sea un
    # enlace simbólico.
    # Se excluyen solo los ficheros que git ve como no seguidos y no ignorados: las salidas sueltas
    # de macros y análisis que se corren en el área (minitrees, .root de estudios, logs, listas).
    # Lo seguido por git y los productos de compilación (lib/, bin/, include/, *Config.cmake) se copian
    # siempre, estén o no en el .gitignore: highland no tiene .gitignore y su lib/ salía como "suelta"
    # (workflow 23524, 25-nov-2026: libhighland.so no estaba en el tarball y fallaron todos los
    # trabajos). Sin la exclusión el tarball pasó de 86 MB a > 2 GB (23-nov-2026) y
    # justin-cvmfs-upload no lo acepta.
    excl="$TMP/excluir_$pkg.txt"
    if git -C "$src" rev-parse --git-dir > /dev/null 2>&1; then
        git -C "$src" ls-files --others --exclude-standard | sed 's|^|/|' \
            | grep -Ev '^/(lib|bin|include)/|^/[^/]*Config\.cmake$' > "$excl" || true
    else
        : > "$excl"
    fi
    if [[ -s "$excl" ]]; then
        echo "$pkg: se excluyen $(wc -l < "$excl") ficheros sueltos fuera de git ($(cd "$src" && sed 's|^/||' "$excl" | tr '\n' '\0' | du -ch --files0-from=- 2>/dev/null | tail -1 | cut -f1)); los mayores:"
        (cd "$src" && sed 's|^/||' "$excl" | tr '\n' '\0' | du -h --files0-from=- 2>/dev/null | sort -h | tail -5 | sed 's/^/    /')
    fi
    rsync -a --exclude .git --exclude-from="$excl" "$src/" "$RT/highland/$pkg/"
done

# Comprobación: cada dependencia del módulo que resuelve a highland o highlandPD tiene que estar en el tarball
missing=0
while read -r lib; do
    [[ "$lib" == */highland/* ]] || continue
    if [[ -z "$(find "$RT/highland" -name "$(basename "$lib")" -print -quit)" ]]; then
        echo "ERROR: $(basename "$lib") (dependencia del módulo) no está en el tarball"; missing=1
    fi
done < <(ldd "$MOD" | awk '/=>/ {print $3}')
(( missing )) && { rm -rf "$TMP"; exit 1; }

tar -C "$TMP" -czf "$OUT" pdsp_runtime
rm -rf "$TMP"
du -h "$OUT"
# justin-cvmfs-upload manda el tarball en una sola petición: más de 2 GB falla (OverflowError)
size=$(stat -c %s "$OUT")
if (( size > 1900000000 )); then
    echo "ERROR: $OUT ocupa $((size/1000000)) MB: justin-cvmfs-upload no acepta más de 2 GB. Mira qué hay de más en los árboles."
    exit 1
fi
echo "Siguiente: INPUT_TAR_DIR_LOCAL=\$(justin-cvmfs-upload $OUT)"
