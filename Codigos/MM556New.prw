#include "protheus.ch"
#include "rwmake.ch"

/*/{Protheus.doc} MM556
    (Verificação de parametros da SX6)
    @type  Function
    @author user
    @since 08/11/2021
    @version 1.0
/*/


User Function MM559() 
Local aParam 
Local oFile
Local nLin 
Local nCount
Local cParam
Local cFile := "/scripts/MM556param.txt"
Local aErros := {}
Local cMsg
Local cMsgEr

If Type('cFilAnt') == 'U'
    RPCSetType(3)
    lEnv := RPCSetEnv('01', '010101')
    IF !lEnv
        ConOut("MM556 - Não conseguiu preparar ambiente")
        Return
    EndIf
EndIf

If !File(cFile)
    ConOut("MM556 - Não conseguiu encontrar o arquivo")
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
        Aadd(aErros, {aParam[nLin][1], cParam, aParam[nLin][2]})        
    endif 
next  


cMsg :=('<table border="1" cellspacing="0" cellpadding="10">')
cMsg +=("<tr>")
cMsg +=("<th>Parametro</th>")
cMsg +=("<th>Valor Recebido</th>")
cMsg +=("<th>Valor Padrão</th>")
cMsg +=("</tr>")
for nLin := 1 to len(aErros)
    cMsg +=("<tr>")
    cMsg +=("<td>" + aErros[nLin][1] +"</td>")
    cMsg +=("<td>" + aErros[nLin][2] + "</td>")
    cMsg +=("<td>" + aErros[nLin][3] + "</td>")
    cMsg +=("</tr>")
next
cMsg += ("</table>")

if len(aErros) != 0 
    if len(aErros) == 1
        cMsgEr := "O seguinte parametro está com um valor diferente do seu padrão: <br><br>" + cMsg
    elseif len(aErros) >= 2
        cMsgEr := "Os seguintes parametros estão com os valores diferentes dos seus padrões: <br><br>" + cMsg
    endif
    U_MM020(GetMV("MV_RELSERV")                             ,;
    GetMV("MV_RELACNT")                                     ,;
    GetMV("MV_RELAUSR",,"madeiramadeira")                   ,;
    GetMV("MV_RELPSW")                                      ,;
    "joao.gomes@madeiramadeira.com.br"                      ,;
    "joao.gomes@madeiramadeira.com.br"                      ,;
    "*!Paramentro(s) com valores alterados*"                ,;
    cMsgEr                                                  )
endif
    RpcClearEnv()  
Return

