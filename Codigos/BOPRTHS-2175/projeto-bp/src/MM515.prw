#INCLUDE "protheus.ch"
#INCLUDE "rwmake.ch"
#INCLUDE "TOPCONN.CH"
#INCLUDE "TOTVS.CH"

/*/{Protheus.doc} MM515
Rotina para busca dos pagamentos por pedidos de venda
@author Thiago Almeida
@since 09/04/2021
@type user function
@param none
@return none
@example none
(examples) none
@see (links_or_references) none
/*/
User Function MM515()

	Local cQry,cAlias
	Local nCont := 0
	Local oChk,lExcExec

	Private nToleranc	:= 0

	IF TYPE("cFilAnt") == 'U'
		RpcSetEnv( '01','010101')
	ENDIF

	//Valida se ja esta executando
	oChk := Nil
	oChk := CheckExecution():New()
	lExcExec := oChk:TrafficLight("MM515")

	If !lExcExec
		Conout(CRLF+"MM515 - Importacao dos pagamentos - TrafficLight Ativo - Rotina ja esta em execucao! "+Time()+CRLF)
		FreeObj(oChk)
		Return(.T.)
	Else
		Conout(CRLF+"MM515 - Importacao dos pagamentos - TrafficLight Inativo - Rotina liberada para execucao! "+Time()+CRLF)
	EndIf

	VldImport()

	nToleranc := GETMV("MM_TOLE515") //Parametro com a tolerancia para a diferenca de valores

	CONOUT("MM515 - Inicio da busca pelo pedido pai "+Time())
	//Seleciona os pedidos que ainda nao tiveram Importacao
	cQry := " select pedidopai,pedido from cabecalho_pedidos_venda cabe(nolock) "
	cQry += " where created_at >= '2021-03-26' and protheus = '1' and pedmktplace is null and substring(pedido,1,1) = 'Z' "
	cQry += " and pedidopai not in(SELECT Z21_PEDPAI FROM Z21010 (NOLOCK) WHERE Z21_FILIAL = '' AND Z21_PEDPAI = pedidopai AND D_E_L_E_T_ <> '*') "
//	cQry += " and pedidopai in('25838966') "
	cQry += " order by cabe.pedidopai "
	cAlias := GetNextAlias()
	TCQuery cQry new alias &cAlias

	While !(cAlias)->(EOF())
		nCont++
		CONOUT("MM515 - Verificando pedido pai "+AllTrim((cAlias)->pedidopai)+", contador: "+cValToChar(nCont)+" | "+Time())
		U_BuscaPGTO(AllTrim((cAlias)->pedidopai))
		(cAlias)->(DbSkip())
	ENDDO
	(cAlias)->(DbCloseArea())

	//libera objeto e arquivo de semaforo
	FreeObj(oChk)
Return()

