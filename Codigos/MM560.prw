#include "protheus.ch"
#include "rwmake.ch"

/*/{Protheus.doc} MM560
    (Ajusta ambiente sincronizado apagando parametros que n�o podem rodar fora do ambiente de produ��o)
    @type  Function
    @author user
    @since 23/11/2021
    @version 1.0
    /*/
User Function MM560()
    Local cAmbName := GetEnvServer()
    Local aVal 
    if cAmbName == "ZB4Z6T_PRD"
        Return
    else
    
    If Type('cFilAnt') == 'U'
    RPCSetType(3)
    lEnv := RPCSetEnv('01', '010101')
    IF !lEnv
        ConOut("MM556 - N�o conseguiu preparar ambiente")
        Return
    EndIf
    EndIf

        aVal := AllTrim(SX6->X6_CONTEUD)
    endif


Return 
