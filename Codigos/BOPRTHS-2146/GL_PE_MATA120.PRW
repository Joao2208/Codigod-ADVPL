#include "rwmake.ch"
#include "topconn.ch"
#include "totvs.ch"
#include "protheus.ch"
/*---------------------------------------------------------------------------+
!                         FICHA TECNICA DO PROGRAMA                          !
+----------------------------------------------------------------------------+
!   DADOS DO PROGRAMA                                                        !
+------------------+---------------------------------------------------------+
!Tipo              ! Rotina	                                                 !
+------------------+---------------------------------------------------------+
!Modulo            ! FAT - Faturamento                                       !
+------------------+---------------------------------------------------------+
!Nome              ! P.E. MATA120/MATA121									 !
+------------------+---------------------------------------------------------+
!Descricao         ! P.E. relacionados ao MATA120							 !
+------------------+---------------------------------------------------------+
!Autor             ! GoLive\0/Gisele Morais		                             !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 14/01/2013            	                                 !
+------------------+--------------------------------------------------------*/

/*------------------------------------------------------------------------+
! Funï¿½ï¿½o    ! MT120C1D  ! Autor ! Gisele Morais   	 ! Data !  14/01/2013 !
+-----------+-----------+-------+--------------------+------+-------------+
! Descricao ! P.E. Acrescenta elementos no array dos dados.     		  !
+-----------+------------------------------------------------------------*/
User Function MT120C1D
Local aRetDados := PARAMIXB

	If Alias() == 'SC1'
		Aadd(aRetDados, SC1->C1_FORNECE)
	ElseIf Alias() == 'SC3'
		Aadd(aRetDados, SC3->C3_FORNECE)
	EndIf
Return(aRetDados)

/*------------------------------------------------------------------------+
! Funï¿½ï¿½o    ! MT120C1C  ! Autor ! Gisele Morais   	 ! Data !  14/01/2013 !
+-----------+-----------+-------+--------------------+------+-------------+
! Descricao ! P.E. Acrescenta os tï¿½tulos das colunas acrescidas.		  !
+-----------+------------------------------------------------------------*/
User Function MT120C1C
Local aRetTitle := PARAMIXB

	If Alias() == 'SC1'
		Aadd(aRetTitle, RetTitle('C1_FORNECE'))
	ElseIf Alias() == 'SC3'
		Aadd(aRetTitle, RetTitle('C3_FORNECE'))
	Endif

Return(aRetTitle)

/*------------------------------------------------------------------------+
! Funï¿½ï¿½o    ! A120F4FI  ! Autor ! Gisele Morais   	 ! Data !  14/01/2013 !
+-----------+-----------+-------+--------------------+------+-------------+
! Descricao ! P.E. Disponibiliza Filtro em Tabelas SC1 e SC3.	  		  !
+-----------+------------------------------------------------------------*/
User Function  A120F4FI
Local aRetFiltro := {}
Local cQry	     := ""

	/*O retorno e um array contendo a seguinte estrutura - Estrutura do array:
	1 - String - Filtro no SC1 para ISAM ( Sintaxe xBase )
	2 - String - Filtro no SC1 para SQL ( Sintaxe SQL ) //cQuery  += aFiltro[ 2 ] + " AND "
	3 - String - Filtro no SC3 para ISAM ( Sintaxe xBase )
	4 - String - Filtro no SC3 para SQL ( Sintaxe SQL )
	Nao e necessario definir todos os elementos do array.*/

	cQry := "C1_QUJE<>C1_QUANT AND C1_FORNECE='" + ca120Forn + "'

	Aadd(aRetFiltro, 	' '  )//[1]
	Aadd(aRetFiltro, 	cQry )//[2]
	Aadd(aRetFiltro, 	' '  )//[3]
	Aadd(aRetFiltro, 	' '  )//[4]

Return(aRetFiltro)

/*------------------------------------------------------------------------+
! Funï¿½ï¿½o    ! MT120MAK  ! Autor ! Gisele Morais   	 ! Data !  14/01/2013 !
+-----------+-----------+-------+--------------------+------+-------------+
! Descricao ! P.E. Rotina do usuario para adicionar campos				  !
+-----------+------------------------------------------------------------*/
User Function MT120MAK
Local aRetTitle := PARAMIXB
Local aCampos   := {}

	If aRetTitle[1] == 'SC1'
		Aadd(aCampos,"C1_FORNECE")
		Aadd(aCampos,"C1_ESPECIA")
	Endif

Return(aCampos)

