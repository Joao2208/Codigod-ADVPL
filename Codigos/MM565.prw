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
    Local cMascara  := "*.prw|*.prw"
    Local cTitulo   := "Codigos advpl"
    Local nMascpad  := 0
    Local cDirini   := "C:"
    Local lSalvar   := .F. 
    Local nOpcoes   := GETF_LOCALHARD
    Local lArvore   := .F. 
    //Local ServerFile    := "/importaxml/inn"
    Local LocalFile
    //Local sucess


    DEFINE MSDIALOG oDlgPar TITLE "Arquivos" FROM 001,001 TO 100,210 PIXEL

    @ 017,020 SAY "Arquivos XML" SIZE 100,50 PIXEL OF oDlgPar
    DEFINE SBUTTON FROM 015,060 TYPE 4 ACTION (LocalFile := cGetFile( cMascara, cTitulo, nMascpad, cDirIni, lSalvar, nOpcoes, lArvore),oDlgPar:End()) ENABLE OF oDlgPar
    Sucess := CpyT2S(LocalFile, ServerFile)
    
    

    ACTIVATE MSDIALOG oDlgPar CENTERED
Return


