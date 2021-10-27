#include "protheus.ch"
#include "rwmake.ch"

//-------------------------------------------------------------------------------
/*/{Protheus.doc} MM169
Cadastros de parametros para a controladoria

@return 
@author Felipe Toazza Caldeira
@since 31/07/2017
/*/
//-------------------------------------------------------------------------------

User Function MM169()
Local oDlgPar   := NIL 
Local dUlMes    := GetMV("MV_ULMES")
Local dDataCtb  := GetMV("MV_DATACTB")
Local dDataFat  := GetMV("MV_DATAFAT")
Local dDataFin  := GetMV("MV_DATAFIN")
Local dDataFis  := GetMV("MV_DATAFIS")  
Local dDataMov  := GetMV("MV_DBLQMOV")
Local nLimDias  := GetMV("MM_LIMDIAS")
Local cDtCont   := GetMV("MM_DTCONT")
Local cAltLcto  := GetMV("MV_ALTLCTO")
Local lCont     := GetMV("MM_CONT252")
Local cCont
Local oDataMV    
Local oDiasMM   
Local oDataMM

if cAltLcto == "N"
    cAltLcto := "Nao" 
else 
    cAltLcto := "Sim"
endif

if lCont == .T.
    cCont := "Ativado"
else 
    cCont := "Desativado"
endif

// Monta a tela  
DEFINE MSDIALOG oDlgPar TITLE "Parametros de fechamento" FROM 001,001 TO 390,340 PIXEL
                                                         
@ 006,030 SAY "MV_ULMES: "   SIZE 50,07 PIXEL OF oDlgPar
@ 005,081 MSGET oDataMV VAR dUlMes SIZE 45,05 WHEN .T. PICTURE PesqPict("SE1","E1_EMISSAO") PIXEL OF oDlgPar

@ 021,030 SAY "MV_DATACTB: "   SIZE 50,07 PIXEL OF oDlgPar
@ 020,081 MSGET oDataMV VAR dDataCtb SIZE 45,05 WHEN .T. PICTURE PesqPict("SE1","E1_EMISSAO") PIXEL OF oDlgPar

@ 036,030 SAY "MV_DATAFAT: "   SIZE 50,07 PIXEL OF oDlgPar
@ 035,081 MSGET oDataMV VAR dDataFat SIZE 45,05 WHEN .T. PICTURE PesqPict("SE1","E1_EMISSAO") PIXEL OF oDlgPar

@ 051,030 SAY "MV_DATAFIN: "   SIZE 50,07 PIXEL OF oDlgPar
@ 050,081 MSGET oDataMV VAR dDataFin SIZE 45,05 WHEN .T. PICTURE PesqPict("SE1","E1_EMISSAO") PIXEL OF oDlgPar

@ 066,030 SAY "MV_DATAFIS: "   SIZE 50,07 PIXEL OF oDlgPar
@ 065,081 MSGET oDataMV VAR dDataFis SIZE 45,05 WHEN .T. PICTURE PesqPict("SE1","E1_EMISSAO") PIXEL OF oDlgPar

@ 081,030 SAY "MV_DBLQMOV: "   SIZE 50,07 PIXEL OF oDlgPar
@ 080,081 MSGET oDataMV VAR dDataMov SIZE 45,05 WHEN .T. PICTURE PesqPict("SE1","E1_EMISSAO") PIXEL OF oDlgPar

@ 096,030 SAY "MM_LIMDIAS: "   SIZE 50,07 PIXEL OF oDlgPar
@ 095,081 MSGET oDiasMM VAR nLimDias SIZE 15,05 WHEN .T. PICTURE "@E 99" VALID Positivo(nLimDias) PIXEL OF oDlgPar

@ 111,030 SAY "MM_DTCONT: "   SIZE 50,07 PIXEL OF oDlgPar
@ 110,081 MSGET oDataMM VAR cDtCont SIZE 20,05 WHEN .T. PICTURE "@E 99" PIXEL OF oDlgPar

@ 126,030 SAY "MV_ALTLCTO: "   SIZE 50,07 PIXEL OF oDlgPar
@ 125,081 ComboBox oListBox VAR cAltLcto ITEMS {"Sim","Nao"} SIZE 30,10 PIXEL OF oDlgPar

@ 141,030 SAY "MM_CONT252: "   SIZE 50,07 PIXEL OF oDlgPar
@ 140,081 ComboBox oListBox VAR cCont ITEMS {"Ativado","Desativado"} SIZE 045,010 PIXEL OF oDlgPar 

DEFINE SBUTTON FROM 0175,108 TYPE 1 ACTION (GrvDatas(dUlMes,dDataCtb,dDataFat,dDataFin,dDataFis,dDataMov,nLimDias,cDtCont,cAltLcto,cCont),oDlgPar:End()) ENABLE OF oDlgPar
DEFINE SBUTTON FROM 0175,138 TYPE 2 ACTION (oDlgPar:End()) ENABLE OF oDlgPar

ACTIVATE MSDIALOG oDlgPar CENTERED

Return

Static Function GrvDatas(dUlMes,dDataCtb,dDataFat,dDataFin,dDataFis,dDataMov,nLimDias,cDtCont,cAltLcto,cCont)

if cAltLcto == "Nao"
    cAltLcto := "N" 
else 
    cAltLcto := "S"
endif

if cCont == "Desativado"
    lCont := .F.
else 
    lCont := .T.
endif

PUTMV("MV_ULMES",dUlMes)
PUTMV("MV_DATACTB",dDataCtb)
PUTMV("MV_DATAFAT",dDataFat)
PUTMV("MV_DATAFIN",dDataFin)
PUTMV("MV_DATAFIS",dDataFis)
PUTMV("MV_DBLQMOV",dDataMov)
PUTMV("MM_LIMDIAS",nLimDias)
PUTMV("MM_DTCONT",cDtCont)
PUTMV("MV_ALTLCTO",cAltLcto)
PUTMV("MM_CONT252",lCont)
Return
