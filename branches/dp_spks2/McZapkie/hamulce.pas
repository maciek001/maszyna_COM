unit hamulce;          {fizyka hamulcow dla symulatora}

(*
    MaSzyna EU07 locomotive simulator
    Copyright (C) 2001-2010  Maciej Czapkiewicz and others

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*)

(*
    MaSzyna EU07 - SPKS
    Brakes.
    Copyright (C) 2007-2012 Maciej Cierniak
*)


(*
(C) youBy
Co brakuje:
Knorr, knorr, knorr i moze jeszcze jakis knorr albo SW
*)
(*
Zrobione:
ESt3, ESt3AL2, ESt4R, LSt, FV4a, FD1, EP2, prosty westinghouse
duzo wersji �eliwa
KE
Tarcze od 152A
Magnetyki (implementacja w mover.pas)
*)

interface

uses mctools,sysutils,friction;

CONST

   LocalBrakePosNo=10;         {ilosc nastaw hamulca recznego lub pomocniczego}
   MainBrakeMaxPos=10;          {max. ilosc nastaw hamulca zasadniczego}

   {nastawy hamulca}
   bdelay_G=1;    //G
   bdelay_P=2;    //P
   bdelay_R=4;    //R
   bdelay_M=8;    //Mg
   bdelay_GR=128; //G-R


   {stan hamulca}
   b_off =  0;   //luzowanie
   b_hld =  1;   //trzymanie
   b_on  =  2;   //napelnianie
   b_rfl =  4;   //uzupelnianie
   b_rls =  8;   //odluzniacz
   b_ep  = 16;   //elektropneumatyczny
   b_asb = 32;   //elektropneumatyczny   
   b_dmg =128;   //wylaczony z dzialania

   {uszkodzenia hamulca}
   df_on  =  1;  //napelnianie
   df_off =  2;  //luzowanie
   df_br  =  4;  //wyplyw z ZP
   df_vv  =  8;  //wyplyw z komory wstepnej
   df_bc  = 16;  //wyplyw z silownika
   df_cv  = 32;  //wyplyw z ZS
   df_PP  = 64;  //zawsze niski stopien
   df_RR  =128;  //zawsze wysoki stopien

   {pary cierne}
   bp_P10    =   0;
   bp_P10Bg  =   2; //�eliwo fosforowe P10
   bp_P10Bgu =   1;
   bp_LLBg   =   4; //komp. b.n.t.
   bp_LLBgu  =   3;
   bp_LBg    =   6; //komp. n.t.
   bp_LBgu   =   5;
   bp_KBg    =   8; //komp. w.t.
   bp_KBgu   =   7;
   bp_D1     =   9; //tarcze
   bp_D2     =  10;
   bp_FR513  =  11; //Frenoplast FR513
   bp_Cosid  =  12; //jakistam kompozyt :D
   bp_PKPBg  =  13; //�eliwo PKP
   bp_PKPBgu =  14;
   bp_MHS    = 128; //magnetyczny hamulec szynowy
   bp_P10yBg =  15; //�eliwo fosforowe P10
   bp_P10yBgu=  16;

   Spg=0.7917;
   SpO=0.5067;  //przekroj przewodu 1" w l/m
                //wyj: jednostka dosyc dziwna, ale wszystkie obliczenia
                //i pojemnosci sa podane w litrach (rozsadne wielkosci)
                //zas dlugosc pojazdow jest podana w metrach
                //a predkosc przeplywu w m/s

//   BPT: array[-2..6] of array [0..1] of real= ((0, 5.0), (14, 5.4), (9, 5.0), (6, 4.6), (9, 4.5), (9, 4.0), (9, 3.5), (9, 2.8), (34, 2.8));
   BPT: array[-2..6] of array [0..1] of real= ((0, 5.0), (10, 5.0), (5, 5.0), (5, 4.6), (5, 4.2), (5, 3.8), (5, 3.4), (5, 2.8), (13, 2.8));
   BPT_394: array[-1..5] of array [0..1] of real= ((13, 10.0), (5, 5.0), (0, -1), (5, -1), (5, 0.0), (5, 0.0), (18, 0.0));
//   BPT: array[-2..6] of array [0..1] of real= ((0, 5.0), (12, 5.4), (9, 5.0), (9, 4.6), (9, 4.2), (9, 3.8), (9, 3.4), (9, 2.8), (34, 2.8));
//      BPT: array[-2..6] of array [0..1] of real= ((0, 0),(0, 0),(0, 0),(0, 0),(0, 0),(0, 0),(0, 0),(0, 0),(0, 0));
   i_bcpno= 6;

TYPE
  //klasa obejmujaca pojedyncze zbiorniki
    TReservoir= class
      private
        Cap: real;
        Vol: real;
        dVol: real;
      public
        constructor Create;
        procedure CreateCap(Capacity: real);
        procedure CreatePress(Press: real);
        function pa: real; virtual;
        function P: real; virtual;
        procedure Flow(dv: real);
        procedure Act;
    end;

    TBrakeCyl= class(TReservoir)
      public
        function pa: real; override;
        function P: real; override;
    end;

  //klasa obejmujaca uklad hamulca zespolonego pojazdu
    TBrake= class
      private
        BrakeCyl: TReservoir;      //silownik
        BrakeRes: TReservoir;      //ZP
        ValveRes: TReservoir;      //komora wstepna
        BCN: byte;                 //ilosc silownikow
        BCM: real;                 //przekladnia hamulcowa
        BCA: real;                 //laczny przekroj silownikow
        BrakeDelays: byte;         //dostepne opoznienia
        BrakeDelayFlag: byte;      //aktualna nastawa
        FM: TFricMat;              //material cierny
        MaxBP: real;               //najwyzsze cisnienie
        BA: byte;                  //osie hamowane
        NBpA: byte;                //klocki na os
        SizeBR: real;              //rozmiar^2 ZP (w stosunku do 14")
        SizeBC: real;              //rozmiar^2 CH (w stosunku do 14")
        DCV: boolean;              //podwojny zawor zwrotny

        BrakeStatus: byte; //flaga stamnu
      public
        constructor Create(i_mbp, i_bcr, i_bcd, i_brc: real;
                           i_bcn, i_BD, i_mat, i_ba, i_nbpa: byte);
                    //maksymalne cisnienie, promien, skok roboczy, pojemnosc ZP;
                    //ilosc cylindrow, opoznienia hamulca, material klockow, osie hamowane, klocki na os;

        function GetFC(Vel, N: real): real; virtual;        //wspolczynnik tarcia - hamulec wie lepiej
        function GetPF(PP, dt, Vel: real): real; virtual;     //przeplyw miedzy komora wstepna i PG
        function GetBCF: real;                           //sila tlokowa z tloka
        function GetHPFlow(HP, dt: real): real; virtual; //przeplyw - 8 bar
        function GetBCP: real; virtual; //cisnienie cylindrow hamulcowych
        function GetBRP: real; //cisnienie zbiornika pomocniczego
        function GetVRP: real; //cisnienie komory wstepnej rozdzielacza
        function GetCRP: real; virtual; //cisnienie zbiornika sterujacego
        procedure Init(PP, HPP, LPP, BP: real; BDF: byte); virtual; //inicjalizacja hamulca
        function SetBDF(nBDF: byte): boolean; //nastawiacz GPRM
        procedure Releaser(state: byte); //odluzniacz
        procedure ASB(state: byte); //hamulec przeciwposlizgowy
        function GetStatus(): byte; //flaga statusu, moze sie przydac do odglosow
//        procedure
    end;

    TWest= class(TBrake)
      private
        LBP: real;       //cisnienie hamulca pomocniczego
        dVP: real;
      public
        procedure SetLBP(P: real);   //cisnienie z hamulca pomocniczego
        function GetPF(PP, dt, Vel: real): real; override;     //przeplyw miedzy komora wstepna i PG
        procedure Init(PP, HPP, LPP, BP: real; BDF: byte); override;
        function GetHPFlow(HP, dt: real): real; override;        
//        function LocBrakeFlow(LBP, dvLV: real): boolean;
      end;

    TESt= class(TBrake)
      private
        CntrlRes: TReservoir;      //zbiornik steruj�cy
        BVM: real;                 //przelozenie PG-CH
      public
        function GetPF(PP, dt, Vel: real): real; override;     //przeplyw miedzy komora wstepna i PG
        procedure EStParams(i_crc: real);                 //parametry charakterystyczne dla ESt
        procedure Init(PP, HPP, LPP, BP: real; BDF: byte); override;
        function GetCRP: real; override;
        procedure CheckState(BCP: real; var dV1: real); //glowny przyrzad rozrzadczy
        procedure CheckReleaser(dt: real); //odluzniacz
        function CVs(bp: real): real;      //napelniacz sterujacego
        function BVs(BCP: real): real;     //napelniacz pomocniczego
      end;

    TESt3= class(TESt)
      private
        CylFlowSpeed: array[0..1] of array [0..1] of real;
      public
        function GetPF(PP, dt, Vel: real): real; override;     //przeplyw miedzy komora wstepna i PG
      end;

    TESt3AL2= class(TESt3)
      private
        TareM, LoadM: real;  //masa proznego i pelnego
        TareBP: real;  //cisnienie dla proznego
        LoadC: real;
      public
        ImplsRes: TReservoir;      //komora impulsowa
        function GetPF(PP, dt, Vel: real): real; override;     //przeplyw miedzy komora wstepna i PG
        procedure PLC(mass: real);  //wspolczynnik cisnienia przystawki wazacej
        procedure SetLP(TM, LM, TBP: real);  //parametry przystawki wazacej
        procedure Init(PP, HPP, LPP, BP: real; BDF: byte); override;
      end;

    TESt4R= class(TESt)
      private
        RapidStatus: boolean;
      public
        ImplsRes: TReservoir;      //komora impulsowa
        function GetPF(PP, dt, Vel: real): real; override;     //przeplyw miedzy komora wstepna i PG
        procedure Init(PP, HPP, LPP, BP: real; BDF: byte); override;
      end;

    TLSt= class(TESt4R)
      private
        CylFlowSpeed: array[0..1] of array [0..1] of real;
        LBP: real;       //cisnienie hamulca pomocniczego
        RM: real;        //przelozenie rapida
        EDFlag: boolean; //luzowanie hamulca z powodu zalaczonego ED
      public
        procedure SetLBP(P: real);   //cisnienie z hamulca pomocniczego
        procedure SetRM(RMR: real);   //ustalenie przelozenia rapida
        function GetPF(PP, dt, Vel: real): real; override;     //przeplyw miedzy komora wstepna i PG
        function GetHPFlow(HP, dt: real): real; override; //przeplyw - 8 bar
        procedure Init(PP, HPP, LPP, BP: real; BDF: byte); override;
        function GetEDBCP: real;    //cisnienie tylko z hamulca zasadniczego, uzywane do hamulca ED w EP09
        procedure SetED(EDstate: boolean); //stan hamulca ED do luzowania
      end;

    TEStEP2= class(TLSt)
      private
        TareM, LoadM: real;  //masa proznego i pelnego
        TareBP: real;  //cisnienie dla proznego
        LoadC: real;
        EPS: real;
      public
        function GetPF(PP, dt, Vel: real): real; override;     //przeplyw miedzy komora wstepna i PG
        procedure Init(PP, HPP, LPP, BP: real; BDF: byte); override;  //inicjalizacja
        procedure PLC(mass: real);  //wspolczynnik cisnienia przystawki wazacej
        procedure SetEPS(nEPS: real);  //stan hamulca EP
        procedure SetLP(TM, LM, TBP: real);  //parametry przystawki wazacej
      end;

    TCV1= class(TBrake)
      private
        CntrlRes: TReservoir;      //zbiornik steruj�cy
        BVM: real;                 //przelozenie PG-CH
      public
        function GetPF(PP, dt, Vel: real): real; override;     //przeplyw miedzy komora wstepna i PG
        procedure Init(PP, HPP, LPP, BP: real; BDF: byte); override;
        function GetCRP: real; override;
        procedure CheckState(BCP: real; var dV1: real);
        function CVs(bp: real): real;
        function BVs(BCP: real): real;
      public
      end;

    TCV1R= class(TCV1)
      private
        ImplsRes: TReservoir;      //komora impulsowa
        RapidStatus: boolean;
      public
