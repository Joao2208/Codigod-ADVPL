#include "totvs.ch"


User Function fValidPreco()     
Local _lRet:= .T.
Local _cCusto
//Local _cPreco

//Não valida a execução via job - Lucilene SMSTI - 14.06.21
If isBlind()
	Return _lRet
Endif	

_nPosCus  := aScan(aHeader,{|x| AllTrim(x[2])=="C7_CUSTOMM"})
_cCusto   := aCols[n][_nPosCus]
	
If !(RetCodUsr() $ GetMV("MV_GRPALTP"))
	If M->C7_PRECO > _cCusto+0.20 
 		Alert("Você não tem autorização para alteração de preço. Favor consultar seu gerente!")
		_lRet:=.F.
	Endif
Endif
	
Return _lRet
