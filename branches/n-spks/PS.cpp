//---------------------------------------------------------------------------

#pragma hdrstop

#include "PS.h"
#include "opengl/glew.h"
#include "stdlib.h"

//---------------------------------------------------------------------------

void __fastcall CRain::CreateDrop()
{
if(nr<maxnr)
{
// pocz�tkowa pr�dko�� kropli, zaburzona losowo
drops[nr].v.x = 0;
drops[nr].v.y = -10 + 0;
drops[nr].v.z = 0;
// pocz�tkowe, losowe po�o�enie kropli
drops[nr].p.x = start.x+((float)rand()/(float)(RAND_MAX+1.0)-1.0)*r;
drops[nr].p.z = start.z+((float)rand()/(float)(RAND_MAX+1.0)-1.0)*r;
drops[nr].p.y = start.y-(float)rand()/(float)(RAND_MAX+1.0)*h;
// poprzednie po�o�enie kropli =
// = startowe po�o�enie kropli
drops[nr].prevp = drops[nr].p;
drops[nr].t = 0; // czas �ycia kropli = 0
nr++; // uaktualnij liczb� kropli
}
} 

void __fastcall CRain::Update(float t, vector3ps w)
{
  r=500;
  for(int i=0;i<nr;i++)
   {
    if(drops[i].t+t<tmax)
     {
      // poprzednia pozycja kropli
      drops[i].prevp = drops[i].p;
      // nowa pozycja kropli
      drops[i].p.x += t*(drops[i].v.x+w.x);
      drops[i].p.z += t*(drops[i].v.z+w.z);
      drops[i].p.y += t*(drops[i].v.y+w.y);
      // uaktualnij czas �ycia
      drops[i].t += t;
     }
    else
     {
      // kropla "martwa", oznacz j� przez t = -1
      drops[i].t = -1;
     }
   }
int k = 0; //liczba martwych kropli
// uporz�dkuj list� kropli, usuwaj�c martwe krople
for(int i=0;i<nr;i++)
{
if(drops[i].t == -1)
{
drops[i] = drops[nr-1];
nr--; // uwaga! modyfikowanie zmiennej wyst�puj�cej
// w warunku p�tli for jest niebezpieczne!
k++;
}
}
// wygeneruj odpowiedni� liczb� nowych kropli
Generate(k);
}

void __fastcall CRain::Generate(int n)
{
  for(int i=0;i<n;i++) CreateDrop();
}


void __fastcall CRain::MoveTo(float x, float y, float z)
{
// przesu� punkt startowy
start.x = x;
start.y = y;
start.z = z;
// sprawd�, kt�re krople wypad�y poza
// obr�b chmury, oznacz je jako martwe
for(int i=0;i<nr;i++)
{
if( abs(drops[i].p.x-start.x)>r ||
abs(drops[i].p.z-start.z)>r ||
drops[i].p.y>start.y ||
start.y-drops[i].p.y>h)
drops[i].t = -1;
}
int k = 0; //liczba martwych kropli
// uporz�dkuj list� kropli, usuwaj�c martwe krople
for(int i=0;i<nr;i++)
{
if(drops[i].t == -1)
{
drops[i] = drops[nr-1];
nr--; // uwaga! modyfikowanie zmiennej wyst�puj�cej
// w warunku p�tli for jest niebezpieczne!
k++;
}
}
// wygeneruj odpowiedni� liczb� nowych kropli
Generate(k);
} 

void __fastcall CRain::Render()
{
glDisable(GL_TEXTURE_2D);
glShadeModel(GL_FLAT);
glEnable(GL_BLEND); // w��cz ��czenie kolor�w
// ustal spos�b ��czenia kolor�w
glBlendFunc(GL_SRC_ALPHA, GL_ONE);
glBegin(GL_LINES);
// kolor linii z kana�em alfa
//glColor4f(0.7, 0.7, 0.7, 0.25);
glColor4f(1, 0, 0, 1);
// narysuj wszystkie krople
for(int i=0; i<nr; i++)
{
//aktualna pozycja kropli
glVertex3f(drops[i].p.x,drops[i].p.y,drops[i].p.z);
// poprzednia pozycja kropli
glVertex3f(drops[i].prevp.x+10,drops[i].prevp.y+10,drops[i].prevp.z+10);

}
glEnd();
glDisable(GL_BLEND);
glEnable(GL_TEXTURE_2D);
glShadeModel(GL_SMOOTH);
}

void __fastcall CRain::Init(int maxn, float x0, float y0, float z0, float timemax, float maxr, float maxh, float vstart)
{
  maxnr=1000; // maksymalna liczba kropli
  r=maxr; // promie� obszaru emisji
  h=maxh; // wysoko�� obszaru emisji
  tmax= timemax; // maksymalny czas �ycia kropli
  start.x= x0;
  start.y= y0;
  start.z= z0;
  nr=0;
}


__fastcall CRain::CRain()
{
}

__fastcall CRain::~CRain()
{
}
#pragma package(smart_init)
