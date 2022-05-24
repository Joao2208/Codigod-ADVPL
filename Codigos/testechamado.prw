/*/{Protheus.doc} MMtesteEnv()

    (long_description)
    @type  Static Function
    @author user
    @since date
    @version version
    @param param, param_type, param_descr
    @return return, return_type, return_description
    @example
    (examples)
    @see (links_or_references)
    /*/
USER Function MMtesteEnv()
    Local acustonfield2 := {}
    Local lRet

    Aadd(acustonfield2, {"customfield_11090", "11111"})
    Aadd(acustonfield2, {"customfield_11196", '{"value":"Pedidos"}'})
    Aadd(acustonfield2, {"customfield_11632", '{"value":"Importação de pedidos"}'})
    lRet := U_MM537("6"          ,"582"        ,"Pagamento nao retornado","teste"  ,acustonfield2)
Return lRet
