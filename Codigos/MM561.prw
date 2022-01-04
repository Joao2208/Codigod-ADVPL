#include "protheus.ch"
#include "rwmake.ch"

/*/{Protheus.doc} MM561
    (Ajusta ambiente sincronizado apagando parametros que não podem rodar fora do ambiente de produção)
    @type  Function
    @author Joao Gomes
    @since 23/11/2021
    @version 1.0
    /*/
User Function MM561() 
    Local aAllGroup := {}
    Local aParam := {}
    Local cParName
    Local nCount := 1
    Local cFiL
    Local cAmbName := GetEnvServer()
    Local cMsg := "Voce está no ambiente: " + cAmbName 
    Local cParVal
    Local cDelet := "MM_NMBID|MM_NMBKEY|MM_NBTAXN|MM_NMBURL|MM_WMSLAMB|MM_NEXAPI|MM_NEXTOK"
    Local cQuery

    //Verifica se pode rodar no ambiente conectado
    if "ZB4Z6T_PRD" $ cAmbName  
        If IsBlind()
            ConOut("Rotina não permitida no ambiente de Producao. Ambiente: " + cAmbName)
        Else
            Help(,,"Rotina não permitida neste ambiente." ,,cMsg,1,0)
        EndIf
        Return
    endif

    //Prepara o priemiro ambiente
    If Type('cFilAnt') == 'U'
        RPCSetType(3)
        lEnv := RPCSetEnv('01', '010101')
        IF !lEnv
            ConOut("MM561 - Não conseguiu preparar ambiente")
            Return
        EndIf
    EndIf

    //pega o grupo de empresas 
    aAllGroup := FWAllGrpCompany()
    
    //Roda o codigo para todas as empresas encontradas
    for nCount := 1 to Len(aAllGroup) 
        //Limpa o ambiente para poder entrar nas demais empresas
        RpcClearEnv()
        //prepara o ambiente para cada empresa 
        RPCSetType(3)
        lEnv := RPCSetEnv(aAllGroup[nCount], aAllGroup[nCount] + '0101')
        IF !lEnv
            ConOut("MM561 - Não conseguiu preparar ambiente")
        Return
        EndIf
        
        //Seleciona a tabela e vai para o topo dela 
        DBSelectArea("SX6")
        SX6->(DBGOTOP())

        //Identifica todos os parametros que estão no cDelet ou que possuirem as Palavras MADEIRA E/OU BULKYLOG no cteudo, logo em seguida limpa o conteudo dos que tiverem BULKYLOG/MADEIRA e deleta os encontrados no cDelet 
        while !SX6->(EOF())
            cParVal := SX6->X6_CONTEUD
            cParName := SX6->X6_VAR
            cFil := SX6->X6_FIL
            if VALTYPE(cParVal) == "C"
                if 'MADEIRA' $ UPPER(cParVal) .or. 'BULKYLOG' $ UPPER(cParVal)
                    RecLock("SX6", .F.)
	    	            SX6->X6_CONTEUD := ""
                        SX6->X6_CONTSPA := ""
                        SX6->X6_CONTENG := ""
                    Aadd(aParam, cParName)
	                SX6->(MsUnlock())
                elseif AllTrim(Upper(cParName)) $ cDelet 
                    RecLock("SX6", .F.)
                        SX6->(DBDelete())
                    Aadd(aParam, cParName)
                    SX6->(MsUnlock())
                endif
            endif
            SX6->(DbSkip())
        end

        //SRA - RA_SALARIO, RA_ANTEAUM (Cadastro de funcionário)
        cQuery := "UPDATE " + RetSqlNAme("SRA") + " SET RA_SALARIO = RA_SALARIO / 0.023, RA_ANTEAUM = RA_ANTEAUM / 0.023"
        TCSqlExec(cQuery)
        
        //SRD - RD_VALOR, RD_VALORBA (Acumulado das folhas)
        //--UPDATE SRD010 SET RD_VALOR = RD_VALOR / 0.023, RD_VALORBA = RD_VALORBA / 0.023

        //SRC - RC_VALOR, RC_VALORBA (Movimento mês)
        cQuery := "UPDATE " + RetSqlName("SRC") + " SET RC_VALOR = RC_VALOR * 0.023, RC_VALORBA = RC_VALORBA * 0.023"
        TCSqlExec(cQuery)

        //SRH - RH_SALMES, RH_SALDIA, RH_SALHRS, RH_SALARIO (Cabeçalho Férias)
        cQuery := "UPDATE " + RetSqlNAme("SRH") + " SET RH_SALMES = RH_SALMES * 0.023, RH_SALDIA = RH_SALDIA * 0.023, RH_SALHRS = RH_SALHRS * 0.    023RH_SALARIO = RH_SALARIO * 0.023"
        TCSqlExec(cQuery)

        //SRG - RG_NORMAL, RG_DESCANS, RG_SALMES, RG_SALDIA, RG_SALHORA (Cabeçalho Rescisão)
        cQuery := "UPDATE " + RetSqlNAme("SRG") + " SET RG_NORMAL = RG_NORMAL * 0.023, RG_DESCANS = RG_DESCANS * 0.023, RG_SALMES = RG_SALMES * 023, RG_SALDIA = RG_SALDIA * 0.023, RG_SALHORA = RG_SALHORA * 0.023"
        TCSqlExec(cQuery)

        //SRR - RR_VALOR (ítens férias/rescisões)
        cQuery := "UPDATE " + RetSqlNAme("SRR") + " SET RR_VALOR = RR_VALOR * 0.023"
        TCSqlExec(cQuery)

        //SR3 - R3_VALOR, R3_ANTEAUM (Alterações salariais)
        cQuery := "UPDATE " + RetSqlNAme("SR3") + " SET R3_VALOR = R3_VALOR * 0.023, R3_ANTEAUM = R3_ANTEAUM * 0.023"
        TCSqlExec(cQuery)

        //SRZ - RZ_VALOR (Contabilização)
        cQuery := "UPDATE " + RetSqlNAme("SRZ") + " SET RZ_VAL = RZ_VAL * 0.023"
        TCSqlExec(cQuery)

        //RC1 - RC1_VALOR (Títulos)
        cQuery := "UPDATE " + RetSqlNAme("RC1") + " SET RC1_VALOR = RC1_VALOR * 0.023"
        TCSqlExec(cQuery)

        //T1V - T1V_VLSLFX (Dados do contrato - TAF)
        cQuery := "UPDATE " + RetSqlNAme("T1V") + " SET T1V_VLSLFX = T1V_VLSLFX * 0.023"
        TCSqlExec(cQuery)

        //T3R - T3R_VLRLIQ (Folha enviada para Esocial S1210 - TAF)
        cQuery := "UPDATE " + RetSqlNAme("T3R") + " SET T3R_VLRLIQ = T3R_VLRLIQ * 0.023"
        TCSqlExec(cQuery)

        //RAZ - RAZ_VALOR (Remuneração - S1200 - TAF)
        cQuery := "UPDATE " + RetSqlNAme("RAZ") + " SET RAZ_VALOR = RAZ_VALOR * 0.023"
        TCSqlExec(cQuery)

        //T6W - T6W_VLREMU (Remuneração - S1200 - TAF)
        cQuery := "UPDATE " + RetSqlNAme("T6W") + " SET T6W_VLREMU = T6W_VLREMU * 0.023"
        TCSqlExec(cQuery)

        //CUP - CUP_VLSLFX (Envio de funcionários e diretores - S2200 e S2300 - TAF)
        cQuery := "UPDATE " + RetSqlNAme("CUP") + " SET CUP_VLSLFX = CUP_VLSLFX * 0.023"
        TCSqlExec(cQuery)

    next
Return 
