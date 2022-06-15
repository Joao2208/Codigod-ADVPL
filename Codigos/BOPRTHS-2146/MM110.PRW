#include "protheus.ch"
#include "topconn.ch"
#include "rptdef.ch"

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa  ³          ³ Autor ³ Mauricio Micheli      ³ Data ³ 25/08/16 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Pedido de Compras e Autorizacao de Entrega                 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³                                                            ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/

User Function MM110(cNumPed)
local cEmit := 'X'
Local nTxMoeda 	:= 0
local nBegin
Private cFiltro    := ""
private cPath 			:= "\SYSTEM\FTPMM\"
private cFileName  := 'PC'+AllTrim(cNumPed)+'.pdf'
private oPrn       := FWMSPrinter():New(cFileName, IMP_PDF, .T., cPath, .T., .T., , , .T., .T., .F.,.F., 1)

cNumPed := PadR(cNumPed, TamSX3("C7_NUM")[1])

if !ExistDir(cPath)
	MakeDir(cPath)
endif

if File(cPath + cFileName)
	FErase(cPath + cFileName)
endif

oPrn:cPathPDF := cPath

nLin       		:= 2401                                                                                                                   
nPagina    		:= 1
cDescPro   		:= ""
aProdZC7   		:= {}
cItemNeg   		:= "" 

oFont1 := TFont():New("Arial",09,08,,.F.,,,,,.F.)
oFont2 := TFont():New("Arial",09,10,,.F.,,,,,.F.)

oPrn:SetPortrait()
oPrn:SetPaperSize(9)='A4'

dbSelectArea("ZC7") 
Do While !ZC7->(Eof())
	RecLock("ZC7")
    DbDelete()
    MsUnlock() 
   	DbSkip()
Enddo 

//Gerar Tabela de Historico de Agrupamento
U_ACOM002(cNumPed)
MaFisEnd()
//StaticCall(MATR110, R110FIniPC, cNumPed, , , cFiltro)
R110FIniPC(cNumPed, , , cFiltro)

cAls1 := GetNextAlias()

BeginSql Alias cAls1
%NoParser%

SELECT SC7.C7_PRODUTO, SC7.C7_NUM, SC7.C7_FORNECE, SC7.C7_LOJA, SC7.C7_TXMOEDA, SC7.C7_UM,
       SC7.C7_PRECO, SC7.C7_MOEDA, SC7.C7_DATPRF, SC7.C7_IPI, SC7.C7_NUMSC, SC7.C7_MMNUMPV,
       SC7.C7_UM, SC7.C7_QUANT, SC7.C7_TOTAL, SC7.C7_APROV, SC7.C7_CONAPRO, SC7.C7_TIPO,
       SC7.C7_DESC1, SC7.C7_DESC2, SC7.C7_DESC3, SC7.C7_COND, SC7.C7_EMISSAO, SC7.C7_REAJUST,
       SC7.C7_OBS, SC7.C7_QTSEGUM, SC7.C7_ITEM, RTRIM(SA5.A5_CODPRF) A5_CODPRF
  FROM %Table:SC7% SC7
  LEFT JOIN %Table:SA5% SA5 (NOLOCK) ON SA5.A5_FILIAL = %xFilial:SA5%
                                    AND SA5.A5_FORNECE = SC7.C7_FORNECE
                                    AND SA5.A5_LOJA = SC7.C7_LOJA
                                    AND SA5.A5_PRODUTO = SC7.C7_PRODUTO
                                    AND SA5.D_E_L_E_T_ != '*'
                                    AND SA5.R_E_C_N_O_ =
                                (SELECT TOP 1 SA5B.R_E_C_N_O_
                                   FROM %Table:SA5% SA5B (NOLOCK)
                                  WHERE SA5B.A5_FILIAL = SA5.A5_FILIAL
                                    AND SA5B.A5_FORNECE = SA5.A5_FORNECE
                                    AND SA5B.A5_LOJA = SA5.A5_LOJA
                                    AND SA5B.A5_PRODUTO = SA5.A5_PRODUTO
                                    AND SA5B.D_E_L_E_T_ != '*'
                                    AND LEFT(SA5B.A5_MMVIGEN, 8) <= C7_EMISSAO
                                  ORDER BY SA5B.A5_MMVIGEN DESC, SA5B.R_E_C_N_O_ DESC)
WHERE SC7.C7_FILIAL = %xFilial:SC7%
AND SC7.C7_NUM = %Exp:cNumPed%
AND SC7.D_E_L_E_T_ != '*'

EndSql


/*
cQuery:="SELECT "
cQuery+="		SC7.C7_PRODUTO, SC7.C7_NUM, SC7.C7_FORNECE, SC7.C7_LOJA, SC7.C7_TXMOEDA, SC7.C7_UM, "
cQuery+=" 		SC7.C7_PRECO, SC7.C7_MOEDA, SC7.C7_DATPRF, SC7.C7_IPI, SC7.C7_NUMSC, SC7.C7_MMNUMPV, "
cQuery+=" 		SC7.C7_UM, SC7.C7_QUANT, SC7.C7_TOTAL, SC7.C7_APROV, SC7.C7_CONAPRO, SC7.C7_TIPO, SC7.C7_DESC1, "
cQuery+="		SC7.C7_DESC2, SC7.C7_DESC3, SC7.C7_COND, SC7.C7_EMISSAO, SC7.C7_REAJUST, SC7.C7_OBS, SC7.C7_QTSEGUM, SC7.C7_ITEM "
cQuery+="FROM "+RetSqlName("SC7")+ " SC7 "
cQuery+="WHERE SC7.C7_NUM = '"+cNumPed+"' AND "
cQuery+="SC7.C7_FILIAL = '"+xFilial("SC7")+"' AND "
cQuery+="SC7.D_E_L_E_T_ = ' ' "
TCQuery cQuery new alias &cAls1
*/

