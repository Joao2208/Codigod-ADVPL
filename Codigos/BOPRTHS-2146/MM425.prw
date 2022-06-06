#include "rwmake.ch"
#include "topconn.ch"
#include "totvs.ch"
#include "protheus.ch"

//-------------------------------------------------------------------------------
/*/{Protheus.doc} MM425
Fila de envio de OC para o Nexus/Portal Fornecedor

@return
@author Vinicius Wille
@since 18/09/2019
/*/
//-------------------------------------------------------------------------------

User Function MM425()
Local cQry		:= ""
//Local cQry2		:= ""
Local cAlias	:= ""//GetNextAlias()
//Local cAlias2	:= ""//GetNextAlias()
Local aArea		:= ""//GetArea()
//Local nTempo	:= 0
Local nAux      := 0
//Local aEventType:= {'PURCHASE_ORDER_SEARCHED_PROTHEUS', 'PURCHASE_ORDER_VIEWED_PROTHEUS', 'PURCHASE_ORDER_CREATED_PROTHEUS', 'PURCHASE_ORDER_UPDATED_PROTHEUS', 'PURCHASE_ORDER_CANCELED_PROTHEUS'}
Local lQueue	:= .F.
Local oChkExec	:= Nil
Local oMultThrd	:= Nil
Local cThreadId 
Local nThrds
Local nLmtOcTh

	//Prepara o ambiente para schedule
	RPCSetEnv("01","010101")
	
	cThreadId := cValToChar(ThreadId())

	Conout(CRLF + "MM425 - Thread Master " + cThreadId + " | Envio OC´s para o Portal - Inicio as " + Time())

	oChkExec := CheckExecution():New()
	If !oChkExec:ChkExcExec("MM425")
		Return
	EndIF

	Limbo()

	nThrds     := SuperGetmv("MM_425QTHD",.F.,2) //4
	nLmtOcTh   := Supergetmv("MM_425OCTH",.F.,100)

	cAlias	:= GetNextAlias()

	aArea   := GetArea()

	DbSelectArea("SC7")
	DBSetOrder(1)

	DbSelectArea("SX6")
	DBSetOrder(1)

    //Verifica se função já está em execução
	/*If !U_425Mnt()
		Return()
	EndIf*/

	lQueue := GetMV("MM_NEXQUEU")
	If lQueue
		/*
		Z3B_ENVIAD
		'S' = Enviado para o Portal
		'N' = Não enviado
		' ' = Não enviado
		'X' = Erro
		*/
		cQry	:= "SELECT Z3B_FILIAL, Z3B_C7NUM, Z3B_PVMM, Z3B_NOPC, Z3B.R_E_C_N_O_ RECNOZ3B " + CRLF
		cQry	+= "  FROM " + RetSQLName("Z3B") + " Z3B (NOLOCK) " + CRLF
		cQry	+= " WHERE Z3B_ENVIAD NOT IN ('S','X') " + CRLF
		//cQry	+= "   AND Z3B_NOPC IN ('1','2','3','4','5','6','7') " + CRLF
		cQry    += "   AND D_E_L_E_T_ != '*' " + CRLF
		cQry	+= " ORDER BY R_E_C_N_O_ " + CRLF
		TCQuery cQry new alias &cAlias
		Count To nCount

		IF nCount >= nLmtOcTh
			nThrds := SuperGetmv("MM_425QTHD",.F.,2) //4
		ENDIF

		DbSelectArea(cAlias)
		(cAlias)->(DbGoTop())

		If !(cAlias)->(Eof())
			oMultThrd := TMultiT():New(cAlias,nThrds,,)
			oMultThrd:Generate()
			(cAlias)->(DbCloseArea())
			For nAux := 1 To Len(oMultThrd:Threads)
				StartJob("U_MM425THD", GetEnvServer(), .F., oMultThrd:Threads[nAux], nAux)
				ConOut("MM425 - Abriu a fila " + cValToChar(nAux))
				//U_MM425THD(oMultThrd:Threads[nAux], nAux)
			Next nAux
			Conout(CRLF + "MM425 - Thread " + cThreadId + " | Envio OC´s para o Portal - Termino as " + Time())
			//LIBERA OBJETO APÓS USO
			FREEOBJ(oMultThrd)
			oMulti := Nil
		Else
			(cAlias)->(DbCloseArea())
			Conout(CRLF + "MM425 - Thread " + cThreadId + " | Fila de envio OC's para portal em branco - Termino as " + Time())
		EndIf
		RestArea(aArea)
    Else
		Conout(CRLF + "MM425 - Thread " + cThreadId + " | Fila de Envio OC´s para o Portal Desativada " + Time())
	EndIf
