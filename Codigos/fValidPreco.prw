#include "totvs.ch"


User Function fValidPreco()     
Local _lRet:= .T.
Local _cCusto
//Local _cPreco

//N�o valida a execu��o via job - Lucilene SMSTI - 14.06.21
If isBlind()
	Return _lRet
Endif	

_nPosCus  := aScan(aHeader,{|x| AllTrim(x[2])=="C7_CUSTOMM"})
_cCusto   := aCols[n][_nPosCus]
	
If !(RetCodUsr() $ GetMV("MV_GRPALTP"))
	If M->C7_PRECO > _cCusto+0.20 
 		Alert("Voc� n�o tem autoriza��o para altera��o de pre�o. Favor consultar seu gerente!")
		_lRet:=.F.
	Endif
Endif
	
Return _lRet