if !(cAls1)->(eof())	
	While !(cAls1)->(Eof())
	
		If ASCAN(aProdZC7, (cAls1)->C7_PRODUTO) > 0
			(cAls1)->(DbSkip())
			Loop 	
		EndIf	
				
		If nLin > 2400
			nLin := InitCabec(cNumPed)
			nPagina += 1
		EndIf
		
		//MaFisEnd()
		//StaticCall(MATR110, R110FIniPC, cNumPed, , , cFiltro)
	
		SB1->(dbSetOrder(1))
		SB1->(dbSeek( xFilial("SB1") + (cAls1)->C7_PRODUTO ))
		
		cDescPro := Alltrim(UPPER(SB1->B1_MMDESC))
		
		If SB1->B1_AGRUPA == "1"
			DbSelectarea("ZC7")
			ZC7->(DbSetOrder(1))
			ZC7->(DbSeek(xFilial("ZC7") + (cAls1)->C7_NUM + (cAls1)->C7_PRODUTO ))			
				
			oprn:say(350+nLin,0135,(cAls1)->C7_PRODUTO,oFont1,100)	 
			
			If !Empty((cAls1)->A5_CODPRF)
				oprn:say(350+nLin,0330,(cAls1)->A5_CODPRF,oFont1,100)
			End
			/*
			SA5->(dbSetOrder(1))
			If SA5->(dbSeek(xFilial("SA5")+ (cAls1)->C7_FORNECE + (cAls1)->C7_LOJA + (cAls1)->C7_PRODUTO ))
				oprn:say(350+nLin,0330,SA5->A5_CODPRF,oFont1,100)	 
			EndIf
			*/
				
			nTxMoeda := IIF((cAls1)->C7_TXMOEDA > 0,(cAls1)->C7_TXMOEDA,Nil)
			
			oprn:say(350+nLin,0950,(cAls1)->C7_UM,oFont1,100)	 
			oprn:say(350+nLin,1050,Transform(ZC7->ZC7_QUANT,"@E 999,999,999.9999"),oFont1,100)
			oprn:say(350+nLin,1250,Transform(ZC7->ZC7_QSEGUM,"@E 99,999,999.9999"),oFont1,100)
			oprn:say(350+nLin,1400,Transform(xMoeda((cAls1)->C7_PRECO,(cAls1)->C7_MOEDA,1,(cAls1)->C7_DATPRF,MsDecimais((cAls1)->C7_MOEDA),nTxMoeda),"@E 99,999,999,999.9999"),oFont1,100)		
			oprn:say(350+nLin,1700,Transform((cAls1)->C7_IPI,"@E 99.99"),oFont1,100)			
			oprn:say(350+nLin,1830,Transform(xMoeda(ZC7->ZC7_TOTAL,(cAls1)->C7_MOEDA,1,(cAls1)->C7_DATPRF,,nTxMoeda),"@E 999,999,999.99"),oFont1,100)			
			oprn:say(350+nLin,2060,(cAls1)->C7_NUMSC,oFont1,100)			
				
			//cDescPro := Alltrim(UPPER(SB1->B1_MMDESC))
			nTamDesc := 24
			nLinha   := MLCount(cDescPro,nTamDesc) 
			
			For nBegin := 1 To nLinha
				oprn:say(350+nLin,0560,MemoLine(cDescPro,nTamDesc,nBegin),oFont1,100)	 	
				nLin += 45
			Next nBegin   
			
			SC5->(DbGoTop())
			If !EMPTY((cAls1)->C7_MMNUMPV)
				If SC5->(DbSeek(xFilial("SC5")+(cAls1)->C7_MMNUMPV))
					If SC5->C5_ESPECIA=="1"
						cItemNeg := "(Item negociado de maneira diferenciada)"
					EndIf
				EndIf	
			EndIf
			
			nLinha := MLCount(cItemNeg,nTamDesc) 
			
			For nBegin := 1 To nLinha
				oprn:say(380+nLin,0560,MemoLine(cItemNeg,nTamDesc,nBegin),oFont1,100)	 	
				nLin += 45
			Next nBegin   
			
			nLin := nLin + 60
			
			AADD(aProdZC7,(cAls1)->C7_PRODUTO)
		Else
			oprn:say(350+nLin,0135,(cAls1)->C7_PRODUTO,oFont1,100)	 

			If !Empty((cAls1)->A5_CODPRF)
				oprn:say(350+nLin,0330,(cAls1)->A5_CODPRF,oFont1,100)
			End
			/*
			SA5->(dbSetOrder(1))
			If SA5->(dbSeek(xFilial("SA5")+ (cAls1)->C7_FORNECE + (cAls1)->C7_LOJA + (cAls1)->C7_PRODUTO ))
				oprn:say(350+nLin,0330,SA5->A5_CODPRF,oFont1,100)	 
			EndIf
			*/
				
			nTxMoeda := IIF((cAls1)->C7_TXMOEDA > 0,(cAls1)->C7_TXMOEDA,Nil)
			
			oprn:say(350+nLin,0950,(cAls1)->C7_UM,oFont1,100)	 
			oprn:say(350+nLin,1050,Transform((cAls1)->C7_QUANT,"@E 999,999,999.9999"),oFont1,100)
			oprn:say(350+nLin,1250,Transform((cAls1)->C7_QTSEGUM,"@E 99,999,999.9999"),oFont1,100)
			oprn:say(350+nLin,1400,Transform(xMoeda((cAls1)->C7_PRECO,(cAls1)->C7_MOEDA,1,(cAls1)->C7_DATPRF,MsDecimais((cAls1)->C7_MOEDA),nTxMoeda),"@E 99,999,999,999.9999"),oFont1,100)		
			oprn:say(350+nLin,1700,Transform((cAls1)->C7_IPI,"@E 99.99"),oFont1,100)			
			oprn:say(350+nLin,1830,Transform(xMoeda((cAls1)->C7_TOTAL,(cAls1)->C7_MOEDA,1,(cAls1)->C7_DATPRF,,nTxMoeda),"@E 999,999,999.99"),oFont1,100)			
			oprn:say(350+nLin,2060,(cAls1)->C7_NUMSC,oFont1,100)			
				
			//cDescPro := Alltrim(UPPER(SB1->B1_MMDESC))
			nTamDesc := 24
			nLinha   := MLCount(cDescPro,nTamDesc) 
			
			For nBegin := 1 To nLinha
				oprn:say(350+nLin,0560,MemoLine(cDescPro,nTamDesc,nBegin),oFont1,100)	 	
				nLin += 45
			Next nBegin   
	
			SC5->(DbGoTop())
			If !EMPTY((cAls1)->C7_MMNUMPV)
				If SC5->(DbSeek(xFilial("SC5")+(cAls1)->C7_MMNUMPV))
					If SC5->C5_ESPECIA=="1"
						cItemNeg := "(Item negociado de maneira diferenciada)"
					EndIf
				EndIf	
			EndIf
			
			nLinha := MLCount(cItemNeg,nTamDesc) 
			
			For nBegin := 1 To nLinha
				oprn:say(380+nLin,0560,MemoLine(cItemNeg,nTamDesc,nBegin),oFont1,100)	 	
				nLin += 45
			Next nBegin   
			
			nLin := nLin + 60
		EndIf
	
		(cAls1)->(dbSkip())                    
			
	EndDo                      		
	
	InitRodape(nLin, cNumPed)
		
	oPrn:Print()

	if File(cPath+cFileName)
		//Valida de pedido já foi enviado pela fila
   	    dbSelectarea("Z3B")
        Z3B->(DbSetOrder(1))
        If Z3B->(DbSeek(SC7->C7_FILIAL + AllTrim(cNumPed)))
        	If Z3B->Z3B_ENVIAD = 'S'
		        dbSelectarea("SC7")
		        SC7->(DbSetOrder(1))
		        if SC7->(DbSeek(xFilial("SC7")+AllTrim(cNumPed)))
		            
		            if ! U_fIntegra( SC7->C7_NUM, 'PURCHASE_ORDER_VIEWED_PROTHEUS')
		                cEmit := 'X'
		            else
		                cEmit := 'S'
		            endif
					
			        //Atualiza fila de envio de OC´s
			        RecLock('Z3B',.F.)
			        Z3B->Z3B_ENVIAD	:= cEmit
			        Z3B->(MsUnlock())
		
					while SC7->C7_FILIAL == xFilial("SC7") .and. AllTrim(SC7->C7_NUM) == AllTrim(cNumPed)            
		                RecLock("SC7",.F.)
		                SC7->C7_EMITIDO := cEmit
		                MsUnLock()
		                SC7->(dbSkip())
		            enddo
				endif
			EndIf
		EndIf
	endif

	FErase(cPath + StrTran(cFileName, '.pdf', '.rel'))
