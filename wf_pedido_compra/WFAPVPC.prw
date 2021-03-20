#Include "Protheus.ch"
#Include "topconn.ch"
#Include "Rwmake.ch"
#INCLUDE "tbiconn.ch"   
#INCLUDE "TOTVS.CH"

/*/{Protheus.doc} WFAPVPC
//Workflow - aprovacao pedido de compra
@author Celso Rene
@since 17/01/2019
@version 1.0
@type function
/*/
User Function WFAPVPC( cNumPC, lInclusao, lAlteracao, lAprovN2 )

	Local aArea    	:= GetArea()
	Local aAreaSCR	:= SCR->(GetArea())
	Local aAreaSC7	:= SC7->(GetArea())
	Local aAreaSB1	:= SB5->(GetArea())
	Local aAreaSB5	:= SB1->(GetArea())
	Local lEnvia    := .F.

	Private cNomeSup:= "WF Aprovador"
	Private _cMail	:= ""
	Private _cIDUSER:= ""
	Private _cIPServ	:= "http://" + Alltrim(GetMv("MV_WFBRWSR")) + "/WorkFlow/Messenger/Emp" + AllTrim( FWCodEmp() ) + "/WFPC01/"

	Default lInclusao := .F.
	Default lAlteracao := .F.
	Default lAprovN2 := .F.

	dbSelectArea("SCR")
	dbSetOrder(2) // CR_FILIAL+CR_TIPO+CR_NUM+CR_USER                                                                                                                                
	If dbSeek( xFilial("SCR") + "PC" + cNumPC )
		// Conout( "WORKFLOW PC - " + DtoC( Date() ) + " as " + Time() )
		// Conout( "PC: " + cNumPC )
		// Conout( "Inclusao: " + IIF( lInclusao, "Sim", "Nao") )
		// Conout( "Alteracao: " + IIF( lAlteracao, "Sim", "Nao") )
		// Conout( "Aprovar Nivel 2: " + IIF( lAprovN2, "Sim", "Nao") )
	
		Do While ( !SCR->(EOF()) .and. SCR->CR_TIPO == "PC" .and. Alltrim(SCR->CR_NUM) == cNumPC )

			lEnvia := .F.
	
			If lInclusao

				// 01=Aguardando nivel anterior OU 02=Pendente AND primeiro nível
				If ( (SCR->CR_STATUS == "01" .or. SCR->CR_STATUS == "02") .And. Val(SCR->CR_NIVEL) == 1 )
					lEnvia := .T.
				EndIf

			ElseIf lAlteracao

				// 01=Aguardando nivel anterior OU 02=Pendente AND primeiro nível
				If ( (SCR->CR_STATUS == "01" .or. SCR->CR_STATUS == "02") .And. Val(SCR->CR_NIVEL) == 1 )
					lEnvia := .T.
				EndIf
			
			ElseIf ( lAprovN2 .And. Val(SCR->CR_NIVEL) > 1 )
				lEnvia := .T.
			EndIf

			If lEnvia
				_cMail   := UsrRetMail( SCR->CR_USER ) //buscando o e-mail do usuario cadastrado no Protheus
				_cIDUSER := SCR->CR_USER
				cNomeSup := UsrFullName( _cIDUSER )
				//Conout( "Vai iniciar o processo de workflow para o usuario " + _cIDUSER + " com nivel " + SCR->CR_NIVEL )
				If !lAprovN2
					MsgRun( "Gerando WorkFlow de Aprovacao, Aguarde...", "", {|| CursorWait(), XWFENV( cNumPC, lAprovN2 ), CursorArrow() } )
				Else
					XWFENV( cNumPC, lAprovN2 )
				EndIf
			EndIf
			SCR->( dbSkip() )
		EndDo
		//Conout( "Final do loop de Alcadas")
	EndIf

	//Retorna o Posicionamento Original do Arquivo
	RestArea(aAreaSB5)
	RestArea(aAreaSB1)
	RestArea(aAreaSC7)
	RestArea(aAreaSCR)
	RestArea(aArea)

Return()