Return

//-------------------------------------------------------------------------------
/*/{Protheus.doc} MM425THD
JOb para criação das thread e processamento das OCs

@return
@author Saulo Lima
@since 03/06/2020
/*/
//-------------------------------------------------------------------------------
User Function MM425THD(aContent, nTh)
Local nAux1
Local cAlias2	:= GetNextAlias()
Local aEventType:= {'PURCHASE_ORDER_SEARCHED_PROTHEUS', ; //1
                    'PURCHASE_ORDER_VIEWED_PROTHEUS', ; //2
					'PURCHASE_ORDER_CREATED_PROTHEUS', ; //3
					'PURCHASE_ORDER_UPDATED_PROTHEUS', ; //4
					'PURCHASE_ORDER_CANCELED_PROTHEUS', ; //5
					'PURCHASE_ORDER_SUPPLIER_BILLING_SYM_CHECK',; //6
					'PURCHASE_ORDER_SUPPLIER_BILLING_SYM_INPUT'} //7
Local nCount	:= Len(aContent)
Local nI        := 0	//Daniel Bueno - 18.01.21
Local nTentativ := 0	//Daniel Bueno - 18.01.21
Local lOpcVal := .F.
Local cThreadId := cValToChar(ThreadID())

Conout("Iniciando Thread : " + cValToChar(nTh) + " - Thread ID :" + cThreadId)
//Varinfo("aContent",aContent)
	If Type("cFilAnt") == 'U'
		RPCSetEnv('01','010101')
	EndIf

	nTentativ := GetNewPar("MM_425TENT",5)	//Daniel Bueno - 18.01.21

	//While !(cAlias)->(EOF())
	For nAux1 := 1 To Len(aContent)
		nTempo	  := Seconds()
		lTentativ := .F.	//Alterado por Daniel Bueno - 18.01.21

		cQry2	:= "SELECT C7_FILIAL, C7_NUM, C7_MMNUMPV, C7_MMITV, C7_MMITPV, C7_ITEM, C7_PRODUTO, C7_QUANT, C7_PRECO, C7_TOTAL, C7_NUMSC, R_E_C_N_O_ RECNOSC7 " + CRLF
		cQry2	+= "  FROM " + RetSQLName("SC7") + " (NOLOCK) " + CRLF
		//cQry2	+= " WHERE D_E_L_E_T_ = ' ' " + CRLF
		cQry2	+= "   WHERE  C7_FILIAL = '" + aContent[nAux1][1] + "' " + CRLF
		cQry2	+= "   AND C7_NUM = '" + aContent[nAux1][2] + "' " + CRLF
		cQry2	+= "   AND C7_MMNUMPV = '" + aContent[nAux1][3] + "' " + CRLF
		TCQuery cQry2 new alias &cAlias2
		
		//Valida se a OC existe e está vinculada ao PV MM correto
		If !(cAlias2)->(EOF())
			nOpcao	:= Val(aContent[nAux1][4])
			cNumPC	:= aContent[nAux1][2]
			
			//Alterado por Daniel Bueno - 18.01.21
			For nI := 1 To nTentativ
				Conout("[MM425] - TENTATIVA " + cValToChar(nI) + " DE " + cValToChar(nTentativ))

				lTentativ := .F.
				lOpcVal := If(nOpcao >= 1 .And. nOpcao <= Len(aEventType), .T., .F.)

				If lOpcVal
					lTentativ := U_fIntegra( cNumPC, aEventType[nOpcao]) .And. ValType(cNumPC) == "C"
				Else
					Exit
				End

				If lTentativ
					Exit
				EndIf
			Next
			
			If !lTentativ	//!U_fIntegra( cNumPC, aEventType[nOpcao]) .And. ValType(cNumPC) == "C"	//Fim da alteracao - Daniel Bueno
				DbSelectArea("SC7")
				SC7->(DbSetOrder(1))
				If SC7->(DbSeek((cAlias2)->C7_FILIAL + cNumPC))
					While !SC7->(EOF()) .And. SC7->C7_NUM == cNumPC
						RecLock('SC7', .F.)
							SC7->C7_EMITIDO := 'X'
						SC7->(MsUnlock())
						SC7->(DbSkip())
					EndDo
				EndIf
				Z3B->(DbGoTo(aContent[nAux1][5]))
		        RecLock('Z3B',.F.)
		        	Z3B->Z3B_ENVIAD	:= 'X'
		        Z3B->(MsUnlock())
				If lOpcVal
					U_fConOut(ProcName(0), "Recno Z3B "  + cValToChar(aContent[nAux1][5]) + " OC " + AllTrim(aContent[nAux1][2]) + " falha no envio.", .t.)
					Conout(CRLF + "MM425 - OC " + AllTrim(aContent[nAux1][2]) + " falha no envio em " + AllTrim(Str(Seconds() - nTempo)) + "s (ENVIADOS " + AllTrim(Str(nAux1)) + " de " + AllTrim(Str(nCount)) + " REGISTROS)")
				Else
					U_fConOut(ProcName(0), "Recno Z3B "  + cValToChar(aContent[nAux1][5]) + " OC " + AllTrim(aContent[nAux1][2]) + " número do evento inválido.", .t.)
					Conout(CRLF + "MM425 - OC " + AllTrim(aContent[nAux1][2]) + " número do evento inválido em " + AllTrim(Str(Seconds() - nTempo)) + "s (ENVIADOS " + AllTrim(Str(nAux1)) + " de " + AllTrim(Str(nCount)) + " REGISTROS)")
				End
			Else
				DbSelectArea("SC7")
				SC7->(DbSetOrder(1))
				If SC7->(DbSeek((cAlias2)->C7_FILIAL + cNumPC))
					While !SC7->(EOF()) .And. SC7->C7_NUM == cNumPC
						RecLock('SC7', .F.)
						SC7->C7_EMITIDO := 'S'
						SC7->(MsUnlock())
						SC7->(DbSkip())
					EndDo
				EndIf
				Z3B->(DbGoTo(aContent[nAux1][5]))
		        RecLock('Z3B',.F.)
		        	Z3B->Z3B_ENVIAD	:= 'S'
		        Z3B->(MsUnlock())
				U_fConOut(ProcName(0), "Recno Z3B: "  + cValToChar(aContent[nAux1][5]) + " OC: " + AllTrim(aContent[nAux1][2]) + " Pedido: " + AllTrim(aContent[nAux1][3]) + " sucesso no envio.", .t.)
				Conout(CRLF + "MM425 - OC: " + AllTrim(aContent[nAux1][2]) + " Pedido: " + AllTrim(aContent[nAux1][3]) + " enviada em " + AllTrim(Str(Seconds() - nTempo)) + "s (ENVIADOS " + AllTrim(Str(nAux1)) + " de " + AllTrim(Str(nCount)) + " REGISTROS)")
			EndIf
		Else
			Z3B->(DbGoTo(aContent[nAux1][5]))
	        RecLock('Z3B',.F.)
	        Z3B->Z3B_ENVIAD	:= 'X'
	        Z3B->(MsUnlock())
			U_fConOut(ProcName(0), "Recno Z3B: "  + cValToChar(aContent[nAux1][5]) + " OC: " + AllTrim(aContent[nAux1][2]) + " Pedido: " + AllTrim(aContent[nAux1][3]) + " falha no envio.", .t.)
		EndIf
		(cAlias2)->(DbCloseArea())
		//(cAlias)->(DbSkip())
	Next nAux1
	//EndDo

