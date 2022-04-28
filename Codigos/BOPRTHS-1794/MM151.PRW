#include "protheus.ch"
#include "topconn.ch"
#include "tbiconn.ch"

//Envia E-mail Funcionario Demitido                         
User Function MM151()
Local _cRet := ""
Local cCCFin := GetMV("MM_MM151") // Centros de custo financeiro
Local lRet := .F.
Local serviceDeskId := GetMV("MM_151SID")
Local requestTypeId := GetMV("MM_151RID")
Local summart
Local description
Local acustomfield := {}


If ALLTRIM(FUNNAME())$"GPEA010/GPEA011"
	_cRet := M->RA_DEMITID
		
	If M->RA_DEMITID == "1"
		/*
		If Alltrim(M->RA_CC) $ cCCFin
			cMail := "chamados@madeiramadeira.com.br;protheus@madeiramadeira.com.br;chamados.jira@madeiramadeira.com.br;alertadesligamento@madeiramadeira.com.br"
		Else
		  	cMail := "chamados@madeiramadeira.com.br;protheus@madeiramadeira.com.br;chamados.jira@madeiramadeira.com.br"
		EndIf
		If M->RA_MAILSO == 'S'
			cMail += ";"+Alltrim(GetMV("MM_MAILSTO"))
		EndIf
		*/
		//		cMail += ";"+Alltrim(GetMV("MM_MAILMUR"))//cemuralha.recepcao@gmail.com    
		/*
		_cRet := "3"
		
			U_MM020(GetMV("MV_RELSERV"),;
					GetMV("MV_RELACNT"),;
					GetMV("MV_RELAUSR" ,,"madeiramadeira"),;
					GetMV("MV_RELPSW") ,;
					GetMV("MV_RELFROM"),;
					cMail,;
					"O Funcionário " + M->RA_NOMECMP + " foi Demitido.",;
					"O Funcionário " + M->RA_NOMECMP + " - " + Posicione("SRJ",1,xfilial("SRJ")+M->RA_CODFUNC,"RJ_DESC") + " foi Demitido. Email do funcionário: " + M->RA_MAILINT + ".")
			M->RA_DEMITID := "3"
		/*/   
		  
		//Coleta de dados para o preenchimento do campo acustonfield
		Aadd(acustomfield, {"customfield_10634:", M->RA_NOME})  //"Nome Completo Funcionario", Obrigatório
		Aadd(acustomfield, {"customfield_10183:", M->RA_MAILINT})  //"email@corporativo", Obrigatório
		Aadd(acustomfield, {"customfield_10761:", M->RA_MAT})  //1234, Matrícula
		Aadd(acustomfield, {"customfield_10671:", M->RA_CARGO})  //"Cargo", Obrigatório
		Aadd(acustomfield, {"customfield_10197:", M->RA_CC})  //"CC Descrição Centro de Custo", Obrigatório Centro de Custo
		Aadd(acustomfield, {"customfield_10864:", M->RA_MMDIRET})  //{ "value": "Diretoria" }, Obrigatório
		Aadd(acustomfield, {"customfield_10854:", M->RA_EMAIL})  //"email@pessoal", Opcional
		Aadd(acustomfield, {"customfield_10859:", M->RA_MAILSUP})  //"email@gestor", Opcional
		Aadd(acustomfield, {"customfield_10863:", M->RA_DEMISSA})  //"2021-25-11", Data Demissão - Obrigatório
		Aadd(acustomfield, {"customfield_10859:", M->RA_ADMISSA})  //"2021-16-06", Data Admissão - Obrigatório
		if M->RA_CEP != "" 
			Aadd(acustomfield, {"customfield_10635:", M->RA_ENDEREC + M->RA_LOGRNUM})  //"Rua + numero", Campo de texto simples opcional
			Aadd(acustomfield, {"customfield_10637:", M->RA_COMPLEM})  //"Complemento", Opcional
			Aadd(acustomfield, {"customfield_10633:", M->RA_MUNICIP + M->RA_ESTADO})  //{ "value": "Estado", "child": { "value" : "Cidade"} }Opcional
			Aadd(acustomfield, {"customfield_10639:", M->RA_CEP})  //"CEP", Opcional
			Aadd(acustomfield, {"customfield_10640:", M->RA_TELEFON})  //"Telefone" Opcional
		endif
		summary := "Chamado de Desligamento do colaborador" + M->RA_NOME
		description := "O funcionario " + M->RA_NOME + " foi demitido, EMAIL: " + RA_EMAIL

		lRet:=U_MM537(serviceDeskId,requestTypeId,summary,description,acustomfield)
		
		if lRet != .F.
			ConOut("Chamado aberto com sucesso")
			_cRet := "3"
			M->RA_DEMITID := "3"
		EndIf
		
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
