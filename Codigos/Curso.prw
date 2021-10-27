#include 'totvs.ch'
#include 'protheus.ch'
User Function JG00()
	Local nNum1 := Randomize(1,100)
	Local nNum2 := Randomize(1,500)
	Local nNum3 := Randomize(1,1000)
	Local nChute := 0
	Local nTent := 1
	Local cDif
	cDif := FWInputBox("Escolha a dificuldade [Facil/Normal/Dificil]","")
	if Upper(AllTrim(cDif)) == "FACIL"
		while nChute != nNum1
			nChute := Val(FWInputBox("Descubra o numero de [1-100]",""))
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
	endif
	
	if Upper(AllTrim(cDif)) == "NORMAL"
		while nChute != nNum2
			nChute := Val(FWInputBox("Descubra o numero de [1-500]",""))
			if nChute == nNum2
				MsgInfo ("Você é muito bom - <b>" + cValToChar(nChute) + "</b><br>Tentativas: " + cValToChar(nTent), "Fim de Jogo")
			elseif nChute > nNum2
				MsgAlert("Valor alto","Tente Novamente")
				nTent += 1
			else
				MsgAlert("Valor baixo","Tente novamente")
				nTent += 1
			endif
		end
	endif
	if Upper(AllTrim(cDif)) == "DIFICIL"
		while nChute != nNum3
			nChute := Val(FWInputBox("Descubra o numero de [1-1000]",""))
			if nChute == nNum3
				MsgInfo ("Você é muito bom - <b>" + cValToChar(nChute) + "</b><br>Tentativas: " + cValToChar(nTent), "Fim de Jogo")
			elseif nChute > nNum3
				MsgAlert("Valor alto","Tente Novamente")
				nTent += 1
			else
				MsgAlert("Valor baixo","Tente novamente")
				nTent += 1
			endif
		end
	endif
	//If Upper(AllTrim(cDif)) != ("FACIL".or."NORMAL".or."DIFICIL")
	//	Alert("Opção Inválida!")
	//EndIf
Return


//diminuir o tamanho do codigo(tratar o nivel de dificuldade de acordo com variavel) e acertar o final