/*------------------------------------------------------------------------+
! Funï¿½ï¿½o    ! A120PIDF  ! Autor ! Gisele Morais   	 ! Data !  14/01/2013 !
+-----------+-----------+-------+--------------------+------+-------------+
! Descricao ! P.E. Disponibiliza Filtro em Tabelas SC1 e SC3.	  		  !
+-----------+------------------------------------------------------------*/
User Function A120PIDF
Local aFiltro := {}//-- Validaï¿½ï¿½es do Usuario
Local cFilter := ""

	/*Estrutura do array
	1 - String - Filtro no SC1 para ISAM ( Sintaxe xBase )
	2 - String - Filtro no SC1 para SQL ( Sintaxe SQL para futura implementaï¿½ao )*/
	cFilter := "C1_QUJE<>C1_QUANT .And. C1_FORNECE='" + ca120Forn + "'
	Aadd(aFiltro, 	cFilter	)//[1]

Return(aFiltro)

/*------------------------------------------------------------------------+
! Funï¿½ï¿½o    ! MT120FIM  ! Autor ! Gisele Morais   	 ! Data !  24/01/2013 !
+-----------+-----------+-------+--------------------+------+-------------+
! Descricao ! P.E. se encontra no final da funï¿½ï¿½o A120PEDIDO			  !
+-----------+------------------------------------------------------------*/
User Function MT120FIM

    Local nOpcao := PARAMIXB[1]   // Opï¿½ï¿½o Escolhida pelo usuario
    Local cNumPC := PARAMIXB[2]   // Numero do Pedido de Compras
    Local nOpcA  := PARAMIXB[3]   // Indica se a aï¿½ï¿½o foi Cancelada = 0  ou Confirmada = 1.
    local aArea := GetArea()
    local aSC7 := SC7->(GetArea())
    
    local aEventType:= {'PURCHASE_ORDER_SEARCHED_PROTHEUS', 'PURCHASE_ORDER_VIEWED_PROTHEUS', 'PURCHASE_ORDER_CREATED_PROTHEUS', 'PURCHASE_ORDER_UPDATED_PROTHEUS', 'PURCHASE_ORDER_CANCELED_PROTHEUS'}
    Local cQuery    := "", cQryZ3B := ""
	Local cAls      := "", cAlsZ3B := ""
	Local nRegZ3B   := 0
	Local cAutEmp	:= GetNewPar("MM_EMPZ3B","01")
	Local cBlqFil	:= GetNewPar("MM_BFILZ3B","010191")

    If nOpcA == 1 .Or. l120Auto
		If cEmpAnt $ cAutEmp //Adicionado Lucilene SMSTI - 30/04/2021- Projeto Nimbi
			if !cFilAnt $ cBlqFil
				cAlsZ3B := GetNextAlias()

				cQryZ3B := " SELECT C7_FILIAL FILIAL, C7_NUM NUM, C7_MMITV MMITV, C7_MMIDNIM NIMBI" + CRLF
				cQryZ3B += " FROM " + RetSQLName("SC7") + " (NOLOCK)" + CRLF 
				cQryZ3B += " WHERE C7_FILIAL = '" + xFilial("SC7") + "'" + CRLF 
				cQryZ3B += " AND C7_NUM = '" + cNumPC + "'" 

				TcQuery cQryZ3B New Alias &cAlsZ3B

				Count To nRegZ3B

				DbSelectArea(cAlsZ3B)
				(cAlsZ3B)->(DbGoTop())

				If (nRegZ3B > 0)
					If (Empty(Alltrim((cAlsZ3B)->NIMBI))) //Pedidos do Nimbi não devem ir para a fila do Protal Fornecedor
						If (SubStr(cNumPC, 1, 1) != "N")
							DbSelectArea('Z3B')
							RecLock('Z3B',.T.)
								Z3B->Z3B_FILIAL	:= (cAlsZ3B)->FILIAL
								Z3B->Z3B_C7NUM	:= (cAlsZ3B)->NUM
								Z3B->Z3B_PVMM	:= (cAlsZ3B)->MMITV
								Z3B->Z3B_NOPC	:= cValToChar(nOpcao)
								Z3B->Z3B_ENVIAD	:= 'N'
							Z3B->(MsUnlock())
						EndIf
					EndIf
				EndIf
				
				(cAlsZ3B)->(DbCloseArea())
			Endif
		End

        RestArea(aSC7)
    	//Incluir ou Alterar
    	If nOpcao == 3 .Or. nOpcao == 4
    	    /*---------------------------------------------------------------------------------------------+
    	    !	Gravar Historico Agrupamento (Gisele - 25/01/13)                                           !
    	    !	Arredondar a quantidade de itens de acordo com o Controle de Embalagens (Gisele - 08/02/13)!
    	    +---------------------------------------------------------------------------------------------*/
    		U_ACOM002(cNumPC)
    //		U_ACOM005(cNumPC,nOpcao) //Calcular a diferenca do Controle de Embalagens (Gisele - 12/02/13)
    //		U_ACOM004(cNumPC) //Gravar Pedido de Venda e Item de Venda (Gisele - 08/02/13)
    		If !IsinCallStack("u_NGERAPC") //Lucilene SMSTI 10.05.2021.
				U_MM110(cNumPC, aEventType[nOpcao])		// Gravar arquivo PDF do pedido de compras -- 14/09/2016 -- Mauricio
			Endif
    	ElseIf nOpcao == 5
    		U_ACOM003(cNumPC) //Excluir Historico Agrupamento (Gisele - 25/01/13)
    		U_ACOM006(cNumPC) //Ao excluir PC, incluir novo fornecedor aos itens excluidos da SC (Gisele - 18/02/12)

			//Alterado por Daniel Bueno - 05/2021
			If (cEmpAnt == '01')
				If (SC7->C7_MMGS == '1')
					cAls := GetNextAlias()

					cQuery := " SELECT R_E_C_N_O_ RECZ14" + CRLF
					cQuery += " FROM " + RetSQLName("Z14") + " (NOLOCK)" + CRLF 
					cQuery += " WHERE Z14_FILIAL = '" + SC7->C7_FILIAL + "'" + CRLF
					cQuery += " AND Z14_NUMOC = '" + SC7->C7_NUM + "'" + CRLF 
					cQuery += " AND D_E_L_E_T_ <> '*'"

					TcQuery cQuery New Alias &cAls

					DbSelectArea(cAls)
					(cAls)->(DbGoTop())

					While !(cAls)->(EOF())
						DbSelectArea("Z14")
						Z14->(DbGoTo((cAls)->RECZ14))

						Reclock("Z14", .F.)
							Z14->Z14_STATUS := "4"
							Z14->Z14_STACOT := "2"
							Z14->Z14_NUMOC  := ""
							Z14->Z14_ITOC   := ""
						Z14->(MsUnLock())

						(cAls)->(DbSkip())
					End

					(cAls)->(DbCloseArea())
				EndIf
			EndIf
    	EndIf
    	
    EndIf

    RestArea(aArea)
