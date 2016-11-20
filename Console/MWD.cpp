/*
        Program obs�ugi portu COM i innych na potrzeby sterownika MWDevise
        dla Symulatora Pojazd�w Szynowych MaSzyna

        author: Maciej Witek 2016
        wszelkie prawa zastrze�one!
*/

#include "MWD.h"
#include "Logs.h"
#include "Globals.h"
#include "World.h"

#include <windows.h>

#define BYTETOWRITE 31  		/* ilo�� bajt�w przesy�anych z MaSzyny*/
#define BYTETOREAD  16  		/* ilo�� bajt�w przesy�anych do MaSzyny*/

HANDLE hComm;

MWDComm::MWDComm()		// konstruktor
{
    MWDTime = 0;
    bSHPstate = false;	// // usun��em typy zmiennych (bool-e) - po co jeszcze raz deklarowa� przy inicjalizacji?
    bPrzejazdSHP = false;
    bKabina1 = true;		// pasuje wyci�gn�� dane na temat kabiny i ustawia� te dwa parametry!
    bKabina2 = false;
    bHamowanie = false;
    bCzuwak = false;

    bRysik1H = false;
    bRysik1L = false;
    bRysik2H = false;
    bRysik2L = false;

    bocznik = 0;
    nastawnik = 0;
    kierunek = 0;
    bnkMask = 0;

    int i=0;
    while(i<BYTETOWRITE)
    {
        if(i<BYTETOREAD)ReadDataBuff[i] = 0;
        WriteDataBuff[i] = 0;
        i++;
    }
    i=0;
    while(i<6)
    {
        lastStateData[i] = 0;
        maskSwitch[i] = 0;
        bitSwitch[i] = 0;
        i++;
    }
}

MWDComm::~MWDComm()		// destruktor
{
    Close();
}

bool MWDComm::Open()		// otwieranie portu COM
{
    LPCSTR portId = Global::sMWDPortId.c_str();
    hComm = CreateFile(portId, GENERIC_READ | GENERIC_WRITE, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);

    if (hComm == INVALID_HANDLE_VALUE){
        if(GetLastError()==ERROR_FILE_NOT_FOUND){
            WriteLog("PortCOM ERROR: serial port does not exist");	//serial port does not exist.  Inform user.
        }
        WriteLog("PortCOM ERROR! not open!");
        //some other error occurred. Inform user.
        return FALSE;
    }

    DCB CommDCB;
    CommDCB.DCBlength = sizeof(DCB);
    GetCommState(hComm, &CommDCB);

    CommDCB.BaudRate = Global::iMWDBaudrate;
    CommDCB.fBinary = TRUE;
    CommDCB.fParity = FALSE;
    CommDCB.fOutxCtsFlow = FALSE;         // No CTS output flow control
    CommDCB.fOutxDsrFlow = FALSE;         // No DSR output flow control
    CommDCB.fDtrControl = FALSE;          // DTR flow control type

    CommDCB.fDsrSensitivity = FALSE;      // DSR sensitivity
    CommDCB.fTXContinueOnXoff = FALSE;     // XOFF continues Tx
    CommDCB.fOutX = FALSE;                // No XON/XOFF out flow control
    CommDCB.fInX = FALSE;                 // No XON/XOFF in flow control
    CommDCB.fErrorChar = FALSE;           // Disable error replacement
    CommDCB.fNull = FALSE;                // Disable null stripping
    CommDCB.fRtsControl = RTS_CONTROL_DISABLE;

    CommDCB.fAbortOnError = FALSE;

    CommDCB.ByteSize = 8;
    CommDCB.Parity = NOPARITY;
    CommDCB.StopBits = ONESTOPBIT;

    //konfiguracja portu
    if (!SetCommState (hComm, &CommDCB))
    {
        //dwError = GetLastError ();
        WriteLog("Unable to configure the serial port!");
        return FALSE;
    }
    WriteLog("PortCOM OPEN and CONFIG!");
    return TRUE;
}

