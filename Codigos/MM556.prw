#include "protheus.ch"
#include "rwmake.ch"

/*/{Protheus.doc} MM556
    (Verificação de parametros)
    @type  Function
    @author user
    @since 08/11/2021
    @version 1.0
/*/


User Function MM556()
Local cParam 
Local cFile := 'MM556param.txt'
Local oFile
oFile := FWFileReader():New(cFile)

if (oFile:Open())
    while (oFile:hasLine())
        cParam := File:GetLine
    end
    oFile:close()         
endif


If Type('cFilAnt') == 'U'
    RPCSetType(3)
    lEnv := RPCSetEnv('01', '010101')
    IF !lEnv
        ConOut("MM556 - Não conseguiu preparar ambiente")
        Return
    EndIf
EndIf

if Empty(cParam) 
	// Envia Email 
	U_MM020(    GetMV("MV_RELSERV")                                                     ,;
                GetMV("MV_RELACNT")                                                     ,;
                GetMV("MV_RELAUSR",,"madeiramadeira")                                   ,;
                GetMV("MV_RELPSW")                                                      ,;
                "joao.gomes@madeiramadeira.com.br"/*GetMV("MV_RELFROM")*/               ,;
                "joao.gomes@madeiramadeira.com.br"                                      ,;
                "***!!Paramentro com erro!!***"                                         ,;
                "O parametro do esta diferente do valor padrao"               ) 
  
endif
    RpcClearEnv()  
Return

