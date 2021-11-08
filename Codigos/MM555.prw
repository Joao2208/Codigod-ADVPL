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

User Function MM555()
Local cEstNeg    := GetMV("MV_ESTNEG")

if cEstNeg != "N"
    RpcSetEnv('01', '010101')
	// Envia Email 
	U_MM020(    GetMV("MV_RELSERV")                                                   ,;
                GetMV("MV_RELACNT")                                                   ,;
                GetMV("MV_RELAUSR",,"madeiramadeira")                                 ,;
                GetMV("MV_RELPSW")                                                    ,;
                GetMV("MV_RELFROM")                                                   ,;
                "protheus@madeiramadeira.com.br"                                      ,;
                "*****!!Paramentro do MV_ESTNEG esta igual ao do padrão 'N'!!*****"   )

	RpcClearEnv()    
endif

Return

