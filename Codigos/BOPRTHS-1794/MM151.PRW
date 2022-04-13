#include "protheus.ch"
#include "topconn.ch"
#include "tbiconn.ch"

//Envia E-mail Funcionario Demitido                         
User Function MM151()
Local _cRet := ""
Local cCCFin := GetMV("MM_MM151") // Centros de custo financeiro

If ALLTRIM(FUNNAME())$"GPEA010/GPEA011"
	_cRet := M->RA_DEMITID
		
	If M->RA_DEMITID == "1"
		If Alltrim(M->RA_CC) $ cCCFin
			cMail := "chamados@madeiramadeira.com.br;protheus@madeiramadeira.com.br;chamados.jira@madeiramadeira.com.br;alertadesligamento@madeiramadeira.com.br"
		  Else
		  	cMail := "chamados@madeiramadeira.com.br;protheus@madeiramadeira.com.br;chamados.jira@madeiramadeira.com.br"
		EndIf
		If M->RA_MAILSO == 'S'
			cMail += ";"+Alltrim(GetMV("MM_MAILSTO"))
		EndIf
//		cMail += ";"+Alltrim(GetMV("MM_MAILMUR"))//cemuralha.recepcao@gmail.com
		
		_cRet := "3"
		
		U_MM020(	GetMV("MV_RELSERV"),;
					GetMV("MV_RELACNT"),;
					GetMV("MV_RELAUSR" ,,"madeiramadeira"),;
					GetMV("MV_RELPSW") ,;
					GetMV("MV_RELFROM"),;
					cMail,;
					"O Funcionário " + M->RA_NOMECMP + " foi Demitido.",;
					"O Funcionário " + M->RA_NOMECMP + " - " + Posicione("SRJ",1,xfilial("SRJ")+M->RA_CODFUNC,"RJ_DESC") + " foi Demitido. Email do funcionário: " + M->RA_MAILINT + ".")

		M->RA_DEMITID := "3"   
		If SubStr(M->RA_NOME,1,At(" ",M->RA_NOME)-1) $ UPPER(M->RA_MAILINT)
			cMailMat := M->RA_MAILINT
		ElseIf "@MADEIRAMADEIRA.COM.BR" $ UPPER(M->RA_EMAIL)
			cMailMat := M->RA_EMAIL
		Else
			cMailMat := ""
		EndIf       
		
		U_MM537(serviceDeskId,requestTypeId,summary,description,acustomfield)
		
		




		U_MM167(M->RA_MAT,cMailMat)									
		U_MM167B(M->RA_CIC)
		U_MM188(cMailMat)											
	EndIf
EndIf

Return _cRet



