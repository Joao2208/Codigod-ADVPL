#include 'totvs.ch'
#include 'topconn.ch'
#INCLUDE "MATR110.CH"
#include "rptdef.ch"

class TPurchaseOrder
	
	data id_insert
	data id
	data codigo_sku
	data filial_madeira
	data transportadora_filial
	data transportadora_entrega
	data data_criacao
	data data_aprovacao
	data fornecedor
	data numero_ordem_compra
	data expresso
	data itens
	data lojista_retira
	data telefone_filial_madeira
	data telefone_fornecedor
	data desconto
	data condicao_pagamento
	data valor_total
	data despesa
	data valor_seguro
	data descricao_pagamento
	data nTotIcms
	
	// --------------- DECLARACAO DE METODOS ---------------
	method new(oObj) CONSTRUCTOR
	method get(cNumOC)
	method getByNF(cFil, cNumDoc, cNumSer)
	
endclass

//-----------------------------------------------------------------
method new(oObjDoc) class TPurchaseOrder
	
	default oObjDoc := nil

	::id_insert := ''
	::id := ''
	::codigo_sku := ''
	::filial_madeira := ''
	::transportadora_filial := ''
	::transportadora_entrega := ''
	::data_criacao := ''
	::data_aprovacao := ''
	::fornecedor := ''
	::numero_ordem_compra := ''
	::expresso := 0
	::lojista_retira := ''
	::telefone_filial_madeira := ''
	::telefone_fornecedor := ''
	::desconto := ''
	::condicao_pagamento := ''
	::valor_total := ''
	::despesa := ''
	::valor_seguro := ''
	::descricao_pagamento := ''
	::nTotIcms := ''
	
	::itens := {}
	
	if oObjDoc != nil

		::id := IIF(ValType(oObjDoc:id) != nil, oObjDoc:id, "")
		::codigo_sku := IIF(ValType(oObjDoc:codigo_sku) != nil, oObjDoc:codigo_sku, "")
		::filial_madeira := IIF(ValType(oObjDoc:filial_madeira) != nil, oObjDoc:filial_madeira, "")
		::transportadora_filial := IIF(ValType(oObjDoc:transportadora_filial) != nil, oObjDoc:transportadora_filial, "")
		::transportadora_entrega := IIF(ValType(oObjDoc:transportadora_entrega) != nil, oObjDoc:transportadora_entrega, "")
		::data_criacao := IIF(ValType(oObjDoc:data_criacao) != nil, oObjDoc:data_criacao, "")
		::data_aprovacao := IIF(ValType(oObjDoc:data_aprovacao) != nil, oObjDoc:data_aprovacao, "")
		::fornecedor := IIF(ValType(oObjDoc:fornecedor) != nil, oObjDoc:fornecedor, "")
		::numero_ordem_compra := IIF(ValType(oObjDoc:numero_ordem_compra) != nil, oObjDoc:numero_ordem_compra, "")
		::expresso := IIF(ValType(oObjDoc:expresso) != nil, oObjDoc:expresso, 0)
		::lojista_retira := IIF(ValType(oObjDoc:lojista_retira) != nil, oObjDoc:lojista_retira, "")
		::telefone_filial_madeira := IIF(ValType(oObjDoc:telefone_filial_madeira) != nil, oObjDoc:telefone_filial_madeira, "")
		::telefone_fornecedor := IIF(ValType(oObjDoc:telefone_fornecedor) != nil, oObjDoc:telefone_fornecedor, "")
		::desconto := IIF(ValType(oObjDoc:desconto) != nil, oObjDoc:desconto, "")
		::condicao_pagamento := IIF(ValType(oObjDoc:condicao_pagamento) != nil, oObjDoc:condicao_pagamento, "")
		::valor_total := IIF(ValType(oObjDoc:valor_total) != nil, oObjDoc:valor_total, "")
		::despesa := IIF(ValType(oObjDoc:despesa) != nil, oObjDoc:despesa, "")
		::valor_seguro := IIF(ValType(oObjDoc:valor_seguro) != nil, oObjDoc:valor_seguro, "")
		::descricao_pagamento := IIF(ValType(oObjDoc:descricao_pagamento) != nil, oObjDoc:descricao_pagamento, "")
		::nTotIcms := IIF(ValType(oObjDoc:nTotIcms) != nil, oObjDoc:nTotIcms, "")
		
		::itens := IIF(ValType(oObjDoc:itens) != nil, oObjDoc:itens, {})
	endif
	
