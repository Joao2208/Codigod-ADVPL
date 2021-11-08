
#include "protheus.ch"
#include "rwmake.ch"

//-------------------------------------------------------------------------------
/*/
{Protheus.doc} MM555
Vereificação de parametros, com aviso via email

@return 
@author Joao Gomes
@since 08/11/2021
/*/
//-------------------------------------------------------------------------------

User Function MM169()
Local cEstNeg    := GetMV("MV_ESTNEG")

if cEstNeg != "N"
    //RpcSetEnv('01', '010102')
	// Envia 
	U_MM020(    GetMV("MV_RELSERV")                                                                 ,;
                GetMV("MV_RELACNT")                                                                 ,;
                GetMV("MV_RELAUSR",,"madeiramadeira")                                               ,;
                GetMV("MV_RELPSW")                                                                  ,;
                "joao.gomes@madeiramadeira.com.br"                                                  ,;
                "Paramentro do MV_ESTNEG está diferente do padrão 'N' "                             ,;
)

	RpcClearEnv()    

endif

Return

