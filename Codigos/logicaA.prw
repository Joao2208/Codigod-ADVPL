#include "protheus.ch"
#include "rwmake.ch"


User Function testando()
    //Local cAmbName := GetEnvServer()
    Local cName
    Local cValor
    Local aParam := {}
    Local aVal
    Local nCount
     
    If Type('cFilAnt') == 'U'
    RPCSetType(3)
    lEnv := RPCSetEnv('01', '010101')
    IF !lEnv
        ConOut("MM560 - Não conseguiu preparar ambiente")
        Return
    EndIf
    EndIf

    DBSelectArea("SX6")
    
    while !SX6->(EOF())
        cValor := SX6->X6_CONTEUD

        aVal := STRTOKARR(cValor, " ")

        while nCount <= Len(aVal)
            if UPPER(aVal[1][nCount]) = "MADEIRA"
                cName := SX6->X6_VAR
                AAdd(aParam, {cName, cValor})  
            endif
        end

        //if cValor = "1"
        //    cName := SX6->X6_VAR
        //    AAdd(aParam, {cName, cValor}) 
        //endif
        SX6->(DbSkip())
    end

    DbCloseArea()
Return 