/*/{Protheus.doc} WFENV
//Funcao monta Workflow, e envia para o destinatario
@author Celso Rene
@since 17/01/2019
@version 1.0
@type function
/*/
Static Function XWFENV( _cNum, lRetNivelUm )

	Local oProcess   	:= Nil
	Local oHtml    		:= Nil
	Local cArqHtml  	:= ""
	Local cDescPrd		:= ""
	Local cAssunto 		:= ""
	Local cUsrCorrente  := ""
	Local cCodigoStatus := ""
	Local cHtmlModelo  	:= ""
	Local cNumPC    	:= _cNum
	Local cDescricao  	:= ""
	Local cUser       	:= RetCodUsr() //__cUserID
	Local cMailID    	:= ""
	Local _x			:= 0

	//Assunto do E-mail
	cAssunto := "Aprovacao do P.C.: " + _cNum

	//Caminho e Arquivo HTML do Link de Formulario de Aprovacao
	cArqHtml := "\Workflow\htmpc\XWFENV.htm"

	//Obtem o Usuario Logado
	cUsrCorrente := AllTrim( UsrRetName( cUser ) ) //SubStr( cUsuario, 7, 15 )

	//Inicia o Processo de WorkFlow de Aprovacao de P.C.
	oProcess := TWFProcess():New( "WFPC01", cAssunto )

	//Cria uma Nova Tarefa Informando o HTML do Link de Envio
	oProcess:NewTask( "Aprovacao Pedido de Compra", cArqHtml )

	//Informa o Codigo e Descricao do Status do Processo Correspondente ao Inicio do Start de WorkFlow 
	cCodigoStatus   := "100100"
	cDescricao   := "Inicio do Processo de Aprovacao P.C."

	//Ratreabilidade com o Codigo do Status, Descricao e Usuario Logado 
	oProcess:Track( cCodigoStatus, cDescricao, cUsrCorrente)

	//Funcao de Retorno da Aprovacao do WorkFlow P.C.
	oProcess:bReturn  := "U_PCRetorno"
	oProcess:cSubject := cAssunto

	//Usuario Responsavel pelo Processo do WorkFlow de Aprovacao P.C.
	oProcess:UserSiga := WFCodUser( cUser )

	//Cria Objeto HTML do Processo de WorkFlow de Aprovacao P.C.
	oHtml := oProcess:oHTML

	//Informa o Codigo e Descricao do Status do Processo Correspondente ao Inicio do Start de WorkFlow 
	cCodigoStatus   := "100200"
	cDescricao   := "Gerando Processo de Aprovacao do P.C."  

	//Ratreabilidade com o Codigo do Status, Descricao e Usuario Logado
	oProcess:Track(cCodigoStatus, cDescricao, cUsrCorrente )

	// Preenche os Campos do HTML com as Informacoes do P.C.
	DBSelectArea("SC7")
	SC7->(DBSetOrder(1))
	SC7->(DBSeek(FwFilial("SC7") + cNumPC))

	oHtml:ValByName( "IDUSER" 		, _cIDUSER )
	oHtml:ValByName( "Dt_Emissao"	, DtoC(SC7->C7_EMISSAO))
	oHtml:ValByName( "Dt_Entrega"	, DtoC(SC7->C7_DATPRF))
	oHtml:ValByName( "Solicitante"	, SC7->C7_SOLICIT)
	oHtml:ValByName( "CC"         	, SC7->C7_CC + " - " + SC7->C7_ITEMCTA)
	oHtml:ValByName( "Aprovacao"  	, "Bloqueada")
	oHtml:ValByName( "Aprovador"  	, cNomeSup)
	oHtml:ValByName( "Num_PC"  		, cNumPC )
	oHtml:ValByName( "COMPRA"  		, UsrFullName( SC7->C7_USER ) )
	oHtml:ValByName( "FORNECE"  	, SC7->C7_FORNECE + "-" + SC7->C7_LOJA + " - " + Left(Posicione("SA2",1,xFilial("SA2") + SC7->C7_FORNECE + SC7->C7_LOJA,"A2_NOME"),30) )

	_cWFID:= oProcess:fProcessID

	// Preencha o Arquivo HTML com as Informacoes do P.C.
	While !SC7->( EOF() ) .And. (SC7->C7_FILIAL == FwFilial("SC7") .And. SC7->C7_NUM == cNumPC)
	
		If SB5->( DbSeek( xFilial("SB5") + SC7->C7_PRODUTO ) )
            cDescPrd := AllTrim( SB5->B5_CEME )
        Else
            dbSelectArea("SB1")
            dbSetOrder(1)
            dbSeek( xFilial("SB1") + SC7->C7_PRODUTO )
            cDescPrd := AllTrim( SB1->B1_DESC )
        EndIf
        
		AADD( ( oHtml:ValByName( "TB.Item"   ))  	, SC7->C7_ITEM    )
		AADD( ( oHtml:ValByName( "TB.Codigo" ))  	, SC7->C7_PRODUTO )
		AADD( ( oHtml:ValByName( "TB.Unid" ))       , SC7->C7_UM  )
		AADD( ( oHtml:ValByName( "TB.Descricao" ))  , cDescPrd )
		AADD( ( oHtml:ValByName( "TB.Qtd" ))  		, Transform( SC7->C7_QUANT,'@E 999,999.99' ) )
		AADD( ( oHtml:ValByName( "TB.UNIT" ))  		, Transform( SC7->C7_PRECO,'@E 999,999.99' ) )
		AADD( ( oHtml:ValByName( "TB.TOTAL" ))  	, Transform( SC7->C7_TOTAL,'@E 999,999.99' ) )
		AADD( ( oHtml:ValByName( "TB.PRF" ))  		, DtoC(SC7->C7_DATPRF) )
		AADD( ( oHtml:ValByName( "TB.SC" ))  		, SC7->C7_NUMSC )
		AADD( ( oHtml:ValByName( "TB.COT" ))  		, SC7->C7_NUMCOT )
		AADD( ( oHtml:ValByName( "TB.OBS" ))  		, SC7->C7_OBS )


		//Criar a Cor das Linhas em Zebrado atraves da verificacao se a Linha Par ou Impar
		If (Val(SC7->C7_ITEM)%2) = 0
			AADD(oHTML:ValByName('TB.Fundo'),"#FFFFFF")
		Else
			AADD(oHTML:ValByName('TB.Fundo'),"#f3f3f3")
		EndIf

		RecLock("SC7", .F.)
			SC7->C7_WFID   := _cWFID
			SC7->C7_DESCRI := cDescPrd
		SC7->(MsUnLock())	

		SC7->(DbSkip())
	Enddo

	//Salva o Processo de WorkFlow na Pasta WFPC01
	oProcess:cTo := "WFPC01"

	//Cria o Processo de WorkFlow para Aprovacao P.C.
	cMailID := oProcess:Start()

	//Associa o Arquivo HTML do Link
	cHtmlModelo := "\workflow\htmpc\XWFLINCK.htm"

	//Cria uma Nova Tarefa par ao Processo de Aprovacao de WorkFlow P.C.
	oProcess:NewTask(cAssunto, cHtmlModelo)

	//E-mail do Aprovador do Processo de Aprovacao de WorkFlow P.C.
	oProcess:cTo := _cMail

	//Substitui as Macros do Arquivo HTML do Link
	oProcess:oHTML:ValByName("usuario"  , AllTrim(cNomeSup))
	oProcess:oHTML:ValByName("referente", cNumPC)
	oProcess:oHTML:ValByName("proc_link", _cIPServ + cMailID + ".htm")
	
	//carregando itens da cotacoes referente ao pedido de compra
	_aCotV := CarregaCOT(cNumPC)

	//COTACOES VENCEDORAS
	For _x:= 1 to Len(_aCotV[2])
	
		AADD( ( oHtml:ValByName( "COTV.Venc"   ))  , _aCotV[2][_x][14] )
		AADD( ( oHtml:ValByName( "COTV.Cot"    ))  , _aCotV[2][_x][1]  )
		AADD( ( oHtml:ValByName( "COTV.Item"   ))  , _aCotV[2][_x][2]  )
		AADD( ( oHtml:ValByName( "COTV.Forn"   ))  , _aCotV[2][_x][3]  )
		AADD( ( oHtml:ValByName( "COTV.Codigo" ))  , _aCotV[2][_x][4]  )
		AADD( ( oHtml:ValByName( "COTV.Unid"   ))  , _aCotV[2][_x][5]  )
		AADD( ( oHtml:ValByName( "COTV.Desc"   ))  , _aCotV[2][_x][6]  )
		AADD( ( oHtml:ValByName( "COTV.Emis"   ))  , _aCotV[2][_x][7]  )
		AADD( ( oHtml:ValByName( "COTV.Qtd"    ))  , _aCotV[2][_x][8]  )
		AADD( ( oHtml:ValByName( "COTV.Unit"   ))  , _aCotV[2][_x][9]  )  
		AADD( ( oHtml:ValByName( "COTV.Total"  ))  , _aCotV[2][_x][10] )
		AADD( ( oHtml:ValByName( "COTV.PRF"    ))  , _aCotV[2][_x][11] )  
		AADD( ( oHtml:ValByName( "COTV.SC"     ))  , _aCotV[2][_x][12] )
		AADD( ( oHtml:ValByName( "COTV.ITSC"   ))  , _aCotV[2][_x][13] )		
		
	Next _x

	//Informa o Codigo e Descricao do Status do Processo Correspondente ao Inicio do Start de WorkFlow
	cCodigoStatus   := "100300"
	cDescricao   := "Enviando Processo de Aprovacao do P.C."

	//Ratreabilidade com o Codigo do Status, Descricao e Usuario Logado
	oProcess:Track( cCodigoStatus, cDescricao, cUsrCorrente )

	//Inicia o Processo de Envio de E-mail do WorkFlow de Aprovacao P.C.
	oProcess:Start()


