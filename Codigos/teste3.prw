#INCLUDE 'protheus.ch'

User Function MM992()
Local acustonfield := {}

    Aadd(acustonfield, {"customfield_11196", '{"value": "Pedidos"}'}) 
    Aadd(acustonfield, {"customfield_11200", EncodeUtf8('{"value": "Importação de pedidos"}')})
    Aadd(acustonfield, {"customfield_11090", Val("555555")}) 
    
    U_MM537("6", "880", "teste testado", " teste", acustonfield)
Return 