else
	U_fConOut("MM110", "Pedido " + cNumPed + " nao existe.")	
endif

(cAls1)->(dbCloseArea())
Return

//±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
Static Function InitCabec(cNumPed)

nLinCabec := 80

oPrn:StartPage()

oPrn:Box(nLinCabec,0073,313,1026) 
oPrn:Box(nLinCabec,1026,313,2218) 

oprn:say(50+nLinCabec,0100,"Empresa: " + SM0->M0_NOMECOM,oFont2,100)
oprn:say(80+nLinCabec,0100,"Endereço: " + SM0->M0_ENDENT,oFont2,100) 
oprn:say(110+nLinCabec,0100,"CEP: " + Trans(SM0->M0_CEPENT,PesqPict("SA2","A2_CEP")) + "  Cidade: " + RTRIM(SM0->M0_CIDENT) + "  UF: " + SM0->M0_ESTENT,oFont2,100) 
oprn:say(140+nLinCabec,0100,"TEL: " + SM0->M0_TEL + "    FAX: " + SM0->M0_FAX,oFont2,100) 
oprn:say(170+nLinCabec,0100,"CNPJ/CPF: " + Transform(SM0->M0_CGC,PesqPict("SA2","A2_CGC")) + "    IE: " + InscrEst(),oFont2,100)

oprn:say(20+nLinCabec,1050,"P E D I D O  D E  C O M P R A S - REAL" + "                                       " + cNumPed + " /" + Ltrim(Str(nPagina,2)),oFont2,100)
oprn:say(50+nLinCabec,1855,"1a.Emissão  1a.VIA",oFont2,100)

SA2->(dbSetOrder(1))
SA2->(dbSeek(xFilial("SA2") + Posicione("SC7",1,xFilial("SC7")+cNumPed,"C7_FORNECE") + Posicione("SC7",1,xFilial("SC7")+cNumPed,"C7_LOJA")))

oprn:say(80+nLinCabec,01050,"Razão Social: " + SUBSTR(SA2->A2_NOME,1,35) + " - " + "Código: " + SA2->A2_COD + " " + "Loja: " + SA2->A2_LOJA,oFont2,100)
oprn:say(110+nLinCabec,01050,"Endereço: " + SUBSTR(SA2->A2_END,1,30) + " Bairro: " + SUBSTR(SA2->A2_BAIRRO,1,15),oFont2,100)
oprn:say(140+nLinCabec,01050,"Município: " + SA2->A2_MUN + " Estado: " + SA2->A2_EST,oFont2,100)
oprn:say(170+nLinCabec,01050,"CEP: " + SA2->A2_CEP + " CNPJ/CPF: " + Transform(SA2->A2_CGC,PesqPict("SA2","A2_CGC")),oFont2,100)
oprn:say(200+nLinCabec,01050,"FONE: " + "("+Substr(SA2->A2_DDD,1,3)+") "+Substr(SA2->A2_TEL,1,15) + "FAX: "+"("+Substr(SA2->A2_DDD,1,3)+") "+Substr(SA2->A2_FAX,1,15) + "          Ins. Estad.: " + SA2->A2_INSCR,oFont2,100)

oPrn:Box(250+nLinCabec,0073,2950,2218) 

oprn:say(260+nLinCabec,0130,"Produto            Cód.Prod.For.                 Descrição                     Unidade     Quantidade    Qt. Seg. Um.   Valor Unitário     Aliq. IPI     Valor Total    Número da SC",oFont2,100)
oprn:say(290+nLinCabec,0073,"____________________________________________________________________________________________________________________________________",oFont2,100)

Return(nLinCabec)
                           
//±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
Static Function InitRodape(nLinRodape, cNumPed)

local nRecNoSC5	:= 0
local nRecNoSA1	:= 0
local lIsVaO		:= .f.
local nx := 0
Local nTotIpi	 := 0
Local nTotIcms	 := 0
Local nTotDesp	 := 0
Local nTotFrete	 := 0
Local nTotalNF	 := 0
Local nTotSeguro := 0
Local nTxMoeda   := 0
Local nTotal     := 0
Local nTotMerc   := 0
Local nLinObs    := 0
Local cVar       := ""
Local lNewAlc	 := .F.
Local lLiber     := .F.
Private cObs01   := ""
Private cObs02   := ""
Private cObs03   := ""
Private cObs04   := ""
Private cObs05   := ""
Private cObs06   := ""
Private cObs07   := ""
Private cObs08   := ""
Private cObs09   := ""
Private cObs10   := ""
Private cObs11   := ""
Private cObs12   := ""
Private cObs13   := ""
Private cObs14   := ""
Private cObs15   := ""
Private cObs16   := ""
aProd2ZC7        := {}
Datprf           := dDataBase   
C7Aprov          := ""
C7Conapro        := ""
C7Tipo           := ""

If nLinRodape > 1150
	oPrn:StartPage()
	oPrn:Box(80,0073,2950,2218) 
	nLinRodape := 130	
