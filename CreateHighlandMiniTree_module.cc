////////////////////////////////////////////////////////////////////////
// Class:       CreateHighlandMiniTree
// Module Type: analyzer
// File:        CreateHighlandMiniTree_module.cc
//
// Generated at Fri Nov 20 08:01:58 2020 by Miguel Garcia Peris using artmod
// from cetpkgsupport v1_14_01.
////////////////////////////////////////////////////////////////////////

//basic includes
#include "art/Framework/Core/EDAnalyzer.h"
#include "art/Framework/Core/ModuleMacros.h"
#include "art/Framework/Principal/Event.h"
#include "art/Framework/Principal/Handle.h"
#include "art/Framework/Principal/Run.h"
#include "art/Framework/Principal/SubRun.h"
#include "canvas/Utilities/InputTag.h"
#include "fhiclcpp/ParameterSet.h"
#include "messagefacility/MessageLogger/MessageLogger.h"

//framework includes
#include "art_root_io/TFileService.h"

#include "dune/DuneObj/ProtoDUNEBeamEvent.h"
#include "protoduneana/protoduneana/Utilities/ProtoDUNETrackUtils.h"
#include "protoduneana/protoduneana/Utilities/ProtoDUNEShowerUtils.h"
#include "protoduneana/protoduneana/Utilities/ProtoDUNETruthUtils.h"
#include "protoduneana/protoduneana/Utilities/ProtoDUNEPFParticleUtils.h"
#include "dune/Protodune/singlephase/DataUtils/ProtoDUNEDataUtils.h"
#include "protoduneana/protoduneana/Utilities/ProtoDUNEBeamlineUtils.h"
#include "protoduneana/Utilities/ProtoDUNEBeamCuts.h"
#include "larsim/MCCheater/ParticleInventoryService.h"
#include "lardata/DetectorInfoServices/DetectorPropertiesService.h"
#include "lardata/ArtDataHelper/MVAReader.h"
#include "lardataobj/RecoBase/Wire.h"
#include "protoduneana/Utilities/ProtoDUNECalibration.h"


//root includes
#include "TTree.h"
#include "TVector3.h"

//highland includes
#include "pdDataClasses.hxx"
#include "Header.hxx"
#include "pdAnalysisUtils.hxx"

namespace highlandAnalysis {
  
  class CreateHighlandMiniTree;  

}

class highlandAnalysis::CreateHighlandMiniTree : public art::EDAnalyzer {
public:
  explicit CreateHighlandMiniTree(fhicl::ParameterSet const & p);
  // The destructor generated by the compiler is fine for classes
  // without bare pointers or other resource use.
  
  // Plugins should not be copied or assigned.
  CreateHighlandMiniTree(CreateHighlandMiniTree const &) = delete;
  CreateHighlandMiniTree(CreateHighlandMiniTree &&) = delete;
  CreateHighlandMiniTree & operator = (CreateHighlandMiniTree const &) = delete;
  CreateHighlandMiniTree & operator = (CreateHighlandMiniTree &&) = delete;
  
  // Required functions.
  void analyze(art::Event const & e) override;
  
  // Selected optional functions
  void beginJob() override;
  void endJob() override;
  void reset();

  // HighLAND functions
  AnaSpillPD*         MakeSpill()       { return new AnaSpillPD(); }
  AnaBunchPD*         MakeBunch()       { return new AnaBunchPD(); }
  AnaBeamPD*          MakeBeam()        { return new AnaBeamPD(); }
  AnaDataQualityB*    MakeDataQuality() { return new AnaDataQuality(); }
  AnaEventInfoB*      MakeEventInfo()   { return new AnaEventInfo(); }

  AnaTrueParticlePD*  MakeTrueParticle(){ return new AnaTrueParticlePD(); }
  AnaTrueVertex*      MakeTrueVertex()  { return new AnaTrueVertex(); }
  AnaParticlePD*      MakeParticle()    { return new AnaParticlePD(); }

  // ----------------------------

  void FillDQInfo      (art::Event const &evt, AnaDataQuality* dq);
  void FillTrueInfo    (art::Event const &evt, AnaSpill* spill);
  void FillTruePartInfo(art::Event const &evt, art::ServiceHandle<cheat::ParticleInventoryService> &piServ, 
			const sim::ParticleList &pList, const simb::MCParticle* ls_truePart,
			std::vector<AnaTrueParticleB*> &trueParticles, int generation);
  void FillBeamInfo    (art::Event const &evt, AnaBeamPD* beam);
  void FillBunchInfo   (art::Event const &evt, std::vector<AnaTrueParticleB*>& trueParticles, AnaBunch* bunch, AnaSpillPD* spill);
  void FillParticleInfo(art::Event const &evt, protoana::ProtoDUNEPFParticleUtils &pfpUtil,
			art::ValidHandle<std::vector<recob::PFParticle>> &pfpVec, const recob::PFParticle* ls_part,
			std::vector<AnaTrueParticleB*>& trueParticles, AnaBunch* bunch, int generation);
  void FillTrackInfo   (art::Event const &evt, const recob::Track* track, AnaParticlePD* part);
  void FillShowerInfo  (const recob::Shower* shower, AnaParticlePD* part);
  
  //other functions/utilities
  int GetTrueParticleID(art::Event const &evt, const recob::PFParticle* ls_part);
  std::pair<float*,int> GetCNNOutputFromPFParticleFromPlane(const art::Event &evt, 
							    const anab::MVAReader<recob::Hit,4> &CNN_results,
							    protoana::ProtoDUNEPFParticleUtils& pfpUtil,
							    const recob::PFParticle &part,
							    int planeID);


