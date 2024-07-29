#Include "PROTHEUS.CH"
#Include "Totvs.ch"
#Include "Topconn.ch"
#Include "rwmake.ch"


//teste execauto - SE2
User Function xExecSE2()

	Local 	_aSE2		:= {}
	Private lMsErroAuto := .F.

	//RpcSetEnv('99','01')
	RpcSetEnv("99","01","admin","","FIN",  ,{"SM0","SE2","SA2","SED"})

	_aSE2 := {}

	//contas a pagar

	_aSE2 := {;
		{"E2_FILIAL"     ,"01"	        ,Nil},;
		{"E2_PREFIXO"    ,"TST"	        ,Nil},;
		{"E2_NUM"        ,"000000002"	,Nil},;
		{"E2_PARCELA"    ,"1"	        ,Nil},;
		{"E2_TIPO"       ,"NF"		    ,Nil},;
		{"E2_NATUREZ"    ,"0009      "  ,Nil},;
		{"E2_FORNECE"    ,"002   "	    ,Nil},;
		{"E2_LOJA"       ,"01"		    ,Nil},;
		{"E2_EMISSAO"    ,dDataBase	    ,NIL},;
		{"E2_VENCTO"     ,dDataBase + 5	,NIL},;
		{"E2_VENCREA"    ,DataValida(dDataBase + 5)	,NIL},;
		{"E2_HIST"       ,"TESTE"		,Nil},;
		{"E2_VALOR"      ,100			,Nil},;
		{"E2_SALDO"      ,100			,Nil}}

	lMsErroAuto := .F.
	//lMsHelpAuto := .F.

	MSExecAuto({|x,y,z| Fina050(x,y,z)},_aSE2,,3) //inclusao
	If (lMsErroAuto)
		MostraErro()
	endif


	RpcClearEnv()


Return()


//teste execauto - SE1
User Function xExecSE1()

	Local 	_aSE1		:= {}
	Private lMsErroAuto := .F.

	//RpcSetEnv('99','01')
	RpcSetEnv("99","01","admin","","FIN",  ,{"SM0","SE1","SE5","SA1","SED"})

	_aSE1 := {}

	//contas a pagar

	_aSE1 := {;
		{"E1_FILIAL"     ,"01"	        ,Nil},;
		{"E1_PREFIXO"    ,"TST"	        ,Nil},;
		{"E1_NUM"        ,"000000003"	,Nil},;
		{"E1_PARCELA"    ,"1"	        ,Nil},;
		{"E1_TIPO"       ,"NF"		    ,Nil},;
		{"E1_NATUREZ"    ,"0009      "  ,Nil},;
		{"E1_CLIENTE"    ,"0001  "	    ,Nil},;
		{"E1_LOJA"       ,"01"		    ,Nil},;
		{"E1_EMISSAO"    ,dDataBase	    ,NIL},;
		{"E1_VENCTO"     ,dDataBase + 5	,NIL},;
		{"E1_VENCREA"    ,DataValida(dDataBase + 5)	,NIL},;
		{"E1_HIST"       ,"TESTE"		,Nil},;
		{"E1_MOEDA"      , 1            ,NIL},;
		{"E1_VLCRUZ "    ,100			,Nil},;
		{"E1_VALOR"      ,100			,Nil}}

	lMsErroAuto := .F.
	//lMsHelpAuto := .F.

	MsExecAuto( { |x,y| FINA040(x,y)} , _aSE1, 3) //inclusao
	If (lMsErroAuto)
		MostraErro()
	endif


	RpcClearEnv()


Return()