//        function GetPF(PP, dt, Vel: real): real; override;     //przeplyw miedzy komora wstepna i PG
//        procedure Init(PP, HPP, LPP, BP: real; BDF: byte); override;
      end;

    TCV1L_TR= class(TCV1)
      private
        ImplsRes: TReservoir;      //komora impulsowa
        LBP: real;     //cisnienie hamulca pomocniczego
      public
        function GetPF(PP, dt, Vel: real): real; override;     //przeplyw miedzy komora wstepna i PG
        procedure Init(PP, HPP, LPP, BP: real; BDF: byte); override;
        procedure SetLBP(P: real);   //cisnienie z hamulca pomocniczego
        function GetHPFlow(HP, dt: real): real; override; //przeplyw - 8 bar
      end;

    TKE= class(TBrake) //Knorr Einheitsbauart � jeden do wszystkiego
      private
        RapidStatus: boolean;
        ImplsRes: TReservoir;      //komora impulsowa
        CntrlRes: TReservoir;      //zbiornik steruj�cy
        Brak2Res: TReservoir;      //zbiornik pomocniczy 2        
        BVM: real;                 //przelozenie PG-CH
        TareM, LoadM: real;        //masa proznego i pelnego
        TareBP: real;              //cisnienie dla proznego
        LoadC: real;               //wspolczynnik zaladowania
        RM: real;                  //przelozenie rapida
        LBP: real;                 //cisnienie hamulca pomocniczego
      public
        procedure SetRM(RMR: real);   //ustalenie przelozenia rapida
        function GetPF(PP, dt, Vel: real): real; override;     //przeplyw miedzy komora wstepna i PG
        procedure Init(PP, HPP, LPP, BP: real; BDF: byte); override;
        function GetHPFlow(HP, dt: real): real; override; //przeplyw - 8 bar        
        function GetCRP: real; override;
        procedure CheckState(BCP: real; var dV1: real);
        procedure CheckReleaser(dt: real); //odluzniacz
        function CVs(bp: real): real;      //napelniacz sterujacego
        function BVs(BCP: real): real;     //napelniacz pomocniczego
        procedure PLC(mass: real);  //wspolczynnik cisnienia przystawki wazacej
        procedure SetLP(TM, LM, TBP: real);  //parametry przystawki wazacej
        procedure SetLBP(P: real);   //cisnienie z hamulca pomocniczego
      end;




  //klasa obejmujaca krany
    THandle= class
      private
//        BCP: integer;
      public
        function GetPF(i_bcp:real; pp, hp, dt, ep: real): real; virtual;
        procedure Init(press: real); virtual;
        function GetCP(): real; virtual;
        procedure SetReductor(nAdj: real); virtual;        
      end;

    TFV4a= class(THandle)
      private
        CP, TP, RP: real;      //zbiornik steruj�cy, czasowy, redukcyjny
      public
        function GetPF(i_bcp:real; pp, hp, dt, ep: real): real; override;
        procedure Init(press: real); override;
      end;

    TFV4aM= class(THandle)
      private
        CP, TP, RP: real;      //zbiornik steruj�cy, czasowy, redukcyjny
        XP: real;              //komora powietrzna w reduktorze � jest potrzebna do odwzorowania fali
        RedAdj: real;          //dostosowanie reduktora cisnienia (krecenie kapturkiem)
      public
        function GetPF(i_bcp:real; pp, hp, dt, ep: real): real; override;
        procedure Init(press: real); override;
        procedure SetReductor(nAdj: real); override;
      end;

    TM394= class(THandle)
      private
        CP: real;      //zbiornik steruj�cy, czasowy, redukcyjny
        RedAdj: real;          //dostosowanie reduktora cisnienia (krecenie kapturkiem)
      public
        function GetPF(i_bcp:real; pp, hp, dt, ep: real): real; override;
        procedure Init(press: real); override;
        procedure SetReductor(nAdj: real); override;
        function GetCP: real; override;
      end;

    TH14K1= class(THandle)
      private
        CP: real;      //zbiornik steruj�cy, czasowy, redukcyjny
        RedAdj: real;          //dostosowanie reduktora cisnienia (krecenie kapturkiem)
      public
        function GetPF(i_bcp:real; pp, hp, dt, ep: real): real; override;
        procedure Init(press: real); override;
        procedure SetReductor(nAdj: real); override;
        function GetCP: real; override;
      end;

    Ttest= class(THandle)
      private
        CP: real;
      public
        function GetPF(i_bcp:real; pp, hp, dt, ep: real): real; override;
        procedure Init(press: real); override;
      end;

    TFD1= class(THandle)
      private
        MaxBP: real;  //najwyzsze cisnienie
        BP: real;     //aktualne cisnienie
      public
        function GetPF(i_bcp:real; pp, hp, dt, ep: real): real; override;
        procedure Init(press: real); override;
        function GetCP(): real; override;
//        procedure Init(press: real; MaxBP: real); overload;
      end;

    TH1405= class(THandle)
      private
        MaxBP: real;  //najwyzsze cisnienie
        BP: real;     //aktualne cisnienie
      public
        function GetPF(i_bcp:real; pp, hp, dt, ep: real): real; override;
        procedure Init(press: real); override;
        function GetCP(): real; override;
//        procedure Init(press: real; MaxBP: real); overload;
      end;


    TFVel6= class(THandle)
      private
        EPS: real;
      public
        function GetPF(i_bcp:real; pp, hp, dt, ep: real): real; override;
        function GetCP(): real; override;
      end;

function PF(P1,P2,S:real):real;

implementation

uses _mover;
//---FUNKCJE OGOLNE---

function PR(p1,p2:real):real;
var ph,pl: real;
begin
  ph:=Max0R(p1,p2)+0.1;
  pl:=p1+p2-ph+0.2;
  PR:=(p2-p1)/(1.13*ph-pl);
end;

function PF_old(P1,P2,S:real):real;
var ph,pl: real;
begin
  PH:=Max0R(P1,P2)+1;
  PL:=P1+P2-PH+2;
  if  PH-PL<0.0001 then PF_old:=0 else
  if (PH-PL)<0.05 then
    PF_old:=20*(PH-PL)*(PH+1)*222*S*(P2-P1)/(1.13*ph-pl)
  else
    PF_old:=(PH+1)*222*S*(P2-P1)/(1.13*ph-pl);
end;

function PF(P1,P2,S:real):real;
var ph,pl,sg,fm: real;
begin
  PH:=Max0R(P1,P2)+1; //wyzsze cisnienie absolutne
  PL:=P1+P2-PH+2;  //nizsze cisnienie absolutne
  sg:=PL/PH; //bezwymiarowy stosunek cisnien
  fm:=PH*197*S*sign(P2-P1); //najwyzszy mozliwy przeplyw, wraz z kierunkiem
  if (SG>0.5) then //jesli ponizej stosunku krytycznego
    if (PH-PL)<0.1 then //niewielka roznica cisnien
      PF:=10*(PH-PL)*fm*2*SQRT((sg)*(1-sg))
    else
      PF:=fm*2*SQRT((sg)*(1-sg))
  else             //powyzej stosunku krytycznego
    PF:=fm;
end;

function PFVa(PH,PL,S,LIM:real):real; //zawor napelniajacy z PH do PL, PL do LIM
var sg,fm: real;
begin
  if LIM>PL then
   begin
    LIM:=LIM+1;   
    PH:=PH+1; //wyzsze cisnienie absolutne
    PL:=PL+1;  //nizsze cisnienie absolutne
    sg:=PL/PH; //bezwymiarowy stosunek cisnien
    fm:=PH*197*S; //najwyzszy mozliwy przeplyw, wraz z kierunkiem
    if (LIM-PL)<0.1 then fm:=fm*10*(LIM-PL); //jesli jestesmy przy nastawieniu, to zawor sie przymyka
    if (SG>0.5) then //jesli ponizej stosunku krytycznego
      if (PH-PL)<0.1 then //niewielka roznica cisnien
        PFVa:=10*(PH-PL)*fm*2*SQRT((sg)*(1-sg))
      else
        PFVa:=fm*2*SQRT((sg)*(1-sg))
    else             //powyzej stosunku krytycznego
      PFVa:=fm;
   end
  else
    PFVa:=0;
end;

function PFVd(PH,PL,S,LIM:real):real; //zawor wypuszczajacy z PH do PL, PH do LIM
var sg,fm: real;
begin
  if LIM<PH then
   begin
    LIM:=LIM+1;
    PH:=PH+1; //wyzsze cisnienie absolutne
    PL:=PL+1;  //nizsze cisnienie absolutne
    sg:=PL/PH; //bezwymiarowy stosunek cisnien
    fm:=PH*197*S; //najwyzszy mozliwy przeplyw, wraz z kierunkiem
    if (PH-LIM)<0.1 then fm:=fm*10*(PH-LIM); //jesli jestesmy przy nastawieniu, to zawor sie przymyka
    if (SG>0.5) then //jesli ponizej stosunku krytycznego
    if (PH-PL)<0.1 then //niewielka roznica cisnien
        PFVd:=10*(PH-PL)*fm*2*SQRT((sg)*(1-sg))
      else
        PFVd:=fm*2*SQRT((sg)*(1-sg))
    else             //powyzej stosunku krytycznego
      PFVd:=fm;
   end
  else
    PFVd:=0;
end;

//---ZBIORNIKI---

function TReservoir.pa:real;
begin
  pa:=0.1*Vol/Cap;
end;

function TReservoir.P:real;
begin
  P:=Vol/Cap;
end;

procedure TReservoir.Flow(dv: real);
begin
  dVol:=dVol+dv;
end;

constructor TReservoir.Create;
begin
  inherited Create;
  Cap:=1;
  Vol:=0;
end;

procedure TReservoir.Act;
begin
  Vol:=Vol+dVol;
  dVol:=0;
end;

procedure TReservoir.CreateCap(Capacity:real);
begin
  Cap:=Capacity;
end;

procedure TReservoir.CreatePress(Press:real);
begin
  Vol:=Cap*Press;
  dVol:=0;
end;