  void collect_adc_for_CNN(const art::Event & evt, const recob::PFParticle* particle, const std::vector<recob::PFParticle>& pfpVec, 
			   protoana::ProtoDUNEPFParticleUtils & pfpUtil,const std::string& fPFParticleTag,
			   std::vector<std::vector<float> >& reduced_adc_cnn_map,
			   std::vector<Int_t>& reduced_adc_cnn_map_wires,
			   std::vector<Int_t>& reduced_adc_cnn_map_times);


private:

  TTree* fTree;
  TTree* fHeaderTree;
  AnaSpillPD* fspill;
  
  // fcl parameters
  std::string fBeamModuleLabel;
  protoana::ProtoDUNEBeamlineUtils fBeamlineUtils;
  std::string fPFParticleTag;
  std::string fGeneratorTag;
  std::string fTrackerTag;
  std::string fShowerTag;
  std::string fCalorimetryTagSCE;
  std::string fCalorimetryTagNoSCE;
  std::string fHitTag;

  protoana::ProtoDUNECalibration calibrationSCE;
  protoana::ProtoDUNECalibration calibrationNoSCE;

  int         fMaxGeneration;
  int         fMCMaxGeneration;

  double      fNominalBeamMom;

  bool        fDebug;
};

//*****************************************************************************
highlandAnalysis::CreateHighlandMiniTree::CreateHighlandMiniTree(fhicl::ParameterSet const & p)
//*****************************************************************************
  :
  EDAnalyzer(p),
  fBeamModuleLabel(p.get<std::string>("BeamModuleLabel")),
  fBeamlineUtils(p.get< fhicl::ParameterSet >("BeamlineUtils")),
  fPFParticleTag(p.get<std::string>("PFParticleTag")),
  fGeneratorTag(p.get<std::string>("GeneratorTag")),
  fTrackerTag(p.get<std::string>("TrackerTag")),
  fShowerTag(p.get<std::string>("ShowerTag")),
  fCalorimetryTagSCE(p.get<std::string>("CalorimetryTagSCE")),
  fCalorimetryTagNoSCE(p.get<std::string>("CalorimetryTagNoSCE")),
  fHitTag(p.get<std::string>("HitTag")),

  calibrationSCE(p.get<fhicl::ParameterSet>("CalibrationParsSCE")),
  calibrationNoSCE(p.get<fhicl::ParameterSet>("CalibrationParsNoSCE")),

  fMaxGeneration(p.get<int>("MaxGeneration")),
  fMCMaxGeneration(p.get<int>("MCMaxGeneration")),

  fNominalBeamMom(p.get<double>("NominalBeamMom")), 

  fDebug(p.get<bool>("Debug")){

}

//*****************************************************************************
void highlandAnalysis::CreateHighlandMiniTree::analyze(art::Event const & evt){
//*****************************************************************************

  //create a spill for each event and fill event info
  AnaSpillPD* spill = MakeSpill();
  spill->EventInfo = MakeEventInfo();
  
  AnaEventInfo& info = *static_cast<AnaEventInfo*>(spill->EventInfo);
  info.Run    = evt.run();
  info.SubRun = evt.subRun();
  info.Event  = evt.id().event();
  info.IsMC   = !evt.isRealData();

  if(fDebug)std::cout << "Run " << info.Run << ", event " << info.Event << ", MC = " << info.IsMC << std::endl;

  //data quality and check
  spill->DataQuality = MakeDataQuality();
  FillDQInfo(evt,static_cast<AnaDataQuality*>(spill->DataQuality));
  if(!static_cast<AnaDataQuality*>(spill->DataQuality)->GoodDaq){
    mf::LogVerbatim("CreateHighlandMiniTree") << "Beam quality check failed";
    return;
  }

  //true info
  if(info.IsMC){
    FillTrueInfo(evt,spill);
    if(spill->TrueParticles.empty())return;
  }

  //beam related information
  spill->Beam = MakeBeam();
  FillBeamInfo(evt, static_cast<AnaBeamPD*>(spill->Beam));
  //if it is a mc event, match the primary particle with the beam particle
  if(info.IsMC)static_cast<AnaBeam*>(spill->Beam)->BeamParticle->TrueObject = spill->TrueParticles.at(0);
  
  //Fill each bunch info (we have only one in PD)
  AnaBunch* bunch = MakeBunch();
  spill->Bunches.push_back(bunch);
  FillBunchInfo(evt, spill->TrueParticles, bunch, spill);
  if(bunch->Particles.empty())return;
  
  //check if primary particle is beam particle (MC only)
  if(info.IsMC){
    AnaTrueParticlePD* tp1 = static_cast<AnaTrueParticlePD*>(static_cast<AnaBeam*>(spill->Beam)->BeamParticle->TrueObject);
    AnaTrueParticlePD* tp2 = static_cast<AnaTrueParticlePD*>(bunch->Particles.at(0)->TrueObject);
    if(tp1 && tp2){
      if(tp1->ID == tp2->ID){
	static_cast<AnaTrueParticlePD*>(bunch->Particles.at(0)->TrueObject)->Matched = true;
	if(fDebug)std::cout << "Primary particle in TPC and beam particle matched" << std::endl;
      }
      else {
	static_cast<AnaTrueParticlePD*>(bunch->Particles.at(0)->TrueObject)->Matched = false;
	if(fDebug)std::cout << "Primary part missmatched" << std::endl;
      }
    }
  }
  
  //if spill has been correctly saved, delete previous one
  if(fspill)delete fspill;
  fspill = NULL;

  //clone the new spill and fill the three
  fspill = spill->Clone();
  fTree->Fill();
}

