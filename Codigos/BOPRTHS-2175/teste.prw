#include "tbiconn.ch"
#include "topconn.ch"
#include 'protheus.ch'
#Include "Totvs.ch"


User Function MM2208()
    Local cPedido := "Z25632183"
    Local cPedidoPai := "25632182"
    Local acustonfield3 := {}
    Local cMensagem
    Local aArray := {}
    Local lResp
    Local cPayLoad

        aArray := U_BuscaPGTO(cPedidoPai)
        If Len(aArray) > 1
            lResp := aArray[2]
            cPayLoad := aArray[1]
        else
            lResp := aArray[1]
            cPayLoad := "PayLoad não retornado"
        endif

        If !lResp
            cMensagem := "A Rotina MM328-Importacao de pedidos, identificou o pedido " + cPedido + " sem detalhes de pagamento enviados pelo Black Panter. Pedido pai: " + cPedidoPai +"- PAYLOAD retornado do BP: "+ cPayLoad //+"'" payload do bp.
            //JIRA (serviceDeskId,requestTypeId,summary                  ,description,acustomfield)
            Aadd(acustonfield3, {"customfield_11090", Val(cPedidoPai)})
            Aadd(acustonfield3, {"customfield_11196", '{"value":"Pedidos"}'})
            Aadd(acustonfield3, {"customfield_11200", EncodeUtf8('{"value":"Importação de pedidos"}')})
            U_MM537("6"          ,"880"        ,"Pagamento nao retornado",cMensagem  ,acustonfield3)
        ENDIF
Return