Return
//-------------------------------------------------------------------------------
/*/{Protheus.doc} 425Mnt
Verifica se função principal já está em execução

@return
@author Vinicius Wille
@since 05/11/2018
/*/
//-------------------------------------------------------------------------------
User Function 425Mnt()
	Local aRotina	:= GetUserInfoArray() // Resultado: (Informações dos processos)
	Local lRet		:= .T.
	Local cThreadId := cValToChar(ThreadID())
	Local nR

	For nR := 1 to Len(aRotina)
		//Verifica se o fonte está na pilha de chamadas
		If "MM425" $ Upper(AllTrim(aRotina[nR][5])) .Or. "MM425" $ Upper(AllTrim(aRotina[nR][11])) .Or. "425" $ Upper(AllTrim(aRotina[nR][5])) .Or. "425" $ Upper(AllTrim(aRotina[nR][11]))
			//Verifica se está na mesma filial que está tentando executar novamente
			If cFilAnt $ Upper(AllTrim(aRotina[nR][11]))
				//Verifica se é em outra thread
				If cThreadId <> AllTrim(cValToChar(aRotina[nR][3]))
					ConOut("MM425 - Thread " + cThreadId + " | Rotina já está em execução, esta thread será encerrada")
					lRet	:= .F.
				EndIf
			EndIf
		EndIf
	Next

