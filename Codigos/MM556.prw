#include "protheus.ch"
#include "rwmake.ch"

/*/{Protheus.doc} MM556
    (Verificação de parametros)
    @type  Function
    @author user
    @since 08/11/2021
    @version 1.0
/*/


User Function MM55() 
Local aParam 
Local oFile
Local nLin 
Local nColun := 1
Local nCount
Local aErro
Local nE := 0
Local cErro

If Type('cFilAnt') == 'U'
    RPCSetType(3)
    lEnv := RPCSetEnv('01', '010101')
    IF !lEnv
        ConOut("MM556 - Não conseguiu preparar ambiente")
        Return
    EndIf
EndIf

oFile := tFile():Open("C:\Users\joao.gomes\Documents\CodigosGit\Codigod-ADVPL\Codigos\MM556param.txt",,"r")

if !oFile:lerr
    aParam := oFile:GetContent("=")
endif

oFile:close()
FreeOBJ(oFile)

nCount := Len(aParam)

for nLin := 1 to nCount
    if GetMV(aParam[nLin][nColun]) != aParam[nLin][nColun+1]
        cErro := aParam[nLin][nColun]
    endif   
    aErro[nE] := cErro 
next  
    
    
    
/*/if Empty(cParam) 
	// Envia Email 
	U_MM020(    GetMV("MV_RELSERV")                                                     ,;
                GetMV("MV_RELACNT")                                                     ,;
                GetMV("MV_RELAUSR",,"madeiramadeira")                                   ,;
                GetMV("MV_RELPSW")                                                      ,;
                "joao.gomes@madeiramadeira.com.br"/*GetMV("MV_RELFROM")               ,;
                "joao.gomes@madeiramadeira.com.br"                                      ,;
                "***!!Paramentro com erro!!***"                                         ,;
                "O parametro do esta diferente do valor padrao"               ) 
  
endif
    RpcClearEnv() 
*/
Return