Else
	nLinRodape := 1610
	oprn:say(1560,0073,"____________________________________________________________________________________________________________________________________",oFont2,100)
EndIf

cAls2 := GetNextAlias()

cQuery:="SELECT  "
cQuery+="		SC5.R_E_C_N_O_ C5RECNO, SA1.R_E_C_N_O_ A1RECNO, A2_MMVAO, SA2.R_E_C_N_O_ A2RECNO, "
cQuery+=" 		SC7.C7_PRODUTO, SC7.C7_NUM, SC7.C7_FORNECE, SC7.C7_LOJA, SC7.C7_TXMOEDA, SC7.C7_UM, SC7.C7_PRECO, SC7.C7_MOEDA, SC7.C7_DATPRF, SC7.C7_IPI, "
cQuery+="		SC7.C7_NUMSC, SC7.C7_MMNUMPV, SC7.C7_UM, SC7.C7_QUANT, SC7.C7_TOTAL, SC7.C7_APROV, SC7.C7_CONAPRO, SC7.C7_TIPO, SC7.C7_DESC1, SC7.C7_DESC2, "
cQuery+="		SC7.C7_DESC3, SC7.C7_COND, SC7.C7_EMISSAO, SC7.C7_REAJUST, SC7.C7_OBS "
cQuery+="FROM "+RetSqlName("SC7")+ " SC7 "
cQuery+=" INNER JOIN "+RetSqlName("SA2")+ " SA2 ON A2_FILIAL = '"+xFilial("SA2")+"' AND A2_COD = C7_FORNECE AND A2_LOJA = C7_LOJA AND SA2.D_E_L_E_T_ = '' "
cQuery+=" LEFT JOIN "+RetSqlName("SC6")+ " SC6 ON C6_FILIAL = '"+xFilial("SC6")+"' AND C6_NUM = C7_MMITV AND C7_MMITPV = C6_ITEM AND SC6.D_E_L_E_T_ = '' "
cQuery+=" LEFT JOIN "+RetSqlName("SC5")+ " SC5 ON C5_FILIAL = C6_FILIAL AND C5_NUM = C6_NUM AND SC5.D_E_L_E_T_ = '' "
cQuery+=" LEFT JOIN "+RetSqlName("SA1")+ " SA1 ON A1_FILIAL = '"+xFilial("SA1")+"' AND A1_COD = C5_CLIENTE AND A1_LOJA = C5_LOJACLI AND SA1.D_E_L_E_T_ = '' "
cQuery+="WHERE SC7.C7_NUM = '"+cNumPed+"' AND "
cQuery+="SC7.C7_FILIAL = '"+xFilial("SC7")+"' AND "
cQuery+="SC7.D_E_L_E_T_ = ' ' "
TCQuery cQuery new alias &cAls2

nTxMoeda  := IIF((cAls2)->C7_TXMOEDA > 0,(cAls2)->C7_TXMOEDA,Nil)
Datprf    := DTOC(STOD((cAls2)->C7_DATPRF))
C7Aprov   := (cAls2)->C7_APROV
C7Conapro := (cAls2)->C7_CONAPRO
C7Tipo    := (cAls2)->C7_TIPO

oprn:say(nLinRodape,0100,"D E S C O N T O S -->" + " " + TransForm((cAls2)->C7_DESC1,"999.99" ) + " %    " + TransForm((cAls2)->C7_DESC2,"999.99" ) + " %    " + 	TransForm((cAls2)->C7_DESC3,"999.99" ) + " %    " + TransForm(xMoeda(0,1,1,Datprf,MsDecimais(1),nTxMoeda) , PesqPict("SC7","C7_VLDESC",14, 1) ),oFont2,100)

oprn:say(30+nLinRodape,0073,"____________________________________________________________________________________________________________________________________",oFont2,100)

SA2->(dbSetOrder(1))
//SA2->(dbSeek(xFilial("SA2") + Posicione("SC7",1,xFilial("SC7")+cNumPed,"C7_FORNECE") + Posicione("SC7",1,xFilial("SC7")+cNumPed,"C7_LOJA")))
SA2->(dbGoTo((cAls2)->A2RECNO))

nRecNoSC5	:= (cAls2)->C5RECNO
nRecNoSA1	:= (cAls2)->A1RECNO
lIsVaO			:= (cAls2)->A2_MMVAO == 'S'
	
If AllTrim(SA2->A2_MMENTRE) $ "R/V"
	if Empty(Alltrim(SA2->A2_ENDDRSH))
		cLocalEnt := "Retirar no Local"
	else
		cLocalEnt := Alltrim(SA2->A2_ENDDRSH)+" - "+Alltrim(SA2->A2_CIDADDS)+" - "+ALLTRIM(SA2->A2_UFDS)+" - "+"CEP :"+" "+Trans(SA2->A2_CEPDS,PesqPict("SA2","A2_CEPDS"))
	endif   			
Elseif AllTrim(SA2->A2_MMENTRE) == "E"  
	cLocalEnt := "Rua Salgado Filho, 915" +" - "+"Pinhais"+" - "+"PR"+" - "+"CEP :"+" "+Trans("83330110",PesqPict("SA2","A2_CEP"))
Else
	cLocalEnt := Rtrim(SM0->M0_ENDENT)+" - "+Rtrim(SM0->M0_CIDENT)+" - "+SM0->M0_ESTENT+" - "+"CEP :"+" "+Trans(Alltrim(SM0->M0_CEPENT),PesqPict("SA2","A2_CEP"))
Endif

oprn:say(nLinRodape+080,0100,"Local de Entrega  : " + cLocalEnt, oFont2, 100)		
oprn:say(nLinRodape+120,0100,"Local de Cobrança : " + Rtrim(SM0->M0_ENDCOB)+" - "+Rtrim(SM0->M0_CIDCOB)+" - "+SM0->M0_ESTCOB+" - "+"CEP :"+" "+Trans(Alltrim(SM0->M0_CEPCOB),PesqPict("SA2","A2_CEP")),oFont2,100)
                      
oprn:say(150+nLinRodape,0073,"____________________________________________________________________________________________________________________________________",oFont2,100)

SE4->(dbSetOrder(1))
SE4->(dbSeek(xFilial("SE4")+(cAls2)->C7_COND))
		
oprn:say(nLinRodape+200,0100,"Condição de Pagto "+SubStr(SE4->E4_COND,1,40),oFont2,100)
oprn:say(nLinRodape+240,0100,SubStr(SE4->E4_DESCRI,1,34),oFont2,100)
oprn:say(nLinRodape+200,01050,"Data de Emissão",oFont2,100)
oprn:say(nLinRodape+240,01050,DTOC(STOD((cAls2)->C7_EMISSAO)),oFont2,100)

