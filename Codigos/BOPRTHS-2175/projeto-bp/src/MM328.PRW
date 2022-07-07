#include "tbiconn.ch"
#include "topconn.ch"
#include 'protheus.ch'
#Include "Totvs.ch"

Static _cAlItBrid := Nil
Static _cAlias1 := Nil
Static _cAlias2 := Nil
Static _cAliasPed := Nil
Static _lLogPV := Nil

//-------------------------------------------------------------------------------
/*/{Protheus.doc} MM328
Importacao de pedidos de venda da bridge
Refactor
Marcelo Spilares Secate
22/10/2021
/*/
//-------------------------------------------------------------------------------
User Function MM328()
	// nome do parametro e funcao a ser executada
	Local aMyParFun 	:= {"MM_MM328", "MM328"}
	//Preparada o ambiente para chamada das threads
	RpcSetType(3)
	RpcSetEnv('01','010102')

    //MM328Job()
    //Return

	If U_328Mnt() //GetUserInfoArray
		If U_fCanRunX(aMyParFun) // Funcao que identifica se uma rotina pode ser executada em modo exclusivo
	  		PutMv(aMyParFun[1], 1)
			
            If GetMV("MM_328CCOT", .F., .F.)
                CorrigeCot() //corrige pedidos represados com erro de cotação
            End

            If GetMV("MM_AMRESGS", .F., .T.) //amarra reservas manuais aos pedidos showroom GS
                AmaResShow()
            End

            MM328Job() //Job para execucao do processo
			U_MM253Job()//IMPORTACAO DE PEDIDOS DE VENDA MARKETPLACE
			PutMv(aMyParFun[1], 0)
		End
	End
Return
//-------------------------------------------------------------------------------
/*/{Protheus.doc} MM328Job
Job para execucao do processo
@return
@author Vinicius Wille
@since 23/10/2018
/*/
//-------------------------------------------------------------------------------
Static Function MM328Job()
Local aUserInfo := {}
Local nSegIni := 0
Local nSegFim := 0
Local nSegTot := 0
Local nQtdReg := 0
Local nTamPed := TamSX3("C5_NUM")[1]
Local nTamCli := TamSX3("C5_CLIENTE")[1]
Local cOpcProt := "% " + FormatIn("0/2/3/4/5", "/")  + " %"
Local cSemafaro := cEmpAnt + "_" + cFilAnt + "_" + ProcName() 
Local cLjMktPlace := "% " + FormatIn(SuperGetMV("MM_328BLQF",,""), "/") + " %"
Local cJsonCab := ""
Local cUpdate := ""
Local nMaxThrd := GetMV("MM_PVTHRD", .F., 1)
Local nThrdAtiva := nMaxThrd
Local nThrdProc := 0
Local nT := 0
Local nRegEnv := 1
Local cAliasCab := GetNextAlias()
Local nThreadId := ThreadID()
Local cThreadId := CValToChar(nThreadId)
Local aPVProc := {} //pvs já enviados para threads
Local lContinua := .F.
Local lEnviado := .F.
Local jCabec
Local oExclusivo
Local lDebug := .F.

    U_fConOut("MM328","Thread " + cThreadId + " | Iniciando importacao pedidos de venda - " + DtoC(Date()) + " " + Time())

	//STATUS PROTHEUS
	//0-NOVO OK
	//1-LIDO E PROCESSADO OK
	//2-CANCELADO OK
	//3-RESERVA TEMPORARIA OK
	//4-ALTERACAO DE ITENS OK
	//5-ALTERACAO DE ENDERECO OK

    nSegIni := Seconds()

    BeginSql Alias cAliasCab 
    %NoParser%

	select cab.protheus, cab.pedido, cab.cliente, rtrim(cab.condicao_pagamento) condpg, cab.valorfrete, cab.despesa, cab.formpag, cab.especial, 
           cab.loja, cab.fatantecip, cab.formpagvt, cab.condvt, cab.pedidovt, cab.valorvt, cab.itemvt, cab.naogeraoc, cab.channel, cab.cancelado, 
	       rtrim(cab.cepentrega) cepent, 
           rtrim(cab.bairroentrega) bairroent, 
           rtrim(cab.cidadeentrega) cidadeent, 
           rtrim(cab.endeentrega) ENDERENT, 
           rtrim(cab.numeroentrega) numeroent, 
           rtrim(cab.complementoentrega) compent, cab.ufentrega ufent, cab.ibgeentrega ibgeent, cab.cep, 
           rtrim(cab.bairro) bairro, 
           rtrim(cab.cidade) cidade, 
           rtrim(cab.endereco) ENDERECO, 
           cab.numero, id_seller,
           rtrim(cab.complemento) complemento, cab.uf, cab.pedidopai, cab.pedmktplaceacompanha as pdmkacomp, cab.expresso, cab.custofrete, 
           cab.liberado, cab.pedmktplace, cab.lojamktplace, cab.bonificacao,cab.identrega, cab.redehome, cab.teste_ab, round(cab.juros,2) juros,
	       cli.protheus clistat, A3_COD, A3_COMIS,
           cli.endereco cli_end, cli.numero cli_num, cli.complemento cli_com, 
           cli.uf cli_uf, cli.cidade cli_cid, cli.bairro cli_bai, cli.cep cli_cep, cli.pais cli_pais, 
           cli.endeentrega cli_endent, cli.numeroentrega cli_nument, cli.complementoentrega cli_coment, 
           cli.ufentrega cli_ufent, cli.cidadeentrega cli_cident, cli.bairroentrega cli_baient, cli.cepentrega cli_cepent, 
	       cli.ibge cli_ibge,
           cab.desconto_incondicional
	  from cabecalho_pedidos_venda cab (nolock) 
	  join clientes cli (nolock) on cab.cliente = cli.codigo AND cli.protheus = 1 
      LEFT JOIN %Table:SA3% SA3 (NOLOCK) ON A3_FILIAL = %xFilial:SA3% AND A3_COD = rtrim(cab.lojamktplace) AND SA3.D_E_L_E_T_ != '*'
	 where cab.protheus in %Exp:cOpcProt%
     //where cab.protheus in ('9')
     //where cab.pedido in ('Z23365868')
	   and coalesce(cab.lojamktplace, 'XX') not in %Exp:cLjMktPlace%
       and ( (ltrim(rtrim(coalesce(id_seller, ''))) in ('','0'))
	    or ( (ltrim(rtrim(coalesce(id_seller, ''))) not in ('','0')) 
	          and coalesce(cab.channel,'') != '' 
              and (replace(cab.cepentrega,'-','') = '00099123'
                  or replace(cab.cep,'-','') = '00099123')     ) ) 
	    and cab.pedido not in (select pedido from items_do_pedido_de_venda it (nolock) where it.protheus = '0' and it.tipo_frete = 3 )
       //and cab.juros > 0
    //  and cab.pedido in ('Z30303070','Z30303071','Z30303072','Z30303073') //TESTE CASHBACK
       //and left(cab.pedido, 2) = 'Z3'
       //and cab.erro = '0' 
  order by cab.data_compra 

    EndSql

    nSegFim := Seconds()

    If (cAliasCab)->(Eof())
        nSegTot := nSegFim - nSegIni
        U_fConOut("MM328","Thread " + cThreadId + " | Nenhuma PV a ser gerado. Tempo para selecao dos pedidos na Bridge: " + cValToChar(nSegTot) + "s")    
    Else
        nSegTot := nSegFim - nSegIni
        U_fConOut("MM328","Thread " + cThreadId + " | Tempo para selecao dos pedidos na Bridge: " + cValToChar(nSegTot) + "s")    
        (cAliasCab)->(DBEval({|| nQtdReg++ }))
        (cAliasCab)->(DBGoTop())

        If nQtdReg < nMaxThrd
            nThrdAtiva := nQtdReg
        End
        
        If !lDebug
            For nT := 1 To nThrdAtiva
                StartJob("U_328Thrd", GetEnvServer(), .F., cSemafaro, nThreadId)
                ConOut("MM328 - Iniciando a thread " + cValtoChar(nT))
            Next nT
        End
        
        ConOut("MM328 - Verifcando se todas as threads montaram ambiente...")

        nThrdProc := 0
        aUserInfo := GetUserInfoArray()
        aEval(aUserInfo, {|x| If(x[05] == "U_328THRD", nThrdProc++,) })

        nT := 1

        ConOut("MM328 - " + CValToChar(nThrdProc) + " threads confirmadas, tentativa " + CValToChar(nT))
        
        If !lDebug
            While nThrdProc < nThrdAtiva .And. nT <= 10
                nT++

                nThrdProc := 0
                aUserInfo := GetUserInfoArray()
                aEval(aUserInfo, {|x| If(x[05] == "U_328THRD", nThrdProc++,) })

                ConOut("MM328 - " + CValToChar(nThrdProc) + " threads confirmadas, tentativa " + CValToChar(nT))
                Sleep(700)
            End
        End
    End

    While !(cAliasCab)->(Eof())
        lContinua := .F.
        jCabec := JsonObject():New()
        jCabec["pedido"] := PadR(AllTrim((cAliasCab)->pedido), nTamPed)
        lContinua := aScan(aPVProc, {|x| x == AllTrim(jCabec["pedido"]) }) == 0
        If lContinua
            aAdd(aPVProc, AllTrim(jCabec["pedido"]))
            jCabec["protheus"] := AllTrim((cAliasCab)->protheus)
            jCabec["cliente"] := PadR(AllTrim((cAliasCab)->cliente), nTamCli)
            jCabec["condpg"] := AllTrim((cAliasCab)->condpg)
            jCabec["valorfrete"] := Val(AllTrim((cAliasCab)->valorfrete))
            jCabec["despesa"] := Val(AllTrim((cAliasCab)->despesa))
            jCabec["formpag"] := AllTrim((cAliasCab)->formpag)
            jCabec["especial"] := AllTrim((cAliasCab)->especial)
            jCabec["loja"] := AllTrim((cAliasCab)->loja)
            jCabec["fatantecip"] := AllTrim((cAliasCab)->fatantecip)
            jCabec["formpagvt"] := AllTrim((cAliasCab)->formpagvt)
            jCabec["condvt"] := AllTrim((cAliasCab)->condvt)
            jCabec["pedidovt"] := AllTrim((cAliasCab)->pedidovt)
            jCabec["valorvt"] := Val(AllTrim((cAliasCab)->valorvt))
            jCabec["itemvt"] := AllTrim((cAliasCab)->itemvt)
            jCabec["naogeraoc"] := AllTrim((cAliasCab)->naogeraoc)
            jCabec["channel"] := AllTrim((cAliasCab)->channel)
            jCabec["cepent"] := StrTran(AllTrim((cAliasCab)->cepent),"-", "")
            jCabec["cep"] := StrTran(AllTrim((cAliasCab)->cep),"-", "")
            jCabec["mostruariogs"] := "N"

            If !Empty(jCabec["channel"])
                If (jCabec["cepent"] == "00099123" .Or. jCabec["cep"] == "00099123")
                    jCabec["mostruariogs"] := "S"
                End
            End
                   
            //jCabec["cep"] := StrTran(AllTrim((cAliasCab)->cep),"-", "")
            jCabec["bairro"] := AllTrim((cAliasCab)->bairro)
            jCabec["cidade"] := AllTrim((cAliasCab)->cidade)
            jCabec["endereco"] := AllTrim((cAliasCab)->ENDERECO)
            jCabec["numero"] := AllTrim((cAliasCab)->numero)
            jCabec["complemento"] := AllTrim((cAliasCab)->complemento)
            jCabec["uf"] := Upper(AllTrim((cAliasCab)->uf))

            //jCabec["cepent"] := StrTran(AllTrim((cAliasCab)->cepent),"-", "")
            jCabec["bairroent"] := Alltrim((cAliasCab)->bairroent)
            jCabec["cidadeent"] := AllTrim((cAliasCab)->cidadeent)
            jCabec["enderent"] := AllTrim((cAliasCab)->ENDERENT)
            jCabec["numeroent"] := AllTrim((cAliasCab)->numeroent)
            jCabec["compent"] := AllTrim((cAliasCab)->compent)
            jCabec["ufent"] := Upper(AllTrim((cAliasCab)->ufent))

            jCabec["ibgeent"] := AllTrim((cAliasCab)->ibgeent)                   

            jCabec["pedidopai"] := AllTrim((cAliasCab)->pedidopai)
            jCabec["pdmkacomp"] := AllTrim((cAliasCab)->pdmkacomp)
            jCabec["expresso"] := AllTrim((cAliasCab)->expresso)
            jCabec["custofrete"] := Val(AllTrim((cAliasCab)->custofrete))
            jCabec["liberado"] := AllTrim((cAliasCab)->liberado)
            jCabec["pedmktplace"] := AllTrim((cAliasCab)->pedmktplace)
            jCabec["lojamktplace"] := AllTrim((cAliasCab)->lojamktplace)
            jCabec["bonificacao"] := AllTrim((cAliasCab)->bonificacao)
            jCabec["identrega"] := AllTrim((cAliasCab)->identrega)
            jCabec["redehome"] := AllTrim((cAliasCab)->redehome)
            jCabec["clistat"] := (cAliasCab)->clistat          

            jCabec["teste_ab"] := AllTrim((cAliasCab)->teste_ab)
            jCabec["cancelado"] := AllTrim((cAliasCab)->cancelado)
            jCabec["A3_COD"] := (cAliasCab)->A3_COD
            jCabec["A3_COMIS"] := (cAliasCab)->A3_COMIS
            jCabec["juros"] := Round((cAliasCab)->juros,2)
            jCabec["id_seller"] := AllTrim((cAliasCab)->id_seller)
            jCabec["desconto_incondicional"] := Round((cAliasCab)->desconto_incondicional,2)
            
            cJsonCab := jCabec:ToJson()

            If lDebug
                //para debugar
                U_328Thrd(cSemafaro, nThreadId, lDebug, cJsonCab)
            Else
                lEnviado := IPCGo(cSemafaro, cJsonCab, .F.)
            
                While !lEnviado
                    If (nQtdReg - nRegEnv) > 3 .And. !(cAliasCab)->(Eof())
                        nThrdProc := 0
                        aUserInfo := GetUserInfoArray()
                        aEval(aUserInfo, {|x| If(x[05] == "U_328THRD", nThrdProc++,) })

                        If nThrdProc < nThrdAtiva
                            ConOut("MM328 - Subindo threads que cairam..." )

                            For nT := 1 To (nThrdAtiva - nThrdProc)
                                StartJob("U_328Thrd", GetEnvServer(), .F., cSemafaro, nThreadId)
                                ConOut("MM328 - Iniciando a thread " + cValtoChar(nT))
                            Next nT
                        End
                    End

                    Sleep(1000)
                    
                    lEnviado := IPCGo(cSemafaro, cJsonCab, .F.)
                End
            End
            
            ConOut("MM328 - Pedido " + cValtochar(nRegEnv) + " de " + cValToChar(nQtdReg) + " enviado" )
        End

        nRegEnv++

        FreeObj(jCabec)
        
        (cAliasCab)->(DBSkip())
    End

    (cAliasCab)->(DBCloseArea())

	aUserInfo := GetUserInfoArray()

	While aScan(aUserInfo, {|x| Upper(AllTrim(x[05])) == "U_328THRD"}) > 0//IPCCount(cSemafaro) > 0
		ConOut("MM328 - Aguardando threads finalizarem")
        If IPCCount(cSemafaro)
			lEnviado := IPCGo(cSemafaro, Nil, .T.)
		End
		Sleep(1000)
		aUserInfo := GetUserInfoArray()
	End

    nSegFim := Seconds()
    nSegTot := nSegFim - nSegIni

    ConOut("MM328 - " + cValToChar(nQtdReg) + " PVs em " + cValToChar(nSegTot) + ", média: " + cValToChar(nSegTot / nQtdReg))

    // Bloqueia os pedidos cujo cliente esteja divergente entre FC e protheus
    cUpdate := " UPDATE SC5010 SET C5_FATCOT='S', C5_CEP='XXXXXXXX', C5_CEPE='XXXXXXXX' "
    cUpdate += " FROM SC5010 SC5 LEFT JOIN cabecalho_pedidos_venda cab ON ( "
    cUpdate += "		cab.pedido = SC5.C5_NUM "
    cUpdate += "	) "
    cUpdate += "	WHERE "
    cUpdate += "		SC5.D_E_L_E_T_ = ''  "
    cUpdate += "	AND SC5.C5_EMISSAO > '20200101' "
    cUpdate += "	AND SC5.C5_NUM like 'Z%' "
    cUpdate += "	AND rtrim(SC5.C5_CLIENTE) <> rtrim(COALESCE(cab.cliente, '')) "
    //ConOut(cQuery)
    TCSQLEXEC(cUpdate)

    fChkIntegra()  

    oExclusivo := TMMExclusivo():New()  

	If GetMV("MM_328REGF", .F., .T.) .And. oExclusivo:Reservar("A410RegFat")
        ConOut("MM328 - Verificando pedidos com erro A410REGFAT...")
        A410RegFat()
        oExclusivo:Liberar() 
    End

	If GetMV("MM_328AJNP", .F., .T.) .And. oExclusivo:Reservar("AjNumPed")
        ConOut("MM328 - Verificando pedidos com erro NUMERO PV REPETIDO...")
        AjNumPed()
        oExclusivo:Liberar() 
    End

	If GetMV("MM_328ITIM", .F., .T.) .And. oExclusivo:Reservar("ItImpPVPar")
        ConOut("MM328 - Verificando itens em PVs importados parcialmente...")
        ItImpPVPar()
        oExclusivo:Liberar() 
    End    

	If GetMV("MM_328EXRE", .F., .T.) .And. oExclusivo:Reservar("ExcluiRes")
        ConOut("MM328 - Verificando reservas em pedidos cancelados e/ou excluidos...")
        ExcluiRes()
        oExclusivo:Liberar() 
    End     

	// verificar pedidos venda showroom com erros
	If GetMV("MM_PVSHOWR", .F., .T.) .And. oExclusivo:Reservar("PVShowRoom")
        ConOut("MM328 - Verificando pedidos venda showroom com erro na importação...")
        PVShowRoom()
        oExclusivo:Liberar() 
    End       

    If GetMV("MM_MM506ON", .F., .F.) .And. oExclusivo:Reservar("MM506")
        ConOut("MM328 - Verificando pedidos origem fornecedor com estoque disponivel e prazo 0...")
        StartJob("U_MM506", GetEnvServer(), .T., Nil, Decode64(AllTrim(GetMv("MM_UAGENDA"))))
        oExclusivo:Liberar()
        //U_MM506() //virar pedidos que sairam como VAO porem temos saldo em estoque e prazo é 0
    End    

	// Busca por pedidos que nao tenham OC ou reserva de estoque e corrige
	If GetMV("MM_FFIXLIM", .F., .T.) .And. oExclusivo:Reservar("fFixLimbo")
        ConOut("MM328 - fFixLimbo iniciando...")
        fFixLimbo()
        oExclusivo:Liberar() 
        ConOut("MM328 - fFixLimbo fim.")   
    End

    FreeObj(oExclusivo)
	
	U_fConOut("MM328", "Thread " + cValToChar(ThreadID()) + " | Finalizando importacao de PEDIDOS - " + DtoC(Date()) + " " + Time())
Return
//
User Function 328Thrd(cSemafaro, nThreadMae, lDebug, cJsonCab)
Local aUserInfo := {}
Local cThreadId := cValToChar(ThreadId())
Local lEnv := .F.
Local lRecebido := .F.
Local lSair := .F.

