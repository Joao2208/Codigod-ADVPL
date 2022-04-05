#INCLUDE "PROTHEUS.CH"
#INCLUDE "RWMAKE.CH"
#INCLUDE "TOPCONN.CH"

/*---------------------------------------------------------------------------+
!                          FICHA TECNICA DO PROGRAMA                         !
+----------------------------------------------------------------------------+
!DADOS DO PROGRAMA 	RELSE1                                                   !
+------------------+---------------------------------------------------------+
!Tipo              ! Relatório		                                         !
+------------------+---------------------------------------------------------+
!Modulo            ! SIGAFIN			                                     !
+------------------+---------------------------------------------------------+
!Descricao         ! Relatório Conciliação MktPlace							 !
!                  ! 						     							 !
+------------------+---------------------------------------------------------+
!Autor             ! Thiago Leonardo de Almeida                              !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 22/07/2016                                          	 !
+------------------+---------------------------------------------------------+
!                               ATUALIZACOES                                 !
+-------------------------------------------+-----------+-----------+--------+
!   Descricao detalhada da atualizacao      !  Nome do  ! Analista  !Data da !
!                                           !Solicitante! Respons.  !Atualiz.!
+-------------------------------------------+-----------+-----------+--------+
!		                                    !    	    !           !        !
+-------------------------------------------+-----------+-----------+-------*/

user function RFIN006()
local oReport
local cPerg  := 'RFIN006'
local cAlias := getNextAlias()

criaSx1(cPerg)
Pergunte(cPerg, .F.)

oReport := reportDef(cAlias, cPerg)

oReport:printDialog()
return

//+-----------------------------------------------------------------------------------------------+
//! Função para criação da estrutura do relatório.                                                !
//+-----------------------------------------------------------------------------------------------+
Static Function ReportDef(cAlias,cPerg)

local cTitle  := "Relatório Conciliação MktPlace"
local cHelp   := "Permite a impressão do relatório Conciliação MktPlace"
Local aOrdem  := {"Padrão"}
local oReport
local oSection1
local oSection2
local oBreak1

oReport	:= TReport():New('RFIN006',cTitle,cPerg,{|oReport|ReportPrint(oReport,cAlias)},cHelp)
oReport:SetLANDSCAPE() //PAISAGEM
//oReport:SetPortrait() //RETRATO

oSection1 := TRSection():New(oReport,"SE1",{"SE1"},aOrdem)
oSection2:= TRSection():New(oSection1,"Conciliação MktPlace",{"SE1"})
oSection2:SetLeftMargin(2)  //Define a margem à esquerda
TRCell():New(oSection2,"E1_CLIENTE", "QSE1", "Cliente",,TamSX3("E1_CLIENTE")[1]+1)
TRCell():New(oSection2,"E1_LOJA", "QSE1", "Loja",,TamSX3("E1_LOJA")[1]+1)
TRCell():New(oSection2,"E1_NOMCLI", "QSE1", "Nome do Cliente",,TamSX3("E1_NOMCLI")[1]+1)
TRCell():New(oSection2,"E1_PREFIXO", "QSE1", "Prefixo",,TamSX3("E1_PREFIXO")[1]+1)
TRCell():New(oSection2,"E1_NUM", "QSE1", "Número",,TamSX3("E1_NUM")[1]+1)
TRCell():New(oSection2,"E1_TIPO", "QSE1", "Tipo",,TamSX3("E1_TIPO")[1]+1)
TRCell():New(oSection2,"E1_NATUREZ", "QSE1", "Natureza",,TamSX3("E1_NATUREZ")[1]+1)
TRCell():New(oSection2,"E1_EMISSAO", "QSE1", "DT.Emissão",,TamSX3("E1_EMISSAO")[1]+1)
TRCell():New(oSection2,"E1_FOMRPAG", "QSE1", "Forma Pgto",,TamSX3("E1_FOMRPAG")[1]+1)
TRCell():New(oSection2,"E1_VALOR", "QSE1", "Valor Original",,TamSX3("E1_VALOR")[1]+1)
TRCell():New(oSection2,"E1_SALDO", "QSE1", "Valor Atual",,TamSX3("E1_SALDO")[1]+1)
TRCell():New(oSection2,"E1_VENCTO", "QSE1", "Vencimento",,TamSX3("E1_VENCTO")[1]+1)
TRCell():New(oSection2,"E1_VENCREA", "QSE1", "Vencimento Real",,TamSX3("E1_VENCREA")[1]+1)
TRCell():New(oSection2,"C5_MMPEDMP", "QSE1", "Ped.MktPlace",,TamSX3("C5_MMPEDMP")[1]+1)
TRCell():New(oSection2,"C5_LOJACOM", "QSE1", "Loja MktPlace",,TamSX3("C5_LOJACOM")[1]+1)