Return()


//Funcao de Retorno da Aprovacao/Rejeicao do WorkFlow
/*/{Protheus.doc} PCRetorno
//Retorno Workflow - PCRetorno
@author Celso Rene
@since 17/01/2019	
@version 1.0
@type function
/*/
User Function PCRetorno(oProcess)

	//Variaveis Locais
	Local cAssunto  	:= ""
	Local cNumPC    	:= ""
	Local cComprador    := ""
	Local cAprovador    := ""
	Local cNivelAprov   := ""
	Local cUserProt     := ""
	Local cCodigoStatus := ""
	Local cDescricao  	:= ""
	Local cDescWork  	:= ""
	Local cCor    		:= ""
	Local cAprovacao  	:= ""
	Local cStatusAP  	:= ""
	Local cMotRejApv  	:= ""
	Local lPCRejeitado  := .F.
	Local lAprovN2      := .F.

	//Recupera o Numero do P.C. do Processo de WorkFlow
	cNumPC := oProcess:oHtml:RetByName("Num_PC")

	// Código do usuário Protheus que existe no cadastro de Aprovador
	cUserProt := Alltrim(oProcess:oHtml:RetByName("IDUSER"))
	
	// Código do Aprovador
	cAprovador := Posicione("SAK", 2, xFilial("SAK") + cUserProt, "AK_COD")

	// Pega o nível do usuário na Liberação do PC
	// CR_FILIAL + CR_TIPO + CR_NUM + CR_USER
	cNivelAprov := Posicione( "SCR", 2, xFilial("SCR") + "PC" + Padr(cNumPC ,TamSx3("CR_NUM")[1] ) + cUserProt, "CR_NIVEL")

	// Conout( "WORKFLOW PC - " + DtoC( Date() ) + " as " + Time() )
	// Conout( "PC: " + cNumPC )
	// Conout( "Aprovador: " + cAprovador )
	// Conout( "Usuario Protheus: " + cUserProt )
	// Conout( "Nivel: " + cNivelAprov )

	//Informa o Codigo e Descricao do Status do Processo Correspondente ao Inicio do Start de WorkFlow 
	cAssunto   := "Pedido de compras: " + cNumPC
	cCodigoStatus  := "100400"
	cDescricao   := "Aguardando Aprovacao do P.C."

	//Ratreabilidade com o Codigo do Status, Descricao e Usuario Logado 
	oProcess:Track( cCodigoStatus, cDescricao )

	//Verifica se o WorkFlow de Processo de Aprovacao P.C. foi Aprovador ou Rejeitado
	If Upper(oProcess:oHtml:RetByName("RBAPROVA")) <> "SIM"
		//Varives de Controle de Aprovacao de WorkFlow de Aprovacao de P.C.
		cAprovacao := "Rejeitado"
		cStatusAP  := "R"
		cMotRejApv := oProcess:oHtml:RetByName('lbmotivo')

		//Cria uma Nova Tarefa par ao Processo de Aprovacao de WorkFlow de P.C.
		cCodigoStatus := "100600"
		cDescricao    := "P.C. Reprovado"
		cCor          := "#FF6600"
	Else
		//Varives de Controle de Aprovacao e Motivo de Rejeicao do WorkFlow de Aprovacao P.C.
		cAprovacao := "Aprovado"
		cStatusAP  := "L"
		cMotRejApv := oProcess:oHtml:RetByName('lbmotivo')

		//Cria uma Nova Tarefa par ao Processo de Aprovacao de WorkFlow P.C.
		cCodigoStatus := "100500"
		cDescricao    := "P.C. Aprovado"
		cCor          := "#009900"
	EndIf

	DBSelectarea("SC7")
	DBSetOrder(1)
	SC7->( dbSeek(FwFilial("SC7") + cNumPC) )
	cComprador := SC7->C7_USER
	
	lPCRejeitado := ( SC7->C7_CONAPRO == "R" )

	If !lPCRejeitado
		dbSelectArea("SCR")
		dbSetOrder(2) //CR_FILIAL+CR_TIPO+CR_NUM+CR_USER   
		If ( dbSeek(xFilial("SCR") + "PC" + Padr(cNumPC ,TamSx3("CR_NUM")[1] ) + cUserProt ) )

			If cStatusAP == "R" // status de reprovacao

				// Chama rotina padrão (em MATXALC.prx)
				MaAlcDoc({cNumPC,"PC", SC7->C7_TOTAL,cAprovador,cUserProt,SCR->CR_GRUPO,,,,,cMotRejApv}, dDataBase, 7/*nOper*/)

				DBSelectarea("SC7")
				DBSetOrder(1)
				SC7->(dbSeek(FwFilial("SC7") + cNumPC))
				While !SC7->(EOF()) .And. ( SC7->C7_FILIAL == FwFilial("SC7") .And. SC7->C7_NUM == cNumPC )
					
					RecLock("SC7",.F.)
						SC7->C7_CONAPRO  := cStatusAP
						SC7->C7_APROV    := cAprovador
						SC7->C7_OBS      := AllTrim(SC7->C7_OBS) + IIF(AllTrim(SC7->C7_OBS) == "" .Or. AllTrim(cMotRejApv) == "", "", " - ") + cMotRejApv
					SC7->(MsUnLock())

					SC7->(DBSkip())
				EndDo
			
			Else // Liberação do PC

				If Val( cNivelAprov ) == 1 .And. cNivelAprov == SCR->CR_NIVEL
					lAprovN2 := .T.
				EndIf

				// Chama rotina padrão (em MATXALC.prx)
				MaAlcDoc({cNumPC,"PC", SC7->C7_TOTAL,cAprovador,cUserProt,SCR->CR_GRUPO,,,,,cMotRejApv}, dDataBase, 4/*nOper*/)

				// Pedido TOTALMENTE liberado
				If xLibPC(cNumPC) == .T.

					DBSelectarea("SC7")
					DBSetOrder(1)
					SC7->(dbSeek(FwFilial("SC7") + cNumPC))
					
					While !SC7->(EOF()) .And. ( SC7->C7_FILIAL == FwFilial("SC7") .And. SC7->C7_NUM == cNumPC)
						
						RecLock("SC7",.F.)
							SC7->C7_CONAPRO  := cStatusAP
							SC7->C7_APROV    := cAprovador
							SC7->C7_OBS      := AllTrim(SC7->C7_OBS) + IIF(AllTrim(SC7->C7_OBS) == "" .Or. AllTrim(cMotRejApv) == "", "", " - ") + cMotRejApv
						SC7->(MsUnLock())
						SC7->(DBSkip())
					EndDo
				EndIf
			EndIf
		EndIf
	
	EndIf // If !lPCRejeitado

	//Associa a Descricao do Track ao Titulo da Notificacao
	cDescWork := cDescricao 

	//Ratreabilidade com o Codigo do Status, Descricao e Usuario Logado 
	oProcess:Track( cCodigoStatus, cDescricao )

	// PC TOTALMENTE Liberado 
	If xLibPC(cNumPC) == .T. .Or. lPCRejeitado
		// Execute a funcao responsavel pela notificacao ao usuario solicitante.
		U_CPNotificar( oProcess, cDescWork, cCor, cAprovacao, cComprador )
	EndIf

	// Chama novamente a rotina de Workflow para enviar o e-mail para os níveis maiores do que um
	If lAprovN2
		U_WFAPVPC( cNumPC, .F. /*lInclusao*/, .F. /*lAlteracao*/, .T. /*lAprovN2*/ )
	EndIf

