#include "protheus.ch"
#include "topconn.ch"
#include "rptdef.ch"

/*/{Protheus.doc} User Function GetICMS
	(long_description)
	@type  Function
	@author JOAO.GOMES
	@since 08/06/2022
	@version 1.0
	@param cNumDoc, 	, param_descr
	@return return_var, return_type, return_description
	@example
	(examples)
	@see (links_or_references)
	/*/
USER Function GetICMS(cNumDoc)
	//Local cAls
  //Local cQry
  Local cNumPed := '8668270'
  Local nICMS
  Local nTxMoeda 
  Local Datprf   
  Local C7Aprov  
  Local C7Conapro
  Local C7Tipo   
  Local nX
  
  
  If Type('cFilAnt') == 'U'
    RPCSetType(3)
    lEnv := RPCSetEnv('01', '010101')
    IF !lEnv
        ConOut("MM556 - Não conseguiu preparar ambiente")
        Return
    EndIf
  EndIf
  
  cAls2 := GetNextAlias()

cQuery:="SELECT  "
cQuery+="		SC5.R_E_C_N_O_ C5RECNO, SA1.R_E_C_N_O_ A1RECNO, A2_MMVAO, SA2.R_E_C_N_O_ A2RECNO, "
cQuery+=" 		SC7.C7_PRODUTO, SC7.C7_NUM, SC7.C7_FORNECE, SC7.C7_LOJA, SC7.C7_TXMOEDA, SC7.C7_UM, SC7.C7_PRECO, SC7.C7_MOEDA, SC7.C7_DATPRF, SC7.C7_IPI, "
cQuery+="		SC7.C7_NUMSC, SC7.C7_MMNUMPV, SC7.C7_UM, SC7.C7_QUANT, SC7.C7_TOTAL, SC7.C7_APROV, SC7.C7_CONAPRO, SC7.C7_TIPO, SC7.C7_DESC1, SC7.C7_DESC2, "
cQuery+="		SC7.C7_DESC3, SC7.C7_COND, SC7.C7_EMISSAO, SC7.C7_REAJUST, SC7.C7_OBS "
cQuery+="FROM "+RetSqlName("SC7")+ " SC7 "
cQuery+=" INNER JOIN "+RetSqlName("SA2")+ " SA2 ON A2_FILIAL = '"+xFilial("SA2")+"' AND A2_COD = C7_FORNECE AND A2_LOJA = C7_LOJA AND SA2.D_E_L_E_T_ = '' "
cQuery+=" LEFT JOIN "+RetSqlName("SC6")+ " SC6 ON C6_FILIAL = '"+xFilial("SC6")+"' AND C6_NUM = C7_MMITV AND C7_MMITPV = C6_ITEM AND SC6.D_E_L_E_T_ = '' "
cQuery+=" LEFT JOIN "+RetSqlName("SC5")+ " SC5 ON C5_FILIAL = C6_FILIAL AND C5_NUM = C6_NUM AND SC5.D_E_L_E_T_ = '' "
cQuery+=" LEFT JOIN "+RetSqlName("SA1")+ " SA1 ON A1_FILIAL = '"+xFilial("SA1")+"' AND A1_COD = C5_CLIENTE AND A1_LOJA = C5_LOJACLI AND SA1.D_E_L_E_T_ = '' "
cQuery+="WHERE SC7.C7_NUM = '"+cNumPed+"' AND "
cQuery+="SC7.C7_FILIAL = '010107' AND "
cQuery+="SC7.D_E_L_E_T_ = ' ' "
TCQuery cQuery new alias &cAls2



Return nICMS


Static Function R110FIniOC(cPedido,cItem,cSequen,cFiltro)

Local aArea		:= GetArea()
Local aAreaSC7	:= SC7->(GetArea())
Local cValid	:= ""
Local nPosRef	:= 0
Local nItem		:= 0
Local cItemDe	:= IIf(cItem==Nil,'',cItem)
Local cItemAte	:= IIf(cItem==Nil,Repl('Z',Len(SC7->C7_ITEM)),cItem)
Local cRefCols	:= ''
Local nX
Local cFilSC7   := xFilial('SC7')
Static aStru	:= FWFormStruct(3,"SC7")[1]

DEFAULT cSequen	:= ""
DEFAULT cFiltro	:= ""