//*****************************************************************************
void highlandAnalysis::CreateHighlandMiniTree::FillDQInfo(art::Event const &evt, AnaDataQuality* dq){
//*****************************************************************************

  if(fDebug)std::cout << "Filling data quality info" << std::endl;

  //associate trigger quality to data quality. Only for data, MC is always good.
  if(evt.isRealData())dq->GoodDaq = fBeamlineUtils.IsGoodBeamlineTrigger(evt);
  else dq->GoodDaq = true;

}

//*****************************************************************************
void highlandAnalysis::CreateHighlandMiniTree::FillTrueInfo(art::Event const &evt, AnaSpill* spill){
//*****************************************************************************
  
  if(fDebug)std::cout << "Filling truth info" << std::endl;

  //create a truth utils instance
  protoana::ProtoDUNETruthUtils truthUtil;
  auto mcTruths = evt.getValidHandle<std::vector<simb::MCTruth>>(fGeneratorTag);
 
  //get true primary particle
  const simb::MCParticle* ls_truePrimaryPart = truthUtil.GetGeantGoodParticle((*mcTruths)[0],evt);
  if(!ls_truePrimaryPart){
    mf::LogVerbatim("CreateHighlandMiniTree") << "True primary particle not found" << std::endl;
    return;
  }
  if(fDebug)std::cout << "true primary particle found" << std::endl;

  //fill true particle info recursively
  art::ServiceHandle<cheat::ParticleInventoryService> piServ;
  const sim::ParticleList &pList = piServ->ParticleList();

  spill->TrueParticles.clear();
  
  int generation = -1;

  FillTruePartInfo(evt, piServ, pList, ls_truePrimaryPart, spill->TrueParticles, generation);
}

//*****************************************************************************
void highlandAnalysis::CreateHighlandMiniTree::FillTruePartInfo(art::Event const &evt,
						     art::ServiceHandle<cheat::ParticleInventoryService> &piServ,
						     const sim::ParticleList &pList, 
						     const simb::MCParticle* ls_truePart,
						     std::vector<AnaTrueParticleB*>& trueParticles,
						     int generation){
//*****************************************************************************

  //create true particle and add it to the vector of true particles
  AnaTrueParticlePD* truePart = MakeTrueParticle();
  trueParticles.push_back(truePart);
 
  //fill truepart information
  truePart->ID = ls_truePart->TrackId();
  truePart->ParentID = ls_truePart->Mother();
  truePart->Origin   = piServ->TrackIdToMCTruth_P(ls_truePart->TrackId())->Origin();

  truePart->PDG = ls_truePart->PdgCode();
  //truePart->ParentPDG = ls_truePart->PDGCode();
  
  truePart->ProcessStart = truePart->ConvertProcess(ls_truePart->Process());
  truePart->ProcessEnd = truePart->ConvertProcess(ls_truePart->EndProcess());

  truePart->Position[0] = ls_truePart->Position(0).X();
  truePart->Position[1] = ls_truePart->Position(0).Y();
  truePart->Position[2] = ls_truePart->Position(0).Z();

  truePart->PositionEnd[0] = ls_truePart->EndX();
  truePart->PositionEnd[1] = ls_truePart->EndY();
  truePart->PositionEnd[2] = ls_truePart->EndZ();

  truePart->Direction[0] = ls_truePart->Px()/ls_truePart->P();
  truePart->Direction[1] = ls_truePart->Py()/ls_truePart->P();
  truePart->Direction[2] = ls_truePart->Pz()/ls_truePart->P();

  size_t np = ls_truePart->NumberTrajectoryPoints();

  truePart->DirectionEnd[0] = ls_truePart->Px(np-2)/ls_truePart->P(np-2);
  truePart->DirectionEnd[1] = ls_truePart->Py(np-2)/ls_truePart->P(np-2);
  truePart->DirectionEnd[2] = ls_truePart->Pz(np-2)/ls_truePart->P(np-2);

  truePart->Momentum = ls_truePart->P();
  truePart->MomentumEnd = ls_truePart->P(np-2);

  //increment generation
  generation++;

  //go for daughters
  truePart->Daughters.clear();

  //loop over daughters to get their IDs
  for(int idau = 0; idau < ls_truePart->NumberDaughters(); idau++){
    //loop over simb::MCParticle to get the daughter
    for(auto const ls_trueDau : pList){
      if(ls_trueDau.second->TrackId() == ls_truePart->Daughter(idau)){
	//skip delta rays
	if(ls_trueDau.second->Process() == "muIoni" || ls_trueDau.second->Process() == "hIoni" || 
	   ls_trueDau.second->Process() == "compt"  || ls_trueDau.second->Process() == "eIoni")continue;
	else{
	  //fill daughters vector
	  truePart->Daughters.push_back(ls_truePart->Daughter(idau));
	  //fill daughter info
	  if(generation < fMCMaxGeneration && ls_truePart->NumberDaughters() > 0)
	    FillTruePartInfo(evt, piServ, pList, ls_trueDau.second, trueParticles, generation);
	}
      }
    }
  }
}

