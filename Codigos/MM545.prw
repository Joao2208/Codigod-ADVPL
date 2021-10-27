#include "protheus.ch"
#include "tbiconn.ch"
#include "totvs.ch"
#include "topconn.ch"

/*/{Protheus.doc} User Function MM545
	(Função para puxar tabelas)
	@type  Function
	@author João Gomes	
	@since 30/08/2021
	@version 1
/*/
User Function MM545()
Local cIndice1, cIndice2, cIndice3, cQuery, cAlsBrow

Private oBrowse, cArqJGT, cLegBrw
Private aRotina := {}
Private cCadastro := "REPASSE DE SELLERS"
Private aCampos   := {}, aSeek := {}, aFieFilter := {}

//Rotinas do menu
aAdd(aRotina, {"Legenda"	        , "U_MM545LBR", 0, 1})



//Array contendo os campos da tabela temporária
AAdd(aCampos,{"SELLER",		"C",TamSx3("Z1E_SELLER")[1],0})
AAdd(aCampos,{"NOME",		"C",TamSx3("A2_NREDUZ")[1],0}) 
AAdd(aCampos,{"REPASSE",	"C",TamSx3("Z1E_CTRLRE")[1],0})
AAdd(aCampos,{"INCLUSAO",	"C",TamSx3("Z1E_DTINCL")[1],0})
AAdd(aCampos,{"HORA",		"C",TamSx3("Z1E_HORA")[1],0})
AAdd(aCampos,{"CNPJ",		"C",TamSx3("A2_CGC")[1],0})
AAdd(aCampos,{"SOLICITADO",	"C",TamSx3("Z1E_DTSORE")[1],0})
AAdd(aCampos,{"DATA_REP",	"C",TamSx3("Z1E_DTREPA")[1],0})
AAdd(aCampos,{"VALOR",		"N",TamSx3("Z1E_VLREPA")[1],0})
AAdd(aCampos,{"COMISSAO",	"N",TamSx3("Z1E_VLCOMI")[1],0})
AAdd(aCampos,{"FRETE",		"N",TamSx3("Z1E_VLFRET")[1],0})
AAdd(aCampos,{"DESCONTOS",	"N",TamSx3("Z1F_VALOR")[1],0})
AAdd(aCampos,{"ARRJ",		"C",TamSx3("Z11_BANDEI")[1],0})
AAdd(aCampos,{"FATURA",		"C",TamSx3("E2_NUM")[1],0})
AAdd(aCampos,{"EMISSAO",	"C",TamSx3("E2_EMISSAO")[1],0})
AAdd(aCampos,{"VENCIMENTO",	"C",TamSx3("E2_VENCREA")[1],0})
AAdd(aCampos,{"PREFIXO",	"C",TamSx3("E2_PREFIXO")[1],0})
AAdd(aCampos,{"SALDO",		"N",TamSx3("E2_SALDO")[1],0})   
AAdd(aCampos,{"BORDERO",	"C",TamSx3("E2_NUMBOR")[1],0})
AAdd(aCampos,{"DATA_PGTO",	"C",TamSx3("EA_DATABOR")[1],0})
AAdd(aCampos,{"IDCNAB",		"C",TamSx3("E2_IDCNAB")[1],0})
AAdd(aCampos,{"BANCO",		"C",TamSx3("FIL_BANCO")[1],0})
AAdd(aCampos,{"AGENCIA",	"C",TamSx3("FIL_AGENCI")[1],0})
AAdd(aCampos,{"CONTA",		"C",TamSx3("FIL_CONTA")[1],0})
AAdd(aCampos,{"RET_CNAB",	"C",TamSx3("Z2V_OCORRE")[1]+1+TamSx3("Z2V_DESCRI")[1],0})
AAdd(aCampos,{"RET_VALOR",	"N",TamSx3("Z2V_VALOR")[1],0})
AAdd(aCampos,{"EFTO_CONT",	"C",TamSx3("Z4F_IDPGTO")[1],0})
AAdd(aCampos,{"VLR_EFT",	"N",TamSx3("Z4F_VALOR")[1],0})
AAdd(aCampos,{"CNPJ_BENE",	"C",TamSx3("Z4F_CNPJ")[1],0})
AAdd(aCampos,{"BENEFI",		"C",TamSx3("A2_NREDUZ")[1],0})

//Antes de criar a tabela, verificar se a mesma já foi aberta
If (Select("JGT") <> 0)
	dbSelectArea("JGT")
	JGT->(DbCloseArea ())
