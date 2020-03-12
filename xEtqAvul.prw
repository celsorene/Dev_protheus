#include 'protheus.ch'
#Include "Rwmake.ch"
#Include "topconn.ch"

/*/{Protheus.doc} xEtqAvul
Gera Etiquetas Avulsas 
@type function
@author Celso Rene
@since 06/03/2020
@return null
/*/

User Function xEtqAvul()

	Local oError := ErrorBlock({|e|ChecErro(e)}) //Para exibir um erro mais amigavel
	Local cRetorno := ""
	Local nRetorno := 0
	Local lOk := .F.

	Local nCmPx := 37.795 //1 cm equivale a 37,795 pixels
	Local _cBitMap1 := ""
	Local _cBitMap2 := ""

	Private oPrinter := TMSPrinter():New("Etiquetas Avulsas")
	_cFonte := "Courier" //Fonte padrao das etiquetas

	//Fontes etiqueta de fracionamento
	oFont10N 	:=  TFont():New(_cFonte,09,10,,.T.,,,,,.F.,   ,.F.)
	oFont11N 	:=  TFont():New(_cFonte,09,11,,.T.,,,,,.F.,   ,.F.)
	oFont12N 	:=  TFont():New(_cFonte,09,12,,.T.,,,,,.F.,   ,.F.)
	oFont16N 	:=  TFont():New(_cFonte,09,16,,.T.,,,,,.F.,   ,.F.)
	oFont20N 	:=  TFont():New(_cFonte,09,20,,.T.,,,,,.F.,   ,.F.)
	oFont22N 	:=  TFont():New(_cFonte,09,22,,.T.,,,,,.F.,   ,.F.)

	While !lOk

		cRetorno := FWInputBox("Informe a quantidade de Etiquetas para Impressão:", "")
		lOk := IsNumeric(nRetorno) .and. VAL(cRetorno) > 0

		if !lOk
			MsgAlert("Valor digitado é inválido.","A T E N C A O")
		endif

	EndDo

	If MsgYesNo("Deseja imprimir a Etiqueta de identificação de saída do almoxarifado?")

		_aEtiq := {}
		For i:=1 to val(cRetorno)
			_cCodigo := soma1(GETMV('MV_CODCB0')) 	//Pega o proximo
			aAdd(_aEtiq,_cCodigo)
			PutMv('MV_CODCB0',_cCodigo)		//Grava o codigo atual
		Next i

		//Faz a impressao das etiquetas usando TMSPRINTER
		For i:=1 to len(_aEtiq)

			//INICIO DA IMPRESSAO = PAGINA
			oPrinter:StartPage()

			_cBMP := "\system\lgrl"+ cEmpAnt +".bmp" //BITMAP 

			nLin := 030
			nCol := 030

			//IMPRESSAO DO LOGO 
			nLL1 := 460
			nAL1 := nLL1 * 0.2427 //ALTURA DA IMAGEM EM PROPORÇAO

			oPrinter:SayBitmap( 0 ,50,_cBMP,100,100)//logo LINHA/COLUNA/ARQUIVO/LARG/ALTU

			//INFO INDUSTRIA BRASILEIRA - PADRAO PARA TODAS AS ETIQUETAS
			nLin := 185
			nCol := 270

			//DADOS PADRAO
			oPrinter:Say(nLin-95,nCol-90,"ETIQUETA AVULSA - I.D.",oFont20N)

			//CODIGO DE BARRAS ID UNICO - PADRAO PARA TODOS AS ETIQUETAS
			nLin := 300
			nCol := 480
			//Codigo Unico
			oPrinter:Say(nLin,nCol-30,_aEtiq[i],oFont16N)

			ntopo:=3.10 //dist do topo
			nesqu:=1.52 //dist esquerda
			nlarg:=0.05
			nEsca:=0.90
			msBar3('CODE128', ntopo , nesqu, alltrim( _aEtiq[i]) , oPrinter, .F., , .T., nLarg , nEsca, .F., 'TAHOMA', 'B', .F. )

			oPrinter:EndPage()
			//FIM DA IMPRESSAO = PAGINA

		Next i

		//PRE-VISUALIZACAO DA IMPRESSAO
		oPrinter:Preview()


	EndIf

	//ErrorBlock(oError)

Return()