oprn:say(270+nLinRodape,0073,"____________________________________________________________________________________________________________________________________",oFont2,100)
	                                                                    
SM4->(dbSetOrder(1))
If SM4->(dbSeek(xFilial("SM4")+(cAls2)->C7_REAJUST))
	oprn:say(nLinRodape+340,0100,"Reajuste:" + " " + (cAls2)->C7_REAJUST + " " + SM4->M4_DESCR ,oFont2,100)
EndIf			
	
SB1->(dbSetOrder(1))
SB1->(dbSeek( xFilial("SB1") + (cAls2)->C7_PRODUTO ))
								
If SB1->B1_AGRUPA == "1"
	DbSelectarea("ZC7")
	ZC7->(DbSetOrder(1))
	ZC7->(DbSeek(xFilial("ZC7") + (cAls2)->C7_NUM ))			
		
	While !ZC7->(Eof()) .AND. cNumPed == ZC7->ZC7_NUMPC
		nTotal := nTotal + ZC7->ZC7_TOTAL
		ZC7->(dbSkip())
	Enddo 
    
    While !(cAls2)->(Eof()) .AND. cNumPed == (cAls2)->C7_NUM
		If ASCAN(aProd2ZC7, (cAls2)->C7_PRODUTO) > 0
			(cAls2)->(DbSkip())
			Loop 	
		EndIf	
	
		If !Empty((cAls2)->C7_OBS) .And. nLinObs < 17
			nLinObs++
			cVar:="cObs"+StrZero(nLinObs,2)
			Eval(MemVarBlock(cVar),(cAls2)->C7_OBS)
		Endif

		If Empty(cObs02)
			If Len(cObs01) > 80
				cObs := cObs01
				cObs01 := Substr(cObs,1,80)
				For nX := 2 To 16
					cVar  := "cObs"+StrZero(nX,2)
					&cVar := Substr(cObs,(80*(nX-1))+1,80)
				Next nX
			EndIf
		Else
			cObs01:= Substr(cObs01,1,IIf(Len(cObs01)<80,Len(cObs01),80))
			cObs02:= Substr(cObs02,1,IIf(Len(cObs02)<80,Len(cObs01),80))
			cObs03:= Substr(cObs03,1,IIf(Len(cObs03)<80,Len(cObs01),80))
			cObs04:= Substr(cObs04,1,IIf(Len(cObs04)<80,Len(cObs01),80))
			cObs05:= Substr(cObs05,1,IIf(Len(cObs05)<80,Len(cObs01),80))
			cObs06:= Substr(cObs06,1,IIf(Len(cObs06)<80,Len(cObs01),80))
			cObs07:= Substr(cObs07,1,IIf(Len(cObs07)<80,Len(cObs01),80))
			cObs08:= Substr(cObs08,1,IIf(Len(cObs08)<80,Len(cObs01),80))
			cObs09:= Substr(cObs09,1,IIf(Len(cObs09)<80,Len(cObs01),80))
			cObs10:= Substr(cObs10,1,IIf(Len(cObs10)<80,Len(cObs01),80))
			cObs11:= Substr(cObs11,1,IIf(Len(cObs11)<80,Len(cObs01),80))
			cObs12:= Substr(cObs12,1,IIf(Len(cObs12)<80,Len(cObs01),80))
			cObs13:= Substr(cObs13,1,IIf(Len(cObs13)<80,Len(cObs01),80))
			cObs14:= Substr(cObs14,1,IIf(Len(cObs14)<80,Len(cObs01),80))
			cObs15:= Substr(cObs15,1,IIf(Len(cObs15)<80,Len(cObs01),80))
			cObs16:= Substr(cObs16,1,IIf(Len(cObs16)<80,Len(cObs01),80))
		EndIf
		
		AADD(aProd2ZC7,(cAls2)->C7_PRODUTO)
		
		(cAls2)->(dbSkip())
	Enddo 
			
	oprn:say(nLinRodape+400,0100,"Observações",oFont2,100)
	oprn:say(nLinRodape+440,0100,cObs01,oFont2,100)
	oprn:say(nLinRodape+480,0100,cObs02,oFont2,100)
	oprn:say(nLinRodape+520,0100,cObs03,oFont2,100)
	oprn:say(nLinRodape+560,0100,cObs04,oFont2,100)
	oprn:say(nLinRodape+600,0100,cObs05,oFont2,100)
	oprn:say(nLinRodape+640,0100,cObs06,oFont2,100)
	oprn:say(nLinRodape+680,0100,cObs07,oFont2,100)
	oprn:say(nLinRodape+720,0100,cObs08,oFont2,100)
	oprn:say(nLinRodape+760,0100,cObs09,oFont2,100)
	oprn:say(nLinRodape+800,0100,cObs10,oFont2,100)
	oprn:say(nLinRodape+840,0100,cObs11,oFont2,100)
	oprn:say(nLinRodape+880,0100,cObs12,oFont2,100)
	oprn:say(nLinRodape+920,0100,cObs13,oFont2,100)
	oprn:say(nLinRodape+960,0100,cObs14,oFont2,100)
	oprn:say(nLinRodape+1000,0100,cObs15,oFont2,100)
	oprn:say(nLinRodape+1040,0100,cObs16,oFont2,100)
	
	oprn:say(1070+nLinRodape,0073,"____________________________________________________________________________________________________________________________________",oFont2,100)
		
	nTotMerc   := MaFisRet(,"NF_TOTAL")
	nTotIpi	   := MaFisRet(,'NF_VALIPI')
	nTotIcms   := MaFisRet(,'NF_VALICM')
	nTotDesp   := MaFisRet(,'NF_DESPESA')
	nTotFrete  := MaFisRet(,'NF_FRETE')
	nTotSeguro := MaFisRet(,'NF_SEGURO')
	nTotalNF   := MaFisRet(,'NF_TOTAL')
		
	oprn:say(nLinRodape+200,01650,"Total das Mercadorias: " + Transform(xMoeda(nTotal,1,1,Datprf,MsDecimais(1),nTxMoeda) , tm(nTotal,14,MsDecimais(1)) ),oFont2,100)  
	oprn:say(nLinRodape+240,01650,"Total com Impostos:     " + Transform(xMoeda(nTotMerc,1,1,Datprf,MsDecimais(1),nTxMoeda) , tm(nTotMerc,14,MsDecimais(1)) ),oFont2,100)
	oprn:say(nLinRodape+400,01250,"IPI:       " + Transform(xMoeda(nTotIPI ,1,1,Datprf,MsDecimais(1),nTxMoeda) , tm(nTotIpi ,14,MsDecimais(1))),oFont2,100)
	oprn:say(nLinRodape+400,01650,"ICMS:       " + Transform(xMoeda(nTotIcms,1,1,Datprf,MsDecimais(1),nTxMoeda) , tm(nTotIcms,14,MsDecimais(1))),oFont2,100)
	oprn:say(nLinRodape+440,01250,"Frete:    " + Transform(xMoeda(nTotFrete,1,1,Datprf,MsDecimais(1),nTxMoeda) , tm(nTotFrete,14,MsDecimais(1))),oFont2,100)
	oprn:say(nLinRodape+440,01650,"Despesas: " + Transform(xMoeda(nTotDesp ,1,1,Datprf,MsDecimais(1),nTxMoeda) , tm(nTotDesp ,14,MsDecimais(1))),oFont2,100)
	oprn:say(nLinRodape+480,01650,"Seguro:      " + Transform(xMoeda(nTotSeguro,1,1,Datprf,MsDecimais(1),nTxMoeda) , tm(nTotSeguro,14,MsDecimais(1))),oFont2,100)
		
	If !Empty(C7Aprov)
		lNewAlc := .T.
	EndIf
	
	If C7Conapro != "B"
		lLiber := .T.
	EndIf
		
	If !lNewAlc
		oprn:say(nLinRodape+560,01650,"Total Geral :" + Transform(xMoeda(nTotalNF,1,1,Datprf,MsDecimais(1),nTxMoeda) , tm(nTotalNF,14,MsDecimais(1))),oFont2,100) 
		If SA2->A2_COD=="000363" .OR. SA2->A2_MMTZZ9='S'
			dbSelectArea("SA4")
   			dbSetOrder(1)
   			If dbSeek( xFilial("SA4")+SC7->C7_MMTRANS ) 
   				oprn:say(nLinRodape+800 ,01250,"Coletado Por:",oFont2,100)  
   				oprn:say(nLinRodape+840 ,01250,Alltrim(SA4->A4_NOME),oFont2,100)
   				oprn:say(nLinRodape+880 ,01250,Alltrim(SA4->A4_END)+"-"+Alltrim(SA4->A4_MUN)+"-"+Alltrim(SA4->A4_EST),oFont2,100)
   				oprn:say(nLinRodape+920 ,01250,"BAIRRO:"+Alltrim(SA4->A4_BAIRRO)+" CEP:"+Alltrim(SA4->A4_CEP),oFont2,100)
   				oprn:say(nLinRodape+960 ,01250,"Fone:"+Alltrim(SA4->A4_DDD)+"-"+Alltrim(SA4->A4_TEL)+" Celular:"+Alltrim(SA4->A4_CDDD)+"-"+Alltrim(SA4->A4_CTEL)+" Contato:"+Alltrim(SA4->A4_PESSOA),oFont2,100)
   				oprn:say(nLinRodape+1000,01250,"CNPJ:"+Alltrim(SA4->A4_CGC)+" Ins.Est:"+Alltrim(SA4->A4_INSEST),oFont2,100)
   			EndIf                   
   		EndIf
	Else
		If lLiber
			oprn:say(nLinRodape+560,01650,"Total Geral :" + Transform(xMoeda(nTotalNF,1,1,Datprf,MsDecimais(1),nTxMoeda) , tm(nTotalNF,14,MsDecimais(1))),oFont2,100)
		Else
			oprn:say(nLinRodape+560,01650,"Total Geral :" + If((C7Tipo == 1 .OR. C7Tipo == 3),"     P E D I D O   B L O Q U E A D O ","AUTORIZACAO DE ENTREGA BLOQUEADA   "),oFont2,100)
		EndIf
	EndIf
	
	If C7Tipo == 1 .OR. C7Tipo == 3
		oprn:say(nLinRodape+1130,0100,"NOTA: Só aceitaremos a mercadoria se na sua Nota Fiscal constar o número do nosso Pedido de Compras.",oFont2,100)
	Else
		oprn:say(nLinRodape+1130,0100,"NOTA: Só aceitaremos a mercadoria se na sua Nota Fiscal constar o número da Autorizacao de Entrega.",oFont2,100)
	EndIf