Endif

//Criar tabela temporária
cArqJGT := CriaTrab(aCampos,.T.)


//Definir indices da tabela
cIndice1 := Alltrim(CriaTrab(,.F.))
cIndice2 := cIndice1
cIndice3 := cIndice1

cIndice1 := Left(cIndice1,5)+Right(cIndice1,2)+"A"
cIndice2 := Left(cIndice2,5)+Right(cIndice2,2)+"B"
cIndice3 := Left(cIndice3,5)+Right(cIndice3,2)+"C"

If File(cIndice1+OrdBagExt())
	FErase(cIndice1+OrdBagExt())
EndIf

If File(cIndice2+OrdBagExt())
	FErase(cIndice2+OrdBagExt())
EndIf

If File(cIndice3+OrdBagExt())
	FErase(cIndice3+OrdBagExt())
EndIf


//Criar e abrir a tabela
dbUseArea(.T.,,cArqJGT,"JGT",Nil,.F.)


//Criar indice
IndRegua("JGT",cIndice1,"SELLER",,,)
IndRegua("JGT",cIndice2,"CNPJ",,,)
IndRegua("JGT",cIndice3,"REPASSE",,,)
dbClearIndex()
dbSetIndex(cIndice1+OrdBagExt())
dbSetIndex(cIndice2+OrdBagExt())
dbSetIndex(cIndice3+OrdBagExt())


//Busca as infos para o browse
cAlsBrow := GetNextAlias()