/*/{Protheus.doc} BuscaPGTO
Realiza para busca dos pagamentos por pedido pai
@author Thiago Almeida
@since 09/04/2021
@type user function
@param cPedidopai
@return Logico
@example none
(examples) none
@see (links_or_references) none
/*/
USER Function BuscaPGTO(cPedidopai)

	Local cQry,cAlias,n1
	Local aRetorno 	:= {}
	Local aRet := {}
	Local nVldValor	:= 0
	Local lValida	:= .F.
	Local nTotValBP := 0
	Local nTotValBridge := 0
	Local nPerc := 0
	Local nNewAmount := 0
	Local nDiffVal := 0
	Local nCount
	Local lRet := .F.
	Local lCancelado := .F.
	//Local lSemBandei := .F.
	Private cMensagem := ""
	IF TYPE("cFilAnt") == 'U'
		RpcSetEnv( '01','010101')
	ENDIF
	nToleranc := GETMV("MM_TOLE515") //Parametro com a tolerancia para a diferenca de valores
	//Valida se ja foi importado, pois o pedido pai pode ter n filhos
	cQry := " SELECT Z21_PEDPAI FROM Z21010 (NOLOCK) WHERE Z21_PEDPAI = '"+cPedidopai+"' AND D_E_L_E_T_ <> '*'  "
	cAlias := GetNextAlias()
	TCQuery cQry new alias &cAlias
	
	//Retorna um array e sua ultima posição é o payload retornardo pelo BP
	aRetorno := GetPgtoBp(cPedidopai) // GetPgto(cHash) //consulta a API do CoreAPI's
	nCount:=Len(aRetorno)
	AAdd(aRet,aRetorno[nCount])

	IF EMPTY((cAlias)->Z21_PEDPAI)
		//aRetorno := GetPgtoBp(cPedidopai) 
		IF Len(aRetorno) > 0
			lCancelado := .F.
			//lSemBandei := .F.
			For n1 := 1 to Len(aRetorno)-1 // "-1" foi adicionado pois a ultima posição desse array é sempre uma string com payloado e não se encaixa na validação
				nTotValBP += aRetorno[n1]:AMOUNT

				IF aRetorno[n1]:TYPE == "canceled" .AND. aRetorno[n1]:BRAND == "CANCELADO"
					lCancelado := .T.
				ENDIF
				/*
				IF EMPTY(aRetorno[n1]:BRAND) .AND. aRetorno[n1]:TYPE <> "canceled"
					lSemBandei := .T.
				ENDIF
				*/
			Next
			// IF lSemBandei //Validacao para abertura de chamado quando nao existir bandeira para o pagamento
			/*
				cMensagem += "A Rotina MM515-Importacao de pagamentos, identificou no Black Panter que o Pedido Pai " + cPedidopai
				cMensagem += " está sem a informação da bandeira de cartão de crédito que foi realizado o pagamento.'"
				//JIRA (serviceDeskId,requestTypeId,summary                  ,description,acustomfield)
				Aadd(acustonfield3, {"customfield_11090", Val(cPedidoPai)})
				Aadd(acustonfield3, {"customfield_11196", '{"value":"Pedidos"}'})
				Aadd(acustonfield3, {"customfield_11200", '{"value":"Importação de pedidos"}'})
				U_MM537("52"          ,"881"        ,"Pagamento nao retornado",cMensagem  ,acustonfield3)
			*/
			/*
				cMensagem += "A Rotina MM515-Importacao de pagamentos, identificou no Black Panter que o Pedido Pai " + cPedidopai
				cMensagem += " está sem a informação da bandeira de cartão de crédito que foi realizado o pagamento."
				U_MM537("2"          ,"229"        ,"Pagamento nao retornado",cMensagem  ,{{"customfield_10188", cPedidoPai}})
			ENDIF 
			*/
			nTotValBridge := totValBrd(cPedidopai)

			DbSelectArea("Z21")
			Begin Transaction
				For n1 := 1 to Len(aRetorno)-1
					CONOUT("MM515 - Gravando pagamentos do pedido pai "+cPedidopai+" | "+Time())
					IF RecLock("Z21",.T.)
						Z21->Z21_FILIAL := xFilial("Z21")
						Z21->Z21_PEDPAI	:= cPedidopai
						//Z21->Z21_TIPO	:= IIF(aRetorno[n1]:METHOD = 'cartaodecredito','CREDIT_CARD',IIF(aRetorno[n1]:METHOD = 'cartaodedebito','DEBIT_CARD',UPPER(AllTrim(aRetorno[n1]:METHOD))))   //aRetorno[n1]:TYPE

						IF aRetorno[n1]:METHOD = 'cartaodecredito'
							Z21->Z21_TIPO := 'CREDIT_CARD'
						ELSEIF aRetorno[n1]:METHOD = 'cartaodedebito'
							Z21->Z21_TIPO := 'DEBIT_CARD'
						ELSEIF aRetorno[n1]:METHOD = 'pos' .AND. UPPER(aRetorno[n1]:BRAND) == 'MAESTRO'
							Z21->Z21_TIPO := 'DEBIT_CARD'
						ELSE
							Z21->Z21_TIPO := UPPER(AllTrim(aRetorno[n1]:METHOD))
						ENDIF

						//Z21->Z21_ARRANJ	:= IIF(UPPER(aRetorno[n1]:BRAND) = 'MASTER','MASTERCARD',UPPER(aRetorno[n1]:BRAND))

						IF UPPER(aRetorno[n1]:BRAND) = 'MASTER'
							Z21->Z21_ARRANJ := 'MASTERCARD'
						ELSEIF UPPER(aRetorno[n1]:BRAND) == 'MAESTRO' //.AND. aRetorno[n1]:METHOD = 'pos'
							Z21->Z21_ARRANJ := 'MASTERCARD'
						ELSEIF UPPER(aRetorno[n1]:BRAND) == 'SOROCRED' .AND. aRetorno[n1]:METHOD = 'cartaodecredito'
							Z21->Z21_ARRANJ := 'MASTERCARD'
						ELSE
							Z21->Z21_ARRANJ := UPPER(aRetorno[n1]:BRAND)
						ENDIF

						nDiffVal := nTotValBridge - nTotValBP
						nDiffVal := IIf(nDiffVal < 0,nDiffVal * -1,nDiffVal)
						If nDiffVal <= nToleranc //Se a diferença for menor que a tolerancia estabelecida, segue fluxo normal
							Z21->Z21_VALOR	:= aRetorno[n1]:AMOUNT
						Else
							nPerc = (aRetorno[n1]:AMOUNT*1)/nTotValBP //Percentual nAmount no BP
							nNewAmount := nTotValBridge * nPerc //Aplica o percentual do pagamento e aplica sobre valor da bridge
							Z21->Z21_VALOR	:= nNewAmount
							Z21->Z21_HASH   := "Bridge "+AllTrim(cValToChar(nTotValBridge))+";API "+AllTrim(cValToChar(nTotValBP))+";dif: "+AllTrim(cValToChar(nDiffVal))
						EndIf
						Z21->Z21_QTDPAR	:= aRetorno[n1]:INSTALLMENTS	//aRetorno[n1]:INSTALLMENT:NUMBER
						//Z21->Z21_VALPAR := aRetorno[n1]:INSTALLMENT:VALUE
						//Z21->Z21_DESCON := aRetorno[n1]:INSTALLMENT:DISCOUNT
						//Z21->Z21_JUROS	:= aRetorno[n1]:INSTALLMENT:INTEREST
						//Z21->Z21_HASH	:= cHash
						Z21->Z21_ADQUIR	:= Upper(Alltrim(aRetorno[n1]:PROVIDER))
						Z21->Z21_DATA	:= Date()
						Z21->Z21_HORA	:= Time()
						Z21->(MsUnLock())
						nVldValor += IIf(nDiffVal <= nToleranc,aRetorno[n1]:AMOUNT,nNewAmount) //aRetorno[n1]:INSTALLMENT:TOTAL
						lRet := .T.
					ELSE
						DisarmTransaction()
						lRet := .F.
					ENDIF
				Next
				cMensagem := ""
				lValida := DivPgto(cPedidopai,nVldValor,lCancelado) //Chama a rotina para divisao dos valores por arranjo
				IF !lValida //Se o valor da API nao bater com o valor da bridge
					DisarmTransaction()
					RecLock("Z21",.T.)
					Z21->Z21_FILIAL := xFilial("Z21")
					Z21->Z21_PEDPAI	:= cPedidopai
					Z21->Z21_TIPO	:= "ERRO"
					Z21->Z21_ARRANJ	:= "ERRO"
					Z21->Z21_HASH	:= cMensagem
					Z21->Z21_DATA	:= Date()
					Z21->Z21_HORA	:= Time()
					Z21->(MsUnLock())
					lRet := .F.
				ENDIF
			End Transaction
		ENDIF
	ENDIF
	(cAlias)->(DbCloseArea())
	Aadd(aRet, lRet)
