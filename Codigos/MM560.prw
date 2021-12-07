#include "protheus.ch"
#include "rwmake.ch"

/*/{Protheus.doc} MM560
    (Ajusta ambiente sincronizado apagando parametros que não podem rodar fora do ambiente de produção)
    @type  Function
    @author Joao Gomes
    @since 23/11/2021
    @version 1.0
    /*/
User Function MM560()
    Local cAmbName := GetEnvServer()
    //ocal cName
    Local cParName
    Local nCol := 1
    Local cFil
    Local cParVal
    Local cDelet := "MM_NMBID|MM_NMBKEY|MM_NBTAXN|MM_NMBURL|MM_WMSLAMB|MM_NEXAPI|MM_NEXTOK"
    Local aParam := {}
    Local cQuery
    if "ZB4Z6T_PRD" $ cAmbName  
        Return
    endif
    
    //Prepara o Ambiente
    If Type('cFilAnt') == 'U'
        RPCSetType(3)
        lEnv := RPCSetEnv('01', '010101')
    IF !lEnv
        ConOut("MM560 - Não conseguiu preparar ambiente")
        Return
    EndIf
    EndIf

    DBSelectArea("SX6")
    SX6->(DBGOTOP())
    
    while !SX6->(EOF())
        cParVal := SX6->X6_CONTEUD
        cParName := SX6->X6_VAR
        cFil := SX6->X6_FIL
        if VALTYPE(cParVal) == "C"
            if 'MADEIRA' $ UPPER(cParVal) .or. AllTrim(Upper(cParName)) $ cDelet
                Aadd(aParam, {cFil, cParName})
            endif
        endif
        SX6->(DbSkip())
    end


    while nCol <= Len(aParam)
        //PutMV(aParam[nCol][1], " ")//Ou da pra colocar o valor como nill? 
    end

    //Deleta os parametros
    while nCol <= Len(aParam)
        SX6->(DbSeek(aParam[nCol][1] + aParam[nCol][2]))
        RecLock("SX6", .F.)
		    SX6->X6_CONTEUD := ""
            //SX6->(DBDelete())
	    SX6->(MsUnlock())
    end

    //Fecha a tabela
    DbCloseArea()

    /*SRA - RA_SALARIO, RA_ANTEAUM (Cadastro de funcionário)*/
    cQuery := "UPDATE " + RetSqlNAme("SRA") + " SET RA_SALARIO = RA_SALARIO * 0.023, RA_ANTEAUM = RA_ANTEAUM * 0.023"+ CRLF
    //SRD - RD_VALOR, RD_VALORBA (Acumulado das folhas)
    //--UPDATE SRD010 SET RD_VALOR = RD_VALOR * 0.023, RD_VALORBA = RD_VALORBA * 0.023
    //SRC - RC_VALOR, RC_VALORBA (Movimento mês)*/
    cQuery += "UPDATE " + RetSqlName("SRC") + " SET RC_VALOR = RC_VALOR * 0.023, RC_VALORBA = RC_VALORBA * 0.023"+ CRLF
    /*SRH - RH_SALMES, RH_SALDIA, RH_SALHRS, RH_SALARIO (Cabeçalho Férias)*/
    cQuery += "UPDATE " + RetSqlNAme("SRH") + " SET RH_SALMES = RH_SALMES * 0.023, RH_SALDIA = RH_SALDIA * 0.023, RH_SALHRS = RH_SALHRS * 0.023, RH_SALARIO = RH_SALARIO * 0.023"+ CRLF
    /*SRG - RG_NORMAL, RG_DESCANS, RG_SALMES, RG_SALDIA, RG_SALHORA (Cabeçalho Rescisão)*/
    cQuery += "UPDATE " + RetSqlNAme("SRG") + " SET RG_NORMAL = RG_NORMAL * 0.023, RG_DESCANS = RG_DESCANS * 0.023, RG_SALMES = RG_SALMES * 0.023, RG_SALDIA = RG_SALDIA * 0.023, RG_SALHORA = RG_SALHORA * 0.023"+ CRLF
    /*SRR - RR_VALOR (ítens férias/rescisões)*/
    cQuery += "UPDATE " + RetSqlNAme("SRR") + " SET RR_VALOR = RR_VALOR * 0.023"+ CRLF
    /*SR3 - R3_VALOR, R3_ANTEAUM (Alterações salariais)*/
    cQuery += "UPDATE " + RetSqlNAme("SR3") + " SET R3_VALOR = R3_VALOR * 0.023, R3_ANTEAUM = R3_ANTEAUM * 0.023"+ CRLF
    /*SRZ - RZ_VALOR (Contabilização)*/
    cQuery += "UPDATE " + RetSqlNAme("SRZ") + " SET RZ_VAL = RZ_VAL * 0.023"+ CRLF
    /*RC1 - RC1_VALOR (Títulos)*/
    cQuery += "UPDATE " + RetSqlNAme("RC1") + " SET RC1_VALOR = RC1_VALOR * 0.023"+ CRLF
    /*T1V - T1V_VLSLFX (Dados do contrato - TAF)*/
    cQuery += "UPDATE " + RetSqlNAme("T1V") + " SET T1V_VLSLFX = T1V_VLSLFX * 0.023"+ CRLF
    /*T3R - T3R_VLRLIQ (Folha enviada para Esocial S1210 - TAF)*/
    cQuery += "UPDATE " + RetSqlNAme("T3R") + " SET T3R_VLRLIQ = T3R_VLRLIQ * 0.023"+ CRLF
    /*RAZ - RAZ_VALOR (Remuneração - S1200 - TAF)*/
    cQuery += "UPDATE " + RetSqlNAme("RAZ") + " SET RAZ_VALOR = RAZ_VALOR * 0.023"+ CRLF
    /*T6W - T6W_VLREMU (Remuneração - S1200 - TAF)*/
    cQuery += "UPDATE " + RetSqlNAme("T6W") + " SET T6W_VLREMU = T6W_VLREMU * 0.023"+ CRLF
    /*CUP - CUP_VLSLFX (Envio de funcionários e diretores - S2200 e S2300 - TAF)*/
    cQuery += "UPDATE " + RetSqlNAme("CUP") + " SET CUP_VLSLFX = CUP_VLSLFX * 0.023"+ CRLF

    //TCSqlExec(cQuery)

Return 