cQuery := "SELECT"+ CRLF
cQuery += "Z1E_SELLER SELLER, SA2.A2_NREDUZ NOME, SA2.A2_CGC CNPJ, Z1E_CTRLRE REPASSE, Z1E_DTINCL INCLUSAO, Z1E_HORA HORA, Z1E_DTSORE SOLICITADO, Z1E_DTREPA DATA_REP,"+ CRLF
cQuery += "Z1E_VLREPA VALOR, Z1E_VLCOMI COMISSAO, Z1E_VLFRET FRETE, (SELECT SUM(Z1F_VALOR)"+ CRLF
cQuery += "FROM " + RetSQLName("Z1F") + " Z1F(NOLOCK)"+ CRLF
cQuery += "WHERE Z1F_CTRLRE = Z1E_CTRLRE"+ CRLF
cQuery += "AND Z1F_TPLANC IN ('4','10','8','14','15')) DESCONTOS,"+ CRLF
cQuery += "Z11_BANDEI ARRJ, SE2.E2_NUM FATURA, SE2.E2_EMISSAO EMISSAO, SE2.E2_VENCREA VENCIMENTO,"+ CRLF
cQuery += "SE2.E2_PREFIXO PREFIXO, SE2.E2_SALDO - SE2.E2_SDDECRE SALDO, SE2.E2_NUMBOR BORDERO, EA_DATABOR DATA_PGTO, SE2.E2_IDCNAB IDCNAB,"+ CRLF
cQuery += "CASE"+ CRLF
cQuery += "WHEN SE2.E2_PREFIXO = 'PM ' THEN FIL_BANCO"+ CRLF
cQuery += "WHEN SE2.E2_PREFIXO = 'CER' THEN Z4F_BANCO"+ CRLF
cQuery += "END BANCO,"+ CRLF
cQuery += "CASE WHEN SE2.E2_PREFIXO = 'PM ' THEN FIL_AGENCI WHEN SE2.E2_PREFIXO = 'CER' THEN Z4F_AGENCI END AGENCIA,"+  CRLF
cQuery += "CASE WHEN SE2.E2_PREFIXO = 'PM ' THEN FIL_CONTA WHEN SE2.E2_PREFIXO = 'CER' THEN Z4F_CONTA END CONTA,"+ CRLF
cQuery += "(SELECT Z2VA.Z2V_OCORRE+' '+Z2VA.Z2V_DESCRI"+ CRLF
cQuery += "FROM " + RetSQLName("Z2V") + " Z2VA(NOLOCK)"+ CRLF
cQuery += "WHERE Z2VA.R_E_C_N_O_ = (SELECT MAX(Z2VB.R_E_C_N_O_) RECNO"+ CRLF
cQuery += "FROM " + RetSQLName("Z2V") + " Z2VB(NOLOCK)"+ CRLF
cQuery += "WHERE Z2VB.Z2V_IDCNAB = SE2.E2_IDCNAB AND Z2V_IDCNAB != '' AND Z2VB.D_E_L_E_T_ != '*')"+ CRLF
cQuery += ") RET_CNAB,"+ CRLF
cQuery += "(SELECT Z2VC.Z2V_VALOR"+ CRLF
cQuery += "FROM " + RetSQLName("Z2V") + " Z2VC(NOLOCK)"+ CRLF
cQuery += "WHERE Z2VC.R_E_C_N_O_ = (SELECT MAX(Z2VD.R_E_C_N_O_) RECNOD"+ CRLF
cQuery += "FROM " + RetSQLName("Z2V") + " Z2VD(NOLOCK)"+ CRLF
cQuery += "WHERE Z2VD.Z2V_IDCNAB = SE2.E2_IDCNAB AND Z2V_IDCNAB != '' AND Z2VD.Z2V_OCORRE IN ('00','06','07','08') AND Z2VD.D_E_L_E_T_ != '*')"+ CRLF
cQuery += ") RET_VALOR,"+ CRLF
cQuery += "Z4F_IDPGTO EFTO_CONT, Z4F_VALOR VLR_EFT,"+ CRLF
cQuery += "Z4F_CNPJ CNPJ_BENE, SA2A.A2_NREDUZ BENEFI"+ CRLF
cQuery += "FROM " + RetSQLName("Z1E") + " Z1E(NOLOCK)"+ CRLF
cQuery += "LEFT JOIN "+ RetSQLName("Z11") + " Z11(NOLOCK)"+ CRLF
cQuery += "ON Z11_FILIAL = Z1E_FILIAL AND Z11_CTRLRE = Z1E_CTRLRE AND Z11.D_E_L_E_T_ != '*'"+ CRLF
cQuery += "LEFT JOIN "+ RetSQLName("SE2") + " SE2(NOLOCK)"+ CRLF
cQuery += "ON SE2.R_E_C_N_O_ = Z11_RECSE2 AND SE2.D_E_L_E_T_ != '*'"+ CRLF
cQuery += "LEFT JOIN "+ RetSQLName("Z4F") + " Z4F(NOLOCK)"+ CRLF
cQuery += "ON Z4F_RECSE2 = Z11_RECSE2 AND Z4F_GERDPA = 'S' AND Z4F.D_E_L_E_T_ != '*'"+ CRLF
cQuery += "INNER JOIN "+ RetSQLName("SA2") + " SA2(NOLOCK)"+ CRLF
cQuery += "ON SA2.A2_MMSELLE = Z1E_SELLER AND SA2.A2_MSBLQL = '2' AND SA2.D_E_L_E_T_ != '*'"+ CRLF
cQuery += "LEFT JOIN "+ RetSQLName("FIL") + " FIL(NOLOCK)"+ CRLF
cQuery += "ON FIL_FILIAL = A2_FILIAL AND FIL_FORNEC = A2_COD AND FIL_TIPO = '1' AND FIL.D_E_L_E_T_ != '*'"+ CRLF
cQuery += "LEFT JOIN "+ RetSQLName("SA2") + " SA2A(NOLOCK)"+ CRLF
cQuery += "ON SA2A.A2_CGC = Z4F_CNPJ AND SA2A.A2_MSBLQL = '2' AND SA2A.A2_MMSELLE != '' AND SA2A.D_E_L_E_T_ != '*'"+ CRLF
cQuery += "LEFT JOIN "+ RetSQLName("SEA") + " SEA(NOLOCK)"+ CRLF
cQuery += "ON EA_FILIAL = SE2.E2_FILIAL AND EA_NUM = E2_NUM AND EA_PREFIXO = E2_PREFIXO AND EA_PARCELA = E2_PARCELA AND EA_TIPO = E2_TIPO AND EA_FORNECE = E2_FORNECE AND SEA.D_E_L_E_T_ != '*'"+ CRLF
cQuery += "WHERE Z1E_DTINCL >= '20210830'"+ CRLF
cQuery += "AND Z1E_STATUS = 'S'"+ CRLF
cQuery += "AND Z1E.D_E_L_E_T_ != '*'"+ CRLF
cQuery += "ORDER BY Z1E_CTRLRE, SE2.E2_PREFIXO+Z11_BANDEI DESC"+ CRLF


TcQuery cQuery New Alias &cAlsBrow

DbSelectArea(cAlsBrow)
(cAlsBrow)->(DbGoTop())