Return(aRet)

/*/{Protheus.doc} GetPgtoBp
Chama API para consulta o pedido no Black Panther
@author Thiago Almeida
@since 09/04/2021
@type user function
@param cPedidopai
@return array com os dados de pagamento
@example none
(examples) none
@see (links_or_references) none
/*/
Static Function GetPgtoBp(cPedidopai)
	Local cURL			:= "https://black-panther.madeiramadeira.com.br"
	Local cURLPath		:= "/v1/protheus-checkout/"
	Local aHeader		:= {}
	Local aArray        := {}
	Local nCanc			:= 0

	Private oResp       := nil
	DEFAULT cRespPGTO   := ""
	Aadd(aHeader, "X-Auth:9V1jO0G6mwcfuAdLlzlfUEqVpdwDpKS1")

	oRestClient := FWRest():New(cURL)
	oRestClient:SetPath(cURLPath+cPedidopai)
	CONOUT("MM515 - CONSULTANDO BLACK PANTHER, disparando o GET, pedido pai "+cPedidopai)
	If oRestClient:Get(aHeader)
		oResp := Nil
		CONOUT("MM515 -  CONSULTANDO PEDIDO PAI "+cPedidopai+" | "+Time())
		FWJsonDeserialize(oRestClient:GetResult(), @oResp)
		aArray := oResp:DATA:PAYMENTS
	ENDIF
	cRespPGTO := oRestClient:CRESULT
	IF oResp:DATA:STATUS == "canceled"
		For nCanc := 1 to Len(aArray)
			IF EMPTY(aArray[nCanc]:BRAND)
				aArray[nCanc]:BRAND := "CANCELADO"
				aArray[nCanc]:TYPE  := oResp:DATA:STATUS
			ENDIF
		Next
	ENDIF	
	AADD(aArray, cRespPGTO) 
