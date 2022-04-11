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
  larsim::Simulation
  lardataobj::Simulation
  lardataobj::RecoBase
  lardata::Utilities
  lardata::ArtDataHelper
  larcorealg::Geometry
  nusimdata::SimulationBase
  larsim::MCCheater_PhotonBackTrackerService_service           
  larsim::MCCheater_BackTrackerService_service           
  larsim::MCCheater_ParticleInventoryService_service
  larreco::RecoAlg
  ROOT_BASIC_LIB_LIST
  ProtoDUNEUtilities
  geant4reweight::ReweightBaseLib
  geant4reweight::PropBaseLib
  art::Framework_Core
  art::Framework_Principal
  art::Framework_Services_Registry
  art_root_io::tfile_support
  ROOT::Core
  art_root_io::TFileService_service
  art::Persistency_Common
  canvas::canvas
  art::Persistency_Provenance
  art::Utilities
  messagefacility::MF_MessageLogger
  )
install_headers()
install_fhicl()
install_source()

