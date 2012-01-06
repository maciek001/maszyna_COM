//---------------------------------------------------------------------------

#ifndef TrainH
#define TrainH

#include "Track.h"
#include "TrkFoll.h"
#include "Model3d.h"
#include "Spring.h"
#include "Gauge.h"
#include "Button.h"
#include "DynObj.h"
#include "mtable.hpp"

#include "Sound.h"
#include "AdvSound.h"
#include "RealSound.h"
#include "FadeSound.h"


// typedef enum {st_Off, st_Starting, st_On, st_ShuttingDown} T4State;

const int maxcab=2;

// const double fCzuwakTime= 90.0f;
const double fCzuwakBlink= 0.15f;
const float fConverterPrzekaznik = 1.5f; //hunter-261211: do przekaznika nadmiarowego przetwornicy
                         //0.33f
// const double fBuzzerTime= 5.0f;

// const double fStycznTime= 0.5f;
// const double fDblClickTime= 0.2f;

class TCab
{
 public:
  __fastcall TCab();
  __fastcall ~TCab();
  void __fastcall Init(double Initx1,double Inity1,double Initz1,double Initx2,double Inity2,double Initz2,bool InitEnabled,bool InitOccupied);
  void __fastcall Load(TQueryParserComp *Parser);
  vector3 CabPos1;
  vector3 CabPos2;
  bool bEnabled;
  bool bOccupied;
  double dimm_r, dimm_g, dimm_b;                 //McZapkie-120503: tlumienie swiatla
  double intlit_r, intlit_g, intlit_b;           //McZapkie-120503: oswietlenie kabiny
  double intlitlow_r, intlitlow_g, intlitlow_b;  //McZapkie-120503: przyciemnione oswietlenie kabiny
private:
  bool bChangePossible;
};


class TTrain//:public TDynamicObject
{
public:
    bool CabChange(int iDirection);
    bool ActiveUniversal4;
    bool ShowNextCurrent; //pokaz przd w podlaczonej lokomotywie (ET41)
    bool InitializeCab(int NewCabNo, AnsiString asFileName);
    __fastcall TTrain();
    __fastcall ~TTrain();
//    bool __fastcall Init(TTrack *Track);
//McZapkie-010302
    bool __fastcall Init(TDynamicObject *NewDynamicObject);
    void __fastcall OnKeyPress(int cKey);

//    bool __fastcall SHP() { fShpTimer= 0; };

    inline vector3 __fastcall GetDirection() { return DynamicObject->GetDirection(); };
    inline vector3 __fastcall GetUp() { return DynamicObject->vUp; };
    void __fastcall UpdateMechPosition(double dt);
    bool __fastcall Update();
//    virtual bool __fastcall RenderAlpha();
//McZapkie-310302: ladowanie parametrow z pliku
    bool __fastcall LoadMMediaFile(AnsiString asFileName);

    TDynamicObject *DynamicObject;

    AnsiString asMessage;

//McZapkie: definicje wskaznikow
    TGauge VelocityGauge;
    TGauge I1Gauge;
    TGauge I2Gauge;
    TGauge I3Gauge;
    TGauge ItotalGauge;
    TGauge CylHamGauge;
    TGauge PrzGlGauge;
    TGauge ZbGlGauge;
    //ABu: zdublowane dla dwukierunkowych kabin
       TGauge VelocityGaugeB;
       TGauge I1GaugeB;
       TGauge I2GaugeB;
       TGauge I3GaugeB;
       TGauge ItotalGaugeB;
       TGauge CylHamGaugeB;
       TGauge PrzGlGaugeB;
       TGauge ZbGlGaugeB;
    //******************************************
    TGauge ClockSInd;
    TGauge ClockMInd;
    TGauge ClockHInd;
    TGauge HVoltageGauge;
    TGauge LVoltageGauge;
    TGauge enrot1mGauge;
    TGauge enrot2mGauge;
    TGauge enrot3mGauge;
    TGauge engageratioGauge;
    TGauge maingearstatusGauge;