Return(aArray)

//Consulta o pedido no CORE API
/*
Static Function GetPgto(cHash)

	Local cURL			:= "https://shop-api-services.madeiramadeira.com.br"
	Local cURLPath		:= "/order/"
	Local aHeader		:= {}
	Local aArray        := {}

	Private oResp := nil

	Aadd(aHeader, "apiKey:fsxtY1YMUOEiQl34AO6fl78VSetNItTc")

	oRestClient := FWRest():New(cURL)
	oRestClient:SetPath(cURLPath+cHash)
	CONOUT("MM515 - CONSULTANDO CORE API, disparando o GET, Hash "+cHash)
	If oRestClient:Get(aHeader)
		oResp := Nil
		CONOUT("MM515 -  CONSULTANDO Hash "+cHash+" | "+Time())
		FWJsonDeserialize(oRestClient:GetResult(), @oResp)
		aArray := oResp:DATA:PAYMENTS
	ENDIF

Return(aArray)
*/

/*/{Protheus.doc} DivPgto
Funcao para a divisao dos pagamentos por arranjo
@author Thiago Almeida
@since 09/04/2021
@type user function
@param cPedPai,nVldValor,lCancelado
@return Logico
@example none
(examples) none
@see (links_or_references) none
/*/
Static Function DivPgto(cPedPai,nVldValor,lCancelado)

	Local cQry01,cQry02,cQry03,cAlias01,cAlias02,cAlias03,n1,cTpArranjo,nVlrDif,dData,cHora
	Local nValCalc 		:= 0
	Local nValorTot 	:= 0
	Local nValPedido 	:= 0
	Local nValGarant	:= 0
	Local aResultado 	:= {}
	Local aArranjo		:= {}
	Local lResult		:= .T.
	Local nDuplic		:= 0
	Local nVlrArrd		:= 0

	IF TYPE("cFilAnt") == 'U'
		RpcSetEnv( '01','010101')
	ENDIF

	//PEDIDO PAI PARA TESTE 16700530
	dData := Date()
	cHora := Time()

	cQry01 := " select pedido,round(Convert(Numeric(10,2),valorfrete),2) as valorfrete from cabecalho_pedidos_venda (nolock) where pedidopai = '"+cPedPai+"' "
	cQry01 += " AND created_at >= '2021-03-26' and pedmktplace is null and substring(pedido,1,1) = 'Z' "
	cQry01 += " order by pedido "
	cAlias01 := GetNextAlias()
	TCQuery cQry01 new alias &cAlias01

	While !(cAlias01)->(EOF())
		//Verifica os valores nos itens, Atenção para o valor da garantia estendida, campo valor_garantia
		cQry02 := " select round(sum(Convert(Numeric(10,2),valor_total)),2) as vlr_total, round(sum(Convert(Numeric(10,2),frete)),2) as frete_total, "
		cQry02 += " round(sum(Convert(Numeric(10,2),valor_garantia)),2) as valor_garantia "
		cQry02 += " from items_do_pedido_de_venda (nolock) where pedido = '"+(cAlias01)->pedido+"' "
		cAlias02 := GetNextAlias()
		TCQuery cQry02 new alias &cAlias02

		IF (cAlias02)->vlr_total > 0
			nValPedido := (cAlias02)->vlr_total + IIF((cAlias02)->frete_total > 0,(cAlias02)->frete_total,(cAlias01)->valorfrete)
			//nValGarant += (cAlias02)->valor_garantia
			nValPedido := IIF((cAlias02)->valor_garantia > 0,nValPedido + (cAlias02)->valor_garantia,nValPedido)
			IF nValorTot = 0 // Se nao iniciou o calculo do valor total, verifica a quantidade de pagamentos para montar o array aResultado
				cQry03 := " SELECT Z21_ARRANJ AS ARRANJO,Z21_TIPO,Z21_VALOR FROM Z21010 (nolock) "
				cQry03 += " WHERE Z21_PEDPAI = '"+cPedPai+"' AND D_E_L_E_T_ <> '*' "
				cAlias03 := GetNextAlias()
				TCQuery cQry03 new alias &cAlias03

				While !(cAlias03)->(EOF())
					cTpArranjo := IIF(EMPTY((cAlias03)->ARRANJO),"OUTROS",AllTrim((cAlias03)->ARRANJO))

					IF Len(aArranjo) > 0 //Validacao para juntar os pagamentos se for a mesma bandeira/arranjo
						nDuplic := 0
						For n1 := 1 to Len(aArranjo)
							IF cTpArranjo == aArranjo[n1,1] .AND. AllTrim((cAlias03)->Z21_TIPO) == aArranjo[n1,3]
								aArranjo[n1,2] += (cAlias03)->Z21_VALOR
								nDuplic++
								n1 := Len(aArranjo)
							ENDIF
						Next
						IF nDuplic = 0
							AADD(aArranjo,{cTpArranjo,(cAlias03)->Z21_VALOR,AllTrim((cAlias03)->Z21_TIPO)})
						ENDIF
					ELSE
						AADD(aArranjo,{cTpArranjo,(cAlias03)->Z21_VALOR,AllTrim((cAlias03)->Z21_TIPO)})
					ENDIF
					(cAlias03)->(DbSkip())
				ENDDO
				(cAlias03)->(DbCloseArea())
			ENDIF

			nValorTot += nValPedido

			For n1 := 1 to Len(aArranjo)
				AADD(aResultado,{{'PEDIDO',(cAlias01)->pedido},{"VALOR PEDIDO",nValPedido},{"TIPO","DEBITO OU CREDITO"},{"ARRANJO",aArranjo[n1,1]},{"VALOR ARRANJO",aArranjo[n1,2]},{"TIPO",aArranjo[n1,3]}})
			NEXT
		ENDIF
		(cAlias02)->(DbCloseArea())

		(cAlias01)->(DbSkip())
	ENDDO
	(cAlias01)->(DbCloseArea())
	//Olha os pagamentos recebidos
	For n1 := 1 to Len(aResultado)
		cQry03 := " SELECT Z21_TIPO,Z21_ARRANJ,Z21_VALOR FROM Z21010 (nolock) "
		cQry03 += " WHERE Z21_PEDPAI = '"+cPedPai+"' AND Z21_ARRANJ = '"+IIF(aResultado[n1,4,2] = "OUTROS","",aResultado[n1,4,2])+"' AND Z21_TIPO = '"+aResultado[n1,6,2]+"' AND D_E_L_E_T_ <> '*' "
		cAlias03 := GetNextAlias()
		TCQuery cQry03 new alias &cAlias03

		IF (cAlias03)->Z21_VALOR <> aResultado[n1,5,2] //Se for diferente do calculado
			nValCalc := ROUND((aResultado[n1,2,2] / nValorTot) * aResultado[n1,5,2],2) //Calculo do valor com base no recebimento
		ELSE
			nValCalc := ROUND((aResultado[n1,2,2] / nValorTot) * (cAlias03)->Z21_VALOR,2) //Calculo do valor com base no recebimento
		ENDIF

		aResultado[n1,3,2] := AllTrim((cAlias03)->Z21_TIPO)
		aResultado[n1,5,2] := nValCalc

		(cAlias03)->(DbCloseArea())
	NEXT

