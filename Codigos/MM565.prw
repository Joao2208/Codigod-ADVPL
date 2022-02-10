#include "protheus.ch"
#include "rwmake.ch

/*/{Protheus.doc} User Function MM565
    (Transferência de arquivos da estação do usuário para o diretório de importação)
    @type  Function
    @author joao.gomes
    @since 07/02/2022
    @version 1.0
/*/

User Function MM565()
    Local cMascara  := "Arquivos XML|*.xml"
    Local cTitulo   := "Arquivos XML"
    Local nMascpad  := 0
    Local cDirini   := "C:"
    Local lSalvar   := .F. 
    Local nOpcao1   := GETF_MULTISELECT+GETF_LOCALHARD
    Local nOpcao2   := GETF_RETDIRECTORY+GETF_LOCALHARD
    Local lArvore   := .F.
    Local cArqFile 
    Local cServerFile    := "/importaxml/inn"
    Local cLocalFile
    Local lSucess
    Local aFile 


    DEFINE MSDIALOG oDlgPar TITLE "Arquivos" FROM 001,001 TO 130,290 PIXEL

        @ 015,020 SAY "Escolha uma pasta ou um arquivo do sistema: " SIZE 60,50 PIXEL OF oDlgPar
        @ 015,080 ComboBox oListBox VAR cArqFile ITEMS {"","Pasta","Arquivo"} SIZE 045,010 PIXEL OF oDlgPar 
        DEFINE SBUTTON FROM 030,080 TYPE 1 ACTION (oDlgPar:End()) ENABLE OF oDlgPar

    ACTIVATE MSDIALOG oDlgPar CENTERED
    
    if cArqFile == "Arquivo"
        cLocalFile := cGetFile( cMascara, cTitulo, nMascpad, cDirIni, lSalvar, nOpcao1, lArvore)
        aFile := Directory(cLocalFile, "S")
    elseif cArqFile == "Pasta"
        cLocalFile := cGetFile( cMascara, cTitulo, nMascpad, cDirIni, lSalvar, nOpcao2, lArvore)
        aFile := Directory(cLocalFile+"*.xml*", "D")
    else
        MsgInfo("Nenhuma opcao foi selecionada, o programa ira fechar", "Aviso")
    endif  
    
    lSucess := CpyT2S(cLocalFile, cServerFile)

    if (lSucsses)
        MsgAlert("Arquivos enviados com sucesso", "Alerta")
    else
        MsgAlert("Erro ao enviar arquivos", "Alerta")
    endif
Return


