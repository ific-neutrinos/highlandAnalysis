find_ups_product( dunetpc )

#------ HighLAND -------------------
set(ENV{HIGHLAND_DIR} $ENV{MRB_INSTALL}/highland/highland/)
find_package(HIGHLAND REQUIRED)

message("HIGHLAND include directories: ${HIGHLAND_INCLUDE_DIRS}")
message("HIGHLAND libraries:           ${HIGHLAND_LIBRARIES}")

#------ HighLANDPD -----------------
set(ENV{HIGHLAND_PD_DIR} $ENV{MRB_INSTALL}/highland/highlandPD/)
find_package(HIGHLAND_PD REQUIRED)

message("HIGHLAND_PD include directories: ${HIGHLAND_PD_INCLUDE_DIRS}")
message("HIGHLAND_PD libraries:           ${HIGHLAND_PD_LIBRARIES}")

#------ include HighLANDs ----------
include_directories(${HIGHLAND_INCLUDE_DIRS} ${HIGHLAND_PD_INCLUDE_DIRS})
link_libraries(${HIGHLAND_LIBRARIES} ${HIGHLAND_PD_LIBRARIES})

#-----------------------------------

art_make(BASENAME_ONLY
  MODULE_LIBRARIES
  cetlib cetlib_except
  larsim_Simulation
  lardataobj_Simulation
  lardataobj_RecoBase
  lardata_Utilities
  lardata_ArtDataHelper
  larcorealg_Geometry
  nusimdata_SimulationBase
  larsim_MCCheater_PhotonBackTrackerService_service           
  larsim_MCCheater_BackTrackerService_service           
  larsim_MCCheater_ParticleInventoryService_service
  larreco_RecoAlg
  ${ROOT_BASIC_LIB_LIST}
  ProtoDUNEUtilities
  ReweightBaseLib
  PropBaseLib
  ${ART_FRAMEWORK_CORE}
  ${ART_FRAMEWORK_PRINCIPAL}
  ${ART_FRAMEWORK_SERVICES_REGISTRY}
  ${ART_FRAMEWORK_SERVICES_BASIC}
  ${ART_FRAMEWORK_SERVICES_OPTIONAL}
  ${ART_FRAMEWORK_SERVICES_OPTIONAL_TFILESERVICE_SERVICE}
  ${ART_PERSISTENCY_COMMON}
  canvas
  art_Persistency_Provenance
  art_root_io
  ${ART_ROOT_IO_TFILE_SUPPORT} ${ROOT_CORE}
  ${ART_ROOT_IO_TFILESERVICE_SERVICE}
  ${ART_UTILITIES}
  ${MF_MESSAGELOGGER}
  )
install_headers()
install_fhicl()
install_source()