Return(oReport)

Static Function ReportPrint(oReport,cAlias)

local oSection1 := oReport:Section(1)
local oSection2 := oReport:Section(1):Section(1)

cQry := " SELECT E1_CLIENTE,E1_LOJA,E1_NOMCLI,E1_PREFIXO,E1_NUM,E1_TIPO,E1_NATUREZ,E1_EMISSAO,E1_FOMRPAG,E1_VALOR,E1_SALDO,E1_VENCTO,E1_VENCREA,E1_PEDIDO "
IF MV_PAR07 <> 5
	cQry += ",C5_MMPEDMP, C5_LOJACOM"
ENDIF
cQry += " FROM "+retSqlName("SE1")+" SE1 "
IF MV_PAR07 <> 5
	cQry += " INNER JOIN SC5010 SC5 ON C5_FILIAL = '"+xFilial("SC5")+"' AND C5_NUM = E1_PEDIDO AND C5_CLIENTE = E1_CLIENTE AND E1_LOJA = C5_LOJACLI AND SC5.D_E_L_E_T_ <> '*' "
ENDIF
cQry += " WHERE E1_FILIAL BETWEEN  '"+MV_PAR01+"' AND '"+MV_PAR02+"' "
cQry += " AND E1_EMISSAO BETWEEN  '"+DTOS(MV_PAR03)+"' AND '"+DTOS(MV_PAR04)+"' "
cQry += " AND SE1.D_E_L_E_T_ <> '*' "
cQry += " AND E1_SALDO > '0' "
cQry += " AND E1_VENCREA BETWEEN  '"+DTOS(MV_PAR05)+"' AND '"+DTOS(MV_PAR06)+"' "
IF MV_PAR07 <> 5
	IF MV_PAR07 == 1
		cQry += " AND C5_LOJACOM IN ('CB','EX','PF') " // CNOVA
	ELSEIF MV_PAR07 == 2
		cQry += " AND C5_LOJACOM IN ('LO','SH','SU') " // B2W
	ELSEIF MV_PAR07 == 3
		cQry += " AND C5_LOJACOM = 'ML' " //MercadoLivre
	ELSEIF MV_PAR07 == 4
		cQry += " AND C5_LOJACOM = 'VM' " //WallMart
	ENDIF
ENDIF
cQry += " ORDER BY E1_NUM "

IF Select("QSE1") <> 0
	DbSelectArea("QSE1")
	QSE1->(DbCloseArea())
ENDIF

TCQUERY cQry NEW ALIAS "QSE1"

oSection2:Init()
oReport:IncMeter()

