#include 'totvs.ch'
#include 'protheus.ch'
/*/{Protheus.doc} User Function JG02
	(jogo de adivinhação de numeros)
	@type  Function
	@author JOAO.GOMES
	@since 05/07/2021
	@param Nil
	@return Nil
/*/

User Function JG02()
	Local nNum1  := 0
	Local nChute := 0
	Local nTent  := 1
	Local cDif
			MsgAlert("Facil(1-100) Normal(1-500) Dificil(1-1000)")
	cDif := FWInputBox("Escolha a dificuldade [Facil/Normal/Dificil]","")
		if cDif=""
			return
		endif

	if Upper(AllTrim(cDif)) == "FACIL"
        nNum1:=Randomize(1,100)
    elseif Upper(AllTrim(cDif)) == "NORMAL"
        nNum1:=Randomize(1,500)
    elseif Upper(AllTrim(cDif)) == "DIFICIL"
        nNum1:=Randomize(1,1000)
    elseif Alert("Opção invalida")
    endif
		while nChute != nNum1            
			nChute := Val(FWInputBox("Chute um numero",""))
				if nChute = 0
					return
				endif
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
	