bool MWDComm::Close()		// zamykanie portu COM
{
    WriteLog("zamykam COM-a");
    int i = 0;
    while(i<BYTETOWRITE)
    {
        WriteDataBuff[i] = 0;
        i++;
    }
    Sleep(100);
    SendData();
    Sleep(700);
    CloseHandle(hComm);
    WriteLog("COM zamkniety");
    return TRUE;
}

bool MWDComm::GetMWDState()	// sprawdzanie otwarcia portu COM
{
    if(hComm > 0) return 1;
    else return 0;
}

bool MWDComm::ReadData()	// odbieranie danych + odczyta danych analogowych i zapis do zmiennych
{
    DWORD bytes_read;
    ReadFile(hComm, &ReadDataBuff[0], BYTETOREAD, &bytes_read, NULL);
    //WriteConsoleOnly("Read OK!");
    fAnalog[0] = (float)((ReadDataBuff[8]<<8)+ReadDataBuff[9]) / Global::fMWDAnalogCalib[0][3]; //4095.0f; //max wartosc wynikaj�ca z rozdzielczo�ci
    fAnalog[1] = (float)((ReadDataBuff[10]<<8)+ReadDataBuff[11]) / Global::fMWDAnalogCalib[1][3];
    fAnalog[2] = (float)((ReadDataBuff[12]<<8)+ReadDataBuff[13]) / Global::fMWDAnalogCalib[2][3];
    fAnalog[3] = (float)((ReadDataBuff[14]<<8)+ReadDataBuff[15]) / Global::fMWDAnalogCalib[3][3];
    CheckData();
    //WriteLog("hamulec zespolony VALUE: "+AnsiString(fAnalog[0]));
    //WriteLog("hamulec zespolony ReadB[9]: "+AnsiString(ReadDataBuff[9]));
    //WriteLog("hamulec zespolony calib: "+AnsiString(Global::fMWDAnalogCalib[0][3]));

    return TRUE;
}

bool MWDComm::SendData()	// wysy�anie danych
{
    DWORD bytes_write;
    DWORD fdwEvtMask;

    WriteFile(hComm, &WriteDataBuff[0], BYTETOWRITE, &bytes_write, NULL);

    return TRUE;
}

bool MWDComm::Run()			// wysyo�ywanie obs�ugi MWD + generacja wi�kszego op�nienia
{
    MWDTime++;
    if(!(MWDTime%5))
    {
        if(GetMWDState())
        {
            SendData();
            ReadData();
            return 1;
        }else
        {
            WriteLog("Port COM: blad polaczenia!");
            // mo�e spr�bowa� si� po��czy� znowu?
            return 0;
        }
        MWDTime = 0;
    }
}

