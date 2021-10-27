#include 'totvs.ch'
#include 'protheus.ch'
#include 'parmtype.ch'

User Function JG2021()
    Local aArea := GetArea()
    Local aDados:= {}
    Private lMSErroAuto := .F.

    aDados := {;
                {"B1_COD", "030822",         Nil},;
                {"B1_DESC", "PRODUTO TESTE", Nil},;
                {"B1_TIPO", "GG",            Nil},;
                {"B1_UM", "PC",              Nil},;
                {"B1_LOCPAD", "01",          Nil},;
                {"B1_PICM", 0,               Nil},;
                {"B1_IPI", 0,                Nil},;
                {"B1_CONTRAT","N",           Nil},;
                {"B1_LOCALIZ","N",           Nil};
              }

    Begin  Transaction
        MSExecAuto({|x,y|Mata010(x,y)}, aDados,3)

        If lMSErroAuto  
            Alert("Erros durante a operação!")
            MostraErro()

            DisarmTransection()
        Else
            MsgInfo("Operação finalizada!", "Aviso")
        EndIf
        End Transaction

        RestArea(aArea)
        

Return