return self

// Busca pedido e cria objeto
method get(cNumOC) class TPurchaseOrder
	local cQry
	local cAls := GetNextAlias()
	Local cC6DEL := ""	//Alterado por Daniel Bueno - 08.02.2021
	Local cFiltro := ""
	//Local aTotalIcms := {}
	
	::new()
	MaFisEnd()
	GetItensPC(cNumOC,,cFiltro)
	
	//Alteracoes na query: adicionado NOLOCK nas tabelas e caso a rotina MM425THD esteja na pilha, desconsidera o D_E_L_E_T_ da SC6 para correto processamento no Nexus - Daniel Bueno - 09.02.21
	if Empty(cNumOC)
		xRet := nil
	else
		cQry := " SELECT " +;
				" SC7.R_E_C_N_O_ C7RECNO, SC7.D_E_L_E_T_ C7DELET, C7_FILIAL, C7_EMISSAO, C7_NUM, C7_ITEM, C7_PRODUTO, C7_FORNECE, C7_MMTRANS, " +;
				" C7_MMITV, C7_QUANT, C7_PRECO, C7_TOTAL, C7_QUJE, C7_UM, C7_IPI, C7_OPERS, C7_CST, C7_TIPAT, C7_MMLJRET, C7_MMNUMPV, C7_MMREDES, C7_LOCAL," +;
				" C7_NUMSC, C7_QTSEGUM, C7_VLDESC, C7_COND, C7_BASIMP5, C7_OBS, C7_VALIPI, C7_DESPESA, C7_SEGURO, "+;
				"	C5_EMISSAO, C5_EXPRESS, " +;
				"	C6_NUM, C6_QTDVEN, C6_DATAENT, C6_PZTRANS, C6_ENTFORN, C6_LOCAL, " +;
				"	A5_CODPRF, A5_MMDEFOR, A5_XCONV, " +;
				"	A2_NFPRZ, A2_DDD, A2_TEL, " +;
				"	ean, " +;
				"	B1_MMDESC, B1_AGRUPA, " +;
				"	E4_DESCRI " +;
				" FROM " +;
				" SC7010 SC7 (NOLOCK) " +;
				" LEFT JOIN SE4010 SE4 (NOLOCK) ON SE4.E4_FILIAL = '      ' AND SE4.E4_CODIGO = SC7.C7_COND" +;
				" LEFT JOIN SC1010 SC1 (NOLOCK) ON SC1.C1_FILIAL = SC7.C7_FILIAL AND SC1.C1_NUM = SC7.C7_NUMSC AND SC1.C1_ITEM = SC7.C7_ITEMSC AND SC1.C1_PEDIDO = SC7.C7_NUM AND SC1.D_E_L_E_T_ = '' " +;
				" INNER JOIN SB1010 SB1 (NOLOCK) ON SB1.B1_FILIAL = '"+xFilial("SB1")+"' AND SB1.B1_COD = SC7.C7_PRODUTO " +;
				" INNER JOIN SA2010 SA2 (NOLOCK) ON SA2.A2_FILIAL = '"+xFilial("SA2")+"' AND SA2.A2_COD = SC7.C7_FORNECE AND SA2.A2_LOJA = SC7.C7_LOJA " +;
				" LEFT JOIN SA5010 SA5 (NOLOCK) ON SA5.A5_FILIAL = '"+xFilial("SA5")+"' AND SA5.A5_FORNECE = SC7.C7_FORNECE AND SA5.A5_LOJA = SC7.C7_LOJA AND SA5.A5_PRODUTO = SC7.C7_PRODUTO AND SA5.D_E_L_E_T_ = '' " +;
				" AND A5_MMVIGEN = (SELECT TOP 1  A5_MMVIGEN  " +;
				"                     FROM SA5010 SA5B (NOLOCK)  " +;
				"					  WHERE SA5B.A5_FILIAL = SA5.A5_FILIAL   " +;
				"					  AND SA5B.A5_FORNECE = SA5.A5_FORNECE " +;
				"					  AND SA5B.A5_LOJA = SA5.A5_LOJA " +;
				"					  AND SA5B.A5_PRODUTO = SA5.A5_PRODUTO " +;
				"					  AND SA5B.D_E_L_E_T_ != '*' " +;
				"					  AND LEFT(SA5B.A5_MMVIGEN,8) <= C7_EMISSAO " +;
				"					  ORDER BY SA5B.A5_MMVIGEN DESC) 	 " +;			
				" LEFT JOIN SC6010 SC6 (NOLOCK) ON SC6.C6_FILIAL = '"+xFilial("SC6")+"' AND SC6.C6_NUM = SC7.C7_MMITV AND SC6.C6_ITEM = RIGHT(RTRIM(SC7.C7_MMITPV),2) AND SC6.C6_PRODUTO = SC7.C7_PRODUTO" +;
				Iif(IsInCallStack('U_MM425THD') .And. IsInCallStack('fIntegra') .And. AllTrim(cEvenPO) == 'PURCHASE_ORDER_CANCELED_PROTHEUS', ""," AND SC6.D_E_L_E_T_ = '' ") +;
				" LEFT JOIN SC5010 SC5 (NOLOCK) ON SC5.C5_FILIAL = SC6.C6_FILIAL AND SC5.C5_NUM = SC6.C6_NUM " +;
				" LEFT JOIN produtos prd ON prd.codigo = SC7.C7_PRODUTO " +;
				" WHERE " +;
				" C7_NUM = '"+cNumOC+"' "
		TCQuery cQry new alias &cAls
		if (!Empty((cAls)->C7_MMNUMPV) .and. !Empty((cAls)->C6_NUM)) .Or. (Empty((cAls)->C7_MMNUMPV) .and. Empty((cAls)->C6_NUM))
			ConOut("Thread " + cValToChar(ThreadID()) + " | TPurchaseOrder - Vinculou SC6, OC: " + (cAls)->C7_NUM + " PV: " + (cAls)->C7_MMNUMPV)
			U_fConout(ProcName(0), "TPurchaseOrder - OK -> OC: " + (cAls)->C7_NUM + " PV: " + (cAls)->C7_MMNUMPV + " C6: " + (cAls)->C6_NUM + " Query: " + cQry, .t.)	//Alterado por Daniel Bueno - 08.02.2021

			if !(cAls)->(eof())
				::id_insert := (cAls)->C7RECNO
				::id := AllTrim((cAls)->C7_NUM)
				::codigo_sku := AllTrim((cAls)->C7_FORNECE)
				::filial_madeira := Right((cAls)->C7_FILIAL, 2)
				::transportadora_filial := AllTrim((cAls)->C7_MMTRANS)
				::transportadora_entrega := AllTrim((cAls)->C7_MMREDES)
				::data_criacao := (cAls)->C7_EMISSAO
				// Se nao houver um PV vinculado, assume a data de aprovacao como emissao da OC
				::data_aprovacao := IIF(Empty((cAls)->C5_EMISSAO) .and. Empty((cAls)->C7_MMITV), (cAls)->C7_EMISSAO, AllTrim((cAls)->C5_EMISSAO))
				::fornecedor := AllTrim((cAls)->C7_FORNECE)
				::numero_ordem_compra := AllTrim((cAls)->C7_NUM)
				::expresso := IIF((cAls)->C5_EXPRESS == 'S', 1, 0)
				::lojista_retira := (cAls)->C7_MMLJRET 
				::telefone_filial_madeira := FWSM0Util():GetSM0Data(SubStr((cAls)->C7_FILIAL, 1, 2), (cAls)->C7_FILIAL)[16][2]
				::telefone_fornecedor := "(" + AllTrim((cAls)->A2_DDD) + ") " + AllTrim((cAls)->A2_TEL)
				::desconto := (cAls)->C7_VLDESC
				::condicao_pagamento := AllTrim((cAls)->C7_COND)
				::descricao_pagamento := AllTrim((cAls)->E4_DESCRI) 
				::valor_total := (cAls)->C7_BASIMP5
				::despesa := (cAls)->C7_DESPESA
				::valor_seguro := (cAls)->C7_SEGURO
				::nTotIcms   := MaFisRet(,'NF_VALICM')


				while !(cAls)->(eof())
				
					oIt := TPurchaseOrderItem():new()
					oIt:id_insert := (cAls)->C7RECNO
					oIt:deletado := (cAls)->C7DELET
					oIt:codigo := AllTrim((cAls)->C7_PRODUTO)
					oIt:codigo_produto_fornecedor := AllTrim((cAls)->A5_CODPRF)
					oIt:numero_pedido_venda := AllTrim((cAls)->C7_MMITV)
					oIt:quantidade_pedido_venda := (cAls)->C6_QTDVEN
					oIt:item := (cAls)->C7_ITEM
					oIt:idfk_pedido_compra := AllTrim((cAls)->C7_NUM)
					oIt:descricao := AllTrim((cAls)->B1_MMDESC)
					oIt:quantidade := (cAls)->C7_QUANT
					oIt:preco_unitario := (cAls)->C7_PRECO
					oIt:quantidade_confirmada := (cAls)->C7_QUJE
					oIt:data_estimada_entrega := AllTrim((cAls)->C6_DATAENT)
					oIt:prazo_transportadora := Val((cAls)->C6_PZTRANS)
					oIt:prazo_entrega := IIF(Val((cAls)->C6_ENTFORN) > 0, Val((cAls)->C6_ENTFORN), (cAls)->A5_MMDEFOR) 
					oIt:prazo_nota := (cAls)->A2_NFPRZ
					oIt:unidade_medida := (cAls)->C7_UM
					oIt:preco_total := (cAls)->C7_TOTAL
					oIt:ipi := (cAls)->C7_IPI
					oIt:unidade_conversao := (cAls)->A5_XCONV
					oIt:ean := AllTrim((cAls)->ean)
					oIt:operacao := AllTrim((cAls)->C7_OPERS)
					oIt:cst := AllTrim((cAls)->C7_CST)
					oIt:tipo_assistencia := (cAls)->C7_TIPAT
					oIt:agrupa := (cAls)->B1_AGRUPA
					oIt:armazem := (cAls)->C7_LOCAL
					oIt:valor_ipi := (cAls)->C7_VALIPI
					oIt:numero_sc := (cAls)->C7_NUMSC
					oIt:qtsegum := (cAls)->C7_QTSEGUM
					oIt:valor_desconto := (cAls)->C7_VLDESC
					oIt:obs_item := AllTrim((cAls)->C7_OBS)

					AADD(::itens, oIt)
					(cAls)->(dbSkip())
				enddo
			else
				xRet := nil
			endif
		else	//Alterado por Daniel Bueno - 08.02.21
			If (Empty((cAls)->C6_NUM))
				cC6DEL := "S"
			EndIf
			U_fConout(ProcName(0), "TPurchaseOrder - NOK -> OC: " + (cAls)->C7_NUM + " PV: " + (cAls)->C7_MMNUMPV + " C6: " + (cAls)->C6_NUM + " C6DELET: " + cC6DEL + " Query: " + cQry, .t.)
			xRet := nil
		endif	
		(cAls)->(dbCloseArea())
		
		xRet := self
	endif
	