Return Nil



//Funcao de Notificacao do WorkFlow de Aprovacao P.C.
User Function CPNotificar( oProcess, cDescWork, cCor, cAprovacao, cComprador )

	Local oHtml    := Nil
	Local aValues   := Array(20)
	Local cCodigoStatus  := ""
	Local cDescricao  := ""
	Local cArqHtml  := ""

	//Caminho e Arquivo HTML do Link de Formulario de Aprovacao
	cArqHtml := "\Workflow\htmpc\XWFAPROV.htm"

	//Informa o Codigo do Status do Processo Correspondente ao Inicio do Start de WorkFlow
	cCodigoStatus  := "100700"
	cDescricao   := "Notifica a Aprovacao/Reprovacao ao Solicitante e ao Departamento de Compras"

	//Ratreabilidade com o Codigo do Status, Descricao e Usuario Logado
	oProcess:Track( cCodigoStatus, cDescricao )

	//Cria Objeto HTML do Processo de WorkFlow de Aprovacao do P.C.
	oHtml := oProcess:oHtml

	//Atribui os Valores Recuperados do HTML ao Array aValues
	aValues[01] := oHtml:ValByName("Num_PC")
	aValues[02] := oHtml:ValByName("Dt_Emissao")
	aValues[03] := oHtml:ValByName("Dt_Entrega")
	aValues[04] := oHtml:ValByName("Solicitante")
	aValues[05] := oHtml:ValByName("CC")
	aValues[06] := oHtml:ValByName("TB.Item")
	aValues[07] := oHtml:ValByName("TB.Codigo")
	aValues[08] := oHtml:ValByName("TB.Unid")
	aValues[09] := oHtml:ValByName("TB.Descricao")
	aValues[10] := oHtml:ValByName("TB.Qtd")
	aValues[11] := oHtml:ValByName("TB.Fundo")
	aValues[12] := UsrFullName(Alltrim(oProcess:oHtml:RetByName("IDUSER")) ) //oHtml:ValByName("Aprovador")
	aValues[13] := oHtml:ValByName("COMPRA")
	aValues[14] := oHtml:ValByName("FORNECE")

	aValues[15] := oHtml:ValByName("TB.UNIT")
	aValues[16] := oHtml:ValByName("TB.TOTAL")
	aValues[17] := oHtml:ValByName("TB.PRF")
	aValues[18] := oHtml:ValByName("TB.SC")
	aValues[19] := oHtml:ValByName("TB.COT")
	aValues[20] := oHtml:ValByName("TB.OBS")

	//Cria uma Nova Tarefa Informando o HTML do Link de Envio
	oProcess:NewTask("Resultado da Aprovacao", cArqHtml )

	oHtml := oProcess:oHtml

	//Recupera as Informacoes do Array e Preenche o Arquivo HTML de Notificao
	oHtml:ValByName("Num_PC" 		, aValues[01] )
	oHtml:ValByName("Dt_Emissao"  	, aValues[02] )
	oHtml:ValByName("Dt_Entrega" 	, aValues[03] )
	oHtml:ValByName("Solicitante"  	, aValues[04] )
	oHtml:ValByName("CC"   			, aValues[05] )
	oHtml:ValByName("Aprovador"  	, aValues[12] )
	oHtml:ValByName("COMPRA"  		, aValues[13] )
	oHtml:ValByName("FORNECE"   	, aValues[14] )

	//Recupera as Informacoes do Array e Preenche o Arquivo HTML de Notificao
	AEval( aValues[06],{ |x| AADD( oHtml:ValByName( "TB.Item" )     , x ) } )
	AEval( aValues[07],{ |x| AADD( oHtml:ValByName( "TB.Codigo" )   , x ) } )
	AEval( aValues[08],{ |x| AADD( oHtml:ValByName( "TB.Unid" )    	, x ) } )
	AEval( aValues[09],{ |x| AADD( oHtml:ValByName( "TB.Descricao" ), x ) } )
	AEval( aValues[10],{ |x| AADD( oHtml:ValByName( "TB.Qtd" )   	, x ) } )
	AEval( aValues[11],{ |x| AADD( oHtml:ValByName( "TB.Fundo" )    , x ) } )
	AEval( aValues[15],{ |x| AADD( oHtml:ValByName( "TB.UNIT" )     , x ) } )
	AEval( aValues[16],{ |x| AADD( oHtml:ValByName( "TB.TOTAL" )    , x ) } )
	AEval( aValues[17],{ |x| AADD( oHtml:ValByName( "TB.PRF" )      , x ) } )
	AEval( aValues[18],{ |x| AADD( oHtml:ValByName( "TB.SC" )       , x ) } )
	AEval( aValues[19],{ |x| AADD( oHtml:ValByName( "TB.COT" )      , x ) } )
	AEval( aValues[20],{ |x| AADD( oHtml:ValByName( "TB.OBS" )      , x ) } )

	////Recupera as Informacoes das Variaveis e Preenche o Arquivo HTML de Notificao
	oHtml:ValByName( "Titulo"    	, cDescWork )
	oHtml:ValByName( "Cor_Tit"   	, cCor )
	oHtml:ValByName( "Cor_Itens" 	, cCor )
	oHtml:ValByName( "Aprovacao" 	, cAprovacao)
	oHtml:ValByName( "Dt_Aprov"  	, dDataBase )
	oHtml:ValByName( "Hora_Aprov"  	, Time()  )

	//E-mail que Ira Receber a Notificacao de Aprovacao/Rejeicao do Processo de WorkFlow
	//comprador do pedido de compra recebe notificacao automatica
	oProcess:cTo := UsrRetMail( cComprador )

	//Assunto do E-mail que Ira Receber a Notificacao de Aprovacao/Rejeicao do Processo de WorkFlow
	oProcess:cSubject := "Retorno da Aprovacao do Pedido de Compras: " + aValues[01] 

	//Cria e Inicia o Processo de Envio de E-mail do WorkFlow de Aprovacao do P.C.
	oProcess:Start()

	//Informa o Codigo e Descricao do Status do Processo Correspondente ao Inicio do Start de WorkFlow 
	cCodigoStatus := "100800"
	cDescricao := "Finalizacao do Processo de Workflow de Aprovacao do P.C."

	//Ratreabilidade com o Codigo do Status, Descricao e Usuario Logado
	oProcess:Track( cCodigoStatus, cDescricao )

