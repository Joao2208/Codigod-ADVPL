#include 'totvs.ch'
#include 'protheus.ch'
#include 'parmtype.ch'
#include 'topconn.ch'
/*/{Protheus.doc} User Function MM519BAM
	(Fun��o criada para o cadastro de novos ambientes)
	@type  Function
	@author Jo�o Gomes	
	@since 9/06/2021
	@version 1
/*/
User Function MM519BAM()
	Local cAlias := "Z19"
	Private cTitulo := "Cadastro ambientes GS"
	Private aRotina := {}
	Private cCadastro := "Cadastro de ambientes GS"


	AADD(aRotina,{"Pesquisa"    ,"AxPesqui"   	  ,0,1})
	AADD(aRotina,{"Visualizar"  ,"AxVisual"       ,0,2})
	AADD(aRotina,{"Incluir"     ,"U_MM519BAI"     ,0,3})
	AADD(aRotina,{"Trocar"      ,"U_MM519BAA"     ,0,4})
	AADD(aRotina,{"Excluir"     ,"U_MM519BAE"     ,0,5})

	dbSelectArea(cAlias)
	dbSetOrder(1)
	MBrowse(,,,,cAlias)
Return nil

/*/{Protheus.doc} User Function MM519BAI
	(Inclus�o dos ambientes)
	@type  Function
	@author Jo�o Gomes	
	@since 9/06/2021
	@version 1
/*/
User Function MM519BAI(cAlias,nReg,nOpc)
	Local nOpcao := 0
	nOpcao := AxInclui(cAlias,nReg,nOpc)
	If nOpcao == 1
		MsgInfo("Inclus�o efetuada com sucesso!")
	Else
		MsgAlert("Inclus�o Cancelada!")
	EndIf
Return

/*/{Protheus.doc} User Function MM519BAA
	(Altera��o dos ambientes)
	@type  Function
	@author Jo�o Gomes	
	@since 9/06/2021
	@version 1
/*/
User Function MM519BAA(cAlias,nReg,nOpc)
	Local nOpcao := 0
	nOpcao := AxAltera(cAlias,nReg,nOpc)
	If nOpcao == 1
		MsgInfo("Altera��o efetuada com sucesso!")
	Else
		MsgAlert("Altera��o Cancelada!")
	EndIf
Return Nil

/*/{Protheus.doc} User Function MM519BAE
	(Deleta os ambientes)
	@type  Function
	@author Jo�o Gomes	
	@since 9/06/2021
	@version 1
/*/
User Function MM519BAE(cAlias,nReg,nOpc)
	Local nOpcao := 0
	nOpcao := AxDeleta(cAlias,nReg,nOpc)
	If nOpcao == 1
		MsgInfo("Exclus�o cancelada!")
	Else
		MsgAlert("Exclus�o efetuada com sucesso!")
	Endif
Return Nil

/*/{Protheus.doc} User Function MM519AMB
	(Numerac�o automatica do ID do campo ambiente )
	@type  Function
	@author Daniel Bueno	
	@since 9/06/2021
	@version 1
/*/
User Function MM519AMB()
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


