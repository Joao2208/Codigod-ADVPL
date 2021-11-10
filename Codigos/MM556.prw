#include "protheus.ch"
#include "rwmake.ch"

/*/{Protheus.doc} MM556
    (Verifica��o de parametros)
    @type  Function
    @author user
    @since 08/11/2021
    @version 1.0
/*/


User Function MM55() 
Local aParam 
Local oFile
Local nLin 
Local nCount
Local cParam
Local cFile := "/scripts/MM556param.txt"

If Type('cFilAnt') == 'U'
    RPCSetType(3)
    lEnv := RPCSetEnv('01', '010101')
    IF !lEnv
        ConOut("MM556 - N�o conseguiu preparar ambiente")
        Return
    EndIf
EndIf

If !File(cFile)
    ConOut("MM556 - N�o conseguiu encontrar o arquivo")
    Return
EndIf

oFile := tFile():Open(cFile,,"r")

if !oFile:lerr
    aParam := oFile:GetContent("=")
endif

oFile:close()
FreeOBJ(oFile)

nCount := Len(aParam)

for nLin := 1 to nCount
    cParam := AllTrim(CValToChar(GetMV(aParam[nLin][1])))

    if cParam != AllTrim(aParam[nLin][2])
        U_MM020(GetMV("MV_RELSERV")                                                                             ,;
                GetMV("MV_RELACNT")                                                                                 ,;
                GetMV("MV_RELAUSR",,"madeiramadeira")                                                               ,;
                GetMV("MV_RELPSW")                                                                                  ,;
                "joao.gomes@madeiramadeira.com.br"                                                                  ,;
                "joao.gomes@madeiramadeira.com.br"                                                                  ,;
                "***!!Paramentro " + aParam[nLin][1] + " com erro!!***"                                             ,;
                "***********************************************************************************************"   ,;
                "O parametro " + aParam[nLin][1] + " esta com um valor diferente do padrao que eh "+ aParam[nLin][2],;
                "***********************************************************************************************"   ,)
    endif 
next  
    RpcClearEnv()  
Return