return xRet


method getByNF(cFil, cNumDoc, cNumSer) class TPurchaseOrder
    local cQry
    local cNumOC := ''
    local cAls := GetNextAlias()
    
    default cFil := xFilial('SF2')
    default cNumDoc := '000000000'
    default cNumSer := '1  '
    
    cQry := " SELECT C7_NUM FROM " +;
            " SD2010 SD2 (nolock) " +;
            " LEFT JOIN SC7010 SC7 ON D2_PEDIDO = C7_MMITV AND D2_ITEMPV = C7_MMITPV AND SC7.D_E_L_E_T_ = '' " +;
            " WHERE D2_FILIAL = '" + cFil + "' " +;
            " AND D2_DOC = '" + cNumDoc + "' " +;
            " AND D2_SERIE = '" + cNumSer + "' " +;
            " AND SD2.D_E_L_E_T_ = '' "
    
    TCQuery cQry new alias &cAls
    if !(cAls)->(eof())
        cNumOC := (cAls)->C7_NUM
    endif
    (cAls)->(dbCloseArea())
    
return ::get(cNumOC)


Static Function GetItensPC(cPedido,cItem,cSequen,cFiltro)

Local aArea		:= GetArea()
Local aAreaSC7	:= SC7->(GetArea())
Local cValid	:= ""
Local nPosRef	:= 0
Local nItem		:= 0
Local cItemDe	:= IIf(cItem==Nil,'',cItem)
Local cItemAte	:= IIf(cItem==Nil,Repl('Z',Len(SC7->C7_ITEM)),cItem)
Local cRefCols	:= ''
Local nX
Local cFilSC7   := '010104'//Filial('SC7')
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
			If "MAFISREF" $ cValid .And. !(aStru[nX][14]) //campos que n�o s�o virtuais
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