//---SILOWNIK---
function TBrakeCyl.pa:real;
//var VtoC: real;
begin
//  VtoC:=Vol/Cap;
  pa:=P*0.1
end;


(* NOWSZA WERSJA - maksymalne ci�nienie to ok. 4,75 bar, co powoduje
//                 problemy przy rapidzie w lokomotywach, gdyz jest
//                 osiagany wierzcholek paraboli
function TBrakeCyl.P:real;
var VtoC: real;
begin
  VtoC:=Vol/Cap;
  if VtoC<0.06 then P:=VtoC/4
  else if VtoC>0.88 then P:=0.5+(VtoC-0.88)*1.043-0.064*(VtoC-0.88)*(VtoC-0.88)
  else P:=0.15+0.35/0.82*(VtoC-0.06);
end; *)

//(* STARA WERSJA
function TBrakeCyl.P:real;
var VtoC: real; //stosunek cisnienia do objetosci
begin
  VtoC:=Vol/Cap;
//  P:=VtoC;
  if VtoC<0.15 then P:=VtoC//objetosc szkodliwa
  else if VtoC>1.3 then P:=VtoC-1 //caly silownik
  else P:=0.15*(1+(VtoC-0.15)/1.15); //wysuwanie tloka
end;  //*)


//---HAMULEC---
(*
constructor TBrake.Create(i_mbp, i_bcr, i_bcd, i_brc: real; i_bcn, i_BD, i_mat, i_ba, i_nbpa: byte);
begin
  inherited Create;
  MaxBP:=i_mbp;
  BCN:=i_bcn;
  BCA:=i_bcn*i_bcr*i_bcr*pi;
  BA:=i_ba;
  NBpA:=i_nbpa;
  BrakeDelays:=i_BD;

//tworzenie zbiornikow
  BrakeCyl.CreateCap(i_bcd*BCA*1000);
  BrakeRes.CreateCap(i_brc);
  ValveRes.CreateCap(0.2);

//  FM.Free;
//materialy cierne
  case i_mat of
  bp_P10Bg:   FM:=TP10Bg.Create;
  bp_P10Bgu:  FM:=TP10Bgu.Create;
  else //domyslnie
  FM:=TP10.Create;
  end;


end  ; *)

constructor TBrake.Create(i_mbp, i_bcr, i_bcd, i_brc: real; i_bcn, i_BD, i_mat, i_ba, i_nbpa: byte);
begin
  inherited Create;
  MaxBP:=i_mbp;
  BCN:=i_bcn;
  BCA:=i_bcn*i_bcr*i_bcr*pi;
  BA:=i_ba;
  NBpA:=i_nbpa;
  BrakeDelays:=i_BD;
                               //210.88
//  SizeBR:=i_bcn*i_bcr*i_bcr*i_bcd*40.17*MaxBP/(5-MaxBP);  //objetosc ZP w stosunku do cylindra 14" i cisnienia 4.2 atm
  SizeBR:=i_brc*0.0128;
  SizeBC:=i_bcn*i_bcr*i_bcr*i_bcd*210.88*MaxBP/4.2;            //objetosc CH w stosunku do cylindra 14" i cisnienia 4.2 atm

//  BrakeCyl:=TReservoir.Create;
  BrakeCyl:=TBrakeCyl.Create;
  BrakeRes:=TReservoir.Create;
  ValveRes:=TReservoir.Create;

//tworzenie zbiornikow
  BrakeCyl.CreateCap(i_bcd*BCA*1000);
  BrakeRes.CreateCap(i_brc);
  ValveRes.CreateCap(0.25);

//  FM.Free;
//materialy cierne
  i_mat:=i_mat and (255-bp_MHS);
  case i_mat of
  bp_P10Bg:   FM:=TP10Bg.Create;
  bp_P10Bgu:  FM:=TP10Bgu.Create;
  bp_FR513:   FM:=TFR513.Create;
  bp_Cosid:   FM:=TCosid.Create;
  bp_P10yBg:  FM:=TP10yBg.Create;
  bp_P10yBgu: FM:=TP10yBgu.Create;
  bp_D1:      FM:=TDisk1.Create;
  else //domyslnie
  FM:=TP10.Create;
  end;
end;

//inicjalizacja hamulca (stan poczatkowy)
procedure TBrake.Init(PP, HPP, LPP, BP: real; BDF: byte);
begin

end;

//pobranie wspolczynnika tarcia materialu
function TBrake.GetFC(Vel, N: real): real;
begin
  GetFC:=FM.GetFC(N, Vel);
end;

//cisnienie cylindra hamulcowego
function TBrake.GetBCP: real;
begin
  GetBCP:=BrakeCyl.P;
end;

//cisnienie zbiornika pomocniczego
function TBrake.GetBRP: real;
begin
  GetBRP:=BrakeRes.P;
end;

//cisnienie komory wstepnej
function TBrake.GetVRP: real;
begin
  GetVRP:=ValveRes.P;
end;

//cisnienie zbiornika sterujacego
function TBrake.GetCRP: real;
begin
  GetCRP:=0;
end;

//przeplyw z przewodu glowneg
function TBrake.GetPF(PP, dt, Vel: real): real;
begin
  ValveRes.Act;
  BrakeCyl.Act;
  BrakeRes.Act;
  GetPF:=0;
end;

//przeplyw z przewodu zasilajacego
function TBrake.GetHPFlow(HP, dt: real): real;
begin
  GetHPFlow:=0;
end;

function TBrake.GetBCF: real;
begin
  GetBCF:=BCA*100*BrakeCyl.P;
end;

function TBrake.SetBDF(nBDF: byte): boolean;
begin
  if ((nBDF and BrakeDelays)=nBDF)and(nBDF<>BrakeDelayFlag) then
   begin
    BrakeDelayFlag:=nBDF;
    SetBDF:=true;
   end
  else
    SetBDF:=false;
end;

procedure TBrake.Releaser(state: byte);
begin
  BrakeStatus:=(BrakeStatus and 247) or state*b_rls;
end;

procedure TBrake.ASB(state: byte);
begin                           //255-b_asb(32)
  BrakeStatus:=(BrakeStatus and 223) or state*b_asb;
end;

function TBrake.GetStatus(): byte;
begin
  GetStatus:=BrakeStatus;
end;

//---WESTINGHOUSE---

procedure TWest.Init(PP, HPP, LPP, BP: real; BDF: byte);
begin
   ValveRes.CreatePress(PP);
   BrakeCyl.CreatePress(BP);
   BrakeRes.CreatePress(PP/2+HPP/2);
//   BrakeStatus:=3*Byte(BP>0.1);
end;

function TWest.GetPF(PP, dt, Vel: real): real;
var dv, dv1:real;
    VVP, BVP, CVP, BCP: real;
begin

 BVP:=BrakeRes.P;
 VVP:=ValveRes.P;
 CVP:=BrakeCyl.P;
 BCP:=BrakeCyl.P;

 if (BrakeStatus and 1)=1 then
   if(VVP+0.03<BVP)then
     BrakeStatus:=(BrakeStatus or 2)
   else if(VVP>BVP+0.1) then
     BrakeStatus:=(BrakeStatus and 252)
   else if(VVP>BVP) then
     BrakeStatus:=(BrakeStatus and 253)
   else
 else
   if(VVP+0.25<BVP) then
     BrakeStatus:=(BrakeStatus or 3);

  if((BrakeStatus and b_hld)=b_off) and (not DCV) then
   dV:=PF(0,CVP,0.0068*sizeBC)*dt
  else dV:=0;
  BrakeCyl.Flow(-dV);

  if(BCP>LBP+0.01) and (DCV) then
   dV:=PF(0,CVP,0.01*sizeBC)*dt
  else dV:=0;
  BrakeCyl.Flow(-dV);

//przeplyw ZP <-> silowniki
  if((BrakeStatus and b_on)=b_on)then
    if(BVP>LBP)then
     begin
      DCV:=false;
      dV:=PF(BVP,CVP,0.017*sizeBC)*dt;
     end
  else dV:=0;
  BrakeRes.Flow(dV);
  BrakeCyl.Flow(-dV);
  if(DCV)then
   dVP:=PF(LBP,BCP,0.1)*dt
  else dVP:=0;
  BrakeCyl.Flow(-dVP);
//przeplyw ZP <-> rozdzielacz
  if((BrakeStatus and b_hld)=b_off)then
   dV:=PF(BVP,VVP,0.0011*sizeBR)*dt
  else dV:=0;
  BrakeRes.Flow(dV);
  dV1:=dV*0.95;
  ValveRes.Flow(-0.05*dV);
//przeplyw PG <-> rozdzielacz
  dV:=PF(PP,VVP,0.01*sizeBR)*dt;
  ValveRes.Flow(-dV);

  ValveRes.Act;
  BrakeCyl.Act;
  BrakeRes.Act;
  GetPF:=dV-dV1;
end;

function TWest.GetHPFlow(HP, dt: real): real;
begin
  GetHPFlow:=dVP;
end;

procedure TWest.SetLBP(P: real);
begin
  LBP:=P;
  if P>BrakeCyl.P then
//   begin
    DCV:=true;
//   end
//  else
//    LBP:=P;  
end;


//---OERLIKON EST4---
procedure TESt.CheckReleaser(dt: real);
var VVP, BVP, CVP: real;
begin
  VVP:=Min0R(ValveRes.P,BrakeRes.P+0.05);
  CVP:=CntrlRes.P-0.0;

//odluzniacz
 if(BrakeStatus and b_rls=b_rls)then
   if(CVP-VVP<0)then
    BrakeStatus:=BrakeStatus and 247
   else
    begin
     CntrlRes.Flow(+PF(CVP,0,0.1)*dt);
    end;
end;

procedure TESt.CheckState(BCP: real; var dV1: real);
var VVP, BVP, CVP: real;
begin
  BVP:=BrakeRes.P;
  VVP:=Min0R(ValveRes.P,BVP+0.05);
  CVP:=CntrlRes.P-0.0;

//sprawdzanie stanu
 if (BrakeStatus and 1)=1 then
   if(VVP+0.003+BCP/BVM<CVP)then
     BrakeStatus:=(BrakeStatus or 2) //hamowanie stopniowe
   else if(VVP-0.003+BCP/BVM>CVP) then
     BrakeStatus:=(BrakeStatus and 252) //luzowanie
   else if(VVP+BCP/BVM>CVP) then
     BrakeStatus:=(BrakeStatus and 253) //zatrzymanie napelaniania
   else
 else
   if(VVP+0.10<CVP)and(BCP<0.1)then    //poczatek hamowania
    begin
     BrakeStatus:=(BrakeStatus or 3);
     ValveRes.CreatePress(0.8*VVP);
//       dV1:=0.5;
    end
   else if(VVP+BCP/BVM<CVP)and((CVP-VVP)*BVM>0.25) then //zatrzymanie luzowanie
     BrakeStatus:=(BrakeStatus or 1);
end;

function TESt.CVs(bp: real): real;
var VVP, BVP, CVP: real;
begin
  BVP:=BrakeRes.P;
  CVP:=CntrlRes.P;
  VVP:=ValveRes.P;

