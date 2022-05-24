#include 'protheus.ch'

/*/{Protheus.doc} User Function MM111
    (long_description)
    @type  Function
    @author user
    @since 23/05/2022
    @version version
    @param param_name, param_type, param_descr
    @return return_var, return_type, return_description
    @example
    (examples)
    @see (links_or_references)
    /*/
User Function MM111()
acustonfield3 := {}
    
Aadd(acustonfield3, {"customfield_11138", '{"value": "Protheus"}'})
Aadd(acustonfield3, {"customfield_11143", '{"value": "Saldo"}'})
Aadd(acustonfield3, {"customfield_11186", '{"value": "Saldo negativo"}'})

U_MM537("6",;
        "880",;
        "[PEDIDO SALDAO GUIDE SHOP]",;
        "Guide Filial CNPJ Pedido sku ",;
        acustonfield3)
RETURN

