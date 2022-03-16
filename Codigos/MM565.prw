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
    Local lSuccess
    Local aFile 
    Local nCount
    Local cConti

    while cConti != "Nao"
    
        //Monta a tela inicial para escolha do tipo de conteudo que deseja selecionar
        DEFINE MSDIALOG oDlgPar TITLE "Arquivos" FROM 001,001 TO 130,290 PIXEL
            @ 015,020 SAY "Escolha uma pasta ou um arquivo do sistema: " SIZE 60,50 PIXEL OF oDlgPar
            @ 015,080 ComboBox oListBox VAR cArqFile ITEMS {"","Pasta","Arquivo"} SIZE 045,010 PIXEL OF oDlgPar 
            DEFINE SBUTTON FROM 030,080 TYPE 1 ACTION (oDlgPar:End()) ENABLE OF oDlgPar
        ACTIVATE MSDIALOG oDlgPar CENTERED
        //Caso seja arquivo manda para um tela onde podemos escolher os arquivos .xml de qualquer pasta do sistema
        if cArqFile == "Arquivo"
            cLocalFile := cGetFile( cMascara, cTitulo, nMascpad, cDirIni, lSalvar, nOpcao1, lArvore)
            aFile := STRTOKARR(cLocalFile, "|")
            //Caso tenha mais de um arquivo selecionado o sistema identifica e faz um procedimento para poder enviar todos para o servidor 
            if len(aFile) > 1
                for nCount := 1 to len(aFile)
                    lSuccess := CpyT2S(AllTrim(aFile[nCount]), cServerFile, .F.)
                next
            else
                lSuccess := CpyT2S(cLocalFile, cServerFile)
            endif
        //Caso seja pasta escolhemos a pasta e somente os arquivos .xml dela vão ir para o sistema
        elseif cArqFile == "Pasta"
            cLocalFile := cGetFile( cMascara, cTitulo, nMascpad, cDirIni, lSalvar, nOpcao2, lArvore)
            aFile := Directory(cLocalFile+"*.xml*", "D")
            //pega arquivo por arquivo da pasta e manda para o servidor
            for nCount := 1 to len(aFile)
                lSuccess := CpyT2S(cLocalFile+aFile[nCount][1], cServerFile)   
            next

        else
            MsgInfo("Nenhuma opcao foi selecionada!", "Aviso")
        endif  


        if (lSuccess)
            MsgInfo("Arquivos enviados com sucesso", "Aviso")
        else
            MsgAlert("Erro ao enviar arquivos", "Alerta")
        endif

        //Gera uma tela para informar se deseja exportar mais arquivos ou não
        DEFINE MSDIALOG oDlgPar TITLE "Finalizacao" FROM 001,001 TO 130,290 PIXEL
            @ 015,020 SAY "Deseja continuar fazendo a exportacao de arquivos ?" SIZE 65,50 PIXEL OF oDlgPar
            @ 015,090 ComboBox oListBox VAR cConti ITEMS {"Nao","Sim"} SIZE 045,010 PIXEL OF oDlgPar 
            DEFINE SBUTTON FROM 030,090 TYPE 1 ACTION (oDlgPar:End()) ENABLE OF oDlgPar
        ACTIVATE MSDIALOG oDlgPar CENTERED

        if cConti == "Nao"
            Return
        endif

    end



