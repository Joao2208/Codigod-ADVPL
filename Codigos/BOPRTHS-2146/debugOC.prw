/*/{Protheus.doc} User Function EnvioOC
    (long_description)
    @type  Function
    @author user
    @since 01/06/2022
    @version version
    @param param_name, param_type, param_descr
    @return return_var, return_type, return_description
    @example
    (examples)
    @see (links_or_references)
    /*/
User Function EnvioOC()
    Local lTentativ
    
    RPCSetEnv('01','010101')

    lTentativ := U_fIntegra("8858561", 'PURCHASE_ORDER_VIEWED_PROTHEUS')

Return lTentativ