While !((cAlsBrow)->(EOF())) 
	DbSelectArea("JGT")	
	RecLock("JGT",.T.)		
		JGT->SELLER :=		(cAlsBrow)->SELLER
		JGT->NOME := 		(cAlsBrow)->NOME
		JGT->CNPJ := 		(cAlsBrow)->CNPJ
		JGT->REPASSE := 	(cAlsBrow)->REPASSE 
		JGT->INCLUSAO :=	(cAlsBrow)->INCLUSAO
		JGT->HORA :=		(cAlsBrow)->HORA
		JGT->SOLICITADO := 	(cAlsBrow)->SOLICITADO 
		JGT->DATA_REP := 	(cAlsBrow)->DATA_REP
		JGT->VALOR := 		(cAlsBrow)->VALOR 
		JGT->COMISSAO := 	(cAlsBrow)->COMISSAO 
		JGT->FRETE := 		(cAlsBrow)->FRETE 
		JGT->DESCONTOS := 	(cAlsBrow)->DESCONTOS 
		JGT->ARRJ := 		(cAlsBrow)->ARRJ 
		JGT->FATURA := 		(cAlsBrow)->FATURA 
		JGT->EMISSAO :=		(cAlsBrow)->EMISSAO
		JGT->VENCIMENTO := 	(cAlsBrow)->VENCIMENTO 
		JGT->PREFIXO := 	(cAlsBrow)->PREFIXO 
		JGT->SALDO := 		(cAlsBrow)->SALDO 
		JGT->BORDERO := 	(cAlsBrow)->BORDERO 
		JGT->DATA_PGTO := 	(cAlsBrow)->DATA_PGTO 
		JGT->IDCNAB := 		(cAlsBrow)->IDCNAB 
		JGT->BANCO := 		(cAlsBrow)->BANCO 
		JGT->AGENCIA := 	(cAlsBrow)->AGENCIA 
		JGT->CONTA := 	 	(cAlsBrow)->CONTA 
		JGT->RET_CNAB := 	(cAlsBrow)->RET_CNAB 
		JGT->RET_VALOR := 	(cAlsBrow)->RET_VALOR 
		JGT->EFTO_CONT := 	(cAlsBrow)->EFTO_CONT 
		JGT->VLR_EFT := 	(cAlsBrow)->VLR_EFT 
		JGT->CNPJ_BENE := 	(cAlsBrow)->CNPJ_BENE 
		JGT->BENEFI := 		(cAlsBrow)->BENEFI 
	MsunLock()
	
	(cAlsBrow)->(DbSkip())
End

(cAlsBrow)->(DbCloseArea())

DbSelectArea("JGT")
JGT->(DbGoTop())

//Campos que irao compor o combo de pesquisa na tela principal
Aadd(aSeek,{"Codigo do seller."	 ,{{"","C",10,0,"SELLER","@!"}},1,.T.})
Aadd(aSeek,{"CNPJ."				 ,{{"","C",18,0,"CNPJ","@R 99.999.999/9999-99"}},2,.T.})
Aadd(aSeek,{"Codigo de repasse." ,{{"","C",20,0,"REPASSE","@!"}},3,.T.})


