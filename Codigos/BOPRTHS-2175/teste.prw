#include "tbiconn.ch"
#include "topconn.ch"
#include 'protheus.ch'
#Include "Totvs.ch"


User Function MM2208()
    Local cPedido := "Z25632169"
    Local cPedidoPai := "25632168"
    Local acustonfield3 := {}
    Local cMensagem
    Local aArray := {}
    Local lResp
    Local cPayLoad
    //Local xValue        := Nil

        aArray := U_BuscaPGTO(cPedidoPai)
        If Len(aArray) > 1
            lResp := aArray[2]
            cPayLoad := aArray[1]
        endif
        cPayload:= StrTran(cPayload,'"','')

        If !lResp
            cMensagem := " -TESTE- A Rotina MM328-Importacao de pedidos, identificou o pedido " + cPedido + " sem detalhes de pagamento enviados pelo Black Panter. Pedido pai: " + cPedidoPai + " - PAYLOAD retornado do BP: -- " + cPayLoad + " --" //payload do bp.
            //JIRA (serviceDeskId,requestTypeId,summary                  ,description,acustomfield)
            Aadd(acustonfield3, {"customfield_11090", Val(cPedidoPai)})
            Aadd(acustonfield3, {"customfield_11196", '{"value":"Pedidos"}'})
            Aadd(acustonfield3, {"customfield_11200", EncodeUtf8('{"value":"Importação de pedidos"}')})
            U_MM537("52"          ,"881"        ,"Pagamento nao retornado",cMensagem  ,acustonfield3)
        ENDIF
Return
