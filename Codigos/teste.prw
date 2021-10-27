#include 'totvs.ch'
#include 'protheus.ch'
User Function TESTE()
	Local nNum1  := 0
	Local nChute := 0
	Local nTent  := 1
	Local cDif
			MsgAlert("Facil(1-100) Normal(1-500) Dificil(1-1000)")
	cDif := FWInputBox("Escolha a dificuldade [Facil/Normal/Dificil]","")

	if Upper(AllTrim(cDif)) == "FACIL"
        nNum1:=Randomize(1,100)
    endif
    if Upper(AllTrim(cDif)) == "NORMAL"
        nNum1:=Randomize(1,500)
    endif
    if Upper(AllTrim(cDif)) == "DIFICIL"
        nNum1:=Randomize(1,1000)
    endif
		while nChute != nNum1            
			nChute := Val(FWInputBox("Chute um numero",""))
			if nChute == nNum1
				MsgInfo ("Você é muito bom - <b>" + cValToChar(nChute) + "</b><br>Tentativas: " + cValToChar(nTent), "Fim de Jogo")
			elseif nChute > nNum1
				MsgAlert("Valor alto","Tente Novamente")
				nTent += 1
			else
				MsgAlert("Valor baixo","Tente novamente")
				nTent += 1
			endif
		end
Return
	