Return

/*------------------------------------------------------------------------+
! Funï¿½ï¿½o    ! MT120OK 	! Autor ! Gisele Morais   	 ! Data !  04/02/2013 !
+-----------+-----------+-------+--------------------+------+-------------+
! Descricao ! P.E. Validaï¿½ï¿½es Especï¿½ficas de Usuï¿½rio					  !
+-----------+------------------------------------------------------------*/
User Function  MT120OK()
Local lOk        := .T.
Local nPosPrd    := aScan(aHeader,{|x| AllTrim(x[2]) == "C7_PRODUTO"})
Local nPosNumSC  := aScan(aHeader,{|x| AllTrim(x[2]) == "C7_NUMSC"})
Local nPosItemSC := aScan(aHeader,{|x| AllTrim(x[2]) == "C7_ITEMSC"})
Local nPosEspeci := aScan(aHeader,{|x| AllTrim(x[2]) == "C7_ESPECIA"})
Local cNumSC     := ''
Local cAux       := ''
Local nQtdSC     := 0
Local nX         := 0
Local nEspec	 := 0
Local nComum	 := 0

lRet := U_A0212A()
If  !lRet
	Return(.F.)
EndIf
	If Alltrim(FunName()) == "MATA121"

		SA2->(DbSetOrder(1))
		SA2->(DbSeek(xFilial("SA2") + cA120Forn ))
		cAgrupa := SA2->A2_AGRUPSC

		If !Empty(Alltrim(cA120Forn)) .And. cAgrupa == '2'

			//Permitir apenas uma 1SC x 1PV para Fornecedores marcados para nao agrupar SC
			For nX :=1 To Len( aCols )
				If ( !aCols[nx][Len(aCols[nX])] .And. !Empty(aCols[nX][nPosPrd]) )

					cNumSC := aCols[nX][nPosNumSc]

					If cAux <> cNumSC
						nQtdSC++
						cAux := cNumSC
					EndIf

					If nQtdSC > 1
						lOk := .F.
					ElseIf nQtdSC == 1
						lOk := .T.
                    EndIf
				EndIf
			Next nX
			If !lOk
				MsgInfo("Este Fornecedor não permite agrupar Solicitação de Compra." , "Aviso!" )
			EndIf
        EndIf
   EndIf
	lOk := U_A020801()
Return lOk

