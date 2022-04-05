#INCLUDE "PROTHEUS.CH"
#INCLUDE "RWMAKE.CH"
#INCLUDE "TOPCONN.CH"

/*/{Protheus.doc} User Function MM571 
    (Função para desenvolver relatorio de repasse de seller)
    @type  Function
    @author user
    @since 17/03/2022
    @version 1.0
/*/

user function MM571()
	local oReport
	local cPerg  := 'MM571'
	local cAlias := getNextAlias()

	oReport := MM571Rep(cAlias, cPerg)

	oReport:printDialog()
Return()


/*/{Protheus.doc} User Function MM571Rep
	(Função para criação da estrutura do relatório. )
	@type  Function
	@author user
	@since 17/03/2022
	@version 1.0
/*/
Static Function MM571Rep(cAlias,cPerg)

	local cTitle  := "Repasse de Relatorio de Seller"
	local cHelp   := "Permite a impressão do relatório de Repasse de Seller"
	Local aOrdem  := {"Padrão"}
	local oReport
	local oSection1
	local oSection2

	//função que cria a tela com as perguntas e todas as funçoes
	oReport	:= TReport():New('MM571',cTitle,cPerg,{|oReport|MM571Print(oReport,cAlias)},cHelp)
	oReport:SetLANDSCAPE() //PAISAGEM
	oSection1 := TRSection():New(oReport,"Relatorio",{"Z11","Z1E","SA2"},aOrdem)
	oSection2:= TRSection():New(oSection1,"Relatorio Sellers",{"Z11","Z1E","SA2"})
	oSection2:SetLeftMargin(2)  //Define a margem à esquerda
	TRCell():New(oSection2,"COD_REPASSE", 	"QSE1", "Codigo_Repasse",,10,,,"LEFT",.t.)
	TRCell():New(oSection2,"COD_FORNEC", 	"QSE1", "Codigo_Fornecedor",,TamSX3("A2_COD")[1]+1,,,"LEFT",.t.)
	TRCell():New(oSection2,"RAZAO_SOCIAL", 	"QSE1", "Razão_Social",,TamSX3("A2_NOME")[1]+1,,,"LEFT",.t.)
	TRCell():New(oSection2,"NOME_FORNECEDOR", "QSE1", "Nome_Fornecedor",,TamSX3("A2_NREDUZ")[1]+1,,,"LEFT",.t.)
	TRCell():New(oSection2,"CNPJ", "QSE1", 	"CNPJ",,TamSX3("A2_CGC")[1]+3,,,"LEFT",.t.)
	TRCell():New(oSection2,"VALOR_REPASSE", "QSE1", "Valor_Repasse",,TamSX3("Z1E_VLREPA")[1]+1,,,"LEFT",.t.)
	TRCell():New(oSection2,"VALOR_ARRANJO", "QSE1", "Valor_Arranjo",,TamSX3("Z11_VLREPA")[1]+1,,,"LEFT",.t.)
	TRCell():New(oSection2,"Z11_PAGO", "QSE1", "Pago?",,TamSX3("Z11_PAGO")[1]+1,,,"LEFT",.t.)
	//TRCell():New(oSection2,"Z11_STATUS", "QSE1", "Status",,TamSX3("Z11_STATUS")[1]+1,,,"LEFT",.t.)
	TRCell():New(oSection2,"Z11_IDCNAB", "QSE1", "IDCNAB",,TamSX3("Z11_IDCNAB")[1]+1,,,"LEFT",.t.)
	TRCell():New(oSection2,"DATA_PAGAMENTO", "QSE1", "Data_Pagamento",,TamSX3("Z11_PAGDIA")[1]+3,,,"LEFT",.t.)
	TRCell():New(oSection2,"VALOR_PAGO", "QSE1", "Valor_Pago",,TamSX3("Z11_VLRPAG")[1]+1,,,"LEFT",.t.)
	TRCell():New(oSection2,"DATA_SOLICIT", "QSE1", "Data_Solicitação",,TamSX3("Z1E_DTSORE")[1]+3,,,"LEFT",.t.)
	TRCell():New(oSection2,"VENCIMENTO", "QSE1", "Data_Vencimento",,TamSX3("Z1E_DTREPA")[1]+1,,,"LEFT",.t.)
	TRCell():New(oSection2,"Z11_BANCPG", "QSE1", "BANCO",,TamSX3("Z11_BANCPG")[1]+2,,,"LEFT",.t.)
	TRCell():New(oSection2,"Z11_DSCBAN", "QSE1", "Bandeira",,TamSX3("Z11_DSCBAN")[1]+1,,,"LEFT",.t.)
	TRCell():New(oSection2,"Z11_TIPOPG", "QSE1", "Tipo pagamento",,TamSX3("Z11_TIPOPG")[1]+1,,,"LEFT",.t.)
	TRCell():New(oSection2,"LINHA_BANCO", "QSE1", "Linha do banco",,TamSX3("Z11_LINHA")[1]+1,,,"LEFT",.t.)
	//TRCell():New(oSection2,"ARQUIVO_PGTO", "QSE1", "Arquivo",,TamSX3("Z11_ARQPGT")[1]+1,,,"LEFT",.t.)

Return(oReport)

