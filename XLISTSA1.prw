#Include "Protheus.ch"
#Include "Totvs.ch"
#Include "topconn.ch"


/*/{Protheus.doc} XLISTSA1
//Tela para selecao - ListBox                                                               
@author Celso Rene
@since 17/03/2020
@version 1.0
@type function                                                   
/*/
User Function XLISTSA1()

	Local oButton1
	Local oButton2
	Local oGet1
	Local cGet1         := Space(14)
    Local oGet2
    Local cGet2         := Space(50)
	Local oSay1
	Local oFont1        := TFont():New("MS Sans Serif",,015,,.F.,,,,,.F.,.F.)

	Private lMark       := .F.
	Private lChk        := .F.
	Private oOk         := LoadBitmap( GetResources(), "CHECKED" )
	Private oNo         := LoadBitmap( GetResources(), "UNCHECKED" )
    Private nListBox1   := 1
    Private oCheckBo1 
    Private oListBox1
	Private _oDlg
	Private _aVetor	    := {}
    Private _lRetOK     := .F.



	_cQuery:= " SELECT A1_COD, A1_LOJA, A1_NOME "+ chr(13)
	_cQuery+= " FROM "+ RETSQLNAME("SA1") + " WHERE D_E_L_E_T_ = '' "+ chr(13)

	If( Select( "TMP" ) <> 0 )
		TMP->( DbCloseArea() )
	EndIf

	TcQuery _cQuery New Alias "TMP"

	dbSelectArea("TMP")
	dbGoTop()

	If TMP->( EOF() )
		MsgAlert("Conforme parametros informados nao foi encontrado nenhum registro!","#Registros")
		Return()
	EndIf

	TMP->(DbGotop())
	While TMP->(!Eof())

		lMark   	   := .F. //controle marca / desmarca 
		Aadd( _aVetor,{ lMark, TMP->A1_COD, TMP->A1_LOJA, TMP->A1_NOME })

		TMP->(DbSkip())

	EndDo

	dbCloseArea("TMP")

	DEFINE MSDIALOG _oDlg TITLE "Lista cliente - listbox" FROM 0, 0  TO 500, 500 COLORS 0, 16777215 PIXEL

	@ 013, 009 SAY oSay1 PROMPT "DOC:" SIZE 015, 007 OF _oDlg FONT oFont1 COLORS 0, 16777215 PIXEL
	@ 010, 030 MSGET oGet1 VAR cGet1 SIZE 061, 012 OF _oDlg COLORS 0, 16777215 FONT oFont1 PIXEL //READONLY
    @ 010, 097 MSGET oGet2 VAR cGet2 SIZE 144, 012 OF _oDlg COLORS 0, 16777215 FONT oFont1 PIXEL //READONLY

	@ 043, 007 LISTBOX oListBox1 VAR VAR cVar FIELDS HEADER  "", "Codigo", "Loja", "Nome"  SIZE 235, 182 OF _oDlg COLORS 0, 16777215 FONT oFont1 PIXEL;
	ON dblClick(_aVetor[oListBox1:nAt,1] := !_aVetor[oListBox1:nAt,1],oListBox1:Refresh())

	oListBox1:SetArray( _aVetor )
	oListBox1:bLine := {|| {Iif(_aVetor[oListBox1:nAt,1],oOk,oNo),_aVetor[oListBox1:nAt,2],_aVetor[oListBox1:nAt,3],_aVetor[oListBox1:nAt,4] }}

	@ 031, 008 CHECKBOX oCheckBo1 VAR lChk PROMPT "Marcar todos/desmarcar" SIZE 071, 008 OF _oDlg COLORS 0, 16777215 PIXEL ;
	ON CLICK( aEval( _aVetor, { |x| x[1] := lChk } ), oListBox1:Refresh()) 

	@ 233, 014 BUTTON oButton1 PROMPT "O.K." SIZE 037, 012 OF _oDlg PIXEL ACTION(xConfirma())
	@ 233, 059 BUTTON oButton2 PROMPT "CANCELAR" SIZE 037, 012 OF _oDlg PIXEL ACTION(_oDlg:End())
	
	 ACTIVATE MSDIALOG _oDlg CENTERED



Return(_lRetOK)


/*/{Protheus.doc} xMarcaApont
//Marca registros - LISTBOX
@author Celso Rene
@since 20/03/2020
@version 1.0
@type function                                           
/*/
Static Function xMarcaApont()

Local _nx := 0

//marcando conforme apontamento de producao 
    For _nx := 1 to Len(_aVetor)
    	_aVetor[_nx][1] := iif(lChk , .T. , .F.)
    Next _nx

oListBox1:Refresh()


Return()


/*/{Protheus.doc} xConfirmar
//Confirma - gravar dados                                                   
@author Celso Rene
@since 17/03/2020   
@version 1.0  
@type function                                                
/*/
Static Function xConfirma()

MsgInfo("Gravou!","# Operação confirmada")

_lRetOK     := .T.
_oDlg:End()


Return()
