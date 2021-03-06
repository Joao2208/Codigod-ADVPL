#INCLUDE 'totvs.ch'
#INCLUDE 'topconn.ch'

/*/{Protheus.doc} MM577
    (Fun��o para procurar funcionarios demitidos, mas que as permissoes n�o foram retiradas)
    @type  Static Function
    @author JOAO.GOMES
    @since 13/04/2022
    @version 1.0
/*/
User Function MM583(aParam)
    Local acustomfield := {}
    Local serviceDeskId := GetMV("MM_151SID")
    Local requestTypeId := GetMV("MM_151RID")
    Local summary
    Local description
    Local aMat
    Local lRet
    Local _cRet
    Local cQry
    Local cAls
    Local cCount

    _cRet := M->RA_DEMITID

    If Type('cFilAnt') == 'U'
        RPCSetType(3)
        lEnv := RPCSetEnv(aParam[1], aParam[2])
        IF !lEnv
            ConOut("MM561 - N�o conseguiu preparar ambiente")
            Return
        EndIf
    EndIf

    cQry := "SELECT * FROM " + RetSqlName("SRA") + "WHERE"
    cQry += "(RA_DEMITID = '2' AND RA_DEMISSA > '20220401')"
    cQry += "OR RA_DEMITID = '1'"
    TCQuery cQry new alias &cAls

    while cAls->(EoF())
        Aadd(aMat, cAls->RA_MAT)
        cAls->(dbSkip())
    end
    cCount := Len(aMat)
    
    while cCount != "0"
        if cAls->RA_MAT == aMat[cCount]
            Aadd(acustomfield, {"customfield_10634:", cAls->RA_NOME})  //"Nome Completo Funcionario", Obrigat�rio
		    Aadd(acustomfield, {"customfield_10183:", cAls->RA_MAILINT})  //"email@corporativo", Obrigat�rio
		    Aadd(acustomfield, {"customfield_10761:", cAls->RA_MAT})  //1234, Matr�cula
		    Aadd(acustomfield, {"customfield_10671:", cAls->RA_CARGO})  //"Cargo", Obrigat�rio
		    Aadd(acustomfield, {"customfield_10197:", cAls->RA_CC})  //"CC Descri��o Centro de Custo", Obrigat�rio Centro de Custo
		    Aadd(acustomfield, {"customfield_10864:", cAls->RA_MMDIRET})  //{ "value": "Diretoria" }, Obrigat�rio
		    Aadd(acustomfield, {"customfield_10854:", cAls->RA_EMAIL})  //"email@pessoal", Opcional
		    Aadd(acustomfield, {"customfield_10859:", cAls->RA_MAILSUP})  //"email@gestor", Opcional
		    Aadd(acustomfield, {"customfield_10863:", cAls->RA_DEMISSA})  //"2021-25-11", Data Demiss�o - Obrigat�rio
		    Aadd(acustomfield, {"customfield_10859:", cAls->RA_ADMISSA})  //"2021-16-06", Data Admiss�o - Obrigat�rio
		    if cAls->RA_CEP != "" 
		    	Aadd(acustomfield, {"customfield_10635:", cAls->RA_ENDEREC + M->RA_LOGRNUM})  //"Rua + numero", Campo de texto simples opcional
		    	Aadd(acustomfield, {"customfield_10637:", cAls->RA_COMPLEM})  //"Complemento", Opcional
		    	Aadd(acustomfield, {"customfield_10633:", cAls->RA_MUNICIP + M->RA_ESTADO})  //{ "value": "Estado", "child": { "value" : "Cidade"} }Opcional
		    	Aadd(acustomfield, {"customfield_10639:", cAls->RA_CEP})  //"CEP", Opcional
		    	Aadd(acustomfield, {"customfield_10640:", cAls->RA_TELEFON})  //"Telefone" Opcional
		    endif
		    summary := "Chamado de Desligamento do colaborador" + M->RA_NOME
		    description := "O funcionario " + M->RA_NOME + " foi demitido, EMAIL: " + RA_EMAIL

            lRet:=U_MM537(serviceDeskId,requestTypeId,summary,description,acustomfield)
            if lRet == .F.
                ConOut("Erro na chamada da fun��o MM537")
            endif
            cCount -= "1"
        endif
    end
Return 