Else
	While !(cAls2)->(Eof())
		nTotal := nTotal + (cAls2)->C7_TOTAL
		(cAls2)->(dbSkip())
	Enddo
	
	While !(cAls2)->(Eof()) .AND. cNumPed == (cAls2)->C7_NUM
		If ASCAN(aProd2ZC7, (cAls2)->C7_PRODUTO) > 0
			(cAls2)->(DbSkip())
			Loop 	
		EndIf	
	
		If !Empty((cAls2)->C7_OBS) .And. nLinObs < 17
			nLinObs++
			cVar:="cObs"+StrZero(nLinObs,2)
			Eval(MemVarBlock(cVar),(cAls2)->C7_OBS)
		Endif

		If Empty(cObs02)
			If Len(cObs01) > 80
				cObs := cObs01
				cObs01 := Substr(cObs,1,80)
				For nX := 2 To 16
					cVar  := "cObs"+StrZero(nX,2)
					&cVar := Substr(cObs,(80*(nX-1))+1,80)
				Next nX
			EndIf
		Else
			cObs01:= Substr(cObs01,1,IIf(Len(cObs01)<80,Len(cObs01),80))
			cObs02:= Substr(cObs02,1,IIf(Len(cObs02)<80,Len(cObs01),80))
			cObs03:= Substr(cObs03,1,IIf(Len(cObs03)<80,Len(cObs01),80))
			cObs04:= Substr(cObs04,1,IIf(Len(cObs04)<80,Len(cObs01),80))
			cObs05:= Substr(cObs05,1,IIf(Len(cObs05)<80,Len(cObs01),80))
			cObs06:= Substr(cObs06,1,IIf(Len(cObs06)<80,Len(cObs01),80))
			cObs07:= Substr(cObs07,1,IIf(Len(cObs07)<80,Len(cObs01),80))
			cObs08:= Substr(cObs08,1,IIf(Len(cObs08)<80,Len(cObs01),80))
			cObs09:= Substr(cObs09,1,IIf(Len(cObs09)<80,Len(cObs01),80))
			cObs10:= Substr(cObs10,1,IIf(Len(cObs10)<80,Len(cObs01),80))
			cObs11:= Substr(cObs11,1,IIf(Len(cObs11)<80,Len(cObs01),80))
			cObs12:= Substr(cObs12,1,IIf(Len(cObs12)<80,Len(cObs01),80))
			cObs13:= Substr(cObs13,1,IIf(Len(cObs13)<80,Len(cObs01),80))
			cObs14:= Substr(cObs14,1,IIf(Len(cObs14)<80,Len(cObs01),80))
			cObs15:= Substr(cObs15,1,IIf(Len(cObs15)<80,Len(cObs01),80))
			cObs16:= Substr(cObs16,1,IIf(Len(cObs16)<80,Len(cObs01),80))
		EndIf
		
		AADD(aProd2ZC7,(cAls2)->C7_PRODUTO)
		
		(cAls2)->(dbSkip())
	Enddo 
			
	oprn:say(nLinRodape+400,0100,"Observações",oFont2,100)
	oprn:say(nLinRodape+440,0100,cObs01,oFont2,100)
	oprn:say(nLinRodape+480,0100,cObs02,oFont2,100)
	oprn:say(nLinRodape+520,0100,cObs03,oFont2,100)
	oprn:say(nLinRodape+560,0100,cObs04,oFont2,100)
	oprn:say(nLinRodape+600,0100,cObs05,oFont2,100)
	oprn:say(nLinRodape+640,0100,cObs06,oFont2,100)
	oprn:say(nLinRodape+680,0100,cObs07,oFont2,100)
	oprn:say(nLinRodape+720,0100,cObs08,oFont2,100)
	oprn:say(nLinRodape+760,0100,cObs09,oFont2,100)
	oprn:say(nLinRodape+800,0100,cObs10,oFont2,100)
	oprn:say(nLinRodape+840,0100,cObs11,oFont2,100)
	oprn:say(nLinRodape+880,0100,cObs12,oFont2,100)
	oprn:say(nLinRodape+920,0100,cObs13,oFont2,100)
	oprn:say(nLinRodape+960,0100,cObs14,oFont2,100)
	oprn:say(nLinRodape+1000,0100,cObs15,oFont2,100)
	oprn:say(nLinRodape+1040,0100,cObs16,oFont2,100)
	
	oprn:say(1070+nLinRodape,0073,"____________________________________________________________________________________________________________________________________",oFont2,100)
		
	nTotMerc   := MaFisRet(,"NF_TOTAL")
	nTotIpi	   := MaFisRet(,'NF_VALIPI')
	nTotIcms   := MaFisRet(,'NF_VALICM')
	nTotDesp   := MaFisRet(,'NF_DESPESA')
	nTotFrete  := MaFisRet(,'NF_FRETE')
	nTotSeguro := MaFisRet(,'NF_SEGURO')
	nTotalNF   := MaFisRet(,'NF_TOTAL')
		
	oprn:say(nLinRodape+200,01650,"Total das Mercadorias: " + Transform(xMoeda(nTotal,1,1,Datprf,MsDecimais(1),nTxMoeda) , tm(nTotal,14,MsDecimais(1)) ),oFont2,100)  
	oprn:say(nLinRodape+240,01650,"Total com Impostos:     " + Transform(xMoeda(nTotMerc,1,1,Datprf,MsDecimais(1),nTxMoeda) , tm(nTotMerc,14,MsDecimais(1)) ),oFont2,100)
	oprn:say(nLinRodape+400,01250,"IPI:       " + Transform(xMoeda(nTotIPI ,1,1,Datprf,MsDecimais(1),nTxMoeda) , tm(nTotIpi ,14,MsDecimais(1))),oFont2,100)
	oprn:say(nLinRodape+400,01650,"ICMS:       " + Transform(xMoeda(nTotIcms,1,1,Datprf,MsDecimais(1),nTxMoeda) , tm(nTotIcms,14,MsDecimais(1))),oFont2,100)
	oprn:say(nLinRodape+440,01250,"Frete:    " + Transform(xMoeda(nTotFrete,1,1,Datprf,MsDecimais(1),nTxMoeda) , tm(nTotFrete,14,MsDecimais(1))),oFont2,100)
	oprn:say(nLinRodape+440,01650,"Despesas: " + Transform(xMoeda(nTotDesp ,1,1,Datprf,MsDecimais(1),nTxMoeda) , tm(nTotDesp ,14,MsDecimais(1))),oFont2,100)
	oprn:say(nLinRodape+480,01650,"Seguro:      " + Transform(xMoeda(nTotSeguro,1,1,Datprf,MsDecimais(1),nTxMoeda) , tm(nTotSeguro,14,MsDecimais(1))),oFont2,100)
		
	If !Empty(C7Aprov)
		lNewAlc := .T.
	EndIf
	
	If C7Conapro != "B"
		lLiber := .T.
	EndIf
		
	If !lNewAlc
		oprn:say(nLinRodape+560,01650,"Total Geral :" + Transform(xMoeda(nTotalNF,1,1,Datprf,MsDecimais(1),nTxMoeda) , tm(nTotalNF,14,MsDecimais(1))),oFont2,100) 
		If SA2->A2_COD=="000363" .OR. SA2->A2_MMTZZ9=='S'
			dbSelectArea("SA4")
   			dbSetOrder(1)
   			If dbSeek( xFilial("SA4")+SC7->C7_MMTRANS ) 
   				oprn:say(nLinRodape+800 ,01250,"Coletado Por:",oFont2,100)  
   				oprn:say(nLinRodape+840 ,01250,Alltrim(SA4->A4_NOME),oFont2,100)
   				oprn:say(nLinRodape+880 ,01250,Alltrim(SA4->A4_END)+"-"+Alltrim(SA4->A4_MUN)+"-"+Alltrim(SA4->A4_EST),oFont2,100)
   				oprn:say(nLinRodape+920 ,01250,"BAIRRO:"+Alltrim(SA4->A4_BAIRRO)+" CEP:"+Alltrim(SA4->A4_CEP),oFont2,100)
   				oprn:say(nLinRodape+960 ,01250,"Fone:"+Alltrim(SA4->A4_DDD)+"-"+Alltrim(SA4->A4_TEL)+" Celular:"+Alltrim(SA4->A4_CDDD)+"-"+Alltrim(SA4->A4_CTEL)+" Contato:"+Alltrim(SA4->A4_PESSOA),oFont2,100)
   				oprn:say(nLinRodape+1000,01250,"CNPJ:"+Alltrim(SA4->A4_CGC)+" Ins.Est:"+Alltrim(SA4->A4_INSEST),oFont2,100)
   			EndIf                   
   		EndIf
	Else
		If lLiber
			oprn:say(nLinRodape+560,01650,"Total Geral :" + Transform(xMoeda(nTotalNF,1,1,Datprf,MsDecimais(1),nTxMoeda) , tm(nTotalNF,14,MsDecimais(1))),oFont2,100)
		Else
			oprn:say(nLinRodape+560,01650,"Total Geral :" + If((C7Tipo == 1 .OR. C7Tipo == 3),"     P E D I D O   B L O Q U E A D O ","AUTORIZACAO DE ENTREGA BLOQUEADA   "),oFont2,100)
		EndIf
	EndIf
	
	If C7Tipo == 1 .OR. C7Tipo == 3
		oprn:say(nLinRodape+1130,0100,"NOTA: Só aceitaremos a mercadoria se na sua Nota Fiscal constar o número do nosso Pedido de Compras.",oFont2,100)
	Else
		oprn:say(nLinRodape+1130,0100,"NOTA: Só aceitaremos a mercadoria se na sua Nota Fiscal constar o número da Autorizacao de Entrega.",oFont2,100)
	EndIf
