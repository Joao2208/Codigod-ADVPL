#include "protheus.ch"
#include "topconn.ch"
#include "tbiconn.ch"

//Envia E-mail Funcionario Demitido                         
User Function MM151()
Local _cRet := ""
//Local cCCFin := GetMV("MM_MM151") // Centros de custo financeiro
Local lRet := .F.
Local serviceDeskId :=  "6" 	//cValToChar(GetMV("MM_151SID"))
Local requestTypeId := 	"582"	//cValToChar(GetMV("MM_151RID"))
Local summary
Local description
Local acustomfield := {}
Local cDataDemissa
Local cDataAdmissa
Local cCC
Local oCargo := JsonObject():new() 

cCC := FWUsrEmp(M->RA_MAT)



/*
DbSelectArea("SQ3")
DbSetOrder(1)
While !(SQ3)->(EoF())
	if SQ3->Q3_CARGO = M
		cCC += SQ3->Q3_DESCSUM
	endif
end
*/

cDataDemissa:= DToC(M->RA_DEMISSA)
cDataAdmissa:= DToC(M->RA_ADMISSA)

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
		Aadd(acustomfield, {"customfield_10634", AllTrim(M->RA_NOME)})  //"Nome Completo Funcionario", Obrigatório
		Aadd(acustomfield, {"customfield_10183", AllTrim(M->RA_MAILINT)})  //"email@corporativo", Obrigatório
		Aadd(acustomfield, {"customfield_10761", Val(AllTrim(M->RA_MAT))})  //1234, Matrícula
		Aadd(acustomfield, {"customfield_10671", oCargo[AllTrim(M->RA_CARGO)]})  //"Cargo", Obrigatório
		Aadd(acustomfield, {"customfield_10197", AllTrim(M->RA_CC)})  //"CC Descrição Centro de Custo", Obrigatório Centro de Custo
		Aadd(acustomfield, {"customfield_10864", '{"value" : "' + oDir[AllTrim(M->RA_MMDIRET)] + '"}'})  //{ "value": "Diretoria" }, Obrigatório
		Aadd(acustomfield, {"customfield_10854", AllTrim(M->RA_EMAIL)})  //"email@pessoal", Opcional
		Aadd(acustomfield, {"customfield_10859", AllTrim(M->RA_MAILSUP)})  //"email@gestor", Opcional
		Aadd(acustomfield, {"customfield_10863", SubStr(cDataDemissa, 7, 4) + "-" + SubStr(cDataDemissa, 4, 2) + "-" + SubStr(cDataDemissa, 1, 2)})  //"2021-25-11", Data Demissão - Obrigatório
		Aadd(acustomfield, {"customfield_10862", SubStr(cDataAdmissa, 7, 4) + "-" + SubStr(cDataAdmissa, 4, 2) + "-" + SubStr(cDataAdmissa, 1, 2)})  //"2021-16-06", Data Admissão - Obrigatório
		if M->RA_CEP != "" 
			Aadd(acustomfield, {"customfield_10635", AllTrim(M->RA_ENDEREC)+ " " +AllTrim(M->RA_LOGRNUM)})  //"Rua + numero", Campo de texto simples opcional
			Aadd(acustomfield, {"customfield_10637", AllTrim(M->RA_COMPLEM)})  //"Complemento", Opcional
			//Aadd(acustomfield, {"customfield_10633", '{ "value": "' +AllTrim(M->RA_ESTADO)+ '", "child": { "value" :"' + AllTrim(M->RA_MUNICIP) +'" }}'})  //{ "value": "Estado", "child": { "value" : "Cidade"} }Opcional
			Aadd(acustomfield, {"customfield_10639", AllTrim(M->RA_CEP)})  //"CEP", Opcional
			Aadd(acustomfield, {"customfield_10640", AllTrim(M->RA_TELEFON)})  //"Telefone" Opcional
		endif
		summary := "Chamado de Desligamento do colaborador " + AllTrim(M->RA_NOME) + "."
		description := "O funcionario " + AllTrim(M->RA_NOME) + " foi demitido, EMAIL: " + AllTrim(RA_EMAIL) + " CARGO: " + oCargo[AllTrim(M->RA_CARGO)]

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
