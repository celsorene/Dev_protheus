#INCLUDE "TOTVS.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"

//Posicoes do array aDados
#DEFINE POS_ITEM    1
#DEFINE POS_PROD    2
#DEFINE POS_DESCPRO 3
#DEFINE POS_UM      4
#DEFINE POS_OPER    5
#DEFINE POS_TES     6
#DEFINE POS_NCM     7
#DEFINE POS_RECNO   8
#DEFINE POS_FORNECE 9
#DEFINE POS_LOJA    10

/*/{Protheus.doc} MT120FIM
//P.E. - Final pedido de compra
//Apos a restauracao do filtro da FilBrowse depois de fechar a operacao realizada no pedido de compras, 
//e a ultima instrucao da funcao A120Pedido
@author Celso Rene
@since 17/01/2019
@version 1.0
@type function
/*/
User Function MT120FIM()
	
   Local _nOpcao 	:= PARAMIXB[1]   // Opcao escolhida pelo usuario 
   Local _cNumPC 	:= PARAMIXB[2]   // Numero do pedido de compras   
   Local _nOpcA  	:= PARAMIXB[3]   // Indica se a acao foi cancelada = 0  ou confirmada = 1
   Local cAliAtu   := Alias()
   Local _aAreaC7	:= SC7->( GetArea() )
   Local _aAreaC8	:= SC8->( GetArea() )
   Local _aAreaCR	:= SCR->( GetArea() )
   Local _aAreaB1	:= SB1->( GetArea() )
   Local _aAreaB5	:= SB5->( GetArea() )
   Local _aAreaX3	:= SX3->( GetArea() )

   // Jorge Alberto - Solutio - 05/11/2019 - #24586 - Inclusão da rotina que atualiza alguns dados do PC.
   // Inclusão ou Alteração
   If ( ( _nOpcao == 3 .and. _nOpcA == 1 ) .Or. ( _nOpcao == 4 .And. _nOpcA == 1 ) )
      AtualizaPC( SC7->C7_NUM )
   EndIf

   RestArea( _aAreaC7 )
   RestArea( _aAreaC8 )
   RestArea( _aAreaCR )
   RestArea( _aAreaB1 )
   RestArea( _aAreaB5 )
   RestArea( _aAreaX3 )
   If !Empty( cAliAtu )
      DbSelectArea( cAliAtu )
   EndIf
 
   // Inclusão ou Alteração
   If ( ( _nOpcao == 3 .and. _nOpcA == 1 ) .Or. ( _nOpcao == 4 .And. _nOpcA == 1 ) )
      U_WFAPVPC( _cNumPC, (_nOpcao == 3), (_nOpcao == 4) )
   EndIf	

   RestArea( _aAreaC7 )
   RestArea( _aAreaC8 )
   RestArea( _aAreaCR )
   RestArea( _aAreaB1 )
   RestArea( _aAreaB5 )
   RestArea( _aAreaX3 )
   If !Empty( cAliAtu )
       DbSelectArea( cAliAtu )
   EndIf

Return()


