#INCLUDE 'protheus.ch'

User Function MM999()
Local acustonfield := {}

    Aadd(acustonfield, {"customfield_11267",'{"value":"Processo interno"}'}) 
    Aadd(acustonfield, {"customfield_10107",'{"value":"Outros"}'}) 
    
    U_MM537("6", "880", "Erro TES Inteligente Importacao de Pedidos", " teste", acustonfield)
Return 
