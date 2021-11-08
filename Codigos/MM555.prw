#include "protheus.ch"
#include "rwmake.ch"

/*/{Protheus.doc} MM555
    (Verificação de parametros)
    @type  Function
    @author user
    @since 08/11/2021
    @version 1.0
    /*/


User Function MM555()
Local cEstNeg    := ""//GetMV("MV_ESTNEG")

If Type('cFilAnt') == 'U'
    RPCSetType(3)
    lEnv := RPCSetEnv('01', '010101')
    IF !lEnv
        ConOut("MM555 - Não conseguiu preparar ambiente")
        Return
    EndIf
EndIf

cEstNeg := GetMV("MV_ESTNEG")

if cEstNeg != "N"
	// Envia Email 
	U_MM020(    GetMV("MV_RELSERV")                                                   ,;
                GetMV("MV_RELACNT")                                                   ,;
                GetMV("MV_RELAUSR",,"madeiramadeira")                                 ,;
                GetMV("MV_RELPSW")                                                    ,;
                GetMV("MV_RELFROM")                                                   ,;
                "protheus@madeiramadeira.com.br"                                      ,;
                "*****!!Paramentro do MV_ESTNEG errado!!*****"                        ,;
                "O parametro do MV_ESTNEG esta diferente do valor padrao 'N'"         ) 
  
endif
    RpcClearEnv()  
Return

