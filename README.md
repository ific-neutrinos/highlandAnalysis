# highlandAnalysis

Módulo de art `CreateHighlandMiniTree` para ProtoDUNE-SP: lee la reconstrucción (reco1/reco2 de
datos, Prod4a de MC) y escribe un minitree de HighLAND (`highlandana/MiniTree`, rama `Spill` de
clase `AnaSpillPD`) que leen los análisis de [highlandPD](https://github.com/ific-neutrinos/highlandPD).
El formato del minitree lo define `pdDataClasses` de highlandPD: el módulo y highlandPD tienen que
ser de versiones compatibles (mismo tag).

Versión: **dunesw v09_56_00d00** (`-q e20:prof`), en SL7 (Apptainer en dunegpvm).

## Entorno (dunegpvm)

Área de mrb con `protoduneana` en `srcs/`; este paquete va en
`srcs/protoduneana/protoduneana/singlephase/highlandAnalysis`. Un `setup_larsoft.sh` en la raíz
del área con:

```bash
setup mrb v5_19_12
setup cmake v3_22_2
setup cetmodules v3_16_00          # larsoft v09_56_00 pide esta; con la v3_27_04 falla el find_package de Pythia6
setup dunesw v09_56_00d00 -q e20:prof
source localProducts*/setup
mrbsetenv
```

Versión completa en `justin/setup_larsoft.example.sh` (copiarla a la raíz del área como `setup_larsoft.sh`): con `PD_TOKEN` elige el token (justIN para samweb y justIN; `interactive` para escribir en persistent). mrb v4 no vale (el área pide mrb >= v5). Algún setup deja `/products/cmake/v3_27_4/bin/` delante
en el `PATH`: después de cada `mrbsetenv` hay que quitar del `PATH` los cmake que no sean la
v3_22_2 y hacer `hash -r` (en el `setup_larsoft.sh` de referencia, funciones `fixcmake` y
`checkenv`).

## highland y highlandPD

El `CMakeLists.txt` los busca en `$MRB_INSTALL/highland/highland` y
`$MRB_INSTALL/highland/highlandPD` (`HIGHLANDConfig.cmake` y `HIGHLAND_PDConfig.cmake`, que generan
sus builds). Se compilan en el mismo entorno de dunesw (después del `setup dunesw`: el
`setup.sh` de highland solo carga sus propios productos si `ROOTSYS` y `TBBROOT` están vacíos),
con las ramas o tags que correspondan al del módulo. Para compilar el módulo no hace falta
cargar los `setup.sh` de highland y highlandPD.

## Compilar

```bash
source setup_larsoft.sh
mrb z && mrbsetenv && fixcmake && checkenv && mrb i -j8
```

## Ejecutar

```bash
lar -c CreateHighlandMiniTree_mc.fcl   -s <reco.root> -n 10   # MC: corre la etapa 2 de calibración
lar -c CreateHighlandMiniTree_data.fcl -s <reco2.root> -n 10  # datos
```

`dEdxrestemplates.root` tiene que estar en el directorio de trabajo (o la ruta completa en
`PIDFilename`). Con el fcl de MC sobre datos, la recalibración sale como MC: usar siempre el de
datos para datos. Los dos ponen un `MissingProductFilter` antes de la etapa 2: los eventos sin
productos de Pandora se guardan marcados (`HasPandora = false`, `MissingReco = true`) en vez de
abortar.

La configuración está en `CreateHighlandMiniTree.fcl`, comentada parámetro a parámetro. Lo
principal:

- `CosmicsMode` (0-4) y `CosmicsRadius`: qué cósmicos se guardan completos y cuáles en resumen.
  Por defecto 2: completos los que están cerca de los extremos de la beam slice.
- `MuCandidates`: completos también los candidatos a mu de K+ en reposo (traza parada con rango de
  mu de 150-350 MeV/c cerca del eje del haz), también sin beam slice (`MuCandidatesWithoutBeamSlice`).
  `MuCandidateShowers` añade los PFParticles sin traza con su traza forzada; está apagado porque
  guarda completas muchas cascadas de cósmicos (+61 % de tamaño frente a +4 %).
  `AnaParticlePD::CosmicCriteria` dice qué criterio pasó cada jerarquía.
- `SaveTrueAncestors` (MC): las madres de las partículas true emparejadas con un PFParticle que la
  recursión desde el haz no alcanza, hasta una ya guardada. Sin ellas no se sabe de dónde viene ~40 %
  de los mu+ de K+ en reposo.
- `BeamVolume*`: eje del haz, distinto en datos y MC. Vale para 3-7 GeV.
- `FullDumpTruePDGs` (MC): volcado completo de los eventos con esos PDG en la cadena del haz (en
  el fcl de MC, `[321]`, para estudios de eficiencia).
- `CompressionSettings`: 208 (LZMA 8).

Tamaño típico a 6 GeV: MC ~1 MB/evento (con el volcado de los eventos con K+), datos ~0,23
MB/evento.

## Grid (justIN)

Scripts en `justin/`; cada uno explica su uso en la cabecera. Flujo:

1. `make_filelist.sh <definición SAM> <N> lists/filelist_<mode>.txt`: URLs xrootd (y una
   definición con esos ficheros para el prestage).
2. Prestage si hace falta (`samweb prestage-dataset`); `check_locality.sh` dice qué está en disco.
3. `pack_runtime.sh lists pdsp_runtime.tar.gz` (con el entorno de mrb): módulo, fcl, plantillas,
   listas y highland y highlandPD enteros. Subirlo con `justin-cvmfs-upload` y guardar la ruta.
   Rehacerlo si cambian código, fcl o listas.
4. `submit.sh <mc|data> <N trabajos> $INPUT_TAR_DIR_LOCAL [nevents]` (tras `justin get-token`).
   Variables: `SITES` (p. ej. `US_FNAL-FermiGrid`: lejos de FNAL domina la lectura por xrootd),
   `LIST`, `FILES_PER_JOB`, `RSS_MIB` (8000 por defecto), `WALL_SECONDS`.
5. `collect.sh <workflow> [mode fecha]`: mueve la salida a `scratch/users/$USER/pdsp/<mode>/<fecha>/`.
6. `summarize.sh <dir> lists/filelist_<mode>.txt`: trabajos bien y mal, tiempo, memoria y tamaño;
   con `RETRY_LIST` escribe la lista para relanzar los que fallaron.

El scratch de dCache se purga: copiar lo que se quiera guardar a
`/pnfs/dune/persistent/users/$USER`.

Validación de las muestras con las macros de highlandPD `test/phase2/` (`count_module_minitrees.C`,
`kaon_fate_minitrees.C`, `cosmic_criteria_minitrees.C`, `size_breakdown_minitree.C`,
`compare_module_minitrees.C`, `beam_axis_minitrees.C`).