//Campos que irao compor a tela de filtro
Aadd(aFieFilter,{"SELLER","Codigo do seller." 		,"C",10,0,"@!"})
Aadd(aFieFilter,{"NOME","Nome"					 	,"C",10,0,"@!"})
Aadd(aFieFilter,{"CNPJ","CNPJ"					 	,"C",18,0,"@R 99.999.999/9999-99"})
Aadd(aFieFilter,{"REPASSE","Codigo do repasse" 		,"C",07,0,"@!"})
Aadd(aFieFilter,{"INCLUSAO","Inclusão"			 	,"C",10,0,"@R 9999/99/99"})
Aadd(aFieFilter,{"HORA","Horar"						,"C",08,0,"@!"})
Aadd(aFieFilter,{"SOLICITADO ","Solicitado"			,"C",08,0,"@R 9999/99/99"})
Aadd(aFieFilter,{"DATA_REP","Data de repasse"	   	,"C",08,0,"@R 9999/99/99"})
Aadd(aFieFilter,{"VALOR ","Valor"				   	,"N",10,0,"@E 999,999.99"})
Aadd(aFieFilter,{"COMISSAO ","Valor de comissão"   	,"N",10,0,"@E 999,999.99"})
Aadd(aFieFilter,{"FRETE ","Valor de frete"		   	,"N",06,0,"@E 999,999.99"})
Aadd(aFieFilter,{"DESCONTOS ","Valor de desconto"  	,"N",08,0,"@E 999,999.99"})
Aadd(aFieFilter,{"ARRJ ","Arranjo"				   	,"C",02,0,"@!"})
Aadd(aFieFilter,{"FATURA ","Fatura"					,"C",12,0,"@!"})
Aadd(aFieFilter,{"EMISSAO ","Data de emissao"		,"C",08,0,"@R 9999/99/99"})
Aadd(aFieFilter,{"VENCIMENTO ","Data de Vencimento"	,"C",08,0,"@R 9999/99/99"})
Aadd(aFieFilter,{"PREFIXO ","Prefixo"			   	,"C",03,0,"@!"})
Aadd(aFieFilter,{"SALDO ","Saldo"				   	,"N",12,0,"@E 999,999.99"})
Aadd(aFieFilter,{"BORDERO ","Bordero"			   	,"C",06,0,"@!"})
Aadd(aFieFilter,{"DATA_PGTO ","Data de pagamento"  	,"C",08,0,"@R 9999/99/99"})
Aadd(aFieFilter,{"IDCNAB ","ID CNAB"			   	,"C",10,0,"@!"})
Aadd(aFieFilter,{"BANCO ","Banco"				   	,"C",03,0,"@!"})
Aadd(aFieFilter,{"AGENCIA ","Agencia"  				,"C",05,0,"@!"})
Aadd(aFieFilter,{"CONTA ","Conta"  					,"C",16,0,"@!"})
Aadd(aFieFilter,{"RET_CNAB ","Etapa do pagamento"  	,"C",25,0,"@!"})
Aadd(aFieFilter,{"RET_VALOR ","RET_VALOR"		   	,"N",25,0,"@E 999,999.99"})
Aadd(aFieFilter,{"EFTO_CONT ","Efeito do contrato" 	,"C",25,0,"@!"})
Aadd(aFieFilter,{"VLR_EFT","Valor de efeito"	   	,"N",25,0,"@E 999,999.99"})
Aadd(aFieFilter,{"CNPJ_BENE","CNPJ do beneficiario"	,"C",11,0,"@R 99.999.999/9999-99"})
Aadd(aFieFilter,{"BENEFI ","Nome do beneficiario"  	,"C",25,0,"@!"})


//Montagem do Browse
oBrowse := FWmBrowse():New()
oBrowse:SetAlias("JGT")
oBrowse:SetDescription(cCadastro)
oBrowse:SetSeek(.T.,aSeek)
oBrowse:SetTemporary(.T.)
oBrowse:SetLocate()
oBrowse:SetUseFilter(.T.)
oBrowse:SetDBFFilter(.T.)
oBrowse:SetFilterDefault("") 
oBrowse:SetFieldFilter(aFieFilter)
oBrowse:DisableDetails()
oBrowse:ForceQuitButton()

//Legendas
oBrowse:AddLegend("RET_CNAB='06'", "GREEN")
oBrowse:AddLegend("RET_CNAB='02'", "YELLOW")
oBrowse:AddLegend("RET_CNAB !='06' .AND. RET_CNAB != '02'", "RED")