//Grava o resultado
	IF nValorTot == nVldValor
		lResult := .T.
	ELSEIF nValGarant > 0
		IF (nValorTot + nValGarant) == nVldValor
			lResult := .T.
		ENDIF
	ELSE
		nVlrDif := nValorTot - nVldValor
		nVlrDif := IIF(nVlrDif < 0,nVlrDif * -1,nVlrDif)
		IF nVlrDif <= nToleranc //0.02
			lResult := .T.
		ELSE
			CONOUT("MM515 - Diferenca de valores para o pedido pai "+cPedPai+", valor na Bridge "+cValToChar(nValorTot)+", valor da API "+cValToChar(nVldValor)+;
				", diferenca: "+cValToChar(nVlrDif))
			cMensagem := "Bridge "+AllTrim(cValToChar(nValorTot))+",API "+AllTrim(cValToChar(nVldValor))+",dif: "+AllTrim(cValToChar(nVlrDif))
			lResult := .F.
		ENDIF
	ENDIF
	IF lResult
		DbSelectArea("Z12")
		Begin Transaction
			nValAnt := 0
			For n1 := 1 to Len(aResultado)
				IF RecLock("Z12",.T.)
					nVlrArrd := aResultado[n1,2,2] - aResultado[n1,5,2]
					nVlrArrd := IIF(nVlrArrd < 0,nVlrArrd * -1,nVlrArrd)
					IF nVlrArrd == 0.01
						/*Z12_VALARR*/aResultado[n1,5,2] := aResultado[n1,2,2]/*Z12_VALPED*/
					ELSE
						nValAnt += aResultado[n1,5,2]
					ENDIF
					//Corrige o arredondamento quando possuir mais de 2 metodos de pagamento
					IF n1 = 1
						cPedidoAr := aResultado[n1,1,2]
					ELSEIF Len(aResultado) > 2 //se o pagamento possuir mais de 2 registros
						IF cPedidoAr = aResultado[n1,1,2]
							nVlrArrd := nValAnt - aResultado[n1,2,2]
							// nVlrArrd := IIF(nVlrArrd < 0,nVlrArrd * -1,nVlrArrd)
							IF nVlrArrd == 0.01 .OR. nVlrArrd == -0.01
								aResultado[n1,5,2] := aResultado[n1,5,2] - nVlrArrd
							ENDIF
							nValAnt := 0
						ELSE
							cPedidoAr := aResultado[n1,1,2]
						ENDIF
					ENDIF
					// caso o pedido não entre na regra anterior
					IF n1 > 1 .AND. n1 = Len(aResultado) .AND. nValAnt > 0
						nVlrArrd := nValAnt - aResultado[n1,2,2]
						nVlrArrd := IIF(nVlrArrd < 0,nVlrArrd * -1,nVlrArrd)
						IF nVlrArrd == 0.01
							aResultado[n1,5,2] := aResultado[n1,5,2] - nVlrArrd
						ENDIF
					ENDIF

					Z12->Z12_FILIAL := XFilial("Z12")
					Z12->Z12_PEDPAI := cPedPai
					Z12->Z12_PEDIDO := aResultado[n1,1,2]
					Z12->Z12_VALTOT := nValorTot
					Z12->Z12_VALPED := aResultado[n1,2,2]
					Z12->Z12_VALARR := aResultado[n1,5,2]
					Z12->Z12_ARRANJ := aResultado[n1,4,2]
					Z12->Z12_TIPOAR := aResultado[n1,3,2]
					Z12->Z12_DATA 	:= dData
					Z12->Z12_HORA 	:= cHora
					Z12->Z12_CANCEL := IIF(lCancelado,'X','')
					Z12->(MsUnLock())
				ELSE
					DisarmTransaction()
				ENDIF
			NEXT
		End Transaction
	ENDIF