EndIf


if lIsVaO

	SA1->(dbGoTo(nRecNoSA1))
	SC5->(dbGoTo(nRecNoSC5))
	aEndEnt := {}
	if SA1->A1_PESSOA == 'F'
		// Buscar o endereco a ser entregue (prioridade nesta ordem -> C5_CEPE, C5_CEP, A1_CEPE, A1_CEP)
		if !Empty(SC5->C5_CEPE)
			aEndEnt := {SC5->C5_NUM, SC5->C5_ENDENT, SC5->C5_BAIRROE, SC5->C5_MUNE, SC5->C5_ESTE, SC5->C5_CEPE}
		elseif !Empty(SC5->C5_CEP)
			aEndEnt := {SC5->C5_NUM, SC5->C5_ENDEN, SC5->C5_BAIRRO, SC5->C5_MUN, SC5->C5_EST, SC5->C5_CEP}
		elseif !Empty(SA1->A1_CEPE)
			aEndEnt := {SC5->C5_NUM, SA1->A1_ENDENT, SA1->A1_BAIRROE, SA1->A1_MUNE, SA1->A1_ESTE, SA1->A1_CEPE}
		else
			aEndEnt := {SC5->C5_NUM, SA1->A1_END, SA1->A1_BAIRRO, SA1->A1_MUN, SA1->A1_EST, SA1->A1_CEP}
		endif
	else
		aEndEnt := {SC5->C5_NUM, SA1->A1_END, SA1->A1_BAIRRO, SA1->A1_MUN, SA1->A1_EST, SA1->A1_CEP}
	endif
	oprn:say(nLinRodape+800,00100,"Cliente :",oFont2,100)  
	oprn:say(nLinRodape+840,00100,Alltrim(SA1->A1_NOME),oFont2,100)
	oprn:say(nLinRodape+880,00100,Alltrim(aEndEnt[2])+"-"+Alltrim(aEndEnt[4])+"-"+Alltrim(aEndEnt[5]),oFont2,100)
	oprn:say(nLinRodape+920,00100,"BAIRRO:"+Alltrim(aEndEnt[3])+" CEP:"+Alltrim(aEndEnt[6]),oFont2,100)
	oprn:say(nLinRodape+960,00100,"CPF/CNPJ:"+Alltrim(SA1->A1_CGC)+IIF(!Empty(SA1->A1_INSCR), " Ins.Est:"+Alltrim(SA1->A1_INSCR), ""),oFont2,100)
