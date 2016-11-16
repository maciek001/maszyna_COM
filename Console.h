/*
This Source Code Form is subject to the
terms of the Mozilla Public License, v.
2.0. If a copy of the MPL was not
distributed with this file, You can
obtain one at
http://mozilla.org/MPL/2.0/.
*/

#ifndef ConsoleH
#define ConsoleH
//---------------------------------------------------------------------------
class TConsoleDevice; // urz�dzenie pod��czalne za pomoc� DLL
class TPoKeys55;
class TLPT;
class MWDComm;        // maciek001: dodana obsluga portu COM

// klasy konwersji znak�w wprowadzanych z klawiatury
class TKeyTrans
{ // przekodowanie kodu naci�ni�cia i zwolnienia klawisza
public:
    short int iDown, iUp;
};

class Console
{ // Ra: klasa statyczna gromadz�ca sygna�y steruj�ce oraz informacje zwrotne
    // Ra: stan wej�cia zmieniany klawiatur� albo dedykowanym urz�dzeniem
    // Ra: stan wyj�cia zmieniany przez symulacj� (mierniki, kontrolki)
private:
    static int iMode; // tryb pracy
    static int iConfig; // dodatkowa informacja o sprz�cie (np. numer LPT)
    static long int iBits; // podstawowy zestaw lampek
    static TPoKeys55 *PoKeys55[2]; // mo�e ich by� kilka
    static TLPT *LPT;
    static MWDComm *MWD;	// maciek001: na potrzeby MWD
    static void BitsUpdate(long int mask);
    // zmienne dla trybu "jednokabinowego", potrzebne do wsp�pracy z pulpitem (PoKeys)
    // u�ywaj�c klawiatury, ka�dy pojazd powinien mie� w�asny stan prze��cznik�w
    // bazowym sterowaniem jest wirtualny strumie� klawiatury
    // przy zmianie kabiny z PoKeys, do kabiny s� wysy�ane stany tych przycisk�w
    static int iSwitch[8]; // bistabilne w kabinie, za��czane z [Shift], wy��czane bez
    static int iButton[8]; // monostabilne w kabinie, za��czane podczas trzymania klawisza
    static TKeyTrans ktTable[4 * 256]; // tabela wczesnej konwersji klawiatury
public:
    Console();
    ~Console();
    static void ModeSet(int m, int h = 0);
    static void BitsSet(long int mask, long int entry = 0);
    static void BitsClear(long int mask, long int entry = 0);
    static int On();
    static void Off();
    static bool Pressed(int x);
    static void ValueSet(int x, double y);
    static void Update();
    static float AnalogGet(int x);
    static float AnalogCalibrateGet(int x);
    static unsigned char DigitalGet(int x);
    static void OnKeyDown(int k);
    static void OnKeyUp(int k);
    static int KeyDownConvert(int k);
    static int KeyUpConvert(int k);
};

#endif