dbSelectArea("SC7")
dbSetOrder(1)
If dbSeek(cFilSC7+cPedido+cItemDe+Alltrim(cSequen))
	MaFisEnd()
	MaFisIni(SC7->C7_FORNECE,SC7->C7_LOJA,"F","N","R",{})
	While !Eof() .AND. SC7->C7_FILIAL+SC7->C7_NUM == cFilSC7+cPedido .AND. ;
			SC7->C7_ITEM <= cItemAte .AND. (Empty(cSequen) .OR. cSequen == SC7->C7_SEQUEN)

		// Nao processar os Impostos se o item possuir residuo eliminado  
		If &cFiltro
			SC7->(dbSkip())
			Loop
		EndIf
            
		// Inicia a Carga do item nas funcoes MATXFIS  
		nItem++
		MaFisIniLoad(nItem)

		For nX := 1 To Len(aStru)
			cValid	:= StrTran(UPPER(GetCbSource(aStru[nX][7]))," ","")
			cValid	:= StrTran(cValid,"'",'"')
			If "MAFISREF" $ cValid .And. !(aStru[nX][14]) //campos que não são virtuais
				nPosRef  := AT('MAFISREF("',cValid) + 10
				cRefCols := Substr(cValid,nPosRef,AT('","MT120",',cValid)-nPosRef )
				// Carrega os valores direto do SC7.           
				MaFisLoad(cRefCols,&("SC7->"+ aStru[nX][3]),nItem)
			EndIf
		Next nX		

		MaFisEndLoad(nItem,2)
		
		SC7->(dbSkip())
	End
EndIf

RestArea(aAreaSC7)
RestArea(aArea)

Return .T.

/*
U_ACOM002("8668270")
	MaFisEnd()
	cAls := GetNextAlias()

//BeginSql Alias cAls
//%NoParser%

cQry:=  "SELECT SC7.C7_PRODUTO, SC7.C7_NUM, SC7.C7_FORNECE, SC7.C7_LOJA, SC7.C7_TXMOEDA, SC7.C7_UM,"+;
          "SC7.C7_PRECO, SC7.C7_MOEDA, SC7.C7_DATPRF, SC7.C7_IPI, SC7.C7_NUMSC, SC7.C7_MMNUMPV,"+;
          "SC7.C7_UM, SC7.C7_QUANT, SC7.C7_TOTAL, SC7.C7_APROV, SC7.C7_CONAPRO, SC7.C7_TIPO,"+;
          "SC7.C7_DESC1, SC7.C7_DESC2, SC7.C7_DESC3, SC7.C7_COND, SC7.C7_EMISSAO, SC7.C7_REAJUST,"+;
          "SC7.C7_OBS, SC7.C7_QTSEGUM, SC7.C7_ITEM, RTRIM(SA5.A5_CODPRF) A5_CODPRF "+;
        "FROM " + RetSQLName("SC7") + " SC7 "+;
        "LEFT JOIN " + RetSQLName("SA5") + " SA5 (NOLOCK) ON SA5.A5_FILIAL = " + xFilial("SC7") +;
                                    " AND SA5.A5_FORNECE = SC7.C7_FORNECE "+;
                                    "AND SA5.A5_LOJA = SC7.C7_LOJA "+;
                                    "AND SA5.A5_PRODUTO = SC7.C7_PRODUTO "+;
                                    "AND SA5.D_E_L_E_T_ != '*' "+;
                                    "AND SA5.R_E_C_N_O_ = "+;
                                    "(SELECT TOP 1 SA5B.R_E_C_N_O_ "+;
                                    "FROM " + RetSQLName("SA5") + " SA5B (NOLOCK) "+;
                                    "WHERE SA5B.A5_FILIAL = SA5.A5_FILIAL "+;
                                    "AND SA5B.A5_FORNECE = SA5.A5_FORNECE "+;
                                    "AND SA5B.A5_LOJA = SA5.A5_LOJA "+;
                                    "AND SA5B.A5_PRODUTO = SA5.A5_PRODUTO "+;
                                    "AND SA5B.D_E_L_E_T_ != '*' "+;
                                    "AND LEFT(SA5B.A5_MMVIGEN, 8) <= C7_EMISSAO "+;
                                  "ORDER BY SA5B.A5_MMVIGEN DESC, SA5B.R_E_C_N_O_ DESC) "+;
          "WHERE SC7.C7_FILIAL = " + xFilial("SC7") +;
          "AND SC7.C7_NUM = '8668270' "+;
          "AND SC7.D_E_L_E_T_ != '*'"
  TCQuery cQry new alias &cAls
  */