//przeplyw ZS <-> PG
  if(BVP<CVP-0.05)or(BrakeStatus>0)or(bp>0.25)then
    CVs:=0
  else
    if(VVP>CVP+0.4)then
      if(BVP>CVP+0.2)then
        CVs:=0.23
      else
        CVs:=0.05
    else
      if(BVP>CVP-0.1)then
        CVs:=1
      else
        CVs:=0.3;
end;

function TESt.BVs(BCP: real): real;
var VVP, BVP, CVP: real;
begin
  BVP:=BrakeRes.P;
  CVP:=CntrlRes.P;
  VVP:=ValveRes.P;

//przeplyw ZP <-> rozdzielacz
  if(BVP<CVP-0.05)then
    BVs:=0.6
  else
    if(BCP<0.5) then
      if(VVP>CVP+0.4)then
        BVs:=0.1
      else
//        if(BVP>CVP+0.1)then
//          temp:=0.3
//        else
          BVs:=0.2*(1.5-Byte(BVP>VVP))
    else
      BVs:=0;
end;





function TESt.GetPF(PP, dt, Vel: real): real;
var dv, dv1, temp:real;
    VVP, BVP, BCP, CVP: real;
begin
 BVP:=BrakeRes.P;
 VVP:=Min0R(ValveRes.P,BVP+0.05);
 BCP:=BrakeCyl.P;
 CVP:=CntrlRes.P-0.0;

 dV:=0; dV1:=0;

//sprawdzanie stanu
  CheckState(BCP, dV1);
  CheckReleaser(dt);

  CVP:=CntrlRes.P;
  VVP:=ValveRes.P;
//przeplyw ZS <-> PG
  temp:=CVs(BCP);
  dV:=PF(CVP,VVP,0.0015*temp)*dt;
  CntrlRes.Flow(+dV);
  ValveRes.Flow(-0.04*dV);
  dV1:=dV1-0.96*dV;


//luzowanie
  if(BrakeStatus and b_hld)=b_off then
   dV:=PF(0,BCP,0.0058*sizeBC)*dt
  else dV:=0;
  BrakeCyl.Flow(-dV);

//przeplyw ZP <-> silowniki
  if(BrakeStatus and b_on)=b_on then
   dV:=PF(BVP,BCP,0.016*sizeBC)*dt
  else dV:=0;
  BrakeRes.Flow(dV);
  BrakeCyl.Flow(-dV);

//przeplyw ZP <-> rozdzielacz
  temp:=BVs(BCP);
//  if(BrakeStatus and b_hld)=b_off then
  if(BCP<0.25)or(VVP+0.05>BVP)then
   dV:=PF(BVP,VVP,0.02*sizeBR*temp/1.87)*dt
  else dV:=0;
  BrakeRes.Flow(dV);
  dV1:=dV1+dV*0.96;
  ValveRes.Flow(-0.04*dV);
//przeplyw PG <-> rozdzielacz
  dV:=PF(PP,VVP,0.01)*dt;
  ValveRes.Flow(-dV);

  ValveRes.Act;
  BrakeCyl.Act;
  BrakeRes.Act;
  CntrlRes.Act;
  GetPF:=dV-dV1;
end;

procedure TESt.Init(PP, HPP, LPP, BP: real; BDF: byte);
begin
   ValveRes.CreatePress(PP);
   BrakeCyl.CreatePress(BP);
   BrakeRes.CreatePress(PP);
   CntrlRes:=TReservoir.Create;
   CntrlRes.CreateCap(15);
   CntrlRes.CreatePress(HPP);
   BrakeStatus:=0;

   BVM:=1/(HPP-LPP)*MaxBP;

   BrakeDelayFlag:=BDF;
end;


procedure TESt.EStParams(i_crc: real);
begin

end;


function TESt.GetCRP: real;
begin
  GetCRP:=CntrlRes.P;
end;

//---EP2---

procedure TEStEP2.Init(PP, HPP, LPP, BP: real; BDF: byte);
begin
   inherited;
   ImplsRes.CreateCap(1);
   ImplsRes.CreatePress(BP);

   BrakeRes.CreatePress(PP);

   BrakeDelayFlag:=bdelay_P;
   BrakeDelays:=bdelay_P;
end;


function TEStEP2.GetPF(PP, dt, Vel: real): real;
var dv, dv1, temp:real;
    VVP, BVP, BCP, CVP: real;
begin
  BVP:=BrakeRes.P;
  VVP:=ValveRes.P;
  BCP:=ImplsRes.P;
  CVP:=CntrlRes.P-0.0;

  dV:=0; dV1:=0;

//odluzniacz
  CheckReleaser(dt);

//sprawdzanie stanu
 if (BrakeStatus and 1)=1 then
   if(VVP+0.003+BCP/BVM<CVP)then
     BrakeStatus:=(BrakeStatus or 2) //hamowanie stopniowe
   else if(VVP-0.003+BCP/BVM>CVP) then
     BrakeStatus:=(BrakeStatus and 252) //luzowanie
   else if(VVP+BCP/BVM>CVP) then
     BrakeStatus:=(BrakeStatus and 253) //zatrzymanie napelaniania
   else
 else
   if(VVP+0.10<CVP)and(BCP<0.1) then    //poczatek hamowania
    begin
     BrakeStatus:=(BrakeStatus or 3);
     dV1:=1.25;
    end
   else if(VVP+BCP/BVM<CVP)and(BCP>0.25) then //zatrzymanie luzowanie
     BrakeStatus:=(BrakeStatus or 1);

//przeplyw ZS <-> PG
  if(BVP<CVP-0.2)or(BrakeStatus>0)or(BCP>0.25)then
    temp:=0
  else
    if(VVP>CVP+0.4)then
      temp:=0.1
    else
      temp:=0.5;
      
  dV:=PF(CVP,VVP,0.0015*temp/1.8)*dt;
  CntrlRes.Flow(+dV);
  ValveRes.Flow(-0.04*dV);
  dV1:=dV1-0.96*dV;

//hamulec EP
  temp:=BVP*Byte(EPS>0);
  dV:=PF(temp,LBP,0.0015)*dt*EPS*EPS*Byte(LBP*EPS<MaxBP);
  LBP:=LBP-dV;

//luzowanie KI
  if(BrakeStatus and b_hld)=b_off then
   dV:=PF(0,BCP,0.00037)*dt
  else dV:=0;
  ImplsRes.Flow(-dV);
//przeplyw ZP <-> KI
  if ((BrakeStatus and b_on)=b_on) and (BCP<MaxBP) then
   dV:=PF(BVP,BCP,0.0014)*dt
  else dV:=0;
  BrakeRes.Flow(dV);
  ImplsRes.Flow(-dV);
//przeplyw PG <-> rozdzielacz
  dV:=PF(PP,VVP,0.001*sizeBR)*dt;
  ValveRes.Flow(-dV);

  GetPF:=dV-dV1;

  temp:=Max0R(BCP,LBP);

//luzowanie CH
  if(BrakeCyl.P>temp+0.005)or(Max0R(ImplsRes.P,8*LBP)<0.25) then
   dV:=PF(0,BrakeCyl.P,0.025*sizeBC)*dt
  else dV:=0;
  BrakeCyl.Flow(-dV);
//przeplyw ZP <-> CH
  if(BrakeCyl.P<temp-0.005)and(Max0R(ImplsRes.P,8*LBP)>0.3)and(Max0R(BCP,LBP)<MaxBP*LoadC)then
   dV:=PF(BVP,BrakeCyl.P,0.035*sizeBC)*dt
  else dV:=0;
  BrakeRes.Flow(dV);
  BrakeCyl.Flow(-dV);

  ImplsRes.Act;
  ValveRes.Act;
  BrakeCyl.Act;
  BrakeRes.Act;
  CntrlRes.Act;
end;

procedure TEStEP2.PLC(mass: real);
begin
  LoadC:=1+Byte(Mass<LoadM)*((TareBP+(MaxBP-TareBP)*(mass-TareM)/(LoadM-TareM))/MaxBP-1);
end;

procedure TEStEP2.SetEPS(nEPS: real);
begin
  EPS:=nEPS;
end;

procedure TEStEP2.SetLP(TM, LM, TBP: real);
begin
  TareM:=TM;
  LoadM:=LM;
  TareBP:=TBP;
end;

//---EST3--

function TESt3.GetPF(PP, dt, Vel: real): real;
var dv, dv1, temp:real;
    VVP, BVP, BCP, CVP: real;
begin
 BVP:=BrakeRes.P;
 VVP:=Min0R(ValveRes.P,BVP+0.05);
 BCP:=BrakeCyl.P;
 CVP:=CntrlRes.P-0.0;

 dV:=0; dV1:=0;

//sprawdzanie stanu
  CheckState(BCP, dV1);
  CheckReleaser(dt);  

  CVP:=CntrlRes.P;
  VVP:=ValveRes.P;
//przeplyw ZS <-> PG
  temp:=CVs(BCP);
  dV:=PF(CVP,VVP,0.0015*temp)*dt;
  CntrlRes.Flow(+dV);
  ValveRes.Flow(-0.04*dV);
  dV1:=dV1-0.96*dV;


//luzowanie
  if(BrakeStatus and b_hld)=b_off then
   dV:=PF(0,BCP,0.0042*(1.37-Byte(BrakeDelayFlag=bdelay_G))*sizeBC)*dt
  else dV:=0;
  BrakeCyl.Flow(-dV);
//przeplyw ZP <-> silowniki
  if(BrakeStatus and b_on)=b_on then
   dV:=PF(BVP,BCP,0.017*(1+Byte((BCP<0.58)and(BrakeDelayFlag=bdelay_G)))*(1.13-Byte((BCP>0.6)and(BrakeDelayFlag=bdelay_G)))*sizeBC)*dt
  else dV:=0;
  BrakeRes.Flow(dV);
  BrakeCyl.Flow(-dV);
//przeplyw ZP <-> rozdzielacz
  temp:=BVs(BCP);
  if(BCP<0.25)or(VVP+0.05>BVP)then
   dV:=PF(BVP,VVP,0.02*sizeBR*temp/1.87)*dt
  else dV:=0;
  BrakeRes.Flow(dV);
  dV1:=dV1+dV*0.96;
  ValveRes.Flow(-0.04*dV);
//przeplyw PG <-> rozdzielacz
  dV:=PF(PP,VVP,0.01)*dt;
  ValveRes.Flow(-dV);

  ValveRes.Act;
  BrakeCyl.Act;
  BrakeRes.Act;
  CntrlRes.Act;
  GetPF:=dV-dV1;
end;

//---EST4-RAPID---

function TESt4R.GetPF(PP, dt, Vel: real): real;
var dv, dv1, temp:real;
    VVP, BVP, BCP, CVP: real;
begin
 BVP:=BrakeRes.P;
 VVP:=Min0R(ValveRes.P,BVP+0.05);
 BCP:=ImplsRes.P;
 CVP:=CntrlRes.P-0.0;

 dV:=0; dV1:=0;

//sprawdzanie stanu
  CheckState(BCP, dV1);
  CheckReleaser(dt);

  CVP:=CntrlRes.P;
  VVP:=ValveRes.P;
//przeplyw ZS <-> PG
  temp:=CVs(BCP);
  dV:=PF(CVP,VVP,0.0015*temp/1.8)*dt;
  CntrlRes.Flow(+dV);
  ValveRes.Flow(-0.04*dV);
  dV1:=dV1-0.96*dV;


