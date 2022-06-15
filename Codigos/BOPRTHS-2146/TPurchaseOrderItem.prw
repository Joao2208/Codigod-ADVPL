#include 'totvs.ch'
#include 'topconn.ch'

class TPurchaseOrderItem

	data id_insert
	data deletado
	data codigo
	data codigo_produto_fornecedor
	data numero_pedido_venda
	data quantidade_pedido_venda
	data item
	data idfk_pedido_compra
	data descricao
	data quantidade
	data preco_unitario
	data quantidade_confirmada
	data data_estimada_entrega
	data prazo_transportadora
	data prazo_entrega
	data prazo_nota
	data unidade_medida
	data preco_total
	data ipi
	data unidade_conversao
	data ean
	data operacao
	data cst
	data tipo_assistencia
	data agrupa
	data armazem
	data valor_ipi 
	data numero_sc 
	data qtsegum 
	data valor_desconto 
	data obs_item 
	data icms 
	
	method new() constructor
	method setItem(cFil, cOC, cIt)		// Define o item baseado na filial, OC e numero de item

endclass

method new() class TPurchaseOrderItem

	::id_insert := ''
	::deletado := ''
	::codigo := ''
	::codigo_produto_fornecedor := ''
	::numero_pedido_venda := ''
	::quantidade_pedido_venda := ''
	::item := ''
	::idfk_pedido_compra := ''
	::descricao := ''
	::quantidade := ''
	::preco_unitario := 0
	::quantidade_confirmada := ''
	::data_estimada_entrega := ''
	::prazo_transportadora := ''
	::prazo_entrega := ''
	::prazo_nota := ''
	::unidade_medida := ''
	::preco_total := ''
	::ipi := ''
	::unidade_conversao := ''
	::ean := ''
	::operacao := ''
	::cst := ''
	::tipo_assistencia := ''
	::agrupa := ''
	::armazem := ''
	::valor_ipi := ''
	::numero_sc := ''
	::qtsegum := ''
	::valor_desconto := ''
	::obs_item := ''
	::icms := ''
	
return self

method setItem(cFil, cOC, cIt) class TPurchaseOrderItem
	local cQry
	local cAls := GetNextAlias()
	
	::new()
	
	
	cQry := " SELECT " +;
							" R_E_C_N_O_ C7RECNO, " +;
							" D_E_L_E_T_ C7DELET, " +;
							"	C7_PRODUTO, " +;
							"	A5_CODPRF, " +;
							"	C7_MMITV, " +;
							"	C6_QTDVEN, " +;
							"	C7_ITEM, " +;
							"	C7_NUM, " +;
							"	B1_MMDESC, " +;
							"	C7_QUANT, " +;
							"	C7_PRECO, " +;
							"	C7_QUJE, " +;
							"	C6_DATAENT, " +;
							"	C6_PZTRANS, " +;
							"	C6_ENTFORN, " +;
							"	C6_LOCAL, " +;							
							"	A5_MMDEFOR, " +;
							"	A2_NFPRZ, " +;
							"	C7_UM, " +;
							"	C7_TOTAL, " +;
							"	C7_IPI, " +;
							"	A5_XCONV, " +;
							"	ean, " +;
							"	C7_OPERS, " +;
							"	C7_CST, " +;
							"	C7_TIPAT, " +;
							"   C7_MMLJRET, " +;
							"   C7_LOCAL, " +;							
							"	B1_AGRUPA " +;
						" FROM " +;
						" SC7010 SC7 " +;
						" INNER JOIN SB1010 SB1 ON SB1.B1_FILIAL = '"+xFilial("SB1")+"' AND SB1.B1_COD = SC7.C7_PRODUTO " +;
						" INNER JOIN SA2010 SA2 ON SA2.A2_FILIAL = '"+xFilial("SA2")+"' AND SA2.A2_COD = SC7.C7_FORNECE AND SA2.A2_LOJA = SC7.C7_LOJA " +;
						" LEFT JOIN SA5010 SA5 ON SA5.A5_FILIAL = '"+xFilial("SA5")+"' AND SA5.A5_FORNECE = SC7.C7_FORNECE AND SA5.A5_LOJA = SC7.C7_LOJA AND SA5.A5_PRODUTO = SC7.C7_PRODUTO AND SA5.D_E_L_E_T_ = '' " +;
						" LEFT JOIN SC6010 SC6 ON SC6.C6_FILIAL = '"+xFilial("SC6")+"' AND SC6.C6_NUM = SC7.C7_MMITV AND SC6.C6_ITEM = SC7.C7_MMITPV AND SC6.C6_PRODUTO = SC7.C7_PRODUTO " +;
						" LEFT JOIN SC5010 SC5 ON SC5.C5_FILIAL = SC6.C6_FILIAL AND SC5.C5_NUM = SC6.C6_NUM " +;
						" LEFT JOIN produtos prd ON prd.codigo = SC7010.C7_PRODUTO " +;
						" WHERE " +;
						" C7_FILIAL = '"+cFil+"' " +;
						" AND C7_NUM = '"+cOC+"' " +;
						" AND C7_ITEM = '"+cIt+"' "
	
		TCQuery cQry new alias &cAls
		
	if !(cAls)->(eof())
		::id_insert := AllTrim(Str(SC7->C7RECNO))
		::deletado := (cAls)->C7DELET
		::codigo := (cAls)->C7_PRODUTO
		::codigo_produto_fornecedor := AllTrim((cAls)->A5_CODPRF)
		::numero_pedido_venda := (cAls)->C7_MMITV
		::quantidade_pedido_venda := (cAls)->C6_QTDVEN
		::item := (cAls)->C7_ITEM
		::idfk_pedido_compra := (cAls)->C7_NUM
		::descricao := AllTrim((cAls)->B1_MMDESC)
		::quantidade := (cAls)->C7_QUANT
		::preco_unitario := (cAls)->C7_PRECO
		::quantidade_confirmada := (cAls)->C7_QUJE
		::data_estimada_entrega := (cAls)->C6_DATAENT
		::prazo_transportadora := (cAls)->C6_PZTRANS
		::prazo_entrega := IIF((cAls)->C6_ENTFORN > 0, (cAls)->C6_ENTFORN, (cAls)->A5_MMDEFOR) 
		::prazo_nota := (cAls)->A2_NFPRZ
		::unidade_medida := (cAls)->C7_UM
		::preco_total := (cAls)->C7_TOTAL
		::ipi := (cAls)->C7_IPI
		::unidade_conversao := (cAls)->A5_XCONV
		::ean := (cAls)->ean
		::operacao := (cAls)->C7_OPERS
		::cst := (cAls)->C7_CST
		::tipo_assistencia := (cAls)->C7_TIPAT
		::agrupa := (cAls)->B1_AGRUPA
		::armazem := (cAls)->C7_LOCAL
	endif
	
	(cAls)->(dbCloseArea())
	
return self
