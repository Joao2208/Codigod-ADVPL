#include "protheus.ch"
#include "rwmake.ch"

/*/{Protheus.doc} MM556
    (Função que verifica diariamente o valor de parametros cadastrados na SX6)
    @type  Function
    @author Joao Gomes
    @since 08/11/2021
    @version 1.0
/*/


User Function MM556() 
Local aFile 
Local oFile
Local nLin 
Local nCount
Local cParam
Local cFile := "/scripts/MM556param.txt"
Local aErros := {}
Local cMsg
Local cMsgEr

//prepara o ambiente
If Type('cFilAnt') == 'U'
    RPCSetType(3)
    lEnv := RPCSetEnv('01', '010101')
    IF !lEnv
        ConOut("MM556 - Não conseguiu preparar ambiente")
        Return
    EndIf
EndIf

//verifica se encontra arquivo .txt
If !File(cFile)
    ConOut("MM556 - Não conseguiu encontrar o arquivo")
    Return
EndIf

oFile := tFile():Open(cFile,,"r")

if !oFile:lerr
    aFile := oFile:GetContent("=")
endif

oFile:close()
FreeOBJ(oFile)

nCount := Len(aFile)

//Verifica se tem parametros com o valor diferente do padrão
for nLin := 1 to nCount
    cParam := AllTrim(CValToChar(GetMV(aFile[nLin][1])))
    if cParam != AllTrim(aFile[nLin][2])
        Aadd(aErros, {aFile[nLin][1], cParam, aFile[nLin][2]})        
    endif 
next  

//Cria tabela com os parametros que estão diferente do padrão
cMsg :=('<table border="1" cellspacing="0" cellpadding="10">')
cMsg +=("<tr>")
cMsg +=("<th>Parametro</th>")
cMsg +=("<th>Valor Atual</th>")
cMsg +=("<th>Valor Padrão</th>")
cMsg +=("</tr>")
for nLin := 1 to len(aErros)
    cMsg +=("<tr>")
    cMsg +=("<td>" + aErros[nLin][1] + "</td>")
    cMsg +=("<td>" + aErros[nLin][2] + "</td>")
    cMsg +=("<td>" + aErros[nLin][3] + "</td>")
    cMsg +=("</tr>")
next
cMsg += ("</table>")

//Se tiver parametros fora do padrão manda o e-mail com seus dados
if len(aErros) != 0 
    if len(aErros) == 1
        cMsgEr := "O seguinte parâmetro está com um valor diferente do seu padrão: <br><br>" + cMsg
    elseif len(aErros) >= 2
        cMsgEr := "Os seguintes parâmetros estão com os valores diferentes dos seus padrões: <br><br>" + cMsg
    endif
    U_MM020(GetMV("MV_RELSERV")                             ,;
    GetMV("MV_RELACNT")                                     ,;
    GetMV("MV_RELAUSR",,"madeiramadeira")                   ,;
    GetMV("MV_RELPSW")                                      ,;
    GetMV("MV_RELFROM")                                     ,;
    "protheus@madeiramadeira.com.br"                      ,;
    "*Paramentro(s) com valores alterados!*"                ,;
    cMsgEr                                                  )
endif
    RpcClearEnv()  
Return