bool MWDComm::CheckData()	// sprawdzanie wej�� cyfrowych i odpowiednie sterowanie maszyn�
{
    int i=0;
    while(i<6)
    {
        maskData[i] = ReadDataBuff[i]^lastStateData[i];
        lastStateData[i] = ReadDataBuff[i];
        i++;
    }
    /*
                Rozpiska port�w!
                Port0: 	0 	NC			odblok. przek. spr�arki i wentyl. opor�w
                                1 	M			wy��cznik wy�. szybkiego
                                2 	Shift+M		impuls za��czaj�cy wy�. szybki
                                3 	N			odblok. przeka�nik�w nadmiarowych i r�nicowego obwodu g��wnego
                                4 	NC			rezerwa
                                5 	Ctrl+N		odblok. przek. nadmiarowych przetwornicy, ogrzewania poci�gu i r�nicowych obw. pomocniczych
                                6 	L			wy�. stycznik�w liniowych
                                7 	SPACE		kasowanie czuwaka

                Port1: 	0 	NC
                                1 	(Shift)	X	przetwornica
                                2 	(Shift)	C	spr�arka
                                3 	S			piasecznice
                                4 	(Shift)	H	ogrzewanie sk�adu
                                5 				przel. hamowania	Shift+B pspbpwy Ctrl+B pospieszny B towarowy
                                6 				przel. hamowania
                                7 	(Shift)	F	rozruch w/n

                Port2: 	0 	(Shift) P	pantograf przedni
                                1 	(Shift)	O	pantograf tylni
                                2 	ENTER		przyhamowanie przy po�lizgu
                                3 	()		przyciemnienie �wiate�
                                4 	()		przyciemnienie �wiate�
                                5 	NUM6		odlu�niacz
                                6 	a			syrena lok W
                                7	A			syrena lok N

                Port3: 	0 	Shift+J		bateria
                                1
                                2
                                3
                                4
                                5
                                6
                                7
        */

    /*	po prze��czeniu bistabilnego najpierw wciskamy klawisz i przy nast�pnym
                wej�ciu w p�tl� MWD puszczamy bo inaczej nie dzia�a							*/

    // wciskanie przycisk�w klawiatury
    /*PORT0*/
    if(maskData[0] & 0x02) if(lastStateData[0] & 0x02) 	KeyBoard('M',1);	// wy��czenie wy��cznika szybkiego
    else 						KeyBoard('M',0);	// monostabilny
    if(maskData[0] & 0x04) if(lastStateData[0] & 0x04) 	{               	// impuls za��czaj�cy wy��cznik szybki
        KeyBoard(0x10,1);	// monostabilny
        KeyBoard('M',1);
    }else{
        KeyBoard('M',0);
        KeyBoard(0x10,0);
    }
    if(maskData[0] & 0x08) if(lastStateData[0] & 0x08) 	KeyBoard('N',1);	// odblok nadmiarowego silnik�w trakcyjnych
    else						KeyBoard('N',0);	// monostabilny
    if(maskData[0] & 0x20) if(lastStateData[0] & 0x20) 	{			// odblok nadmiarowego przetwornicy, ogrzewania poc.
        KeyBoard(0x11,1);                                                       // r�nicowego obwod�w pomocniczych
        KeyBoard('N',1);          // monostabilny
    }else{
        KeyBoard('N',0);
        KeyBoard(0x11,0);
    }
    if(maskData[0] & 0x40) if(lastStateData[0] & 0x40) 	KeyBoard('L',1);	// wy�. stycznik�w liniowych
    else						KeyBoard('L',0);	// monostabilny
    if(maskData[0] & 0x80) if(lastStateData[0] & 0x80) 	KeyBoard(0x20,1);	// kasowanie czuwaka/SHP
    else 						KeyBoard(0x20,0);	// kasowanie czuwaka/SHP

    /*PORT1*/

    // puszczanie przycisku bistabilnego klawiatury
    if(maskSwitch[1]&0x02){
        if(bitSwitch[1] &0x02){
            KeyBoard('X',0);
            KeyBoard(0x10,0);
        }else KeyBoard('X',0);
        maskSwitch[1] &= ~0x02;
    }
    if(maskSwitch[1]&0x04){
        if(bitSwitch[1] &0x04){
            KeyBoard('C',0);
            KeyBoard(0x10,0);
        }else KeyBoard('C',0);
        maskSwitch[1] &= ~0x04;
    }
    if(maskSwitch[1]&0x10){
        if(bitSwitch[1] &0x10){
            KeyBoard('H',0);
            KeyBoard(0x10,0);
        }else KeyBoard('H',0);
        maskSwitch[1] &= ~0x10;
    }
    if(maskSwitch[1] & 0x20 || maskSwitch[1] & 0x40){
        if(maskSwitch[1] & 0x20) KeyBoard(0x10,0);
        if(maskSwitch[1] & 0x40) KeyBoard(0x11,0);
        KeyBoard('B',0);
        maskSwitch[1] &= ~0x60;
    }
    if(maskSwitch[1]&0x80){
        if(bitSwitch[1] &0x80){
            KeyBoard('F',0);
            KeyBoard(0x10,0);
        }else KeyBoard('F',0);
        maskSwitch[1] &= ~0x80;
    }


    if(maskData[1] & 0x02) if(lastStateData[1] & 0x02) 	{                     // przetwornica
        KeyBoard(0x10,1);	// bistabilny
        KeyBoard('X',1);
        maskSwitch[1] |= 0x02;
        bitSwitch[1] |= 0x02;
    }else{
        maskSwitch[1] |= 0x02;
        bitSwitch[1] &= ~0x02;
        KeyBoard('X',1);
    }
    if(maskData[1] & 0x04) if(lastStateData[1] & 0x04) 	{                      // spr�arka
        KeyBoard(0x10,1);	// bistabilny
        KeyBoard('C',1);
        maskSwitch[1] |= 0x04;
        bitSwitch[1] |= 0x04;
    }else{
        maskSwitch[1] |= 0x04;
        bitSwitch[1] &= ~0x04;
        KeyBoard('C',1);
    }
    if(maskData[1] & 0x08) if(lastStateData[1] & 0x08)	KeyBoard('S',1);	// piasecznica
    else                                            	KeyBoard('S',0);	// monostabilny
    if(maskData[1] & 0x10) if(lastStateData[1] & 0x10)  {			// ogrzewanie sk�adu
        KeyBoard(0x11,1);	// bistabilny
        KeyBoard('H',1);
        maskSwitch[1] |= 0x10;
        bitSwitch[1] |= 0x10;
    }else{
        maskSwitch[1] |= 0x10;
        bitSwitch[1] &= ~0x10;
        KeyBoard('H',1);
    }
    if(maskData[1] & 0x20 || maskData[1] & 0x40){				// prze��cznik hamowania
        if(lastStateData[1] & 0x20){		// Shift+B
            KeyBoard(0x10,1);
            maskSwitch[1] |= 0x20;
        }else if(lastStateData[1] & 0x40){	// Ctrl+B
            KeyBoard(0x11,1);
            maskSwitch[1] |= 0x40;
        }
        KeyBoard('B',1);
    }

    if(maskData[1] & 0x80) if(lastStateData[1] & 0x80) 	{			// rozruch wysoki/niski
        KeyBoard(0x10,1);	// bistabilny
        KeyBoard('F',1);
        maskSwitch[1] |= 0x80;
        bitSwitch[1] |= 0x80;
    }else{
        maskSwitch[1] |= 0x80;
        bitSwitch[1] &= ~0x80;
        KeyBoard('F',1);
    }


    /*PORT2*/

    if(maskSwitch[2]&0x01){
        if(bitSwitch[2] &0x01){
            KeyBoard('P',0);
            KeyBoard(0x10,0);
        }else KeyBoard('P',0);
        maskSwitch[2] &= ~0x01;
    }
    if(maskSwitch[2]&0x02){
        if(bitSwitch[2] &0x02){
            KeyBoard('O',0);
            KeyBoard(0x10,0);
        }else KeyBoard('O',0);
        maskSwitch[2] &= ~0x02;
    }


    if(maskData[2] & 0x01) if(lastStateData[2] & 0x01) 	{		// pantograf przedni
        KeyBoard(0x10,1);	// bistabilny
        KeyBoard('P',1);
        maskSwitch[2] |= 0x01;
        bitSwitch[2] |= 0x01;
    }else{
        maskSwitch[2] |= 0x01;
        bitSwitch[2] &= ~0x01;
        KeyBoard('P',1);
    }
    if(maskData[2] & 0x02) if(lastStateData[2] & 0x02) 	{		// pantograf tylni
        KeyBoard(0x10,1);	// bistabilny
        KeyBoard('O',1);
        maskSwitch[2] |= 0x02;
        bitSwitch[2] |= 0x02;
    }else{
        maskSwitch[2] |= 0x02;
        bitSwitch[2] &= ~0x02;
        KeyBoard('O',1);
    }
    if(maskData[2] & 0x04) if(lastStateData[2] & 0x04) 	{		// przyhamowanie przy po�lizgu
        KeyBoard(0x10,1);	// monostabilny
        KeyBoard(0x0D,1);
    }else{

        KeyBoard(0x0D,0);
        KeyBoard(0x10,0);
    }
    /*if(maskData[2] & 0x08) if(lastStateData[2] & 0x08){           // przyciemnienie �wiate�
            KeyBoard(' ',0);	// bistabilny
            KeyBoard(0x10,1);
            KeyBoard(' ',1);
        }else{
            KeyBoard(' ',0);
            KeyBoard(0x10,0);
            KeyBoard(' ',1);
        }
        if(maskData[2] & 0x10) if(lastStateData[2] & 0x10)  {       // przyciemnienie �wiate�
            KeyBoard(' ',0);	// bistabilny
            KeyBoard(0x11,1);
            KeyBoard(' ',1);
        }else{
            KeyBoard(' ',0);
            KeyBoard(0x11,0);
            KeyBoard(' ',1);
        }*/
    if(maskData[2] & 0x20) if(lastStateData[2] & 0x20)	KeyBoard(0x66,1);	// odlu�niacz
    else						KeyBoard(0x66,0);	// monostabilny
    if(maskData[2] & 0x40) if(lastStateData[2] & 0x40) 	{			// syrena wysoka
        KeyBoard(0x10,1);	// monostabilny
        KeyBoard('A',1);
    }else{
        KeyBoard('A',0);
        KeyBoard(0x10,0);
    }
    if(maskData[2] & 0x80) if(lastStateData[2] & 0x80)	KeyBoard('A',1);	// syrena niska
    else						KeyBoard('A',0);	// monostabilny


    /*PORT3*/

    if(maskSwitch[3]&0x01){
        if(bitSwitch[3] &0x01){
            KeyBoard('J',0);
            KeyBoard(0x10,0);
        }else KeyBoard('J',0);
        maskSwitch[3] &= ~0x01;
    }

    if(maskData[3] & 0x01) if(lastStateData[3] & 0x01) 	{			// bateria
        KeyBoard(0x10,1);	// bistabilny
        KeyBoard('J',1);
        maskSwitch[3] |= 0x01;
        bitSwitch[3] |= 0x01;
    }else{
        maskSwitch[3] |= 0x01;
        bitSwitch[3] &= ~0x01;
        KeyBoard('J',1);
    }

    /*
        if(maskData[3] & 0x04) if(lastStateData[1] & 0x04) 	{                                                                                                                KeyBoard(0x10,1);
                                                                        KeyBoard('C',1);	//
                                                                        KeyBoard('C',0);
                                                                        KeyBoard(0x10,0);
        }else{								KeyBoard('C',1);	//
                                                                        KeyBoard('C',0);
        }
        if(maskData[3] & 0x08) if(lastStateData[1] & 0x08)	KeyBoard('S',1);	//
        else							KeyBoard('S',0);


        if(maskData[3] & 0x10) if(lastStateData[1] & 0x10)  {
                                                                KeyBoard(0x11,1);
                                                                KeyBoard('H',1);
        }else{							KeyBoard('H',0);
                                                                KeyBoard(0x11,0);
        }
        if(maskData[3] & 0x20) if(lastStateData[1] & 0x20) {
                                                                                                                KeyBoard(0x11,1);
                                                                                                                KeyBoard(' ',1);
        }else{												KeyBoard(' ',0);
                                                                                                                KeyBoard(0x11,0);
        }
        if(maskData[3] & 0x40) if(lastStateData[1] & 0x40) 	{
                                                                                                                KeyBoard(0x10,1);
                                                                                                                KeyBoard(' ',1);
        }else{												KeyBoard(' ',0);
                                                                                                                KeyBoard(0x10,0);
        }
        if(maskData[3] & 0x80) if(lastStateData[1] & 0x80) 	{
                                                                                                                KeyBoard(0x10,1);
                                                                                                                KeyBoard('F',1);
        }else{												KeyBoard('F',0);
                                                                                                                KeyBoard(0x10,0);
        }

        /*PORT4*//*
        if(maskData[4] & 0x02) if(lastStateData[1] & 0x02) 	{
                                                                                                                KeyBoard(0x10,1);
                                                                                                                KeyBoard('X',1);	//
                                                                                                                KeyBoard('X',0);
                                                                                                                KeyBoard(0x10,0);
        }else{ 												KeyBoard('X',1);	//
                                                                                                                KeyBoard('X',0);
        }
        if(maskData[4] & 0x04) if(lastStateData[1] & 0x04) 	{
                                                                                                                KeyBoard(0x10,1);
                                                                                                                KeyBoard('C',1);	//
                                                                                                                KeyBoard('C',0);
                                                                                                                KeyBoard(0x10,0);
        }else{												KeyBoard('C',1);	//
                                                                                                                KeyBoard('C',0);
        }
        if(maskData[4] & 0x08) if(lastStateData[1] & 0x08)	KeyBoard('S',1);	//
        else												KeyBoard('S',0);


        if(maskData[4] & 0x10) if(lastStateData[1] & 0x10)  {
                                                                                                                KeyBoard(0x11,1);
                                                                                                                KeyBoard('H',1);
        }else{												KeyBoard('H',0);
                                                                                                                KeyBoard(0x11,0);
        }
        if(maskData[4] & 0x20) if(lastStateData[1] & 0x20) {
                                                                                                                KeyBoard(0x11,1);
                                                                                                                KeyBoard(' ',1);
        }else{												KeyBoard(' ',0);
                                                                                                                KeyBoard(0x11,0);
        }
        if(maskData[4] & 0x40) if(lastStateData[1] & 0x40) 	{
                                                                                                                KeyBoard(0x10,1);
                                                                                                                KeyBoard(' ',1);
        }else{												KeyBoard(' ',0);
                                                                                                                KeyBoard(0x10,0);
        }
        if(maskData[4] & 0x80) if(lastStateData[1] & 0x80) 	{
                                                                                                                KeyBoard(0x10,1);
                                                                                                                KeyBoard('F',1);
        }else{												KeyBoard('F',0);
                                                                                                                KeyBoard(0x10,0);
        }

        /*PORT5*//*
        if(maskData[5] & 0x02) if(lastStateData[1] & 0x02) 	{
                                                                                                                KeyBoard(0x10,1);
                                                                                                                KeyBoard('X',1);	//
                                                                                                                KeyBoard('X',0);
                                                                                                                KeyBoard(0x10,0);
        }else{ 												KeyBoard('X',1);	//
                                                                                                                KeyBoard('X',0);
        }
        if(maskData[5] & 0x04) if(lastStateData[1] & 0x04) 	{
                                                                                                                KeyBoard(0x10,1);
                                                                                                                KeyBoard('C',1);	//
                                                                                                                KeyBoard('C',0);
                                                                                                                KeyBoard(0x10,0);
        }else{												KeyBoard('C',1);	//
                                                                                                                KeyBoard('C',0);
        }
        if(maskData[5] & 0x08) if(lastStateData[1] & 0x08)	KeyBoard('S',1);	//
        else												KeyBoard('S',0);


        if(maskData[5] & 0x10) if(lastStateData[1] & 0x10)  {
                                                                                                                KeyBoard(0x11,1);
                                                                                                                KeyBoard('H',1);
        }else{												KeyBoard('H',0);
                                                                                                                KeyBoard(0x11,0);
        }
        if(maskData[5] & 0x20) if(lastStateData[1] & 0x20) {
                                                                                                                KeyBoard(0x11,1);
                                                                                                                KeyBoard(' ',1);
        }else{												KeyBoard(' ',0);
                                                                                                                KeyBoard(0x11,0);
        }
        if(maskData[5] & 0x40) if(lastStateData[1] & 0x40) 	{
                                                                                                                KeyBoard(0x10,1);
                                                                                                                KeyBoard(' ',1);
        }else{												KeyBoard(' ',0);
                                                                                                                KeyBoard(0x10,0);
        }
        if(maskData[5] & 0x80) if(lastStateData[1] & 0x80) 	{
                                                                                                                KeyBoard(0x10,1);
                                                                                                                KeyBoard('F',1);
        }else{												KeyBoard('F',0);
                                                                                                                KeyBoard(0x10,0);
        }//*/

    /* NASTAWNIK, BOCZNIK i KIERUNEK */

    if(bnkMask & 1){
        KeyBoard(0x6B,0);
        bnkMask &= ~1;
    }
    if(bnkMask & 2){
        KeyBoard(0x6D,0);
        bnkMask &= ~2;
    }
    if(bnkMask & 4){
        KeyBoard(0x6F,0);
        bnkMask &= ~4;
    }
    if(bnkMask & 8){
        KeyBoard(0x6A,0);
        bnkMask &= ~8;
    }

    if(nastawnik < ReadDataBuff[6])
    {
        bnkMask |= 1;
        nastawnik++;
        KeyBoard(0x6B,1); //wci�nij + i dodaj 1 do nastawnika
    }
    if(nastawnik > ReadDataBuff[6])
    {
        bnkMask |= 2;
        nastawnik--;
        KeyBoard(0x6D,1); //wci�nij - i odejmij 1 do nastawnika
    }
    if(bocznik < ReadDataBuff[7])
    {
        bnkMask |= 4;
        bocznik++;
        KeyBoard(0x6F,1); //wci�nij / i dodaj 1 do bocznika
    }
    if(bocznik > ReadDataBuff[7])
    {
        bnkMask |= 8;
        bocznik--;
        KeyBoard(0x6A,1); //wci�nij * i odejmij 1 do bocznika
    }

    /* Obs�uga HASLERA */

    if(ReadDataBuff[0] & 0x80) bCzuwak = true;

    if(bKabina1){			// logika rysika 1
        bRysik1H = true;
        bRysik1L = false;
        if(bPrzejazdSHP) bRysik1H = false;
    }else if(bKabina2){
        bRysik1L = true;
        bRysik1H = false;
        if(bPrzejazdSHP) bRysik1L = false;
    }else{
        bRysik1H = false;
        bRysik1L = false;
    }

    if(bHamowanie){			// logika rysika 2
        bRysik2H = false;
        bRysik2L = true;
    }else{
        if(bCzuwak) bRysik2H = true;
        else bRysik2H = false;
        bRysik2L = false;
    }
    bCzuwak = false;
    if(bRysik1H) 	WriteDataBuff[5] |= 1<<0;
    else 			WriteDataBuff[5] &= ~(1<<0);
    if(bRysik1L) 	WriteDataBuff[5] |= 1<<1;
    else 			WriteDataBuff[5] &= ~(1<<1);
    if(bRysik2H) 	WriteDataBuff[5] |= 1<<2;
    else 			WriteDataBuff[5] &= ~(1<<2);
    if(bRysik2L) 	WriteDataBuff[5] |= 1<<3;
    else 			WriteDataBuff[5] &= ~(1<<3);
}

bool MWDComm::KeyBoard(int key, int s)	// emulacja klawiatury
{
    INPUT ip;
    // Set up a generic keyboard event.
    ip.type = INPUT_KEYBOARD;
    ip.ki.wScan = 0; // hardware scan code for key
    ip.ki.time = 0;
    ip.ki.dwExtraInfo = 0;

    ip.ki.wVk = key; // virtual-key code for the "a" key
    
    if(s!=0){// Press the "A" key
        ip.ki.dwFlags = 0; // 0 for key press
        SendInput(1, &ip, sizeof(INPUT));
    }else{
        ip.ki.dwFlags = KEYEVENTF_KEYUP; // KEYEVENTF_KEYUP for key release
        SendInput(1, &ip, sizeof(INPUT));
    }

    return 1;
}


