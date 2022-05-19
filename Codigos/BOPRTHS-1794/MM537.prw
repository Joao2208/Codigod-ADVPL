#INCLUDE "protheus.ch"
#INCLUDE "TOPCONN.CH"
#INCLUDE "TOTVS.CH"
/*/{Protheus.doc} MM537
Integrção com JIRA para abertura de chamados
@type function
@author michael andrade
@since 27/08/2021
@param serviceDeskId, Id do Projeto no JIRA 2=SD
@param requestTypeId, Id do Tipo de chamado 229=Erro de pagamento
@param summary, Titulo do chamado
@param description, Descrição do erro
@param acustomfield, Campos especiais da tipo de chamado [nome,conteudo] ["customfield_10188","Z96699923"] 
       Para o ID 229 o campo customizado 10188 é o numero do pedido.

@return logical, retorna se validou ou não a rotina
/*/
User Function MM537(serviceDeskId,requestTypeId,summary,description,acustomfield)

	Local cURL			:= ""
	Local cURLPath		:= "/rest/servicedeskapi/request"
	Local aHeader		:= {}
    Local cBodyOut      := ""
    Local nCustomFields
    Local lRet          := .F.
    Local cResp         :=''
    Local xValue        := Nil

	Private oResp       := nil

	IF TYPE("cFilAnt") == 'U'
		RpcSetEnv( '01','010101')
	ENDIF   

    //Cria o cabeçalho da requisição
    Aadd(aHeader, "Accept: application/json")
    Aadd(aHeader, "Content-Type: application/json")
    Aadd(aHeader, "Cache-Control: no-cache")
    //https://developer.atlassian.com/cloud/jira/platform/basic-auth-for-rest-apis/
    //BASE64 encode the string: protheus@madeiramadeira.com.br:HKRjF8qZsJUPXVsn67kR36CD
	Aadd(aHeader, "Authorization: Basic am9hby5nb21lc0BtYWRlaXJhbWFkZWlyYS5jb20uYnI6QWUxd0tYT3pzaEpWZ2YwdzhBNjFCQ0I4")
    cUrl:= GetNewPar("MM_URLJIRA","https://madeiramadeira.atlassian.net")

    cBodyOut:= '{'
    cBodyOut+= '"serviceDeskId":'+serviceDeskId+','
    cBodyOut+= '"requestTypeId":'+requestTypeId+','
    cBodyOut+= '"requestFieldValues":{'
    cBodyOut+= '"summary":"'+summary+'",'
    cBodyOut+= '"description":"'+description +'"'
    If Len(acustomfield) >0
        cBodyOut+= ','
        For nCustomFields := 1 to Len(acustomfield)
            //          "customfield_10188"                :"Z96699923"
            //cBodyOut+= '"'+acustomfield[nCustomFields,1]+'":"'+acustomfield[nCustomFields,2] +'"'
            cBodyOut += '"' + acustomfield[nCustomFields,1] + '":'
            xValue := acustomfield[nCustomFields,2]
            
            Do Case 
                Case ValType(xValue) == "C"
                    if left(xValue, 1) == "{" //
                        cBodyOut += '' + xValue + ''
                    else
                       cBodyOut += '"' + xValue + '"' 
                    endif
                Case ValType(xValue) == "J"
                    cBodyOut += xValue:ToJson()
                    FreeObj(xValue)
                Case ValType(xValue) == "N"
                    cBodyOut += cValToChar(xValue)
                OtherWise
                    cBodyOut += 'null' 
            End Case
            
            If nCustomFields<Len(acustomfield)
                cBodyOut+= ','
            Endif
        Next      
    Endif
    cBodyOut+= '}' 
    cBodyOut+= '}' 

    oRest:= FWRest():New(cUrl) 
    oRest:setPath(cURLPath)	
    oRest:SetPostParams(cBodyOut)

    If oRest:Post(aHeader)
        cResp := oRest:GetResult()	
    Endif
    

    //Resposta
    If Empty(cResp)
        cResp:= oRest:cResult
        cErro:= oRest:Getlasterror()
        cMsg := "Falha ao criar JIRA-SD " + Time() + ". Retorno: " + IIF(Type("oRest:oResponseH:cStatusCode") == "C", oRest:oResponseH:cStatusCode, cValToChar(oRest:oResponseH:cStatusCode)) + ' ' + oRest:GetLastError()  
        Conout(cMsg)
    Else
        nPosHdr:= aScan(oRest:oResponseH:aHeaderFields,{|x| x[1]  == "errorMessage"})
        If nPosHdr > 0  
            cMsg := "Falha ao criar JIRA-SD " + Time() + ". Retorno: " + IIF(Type("oRest:oResponseH:cStatusCode") == "C", oRest:oResponseH:cStatusCode, cValToChar(oRest:oResponseH:cStatusCode)) + ' ' + oRest:GetLastError()  
            Conout(cMsg)
        Else
            cMsg := "Sucesso ao criar JIRA-SD " + Time() + ". Retorno: " + IIF(Type("oRest:oResponseH:cStatusCode") == "C", oRest:oResponseH:cStatusCode, cValToChar(oRest:oResponseH:cStatusCode))
            Conout(cMsg)
            lRet:=.T.
        Endif	
    Endif

    FWFreeVar(@oRest)

Return lRet