endif		
oPrn:EndPage()

(cAls2)->(dbCloseArea())

Return


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Funcao    ³R110FIniPC³ Autor ³ Edson Maricate        ³ Data ³20/05/2000³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descricao ³ Inicializa as funcoes Fiscais com o Pedido de Compras      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ R110FIniPC(ExpC1,ExpC2)                                    ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ ExpC1 := Numero do Pedido                                  ³±±
±±³          ³ ExpC2 := Item do Pedido                                    ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ MATR110,MATR120,Fluxo de Caixa                             ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function R110FIniPC(cPedido,cItem,cSequen,cFiltro)

Local aArea		:= GetArea()
Local aAreaSC7	:= SC7->(GetArea())
Local cValid	:= ""
Local nPosRef	:= 0
Local nItem		:= 0
Local cItemDe	:= IIf(cItem==Nil,'',cItem)
Local cItemAte	:= IIf(cItem==Nil,Repl('Z',Len(SC7->C7_ITEM)),cItem)
Local cRefCols	:= ''
Local nX
Local cFilSC7   := xFilial('SC7')
Static aStru	:= FWFormStruct(3,"SC7")[1]

DEFAULT cSequen	:= ""
DEFAULT cFiltro	:= ""

dbSelectArea("SC7")
dbSetOrder(1)
If dbSeek(cFilSC7+cPedido+cItemDe+Alltrim(cSequen))
	MaFisEnd()
	MaFisIni(SC7->C7_FORNECE,SC7->C7_LOJA,"F","N","R",{})
	While !Eof() .AND. SC7->C7_FILIAL+SC7->C7_NUM == cFilSC7+cPedido .AND. ;
			SC7->C7_ITEM <= cItemAte .AND. (Empty(cSequen) .OR. cSequen == SC7->C7_SEQUEN)

		// Nao processar os Impostos se o item possuir residuo eliminado  
		If &cFiltro
			SC7->(dbSkip())
			Loop
		EndIf
            
		// Inicia a Carga do item nas funcoes MATXFIS  
		nItem++
		MaFisIniLoad(nItem)

		For nX := 1 To Len(aStru)
			cValid	:= StrTran(UPPER(GetCbSource(aStru[nX][7]))," ","")
			cValid	:= StrTran(cValid,"'",'"')
			If "MAFISREF" $ cValid .And. !(aStru[nX][14]) //campos que não são virtuais
				nPosRef  := AT('MAFISREF("',cValid) + 10
				cRefCols := Substr(cValid,nPosRef,AT('","MT120",',cValid)-nPosRef )
				// Carrega os valores direto do SC7.           
				MaFisLoad(cRefCols,&("SC7->"+ aStru[nX][3]),nItem)
			EndIf
		Next nX		

		MaFisEndLoad(nItem,2)
		
		SC7->(dbSkip())
	End
EndIf

RestArea(aAreaSC7)
RestArea(aArea)

Return .T.