Static Function MM571Print(oReport,cAlias)

	local oSection1 := oReport:Section(1)
	local oSection2 := oReport:Section(1):Section(1)
	Local QSE1,cQry

	//caso o usuario não escolha uma data o programa altomaticamente coloca a do dia
	if EMPTY(mv_par01) .or. EMPTY(mv_par02)
		MsgAlert("Voce não escolheu uma data especifica, entao o programa ira gerar um arquivo com as datas de hoje e em seguida fechar", "Alerta")
		mv_par01 := DATE()
		mv_par02 := DATE()
		return()
	ENDIF
	/*
	if EMPTY(mv_par02)
		MsgAlert("Voce não escolheu uma data especifica, por isso o programa ir fechar", "Alerta")
		mv_par02 := DATE()
		return()
	endif
	*/
	//QUery principal que traz os dados para o relatorio
	cQry := "SELECT Z11_CTRLRE COD_REPASSE,A2_COD COD_FORNEC, A2_NOME RAZAO_SOCIAL, A2_NREDUZ NOME_FORNECEDOR,A2_CGC CNPJ,"
	cQry += "Z1E_VLREPA VALOR_REPASSE,Z11_VLREPA VALOR_ARRANJO,Z11_PAGO,Z11_IDCNAB,"
	cQry += "Z11_PAGDIA DATA_PAGAMENTO,Z11_VLRPAG VALOR_PAGO,Z1E_DTSORE DATA_SOLICIT,Z1E_DTREPA VENCIMENTO, Z11_BANCPG, Z11_DSCBAN,Z11_TIPOPG,ISNULL(CAST(CAST(Z11_LINHA AS VARBINARY(8000)) AS VARCHAR(8000)),'') AS LINHA_BANCO "
	cQry += "FROM  " +  RetSqlName("Z11") + " Z11(NOLOCK)"+CRLF
	cQry += "INNER JOIN " +  RetSqlName("Z1E") + " Z1E(NOLOCK) ON Z1E_FILIAL = Z11_FILIAL AND Z1E_CTRLRE = Z11_CTRLRE AND Z1E.D_E_L_E_T_ <> '*'"
	cQry += "INNER JOIN " +  RetSqlName("SA2") + " A2 (NOLOCK) ON A2_FILIAL = Z1E_FILIAL AND A2_MMSELLE = Z1E_SELLER AND A2.D_E_L_E_T_ <> '*'"
	cQry += "WHERE Z11_FILIAL = '' AND Z1E_DTSORE BETWEEN '"+ DtoS(mv_par01) +"' AND '"+ DtoS(mv_par02) + "' AND Z11_BANDEI <> 'FT' AND Z11_VLREPA > 0 AND Z11.D_E_L_E_T_ <> '*'"
	if EMPTY(mv_par03) .OR. mv_par03 == 3
		cQry += "ORDER BY Z11_CTRLRE,Z11_PARCEL"
	else
		if mv_par03 == 1
			cQry += "AND Z11_BANCPG = 'ITAU' "
			cQry += "ORDER BY Z11_CTRLRE,Z11_PARCEL"
		elseif mv_par03 == 2 
			cQry += "AND Z11_BANCPG = 'CIP-SANTANDER' "
			cQry += "ORDER BY Z11_CTRLRE,Z11_PARCEL"
		endif
	endif

	QSE1 := GetNextAlias()

	TCQUERY cQry NEW ALIAS &QSE1

	oSection2:Init()
	oReport:IncMeter()

	//Traz os resultados da obtidos a partir da query
	While !(QSE1)->(Eof())
	
		oSection2:Cell("COD_REPASSE"):SetValue((QSE1)->COD_REPASSE)
		oSection2:Cell("COD_FORNEC"):SetValue((QSE1)->COD_FORNECEDOR)
		oSection2:Cell("RAZAO_SOCIAL"):SetValue((QSE1)->RAZAO_SOCIAL)
		oSection2:Cell("NOME_FORNECEDOR"):SetValue((QSE1)->NOME_FORNECEDOR)
		oSection2:Cell("CNPJ"):SetValue((QSE1)->CNPJ)
		oSection2:Cell("VALOR_REPASSE"):SetValue((QSE1)->VALOR_REPASSE)
		oSection2:Cell("VALOR_ARRANJO"):SetValue((QSE1)->VALOR_ARRANJO)       
		oSection2:Cell("Z11_PAGO"):SetValue((QSE1)->Z11_PAGO)
		//oSection2:Cell("Z11_STATUS"):SetValue((QSE1)->Z11_STATUS)
		oSection2:Cell("Z11_IDCNAB"):SetValue((QSE1)->Z11_IDCNAB)
		oSection2:Cell("DATA_PAGAMENTO"):SetValue((QSE1)->DATA_PAGAMENTO)
		oSection2:Cell("VALOR_PAGO"):SetValue((QSE1)->VALOR_PAGO)
		oSection2:Cell("DATA_SOLICIT"):SetValue((QSE1)->DATA_SOLICIT)
		oSection2:Cell("VENCIMENTO"):SetValue((QSE1)->VENCIMENTO)
		oSection2:Cell("Z11_BANCPG"):SetValue((QSE1)->Z11_BANCPG)
		oSection2:Cell("Z11_DSCBAN"):SetValue((QSE1)->Z11_DSCBAN)
		oSection2:Cell("Z11_TIPOPG"):SetValue((QSE1)->Z11_TIPOPG)
		oSection2:Cell("LINHA_BANCO"):SetValue((QSE1)->LINHA_BANCO)

		oSection2:Printline()
		(QSE1)->(dbSkip())

	ENDDO
	(QSE1)->(DbCloseArea())
	oSection1:Finish()

return