/*/{Protheus.doc} MT120PCOL
P.E. O ponto de entrada MT120PCOL e utilizado para validar a
inclusao do pedido de compra (MATA120) antes da validacao do modulo     
SIGAPCO (validacao de bloqueio). Linha a linha dos itens do pedido
@type function
@author Gisele Morais
@since 28/02/2013
@return logical, Retorna .T. caso não tenha bloqueio e .F. para realizar bloqueio
/*/
User Function MT120PCOL
	local lOk := .t.
	local nPosItem     := aScan(aHeader, {|aItem| AllTrim(aItem[2]) == "C7_ITEM"})
	local nPosNumPV    := aScan(aHeader, {|aItem| AllTrim(aItem[2]) == "C7_MMNUMPV"})
	local nPosItv      := aScan(aHeader, {|aItem| AllTrim(aItem[2]) == "C7_MMITV"})
	local nPosItPV     := aScan(aHeader, {|aItem| AllTrim(aItem[2]) == "C7_MMITPV"})
	local nPosCusto    := aScan(aHeader, {|aItem| AllTrim(aItem[2]) == "C7_CUSTOMM"})
	local nPosObs      := aScan(aHeader, {|aItem| AllTrim(aItem[2]) == "C7_OBS"})
	local nPosEspec    := aScan(aHeader, {|aItem| AllTrim(aItem[2]) == "C7_ESPECIA"})
	local nPosOper     := aScan(aHeader, {|aItem| AllTrim(aItem[2]) == "C7_OPER"})
	local nPosOperS    := aScan(aHeader, {|aItem| AllTrim(aItem[2]) == "C7_OPERS"})
	Local nPosSC	   := aScan(aHeader, {|aItem| AllTrim(aItem[2]) == "C7_NUMSC"}) //Adicionado Lucilene SMSTI 30/04/2021 - Projeto Nimbi
	Local nPosISC	   := aScan(aHeader, {|aItem| AllTrim(aItem[2]) == "C7_ITEMSC"}) 
	local cObs		   //:= AllTrim(aCols[N, nPosCusto])
	
	local cMsgEsp := "| Preco com desconto da lista de oportunidades ou aplicado pelo diretor comercial |"
	local cMsgIncent := " Nao recolhimento da ST conforme Regime Especial 5.392/2015 - DOU 28/12/2015 "
	local cCodTarket := "000363"
	local cMsgTarket := " | Desconto adicional concedido pela diretoria comercial da Tarkett. Desconto 5% (ou 7%) autorizado Marco Cordeiro."
	
	Do Case
		Case Type("aCols") <> "A" 
			Help(,,"MT120PCOL",,"aCols não é um array!",1,0,,,,,,{"Abra um chamado com o log dessa ocorrência!"})
			Return .F.
		Case Len(aCols) == 0
			Help(,,"MT120PCOL",,"aCols de itens está vazio!",1,0,,,,,,{"Verifique se há itens válidos!"})
			Return .F.		
	End Case

	cObs := AllTrim(aCols[N, nPosCusto])	
	SC1->(DbSetOrder(1))
	SC1->(DbSeek(xFilial('SC1')+aCols[N, nPosSC]+aCols[N, nPosISC])) //força o posicionamento da SC1
	If !Empty(aCols[N,nPosSC]) //Lucilene SMSTI 3O/04/21
		aCols[N, nPosNumPV] := SC1->C1_PVMM
		aCols[N, nPosItv] := SC1->C1_PVMM
		aCols[N, nPosItPV] := StrZero(Val(SC1->C1_ITEM), TamSX3('C6_ITEM')[1])	// o numero de item da SC eh o MESMO da SC6 (com diferença de tamanho)
		aCols[N, nPosCusto] := SC1->C1_CUSTOMM
		aCols[N, nPosEspec] := SC1->C1_ESPECIA
	Endif
	aCols[N, nPosOperS] := aCols[N, nPosOper]
	
	// Se a primeiro caracter do grupo tributário for uma letra (regra informada pelo Marcelo Scandian)
	if IsAlpha(Left(SB1->B1_GRTRIB, 1)) .and. !(cMsgIncent $ cObs)
		cObs += cMsgIncent
	endif
	// Pedido com preco especial
	if !Empty(aCols[N,nPosSC]) .and. !Empty(SC1->C1_ESPECIA) .and. !(cMsgEsp $ cObs)
		cObs += cMsgEsp
	endif
	// Se for produto FADEMAC/TARKETT
	if AllTrim(cA120Forn) == cCodTarket .and. !(cMsgTarket $ cObs)
		 cObs += cMsgTarket
	endif
	
	If !cEmpAnt $ ('03')
		if !cFilAnt $ ('010191')
			aCols[N, nPosObs] := cObs
		endif
	End
	If !Empty(aCols[N,nPosSC]) //Lucilene SMSTI 3O/04/21
		RecLock("SC1", .f.)
		SC1->C1_PEDANT  := cA120Num		
		SC1->C1_ITPDANT := aCols[N, nPosItem]
		SC1->(MsUnlock())
	Endif
Return lOk

