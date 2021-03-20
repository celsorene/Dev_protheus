#include 'protheus.ch'

/*/{Protheus.doc} MT160WF
//P.E. - Final pedido de compra na rotina de analisa cotação (antes da contabilização)
@author Gregory A.
@since 28/08/2019
@version 1.0
@type function
@see https://tdn.totvs.com/display/public/PROT/MT160WF+-+Processos+de+workflow
/*/
User Function MT160WF()

    Local _aAreaC7	:= SC7->( GetArea() )
    Local _aAreaCR	:= SCR->( GetArea() )

    U_WFAPVPC( SC7->C7_NUM )

    RestArea( _aAreaC7 )
    RestArea( _aAreaCR )

Return