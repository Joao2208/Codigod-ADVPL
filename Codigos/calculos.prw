#include 'totvs.ch'
#include 'protheus.ch'
#include 'parmtype.ch'

User Function CLC()
	Local oDlgPar := Nil
	Local oLimite
	Local nNum1 := space(6)
	Local nNum2 := space(6)
	Local cCalc := space(1)


	DEFINE MSDIALOG oDlgPar TITLE "Calculadora" FROM 001,001 TO 200,310 PIXEL
	@ 005,005 SAY "Digite o valor 1" SIZE 100,20 PIXEL OF oDlgPar
	@ 006,075 MSGET oLimite VAR nNum1  SIZE 50,05 PIXEL OF oDlgPar
	@ 015,005 SAY "Digite o valor 2" SIZE 100,20 PIXEL OF oDlgPar
	@ 016,075 MSGET oLimite VAR nNum2  SIZE 50,05 PIXEL OF oDlgPar
	@ 025,005 SAY "\ soma(s) \ sub \ div \ mult \" SIZE 100,20 PIXEL OF oDlgPar
	@ 026,075 MSGET oLimite VAR cCalc  SIZE 50,05 PIXEL OF oDlgPar


	DEFINE SBUTTON FROM 033,028 TYPE 1 ACTION (LC(nNum1,nNum2,cCalc), oDlgPar:End()) ENABLE OF oDlgPar
	DEFINE SBUTTON FROM 035,060 TYPE 2 ACTION (oDlgPar:end()) ENABLE OF oDlgPar
	ACTIVATE MSDIALOG oDlgPar CENTERED
Return

User Function LC(nNum1,nNum2,cCalc)
	Local X:= val(nNum1)
	Local Y:= val(nNum2)
	Local form:=(cCalc)

	alert (X)
	alert (Y)
	alert (form) 

	//if form="+"
	//	alert (X+Y)
	//endif
	//if form="-"
	//	alert (X-Y)
	//elseif form="/"
	//	alert (X/Y)
	//elseif form="x"
	//	alert (X*Y)
	//endif


Return
 