// Validacao da exclusao da OC
User Function MTA120EX()
    local lRet := .t.
    local lAutoExec := Type("oMainWnd") <> "O"
    local cMot
	Local cUser  := GetMV("MM_USERT1",.F.,"000423")
    
    if !lAutoExec
        // Se o usuario NAO for administrador, proibe o cancelamento via protheus
		// if !(PswAdmin( , ,RetCodUsr()) == 0)  -- Incluida validação para o time do t1 conseguir excluir OCs tbm -- Guilherme Froes 
        if !(PswAdmin( , ,RetCodUsr()) == 0 .or. __cUserID $ cUser) 
            lRet := .f.
            Alert("Exclusao de OCs deve ser realizada SOMENTE pelo Portal Fornecedor")
        endif
    else   
        cMot := U_fCanDel( SC7->C7_NUM )
        lRet := Empty(cMot)
        if !lRet
            Conout(cMot)
        endif
    endif
    
return lRet

/*----------+-------------------------------------------------------------+
! Descricao ! P.E. Continuar ou nao a inclusao, alteracao ou exclusao	    !
+-----------+------------------------------------------------------------*/
User Function MT120GRV
	local cNumPC 	:= PARAMIXB[1]
	local lInclui	:= PARAMIXB[2]
	local lAltera	:= PARAMIXB[3]
	local lExclui	:= PARAMIXB[4]
	local lAutoExec := Type("oMainWnd") <> "O"
	
	local nI				:= 0
	local lRet   	:= .t.
	local aArea		:= GetArea()	
	local nPosTrans	:= aScan(aHeader, {|aItem| aItem[2] == "C7_MMTRANS"})
	local nPosRedes	:= aScan(aHeader, {|aItem| aItem[2] == "C7_MMREDES"})
	
	local aTransp	:= {}
	
	local cMot      := ''
	
	if lInclui 
		aTransp := fGetTransp()
		for nI := 1 to Len(aCols)
			aCols[nI, nPosTrans] := aTransp[1]
			aCols[nI, nPosRedes] := aTransp[2]
		next nI
	endif
	
	RestArea(aArea)
return lRet

/*------------------------------------------------------------------------+
! Funï¿½ï¿½o    ! MA120E    ! Autor ! Gisele Morais   	 ! Data !  18/02/2013 !
+-----------+-----------+-------+--------------------+------+-------------+
! Descricao ! P.E. Valida exclusï¿½o de PC ou AE							  !
+-----------+------------------------------------------------------------*/
/*NAO FUNCIONA
User Function MA120E()
Local nOpcA  := PARAMIXB[1]		// Indica se a aï¿½ï¿½o foi Cancelada = 0  ou Confirmada = 1.
Local cNumPC := PARAMIXB[2]   	// Numero do Pedido de Compras
Local lRet   := .T.
	If  nOpcA == 1
	Endif
Return(lRet)
*/
/*------------------------------------------------------------------------+
! Funï¿½ï¿½o    ! MT120VSC  ! Autor ! Gisele Morais   	 ! Data !  14/01/2013 !
+-----------+-----------+-------+--------------------+------+-------------+
! Descricao ! P.E. Manipular o Array em solicitaï¿½ï¿½o de Compras (F4)		  !
+-----------+------------------------------------------------------------*/
/*User Function MT120VSC
Local aSC    := ParamIxb[1]
Local nSC    := ParamIxb[2] //Se for opï¿½ï¿½o 1 ï¿½ Solicitaï¿½ï¿½o de Compras. Se for opï¿½ï¿½o 2, ï¿½ Contrato de Parceria
Local nPFor  := aScan(aHeader,{|x| AllTrim(x[2])=="C1_FORNECE"})
	If nSC = 1
	EndIf
Return aSC
*/
/*------------------------------------------------------------------------+
! Funï¿½ï¿½o    ! MT120VIT  ! Autor ! Gisele Morais   	 ! Data !  14/01/2013 !
+-----------+-----------+-------+--------------------+------+-------------+
! Descricao ! P.E. Manipular o Array em solicitaï¿½ï¿½o de Compras/Item (F5)  !
+-----------+------------------------------------------------------------*/
/*User Function MT120VIT
Local aSC := ParamIxb[1]
Local nSC := ParamIxb[2] //Se for opï¿½ï¿½o 1 ï¿½ Solicitaï¿½ï¿½o de Compras. Se for opï¿½ï¿½o 2, ï¿½ Contrato de Parceria
Return aSC
*/
/*------------------------------------------------------------------------+
! Funï¿½ï¿½o    ! MT120CPE  ! Autor ! Gisele Morais   	 ! Data !  14/01/2013 !
+-----------+-----------+-------+--------------------+------+-------------+
! Descricao ! P.E. Antes de entrar no Pedido de Compra	  				  !
+-----------+------------------------------------------------------------*/
/*User Function MT120CPE
Local nOpc   := PARAMIXB[1]
Local lCopia := PARAMIXB[2]
Return
*/
/*------------------------------------------------------------------------+
! Funï¿½ï¿½o    ! MT120EXC  ! Autor ! Gisele Morais   	 ! Data !  14/01/2013 !
+-----------+-----------+-------+--------------------+------+-------------+
! Descricao ! P.E. executado na exclusao								  !
+-----------+------------------------------------------------------------*/
/*
User Function MT120EXC
Local Area := GetArea()
RestArea(Area)
Return
*/