Return(lRet)

/*/{Protheus.doc} Limbo
	(entrada de OCs que ficaram no limbo)
	@type  Static Function
	@author user
	@since 12/11/2021
	@version version
	@param param_name, param_type, param_descr
	@return return_var, return_type, return_description
	@example
	(examples)
	@see (links_or_referencLimbo
/*/
Static Function Limbo()
Local cAlias := GetNextAlias()
Local nCount := 0

	BeginSql Alias cAlias
	%NoParser%

	SELECT C7_FILIAL, C7_NUM, C7_MMITV
	  FROM %Table:SD1% SD1 (NOLOCK)
	  JOIN %Table:SC7% SC7 (NOLOCK) ON C7_FILIAL = D1_FILIAL AND C7_NUM = D1_PEDIDO AND C7_ITEM = D1_ITEMPC AND SC7.D_E_L_E_T_ != '*'
							  AND NOT EXISTS (SELECT 1 
											    FROM Z3B010 Z3B (NOLOCK) 
											   WHERE Z3B_FILIAL = C7_FILIAL 
												 AND Z3B_C7NUM = C7_NUM
												 AND Z3B_NOPC = '7'
												 AND Z3B_DATAU >= D1_DTDIGIT + '000000' 
												 AND Z3B.D_E_L_E_T_ != '*')
	 WHERE D1_FILIAL BETWEEN '' AND 'Z'
	   AND D1_DTDIGIT = CONVERT(VARCHAR(8), GETDATE(), 112)
	   AND SD1.D_E_L_E_T_ != '*'

	EndSql

	(cAlias)->(DBEval({|| nCount++}))
	(cAlias)->(DBGoTop())

	Conout(CRLF + "MM425 - Thread " + cValToChar(ThreadID()) + " | " + CValToChar(nCount) + " regitro(s) no limbo"   )	

	If !(cAlias)->(Eof())
		DbSelectArea("Z3B")

		While !(cAlias)->(Eof())
			Begin Transaction

			RecLock('Z3B',.T.)
				Z3B->Z3B_FILIAL	:= (cAlias)->C7_FILIAL
				Z3B->Z3B_C7NUM	:= (cAlias)->C7_NUM
				Z3B->Z3B_PVMM	:= (cAlias)->C7_MMITV
				Z3B->Z3B_NOPC	:= "6" //PURCHASE_ORDER_SUPPLIER_BILLING_SYM_CHECK
				Z3B->Z3B_ENVIAD	:= 'N'
			Z3B->(MsUnlock())	

			RecLock('Z3B',.T.)
				Z3B->Z3B_FILIAL	:= (cAlias)->C7_FILIAL
				Z3B->Z3B_C7NUM	:= (cAlias)->C7_NUM
				Z3B->Z3B_PVMM	:= (cAlias)->C7_MMITV
				Z3B->Z3B_NOPC	:= "7" //PURCHASE_ORDER_SUPPLIER_BILLING_SYM_INPUT
				Z3B->Z3B_ENVIAD	:= 'N'
			Z3B->(MsUnlock())	

			End Transaction

			(cAlias)->(DBSkip())
		End
	End

	(cAlias)->(DBCloseArea())
Return Nil
