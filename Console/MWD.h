#ifndef MWDH
#define MWDH
//---------------------------------------------------------------------------

typedef unsigned char BYTE;
typedef unsigned long DWORD;

class MWDComm
{
private:
    int MWDTime;	//
    char lastStateData[6], maskData[6],maskSwitch[6], bitSwitch[6];
    int bocznik, nastawnik, kierunek;
    char bnkMask;
    
    bool ReadData();	//BYTE *pReadDataBuff);
    bool SendData();	//BYTE *pWriteDataBuff);
    bool CheckData();	//sprawdzanie zmian wej�� i kontrola mazak�w HASLERA
    bool KeyBoard(int key, int s);

    bool bRysik1H;
    bool bRysik1L;
    bool bRysik2H;
    bool bRysik2L;

public:
    bool Open();		// Otwarcie portu
    bool Close();		// Zamkni�cie portu
    bool Run();			// Obs�uga portu
    bool GetMWDState(); // sprawd� czy port jest otwarty, 0 zamkni�ty, 1 otwarty

    // zmienne do rysik�w HASLERA
    bool bSHPstate;
    bool bPrzejazdSHP;
    bool bKabina1;
    bool bKabina2;
    bool bHamowanie;
    bool bCzuwak;



    float fAnalog[4]; 		// trzymanie danych z wej�� analogowych

    BYTE ReadDataBuff[17];	// bufory danych
    BYTE WriteDataBuff[31];

    MWDComm();	//konstruktor
    ~MWDComm();	//destruktor
};
#endif


/*
        INFO - zmiany dokonane w innych plikach niezb�dne do prawid�owego dzia�ania:

        Console.cpp:
         Console::AnalogCalibrateGet	- obs�uga kran�w hamulc�w
         Console::Update		- wywo�ywanie obs�ugi MWD
         Console::ValueSet		- obs�uga manometr�w, miernik�w WN (PWM-y)
         Console::BitsUpdate		- ustawiania lampek
         Console::Off			- zamykanie portu COM
         Console::On			- otwieranie portu COM
         Console::~Console		- usuwanie MWD (jest te� w Console OFF)

         MWDComm * Console::MWD = NULL; - luzem, obiekt i wska�nik(?)
         dodatkowo zmieni�em int na long int dla BitSet i BitClear oraz iBits

        Train.cpp:
         if (Global::iFeedbackMode == 5) - pobieranie pr�dko�ci, manometr�w i miernik�w WN
         if (ggBrakeCtrl.SubModel)       - mo�liwo�� sterowania hamulcem zespolonym
         if (ggLocalBrake.SubModel) 	 - mo�liwo�� sterowania hamulcem lokomotywy

        Globals.h:
         dodano zmienne dla MWD
        Globals.cpp:
         dodano inicjalizaj� zmiennych i odczyt z ini ustawie�

        Wpisy do pliku eu07.ini

                //maciek001 MWD
                comportname COM3	// wyb�r portu COM
                mwdbaudrate 500000

                mwdbreakenable yes	// czy za��czy� sterowanie hamulcami? blokuje klawiature
                mwdbreak 1 255 0 255	// hamulec zespolony
                mwdbreak 2 255 0 255	// hamulec lokomotywy

                mwdzbiornikglowny 	0.82 255
                mwdprzewodglowny 	0.7 255
                mwdcylinderhamulcowy 	0.43 255
                mwdwoltomierzwn 	4000 255
                mwdamperomierzwn 	800 255
*/
