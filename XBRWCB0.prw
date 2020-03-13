#INCLUDE "rwmake.ch"
#INCLUDE "PROTHEUS.CH"
#include "TOPCONN.CH"


/*/{Protheus.doc} XBRWCB0
//Cadastro customizado CB0 - Etiquetas
@author Celso Rene
@since 13/03/2020
@version 1.0
@type function
/*/
user function XBRWCB0()

    Private _aRetun 	:= {}
    Private oBrw
    Private aHead		:= {}
    Private cCadastro	:= "CB0"
    Private aRotina     := { }
    Private cFiltro   := ""
    Private aCores  := {;
        { "CB0->CB0_TIPO == '01' " , "ENABLE" 		 },;
        { "CB0->CB0_TIPO == '02' " , "BR_LARANJA"    },;
        { "CB0->CB0_TIPO == '03' " , "BR_PRETO" 	 },;
        { "CB0->CB0_TIPO == '04' " , "BR_BRANCO"     },;
        { "CB0->CB0_TIPO == '05' " , "BR_AZUL"  	 } }

     Private cAliasX3 := GetNextAlias()

    AADD(aRotina, { "Pesquisar"	, "AxPesqui"  	    , 0 , 1 })
    AADD(aRotina, { "Visualizar", "AxVisual"  	 	, 0 , 2 })
    AADD(aRotina, { "Legenda"   , "u__LegCB0()"	    , 1 , 0, 9 })
    //AADD(aRotina, { "Incluir"   , "AxInclui"     , 0 , 3 })
    //AADD(aRotina, { "Alterar"   , "AxAltera"     , 0 , 4 })
    //AADD(aRotina, { "Excluir"   , "AxDeleta"     , 0 , 5 })

    oBrw := FWMBrowse():New()

    //01=Produto;02=Endereco;03=Unitizador;04=Usuario;05=Volume
    oBrw:AddLegend( "CB0->CB0_TIPO == '01' " , "ENABLE" 	, "Produto" )
    oBrw:AddLegend( "CB0->CB0_TIPO == '02' " , "BR_LARANJA" , "Endereço" )
    oBrw:AddLegend( "CB0->CB0_TIPO == '03' " , "BR_AMARELO" , "Unitilizador" )
    oBrw:AddLegend( "CB0->CB0_TIPO == '04' " , "BR_BRANCO" 	, "Usuário" )
    oBrw:AddLegend( "CB0->CB0_TIPO == '05' " , "BR_AZUL" 	, "Embalagem" )

    OpenSXs(Nil,Nil,Nil,Nil,cEmpAnt,cAliasX3,"SX3",Nil,.F.)
	lOpen := Select(cAliasX3) > 0
    If (lOpen)
		dbSelectArea(cAliasX3)
		(cAliasX3)->(dbSetOrder(1)) //arquivo
		(cAliasX3)->(dbSeek(cCadastro))
		While ( !(cAliasX3)->(Eof()) .And. &("(cAliasX3)->X3_ARQUIVO") == cCadastro )

            If X3USO((cAliasX3)-X3_USADO)
                Aadd(aHead,{ AllTrim(&("(cAliasX3)->X3_TITULO")), &("(cAliasX3)->X3_CAMPO"), &("(cAliasX3)->X3_PICTURE"),&("(cAliasX3)->X3_TAMANHO"),;
                &("(cAliasX3)->X3_DECIMAL"),"AllwaysTrue()",&("(cAliasX3)->X3_USADO"), &("(cAliasX3)->X3_TIPO"), &("(cAliasX3)->X3_ARQUIVO"), &("(cAliasX3)->X3_CONTEXT") } )
            Endif
            (cAliasX3)->(dbSkip())
		EndDo	    
	Endif
    (cAliasX3)->(DBCloseArea())

    dbSelectArea("CB0")
    CB0->(dbgotop())

    oBrw:SetAlias("CB0")
    oBrw:SetFields(aHead)
    oBrw:SetDescription("# Cadastros Etiquetas I.D. - ACD")
    oBrw:Activate()

Return()


/*/{Protheus.doc} _LegCB0
//Funcao para tela de legenda CB0
@author Celso Rene
@since 13032020
@version 1.0
@type function
/*/
User Function _LegCB0()

    //01=Produto;02=Endereco;03=Unitizador;04=Usuario;05=Volume
    BrwLegenda(cCadastro,"Legenda"				  ,{;
        {"ENABLE"    	,"01-Etiqueta"  			},;
        {"BR_LARANJA"   ,"02-Endereço" 				},;
        {"BR_AMARELO"   ,"03-Unitilizador" 			},;
        {"BR_BRANCO"    ,"04-Usuario"	 			},;
        {"BR_AZUL"   	,"05-Volume"	 			}} )

Return()
