#Include 'Protheus.ch'

/*/{Protheus.doc} MM167
Função para integração com portal da MadeiraMaderia, cancelando acesso da matricula informada

U_MM167("987654","teste123teste@madeiramadeira.com.br")

@type function
@author Felipe Toazza Caldeira
@since 03/08/20167
/*/
User Function MM167(cMat,cMail)
//http://portais.madeiramadeira.com.br/api/user-reset?matricula=999999&email=teste123teste@madeiramadeira.com.brLOCAL cEndUrl  := GetNewPar("CP_URLINT","http://vdev-win-dev:9004/N4FATUR-747/api/")
LOCAL cEndUrl  := GetNewPar("MM_URLINT","https://portais.madeiramadeira.com.br/api/")//
LOCAL cJSonRet := ""
LOCAL lRetorno := .T.
LOCAL oObjRet
LOCAL cUrl     := AllTrim(cEndUrl)+"user-reset"
Local nTimeOut := 120
Local aHeadOut := {}
Local cHeadRet := ""
Local sPostRet := ""
Local _cSend := ""

	aadd(aHeadOut,'User-Agent: Mozilla/4.0 (compatible; Protheus '+GetBuild()+')')
	aadd(aHeadOut,'Content-Type: application/json')

	_cSend:='{"matricula":"'+Escape(Alltrim(Str(Val(cMat))))+'"'
	_cSend+=',"email":"'+Escape(cMail)+'"}'	    
//	'{"orderId":"'+cPed+'"}'
	
    sPostRet := HttpPost(cUrl,"",_cSend,nTimeOut,aHeadOut,@cHeadRet)
       
	If valtype(sPostRet) != "C"  //trata erro de retorno
		sPostRet := ""
  	EndIf	          
	
  	If At('"STATUS":200',UPPER(sPostRet)) > 0 .AND. At('"RESPONSE":TRUE',UPPER(sPostRet)) > 0
  		cRet:= " SUCESSO : MATRICULA BLOQUEADA NO PORTAL"
  		lRetorno:= .T.  	
  	Else
		cRet:= " ERRO : NAO FOI POSSIVEL BLOQUEAR A MATRICULA NO PORTAL"
		lRetorno:= .F.  	
  	EndIf

Return {cRet,lRetorno}

User Function MM167B(cCPF)
LOCAL cUrl  := "https://tardis.madeiramadeira.com.br/api/access/inactivate/$2y$10$fpc3c1kNzrQvswhsWQhSvOPLFoOuLAmtsYDlPs74xZZTV.4NJJFWm"
LOCAL cJSonRet := ""
LOCAL lRetorno := .T.
LOCAL oObjRet
Local nTimeOut := 120
Local aHeadOut := {}
Local cHeadRet := ""
Local sPostRet := ""
Local _cSend := ""                   

	aadd(aHeadOut,'User-Agent: Mozilla/4.0 (compatible; Protheus '+GetBuild()+')')
	aadd(aHeadOut,'Content-Type: application/json')

	_cSend:='{"cpf":"'+Escape(Alltrim(cCPF))+'"}'
	
    sPostRet := HttpPost(cUrl,"",_cSend,nTimeOut,aHeadOut,@cHeadRet)
     //sPostRet := HttpPost("https://tardis.madeiramadeira.com.br/api/access/inactivate/$2y$10$fpc3c1kNzrQvswhsWQhSvOPLFoOuLAmtsYDlPs74xZZTV.4NJJFWm","",'{"cpf":"04551366960"}',120,{},"")  
	If valtype(sPostRet) != "C"  //trata erro de retorno
		sPostRet := ""
  	EndIf	          
	
  	If At('"STATUS":200',UPPER(sPostRet)) > 0 .AND. At('"RESPONSE":TRUE',UPPER(sPostRet)) > 0
  		cRet:= " SUCESSO : CPF BLOQUEADO NO PORTAL"
  		lRetorno:= .T.  	
  	Else
		cRet:= " ERRO : NAO FOI POSSIVEL BLOQUEAR O CPF NO PORTAL"
		lRetorno:= .F.  	
  	EndIf

Return {cRet,lRetorno}