//luzowanie KI
  if(BrakeStatus and b_hld)=b_off then
   dV:=PF(0,BCP,0.00037*1.14*15/19)*dt
  else dV:=0;
  ImplsRes.Flow(-dV);
//przeplyw ZP <-> KI
  if(BrakeStatus and b_on)=b_on then
   dV:=PF(BVP,BCP,0.0014)*dt
  else dV:=0;
//  BrakeRes.Flow(dV);
  ImplsRes.Flow(-dV);
//przeplyw ZP <-> rozdzielacz
  temp:=BVs(BCP);
  if(BVP<PP+0.01)or(BCP<0.25)then  //or((PP<CVP)and(CVP<PP-0.1)
   dV:=PF(BVP,VVP,0.02*sizeBR*temp/1.87)*dt
  else dV:=0;
  BrakeRes.Flow(dV);
  dV1:=dV1+dV*0.96;
  ValveRes.Flow(-0.04*dV);
//przeplyw PG <-> rozdzielacz
  dV:=PF(PP,VVP,0.01*sizeBR)*dt;
  ValveRes.Flow(-dV);

  GetPF:=dV-dV1;



  RapidStatus:=(BrakeDelayFlag=bdelay_R)and(((Vel>55)and(RapidStatus))or(Vel>70));

  temp:=1.9-0.9*Byte(RapidStatus);

//luzowanie CH
  if(BrakeCyl.P*temp>ImplsRes.P+0.005)or(ImplsRes.P<0.25) then
//   dV:=PF(0,BrakeCyl.P,0.115*sizeBC/2)*dt
   dV:=PFVd(BrakeCyl.P,0,0.015*sizeBC/2,ImplsRes.P/temp)*dt
  else dV:=0;
  BrakeCyl.Flow(-dV);
//przeplyw ZP <-> CH
  if(BrakeCyl.P*temp<ImplsRes.P-0.005)and(ImplsRes.P>0.3) then
   dV:=PFVa(BVP,BrakeCyl.P,0.020*sizeBC,ImplsRes.P/temp)*dt
  else dV:=0;
  BrakeRes.Flow(-dV);
  BrakeCyl.Flow(+dV);

  ImplsRes.Act;
  ValveRes.Act;
  BrakeCyl.Act;
  BrakeRes.Act;
  CntrlRes.Act;
end;

procedure TESt4R.Init(PP, HPP, LPP, BP: real; BDF: byte);
begin
   inherited;
   ImplsRes:=TReservoir.Create;
   ImplsRes.CreateCap(1);
   ImplsRes.CreatePress(BP);

   BrakeDelayFlag:=bdelay_R;
end;


//---EST3/AL2---

function TESt3AL2.GetPF(PP, dt, Vel: real): real;
var dv, dv1, temp:real;
    VVP, BVP, BCP, CVP: real;
begin
 BVP:=BrakeRes.P;
 VVP:=Min0R(ValveRes.P,BVP+0.05);
 BCP:=ImplsRes.P;
 CVP:=CntrlRes.P-0.0;

 dV:=0; dV1:=0;

//sprawdzanie stanu
  CheckState(BCP, dV1);
  CheckReleaser(dt);  

  VVP:=ValveRes.P;
//przeplyw ZS <-> PG
  temp:=CVs(BCP);
  dV:=PF(CVP,VVP,0.0015*temp)*dt;
  CntrlRes.Flow(+dV);
  ValveRes.Flow(-0.04*dV);
  dV1:=dV1-0.96*dV;

//luzowanie KI
  if(BrakeStatus and b_hld)=b_off then
   dV:=PF(0,BCP,0.00017*(1.37-Byte(BrakeDelayFlag=bdelay_G)))*dt
  else dV:=0;
  ImplsRes.Flow(-dV);
//przeplyw ZP <-> KI
  if ((BrakeStatus and b_on)=b_on) and (BCP<MaxBP) then
   dV:=PF(BVP,BCP,0.0008*(1+Byte((BCP<0.58)and(BrakeDelayFlag=bdelay_G)))*(1.13-Byte((BCP>0.6)and(BrakeDelayFlag=bdelay_G))))*dt
  else dV:=0;
  BrakeRes.Flow(dV);
  ImplsRes.Flow(-dV);
//przeplyw ZP <-> rozdzielacz
  temp:=BVs(BCP);
  if(BCP<0.25)or(VVP+0.05>BVP)then
   dV:=PF(BVP,VVP,0.02*sizeBR*temp/1.87)*dt
  else dV:=0;
  BrakeRes.Flow(dV);
  dV1:=dV1+dV*0.96;
  ValveRes.Flow(-0.04*dV);
//przeplyw PG <-> rozdzielacz
  dV:=PF(PP,VVP,0.01)*dt;
  ValveRes.Flow(-dV);
  GetPF:=dV-dV1;

//luzowanie CH
  if(BrakeCyl.P>ImplsRes.P*LoadC+0.005)or(ImplsRes.P<0.15) then
   dV:=PF(0,BrakeCyl.P,0.015*sizeBC)*dt
  else dV:=0;
  BrakeCyl.Flow(-dV);

//przeplyw ZP <-> CH
  if(BrakeCyl.P<ImplsRes.P*LoadC-0.005)and(ImplsRes.P>0.15) then
   dV:=PF(BVP,BrakeCyl.P,0.020*sizeBC)*dt
  else dV:=0;
  BrakeRes.Flow(dV);
  BrakeCyl.Flow(-dV);

  ImplsRes.Act;
  ValveRes.Act;
  BrakeCyl.Act;
  BrakeRes.Act;
  CntrlRes.Act;
end;

procedure TESt3AL2.PLC(mass: real);
begin
  LoadC:=1+Byte(Mass<LoadM)*((TareBP+(MaxBP-TareBP)*(mass-TareM)/(LoadM-TareM))/MaxBP-1);
end;

procedure TESt3AL2.SetLP(TM, LM, TBP: real);
begin
  TareM:=TM;
  LoadM:=LM;
  TareBP:=TBP;
end;

procedure TESt3AL2.Init(PP, HPP, LPP, BP: real; BDF: byte);
begin
   inherited;
   ImplsRes:=TReservoir.Create;
   ImplsRes.CreateCap(1);
   ImplsRes.CreatePress(BP);
end;


//---LSt---

function TLSt.GetPF(PP, dt, Vel: real): real;
var dv, dv1, temp:real;
    VVP, BVP, BCP, CVP: real;
begin

// ValveRes.CreatePress(LBP);
// LBP:=0;

 BVP:=BrakeRes.P;
 VVP:=ValveRes.P;
 BCP:=ImplsRes.P;
 CVP:=CntrlRes.P;

 dV:=0; dV1:=0;

//sprawdzanie stanu
 if(BrakeStatus and b_rls=b_rls)then
   if(CVP<1)then
     BrakeStatus:=BrakeStatus and 247
   else
    begin
     dV:=PF(CVP,BCP,0.008)*dt;
     CntrlRes.Flow(+dV);
//     dV1:=+dV; //minus potem jest
//     ImplsRes.Flow(-dV1);
    end;

  VVP:=ValveRes.P;
//przeplyw ZS <-> PG
  if((CVP-BCP)*BVM>0.5)then
    temp:=0
  else
    if(VVP>CVP+0.4)then
        temp:=0.5
    else
        temp:=0.5;
  dV:=PF(CVP,VVP,0.0015*temp/1.8)*dt;
  CntrlRes.Flow(+dV);
  ValveRes.Flow(-0.04*dV);
  dV1:=dV1-0.96*dV;


//luzowanie KI  {G}
//   if VVP>BCP then
//    dV:=PF(VVP,BCP,0.00004)*dt
//   else if (CVP-BCP)<1.5 then
//    dV:=PF(VVP,BCP,0.00020*(1.33-Byte((CVP-BCP)*BVM>0.65)))*dt
//  else dV:=0;      0.00025 P
                {P}
   if VVP>BCP then
    dV:=PF(VVP,BCP,0.00043*(1.5-Byte(((CVP-BCP)*BVM>1)and(BrakeDelayFlag=bdelay_G))))*dt
   else if (CVP-BCP)<1.5 then
    dV:=PF(VVP,BCP,0.001472*(1.36-Byte(((CVP-BCP)*BVM>1)and(BrakeDelayFlag=bdelay_G))))*dt
  else dV:=0;

  ImplsRes.Flow(-dV);
  ValveRes.Flow(+dV);
//przeplyw PG <-> rozdzielacz
  dV:=PF(PP,VVP,0.01)*dt;
  ValveRes.Flow(-dV);

  GetPF:=dV-dV1;

//  if Vel>55 then temp:=0.72 else
//    temp:=1;{R}
//cisnienie PP
  temp:=1-RM*Byte((Vel>55)and(BrakeDelayFlag=bdelay_R));
  if EDFlag then temp:=10000;

//powtarzacz � podwojny zawor zwrotny
  temp:=Max0R(((CVP-BCP)*BVM+1.6*Byte((BrakeStatus and b_asb)=b_asb))/temp,LBP);
//luzowanie CH
  if(BrakeCyl.P>temp+0.005)or(temp<0.28) then
//   dV:=PF(0,BrakeCyl.P,0.0015*3*sizeBC)*dt
   dV:=PF(0,BrakeCyl.P,0.005*3*sizeBC)*dt
  else dV:=0;
  BrakeCyl.Flow(-dV);
//przeplyw ZP <-> CH
  if(BrakeCyl.P<temp-0.005)and(temp>0.29) then
   dV:=PF(BVP,BrakeCyl.P,0.002*3*sizeBC*2)*dt
  else dV:=0;
  BrakeRes.Flow(dV);
  BrakeCyl.Flow(-dV);

  ImplsRes.Act;
  ValveRes.Act;
  BrakeCyl.Act;
  BrakeRes.Act;                                      
  CntrlRes.Act;
//  LBP:=ValveRes.P;
//  ValveRes.CreatePress(ImplsRes.P);
end;

procedure TLSt.Init(PP, HPP, LPP, BP: real; BDF: byte);
begin
  inherited;
  ValveRes.CreateCap(1);
  ImplsRes.CreateCap(8);
  ImplsRes.CreatePress(PP);
  BrakeRes.CreatePress(8);
  ValveRes.CreatePress(PP);

  EDFlag:=False;

  BrakeDelayFlag:=BDF;
end;

procedure TLSt.SetLBP(P: real);
begin
  LBP:=P;
end;

function TLSt.GetEDBCP: real;
var CVP, BCP: real;
begin
  CVP:=CntrlRes.P;
  BCP:=ImplsRes.P;
  GetEDBCP:=(CVP-BCP)*BVM;
end;

procedure TLSt.SetED(EDstate: boolean);
begin
  EDFlag:=EDstate
end;

procedure TLSt.SetRM(RMR: real);
begin
  RM:=1-RMR;
end;

function TLSt.GetHPFlow(HP, dt: real): real;
var dV: real;
begin
  dV:=Min0R(PF(HP,BrakeRes.P,0.01*dt),0);
  BrakeRes.Flow(-dV);
  GetHPFlow:=dV;