//Detalhes das colunas que serao exibidas
oBrowse:SetColumns(MM545COL("SELLER","Codigo do seller"   	  ,02,"@!",0,020,0))
oBrowse:SetColumns(MM545COL("NOME","Nome"					  ,02,"@!",1,020,0))
oBrowse:SetColumns(MM545COL("CNPJ","CNPJ"					  ,02,"@R 99.999.999/9999-99",1,020,0))
oBrowse:SetColumns(MM545COL("REPASSE","Codigo do repasse" 	  ,02,"@!",1,020,0))
oBrowse:SetColumns(MM545COL("INCLUSAO","Inclusão"			  ,02,"@R 9999/99/99",1,020,0))
oBrowse:SetColumns(MM545COL("HORA","Horario"				  ,02,"@!",1,020,0))
oBrowse:SetColumns(MM545COL("SOLICITADO ","Solicitado"		  ,02,"@R 9999/99/99",1,020,0))
oBrowse:SetColumns(MM545COL("DATA_REP","Data de repasse"	  ,02,"@R 9999/99/99",1,020,0))
oBrowse:SetColumns(MM545COL("VALOR ","Valor"				  ,02,"@E 999,999.99",2,020,0))
oBrowse:SetColumns(MM545COL("COMISSAO ","Valor de comissão"	  ,02,"@E 999,999.99",2,020,0))
oBrowse:SetColumns(MM545COL("FRETE ","Valor de frete"		  ,02,"@E 999,999.99",2,020,0))
oBrowse:SetColumns(MM545COL("DESCONTOS ","Valor de desconto"  ,02,"@E 999,999.99",2,020,0))
oBrowse:SetColumns(MM545COL("ARRJ ","Arranjo"				  ,02,"@!",1,020,0))
oBrowse:SetColumns(MM545COL("FATURA ","Fatura"				  ,02,"@!",1,020,0))
oBrowse:SetColumns(MM545COL("EMISSAO ","Data de emissao"	  ,02,"@R 9999/99/99",1,020,0))
oBrowse:SetColumns(MM545COL("VENCIMENTO ","Vencimento"		  ,02,"@R 9999/99/99",1,020,0))
oBrowse:SetColumns(MM545COL("PREFIXO ","Prefixo"			  ,02,"@!",1,020,0))
oBrowse:SetColumns(MM545COL("SALDO ","Saldo"				  ,02,"@E 999,999.99",2,020,0))
oBrowse:SetColumns(MM545COL("BORDERO ","Bordero"			  ,02,"@!",1,020,0))
oBrowse:SetColumns(MM545COL("DATA_PGTO ","Data de pagamento"  ,02,"@R 9999/99/99",1,020,0))
oBrowse:SetColumns(MM545COL("IDCNAB ","ID CNAB"				  ,02,"@!",1,020,0))	 
oBrowse:SetColumns(MM545COL("BANCO ","Bancos"				  ,02,"@!",1,020,0))
oBrowse:SetColumns(MM545COL("AGENCIA ","Agencia"  			  ,02,"@!",1,020,0))
oBrowse:SetColumns(MM545COL("CONTA ","Conta"  				  ,02,"@!",1,020,0))
oBrowse:SetColumns(MM545COL("RET_CNAB ","Etapa do pagamento"  ,02,"@!",1,020,0))
oBrowse:SetColumns(MM545COL("RET_VALOR ","RET_VALOR"		  ,02,"@E 999,999.99",2,020,0))
oBrowse:SetColumns(MM545COL("EFTO_CONT ","Efeito do contrato" ,02,"@!",1,020,0))
oBrowse:SetColumns(MM545COL("VLR_EFT","Valor de efeito"		  ,02,"@E 999,999.99",2,020,0))
oBrowse:SetColumns(MM545COL("CNPJ_BENE","CNPJ do beneficiario",02,"@R 99.999.999/9999-99",1,020,0))
oBrowse:SetColumns(MM545COL("BENEFI ","Nome do beneficiario"  ,02,"@!",1,020,0))

oBrowse:Activate()

If !Empty(cArqJGT)
	Ferase(cArqJGT+GetDBExtension())
	Ferase(cArqJGT+OrdBagExt())
	cArqJGT := ""
	JGT->(DbCloseArea())
	delTabTmp('JGT')
	dbClearAll()
EndIf

Return .T.

/*/{Protheus.doc} User Function MM545LBR
	(Função para as legendas da tabela)
	@type  Function
	@author João Gomes	
	@since 31/08/2021
	@version 1
/*/
User Function MM545LBR()
BrwLegenda(cCadastro,"Legenda",{{"BR_VERDE"   ,"Pagamento efetuado"},;
								{"BR_AMARELO" ,"Pagamento em andamento"},;
								{"BR_VERMELHO","Pagamento nao efetuado"}})
Return .T.

/*/{Protheus.doc} User Function MM545LGB
	(Montar Colunas)
	@type  Function
	@author João Gomes	
	@since 06/09/2021
	@version 1
/*/
Static Function MM545COL(cCampo,cTitulo,nArrData,cPicture,nAlign,nSize,nDecimal)
Local aColumn
Local bData := {||}

Default nAlign   := 1
Default nSize    := 20
Default nDecimal := 0
Default nArrData := 0

If nArrData > 0
	bData := &("{||" + cCampo +"}")
EndIf

aColumn := {cTitulo,bData,,cPicture,nAlign,nSize,nDecimal,.F.,{||.T.},.F.,{||.T.},NIL,{||.T.},.F.,.F.,{}}

Return {aColumn}
