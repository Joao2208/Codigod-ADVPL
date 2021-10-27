#include 'totvs.ch'
#include 'protheus.ch'
#include 'parmtype.ch'

User Function MBR00()
    Local cAlias := "Z19"
    Private cTitulo := "Cadastro produtos teste"
    Private aRotina := {}
    Private cCadastro := "Cadastro de Produtos"

    AADD(aRotina,{"Pesquisa"    ,"AxPesqui"     ,0,1})
    AADD(aRotina,{"Visualizar"  ,"AxVisual"     ,0,2})
    AADD(aRotina,{"Incluir"     ,"AxInclui"     ,0,3})
    AADD(aRotina,{"Trocar"      ,"AxAltera"     ,0,4})
    AADD(aRotina,{"Excluir"     ,"AxDeleta"     ,0,5})

    dbSelectArea(cAlias)
    dbSetOrder(1)
    MBrowse(,,,,cAlias)



Return nil