Default cJsonCab := ""
Default lDebug := .F.

	If Type("cFilAnt") == 'U'
		lEnv := RpcSetEnv('01', "010102")
	End

	If Type("cFilAnt") == 'U'
		ConOut("328Thrd - Thread " + cThreadId + " - Não montou ambiente")
        Return Nil
	End

    If ValType(_cAlItBrid) == "U"
        _cAlItBrid := GetNextAlias()
    End

    If ValType(_cAlias1) == "U"
        _cAlias1 := GetNextAlias()
    End

    If ValType(_cAlias2) == "U"
        _cAlias2 := GetNextAlias()
    End

    If ValType(_cAliasPed) == "U"
        _cAliasPed := GetNextAlias()
    End  

    If ValType(_lLogPV) == "U"
        _lLogPV := GetMV("MM_328LOGP", .F., .T.)
    End

    If lDebug
        ProcessaPV(cJsonCab, cThreadId)
    Else
        While !KillApp()
            lRecebido := IPCWaitEx(cSemafaro, 10000, @cJsonCab, @lSair)
            If lRecebido
                If lSair
                    ConOut("328Thrd - Thread " + cThreadId + " - Recebeu msg para sair.")
                    Exit
                Else
                    ProcessaPV(cJsonCab, cThreadId)
                End
            Else //caso tenha saido nos 10 segundos... 
                //ver se a thread mãe ainda está em processamento
                //se a thread mãe morreu, a filha tb morre
                //exit
                aUserInfo := GetUserInfoArray()
                If aScan(aUserInfo, {|x| x[03] == nThreadMae}) == 0
                    ConOut("328Thrd - Thread " + cThreadId + " - saindo pois não encontrou a thread mãe.")
                    Exit
                End
            End
        End
    End

    If Select(_cAlItBrid) > 0
        (_cAlItBrid)->(DBCloseArea())
        _cAlItBrid := Nil
    End

    If Select(_cAlias1) > 0
        (_cAlias1)->(DBCloseArea())
        _cAlias1 := Nil
    End

    If Select(_cAlias2) > 0
        (_cAlias2)->(DBCloseArea())
        _cAlias2 := Nil
    End

    If Select(_cAliasPed) > 0
        (_cAliasPed)->(DBCloseArea())
        _cAliasPed := Nil
    End     

    _lLogPV := Nil 

    If lEnv
        RpcClearEnv()
    End      
Return Nil
//
/*/{Protheus.doc} nomeStaticFunction
    (long_description)
    @type  Static Function
    @author user
    @since 25/10/2021
    @version version
    @param param_name, param_type, param_descr
    @return return_var, return_type, return_description
    @example
    (examples)
    @see (links_or_references)
/*/
Static Function ProcessaPV(cJCabec, cThreadId)
Local aCabec := {}
Local aItens := {}
Local aLinha := {}
Local aItensBrid := {}
Local acustonfield1 := {}
Local acustonfield2 := {}
Local acustonfield3 := {}
Local aArray := {}
Local aSM0
Local cPayLoad
Local cJErro := Nil
Local cFilBkp := cFilAnt
Local cFilAux := cFilBkp
Local cFatAntecip := ""
Local cNota := ""
Local cNotFat := SuperGetMV("MM_328BLCL",.F.,"064282/")
Local cArqLog
Local cMensagem := ""
Local cErro, cAno, cMes, cDia, cDataHora
Local cUpdate
Local cPedidoPai
Local cPedido
Local cMktJuros := SuperGetMV("MM_MKTJURO",,"")
Local lReservou := .F.
Local lErr := .F.
Local lSaiFila := .F.
Local lVldPgto := SuperGetMV("MM_328VPG",.F.,.T.)
Local lErroPgto := .F.
Local lResp
Local nSegIni := 0
Local nSegFim := 0
Local nSegTot := 0
Local nCusto := 0
Local nDespesa := 0
Local nI := 0
Local nPosCot := 0
Local jItem, jCotacao, jJson, jJson2,n2
Local jCabec := JsonObject():New()
Local oItem
Local oEst := TMMStock():New()
Local nTotalPed := 0

Local cMVRelServ := SuperGetMV("MV_RELSERV")
Local cMVRelaCnt := SuperGetMV("MV_RELACNT")
Local cMVRelaUsr := SuperGetMV("MV_RELAUSR" ,,"madeiramadeira")
Local cMVRelPsw  := SuperGetMV("MV_RELPSW")
Local cMVRelFrom := SuperGetMV("MV_RELFROM")

Local cQryCash, cAliasCash