    TGauge EngineVoltage;
    TGauge I1BGauge;
    TGauge I2BGauge;
    TGauge I3BGauge;
    TGauge ItotalBGauge;

//McZapkie: definicje regulatorow
    TGauge MainCtrlGauge;
    TGauge MainCtrlActGauge;    
    TGauge ScndCtrlGauge;
    TGauge ScndCtrlButtonGauge;
    TGauge DirKeyGauge;
    TGauge BrakeCtrlGauge;
    TGauge LocalBrakeGauge;

    TGauge BrakeProfileCtrlGauge;
    TGauge MaxCurrentCtrlGauge;

    TGauge MainOffButtonGauge;
    TGauge MainOnButtonGauge;
    TGauge MainButtonGauge; //EZT
    TGauge SecurityResetButtonGauge;
    TGauge ReleaserButtonGauge;
    TGauge AntiSlipButtonGauge;
    TGauge FuseButtonGauge;
    TGauge ConverterFuseButtonGauge; //hunter-261211: przycisk odblokowania nadmiarowego przetwornic i ogrzewania
    TGauge StLinOffButtonGauge;
    TGauge RadioButtonGauge;
    TGauge UpperLightButtonGauge;
    TGauge LeftLightButtonGauge;
    TGauge RightLightButtonGauge;
    TGauge LeftEndLightButtonGauge;
    TGauge RightEndLightButtonGauge;
    TGauge IgnitionKeyGauge;

    TGauge CompressorButtonGauge;
    TGauge ConverterButtonGauge;
    TGauge ConverterOffButtonGauge;

//ABu 090305 - syrena i prad nastepnego czlonu
    TGauge HornButtonGauge;
    TGauge NextCurrentButtonGauge;
//ABu 090305 - uniwersalne przyciski
    TGauge Universal1ButtonGauge;
    TGauge Universal2ButtonGauge;
    TGauge Universal3ButtonGauge;
    TGauge Universal4ButtonGauge;
//NBMX wrzesien 2003 - obsluga drzwi
    TGauge DoorLeftButtonGauge;
    TGauge DoorRightButtonGauge;
    TGauge DepartureSignalButtonGauge;

//Winger 160204 - obsluga pantografow - ZROBIC
    TGauge PantFrontButtonGauge;
    TGauge PantRearButtonGauge;
    TGauge PantFrontButtonOffGauge; //EZT
    TGauge PantAllDownButtonGauge;
//Winger 020304 - wlacznik ogrzewania
    TGauge TrainHeatingButtonGauge;


//    TModel3d *mdKabina; McZapkie-030303: to do dynobj

    TButton btLampkaPoslizg;
    TButton btLampkaStyczn;
    TButton btLampkaNadmPrzetw;
    TButton btLampkaPrzekRozn;
    TButton btLampkaPrzekRoznPom;
    TButton btLampkaNadmSil;
    TButton btLampkaWylSzybki;
    TButton btLampkaNadmWent;
    TButton btLampkaNadmSpr;
//yB: drugie lampki dla EP05 i ET42
      TButton btLampkaOporyB;
      TButton btLampkaStycznB;
      TButton btLampkaWylSzybkiB;
      TButton btLampkaNadmPrzetwB;

//    TButton btLampkaUnknown;
    TButton btLampkaOpory;
    TButton btLampkaWysRozr;
    TButton btLampkaUniversal3;
    int LampkaUniversal3_typ; //ABu 030405 - swiecenie uzaleznione od: 0-nic, 1-obw.gl, 2-przetw.
    bool LampkaUniversal3_st;
    TButton btLampkaWentZaluzje;     //ET22
    TButton btLampkaOgrzewanieSkladu;
    TButton btLampkaSHP;
    TButton btLampkaCzuwaka;  //McZapkie-141102
    TButton btLampkaRezerwa;
//youBy - jakies dodatkowe lampki
    TButton btLampkaNapNastHam;
    TButton btLampkaSprezarka;
    TButton btLampkaSprezarkaB;    
    TButton btLampkaBocznikI;
    TButton btLampkaBocznikII;
    TButton btLampkaRadiotelefon;
    TButton btLampkaHamienie;
    TButton btLampkaJazda;                   
//    TButton bt;
//
    TButton btLampkaDoorLeft;
    TButton btLampkaDoorRight;
    TButton btLampkaDepartureSignal;