/*/{Protheus.doc} AtualizaPC
//Rotina que mostra alguns dados do PC na tela para que o usuário possa alterar alguns dados do PC.
@author Jorge Alberto
@since 05/11/2019
@version 1.0
@type static function
/*/
Static Function AtualizaPC( cNumPC )

   Local aDados := {}
   Local nOpcao := 0
   Local nReg := 0
   Local oDlg
   Local oListPC
   Local oGetOper
   Local cDescProd := ""
   Local cOper := Space(2)
   Local cPictNCM := ""

   dbSelectArea("SB1")
   dbSetOrder(1)

   dbSelectArea("SB5")
   dbSetOrder(1)

   DbSelectArea("SC7")
   DbSetOrder(1)
   SC7->( DbSeek( xFilial("SC7")+ cNumPC ) )
   While SC7->( !EOF() ) .And. SC7->C7_NUM == cNumPC

       // Não pode ter nenhuma quantidade do Produto com entrega Parcial e Classificada (PC já usado em Pre Nota).
       If ( SC7->C7_QUJE == 0 .And. SC7->C7_QTDACLA == 0 )

           If SB5->( DbSeek( xFilial("SB5") + SC7->C7_PRODUTO ) )
               cDescProd := Left( AllTrim( SB5->B5_CEME ), 50 )
               
               SB1->( DbSeek( xFilial("SB1") + SC7->C7_PRODUTO ) )
               cNCM := SB1->B1_POSIPI
           Else
               SB1->( DbSeek( xFilial("SB1") + SC7->C7_PRODUTO ) )
               cDescProd := Left( AllTrim( SB1->B1_DESC ), 50 )
               cNCM      := SB1->B1_POSIPI
           EndIf

           AADD( aDados, { SC7->C7_ITEM, SC7->C7_PRODUTO, cDescProd, SC7->C7_UM, cOper, SC7->C7_TES, cNCM, SC7->( Recno() ), SC7->C7_FORNECE, SC7->C7_LOJA } )
       
       EndIf

       SC7->( DbSkip() )
   EndDo

   If Len( aDados ) <= 0
       Return
   EndIf

   cPictNCM := PesqPict("SB1", "B1_POSIPI")

   DEFINE MSDIALOG oDlg TITLE "Atualização do TES no Pedido de Compra" FROM 0,0 TO 400,800 PIXEL

   @ 008,005 SAY "Operação" SIZE 035,010 OF oDlg PIXEL
   @ 005,035 MSGET oGetOper VAR cOper SIZE 015,010 F3( "DJ") Valid IIF( Empty(cOper) .Or. ExistCPO("SX5", "DJ" + cOper ), AtualizTES( @oListPC, 0, cOper ), .F. )  OF oDlg PIXEL

   @ 025,005 LISTBOX oListPC FIELDS HEADER "Item", "Produto", "Descrição", "UM", "Operação", "TES", "NCM";
   SIZE 395,140 OF oDlg PIXEL ON dblClick( EditCpo( @oListPC, oListPC:ColPos ) )

   oListPC:SetArray( aDados )
   oListPC:bLine := {||{ aDados[oListPC:nAt,POS_ITEM],;
                       aDados[oListPC:nAt,POS_PROD],;
                       aDados[oListPC:nAt,POS_DESCPRO],;
                       aDados[oListPC:nAt,POS_UM],;
                       aDados[oListPC:nAt,POS_OPER],;
                       aDados[oListPC:nAt,POS_TES],;
                       Transform( aDados[oListPC:nAt,POS_NCM], cPictNCM ) } }

   @ 175,015 Button "Confirma" Size 037,012 PIXEL OF oDlg ACTION( nOpcao := 1, oDlg:End() )
   @ 175,065 Button "Sair"     Size 037,012 PIXEL OF oDlg ACTION( nOpcao := 0, oDlg:End() )

   ACTIVATE MSDIALOG oDlg CENTERED

   If nOpcao <> 1
       Return
   EndIf

   // Atualiza o TES no PC
   For nReg := 1 To Len( aDados )

       If !Empty( aDados[ nReg, POS_TES ] )
           
           SC7->( DbGoTo( aDados[ nReg, POS_RECNO ] ) )
           RecLock( "SC7", .F. )
               SC7->C7_TES := aDados[ nReg, POS_TES ]
           MsUnLock()
       EndIf

   Next

Return


