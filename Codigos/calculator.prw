#include 'totvs.ch'
#include 'protheus.ch'
#include 'parmtype.ch'
/*/{Protheus.doc} User Function JG01
	(CALCULADORA)
	@type  Function
	@author JOAO.GOMES
	@since 13/07/2021
	@param Nil
	@return Nil
/*/



User Function JG01()
	Local nNum1:= 0
	Local nNum2:= 0
	Local cCalc:= ""

	nNum1 := val(FWInputBox("Coloque o primeiro valor : ",""))
		if nNum1=0
			Return			
		endif

    nNum2 := val(FWInputBox("Coloque o segundo valor: ",""))
		if nNum2= 0
			Return			
		endif

		MsgAlert("somar(+), diminuir(-), Multiplicar(*),<br> dividir(/), elevar(^), raiz(Raiz), porcentagem(%)")
    cCalc := FWInputBox("Quer qual função ? ","")
		if cCalc= ""
			Return			
		endif

	if Upper(AllTrim(cCalc))="+"//+
		msgalert(nNum1 + nNum2)
	endif
	if Upper(AllTrim(cCalc))="-"//-
		msgalert(nNum1 - nNum2)
    endif
    if Upper(AllTrim(cCalc))="/"// /
		msgalert(nNum1 / nNum2) 
    endif
	if Upper(AllTrim(cCalc))="*"// *
		msgalert(nNum1*nNum2)
	endif
	if Upper(AllTrim(cCalc))="^"// ^
		MsgAlert(nNum1^nNum2)
	EndIf
	if Upper(AllTrim(cCalc))="RAIZ"// 
		MsgInfo ("Numero 1 " + cValToChar(SQRT(nNum1)))
		MsgInfo ("Numero 2 " + cValToChar(SQRT(nNum2)))
	EndIf
	if Upper(AllTrim(cCalc))="%"//primeiro valor completo depois quantos % vc quer tirar 
		porc := (nNum2/100)*nNum1
		MsgAlert(cValToChar(nNum1) + "% de " + cValToChar(nNum2) + " é: " + cValToChar(porc))
	EndIf


Return


 