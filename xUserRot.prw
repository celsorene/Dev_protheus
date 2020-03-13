#include "Protheus.ch"


/*/{Protheus.doc} xUserRot
//Tela xUserRot OP
//exemplo: u_xUserRot("MATA010",.T.)
//parametro 1 = rotina a ser procurada usuários acessando (caractere)
//parametro 2 = indica se sera exibida mensagem dos usuarios que estao acessando a rotina (logico)
@author Celso Rene
@since 15/03/2020
@version 1.0
@type function
/*/ 
User Function xUserRot(_cRotina,_lMens) 

    Local 	aInfo 	:= GetUserInfoArray()
    Local 	lAchou 	:= .F.
    Local   _cUser  := ""
    Default	_cRotina:= ""
    Default _lMens  := .F.

    if !(Empty(_cRotina))
        For m := 1 to Len(aInfo)
            If (Alltrim(_cRotina) $ aInfo[m][11])
                lAchou := .T.
                if (_lMens == .F.)
                    m := Len(aInfo) + 1
                Else
                    if Empty(_cUser)
                        _cUser := Alltrim(Substring(aInfo[m][11],20,13))
                    else
                        _cUser += "," + chr(10) + chr(13) + Alltrim(Substring(aInfo[m][11],20,13))
                    endif
                Endif
            EndIf
        Next

        //se encontrou usuarios acessando rotina e controle de mensagem = .T. - mensagem de aviso usuarios
        If (lAchou == .T. .and. _lMens == .T.)
            Aviso("# Em uso rotina " + _cRotina +"",;
                "O(s) usuário(s): " +_cUser + " está(ã)o utilizando a rotina: "+ _cRotina + ".")
        Endif
    endif

Return(lAchou)