end;


//---DAKO CV1---

procedure TCV1.CheckState(BCP: real; var dV1: real);
var VVP, BVP, CVP: real;
begin
  BVP:=BrakeRes.P;
  VVP:=Min0R(ValveRes.P,BVP+0.05);
  CVP:=CntrlRes.P-0.0;

//odluzniacz
 if(BrakeStatus and b_rls=b_rls)and(CVP-VVP<0)then
  BrakeStatus:=BrakeStatus and 247;

//sprawdzanie stanu
 if (BrakeStatus and 1)=1 then
   if(VVP+0.003+BCP/BVM<CVP)then
     BrakeStatus:=(BrakeStatus or 2) //hamowanie stopniowe
   else if(VVP-0.003+BCP/BVM>CVP) then
     BrakeStatus:=(BrakeStatus and 252) //luzowanie
   else if(VVP+BCP/BVM>CVP) then
     BrakeStatus:=(BrakeStatus and 253) //zatrzymanie napelaniania
   else
 else
   if(VVP+0.10<CVP)and(BCP<0.1) then    //poczatek hamowania
    begin
     BrakeStatus:=(BrakeStatus or 3);
     dV1:=1.25;
    end
   else if(VVP+BCP/BVM<CVP)and(BCP>0.25) then //zatrzymanie luzowanie
     BrakeStatus:=(BrakeStatus or 1);
end;

function TCV1.CVs(bp: real): real;
begin
//przeplyw ZS <-> PG
  if(bp>0.05)then
    CVs:=0
  else
    CVs:=0.23
end;

function TCV1.BVs(BCP: real): real;
var VVP, BVP, CVP: real;
begin
  BVP:=BrakeRes.P;
  CVP:=CntrlRes.P;
  VVP:=ValveRes.P;

//przeplyw ZP <-> rozdzielacz
  if(BVP<CVP-0.1)then
    BVs:=1
  else
    if(BCP>0.05)then
      BVs:=0
    else
      BVs:=0.2*(1.5-Byte(BVP>VVP));
end;

function TCV1.GetPF(PP, dt, Vel: real): real;
var dv, dv1, temp:real;
    VVP, BVP, BCP, CVP: real;
begin
 BVP:=BrakeRes.P;
 VVP:=Min0R(ValveRes.P,BVP+0.05);
 BCP:=BrakeCyl.P;
 CVP:=CntrlRes.P-0.0;

 dV:=0; dV1:=0;

//sprawdzanie stanu
  CheckState(BCP, dV1);

  VVP:=ValveRes.P;
//przeplyw ZS <-> PG
  temp:=CVs(BCP);
  dV:=PF(CVP,VVP,0.0015*temp)*dt;
  CntrlRes.Flow(+dV);
  ValveRes.Flow(-0.04*dV);
  dV1:=dV1-0.96*dV;


//luzowanie
  if(BrakeStatus and b_hld)=b_off then
   dV:=PF(0,BCP,0.0042*(1.37-Byte(BrakeDelayFlag=bdelay_G))*sizeBC)*dt
  else dV:=0;
  BrakeCyl.Flow(-dV);

//przeplyw ZP <-> silowniki
  if(BrakeStatus and b_on)=b_on then
   dV:=PF(BVP,BCP,0.017*(1+Byte((BCP<0.58)and(BrakeDelayFlag=bdelay_G)))*(1.13-Byte((BCP>0.6)and(BrakeDelayFlag=bdelay_G)))*sizeBC)*dt
  else dV:=0;
  BrakeRes.Flow(dV);
  BrakeCyl.Flow(-dV);

//przeplyw ZP <-> rozdzielacz
  temp:=BVs(BCP);
  if(VVP+0.05>BVP)then
   dV:=PF(BVP,VVP,0.02*sizeBR*temp/1.87)*dt
  else dV:=0;
  BrakeRes.Flow(dV);
  dV1:=dV1+dV*0.96;
  ValveRes.Flow(-0.04*dV);
//przeplyw PG <-> rozdzielacz
  dV:=PF(PP,VVP,0.01)*dt;
  ValveRes.Flow(-dV);

  ValveRes.Act;
  BrakeCyl.Act;
  BrakeRes.Act;
  CntrlRes.Act;
  GetPF:=dV-dV1;
end;

procedure TCV1.Init(PP, HPP, LPP, BP: real; BDF: byte);
begin
   ValveRes.CreatePress(PP);
   BrakeCyl.CreatePress(BP);
   BrakeRes.CreatePress(PP);
   CntrlRes:=TReservoir.Create;
   CntrlRes.CreateCap(15);
   CntrlRes.CreatePress(HPP);
   BrakeStatus:=0;

   BVM:=1/(HPP-LPP)*MaxBP;

   BrakeDelayFlag:=BDF;
end;

function TCV1.GetCRP: real;
begin
  GetCRP:=CntrlRes.P;
end;


//---CV1-L-TR---

procedure TCV1L_TR.SetLBP(P: real);
begin
  LBP:=P;
end;

function TCV1L_TR.GetHPFlow(HP, dt: real): real;
var dV: real;
begin
  dV:=PF(HP,BrakeRes.P,0.01)*dt;
  dV:=Min0R(0,dV);
  BrakeRes.Flow(-dV);
  GetHPFlow:=dV;
end;

procedure TCV1L_TR.Init(PP, HPP, LPP, BP: real; BDF: byte);
begin
   inherited;
   ImplsRes:=TReservoir.Create;
   ImplsRes.CreateCap(2.5);
   ImplsRes.CreatePress(BP);
end;

function TCV1L_TR.GetPF(PP, dt, Vel: real): real;
var dv, dv1, temp:real;
    VVP, BVP, BCP, CVP: real;
begin
 BVP:=BrakeRes.P;
 VVP:=Min0R(ValveRes.P,BVP+0.05);
 BCP:=ImplsRes.P;
 CVP:=CntrlRes.P-0.0;

 dV:=0; dV1:=0;

//sprawdzanie stanu
  CheckState(BCP, dV1);

  VVP:=ValveRes.P;
//przeplyw ZS <-> PG
  temp:=CVs(BCP);
  dV:=PF(CVP,VVP,0.0015*temp)*dt;
  CntrlRes.Flow(+dV);
  ValveRes.Flow(-0.04*dV);
  dV1:=dV1-0.96*dV;


//luzowanie KI
  if(BrakeStatus and b_hld)=b_off then
   dV:=PF(0,BCP,0.000425*(1.37-Byte(BrakeDelayFlag=bdelay_G)))*dt
  else dV:=0;
  ImplsRes.Flow(-dV);
//przeplyw ZP <-> KI
  if ((BrakeStatus and b_on)=b_on) and (BCP<MaxBP) then
   dV:=PF(BVP,BCP,0.002*(1+Byte((BCP<0.58)and(BrakeDelayFlag=bdelay_G)))*(1.13-Byte((BCP>0.6)and(BrakeDelayFlag=bdelay_G))))*dt
  else dV:=0;
  BrakeRes.Flow(dV);
  ImplsRes.Flow(-dV);

//przeplyw ZP <-> rozdzielacz
  temp:=BVs(BCP);
  if(VVP+0.05>BVP)then
   dV:=PF(BVP,VVP,0.02*sizeBR*temp/1.87)*dt
  else dV:=0;
  BrakeRes.Flow(dV);
  dV1:=dV1+dV*0.96;
  ValveRes.Flow(-0.04*dV);
//przeplyw PG <-> rozdzielacz
  dV:=PF(PP,VVP,0.01)*dt;
  GetPF:=dV-dV1;

  temp:=Max0R(BCP,LBP);

//luzowanie CH
  if(BrakeCyl.P>temp+0.005)or(Max0R(ImplsRes.P,8*LBP)<0.25) then
   dV:=PF(0,BrakeCyl.P,0.015*sizeBC)*dt
  else dV:=0;
  BrakeCyl.Flow(-dV);

//przeplyw ZP <-> CH
  if(BrakeCyl.P<temp-0.005)and(Max0R(ImplsRes.P,8*LBP)>0.3)and(Max0R(BCP,LBP)<MaxBP)then
   dV:=PF(BVP,BrakeCyl.P,0.020*sizeBC)*dt
  else dV:=0;
  BrakeRes.Flow(dV);
  BrakeCyl.Flow(-dV);

  ImplsRes.Act;
  ValveRes.Act;
  BrakeCyl.Act;
  BrakeRes.Act;
  CntrlRes.Act;
end;



//--- KNORR KE ---
procedure TKE.CheckReleaser(dt: real);
var VVP, CVP: real;
begin
  VVP:=ValveRes.P;
  CVP:=CntrlRes.P;

//odluzniacz
 if(BrakeStatus and b_rls=b_rls)then
   if(CVP-VVP<0)then
    BrakeStatus:=BrakeStatus and 247
   else
    begin
     CntrlRes.Flow(+PF(CVP,0,0.1)*dt);
    end;
end;

procedure TKE.CheckState(BCP: real; var dV1: real);
var VVP, BVP, CVP: real;
begin
  BVP:=BrakeRes.P;
  VVP:=ValveRes.P;
  CVP:=CntrlRes.P;

//sprawdzanie stanu
 if (BrakeStatus and 1)=1 then
   if(VVP+0.003+BCP/BVM<CVP)then
     BrakeStatus:=(BrakeStatus or 2) //hamowanie stopniowe
   else if(VVP-0.003+BCP/BVM>CVP) then
     BrakeStatus:=(BrakeStatus and 252) //luzowanie
   else if(VVP+BCP/BVM>CVP) then
     BrakeStatus:=(BrakeStatus and 253) //zatrzymanie napelaniania
   else
 else
   if(VVP+0.10<CVP)and(BCP<0.1)then    //poczatek hamowania
    begin
     BrakeStatus:=(BrakeStatus or 3);
     ValveRes.CreatePress(0.8*VVP); //przyspieszacz
    end
   else if(VVP+BCP/BVM<CVP)and((CVP-VVP)*BVM>0.25) then //zatrzymanie luzowanie
     BrakeStatus:=(BrakeStatus or 1);
end;

function TKE.CVs(bp: real): real;
var VVP, BVP, CVP: real;
begin
  BVP:=BrakeRes.P;
  CVP:=CntrlRes.P;
  VVP:=ValveRes.P;

//przeplyw ZS <-> PG
  if(bp>0.2)then
    CVs:=0
  else
    if(VVP>CVP+0.4)then
        CVs:=0.05
      else
        CVs:=0.23
end;

function TKE.BVs(BCP: real): real;
var VVP, BVP, CVP: real;
begin
  BVP:=BrakeRes.P;
  CVP:=CntrlRes.P;
  VVP:=ValveRes.P;

//przeplyw ZP <-> rozdzielacz
  if (BVP>VVP) then
    BVs:=0
  else
  if(BVP<CVP-0.3)then
    BVs:=0.6
  else
    BVs:=0.13
end;

function TKE.GetPF(PP, dt, Vel: real): real;
var dv, dv1, temp:real;
    VVP, BVP, BCP, IMP, CVP: real;
begin
 BVP:=BrakeRes.P;
 VVP:=ValveRes.P;
 BCP:=BrakeCyl.P;
 IMP:=ImplsRes.P;
 CVP:=CntrlRes.P;

 dV:=0; dV1:=0;

