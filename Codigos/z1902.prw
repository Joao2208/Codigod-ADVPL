#include 'protheus.ch'
#include 'parmtype.ch'
#include 'totvs.ch'
#include 'topconn.ch'

/*/{Protheus.doc} MBRSA2
//TODO Descrição auto-gerada.
@author RCTI TREINAMENTOS
@since 2018
@version undefined

@type function
/*/
user function Z19()
	Local cAlias 		:= "Z19"
	Private cCadastro 	:= "Cadastro Produtos"
	Private aRotina 	:= {}
	Private aIndexZ19 	:= {}
	Private cFiltra		:= {}
	Private bFiltraBrw := {|| FilBrowse(cAlias,@aIndexZ19,@cFiltra)} 
	 
	
	AADD(aRotina,{"Pesquisar" 	,"AxPesqui" 	,0,1})
	AADD(aRotina,{"Visualizar" 	,"AxVisual" 	,0,2})
	AADD(aRotina,{"Incluir" 	,"U_AInclui" 	,0,3})
	AADD(aRotina,{"Alterar" 	,"U_AAltera" 	,0,4})
	AADD(aRotina,{"Excluir" 	,"U_ADeleta" 	,0,5})

	

	dbSelectArea(cAlias) 
	dbSetOrder(1)
	
	Eval(bFiltraBrw)
	
	dbGoTop()
	mBrowse(6,1,22,75,cAlias)
	
	EndFilBrw(cAlias,aIndexZ19)
	
return

User Function AInclui(cAlias,nReg,nOpc)
	Local nOpcao := 0
	nOpcao := AxInclui(cAlias,nReg,nOpc)
		If nOpcao == 1
			MsgInfo("Inclusão efetuada com sucesso!")
		Else
			MsgAlert("Inclusão Cancelada!")
		EndIf	
Return

User Function AAltera(cAlias,nReg,nOpc)
	Local nOpcao := 0
	nOpcao := AxAltera(cAlias,nReg,nOpc)
		If nOpcao == 1
			MsgInfo("Alteração efetuada com sucesso!")
		Else
			MsgAlert("Alteração Cancelada!")
		EndIf	
Return Nil

User Function ADeleta(cAlias,nReg,nOpc)
	Local nOpcao := 0
	nOpcao := AxDeleta(cAlias,nReg,nOpc)
	If nOpcao == 1                                 
		MsgInfo("Exclusão cancelada!")           
	Else
		MsgAlert("Exclusão efetuada com sucesso!")
	Endif
Return Nil

User Function MM519()
Local cAls := ""
Local cQry := ""
Local cID  := ""
cAls := GetNextAlias()
cQry := " SELECT COALESCE(MAX(Z19_ID),'0') Z19ID FROM " + RetSQLName("Z19") + " (NOLOCK) WHERE Z19_FILIAL = '" + xFilial("Z19") + "' AND D_E_L_E_T_ <> '*'"
TcQuery cQry New Alias &cAls
DbSelectArea(cAls)
(cAls)->(DbGoTop())
cID := Soma1((cAls)->Z19ID)
(cAls)->(DbCloseArea())
Return cID