/*------------------------------------------------------------------------+
| Funï¿½ï¿½o    | MT120ISC  | Autor : Giancarlo(Golive)  ! Data !  26/02/2013 !
+-----------+-----------+-------+--------------------+------+-------------+
| Descricao | P.E. Manipula o acols do pedido de compras				  !
+-----------+------------------------------------------------------------*/
User Function  MT120ISC()
//	U_A0208()
	U_A0211C()
Return


// Funcao para buscar as transportadoras de entrega e redespacho
static function fGetTransp()

	local nI 				:= 0
	local cTransp		:= ''
	local cRedes		:= ''
	local cOrigem		:= ''
	local nPeso			:= 0
	local nMedMax		:= 0
	local cCEP 			:= ''
	local aPrd          := {}
    local cMenuFre      := ''
    local cTabFre		:= ''
    local cLojaMM		:= ''
    
	local nPosNumSC	:= aScan(aHeader, {|aIt| AllTrim(aIt[2]) == "C7_NUMSC" })
	local nPosItSC	:= aScan(aHeader, {|aIt| AllTrim(aIt[2]) == "C7_ITEMSC" })
	
	local cWhere		:= ""
	local cQry 			:= ""
	local cChave		:= ""
	local cAls				:= GetNextAlias()
	local aArea			:= GetArea()
	
	local cMailAdm		:= SuperGetMV("MM_0202ADM", , "protheus@madeiramadeira.com.br;logistica7@madeiramadeira.com.br")
	
	for nI := 1 to Len(aCols)
		cWhere += " ( C1_NUM = '" + aCols[nI, nPosNumSC] + "' AND C1_ITEM = '" + aCols[nI, nPosItSC] + "' ) OR"	
	next nI
	cWhere := Left(cWhere, Len(cWhere) - 2)

	if Empty(cWhere)
		RestArea(aArea)
		return
	endif
	
    cQry := " SELECT " +;
			"    A2_MMENTRE, A2_MMTZZ9, A2_TRANSP, " +;
			"    LEFT(LTRIM(C5_CEPE + C5_CEP + A1_CEPE + A1_CEP), 8) CEP, C5_LOJACOM, " +; 
			"    it.id_menufrete menufrete, it.id_tabelafrete tabfrete, it.transp, " +;
			"    C1_QUANT, C1_PRODUTO, B1_PESO, B1_MMEDMAX, C5_NUM " +;
			" FROM " +;
			" 	" + RetSQLName("SC1") + " SC1 (nolock) " +;
			" 	INNER JOIN " + RetSQLName("SB1") + " SB1 (nolock) ON B1_FILIAL = '" + xFilial("SB1") + "' AND B1_COD = C1_PRODUTO " +;
			" 	INNER JOIN " + RetSQLName("SC5") + " SC5 (nolock) ON C5_FILIAL = '" + xFilial("SC5") + "' AND C5_NUM = C1_PVMM " +;
			"   INNER JOIN " + RetSQLName("SC6") + " SC6 (nolock) ON C6_FILIAL = '" + xFilial("SC6") + "' AND C6_NUM = C1_PVMM AND C6_PRODUTO = C1_PRODUTO " +;
			"   LEFT JOIN items_do_pedido_de_venda it (nolock) ON C6_NUM = it.pedido AND C6_PRODUTO = it.cod_produto " +;
			" 	INNER JOIN " + RetSqlName("SA1") + " SA1 (nolock) ON A1_FILIAL = '" + xFilial("SA1") + "' AND A1_COD = C5_CLIENTE AND A1_LOJA = C5_LOJACLI " +;
			" 	INNER JOIN " + RetSqlName("SA2") + " SA2 (nolock) ON A2_FILIAL = '" + xFilial("SA2") + "' AND A2_COD = C1_FORNECE AND A2_LOJA = C1_LOJA " +;
			" WHERE " +;
			" 	SC1.D_E_L_E_T_ = '' " +;
			" 	AND SC1.C1_FILIAL = '" + xFilial("SC1") + "' " +;
			" 	AND ( " + cWhere + " ) "
						
	TCQuery cQry new alias &cAls
	
	if AllTrim((cAls)->A2_MMTZZ9) != 'S'
	   cTransp := (cAls)->A2_TRANSP
	else
        // Se for transp RedeHome
        if !Empty((cAls)->transp)
            aTransp := {PadL((cAls)->transp, TamSX3("A4_COD")[1], '0'), ''}
        else
            cOrigem := (cAls)->A2_MMENTRE
			If !Empty((cAls)->CEP) .and. Alltrim((cAls)->CEP) != "XXXXXXXX"
            	cCEP := (cAls)->CEP
			Else
				DbSelectArea("SC5")
				DbSetOrder(1)
				SC5->(DbSeek(xFilial("SC5") + Alltrim((cAls)->C5_NUM)) )
				//Escolha de CEP a ser utilizado
				IF !Empty(SC5->C5_CEPE) .AND. SC5->C5_CEPE != "XXXXXXXX"
					cCEP := SC5->C5_CEPE
				ELSEIF !Empty(SC5->C5_CEP) .AND. SC5->C5_CEP != "XXXXXXXX"
					cCEP := SC5->C5_CEP
				ELSEIF !Empty(Posicione("SA1",1,xFilial("SA1")+SC5->C5_CLIENTE,"A1_CEPE"))
					cCEP := Posicione("SA1",1,xFilial("SA1")+SC5->C5_CLIENTE,"A1_CEPE")
				ELSEIF !Empty(Posicione("SA1",1,xFilial("SA1")+SC5->C5_CLIENTE,"A1_CEP"))
					cCEP := Posicione("SA1",1,xFilial("SA1")+SC5->C5_CLIENTE,"A1_CEP")
				ENDIF
			EndIf
            cMenuFre := (cAls)->menufrete
            cTabFre := (cAls)->tabfrete
            cLojaMM := IIF((cAls)->C5_LOJACOM == '99', '', (cAls)->C5_LOJACOM)
            while !(cAls)->(eof())
                nPeso += (cAls)->C1_QUANT * (cAls)->B1_PESO
                nMedMax := IIF((cAls)->B1_MMEDMAX > nMedMax, (cAls)->B1_MMEDMAX, nMedMax)
                aAdd(aPrd, AllTrim((cAls)->C1_PRODUTO))
               (cAls)->(dbSkip())
            enddo
            aTransp := U_MM103(cOrigem, cCEP, nPeso, nMedMax, aPrd, cMenuFre, cTabFre, cLojaMM, aCols[1, nPosNumSC])
        endif
            
        cTransp := IIF(Empty(aTransp[2]), aTransp[1], aTransp[2])
        cRedes := IIF(Empty(aTransp[2]), aTransp[2], aTransp[1])
    endif
	(cAls)->(dbCloseArea())
	
	RestArea(aArea)