//sprawdzanie stanu
  CheckState(IMP, dV1);
  CheckReleaser(dt);

//przeplyw ZS <-> PG
  temp:=CVs(IMP);
  dV:=PF(CVP,VVP,0.0015*temp)*dt;
  CntrlRes.Flow(+dV);
  ValveRes.Flow(-0.04*dV);
  dV1:=dV1-0.96*dV;

//luzowanie
  if(BrakeStatus and b_hld)=b_off then
   begin
    if ((BrakeDelayFlag and bdelay_G)=0) then
      temp:=0.283+0.139
    else
      temp:=0.139;
    dV:=PF(0,IMP,0.001*temp)*dt
   end
  else dV:=0;
  ImplsRes.Flow(-dV);

//przeplyw ZP <-> silowniki
  if((BrakeStatus and b_on)=b_on)and(IMP<MaxBP)then
   begin
    temp:=0.113;
    if ((BrakeDelayFlag and bdelay_G)=0) then
      temp:=temp+0.636;
    if (BCP<0.5) then
      temp:=temp+0.785;
    dV:=PF(BVP,IMP,0.001*temp)*dt
   end
  else dV:=0;
  BrakeRes.Flow(dV);
  ImplsRes.Flow(-dV);


//rapid
  if not (FM is TDisk1) then   //jesli zeliwo to schodz
    RapidStatus:=((BrakeDelayFlag and bdelay_R)=bdelay_R)and(((Vel>50)and(RapidStatus))or(Vel>70))
  else                         //jesli tarczowki, to zostan
    RapidStatus:=((BrakeDelayFlag and bdelay_R)=bdelay_R);

//  temp:=1.9-0.9*Byte(RapidStatus);

  if(RM*RM>0.1)then //jesli jest rapid
    if(RM>0)then //jesli dodatni (naddatek);
      temp:=1-RM*Byte(RapidStatus)
    else
      temp:=1-RM*(1-Byte(RapidStatus))
  else
    temp:=1;
  temp:=temp/LoadC;
//luzowanie CH
//  temp:=Max0R(BCP,LBP);
  IMP:=Max0R(IMP/temp,LBP);

//luzowanie CH
  if(BCP>IMP+0.005)or(Max0R(ImplsRes.P,8*LBP)<0.25) then
   dV:=PFVd(BCP,0,0.05,IMP)*dt
  else dV:=0;
  BrakeCyl.Flow(-dV);
  if(BCP<IMP-0.005)and(Max0R(ImplsRes.P,8*LBP)>0.3) then
   dV:=PFVa(BVP,BCP,0.02,IMP)*dt
  else dV:=0;
  BrakeRes.Flow(-dV);
  BrakeCyl.Flow(+dV);

//przeplyw ZP <-> rozdzielacz
  temp:=BVs(IMP);
//  if(BrakeStatus and b_hld)=b_off then
  if(IMP<0.25)or(VVP+0.05>BVP)then
   dV:=PF(BVP,VVP,0.02*sizeBR*temp/1.87)*dt
  else dV:=0;
  BrakeRes.Flow(dV);
  dV1:=dV1+dV*0.96;
  ValveRes.Flow(-0.04*dV);
//przeplyw PG <-> rozdzielacz
  dV:=PF(PP,VVP,0.01)*dt;
  ValveRes.Flow(-dV);

  ValveRes.Act;
  BrakeCyl.Act;
  BrakeRes.Act;
  CntrlRes.Act;
  ImplsRes.Act;
  GetPF:=dV-dV1;
end;

procedure TKE.Init(PP, HPP, LPP, BP: real; BDF: byte);
begin
   ValveRes.CreatePress(PP);
   BrakeCyl.CreatePress(BP);
   BrakeRes.CreatePress(PP);

   CntrlRes:=TReservoir.Create; //komora sterujaca
   CntrlRes.CreateCap(5);
   CntrlRes.CreatePress(HPP);

   ImplsRes:=TReservoir.Create; //komora zastepcza silownika
   ImplsRes.CreateCap(1);
   ImplsRes.CreatePress(BP);

   BrakeStatus:=0;

   BVM:=1/(HPP-LPP)*MaxBP;

   BrakeDelayFlag:=BDF;
end;

function TKE.GetCRP: real;
begin
  GetCRP:=CntrlRes.P;
end;

function TKE.GetHPFlow(HP, dt: real): real;
var dV: real;
begin
  dV:=PF(HP,BrakeRes.P,0.01)*dt;
  dV:=Min0R(0,dV);
  BrakeRes.Flow(-dV);
  GetHPFlow:=dV;
end;

procedure TKE.PLC(mass: real);
begin
  LoadC:=1+Byte(Mass<LoadM)*((TareBP+(MaxBP-TareBP)*(mass-TareM)/(LoadM-TareM))/MaxBP-1);
end;

procedure TKE.SetLP(TM, LM, TBP: real);
begin
  TareM:=TM;
  LoadM:=LM;
  TareBP:=TBP;
end;

procedure TKE.SetRM(RMR: real);
begin
  RM:=1-RMR;
end;

procedure TKE.SetLBP(P: real);
begin
  LBP:=P;
end;


//---KRANY---

function THandle.GetPF(i_bcp:real; pp, hp, dt, ep: real): real;
begin
  GetPF:=0;
end;

procedure THandle.Init(press: real);
begin
end;

procedure THandle.SetReductor(nAdj: real);
begin

end;

function THandle.GetCP: real;
begin
  GetCP:=0;
end;


//---FV4a---

function TFV4a.GetPF(i_bcp:real; pp, hp, dt, ep: real): real;
const
  LBDelay = 100;
var
  LimPP, dpPipe, dpMainValve, ActFlowSpeed: real;
begin
          ep:=pp; //SPKS!!
          Limpp:=Min0R(BPT[Round(i_bcp)][1],HP);
          ActFlowSpeed:=BPT[Round(i_bcp)][0];

          if(i_bcp=i_bcpNo)then limpp:=2.9;

          cp:=cp+20*Min0R(abs(Limpp-cp),0.05)*PR(cp,Limpp)*dt/1;
          rp:=rp+20*Min0R(abs(ep-rp),0.05)*PR(rp,ep)*dt/2.5;


          Limpp:=cp;
          dpPipe:=Min0R(HP,Limpp);

          dpMainValve:=PF(dpPipe,pp,ActFlowSpeed/(LBDelay))*dt;
          if(cp>rp+0.05)then
            dpMainValve:=PF(Min0R(cp+0.1,HP),pp,1.1*(ActFlowSpeed)/(LBDelay))*dt;
          if(cp<rp-0.05)then
            dpMainValve:=PF(cp-0.1,pp,1.1*(ActFlowSpeed)/(LBDelay))*dt;

          if Round(i_bcp)=-1 then
           begin
            cp:=cp+5*Min0R(abs(Limpp-cp),0.2)*PR(cp,Limpp)*dt/2;
            if(cp<rp+0.03)then
              if(tp<5)then tp:=tp+dt;
//            if(cp+0.03<5.4)then
            if(rp+0.03<5.4)or(cp+0.03<5.4)then //fala
              dpMainValve:=PF(Min0R(HP,17.1),pp,(ActFlowSpeed)/(LBDelay))*dt
//              dpMainValve:=20*Min0R(abs(ep-7.1),0.05)*PF(HP,pp,(ActFlowSpeed)/(LBDelay))*dt
            else
             begin
             rp:=5.45;
              if (cp<pp-0.01) then                  //: /34*9
                dpMainValve:=PF(dpPipe,pp,(ActFlowSpeed)/34*9/(LBDelay))*dt
              else
                dpMainValve:=PF(dpPipe,pp,(ActFlowSpeed)/(LBDelay))*dt
             end;
           end;

          if(Round(i_bcp)=0)then
           begin
            if(tp>0.1)then
            begin
              cp:=5+(tp-0.1)*0.08;
              tp:=tp-dt/12;
            end;
            if(cp>rp+0.1)and(cp<=5)then
              dpMainValve:=PF(Min0R(cp+0.25,HP),pp,2*(ActFlowSpeed)/(LBDelay))*dt
            else
            if cp>5 then
              dpMainValve:=PF(Min0R(cp,HP),pp,2*(ActFlowSpeed)/(LBDelay))*dt
            else
              dpMainValve:=PF(dpPipe,pp,(ActFlowSpeed)/(LBDelay))*dt
           end;

          if(Round(i_bcp)=i_bcpNo)then
           begin
            dpMainValve:=PF(0,pp,(ActFlowSpeed)/(LBDelay))*dt;
           end;

  GetPF:=dpMainValve;
end;

procedure TFV4a.Init(press: real);
begin
  CP:= press;
  TP:= 0;
  RP:= press;
end;


//---FV4a/M--- nowonapisany kran + poprawki IC

function TFV4aM.GetPF(i_bcp:real; pp, hp, dt, ep: real): real;
function LPP_RP(pos: real): real; //cisnienie z zaokraglonej pozycji;
var i_pos: integer;
begin
  i_pos:=Round(pos-0.5); //zaokraglone w dol
  LPP_RP:=BPT[i_pos][1]+(BPT[i_pos+1][1]-BPT[i_pos][1])*(pos-i_pos); //interpolacja liniowa
end;
const
  LBDelay = 100;
  xpM = 0.3; //mnoznik membrany komory pod
var
  LimPP, dpPipe, dpMainValve, ActFlowSpeed: real;
begin
          ep:=pp/2+ep/2; //SPKS!!

          i_bcp:=Max0R(Min0R(i_bcp,5.999),-1.999); //na wszelki wypadek, zeby nie wyszlo poza zakres

          if(tp>0)then  //jesli czasowy jest niepusty
            tp:=tp-dt*0.08 //od cisnienia 5 do 0 w 60 sekund ((5-0)*dt/60)
          else
            tp:=0;         //jak pusty, to pusty

          if(xp>0)then  //jesli komora pod niepusta jest niepusty
            xp:=xp-dt*0.75 //od cisnienia 5 do 0 w 10 sekund ((5-0)*dt/10)
          else
            xp:=0;         //jak pusty, to pusty

          if(cp>rp+0.05)then
            if(cp>rp+0.15)then
              xp:=xp-3*PR(cp,xp)*dt
            else
              xp:=xp-3*(cp-(rp+0.05))/(0.1)*PR(cp,xp)*dt;

//          Limpp:=Min0R(BPT[Round(i_bcp)][1]+tp*0.08,HP); //pozycja + czasowy lub zasilanie
          Limpp:=Min0R(LPP_RP(i_bcp)+tp*0.08+RedAdj,HP); //pozycja + czasowy lub zasilanie
          ActFlowSpeed:=BPT[Round(i_bcp)][0];

