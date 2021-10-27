#include "totvs.ch"
#include "protheus.ch"

User Function FSX()
	Local oDlgPar := Nil
	Local oLimite
	Local nLimite := space(6)
	Static cMensagem := space(30)


	DEFINE MSDIALOG oDlgPar TITLE "Sequencia de Fibonacci" FROM 001,001 TO 200,310 PIXEL
	@ 003,005 SAY "Quantia de repetiçoes" SIZE 100,20 PIXEL OF oDlgPar
	@ 002,065 MSGET oLimite VAR nLimite  SIZE 50,05 PIXEL OF oDlgPar


	DEFINE SBUTTON FROM 033,028 TYPE 1 ACTION (FXS(nLimite), oDlgPar:End()) ENABLE OF oDlgPar
	DEFINE SBUTTON FROM 033,058 TYPE 2 ACTION (oDlgPar:end()) ENABLE OF oDlgPar
	ACTIVATE MSDIALOG oDlgPar CENTERED
Return

Static Function FXS(nLimite)
	Local a,t
	Static b,c


	a:=0
	b:=1
	t:=0
	nLimite:=val(nLimite)
	c:=b
	while (a<nLimite)
		t:=a
		a:=b
		b:=t+b

		if (b%2==0)
			alert ("Numero é par "+ cvaltochar(b))
		else
			alert ("numero é impar "+ cvaltochar(b))
		endif
	end
Return


//ver se o numero é primo ou nao e apresentar a msg dizendo se é primo ou nao 