    TButton btLampkaForward; //Ra: lampki w prz�d i w ty� dla komputerowych kabin
    TButton btLampkaBackward;

    vector3 pPosition;
    vector3 pMechOffset;
    vector3 vMechMovement;
    vector3 pMechPosition;
    vector3 pMechShake;
    vector3 vMechVelocity;
//McZapkie: do poruszania sie po kabinie
    double fMechCroach;
//McZapkie: opis kabiny - obszar poruszania sie mechanika oraz zajetosc
    TCab Cabine[maxcab+1];  //przedzial maszynowy, kabina 1 (A), kabina 2 (B)
    int iCabn;
    TSpring MechSpring;
    double fMechSpringX;  //McZapkie-250303: parametry bujania
    double fMechSpringY;
    double fMechSpringZ;
    double fMechMaxSpring;
    double fMechRoll;
    double fMechPitch;

    PSound dsbNastawnikJazdy;
    PSound dsbNastawnikBocz; //hunter-081211
    PSound dsbRelay;
    PSound dsbPneumaticRelay;
    PSound dsbSwitch;
    PSound dsbPneumaticSwitch;    
    PSound dsbReverserKey; //hunter-121211

    PSound dsbCouplerAttach;
    PSound dsbCouplerDetach;

    PSound dsbDieselIgnition;

    PSound dsbDoorClose;
    PSound dsbDoorOpen;

//Winger 010304
    PSound dsbPantUp;
    PSound dsbPantDown;

    PSound dsbWejscie_na_bezoporow;
    PSound dsbWejscie_na_drugi_uklad; //hunter-081211: poprawka literowki


//    PSound dsbHiss1;
  //  PSound dsbHiss2;

//McZapkie-280302
    TRealSound rsBrake;
    TRealSound rsSlippery;
    TRealSound rsHiss;
    TRealSound rsSBHiss;
    TRealSound rsRunningNoise;
    TRealSound rsEngageSlippery;
    TRealSound rsFadeSound;

    PSound dsbHasler;
    PSound dsbBuzzer;
    PSound dsbSlipAlarm; //Bombardier 011010: alarm przy poslizgu dla 181/182
    TFadeSound sConverter;  //przetwornica
    TFadeSound sSmallCompressor;  //przetwornica

    int iCabLightFlag; //McZapkie:120503: oswietlenie kabiny (0: wyl, 1: przyciemnione, 2: pelne)
    vector3 pMechSittingPosition; //ABu 180404
private:
    //PSound dsbBuzzer;
        PSound dsbCouplerStretch;
        PSound dsbBufferClamp;
//    TSubModel *smCzuwakShpOn;
//    TSubModel *smCzuwakOn;
//    TSubModel *smShpOn;
//    TSubModel *smCzuwakShpOff;
//    double fCzuwakTimer;
    double fBlinkTimer;
    float fConverterTimer;  //hunter-261211: dla przekaznika
    float fMainRelayTimer;  //hunter-141211: zalaczanie WSa z opoznieniem
    int CAflag; //hunter-131211: dla osobnego zbijania CA i SHP

//    double fShpTimer;
//    double fDblClickTimer;
    //ABu: Przeniesione do public. - Wiem, ze to nieladnie...
    //bool CabChange(int iDirection);
    //bool InitializeCab(int NewCabNo, AnsiString asFileName);
    TTrack *tor;
    int keybrakecount;
//McZapkie-240302 - przyda sie do tachometru
    float fTachoVelocity;
    float fTachoCount;
//McZapkie: do syczenia
    float fPPress,fNPress;
    float fSPPress,fSNPress;
 int iSekunda; //Ra: sekunda aktualizacji pr�dko�ci
};
//---------------------------------------------------------------------------
#endif