return {cTransp, cRedes}

User function fIntegra(cNumOC, cEvent)
	
    local cNexusToken	:= GetMV("MM_NEXTOK",,"Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyRW1haWwiOiJzaXN0ZW1hc0BtYWRlaXJhbWFkZWlyYS5jb20uYnIifQ.mDAETkhMqTs4cPqseCERRhUEkZjbvlpwGtEsTIL2-Rs")
    local cNexusURL		:= GetMV("MM_NEXAPI",,"")
    local cNexusPath	:= '/api/purchase-order/create'
        
    local lIntNexus     := GetMV("MM_INTNEX",,.f.)
    
    local aHeader			:= {}
    
    local lErr          := .f.
    local cMsg          := ''
	Local nSttsCode
    
    local lDebugWSC		:= GetMV("MM_DBGWSC", , .f.)
    Private oRestNexus	:= FWRest():new(cNexusURL)
    default cNumOC		:= ''
    default cEvent      := ''

	Public cEvenPO := ""		//Alterado por Daniel Bueno - 09.02.21
    
    aAdd(aHeader, "Content-Type: application/json; charset=utf-8")
    //ConOut("fIntegra - OC: " + cNumOC + " Evento: " + cEvent)
	cEvenPO := cEvent	//Alterado por Daniel Bueno - 09.02.21
    oOC := TPurchaseOrder():get(cNumOC)
    if oOC != nil .and. !Empty(oOC:id)
        U_fSendELK('/mr-mike/publish/' + cNumOC, cNumOC, cEvent, oOC, IIF(lErr, 'ERROR', 'INFO'), IIF(lErr, {cMsg}, {}), {'supplier', oOC:fornecedor})
		If Alltrim(cEvent) == 'PURCHASE_ORDER_SUPPLIER_BILLING_SYM_CHECK' .OR. Alltrim(cEvent) == 'PURCHASE_ORDER_VIEWED_PROTHEUS'
			FreeObj(oOC)
			oOC := nil		
			return !lErr
		EndIf
		cJSON := EncodeUTF8(FWJsonSerialize(oOC, .f.))
        
        aAdd(aHeader, 'Authorization:' + cNexusToken)
        // Envia para o Nexus - Smartlink
        oRestNexus:setPath(cNexusPath)
        oRestNexus:setPostParams(cJSON)
		CONOUT("payload ", cJSON)
		//Varinfo("oRestNexus",oRestNexus)
        if oRestNexus:Post(aHeader)
            cMsg := "TENTATIVA 1 : OC " + cNumOC + " enviada para o nexus as " + Time() + ". Retorno: " + oRestNexus:oResponseH:cStatusCode + ' ' + oRestNexus:GetResult()
			nSttsCode := IIF(Type("oRestNexus:oResponseH:cStatusCode") == "C", Val(oRestNexus:oResponseH:cStatusCode), IIF(Type("oRestNexus:oResponseH:cStatusCode") == "N",oRestNexus:oResponseH:cStatusCode,200))
			Conout(cMsg)
			IF nSttsCode >= 400
				lErr := .T.
				cMsg := "1 TENTATIVAS : OC " + cNumOC + " falhou no envio para o nexus as " + Time() + ". Retorno: " + IIF(Type("oRestNexus:oResponseH:cStatusCode") == "C", oRestNexus:oResponseH:cStatusCode, IIF(Type("oRestNexus:oResponseH:cStatusCode") == "N",Str(oRestNexus:oResponseH:cStatusCode),"509")) + ' ' + oRestNexus:GetLastError()
				Conout(cMsg)
			ENDIF
        else // reenvia
			if oRestNexus:Post(aHeader)
				cMsg := "TENTATIVA 2 : OC " + cNumOC + " enviada para o nexus as " + Time() + ". Retorno: " + oRestNexus:oResponseH:cStatusCode + ' ' + oRestNexus:GetResult()
				nSttsCode := IIF(Type("oRestNexus:oResponseH:cStatusCode") == "C", Val(oRestNexus:oResponseH:cStatusCode), IIF(Type("oRestNexus:oResponseH:cStatusCode") == "N",oRestNexus:oResponseH:cStatusCode,200))
				Conout(cMsg)
				IF nSttsCode >= 400
					lErr := .T.
					cMsg := "2 TENTATIVAS : OC " + cNumOC + " falhou no envio para o nexus as " + Time() + ". Retorno: " + IIF(Type("oRestNexus:oResponseH:cStatusCode") == "C", oRestNexus:oResponseH:cStatusCode, IIF(Type("oRestNexus:oResponseH:cStatusCode") == "N",Str(oRestNexus:oResponseH:cStatusCode),"509")) + ' ' + oRestNexus:GetLastError()
					Conout(cMsg)
				ENDIF
			else
				lErr := .T.
				cMsg := "2 TENTATIVAS : OC " + cNumOC + " falhou no envio para o nexus as " + Time() + ". Retorno: " + IIF(Type("oRestNexus:oResponseH:cStatusCode") == "C", oRestNexus:oResponseH:cStatusCode, IIF(Type("oRestNexus:oResponseH:cStatusCode") == "N",Str(oRestNexus:oResponseH:cStatusCode),"509")) + ' ' + oRestNexus:GetLastError()
				Conout(cMsg)
			EndIf
        endif
		//Varinfo("oRestNexus",oRestNexus)
        U_fConOut(ProcName(0), cMsg, .t.)
        
        if lDebugWSC
            U_fConOut(ProcName(0), "JSON Enviado|" + cJSON, .t.)
    	endif
        
        FreeObj(oOC)
        oOC := nil
    else		//Alterado por Daniel Bueno - 08.02.21
		If (Type("oOC") <> "U")
			cJSON := EncodeUTF8(FWJsonSerialize(oOC, .f.))
			U_fConout(ProcName(0), "OC " + cNumOC + " - Erro integracao (JSON): " + cJSON, .t.)
		Else
			U_fConout(ProcName(0), "OC " + cNumOC + " - Erro integracao: oOC nulo ou oOC:id vazio!", .t.)
		EndIf

		Conout("FIntegra passou longe")
		lErr := .T.
	endif
    
    FreeObj(oRestNexus)
    oRestNexus := nil
return !lErr

/*******************************************************************************|
|Funcao    | MT120FIL											     		    |
|-------------------------------------------------------------------------------|
|Descricao | PE para filtro das OCs das Guide Shops                             |
|-------------------------------------------------------------------------------|
|Autor     | Daniel Bueno														|
********************************************************************************/
User Function MT120FIL()
Local cRet := ""
Local cUsers := GetNewPar("MM_OCGS", "")

If (__cUserID $ cUsers)
    If MsgYesNo ("Deseja filtrar somente os itens das Guide Shops?")
        cRet := " C7_MMGS = '1'"
    EndIf
EndIf

Return cRet