//*****************************************************************************
void highlandAnalysis::CreateHighlandMiniTree::FillBeamInfo(art::Event const &evt, AnaBeamPD* beam){
//*****************************************************************************

  if(fDebug)std::cout << "Filling beam info" << std::endl;

  //get vector of beam events, but use just the first one
  //some criteria is needed if more than 1 beam event is found
  std::string beamtag;
  if(evt.isRealData())beamtag = fBeamModuleLabel;
  else beamtag = fGeneratorTag;
  auto beamHandle = evt.getValidHandle<std::vector<beam::ProtoDUNEBeamEvent>>(beamtag);
  std::vector<art::Ptr<beam::ProtoDUNEBeamEvent>> beamVec;

  if(beamHandle.isValid()){
    art::fill_ptr_vector(beamVec, beamHandle);
  }

  const beam::ProtoDUNEBeamEvent & beamEvent = *(beamVec.at(0)); //Should just have one

  //fill beam intrumentation information
  beam->nTracks = beamEvent.GetBeamTracks().size();
  beam->nMomenta = beamEvent.GetRecoBeamMomenta().size();
   
  beam->TOF = beamEvent.GetTOF();

  std::vector< int > pdgs = fBeamlineUtils.GetPID(beamEvent, fNominalBeamMom);
  beam->PDGs.insert(beam->PDGs.end(), pdgs.begin(), pdgs.end());

  beam->nFibers[0] = beamEvent.GetActiveFibers( "XBPF022697" ).size();
  beam->nFibers[1] = beamEvent.GetActiveFibers( "XBPF022701" ).size();
  beam->nFibers[2] = beamEvent.GetActiveFibers( "XBPF022702" ).size();

  //create the beam particle
  beam->BeamParticle = MakeParticle();

  if(beam->nTracks > 0){

    if(beam->nMomenta > 0)beam->BeamParticle->Momentum = beamEvent.GetRecoBeamMomenta()[0];

    beam->BeamParticle->PositionStart[0] = beamEvent.GetBeamTracks()[0].Trajectory().Start().X();
    beam->BeamParticle->PositionStart[1] = beamEvent.GetBeamTracks()[0].Trajectory().Start().Y();
    beam->BeamParticle->PositionStart[2] = beamEvent.GetBeamTracks()[0].Trajectory().Start().Z();
    beam->BeamParticle->PositionEnd[0]   = beamEvent.GetBeamTracks()[0].Trajectory().End().X();
    beam->BeamParticle->PositionEnd[1]   = beamEvent.GetBeamTracks()[0].Trajectory().End().Y();
    beam->BeamParticle->PositionEnd[2]   = beamEvent.GetBeamTracks()[0].Trajectory().End().Z();

    beam->BeamParticle->DirectionStart[0] = beamEvent.GetBeamTracks()[0].Trajectory().StartDirection().X();
    beam->BeamParticle->DirectionStart[1] = beamEvent.GetBeamTracks()[0].Trajectory().StartDirection().Y();
    beam->BeamParticle->DirectionStart[2] = beamEvent.GetBeamTracks()[0].Trajectory().StartDirection().Z();
    beam->BeamParticle->DirectionEnd[0]   = beamEvent.GetBeamTracks()[0].Trajectory().EndDirection().X();
    beam->BeamParticle->DirectionEnd[1]   = beamEvent.GetBeamTracks()[0].Trajectory().EndDirection().Y();
    beam->BeamParticle->DirectionEnd[2]   = beamEvent.GetBeamTracks()[0].Trajectory().EndDirection().Z();
  }

  if(fDebug)std::cout << "beam information retrieved. Event has " << beam->nTracks << " tracks" << std::endl;
} 

//*****************************************************************************
void highlandAnalysis::CreateHighlandMiniTree::FillBunchInfo(art::Event const &evt,
						  std::vector<AnaTrueParticleB*>& trueParticles,
						  AnaBunch* bunch, AnaSpillPD* spill){
//*****************************************************************************
  
  if(fDebug)std::cout << "Filling bunch info" << std::endl;

  //basic bunch info
  bunch->Bunch  = 1;
  bunch->Weight = 1;

  //create a pfp utils instance, get the primary PFParticle and the vector of PFParticles
  protoana::ProtoDUNEPFParticleUtils pfpUtil;
  std::vector<const recob::PFParticle*> primaryParticles = pfpUtil.GetPFParticlesFromBeamSlice(evt,fPFParticleTag);
  auto pfpVec = evt.getValidHandle<std::vector<recob::PFParticle>>(fPFParticleTag);

  if(primaryParticles.size() == 0){
    std::cout << "No primary particle found" << std::endl;
    return;
  }

  //get the primary particle
  const recob::PFParticle* ls_primaryPart = primaryParticles.at(0);

  //clear particles vector
  bunch->Particles.clear();

  //fill particle info recursively
  int generation = -1;
  
  FillParticleInfo(evt, pfpUtil, pfpVec, ls_primaryPart, trueParticles, bunch, generation);

  // adcs for CNN input

  std::vector<std::vector<float> > reduced_adc_cnn_map;
  std::vector<Int_t> reduced_adc_cnn_map_wires;
  std::vector<Int_t> reduced_adc_cnn_map_times;

  collect_adc_for_CNN(evt,ls_primaryPart,*pfpVec, pfpUtil, fPFParticleTag,reduced_adc_cnn_map, reduced_adc_cnn_map_wires, reduced_adc_cnn_map_times);

  for (size_t wi=0;wi<reduced_adc_cnn_map_wires.size();wi++){
    Int_t wire = reduced_adc_cnn_map_wires[wi];
    Int_t t0   = reduced_adc_cnn_map_times[wi];
    AnaWireCNN cnnwire;
    cnnwire.wire = wire;
    cnnwire.time = t0;
    for (size_t s=0;s<reduced_adc_cnn_map[wi].size();s++){
      //      Int_t time = t0+s;
      cnnwire.adcs.push_back(reduced_adc_cnn_map[wi][s]);
      //      std::cout << wire << " " << t0 << " " << time << std::endl;
      //      spill->ADC[wire][time]=reduced_adc_cnn_map[wi][s];
    }
    static_cast<AnaBunchPD*>(bunch)->CNNwires.push_back(cnnwire);
  }

}