// variaveis para controlar a geracao de erros de ExecAuto
Private lMsHelpAuto		:= .T.
Private lAutoErrNoFile	:= .T.
Private lMSErroAuto 	:= .F.

    cJErro := jCabec:FromJson(cJCabec)

    If ValType(cJErro) == "C"
        U_fConOut("MM328", "MM328 | ProcessaPV" + CRLF + cJErro, .T.)
        ConOut("MM328 | ProcessaPV: " + CRLF + cJErro)
        //Break
        FreeObj(jCabec)
        Return Nil
    End

    cPedido := Alltrim(jCabec["pedido"])
    cPedidoPai := Alltrim(jCabec["pedidopai"])    

    U_fConOut("MM328", "Thread " + cThreadId + " | Pedido " + cPedido + " sendo processado.")    

    nSegIni := Seconds()

    //De-Para channel/filial
    cFilAnt := U_MM552Fil(jCabec["channel"], cFilAnt)

    If Round(jCabec["valorfrete"],2) == Round(9999999.99,2)
        U_MM020(GetMV("MV_RELSERV"), GetMV("MV_RELACNT"), GetMV("MV_RELAUSR",,"madeiramadeira"), GetMV("MV_RELPSW"),;
                    GetMV("MV_RELFROM"), GetMV("MM_328MAIL"), "[ERRO PV] Pedido nao importado",;
                    "Nao foi importado o pedido abaixo devido a problemas com frete: <br> " +;
                        "Pedido" + cPedido )
        TCSqlExec("update cabecalho_pedidos_venda SET protheus='9',erro='1', mensagem='FRETE ERRADO' where pedido='" + cPedido +"'")
        //Break
        FreeObj(jCabec)
        cFilAnt := cFilBkp
        Return Nil
    End

    //Valida se o cashback esta rateado por pedido filho, remover tratativa quando corrigigem o cashback na bridge cabecalho_pedidos_venda
    IF jCabec["desconto_incondicional"] > 0
        cQryCash := " select pedidopai,desconto_incondicional,count(*) as qtd_pedidos from cabecalho_pedidos_venda(nolock)  "
        cQryCash += " where desconto_incondicional > 0 "
        cQryCash += " and pedidopai in(select pedidopai from cabecalho_pedidos_venda (nolock) where pedido = '"+cPedido+"') "
        cQryCash += " group by pedidopai,desconto_incondicional "
        cQryCash += " having count(*) > 1 "
        
        cAliasCash := GetNextAlias()
        TCQUERY cQryCash NEW ALIAS &cAliasCash

        IF (cAliasCash)->qtd_pedidos > 0
            TCSqlExec("update cabecalho_pedidos_venda SET protheus='9',erro='1', mensagem='CASHBACK NAO ESTA RATEADO' where pedidopai ='" + (cAliasCash)->pedidopai +"'")
            FreeObj(jCabec)
            cFilAnt := cFilBkp
            Return Nil        
        ENDIF
        (cAliasCash)->(DbCloseArea())
    ENDIF
    If jCabec["fatantecip"] == "1"
        cFatAntecip := "1" // Para ser filtrado por item em relacao a VAO
    ElseIf jCabec["fatantecip"] == "2"
        cFatAntecip := "2"
    ElseIf jCabec["bonificacao"] == "S"
        cFatAntecip := "3" // Para ser filtrado por item em relacao a VAO
    Else 
        cFatAntecip := "0" // Para ser filtrado por item em relacao a VAO
    End    

    Do Case
        Case jCabec["protheus"] == "0"//CASO FOR INCLUSAO NORMAL
            aCabec := {}
            aItens := {}
            aItensBrid := ItensBrid(cPedido, jCabec["protheus"])
            jCabec["itens"] := aItensBrid

            //ADAPTACAO TEMPORARIA DE PRODUTOS ESPECIAIS MARCELO SCANDIAN
            jCabec["prop"] := 0
            jCabec["total"] := 0
            aEval(aItensBrid, {|x| If("/" + Alltrim(x["produto"]) + "/" $ "/126653/126656/", jCabec["prop"] += x["quantidade"] * x["preco_unitario"],)})
            aEval(aItensBrid, {|x| jCabec["total"] += x["quantidade"] * x["preco_unitario"]})
            jCabec["prop"] := Round(jCabec["prop"],2)
            jCabec["total"] := Round(jCabec["total"],2)
            //FIM ADAPTACAO TEMPORARIA DE PRODUTOS ESPECIAIS MARCELO SCANDIAN

            jCabec["condpag"] := "001"
            If(jCabec["condpg"] == "1" .Or. Empty(jCabec["condpg"]))
                jCabec["condpag"] := "001"
            Else
                jCabec["condpag"] := jCabec["condpg"]
                If !Empty(Posicione('SE4', 1, xFilial('SE4') + jCabec["condpag"],"E4_MMCONV"))
                    jCabec["condpag"] := SE4->E4_MMCONV
                End
            End

            If jCabec["lojamktplace"] $ 'LO\AZ\RE\ZM\LA\MP\SU\CD\WC\PA\LU\EX\CA\BP\PF\CB\SH\RB\SF\AM\ML\WM\RD'
                jCabec["condpag"] :=  "045"
            End
            
            AADD(aCabec,{"C5_NUM"		, cPedido																		, Nil})
            AADD(aCabec,{"C5_TIPO"		, "N"																						, Nil})
            AADD(aCabec,{"C5_CLIENTE"	, jCabec["cliente"]																		, Nil})
            AADD(aCabec,{"C5_LOJACLI"	, "01"																						, Nil})
            AADD(aCabec,{"C5_CONDPAG"	, jCabec["condpag"]																			, Nil})
            AADD(aCabec,{"C5_TPFRETE"	, If(jCabec["mostruariogs"] == "S", "D", "C") 												, Nil})
            AADD(aCabec,{"C5_VOLUME1"	, 1																							, Nil})
            AADD(aCabec,{"C5_LOJACOM"	, jCabec["loja"]																		, Nil})
            AADD(aCabec,{"C5_FOMRPAG"	, If((jCabec["formpag"] == "0" .OR. jCabec["formpag"] == ""), "R$", jCabec["formpag"])		, Nil})
            AADD(aCabec,{"C5_REVISA" 	, '9'																						, Nil}) //Marca o PV como 'nao enviado ao portal'
            
            If !Empty(jCabec["lojamktplace"]) .And. !Empty(jCabec["pedmktplace"]) 
                AADD(aCabec,{"C5_INDPRES" 	, '2'			    																	, Nil}) //INDPRES 2-NÃO PRESENCIAL,NET

                If !Empty(jCabec["pedmktplace"])
                    aAdd(aCabec, {"C5_MMPEDMP", jCabec["pedmktplace"], Nil} )
                    aAdd(aCabec, {"C5_LOJACOM", jCabec["lojamktplace"], Nil} )
                    
                    If !Empty(jCabec["A3_COD"])
                        aAdd(aCabec, {"C5_VEND1"		, jCabec["A3_COD"], Nil} )
                        aAdd(aCabec, {"C5_COMIS1"		, jCabec["A3_COMIS"], Nil} )
                        aAdd(aCabec, {"C5_CODA1U"		, jCabec["lojamktplace"], Nil} )
                    Else
                        U_MM020(GetMV("MV_RELSERV"), GetMV("MV_RELACNT"), GetMV("MV_RELAUSR",,"madeiramadeira"),;
                                GetMV("MV_RELPSW"), GetMV("MV_RELFROM"),;
                                "protheus@madeiramadeira.com.br", "[MarketPlace] Importacao de pedido sem vendedor",;
                                "Nao foram encontrados vendedores para o pedido marketplace abaixo: <br> " +;
                                "Pedido MktPlace: " + jCabec["pedmktplace"] + "<br> Pedido Madeira: " + cPedido + "<br> Loja MktPlace: " + jCabec["lojamktplace"])
                    End
                End
            Else
                AADD(aCabec,{"C5_INDPRES" 	, '0'			    																	, Nil}) //INDPRES 0-Não se aplica
            End

            //ADAPTACAO TEMPORARIA DE PRODUTOS ESPECIAIS MARCELO SCANDIAN
            If jCabec["prop"] == 0//(cAlsQRA)->PROP == 0
                //AADD(aCabec,{"C5_DESPESA",jCabec["despesa"],Nil})
                nDespesa := jCabec["despesa"]
            Else
                jCabec["fator"] := jCabec["prop"] / jCabec["total"] //nFator := (cAlsQRA)->PROP/(cAlsQRB)->TOTAL
                //AADD(aCabec,{"C5_DESPESA",(jCabec["fator"] * jCabec["despesa"]/1.05) + (jCabec["despesa"]-(jCabec["fator"] * jCabec["despesa"])) ,Nil})
                nDespesa := (jCabec["fator"] * jCabec["despesa"]/1.05) + (jCabec["despesa"]-(jCabec["fator"] * jCabec["despesa"]))
                //AADD(aCabec,{"C5_DESPESA",(nFator * Val(AllTrim(aSC5[n1][6]))/1.05) + (Val(AllTrim(aSC5[n1][6]))-(nFator * Val(AllTrim(aSC5[n1][6])))) ,Nil})
            EndIf
            //FIM ADAPTACAO TEMPORARIA DE PRODUTOS ESPECIAIS MARCELO SCANDIAN

            If jCabec["juros"] > 0 .And. "/" + jCabec["lojamktplace"] + "/" $ cMktJuros
                nDespesa += jCabec["juros"]
            End

            AADD(aCabec,{"C5_DESPESA", nDespesa, Nil})

            AADD(aCabec,{"C5_TIPLIB"	,"1"							,Nil})
            AADD(aCabec,{"C5_ESPEC1"	,"VL"							,Nil})
            AADD(aCabec,{"C5_ESPECIA"	,jCabec["especial"]			,Nil})

            //ADAPTACAO TEMPORARIA DE PRODUTOS ESPECIAIS MARCELO SCANDIAN
            If jCabec["prop"] == 0
                //AADD(aCabec,{"C5_FRETE",Val(AllTrim(aSC5[n1][5])),Nil})
                AADD(aCabec,{"C5_FRETE",jCabec["valorfrete"],Nil})
            Else
                //nFator := (cAlsQRA)->PROP/(cAlsQRB)->TOTAL
                jCabec["fator"] := jCabec["prop"] / jCabec["total"]
                //AADD(aCabec,{"C5_FRETE",(nFator * Val(AllTrim(aSC5[n1][5]))/1.05) + (Val(AllTrim(aSC5[n1][5]))-(nFator * Val(AllTrim(aSC5[n1][5])))),Nil})
                AADD(aCabec,{"C5_FRETE",(jCabec["fator"] * jCabec["valorfrete"]/1.05) + (jCabec["valorfrete"]-(jCabec["fator"] * jCabec["valorfrete"])),Nil})            
            End
            //FIM ADAPTACAO TEMPORARIA DE PRODUTOS ESPECIAIS MARCELO SCANDIAN            
            
            AADD(aCabec,{"C5_FATANT"	,cFatAntecip									,Nil})
            AADD(aCabec,{"C5_VALORVT"	,jCabec["valorvt"]				,Nil})
            AADD(aCabec,{"C5_PEDVT"		,jCabec["pedidovt"]							,Nil})
            AADD(aCabec,{"C5_CONDVT"	,jCabec["condvt"]							,Nil})
            AADD(aCabec,{"C5_FORPGVT"	,jCabec["formpagvt"]							,Nil})
            AADD(aCabec,{"C5_ITEMVT"	,jCabec["itemvt"]							,Nil})
            AADD(aCabec,{"C5_ENDENT"	,jCabec["enderent"]							,Nil})
            AADD(aCabec,{"C5_BAIRROE"	,jCabec["bairroent"]							,Nil})
            AADD(aCabec,{"C5_CEPE"		,jCabec["cepent"]					,Nil})
            AADD(aCabec,{"C5_MUNE"		,jCabec["cidadeent"]							,Nil})
            AADD(aCabec,{"C5_ESTE"		,jCabec["ufent"]					,Nil})
            AADD(aCabec,{"C5_MMIBGEE"	,jCabec["ibgeent"]							,Nil})
            AADD(aCabec,{"C5_ENDEN"		,jCabec["endereco"]							,Nil})
            AADD(aCabec,{"C5_BAIRRO"	,jCabec["bairro"]							,Nil})
            AADD(aCabec,{"C5_CEP"		,jCabec["cep"]					,Nil})
            AADD(aCabec,{"C5_MUN"		,jCabec["cidade"]							,Nil})
            AADD(aCabec,{"C5_EST"		,jCabec["uf"]					,Nil})
            AADD(aCabec,{"C5_EXPRESS"	,jCabec["expresso"] 							,Nil})
            AADD(aCabec,{"C5_FRETESA"	,jCabec["valorfrete"]						,Nil})
            AADD(aCabec,{"C5_DESPESL"	,jCabec["despesa"]						,Nil})
            AADD(aCabec,{"C5_CUSTFRE"	,jCabec["custofrete"]								,Nil})
            
            If ( AllTrim(jCabec["cliente"]) $ cNotFat .Or. Posicione("SA1", 1, xFilial("SA1") + jCabec["cliente"] + '01', "A1_PESSOA") == "J" )
                AADD(aCabec, {"C5_FATCOT", "S", Nil})            
            Else            
                AADD(aCabec, {"C5_FATCOT", "N", Nil})             
            End
            
            AADD(aCabec,{"C5_IDENTML"	,jCabec["identrega"]							,Nil})
            AADD(aCabec,{"C5_PEDPAI"	,jCabec["pedidopai"] 							,Nil})
            AADD(aCabec,{"C5_MMPDORI"	,jCabec["pdmkacomp"]							,Nil})
            AADD(aCabec,{"C5_MMRH"		,jCabec["redehome"]							,Nil})

         //   AADD(aCabec,{"C5_DESCONT "		,jCabec["desconto_incondicional"]							,Nil})
            
            If jCabec["naogeraoc"] == 'S'
                AADD(aCabec,{"C5_MMCANCE",'S',Nil})
            End
            
            jCabec["estcli"] := If(!Empty(jCabec["uf"]), jCabec["uf"], Posicione('SA1', 1, xFilial('SA1') + jCabec["cliente"], "A1_EST"))

            oEst:ClearItems()
            nTotalPed := 0 //CONTORNO PROVISORIO CASHBACK - Thiago Almeida 24/06/2022
            For nI := 1 To Len(aItensBrid)
                jItem := aItensBrid[nI]
                oItem := oEst:Analyze(cPedido, jItem["item"], jItem["produto"], jItem["quantidade"], .F., jCabec["cliente"], jCabec["protheus"], .F., .T.,,,jItem["produto_alterado"])
                jItem["produto"] := oItem:GetItem("C6_PRODUTO")

                DBSelectArea("SB1")
                DBSetOrder(1)
                MSSeek(xFilial("SB1") + jItem["produto"])  

                jItem["B1_PROC"] := SB1->B1_PROC

                nCusto := 0

                If oItem:GetItem("PROCESSO") $ "01/02" //EA FF
                    cFilAux := cFilAnt
                    cFilAnt := oItem:GetItem("FILIAL")
                    If jCabec["mostruariogs"] != "S"
                        nCusto := U_BuscaCusto( jItem["produto"], jCabec["estcli"], jItem["B1_PROC"], If(cFilAnt=='010107',.T.,.F.), If(cFilAnt=='010107',.T.,.F.), cPedido)
                    End
                    cFilant := cFilAux
                    If (Empty(nCusto) .Or. nCusto == 0)
                        nCusto := jItem["custo"]
                    End     
                Else
                    //PARA ITENS QUE SEJAM FORNECEDOR VOU DEIXAR BUSCAR NO PROCCESSAMENTO DO ARRAY aGerSol EM MM061, 
                    //POIS A ESCOLHA DA FILIAL NA GERAÇÃO DE OC É DIFERENTE DA QUE ESTÁ AQUI NO MM328
                    nCusto := jItem["custo"]
                    
                    //se o custo for 0 então forço uma busca lá, porem pode estar errado devido a forma com a filial é selecioanda paera oc
                    If (Empty(nCusto) .Or. nCusto == 0) .And. jCabec["mostruariogs"] != "S"
                        nCusto := U_BuscaCusto( jItem["produto"], jCabec["estcli"],  jItem["B1_PROC"], If(cFilAnt=='010107',.T.,.F.), If(cFilAnt=='010107',.T.,.F.), cPedido)    
                    End                
                End

                U_fConOut(ProcName(0), "Pedido: " +  cPedido + " Saldo " + jItem["produto"] + ": " + cValToChar(oItem:GetItem("SALDO")), .T.)                

                aLinha := {}

                AADD(aLinha,{"C6_ITEM"		, jItem["C6_ITEM"]						, Nil})
                AADD(aLinha,{"C6_PRODUTO"	, jItem["produto"]                      , Nil})
                AADD(aLinha,{"C6_CUSTOMM"	, nCusto * jItem["xconval"]				, Nil})
                AADD(aLinha,{"C6_DATAENT"	, jItem["dataentrega"]                  , Nil})
                AADD(aLinha,{"C6_ENTFORN"	, oItem:GetItem("PRAZOFORNECEDOR") 	    , Nil})
                AADD(aLinha,{"C6_QTDVEN"	, jItem["quantidade"]					, Nil})
                
                If nCusto == 0 .And. jCabec["mostruariogs"] != "S"
                    AADD(aLinha,{"C6_PRCVEN",0,Nil})//zerar valor para nÃ£o integrar o pedido
                    U_MM020(	cMVRelServ,;
                                cMVRelaCnt,;
                                cMVRelaUsr,;
                                cMVRelPsw,;
                                cMVRelFrom,;
                                "diego.amatuzzi@madeiramadeira.com.br;luiz.falcao@madeiramadeira.com.br;arthur.klann@madeiramadeira.com.br;protheus@madeiramadeira.com.br",;
                                "[ERRO PV] Pedido nao importado devido a erro de custo",;
                                "Nao foi importado o pedido abaixo devido a problemas com custo: <br> " +;
                                "Pedido:" + cPedido + "- Produto: " + jItem["produto"]  + " - Fornecedor: " + jItem["B1_PROC"] )
                    TCSqlExec("update cabecalho_pedidos_venda SET protheus='9',erro='1', mensagem='CUSTO ERRADO' where pedido='" + cPedido +"'" )
                Else
                    //ADAPTACAO TEMPORARIA DE PRODUTOS ESPECIAIS MARCELO SCANDIAN
                    If "/" + AllTrim(jItem["produto"]) + "/" $ "/126653/126656/"
                        AADD(aLinha,{"C6_PRCVEN",Round(jItem["preco_unitario"] / 1.05 * jItem["xconval"], 2),Nil})
                    Else
                        AADD(aLinha,{"C6_PRCVEN",Round(jItem["preco_unitario"] * jItem["xconval"], 2),Nil})
                    End
                    //FIM ADAPTACAO TEMPORARIA DE PRODUTOS ESPECIAIS MARCELO SCANDIAN
                End
                
                If (jCabec["redehome"] == 'S' .And. jCabec["lojamktplace"] == 'RB')
                    cFilAux := cFilAnt
                    cFilAnt := '010101'
                    AADD(aLinha,{"C6_TES"		, '567'													, Nil})
                Else
                    AADD(aLinha,{"C6_OPER"		,  oItem:GetItem("OPERACAO")													, Nil})
                    AADD(aLinha,{"C6_OPERS"		,  oItem:GetItem("OPERACAO")													, Nil})
                End
                
                AADD(aLinha,{"C6_LOCAL"	, oItem:GetItem("LOCAL")							, Nil})

                //If oItem:GetItem("LOCAL") == "08"
                DbSelectArea("NNR")
                NNR->(DbSetOrder(1))
                If !NNR->(MSSeek(cFilAnt + oItem:GetItem("LOCAL")))
                    RecLock("NNR", .T.)
                        NNR->NNR_FILIAL := cFilAnt
                        NNR->NNR_CODIGO := oItem:GetItem("LOCAL")
                        NNR->NNR_DESCRI := If(oItem:GetItem("LOCAL") == "08", "CROSSDOCKING", If(oItem:GetItem("LOCAL") == '11', "CONSIGNADO", "ESTOQUE"))
                        NNR->NNR_INTP := '3'
                        NNR->NNR_TIPO := '1'
                        NNR->NNR_MRP := '1'
                        NNR->NNR_ANP45 := .F.
                        NNR->NNR_ARMALT := '2'
                        NNR->NNR_VDADMS := '0'
                        NNR->NNR_AMZUNI := '2'
                        NNR->NNR_MSBLQL := '2'                            
                    NNR->(MsUnlock())
                    NNR->(DBCommit())
                End
                //End
                
                AADD(aLinha,{"C6_ESPECIA"	, jCabec["especial"]										, Nil})
                AADD(aLinha,{"C6_PZTRANS"	, oItem:GetItem("PRAZOTRANSPORTE")							, Nil})
                AADD(aLinha,{"C6_PRUNIT"	, Round(jItem["preco_unitario"]*jItem["xconval"], 2)	, Nil})
                AADD(aLinha,{"C6_MMREFAT"	, jItem["refaturar"]							, Nil})
                AADD(aLinha,{"C6_MMVAO"		, If(oItem:GetItem("VAO"), "S", "N")														, Nil})
                AADD(aLinha,{"C6_MMESTKH"	, If(Posicione("SB1",1,xFilial("SB1")+jItem["produto"],"B1_MMESTKH")-Posicione("SB1",1,xFilial("SB1")+jItem["produto"],"B1_MMECOKH")>0,"S",""),Nil})
                AADD(aLinha,{"C6_MMFRETE"	, jItem["frete"]											, Nil})
                AADD(aLinha,{"C6_MMKTPRD"	, jItem["prdconj"]										, Nil})
                AADD(aLinha,{"C6_DTENTAX"	, jItem["dtentaux"]							, Nil})
                AADD(aLinha,{"C6_MMTPFRE"	, jItem["tipo_frete"]							, Nil})
                AADD(aLinha,{"C6_MMCUSRH"	, Round(jItem["custo"], 4)		, Nil})
                AADD(aLinha,{"C6_MMMEFRT"	, jItem["id_menufrete"]										, Nil})
                AADD(aLinha,{"C6_MMTBFRT"	, jItem["id_tabelafrete"]										, Nil})
                AADD(aLinha,{"C6_MMBRIND"	, If(Empty(jItem["brinde"]),'','S')	, Nil})
                AADD(aLinha,{"C6_MMBRVIN"	, jItem["brinde"]						, Nil})
                nTotalPed += Round(jItem["preco_unitario"]*jItem["xconval"], 2) //CONTORNO PROVISORIO CASHBACK - Thiago Almeida 24/06/2022

                If jCabec["naogeraoc"] == 'S'
                    AADD(aLinha,{"C6_MMCANCE",'S',Nil})
                End

                AADD(aLinha,{"C6_MMPZCD", oItem:GetItem("PRAZOINTERNO"), Nil})                                       
                AADD(aLinha,{"C6_MMPROCE", oItem:GetItem("PROCESSO") , Nil})
                
                AADD(aLinha,{"C6_MMITBRI", oItem:GetItem("C6_MMITBRI") , Nil})

                AADD(aItens,aLinha)

                jCabec["margem"] := "S"
                //cMargem	:= "S"
                //VERIFICA SE O CUSTO E PELO MENOS 5%
                If jCabec["mostruariogs"] != "S"
                    If (jItem["custo"] * 1.05 * jItem["xconval"]) > jItem["preco_unitario"] * jItem["xconval"] .And. jCabec["liberado"] != "S" .And. jCabec["lojamktplace"] != "RB"
                        jCabec["margem"] := "N"
                        cMensagem += " -> Item " + jItem["C6_ITEM"] + " com custo (" + cValToChar(jItem["custo"]) + ") menor ou igual a 1.05 do preco_unitario (" +  cValToChar(jItem["preco_unitario"]) + ") | "
                    End
                    //VERIFICA SE EXISTE ALGUM VALOR NEGATIVO
                    If jItem["preco_unitario"] <= 0
                        jCabec["margem"] := "B"
                        cMensagem += " -> Item " + jItem["C6_ITEM"] + " com preco_unitario negativo (" +  cValToChar(jItem["preco_unitario"]) + ") | "
                    End
                End
            Next nI

            //CONTORNO PROVISORIO CASHBACK - Thiago Almeida 24/06/2022
            IF jCabec["desconto_incondicional"] > 0
                For nI := 1 To Len(aItens)
                    For n2 := 1 to Len(aItens[nI])
                        IF aItens[nI,n2,1] == "C6_PRCVEN"
                            aItens[nI,n2,2] := aItens[nI,n2,2] - ROUND((aItens[nI,n2,2] / nTotalPed) * jCabec["desconto_incondicional"],2)
                         //   n2 := Len(aItens[nI])
                        ELSEIF aItens[nI,n2,1] == "C6_PRUNIT"
                            aItens[nI,n2,2] := aItens[nI,n2,2] - ROUND((aItens[nI,n2,2] / nTotalPed) * jCabec["desconto_incondicional"],2)
                        ENDIF
                    Next n2
                Next nI
            ENDIF

            DbSelectArea("SC5")
            DbSetOrder(1)
            lMsErroAuto := .F.
            lErr := .F.
            lSaiFila := .F.

            Do Case
                Case (!oEst:lShowcaseGS .And. aScan(aItensBrid, {|j| Empty(j["prod_cod"])}) > 0)
                    nPosCot := aScan(aItensBrid, {|j| Empty(j["prod_cod"])})
                    jItem := aItensBrid[nPosCot]
                    lErr := .T.
                    lSaiFila := .F.
                    cMensagem += 'Sku nao encontrado na tabela de integracao bridge: ' + Alltrim(jItem["produto"]) + " | "
                Case (!oEst:lShowcaseGS .And. aScan(aItensBrid, {|j| j["prod_prot"] != "1" }) > 0)
                    nPosCot := aScan(aItensBrid, {|j| j["prod_prot"] != "1" })
                    jItem := aItensBrid[nPosCot]
                    lErr := .T.
                    lSaiFila := .F.
                    cMensagem += 'Sku aguarda por atualizacao na integracao bridge: ' + Alltrim(jItem["produto"]) + " | "
                Case aScan(aItensBrid, {|j| Empty(j["B1_COD"])}) > 0
                    nPosCot := aScan(aItensBrid, {|j| Empty(j["B1_COD"])})
                    jItem := aItensBrid[nPosCot]
                    lErr := .T.
                    lSaiFila := .F.
                    cMensagem += 'Sku nao integrado no Protheus: ' + Alltrim(jItem["produto"]) + " | "
                Case Len(aItens) <= 0
                    lErr := .T.
                    lSaiFila := .F.
                    cMensagem += 'Pedido sem itens na bridge | '
                Case jCabec["clistat"] != 1
                    lErr := .T.
                    lSaiFila := .F.
                    cMensagem += 'Cliente nao integrado | '
                Case !ExistCpo("SA1", jCabec["cliente"])
                    lErr := .T.
                    lSaiFila := .F.
                    cMensagem += 'Cliente nao existe no protheus | '
                Case aScan(oEst:aItems, {|x| ValType(x:GetItem("COTACAO")) == "J" .And. x:GetItem("COTACAO")["error"]}) > 0
                    lErr := .T.
                    lSaiFila := .F.
                    nPosCot := aScan(oEst:aItems, {|x| ValType(x:GetItem("COTACAO")) == "J" .And. x:GetItem("COTACAO")["error"]})
                    oItem := oEst:aItems[nPosCot]
                    jCotacao := oItem:GetItem("COTACAO")

                    If ValType(jCotacao["message"]) == "C" .And. !Empty(jCotacao["message"])
                        cMensagem += 'COTACAO: ' + jCotacao["message"] + " | "

                        If jCotacao["message"] == "Saldo insuficiente em estoque GS"
                            cArqLog := "\log\MM328\" + AllTrim(jCabec["pedido"]) + "_" + AllTrim(oItem:GetItem("C6_PRODUTO")) + "_estoque_guideshop.log"
                            If !File(cArqLog)
                                aSM0 := FWLoadSM0(.T.)
                                nPosCot := aScan(aSM0, {|x| AllTrim(x[2]) == cFilAnt})
                                jJson2 := JsonObject():New()
                                jJson2["id"] := "21773"
                                jJson := JsonObject():New()
                                jJson["id"] := "21772"
                                jJson["child"] := jJson2
                                Aadd(acustonfield1, {"customfield_11138", '{"value": "Protheus"}'})
                                Aadd(acustonfield1, {"customfield_11143", '{"value": "Guide"}'})
                                Aadd(acustonfield1, {"customfield_11186", '{"value": "Saldo negativo"}'})
                                If U_MM537("52",;
                                            "881",;
                                            "[PEDIDO SALDAO GUIDE SHOP]",;
                                            "Guide " + jCabec["channel"] + " Filial " + cFilAnt + " CNPJ " + aSM0[nPosCot, 18] + ;
                                            " Pedido " + AllTrim(jCabec["pedido"]) + " sku " + AllTrim(oItem:GetItem("C6_PRODUTO")),;
                                            acustonfield1)
                                    MemoWrite(cArqLog, "SD criado com sucesso!")
                                End
                                FreeObj(jJson2)
                                FreeObj(jJson)
                            End  
                        End
                    Else
                        cMensagem += 'COTACAO: error | '
                    End
                Case aScan(oEst:aItems, {|x| Empty(x:GetItem("TES")) .And. !Empty(x:GetItem("OPERACAO"))  }) > 0
                    nPosCot := aScan(oEst:aItems, {|x| Empty(x:GetItem("TES")) .And. !Empty(x:GetItem("OPERACAO"))  })
                    oItem := oEst:aItems[nPosCot]
                    lErr := .T.
                    lSaiFila := .F.
                    cMensagem += 'TES Inteligente Nao existe para a operacao ' + oItem:GetItem("OPERACAO") + " filial " + cFilAnt
                    cArqLog := "\log\MM328\" + AllTrim(jCabec["pedido"]) + "_" + AllTrim(oItem:GetItem("C6_PRODUTO")) + "_tes_inteligente.log"

                    If !File(cArqLog)
                        jJson := JsonObject():New()
                        jJson["id"] := "11094"
                        Aadd(acustonfield2, {"customfield_10107",'{"value":"Outros"}'})
                        Aadd(acustonfield2, {"customfield_11267",'{"value":"Processo interno"}'})
                        If U_MM537("52", "881", "Erro TES Inteligente Importacao de Pedidos", cMensagem + " PV " + cPedido + " SKU " + AllTrim(oItem:GetItem("C6_PRODUTO")), acustonfield2)
                            MemoWrite(cArqLog, "SD criado com sucesso!")
                        End
                        FreeObj(jJson)
                    End                
                Case aScan(oEst:aItems, {|x| x:GetItem("CEPORIGEM") == 0}) > 0
                    lErr := .T.
                    lSaiFila := .F.
                    cMensagem += 'CEP ORIGEM não identificado. | '     
                Case PedExiste(xFilial("SC5"), cPedido)   
                    lErr := .T.
                    lSaiFila := .T.
                    cMensagem += 'E proibida a reutilizacao do numero do pedido. Este pedido ja foi importado anteriormente para o Protheus. | '
                Case jCabec["margem"] != "S"
                    lErr := .T.
                    lSaiFila := .T.
                    cMensagem += "Erro de margem."
                Case !EnderecoOk(cPedido, @cMensagem, oEst:lShowcaseGS)
                    lErr := .T.
                    lSaiFila := .T.
                Otherwise
                    cErro := fVldPed(jCabec, aCabec, aItens)
                    If !Empty(cErro)
                        lErr := .T.
                        lSaiFila := .F.
                        cMensagem += cErro + ' | '
                        U_fLogPed("X", cPedido, cMensagem)
                    End
            End Case
           
            //Trava importação por detalhes de pagamento inconsistentes
            //Valida se ja foi importado, pois o pedido pai pode ter n filhos     
            If !lErr
                If Empty(jCabec["lojamktplace"])
                    If !Empty(jCabec["pedidopai"])
                        If Select(_cAlias1) > 0
                            (_cAlias1)->(DBCloseArea())
                        End

                        BeginSql Alias _cAlias1
                        %NoParser%

                        SELECT Z21_PEDPAI 
                          FROM Z21010 (NOLOCK) 
                         WHERE Z21_PEDPAI = %Exp:cPedidoPai%
                           AND D_E_L_E_T_ <> '*'

                        EndSql

                        If Empty((_cAlias1)->Z21_PEDPAI) .And. lVldPgto
                            aArray := U_BuscaPGTO(cPedidoPai)
                            If Len(aArray) > 1
                                lResp := aArray[2]
                                cPayLoad := aArray[1]
                            endif
                            cPayload:= StrTran(cPayload,'"','')

                            If !lResp
                                If Select(_cAlias2) > 0
                                    (_cAlias2)->(DBCloseArea())
                                End
                                
                                BeginSql Alias _cAlias2
                                %NoParser%

                                select erro 
                                  from cabecalho_pedidos_venda (nolock) 
                                 where pedido = %Exp:cPedido%

                                EndSql

                                If (Empty((_cAlias2)->erro) .Or. (_cAlias2)->erro <> '2')
                                    cMensagem += " -TESTE- A Rotina MM328-Importacao de pedidos, identificou o pedido " + cPedido + " sem detalhes de pagamento enviados pelo Black Panter. Pedido pai: " + cPedidoPai + " - PAYLOAD retornado do BP: -- " + cPayLoad + " --" //payload do bp.
                                    //JIRA (serviceDeskId,requestTypeId,summary                  ,description,acustomfield)
                                    Aadd(acustonfield3, {"customfield_11090", Val(cPedidoPai)})
                                    Aadd(acustonfield3, {"customfield_11196", '{"value":"Pedidos"}'})
                                    Aadd(acustonfield3, {"customfield_11200", EncodeUtf8('{"value":"Importação de pedidos"}')})
                                    U_MM537("52"          ,"881"        ,"Pagamento nao retornado",cMensagem  ,acustonfield3)
                                End

                                lErr := .T.
                                lErroPgto := .T.
                                cUpdate := "update cabecalho_pedidos_venda " + ;
                                           "   set erro = '2', mensagem = 'E proibida a inclusao de pedido sem os detalhes de pagamento.'" + ;
                                           " where pedido = '" + cPedido + "'"
                               
                                TCSqlExec(cUpdate)
                            End
                        End
                    End
                End
            End
            
            If !lErr
                oEst:SaveRep()
                
                aItens := FWVetByDic(aItens, 'SC6', .T.)

                If Len(aItens) > 1 
                    aSort(aItens,,,{|x,y|x[1][2]<y[1][2]})  //Ordenar os itens para que saia na ordem correta na Danfe e XML
                End
                
                MsExecAuto({|x, y, z| MATA410(x, y, z)}, aCabec, aItens, 3) //3=inclusao, 4=Alteracao, 5=Exclusao
                
                If !lMsErroAuto
                    // Haviam casos onde o protheus indicava lMsErroAuto == .F. mas o pedido nao era importado
                    // Validacao de SC5 para checar em definitivo
                    DbSelectArea("SC5")
                    SC5->(DbSetOrder(1))
                    If SC5->(DbSeek(xFilial("SC5") + jCabec["pedido"])) .And. AllTrim(SC5->C5_NUM) == AllTrim(jCabec["pedido"])
                        TCSQLExec("UPDATE cabecalho_pedidos_venda SET protheus='1', erro='',mensagem='' where pedido='" + cPedido + "'" )
                        TCSQLExec("UPDATE items_do_pedido_de_venda SET protheus='1' where pedido='" + cPedido + "'")
                        // Inclui log
                        U_fLogPed("I", cPedido, "Pedido incluido com sucesso pela rotina automatica. Importados " + cValToChar(Len(aItens)) + " itens | SC5.R_E_C_N_O_ => " + cValToChar(SC5->(RecNo())))
                        // Realiza "alteracao no revisa" para ser replicado
                        // gambiarra p/ leitura no portal
                        DbSelectArea("SA1")
                        SA1->(DbSetOrder(1))
                        If SA1->(DbSeek(xFilial("SA1") + SC5->(C5_CLIENTE + C5_LOJACLI)))
                            RecLock("SA1", .F.)
                                SA1->A1_REVISA := '9'
                            SA1->(MsUnlock())
                            RecLock("SA1", .F.)
                                SA1->A1_REVISA := ' '
                            SA1->(MsUnlock())
                        End
                    Else
                        lErr := .T.
                        cMensagem += " lMsErroAuto == .F. com erro de inclusao do pedido " + cValToChar(Len(aItens)) + " itens | "
                    End
                Else
                    lErr := .T.
                    cMensagem += StrTran(StrTran(U_fMkErr(), CRLF, " |"), "'", "")
                End
            End

            cFilAnt := cFilAux

            If lErr
                If !lErroPgto //Quando tem erro de pagamento é aberto chamado e o campo erro='2'
                    cUpdate := "update cabecalho_pedidos_venda " + ;
                                  "set erro='1', " + ;
                                      "mensagem = '" + cMensagem + "' " 
                    If lSaiFila
                        cUpdate += ", protheus='9' "
                    End

                    cUpdate += " where pedido = '" + cPedido + "'"

                    //voltar esse para produção
                    TCSqlExec(cUpdate)
                Endif
                //esse só para homologar
                //TCSQLExec("UPDATE cabecalho_pedidos_venda SET protheus='9', erro='1', mensagem='" + cMensagem + "' where pedido='" + AllTrim(aSC5[n1][2]) + "'")
                // Inclui log
                U_fLogPed("X", cPedido, cMensagem)
                nSegFim := Seconds()
                nSegTot := nSegFim - nSegIni
                U_fConOut("MM328", "Thread " + cThreadId + " | Erro na inclusao do pedido de venda: " +cPedido + " | Tempo: " + cValToChar(nSegTot) + "s")
            Else
                nSegFim := Seconds()
                nSegTot := nSegFim - nSegIni            
                
                U_fConOut("MM328", "Thread " + cThreadId + " | Pedido de venda incluido com sucesso: " +cPedido + " | Tempo: " + cValToChar(nSegTot) + "s")
            End    
        Case jCabec["protheus"] == "2" //CASO FOR EXCLUSAO DO PEDIDO
            DbSelectArea("SC5")
            DBSetOrder(1)
            If DBSeek(xFilial("SC5") + jCabec["pedido"])
                cNota := NotaSaida(jCabec["pedido"])
                jCabec["Nota"] := cNota
                If Empty(cNota)
                    aItensBrid := ItensBrid(cPedido, jCabec["protheus"])
                    jCabec["itens"] := aItensBrid                    

                    For nI := 1 to Len(aItensBrid)
                        jItem := aItensBrid[nI]
                        //Deletar desassociar, deletar reserva e deletar referencia do PC
                        U_ExcluiLib(cPedido, jItem["item"], jItem["produto"])
                        U_MM021(cPedido, jItem["produto"])
                    Next nI

                    TCSqlExec("UPDATE SC5010 SET C5_MMCANCE='S' WHERE C5_FILIAL = '" + xFilial("SC5") + "' AND C5_NUM='" + cPedido + "'" )

                    aCabec		:= 	{}
                    aItens		:= 	{}
                    
                    AADD(aCabec,{"C5_NUM", cPedido, Nil})
                    
                    lMSErroAuto := .F.
                    
                    MsExecAuto({|x, y, z| MATA410(x, y, z)}, aCabec, aItens, 5) //3=inclusao, 4=Alteracao, 5=Exclusao
                    // Se houve erro na exclusao
                    If lMSErroAuto
                        cMensagem += StrTran(U_fMkErr(), CRLF, "|")
                        TCSqlExec("UPDATE cabecalho_pedidos_venda SET erro='1',mensagem='" + cMensagem + "' where pedido='" + cPedido + "'" )
                        // Inclui log
                        U_fLogPed("X", cPedido, cMensagem)
                    Else
                        TCSqlExec("UPDATE cabecalho_pedidos_venda SET protheus=1, erro='' where pedido='" + cPedido + "'" )
                        TCSqlExec("UPDATE items_do_pedido_de_venda SET protheus=1 where pedido='" + cPedido + "'" )
                        // Inclui log
                        U_fLogPed("E", cPedido, "Pedido excluido com sucesso pela rotina automatica.")
                        //exclusao tb passa pelo pe M410STTS, se estiver funcionando então pode-se tirar essa integração daqui
                        U_MM496GRV(cPedido, "5")
                    EndIf
                Else
                    TCSqlExec("UPDATE SC5010 SET C5_MMCANCE='S' where C5_NUM='" +cPedido + "'" )
                    cMensagem += "Nota ja emitida. Nao e possivel cancelar este pv!"
                    TCSqlExec("update cabecalho_pedidos_venda SET protheus='E', erro='1',mensagem='" + cMensagem + "' where pedido='" + cPedido + "'" )
                    U_fLogPed("X", cPedido, cMensagem)                    
                End
            Else
                TCSqlExec("UPDATE cabecalho_pedidos_venda SET protheus=1, erro='' where pedido='" + cPedido + "'" )
                TCSqlExec("UPDATE items_do_pedido_de_venda SET protheus=1 where pedido='" + cPedido + "'" )
                // Inclui log
                U_fLogPed("E", cPedido, "Pedido excluido anteriormente com sucesso pela rotina automatica.")
            End

            nSegFim := Seconds()
            nSegTot := nSegFim - nSegIni    
            
            U_fConOut("MM328", "Thread " + cThreadId + " | Tempo ate exclusao do pedido de venda: " + cValToChar(nSegTot) + "s")
        Case jCabec["protheus"] == "3" //RESERVA TEMPORARIA
            aItensBrid := ItensBrid(cPedido, jCabec["protheus"])
            jCabec["itens"] := aItensBrid
            lErr := .F.
            cMensagem := ""
            oEst:ClearItems()

            If Len(aItensBrid) >= 1
                For nI := 1 To Len(aItensBrid)
                    jItem := aItensBrid[nI]

                    oEst:Analyze(cPedido, jItem["item"], jItem["produto"], jItem["quantidade"], .F., jCabec["cliente"], jCabec["protheus"], .T.,,,,jItem["produto_alterado"])
                    oItem := oEst:GetItem(1)

                    jItem["produto"] := oItem:GetItem("C6_PRODUTO")

                    If oItem:GetItem("PROCESSO") $ "01/02" //01 estoque avancado prorio 02 fulfillment
                        cFilBkp := cFilAnt
                        cFilAnt := oItem:GetItem("FILIAL")
                        lReservou := .F.
                        
                        If oItem:GetItem("RECNOSC0") > 0
                            lReservou := .T.
                        Else
                            lReservou := a430Reserv({1,"PD",jCabec["pedido"],"TEMPORARIO",xfilial()},U_MM018(),jItem["produto"],oItem:GetItem("LOCAL"),jItem["quantidade"],{"","","",""})                        
                        End

                        If !lReservou
                            lErr := .T.
                            cMensagem += "a430Reserv falhou ao tentar reservar " + jItem["produto"] + "<br/>"
                        End

                        cFilAnt := cFilBkp
                    Else
                        lErr := .T.
                        cMensagem += "Estoque insuficiente para reservar " + jItem["produto"] + "<br/>"
                    End
                Next nI
            Else
                lErr := .T.
                cMensagem += 'Pedido sem itens na bridge | '            
            End

            If lErr
                TCSqlExec("update cabecalho_pedidos_venda SET protheus='9', erro='1', mensagem='" + cMensagem + "' where pedido='" +cPedido + "'" )
            Else
                TCSqlExec("update cabecalho_pedidos_venda SET protheus='1', erro='' where pedido='" + cPedido + "'" )
                U_fLogPed("I", cPedido, "RESERVA de pedido incluida com sucesso pela rotina automatica.")
            End

            nSegFim := Seconds()
            nSegTot := nSegFim - nSegIni

            U_fConOut("MM328", "Thread " + cThreadId + " | Tempo ate reserva do pedido de venda: " + cValToChar(nSegTot) + "s")
        Case jCabec["protheus"] == "4" //EXCLUSAO DE ITENS E TROCA DE ITENS
            lMsErroAuto := .F.
            aCabec := {}
            aItens := {}
            aItensBrid := ItensBrid(cPedido, jCabec["protheus"])
            jCabec["itens"] := aItensBrid
            lErr := .F.

            aAdd(aCabec, {"C5_NUM", jCabec["pedido"], Nil})

            jCabec["estcli"] := Posicione('SA1', 1, xFilial('SA1') + jCabec["cliente"], "A1_EST")           
            
            oEst:ClearItems()

            For nI := 1 To Len(aItensBrid)
                jItem := aItensBrid[nI]
                aLinha := {}

                If jItem["protheus"] == "4"
                    U_ExcluiLib(cPedido, jItem["item"], jItem["produto"])
                    //Deletar desassociar, deletar reserva e deletar referencia do PC
                    U_MM021(cPedido, jItem["produto"])                

                    DbSelectArea("SC6")
                    SC6->(DbSetOrder(2))
                    SC6->(DbGoTop())
                    IF DbSeek(xFilial("SC6") + jItem["produto"] + jCabec["pedido"])
                        If Empty(AllTrim(SC6->C6_NOTA))
                            TCSqlExec("UPDATE SC6010 SET C6_MMCANC='S' WHERE C6_FILIAL = '' AND C6_NUM='" +  jCabec["pedido"] + "' AND C6_PRODUTO='" + jItem["produto"] + "' ")
                            aAdd(aLinha,{"LINPOS", "C6_ITEM", SC6->C6_ITEM})
                            aAdd(aLinha,{"AUTDELETA", "S", Nil})
                        Else
                            aCabec := {}
                            lMsErroAuto := .T.
                            cMensagem += "Nao e possivel cancelar este item! Nota ja emitida: " + SC6->C6_NOTA
                            U_fLogPed("X", cPedido, "")
                            TCSqlExec("UPDATE cabecalho_pedidos_venda SET erro='1', mensagem='" + cMensagem + "' where pedido='" + cPedido + "'")
                        EndIf
                    EndIf
                Else
                    oItem := oEst:Analyze(cPedido, jItem["item"], jItem["produto"], jItem["quantidade"], .F., jCabec["cliente"], jCabec["protheus"], .T., .T.,,,jItem["produto_alterado"])
                    jItem["produto"] := oItem:GetItem("C6_PRODUTO")                

                    DBSelectArea("SB1")
                    DBSetOrder(1)
                    MSSeek(xFilial("SB1") + jItem["produto"])  

                    jItem["B1_PROC"] := SB1->B1_PROC

                    nCusto := 0

                    //PARA ESTOQUE VOU BUSCAR O CUSTO EM BUSCACUSTO DO FONTE MM061
                    If oItem:GetItem("PROCESSO") $ "01/02" //EA FF
                        cFilAux := cFilAnt
                        cFilAnt := oItem:GetItem("FILIAL")
                        nCusto := U_BuscaCusto( jItem["produto"], jCabec["estcli"], jItem["B1_PROC"], If(cFilAnt=='010107',.T.,.F.), If(cFilAnt=='010107',.T.,.F.), cPedido)
                        cFilant := cFilAux
                        If (Empty(nCusto) .Or. nCusto == 0)
                            nCusto := jItem["custo"]
                        End
                    Else
                        //PARA ITENS QUE SEJAM FORNECEDOR VOU DEIXAR BUSCAR NO PROCCESSAMENTO DO ARRAY aGerSol EM MM061, 
                        //POIS A ESCOLHA DA FILIAL NA GERAÇÃO DE OC É DIFERENTE DA QUE ESTÁ AQUI NO MM328
                        nCusto := jItem["custo"]
                        
                        //se o custo for 0 então forço uma busca lá, porem pode estar errado devido a forma com a filial é selecioanda paera oc
                        If (Empty(nCusto) .Or. nCusto == 0)
                            nCusto := U_BuscaCusto( jItem["produto"], jCabec["estcli"],  jItem["B1_PROC"], If(cFilAnt=='010107',.T.,.F.), If(cFilAnt=='010107',.T.,.F.), cPedido)    
                        End                          
                    End

                    aLinha := {}

                    AADD(aLinha,{"C6_ITEM"		, jItem["C6_ITEM"]					, Nil})
                    AADD(aLinha,{"C6_PRODUTO"	, jItem["produto"]											, Nil})
                    AADD(aLinha,{"C6_CUSTOMM"	, nCusto * jItem["xconval"]													, Nil})
                    AADD(aLinha,{"C6_DATAENT"	, jItem["dataentrega"] 						, Nil})
                    AADD(aLinha,{"C6_ENTFORN"	, oItem:GetItem("PRAZOFORNECEDOR")                          , Nil})
                    AADD(aLinha,{"C6_QTDVEN"	, jItem["quantidade"]													, Nil})
                    AADD(aLinha,{"C6_PRCVEN"	, Round(jItem["preco_unitario"] * jItem["xconval"], 2)	, Nil})
                    AADD(aLinha,{"C6_OPER"		, oItem:GetItem("OPERACAO")													, Nil})
                    
                    AADD(aLinha,{"C6_LOCAL"	, oItem:GetItem("LOCAL")							, Nil})

                    If oItem:GetItem("LOCAL") == "08"
                        DbSelectArea("NNR")
                        DbSetOrder(1)
                        If !DbSeek(cFilAnt + "08")
                            RecLock("NNR", .T.)
                                NNR->NNR_FILIAL := cFilAnt
                                NNR->NNR_CODIGO := '08'
                                NNR->NNR_DESCRI := 'CROSSDOCKING'
                                NNR->NNR_INTP := '3'
                                NNR->NNR_TIPO := '1'
                                NNR->NNR_MRP := '1'
                                NNR->NNR_ANP45 := .F.
                                NNR->NNR_ARMALT := '2'
                                NNR->NNR_VDADMS := '0'
                                NNR->NNR_AMZUNI := '2'
                                NNR->NNR_MSBLQL := '2'                            
                            NNR->(MsUnlock())
                        End
                    End
                    
                    AADD(aLinha,{"C6_OPERS"		, oItem:GetItem("OPERACAO")													, Nil})
                    AADD(aLinha,{"C6_ESPECIA"	, jCabec["especial"]										, Nil})
                    AADD(aLinha,{"C6_PZTRANS"	, oItem:GetItem("PRAZOTRANSPORTE")							, Nil})
                    AADD(aLinha,{"C6_PRUNIT"	, Round(jItem["preco_unitario"]*jItem["xconval"], 2)	, Nil})
                    AADD(aLinha,{"C6_MMREFAT"	, jItem["refaturar"]							, Nil})
                    AADD(aLinha,{"C6_MMVAO"		, If(oItem:GetItem("VAO"), "S", "N")														, Nil})
                    AADD(aLinha,{"C6_MMESTKH"	, If(Posicione("SB1",1,xFilial("SB1")+jItem["produto"],"B1_MMESTKH")-Posicione("SB1",1,xFilial("SB1")+jItem["produto"],"B1_MMECOKH")>0,"S",""),Nil})
                    AADD(aLinha,{"C6_MMFRETE"	, jItem["frete"]											, Nil})
                    AADD(aLinha,{"C6_MMKTPRD"	, jItem["prdconj"]											, Nil})
                    AADD(aLinha,{"C6_MMCUSRH"	, Round(jItem["custo"], 4)					, Nil})
                    AADD(aLinha,{"C6_DTENTAX"	, jItem["dtentaux"]		, Nil})
                    AADD(aLinha,{"C6_MMTPFRE"	, jItem["tipo_frete"]	, Nil})
                    AADD(aLinha,{"C6_MMMEFRT"	, jItem["id_menufrete"]	, Nil})
                    AADD(aLinha,{"C6_MMTBFRT"	, jItem["id_tabelafrete"]	, Nil})
                    AADD(aLinha,{"C6_MMPZCD", oItem:GetItem("PRAZOINTERNO"), Nil})                        
                    AADD(aLinha,{"C6_MMPROCE", oItem:GetItem("PROCESSO"), Nil})                                        
                End

                If Len(aLinha) > 0
                    AADD(aItens, aLinha)
                End
            Next nI

            Do Case
                Case aScan(aItensBrid, {|j| Empty(j["prod_cod"])}) > 0
                    nPosCot := aScan(aItensBrid, {|j| Empty(j["prod_cod"])})
                    jItem := aItensBrid[nPosCot]
                    lErr := .T.
                    cMensagem += 'Sku nao encontrado na tabela de integracao bridge: ' + Alltrim(jItem["produto"]) + " | "
                Case aScan(aItensBrid, {|j| j["prod_prot"] != "1" }) > 0
                    nPosCot := aScan(aItensBrid, {|j| j["prod_prot"] != "1" })
                    jItem := aItensBrid[nPosCot]
                    lErr := .T.
                    cMensagem += 'Sku aguarda por atualizacao na integracao bridge: ' + Alltrim(jItem["produto"]) + " | "
                Case aScan(aItensBrid, {|j| Empty(j["B1_COD"])}) > 0
                    nPosCot := aScan(aItensBrid, {|j| Empty(j["B1_COD"])})
                    jItem := aItensBrid[nPosCot]
                    lErr := .T.
                    cMensagem += 'Sku nao integrado no Protheus: ' + Alltrim(jItem["produto"]) + " | "
            End Case

            If Len(aCabec) > 0 .And. Len(aItens) > 0 .And. !lErr
                oEst:SaveRep()
                MsExecAuto({|x, y, z| MATA410(x, y, z)}, aCabec, aItens, 4) //3=inclusao, 4=Alteracao, 5=Exclusao

                If !lMsErroAuto
                    TCSQLEXEC("UPDATE cabecalho_pedidos_venda SET protheus='1', erro='' where pedido='" + cPedido + "'" )
                    TCSQLEXEC("UPDATE items_do_pedido_de_venda SET protheus='1' where pedido='" + cPedido + "'" )
                    // Inclui log
                    U_fLogPed("A", cPedido, "Pedido alterado com sucesso pela rotina automatica.")
                Else
                    If Empty(cMensagem)
                        cMensagem += StrTran(U_fMkErr(), CRLF, "|")
                    EndIf
                    // Inclui log
                    U_fLogPed("X", cPedido, cMensagem)
                    TCSQLEXEC("UPDATE cabecalho_pedidos_venda SET erro='1', mensagem='" + cMensagem + "' where pedido='" + cPedido + "'")
                End
            End

            If lErr
                U_fLogPed("X", cPedido, cMensagem)
                TCSQLEXEC("UPDATE cabecalho_pedidos_venda SET erro='1', mensagem='" + cMensagem + "' where pedido='" + cPedido + "'")            
            End

            nSegFim := Seconds()
            nSegTot := nSegFim - nSegIni
            
            U_fConOut("MM328", "Thread " + cThreadId + " | Tempo ate exclusao/troca do item pedido de venda: " + CValToChar(nSegTot) + "s")
        Case jCabec["protheus"] == "5" //ALTERACAO DE ENDERECO DESATIVADO
            DbSelectArea("SC5")
            DbSetOrder(1)
            If SC5->(DbSeek(xFilial("SC5")+ jCabec["pedido"]))
                cErro := fVldPed(jCabec)
                If !Empty(cErro)
                    TCSQLEXEC("UPDATE cabecalho_pedidos_venda SET erro='1', mensagem='" + cErro + "' where pedido='" + cPedido + "'" )
                Else
                    RecLock("SC5",.F.)
                        SC5->C5_ENDENT 	:= jCabec["enderent"]
                        SC5->C5_BAIRROE := jCabec["bairroent"]
                        SC5->C5_CEPE 	:= jCabec["cepent"]
                        SC5->C5_MUNE 	:= jCabec["cidadeent"]
                        SC5->C5_ESTE 	:= jCabec["ufent"]
                        SC5->C5_MMIBGEE	:= jCabec["ibgeent"]
                        SC5->C5_ENDEN	:= jCabec["endereco"]
                        SC5->C5_BAIRRO 	:= jCabec["bairro"]
                        SC5->C5_CEP 	:= jCabec["cep"]
                        SC5->C5_MUN 	:= jCabec["cidade"]
                        SC5->C5_EST 	:= jCabec["uf"]
                    SC5->(MsUnlock())
                    TCSQLEXEC("UPDATE cabecalho_pedidos_venda SET protheus='1' where pedido='" + cPedido + "'" )
                    TCSQLEXEC("UPDATE items_do_pedido_de_venda SET protheus='1' where pedido='" + cPedido + "'" )
                    // Inclui log
                    U_fLogPed("A", cPedido, "Pedido encontrado e endereco alterado com sucesso." )
                    U_MM496GRV(cPedido, "E")
                EndIf
            Else
                If jCabec["cancelado"] == "S"
                    TCSqlExec("update cabecalho_pedidos_venda set protheus='1', erro='0', mensagem='' where pedido='" + cPedido + "'")
                Else
                    TCSqlExec("update items_do_pedido_de_venda set protheus='0' where pedido='" + cPedido + "'")
                    TCSqlExec("update cabecalho_pedidos_venda set protheus='0', erro='0', mensagem='' where pedido='" + cPedido + "'")
                End
                //TCSQLEXEC("UPDATE cabecalho_pedidos_venda SET erro='1', mensagem='Pedido NAO encontrado para alteracao de endereco.' where pedido='" + AllTrim(aSC5[n1][2]) + "'" )
                // Inclui log
                //U_fLogPed("X", AllTrim(aSC5[n1][2]), "Pedido NAO encontrado para alteracao de endereco." )
            EndIf
        Otherwise
            //
    End Case    

    If _lLogPV
        cAno := cValToChar(Year(Date()))
        cMes := StrZero(Month(Date()),2)
        cDia := StrZero(Day(Date()),2)
        
        If !ExistDir("\LOG\MM328\JSON")
            MakeDir("\LOG\MM328\JSON",,.F.)
        End

        If !ExistDir("\LOG\MM328\JSON\" + cAno)
            MakeDir("\LOG\MM328\JSON\" + cAno,,.F.)
        End        

        If !ExistDir("\LOG\MM328\JSON\" + cAno + "\" + cMes)
            MakeDir("\LOG\MM328\JSON\" + cAno + "\" + cMes,,.F.)
        End         

        If !ExistDir("\LOG\MM328\JSON\" + cAno + "\" + cMes + "\" + cDia)
            MakeDir("\LOG\MM328\JSON\" + cAno + "\" + cMes + "\" + cDia,,.F.)
        End    

        cDataHora := "\LOG\MM328\JSON\" + cAno + "\" + cMes + "\" + cDia + "\PV_" + cPedido + "_" + Dtos(Date()) + "_" + Left(Time(),2) + ".JSON"

        MemoWrite(cDataHora, jCabec:ToJson())
    End
    
    //break
    FreeObj(jCabec)
    cFilAnt := cFilBkp
Return Nil

/*/{Protheus.doc} nomeStaticFunction
    (long_description)
    @type  Static Function
    @author user
    @since 25/10/2021
    @version version
    @param param_name, param_type, param_descr
    @return return_var, return_type, return_description
    @example
    (examples)
    @see (links_or_references)
/*/
Static Function ItensBrid(cPedido, cProtheus)
Local aItensBrid := {}
Local jItem := Nil
Local nTamProd := TamSX3("B1_COD")[1]
Local cXProFat := ""

    If Select(_cAlItBrid) > 0
        (_cAlItBrid)->(DBCloseArea())
    End

    Do Case
        Case cProtheus == "0" //CASO FOR INCLUSAO NORMAL
            BeginSql Alias _cAlItBrid
            %NoParser%

            select it.item, ltrim(rtrim(it.cod_produto)) cod_produto, it.quantidade, it.protheus, it.custo, it.dataentrega, it.preco_unitario,
                   it.refaturar, it.frete,  it.cod_produto_conjunto prdconj, coalesce(it.dataentregaaux,'') dtentaux, it.tipo_frete, 
                   coalesce(it.id_menufrete,0) id_menufrete, coalesce(id_tabelafrete,0) id_tabelafrete, it.brinde,
                   cab.tipo_cliente tipocli, cab.cepentrega cepent, cab.cep, 
                   coalesce(ltrim(rtrim(p.codigo)),'') prod_cod, coalesce(p.protheus,'') prod_prot,
                   B1_COD, B1_PROC
              FROM items_do_pedido_de_venda it (nolock) 
              JOIN cabecalho_pedidos_venda cab (nolock) on cab.pedido = it.pedido 
              left join produtos p (nolock) on ltrim(rtrim(p.codigo)) = ltrim(rtrim(it.cod_produto))
              LEFT JOIN %Table:SB1% SB1 (nolock) ON B1_FILIAL = %xFilial:SB1% AND B1_COD = ltrim(rtrim(cod_produto)) AND SB1.D_E_L_E_T_ != '*' 
             WHERE it.pedido = %Exp:cPedido% 
               AND (it.despesa IS NULL OR it.despesa='N') 
               AND (it.cancelado !='S' OR it.cancelado IS NULL) 

            EndSql  
        Case cProtheus == "2" //exclusão pedido
            BeginSql Alias _cAlItBrid
            %NoParser%

            select item, ltrim(rtrim(cod_produto)) cod_produto, quantidade, protheus
              from items_do_pedido_de_venda (nolock) 
             where pedido = %Exp:cPedido%

            EndSql
        Case cProtheus == "3" //reserva temporaria
            BeginSql Alias _cAlItBrid
            %NoParser%

            select it.item, ltrim(rtrim(it.cod_produto)) cod_produto, it.quantidade, it.protheus
              from items_do_pedido_de_venda it (nolock) 
              join cabecalho_pedidos_venda cab (nolock) on cab.pedido = it.pedido  
             where it.pedido = %Exp:cPedido% 
               and it.protheus = '3'

            EndSql        
        Case cProtheus == "4" //exclusao de itens e troca de itens
            BeginSql Alias _cAlItBrid
            %NoParser%

            select it.item, ltrim(rtrim(it.cod_produto)) cod_produto, it.quantidade, it.protheus, it.custo, it.dataentrega, it.preco_unitario,
                   it.refaturar, it.frete,  it.cod_produto_conjunto prdconj, it.dataentregaaux dtentaux, it.tipo_frete, it.id_menufrete,
                   it.despesa, it.id_tabelafrete, it.brinde,
                   cab.tipo_cliente tipocli, cab.cepentrega cepent, cab.cep, 
                   coalesce(ltrim(rtrim(p.codigo)),'') prod_cod, coalesce(p.protheus,'') prod_prot,
                   B1_COD
              from items_do_pedido_de_venda it (nolock) 
              join cabecalho_pedidos_venda cab (nolock) on cab.pedido = it.pedido 
              left join produtos p (nolock) on ltrim(rtrim(p.codigo)) = ltrim(rtrim(it.cod_produto))
              LEFT JOIN %Table:SB1% SB1 (nolock) ON B1_FILIAL = %xFilial:SB1% AND B1_COD = ltrim(rtrim(cod_produto)) AND SB1.D_E_L_E_T_ != '*' 
             where it.pedido= %Exp:cPedido% 
               and (it.protheus = '0' or it.protheus = '4') 
               and (it.despesa is null or it.despesa='N')  

            EndSql    
    End Case

    While !(_cAlItBrid)->(Eof())
        jItem := JsonObject():New()
        jItem["pedido"] := cPedido
        jItem["protheus"] := AllTrim((_cAlItBrid)->protheus)
        jItem["item"] := AllTrim((_cAlItBrid)->item)
        jItem["cod_produto"] := PadR((_cAlItBrid)->cod_produto, nTamProd)
        jItem["quantidade"] := Val(AllTrim((_cAlItBrid)->quantidade))
        jItem["xconval"] := 1
        
        cXProFat := If(SB1->(FieldPos("B1_XPROFAT")) > 0, Posicione("SB1", 1, xFilial("SB1") + jItem["cod_produto"], "B1_XPROFAT"), "")
        
        If !Empty(cXProFat) .And. AllTrim(cXProFat) != AllTrim(jItem["cod_produto"])
            jItem["sku"] := cXProFat
            jItem["produto"] := cXProFat
            jItem["xconval"] := SB1->B1_XCONVAL
            If jItem["xconval"] > 0
                jItem["quantidade"] := jItem["quantidade"] / jItem["xconval"]
            End
            jItem["produto_alterado"] := .T.
        Else
            jItem["sku"] := jItem["cod_produto"]
            jItem["xconval"] := 1
            jItem["produto_alterado"] := .F.
            jItem["produto"] := jItem["cod_produto"]
        End
        
        jItem["xprofat"] := PadR(cXProFat, nTamProd)

        If cProtheus $ "0/4"
            jItem["dataentrega"] := Stod(AllTrim((_cAlItBrid)->dataentrega))
            jItem["preco_unitario"] := Val(AllTrim((_cAlItBrid)->preco_unitario))
            jItem["C6_ITEM"] := Right("00" + AllTrim((_cAlItBrid)->item), 2)
            jItem["refaturar"] := AllTrim((_cAlItBrid)->refaturar)
            jItem["dtentaux"]  := Stod(AllTrim((_cAlItBrid)->dtentaux))
            jItem["frete"] := (_cAlItBrid)->frete
            jItem["prdconj"] := Alltrim((_cAlItBrid)->prdconj)
            jItem["tipo_frete"] := AllTrim((_cAlItBrid)->tipo_frete)
            jItem["custo"] := Val(AllTrim((_cAlItBrid)->custo))
            jItem["id_menufrete"] := (_cAlItBrid)->id_menufrete
            jItem["id_tabelafrete"] := (_cAlItBrid)->id_tabelafrete
            jItem["brinde"] := AllTrim((_cAlItBrid)->brinde)
            jItem["B1_COD"] := AllTrim((_cAlItBrid)->B1_COD)
            jItem["prod_cod"] := AllTrim((_cAlItBrid)->prod_cod)
            jItem["prod_prot"] := AllTrim((_cAlItBrid)->prod_prot)
        End

        aAdd(aItensBrid, jItem)
        (_cAlItBrid)->(DBSkip())
    End

Return aItensBrid
/*
*
*/
Static Function EnderecoOk(cPedido, cMensagem, lMostruario)
Local cAnd     := ""
Local lRet      := .T.
Local lEntrega  := .F.
Local oClean    := 	CleanChar():New()
Local nSitIBGE  := 0
Local aRet      := {}
Local aEndereco := {{"TABELA"     , ""}, ; //1
					{"ENDERECO"   , "", ""}, ; //2
					{"NUMERO"     , "", ""}, ; //3
					{"COMPLEMENTO", "", ""}, ; //4
					{"BAIRRO"     , "", ""}, ; //5
					{"CIDADE"     , "", ""}, ; //6
					{"UF"         , "", ""}, ; //7
                    {"CEP"        , "", ""}, ; //8
                    {"IBGE"       , "", ""}, ; //9
					{"IBGECAD"    , "", ""}} //10

Default	cMensagem := ""
Default lMostruario := .F.

    If Select(_cAlias1) > 0
        (_cAlias1)->(DbCloseArea())
    End    

	BeginSql alias _cAlias1
	%NoParser%
	select pedido, cliente,
		   cpv.cepentrega, cpv.bairroentrega, cpv.cidadeentrega, cpv.endeentrega ENDEENTREGA, ibgeentrega, cpv.complementoentrega complent, cpv.numeroentrega, cpv.ufentrega,
		   cpv.cep, cpv.bairro, cpv.cidade, cpv.endereco, cpv.uf, cpv.complemento, cpv.numero,
		   c.endereco cli_endereco, c.uf cli_uf, c.cidade cli_cidade, c.bairro cli_bairro, c.cep cli_cep, c.ibge cli_ibge,
		   c.ibge_cadastro cli_ibge_cadastro, c.complemento cli_complemento, c.numero cli_numero,
		   c.endeentrega cli_endeentrega, c.ufentrega cli_ufentrega, c.cidadeentrega cli_cidadeentrega, c.bairroentrega cli_baient,
		   c.cepentrega cli_cepentrega, c.complementoentrega cli_coment, c.numeroentrega cli_nument
	  from cabecalho_pedidos_venda cpv (nolock)
	  join clientes c (nolock) on cpv.cliente = c.codigo
	 where cpv.pedido = %Exp:AllTrim(cPedido)%
	EndSql
	
    Do Case
		Case !Empty((_cAlias1)->cepentrega) //.And. AllTrim((_cAlias1)->cepentrega) != '00099123'
			lEntrega := .T.
			aEndereco[01, 02] := "cabecalho_pedidos_venda"
			aEndereco[02, 02] := "endeentrega"
			aEndereco[02, 03] := oClean:Cleaning(.F., Alltrim((_cAlias1)->ENDEENTREGA))
			aEndereco[03, 02] := "numeroentrega"
			aEndereco[03, 03] := Alltrim((_cAlias1)->numeroentrega)
			aEndereco[04, 02] := "complementoentrega"
			aEndereco[04, 03] := oClean:Cleaning(.F., Alltrim((_cAlias1)->complent))
			aEndereco[05, 02] := "bairroentrega"
			aEndereco[05, 03] := oClean:Cleaning(.F., Alltrim((_cAlias1)->bairroentrega))
			aEndereco[06, 02] := "cidadeentrega"
			aEndereco[06, 03] := oClean:Cleaning(.F., Alltrim((_cAlias1)->cidadeentrega))
			aEndereco[07, 02] := "ufentrega"
			aEndereco[07, 03] := Upper(oClean:Cleaning(.F., Alltrim((_cAlias1)->ufentrega)))
			aEndereco[08, 02] := "cepentrega"
			aEndereco[08, 03] := Alltrim((_cAlias1)->cepentrega)
			aEndereco[09, 02] := "ibgeentrega"
			aEndereco[09, 03] := Alltrim((_cAlias1)->ibgeentrega)
		Case !Empty((_cAlias1)->cep) //.And. AllTrim((_cAlias1)->cep) != '00099123'
			lEntrega := .F.
			aEndereco[01, 02] := "cabecalho_pedidos_venda"
			aEndereco[02, 02] := "endereco"
			aEndereco[02, 03] := oClean:Cleaning(.F., Alltrim((_cAlias1)->ENDERECO))
			aEndereco[03, 02] := "numero"
			aEndereco[03, 03] := Alltrim((_cAlias1)->numero)
			aEndereco[04, 02] := "complemento"
			aEndereco[04, 03] := oClean:Cleaning(.F., Alltrim((_cAlias1)->complemento))
			aEndereco[05, 02] := "bairro"
			aEndereco[05, 03] := oClean:Cleaning(.F., Alltrim((_cAlias1)->bairro))
			aEndereco[06, 02] := "cidade"
			aEndereco[06, 03] := oClean:Cleaning(.F., Alltrim((_cAlias1)->cidade))
			aEndereco[07, 02] := "uf"
			aEndereco[07, 03] := Upper(oClean:Cleaning(.F., Alltrim((_cAlias1)->uf)))
			aEndereco[08, 02] := "cep"
			aEndereco[08, 03] := Alltrim((_cAlias1)->cep)
		Case !Empty((_cAlias1)->cli_cepentrega) //.And. AllTrim((_cAlias1)->cli_cepentrega) != '00099123'
			lEntrega := .T.
			aEndereco[01, 02] := "clientes"
			aEndereco[02, 02] := "endeentrega"
			aEndereco[02, 03] := oClean:Cleaning(.F., Alltrim((_cAlias1)->cli_endeentrega))
			aEndereco[03, 02] := "numeroentrega"
			aEndereco[03, 03] := Alltrim((_cAlias1)->cli_nument)
			aEndereco[04, 02] := "complementoentrega"
			aEndereco[04, 03] := oClean:Cleaning(.F., Alltrim((_cAlias1)->cli_coment))
			aEndereco[05, 02] := "bairroentrega"
			aEndereco[05, 03] := oClean:Cleaning(.F., Alltrim((_cAlias1)->cli_baient))
			aEndereco[06, 02] := "cidadeentrega"
			aEndereco[06, 03] := oClean:Cleaning(.F., Alltrim((_cAlias1)->cli_cidadeentrega))
			aEndereco[07, 02] := "ufentrega"
			aEndereco[07, 03] := Upper(oClean:Cleaning(.F., Alltrim((_cAlias1)->cli_ufentrega))) //Alltrim((_cAlias1)->cli_ufentrega)
			aEndereco[08, 02] := "cepentrega"
			aEndereco[08, 03] := Alltrim((_cAlias1)->cli_cepentrega)
		Case !Empty((_cAlias1)->cli_cep) //.And. AllTrim((_cAlias1)->cli_cep) != '00099123'
			lEntrega := .F.
			aEndereco[01, 02] := "clientes"
			aEndereco[02, 02] := "endereco"
			aEndereco[02, 03] := oClean:Cleaning(.F., Alltrim((_cAlias1)->cli_endereco))
			aEndereco[03, 02] := "numero"
			aEndereco[03, 03] := Alltrim((_cAlias1)->cli_numero)
			aEndereco[04, 02] := "complemento"
			aEndereco[04, 03] := oClean:Cleaning(.F., Alltrim((_cAlias1)->cli_complemento))
			aEndereco[05, 02] := "bairro"
			aEndereco[05, 03] := oClean:Cleaning(.F., Alltrim((_cAlias1)->cli_bairro))
			aEndereco[06, 02] := "cidade"
			aEndereco[06, 03] := oClean:Cleaning(.F., Alltrim((_cAlias1)->cli_cidade))
			aEndereco[07, 02] := "uf"
			aEndereco[07, 03] := Upper(oClean:Cleaning(.F., Alltrim((_cAlias1)->cli_uf)))//Alltrim((_cAlias1)->cli_uf)
			aEndereco[08, 02] := "cep"
			aEndereco[08, 03] := Alltrim((_cAlias1)->cli_cep)
			aEndereco[09, 02] := "ibge"
			aEndereco[09, 03] := Alltrim((_cAlias1)->cli_ibge)
			aEndereco[10, 02] := "ibge_cadastro"
			aEndereco[10, 03] := Alltrim((_cAlias1)->cli_ibge_cadastro)
	End Case
	
    If Empty(aEndereco[01,02])
		lRet := .F.
		cMensagem += "Nao existem informacoes de endereco nas tabelas cabecalho_pedidos_venda e clientes."
		FreeObj(oClean)
		oClean := Nil
		Return lRet
	End
	
    If !U_fVldCEP(aEndereco[08,03])
		lRet := .F.
		cMensagem += "O CEP " + aEndereco[08,03] + " informado na tabela " + aEndereco[01,02] + ", campo " + aEndereco[08,02] + " nao e valido."
		FreeObj(oClean)
		oClean := Nil
		Return lRet
	End
	
    aRet := U_MMGetEnd(aEndereco[02,03])
	
    If Len(aRet[01]) < 2
		lRet := .F.
		cMensagem += "O logradouro " + aRet[01] + " informado na tabela " + aEndereco[01,02] + ", campo " + aEndereco[02,02] + ;
		             " nao pode ter tamanho menor que 2."
		FreeObj(oClean)
		oClean := Nil
		Return lRet
	End
	
    If Len(aEndereco[05,03]) < 2
		lRet := .F.
		cMensagem += "O bairro " + aEndereco[05,03] + " informado na tabela " + aEndereco[01,02] + ", campo " + aEndereco[05,02] + ;
		             " nao pode ter tamanho menor que 2."
		FreeObj(oClean)
		oClean := Nil
		Return lRet
	End
	
    Do Case
		Case aEndereco[01, 02] == "cabecalho_pedidos_venda" .And. lEntrega .And. !Empty(aEndereco[09, 03])
			nSitIBGE := 1
			cAnd := "% AND CC2_CODMUN = '" + aEndereco[09, 03] + "' %"
		Case aEndereco[01, 02] == "clientes" .And. !lEntrega .And. !Empty(aEndereco[09, 03])
			nSitIBGE := 2
			cAnd := "% AND CC2_CODMUN = '" + aEndereco[09, 03] + "' %"
		Case aEndereco[01, 02] == "clientes" .And. !lEntrega .And. !Empty(aEndereco[10, 03])
			nSitIBGE := 3
			cAnd := "% AND CC2_CODMUN = '" + aEndereco[10, 03] + "' %"
		Otherwise
			nSitIBGE := 4
			cAnd := "% AND REPLACE(CC2_MUN, CHAR(39), '') LIKE '%" + Strtran(Upper(aEndereco[06,03]), "'", "") + "%' %"
	End Case
	
    If Select(_cAlias2) > 0
        (_cAlias2)->(DbCloseArea())
    End    

    BeginSql Alias _cAlias2
	%NoParser%
	
    SELECT CC2_EST, CC2_CODMUN, CC2_MUN
	  FROM %Table:CC2% (NOLOCK)
	 WHERE CC2_FILIAL = %xFilial:CC2%
	   AND CC2_EST = %Exp:aEndereco[07,03]%
	   AND %NotDel%
	   %Exp:cAnd%
	EndSql
	
    If (_cAlias2)->(Eof())
		lRet := .F.
        Do Case
		    Case (nSitIBGE == 1 .Or. nSitIBGE == 2)
                cMensagem += "O codigo IBGE " + aEndereco[09,03] + ", para a UF " + aEndereco[07,03] + ", informado na tabela " + ;
                            aEndereco[01,02] + ", campo " + aEndereco[09,02] + ", nao foi localizado na tabela de municipios do Protheus."
		    Case nSitIBGE == 3
                cMensagem += "O codigo IBGE " + aEndereco[10,03] + ", para a UF " + aEndereco[07,03] + ", informado na tabela " + ;
                            aEndereco[01,02] + ", campo " + aEndereco[10,02] + ", nao foi localizado na tabela de municipios do Protheus."
		    Case nSitIBGE == 4
                cMensagem += "O municipio " +  Upper(aEndereco[06,03]) + ", para a UF " + aEndereco[07,03] + ", informado na tabela " + ;
                            aEndereco[01,02] + ", campo " + aEndereco[06,02] + ", nao foi localizado na tabela de municipios do Protheus."
        End Case
	End

    FreeObj(oClean)
Return lRet
//-------------------------------------------------------------------------------
/*/{Protheus.doc} fVldPed
Valida o pedido para inclusao
@return
@author Vinicius Wille
@since 23/10/2018
/*/
//-------------------------------------------------------------------------------
Static Function fVldPed(jCabec, aCab, aIt)
	Local cRet 		:= ""
	Local cCEP 		:= ""
	Local cCEPEnt	:= ""
	Local aEnd		:= {}
	Local aEndEnt	:= {}
	local cIBGE     := ""
    Local nPosQtdVen := 0//aScan(aIt, {|aItem| aItem[1] == "C6_QTDVEN"})
    Local nPosItem   := 0//aScan(aIt, {|aItem| aItem[1] == "C6_ITEM"})
    //Local nPos := 0
    Local nT

    Default aCab	:= {}
	Default aIt		:= {}
	
    nPosEnd		:= aScan(aCab, {|aItem| aItem[1] == "C5_ENDEN"})
	nPosBairro	:= aScan(aCab, {|aItem| aItem[1] == "C5_BAIRRO"})
	nPosMun		:= aScan(aCab, {|aItem| aItem[1] == "C5_MUN"})
	nPosEst		:= aScan(aCab, {|aItem| aItem[1] == "C5_EST"})
	nPosIBGE	:= aScan(aCab, {|aItem| aItem[1] == "C5_MMIBGE"})
	nPosEndEnt	:= aScan(aCab, {|aItem| aItem[1] == "C5_ENDENT"})
	nPosMunEnt	:= aScan(aCab, {|aItem| aItem[1] == "C5_MUNE"})
	nPosBaiEnt	:= aScan(aCab, {|aItem| aItem[1] == "C5_BAIRROE"})
	nPosEstE	:= aScan(aCab, {|aItem| aItem[1] == "C5_ESTE"})
    nPosIBGEE   := aScan(aCab, {|aItem| aItem[1] == "C5_MMIBGEE"})
	// valida CEP
	cCEP		:= IIF(Len(aCab) > 0, aCab[aScan(aCab, {|aItem| aItem[1] == "C5_CEP"}) , 2]	, jCabec["cep"])
	cCEPEnt		:= IIF(Len(aCab) > 0, aCab[aScan(aCab, {|aItem| aItem[1] == "C5_CEPE"}), 2]	, jCabec["cepent"])
	
    cCEPEnt := StrTran(cCEPEnt, '-', '')
	If !Empty(cCEPEnt) .And. !fVldCEP(cCEPEnt)
		cRet := "CEP de entrega invalido: " + cCEPEnt
	EndIf
	
    cCEP := StrTran(cCEP, '-', '')
	If !Empty(cCEP) .And. !fVldCEP(cCEP)
		cRet := "CEP invalido: " + cCEP
	EndIf
	
    // Ajuste de cidade e bairro de acordo com o servico dos correios
	If !Empty(aCab)
		//{ oResp:ibge, oResp:cidade, oResp:estado, oResp:bairro, oResp:endereco}
		aEnd := U_MM010fAddrInfo( cCEP)
		cIBGE := Right(AllTrim(IIF(Len(aEnd) > 0, aEnd[1], '')), 5)
		
        If nPosIBGE > 0 .and. Len(aEnd) > 1 .And. !Empty(cIBGE) .And. AllTrim(Upper(cIBGE)) != AllTrim(Upper(aCab[nPosIBGE, 2]))
            aCab[nPosIBGE, 2] := cIBGE
        EndIf
		If Len(aEnd) > 1 .And. !Empty(aEnd[2]) .And. AllTrim(Upper(aEnd[2])) != AllTrim(Upper(aCab[nPosMun, 2]))
			aCab[nPosMun, 2] := aEnd[2]
		EndIf
		If Len(aEnd) > 2 .And. !Empty(aEnd[3]) .And. AllTrim(Upper(aEnd[3])) != AllTrim(Upper(aCab[nPosEst, 2]))
			aCab[nPosEst, 2] := aEnd[3]
		EndIf
		If Len(aEnd) > 3 .And. !Empty(aEnd[4]) .And. AllTrim(Upper(aEnd[4])) != AllTrim(Upper(aCab[nPosBairro, 2]))
			aCab[nPosBairro, 2] := aEnd[4]
		EndIf
		
        // Separa o endereco em um array contendo: logradouro, numero NUMERIC, numero CHAR, complemento
		aFullAddr := U_MMGetEnd(aCab[nPosEnd, 2])
		If Len(aEnd) > 4 .And. !Empty(aEnd[5]) .And. AllTrim(Upper(aEnd[5])) != AllTrim(Upper(aFullAddr[1]))
			aCab[nPosEnd, 2] := aEnd[5] + ", " + aFullAddr[3] + ", " + aFullAddr[4]
		EndIf
		
        If !Empty(cCEPEnt)
			aEndEnt := U_MM010fAddrInfo( cCEPEnt)
			If Len(aEndEnt) > 1 .And. !Empty(aEndEnt[2]) .And. AllTrim(Upper(aEndEnt[2])) != AllTrim(Upper(aCab[nPosMunEnt, 2]))
				aCab[nPosMunEnt, 2] := aEndEnt[2]
			EndIf
			If Len(aEndEnt) > 2 .And. !Empty(aEndEnt[3]) .And. AllTrim(Upper(aEndEnt[3])) != AllTrim(Upper(aCab[nPosEstE, 2]))
				aCab[nPosEstE, 2] := aEndEnt[3]
			EndIf
			If Len(aEndEnt) > 3 .And. !Empty(aEndEnt[4]) .And. AllTrim(Upper(aEndEnt[4])) != AllTrim(Upper(aCab[nPosBaiEnt, 2]))
				aCab[nPosBaiEnt, 2] := aEndEnt[4]
			EndIf
			// Separa o endereco em um array contendo: logradouro, numero NUMERIC, numero CHAR, complemento
			aFullAddr := U_MMGetEnd(aCab[nPosEndEnt, 2])
			If Len(aEndEnt) > 4 .And. !Empty(aEndEnt[5]) .And. AllTrim(Upper(aEndEnt[5])) != AllTrim(Upper(aFullAddr[1]))
				aCab[nPosEndEnt, 2] := aEndEnt[5] + ", " + aFullAddr[3] + ", " + aFullAddr[4]
			EndIf
		EndIf
	EndIf
	
    // Valida informacoes de entrega SE HOUVEREM
	cEndEnt		:= IIF(Len(aCab) > 0, aCab[aScan(aCab, {|aItem| aItem[1] == "C5_ENDENT"}), 2], jCabec["enderent"] )
	cBairroEnt	:= IIF(Len(aCab) > 0, aCab[nPosBaiEnt, 2], jCabec["bairroent"] )
	cMunEnt		:= IIF(Len(aCab) > 0, Upper(AllTrim(aCab[nPosMunEnt, 2])), jCabec["cidadeent"] )
	cEstEnt		:= IIF(Len(aCab) > 0, aCab[nPosEstE, 2], jCabec["ufent"] )
	cIBGEEnt	:= IIF(Len(aCab) > 0, aCab[nPosIBGEE, 2], jCabec["ibgeent"] )
	cMun		:= IIF(Len(aCab) > 0, Upper(AllTrim(aCab[aScan(aCab, {|aItem| aItem[1] == "C5_MUN"}), 2])), jCabec["cidade"] )
	
    If !Empty(cEndEnt)
        Do Case
            Case Empty(cBairroEnt)
                cRet := "Bairro de entrega vazio"
            Case Empty(cMunEnt)
                cRet := "Municipio de entrega vazio"
            Case Empty(cEstEnt)
                cRet := "Estado de entrega vazio"
            Case cMun != cMunEnt .And. Empty(cIBGEEnt)	// IBGE entrega so sera preenchido se as cidades forem diferentes
                cRet := "IBGE de entrega vazio"
            Otherwise
                //{ oResp:ibge, oResp:cidade, oResp:estado, oResp:bairro, oResp:endereco}
                aEnd := U_MM010fAddrInfo( cCEPEnt)
                cIBGE := Right(AllTrim(IIF(Len(aEnd) > 0, aEnd[1], '')), 5)
                If nPosIBGEE > 0 .and. Len(aEnd) > 1 .And. !Empty(cIBGE) .And. AllTrim(Upper(cIBGE)) != AllTrim(Upper(aCab[nPosIBGEE, 2]))
                    aCab[nPosIBGEE, 2] := cIBGE
                EndIf
		End Case
	End
    
    If !Empty(aIt)
        For nT := 1 To Len(aIt)
            nPosItem := aScan(aIt[nT], {|x| x[01] == "C6_ITEM"})
            nPosQtdVen := aScan(aIt[nT], {|x| x[01] == "C6_QTDVEN"})
            If nPosQtdVen > 0
                If aIt[nT, nPosQtdVen, 02] == 0
                    cRet := "C6_QTDVEN não informado, item " + aIt[nT, nPosItem, 02]
                    Exit
                End
            End
        Next nT
    End
Return cRet
//-------------------------------------------------------------------------------
/*/{Protheus.doc} fVldCEP
Valida o CEP
@return
@author Vinicius Wille
@since 23/10/2018
/*/
//-------------------------------------------------------------------------------
Static Function fVldCEP(cCEP)
	Local lRet		:= .T.
	Local cMyCEP	:= cCEP
	If Len(AllTrim(cMyCEP)) < 8
		lRet := .F.
	Else
		While lRet .And. Len(cMyCEP) > 0
			lRet := IsDigit(cMyCEP)
			cMyCEP := Right(cMyCEP, Len(cMyCEP) - 1)
		EndDo
	EndIf
Return lRet
/*

*/
Static Function PedExiste(cFil, cPedido)
Local lRet := .F.
	
    If Select(_cAliasPed) > 0
        (_cAliasPed)->(DbCloseArea())
    End
	
    //DELETADO E ATIVO
	BeginSql alias _cAliasPed
	%NoParser%
	
    SELECT C5_NUM
	  FROM %Table:SC5% (NOLOCK)
	 WHERE C5_FILIAL = %xFilial:SC5%
	   AND C5_NUM = %Exp:cPedido%
	
    EndSql
	
    lRet := !(_cAliasPed)->(Eof())
Return lRet
/*/{Protheus.doc} CorrigeCot
    (Corrigir cotação de pedidos represados na bridge por problema de cotação)
    @type Static Function
    @author Marcelo.Secate
    @since 28/05/2021
    @version 1.0
    @param Nil, Nil, Nil
    @return Nil, Nil, Nil
    @example
    (CorrigeCot())
    @see (links_or_references)
    /*/
Static Function CorrigeCot()
Local jQuotation
Local cError

    If ValType(_cAlias1) == "U"
        _cAlias1 := GetNextAlias()
    End

    If Select(_cAlias1) > 0
        (_cAlias1)->(DBCloseArea())
    End

    BeginSql Alias _cAlias1
    %NoParser%

    select cpv.pedido, cpv.data_compra, cpv.protheus, cpv.erro, cpv.mensagem, 
           ipv.item, ipv.cod_produto, coalesce(ipv.cod_produto_conjunto,'') cod_conjunto, 
           coalesce(ipv.prazotransp,'0') prazotransp, 
           coalesce(ipv.entregafornecedor,'0') entregafornecedor, 
           ipv.ceporigem,
           B1_MMCONSI
      from cabecalho_pedidos_venda cpv (nolock)
      join items_do_pedido_de_venda ipv (nolock) on ipv.pedido = cpv.pedido and coalesce(ipv.cancelado,'') <> 'S'
      join clientes cli on cpv.cliente = cli.codigo AND cli.protheus = 1 
      JOIN SB1010 SB1 (NOLOCK) ON B1_FILIAL = '' AND (B1_COD = ipv.cod_produto or B1_COD = ipv.cod_produto_conjunto) AND SB1.D_E_L_E_T_ != '*'      
     where cpv.protheus in  ('0','2','3','4','5')
       and COALESCE(cpv.lojamktplace, 'XX') NOT IN ('  ')
       and cli.protheus in ('1') 
       and redehome is not null
       and cpv.erro = '1'
       and left( convert(varchar(7), cpv.mensagem), 7) = 'COTACAO'
       and (cpv.mensagem like '%Produto indisponível%' or cpv.mensagem like '%Cep inválido%')
       and coalesce(cpv.cancelado,'') <> 'S'
     order by data_compra, pedido, item

    EndSql

    While !(_cAlias1)->(Eof())
        jQuotation := JsonObject():New()
        cError := Nil

        jQuotation["fake"] := .T.
        jQuotation["programa"] := "MM328 | CorrigeCot"
        jQuotation["error"] := .F.
        jQuotation["status"] := "success"
        jQuotation["transportadora"] := Val((_cAlias1)->prazotransp)
        jQuotation["fornecedor"] := Val((_cAlias1)->entregafornecedor)
        jQuotation["prazo_interno"] := 2
        jQuotation["quote_date"] := Dtos(Date()) + StrTran(Time(), ":", "")
        jQuotation["sku"] := If(Empty((_cAlias1)->cod_conjunto), AllTrim((_cAlias1)->cod_produto), AllTrim((_cAlias1)->cod_conjunto))
        jQuotation["message"] := ""
        jQuotation["cep_origem"] := If((_cAlias1)->ceporigem == 0, "2", cValToChar((_cAlias1)->ceporigem))
        jQuotation["is_cd"] := .F.
        jQuotation["is_own_stock"] := If((_cAlias1)->B1_MMCONSI == "S", .F., .T.)
        jQuotation["armazem"] := If((_cAlias1)->B1_MMCONSI == "S", "11", "01")

        RecLock("ZMB", .T.)
            ZMB->ZMB_FILIAL := xFilial("ZMB")
            ZMB->ZMB_PEDIDO := AllTrim((_cAlias1)->pedido)
            ZMB->ZMB_ITEM := Right("0" + Alltrim((_cAlias1)->item),2)
            ZMB->ZMB_PRODUT := jQuotation["sku"]
            ZMB->ZMB_DATHOR := jQuotation["quote_date"]
            ZMB->ZMB_PATH := jQuotation["programa"]       
            ZMB->ZMB_STATUS := jQuotation["status"]
            ZMB->ZMB_PZTRAN := jQuotation["transportadora"]
            ZMB->ZMB_PZFORN := jQuotation["fornecedor"]
            ZMB->ZMB_PZINTE := jQuotation["prazo_interno"]
            ZMB->ZMB_QUOTDT := jQuotation["quote_date"]
            ZMB->ZMB_CEPORI := jQuotation["cep_origem"]
            ZMB->ZMB_JSONRE := jQuotation:ToJson()
        ZMB->(MSUnlock())
        ZMB->(DBCommit())

        TCSqlExec("update cabecalho_pedidos_venda set erro = '', mensagem = '' where pedido = '" + AllTrim((_cAlias1)->pedido) + "'")

        FreeObj(jQuotation)
        jQuotation := Nil

        (_cAlias1)->(DBSkip())
    End

    (_cAlias1)->(DBCloseArea())    

    //DBCommitAll()
Return Nil
/*/{Protheus.doc} nomeStaticFunction
    (long_description)
    @type  Static Function
    @author user
    @since 18/10/2021
    @version version
    @param param_name, param_type, param_descr
    @return return_var, return_type, return_description
    @example
    (examples)
    @see (links_or_references)
/*/
User Function ExcluiLib(cPedido, cItem, cProduto, lExcluirC9)
Local cFilBkp := cFilAnt
Local nTamNum := GetSx3Cache("C5_NUM", "X3_TAMANHO") //TamSX3("C5_NUM")[1]
Local nTamProd := GetSx3Cache("C6_PRODUTO", "X3_TAMANHO") //TamSX3("C6_PRODUTO")[1]
Local cTamItem := GetSx3Cache("C6_ITEM", "X3_TAMANHO")
Local lSC6 := .F.

Default lExcluirC9 := .F.

    cPedido := PadR(cPedido, nTamNum)
    cItem := Right("00" + AllTrim(cItem), cTamItem)
    cProduto := PadR(cProduto, nTamProd)

    DbSelectArea("SC5")
    DbSetOrder(1)
    If DBSeek(xFilial("SC5") + cPedido)
        DbSelectArea("SC6")
        DbSetOrder(1)
        If DBseek(xFilial("SC6") + cPedido + cItem)
            lSC6 := .T.
        Else
            DbSetOrder(2)
            If DBseek(xFilial("SC6") + cProduto + cPedido)
                lSC6 := .T.
            End    
        End
    End

    If lSC6
        If (ValType(_cAlias1) == "U" .Or. Empty(_cAlias1))
            _cAlias1 := GetNextAlias()
        End

        If Select(_cAlias1) > 0
            (_cAlias1)->(DBCloseArea())
        End

        BeginSql Alias _cAlias1
        %NoParser%

        SELECT SC9.R_E_C_N_O_ RECNOSC9
          FROM %Table:SC9% SC9 (NOLOCK) 
         WHERE C9_FILIAL >= ''
           AND C9_PEDIDO = %Exp:SC6->C6_NUM%
           AND C9_ITEM = %Exp:SC6->C6_ITEM%
           AND C9_PRODUTO = %Exp:SC6->C6_PRODUTO%
           AND SC9.%NotDel%

        EndSql

        While !(_cAlias1)->(Eof())
            DbSelectArea("SC9")
            DBGoTo((_cAlias1)->RECNOSC9)
            If !Eof()
                cFilAnt := SC9->C9_FILIAL
                If lExcluirC9
                    a460Estorna(.T.)
                Else
                    RecLock("SC9", .F.)
                        SC9->C9_QTDRESE := 0
                        SC9->C9_RESERVA := ""
                    SC9->(MsUnlock())
                    SC9->(DBCommit())
                End
            End
            (_cAlias1)->(DBSkip())
        End

        If (_cAlias1)->(Eof()) .Or. ((lExcluirC9 .And. SC9->(Deleted())) .Or. SC9->(Eof()))
            RecLock("SC6", .F.)
                SC6->C6_QTDEMP := 0//quantidade liberada mas não faturada
                SC6->C6_QTDEMP2 := 0
            SC6->(MsUnlock())
            SC6->(DBCommit())
        End
    End

    cFilAnt := cFilBkp
Return Nil
/*/{Protheus.doc} nomeStaticFunction
    (long_description)
    @type  Static Function
    @author user
    @since 10/08/2021
    @version version
    @param param_name, param_type, param_descr
    @return return_var, return_type, return_description
    @example
    (examples)
    @see (links_or_references)
/*/
Static Function A410RegFat()
Local cAlias := GetNextAlias()    
Local cUpdate

    BeginSql Alias cAlias
    %NoParser%

    select pedido 
      from cabecalho_pedidos_venda cpv (nolock) 
     where cpv.protheus = '2' and cpv.erro = '1'
       and cpv.mensagem like '%A410REGFAT%'
       and cpv.mensagem not like '%A410LIBER%'    

    EndSql

    If !(cAlias)->(Eof())
        cUpdate := "update cabecalho_pedidos_venda set protheus = 'E' " + ;
                   " where protheus = '2' and erro = '1' " + ;
                   "   and mensagem like '%A410REGFAT%' " + ;
                   "   and mensagem not like '%A410LIBER%'"

        TCSqlExec(cUpdate)                   
    End

    (cAlias)->(DBCloseArea())
Return Nil
/*/{Protheus.doc} nomeStaticFunction
    (long_description)
    @type  Static Function
    @author user
    @since 11/08/2021
    @version version
    @param param_name, param_type, param_descr
    @return return_var, return_type, return_description
    @example
    (examples)
    @see (links_or_references)
/*/
Static Function AjNumPed()
Local cAlias := GetNextAlias()
Local cUpdate 

    BeginSql Alias cAlias
    %NoParser%

    select cpv.pedido, cpv.created_at, cpv.cancelado, cpv.protheus, cpv.erro, SC5.D_E_L_E_T_ DELETSC5, C5_NUM
      from cabecalho_pedidos_venda cpv (nolock) 
      LEFT JOIN SC5010 SC5 (NOLOCK) ON C5_FILIAL = '' AND C5_NUM = cpv.pedido
     where cpv.erro = '1'
       and cpv.protheus <> '1' 
       and coalesce(cpv.cancelado,'') <> 'S'
       and cpv.mensagem like '%E proibida a reutilizacao do numero do pedido%'
       AND C5_NUM IS NULL

    EndSql

    While !(cAlias)->(Eof())
        cUpdate := "update cabecalho_pedidos_venda set protheus = '0' where pedido = '" + (cAlias)->pedido + "'"
        TCSqlExec(cUpdate)
        (cAlias)->(DBSkip())
    End While

    (cAlias)->(DBCloseArea())
Return Nil
/*
EXCLUIR
--RESERVAS DE PEDIDOS EXCLUIDOS
--RESERVAS DE PEDIDOS CANCELADOS
--RESERVAS EM PEDIDOS FATURADOS
*/
Static Function ExcluiRes()
Local cAlias := GetNextAlias()
Local cFilBkp := cFilAnt

    BeginSql Alias cAlias
    %NoParser%

    //RESERVAS DE PEDIDOS EXCLUIDOS
    SELECT C0_FILIAL, C0_NUM, C0_TIPO, C0_DOCRES, C0_PRODUTO, C0_LOCAL, C0_SOLICIT, C0_QUANT, C0_QTDPED
      FROM SC0010 SC0 (NOLOCK)
     WHERE C0_FILIAL >= ''
       AND (C0_QUANT > 0 OR C0_QTDPED > 0)
	   AND C0_SOLICIT NOT IN ('TEMPORARIO')
	   AND C0_TIPO IN ('PD','LB')
       AND SC0.D_E_L_E_T_ != '*'
        AND NOT EXISTS (SELECT 1 
                        FROM SC6010 B (NOLOCK) 
                        WHERE B.C6_FILIAL = ''
                            AND B.C6_NUM = C0_DOCRES
                            AND B.C6_PRODUTO = C0_PRODUTO
                            AND B.D_E_L_E_T_ != '*')

    UNION

    //RESERVAS DE PEDIDOS CANCELADOS
    SELECT C0_FILIAL, C0_NUM, C0_TIPO, C0_DOCRES, C0_PRODUTO, C0_LOCAL, C0_SOLICIT, C0_QUANT, C0_QTDPED
      FROM SC0010 SC0 (NOLOCK)
      JOIN SC5010 SC5 (NOLOCK) ON C5_FILIAL = '' AND C5_NUM = C0_DOCRES AND SC5.D_E_L_E_T_ != '*'
      left join cabecalho_pedidos_venda cpv (nolock) on cpv.pedido = C5_NUM
      JOIN SC6010 SC6 (NOLOCK) ON C6_FILIAL = C5_FILIAL AND C6_NUM = C5_NUM AND SC6.D_E_L_E_T_ != '*'
      left join items_do_pedido_de_venda ipv (nolock) on ipv.pedido = C6_NUM 
                                                and (ipv.item = (CASE WHEN C6_MMITBRI != '' THEN C6_MMITBRI ELSE CONVERT(VARCHAR(2), CONVERT(INT, C6_ITEM)) END)
                                                or ipv.cod_produto = C6_PRODUTO)
      LEFT JOIN SD2010 SD2 (NOLOCK) ON D2_FILIAL >= '' AND D2_PEDIDO = C6_NUM AND D2_ITEMPV = C6_ITEM AND D2_COD = C6_PRODUTO AND D2_TIPO = 'N' AND SD2.D_E_L_E_T_ != '*'
      LEFT JOIN SF4010 SF4 (NOLOCK) ON F4_FILIAL = '' AND F4_CODIGO = D2_TES AND SF4.D_E_L_E_T_ != '*'
     WHERE C0_FILIAL >= ''
       AND (C0_QUANT > 0 OR C0_QTDPED > 0)
       AND SC0.D_E_L_E_T_ != '*'
       AND (C5_MMCANCE = 'S' OR C6_MMCANC = 'S' or coalesce(cpv.cancelado, '') = 'S' or coalesce(ipv.cancelado, '') = 'S')

    UNION

    //RESERVAS DE PEDIDOS FATURADOS
    SELECT C0_FILIAL, C0_NUM, C0_TIPO, C0_DOCRES, C0_PRODUTO, C0_LOCAL, C0_SOLICIT, C0_QUANT, C0_QTDPED
      FROM SC0010 SC0 (NOLOCK)
      JOIN SC5010 SC5 (NOLOCK) ON C5_FILIAL = '' AND C5_NUM = C0_DOCRES AND SC5.D_E_L_E_T_ != '*'
      JOIN SC6010 SC6 (NOLOCK) ON C6_FILIAL = C5_FILIAL AND C6_NUM = C5_NUM AND C6_PRODUTO = C0_PRODUTO AND SC6.D_E_L_E_T_ != '*'
      JOIN SD2010 SD2 (NOLOCK) ON D2_FILIAL >= '' AND D2_PEDIDO = C6_NUM AND D2_ITEMPV = C6_ITEM AND D2_COD = C6_PRODUTO AND SD2.D_E_L_E_T_ != '*' 
      JOIN SF4010 SF4 (NOLOCK) ON F4_FILIAL = '' AND F4_CODIGO = D2_TES AND SF4.D_E_L_E_T_ != '*'
     WHERE C0_FILIAL >= ''
       AND (C0_QUANT > 0 OR C0_QTDPED > 0)
       AND C0_TIPO NOT IN ('LB')
       AND SC0.D_E_L_E_T_ != '*'

    UNION

    //RESERVAS EM PEDIDOS FATURADOS e com SC9 LIBERADOS
    SELECT C0_FILIAL, C0_NUM, C0_TIPO, C0_DOCRES, C0_PRODUTO, C0_LOCAL, C0_SOLICIT, C0_QUANT, C0_QTDPED
      FROM SC0010 SC0 (NOLOCK)
      JOIN SC5010 SC5 (NOLOCK) ON C5_FILIAL = '' AND C5_NUM = C0_DOCRES AND SC5.D_E_L_E_T_ != '*'
      JOIN SC6010 SC6 (NOLOCK) ON C6_FILIAL = C5_FILIAL AND C6_NUM = C5_NUM AND C6_PRODUTO = C0_PRODUTO AND SC6.D_E_L_E_T_ != '*'
      JOIN SD2010 SD2 (NOLOCK) ON D2_FILIAL >= '' AND D2_PEDIDO = C6_NUM AND D2_ITEMPV = C6_ITEM AND D2_COD = C6_PRODUTO AND SD2.D_E_L_E_T_ != '*'
      JOIN SF4010 SF4 (NOLOCK) ON F4_FILIAL = '' AND F4_CODIGO = D2_TES AND SF4.D_E_L_E_T_ != '*'
      LEFT JOIN SC9010 SC9 (NOLOCK) ON C9_FILIAL = C0_FILIAL AND C9_RESERVA = C0_NUM AND C9_PRODUTO = C0_PRODUTO AND SC9.D_E_L_E_T_ != '*'
     WHERE C0_FILIAL >= ''
       AND (C0_QUANT > 0 OR C0_QTDPED > 0)
       AND C0_TIPO IN ('LB')
       AND SC0.D_E_L_E_T_ != '*'     

    ORDER BY C0_FILIAL, C0_NUM  

    EndSql

    While !(cAlias)->(Eof())
        cFilAnt := (cAlias)->C0_FILIAL
        U_MM022((cAlias)->C0_DOCRES, (cAlias)->C0_PRODUTO, (cAlias)->C0_LOCAL, (cAlias)->C0_NUM)
        (cAlias)->(DBSkip())
    End
    
    (cAlias)->(DBCloseArea())

    cFilAnt := cFilBkp
Return Nil
//malandramente pelo cleds
static function fFixLimbo()
    local aPed := {}
    local nI := 1
    local cAls
    cAls := GetNextAlias()

    BeginSql Alias cAls
    %NoParser%

    SELECT C5_EMISSAO, C5_NUM, C6_PRODUTO
      FROM SC5010 SC5 (NOLOCK) 
      join cabecalho_pedidos_venda cpv (nolock) on cpv.pedido = C5_NUM
      JOIN SC6010 SC6 (NOLOCK) ON C6_FILIAL = C5_FILIAL AND C6_NUM = C5_NUM AND SC6.D_E_L_E_T_ != '*' AND C6_MMCANC <> 'S' AND C6_NOTA = ''
                              AND NOT EXISTS (SELECT 1 FROM SD2010 SD2 (NOLOCK) 
                                               WHERE D2_FILIAL BETWEEN '' AND 'Z' AND D2_PEDIDO = C6_NUM 
                                                 AND D2_ITEMPV = C6_ITEM AND D2_COD = C6_PRODUTO 
                                                 AND SD2.D_E_L_E_T_ != '*' AND D2_QTDEDEV = 0)
      join items_do_pedido_de_venda ipv (nolock) on ipv.pedido = C6_NUM 
                                                and (ipv.item = (case when C6_MMITBRI <> '' then C6_MMITBRI 
                                                                      when C6_MMITBRI = '' AND ISNUMERIC(C6_ITEM) = 1 
                                                                           then CONVERT(VARCHAR(2), CONVERT(INT, C6_ITEM)) 
                                                                end)
                                                 or ipv.cod_produto = C6_PRODUTO)
      LEFT JOIN SC0010 SC0 (NOLOCK) ON C0_FILIAL BETWEEN '' AND 'Z' AND C0_DOCRES = C6_NUM AND C0_PRODUTO = C6_PRODUTO AND SC0.D_E_L_E_T_ != '*' 
      LEFT JOIN SC1010 SC1 (NOLOCK) ON C1_FILIAL BETWEEN '' AND 'Z' AND C1_PVMM = C6_NUM AND C1_PRODUTO = C6_PRODUTO AND SC1.D_E_L_E_T_ != '*' 
     WHERE C5_FILIAL = ''
       AND C5_EMISSAO >= '20210710'
       AND (C5_NUM LIKE '%Z%' OR C5_NUM LIKE '%P%' OR C5_NUM LIKE '%R%')
       AND SC5.D_E_L_E_T_ != '*'
       AND C5_MMCANCE <> 'S'
       AND C5_TIPO = 'N'
       and coalesce(cpv.cancelado,'') <> 'S'
       and coalesce(ipv.cancelado,'') <> 'S'
       AND C1_NUM IS NULL
       AND C0_NUM IS NULL
    UNION
    SELECT C5_EMISSAO, C5_NUM, C6_PRODUTO
      FROM SC5010 SC5 (NOLOCK) 
      join cabecalho_pedidos_venda cpv (nolock) on cpv.pedido = C5_NUM
      JOIN SC6010 SC6 (NOLOCK) ON C6_FILIAL = C5_FILIAL AND C6_NUM = C5_NUM AND SC6.D_E_L_E_T_ != '*' AND C6_MMCANC <> 'S' AND C6_NOTA = ''
                              AND NOT EXISTS (SELECT 1 FROM SD2010 SD2 (NOLOCK) 
                                               WHERE D2_FILIAL BETWEEN '' AND 'Z' AND D2_PEDIDO = C6_NUM 
                                                 AND D2_ITEMPV = C6_ITEM AND D2_COD = C6_PRODUTO 
                                                 AND SD2.D_E_L_E_T_ != '*' AND D2_QTDEDEV = 0)
      join items_do_pedido_de_venda ipv (nolock) on ipv.pedido = C6_NUM 
                                                and (ipv.item = (case when C6_MMITBRI <> '' then C6_MMITBRI 
                                                                      when C6_MMITBRI = '' AND ISNUMERIC(C6_ITEM) = 1 
                                                                           THEN CONVERT(VARCHAR(2), CONVERT(INT, C6_ITEM)) 
                                                                end)
                                                 or ipv.cod_produto = C6_PRODUTO)
      LEFT JOIN SC0010 SC0 (NOLOCK) ON C0_FILIAL BETWEEN '' AND 'Z' AND C0_DOCRES = C6_NUM AND C0_PRODUTO = C6_PRODUTO AND SC0.D_E_L_E_T_ != '*' AND C0_SOLICIT <> 'REJETIADO'
      LEFT JOIN SC1010 SC1 (NOLOCK) ON C1_FILIAL BETWEEN '' AND 'Z' AND C1_PVMM = C6_NUM AND C1_PRODUTO = C6_PRODUTO AND SC1.D_E_L_E_T_ != '*' AND C1_FORNECE <> ''
     WHERE C5_FILIAL = ''
       AND C5_EMISSAO >= CONVERT(VARCHAR(8), GETDATE() - 4, 112)
       AND (C5_NUM LIKE '%Z%' OR C5_NUM LIKE '%P%' OR C5_NUM LIKE '%R%')
       AND SC5.D_E_L_E_T_ != '*'
       AND C5_MMCANCE <> 'S'
       AND C5_TIPO = 'N'
       and coalesce(cpv.cancelado,'') <> 'S'
       and coalesce(ipv.cancelado,'') <> 'S'
       AND C1_NUM IS NULL
       AND C0_NUM IS NULL
     ORDER BY C5_EMISSAO, C5_NUM, C6_PRODUTO

    EndSql

    while !(cAls)->(eof())
        aAdd(aPed, {(cAls)->C5_NUM, {(cAls)->C6_PRODUTO}})
        (cAls)->(dbSkip())
    enddo
    
    (cAls)->(dbCloseArea())
	
    for nI := 1 to Len(aPed)
        dbSelectArea("SC5")
        SC5->(dbSetOrder(1))
        if SC5->(dbSeek(xFilial("SC5") + aPed[nI,01]))
            dbSelectArea("SC6")
            SC6->(dbSetOrder(1))
            if SC6->(dbSeek(xFilial("SC6") + SC5->C5_NUM))
                U_MM061(.T., .F., aPed[nI,02])
            endif
        endif
    next nI
return
//
//-------------------------------------------------------------------------------
/*/{Protheus.doc} fChkIntegra
Verifica integracao portal
@return
@author Vinicius Wille
@since 23/10/2018
/*/
//-------------------------------------------------------------------------------
Static Function fChkIntegra()
    Local cQry	:= ''
    Local cAls	:= GetNextAlias()
    Local aArea	:= GetArea()
    cQry := "SELECT C5_NUM FROM SC5010 (nolock) WHERE C5_REVISA = '9' AND D_E_L_E_T_ != '*' "
    TCQuery cQry new alias &cAls
    While !(cAls)->(EOF())
        U_MM496GRV((cAls)->C5_NUM, "F")
        //oPV := TSalesOrder():get((cAls)->C5_NUM)
        //oPV:integrate()
        //FreeObj(oPV)
        //oPV := Nil
        (cAls)->(DbSkip())
    EndDo
	(cAls)->(DbCloseArea())
    RestArea(aArea)
Return
//-------------------------------------------------------------------------------
/*/{Protheus.doc} 328Mnt
Verifica se funcao principal ja esta em execucao
@return
@author Vinicius Wille
@since 05/11/2018
/*/
//-------------------------------------------------------------------------------
User Function 328Mnt()
	Local aRotina	:= GetUserInfoArray() // Resultado: (Informacoes dos processos)
	Local lRet		:= .T.
    Local nR
	For nR := 1 to Len(aRotina)
		//Verifica se o fonte esta na pilha de chamadas
		If "MM328" $ Upper(AllTrim(aRotina[nR][5])) .Or. "MM328" $ Upper(AllTrim(aRotina[nR][11])) .Or. "328THRD" $ Upper(AllTrim(aRotina[nR][5])) .Or. "328THRD" $ Upper(AllTrim(aRotina[nR][11]))
			//Verifica se esta na mesma filial que esta tentando executar novamente
			If cFilAnt $ Upper(AllTrim(aRotina[nR][11]))
				//Verifica se ja em outra thread
				If AllTrim(cValToChar(ThreadID())) <> AllTrim(cValToChar(aRotina[nR][3]))
					U_fConOut("MM328","Thread " + cValToChar(ThreadID()) + " | Rotina ja esta em execucao, esta thread sera encerrada")
					lRet	:= .F.
				EndIf
			EndIf
		EndIf
	Next
Return(lRet)
//-------------------------------------------------------------------------------
/*/{Protheus.doc} fC1Num
Reserva da numeracao sequencial para a SC
@return
@author Vinicius Wille
@since 31/10/2018
/*/
//-------------------------------------------------------------------------------
User Function fC1Num()
Local cC1_NUM := ""
Local cQryNum := ""
Local aArea   := GetArea()
Local cAlsNum := ""//GetNextAlias()
Local cArqSem := "MMfC1Num.sem" //arquivo semafaro
Local cThread := cValToChar(ThreadID())
Local nHandle := -1
	nHandle := FCreate(cArqSem, 1)
	While nHandle == -1
		ConOut("MM328 - Thread " + cThread + " aguardando liberacao de C1_NUM / " + cArqSem)
		Sleep(1)
		nHandle := FCreate(cArqSem, 1)
	End
	ConOut("MM328 - Thread " + cThread + " bloqueou C1_NUM / " + cArqSem)
	cAlsNum := GetNextAlias()
	cQryNum	:= "SELECT MAX(Z1W_C1NUM) AS Z1W_C1NUM " + CRLF
	cQryNum	+= "  FROM Z1W010 (NOLOCK)  " + CRLF
	cQryNum	+= " WHERE D_E_L_E_T_ = ' ' " + CRLF
	TCQuery cQryNum NEW ALIAS &cAlsNum
	cC1_NUM := Soma1(AllTrim((cAlsNum)->Z1W_C1NUM))
	RecLock("Z1W",.T.)
		Z1W->Z1W_C1NUM	:= cC1_NUM
	Z1W->(MsUnlock())
	FClose(nHandle)
	(cAlsNum)->(DbCloseArea())
	ConOut("MM328 - Thread " + cThread + " liberou C1_NUM / " + cArqSem)
	RestArea(aArea)
Return(cC1_NUM)
/**/
Static Function NotaSaida(cPedido)
Local cNota := ""

    If Select(_cAlias1) > 0
        (_cAlias1)->(DBCloseArea())
    End

    BeginSql Alias _cAlias1

    SELECT D2_FILIAL, D2_SERIE, D2_DOC
      FROM %Table:SD2% SD2 (NOLOCK)
     WHERE D2_FILIAL BETWEEN '' AND 'Z'
       AND D2_PEDIDO = %Exp:cPedido%
       AND SD2.D_E_L_E_T_ != '*'
    ORDER BY R_E_C_N_O_ DESC

    EndSql

    If !(_cAlias1)->(Eof())
        cNota := (_cAlias1)->D2_FILIAL + (_cAlias1)->D2_SERIE + (_cAlias1)->D2_DOC
    End
Return cNota
/*/{Protheus.doc} nomeStaticFunction
    Verificar itens que ficaram sem importa, ou seja, a importação do pedido foi parcial
    @type  Static Function
    @author user
    @since 04/11/2021
    @version version
    @param param_name, param_type, param_descr
    @return return_var, return_type, return_description
    @example
    (examples)
    @see (links_or_references)
/*/
Static Function ItImpPVPar()
Local aItens := {}
Local nPosPV := 0, nPosItem := 0
Local cItens := ""
Local cUpdate := ""

    If ValType(_cAlias2) == "U"
        _cAlias2 := GetNextAlias()
    End

    If Select(_cAlias2) > 0
        (_cAlias2)->(DBCloseArea())
    End

    BeginSql Alias _cAlias2
    %NoParser%

    SELECT C5_NUM, C5_EMISSAO, 
           SC6.D_E_L_E_T_ SC6DELET, C6_ITEM, C6_MMITBRI, C6_PRODUTO, ipv.protheus, ipv.item, ipv.cod_produto, ipv.despesa
      FROM SC5010 SC5 (NOLOCK)
      join cabecalho_pedidos_venda cpv (nolock) on cpv.pedido = C5_NUM 
                                               and (cpv.protheus = '1' or (cpv.protheus = '9' and cpv.mensagem like  '%E proibida a reutilizacao do numero do pedido.%')) 
                                               and coalesce(cpv.cancelado,'') != 'S'
      join items_do_pedido_de_venda ipv (nolock) on ipv.pedido = cpv.pedido and coalesce(ipv.cancelado,'') != 'S' and coalesce(ipv.despesa, 'N') = 'N'
      LEFT JOIN SC6010 SC6 (NOLOCK) ON C6_FILIAL = C5_FILIAL AND C6_NUM = C5_NUM
                                   AND (C6_MMITBRI != '' AND C6_MMITBRI = ipv.item
                                    OR C6_PRODUTO = rtrim(ltrim(ipv.cod_produto))
                                    OR (C6_MMITBRI = '' AND C6_ITEM = RIGHT('0' + ipv.item, 2)))
     WHERE C5_FILIAL = ''
       AND C5_EMISSAO >= CONVERT(VARCHAR(8), GETDATE() - 90, 112)
       AND C5_TIPO = 'N'
       AND C5_MMCANCE != 'S'
       //AND COALESCE(C6_MMCANC, '') != 'S'
       AND SC5.D_E_L_E_T_ != '*'
       AND SC6.C6_ITEM IS NULL
     ORDER BY C5_EMISSAO, C5_NUM, ipv.item

    EndSql

    While !(_cAlias2)->(Eof())
        nPosPV := aScan(aItens, {|x| x[1] == AllTrim((_cAlias2)->C5_NUM)   })

        If nPosPV == 0
            aAdd(aItens, {AllTrim((_cAlias2)->C5_NUM), {AllTrim((_cAlias2)->Item)}})
        Else
            nPosItem := aScan(aItens[nPosPV,02], {|x| x == AllTrim((_cAlias2)->Item)  })
            If nPosItem == 0
                aAdd(aItens[nPosPV,02], AllTrim((_cAlias2)->Item))
            End
        End

        (_cAlias2)->(DBSkip())
    End

    (_cAlias2)->(DBCloseArea())

    If Len(aItens) > 0
        For nPosPV := 1 To Len(aItens)
            cItens := ""
            For nPosItem := 1 To Len(aItens[nPosPV,02])
                cItens += If(!Empty(cItens), "/", "") + aItens[nPosPV, 02, nPosItem]
            Next nPosItem

            cItens := FormatIn(cItens, "/")

            cUpdate := "update items_do_pedido_de_venda " + ;
                       "   set protheus = '1' " + ;
                       " where pedido = '" + aItens[nPosPV,01] + "' " + ;
                       "   and item not in " + cItens

            TCSqlExec(cUpdate)

            cUpdate := "update items_do_pedido_de_venda " + ;
                       "   set protheus = '0' " + ;
                       " where pedido = '" + aItens[nPosPV,01] + "' " + ;
                       "   and item in " + cItens

            TCSqlExec(cUpdate)            

            cUpdate := "update cabecalho_pedidos_venda " + ;
                       "   set protheus = '4' " + ;
                       " where pedido = '" + aItens[nPosPV,01] + "' " 

            TCSqlExec(cUpdate)               
        Next nPosPV
    End
Return Nil

/*/{Protheus.doc} nomeStaticFunction
    (long_description)
    @type  Static Function
    @author user
    @since 11/04/2022
    @version version
    @param param_name, param_type, param_descr
    @return return_var, return_type, return_description
    @example
    (examples)
    @see (links_or_references)
/*/
Static Function PVShowRoom()
Local cAlias := GetNextAlias()
Local cUpdate

    BeginSql Alias cAlias
    %NoParser%

    select cpv.pedido, cpv.channel, cpv.cep, cpv.cepentrega, cpv.protheus, cpv.erro, cpv.mensagem
      from cabecalho_pedidos_venda cpv (nolock)
      join items_do_pedido_de_venda ipv (nolock) on ipv.pedido = cpv.pedido
                                                and coalesce(ipv.cancelado,'') = ''
     where cpv.created_at >= '2022-02-01 00:00:00'
       and cpv.protheus = '9'
       and cpv.erro = '1'
       and (cpv.cep = '00099123' or cpv.cepentrega = '00099123')
       and coalesce(cpv.channel,'') != '' 
       and coalesce(cpv.cancelado,'') = ''
       and cpv.mensagem not like 'E proibida a reutilizacao do numero do pedido.%'

    EndSql
    
    If !(cAlias)->(Eof())
        While !(cAlias)->(Eof())
            cUpdate := "update cabecalho_pedidos_venda " + ;
                          "set protheus = '0', erro = '', mensagem = '' " + ;
                        "where pedido = '" + (cAlias)->pedido + "'"
            TCSqlExec(cUpdate)                          
            (cAlias)->(DBSkip())
        End
    End

    (cAlias)->(DBCloseArea())
Return Nil

/*/{Protheus.doc} nomeStaticFunction
    (long_description)
    @type  Static Function
    @author user
    @since 01/06/2022
    @version version
    @param param_name, param_type, param_descr
    @return return_var, return_type, return_description
    @example
    (examples)
    @see (links_or_references)
/*/
Static Function AmaResShow()
Local lAmarra := .T.
Local cFilBkp := cFilAnt
Local oLockPV

    If _cAlias2 == Nil
        _cAlias2 := GetNextAlias()
    Else
        If Select(_cAlias2) > 0
            (_cAlias2)->(DBCloseArea())
        End
    End

    BeginSql Alias _cAlias2
    %NoParser%

    select cpv.pedido, cpv.cep, cpv.cepentrega, C6_NUM, C6_ITEM, C6_PRODUTO, C6_RESERVA, C6_QTDRESE, C6_QTDEMP,
           C9_FILIAL, C9_PEDIDO, C9_ITEM, C9_SEQUEN, C9_PRODUTO, C9_BLEST, C9_BLCRED, SC9.R_E_C_N_O_ RECNOSC9, C9_DATALIB,
           C0_FILIAL, C0_NUM, C0_LOCAL, C0_QUANT, C0_QTDPED
      from cabecalho_pedidos_venda cpv (nolock)
      JOIN SC5010 SC5 (NOLOCK) ON C5_FILIAL = '' AND C5_NUM = cpv.pedido AND SC5.D_E_L_E_T_ != '*' AND C5_MMCANCE != 'S'
      join items_do_pedido_de_venda ipv (nolock) on ipv.pedido = cpv.pedido and coalesce(ipv.cancelado,'') != 'S'
      JOIN SC6010 SC6 (NOLOCK) ON C6_FILIAL = '' AND C6_NUM = ipv.pedido 
                              AND (C6_MMITBRI != '' AND C6_MMITBRI = ipv.item 
                                OR C6_MMITBRI = '' AND C6_PRODUTO = ipv.cod_produto
                                OR C6_MMITBRI = '' AND C6_ITEM = RIGHT('00' + ipv.item,2))
                              AND SC6.D_E_L_E_T_ != '*'
                              AND C6_MMCANC != 'S'
                              AND C6_RESERVA != ''
                              AND NOT EXISTS (SELECT 1 FROM SD2010 SD2 (NOLOCK) WHERE D2_FILIAL >= '' AND D2_PEDIDO = C6_NUM AND D2_ITEMPV = C6_ITEM AND D2_COD = C6_PRODUTO AND SD2.D_E_L_E_T_ != '*')
    JOIN SC0010 SC0 (NOLOCK) ON C0_FILIAL >= '' AND C0_NUM = C6_RESERVA AND C0_DOCRES = C6_NUM AND C0_PRODUTO = C6_PRODUTO AND SC0.D_E_L_E_T_ != '*'
    LEFT JOIN SC9010 SC9 (NOLOCK) ON C9_FILIAL >= '' AND C9_PEDIDO = C6_NUM AND C9_ITEM = C6_ITEM AND C9_PRODUTO = C6_PRODUTO AND SC9.D_E_L_E_T_ != '*'
    where cpv.created_at >= '2022-02-01 00:00:00'
    and (cpv.cep = '00099123' or cpv.cepentrega = '00099123')
    and coalesce(cpv.cancelado,'') != 'S'
    AND (C6_QTDRESE = 0 OR (C0_QUANT = 0 AND C0_QTDPED = 0))
    //AND C0_QUANT > 0

    EndSql

    While !(_cAlias2)->(Eof())
        If !Empty((_cAlias2)->C9_FILIAL)
            oLockPV := TMMLockSalesOrder():New()
            //If (_cAlias2)->C9_DATALIB < Dtos(Date())
            If oLockPV:Lock((_cAlias2)->C6_NUM, {(_cAlias2)->C6_PRODUTO})
                U_ExcluiLib((_cAlias2)->C6_NUM, (_cAlias2)->C6_ITEM, (_cAlias2)->C6_PRODUTO, .T.)
                DbSelectArea("SC6")
                SC6->(dbSetOrder(2))
                if SC6->(dbSeek(xFilial("SC6") + (_cAlias2)->C6_PRODUTO + (_cAlias2)->C6_NUM))
                    RecLock("SC6", .F.)
                        SC6->C6_RESERVA	:= ''   
                        SC6->C6_QTDRESE	:= 0
                    SC6->(MsUnLock())
                    SC6->(DBCommit())
                End

                oLockPV:Unlock()
            End
            FreeObj(oLockPV)
        End

        (_cAlias2)->(DBskip())
    End
    
    (_cAlias2)->(DBCloseArea())

    BeginSql Alias _cAlias2
    %NoParser%

    select cpv.pedido, cpv.cep, cpv.cepentrega, C6_NUM, C6_ITEM, C6_PRODUTO, C6_RESERVA, C6_QTDRESE, C6_QTDEMP,
           C9_FILIAL, C9_PEDIDO, C9_ITEM, C9_SEQUEN, C9_PRODUTO, C9_BLEST, C9_BLCRED, SC9.R_E_C_N_O_ RECNOSC9, 
           C0_FILIAL, C0_NUM, C0_QUANT, C0_QTDPED, C0_LOCAL
      from cabecalho_pedidos_venda cpv (nolock)
      JOIN SC5010 SC5 (NOLOCK) ON C5_FILIAL = '' AND C5_NUM = cpv.pedido AND SC5.D_E_L_E_T_ != '*' AND C5_MMCANCE != 'S'
      join items_do_pedido_de_venda ipv (nolock) on ipv.pedido = cpv.pedido and coalesce(ipv.cancelado,'') != 'S'
      JOIN SC6010 SC6 (NOLOCK) ON C6_FILIAL = '' AND C6_NUM = ipv.pedido 
                              AND (C6_MMITBRI != '' AND C6_MMITBRI = ipv.item 
                                OR C6_MMITBRI = '' AND C6_PRODUTO = ipv.cod_produto
                                OR C6_MMITBRI = '' AND C6_ITEM = RIGHT('00' + ipv.item,2))
                              AND SC6.D_E_L_E_T_ != '*'
                              AND C6_MMCANC != 'S'
                              AND C6_RESERVA = ''
                              AND NOT EXISTS (SELECT 1 FROM SD2010 SD2 (NOLOCK) WHERE D2_FILIAL >= '' AND D2_PEDIDO = C6_NUM AND D2_ITEMPV = C6_ITEM AND D2_COD = C6_PRODUTO AND SD2.D_E_L_E_T_ != '*')
    JOIN SC0010 SC0 (NOLOCK) ON C0_FILIAL >= '' AND C0_DOCRES = C6_NUM AND C0_PRODUTO = C6_PRODUTO AND SC0.D_E_L_E_T_ != '*'
    LEFT JOIN SC9010 SC9 (NOLOCK) ON C9_FILIAL >= '' AND C9_PEDIDO = C6_NUM AND C9_ITEM = C6_ITEM AND C9_PRODUTO = C6_PRODUTO AND SC9.D_E_L_E_T_ != '*'
    where cpv.created_at >= '2022-02-01 00:00:00'
    and (cpv.cep = '00099123' or cpv.cepentrega = '00099123')
    and coalesce(cpv.cancelado,'') != 'S'

    EndSql

    If !(_cAlias2)->(Eof())
        While !(_cAlias2)->(Eof())
            lAmarra := .T.

            If !Empty((_cAlias2)->C9_FILIAL)
                U_ExcluiLib((_cAlias2)->C6_NUM, (_cAlias2)->C6_ITEM, (_cAlias2)->C6_PRODUTO, .T.)

                DbSelectArea("SC9")
                DbSetOrder(1)

                If DBSeek((_cAlias2)->C9_FILIAL + (_cAlias2)->C9_PEDIDO + (_cAlias2)->C9_ITEM + (_cAlias2)->C9_SEQUEN + (_cAlias2)->C9_PRODUTO)
                    lAmarra := .F.
                End
            End

            If lAmarra
                cFilant := (_cAlias2)->C0_FILIAL
                U_MM019((_cAlias2)->C6_NUM, (_cAlias2)->C0_NUM, (_cAlias2)->C6_PRODUTO, (_cAlias2)->C0_LOCAL)
            End

            (_cAlias2)->(DBSkip())
        End
    End

    (_cAlias2)->(DBCloseArea())

    cFilAnt := cFilBkp
Return Nil
