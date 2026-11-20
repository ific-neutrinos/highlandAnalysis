# setup_larsoft.sh: entorno de dunesw v09_56_00d00 + mrb para compilar highlandAnalysis
# Copia de referencia: el de verdad va en la raíz del área de mrb (al lado de localProducts_*).
#
# Uso: source setup_larsoft.sh                         (token de justIN: samweb, justIN, compilar)
#      PD_TOKEN=interactive source setup_larsoft.sh    (token interactivo: escribir en persistent)
#      PD_TOKEN=none source setup_larsoft.sh           (sin tocar el token)

_PD_AREA="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source /cvmfs/dune.opensciencegrid.org/products/dune/setup_dune.sh

# Solo hace unsetup si el producto está cargado (evita "Cannot do unsetup")
_pd_unsetup() { local v="SETUP_$(echo "$1" | tr '[:lower:]' '[:upper:]')"; [ -n "${!v}" ] && unsetup "$1"; }

# mrb y las herramientas de compilación de la época de larsoft v09_56 (el mrb
# actual configura cetmodules v3_27_04 / cmake 3.27, que rompen protoduneana)
_pd_unsetup mrb;        setup mrb v5_19_12
_pd_unsetup cetmodules; _pd_unsetup cmake
setup cmake v3_22_2
setup cetmodules v3_16_00

export DV=v09_56_00d00
export DQ="e20:prof"
setup dunesw $DV -q $DQ

setup justin
setup python v3_9_15
setup metacat

export METACAT_SERVER_URL=https://metacat.fnal.gov:9443/dune_meta_prod/app
export METACAT_AUTH_SERVER_URL=https://metacat.fnal.gov:8143/auth/dune

# Token: PD_TOKEN=justin (samweb, justIN; por defecto), interactive (escribir en persistent
# con justin/to_persistent.sh: es el único con storage.create:/persistent/users/$USER) o none.
# Cada uno sobrescribe el fichero de token de esta máquina: con el interactivo, SAM responde
# "Username 'interactive' is not registered". justin get-token deja además un proxy de justIN
# en /tmp/x509up_u<uid>, que es el que usa el xrdcp de este entorno (no sabe usar tokens).
export BEARER_TOKEN_FILE=/run/user/$(id -u)/bt_u$(id -u)
export X509_CERT_DIR=/cvmfs/oasis.opensciencegrid.org/mis/certificates
case "${PD_TOKEN:-justin}" in
  justin)      justin get-token ;;
  interactive) htgettoken -i dune --vaultserver htvaultprod.fnal.gov -r interactive ;;
  none)        ;;
  *)           echo "PD_TOKEN tiene que ser justin, interactive o none" ;;
esac

source "$_PD_AREA"/localProducts_larsoft_v09_56_00_e20_prof/setup
mrbsetenv

# Algún setup deja en el PATH el bin de cmake v3_27_4 por delante del de ups:
# quitar del PATH cualquier cmake que no sea v3_22_2. Repetir tras cada mrbsetenv.
fixcmake() {
  local newpath
  newpath=$(echo "$PATH" | tr ':' '\n' \
            | awk 'NF && (!/\/products\/cmake\// || /\/products\/cmake\/v3_22_2\//)' \
            | paste -sd:)
  if [ -n "$newpath" ]; then export PATH="$newpath"; hash -r
  else echo "fixcmake: PATH vacío tras filtrar, no se cambia"; fi
}

checkenv() {
  ups active | grep -iE "cetmodules|cetbuildtools|^cmake |^mrb "
  echo "cmake en PATH: $(command -v cmake) ($(cmake --version | head -1))"
  case "$(cmake --version | head -1)" in
    *3.22.2*) echo "OK" ;;
    *) echo "AVISO: no es cmake 3.22.2; ejecuta fixcmake" ;;
  esac
}

fixcmake
checkenv