//*****************************************************************************
void highlandAnalysis::CreateHighlandMiniTree::FillParticleInfo(art::Event const &evt,
						     protoana::ProtoDUNEPFParticleUtils &pfpUtil,
						     art::ValidHandle<std::vector<recob::PFParticle>> &pfpVec,
						     const recob::PFParticle* ls_part,
						     std::vector<AnaTrueParticleB*>& trueParticles,
						     AnaBunch* bunch, int generation){
//*****************************************************************************

  //create AnaParticle and add it to the bunch
  AnaParticlePD* part = MakeParticle();
  bunch->Particles.push_back(part);

  //if mc try to match a truth particle
  if(!evt.isRealData()){
    int truePartID = GetTrueParticleID(evt, ls_part);
    for(int itrue = 0; itrue < (int)trueParticles.size(); itrue++){
      if(truePartID == trueParticles.at(itrue)->ID){
	if(fDebug)std::cout << "matching true particle found" << std::endl;
	part->TrueObject = trueParticles.at(itrue);
	break;
      }
    }
  }

  //fill PFP basic info
  part->isPandora = ls_part->IsPrimary();
  part->UniqueID = ls_part->Self();

  //get number of hits of the PFP regardless track or shower
  const std::vector<art::Ptr<recob::Hit>> ls_part_hits = pfpUtil.GetPFParticleHits_Ptrs(*ls_part, evt, fPFParticleTag);
  part->NHits = ls_part_hits.size();

  // Determine if the particle is track-like or shower-like
  const recob::Track* track = pfpUtil.GetPFParticleTrack(*ls_part,evt,fPFParticleTag,fTrackerTag);
  const recob::Shower* shower = pfpUtil.GetPFParticleShower(*ls_part,evt,fPFParticleTag,fShowerTag);

  //fill track-like info or showerlike info
  if(track)FillTrackInfo(evt,track,part);
  if(shower)FillShowerInfo(shower,part);

  //go for CNN
  //CNN Outputs: Track, EM, Michel, Empty
  anab::MVAReader<recob::Hit,4> mvaReader(evt, "emtrkmichelid:emtrkmichel");
  //get cnn for plane 2
  std::pair<float*, int> cnnResult = GetCNNOutputFromPFParticleFromPlane(evt, mvaReader, pfpUtil, *ls_part, 2);
  for(int i = 0; i < 3; i++)part->CNNscore[i] = cnnResult.first[i] / cnnResult.second;

  //increment generation
  generation++;

  //go for daughters
  part->DaughtersIDs.clear();
  
  //loop over daughters
  for(int idau = 0; idau < ls_part->NumDaughters(); idau++){
    //get daughter matching id
    const recob::PFParticle* ls_dau = &(pfpVec->at(ls_part->Daughter(idau)));
    //fill daughters id vector
    part->DaughtersIDs.push_back(ls_dau->Self());
    //fill daughter info
    if(generation < fMaxGeneration)
      FillParticleInfo(evt, pfpUtil, pfpVec, ls_dau, trueParticles, bunch, generation);
  }
}

//*****************************************************************************
void highlandAnalysis::CreateHighlandMiniTree::FillTrackInfo(art::Event const &evt, const recob::Track* track, AnaParticlePD* part){
//*****************************************************************************

  //fill track basic info
  part->Type = AnaParticlePD::kTrack;
  
  part->PositionStart[0] = track->Start().X();
  part->PositionStart[1] = track->Start().Y();
  part->PositionStart[2] = track->Start().Z();
  
  part->PositionEnd[0] = track->End().X();
  part->PositionEnd[1] = track->End().Y();
  part->PositionEnd[2] = track->End().Z();
    
  part->DirectionStart[0] = track->StartDirection().X();
  part->DirectionStart[1] = track->StartDirection().Y();
  part->DirectionStart[2] = track->StartDirection().Z();
  
  part->DirectionEnd[0] = track->EndDirection().X();
  part->DirectionEnd[1] = track->EndDirection().Y();
  part->DirectionEnd[2] = track->EndDirection().Z();
    
  part->Length = track->Length();

  //fill hit basic info
  for(int iplane = 0; iplane < 3; iplane++)part->Hits[iplane].clear();

  //create a track utils instance and get calo information
  protoana::ProtoDUNETrackUtils trackUtil;
  std::vector<anab::Calorimetry> SCEcalo = trackUtil.GetRecoTrackCalorimetry(*track, evt, fTrackerTag, fCalorimetryTagSCE);
  std::vector<anab::Calorimetry> NoSCEcalo = trackUtil.GetRecoTrackCalorimetry(*track, evt, fTrackerTag, fCalorimetryTagNoSCE);

  //safety check
  if(SCEcalo.empty() || NoSCEcalo.empty()) return;

  //get a handle of all hits
  auto allHits = evt.getValidHandle<std::vector<recob::Hit>>(fHitTag);
  //get calibrated dEdx
  std::vector<float> dEdx_SCE_cal = calibrationSCE.GetCalibratedCalorimetry(*track, evt, fTrackerTag, fCalorimetryTagSCE, 2, -1.);

  //number of hits
  part->NHitsPerPlane[2] = SCEcalo[0].dQdx().size();

  //loop over hits. Index 0 == recollection plane 2
  for(int ihit = 0; ihit < (int)SCEcalo[0].dQdx().size(); ihit++){
    //create a highland hit and a LArSoft hit
    AnaHitPD hit;
    const recob::Hit & ls_hit = (*allHits)[SCEcalo[0].TpIndices().at(ihit)];

    //fill calo info
    if(ihit < (int)NoSCEcalo[0].dQdx().size()) hit.dQdx_NoSCE = NoSCEcalo[0].dQdx().at(ihit);
    hit.dQdx       = SCEcalo[0].dQdx().at(ihit);

    hit.dEdx       = SCEcalo[0].dEdx().at(ihit);
    if(ihit < (int)dEdx_SCE_cal.size())hit.dEdx_calib = dEdx_SCE_cal.at(ihit);

    hit.ResidualRange = SCEcalo[0].ResidualRange().at(ihit);

    hit.Position.SetXYZ(SCEcalo[0].XYZ().at(ihit).X(), SCEcalo[0].XYZ().at(ihit).Y(), SCEcalo[0].XYZ().at(ihit).Z());

    //fill hit info
    hit.Integral = ls_hit.Integral();
    hit.PeakTime = ls_hit.PeakTime();
    hit.PeakAmplitude = ls_hit.PeakAmplitude();

    hit.StartTick = ls_hit.StartTick();
    hit.EndTick = ls_hit.EndTick();

    hit.Channel = ls_hit.Channel();
    hit.View = ls_hit.View();

    hit.WireID.Plane = 2; //the only one we are saving for the moment
    hit.WireID.Wire  = ls_hit.WireID().Wire;

    //add it to the vector of this
    part->Hits[2].push_back(hit);
  }

  //compute truncated mean
  part->truncLibo_dEdx = pdAnaUtils::ComputeTruncatedMean(0.16,0.16,part->Hits[2]);
}