While QSE1->(!Eof())
	
	IF MV_PAR07 <> 5
		cMMpedmp := QSE1->C5_MMPEDMP
		cLojacom := IIF(QSE1->C5_LOJACOM $"CB/EX/PF","CNOVA",IIF(QSE1->C5_LOJACOM $"LO/SH/SU","B2W",IIF(QSE1->C5_LOJACOM $"ML","MercadoLivre",;
		IIF(QSE1->C5_LOJACOM $"WM","WalMart",""))))
	ELSE
		cMMpedmp := Posicione("SC5",1,xFilial("SC5")+QSE1->E1_PEDIDO,"C5_MMPEDMP")
		cLojacom := IIF(SC5->C5_LOJACOM $"CB/EX/PF","CNOVA",IIF(SC5->C5_LOJACOM $"LO/SH/SU","B2W",IIF(SC5->C5_LOJACOM $"ML","MercadoLivre",;
					IIF(SC5->C5_LOJACOM $"WM","WalMart",""))))
		IF EMPTY(cMMpedmp) .AND. QSE1->E1_TIPO == 'NCC'
			
			cQd1 := " SELECT D1_DOC, D1_SERIE, D1_NFORI, D1_SERIORI, D1_ITEMORI,D2_DOC, D2_SERIE,C5_NUM, C5_MMPEDMP, C5_LOJACOM "
			cQd1 += " FROM "+retSqlName("SD1")+" SD1"
			cQd1 += " INNER JOIN "+retSqlName("SD2")+" SD2 ON D2_DOC = D1_NFORI AND D2_SERIE = D1_SERIORI AND D2_ITEM = D1_ITEMORI AND SD2.D_E_L_E_T_ <> '*' "
			cQd1 += " INNER JOIN "+retSqlName("SC5")+" SC5 ON C5_FILIAL = '"+xFilial("SC5")+"' AND C5_NUM = D2_PEDIDO AND C5_CLIENTE = D2_CLIENTE AND D2_LOJA = C5_LOJACLI AND SC5.D_E_L_E_T_ <> '*' "
			cQd1 += " WHERE D1_DOC = '"+QSE1->E1_NUM+"' "
			cQd1 += " AND D1_EMISSAO = '"+QSE1->E1_EMISSAO+"' "
			cQd1 += " AND D1_TIPO = 'D' " 
			cQd1 += " AND SD1.D_E_L_E_T_ <> '*' "
			
			IF Select("QSD1") <> 0
 				DbSelectArea("QSD1")
				QSD1->(DbCloseArea())
			ENDIF

			TCQUERY cQd1 NEW ALIAS "QSD1"
			
			cMMpedmp := QSD1->C5_MMPEDMP
			cLojacom := IIF(QSD1->C5_LOJACOM $"CB/EX/PF","CNOVA",IIF(QSD1->C5_LOJACOM $"LO/SH/SU","B2W",IIF(QSD1->C5_LOJACOM $"ML","MercadoLivre",;
						IIF(QSD1->C5_LOJACOM $"WM","WalMart",""))))
		ENDIF
	ENDIF
	
	oSection2:Cell("E1_CLIENTE"):SetValue(QSE1->E1_CLIENTE)
	oSection2:Cell("E1_LOJA")	:SetValue(QSE1->E1_LOJA)
	oSection2:Cell("E1_NOMCLI")	:SetValue(QSE1->E1_NOMCLI)
	oSection2:Cell("E1_PREFIXO"):SetValue(QSE1->E1_PREFIXO)
	oSection2:Cell("E1_NUM") 	:SetValue(QSE1->E1_NUM)
	oSection2:Cell("E1_TIPO")	:SetValue(QSE1->E1_TIPO)
	oSection2:Cell("E1_NATUREZ"):SetValue(QSE1->E1_NATUREZ)
	oSection2:Cell("E1_EMISSAO"):SetValue(STOD(QSE1->E1_EMISSAO))
	oSection2:Cell("E1_FOMRPAG"):SetValue(ALLTRIM(QSE1->E1_FOMRPAG))
	oSection2:Cell("E1_VALOR")	:SetValue(QSE1->E1_VALOR)
	oSection2:Cell("E1_SALDO")	:SetValue(QSE1->E1_SALDO)
	oSection2:Cell("E1_VENCTO")	:SetValue(STOD(QSE1->E1_VENCTO))
	oSection2:Cell("E1_VENCREA"):SetValue(STOD(QSE1->E1_VENCREA))
	oSection2:Cell("C5_MMPEDMP"):SetValue(cMMpedmp)
	oSection2:Cell("C5_LOJACOM"):SetValue(cLojacom)
	
	oSection2:Printline()
	QSE1->(dbSkip())
ENDDO

oSection1:Finish()

return

//+-----------------------------------------------------------------------------------------------+
//! Função para criação das perguntas                                                             !
//+-----------------------------------------------------------------------------------------------+
static function criaSX1(cPerg)

putSx1(cPerg, '01', 'Filial de?'          , '', '', 'mv_ch1', 'C', TAMSX3("E1_FILIAL")[1], 0, 0, 'G', '', 'SM0', '', '', 'mv_par01')
putSx1(cPerg, '02', 'Filial até?'         , '', '', 'mv_ch2', 'C', TAMSX3("E1_FILIAL")[1], 0, 0, 'G', '', 'SM0', '', '', 'mv_par02')
putSx1(cPerg, '03', 'Emissão de?'         , '', '', 'mv_ch3', 'D', TAMSX3("E1_EMISSAO")[1], 0, 0, 'G', '', '', '', '', 'mv_par03')
putSx1(cPerg, '04', 'Emissão até?'         , '', '', 'mv_ch4', 'D', TAMSX3("E1_EMISSAO")[1], 0, 0, 'G', '', '', '', '', 'mv_par04')
putSx1(cPerg, '05', 'Vencimento de?'         , '', '', 'mv_ch5', 'D', TAMSX3("E1_VENCREA")[1], 0, 0, 'G', '', '', '', '', 'mv_par05')
putSx1(cPerg, '06', 'Vencimento até?'         , '', '', 'mv_ch6', 'D', TAMSX3("E1_VENCREA")[1], 0, 0, 'G', '', '', '', '', 'mv_par06')
PutSx1(cPerg, '07', 'MktPlace?'		,'','',"mv_ch7","N",1,0,0,"C","","","","","mv_par07","CNOVA","","","","B2W","","","MercadoLivre","","","WalMart","","","Não Seleciona","","","", "","", "")

return