Return Nil


/*/{Protheus.doc} xLibPC
//Verifica se liberados os registros da SRC
@author Celso Rene
@since 17/01/2019
@version 1.0
@type function
/*/
Static Function xLibPC(_cNumPC)

	Local _lRet := .T.	 

	dbSelectArea("SCR")
	dbSetOrder(2) //CR_FILIAL+CR_TIPO+CR_NUM+CR_USER
	DbGoTop()
	If ( dbSeek(xFilial("SCR") + "PC" + _cNumPC ) )
		While ( !SCR->(EOF()) .and. SCR->CR_TIPO == "PC" .and. Alltrim(SCR->CR_NUM) == _cNumPC ) 
			/*
			Status da SCR:
				01 = Aguardando nivel anterior
				02 = Pendente
				03 = Liberado
				04 = Bloqueado
				05 = Liberado/Rejeirado outro usuario
				06 = Rejeitado
			*/
			If ( SCR->CR_STATUS == "01" .or. SCR->CR_STATUS == "02" .or. SCR->CR_STATUS == "04" .or. SCR->CR_STATUS == "06" )
				_lRet := .F.
				Exit
			EndIf
			SCR->(dbSkip())
		EndDo  
	EndIf

Return(_lRet)


/*/{Protheus.doc} CarregaCOT
//Seleciona cotacoes do pedido de compra
@author Celso Rene
@since 21/01/2019
@version 1.0
@type function
/*/
Static Function CarregaCOT(_cPCCot)

	Local _lRet 	:= .F.		//logico informando se retornou cotacoes
	Local _cQuery	:= ""		//string para mostar query 
	Local _aCot		:= {} 		//itens cotacoes do P.C.
	Local _cCotIN	:= ""		//S.C. - cotacoes a serem listadas
	Local _cItem	:= "0000" 	//incremental registros - cotacoes

	_cQuery := " SELECT SC7.C7_NUM, SC8.C8_NUM, SC8.C8_ITEM, SC8.C8_NUMPRO, SC8.C8_PRODUTO, SB1.B1_DESC , SC8.C8_UM, SC8.C8_QTDCTR, SC8.C8_QUANT, SC8.C8_PRECO " + chr(13)
	_cQuery += " ,SC8.C8_TOTAL, SC8.C8_FORNECE, SC8.C8_LOJA, SC8.C8_EMISSAO, SC8.C8_NUMPED, SC8.C8_ITEMPED,SC8.C8_NUMSC, SC8.C8_ITEMSC, SC8.C8_DATPRF , SC8.C8_FORNOME " + chr(13)
	_cQuery += " , SC8.C8_TPDOC, SC8.C8_CODORCA " + chr(13)
	_cQuery += " FROM  " + RetSqlName("SC7")+" SC7 WITH (NOLOCK) " + chr(13) 
	//_cQuery += " INNER JOIN " + RetSqlName("SA2")+" SA2 ON SA2.A2_COD = SC7.C7_FORNECE AND SA2.A2_LOJA = SC7.C7_LOJA AND SA2.D_E_L_E_T_ = '' AND SA2.A2_FILIAL = '" + xFilial("SA2") + "' " + chr(13)
	_cQuery += " INNER JOIN " + RetSqlName("SB1")+" SB1 ON SB1.B1_COD = SC7.C7_PRODUTO AND SB1.D_E_L_E_T_ = '' AND SB1.B1_FILIAL = '" + xFilial("SB1") + "' AND SB1.D_E_L_E_T_ = '' " + chr(13)
	_cQuery += " INNER JOIN " + RetSqlName("SC8")+" SC8 ON SC8.C8_NUMPED <> '' AND SC8.C8_NUMPED = SC7.C7_NUM AND SC8.C8_ITEMPED = SC7.C7_ITEM AND SC8.C8_NUMSC = SC7.C7_NUMSC  " + chr(13)
	_cQuery += " AND SC8.C8_ITEMSC = SC7.C7_ITEMSC AND SC8.D_E_L_E_T_ = '' AND SC8.C8_FILIAL = '" + xFilial("SC8") + "' " + chr(13)
	_cQuery += " WHERE SC7.D_E_L_E_T_ = '' AND SC7.C7_FILIAL = '" + xFilial("SC7") + "'  AND SC7.C7_NUM = '" + _cPCCot + "' " + chr(13) 
	_cQuery += " ORDER BY SC8.C8_NUMPED,SC8.C8_ITEMPED, SC8.C8_NUMSC,SC8.C8_ITEMSC , SC8.C8_NUM,SC8.C8_ITEM " 

	If Select("TSC8") <> 0
		TSC8->(DbCloseArea())
	EndIf

	TcQuery _cQuery Alias "TSC8" New
	DbSelectArea("TSC8")	
	If (!TSC8->(Eof()) )
		While !TSC8->(EOF()) 
		
			_cItem := Soma1(_cItem) 

			AADD(_aCot, { ;
			TSC8->C8_NUM,;
			TSC8->C8_ITEM,;
			TSC8->C8_FORNECE + "-" + TSC8->C8_LOJA + " - " + Left(TSC8->C8_FORNOME,20),;			
			TSC8->C8_PRODUTO,;
			TSC8->C8_UM,;
			Left(TSC8->B1_DESC,20),;
			DtoC(StoD(TSC8->C8_EMISSAO)),;
			Transform( TSC8->C8_QUANT,'@E 999,999.99' ),;
			Transform( TSC8->C8_PRECO,'@E 999,999.99' ),;
			Transform( TSC8->C8_TOTAL,'@E 999,999.99' ),;
			DtoC(StoD(TSC8->C8_DATPRF)),;
			TSC8->C8_NUMSC,;
			TSC8->C8_ITEMSC,;
			TSC8->C8_NUMPED + TSC8->C8_ITEMPED,;
			_cItem  } )
	

			//adicionando solicitacoes
			If !(Alltrim(TSC8->C8_NUMSC) $ _cCotIN)
				_cCotIN += If(_cCotIN == "",TSC8->C8_NUMSC + TSC8->C8_ITEMSC ,"," + TSC8->C8_NUMSC + TSC8->C8_ITEMSC)
			EndIf 

			_lRet := .T.

			TSC8->(DBSkip())

		EndDo

	Else
	
		//_cItem := Soma1(_cItem) 

		AADD(_aCot, { ;
		"",;
		"",;
		"",;
		"",;
		"",;
		"",;
		"",;												
		"",;
		"",;
		"",;
		"",;
		"",;
		"",;
		"-Sem cotacoes-",;
		_cItem  } )

	EndIf

	TSC8->(dbCloseArea())

	_cQuery := " SELECT SC8.C8_NUM, SC8.C8_ITEM, SC8.C8_NUMPRO, SC8.C8_PRODUTO, SB1.B1_DESC , SC8.C8_UM, SC8.C8_QTDCTR, SC8.C8_QUANT, SC8.C8_PRECO " + chr(13)
	_cQuery += " ,SC8.C8_TOTAL, SC8.C8_FORNECE, SC8.C8_LOJA, SC8.C8_EMISSAO, SC8.C8_NUMPED, SC8.C8_ITEMPED,SC8.C8_NUMSC, SC8.C8_ITEMSC, SC8.C8_DATPRF , SC8.C8_FORNOME " + chr(13)
	_cQuery += " , SC8.C8_TPDOC, SC8.C8_CODORCA " + chr(13)
	_cQuery += " FROM  " + RetSqlName("SC8")+" SC8 " + chr(13) 
	_cQuery += " INNER JOIN " + RetSqlName("SB1")+" SB1 ON SB1.B1_COD = SC8.C8_PRODUTO AND SB1.B1_FILIAL = '" + xFilial("SB1") + "' AND SB1.D_E_L_E_T_ = '' " + chr(13)
	_cQuery += " WHERE SC8.C8_FILIAL = '" + xFilial("SC8") + "' AND SC8.D_E_L_E_T_ = '' AND SC8.C8_NUMSC + SC8.C8_ITEMSC IN ('" + Alltrim(STRTRAN(_cCotIN,",","','")) + "') AND SC8.C8_NUMPED = '' " + chr(13)
	_cQuery += " ORDER BY SC8.C8_NUMSC, SC8.C8_ITEMSC, SC8.C8_NUM,SC8.C8_ITEM " 	

	If Select("TSC82") <> 0
		TSC82->(DbCloseArea())
	EndIf

	TcQuery _cQuery Alias "TSC82" New
	DbSelectArea("TSC82")	
	If (!TSC82->(Eof()) )
		While !TSC82->(EOF()) 

			_cItem := Soma1(_cItem) 
			
			AADD(_aCot, { ;
			TSC82->C8_NUM,;
			TSC82->C8_ITEM,;
			TSC82->C8_FORNECE + "-" + TSC82->C8_LOJA + " - " + Left(TSC82->C8_FORNOME,20),;
			TSC82->C8_PRODUTO,;
			TSC82->C8_UM,;
			Left(TSC82->B1_DESC,20),;
			DtoC(StoD(TSC82->C8_EMISSAO)),;
			Transform( TSC82->C8_QUANT,'@E 999,999.99' ),;
			Transform( TSC82->C8_PRECO,'@E 999,999.99' ),;
			Transform( TSC82->C8_TOTAL,'@E 999,999.99' ),;
			DtoC(StoD(TSC82->C8_DATPRF)),;
			TSC82->C8_NUMSC,;
			TSC82->C8_ITEMSC,;
			"",;
			_cItem  } )
			
			
			_lRet := .T.

			TSC82->(DBSkip())

		EndDo

	EndIf

	TSC82->(DbCloseArea())


Return({_lRet,_aCot})