//*****************************************************************************
void highlandAnalysis::CreateHighlandMiniTree::FillShowerInfo(const recob::Shower* shower, AnaParticlePD* part){
//*****************************************************************************

  //fill shower basic info
  part->Type = AnaParticlePD::kShower;

  part->PositionStart[0] = shower->ShowerStart().X();
  part->PositionStart[1] = shower->ShowerStart().Y();
  part->PositionStart[2] = shower->ShowerStart().Z();
  
  part->DirectionStart[0] = shower->Direction().X();
  part->DirectionStart[1] = shower->Direction().Y();
  part->DirectionStart[2] = shower->Direction().Z();
  
  part->Length = shower->Length();

}

//*****************************************************************************
int highlandAnalysis::CreateHighlandMiniTree::GetTrueParticleID(art::Event const &evt, const recob::PFParticle* ls_part){
//*****************************************************************************

  //create a truth utils instance
  protoana::ProtoDUNETruthUtils truthUtil;

  //create a clock instance
  auto const clockData = art::ServiceHandle<detinfo::DetectorClocksService>()->DataFor(evt);

  //look for the MCParticle that most probably generated the PFParticle
  const simb::MCParticle* ls_truePart = truthUtil.GetMCParticleFromPFParticle(clockData, *ls_part, evt, fPFParticleTag);

  if(ls_truePart)return ls_truePart->TrackId();
  else{
    std::cout << "no match trueparticle found" << std::endl;
    return -1;
  }

}

//*****************************************************************************
std::pair<float*, int> highlandAnalysis::CreateHighlandMiniTree::
GetCNNOutputFromPFParticleFromPlane(const art::Event &evt,
				    const anab::MVAReader<recob::Hit,4> &CNN_results,
				    protoana::ProtoDUNEPFParticleUtils& pfpUtil, 
				    const recob::PFParticle &part,
				    int planeID){
//*****************************************************************************
  
  //get hits from plane
  const std::vector<art::Ptr<recob::Hit>> daughterPFP_hits = 
    pfpUtil.GetPFParticleHitsFromPlane_Ptrs(part, evt, fPFParticleTag, planeID);
  
  //loop over hits
  float cnn[4] = {0};
  int nhits = 0;
  //  std::cout << "CNN outputs for hits: #hits = " << daughterPFP_hits.size() << std::endl;
  for(int ihit = 0; ihit < (int)daughterPFP_hits.size(); ihit++){
    std::array<float,4> cnn_out = CNN_results.getOutput(daughterPFP_hits[ihit]);
    //    std::cout << ihit << ": " << daughterPFP_hits[ihit]->Channel() << " " << daughterPFP_hits[ihit]->PeakTime() << " --> " << cnn_out[CNN_results.getIndex("track")] << " " << cnn_out[CNN_results.getIndex("em")] << " " << cnn_out[CNN_results.getIndex("michel")] << std::endl;
    cnn[0] += cnn_out[ CNN_results.getIndex("track") ];
    cnn[1] += cnn_out[ CNN_results.getIndex("em") ];
    cnn[2] += cnn_out[ CNN_results.getIndex("michel") ];
    cnn[3] += cnn_out[ CNN_results.getIndex("none") ];
    nhits++;
  }
  
  std::pair<float*, int> output(cnn, nhits);
  
  return output;
}


//*****************************************************************************
void highlandAnalysis::CreateHighlandMiniTree::beginJob(){
//*****************************************************************************

  art::ServiceHandle<art::TFileService> tfs;
  fTree = tfs->make<TTree>("MiniTree","event model tree");
  fspill = NULL;
  fTree->Branch("Spill", "AnaSpillPD", &fspill,64000,1);

  
}

