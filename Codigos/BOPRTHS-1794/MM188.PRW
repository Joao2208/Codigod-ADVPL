#Include 'Protheus.ch'

/*/{Protheus.doc} MM188
Função para integração com portal da MadeiraMaderia, cancelando acesso do e-mail informado

U_MM188("usuario.teste@madeiramadeira.com.br")

@type function
@since 03/08/20167
/*/
User Function MM188(cMail)

	Local cURL     		:= "http://admm.madeiramadeira.com.br"
	Local cURLPath 		:= "/admm/v1/demissao "
	Local cUser 		:= GetMV("MM_155USR", .f., "protheus") //mesmo user 
	Local cPass 		:= GetMV("MM_155PWD", .f., "Fdfim3F4543hfDrnkf")//mesmo pass
	Local aHeader 		:= {}
	Local cAlsPro		:= GetNextAlias()
	Local cJSON 		:= ""
	local cQRC			:= ""
	
	Aadd(aHeader, "Authorization: Basic " + Encode64(cUser+":"+cPass))
	Aadd(aHeader, "Content-Type: application/json ")

	oRestClient := FWRest():New(cURL)                                
	oRestClient:SetPath(cURLPath)
			
	cJSON :=  '{"email":"'+alltrim(cMail)+'"}'

	oRestClient:Put(aHeader, cJSON)  
	If oRestClient:oresponseh:cStatusCode != '204'
	   	Alert('Usuário não bloqueado no Firstclass')
	EndIF

Return 