//          if(i_bcp=i_bcpNo)then limpp:=Min0R(BPT[Round(i_bcp-1)][1]+tp*0.08,HP);
          if(Limpp>cp)then //podwyzszanie szybkie
            cp:=cp+60*Min0R(abs(Limpp-cp),0.05)*PR(cp,Limpp)*dt //zbiornik sterujacy
          else
            cp:=cp+17*Min0R(abs(Limpp-cp),0.05)*PR(cp,Limpp)*dt; //zbiornik sterujacy

          if(rp>ep)then //zaworek zwrotny do opozniajacego
            rp:=rp+PF(rp,ep,0.01)*dt //szybki upust
          else
            rp:=rp+PF(rp,ep,0.0003)*dt; //powolne wzrastanie
          if (rp<ep) and (rp<BPT[Round(i_bcpNo)][1])then //jesli jestesmy ponizej cisnienia w sterujacym (2.9 bar)
            rp:=rp+PF(rp,cp,0.001)*dt; //przypisz cisnienie w PG - wydluzanie napelniania o czas potrzebny do napelnienia PG


          Limpp:=cp;
          dpPipe:=Min0R(HP,Limpp+xp*xpM);

          if(dpPipe>pp)then //napelnianie
           begin
            if(Round(i_bcp)=0)and(tp>2)then //na pozycji jazdy mamy mocniejsze napelnianie z czasowym
              dpMainValve:=PF(dpPipe,pp,ActFlowSpeed*2/(LBDelay))*dt
//                dpMainValve:=-PFVa(Min0R(dpPipe+0.1,HP),pp,ActFlowSpeed/(LBDelay),dpPipe)
            else //normalne napelnianie
              dpMainValve:=PF(dpPipe,pp,ActFlowSpeed/(LBDelay))*dt
           end
          else //spuszczanie
              dpMainValve:=PF(dpPipe,pp,ActFlowSpeed/(LBDelay))*dt;

//          if(cp>rp+0.05)then
//            dpMainValve:=PF(Min0R(cp,HP),pp,(ActFlowSpeed)/(LBDelay))*dt;


          if Round(i_bcp)=-1 then
           begin
//            cp:=cp+5*Min0R(abs(Limpp-cp),0.2)*PR(cp,Limpp)*dt/2;
            if(tp<5)then tp:=tp+1.5*dt;
//            if(cp+0.03<5.4)then
//            if(rp+0.03<5.4)or(cp+0.03<5.4)then //fala
              dpMainValve:=dpMainValve+PF(dpPipe,pp,(ActFlowSpeed)/(LBDelay))*dt//coby nie przeszkadzal przy ladowaniu z zaworu obok
//              dpMainValve:=20*Min0R(abs(ep-7.1),0.05)*PF(HP,pp,(ActFlowSpeed)/(LBDelay))*dt
{            else
             begin
             rp:=5.45;
              if (cp<pp-0.01) then                  //: /34*9
                dpMainValve:=PF(dpPipe,pp,(ActFlowSpeed)/34*9/(LBDelay))*dt
              else
                dpMainValve:=PF(dpPipe,pp,(ActFlowSpeed)/(LBDelay))*dt
             end; }
           end;

          if(Round(i_bcp)=i_bcpNo)then
           begin
            dpMainValve:=PF(0,pp,(ActFlowSpeed)/(LBDelay))*dt;
           end;

  GetPF:=dpMainValve;
end;

procedure TFV4aM.Init(press: real);
begin
  CP:= press;
  TP:= 0;
  RP:= press;
  XP:= 0;
end;

procedure TFV4aM.SetReductor(nAdj: real);
begin
  RedAdj:= nAdj;
end;


//---M394--- Matrosow

function TM394.GetPF(i_bcp:real; pp, hp, dt, ep: real): real;
const
  LBDelay = 65;
var
  LimPP, dpPipe, dpMainValve, ActFlowSpeed: real;
  bcp: integer;
begin
  bcp:=Round(i_bcp);
  if bcp<-1 then bcp:=1;

  Limpp:=Min0R(BPT_394[bcp][1],HP);
  ActFlowSpeed:=BPT_394[bcp][0];
  if (bcp=1) then
    Limpp:=pp;
  if (bcp=0) then
    Limpp:=Limpp+RedAdj;
  if (bcp<>2) then
    if cp<Limpp then
      cp:=cp+6*(2+Byte(bcp<0))*Min0R(abs(Limpp-cp),0.05)*PR(cp,Limpp)*dt //zbiornik sterujacy
    else
      cp:=cp+4*(1+Byte(bcp<>3)+Byte(bcp>4))*Min0R(abs(Limpp-cp),0.05)*PR(cp,Limpp)*dt; //zbiornik sterujacy

  Limpp:=cp;
  dpPipe:=Min0R(HP,Limpp);

//  if(dpPipe>pp)then //napelnianie
//    dpMainValve:=PF(dpPipe,pp,ActFlowSpeed/(LBDelay))*dt
//  else //spuszczanie
    dpMainValve:=PF(dpPipe,pp,ActFlowSpeed/(LBDelay))*dt;

          if bcp=-1 then
//           begin
              dpMainValve:=PF(HP,pp,(ActFlowSpeed)/(LBDelay))*dt;
//           end;

          if bcp=i_bcpNo then
//           begin
            dpMainValve:=PF(0,pp,(ActFlowSpeed)/(LBDelay))*dt;
//           end;

  GetPF:=dpMainValve;
end;

procedure TM394.Init(press: real);
begin
  CP:= press;
  RedAdj:= 0;
end;

procedure TM394.SetReductor(nAdj: real);
begin
  RedAdj:= nAdj;
end;

function TM394.GetCP: real;
begin
  GetCP:= CP;
end;

//---H14K1-- Knorr

function TH14K1.GetPF(i_bcp:real; pp, hp, dt, ep: real): real;
const
  LBDelay = 100;                                    //szybkosc + zasilanie sterujacego
  BPT_K: array[-1..4] of array [0..1] of real= ((10, 0), (4, 1), (0, 1), (4, 0), (4, -1), (15, -1));
  NomPress = 5.0;
var
  LimPP, dpPipe, dpMainValve, ActFlowSpeed: real;
  bcp: integer;
begin
  bcp:=Round(i_bcp);
  if bcp<-1 then bcp:=1;
  Limpp:=BPT_K[bcp][1];
  if Limpp<0 then
    Limpp:=0.5*pp
  else if Limpp>0 then
    Limpp:=pp
  else
    Limpp:=cp;
  ActFlowSpeed:=BPT_K[bcp][0];

//  if cp<Limpp then
//    cp:=cp+6*Min0R(abs(Limpp-cp),0.05)*PR(cp,Limpp)*dt //zbiornik sterujacy
//  else
    cp:=cp+6*Min0R(abs(Limpp-cp),0.05)*PR(cp,Limpp)*dt; //zbiornik sterujacy

//  Limpp:=cp;
//  dpPipe:=Min0R(HP,Limpp);


//  if(dpPipe>pp)then //napelnianie
//    if(bcp<=0)then
//      dpMainValve:=PF(dpPipe,pp,ActFlowSpeed/(LBDelay))*dt
//    else
//      dpMainVale:=0;
//  else //spuszczanie
//    if(bcp>1)then
//    dpMainValve:=PF(dpPipe,pp,ActFlowSpeed/(LBDelay))*dt;

  dpMainValve:=0;

  if bcp=-1 then
    dpMainValve:=PF(HP,pp,(ActFlowSpeed)/(LBDelay))*dt;
  if(bcp=0)then
    dpMainValve:=-PFVa(HP,pp,(ActFlowSpeed)/(LBDelay),NomPress+RedAdj)*dt;
  if (bcp>1)and(pp>cp) then
    dpMainValve:=PFVd(pp,0,(ActFlowSpeed)/(LBDelay),cp)*dt;
  if bcp=i_bcpNo then
    dpMainValve:=PF(0,pp,(ActFlowSpeed)/(LBDelay))*dt;

  GetPF:=dpMainValve;
end;

procedure TH14K1.Init(press: real);
begin
  CP:= press;
  RedAdj:= 0;
end;

procedure TH14K1.SetReductor(nAdj: real);
begin
  RedAdj:= nAdj;
end;

function TH14K1.GetCP: real;
begin
  GetCP:= CP;
end;

//--- test ---

function Ttest.GetPF(i_bcp:real; pp, hp, dt, ep: real): real;
const
  LBDelay = 100;
var
  LimPP, dpPipe, dpMainValve, ActFlowSpeed: real;
begin

          Limpp:=BPT[Round(i_bcp)][1];
          ActFlowSpeed:=BPT[Round(i_bcp)][0];

          if(i_bcp=i_bcpNo)then limpp:=0.0;

          if(i_bcp=-1)then limpp:=7;

          cp:=cp+20*Min0R(abs(Limpp-cp),0.05)*PR(cp,Limpp)*dt/1;

          Limpp:=cp;
          dpPipe:=Min0R(HP,Limpp);

          dpMainValve:=PF(dpPipe,pp,ActFlowSpeed/(LBDelay))*dt;

          if(Round(i_bcp)=i_bcpNo)then
           begin
            dpMainValve:=PF(0,pp,(ActFlowSpeed)/(LBDelay))*dt;
           end;

  GetPF:=dpMainValve;
end;

procedure Ttest.Init(press: real);
begin
  CP:= press;
end;


//---FD1---

function TFD1.GetPF(i_bcp:real; pp, hp, dt, ep: real): real;
var dp, temp: real;
begin
//  MaxBP:=4;
//  temp:=Min0R(i_bcp*MaxBP,Min0R(5.0,HP));
  temp:=Min0R(i_bcp*MaxBP,HP);              //0011
  dp:=10*Min0R(abs(temp-BP),0.1)*PF(temp,BP,0.0006*(2+Byte(temp>BP)))*dt;
  BP:=BP-dp;
  GetPF:=-dp;
end;

procedure TFD1.Init(press: real);
begin
  BP:=0;
  MaxBP:=press;
end;

function TFD1.GetCP: real;
begin
  GetCP:=BP;
end;


//---KNORR---

function TH1405.GetPF(i_bcp:real; pp, hp, dt, ep: real): real;
var dp, temp, A: real;
begin
  pp:=Min0R(pp,MaxBP);
  if i_bcp>0.5 then
   begin
    temp:=Min0R(MaxBP,HP);
    A:=2*(i_bcp-0.5)*0.0011;
    BP:=Max0R(BP,pp);
   end
  else
   begin
    temp:=0;
    A:=0.2*(0.5-i_bcp)*0.0018;
    BP:=Min0R(BP,pp);
   end;
  dp:=PF(temp,BP,A)*dt;
  BP:=BP-dp;
  GetPF:=-dp;
end;

procedure TH1405.Init(press: real);
begin
  BP:=0;
  MaxBP:=press;
end;

function TH1405.GetCP: real;
begin
  GetCP:=BP;
end;


//---FVel6---

function TFVel6.GetPF(i_bcp:real; pp, hp, dt, ep: real): real;
const
  LBDelay = 100;
var
  LimPP, dpPipe, dpMainValve, ActFlowSpeed: real;
begin
  Limpp:=Min0R(5*Byte(i_bcp<3),hp);
  ActFlowSpeed:=2*Byte((i_bcp<3) or (i_bcp=4));
  dpMainValve:=PF(Limpp,pp,ActFlowSpeed/(LBDelay))*dt;
  GetPF:=dpMainValve;
  EPS:=i_bcp*Byte(i_bcp<2);
end;

function TFVel6.GetCP: real;
begin
  GetCP:=EPS;
end;

end.