//*****************************************************************************
void highlandAnalysis::CreateHighlandMiniTree::endJob(){
//*****************************************************************************
  
  //create header file
  art::ServiceHandle<art::TFileService> tfs;
  fHeaderTree = tfs->make<TTree>("header","header tree");
  Header* headerp = NULL;                                                                                                         
  fHeaderTree->Branch("POTInfo","Header",&headerp,32000,0);                                                                
  fHeaderTree->Fill();

  //delete last spill before exiting
  delete fspill;

}

//*****************************************************************************
void highlandAnalysis::CreateHighlandMiniTree::reset(){
//*****************************************************************************
  
}

//*****************************************************************************
void highlandAnalysis::CreateHighlandMiniTree::collect_adc_for_CNN(const art::Event & evt, const recob::PFParticle* particle, const std::vector<recob::PFParticle>& pfpVec, 
								   protoana::ProtoDUNEPFParticleUtils & pfpUtil,const std::string& fPFParticleTag,
								   std::vector<std::vector<float> >& reduced_adc_cnn_map,
								   std::vector<Int_t>& reduced_adc_cnn_map_wires,
								   std::vector<Int_t>& reduced_adc_cnn_map_times){
  //*****************************************************************************

   bool debug=false;

   //  art::InputTag fWireProducerLabel = "wclsdatanfsp:gauss";
  art::InputTag fWireProducerLabel = "wclsdatasp:gauss";
  auto wireHandle = evt.getValidHandle< std::vector<recob::Wire> >(fWireProducerLabel);
  //  auto const& wires = evt.getValidHandle<std::vector<recob::Wire> >("wclsdatanfsp:gauss");
  //  size_t nTotalWires = wires->size();
  //  if (debug) std::cout << "#wires = " << nTotalWires << std::endl;
  if (!wireHandle) return;

  size_t nTotalWires = wireHandle->size();
  if (debug) std::cout << "#wires = " << nTotalWires << std::endl;
  /*
  for (size_t i=0;i<wireHandle->size();i++){
    if (debug) std::cout << i << " " << (*wireHandle)[i].Channel()  << " " << (*wireHandle)[i].View() << " " << (*wireHandle)[i].Signal().size() << std::endl;
    if (i==0)
      for (size_t j=0;j<(*wireHandle)[i].Signal().size(); j++)
	if (debug) std::cout << j << " " <<  (*wireHandle)[i].Signal()[j] << std::endl;

    std::vector<geo::WireID> wireIDs = geom->ChannelToWire((*wireHandle)[i].Channel());  
    if (debug) std::cout << "#  wireIDs = " << wireIDs.size() << std::endl;
    for (auto const& id : wireIDs) {
      if (debug) std::cout << "    - " << id.Cryostat << " " << id.TPC << " " << id.Plane << " " << id.Wire << std::endl;
    }
  }
  */


  std::vector<std::vector<std::vector<float> > > adc_cnn_map;
    std::vector<Float_t> adc_cnn; // anselmo
    adc_cnn_map.resize(nTotalWires);
    std::vector<bool> adc_cnn_map_wire_filled(nTotalWires,false);
    for (size_t i=0;i<nTotalWires;i++) adc_cnn_map[i].clear();

    std::vector<int> adc_cnn_map_tmin(nTotalWires,1000000);
    std::vector<int> adc_cnn_map_tmax(nTotalWires,-1000000);

    std::vector<size_t> particleIDs;

    particleIDs.push_back(particle->Self());
    // loop over beam particle daughter ID's
    for( size_t daughterID : particle->Daughters() ){
      particleIDs.push_back(daughterID);
    }

    for( size_t pID : particleIDs ){
      // get the particle with that ID
      const recob::PFParticle * partPFP = &(pfpVec.at( pID ));

      // get the hits for that particle
      const std::vector< art::Ptr< recob::Hit > > partPFP_hits = pfpUtil.GetPFParticleHits_Ptrs( *partPFP, evt, fPFParticleTag );
     
      if (debug) std::cout << "anselmo: hits in particle. #hits = " << partPFP_hits.size() << std::endl;
      
      // loop over hits in particle
      for (size_t i = 0; i < partPFP_hits.size(); ++i) {

	// use only the collection plane
        if (partPFP_hits[i]->View() != 2) continue;

	// wire ID for that hit
	const geo::WireID& id = partPFP_hits[i]->WireID();
	
	// channel number for that hit
	size_t wh=partPFP_hits[i]->Channel();

	if (debug) std::cout << "    - Hit: " << i << " " << " " << wh << " " << (*wireHandle)[wh].Signal().size() 
		  << " " << partPFP_hits[i]->StartTick() << "-" << partPFP_hits[i]->EndTick()
		  << " " << id.Cryostat << " " << id.TPC << " " << id.Plane << " " << id.Wire << std::endl;
	
	
	size_t nadc_hit=0;
	
	// start and end time for the hit waveform 
	int t0 = partPFP_hits[i]->StartTick();
	int t1 = partPFP_hits[i]->EndTick();
	
	// compute the maximum and minimum times for that channel
	if (t0<adc_cnn_map_tmin[wh]) adc_cnn_map_tmin[wh]=t0;
	if (t1>adc_cnn_map_tmax[wh]) adc_cnn_map_tmax[wh]=t1;
		
	//  create an entry in the map when the channel is not yet filled
	if (adc_cnn_map[wh].empty()){
	  adc_cnn_map[wh].resize(6000);
	  for (size_t t=0;t<6000;t++) adc_cnn_map[wh][t].clear();
	}
	
	// create a waveform starting at t0
	if (adc_cnn_map[wh][t0].empty()){
	  for (int t=partPFP_hits[i]->StartTick();t<=partPFP_hits[i]->EndTick();t++){
	    //	      if (debug) std::cout << "    - " << t << " " << (*wireHandle)[wh].Signal()[t] << std::endl; 
	    // tis is just for crosschecks. In principle all values should be above 0
	    if ((*wireHandle)[wh].Signal()[t]>0){ 
	      adc_cnn.push_back((*wireHandle)[wh].Signal()[t]);
	    }
	    // fill the map for that channel and t0
	    adc_cnn_map[wh][t0].push_back((*wireHandle)[wh].Signal()[t]);
	    adc_cnn_map_wire_filled[wh]= true;
	    nadc_hit++;
	  }
	}
	
	// loop over a range of wires in both sides of the nominal wire
	for (size_t w=wh-44/2;w<wh+44/2;w++){
	  // Create an entry for that wire (only when it has not been created previously)
	  if (adc_cnn_map[w].empty()){
	    adc_cnn_map[w].resize(6000);
	    for (size_t t=0;t<6000;t++) adc_cnn_map[w][t].clear();
	    adc_cnn_map_wire_filled[w]=false;
	  }
	  
	  if (t0<adc_cnn_map_tmin[w]) adc_cnn_map_tmin[w]=t0;
	  if (t1>adc_cnn_map_tmax[w]) adc_cnn_map_tmax[w]=t1;
	}
	if (debug) std::cout << "        ---> " << nadc_hit << " adcs for this hit" << std::endl;
      }  // end loop over hits
    }  // end loop over particless

    // add samples with time 288/2 below and above the minimum and maximum times for each wire   
    size_t nadc_samples=0;

    if (debug) std::cout << "anselmo: find adcs in window" << std::endl;

    // loop over all wires
    for (size_t w=0;w<nTotalWires;w++){
      // but used only the ones in the window for any of the hits 
      if (adc_cnn_map[w].empty()) continue;

      // Search for pulses starting at t0-288/2
      int t0=adc_cnn_map_tmin[w]-288/2;
      if (t0<0) t0=0;
      if (debug) std::cout << " wire, t0 " << w << " " << t0 << std::endl; 
      size_t nadc_samples_t0=0;
      bool t0_found=false;
      for (int t=adc_cnn_map_tmin[w]-288/2;t<adc_cnn_map_tmax[w]+288/2;t++){

	if (t>=adc_cnn_map_tmin[w] && t<=adc_cnn_map_tmax[w] && adc_cnn_map_wire_filled[w]){
	  // added preeviously to the map. Just count
	  nadc_samples += adc_cnn_map[w][t].size();
	  continue ;
	}
	// a new pulse is found when there is a signal over 0 after an empty block
	if ((*wireHandle)[w].Signal()[t]>0){
	  if (!t0_found && adc_cnn_map[w][t].empty()){  // make sure this pulse was not previously added
	    t0=t;
	    t0_found=true;
	    if (debug) std::cout << "    new t0 " << t0 << std::endl; 
	  }
	  //	  if (debug) std::cout << "        - " << t << " " << (*wireHandle)[w].Signal()[t] << std::endl; 
	  // add all elements to the pulse/waveform
	  adc_cnn_map[w][t0].push_back((*wireHandle)[w].Signal()[t]);
	  nadc_samples++;
	  nadc_samples_t0++;
	}
	else{
	  if (t0_found) if (debug) std::cout << "        --> #samples for this t0 = " << nadc_samples_t0 << std::endl;
	  nadc_samples_t0=0;
	  t0_found=false;
	}
      }
      
    }
    

    int adc_values=0, adc_values_gt0=0;
    std::vector<float> reduced_adc_cnn_map_waveform;

    if (debug) std::cout << "####################### adc values from particles: " << std::endl;
    for (size_t w=0;w<nTotalWires;w++){
      if (adc_cnn_map[w].empty()) continue;
      for (size_t t=0;t<adc_cnn_map[w].size();t++){
	if (adc_cnn_map[w][t].empty()) continue;
	reduced_adc_cnn_map_waveform.clear();
	for (size_t s=0;s<adc_cnn_map[w][t].size();s++){
	  //	  if (adc_cnn_map[w][t][s]>0)
	    if (debug) std::cout << w << " " << t << " " << s << " " <<adc_cnn_map[w][t][s]  << std::endl;
	    if (adc_cnn_map[w][t][s]>0) adc_values_gt0++;
	    adc_values++;
	    reduced_adc_cnn_map_waveform.push_back(adc_cnn_map[w][t][s]);
	}
	reduced_adc_cnn_map.push_back(reduced_adc_cnn_map_waveform);
	reduced_adc_cnn_map_wires.push_back(w);
	reduced_adc_cnn_map_times.push_back(t);
      }
    }

    if (debug) std::cout << "####################### adc values from particles = " 
	      << adc_cnn.size() << " " 
	      << nadc_samples   << " " 
	      << adc_values     << " " 
	      << adc_values_gt0 << std::endl;

    if (debug) std::cout << "####################### reduced adc map ################ " << std::endl;
    for (size_t w=0;w<reduced_adc_cnn_map_wires.size();w++){
      if (debug) std::cout << w << " " << reduced_adc_cnn_map_wires[w] << " " << reduced_adc_cnn_map_times[w] << " \t--> ";
      for (size_t s=0;s<reduced_adc_cnn_map[w].size();s++){
	if (debug) std::cout << reduced_adc_cnn_map[w][s] << " ";
      }
      if (debug) std::cout << std::endl;
    }

    
}


DEFINE_ART_MODULE(highlandAnalysis::CreateHighlandMiniTree)