/*/{Protheus.doc} EditCpo
//Editar uma determinada celula do grid
@author Jorge Alberto
@since 05/11/2019
@version 1.0
@type static function
/*/
Static Function EditCpo( oListBox, nColPos )

  Local aDim  
  Local bSetGet
  Local bValid
  Local oDlg
   Local oGet
   
  If nColPos == POS_OPER
     bSetGet := { |u| IF( PCount() == 0, oListBox:aArray[oListBox:nAT][oListBox:ColPos], oListBox:aArray[oListBox:nAT][oListBox:ColPos] := u ) }
       bValid := {|| IIF( Empty(oListBox:aArray[oListBox:nAT][nColPos]) .Or. ExistCPO("SX5", "DJ" + oListBox:aArray[oListBox:nAT][nColPos] ), AtualizTES( @oListBox, oListBox:nAT, oListBox:aArray[oListBox:nAT][POS_OPER] ), .F. ) }

       // Preenche com espaços até o limite de caracteres
     oListBox:aArray[oListBox:nAT][nColPos] := PadR( AllTrim( oListBox:aArray[oListBox:nAT][nColPos] ), 02, "" )

     GetCellRect( @oListBox , @aDim ) //Obtenho as Coordenadas da Celula

     DEFINE MSDIALOG oDlg FROM 0,0 TO 0,0 STYLE nOR( WS_VISIBLE , WS_POPUP ) PIXEL WINDOW oListBox:oWnd
     oGet := TGet():New( 0/*[nRow]*/, 0/*[nCol]*/, bSetGet, oDlg, 80/*[nWidth]*/, 50/*[nHeight]*/, /*[cPict]*/, bValid, CLR_BLACK/*[nClrFore]*/, CLR_WHITE/*[nClrBack]*/, NIL/*[oFont]*/, NIL/*[uParam12]*/, NIL/*[uParam13]*/, .T./*[lPixel]*/, NIL/*[uParam15]*/, NIL/*[uParam16]*/, /*bWhen*/, NIL/*[uParam18]*/, NIL/*[uParam19]*/, /*bChange*/, .F./*[lReadOnly]*/, .F./*[lPassword]*/, NIL/*[uParam23]*/, oListBox:aArray[oListBox:nAT][oListBox:ColPos] /*[cReadVar]*/, NIL/*[uParam25]*/, NIL/*[uParam26]*/, NIL/*[uParam27]*/, .F./*[lHasButton]*/, .F./*[lNoButton]*/, NIL/*[uParam30]*/, ""/*[cLabelText]*/, NIL/*[nLabelPos]*/, NIL/*[oLabelFont]*/, NIL/*[nLabelColor]*/, ""/*[cPlaceHold]*/, .F./*[lPicturePriority]*/, .F./*[lFocSel]*/ )
     oGet:Move( -2 , -2 , ( ( aDim[ 4 ] - aDim[ 2 ] ) + 4 ) , ( ( aDim[ 3 ] - aDim[ 1 ] ) + 4 ) )
     oDlg:Move( aDim[1] , aDim[2] , ( aDim[4]-aDim[2] ) , ( aDim[3]-aDim[1] ) )
     @ 0, 0 BUTTON oBtn PROMPT "" SIZE 0,0 OF oDlg
     oBtn:bGotFocus	:= { || oDlg:nLastKey := VK_RETURN , oDlg:End(0) }
       ACTIVATE MSDIALOG oDlg
   EndIf
   
   oListBox:Refresh()

Return


/*/{Protheus.doc} AtualizTES
//Preenche o TES conforme a Operação informada no campo do cabeçalho ou no item do PC.
@author Jorge Alberto
@since 05/11/2019
@version 1.0
@type static function
/*/
Static Function AtualizTES( oListBox, nItem, cOperacao )

   Local cTES := ""
   Local nReg := 0
   Local nTotReg := Len( oListBox:aArray )

   If Empty( cOperacao )
       Return
   EndIf

   DEFAULT nItem := 0

   // Pode estar posicionado na linha
   If nItem > 0
       cTES := MaTesInt( 1, cOperacao, oListBox:aArray[nItem][POS_FORNECE], oListBox:aArray[nItem][POS_LOJA], "F", oListBox:aArray[nItem][POS_PROD] )

       //If !Empty( cTES )
           oListBox:aArray[nItem][POS_TES] := PadR( cTES, 3, "" )
       //EndIf

   Else // Se não está na linha, então atualiza todas as linhas

       For nReg := 1 To nTotReg
           cTES := MaTesInt( 1, cOperacao, oListBox:aArray[nReg][POS_FORNECE], oListBox:aArray[nReg][POS_LOJA], "F", oListBox:aArray[nReg][POS_PROD] )

           //If !Empty( cTES )
               oListBox:aArray[nReg][POS_TES] := PadR( cTES, 3, "" )
           //EndIf
       Next
   EndIf

   oListBox:Refresh()
Return