Return(lResult)


/*/{Protheus.doc} totValBrd
	busca valor total por pedido pai na bridge
	@type  Static Function
	@author GabrielRosa
	@since 24/05/2021
	@version 1.0
	@param pedidopai, caractere, numero do pedido pai que será buscado
	@return nTotValBrd, numeric, valor total do pedido
/*/
Static Function totValBrd(pedidopai)
	Local cAls := GetNextAlias()
	Local cQuery := ''
	Local nTotValBrd := 0

	cQuery += "	SELECT "
	cQuery += "		total_value = sum(pedido_valor_total) + sum(pedido_valor_frete)  + sum(pedido_valor_garantia) "
	cQuery += "	FROM ( "
	cQuery += "		SELECT "
	cQuery += "			cabec.pedido, "
	cQuery += "			pedido_valor_total  = round(sum(convert(Numeric(10,2),items.valor_total)),2), "
	cQuery += "			pedido_valor_frete  = iif(sum(convert(Numeric(10,2),items.frete)) = 0,convert(Numeric(10,2),cabec.valorfrete),round(sum(convert(Numeric(10,2),items.frete)),2) ), "
	cQuery += "			pedido_valor_garantia = round(sum(iif(items.valor_garantia is not null, convert(Numeric(10,2),items.valor_garantia),0)),2) "
	cQuery += "		FROM items_do_pedido_de_venda items "
	cQuery += "		LEFT JOIN cabecalho_pedidos_venda cabec ON items.pedido = cabec.pedido "
	cQuery += "			AND  cabec.created_at >= '2021-03-26' and cabec.pedmktplace is null and substring(cabec.pedido,1,1) = 'Z' "
	cQuery += "		WHERE cabec.pedidopai = '"+pedidopai+"' "
	cQuery += "		GROUP BY cabec.pedido,cabec.valorfrete "
	cQuery += "		 "
	cQuery += "	) VALORES_PEDIDOS "

	TcQuery cQuery new alias &cAls

	(cAls)->(DbGoTop())

	If (cAls)->(Eof())
		Return .F.
	EndIf

	nTotValBrd := (cAls)->total_value

	(cAls)->(DbCloseArea())
