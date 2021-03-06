 #include "protheus.ch"
#include "topconn.ch"
#include "tbiconn.ch"
/*/{Protheus.doc} MM151
	(Abertura de chamados para Funcionarios Demitidos)
	@type  Static Function
	@author JOAO.GOMES
	@since 19/05/2022
	@version 1.0
	@param cDiretoria
	@return cDir'
/*/                        
User Function MM151()
Local cFil := CFILANT
Local _cRet := ""
Local cMail
Local cCCFin := GetMV("MM_MM151") // Centros de custo financeiro
Local lRet := .F.
Local serviceDeskId := cValToChar(GetMV("MM_151SID")) // PARQUINHO : 6 
Local requestTypeId := cValToChar(GetMV("MM_151RID")) // PARQUINHO : 582
Local summary
Local description
Local acustomfield := {}
Local aArea:=GetArea()
Local cDataDemissa
Local cDataAdmissa
Local oEmpresa := JsonObject():new() 

oEmpresa["01"] := "MadeiraMadeira" 
oEmpresa["02"] := "BulkyLog"
oEmpresa["03"] := "iTrack"
oEmpresa["04"] := "IguanaFix"
oEmpresa[""] := "Terceiros"


cDataDemissa:= DToC(M->RA_DEMISSA)
cDataAdmissa:= DToC(M->RA_ADMISSA)

If ALLTRIM(FUNNAME())$"GPEA010/GPEA011"
	_cRet := M->RA_DEMITID
	
	//Faz o envio do email para o financeiro e para stok em casos especificos	
	If M->RA_DEMITID == "1"
		If Alltrim(M->RA_CC) $ cCCFin
			cMail :="desligamentos.fin@madeiramadeira.com.br"
		EndIf
		If M->RA_MAILSO == 'S'
			If Empty(cMail)
				cMail := "desligamentos.stok@madeiramadeira.com.br"
			else
				cMail += ";desligamentos.stok@madeiramadeira.com.br"
			ENDIF
		EndIf
		//Caso cMail esteja preenchido a fun��o MM020 � chamada
		If !Empty(cMail)
			U_MM020(GetMV("MV_RELSERV"),;
					GetMV("MV_RELACNT"),;
					GetMV("MV_RELAUSR" ,,"madeiramadeira"),;
					GetMV("MV_RELPSW") ,;
					GetMV("MV_RELFROM"),;
					cMail,;
					"O Funcion�rio " + M->RA_NOMECMP + " foi Demitido.",;
					"O Funcion�rio " + M->RA_NOMECMP + " - " + Posicione("SRJ",1,xfilial("SRJ")+M->RA_CODFUNC,"RJ_DESC") + " foi Demitido. Email do funcion�rio: " + M->RA_MAILINT + ". Filial: " + SRA->RA_FILIAL + " - Matricula: " + M->RA_MAT + ".")
		EndIf 
		  
		//Coleta de dados para o preenchimento do campo acustonfield
		Aadd(acustomfield, {"customfield_10634", AllTrim(M->RA_NOME)})  //"Nome Completo Funcionario", Obrigat�rio
		Aadd(acustomfield, {"customfield_11311", '{"value":"'+ oEmpresa[SubStr(AllTrim(cFil),1,2)]+'"}'})
		Aadd(acustomfield, {"customfield_10183", AllTrim(M->RA_MAILINT)})  //"email@corporativo", Obrigat�rio
		Aadd(acustomfield, {"customfield_10761", Val(AllTrim(M->RA_MAT))})  //1234, Matr�cula
		Aadd(acustomfield, {"customfield_10671", AllTrim(GetCargo(M->RA_CARGO))})  //"Cargo", Obrigat�rio
		Aadd(acustomfield, {"customfield_10197", AllTrim(GetCCusto(M->RA_CC))})  //"CC Descri��o Centro de Custo", Obrigat�rio Centro de Custo
		Aadd(acustomfield, {"customfield_11332", AllTrim(GetDiretoria(M->RA_MMDIRET, cFil))}) // "Diretoria", Obrigat�rio
		Aadd(acustomfield, {"customfield_10854", AllTrim(M->RA_EMAIL)})  //"email@pessoal", Opcional
		Aadd(acustomfield, {"customfield_10859", AllTrim(M->RA_MAILSUP)})  //"email@gestor", Opcional
		Aadd(acustomfield, {"customfield_10863", SubStr(cDataDemissa, 7, 4) + "-" + SubStr(cDataDemissa, 4, 2) + "-" + SubStr(cDataDemissa, 1, 2)})  //"2021-25-11", Data Demiss�o - Obrigat�rio
		Aadd(acustomfield, {"customfield_10862", SubStr(cDataAdmissa, 7, 4) + "-" + SubStr(cDataAdmissa, 4, 2) + "-" + SubStr(cDataAdmissa, 1, 2)})  //"2021-16-06", Data Admiss�o - Obrigat�rio
		if M->RA_CEP != "" 
			Aadd(acustomfield, {"customfield_10635", AllTrim(M->RA_ENDEREC)+ " " +AllTrim(M->RA_LOGRNUM)})  //"Rua + numero", Campo de texto simples opcional
			Aadd(acustomfield, {"customfield_10637", AllTrim(M->RA_COMPLEM)})  //"Complemento", Opcional
			Aadd(acustomfield, {"customfield_11319", '{"value": "' + AllTrim(M->RA_ESTADO) + '"}'})
			Aadd(acustomfield, {"customfield_11318", AllTrim(M->RA_MUNICIP)})  //{ "value": "Estado", "child": { "value" : "Cidade"} }Opcional
			Aadd(acustomfield, {"customfield_10639", AllTrim(M->RA_CEP)})  //"CEP", Opcional
			Aadd(acustomfield, {"customfield_10640", AllTrim(M->RA_TELEFON)})  //"Telefone" Opcional
		endif
		summary := "Chamado de Desligamento do colaborador " + AllTrim(M->RA_NOME) + ", CARGO: " + AllTrim(GetCargo(M->RA_CARGO)) + "."
		description := "O funcionario " + AllTrim(M->RA_NOME) + " foi demitido, EMAIL: " + AllTrim(RA_MAILINT) + " CARGO: " + AllTrim(GetCargo(M->RA_CARGO)) + "."

		//abertura do chamado	
		lRet:=U_MM537(serviceDeskId,requestTypeId,summary,description,acustomfield)
		
		if lRet != .F.
			U_fConOut("MM151","Chamado aberto com sucesso- matricula funcionario: "+ M->RA_MAT,.T.,.F.)
			_cRet := "3"
			M->RA_DEMITID := "3"
		EndIf

		RestArea(aArea)
		
		If SubStr(M->RA_NOME,1,At(" ",M->RA_NOME)-1) $ UPPER(M->RA_MAILINT)
			cMailMat := M->RA_MAILINT
		ElseIf "@MADEIRAMADEIRA.COM.BR" $ UPPER(M->RA_EMAIL)
			cMailMat := M->RA_EMAIL
		Else
			cMailMat := ""
		EndIf
		
		U_MM167(M->RA_MAT,cMailMat)									
		U_MM167B(M->RA_CIC)
		U_MM188(cMailMat)											
	EndIf
EndIf

Return _cRet

/*/{Protheus.doc} GetCCusto
	(Relaciona a cigla com o centro de custo)
	@type  Static Function
	@author JOAO.GOMES
	@since 19/05/2022
	@version 1.0
	@param cCodigo
	@return cDesc
/*/
Static Function GetCCusto(cCodigo)
	Local cDesc := ""
	
	DbSelectArea("CTT")
	DbSetOrder(1)
	If CTT->(DbSeek(xFilial("CTT") + cCodigo))
		cDesc := CTT->CTT_DESC01
	EndIf
Return cDesc

/*/{Protheus.doc} GetCargo
	(Verifica o cargo do funcionario)
	@type  Static Function
	@author Joao.Gomes
	@since 19/05/2022
	@param cCargo
	@return cDescCarg
/*/
Static Function GetCargo(cCargo)
	Local cDescCarg := ""
	
	DbSelectArea("SQ3")
	DbSetOrder(1)
	If SQ3->(DbSeek(xFilial("SQ3") + cCargo))
		cDescCarg := SQ3->Q3_DESCSUM
	EndIf
Return cDescCarg

/*/{Protheus.doc} GetDiretoria
	@type  Static Function
	@author JOAO.GOMES
	@since 19/05/2022
	@version 1.0
	@param cDiretoria
	@return cDir'
/*/
Static Function GetDiretoria(cDiretoria,cFil)
	Local cDir := ""
	Local aRetSx5
	Local natual
	
	aRetSx5 := FwGetSx5("ZL")
	For nAtual := 1 To Len(aRetSx5)
        If AllTrim(aRetSx5[nAtual][3]) = AllTrim(cDiretoria)
			cDir := aRetSx5[nAtual][4]
		EndIf
    Next
	If Empty(cDir)
		RpcClearEnv()
		RPCSetType(3)
		lEnv := RPCSetEnv('01', '010101')

		aRetSx5 := FwGetSx5("ZL")

		For nAtual := 1 To Len(aRetSx5)
    	    If AllTrim(aRetSx5[nAtual][3]) = AllTrim(cDiretoria)
				cDir := aRetSx5[nAtual][4]
			EndIf
    	Next
	EndIf
Return cDir
      