Return nTotValBrd

/*/{Protheus.doc} VldImport
Verifica se existe algum pedido filho que não teve as informações de pagamento importadas
@author Thiago Almeida
@since 09/04/2021
@type static function
@param none
@return none
@example none
(examples) none
@see (links_or_references) none
/*/
Static Function VldImport()

	Local cQry01,cQry02,cAlias01,cAlias02

	cQry01 := " select pedidopai,pedido from cabecalho_pedidos_venda cabe(nolock) "
	cQry01 += " where created_at >= '2021-03-26' and protheus = '1' and pedmktplace is null and substring(pedido,1,1) = 'Z' "
	cQry01 += " and pedidopai in(SELECT Z21_PEDPAI FROM Z21010 (NOLOCK) WHERE Z21_FILIAL = '' AND Z21_PEDPAI = pedidopai AND D_E_L_E_T_ <> '*') "
	cQry01 += " and pedido not in(SELECT Z12_PEDIDO FROM Z12010(NOLOCK) WHERE Z12_PEDIDO = pedido AND D_E_L_E_T_ <> '*') "
	cQry01 += " ORDER BY pedidopai "
	cAlias01 := GetNextAlias()
	TCQuery cQry01 new alias &cAlias01

	DbSelectArea("Z12")
	DbSelectArea("Z21")
	CONOUT("MM515 - IMPORTACAO INFORMACOES DE PAGAMENTO, VALIDANDO A EXISTENCIA DE PEDIDOS FILHOS NAO IMPORTADOS")
	While !(cAlias01)->(EOF())
		Begin Transaction
			cQry02 := " SELECT R_E_C_N_O_ AS RECNOZ12 FROM Z12010 WHERE Z12_PEDPAI = '"+(cAlias01)->pedidopai+"' AND D_E_L_E_T_ <> '*' "
			cAlias02 := GetNextAlias()
			TCQuery cQry02 new alias &cAlias02

			While !(cAlias02)->(EOF())
				CONOUT("MM515 - DELETANDO REGISTRO DA TABELA Z12 "+Time())
				Z12->(DbGoTo((cAlias02)->RECNOZ12))
				RecLock("Z12",.F.)
				Z12->(DbDelete())
				Z12->(MsUnLock())
				(cAlias02)->(DbSkip())
			ENDDO
			(cAlias02)->(DbCloseArea())

			cQry02 := " SELECT R_E_C_N_O_ AS RECNOZ21 FROM Z21010 (nolock) WHERE Z21_PEDPAI = '"+(cAlias01)->pedidopai+"' AND D_E_L_E_T_ <> '*' "
			cAlias02 := GetNextAlias()
			TCQuery cQry02 new alias &cAlias02

			While !(cAlias02)->(EOF())
				CONOUT("MM515 - DELETANDO REGISTRO DA TABELA Z21 "+Time())
				Z21->(DbGoTo((cAlias02)->RECNOZ21))
				RecLock("Z21",.F.)
				Z21->(DbDelete())
				Z21->(MsUnLock())
				(cAlias02)->(DbSkip())
			ENDDO
			(cAlias02)->(DbCloseArea())

			(cAlias01)->(DbSkip())
		End Transaction
	ENDDO
	(cAlias01)->(DbCloseArea())

Return()
